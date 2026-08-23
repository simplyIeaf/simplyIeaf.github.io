local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local camera = workspace.CurrentCamera

local connections = {}
local screenGui
local settingsFrame
local humanoidConnection
local lastSettingsToggle = 0
local settingsState = {
fieldOfView = camera.FieldOfView,
cameraSensitivity = 1,
timeIsDay = Lighting.ClockTime > 6 and Lighting.ClockTime < 18,
musicVolume = 0.5,
musicId = "",
musicPlaying = false,
hideGuis = false,
hidePlayers = false,
skyboxIds = ""
}

local studTextureId = "rbxthumb://type=Asset&id=14905298664&w=150&h=150"
local gearIconId = "7059346373"

local localMusicPlayer = Instance.new("Sound")
localMusicPlayer.Name = "CustomSettingsMusic"
localMusicPlayer.Looped = true
localMusicPlayer.Parent = SoundService

local originalSky = Lighting:FindFirstChildWhichIsA("Sky")
local originalSkyClone = originalSky and originalSky:Clone() or nil

local hiddenGuiStates = {}
local hiddenPlayerParts = {}
local playerConnections = {}

local cameraInputModule
local originalCameraGetRotation

local function createSquareButton(parent, iconId)
    local button = Instance.new("ImageButton")
    button.Size = UDim2.new(0, 96, 0, 96)
    button.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    button.ImageColor3 = Color3.fromRGB(60, 60, 60)
    button.Image = studTextureId
    button.ScaleType = Enum.ScaleType.Tile
    button.TileSize = UDim2.new(0, 48, 0, 48)
    button.Parent = parent
    
    local buttonAspect = Instance.new("UIAspectRatioConstraint")
    buttonAspect.AspectRatio = 1
    buttonAspect.Parent = button
    
    local uiCorner = Instance.new("UICorner")
    uiCorner.CornerRadius = UDim.new(0.2, 0)
    uiCorner.Parent = button
    
    local buttonStroke = Instance.new("UIStroke")
    buttonStroke.Thickness = 4
    buttonStroke.Color = Color3.new(0, 0, 0)
    buttonStroke.Parent = button
    
    local icon = Instance.new("ImageLabel")
    icon.AnchorPoint = Vector2.new(0.5, 0.5)
    icon.Position = UDim2.new(0.5, 0, 0.5, 0)
    icon.Size = UDim2.new(0.65, 0, 0.65, 0)
    icon.BackgroundTransparency = 1
    icon.Image = "rbxthumb://type=Asset&id=" .. iconId .. "&w=150&h=150"
    icon.Parent = button
    
    return button
end

local function getSkyboxValues()
    local values = {}
    
    for value in string.gmatch(settingsState.skyboxIds, "[^,%s]+") do
        table.insert(values, value)
    end
    
    return values
end

local function restoreOriginalSkybox()
    local currentSky = Lighting:FindFirstChildWhichIsA("Sky")
    
    if currentSky then
        currentSky:Destroy()
    end
    
    if originalSkyClone then
        originalSky = originalSkyClone:Clone()
        originalSky.Parent = Lighting
    end
end

local function applySkybox()
    local values = getSkyboxValues()
    
    if #values ~= 6 then
        restoreOriginalSkybox()
        return
    end
    
    local sky = Lighting:FindFirstChildWhichIsA("Sky")
    
    if not sky then
        sky = Instance.new("Sky")
        sky.Parent = Lighting
    end
    
    local properties = {
    "SkyboxBk",
    "SkyboxDn",
    "SkyboxFt",
    "SkyboxLf",
    "SkyboxRt",
    "SkyboxUp"
    }
    
    for index, property in ipairs(properties) do
        local id = values[index]
        
        if not string.find(id, "rbxassetid://", 1, true) then
            id = "rbxassetid://" .. id
        end
        
        sky[property] = id
    end
end

