-- PUBLIC
-- Note : Put the localscript inside of StarterGui instead of StarterPlayerScripts

local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

local TEXT_CONFIG = {
	TypingSpeed = 0.05,
	ReadTime = 2,
	FadeTime = 0.5,
	InterTurnDelay = 0.5,
	Font = Enum.Font.GothamBold,
	TextSize = 18,
	TextColor = Color3.new(1, 1, 1),
	StrokeColor = Color3.new(0, 0, 0),
	StrokeTransparency = 0,
	HeightOffset = Vector3.new(0, 3, 0),
	MaxDistance = 100,
	BoxWidth = 250,
	BoxHeight = 50,
	OptionTimeout = 20,
	MaxConversationDistance = 30,
	InteractionDistance = 10,
	HeadRotationLimit = math.rad(70),
	TalkingFaceAssetId = 66330310,
	TypeSoundId = 9120300060
}

local NPCS = {
	["Poke"] = {
		TextContent = "Yo! What's up?",
		Responses = {
			{text = "Nothing much, I'm a big fan", response = "Just chilling here & thanks!"},
			{text = "Not much, you?", response = "Just chilling here."},
			{text = "Bye!", response = "See ya!"}
		},
		isPart = false
	}
}

local isDialogueActive = false
local currentTalkingNPC = nil
local distanceCheckConnection = nil
local activeHighlight = nil
local highlightedNPCName = nil
local defaultHeadCFrame = {}
local originalFaceTexture = {}

local function findNPCObject(npcName)
	return workspace:FindFirstChild(npcName)
end

local function getNPCParts(npcName, npcData)
	local npcObject = findNPCObject(npcName)
	if not npcObject then return nil, nil, nil end
	local rootPart, headPart
	if npcData.isPart and npcObject:IsA("BasePart") then
		rootPart = npcObject
		headPart = npcObject
	elseif not npcData.isPart and npcObject:IsA("Model") then
		rootPart = npcObject:FindFirstChild("HumanoidRootPart")
		headPart = npcObject:FindFirstChild("Head")
	end
	return rootPart, headPart, npcObject
end

local function cleanStartupMess()
	for npcName, npcData in pairs(NPCS) do
		local _, headPart, npcObject = getNPCParts(npcName, npcData)
		if npcObject then
			local oldHighlight = npcObject:FindFirstChild("Highlight")
			if oldHighlight then oldHighlight:Destroy() end
			
			if headPart then
				local oldBb = headPart:FindFirstChildOfClass("BillboardGui")
				if oldBb then oldBb:Destroy() end
			end
		end
	end
end

local function updateNPCHeadLook(npcName, targetPosition)
	local rootPart, headPart, npcObject = getNPCParts(npcName, NPCS[npcName])
	if not headPart or not rootPart then return end

	if not defaultHeadCFrame[npcName] then
		defaultHeadCFrame[npcName] = headPart.CFrame
	end

	if targetPosition then
		local distance = (targetPosition - headPart.Position).Magnitude
		if distance < 3.5 then return end

		local direction = (targetPosition - headPart.Position).Unit
		local lookVector = defaultHeadCFrame[npcName].LookVector
		local dot = direction:Dot(lookVector)

		if dot >= math.cos(TEXT_CONFIG.HeadRotationLimit) then
			local goalCFrame = CFrame.lookAt(headPart.Position, targetPosition)
			headPart.CFrame = headPart.CFrame:Lerp(goalCFrame, 0.15)
		else
			headPart.CFrame = headPart.CFrame:Lerp(defaultHeadCFrame[npcName], 0.1)
		end
	else
		headPart.CFrame = headPart.CFrame:Lerp(defaultHeadCFrame[npcName], 0.1)
	end
end

local function toggleNPCFace(npcName, isTalking)
	local _, headPart, _ = getNPCParts(npcName, NPCS[npcName])
	if not headPart then return end
	local face = headPart:FindFirstChildOfClass("Decal")
	if not face then return end
	if isTalking then
		if not originalFaceTexture[npcName] then
			originalFaceTexture[npcName] = face.Texture
		end
		face.Texture = string.format("rbxthumb://type=Asset&id=%d&w=420&h=420", TEXT_CONFIG.TalkingFaceAssetId)
	else
		if originalFaceTexture[npcName] then
			face.Texture = originalFaceTexture[npcName]
			originalFaceTexture[npcName] = nil
		end
	end
end

local function initializeNPCHead(npcName)
	local rootPart, headPart, npcObject = getNPCParts(npcName, NPCS[npcName])
	if not headPart or not rootPart then return end
	local neck = npcObject:FindFirstChild("Neck", true) or headPart:FindFirstChild("Neck")
	if neck then
		neck:Destroy()
	end
	headPart.Anchored = true
	if not defaultHeadCFrame[npcName] then
		defaultHeadCFrame[npcName] = headPart.CFrame
	end
