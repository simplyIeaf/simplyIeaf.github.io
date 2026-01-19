local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ContextActionService = game:GetService("ContextActionService")
local TextChatService = game:GetService("TextChatService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local camera = workspace.CurrentCamera

local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local lastCommandTime = 0

local freecamEnabled = false
local movementDisabled = false

local cameraState = {
    Position = Vector3.new(0, 0, 0),
    Rotation = Vector2.new(0, 0),
    Velocity = Vector3.new(0, 0, 0)
}

local settings = {
    Speed = 2,
    SprintSpeed = 5,
    Sensitivity = 0.25,
    Damping = 0.15,
    FOV = 70,
    MobileSensitivity = 0.5,
    Keybinds = {
        Forward = Enum.KeyCode.W,
        Backward = Enum.KeyCode.S,
        Left = Enum.KeyCode.A,
        Right = Enum.KeyCode.D,
        Up = Enum.KeyCode.E,
        Down = Enum.KeyCode.Q,
        Sprint = Enum.KeyCode.LeftShift,
        ToggleFreecam = Enum.KeyCode.F
    }
}

local inputState = {
    W = false, A = false, S = false, D = false,
    E = false, Q = false, Shift = false
}

local mobileControls = {
    MovementThumbstick = nil,
    MovementKnob = nil,
    UpDownDpad = nil,
    ZoomButton = nil,
    MovementDragging = false,
    UpDownDragging = false,
    MoveVector = Vector3.new(0, 0, 0),
    UpDownVector = 0,
    MovementTouchId = nil,
    UpDownTouchId = nil
}

local connections = {}
local originalWalkSpeed = 16
local originalJumpPower = 50

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "FreecamInterface"
screenGui.Parent = playerGui
screenGui.ResetOnSpawn = true
screenGui.IgnoreGuiInset = true
screenGui.Enabled = isMobile

if isMobile then
    local thumbFrame = Instance.new("Frame")
    thumbFrame.Name = "MovementThumbstick"
    thumbFrame.Size = UDim2.fromOffset(120, 120)
    thumbFrame.Position = UDim2.new(0, 30, 1, -150)
    thumbFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    thumbFrame.BackgroundTransparency = 0.6
    thumbFrame.Visible = false
    thumbFrame.ZIndex = 10
    thumbFrame.Parent = screenGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = thumbFrame
    
    local knob = Instance.new("Frame")
    knob.Name = "Knob"
    knob.Size = UDim2.fromOffset(50, 50)
    knob.Position = UDim2.fromScale(0.5, 0.5)
    knob.AnchorPoint = Vector2.new(0.5, 0.5)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.BackgroundTransparency = 0.2
    knob.Parent = thumbFrame
    
    local knobCorner = Instance.new("UICorner")
    knobCorner.CornerRadius = UDim.new(1, 0)
    knobCorner.Parent = knob
    
    mobileControls.MovementThumbstick = thumbFrame
    mobileControls.MovementKnob = knob
    
    local dpadFrame = Instance.new("Frame")
    dpadFrame.Name = "UpDownDpad"
    dpadFrame.Size = UDim2.fromOffset(120, 120)
    dpadFrame.Position = UDim2.new(0, 170, 1, -150)
    dpadFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    dpadFrame.BackgroundTransparency = 0.6
    dpadFrame.Visible = false
    dpadFrame.ZIndex = 10
    dpadFrame.Parent = screenGui
    
    local dpadCorner = Instance.new("UICorner")
    dpadCorner.CornerRadius = UDim.new(1, 0)
    dpadCorner.Parent = dpadFrame
    
    local upArrow = Instance.new("TextLabel")
    upArrow.Name = "UpArrow"
    upArrow.Size = UDim2.fromOffset(40, 40)
    upArrow.Position = UDim2.fromScale(0.5, 0.15)
    upArrow.AnchorPoint = Vector2.new(0.5, 0.5)
    upArrow.BackgroundTransparency = 1
    upArrow.Text = "▲"
    upArrow.TextColor3 = Color3.fromRGB(255, 255, 255)
    upArrow.TextSize = 24
    upArrow.Font = Enum.Font.GothamBold
    upArrow.Parent = dpadFrame
    
    local downArrow = Instance.new("TextLabel")
    downArrow.Name = "DownArrow"
    downArrow.Size = UDim2.fromOffset(40, 40)
    downArrow.Position = UDim2.fromScale(0.5, 0.85)
    downArrow.AnchorPoint = Vector2.new(0.5, 0.5)
    downArrow.BackgroundTransparency = 1
    downArrow.Text = "▼"
    downArrow.TextColor3 = Color3.fromRGB(255, 255, 255)
    downArrow.TextSize = 24
    downArrow.Font = Enum.Font.GothamBold
    downArrow.Parent = dpadFrame
    
    local centerKnob = Instance.new("Frame")
    centerKnob.Name = "CenterKnob"
    centerKnob.Size = UDim2.fromOffset(50, 50)
    centerKnob.Position = UDim2.fromScale(0.5, 0.5)
    centerKnob.AnchorPoint = Vector2.new(0.5, 0.5)
    centerKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    centerKnob.BackgroundTransparency = 0.2
    centerKnob.Parent = dpadFrame
    
    local centerCorner = Instance.new("UICorner")
    centerCorner.CornerRadius = UDim.new(1, 0)
    centerCorner.Parent = centerKnob
    
    mobileControls.UpDownDpad = dpadFrame
    
    local zoomBtn = Instance.new("TextButton")
    zoomBtn.Name = "ZoomButton"
    zoomBtn.Size = UDim2.fromOffset(70, 70)
    zoomBtn.Position = UDim2.new(1, -100, 1, -180)
    zoomBtn.AnchorPoint = Vector2.new(0.5, 0.5)
    zoomBtn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    zoomBtn.BackgroundTransparency = 0.6
    zoomBtn.Text = "ZOOM"
    zoomBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    zoomBtn.TextSize = 14
    zoomBtn.Font = Enum.Font.GothamBold
    zoomBtn.Visible = false
    zoomBtn.ZIndex = 10
    zoomBtn.Parent = screenGui
    
    local zoomCorner = Instance.new("UICorner")
    zoomCorner.CornerRadius = UDim.new(1, 0)
    zoomCorner.Parent = zoomBtn
    
    mobileControls.ZoomButton = zoomBtn
    
    mobileControls.ZoomButton.MouseButton1Click:Connect(function()
        settings.FOV = (settings.FOV == 70) and 20 or 70
    end)
end

local function toggleDefaultGui(visible)
    local touchGui = playerGui:FindFirstChild("TouchGui")
    if touchGui then
        touchGui.Enabled = visible
    end
end

local function setCharacterMovement(enabled)
    local character = player.Character
    if not character then return end
    
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        if enabled then
            humanoid.WalkSpeed = originalWalkSpeed
            humanoid.JumpPower = originalJumpPower
        else
            originalWalkSpeed = humanoid.WalkSpeed
            originalJumpPower = humanoid.JumpPower
            humanoid.WalkSpeed = 0
            humanoid.JumpPower = 0
        end
    end
end

local function setMovementEnabled(enabled)
    if movementDisabled == not enabled then return end
    movementDisabled = not enabled
    
    if enabled then
        ContextActionService:UnbindAction("FreecamSink")
        toggleDefaultGui(true)
        setCharacterMovement(true)
    else
        ContextActionService:BindAction("FreecamSink", function() return Enum.ContextActionResult.Sink end, false, unpack(Enum.PlayerActions:GetEnumItems()))
        toggleDefaultGui(false)
        setCharacterMovement(false)
    end
end

local function updateMovementThumbstick(input)
    if not mobileControls.MovementThumbstick then return end
    local center = mobileControls.MovementThumbstick.AbsolutePosition + (mobileControls.MovementThumbstick.AbsoluteSize / 2)
    local offset = Vector2.new(input.Position.X, input.Position.Y) - center
    local radius = mobileControls.MovementThumbstick.AbsoluteSize.X / 2
    if offset.Magnitude > radius then offset = offset.Unit * radius end
    mobileControls.MovementKnob.Position = UDim2.new(0.5, offset.X, 0.5, offset.Y)
    local normalizedX = offset.X / radius
    local normalizedZ = -offset.Y / radius
    mobileControls.MoveVector = Vector3.new(normalizedX, 0, normalizedZ)
end

local function updateUpDownDpad(input)
    if not mobileControls.UpDownDpad then return end
    local center = mobileControls.UpDownDpad.AbsolutePosition + (mobileControls.UpDownDpad.AbsoluteSize / 2)
    local offset = Vector2.new(input.Position.X, input.Position.Y) - center
    local radius = mobileControls.UpDownDpad.AbsoluteSize.X / 2
    if offset.Magnitude > radius then offset = offset.Unit * radius end
    local knob = mobileControls.UpDownDpad:FindFirstChild("CenterKnob")
    if knob then
        knob.Position = UDim2.new(0.5, 0, 0.5, offset.Y)
    end
    local normalizedY = offset.Y / radius
    mobileControls.UpDownVector = normalizedY
end

local function resetMovementThumbstick()
    if mobileControls.MovementKnob then
        TweenService:Create(mobileControls.MovementKnob, TweenInfo.new(0.1), {Position = UDim2.fromScale(0.5, 0.5)}):Play()
    end
    mobileControls.MoveVector = Vector3.new(0, 0, 0)
    mobileControls.MovementDragging = false
    mobileControls.MovementTouchId = nil
end

local function resetUpDownDpad()
    local knob = mobileControls.UpDownDpad and mobileControls.UpDownDpad:FindFirstChild("CenterKnob")
    if knob then
        TweenService:Create(knob, TweenInfo.new(0.1), {Position = UDim2.fromScale(0.5, 0.5)}):Play()
    end
    mobileControls.UpDownVector = 0
    mobileControls.UpDownDragging = false
    mobileControls.UpDownTouchId = nil
end

local function enableFreecam()
    if freecamEnabled then return end
    camera = workspace.CurrentCamera
    freecamEnabled = true
    
    cameraState.Position = camera.CFrame.Position
    local rx, ry, rz = camera.CFrame:ToOrientation()
    cameraState.Rotation = Vector2.new(rx, ry)
    cameraState.Rotation = Vector2.new(
        math.clamp(cameraState.Rotation.X, -math.pi/2 + 0.01, math.pi/2 - 0.01),
        cameraState.Rotation.Y
    )
    camera.CameraType = Enum.CameraType.Scriptable
    
    setMovementEnabled(false)
    UserInputService.MouseBehavior = isMobile and Enum.MouseBehavior.Default or Enum.MouseBehavior.LockCenter
    
    if isMobile then
        mobileControls.MovementThumbstick.Visible = true
        mobileControls.UpDownDpad.Visible = true
        mobileControls.ZoomButton.Visible = true
    end
    
    connections.Render = RunService.RenderStepped:Connect(function(dt)
        local moveDir = Vector3.new(0, 0, 0)
        local speedMult = settings.Speed
        local fovScale = (70 / settings.FOV)
        
        if isMobile then
            local horizontalMove = Vector3.new(0, 0, 0)
            if mobileControls.MoveVector.Magnitude > 0.01 then
                local camYaw = CFrame.fromEulerAnglesYXZ(0, cameraState.Rotation.Y, 0)
                local right = mobileControls.MoveVector.X
                local forward = mobileControls.MoveVector.Z
                horizontalMove = camYaw * Vector3.new(right, 0, -forward)
                horizontalMove = horizontalMove * speedMult * mobileControls.MoveVector.Magnitude * fovScale
            end
            
            local verticalMove = Vector3.new(0, 0, 0)
            if math.abs(mobileControls.UpDownVector) > 0.01 then
                verticalMove = Vector3.new(0, -mobileControls.UpDownVector * speedMult * fovScale, 0)
            end
            
            moveDir = horizontalMove + verticalMove
        else
            local forward = (inputState.W and 1 or 0) - (inputState.S and 1 or 0)
            local right = (inputState.D and 1 or 0) - (inputState.A and 1 or 0)
            local up = (inputState.E and 1 or 0) - (inputState.Q and 1 or 0)
            speedMult = inputState.Shift and settings.SprintSpeed or settings.Speed
            
            if forward ~= 0 or right ~= 0 then
                local camYaw = CFrame.fromEulerAnglesYXZ(0, cameraState.Rotation.Y, 0)
                moveDir = (camYaw * Vector3.new(right, 0, -forward)).Unit * speedMult * fovScale
            end
            
            if up ~= 0 then
                moveDir = moveDir + Vector3.new(0, up * speedMult * fovScale, 0)
            end
        end
        
        cameraState.Velocity = cameraState.Velocity:Lerp(moveDir * 20, settings.Damping)
        cameraState.Position = cameraState.Position + (cameraState.Velocity * dt)
        
        local camCFrame = CFrame.new(cameraState.Position) * CFrame.fromEulerAnglesYXZ(cameraState.Rotation.X, cameraState.Rotation.Y, 0)
        camera.CFrame = camCFrame
        camera.FieldOfView = camera.FieldOfView + (settings.FOV - camera.FieldOfView) * 0.2
    end)
    
    connections.Input = UserInputService.InputChanged:Connect(function(input, processed)
        if input.UserInputType == Enum.UserInputType.MouseMovement and not isMobile then
            local newRotation = cameraState.Rotation - Vector2.new(input.Delta.Y * 0.005 * settings.Sensitivity, input.Delta.X * 0.005 * settings.Sensitivity)
            cameraState.Rotation = Vector2.new(
                math.clamp(newRotation.X, -math.pi/2 + 0.01, math.pi/2 - 0.01),
                newRotation.Y
            )
        elseif input.UserInputType == Enum.UserInputType.MouseWheel and not isMobile then
            settings.FOV = math.clamp(settings.FOV - (input.Position.Z * 5), 5, 120)
        end
        if isMobile and input.UserInputType == Enum.UserInputType.Touch then
            if mobileControls.MovementDragging and input == mobileControls.MovementTouchId then
                updateMovementThumbstick(input)
            elseif mobileControls.UpDownDragging and input == mobileControls.UpDownTouchId then
                updateUpDownDpad(input)
            elseif not mobileControls.MovementDragging and not mobileControls.UpDownDragging then
                local sensitivity = settings.MobileSensitivity * 0.005
                local newRotation = cameraState.Rotation - Vector2.new(input.Delta.Y * sensitivity, input.Delta.X * sensitivity)
                cameraState.Rotation = Vector2.new(
                    math.clamp(newRotation.X, -math.pi/2 + 0.01, math.pi/2 - 0.01),
                    newRotation.Y
                )
            end
        end
    end)
end

local function disableFreecam()
    if not freecamEnabled then return end
    freecamEnabled = false
    if connections.Render then connections.Render:Disconnect() end
    if connections.Input then connections.Input:Disconnect() end
    camera.CameraType = Enum.CameraType.Custom
    setMovementEnabled(true)
    UserInputService.MouseBehavior = Enum.MouseBehavior.Default
    if isMobile then
        mobileControls.MovementThumbstick.Visible = false
        mobileControls.UpDownDpad.Visible = false
        mobileControls.ZoomButton.Visible = false
        resetMovementThumbstick()
        resetUpDownDpad()
    end
end

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.UserInputType == Enum.UserInputType.Keyboard then
        local key = input.KeyCode
        if key == settings.Keybinds.Forward then inputState.W = true
        elseif key == settings.Keybinds.Left then inputState.A = true
        elseif key == settings.Keybinds.Backward then inputState.S = true
        elseif key == settings.Keybinds.Right then inputState.D = true
        elseif key == settings.Keybinds.Up then inputState.E = true
        elseif key == settings.Keybinds.Down then inputState.Q = true
        elseif key == settings.Keybinds.Sprint then inputState.Shift = true
        elseif key == settings.Keybinds.ToggleFreecam then
            if os.clock() - lastCommandTime < 1 then return end
            lastCommandTime = os.clock()
            if freecamEnabled then disableFreecam() else enableFreecam() end
        end
    elseif input.UserInputType == Enum.UserInputType.Touch and isMobile then
        if mobileControls.MovementThumbstick and mobileControls.MovementThumbstick.Visible then
            local tPos = input.Position
            local mPos, mSize = mobileControls.MovementThumbstick.AbsolutePosition, mobileControls.MovementThumbstick.AbsoluteSize
            if tPos.X >= mPos.X and tPos.X <= mPos.X + mSize.X and tPos.Y >= mPos.Y and tPos.Y <= mPos.Y + mSize.Y then
                mobileControls.MovementDragging, mobileControls.MovementTouchId = true, input
                updateMovementThumbstick(input)
            end
            
            local uPos, uSize = mobileControls.UpDownDpad.AbsolutePosition, mobileControls.UpDownDpad.AbsoluteSize
            if tPos.X >= uPos.X and tPos.X <= uPos.X + uSize.X and tPos.Y >= uPos.Y and tPos.Y <= uPos.Y + uSize.Y then
                mobileControls.UpDownDragging, mobileControls.UpDownTouchId = true, input
                updateUpDownDpad(input)
            end
        end
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Keyboard then
        local key = input.KeyCode
        if key == settings.Keybinds.Forward then inputState.W = false
        elseif key == settings.Keybinds.Left then inputState.A = false
        elseif key == settings.Keybinds.Backward then inputState.S = false
        elseif key == settings.Keybinds.Right then inputState.D = false
        elseif key == settings.Keybinds.Up then inputState.E = false
        elseif key == settings.Keybinds.Down then inputState.Q = false
        elseif key == settings.Keybinds.Sprint then inputState.Shift = false
        end
    elseif input.UserInputType == Enum.UserInputType.Touch and isMobile then
        if input == mobileControls.MovementTouchId then resetMovementThumbstick() end
        if input == mobileControls.UpDownTouchId then resetUpDownDpad() end
    end
end)

TextChatService.OnIncomingMessage = function(message)
    if message.TextSource and message.TextSource.UserId == player.UserId then
        if message.Text:lower() == "/freecam" then
            if os.clock() - lastCommandTime < 1 then return end
            lastCommandTime = os.clock()
            if freecamEnabled then disableFreecam() else enableFreecam() end
        end
    end
end

player.CharacterRemoving:Connect(disableFreecam)