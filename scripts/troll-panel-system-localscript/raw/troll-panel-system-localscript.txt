local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContentProvider = game:GetService("ContentProvider")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local TextChatService = game:GetService("TextChatService")

local Remotes = ReplicatedStorage:WaitForChild("TrollRemotes")
local ActionRemote = Remotes:WaitForChild("ActionRemote")
local GetAssetsRemote = Remotes:WaitForChild("GetAssetsRemote")
local EffectEvent = Remotes:WaitForChild("EffectEvent")

local Scroll
local isGuiOpen = false
local AssetData = nil
local lastExecuteTime = 0
local executeCooldown = 1

local activeEffects = {
	Night = nil,
	Invert = nil,
	Flip = nil,
	AntiJump = nil,
	FakeLag = nil
}

local function handleDeath()
	local gui = LocalPlayer.PlayerGui:FindFirstChild("TrollPanelGui")
	if gui then
		gui:Destroy()
		isGuiOpen = false
	end
end

if LocalPlayer.Character then
	local hum = LocalPlayer.Character:FindFirstChild("Humanoid")
	if hum then hum.Died:Connect(handleDeath) end
end

LocalPlayer.CharacterAdded:Connect(function(char)
	local hum = char:WaitForChild("Humanoid")
	hum.Died:Connect(handleDeath)
end)

local function createInputBox(parent, placeholder, sizeY)
	local Holder = Instance.new("Frame")
	Holder.Size = UDim2.new(1, 0, 0, sizeY or 36)
	Holder.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
	Holder.BorderSizePixel = 0
	Holder.LayoutOrder = 2
	Holder.Parent = parent

	local Corner = Instance.new("UICorner")
	Corner.CornerRadius = UDim.new(0, 6)
	Corner.Parent = Holder

	local Stroke = Instance.new("UIStroke")
	Stroke.Color = Color3.fromRGB(45, 45, 45)
	Stroke.Thickness = 1
	Stroke.Parent = Holder

	local Box = Instance.new("TextBox")
	Box.Size = UDim2.new(1, -16, 1, 0)
	Box.Position = UDim2.new(0, 8, 0, 0)
	Box.BackgroundTransparency = 1
	Box.PlaceholderText = placeholder
	Box.Text = ""
	Box.Font = Enum.Font.Gotham
	Box.TextSize = 13
	Box.TextColor3 = Color3.fromRGB(230, 230, 230)
	Box.PlaceholderColor3 = Color3.fromRGB(100, 100, 100)
	Box.Parent = Holder

	return Box
end

local function createDropdown(parent, options)
	local Container = Instance.new("Frame")
	Container.Size = UDim2.new(1, 0, 0, 36)
	Container.BackgroundTransparency = 1
	Container.LayoutOrder = 3
	Container.ZIndex = 5
	Container.Parent = parent

	local Button = Instance.new("TextButton")
	Button.Size = UDim2.new(1, 0, 1, 0)
	Button.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
	Button.Text = "Select"
	Button.Font = Enum.Font.Gotham
	Button.TextSize = 13
	Button.TextColor3 = Color3.fromRGB(180, 180, 180)
	Button.AutoButtonColor = false
	Button.ZIndex = 6
	Button.Parent = Container

	local Corner = Instance.new("UICorner")
	Corner.CornerRadius = UDim.new(0, 6)
	Corner.Parent = Button

	local Stroke = Instance.new("UIStroke")
	Stroke.Color = Color3.fromRGB(45, 45, 45)
	Stroke.Thickness = 1
	Stroke.Parent = Button

	local ListFrame = Instance.new("Frame")
	ListFrame.Size = UDim2.new(1, 0, 0, 0)
	ListFrame.Position = UDim2.new(0, 0, 1, 4)
	ListFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
	ListFrame.BorderSizePixel = 0
	ListFrame.Visible = false
	ListFrame.ZIndex = 10
	ListFrame.Parent = Container

	local ListCorner = Instance.new("UICorner")
	ListCorner.CornerRadius = UDim.new(0, 6)
	ListCorner.Parent = ListFrame

	local ListLayout = Instance.new("UIListLayout")
	ListLayout.Padding = UDim.new(0, 2)
	ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	ListLayout.Parent = ListFrame

	local selectedValue = nil
	local isOpen = false

	local function toggle()
		isOpen = not isOpen
		ListFrame.Visible = isOpen
		if isOpen then
			ListFrame.Size = UDim2.new(1, 0, 0, ListLayout.AbsoluteContentSize.Y + 8)
		else
			ListFrame.Size = UDim2.new(1, 0, 0, 0)
		end
	end

	Button.MouseButton1Click:Connect(toggle)

	for _, opt in ipairs(options) do
		local Item = Instance.new("TextButton")
		Item.Size = UDim2.new(1, 0, 0, 28)
		Item.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
		Item.BackgroundTransparency = 1
		Item.Text = opt
		Item.Font = Enum.Font.Gotham
		Item.TextSize = 12
		Item.TextColor3 = Color3.fromRGB(200, 200, 200)
		Item.ZIndex = 11
		Item.Parent = ListFrame

		local ItemCorner = Instance.new("UICorner")
		ItemCorner.CornerRadius = UDim.new(0, 4)
		ItemCorner.Parent = Item

		Item.MouseButton1Click:Connect(function()
			selectedValue = opt
			Button.Text = opt
			Button.TextColor3 = Color3.fromRGB(255, 255, 255)
			toggle()
		end)
	end

	return function() return selectedValue end
