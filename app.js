const state = {
    view: 'home',
    scripts: [],
    searchQuery: '',
    currentFilter: 'all',
    currentSort: 'newest',
    authToken: localStorage.getItem('gh_token'),
    isAdmin: false,
    editingId: null,
    githubConfig: null
};

const UI = {
    scriptList: document.getElementById('script-list'),
    adminList: document.getElementById('admin-list'),
    search: document.getElementById('search'),
    sort: document.getElementById('sort-select'),
    views: document.querySelectorAll('.view-section'),
    userSection: document.getElementById('user-section'),
    authSection: document.getElementById('auth-section'),
    loginModal: document.getElementById('login-modal'),
    scriptContentView: document.getElementById('script-content-view')
};

function escapeHtml(unsafe) {
    if (!unsafe) return "";
    return unsafe
        .replace(/&/g, "&amp;")
        .replace(/</g, "&lt;")
        .replace(/>/g, "&gt;")
        .replace(/"/g, "&quot;")
        .replace(/'/g, "&#039;");
}

function showToast(msg, type = 'success') {
    Toastify({
        text: msg,
        duration: 3000,
        gravity: "bottom",
        position: "right",
        className: `animate__animated animate__fadeInUp toast-${type}`,
        style: {
            background: 'transparent',
            border: `1px solid ${type === 'error' ? 'var(--danger)' : 'var(--accent)'}`,
            backdropFilter: 'blur(10px)',
            boxShadow: '0 10px 30px rgba(0,0,0,0.5)'
        }
    }).showToast();
}

async function init() {
    setupEventListeners();
    setupResponsiveUI();
    
    if (state.authToken) {
        state.isAdmin = true;
        UI.userSection.style.display = 'block';
        UI.authSection.style.display = 'none';
        document.getElementById('private-filter').style.display = 'flex';
    }
    
    await loadScripts();
}

function setupEventListeners() {
    document.addEventListener('click', e => {
        const target = e.target.closest('[data-action]');
        if (!target) return;

        const action = target.dataset.action;
        const param = target.dataset.param;

        if (action === 'navigate') showView(param || 'home');
        if (action === 'filter') {
            state.currentFilter = param;
            document.querySelectorAll('.sidebar-link').forEach(l => l.classList.remove('active'));
            target.classList.add('active');
            renderScripts();
        }
        if (action === 'login-modal') {
            if (UI.loginModal.style.display === 'none') {
                UI.loginModal.style.display = 'flex';
                document.getElementById('auth-token').focus();
            } else {
                UI.loginModal.style.display = 'none';
            }
        }
        if (action === 'login') handleLogin();
        if (action === 'logout') handleLogout();
        if (action === 'admin-tab') switchAdminTab(param);
        if (action === 'save-script') handleSave();
        if (action === 'view-script') openScript(param);
        if (action === 'copy-code') copyCode(param);
        if (action === 'download-code') downloadCode(param);
        if (action === 'raw-code') openRaw(param);
        
        e.stopPropagation();
    });

    UI.search.addEventListener('input', e => {
        state.searchQuery = e.target.value.toLowerCase();
        renderScripts();
    });

    UI.sort.addEventListener('change', e => {
        state.currentSort = e.target.value;
        renderScripts();
    });

    document.getElementById('btn-delete').addEventListener('click', handleDelete);
    
    document.addEventListener('keydown', e => {
        if (e.key === 'Escape' && UI.loginModal.style.display === 'flex') {
            UI.loginModal.style.display = 'none';
        }
    });
    
    window.addEventListener('resize', setupResponsiveUI);
}

function setupResponsiveUI() {
    const isMobile = window.innerWidth <= 768;
    const isPortrait = window.innerHeight > window.innerWidth;
    
    if (isMobile) {
        if (isPortrait) {
            UI.sort.style.display = 'none';
            document.querySelector('.sidebar-sort')?.style.display = 'none';
        } else {
            UI.sort.style.display = 'block';
            document.querySelector('.sidebar-sort')?.style.display = 'block';
        }
        
        document.querySelectorAll('.admin-item').forEach(item => {
            item.style.flexDirection = 'column';
            item.style.alignItems = 'flex-start';
            item.style.padding = '16px';
        });
        
        document.querySelectorAll('.toolbar-right').forEach(toolbar => {
            toolbar.style.flexWrap = 'wrap';
            toolbar.style.gap = '8px';
        });
        
        document.querySelectorAll('.code-textarea').forEach(textarea => {
            textarea.style.minHeight = '300px';
            textarea.style.fontSize = '14px';
        });
    } else {
        UI.sort.style.display = 'block';
        document.querySelector('.sidebar-sort')?.style.display = 'block';
    }
}

async function loadScripts() {
    try {
        if (state.isAdmin && state.authToken) {
            const scripts = await fetchDatabaseFromGitHub();
            if (scripts && Array.isArray(scripts)) {
                state.scripts = scripts.filter(script => !script.expire || new Date(script.expire) > new Date());
            } else {
                state.scripts = [];
            }
        } else {
            state.scripts = [];
        }
    } catch (error) {
        state.scripts = [];
    }
    renderScripts();
}

async function fetchDatabaseFromGitHub() {
    try {
        const repoPath = window.location.pathname.split('/')[1] || 'scripts';
        const username = await getGitHubUsername();
        
        if (!username) return null;
        
        const response = await fetch(
            `https://api.github.com/repos/${username}/${repoPath}/contents/database.json`,
            {
                headers: {
                    'Authorization': `token ${state.authToken}`,
                    'Accept': 'application/vnd.github.v3+json'
                }
            }
        );
        
        if (response.status === 404) {
            return [];
        }
        
        if (response.ok) {
            const data = await response.json();
            const content = atob(data.content.replace(/\n/g, ''));
            return JSON.parse(content);
        }
        return null;
    } catch (error) {
        return null;
    }
}

async function getGitHubUsername() {
    try {
        const response = await fetch('https://api.github.com/user', {
            headers: {
                'Authorization': `token ${state.authToken}`,
                'Accept': 'application/vnd.github.v3+json'
            }
        });
        
        if (response.ok) {
            const userData = await response.json();
            return userData.login;
        }
        return null;
    } catch (error) {
        return null;
    }
}

async function saveDatabaseToGitHub() {
    try {
        const repoPath = window.location.pathname.split('/')[1] || 'scripts';
        const username = await getGitHubUsername();
        
        if (!username) {
            showToast("Cannot save: GitHub not configured", "error");
            return false;
        }
        
        let sha = null;
        try {
            const getResponse = await fetch(
                `https://api.github.com/repos/${username}/${repoPath}/contents/database.json`,
                {
                    headers: {
                        'Authorization': `token ${state.authToken}`,
                        'Accept': 'application/vnd.github.v3+json'
                    }
                }
            );
            
            if (getResponse.ok) {
                const data = await getResponse.json();
                sha = data.sha;
            }
        } catch (e) {
        }
        
        const filteredScripts = state.scripts.filter(script => !script.expire || new Date(script.expire) > new Date());
        const content = btoa(JSON.stringify(filteredScripts, null, 2));
        const payload = {
            message: `Update scripts database - ${new Date().toISOString()}`,
            content: content,
            sha: sha
        };
        
        const response = await fetch(
            `https://api.github.com/repos/${username}/${repoPath}/contents/database.json`,
            {
                method: 'PUT',
                headers: {
                    'Authorization': `token ${state.authToken}`,
                    'Accept': 'application/vnd.github.v3+json',
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify(payload)
            }
        );
        
        return response.ok;
    } catch (error) {
        return false;
    }
}

function renderScripts() {
    let filtered = state.scripts.filter(s => {
        const matchesSearch = s.title.toLowerCase().includes(state.searchQuery) || 
                             s.description.toLowerCase().includes(state.searchQuery);
        const matchesFilter = state.currentFilter === 'all' || 
                             s.visibility.toLowerCase() === state.currentFilter;
        const notExpired = !s.expire || new Date(s.expire) > new Date();
        return matchesSearch && matchesFilter && notExpired;
    });

    if (state.currentSort === 'alpha') {
        filtered.sort((a, b) => a.title.localeCompare(b.title));
    } else {
        filtered.sort((a, b) => new Date(b.created) - new Date(a.created));
    }

    if (filtered.length === 0) {
        UI.scriptList.innerHTML = `
            <div style="text-align:center;padding:60px 0;grid-column:1/-1;">
                <svg width="64" height="64" viewBox="0 0 24 24" fill="none" stroke="var(--text-muted)" stroke-width="1.5" style="margin-bottom:20px;">
                    <path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"></path>
                    <line x1="12" y1="9" x2="12" y2="13"></line>
                    <line x1="12" y1="17" x2="12.01" y2="17"></line>
                </svg>
                <p style="color:var(--text-muted);font-size:16px;font-weight:500;">No scripts found</p>
                ${!state.isAdmin ? '<p style="color:var(--text-muted);font-size:14px;margin-top:8px;">Login to see private scripts</p>' : ''}
            </div>
        `;
        return;
    }

    UI.scriptList.innerHTML = filtered.map(s => `
        <div class="script-card animate__animated animate__fadeIn" data-action="view-script" data-param="${s.id}">
            <div class="card-header-section">
                <span class="script-title">${escapeHtml(s.title)}</span>
                <span class="badge badge-${s.visibility.toLowerCase()}">${s.visibility}</span>
            </div>
            <p class="text-muted" style="font-size:14px;margin-bottom:16px;line-height:1.5;">${escapeHtml(s.description)}</p>
            <div class="card-meta">
                <span style="display:flex;align-items:center;gap:6px;">
                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                        <polyline points="16 18 22 12 16 6"></polyline>
                        <polyline points="8 6 2 12 8 18"></polyline>
                    </svg>
                    Lua
                </span>
                <span>${new Date(s.created).toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' })}</span>
            </div>
        </div>
    `).join('');
}

function openScript(id) {
    const script = state.scripts.find(s => s.id === id);
    if (!script) return;

    showView('script');
    UI.scriptContentView.innerHTML = `
        <div class="script-header-lg animate__animated animate__fadeIn">
            <div class="brand" style="margin-bottom: 24px;">
                <img src="https://yt3.ggpht.com/wrMKTrl_4TexkVLuTILn1KZWW6NEbqTyLts9UhZNZhzLkOEBS13lBAi3gVl1Q465QruIDSwCUQ=s160-c-k-c0x00ffffff-no-rj" class="nav-icon">
                <span class="nav-title">Leaf's Scripts</span>
            </div>
            <h1>${escapeHtml(script.title)}</h1>
            <div class="meta-row">
                <div class="meta-badge">
                    ${script.visibility === 'PRIVATE' ? '<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="11" width="18" height="11" rx="2" ry="2"></rect><path d="M7 11V7a5 5 0 0 1 10 0v4"></path></svg>' : 
                      script.visibility === 'UNLISTED' ? '<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="3"></circle><path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 0 1 0 2.83 2 2 0 0 1-2.83 0l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-2 2 2 2 0 0 1-2-2v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 0 1-2.83 0 2 2 0 0 1 0-2.83l.06-.06a1.65 1.65 0 0 0 .33-1.82 1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1-2-2 2 2 0 0 1 2-2h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 0 1 0-2.83 2 2 0 0 1 2.83 0l.06.06a1.65 1.65 0 0 0 1.82.33H9a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 2-2 2 2 0 0 1 2 2v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 0 1 2.83 0 2 2 0 0 1 0 2.83l-.06.06a1.65 1.65 0 0 0-.33 1.82V9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 2 2 2 2 0 0 1-2 2h-.09a1.65 1.65 0 0 0-1.51 1z"></path></svg>' :
                      '<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"></circle><path d="M2 12h20"></path></svg>'}
                    <span style="margin-left: 6px">${script.visibility}</span>
                </div>
                <div class="meta-badge">
                    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                        <polyline points="16 18 22 12 16 6"></polyline>
                        <polyline points="8 6 2 12 8 18"></polyline>
                    </svg>
                    <span style="margin-left: 6px">Lua</span>
                </div>
                ${script.expire ? `
                <div class="meta-badge">
                    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                        <circle cx="12" cy="12" r="10"></circle>
                        <polyline points="12 6 12 12 16 14"></polyline>
                    </svg>
                    <span style="margin-left: 6px">Expires: ${new Date(script.expire).toLocaleDateString()}</span>
                </div>
                ` : ''}
            </div>
        </div>
        <div class="code-box animate__animated animate__fadeInUp">
            <div class="toolbar">
                <span class="file-info">${escapeHtml(script.title).toLowerCase().replace(/[^\w\s]/gi, '').replace(/\s+/g, '_')}.lua</span>
                <div class="toolbar-right">
                    <button class="btn btn-emerald" data-action="copy-code" data-param="${script.id}">Copy</button>
                    <button class="btn btn-secondary" data-action="raw-code" data-param="${script.id}">Raw</button>
                    <button class="btn btn-secondary" data-action="download-code" data-param="${script.id}">Download</button>
                </div>
            </div>
            <pre style="margin:0;"><code class="language-lua">${escapeHtml(script.content)}</code></pre>
        </div>
    `;
    hljs.highlightAll();
}

function showView(viewName) {
    state.view = viewName;
    UI.views.forEach(v => {
        v.style.display = 'none';
        v.classList.remove('animate__fadeIn');
    });
    
    setTimeout(() => {
        if (viewName === 'admin') {
            const view = document.getElementById('view-admin');
            view.style.display = 'block';
            view.classList.add('animate__fadeIn');
            renderAdminList();
            setupResponsiveUI();
        } else if (viewName === 'script') {
            const view = document.getElementById('view-script');
            view.style.display = 'block';
            view.classList.add('animate__fadeIn');
        } else {
            const view = document.getElementById('view-home');
            view.style.display = 'block';
            view.classList.add('animate__fadeIn');
            renderScripts();
        }
    }, 10);
}

function renderAdminList() {
    if (state.scripts.length === 0) {
        UI.adminList.innerHTML = `
            <div style="text-align:center;padding:40px 0;color:var(--text-muted);" class="animate__animated animate__fadeIn">
                <svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" style="margin-bottom:16px;opacity:0.5;">
                    <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"></path>
                    <polyline points="14 2 14 8 20 8"></polyline>
                    <line x1="16" y1="13" x2="8" y2="13"></line>
                    <line x1="16" y1="17" x2="8" y2="17"></line>
                    <polyline points="10 9 9 9 8 9"></polyline>
                </svg>
                <p style="font-size:16px;margin-bottom:8px;">No scripts yet</p>
                <p style="font-size:14px;opacity:0.7;">Click "Add New" to create your first script</p>
            </div>
        `;
        return;
    }
    
    const validScripts = state.scripts.filter(s => !s.expire || new Date(s.expire) > new Date());
    
    UI.adminList.innerHTML = validScripts.map(s => `
        <div class="admin-item animate__animated animate__fadeIn" onclick="openEditor('${s.id}')">
            <div class="admin-item-left">
                <strong>${escapeHtml(s.title)}</strong>
                <div style="display:flex;align-items:center;gap:12px;margin-top:4px;">
                    <span class="badge badge-${s.visibility.toLowerCase()}" style="font-size:10px;padding:4px 8px;">${s.visibility}</span>
                    <span class="text-muted" style="font-size:12px;">
                        ${new Date(s.created).toLocaleDateString()}
                        ${s.expire ? ` • Expires: ${new Date(s.expire).toLocaleDateString()}` : ''}
                    </span>
                </div>
            </div>
            <div class="admin-item-right">
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <path d="M9 18l6-6-6-6"/>
                </svg>
            </div>
        </div>
    `).join('');
    
    document.getElementById('total-stats').innerHTML = `${validScripts.length} script${validScripts.length !== 1 ? 's' : ''}`;
}

function openEditor(id = null) {
    state.editingId = id;
    switchAdminTab('editor');
    const heading = document.getElementById('editor-heading');
    const deleteBtn = document.getElementById('btn-delete');
    
    if (id) {
        const s = state.scripts.find(x => x.id === id);
        heading.innerText = 'Edit Script';
        deleteBtn.style.display = 'block';
        deleteBtn.classList.remove('btn-danger');
        deleteBtn.classList.add('btn-danger');
        document.getElementById('edit-title').value = s.title;
        document.getElementById('edit-desc').value = s.description;
        document.getElementById('edit-visibility').value = s.visibility;
        document.getElementById('edit-code').value = s.content;
        if (s.expire) {
            document.getElementById('edit-expire').value = s.expire.split('T')[0];
        } else {
            document.getElementById('edit-expire').value = '';
        }
    } else {
        heading.innerText = 'Create New Script';
        deleteBtn.style.display = 'none';
        document.getElementById('edit-title').value = '';
        document.getElementById('edit-desc').value = '';
        document.getElementById('edit-code').value = '';
        document.getElementById('edit-expire').value = '';
        document.getElementById('edit-visibility').value = 'PUBLIC';
    }
}

function switchAdminTab(tab) {
    document.querySelectorAll('.admin-tab').forEach(t => {
        t.style.display = 'none';
        t.classList.remove('animate__fadeIn');
    });
    document.querySelectorAll('.tab-btn').forEach(b => b.classList.remove('active'));
    
    if (tab === 'create') {
        openEditor(null);
    } else {
        const tabElement = document.getElementById(`admin-tab-${tab}`);
        tabElement.style.display = 'block';
        setTimeout(() => tabElement.classList.add('animate__fadeIn'), 10);
        document.querySelector(`[data-param="${tab}"]`)?.classList.add('active');
    }
    setupResponsiveUI();
}

async function handleSave() {
    const title = document.getElementById('edit-title').value.trim();
    const desc = document.getElementById('edit-desc').value.trim();
    const content = document.getElementById('edit-code').value.trim();
    const visibility = document.getElementById('edit-visibility').value;
    const expire = document.getElementById('edit-expire').value;

    if (!title) {
        showToast("Script title is required", "error");
        document.getElementById('edit-title').focus();
        return;
    }
    
    if (!content) {
        showToast("Source code is required", "error");
        document.getElementById('edit-code').focus();
        return;
    }

    const newScript = {
        id: state.editingId || Date.now().toString(),
        title: title,
        description: desc || "No description",
        visibility: visibility,
        content: content,
        created: state.editingId ? state.scripts.find(s => s.id === state.editingId)?.created || new Date().toISOString() : new Date().toISOString(),
        expire: expire ? new Date(expire + 'T23:59:59').toISOString() : null
    };

    if (state.editingId) {
        state.scripts = state.scripts.map(s => s.id === state.editingId ? newScript : s);
        showToast("Script updated successfully");
    } else {
        state.scripts.unshift(newScript);
        showToast("Script created successfully");
    }
    
    if (state.isAdmin) {
        const saved = await saveDatabaseToGitHub();
        if (!saved) {
            showToast("Error: Could not save to GitHub", "error");
        }
    }
    
    showView('admin');
    switchAdminTab('list');
}

async function handleDelete() {
    if (!state.editingId) return;
    
    if (confirm('Are you sure you want to delete this script? This action cannot be undone.')) {
        state.scripts = state.scripts.filter(s => s.id !== state.editingId);
        
        if (state.isAdmin) {
            const saved = await saveDatabaseToGitHub();
            if (!saved) {
                showToast("Error: Could not update GitHub", "error");
            } else {
                showToast("Script deleted successfully");
            }
        } else {
            showToast("Script deleted locally");
        }
        
        state.editingId = null;
        showView('admin');
        switchAdminTab('list');
    }
}

function copyCode(id) {
    const s = state.scripts.find(x => x.id === id);
    if (!s) return;
    
    navigator.clipboard.writeText(s.content).then(() => {
        showToast("Source code copied to clipboard!");
    }).catch(() => {
        const textArea = document.createElement('textarea');
        textArea.value = s.content;
        document.body.appendChild(textArea);
        textArea.select();
        document.execCommand('copy');
        document.body.removeChild(textArea);
        showToast("Source code copied to clipboard!");
    });
}

function downloadCode(id) {
    const s = state.scripts.find(x => x.id === id);
    if (!s) return;
    
    const blob = new Blob([s.content], { type: 'text/plain' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `${s.title.replace(/[^\w\s]/gi, '').replace(/\s+/g, '_')}.lua`;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(url);
    showToast("Download started");
}

function openRaw(id) {
    const s = state.scripts.find(x => x.id === id);
    if (!s) return;
    
    const win = window.open('', '_blank');
    win.document.write(`
        <!DOCTYPE html>
        <html>
        <head>
            <title>${escapeHtml(s.title)} - Raw</title>
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>
                body { margin: 0; padding: 20px; font-family: 'Courier New', monospace; background: #000; color: #00ff88; white-space: pre-wrap; line-height: 1.6; }
                @media (max-width: 768px) { body { padding: 16px; font-size: 14px; } }
            </style>
        </head>
        <body>${escapeHtml(s.content)}</body>
        </html>
    `);
}

async function handleLogin() {
    const token = document.getElementById('auth-token').value.trim();
    const errorEl = document.getElementById('login-error');
    
    if (!token) {
        errorEl.textContent = "Please enter a token";
        errorEl.style.display = 'block';
        return;
    }
    
    try {
        errorEl.style.display = 'none';
        
        const response = await fetch('https://api.github.com/user', {
            headers: {
                'Authorization': `token ${token}`,
                'Accept': 'application/vnd.github.v3+json'
            }
        });
        
        if (response.ok) {
            localStorage.setItem('gh_token', token);
            state.authToken = token;
            state.isAdmin = true;
            
            showToast("Login successful!");
            
            setTimeout(() => {
                UI.loginModal.style.display = 'none';
                document.getElementById('auth-token').value = '';
                
                UI.userSection.style.display = 'block';
                UI.authSection.style.display = 'none';
                document.getElementById('private-filter').style.display = 'flex';
                
                loadScripts();
            }, 1000);
            
        } else {
            errorEl.textContent = "Invalid token";
            errorEl.style.display = 'block';
        }
    } catch (error) {
        errorEl.textContent = "Login failed";
        errorEl.style.display = 'block';
    }
}

function handleLogout() {
    if (confirm('Are you sure you want to logout?')) {
        localStorage.removeItem('gh_token');
        localStorage.removeItem('gh_config');
        showToast("Logged out successfully");
        setTimeout(() => location.reload(), 1000);
    }
}

init();
