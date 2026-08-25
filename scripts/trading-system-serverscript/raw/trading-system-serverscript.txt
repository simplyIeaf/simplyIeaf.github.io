local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local remote = ReplicatedStorage:FindFirstChild("TradeRemote") or Instance.new("RemoteEvent")
remote.Name = "TradeRemote"
remote.Parent = ReplicatedStorage

local tradeSessions = {}
local playerCooldowns = {}
local DEBOUNCE_TIME = 0.15

local function getSession(player)
	for key, session in pairs(tradeSessions) do
		if session.Player1 == player or session.Player2 == player then
			return session, key
		end
	end
	return nil, nil
end

local function cleanSession(session, key)
	if not session then return end
	
	if session.TimerJob then
		task.cancel(session.TimerJob)
		session.TimerJob = nil
	end
	
	if session.Player1 and session.Player1.Parent then
		session.Player1:SetAttribute("Trading", false)
		task.defer(function()
			pcall(function()
				remote:FireClient(session.Player1, "Close")
			end)
		end)
	end
	
	if session.Player2 and session.Player2.Parent then
		session.Player2:SetAttribute("Trading", false)
		task.defer(function()
			pcall(function()
				remote:FireClient(session.Player2, "Close")
			end)
		end)
	end
	
	tradeSessions[key] = nil
end

local function syncOffers(session)
	if not session or not session.Player1 or not session.Player2 then return end
	if not session.Player1.Parent or not session.Player2.Parent then return end
	
	local p1Data, p2Data = {}, {}
	
	local p1Backpack = session.Player1:FindFirstChild("Backpack")
	local p2Backpack = session.Player2:FindFirstChild("Backpack")
	
	if not p1Backpack or not p2Backpack then return end
	
	for i = #session.P1Offer, 1, -1 do
		local item = session.P1Offer[i]
		if item and item:IsA("Tool") and item.Parent == p1Backpack then
			table.insert(p1Data, {Name = item.Name, Texture = item.TextureId})
		else
			table.remove(session.P1Offer, i)
		end
	end
	
	for i = #session.P2Offer, 1, -1 do
		local item = session.P2Offer[i]
		if item and item:IsA("Tool") and item.Parent == p2Backpack then
			table.insert(p2Data, {Name = item.Name, Texture = item.TextureId})
		else
			table.remove(session.P2Offer, i)
		end
	end
	
	task.spawn(function()
		pcall(function()
			remote:FireClient(session.Player1, "UpdateView", p1Data, p2Data)
		end)
	end)
	
	task.spawn(function()
		pcall(function()
			remote:FireClient(session.Player2, "UpdateView", p2Data, p1Data)
		end)
	end)
end

local function stopTimer(session)
	if session.TimerJob then
		task.cancel(session.TimerJob)
		session.TimerJob = nil
	end
	
	if session.Player1 and session.Player1.Parent then
		task.defer(function()
			pcall(function()
				remote:FireClient(session.Player1, "HideTimer")
			end)
		end)
	end
	
	if session.Player2 and session.Player2.Parent then
		task.defer(function()
			pcall(function()
				remote:FireClient(session.Player2, "HideTimer")
			end)
		end)
	end
end

local function startTimer(session)
	if session.TimerJob then return end
	if not session.Player1 or not session.Player2 then return end
	if not session.Player1.Parent or not session.Player2.Parent then return end
	
	session.TimerJob = task.spawn(function()
		for i = 5, 1, -1 do
			if not session.Player1 or not session.Player2 then return end
			if not session.Player1.Parent or not session.Player2.Parent then return end
			
			task.spawn(function()
				pcall(function()
					remote:FireClient(session.Player1, "TimerUpdate", i)
				end)
			end)
			task.spawn(function()
				pcall(function()
					remote:FireClient(session.Player2, "TimerUpdate", i)
				end)
			end)
			task.wait(1)
		end
		
		if not session.Player1 or not session.Player2 then return end
		if not session.Player1.Parent or not session.Player2.Parent then return end
		
		task.spawn(function()
			pcall(function()
				remote:FireClient(session.Player1, "TimerUpdate", 0)
			end)
		end)
		task.spawn(function()
			pcall(function()
				remote:FireClient(session.Player2, "TimerUpdate", 0)
			end)
		end)
		
		task.wait(0.5)
		
		local p1Backpack = session.Player1:FindFirstChild("Backpack")
		local p2Backpack = session.Player2:FindFirstChild("Backpack")
		local p1Char = session.Player1.Character
		local p2Char = session.Player2.Character
		
		if not p1Backpack or not p2Backpack then
			local key = session.Player1.UserId.."-"..session.Player2.UserId
			cleanSession(session, key)
			return
		end
		
		local p1ItemsToTrade = {}
		local p2ItemsToTrade = {}
		
		for _, item in ipairs(session.P1Offer) do
			if item and item:IsA("Tool") and item.Parent and (item.Parent == p1Backpack or (p1Char and item.Parent == p1Char)) then
				table.insert(p1ItemsToTrade, item)
			end
		end
		
		for _, item in ipairs(session.P2Offer) do
			if item and item:IsA("Tool") and item.Parent and (item.Parent == p2Backpack or (p2Char and item.Parent == p2Char)) then
				table.insert(p2ItemsToTrade, item)
			end
		end
		
		local function unequipPlayerTools(char, itemsToCheck)
			if not char then return end
			local humanoid = char:FindFirstChildOfClass("Humanoid")
			if not humanoid then return end
			
			for _, tool in ipairs(char:GetChildren()) do
				if tool:IsA("Tool") and table.find(itemsToCheck, tool) then
					pcall(function()
						humanoid:UnequipTools()
					end)
					break
				end
			end
		end
		
		unequipPlayerTools(p1Char, p1ItemsToTrade)
		unequipPlayerTools(p2Char, p2ItemsToTrade)
		
		task.wait(0.15)
		
		for _, item in ipairs(p1ItemsToTrade) do
			task.defer(function()
				if item and item:IsA("Tool") and item.Parent then
					local success = pcall(function()
						item.Parent = p2Backpack
					end)
					if not success then
						warn("Failed to transfer item from Player1 to Player2:", item.Name)
					end
				end
			end)
		end
		
		for _, item in ipairs(p2ItemsToTrade) do
			task.defer(function()
				if item and item:IsA("Tool") and item.Parent then
					local success = pcall(function()
						item.Parent = p1Backpack
					end)
					if not success then
						warn("Failed to transfer item from Player2 to Player1:", item.Name)
					end
				end
			end)
		end
		
		task.wait(0.3)
		
		local key = session.Player1.UserId.."-"..session.Player2.UserId
		cleanSession(session, key)
	end)