end

local function cleanupConversation(screenGui)
	if distanceCheckConnection then
		distanceCheckConnection:Disconnect()
		distanceCheckConnection = nil
	end
	if screenGui then
		screenGui:Destroy()
	end
	if currentTalkingNPC then
		toggleNPCFace(currentTalkingNPC, false)
		updateNPCHeadLook(currentTalkingNPC, nil)
	end
	isDialogueActive = false
	currentTalkingNPC = nil
end

local function startDistanceCheck(npcPart, screenGui)
	if distanceCheckConnection then distanceCheckConnection:Disconnect() end
	distanceCheckConnection = RunService.Heartbeat:Connect(function()
		if not character or not character.Parent then
			cleanupConversation(screenGui)
			return
		end
		
		local currentRoot = character:FindFirstChild("HumanoidRootPart")
		if not currentRoot then return end

		local dist = (currentRoot.Position - npcPart.Position).Magnitude
		if dist > TEXT_CONFIG.MaxConversationDistance then
			cleanupConversation(screenGui)
		end
	end)
end

local function createFloatingText(part, text, callback, isNPC)
	if not part then 
		if callback then callback() end
		return 
	end
	if isNPC and currentTalkingNPC then
		toggleNPCFace(currentTalkingNPC, true)
	end
	local billboardGui = Instance.new("BillboardGui")
	billboardGui.Size = UDim2.new(0, TEXT_CONFIG.BoxWidth, 0, TEXT_CONFIG.BoxHeight)
	billboardGui.StudsOffset = TEXT_CONFIG.HeightOffset
	billboardGui.AlwaysOnTop = true
	billboardGui.Parent = part
	local textLabel = Instance.new("TextLabel")
	textLabel.Size = UDim2.new(1, 0, 1, 0)
	textLabel.BackgroundTransparency = 1
	textLabel.Text = ""
	textLabel.TextColor3 = TEXT_CONFIG.TextColor
	textLabel.TextStrokeTransparency = TEXT_CONFIG.StrokeTransparency
	textLabel.TextStrokeColor3 = TEXT_CONFIG.StrokeColor
	textLabel.Font = TEXT_CONFIG.Font
	textLabel.TextWrapped = true
	textLabel.TextSize = TEXT_CONFIG.TextSize
	textLabel.Parent = billboardGui
	local typeSound = Instance.new("Sound")
	typeSound.SoundId = "rbxassetid://" .. TEXT_CONFIG.TypeSoundId
	typeSound.Volume = 10
	typeSound.Parent = part
	
	task.spawn(function()
		local totalChars = #text
		for i = 1, totalChars do
			if not billboardGui or not billboardGui.Parent then break end
			textLabel.Text = string.sub(text, 1, i)
			typeSound:Play()
			task.wait(TEXT_CONFIG.TypingSpeed)
		end
		if isNPC and currentTalkingNPC then
			toggleNPCFace(currentTalkingNPC, false)
		end
		task.wait(TEXT_CONFIG.ReadTime)
		
		if billboardGui and billboardGui.Parent then
			local fadeOut = TweenService:Create(textLabel, TweenInfo.new(TEXT_CONFIG.FadeTime), {TextTransparency = 1, TextStrokeTransparency = 1})
			fadeOut:Play()
			fadeOut.Completed:Wait()
			billboardGui:Destroy()
			typeSound:Destroy()
		end
		
		if callback then callback() end
	end)
end

