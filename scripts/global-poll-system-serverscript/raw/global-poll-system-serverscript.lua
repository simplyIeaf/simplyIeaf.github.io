local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MessagingService = game:GetService("MessagingService")
local HttpService = game:GetService("HttpService")

local ADMIN_IDS = {1, 2}

local remotesFolder = Instance.new("Folder")
remotesFolder.Name = "PollRemotes"
remotesFolder.Parent = ReplicatedStorage

local PollEvent = Instance.new("RemoteEvent")
PollEvent.Name = "PollEvent"
PollEvent.Parent = remotesFolder

local PollFunction = Instance.new("RemoteFunction")
PollFunction.Name = "PollFunction"
PollFunction.Parent = remotesFolder

local activePolls = {}
local scheduledPolls = {}
local pollVoters = {}

local pendingBroadcasts = {}
local BATCH_INTERVAL = 0.1

local adminSet = {}
for _, id in ipairs(ADMIN_IDS) do
	adminSet[id] = true
end

local function isAdmin(player)
	return adminSet[player.UserId] == true
end

local function fireAll(action, data)
	PollEvent:FireAllClients(action, data)
end

local function firePlayer(plr, action, data)
	PollEvent:FireClient(plr, action, data)
end

local function fireAdmins(action, data)
	for _, plr in ipairs(Players:GetPlayers()) do
		if isAdmin(plr) then
			firePlayer(plr, action, data)
		end
	end
end

local function scheduleBroadcast(pollId)
	if pendingBroadcasts[pollId] then return end
	pendingBroadcasts[pollId] = true
	task.delay(BATCH_INTERVAL, function()
		pendingBroadcasts[pollId] = nil
		local poll = activePolls[pollId]
		if not poll or not poll.active then return end
		fireAll("updatePoll", {
			id = pollId,
			leftVotes = poll.leftVotes,
			rightVotes = poll.rightVotes,
		})
		if poll.global then
			pcall(function()
				MessagingService:PublishAsync("PollVote_v1", HttpService:JSONEncode({
					pollId = pollId,
					leftVotes = poll.leftVotes,
					rightVotes = poll.rightVotes,
				}))
			end)
		end
	end)
end

local function endPoll(pollId)
	local poll = activePolls[pollId]
	if not poll then return end
	poll.active = false

	if poll.thread then
		pcall(task.cancel, poll.thread)
		poll.thread = nil
	end

	pendingBroadcasts[pollId] = nil

	local endData = {
		id = poll.id,
		question = poll.question,
		leftLabel = poll.leftLabel,
		rightLabel = poll.rightLabel,
		leftVotes = poll.leftVotes,
		rightVotes = poll.rightVotes,
		global = poll.global,
	}

	activePolls[pollId] = nil
	pollVoters[pollId] = nil

	if poll.global then
		pcall(function()
			MessagingService:PublishAsync("PollEnd_v1", HttpService:JSONEncode(endData))
		end)
	else
		fireAll("endPoll", endData)
	end
end

local function startPoll(pollData)
	local pollId = HttpService:GenerateGUID(false)
	pollData.id = pollId
	pollData.leftVotes = 0
	pollData.rightVotes = 0
	pollData.active = true

	activePolls[pollId] = pollData
	pollVoters[pollId] = {}

	local broadcastData = {
		id = pollId,
		question = pollData.question,
		leftLabel = pollData.leftLabel,
		rightLabel = pollData.rightLabel,
		leftVotes = 0,
		rightVotes = 0,
		global = pollData.global,
		duration = pollData.duration,
	}

	fireAll("showPoll", broadcastData)
	fireAdmins("pollCreated", broadcastData)

	if pollData.global then
		pcall(function()
			MessagingService:PublishAsync("PollStart_v1", HttpService:JSONEncode(broadcastData))
		end)
	end

	pollData.thread = task.delay(pollData.duration, function()
		endPoll(pollId)
	end)

	return pollId
end

pcall(function()
	MessagingService:SubscribeAsync("PollStart_v1", function(message)
		local ok, data = pcall(HttpService.JSONDecode, HttpService, message.Data)
		if not ok or type(data) ~= "table" then return end

		local pollId = data.id
		if activePolls[pollId] then return end

		activePolls[pollId] = {
			id = pollId,
			question = data.question,
			leftLabel = data.leftLabel,
			rightLabel = data.rightLabel,
			leftVotes = data.leftVotes or 0,
			rightVotes = data.rightVotes or 0,
			active = true,
			global = true,
			duration = data.duration or 60,
		}
		pollVoters[pollId] = {}

		fireAll("showPoll", data)
		fireAdmins("pollCreated", data)

		activePolls[pollId].thread = task.delay(data.duration or 60, function()
			if activePolls[pollId] then
				activePolls[pollId] = nil
				pollVoters[pollId] = nil
			end
		end)
	end)
end)

pcall(function()
	MessagingService:SubscribeAsync("PollVote_v1", function(message)
		local ok, data = pcall(HttpService.JSONDecode, HttpService, message.Data)
		if not ok or type(data) ~= "table" then return end

		local poll = activePolls[data.pollId]
		if not poll then return end

		poll.leftVotes = data.leftVotes or poll.leftVotes
		poll.rightVotes = data.rightVotes or poll.rightVotes

		fireAll("updatePoll", {
			id = data.pollId,
			leftVotes = poll.leftVotes,
			rightVotes = poll.rightVotes,
		})
	end)
end)

