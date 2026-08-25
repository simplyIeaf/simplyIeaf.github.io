-- made by @simplyIeaf1 on youtube

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local localPlayer = Players.LocalPlayer
local getPlatformRemote = ReplicatedStorage:WaitForChild("GetPlayerPlatform")

local function updatePlatform()
    local platform
    if UserInputService.TouchEnabled then
        platform = "mobile"
    elseif UserInputService.GamepadEnabled then
        platform = "controller"
    else
        platform = "pc"
    end
    warn("Platform detected for " .. localPlayer.Name .. ": " .. platform)
    return platform
end

getPlatformRemote.OnClientInvoke = function()
    return updatePlatform()
end

local function onCharacterAdded(character)
    local humanoid = character:WaitForChild("Humanoid")
    humanoid.Died:Connect(function()
        warn("Player " .. localPlayer.Name .. " died, waiting for respawn")
        local newCharacter = localPlayer.CharacterAdded:Wait()
        task.wait(0.5) -- Ensure character is fully loaded
        local newPlatform = updatePlatform()
        warn("Platform after respawn for " .. localPlayer.Name .. ": " .. newPlatform)
    end)
end

localPlayer.CharacterAdded:Connect(onCharacterAdded)
if localPlayer.Character then
    onCharacterAdded(localPlayer.Character)
end