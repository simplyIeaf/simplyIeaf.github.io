local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local redeemRemote = ReplicatedStorage:WaitForChild("RedeemCode")

local isGuiOpen = false
local screenGui = nil
local mainFrame = nil
local toggleButton = nil

local function createToggleButton()
	local buttonGui = Instance.new("ScreenGui")
	buttonGui.Name = "CodeToggleButtonGui"
	buttonGui.ResetOnSpawn = false
	buttonGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	buttonGui.Parent = playerGui
	
	local button = Instance.new("ImageButton")
	button.Name = "ToggleButton"
	button.Size = UDim2.new(0, 60, 0, 60)
	button.Position = UDim2.new(1, -80, 0.5, -30)
	button.AnchorPoint = Vector2.new(0, 0.5)
	button.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
	button.BorderSizePixel = 0
	button.Image = "rbxthumb://type=Asset&id=82777739698036&w=150&h=150"
	button.ScaleType = Enum.ScaleType.Fit
	button.AutoButtonColor = false
	button.Parent = buttonGui
	
	local aspectRatio = Instance.new("UIAspectRatioConstraint")
	aspectRatio.AspectRatio = 1
	aspectRatio.Parent = button
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = button
	
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(35, 35, 35)
	stroke.Thickness = 1
	stroke.Transparency = 0.5
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = button
	
	button.MouseEnter:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.2), {Size = UDim2.new(0, 66, 0, 66)}):Play()
		stroke.Transparency = 0.3
	end)
	
	button.MouseLeave:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.2), {Size = UDim2.new(0, 60, 0, 60)}):Play()
		stroke.Transparency = 0.5
	end)
	
	return buttonGui, button
end

