-- made by @simplyIeaf1 on YouTube

local RunSvc = game:GetService("RunService")
local Players = game:GetService("Players")
local RepStorage = game:GetService("ReplicatedStorage")
 
local PlayAnimationState = RepStorage:FindFirstChild("PlayAnimationState")
if not PlayAnimationState then
    PlayAnimationState = Instance.new("RemoteEvent")
    PlayAnimationState.Name = "PlayAnimationState"
    PlayAnimationState.Parent = RepStorage
end
 
local MOVEMENT_THRESHOLD = 0.01
local CharacterData = {}
 
local function getSpecialState(currentHumState)
    if currentHumState == Enum.HumanoidStateType.Jumping then
        return "Jump"
    elseif currentHumState == Enum.HumanoidStateType.Freefall then
        return "Jump"
    elseif currentHumState == Enum.HumanoidStateType.Swimming then
        return "Swim"
    elseif currentHumState == Enum.HumanoidStateType.Climbing then
        return "Climb"
    end
    return nil
end
 
local function isStateValid(data, newState)
    if not data.Humanoid or not data.RootPart then return false end
    
    if newState == "Walk" then
        return data.Humanoid.MoveDirection.Magnitude > MOVEMENT_THRESHOLD and data.Humanoid.FloorMaterial ~= Enum.Material.Air
    elseif newState == "Idle" then
        return data.Humanoid.MoveDirection.Magnitude <= MOVEMENT_THRESHOLD and data.Humanoid.FloorMaterial ~= Enum.Material.Air
    end
    return true
end
 
local function FireToAllExceptOwner(playerToExclude, newState)
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= playerToExclude then
            PlayAnimationState:FireClient(player, playerToExclude, newState)
        end
    end
end
 
local function fireState(player, data, newState)
    if not isStateValid(data, newState) then return end
    if data.CurrentState == newState then return end
    
    data.CurrentState = newState
    
    PlayAnimationState:FireClient(player, player, newState)
    FireToAllExceptOwner(player, newState)
end
 
local function handleCharacterAdded(character)
    local player = Players:GetPlayerFromCharacter(character)
    if not player then return end
    
    local humanoid = character:WaitForChild("Humanoid")
    local rootPart = character:WaitForChild("HumanoidRootPart")
    
    humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
    
    local data = {
    Character = character,
    Humanoid = humanoid,
    RootPart = rootPart,
    CurrentState = "Idle",
    SpecialStateLock = false
    }
    CharacterData[player] = data
    
    PlayAnimationState:FireClient(player, player, "Idle")
    
    humanoid.StateChanged:Connect(function(oldState, newState)
        local specialState = getSpecialState(newState)
        
        if specialState then
            data.SpecialStateLock = true
            fireState(player, data, specialState)
        else
            data.SpecialStateLock = false
        end
    end)
end
 
local function onPlayerRemoving(player)
    CharacterData[player] = nil
end
 
local function onPlayerAdded(player)
    player.CharacterAdded:Connect(handleCharacterAdded)
    player.CharacterRemoving:Connect(function()
        CharacterData[player] = nil
    end)
    if player.Character then
        handleCharacterAdded(player.Character)
    end
end
 
Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)
 
for _, player in pairs(Players:GetPlayers()) do
    onPlayerAdded(player)
end
 
RunSvc.Heartbeat:Connect(function()
    for player, data in pairs(CharacterData) do
        if data.Character and data.Humanoid.Health > 0 and data.RootPart and not data.SpecialStateLock then
            local moveMag = data.Humanoid.MoveDirection.Magnitude
            local nextState = "Idle"
            
            if moveMag > MOVEMENT_THRESHOLD and data.Humanoid.FloorMaterial ~= Enum.Material.Air then
                nextState = "Walk"
            end
            
            if data.CurrentState ~= nextState then
                fireState(player, data, nextState)
            end
        end
    end
end)
