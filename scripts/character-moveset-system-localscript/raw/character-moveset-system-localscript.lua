local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
 
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local remoteEvent = ReplicatedStorage:WaitForChild("CharacterSelectEvent")
local previewFolder = ReplicatedStorage:WaitForChild("ClientCharacterPreviews")
 
local PLACEHOLDER_ID = "75000183965587"
local PURE_BLACK = Color3.fromRGB(0, 0, 0)
local OFF_BLACK = Color3.fromRGB(15, 15, 15)
local CARD_BG = Color3.fromRGB(25, 25, 25)
local SELECTED_BORDER = Color3.fromRGB(255, 255, 255)
local TEXT_PRIMARY = Color3.fromRGB(255, 255, 255)
local TEXT_SECONDARY = Color3.fromRGB(120, 120, 120)
 
local isSelecting = false
 
local function getCharacterImage(containerModel)
    local targetId = PLACEHOLDER_ID
    
    local configImage = containerModel:FindFirstChildWhichIsA("ImageLabel")
    
    if configImage and configImage.Image ~= "" then
        local extractedId = string.match(configImage.Image, "%d+")
        if extractedId then
            targetId = extractedId
        end
    end
    
    return "rbxthumb://type=Asset&id=" .. targetId .. "&w=420&h=420"
end
 
