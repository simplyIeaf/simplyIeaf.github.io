local DATASTORE_NAME = "WinsLeaderboard1"
local MAX_ENTRIES = 10
local REFRESH_RATE = 20
local TITLE_TEXT = "Most Wins"
local CurrencyName = "Wins"
local MinimumRequirement = 1

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

local GlobalLeaderboardB = DataStoreService:GetOrderedDataStore(DATASTORE_NAME)
local RecentlySaved = {}

local surfaceGui = script.Parent

for _, child in ipairs(surfaceGui:GetChildren()) do
	if child ~= script then
		child:Destroy()
	end
end

local main = Instance.new("Frame")
main.Size = UDim2.new(1, 0, 1, 0)
main.BackgroundTransparency = 1
main.Parent = surfaceGui

local title = Instance.new("TextLabel")
title.Name = "Header"
title.Size = UDim2.new(1, 0, 0.15, 0)
title.BackgroundTransparency = 1
title.Text = TITLE_TEXT
title.Font = Enum.Font.FredokaOne
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextScaled = false
title.TextSize = 52
title.Parent = main

local titleStroke = Instance.new("UIStroke")
titleStroke.Color = Color3.fromRGB(0, 0, 0)
titleStroke.Thickness = 6
titleStroke.Parent = title

local list = Instance.new("ScrollingFrame")
list.Name = "List"
list.Size = UDim2.new(0.92, 0, 0.75, 0)
list.Position = UDim2.new(0.04, 0, 0.17, 0)
list.BackgroundTransparency = 1
list.BorderSizePixel = 0
list.ScrollBarThickness = 8
list.AutomaticCanvasSize = Enum.AutomaticSize.Y
list.CanvasSize = UDim2.new(0, 0, 0, 0)
list.Parent = main

local layout = Instance.new("UIListLayout")
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Padding = UDim.new(0, 8)
layout.Parent = list

local timerLabel = Instance.new("TextLabel")
timerLabel.Size = UDim2.new(1, 0, 0.06, 0)
timerLabel.Position = UDim2.new(0, 0, 0.93, 0)
timerLabel.BackgroundTransparency = 1
timerLabel.Font = Enum.Font.FredokaOne
timerLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
timerLabel.TextScaled = true
timerLabel.Text = "Updating in..."
timerLabel.Parent = main

local timerStroke = Instance.new("UIStroke")
timerStroke.Color = Color3.fromRGB(0, 0, 0)
timerStroke.Thickness = 2.5
timerStroke.Parent = timerLabel

