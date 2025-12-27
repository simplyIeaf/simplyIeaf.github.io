local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")

local plr = Players.LocalPlayer
local char = plr.Character or plr.CharacterAdded:Wait()
local hum = char:WaitForChild("Humanoid")
local gui = plr:WaitForChild("PlayerGui")
local cam = workspace.CurrentCamera

local walkSpeed = 16
local runSpeed = 26
local defaultFOV = 70
local runFOV = 85
local maxStam = 100
local stam = maxStam
local drainRate = 15
local regenRate = 20
local running = false
local canRun = true

local sg = Instance.new("ScreenGui")
sg.Name = "StaminaHealthGUI"
sg.ResetOnSpawn = false
sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
sg.Parent = gui

local main = Instance.new("Frame")
main.Name = "MainFrame"
main.Size = UDim2.new(0, 320, 0, 80)
main.Position = UDim2.new(0, 30, 1, -110)
main.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
main.BorderSizePixel = 0
main.Parent = sg

local corner1 = Instance.new("UICorner")
corner1.CornerRadius = UDim.new(0, 10)
corner1.Parent = main

local stroke1 = Instance.new("UIStroke")
stroke1.Color = Color3.fromRGB(40, 40, 40)
stroke1.Thickness = 2
stroke1.Parent = main

local aspect1 = Instance.new("UIAspectRatioConstraint")
aspect1.AspectRatio = 4
aspect1.Parent = main

local pfpFrame = Instance.new("Frame")
pfpFrame.Name = "HeadshotFrame"
pfpFrame.Size = UDim2.new(0, 64, 0, 64)
pfpFrame.Position = UDim2.new(0, 8, 0.5, -32)
pfpFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
pfpFrame.BorderSizePixel = 0
pfpFrame.Parent = main

local corner2 = Instance.new("UICorner")
corner2.CornerRadius = UDim.new(0, 8)
corner2.Parent = pfpFrame

local pfp = Instance.new("ImageLabel")
pfp.Name = "Headshot"
pfp.Size = UDim2.new(1, 0, 1, 0)
pfp.BackgroundTransparency = 1
pfp.Image = Players:GetUserThumbnailAsync(plr.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
pfp.Parent = pfpFrame

local corner3 = Instance.new("UICorner")
corner3.CornerRadius = UDim.new(0, 8)
corner3.Parent = pfp

local bars = Instance.new("Frame")
bars.Name = "BarsContainer"
bars.Size = UDim2.new(0, 228, 0, 64)
bars.Position = UDim2.new(0, 84, 0.5, -32)
bars.BackgroundTransparency = 1
bars.Parent = main

local hpBg = Instance.new("Frame")
hpBg.Name = "HealthBarBg"
hpBg.Size = UDim2.new(1, 0, 0, 26)
hpBg.Position = UDim2.new(0, 0, 0, 0)
hpBg.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
hpBg.BorderSizePixel = 0
hpBg.Parent = bars

local corner4 = Instance.new("UICorner")
corner4.CornerRadius = UDim.new(0, 6)
corner4.Parent = hpBg

local hpFill = Instance.new("Frame")
hpFill.Name = "HealthBarFill"
hpFill.Size = UDim2.new(1, 0, 1, 0)
hpFill.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
hpFill.BorderSizePixel = 0
hpFill.Parent = hpBg

local corner5 = Instance.new("UICorner")
corner5.CornerRadius = UDim.new(0, 6)
corner5.Parent = hpFill

local grad1 = Instance.new("UIGradient")
grad1.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 70, 70)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 40, 40))
}
grad1.Rotation = 90
grad1.Parent = hpFill

local hpText = Instance.new("TextLabel")
hpText.Name = "HealthText"
hpText.Size = UDim2.new(1, 0, 1, 0)
hpText.BackgroundTransparency = 1
hpText.Text = "Health"
hpText.Font = Enum.Font.GothamBold
hpText.TextSize = 14
hpText.TextColor3 = Color3.fromRGB(255, 255, 255)
hpText.TextStrokeTransparency = 0.5
hpText.Parent = hpBg

local stamBg = Instance.new("Frame")
stamBg.Name = "StaminaBarBg"
stamBg.Size = UDim2.new(1, 0, 0, 26)
stamBg.Position = UDim2.new(0, 0, 0, 38)
stamBg.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
stamBg.BorderSizePixel = 0
stamBg.Parent = bars

