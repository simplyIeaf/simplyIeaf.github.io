-- made by @simplyIeaf1 on youtube

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local giveEvent = ReplicatedStorage:FindFirstChild("GiveItemEvent")
if not giveEvent then
    giveEvent = Instance.new("RemoteEvent")
    giveEvent.Name = "GiveItemEvent"
    giveEvent.Parent = ReplicatedStorage
end

-- pendingGifts[senderUserId][targetUserId] = tool
local pendingGifts = {}

giveEvent.OnServerEvent:Connect(function(sender, targetUserId, itemName, action)
    local targetPlayer = Players:GetPlayerByUserId(targetUserId)
    if not targetPlayer then return end

    pendingGifts[sender.UserId] = pendingGifts[sender.UserId] or {}

    if action == "Request" then
        if pendingGifts[sender.UserId][targetPlayer.UserId] then return end
        local tool = sender.Backpack:FindFirstChild(itemName) or sender.Character:FindFirstChild(itemName)
        if tool then
            pendingGifts[sender.UserId][targetPlayer.UserId] = tool
            -- Notify target client
            giveEvent:FireClient(targetPlayer, sender.UserId, itemName)
        end

    elseif action == "Accept" then
        local tool = pendingGifts[targetPlayer.UserId] and pendingGifts[targetPlayer.UserId][sender.UserId]
        if tool and tool.Parent then
            -- Move tool to the accepting player
            tool.Parent = sender.Backpack
            pendingGifts[targetPlayer.UserId][sender.UserId] = nil
        end

    elseif action == "Decline" then
        if pendingGifts[targetPlayer.UserId] then
            pendingGifts[targetPlayer.UserId][sender.UserId] = nil
        end
    end
end)