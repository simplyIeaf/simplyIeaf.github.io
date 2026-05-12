local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local localPlayer = Players.LocalPlayer
local camera = workspace.CurrentCamera

local permittedIdsRemote = ReplicatedStorage:WaitForChild("PermittedIdsRemote")
local remoteEvent = ReplicatedStorage:WaitForChild("AnnouncementsRemote")

local STUD_TEXTURE_ID = "rbxthumb://type=Asset&id=14905298664&w=150&h=150"
local VERIFIED_ICON = utf8.char(0xE000)
local DEFAULT_SOUND_ID = 130501547093536

local FONTS = {
	"FredokaOne","GothamBold","GothamMedium","Arial","ArialBold",
	"Code","SourceSans","SourceSansBold","RobotoMono","Oswald",
	"PatrickHand","Cartoon","Arcade","Fantasy","Antique",
	"Bodoni","Creepster","DenkOne","Fondamento","Gotham"
}

local COLORS = {
	{ name = "White",      hex = "#FFFFFF" },
	{ name = "Red",        hex = "#FF5050" },
	{ name = "Green",      hex = "#50FF50" },
	{ name = "Blue",       hex = "#5080FF" },
	{ name = "Gold",       hex = "#FFD700" },
	{ name = "Pink",       hex = "#FF80FF" },
	{ name = "Cyan",       hex = "#00FFFF" },
	{ name = "Orange",     hex = "#FF8C00" },
	{ name = "Lime",       hex = "#ADFF2F" },
	{ name = "HotPink",    hex = "#FF69B4" },
	{ name = "Teal",       hex = "#00CED1" },
	{ name = "Crimson",    hex = "#DC143C" },
	{ name = "Chartreuse", hex = "#7FFF00" },
	{ name = "Purple",     hex = "#9400D3" },
	{ name = "OrangeRed",  hex = "#FF4500" },
	{ name = "DodgerBlue", hex = "#1E90FF" },
	{ name = "Khaki",      hex = "#F0E68C" },
	{ name = "Tomato",     hex = "#FF6347" },
	{ name = "Turquoise",  hex = "#40E0D0" },
	{ name = "Violet",     hex = "#EE82EE" },
}

local isPermitted = false

local function hexToColor3(hex)
	hex = hex:gsub("#", "")
	return Color3.fromRGB(
		tonumber(hex:sub(1,2), 16),
		tonumber(hex:sub(3,4), 16),
		tonumber(hex:sub(5,6), 16)
	)
end

local function makeStroke(obj, thickness)
	local s = Instance.new("UIStroke")
	s.Color = Color3.new(0,0,0)
	s.Thickness = thickness or 1
	s.Parent = obj
end

local function makeCorner(obj, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius)
	c.Parent = obj
end

local screenGui
local announcementContainer
local uiScale

