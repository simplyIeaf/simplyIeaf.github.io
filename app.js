import { create } from 'https://esm.sh/zustand@4.5.3';
import Swal from 'https://esm.sh/sweetalert2@11.15.4';
import Toastify from 'https://esm.sh/toastify-js@1.12.0';
import NProgress from 'https://esm.sh/nprogress@0.2.0';
import { saveAs } from 'https://esm.sh/file-saver@2.0.5';

const CONFIG = {
    user: 'simplyIeaf',
    repo: 'simplyIeaf.github.io',
    cacheBuster: () => Date.now()
};

const utils = {
    debounce(func, wait) {
        let timeout;
        return function(...args) {
            const context = this;
            clearTimeout(timeout);
            timeout = setTimeout(() => func.apply(context, args), wait);
        };
    },
    
    safeBtoa(str) {
        try {
            return btoa(encodeURIComponent(str).replace(/%([0-9A-F]{2})/g, 
                (match, p1) => String.fromCharCode('0x' + p1)));
        } catch(e) {
            return btoa(unescape(encodeURIComponent(str)));
        }
    },
    
    safeAtob(str) {
        try {
            return decodeURIComponent(atob(str).split('').map(c => 
                '%' + ('00' + c.charCodeAt(0).toString(16)).slice(-2)).join(''));
        } catch(e) {
            return decodeURIComponent(escape(atob(str)));
        }
    },

    sanitizeTitle(title) {
        return title.toLowerCase()
            .replace(/[^a-z0-9]+/g, '-')
            .replace(/^-+|-+$/g, '')
            .substring(0, 100);
    },

    escapeHtml(text) {
        const div = document.createElement('div');
        div.textContent = text;
        return div.innerHTML;
    },

    validateTitle(title) {
        if (!title || title.trim().length === 0) return 'Title is required';
        if (title.length > 100) return 'Title must be less than 100 characters';
        const sanitized = this.sanitizeTitle(title);
        if (sanitized.includes('..') || sanitized.includes('/') || sanitized.includes('\\')) {
            return 'Invalid title characters';
        }
        const reserved = ['con', 'prn', 'aux', 'nul'];
        if (reserved.includes(sanitized.toLowerCase())) return 'Invalid title';
        return null;
    },

    validateCode(code) {
        if (!code || code.trim().length === 0) return 'Code is required';
        if (code.length > 100000) return 'Code is too large (max 100KB)';
        return null;
    },

    showToast(message, type = 'success') {
        Toastify({
            text: message,
            duration: 3000,
            gravity: "top",
            position: "right",
            backgroundColor: type === 'success' ? "#10b981" : type === 'error' ? "#ef4444" : "#f59e0b",
            stopOnFocus: true
        }).showToast();
    }
};