local function createSelectionGui()
    local existingGui = playerGui:FindFirstChild("CharacterSelect")
    if existingGui then existingGui:Destroy() end
    
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "CharacterSelect"
    screenGui.ResetOnSpawn = false
    screenGui.IgnoreGuiInset = true
    screenGui.Parent = playerGui
    
    local container = Instance.new("Frame")
    container.Name = "SlideContainer"
    container.Size = UDim2.new(1, 0, 1, 0)
    container.Position = UDim2.new(-1, 0, 0, 0)
    container.BackgroundColor3 = PURE_BLACK
    container.BackgroundTransparency = 1
    container.BorderSizePixel = 0
    container.Parent = screenGui
    
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0.8, 0, 0.8, 0)
    mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    mainFrame.BackgroundColor3 = PURE_BLACK
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = container
    
    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 8)
    mainCorner.Parent = mainFrame
    
    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 60)
    header.BackgroundColor3 = OFF_BLACK
    header.BorderSizePixel = 0
    header.Parent = mainFrame
    
    local headerCorner = Instance.new("UICorner")
    headerCorner.CornerRadius = UDim.new(0, 8)
    headerCorner.Parent = header
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 1, 0)
    title.BackgroundTransparency = 1
    title.Text = "SELECT CHARACTER"
    title.TextColor3 = TEXT_PRIMARY
    title.Font = Enum.Font.GothamBold
    title.TextSize = 22
    title.Parent = header
    
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Size = UDim2.new(1, -20, 1, -80)
    scrollFrame.Position = UDim2.new(0, 10, 0, 70)
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.BorderSizePixel = 0
    scrollFrame.ScrollBarThickness = 4
    scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(60, 60, 60)
    scrollFrame.Parent = mainFrame
    
    local gridLayout = Instance.new("UIGridLayout")
    gridLayout.CellSize = UDim2.new(0, 200, 0, 220)
    gridLayout.CellPadding = UDim2.new(0, 15, 0, 15)
    gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
    gridLayout.Parent = scrollFrame
    
    local charList = {}
    local seenNames = {}
    
    for _, charData in ipairs(previewFolder:GetChildren()) do
        if charData:IsA("Model") then
            if not seenNames[charData.Name] then
                seenNames[charData.Name] = true
                table.insert(charList, charData)
            end
        end
    end
    
    table.sort(charList, function(a, b) return a.Name < b.Name end)
        
        for i, charData in ipairs(charList) do
            local success, err = pcall(function()
                local card = Instance.new("Frame")
                card.Name = charData.Name
                card.BackgroundColor3 = CARD_BG
                card.BorderSizePixel = 0
                card.LayoutOrder = i
                card.Parent = scrollFrame
                
                local cardCorner = Instance.new("UICorner")
                cardCorner.CornerRadius = UDim.new(0, 4)
                cardCorner.Parent = card
                
                local stroke = Instance.new("UIStroke")
                stroke.Color = SELECTED_BORDER
                stroke.Thickness = 3
                stroke.Transparency = 1
                stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                stroke.Parent = card
                
                local imageContainer = Instance.new("Frame")
                imageContainer.Size = UDim2.new(1, -20, 0, 140)
                imageContainer.Position = UDim2.new(0, 10, 0, 10)
                imageContainer.BackgroundColor3 = OFF_BLACK
                imageContainer.BorderSizePixel = 0
                imageContainer.Parent = card
                
                local imgCorner = Instance.new("UICorner")
                imgCorner.CornerRadius = UDim.new(0, 4)
                imgCorner.Parent = imageContainer
                
                local characterImg = Instance.new("ImageLabel")
                characterImg.Size = UDim2.new(1, 0, 1, 0)
                characterImg.BackgroundTransparency = 1
                characterImg.ScaleType = Enum.ScaleType.Crop
                characterImg.Image = getCharacterImage(charData)
                characterImg.Parent = imageContainer
                
                local nameLbl = Instance.new("TextLabel")
                nameLbl.Size = UDim2.new(1, 0, 0, 25)
                nameLbl.Position = UDim2.new(0, 0, 0, 165)
                nameLbl.BackgroundTransparency = 1
                nameLbl.Text = string.upper(charData.Name)
                nameLbl.TextColor3 = TEXT_SECONDARY
                nameLbl.Font = Enum.Font.GothamBold
                nameLbl.TextSize = 14
                nameLbl.Parent = card
                
                local btn = Instance.new("TextButton")
                btn.Size = UDim2.new(1, 0, 1, 0)
                btn.BackgroundTransparency = 1
                btn.Text = ""
                btn.Parent = card
                
                btn.MouseButton1Click:Connect(function()
                    if isSelecting then return end
                    
                    for _, other in pairs(scrollFrame:GetChildren()) do
                        if other:IsA("Frame") then
                            local otherStroke = other:FindFirstChildOfClass("UIStroke")
                            local otherLabel = other:FindFirstChildOfClass("TextLabel")
                            if otherStroke then otherStroke.Transparency = 1 end
                            if otherLabel then otherLabel.TextColor3 = TEXT_SECONDARY end
                        end
                    end
                    
                    stroke.Transparency = 0
                    nameLbl.TextColor3 = TEXT_PRIMARY
                    isSelecting = true
                    
                    local slideOut = TweenService:Create(container, TweenInfo.new(0.6, Enum.EasingStyle.Exponential, Enum.EasingDirection.In), {
                    Position = UDim2.new(1.5, 0, 0, 0)
                    })
                    slideOut:Play()
                    slideOut.Completed:Wait()
                    
                    remoteEvent:FireServer(charData.Name)
                    
                    screenGui:Destroy()
                    isSelecting = false
                end)
            end)
            
            if not success then warn("Card Error: " .. tostring(err)) end
        end
        
        local rows = math.ceil(#charList / 3)
        scrollFrame.CanvasSize = UDim2.new(0, 0, 0, rows * 240)
        
        return container
    end
    
    local function startFlow()
        if #previewFolder:GetChildren() == 0 then
            local connection
            connection = previewFolder.ChildAdded:Connect(function()
                connection:Disconnect()
                task.wait(1)
                startFlow()
            end)
            return
        end
        
        isSelecting = false
        local container = createSelectionGui()
        
        container.Position = UDim2.new(-1, 0, 0, 0)
        
        task.wait(0.5)
        
        local slideIn = TweenService:Create(container, TweenInfo.new(0.6, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {
        Position = UDim2.new(0, 0, 0, 0)
        })
        slideIn:Play()
    end
    
    local function onCharacterAdded(char)
        task.wait(0.5)
        if player:GetAttribute("IsMorphing") then return end
        startFlow()
    end
    
    if player.Character then
        onCharacterAdded(player.Character)
    end
    
    player.CharacterAdded:Connect(onCharacterAdded)
