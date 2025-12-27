-- made by @simplyIeaf1 on youtube

local GUI_WIDTH = 600
local GUI_HEIGHT = 400
local VOTING_TIME = 10

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local remotesFolder = ReplicatedStorage:WaitForChild("MapVotingRemotes", 30)
if not remotesFolder then
    warn("MapVotingRemotes folder not found in ReplicatedStorage after 30 seconds!")
    return
end

local startVotingRemote = remotesFolder:WaitForChild("StartVoting", 10)
local voteMapRemote = remotesFolder:WaitForChild("VoteMap", 10)
local updateVotesRemote = remotesFolder:WaitForChild("UpdateVotes", 10)
local endVotingRemote = remotesFolder:WaitForChild("EndVoting", 10)

if not (startVotingRemote and voteMapRemote and updateVotesRemote and endVotingRemote) then
    warn("One or more remote events missing in MapVotingRemotes!")
    return
end

local screenGui = nil
local mainFrame = nil
local titleLabel = nil
local timerLabel = nil
local optionsContainer = nil
local mainStroke = nil
local voteLabels = {}
local voteButtons = {}
local currentGlowTween = nil
local currentVote = nil
local timerConnection = nil
local votingStartTime = nil

local isVotingActive = false
local currentMapData = nil
local currentVoteCounts = nil

local function getPlayerGui()
    return player:FindFirstChild("PlayerGui") or player:WaitForChild("PlayerGui")
end

local function cleanupGUI()
    print("Cleaning up GUI elements")
    
    if currentGlowTween then
        currentGlowTween:Cancel()
        currentGlowTween = nil
    end
    
    if timerConnection then
        timerConnection:Disconnect()
        timerConnection = nil
    end
    
    if not isVotingActive then
        voteLabels = {}
        voteButtons = {}
        currentVote = nil
        currentMapData = nil
        currentVoteCounts = nil
        votingStartTime = nil
    else
        voteLabels = {}
        voteButtons = {}
    end
end

