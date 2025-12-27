local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")
local MessagingService = game:GetService("MessagingService")
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

local admins = {"username1", "username2"}
for i, v in ipairs(admins) do
    admins[i] = v:lower()
end

local countdownStore = DataStoreService:GetDataStore("GlobalCountdownStore")

local StartCountdown = ReplicatedStorage:FindFirstChild("StartCountdown")
if not StartCountdown then
    StartCountdown = Instance.new("RemoteEvent")
    StartCountdown.Name = "StartCountdown"
    StartCountdown.Parent = ReplicatedStorage
end

local remoteCooldowns = {}
local COOLDOWN_TIME = 2

local currentEndTime = 0
local currentFormat = {}
local countdownActive = false
local topic = "GlobalCountdown"

local function isValidPlayer(player)
    if not player then return false end
    if not player:IsDescendantOf(Players) then return false end
    if not player.Parent then return false end
    return true
end

local function isAdmin(player)
    if not isValidPlayer(player) then return false end
    return table.find(admins, player.Name:lower()) ~= nil
end

local function canUseCommand(player)
    if not isAdmin(player) then return false end
    
    local userId = player.UserId
    local currentTime = os.clock()
    
    if remoteCooldowns[userId] and currentTime - remoteCooldowns[userId] < COOLDOWN_TIME then
        return false
    end
    
    remoteCooldowns[userId] = currentTime
    return true
end

local function loadCountdown()
    local success, result = pcall(function()
        return countdownStore:GetAsync("ActiveCountdown")
    end)
    
    if success and result and type(result) == "table" then
        if result.endTime and type(result.endTime) == "number" and result.endTime > os.time() then
            currentEndTime = result.endTime
            currentFormat = result.format or {}
            countdownActive = true
            StartCountdown:FireAllClients(currentEndTime, currentFormat)
            return true
        else
            pcall(function()
                countdownStore:RemoveAsync("ActiveCountdown")
            end)
        end
    end
    countdownActive = false
    return false
end

local function saveCountdown(endTime, format)
    if type(endTime) ~= "number" or type(format) ~= "table" then return end
    
    pcall(function()
        countdownStore:SetAsync("ActiveCountdown", {
            endTime = endTime,
            format = format
        })
    end)
end

local function clearCountdown()
    pcall(function()
        countdownStore:RemoveAsync("ActiveCountdown")
    end)
end

loadCountdown()

MessagingService:SubscribeAsync(topic, function(message)
    local data = message.Data
    if not data or type(data) ~= "table" then return end
    
    if data.clear then
        currentEndTime = 0
        currentFormat = {}
        countdownActive = false
        StartCountdown:FireAllClients(0, {})
    elseif data.endTime and type(data.endTime) == "number" and data.endTime > os.time() then
        currentEndTime = data.endTime
        currentFormat = type(data.format) == "table" and data.format or {}
        countdownActive = true
        StartCountdown:FireAllClients(data.endTime, data.format or {})
    end
end)

local command = Instance.new("TextChatCommand")
command.Name = "GlobalCountdownCommand"
command.PrimaryAlias = "/globalcountdown"
command.SecondaryAlias = "/countdown"
command.Triggered:Connect(function(textSource, message)
    if not textSource or not textSource.UserId then return end
    if countdownActive then return end
    
    local player = Players:GetPlayerByUserId(textSource.UserId)
    if not canUseCommand(player) then return end
    
    message = message:lower()
    local args = message:match("^/globalcountdown%s+(.+)$") or message:match("^/countdown%s+(.+)$")
    if not args or type(args) ~= "string" or #args > 200 then return end
    
    local parts = {}
    for part in args:gmatch("%S+") do
        if #parts >= 10 then break end
        table.insert(parts, part)
    end
    
    local times = {days = 0, hours = 0, minutes = 0, seconds = 0}
    local format = {}
    local valid = false
    
    for _, part in ipairs(parts) do
        if type(part) ~= "string" then continue end
        
        local key, val = part:match("^(%a+):(%d+)$")
        if key and val then
            key = key:lower()
            if times[key] ~= nil then
                local numVal = tonumber(val)
                if not numVal or numVal < 0 or numVal > 365 then continue end
                
                times[key] = numVal
                table.insert(format, key)
                valid = true
            end
        end
    end
    
    if not valid or #format == 0 then return end
    
    local totalSeconds = times.days * 86400 + times.hours * 3600 + times.minutes * 60 + times.seconds
    if totalSeconds <= 0 or totalSeconds > 31536000 then return end
    
    local endTime = os.time() + totalSeconds
    currentEndTime = endTime
    currentFormat = format
    countdownActive = true
    
    saveCountdown(endTime, format)
    
    local data = {endTime = endTime, format = format}
    StartCountdown:FireAllClients(endTime, format)
    
    local success, err = pcall(function()
        MessagingService:PublishAsync(topic, data)
    end)
    if not success then
        warn("Failed to publish countdown:", err)
    end
end)
command.Parent = TextChatService.TextChatCommands

local stopCommand = Instance.new("TextChatCommand")
stopCommand.Name = "StopCountdownCommand"
stopCommand.PrimaryAlias = "/stopcountdown"
stopCommand.Triggered:Connect(function(textSource, message)
    if not textSource or not textSource.UserId then return end
    
    local player = Players:GetPlayerByUserId(textSource.UserId)
    if not canUseCommand(player) then return end
    
    if countdownActive then
        currentEndTime = 0
        currentFormat = {}
        countdownActive = false
        clearCountdown()
        
        StartCountdown:FireAllClients(0, {})
        
        pcall(function()
            MessagingService:PublishAsync(topic, {clear = true})
        end)
    end
end)
stopCommand.Parent = TextChatService.TextChatCommands

local function onPlayerAdded(player)
    if not isValidPlayer(player) then return end
    
    if countdownActive and currentEndTime > os.time() then
        StartCountdown:FireClient(player, currentEndTime, currentFormat)
    end
end

Players.PlayerAdded:Connect(onPlayerAdded)

for _, player in ipairs(Players:GetPlayers()) do
    task.spawn(function()
        onPlayerAdded(player)
    end)
end

task.spawn(function()
    while true do
        task.wait(5)
        if countdownActive and currentEndTime > 0 then
            if os.time() >= currentEndTime then
                currentEndTime = 0
                currentFormat = {}
                countdownActive = false
                clearCountdown()
                
                pcall(function()
                    MessagingService:PublishAsync(topic, {clear = true})
                end)
            end
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(60)
        local now = os.clock()
        for userId, lastTime in pairs(remoteCooldowns) do
            if now - lastTime > 300 then
                remoteCooldowns[userId] = nil
            end
        end
    end
end)