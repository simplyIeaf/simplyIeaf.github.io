local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
 
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
 
local tradingSys = ReplicatedStorage:WaitForChild("TradingSys")
local tradeEvent = tradingSys:WaitForChild("TradeEvent")
local tradeFunction = tradingSys:WaitForChild("TradeFunction")
 
local studTextureId = "rbxthumb://type=Asset&id=14905298664&w=150&h=150"
 
local highlight = Instance.new("Highlight")
highlight.FillTransparency = 1
highlight.OutlineColor = Color3.new(0, 0, 0)
highlight.OutlineTransparency = 0
highlight.Parent = ReplicatedStorage
 
local currentTarget = nil
local isTrading = false
local hasPendingOutgoing = false
local tradeGui = nil
local debounce = false
local timerLocked = false
local activeSession = nil
local connections = {}
local invConnections = {}
local activeHighlight = nil
 
local function cleanup()
    for _, conn in ipairs(connections) do
        if conn.Connected then conn:Disconnect() end
    end
    table.clear(connections)
    
    for _, conn in ipairs(invConnections) do
        if conn.Connected then conn:Disconnect() end
    end
    table.clear(invConnections)
    
    local wasTrading = isTrading
    local wasPending = hasPendingOutgoing
    
    isTrading = false
    hasPendingOutgoing = false
    timerLocked = false
    currentTarget = nil
    
    if activeHighlight then
        activeHighlight:Destroy()
        activeHighlight = nil
    end
    
    if tradeGui then
        tradeGui:Destroy()
        tradeGui = nil
    end
    
    for _, v in pairs(player.PlayerGui:GetChildren()) do
        if v.Name == "TradePromptUI" or v.Name == "GameSystemUI_Trade" then
            v:Destroy()
        end
    end
    
    if wasTrading or wasPending then
        tradeEvent:FireServer("Cancel")
    end
end
 
if player.Character then
    local hum = player.Character:WaitForChild("Humanoid", 3)
    if hum then
        table.insert(connections, hum.Died:Connect(cleanup))
    end
end
table.insert(connections, player.CharacterAdded:Connect(function(char)
    local hum = char:WaitForChild("Humanoid", 3)
    if hum then
        table.insert(connections, hum.Died:Connect(cleanup))
    end
end))
 
