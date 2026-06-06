local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local camera = workspace.CurrentCamera

local eventFolder = ReplicatedStorage:WaitForChild("TrollSystemEvents")
local trollFunction = eventFolder:WaitForChild("TrollFunction")
local trollEvent = eventFolder:WaitForChild("TrollEvent")

local trollActions = trollFunction:InvokeServer()

local connections = {}
local screenGui
local notificationGui
local spectateBar
local trollBar

local isSpectating = false
local targetIndex = 1

local lastSpectateToggle = 0
local lastSpectateAction = 0

local studTextureId = "rbxthumb://type=Asset&id=14905298664&w=150&h=150"

local function cleanup()
	for _, conn in ipairs(connections) do
		if conn then conn:Disconnect() end
	end
	table.clear(connections)

	if screenGui then
		screenGui:Destroy()
		screenGui = nil
	end
	
	if notificationGui then
		notificationGui:Destroy()
		notificationGui = nil
	end

	if player.Character and player.Character:FindFirstChild("Humanoid") then
		camera.CameraSubject = player.Character.Humanoid
	end
	isSpectating = false
end

local function getSpectatablePlayers()
	local valid = {}
	for _, p in ipairs(Players:GetPlayers()) do
		if p.Character and p.Character:FindFirstChild("Humanoid") then
			table.insert(valid, p)
		end
	end
	return valid
end

local function showNotification(actionName, attackerName)
	if not notificationGui then return end
	local label = notificationGui:FindFirstChild("NotifyLabel")
	if not label then return end
	local stroke = label:FindFirstChild("UIStroke")
	
	label.Text = "@" .. attackerName .. " used " .. actionName
	
	local tweenInLabel = TweenService:Create(label, TweenInfo.new(0.1), {TextTransparency = 0})
	local tweenInStroke = TweenService:Create(stroke, TweenInfo.new(0.1), {Transparency = 0})
	tweenInLabel:Play()
	tweenInStroke:Play()
	
	task.delay(4, function()
		if label and stroke then
			local tweenOutLabel = TweenService:Create(label, TweenInfo.new(0.1), {TextTransparency = 1})
			local tweenOutStroke = TweenService:Create(stroke, TweenInfo.new(0.1), {Transparency = 1})
			tweenOutLabel:Play()
			tweenOutStroke:Play()
		end
	end)
end

local function triggerJumpscare()
	local jumpGui = Instance.new("ScreenGui")
	jumpGui.Name = "ScareGui"
	jumpGui.IgnoreGuiInset = true
	jumpGui.ResetOnSpawn = false
	jumpGui.Parent = playerGui
	
	local img = Instance.new("ImageLabel")
	img.Size = UDim2.new(1, 0, 1, 0)
	img.Image = "rbxthumb://type=Asset&id=7278293467&w=420&h=420"
	img.ScaleType = Enum.ScaleType.Stretch
	img.BackgroundTransparency = 1
	img.Parent = jumpGui
	
	local sound = Instance.new("Sound")
	sound.SoundId = "rbxassetid://139162107746216"
	sound.Volume = 3
	sound.Parent = jumpGui
	sound:Play()
	
	sound.Ended:Connect(function()
		jumpGui:Destroy()
	end)
end

trollEvent.OnClientEvent:Connect(function(actionName, attackerName)
	if not attackerName then
		local validPlrs = getSpectatablePlayers()
		local target = validPlrs[targetIndex]
		if target then
			trollEvent:FireServer(actionName, target)
		end
	else
		showNotification(actionName, attackerName)
		if actionName == "Jumpscare" then
			triggerJumpscare()
		end
	end
end)

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

