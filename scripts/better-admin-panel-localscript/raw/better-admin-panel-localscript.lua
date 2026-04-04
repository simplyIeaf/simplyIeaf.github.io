local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local Lighting = game:GetService("Lighting")
local TextChatService = game:GetService("TextChatService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local camera = workspace.CurrentCamera

local AdminFunction = ReplicatedStorage:WaitForChild("AdminFunction")
local AdminEvent = ReplicatedStorage:WaitForChild("AdminEvent")

local studTextureId = "rbxthumb://type=Asset&id=14905298664&w=150&h=150"
local btnTextureId = "rbxthumb://type=Asset&id=87745909437443&w=150&h=150"

local screenGui
local adminFrame
local openButton
local uiOpened = false

local isFlying = false
local currentFlySpeed = 50
local flyBodyGyro
local flyBodyVelocity

local maxClientFPS = nil
local fpsLoop
local isFakeAdmin = false
local isMessageActive = false

local controlModule
local oldMoveFunction
local controlInverted = false

local oldMusicVolumes = {}
local currentAdminMusic = nil

local climbHeartbeat
local climbAlignOrientation
local climbAttachment
local climbAnimTrack
local isClimbingWall = false

local isAdmin, commandData = AdminFunction:InvokeServer("GetCommands")

local function buildOpenButton(parent)
	local btn = Instance.new("ImageButton")
	btn.Name = "AdminOpenButton"
	btn.Size = UDim2.new(0, 50, 0, 50)
	btn.Position = UDim2.new(1, -70, 0.5, 50)
	btn.AnchorPoint = Vector2.new(0.5, 0.5)
	btn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	btn.BackgroundTransparency = 0.5
	btn.AutoButtonColor = true
	btn.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = btn

	local icon = Instance.new("ImageLabel")
	icon.Size = UDim2.new(0.6, 0, 0.6, 0)
	icon.AnchorPoint = Vector2.new(0.5, 0.5)
	icon.Position = UDim2.new(0.5, 0, 0.5, 0)
	icon.BackgroundTransparency = 1
	icon.Image = btnTextureId
	icon.Parent = btn

	btn.MouseButton1Click:Connect(function()
		if adminFrame then
			uiOpened = not uiOpened
			adminFrame.Visible = uiOpened
		end
	end)

	return btn
end

local function buildAdminUI(parent)
	local main = Instance.new("Frame")
	main.Name = "AdminFrame"
	main.Size = UDim2.new(0, 600, 0, 500)
	main.AnchorPoint = Vector2.new(0.5, 0.5)
	main.Position = UDim2.new(0.5, 0, 0.5, 0)
	main.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	main.Visible = uiOpened
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
	topBar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	topBar.BorderSizePixel = 0
	topBar.ZIndex = 2
	topBar.Parent = main
	
	local topGradient = Instance.new("UIGradient")
	topGradient.Color = ColorSequence.new(Color3.fromRGB(0, 180, 0), Color3.fromRGB(0, 90, 0))
	topGradient.Rotation = 90
	topGradient.Parent = topBar
	
	local topStuds = Instance.new("ImageLabel")
	topStuds.Size = UDim2.new(1, 0, 1, 0)
	topStuds.BackgroundTransparency = 1
	topStuds.Image = studTextureId
	topStuds.ImageColor3 = Color3.fromRGB(40, 40, 40)
	topStuds.ImageTransparency = 0.2
	topStuds.ScaleType = Enum.ScaleType.Tile
	topStuds.TileSize = UDim2.new(0, 50, 0, 50)
	topStuds.ZIndex = 2
	topStuds.Parent = topBar
	
	local topStroke = Instance.new("UIStroke")
	topStroke.Thickness = 4
	topStroke.Parent = topBar
	
	local titleText = Instance.new("TextLabel")
	titleText.Size = UDim2.new(1, 0, 1, 0)
	titleText.BackgroundTransparency = 1
	titleText.Text = "Admin Panel"
	titleText.TextColor3 = Color3.fromRGB(255, 255, 255)
	titleText.Font = Enum.Font.FredokaOne
	titleText.TextScaled = true
	titleText.ZIndex = 4
	titleText.Parent = topBar
	
	local titleConstraint = Instance.new("UITextSizeConstraint")
	titleConstraint.MaxTextSize = 22
	titleConstraint.MinTextSize = 8
	titleConstraint.Parent = titleText
	
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
	closeBtn.ZIndex = 5
	closeBtn.Parent = topBar
	
	local closeStrokeBtn = Instance.new("UIStroke")
	closeStrokeBtn.Thickness = 2
	closeStrokeBtn.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	closeStrokeBtn.Parent = closeBtn

	local closeStrokeTxt = Instance.new("UIStroke")
	closeStrokeTxt.Thickness = 2
	closeStrokeTxt.Parent = closeBtn
	
	closeBtn.MouseButton1Click:Connect(function() 
		uiOpened = false
		main.Visible = false 
	end)

	local searchBox = Instance.new("TextBox")
	searchBox.Size = UDim2.new(1, -20, 0, 30)
	searchBox.Position = UDim2.new(0, 10, 0, 60)
	searchBox.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	searchBox.Font = Enum.Font.FredokaOne
	searchBox.TextSize = 14
	searchBox.TextColor3 = Color3.new(1, 1, 1)
	searchBox.PlaceholderText = "Search Commands..."
	searchBox.Text = ""
	searchBox.Parent = main

	local searchStroke = Instance.new("UIStroke")
	searchStroke.Thickness = 2
	searchStroke.Parent = searchBox

	local searchCorner = Instance.new("UICorner")
	searchCorner.CornerRadius = UDim.new(0, 4)
	searchCorner.Parent = searchBox

	local tabsFrame = Instance.new("ScrollingFrame")
	tabsFrame.Size = UDim2.new(1, -20, 0, 30)
	tabsFrame.Position = UDim2.new(0, 10, 0, 100)
	tabsFrame.BackgroundTransparency = 1
	tabsFrame.ScrollBarThickness = 0
	tabsFrame.CanvasSize = UDim2.new(2, 0, 0, 0)
	tabsFrame.Parent = main

	local tabsLayout = Instance.new("UIListLayout")
	tabsLayout.FillDirection = Enum.FillDirection.Horizontal
	tabsLayout.Padding = UDim.new(0, 5)
	tabsLayout.Parent = tabsFrame

	local scrollFrame = Instance.new("ScrollingFrame")
	scrollFrame.Size = UDim2.new(1, -20, 1, -190)
	scrollFrame.Position = UDim2.new(0, 10, 0, 140)
	scrollFrame.BackgroundTransparency = 1
	scrollFrame.BorderSizePixel = 0
	scrollFrame.ScrollBarThickness = 8
	scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(0, 0, 0)
	scrollFrame.Parent = main

	local listLayout = Instance.new("UIListLayout")
	listLayout.Padding = UDim.new(0, 5)
	listLayout.Parent = scrollFrame

	local inputFrame = Instance.new("Frame")
	inputFrame.Size = UDim2.new(1, -20, 0, 40)
	inputFrame.Position = UDim2.new(0, 10, 1, -45)
	inputFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	inputFrame.Parent = main

	local inputCorner = Instance.new("UICorner")
	inputCorner.CornerRadius = UDim.new(0, 6)
	inputCorner.Parent = inputFrame

	local inputStroke = Instance.new("UIStroke")
	inputStroke.Thickness = 3
	inputStroke.Parent = inputFrame

	local cmdBox = Instance.new("TextBox")
	cmdBox.Size = UDim2.new(0.8, -10, 1, 0)
	cmdBox.Position = UDim2.new(0, 10, 0, 0)
	cmdBox.BackgroundTransparency = 1
	cmdBox.Font = Enum.Font.FredokaOne
	cmdBox.TextSize = 16
	cmdBox.TextColor3 = Color3.new(1, 1, 1)
	cmdBox.PlaceholderText = "Type command here..."
	cmdBox.Text = ""
	cmdBox.TextXAlignment = Enum.TextXAlignment.Left
	cmdBox.ClearTextOnFocus = false
	cmdBox.Parent = inputFrame

	local execBtn = Instance.new("TextButton")
	execBtn.Size = UDim2.new(0.2, -5, 1, -10)
	execBtn.Position = UDim2.new(0.8, 0, 0, 5)
	execBtn.BackgroundColor3 = Color3.fromRGB(40, 220, 40)
	execBtn.Text = "Run"
	execBtn.Font = Enum.Font.FredokaOne
	execBtn.TextColor3 = Color3.new(1, 1, 1)
	execBtn.TextSize = 18
	execBtn.Parent = inputFrame
	
	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 4)
	btnCorner.Parent = execBtn
	
	local btnStroke = Instance.new("UIStroke")
	btnStroke.Thickness = 2
	btnStroke.Parent = execBtn

	local commandRows = {}
	local currentCategory = "All"
	local categories = {All = true}

	if commandData then
		for _, cmd in ipairs(commandData) do
			categories[cmd.Category] = true
			
			local row = Instance.new("Frame")
			row.Size = UDim2.new(1, -15, 0, 40)
			row.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
			row.Parent = scrollFrame

			local rowCorner = Instance.new("UICorner")
			rowCorner.CornerRadius = UDim.new(0, 4)
			rowCorner.Parent = row

			local rowStroke = Instance.new("UIStroke")
			rowStroke.Thickness = 2
			rowStroke.Parent = row

			local nameLbl = Instance.new("TextLabel")
			nameLbl.Size = UDim2.new(0.3, 0, 1, 0)
			nameLbl.Position = UDim2.new(0, 10, 0, 0)
			nameLbl.BackgroundTransparency = 1
			nameLbl.Font = Enum.Font.FredokaOne
			nameLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
			nameLbl.TextSize = 18
			nameLbl.TextXAlignment = Enum.TextXAlignment.Left
			nameLbl.Text = cmd.Name
			nameLbl.Parent = row
			
			local nameStroke = Instance.new("UIStroke")
			nameStroke.Thickness = 1
			nameStroke.Parent = nameLbl

			local usageLbl = Instance.new("TextLabel")
			usageLbl.Size = UDim2.new(0.7, -20, 1, 0)
			usageLbl.Position = UDim2.new(0.3, 0, 0, 0)
			usageLbl.BackgroundTransparency = 1
			usageLbl.Font = Enum.Font.GothamBold
			usageLbl.TextColor3 = Color3.fromRGB(200, 200, 200)
			usageLbl.TextSize = 14
			usageLbl.TextXAlignment = Enum.TextXAlignment.Right
			usageLbl.Text = cmd.Usage
			usageLbl.Parent = row

			local rowBtn = Instance.new("TextButton")
			rowBtn.Size = UDim2.new(1, 0, 1, 0)
			rowBtn.BackgroundTransparency = 1
			rowBtn.Text = ""
			rowBtn.Parent = row
			rowBtn.MouseButton1Click:Connect(function()
				cmdBox.Text = cmd.Name .. " "
				cmdBox:CaptureFocus()
			end)
			
			table.insert(commandRows, {Frame = row, Name = cmd.Name, Category = cmd.Category})
		end
	end

	local function refreshList()
		local term = string.lower(searchBox.Text)
		for _, obj in ipairs(commandRows) do
			local matchesCat = (currentCategory == "All" or obj.Category == currentCategory)
			local matchesSearch = (term == "" or string.find(string.lower(obj.Name), term))
			obj.Frame.Visible = matchesCat and matchesSearch
		end
		scrollFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 10)
	end

	for cat, _ in pairs(categories) do
		local tabBtn = Instance.new("TextButton")
		tabBtn.Size = UDim2.new(0, 80, 1, 0)
		tabBtn.BackgroundColor3 = Color3.fromRGB(40, 120, 40)
		tabBtn.Text = cat
		tabBtn.Font = Enum.Font.FredokaOne
		tabBtn.TextColor3 = Color3.new(1, 1, 1)
		tabBtn.TextSize = 14
		tabBtn.Parent = tabsFrame

		local tCorner = Instance.new("UICorner")
		tCorner.CornerRadius = UDim.new(0, 4)
		tCorner.Parent = tabBtn

		local tStroke = Instance.new("UIStroke")
		tStroke.Thickness = 1
		tStroke.Parent = tabBtn

		tabBtn.MouseButton1Click:Connect(function()
			currentCategory = cat
			refreshList()
		end)
	end
	
	searchBox.Changed:Connect(function(prop)
		if prop == "Text" then refreshList() end
	end)
	refreshList()

	local function executeCommand()
		if cmdBox.Text ~= "" then
			local success, msg = AdminFunction:InvokeServer("Execute", cmdBox.Text)
			cmdBox.Text = ""
			cmdBox.PlaceholderText = msg
			task.delay(3, function() cmdBox.PlaceholderText = "Type command here..." end)
		end
	end

	execBtn.MouseButton1Click:Connect(executeCommand)
	cmdBox.FocusLost:Connect(function(enterPressed)
		if enterPressed then executeCommand() end
	end)

	return main
