local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")

local inventoryDataStore = DataStoreService:GetDataStore("PlayerInventoryData_V1")
local toolsFolder = ServerStorage:WaitForChild("Tools")
local saveDebounces = {}

local function saveInventory(player)
	if not player or not player:IsDescendantOf(Players) then return end

	local toolNames = {}
	local backpack = player:FindFirstChild("Backpack")
	local character = player.Character

	if backpack then
		for _, item in ipairs(backpack:GetChildren()) do
			if item:IsA("Tool") then
				table.insert(toolNames, item.Name)
			end
		end
	end

	if character then
		for _, item in ipairs(character:GetChildren()) do
			if item:IsA("Tool") then
				table.insert(toolNames, item.Name)
			end
		end
	end

	pcall(function()
		inventoryDataStore:SetAsync(tostring(player.UserId), toolNames)
	end)
end

local function queueSave(player)
	if saveDebounces[player.UserId] then return end
	saveDebounces[player.UserId] = true

	task.delay(5, function()
		saveInventory(player)
		saveDebounces[player.UserId] = false
	end)
end

local function loadInventory(player)
	local success, savedTools = pcall(function()
		return inventoryDataStore:GetAsync(tostring(player.UserId))
	end)

	if success and savedTools and type(savedTools) == "table" then
		for _, toolName in ipairs(savedTools) do
			local foundTool = toolsFolder:FindFirstChild(toolName)
			if foundTool then
				foundTool:Clone().Parent = player:WaitForChild("Backpack")
			end
		end
	end
end

local function setupConnections(player)
	local backpack = player:WaitForChild("Backpack")
	
	backpack.ChildAdded:Connect(function() queueSave(player) end)
	backpack.ChildRemoved:Connect(function() queueSave(player) end)

	player.CharacterAdded:Connect(function(character)
		character.ChildAdded:Connect(function(child)
			if child:IsA("Tool") then queueSave(player) end
		end)
		character.ChildRemoved:Connect(function(child)
			if child:IsA("Tool") then queueSave(player) end
		end)
	end)
end

Players.PlayerAdded:Connect(function(player)
	loadInventory(player)
	setupConnections(player)
end)

Players.PlayerRemoving:Connect(function(player)
	saveInventory(player)
	saveDebounces[player.UserId] = nil
end)

game:BindToClose(function()
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(saveInventory, player)
	end
	task.wait(2)
end)