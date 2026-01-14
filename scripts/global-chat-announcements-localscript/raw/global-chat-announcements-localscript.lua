local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")

local remote = ReplicatedStorage:WaitForChild("GlobalAnnounceRemote")

remote.OnClientEvent:Connect(function(content)
	local channel = TextChatService.TextChannels:FindFirstChild("RBXGeneral")
	if channel then
		local displayFormat = "<font color='#FFA500'><b>[GLOBAL]:</b></font> " .. content
		channel:DisplaySystemMessage(displayFormat)
	end
end)