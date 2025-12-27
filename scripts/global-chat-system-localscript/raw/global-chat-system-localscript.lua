-- made by @simplyIeaf1 on youtube

local TextChatService   = game:GetService("TextChatService")
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Messenger     = ReplicatedStorage:WaitForChild("GlobalChatRemote", 10)
local GlobalChannel = TextChatService:WaitForChild("TextChannels", 10):WaitForChild("Global", 10)
local LocalPlayer   = Players.LocalPlayer
 
local function displayMessage(name, text)
    local formattedMsg = string.format("%s: %s", name, text)
    GlobalChannel:DisplaySystemMessage(formattedMsg)
end

TextChatService.SendingMessage:Connect(function(chatMsg)
    if chatMsg.TextChannel == GlobalChannel then
        Messenger:FireServer(chatMsg.Text)
    end
end)

Messenger.OnClientEvent:Connect(function(name, text)
    displayMessage(name, text)
end)

TextChatService.OnChatWindowAdded = function(msg)
    local props = TextChatService.ChatWindowConfiguration:DeriveNewMessageProperties()
    if msg.TextSource then
        local plr = Players:GetPlayerByUserId(msg.TextSource.UserId)
        if plr then
            local hash = 2166136261
            for i = 1, #plr.DisplayName do
                hash = (hash * 16777619 + string.byte(plr.DisplayName, i)) % 4294967296
            end
            local r = (hash % 111) + 70
            local g = ((hash % 24236) * 0.0064102564102564) % 111 + 70
            local b = (hash * 0.0000412070895522388) % 111 + 70
            props.PrefixTextProperties = TextChatService.ChatWindowConfiguration:DeriveNewMessageProperties()
            props.PrefixTextProperties.TextColor3 = Color3.fromRGB(
            math.clamp(math.floor(r), 0, 255),
            math.clamp(math.floor(g), 0, 255),
            math.clamp(math.floor(b), 0, 255)
            )
        end
    end
    return props
end
