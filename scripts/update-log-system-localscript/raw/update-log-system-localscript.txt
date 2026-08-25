-- made by @simplyIeaf1 on YouTube

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local GetLogsRF = ReplicatedStorage:WaitForChild("GetUpdateLogs")

local ok, logs, shouldShow, gameName = pcall(GetLogsRF.InvokeServer, GetLogsRF)
if not ok or not logs or not shouldShow then return end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "UpdateLogGUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local uiScale = Instance.new("UIScale")
uiScale.Scale = 1
uiScale.Parent = screenGui

local function updateScale()
    local camera = workspace.CurrentCamera
    if not camera then return end
    local size = camera.ViewportSize
    local baseWidth, baseHeight = 1920, 1080
    local scaleX = size.X / baseWidth
    local scaleY = size.Y / baseHeight
    local scale = math.min(scaleX, scaleY)
    scale = math.max(scale, 0.8)
    uiScale.Scale = scale
end

updateScale()
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale)

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.fromScale(0.55, 0.55)
mainFrame.Position = UDim2.fromScale(0.5, 0.5)
mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
mainFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
mainFrame.BackgroundTransparency = 0.4
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 14)
mainCorner.Parent = mainFrame

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(0.5, 0, 0, 36)
titleLabel.Position = UDim2.new(0, 16, 0, 16)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "Update Log"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextSize = 28
titleLabel.Font = Enum.Font.ArialBold
titleLabel.RichText = true
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = mainFrame

local titleStroke = Instance.new("UIStroke")
titleStroke.Thickness = 2.5
titleStroke.Color = Color3.fromRGB(0, 0, 0)
titleStroke.Parent = titleLabel

local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.new(0, 32, 0, 32)
closeButton.Position = UDim2.new(1, -48, 0, 20)
closeButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
closeButton.BackgroundTransparency = 0.3
closeButton.BorderSizePixel = 0
closeButton.Text = "X"
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.TextSize = 20
closeButton.Font = Enum.Font.ArialBold
closeButton.Parent = mainFrame

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 8)
closeCorner.Parent = closeButton

local closeStroke = Instance.new("UIStroke")
closeStroke.Thickness = 2
closeStroke.Color = Color3.fromRGB(0, 0, 0)
closeStroke.Parent = closeButton

closeButton.MouseButton1Click:Connect(function()
    screenGui:Destroy()
end)

local innerFrame = Instance.new("Frame")
innerFrame.Size = UDim2.new(1, -24, 1, -90)
innerFrame.Position = UDim2.new(0, 12, 0, 70)
innerFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
innerFrame.BackgroundTransparency = 0.25
innerFrame.BorderSizePixel = 0
innerFrame.ClipsDescendants = true
innerFrame.Parent = mainFrame

local innerCorner = Instance.new("UICorner")
innerCorner.CornerRadius = UDim.new(0, 10)
innerCorner.Parent = innerFrame

local gameNameLabel = Instance.new("TextLabel")
gameNameLabel.Size = UDim2.new(1, 0, 0, 40)
gameNameLabel.BackgroundTransparency = 1
gameNameLabel.Text = gameName
gameNameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
gameNameLabel.TextSize = 32
gameNameLabel.Font = Enum.Font.ArialBold
gameNameLabel.RichText = true
gameNameLabel.TextXAlignment = Enum.TextXAlignment.Center
gameNameLabel.Parent = innerFrame

local gameStroke = Instance.new("UIStroke")
gameStroke.Thickness = 3
gameStroke.Color = Color3.fromRGB(0, 0, 0)
gameStroke.Parent = gameNameLabel

local scrollingFrame = Instance.new("ScrollingFrame")
scrollingFrame.Size = UDim2.new(1, 0, 1, -50)
scrollingFrame.Position = UDim2.new(0, 0, 0, 50)
scrollingFrame.BackgroundTransparency = 1
scrollingFrame.BorderSizePixel = 0
scrollingFrame.ScrollBarThickness = 5
scrollingFrame.ScrollBarImageColor3 = Color3.fromRGB(200, 200, 200)
scrollingFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
scrollingFrame.Parent = innerFrame

local container = Instance.new("Frame")
container.Name = "Container"
container.Size = UDim2.new(1, 0, 0, 0)
container.BackgroundTransparency = 1
container.AutomaticSize = Enum.AutomaticSize.Y
container.Parent = scrollingFrame

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 12)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = container

local scrollPadding = Instance.new("UIPadding")
scrollPadding.PaddingLeft = UDim.new(0, 12)
scrollPadding.PaddingRight = UDim.new(0, 12)
scrollPadding.PaddingTop = UDim.new(0, 8)
scrollPadding.PaddingBottom = UDim.new(0, 8)
scrollPadding.Parent = container

local function createLogEntry(entry)
    local entryFrame = Instance.new("Frame")
    entryFrame.Size = UDim2.new(1, 0, 0, 0)
    entryFrame.BackgroundTransparency = 1
    entryFrame.AutomaticSize = Enum.AutomaticSize.Y
    entryFrame.LayoutOrder = -entry.version
    entryFrame.Parent = container
    
    local entryLayout = Instance.new("UIListLayout")
    entryLayout.Padding = UDim.new(0, 4)
    entryLayout.SortOrder = Enum.SortOrder.LayoutOrder
    entryLayout.Parent = entryFrame
    
    local dateLabel = Instance.new("TextLabel")
    dateLabel.Size = UDim2.new(1, 0, 0, 24)
    dateLabel.BackgroundTransparency = 1
    dateLabel.Text = entry.date
    dateLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    dateLabel.TextTransparency = 0.25
    dateLabel.TextSize = 18
    dateLabel.Font = Enum.Font.ArialBold
    dateLabel.RichText = true
    dateLabel.TextXAlignment = Enum.TextXAlignment.Left
    dateLabel.LayoutOrder = 1
    dateLabel.Parent = entryFrame
    
    local dateStroke = Instance.new("UIStroke")
    dateStroke.Thickness = 1.8
    dateStroke.Color = Color3.fromRGB(0, 0, 0)
    dateStroke.Transparency = 0.3
    dateStroke.Parent = dateLabel
    
    local infoLabel = Instance.new("TextLabel")
    infoLabel.Size = UDim2.new(1, 0, 0, 0)
    infoLabel.BackgroundTransparency = 1
    infoLabel.Text = entry.info
    infoLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    infoLabel.TextTransparency = 0.15
    infoLabel.TextSize = 16
    infoLabel.Font = Enum.Font.ArialBold
    infoLabel.RichText = true
    infoLabel.TextXAlignment = Enum.TextXAlignment.Left
    infoLabel.TextWrapped = true
    infoLabel.TextYAlignment = Enum.TextYAlignment.Top
    infoLabel.AutomaticSize = Enum.AutomaticSize.Y
    infoLabel.LayoutOrder = 2
    infoLabel.Parent = entryFrame
    
    local infoStroke = Instance.new("UIStroke")
    infoStroke.Thickness = 1.5
    infoStroke.Color = Color3.fromRGB(0, 0, 0)
    infoStroke.Transparency = 0.25
    infoStroke.Parent = infoLabel
end

table.sort(logs, function(a, b) return a.version > b.version end)
    for _, log in ipairs(logs) do
        createLogEntry(log)
    end
    
    task.wait(0.1)
    scrollingFrame.CanvasPosition = Vector2.new(0, 0)
