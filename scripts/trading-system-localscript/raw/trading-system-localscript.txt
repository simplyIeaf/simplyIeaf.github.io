local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local remote = ReplicatedStorage:WaitForChild("TradeRemote")

local highlight = Instance.new("Highlight")
highlight.FillTransparency = 1
highlight.OutlineColor = Color3.new(0, 0, 0)
highlight.OutlineTransparency = 0
highlight.Parent = ReplicatedStorage

local currentTarget = nil
local isTrading = false
local tradeGui = nil
local debounce = false
local timerLocked = false

local function checkDebounce()
	if debounce then return false end
	debounce = true
	task.delay(0.15, function() debounce = false end)
	return true
end

local function createTradeGui(partner)
	if tradeGui then tradeGui:Destroy() end
	timerLocked = false
	
	local gui = Instance.new("ScreenGui")
	gui.Name = "ModernTrade"
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.Parent = player.PlayerGui
	tradeGui = gui

	local main = Instance.new("Frame")
	main.Size = UDim2.fromOffset(550, 350)
	main.AnchorPoint = Vector2.new(0.5, 0.5)
	main.Position = UDim2.fromScale(0.5, 0.5)
	main.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
	main.BorderSizePixel = 0
	main.Parent = gui
	
	local uic = Instance.new("UICorner")
	uic.CornerRadius = UDim.new(0, 10)
	uic.Parent = main
	
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(45, 45, 45)
	stroke.Thickness = 1
	stroke.Parent = main

	local topBar = Instance.new("Frame")
	topBar.Size = UDim2.new(1, 0, 0, 45)
	topBar.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
	topBar.BorderSizePixel = 0
	topBar.Parent = main
	Instance.new("UICorner", topBar).CornerRadius = UDim.new(0, 10)
	
	local title = Instance.new("TextLabel")
	title.Text = "Trading with " .. partner.Name
	title.Font = Enum.Font.GothamBold
	title.TextSize = 16
	title.TextColor3 = Color3.fromRGB(220, 220, 220)
	title.Size = UDim2.fromScale(1, 1)
	title.BackgroundTransparency = 1
	title.Parent = topBar

	local function makeContainer(pTitle, xPos)
		local frame = Instance.new("Frame")
		frame.Size = UDim2.new(0.46, 0, 0.65, 0)
		frame.Position = UDim2.new(xPos, 0, 0.18, 0)
		frame.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
		frame.Parent = main
		Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 6)
		Instance.new("UIStroke", frame).Color = Color3.fromRGB(40,40,40)
		
		local lbl = Instance.new("TextLabel")
		lbl.Text = pTitle
		lbl.Size = UDim2.new(1, 0, 0, 25)
		lbl.BackgroundTransparency = 1
		lbl.TextColor3 = Color3.fromRGB(150, 150, 150)
		lbl.Font = Enum.Font.Gotham
		lbl.TextSize = 12
		lbl.Parent = frame
		
		local scroll = Instance.new("ScrollingFrame")
		scroll.Size = UDim2.new(1, -10, 1, -30)
		scroll.Position = UDim2.new(0, 5, 0, 25)
		scroll.BackgroundTransparency = 1
		scroll.ScrollBarThickness = 2
		scroll.Parent = frame
		
		local grid = Instance.new("UIGridLayout")
		grid.CellSize = UDim2.new(0, 55, 0, 55)
		grid.CellPadding = UDim2.new(0, 5, 0, 5)
		grid.Parent = scroll
		
		return scroll
	end

	local myContainer = makeContainer("Your Offer", 0.02)
	local theirContainer = makeContainer(partner.Name.."'s Offer", 0.52)
	
	local statusOverlay = Instance.new("Frame")
	statusOverlay.Size = UDim2.fromScale(1, 1)
	statusOverlay.BackgroundTransparency = 1
	statusOverlay.Visible = false
	statusOverlay.ZIndex = 5
	statusOverlay.Parent = main
	
	local timerTxt = Instance.new("TextLabel")
	timerTxt.Size = UDim2.fromScale(1, 1)
	timerTxt.BackgroundTransparency = 0.3
	timerTxt.BackgroundColor3 = Color3.new(0,0,0)
	timerTxt.TextColor3 = Color3.fromRGB(255, 255, 255)
	timerTxt.TextSize = 48
	timerTxt.Font = Enum.Font.GothamBold
	timerTxt.Text = "5"
	timerTxt.Parent = statusOverlay
	Instance.new("UICorner", timerTxt).CornerRadius = UDim.new(0, 10)

	local readyBtn = Instance.new("TextButton")
	readyBtn.Size = UDim2.new(0.4, 0, 0, 40)
	readyBtn.Position = UDim2.new(0.05, 0, 0.86, 0)
	readyBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	readyBtn.Text = "Ready"
	readyBtn.Font = Enum.Font.GothamBold
	readyBtn.TextColor3 = Color3.new(1,1,1)
	readyBtn.TextSize = 14
	readyBtn.Parent = main
	Instance.new("UICorner", readyBtn).CornerRadius = UDim.new(0, 6)
	
	local cancelBtn = Instance.new("TextButton")
	cancelBtn.Size = UDim2.new(0.4, 0, 0, 40)
	cancelBtn.Position = UDim2.new(0.55, 0, 0.86, 0)
	cancelBtn.BackgroundColor3 = Color3.fromRGB(150, 40, 40)
	cancelBtn.Text = "Cancel"
	cancelBtn.Font = Enum.Font.GothamBold
	cancelBtn.TextColor3 = Color3.new(1,1,1)
	cancelBtn.TextSize = 14
	cancelBtn.Parent = main
	Instance.new("UICorner", cancelBtn).CornerRadius = UDim.new(0, 6)

	local myOfferedItems = {}
	local itemButtons = {}
	
	local function renderInventory()
		for _, v in pairs(myContainer:GetChildren()) do
			if v:IsA("GuiButton") then v:Destroy() end
		end
		
		table.clear(itemButtons)
		
		for _, tool in pairs(player.Backpack:GetChildren()) do
			if tool:IsA("Tool") then
				local btn = Instance.new("TextButton")
				btn.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
				btn.Text = ""
				btn.Parent = myContainer
				Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
				
				local icon = Instance.new("ImageLabel")
				icon.BackgroundTransparency = 1
				icon.Size = UDim2.fromScale(0.85, 0.85)
				icon.Position = UDim2.fromScale(0.075, 0.075)
				icon.Image = tool.TextureId ~= "" and tool.TextureId or "rbxasset://textures/ui/GuiImagePlaceholder.png"
				icon.Parent = btn
				
				itemButtons[tool] = btn
				
				if myOfferedItems[tool] then
					btn.BackgroundColor3 = Color3.fromRGB(0, 180, 80)
				end
				
				btn.MouseButton1Click:Connect(function()
					if not checkDebounce() then return end
					if timerLocked then return end
					
					if myOfferedItems[tool] then
						myOfferedItems[tool] = nil
						btn.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
					else
						myOfferedItems[tool] = true
						btn.BackgroundColor3 = Color3.fromRGB(0, 180, 80)
					end
					remote:FireServer("ToggleItem", tool)
				end)
			end
		end
	end
	
	renderInventory()
	
	readyBtn.MouseButton1Click:Connect(function()
		if not checkDebounce() then return end
		if timerLocked then return end
		remote:FireServer("ToggleReady")
	end)
	
	cancelBtn.MouseButton1Click:Connect(function()
		if not checkDebounce() then return end
		remote:FireServer("Cancel")
	end)
	
	return {
		GUI = gui,
		RenderInv = renderInventory,
		TheirContainer = theirContainer,
		ReadyBtn = readyBtn,
		Overlay = statusOverlay,
		TimerTxt = timerTxt,
		MyOfferedItems = myOfferedItems,
		ItemButtons = itemButtons,
		SetReadyVisual = function(isReady)
			if isReady then
				readyBtn.Text = "Unready"
				readyBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 80)
			else
				readyBtn.Text = "Ready"
				readyBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
			end
		end
	}
