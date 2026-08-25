-- made by @simplyIeaf1 on youtube

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer or Players:GetPropertyChangedSignal("LocalPlayer"):Wait() and Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui", 30)

local commandRemote = ReplicatedStorage:WaitForChild("ExecuteCommand", 30)
local getCommandsRemote = ReplicatedStorage:WaitForChild("GetCommands", 30)
local checkAdminRemote = ReplicatedStorage:WaitForChild("CheckAdmin", 30)

local activeConnections = {}
local currentGui = nil
local isAnimating = false
local validCommands = {}
local autocompleteLabel = nil
local isAdmin = false

local function createCommandBarGUI()
    if playerGui:FindFirstChild("CmdBarGui") then
        playerGui.CmdBarGui:Destroy()
    end
    
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "CmdBarGui"
    screenGui.IgnoreGuiInset = true
    screenGui.ResetOnSpawn = true
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = playerGui

    local cmdBar = Instance.new("Frame")
    cmdBar.Name = "CommandBar"
    cmdBar.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    cmdBar.BackgroundTransparency = 0.2
    cmdBar.BorderSizePixel = 0
    cmdBar.AnchorPoint = Vector2.new(0.5, 0.5)
    cmdBar.Position = UDim2.new(0.5, 0, 0.5, 0)
    cmdBar.Size = UDim2.new(0, 0, 0, 60)
    cmdBar.Visible = false
    cmdBar.ZIndex = 10
    cmdBar.Parent = screenGui

    local cornerCmd = Instance.new("UICorner")
    cornerCmd.CornerRadius = UDim.new(0, 12)
    cornerCmd.Parent = cmdBar

    local border = Instance.new("UIStroke")
    border.Name = "Border"
    border.Color = Color3.fromRGB(60, 60, 60)
    border.Thickness = 1
    border.Transparency = 0.5
    border.Parent = cmdBar

    local textBox = Instance.new("TextBox")
    textBox.Name = "CommandInput"
    textBox.BackgroundTransparency = 1
    textBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    textBox.TextSize = 18
    textBox.Font = Enum.Font.GothamMedium
    textBox.PlaceholderText = "Type command..."
    textBox.PlaceholderColor3 = Color3.fromRGB(140, 140, 140)
    textBox.TextXAlignment = Enum.TextXAlignment.Left
    textBox.TextYAlignment = Enum.TextYAlignment.Center
    textBox.ClearTextOnFocus = false
    textBox.Text = ""
    textBox.ZIndex = 11
    textBox.Size = UDim2.new(1, -40, 1, 0)
    textBox.Position = UDim2.new(0, 20, 0, 0)
    textBox.Parent = cmdBar

    local suggestionLabel = Instance.new("TextLabel")
    suggestionLabel.Name = "SuggestionLabel"
    suggestionLabel.BackgroundTransparency = 1
    suggestionLabel.TextColor3 = Color3.fromRGB(140, 140, 140)
    suggestionLabel.TextSize = 18
    suggestionLabel.Font = Enum.Font.GothamMedium
    suggestionLabel.TextXAlignment = Enum.TextXAlignment.Left
    suggestionLabel.TextYAlignment = Enum.TextYAlignment.Center
    suggestionLabel.Text = ""
    suggestionLabel.ZIndex = 10
    suggestionLabel.Size = UDim2.new(1, -40, 1, 0)
    suggestionLabel.Position = UDim2.new(0, 20, 0, 0)
    suggestionLabel.Parent = cmdBar
    autocompleteLabel = suggestionLabel

    if not cmdBar or not textBox then
        screenGui:Destroy()
        return nil
    end

    local mobileButton
    if isAdmin and UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
        mobileButton = Instance.new("TextButton")
        mobileButton.Name = "MobileCmdButton"
        mobileButton.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
        mobileButton.BackgroundTransparency = 0.2
        mobileButton.BorderSizePixel = 0
        mobileButton.AnchorPoint = Vector2.new(1, 0.5)
        mobileButton.Position = UDim2.new(1, -20, 0.5, 0)
        mobileButton.Size = UDim2.new(0, 70, 0, 70)
        mobileButton.Text = "CMD"
        mobileButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        mobileButton.TextSize = 16
        mobileButton.Font = Enum.Font.GothamBold
        mobileButton.ZIndex = 12
        mobileButton.Parent = screenGui

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 16)
        corner.Parent = mobileButton

        local buttonStroke = Instance.new("UIStroke")
        buttonStroke.Color = Color3.fromRGB(60, 60, 60)
        buttonStroke.Thickness = 1
        buttonStroke.Transparency = 0.5
        buttonStroke.Parent = mobileButton

        table.insert(activeConnections, mobileButton.MouseButton1Click:Connect(function()
            if currentGui then
                toggleCmdBar()
            end
        end))
        table.insert(activeConnections, mobileButton.TouchTap:Connect(function()
            if currentGui then
                toggleCmdBar()
            end
        end))

        table.insert(activeConnections, mobileButton.MouseEnter:Connect(function()
            mobileButton.BackgroundTransparency = 0.1
        end))
        table.insert(activeConnections, mobileButton.MouseLeave:Connect(function()
            mobileButton.BackgroundTransparency = 0.2
        end))
    end

    return screenGui
