-- made by @simplyIeaf1 on YouTube

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UpdateLogStore = DataStoreService:GetDataStore("UpdateLogSeen")
local GetLogsRF = Instance.new("RemoteFunction")
GetLogsRF.Name = "GetUpdateLogs"
GetLogsRF.Parent = ReplicatedStorage

local AUTO_GAME_NAME = true
local CUSTOM_GAME_NAME = "Your Game Name"

local UPDATE_LOGS = {
{date = "October 28, 2025", version = 1, info = "• Added Update Log GUI\n• Performance improvements"}
}

local CURRENT_MAX_VERSION = 0
local relevantLogs = {}

for _, log in ipairs(UPDATE_LOGS) do
    if log.version > CURRENT_MAX_VERSION then
        CURRENT_MAX_VERSION = log.version
    end
    if log.version <= CURRENT_MAX_VERSION then
        table.insert(relevantLogs, log)
    end
end

table.sort(relevantLogs, function(a, b) return a.version > b.version end)
    
    local contentString = ""
    for _, log in ipairs(relevantLogs) do
        contentString = contentString .. log.date .. "|" .. log.info .. "|"
    end
    local CURRENT_CONTENT_HASH = contentString
    
    local GAME_NAME = AUTO_GAME_NAME and MarketplaceService:GetProductInfo(game.PlaceId).Name or CUSTOM_GAME_NAME
    
    GetLogsRF.OnServerInvoke = function(plr)
        local key = "P_" .. plr.UserId
        local ok, data = pcall(UpdateLogStore.GetAsync, UpdateLogStore, key)
        
        local lastSeenVersion = 0
        local lastSeenHash = ""
        
        if ok and data and type(data) == "table" then
            lastSeenVersion = data.version or 0
            lastSeenHash = data.hash or ""
        end
        
        local show = false
        if CURRENT_MAX_VERSION > lastSeenVersion then
            show = true
        elseif CURRENT_MAX_VERSION == lastSeenVersion and CURRENT_CONTENT_HASH ~= lastSeenHash then
            show = true
        end
        
        if show then
            local saveData = {
            version = CURRENT_MAX_VERSION,
            hash = CURRENT_CONTENT_HASH
            }
            local s, err = pcall(UpdateLogStore.SetAsync, UpdateLogStore, key, saveData)
            if not s then warn("Datastore save fail:", plr.Name, err) end
        end
        
        return UPDATE_LOGS, show, GAME_NAME
    end
