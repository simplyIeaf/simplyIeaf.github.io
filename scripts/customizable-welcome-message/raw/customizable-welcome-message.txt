-- made by @simplyIeaf1 on YouTube

local config = {
Username = "simplyieaf",
DisplayName = "Leaf",
Message = "Welcome to the game, this is a epic message made by a epic scripter.",
DisplayTime = 5
}

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local localPlayer = Players.LocalPlayer

local headshot = "rbxasset://textures/ui/GuiImagePlaceholder.png"
local success, userId = pcall(function()
    return Players:GetUserIdFromNameAsync(config.Username)
end)

if success then
    local ok, thumb = pcall(function()
        return Players:GetUserThumbnailAsync(userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
    end)
    if ok then
        headshot = thumb
    end
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "JoinMessageGui"
screenGui.Parent = localPlayer:WaitForChild("PlayerGui")

local bubble = Instance.new("Frame")
bubble.Size = UDim2.new(0.375, 0, 0.18, 0)
bubble.Position = UDim2.new(0.325, 0, 0, 0)
bubble.BackgroundColor3 = Color3.fromRGB(0,0,0)
bubble.BorderSizePixel = 0
bubble.BackgroundTransparency = 1
bubble.Visible = false
bubble.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0.15, 0)
corner.Parent = bubble

local profileImage = Instance.new("ImageLabel")
profileImage.Size = UDim2.new(0, 35, 0, 35)
profileImage.Position = UDim2.new(0.05, 0, 0.05, 0)
profileImage.BackgroundTransparency = 1
profileImage.ImageTransparency = 1
profileImage.Image = headshot
profileImage.Parent = bubble

local profileCorner = Instance.new("UICorner")
profileCorner.CornerRadius = UDim.new(1, 0)
profileCorner.Parent = profileImage

local nameLabel = Instance.new("TextLabel")
nameLabel.Size = UDim2.new(0.75, 0, 0.25, 0)
nameLabel.Position = UDim2.new(0.25, 0, 0.125, 0)
nameLabel.BackgroundTransparency = 1
nameLabel.Text = config.DisplayName
nameLabel.Font = Enum.Font.GothamBold
nameLabel.TextColor3 = Color3.fromRGB(255,255,255)
nameLabel.TextTransparency = 1
nameLabel.TextScaled = true
nameLabel.TextWrapped = true
nameLabel.TextXAlignment = Enum.TextXAlignment.Left
nameLabel.TextYAlignment = Enum.TextYAlignment.Center
nameLabel.Parent = bubble

local nameConstraint = Instance.new("UITextSizeConstraint")
nameConstraint.MaxTextSize = 22
nameConstraint.MinTextSize = 12
nameConstraint.Parent = nameLabel

local textLabel = Instance.new("TextLabel")
textLabel.Size = UDim2.new(0.75, 0, 0.625, 0)
textLabel.Position = UDim2.new(0.25, 0, 0.375, 0)
textLabel.BackgroundTransparency = 1
textLabel.Text = config.Message
textLabel.TextColor3 = Color3.fromRGB(255,255,255)
textLabel.TextWrapped = true
textLabel.TextScaled = true
textLabel.Font = Enum.Font.GothamBold
textLabel.TextTransparency = 1
textLabel.TextXAlignment = Enum.TextXAlignment.Left
textLabel.TextYAlignment = Enum.TextYAlignment.Top
textLabel.Parent = bubble

local textConstraint = Instance.new("UITextSizeConstraint")
textConstraint.MaxTextSize = 20
textConstraint.MinTextSize = 10
textConstraint.Parent = textLabel

local fadeInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local function fadeIn()
    bubble.Visible = true
    TweenService:Create(bubble, fadeInfo, {BackgroundTransparency = 0}):Play()
    TweenService:Create(textLabel, fadeInfo, {TextTransparency = 0}):Play()
    TweenService:Create(nameLabel, fadeInfo, {TextTransparency = 0}):Play()
    TweenService:Create(profileImage, fadeInfo, {ImageTransparency = 0}):Play()
end

local function fadeOut()
    local tween1 = TweenService:Create(bubble, fadeInfo, {BackgroundTransparency = 1})
    local tween2 = TweenService:Create(textLabel, fadeInfo, {TextTransparency = 1})
    local tween3 = TweenService:Create(nameLabel, fadeInfo, {TextTransparency = 1})
    local tween4 = TweenService:Create(profileImage, fadeInfo, {ImageTransparency = 1})
    
    tween1:Play()
    tween2:Play()
    tween3:Play()
    tween4:Play()
    
    tween1.Completed:Wait()
    bubble.Visible = false
end

local function showMessage()
    fadeIn()
    task.wait(config.DisplayTime)
    fadeOut()
end

showMessage()