end

local function updateViewportScale()
    if not currentGui then return end
    
    local currentCmdBar = currentGui:FindFirstChild("CommandBar")
    local currentTextBox = currentCmdBar and currentCmdBar:FindFirstChild("CommandInput")
    local currentMobileButton = currentGui:FindFirstChild("MobileCmdButton")
    local currentSuggestionLabel = currentCmdBar and currentCmdBar:FindFirstChild("SuggestionLabel")
    
    if not currentCmdBar or not currentTextBox then return end
    
    local viewportSize = workspace.CurrentCamera.ViewportSize
    local baseWidth = 1920
    local baseHeight = 1080
    
    local scaleX = viewportSize.X / baseWidth
    local scaleY = viewportSize.Y / baseHeight
    local scale = math.min(scaleX, scaleY)
    scale = math.clamp(scale, 0.5, 1.5)
    
    local scaledWidth = 600 * scale
    local scaledHeight = 60 * scale
    currentCmdBar.Size = UDim2.new(0, scaledWidth, 0, scaledHeight)
    
    local scaledTextSize = math.floor(18 * scale)
    local scaledPadding = 20 * scale
    currentTextBox.TextSize = scaledTextSize
    currentTextBox.Size = UDim2.new(1, -2 * scaledPadding, 1, 0)
    currentTextBox.Position = UDim2.new(0, scaledPadding, 0, 0)
    
    if currentSuggestionLabel then
        currentSuggestionLabel.TextSize = scaledTextSize
        currentSuggestionLabel.Size = UDim2.new(1, -2 * scaledPadding, 1, 0)
        currentSuggestionLabel.Position = UDim2.new(0, scaledPadding, 0, 0)
    end
    
    if currentMobileButton then
        local scaledButtonSize = 70 * scale
        local scaledButtonTextSize = math.floor(32 * scale)
        local scaledMargin = 20 * scale
        
        currentMobileButton.Size = UDim2.new(0, scaledButtonSize, 0, scaledButtonSize)
        currentMobileButton.TextSize = scaledButtonTextSize
        currentMobileButton.Position = UDim2.new(1, -scaledMargin, 0.5, 0)
    end
end

