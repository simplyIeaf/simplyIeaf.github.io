-- made by @simplyIeaf1 on youtube

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local respawnEvent = ReplicatedStorage:WaitForChild("RespawnEvent")

-- ui setup
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DeathUI"
screenGui.IgnoreGuiInset = true
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

-- UIScale for resolution scaling
local uiScale = Instance.new("UIScale")
uiScale.Parent = screenGui

local function updateScale()
	local minScale = 0.7
	local scaleX = camera.ViewportSize.X / 1920
	local scaleY = camera.ViewportSize.Y / 1080
	uiScale.Scale = math.max(minScale, math.min(scaleX, scaleY))
end
updateScale()
camera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale)

-- frame
local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 300, 0, 80)
frame.Position = UDim2.new(0, -320, 1, -120) -- off-screen bottom-left
frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
frame.BackgroundTransparency = 0.45 -- less opacity but still visible
frame.BorderSizePixel = 0
frame.Visible = false
frame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = frame

local label = Instance.new("TextLabel")
label.Size = UDim2.new(1, -20, 1, 0)
label.Position = UDim2.new(0, 10, 0, 0)
label.BackgroundTransparency = 1
label.Font = Enum.Font.GothamBold
label.TextColor3 = Color3.fromRGB(255, 255, 255)
label.TextScaled = true
label.TextXAlignment = Enum.TextXAlignment.Center
label.Parent = frame

local function tween(obj, props, time, style, dir)
	return TweenService:Create(
		obj,
		TweenInfo.new(time, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out),
		props
	)
end

local function showCard(text, killer)
	frame.Visible = true
	label.Text = text or ""

	-- Start bottom-left (off-screen)
	frame.Position = UDim2.new(0, -320, 1, -120)

	local followConnection

	-- Camera if killer exists
	if killer and killer.Character and killer.Character:FindFirstChild("HumanoidRootPart") then
		local root = killer.Character.HumanoidRootPart
		camera.CameraType = Enum.CameraType.Scriptable

		-- Smooth follow
		followConnection = RunService.RenderStepped:Connect(function()
			if root and root.Parent then
				local camPos = camera.CFrame.Position
				local targetPos = root.Position
				-- smooth lerp look at killer
				local newCF = CFrame.new(camPos, camPos + (targetPos - camPos).Unit)
				camera.CFrame = camera.CFrame:Lerp(newCF, 0.1)
			end
		end)
	end

	-- anim
	tween(frame, {Position = UDim2.new(0.5, -150, 1, -120)}, 0.5):Play()
	task.wait(3)

	-- anim
	tween(frame, {Position = UDim2.new(1, 20, 1, -120)}, 0.5):Play()
	task.wait(0.6)
	frame.Visible = false

	-- stop following killer
	if followConnection then
		followConnection:Disconnect()
	end

	-- reset camera instantly
	camera.CameraType = Enum.CameraType.Custom
	camera.CameraSubject = player.Character and player.Character:FindFirstChild("Humanoid")

	-- respawn now
	respawnEvent:FireServer()
end

-- handle deaths
local function onCharacterAdded(char)
	local humanoid = char:WaitForChild("Humanoid")
	humanoid.Died:Connect(function()
		local killer = nil
		local creatorTag = humanoid:FindFirstChild("creator")
		if creatorTag and creatorTag.Value then
			killer = creatorTag.Value
		end

		if killer then
			showCard("Killed by: " .. killer.Name, killer)
		else
			showCard("You Died")
		end
	end)
end

-- character spawning stuff
if player.Character then
	onCharacterAdded(player.Character)
end
player.CharacterAdded:Connect(onCharacterAdded)