end

local function createUI()
	if screenGui then screenGui:Destroy() end
	
	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "AdminSystemUI"
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
		if vp.X <= 0 or vp.Y <= 0 then return end
		local scale = math.min(vp.X / 1920, vp.Y / 1080)
		uiScale.Scale = scale
		safeFrame.Size = UDim2.new(0, vp.X / scale, 0, vp.Y / scale)
	end
	
	camera:GetPropertyChangedSignal("ViewportSize"):Connect(update)
	update()
	
	if isAdmin or isFakeAdmin then
		openButton = buildOpenButton(safeFrame)
		adminFrame = buildAdminUI(safeFrame)
	end
end

createUI()

local function handleDeath()
	uiOpened = false
	if adminFrame then adminFrame:Destroy() end
	if openButton then openButton:Destroy() end
end

player.CharacterAdded:Connect(function(char)
	local hum = char:WaitForChild("Humanoid")
	hum.Died:Connect(handleDeath)
	if isAdmin or isFakeAdmin then
		createUI()
	end
end)

if player.Character then
	local hum = player.Character:FindFirstChild("Humanoid")
	if hum then
		hum.Died:Connect(handleDeath)
	end
end

UserInputService.InputBegan:Connect(function(input, gpe)
	if not gpe and input.KeyCode == Enum.KeyCode.F2 then
		if adminFrame then
			uiOpened = not uiOpened
			adminFrame.Visible = uiOpened
		end
	end
end)

