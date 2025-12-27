const state = {
    view: 'home',
    scripts: [],
    filteredScripts: [],
    searchQuery: '',
    currentFilter: 'all',
    currentSort: 'newest',
    authToken: localStorage.getItem('gh_token'),
    isAdmin: false,
    editingId: null,
    githubConfig: {
        username: '',
        repo: '',
        path: 'database.json'
    }
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
        className: "animate__animated animate__fadeInUp",
        style: {
            background: type === 'error' ? 'var(--danger)' : 'var(--surface)',
            border: `1px solid ${type === 'error' ? 'var(--danger)' : 'var(--accent)'}`
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
        await autoDetectRepo();
        await loadScripts();
    } else {
        await loadScripts();
    }
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
        if (action === 'login-modal') UI.loginModal.style.display = UI.loginModal.style.display === 'none' ? 'flex' : 'none';
        if (action === 'login') handleLogin();
        if (action === 'logout') handleLogout();
        if (action === 'admin-tab') switchAdminTab(param);
        if (action === 'save-script') handleSave();
        if (action === 'view-script') openScript(param);
        if (action === 'copy-code') copyCode(param);
        if (action === 'download-code') downloadCode(param);
        if (action === 'raw-code') openRaw(param);
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
    
    window.addEventListener('resize', setupResponsiveUI);
}

function setupResponsiveUI() {
    const isMobile = window.innerWidth <= 768;
    const isPortrait = window.innerHeight > window.innerWidth;
    
    if (isMobile) {
        if (isPortrait) {
            UI.sort.style.display = 'none';
            document.querySelector('.sidebar-sort').style.display = 'none';
        } else {
            UI.sort.style.display = 'block';
            document.querySelector('.sidebar-sort').style.display = 'block';
        }
        
        document.querySelectorAll('.admin-item').forEach(item => {
            item.style.flexDirection = 'column';
            item.style.alignItems = 'flex-start';
            item.style.padding = '12px';
        });
        
        document.querySelectorAll('.toolbar-right').forEach(toolbar => {
            toolbar.style.flexWrap = 'wrap';
            toolbar.style.gap = '6px';
        });
        
        document.querySelectorAll('.code-textarea').forEach(textarea => {
            textarea.style.minHeight = '300px';
            textarea.style.fontSize = '14px';
        });
    } else {
        UI.sort.style.display = 'block';
        document.querySelector('.sidebar-sort').style.display = 'block';
    }
}

async function autoDetectRepo() {
    try {
        const response = await fetch('https://api.github.com/user/repos', {
            headers: {
                'Authorization': `token ${state.authToken}`,
                'Accept': 'application/vnd.github.v3+json'
            }
        });
        
        if (response.ok) {
            const repos = await response.json();
            const currentUrl = window.location.href;
            
            repos.forEach(repo => {
                if (currentUrl.includes(repo.name.toLowerCase())) {
                    state.githubConfig.username = repo.owner.login;
                    state.githubConfig.repo = repo.name;
                    localStorage.setItem('gh_repo', JSON.stringify(state.githubConfig));
                }
            });
            
            if (!state.githubConfig.username) {
                const saved = localStorage.getItem('gh_repo');
                if (saved) {
                    state.githubConfig = JSON.parse(saved);
                }
            }
        }
    } catch (error) {
        console.error('Auto-detect error:', error);
    }
}

async function loadScripts() {
    if (state.isAdmin && state.authToken && state.githubConfig.username) {
        try {
            const scripts = await fetchDatabaseFromGitHub();
            if (scripts && Array.isArray(scripts)) {
                state.scripts = scripts;
            } else {
                state.scripts = [];
            }
        } catch (error) {
            console.error('Load error:', error);
            state.scripts = [];
        }
    } else {
        state.scripts = [];
    }
    renderScripts();
}

