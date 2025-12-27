-- made by @simplyIeaf1 on YouTube

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
 
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local camera = workspace.CurrentCamera

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SpectateButtonGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local button = Instance.new("TextButton")
button.Name = "SpectateButton"
button.Size = UDim2.new(0, 60, 0, 60)
button.Position = UDim2.new(0, 20, 0.40, -30)
button.AnchorPoint = Vector2.new(0.20, 0)
button.BackgroundColor3 = Color3.new(1, 1, 1)
button.BorderMode = "Inset"
button.BorderSizePixel = 7
button.BorderColor3 = Color3.new(0, 0, 0)
button.Text = ""
button.Parent = screenGui

local uiCorner = Instance.new("UICorner")
uiCorner.CornerRadius = UDim.new(0.15, 0)
uiCorner.Parent = button

local imageLabel = Instance.new("ImageLabel")
imageLabel.Size = UDim2.new(0.8, 0, 0.8, 0)
imageLabel.Position = UDim2.new(0.1, 0, 0.1, 0)
imageLabel.AnchorPoint = Vector2.new(0, 0)
imageLabel.BackgroundTransparency = 1
imageLabel.Image = "rbxthumb://type=Asset&id=108583595363689&w=420&h=420"
imageLabel.Parent = button
 
local isSpectating = false
local spectateTarget = nil
local spectateIndex = 1
local spectateList = {}
local originalCameraType = camera.CameraType
local originalCameraSubject = nil
local playerIsDead = false
 
local spectateScreenGui = Instance.new("ScreenGui")
spectateScreenGui.Name = "SpectateGui"
spectateScreenGui.ResetOnSpawn = false
spectateScreenGui.Parent = playerGui
 
local spectateFrame = Instance.new("Frame")
spectateFrame.Name = "SpectateFrame"
spectateFrame.Size = UDim2.new(0, 300, 0, 60)
spectateFrame.Position = UDim2.new(0.5, -150, 1, -80)
spectateFrame.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
spectateFrame.BorderSizePixel = 0
spectateFrame.Visible = false
spectateFrame.Parent = spectateScreenGui
 
local playerLabel = Instance.new("TextLabel")
playerLabel.Name = "PlayerLabel"
playerLabel.Size = UDim2.new(1, -100, 1, 0)
playerLabel.Position = UDim2.new(0, 50, 0, 0)
playerLabel.BackgroundTransparency = 1
playerLabel.Text = "Spectating: Player"
playerLabel.TextColor3 = Color3.new(1, 1, 1)
playerLabel.TextSize = 12
playerLabel.Font = Enum.Font.GothamBold
playerLabel.Parent = spectateFrame
 
local leftButton = Instance.new("TextButton")
leftButton.Name = "LeftButton"
leftButton.Size = UDim2.new(0, 40, 0, 40)
leftButton.Position = UDim2.new(0, 10, 0.5, -20)
leftButton.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
leftButton.BorderSizePixel = 0
leftButton.Text = "<"
leftButton.TextColor3 = Color3.new(1, 1, 1)
leftButton.TextScaled = true
leftButton.Font = Enum.Font.GothamBold
leftButton.Parent = spectateFrame
 
local rightButton = Instance.new("TextButton")
rightButton.Name = "RightButton"
rightButton.Size = UDim2.new(0, 40, 0, 40)
rightButton.Position = UDim2.new(1, -50, 0.5, -20)
rightButton.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
rightButton.BorderSizePixel = 0
rightButton.Text = ">"
rightButton.TextColor3 = Color3.new(1, 1, 1)
rightButton.TextScaled = true
rightButton.Font = Enum.Font.GothamBold
rightButton.Parent = spectateFrame
 

 
local function addHoverEffect(btn, hoverColor, normalColor)
    btn.MouseEnter:Connect(function()
        local tween = TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = hoverColor})
        tween:Play()
    end)
    
    btn.MouseLeave:Connect(function()
        local tween = TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = normalColor})
        tween:Play()
    end)
end
 
addHoverEffect(leftButton, Color3.new(0.3, 0.3, 0.3), Color3.new(0.2, 0.2, 0.2))
addHoverEffect(rightButton, Color3.new(0.3, 0.3, 0.3), Color3.new(0.2, 0.2, 0.2))
 
local function isPlayerDead()
    if not player.Character then
        return true
    end
    local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
    return humanoid and humanoid.Health <= 0
end
 
local function saveCameraState()
    originalCameraType = camera.CameraType
    originalCameraSubject = camera.CameraSubject
end
 
local function restoreCameraToNormal()
    camera.CameraType = originalCameraType
    
    if player.Character and not isPlayerDead() then
        local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            camera.CameraSubject = humanoid
        end
    else
        if originalCameraSubject and originalCameraSubject.Parent then
            camera.CameraSubject = originalCameraSubject
        end
    end
end
 
local function updateSpectateList()
    spectateList = {}
    for _, otherPlayer in pairs(Players:GetPlayers()) do
        if otherPlayer ~= player and otherPlayer.Character and otherPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local humanoid = otherPlayer.Character:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid.Health > 0 then
                table.insert(spectateList, otherPlayer)
            end
        end
    end
