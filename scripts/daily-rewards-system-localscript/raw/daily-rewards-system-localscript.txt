local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
 
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local playerGui = player:WaitForChild("PlayerGui")
 
local rewardFunction = ReplicatedStorage:WaitForChild("DailyRewardFunction")
 
local serverData = rewardFunction:InvokeServer("GetInfo")
local DAILY_REWARDS = serverData.rewardsTable
local currentStreakDay = serverData.streak
local nextClaimTimestamp = serverData.nextClaimTime
 
local guiOpen = false
local alive = true
 
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DailyRewardsGui"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui
 
humanoid.Died:Connect(function()
    alive = false
    if screenGui then
        screenGui:Destroy()
    end
end)
 
local mainContainer = Instance.new("Frame")
mainContainer.Name = "MainContainer"
mainContainer.AnchorPoint = Vector2.new(0.5, 0.5)
mainContainer.Position = UDim2.new(0.5, 0, 0.5, 0)
mainContainer.Size = UDim2.new(0, 0, 0, 0)
mainContainer.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
mainContainer.BorderSizePixel = 0
mainContainer.Visible = false
mainContainer.ClipsDescendants = true
mainContainer.Parent = screenGui
 
local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0.025, 0)
mainCorner.Parent = mainContainer
 
local topBar = Instance.new("Frame")
topBar.Name = "TopBar"
topBar.Size = UDim2.new(1, 0, 0.12, 0)
topBar.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
topBar.BorderSizePixel = 0
topBar.Parent = mainContainer
 
local topBarCorner = Instance.new("UICorner")
topBarCorner.CornerRadius = UDim.new(0.025, 0)
topBarCorner.Parent = topBar
 
local topBarCover = Instance.new("Frame")
topBarCover.Size = UDim2.new(1, 0, 0.3, 0)
topBarCover.Position = UDim2.new(0, 0, 0.7, 0)
topBarCover.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
topBarCover.BorderSizePixel = 0
topBarCover.Parent = topBar
 
local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(0.6, 0, 0.8, 0)
title.Position = UDim2.new(0.2, 0, 0.1, 0)
title.BackgroundTransparency = 1
title.Text = "Daily Rewards"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextScaled = true
title.Font = Enum.Font.GothamBold
title.Parent = topBar
 
local closeButton = Instance.new("TextButton")
closeButton.Name = "CloseButton"
closeButton.AnchorPoint = Vector2.new(1, 0.5)
closeButton.Size = UDim2.new(0.05, 0, 0.7, 0)
closeButton.Position = UDim2.new(0.98, 0, 0.5, 0)
closeButton.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
closeButton.Text = "X"
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.TextScaled = true
closeButton.Font = Enum.Font.GothamBold
closeButton.Parent = topBar
 
local closeAspect = Instance.new("UIAspectRatioConstraint")
closeAspect.AspectRatio = 1
closeAspect.Parent = closeButton
 
local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(1, 0)
closeCorner.Parent = closeButton
 
local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Name = "ScrollFrame"
scrollFrame.Size = UDim2.new(0.96, 0, 0.82, 0)
scrollFrame.Position = UDim2.new(0.02, 0, 0.15, 0)
scrollFrame.BackgroundTransparency = 1
scrollFrame.BorderSizePixel = 0
scrollFrame.ScrollBarThickness = 6
scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(60, 60, 60)
scrollFrame.Parent = mainContainer
 
local scrollLayout = Instance.new("UIListLayout")
scrollLayout.FillDirection = Enum.FillDirection.Horizontal
scrollLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
scrollLayout.Padding = UDim.new(0.015, 0)
scrollLayout.Parent = scrollFrame
 
local scrollPadding = Instance.new("UIPadding")
scrollPadding.PaddingTop = UDim.new(0.02, 0)
scrollPadding.PaddingBottom = UDim.new(0.02, 0)
scrollPadding.Parent = scrollFrame
 
