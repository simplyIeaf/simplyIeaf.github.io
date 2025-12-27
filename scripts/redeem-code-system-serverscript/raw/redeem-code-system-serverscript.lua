local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local RedeemDataStore = DataStoreService:GetDataStore("RedeemedCodes_v1")

local CODES = {
	["LAUNCH2025"] = {Stat = "Coins", Amount = 1000}
}

local redeemRemote = Instance.new("RemoteFunction")
redeemRemote.Name = "RedeemCode"
redeemRemote.Parent = ReplicatedStorage

local processingPlayers = {}

local function getRedeemedCodes(userId)
	local success, result = pcall(function()
		return RedeemDataStore:GetAsync("Player_" .. userId)
	end)
	
	if success and result then
		return result
	end
	return {}
end

local function saveRedeemedCode(userId, code)
	local success, result = pcall(function()
		local redeemed = getRedeemedCodes(userId)
		table.insert(redeemed, code)
		RedeemDataStore:SetAsync("Player_" .. userId, redeemed)
		return true
	end)
	
	return success
end

local function hasRedeemedCode(userId, code)
	local redeemed = getRedeemedCodes(userId)
	for _, redeemedCode in pairs(redeemed) do
		if redeemedCode == code then
			return true
		end
	end
	return false
end

local function awardReward(player, statName, amount)
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		return false, "Leaderstats not found"
	end
	
	local stat = leaderstats:FindFirstChild(statName)
	if not stat then
		return false, "Stat '" .. statName .. "' not found"
	end
	
	if typeof(stat.Value) ~= "number" then
		return false, "Invalid stat type"
	end
	
	stat.Value = stat.Value + amount
	return true, "Successfully redeemed!"
end

redeemRemote.OnServerInvoke = function(player, code)
	if not player or not player.Parent then
		return {Success = false, Message = "Invalid player"}
	end
	
	if typeof(code) ~= "string" then
		return {Success = false, Message = "Invalid code format"}
	end
	
	code = code:gsub("%s+", ""):upper()
	
	if code == "" or #code > 50 then
		return {Success = false, Message = "Invalid code"}
	end
	
	local userId = player.UserId
	
	if processingPlayers[userId] then
		return {Success = false, Message = "Please wait"}
	end
	
	processingPlayers[userId] = true
	
	task.spawn(function()
		task.wait(1)
		processingPlayers[userId] = nil
	end)
	
	if not CODES[code] then
		return {Success = false, Message = "Invalid code"}
	end
	
	if hasRedeemedCode(userId, code) then
		return {Success = false, Message = "Code already redeemed"}
	end
	
	local codeData = CODES[code]
	local success, message = awardReward(player, codeData.Stat, codeData.Amount)
	
	if not success then
		return {Success = false, Message = message}
	end
	
	local saved = saveRedeemedCode(userId, code)
	if not saved then
		local stat = player.leaderstats:FindFirstChild(codeData.Stat)
		if stat then
			stat.Value = stat.Value - codeData.Amount
		end
		return {Success = false, Message = "Failed to save progress"}
	end
	
	return {Success = true, Message = "Redeemed +" .. codeData.Amount .. " " .. codeData.Stat .. "!"}
end