local function createResponseGui(responses, onOptionSelected, onTimeout)
	local playerGui = player:WaitForChild("PlayerGui")
	if playerGui:FindFirstChild("NPC_Dialogue_Screen") then
		playerGui.NPC_Dialogue_Screen:Destroy()
	end
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "NPC_Dialogue_Screen"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = playerGui
	
	local mainFrame = Instance.new("Frame")
	mainFrame.Size = UDim2.new(0, 250, 0, (#responses * 45) + 10)
	mainFrame.Position = UDim2.new(1.2, 0, 0.5, 0)
	mainFrame.AnchorPoint = Vector2.new(0, 0.5)
	mainFrame.BackgroundTransparency = 1
	mainFrame.Parent = screenGui
	
	local isSelected = false
	local buttons = {}
	for i, option in ipairs(responses) do
		local button = Instance.new("TextButton")
		button.Size = UDim2.new(1, 0, 0, 40)
		button.Position = UDim2.new(0, 0, 0, (i - 1) * 45)
		button.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
		button.BackgroundTransparency = 1
		button.TextTransparency = 1
		button.Text = option.text
		button.TextColor3 = Color3.new(1, 1, 1)
		button.Font = Enum.Font.GothamBold
		button.TextSize = 14
		button.Parent = mainFrame
		
		local uiCorner = Instance.new("UICorner")
		uiCorner.CornerRadius = UDim.new(0, 8)
		uiCorner.Parent = button
		
		button.MouseButton1Click:Connect(function()
			if isSelected then return end
			isSelected = true
			mainFrame:TweenPosition(UDim2.new(1.2, 0, 0.5, 0), "In", "Quad", 0.3, true, function()
				screenGui:Destroy()
			end)
			onOptionSelected(option.text, option.response)
		end)
		table.insert(buttons, button)
	end
	
	mainFrame:TweenPosition(UDim2.new(0.7, 0, 0.5, 0), "Out", "Quad", 0.3)
	task.spawn(function()
		task.wait(0.3)
		for _, btn in ipairs(buttons) do
			TweenService:Create(btn, TweenInfo.new(0.3), {BackgroundTransparency = 0.2, TextTransparency = 0}):Play()
		end
	end)
	
	task.delay(TEXT_CONFIG.OptionTimeout, function()
		if not isSelected and screenGui.Parent then
			cleanupConversation(screenGui)
			if onTimeout then onTimeout() end
		end
	end)
	return screenGui
end

local function updateLoop()
	if not character or not character.Parent then return end
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	local closestNPC = nil
	local shortestDist = TEXT_CONFIG.InteractionDistance

	if isDialogueActive and currentTalkingNPC then
		closestNPC = currentTalkingNPC
		local playerHead = character:FindFirstChild("Head")
		if playerHead then
			updateNPCHeadLook(currentTalkingNPC, playerHead.Position)
		end
	else
		for npcName, npcData in pairs(NPCS) do
			local targetPart, _, _ = getNPCParts(npcName, npcData)
			if targetPart then
				local dist = (hrp.Position - targetPart.Position).Magnitude
				if dist <= shortestDist then
					shortestDist = dist
					closestNPC = npcName
				end
			end
		end

		if closestNPC then
			local playerHead = character:FindFirstChild("Head")
			if playerHead then
				updateNPCHeadLook(closestNPC, playerHead.Position)
			end
		else
			for npcName, _ in pairs(NPCS) do
				updateNPCHeadLook(npcName, nil)
			end
		end
	end

	if closestNPC ~= highlightedNPCName then
		if activeHighlight then
			activeHighlight:Destroy()
			activeHighlight = nil
		end
		highlightedNPCName = nil

		if closestNPC then
			local _, _, npcObject = getNPCParts(closestNPC, NPCS[closestNPC])
			if npcObject then
				activeHighlight = Instance.new("Highlight")
				activeHighlight.FillTransparency = 1
				activeHighlight.OutlineColor = Color3.new(0, 0, 0)
				activeHighlight.OutlineTransparency = 0
				activeHighlight.Parent = npcObject
				highlightedNPCName = closestNPC
			end
		end
	end
end

cleanStartupMess()
for npcName, _ in pairs(NPCS) do
	initializeNPCHead(npcName)
end

RunService.Heartbeat:Connect(updateLoop)

local function processInput(inputPosition)
	if isDialogueActive then return end
	if not character or not character.Parent then return end
	
	local camera = workspace.CurrentCamera
	local ray = camera:ViewportPointToRay(inputPosition.X, inputPosition.Y)
	local result = workspace:Raycast(ray.Origin, ray.Direction * 1000)

	if result and result.Instance then
		local hitModel = result.Instance:FindFirstAncestorOfClass("Model")
		local hitPart = result.Instance
		
		if highlightedNPCName then
			local npcData = NPCS[highlightedNPCName]
			local rootPart, headPart, npcObject = getNPCParts(highlightedNPCName, npcData)
			local isMatch = false
			
			if npcData.isPart and (hitPart == npcObject) then
				isMatch = true
			elseif not npcData.isPart and (hitModel == npcObject) then
				isMatch = true
			end
			
			if isMatch and rootPart then
				if (character.HumanoidRootPart.Position - rootPart.Position).Magnitude <= TEXT_CONFIG.InteractionDistance then
					isDialogueActive = true
					currentTalkingNPC = highlightedNPCName
					createFloatingText(headPart, npcData.TextContent, function()
						local gui = createResponseGui(npcData.Responses, function(question, response)
							if distanceCheckConnection then distanceCheckConnection:Disconnect() end
							local playerHead = character:FindFirstChild("Head")
							createFloatingText(playerHead, question, function()
								task.wait(TEXT_CONFIG.InterTurnDelay)
								createFloatingText(headPart, response, function()
									cleanupConversation(nil)
								end, true)
							end, false)
						end, function()
							cleanupConversation(nil)
						end)
						startDistanceCheck(rootPart, gui)
					end, true)
				end
			end
		end
	end
end

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		local mousePos = UserInputService:GetMouseLocation()
		processInput(mousePos)
	end
end)