local function toggleFly(enable, speed)
	local char = player.Character
	if not char then return end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	local hum = char:FindFirstChildWhichIsA("Humanoid")
	if not hrp or not hum then return end

	if enable then
		currentFlySpeed = speed or 50
	end

	if enable and not isFlying then
		isFlying = true
		
		flyBodyGyro = Instance.new("BodyGyro")
		flyBodyGyro.P = 9e4
		flyBodyGyro.maxTorque = Vector3.new(9e9, 9e9, 9e9)
		flyBodyGyro.cframe = hrp.CFrame
		flyBodyGyro.Parent = hrp
		
		flyBodyVelocity = Instance.new("BodyVelocity")
		flyBodyVelocity.velocity = Vector3.new(0, 0, 0)
		flyBodyVelocity.maxForce = Vector3.new(9e9, 9e9, 9e9)
		flyBodyVelocity.Parent = hrp
		
		hum.PlatformStand = true
		
		task.spawn(function()
			while isFlying and hum.Health > 0 do
				RunService.RenderStepped:Wait()
				flyBodyGyro.cframe = camera.CFrame
				
				local moveDir = Vector3.new()
				if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + camera.CFrame.LookVector end
				if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - camera.CFrame.LookVector end
				if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - camera.CFrame.RightVector end
				if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + camera.CFrame.RightVector end
				if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0, 1, 0) end
				if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then moveDir = moveDir - Vector3.new(0, 1, 0) end
				
				if moveDir.Magnitude > 0 then
					flyBodyVelocity.velocity = moveDir.Unit * currentFlySpeed
				else
					flyBodyVelocity.velocity = Vector3.new(0, 0, 0)
				end
			end
			toggleFly(false)
		end)
		
	elseif not enable and isFlying then
		isFlying = false
		if flyBodyGyro then flyBodyGyro:Destroy() end
		if flyBodyVelocity then flyBodyVelocity:Destroy() end
		hum.PlatformStand = false
	end
