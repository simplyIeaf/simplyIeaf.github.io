const CONFIG = {
    user: 'simplyIeaf',
    repo: 'simplyIeaf.github.io'
};

const app = {
    db: { scripts: {} },
    token: localStorage.getItem('gh_token'),
    
    notify(msg, color = "#3b82f6") {
        Toastify({ text: msg, style: { background: color }, duration: 2000 }).showToast();
    },

    async init() {
        if (this.token) {
            document.getElementById('auth-section').style.display = 'none';
            document.getElementById('user-section').style.display = 'block';
        }
        await this.loadDB();
        this.renderList();
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
        } catch (e) { this.notify("Failed to load index", "#ef4444"); }
    },

    async save() {
        const title = document.getElementById('edit-title').value;
        const code = document.getElementById('edit-code').value;
        const slug = title.toLowerCase().replace(/ /g, '-');

        if (!this.token) return;

        this.notify("Publishing files...");
        
        const scriptHTML = this.getTemplate(title, slug);
        
        try {
            // 1. Save Raw Lua
            await this.gitPut(`scripts/${slug}/raw/script.lua`, code, `Update raw lua for ${title}`);
            // 2. Save Index HTML
            await this.gitPut(`scripts/${slug}/index.html`, scriptHTML, `Update page for ${title}`);
            
            // 3. Update Database Index
            this.db.scripts[slug] = { title, slug, date: new Date().toISOString() };
            await this.gitPut(`database.json`, JSON.stringify(this.db, null, 2), `Update index`, this.dbSha);
            
            this.notify("Published successfully!", "#10b981");
            location.hash = 'admin';
            this.loadDB();
        } catch (e) { this.notify("GitHub API Error", "#ef4444"); }
    },

    async deleteFlow() {
        const slug = this.currentEditingId;
        if (!confirm("Delete all files for this script?")) return;

        this.notify("Deleting index entry...");
        delete this.db.scripts[slug];
        await this.gitPut(`database.json`, JSON.stringify(this.db, null, 2), `Deleted ${slug}`, this.dbSha);
        
        this.notify("Files remain in repo but removed from index.", "#10b981");
        location.hash = 'admin';
        this.loadDB();
    },

    async gitPut(path, content, msg, sha = null) {
        return fetch(`https://api.github.com/repos/${CONFIG.user}/${CONFIG.repo}/contents/${path}`, {
            method: 'PUT',
            headers: { 'Authorization': `token ${this.token}`, 'Content-Type': 'application/json' },
            body: JSON.stringify({ message: msg, content: btoa(content), sha: sha })
        });
    },

    getTemplate(title, slug) {
        return `<!DOCTYPE html><html><head><title>${title}</title><link rel="stylesheet" href="../../style.css"></head>
        <body>
            <nav class="navbar"><div class="brand" onclick="location.href='../../index.html'"><span>Leaf's Scripts</span></div></nav>
            <div class="container">
                <h1>${title}</h1>
                <div class="code-container">
                    <div class="code-header">
                        <span>script.lua</span>
                        <div class="btns">
                            <button class="btn-green" onclick="copy()">Copy</button>
                            <a href="raw/script.lua" class="btn-primary">Raw</a>
                            <button class="btn-primary" onclick="dl()">Download</button>
                        </div>
                    </div>
                    <pre id="c"></pre>
                </div>
            </div>
            <script>
                async function load(){
                    const r = await fetch('raw/script.lua');
                    const txt = await r.text();
                    document.getElementById('c').innerText = txt;
                }
                function copy(){
                    navigator.clipboard.writeText(document.getElementById('c').innerText);
                    alert('Copied!');
                }
                function dl(){
                    const blob = new Blob([document.getElementById('c').innerText], {type:'text/plain'});
                    const a = document.createElement('a');
                    a.href = URL.createObjectURL(blob);
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
        container.innerHTML = '';
        adminContainer.innerHTML = '';

        Object.values(this.db.scripts).forEach(s => {
            const card = `<div class="script-card" onclick="location.href='scripts/${s.slug}/index.html'">
                <h3>${s.title}</h3>
                <small>${new Date(s.date).toLocaleDateString()}</small>
            </div>`;
            container.innerHTML += card;

            const adminCard = `<div class="script-card" onclick="app.edit('${s.slug}')">
                <h3>${s.title} (Edit)</h3>
            </div>`;
            adminContainer.innerHTML += adminCard;
        });
    },

    handleRouting() {
        const hash = location.hash;
        document.querySelectorAll('.view-section').forEach(v => v.style.display = 'none');
        if (hash === '#admin' && this.token) document.getElementById('view-admin').style.display = 'block';
        else if (hash === '#editor' && this.token) document.getElementById('view-editor').style.display = 'block';
        else document.getElementById('view-home').style.display = 'block';
    },

    login() {
        const t = document.getElementById('token-input').value;
        this.token = t;
        localStorage.setItem('gh_token', t);
        location.reload();
    },

    logout() {
        localStorage.removeItem('gh_token');
        location.href = '';
    },

    showLogin() { document.getElementById('login-modal').style.display = 'flex'; },
    closeLogin() { document.getElementById('login-modal').style.display = 'none'; },
    showEditor() { this.currentEditingId = null; location.hash = 'editor'; document.getElementById('del-btn').style.display = 'none'; },
    edit(slug) { 
        this.currentEditingId = slug; 
        location.hash = 'editor'; 
        document.getElementById('edit-title').value = this.db.scripts[slug].title;
        document.getElementById('del-btn').style.display = 'block';
    },
    debouncedRender: function() { app.renderList(); }
};

app.init();
