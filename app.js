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
    },

    generateSecureToken() {
        const array = new Uint8Array(32);
        window.crypto.getRandomValues(array);
        return Array.from(array, byte => byte.toString(16).padStart(2, '0')).join('');
    }
};

const app = {
    db: { scripts: {} },
    dbSha: null,
    token: null,
    sessionToken: null,
    currentUser: null,
    currentFilter: 'all',
    currentSort: 'newest',
    actionInProgress: false,
    currentEditingId: null,
    originalTitle: null,
    securityCheckInterval: null,
    
    async init() {
        this.loadSession();
        await this.loadDatabase();
        this.handleRouting();
        window.addEventListener('hashchange', () => this.handleRouting());
        
        this.debouncedRender = utils.debounce(() => this.renderList(), 300);
        this.debouncedSave = utils.debounce(() => this.saveScript(), 750);
        this.debouncedLogin = utils.debounce(() => this.login(), 750);
        this.debouncedToggleLogin = utils.debounce(() => this.toggleLoginModal(), 200);
        
        const today = new Date().toISOString().split('T')[0];
        document.getElementById('edit-expire').min = today;
        
        this.startSecurityMonitor();
    },

    loadSession() {
        const storedSession = localStorage.getItem('gh_session');
        if (storedSession) {
            try {
                const session = JSON.parse(storedSession);
                const now = Date.now();
                
                if (session.expires > now && session.userAgent === navigator.userAgent) {
                    this.token = session.token;
                    this.sessionToken = session.sessionToken;
                    this.currentUser = { login: CONFIG.user };
                    return true;
                } else {
                    localStorage.removeItem('gh_session');
                    localStorage.removeItem('gh_token');
                }
            } catch(e) {
                localStorage.removeItem('gh_session');
                localStorage.removeItem('gh_token');
            }
        }
        return false;
    },

    saveSession() {
        const session = {
            token: this.token,
            sessionToken: this.sessionToken,
            expires: Date.now() + (12 * 60 * 60 * 1000),
            userAgent: navigator.userAgent,
            timestamp: Date.now()
        };
        localStorage.setItem('gh_session', JSON.stringify(session));
    },

    startSecurityMonitor() {
        this.securityCheckInterval = setInterval(() => {
            this.checkSessionValidity();
        }, 30000);
        
        window.addEventListener('storage', (e) => {
            if (e.key === 'gh_session' && !e.newValue) {
                this.logout(true);
            }
        });
        
        window.addEventListener('beforeunload', () => {
            if (this.currentUser) {
                this.saveSession();
            }
        });
    },

    async checkSessionValidity() {
        if (!this.currentUser || !this.token) return;
        
        try {
            const storedSession = localStorage.getItem('gh_session');
            if (!storedSession) {
                this.logout(true);
                return;
            }
            
            const session = JSON.parse(storedSession);
            if (session.userAgent !== navigator.userAgent) {
                this.logout(true);
                return;
            }
            
            if (session.expires < Date.now()) {
                this.logout(true);
                return;
            }
            
            const res = await fetch('https://api.github.com/user', {
                headers: { 
                    'Authorization': `token ${this.token}`,
                    'X-Session-Check': 'true'
                }
            });
            
            if (!res.ok) {
                this.logout(true);
            }
        } catch(e) {
            console.warn('Session check failed:', e);
        }
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
            
            if (!token.startsWith('ghp_') && !token.startsWith('github_pat_')) {
                this.showLoginError('Invalid token format');
                return;
            }
            
            this.token = token;
            const success = await this.verifyToken(false);
            if (success) {
                this.sessionToken = utils.generateSecureToken();
                this.saveSession();
                this.toggleLoginModal();
                document.getElementById('auth-token').value = '';
                await this.loadDatabase();
                this.renderList();
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

    logout(silent = false) {
        if (!silent && !confirm('Are you sure you want to logout?')) {
            return;
        }
        
        clearInterval(this.securityCheckInterval);
        
        localStorage.removeItem('gh_session');
        localStorage.removeItem('gh_token');
        
        this.token = null;
        this.sessionToken = null;
        this.currentUser = null;
        
        document.getElementById('auth-section').style.display = 'block';
        document.getElementById('user-section').style.display = 'none';
        document.getElementById('private-filter').style.display = 'none';
        document.getElementById('unlisted-filter').style.display = 'none';
        
        location.href = '#';
        
        if (!silent) {
            location.reload();
        }
    },

    async verifyToken(silent) {
        try {
            const res = await fetch('https://api.github.com/user', {
                headers: { 
                    'Authorization': `token ${this.token}`,
                    'X-Requested-With': 'XMLHttpRequest'
                }
            });
            
            if (!res.ok) {
                throw new Error('Invalid token');
            }
            
            const user = await res.json();
            if (user.login.toLowerCase() !== CONFIG.user.toLowerCase()) {
                throw new Error(`Token belongs to ${user.login}, not ${CONFIG.user}.`);
            }
            
            this.currentUser = user;
            document.getElementById('auth-section').style.display = 'none';
            document.getElementById('user-section').style.display = 'flex';
            document.getElementById('private-filter').style.display = 'block';
            document.getElementById('unlisted-filter').style.display = 'block';
            
            return true;
        } catch (e) {
            if (!silent) {
                this.showLoginError(e.message);
            }
            this.token = null;
            localStorage.removeItem('gh_session');
            localStorage.removeItem('gh_token');
            return false;
        }
    },

    async secureFetch(url, options = {}) {
        if (!this.token || !this.sessionToken) {
            throw new Error('Not authenticated');
        }
        
        const defaultHeaders = {
            'Authorization': `token ${this.token}`,
            'X-Session-Token': this.sessionToken,
            'X-Requested-With': 'XMLHttpRequest'
        };
        
        const headers = { ...defaultHeaders, ...options.headers };
        
        try {
            const response = await fetch(url, { ...options, headers });
            
            if (response.status === 401 || response.status === 403) {
                this.logout(true);
                throw new Error('Session expired');
            }
            
            return response;
        } catch (error) {
            if (error.message.includes('Session expired')) {
                throw error;
            }
            throw new Error(`Request failed: ${error.message}`);
        }
    },

    async loadDatabase() {
        try {
            const list = document.getElementById('admin-list');
            if (list) {
                list.innerHTML = `<div style="text-align:center;padding:20px"><div class="spinner"></div><p>Loading scripts...</p></div>`;
            }
            
            const res = await fetch(`https://api.github.com/repos/${CONFIG.user}/${CONFIG.repo}/contents/database.json?t=${CONFIG.cacheBuster()}`, {
                headers: this.token ? { 
                    'Authorization': `token ${this.token}`,
                    'X-Requested-With': 'XMLHttpRequest'
                } : {}
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
            this.resetEditor();
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
        
        this.initSwipeToDelete();
    },

    initSwipeToDelete() {
        const adminItems = document.querySelectorAll('.admin-item');
        
        adminItems.forEach(item => {
            let startX = 0;
            let endX = 0;
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
                
                endX = e.changedTouches[0].clientX;
                const diff = endX - startX;
                
                item.style.transition = 'transform 0.3s ease, background-color 0.3s ease';
                
                if (diff > 100) {
                    item.style.transform = 'translateX(300px)';
                    item.style.opacity = '0';
                    
                    setTimeout(() => {
                        const scriptTitle = item.getAttribute('data-script-title');
                        this.showSwipeDeleteConfirmation(scriptTitle, item);
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

    showSwipeDeleteConfirmation(scriptTitle, itemElement) {
        const modalHTML = `
            <div class="modal-overlay" id="swipe-delete-modal" style="display:flex">
                <div class="modal animate__animated animate__zoomIn" style="max-width:400px">
                    <div class="modal-header">
                        <h3 style="color:var(--color-danger)">Delete Script</h3>
                        <button class="close-btn" onclick="document.getElementById('swipe-delete-modal').remove()">×</button>
                    </div>
                    <div class="modal-body">
                        <p style="margin-bottom:20px;text-align:center;font-size:16px">Are you sure you want to delete<br><strong>"${scriptTitle}"</strong>?</p>
                        <div style="display:flex;gap:10px;margin-top:24px">
                            <button class="btn btn-secondary btn-full" onclick="document.getElementById('swipe-delete-modal').remove(); app.restoreSwipeItem()">No, Keep It</button>
                            <button class="btn btn-delete btn-full" onclick="app.confirmSwipeDelete('${scriptTitle.replace(/'/g, "\\'")}')">Yes, Delete It</button>
                        </div>
                    </div>
                </div>
            </div>
        `;
        
        const existingModal = document.getElementById('swipe-delete-modal');
        if (existingModal) existingModal.remove();
        
        document.body.insertAdjacentHTML('beforeend', modalHTML);
        
        this.pendingSwipeDelete = {
            scriptTitle: scriptTitle,
            itemElement: itemElement
        };
    },

    restoreSwipeItem() {
        if (this.pendingSwipeDelete && this.pendingSwipeDelete.itemElement) {
            const item = this.pendingSwipeDelete.itemElement;
            item.style.transform = 'translateX(0)';
            item.style.opacity = '1';
            item.style.backgroundColor = '';
            item.style.transition = 'transform 0.3s ease, opacity 0.3s ease, background-color 0.3s ease';
            
            setTimeout(() => {
                item.style.transition = '';
            }, 300);
        }
        this.pendingSwipeDelete = null;
    },

    async confirmSwipeDelete(scriptTitle) {
        const modal = document.getElementById('swipe-delete-modal');
        if (modal) modal.remove();
        
        if (this.actionInProgress) return;
        
        if (!this.currentUser) {
            alert('Please login first.');
            this.restoreSwipeItem();
            return;
        }
        
        if (!scriptTitle || !this.db.scripts[scriptTitle]) {
            alert('Script not found or already deleted.');
            this.restoreSwipeItem();
            return;
        }

        this.actionInProgress = true;
        
        try {
            const scriptId = utils.sanitizeTitle(scriptTitle);
            const scriptData = this.db.scripts[scriptTitle];
            
            const luaPath = `scripts/${scriptId}/raw/${scriptData.filename}`;
            try {
                const luaRes = await this.secureFetch(`https://api.github.com/repos/${CONFIG.user}/${CONFIG.repo}/contents/${luaPath}`);
                
                if (luaRes.ok) {
                    const luaData = await luaRes.json();
                    await this.secureFetch(`https://api.github.com/repos/${CONFIG.user}/${CONFIG.repo}/contents/${luaPath}`, {
                        method: 'DELETE',
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
                const idxRes = await this.secureFetch(`https://api.github.com/repos/${CONFIG.user}/${CONFIG.repo}/contents/${indexPath}`);
                
                if (idxRes.ok) {
                    const idxData = await idxRes.json();
                    await this.secureFetch(`https://api.github.com/repos/${CONFIG.user}/${CONFIG.repo}/contents/${indexPath}`, {
                        method: 'DELETE',
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
            
            const dbRes = await this.secureFetch(`https://api.github.com/repos/${CONFIG.user}/${CONFIG.repo}/contents/database.json`, {
                method: 'PUT',
                body: JSON.stringify({
                    message: `Remove ${scriptTitle} from database`,
                    content: utils.safeBtoa(JSON.stringify(this.db, null, 2)),
                    sha: this.dbSha
                })
            });
            
            if (dbRes.ok) {
                const newDbData = await dbRes.json();
                this.dbSha = newDbData.content.sha;
                
                if (this.pendingSwipeDelete && this.pendingSwipeDelete.itemElement) {
                    const item = this.pendingSwipeDelete.itemElement;
                    item.remove();
                }
                
                setTimeout(() => {
                    location.reload();
                }, 500);
                
            } else {
                throw new Error('Failed to update database');
            }
            
        } catch(e) {
            console.error('Delete error:', e);
            alert('Delete failed: ' + e.message);
            this.restoreSwipeItem();
        } finally {
            this.actionInProgress = false;
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
        if (!this.currentUser) return;
        
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
            const res = await this.secureFetch(`https://api.github.com/repos/${CONFIG.user}/${CONFIG.repo}/contents/scripts/${scriptId}/raw/${s.filename}`);
            
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
        if (!this.currentUser) {
            alert('Please login first.');
            return;
        }
        
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
        
        if (isEditing && !titleChanged) {
            if (this.db.scripts[title] && this.db.scripts[title] !== this.db.scripts[this.originalTitle]) {
                msg.innerHTML = `<span style="color:var(--color-danger)">Script with this title already exists</span>`;
                saveBtn.disabled = false;
                saveBtn.textContent = originalBtnText;
                setTimeout(() => { msg.innerHTML = ''; this.actionInProgress = false; }, 3000);
                return;
            }
        } else if (!isEditing && this.db.scripts[title]) {
            msg.innerHTML = `<span style="color:var(--color-danger)">Script with this title already exists</span>`;
            saveBtn.disabled = false;
            saveBtn.textContent = originalBtnText;
            setTimeout(() => { msg.innerHTML = ''; this.actionInProgress = false; }, 3000);
            return;
        }
        
        msg.innerHTML = `<span class="loading">Publishing...</span>`;
        
        try {
            if (isEditing && titleChanged && this.originalTitle) {
                const oldScriptData = this.db.scripts[this.originalTitle];
                if (oldScriptData) {
                    const oldScriptId = utils.sanitizeTitle(this.originalTitle);
                    
                    try {
                        const oldLuaPath = `scripts/${oldScriptId}/raw/${oldScriptData.filename}`;
                        const luaRes = await this.secureFetch(`https://api.github.com/repos/${CONFIG.user}/${CONFIG.repo}/contents/${oldLuaPath}`);
                        
                        if (luaRes.ok) {
                            const luaData = await luaRes.json();
                            await this.secureFetch(`https://api.github.com/repos/${CONFIG.user}/${CONFIG.repo}/contents/${oldLuaPath}`, {
                                method: 'DELETE',
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
                        const idxRes = await this.secureFetch(`https://api.github.com/repos/${CONFIG.user}/${CONFIG.repo}/contents/${oldIndexPath}`);
                        
                        if (idxRes.ok) {
                            const idxData = await idxRes.json();
                            await this.secureFetch(`https://api.github.com/repos/${CONFIG.user}/${CONFIG.repo}/contents/${oldIndexPath}`, {
                                method: 'DELETE',
                                body: JSON.stringify({
                                    message: `Delete old index`,
                                    sha: idxData.sha
                                })
                            });
                        }
                    } catch(e) {
                        console.warn('Error deleting old index file:', e.message);
                    }
                    
                    delete this.db.scripts[this.originalTitle];
                }
            }
            
            const scriptData = {
                title: title,
                visibility: visibility,
                description: desc,
                expiration: expiration,
                filename: filename,
                size: code.length,
                created: (isEditing && !titleChanged && this.db.scripts[title]) ? this.db.scripts[title].created : new Date().toISOString(),
                updated: new Date().toISOString()
            };
            
            this.db.scripts[title] = scriptData;
            
            const luaPath = `scripts/${scriptId}/raw/${filename}`;
            let luaSha = null;
            
            if (isEditing && !titleChanged) {
                try {
                    const check = await this.secureFetch(`https://api.github.com/repos/${CONFIG.user}/${CONFIG.repo}/contents/${luaPath}`);
                    if (check.ok) {
                        const data = await check.json();
                        luaSha = data.sha;
                    }
                } catch(e) {
                    console.log('Creating new Lua file');
                }
            }
            
            const luaRes = await this.secureFetch(`https://api.github.com/repos/${CONFIG.user}/${CONFIG.repo}/contents/${luaPath}`, {
                method: 'PUT',
                body: JSON.stringify({
                    message: `${isEditing ? 'Update' : 'Create'} ${filename}`,
                    content: utils.safeBtoa(code),
                    sha: luaSha || undefined
                })
            });
            
            if (!luaRes.ok) {
                throw new Error('Failed to save Lua file');
            }
            
            const dbRes = await this.secureFetch(`https://api.github.com/repos/${CONFIG.user}/${CONFIG.repo}/contents/database.json`, {
                method: 'PUT',
                body: JSON.stringify({
                    message: `${isEditing ? (titleChanged ? 'Rename' : 'Update') : 'Add'} ${title}`,
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
                    const check = await this.secureFetch(`https://api.github.com/repos/${CONFIG.user}/${CONFIG.repo}/contents/${indexPath}`);
                    if (check.ok) {
                        const data = await check.json();
                        indexSha = data.sha;
                    }
                } catch(e) {
                    console.log('Creating new index file');
                }
            }
            
            const indexRes = await this.secureFetch(`https://api.github.com/repos/${CONFIG.user}/${CONFIG.repo}/contents/${indexPath}`, {
                method: 'PUT',
                body: JSON.stringify({
                    message: `${isEditing ? 'Update' : 'Create'} index for ${title}`,
                    content: utils.safeBtoa(indexHTML),
                    sha: indexSha || undefined
                })
            });
            
            if (!indexRes.ok) {
                throw new Error('Failed to save index.html');
            }
            
            msg.innerHTML = `<span style="color:var(--color-primary)">${isEditing ? 'Updated' : 'Published'} successfully!</span>`;
            
            if (isEditing && titleChanged) {
                this.currentEditingId = title;
                this.originalTitle = title;
            }
            
            const actionButtons = document.querySelector('.action-buttons');
            const viewBtn = actionButtons.querySelector('.btn-view-script');
            if (viewBtn) {
                viewBtn.href = `scripts/${scriptId}/index.html`;
            } else {
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

    async deleteScript() {
        if (!this.currentUser) {
            alert('Please login first.');
            return;
        }
        
        if (this.actionInProgress) return;
        
        if (!this.currentEditingId) {
            alert('No script selected for deletion.');
            return;
        }

        const scriptTitle = this.currentEditingId;
        
        if (!this.db.scripts[scriptTitle]) {
            alert('Script not found or already deleted.');
            this.switchAdminTab('list');
            return;
        }

        if (!confirm(`Are you sure you want to delete "${scriptTitle}"? This will permanently delete the script, Lua file, and HTML page.`)) {
            return;
        }

        this.actionInProgress = true;
        const msg = document.getElementById('admin-msg');
        msg.innerHTML = `<span class="loading">Deleting script...</span>`;
        
        try {
            const scriptId = utils.sanitizeTitle(scriptTitle);
            const scriptData = this.db.scripts[scriptTitle];
            
            const luaPath = `scripts/${scriptId}/raw/${scriptData.filename}`;
            try {
                const luaRes = await this.secureFetch(`https://api.github.com/repos/${CONFIG.user}/${CONFIG.repo}/contents/${luaPath}`);
                
                if (luaRes.ok) {
                    const luaData = await luaRes.json();
                    await this.secureFetch(`https://api.github.com/repos/${CONFIG.user}/${CONFIG.repo}/contents/${luaPath}`, {
                        method: 'DELETE',
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
                const idxRes = await this.secureFetch(`https://api.github.com/repos/${CONFIG.user}/${CONFIG.repo}/contents/${indexPath}`);
                
                if (idxRes.ok) {
                    const idxData = await idxRes.json();
                    await this.secureFetch(`https://api.github.com/repos/${CONFIG.user}/${CONFIG.repo}/contents/${indexPath}`, {
                        method: 'DELETE',
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
            
            const dbRes = await this.secureFetch(`https://api.github.com/repos/${CONFIG.user}/${CONFIG.repo}/contents/database.json`, {
                method: 'PUT',
                body: JSON.stringify({
                    message: `Remove ${scriptTitle} from database`,
                    content: utils.safeBtoa(JSON.stringify(this.db, null, 2)),
                    sha: this.dbSha
                })
            });
            
            if (dbRes.ok) {
                const newDbData = await dbRes.json();
                this.dbSha = newDbData.content.sha;
                
                msg.innerHTML = `<span style="color:var(--color-primary)">Script deleted successfully!</span>`;
                
                setTimeout(() => {
                    this.resetEditor();
                    this.switchAdminTab('list');
                    msg.innerHTML = '';
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
    }
};

function navigate(path) {
    if (path === 'admin' && !app.currentUser) {
        app.toggleLoginModal();
        return;
    }
    location.hash = path;
}

Object.freeze(CONFIG);
Object.freeze(utils);

app.init();
