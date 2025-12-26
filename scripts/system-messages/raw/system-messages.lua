-- starterCharacterScripts > localScript
 
local TextChatService = game:GetService("TextChatService")
local TextChannels = TextChatService:WaitForChild("TextChannels")
local GeneralChannel = TextChannels:WaitForChild("RBXGeneral")
 
-- list of messages
local messages = {
"Remember to take breaks!",
"Invite your friends to join!",
"Follow the game for updates!",
"Use /help to see all commands!",
"Thanks for playing!",
}
 
local lastMessage = nil
 
-- show a new random message, avoiding repeating the same one
local function getUniqueRandomMessage()
    if #messages <= 1 then
        return messages[1] -- fallback if only one message
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
        GeneralChannel:DisplaySystemMessage("[SYSTEM] : " .. message)
    end
end
 
-- start loop
task.spawn(function()
    while true do
        local waitTime = math.random(360, 420) -- 6–7 minutes
        task.wait(waitTime)
        postSystemMessage()
    end
end)