local function setCharacterHidden(character, hidden)
    if not character then
        return
    end
    
    if hidden then
        for _, obj in ipairs(character:GetDescendants()) do
            if obj:IsA("BasePart") then
                if hiddenPlayerParts[obj] == nil then
                    hiddenPlayerParts[obj] = obj.LocalTransparencyModifier
                end
                
                obj.LocalTransparencyModifier = 1
            elseif obj:IsA("Decal") or obj:IsA("Texture") then
                if hiddenPlayerParts[obj] == nil then
                    hiddenPlayerParts[obj] = obj.Transparency
                end
                
                obj.Transparency = 1
            end
        end
    else
        for _, obj in ipairs(character:GetDescendants()) do
            local original = hiddenPlayerParts[obj]
            
            if original ~= nil then
                if obj:IsA("BasePart") then
                    obj.LocalTransparencyModifier = original
                elseif obj:IsA("Decal") or obj:IsA("Texture") then
                    obj.Transparency = original
                end
                
                hiddenPlayerParts[obj] = nil
            end
        end
    end
end

local function setAllPlayersHidden(hidden)
    for _, otherPlayer in ipairs(Players:GetPlayers()) do
        if otherPlayer ~= player and otherPlayer.Character then
            setCharacterHidden(otherPlayer.Character, hidden)
        end
    end
end

local function watchPlayer(otherPlayer)
    if otherPlayer == player or playerConnections[otherPlayer] then
        return
    end
    
    local characterConnection
    
    characterConnection = otherPlayer.CharacterAdded:Connect(function(character)
        task.wait()
        
        if settingsState.hidePlayers then
            setCharacterHidden(character, true)
        end
        
        character.DescendantAdded:Connect(function(obj)
            if settingsState.hidePlayers then
                if obj:IsA("BasePart") then
                    if hiddenPlayerParts[obj] == nil then
                        hiddenPlayerParts[obj] = obj.LocalTransparencyModifier
                    end
                    
                    obj.LocalTransparencyModifier = 1
                elseif obj:IsA("Decal") or obj:IsA("Texture") then
                    if hiddenPlayerParts[obj] == nil then
                        hiddenPlayerParts[obj] = obj.Transparency
                    end
                    
                    obj.Transparency = 1
                end
            end
        end)
    end)
    
    playerConnections[otherPlayer] = characterConnection
    
    if otherPlayer.Character then
        if settingsState.hidePlayers then
            setCharacterHidden(otherPlayer.Character, true)
        end
    end
end

local function unwatchPlayer(otherPlayer)
    local connection = playerConnections[otherPlayer]
    
    if connection then
        connection:Disconnect()
        playerConnections[otherPlayer] = nil
    end
    
    if otherPlayer.Character then
        setCharacterHidden(otherPlayer.Character, false)
    end
end

local function applyGuiVisibility()
    for gui, originalEnabled in pairs(hiddenGuiStates) do
        if gui and gui.Parent then
            if settingsState.hideGuis then
                gui.Enabled = false
            else
                gui.Enabled = originalEnabled
            end
        else
            hiddenGuiStates[gui] = nil
        end
    end
    
    for _, gui in ipairs(playerGui:GetChildren()) do
        if gui:IsA("ScreenGui") and gui ~= screenGui then
            if hiddenGuiStates[gui] == nil then
                hiddenGuiStates[gui] = gui.Enabled
            end
            
            gui.Enabled = settingsState.hideGuis and false or hiddenGuiStates[gui]
        end
    end
end

local function applyTimeOfDay()
    Lighting.ClockTime = settingsState.timeIsDay and 14 or 2
end

local function applyCameraSensitivity()
    UserInputService.MouseDeltaSensitivity = 1
    
    if cameraInputModule and originalCameraGetRotation then
        cameraInputModule.getRotation = function(...)
            return originalCameraGetRotation(...) * settingsState.cameraSensitivity
        end
    end
