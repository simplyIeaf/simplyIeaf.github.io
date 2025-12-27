-- made by @simplyIeaf1 on youtube

local StarterGui = game:GetService("StarterGui")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local backpack = player:WaitForChild("Backpack")

StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)

local screenGui = script.Parent
if not screenGui:IsA("ScreenGui") then
    screenGui = Instance.new("ScreenGui")
    screenGui.Name = "CustomHotbar"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = player:WaitForChild("PlayerGui")
    script.Parent = screenGui
end

local hotbarFrame = Instance.new("Frame")
hotbarFrame.Name = "HotbarFrame"
hotbarFrame.Size = UDim2.new(0, 300, 0, 60)
hotbarFrame.Position = UDim2.new(0.5, 0, 1, -10)
hotbarFrame.AnchorPoint = Vector2.new(0.5, 1)
hotbarFrame.BackgroundTransparency = 1
hotbarFrame.ZIndex = 5
hotbarFrame.Parent = screenGui

local uiListLayoutHotbar = Instance.new("UIListLayout")
uiListLayoutHotbar.FillDirection = Enum.FillDirection.Horizontal
uiListLayoutHotbar.HorizontalAlignment = Enum.HorizontalAlignment.Center
uiListLayoutHotbar.VerticalAlignment = Enum.VerticalAlignment.Center
uiListLayoutHotbar.SortOrder = Enum.SortOrder.LayoutOrder
uiListLayoutHotbar.Padding = UDim.new(0, 5)
uiListLayoutHotbar.Parent = hotbarFrame

local menuFrame = Instance.new("Frame")
menuFrame.Name = "MenuFrame"
menuFrame.Size = UDim2.new(0, 275, 0, 225)
menuFrame.Position = UDim2.new(0.5, 0, 1, -70)
menuFrame.AnchorPoint = Vector2.new(0.5, 1)
menuFrame.BackgroundColor3 = Color3.new(0, 0, 0)
menuFrame.BackgroundTransparency = 0.5
menuFrame.Visible = false
menuFrame.ZIndex = 10
menuFrame.Parent = screenGui

local menuCorner = Instance.new("UICorner")
menuCorner.CornerRadius = UDim.new(0, 8)
menuCorner.Parent = menuFrame

local scrollingFrame = Instance.new("ScrollingFrame")
scrollingFrame.Name = "ScrollingFrame"
scrollingFrame.Size = UDim2.new(1, -10, 1, -10)
scrollingFrame.Position = UDim2.new(0, 5, 0, 5)
scrollingFrame.BackgroundTransparency = 1
scrollingFrame.ScrollingDirection = Enum.ScrollingDirection.Y
scrollingFrame.ScrollBarThickness = 5
scrollingFrame.ZIndex = 15
scrollingFrame.Parent = menuFrame

local uiGridLayout = Instance.new("UIGridLayout")
uiGridLayout.FillDirection = Enum.FillDirection.Horizontal
uiGridLayout.SortOrder = Enum.SortOrder.LayoutOrder
uiGridLayout.CellSize = UDim2.new(0, 50, 0, 50)
uiGridLayout.CellPadding = UDim2.new(0, 3, 0, 3)
uiGridLayout.Parent = scrollingFrame

local allSlots = {}
local equippedTool = nil
local isUpdating = false
local toolInstanceIds = {}
local nextInstanceId = 1
local menuSlot = nil
local lastEquipTime = 0
local equipCooldown = 0.5
local lastUpdateTime = 0
local updateCooldown = 0.1
local updateDebounce = false
local pendingUpdate = false

task.spawn(function()
    setmetatable(toolInstanceIds, {__mode = "k"})
end)

local scheduleUpdate
local updateInventory
local createItemSlot
local createMenuSlot
local updateMenu

local function getToolIcon(tool)
    if not tool then return "rbxasset://textures/ui/GuiImagePlaceholder.png" end
    if tool.TextureId and tool.TextureId ~= "" then
        return tool.TextureId
    end
    return "rbxasset://textures/ui/GuiImagePlaceholder.png"
end

local function setToolInstanceId(tool)
    if not tool then return 0 end
    local instanceId = tool:GetAttribute("InstanceId")
    if not instanceId then
        instanceId = nextInstanceId
        task.spawn(function()
            if tool and tool.Parent then
                tool:SetAttribute("InstanceId", instanceId)
                toolInstanceIds[tool] = instanceId
                nextInstanceId = nextInstanceId + 1
            end
        end)
    end
    return instanceId
