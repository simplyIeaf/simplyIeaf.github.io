local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local chatRemote = Instance.new("RemoteEvent")
chatRemote.Name = "SafeChatEvent"
chatRemote.Parent = ReplicatedStorage

local getMessagesFunc = Instance.new("RemoteFunction")
getMessagesFunc.Name = "GetMessages"
getMessagesFunc.Parent = ReplicatedStorage

local messages = {
	"Hello",
	"Good Game",
	"Need Help?",
	"Follow Me",
	"Thanks!",
	"Let's Go",
	"Wait",
	"Nice",
	"On My Way",
	"Ready"
}

local cooldowns = {}

function getMessagesFunc.OnServerInvoke(player)
	return messages
end

chatRemote.OnServerEvent:Connect(function(player, messageText)
	local lastTime = cooldowns[player.UserId]
	local now = os.clock()

	if lastTime and (now - lastTime < 3) then
		return
	end

	local valid = false
	for _, msg in ipairs(messages) do
		if msg == messageText then
			valid = true
			break
		end
	end

	if valid then
		cooldowns[player.UserId] = now
		chatRemote:FireAllClients(player, messageText)
	end
end)