local function createVotingGui()
    print("Creating voting GUI in StarterGui script")
    
    local currentPlayerGui = getPlayerGui()
    
    local existingGui = currentPlayerGui:FindFirstChild("MapVotingGui")
    if existingGui then
        existingGui:Destroy()
        print("Destroyed existing MapVotingGui")
        task.wait(0.1)
    end
    
    cleanupGUI()
    
    screenGui = Instance.new("ScreenGui")
    screenGui.Name = "MapVotingGui"
    screenGui.ResetOnSpawn = false
    screenGui.Enabled = true
    screenGui.IgnoreGuiInset = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = currentPlayerGui
    
    local uiScale = Instance.new("UIScale")
    uiScale.Parent = screenGui
    
    local function calculateUIScale()
        local camera = workspace.CurrentCamera
        local viewportSize = camera and camera.ViewportSize or Vector2.new(1920, 1080)
        local baseWidth = 1920
        local baseHeight = 1080
        local scale = math.min(viewportSize.X / baseWidth, viewportSize.Y / baseHeight)
        return math.clamp(scale, 0.5, 1.5)
    end
    
    local function updateUIScale()
        if uiScale and uiScale.Parent then
            uiScale.Scale = calculateUIScale()
        end
    end
    
    updateUIScale()
    
    if workspace.CurrentCamera then
        workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateUIScale)
    end
    
    mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, GUI_WIDTH, 0, GUI_HEIGHT)
    mainFrame.Position = UDim2.new(0.5, 0, -1, 0)
    mainFrame.AnchorPoint = Vector2.new(0.5, 0)
    mainFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
    mainFrame.BorderSizePixel = 0
    mainFrame.Visible = false
    mainFrame.Parent = screenGui
    
    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 20)
    mainCorner.Parent = mainFrame
    
    local mainGradient = Instance.new("UIGradient")
    mainGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(20, 20, 25)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(10, 10, 15)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(5, 5, 10))
    }
    mainGradient.Rotation = 135
    mainGradient.Parent = mainFrame
    
    mainStroke = Instance.new("UIStroke")
    mainStroke.Thickness = 3
    mainStroke.Color = Color3.fromRGB(80, 80, 120)
    mainStroke.Transparency = 0.3
    mainStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    mainStroke.Parent = mainFrame
    
    local titleFrame = Instance.new("Frame")
    titleFrame.Name = "TitleFrame"
    titleFrame.Size = UDim2.new(1, 0, 0.2, 0)
    titleFrame.Position = UDim2.new(0, 0, 0, 0)
    titleFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    titleFrame.BorderSizePixel = 0
    titleFrame.Parent = mainFrame
    
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 20)
    titleCorner.Parent = titleFrame
    
    local titleGradient = Instance.new("UIGradient")
    titleGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(30, 30, 35)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 20, 25))
    }
    titleGradient.Rotation = 90
    titleGradient.Parent = titleFrame
    
    titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Size = UDim2.new(0.7, -20, 1, 0)
    titleLabel.Position = UDim2.new(0, 20, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "Vote for the next map!"
    titleLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    titleLabel.TextScaled = true
    titleLabel.TextSize = 28
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = titleFrame
    
    local titleStroke = Instance.new("UIStroke")
    titleStroke.Thickness = 2
    titleStroke.Color = Color3.fromRGB(200, 200, 200)
    titleStroke.Transparency = 0.8
    titleStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
    titleStroke.Parent = titleLabel
    
    timerLabel = Instance.new("TextLabel")
    timerLabel.Name = "Timer"
    timerLabel.Size = UDim2.new(0.3, -20, 1, 0)
    timerLabel.Position = UDim2.new(0.7, 10, 0, 0)
    timerLabel.BackgroundTransparency = 1
    timerLabel.Text = tostring(VOTING_TIME)
    timerLabel.TextColor3 = Color3.fromRGB(255, 150, 150)
    timerLabel.TextScaled = true
    timerLabel.TextSize = 24
    timerLabel.Font = Enum.Font.GothamBold
    timerLabel.TextXAlignment = Enum.TextXAlignment.Right
    timerLabel.Parent = titleFrame
    
    local timerStroke = Instance.new("UIStroke")
    timerStroke.Thickness = 2
    timerStroke.Color = Color3.fromRGB(255, 150, 150)
    timerStroke.Transparency = 0.8
    timerStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
    timerStroke.Parent = timerLabel
    
    optionsContainer = Instance.new("Frame")
    optionsContainer.Name = "OptionsContainer"
    optionsContainer.Size = UDim2.new(1, -40, 0.75, -20)
    optionsContainer.Position = UDim2.new(0, 20, 0.2, 10)
    optionsContainer.BackgroundTransparency = 1
    optionsContainer.Parent = mainFrame
    
    local optionsLayout = Instance.new("UIListLayout")
    optionsLayout.FillDirection = Enum.FillDirection.Horizontal
    optionsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    optionsLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    optionsLayout.Padding = UDim.new(0, 20)
    optionsLayout.Parent = optionsContainer
    
    print("Voting GUI created successfully")
end

local function createVoteButton(mapData, index)
    if not mapData or not mapData.name or not mapData.thumbnail then
        warn("Invalid mapData for index:", index)
        mapData = {name = "Unknown Map", thumbnail = "rbxthumb://type=Asset&id=0&w=420&h=420"}
    end
    
    print("Creating vote button for:", mapData.name, "at index:", index)
    
    local buttonContainer = Instance.new("Frame")
    buttonContainer.Name = "ButtonContainer" .. index
    buttonContainer.Size = UDim2.new(0, 160, 1, 0)
    buttonContainer.BackgroundTransparency = 1
    buttonContainer.Parent = optionsContainer
    
    local button = Instance.new("TextButton")
    button.Name = "VoteButton" .. index
    button.Size = UDim2.new(1, 0, 1, 0)
    button.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    button.BorderSizePixel = 0
    button.Text = ""
    button.AutoButtonColor = false
    button.Parent = buttonContainer
    
    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 15)
    buttonCorner.Parent = button
    
    local buttonGradient = Instance.new("UIGradient")
    buttonGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(25, 25, 30)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(15, 15, 20)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 10, 15))
    }
    buttonGradient.Rotation = 135
    buttonGradient.Parent = button
    
    local buttonStroke = Instance.new("UIStroke")
    buttonStroke.Name = "ButtonStroke"
    buttonStroke.Thickness = 2
    buttonStroke.Color = Color3.fromRGB(60, 60, 80)
    buttonStroke.Transparency = 0.5
    buttonStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    buttonStroke.Parent = button
    
    local imageContainer = Instance.new("Frame")
    imageContainer.Size = UDim2.new(1, -20, 0.6, -10)
    imageContainer.Position = UDim2.new(0, 10, 0, 10)
    imageContainer.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
    imageContainer.BorderSizePixel = 0
    imageContainer.Parent = button
    
    local imageCorner = Instance.new("UICorner")
    imageCorner.CornerRadius = UDim.new(0, 10)
    imageCorner.Parent = imageContainer
    
    local imageStroke = Instance.new("UIStroke")
    imageStroke.Thickness = 1
    imageStroke.Color = Color3.fromRGB(30, 30, 40)
    imageStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    imageStroke.Parent = imageContainer
    
    local imageLabel = Instance.new("ImageLabel")
    imageLabel.Size = UDim2.new(1, -4, 1, -4)
    imageLabel.Position = UDim2.new(0, 2, 0, 2)
    imageLabel.BackgroundTransparency = 1
    imageLabel.Image = mapData.thumbnail or ""
    imageLabel.ScaleType = Enum.ScaleType.Crop
    imageLabel.Parent = imageContainer
    
    local imageCorner2 = Instance.new("UICorner")
    imageCorner2.CornerRadius = UDim.new(0, 8)
    imageCorner2.Parent = imageLabel
    
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, -20, 0.2, 0)
    nameLabel.Position = UDim2.new(0, 10, 0.6, 5)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = mapData.name or "Unknown"
    nameLabel.TextColor3 = Color3.fromRGB(180, 180, 190)
    nameLabel.TextScaled = true
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextStrokeTransparency = 0.8
    nameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    nameLabel.Parent = button
    
    local voteContainer = Instance.new("Frame")
    voteContainer.Size = UDim2.new(1, -20, 0.15, 0)
    voteContainer.Position = UDim2.new(0, 10, 0.82, 0)
    voteContainer.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    voteContainer.BorderSizePixel = 0
    voteContainer.Parent = button
    
    local voteCorner = Instance.new("UICorner")
    voteCorner.CornerRadius = UDim.new(0, 8)
    voteCorner.Parent = voteContainer
    
    local voteGradient = Instance.new("UIGradient")
    voteGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(50, 50, 60)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(30, 30, 40))
    }
    voteGradient.Rotation = 90
    voteGradient.Parent = voteContainer
    
    local voteLabel = Instance.new("TextLabel")
    voteLabel.Name = "VoteCount"
    voteLabel.Size = UDim2.new(1, -10, 1, 0)
    voteLabel.Position = UDim2.new(0, 5, 0, 0)
    voteLabel.BackgroundTransparency = 1
    voteLabel.Text = "0 VOTES"
    voteLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    voteLabel.TextScaled = true
    voteLabel.Font = Enum.Font.GothamBold
    voteLabel.TextStrokeTransparency = 0.8
    voteLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    voteLabel.Parent = voteContainer
    
    voteLabels[index] = voteLabel
    voteButtons[index] = button
    
    local hoverTween = nil
    local clickTween = nil
    
    button.MouseEnter:Connect(function()
        if hoverTween then hoverTween:Cancel() end
        hoverTween = TweenService:Create(
            buttonStroke,
            TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {Transparency = 0, Color = Color3.fromRGB(100, 100, 120)}
        )
        hoverTween:Play()
        
        TweenService:Create(
            button,
            TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {Size = UDim2.new(1.05, 0, 1.05, 0)}
        ):Play()
    end)
    
    button.MouseLeave:Connect(function()
        if hoverTween then hoverTween:Cancel() end
        local targetColor = currentVote == index and Color3.fromRGB(80, 200, 80) or Color3.fromRGB(60, 60, 80)
        hoverTween = TweenService:Create(
            buttonStroke,
            TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {Transparency = 0.5, Color = targetColor}
        )
        hoverTween:Play()
        
        TweenService:Create(
            button,
            TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {Size = UDim2.new(1, 0, 1, 0)}
        ):Play()
    end)
    
    button.MouseButton1Click:Connect(function()
        if not isVotingActive then return end
        
        print("Vote button clicked for index:", index)
        
        if clickTween then clickTween:Cancel() end
        clickTween = TweenService:Create(
            button,
            TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {Size = UDim2.new(0.95, 0, 0.95, 0)}
        )
        clickTween:Play()
        
        clickTween.Completed:Connect(function()
            TweenService:Create(
                button,
                TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
                {Size = UDim2.new(1, 0, 1, 0)}
            ):Play()
        end)
        
        if currentVote ~= index then
            pcall(function()
                voteMapRemote:FireServer(index)
            end)
            
            currentVote = index
            print("Voted for map index:", index)
            
            for i, btn in pairs(voteButtons) do
                local stroke = btn:FindFirstChild("ButtonStroke")
                if stroke then
                    local isSelected = (i == index)
                    TweenService:Create(
                        stroke,
                        TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                        {
                            Color = isSelected and Color3.fromRGB(80, 200, 80) or Color3.fromRGB(60, 60, 80),
                            Transparency = isSelected and 0 or 0.5,
                            Thickness = isSelected and 4 or 2
                        }
                    ):Play()
                end
            end
        end
    end)
    
    return button
