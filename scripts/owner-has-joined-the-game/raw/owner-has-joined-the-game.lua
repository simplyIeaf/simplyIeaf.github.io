local TextChatService = game:GetService("TextChatService")
local Players = game:GetService("Players")

local roleGroups = {
{users = {"simplyIeaf", "owner2"}, title = "Owner"},
{users = {"admin1", "admin2"}, title = "Admin"},
{users = {"dev1", "dev2"}, title = "Developer"},
{users = {"tester1", "tester2"}, title = "Tester"}
}

local processedPlayers = {}

local function checkAndDisplay(player)
    if processedPlayers[player.UserId] then return end
    processedPlayers[player.UserId] = true
    
    local lowerName = string.lower(player.Name)
    local foundTitle = nil
    
    for _, group in pairs(roleGroups) do
        for _, username in pairs(group.users) do
            if string.lower(username) == lowerName then
                foundTitle = group.title
                break
            end
        end
        if foundTitle then break end
    end
    
    if foundTitle then
        local generalChannel = TextChatService:FindFirstChild("TextChannels") and TextChatService.TextChannels:FindFirstChild("RBXGeneral")
        if generalChannel then
            local message = string.format("[SERVER]: %s has joined the game!", foundTitle)
            generalChannel:DisplaySystemMessage(message)
        end
    end
end

Players.PlayerAdded:Connect(checkAndDisplay)

for _, player in pairs(Players:GetPlayers()) do
    checkAndDisplay(player)
end

Players.PlayerRemoving:Connect(function(player)
    processedPlayers[player.UserId] = nil
end)