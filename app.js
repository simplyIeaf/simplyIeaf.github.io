document.addEventListener('DOMContentLoaded', () => {
    let state = {
        token: localStorage.getItem('gh_token'),
        scripts: [],
        filter: 'all',
        sort: 'newest',
        editingId: null,
        currentUser: null
    };

    const ui = {
        views: {
            home: document.getElementById('view-home'),
            detail: document.getElementById('view-detail'),
            admin: document.getElementById('view-admin')
        },
        lists: {
            public: document.getElementById('script-list'),
            admin: document.getElementById('admin-list')
        },
        inputs: {
            search: document.getElementById('search'),
            title: document.getElementById('edit-title'),
            desc: document.getElementById('edit-desc'),
            code: document.getElementById('edit-code'),
            public: document.getElementById('edit-visibility'),
            token: document.getElementById('auth-token')
        },
        detail: {
            title: document.getElementById('detail-title'),
            desc: document.getElementById('detail-desc'),
            code: document.getElementById('detail-code'),
            badges: document.getElementById('detail-badges'),
            btnCopy: document.getElementById('btn-copy'),
            btnRaw: document.getElementById('btn-raw'),
            btnDownload: document.getElementById('btn-download')
        }
    };

    const api = {
        headers() {
            return state.token ? { 
                'Authorization': `token ${state.token}`,
                'Accept': 'application/vnd.github.v3+json'
            } : {
                'Accept': 'application/vnd.github.v3+json'
            };
        },
        
        async getScripts() {
            const url = state.token ? 'https://api.github.com/gists' : 'https://api.github.com/gists/public';
            const res = await fetch(url, { headers: this.headers() });
            if (!res.ok) throw new Error('Failed to fetch scripts');
            const data = await res.json();
            return data.filter(g => g.files && Object.keys(g.files).some(k => k.endsWith('.lua')));
        },

        async getRaw(url) {
            const res = await fetch(url);
            return await res.text();
        },

        async createScript(data) {
            const body = {
                description: `${data.title} | ${data.desc}`,
                public: data.public === 'true',
                files: { 'script.lua': { content: data.code } }
            };
            const res = await fetch('https://api.github.com/gists', {
                method: 'POST',
                headers: { ...this.headers(), 'Content-Type': 'application/json' },
                body: JSON.stringify(body)
            });
            if (!res.ok) throw new Error('Create failed');
            return await res.json();
        },

        async updateScript(id, data) {
            const body = {
                description: `${data.title} | ${data.desc}`,
                files: { 'script.lua': { content: data.code } }
            };
            const res = await fetch(`https://api.github.com/gists/${id}`, {
                method: 'PATCH',
                headers: { ...this.headers(), 'Content-Type': 'application/json' },
                body: JSON.stringify(body)
            });
            if (!res.ok) throw new Error('Update failed');
            return await res.json();
        },

        async deleteScript(id) {
            const res = await fetch(`https://api.github.com/gists/${id}`, {
                method: 'DELETE',
                headers: this.headers()
            });
            if (!res.ok) throw new Error('Delete failed');
            return true;
        }
    };

    function init() {
        if (state.token) {
            document.getElementById('auth-section').style.display = 'none';
            document.getElementById('user-section').style.display = 'block';
            document.getElementById('private-filter').style.display = 'flex';
        }
        loadScripts();
    }

    async function loadScripts() {
        try {
            state.scripts = await api.getScripts();
            renderHome();
            if (state.token) renderAdminList();
        } catch (err) {
            notify("Error loading scripts", "error");
        }
    }

    function renderHome() {
        const list = ui.lists.public;
        list.innerHTML = '';
        
        let filtered = state.scripts.filter(s => {
            const desc = s.description || "Untitled";
            return desc.toLowerCase().includes(ui.inputs.search.value.toLowerCase());
        });

        if (state.filter === 'public') filtered = filtered.filter(s => s.public);
        if (state.filter === 'private') filtered = filtered.filter(s => !s.public);

        if (state.sort === 'alpha') {
            filtered.sort((a,b) => (a.description||'').localeCompare(b.description||''));
        }

        if (filtered.length === 0) {
            list.innerHTML = `<div style="grid-column:1/-1;text-align:center;padding:40px;color:#666;">No scripts found.</div>`;
            return;
        }

        filtered.forEach(script => {
            const parts = (script.description || "Untitled").split('|');
            const title = parts[0].trim();
            const badgeType = script.public ? 'badge-public' : 'badge-private';
            const badgeText = script.public ? 'Public' : 'Private';
            const icon = script.public 
                ? '<circle cx="12" cy="12" r="10"></circle>' 
                : '<rect x="3" y="11" width="18" height="11" rx="2" ry="2"></rect><path d="M7 11V7a5 5 0 0 1 10 0v4"></path>';

            const card = document.createElement('div');
            card.className = 'script-card animate__animated animate__fadeIn';
            card.onclick = () => openDetail(script.id);
            card.innerHTML = `
                <div class="script-title">${title}</div>
                <div class="card-meta">
                    <span class="badge ${badgeType}">
                        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">${icon}</svg>
                        ${badgeText}
                    </span>
                    <span>${new Date(script.updated_at).toLocaleDateString()}</span>
                </div>
            `;
            list.appendChild(card);
        });
    }

    async function openDetail(id) {
        const script = state.scripts.find(s => s.id === id);
        if (!script) return;

        const file = Object.values(script.files)[0];
        const parts = (script.description || "Untitled").split('|');
        
        ui.detail.title.textContent = parts[0].trim();
        ui.detail.desc.textContent = parts[1] ? parts[1].trim() : "No description available.";
        ui.detail.code.textContent = "Loading source code...";
        
        const badgeClass = script.public ? 'badge-public' : 'badge-private';
        const badgeLabel = script.public ? 'Public' : 'Private';
        const badgeIcon = script.public 
            ? '<circle cx="12" cy="12" r="10"></circle>' 
            : '<rect x="3" y="11" width="18" height="11" rx="2" ry="2"></rect><path d="M7 11V7a5 5 0 0 1 10 0v4"></path>';
            
        ui.detail.badges.innerHTML = `
            <span class="badge ${badgeClass}">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">${badgeIcon}</svg>
                ${badgeLabel}
            </span>
        `;

        switchView('detail');

        try {
            const code = await api.getRaw(file.raw_url);
            ui.detail.code.textContent = code;
            Prism.highlightElement(ui.detail.code);

            const blob = new Blob([code], { type: 'text/plain' });
            const url = window.URL.createObjectURL(blob);
            ui.detail.btnDownload.href = url;
            ui.detail.btnRaw.onclick = () => window.open(url, '_blank');
            ui.detail.btnCopy.onclick = () => {
                navigator.clipboard.writeText(code);
                notify("Copied to clipboard!", "success");
            };
        } catch (e) {
            ui.detail.code.textContent = "Error loading source code.";
        }
    }

    function renderAdminList() {
        const list = ui.lists.admin;
        list.innerHTML = '';
        state.scripts.forEach(script => {
            const title = (script.description || "Untitled").split('|')[0].trim();
            const item = document.createElement('div');
            item.className = 'admin-item';
            item.onclick = () => loadEditor(script.id);
            item.innerHTML = `
                <div style="font-weight:600">${title}</div>
                <div style="font-size:12px;color:#666">${script.public ? 'Public' : 'Private'}</div>
            `;
            list.appendChild(item);
        });
    }

    async function loadEditor(id) {
        state.editingId = id; 
        const script = state.scripts.find(s => s.id === id);
        const file = Object.values(script.files)[0];
        const parts = (script.description || "").split('|');

        ui.inputs.title.value = parts[0].trim();
        ui.inputs.desc.value = parts[1] ? parts[1].trim() : "";
        ui.inputs.public.value = script.public.toString();
        ui.inputs.code.value = "Loading...";

        document.getElementById('editor-heading').textContent = "Edit Script";
        document.getElementById('btn-delete').style.display = 'flex';
        
        switchAdminTab('editor');

        const code = await api.getRaw(file.raw_url);
        ui.inputs.code.value = code;
    }

    function resetEditor() {
        state.editingId = null;
        ui.inputs.title.value = "";
        ui.inputs.desc.value = "";
        ui.inputs.code.value = "";
        ui.inputs.public.value = "true";
        document.getElementById('editor-heading').textContent = "Create New Script";
        document.getElementById('btn-delete').style.display = 'none';
    }

    function switchView(viewName) {
        Object.values(ui.views).forEach(el => el.style.display = 'none');
        ui.views[viewName].style.display = 'block';
        window.scrollTo(0,0);
    }

    function switchAdminTab(tabName) {
        const list = document.getElementById('admin-view-list');
        const editor = document.getElementById('admin-view-editor');
        
        if (tabName === 'list') {
            list.style.display = 'block';
            editor.style.display = 'none';
        } else {
            list.style.display = 'none';
            editor.style.display = 'block';
        }
    }

    function notify(msg, type = 'success') {
        Toastify({
            text: msg,
            duration: 3000,
            gravity: "bottom",
            position: "right",
            style: {
                background: type === 'error' ? '#ef4444' : '#10b981',
                color: '#fff',
                borderRadius: '8px',
                fontWeight: '600'
            }
        }).showToast();
    }

    document.addEventListener('click', async (e) => {
        const target = e.target.closest('[data-action]');
        if (!target) return;
        
        const action = target.dataset.action;
        const param = target.dataset.param;

        if (action === 'navigate') {
            if (param === 'admin') {
                if (!state.token) return notify("Please login first", "error");
                switchView('admin');
                renderAdminList();
            } else {
                switchView('home');
                loadScripts();
            }
        }
        else if (action === 'login-modal') {
            document.getElementById('login-modal').style.display = 'flex';
        }
        else if (action === 'close-modal') {
            document.getElementById('login-modal').style.display = 'none';
        }
        else if (action === 'login') {
            const token = ui.inputs.token.value.trim();
            if (!token.startsWith('ghp_')) return notify("Invalid Token Format", "error");
            localStorage.setItem('gh_token', token);
            location.reload();
        }
        else if (action === 'logout') {
            localStorage.removeItem('gh_token');
            location.reload();
        }
        else if (action === 'filter') {
            document.querySelectorAll('.sidebar-link').forEach(l => l.classList.remove('active'));
            target.classList.add('active');
            state.filter = param;
            renderHome();
        }
        else if (action === 'admin-switch') {
            if (param === 'create') resetEditor();
            switchAdminTab(param === 'create' ? 'editor' : 'list');
        }
        else if (action === 'save-script') {
            const data = {
                title: ui.inputs.title.value,
                desc: ui.inputs.desc.value,
                code: ui.inputs.code.value,
                public: ui.inputs.public.value
            };
            
            if (!data.title || !data.code) return notify("Title and Code required", "error");

            try {
                if (state.editingId) {
                    await api.updateScript(state.editingId, data);
                    notify("Script updated!");
                } else {
                    await api.createScript(data);
                    notify("Script created!");
                }
                loadScripts();
                switchAdminTab('list');
            } catch (err) {
                notify("Failed to save script", "error");
            }
        }
    });

    document.getElementById('btn-delete').onclick = async () => {
        if (!state.editingId) return notify("Error: No script is currently being edited.", "error");
        
        if (confirm("Are you sure you want to delete this script?")) {
            try {
                await api.deleteScript(state.editingId);
                notify("Script deleted successfully");
                state.editingId = null;
                await loadScripts();
                switchAdminTab('list');
            } catch (err) {
                notify("Failed to delete script", "error");
            }
        }
    };

    ui.inputs.search.addEventListener('input', renderHome);
    document.getElementById('sort-select').addEventListener('change', (e) => {
        state.sort = e.target.value;
        renderHome();
    });

    init();
});
