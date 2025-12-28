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
            return btoa(unescape(encodeURIComponent(str)));
        } catch(e) {
            return btoa(str);
        }
    },
    
    safeAtob(str) {
        try {
            return decodeURIComponent(escape(atob(str)));
        } catch(e) {
            return atob(str);
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
    }
};

const app = {
    db: { scripts: {} },
    dbSha: null,
    token: null,
    currentUser: null,
    currentFilter: 'all',
    currentSort: 'newest',
    actionInProgress: false,
    currentEditingId: null,
    originalTitle: null,
    originalScriptId: null,
    isLoading: false,
    searchQuery: '',
    
    async init() {
        const sessionValid = await this.loadSession();
        await this.loadDatabase();
        this.handleRouting();
        window.addEventListener('hashchange', () => this.handleRouting());
        
        this.debouncedRender = utils.debounce(() => this.renderList(), 300);
        
        const today = new Date().toISOString().split('T')[0];
        const expireInput = document.getElementById('edit-expire');
        if (expireInput) expireInput.min = today;
        
        this.initEventListeners();
        this.loadMonacoIfNeeded();
        
        window.addEventListener('keydown', (e) => {
            if ((e.ctrlKey || e.metaKey) && e.key === 's') {
                e.preventDefault();
                if (location.hash === '#admin') {
                    this.saveScript();
                }
            }
        });

        this.startSessionRefresh();
    },

    startSessionRefresh() {
        setInterval(() => {
            if (this.token && this.currentUser) {
                const expiry = localStorage.getItem('gh_token_expiry');
                if (expiry && Date.now() >= parseInt(expiry)) {
                    this.logout(true);
                }
            }
        }, 60000);
    },
    
    initEventListeners() {
        const searchInput = document.getElementById('search');
        if (searchInput) {
            searchInput.addEventListener('input', (e) => {
                this.searchQuery = e.target.value;
                this.debouncedRender();
            });
        }
    },
    
    loadMonacoIfNeeded() {
        if (location.hash === '#admin') {
            setTimeout(() => {
                this.loadMonacoEditor();
                this.loadQuillEditor();
            }, 100);
        }
    },

    async loadSession() {
        try {
            const storedToken = localStorage.getItem('gh_token');
            const storedUser = localStorage.getItem('gh_user');
            const tokenExpiry = localStorage.getItem('gh_token_expiry');
            
            if (storedToken && storedUser && tokenExpiry) {
                const now = Date.now();
                if (now < parseInt(tokenExpiry)) {
                    this.token = storedToken;
                    this.currentUser = JSON.parse(storedUser);
                    
                    if (this.currentUser.login.toLowerCase() !== CONFIG.user.toLowerCase()) {
                        this.logout(true);
                        return false;
                    }
                    
                    this.updateUIForLoggedInUser();
                    
                    return true;
                } else {
                    this.logout(true);
                }
            }
        } catch(e) {
            console.error('Session load error:', e);
        }
        return false;
    },

    updateUIForLoggedInUser() {
        document.getElementById('auth-section').style.display = 'none';
        document.getElementById('user-section').style.display = 'flex';
        document.getElementById('private-filter').style.display = 'block';
        document.getElementById('unlisted-filter').style.display = 'block';
    },

    saveSession() {
        if (this.token && this.currentUser) {
            try {
                const expiry = Date.now() + (30 * 24 * 60 * 60 * 1000);
                localStorage.setItem('gh_token', this.token);
                localStorage.setItem('gh_user', JSON.stringify(this.currentUser));
                localStorage.setItem('gh_token_expiry', expiry.toString());
            } catch(e) {
                console.error('Session save error:', e);
                this.showToast('Failed to save session', 'error');
            }
        }
    },

    generateScriptHTML(title, scriptData) {
        const scriptId = utils.sanitizeTitle(title);
        const descriptionHtml = scriptData.description ? 
            `<div class="script-description">${scriptData.description}</div>` : '';
        
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
    <script src="https://cdn.jsdelivr.net/npm/file-saver@2.0.5/dist/FileSaver.min.js"></script>
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

    toggleLoginModal() {
        const modal = document.getElementById('login-modal');
        modal.style.display = modal.style.display === 'flex' ? 'none' : 'flex';
        document.getElementById('login-error').style.display = 'none';
        if (modal.style.display === 'flex') {
            document.getElementById('auth-token').focus();
        }
    },

    async login() {
        if (this.actionInProgress) return;
        this.actionInProgress = true;
        
        try {
            const token = document.getElementById('auth-token').value.trim();
            if (!token) {
                this.showLoginError('Token is required');
                return;
            }
            
            this.token = token;
            const success = await this.verifyToken(false);
            if (success) {
                this.saveSession();
                this.toggleLoginModal();
                document.getElementById('auth-token').value = '';
                await this.loadDatabase();
                this.renderList();
                this.showToast('Logged in successfully!', 'success');
            }
        } finally {
            this.actionInProgress = false;
        }
    },

    showLoginError(message) {
        const err = document.getElementById('login-error');
        err.textContent = message;
        err.style.display = 'block';
        this.actionInProgress = false;
    },
    
    showToast(message, type = 'success') {
        if (typeof Toastify !== 'undefined') {
            Toastify({
                text: message,
                duration: 3000,
                gravity: "top",
                position: "right",
                backgroundColor: type === 'success' ? "#10b981" : type === 'error' ? "#ef4444" : "#f59e0b",
                stopOnFocus: true
            }).showToast();
        } else {
            alert(message);
        }
    },

    logout(silent = false) {
        if (!silent && !confirm('Are you sure you want to logout?')) {
            return;
        }
        
        try {
            localStorage.removeItem('gh_token');
            localStorage.removeItem('gh_user');
            localStorage.removeItem('gh_token_expiry');
        } catch(e) {
            console.error('Logout error:', e);
        }
        
        this.token = null;
        this.currentUser = null;
        
        document.getElementById('auth-section').style.display = 'block';
        document.getElementById('user-section').style.display = 'none';
        document.getElementById('private-filter').style.display = 'none';
        document.getElementById('unlisted-filter').style.display = 'none';
        
        location.href = '#';
        
        if (!silent) {
            this.showToast('Logged out successfully', 'success');
            setTimeout(() => location.reload(), 1000);
        }
    },

    async verifyToken(silent) {
        try {
            const res = await fetch('https://api.github.com/user', {
                headers: { 'Authorization': `token ${this.token}` }
            });
            
            if (!res.ok) {
                throw new Error('Invalid token');
            }
            
            const user = await res.json();
            if (user.login.toLowerCase() !== CONFIG.user.toLowerCase()) {
                throw new Error(`Token belongs to ${user.login}, not ${CONFIG.user}.`);
            }
            
            this.currentUser = user;
            this.updateUIForLoggedInUser();
            
            return true;
        } catch (e) {
            if (!silent) {
                this.showLoginError(e.message);
            }
            this.token = null;
            try {
                localStorage.removeItem('gh_token');
                localStorage.removeItem('gh_user');
                localStorage.removeItem('gh_token_expiry');
            } catch(err) {
                console.error('Error clearing storage:', err);
            }
            return false;
        }
    },

    async loadDatabase() {
        try {
            this.isLoading = true;
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
                try {
                    this.db = JSON.parse(utils.safeAtob(file.content));
                    if (!this.db.scripts) {
                        this.db = { scripts: {} };
                    }
                } catch(parseError) {
                    console.error('Database parse error:', parseError);
                    this.showToast('Database corrupted, initializing new database', 'warning');
                    this.db = { scripts: {} };
                }
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
            this.showToast(`Error loading scripts: ${e.message}`, 'error');
        } finally {
            this.isLoading = false;
        }
    },

    renderList() {
        const list = document.getElementById('script-list');
        if (!list) return;
        
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
                    ${s.description ? `<p style="color:var(--color-text-muted);font-size:13px;margin:8px 0">${utils.escapeHtml(s.description.replace(/<[^>]*>/g, '').substring(0, 150))}${s.description.length > 150 ? '...' : ''}</p>` : ''}
                    <div class="card-meta">
                        <span>${new Date(s.created).toLocaleDateString()}</span>
                        ${s.updated && s.updated !== s.created ? `<span title="Updated">↻ ${new Date(s.updated).toLocaleDateString()}</span>` : ''}
                    </div>
                </div>
            </div>
        `}).join('');
    },

    filterLogic(scripts) {
        const query = this.searchQuery.toLowerCase();
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
        if (tab === 'admin' && !this.currentUser) {
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
            this.loadMonacoEditor();
            this.loadQuillEditor();
        }
    },

    async renderAdminList() {
        if (!this.currentUser) return;
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
            <div class="admin-item" data-script-title="${s.title.replace(/'/g, "\\'").replace(/"/g, '&quot;')}" onclick="app.populateEditor('${s.title.replace(/'/g, "\\'").replace(/"/g, '&quot;')}')">
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
        this.initSwipeToDelete();
    },

    initSwipeToDelete() {
        const adminItems = document.querySelectorAll('.admin-item');
        adminItems.forEach(item => {
            let startX = 0;
            let isSwiping = false;
            item.addEventListener('touchstart', (e) => {
                startX = e.touches[0].clientX;
                isSwiping = false;
                item.style.transition = 'none';
            }, { passive: true });
            item.addEventListener('touchmove', (e) => {
                if (!startX) return;
                const currentX = e.touches[0].clientX;
                const diff = currentX - startX;
                if (Math.abs(diff) > 30) {
                    isSwiping = true;
                    e.preventDefault();
                    if (diff > 0) {
                        item.style.transform = `translateX(${Math.min(diff, 100)}px)`;
                        item.style.backgroundColor = 'rgba(239, 68, 68, 0.1)';
                    }
                }
            }, { passive: false });
            item.addEventListener('touchend', (e) => {
                if (!startX || !isSwiping) return;
                const endX = e.changedTouches[0].clientX;
                const diff = endX - startX;
                item.style.transition = 'transform 0.3s ease, background-color 0.3s ease';
                if (diff > 100) {
                    item.style.transform = 'translateX(300px)';
                    item.style.opacity = '0';
                    setTimeout(() => {
                        const scriptTitle = item.getAttribute('data-script-title');
                        this.deleteScriptConfirmation(scriptTitle);
                    }, 300);
                } else {
                    item.style.transform = 'translateX(0)';
                    item.style.backgroundColor = '';
                }
                startX = 0;
                isSwiping = false;
            });
            item.addEventListener('click', (e) => {
                if (isSwiping) {
                    e.preventDefault();
                    e.stopPropagation();
                }
            });
        });
    },

    async deleteScriptConfirmation(scriptTitle) {
        if (!scriptTitle || !this.db.scripts[scriptTitle]) {
            this.showToast('Script not found or already deleted.', 'error');
            await this.loadDatabase();
            return;
        }

        const confirmMessage = `Are you sure you want to delete "${scriptTitle}"? This will permanently delete the script, Lua file, and HTML page.`;
        
        let shouldDelete = false;
        
        if (typeof Swal !== 'undefined') {
            const result = await Swal.fire({
                title: 'Delete Script',
                text: confirmMessage,
                icon: 'warning',
                showCancelButton: true,
                confirmButtonText: 'Yes, delete it!',
                cancelButtonText: 'Cancel',
                confirmButtonColor: '#ef4444'
            });
            shouldDelete = result.isConfirmed;
        } else {
            shouldDelete = confirm(confirmMessage);
        }

        if (!shouldDelete) {
            await this.loadDatabase();
            return;
        }

        await this.deleteScriptLogic(scriptTitle);
    },

    async deleteScriptLogic(scriptTitle) {
        if (this.actionInProgress) return;
        if (!this.currentUser) {
            this.showToast('Please login first.', 'error');
            return;
        }

        this.actionInProgress = true;
        
        try {
            if (typeof NProgress !== 'undefined') NProgress.start();
            
            const scriptData = this.db.scripts[scriptTitle];
            const scriptId = utils.sanitizeTitle(scriptTitle);
            
            const luaPath = `scripts/${scriptId}/raw/${scriptData.filename}`;
            try {
                const luaRes = await fetch(`https://api.github.com/repos/${CONFIG.user}/${CONFIG.repo}/contents/${luaPath}`, {
                    headers: { 'Authorization': `token ${this.token}` }
                });
                
                if (luaRes.ok) {
                    const luaData = await luaRes.json();
                    await fetch(`https://api.github.com/repos/${CONFIG.user}/${CONFIG.repo}/contents/${luaPath}`, {
                        method: 'DELETE',
                        headers: { 
                            'Authorization': `token ${this.token}`,
                            'Content-Type': 'application/json'
                        },
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
                        headers: { 
                            'Authorization': `token ${this.token}`,
                            'Content-Type': 'application/json'
                        },
                        body: JSON.stringify({
                            message: `Delete index for ${scriptTitle}`,
                            sha: idxData.sha
                        })
                    });
                }
            } catch(e) {
                console.warn('Index file deletion error:', e.message);
            }
            
            delete this.db.scripts[scriptTitle];
            
            const dbRes = await fetch(`https://api.github.com/repos/${CONFIG.user}/${CONFIG.repo}/contents/database.json`, {
                method: 'PUT',
                headers: { 
                    'Authorization': `token ${this.token}`,
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({
                    message: `Remove ${scriptTitle} from database`,
                    content: utils.safeBtoa(JSON.stringify(this.db, null, 2)),
                    sha: this.dbSha
                })
            });
            
            if (dbRes.ok) {
                const newDbData = await dbRes.json();
                this.dbSha = newDbData.content.sha;
                
                this.showToast('Script deleted successfully!', 'success');
                
                if (this.currentEditingId === scriptTitle) {
                    this.resetEditor();
                    this.switchAdminTab('list');
                }
                
                await this.loadDatabase();
            } else {
                throw new Error('Failed to update database');
            }
            
        } catch(e) {
            console.error('Delete error:', e);
            this.showToast(`Delete failed: ${e.message}`, 'error');
            await this.loadDatabase();
        } finally {
            this.actionInProgress = false;
            if (typeof NProgress !== 'undefined') NProgress.done();
        }
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
        document.getElementById('edit-expire').value = '';
        
        if (window.monacoEditor) {
            window.monacoEditor.setValue('');
        } else {
            document.getElementById('edit-code').value = '';
        }
        
        if (window.quillEditor) {
            window.quillEditor.root.innerHTML = '';
        } else {
            document.getElementById('edit-desc').value = '';
        }
        
        document.querySelector('.editor-actions .btn:last-child').textContent = 'Publish';
        const deleteBtn = document.querySelector('.btn-delete');
        if (deleteBtn) deleteBtn.remove();
        
        const viewBtn = document.querySelector('.btn-view-script');
        if (viewBtn) viewBtn.remove();
        
        this.currentEditingId = null;
        this.originalTitle = null;
        this.originalScriptId = null;
    },

    async populateEditor(title) {
        if (!this.currentUser) return;
        const s = this.db.scripts[title];
        if (!s) return;
        
        this.currentEditingId = title;
        this.originalTitle = title;
        this.originalScriptId = utils.sanitizeTitle(title);
        
        this.switchAdminTab('create');
        
        document.getElementById('editor-heading').textContent = `Edit: ${title}`;
        document.getElementById('edit-title').value = s.title;
        document.getElementById('edit-visibility').value = s.visibility;
        document.getElementById('edit-expire').value = s.expiration || '';
        
        if (window.quillEditor) {
            setTimeout(() => {
                window.quillEditor.root.innerHTML = s.description || '';
                const descInput = document.getElementById('edit-desc');
                if (descInput) descInput.value = s.description || '';
            }, 100);
        } else {
            document.getElementById('edit-desc').value = s.description || '';
        }
        
        try {
            if (typeof NProgress !== 'undefined') NProgress.start();
            
            const res = await fetch(`scripts/${this.originalScriptId}/raw/${s.filename}?t=${CONFIG.cacheBuster()}`);
            
            if (res.ok) {
                const code = await res.text();
                
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
            console.error('Load error:', e);
            const errorText = '-- Error loading content';
            if (window.monacoEditor) {
                window.monacoEditor.setValue(errorText);
            } else {
                document.getElementById('edit-code').value = errorText;
            }
        } finally {
            if (typeof NProgress !== 'undefined') NProgress.done();
        }
        
        document.querySelector('.editor-actions .btn:last-child').textContent = 'Update Script';
        
        const actionButtons = document.querySelector('.action-buttons');
        let deleteBtn = document.querySelector('.btn-delete');
        if (!deleteBtn) {
            deleteBtn = document.createElement('button');
            deleteBtn.className = 'btn btn-delete';
            deleteBtn.innerHTML = `
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <path d="M3 6h18M19 6v14a2 2 0 01-2 2H7a2 2 0 01-2-2V6m3 0V4a2 2 0 012-2h4a2 2 0 012 2v2"></path>
                </svg>
                Delete
            `;
            deleteBtn.onclick = () => this.deleteScriptConfirmation(title);
            actionButtons.appendChild(deleteBtn);
        }
        
        this.updateViewButton(this.originalScriptId);
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

    async saveScript() {
        if (!this.currentUser) {
            this.showToast('Please login first.', 'error');
            return;
        }
        
        if (this.actionInProgress) return;
        this.actionInProgress = true;
        
        const title = document.getElementById('edit-title').value.trim();
        const visibility = document.getElementById('edit-visibility').value;
        const expiration = document.getElementById('edit-expire').value;
        const code = window.monacoEditor ? window.monacoEditor.getValue() : document.getElementById('edit-code').value;
        const desc = window.quillEditor ? window.quillEditor.root.innerHTML : document.getElementById('edit-desc').value;
        const saveBtn = document.querySelector('.editor-actions .btn:last-child');
        const originalBtnText = saveBtn.textContent;
        
        const titleError = utils.validateTitle(title);
        const codeError = utils.validateCode(code);
        
        if (titleError || codeError) {
            this.showToast(titleError || codeError, 'error');
            this.actionInProgress = false;
            return;
        }
        
        if (expiration && new Date(expiration) < new Date()) {
            this.showToast('Expiration date cannot be in the past', 'error');
            this.actionInProgress = false;
            return;
        }
        
        const isEditing = !!this.currentEditingId;
        const newScriptId = utils.sanitizeTitle(title);
        const filename = newScriptId + '.lua';
        const titleChanged = isEditing && this.originalTitle !== title;
        
        saveBtn.disabled = true;
        saveBtn.textContent = isEditing ? 'Updating...' : 'Publishing...';
        
        if (typeof NProgress !== 'undefined') NProgress.start();
        
        try {
            const scriptData = {
                title: title,
                visibility: visibility,
                description: desc,
                expiration: expiration || null,
                filename: filename,
                size: code.length,
                created: (isEditing && this.db.scripts[this.originalTitle]) ? this.db.scripts[this.originalTitle].created : new Date().toISOString(),
                updated: new Date().toISOString()
            };
            
            if (isEditing) {
                if (titleChanged) {
                    await this.deleteOldScriptFiles(this.originalTitle);
                    delete this.db.scripts[this.originalTitle];
                }
            }
            
            this.db.scripts[title] = scriptData;
            
            const luaPath = `scripts/${newScriptId}/raw/${filename}`;
            let luaSha = null;
            
            if (isEditing && !titleChanged) {
                try {
                    const luaRes = await fetch(`https://api.github.com/repos/${CONFIG.user}/${CONFIG.repo}/contents/${luaPath}`, {
                        headers: { 'Authorization': `token ${this.token}` }
                    });
                    if (luaRes.ok) {
                        const luaData = await luaRes.json();
                        luaSha = luaData.sha;
                    }
                } catch(e) {
                    console.warn('Could not fetch Lua file SHA:', e.message);
                }
            }
            
            const luaBody = {
                message: `${isEditing ? 'Update' : 'Create'} ${filename}`,
                content: utils.safeBtoa(code)
            };
            if (luaSha) luaBody.sha = luaSha;
            
            const luaRes = await fetch(`https://api.github.com/repos/${CONFIG.user}/${CONFIG.repo}/contents/${luaPath}`, {
                method: 'PUT',
                headers: { 
                    'Authorization': `token ${this.token}`,
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify(luaBody)
            });
            
            if (!luaRes.ok) {
                throw new Error('Failed to save Lua file');
            }
            
            const dbRes = await fetch(`https://api.github.com/repos/${CONFIG.user}/${CONFIG.repo}/contents/database.json`, {
                method: 'PUT',
                headers: { 
                    'Authorization': `token ${this.token}`,
                    'Content-Type': 'application/json'
                },
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
            const indexPath = `scripts/${newScriptId}/index.html`;
            let indexSha = null;
            
            if (isEditing && !titleChanged) {
                try {
                    const indexRes = await fetch(`https://api.github.com/repos/${CONFIG.user}/${CONFIG.repo}/contents/${indexPath}`, {
                        headers: { 'Authorization': `token ${this.token}` }
                    });
                    if (indexRes.ok) {
                        const indexData = await indexRes.json();
                        indexSha = indexData.sha;
                    }
                } catch(e) {
                    console.warn('Could not fetch index file SHA:', e.message);
                }
            }
            
            const indexBody = {
                message: `${isEditing ? 'Update' : 'Create'} index for ${title}`,
                content: utils.safeBtoa(indexHTML)
            };
            if (indexSha) indexBody.sha = indexSha;
            
            const indexRes = await fetch(`https://api.github.com/repos/${CONFIG.user}/${CONFIG.repo}/contents/${indexPath}`, {
                method: 'PUT',
                headers: { 
                    'Authorization': `token ${this.token}`,
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify(indexBody)
            });
            
            if (!indexRes.ok) {
                throw new Error('Failed to save index.html');
            }
            
            this.showToast(`${isEditing ? 'Updated' : 'Published'} successfully!`, 'success');
            
            this.currentEditingId = title;
            this.originalTitle = title;
            this.originalScriptId = newScriptId;
            
            document.getElementById('editor-heading').textContent = `Edit: ${title}`;
            saveBtn.textContent = 'Update Script';
            
            this.updateViewButton(newScriptId);
            
            await this.loadDatabase();
            
        } catch(e) {
            console.error('Save error:', e);
            this.showToast(`Error: ${e.message}`, 'error');
        } finally {
            saveBtn.disabled = false;
            saveBtn.textContent = originalBtnText;
            this.actionInProgress = false;
            if (typeof NProgress !== 'undefined') NProgress.done();
        }
    },

    async deleteOldScriptFiles(oldTitle) {
        const oldScriptData = this.db.scripts[oldTitle];
        if (!oldScriptData) return;
        
        const oldScriptId = utils.sanitizeTitle(oldTitle);
        
        try {
            const oldLuaPath = `scripts/${oldScriptId}/raw/${oldScriptData.filename}`;
            const luaRes = await fetch(`https://api.github.com/repos/${CONFIG.user}/${CONFIG.repo}/contents/${oldLuaPath}`, {
                headers: { 'Authorization': `token ${this.token}` }
            });
            
            if (luaRes.ok) {
                const luaData = await luaRes.json();
                await fetch(`https://api.github.com/repos/${CONFIG.user}/${CONFIG.repo}/contents/${oldLuaPath}`, {
                    method: 'DELETE',
                    headers: { 
                        'Authorization': `token ${this.token}`,
                        'Content-Type': 'application/json'
                    },
                    body: JSON.stringify({
                        message: `Delete old Lua file`,
                        sha: luaData.sha
                    })
                });
            }
        } catch(e) {
            console.warn('Error deleting old Lua file:', e.message);
        }
        
        try {
            const oldIndexPath = `scripts/${oldScriptId}/index.html`;
            const idxRes = await fetch(`https://api.github.com/repos/${CONFIG.user}/${CONFIG.repo}/contents/${oldIndexPath}`, {
                headers: { 'Authorization': `token ${this.token}` }
            });
            
            if (idxRes.ok) {
                const idxData = await idxRes.json();
                await fetch(`https://api.github.com/repos/${CONFIG.user}/${CONFIG.repo}/contents/${oldIndexPath}`, {
                    method: 'DELETE',
                    headers: { 
                        'Authorization': `token ${this.token}`,
                        'Content-Type': 'application/json'
                    },
                    body: JSON.stringify({
                        message: `Delete old index`,
                        sha: idxData.sha
                    })
                });
            }
        } catch(e) {
            console.warn('Error deleting old index file:', e.message);
        }
    },

    handleRouting() {
        const hash = location.hash.slice(1);
        document.querySelectorAll('.view-section').forEach(el => el.style.display = 'none');
        window.scrollTo(0, 0);
        
        if (hash === 'admin') {
            if (!this.currentUser) {
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
    
    loadMonacoEditor() {
        if (typeof monaco !== 'undefined' || window.monacoEditor) return;
        
        if (!document.querySelector('#editor-container')) return;
        
        const loadMonaco = () => {
            if (typeof monaco === 'undefined') {
                const script = document.createElement('script');
                script.src = 'https://cdnjs.cloudflare.com/ajax/libs/monaco-editor/0.34.0/min/vs/loader.min.js';
                script.onload = () => {
                    require.config({ 
                        paths: { 
                            vs: 'https://cdnjs.cloudflare.com/ajax/libs/monaco-editor/0.34.0/min/vs' 
                        } 
                    });
                    require(['vs/editor/editor.main'], () => {
                        window.monacoEditor = monaco.editor.create(document.getElementById('editor-container'), {
                            value: '',
                            language: 'lua',
                            theme: 'vs-dark',
                            fontSize: 14,
                            minimap: { enabled: false },
                            scrollBeyondLastLine: false,
                            wordWrap: 'on',
                            lineNumbers: 'on',
                            automaticLayout: true
                        });
                        
                        const textarea = document.getElementById('edit-code');
                        if (textarea) textarea.style.display = 'none';
                    });
                };
                document.head.appendChild(script);
            }
        };
        
        setTimeout(loadMonaco, 100);
    },
    
    loadQuillEditor() {
        if (typeof Quill !== 'undefined' || window.quillEditor) return;
        
        if (!document.querySelector('#quill-container')) return;
        
        const loadQuill = () => {
            if (typeof Quill === 'undefined') {
                const link = document.createElement('link');
                link.href = 'https://cdn.quilljs.com/1.3.6/quill.snow.css';
                link.rel = 'stylesheet';
                document.head.appendChild(link);
                
                const script = document.createElement('script');
                script.src = 'https://cdn.quilljs.com/1.3.6/quill.min.js';
                script.onload = () => {
                    window.quillEditor = new Quill('#quill-container', {
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
                    
                    const descInput = document.getElementById('edit-desc');
                    if (descInput) descInput.style.display = 'none';
                    
                    window.quillEditor.on('text-change', () => {
                        const html = window.quillEditor.root.innerHTML;
                        if (descInput) descInput.value = html === '<p><br></p>' ? '' : html;
                    });
                };
                document.head.appendChild(script);
            }
        };
        
        setTimeout(loadQuill, 100);
    }
};

function navigate(path) {
    if (path === 'admin' && !app.currentUser) {
        app.toggleLoginModal();
        return;
    }
    location.hash = path;
}

window.addEventListener('DOMContentLoaded', () => {
    app.init();
    
    if (typeof NProgress !== 'undefined') {
        NProgress.configure({ 
            showSpinner: false,
            speed: 400,
            trickleSpeed: 200 
        });
    }
});

window.app = app;
window.navigate = navigate;
