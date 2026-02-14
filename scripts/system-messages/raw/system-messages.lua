local TextChatService = game:GetService("TextChatService")
local TextChannels = TextChatService:WaitForChild("TextChannels")
local GeneralChannel = TextChannels:WaitForChild("RBXGeneral")

local messages = {
    "Remember to take breaks!",
    "Invite your friends to join!",
    "Follow the game for updates!",
    "Use /help to see all commands!",
    "Thanks for playing!",
}

local lastMessage = nil

local function getUniqueRandomMessage()
    if #messages <= 1 then
        return messages[1]
    end
    
    local newMessage
    repeat
        newMessage = messages[math.random(1, #messages)]
    until newMessage ~= lastMessage
    
    lastMessage = newMessage
    return newMessage
end

local function postSystemMessage()
    local message = getUniqueRandomMessage()
    if GeneralChannel then
        GeneralChannel:DisplaySystemMessage("<font color='#FFD700'>[SYSTEM]:</font> " .. message)
    end
end

while true do
    local waitTime = math.random(360, 420)
    task.wait(waitTime)
    postSystemMessage()
end