const useStore = create((set, get) => ({
    db: { scripts: {} },
    dbSha: null,
    token: null,
    currentUser: null,
    currentFilter: 'all',
    currentSort: 'newest',
    actionInProgress: false,
    currentEditingId: null,
    originalTitle: null,
    isLoading: false,
    searchQuery: '',
    
    setLoading: (loading) => set({ isLoading: loading }),
    setSearchQuery: (query) => set({ searchQuery: query }),
    setCurrentFilter: (filter) => set({ currentFilter: filter }),
    setCurrentSort: (sort) => set({ currentSort: sort }),
    
    setAuth: (token, user) => set({ token, currentUser: user }),
    clearAuth: () => set({ token: null, currentUser: null }),
    
    setDatabase: (db, sha) => set({ db, dbSha: sha }),
    setEditingId: (id, originalTitle) => set({ currentEditingId: id, originalTitle }),
    clearEditing: () => set({ currentEditingId: null, originalTitle: null }),
    
    startAction: () => set({ actionInProgress: true }),
    endAction: () => set({ actionInProgress: false }),
    
    async init() {
        await this.loadSession();
        await this.loadDatabase();
        this.handleRouting();
        window.addEventListener('hashchange', () => this.handleRouting());
        
        const today = new Date().toISOString().split('T')[0];
        document.getElementById('edit-expire').min = today;
        
        window.addEventListener('keydown', (e) => {
            if ((e.ctrlKey || e.metaKey) && e.key === 's') {
                e.preventDefault();
                this.saveScript();
            }
        });
    },

    async loadSession() {
        try {
            const storedToken = sessionStorage.getItem('gh_token');
            const storedUser = sessionStorage.getItem('gh_user');
            
            if (storedToken && storedUser) {
                const user = JSON.parse(storedUser);
                
                if (user.login.toLowerCase() !== CONFIG.user.toLowerCase()) {
                    this.clearAuth();
                    sessionStorage.clear();
                    return false;
                }
                
                this.setAuth(storedToken, user);
                await this.verifyToken(true);
                return true;
            }
        } catch(e) {
            this.clearAuth();
            sessionStorage.clear();
        }
        return false;
    },

    saveSession() {
        const { token, currentUser } = get();
        if (token && currentUser) {
            sessionStorage.setItem('gh_token', token);
            sessionStorage.setItem('gh_user', JSON.stringify(currentUser));
            setTimeout(() => {
                sessionStorage.removeItem('gh_token');
            }, 4 * 60 * 60 * 1000);
        }
    },

    async verifyToken(silent) {
        const { token } = get();
        if (!token) return false;
        
        try {
            NProgress.start();
            const res = await fetch('https://api.github.com/user', {
                headers: { 'Authorization': `token ${token}` }
            });
            
            if (!res.ok) throw new Error('Invalid token');
            
            const user = await res.json();
            if (user.login.toLowerCase() !== CONFIG.user.toLowerCase()) {
                throw new Error(`Token belongs to ${user.login}, not ${CONFIG.user}.`);
            }
            
            this.setAuth(token, user);
            document.getElementById('auth-section').style.display = 'none';
            document.getElementById('user-section').style.display = 'flex';
            document.getElementById('private-filter').style.display = 'block';
            document.getElementById('unlisted-filter').style.display = 'block';
            
            return true;
        } catch (e) {
            if (!silent) {
                utils.showToast(e.message, 'error');
            }
            this.clearAuth();
            sessionStorage.clear();
            return false;
        } finally {
            NProgress.done();
        }
    },

    async loadDatabase() {
        try {
            this.setLoading(true);
            const { token } = get();
            
            const res = await fetch(`https://api.github.com/repos/${CONFIG.user}/${CONFIG.repo}/contents/database.json?t=${CONFIG.cacheBuster()}`, {
                headers: token ? { 'Authorization': `token ${token}` } : {}
            });
            
            if (res.status === 404) {
                this.setDatabase({ scripts: {} }, null);
            } else if (res.ok) {
                const file = await res.json();
                const db = JSON.parse(utils.safeAtob(file.content));
                this.setDatabase(db, file.sha);
            } else {
                throw new Error(`Failed to load database: ${res.status}`);
            }
            
            this.renderList();
            this.renderAdminList();
        } catch (e) { 
            console.error("DB Error", e);
            utils.showToast(`Error loading scripts: ${e.message}`, 'error');
        } finally {
            this.setLoading(false);
        }
    },

    generateScriptHTML(title, scriptData) {
        const scriptId = utils.sanitizeTitle(title);
        const descriptionHtml = scriptData.description ? 
            `<div class="script-description">${this.sanitizeHtml(scriptData.description)}</div>` : '';
        
        return `<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>${utils.escapeHtml(scriptData.title)} - Leaf's Scripts</title>
    <link rel="icon" type="image/png" href="https://yt3.ggpht.com/wrMKTrl_4TexkVLuTILn1KZWW6NEbqTyLts9UhZNZhzLkOEBS13lBAi3gVl1Q465QruIDSwCUQ=s160-c-k-c0x00ffffff-no-rj">
    <link rel="stylesheet" href="../../style.css">
    <link href="https://cdnjs.cloudflare.com/ajax/libs/prism/1.29.0/themes/prism-tomorrow.min.css" rel="stylesheet" />
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
</head>
<body>
    <nav class="navbar">
        <div class="nav-content">
            <div class="nav-left">
                <a href="../../index.html" class="brand" style="text-decoration: none; color: inherit;">
                    <img src="https://yt3.ggpht.com/wrMKTrl_4TexkVLuTILn1KZWW6NEbqTyLts9UhZNZhzLkOEBS13lBAi3gVl1Q465QruIDSwCUQ=s160-c-k-c0x00ffffff-no-rj" class="nav-icon" alt="Icon">
                    <span class="nav-title">Leaf's Scripts</span>
                </a>
            </div>
            <div class="nav-right">
                <a href="../../index.html" class="btn btn-secondary btn-sm">Back</a>
            </div>
        </div>
    </nav>
    
    <div class="container">
        <div class="script-header-lg">
            <div>
                <h1>${utils.escapeHtml(scriptData.title)}</h1>
                <div class="meta-row">
                    <span class="meta-badge">
                        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="4" width="18" height="18" rx="2" ry="2"></rect><line x1="16" y1="2" x2="16" y2="6"></line><line x1="8" y1="2" x2="8" y2="6"></line><line x1="3" y1="10" x2="21" y2="10"></line></svg>
                        <span>${new Date(scriptData.created).toLocaleDateString()}</span>
                    </span>
                </div>
            </div>
        </div>

        ${descriptionHtml}
        
        <div class="code-box">
            <div class="toolbar">
                <div class="file-info">raw/${scriptData.filename}</div>
                <div class="toolbar-right">
                    <button class="btn btn-sm" onclick="downloadScript()">Download</button>
                    <button class="btn btn-sm" onclick="copyScript(this)">Copy</button>
                    <a href="raw/${scriptData.filename}" class="btn btn-secondary btn-sm" target="_blank">Raw</a>
                </div>
            </div>
            <pre><code id="code-display" class="language-lua">Loading...</code></pre>
        </div>
    </div>

    <script src="https://cdnjs.cloudflare.com/ajax/libs/prism/1.29.0/prism.min.js"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/prism/1.29.0/components/prism-lua.min.js"></script>
    <script>
        const filename = '${scriptData.filename}';
        const scriptId = '${scriptId}';
        
        async function loadScript() {
            try {
                const res = await fetch(\`raw/\${filename}\`);
                const code = await res.text();
                document.getElementById('code-display').textContent = code;
                Prism.highlightAll();
            } catch(e) {
                document.getElementById('code-display').textContent = '-- Error loading source';
            }
        }
        
        function copyScript(btn) {
            const code = document.getElementById('code-display').textContent;
            navigator.clipboard.writeText(code).then(() => {
                const original = btn.innerText;
                btn.innerText = 'Copied!';
                setTimeout(() => btn.innerText = original, 2000);
            });
        }
        
        function downloadScript() {
            const code = document.getElementById('code-display').textContent;
            const blob = new Blob([code], { type: 'text/plain;charset=utf-8' });
            saveAs(blob, filename);
        }
        
        loadScript();
    </script>
</body>
</html>`;
    },

    sanitizeHtml(html) {
        const temp = document.createElement('div');
        temp.textContent = html;
        return temp.innerHTML.replace(/\n/g, '<br>');
    },

    renderList() {
        const { db, currentFilter, currentSort, searchQuery, currentUser } = get();
        const list = document.getElementById('script-list');
        const scripts = Object.entries(db.scripts || {}).map(([title, data]) => ({ title, ...data }));
        
        const filtered = scripts.filter(s => {
            if (!s.title.toLowerCase().includes(searchQuery.toLowerCase())) return false;
            if (s.visibility === 'PRIVATE' && !currentUser) return false;
            if (s.visibility === 'UNLISTED' && !currentUser) return false; 
            if (currentFilter === 'private' && s.visibility !== 'PRIVATE') return false;
            if (currentFilter === 'public' && s.visibility !== 'PUBLIC') return false;
            if (currentFilter === 'unlisted' && s.visibility !== 'UNLISTED') return false;
            if (s.expiration && new Date(s.expiration) < new Date()) return false;
            return true;
        });
        
        const sorted = filtered.sort((a, b) => {
            if (currentSort === 'newest') return new Date(b.created || 0) - new Date(a.created || 0);
            if (currentSort === 'oldest') return new Date(a.created || 0) - new Date(b.created || 0);
            if (currentSort === 'alpha') return a.title.localeCompare(b.title);
            if (currentSort === 'updated') return new Date(b.updated || b.created || 0) - new Date(a.updated || a.created || 0);
            return 0;
        });
        
        if (sorted.length === 0) {
            list.innerHTML = `<div class="empty-state">
                <svg width="64" height="64" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" style="opacity:0.3;margin-bottom:16px;">
                    <path d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"></path>
                </svg>
                <h2>No scripts found</h2>
                <p>Try adjusting your search or filter</p>
            </div>`;
            return;
        }
        
        list.innerHTML = sorted.map(s => {
            const scriptId = utils.sanitizeTitle(s.title);
            const isExpired = s.expiration && new Date(s.expiration) < new Date();
            return `
            <div class="script-card animate__animated animate__fadeInUp" onclick="window.location.href='scripts/${scriptId}/index.html'">
                <div class="card-content">
                    <div class="card-header-section">
                        <h3 class="script-title">${utils.escapeHtml(s.title)} ${isExpired ? '⏰' : ''}</h3>
                        ${s.visibility !== 'PUBLIC' ? `<span class="badge badge-${s.visibility.toLowerCase()}">${s.visibility}</span>` : ''}
                        ${isExpired ? `<span class="badge" style="background:#ef4444;color:#fff">EXPIRED</span>` : ''}
                    </div>
                    ${s.description ? `<p style="color:var(--color-text-muted);font-size:13px;margin:8px 0">${utils.escapeHtml(s.description)}</p>` : ''}
                    <div class="card-meta">
                        <span>${new Date(s.created).toLocaleDateString()}</span>
                        ${s.updated && s.updated !== s.created ? `<span title="Updated">↻ ${new Date(s.updated).toLocaleDateString()}</span>` : ''}
                    </div>
                </div>
            </div>
        `}).join('');
    },

    async updateScript(scriptTitle, newTitle, scriptData) {
        const { db, dbSha, token, currentEditingId, originalTitle } = get();
        
        if (!currentEditingId || !originalTitle) {
            throw new Error('No script being edited');
        }
        
        const oldScriptId = utils.sanitizeTitle(originalTitle);
        const newScriptId = utils.sanitizeTitle(newTitle);
        const oldScriptData = db.scripts[originalTitle];
        
        const isTitleChanged = newTitle !== originalTitle;
        
        try {
            NProgress.start();
            
            if (isTitleChanged && oldScriptData) {
                const oldLuaPath = `scripts/${oldScriptId}/raw/${oldScriptData.filename}`;
                const oldIndexPath = `scripts/${oldScriptId}/index.html`;
                
                await this.deleteGitHubFile(oldLuaPath);
                await this.deleteGitHubFile(oldIndexPath);
                
                delete db.scripts[originalTitle];
            }
            
            const filename = newScriptId + '.lua';
            const scriptEntry = {
                title: newTitle,
                visibility: scriptData.visibility,
                description: scriptData.description,
                expiration: scriptData.expiration,
                filename: filename,
                size: scriptData.code.length,
                created: isTitleChanged ? new Date().toISOString() : oldScriptData?.created || new Date().toISOString(),
                updated: new Date().toISOString()
            };
            
            db.scripts[newTitle] = scriptEntry;
            
            const luaPath = `scripts/${newScriptId}/raw/${filename}`;
            const luaSha = await this.getFileSha(luaPath);
            
            await this.putGitHubFile(luaPath, scriptData.code, luaSha, 
                `${isTitleChanged ? 'Create' : 'Update'} ${filename}`);
            
            const indexHTML = this.generateScriptHTML(newTitle, scriptEntry);
            const indexPath = `scripts/${newScriptId}/index.html`;
            const indexSha = await this.getFileSha(indexPath);
            
            await this.putGitHubFile(indexPath, indexHTML, indexSha, 
                `${isTitleChanged ? 'Create' : 'Update'} index for ${newTitle}`);
            
            const newDbRes = await fetch(`https://api.github.com/repos/${CONFIG.user}/${CONFIG.repo}/contents/database.json`, {
                method: 'PUT',
                headers: { 
                    'Authorization': `token ${token}`,
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({
                    message: `${isTitleChanged ? 'Rename' : 'Update'} ${newTitle}`,
                    content: utils.safeBtoa(JSON.stringify(db, null, 2)),
                    sha: dbSha
                })
            });
            
            if (!newDbRes.ok) {
                throw new Error('Failed to update database');
            }
            
            const newDbData = await newDbRes.json();
            this.setDatabase(db, newDbData.content.sha);
            
            if (isTitleChanged) {
                this.setEditingId(newTitle, newTitle);
            }
            
            utils.showToast(`Script ${isTitleChanged ? 'renamed and updated' : 'updated'} successfully!`, 'success');
            return true;
            
        } catch (error) {
            console.error('Update error:', error);
            utils.showToast(`Error: ${error.message}`, 'error');
            throw error;
        } finally {
            NProgress.done();
        }
    },

    async deleteGitHubFile(path) {
        const { token } = get();
        try {
            const res = await fetch(`https://api.github.com/repos/${CONFIG.user}/${CONFIG.repo}/contents/${path}`, {
                headers: { 'Authorization': `token ${token}` }
            });
            
            if (res.ok) {
                const data = await res.json();
                await fetch(`https://api.github.com/repos/${CONFIG.user}/${CONFIG.repo}/contents/${path}`, {
                    method: 'DELETE',
                    headers: { 
                        'Authorization': `token ${token}`,
                        'Content-Type': 'application/json'
                    },
                    body: JSON.stringify({
                        message: `Delete ${path.split('/').pop()}`,
                        sha: data.sha
                    })
                });
            }
        } catch (e) {
            console.warn(`File deletion error for ${path}:`, e.message);
        }
    },

    async getFileSha(path) {
        const { token } = get();
        try {
            const res = await fetch(`https://api.github.com/repos/${CONFIG.user}/${CONFIG.repo}/contents/${path}`, {
                headers: { 'Authorization': `token ${token}` }
            });
            if (res.ok) {
                const data = await res.json();
                return data.sha;
            }
        } catch (e) {
            return null;
        }
        return null;
    },

    async putGitHubFile(path, content, sha, message) {
        const { token } = get();
        const res = await fetch(`https://api.github.com/repos/${CONFIG.user}/${CONFIG.repo}/contents/${path}`, {
            method: 'PUT',
            headers: { 
                'Authorization': `token ${token}`,
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                message: message,
                content: utils.safeBtoa(content),
                sha: sha || undefined
            })
        });
        
        if (!res.ok) {
            throw new Error(`Failed to save ${path}`);
        }
        
        return await res.json();
    },

    async createScript(scriptData) {
        const { db, dbSha, token } = get();
        const scriptId = utils.sanitizeTitle(scriptData.title);
        const filename = scriptId + '.lua';
        
        const scriptEntry = {
            title: scriptData.title,
            visibility: scriptData.visibility,
            description: scriptData.description,
            expiration: scriptData.expiration,
            filename: filename,
            size: scriptData.code.length,
            created: new Date().toISOString(),
            updated: new Date().toISOString()
        };
        
        db.scripts[scriptData.title] = scriptEntry;
        
        try {
            NProgress.start();
            
            await this.putGitHubFile(
                `scripts/${scriptId}/raw/${filename}`,
                scriptData.code,
                null,
                `Create ${filename}`
            );
            
            const indexHTML = this.generateScriptHTML(scriptData.title, scriptEntry);
            
            await this.putGitHubFile(
                `scripts/${scriptId}/index.html`,
                indexHTML,
                null,
                `Create index for ${scriptData.title}`
            );
            
            const newDbRes = await fetch(`https://api.github.com/repos/${CONFIG.user}/${CONFIG.repo}/contents/database.json`, {
                method: 'PUT',
                headers: { 
                    'Authorization': `token ${token}`,
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({
                    message: `Add ${scriptData.title}`,
                    content: utils.safeBtoa(JSON.stringify(db, null, 2)),
                    sha: dbSha
                })
            });
            
            if (!newDbRes.ok) {
                throw new Error('Failed to update database');
            }
            
            const newDbData = await newDbRes.json();
            this.setDatabase(db, newDbData.content.sha);
            
            utils.showToast('Script created successfully!', 'success');
            return true;
            
        } catch (error) {
            console.error('Create error:', error);
            utils.showToast(`Error: ${error.message}`, 'error');
            throw error;
        } finally {
            NProgress.done();
        }
    },

    async saveScript() {
        const { actionInProgress, currentEditingId, db } = get();
        if (actionInProgress || !useStore.getState().currentUser) return;
        
        const title = document.getElementById('edit-title').value.trim();
        const visibility = document.getElementById('edit-visibility').value;
        const desc = document.getElementById('edit-desc').value.trim();
        const expiration = document.getElementById('edit-expire').value;
        const code = window.monacoEditor ? window.monacoEditor.getValue() : document.getElementById('edit-code').value;
        
        const titleError = utils.validateTitle(title);
        const codeError = utils.validateCode(code);
        
        if (titleError || codeError) {
            utils.showToast(titleError || codeError, 'error');
            return;
        }
        
        if (expiration && new Date(expiration) < new Date()) {
            utils.showToast('Expiration date cannot be in the past', 'error');
            return;
        }
        
        const scriptData = {
            title,
            visibility,
            description: desc,
            expiration,
            code
        };
        
        this.startAction();
        
        try {
            if (currentEditingId) {
                await this.updateScript(currentEditingId, title, scriptData);
            } else {
                if (db.scripts[title]) {
                    const result = await Swal.fire({
                        title: 'Script Already Exists',
                        text: `A script titled "${title}" already exists. Do you want to overwrite it?`,
                        icon: 'warning',
                        showCancelButton: true,
                        confirmButtonText: 'Overwrite',
                        cancelButtonText: 'Cancel'
                    });
                    
                    if (result.isConfirmed) {
                        this.setEditingId(title, title);
                        await this.updateScript(title, title, scriptData);
                    } else {
                        return;
                    }
                } else {
                    await this.createScript(scriptData);
                }
            }
            
            await this.loadDatabase();
            if (currentEditingId) {
                this.switchAdminTab('list');
            }
            
        } catch (error) {
            console.error('Save error:', error);
        } finally {
            this.endAction();
        }
    },

    async deleteScript() {
        const { currentEditingId, db, token, dbSha } = get();
        
        if (!currentEditingId || !db.scripts[currentEditingId]) {
            utils.showToast('No script selected for deletion', 'error');
            return;
        }
        
        const result = await Swal.fire({
            title: 'Delete Script',
            text: `Are you sure you want to delete "${currentEditingId}"? This action cannot be undone.`,
            icon: 'warning',
            showCancelButton: true,
            confirmButtonText: 'Yes, delete it!',
            cancelButtonText: 'Cancel',
            confirmButtonColor: '#ef4444'
        });
        
        if (!result.isConfirmed) return;
        
        try {
            NProgress.start();
            this.startAction();
            
            const scriptId = utils.sanitizeTitle(currentEditingId);
            const scriptData = db.scripts[currentEditingId];
            
            await this.deleteGitHubFile(`scripts/${scriptId}/raw/${scriptData.filename}`);
            await this.deleteGitHubFile(`scripts/${scriptId}/index.html`);
            
            delete db.scripts[currentEditingId];
            
            const newDbRes = await fetch(`https://api.github.com/repos/${CONFIG.user}/${CONFIG.repo}/contents/database.json`, {
                method: 'PUT',
                headers: { 
                    'Authorization': `token ${token}`,
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({
                    message: `Remove ${currentEditingId} from database`,
                    content: utils.safeBtoa(JSON.stringify(db, null, 2)),
                    sha: dbSha
                })
            });
            
            if (!newDbRes.ok) {
                throw new Error('Failed to update database');
            }
            
            const newDbData = await newDbRes.json();
            this.setDatabase(db, newDbData.content.sha);
            this.clearEditing();
            
            utils.showToast('Script deleted successfully', 'success');
            await this.loadDatabase();
            this.switchAdminTab('list');
            
        } catch (error) {
            console.error('Delete error:', error);
            utils.showToast(`Delete failed: ${error.message}`, 'error');
        } finally {
            this.endAction();
            NProgress.done();
        }
    },

    async populateEditor(title) {
        const { db, currentUser } = get();
        if (!currentUser) return;
        
        const s = db.scripts[title];
        if (!s) return;
        
        this.setEditingId(title, title);
        this.switchAdminTab('create');
        
        document.getElementById('editor-heading').textContent = `Edit: ${title}`;
        document.getElementById('edit-title').value = s.title;
        document.getElementById('edit-visibility').value = s.visibility;
        document.getElementById('edit-desc').value = s.description || '';
        document.getElementById('edit-expire').value = s.expiration || '';
        
        const scriptId = utils.sanitizeTitle(title);
        
        try {
            NProgress.start();
            const res = await fetch(`https://api.github.com/repos/${CONFIG.user}/${CONFIG.repo}/contents/scripts/${scriptId}/raw/${s.filename}`, {
                headers: { 'Authorization': `token ${get().token}` }
            });
            
            if (res.ok) {
                const data = await res.json();
                const code = utils.safeAtob(data.content);
                
                if (window.monacoEditor) {
                    window.monacoEditor.setValue(code);
                } else {
                    document.getElementById('edit-code').value = code;
                }
            } else {
                const errorText = '-- Error loading content';
                if (window.monacoEditor) {
                    window.monacoEditor.setValue(errorText);
                } else {
                    document.getElementById('edit-code').value = errorText;
                }
            }
        } catch(e) { 
            const errorText = '-- Error loading content';
            if (window.monacoEditor) {
                window.monacoEditor.setValue(errorText);
            } else {
                document.getElementById('edit-code').value = errorText;
            }
        } finally {
            NProgress.done();
        }
        
        document.getElementById('btn-delete').style.display = 'inline-flex';
        document.querySelector('.editor-actions .btn:last-child').textContent = 'Update Script';
        
        this.updateViewButton(scriptId);
    },

    updateViewButton(scriptId) {
        let viewBtn = document.querySelector('.btn-view-script');
        if (!viewBtn) {
            const actionButtons = document.querySelector('.action-buttons');
            viewBtn = document.createElement('a');
            viewBtn.href = `scripts/${scriptId}/index.html`;
            viewBtn.target = '_blank';
            viewBtn.className = 'btn btn-secondary btn-view-script';
            viewBtn.innerHTML = `
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <path d="M18 13v6a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h6"></path>
                    <polyline points="15 3 21 3 21 9"></polyline>
                    <line x1="10" y1="14" x2="21" y2="3"></line>
                </svg>
                View Script
            `;
            actionButtons.appendChild(viewBtn);
        } else {
            viewBtn.href = `scripts/${scriptId}/index.html`;
        }
    },

    resetEditor() {
        document.getElementById('editor-heading').textContent = 'Create New Script';
        document.getElementById('edit-title').value = '';
        document.getElementById('edit-visibility').value = 'PUBLIC';
        document.getElementById('edit-desc').value = '';
        document.getElementById('edit-expire').value = '';
        
        if (window.monacoEditor) {
            window.monacoEditor.setValue('');
        } else {
            document.getElementById('edit-code').value = '';
        }
        
        document.getElementById('btn-delete').style.display = 'none';
        document.querySelector('.editor-actions .btn:last-child').textContent = 'Save & Publish';
        
        const viewBtn = document.querySelector('.btn-view-script');
        if (viewBtn) viewBtn.remove();
        
        this.clearEditing();
    },

    switchAdminTab(tab) {
        const { currentUser } = get();
        if (tab === 'admin' && !currentUser) {
            location.hash = '';
            return;
        }
        
        document.querySelectorAll('.admin-tab').forEach(t => t.style.display = 'none');
        document.querySelectorAll('.tab-btn').forEach(b => b.classList.remove('active'));
        
        if (tab === 'list') {
            document.getElementById('admin-tab-list').style.display = 'block';
            document.querySelectorAll('.tab-btn')[0].classList.add('active');
            this.renderAdminList();
        } else if (tab === 'stats') {
            document.getElementById('admin-tab-stats').style.display = 'block';
            document.querySelectorAll('.tab-btn')[2].classList.add('active');
            this.renderStats();
        } else {
            document.getElementById('admin-tab-editor').style.display = 'block';
            document.querySelectorAll('.tab-btn')[1].classList.add('active');
            if (tab === 'create') {
                this.resetEditor();
            }
        }
    },

    async renderAdminList() {
        const { db, currentUser } = get();
        if (!currentUser) return;
        
        const list = document.getElementById('admin-list');
        const scripts = Object.entries(db.scripts || {}).map(([title, data]) => ({ title, ...data }));
        const sorted = scripts.sort((a, b) => new Date(b.updated || b.created || 0) - new Date(a.updated || a.created || 0));
        
        document.getElementById('total-stats').textContent = `${scripts.length} Total Scripts`;
        
        if (sorted.length === 0) {
            list.innerHTML = `<div class="empty-admin-state">
                <p>No scripts yet. Click "Add New" to create your first script.</p>
            </div>`;
            return;
        }
        
        list.innerHTML = sorted.map(s => {
            const updated = s.updated ? new Date(s.updated).toLocaleDateString() : new Date(s.created).toLocaleDateString();
            const isExpired = s.expiration && new Date(s.expiration) < new Date();
            
            return `
            <div class="admin-item" data-script-title="${s.title.replace(/'/g, "\\'")}" onclick="app.populateEditor('${s.title.replace(/'/g, "\\'")}')">
                <div class="admin-item-left">
                    <strong>${utils.escapeHtml(s.title)} ${isExpired ? '⏰' : ''}</strong>
                    <div class="admin-meta">
                        <span class="badge badge-sm badge-${s.visibility.toLowerCase()}">${s.visibility}</span>
                        ${isExpired ? `<span class="badge badge-sm" style="background:#ef4444;color:#fff">EXPIRED</span>` : ''}
                        <span class="text-muted">Updated ${updated}</span>
                    </div>
                </div>
                <div class="admin-item-right">
                    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                        <path d="M9 18l6-6-6-6"/>
                    </svg>
                </div>
            </div>
        `}).join('');
    },

    renderStats() {
        const { db } = get();
        const scripts = Object.entries(db.scripts || {}).map(([title, data]) => ({ title, ...data }));
        const publicCount = scripts.filter(s => s.visibility === 'PUBLIC').length;
        const privateCount = scripts.filter(s => s.visibility === 'PRIVATE').length;
        const unlistedCount = scripts.filter(s => s.visibility === 'UNLISTED').length;
        const expiredCount = scripts.filter(s => s.expiration && new Date(s.expiration) < new Date()).length;
        const totalSize = scripts.reduce((acc, s) => acc + (s.size || 0), 0);
        
        if (scripts.length === 0) {
            document.getElementById('stats-content').innerHTML = `
                <div class="empty-admin-state">
                    <p>No scripts yet. Create your first script to see statistics.</p>
                </div>
            `;
            return;
        }
        
        document.getElementById('stats-content').innerHTML = `
            <div class="stats-grid">
                <div class="stat-card">
                    <div class="stat-number">${scripts.length}</div>
                    <div class="stat-label">Total Scripts</div>
                </div>
                <div class="stat-card">
                    <div class="stat-number">${publicCount}</div>
                    <div class="stat-label">Public</div>
                </div>
                <div class="stat-card">
                    <div class="stat-number">${privateCount}</div>
                    <div class="stat-label">Private</div>
                </div>
                <div class="stat-card">
                    <div class="stat-number">${unlistedCount}</div>
                    <div class="stat-label">Unlisted</div>
                </div>
                <div class="stat-card">
                    <div class="stat-number">${expiredCount}</div>
                    <div class="stat-label">Expired</div>
                </div>
                <div class="stat-card">
                    <div class="stat-number">${(totalSize / 1024).toFixed(1)}KB</div>
                    <div class="stat-label">Total Size</div>
                </div>
            </div>
        `;
    },

    handleRouting() {
        const hash = location.hash.slice(1);
        document.querySelectorAll('.view-section').forEach(el => el.style.display = 'none');
        window.scrollTo(0, 0);
        
        if (hash === 'admin') {
            if (!get().currentUser) {
                this.toggleLoginModal();
                location.hash = '';
                return;
            }
            document.getElementById('view-admin').style.display = 'block';
            this.switchAdminTab('list');
        } else {
            document.getElementById('view-home').style.display = 'block';
        }
    },

    toggleLoginModal() {
        const modal = document.getElementById('login-modal');
        modal.style.display = modal.style.display === 'flex' ? 'none' : 'flex';
        document.getElementById('login-error').style.display = 'none';
        if (modal.style.display === 'flex') {
            document.getElementById('auth-token').focus();
        }
    },

    async login() {
        const { actionInProgress } = get();
        if (actionInProgress) return;
        
        this.startAction();
        try {
            const token = document.getElementById('auth-token').value.trim();
            if (!token) {
                utils.showToast('Token is required', 'error');
                return;
            }
            
            this.setAuth(token, null);
            const success = await this.verifyToken(false);
            
            if (success) {
                this.saveSession();
                this.toggleLoginModal();
                document.getElementById('auth-token').value = '';
                await this.loadDatabase();
                this.renderList();
                utils.showToast('Logged in successfully!', 'success');
            }
        } finally {
            this.endAction();
        }
    },

    logout() {
        Swal.fire({
            title: 'Logout',
            text: 'Are you sure you want to logout?',
            icon: 'question',
            showCancelButton: true,
            confirmButtonText: 'Yes, logout',
            cancelButtonText: 'Cancel'
        }).then((result) => {
            if (result.isConfirmed) {
                this.clearAuth();
                sessionStorage.clear();
                document.getElementById('auth-section').style.display = 'block';
                document.getElementById('user-section').style.display = 'none';
                document.getElementById('private-filter').style.display = 'none';
                document.getElementById('unlisted-filter').style.display = 'none';
                location.href = '#';
                utils.showToast('Logged out successfully', 'success');
                setTimeout(() => location.reload(), 1000);
            }
        });
    }
}));

const app = useStore.getState();

function navigate(path) {
    if (path === 'admin' && !app.currentUser) {
        app.toggleLoginModal();
        return;
    }
    location.hash = path;
}

function initSearch() {
    const searchInput = document.getElementById('search');
    const debouncedSearch = utils.debounce(() => {
        useStore.getState().setSearchQuery(searchInput.value);
        useStore.getState().renderList();
    }, 300);
    
    searchInput.addEventListener('input', debouncedSearch);
}

function initMonacoEditor() {
    if (typeof monaco === 'undefined') return;
    
    const container = document.getElementById('editor-container');
    if (!container) return;
    
    window.monacoEditor = monaco.editor.create(container, {
        value: '',
        language: 'lua',
        theme: 'vs-dark',
        fontSize: 14,
        minimap: { enabled: false },
        scrollBeyondLastLine: false,
        wordWrap: 'on',
        lineNumbers: 'on',
        roundedSelection: false,
        scrollbar: {
            vertical: 'visible',
            horizontal: 'visible',
            useShadows: false
        },
        automaticLayout: true
    });
    
    const textarea = document.getElementById('edit-code');
    if (textarea) {
        textarea.style.display = 'none';
    }
}

async function loadMonacoEditor() {
    if (!document.getElementById('admin-tab-editor') || document.getElementById('admin-tab-editor').style.display === 'none') {
        return;
    }
    
    if (typeof monaco === 'undefined') {
        const script = document.createElement('script');
        script.src = 'https://cdnjs.cloudflare.com/ajax/libs/monaco-editor/0.34.0/min/vs/loader.min.js';
        script.onload = () => {
            require.config({ paths: { vs: 'https://cdnjs.cloudflare.com/ajax/libs/monaco-editor/0.34.0/min/vs' } });
            require(['vs/editor/editor.main'], () => {
                initMonacoEditor();
            });
        };
        document.head.appendChild(script);
    } else {
        initMonacoEditor();
    }
}

function initQuillEditor() {
    if (typeof Quill === 'undefined') return;
    
    const container = document.getElementById('quill-container');
    if (!container) return;
    
    const quill = new Quill(container, {
        theme: 'snow',
        modules: {
            toolbar: [
                ['bold', 'italic', 'underline'],
                ['code-block'],
                [{ 'list': 'ordered'}, { 'list': 'bullet' }],
                ['clean']
            ]
        },
        placeholder: 'Script description...'
    });
    
    quill.on('text-change', () => {
        document.getElementById('edit-desc').value = quill.root.innerHTML;
    });
    
    return quill;
}

async function loadQuillEditor() {
    if (typeof Quill === 'undefined') {
        const link = document.createElement('link');
        link.href = 'https://cdn.quilljs.com/1.3.6/quill.snow.css';
        link.rel = 'stylesheet';
        document.head.appendChild(link);
        
        const script = document.createElement('script');
        script.src = 'https://cdn.quilljs.com/1.3.6/quill.min.js';
        script.onload = () => {
            const quill = initQuillEditor();
            window.quillEditor = quill;
        };
        document.head.appendChild(script);
    } else {
        window.quillEditor = initQuillEditor();
    }
}

window.addEventListener('DOMContentLoaded', async () => {
    NProgress.configure({ 
        showSpinner: false,
        speed: 400,
        trickleSpeed: 200 
    });
    
    await app.init();
    initSearch();
    
    const observer = new MutationObserver((mutations) => {
        mutations.forEach((mutation) => {
            if (mutation.type === 'attributes' && mutation.attributeName === 'style') {
                const editorTab = document.getElementById('admin-tab-editor');
                if (editorTab && editorTab.style.display === 'block') {
                    loadMonacoEditor();
                    loadQuillEditor();
                }
            }
        });
    });
    
    const editorTab = document.getElementById('admin-tab-editor');
    if (editorTab) {
        observer.observe(editorTab, { attributes: true });
    }
    
    document.getElementById('search').addEventListener('input', (e) => {
        useStore.getState().setSearchQuery(e.target.value);
        useStore.getState().renderList();
    });
    
    document.querySelectorAll('.sidebar-link').forEach(link => {
        link.addEventListener('click', (e) => {
            e.preventDefault();
            const filter = e.target.getAttribute('onclick').match(/'(.*?)'/)[1];
            useStore.getState().setCurrentFilter(filter);
            useStore.getState().renderList();
            
            document.querySelectorAll('.sidebar-link').forEach(l => l.classList.remove('active'));
            e.target.classList.add('active');
        });
    });
    
    document.querySelector('.sidebar-sort select').addEventListener('change', (e) => {
        useStore.getState().setCurrentSort(e.target.value);
        useStore.getState().renderList();
    });
});

window.app = app;
window.navigate = navigate;
window.saveAs = saveAs;
