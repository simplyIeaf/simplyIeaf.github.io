local MessagingService = game:GetService("MessagingService")
local TextChatService = game:GetService("TextChatService")
local TextService = game:GetService("TextService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local adminIds = {
	1234567, -- Replace with your ID
	9876543
}

local config = {
	prefix = "/gcannounce",
	topic = "GlobalNetworkSync"
}

local remote = Instance.new("RemoteEvent")
remote.Name = "GlobalAnnounceRemote"
remote.Parent = ReplicatedStorage

local cmd = Instance.new("TextChatCommand")
cmd.Name = "GlobalAnnounce"
cmd.PrimaryAlias = config.prefix
cmd.Parent = TextChatService:WaitForChild("TextChatCommands")

local function isAdmin(id)
	for _, adminId in ipairs(adminIds) do
		if adminId == id then return true end
	end
	return false
end

local function filterText(text, fromUserId)
	local success, result = pcall(function()
		local filterResult = TextService:FilterStringAsync(text, fromUserId)
		return filterResult:GetNonChatStringForBroadcastAsync()
	end)
	return success and result or "???"
end

MessagingService:SubscribeAsync(config.topic, function(message)
	remote:FireAllClients(message.Data)
end)

cmd.Triggered:Connect(function(source, text)
	if not source or not isAdmin(source.UserId) then 
		return 
	end

	local pattern = "^" .. config.prefix .. "%s+(.+)$"
	local messageContent = string.match(text, pattern)
	
	if messageContent and #messageContent > 0 then
		local filteredMessage = filterText(messageContent, source.UserId)
		
		local success, err = pcall(function()
			MessagingService:PublishAsync(config.topic, filteredMessage)
		end)
		
		if not success then warn(err) end
	end
end)