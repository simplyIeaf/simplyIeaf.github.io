const CONFIG = { 
    user: 'simplyIeaf', 
    repo: 'simplyIeaf.github.io',
    cacheBuster: () => Date.now()
};

const utils = {
    debounce(func, wait) {
        let timeout;
        return function(...args) {
            clearTimeout(timeout);
            timeout = setTimeout(() => func.apply(this, args), wait);
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
            const isValid = await this.verifyToken(true);
            if (isValid) await this.loadDatabase();
        } else {
            await this.loadDatabase();
        }
        this.handleRouting();
    },

    setupListeners() {
        window.addEventListener('hashchange', () => this.handleRouting());
        document.addEventListener('click', async (e) => {
            const target = e.target.closest('[data-action]');
            if (!target) return;
            const action = target.getAttribute('data-action');
            const value = target.getAttribute('data-value');
            if (action === 'navigate') {
                window.location.hash = value;
            } else if (action === 'login') {
                this.login();
            } else if (action === 'logout') {
                this.logout();
            } else if (action === 'toggle-modal') {
                this.toggleLoginModal();
            } else if (action === 'save') {
                this.saveScript();
            } else if (action === 'delete') {
                this.executeDeleteProcedure();
            } else if (action === 'admin-tab') {
                this.switchAdminTab(value);
            } else if (action === 'edit-script') {
                this.populateEditor(value);
            } else if (action === 'filter') {
                e.preventDefault();
                this.filterCategory(value, target);
            }
        });
        this.debouncedRender = utils.debounce(() => this.renderList(), 300);
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
            const res = await fetch('https://api.github.com/user', { headers: this.getHeaders() });
            if (!res.ok) throw new Error();
            this.currentUser = await res.json();
            document.getElementById('auth-section').style.display = 'none';
            document.getElementById('user-section').style.display = 'flex';
            document.getElementById('private-filter').style.display = 'block';
            return true;
        } catch (e) {
            this.token = null;
            localStorage.removeItem('gh_token');
            return false;
        }
    },

    async login() {
        const token = document.getElementById('auth-token').value.trim();
        if (!token) return;
        this.token = token;
        if (await this.verifyToken(false)) {
            localStorage.setItem('gh_token', token);
            this.toggleLoginModal();
            await this.loadDatabase();
            this.handleRouting();
        }
    },

    logout() {
        localStorage.removeItem('gh_token');
        window.location.href = window.location.pathname; 
    },

    async loadDatabase() {
        const res = await fetch(`https://api.github.com/repos/${CONFIG.user}/${CONFIG.repo}/contents/database.json?t=${Date.now()}`, { headers: this.getHeaders() });
        if (res.ok) {
            const data = await res.json();
            this.dbSha = data.sha;
            this.db = JSON.parse(utils.safeAtob(data.content));
            this.renderList();
        }
    },

    async executeDeleteProcedure() {
        if (!this.currentEditingId || this.actionInProgress) return;
        if (!confirm(`Permanently remove "${this.currentEditingId}" and all its files?`)) return;

        this.actionInProgress = true;
        const msg = document.getElementById('admin-msg');
        msg.innerHTML = '<span style="color:orange">Deleting Files...</span>';

        const id = utils.sanitizeTitle(this.currentEditingId);
        const script = this.db.scripts[this.currentEditingId];
        const files = [
            `scripts/${id}/raw/${script.filename}`,
            `scripts/${id}/index.html`
        ];

        try {
            for (const path of files) {
                const getFile = await fetch(`https://api.github.com/repos/${CONFIG.user}/${CONFIG.repo}/contents/${path}`, { headers: this.getHeaders() });
                if (getFile.ok) {
                    const fileData = await getFile.json();
                    await fetch(`https://api.github.com/repos/${CONFIG.user}/${CONFIG.repo}/contents/${path}`, {
                        method: 'DELETE',
                        headers: this.getHeaders(),
                        body: JSON.stringify({ message: `Purge ${path}`, sha: fileData.sha })
                    });
                }
            }

            delete this.db.scripts[this.currentEditingId];
            const dbRes = await fetch(`https://api.github.com/repos/${CONFIG.user}/${CONFIG.repo}/contents/database.json`, {
                method: 'PUT',
                headers: this.getHeaders(),
                body: JSON.stringify({
                    message: `Remove ${this.currentEditingId} from registry`,
                    content: utils.safeBtoa(JSON.stringify(this.db, null, 2)),
                    sha: this.dbSha
                })
            });

            if (dbRes.ok) {
                const dbData = await dbRes.json();
                this.dbSha = dbData.content.sha;
                msg.innerHTML = '<span style="color:var(--accent)">Successfully Deleted</span>';
                setTimeout(() => {
                    this.switchAdminTab('list');
                    this.actionInProgress = false;
                }, 1000);
            }
        } catch (e) {
            msg.innerHTML = '<span style="color:red">Error during deletion</span>';
            this.actionInProgress = false;
        }
    },

    async saveScript() {
        if (this.actionInProgress) return;
        const title = document.getElementById('edit-title').value.trim();
        const code = document.getElementById('edit-code').value;
        if (!title || !code) return;

        this.actionInProgress = true;
        const msg = document.getElementById('admin-msg');
        msg.innerHTML = "Processing...";

        try {
            const id = utils.sanitizeTitle(title);
            const filename = `${id}.lua`;

            if (this.currentEditingId && this.currentEditingId !== title) {
                const oldId = utils.sanitizeTitle(this.currentEditingId);
                const oldScript = this.db.scripts[this.currentEditingId];
                const oldFiles = [`scripts/${oldId}/raw/${oldScript.filename}`, `scripts/${oldId}/index.html`];
                for (const path of oldFiles) {
                    const g = await fetch(`https://api.github.com/repos/${CONFIG.user}/${CONFIG.repo}/contents/${path}`, { headers: this.getHeaders() });
                    if (g.ok) {
                        const d = await g.json();
                        await fetch(`https://api.github.com/repos/${CONFIG.user}/${CONFIG.repo}/contents/${path}`, { method: 'DELETE', headers: this.getHeaders(), body: JSON.stringify({ message: "Rename cleanup", sha: d.sha }) });
                    }
                }
                delete this.db.scripts[this.currentEditingId];
            }

            const luaPath = `scripts/${id}/raw/${filename}`;
            let luaSha = null;
            const cL = await fetch(`https://api.github.com/repos/${CONFIG.user}/${CONFIG.repo}/contents/${luaPath}`, { headers: this.getHeaders() });
            if (cL.ok) luaSha = (await cL.json()).sha;

            await fetch(`https://api.github.com/repos/${CONFIG.user}/${CONFIG.repo}/contents/${luaPath}`, {
                method: 'PUT',
                headers: this.getHeaders(),
                body: JSON.stringify({ message: `Upload ${filename}`, content: utils.safeBtoa(code), sha: luaSha || undefined })
            });

            this.db.scripts[title] = {
                title,
                visibility: document.getElementById('edit-visibility').value,
                description: document.getElementById('edit-desc').value,
                expiration: document.getElementById('edit-expire').value,
                filename,
                created: this.db.scripts[title]?.created || new Date().toISOString(),
                updated: new Date().toISOString()
            };

            const htmlContent = `<!DOCTYPE html><html><head><meta charset="UTF-8"><title>${title}</title><link rel="stylesheet" href="../../style.css"></head><body><div class="container"><h1>${title}</h1><pre><code id="c">${utils.escapeHtml(code)}</code></pre></div></body></html>`;
            const indexPath = `scripts/${id}/index.html`;
            let indexSha = null;
            const cI = await fetch(`https://api.github.com/repos/${CONFIG.user}/${CONFIG.repo}/contents/${indexPath}`, { headers: this.getHeaders() });
            if (cI.ok) indexSha = (await cI.json()).sha;

            await fetch(`https://api.github.com/repos/${CONFIG.user}/${CONFIG.repo}/contents/${indexPath}`, {
                method: 'PUT',
                headers: this.getHeaders(),
                body: JSON.stringify({ message: "Update UI", content: utils.safeBtoa(htmlContent), sha: indexSha || undefined })
            });

            const dbUpdate = await fetch(`https://api.github.com/repos/${CONFIG.user}/${CONFIG.repo}/contents/database.json`, {
                method: 'PUT',
                headers: this.getHeaders(),
                body: JSON.stringify({ message: "Sync Registry", content: utils.safeBtoa(JSON.stringify(this.db, null, 2)), sha: this.dbSha })
            });
            const dbFinal = await dbUpdate.json();
            this.dbSha = dbFinal.content.sha;

            this.switchAdminTab('list');
        } catch (e) { msg.innerHTML = "Save Error"; }
        this.actionInProgress = false;
    },

    handleRouting() {
        const hash = window.location.hash.slice(1);
        document.getElementById('view-home').style.display = 'none';
        document.getElementById('view-admin').style.display = 'none';
        if (hash === 'admin' && this.currentUser) {
            document.getElementById('view-admin').style.display = 'block';
            this.switchAdminTab('list');
        } else {
            document.getElementById('view-home').style.display = 'block';
            this.renderList();
        }
    },

    toggleLoginModal() {
        const m = document.getElementById('login-modal');
        m.style.display = m.style.display === 'flex' ? 'none' : 'flex';
    },

    renderList() {
        const list = document.getElementById('script-list');
        const q = document.getElementById('search').value.toLowerCase();
        const items = Object.entries(this.db.scripts).filter(([t, s]) => {
            if (!t.toLowerCase().includes(q)) return false;
            if (!this.currentUser && s.visibility !== 'PUBLIC') return false;
            return true;
        });
        list.innerHTML = items.map(([t, s]) => `<div class="script-card" onclick="window.location.href='scripts/${utils.sanitizeTitle(t)}/index.html'"><h3 class="script-title">${t}</h3><div class="card-meta">${s.visibility}</div></div>`).join('');
    },

    renderAdminList() {
        const list = document.getElementById('admin-list');
        list.innerHTML = Object.keys(this.db.scripts).map(t => `<div class="admin-item" data-action="edit-script" data-value="${t}"><strong>${t}</strong><span class="badge badge-sm">${this.db.scripts[t].visibility}</span></div>`).join('');
    },

    async populateEditor(title) {
        const s = this.db.scripts[title];
        this.currentEditingId = title;
        this.switchAdminTab('create');
        document.getElementById('edit-title').value = s.title;
        document.getElementById('edit-visibility').value = s.visibility;
        document.getElementById('edit-desc').value = s.description || '';
        document.getElementById('edit-expire').value = s.expiration || '';
        document.getElementById('edit-code').value = "Fetching Source...";
        document.getElementById('btn-delete').style.display = 'block';
        const res = await fetch(`https://api.github.com/repos/${CONFIG.user}/${CONFIG.repo}/contents/scripts/${utils.sanitizeTitle(title)}/raw/${s.filename}`, { headers: this.getHeaders() });
        const data = await res.json();
        document.getElementById('edit-code').value = utils.safeAtob(data.content);
    },

    switchAdminTab(tab) {
        document.querySelectorAll('.admin-tab').forEach(t => t.style.display = 'none');
        document.getElementById(`admin-tab-${tab}`).style.display = 'block';
        if (tab === 'list') this.renderAdminList();
        if (tab === 'create' && !this.currentEditingId) this.resetEditor();
    },

    resetEditor() {
        this.currentEditingId = null;
        document.getElementById('edit-title').value = '';
        document.getElementById('edit-code').value = '';
        document.getElementById('btn-delete').style.display = 'none';
    },

    filterCategory(cat) {
        this.currentFilter = cat;
        this.renderList();
    }
};

app.init();