function toggleCmdBar()
    if not currentGui or isAnimating or not isAdmin then return end
    
    local currentCmdBar = currentGui:FindFirstChild("CommandBar")
    local currentTextBox = currentCmdBar and currentCmdBar:FindFirstChild("CommandInput")
    
    if not currentCmdBar or not currentTextBox then return end
    
    isAnimating = true
    
    local isCurrentlyVisible = currentCmdBar.Visible and currentCmdBar.Size.X.Offset > 50
    
    if not isCurrentlyVisible then
        currentCmdBar.Visible = true
        currentCmdBar.Size = UDim2.new(0, 0, 0, 60)
        
        local viewportSize = workspace.CurrentCamera.ViewportSize
        local baseWidth = 1920
        local scale = math.min(viewportSize.X / baseWidth, viewportSize.Y / 1080)
        scale = math.clamp(scale, 0.5, 1.5)
        local targetWidth = 600 * scale
        local targetHeight = 60 * scale
        
        local expandTween = TweenService:Create(
            currentCmdBar,
            TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
            {Size = UDim2.new(0, targetWidth, 0, targetHeight)}
        )
        expandTween:Play()
        expandTween.Completed:Wait()
        currentTextBox:CaptureFocus()
        updateViewportScale()
        isAnimating = false
    else
        currentTextBox.TextSize = 1
        currentTextBox:ReleaseFocus()
        task.wait(0.05)
        local shrinkTween = TweenService:Create(
            currentCmdBar,
            TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
            {Size = UDim2.new(0, 0, 0, currentCmdBar.Size.Y.Offset)}
        )
        shrinkTween:Play()
        shrinkTween.Completed:Wait()
        currentCmdBar.Visible = false
        currentTextBox.Text = ""
        updateViewportScale()
        isAnimating = false
    end
end