pcall(function()
	MessagingService:SubscribeAsync("PollEnd_v1", function(message)
		local ok, data = pcall(HttpService.JSONDecode, HttpService, message.Data)
		if not ok or type(data) ~= "table" then return end

		local poll = activePolls[data.id]
		if poll then
			if poll.thread then
				pcall(task.cancel, poll.thread)
			end
			activePolls[data.id] = nil
			pollVoters[data.id] = nil
		end
		fireAll("endPoll", data)
	end)
end)

PollFunction.OnServerInvoke = function(player, action, data)
	if action == "checkAdmin" then
		return isAdmin(player)

	elseif action == "requestActivePoll" then
		for _, poll in pairs(activePolls) do
			if poll.active then
				local voters = pollVoters[poll.id]
				return {
					poll = {
						id = poll.id,
						question = poll.question,
						leftLabel = poll.leftLabel,
						rightLabel = poll.rightLabel,
						leftVotes = poll.leftVotes,
						rightVotes = poll.rightVotes,
						global = poll.global,
					},
					previousVote = voters and voters[player.UserId],
				}
			end
		end
		return nil
	end

	return nil
end

PollEvent.OnServerEvent:Connect(function(player, action, data)
	if type(action) ~= "string" then return end
	if type(data) ~= "table" then return end

	if action == "vote" then
		local pollId = data.pollId
		local side = data.side

		if type(pollId) ~= "string" then return end
		if side ~= "left" and side ~= "right" then return end

		local poll = activePolls[pollId]
		if not poll or not poll.active then return end

		local voters = pollVoters[pollId]
		if not voters then return end

		local previousVote = voters[player.UserId]
		if previousVote == side then return end

		if previousVote == "left" then
			poll.leftVotes = math.max(0, poll.leftVotes - 1)
		elseif previousVote == "right" then
			poll.rightVotes = math.max(0, poll.rightVotes - 1)
		end

		if side == "left" then
			poll.leftVotes = poll.leftVotes + 1
		else
			poll.rightVotes = poll.rightVotes + 1
		end

		voters[player.UserId] = side

		firePlayer(player, "voteChanged", {
			id = pollId,
			side = side,
			leftVotes = poll.leftVotes,
			rightVotes = poll.rightVotes,
		})

		scheduleBroadcast(pollId)

	elseif action == "createPoll" then
		if not isAdmin(player) then return end
		if type(data.question) ~= "string" or #data.question == 0 or #data.question > 200 then return end
		if type(data.leftLabel) ~= "string" or #data.leftLabel == 0 or #data.leftLabel > 50 then return end
		if type(data.rightLabel) ~= "string" or #data.rightLabel == 0 or #data.rightLabel > 50 then return end
		if type(data.duration) ~= "number" or data.duration <= 0 or data.duration > 86400 then return end

		startPoll({
			question = data.question,
			leftLabel = data.leftLabel,
			rightLabel = data.rightLabel,
			duration = math.floor(data.duration),
			global = data.global == true,
		})

	elseif action == "schedulePoll" then
		if not isAdmin(player) then return end
		if type(data.question) ~= "string" or #data.question == 0 or #data.question > 200 then return end
		if type(data.leftLabel) ~= "string" or #data.leftLabel == 0 or #data.leftLabel > 50 then return end
		if type(data.rightLabel) ~= "string" or #data.rightLabel == 0 or #data.rightLabel > 50 then return end
		if type(data.duration) ~= "number" or data.duration <= 0 or data.duration > 86400 then return end
		if type(data.delay) ~= "number" or data.delay <= 0 or data.delay > 2592000 then return end

		local schedId = HttpService:GenerateGUID(false)
		local sanitized = {
			id = schedId,
			question = data.question,
			leftLabel = data.leftLabel,
			rightLabel = data.rightLabel,
			duration = math.floor(data.duration),
			global = data.global == true,
			delay = math.floor(data.delay),
			scheduleLabel = type(data.scheduleLabel) == "string" and data.scheduleLabel:sub(1, 60) or nil,
		}

		scheduledPolls[schedId] = sanitized
		firePlayer(player, "pollScheduled", sanitized)

		task.delay(sanitized.delay, function()
			if not scheduledPolls[schedId] then return end
			scheduledPolls[schedId] = nil

			local activePollId = startPoll({
				question = sanitized.question,
				leftLabel = sanitized.leftLabel,
				rightLabel = sanitized.rightLabel,
				duration = sanitized.duration,
				global = sanitized.global,
			})

			firePlayer(player, "scheduledStarted", {
				schedId = schedId,
				id = activePollId,
				question = sanitized.question,
				leftLabel = sanitized.leftLabel,
				rightLabel = sanitized.rightLabel,
				global = sanitized.global,
			})
		end)

	elseif action == "endPoll" then
		if not isAdmin(player) then return end
		if type(data.pollId) ~= "string" then return end
		endPoll(data.pollId)

	elseif action == "removePoll" then
		if not isAdmin(player) then return end
		if type(data.pollId) ~= "string" then return end

		if scheduledPolls[data.pollId] then
			scheduledPolls[data.pollId] = nil
			return
		end

		local poll = activePolls[data.pollId]
		if poll then
			if poll.thread then
				pcall(task.cancel, poll.thread)
			end
			pendingBroadcasts[data.pollId] = nil
			activePolls[data.pollId] = nil
			pollVoters[data.pollId] = nil

			local endData = {
				id = poll.id,
				question = poll.question,
				leftLabel = poll.leftLabel,
				rightLabel = poll.rightLabel,
				leftVotes = poll.leftVotes,
				rightVotes = poll.rightVotes,
				global = poll.global,
			}

			if poll.global then
				pcall(function()
					MessagingService:PublishAsync("PollEnd_v1", HttpService:JSONEncode(endData))
				end)
			else
				fireAll("endPoll", endData)
			end
		end
	end
end)