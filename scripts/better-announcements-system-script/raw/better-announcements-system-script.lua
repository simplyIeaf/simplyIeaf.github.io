-- made by @simplyIeaf1 on YouTube

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local MessagingService = game:GetService("MessagingService")

local authorizedIds = {
[8033814042] = true,
}

local remote = ReplicatedStorage:FindFirstChild("MessageEvent")
if not remote then
    remote = Instance.new("RemoteEvent")
    remote.Name = "MessageEvent"
    remote.Parent = ReplicatedStorage
end

local success, err = pcall(function()
    MessagingService:SubscribeAsync("Announcements", function(message)
        remote:FireAllClients(message.Data)
    end)
end)

if not success then
    warn("Failed to subscribe to Announcements: " .. tostring(err))
end

Players.PlayerAdded:Connect(function(player)
    player.Chatted:Connect(function(msg)
        if msg:sub(1, 9):lower() == "/announce" and authorizedIds[player.UserId] then
            local announceText = msg:sub(11)
            if announceText and announceText ~= "" then
                local ok, publishErr = pcall(function()
                    MessagingService:PublishAsync("Announcements", {
                    username = player.Name,
                    text = announceText
                    })
                end)
                if not ok then
                    warn("Failed to publish announcement: " .. tostring(publishErr))
                end
            end
        end
    end)
end)
