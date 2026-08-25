-- ServerScriptService script for soft shutdown system
-- made by @simplyIeaf1 on youtube

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MessagingService = game:GetService("MessagingService")
local TeleportService = game:GetService("TeleportService")
local RunService = game:GetService("RunService")

local SHUTDOWN_TOPIC = "SoftShutdownTrigger"
local PLACE_ID = game.PlaceId

local shutdownEvent = ReplicatedStorage:FindFirstChild("SofShudowEvent")
if not shutdownEvent then
    shutdownEvent = Instance.new("RemoteEvent")
    shutdownEvent.Name = "SofShudowEvent"
    shutdownEvent.Parent = ReplicatedStorage
end 

local authorizedIds = {
[8033814042] = true
}

local reservedServerCode = nil

local function teleportToReserved(players)
    if not reservedServerCode then
        reservedServerCode = TeleportService:ReserveServer(PLACE_ID)
    end
    for _, player in ipairs(players) do
        TeleportService:TeleportToPrivateServer(PLACE_ID, reservedServerCode, { player })
        wait()
    end
end

local function softShutdown()
    print("Soft shutdown triggered")
    shutdownEvent:FireAllClients()
    task.wait(3)
    teleportToReserved(Players:GetPlayers())
end

MessagingService:SubscribeAsync(SHUTDOWN_TOPIC, function()
    softShutdown()
end)

Players.PlayerAdded:Connect(function(player)
    player.Chatted:Connect(function(message)
        if message:lower() == "/restart" and authorizedIds[player.UserId] then
            print(player.Name .. " triggered /restart")
            MessagingService:PublishAsync(SHUTDOWN_TOPIC, true)
        end
    end)
end)

game:BindToClose(function()
    if RunService:IsStudio() then return end
    print("Server closing - teleporting players to reserved server")
    shutdownEvent:FireAllClients()
    task.wait(3)
    teleportToReserved(Players:GetPlayers())
end)

local function handleReturnFromReserved()
    if game.PrivateServerId ~= "" and game.PrivateServerOwnerId == 0 then
        print("This is a reserved server, will return players to main place shortly")
        wait(5)
        for _, player in ipairs(Players:GetPlayers()) do
            TeleportService:Teleport(PLACE_ID, player)
            wait()
        end
    end
end

handleReturnFromReserved()
