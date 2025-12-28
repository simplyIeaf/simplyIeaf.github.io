-- test

local Players = game:GetService("Players")
local PhysicsService = game:GetService("PhysicsService")

local PLAYER_GROUP = "PlayersNoCollide"

local ENABLE_TRANSPARENCY = false
local AFK_TRANSPARENCY = 0.5
local ENABLE_PLAYER_COLLISION = false

local afkData = {}

local success, err = pcall(function()
	PhysicsService:RegisterCollisionGroup(PLAYER_GROUP)
	PhysicsService:CollisionGroupSetCollidable(PLAYER_GROUP, PLAYER_GROUP, ENABLE_PLAYER_COLLISION)
	PhysicsService:CollisionGroupSetCollidable(PLAYER_GROUP, "Default", true)
end)

if not success then
	warn("Failed to setup collision groups: " .. tostring(err))
end

local function formatTime(seconds)
	local minutes = math.floor(seconds / 60)
	local remainingSeconds = seconds % 60
	return string.format("%02d:%02d", minutes, remainingSeconds)
end

local function setCollisionGroup(character, groupName)
	for _, part in ipairs(character:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CollisionGroup = groupName
		end
	end
end

local function setTransparency(character, transparency)
	if not ENABLE_TRANSPARENCY then return end
	
	for _, part in ipairs(character:GetDescendants()) do
		if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
			if transparency > 0 and not part:GetAttribute("OriginalTransparency") then
				part:SetAttribute("OriginalTransparency", part.Transparency)
			end
			
			if transparency > 0 then
				local original = part:GetAttribute("OriginalTransparency") or 0
				part.Transparency = math.max(original, transparency)
			else
				part.Transparency = part:GetAttribute("OriginalTransparency") or 0
				part:SetAttribute("OriginalTransparency", nil)
			end
		elseif part:IsA("Decal") then
			if transparency > 0 and not part:GetAttribute("OriginalTransparency") then
				part:SetAttribute("OriginalTransparency", part.Transparency)
			end
			
			if transparency > 0 then
				part.Transparency = transparency
			else
				part.Transparency = part:GetAttribute("OriginalTransparency") or 0
				part:SetAttribute("OriginalTransparency", nil)
			end
		end
	end
	
	local humanoid = character:FindFirstChild("Humanoid")
	if humanoid then
		for _, accessory in ipairs(humanoid:GetAccessories()) do
			local handle = accessory:FindFirstChild("Handle")
			if handle then
				if transparency > 0 and not handle:GetAttribute("OriginalTransparency") then
					handle:SetAttribute("OriginalTransparency", handle.Transparency)
				end
				
				if transparency > 0 then
					local original = handle:GetAttribute("OriginalTransparency") or 0
					handle.Transparency = math.max(original, transparency)
				else
					handle.Transparency = handle:GetAttribute("OriginalTransparency") or 0
					handle:SetAttribute("OriginalTransparency", nil)
				end
			end
		end
	end
end

local function toggleAfk(player)
	local character = player.Character
	if not character then return end
	
	local humanoid = character:FindFirstChild("Humanoid")
	local head = character:FindFirstChild("Head")
	
	if not humanoid or not head then return end

	if afkData[player.UserId] then
		afkData[player.UserId] = nil
		
		humanoid.WalkSpeed = 16
		humanoid.JumpPower = 50
		setTransparency(character, 0)
		
		local ff = character:FindFirstChild("AFK_ForceField")
		if ff then ff:Destroy() end
		
		local tag = character:FindFirstChild("NameTag")
		if tag then tag:Destroy() end
		
		setCollisionGroup(character, PLAYER_GROUP)
	else
		afkData[player.UserId] = os.time()
		
		humanoid.WalkSpeed = 0
		humanoid.JumpPower = 0
		setTransparency(character, AFK_TRANSPARENCY)
		
		local ff = Instance.new("ForceField")
		ff.Name = "AFK_ForceField"
		ff.Visible = true
		ff.Parent = character
		
		setCollisionGroup(character, PLAYER_GROUP)

		local billboardGui = Instance.new("BillboardGui")
		billboardGui.Name = "NameTag"
		billboardGui.Adornee = head
		billboardGui.Size = UDim2.new(4, 0, 1, 0)
		billboardGui.StudsOffset = Vector3.new(0, 2, 0)
		billboardGui.AlwaysOnTop = true
		billboardGui.MaxDistance = 100
		billboardGui.LightInfluence = 0

		local frame = Instance.new("Frame")
		frame.Parent = billboardGui
		frame.Size = UDim2.new(1, 0, 1, 0)
		frame.Position = UDim2.new(0, 0, 0, 0)
		frame.BackgroundTransparency = 1
		frame.BorderSizePixel = 0

		local textLabel = Instance.new("TextLabel")
		textLabel.Parent = frame
		textLabel.Size = UDim2.new(1, -10, 1, 0)
		textLabel.Position = UDim2.new(0, 5, 0, 0)
		textLabel.BackgroundTransparency = 1
		textLabel.Text = "AFK - 00:00"
		textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		textLabel.TextSize = 20
		textLabel.TextScaled = true
		textLabel.Font = Enum.Font.GothamBold

		local textStroke = Instance.new("UIStroke")
		textStroke.Parent = textLabel
		textStroke.Color = Color3.fromRGB(0, 0, 0)
		textStroke.Transparency = 0
		textStroke.Thickness = 2

		local textSizeConstraint = Instance.new("UITextSizeConstraint")
		textSizeConstraint.Parent = textLabel
		textSizeConstraint.MaxTextSize = 20
		textSizeConstraint.MinTextSize = 8

		billboardGui.Parent = character

		task.spawn(function()
			while afkData[player.UserId] and character.Parent do
				local elapsed = os.time() - afkData[player.UserId]
				textLabel.Text = "AFK - " .. formatTime(elapsed)
				task.wait(1)
			end
		end)
	end
end

local function applyInitialPlayerCollision(character)
	local success, rootPart = pcall(function()
		return character:WaitForChild("HumanoidRootPart", 5)
	end)

	if success and rootPart then
		task.wait(0.5) 
		setCollisionGroup(character, PLAYER_GROUP)
	end
end

Players.PlayerAdded:Connect(function(player)
	player.Chatted:Connect(function(message)
		if message:lower() == "/toggleafk" then
			toggleAfk(player)
		end
	end)
	
	player.CharacterAdded:Connect(function(character)
		applyInitialPlayerCollision(character)
	end)

	player.CharacterRemoving:Connect(function()
		afkData[player.UserId] = nil
	end)
end)