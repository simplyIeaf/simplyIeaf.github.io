document.addEventListener('DOMContentLoaded', () => {
    let state = {
        token: localStorage.getItem('gh_token'),
        scripts: [],
        filter: 'all',
        sort: 'newest',
        editingId: null
    };

    const ui = {
        views: document.querySelectorAll('.view-section'),
        scriptList: document.getElementById('script-list'),
        adminList: document.getElementById('admin-list'),
        detailCode: document.getElementById('detail-code'),
        inputs: {
            title: document.getElementById('edit-title'),
            desc: document.getElementById('edit-desc'),
            code: document.getElementById('edit-code'),
            public: document.getElementById('edit-visibility'),
            search: document.getElementById('search')
        }
    };

    const api = {
        headers: () => state.token ? { 'Authorization': `token ${state.token}` } : {},
        
        async fetchScripts() {
            const endpoint = state.token ? 'https://api.github.com/gists' : 'https://api.github.com/gists/public';
            try {
                const res = await fetch(endpoint, { headers: this.headers() });
                const data = await res.json();
                state.scripts = data.filter(g => g.files && Object.keys(g.files).some(k => k.endsWith('.lua')));
                renderScripts();
                renderAdminList();
            } catch (e) {
                notify("Failed to load scripts", "error");
            }
        },

        async saveScript(data) {
            const method = state.editingId ? 'PATCH' : 'POST';
            const url = state.editingId 
                ? `https://api.github.com/gists/${state.editingId}` 
                : 'https://api.github.com/gists';
            
            const body = {
                description: `${data.title} | ${data.desc}`,
                public: data.public === 'true',
                files: {
                    'script.lua': { content: data.code }
                }
            };

            const res = await fetch(url, {
                method: method,
                headers: { ...this.headers(), 'Content-Type': 'application/json' },
                body: JSON.stringify(body)
            });

            if (!res.ok) throw new Error();
            const json = await res.json();
            state.editingId = json.id; 
            return json;
        },

        async deleteScript(id) {
            const res = await fetch(`https://api.github.com/gists/${id}`, {
                method: 'DELETE',
                headers: this.headers()
            });
            if (!res.ok) throw new Error();
        }
    };

    function init() {
        if (state.token) {
            document.getElementById('auth-section').style.display = 'none';
            document.getElementById('user-section').style.display = 'block';
            document.getElementById('private-filter').style.display = 'flex';
        }
        api.fetchScripts();
    }

    document.addEventListener('click', async (e) => {
        const target = e.target.closest('[data-action]');
        if (!target) return;
        const action = target.dataset.action;
        const param = target.dataset.param;

        if (action === 'navigate') {
            switchView(param === 'admin' ? 'view-admin' : 'view-home');
            if (!param) api.fetchScripts();
        }
        else if (action === 'login-modal') {
            document.getElementById('login-modal').style.display = 'flex';
        }
        else if (action === 'login') {
            const token = document.getElementById('auth-token').value;
            if (token.startsWith('ghp_')) {
                localStorage.setItem('gh_token', token);
                location.reload();
            } else {
                notify("Invalid Token Format", "error");
            }
        }
        else if (action === 'logout') {
            localStorage.removeItem('gh_token');
            location.reload();
        }
        else if (action === 'open-script') {
            openDetail(param);
        }
        else if (action === 'filter') {
            document.querySelectorAll('.sidebar-link').forEach(l => l.classList.remove('active'));
            target.classList.add('active');
            state.filter = param;
            renderScripts();
        }
        else if (action === 'admin-tab') {
            document.querySelectorAll('.tab-btn').forEach(b => b.classList.remove('active'));
            target.classList.add('active');
            document.querySelectorAll('.admin-tab').forEach(t => t.style.display = 'none');
            document.getElementById(`admin-tab-${param}`).style.display = 'block';
            if (param === 'create') clearEditor();
        }
        else if (action === 'edit-script') {
            loadEditor(param);
        }
        else if (action === 'save-script') {
            try {
                if(!ui.inputs.title.value || !ui.inputs.code.value) return notify("Title and Code required", "error");
                
                await api.saveScript({
                    title: ui.inputs.title.value,
                    desc: ui.inputs.desc.value,
                    code: ui.inputs.code.value,
                    public: ui.inputs.public.value
                });
                notify("Script saved successfully", "success");
                document.getElementById('btn-delete').style.display = 'inline-flex'; 
                api.fetchScripts();
            } catch (err) {
                notify("Error saving script", "error");
            }
        }
        else if (target.id === 'btn-delete') {
            if (!state.editingId) return notify("No script to delete", "error");
            if (confirm('Delete this script?')) {
                try {
                    await api.deleteScript(state.editingId);
                    notify("Script deleted", "success");
                    document.querySelector('[data-param="list"]').click();
                    api.fetchScripts();
                } catch(e) {
                    notify("Error deleting script", "error");
                }
            }
        }
    });

    document.querySelector('.close-btn').onclick = () => {
        document.getElementById('login-modal').style.display = 'none';
    };

    ui.inputs.search.addEventListener('input', (e) => {
        renderScripts(e.target.value.toLowerCase());
    });

    document.getElementById('sort-select').addEventListener('change', (e) => {
        state.sort = e.target.value;
        renderScripts();
    });

    document.getElementById('btn-copy').onclick = () => {
        navigator.clipboard.writeText(ui.detailCode.textContent);
        notify("Copied to clipboard", "success");
    };

    function switchView(id) {
        ui.views.forEach(v => {
            v.style.display = 'none';
            v.classList.remove('active');
        });
        const active = document.getElementById(id);
        active.style.display = 'block';
        active.classList.add('active');
        window.scrollTo(0,0);
    }

    function renderScripts(search = '') {
        ui.scriptList.innerHTML = '';
        let filtered = state.scripts.filter(s => {
            const rawDesc = s.description || "Untitled";
            const parts = rawDesc.split('|');
            const title = parts[0].trim().toLowerCase();
            return title.includes(search);
        });

        if (state.filter === 'public') filtered = filtered.filter(s => s.public);
        if (state.filter === 'private') filtered = filtered.filter(s => !s.public);

        if (state.sort === 'alpha') {
            filtered.sort((a,b) => (a.description||'').localeCompare(b.description||''));
        }

        if(filtered.length === 0) {
            ui.scriptList.innerHTML = '<div style="text-align:center;color:#888;grid-column:1/-1;padding:40px;">No scripts found.</div>';
            return;
        }

        filtered.forEach(script => {
            const descParts = (script.description || "Untitled").split('|');
            const title = descParts[0].trim();
            const badge = script.public 
                ? `<span class="badge badge-public"><svg width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3"><circle cx="12" cy="12" r="10"></circle></svg> Public</span>` 
                : `<span class="badge badge-private"><svg width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3"><rect x="3" y="11" width="18" height="11" rx="2" ry="2"></rect><path d="M7 11V7a5 5 0 0 1 10 0v4"></path></svg> Private</span>`;

            const card = document.createElement('div');
            card.className = 'script-card animate__animated animate__fadeIn';
            card.setAttribute('data-action', 'open-script');
            card.setAttribute('data-param', script.id);
            card.innerHTML = `
                <div class="script-title">${title}</div>
                <div class="card-meta">
                    ${badge}
                    <span>${new Date(script.updated_at).toLocaleDateString()}</span>
                </div>
            `;
            ui.scriptList.appendChild(card);
        });
    }

    function renderAdminList() {
        ui.adminList.innerHTML = '';
        state.scripts.forEach(script => {
            const title = (script.description || "Untitled").split('|')[0].trim();
            const div = document.createElement('div');
            div.className = 'admin-item';
            div.setAttribute('data-action', 'edit-script');
            div.setAttribute('data-param', script.id);
            div.innerHTML = `
                <strong>${title}</strong>
                <span class="text-muted">${script.public ? 'Public' : 'Private'}</span>
            `;
            ui.adminList.appendChild(div);
        });
    }

    async function openDetail(id) {
        const script = state.scripts.find(s => s.id === id);
        if (!script) return;

        const fileKey = Object.keys(script.files).find(k => k.endsWith('.lua')) || Object.keys(script.files)[0];
        const file = script.files[fileKey];
        const descParts = (script.description || "Untitled").split('|');

        document.getElementById('detail-title').innerText = descParts[0].trim();
        document.getElementById('detail-desc').innerText = descParts[1] ? descParts[1].trim() : "No description provided.";
        
        const badgeContainer = document.getElementById('detail-badges');
        badgeContainer.innerHTML = script.public 
            ? `<span class="badge badge-public"><svg width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3"><circle cx="12" cy="12" r="10"></circle></svg> Public</span>`
            : `<span class="badge badge-private"><svg width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3"><rect x="3" y="11" width="18" height="11" rx="2" ry="2"></rect><path d="M7 11V7a5 5 0 0 1 10 0v4"></path></svg> Private</span>`;

        ui.detailCode.textContent = "Loading...";
        switchView('view-detail');

        try {
            const res = await fetch(file.raw_url);
            const code = await res.text();
            ui.detailCode.textContent = code;
            Prism.highlightElement(ui.detailCode);

            const blob = new Blob([code], { type: 'text/plain' });
            const url = window.URL.createObjectURL(blob);
            
            document.getElementById('btn-download').href = url;
            document.getElementById('btn-raw').onclick = () => window.open(url, '_blank');
        } catch (e) {
            ui.detailCode.textContent = "-- Error loading code";
        }
    }

    function clearEditor() {
        state.editingId = null;
        ui.inputs.title.value = '';
        ui.inputs.desc.value = '';
        ui.inputs.code.value = '';
        document.getElementById('editor-heading').innerText = "Create New Script";
        document.getElementById('btn-delete').style.display = 'none';
        document.querySelector('[data-action="admin-tab"][data-param="create"]').click();
    }

    async function loadEditor(id) {
        state.editingId = id;
        const script = state.scripts.find(s => s.id === id);
        const file = Object.values(script.files)[0];
        const parts = (script.description || "").split('|');
        
        ui.inputs.title.value = parts[0].trim();
        ui.inputs.desc.value = parts[1] ? parts[1].trim() : "";
        ui.inputs.public.value = script.public.toString();
        
        const res = await fetch(file.raw_url);
        ui.inputs.code.value = await res.text();
        
        document.getElementById('editor-heading').innerText = "Edit Script";
        document.getElementById('btn-delete').style.display = 'inline-flex';
        document.querySelector('[data-action="admin-tab"][data-param="create"]').click();
    }

    function notify(msg, type) {
        Toastify({
            text: msg,
            duration: 3000,
            gravity: "bottom",
            position: "right",
            backgroundColor: type === "error" ? "#ef4444" : "#10b981",
        }).showToast();
    }

    init();
});