end

local activeSession = nil

RunService.RenderStepped:Connect(function()
	if isTrading then
		highlight.Adornee = nil
		currentTarget = nil
		return
	end
	
	if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
		highlight.Adornee = nil
		currentTarget = nil
		return
	end
	
	local closest, minDist = nil, 5
	for _, p in pairs(Players:GetPlayers()) do
		if p ~= player and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
			local d = (player.Character.HumanoidRootPart.Position - p.Character.HumanoidRootPart.Position).Magnitude
			if d < minDist then
				closest = p
				minDist = d
			end
		end
	end
	
	currentTarget = closest
	highlight.Adornee = closest and closest.Character or nil
end)

UserInputService.InputBegan:Connect(function(input, gpe)
	if gpe or isTrading or not currentTarget then return end
	if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
		if checkDebounce() then
			remote:FireServer("Request", currentTarget)
		end
	end
end)

remote.OnClientEvent:Connect(function(action, data, data2)
	if action == "Prompt" then
		local sg = Instance.new("ScreenGui")
		sg.ResetOnSpawn = false
		sg.Parent = player.PlayerGui
		
		local fr = Instance.new("Frame", sg)
		fr.Size = UDim2.fromOffset(250, 120)
		fr.Position = UDim2.fromScale(0.5, 0.5)
		fr.AnchorPoint = Vector2.new(0.5, 0.5)
		fr.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
		Instance.new("UICorner", fr).CornerRadius = UDim.new(0, 8)
		
		local txt = Instance.new("TextLabel", fr)
		txt.Text = data.Name .. " wants to trade!"
		txt.TextColor3 = Color3.new(1,1,1)
		txt.Size = UDim2.new(1,0,0.5,0)
		txt.BackgroundTransparency = 1
		txt.Font = Enum.Font.GothamBold
		txt.TextSize = 14
		
		local yBtn = Instance.new("TextButton", fr)
		yBtn.Text = "Accept"
		yBtn.Size = UDim2.new(0.4,0,0.3,0)
		yBtn.Position = UDim2.new(0.05,0,0.6,0)
		yBtn.BackgroundColor3 = Color3.fromRGB(0,150,0)
		yBtn.Font = Enum.Font.GothamBold
		yBtn.TextColor3 = Color3.new(1,1,1)
		yBtn.TextSize = 13
		Instance.new("UICorner", yBtn).CornerRadius = UDim.new(0,6)
		
		local nBtn = Instance.new("TextButton", fr)
		nBtn.Text = "Decline"
		nBtn.Size = UDim2.new(0.4,0,0.3,0)
		nBtn.Position = UDim2.new(0.55,0,0.6,0)
		nBtn.BackgroundColor3 = Color3.fromRGB(150,0,0)
		nBtn.Font = Enum.Font.GothamBold
		nBtn.TextColor3 = Color3.new(1,1,1)
		nBtn.TextSize = 13
		Instance.new("UICorner", nBtn).CornerRadius = UDim.new(0,6)
		
		yBtn.MouseButton1Click:Connect(function() 
			if sg then 
				sg:Destroy() 
				remote:FireServer("AcceptRequest", data) 
			end
		end)
		nBtn.MouseButton1Click:Connect(function() 
			if sg then 
				sg:Destroy() 
				remote:FireServer("DeclineRequest", data) 
			end
		end)
		
		task.delay(10, function() 
			if sg and sg.Parent then 
				sg:Destroy() 
			end 
		end)

	elseif action == "StartSession" then
		isTrading = true
		activeSession = createTradeGui(data)

	elseif action == "UpdateView" then
		if not activeSession then return end
		
		for _, c in pairs(activeSession.TheirContainer:GetChildren()) do
			if c:IsA("GuiButton") then c:Destroy() end
		end
		
		if data2 then
			for _, itemData in pairs(data2) do
				local btn = Instance.new("TextButton")
				btn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
				btn.Text = ""
				btn.AutoButtonColor = false
				btn.Parent = activeSession.TheirContainer
				Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
				
				local icon = Instance.new("ImageLabel")
				icon.BackgroundTransparency = 1
				icon.Size = UDim2.fromScale(0.85, 0.85)
				icon.Position = UDim2.fromScale(0.075, 0.075)
				icon.Image = itemData.Texture ~= "" and itemData.Texture or "rbxasset://textures/ui/GuiImagePlaceholder.png"
				icon.Parent = btn
			end
		end

	elseif action == "UpdateStatus" then
		if activeSession then
			activeSession.SetReadyVisual(data)
		end

	elseif action == "TimerUpdate" then
		if activeSession then
			activeSession.Overlay.Visible = true
			if data == 0 then
				timerLocked = true
				activeSession.TimerTxt.Text = "Processing..."
				activeSession.TimerTxt.TextSize = 32
			else
				activeSession.TimerTxt.Text = tostring(data)
				activeSession.TimerTxt.TextSize = 48
			end
		end
		
	elseif action == "HideTimer" then
		if activeSession then
			activeSession.Overlay.Visible = false
		end

	elseif action == "Close" then
		isTrading = false
		currentTarget = nil
		timerLocked = false
		if tradeGui then 
			tradeGui:Destroy() 
			tradeGui = nil
		end
		activeSession = nil
	end
end)