end

local function setupCameraSensitivity()
    task.spawn(function()
        local playerScripts = player:WaitForChild("PlayerScripts")
        local playerModule = playerScripts:WaitForChild("PlayerModule")
        local cameraModule = playerModule:WaitForChild("CameraModule")
        local cameraInput = cameraModule:WaitForChild("CameraInput")
        
        local ok, module = pcall(require, cameraInput)
        
        if ok and module and type(module.getRotation) == "function" then
            cameraInputModule = module
            originalCameraGetRotation = module.getRotation
            applyCameraSensitivity()
        end
    end)
end

local function applyAll()
    camera.FieldOfView = settingsState.fieldOfView
    
    applyCameraSensitivity()
    applyTimeOfDay()
    applySkybox()
    applyGuiVisibility()
    
    setAllPlayersHidden(settingsState.hidePlayers)
    
    localMusicPlayer.Volume = settingsState.musicVolume
    
    if settingsState.musicPlaying and settingsState.musicId ~= "" then
        localMusicPlayer.SoundId = "rbxassetid://" .. settingsState.musicId
        
        if not localMusicPlayer.IsPlaying then
            localMusicPlayer:Play()
        end
    elseif not settingsState.musicPlaying and localMusicPlayer.IsPlaying then
        localMusicPlayer:Stop()
    end
end

