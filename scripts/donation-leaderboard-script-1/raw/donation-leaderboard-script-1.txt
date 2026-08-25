local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local MarketplaceService = game:GetService("MarketplaceService")
local ServerStorage = game:GetService("ServerStorage")

-- keep in mind you also have to manually replace the existing developer product id's with your own
local DonationButtons = {
{Name = "10", ID = 3585769207, Amount = 10},
{Name = "50", ID = 3585772416, Amount = 50},
{Name = "100", ID = 3585772965, Amount = 100},
{Name = "500", ID = 3585773319, Amount = 500}, 
{Name = "1000", ID = 3585773671, Amount = 1000}, 
{Name = "5000", ID = 3585885587, Amount = 5000}, 
{Name = "10000", ID = 3585774277, Amount = 10000}, 
{Name = "50000", ID = 3585774609, Amount = 50000}, 
{Name = "100000", ID = 3585775569, Amount = 100000}, 
{Name = "500000", ID = 3585789017, Amount = 500000}, 
{Name = "1000000", ID = 3585886560, Amount = 1000000}
}

local GlobalLeaderboardB = DataStoreService:GetOrderedDataStore("DonationLeaderboard_Live1")
local TempPart = script.Parent

local Bindable = Instance.new("BindableEvent")
Bindable.Name = "AddDonationButtonEvent"
Bindable.Parent = ServerStorage

local studTextureId = "rbxassetid://1013778272"

local SurfaceGui = Instance.new("SurfaceGui")
SurfaceGui.Parent = TempPart
SurfaceGui.Face = Enum.NormalId.Front
SurfaceGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
SurfaceGui.PixelsPerStud = 50

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
Title.Text = "Top Donators"
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

local MainFrame = Instance.new("ScrollingFrame")
MainFrame.Name = "List"
MainFrame.Parent = Background
MainFrame.Size = UDim2.new(1, 0, 1, -60)
MainFrame.Position = UDim2.new(0, 0, 0, 60)
MainFrame.BackgroundTransparency = 1
MainFrame.BorderSizePixel = 0
MainFrame.ScrollBarThickness = 8
MainFrame.ScrollBarImageColor3 = Color3.fromRGB(0, 0, 0)
MainFrame.ZIndex = 2

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Parent = MainFrame
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 6)
UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

local gridPadding = Instance.new("UIPadding")
gridPadding.PaddingTop = UDim.new(0, 10)
gridPadding.PaddingBottom = UDim.new(0, 10)
gridPadding.Parent = MainFrame

local Template = Instance.new("Frame")
Template.Name = "Template"
Template.Size = UDim2.new(0.949, 0, 0, 46)
Template.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
Template.BackgroundTransparency = 0.5
Template.BorderSizePixel = 0

local TemplateCorner = Instance.new("UICorner")
TemplateCorner.CornerRadius = UDim.new(0, 6)
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

local Rank = Instance.new("TextLabel")
Rank.Name = "Rank"
Rank.Parent = Template
Rank.Size = UDim2.new(0.12, 0, 0.7, 0)
Rank.Position = UDim2.new(0.02, 0, 0.15, 0)
Rank.BackgroundTransparency = 1
Rank.TextColor3 = Color3.fromRGB(255, 255, 255)
Rank.Font = Enum.Font.FredokaOne
Rank.TextScaled = true
Rank.Text = "#"
Rank.ZIndex = 4

local rankStroke = Instance.new("UIStroke")
rankStroke.Thickness = 2
rankStroke.Parent = Rank

local Icon = Instance.new("ImageLabel")
Icon.Name = "Icon"
Icon.Parent = Template
Icon.Size = UDim2.new(1, 0, 0.8, 0)
Icon.Position = UDim2.new(0.16, 0, 0.1, 0)
Icon.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
Icon.BackgroundTransparency = 1
Icon.ZIndex = 4

local IconAspect = Instance.new("UIAspectRatioConstraint")
IconAspect.AspectRatio = 1
IconAspect.AspectType = Enum.AspectType.FitWithinMaxSize
IconAspect.Parent = Icon

local IconCorner = Instance.new("UICorner")
IconCorner.CornerRadius = UDim.new(1, 0)
IconCorner.Parent = Icon

local iconStroke = Instance.new("UIStroke")
iconStroke.Thickness = 2
iconStroke.Parent = Icon