async function fetchDatabaseFromGitHub() {
    if (!state.authToken || !state.githubConfig.username) return null;
    
    try {
        const response = await fetch(
            `https://api.github.com/repos/${state.githubConfig.username}/${state.githubConfig.repo}/contents/${state.githubConfig.path}`,
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
        console.error('GitHub fetch error:', error);
        return null;
    }
}

async function saveDatabaseToGitHub() {
    if (!state.authToken || !state.githubConfig.username) {
        showToast("Cannot save: GitHub not configured", "error");
        return false;
    }
    
    try {
        let sha = null;
        try {
            const getResponse = await fetch(
                `https://api.github.com/repos/${state.githubConfig.username}/${state.githubConfig.repo}/contents/${state.githubConfig.path}`,
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
        
        const content = btoa(JSON.stringify(state.scripts, null, 2));
        const payload = {
            message: `Update scripts database - ${new Date().toISOString()}`,
            content: content,
            sha: sha
        };
        
        const response = await fetch(
            `https://api.github.com/repos/${state.githubConfig.username}/${state.githubConfig.repo}/contents/${state.githubConfig.path}`,
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
        console.error('GitHub save error:', error);
        return false;
    }
}

function renderScripts() {
    let filtered = state.scripts.filter(s => {
        const matchesSearch = s.title.toLowerCase().includes(state.searchQuery) || 
                             s.description.toLowerCase().includes(state.searchQuery);
        const matchesFilter = state.currentFilter === 'all' || 
                             s.visibility.toLowerCase() === state.currentFilter;
        return matchesSearch && matchesFilter;
    });

    if (state.currentSort === 'alpha') {
        filtered.sort((a, b) => a.title.localeCompare(b.title));
    } else {
        filtered.sort((a, b) => new Date(b.created) - new Date(a.created));
    }

    if (filtered.length === 0) {
        UI.scriptList.innerHTML = `
            <div style="text-align:center;padding:60px 0;grid-column:1/-1;">
                <p style="color:var(--text-muted);">No scripts found</p>
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
            <p class="text-muted" style="font-size:13px;margin-bottom:12px;">${escapeHtml(s.description)}</p>
            <div class="card-meta">
                <span>Lua</span>
                <span>${new Date(s.created).toLocaleDateString()}</span>
            </div>
        </div>
    `).join('');
}

function openScript(id) {
    const script = state.scripts.find(s => s.id === id);
    if (!script) return;

    showView('script');
    UI.scriptContentView.innerHTML = `
        <div class="script-header-lg">
            <div class="brand" style="margin-bottom: 24px;">
                <img src="https://yt3.ggpht.com/wrMKTrl_4TexkVLuTILn1KZWW6NEbqTyLts9UhZNZhzLkOEBS13lBAi3gVl1Q465QruIDSwCUQ=s160-c-k-c0x00ffffff-no-rj" class="nav-icon">
                <span class="nav-title">Leaf's Scripts</span>
            </div>
            <h1>${escapeHtml(script.title)}</h1>
            <div class="meta-row">
                <div class="meta-badge">
                    ${script.visibility === 'PRIVATE' ? '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="11" width="18" height="11" rx="2" ry="2"></rect><path d="M7 11V7a5 5 0 0 1 10 0v4"></path></svg>' : '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"></circle><path d="M2 12h20"></path></svg>'}
                    <span style="margin-left: 4px">${script.visibility}</span>
                </div>
                <div class="meta-badge">Lua</div>
            </div>
        </div>
        <div class="code-box">
            <div class="toolbar">
                <span class="file-info">${escapeHtml(script.title).toLowerCase().replace(/\s/g, '_')}.lua</span>
                <div class="toolbar-right">
                    <button class="btn btn-emerald" data-action="copy-code" data-param="${script.id}">Copy</button>
                    <button class="btn btn-secondary" data-action="raw-code" data-param="${script.id}">Raw</button>
                    <button class="btn btn-secondary" data-action="download-code" data-param="${script.id}">Download</button>
                </div>
            </div>
            <pre><code class="language-lua">${escapeHtml(script.content)}</code></pre>
        </div>
    `;
    hljs.highlightAll();
}

function showView(viewName) {
    state.view = viewName;
    UI.views.forEach(v => v.style.display = 'none');
    
    if (viewName === 'admin') {
        document.getElementById('view-admin').style.display = 'block';
        renderAdminList();
        setupResponsiveUI();
    } else if (viewName === 'script') {
        document.getElementById('view-script').style.display = 'block';
    } else {
        document.getElementById('view-home').style.display = 'block';
        renderScripts();
    }
}

function renderAdminList() {
    if (state.scripts.length === 0) {
        UI.adminList.innerHTML = `
            <div style="text-align:center;padding:40px 0;color:var(--text-muted);">
                No scripts yet. Click "Add New" to create one.
            </div>
        `;
        return;
    }
    
    UI.adminList.innerHTML = state.scripts.map(s => `
        <div class="admin-item" onclick="openEditor('${s.id}')">
            <div class="admin-item-left">
                <strong>${escapeHtml(s.title)}</strong>
                <span class="text-muted">${s.visibility}</span>
            </div>
            <div class="admin-item-right">
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M9 18l6-6-6-6"/></svg>
            </div>
        </div>
    `).join('');
    
    document.getElementById('total-stats').innerHTML = `(${state.scripts.length} scripts)`;
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
    document.querySelectorAll('.admin-tab').forEach(t => t.style.display = 'none');
    document.querySelectorAll('.tab-btn').forEach(b => b.classList.remove('active'));
    
    if (tab === 'create') {
        openEditor(null);
    } else {
        document.getElementById(`admin-tab-${tab}`).style.display = 'block';
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

    if (!title || !content) {
        showToast("Title and Source Code are required", "error");
        return;
    }

    const newScript = {
        id: state.editingId || Date.now().toString(),
        title: title,
        description: desc,
        visibility: visibility,
        content: content,
        created: new Date().toISOString(),
        expire: expire ? new Date(expire).toISOString() : null
    };

    if (state.editingId) {
        state.scripts = state.scripts.map(s => s.id === state.editingId ? newScript : s);
    } else {
        state.scripts.push(newScript);
    }
    
    if (state.isAdmin) {
        const saved = await saveDatabaseToGitHub();
        if (saved) {
            showToast(state.editingId ? "Script updated successfully" : "Script created successfully");
        } else {
            showToast("Error saving to database", "error");
        }
    } else {
        showToast(state.editingId ? "Script updated locally" : "Script created locally");
    }
    
    showView('admin');
    switchAdminTab('list');
}

async function handleDelete() {
    if (!state.editingId) {
        showToast("Error: No script selected for deletion", "error");
        return;
    }
    
    if (confirm('Are you sure you want to delete this script? This action cannot be undone.')) {
        state.scripts = state.scripts.filter(s => s.id !== state.editingId);
        
        if (state.isAdmin) {
            const saved = await saveDatabaseToGitHub();
            if (!saved) {
                showToast("Warning: Could not delete from database", "error");
            }
        }
        
        state.editingId = null;
        showToast("Script deleted successfully");
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
            <style>
                body { margin: 20px; font-family: monospace; background: #111; color: #fff; white-space: pre-wrap; }
            </style>
        </head>
        <body>${escapeHtml(s.content)}</body>
        </html>
    `);
}

async function handleLogin() {
    const token = document.getElementById('auth-token').value.trim();
    if (!token.startsWith('ghp_') && !token.startsWith('github_pat_')) {
        showToast("Invalid GitHub token format", "error");
        return;
    }
    
    try {
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
            await autoDetectRepo();
            await loadScripts();
            location.reload();
        } else {
            showToast("Invalid GitHub token", "error");
        }
    } catch (error) {
        console.error('Login error:', error);
        showToast("Login failed. Check token.", "error");
    }
}

function handleLogout() {
    localStorage.removeItem('gh_token');
    localStorage.removeItem('gh_repo');
    location.reload();
}

init();