end
 

 
local function spectatePlayer(targetPlayer)
    if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local humanoid = targetPlayer.Character:FindFirstChildOfClass("Humanoid")
        if humanoid and humanoid.Health > 0 then
            spectateTarget = targetPlayer
            camera.CameraType = Enum.CameraType.Custom
            camera.CameraSubject = humanoid
            playerLabel.Text = "Spectating: " .. targetPlayer.Name
            return true
        end
    end
    return false
end
 
local function startSpectating()
    if isSpectating then return end
    
    saveCameraState()
    
    updateSpectateList()
    if #spectateList == 0 then
        spectateFrame.Visible = true
        playerLabel.Text = "No players to spectate"
        isSpectating = true
        return
    end
    
    isSpectating = true
    spectateIndex = 1
    
    spectateFrame.Visible = true
    
    if spectatePlayer(spectateList[spectateIndex]) then
    else
        playerLabel.Text = "No valid target found"
    end
end
 
local function stopSpectating()
    if not isSpectating then return end
    
    isSpectating = false
    spectateTarget = nil
    
    restoreCameraToNormal()
    
    spectateFrame.Visible = false
end
 
local function nextPlayer()
    if not isSpectating or #spectateList == 0 then return end
    
    spectateIndex = spectateIndex + 1
    if spectateIndex > #spectateList then
        spectateIndex = 1
    end
    
    updateSpectateList()
    if spectateList[spectateIndex] then
        spectatePlayer(spectateList[spectateIndex])
    end
end
 
local function previousPlayer()
    if not isSpectating or #spectateList == 0 then return end
    
    spectateIndex = spectateIndex - 1
    if spectateIndex < 1 then
        spectateIndex = #spectateList
    end
    
    updateSpectateList()
    if spectateList[spectateIndex] then
        spectatePlayer(spectateList[spectateIndex])
    end
end
 
local function toggleSpectating()
    if isSpectating then
        stopSpectating()
    else
        startSpectating()
    end
end
 
button.Activated:Connect(function()
    toggleSpectating()
end)
 
leftButton.Activated:Connect(function()
    if isSpectating then
        previousPlayer()
    end
end)
 
rightButton.Activated:Connect(function()
    if isSpectating then
        nextPlayer()
    end
end)
 
Players.PlayerRemoving:Connect(function(leavingPlayer)
    if isSpectating and spectateTarget == leavingPlayer then
        updateSpectateList()
        if #spectateList > 0 then
            spectateIndex = math.min(spectateIndex, #spectateList)
            spectatePlayer(spectateList[spectateIndex])
        else
            spectateTarget = nil
            playerLabel.Text = "No players to spectate"
            playerLabel.TextSize = 14
            restoreCameraToNormal()
        end
    end
end)
 
player.CharacterAdded:Connect(function(character)
    playerIsDead = false
    if not isSpectating then
        saveCameraState()
    end
end)
 
player.CharacterRemoving:Connect(function()
    playerIsDead = true
end)
 
RunService.Heartbeat:Connect(function()
    local wasPlayerDead = playerIsDead
    playerIsDead = isPlayerDead()
    
    if isSpectating and not wasPlayerDead and playerIsDead then
        stopSpectating()
        return
    end
    
    if isSpectating then
        
        if spectateTarget then
            local humanoid = spectateTarget.Character and spectateTarget.Character:FindFirstChildOfClass("Humanoid")
            
            if humanoid and humanoid.Health <= 0 then
                updateSpectateList()
                local foundValidPlayer = false
                
                for i = 1, #spectateList do
                    local checkIndex = ((spectateIndex - 1 + i - 1) % #spectateList) + 1
                    if spectateList[checkIndex] and spectateList[checkIndex] ~= spectateTarget then
                        spectateIndex = checkIndex
                        if spectatePlayer(spectateList[spectateIndex]) then
                            foundValidPlayer = true
                            break
                        end
                    end
                end
                
                if not foundValidPlayer then
                    spectateTarget = nil
                    playerLabel.Text = "No players to spectate"
                    restoreCameraToNormal()
                end
                
            elseif not spectateTarget.Character or not spectateTarget.Character:FindFirstChild("HumanoidRootPart") then
                updateSpectateList()
                local foundValidPlayer = false
                
                for i = 1, #spectateList do
                    local checkIndex = ((spectateIndex - 1 + i - 1) % #spectateList) + 1
                    if spectateList[checkIndex] and spectateList[checkIndex] ~= spectateTarget then
                        spectateIndex = checkIndex
                        if spectatePlayer(spectateList[spectateIndex]) then
                            foundValidPlayer = true
                            break
                        end
                    end
                end
                
                if not foundValidPlayer then
                    spectateTarget = nil
                    playerLabel.Text = "No players to spectate"
                    restoreCameraToNormal()
                end
            end
        else
            updateSpectateList()
            if #spectateList > 0 then
                spectateIndex = 1
                spectatePlayer(spectateList[spectateIndex])
            end
        end
    end
end)