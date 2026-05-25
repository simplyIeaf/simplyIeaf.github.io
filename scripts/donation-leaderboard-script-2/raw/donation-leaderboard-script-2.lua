local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
 
local Part = script.Parent
 
local studTextureId = "rbxassetid://1013778272"
 
local SurfaceGui = Instance.new("SurfaceGui")
SurfaceGui.Parent = Part
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
Title.Text = "Donations"
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
UIListLayout.Padding = UDim.new(0, 10)
UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
 
local gridPadding = Instance.new("UIPadding")
gridPadding.PaddingTop = UDim.new(0, 15)
gridPadding.PaddingBottom = UDim.new(0, 15)
gridPadding.Parent = MainFrame
 
local Bindable = ServerStorage:WaitForChild("AddDonationButtonEvent")
 
Bindable.Event:Connect(function(buttonName, productId)
    local Btn = Instance.new("TextButton")
    Btn.Name = buttonName
    Btn.Size = UDim2.new(0.949, 0, 0, 60)
    Btn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Btn.BorderSizePixel = 0
    Btn.Text = ""
    Btn.ZIndex = 3
    Btn.Parent = MainFrame
    
    local BtnCorner = Instance.new("UICorner")
    BtnCorner.CornerRadius = UDim.new(0, 6)
    BtnCorner.Parent = Btn
    
    local btnGradient = Instance.new("UIGradient")
    btnGradient.Color = ColorSequence.new(Color3.fromRGB(40, 220, 40), Color3.fromRGB(15, 120, 15))
    btnGradient.Rotation = 90
    btnGradient.Parent = Btn
    
    local cellStuds = Instance.new("ImageLabel")
    cellStuds.Size = UDim2.new(1, 0, 1, 0)
    cellStuds.BackgroundTransparency = 1
    cellStuds.Image = studTextureId
    cellStuds.ImageTransparency = 0.7
    cellStuds.ScaleType = Enum.ScaleType.Tile
    cellStuds.TileSize = UDim2.new(0, 40, 0, 40)
    cellStuds.ZIndex = 4
    cellStuds.Parent = Btn
    
    local ContentLabel = Instance.new("TextLabel")
    ContentLabel.Name = "Label"
    ContentLabel.Size = UDim2.new(1, 0, 1, 0)
    ContentLabel.BackgroundTransparency = 1
    ContentLabel.Text = buttonName
    ContentLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    ContentLabel.Font = Enum.Font.FredokaOne
    ContentLabel.TextScaled = true
    ContentLabel.ZIndex = 5
    ContentLabel.Parent = Btn
    
    local labelStroke = Instance.new("UIStroke")
    labelStroke.Thickness = 3
    labelStroke.Color = Color3.fromRGB(0, 0, 0)
    labelStroke.Parent = ContentLabel
    
    local txtConstraint = Instance.new("UITextSizeConstraint")
    txtConstraint.MaxTextSize = 35
    txtConstraint.MinTextSize = 10
    txtConstraint.Parent = ContentLabel
    
    local txtPadding = Instance.new("UIPadding")
    txtPadding.PaddingTop = UDim.new(0, 10)
    txtPadding.PaddingBottom = UDim.new(0, 10)
    txtPadding.Parent = ContentLabel
    
    Btn.MouseButton1Click:Connect(function()
        local player = Players:GetPlayerFromCharacter(Btn.Parent.Parent.Parent.Parent.Parent)
        if not player then
            for _, p in pairs(Players:GetPlayers()) do
                if p:DistanceFromCharacter(Part.Position) < 20 then
                    player = p
                    break
                end
            end
        end
        if player then
            MarketplaceService:PromptProductPurchase(player, productId)
        end
    end)
end)