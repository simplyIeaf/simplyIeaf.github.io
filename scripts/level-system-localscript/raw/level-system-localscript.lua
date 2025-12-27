-- made by @simplyIeaf1 on youtube

local player = game.Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local camera = workspace.CurrentCamera
local TextChatService = game:GetService("TextChatService")
 
local UpdateLevelUI = ReplicatedStorage:WaitForChild("UpdateLevelUI")
local GetLevelData = ReplicatedStorage:WaitForChild("GetLevelData")
 
local levelBarState = {
isHidden = false,
screenGui = nil,
mainFrame = nil
}
 
local function CreateLevelBar()
    if player.PlayerGui:FindFirstChild("LevelBarGui") then
        player.PlayerGui.LevelBarGui:Destroy()
    end
    
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "LevelBarGui"
    screenGui.Parent = player.PlayerGui
    screenGui.ResetOnSpawn = false
    
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "LevelBarFrame"
    mainFrame.Size = UDim2.new(0.23, 0, 0.05, 0)
    mainFrame.Position = UDim2.new(0.5, 0, 0, 10)
    mainFrame.AnchorPoint = Vector2.new(0.5, 0)
    mainFrame.BackgroundColor3 = Color3.fromRGB(128, 128, 128)
    mainFrame.BackgroundTransparency = 0.5
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = screenGui
    
    local uiCorner = Instance.new("UICorner")
    uiCorner.CornerRadius = UDim.new(0, 5)
    uiCorner.Parent = mainFrame
    
    local uiStroke = Instance.new("UIStroke")
    uiStroke.Color = Color3.fromRGB(0, 0, 0)
    uiStroke.Transparency = 0
    uiStroke.Parent = mainFrame
    
    local originalThickness = 10
    local referenceSize = Vector2.new(1920, 1080)
    
    local function getMinDim(v)
        return math.min(v.X, v.Y)
    end
    
    local function updateStroke()
        local scale = getMinDim(camera.ViewportSize) / getMinDim(referenceSize)
        uiStroke.Thickness = originalThickness * scale
    end
    
    updateStroke()
    camera:GetPropertyChangedSignal("ViewportSize"):Connect(updateStroke)
    
    local progressFrame = Instance.new("Frame")
    progressFrame.Name = "Progress"
    progressFrame.Size = UDim2.new(0, 0, 1, 0)
    progressFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 0)
    progressFrame.BorderSizePixel = 0
    progressFrame.Parent = mainFrame
    
    local progressCorner = Instance.new("UICorner")
    progressCorner.CornerRadius = UDim.new(0, 5)
    progressCorner.Parent = progressFrame
    
    local verticalBar = Instance.new("Frame")
    verticalBar.Name = "VerticalBar"
    verticalBar.Size = UDim2.new(0.05, 0, 0.5, 0)
    verticalBar.Position = UDim2.new(0.5, 0, 0.5, 0)
    verticalBar.AnchorPoint = Vector2.new(0.5, 0.5)
    verticalBar.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    verticalBar.BackgroundTransparency = 1
    verticalBar.BorderSizePixel = 0
    verticalBar.Parent = mainFrame
    
    local verticalBarProgress = Instance.new("Frame")
    verticalBarProgress.Name = "VerticalBarProgress"
    verticalBarProgress.Size = UDim2.new(0, 0, 1, 0)
    verticalBarProgress.BackgroundColor3 = Color3.fromRGB(255, 255, 0)
    verticalBarProgress.BorderSizePixel = 0
    verticalBarProgress.Parent = verticalBar
    verticalBarProgress.Transparency = 1
    
    local verticalBarCorner = Instance.new("UICorner")
    verticalBarCorner.CornerRadius = UDim.new(0, 5)
    verticalBarCorner.Parent = verticalBar
    
    local verticalBarProgressCorner = Instance.new("UICorner")
    verticalBarProgressCorner.CornerRadius = UDim.new(0, 4)
    verticalBarProgressCorner.Parent = verticalBarProgress
    
    local levelLabel = Instance.new("TextLabel")
    levelLabel.Name = "LevelLabel"
    levelLabel.Size = UDim2.new(1, 0, 1, 0)
    levelLabel.BackgroundTransparency = 1
    levelLabel.TextColor3 = Color3.fromRGB(0, 0, 0)
    levelLabel.TextScaled = true
    levelLabel.Font = Enum.Font.SourceSansBold
    levelLabel.Text = "Level 1 (0/100)"
    levelLabel.Parent = mainFrame
    
    levelBarState.screenGui = screenGui
    levelBarState.mainFrame = mainFrame
    
    local function UpdateUI(level, currentXP, maxXP)
        if type(level) ~= "number" or type(currentXP) ~= "number" or type(maxXP) ~= "number" then return end
        local progress = math.clamp(currentXP / maxXP, 0, 1)
        local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Linear)
        local goal = {Size = UDim2.new(progress, 0, 1, 0)}
        TweenService:Create(progressFrame, tweenInfo, goal):Play()
        TweenService:Create(verticalBarProgress, tweenInfo, goal):Play()
        levelLabel.Text = "Level " .. math.floor(level) .. " (" .. math.floor(currentXP) .. "/" .. math.floor(maxXP) .. ")"
    end
    
    UpdateLevelUI.OnClientEvent:Connect(UpdateUI)
    
    local level, currentXP, maxXP = GetLevelData:InvokeServer()
    if level and currentXP and maxXP then
        UpdateUI(level, currentXP, maxXP)
    end
end
 
local hideCommand = Instance.new("TextChatCommand")
hideCommand.Name = "HideLevelBarCommand"
hideCommand.PrimaryAlias = "/hidelevelbar"
hideCommand.Parent = TextChatService
 
hideCommand.Triggered:Connect(function(textSource, message)
    if levelBarState.isHidden or not levelBarState.mainFrame then return end
    levelBarState.isHidden = true
    levelBarState.mainFrame.Visible = false
end)
 
local showCommand = Instance.new("TextChatCommand")
showCommand.Name = "ShowLevelBarCommand"
showCommand.PrimaryAlias = "/showlevelbar"
showCommand.Parent = TextChatService
 
showCommand.Triggered:Connect(function(textSource, message)
    if not levelBarState.isHidden or not levelBarState.mainFrame then return end
    levelBarState.isHidden = false
    levelBarState.mainFrame.Visible = true
end)
 
player.CharacterAdded:Connect(function()
    CreateLevelBar()
end)
 
if player.Character then
    CreateLevelBar()
end
 
player.CharacterRemoving:Connect(function()
    if player.PlayerGui:FindFirstChild("LevelBarGui") then
        player.PlayerGui.LevelBarGui:Destroy()
    end
end)
