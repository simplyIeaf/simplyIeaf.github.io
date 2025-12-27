const CONFIG = {
    user: 'simplyIeaf',
    repo: 'simplyIeaf.github.io'
};

const app = {
    db: { scripts: {} },
    dbSha: null,
    token: localStorage.getItem('gh_token'),
    actionInProgress: false,
    currentEditingId: null,

    notify(msg, color = "#3b82f6") {
        Toastify({ 
            text: msg, 
            style: { background: color, borderRadius: "8px", fontWeight: "800" }, 
            duration: 2500 
        }).showToast();
    },

    async init() {
        if (this.token) {
            document.getElementById('auth-section').style.display = 'none';
            document.getElementById('user-section').style.display = 'block';
        }
        await this.loadDB();
        this.handleRouting();
        window.onhashchange = () => this.handleRouting();
    },

    async loadDB() {
        try {
            const res = await fetch(`https://api.github.com/repos/${CONFIG.user}/${CONFIG.repo}/contents/database.json?t=${Date.now()}`);
            if (res.ok) {
                const data = await res.json();
                this.db = JSON.parse(atob(data.content));
                this.dbSha = data.sha;
            }
            this.renderList();
        } catch (e) { this.notify("Index Sync Error", "#ef4444"); }
    },

    async save() {
        if (this.actionInProgress) return;
        const title = document.getElementById('edit-title').value.trim();
        const code = document.getElementById('edit-code').value;
        if (!title || !code) return this.notify("Missing Title or Code", "#ef4444");

        this.actionInProgress = true;
        const slug = title.toLowerCase().replace(/[^a-z0-9]+/g, '-');

        try {
            await this.loadDB(); 
            
            await this.gitPut(`scripts/${slug}/raw/script.lua`, code, `Update source: ${title}`);
            const template = this.getTemplate(title, slug);
            await this.gitPut(`scripts/${slug}/index.html`, template, `Update page: ${title}`);
            
            this.db.scripts[slug] = { title, slug, date: new Date().toISOString() };
            await this.gitPut(`database.json`, JSON.stringify(this.db, null, 2), `Index update: ${title}`, this.dbSha);
            
            this.notify("Deployed Successfully", "#10b981");
            location.hash = 'admin';
        } catch (e) {
            this.notify("Push Failed: Check Token Permissions", "#ef4444");
        } finally {
            this.actionInProgress = false;
        }
    },

    async deleteFlow() {
        if (!this.currentEditingId || this.actionInProgress) return;
        if (!confirm("Remove from public index? Files will be archived.")) return;

        this.actionInProgress = true;
        const slug = this.currentEditingId;

        try {
            await this.loadDB();
            delete this.db.scripts[slug];
            
            await this.gitPut(`database.json`, JSON.stringify(this.db, null, 2), `Remove ${slug}`, this.dbSha);
            
            this.notify("Deleted from Index", "#10b981");
            location.hash = 'admin';
            await this.loadDB();
        } catch (e) {
            this.notify("Delete Failed", "#ef4444");
        } finally {
            this.actionInProgress = false;
        }
    },

    async gitPut(path, content, msg, sha = null) {
        const body = { message: msg, content: btoa(unescape(encodeURIComponent(content))) };
        if (sha) body.sha = sha;

        const res = await fetch(`https://api.github.com/repos/${CONFIG.user}/${CONFIG.repo}/contents/${path}`, {
            method: 'PUT',
            headers: { 'Authorization': `token ${this.token}`, 'Content-Type': 'application/json' },
            body: JSON.stringify(body)
        });
        if (!res.ok) throw new Error("Git Error");
        return res.json();
    },

    getTemplate(title, slug) {
        return `<!DOCTYPE html><html lang="en"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0"><title>${title}</title><link rel="stylesheet" href="../../style.css"><link href="https://fonts.googleapis.com/css2?family=Inter:wght@600;800&display=swap" rel="stylesheet"></head>
        <body class="script-view">
            <nav class="navbar"><div class="nav-content"><div class="brand" onclick="location.href='../../index.html'"><span>Leaf's Scripts</span></div></div></nav>
            <div class="container">
                <div class="script-header"><h1>${title}</h1></div>
                <div class="code-container">
                    <div class="code-header">
                        <span class="fname">script.lua</span>
                        <div class="actions">
                            <button class="btn-green" onclick="copyCode()">Copy</button>
                            <a href="raw/script.lua" class="btn-primary">Raw</a>
                            <button class="btn-primary" onclick="downloadCode()">Download</button>
                        </div>
                    </div>
                    <pre id="code-output">Loading source...</pre>
                </div>
            </div>
            <script>
                async function load(){
                    const r = await fetch('raw/script.lua');
                    const t = await r.text();
                    document.getElementById('code-output').innerText = t;
                }
                function copyCode(){
                    navigator.clipboard.writeText(document.getElementById('code-output').innerText);
                    alert('Copied to clipboard!');
                }
                function downloadCode(){
                    const b = new Blob([document.getElementById('code-output').innerText], {type:'text/plain'});
                    const a = document.createElement('a');
                    a.href = URL.createObjectURL(b);
                    a.download = 'script.lua';
                    a.click();
                }
                load();
            </script>
        </body></html>`;
    },

    renderList() {
        const container = document.getElementById('script-list');
        const adminContainer = document.getElementById('admin-list');
        const query = document.getElementById('search').value.toLowerCase();
        
        container.innerHTML = '';
        adminContainer.innerHTML = '';

        Object.values(this.db.scripts).forEach(s => {
            if (s.title.toLowerCase().includes(query)) {
                const card = `<div class="script-card" onclick="location.href='scripts/${s.slug}/index.html'">
                    <h3>${s.title}</h3>
                    <div class="card-footer"><span>${new Date(s.date).toLocaleDateString()}</span></div>
                </div>`;
                container.innerHTML += card;

                const adminCard = `<div class="script-card" onclick="app.edit('${s.slug}')">
                    <h3>${s.title}</h3>
                    <div class="card-footer"><span style="color:var(--primary)">Click to Edit</span></div>
                </div>`;
                adminContainer.innerHTML += adminCard;
            }
        });
    },

    handleRouting() {
        const h = location.hash;
        document.querySelectorAll('.view-section').forEach(v => v.style.display = 'none');
        if (h === '#admin' && this.token) {
            document.getElementById('view-admin').style.display = 'block';
            this.renderList();
        } else if (h === '#editor' && this.token) {
            document.getElementById('view-editor').style.display = 'block';
        } else {
            document.getElementById('view-home').style.display = 'block';
            this.renderList();
        }
    },

    edit(slug) {
        this.currentEditingId = slug;
        const s = this.db.scripts[slug];
        document.getElementById('edit-title').value = s.title;
        document.getElementById('del-btn').style.display = 'block';
        location.hash = 'editor';
    },

    login() {
        const t = document.getElementById('token-input').value;
        if (t) {
            localStorage.setItem('gh_token', t);
            location.reload();
        }
    },

    logout() {
        localStorage.removeItem('gh_token');
        location.hash = '';
        location.reload();
    },

    showLogin() { document.getElementById('login-modal').style.display = 'flex'; },
    closeLogin() { document.getElementById('login-modal').style.display = 'none'; },
    showEditor() {
        this.currentEditingId = null;
        document.getElementById('edit-title').value = '';
        document.getElementById('edit-code').value = '';
        document.getElementById('del-btn').style.display = 'none';
        location.hash = 'editor';
    },
    debouncedRender() { this.renderList(); }
};

app.init();
