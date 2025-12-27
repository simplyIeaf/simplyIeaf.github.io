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
        try {
            return decodeURIComponent(escape(window.atob(str)));
        } catch(e) {
            return window.atob(str);
        }
    },

    sanitizeTitle(title) {
        return title.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-+|-+$/g, '');
    },

    escapeHtml(text) {
        const div = document.createElement('div');
        div.textContent = text;
        return div.innerHTML;
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
    
    async init() {
        this.setupListeners();
        
        if (this.token) {
            await this.verifyToken(true);
        }
        await this.loadDatabase();
        this.handleRouting();
        window.addEventListener('hashchange', () => this.handleRouting());
        this.debouncedRender = utils.debounce(() => this.renderList(), 300);
    },

    setupListeners() {
        document.addEventListener('click', (e) => {
            const target = e.target.closest('[data-action]');
            if (!target) return;
            
            const action = target.dataset.action;
            const param = target.dataset.param;
            
            e.preventDefault();
            e.stopPropagation();
            
            console.log('Action triggered:', action, 'Param:', param);
            
            switch(action) {
                case 'navigate':
                    window.location.hash = param || '';
                    break;
                case 'login-modal':
                    this.toggleLoginModal();
                    break;
                case 'login':
                    this.login();
                    break;
                case 'logout':
                    this.logout();
                    break;
                case 'filter':
                    this.filterCategory(param, e);
                    break;
                case 'admin-tab':
                    this.switchAdminTab(param);
                    break;
                case 'save-script':
                    this.saveScript();
                    break;
                case 'delete-script':
                    console.log('Delete script triggered for:', this.currentEditingId);
                    this.deleteScript();
                    break;
                case 'edit-script':
                    this.populateEditor(param);
                    break;
                case 'view-script':
                    window.location.href = `scripts/${utils.sanitizeTitle(param)}/index.html`;
                    break;
            }
        });

        const searchInput = document.getElementById('search');
        if (searchInput) {
            searchInput.addEventListener('input', () => this.debouncedRender());
        }

        const sortSelect = document.querySelector('.sidebar-sort select');
        if (sortSelect) {
            sortSelect.addEventListener('change', (e) => this.setSort(e.target.value));
        }

        const modalOverlay = document.getElementById('login-modal');
        if (modalOverlay) {
            modalOverlay.addEventListener('click', (e) => {
                if (e.target === modalOverlay) {
                    this.toggleLoginModal();
                }
            });
        }
    },

    getHeaders() {
        const headers = {
            'Accept': 'application/vnd.github.v3+json',
            'Content-Type': 'application/json'
        };
        if (this.token) {
            headers['Authorization'] = `token ${this.token}`;
        }
        return headers;
    },

    async verifyToken(silent) {
        try {
            const res = await fetch('https://api.github.com/user', {
                headers: this.getHeaders()
            });
            if (!res.ok) throw new Error('Invalid token');
            const user = await res.json();
            if (user.login.toLowerCase() !== CONFIG.user.toLowerCase()) {
                throw new Error(`Unauthorized user.`);
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
            localStorage.removeItem('gh_token');
            return false;
        }
    },

    async login() {
        if (this.actionInProgress) return;
        this.actionInProgress = true;
        try {
            const tokenInput = document.getElementById('auth-token');
            const token = tokenInput.value.trim();
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
            window.location.hash = '';
            location.reload();
        }
    },

    async loadDatabase() {
        try {
            const res = await fetch(`https://api.github.com/repos/${CONFIG.user}/${CONFIG.repo}/contents/database.json?t=${CONFIG.cacheBuster()}`, {
                headers: this.getHeaders()
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
            console.error("Database Load Error", e); 
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
        
        if (!title || !code) { 
            msg.innerHTML = `<span style="color:var(--danger)">Title and Code are required</span>`;
            this.actionInProgress = false;
            return; 
        }

        msg.innerHTML = `<span class="loading">Saving to GitHub...</span>`;
        
        try {
            const scriptId = utils.sanitizeTitle(title);
            const filename = scriptId + '.lua';

            if (this.currentEditingId && this.currentEditingId !== title) {
                await this.deleteScriptFiles(this.currentEditingId);
                delete this.db.scripts[this.currentEditingId];
            }

            const luaPath = `scripts/${scriptId}/raw/${filename}`;
            let existingSha = null;
            try {
                const check = await fetch(`https://api.github.com/repos/${CONFIG.user}/${CONFIG.repo}/contents/${luaPath}`, { headers: this.getHeaders() });
                if (check.ok) existingSha = (await check.json()).sha;
            } catch(e) {}

            await fetch(`https://api.github.com/repos/${CONFIG.user}/${CONFIG.repo}/contents/${luaPath}`, {
                method: 'PUT',
                headers: this.getHeaders(),
                body: JSON.stringify({
                    message: `Upload ${filename}`,
                    content: utils.safeBtoa(code),
                    sha: existingSha || undefined
                })
            });

            const scriptData = {
                title, visibility, description: desc, expiration, filename,
                created: (this.db.scripts[title]) ? this.db.scripts[title].created : new Date().toISOString(),
                updated: new Date().toISOString()
            };
            this.db.scripts[title] = scriptData;

            const indexHTML = this.generateScriptHTML(title, scriptData);
            const indexPath = `scripts/${scriptId}/index.html`;
            let indexSha = null;
            try {
                const check = await fetch(`https://api.github.com/repos/${CONFIG.user}/${CONFIG.repo}/contents/${indexPath}`, { headers: this.getHeaders() });
                if (check.ok) indexSha = (await check.json()).sha;
            } catch(e) {}

            await fetch(`https://api.github.com/repos/${CONFIG.user}/${CONFIG.repo}/contents/${indexPath}`, {
                method: 'PUT',
                headers: this.getHeaders(),
                body: JSON.stringify({
                    message: `Update Index HTML`,
                    content: utils.safeBtoa(indexHTML),
                    sha: indexSha || undefined
                })
            });

            const dbUpdate = await fetch(`https://api.github.com/repos/${CONFIG.user}/${CONFIG.repo}/contents/database.json`, {
                method: 'PUT',
                headers: this.getHeaders(),
                body: JSON.stringify({
                    message: `Update Database Registry`,
                    content: utils.safeBtoa(JSON.stringify(this.db, null, 2)),
                    sha: this.dbSha
                })
            });
            const dbData = await dbUpdate.json();
            this.dbSha = dbData.content.sha;

            msg.innerHTML = `<span style="color:var(--accent)">Successfully Published!</span>`;
            setTimeout(() => { 
                this.switchAdminTab('list'); 
                this.actionInProgress = false; 
            }, 1500);
        } catch(e) {
            msg.innerHTML = `<span style="color:red">Error: ${e.message}</span>`;
            this.actionInProgress = false;
        }
    },

    async deleteScript() {
        if (this.actionInProgress) {
            console.log('Action already in progress, skipping delete');
            return;
        }
        
        if (!this.currentEditingId) {
            console.log('No script selected for deletion');
            alert('No script selected for deletion');
            return;
        }

        const titleToDelete = this.currentEditingId;
        
        if (!confirm(`Are you sure you want to delete "${titleToDelete}"? This cannot be undone.`)) {
            console.log('Delete cancelled by user');
            return;
        }

        this.actionInProgress = true;
        const msg = document.getElementById('admin-msg');
        msg.innerHTML = `<span class="loading">Deleting "${titleToDelete}"...</span>`;

        try {
            const scriptId = utils.sanitizeTitle(titleToDelete);
            const script = this.db.scripts[titleToDelete];
            
            console.log('Deleting script:', titleToDelete, 'ID:', scriptId, 'Script data:', script);
            
            if (!script) {
                throw new Error('Script not found in database');
            }

            const filesToDelete = [
                { path: `scripts/${scriptId}/raw/${script.filename}`, name: 'Lua file' },
                { path: `scripts/${scriptId}/index.html`, name: 'Index file' }
            ];

            console.log('Files to delete:', filesToDelete);

            for (const file of filesToDelete) {
                try {
                    console.log(`Fetching SHA for ${file.name}: ${file.path}`);
                    
                    const getFile = await fetch(
                        `https://api.github.com/repos/${CONFIG.user}/${CONFIG.repo}/contents/${file.path}?t=${CONFIG.cacheBuster()}`, 
                        { headers: this.getHeaders() }
                    );
                    
                    if (getFile.ok) {
                        const fileData = await getFile.json();
                        console.log(`Got SHA for ${file.name}:`, fileData.sha);
                        
                        const deleteRes = await fetch(
                            `https://api.github.com/repos/${CONFIG.user}/${CONFIG.repo}/contents/${file.path}`, 
                            {
                                method: 'DELETE',
                                headers: this.getHeaders(),
                                body: JSON.stringify({
                                    message: `Delete ${file.path}`,
                                    sha: fileData.sha
                                })
                            }
                        );
                        
                        if (deleteRes.ok) {
                            console.log(`Successfully deleted ${file.name}`);
                        } else {
                            const errorText = await deleteRes.text();
                            console.error(`Failed to delete ${file.name}:`, errorText);
                        }
                    } else {
                        console.log(`File not found: ${file.name} (${file.path})`);
                    }
                } catch(e) { 
                    console.error(`Error deleting ${file.name}:`, e); 
                }
            }

            console.log('Removing from database...');
            delete this.db.scripts[titleToDelete];

            console.log('Updating database.json on GitHub...');
            const res = await fetch(`https://api.github.com/repos/${CONFIG.user}/${CONFIG.repo}/contents/database.json`, {
                method: 'PUT',
                headers: this.getHeaders(),
                body: JSON.stringify({
                    message: `Delete script: ${titleToDelete}`,
                    content: utils.safeBtoa(JSON.stringify(this.db, null, 2)),
                    sha: this.dbSha
                })
            });
            
            if (!res.ok) {
                const errorText = await res.text();
                throw new Error(`Failed to update database: ${errorText}`);
            }
            
            const data = await res.json();
            this.dbSha = data.content.sha;
            
            console.log('Database updated successfully');

            msg.innerHTML = `<span style="color:var(--accent)">Successfully deleted "${titleToDelete}"</span>`;
            
            setTimeout(() => { 
                this.currentEditingId = null;
                this.switchAdminTab('list'); 
                this.actionInProgress = false; 
                this.renderList();
                this.renderAdminList();
            }, 1500);
        } catch(e) {
            console.error('Delete failed:', e);
            msg.innerHTML = `<span style="color:red">Delete failed: ${e.message}</span>`;
            this.actionInProgress = false;
        }
    },

    async deleteScriptFiles(title) {
        const scriptId = utils.sanitizeTitle(title);
        const script = this.db.scripts[title];
        if (!script) return;

        const filesToDelete = [
            `scripts/${scriptId}/raw/${script.filename}`,
            `scripts/${scriptId}/index.html`
        ];

        for (const path of filesToDelete) {
            try {
                const getFile = await fetch(`https://api.github.com/repos/${CONFIG.user}/${CONFIG.repo}/contents/${path}?t=${CONFIG.cacheBuster()}`, {
                    headers: this.getHeaders()
                });
                if (getFile.ok) {
                    const fileData = await getFile.json();
                    await fetch(`https://api.github.com/repos/${CONFIG.user}/${CONFIG.repo}/contents/${path}`, {
                        method: 'DELETE',
                        headers: this.getHeaders(),
                        body: JSON.stringify({
                            message: `Clean up ${path}`,
                            sha: fileData.sha
                        })
                    });
                }
            } catch(e) { 
                console.error("File deletion error:", e); 
            }
        }
    },

    generateScriptHTML(title, scriptData) {
        const scriptId = utils.sanitizeTitle(title);
        return `<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>${utils.escapeHtml(scriptData.title)}</title>
    <link rel="stylesheet" href="../../style.css">
    <link href="https://cdnjs.cloudflare.com/ajax/libs/prism/1.29.0/themes/prism-tomorrow.min.css" rel="stylesheet" />
</head>
<body>
    <nav class="navbar"><div class="nav-content"><a href="../../index.html" class="brand">Leaf's Scripts</a><a href="../../index.html" class="btn btn-secondary btn-sm">Back</a></div></nav>
    <div class="container">
        <h1>${utils.escapeHtml(scriptData.title)}</h1>
        <p class="script-desc">${utils.escapeHtml(scriptData.description || '')}</p>
        <div class="code-box">
            <pre><code id="code-display" class="language-lua">Loading script...</code></pre>
        </div>
    </div>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/prism/1.29.0/prism.min.js"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/prism/1.29.0/components/prism-lua.min.js"></script>
    <script>
        fetch('raw/${scriptData.filename}').then(r => r.text()).then(t => {
            document.getElementById('code-display').textContent = t;
            Prism.highlightAll();
        });
    </script>
</body>
</html>`;
    },

    handleRouting() {
        const hash = window.location.hash.slice(1);
        const homeView = document.getElementById('view-home');
        const adminView = document.getElementById('view-admin');
        
        homeView.style.display = 'none';
        adminView.style.display = 'none';
        
        if (hash === 'admin') {
            if (this.currentUser) {
                adminView.style.display = 'block';
                this.switchAdminTab('list');
            } else {
                window.location.hash = '';
                homeView.style.display = 'block';
            }
        } else {
            homeView.style.display = 'block';
            this.renderList();
        }
    },

    toggleLoginModal() {
        const modal = document.getElementById('login-modal');
        modal.style.display = (modal.style.display === 'flex') ? 'none' : 'flex';
    },

    renderList() {
        const list = document.getElementById('script-list');
        const scripts = Object.entries(this.db.scripts || {}).map(([title, data]) => ({ title, ...data }));
        const filtered = this.filterLogic(scripts);
        const sorted = this.sortLogic(filtered);
        
        if (!sorted.length) {
            list.innerHTML = '<div class="empty-state"><h2>No scripts found</h2></div>';
            return;
        }

        list.innerHTML = sorted.map(s => `
            <div class="script-card" data-action="view-script" data-param="${utils.escapeHtml(s.title)}">
                <div class="card-content">
                    <div class="card-header-section">
                        <h3 class="script-title">${utils.escapeHtml(s.title)}</h3>
                        ${(this.currentUser && s.visibility !== 'PUBLIC') ? `<span class="badge badge-${s.visibility.toLowerCase()}">${s.visibility}</span>` : ''}
                    </div>
                    <div class="card-meta"><span>${new Date(s.created).toLocaleDateString()}</span></div>
                </div>
            </div>
        `).join('');
    },

    filterLogic(scripts) {
        const query = document.getElementById('search').value.toLowerCase();
        return scripts.filter(s => {
            if (!s.title.toLowerCase().includes(query)) return false;
            if (!this.currentUser && s.visibility !== 'PUBLIC') return false;
            if (this.currentFilter === 'private' && s.visibility !== 'PRIVATE') return false;
            if (this.currentFilter === 'public' && s.visibility !== 'PUBLIC') return false;
            return true;
        });
    },

    sortLogic(scripts) {
        return scripts.sort((a, b) => {
            if (this.currentSort === 'newest') return new Date(b.created) - new Date(a.created);
            if (this.currentSort === 'alpha') return a.title.localeCompare(b.title);
            return 0;
        });
    },

    filterCategory(cat, e) {
        if (e) e.preventDefault();
        this.currentFilter = cat;
        document.querySelectorAll('.sidebar-link').forEach(l => l.classList.remove('active'));
        if (e && e.currentTarget) e.currentTarget.classList.add('active');
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
            document.querySelector('.tab-btn:nth-child(1)').classList.add('active');
            this.renderAdminList();
        } else if (tab === 'stats') {
            document.getElementById('admin-tab-stats').style.display = 'block';
            document.querySelector('.tab-btn:nth-child(3)').classList.add('active');
            this.renderStats();
        } else {
            document.getElementById('admin-tab-editor').style.display = 'block';
            document.querySelector('.tab-btn:nth-child(2)').classList.add('active');
            this.resetEditor();
        }
    },

    async renderAdminList() {
        const list = document.getElementById('admin-list');
        const scripts = Object.entries(this.db.scripts || {});
        
        document.getElementById('total-stats').textContent = `${scripts.length} Scripts`;
        
        list.innerHTML = scripts.map(([title, s]) => `
            <div class="admin-item" data-action="edit-script" data-param="${utils.escapeHtml(title)}">
                <div class="admin-item-left">
                    <strong>${utils.escapeHtml(title)}</strong>
                    <div class="admin-meta"><span class="badge badge-sm badge-${s.visibility.toLowerCase()}">${s.visibility}</span></div>
                </div>
            </div>
        `).join('');
    },

    async populateEditor(title) {
        const s = this.db.scripts[title];
        if (!s) return;
        this.currentEditingId = title;
        this.switchAdminTab('create');
        
        console.log('Editing script:', title);
        
        document.getElementById('editor-heading').textContent = `Edit: ${title}`;
        document.getElementById('edit-title').value = s.title;
        document.getElementById('edit-visibility').value = s.visibility;
        document.getElementById('edit-desc').value = s.description || '';
        document.getElementById('edit-expire').value = s.expiration || '';
        document.getElementById('edit-code').value = 'Loading...';
        document.getElementById('btn-delete').style.display = 'inline-flex';
        document.getElementById('admin-msg').innerHTML = '';

        try {
            const res = await fetch(`https://api.github.com/repos/${CONFIG.user}/${CONFIG.repo}/contents/scripts/${utils.sanitizeTitle(title)}/raw/${s.filename}?t=${CONFIG.cacheBuster()}`, { 
                headers: this.getHeaders() 
            });
            const data = await res.json();
            document.getElementById('edit-code').value = utils.safeAtob(data.content);
        } catch(e) { 
            document.getElementById('edit-code').value = '-- Error loading source code'; 
        }
    },

    resetEditor() {
        this.currentEditingId = null;
        document.getElementById('edit-title').value = '';
        document.getElementById('edit-desc').value = '';
        document.getElementById('edit-expire').value = '';
        document.getElementById('edit-code').value = '';
        document.getElementById('btn-delete').style.display = 'none';
        document.getElementById('editor-heading').textContent = 'Create New Script';
        document.getElementById('admin-msg').innerHTML = '';
    },

    renderStats() {
        const total = Object.keys(this.db.scripts).length;
        const publicCount = Object.values(this.db.scripts).filter(s => s.visibility === 'PUBLIC').length;
        const privateCount = Object.values(this.db.scripts).filter(s => s.visibility === 'PRIVATE').length;
        const unlistedCount = Object.values(this.db.scripts).filter(s => s.visibility === 'UNLISTED').length;
        
        document.getElementById('stats-content').innerHTML = `
            <div class="stats-grid">
                <div class="stat-card">
                    <div class="stat-number">${total}</div>
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
            </div>
        `;
    }
};

app.init();
