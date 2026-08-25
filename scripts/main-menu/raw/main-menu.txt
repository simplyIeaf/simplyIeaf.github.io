-- made by @simplyIeaf1 on youtube

local TITLE_TEXT = "my awesome game" 
local CreditsConfig = {
    {Username = "simplyIeaf", Role = "epic scripter"},
    {Username = "builderman", Role = "builder"},
    {Username = "Roblox", Role = "the guy himself"},
}

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local PhysicsService = game:GetService("PhysicsService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")


local function calculateUIScale()
    local camera = workspace.CurrentCamera
    local viewportSize = camera.ViewportSize
    
    local baseWidth = 1920
    local baseHeight = 1080
    
    local widthScale = viewportSize.X / baseWidth
    local heightScale = viewportSize.Y / baseHeight
    
    local scale = math.min(widthScale, heightScale)
    
    scale = math.max(scale, 0.7)
    
    return scale
end


-- Fixed camera setup with proper waiting
local camera = Workspace.CurrentCamera
local menuCamPart = Workspace:WaitForChild("MenuCamera", 10) -- Wait up to 10 seconds

if menuCamPart then
    camera.CameraType = Enum.CameraType.Scriptable
    camera.CFrame = menuCamPart.CFrame
else
    warn("MenuCamera part not found in Workspace!")
end

StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat,false)

local function disablePlayerControls()
    local character = player.Character or player.CharacterAdded:Wait()
    local humanoid = character:WaitForChild("Humanoid")
    
    humanoid.PlatformStand = true
    humanoid.JumpPower = 0
    humanoid.WalkSpeed = 0
    
    game:GetService("UserInputService").ModalEnabled = true
end

local function enablePlayerControls()
    if player.Character then
        local humanoid = player.Character:FindFirstChild("Humanoid")
        if humanoid then
            humanoid.PlatformStand = false
            humanoid.JumpPower = 50
            humanoid.WalkSpeed = 16
        end
    end
    
    game:GetService("UserInputService").ModalEnabled = false
    
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, true)
end

disablePlayerControls()

local characterConnection
characterConnection = player.CharacterAdded:Connect(function()
    task.wait()
    if screenGui and screenGui.Parent then -- Only disable controls if menu is still active
        disablePlayerControls()
    end
end)


local blur = Instance.new("BlurEffect")
blur.Size = 0
blur.Parent = Lighting
TweenService:Create(blur,TweenInfo.new(1),{Size=20}):Play()


local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MainMenu"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = playerGui


local uiScale = Instance.new("UIScale")
uiScale.Scale = calculateUIScale()
uiScale.Parent = screenGui


local function updateUIScale()
    local newScale = calculateUIScale()
    TweenService:Create(uiScale, TweenInfo.new(0.3), {Scale = newScale}):Play()
end


camera:GetPropertyChangedSignal("ViewportSize"):Connect(updateUIScale)


local fadeFrame = Instance.new("Frame")
fadeFrame.Size = UDim2.new(1,0,1,0)
fadeFrame.BackgroundColor3 = Color3.new(0,0,0)
fadeFrame.BackgroundTransparency = 1
fadeFrame.ZIndex = 10
fadeFrame.Parent = screenGui

local function makeButton(text, yPosition)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0,220,0,55)
    btn.Position = UDim2.new(-0.3,0,yPosition,0) -- Start off-screen to the left
    btn.Text = text
    btn.TextSize = 22
    btn.BackgroundColor3 = Color3.fromRGB(30,30,30)
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Font = Enum.Font.GothamSemibold
    btn.AutoButtonColor = false
    
    local uicorner = Instance.new("UICorner")
    uicorner.CornerRadius = UDim.new(0,12)
    uicorner.Parent = btn
    
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn,TweenInfo.new(0.2),{BackgroundColor3=Color3.fromRGB(60,60,60)}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn,TweenInfo.new(0.2),{BackgroundColor3=Color3.fromRGB(30,30,30)}):Play()
    end)
    
    btn.Parent = screenGui
    return btn
end

-- Create buttons with their final Y positions
local playBtn = makeButton("Play", 0.4)
local settingsBtn = makeButton("Settings", 0.52)
local creditsBtn = makeButton("Credits", 0.64)

-- Animate buttons to slide in from the left with proper spacing
TweenService:Create(playBtn,TweenInfo.new(1,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Position=UDim2.new(0.05,0,0.4,0)}):Play()
task.wait(0.2)
TweenService:Create(settingsBtn,TweenInfo.new(1,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Position=UDim2.new(0.05,0,0.52,0)}):Play()
task.wait(0.2)
TweenService:Create(creditsBtn,TweenInfo.new(1,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Position=UDim2.new(0.05,0,0.64,0)}):Play()