end

local function setupClimbing(char)
	local hum = char:WaitForChild("Humanoid")
	local hrp = char:WaitForChild("HumanoidRootPart")
	
	local rigType = hum.RigType
	local animId = (rigType == Enum.HumanoidRigType.R15) and "rbxassetid://507765644" or "rbxassetid://180436334"
	
	local climbAnim = Instance.new("Animation")
	climbAnim.AnimationId = animId
	
	local animator = hum:FindFirstChildOfClass("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = hum
	end
	climbAnimTrack = animator:LoadAnimation(climbAnim)
	
	climbAlignOrientation = Instance.new("AlignOrientation")
	climbAlignOrientation.Mode = Enum.OrientationAlignmentMode.OneAttachment
	climbAlignOrientation.MaxTorque = 10000
	climbAlignOrientation.Responsiveness = 200
	climbAlignOrientation.Enabled = false
	climbAlignOrientation.Parent = hrp
	
	climbAttachment = Instance.new("Attachment")
	climbAttachment.Parent = hrp
	climbAlignOrientation.Attachment0 = climbAttachment
	
	local function getRaycastPoints()
		local points = {}
		if rigType == Enum.HumanoidRigType.R15 then
			local leftLeg = char:FindFirstChild("LeftUpperLeg")
			local rightLeg = char:FindFirstChild("RightUpperLeg")
			local upperTorso = char:FindFirstChild("UpperTorso")
			if leftLeg then table.insert(points, leftLeg.Position) end
			if rightLeg then table.insert(points, rightLeg.Position) end
			if upperTorso then table.insert(points, upperTorso.Position) end
		else
			local leftLeg = char:FindFirstChild("Left Leg")
			local rightLeg = char:FindFirstChild("Right Leg")
			local torso = char:FindFirstChild("Torso")
			if leftLeg then table.insert(points, leftLeg.Position) end
			if rightLeg then table.insert(points, rightLeg.Position) end
			if torso then table.insert(points, torso.Position) end
		end
		return points
	end
	
	local function detectWall()
		local rayParams = RaycastParams.new()
		rayParams.FilterDescendantsInstances = {char}
		rayParams.FilterType = Enum.RaycastFilterType.Exclude
		
		local points = getRaycastPoints()
		local hitCount = 0
		local averageNormal = Vector3.new()
		
		for _, point in ipairs(points) do
			local ray = workspace:Raycast(point, hrp.CFrame.LookVector * 2.5, rayParams)
			if ray and ray.Instance:IsA("BasePart") and ray.Instance.CanTouch then
				hitCount = hitCount + 1
				averageNormal = averageNormal + ray.Normal
			end
		end
		
		if hitCount > 0 then
			return true, (averageNormal / hitCount).Unit
		end
		return false, nil
	end
	
	climbHeartbeat = RunService.Heartbeat:Connect(function()
		if not isClimbingWall then return end
		if not char.Parent or hum.Health <= 0 then return end
		
		local hasWall, wallNormal = detectWall()
		local moveDir = hum.MoveDirection
		local movingForward = false
		
		if moveDir.Magnitude > 0.3 then
			local dotProduct = moveDir:Dot(hrp.CFrame.LookVector)
			movingForward = dotProduct > 0.3
		end
		
		if hasWall and movingForward then
			hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
			hum:SetStateEnabled(Enum.HumanoidStateType.Freefall, false)
			
			local targetCFrame = CFrame.lookAt(hrp.Position, hrp.Position - wallNormal)
			climbAlignOrientation.CFrame = targetCFrame
			climbAlignOrientation.Enabled = true
			
			climbAnimTrack:AdjustSpeed(1)
			hrp.AssemblyLinearVelocity = Vector3.new(0, 18, 0)
			hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
			
			if hum:GetState() ~= Enum.HumanoidStateType.Climbing then
				hum:ChangeState(Enum.HumanoidStateType.Climbing)
			end
			if not climbAnimTrack.IsPlaying then
				climbAnimTrack:Play()
			end
		else
			climbAlignOrientation.Enabled = false
			hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
			hum:SetStateEnabled(Enum.HumanoidStateType.Freefall, true)
			if climbAnimTrack.IsPlaying then
				climbAnimTrack:Stop()
			end
			if hum:GetState() == Enum.HumanoidStateType.Climbing then
				hum:ChangeState(Enum.HumanoidStateType.Freefall)
			end
		end
	end)
end

local function destroyAllGuis()
	for _, gui in ipairs(playerGui:GetChildren()) do
		if not gui:IsA("ScreenGui") then continue end
		if gui.Name == "Chat" or gui.Name == "BubbleChat" or gui.Name == "Freecam" or gui.Name == "AdminSystemUI" then continue end
		gui:Destroy()
	end
end

AdminEvent.OnClientEvent:Connect(function(action, arg1, arg2, arg3)
	if action == "Fly" then
		toggleFly(arg1, arg2)
	elseif action == "Blur" then
		if arg1 then
			local b = Lighting:FindFirstChild("AdminBlur") or Instance.new("BlurEffect", Lighting)
			b.Name = "AdminBlur"
			b.Size = 24
		else
			local b = Lighting:FindFirstChild("AdminBlur")
			if b then b:Destroy() end
		end
	elseif action == "Spectate" then
		if arg1 and arg1.Character then
			camera.CameraSubject = arg1.Character:FindFirstChild("Humanoid")
		else
			if player.Character then camera.CameraSubject = player.Character:FindFirstChild("Humanoid") end
		end
	elseif action == "Rejoin" then
		TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, player)
	elseif action == "Crash" then
		player.CameraMode = Enum.CameraMode.LockFirstPerson
		Instance.new("BlurEffect", camera).Size = 999
		playerGui:ClearAllChildren()
		game:GetService("StarterGui"):SetCore("TopbarEnabled", false)
		for a = 1, 10 do
			for i = 1, 10 do
				local audio = Instance.new("Sound", playerGui)
				audio.Volume = 10
				audio.PlaybackSpeed = a * i
				audio.Looped = true
				audio.SoundId = math.random(1,2) == 1 and "rbxassetid://168137470" or "rbxassetid://714583842"
				audio:Play()
			end
		end
		task.wait(1)
		while true do end
	elseif action == "SetFPS" then
		maxClientFPS = arg1
		if fpsLoop then fpsLoop:Disconnect() end
		if maxClientFPS and maxClientFPS > 0 then
			fpsLoop = RunService.Heartbeat:Connect(function()
				local t0 = tick()
				repeat until (t0 + 1/maxClientFPS) < tick()
			end)
		end
	elseif action == "DestroyGuis" then
		destroyAllGuis()
	elseif action == "Message" then
		if isMessageActive then return end
		isMessageActive = true
		
		local msgGui = Instance.new("ScreenGui", playerGui)
		msgGui.IgnoreGuiInset = true
		msgGui.DisplayOrder = 100
		
		local frame = Instance.new("Frame", msgGui)
		frame.Size = UDim2.new(1, 0, 1, 0)
		frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		frame.BackgroundTransparency = 1
		
		local msgLabel = Instance.new("TextLabel", frame)
		msgLabel.Size = UDim2.new(0.8, 0, 0.4, 0)
		msgLabel.Position = UDim2.new(0.1, 0, 0.3, 0)
		msgLabel.BackgroundTransparency = 1
		msgLabel.Font = Enum.Font.FredokaOne
		msgLabel.Text = arg1
		msgLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		msgLabel.TextScaled = true
		msgLabel.TextTransparency = 1
		
		local senderLabel = Instance.new("TextLabel", frame)
		senderLabel.Size = UDim2.new(0.6, 0, 0.1, 0)
		senderLabel.Position = UDim2.new(0.2, 0, 0.1, 0)
		senderLabel.BackgroundTransparency = 1
		senderLabel.Font = Enum.Font.FredokaOne
		senderLabel.Text = "Message from @" .. arg2
		senderLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		senderLabel.TextScaled = true
		senderLabel.TextTransparency = 1
		
		local ti = TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		TweenService:Create(frame, ti, {BackgroundTransparency = 0.3}):Play()
		TweenService:Create(msgLabel, ti, {TextTransparency = 0}):Play()
		TweenService:Create(senderLabel, ti, {TextTransparency = 0}):Play()
		
		task.wait(5)
		
		TweenService:Create(msgLabel, ti, {TextTransparency = 1}):Play()
		TweenService:Create(senderLabel, ti, {TextTransparency = 1}):Play()
		task.wait(1)
		local fadeOutFrame = TweenService:Create(frame, ti, {BackgroundTransparency = 1})
		fadeOutFrame:Play()
		fadeOutFrame.Completed:Wait()
		
		msgGui:Destroy()
		isMessageActive = false
	elseif action == "FlipCamera" then
		if arg1 then
			camera.CFrame = camera.CFrame * CFrame.Angles(0, 0, math.rad(180))
		else
			camera.CFrame = camera.CFrame * CFrame.Angles(0, 0, math.rad(180))
		end
	elseif action == "InvertControls" then
		if arg1 then
			if not controlModule then
				controlModule = require(player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule")):GetControls()
			end
			if not controlInverted then
				oldMoveFunction = controlModule.moveFunction
				controlModule.moveFunction = function(self, direction, relative)
					oldMoveFunction(self, -direction, relative)
				end
				controlInverted = true
			end
		else
			if controlModule and controlInverted then
				controlModule.moveFunction = oldMoveFunction
				controlInverted = false
			end
		end
	elseif action == "Jumpscare" then
		local Gui = Instance.new("ScreenGui", playerGui)
		Gui.IgnoreGuiInset = true
		local Img = Instance.new("ImageLabel", Gui)
		Img.Size = UDim2.new(1, 0, 1, 0)
		Img.Image = "rbxthumb://type=Asset&id=" .. arg2 .. "&w=768&h=432"
		Img.ScaleType = Enum.ScaleType.Stretch
		local Snd = Instance.new("Sound", Gui)
		Snd.SoundId = "rbxassetid://" .. arg1
		Snd.Volume = 10
		Snd:Play()
		Snd.Ended:Wait()
		Gui:Destroy()
	elseif action == "AudioPlayer" then
		local Snd = Instance.new("Sound", player.Character or workspace)
		Snd.SoundId = "rbxassetid://" .. arg1
		Snd.Volume = 10
		Snd:Play()
		Snd.Ended:Wait()
		Snd:Destroy()
	elseif action == "Music" then
		if arg1 then
			for _, v in ipairs(workspace:GetDescendants()) do
				if v:IsA("Sound") and v.Playing then
					oldMusicVolumes[v] = v.Volume
					v.Volume = 0
				end
			end
			if currentAdminMusic then currentAdminMusic:Destroy() end
			currentAdminMusic = Instance.new("Sound", workspace)
			currentAdminMusic.SoundId = "rbxassetid://" .. arg1
			currentAdminMusic.Volume = 5
			currentAdminMusic.Looped = true
			currentAdminMusic:Play()
		else
			if currentAdminMusic then currentAdminMusic:Destroy() end
			for snd, vol in pairs(oldMusicVolumes) do
				if snd and snd.Parent then snd.Volume = vol end
			end
			oldMusicVolumes = {}
		end
	elseif action == "WallClimb" then
		if arg1 then
			if not isClimbingWall and player.Character then
				isClimbingWall = true
				setupClimbing(player.Character)
			end
		else
			isClimbingWall = false
			if climbHeartbeat then climbHeartbeat:Disconnect() end
			if climbAlignOrientation then climbAlignOrientation:Destroy() end
			if climbAttachment then climbAttachment:Destroy() end
			if climbAnimTrack and climbAnimTrack.IsPlaying then climbAnimTrack:Stop() end
			local hum = player.Character and player.Character:FindFirstChild("Humanoid")
			if hum then
				hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
				hum:SetStateEnabled(Enum.HumanoidStateType.Freefall, true)
			end
		end
	elseif action == "SystemMessage" then
		local channel = TextChatService.TextChannels:FindFirstChild("RBXGeneral")
		if channel then
			channel:DisplaySystemMessage(arg1)
		end
	elseif action == "FakeAdmin" then
		isFakeAdmin = true
		local channel = TextChatService.TextChannels:FindFirstChild("RBXGeneral")
		if channel then
			channel:DisplaySystemMessage("You are now an admin, type " .. arg1 .. "cmds for commands!")
		end
		createUI()
	elseif action == "Cmds" then
		if isFakeAdmin or isAdmin then
			uiOpened = true
			if adminFrame then adminFrame.Visible = true end
		end
	elseif action == "RunScript" then
		local func, err = loadstring(arg1)
		if func then
			pcall(func)
		else
			warn("LocalScript error:", err)
		end
	end
end)