local function buildSettingsUI(parent)
    local main = Instance.new("Frame")
    main.Name = "SettingsFrame"
    main.Size = UDim2.new(0, 500, 0, 550)
    main.AnchorPoint = Vector2.new(0.5, 0.5)
    main.Position = UDim2.new(0.5, 0, 0.5, 0)
    main.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    main.Visible = false
    main.ClipsDescendants = true
    main.Parent = parent
    
    local mainStroke = Instance.new("UIStroke")
    mainStroke.Thickness = 4
    mainStroke.Parent = main
    
    local bgStuds = Instance.new("ImageLabel")
    bgStuds.Size = UDim2.new(1, 0, 1, 0)
    bgStuds.BackgroundTransparency = 1
    bgStuds.Image = studTextureId
    bgStuds.ImageColor3 = Color3.fromRGB(40, 40, 40)
    bgStuds.ImageTransparency = 0.5
    bgStuds.ScaleType = Enum.ScaleType.Tile
    bgStuds.TileSize = UDim2.new(0, 50, 0, 50)
    bgStuds.Parent = main
    
    local topBar = Instance.new("Frame")
    topBar.Size = UDim2.new(1, 0, 0, 50)
    topBar.BackgroundColor3 = Color3.fromRGB(35, 150, 55)
    topBar.BorderSizePixel = 0
    topBar.ZIndex = 10
    topBar.Parent = main
    
    local topStuds = Instance.new("ImageLabel")
    topStuds.Size = UDim2.new(1, 0, 1, 0)
    topStuds.BackgroundTransparency = 1
    topStuds.Image = studTextureId
    topStuds.ImageColor3 = Color3.fromRGB(25, 90, 35)
    topStuds.ImageTransparency = 0.35
    topStuds.ScaleType = Enum.ScaleType.Tile
    topStuds.TileSize = UDim2.new(0, 50, 0, 50)
    topStuds.ZIndex = 11
    topStuds.Parent = topBar
    
    local topStroke = Instance.new("UIStroke")
    topStroke.Thickness = 4
    topStroke.Parent = topBar
    
    local titleText = Instance.new("TextLabel")
    titleText.Size = UDim2.new(1, -50, 1, 0)
    titleText.BackgroundTransparency = 1
    titleText.Text = "Settings"
    titleText.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleText.Font = Enum.Font.FredokaOne
    titleText.TextScaled = true
    titleText.ZIndex = 12
    titleText.Parent = topBar
    
    local titleConstraint = Instance.new("UITextSizeConstraint")
    titleConstraint.MaxTextSize = 28
    titleConstraint.MinTextSize = 8
    titleConstraint.Parent = titleText
    
    local titlePadding = Instance.new("UIPadding")
    titlePadding.PaddingTop = UDim.new(0, 8)
    titlePadding.PaddingBottom = UDim.new(0, 8)
    titlePadding.Parent = titleText
    
    local titleStroke = Instance.new("UIStroke")
    titleStroke.Thickness = 3
    titleStroke.Parent = titleText
    
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 50, 1, 0)
    closeBtn.Position = UDim2.new(1, -50, 0, 0)
    closeBtn.BackgroundColor3 = Color3.fromRGB(210, 25, 25)
    closeBtn.BorderSizePixel = 0
    closeBtn.Text = "X"
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.Font = Enum.Font.FredokaOne
    closeBtn.TextSize = 24
    closeBtn.ZIndex = 13
    closeBtn.Parent = topBar
    
    local closeStroke = Instance.new("UIStroke")
    closeStroke.Thickness = 4
    closeStroke.Color = Color3.new(0, 0, 0)
    closeStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    closeStroke.Parent = closeBtn
    
    local closeTxtStroke = Instance.new("UIStroke")
    closeTxtStroke.Thickness = 3
    closeTxtStroke.Color = Color3.new(0, 0, 0)
    closeTxtStroke.Parent = closeBtn
    
    table.insert(
    connections,
    closeBtn.Activated:Connect(function()
        local now = os.clock()
        
        if now - lastSettingsToggle < 0.25 then
            return
        end
        
        lastSettingsToggle = now
        main.Visible = false
    end)
    )
    
    local scrollContainer = Instance.new("ScrollingFrame")
    scrollContainer.Name = "SettingsScroll"
    scrollContainer.Size = UDim2.new(1, 0, 1, -50)
    scrollContainer.Position = UDim2.new(0, 0, 0, 50)
    scrollContainer.BackgroundTransparency = 1
    scrollContainer.BorderSizePixel = 0
    scrollContainer.ScrollBarThickness = 8
    scrollContainer.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
    scrollContainer.ScrollingDirection = Enum.ScrollingDirection.Y
    scrollContainer.ScrollingEnabled = true
    scrollContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scrollContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
    scrollContainer.ElasticBehavior = Enum.ElasticBehavior.Always
    scrollContainer.ZIndex = 3
    scrollContainer.Active = true
    scrollContainer.Parent = main
    
    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0, 15)
    listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Parent = scrollContainer
    
    local listPadding = Instance.new("UIPadding")
    listPadding.PaddingTop = UDim.new(0, 30)
    listPadding.PaddingBottom = UDim.new(0, 30)
    listPadding.PaddingLeft = UDim.new(0, 5)
    listPadding.PaddingRight = UDim.new(0, 15)
    listPadding.Parent = scrollContainer
    
    local function createSettingRow(labelText, height)
        local row = Instance.new("Frame")
        row.Size = UDim2.new(0.9, 0, 0, height or 60)
        row.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        row.ZIndex = 4
        
        local rowCorner = Instance.new("UICorner")
        rowCorner.CornerRadius = UDim.new(0, 8)
        rowCorner.Parent = row
        
        local rowStroke = Instance.new("UIStroke")
        rowStroke.Thickness = 3
        rowStroke.Parent = row
        
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(0.5, -10, 1, 0)
        lbl.Position = UDim2.new(0, 15, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = labelText
        lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
        lbl.Font = Enum.Font.FredokaOne
        lbl.TextSize = 20
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.ZIndex = 5
        lbl.Parent = row
        
        return row
    end
    
    local function addSliderSetting(labelText, minVal, maxVal, currentVal, callback)
        local row = createSettingRow(labelText)
        row.Parent = scrollContainer
        
        local sliderBg = Instance.new("Frame")
        sliderBg.Size = UDim2.new(0.4, 0, 0, 15)
        sliderBg.AnchorPoint = Vector2.new(1, 0.5)
        sliderBg.Position = UDim2.new(1, -20, 0.5, 0)
        sliderBg.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
        sliderBg.ZIndex = 5
        sliderBg.Parent = row
        
        local bgCorner = Instance.new("UICorner")
        bgCorner.CornerRadius = UDim.new(1, 0)
        bgCorner.Parent = sliderBg
        
        local bgStroke = Instance.new("UIStroke")
        bgStroke.Thickness = 2
        bgStroke.Parent = sliderBg
        
        local startPct = math.clamp(
        (currentVal - minVal) / (maxVal - minVal),
        0,
        1
        )
        
        local sliderFill = Instance.new("Frame")
        sliderFill.Size = UDim2.new(startPct, 0, 1, 0)
        sliderFill.BackgroundColor3 = Color3.fromRGB(40, 200, 40)
        sliderFill.ZIndex = 6
        sliderFill.Parent = sliderBg
        
        local fillCorner = Instance.new("UICorner")
        fillCorner.CornerRadius = UDim.new(1, 0)
        fillCorner.Parent = sliderFill
        
        local knob = Instance.new("TextButton")
        knob.Size = UDim2.new(0, 25, 0, 25)
        knob.AnchorPoint = Vector2.new(0.5, 0.5)
        knob.Position = UDim2.new(1, 0, 0.5, 0)
        knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        knob.Text = ""
        knob.ZIndex = 7
        knob.Parent = sliderFill
        
        local knobCorner = Instance.new("UICorner")
        knobCorner.CornerRadius = UDim.new(1, 0)
        knobCorner.Parent = knob
        
        local isDragging = false
        
        local function updateSlider(input)
            if sliderBg.AbsoluteSize.X <= 0 then
                return
            end
            
            local pos = math.clamp(
            (input.Position.X - sliderBg.AbsolutePosition.X) / sliderBg.AbsoluteSize.X,
            0,
            1
            )
            
            sliderFill.Size = UDim2.new(pos, 0, 1, 0)
            
            callback(
            minVal + (pos * (maxVal - minVal))
            )
        end
        
        table.insert(
        connections,
        knob.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
                isDragging = true
                updateSlider(input)
            end
        end)
        )
        
        table.insert(
        connections,
        sliderBg.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
                isDragging = true
                updateSlider(input)
            end
        end)
        )
        
        table.insert(
        connections,
        UserInputService.InputChanged:Connect(function(input)
            if not isDragging then
                return
            end
            
            if input.UserInputType == Enum.UserInputType.MouseMovement
                or input.UserInputType == Enum.UserInputType.Touch then
                updateSlider(input)
            end
        end)
        )
        
        table.insert(
        connections,
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
                isDragging = false
            end
        end)
        )
        
        return row
    end
    
    local function addToggleSetting(
        labelText,
        startState,
        onText,
        offText,
        callback
        )
        local row = createSettingRow(labelText)
        row.Parent = scrollContainer
        
        local toggleBtn = Instance.new("TextButton")
        toggleBtn.Size = UDim2.new(0, 120, 0, 40)
        toggleBtn.AnchorPoint = Vector2.new(1, 0.5)
        toggleBtn.Position = UDim2.new(1, -15, 0.5, 0)
        toggleBtn.BackgroundColor3 =
        startState
        and Color3.fromRGB(40, 200, 40)
        or Color3.fromRGB(200, 40, 40)
        toggleBtn.Text = startState and onText or offText
        toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        toggleBtn.Font = Enum.Font.FredokaOne
        toggleBtn.TextSize = 16
        toggleBtn.ZIndex = 5
        toggleBtn.Parent = row
        
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 6)
        btnCorner.Parent = toggleBtn
        
        local btnStroke = Instance.new("UIStroke")
        btnStroke.Thickness = 2
        btnStroke.Color = Color3.new(0, 0, 0)
        btnStroke.Parent = toggleBtn
        
        local currentState = startState
        
        table.insert(
        connections,
        toggleBtn.Activated:Connect(function()
            currentState = not currentState
            
            toggleBtn.BackgroundColor3 =
            currentState
            and Color3.fromRGB(40, 200, 40)
            or Color3.fromRGB(200, 40, 40)
            
            toggleBtn.Text = currentState and onText or offText
            
            callback(currentState)
        end)
        )
        
        return row
    end
    
    addSliderSetting(
    "Field of View",
    70,
    120,
    settingsState.fieldOfView,
    function(value)
        settingsState.fieldOfView = value
        camera.FieldOfView = value
    end
    )
    
    addSliderSetting(
    "Camera Sensitivity",
    0.1,
    2,
    settingsState.cameraSensitivity,
    function(value)
        settingsState.cameraSensitivity = value
        applyCameraSensitivity()
    end
    )
    
    addToggleSetting(
    "Time of Day",
    settingsState.timeIsDay,
    "Day",
    "Night",
    function(value)
        settingsState.timeIsDay = value
        
        local targetTime = value and 14 or 2
        
        local info = TweenInfo.new(
        1.5,
        Enum.EasingStyle.Sine,
        Enum.EasingDirection.InOut
        )
        
        TweenService:Create(
        Lighting,
        info,
        {
        ClockTime = targetTime
        }
        ):Play()
    end
    )
    
    addToggleSetting(
    "Hide GUIs",
    settingsState.hideGuis,
    "Hidden",
    "Visible",
    function(value)
        settingsState.hideGuis = value
        applyGuiVisibility()
    end
    )
    
    addToggleSetting(
    "Hide Players",
    settingsState.hidePlayers,
    "Hidden",
    "Visible",
    function(value)
        settingsState.hidePlayers = value
        setAllPlayersHidden(value)
    end
    )
    
    local skyRow = createSettingRow("Skybox", 80)
    skyRow.Parent = scrollContainer
    
    local skyBox = Instance.new("TextBox")
    skyBox.Size = UDim2.new(0.46, 0, 0, 38)
    skyBox.AnchorPoint = Vector2.new(1, 0.5)
    skyBox.Position = UDim2.new(1, -65, 0.5, 0)
    skyBox.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    skyBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    skyBox.PlaceholderText = "6 IDs: Bk,Dn,Ft,Lf,Rt,Up"
    skyBox.Text = settingsState.skyboxIds
    skyBox.Font = Enum.Font.GothamBold
    skyBox.TextSize = 12
    skyBox.ClearTextOnFocus = false
    skyBox.ZIndex = 5
    skyBox.Parent = skyRow
    
    local skyCorner = Instance.new("UICorner")
    skyCorner.CornerRadius = UDim.new(0, 6)
    skyCorner.Parent = skyBox
    
    local skyStroke = Instance.new("UIStroke")
    skyStroke.Thickness = 2
    skyStroke.Parent = skyBox
    
    local skyApply = Instance.new("TextButton")
    skyApply.Size = UDim2.new(0, 45, 0, 38)
    skyApply.AnchorPoint = Vector2.new(1, 0.5)
    skyApply.Position = UDim2.new(1, -15, 0.5, 0)
    skyApply.BackgroundColor3 = Color3.fromRGB(40, 200, 40)
    skyApply.Text = "Set"
    skyApply.TextColor3 = Color3.fromRGB(255, 255, 255)
    skyApply.Font = Enum.Font.GothamBold
    skyApply.TextSize = 13
    skyApply.ZIndex = 5
    skyApply.Parent = skyRow
    
    local skyApplyCorner = Instance.new("UICorner")
    skyApplyCorner.CornerRadius = UDim.new(0, 6)
    skyApplyCorner.Parent = skyApply
    
    local skyApplyStroke = Instance.new("UIStroke")
    skyApplyStroke.Thickness = 2
    skyApplyStroke.Color = Color3.new(0, 0, 0)
    skyApplyStroke.Parent = skyApply
    
    table.insert(
    connections,
    skyApply.Activated:Connect(function()
        settingsState.skyboxIds = skyBox.Text
        applySkybox()
    end)
    )
    
    local musicRow = createSettingRow("Music", 80)
    musicRow.Parent = scrollContainer
    
    local musicBox = Instance.new("TextBox")
    musicBox.Size = UDim2.new(0, 120, 0, 35)
    musicBox.AnchorPoint = Vector2.new(1, 0.5)
    musicBox.Position = UDim2.new(1, -60, 0.5, 0)
    musicBox.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    musicBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    musicBox.Font = Enum.Font.GothamBold
    musicBox.TextSize = 14
    musicBox.Text = settingsState.musicId
    musicBox.PlaceholderText = "Asset ID"
    musicBox.ZIndex = 5
    musicBox.Parent = musicRow
    
    local boxCorner = Instance.new("UICorner")
    boxCorner.CornerRadius = UDim.new(0, 6)
    boxCorner.Parent = musicBox
    
    local boxStroke = Instance.new("UIStroke")
    boxStroke.Thickness = 2
    boxStroke.Parent = musicBox
    
    local playBtn = Instance.new("TextButton")
    playBtn.Size = UDim2.new(0, 40, 0, 35)
    playBtn.AnchorPoint = Vector2.new(1, 0.5)
    playBtn.Position = UDim2.new(1, -15, 0.5, 0)
    playBtn.BackgroundColor3 =
    settingsState.musicPlaying
    and Color3.fromRGB(200, 40, 40)
    or Color3.fromRGB(40, 200, 40)
    playBtn.Text = settingsState.musicPlaying and "■" or "▶"
    playBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    playBtn.Font = Enum.Font.GothamBold
    playBtn.TextSize = 18
    playBtn.ZIndex = 5
    playBtn.Parent = musicRow
    
    local playCorner = Instance.new("UICorner")
    playCorner.CornerRadius = UDim.new(0, 6)
    playCorner.Parent = playBtn
    
    local playStroke = Instance.new("UIStroke")
    playStroke.Thickness = 2
    playStroke.Color = Color3.new(0, 0, 0)
    playStroke.Parent = playBtn
    
    local volRow = addSliderSetting(
    "Music Volume",
    0,
    1,
    settingsState.musicVolume,
    function(value)
        settingsState.musicVolume = value
        localMusicPlayer.Volume = value
    end
    )
    
    volRow.Visible = settingsState.musicPlaying
    
    table.insert(
    connections,
    playBtn.Activated:Connect(function()
        if not settingsState.musicPlaying then
            local id = tonumber(musicBox.Text)
            
            if id then
                settingsState.musicId = tostring(id)
                settingsState.musicPlaying = true
                
                localMusicPlayer.SoundId =
                "rbxassetid://" .. settingsState.musicId
                
                localMusicPlayer.Volume =
                settingsState.musicVolume
                
                localMusicPlayer:Play()
                
                playBtn.Text = "■"
                playBtn.BackgroundColor3 =
                Color3.fromRGB(200, 40, 40)
                
                volRow.Visible = true
            end
        else
            settingsState.musicPlaying = false
            
            localMusicPlayer:Stop()
            
            playBtn.Text = "▶"
            playBtn.BackgroundColor3 =
            Color3.fromRGB(40, 200, 40)
            
            volRow.Visible = false
        end
    end)
    )
    
    table.insert(
    connections,
    main:GetPropertyChangedSignal("Visible"):Connect(function()
        if not main.Visible then
            skyBox:ReleaseFocus()
            musicBox:ReleaseFocus()
        end
    end)
    )
    
    return main