local Username = Instance.new("TextLabel")
Username.Name = "Username"
Username.Parent = Template
Username.Size = UDim2.new(0.45, 0, 0.7, 0)
Username.Position = UDim2.new(0.28, 0, 0.15, 0)
Username.BackgroundTransparency = 1
Username.TextColor3 = Color3.fromRGB(255, 255, 255)
Username.Font = Enum.Font.FredokaOne
Username.TextScaled = true
Username.Text = "Username"
Username.TextXAlignment = Enum.TextXAlignment.Left
Username.ZIndex = 4

local userStroke = Instance.new("UIStroke")
userStroke.Thickness = 2
userStroke.Parent = Username

local Score = Instance.new("TextLabel")
Score.Name = "Score"
Score.Parent = Template
Score.Size = UDim2.new(0.2, 0, 0.7, 0)
Score.Position = UDim2.new(0.75, 0, 0.15, 0)
Score.BackgroundTransparency = 1
Score.TextColor3 = Color3.fromRGB(200, 255, 200)
Score.Font = Enum.Font.FredokaOne
Score.TextScaled = true
Score.Text = "0"
Score.ZIndex = 4

local scoreStroke = Instance.new("UIStroke")
scoreStroke.Thickness = 2
scoreStroke.Parent = Score

local ListSize = 10
local UpdateEvery = 20
local MinimumRequirement = 1
local ProductValues = {}

task.spawn(function()
    task.wait(2)
    for _, btnData in ipairs(DonationButtons) do
        ProductValues[btnData.ID] = btnData.Amount
        Bindable:Fire(btnData.Name, btnData.ID)
    end
end)

local function abbreviate(value, idp)
    if value < 1000 then
        return math.floor(value + 0.5)
    else
        local abbreviations = {"", "K", "M", "B", "T"}
        local ex = math.floor(math.log(math.max(1, math.abs(value)), 1000))
        local abbrevs = abbreviations[1 + ex] or ("e+" .. ex)
        local normal = math.floor(value * ((10 ^ idp) / (1000 ^ ex))) / (10 ^ idp)
        return ("%." .. idp .. "f%s"):format(normal, abbrevs)
    end
end

MarketplaceService.ProcessReceipt = function(receiptInfo)
    local productId = receiptInfo.ProductId
    local playerId = receiptInfo.PlayerId
    
    local addedAmount = ProductValues[productId]
    if not addedAmount then
        return Enum.ProductPurchaseDecision.NotProcessedYet
    end
    
    local success, err = pcall(function()
        GlobalLeaderboardB:UpdateAsync(playerId, function(oldValue)
            local current = oldValue or 0
            return current + addedAmount
        end)
    end)
    
    if success then
        return Enum.ProductPurchaseDecision.PurchaseGranted
    else
        return Enum.ProductPurchaseDecision.NotProcessedYet
    end
end

while true do
    for i, v in pairs(MainFrame:GetChildren()) do
        if v:IsA("Frame") then
            v:Destroy()
        end
    end
    
    local Success, Pages = pcall(function()
        return GlobalLeaderboardB:GetSortedAsync(false, ListSize)
    end)
    
    if Success then
        local TopList = Pages:GetCurrentPage()
        
        local donatorIds = {}
        for _, dData in ipairs(TopList) do
            if dData.value >= MinimumRequirement then
                donatorIds[dData.key] = true
            end
        end
        
        for _, p in ipairs(Players:GetPlayers()) do
            if donatorIds[p.UserId] then
                p:SetAttribute("IsDonator", true)
            else
                p:SetAttribute("IsDonator", false)
            end
        end
        
        for RankNum, SavedData in ipairs(TopList) do
            local UserId = SavedData.key
            local CAmount = SavedData.value
            
            if CAmount >= MinimumRequirement then
                local TemplateClone = Template:Clone()
                TemplateClone.Parent = MainFrame
                TemplateClone.LayoutOrder = RankNum
                TemplateClone.Score.Text = abbreviate(CAmount, 1)
                
                if RankNum == 1 then
                    TemplateClone.Rank.Text = "🥇"
                elseif RankNum == 2 then
                    TemplateClone.Rank.Text = "🥈"
                elseif RankNum == 3 then
                    TemplateClone.Rank.Text = "🥉"
                else
                    TemplateClone.Rank.Text = "#" .. RankNum
                end
                
                local User = "Unknown"
                pcall(function()
                    User = Players:GetNameFromUserIdAsync(UserId)
                end)
                
                if User == "Unknown" then
                    TemplateClone.Username.Text = "Not Ranked"
                else
                    TemplateClone.Username.Text = User
                end
                
                TemplateClone.Icon.Image = "rbxthumb://type=AvatarHeadShot&id=" .. UserId .. "&w=150&h=150"
                TemplateClone.Name = User
            end
        end
    end
    task.wait(UpdateEvery)
end