local function getClosestCommand(partialCommand)
    if #partialCommand == 0 then return "" end
    partialCommand = partialCommand:lower()
    local closestMatch = ""
    local minDistance = math.huge
    
    for _, cmd in ipairs(validCommands) do
        if cmd:lower():sub(1, #partialCommand) == partialCommand then
            local distance = #cmd - #partialCommand
            if distance < minDistance then
                minDistance = distance
                closestMatch = cmd
            end
        end
    end
    return closestMatch
end

local function updateAutocomplete(input)
    if not autocompleteLabel then return end
    local closestCommand = getClosestCommand(input)
    if closestCommand ~= "" and input:lower() ~= closestCommand:lower() then
        autocompleteLabel.Text = input .. closestCommand:sub(#input + 1)
    else
        autocompleteLabel.Text = ""
    end
end

local function connectTextBoxEvents()
    if not currentGui then return end
    
    local currentCmdBar = currentGui:FindFirstChild("CommandBar")
    local currentTextBox = currentCmdBar and currentCmdBar:FindFirstChild("CommandInput")
    
    if not currentCmdBar or not currentTextBox then return end
    
    table.insert(activeConnections, currentTextBox:GetPropertyChangedSignal("Text"):Connect(function()
        local input = currentTextBox.Text
        if #input > 50 then
            currentTextBox.Text = input:sub(1, 50)
            return
        end
        updateAutocomplete(input)
    end))
    
    table.insert(activeConnections, currentTextBox.FocusLost:Connect(function(enterPressed)
        if isAnimating then return end
        if enterPressed then
            local input = currentTextBox.Text
            if #input > 50 or input:match("[^%w]") then
                currentTextBox.Text = ""
                autocompleteLabel.Text = ""
                return
            end
            local commandToExecute = input
            if not table.find(validCommands, input:lower()) then
                commandToExecute = getClosestCommand(input)
            end
            if commandToExecute ~= "" then
                commandRemote:FireServer(commandToExecute)
            end
            currentTextBox.Text = ""
            autocompleteLabel.Text = ""
        end
        task.wait(0.1)
        if currentCmdBar.Visible and currentCmdBar.Size.X.Offset > 50 then
            isAnimating = true
            currentTextBox.TextTransparency = 1
            task.wait(0.05)
            local shrinkTween = TweenService:Create(
                currentCmdBar,
                TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
                {Size = UDim2.new(0, 0, 0, currentCmdBar.Size.Y.Offset)}
            )
            shrinkTween:Play()
            shrinkTween.Completed:Wait()
            currentCmdBar.Visible = false
            currentTextBox.Text = ""
            currentTextBox.TextTransparency = 0
            autocompleteLabel.Text = ""
            isAnimating = false
        end
    end))

    table.insert(activeConnections, currentTextBox.Focused:Connect(function()
        if isAnimating or not isAdmin then return end
        if not currentCmdBar.Visible or currentCmdBar.Size.X.Offset < 50 then
            isAnimating = true
            currentCmdBar.Visible = true
            currentCmdBar.Size = UDim2.new(0, 0, 0, 60)
            
            local viewportSize = workspace.CurrentCamera.ViewportSize
            local baseWidth = 1920
            local scale = math.min(viewportSize.X / baseWidth, viewportSize.Y / 1080)
            scale = math.clamp(scale, 0.5, 1.5)
            local targetWidth = 600 * scale
            local targetHeight = 60 * scale
            
            local expandTween = TweenService:Create(
                currentCmdBar,
                TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
                {Size = UDim2.new(0, targetWidth, 0, targetHeight)}
            )
            expandTween:Play()
            expandTween.Completed:Wait()
            isAnimating = false
        end
    end))
end

table.insert(activeConnections, UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
    if gameProcessedEvent or not isAdmin then return end
    
    if input.KeyCode == Enum.KeyCode.Comma and not UserInputService.TouchEnabled then
        if currentGui then
            toggleCmdBar()
        end
    elseif input.KeyCode == Enum.KeyCode.Escape then
        if not currentGui or isAnimating then return end
        local currentCmdBar = currentGui:FindFirstChild("CommandBar")
        local currentTextBox = currentCmdBar and currentCmdBar:FindFirstChild("CommandInput")
        if currentCmdBar and currentCmdBar.Visible and currentCmdBar.Size.X.Offset > 50 then
            isAnimating = true
            currentTextBox.TextTransparency = 1
            currentTextBox:ReleaseFocus()
            task.wait(0.05)
            local shrinkTween = TweenService:Create(
                currentCmdBar,
                TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
                {Size = UDim2.new(0, 0, 0, currentCmdBar.Size.Y.Offset)}
            )
            shrinkTween:Play()
            shrinkTween.Completed:Wait()
            currentCmdBar.Visible = false
            currentTextBox.Text = ""
            currentTextBox.TextTransparency = 0
            autocompleteLabel.Text = ""
            isAnimating = false
        end
    end
end))

table.insert(activeConnections, UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
    if not currentGui or isAnimating or not isAdmin then return end
    
    local currentCmdBar = currentGui:FindFirstChild("CommandBar")
    local currentTextBox = currentCmdBar and currentCmdBar:FindFirstChild("CommandInput")
    
    if not currentCmdBar or not currentTextBox or not currentCmdBar.Visible or currentCmdBar.Size.X.Offset < 50 then return end
    
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        local mousePos = UserInputService:GetMouseLocation()
        local guiObjects = playerGui:GetGuiObjectsAtPosition(mousePos.X, mousePos.Y)
        local isClickOnCmdBar = false
        
        for _, guiObj in ipairs(guiObjects) do
            if guiObj:IsDescendantOf(currentCmdBar) then
                isClickOnCmdBar = true
                break
            end
        end
        
        if not isClickOnCmdBar then
            isAnimating = true
            currentTextBox.TextTransparency = 1
            currentTextBox:ReleaseFocus()
            task.wait(0.05)
            local shrinkTween = TweenService:Create(
                currentCmdBar,
                TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
                {Size = UDim2.new(0, 0, 0, currentCmdBar.Size.Y.Offset)}
            )
            shrinkTween:Play()
            shrinkTween.Completed:Wait()
            currentCmdBar.Visible = false
            currentTextBox.Text = ""
            currentTextBox.TextTransparency = 0
            autocompleteLabel.Text = ""
            isAnimating = false
        end
    end
end))

local success, err = pcall(function()
    isAdmin = checkAdminRemote:InvokeServer()
    if not isAdmin then
        warn("Player is not an admin, command bar disabled")
        return
    end
    
    validCommands = getCommandsRemote:InvokeServer() or {}
    if #validCommands == 0 then
        error("Failed to retrieve commands")
    end
    
    currentGui = createCommandBarGUI()
    if not currentGui then
        error("GUI creation failed")
    end
    connectTextBoxEvents()
    table.insert(activeConnections, workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
        updateViewportScale()
    end))
    updateViewportScale()
end)

if not success then
    warn("Failed to initialize command bar: " .. tostring(err))
end