local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MyUpdates = {
    {
        Date = "10/24/2023",
        UpdateName = "testing",
        UpdateInfo = "testing the update log sys, that's it lol"
    }
}

local TempPart = script.Parent.Parent
TempPart.Color = Color3.fromRGB(12, 12, 12)
TempPart.Material = Enum.Material.SmoothPlastic

local BindableEvent = Instance.new("BindableEvent")
BindableEvent.Name = "UpdateLogEvent"
BindableEvent.Parent = ReplicatedStorage

local studTextureId = "rbxassetid://1013778272" 

local SurfaceGui = script.Parent

local Background = Instance.new("Frame")
Background.Name = "Background"
Background.Parent = SurfaceGui
Background.Size = UDim2.new(1, 0, 1, 0)
Background.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
Background.BorderSizePixel = 0

local bgStroke = Instance.new("UIStroke")
bgStroke.Thickness = 4
bgStroke.Parent = Background

local bgStuds = Instance.new("ImageLabel")
bgStuds.Size = UDim2.new(1, 0, 1, 0)
bgStuds.BackgroundTransparency = 1
bgStuds.Image = studTextureId
bgStuds.ImageColor3 = Color3.fromRGB(40, 40, 40)
bgStuds.ImageTransparency = 0.5
bgStuds.ScaleType = Enum.ScaleType.Tile
bgStuds.TileSize = UDim2.new(0, 50, 0, 50)
bgStuds.Parent = Background

local Header = Instance.new("Frame")
Header.Name = "Header"
Header.Parent = Background
Header.Size = UDim2.new(1, 0, 0, 50)
Header.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Header.BorderSizePixel = 0
Header.ZIndex = 2

local topGradient = Instance.new("UIGradient")
topGradient.Color = ColorSequence.new(Color3.fromRGB(40, 220, 40), Color3.fromRGB(15, 120, 15))
topGradient.Rotation = 90
topGradient.Parent = Header

local topStuds = Instance.new("ImageLabel")
topStuds.Size = UDim2.new(1, 0, 1, 0)
topStuds.BackgroundTransparency = 1
topStuds.Image = studTextureId
topStuds.ImageColor3 = Color3.fromRGB(40, 40, 40)
topStuds.ImageTransparency = 0.2
topStuds.ScaleType = Enum.ScaleType.Tile
topStuds.TileSize = UDim2.new(0, 50, 0, 50)
topStuds.ZIndex = 2
topStuds.Parent = Header

local topStroke = Instance.new("UIStroke")
topStroke.Thickness = 4
topStroke.Parent = Header

local Title = Instance.new("TextLabel")
Title.Name = "Title"
Title.Parent = Header
Title.Size = UDim2.new(1, 0, 1, 0)
Title.Position = UDim2.new(0, 0, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "Update Logs"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.FredokaOne
Title.TextScaled = true
Title.ZIndex = 4

local titleConstraint = Instance.new("UITextSizeConstraint")
titleConstraint.MaxTextSize = 28
titleConstraint.MinTextSize = 8
titleConstraint.Parent = Title

local titlePadding = Instance.new("UIPadding")
titlePadding.PaddingTop = UDim.new(0, 8)
titlePadding.PaddingBottom = UDim.new(0, 8)
titlePadding.Parent = Title

local titleStroke = Instance.new("UIStroke")
titleStroke.Thickness = 3
titleStroke.Parent = Title

local MainFrame = Instance.new("Frame")
MainFrame.Name = "List"
MainFrame.Parent = Background
MainFrame.Size = UDim2.new(1, 0, 1, -140)
MainFrame.Position = UDim2.new(0, 0, 0, 60)
MainFrame.BackgroundTransparency = 1
MainFrame.BorderSizePixel = 0
MainFrame.ZIndex = 2

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Parent = MainFrame
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 10)
UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

local gridPadding = Instance.new("UIPadding")
gridPadding.PaddingTop = UDim.new(0, 10)
gridPadding.PaddingBottom = UDim.new(0, 10)
gridPadding.Parent = MainFrame

