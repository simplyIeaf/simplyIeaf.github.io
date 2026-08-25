-- made by @simplyIeaf1 on youtube

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local ShowHealthBarOnNPCs = true

local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)

local function createHealthBar(character)
    if not character then return end
    task.wait(0.1)
    if not character.Parent or character:FindFirstChild("HealthBarGUI") then return end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end

    local head = character:FindFirstChild("Head")
    if not head then return end

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "HealthBarGUI"
    billboard.Adornee = head
    billboard.Size = UDim2.new(2, 0, 0.5, 0)
    billboard.StudsOffset = Vector3.new(0, 2, 0)
    billboard.AlwaysOnTop = false
    billboard.Parent = character

    local bgFrame = Instance.new("Frame")
    bgFrame.Size = UDim2.new(0.98, 0, 0.8, 0)
    bgFrame.Position = UDim2.new(0.01, 0, 0.1, 0)
    bgFrame.BackgroundColor3 = Color3.new(0, 0, 0)
    bgFrame.BackgroundTransparency = 0.5
    bgFrame.BorderSizePixel = 0
    bgFrame.Parent = billboard

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0.98, 0, 0.8, 0)
    frame.Position = UDim2.new(0.01, 0, 0.1, 0)
    frame.BackgroundColor3 = Color3.new(0, 1, 0)
    frame.BorderSizePixel = 0
    frame.Parent = billboard

    local outlineFrame = Instance.new("Frame")
    outlineFrame.Size = UDim2.new(0.98, 0, 0.8, 0)
    outlineFrame.Position = UDim2.new(0.01, 0, 0.1, 0)
    outlineFrame.BackgroundTransparency = 1
    outlineFrame.BorderSizePixel = 0
    outlineFrame.Parent = billboard

    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 2
    stroke.Color = Color3.new(0, 0, 0)
    stroke.Parent = outlineFrame

    local shadowOverlay = Instance.new("Frame")
    shadowOverlay.Name = "ShadowOverlay"
    shadowOverlay.Size = UDim2.new(0.98, 0, 0.4, 0)
    shadowOverlay.Position = UDim2.new(0.01, 0, 0.5, 0)
    shadowOverlay.BackgroundColor3 = Color3.new(0, 0, 0)
    shadowOverlay.BackgroundTransparency = 0.7
    shadowOverlay.BorderSizePixel = 0
    shadowOverlay.Parent = billboard

    local healthText = Instance.new("TextLabel")
    healthText.Size = UDim2.new(0.8, 0, 0.6, 0)
    healthText.Position = UDim2.new(0.1, 0, 0.2, 0)
    healthText.BackgroundTransparency = 1
    healthText.Text = "100/100 HP"
    healthText.TextColor3 = Color3.new(1, 1, 1)
    healthText.TextScaled = true
    healthText.Font = Enum.Font.GothamBold
    healthText.TextXAlignment = Enum.TextXAlignment.Center
    healthText.TextYAlignment = Enum.TextYAlignment.Center
    healthText.Parent = billboard

    local textConstraint = Instance.new("UITextSizeConstraint")
    textConstraint.MinTextSize = 12
    textConstraint.MaxTextSize = 12
    textConstraint.Parent = healthText

    local textStroke = Instance.new("UIStroke")
    textStroke.Thickness = 1
    textStroke.Color = Color3.new(0, 0, 0)
    textStroke.Parent = healthText

    local function updateHealth()
        if not humanoid or not humanoid.Parent or humanoid.Health <= 0 then
            local sizeTween = TweenService:Create(frame, tweenInfo, {Size = UDim2.new(0, 0, 0.8, 0)})
            sizeTween:Play()
            local shadowSizeTween = TweenService:Create(shadowOverlay, tweenInfo, {Size = UDim2.new(0, 0, 0.4, 0)})
            shadowSizeTween:Play()
            healthText.Text = "0/" .. math.floor(humanoid.MaxHealth) .. " HP"
            return
        end

        local healthPercent = humanoid.Health / humanoid.MaxHealth
        local newSize = UDim2.new(0.98 * healthPercent, 0, 0.8, 0)
        local newShadowSize = UDim2.new(0.98 * healthPercent, 0, 0.4, 0)

        local targetColor
        if healthPercent <= 0.25 then
            targetColor = Color3.new(1, 0, 0)
        elseif healthPercent <= 0.5 then
            targetColor = Color3.new(1, 1, 0)
        else
            targetColor = Color3.new(0, 1, 0)
        end

        local sizeTween = TweenService:Create(frame, tweenInfo, {Size = newSize})
        sizeTween:Play()

        local shadowSizeTween = TweenService:Create(shadowOverlay, tweenInfo, {Size = newShadowSize})
        shadowSizeTween:Play()

        local colorTween = TweenService:Create(frame, tweenInfo, {BackgroundColor3 = targetColor})
        colorTween:Play()

        healthText.Text = math.floor(humanoid.Health) .. "/" .. math.floor(humanoid.MaxHealth) .. " HP"
    end

    humanoid:GetPropertyChangedSignal("Health"):Connect(function()
        if humanoid and humanoid.Parent then
            updateHealth()
        end
    end)
    humanoid:GetPropertyChangedSignal("MaxHealth"):Connect(function()
        if humanoid and humanoid.Parent then
            updateHealth()
        end
    end)
    updateHealth()

    humanoid.Died:Connect(function()
        if billboard and billboard.Parent then
            billboard:Destroy()
        end
    end)
end

local function onPlayerAdded(player)
    local function onCharacterAdded(character)
        if character then
            createHealthBar(character)
        end
    end

    player.CharacterAdded:Connect(onCharacterAdded)
    if player.Character then
        onCharacterAdded(player.Character)
    end
end

if ShowHealthBarOnNPCs then
    local function checkNPCs()
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("Model") and not Players:GetPlayerFromCharacter(obj) then
                createHealthBar(obj)
            end
        end
    end

    Workspace.DescendantAdded:Connect(function(descendant)
        if descendant:IsA("Model") and not Players:GetPlayerFromCharacter(descendant) then
            createHealthBar(descendant)
        end
    end)

    checkNPCs()
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in ipairs(Players:GetPlayers()) do
    onPlayerAdded(player)
end

Players.PlayerRemoving:Connect(function(player)
    if player.Character and player.Character:FindFirstChild("HealthBarGUI") then
        player.Character.HealthBarGUI:Destroy()
    end
end)