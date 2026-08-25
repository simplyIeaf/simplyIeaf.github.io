local players = game:GetService("Players")
local runService = game:GetService("RunService")
local debris = game:GetService("Debris")
local tweens = game:GetService("TweenService")
local userInputService = game:GetService("UserInputService")

local lp = players.LocalPlayer
local char = lp.Character or lp.CharacterAdded:Wait()
local hum = char:WaitForChild("Humanoid")
local root = char:WaitForChild("HumanoidRootPart")

local CD_TIME = 5
local POWER = 75
local DUR = 0.2
local USE_CUSTOM_ANIMS = false
local FORWARD_ANIM_ID = "rbxassetid://0"
local BACKWARD_ANIM_ID = "rbxassetid://0"
local LEFT_ANIM_ID = "rbxassetid://0"
local RIGHT_ANIM_ID = "rbxassetid://0"
local SOUND_ENABLED = true
local SOUND_ID = "rbxassetid://0"
local CAMERA_SHAKE = true

local isMobile = userInputService.TouchEnabled and not userInputService.KeyboardEnabled

local gui = Instance.new("ScreenGui")
gui.Name = "DashSystemGui"
gui.ResetOnSpawn = true
gui.Parent = lp:WaitForChild("PlayerGui")

local btn = Instance.new("TextButton")
btn.Name = "DashBtn"
btn.Size = UDim2.fromScale(0.12, 0.12)
btn.Position = UDim2.fromScale(0.86, 0.55)
btn.AnchorPoint = Vector2.new(0.5, 0.5)
btn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
btn.BackgroundTransparency = 0.4
btn.Text = "Dash"
btn.TextColor3 = Color3.fromRGB(255, 255, 255)
btn.Font = Enum.Font.GothamBold
btn.TextScaled = true
btn.Visible = isMobile
btn.Parent = gui

local round = Instance.new("UICorner")
round.CornerRadius = UDim.new(0.5, 0)
round.Parent = btn

local stroke = Instance.new("UIStroke")
stroke.Color = btn.BackgroundColor3
stroke.Thickness = 3
stroke.Transparency = 0.5
stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
stroke.Parent = btn

local pad = Instance.new("UIPadding")
local spacing = UDim.new(0.20, 0)
pad.PaddingBottom = spacing
pad.PaddingTop = spacing
pad.PaddingLeft = spacing
pad.PaddingRight = spacing
pad.Parent = btn

local textSizeConstraint = Instance.new("UITextSizeConstraint")
textSizeConstraint.MaxTextSize = 30
textSizeConstraint.MinTextSize = 10
textSizeConstraint.Parent = btn

Instance.new("UIAspectRatioConstraint", btn).AspectRatio = 1

local dashAnims = {
    forward = nil,
    backward = nil,
    left = nil,
    right = nil
}

local function loadAnimations()
    if not USE_CUSTOM_ANIMS then return end
    
    local animator = hum:FindFirstChildOfClass("Animator")
    if not animator then return end
    
    if FORWARD_ANIM_ID ~= "rbxassetid://0" then
        local anim = Instance.new("Animation")
        anim.AnimationId = FORWARD_ANIM_ID
        dashAnims.forward = animator:LoadAnimation(anim)
        dashAnims.forward.Priority = Enum.AnimationPriority.Action
    end
    
    if BACKWARD_ANIM_ID ~= "rbxassetid://0" then
        local anim = Instance.new("Animation")
        anim.AnimationId = BACKWARD_ANIM_ID
        dashAnims.backward = animator:LoadAnimation(anim)
        dashAnims.backward.Priority = Enum.AnimationPriority.Action
    end
    
    if LEFT_ANIM_ID ~= "rbxassetid://0" then
        local anim = Instance.new("Animation")
        anim.AnimationId = LEFT_ANIM_ID
        dashAnims.left = animator:LoadAnimation(anim)
        dashAnims.left.Priority = Enum.AnimationPriority.Action
    end
    
    if RIGHT_ANIM_ID ~= "rbxassetid://0" then
        local anim = Instance.new("Animation")
        anim.AnimationId = RIGHT_ANIM_ID
        dashAnims.right = animator:LoadAnimation(anim)
        dashAnims.right.Priority = Enum.AnimationPriority.Action
    end