end

local function getToolDisplayName(tool)
    if not tool then return "" end
    local sameName = {}
    for _, child in ipairs(backpack:GetChildren()) do
        if child:IsA("Tool") and child.Name == tool.Name then
            table.insert(sameName, child)
        end
    end
    local character = player.Character
    if character then
        for _, child in ipairs(character:GetChildren()) do
            if child:IsA("Tool") and child.Name == tool.Name then
                local found = false
                for _, t in ipairs(sameName) do
                    if t == child then
                        found = true
                        break
                    end
                end
                if not found then
                    table.insert(sameName, child)
                end
            end
        end
    end
    if #sameName <= 1 then
        return tool.Name
    end
    local instanceId = setToolInstanceId(tool)
    return tool.Name .. "_" .. instanceId
end

local function updateHighlights()
    for i, slotData in ipairs(allSlots) do
        if slotData and slotData.slot and slotData.slot.Parent then
            local stroke = slotData.slot:FindFirstChild("SelectionStroke")
            local hoverStroke = slotData.slot:FindFirstChild("HoverStroke")
            if stroke then
                local tool = slotData.tool
                if tool and tool == equippedTool then
                    stroke.Transparency = 0
                    if hoverStroke then
                        hoverStroke.Transparency = 1
                    end
                else
                    stroke.Transparency = 1
                end
            end
        end
    end
end

createMenuSlot = function(slotNumber)
    local slot = Instance.new("Frame")
    slot.Name = "MenuSlot"
    slot.Size = UDim2.new(0, 50, 0, 50)
    slot.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    slot.BackgroundTransparency = 0.3
    slot.BorderSizePixel = 0
    slot.LayoutOrder = slotNumber
    slot.ZIndex = 5
    
    local uiCornerSlot = Instance.new("UICorner")
    uiCornerSlot.CornerRadius = UDim.new(0, 8)
    uiCornerSlot.Parent = slot
    
    local iconFrame = Instance.new("Frame")
    iconFrame.Name = "MenuIcon"
    iconFrame.Size = UDim2.new(0.6, 0, 0.6, 0)
    iconFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    iconFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    iconFrame.BackgroundTransparency = 1
    iconFrame.ZIndex = 6
    iconFrame.Parent = slot
    
    local stripe1 = Instance.new("Frame")
    stripe1.Size = UDim2.new(0.8, 0, 0.1, 0)
    stripe1.Position = UDim2.new(0.5, 0, 0.25, 0)
    stripe1.AnchorPoint = Vector2.new(0.5, 0.5)
    stripe1.BackgroundColor3 = Color3.new(1, 1, 1)
    stripe1.ZIndex = 6
    stripe1.Parent = iconFrame
    
    local stripe2 = Instance.new("Frame")
    stripe2.Size = UDim2.new(0.8, 0, 0.1, 0)
    stripe2.Position = UDim2.new(0.5, 0, 0.5, 0)
    stripe2.AnchorPoint = Vector2.new(0.5, 0.5)
    stripe2.BackgroundColor3 = Color3.new(1, 1, 1)
    stripe2.ZIndex = 6
    stripe2.Parent = iconFrame
    
    local stripe3 = Instance.new("Frame")
    stripe3.Size = UDim2.new(0.8, 0, 0.1, 0)
    stripe3.Position = UDim2.new(0.5, 0, 0.75, 0)
    stripe3.AnchorPoint = Vector2.new(0.5, 0.5)
    stripe3.BackgroundColor3 = Color3.new(1, 1, 1)
    stripe3.ZIndex = 6
    stripe3.Parent = iconFrame
    
    local clickDetector = Instance.new("TextButton")
    clickDetector.Name = "ClickDetector"
    clickDetector.Size = UDim2.new(1, 0, 1, 0)
    clickDetector.BackgroundTransparency = 1
    clickDetector.Text = ""
    clickDetector.ZIndex = 6
    clickDetector.Parent = slot
    
    local clickConnection
    clickConnection = clickDetector.MouseButton1Click:Connect(function()
        if isUpdating then return end
        isUpdating = true
        menuFrame.Visible = not menuFrame.Visible
        if menuFrame.Visible then
            task.spawn(updateMenu)
        end
        isUpdating = false
    end)
    
    slot.AncestryChanged:Connect(function()
        if not slot.Parent then
            if clickConnection then clickConnection:Disconnect() end
        end
    end)
    
    return slot