end

local function showVotingUI()
    print("Showing voting UI")
    
    if not mainFrame then
        warn("MainFrame is nil in showVotingUI!")
        return
    end
    
    mainFrame.Visible = true
    
    TweenService:Create(
        mainFrame,
        TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Position = UDim2.new(0.5, 0, 0, 5)}
    ):Play()
    
    if mainStroke then
        currentGlowTween = TweenService:Create(
            mainStroke,
            TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
            {Transparency = 0.1}
        )
        currentGlowTween:Play()
    end
    
    votingStartTime = tick()
    if timerConnection then
        timerConnection:Disconnect()
    end
    
    timerConnection = RunService.Heartbeat:Connect(function()
        if not votingStartTime or not timerLabel then return end
        
        local elapsed = tick() - votingStartTime
        local remaining = math.max(0, VOTING_TIME - elapsed)
        
        timerLabel.Text = string.format("%.1f", remaining)
        timerLabel.TextColor3 = remaining <= 3 and Color3.fromRGB(255, 100, 100) or Color3.fromRGB(255, 150, 150)
        
        if remaining <= 0 then
            if timerConnection then
                timerConnection:Disconnect()
                timerConnection = nil
            end
        end
    end)
end

local function hideVotingUI()
    print("Hiding voting UI")
    
    isVotingActive = false
    currentMapData = nil
    currentVoteCounts = nil
    currentVote = nil
    votingStartTime = nil
    
    if currentGlowTween then
        currentGlowTween:Cancel()
        currentGlowTween = nil
    end
    
    if timerConnection then
        timerConnection:Disconnect()
        timerConnection = nil
    end
    
    if not titleLabel or not timerLabel or not mainFrame then
        warn("GUI elements are nil in hideVotingUI!")
        return
    end
    
    titleLabel.Text = "Loading map…"
    titleLabel.TextColor3 = Color3.fromRGB(80, 200, 80)
    timerLabel.Text = ""
    
    local pulseTween = TweenService:Create(
        mainFrame,
        TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, 2, true),
        {BackgroundTransparency = 0.2}
    )
    pulseTween:Play()
    
    pulseTween.Completed:Connect(function()
        if mainFrame then
            TweenService:Create(
                mainFrame,
                TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
                {Position = UDim2.new(0.5, 0, -1, 0)}
            ):Play()
            
            task.wait(0.5)
            mainFrame.Visible = false
        end
    end)
