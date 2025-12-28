(function() {
    let GH_TOKEN = localStorage.getItem('ls_auth_token') || null;
    let scriptsCache = [];
    let currentCategory = 'all';
    let currentSort = 'newest';
    let monacoEditor = null;
    let quillEditor = null;
    let isEditing = false;
    let currentEditingId = null;

    const dom = {
        loginModal: document.getElementById('login-modal'),
        authToken: document.getElementById('auth-token'),
        loginError: document.getElementById('login-error'),
        viewHome: document.getElementById('view-home'),
        viewAdmin: document.getElementById('view-admin'),
        userSection: document.getElementById('user-section'),
        authSection: document.getElementById('auth-section'),
        scriptList: document.getElementById('script-list'),
        adminList: document.getElementById('admin-list'),
        adminTabList: document.getElementById('admin-tab-list'),
        adminTabEditor: document.getElementById('admin-tab-editor'),
        adminTabStats: document.getElementById('admin-tab-stats'),
        searchInput: document.getElementById('search'),
        editorHeading: document.getElementById('editor-heading'),
        
        editTitle: document.getElementById('edit-title'),
        editVisibility: document.getElementById('edit-visibility'),
        editExpire: document.getElementById('edit-expire'),
        
        filterLinks: document.querySelectorAll('.sidebar-link'),
        tabBtns: document.querySelectorAll('.tab-btn')
    };

    require.config({ paths: { 'vs': 'https://cdnjs.cloudflare.com/ajax/libs/monaco-editor/0.44.0/min/vs' }});
    require(['vs/editor/editor.main'], function() {
        monacoEditor = monaco.editor.create(document.getElementById('monaco-container'), {
            value: '-- Lua Script\nprint("Hello World")',
            language: 'lua',
            theme: 'vs-dark',
            automaticLayout: true,
            minimap: { enabled: false },
            fontSize: 14,
            scrollBeyondLastLine: false,
            padding: { top: 16, bottom: 16 }
        });
    });

    quillEditor = new Quill('#quill-container', {
        theme: 'snow',
        modules: {
            toolbar: [['bold', 'italic', 'underline'], [{ 'list': 'ordered'}, { 'list': 'bullet' }], ['clean']]
        },
        placeholder: 'Script description...'
    });

    function init() {
        if(GH_TOKEN) {
            verifyToken(GH_TOKEN).then(valid => {
                if(valid) {
                    dom.authSection.style.display = 'none';
                    dom.userSection.style.display = 'block';
                    document.getElementById('private-filter').style.display = 'flex';
                    document.getElementById('unlisted-filter').style.display = 'flex';
                } else {
                    logout();
                }
                loadScripts();
            });
        } else {
            loadScripts();
        }

        dom.searchInput.addEventListener('input', (e) => {
            renderScripts(e.target.value);
        });
    }

    async function verifyToken(token) {
        try {
            const res = await fetch('https://api.github.com/user', {
                headers: { Authorization: `token ${token}` }
            });
            return res.status === 200;
        } catch { return false; }
    }

    async function loadScripts() {
        NProgress.start();
        try {
            const headers = GH_TOKEN ? { Authorization: `token ${GH_TOKEN}` } : {};
            const res = await fetch('https://api.github.com/gists', { headers });
            const data = await res.json();
            
            scriptsCache = data.map(gist => {
                const file = Object.values(gist.files)[0];
                if (!file) return null;
                
                let content = {};
                try {
                    content = JSON.parse(gist.description);
                } catch {
                    content = { title: file.filename, desc: "No description", visibility: "PUBLIC" };
                }

                return {
                    id: gist.id,
                    title: content.title || file.filename,
                    desc: content.desc || "",
                    code: null, 
                    rawUrl: file.raw_url,
                    visibility: content.visibility || "PUBLIC",
                    expire: content.expire || "",
                    updated: new Date(gist.updated_at),
                    created: new Date(gist.created_at)
                };
            }).filter(s => s !== null);

            renderScripts();
            if(GH_TOKEN) renderAdminList();
            renderStats();
        } catch (error) {
            console.error(error);
            Toastify({ text: "Failed to load scripts", backgroundColor: "var(--color-danger)" }).showToast();
        }
        NProgress.done();
    }

    function renderScripts(query = "") {
        const grid = dom.scriptList;
        grid.innerHTML = '';

        let filtered = scriptsCache.filter(s => {
            const matchQuery = s.title.toLowerCase().includes(query.toLowerCase());
            const matchFilter = currentCategory === 'all' || s.visibility.toLowerCase() === currentCategory;
            const isPublicOrAuthed = s.visibility === 'PUBLIC' || GH_TOKEN;
            return matchQuery && matchFilter && isPublicOrAuthed;
        });

        filtered.sort((a, b) => {
            if(currentSort === 'newest') return b.created - a.created;
            if(currentSort === 'oldest') return a.created - b.created;
            if(currentSort === 'alpha') return a.title.localeCompare(b.title);
            if(currentSort === 'updated') return b.updated - a.updated;
        });

        if(filtered.length === 0) {
            grid.innerHTML = `<div style="text-align:center;padding:60px 0;grid-column:1/-1;color:var(--color-text-muted)">No scripts found.</div>`;
            return;
        }

        filtered.forEach(s => {
            const card = document.createElement('div');
            card.className = 'script-card animate__animated animate__fadeIn';
            card.onclick = () => viewScript(s);
            
            let badgeClass = 'badge-public';
            if(s.visibility === 'PRIVATE') badgeClass = 'badge-private';
            if(s.visibility === 'UNLISTED') badgeClass = 'badge-unlisted';

            card.innerHTML = `
                <div class="card-header-section">
                    <h3 class="script-title">${s.title}</h3>
                    ${GH_TOKEN ? `<span class="badge ${badgeClass} badge-sm">${s.visibility}</span>` : ''}
                </div>
                <div class="card-meta">
                    <span>${s.updated.toLocaleDateString()}</span>
                </div>
            `;
            grid.appendChild(card);
        });
    }

    async function viewScript(script) {
        try {
            NProgress.start();
            const res = await fetch(script.rawUrl);
            const code = await res.text();
            
            Swal.fire({
                title: script.title,
                html: `
                    <div style="text-align:left">
                        <div class="ql-editor" style="padding:0;margin-bottom:15px">${script.desc}</div>
                        <pre style="max-height:300px;overflow:auto;font-size:12px;border-radius:6px"><code>${code.replace(/</g, '&lt;')}</code></pre>
                    </div>
                `,
                width: 800,
                showCancelButton: true,
                confirmButtonText: 'Download',
                cancelButtonText: 'Close'
            }).then((result) => {
                if (result.isConfirmed) {
                    const blob = new Blob([code], { type: "text/plain;charset=utf-8" });
                    saveAs(blob, `${script.title}.lua`);
                }
            });
        } catch {
            Toastify({ text: "Failed to load code", backgroundColor: "var(--color-danger)" }).showToast();
        }
        NProgress.done();
    }

    function renderAdminList() {
        const list = dom.adminList;
        list.innerHTML = '';
        
        scriptsCache.forEach(s => {
            const item = document.createElement('div');
            item.className = 'admin-item';
            
            const content = document.createElement('div');
            content.className = 'admin-item-content';
            content.innerHTML = `
                <div class="admin-item-left">
                    <strong>${s.title}</strong>
                    <span class="text-muted" style="font-size:12px">${s.visibility} • ${s.updated.toLocaleDateString()}</span>
                </div>
                <div class="admin-item-right">
                    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                        <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"></path>
                        <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"></path>
                    </svg>
                </div>
            `;

            const bg = document.createElement('div');
            bg.className = 'swipe-bg';
            bg.innerHTML = '<span class="swipe-text">Delete</span>';

            item.appendChild(bg);
            item.appendChild(content);
            list.appendChild(item);

            setupSwipe(item, s.id);

            item.onclick = (e) => {
                if(!item.classList.contains('swiping')) {
                    editScript(s);
                }
            };
        });
        
        document.getElementById('total-stats').innerText = `${scriptsCache.length} Scripts`;
    }

    function setupSwipe(element, id) {
        let startX = 0;
        let currentX = 0;
        let isDragging = false;
        const threshold = 150;

        const start = (x) => {
            startX = x;
            isDragging = true;
            element.style.transition = 'none';
        };

        const move = (x) => {
            if (!isDragging) return;
            currentX = x - startX;
            if (currentX > 0) {
                element.style.transform = `translateX(${currentX}px)`;
                const opacity = Math.min(currentX / threshold, 1);
                element.querySelector('.swipe-bg').style.opacity = opacity;
            }
        };

        const end = () => {
            if (!isDragging) return;
            isDragging = false;
            element.style.transition = 'transform 0.3s ease';
            
            if (currentX > threshold) {
                element.style.transform = `translateX(100%)`;
                setTimeout(() => deleteScript(id), 300);
            } else {
                element.style.transform = 'translateX(0)';
                element.querySelector('.swipe-bg').style.opacity = 0;
            }
            currentX = 0;
        };

        element.addEventListener('mousedown', e => start(e.clientX));
        window.addEventListener('mousemove', e => move(e.clientX));
        window.addEventListener('mouseup', end);
        
        element.addEventListener('touchstart', e => start(e.touches[0].clientX), {passive: true});
        element.addEventListener('touchmove', e => move(e.touches[0].clientX), {passive: true});
        element.addEventListener('touchend', end);
    }

    async function editScript(script) {
        try {
            NProgress.start();
            isEditing = true;
            currentEditingId = script.id;
            
            dom.editTitle.value = script.title;
            dom.editVisibility.value = script.visibility;
            dom.editExpire.value = script.expire;
            
            quillEditor.root.innerHTML = script.desc;
            
            const res = await fetch(script.rawUrl);
            const code = await res.text();
            monacoEditor.setValue(code);
            
            switchAdminTab('create');
            dom.editorHeading.innerText = "Edit Script";
        } catch(e) {
            Toastify({ text: "Error loading script data", backgroundColor: "var(--color-danger)" }).showToast();
        }
        NProgress.done();
    }

    async function saveScript() {
        const title = dom.editTitle.value;
        const code = monacoEditor.getValue();
        const desc = quillEditor.root.innerHTML;
        const visibility = dom.editVisibility.value;
        const expire = dom.editExpire.value;

        if(!title || !code) {
            Toastify({ text: "Title and Code are required", backgroundColor: "var(--color-danger)" }).showToast();
            return;
        }

        NProgress.start();
        const meta = JSON.stringify({ title, desc, visibility, expire });
        const payload = {
            description: meta,
            public: visibility === 'PUBLIC',
            files: {
                [title + ".lua"]: { content: code }
            }
        };

        try {
            let url = 'https://api.github.com/gists';
            let method = 'POST';
            
            if (isEditing && currentEditingId) {
                url = `https://api.github.com/gists/${currentEditingId}`;
                method = 'PATCH';
                
                const oldScript = scriptsCache.find(s => s.id === currentEditingId);
                if(oldScript && oldScript.title !== title) {
                    payload.files[oldScript.title + ".lua"] = null; 
                }
            }

            const res = await fetch(url, {
                method: method,
                headers: { Authorization: `token ${GH_TOKEN}` },
                body: JSON.stringify(payload)
            });

            if(res.ok) {
                Toastify({ text: "Script saved successfully", backgroundColor: "var(--color-primary)" }).showToast();
                resetEditor();
                switchAdminTab('list');
                loadScripts();
            } else {
                throw new Error("API Error");
            }
        } catch (e) {
            Toastify({ text: "Failed to save script", backgroundColor: "var(--color-danger)" }).showToast();
        }
        NProgress.done();
    }

    async function deleteScript(id) {
        Swal.fire({
            title: 'Delete Script?',
            text: "You won't be able to revert this!",
            icon: 'warning',
            showCancelButton: true,
            confirmButtonColor: '#d33',
            cancelButtonColor: '#3085d6',
            confirmButtonText: 'Yes, delete it!'
        }).then(async (result) => {
            if (result.isConfirmed) {
                NProgress.start();
                try {
                    await fetch(`https://api.github.com/gists/${id}`, {
                        method: 'DELETE',
                        headers: { Authorization: `token ${GH_TOKEN}` }
                    });
                    loadScripts();
                    Toastify({ text: "Deleted successfully", backgroundColor: "var(--color-primary)" }).showToast();
                } catch {
                    Toastify({ text: "Failed to delete", backgroundColor: "var(--color-danger)" }).showToast();
                }
                NProgress.done();
            } else {
                renderAdminList(); 
            }
        });
    }

    function resetEditor() {
        isEditing = false;
        currentEditingId = null;
        dom.editTitle.value = '';
        dom.editVisibility.value = 'PUBLIC';
        dom.editExpire.value = '';
        quillEditor.setText('');
        monacoEditor.setValue('-- Lua Script');
        dom.editorHeading.innerText = "Create New Script";
    }

    function switchAdminTab(tabName) {
        document.querySelectorAll('.admin-tab').forEach(el => el.style.display = 'none');
        document.getElementById(`admin-tab-${tabName}`).style.display = 'block';
        
        dom.tabBtns.forEach(btn => btn.classList.remove('active'));
        event?.currentTarget?.classList.add('active');

        if(tabName === 'create' && !isEditing) resetEditor();
    }

    function renderStats() {
        const total = scriptsCache.length;
        const publicCount = scriptsCache.filter(s => s.visibility === 'PUBLIC').length;
        const privateCount = scriptsCache.filter(s => s.visibility === 'PRIVATE').length;
        
        document.getElementById('stats-content').innerHTML = `
            <div class="stats-grid">
                <div class="stat-card"><div class="stat-number">${total}</div><div class="stat-label">Total Scripts</div></div>
                <div class="stat-card"><div class="stat-number">${publicCount}</div><div class="stat-label">Public</div></div>
                <div class="stat-card"><div class="stat-number">${privateCount}</div><div class="stat-label">Private</div></div>
            </div>
        `;
    }

    function logout() {
        GH_TOKEN = null;
        localStorage.removeItem('ls_auth_token');
        dom.authSection.style.display = 'block';
        dom.userSection.style.display = 'none';
        navigate('');
        location.reload();
    }

    window.app = {
        toggleLoginModal: () => {
            const isVisible = dom.loginModal.style.display === 'flex';
            dom.loginModal.style.display = isVisible ? 'none' : 'flex';
            dom.loginError.style.display = 'none';
            dom.authToken.value = '';
        },
        submitLogin: async () => {
            const token = dom.authToken.value.trim();
            if(!token) return;
            
            NProgress.start();
            if(await verifyToken(token)) {
                GH_TOKEN = token;
                localStorage.setItem('ls_auth_token', token);
                dom.loginModal.style.display = 'none';
                dom.authSection.style.display = 'none';
                dom.userSection.style.display = 'block';
                document.getElementById('private-filter').style.display = 'flex';
                document.getElementById('unlisted-filter').style.display = 'flex';
                loadScripts();
                app.navigate('admin');
            } else {
                dom.loginError.innerText = "Invalid Token";
                dom.loginError.style.display = 'block';
            }
            NProgress.done();
        },
        navigate: (view) => {
            if(view === 'admin') {
                dom.viewHome.style.display = 'none';
                dom.viewAdmin.style.display = 'block';
                renderAdminList();
            } else {
                dom.viewAdmin.style.display = 'none';
                dom.viewHome.style.display = 'block';
            }
        },
        filterCategory: (cat, e) => {
            e.preventDefault();
            dom.filterLinks.forEach(l => l.classList.remove('active'));
            e.currentTarget.classList.add('active');
            currentCategory = cat;
            renderScripts();
        },
        setSort: (val) => {
            currentSort = val;
            renderScripts();
        },
        switchAdminTab,
        saveScript,
        logout
    };

    init();
})();