end

local function createWidget(titleText, dropdownOptions, extraInputPlaceholder, hasTimeInput)
	local Widget = Instance.new("Frame")
	Widget.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
	Widget.Parent = Scroll

	local WidgetCorner = Instance.new("UICorner")
	WidgetCorner.CornerRadius = UDim.new(0, 8)
	WidgetCorner.Parent = Widget

	local WidgetStroke = Instance.new("UIStroke")
	WidgetStroke.Color = Color3.fromRGB(40, 40, 40)
	WidgetStroke.Thickness = 1
	WidgetStroke.Parent = Widget

	local WidgetLayout = Instance.new("UIListLayout")
	WidgetLayout.Padding = UDim.new(0, 10)
	WidgetLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	WidgetLayout.SortOrder = Enum.SortOrder.LayoutOrder
	WidgetLayout.Parent = Widget

	local WidgetPadding = Instance.new("UIPadding")
	WidgetPadding.PaddingTop = UDim.new(0, 12)
	WidgetPadding.PaddingBottom = UDim.new(0, 12)
	WidgetPadding.PaddingLeft = UDim.new(0, 12)
	WidgetPadding.PaddingRight = UDim.new(0, 12)
	WidgetPadding.Parent = Widget

	local WTitle = Instance.new("TextLabel")
	WTitle.Size = UDim2.new(1, 0, 0, 18)
	WTitle.BackgroundTransparency = 1
	WTitle.Text = titleText
	WTitle.Font = Enum.Font.GothamBold
	WTitle.TextSize = 14
	WTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
	WTitle.TextXAlignment = Enum.TextXAlignment.Center
	WTitle.LayoutOrder = 1
	WTitle.Parent = Widget

	local UsernameBox = createInputBox(Widget, "Username")

	local ExtraBox
	if extraInputPlaceholder then
		ExtraBox = createInputBox(Widget, extraInputPlaceholder)
	end

	local TimeBox
	if hasTimeInput then
		TimeBox = createInputBox(Widget, "Duration (Seconds)")
	end

	local getDropdown
	local height = 136
	if dropdownOptions then
		height = height + 40
		getDropdown = createDropdown(Widget, dropdownOptions)
	end
	if extraInputPlaceholder then height = height + 40 end
	if hasTimeInput then height = height + 40 end

	Widget.Size = UDim2.new(0, 260, 0, height)

	local ButtonContainer = Instance.new("Frame")
	ButtonContainer.Size = UDim2.new(1, 0, 0, 36)
	ButtonContainer.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	ButtonContainer.LayoutOrder = 10
	ButtonContainer.Parent = Widget

	local BtnCorner = Instance.new("UICorner")
	BtnCorner.CornerRadius = UDim.new(0, 6)
	BtnCorner.Parent = ButtonContainer

	local BtnGradient = Instance.new("UIGradient")
	BtnGradient.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 200, 80)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 100, 40))
	}
	BtnGradient.Rotation = 90
	BtnGradient.Parent = ButtonContainer

	local ExecuteBtn = Instance.new("TextButton")
	ExecuteBtn.Size = UDim2.new(1, 0, 1, 0)
	ExecuteBtn.BackgroundTransparency = 1
	ExecuteBtn.Text = "Execute"
	ExecuteBtn.Font = Enum.Font.GothamBold
	ExecuteBtn.TextSize = 13
	ExecuteBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	ExecuteBtn.ZIndex = 5
	ExecuteBtn.Parent = ButtonContainer

	ExecuteBtn.MouseButton1Click:Connect(function()
		local currentTime = tick()
		if currentTime - lastExecuteTime < executeCooldown then
			local remainingTime = math.ceil(executeCooldown - (currentTime - lastExecuteTime))
			ExecuteBtn.Text = "Wait " .. remainingTime .. "s"
			task.wait(1)
			ExecuteBtn.Text = "Execute"
			return
		end

		local target = UsernameBox.Text
		if target == "" then
			ExecuteBtn.Text = "Error"
			task.wait(1)
			ExecuteBtn.Text = "Execute"
			return
		end

		local selectedOption = getDropdown and getDropdown() or nil
		local extraData = ExtraBox and ExtraBox.Text or nil
		local timeData = TimeBox and TimeBox.Text or nil

		ExecuteBtn.Text = "..."
		local success = ActionRemote:InvokeServer(titleText, selectedOption, target, extraData, timeData)
		lastExecuteTime = tick()
		task.wait(0.3)
		ExecuteBtn.Text = success and "Success" or "Failed"
		task.wait(1)
		ExecuteBtn.Text = "Execute"
	end)
