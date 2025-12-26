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

    async incrementView(slug) {
        const key = `seen_${slug}`;
        if (localStorage.getItem(key)) return;
        
        const maxRetries = 5;
        let attempt = 0;
        
        while (attempt < maxRetries) {
            try {
                await this.loadViewsData();
                this.viewsData[slug] = (this.viewsData[slug] || 0) + 1;
                this.viewCounts[slug] = this.viewsData[slug];
                
                const response = await fetch(`https://api.github.com/repos/${CONFIG.user}/${CONFIG.repo}/contents/views.json`, {
                    method: 'PUT',
                    headers: { 
                        'Authorization': `token ${this.token || ''}`, 
                        'Content-Type': 'application/json' 
                    },
                    body: JSON.stringify({
                        message: `Update view count for ${slug}`,
                        content: btoa(JSON.stringify(this.viewsData, null, 2)),
                        sha: this.viewsSha
                    })
                });
                
                if (response.ok) {
                    const data = await response.json();
                    this.viewsSha = data.content.sha;
                    localStorage.setItem(key, 'true');
                    
                    const viewerEl = document.getElementById('viewer-views');
                    if (viewerEl) {
                        const span = viewerEl.querySelector('span');
                        if (span) span.textContent = `${this.viewsData[slug]} Views`;
                    }
                    return;
                } else if (response.status === 409 || response.status === 422) {
                    attempt++;
                    const delay = Math.min(1000 * Math.pow(2, attempt), 5000) + Math.random() * 1000;
                    console.log(`Conflict detected, retrying in ${delay}ms (attempt ${attempt}/${maxRetries})`);
                    await new Promise(resolve => setTimeout(resolve, delay));
                    this.viewsSha = null;
                } else { 
                    throw new Error(`HTTP ${response.status}`); 
                }
            } catch(e) { 
                console.log('View increment error:', e);
                attempt++;
                if (attempt >= maxRetries) {
                    console.error('Failed to increment view after max retries');
                    return;
                }
                const delay = Math.min(1000 * Math.pow(2, attempt), 5000) + Math.random() * 1000;
                await new Promise(resolve => setTimeout(resolve, delay));
            }
        }
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
            <div class="script-card animate__animated animate__fadeInUp" onclick="navigate('script/${s.slug}')">
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

    async loadViewer(slug) {
        const scriptData = this.db.scripts?.[slug];
        const content = document.getElementById('script-viewer-content');
        const accessDenied = document.getElementById('access-denied');
        
        if (!scriptData) {
            if (!this.dbLoaded) { 
                this.dbLoaded = true; 
                await this.loadDatabase(); 
                return this.loadViewer(slug); 
            }
            location.hash = ''; 
            return;
        }
        
        const isExpired = scriptData.expiration && new Date(scriptData.expiration) < new Date();
        if ((scriptData.visibility === 'PRIVATE' && !this.currentUser) || (isExpired && !this.currentUser)) {
            content.style.display = 'none';
            accessDenied.style.display = 'flex';
            return;
        }
        
        content.style.display = 'block';
        accessDenied.style.display = 'none';
        
        await this.incrementView(slug);
        const views = await this.getScriptViewCount(slug);
        
        document.getElementById('viewer-title').textContent = scriptData.title;
        document.getElementById('viewer-desc').textContent = scriptData.description || '';
        document.getElementById('viewer-meta').textContent = `File: ${scriptData.filename}`;
        
        const viewsEl = document.getElementById('viewer-views');
        viewsEl.querySelector('span').textContent = `${views} Views`;
        
        const dateEl = document.getElementById('viewer-date');
        dateEl.querySelector('span').textContent = new Date(scriptData.created || Date.now()).toLocaleDateString();
        
        const badgeContainer = document.getElementById('viewer-badges');
        badgeContainer.innerHTML = `<span class="badge badge-${scriptData.visibility.toLowerCase()}">${scriptData.visibility}</span>`;
        
        const expireBanner = document.getElementById('expiration-banner');
        const codeContainer = document.getElementById('code-box-container');
        if (isExpired) {
            expireBanner.style.display = 'block';
            codeContainer.style.opacity = '0.5';
        } else {
            expireBanner.style.display = 'none';
            codeContainer.style.opacity = '1';
        }
        
        try {
            const res = await fetch(`https://api.github.com/repos/${CONFIG.user}/${CONFIG.repo}/contents/scripts/${slug}/raw/${scriptData.filename}`);
            const data = await res.json();
            const code = atob(data.content);
            document.getElementById('code-display').textContent = code;
            this.currentScriptUrl = data.download_url;
            this.currentScriptCode = code;
            this.currentScriptFilename = scriptData.filename;
            Prism.highlightAll();
        } catch(e) { 
            document.getElementById('code-display').textContent = "Error loading raw file."; 
        }
    },

    copyScript(btn) {
        const code = document.getElementById('code-display').textContent;
        navigator.clipboard.writeText(code).then(() => {
            const original = btn.innerHTML;
            btn.innerHTML = 'Copied';
            setTimeout(() => btn.innerHTML = original, 2000);
        });
    },

    downloadScript() {
        if (!this.currentScriptCode) return;
        const element = document.createElement('a');
        element.setAttribute('href', 'data:text/plain;charset=utf-8,' + encodeURIComponent(this.currentScriptCode));
        element.setAttribute('download', this.currentScriptFilename);
        element.style.display = 'none';
        document.body.appendChild(element);
        element.click();
        document.body.removeChild(element);
    },

    viewRaw() { 
        if (this.currentScriptUrl) window.open(this.currentScriptUrl, '_blank'); 
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
        const oldFilename = oldSlug ? this.db.scripts[oldSlug]?.filename : null;
        const isRename = oldSlug && oldSlug !== newSlug;
        
        msg.innerHTML = `<span class="loading">${isRename ? 'Re-publishing' : 'Saving'}...</span>`;
        
        try {
            let fileSha = null;
            const checkRes = await fetch(`https://api.github.com/repos/${CONFIG.user}/${CONFIG.repo}/contents/scripts/${newSlug}/raw/${newFilename}`, {
                headers: { 'Authorization': `token ${this.token}` }
            });
            if (checkRes.ok) fileSha = (await checkRes.json()).sha;
            
            await fetch(`https://api.github.com/repos/${CONFIG.user}/${CONFIG.repo}/contents/scripts/${newSlug}/raw/${newFilename}`, {
                method: 'PUT',
                headers: { 
                    'Authorization': `token ${this.token}`, 
                    'Content-Type': 'application/json' 
                },
                body: JSON.stringify({
                    message: `${isRename ? 'Create' : 'Update'} ${newFilename}`,
                    content: btoa(unescape(encodeURIComponent(code))),
                    sha: fileSha
                })
            });
            
            if (isRename && oldFilename && oldSlug) {
                try {
                    const oldFileRes = await fetch(`https://api.github.com/repos/${CONFIG.user}/${CONFIG.repo}/contents/scripts/${oldSlug}/raw/${oldFilename}`, {
                        headers: { 'Authorization': `token ${this.token}` }
                    });
                    if (oldFileRes.ok) {
                        const oldFileSha = (await oldFileRes.json()).sha;
                        await fetch(`https://api.github.com/repos/${CONFIG.user}/${CONFIG.repo}/contents/scripts/${oldSlug}/raw/${oldFilename}`, {
                            method: 'DELETE',
                            headers: { 
                                'Authorization': `token ${this.token}`, 
                                'Content-Type': 'application/json' 
                            },
                            body: JSON.stringify({ 
                                message: `Delete ${oldFilename}`, 
                                sha: oldFileSha 
                            })
                        });
                    }
                } catch(e) {
                    console.log('Cleanup error (non-critical):', e);
                }
            }
            
            await this.loadDatabase();
            
            if (isRename && oldSlug) delete this.db.scripts[oldSlug];
            
            const existing = this.db.scripts[newSlug] || {};
            this.db.scripts[newSlug] = {
                title: title, 
                visibility: visibility, 
                description: desc, 
                expiration: expiration,
                filename: newFilename,
                created: isRename ? new Date().toISOString() : (existing.created || new Date().toISOString()),
                updated: new Date().toISOString()
            };
            
            await fetch(`https://api.github.com/repos/${CONFIG.user}/${CONFIG.repo}/contents/database.json`, {
                method: 'PUT',
                headers: { 
                    'Authorization': `token ${this.token}`, 
                    'Content-Type': 'application/json' 
                },
                body: JSON.stringify({
                    message: isRename ? `Update database - republish ${newSlug}` : `Update database`,
                    content: btoa(JSON.stringify(this.db, null, 2)),
                    sha: this.dbSha
                })
            });
            
            msg.innerHTML = `<span style="color:var(--accent)">${isRename ? 'Re-published' : 'Saved'} successfully!</span>`;
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
            const checkRes = await fetch(`https://api.github.com/repos/${CONFIG.user}/${CONFIG.repo}/contents/scripts/${slug}/raw/${filename}`, {
                headers: { 'Authorization': `token ${this.token}` }
            });
            if (checkRes.ok) {
                const sha = (await checkRes.json()).sha;
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
        
        if (hash.startsWith('script/')) {
            const slug = hash.split('/')[1];
            document.getElementById('view-script').style.display = 'block';
            this.loadViewer(slug);
        } else if (hash === 'admin') {
            if (!this.currentUser) { 
                navigate('home'); 
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