local title
task.delay(1.4,function()
    title = Instance.new("TextLabel")
    title.Size = UDim2.new(1,0,0,80)
    title.Position = UDim2.new(0,0,-0.2,0)
    title.Text = TITLE_TEXT
    title.Font = Enum.Font.GothamBold
    title.TextSize = 48
    title.TextColor3 = Color3.new(1,1,1)
    title.TextStrokeTransparency = 0
    title.BackgroundTransparency = 1
    title.Parent = screenGui
    
    TweenService:Create(title,TweenInfo.new(1,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Position=UDim2.new(0,0,0.05,0)}):Play()
end)

local function createPopup(titleText)
    local popup = Instance.new("Frame")
    popup.Size = UDim2.new(0,450,0,350)
    popup.Position = UDim2.new(0.5,-225,0.5,-175)
    popup.BackgroundColor3 = Color3.fromRGB(25,25,25)
    popup.BackgroundTransparency = 1
    popup.Visible = false
    popup.Parent = screenGui
    
    local uicorner = Instance.new("UICorner")
    uicorner.CornerRadius = UDim.new(0,12)
    uicorner.Parent = popup
    
    local titleLbl = Instance.new("TextLabel")
    titleLbl.Size = UDim2.new(1,-40,0,50)
    titleLbl.Position = UDim2.new(0,20,0,0)
    titleLbl.Text = titleText
    titleLbl.Font = Enum.Font.GothamBold
    titleLbl.TextSize = 24
    titleLbl.TextColor3 = Color3.new(1,1,1)
    titleLbl.BackgroundTransparency = 1
    titleLbl.TextTransparency = 1
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.Parent = popup
    
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0,40,0,40)
    closeBtn.Position = UDim2.new(1,-45,0,5)
    closeBtn.Text = "X"
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 20
    closeBtn.TextColor3 = Color3.new(1,1,1)
    closeBtn.TextTransparency = 1
    closeBtn.BackgroundColor3 = Color3.fromRGB(50,50,50)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0,8)
    corner.Parent = closeBtn
    closeBtn.Parent = popup
    
    local function fadeTexts(frame,transparency)
        for _,desc in ipairs(frame:GetDescendants()) do
            if desc:IsA("TextLabel") or desc:IsA("TextButton") then
                TweenService:Create(desc,TweenInfo.new(0.25),{TextTransparency=transparency}):Play()
            end
        end
    end
    
    local function openPopup()
        popup.Visible = true
        TweenService:Create(popup,TweenInfo.new(0.25),{BackgroundTransparency=0}):Play()
        fadeTexts(popup,0)
    end
    
    local function closePopup()
        TweenService:Create(popup,TweenInfo.new(0.25),{BackgroundTransparency=1}):Play()
        fadeTexts(popup,1)
        task.wait(0.25)
        popup.Visible = false
    end
    
    closeBtn.MouseButton1Click:Connect(closePopup)
    return popup,openPopup,closePopup
end

local settingsPopup, openSettings, closeSettings = createPopup("Settings")
local container = Instance.new("Frame")
container.Size = UDim2.new(1,-40,1,-80)
container.Position = UDim2.new(0,20,0,60)
container.BackgroundTransparency = 1
container.Parent = settingsPopup

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0,20)
layout.FillDirection = Enum.FillDirection.Vertical
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = container

local function createSettingRow(labelText)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1,0,0,50)
    frame.BackgroundTransparency = 1
    frame.Parent = container
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.5,0,1,0)
    label.Text = labelText
    label.Font = Enum.Font.GothamSemibold
    label.TextSize = 20
    label.TextColor3 = Color3.fromRGB(230,230,230)
    label.BackgroundTransparency = 1
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame
    
    return frame
end

local function createToggleButton(parent, defaultText)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0, 120, 0, 35)
    button.Position = UDim2.new(0.6,0,0.15,0)
    button.BackgroundColor3 = Color3.fromRGB(50,50,50)
    button.TextColor3 = Color3.fromRGB(255,255,255)
    button.Font = Enum.Font.Gotham
    button.TextSize = 16
    button.Text = defaultText
    button.AutoButtonColor = false
    
    local uicorner = Instance.new("UICorner")
    uicorner.CornerRadius = UDim.new(0, 8)
    uicorner.Parent = button
    
    button.MouseEnter:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3=Color3.fromRGB(80,80,80)}):Play()
    end)
    button.MouseLeave:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3=Color3.fromRGB(50,50,50)}):Play()
    end)
    
    button.Parent = parent
    return button
end