local function createRewardCard(data)
    local card = Instance.new("Frame")
    card.Name = "RewardCard" .. data.day
    card.Size = UDim2.new(0, 160, 0.96, 0)
    card.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    card.BorderSizePixel = 0
    
    local cardCorner = Instance.new("UICorner")
    cardCorner.CornerRadius = UDim.new(0.06, 0)
    cardCorner.Parent = card
    
    local dayLabel = Instance.new("TextLabel")
    dayLabel.Size = UDim2.new(1, 0, 0.15, 0)
    dayLabel.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    dayLabel.BorderSizePixel = 0
    dayLabel.Text = "Day " .. data.day
    dayLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    dayLabel.TextScaled = true
    dayLabel.Font = Enum.Font.GothamBold
    dayLabel.Parent = card
    
    local dayCorner = Instance.new("UICorner")
    dayCorner.CornerRadius = UDim.new(0.06, 0)
    dayCorner.Parent = dayLabel
    
    local dayCover = Instance.new("Frame")
    dayCover.Size = UDim2.new(1, 0, 0.3, 0)
    dayCover.Position = UDim2.new(0, 0, 0.7, 0)
    dayCover.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    dayCover.BorderSizePixel = 0
    dayCover.Parent = dayLabel
    
    local iconImage = Instance.new("ImageLabel")
    iconImage.AnchorPoint = Vector2.new(0.5, 0)
    iconImage.Size = UDim2.new(0.4, 0, 0.4, 0)
    iconImage.Position = UDim2.new(0.5, 0, 0.2, 0)
    iconImage.BackgroundTransparency = 1
    iconImage.ScaleType = Enum.ScaleType.Fit
    iconImage.Parent = card
    
    if data.rewardType == "leaderstat" then
        iconImage.Image = "rbxthumb://type=Asset&id=82777739698036&w=150&h=150"
    elseif data.rewardType == "tool" then
        iconImage.Image = "rbxthumb://type=Asset&id=14280889417&w=150&h=150"
    end
    
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(0.9, 0, 0.12, 0)
    nameLabel.Position = UDim2.new(0.05, 0, 0.55, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = data.rewardName
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.TextScaled = true
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.Parent = card
    
    local timerLabel = Instance.new("TextLabel")
    timerLabel.Name = "TimerLabel"
    timerLabel.Size = UDim2.new(1, 0, 0.08, 0)
    timerLabel.Position = UDim2.new(0, 0, 0.68, 0)
    timerLabel.BackgroundTransparency = 1
    timerLabel.Text = ""
    timerLabel.TextColor3 = Color3.fromRGB(80, 200, 120)
    timerLabel.TextScaled = true
    timerLabel.Font = Enum.Font.GothamBold
    timerLabel.Visible = false
    timerLabel.Parent = card
    
    local claimButton = Instance.new("TextButton")
    claimButton.Name = "ClaimButton"
    claimButton.Size = UDim2.new(0.85, 0, 0.16, 0)
    claimButton.Position = UDim2.new(0.075, 0, 0.8, 0)
    claimButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    claimButton.Text = "Locked"
    claimButton.TextColor3 = Color3.fromRGB(120, 120, 120)
    claimButton.TextScaled = true
    claimButton.Font = Enum.Font.GothamBold
    claimButton.Parent = card
    
    local claimCorner = Instance.new("UICorner")
    claimCorner.CornerRadius = UDim.new(0.2, 0)
    claimCorner.Parent = claimButton
    
    local function updateStatus()
        if data.day < currentStreakDay then
            claimButton.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
            claimButton.Text = "Claimed"
            claimButton.TextColor3 = Color3.fromRGB(100, 100, 100)
            timerLabel.Visible = false
            card.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
            claimButton.AutoButtonColor = false
        elseif data.day == currentStreakDay then
            card.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
            if os.time() >= nextClaimTimestamp then
                claimButton.BackgroundColor3 = Color3.fromRGB(80, 200, 120)
                claimButton.Text = "CLAIM"
                claimButton.TextColor3 = Color3.fromRGB(255, 255, 255)
                timerLabel.Visible = false
                claimButton.AutoButtonColor = true
            else
                claimButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
                claimButton.Text = "Wait"
                claimButton.TextColor3 = Color3.fromRGB(200, 200, 200)
                timerLabel.Visible = true
                claimButton.AutoButtonColor = false
            end
        else
            claimButton.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
            claimButton.Text = "Locked"
            claimButton.TextColor3 = Color3.fromRGB(80, 80, 80)
            timerLabel.Visible = false
            card.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
            claimButton.AutoButtonColor = false
        end
    end
    
    updateStatus()
    
    claimButton.MouseButton1Click:Connect(function()
        if data.day == currentStreakDay and os.time() >= nextClaimTimestamp then
            claimButton.Text = "Claiming..."
            
            local result = rewardFunction:InvokeServer("Claim")
            if result.success then
                local newData = rewardFunction:InvokeServer("GetInfo")
                currentStreakDay = newData.streak
                nextClaimTimestamp = newData.nextClaimTime
                
                for _, c in pairs(scrollFrame:GetChildren()) do
                    if c:IsA("Frame") then c:Destroy() end
                end
                for _, rData in ipairs(DAILY_REWARDS) do
                    local newCard = createRewardCard(rData)
                    newCard.Parent = scrollFrame
                end
            else
                updateStatus()
            end
        end
    end)
    
    return card
end
 
for _, rewardData in ipairs(DAILY_REWARDS) do
    local card = createRewardCard(rewardData)
    card.Parent = scrollFrame
end
 
scrollFrame.CanvasSize = UDim2.new(0, scrollLayout.AbsoluteContentSize.X + 20, 0, 0)
scrollLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    scrollFrame.CanvasSize = UDim2.new(0, scrollLayout.AbsoluteContentSize.X + 20, 0, 0)
end)
 