local function buildTrollBar(parent)
	local bar = Instance.new("ImageLabel")
	bar.Name = "TrollBar"
	bar.AnchorPoint = Vector2.new(0.5, 1)
	bar.Position = UDim2.new(0.5, 0, 1, -120)
	bar.Size = UDim2.new(0, 360, 0, 50)
	bar.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
	bar.ImageColor3 = Color3.fromRGB(60, 60, 60)
	bar.Image = studTextureId
	bar.ScaleType = Enum.ScaleType.Tile
	bar.TileSize = UDim2.new(0, 50, 0, 50)
	bar.BorderSizePixel = 0
	bar.ClipsDescendants = true
	bar.Visible = false
	bar.Parent = parent

	local barStroke = Instance.new("UIStroke")
	barStroke.Thickness = 4
	barStroke.Color = Color3.fromRGB(0, 0, 0)
	barStroke.Parent = bar

	local tabsFrame = Instance.new("ScrollingFrame")
	tabsFrame.Name = "TabsFrame"
	tabsFrame.Size = UDim2.new(1, 0, 1, 0)
	tabsFrame.BackgroundTransparency = 1
	tabsFrame.BorderSizePixel = 0
	tabsFrame.ScrollBarThickness = 0
	tabsFrame.ScrollingEnabled = true
	tabsFrame.ScrollingDirection = Enum.ScrollingDirection.X
	tabsFrame.AutomaticCanvasSize = Enum.AutomaticSize.X
	tabsFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
	tabsFrame.ClipsDescendants = true
	tabsFrame.Parent = bar

	local tabsPadding = Instance.new("UIPadding")
	tabsPadding.PaddingLeft = UDim.new(0, 7)
	tabsPadding.PaddingRight = UDim.new(0, 7)
	tabsPadding.PaddingTop = UDim.new(0, 7)
	tabsPadding.PaddingBottom = UDim.new(0, 7)
	tabsPadding.Parent = tabsFrame

	local tabsLayout = Instance.new("UIListLayout")
	tabsLayout.Name = "TabsLayout"
	tabsLayout.FillDirection = Enum.FillDirection.Horizontal
	tabsLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	tabsLayout.Padding = UDim.new(0, 5)
	tabsLayout.SortOrder = Enum.SortOrder.LayoutOrder
	tabsLayout.Parent = tabsFrame

	local function makePageButton(action)
		local pb = Instance.new("ImageButton")
		pb.AutomaticSize = Enum.AutomaticSize.X
		pb.Size = UDim2.new(0, 0, 1, 0)
		pb.BackgroundColor3 = Color3.fromRGB(25, 200, 25)
		pb.Image = studTextureId
		pb.ImageTransparency = 0.2
		pb.ScaleType = Enum.ScaleType.Tile
		pb.TileSize = UDim2.new(0, 35, 0, 35)
		pb.Parent = tabsFrame

		local gradient = Instance.new("UIGradient")
		gradient.Color = ColorSequence.new(Color3.fromRGB(40, 220, 40), Color3.fromRGB(15, 120, 15))
		gradient.Rotation = 90
		gradient.Parent = pb

		local pbPad = Instance.new("UIPadding")
		pbPad.PaddingLeft = UDim.new(0, 10)
		pbPad.PaddingRight = UDim.new(0, 10)
		pbPad.Parent = pb

		local s = Instance.new("UIStroke")
		s.Thickness = 4
		s.Color = Color3.fromRGB(0, 0, 0)
		s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		s.Parent = pb

		local txt = Instance.new("TextLabel")
		txt.AutomaticSize = Enum.AutomaticSize.X
		txt.Size = UDim2.new(0, 0, 1, 0)
		txt.BackgroundTransparency = 1
		txt.Text = action.Name
		txt.Font = Enum.Font.GothamBold
		txt.TextColor3 = Color3.new(1, 1, 1)
		txt.TextSize = 13
		txt.ZIndex = 2
		txt.Parent = pb

		local txtStroke = Instance.new("UIStroke")
		txtStroke.Thickness = 2
		txtStroke.Color = Color3.fromRGB(0, 0, 0)
		txtStroke.Parent = txt

		table.insert(connections, pb.Activated:Connect(function()
			MarketplaceService:PromptProductPurchase(player, action.ProductId)
		end))

		return pb
	end

	for _, action in ipairs(trollActions) do
		makePageButton(action)
	end

	local mousedOver = false

	table.insert(connections, tabsFrame.MouseEnter:Connect(function()
		mousedOver = true
	end))

	table.insert(connections, tabsFrame.MouseLeave:Connect(function()
		mousedOver = false
	end))

	table.insert(connections, UserInputService.InputChanged:Connect(function(io)
		if io.UserInputType ~= Enum.UserInputType.MouseWheel then return end
		if not mousedOver or not bar.Visible then return end
		
		local diff = math.max(0, tabsFrame.CanvasSize.X.Offset - tabsFrame.AbsoluteWindowSize.X)
		local newPos = math.clamp(tabsFrame.CanvasPosition.X - (io.Position.Z * 60), 0, diff)
		TweenService:Create(tabsFrame, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {CanvasPosition = Vector2.new(newPos, 0)}):Play()
	end))

	return bar
end