end

local function restoreGUIState()
    if not isVotingActive or not currentMapData then return end
    
    print("Restoring GUI state after respawn")
    
    task.wait(0.5)
    
    createVotingGui()
    
    if optionsContainer then
        for _, child in ipairs(optionsContainer:GetChildren()) do
            if child:IsA("Frame") and child.Name:find("ButtonContainer") then
                child:Destroy()
            end
        end
    end
    
    voteLabels = {}
    voteButtons = {}
    
    for i, mapData in ipairs(currentMapData) do
        if i <= 3 then
            createVoteButton(mapData, i)
        end
    end
    
    if currentVoteCounts then
        for i, count in ipairs(currentVoteCounts) do
            if voteLabels[i] then
                local text = count .. (count == 1 and " VOTE" or " VOTES")
                voteLabels[i].Text = text
                if count > 0 then
                    voteLabels[i].TextColor3 = Color3.fromRGB(255, 200, 100)
                end
            end
        end
    end
    
    if currentVote then
        for i, btn in pairs(voteButtons) do
            local stroke = btn:FindFirstChild("ButtonStroke")
            if stroke and i == currentVote then
                stroke.Color = Color3.fromRGB(80, 200, 80)
                stroke.Transparency = 0
                stroke.Thickness = 4
            end
        end
    end
    
    showVotingUI()