local function buildAnnouncementLayer()
	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "GlobalAnnouncementsSystem"
	screenGui.IgnoreGuiInset = true
	screenGui.ResetOnSpawn = false
	screenGui.DisplayOrder = 999999
	screenGui.Parent = localPlayer.PlayerGui

	uiScale = Instance.new("UIScale")
	uiScale.Parent = screenGui

	local safeFrame = Instance.new("Frame")
	safeFrame.Size = UDim2.new(1,0,1,0)
	safeFrame.BackgroundTransparency = 1
	safeFrame.Parent = screenGui

	local function update()
		local vp = camera.ViewportSize
		uiScale.Scale = math.min(vp.X / 1920, vp.Y / 1080)
	end
	camera:GetPropertyChangedSignal("ViewportSize"):Connect(update)
	update()

	announcementContainer = Instance.new("Frame")
	announcementContainer.Size = UDim2.new(0.5,0,0.25,0)
	announcementContainer.Position = UDim2.new(0.25,0,0.04,0)
	announcementContainer.BackgroundTransparency = 1
	announcementContainer.Parent = safeFrame

	local containerList = Instance.new("UIListLayout")
	containerList.Padding = UDim.new(0,10)
	containerList.HorizontalAlignment = Enum.HorizontalAlignment.Center
	containerList.Parent = announcementContainer

	remoteEvent.OnClientEvent:Connect(function(name, message, colorHex, fontName, duration, nameColorHex, showVerified, showIcon, soundId, senderUserId)
		local soundEnabled = true

		if soundEnabled then
			local resolvedId = (type(soundId) == "number" and soundId > 0) and soundId or DEFAULT_SOUND_ID
			local soundObj = Instance.new("Sound")
			soundObj.SoundId = "rbxassetid://" .. tostring(resolvedId)
			soundObj.Volume = 0.7
			soundObj.Parent = workspace
			soundObj:Play()
			game:GetService("Debris"):AddItem(soundObj, 10)
		end

		local wrapperFrame = Instance.new("Frame")
		wrapperFrame.Size = UDim2.new(1,0,0,0)
		wrapperFrame.BackgroundTransparency = 1
		wrapperFrame.ClipsDescendants = true
		wrapperFrame.Parent = announcementContainer

		local innerFrame = Instance.new("Frame")
		innerFrame.Size = UDim2.new(1,0,1,0)
		innerFrame.Position = UDim2.new(0,0,0,0)
		innerFrame.BackgroundColor3 = Color3.new(0,0,0)
		innerFrame.BackgroundTransparency = 1
		innerFrame.BorderSizePixel = 0
		innerFrame.Parent = wrapperFrame

		local gradient = Instance.new("UIGradient")
		gradient.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.7),
			NumberSequenceKeypoint.new(0.15, 0.2),
			NumberSequenceKeypoint.new(0.85, 0.2),
			NumberSequenceKeypoint.new(1, 0.7),
		})
		gradient.Parent = innerFrame

		local contentHolder = Instance.new("Frame")
		contentHolder.BackgroundTransparency = 1
		contentHolder.AnchorPoint = Vector2.new(0.5, 0.5)
		contentHolder.Position = UDim2.new(0.5, 0, 0.5, 0)
		contentHolder.Size = UDim2.new(1, -20, 1, 0)
		contentHolder.ZIndex = 55
		contentHolder.Parent = innerFrame

		local contentLayout = Instance.new("UIListLayout")
		contentLayout.FillDirection = Enum.FillDirection.Horizontal
		contentLayout.VerticalAlignment = Enum.VerticalAlignment.Center
		contentLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		contentLayout.Padding = UDim.new(0, 6)
		contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
		contentLayout.Parent = contentHolder

		local iconImage = nil
		if showIcon and senderUserId then
			iconImage = Instance.new("ImageLabel")
			iconImage.Size = UDim2.new(0, 36, 0, 36)
			iconImage.BackgroundTransparency = 1
			iconImage.Image = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(senderUserId) .. "&w=60&h=60"
			iconImage.ImageTransparency = 1
			iconImage.ZIndex = 56
			iconImage.LayoutOrder = 1
			iconImage.Parent = contentHolder
			makeCorner(iconImage, 18)
		end

		local textLabel = Instance.new("TextLabel")
		textLabel.BackgroundTransparency = 1
		textLabel.Font = Enum.Font[fontName] or Enum.Font.FredokaOne
		textLabel.TextColor3 = Color3.new(1,1,1)
		textLabel.TextTransparency = 1
		textLabel.TextSize = 26
		textLabel.RichText = true
		textLabel.TextWrapped = true
		textLabel.AutomaticSize = Enum.AutomaticSize.XY
		textLabel.TextXAlignment = Enum.TextXAlignment.Center
		textLabel.ZIndex = 56
		textLabel.LayoutOrder = 2
		textLabel.Parent = contentHolder

		local stroke = Instance.new("UIStroke")
		stroke.Color = Color3.new(0,0,0)
		stroke.Thickness = 2
		stroke.Transparency = 1
		stroke.Parent = textLabel

		if showVerified then
			textLabel.Text = string.format(
				'<font color="%s"><b>%s</b></font> <font color="rgb(50,150,255)">%s</font> <font color="rgb(255,255,255)">:</font> <font color="%s">%s</font>',
				nameColorHex, name, VERIFIED_ICON, colorHex, message
			)
		else
			textLabel.Text = string.format(
				'<font color="%s"><b>%s</b></font> <font color="rgb(255,255,255)">:</font> <font color="%s">%s</font>',
				nameColorHex, name, colorHex, message
			)
		end

		task.wait()
		local targetHeight = math.max(textLabel.TextBounds.Y + 18, 48)

		local expandInfo = TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
		TweenService:Create(wrapperFrame, expandInfo, { Size = UDim2.new(1,0,0,targetHeight) }):Play()
		TweenService:Create(innerFrame, expandInfo, { BackgroundTransparency = 0 }):Play()

		task.delay(0.15, function()
			local textIn = TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
			TweenService:Create(textLabel, textIn, { TextTransparency = 0 }):Play()
			TweenService:Create(stroke, textIn, { Transparency = 0 }):Play()
			if iconImage then
				TweenService:Create(iconImage, textIn, { ImageTransparency = 0 }):Play()
			end
		end)

		task.wait(duration)

		local exitInfo = TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
		TweenService:Create(innerFrame, exitInfo, { Position = UDim2.new(0.15,0,0,0), BackgroundTransparency = 1 }):Play()
		TweenService:Create(textLabel, exitInfo, { TextTransparency = 1 }):Play()
		TweenService:Create(stroke, exitInfo, { Transparency = 1 }):Play()
		if iconImage then
			TweenService:Create(iconImage, exitInfo, { ImageTransparency = 1 }):Play()
		end

		task.wait(0.4)

		local collapseInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		local collapseTween = TweenService:Create(wrapperFrame, collapseInfo, { Size = UDim2.new(1,0,0,0) })
		collapseTween:Play()
		collapseTween.Completed:Connect(function()
			wrapperFrame:Destroy()
		end)
	end)