end

local function createPanel()
	local existingGui = LocalPlayer.PlayerGui:FindFirstChild("TrollPanelGui")
	if existingGui then
		existingGui:Destroy()
		isGuiOpen = false
		return
	end

	local ScreenGui = Instance.new("ScreenGui")
	ScreenGui.Name = "TrollPanelGui"
	ScreenGui.ResetOnSpawn = false
	ScreenGui.IgnoreGuiInset = true
	ScreenGui.DisplayOrder = 999
	ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

	local Main = Instance.new("Frame")
	Main.AnchorPoint = Vector2.new(0.5, 0.5)
	Main.Position = UDim2.new(0.5, 0, 0.5, 0)
	Main.Size = UDim2.new(0.9, 0, 0.8, 0)
	Main.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
	Main.BorderSizePixel = 0
	Main.Active = true
	Main.ClipsDescendants = true
	Main.Parent = ScreenGui

	local MainConstraints = Instance.new("UISizeConstraint")
	MainConstraints.MaxSize = Vector2.new(850, 600)
	MainConstraints.MinSize = Vector2.new(300, 400)
	MainConstraints.Parent = Main

	Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 10)
	local MainStroke = Instance.new("UIStroke", Main)
	MainStroke.Color = Color3.fromRGB(35, 35, 35)
	MainStroke.Thickness = 1

	local TopBar = Instance.new("Frame")
	TopBar.Size = UDim2.new(1, 0, 0, 45)
	TopBar.BackgroundTransparency = 1
	TopBar.Parent = Main

	local Title = Instance.new("TextLabel")
	Title.Size = UDim2.new(1, 0, 1, 0)
	Title.BackgroundTransparency = 1
	Title.Text = "Troll Panel"
	Title.Font = Enum.Font.GothamBold
	Title.TextSize = 20
	Title.TextColor3 = Color3.fromRGB(255, 255, 255)
	Title.TextXAlignment = Enum.TextXAlignment.Center
	Title.Parent = TopBar

	local CloseButton = Instance.new("TextButton")
	CloseButton.Size = UDim2.new(0, 45, 0, 45)
	CloseButton.Position = UDim2.new(1, -45, 0, 0)
	CloseButton.BackgroundTransparency = 1
	CloseButton.Text = "X"
	CloseButton.Font = Enum.Font.GothamMedium
	CloseButton.TextSize = 16
	CloseButton.TextColor3 = Color3.fromRGB(150, 150, 150)
	CloseButton.Parent = TopBar

	CloseButton.MouseButton1Click:Connect(function()
		ScreenGui:Destroy()
		isGuiOpen = false
	end)

	Scroll = Instance.new("ScrollingFrame")
	Scroll.Size = UDim2.new(1, -10, 1, -50)
	Scroll.Position = UDim2.new(0, 5, 0, 50)
	Scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	Scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	Scroll.ScrollBarImageColor3 = Color3.fromRGB(60, 60, 60)
	Scroll.ScrollBarThickness = 4
	Scroll.BackgroundTransparency = 1
	Scroll.BorderSizePixel = 0
	Scroll.Parent = Main

	local GridLayout = Instance.new("UIGridLayout", Scroll)
	GridLayout.CellSize = UDim2.new(0, 260, 0, 200)
	GridLayout.CellPadding = UDim2.new(0, 12, 0, 12)
	GridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	GridLayout.SortOrder = Enum.SortOrder.LayoutOrder

	local ScrollPadding = Instance.new("UIPadding", Scroll)
	ScrollPadding.PaddingTop = UDim.new(0, 10)
	ScrollPadding.PaddingBottom = UDim.new(0, 10)

	if AssetData then
		local jumpscareOptions = {}
		for key, _ in pairs(AssetData.Jumpscare) do
			table.insert(jumpscareOptions, key)
		end

		local audioOptions = {}
		for key, _ in pairs(AssetData.Audio) do
			table.insert(audioOptions, key)
		end

		createWidget("Jumpscare", jumpscareOptions)
		createWidget("Audio", audioOptions)
	end

	createWidget("Reset")
	createWidget("Explode")
	createWidget("Fling")
	createWidget("Fake Lag", nil, nil, true)
	createWidget("Freeze", nil, nil, true)
	createWidget("Speed", nil, "WalkSpeed Amount")
	createWidget("Morph", nil, "Morph To Username")
	createWidget("Model", nil, "Model ID")
	createWidget("Clone", nil, "Amount")
	createWidget("Fake Admin")
	createWidget("Invert Controls", nil, nil, true)
	createWidget("Flip Camera", nil, nil, true)
	createWidget("Anti-Jump", nil, nil, true)
	createWidget("Night", nil, nil, true)
	createWidget("Sword")

	isGuiOpen = true
