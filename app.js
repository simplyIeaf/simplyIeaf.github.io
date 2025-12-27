const state = {
    view: 'home',
    scripts: [],
    filteredScripts: [],
    searchQuery: '',
    currentFilter: 'all',
    currentSort: 'newest',
    authToken: localStorage.getItem('gh_token'),
    repo: localStorage.getItem('gh_repo'),
    isAdmin: false,
    editingId: null
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
        .replace(/&/g, "&")
        .replace(/</g, "<")
        .replace(/>/g, ">")
        .replace(/"/g, """)
        .replace(/'/g, "'");
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
    if (state.authToken && state.repo) {
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
}

async function loadScripts() {
    if (!state.repo || !state.authToken) {
        state.scripts = [];
        renderScripts();
        return;
    }

    try {
        const response = await fetch(`https://api.github.com/repos/${state.repo}/contents/`, {
            headers: { 'Authorization': `token ${state.authToken}` }
        });
        
        if (!response.ok) throw new Error('Failed to fetch scripts');
        
        const files = await response.json();
        const jsonFiles = files.filter(f => f.name.endsWith('.json'));
        
        const loadedScripts = await Promise.all(jsonFiles.map(async file => {
            const res = await fetch(file.download_url);
            const data = await res.json();
            return { ...data, sha: file.sha, fileName: file.name };
        }));

        state.scripts = loadedScripts;
        renderScripts();
    } catch (error) {
        console.error(error);
        if (state.isAdmin) showToast(`Could not load scripts from ${state.repo}`, 'error');
    }
}

function renderScripts() {
    let filtered = state.scripts.filter(s => {
        const matchesSearch = s.title.toLowerCase().includes(state.searchQuery);
        const matchesFilter = state.currentFilter === 'all' || s.visibility.toLowerCase() === state.currentFilter;
        return matchesSearch && matchesFilter;
    });

    if (state.currentSort === 'alpha') {
        filtered.sort((a, b) => a.title.localeCompare(b.title));
    } else {
        filtered.sort((a, b) => new Date(b.created) - new Date(a.created));
    }

    if(filtered.length === 0) {
        UI.scriptList.innerHTML = `<div style="grid-column:1/-1;text-align:center;padding:40px;color:var(--text-muted)">No scripts found.</div>`;
    } else {
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
    } else if (viewName === 'script') {
        document.getElementById('view-script').style.display = 'block';
    } else {
        document.getElementById('view-home').style.display = 'block';
        renderScripts();
    }
}

function renderAdminList() {
    UI.adminList.innerHTML = state.scripts.map(s => `
        <div class="admin-item" onclick="openEditor('${s.id}')">
            <div class="admin-item-left">
                <strong>${escapeHtml(s.title)}</strong>
                <span class="text-muted" style="font-size:12px">${s.fileName}</span>
            </div>
            <div class="admin-item-right">
                <span class="badge badge-${s.visibility.toLowerCase()}">${s.visibility}</span>
            </div>
        </div>
    `).join('');
    document.getElementById('total-stats').innerText = `${state.scripts.length} Scripts`;
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
    } else {
        heading.innerText = 'Create New Script';
        deleteBtn.style.display = 'none';
        document.getElementById('edit-title').value = '';
        document.getElementById('edit-desc').value = '';
        document.getElementById('edit-code').value = '';
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
}

async function handleSave() {
    const title = document.getElementById('edit-title').value;
    const desc = document.getElementById('edit-desc').value;
    const content = document.getElementById('edit-code').value;

    if(!title || !content) {
        showToast("Title and Source Code are required", "error");
        return;
    }

    const scriptData = {
        id: state.editingId || Date.now().toString(),
        title: title,
        description: desc,
        visibility: document.getElementById('edit-visibility').value,
        content: content,
        created: new Date().toISOString()
    };

    const fileName = state.editingId 
        ? state.scripts.find(s => s.id === state.editingId).fileName 
        : `script_${scriptData.id}.json`;

    const encodedContent = btoa(unescape(encodeURIComponent(JSON.stringify(scriptData, null, 2))));

    const body = {
        message: state.editingId ? `Update ${title}` : `Create ${title}`,
        content: encodedContent
    };

    if (state.editingId) {
        const s = state.scripts.find(x => x.id === state.editingId);
        body.sha = s.sha;
    }

    try {
        const res = await fetch(`https://api.github.com/repos/${state.repo}/contents/${fileName}`, {
            method: 'PUT',
            headers: {
                'Authorization': `token ${state.authToken}`,
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(body)
        });

        if(!res.ok) throw new Error('GitHub API Error');
        
        showToast(state.editingId ? "Script updated" : "Script created");
        await loadScripts();
        showView('admin');
        switchAdminTab('list');
    } catch(e) {
        showToast("Failed to save to GitHub", "error");
        console.error(e);
    }
}

async function handleDelete() {
    if (!state.editingId) {
        showToast("Error: No script selected for deletion", "error");
        return;
    }
    
    if (confirm('Are you sure you want to permanently delete this script?')) {
        const s = state.scripts.find(x => x.id === state.editingId);
        
        try {
            const res = await fetch(`https://api.github.com/repos/${state.repo}/contents/${s.fileName}`, {
                method: 'DELETE',
                headers: {
                    'Authorization': `token ${state.authToken}`,
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({
                    message: `Delete ${s.title}`,
                    sha: s.sha
                })
            });

            if(!res.ok) throw new Error('Delete Failed');
            
            showToast("Script deleted from GitHub");
            state.editingId = null;
            await loadScripts();
            showView('admin');
            switchAdminTab('list');
        } catch(e) {
            showToast("Failed to delete script", "error");
            console.error(e);
        }
    }
}

function copyCode(id) {
    const s = state.scripts.find(x => x.id === id);
    navigator.clipboard.writeText(s.content).then(() => {
        showToast("Source code copied to clipboard!");
    });
}

function downloadCode(id) {
    const s = state.scripts.find(x => x.id === id);
    const blob = new Blob([s.content], { type: 'text/plain' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `${s.title.replace(/\s/g, '_')}.lua`;
    a.click();
    showToast("Download started");
}

function openRaw(id) {
    const s = state.scripts.find(x => x.id === id);
    const win = window.open('', '_blank');
    win.document.write(`<pre style="word-wrap: break-word; white-space: pre-wrap;">${escapeHtml(s.content)}</pre>`);
}

async function handleLogin() {
    const token = document.getElementById('auth-token').value;
    if (!token) return;

    try {
        const res = await fetch('https://api.github.com/user', {
            headers: { 'Authorization': `token ${token}` }
        });
        
        if (!res.ok) throw new Error('Invalid Token');
        const user = await res.json();
        
        const repo = `${user.login}/scripts-db`;
        
        localStorage.setItem('gh_token', token);
        localStorage.setItem('gh_repo', repo);
        
        state.authToken = token;
        state.repo = repo;
        state.isAdmin = true;
        location.reload();
    } catch (e) {
        showToast("Invalid GitHub Token", "error");
    }
}

function handleLogout() {
    localStorage.removeItem('gh_token');
    localStorage.removeItem('gh_repo');
    location.reload();
}

init();
