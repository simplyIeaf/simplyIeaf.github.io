-- made by @simplyIeaf1 on youtube

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
 
-- server respawn requests
local respawnEvent = Instance.new("RemoteEvent")
respawnEvent.Name = "RespawnEvent"
respawnEvent.Parent = ReplicatedStorage
 
-- auto-respawn
Players.CharacterAutoLoads = false
Players.RespawnTime = 0.1
 
-- spawn when player joins
Players.PlayerAdded:Connect(function(player)
    player:LoadCharacter()
end)
 
-- respawn requests from client
respawnEvent.OnServerEvent:Connect(function(player)
    if player then
        player:LoadCharacter()
    end
end)