end

loadAnimations()

lp.CharacterAdded:Connect(function(newChar)
    char = newChar
    hum = newChar:WaitForChild("Humanoid")
    root = newChar:WaitForChild("HumanoidRootPart")
    
    loadAnimations()
    
    hum.Died:Connect(function()
        gui:Destroy()
    end)
end)

local function getDashDirection()
    local moveDir = hum.MoveDirection
    
    if moveDir.Magnitude < 0.1 then
        return root.CFrame.LookVector, "forward"
    end
    
    local rootCF = root.CFrame
    local relativeMoveDir = rootCF:VectorToObjectSpace(moveDir)
    
    local absX = math.abs(relativeMoveDir.X)
    local absZ = math.abs(relativeMoveDir.Z)
    
    if absZ > absX then
        if relativeMoveDir.Z < 0 then
            return rootCF.LookVector, "forward"
        else
            return -rootCF.LookVector, "backward"
        end
    else
        if relativeMoveDir.X > 0 then
            return rootCF.RightVector, "right"
        else
            return -rootCF.RightVector, "left"
        end
    end
end

local function playSound()
    if not SOUND_ENABLED or SOUND_ID == "rbxassetid://0" then return end
    
    local sound = Instance.new("Sound")
    sound.SoundId = SOUND_ID
    sound.Volume = 0.5
    sound.PlaybackSpeed = 1.2
    sound.Parent = root
    sound:Play()
    debris:AddItem(sound, 1)
end

local function shakeCamera()
    if not CAMERA_SHAKE then return end
    
    local camera = workspace.CurrentCamera
    local original = camera.CFrame
    
    for i = 1, 5 do
        local shake = CFrame.new(
            math.random(-5, 5) / 50,
            math.random(-5, 5) / 50,
            math.random(-5, 5) / 50
        )
        camera.CFrame = camera.CFrame * shake
        task.wait()
    end
end

local function playDashAnimation(direction)
    if not USE_CUSTOM_ANIMS then return end
    
    local anim = dashAnims[direction]
    if anim then
        anim:Play()
    end
end

local function doDash()
    if not char or not hum or not root then return end
    
    local state = hum:GetState()
    if state == Enum.HumanoidStateType.Jumping or state == Enum.HumanoidStateType.Freefall then return end
    if hum.Health <= 0 then return end
    
    local stamp = lp:GetAttribute("DashCD") or 0
    if os.clock() < stamp then return end
    
    lp:SetAttribute("DashCD", os.clock() + CD_TIME)
    
    local dir, dashType = getDashDirection()
    
    playDashAnimation(dashType)
    playSound()
    shakeCamera()
    
    local att = Instance.new("Attachment", root)
    local vel = Instance.new("LinearVelocity", att)
    
    vel.MaxForce = 9999999
    vel.VectorVelocity = dir * POWER
    vel.Attachment0 = att
    vel.RelativeTo = Enum.ActuatorRelativeTo.World
    
    debris:AddItem(att, DUR)
end

btn.MouseButton1Click:Connect(doDash)

userInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.F then
        doDash()
    end
end)

runService.RenderStepped:Connect(function()
    if not isMobile then return end
    
    local stamp = lp:GetAttribute("DashCD") or 0
    local diff = stamp - os.clock()
    
    if diff > 0 then
        btn.Text = string.format("%.1f", diff)
        btn.BackgroundTransparency = 0.7
        stroke.Transparency = 0.8
    else
        btn.Text = "Dash"
        btn.BackgroundTransparency = 0.4
        stroke.Transparency = 0.5
    end
end)

if hum then
    hum.Died:Connect(function()
        for _, anim in pairs(dashAnims) do
            if anim then
                anim:Stop()
            end
        end
        gui:Destroy()
    end)
end