end

EffectEvent.OnClientEvent:Connect(function(data)
	if data.Type == "Reset" then
		for key, conn in pairs(activeEffects) do
			if conn then
				pcall(function() conn:Disconnect() end)
				activeEffects[key] = nil
			end
		end
		Lighting.ClockTime = 14
		Lighting.Brightness = 2
		workspace.CurrentCamera.CFrame = workspace.CurrentCamera.CFrame
		local control = require(LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule")):GetControls()
		control:Enable()
		return
	end

	if data.Type == "Jumpscare" then
		local Gui = Instance.new("ScreenGui", LocalPlayer.PlayerGui)
		Gui.IgnoreGuiInset = true
		local Img = Instance.new("ImageLabel", Gui)
		Img.Size = UDim2.new(1, 0, 1, 0)
		Img.Image = data.Image
		Img.ScaleType = Enum.ScaleType.Stretch
		local Snd = Instance.new("Sound", Gui)
		Snd.SoundId = data.Sound
		Snd.Volume = 10
		Snd:Play()
		Snd.Ended:Wait()
		Gui:Destroy()
	elseif data.Type == "Audio" then
		local Snd = Instance.new("Sound", LocalPlayer.Character or workspace)
		Snd.SoundId = data.Sound
		Snd.Volume = 10
		Snd:Play()
		Snd.Ended:Wait()
		Snd:Destroy()
	elseif data.Type == "FakeLag" then
		if activeEffects.FakeLag then activeEffects.FakeLag:Disconnect() end
		local endTime = os.time() + (data.Duration or 5)
		activeEffects.FakeLag = RunService.Heartbeat:Connect(function()
			if os.time() > endTime then
				activeEffects.FakeLag:Disconnect()
				activeEffects.FakeLag = nil
			else
				local char = LocalPlayer.Character
				if char and char:FindFirstChild("HumanoidRootPart") then
					char.HumanoidRootPart.Anchored = true
					task.wait(math.random(1,3)/10)
					char.HumanoidRootPart.Anchored = false
				end
			end
		end)
	elseif data.Type == "FakeAdmin" then
		local channels = TextChatService:WaitForChild("TextChannels", 5)
		if channels then
			local general = channels:FindFirstChild("RBXGeneral")
			if general then
				general:DisplaySystemMessage("<font color='#FFA500'>[SERVER]: " .. data.TargetName .. " is now admin!</font>")
			end
		end
	elseif data.Type == "InvertControls" then
		if activeEffects.Invert then return end
		local endTime = os.time() + (data.Duration or 10)
		local controlModule = require(LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule")):GetControls()
		local oldMove = controlModule.moveFunction
		controlModule.moveFunction = function(self, direction, relative)
			if os.time() > endTime then
				controlModule.moveFunction = oldMove
				activeEffects.Invert = nil
			else
				oldMove(self, -direction, relative)
			end
		end
		activeEffects.Invert = true 
	elseif data.Type == "FlipCamera" then
		if activeEffects.Flip then activeEffects.Flip:Disconnect() end
		local endTime = os.time() + (data.Duration or 10)
		activeEffects.Flip = RunService.RenderStepped:Connect(function()
			if os.time() > endTime then
				activeEffects.Flip:Disconnect()
				activeEffects.Flip = nil
			else
				workspace.CurrentCamera.CFrame = workspace.CurrentCamera.CFrame * CFrame.Angles(0, 0, math.rad(180))
			end
		end)
	elseif data.Type == "AntiJump" then
		local endTime = os.time() + (data.Duration or 10)
		if activeEffects.AntiJump then activeEffects.AntiJump:Disconnect() end
		activeEffects.AntiJump = RunService.Heartbeat:Connect(function()
			if os.time() > endTime then
				if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
					LocalPlayer.Character.Humanoid.JumpPower = 50
				end
				activeEffects.AntiJump:Disconnect()
				activeEffects.AntiJump = nil
			else
				if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
					LocalPlayer.Character.Humanoid.JumpPower = 0
				end
			end
		end)
	elseif data.Type == "Night" then
		local endTime = os.time() + (data.Duration or 60)
		if activeEffects.Night then activeEffects.Night:Disconnect() end

		Lighting.ClockTime = 0
		Lighting.Brightness = 0

		activeEffects.Night = RunService.Heartbeat:Connect(function()
			if os.time() > endTime then
				Lighting.ClockTime = 14
				Lighting.Brightness = 2
				activeEffects.Night:Disconnect()
				activeEffects.Night = nil
			else
				Lighting.ClockTime = 0
				Lighting.Brightness = 0
			end
		end)
	end
end)

local TrollCommand = Instance.new("TextChatCommand")
TrollCommand.Name = "TrollPanelCommand"
TrollCommand.PrimaryAlias = "/trollpanel"
TrollCommand.Parent = TextChatService

TrollCommand.Triggered:Connect(function()
	local success, data = pcall(function()
		return GetAssetsRemote:InvokeServer()
	end)
	if success and data then
		AssetData = data
		createPanel()
	end
end)

task.spawn(function()
	local success, data = pcall(function()
		return GetAssetsRemote:InvokeServer()
	end)
	if success and data then
		AssetData = data
		if AssetData.Jumpscare then
			local preloadList = {}
			for _, d in pairs(AssetData.Jumpscare) do
				local img = Instance.new("ImageLabel")
				img.Image = d.Image
				table.insert(preloadList, img)
			end
			ContentProvider:PreloadAsync(preloadList)
		end
	end
end)