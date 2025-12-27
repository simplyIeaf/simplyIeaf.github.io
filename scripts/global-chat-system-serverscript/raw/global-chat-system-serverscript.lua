-- made by @simplyIeaf1 on youtube

local TextChatService   = game:GetService("TextChatService")
local MessagingService  = game:GetService("MessagingService")
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextService       = game:GetService("TextService")

-- ignore this option (this was used for debugging)
local SHOW_IN_ORIGIN_SERVER = false

local GLOBAL_TOPIC = "GlobalChat"
local SERVER_ID = game.JobId

local Messenger = ReplicatedStorage:FindFirstChild("GlobalChatRemote")
if not Messenger then
    Messenger = Instance.new("RemoteEvent")
    Messenger.Name = "GlobalChatRemote"
    Messenger.Parent = ReplicatedStorage
end

TextChatService:WaitForChild("ChannelTabsConfiguration", 10).Enabled = true
local TextChannels = TextChatService:WaitForChild("TextChannels", 10)
local GlobalChannel = TextChannels:FindFirstChild("Global")
if not GlobalChannel then
    GlobalChannel = Instance.new("TextChannel")
    GlobalChannel.Name = "Global"
    GlobalChannel.Parent = TextChannels
end

Players.PlayerAdded:Connect(function(plr)
    task.wait(2)
    pcall(function()
        GlobalChannel:AddUserAsync(plr.UserId)
    end)
end)

local function encodeMessage(serverId, userId, displayName, message)
    return string.format("%s|||%d|||%s|||%s", serverId, userId, displayName, message)
end

local function decodeMessage(data)
    local parts = {}
    local current = 1
    
    while true do
        local startPos, endPos = string.find(data, "|||", current, true)
        if not startPos then
            table.insert(parts, string.sub(data, current))
            break
        end
        table.insert(parts, string.sub(data, current, startPos - 1))
        current = endPos + 1
    end
    
    if #parts == 4 then
        return {
        ServerId = parts[1],
        UserId = tonumber(parts[2]),
        DisplayName = parts[3],
        Message = parts[4]
        }
    end
    return nil
end

Messenger.OnServerEvent:Connect(function(player, rawMessage)
    if not (player and rawMessage and rawMessage ~= "") then return end
    
    local success, filtered = pcall(function()
        return TextService:FilterStringAsync(rawMessage, player.UserId, Enum.TextFilterContext.PublicChat)
    end)
    if not success or not filtered then return end
    
    local ok, broadcastMsg = pcall(function()
        return filtered:GetNonChatStringForBroadcastAsync()
    end)
    if not ok or not broadcastMsg then return end
    
    local displayName = player.DisplayName
    
    local encodedData = encodeMessage(SERVER_ID, player.UserId, displayName, broadcastMsg)
    
    task.spawn(function()
        pcall(function()
            MessagingService:PublishAsync(GLOBAL_TOPIC, encodedData)
        end)
    end)
end)

pcall(function()
    MessagingService:SubscribeAsync(GLOBAL_TOPIC, function(message)
        task.spawn(function()
            local success, data = pcall(function()
                return decodeMessage(message.Data)
            end)
            
            if not success or not data then
                warn("Failed to decode message:", message.Data)
                return
            end
            
            if not (data.ServerId and data.UserId and data.DisplayName and data.Message) then 
                warn("Incomplete data received")
                return 
            end
            
            if not SHOW_IN_ORIGIN_SERVER and data.ServerId == SERVER_ID then
                return
            end
            
            for _, plr in ipairs(Players:GetPlayers()) do
                Messenger:FireClient(plr, data.DisplayName, data.Message)
            end
        end)
    end)
end)
