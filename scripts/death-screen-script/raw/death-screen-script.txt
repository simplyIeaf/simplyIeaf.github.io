-- made by @simplyIeaf1 on youtube

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DeathEvent = Instance.new("RemoteEvent")
DeathEvent.Name = "DeatEven"
DeathEvent.Parent = ReplicatedStorage

Players.CharacterAutoLoads = false
Players.RespawnTime = math.huge

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(char)
        local humanoid = char:WaitForChild("Humanoid")
        
        humanoid.Died:Connect(function()
            DeathEvent:FireClient(player)
        end)
    end)
    
    -- Load character manually
    player:LoadCharacter()
end)

DeathEvent.OnServerEvent:Connect(function(player, action)
    if action == "Respawn" then
        player:LoadCharacter()
    end
end)
