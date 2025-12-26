const CONFIG = { 
    user: 'simplyIeaf', 
    repo: 'simplyIeaf.github.io',
    cacheBuster: () => Date.now()
};

const app = {
    db: { scripts: {} }, 
    dbSha: null, 
    viewsData: {}, 
    viewsSha: null,
    token: localStorage.getItem('gh_token'), 
    currentUser: null,
    currentFilter: 'all', 
    currentSort: 'newest', 
    viewCounts: {},
    actionInProgress: false, 
    originalSlug: null,
    currentScriptUrl: null,
    currentScriptCode: null,
    currentScriptFilename: null,
    currentEditingSlug: null,
    currentEditingFile: null,
    dbLoaded: false,
    
    async init() {
        if (this.token) await this.verifyToken(true);
        await this.loadDatabase();
        await this.fetchAllViews(); 
        this.handleRouting();
        window.addEventListener('hashchange', () => this.handleRouting());
    },

    generateScriptHTML(slug, scriptData) {
        return `<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>${scriptData.title} - Leaf's Scripts</title>
    <link rel="icon" type="image/png" href="https://avatars.githubusercontent.com/u/220599690?v=4">
    <link rel="stylesheet" href="../../style.css">
    <link href="https://cdnjs.cloudflare.com/ajax/libs/prism/1.29.0/themes/prism-tomorrow.min.css" rel="stylesheet" />
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
</head>
<body>
    <nav class="navbar">
        <div class="nav-content">
            <div class="nav-left">
                <a href="../../index.html" class="brand" style="text-decoration: none; color: inherit;">
                    <img src="https://avatars.githubusercontent.com/u/220599690?v=4&size=40" class="nav-icon" alt="Profile">
                    <span class="nav-title">Leaf's Scripts</span>
                </a>
            </div>
            <div class="nav-right">
                <a href="../../index.html" class="btn btn-secondary btn-sm">← Back to Home</a>
            </div>
        </div>
    </nav>
    
    <div class="container">
        <div class="script-header-lg">
            <div>
                <h1>${scriptData.title}</h1>
                <div class="meta-row">
                    <span class="meta-badge">
                        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                            <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"></path>
                            <circle cx="12" cy="12" r="3"></circle>
                        </svg>
                        <span id="view-count">Loading...</span>
                    </span>
                    <span class="meta-badge">
                        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                            <rect x="3" y="4" width="18" height="18" rx="2" ry="2"></rect>
                            <line x1="16" y1="2" x2="16" y2="6"></line>
                            <line x1="8" y1="2" x2="8" y2="6"></line>
                            <line x1="3" y1="10" x2="21" y2="10"></line>
                        </svg>
                        <span>${new Date(scriptData.created || Date.now()).toLocaleDateString()}</span>
                    </span>
                </div>
            </div>
            <div class="badges">
                <span class="badge badge-${scriptData.visibility.toLowerCase()}">${scriptData.visibility}</span>
            </div>
        </div>

        ${scriptData.description ? `<p class="script-desc">${scriptData.description}</p>` : ''}
        
        <div class="code-box">
            <div class="toolbar">
                <div class="toolbar-left">
                    <span class="file-info">raw/${scriptData.filename}</span>
                </div>
                <div class="toolbar-right">
                    <button class="btn btn-sm" onclick="downloadScript()">
                        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                            <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"></path>
                            <polyline points="7 10 12 15 17 10"></polyline>
                            <line x1="12" y1="15" x2="12" y2="3"></line>
                        </svg>
                        Download
                    </button>
                    <button class="btn btn-sm" onclick="copyScript(this)">
                        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                            <rect x="9" y="9" width="13" height="13" rx="2" ry="2"></rect>
                            <path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"></path>
                        </svg>
                        Copy
                    </button>
                    <a href="raw/${scriptData.filename}" class="btn btn-secondary btn-sm" target="_blank">Raw</a>
                </div>
            </div>
            <pre><code id="code-display" class="language-lua">Loading source...</code></pre>
        </div>
    </div>

    <script src="https://cdnjs.cloudflare.com/ajax/libs/prism/1.29.0/prism.min.js"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/prism/1.29.0/components/prism-lua.min.js"></script>
    <script>
        const slug = '${slug}';
        const filename = '${scriptData.filename}';
        
        async function loadScript() {
            try {
                const res = await fetch(\`raw/\${filename}\`);
                const code = await res.text();
                document.getElementById('code-display').textContent = code;
                Prism.highlightAll();
            } catch(e) {
                document.getElementById('code-display').textContent = 'Error loading script.';
            }
        }
        
        async function loadViewCount() {
            try {
                const res = await fetch('../../views.json?t=' + Date.now());
                const views = await res.json();
                document.getElementById('view-count').textContent = (views[slug] || 0) + ' Views';
            } catch(e) {
                document.getElementById('view-count').textContent = '0 Views';
            }
        }
        
        async function incrementView() {
            const key = 'seen_' + slug;
            if (localStorage.getItem(key)) return;
            
            try {
                const token = localStorage.getItem('gh_token') || '';
                const res = await fetch('../../views.json?t=' + Date.now());
                let views = {};
                let sha = null;
                
                if (res.ok) {
                    const data = await res.json();
                    views = data;
                }
                
                const shaRes = await fetch('https://api.github.com/repos/${CONFIG.user}/${CONFIG.repo}/contents/views.json');
                if (shaRes.ok) sha = (await shaRes.json()).sha;
                
                views[slug] = (views[slug] || 0) + 1;
                
                await fetch('https://api.github.com/repos/${CONFIG.user}/${CONFIG.repo}/contents/views.json', {
                    method: 'PUT',
                    headers: { 'Authorization': 'token ' + token, 'Content-Type': 'application/json' },
                    body: JSON.stringify({
                        message: 'Update view count for ' + slug,
                        content: btoa(JSON.stringify(views, null, 2)),
                        sha: sha
                    })
                });
                
                localStorage.setItem(key, 'true');
                document.getElementById('view-count').textContent = views[slug] + ' Views';
            } catch(e) {
                console.log('View increment failed:', e);
            }
        }
        
        function copyScript(btn) {
            const code = document.getElementById('code-display').textContent;
            navigator.clipboard.writeText(code).then(() => {
                const original = btn.innerHTML;
                btn.innerHTML = 'Copied!';
                setTimeout(() => btn.innerHTML = original, 2000);
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
        loadViewCount();
        incrementView();
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
        if (!token) { 
            this.actionInProgress = false; 
            return; 
        }
        this.token = token;
        const success = await this.verifyToken(false);
        if (success) {
            localStorage.setItem('gh_token', token);
            this.toggleLoginModal();
            await this.loadDatabase();
            this.renderList();
        }
        setTimeout(() => { this.actionInProgress = false; }, 750);
    },

    logout() {
        if (this.actionInProgress) return;
        this.actionInProgress = true;
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
                this.db = JSON.parse(atob(file.content));
            }
            this.dbLoaded = true;
            this.renderList();
            this.renderAdminList();
        } catch (e) { 
            console.error("DB Error", e); 
        }
    },

    async fetchAllViews() {
        await this.loadViewsData();
        const scripts = Object.keys(this.db.scripts || {});
        for (const slug of scripts) {
            this.viewCounts[slug] = this.viewsData[slug] || 0;
        }
    },

    async loadViewsData() {
        try {
            const res = await fetch(`https://api.github.com/repos/${CONFIG.user}/${CONFIG.repo}/contents/views.json?t=${CONFIG.cacheBuster()}`);
            if (res.status === 404) {
                this.viewsData = {};
                this.viewsSha = null;
            } else if (res.ok) {
                const file = await res.json();
                this.viewsSha = file.sha;
                this.viewsData = JSON.parse(atob(file.content));
            }
        } catch (e) {
            console.log('Views data load error:', e);
            this.viewsData = {};
            this.viewsSha = null;
        }
    },

    async getScriptViewCount(slug) {
        if (this.viewCounts[slug] !== undefined) return this.viewCounts[slug];
        await this.loadViewsData();
        const count = this.viewsData[slug] || 0;
        this.viewCounts[slug] = count;
        return count;
    },

    async renderList() {
        const list = document.getElementById('script-list');
        const scripts = Object.entries(this.db.scripts || {}).map(([slug, data]) => ({ slug, ...data }));
        const filtered = this.filterLogic(scripts);
        const sorted = this.sortLogic(filtered);
        
        if (sorted.length === 0) {
            list.innerHTML = `
                <div class="empty-state">
                    <div class="empty-icon">
                        <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                            <path d="M22 19a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h5l2 3h9a2 2 0 0 1 2 2z"></path>
                        </svg>
                    </div>
                    <h2>No scripts found</h2>
                </div>
            `;
            return;
        }
        
        list.innerHTML = sorted.map(s => `
            <div class="script-card animate__animated animate__fadeInUp" onclick="window.location.href='scripts/${s.slug}/index.html'">
                <div class="card-content">
                    <div class="card-header-section">
                        <h3 class="script-title">${s.title}</h3>
                        ${s.visibility === 'PRIVATE' ? '<span class="badge badge-private">PRIVATE</span>' : ''}
                    </div>
                    <div class="card-meta">
                        <span>${new Date(s.created || Date.now()).toLocaleDateString()}</span>
                    </div>
                </div>
            </div>
        `).join('');
    },

    filterLogic(scripts) {
        const query = document.getElementById('search').value.toLowerCase();
        return scripts.filter(s => {
            if (!s.title.toLowerCase().includes(query)) return false;
            if (s.visibility === 'PRIVATE' && !this.currentUser) return false;
            if (s.visibility === 'UNLISTED') return false; 
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
            if (this.currentSort === 'views') return (this.viewCounts[b.slug] || 0) - (this.viewCounts[a.slug] || 0);
            return 0;
        });
    },

    filterCategory(cat, e) {
        if (e) {
            e.preventDefault();
            document.querySelectorAll('.sidebar-link').forEach(l => l.classList.remove('active'));
            e.target.classList.add('active');
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
        const scripts = Object.entries(this.db.scripts || {}).map(([slug, data]) => ({ slug, ...data }));
        
        document.getElementById('total-stats').textContent = `${scripts.length} Total Scripts`;
        
        list.innerHTML = scripts.map(s => `
            <div class="admin-item" onclick="app.populateEditor('${s.slug}')">
                <div class="admin-item-left">
                    <strong>${s.title}</strong>
                    <div class="admin-meta">
                        <span class="badge badge-sm badge-${s.visibility.toLowerCase()}">${s.visibility}</span>
                        <span class="text-muted"> • <span id="admin-view-${s.slug}">...</span> Views</span>
                    </div>
                </div>
                <div class="admin-item-right">
                    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                        <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"></path>
                        <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"></path>
                    </svg>
                </div>
            </div>
        `).join('');
        
        scripts.forEach(async s => {
            const count = await this.getScriptViewCount(s.slug);
            const el = document.getElementById(`admin-view-${s.slug}`);
            if (el) el.textContent = count;
        });
    },

    resetEditor() {
        document.getElementById('editor-heading').textContent = 'Create New Script';
        document.getElementById('edit-title').value = '';
        document.getElementById('edit-visibility').value = 'PUBLIC';
        document.getElementById('edit-desc').value = '';
        document.getElementById('edit-expire').value = '';
        document.getElementById('edit-code').value = '';
        document.getElementById('btn-delete').style.display = 'none';
        this.currentEditingSlug = null;
        this.originalSlug = null;
    },

    async populateEditor(slug) {
        const s = this.db.scripts[slug];
        if (!s) return;
        
        this.currentEditingSlug = slug;
        this.originalSlug = slug;
        this.currentEditingFile = s.filename;
        this.switchAdminTab('create');
        
        document.getElementById('editor-heading').textContent = `Edit: ${s.title}`;
        document.getElementById('edit-title').value = s.title;
        document.getElementById('edit-visibility').value = s.visibility;
        document.getElementById('edit-desc').value = s.description || '';
        document.getElementById('edit-expire').value = s.expiration || '';
        
        try {
            const res = await fetch(`https://api.github.com/repos/${CONFIG.user}/${CONFIG.repo}/contents/scripts/${slug}/raw/${s.filename}`);
            const data = await res.json();
            document.getElementById('edit-code').value = atob(data.content);
        } catch(e) { 
            document.getElementById('edit-code').value = "Error loading content"; 
        }
        
        const btnDelete = document.getElementById('btn-delete');
        btnDelete.style.display = 'inline-flex';
        btnDelete.onclick = () => this.deleteScript(slug, s.filename);
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
            alert('Title and Code are required'); 
            this.actionInProgress = false; 
            return; 
        }
        
        const newSlug = title.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-+|-+$/g, '');
        const newFilename = `${newSlug}.lua`;
        const oldSlug = this.originalSlug;
        const isRename = oldSlug && oldSlug !== newSlug;
        
        msg.innerHTML = `<span class="loading">Publishing...</span>`;
        
        try {
            // Create/update the Lua file
            let luaSha = null;
            const luaCheckRes = await fetch(`https://api.github.com/repos/${CONFIG.user}/${CONFIG.repo}/contents/scripts/${newSlug}/raw/${newFilename}`, {
                headers: { 'Authorization': `token ${this.token}` }
            });
            if (luaCheckRes.ok) luaSha = (await luaCheckRes.json()).sha;
            
            await fetch(`https://api.github.com/repos/${CONFIG.user}/${CONFIG.repo}/contents/scripts/${newSlug}/raw/${newFilename}`, {
                method: 'PUT',
                headers: { 
                    'Authorization': `token ${this.token}`, 
                    'Content-Type': 'application/json' 
                },
                body: JSON.stringify({
                    message: `${isRename ? 'Create' : 'Update'} ${newFilename}`,
                    content: btoa(unescape(encodeURIComponent(code))),
                    sha: luaSha
                })
            });

            // Update database
            await this.loadDatabase();
            if (isRename && oldSlug) delete this.db.scripts[oldSlug];
            
            const existing = this.db.scripts[newSlug] || {};
            const scriptData = {
                title: title, 
                visibility: visibility, 
                description: desc, 
                expiration: expiration,
                filename: newFilename,
                created: isRename ? new Date().toISOString() : (existing.created || new Date().toISOString()),
                updated: new Date().toISOString()
            };
            this.db.scripts[newSlug] = scriptData;
            
            await fetch(`https://api.github.com/repos/${CONFIG.user}/${CONFIG.repo}/contents/database.json`, {
                method: 'PUT',
                headers: { 
                    'Authorization': `token ${this.token}`, 
                    'Content-Type': 'application/json' 
                },
                body: JSON.stringify({
                    message: `Update database - ${isRename ? 'republish' : 'update'} ${newSlug}`,
                    content: btoa(JSON.stringify(this.db, null, 2)),
                    sha: this.dbSha
                })
            });

            // Create/update index.html for the script
            const indexHTML = this.generateScriptHTML(newSlug, scriptData);
            let indexSha = null;
            const indexCheckRes = await fetch(`https://api.github.com/repos/${CONFIG.user}/${CONFIG.repo}/contents/scripts/${newSlug}/index.html`, {
                headers: { 'Authorization': `token ${this.token}` }
            });
            if (indexCheckRes.ok) indexSha = (await indexCheckRes.json()).sha;
            
            await fetch(`https://api.github.com/repos/${CONFIG.user}/${CONFIG.repo}/contents/scripts/${newSlug}/index.html`, {
                method: 'PUT',
                headers: { 
                    'Authorization': `token ${this.token}`, 
                    'Content-Type': 'application/json' 
                },
                body: JSON.stringify({
                    message: `${isRename ? 'Create' : 'Update'} index.html for ${newSlug}`,
                    content: btoa(indexHTML),
                    sha: indexSha
                })
            });

            // Delete old files if renamed
            if (isRename && oldSlug) {
                try {
                    // Delete old lua file
                    const oldLuaRes = await fetch(`https://api.github.com/repos/${CONFIG.user}/${CONFIG.repo}/contents/scripts/${oldSlug}/raw/${oldSlug}.lua`, {
                        headers: { 'Authorization': `token ${this.token}` }
                    });
                    if (oldLuaRes.ok) {
                        const oldLuaSha = (await oldLuaRes.json()).sha;
                        await fetch(`https://api.github.com/repos/${CONFIG.user}/${CONFIG.repo}/contents/scripts/${oldSlug}/raw/${oldSlug}.lua`, {
                            method: 'DELETE',
                            headers: { 
                                'Authorization': `token ${this.token}`, 
                                'Content-Type': 'application/json' 
                            },
                            body: JSON.stringify({ 
                                message: `Delete old ${oldSlug}.lua`, 
                                sha: oldLuaSha 
                            })
                        });
                    }

                    // Delete old index.html
                    const oldIndexRes = await fetch(`https://api.github.com/repos/${CONFIG.user}/${CONFIG.repo}/contents/scripts/${oldSlug}/index.html`, {
                        headers: { 'Authorization': `token ${this.token}` }
                    });
                    if (oldIndexRes.ok) {
                        const oldIndexSha = (await oldIndexRes.json()).sha;
                        await fetch(`https://api.github.com/repos/${CONFIG.user}/${CONFIG.repo}/contents/scripts/${oldSlug}/index.html`, {
                            method: 'DELETE',
                            headers: { 
                                'Authorization': `token ${this.token}`, 
                                'Content-Type': 'application/json' 
                            },
                            body: JSON.stringify({ 
                                message: `Delete old index.html for ${oldSlug}`, 
                                sha: oldIndexSha 
                            })
                        });
                    }
                } catch(e) {
                    console.log('Cleanup error (non-critical):', e);
                }
            }
            
            msg.innerHTML = `<span style="color:var(--accent)">Published successfully!</span>`;
            setTimeout(() => { 
                msg.innerHTML = ''; 
                this.switchAdminTab('list'); 
                this.actionInProgress = false; 
            }, 1500);
        } catch(e) {
            msg.innerHTML = `<span style="color:red">Error: ${e.message}</span>`;
            setTimeout(() => { this.actionInProgress = false; }, 750);
        }
    },

    async deleteScript(slug, filename) {
        if (this.actionInProgress) return;
        if (!confirm('Delete this script permanently?')) return;
        this.actionInProgress = true;
        
        try {
            // Delete lua file
            const luaRes = await fetch(`https://api.github.com/repos/${CONFIG.user}/${CONFIG.repo}/contents/scripts/${slug}/raw/${filename}`, {
                headers: { 'Authorization': `token ${this.token}` }
            });
            if (luaRes.ok) {
                const sha = (await luaRes.json()).sha;
                await fetch(`https://api.github.com/repos/${CONFIG.user}/${CONFIG.repo}/contents/scripts/${slug}/raw/${filename}`, {
                    method: 'DELETE',
                    headers: { 
                        'Authorization': `token ${this.token}`, 
                        'Content-Type': 'application/json' 
                    },
                    body: JSON.stringify({ 
                        message: `Delete ${filename}`, 
                        sha: sha 
                    })
                });
            }

            // Delete index.html
            const indexRes = await fetch(`https://api.github.com/repos/${CONFIG.user}/${CONFIG.repo}/contents/scripts/${slug}/index.html`, {
                headers: { 'Authorization': `token ${this.token}` }
            });
            if (indexRes.ok) {
                const sha = (await indexRes.json()).sha;
                await fetch(`https://api.github.com/repos/${CONFIG.user}/${CONFIG.repo}/contents/scripts/${slug}/index.html`, {
                    method: 'DELETE',
                    headers: { 
                        'Authorization': `token ${this.token}`, 
                        'Content-Type': 'application/json' 
                    },
                    body: JSON.stringify({ 
                        message: `Delete index.html for ${slug}`, 
                        sha: sha 
                    })
                });
            }
            
            await this.loadDatabase();
            delete this.db.scripts[slug];
            
            await fetch(`https://api.github.com/repos/${CONFIG.user}/${CONFIG.repo}/contents/database.json`, {
                method: 'PUT',
                headers: { 
                    'Authorization': `token ${this.token}`, 
                    'Content-Type': 'application/json' 
                },
                body: JSON.stringify({
                    message: `Remove ${slug} from db`,
                    content: btoa(JSON.stringify(this.db, null, 2)),
                    sha: this.dbSha
                })
            });
            
            setTimeout(() => { 
                this.switchAdminTab('list'); 
                this.actionInProgress = false; 
            }, 750);
        } catch(e) {
            alert('Delete failed: ' + e.message);
            setTimeout(() => { this.actionInProgress = false; }, 750);
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