local function buildSpectateBar(parent)
	local bar = Instance.new("ImageLabel")
	bar.AnchorPoint = Vector2.new(0.5, 1)
	bar.Position = UDim2.new(0.5, 0, 1, -40)
	bar.Size = UDim2.new(0, 400, 0, 70)
	bar.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
	bar.ImageColor3 = Color3.fromRGB(60, 60, 60)
	bar.Image = studTextureId
	bar.ScaleType = Enum.ScaleType.Tile
	bar.TileSize = UDim2.new(0, 70, 0, 70)
	bar.BorderSizePixel = 0
	bar.Visible = false
	bar.Parent = parent

	local barStroke = Instance.new("UIStroke")
	barStroke.Thickness = 4
	barStroke.Parent = bar

	local function createArrow(text, isLeft)
		local btn = Instance.new("ImageButton")
		btn.Size = UDim2.new(0, 70, 1, 0)
		btn.Image = studTextureId
		btn.ScaleType = Enum.ScaleType.Tile
		btn.TileSize = UDim2.new(0, 35, 0, 35)
		btn.ImageTransparency = 0.2

		if isLeft then
			btn.AnchorPoint = Vector2.new(1, 0)
			btn.Position = UDim2.new(0, 0, 0, 0)
		else
			btn.AnchorPoint = Vector2.new(0, 0)
			btn.Position = UDim2.new(1, 0, 0, 0)
		end

		btn.BackgroundColor3 = Color3.fromRGB(25, 200, 25)

		local gradient = Instance.new("UIGradient")
		gradient.Color = ColorSequence.new(Color3.fromRGB(40, 220, 40), Color3.fromRGB(15, 120, 15))
		gradient.Rotation = 90
		gradient.Parent = btn

		local btnStroke = Instance.new("UIStroke")
		btnStroke.Thickness = 4
		btnStroke.Parent = btn

		local txt = Instance.new("TextLabel")
		txt.Size = UDim2.new(1, 0, 1, 0)
		txt.BackgroundTransparency = 1
		txt.Text = text
		txt.Font = Enum.Font.GothamBold
		txt.TextColor3 = Color3.new(1, 1, 1)
		txt.TextSize = 34
		txt.ZIndex = 2
		txt.Parent = btn

		local txtStroke = Instance.new("UIStroke")
		txtStroke.Thickness = 2
		txtStroke.Parent = txt

		btn.Parent = bar
		return btn
	end

	local leftBtn = createArrow("Q", true)
	local rightBtn = createArrow("E", false)

	local displayLbl = Instance.new("TextLabel")
	displayLbl.Size = UDim2.new(1, 0, 0.4, 0)
	displayLbl.Position = UDim2.new(0, 0, 0.15, 0)
	displayLbl.BackgroundTransparency = 1
	displayLbl.Font = Enum.Font.GothamBold
	displayLbl.TextColor3 = Color3.new(1, 1, 1)
	displayLbl.TextSize = 28
	displayLbl.Parent = bar

	local userLbl = Instance.new("TextLabel")
	userLbl.Size = UDim2.new(1, 0, 0.4, 0)
	userLbl.Position = UDim2.new(0, 0, 0.5, 0)
	userLbl.BackgroundTransparency = 1
	userLbl.Font = Enum.Font.GothamBold
	userLbl.TextColor3 = Color3.fromRGB(200, 200, 200)
	userLbl.TextSize = 20
	userLbl.Parent = bar

	return bar, leftBtn, rightBtn, displayLbl, userLbl
end