local suffixes = {"", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc", "Ud", "Dd", "Td", "Qad", "Qid", "Sxd", "Spd", "Ocd", "Nod", "Vig"}

local function formatNumber(n)
	if not tonumber(n) then return n end
	if n < 1000 then return tostring(math.floor(n)) end
	local suffixIndex = math.floor(math.log10(n) / 3) + 1
	if suffixIndex > #suffixes then suffixIndex = #suffixes end
	local divisor = 10 ^ ((suffixIndex - 1) * 3)
	local formatted = string.format("%.1f", n / divisor)
	if formatted:sub(-2) == ".0" then
		formatted = formatted:sub(1, -3)
	end
	return formatted .. suffixes[suffixIndex]
end

local function addNewEntry(rank, user, val)
	local colorA = "e69900"
	local colorB = "ffffff"

	if rank == 1 then
		colorA = "d9a300"
		colorB = "ffce00"
	elseif rank == 2 then
		colorA = "a3d900"
		colorB = "ccff00"
	elseif rank == 3 then
		colorA = "e67e00"
		colorB = "ff9900"
	end

	local entry = Instance.new("Frame")
	entry.Size = UDim2.new(1, -12, 0, 65)
	entry.BackgroundColor3 = Color3.fromHex(colorB)
	entry.LayoutOrder = rank
	entry.Parent = list

	local border = Instance.new("UIStroke")
	border.Thickness = 3.5
	border.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	border.Parent = entry

	local rankSide = Instance.new("Frame")
	rankSide.Size = UDim2.new(0.18, 0, 1, 0)
	rankSide.BackgroundColor3 = Color3.fromHex(colorA)
	rankSide.BorderSizePixel = 0
	rankSide.Parent = entry

	local rankNum = Instance.new("TextLabel")
	rankNum.Size = UDim2.new(1, 0, 1, 0)
	rankNum.BackgroundTransparency = 1
	rankNum.Text = rank
	rankNum.Font = Enum.Font.FredokaOne
	rankNum.TextColor3 = Color3.new(1, 1, 1)
	rankNum.TextScaled = true
	rankNum.Parent = rankSide

	local rankStroke = Instance.new("UIStroke")
	rankStroke.Thickness = 3
	rankStroke.Parent = rankNum

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(0.5, 0, 0.6, 0)
	nameLabel.Position = UDim2.new(0.22, 0, 0.2, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = user
	nameLabel.Font = Enum.Font.FredokaOne
	nameLabel.TextColor3 = Color3.new(1, 1, 1)
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.TextScaled = true
	nameLabel.Parent = entry

	local nameStroke = Instance.new("UIStroke")
	nameStroke.Thickness = 2.5
	nameStroke.Parent = nameLabel

	local badge = Instance.new("Frame")
	badge.Size = UDim2.new(0.25, 0, 0.7, 0)
	badge.Position = UDim2.new(0.97, 0, 0.5, 0)
	badge.AnchorPoint = Vector2.new(1, 0.5)
	badge.BackgroundColor3 = Color3.fromRGB(130, 65, 0)
	badge.Parent = entry

	local bStroke = Instance.new("UIStroke")
	bStroke.Thickness = 3
	bStroke.Parent = badge

	local valLabel = Instance.new("TextLabel")
	valLabel.Size = UDim2.new(0.9, 0, 0.8, 0)
	valLabel.Position = UDim2.new(0.05, 0, 0.1, 0)
	valLabel.BackgroundTransparency = 1
	valLabel.Text = val
	valLabel.Font = Enum.Font.FredokaOne
	valLabel.TextColor3 = Color3.new(1, 1, 1)
	valLabel.TextScaled = true
	valLabel.Parent = badge
end

local leaderboardUpdating = false

local function updateLeaderboard()
	if leaderboardUpdating then return end
	leaderboardUpdating = true

	local success, err = pcall(function()
		local pages = GlobalLeaderboardB:GetSortedAsync(false, MAX_ENTRIES)
		local data = pages:GetCurrentPage()

		for _, child in ipairs(list:GetChildren()) do
			if child:IsA("Frame") then
				child:Destroy()
			end
		end

		for rank, entryInfo in ipairs(data) do
			local userId = entryInfo.key
			local value = entryInfo.value

			if value >= MinimumRequirement then
				local username = "Unknown"
				pcall(function()
					username = Players:GetNameFromUserIdAsync(userId)
				end)

				addNewEntry(rank, username, formatNumber(value))
			end
		end
	end)

	leaderboardUpdating = false

	if not success then
		warn(err)
	end
end

local function returncurrency(player)
	local x = 0
	for _, b in ipairs(player:GetDescendants()) do
		if (b:IsA("IntValue") or b:IsA("NumberValue")) and b.Name == CurrencyName then
			x = b.Value
			break
		end
	end
	return x
end

local function removefromrecentlysaved(playerName)
	for i, v in ipairs(RecentlySaved) do
		if v == playerName then
			table.remove(RecentlySaved, i)
			break
		end
	end
end

local function autoremoverecentsaved(playerName)
	task.spawn(function()
		task.wait(15)
		removefromrecentlysaved(playerName)
	end)
end

local function savePlayer(player)
	local amount = returncurrency(player)
	local success, err = pcall(function()
		GlobalLeaderboardB:SetAsync(player.UserId, amount)
	end)
	if not success then warn(err) end
end

local function saveAllPlayers()
	for _, player in ipairs(Players:GetPlayers()) do
		local pName = player.Name
		if not table.find(RecentlySaved, pName) then
			table.insert(RecentlySaved, pName)
			savePlayer(player)
			removefromrecentlysaved(pName)
		end
	end
end

local function connectPlayerSave(player)
	local leaderstats = player:WaitForChild("leaderstats")
	local wins = leaderstats:WaitForChild(CurrencyName)

	wins.Changed:Connect(function(newValue)
		local success, err = pcall(function()
			GlobalLeaderboardB:SetAsync(player.UserId, newValue)
		end)
		if success then
			updateLeaderboard()
		else
			warn(err)
		end
	end)
end

Players.PlayerAdded:Connect(function(player)
	connectPlayerSave(player)
end)

for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(connectPlayerSave, player)
end

Players.PlayerRemoving:Connect(function(player)
	local pName = player.Name
	if not table.find(RecentlySaved, pName) then
		table.insert(RecentlySaved, pName)
		savePlayer(player)
		removefromrecentlysaved(pName)
	end
end)

game:BindToClose(function()
	saveAllPlayers()
end)

task.spawn(function()
	while true do
		if #Players:GetPlayers() > 0 then
			for _, player in ipairs(Players:GetPlayers()) do
				local pName = player.Name
				if not table.find(RecentlySaved, pName) then
					table.insert(RecentlySaved, pName)
					savePlayer(player)
					autoremoverecentsaved(pName)
				end
			end
		end

		local success, pages = pcall(function()
			return GlobalLeaderboardB:GetSortedAsync(false, MAX_ENTRIES)
		end)

		if not success then
			warn(pages)
		end

		task.wait(REFRESH_RATE)
	end
end)

task.spawn(function()
	while true do
		updateLeaderboard()
		for i = REFRESH_RATE, 1, -1 do
			timerLabel.Text = "Updating in " .. i .. "s..."
			task.wait(1)
		end
	end
end)