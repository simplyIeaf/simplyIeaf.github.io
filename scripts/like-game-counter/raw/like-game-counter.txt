local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")

local UniverseId = game.GameId
local TargetGoal = 1000
local SubText = 'Guaranteed <font color="#363636">Secret</font> at'

local SGui = script.Parent

local function SyncResolution()
    local Adornee = SGui.Adornee or SGui.Parent
    if Adornee and Adornee:IsA("BasePart") then
        local Size = Adornee.Size
        local Face = SGui.Face
        local Width, Height = Size.X, Size.Y
        
        if Face == Enum.NormalId.Top or Face == Enum.NormalId.Bottom then
            Width, Height = Size.X, Size.Z
        elseif Face == Enum.NormalId.Left or Face == Enum.NormalId.Right then
            Width, Height = Size.Z, Size.Y
        end
        
        local ResolutionBase = 800
        SGui.CanvasSize = Vector2.new(ResolutionBase, ResolutionBase * (Height / Width))
    end
end
SyncResolution()

local MainBg = Instance.new("Frame")
MainBg.Size = UDim2.fromScale(1, 1)
MainBg.BackgroundColor3 = Color3.fromRGB(40, 45, 55)
MainBg.BorderSizePixel = 0
MainBg.Parent = SGui

local CenterLayout = Instance.new("UIListLayout")
CenterLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
CenterLayout.VerticalAlignment = Enum.VerticalAlignment.Center
CenterLayout.SortOrder = Enum.SortOrder.LayoutOrder
CenterLayout.Padding = UDim.new(0.02, 0)
CenterLayout.Parent = MainBg

local Title = Instance.new("TextLabel")
Title.LayoutOrder = 1
Title.Size = UDim2.fromScale(1, 0.15)
Title.BackgroundTransparency = 1
Title.Font = Enum.Font.FredokaOne
Title.Text = "LIKE THE GAME"
Title.TextColor3 = Color3.new(1, 1, 1)
Title.TextStrokeTransparency = 0
Title.TextStrokeColor3 = Color3.new(0, 0, 0)
Title.TextScaled = false
Title.TextSize = 65
Title.RichText = true
Title.Parent = MainBg

local BarContainer = Instance.new("Frame")
BarContainer.LayoutOrder = 2
BarContainer.Size = UDim2.fromScale(0.9, 0.16)
BarContainer.BackgroundColor3 = Color3.fromRGB(40, 45, 55)
BarContainer.BorderSizePixel = 0
BarContainer.Parent = MainBg

local BarStroke = Instance.new("UIStroke")
BarStroke.Color = Color3.new(1, 1, 1)
BarStroke.Thickness = 4
BarStroke.Parent = BarContainer

local UICornerBar = Instance.new("UICorner")
UICornerBar.CornerRadius = UDim.new(0.1, 0)
UICornerBar.Parent = BarContainer

local BarFill = Instance.new("Frame")
BarFill.Size = UDim2.fromScale(0, 1)
BarFill.BackgroundColor3 = Color3.new(1, 1, 1)
BarFill.BorderSizePixel = 0
BarFill.Parent = BarContainer

local BarGradient = Instance.new("UIGradient")
BarGradient.Color = ColorSequence.new({
ColorSequenceKeypoint.new(0, Color3.fromRGB(50, 255, 50)),
ColorSequenceKeypoint.new(1, Color3.fromRGB(15, 120, 15))
})
BarGradient.Rotation = 90
BarGradient.Parent = BarFill

local UICornerFill = Instance.new("UICorner")
UICornerFill.CornerRadius = UDim.new(0.1, 0)
UICornerFill.Parent = BarFill

local function FormatNumber(n)
    n = tostring(math.floor(n))
    return n:reverse():gsub("%d%d%d", "%1,"):reverse():gsub("^,", "")
end

local BarText = Instance.new("TextLabel")
BarText.Size = UDim2.fromScale(1, 1)
BarText.BackgroundTransparency = 1
BarText.Font = Enum.Font.FredokaOne
BarText.Text = "0 / " .. FormatNumber(TargetGoal)
BarText.TextColor3 = Color3.new(1, 1, 1)
BarText.TextStrokeTransparency = 0
BarText.TextStrokeColor3 = Color3.new(0, 0, 0)
BarText.TextSize = 65
BarText.ZIndex = 2
BarText.Parent = BarContainer

local TextGroup = Instance.new("Frame")
TextGroup.LayoutOrder = 3
TextGroup.Size = UDim2.fromScale(1, 0.25)
TextGroup.BackgroundTransparency = 1
TextGroup.Parent = MainBg

local TextGroupLayout = Instance.new("UIListLayout")
TextGroupLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
TextGroupLayout.VerticalAlignment = Enum.VerticalAlignment.Top
TextGroupLayout.Padding = UDim.new(0, -2)
TextGroupLayout.Parent = TextGroup

local UnderText1 = Instance.new("TextLabel")
UnderText1.Size = UDim2.fromScale(1, 0.4)
UnderText1.BackgroundTransparency = 1
UnderText1.Font = Enum.Font.FredokaOne
UnderText1.Text = SubText
UnderText1.TextColor3 = Color3.new(1, 1, 1)
UnderText1.TextStrokeTransparency = 0
UnderText1.TextStrokeColor3 = Color3.new(0, 0, 0)
UnderText1.TextSize = 50
UnderText1.RichText = true
UnderText1.Parent = TextGroup

local UnderText2 = Instance.new("TextLabel")
UnderText2.Size = UDim2.fromScale(1, 0.4)
UnderText2.BackgroundTransparency = 1
UnderText2.Font = Enum.Font.FredokaOne
UnderText2.Text = FormatNumber(TargetGoal) .. " LIKES"
UnderText2.TextColor3 = Color3.fromRGB(50, 255, 50)
UnderText2.TextStrokeTransparency = 0
UnderText2.TextStrokeColor3 = Color3.new(0, 0, 0)
UnderText2.TextSize = 55
UnderText2.RichText = true
UnderText2.Parent = TextGroup

local function UpdateStats()
    if UniverseId == 0 then return end
    local FetchUrl = string.format("https://games.roproxy.com/v1/games/%d/votes", UniverseId)
    local ok, data = pcall(function()
        return HttpService:RequestAsync({Url = FetchUrl, Method = "GET"})
    end)
    if ok and data.StatusCode >= 200 and data.StatusCode < 300 then
        local decodeOk, decoded = pcall(HttpService.JSONDecode, HttpService, data.Body)
        if decodeOk then
            local currentLikes = decoded.upVotes or 0
            BarText.Text = FormatNumber(currentLikes) .. " / " .. FormatNumber(TargetGoal)
            local fillAlpha = math.clamp(currentLikes / TargetGoal, 0, 1)
            TweenService:Create(BarFill, TweenInfo.new(1.5, Enum.EasingStyle.Quad), {Size = UDim2.fromScale(fillAlpha, 1)}):Play()
        end
    end
end

task.spawn(function()
    while true do
        UpdateStats()
        task.wait(7)
    end
end)