local function checkDebounce()
    if debounce then return false end
    debounce = true
    task.delay(0.2, function() debounce = false end)
        return true
    end
    
    local function addStudTexture(parent, zIndex)
        local tex = Instance.new("ImageLabel")
        tex.Size = UDim2.new(1, 0, 1, 0)
        tex.Position = UDim2.new(0, 0, 0, 0)
        tex.BackgroundTransparency = 1
        tex.Image = studTextureId
        tex.ImageTransparency = 0.88
        tex.ScaleType = Enum.ScaleType.Tile
        tex.TileSize = UDim2.new(0, 50, 0, 50)
        tex.ZIndex = zIndex
        tex.Parent = parent
        return tex
    end
    
    local function makeTopBar(parent, w, h)
        local clipper = Instance.new("Frame")
        clipper.Size = UDim2.new(0, w, 0, h)
        clipper.Position = UDim2.new(0, 0, 0, 0)
        clipper.BackgroundTransparency = 1
        clipper.ClipsDescendants = true
        clipper.ZIndex = 2
        clipper.Parent = parent
        
        local bar = Instance.new("Frame")
        bar.Size = UDim2.new(0, w, 0, h + 10)
        bar.Position = UDim2.new(0, 0, 0, 0)
        bar.BackgroundColor3 = Color3.new(1, 1, 1)
        bar.BorderSizePixel = 0
        bar.ZIndex = 2
        bar.Parent = clipper
        
        local barCorner = Instance.new("UICorner")
        barCorner.CornerRadius = UDim.new(0, 10)
        barCorner.Parent = bar
        
        local barGrad = Instance.new("UIGradient")
        barGrad.Color = ColorSequence.new(Color3.fromRGB(28, 175, 28), Color3.fromRGB(10, 95, 10))
        barGrad.Rotation = 90
        barGrad.Parent = bar
        
        local barStudTex = Instance.new("ImageLabel")
        barStudTex.Size = UDim2.new(1, 0, 1, 0)
        barStudTex.Position = UDim2.new(0, 0, 0, 0)
        barStudTex.BackgroundTransparency = 1
        barStudTex.Image = studTextureId
        barStudTex.ImageTransparency = 0.88
        barStudTex.ScaleType = Enum.ScaleType.Tile
        barStudTex.TileSize = UDim2.new(0, 50, 0, 50)
        barStudTex.ZIndex = 3
        barStudTex.Parent = bar
        
        local barStudCorner = Instance.new("UICorner")
        barStudCorner.CornerRadius = UDim.new(0, 10)
        barStudCorner.Parent = barStudTex
        
        local bottomBorder = Instance.new("Frame")
        bottomBorder.Size = UDim2.new(0, w, 0, 2)
        bottomBorder.Position = UDim2.new(0, 0, 1, -2)
        bottomBorder.BackgroundColor3 = Color3.new(0, 0, 0)
        bottomBorder.BorderSizePixel = 0
        bottomBorder.ZIndex = 4
        bottomBorder.Parent = clipper
        
        return clipper, bar
    end
    
    local function createStyledButton(parent, text, styleType, px, py, sw, sh, zBase)
        local z = zBase or 5
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, sw, 0, sh)
        btn.Position = UDim2.new(0, px, 0, py)
        btn.BackgroundTransparency = 1
        btn.Text = ""
        btn.ZIndex = z
        btn.AutoButtonColor = false
        btn.Parent = parent
        
        local bg = Instance.new("Frame")
        bg.Size = UDim2.new(1, 0, 1, 0)
        bg.Position = UDim2.new(0, 0, 0, 0)
        bg.BackgroundColor3 = Color3.new(1, 1, 1)
        bg.BorderSizePixel = 0
        bg.ZIndex = z
        bg.Parent = btn
        
        local bgCorner = Instance.new("UICorner")
        bgCorner.CornerRadius = UDim.new(0, 8)
        bgCorner.Parent = bg
        
        local bgStroke = Instance.new("UIStroke")
        bgStroke.Thickness = 2
        bgStroke.Color = Color3.new(0, 0, 0)
        bgStroke.Parent = bg
        
        local grad = Instance.new("UIGradient")
        if styleType == "Green" then
            grad.Color = ColorSequence.new(Color3.fromRGB(20, 150, 20), Color3.fromRGB(8, 80, 8))
        elseif styleType == "Red" then
            grad.Color = ColorSequence.new(Color3.fromRGB(170, 22, 22), Color3.fromRGB(90, 8, 8))
        else
            grad.Color = ColorSequence.new(Color3.fromRGB(90, 90, 90), Color3.fromRGB(50, 50, 50))
        end
        grad.Rotation = 90
        grad.Parent = bg
        
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, 0, 1, 0)
        lbl.Position = UDim2.new(0, 0, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = text
        lbl.TextColor3 = Color3.new(1, 1, 1)
        lbl.Font = Enum.Font.FredokaOne
        lbl.TextScaled = false
        lbl.TextSize = math.max(13, math.floor(sh * 0.44))
        lbl.ZIndex = z + 1
        lbl.Parent = btn
        
        local txtStroke = Instance.new("UIStroke")
        txtStroke.Thickness = 2
        txtStroke.Color = Color3.new(0, 0, 0)
        txtStroke.Parent = lbl
        
        return btn, grad, lbl
    end
    
    local function makeContainer(parent, pTitle, px, py, pw, ph)
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(0, pw, 0, ph)
        frame.Position = UDim2.new(0, px, 0, py)
        frame.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
        frame.BorderSizePixel = 0
        frame.ZIndex = 2
        frame.ClipsDescendants = true
        frame.Parent = parent
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 8)
        corner.Parent = frame
        
        local stroke = Instance.new("UIStroke")
        stroke.Thickness = 2
        stroke.Color = Color3.fromRGB(55, 55, 55)
        stroke.Parent = frame
        
        local titleClipper = Instance.new("Frame")
        titleClipper.Size = UDim2.new(0, pw, 0, 34)
        titleClipper.Position = UDim2.new(0, 0, 0, 0)
        titleClipper.BackgroundTransparency = 1
        titleClipper.ClipsDescendants = true
        titleClipper.ZIndex = 3
        titleClipper.Parent = frame
        
        local titleBar = Instance.new("Frame")
        titleBar.Size = UDim2.new(0, pw, 0, 44)
        titleBar.Position = UDim2.new(0, 0, 0, 0)
        titleBar.BackgroundColor3 = Color3.fromRGB(32, 32, 32)
        titleBar.BorderSizePixel = 0
        titleBar.ZIndex = 3
        titleBar.Parent = titleClipper
        
        local titleBarCorner = Instance.new("UICorner")
        titleBarCorner.CornerRadius = UDim.new(0, 8)
        titleBarCorner.Parent = titleBar
        
        local lbl = Instance.new("TextLabel")
        lbl.Text = pTitle
        lbl.Size = UDim2.new(0, pw - 10, 0, 34)
        lbl.Position = UDim2.new(0, 5, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.TextColor3 = Color3.new(1, 1, 1)
        lbl.Font = Enum.Font.FredokaOne
        lbl.TextScaled = false
        lbl.TextSize = 15
        lbl.ZIndex = 4
        lbl.Parent = titleClipper
        
        local lblStroke = Instance.new("UIStroke")
        lblStroke.Thickness = 2
        lblStroke.Color = Color3.new(0, 0, 0)
        lblStroke.Parent = lbl
        
        local scroll = Instance.new("ScrollingFrame")
        scroll.Size = UDim2.new(0, pw, 0, ph - 34)
        scroll.Position = UDim2.new(0, 0, 0, 34)
        scroll.BackgroundTransparency = 1
        scroll.BorderSizePixel = 0
        scroll.ScrollBarThickness = 6
        scroll.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 80)
        scroll.ZIndex = 3
        scroll.Parent = frame
        
        local pad = Instance.new("UIPadding")
        pad.PaddingTop = UDim.new(0, 8)
        pad.PaddingLeft = UDim.new(0, 8)
        pad.PaddingRight = UDim.new(0, 8)
        pad.PaddingBottom = UDim.new(0, 8)
        pad.Parent = scroll
        
        local grid = Instance.new("UIGridLayout")
        grid.CellSize = UDim2.new(0, 62, 0, 62)
        grid.CellPadding = UDim2.new(0, 8, 0, 8)
        grid.Parent = scroll
        
        return scroll, frame
    end
    
    local function createItemCell(parent, texture, selected)
        local cell = Instance.new("TextButton")
        cell.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        cell.BackgroundTransparency = 0
        cell.BorderSizePixel = 0
        cell.Text = ""
        cell.ZIndex = 3
        cell.AutoButtonColor = false
        cell.Parent = parent
        
        local cellCorner = Instance.new("UICorner")
        cellCorner.CornerRadius = UDim.new(0, 6)
        cellCorner.Parent = cell
        
        local cellStroke = Instance.new("UIStroke")
        cellStroke.Thickness = selected and 2.5 or 0
        cellStroke.Color = Color3.new(1, 1, 1)
        cellStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        cellStroke.Parent = cell
        
        local cellGradient = Instance.new("UIGradient")
        cellGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(48, 48, 48)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 20, 20))
        })
        cellGradient.Rotation = 135
        cellGradient.Parent = cell
        
        local icon = Instance.new("ImageLabel")
        icon.AnchorPoint = Vector2.new(0.5, 0.5)
        icon.Position = UDim2.new(0.5, 0, 0.5, 0)
        icon.Size = UDim2.new(0.78, 0, 0.78, 0)
        icon.BackgroundTransparency = 1
        icon.Image = (texture and texture ~= "") and texture or "rbxasset://textures/ui/GuiImagePlaceholder.png"
        icon.ZIndex = 4
        icon.Parent = cell
        
        return cell, cellStroke
    end
    
    local function buildTradeUI(partner)
        if tradeGui then tradeGui:Destroy() end
        timerLocked = false
        
        for _, conn in ipairs(invConnections) do
            if conn.Connected then conn:Disconnect() end
        end
        table.clear(invConnections)
        
        local gui = Instance.new("ScreenGui")
        gui.Name = "GameSystemUI_Trade"
        gui.IgnoreGuiInset = true
        gui.ResetOnSpawn = false
        gui.Parent = player.PlayerGui
        tradeGui = gui
        
        local uiScale = Instance.new("UIScale")
        uiScale.Parent = gui
        
        local safeFrame = Instance.new("Frame")
        safeFrame.Name = "SafeFrame"
        safeFrame.AnchorPoint = Vector2.new(0.5, 0.5)
        safeFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
        safeFrame.BackgroundTransparency = 1
        safeFrame.Parent = gui
        
        local function update()
            local vp = camera.ViewportSize
            if vp.X <= 0 or vp.Y <= 0 then return end
            local scale = math.min(vp.X / 1920, vp.Y / 1080)
            uiScale.Scale = scale
            safeFrame.Size = UDim2.new(0, vp.X / scale, 0, vp.Y / scale)
        end
        table.insert(invConnections, camera:GetPropertyChangedSignal("ViewportSize"):Connect(update))
        update()
        
        local W, H = 860, 560
        
        local main = Instance.new("Frame")
        main.Size = UDim2.new(0, W, 0, H)
        main.AnchorPoint = Vector2.new(0.5, 0.5)
        main.Position = UDim2.new(0.5, 0, 0.5, 0)
        main.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
        main.BorderSizePixel = 0
        main.ZIndex = 1
        main.Parent = safeFrame
        
        local mainCorner = Instance.new("UICorner")
        mainCorner.CornerRadius = UDim.new(0, 10)
        mainCorner.Parent = main
        
        local mainStroke = Instance.new("UIStroke")
        mainStroke.Thickness = 3
        mainStroke.Color = Color3.fromRGB(50, 50, 50)
        mainStroke.Parent = main
        
        local mainStudTex = Instance.new("ImageLabel")
        mainStudTex.Size = UDim2.new(1, 0, 1, 0)
        mainStudTex.Position = UDim2.new(0, 0, 0, 0)
        mainStudTex.BackgroundTransparency = 1
        mainStudTex.Image = studTextureId
        mainStudTex.ImageTransparency = 0.92
        mainStudTex.ScaleType = Enum.ScaleType.Tile
        mainStudTex.TileSize = UDim2.new(0, 50, 0, 50)
        mainStudTex.ZIndex = 2
        mainStudTex.Parent = main
        
        local mainStudCorner = Instance.new("UICorner")
        mainStudCorner.CornerRadius = UDim.new(0, 10)
        mainStudCorner.Parent = mainStudTex
        
        local topH = 50
        local topClipper, topBar = makeTopBar(main, W, topH)
        
        local titleText = Instance.new("TextLabel")
        titleText.Size = UDim2.new(0, W - 120, 0, topH)
        titleText.Position = UDim2.new(0, 14, 0, 0)
        titleText.BackgroundTransparency = 1
        titleText.Text = "Trading with " .. partner.Name
        titleText.TextColor3 = Color3.new(1, 1, 1)
        titleText.Font = Enum.Font.FredokaOne
        titleText.TextScaled = false
        titleText.TextSize = 22
        titleText.TextXAlignment = Enum.TextXAlignment.Left
        titleText.ZIndex = 5
        titleText.Parent = topClipper
        
        local titleStroke = Instance.new("UIStroke")
        titleStroke.Thickness = 2
        titleStroke.Color = Color3.new(0, 0, 0)
        titleStroke.Parent = titleText
        
        local closeBtn = Instance.new("TextButton")
        closeBtn.Size = UDim2.new(0, 42, 0, 32)
        closeBtn.Position = UDim2.new(0, W - 50, 0, 9)
        closeBtn.BackgroundColor3 = Color3.fromRGB(180, 18, 18)
        closeBtn.BorderSizePixel = 0
        closeBtn.Text = "✕"
        closeBtn.TextColor3 = Color3.new(1, 1, 1)
        closeBtn.Font = Enum.Font.FredokaOne
        closeBtn.TextScaled = false
        closeBtn.TextSize = 16
        closeBtn.ZIndex = 6
        closeBtn.AutoButtonColor = false
        closeBtn.Parent = topClipper
        
        local closeBtnCorner = Instance.new("UICorner")
        closeBtnCorner.CornerRadius = UDim.new(0, 6)
        closeBtnCorner.Parent = closeBtn
        
        local closeBtnStroke = Instance.new("UIStroke")
        closeBtnStroke.Thickness = 2
        closeBtnStroke.Color = Color3.new(0, 0, 0)
        closeBtnStroke.Parent = closeBtn
        
        local closeTxtStroke = Instance.new("UIStroke")
        closeTxtStroke.Thickness = 2
        closeTxtStroke.Color = Color3.new(0, 0, 0)
        closeTxtStroke.Parent = closeBtn
        
        local divider = Instance.new("Frame")
        divider.Size = UDim2.new(0, W - 20, 0, 1)
        divider.Position = UDim2.new(0, 10, 0, topH)
        divider.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        divider.BorderSizePixel = 0
        divider.ZIndex = 2
        divider.Parent = main
        
        local btnH = 42
        local btnY = H - btnH - 12
        local containerY = topH + 10
        local containerH = btnY - containerY - 10
        local containerW = math.floor((W - 30) / 2)
        
        local myScroll, myFrame = makeContainer(main, "Your Offer", 10, containerY, containerW, containerH)
        local theirScroll, theirFrame = makeContainer(main, partner.Name .. "'s Offer", 20 + containerW, containerY, containerW, containerH)
        
        local btnW = containerW
        local readyBtn, readyGrad, readyLbl = createStyledButton(main, "Ready", "Green", 10, btnY, btnW, btnH, 3)
        local cancelBtn, cancelGrad, cancelLbl = createStyledButton(main, "Cancel", "Red", 20 + btnW, btnY, btnW, btnH, 3)
        
        local overlay = Instance.new("Frame")
        overlay.Size = UDim2.new(0, W, 0, H)
        overlay.Position = UDim2.new(0, 0, 0, 0)
        overlay.BackgroundTransparency = 0.45
        overlay.BackgroundColor3 = Color3.new(0, 0, 0)
        overlay.Visible = false
        overlay.ZIndex = 10
        overlay.Parent = main
        
        local overlayCorner = Instance.new("UICorner")
        overlayCorner.CornerRadius = UDim.new(0, 10)
        overlayCorner.Parent = overlay
        
        local timerTxt = Instance.new("TextLabel")
        timerTxt.Size = UDim2.new(0, W, 0, H)
        timerTxt.Position = UDim2.new(0, 0, 0, 0)
        timerTxt.BackgroundTransparency = 1
        timerTxt.TextColor3 = Color3.new(1, 1, 1)
        timerTxt.TextScaled = false
        timerTxt.TextSize = 72
        timerTxt.Font = Enum.Font.FredokaOne
        timerTxt.Text = "5"
        timerTxt.ZIndex = 11
        timerTxt.Parent = overlay
        
        local tStroke = Instance.new("UIStroke")
        tStroke.Thickness = 4
        tStroke.Color = Color3.new(0, 0, 0)
        tStroke.Parent = timerTxt
        
        local myOfferedIDs = {}
        
        local function getAllToolsVisible()
            local tools = {}
            local backpack = player:FindFirstChild("Backpack")
            if backpack then
                for _, t in pairs(backpack:GetChildren()) do
                    if t:IsA("Tool") then
                        table.insert(tools, t)
                    end
                end
            end
            if player.Character then
                for _, t in pairs(player.Character:GetChildren()) do
                    if t:IsA("Tool") then
                        table.insert(tools, t)
                    end
                end
            end
            table.sort(tools, function(a, b)
                return a.Name:lower() < b.Name:lower()
            end)
            return tools
        end
        
        local function renderInventory()
            for _, v in pairs(myScroll:GetChildren()) do
                if v:IsA("GuiButton") then v:Destroy() end
            end
            local tools = getAllToolsVisible()
            for _, tool in ipairs(tools) do
                local tag = tool:WaitForChild("__TradeID", 1)
                if not tag then continue end
                local toolId = tag.Value
                local isSelected = myOfferedIDs[toolId] == true
                local btn, strk = createItemCell(myScroll, tool.TextureId, isSelected)
                btn.Activated:Connect(function()
                    if not checkDebounce() or timerLocked then return end
                    if myOfferedIDs[toolId] then
                        myOfferedIDs[toolId] = nil
                        strk.Thickness = 0
                    else
                        myOfferedIDs[toolId] = true
                        strk.Thickness = 2.5
                    end
                    tradeEvent:FireServer("ToggleItem", toolId)
                end)
            end
        end
        
        renderInventory()
        
        local backpack = player:FindFirstChild("Backpack")
        if backpack then
            table.insert(invConnections, backpack.ChildAdded:Connect(renderInventory))
            table.insert(invConnections, backpack.ChildRemoved:Connect(renderInventory))
        end
        
        if player.Character then
            table.insert(invConnections, player.Character.ChildAdded:Connect(function(child)
                if child:IsA("Tool") then
                    renderInventory()
                end
            end))
            table.insert(invConnections, player.Character.ChildRemoved:Connect(function(child)
                if child:IsA("Tool") then
                    renderInventory()
                end
            end))
        end
        
        table.insert(invConnections, player.CharacterAdded:Connect(function(char)
            table.insert(invConnections, char.ChildAdded:Connect(function(child)
                if child:IsA("Tool") then renderInventory() end
            end))
            table.insert(invConnections, char.ChildRemoved:Connect(function(child)
                if child:IsA("Tool") then renderInventory() end
            end))
        end))
        
        readyBtn.Activated:Connect(function()
            if not checkDebounce() or timerLocked then return end
            tradeEvent:FireServer("ToggleReady")
        end)
        
        closeBtn.Activated:Connect(function()
            if not checkDebounce() then return end
            tradeEvent:FireServer("Cancel")
        end)
        
        cancelBtn.Activated:Connect(function()
            if not checkDebounce() then return end
            tradeEvent:FireServer("Cancel")
        end)
        
        return {
        GUI = gui,
        RenderInv = renderInventory,
        MyOfferedIDs = myOfferedIDs,
        TheirContainer = theirScroll,
        MyContainer = myScroll,
        MyFrame = myFrame,
        TheirFrame = theirFrame,
        Overlay = overlay,
        TimerTxt = timerTxt,
        SetTimerSize = function(sz)
            timerTxt.TextSize = sz
        end,
        SetReadyVisual = function(myReady, theirReady)
            if myReady then
                readyLbl.Text = "Unready"
                readyGrad.Color = ColorSequence.new(Color3.fromRGB(130, 18, 18), Color3.fromRGB(75, 5, 5))
                myFrame.BackgroundColor3 = Color3.fromRGB(18, 65, 18)
            else
                readyLbl.Text = "Ready"
                readyGrad.Color = ColorSequence.new(Color3.fromRGB(20, 150, 20), Color3.fromRGB(8, 80, 8))
                myFrame.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
            end
            theirFrame.BackgroundColor3 = theirReady and Color3.fromRGB(18, 65, 18) or Color3.fromRGB(22, 22, 22)
        end
        }
    end
    
    local function showPrompt(requester)
        for _, v in pairs(player.PlayerGui:GetChildren()) do
            if v.Name == "TradePromptUI" then v:Destroy() end
        end
        
        local sg = Instance.new("ScreenGui")
        sg.Name = "TradePromptUI"
        sg.ResetOnSpawn = false
        sg.IgnoreGuiInset = true
        sg.Parent = player.PlayerGui
        
        local uiScale = Instance.new("UIScale")
        uiScale.Parent = sg
        
        local safeFrame = Instance.new("Frame")
        safeFrame.Name = "SafeFrame"
        safeFrame.AnchorPoint = Vector2.new(0.5, 0.5)
        safeFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
        safeFrame.BackgroundTransparency = 1
        safeFrame.Parent = sg
        
        local promptConnections = {}
        local function update()
            local vp = camera.ViewportSize
            if vp.X <= 0 or vp.Y <= 0 then return end
            local scale = math.min(vp.X / 1920, vp.Y / 1080)
            uiScale.Scale = scale
            safeFrame.Size = UDim2.new(0, vp.X / scale, 0, vp.Y / scale)
        end
        table.insert(promptConnections, camera:GetPropertyChangedSignal("ViewportSize"):Connect(update))
        update()
        
        local PW, PH = 420, 210
        
        local fr = Instance.new("Frame")
        fr.Size = UDim2.new(0, PW, 0, PH)
        fr.AnchorPoint = Vector2.new(0.5, 0.5)
        fr.Position = UDim2.new(0.5, 0, 0.5, 0)
        fr.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
        fr.BorderSizePixel = 0
        fr.Parent = safeFrame
        
        local frCorner = Instance.new("UICorner")
        frCorner.CornerRadius = UDim.new(0, 10)
        frCorner.Parent = fr
        
        local frStroke = Instance.new("UIStroke")
        frStroke.Thickness = 3
        frStroke.Color = Color3.fromRGB(50, 50, 50)
        frStroke.Parent = fr
        
        local frStudTex = Instance.new("ImageLabel")
        frStudTex.Size = UDim2.new(1, 0, 1, 0)
        frStudTex.Position = UDim2.new(0, 0, 0, 0)
        frStudTex.BackgroundTransparency = 1
        frStudTex.Image = studTextureId
        frStudTex.ImageTransparency = 0.92
        frStudTex.ScaleType = Enum.ScaleType.Tile
        frStudTex.TileSize = UDim2.new(0, 50, 0, 50)
        frStudTex.ZIndex = 2
        frStudTex.Parent = fr
        
        local frStudCorner = Instance.new("UICorner")
        frStudCorner.CornerRadius = UDim.new(0, 10)
        frStudCorner.Parent = frStudTex
        
        local topH = 44
        local topClipper, topAccent = makeTopBar(fr, PW, topH)
        
        local headerLbl = Instance.new("TextLabel")
        headerLbl.Size = UDim2.new(0, PW - 16, 0, topH)
        headerLbl.Position = UDim2.new(0, 8, 0, 0)
        headerLbl.BackgroundTransparency = 1
        headerLbl.Text = "Trade Request"
        headerLbl.TextColor3 = Color3.new(1, 1, 1)
        headerLbl.Font = Enum.Font.FredokaOne
        headerLbl.TextScaled = false
        headerLbl.TextSize = 20
        headerLbl.ZIndex = 5
        headerLbl.Parent = topClipper
        
        local headerStroke = Instance.new("UIStroke")
        headerStroke.Thickness = 2
        headerStroke.Color = Color3.new(0, 0, 0)
        headerStroke.Parent = headerLbl
        
        local txt = Instance.new("TextLabel")
        txt.Text = requester.Name .. " wants to trade with you!"
        txt.TextColor3 = Color3.fromRGB(200, 200, 200)
        txt.Size = UDim2.new(0, PW - 24, 0, 48)
        txt.Position = UDim2.new(0, 12, 0, topH + 6)
        txt.BackgroundTransparency = 1
        txt.Font = Enum.Font.FredokaOne
        txt.TextScaled = false
        txt.TextSize = 17
        txt.TextWrapped = true
        txt.ZIndex = 3
        txt.Parent = fr
        
        local txtStroke = Instance.new("UIStroke")
        txtStroke.Thickness = 1
        txtStroke.Color = Color3.new(0, 0, 0)
        txtStroke.Parent = txt
        
        local btnBW = math.floor((PW - 30) / 2)
        local btnBH = 40
        local btnBY = PH - btnBH - 12
        
        local yBtn, yGrad, yLbl = createStyledButton(fr, "Accept", "Green", 10, btnBY, btnBW, btnBH, 5)
        local nBtn, nGrad, nLbl = createStyledButton(fr, "Decline", "Red", 20 + btnBW, btnBY, btnBW, btnBH, 5)
        
        local function destroyPrompt()
            for _, conn in ipairs(promptConnections) do
                if conn.Connected then conn:Disconnect() end
            end
            if sg and sg.Parent then sg:Destroy() end
        end
        
        yBtn.Activated:Connect(function()
            if not checkDebounce() then return end
            destroyPrompt()
            tradeEvent:FireServer("AcceptRequest", requester.UserId)
        end)
        
        nBtn.Activated:Connect(function()
            if not checkDebounce() then return end
            destroyPrompt()
            tradeEvent:FireServer("DeclineRequest", requester.UserId)
        end)
        
        task.delay(10, destroyPrompt)
    end
    
    table.insert(connections, RunService.RenderStepped:Connect(function()
        if isTrading or not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
            if activeHighlight then
                activeHighlight:Destroy()
                activeHighlight = nil
            end
            currentTarget = nil
            return
        end
        
        local closest, minDist = nil, 15
        local rootPos = player.Character.HumanoidRootPart.Position
        
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= player and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                local d = (rootPos - p.Character.HumanoidRootPart.Position).Magnitude
                if d < minDist then
                    closest = p
                    minDist = d
                end
            end
        end
        
        currentTarget = closest
        
        if closest then
            if not activeHighlight then
                activeHighlight = highlight:Clone()
                activeHighlight.Parent = workspace
            end
            activeHighlight.Adornee = closest.Character
        else
            if activeHighlight then
                activeHighlight:Destroy()
                activeHighlight = nil
            end
        end
    end))
    
    table.insert(connections, UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe or isTrading or not currentTarget then return end
        if hasPendingOutgoing then return end
        
        local isClickOrTouch = (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch)
        local isGamepadTradeBtn = (input.KeyCode == Enum.KeyCode.ButtonX)
        
        if isClickOrTouch then
            local inputPos = input.Position
            local ray = camera:ViewportPointToRay(inputPos.X, inputPos.Y)
            local params = RaycastParams.new()
            params.FilterType = Enum.RaycastFilterType.Exclude
            if player.Character then
                params.FilterDescendantsInstances = {player.Character}
            end
            
            local result = workspace:Raycast(ray.Origin, ray.Direction * 150, params)
            if not result or not result.Instance then return end
            
            local clickedModel = result.Instance:FindFirstAncestorOfClass("Model")
            if clickedModel ~= currentTarget.Character then return end
        elseif not isGamepadTradeBtn then
            return
        end
        
        if checkDebounce() then
            hasPendingOutgoing = true
            local success, reason = tradeFunction:InvokeServer(currentTarget)
            if not success then
                hasPendingOutgoing = false
            end
        end
    end))
    
    table.insert(connections, tradeEvent.OnClientEvent:Connect(function(action, data, data2)
        if action == "Prompt" then
            showPrompt(data)
            
        elseif action == "StartSession" then
            for _, v in pairs(player.PlayerGui:GetChildren()) do
                if v.Name == "TradePromptUI" then v:Destroy() end
            end
            isTrading = true
            hasPendingOutgoing = false
            activeSession = buildTradeUI(data)
            
        elseif action == "UpdateView" then
            if not activeSession then return end
            
            for _, c in pairs(activeSession.TheirContainer:GetChildren()) do
                if c:IsA("GuiButton") then c:Destroy() end
            end
            if data2 then
                for _, itemData in pairs(data2) do
                    createItemCell(activeSession.TheirContainer, itemData.Texture, false)
                end
            end
            
            activeSession.MyOfferedIDs = {}
            if data then
                for _, itemData in pairs(data) do
                    activeSession.MyOfferedIDs[itemData.ID] = true
                end
            end
            activeSession.RenderInv()
            
        elseif action == "UpdateStatus" then
            if activeSession then
                activeSession.SetReadyVisual(data, data2)
            end
            
        elseif action == "TimerUpdate" then
            if activeSession then
                activeSession.Overlay.Visible = true
                if data == 0 then
                    timerLocked = true
                    activeSession.TimerTxt.Text = "Processing..."
                    activeSession.SetTimerSize(36)
                else
                    activeSession.TimerTxt.Text = tostring(data)
                    activeSession.SetTimerSize(72)
                end
            end
            
        elseif action == "HideTimer" then
            if activeSession then
                activeSession.Overlay.Visible = false
                timerLocked = false
            end
            
        elseif action == "Close" then
            isTrading = false
            hasPendingOutgoing = false
            timerLocked = false
            if tradeGui then
                tradeGui:Destroy()
                tradeGui = nil
            end
            for _, conn in ipairs(invConnections) do
                if conn.Connected then conn:Disconnect() end
            end
            table.clear(invConnections)
            activeSession = nil
            
        elseif action == "RequestExpired" or action == "RequestDeclined" then
            hasPendingOutgoing = false
        end
    end))