end

remote.OnServerEvent:Connect(function(player, action, data)
	if not player or not player.Parent then return end
	
	local currentTime = tick()
	local lastAction = playerCooldowns[player.UserId] or 0
	if currentTime - lastAction < DEBOUNCE_TIME then return end
	playerCooldowns[player.UserId] = currentTime

	if action == "Request" then
		local target = data
		if not target or not target:IsA("Player") or target == player then return end
		if not target.Parent then return end
		if not player.Character or not target.Character then return end
		
		local pRoot = player.Character:FindFirstChild("HumanoidRootPart")
		local tRoot = target.Character:FindFirstChild("HumanoidRootPart")
		if not pRoot or not tRoot then return end
		
		local dist = (pRoot.Position - tRoot.Position).Magnitude
		if dist <= 15 and not target:GetAttribute("Trading") and not player:GetAttribute("Trading") then
			task.defer(function()
				pcall(function()
					remote:FireClient(target, "Prompt", player)
				end)
			end)
		end

	elseif action == "AcceptRequest" then
		local requester = data
		if not requester or not requester:IsA("Player") then return end
		if not requester.Parent then return end
		if requester:GetAttribute("Trading") or player:GetAttribute("Trading") then return end
		
		local key = requester.UserId .. "-" .. player.UserId
		player:SetAttribute("Trading", true)
		requester:SetAttribute("Trading", true)
		
		tradeSessions[key] = {
			Player1 = requester,
			Player2 = player,
			P1Offer = {},
			P2Offer = {},
			P1Ready = false,
			P2Ready = false,
			TimerJob = nil
		}
		
		task.spawn(function()
			pcall(function()
				remote:FireClient(requester, "StartSession", player)
			end)
		end)
		
		task.spawn(function()
			pcall(function()
				remote:FireClient(player, "StartSession", requester)
			end)
		end)

	elseif action == "DeclineRequest" then
		if data and data:IsA("Player") and data.Parent then
			task.defer(function()
				pcall(function()
					remote:FireClient(data, "RequestDeclined")
				end)
			end)
		end

	elseif action == "ToggleItem" then
		local session, _ = getSession(player)
		if not session then return end
		
		if session.P1Ready or session.P2Ready then return end
		
		local item = data
		if not item or not item:IsA("Tool") then return end
		if item.Parent ~= player.Backpack then return end
		
		local isP1 = (session.Player1 == player)
		local offer = isP1 and session.P1Offer or session.P2Offer
		
		local index = table.find(offer, item)
		if index then
			table.remove(offer, index)
		else
			table.insert(offer, item)
		end
		
		syncOffers(session)

	elseif action == "ToggleReady" then
		local session, _ = getSession(player)
		if not session then return end
		
		local isP1 = (session.Player1 == player)
		
		if isP1 then
			session.P1Ready = not session.P1Ready
		else
			session.P2Ready = not session.P2Ready
		end
		
		pcall(function()
			remote:FireClient(session.Player1, "UpdateStatus", session.P1Ready)
		end)
		
		pcall(function()
			remote:FireClient(session.Player2, "UpdateStatus", session.P2Ready)
		end)
		
		if session.P1Ready and session.P2Ready then
			startTimer(session)
		else
			stopTimer(session)
		end

	elseif action == "Cancel" then
		local session, key = getSession(player)
		if session then
			cleanSession(session, key)
		end
	end
end)

Players.PlayerRemoving:Connect(function(player)
	local session, key = getSession(player)
	if session then
		cleanSession(session, key)
	end
	playerCooldowns[player.UserId] = nil
end)