end

local function onCharacterAdded()
    print("Character added/respawned")
    
    task.wait(0.1)
    
    if isVotingActive then
        restoreGUIState()
    end
    
    playerGui = getPlayerGui()
end

if player.Character then
    onCharacterAdded()
end
player.CharacterAdded:Connect(onCharacterAdded)

player.ChildAdded:Connect(function(child)
    if child.Name == "PlayerGui" then
        playerGui = child
        if isVotingActive then
            task.wait(0.1)
            restoreGUIState()
        end
    end
end)

startVotingRemote.OnClientEvent:Connect(function(mapDataList)
    print("=== StartVoting Event Received ===")
    
    if not mapDataList or type(mapDataList) ~= "table" then
        warn("Received invalid mapDataList:", mapDataList)
        return
    end
    
    print("Starting new voting session with", #mapDataList, "maps")
    
    playerGui = getPlayerGui()
    
    isVotingActive = true
    currentMapData = mapDataList
    currentVoteCounts = {}
    currentVote = nil
    votingStartTime = nil
    
    for i = 1, math.min(#mapDataList, 3) do
        currentVoteCounts[i] = 0
    end
    
    createVotingGui()
    
    if optionsContainer then
        for _, child in ipairs(optionsContainer:GetChildren()) do
            if child:IsA("Frame") and child.Name:find("ButtonContainer") then
                child:Destroy()
            end
        end
    end
    
    voteLabels = {}
    voteButtons = {}
    
    for i, mapData in ipairs(mapDataList) do
        if i <= 3 then
            createVoteButton(mapData, i)
        end
    end
    
    for i = 1, 3 do
        if voteLabels[i] then
            voteLabels[i].Text = "0 VOTES"
        end
    end
    
    if titleLabel then
        titleLabel.Text = "Vote for the next map!"
        titleLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    end
    
    if timerLabel then
        timerLabel.Text = tostring(VOTING_TIME)
    end
    
    task.wait(0.1)
    showVotingUI()
end)

updateVotesRemote.OnClientEvent:Connect(function(counts)
    if not counts or type(counts) ~= "table" then
        warn("Received invalid vote counts:", counts)
        return
    end
    
    print("Updating vote counts:", counts)
    
    currentVoteCounts = counts
    
    for i, count in ipairs(counts) do
        if voteLabels[i] then
            local text = count .. (count == 1 and " VOTE" or " VOTES")
            local voteContainer = voteLabels[i].Parent
            voteLabels[i].Text = text
            
            if voteContainer then
                TweenService:Create(
                    voteContainer,
                    TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
                    {Size = UDim2.new(1, -15, 0.18, 0)}
                ):Play()
                
                task.wait(0.1)
                
                TweenService:Create(
                    voteContainer,
                    TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
                    {Size = UDim2.new(1, -20, 0.15, 0)}
                ):Play()
            end
            
            if count > 0 then
                TweenService:Create(
                    voteLabels[i],
                    TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                    {TextColor3 = Color3.fromRGB(255, 200, 100)}
                ):Play()
            end
        end
    end
end)

endVotingRemote.OnClientEvent:Connect(function()
    print("=== EndVoting Event Received ===")
    hideVotingUI()
end)

Players.PlayerRemoving:Connect(function(leavingPlayer)
    if leavingPlayer == player then
        cleanupGUI()
    end
end)

game:BindToClose(function()
    cleanupGUI()
end)