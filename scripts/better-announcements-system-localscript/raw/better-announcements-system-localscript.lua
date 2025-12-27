-- made by @simplyIeaf1 on YouTube

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ContentProvider = game:GetService("ContentProvider")

local SPACING = 8

local player = Players.LocalPlayer
local remote = ReplicatedStorage:WaitForChild("MessageEvent")

remote.OnClientEvent:Connect(function(message)
    local existingGui = player.PlayerGui:FindFirstChild("Message")
    if existingGui then
        existingGui:Destroy()
    end
    
    local username = type(message) == "table" and message.username or "Unknown"
    local messageText = type(message) == "table" and message.text or tostring(message)
    if #messageText > 100 then
        messageText = messageText:sub(1, 97) .. "..."
    end
    
    local gui = Instance.new("ScreenGui")
    gui.Name = "Message"
    gui.IgnoreGuiInset = false
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = player:WaitForChild("PlayerGui")
    
    -- Add UIScale for responsive scaling
    local uiScale = Instance.new("UIScale")
    uiScale.Parent = gui
    
    local frame = Instance.new("Frame")
    frame.AnchorPoint = Vector2.new(0.5, 0)
    frame.Position = UDim2.new(0.5, 0, -0.2, 0)
    frame.BackgroundTransparency = 1
    frame.BorderSizePixel = 0
    frame.Size = UDim2.new(0, 400, 0, 60)
    frame.AutomaticSize = Enum.AutomaticSize.Y
    frame.ClipsDescendants = false
    frame.ZIndex = 10
    frame.Parent = gui
    
    -- Add size constraint to prevent overflow
    local sizeConstraint = Instance.new("UISizeConstraint")
    sizeConstraint.MaxSize = Vector2.new(800, math.huge)
    sizeConstraint.MinSize = Vector2.new(200, 0)
    sizeConstraint.Parent = frame
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = frame
    
    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, 12)
    padding.PaddingBottom = UDim.new(0, 12)
    padding.PaddingLeft = UDim.new(0, 16)
    padding.PaddingRight = UDim.new(0, 16)
    padding.Parent = frame
    
    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.VerticalAlignment = Enum.VerticalAlignment.Center
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, SPACING)
    layout.Parent = frame
    
    local usernameLabel = Instance.new("TextLabel")
    usernameLabel.Size = UDim2.new(0, 0, 0, 0)
    usernameLabel.AutomaticSize = Enum.AutomaticSize.XY
    usernameLabel.BackgroundTransparency = 1
    usernameLabel.Text = username
    usernameLabel.TextWrapped = false
    usernameLabel.TextScaled = false
    usernameLabel.TextSize = 20
    usernameLabel.Font = Enum.Font.GothamBold
    usernameLabel.TextColor3 = Color3.new(1, 1, 1)
    usernameLabel.TextXAlignment = Enum.TextXAlignment.Center
    usernameLabel.TextYAlignment = Enum.TextYAlignment.Center
    usernameLabel.TextTransparency = 1
    usernameLabel.ZIndex = 10
    usernameLabel.LayoutOrder = 1
    usernameLabel.Parent = frame
    
    -- Add text size constraint
    local usernameTextSize = Instance.new("UITextSizeConstraint")
    usernameTextSize.MaxTextSize = 24
    usernameTextSize.MinTextSize = 14
    usernameTextSize.Parent = usernameLabel
    
    local usernameStroke = Instance.new("UIStroke")
    usernameStroke.Color = Color3.new(0, 0, 0)
    usernameStroke.Thickness = 2
    usernameStroke.Transparency = 0
    usernameStroke.Parent = usernameLabel
    
    local verifiedIcon = Instance.new("ImageLabel")
    verifiedIcon.Size = UDim2.new(0, 20, 0, 20)
    verifiedIcon.BackgroundTransparency = 1
    verifiedIcon.ImageTransparency = 1
    verifiedIcon.ZIndex = 10
    verifiedIcon.LayoutOrder = 2
    verifiedIcon.Parent = frame
    
    -- Add aspect ratio constraint for icon
    local iconAspect = Instance.new("UIAspectRatioConstraint")
    iconAspect.AspectRatio = 1
    iconAspect.Parent = verifiedIcon
    
    local colonLabel = Instance.new("TextLabel")
    colonLabel.Size = UDim2.new(0, 0, 0, 0)
    colonLabel.AutomaticSize = Enum.AutomaticSize.XY
    colonLabel.BackgroundTransparency = 1
    colonLabel.Text = ":"
    colonLabel.TextWrapped = false
    colonLabel.TextScaled = false
    colonLabel.TextSize = 20
    colonLabel.Font = Enum.Font.GothamBold
    colonLabel.TextColor3 = Color3.new(1, 1, 1)
    colonLabel.TextXAlignment = Enum.TextXAlignment.Center
    colonLabel.TextYAlignment = Enum.TextYAlignment.Center
    colonLabel.TextTransparency = 1
    colonLabel.ZIndex = 10
    colonLabel.LayoutOrder = 3
    colonLabel.Parent = frame
    
    local colonTextSize = Instance.new("UITextSizeConstraint")
    colonTextSize.MaxTextSize = 24
    colonTextSize.MinTextSize = 14
    colonTextSize.Parent = colonLabel
    
    local colonStroke = Instance.new("UIStroke")
    colonStroke.Color = Color3.new(0, 0, 0)
    colonStroke.Thickness = 2
    colonStroke.Transparency = 0
    colonStroke.Parent = colonLabel
    
    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(0, 0, 0, 0)
    textLabel.AutomaticSize = Enum.AutomaticSize.XY
    textLabel.BackgroundTransparency = 1
    textLabel.Text = " " .. messageText
    textLabel.TextWrapped = true
    textLabel.TextScaled = false
    textLabel.TextSize = 20
    textLabel.Font = Enum.Font.GothamBold
    textLabel.TextColor3 = Color3.new(1, 1, 1)
    textLabel.TextXAlignment = Enum.TextXAlignment.Left
    textLabel.TextYAlignment = Enum.TextYAlignment.Center
    textLabel.TextTransparency = 1
    textLabel.ZIndex = 10
    textLabel.LayoutOrder = 4
    textLabel.Parent = frame
    
    -- Add max size constraint for text to prevent overflow
    local textSizeConstraint = Instance.new("UISizeConstraint")
    textSizeConstraint.MaxSize = Vector2.new(500, math.huge)
    textSizeConstraint.Parent = textLabel
    
    local textTextSize = Instance.new("UITextSizeConstraint")
    textTextSize.MaxTextSize = 24
    textTextSize.MinTextSize = 14
    textTextSize.Parent = textLabel
    
    local textStroke = Instance.new("UIStroke")
    textStroke.Color = Color3.new(0, 0, 0)
    textStroke.Thickness = 2
    textStroke.Transparency = 0
    textStroke.Parent = textLabel
    
    local assetId = "105931397495778"
    local primaryAsset = "rbxthumb://type=Asset&id=" .. assetId .. "&w=150&h=150"
    local fallbackAsset = "rbxthumb://type=Asset&id=" .. assetId .. "&w=150&h=150"
    local success, _ = pcall(function()
        ContentProvider:PreloadAsync({primaryAsset}, 2)
    end)
    verifiedIcon.Image = success and primaryAsset or fallbackAsset
    
    local slideIn = TweenService:Create(frame, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = UDim2.new(0.5, 0, 0.05, 0)})
    local iconFadeIn = TweenService:Create(verifiedIcon, TweenInfo.new(0.5), {ImageTransparency = 0})
    local usernameFadeIn = TweenService:Create(usernameLabel, TweenInfo.new(0.5), {TextTransparency = 0})
    local colonFadeIn = TweenService:Create(colonLabel, TweenInfo.new(0.5), {TextTransparency = 0})
    local textFadeIn = TweenService:Create(textLabel, TweenInfo.new(0.5), {TextTransparency = 0})
    
    slideIn:Play()
    iconFadeIn:Play()
    usernameFadeIn:Play()
    colonFadeIn:Play()
    textFadeIn:Play()
    
    task.wait(7)
    
    local slideOut = TweenService:Create(frame, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Position = UDim2.new(0.5, 0, -0.2, 0)})
    local iconFadeOut = TweenService:Create(verifiedIcon, TweenInfo.new(0.5), {ImageTransparency = 1})
    local usernameFadeOut = TweenService:Create(usernameLabel, TweenInfo.new(0.5), {TextTransparency = 1})
    local colonFadeOut = TweenService:Create(colonLabel, TweenInfo.new(0.5), {TextTransparency = 1})
    local textFadeOut = TweenService:Create(textLabel, TweenInfo.new(0.5), {TextTransparency = 1})
    
    slideOut:Play()
    iconFadeOut:Play()
    usernameFadeOut:Play()
    colonFadeOut:Play()
    textFadeOut:Play()
    
    slideOut.Completed:Connect(function()
        task.defer(function()
            gui:Destroy()
        end)
    end)
end)