local NavFrame = Instance.new("Frame")
NavFrame.Name = "Navigation"
NavFrame.Parent = Background
NavFrame.Size = UDim2.new(1, 0, 0, 45)
NavFrame.Position = UDim2.new(0, 0, 1, -70)
NavFrame.BackgroundTransparency = 1
NavFrame.ZIndex = 3

local LeftButton = Instance.new("TextButton")
LeftButton.Name = "LeftButton"
LeftButton.Parent = NavFrame
LeftButton.Size = UDim2.new(0, 50, 1, 0)
LeftButton.Position = UDim2.new(0.2, 0, 0, 0)
LeftButton.BackgroundColor3 = Color3.fromRGB(40, 220, 40)
LeftButton.TextColor3 = Color3.fromRGB(255, 255, 255)
LeftButton.Font = Enum.Font.FredokaOne
LeftButton.TextScaled = true
LeftButton.Text = "<"

local leftCorner = Instance.new("UICorner")
leftCorner.CornerRadius = UDim.new(0, 8)
leftCorner.Parent = LeftButton

local leftStroke = Instance.new("UIStroke")
leftStroke.Thickness = 3
leftStroke.Parent = LeftButton

local PageText = Instance.new("TextLabel")
PageText.Name = "PageText"
PageText.Parent = NavFrame
PageText.Size = UDim2.new(0.3, 0, 1, 0)
PageText.Position = UDim2.new(0.35, 0, 0, 0)
PageText.BackgroundTransparency = 1
PageText.TextColor3 = Color3.fromRGB(255, 255, 255)
PageText.Font = Enum.Font.FredokaOne
PageText.TextScaled = true
PageText.Text = "1 / 1"

local pageTextStroke = Instance.new("UIStroke")
pageTextStroke.Thickness = 3
pageTextStroke.Parent = PageText

local RightButton = Instance.new("TextButton")
RightButton.Name = "RightButton"
RightButton.Parent = NavFrame
RightButton.Size = UDim2.new(0, 50, 1, 0)
RightButton.Position = UDim2.new(0.7, 0, 0, 0)
RightButton.BackgroundColor3 = Color3.fromRGB(40, 220, 40)
RightButton.TextColor3 = Color3.fromRGB(255, 255, 255)
RightButton.Font = Enum.Font.FredokaOne
RightButton.TextScaled = true
RightButton.Text = ">"

local rightCorner = Instance.new("UICorner")
rightCorner.CornerRadius = UDim.new(0, 8)
rightCorner.Parent = RightButton

local rightStroke = Instance.new("UIStroke")
rightStroke.Thickness = 3
rightStroke.Parent = RightButton

local Template = Instance.new("Frame")
Template.Name = "Template"
Template.Size = UDim2.new(0.94, 0, 0, 110)
Template.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
Template.BackgroundTransparency = 0.5
Template.BorderSizePixel = 0

local TemplateCorner = Instance.new("UICorner")
TemplateCorner.CornerRadius = UDim.new(0, 8)
TemplateCorner.Parent = Template

local templateStroke = Instance.new("UIStroke")
templateStroke.Thickness = 3
templateStroke.Parent = Template

local templateGradient = Instance.new("UIGradient")
templateGradient.Color = ColorSequence.new({
ColorSequenceKeypoint.new(0, Color3.fromRGB(40, 40, 40)),
ColorSequenceKeypoint.new(1, Color3.fromRGB(15, 15, 15)),
})
templateGradient.Rotation = 135
templateGradient.Parent = Template

local cellStuds = Instance.new("ImageLabel")
cellStuds.Size = UDim2.new(1, 0, 1, 0)
cellStuds.BackgroundTransparency = 1
cellStuds.Image = studTextureId
cellStuds.ImageTransparency = 0.7
cellStuds.ScaleType = Enum.ScaleType.Tile
cellStuds.TileSize = UDim2.new(0, 40, 0, 40)
cellStuds.ZIndex = 3
cellStuds.Parent = Template

