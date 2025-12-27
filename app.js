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
        const isEditing = !isNew;
        
        // Check for duplicate titles (only when not editing the same script)
        if (isNew && this.db.scripts[title]) {
            msg.innerHTML = `<span style="color:var(--danger)">Script with this title already exists</span>`;
            setTimeout(() => { msg.innerHTML = ''; this.actionInProgress = false; }, 2500);
            return;
        }
        
        // If editing and title changed, check for duplicates
        if (isEditing && this.originalTitle !== title && this.db.scripts[title]) {
            msg.innerHTML = `<span style="color:var(--danger)">A script with this new title already exists</span>`;
            setTimeout(() => { msg.innerHTML = ''; this.actionInProgress = false; }, 2500);
            return;
        }
        
        const scriptId = utils.sanitizeTitle(title);
        const oldScriptId = this.originalTitle ? utils.sanitizeTitle(this.originalTitle) : null;
        const filename = scriptId + '.lua';
        const titleChanged = isEditing && this.originalTitle !== title;
        const folderChanged = isEditing && oldScriptId !== scriptId;
        
        msg.innerHTML = `<span class="loading">Publishing...</span>`;
        
        try {
            // Step 1: Handle file operations
            if (folderChanged) {
                // If folder changes, we need to delete old files
                await this.deleteScriptFiles(this.originalTitle);
            }
            
            // Step 2: Upload/Update lua file
            let luaSha = null;
            const luaCheckRes = await fetch(`https://api.github.com/repos/${CONFIG.user}/${CONFIG.repo}/contents/scripts/${scriptId}/raw/${filename}`, {
                headers: { 'Authorization': `token ${this.token}` }
            });
            
            if (luaCheckRes.ok) {
                const luaData = await luaCheckRes.json();
                luaSha = luaData.sha;
            }
            
            const luaUploadRes = await fetch(`https://api.github.com/repos/${CONFIG.user}/${CONFIG.repo}/contents/scripts/${scriptId}/raw/${filename}`, {
                method: 'PUT',
                headers: { 'Authorization': `token ${this.token}`, 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    message: `${isNew ? 'Create' : 'Update'} ${title}`,
                    content: utils.safeBtoa(code),
                    sha: luaSha
                })
            });
            
            if (!luaUploadRes.ok) {
                const errorData = await luaUploadRes.json();
                throw new Error(`Failed to upload lua file: ${errorData.message || luaUploadRes.statusText}`);
            }
            
            // Step 3: Prepare script data
            const scriptData = {
                title: title,
                visibility: visibility,
                description: desc,
                expiration: expiration,
                filename: filename,
                created: isEditing && this.db.scripts[this.originalTitle] 
                    ? this.db.scripts[this.originalTitle].created 
                    : new Date().toISOString(),
                updated: new Date().toISOString()
            };
            
            // Step 4: Update database
            // Remove old entry if title changed
            if (titleChanged && this.originalTitle in this.db.scripts) {
                delete this.db.scripts[this.originalTitle];
            }
            
            // Add/update new entry
            this.db.scripts[title] = scriptData;
            
            // Step 5: Push database changes to GitHub
            const dbUpdateRes = await fetch(`https://api.github.com/repos/${CONFIG.user}/${CONFIG.repo}/contents/database.json`, {
                method: 'PUT',
                headers: { 'Authorization': `token ${this.token}`, 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    message: `Update database for ${title}`,
                    content: utils.safeBtoa(JSON.stringify(this.db, null, 2)),
                    sha: this.dbSha
                })
            });
            
            if (!dbUpdateRes.ok) {
                const errorData = await dbUpdateRes.json();
                throw new Error(`Failed to update database: ${errorData.message || dbUpdateRes.statusText}`);
            }
            
            const dbUpdateData = await dbUpdateRes.json();
            this.dbSha = dbUpdateData.content.sha;
            
            // Step 6: Create/Update index.html
            const indexHTML = this.generateScriptHTML(title, scriptData);
            let indexSha = null;
            
            const indexCheckRes = await fetch(`https://api.github.com/repos/${CONFIG.user}/${CONFIG.repo}/contents/scripts/${scriptId}/index.html`, {
                headers: { 'Authorization': `token ${this.token}` }
            });
            
            if (indexCheckRes.ok) {
                const indexData = await indexCheckRes.json();
                indexSha = indexData.sha;
            }
            
            const indexUploadRes = await fetch(`https://api.github.com/repos/${CONFIG.user}/${CONFIG.repo}/contents/scripts/${scriptId}/index.html`, {
                method: 'PUT',
                headers: { 'Authorization': `token ${this.token}`, 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    message: `Update index for ${title}`,
                    content: utils.safeBtoa(indexHTML),
                    sha: indexSha
                })
            });
            
            if (!indexUploadRes.ok) {
                const errorData = await indexUploadRes.json();
                throw new Error(`Failed to update index: ${errorData.message || indexUploadRes.statusText}`);
            }
            
            // Step 7: Reload and show success
            await this.loadDatabase();
            this.resetEditor();
            msg.innerHTML = `<span style="color:var(--accent)">✓ Published successfully!</span>`;
            setTimeout(() => { 
                msg.innerHTML = ''; 
                this.switchAdminTab('list'); 
            }, 1500);
            
        } catch(e) {
            console.error('Save error:', e);
            msg.innerHTML = `<span style="color:red">Error: ${e.message}</span>`;
            setTimeout(() => msg.innerHTML = '', 4000);
        } finally {
            this.actionInProgress = false;
        }
    },

    async deleteScriptFiles(title) {
        if (!title || !this.db.scripts[title]) {
            console.log('Cannot delete: title or script not found');
            return;
        }
        
        const scriptId = utils.sanitizeTitle(title);
        const s = this.db.scripts[title];
        const filename = s.filename;
        
        console.log(`Deleting files for: ${title} (ID: ${scriptId})`);
        
        const errors = [];
        
        // Delete lua file
        try {
            const luaRes = await fetch(`https://api.github.com/repos/${CONFIG.user}/${CONFIG.repo}/contents/scripts/${scriptId}/raw/${filename}`, {
                headers: { 'Authorization': `token ${this.token}` }
            });
            
            if (luaRes.ok) {
                const luaData = await luaRes.json();
                const deleteRes = await fetch(`https://api.github.com/repos/${CONFIG.user}/${CONFIG.repo}/contents/scripts/${scriptId}/raw/${filename}`, {
                    method: 'DELETE',
                    headers: { 'Authorization': `token ${this.token}`, 'Content-Type': 'application/json' },
                    body: JSON.stringify({ 
                        message: `Delete ${filename}`, 
                        sha: luaData.sha 
                    })
                });
                
                if (!deleteRes.ok) {
                    const errData = await deleteRes.json();
                    errors.push(`Lua file: ${errData.message}`);
                } else {
                    console.log('Lua file deleted successfully');
                }
            } else {
                console.log('Lua file not found, skipping');
            }
        } catch(e) {
            console.error('Error deleting lua file:', e);
            errors.push(`Lua file: ${e.message}`);
        }
        
        // Delete index.html
        try {
            const indexRes = await fetch(`https://api.github.com/repos/${CONFIG.user}/${CONFIG.repo}/contents/scripts/${scriptId}/index.html`, {
                headers: { 'Authorization': `token ${this.token}` }
            });
            
            if (indexRes.ok) {
                const indexData = await indexRes.json();
                const deleteRes = await fetch(`https://api.github.com/repos/${CONFIG.user}/${CONFIG.repo}/contents/scripts/${scriptId}/index.html`, {
                    method: 'DELETE',
                    headers: { 'Authorization': `token ${this.token}`, 'Content-Type': 'application/json' },
                    body: JSON.stringify({ 
                        message: `Delete index for ${title}`, 
                        sha: indexData.sha 
                    })
                });
                
                if (!deleteRes.ok) {
                    const errData = await deleteRes.json();
                    errors.push(`Index file: ${errData.message}`);
                } else {
                    console.log('Index file deleted successfully');
                }
            } else {
                console.log('Index file not found, skipping');
            }
        } catch(e) {
            console.error('Error deleting index file:', e);
            errors.push(`Index file: ${e.message}`);
        }
        
        if (errors.length > 0) {
            throw new Error(`File deletion errors: ${errors.join(', ')}`);
        }
    },

    async deleteScript() {
        if (this.actionInProgress) {
            console.log('Action already in progress, ignoring delete request');
            return;
        }
        
        const title = this.currentEditingId;
        
        if (!title) {
            alert('No script selected for deletion');
            return;
        }
        
        if (!this.db.scripts[title]) {
            alert('Script not found in database');
            return;
        }
        
        if (!confirm(`Are you sure you want to permanently delete "${title}"?`)) {
            return;
        }
        
        this.actionInProgress = true;
        const msg = document.getElementById('admin-msg');
        msg.innerHTML = `<span class="loading">Deleting script...</span>`;
        
        console.log(`Starting deletion of: ${title}`);
        
        try {
            // Step 1: Delete the files from GitHub
            console.log('Step 1: Deleting files...');
            await this.deleteScriptFiles(title);
            console.log('Files deleted successfully');
            
            // Step 2: Remove from local database object
            console.log('Step 2: Removing from database...');
            delete this.db.scripts[title];
            
            // Step 3: Update database.json on GitHub
            console.log('Step 3: Updating database.json...');
            const dbUpdateRes = await fetch(`https://api.github.com/repos/${CONFIG.user}/${CONFIG.repo}/contents/database.json`, {
                method: 'PUT',
                headers: { 'Authorization': `token ${this.token}`, 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    message: `Delete script: ${title}`,
                    content: utils.safeBtoa(JSON.stringify(this.db, null, 2)),
                    sha: this.dbSha
                })
            });
            
            if (!dbUpdateRes.ok) {
                const errorData = await dbUpdateRes.json();
                throw new Error(`Database update failed: ${errorData.message || dbUpdateRes.statusText}`);
            }
            
            const dbUpdateData = await dbUpdateRes.json();
            this.dbSha = dbUpdateData.content.sha;
            console.log('Database updated, new SHA:', this.dbSha);
            
            // Step 4: Reload database and UI
            console.log('Step 4: Reloading interface...');
            await this.loadDatabase();
            this.resetEditor();
            this.switchAdminTab('list');
            
            msg.innerHTML = `<span style="color:var(--accent)">✓ Script deleted successfully!</span>`;
            console.log('Deletion complete!');
            
            setTimeout(() => {
                msg.innerHTML = '';
            }, 2000);
            
        } catch(e) {
            console.error('Delete error:', e);
            msg.innerHTML = `<span style="color:red">Error: ${e.message}</span>`;
            setTimeout(() => {
                msg.innerHTML = '';
            }, 4000);
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
