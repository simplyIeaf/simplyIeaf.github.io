local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContentProvider = game:GetService("ContentProvider")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")

local Remotes = ReplicatedStorage:WaitForChild("TrollRemotes")
local ActionRemote = Remotes:WaitForChild("ActionRemote")
local GetAssetsRemote = Remotes:WaitForChild("GetAssetsRemote")
local EffectEvent = Remotes:WaitForChild("EffectEvent")

local Scroll
local isGuiOpen = false
local AssetData = nil
local lastExecuteTime = 0
local executeCooldown = 2

local function createInputBox(parent, placeholder)
	local Holder = Instance.new("Frame")
	Holder.Size = UDim2.new(1, 0, 0, 36)
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

	local ListPadding = Instance.new("UIPadding")
	ListPadding.PaddingTop = UDim.new(0, 4)
	ListPadding.PaddingBottom = UDim.new(0, 4)
	ListPadding.PaddingLeft = UDim.new(0, 4)
	ListPadding.PaddingRight = UDim.new(0, 4)
	ListPadding.Parent = ListFrame

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

local function createWidget(titleText, dropdownOptions)
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

	local getDropdown
	if dropdownOptions then
		Widget.Size = UDim2.new(0, 260, 0, 200)
		getDropdown = createDropdown(Widget, dropdownOptions)
	else
		Widget.Size = UDim2.new(0, 260, 0, 136)
	end

	local ButtonContainer = Instance.new("Frame")
	ButtonContainer.Size = UDim2.new(1, 0, 0, 36)
	ButtonContainer.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	ButtonContainer.LayoutOrder = 4
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

		ExecuteBtn.Text = "..."
		local success = ActionRemote:InvokeServer(titleText, selectedOption, target)
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
	Main.Size = UDim2.new(0, 850, 0, 550)
	Main.Position = UDim2.new(0.5, -425, 0.5, -275)
	Main.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
	Main.BorderSizePixel = 0
	Main.Active = true
	Main.ClipsDescendants = true
	Main.Parent = ScreenGui

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

	createWidget("Fake Lag")
	createWidget("Invert Controls")
	createWidget("Flip Camera")
	createWidget("Anti-Jump")
	createWidget("Night")
	createWidget("Fling")
	createWidget("Sword")
	
	isGuiOpen = true
end

EffectEvent.OnClientEvent:Connect(function(data)
	if data.Type == "Jumpscare" then
		local Gui = Instance.new("ScreenGui", LocalPlayer.PlayerGui)
		Gui.IgnoreGuiInset = true
		local Img = Instance.new("ImageLabel", Gui)
		Img.Size = UDim2.new(1, 0, 1, 0)
		Img.Image = data.Image
		Img.ScaleType = Enum.ScaleType.Stretch
		local Snd = Instance.new("Sound", Gui)
		Snd.SoundId = data.Sound
		Snd.Volume = 130
		Snd:Play()
		Snd.Ended:Wait()
		Gui:Destroy()
	elseif data.Type == "Audio" then
		local Snd = Instance.new("Sound", LocalPlayer.Character or workspace)
		Snd.SoundId = data.Sound
		Snd.Volume = 130
		Snd:Play()
		Snd.Ended:Wait()
		Snd:Destroy()
	elseif data.Type == "FakeLag" then
		local FakeLag = true
		local waitTime = 0.05
		local delayTime = 0.4

		local connection
		connection = LocalPlayer.CharacterAdded:Connect(function()
			FakeLag = false
			if connection then
				connection:Disconnect()
			end
		end)

		task.spawn(function()
			while wait(waitTime) do
				if not FakeLag then break end
				local character = LocalPlayer.Character
				if character and character:FindFirstChild("HumanoidRootPart") then
					character.HumanoidRootPart.Anchored = true
					wait(delayTime)
					character.HumanoidRootPart.Anchored = false
				end
			end
		end)
	elseif data.Type == "InvertControls" then
		local inverted = true
		local controlModule = nil
		local originalMove = nil

		local connection
		connection = LocalPlayer.CharacterAdded:Connect(function()
			inverted = false
			if controlModule and originalMove then
				controlModule.moveFunction = originalMove
			end
			if connection then
				connection:Disconnect()
			end
		end)

		task.spawn(function()
			pcall(function()
				controlModule = require(LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule")):GetControls()
				originalMove = controlModule.moveFunction

				controlModule.moveFunction = function(self, direction, relative)
					if inverted then
						originalMove(self, -direction, relative)
					else
						originalMove(self, direction, relative)
					end
				end
			end)
		end)
	elseif data.Type == "FlipCamera" then
		local flipped = true
		local camera = workspace.CurrentCamera

		local connection
		local renderConnection

		connection = LocalPlayer.CharacterAdded:Connect(function()
			flipped = false
			if renderConnection then
				renderConnection:Disconnect()
			end
			if connection then
				connection:Disconnect()
			end
		end)

		renderConnection = RunService.RenderStepped:Connect(function()
			if flipped then
				camera.CFrame = camera.CFrame * CFrame.Angles(0, 0, math.rad(180))
			end
		end)
	elseif data.Type == "AntiJump" then
		local antiJump = true
		local originalJumpPower = 50

		local connection
		connection = LocalPlayer.CharacterAdded:Connect(function(char)
			antiJump = false
			local humanoid = char:WaitForChild("Humanoid")
			humanoid.JumpPower = originalJumpPower
			if connection then
				connection:Disconnect()
			end
		end)

		task.spawn(function()
			local character = LocalPlayer.Character
			if character then
				local humanoid = character:FindFirstChild("Humanoid")
				if humanoid then
					originalJumpPower = humanoid.JumpPower
					humanoid.JumpPower = 0
				end
			end
		end)
	elseif data.Type == "Night" then
		local originalClockTime = Lighting.ClockTime
		local originalBrightness = Lighting.Brightness

		local TweenService = game:GetService("TweenService")
		local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Linear)

		local tween1 = TweenService:Create(Lighting, tweenInfo, {ClockTime = 0})
		local tween2 = TweenService:Create(Lighting, tweenInfo, {Brightness = 0.001})

		tween1:Play()
		tween2:Play()

		task.wait(60)

		local revertTween1 = TweenService:Create(Lighting, tweenInfo, {ClockTime = originalClockTime})
		local revertTween2 = TweenService:Create(Lighting, tweenInfo, {Brightness = originalBrightness})

		revertTween1:Play()
		revertTween2:Play()
	end
end)

LocalPlayer.CharacterAdded:Connect(function()
	local existingGui = LocalPlayer.PlayerGui:FindFirstChild("TrollPanelGui")
	if existingGui then
		existingGui:Destroy()
	end

	if isGuiOpen then
		task.wait(0.5)
		createPanel()
	end
end)

LocalPlayer.Chatted:Connect(function(message)
	if message == "/trollpanel" then
		createPanel()
	end
end)

task.spawn(function()
	AssetData = GetAssetsRemote:InvokeServer()
	if AssetData and AssetData.Jumpscare then
		local preloadList = {}
		for _, data in pairs(AssetData.Jumpscare) do
			local img = Instance.new("ImageLabel")
			img.Image = data.Image
			table.insert(preloadList, img)
		end
		ContentProvider:PreloadAsync(preloadList)
	end
end)