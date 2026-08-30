const CONFIG = {
    user: 'simplyIeaf',
    repo: 'simplyIeaf.github.io',
    branch: 'main',
    cacheBuster: () => Date.now()
};

const utils = {
    debounce(func, wait) {
        let timeout;
        return function(...args) {
            const context = this;
            clearTimeout(timeout);
            timeout = setTimeout(() => func.apply(context, args), wait);
        };
    },
    
    safeBtoa(str) {
        try {
            return btoa(unescape(encodeURIComponent(str)));
        } catch(e) {
            return btoa(str);
        }
    },
    
    safeAtob(str) {
        try {
            return decodeURIComponent(escape(atob(str)));
        } catch(e) {
            return atob(str);
        }
    },

    sanitizeTitle(title) {
        return title.toLowerCase()
            .replace(/[^a-z0-9]+/g, '-')
            .replace(/^-+|-+$/g, '')
            .substring(0, 100);
    },

    escapeHtml(text) {
        const div = document.createElement('div');
        div.textContent = text;
        return div.innerHTML;
    },

    escapeAttr(text) {
        return String(text)
            .replace(/&/g, '&amp;')
            .replace(/"/g, '&quot;')
            .replace(/'/g, '&#39;')
            .replace(/</g, '&lt;')
            .replace(/>/g, '&gt;');
    },

    validateTitle(title) {
        if (!title || title.trim().length === 0) return 'Title is required';
        if (title.length > 100) return 'Title must be less than 100 characters';
        const sanitized = this.sanitizeTitle(title);
        if (sanitized.includes('..') || sanitized.includes('/') || sanitized.includes('\\')) {
            return 'Invalid title characters';
        }
        const reserved = ['con', 'prn', 'aux', 'nul'];
        if (reserved.includes(sanitized.toLowerCase())) return 'Invalid title';
        return null;
    },

    validateCode(code) {
        if (!code || code.trim().length === 0) return 'Code is required';
        if (code.length > 100000) return 'Code is too large (max 100KB)';
        return null;
    },

    isExpired(data) {
        if (!data || !data.expiration) return false;
        const exp = new Date(data.expiration);
        if (isNaN(exp.getTime())) return false;
        return exp.getTime() <= Date.now();
    },

    toDateTimeLocal(isoString) {
        const date = new Date(isoString);
        if (isNaN(date.getTime())) return '';
        const offset = date.getTimezoneOffset() * 60000;
        return new Date(date.getTime() - offset).toISOString().slice(0, 16);
    },
    
    formatDisplayTime(isoString, timezone) {
        const date = new Date(isoString);
        if (isNaN(date.getTime())) return 'Invalid date';
        try {
            return date.toLocaleString('en-US', {
                timeZone: timezone || undefined,
                weekday: 'short',
                year: 'numeric',
                month: 'short',
                day: 'numeric',
                hour: '2-digit',
                minute: '2-digit',
                timeZoneName: 'short'
            });
        } catch(e) {
            return date.toLocaleString();
        }
    }
};

const app = {
    db: null,
    dbSha: null,
    token: null,
    currentUser: null,
    currentFilter: 'all',
    actionInProgress: false,
    currentEditingId: null,
    originalTitle: null,
    originalScriptId: null,
    currentBotId: null,
    isLoading: false,
    searchQuery: '',
    sortMode: 'created',
    pendingEditorCode: null,
    suggestionIndex: -1,
    suggestionItems: null,
    fuse: null,
    fuseItems: null,
    scheduledTimers: {},
    
    async init() {
        try {
            const savedSort = localStorage.getItem('script_sort');
            if (savedSort) this.sortMode = savedSort;
        } catch(e) {}
        const sessionValid = await this.loadSession();
        await this.loadDatabase();
        this.handleRouting();
        window.addEventListener('hashchange', () => this.handleRouting());
        
        this.debouncedRender = utils.debounce(() => this.renderList(), 300);
        this.debouncedUpdateSuggestions = utils.debounce(() => this.updateSuggestions(), 150);
        this.initEventListeners();
        
        window.addEventListener('keydown', (e) => {
            if (e.key === 'Escape') {
                const modal = document.getElementById('login-modal');
                if (modal && modal.style.display === 'flex') this.toggleLoginModal();
            }
            if ((e.ctrlKey || e.metaKey) && e.key === 's') {
                e.preventDefault();
                if (location.hash === '#admin') {
                    const activeTab = document.querySelector('.tab-btn.active');
                    if (!activeTab) return;
                    const activeTabName = activeTab.textContent.toLowerCase();
                    if (activeTabName.includes('add new')) {
                        this.saveScript();
                    } else if (activeTabName.includes('bots') || activeTabName.includes('create bot')) {
                        this.saveBot();
                    }
                }
            }
        });

        this.startSessionRefresh();
        this.startBotScheduler();

        if (typeof lucide !== 'undefined') {
            try {
                lucide.createIcons();
            } catch (e) {
                console.error('Lucide icons error:', e);
            }
        }
    },

    startSessionRefresh() {
        setInterval(() => {
            if (this.token && this.currentUser) {
                const expiry = localStorage.getItem('gh_token_expiry');
                if (expiry && Date.now() >= parseInt(expiry)) {
                    this.logout(true);
                }
            }
        }, 60000);
    },
    
    startBotScheduler() {
        setTimeout(() => this.checkScheduledBots(), 1000);
        setInterval(() => this.checkScheduledBots(), 30000);
    },
    
    initEventListeners() {
        const searchInput = document.getElementById('search');
        if (searchInput) {
            searchInput.addEventListener('input', (e) => {
                this.searchQuery = e.target.value;
                this.debouncedRender();
                this.debouncedUpdateSuggestions();
            });
            searchInput.addEventListener('focus', () => this.updateSuggestions());
            searchInput.addEventListener('keydown', (e) => this.handleSearchKeys(e));
            searchInput.addEventListener('blur', () => {
                setTimeout(() => this.hideSuggestions(), 150);
            });
        }
    },

    updateSuggestions() {
        const box = document.getElementById('search-suggestions');
        const input = document.getElementById('search');
        if (!box || !input || !this.db) return;
        const q = this.searchQuery.trim().toLowerCase();
        if (!q || document.activeElement !== input) {
            this.hideSuggestions();
            return;
        }
        
        const scripts = Object.entries(this.db.scripts || {})
            .map(([title, data]) => ({ title, ...data }))
            .filter(s => {
                if (utils.isExpired(s)) return false;
                if (s.visibility === 'PRIVATE' && !this.currentUser) return false;
                if (s.visibility === 'UNLISTED' && !this.currentUser) return false;
                return true;
            });
        
        let matches;
        if (this.fuse) {
            matches = this.fuse.search(q).map(r => r.item).slice(0, 8);
        } else {
            matches = scripts
                .filter(s => s.title.toLowerCase().includes(q))
                .slice(0, 8);
        }
        
        if (matches.length === 0) {
            this.hideSuggestions();
            return;
        }
        
        box.innerHTML = '';
        this.suggestionIndex = -1;
        this.suggestionItems = [];
        
        const showAll = document.createElement('div');
        showAll.className = 'suggestion-item suggestion-showall';
        showAll.textContent = `Search all for "${this.searchQuery.trim()}"`;
        showAll.setAttribute('data-title', '');
        showAll.onmousedown = (e) => { e.preventDefault(); this.applySearchSuggestion(null); };
        box.appendChild(showAll);
        this.suggestionItems.push(showAll);
        
        matches.forEach(s => {
            const item = document.createElement('div');
            item.className = 'suggestion-item';
            const idx = s.title.toLowerCase().indexOf(q);
            const before = utils.escapeHtml(idx >= 0 ? s.title.slice(0, idx) : s.title);
            const match = idx >= 0 ? utils.escapeHtml(s.title.slice(idx, idx + q.length)) : '';
            const after = idx >= 0 ? utils.escapeHtml(s.title.slice(idx + q.length)) : '';
            item.innerHTML = `<span class="suggestion-title">${before}<b>${match}</b>${after}</span>` +
                (s.visibility !== 'PUBLIC' ? `<span class="badge badge-sm badge-${s.visibility.toLowerCase()}">${s.visibility}</span>` : '');
            item.setAttribute('data-title', utils.escapeAttr(s.title));
            item.onmousedown = (e) => { e.preventDefault(); this.applySearchSuggestion(s.title); };
            box.appendChild(item);
            this.suggestionItems.push(item);
        });
        
        box.style.display = 'block';
    },

    applySearchSuggestion(title) {
        const input = document.getElementById('search');
        if (input && title) {
            input.value = title;
            this.searchQuery = title;
        }
        this.hideSuggestions();
        this.renderList();
    },

    hideSuggestions() {
        const box = document.getElementById('search-suggestions');
        if (box) {
            box.style.display = 'none';
            box.innerHTML = '';
        }
        this.suggestionIndex = -1;
        this.suggestionItems = null;
    },

    highlightSuggestion() {
        if (!this.suggestionItems) return;
        this.suggestionItems.forEach((item, i) => {
            item.classList.toggle('active', i === this.suggestionIndex);
        });
    },

    handleSearchKeys(e) {
        const box = document.getElementById('search-suggestions');
        if (!box || box.style.display === 'none' || !this.suggestionItems || this.suggestionItems.length === 0) return;
        const count = this.suggestionItems.length;
        
        if (e.key === 'ArrowDown') {
            e.preventDefault();
            this.suggestionIndex = (this.suggestionIndex + 1) % count;
            this.highlightSuggestion();
        } else if (e.key === 'ArrowUp') {
            e.preventDefault();
            this.suggestionIndex = (this.suggestionIndex - 1 + count) % count;
            this.highlightSuggestion();
        } else if (e.key === 'Enter') {
            e.preventDefault();
            const el = this.suggestionItems[this.suggestionIndex];
            this.applySearchSuggestion(el ? el.getAttribute('data-title') : null);
        } else if (e.key === 'Escape') {
            this.hideSuggestions();
            e.target.blur();
        }
    },
    
    initCodeMirror() {
        if (window.cmEditor) return;
        const textarea = document.getElementById('edit-code');
        if (textarea && typeof CodeMirror !== 'undefined') {
            window.cmEditor = CodeMirror.fromTextArea(textarea, {
                mode: 'lua',
                theme: 'monokai',
                lineNumbers: true,
                lineWrapping: true,
                matchBrackets: true,
                indentUnit: 4
            });
            if (this.pendingEditorCode != null) {
                window.cmEditor.setValue(this.pendingEditorCode);
                this.pendingEditorCode = null;
            }
        }
    },

    setEditorCode(code) {
        if (window.cmEditor) {
            window.cmEditor.setValue(code);
        } else {
            this.pendingEditorCode = code;
        }
    },

    async loadScriptContent(s) {
        const path = `scripts/${utils.sanitizeTitle(s.title)}/raw/${s.filename}`;
        const url = `https://api.github.com/repos/${CONFIG.user}/${CONFIG.repo}/contents/${path}`;
        let status = null;
        
        const attempt = async (useAuth) => {
            const headers = {};
            if (useAuth && this.token) headers['Authorization'] = `token ${this.token}`;
            const res = await fetch(url, { headers });
            status = res.status;
            if (!res.ok) return { ok: false };
            const file = await res.json();
            return { ok: true, code: utils.safeAtob(file.content) };
        };
        
        try {
            const r = await attempt(true);
            if (r.ok) return r;
        } catch (err) {}
        try {
            const r = await attempt(false);
            if (r.ok) return r;
        } catch (err) {}
        
        return { ok: false, status };
    },

    describeLoadError(status, s) {
        if (status === 404) return `-- File not found (${s.filename ? s.filename : s.title})`;
        if (status === 401) return '-- Invalid auth token — please log in again';
        if (status === 403 || status === 429) return '-- GitHub rate limit reached — try again in a minute';
        return '-- Could not fetch script content from GitHub';
    },

    async loadSession() {
        try {
            const storedToken = localStorage.getItem('gh_token');
            const storedUser = localStorage.getItem('gh_user');
            const tokenExpiry = localStorage.getItem('gh_token_expiry');
            
            if (storedToken && storedUser && tokenExpiry) {
                const now = Date.now();
                if (now < parseInt(tokenExpiry)) {
                    this.token = storedToken;
                    this.currentUser = JSON.parse(storedUser);
                    
                    if (this.currentUser.login.toLowerCase() !== CONFIG.user.toLowerCase()) {
                        this.logout(true);
                        return false;
                    }
                    
                    this.updateUIForLoggedInUser();
                    return true;
                } else {
                    this.logout(true);
                }
            }
        } catch(e) {
            console.error('Session load error:', e);
        }
        return false;
    },

    updateUIForLoggedInUser() {
        document.getElementById('auth-section').style.display = 'none';
        document.getElementById('user-section').style.display = 'flex';
        const privateFilter = document.getElementById('private-filter');
        const unlistedFilter = document.getElementById('unlisted-filter');
        if (privateFilter) privateFilter.style.display = 'flex';
        if (unlistedFilter) unlistedFilter.style.display = 'flex';
        this.positionSortSelect();
    },

    saveSession() {
        if (this.token && this.currentUser) {
            try {
                const expiry = Date.now() + (30 * 24 * 60 * 60 * 1000);
                localStorage.setItem('gh_token', this.token);
                localStorage.setItem('gh_user', JSON.stringify(this.currentUser));
                localStorage.setItem('gh_token_expiry', expiry.toString());
            } catch(e) {
                console.error('Session save error:', e);
                this.showToast('Failed to save session', 'error');
            }
        }
    },

    toggleLoginModal() {
        const modal = document.getElementById('login-modal');
        modal.style.display = modal.style.display === 'flex' ? 'none' : 'flex';
        document.getElementById('login-error').style.display = 'none';
        if (modal.style.display === 'flex') {
            document.getElementById('auth-token').focus();
        }
    },

    async login() {
        if (this.actionInProgress) return;
        this.actionInProgress = true;
        
        try {
            const token = document.getElementById('auth-token').value.trim();
            if (!token) {
                this.showLoginError('Token is required');
                return;
            }
            
            this.token = token;
            const success = await this.verifyToken(false);
            if (success) {
                this.saveSession();
                this.toggleLoginModal();
                document.getElementById('auth-token').value = '';
                await this.loadDatabase();
                this.showToast('Logged in successfully!', 'success');
            }
        } finally {
            this.actionInProgress = false;
        }
    },

    showLoginError(message) {
        const err = document.getElementById('login-error');
        err.textContent = message;
        err.style.display = 'block';
        this.actionInProgress = false;
    },
    
    showToast(message, type = 'success') {
        if (typeof Toastify !== 'undefined') {
            Toastify({
                text: message,
                duration: 3000,
                gravity: "top",
                position: "right",
                style: { background: type === 'success' ? "#eab308" : type === 'error' ? "#ef4444" : "#6366f1" },
                stopOnFocus: true
            }).showToast();
        } else {
            alert(message);
        }
    },

    logout(silent = false) {
        if (!silent && !confirm('Are you sure you want to logout?')) {
            return;
        }
        
        try {
            localStorage.removeItem('gh_token');
            localStorage.removeItem('gh_user');
            localStorage.removeItem('gh_token_expiry');
        } catch(e) {}
        
        this.token = null;
        this.currentUser = null;
        this.db = null;
        this.dbSha = null;
        this.fuse = null;
        this.fuseItems = null;
        
        Object.values(this.scheduledTimers).forEach(timer => clearTimeout(timer));
        this.scheduledTimers = {};
        
        document.getElementById('auth-section').style.display = 'block';
        document.getElementById('user-section').style.display = 'none';
        const privateFilter = document.getElementById('private-filter');
        const unlistedFilter = document.getElementById('unlisted-filter');
        if (privateFilter) privateFilter.style.display = 'none';
        if (unlistedFilter) unlistedFilter.style.display = 'none';
        this.positionSortSelect();
        
        location.href = '#';
        
        if (!silent) {
            this.showToast('Logged out successfully', 'success');
            setTimeout(() => location.reload(), 1000);
        }
    },

    async verifyToken(silent) {
        try {
            const res = await fetch('https://api.github.com/user', {
                headers: { 'Authorization': `token ${this.token}` }
            });
            
            if (!res.ok) throw new Error('Invalid token');
            
            const user = await res.json();
            if (user.login.toLowerCase() !== CONFIG.user.toLowerCase()) {
                throw new Error(`Token belongs to ${user.login}, not ${CONFIG.user}.`);
            }
            
            this.currentUser = user;
            this.updateUIForLoggedInUser();
            return true;
        } catch (e) {
            if (!silent) this.showLoginError(e.message);
            this.token = null;
            try {
                localStorage.removeItem('gh_token');
                localStorage.removeItem('gh_user');
                localStorage.removeItem('gh_token_expiry');
            } catch(err) {}
            return false;
        }
    },

    async loadDatabase() {
        try {
            this.isLoading = true;
            const list = document.getElementById('admin-list');
            if (this.currentUser && list) {
                list.innerHTML = `<div style="text-align:center;padding:20px"><div class="spinner"></div><p>Loading...</p></div>`;
            }
            
            let content;
            if (this.token) {
                const url = `https://api.github.com/repos/${CONFIG.user}/${CONFIG.repo}/contents/database.json?t=${CONFIG.cacheBuster()}`;
                const res = await fetch(url, { headers: { 'Authorization': `token ${this.token}` } });
                
                if (res.status === 404) {
                    this.db = { scripts: {}, bots: {} };
                    this.dbSha = null;
                    this.buildSearchIndex();
                    this.renderList();
                    if (list) list.innerHTML = `<div class="empty-admin-state"><p>No scripts yet</p></div>`;
                    return;
                }
                
                if (!res.ok) throw new Error(`Failed to load database: ${res.status}`);
                
                const file = await res.json();
                this.dbSha = file.sha;
                content = utils.safeAtob(file.content);
            } else {
                const res = await fetch(`database.json?t=${CONFIG.cacheBuster()}`, { cache: 'no-store' });
                if (!res.ok) throw new Error(`Failed to load database: ${res.status}`);
                this.dbSha = null;
                content = await res.text();
            }
            
            try {
                this.db = JSON.parse(content);
                if (!this.db.scripts) this.db.scripts = {};
                if (!this.db.bots) this.db.bots = {};

                Object.keys(this.scheduledTimers).forEach(id => clearTimeout(this.scheduledTimers[id]));
                this.scheduledTimers = {};

                Object.entries(this.db.bots).forEach(([botId, bot]) => {
                    if (bot.scheduled && bot.scheduledTime && !bot.sent && !bot.cancelled) {
                        this.scheduleBotTimer(botId, bot);
                    }
                });
                
            } catch(parseError) {
                console.error('Database parse error:', parseError);
                this.db = { scripts: {}, bots: {} };
            }
            
            this.buildSearchIndex();
            this.renderList();
            this.renderAdminList();
            
        } catch (e) {
            console.error("DB Error", e);
            const list = document.getElementById('admin-list');
            if (list) {
                list.innerHTML = `<div class="empty-admin-state">
                    <p style="color:var(--color-danger)">Error: ${e.message}</p>
                    <button class="btn btn-sm" onclick="app.loadDatabase()" style="margin-top:10px">Retry</button>
                </div>`;
            }
            this.showToast(`Error: ${e.message}`, 'error');
        } finally {
            this.isLoading = false;
        }
    },

    scheduleBotTimer(botId, bot) {
        if (this.scheduledTimers[botId]) {
            clearTimeout(this.scheduledTimers[botId]);
            delete this.scheduledTimers[botId];
        }

        if (bot.sent || bot.cancelled || bot.isProcessing || !bot.scheduled) return;

        const scheduledDate = new Date(bot.scheduledTime);
        const delay = scheduledDate.getTime() - Date.now();

        if (isNaN(delay)) return;

        if (delay <= 0) {
            if (delay > -300000) this.triggerScheduledBot(botId);
            return;
        }

        const MAX_BROWSER_DELAY = 2147483647;
        if (delay > MAX_BROWSER_DELAY) return;

        this.scheduledTimers[botId] = setTimeout(() => {
            this.triggerScheduledBot(botId);
            delete this.scheduledTimers[botId];
        }, delay);
    },

    async dispatchBotWorkflow(botId) {
        return fetch(
            `https://api.github.com/repos/${CONFIG.user}/${CONFIG.repo}/actions/workflows/discord-bot.yml/dispatches`,
            {
                method: 'POST',
                headers: {
                    'Authorization': `token ${this.token}`,
                    'Accept': 'application/vnd.github.v3+json',
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({
                    ref: CONFIG.branch,
                    inputs: { botId: botId }
                })
            }
        );
    },

    async triggerScheduledBot(botId) {
        try {
            const bot = this.db.bots[botId];
            if (!bot || bot.sent || bot.cancelled || bot.isProcessing) return;

            bot.isProcessing = true;

            const workflowResponse = await this.dispatchBotWorkflow(botId);

            if (workflowResponse.status === 204) {
                bot.status = 'processing';
                bot.lastTriggered = new Date().toISOString();
                bot.isProcessing = false;
                setTimeout(() => this.loadDatabase(), 5000);
            } else {
                const errorText = await workflowResponse.text();
                bot.isProcessing = false;
                bot.lastError = `Workflow trigger failed: ${workflowResponse.status}`;
            }
        } catch (error) {
            if (this.db.bots[botId]) {
                this.db.bots[botId].isProcessing = false;
                this.db.bots[botId].lastError = error.message;
            }
        }
    },

    checkScheduledBots() {
        if (!this.currentUser || !this.db) return;
        const now = Date.now();
        Object.entries(this.db.bots || {}).forEach(([botId, bot]) => {
            if (bot.scheduled && bot.scheduledTime && !bot.sent && !bot.cancelled && !bot.isProcessing) {
                const scheduledTime = new Date(bot.scheduledTime).getTime();
                const timeDiff = scheduledTime - now;
                if (timeDiff > 0 && timeDiff <= 300000) {
                    if (!this.scheduledTimers[botId]) this.scheduleBotTimer(botId, bot);
                } else if (timeDiff <= 0 && timeDiff > -300000 && !this.scheduledTimers[botId]) {
                    this.triggerScheduledBot(botId);
                }
            }
        });
    },

    async sendBotNow(botId) {
        if (!this.currentUser || !this.db || !this.db.bots[botId]) return false;
        const bot = this.db.bots[botId];
        if (bot.isProcessing || bot.sent) return false;

        bot.isProcessing = true;

        try {
            const workflowResponse = await this.dispatchBotWorkflow(botId);

            if (workflowResponse.status === 204) {
                bot.status = 'processing';
                bot.isProcessing = false;
                
                const dbRes = await fetch(`https://api.github.com/repos/${CONFIG.user}/${CONFIG.repo}/contents/database.json`, {
                    method: 'PUT',
                    headers: { 
                        'Authorization': `token ${this.token}`,
                        'Content-Type': 'application/json'
                    },
                    body: JSON.stringify({
                        message: `Trigger bot: ${bot.title}`,
                        content: utils.safeBtoa(JSON.stringify(this.db, null, 2)),
                        sha: this.dbSha
                    })
                });

                if (dbRes.ok) {
                    const newDbData = await dbRes.json();
                    this.dbSha = newDbData.content.sha;
                    this.showToast('Triggered! Checking GitHub...', 'success');
                    return true;
                }
            } else {
                throw new Error(`GitHub Error: ${workflowResponse.status}`);
            }
            return false;
        } catch (error) {
            bot.isProcessing = false;
            this.showToast(`Error: ${error.message}`, 'error');
            return false;
        }
    },

    async saveBot() {
        const titleInput = document.getElementById('bot-title');
        const messageInput = document.getElementById('bot-message');
        const scheduleInput = document.getElementById('bot-schedule');
        const scheduleTimeInput = document.getElementById('bot-schedule-time');
        const timezoneInput = document.getElementById('bot-timezone');
        const saveBtn = document.querySelector('.bot-actions .btn:last-child');
        
        if (!titleInput || !messageInput || !saveBtn) return;
        
        const title = titleInput.value.trim();
        const message = messageInput.value.trim();
        const schedule = scheduleInput ? scheduleInput.checked : false;
        const scheduleTime = scheduleTimeInput ? scheduleTimeInput.value : '';
        const timezone = timezoneInput ? timezoneInput.value : Intl.DateTimeFormat().resolvedOptions().timeZone;
        
        if (!title || !message) {
            this.showToast('Title and message are required', 'error');
            return;
        }
        
        if (schedule && !scheduleTime) {
            this.showToast('Please pick a scheduled time', 'error');
            return;
        }
        
        if (this.actionInProgress) return;
        this.actionInProgress = true;
        saveBtn.disabled = true;
        
        try {
            const botId = this.currentBotId || `bot_${Date.now()}`;
            const now = new Date().toISOString();
            let scheduledTimeUTC = null;

            if (schedule && scheduleTime) {
                const localDate = new Date(scheduleTime);
                if (localDate < new Date()) {
                    this.showToast('Time cannot be in the past', 'error');
                    this.actionInProgress = false;
                    saveBtn.disabled = false;
                    return;
                }
                scheduledTimeUTC = localDate.toISOString();
            }

            const botData = {
                id: botId,
                title: title,
                message: message,
                scheduled: schedule,
                scheduledTime: scheduledTimeUTC,
                timezone: timezone,
                created: now,
                sent: false,
                status: schedule ? 'scheduled' : 'pending',
                sentTime: null,
                cancelled: false,
                isProcessing: false
            };

            this.db.bots[botId] = botData;

            const dbRes = await fetch(`https://api.github.com/repos/${CONFIG.user}/${CONFIG.repo}/contents/database.json`, {
                method: 'PUT',
                headers: { 
                    'Authorization': `token ${this.token}`,
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({
                    message: `Update bot: ${title}`,
                    content: utils.safeBtoa(JSON.stringify(this.db, null, 2)),
                    sha: this.dbSha
                })
            });

            if (!dbRes.ok) throw new Error('Database update failed');

            const newDbData = await dbRes.json();
            this.dbSha = newDbData.content.sha;

            if (schedule) {
                this.showToast(`Scheduled successfully`, 'success');
                await this.loadDatabase();
            } else {
                await this.sendBotNow(botId);
            }

        } catch(e) {
            this.showToast(`Error: ${e.message}`, 'error');
        } finally {
            saveBtn.disabled = false;
            this.actionInProgress = false;
        }
    },

    renderList() {
        const list = document.getElementById('script-list');
        if (!list || !this.db) return;
        
        const scripts = Object.entries(this.db.scripts || {}).map(([title, data]) => ({ title, ...data }));
        const filtered = this.filterLogic(scripts);
        const sorted = this.sortLogic(filtered);
        
        const sortSelect = document.getElementById('sort-select');
        if (sortSelect) sortSelect.value = this.sortMode;
        
        if (sorted.length === 0) {
            list.innerHTML = `<div class="empty-state">
                <h2>No scripts found</h2>
                <p>Try adjusting your search or filter</p>
            </div>`;
            return;
        }
        
        list.innerHTML = sorted.map(s => {
            const scriptId = utils.sanitizeTitle(s.title);
            const date = s.updated && s.updated !== s.created
                ? new Date(s.updated).toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' })
                : new Date(s.created).toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' });
            return `<div class="script-card" onclick="window.location.href='scripts/${scriptId}/'">
                <div class="card-content">
                    <div class="card-header-section">
                        <h3 class="script-title">${utils.escapeHtml(s.title)}</h3>
                        ${s.visibility !== 'PUBLIC' ? `<span class="badge badge-${s.visibility.toLowerCase()}">${s.visibility}</span>` : ''}
                    </div>
                    ${s.description ? `<p class="card-description">${utils.escapeHtml(s.description.substring(0, 120))}${s.description.length > 120 ? '...' : ''}</p>` : ''}
                    <div class="card-meta">
                        <span>${date}</span>
                    </div>
                </div>
            </div>`;
        }).join('');
    },

    buildSearchIndex() {
        try {
            if (typeof Fuse !== 'undefined' && this.db) {
                const items = Object.entries(this.db.scripts || {}).map(([title, data]) => ({ title, ...data }));
                this.fuseItems = items;
                this.fuse = new Fuse(items, {
                    keys: [
                        { name: 'title', weight: 0.7 },
                        { name: 'description', weight: 0.3 }
                    ],
                    threshold: 0.4,
                    ignoreLocation: true,
                    minMatchCharLength: 2
                });
            } else {
                this.fuse = null;
                this.fuseItems = null;
            }
        } catch (e) {
            console.error('Fuse init error:', e);
            this.fuse = null;
            this.fuseItems = null;
        }
    },

    searchScripts(query) {
        if (!this.fuse) return null;
        const q = query.trim().toLowerCase();
        if (!q) return null;
        try {
            return new Set(this.fuse.search(q).map(r => r.item.title));
        } catch (e) {
            return null;
        }
    },

    filterLogic(scripts) {
        const query = this.searchQuery.trim().toLowerCase();
        const fuzzyMatch = this.searchScripts(query);
        return scripts.filter(s => {
            if (utils.isExpired(s)) return false;
            if (fuzzyMatch && !fuzzyMatch.has(s.title)) return false;
            if (query && !fuzzyMatch && !s.title.toLowerCase().includes(query)) return false;
            if (s.visibility === 'PRIVATE' && !this.currentUser) return false;
            if (s.visibility === 'UNLISTED' && !this.currentUser) return false;
            if (this.currentFilter === 'private' && s.visibility !== 'PRIVATE') return false;
            if (this.currentFilter === 'public' && s.visibility !== 'PUBLIC') return false;
            if (this.currentFilter === 'unlisted' && s.visibility !== 'UNLISTED') return false;
            return true;
        });
    },

    positionSortSelect() {
        const select = document.getElementById('sort-select');
        if (!select) return;
        const anchor = this.currentUser
            ? document.getElementById('unlisted-filter')
            : document.querySelector('.sidebar-link[data-filter="public"]');
        if (!anchor) return;
        const parent = anchor.parentNode;
        if (select.previousElementSibling !== anchor) {
            parent.insertBefore(select, anchor.nextSibling);
        }
    },

    sortLogic(scripts) {
        const mode = this.sortMode || 'created';
        const copy = [...scripts];
        switch (mode) {
            case 'updated':
                return copy.sort((a, b) => new Date(b.updated || b.created || 0) - new Date(a.updated || a.created || 0));
            case 'az':
                return copy.sort((a, b) => a.title.localeCompare(b.title, undefined, { sensitivity: 'base' }));
            case 'za':
                return copy.sort((a, b) => b.title.localeCompare(a.title, undefined, { sensitivity: 'base' }));
            default:
                return copy.sort((a, b) => new Date(b.created || 0) - new Date(a.created || 0));
        }
    },

    setSort(mode) {
        this.sortMode = mode;
        try { localStorage.setItem('script_sort', mode); } catch(e) {}
        this.renderList();
    },

    filterCategory(cat, e) {
        if (e) {
            e.preventDefault();
            document.querySelectorAll('.sidebar-link').forEach(l => l.classList.remove('active'));
            if (e.currentTarget.classList.contains('sidebar-link')) e.currentTarget.classList.add('active');
        }
        this.currentFilter = cat;
        this.renderList();
    },

    switchAdminTab(tab) {
        if (tab === 'admin' && !this.currentUser) {
            location.hash = '';
            return;
        }
        
        document.querySelectorAll('.admin-tab').forEach(t => t.style.display = 'none');
        document.querySelectorAll('.tab-btn').forEach(b => b.classList.remove('active'));
        
        if (tab === 'list') {
            document.getElementById('admin-tab-list').style.display = 'block';
            document.querySelectorAll('.tab-btn')[0].classList.add('active');
            this.renderAdminList();
        } else if (tab === 'bots') {
            document.getElementById('admin-tab-bots').style.display = 'block';
            document.querySelectorAll('.tab-btn')[2].classList.add('active');
            this.renderBotsList();
        } else if (tab === 'create-bot') {
            document.getElementById('admin-tab-bot-editor').style.display = 'block';
            document.querySelectorAll('.tab-btn')[2].classList.add('active');
            this.resetBotEditor();
        } else {
            document.getElementById('admin-tab-editor').style.display = 'block';
            document.querySelectorAll('.tab-btn')[1].classList.add('active');
            if (tab === 'create') {
                this.resetEditor();
            }
            this.initCodeMirror();
            setTimeout(() => {
                if (window.cmEditor) window.cmEditor.refresh();
            }, 50);
        }
    },

    async renderAdminList() {
        if (!this.currentUser || !this.db) return;
        const list = document.getElementById('admin-list');
        const scripts = Object.entries(this.db.scripts || {}).map(([title, data]) => ({ title, ...data }));
        const sorted = scripts.sort((a, b) => new Date(b.updated || b.created || 0) - new Date(a.updated || a.created || 0));
        const botsCount = Object.keys(this.db.bots || {}).length;
        document.getElementById('total-stats').textContent = `${scripts.length} Scripts, ${botsCount} Bots`;
        if (sorted.length === 0) {
            list.innerHTML = `<div class="empty-admin-state"><p>No scripts yet. Click "Add New" to create your first script.</p></div>`;
            return;
        }
        list.innerHTML = sorted.map(s => {
            const updated = s.updated ? new Date(s.updated).toLocaleDateString() : new Date(s.created).toLocaleDateString();
            const expired = utils.isExpired(s);
            const expDate = expired ? `Expired ${new Date(s.expiration).toLocaleDateString()}` : `Updated ${updated}`;
            return `<div class="admin-item" data-script-title="${utils.escapeAttr(s.title)}" onclick="app.populateEditor(this.getAttribute('data-script-title'))">
                <div class="admin-item-left">
                    <strong>${utils.escapeHtml(s.title)}</strong>
                    <div class="admin-meta">
                        <span class="badge badge-sm ${expired ? 'badge-expired' : 'badge-' + s.visibility.toLowerCase()}">${expired ? 'Expired' : s.visibility}</span>
                        <span class="text-muted">${expDate}</span>
                    </div>
                </div>
                <div class="admin-item-right">
                    <button class="item-delete" onclick="event.stopPropagation(); app.deleteScriptConfirmation(this.closest('.admin-item').getAttribute('data-script-title'))" title="Delete script" aria-label="Delete script">
                        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M3 6h18M19 6v14a2 2 0 01-2 2H7a2 2 0 01-2-2V6m3 0V4a2 2 0 012-2h4a2 2 0 012 2v2"></path></svg>
                    </button>
                    <svg class="item-chevron" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M9 18l6-6-6-6"/></svg>
                </div>
            </div>`;
        }).join('');
        this.initSwipeToDelete();
    },

    renderBotsList() {
        if (!this.currentUser || !this.db) return;
        const list = document.getElementById('bots-list');
        const bots = Object.entries(this.db.bots || {}).map(([id, data]) => ({ id, ...data }));
        const sorted = bots.sort((a, b) => new Date(b.created || 0) - new Date(a.created || 0));
        
        if (sorted.length === 0) {
            list.innerHTML = `<div class="empty-admin-state"><p>No bots yet. Click "Create Bot" to add one.</p></div>`;
            return;
        }
        
        list.innerHTML = sorted.map(b => {
            let status = 'Pending', statusClass = 'status-pending', timeInfo = 'Pending';
            if (b.cancelled) { status = 'Cancelled'; statusClass = 'status-cancelled'; } 
            else if (b.sent) { status = 'Sent'; statusClass = 'status-sent'; timeInfo = `Sent: ${new Date(b.sentTime).toLocaleString()}`; } 
            else if (b.scheduled) { status = 'Scheduled'; statusClass = 'status-scheduled'; timeInfo = `Scheduled: ${utils.formatDisplayTime(b.scheduledTime, b.timezone)}`; }
            
            return `<div class="admin-item" data-bot-id="${b.id}" onclick="app.populateBotEditor('${b.id}')">
                <div class="admin-item-left">
                    <strong>${utils.escapeHtml(b.title)}</strong>
                    <div class="admin-meta">
                        <span class="bot-status ${statusClass}">${status}</span>
                        <span class="text-muted">${timeInfo}</span>
                    </div>
                </div>
                <div class="admin-item-right">
                    <button class="item-delete" onclick="event.stopPropagation(); app.deleteBotConfirmation(this.closest('.admin-item').getAttribute('data-bot-id'))" title="Cancel bot" aria-label="Cancel bot">
                        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M3 6h18M19 6v14a2 2 0 01-2 2H7a2 2 0 01-2-2V6m3 0V4a2 2 0 012-2h4a2 2 0 012 2v2"></path></svg>
                    </button>
                    <svg class="item-chevron" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M9 18l6-6-6-6"/></svg>
                </div>
            </div>`;
        }).join('');
        this.initSwipeToDelete();
    },

    initSwipeToDelete() {
        const adminItems = document.querySelectorAll('.admin-item');
        const SWIPE_THRESHOLD = 8;
        const DELETE_THRESHOLD = 100;

        adminItems.forEach(item => {
            let startX = null, isSwiping = false, dragging = false, suppressClick = false;

            item.addEventListener('pointerdown', (e) => {
                if (e.pointerType === 'mouse' && e.button !== 0) return;
                if (e.target.closest('.item-delete')) return;
                startX = e.clientX;
                isSwiping = false;
                dragging = true;
                item.style.transition = 'none';
                item.classList.add('swiping');
                try { item.setPointerCapture(e.pointerId); } catch(err) {}
            });

            item.addEventListener('pointermove', (e) => {
                if (!dragging || startX === null) return;
                const diff = e.clientX - startX;
                if (Math.abs(diff) > SWIPE_THRESHOLD) {
                    isSwiping = true;
                    if (diff > 0) {
                        item.style.transform = `translateX(${Math.min(diff, 100)}px)`;
                        item.style.backgroundColor = 'rgba(239, 68, 68, 0.1)';
                    }
                }
            });

            item.addEventListener('pointerup', (e) => {
                if (!dragging) return;
                dragging = false;
                item.classList.remove('swiping');

                const diff = e.clientX - startX;
                startX = null;

                if (isSwiping) {
                    suppressClick = true;
                    item.style.transition = 'transform 0.3s ease, background-color 0.3s ease, opacity 0.3s ease';
                    if (diff > DELETE_THRESHOLD) {
                        item.style.transform = 'translateX(300px)';
                        item.style.opacity = '0';
                        item.classList.add('swipe-delete');
                        setTimeout(() => {
                            const scriptTitle = item.getAttribute('data-script-title');
                            const botId = item.getAttribute('data-bot-id');
                            if (scriptTitle) this.deleteScriptConfirmation(scriptTitle);
                            else if (botId) this.deleteBotConfirmation(botId);
                        }, 300);
                    } else {
                        item.style.transform = '';
                        item.style.backgroundColor = '';
                    }
                    e.preventDefault();
                } else {
                    item.style.transition = '';
                    item.style.transform = '';
                    item.style.backgroundColor = '';
                }
                isSwiping = false;
            });

            item.addEventListener('pointercancel', () => {
                dragging = false;
                isSwiping = false;
                startX = null;
                item.style.transition = '';
                item.style.transform = '';
                item.style.backgroundColor = '';
                item.classList.remove('swiping');
            });

            item.addEventListener('click', (e) => {
                if (suppressClick) {
                    e.preventDefault();
                    e.stopPropagation();
                    suppressClick = false;
                }
            });
        });
    },

    async deleteScriptConfirmation(scriptTitle) {
        if (!scriptTitle || !this.db.scripts[scriptTitle]) {
            this.showToast('Script not found', 'error');
            await this.loadDatabase();
            return;
        }

        let shouldDelete = false;
        if (typeof Swal !== 'undefined') {
            const result = await Swal.fire({
                title: 'Delete Script',
                text: `Are you sure you want to delete "${scriptTitle}"?`,
                icon: 'warning',
                showCancelButton: true,
                confirmButtonText: 'Delete',
                cancelButtonText: 'Cancel',
                confirmButtonColor: '#ef4444'
            });
            shouldDelete = result.isConfirmed;
        } else {
            shouldDelete = confirm(`Delete "${scriptTitle}"?`);
        }

        if (shouldDelete) await this.deleteScriptLogic(scriptTitle);
        else await this.loadDatabase();
    },

    async deleteBotConfirmation(botId) {
        if (!botId || !this.db.bots[botId]) return;

        const bot = this.db.bots[botId];
        let shouldDelete = false;
        if (typeof Swal !== 'undefined') {
            const result = await Swal.fire({
                title: 'Cancel Bot',
                text: `Are you sure you want to cancel "${bot.title}"?`,
                icon: 'warning',
                showCancelButton: true,
                confirmButtonText: 'Cancel Bot',
                cancelButtonText: 'Keep',
                confirmButtonColor: '#ef4444'
            });
            shouldDelete = result.isConfirmed;
        } else {
            shouldDelete = confirm(`Cancel bot "${bot.title}"?`);
        }

        if (shouldDelete) await this.deleteBotLogic(botId);
        else await this.loadDatabase();
    },

    async deleteScriptLogic(scriptTitle) {
        if (this.actionInProgress) return;
        this.actionInProgress = true;
        
        try {
            const script = this.db.scripts[scriptTitle];
            if (!script) throw new Error('Script not found');
            
            const scriptId = utils.sanitizeTitle(scriptTitle);
            await this.deleteScriptFiles(scriptId, script.filename);
            
            delete this.db.scripts[scriptTitle];
            
            const dbRes = await fetch(`https://api.github.com/repos/${CONFIG.user}/${CONFIG.repo}/contents/database.json`, {
                method: 'PUT',
                headers: { 
                    'Authorization': `token ${this.token}`,
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({
                    message: `Remove ${scriptTitle}`,
                    content: utils.safeBtoa(JSON.stringify(this.db, null, 2)),
                    sha: this.dbSha
                })
            });
            
            if (dbRes.ok) {
                const newDbData = await dbRes.json();
                this.dbSha = newDbData.content.sha;
                this.showToast('Script deleted', 'success');
                await this.loadDatabase();
            } else {
                throw new Error('Failed to update database');
            }
            
        } catch(e) {
            console.error('Delete error:', e);
            this.showToast(`Error: ${e.message}`, 'error');
            await this.loadDatabase();
        } finally {
            this.actionInProgress = false;
        }
    },

    async deleteScriptFiles(scriptId, filename) {
        try {
            const filesToDelete = [
                `scripts/${scriptId}/index.html`,
                `scripts/${scriptId}/raw/${filename}`
            ];

            for (const path of filesToDelete) {
                const url = `https://api.github.com/repos/${CONFIG.user}/${CONFIG.repo}/contents/${path}`;
                const res = await fetch(url, { headers: { 'Authorization': `token ${this.token}` } });
                if (res.ok) {
                    const fileData = await res.json();
                    await fetch(url, {
                        method: 'DELETE',
                        headers: { 
                            'Authorization': `token ${this.token}`,
                            'Content-Type': 'application/json'
                        },
                        body: JSON.stringify({
                            message: `Delete script file: ${path}`,
                            sha: fileData.sha,
                            branch: CONFIG.branch
                        })
                    });
                }
            }
        } catch (e) {
            console.error('Error explicitly deleting script files:', e);
        }
    },

    async deleteBotLogic(botId) {
        if (this.actionInProgress) return;
        this.actionInProgress = true;
        
        try {
            if (this.scheduledTimers[botId]) {
                clearTimeout(this.scheduledTimers[botId]);
                delete this.scheduledTimers[botId];
            }
            
            if (this.db.bots[botId]) {
                this.db.bots[botId].cancelled = true;
                this.db.bots[botId].status = 'cancelled';
                
                const dbRes = await fetch(`https://api.github.com/repos/${CONFIG.user}/${CONFIG.repo}/contents/database.json`, {
                    method: 'PUT',
                    headers: { 
                        'Authorization': `token ${this.token}`,
                        'Content-Type': 'application/json'
                    },
                    body: JSON.stringify({
                        message: `Cancel bot: ${this.db.bots[botId].title}`,
                        content: utils.safeBtoa(JSON.stringify(this.db, null, 2)),
                        sha: this.dbSha
                    })
                });
                
                if (dbRes.ok) {
                    const newDbData = await dbRes.json();
                    this.dbSha = newDbData.content.sha;
                    this.showToast('Bot cancelled', 'success');
                    await this.loadDatabase();
                } else throw new Error('Failed to update database');
            }
        } catch(e) {
            this.showToast(`Error: ${e.message}`, 'error');
            await this.loadDatabase();
        } finally {
            this.actionInProgress = false;
        }
    },

    resetEditor() {
        document.getElementById('editor-heading').textContent = 'Create New Script';
        document.getElementById('edit-title').value = '';
        document.getElementById('edit-visibility').value = 'PUBLIC';
        
        const editDesc = document.getElementById('edit-desc');
        if (editDesc) editDesc.value = '';
        
        const editExpiration = document.getElementById('edit-expiration');
        if (editExpiration) editExpiration.value = '';
        
        if (window.cmEditor) window.cmEditor.setValue('');
        
        const saveBtn = document.querySelector('.editor-actions .btn:last-child');
        if (saveBtn) saveBtn.textContent = 'Publish';
        
        const deleteBtn = document.querySelector('.btn-delete');
        if (deleteBtn) deleteBtn.remove();
        
        const viewBtn = document.querySelector('.btn-view-script');
        if (viewBtn) viewBtn.remove();
        
        this.currentEditingId = null;
        this.originalTitle = null;
        this.originalScriptId = null;
        this.pendingEditorCode = null;
    },

    resetBotEditor() {
        document.getElementById('bot-editor-heading').textContent = 'Create New Bot';
        document.getElementById('bot-title').value = '';
        document.getElementById('bot-message').value = '';
        document.getElementById('bot-schedule').checked = false;
        document.getElementById('bot-schedule-time').value = '';
        document.getElementById('bot-timezone').value = Intl.DateTimeFormat().resolvedOptions().timeZone;
        const saveBtn = document.querySelector('.bot-actions .btn:last-child');
        if (saveBtn) saveBtn.textContent = 'Send Bot';
        this.currentBotId = null;
        this.toggleScheduleFields();
    },

    toggleScheduleFields() {
        const scheduleCheckbox = document.getElementById('bot-schedule');
        const scheduleFields = document.getElementById('schedule-fields');
        if (scheduleCheckbox && scheduleFields) {
            scheduleFields.style.display = scheduleCheckbox.checked ? 'block' : 'none';
            if (scheduleCheckbox.checked) {
                const localDateTime = new Date().toISOString().slice(0, 16);
                document.getElementById('bot-schedule-time').min = localDateTime;
            }
        }
    },

    async populateEditor(title) {
        if (!this.currentUser || !this.db || !this.db.scripts[title]) return;
        const s = this.db.scripts[title];
        
        this.currentEditingId = title;
        this.originalTitle = title;
        this.originalScriptId = utils.sanitizeTitle(title);
        
        this.switchAdminTab('create');
        
        document.getElementById('editor-heading').textContent = `Edit: ${title}`;
        document.getElementById('edit-title').value = s.displayTitle || s.title;
        document.getElementById('edit-visibility').value = s.visibility;
        
        const editDesc = document.getElementById('edit-desc');
        if (editDesc) editDesc.value = s.description || '';
        
        const editExpiration = document.getElementById('edit-expiration');
        if (editExpiration) editExpiration.value = utils.toDateTimeLocal(s.expiration);
        
        const result = await this.loadScriptContent(s);
        if (result.ok) {
            this.setEditorCode(result.code);
        } else {
            this.setEditorCode(this.describeLoadError(result.status, s));
        }
        
        const saveBtn = document.querySelector('.editor-actions .btn:last-child');
        if (saveBtn) saveBtn.textContent = 'Update Script';
        
        const actionButtons = document.querySelector('.action-buttons');
        let deleteBtn = document.querySelector('.btn-delete');
        if (!deleteBtn && actionButtons) {
            deleteBtn = document.createElement('button');
            deleteBtn.className = 'btn btn-delete';
            deleteBtn.innerHTML = `<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M3 6h18M19 6v14a2 2 0 01-2 2H7a2 2 0 01-2-2V6m3 0V4a2 2 0 012-2h4a2 2 0 012 2v2"></path></svg> Delete`;
            deleteBtn.onclick = () => this.deleteScriptConfirmation(title);
            actionButtons.appendChild(deleteBtn);
        }
    },

    async populateBotEditor(botId) {
        if (!this.currentUser || !this.db || !this.db.bots[botId]) return;
        const bot = this.db.bots[botId];
        
        if (bot.sent) {
            this.showToast('Cannot edit sent posts', 'error');
            this.switchAdminTab('bots');
            return;
        }
        
        this.currentBotId = botId;
        this.switchAdminTab('create-bot');
        
        document.getElementById('bot-editor-heading').textContent = `Edit Bot: ${bot.title}`;
        document.getElementById('bot-title').value = bot.title;
        document.getElementById('bot-message').value = bot.message;
        document.getElementById('bot-schedule').checked = bot.scheduled || false;
        
        if (bot.scheduledTime) {
            const localDateTime = new Date(bot.scheduledTime).toISOString().slice(0, 16);
            document.getElementById('bot-schedule-time').value = localDateTime;
        }
        
        document.getElementById('bot-timezone').value = bot.timezone || Intl.DateTimeFormat().resolvedOptions().timeZone;
        
        const saveBtn = document.querySelector('.bot-actions .btn:last-child');
        if (saveBtn) saveBtn.textContent = bot.scheduled ? 'Update Schedule' : 'Send Now';
        this.toggleScheduleFields();
    },

    async saveScript() {
        if (!this.currentUser || !this.db) {
            this.showToast('Please login first.', 'error');
            return;
        }
        
        if (this.actionInProgress) return;
        this.actionInProgress = true;
        
        const titleInput = document.getElementById('edit-title');
        const visibilityInput = document.getElementById('edit-visibility');
        const descInput = document.getElementById('edit-desc');
        const saveBtn = document.querySelector('.editor-actions .btn:last-child');
        
        if (!titleInput || !visibilityInput || !saveBtn) {
            this.showToast('Form elements not found', 'error');
            this.actionInProgress = false;
            return;
        }
        
        const title = titleInput.value.trim();
        const visibility = visibilityInput.value;
        const code = window.cmEditor ? window.cmEditor.getValue() : '';
        const desc = descInput ? descInput.value.trim() : '';
        const expirationInput = document.getElementById('edit-expiration');
        const expiration = expirationInput && expirationInput.value
            ? new Date(expirationInput.value).toISOString()
            : null;
        const originalBtnText = saveBtn.textContent;
        
        const titleError = utils.validateTitle(title);
        const codeError = utils.validateCode(code);
        
        if (titleError || codeError) {
            this.showToast(titleError || codeError, 'error');
            this.actionInProgress = false;
            return;
        }
        
        const isEditing = !!this.currentEditingId;
        const newScriptId = utils.sanitizeTitle(title);
        const filename = newScriptId + '.txt';
        
        saveBtn.disabled = true;
        saveBtn.textContent = isEditing ? 'Updating...' : 'Publishing...';
        
        try {
            let originalCreationDate = new Date().toISOString();
            if (isEditing && this.db.scripts[this.originalTitle]) {
                originalCreationDate = this.db.scripts[this.originalTitle].created;
            }
            
            const scriptData = {
                title: title,
                displayTitle: title,
                visibility: visibility,
                description: desc,
                expiration: expiration,
                filename: filename,
                size: code.length,
                created: originalCreationDate,
                updated: new Date().toISOString()
            };
            
            await this.createScriptFiles(newScriptId, filename, code, isEditing, this.originalScriptId, title);
            this.db.scripts[title] = scriptData;
            
            const dbRes = await fetch(`https://api.github.com/repos/${CONFIG.user}/${CONFIG.repo}/contents/database.json`, {
                method: 'PUT',
                headers: { 
                    'Authorization': `token ${this.token}`,
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({
                    message: `${isEditing ? 'Update' : 'Add'} ${title}`,
                    content: utils.safeBtoa(JSON.stringify(this.db, null, 2)),
                    sha: this.dbSha
                })
            });
            
            if (!dbRes.ok) throw new Error('Failed to update database');
            
            const newDbData = await dbRes.json();
            this.dbSha = newDbData.content.sha;
            
            this.showToast(`${isEditing ? 'Updated' : 'Published'} successfully!`, 'success');
            
            this.currentEditingId = title;
            this.originalTitle = title;
            this.originalScriptId = newScriptId;
            
            document.getElementById('editor-heading').textContent = `Edit: ${title}`;
            saveBtn.textContent = 'Update Script';
            await this.loadDatabase();
            
        } catch(e) {
            this.showToast(`Error: ${e.message}`, 'error');
        } finally {
            saveBtn.disabled = false;
            saveBtn.textContent = originalBtnText;
            this.actionInProgress = false;
        }
    },

    async createScriptFiles(scriptId, filename, code, isEditing, oldScriptId = null, displayTitle = null) {
        const scriptDir = `scripts/${scriptId}`;
        const rawDir = `${scriptDir}/raw`;
        const indexPath = `${scriptDir}/index.html`;
        const rawFilePath = `${rawDir}/${filename}`;
        
        const now = new Date();
        const formattedDate = now.toLocaleDateString('en-US', {
            month: '2-digit', day: '2-digit', year: 'numeric'
        });
        
        const escapedTitle = utils.escapeHtml(displayTitle || scriptId);
        
        const scriptViewerHTML = `<!DOCTYPE html>
<html lang="en">
<head>
    <script>
        if (window.location.pathname.endsWith('index.html')) {
            window.location.replace(window.location.pathname.replace(/index\.html$/, '') + window.location.search + window.location.hash);
        }
    </script>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>${escapedTitle} - Leaf's Scripts</title>
    <link rel="icon" type="image/png" href="https://yt3.googleusercontent.com/lxpJQz3QU7u-_NeTZVzQOphQHKW4Klu82r9ATc8bYCUrjd4FdOpS-nD0KF--YEXCfQEet5GV=s160-c-k-c0x00ffffff-no-rj">
    <link rel="stylesheet" href="../../style.css">
    <link href="https://cdnjs.cloudflare.com/ajax/libs/prism/1.29.0/themes/prism-tomorrow.min.css" rel="stylesheet" />
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
</head>
<body>
    <nav class="navbar">
        <div class="nav-content">
            <div class="nav-left">
                <a href="../../" class="brand" style="text-decoration: none; color: inherit;">
                    <img src="https://yt3.googleusercontent.com/lxpJQz3QU7u-_NeTZVzQOphQHKW4Klu82r9ATc8bYCUrjd4FdOpS-nD0KF--YEXCfQEet5GV=s160-c-k-c0x00ffffff-no-rj" class="nav-icon" alt="Icon">
                    <span class="nav-title" style="color:#ffffff;">Leaf's Scripts</span>
                </a>
            </div>
            <div class="nav-right">
                <a href="../../" class="btn btn-secondary btn-sm">Back</a>
            </div>
        </div>
    </nav>
    
    <div class="container">
        <div class="script-header-lg">
            <div>
                <h1>${escapedTitle}</h1>
                <div class="meta-row">
                    <span class="meta-badge">
                        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="4" width="18" height="18" rx="2" ry="2"></rect><line x1="16" y1="2" x2="16" y2="6"></line><line x1="8" y1="2" x2="8" y2="6"></line><line x1="3" y1="10" x2="21" y2="10"></line></svg>
                        <span>${formattedDate}</span>
                    </span>
                </div>
            </div>
        </div>

        <div class="code-box">
            <div class="toolbar">
                <div class="file-info">raw/${filename}</div>
                <div class="toolbar-right">
                    <button class="btn btn-sm" onclick="downloadScript()">Download</button>
                    <button class="btn btn-sm" onclick="copyScript(this)">Copy</button>
                    <a href="https://raw.githubusercontent.com/${CONFIG.user}/${CONFIG.repo}/refs/heads/${CONFIG.branch}/scripts/${scriptId}/raw/${filename}" class="btn btn-secondary btn-sm" target="_blank">Raw</a>
                </div>
            </div>
            <pre><code id="code-display" class="language-lua">Loading...</code></pre>
        </div>
    </div>

    <script src="https://cdnjs.cloudflare.com/ajax/libs/prism/1.29.0/prism.min.js"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/prism/1.29.0/components/prism-lua.min.js"></script>
    <script>
        const filename = '${filename}';
        const scriptId = '${scriptId}';
        const rawBaseUrl = 'https://raw.githubusercontent.com/${CONFIG.user}/${CONFIG.repo}/refs/heads/${CONFIG.branch}/scripts/${scriptId}/raw';
        
        async function loadScript() {
            try {
                const res = await fetch(rawBaseUrl + '/' + filename);
                const code = await res.text();
                document.getElementById('code-display').textContent = code;
                Prism.highlightAll();
            } catch(e) {
                document.getElementById('code-display').textContent = '-- Error loading source';
            }
        }
        
        function copyScript(btn) {
            const code = document.getElementById('code-display').textContent;
            navigator.clipboard.writeText(code).then(() => {
                const original = btn.innerText;
                btn.innerText = 'Copied!';
                setTimeout(() => btn.innerText = original, 2000);
            });
        }
        
        function downloadScript() {
            const code = document.getElementById('code-display').textContent;
            const element = document.createElement('a');
            element.setAttribute('href', 'data:text/plain;charset=utf-8,' + encodeURIComponent(code));
            element.setAttribute('download', filename);
            element.style.display = 'none';
            document.body.appendChild(element);
            element.click();
            document.body.removeChild(element);
        }
        
        loadScript();
    </script>
</body>
</html>`;
        
        if (isEditing && oldScriptId && oldScriptId !== scriptId) {
            await this.deleteScriptFiles(oldScriptId, filename);
        }
        
        await this.createOrUpdateFile(indexPath, scriptViewerHTML, 'text/html');
        await this.createOrUpdateFile(rawFilePath, code, 'text/plain');
    },

    async createOrUpdateFile(path, content, contentType) {
        const url = `https://api.github.com/repos/${CONFIG.user}/${CONFIG.repo}/contents/${path}`;
        const getRes = await fetch(url, { headers: { 'Authorization': `token ${this.token}` } });
        
        let sha = null;
        if (getRes.ok) {
            const existingFile = await getRes.json();
            sha = existingFile.sha;
        }
        
        const body = {
            message: `Create/update ${path}`,
            content: utils.safeBtoa(content),
            branch: CONFIG.branch
        };
        if (sha) body.sha = sha;
        
        const putRes = await fetch(url, {
            method: 'PUT',
            headers: { 
                'Authorization': `token ${this.token}`,
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(body)
        });
        
        if (!putRes.ok) throw new Error(`Failed to create/update file ${path}`);
    },

    handleRouting() {
        const hash = location.hash.slice(1);
        document.querySelectorAll('.view-section').forEach(el => el.style.display = 'none');
        window.scrollTo(0, 0);
        
        if (hash === 'admin') {
            if (!this.currentUser) {
                this.toggleLoginModal();
                location.hash = '';
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
    if (path === 'admin' && !app.currentUser) {
        app.toggleLoginModal();
        return;
    }
    location.hash = path;
}

window.addEventListener('DOMContentLoaded', () => {
    app.init();
});

window.app = app;
window.navigate = navigate;