end

local function destroyUI()
    for _, connection in ipairs(connections) do
        connection:Disconnect()
    end
    
    table.clear(connections)
    
    if screenGui then
        screenGui:Destroy()
    end
    
    screenGui = nil
    settingsFrame = nil
end

local function createUI()
    if screenGui and screenGui.Parent then
        return
    end
    
    screenGui = Instance.new("ScreenGui")
    screenGui.Name = "GameSystemUI"
    screenGui.IgnoreGuiInset = true
    screenGui.ResetOnSpawn = false
    screenGui.Parent = playerGui
    
    local uiScale = Instance.new("UIScale")
    uiScale.Parent = screenGui
    
    local safeFrame = Instance.new("Frame")
    safeFrame.Name = "SafeFrame"
    safeFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    safeFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    safeFrame.BackgroundTransparency = 1
    safeFrame.Parent = screenGui
    
    local function update()
        local vp = camera.ViewportSize
        
        if vp.X <= 0 or vp.Y <= 0 then
            return
        end
        
        local scale = math.min(
        vp.X / 1920,
        vp.Y / 1080
        )
        
        uiScale.Scale = scale
        
        safeFrame.Size = UDim2.new(
        0,
        vp.X / scale,
        0,
        vp.Y / scale
        )
    end
    
    table.insert(
    connections,
    camera:GetPropertyChangedSignal("ViewportSize"):Connect(update)
    )
    
    update()
    
    local sideContainer = Instance.new("Frame")
    sideContainer.AnchorPoint = Vector2.new(1, 0.5)
    sideContainer.Position = UDim2.new(1, -38, 0.5, 0)
    sideContainer.Size = UDim2.new(0, 96, 0, 110)
    sideContainer.BackgroundTransparency = 1
    sideContainer.Parent = safeFrame
    
    local sideLayout = Instance.new("UIListLayout")
    sideLayout.FillDirection = Enum.FillDirection.Vertical
    sideLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    sideLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    sideLayout.Padding = UDim.new(0, 15)
    sideLayout.Parent = sideContainer
    
    local settingsBtn = createSquareButton(
    sideContainer,
    gearIconId
    )
    
    settingsFrame = buildSettingsUI(safeFrame)
    
    table.insert(
    connections,
    settingsBtn.Activated:Connect(function()
        local now = os.clock()
        
        if now - lastSettingsToggle < 0.5 then
            return
        end
        
        lastSettingsToggle = now
        settingsFrame.Visible = not settingsFrame.Visible
    end)
    )
    
    applyAll()
