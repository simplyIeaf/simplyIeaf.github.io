-- made by @simplyIeaf1 on youtube
 
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
 
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
 
local ADMIN_UIDS = {8033814042}
 
local function isAdmin()
    for _, uid in ipairs(ADMIN_UIDS) do
        if player.UserId == uid then
            return true
        end
    end
    return false
end
 
local function calculateUIScale()
    local camera = workspace.CurrentCamera
    if not camera then return 1 end
    local viewportSize = camera.ViewportSize
    
    local baseWidth = 1920
    local baseHeight = 1080
    
    local widthScale = viewportSize.X / baseWidth
    local heightScale = viewportSize.Y / baseHeight
    
    local scale = math.min(widthScale, heightScale)
    
    scale = math.max(scale, 0.7)
    
    return scale
end
 
local commandsList = {
":kill [player/all/others/me] - Kills the specified player(s)",
":respawn [player] - Respawns the player",
":freeze [player] - Freezes the player in place",
":unfreeze [player] - Unfreezes the player",
":ff [player] - Adds forcefield to player",
":unff [player] - Removes forcefield from player",
":fire [player] - Sets player on fire",
":unfire [player] - Removes fire from player",
":smoke [player] - Adds smoke effect to player",
":unsmoke [player] - Removes smoke from player",
":sparkles [player] - Adds sparkles to player",
":unsparkles [player] - Removes sparkles from player",
":jump [player] - Makes player jump",
":sit [player] - Makes player sit",
":smallhead [player] - Shrinks player's head",
":normalhead [player] - Resets player's head size",
":invisible [player] - Makes player invisible",
":visible [player] - Makes player visible",
":god [player] - Gives player god mode",
":ungod [player] - Removes god mode",
":heal [player] - Heals the player",
":explode [player] - Explodes the player",
":stun [player] - Stuns the player",
":unstun [player] - Unstuns the player",
":trip [player] - Trips the player",
":loopkill [player] - Repeatedly kills the player",
":kick [player] - Kicks the player",
":givetools [player] - Gives tools to player",
":removetools [player] - Removes tools from player",
":shirt [player] <id> - Changes player's shirt",
":pants [player] <id> - Changes player's pants",
":hat [player] <id> - Gives hat to player",
":clearhats [player] - Removes accessories",
":paint [player] <color hex> - Paints player",
":transparency [player] <value> - Sets transparency",
":spin [player] <speed> - Spins the player",
":refresh [player] - Clears effects from player",
":punish [player] - Punishes the player",
":unpunish [player] - Unpunishes the player",
":ice [player] - Traps player in ice",
":ghost [player] - Makes player ghostly",
":neon [player] - Makes player neon",
":glass [player] - Makes player glass",
":gold [player] - Makes player gold",
":shine [player] - Adds shine to player",
":fart [player] - Makes player fart",
":tp [player] [target] - Teleports player to target",
":speed [player] <value> - Sets walk speed",
":jumppower [player] <value> - Sets jump power",
":reset [player] - Resets the player"
}
 
local screenGui
local cmdButton
local currentMainFrame
 