end

local function buildAdminPanel()
	local safeFrame = screenGui:FindFirstChild("Frame")

	local panel = Instance.new("Frame")
	panel.Size = UDim2.new(0,520,0,390)
	panel.Position = UDim2.new(0.5,-260,0.5,-195)
	panel.BackgroundColor3 = Color3.fromRGB(24,24,24)
	panel.BorderSizePixel = 0
	panel.Visible = false
	panel.ZIndex = 50
	panel.Parent = safeFrame
	makeCorner(panel,8)
	makeStroke(panel,2)

	local studsBackground = Instance.new("ImageLabel")
	studsBackground.Size = UDim2.new(1,0,1,0)
	studsBackground.BackgroundTransparency = 1
	studsBackground.Image = STUD_TEXTURE_ID
	studsBackground.ImageColor3 = Color3.fromRGB(255,255,255)
	studsBackground.ImageTransparency = 0.8
	studsBackground.ScaleType = Enum.ScaleType.Tile
	studsBackground.TileSize = UDim2.new(0,40,0,40)
	studsBackground.BorderSizePixel = 0
	studsBackground.ZIndex = 51
	studsBackground.Parent = panel
	makeCorner(studsBackground,8)

	local topbar = Instance.new("Frame")
	topbar.Size = UDim2.new(1,0,0,44)
	topbar.BackgroundColor3 = Color3.fromRGB(35,100,42)
	topbar.BorderSizePixel = 0
	topbar.ClipsDescendants = true
	topbar.ZIndex = 52
	topbar.Parent = panel
	makeCorner(topbar,8)

	local fill = Instance.new("Frame")
	fill.Size = UDim2.new(1,0,0,10)
	fill.Position = UDim2.new(0,0,1,-10)
	fill.BackgroundColor3 = topbar.BackgroundColor3
	fill.BorderSizePixel = 0
	fill.ZIndex = 52
	fill.Parent = topbar

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1,0,1,0)
	title.BackgroundTransparency = 1
	title.Text = "Announcements"
	title.Font = Enum.Font.FredokaOne
	title.TextColor3 = Color3.new(1,1,1)
	title.TextSize = 26
	title.TextXAlignment = Enum.TextXAlignment.Center
	title.ZIndex = 54
	title.Parent = topbar
	makeStroke(title,2)

	local closeButton = Instance.new("TextButton")
	closeButton.Size = UDim2.new(0,32,0,32)
	closeButton.Position = UDim2.new(1,-38,0.5,-16)
	closeButton.Text = "X"
	closeButton.BackgroundColor3 = Color3.fromRGB(200,30,30)
	closeButton.TextColor3 = Color3.new(1,1,1)
	closeButton.Font = Enum.Font.FredokaOne
	closeButton.TextSize = 22
	closeButton.BorderSizePixel = 0
	closeButton.ClipsDescendants = true
	closeButton.ZIndex = 55
	closeButton.Parent = topbar
	makeCorner(closeButton,6)
	makeStroke(closeButton,2)

	local scrollingFrame = Instance.new("ScrollingFrame")
	scrollingFrame.Size = UDim2.new(1,-20,1,-58)
	scrollingFrame.Position = UDim2.new(0,10,0,54)
	scrollingFrame.BackgroundTransparency = 1
	scrollingFrame.ScrollBarThickness = 5
	scrollingFrame.ScrollBarImageColor3 = Color3.fromRGB(100,100,100)
	scrollingFrame.BorderSizePixel = 0
	scrollingFrame.CanvasSize = UDim2.new(0,0,0,0)
	scrollingFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scrollingFrame.ScrollingDirection = Enum.ScrollingDirection.Y
	scrollingFrame.ElasticBehavior = Enum.ElasticBehavior.Always
	scrollingFrame.ZIndex = 52
	scrollingFrame.Parent = panel

	local scrollList = Instance.new("UIListLayout")
	scrollList.Padding = UDim.new(0,6)
	scrollList.SortOrder = Enum.SortOrder.LayoutOrder
	scrollList.Parent = scrollingFrame

	local scrollPadding = Instance.new("UIPadding")
	scrollPadding.PaddingBottom = UDim.new(0,6)
	scrollPadding.PaddingTop = UDim.new(0,2)
	scrollPadding.Parent = scrollingFrame

	local isTouchScrolling = false
	local touchStartY = 0
	local scrollStartCanvas = 0

	scrollingFrame.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch then
			isTouchScrolling = true
			touchStartY = input.Position.Y
			scrollStartCanvas = scrollingFrame.CanvasPosition.Y
		end
	end)
	scrollingFrame.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch and isTouchScrolling then
			local delta = touchStartY - input.Position.Y
			local maxScroll = scrollingFrame.AbsoluteCanvasSize.Y - scrollingFrame.AbsoluteSize.Y
			scrollingFrame.CanvasPosition = Vector2.new(0, math.clamp(scrollStartCanvas + delta, 0, math.max(0, maxScroll)))
		end
	end)
	scrollingFrame.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch then
			isTouchScrolling = false
		end
	end)

	local gamepadScrollConnection
	panel:GetPropertyChangedSignal("Visible"):Connect(function()
		if panel.Visible then
			gamepadScrollConnection = UserInputService.InputChanged:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.Gamepad1
					and input.KeyCode == Enum.KeyCode.Thumbstick1 then
					local maxScroll = scrollingFrame.AbsoluteCanvasSize.Y - scrollingFrame.AbsoluteSize.Y
					local newY = math.clamp(scrollingFrame.CanvasPosition.Y + (-input.Position.Y * 8), 0, math.max(0, maxScroll))
					scrollingFrame.CanvasPosition = Vector2.new(0, newY)
				end
			end)
		else
			if gamepadScrollConnection then
				gamepadScrollConnection:Disconnect()
				gamepadScrollConnection = nil
			end
		end
	end)

	local rowOrder = 0
	local function makeRow(height)
		rowOrder += 1
		local frame = Instance.new("Frame")
		frame.Size = UDim2.new(1,-4,0,height)
		frame.BackgroundColor3 = Color3.fromRGB(30,30,30)
		frame.BorderSizePixel = 0
		frame.ZIndex = 52
		frame.LayoutOrder = rowOrder
		frame.Parent = scrollingFrame
		makeCorner(frame,6)
		makeStroke(frame,1)
		return frame
	end

	local function createLabel(text, parent)
		local l = Instance.new("TextLabel")
		l.Size = UDim2.new(0.6,0,1,0)
		l.Position = UDim2.new(0,10,0,0)
		l.BackgroundTransparency = 1
		l.Text = text
		l.Font = Enum.Font.FredokaOne
		l.TextColor3 = Color3.new(1,1,1)
		l.TextSize = 18
		l.TextXAlignment = Enum.TextXAlignment.Left
		l.ZIndex = 54
		l.Parent = parent
		makeStroke(l,1)
	end

	local selectedColorIndex = 1
	local selectedNameColorIndex = 2
	local selectedFontIndex = 1
	local verifiedEnabled = true
	local playerIconEnabled = false
	local soundEnabled = true
	local customSoundId = DEFAULT_SOUND_ID

	local function makeSwitch(parent, initialEnabled)
		local switchBg = Instance.new("Frame")
		switchBg.Size = UDim2.new(0,52,0,26)
		switchBg.Position = UDim2.new(1,-62,0.5,-13)
		switchBg.BackgroundColor3 = initialEnabled and Color3.fromRGB(40,120,50) or Color3.fromRGB(60,60,60)
		switchBg.BorderSizePixel = 0
		switchBg.ZIndex = 54
		switchBg.Parent = parent
		makeCorner(switchBg,13)
		makeStroke(switchBg,1)

		local knob = Instance.new("Frame")
		knob.Size = UDim2.new(0,20,0,20)
		knob.Position = initialEnabled and UDim2.new(0,28,0.5,-10) or UDim2.new(0,4,0.5,-10)
		knob.BackgroundColor3 = Color3.new(1,1,1)
		knob.BorderSizePixel = 0
		knob.ZIndex = 55
		knob.Parent = switchBg
		makeCorner(knob,10)

		return switchBg, knob
	end

	local function animateSwitch(switchBg, knob, enabled)
		local t = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		if enabled then
			TweenService:Create(switchBg, t, { BackgroundColor3 = Color3.fromRGB(40,120,50) }):Play()
			TweenService:Create(knob, t, { Position = UDim2.new(0,28,0.5,-10) }):Play()
		else
			TweenService:Create(switchBg, t, { BackgroundColor3 = Color3.fromRGB(60,60,60) }):Play()
			TweenService:Create(knob, t, { Position = UDim2.new(0,4,0.5,-10) }):Play()
		end
	end

	local function bindSwitch(switchBg, knob, getEnabled, setEnabled)
		local function toggle()
			setEnabled(not getEnabled())
			animateSwitch(switchBg, knob, getEnabled())
		end
		switchBg.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch then
				toggle()
			end
		end)
	end

	local colorRow = makeRow(40)
	createLabel("Text Color:", colorRow)
	local colorButton = Instance.new("TextButton")
	colorButton.Size = UDim2.new(0.38,-10,0.75,0)
	colorButton.Position = UDim2.new(0.6,0,0.125,0)
	colorButton.BackgroundColor3 = hexToColor3(COLORS[1].hex)
	colorButton.Text = COLORS[1].name
	colorButton.TextColor3 = Color3.new(1,1,1)
	colorButton.Font = Enum.Font.FredokaOne
	colorButton.TextSize = 15
	colorButton.BorderSizePixel = 0
	colorButton.ZIndex = 54
	colorButton.Parent = colorRow
	makeCorner(colorButton,5)
	makeStroke(colorButton,1)

	local nameRow = makeRow(40)
	createLabel("Name Color:", nameRow)
	local nameButton = Instance.new("TextButton")
	nameButton.Size = UDim2.new(0.38,-10,0.75,0)
	nameButton.Position = UDim2.new(0.6,0,0.125,0)
	nameButton.BackgroundColor3 = hexToColor3(COLORS[2].hex)
	nameButton.Text = COLORS[2].name
	nameButton.TextColor3 = Color3.new(1,1,1)
	nameButton.Font = Enum.Font.FredokaOne
	nameButton.TextSize = 15
	nameButton.BorderSizePixel = 0
	nameButton.ZIndex = 54
	nameButton.Parent = nameRow
	makeCorner(nameButton,5)
	makeStroke(nameButton,1)

	local fontRow = makeRow(40)
	createLabel("Font:", fontRow)
	local fontButton = Instance.new("TextButton")
	fontButton.Size = UDim2.new(0.38,-10,0.75,0)
	fontButton.Position = UDim2.new(0.6,0,0.125,0)
	fontButton.BackgroundColor3 = Color3.fromRGB(45,45,45)
	fontButton.Text = FONTS[1]
	fontButton.TextColor3 = Color3.new(1,1,1)
	fontButton.Font = Enum.Font.FredokaOne
	fontButton.TextSize = 16
	fontButton.BorderSizePixel = 0
	fontButton.ZIndex = 54
	fontButton.Parent = fontRow
	makeCorner(fontButton,5)
	makeStroke(fontButton,1)

	local durationRow = makeRow(40)
	createLabel("Duration:", durationRow)
	local durationInput = Instance.new("TextBox")
	durationInput.Size = UDim2.new(0.38,-10,0.75,0)
	durationInput.Position = UDim2.new(0.6,0,0.125,0)
	durationInput.BackgroundColor3 = Color3.fromRGB(45,45,45)
	durationInput.Text = "5"
	durationInput.PlaceholderText = "5"
	durationInput.TextColor3 = Color3.new(1,1,1)
	durationInput.Font = Enum.Font.FredokaOne
	durationInput.TextSize = 16
	durationInput.BorderSizePixel = 0
	durationInput.ZIndex = 54
	durationInput.Parent = durationRow
	makeCorner(durationInput,5)
	makeStroke(durationInput,1)

	local messageRow = makeRow(68)
	createLabel("Message:", messageRow)
	local messageInput = Instance.new("TextBox")
	messageInput.Size = UDim2.new(0.38,-10,0.82,0)
	messageInput.Position = UDim2.new(0.6,0,0.09,0)
	messageInput.BackgroundColor3 = Color3.fromRGB(45,45,45)
	messageInput.PlaceholderText = "Type message..."
	messageInput.Text = ""
	messageInput.TextWrapped = true
	messageInput.MultiLine = true
	messageInput.ClearTextOnFocus = false
	messageInput.TextColor3 = Color3.new(1,1,1)
	messageInput.Font = Enum.Font.FredokaOne
	messageInput.TextSize = 16
	messageInput.BorderSizePixel = 0
	messageInput.ZIndex = 54
	messageInput.Parent = messageRow
	makeCorner(messageInput,5)
	makeStroke(messageInput,1)

	local verifiedRow = makeRow(40)
	createLabel("Verified:", verifiedRow)
	local verifiedSwitchBg, verifiedKnob = makeSwitch(verifiedRow, verifiedEnabled)
	bindSwitch(verifiedSwitchBg, verifiedKnob,
		function() return verifiedEnabled end,
		function(v) verifiedEnabled = v end)

	local iconRow = makeRow(40)
	createLabel("Player Icon:", iconRow)
	local iconSwitchBg, iconKnob = makeSwitch(iconRow, playerIconEnabled)
	bindSwitch(iconSwitchBg, iconKnob,
		function() return playerIconEnabled end,
		function(v) playerIconEnabled = v end)

	local soundRow = makeRow(40)
	createLabel("Sound:", soundRow)
	local soundSwitchBg, soundKnob = makeSwitch(soundRow, soundEnabled)
	bindSwitch(soundSwitchBg, soundKnob,
		function() return soundEnabled end,
		function(v) soundEnabled = v end)

	local soundIdRow = makeRow(40)
	createLabel("Sound ID:", soundIdRow)
	local soundIdInput = Instance.new("TextBox")
	soundIdInput.Size = UDim2.new(0.38,-10,0.75,0)
	soundIdInput.Position = UDim2.new(0.6,0,0.125,0)
	soundIdInput.BackgroundColor3 = Color3.fromRGB(45,45,45)
	soundIdInput.Text = tostring(DEFAULT_SOUND_ID)
	soundIdInput.PlaceholderText = tostring(DEFAULT_SOUND_ID)
	soundIdInput.TextColor3 = Color3.new(1,1,1)
	soundIdInput.Font = Enum.Font.FredokaOne
	soundIdInput.TextSize = 14
	soundIdInput.BorderSizePixel = 0
	soundIdInput.ZIndex = 54
	soundIdInput.Parent = soundIdRow
	makeCorner(soundIdInput,5)
	makeStroke(soundIdInput,1)

	local sendRow = makeRow(40)
	local typeDropdown = Instance.new("TextButton")
	typeDropdown.Size = UDim2.new(0.38,-5,0.7,0)
	typeDropdown.Position = UDim2.new(0,8,0.15,0)
	typeDropdown.BackgroundColor3 = Color3.fromRGB(45,45,45)
	typeDropdown.Text = "GLOBAL"
	typeDropdown.TextColor3 = Color3.new(1,1,1)
	typeDropdown.Font = Enum.Font.FredokaOne
	typeDropdown.TextSize = 16
	typeDropdown.BorderSizePixel = 0
	typeDropdown.ZIndex = 54
	typeDropdown.Parent = sendRow
	makeCorner(typeDropdown,5)
	makeStroke(typeDropdown,1)

	local sendButton = Instance.new("TextButton")
	sendButton.Size = UDim2.new(0.58,-10,0.7,0)
	sendButton.Position = UDim2.new(0.4,0,0.15,0)
	sendButton.BackgroundColor3 = Color3.fromRGB(40,120,50)
	sendButton.Text = "Send"
	sendButton.TextColor3 = Color3.new(1,1,1)
	sendButton.Font = Enum.Font.FredokaOne
	sendButton.TextSize = 18
	sendButton.BorderSizePixel = 0
	sendButton.ZIndex = 54
	sendButton.Parent = sendRow
	makeCorner(sendButton,5)
	makeStroke(sendButton,1)

	local toggleButton = Instance.new("TextButton")
	toggleButton.Name = "ToggleAnnouncementsButton"
	toggleButton.AnchorPoint = Vector2.new(1,1)
	toggleButton.Position = UDim2.new(1,-20,1,-20)
	toggleButton.Size = UDim2.new(0,70,0,70)
	toggleButton.Text = "📢"
	toggleButton.BackgroundColor3 = Color3.fromRGB(15,15,15)
	toggleButton.TextColor3 = Color3.new(1,1,1)
	toggleButton.Font = Enum.Font.FredokaOne
	toggleButton.TextSize = 40
	toggleButton.BorderSizePixel = 0
	toggleButton.ZIndex = 999999
	toggleButton.Parent = screenGui
	makeCorner(toggleButton,10)
	makeStroke(toggleButton,2)

	toggleButton.MouseButton1Click:Connect(function()
		panel.Visible = not panel.Visible
	end)

	closeButton.MouseButton1Click:Connect(function()
		panel.Visible = false
	end)

	colorButton.MouseButton1Click:Connect(function()
		selectedColorIndex = selectedColorIndex % #COLORS + 1
		local c = COLORS[selectedColorIndex]
		colorButton.Text = c.name
		colorButton.BackgroundColor3 = hexToColor3(c.hex)
	end)

	nameButton.MouseButton1Click:Connect(function()
		selectedNameColorIndex = selectedNameColorIndex % #COLORS + 1
		local c = COLORS[selectedNameColorIndex]
		nameButton.Text = c.name
		nameButton.BackgroundColor3 = hexToColor3(c.hex)
	end)

	fontButton.MouseButton1Click:Connect(function()
		selectedFontIndex = selectedFontIndex % #FONTS + 1
		fontButton.Text = FONTS[selectedFontIndex]
	end)

	typeDropdown.MouseButton1Click:Connect(function()
		typeDropdown.Text = typeDropdown.Text == "GLOBAL" and "SERVER" or "GLOBAL"
	end)

	soundIdInput:GetPropertyChangedSignal("Text"):Connect(function()
		local parsed = tonumber(soundIdInput.Text)
		customSoundId = (parsed and parsed > 0) and parsed or DEFAULT_SOUND_ID
	end)

	sendButton.MouseButton1Click:Connect(function()
		if not isPermitted then return end
		local duration = tonumber(durationInput.Text)
		if not duration then return end
		if messageInput.Text == "" then return end
		local resolvedSoundId = customSoundId
		if not tonumber(soundIdInput.Text) or tonumber(soundIdInput.Text) <= 0 then
			resolvedSoundId = DEFAULT_SOUND_ID
		end
		remoteEvent:FireServer(
			messageInput.Text,
			COLORS[selectedColorIndex].hex,
			FONTS[selectedFontIndex],
			duration,
			typeDropdown.Text,
			COLORS[selectedNameColorIndex].hex,
			verifiedEnabled,
			playerIconEnabled,
			resolvedSoundId
		)
	end)
end

buildAnnouncementLayer()

permittedIdsRemote:FireServer()
permittedIdsRemote.OnClientEvent:Connect(function(permitted)
	isPermitted = permitted
	if permitted then
		buildAdminPanel()
	end
end)