local UpdateNameLabel = Instance.new("TextLabel")
UpdateNameLabel.Name = "UpdateName"
UpdateNameLabel.Parent = Template
UpdateNameLabel.Size = UDim2.new(0.65, 0, 0.22, 0)
UpdateNameLabel.Position = UDim2.new(0.02, 0, 0.06, 0)
UpdateNameLabel.BackgroundTransparency = 1
UpdateNameLabel.TextColor3 = Color3.fromRGB(200, 255, 200)
UpdateNameLabel.Font = Enum.Font.FredokaOne
UpdateNameLabel.TextScaled = true
UpdateNameLabel.TextXAlignment = Enum.TextXAlignment.Left
UpdateNameLabel.ZIndex = 4

local nameStroke = Instance.new("UIStroke")
nameStroke.Thickness = 2
nameStroke.Parent = UpdateNameLabel

local DateLabel = Instance.new("TextLabel")
DateLabel.Name = "DateLabel"
DateLabel.Parent = Template
DateLabel.Size = UDim2.new(0.3, 0, 0.18, 0)
DateLabel.Position = UDim2.new(0.68, 0, 0.06, 0)
DateLabel.BackgroundTransparency = 1
DateLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
DateLabel.Font = Enum.Font.FredokaOne
DateLabel.TextScaled = true
DateLabel.TextXAlignment = Enum.TextXAlignment.Right
DateLabel.ZIndex = 4

local dateStroke = Instance.new("UIStroke")
dateStroke.Thickness = 2
dateStroke.Parent = DateLabel

local InfoLabel = Instance.new("TextLabel")
InfoLabel.Name = "InfoLabel"
InfoLabel.Parent = Template
InfoLabel.Size = UDim2.new(0.96, 0, 0.62, 0)
InfoLabel.Position = UDim2.new(0.02, 0, 0.32, 0)
InfoLabel.BackgroundTransparency = 1
InfoLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
InfoLabel.Font = Enum.Font.SourceSansBold
InfoLabel.TextSize = 20
InfoLabel.TextWrapped = true
InfoLabel.TextXAlignment = Enum.TextXAlignment.Left
InfoLabel.TextYAlignment = Enum.TextYAlignment.Top
InfoLabel.ZIndex = 4

local LogsData = {}
local CurrentPage = 1

local function RenderPage()
    for _, v in pairs(MainFrame:GetChildren()) do
        if v:IsA("Frame") then
            v:Destroy()
        end
    end
    
    local TotalPages = math.ceil(#LogsData / 3)
    if TotalPages == 0 then TotalPages = 1 end
    
    if CurrentPage > TotalPages then CurrentPage = TotalPages end
    if CurrentPage < 1 then CurrentPage = 1 end
    
    PageText.Text = CurrentPage .. " / " .. TotalPages
    
    local StartIndex = (CurrentPage - 1) * 3 + 1
    local EndIndex = math.min(CurrentPage * 3, #LogsData)
    
    for i = StartIndex, EndIndex do
        local LogData = LogsData[i]
        if LogData then
            local Clone = Template:Clone()
            Clone.LayoutOrder = i
            Clone.UpdateName.Text = LogData.UpdateName
            Clone.DateLabel.Text = LogData.Date
            
            local ParsedInfo = string.gsub(LogData.UpdateInfo, "/n", "\n")
            Clone.InfoLabel.Text = ParsedInfo
            
            Clone.Parent = MainFrame
        end
    end
end

LeftButton.MouseButton1Click:Connect(function()
    if CurrentPage > 1 then
        CurrentPage = CurrentPage - 1
        RenderPage()
    end
end)

RightButton.MouseButton1Click:Connect(function()
    local TotalPages = math.ceil(#LogsData / 3)
    if CurrentPage < TotalPages then
        CurrentPage = CurrentPage + 1
        RenderPage()
    end
end)

BindableEvent.Event:Connect(function(IncomingLogs)
    local ReversedLogs = {}
    for i = #IncomingLogs, 1, -1 do
        table.insert(ReversedLogs, IncomingLogs[i])
    end
    
    LogsData = ReversedLogs
    CurrentPage = 1
    RenderPage()
end)

task.wait(1)
BindableEvent:Fire(MyUpdates)