local function createRedeemGui()
	local gui = Instance.new("ScreenGui")
	gui.Name = "CodeRedeemGui"
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = playerGui

	local frame = Instance.new("Frame")
	frame.Name = "MainFrame"
	frame.Size = UDim2.new(0, 440, 0, 300)
	frame.Position = UDim2.new(0.5, 0, 0.5, 0)
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
	frame.BorderSizePixel = 0
	frame.Visible = false
	frame.Parent = gui
	
	local guiAspectRatio = Instance.new("UIAspectRatioConstraint")
	guiAspectRatio.AspectRatio = 440 / 300
	guiAspectRatio.Parent = frame

	local mainCorner = Instance.new("UICorner")
	mainCorner.CornerRadius = UDim.new(0, 12)
	mainCorner.Parent = frame

	local gradient = Instance.new("Frame")
	gradient.Name = "Gradient"
	gradient.Size = UDim2.new(1, 0, 1, 0)
	gradient.BackgroundTransparency = 1
	gradient.ZIndex = 2
	gradient.Parent = frame

	local gradientCorner = Instance.new("UICorner")
	gradientCorner.CornerRadius = UDim.new(0, 12)
	gradientCorner.Parent = gradient

	local gradientUI = Instance.new("UIGradient")
	gradientUI.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.fromRGB(25, 25, 25)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(18, 18, 18))
	}
	gradientUI.Rotation = 135
	gradientUI.Parent = gradient

	local borderStroke = Instance.new("UIStroke")
	borderStroke.Color = Color3.fromRGB(35, 35, 35)
	borderStroke.Thickness = 1
	borderStroke.Transparency = 0.5
	borderStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	borderStroke.Parent = frame

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "TitleLabel"
	titleLabel.Size = UDim2.new(1, -48, 0, 32)
	titleLabel.Position = UDim2.new(0, 24, 0, 24)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = "Redeem Code"
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextSize = 22
	titleLabel.TextColor3 = Color3.fromRGB(245, 245, 245)
	titleLabel.TextXAlignment = Enum.TextXAlignment.Center
	titleLabel.ZIndex = 3
	titleLabel.Parent = frame

	local divider = Instance.new("Frame")
	divider.Name = "Divider"
	divider.Size = UDim2.new(1, -48, 0, 1)
	divider.Position = UDim2.new(0, 24, 0, 68)
	divider.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
	divider.BorderSizePixel = 0
	divider.ZIndex = 3
	divider.Parent = frame

	local inputLabel = Instance.new("TextLabel")
	inputLabel.Name = "InputLabel"
	inputLabel.Size = UDim2.new(1, -48, 0, 18)
	inputLabel.Position = UDim2.new(0, 24, 0, 84)
	inputLabel.BackgroundTransparency = 1
	inputLabel.Text = "CODE"
	inputLabel.Font = Enum.Font.GothamBold
	inputLabel.TextSize = 11
	inputLabel.TextColor3 = Color3.fromRGB(120, 120, 120)
	inputLabel.TextXAlignment = Enum.TextXAlignment.Left
	inputLabel.ZIndex = 3
	inputLabel.Parent = frame

	local inputContainer = Instance.new("Frame")
	inputContainer.Name = "InputContainer"
	inputContainer.Size = UDim2.new(1, -48, 0, 52)
	inputContainer.Position = UDim2.new(0, 24, 0, 108)
	inputContainer.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
	inputContainer.BorderSizePixel = 0
	inputContainer.ZIndex = 3
	inputContainer.Parent = frame

	local inputCorner = Instance.new("UICorner")
	inputCorner.CornerRadius = UDim.new(0, 8)
	inputCorner.Parent = inputContainer

	local inputStroke = Instance.new("UIStroke")
	inputStroke.Color = Color3.fromRGB(40, 40, 40)
	inputStroke.Thickness = 1.5
	inputStroke.Transparency = 0.5
	inputStroke.Parent = inputContainer

	local codeInput = Instance.new("TextBox")
	codeInput.Name = "CodeInput"
	codeInput.Size = UDim2.new(1, -24, 1, 0)
	codeInput.Position = UDim2.new(0, 12, 0, 0)
	codeInput.BackgroundTransparency = 1
	codeInput.Text = ""
	codeInput.PlaceholderText = "XXXXXXXXXX"
	codeInput.Font = Enum.Font.GothamMedium
	codeInput.TextSize = 15
	codeInput.TextColor3 = Color3.fromRGB(235, 235, 235)
	codeInput.PlaceholderColor3 = Color3.fromRGB(80, 80, 80)
	codeInput.TextXAlignment = Enum.TextXAlignment.Left
	codeInput.ClearTextOnFocus = false
	codeInput.ZIndex = 4
	codeInput.Parent = inputContainer

	local statusLabel = Instance.new("TextLabel")
	statusLabel.Name = "StatusLabel"
	statusLabel.Size = UDim2.new(1, -48, 0, 20)
	statusLabel.Position = UDim2.new(0, 24, 0, 170)
	statusLabel.BackgroundTransparency = 1
	statusLabel.Text = ""
	statusLabel.Font = Enum.Font.Gotham
	statusLabel.TextSize = 11
	statusLabel.TextColor3 = Color3.fromRGB(231, 76, 60)
	statusLabel.TextXAlignment = Enum.TextXAlignment.Center
	statusLabel.TextYAlignment = Enum.TextYAlignment.Center
	statusLabel.Visible = false
	statusLabel.ZIndex = 3
	statusLabel.Parent = frame

	local redeemButton = Instance.new("TextButton")
	redeemButton.Name = "RedeemButton"
	redeemButton.Size = UDim2.new(1, -48, 0, 48)
	redeemButton.Position = UDim2.new(0, 24, 0, 200)
	redeemButton.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
	redeemButton.BorderSizePixel = 0
	redeemButton.Text = "Redeem Code"
	redeemButton.Font = Enum.Font.GothamBold
	redeemButton.TextSize = 14
	redeemButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	redeemButton.AutoButtonColor = false
	redeemButton.ZIndex = 3
	redeemButton.Parent = frame

	local buttonCorner = Instance.new("UICorner")
	buttonCorner.CornerRadius = UDim.new(0, 8)
	buttonCorner.Parent = redeemButton

	local buttonGradient = Instance.new("UIGradient")
	buttonGradient.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.fromRGB(46, 204, 113)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(39, 174, 96))
	}
	buttonGradient.Rotation = 90
	buttonGradient.Parent = redeemButton

	local cancelButton = Instance.new("TextButton")
	cancelButton.Name = "CancelButton"
	cancelButton.Size = UDim2.new(1, -48, 0, 32)
	cancelButton.Position = UDim2.new(0, 24, 0, 256)
	cancelButton.BackgroundTransparency = 1
	cancelButton.Text = "Close"
	cancelButton.Font = Enum.Font.GothamMedium
	cancelButton.TextSize = 12
	cancelButton.TextColor3 = Color3.fromRGB(120, 120, 120)
	cancelButton.AutoButtonColor = false
	cancelButton.ZIndex = 3
	cancelButton.Parent = frame

	local debounce = false

	redeemButton.MouseEnter:Connect(function()
		redeemButton.BackgroundColor3 = Color3.fromRGB(52, 224, 125)
		TweenService:Create(redeemButton, TweenInfo.new(0.15), {Size = UDim2.new(1, -44, 0, 48)}):Play()
	end)

	redeemButton.MouseLeave:Connect(function()
		redeemButton.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
		TweenService:Create(redeemButton, TweenInfo.new(0.15), {Size = UDim2.new(1, -48, 0, 48)}):Play()
	end)

	cancelButton.MouseEnter:Connect(function()
		cancelButton.TextColor3 = Color3.fromRGB(180, 180, 180)
	end)

	cancelButton.MouseLeave:Connect(function()
		cancelButton.TextColor3 = Color3.fromRGB(120, 120, 120)
	end)

	codeInput.Focused:Connect(function()
		inputStroke.Color = Color3.fromRGB(46, 204, 113)
		inputStroke.Thickness = 2
		inputStroke.Transparency = 0
	end)

	codeInput.FocusLost:Connect(function()
		inputStroke.Color = Color3.fromRGB(40, 40, 40)
		inputStroke.Thickness = 1.5
		inputStroke.Transparency = 0.5
	end)

	local function showStatus(message, color)
		statusLabel.Text = message
		statusLabel.TextColor3 = color
		statusLabel.Visible = true
		task.delay(3, function()
			statusLabel.Visible = false
		end)
	end

	redeemButton.MouseButton1Click:Connect(function()
		if debounce then return end
		
		local code = codeInput.Text:gsub("%s+", "")
		
		if code == "" then
			showStatus("Please enter a code", Color3.fromRGB(231, 76, 60))
			return
		end
		
		debounce = true
		redeemButton.Text = "Redeeming..."
		
		local success, result = pcall(function()
			return redeemRemote:InvokeServer(code)
		end)
		
		task.wait(1)
		
		if success then
			if result.Success then
				showStatus(result.Message, Color3.fromRGB(46, 204, 113))
				codeInput.Text = ""
			else
				showStatus(result.Message, Color3.fromRGB(231, 76, 60))
			end
		else
			showStatus("An error occurred", Color3.fromRGB(231, 76, 60))
		end
		
		redeemButton.Text = "Redeem Code"
		debounce = false
	end)

	cancelButton.MouseButton1Click:Connect(function()
		TweenService:Create(frame, TweenInfo.new(0.2), {Size = UDim2.new(0, 0, 0, 0)}):Play()
		task.wait(0.2)
		frame.Visible = false
		frame.Size = UDim2.new(0, 440, 0, 300)
		isGuiOpen = false
	end)

	local dragging = false
	local dragInput, dragStart, startPos

	local function update(input)
		local delta = input.Position - dragStart
		frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end

	frame.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = frame.Position
			
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)

	frame.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end)

	game:GetService("UserInputService").InputChanged:Connect(function(input)
		if input == dragInput and dragging then
			update(input)
		end
	end)
	
	return gui, frame
end

local function toggleGui()
	if isGuiOpen then
		TweenService:Create(mainFrame, TweenInfo.new(0.2), {Size = UDim2.new(0, 0, 0, 0)}):Play()
		task.wait(0.2)
		mainFrame.Visible = false
		mainFrame.Size = UDim2.new(0, 440, 0, 300)
		isGuiOpen = false
	else
		mainFrame.Visible = true
		mainFrame.Size = UDim2.new(0, 0, 0, 0)
		TweenService:Create(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0, 440, 0, 300)}):Play()
		isGuiOpen = true
	end
end

local function setup()
	if screenGui then
		screenGui:Destroy()
	end
	if toggleButton and toggleButton.Parent then
		toggleButton.Parent:Destroy()
	end
	
	isGuiOpen = false
	
	local buttonGui, button = createToggleButton()
	toggleButton = button
	
	screenGui, mainFrame = createRedeemGui()
	
	toggleButton.MouseButton1Click:Connect(function()
		toggleGui()
	end)
end

setup()

player.CharacterAdded:Connect(function()
	task.wait(0.1)
	setup()
end)