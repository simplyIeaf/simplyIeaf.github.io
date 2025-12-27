-- made by @simplyIeaf1 on youtube

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local DeathEvent = ReplicatedStorage:WaitForChild("DeatEven")

local function calculateUIScale()
    local camera = workspace.CurrentCamera
    local viewportSize = camera.ViewportSize
    local baseWidth = 1920
    local baseHeight = 1080
    local widthScale = viewportSize.X / baseWidth
    local heightScale = viewportSize.Y / baseHeight
    local scale = math.min(widthScale, heightScale)
    scale = math.max(scale, 0.7)
    return scale
end

local screenGui = Instance.new("ScreenGui")
screenGui.IgnoreGuiInset = true
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

local blackFrame = Instance.new("Frame")
blackFrame.Size = UDim2.fromScale(1, 1)
blackFrame.BackgroundColor3 = Color3.new(0, 0, 0)
blackFrame.BackgroundTransparency = 1
blackFrame.Parent = screenGui

local youDied = Instance.new("TextLabel")
youDied.Size = UDim2.fromScale(0.6, 0.2)
youDied.Text = "YOU DIED"
youDied.Font = Enum.Font.GothamBold
youDied.TextSize = 72
youDied.TextColor3 = Color3.new(1, 1, 1)
youDied.TextStrokeColor3 = Color3.new(0, 0, 0)
youDied.TextStrokeTransparency = 0
youDied.BackgroundTransparency = 1
youDied.TextTransparency = 1
youDied.Parent = blackFrame

local youDiedScale = Instance.new("UIScale")
youDiedScale.Parent = youDied

local respawnButton = Instance.new("TextButton")
respawnButton.Size = UDim2.fromOffset(220, 60)
respawnButton.Text = "Respawn"
respawnButton.Font = Enum.Font.GothamSemibold
respawnButton.TextSize = 32
respawnButton.TextColor3 = Color3.new(1, 1, 1)
respawnButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
respawnButton.AutoButtonColor = true
respawnButton.Visible = false
respawnButton.BackgroundTransparency = 1
respawnButton.TextTransparency = 1
respawnButton.Parent = blackFrame

local respawnScale = Instance.new("UIScale")
respawnScale.Parent = respawnButton

local buttonCorner = Instance.new("UICorner")
buttonCorner.CornerRadius = UDim.new(0, 12)
buttonCorner.Parent = respawnButton

local buttonShadow = Instance.new("ImageLabel")
buttonShadow.AnchorPoint = Vector2.new(0.5, 0.5)
buttonShadow.Position = UDim2.fromScale(0.5, 0.5)
buttonShadow.Size = UDim2.new(1.2, 0, 1.5, 0)
buttonShadow.Image = "rbxassetid://1316045217"
buttonShadow.ImageColor3 = Color3.new(0, 0, 0)
buttonShadow.ImageTransparency = 1
buttonShadow.BackgroundTransparency = 1
buttonShadow.ZIndex = 0
buttonShadow.Parent = respawnButton

local shadowScale = Instance.new("UIScale")
shadowScale.Parent = buttonShadow

local fadeTime = 0.7
local tweenInfo = TweenInfo.new(fadeTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local function updateUIScale()
    local scale = calculateUIScale()
    youDiedScale.Scale = scale
    respawnScale.Scale = scale
    shadowScale.Scale = scale
    
    youDied.AnchorPoint = Vector2.new(0.5, 0.5)
    youDied.Position = UDim2.fromScale(0.5, 0.5)
    
    respawnButton.AnchorPoint = Vector2.new(0.5, 0.5)
    respawnButton.Position = UDim2.fromScale(0.5, 0.60)
    
    buttonShadow.AnchorPoint = Vector2.new(0.5, 0.5)
    buttonShadow.Position = UDim2.fromScale(0.5, 0.60)
end

workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateUIScale)

local function showDeathScreen()
    updateUIScale()
    TweenService:Create(blackFrame, tweenInfo, {BackgroundTransparency = 0}):Play()
    task.wait(fadeTime)
    TweenService:Create(youDied, tweenInfo, {TextTransparency = 0}):Play()
    task.wait(2)
    local slideTween = TweenService:Create(youDied, tweenInfo, {Position = UDim2.fromScale(0.5, 0.4)})
    slideTween:Play()
    respawnButton.Visible = true
    TweenService:Create(respawnButton, tweenInfo, {BackgroundTransparency = 0}):Play()
    TweenService:Create(respawnButton, tweenInfo, {TextTransparency = 0}):Play()
    TweenService:Create(buttonShadow, tweenInfo, {ImageTransparency = 0.5}):Play()
end

respawnButton.MouseButton1Click:Connect(function()
    TweenService:Create(youDied, tweenInfo, {TextTransparency = 1}):Play()
    TweenService:Create(respawnButton, tweenInfo, {BackgroundTransparency = 1}):Play()
    TweenService:Create(respawnButton, tweenInfo, {TextTransparency = 1}):Play()
    TweenService:Create(buttonShadow, tweenInfo, {ImageTransparency = 1}):Play()
    task.wait(fadeTime)
    TweenService:Create(blackFrame, tweenInfo, {BackgroundTransparency = 1}):Play()
    DeathEvent:FireServer("Respawn")
end)

DeathEvent.OnClientEvent:Connect(showDeathScreen)

updateUIScale()