local toggleButton = Instance.new("TextButton")
toggleButton.Name = "ToggleButton"
toggleButton.Size = UDim2.new(0.055, 0, 0.1, 0)
toggleButton.Position = UDim2.new(0.93, 0, 0.88, 0)
toggleButton.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
toggleButton.Text = "🎁"
toggleButton.TextColor3 = Color3.new(1,1,1)
toggleButton.TextScaled = true
toggleButton.BorderSizePixel = 0
toggleButton.Parent = screenGui
 
local toggleCorner = Instance.new("UICorner")
toggleCorner.CornerRadius = UDim.new(1, 0)
toggleCorner.Parent = toggleButton
 
local function openGui()
    if guiOpen then return end
    guiOpen = true
    mainContainer.Visible = true
    TweenService:Create(mainContainer, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), 
    {Size = UDim2.new(0.8, 0, 0.6, 0)}):Play()
end
 
local function closeGui()
    if not guiOpen then return end
    guiOpen = false
    local tween = TweenService:Create(mainContainer, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), 
    {Size = UDim2.new(0, 0, 0, 0)})
    tween:Play()
    tween.Completed:Wait()
    mainContainer.Visible = false
end
 
toggleButton.MouseButton1Click:Connect(function()
    if guiOpen then closeGui() else openGui() end
end)
closeButton.MouseButton1Click:Connect(closeGui)
 
task.spawn(function()
    while alive do
        task.wait(1)
        if currentStreakDay then
            local timeLeft = nextClaimTimestamp - os.time()
            
            if timeLeft > 0 then
                local hours = math.floor(timeLeft / 3600)
                local mins = math.floor((timeLeft % 3600) / 60)
                local secs = timeLeft % 60
                local timeString = string.format("%02d:%02d:%02d", hours, mins, secs)
                
                local currentCard = scrollFrame:FindFirstChild("RewardCard"..currentStreakDay)
                if currentCard then
                    local timer = currentCard:FindFirstChild("TimerLabel")
                    local btn = currentCard:FindFirstChild("ClaimButton")
                    if timer then 
                        timer.Text = timeString 
                        timer.Visible = true
                    end
                    if btn then
                        btn.Text = "Wait"
                        btn.BackgroundColor3 = Color3.fromRGB(50,50,50)
                    end
                end
            else
                local currentCard = scrollFrame:FindFirstChild("RewardCard"..currentStreakDay)
                if currentCard then
                    local timer = currentCard:FindFirstChild("TimerLabel")
                    local btn = currentCard:FindFirstChild("ClaimButton")
                    if timer then timer.Visible = false end
                    if btn and btn.Text ~= "CLAIM" then
                        btn.Text = "CLAIM"
                        btn.BackgroundColor3 = Color3.fromRGB(80, 200, 120)
                    end
                end
            end
        end
    end
end)
 
task.wait(1)
openGui()