local timeRow = createSettingRow("Time")
local timeSwitch = createToggleButton(timeRow,"Day")
local timeState = "Day"
timeSwitch.MouseButton1Click:Connect(function()
    if timeState == "Day" then
        timeState = "Night"
        timeSwitch.Text = "Night"
        TweenService:Create(Lighting,TweenInfo.new(1.5),{ClockTime=20}):Play()
    else
        timeState = "Day"
        timeSwitch.Text = "Day"
        TweenService:Create(Lighting,TweenInfo.new(1.5),{ClockTime=14}):Play()
    end
end)

local graphicsRow = createSettingRow("Graphics")
local graphicsSwitch = createToggleButton(graphicsRow,"Medium")
local graphicsOptions = {"Low","Medium","High"}
local graphicsIndex = 2
graphicsSwitch.MouseButton1Click:Connect(function()
    graphicsIndex = graphicsIndex % #graphicsOptions + 1
    graphicsSwitch.Text = graphicsOptions[graphicsIndex]
    
    if graphicsOptions[graphicsIndex]=="Low" then
        Lighting.GlobalShadows=false
        Lighting.OutdoorAmbient = Color3.fromRGB(128,128,128)
    elseif graphicsOptions[graphicsIndex]=="Medium" then
        Lighting.GlobalShadows=true
        Lighting.OutdoorAmbient = Color3.fromRGB(160,160,160)
    else
        Lighting.GlobalShadows=true
        Lighting.OutdoorAmbient = Color3.fromRGB(200,200,200)
    end
end)

local hideRow = createSettingRow("Hide Players")
local hideSwitch = createToggleButton(hideRow,"Off")
local hideState = false
hideSwitch.MouseButton1Click:Connect(function()
    hideState = not hideState
    hideSwitch.Text = hideState and "On" or "Off"
    for _,plr in ipairs(Players:GetPlayers()) do
        if plr ~= player and plr.Character then
            for _,part in ipairs(plr.Character:GetChildren()) do
                if part:IsA("BasePart") then
                    part.Transparency = hideState and 1 or 0
                end
            end
        end
    end
end)

-- FOV Slider (Fixed for PC and Mobile)
local fovRow = createSettingRow("FOV")

-- Create FOV slider container
local sliderContainer = Instance.new("Frame")
sliderContainer.Size = UDim2.new(0, 180, 0, 35)
sliderContainer.Position = UDim2.new(0.55, 0, 0.15, 0)
sliderContainer.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
sliderContainer.BorderSizePixel = 0
sliderContainer.Parent = fovRow

local sliderCorner = Instance.new("UICorner")
sliderCorner.CornerRadius = UDim.new(0, 8)
sliderCorner.Parent = sliderContainer

-- Slider track (filled portion)
local sliderTrack = Instance.new("Frame")
sliderTrack.Size = UDim2.new(0, 0, 1, 0)
sliderTrack.Position = UDim2.new(0, 0, 0, 0)
sliderTrack.BackgroundColor3 = Color3.fromRGB(80, 120, 255)
sliderTrack.BorderSizePixel = 0
sliderTrack.Parent = sliderContainer

local trackCorner = Instance.new("UICorner")
trackCorner.CornerRadius = UDim.new(0, 8)
trackCorner.Parent = sliderTrack

-- Slider handle
local sliderHandle = Instance.new("Frame")
sliderHandle.Size = UDim2.new(0, 20, 0, 20)
sliderHandle.Position = UDim2.new(0, -10, 0.5, -10)
sliderHandle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
sliderHandle.BorderSizePixel = 0
sliderHandle.Parent = sliderContainer

local handleCorner = Instance.new("UICorner")
handleCorner.CornerRadius = UDim.new(1, 0)
handleCorner.Parent = sliderHandle

-- FOV slider functionality (Fixed for PC and Mobile)
local minFOV = 70 -- Default FOV
local maxFOV = 120
local currentFOV = minFOV
local isDragging = false

local function updateFOVSlider(fov)
    currentFOV = math.clamp(fov, minFOV, maxFOV)
    camera.FieldOfView = currentFOV
    
    -- Update slider visual
    local percentage = (currentFOV - minFOV) / (maxFOV - minFOV)
    sliderTrack.Size = UDim2.new(percentage, 0, 1, 0)
    sliderHandle.Position = UDim2.new(percentage, -10, 0.5, -10)
end

-- Initialize slider
updateFOVSlider(minFOV)

local function getSliderPercentage(inputPosition)
    local sliderPos = sliderContainer.AbsolutePosition.X
    local sliderWidth = sliderContainer.AbsoluteSize.X
    local inputX = inputPosition.X
    
    local percentage = math.clamp((inputX - sliderPos) / sliderWidth, 0, 1)
    return percentage
end

