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
        return window.btoa(unescape(encodeURIComponent(str)));
    },
    
    safeAtob(str) {
        return decodeURIComponent(escape(window.atob(str)));
    },

    sanitizeTitle(title) {
        return title.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-+|-+$/g, '');
    },

    escapeHtml(text) {
        const div = document.createElement('div');
        div.textContent = text;
        return div.innerHTML;
    },

    validateTitle(title) {
        if (!title || title.trim().length === 0) return 'Title is required';
        if (title.length > 100) return 'Title must be less than 100 characters';
        if (!/^[a-zA-Z0-9\s\-_]+$/.test(title)) return 'Title can only contain letters, numbers, spaces, hyphens, and underscores';
        return null;
    },

    validateCode(code) {
        if (!code || code.trim().length === 0) return 'Code is required';
        if (code.length > 100000) return 'Code is too large (max 100KB)';
        return null;
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
        
        this.debouncedRender = utils.debounce(() => this.renderList(), 300);
        this.debouncedSave = utils.debounce(() => this.saveScript(), 750);
        this.debouncedLogin = utils.debounce(() => this.login(), 750);
        this.debouncedToggleLogin = utils.debounce(() => this.toggleLoginModal(), 200);
        
        const today = new Date().toISOString().split('T')[0];
        document.getElementById('edit-expire').min = today;
    },

    generateScriptHTML(title, scriptData) {
        const scriptId = utils.sanitizeTitle(title);
        
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

        ${scriptData.description ? `<p class="script-desc">${utils.escapeHtml(scriptData.description)}</p>` : ''}
        
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
        
        try {
            const token = document.getElementById('auth-token').value.trim();
            if (!token) return;
            
            this.token = token;
            const success = await this.verifyToken(false);
            if (success) {
                localStorage.setItem('gh_token', token);
                this.toggleLoginModal();
                await this.loadDatabase();
                this.renderList();
            }
        } finally {
            this.actionInProgress = false;
        }
    },

    logout() {
        if (confirm('Are you sure you want to logout?')) {
            localStorage.removeItem('gh_token');
            this.token = null;
            this.currentUser = null;
            document.getElementById('auth-section').style.display = 'block';
            document.getElementById('user-section').style.display = 'none';
            document.getElementById('private-filter').style.display = 'none';
            document.getElementById('unlisted-filter').style.display = 'none';
            location.href = '#';
            location.reload();
        }
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
            document.getElementById('unlisted-filter').style.display = 'block';
            return true;
        } catch (e) {
            if (!silent) {
                const err = document.getElementById('login-error');
                err.textContent = e.message;
                err.style.display = 'block';
            }
            this.token = null;
            localStorage.removeItem('gh_token');
            return false;
        }
    },

    async loadDatabase() {
        try {
            const list = document.getElementById('admin-list');
            if (list) {
                list.innerHTML = `<div style="text-align:center;padding:20px"><div class="spinner"></div><p>Loading scripts...</p></div>`;
            }
            
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
            } else {
                throw new Error(`Failed to load database: ${res.status}`);
            }
            this.renderList();
            this.renderAdminList();
        } catch (e) { 
            console.error("DB Error", e);
            const list = document.getElementById('admin-list');
            if (list) {
                list.innerHTML = `<div class="empty-admin-state">
                    <p style="color:var(--color-danger)">Error loading scripts: ${e.message}</p>
                    <button class="btn btn-sm" onclick="app.loadDatabase()" style="margin-top:10px">Retry</button>
                </div>`;
            }
        }
    },

    renderList() {
        const list = document.getElementById('script-list');
        const scripts = Object.entries(this.db.scripts || {}).map(([title, data]) => ({ title, ...data }));
        const filtered = this.filterLogic(scripts);
        const sorted = this.sortLogic(filtered);
        
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

    filterLogic(scripts) {
        const query = document.getElementById('search').value.toLowerCase();
        const now = new Date();
        
        return scripts.filter(s => {
            if (!s.title.toLowerCase().includes(query)) return false;
            if (s.visibility === 'PRIVATE' && !this.currentUser) return false;
            if (s.visibility === 'UNLISTED' && !this.currentUser) return false; 
            if (this.currentFilter === 'private' && s.visibility !== 'PRIVATE') return false;
            if (this.currentFilter === 'public' && s.visibility !== 'PUBLIC') return false;
            if (this.currentFilter === 'unlisted' && s.visibility !== 'UNLISTED') return false;
            if (s.expiration && new Date(s.expiration) < now) return false;
            return true;
        });
    },

    sortLogic(scripts) {
        return scripts.sort((a, b) => {
            if (this.currentSort === 'newest') return new Date(b.created || 0) - new Date(a.created || 0);
            if (this.currentSort === 'oldest') return new Date(a.created || 0) - new Date(b.created || 0);
            if (this.currentSort === 'alpha') return a.title.localeCompare(b.title);
            if (this.currentSort === 'updated') return new Date(b.updated || b.created || 0) - new Date(a.updated || a.created || 0);
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
        } else if (tab === 'stats') {
            document.getElementById('admin-tab-stats').style.display = 'block';
            document.querySelectorAll('.tab-btn')[2].classList.add('active');
            this.renderStats();
        } else {
            document.getElementById('admin-tab-editor').style.display = 'block';
            document.querySelectorAll('.tab-btn')[1].classList.add('active');
            this.resetEditor();
        }
    },

    async renderAdminList() {
        const list = document.getElementById('admin-list');
        const scripts = Object.entries(this.db.scripts || {}).map(([title, data]) => ({ title, ...data }));
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
            <div class="admin-item" onclick="app.populateEditor('${s.title.replace(/'/g, "\\'")}')">
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
        const scripts = Object.entries(this.db.scripts || {}).map(([title, data]) => ({ title, ...data }));
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

    resetEditor() {
        document.getElementById('editor-heading').textContent = 'Create New Script';
        document.getElementById('edit-title').value = '';
        document.getElementById('edit-visibility').value = 'PUBLIC';
        document.getElementById('edit-desc').value = '';
        document.getElementById('edit-expire').value = '';
        document.getElementById('edit-code').value = '';
        document.getElementById('btn-delete').style.display = 'none';
        document.getElementById('admin-msg').innerHTML = '';
        
        const viewBtn = document.querySelector('.btn-view-script');
        if (viewBtn) viewBtn.remove();
        
        this.currentEditingId = null;
        this.originalTitle = null;
    },

    async populateEditor(title) {
        const s = this.db.scripts[title];
        if (!s) return;
        
        this.currentEditingId = title;
        this.originalTitle = title;
        this.switchAdminTab('create');
        
        document.getElementById('editor-heading').textContent = `Edit: ${title}`;
        document.getElementById('edit-title').value = s.title;
        document.getElementById('edit-visibility').value = s.visibility;
        document.getElementById('edit-desc').value = s.description || '';
        document.getElementById('edit-expire').value = s.expiration || '';
        
        const scriptId = utils.sanitizeTitle(title);
        
        try {
            const res = await fetch(`https://api.github.com/repos/${CONFIG.user}/${CONFIG.repo}/contents/scripts/${scriptId}/raw/${s.filename}`, {
                headers: this.token ? { 'Authorization': `token ${this.token}` } : {}
            });
            
            if (res.ok) {
                const data = await res.json();
                document.getElementById('edit-code').value = utils.safeAtob(data.content);
            } else {
                document.getElementById('edit-code').value = '-- Error loading content';
            }
        } catch(e) { 
            document.getElementById('edit-code').value = '-- Error loading content'; 
        }
        
        document.getElementById('btn-delete').style.display = 'inline-flex';
        
        const viewBtn = document.querySelector('.btn-view-script');
        if (!viewBtn) {
            const actionButtons = document.querySelector('.action-buttons');
            const newViewBtn = document.createElement('a');
            newViewBtn.href = `scripts/${scriptId}/index.html`;
            newViewBtn.target = '_blank';
            newViewBtn.className = 'btn btn-secondary btn-view-script';
            newViewBtn.innerHTML = `
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <path d="M18 13v6a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h6"></path>
                    <polyline points="15 3 21 3 21 9"></polyline>
                    <line x1="10" y1="14" x2="21" y2="3"></line>
                </svg>
                View Script
            `;
            actionButtons.appendChild(newViewBtn);
        }
    },

    async saveScript() {
        if (this.actionInProgress) return;
        this.actionInProgress = true;
        
        const title = document.getElementById('edit-title').value.trim();
        const visibility = document.getElementById('edit-visibility').value;
        const desc = document.getElementById('edit-desc').value.trim();
        const expiration = document.getElementById('edit-expire').value;
        const code = document.getElementById('edit-code').value; 
        const msg = document.getElementById('admin-msg');
        const saveBtn = document.querySelector('.editor-actions .btn:last-child');
        const originalBtnText = saveBtn.textContent;
        
        const titleError = utils.validateTitle(title);
        const codeError = utils.validateCode(code);
        
        if (titleError || codeError) { 
            msg.innerHTML = `<span style="color:var(--color-danger)">${titleError || codeError}</span>`;
            setTimeout(() => { msg.innerHTML = ''; this.actionInProgress = false; }, 3000);
            return; 
        }
        
        if (expiration && new Date(expiration) < new Date()) {
            msg.innerHTML = `<span style="color:var(--color-danger)">Expiration date cannot be in the past</span>`;
            setTimeout(() => { msg.innerHTML = ''; this.actionInProgress = false; }, 3000);
            return;
        }
        
        const isEditing = !!this.currentEditingId;
        const titleChanged = isEditing && this.originalTitle !== title;
        const scriptId = utils.sanitizeTitle(title);
        const filename = scriptId + '.lua';
        
        saveBtn.disabled = true;
        saveBtn.textContent = 'Publishing...';
        
        if (this.db.scripts[title] && title !== this.originalTitle) {
            msg.innerHTML = `<span style="color:var(--color-danger)">Script with this title already exists</span>`;
            saveBtn.disabled = false;
            saveBtn.textContent = originalBtnText;
            setTimeout(() => { msg.innerHTML = ''; this.actionInProgress = false; }, 3000);
            return;
        }
        
        msg.innerHTML = `<span class="loading">Publishing...</span>`;
        
        try {
            if (titleChanged && this.originalTitle) {
                await this.deleteScriptFiles(this.originalTitle);
            }
            
            let luaSha = null;
            const luaPath = `scripts/${scriptId}/raw/${filename}`;
            
            if (isEditing && !titleChanged) {
                try {
                    const check = await fetch(`https://api.github.com/repos/${CONFIG.user}/${CONFIG.repo}/contents/${luaPath}`, {
                        headers: { 'Authorization': `token ${this.token}` }
                    });
                    if (check.ok) {
                        luaSha = (await check.json()).sha;
                    }
                } catch(e) {
                    console.log('Creating new Lua file');
                }
            }
            
            const luaRes = await fetch(`https://api.github.com/repos/${CONFIG.user}/${CONFIG.repo}/contents/${luaPath}`, {
                method: 'PUT',
                headers: { 'Authorization': `token ${this.token}`, 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    message: `${isEditing ? 'Update' : 'Create'} ${filename}`,
                    content: utils.safeBtoa(code),
                    sha: luaSha || undefined
                })
            });
            
            if (!luaRes.ok) {
                throw new Error('Failed to save Lua file');
            }

            const scriptData = {
                title: title, 
                visibility: visibility, 
                description: desc, 
                expiration: expiration,
                filename: filename,
                size: code.length,
                created: (isEditing && !titleChanged && this.db.scripts[this.originalTitle]) ? this.db.scripts[this.originalTitle].created : new Date().toISOString(),
                updated: new Date().toISOString()
            };
            
            if (titleChanged && this.originalTitle) {
                delete this.db.scripts[this.originalTitle];
            }
            
            this.db.scripts[title] = scriptData;
            
            const dbRes = await fetch(`https://api.github.com/repos/${CONFIG.user}/${CONFIG.repo}/contents/database.json`, {
                method: 'PUT',
                headers: { 'Authorization': `token ${this.token}`, 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    message: `${isEditing ? 'Update' : 'Add'} ${title}`,
                    content: utils.safeBtoa(JSON.stringify(this.db, null, 2)),
                    sha: this.dbSha
                })
            });
            
            if (!dbRes.ok) {
                throw new Error('Failed to update database');
            }
            
            const newDbData = await dbRes.json();
            this.dbSha = newDbData.content.sha;

            const indexHTML = this.generateScriptHTML(title, scriptData);
            let indexSha = null;
            const indexPath = `scripts/${scriptId}/index.html`;
            
            if (isEditing && !titleChanged) {
                try {
                    const check = await fetch(`https://api.github.com/repos/${CONFIG.user}/${CONFIG.repo}/contents/${indexPath}`, {
                        headers: { 'Authorization': `token ${this.token}` }
                    });
                    if (check.ok) {
                        indexSha = (await check.json()).sha;
                    }
                } catch(e) {
                    console.log('Creating new index file');
                }
            }
            
            const indexRes = await fetch(`https://api.github.com/repos/${CONFIG.user}/${CONFIG.repo}/contents/${indexPath}`, {
                method: 'PUT',
                headers: { 'Authorization': `token ${this.token}`, 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    message: `${isEditing ? 'Update' : 'Create'} index for ${title}`,
                    content: utils.safeBtoa(indexHTML),
                    sha: indexSha || undefined
                })
            });
            
            if (!indexRes.ok) {
                throw new Error('Failed to save index.html');
            }
            
            msg.innerHTML = `<span style="color:var(--color-primary)">Published successfully!</span>`;
            
            const actionButtons = document.querySelector('.action-buttons');
            const viewBtn = actionButtons.querySelector('.btn-view-script');
            if (!viewBtn) {
                const newViewBtn = document.createElement('a');
                newViewBtn.href = `scripts/${scriptId}/index.html`;
                newViewBtn.target = '_blank';
                newViewBtn.className = 'btn btn-secondary btn-view-script';
                newViewBtn.innerHTML = `
                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                        <path d="M18 13v6a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h6"></path>
                        <polyline points="15 3 21 3 21 9"></polyline>
                        <line x1="10" y1="14" x2="21" y2="3"></line>
                    </svg>
                    View Script
                `;
                actionButtons.appendChild(newViewBtn);
            }
            
        } catch(e) {
            msg.innerHTML = `<span style="color:var(--color-danger)">Error: ${e.message}</span>`;
            console.error('Save error:', e);
        } finally {
            saveBtn.disabled = false;
            saveBtn.textContent = originalBtnText;
            this.actionInProgress = false;
        }
    },

    async deleteScriptFiles(title) {
        if (!title) return;
        
        const scriptId = utils.sanitizeTitle(title);
        const s = this.db.scripts[title];
        if (!s) return;
        
        const filesToDelete = [
            `scripts/${scriptId}/raw/${s.filename}`,
            `scripts/${scriptId}/index.html`
        ];
        
        for (const path of filesToDelete) {
            try {
                const res = await fetch(`https://api.github.com/repos/${CONFIG.user}/${CONFIG.repo}/contents/${path}`, {
                    headers: { 'Authorization': `token ${this.token}` }
                });
                
                if (res.ok) {
                    const data = await res.json();
                    await fetch(`https://api.github.com/repos/${CONFIG.user}/${CONFIG.repo}/contents/${path}`, {
                        method: 'DELETE',
                        headers: { 'Authorization': `token ${this.token}`, 'Content-Type': 'application/json' },
                        body: JSON.stringify({ 
                            message: `Delete ${path.split('/').pop()}`, 
                            sha: data.sha 
                        })
                    });
                }
            } catch(e) {
                console.warn(`Failed to delete ${path}:`, e.message);
            }
        }
    },

    async deleteScript(title) {
        if (this.actionInProgress) return;
        
        if (!title || !this.db.scripts[title]) {
            alert('Script not found or already deleted');
            this.switchAdminTab('list');
            return;
        }

        const scriptName = document.getElementById('edit-title').value || title;
        const confirmText = prompt(`Type "${scriptName}" to confirm deletion:\n\nThis will permanently delete the script, Lua file, and HTML page.`, '');
        
        if (confirmText !== scriptName) {
            alert('Deletion cancelled. Script names did not match.');
            return;
        }
        
        this.actionInProgress = true;
        const msg = document.getElementById('admin-msg');
        msg.innerHTML = `<span class="loading">Deleting...</span>`;
        
        try {
            const scriptId = utils.sanitizeTitle(title);
            const scriptData = this.db.scripts[title];
            
            const luaPath = `scripts/${scriptId}/raw/${scriptData.filename}`;
            try {
                const luaRes = await fetch(`https://api.github.com/repos/${CONFIG.user}/${CONFIG.repo}/contents/${luaPath}`, {
                    headers: { 'Authorization': `token ${this.token}` }
                });
                
                if (luaRes.ok) {
                    const luaData = await luaRes.json();
                    await fetch(`https://api.github.com/repos/${CONFIG.user}/${CONFIG.repo}/contents/${luaPath}`, {
                        method: 'DELETE',
                        headers: { 'Authorization': `token ${this.token}`, 'Content-Type': 'application/json' },
                        body: JSON.stringify({ 
                            message: `Delete ${scriptData.filename}`, 
                            sha: luaData.sha 
                        })
                    });
                }
            } catch(e) {
                console.warn('Lua file deletion error:', e.message);
            }

            const indexPath = `scripts/${scriptId}/index.html`;
            try {
                const idxRes = await fetch(`https://api.github.com/repos/${CONFIG.user}/${CONFIG.repo}/contents/${indexPath}`, {
                    headers: { 'Authorization': `token ${this.token}` }
                });
                
                if (idxRes.ok) {
                    const idxData = await idxRes.json();
                    await fetch(`https://api.github.com/repos/${CONFIG.user}/${CONFIG.repo}/contents/${indexPath}`, {
                        method: 'DELETE',
                        headers: { 'Authorization': `token ${this.token}`, 'Content-Type': 'application/json' },
                        body: JSON.stringify({ 
                            message: `Delete index for ${title}`, 
                            sha: idxData.sha 
                        })
                    });
                }
            } catch(e) {
                console.warn('Index file deletion error:', e.message);
            }
            
            delete this.db.scripts[title];
            
            const dbRes = await fetch(`https://api.github.com/repos/${CONFIG.user}/${CONFIG.repo}/contents/database.json`, {
                method: 'PUT',
                headers: { 'Authorization': `token ${this.token}`, 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    message: `Remove ${title} from database`,
                    content: utils.safeBtoa(JSON.stringify(this.db, null, 2)),
                    sha: this.dbSha
                })
            });
            
            if (dbRes.ok) {
                const newDbData = await dbRes.json();
                this.dbSha = newDbData.content.sha;
                
                msg.innerHTML = `<span style="color:var(--color-primary)">Deleted successfully!</span>`;
                setTimeout(() => { 
                    msg.innerHTML = '';
                    this.switchAdminTab('list'); 
                }, 1500);
                
                await this.loadDatabase();
            } else {
                throw new Error('Failed to update database');
            }
            
        } catch(e) {
            msg.innerHTML = `<span style="color:var(--color-danger)">Delete failed: ${e.message}</span>`;
            console.error('Delete error:', e);
        } finally {
            this.actionInProgress = false;
        }
    },

    handleDelete() {
        if (this.currentEditingId) {
            this.deleteScript(this.currentEditingId);
        }
    },

    handleRouting() {
        const hash = location.hash.slice(1);
        document.querySelectorAll('.view-section').forEach(el => el.style.display = 'none');
        window.scrollTo(0, 0);
        
        if (hash === 'admin') {
            if (!this.currentUser) { 
                location.hash = ''; 
                return; 
            }
            document.getElementById('view-admin').style.display = 'block';
            this.switchAdminTab('list');
        } else {
            document.getElementById('view-home').style.display = 'block';
        }
    }
};

function navigate(path) { 
    location.hash = path; 
}

app.init();