local function createUI()
	cleanup()

	local existing = playerGui:FindFirstChild("GameSystemUI")
	if existing then existing:Destroy() end
	
	local existingNotify = playerGui:FindFirstChild("NotificationGui")
	if existingNotify then existingNotify:Destroy() end

	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "GameSystemUI"
	screenGui.IgnoreGuiInset = true
	screenGui.ResetOnSpawn = false
	screenGui.Parent = playerGui
	
	notificationGui = Instance.new("ScreenGui")
	notificationGui.Name = "NotificationGui"
	notificationGui.ResetOnSpawn = false
	notificationGui.Parent = playerGui
	
	local notifyLbl = Instance.new("TextLabel")
	notifyLbl.Name = "NotifyLabel"
	notifyLbl.AnchorPoint = Vector2.new(0.5, 0)
	notifyLbl.Position = UDim2.new(0.5, 0, 0.05, 0)
	notifyLbl.Size = UDim2.new(0.5, 0, 0, 50)
	notifyLbl.BackgroundTransparency = 1
	notifyLbl.Font = Enum.Font.GothamBold
	notifyLbl.TextColor3 = Color3.new(1, 1, 1)
	notifyLbl.TextTransparency = 1
	notifyLbl.TextSize = 35
	notifyLbl.Text = ""
	notifyLbl.Parent = notificationGui
	
	local notifyStroke = Instance.new("UIStroke")
	notifyStroke.Thickness = 2
	notifyStroke.Transparency = 1
	notifyStroke.Parent = notifyLbl

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
		if vp.X <= 0 or vp.Y <= 0 then return end
		local scale = math.min(vp.X / 1920, vp.Y / 1080)
		uiScale.Scale = scale
		safeFrame.Size = UDim2.new(0, vp.X / scale, 0, vp.Y / scale)
	end

	table.insert(connections, camera:GetPropertyChangedSignal("ViewportSize"):Connect(update))
	update()

	local sideContainer = Instance.new("Frame")
	sideContainer.Name = "SideContainer"
	sideContainer.AnchorPoint = Vector2.new(0, 0.5)
	sideContainer.Position = UDim2.new(0, 38, 0.5, 0)
	sideContainer.Size = UDim2.new(0, 207, 0, 120)
	sideContainer.BackgroundTransparency = 1
	sideContainer.Parent = safeFrame

	local sideLayout = Instance.new("UIListLayout")
	sideLayout.FillDirection = Enum.FillDirection.Vertical
	sideLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	sideLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	sideLayout.Padding = UDim.new(0, 15)
	sideLayout.Parent = sideContainer

	local specShopFrame = Instance.new("Frame")
	specShopFrame.Name = "SpecShopFrame"
	specShopFrame.Size = UDim2.new(1, 0, 0, 96)
	specShopFrame.BackgroundTransparency = 1
	specShopFrame.Parent = sideContainer

	local specShopLayout = Instance.new("UIListLayout")
	specShopLayout.FillDirection = Enum.FillDirection.Horizontal
	specShopLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	specShopLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	specShopLayout.Padding = UDim.new(0, 15)
	specShopLayout.Parent = specShopFrame

	local spectateBtn = createSquareButton(specShopFrame, "7035631386")

	trollBar = buildTrollBar(safeFrame)
	local bar, leftBtn, rightBtn, displayLbl, userLbl = buildSpectateBar(safeFrame)
	spectateBar = bar

	local function updateTargetVisuals()
		local validPlrs = getSpectatablePlayers()
		if #validPlrs == 0 then return end

		if targetIndex > #validPlrs then targetIndex = 1 end
		if targetIndex < 1 then targetIndex = #validPlrs end

		local target = validPlrs[targetIndex]
		if target then
			displayLbl.Text = target.DisplayName
			userLbl.Text = "@" .. target.Name
			if target.Character and target.Character:FindFirstChild("Humanoid") then
				camera.CameraSubject = target.Character.Humanoid
			end
		end
	end

	local function shiftTarget(direction)
		if not isSpectating then return end

		local now = os.clock()
		if now - lastSpectateAction < 1 then return end
		lastSpectateAction = now

		local validPlrs = getSpectatablePlayers()
		if #validPlrs > 0 then
			targetIndex = targetIndex + direction
			updateTargetVisuals()
		end
	end

	table.insert(connections, leftBtn.Activated:Connect(function() shiftTarget(-1) end))
	table.insert(connections, rightBtn.Activated:Connect(function() shiftTarget(1) end))

	table.insert(connections, UserInputService.InputBegan:Connect(function(input, gpe)
		if gpe or not isSpectating then return end
		if input.KeyCode == Enum.KeyCode.Q then
			shiftTarget(-1)
		elseif input.KeyCode == Enum.KeyCode.E then
			shiftTarget(1)
		end
	end))

	table.insert(connections, RunService.RenderStepped:Connect(function()
		if isSpectating then
			local validPlrs = getSpectatablePlayers()
			local target = validPlrs[targetIndex]
			if target and target.Character and target.Character:FindFirstChild("Humanoid") then
				if camera.CameraSubject ~= target.Character.Humanoid then
					camera.CameraSubject = target.Character.Humanoid
				end
			else
				local now = os.clock()
				if now - lastSpectateAction >= 1 then
					targetIndex = targetIndex + 1
					updateTargetVisuals()
				end
			end
		end
	end))

	table.insert(connections, spectateBtn.Activated:Connect(function()
		local now = os.clock()
		if now - lastSpectateToggle < 1 then return end
		lastSpectateToggle = now

		isSpectating = not isSpectating
		spectateBar.Visible = isSpectating
		trollBar.Visible = isSpectating

		if isSpectating then
			local plrs = getSpectatablePlayers()
			targetIndex = table.find(plrs, player) or 1
			updateTargetVisuals()
		else
			if player.Character and player.Character:FindFirstChild("Humanoid") then
				camera.CameraSubject = player.Character.Humanoid
			end
		end
	end))
end

local characterConnection
local function onCharacterAdded(char)
	task.wait(0.05)
	createUI()

	local humanoid = char:WaitForChild("Humanoid", 5)
	if humanoid then
		table.insert(connections, humanoid.Died:Connect(function()
			cleanup()
		end))
	end
end

if player.Character then
	onCharacterAdded(player.Character)
end

characterConnection = player.CharacterAdded:Connect(onCharacterAdded)

pcall(function()
	game.Close:Connect(function()
		if characterConnection then characterConnection:Disconnect() end
		cleanup()
	end)
end)