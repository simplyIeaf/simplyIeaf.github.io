-- made by @simplyIeaf1 on YouTube

local Players = game.Players
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local COOLDOWN_DAYS = 7
local COOLDOWN_SECONDS = COOLDOWN_DAYS * 24 * 60 * 60

local feedbackDS = DataStoreService:GetDataStore("PlayerFeedback")

local rf = Instance.new("RemoteFunction")
rf.Name = "FeedbackRF"
rf.Parent = ReplicatedStorage

local ADMINS = { "simplyIeaf" }

local function isAdmin(player)
    if not player or not player.Parent then return false end
    return table.find(ADMINS, player.Name) ~= nil
end

local function safeGetAsync(key, default)
    local success, result = pcall(function()
        local data = feedbackDS:GetAsync(key)
        if data and type(data) == "string" then
            return HttpService:JSONDecode(data)
        end
        return data
    end)
    
    if success and result then
        return result
    end
    
    return default
end

local function safeSetAsync(key, value)
    local success, err = pcall(function()
        local encoded = HttpService:JSONEncode(value)
        feedbackDS:SetAsync(key, encoded)
    end)
    
    if not success then
        warn("DataStore SetAsync failed for key", key, ":", err)
    end
    
    return success
end

rf.OnServerInvoke = function(player, action, ...)
    if not player or not player.Parent then return end
    
    if action == "CanSubmit" then
        local key = "Cooldown_" .. player.UserId
        local cooldownData = safeGetAsync(key, {lastSubmit = 0})
        local lastSubmit = cooldownData.lastSubmit or 0
        
        return (os.time() - lastSubmit) >= COOLDOWN_SECONDS
        
    elseif action == "Submit" then
        local text, rating = ...
        if not text or not text:match("%S") or not rating then 
            return false 
        end
        
        local key = "Cooldown_" .. player.UserId
        local now = os.time()
        
        local cooldownData = safeGetAsync(key, {lastSubmit = 0})
        local lastSubmit = cooldownData.lastSubmit or 0
        
        if (now - lastSubmit) < COOLDOWN_SECONDS then 
            warn("Player", player.Name, "tried to submit too soon")
            return false 
        end
        
        local feedbackList = safeGetAsync("FeedbackList", {entries = {}})
        
        local newEntry = {
        userId = player.UserId,
        username = player.Name,
        msg = text,
        timestamp = now,
        rating = rating
        }
        
        table.insert(feedbackList.entries, 1, newEntry)
        
        if #feedbackList.entries > 200 then 
            table.remove(feedbackList.entries) 
        end
        
        local saveSuccess = safeSetAsync("FeedbackList", feedbackList)
        
        if not saveSuccess then
            warn("Failed to save feedback for player", player.Name)
            return false
        end
        
        safeSetAsync(key, {lastSubmit = now})
        
        print("Feedback submitted successfully by", player.Name)
        return true
        
    elseif action == "GetFeedback" then
        if not isAdmin(player) then 
            return {}
        end
        
        local feedbackList = safeGetAsync("FeedbackList", {entries = {}})
        print("Admin", player.Name, "requested feedback. Found", #feedbackList.entries, "entries")
        return feedbackList.entries or {}
        
    elseif action == "RemoveFeedback" then
        local indexToRemove = tonumber((...))
        if not isAdmin(player) or not indexToRemove then return false end
        
        local feedbackList = safeGetAsync("FeedbackList", {entries = {}})
        local entries = feedbackList.entries
        
        if indexToRemove >= 1 and indexToRemove <= #entries then
            table.remove(entries, indexToRemove)
            local saveSuccess = safeSetAsync("FeedbackList", feedbackList)
            
            if saveSuccess then
                print("Admin", player.Name, "removed feedback at index", indexToRemove)
            end
            return saveSuccess
        end
        return false
        
    elseif action == "IsAdmin" then
        return isAdmin(player)
    end
end