end

local function onCharacterAdded(character)
    task.wait(0.1)
    
    camera = workspace.CurrentCamera
    
    camera.FieldOfView = settingsState.fieldOfView
    
    if humanoidConnection then
        humanoidConnection:Disconnect()
        humanoidConnection = nil
    end
    
    local humanoid = character:WaitForChild("Humanoid")
    
    humanoidConnection = humanoid.Died:Connect(function()
        destroyUI()
    end)
    
    createUI()
    
    applyAll()
end

playerGui.ChildAdded:Connect(function(child)
    if child:IsA("ScreenGui") and child ~= screenGui then
        task.defer(applyGuiVisibility)
    end
end)

Players.PlayerAdded:Connect(watchPlayer)
Players.PlayerRemoving:Connect(unwatchPlayer)

for _, otherPlayer in ipairs(Players:GetPlayers()) do
    watchPlayer(otherPlayer)
end

player.CharacterAdded:Connect(onCharacterAdded)

createUI()
setupCameraSensitivity()
applyAll()

if player.Character then
    onCharacterAdded(player.Character)
end

UserInputService:GetPropertyChangedSignal(
"MouseDeltaSensitivity"
):Connect(function()
    if UserInputService.MouseDeltaSensitivity ~= 1 then
        UserInputService.MouseDeltaSensitivity = 1
    end
end)