-- Handle both mouse and touch input for PC and mobile
sliderContainer.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isDragging = true
        
        -- Set initial position
        local percentage = getSliderPercentage(input.Position)
        local newFOV = minFOV + (maxFOV - minFOV) * percentage
        updateFOVSlider(newFOV)
    end
end)

-- Global input handling for dragging
UserInputService.InputChanged:Connect(function(input)
    if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local percentage = getSliderPercentage(input.Position)
        local newFOV = minFOV + (maxFOV - minFOV) * percentage
        updateFOVSlider(newFOV)
    end
end)

-- Stop dragging
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isDragging = false
    end
end)

local creditsPopup, openCredits, closeCredits = createPopup("Credits")
local creditsContainer = Instance.new("Frame")
creditsContainer.Size = UDim2.new(1,-40,1,-80)
creditsContainer.Position = UDim2.new(0,20,0,60)
creditsContainer.BackgroundTransparency = 1
creditsContainer.Parent = creditsPopup

local creditsLayout = Instance.new("UIListLayout")
creditsLayout.Padding = UDim.new(0,15)
creditsLayout.FillDirection = Enum.FillDirection.Vertical
creditsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
creditsLayout.SortOrder = Enum.SortOrder.LayoutOrder
creditsLayout.Parent = creditsContainer

for i=1,math.min(#CreditsConfig,3) do
    local credit = CreditsConfig[i]
    local frame = Instance.new("Frame")
    frame.Size=UDim2.new(1,0,0,60)
    frame.BackgroundTransparency=1
    frame.Parent = creditsContainer
    
    local thumb = Instance.new("ImageLabel")
    thumb.Size=UDim2.new(0,50,0,50)
    thumb.Position = UDim2.new(0,0,0,0)
    thumb.BackgroundTransparency=1
    thumb.Parent = frame
    
    local success,userId = pcall(function() return Players:GetUserIdFromNameAsync(credit.Username) end)
    if success and userId then
        thumb.Image = Players:GetUserThumbnailAsync(userId,Enum.ThumbnailType.HeadShot,Enum.ThumbnailSize.Size100x100)
    end
    
    local name = Instance.new("TextLabel")
    name.Size=UDim2.new(0.5,0,1,0)
    name.Position=UDim2.new(0,60,0,0)
    name.Text=credit.Username
    name.Font=Enum.Font.GothamBold
    name.TextSize=18
    name.TextColor3=Color3.fromRGB(230,230,230)
    name.BackgroundTransparency=1
    name.TextXAlignment=Enum.TextXAlignment.Left
    name.Parent=frame
    
    local roleLbl = Instance.new("TextLabel")
    roleLbl.Size=UDim2.new(0.4,0,1,0)
    roleLbl.Position=UDim2.new(0.6,0,0,0)
    roleLbl.Text=credit.Role
    roleLbl.Font=Enum.Font.Gotham
    roleLbl.TextSize=16
    roleLbl.TextColor3=Color3.fromRGB(200,200,200)
    roleLbl.BackgroundTransparency=1
    roleLbl.TextXAlignment=Enum.TextXAlignment.Right
    roleLbl.Parent=frame
end

settingsBtn.MouseButton1Click:Connect(function()
    if settingsPopup.Visible then 
        closeSettings() 
    else 
        if creditsPopup.Visible then 
            closeCredits() 
        end 
        openSettings() 
    end
end)

creditsBtn.MouseButton1Click:Connect(function()
    if creditsPopup.Visible then 
        closeCredits() 
    else 
        if settingsPopup.Visible then 
            closeSettings() 
        end 
        openCredits() 
    end
end)

playBtn.MouseButton1Click:Connect(function()
    enablePlayerControls()
    
    -- Disconnect the character connection to prevent controls from being disabled on respawn
    if characterConnection then
        characterConnection:Disconnect()
    end
    
    TweenService:Create(fadeFrame,TweenInfo.new(1),{BackgroundTransparency=0}):Play()
    TweenService:Create(blur,TweenInfo.new(1),{Size=0}):Play()
    task.wait(1)
    
    for _,btn in ipairs({playBtn,settingsBtn,creditsBtn}) do
        TweenService:Create(btn,TweenInfo.new(0.5),{BackgroundTransparency=1,TextTransparency=1}):Play()
    end
    if title then
        TweenService:Create(title,TweenInfo.new(0.5),{TextTransparency=1}):Play()
    end
    
    closeSettings()
    closeCredits()
    task.wait(0.5)
    
    camera.CameraType = Enum.CameraType.Custom
    camera.CameraSubject = player.Character:WaitForChild("Humanoid")
    
    TweenService:Create(fadeFrame,TweenInfo.new(1),{BackgroundTransparency=1}):Play()
    task.wait(1)
    screenGui:Destroy()
end)