-- made by @simplyIeaf1 on youtube

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local levelDataStore = DataStoreService:GetDataStore("PlayerLevels")

local UpdateLevelUI = Instance.new("RemoteEvent")
UpdateLevelUI.Name = "UpdateLevelUI"
UpdateLevelUI.Parent = ReplicatedStorage

local GetLevelData = Instance.new("RemoteFunction")
GetLevelData.Name = "GetLevelData"
GetLevelData.Parent = ReplicatedStorage

local playerData = {}

local function GetMaxXP(level)
    return 100 * level
end

local function LoadPlayerData(player)
    local key = "Player_" .. player.UserId
    local success, data = pcall(function()
        return levelDataStore:GetAsync(key)
    end)
    if success and data then
        if type(data.level) == "number" and data.level >= 1 and type(data.xp) == "number" and data.xp >= 0 then
            playerData[player.UserId] = {level = math.floor(data.level), xp = data.xp}
        else
            playerData[player.UserId] = {level = 1, xp = 0}
        end
    else
        playerData[player.UserId] = {level = 1, xp = 0}
    end
end

local function SavePlayerData(userId)
    local data = playerData[userId]
    if data then
        local key = "Player_" .. userId
        local success, err = pcall(function()
            levelDataStore:SetAsync(key, {level = data.level, xp = data.xp})
        end)
        if not success then
            warn("Failed to save data for " .. userId .. ": " .. err)
        end
    end
end

local function AwardXP(player, amount)
    if not player or amount <= 0 or amount > 1000 then return end
    local data = playerData[player.UserId]
    if data then
        data.xp = data.xp + amount
        local maxXP = GetMaxXP(data.level)
        while data.xp >= maxXP do
            data.xp = data.xp - maxXP
            data.level = data.level + 1
            maxXP = GetMaxXP(data.level)
        end
        if player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("Level") then
            player.leaderstats.Level.Value = data.level
        end
        UpdateLevelUI:FireClient(player, data.level, data.xp, maxXP)
    end
end

Players.PlayerAdded:Connect(function(player)
    LoadPlayerData(player)
    
    local leaderstats = Instance.new("Folder")
    leaderstats.Name = "leaderstats"
    leaderstats.Parent = player
    
    local levelValue = Instance.new("IntValue")
    levelValue.Name = "Level"
    levelValue.Value = playerData[player.UserId].level
    levelValue.Parent = leaderstats
    
    local lastXPTime = os.clock()
    local connection
    connection = RunService.Heartbeat:Connect(function(dt)
        if not player.Parent then
            connection:Disconnect()
            return
        end
        local currentTime = os.clock()
        if currentTime - lastXPTime >= 1 then
            AwardXP(player, 10)
            lastXPTime = currentTime
        end
    end)
    
    GetLevelData.OnServerInvoke = function(plr)
        if plr == player then
            local data = playerData[player.UserId]
            if data then
                local maxXP = GetMaxXP(data.level)
                return data.level, data.xp, maxXP
            end
        end
        return nil, nil, nil
    end
end)

Players.PlayerRemoving:Connect(function(player)
    SavePlayerData(player.UserId)
    playerData[player.UserId] = nil
end)

game:BindToClose(function()
    for _, player in ipairs(Players:GetPlayers()) do
        SavePlayerData(player.UserId)
    end
end)
