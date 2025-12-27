const CONFIG = { 
    user: 'simplyIeaf', 
    repo: 'simplyIeaf.github.io',
    cacheBuster: () => Date.now()
};

const utils = {
    safeBtoa(str) {
        return window.btoa(unescape(encodeURIComponent(str)));
    },
    
    safeAtob(str) {
        return decodeURIComponent(escape(window.atob(str)));
    },

    sanitizeTitle(title) {
        return title.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-+|-+$/g, '');
    }
};

const app = {
    db: { scripts: {} }, 
    dbSha: null, 
    token: localStorage.getItem('gh_token'), 
    currentUser: null,
    currentFilter: 'all', 
    currentSort: 'newest', 
    actionInProgress: false, 
    currentEditingId: null,
    originalTitle: null,
    
    async init() {
        if (this.token) await this.verifyToken(true);
        await this.loadDatabase();
        this.handleRouting();
        window.addEventListener('hashchange', () => this.handleRouting());
        
        document.getElementById('search').addEventListener('input', () => this.renderList());
    },

    generateScriptHTML(title, scriptData) {
        const scriptId = utils.sanitizeTitle(title);
        
        return `<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>${scriptData.title} - Leaf's Scripts</title>
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
                    <img src="https://yt3.ggpht.com/wrMKTrl_4TexkVLuTILn1KZWW6NEbqTyLts9UhZNZhzLkOEBS13lBAi3gVl1Q465QruIDSwCUQ=s160-c-k-c0x00ffffff-no-rj" class="nav-icon" alt="Profile">
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
                <h1>${scriptData.title}</h1>
                <div class="meta-row">
                    <span class="meta-badge">
                        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="4" width="18" height="18" rx="2" ry="2"></rect><line x1="16" y1="2" x2="16" y2="6"></line><line x1="8" y1="2" x2="8" y2="6"></line><line x1="3" y1="10" x2="21" y2="10"></line></svg>
                        <span>${new Date(scriptData.created).toLocaleDateString()}</span>
                    </span>
                </div>
            </div>
        </div>

        ${scriptData.description ? `<p class="script-desc">${scriptData.description}</p>` : ''}
        
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
            const element = document.createElement('a');
            element.setAttribute('href', 'data:text/plain;charset=utf-8,' + encodeURIComponent(code));
            element.setAttribute('download', filename);
            element.style.display = 'none';
            document.body.appendChild(element);
            element.click();
            document.body.removeChild(element);
        }
        
        loadScript();
    </script>
</body>
</html>`;
    },

    toggleLoginModal() {
        const modal = document.getElementById('login-modal');
        modal.style.display = modal.style.display === 'flex' ? 'none' : 'flex';
        document.getElementById('login-error').style.display = 'none';
    },

    async login() {
        if (this.actionInProgress) return;
        this.actionInProgress = true;
        const token = document.getElementById('auth-token').value.trim();
        if (!token) { this.actionInProgress = false; return; }
        
        this.token = token;
        const success = await this.verifyToken(false);
        if (success) {
            localStorage.setItem('gh_token', token);
            this.toggleLoginModal();
            await this.loadDatabase();
            this.renderList();
        }
        this.actionInProgress = false;
    },

    logout() {
        localStorage.removeItem('gh_token');
        this.token = null;
        this.currentUser = null;
        location.href = '#';
        location.reload();
    },

    async verifyToken(silent) {
        try {
            const res = await fetch('https://api.github.com/user', {
                headers: { 'Authorization': `token ${this.token}` }
            });
            if (!res.ok) throw new Error('Invalid token');
            const user = await res.json();
            if (user.login.toLowerCase() !== CONFIG.user.toLowerCase()) {
                throw new Error(`Token belongs to ${user.login}, not repo owner.`);
            }
            this.currentUser = user;
            document.getElementById('auth-section').style.display = 'none';
            document.getElementById('user-section').style.display = 'flex';
            document.getElementById('private-filter').style.display = 'block';
            return true;
        } catch (e) {
            if (!silent) {
                const err = document.getElementById('login-error');
                err.textContent = e.message;
                err.style.display = 'block';
            }
            this.token = null;
            return false;
        }
    },

    async loadDatabase() {
        try {
            const res = await fetch(`https://api.github.com/repos/${CONFIG.user}/${CONFIG.repo}/contents/database.json?t=${CONFIG.cacheBuster()}`, {
                headers: this.token ? { 'Authorization': `token ${this.token}` } : {}
            });
            if (res.status === 404) {
                this.db = { scripts: {} };
                this.dbSha = null;
            } else if (res.ok) {
                const file = await res.json();
                this.dbSha = file.sha;
                this.db = JSON.parse(utils.safeAtob(file.content));
            }
            this.renderList();
            this.renderAdminList();
        } catch (e) { 
            console.error("DB Error", e); 
        }
    },

    renderList() {
        const list = document.getElementById('script-list');
        const scripts = Object.entries(this.db.scripts || {}).map(([title, data]) => ({ title, ...data }));
        const filtered = this.filterLogic(scripts);
        const sorted = this.sortLogic(filtered);
        
        if (sorted.length === 0) {
            list.innerHTML = `<div class="empty-state"><h2>No scripts found</h2></div>`;
            return;
        }
        
        list.innerHTML = sorted.map(s => {
            const scriptId = utils.sanitizeTitle(s.title);
            return `
            <div class="script-card animate__animated animate__fadeInUp" onclick="window.location.href='scripts/${scriptId}/index.html'">
                <div class="card-content">
                    <div class="card-header-section">
                        <h3 class="script-title">${s.title}</h3>
                    </div>
                    <div class="card-meta">
                        <span>${new Date(s.created).toLocaleDateString()}</span>
                    </div>
                </div>
            </div>
        `}).join('');
    },

    filterLogic(scripts) {
        const query = document.getElementById('search').value.toLowerCase();
        return scripts.filter(s => {
            if (!s.title.toLowerCase().includes(query)) return false;
            if (s.visibility === 'PRIVATE' && !this.currentUser) return false;
            if (s.visibility === 'UNLISTED' && !this.currentUser) return false; 
            if (this.currentFilter === 'private' && s.visibility !== 'PRIVATE') return false;
            if (this.currentFilter === 'public' && s.visibility !== 'PUBLIC') return false;
            return true;
        });
    },

    sortLogic(scripts) {
        return scripts.sort((a, b) => {
            if (this.currentSort === 'newest') return new Date(b.created || 0) - new Date(a.created || 0);
            if (this.currentSort === 'oldest') return new Date(a.created || 0) - new Date(b.created || 0);
            if (this.currentSort === 'alpha') return a.title.localeCompare(b.title);
            return 0;
        });
    },

    filterCategory(cat, e) {
        if (e) {
            e.preventDefault();
            document.querySelectorAll('.sidebar-link').forEach(l => l.classList.remove('active'));
            if(e.target.classList.contains('sidebar-link')) e.target.classList.add('active');
        }
        this.currentFilter = cat;
        this.renderList();
    },

    setSort(val) { 
        this.currentSort = val; 
        this.renderList(); 
    },

    switchAdminTab(tab) {
        document.querySelectorAll('.admin-tab').forEach(t => t.style.display = 'none');
        document.querySelectorAll('.tab-btn').forEach(b => b.classList.remove('active'));
        
        if (tab === 'list') {
            document.getElementById('admin-tab-list').style.display = 'block';
            document.querySelectorAll('.tab-btn')[0].classList.add('active');
            this.renderAdminList();
        } else {
            document.getElementById('admin-tab-editor').style.display = 'block';
            document.querySelectorAll('.tab-btn')[1].classList.add('active');
            this.resetEditor();
        }
    },

    async renderAdminList() {
        const list = document.getElementById('admin-list');
        const scripts = Object.entries(this.db.scripts || {}).map(([title, data]) => ({ title, ...data }));
        
        document.getElementById('total-stats').textContent = `${scripts.length} Total Scripts`;
        
        list.innerHTML = scripts.map(s => {
            const visibility = (s.visibility || 'PUBLIC').toLowerCase();
            return `
            <div class="admin-item" onclick="app.populateEditor('${s.title.replace(/'/g, "\\'")}')">
                <div class="admin-item-left">
                    <strong>${s.title}</strong>
                    <div class="admin-meta">
                        <span class="badge badge-sm badge-${visibility}">${s.visibility || 'PUBLIC'}</span>
                        <span class="text-muted"> • ${new Date(s.created).toLocaleDateString()}</span>
                    </div>
                </div>
            </div>
        `}).join('');
    },

    resetEditor() {
        document.getElementById('editor-heading').textContent = 'Create New Script';
        document.getElementById('edit-title').value = '';
        document.getElementById('edit-visibility').value = 'PUBLIC';
        document.getElementById('edit-desc').value = '';
        document.getElementById('edit-expire').value = '';
        document.getElementById('edit-code').value = '';
        document.getElementById('btn-delete').style.display = 'none';
        this.currentEditingId = null;
        this.originalTitle = null;
    },

    async populateEditor(title) {
        const s = this.db.scripts[title];
        if (!s) return;
        
        this.currentEditingId = title;
        this.originalTitle = title;
        this.switchAdminTab('create');
        
        document.getElementById('editor-heading').textContent = `Edit: ${s.title}`;
        document.getElementById('edit-title').value = s.title;
        document.getElementById('edit-visibility').value = s.visibility || 'PUBLIC';
        document.getElementById('edit-desc').value = s.description || '';
        document.getElementById('edit-expire').value = s.expiration || '';
        
        const scriptId = utils.sanitizeTitle(title);
        
        try {
            const res = await fetch(`https://api.github.com/repos/${CONFIG.user}/${CONFIG.repo}/contents/scripts/${scriptId}/raw/${s.filename}`, {
                headers: this.token ? { 'Authorization': `token ${this.token}` } : {}
            });
            if (!res.ok) throw new Error();
            const data = await res.json();
            document.getElementById('edit-code').value = utils.safeAtob(data.content);
        } catch(e) { 
            document.getElementById('edit-code').value = "-- Error loading content"; 
        }
        
        document.getElementById('btn-delete').style.display = 'inline-flex';
    },

    async saveScript() {
        if (this.actionInProgress) return;
        this.actionInProgress = true;
        
        const title = document.getElementById('edit-title').value.trim();
        const visibility = document.getElementById('edit-visibility').value || 'PUBLIC';
        const desc = document.getElementById('edit-desc').value.trim();
        const expiration = document.getElementById('edit-expire').value;
        const code = document.getElementById('edit-code').value; 
        const msg = document.getElementById('admin-msg');
        
        if (!title || !code) { 
            msg.innerHTML = `<span style="color:var(--danger)">Title and Code required</span>`;
            setTimeout(() => { msg.innerHTML = ''; this.actionInProgress = false; }, 2000);
            return; 
        }
        
        const isNew = !this.currentEditingId;
        const isRename = !isNew && this.originalTitle && this.originalTitle !== title;
        
        if (this.db.scripts[title] && title !== this.originalTitle) {
            msg.innerHTML = `<span style="color:var(--danger)">Script with this title already exists</span>`;
            setTimeout(() => { msg.innerHTML = ''; this.actionInProgress = false; }, 2500);
            return;
        }
        
        const scriptId = utils.sanitizeTitle(title);
        const filename = scriptId + '.lua';
        
        msg.innerHTML = `<span class="loading">Publishing...</span>`;
        
        try {
            if (isRename) {
                await this.deleteScriptFiles(this.originalTitle);
                delete this.db.scripts[this.originalTitle];
            }
            
            let luaSha = null;
            const luaCheck = await fetch(`https://api.github.com/repos/${CONFIG.user}/${CONFIG.repo}/contents/scripts/${scriptId}/raw/${filename}`, {
                headers: { 'Authorization': `token ${this.token}` }
            });
            if (luaCheck.ok) {
                luaSha = (await luaCheck.json()).sha;
            }
            
            await fetch(`https://api.github.com/repos/${CONFIG.user}/${CONFIG.repo}/contents/scripts/${scriptId}/raw/${filename}`, {
                method: 'PUT',
                headers: { 'Authorization': `token ${this.token}`, 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    message: `${isNew ? 'Create' : 'Update'} script`,
                    content: utils.safeBtoa(code),
                    sha: luaSha
                })
            });

            const scriptData = {
                title: title,
                visibility: visibility,
                description: desc,
                expiration: expiration,
                filename: filename,
                created: isNew ? new Date().toISOString() : this.db.scripts[this.originalTitle || title]?.created || new Date().toISOString(),
                updated: new Date().toISOString()
            };
            
            this.db.scripts[title] = scriptData;
            
            await fetch(`https://api.github.com/repos/${CONFIG.user}/${CONFIG.repo}/contents/database.json`, {
                method: 'PUT',
                headers: { 'Authorization': `token ${this.token}`, 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    message: 'Update database',
                    content: utils.safeBtoa(JSON.stringify(this.db, null, 2)),
                    sha: this.dbSha
                })
            });

            const indexHTML = this.generateScriptHTML(title, scriptData);
            let indexSha = null;
            const indexCheck = await fetch(`https://api.github.com/repos/${CONFIG.user}/${CONFIG.repo}/contents/scripts/${scriptId}/index.html`, {
                headers: { 'Authorization': `token ${this.token}` }
            });
            if (indexCheck.ok) indexSha = (await indexCheck.json()).sha;
            
            await fetch(`https://api.github.com/repos/${CONFIG.user}/${CONFIG.repo}/contents/scripts/${scriptId}/index.html`, {
                method: 'PUT',
                headers: { 'Authorization': `token ${this.token}`, 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    message: 'Update index page',
                    content: utils.safeBtoa(indexHTML),
                    sha: indexSha
                })
            });
            
            await this.loadDatabase();
            this.resetEditor();
            msg.innerHTML = `<span style="color:var(--accent)">Published successfully!</span>`;
            setTimeout(() => { 
                msg.innerHTML = ''; 
                this.switchAdminTab('list'); 
                this.actionInProgress = false; 
            }, 1500);
        } catch(e) {
            msg.innerHTML = `<span style="color:red">Error: ${e.message}</span>`;
            this.actionInProgress = false;
        }
    },

    async deleteScriptFiles(title) {
        if (!title || !this.db.scripts[title]) return;
        const scriptId = utils.sanitizeTitle(title);
        const s = this.db.scripts[title];
        const filename = s.filename;
        
        try {
            const luaRes = await fetch(`https://api.github.com/repos/${CONFIG.user}/${CONFIG.repo}/contents/scripts/${scriptId}/raw/${filename}`, {
                headers: { 'Authorization': `token ${this.token}` }
            });
            if (luaRes.ok) {
                const sha = (await luaRes.json()).sha;
                await fetch(`https://api.github.com/repos/${CONFIG.user}/${CONFIG.repo}/contents/scripts/${scriptId}/raw/${filename}`, {
                    method: 'DELETE',
                    headers: { 'Authorization': `token ${this.token}`, 'Content-Type': 'application/json' },
                    body: JSON.stringify({ message: 'Delete lua file', sha })
                });
            }

            const idxRes = await fetch(`https://api.github.com/repos/${CONFIG.user}/${CONFIG.repo}/contents/scripts/${scriptId}/index.html`, {
                headers: { 'Authorization': `token ${this.token}` }
            });
            if (idxRes.ok) {
                const sha = (await idxRes.json()).sha;
                await fetch(`https://api.github.com/repos/${CONFIG.user}/${CONFIG.repo}/contents/scripts/${scriptId}/index.html`, {
                    method: 'DELETE',
                    headers: { 'Authorization': `token ${this.token}`, 'Content-Type': 'application/json' },
                    body: JSON.stringify({ message: 'Delete index file', sha })
                });
            }
        } catch(e) {
            console.error('Delete files error:', e);
        }
    },

    async deleteScript() {
        const title = this.currentEditingId;
        if (this.actionInProgress || !title) return;
        if (!confirm('Delete this script permanently?')) return;
        
        this.actionInProgress = true;
        const msg = document.getElementById('admin-msg');
        msg.innerHTML = `<span class="loading">Deleting...</span>`;
        
        try {
            await this.deleteScriptFiles(title);
            delete this.db.scripts[title];
            
            await fetch(`https://api.github.com/repos/${CONFIG.user}/${CONFIG.repo}/contents/database.json`, {
                method: 'PUT',
                headers: { 'Authorization': `token ${this.token}`, 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    message: 'Remove script from database',
                    content: utils.safeBtoa(JSON.stringify(this.db, null, 2)),
                    sha: this.dbSha
                })
            });
            
            await this.loadDatabase();
            this.resetEditor();
            this.switchAdminTab('list');
            msg.innerHTML = `<span style="color:var(--accent)">Deleted successfully</span>`;
            setTimeout(() => msg.innerHTML = '', 1500);
        } catch(e) {
            alert('Delete failed: ' + e.message);
            msg.innerHTML = '';
        } finally {
            this.actionInProgress = false;
        }
    },

    handleRouting() {
        const hash = location.hash.slice(1);
        document.querySelectorAll('.view-section').forEach(el => el.style.display = 'none');
        window.scrollTo(0, 0);
        
        if (hash === 'admin') {
            if (!this.currentUser) { location.hash = ''; return; }
            document.getElementById('view-admin').style.display = 'block';
            this.switchAdminTab('list');
        } else {
            document.getElementById('view-home').style.display = 'block';
        }
    }
};

function navigate(path) { location.hash = path; }
app.init();