local function createGUI()
    if screenGui then
        screenGui:Destroy()
    end
    
    local AdminCommand = ReplicatedStorage:WaitForChild("AdminCommand")
    
    screenGui = Instance.new("ScreenGui")
    screenGui.Name = "CMDGui"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = playerGui
    
    cmdButton = Instance.new("TextButton")
    cmdButton.Name = "CMDButton"
    cmdButton.Parent = screenGui
    
    local initialScale = calculateUIScale()
    
    cmdButton.Size = UDim2.new(0, 80, 0, 30)
    cmdButton.Position = UDim2.new(1, -90, 0, 10)
    cmdButton.AnchorPoint = Vector2.new(0, 0)
    cmdButton.BackgroundColor3 = Color3.new(0, 0, 0)
    cmdButton.BackgroundTransparency = 0.3
    cmdButton.BorderSizePixel = 0
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 15)
    corner.Parent = cmdButton
    
    cmdButton.Text = "CMD"
    cmdButton.TextColor3 = Color3.new(1, 1, 1)
    cmdButton.TextScaled = true
    cmdButton.Font = Enum.Font.GothamBold
    
    local textSizeConstraint = Instance.new("UITextSizeConstraint")
    textSizeConstraint.MaxTextSize = 14
    textSizeConstraint.Parent = cmdButton
    
    local function onHover()
        local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        local tween = TweenService:Create(cmdButton, tweenInfo, {BackgroundTransparency = 0.1})
        tween:Play()
    end
    
    local function onLeave()
        local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        local tween = TweenService:Create(cmdButton, tweenInfo, {BackgroundTransparency = 0.3})
        tween:Play()
    end
    
    cmdButton.MouseEnter:Connect(onHover)
    cmdButton.MouseLeave:Connect(onLeave)
    
    local dragging
    local dragInput
    local dragStart
    local startPos
    
    local function update(input)
        local delta = input.Position - dragStart
        cmdButton.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
    
    cmdButton.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = cmdButton.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    
    cmdButton.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            update(input)
        end
    end)
    
    local function transition(current, new, forward)
        local outDir = forward and -1 or 1
        local inDir = forward and 1 or -1
        local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        
        if current then
            current.Position = UDim2.new(0, 0, 0, 0)
            local tweenOut = TweenService:Create(current, tweenInfo, {Position = UDim2.new(outDir, 0, 0, 0)})
            tweenOut:Play()
            tweenOut.Completed:Connect(function()
                current.Visible = false
            end)
        end
        
        new.Position = UDim2.new(inDir, 0, 0, 0)
        new.Visible = true
        local tweenIn = TweenService:Create(new, tweenInfo, {Position = UDim2.new(0, 0, 0, 0)})
        tweenIn:Play()
    end
    
    local function createMainGUI()
        local uiScale = calculateUIScale()
        
        local mainFrame = Instance.new("Frame")
        mainFrame.Name = "MainCMDFrame"
        mainFrame.Parent = screenGui
        mainFrame.Size = UDim2.new(0, 400 * uiScale, 0, 300 * uiScale)
        mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
        mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
        mainFrame.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
        mainFrame.BorderSizePixel = 0
        mainFrame.ClipsDescendants = true
        
        local mainCorner = Instance.new("UICorner")
        mainCorner.CornerRadius = UDim.new(0, 10 * uiScale)
        mainCorner.Parent = mainFrame
        
        local titleBar = Instance.new("Frame")
        titleBar.Name = "TitleBar"
        titleBar.Parent = mainFrame
        titleBar.Size = UDim2.new(1, 0, 0, 30 * uiScale)
        titleBar.Position = UDim2.new(0, 0, 0, 0)
        titleBar.BackgroundColor3 = Color3.new(0.05, 0.05, 0.05)
        titleBar.BorderSizePixel = 0
        
        local titleCorner = Instance.new("UICorner")
        titleCorner.CornerRadius = UDim.new(0, 10 * uiScale)
        titleCorner.Parent = titleBar
        
        local titleFix = Instance.new("Frame")
        titleFix.Parent = titleBar
        titleFix.Size = UDim2.new(1, 0, 0, 10 * uiScale)
        titleFix.Position = UDim2.new(0, 0, 1, -10 * uiScale)
        titleFix.BackgroundColor3 = Color3.new(0.05, 0.05, 0.05)
        titleFix.BorderSizePixel = 0
        
        local titleLabel = Instance.new("TextLabel")
        titleLabel.Parent = titleBar
        titleLabel.Size = UDim2.new(1, -60 * uiScale, 1, 0)
        titleLabel.Position = UDim2.new(0, 10 * uiScale, 0, 0)
        titleLabel.BackgroundTransparency = 1
        titleLabel.Text = "Admin Panel"
        titleLabel.TextColor3 = Color3.new(1, 1, 1)
        titleLabel.Font = Enum.Font.GothamBold
        titleLabel.TextScaled = true
        titleLabel.TextXAlignment = Enum.TextXAlignment.Left
        
        local closeButton = Instance.new("TextButton")
        closeButton.Parent = titleBar
        closeButton.Size = UDim2.new(0, 25 * uiScale, 0, 25 * uiScale)
        closeButton.Position = UDim2.new(1, -30 * uiScale, 0, 2.5 * uiScale)
        closeButton.BackgroundColor3 = Color3.new(0.8, 0.2, 0.2)
        closeButton.Text = "X"
        closeButton.TextColor3 = Color3.new(1, 1, 1)
        closeButton.Font = Enum.Font.GothamBold
        closeButton.TextScaled = true
        closeButton.BorderSizePixel = 0
        
        local closeCorner = Instance.new("UICorner")
        closeCorner.CornerRadius = UDim.new(0, 5 * uiScale)
        closeCorner.Parent = closeButton
        
        closeButton.MouseButton1Click:Connect(function()
            mainFrame:Destroy()
            currentMainFrame = nil
        end)
        
        local contentFrame = Instance.new("Frame")
        contentFrame.Parent = mainFrame
        contentFrame.Size = UDim2.new(1, -20 * uiScale, 1, -50 * uiScale)
        contentFrame.Position = UDim2.new(0, 10 * uiScale, 0, 40 * uiScale)
        contentFrame.BackgroundTransparency = 1
        
        local homeFrame = Instance.new("Frame")
        homeFrame.Parent = contentFrame
        homeFrame.Size = UDim2.new(1, 0, 1, 0)
        homeFrame.Position = UDim2.new(0, 0, 0, 0)
        homeFrame.BackgroundTransparency = 1
        homeFrame.Visible = true
        
        local menuFrame = Instance.new("Frame")
        menuFrame.Parent = homeFrame
        menuFrame.Size = UDim2.new(0, 200 * uiScale, 0, 95 * uiScale)
        menuFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
        menuFrame.AnchorPoint = Vector2.new(0.5, 0.5)
        menuFrame.BackgroundTransparency = 1
        
        local menuLayout = Instance.new("UIListLayout")
        menuLayout.Parent = menuFrame
        menuLayout.FillDirection = Enum.FillDirection.Vertical
        menuLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        menuLayout.VerticalAlignment = Enum.VerticalAlignment.Center
        menuLayout.Padding = UDim.new(0, 15 * uiScale)
        
        local commandsButton = Instance.new("TextButton")
        commandsButton.Parent = menuFrame
        commandsButton.Size = UDim2.new(1, 0, 0, 40 * uiScale)
        commandsButton.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
        commandsButton.Text = "Commands"
        commandsButton.TextColor3 = Color3.new(1, 1, 1)
        commandsButton.Font = Enum.Font.GothamBold
        commandsButton.TextScaled = true
        local cmdBtnCorner = Instance.new("UICorner")
        cmdBtnCorner.CornerRadius = UDim.new(0, 5 * uiScale)
        cmdBtnCorner.Parent = commandsButton
        
        local executionButton = Instance.new("TextButton")
        executionButton.Parent = menuFrame
        executionButton.Size = UDim2.new(1, 0, 0, 40 * uiScale)
        executionButton.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
        executionButton.Text = "Execution"
        executionButton.TextColor3 = Color3.new(1, 1, 1)
        executionButton.Font = Enum.Font.GothamBold
        executionButton.TextScaled = true
        local execBtnCorner = Instance.new("UICorner")
        execBtnCorner.CornerRadius = UDim.new(0, 5 * uiScale)
        execBtnCorner.Parent = executionButton
        
        local commandsTab = Instance.new("Frame")
        commandsTab.Parent = contentFrame
        commandsTab.Size = UDim2.new(1, 0, 1, 0)
        commandsTab.Position = UDim2.new(0, 0, 0, 0)
        commandsTab.BackgroundTransparency = 1
        commandsTab.Visible = false
        
        local cmdBackButton = Instance.new("TextButton")
        cmdBackButton.Parent = commandsTab
        cmdBackButton.Size = UDim2.new(0, 80 * uiScale, 0, 30 * uiScale)
        cmdBackButton.Position = UDim2.new(1, -10 * uiScale, 1, -10 * uiScale)
        cmdBackButton.AnchorPoint = Vector2.new(1, 1)
        cmdBackButton.BackgroundColor3 = Color3.new(0.3, 0.3, 0.3)
        cmdBackButton.Text = "Back"
        cmdBackButton.TextColor3 = Color3.new(1, 1, 1)
        cmdBackButton.Font = Enum.Font.GothamBold
        cmdBackButton.TextScaled = true
        cmdBackButton.ZIndex = 2
        local cmdBackCorner = Instance.new("UICorner")
        cmdBackCorner.CornerRadius = UDim.new(0, 5 * uiScale)
        cmdBackCorner.Parent = cmdBackButton
        
        local searchBox = Instance.new("TextBox")
        searchBox.Parent = commandsTab
        searchBox.Size = UDim2.new(1, -20 * uiScale, 0, 30 * uiScale)
        searchBox.Position = UDim2.new(0, 10 * uiScale, 0, 10 * uiScale)
        searchBox.BackgroundColor3 = Color3.new(0.15, 0.15, 0.15)
        searchBox.TextColor3 = Color3.new(1, 1, 1)
        searchBox.PlaceholderText = "Search commands"
        searchBox.Font = Enum.Font.Gotham
        searchBox.TextScaled = true
        local searchCorner = Instance.new("UICorner")
        searchCorner.CornerRadius = UDim.new(0, 5 * uiScale)
        searchCorner.Parent = searchBox
        
        local scrollingFrame = Instance.new("ScrollingFrame")
        scrollingFrame.Parent = commandsTab
        scrollingFrame.Size = UDim2.new(1, -20 * uiScale, 1, -60 * uiScale)
        scrollingFrame.Position = UDim2.new(0, 10 * uiScale, 0, 50 * uiScale)
        scrollingFrame.BackgroundTransparency = 1
        scrollingFrame.ScrollBarThickness = 5 * uiScale
        scrollingFrame.ClipsDescendants = true
        
        local listLayout = Instance.new("UIListLayout")
        listLayout.Parent = scrollingFrame
        listLayout.Padding = UDim.new(0, 5 * uiScale)
        listLayout.SortOrder = Enum.SortOrder.LayoutOrder
        
        for i, cmdDesc in ipairs(commandsList) do
            local cmdLabel = Instance.new("TextLabel")
            cmdLabel.Parent = scrollingFrame
            cmdLabel.Size = UDim2.new(1, 0, 0, 30 * uiScale)
            cmdLabel.BackgroundTransparency = 1
            cmdLabel.Text = cmdDesc
            cmdLabel.TextColor3 = Color3.new(0.9, 0.9, 0.9)
            cmdLabel.Font = Enum.Font.Gotham
            cmdLabel.TextXAlignment = Enum.TextXAlignment.Left
            cmdLabel.TextScaled = true
            cmdLabel.TextWrapped = true
            cmdLabel.LayoutOrder = i
        end
        
        listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            scrollingFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y)
        end)
        
        searchBox:GetPropertyChangedSignal("Text"):Connect(function()
            local searchText = searchBox.Text:lower()
            for _, child in ipairs(scrollingFrame:GetChildren()) do
                if child:IsA("TextLabel") then
                    child.Visible = (searchText == "" or child.Text:lower():find(searchText))
                end
            end
        end)
        
        local executionTab = Instance.new("Frame")
        executionTab.Parent = contentFrame
        executionTab.Size = UDim2.new(1, 0, 1, 0)
        executionTab.Position = UDim2.new(0, 0, 0, 0)
        executionTab.BackgroundTransparency = 1
        executionTab.Visible = false
        
        local execBackButton = Instance.new("TextButton")
        execBackButton.Parent = executionTab
        execBackButton.Size = UDim2.new(0, 80 * uiScale, 0, 30 * uiScale)
        execBackButton.Position = UDim2.new(1, -10 * uiScale, 1, -10 * uiScale)
        execBackButton.AnchorPoint = Vector2.new(1, 1)
        execBackButton.BackgroundColor3 = Color3.new(0.3, 0.3, 0.3)
        execBackButton.Text = "Back"
        execBackButton.TextColor3 = Color3.new(1, 1, 1)
        execBackButton.Font = Enum.Font.GothamBold
        execBackButton.TextScaled = true
        execBackButton.ZIndex = 2
        local execBackCorner = Instance.new("UICorner")
        execBackCorner.CornerRadius = UDim.new(0, 5 * uiScale)
        execBackCorner.Parent = execBackButton
        
        local execInputFrame = Instance.new("Frame")
        execInputFrame.Parent = executionTab
        execInputFrame.Size = UDim2.new(0, 300 * uiScale, 0, 40 * uiScale)
        execInputFrame.Position = UDim2.new(0.5, 0, 0.5, -20 * uiScale)
        execInputFrame.AnchorPoint = Vector2.new(0.5, 0.5)
        execInputFrame.BackgroundTransparency = 1
        
        local execLayout = Instance.new("UIListLayout")
        execLayout.Parent = execInputFrame
        execLayout.FillDirection = Enum.FillDirection.Horizontal
        execLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        execLayout.VerticalAlignment = Enum.VerticalAlignment.Center
        execLayout.Padding = UDim.new(0, 10 * uiScale)
        
        local commandBox = Instance.new("TextBox")
        commandBox.Parent = execInputFrame
        commandBox.Size = UDim2.new(0, 200 * uiScale, 1, 0)
        commandBox.BackgroundColor3 = Color3.new(0.15, 0.15, 0.15)
        commandBox.TextColor3 = Color3.new(1, 1, 1)
        commandBox.PlaceholderText = "Enter command (e.g. :kill me)"
        commandBox.Font = Enum.Font.Gotham
        commandBox.TextScaled = true
        local cmdBoxCorner = Instance.new("UICorner")
        cmdBoxCorner.CornerRadius = UDim.new(0, 5 * uiScale)
        cmdBoxCorner.Parent = commandBox
        
        local executeBtn = Instance.new("TextButton")
        executeBtn.Parent = execInputFrame
        executeBtn.Size = UDim2.new(0, 90 * uiScale, 1, 0)
        executeBtn.BackgroundColor3 = Color3.new(0.2, 0.6, 0.2)
        executeBtn.Text = "Execute"
        executeBtn.TextColor3 = Color3.new(1, 1, 1)
        executeBtn.Font = Enum.Font.GothamBold
        executeBtn.TextScaled = true
        local executeCorner = Instance.new("UICorner")
        executeCorner.CornerRadius = UDim.new(0, 5 * uiScale)
        executeCorner.Parent = executeBtn
        
        commandsButton.MouseButton1Click:Connect(function()
            transition(homeFrame, commandsTab, true)
        end)
        
        executionButton.MouseButton1Click:Connect(function()
            transition(homeFrame, executionTab, true)
        end)
        
        cmdBackButton.MouseButton1Click:Connect(function()
            transition(commandsTab, homeFrame, false)
        end)
        
        execBackButton.MouseButton1Click:Connect(function()
            transition(executionTab, homeFrame, false)
        end)
        
        local function executeCommand()
            local input = commandBox.Text
            if input == "" or not input:find(":") then return end
            AdminCommand:FireServer(input)
            commandBox.Text = ""
        end
        
        executeBtn.MouseButton1Click:Connect(executeCommand)
        
        commandBox.FocusLost:Connect(function(enterPressed)
            if enterPressed then
                executeCommand()
            end
        end)
        
        mainFrame.Size = UDim2.new(0, 0, 0, 0)
        local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
        local tween = TweenService:Create(mainFrame, tweenInfo, {Size = UDim2.new(0, 400 * uiScale, 0, 300 * uiScale)})
        tween:Play()
        
        currentMainFrame = mainFrame
        return mainFrame
    end
    
    cmdButton.MouseButton1Click:Connect(function()
        if currentMainFrame then
            currentMainFrame:Destroy()
            currentMainFrame = nil
        else
            createMainGUI()
        end
    end)
end
 
local function onCharacterDied()
    if screenGui then
        screenGui:Destroy()
        screenGui = nil
        cmdButton = nil
        currentMainFrame = nil
    end
end
 
local function onCharacterAdded(character)
    onCharacterDied()
    
    wait(0.1)
    
    -- Create new GUI only if admin
    if isAdmin() then
        createGUI()
    end
    
    local humanoid = character:WaitForChild("Humanoid")
    humanoid.Died:Connect(onCharacterDied)
end
 
if isAdmin() then
    -- Create initial GUI
    createGUI()
    
    if player.Character then
        local humanoid = player.Character:FindFirstChild("Humanoid")
        if humanoid then
            humanoid.Died:Connect(onCharacterDied)
        end
    end
    player.CharacterAdded:Connect(onCharacterAdded)
    player.CharacterRemoving:Connect(onCharacterDied)
end