local corner6 = Instance.new("UICorner")
corner6.CornerRadius = UDim.new(0, 6)
corner6.Parent = stamBg

local stamFill = Instance.new("Frame")
stamFill.Name = "StaminaBarFill"
stamFill.Size = UDim2.new(1, 0, 1, 0)
stamFill.BackgroundColor3 = Color3.fromRGB(50, 180, 220)
stamFill.BorderSizePixel = 0
stamFill.Parent = stamBg

local corner7 = Instance.new("UICorner")
corner7.CornerRadius = UDim.new(0, 6)
corner7.Parent = stamFill

local grad2 = Instance.new("UIGradient")
grad2.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(70, 200, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(40, 160, 220))
}
grad2.Rotation = 90
grad2.Parent = stamFill

local stamText = Instance.new("TextLabel")
stamText.Name = "StaminaText"
stamText.Size = UDim2.new(1, 0, 1, 0)
stamText.BackgroundTransparency = 1
stamText.Text = "Stamina"
stamText.Font = Enum.Font.GothamBold
stamText.TextSize = 14
stamText.TextColor3 = Color3.fromRGB(255, 255, 255)
stamText.TextStrokeTransparency = 0.5
stamText.Parent = stamBg

local btn = Instance.new("ImageButton")
btn.Name = "SprintButton"
btn.Size = UDim2.new(0, 90, 0, 90)
btn.Position = UDim2.new(1, -110, 0.5, 20)
btn.AnchorPoint = Vector2.new(0, 0)
btn.BackgroundTransparency = 1
btn.BorderSizePixel = 0
btn.Image = "rbxthumb://type=Asset&id=86542626901340&w=150&h=150"
btn.Visible = (UIS.TouchEnabled or UIS.GamepadEnabled) and not UIS.KeyboardEnabled
btn.Parent = sg

local aspect2 = Instance.new("UIAspectRatioConstraint")
aspect2.AspectRatio = 1
aspect2.Parent = btn

local info = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local fovInfo = TweenInfo.new(0.4, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)

local function updateHP(curr, max)
    local pct = math.clamp(curr / max, 0, 1)
    TweenService:Create(hpFill, info, {Size = UDim2.new(pct, 0, 1, 0)}):Play()
end

local function updateStam()
    local pct = math.clamp(stam / maxStam, 0, 1)
    TweenService:Create(stamFill, info, {Size = UDim2.new(pct, 0, 1, 0)}):Play()
end

local function startRun()
    if stam > 0 and canRun then
        running = true
        hum.WalkSpeed = runSpeed
        TweenService:Create(cam, fovInfo, {FieldOfView = runFOV}):Play()
        if btn.Visible then
            btn.Image = "rbxthumb://type=Asset&id=105069524963775&w=150&h=150"
        end
    end
end

local function stopRun()
    running = false
    hum.WalkSpeed = walkSpeed
    TweenService:Create(cam, fovInfo, {FieldOfView = defaultFOV}):Play()
    if btn.Visible then
        btn.Image = "rbxthumb://type=Asset&id=86542626901340&w=150&h=150"
    end
end

hum.HealthChanged:Connect(function(hp)
    updateHP(hp, hum.MaxHealth)
end)

updateHP(hum.Health, hum.MaxHealth)

UIS.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.LeftShift then
        startRun()
    end
end)

UIS.InputEnded:Connect(function(input, gpe)
    if input.KeyCode == Enum.KeyCode.LeftShift then
        stopRun()
    end
end)

btn.MouseButton1Down:Connect(startRun)
btn.MouseButton1Up:Connect(stopRun)

local touchActive = false
btn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch then
        touchActive = true
        startRun()
    end
end)

btn.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch and touchActive then
        touchActive = false
        stopRun()
    end
end)

RunService.Heartbeat:Connect(function(dt)
    if running and hum.MoveDirection.Magnitude > 0 then
        stam = math.max(0, stam - (drainRate * dt))
        if stam <= 0 then
            stopRun()
            canRun = false
        end
    else
        if stam < maxStam then
            stam = math.min(maxStam, stam + (regenRate * dt))
            if stam >= 20 then
                canRun = true
            end
        end
    end
    updateStam()
end)

hum.Died:Connect(function()
    sg:Destroy()
end)