end

createItemSlot = function(tool, slotNumber, isHotbar)
    if not tool or not tool.Parent then return nil end
    local slot = Instance.new("Frame")
    slot.Name = "Slot" .. slotNumber
    slot.Size = UDim2.new(0, 50, 0, 50)
    slot.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    slot.BackgroundTransparency = 0.3
    slot.BorderSizePixel = 0
    slot.LayoutOrder = slotNumber
    slot.ZIndex = isHotbar and 5 or 15
    
    local uiCornerSlot = Instance.new("UICorner")
    uiCornerSlot.CornerRadius = UDim.new(0, 8)
    uiCornerSlot.Parent = slot
    
    local display = Instance.new("ImageLabel")
    display.Name = "ToolIcon"
    display.Size = UDim2.new(0.75, 0, 0.75, 0)
    display.Position = UDim2.new(0.5, 0, 0.5, 0)
    display.AnchorPoint = Vector2.new(0.5, 0.5)
    display.BackgroundTransparency = 1
    display.Image = getToolIcon(tool)
    display.ImageColor3 = Color3.new(1, 1, 1)
    display.ScaleType = Enum.ScaleType.Fit
    display.ZIndex = isHotbar and 6 or 16
    display.Parent = slot
    
    local uiStroke = Instance.new("UIStroke")
    uiStroke.Name = "SelectionStroke"
    uiStroke.Color = Color3.fromRGB(255, 255, 255)
    uiStroke.Thickness = 3
    uiStroke.Transparency = 1
    uiStroke.ZIndex = isHotbar and 6 or 16
    uiStroke.Parent = slot
    
    local hoverStroke = Instance.new("UIStroke")
    hoverStroke.Name = "HoverStroke"
    hoverStroke.Color = Color3.fromRGB(200, 200, 200)
    hoverStroke.Thickness = 2
    hoverStroke.Transparency = 1
    hoverStroke.ZIndex = isHotbar and 6 or 16
    hoverStroke.Parent = slot
    
    local clickDetector = Instance.new("TextButton")
    clickDetector.Name = "ClickDetector"
    clickDetector.Size = UDim2.new(1, 0, 1, 0)
    clickDetector.BackgroundTransparency = 1
    clickDetector.Text = ""
    clickDetector.ZIndex = isHotbar and 6 or 16
    clickDetector.Parent = slot
    
    local clickConnection
    local enterConnection
    local leaveConnection
    
    enterConnection = clickDetector.MouseEnter:Connect(function()
        if not slot.Parent or tool ~= equippedTool then
            hoverStroke.Transparency = 0.5
        end
    end)
    
    leaveConnection = clickDetector.MouseLeave:Connect(function()
        if not slot.Parent then return end
        hoverStroke.Transparency = 1
    end)
    
    clickConnection = clickDetector.MouseButton1Click:Connect(function()
        if isUpdating or not slot.Parent then return end
        local currentTime = tick()
        if currentTime - lastEquipTime < equipCooldown then return end
        isUpdating = true
        lastEquipTime = currentTime
        
        local character = player.Character
        if not character then
            isUpdating = false
            return
        end
        
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if not humanoid then
            isUpdating = false
            return
        end
        
        if not tool or not tool.Parent then
            scheduleUpdate()
            isUpdating = false
            return
        end
        
        if equippedTool == tool then
            humanoid:UnequipTools()
            equippedTool = nil
        else
            humanoid:UnequipTools()
            humanoid:EquipTool(tool)
            if character:FindFirstChildOfClass("Tool") == tool then
                equippedTool = tool
            else
                scheduleUpdate()
            end
        end
        
        updateHighlights()
        isUpdating = false
    end)
    
    slot.AncestryChanged:Connect(function()
        if not slot.Parent then
            if enterConnection then enterConnection:Disconnect() end
            if leaveConnection then leaveConnection:Disconnect() end
            if clickConnection then clickConnection:Disconnect() end
        end
    end)
    
    if isHotbar then
        local numberLabel = Instance.new("TextLabel")
        numberLabel.Name = "SlotNumber"
        numberLabel.Size = UDim2.new(0, 16, 0, 16)
        numberLabel.Position = UDim2.new(0, 3, 0, 3)
        numberLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        numberLabel.BackgroundTransparency = 0.3
        numberLabel.Text = tostring(slotNumber)
        numberLabel.TextColor3 = Color3.new(1, 1, 1)
        numberLabel.TextSize = 11
        numberLabel.Font = Enum.Font.SourceSansBold
        numberLabel.ZIndex = 6
        numberLabel.Parent = slot
        
        local numberCorner = Instance.new("UICorner")
        numberCorner.CornerRadius = UDim.new(0, 4)
        numberCorner.Parent = numberLabel
    end
    
    return slot
end

updateMenu = function()
    if isUpdating then return end
    isUpdating = true
    
    task.spawn(function()
        for _, child in ipairs(scrollingFrame:GetChildren()) do
            if child:IsA("Frame") then
                child:Destroy()
            end
        end
        
        for i = 1, #allSlots do
            local slotData = allSlots[i]
            if slotData and slotData.tool and slotData.tool.Parent and not slotData.isHotbar then
                local slot = createItemSlot(slotData.tool, i, false)
                if slot then
                    slot.Parent = scrollingFrame
                    slotData.slot = slot
                end
            end
        end
        
        scrollingFrame.CanvasSize = UDim2.new(0, 0, 0, uiGridLayout.AbsoluteContentSize.Y)
        scrollingFrame.CanvasPosition = Vector2.new(0, 0)
        scrollingFrame.Visible = false
        scrollingFrame.Visible = true
    end)
    
    isUpdating = false
end

updateInventory = function()
    if isUpdating then
        return
    end
    local currentTime = tick()
    if currentTime - lastUpdateTime < updateCooldown then
        return
    end
    isUpdating = true
    lastUpdateTime = currentTime
    
    for _, child in ipairs(hotbarFrame:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    for _, child in ipairs(scrollingFrame:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    for i, slotData in ipairs(allSlots) do
        if slotData and slotData.slot then
            slotData.slot:Destroy()
        end
    end
    allSlots = {}
    
    local currentTools = {}
    local toolMap = {}
    local character = player.Character
    local currentEquipped = nil
    
    for _, child in ipairs(backpack:GetChildren()) do
        if child:IsA("Tool") then
            task.spawn(function()
                setToolInstanceId(child)
            end)
            local instanceId = child:GetAttribute("InstanceId") or setToolInstanceId(child)
            if not toolMap[instanceId] then
                toolMap[instanceId] = child
                table.insert(currentTools, child)
            end
        end
    end
    
    if character then
        currentEquipped = character:FindFirstChildOfClass("Tool")
        if currentEquipped then
            equippedTool = currentEquipped
            task.spawn(function()
                setToolInstanceId(currentEquipped)
            end)
            local instanceId = currentEquipped:GetAttribute("InstanceId") or setToolInstanceId(currentEquipped)
            if not toolMap[instanceId] then
                toolMap[instanceId] = currentEquipped
                table.insert(currentTools, currentEquipped)
            end
        end
    end
    
    table.sort(currentTools, function(a, b)
        if a.Name == b.Name then
            local aId = a:GetAttribute("InstanceId") or 0
            local bId = b:GetAttribute("InstanceId") or 0
            return aId < bId
        end
        return a.Name < b.Name
    end)
    
    local hotbarCount = math.min(#currentTools, 3)
    for i = 1, hotbarCount do
        local tool = currentTools[i]
        if tool and tool.Parent then
            local slot = createItemSlot(tool, i, true)
            if slot then
                slot.Parent = hotbarFrame
                allSlots[i] = {tool = tool, slot = slot, isHotbar = true}
            end
        end
    end
    
    for i = 4, #currentTools do
        local tool = currentTools[i]
        if tool and tool.Parent then
            local slot = createItemSlot(tool, i, false)
            if slot then
                slot.Parent = scrollingFrame
                allSlots[i] = {tool = tool, slot = slot, isHotbar = false}
            end
        end
    end
    
    if menuSlot and menuSlot.Parent then
        menuSlot:Destroy()
        menuSlot = nil
    end
    
    if #currentTools >= 1 then
        local menuSlotNumber = math.min(hotbarCount + 1, 4)
        menuSlot = createMenuSlot(menuSlotNumber)
        if menuSlot then
            menuSlot.Parent = hotbarFrame
        end
    end
    
    updateHighlights()
    
    if menuFrame.Visible then
        task.spawn(updateMenu)
    end
    
    isUpdating = false
end

scheduleUpdate = function()
    if updateDebounce then
        pendingUpdate = true
        return
    end
    
    updateDebounce = true
    pendingUpdate = false
    
    task.defer(function()
        updateInventory()
        updateDebounce = false
        
        if pendingUpdate then
            scheduleUpdate()
        end
    end)
end

local function setupCharacter(character)
    if not character then return end
    local humanoid = character:WaitForChild("Humanoid", 5)
    if not humanoid then
        return
    end
    
    local characterConnection1
    local characterConnection2
    local diedConnection
    
    characterConnection1 = character.ChildAdded:Connect(function(child)
        if isUpdating then return end
        if child:IsA("Tool") then
            task.spawn(function()
                setToolInstanceId(child)
            end)
            equippedTool = child
            updateHighlights()
            scheduleUpdate()
        end
    end)
    
    characterConnection2 = character.ChildRemoved:Connect(function(child)
        if isUpdating then return end
        if child:IsA("Tool") then
            if equippedTool == child then
                equippedTool = nil
                updateHighlights()
            end
            scheduleUpdate()
        end
    end)
    
    diedConnection = humanoid.Died:Connect(function()
        toolInstanceIds = {}
        nextInstanceId = 1
        setmetatable(toolInstanceIds, {__mode = "k"})
        if screenGui and screenGui.Parent then
            screenGui:Destroy()
        end
    end)
    
    character.AncestryChanged:Connect(function()
        if not character.Parent then
            if characterConnection1 then characterConnection1:Disconnect() end
            if characterConnection2 then characterConnection2:Disconnect() end
            if diedConnection then diedConnection:Disconnect() end
        end
    end)
    
    local equipped = character:FindFirstChildOfClass("Tool")
    if equipped then
        task.spawn(function()
            setToolInstanceId(equipped)
        end)
        equippedTool = equipped
        updateHighlights()
    end
end

updateInventory()

backpack.ChildAdded:Connect(function(child)
    if isUpdating then return end
    if child:IsA("Tool") then
        task.defer(function()
            if child.Parent == backpack then
                task.spawn(function()
                    setToolInstanceId(child)
                end)
                scheduleUpdate()
            end
        end)
    end
end)

backpack.ChildRemoved:Connect(function(child)
    if isUpdating then return end
    if child:IsA("Tool") then
        scheduleUpdate()
    end
end)

player.CharacterAdded:Connect(function(character)
    if isUpdating then return end
    equippedTool = nil
    setupCharacter(character)
    scheduleUpdate()
end)

if player.Character then
    setupCharacter(player.Character)
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed or isUpdating then return end
    local currentTime = tick()
    if currentTime - lastEquipTime < equipCooldown then return end
    isUpdating = true
    lastEquipTime = currentTime
    
    local keyMap = {
    [Enum.KeyCode.One] = 1,
    [Enum.KeyCode.Two] = 2,
    [Enum.KeyCode.Three] = 3
    }
    
    local slotIndex = keyMap[input.KeyCode]
    if not slotIndex then
        isUpdating = false
        return
    end
    
    local slotData = allSlots[slotIndex]
    if not slotData or not slotData.slot or not slotData.slot.Parent then
        scheduleUpdate()
        isUpdating = false
        return
    end
    
    local tool = slotData.tool
    if not tool or not tool.Parent then
        scheduleUpdate()
        isUpdating = false
        return
    end
    
    local character = player.Character
    if not character then
        isUpdating = false
        return
    end
    
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then
        isUpdating = false
        return
    end
    
    if equippedTool == tool then
        humanoid:UnequipTools()
        equippedTool = nil
    else
        humanoid:UnequipTools()
        humanoid:EquipTool(tool)
        if character:FindFirstChildOfClass("Tool") == tool then
            equippedTool = tool
        else
            scheduleUpdate()
        end
    end
    
    updateHighlights()
    isUpdating = false
end)