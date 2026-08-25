local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")

local voteKickEvent = Instance.new("RemoteEvent")
voteKickEvent.Name = "VoteKickEvent"
voteKickEvent.Parent = ReplicatedStorage

local voteKickFunction = Instance.new("RemoteFunction")
voteKickFunction.Name = "VoteKickFunction"
voteKickFunction.Parent = ReplicatedStorage

local VOTE_DURATION = 20
local COOLDOWN_HOURS = 24
local COOLDOWN_SECONDS = COOLDOWN_HOURS * 3600
local MIN_PLAYERS_TO_VOTEKICK = 2

local cooldownStore = DataStoreService:GetDataStore("VoteKickCooldowns2")
local activeVotes = {}

local function getCooldownKey(userId)
    return "vk_" .. tostring(userId)
end

local function isOnCooldown(initiatorId)
    local success, data = pcall(function()
        return cooldownStore:GetAsync(getCooldownKey(initiatorId))
    end)
    if success and data then
        local elapsed = os.time() - data
        if elapsed < COOLDOWN_SECONDS then
            return true, math.ceil((COOLDOWN_SECONDS - elapsed) / 3600)
        end
    end
    return false, 0
end

local function setCooldown(initiatorId)
    pcall(function()
        cooldownStore:SetAsync(getCooldownKey(initiatorId), os.time())
    end)
end

local function getTargetPlayer(name)
    local lowerName = string.lower(name)
    for _, p in pairs(Players:GetPlayers()) do
        if string.lower(p.Name) == lowerName or string.lower(p.DisplayName) == lowerName then
            return p
        end
    end
    return nil
end

local function checkAllVoted(targetUserId)
    local voteData = activeVotes[targetUserId]
    if not voteData then return end
    
    for _, p in pairs(Players:GetPlayers()) do
        if p.UserId ~= targetUserId and not voteData.Voted[p.UserId] then
            return
        end
    end
    
endVote(targetUserId)
end

function endVote(targetUserId)
    local voteData = activeVotes[targetUserId]
    if not voteData then return end
    
    local targetPlayer = Players:GetPlayerByUserId(targetUserId)
    activeVotes[targetUserId] = nil
    
    voteKickEvent:FireAllClients("ClosePrompt", targetUserId)
    
    if targetPlayer then
        if voteData.Yes > voteData.No then
            local msg = targetPlayer.DisplayName .. " (@" .. targetPlayer.Name .. ") has been votekicked from the server"
            voteKickEvent:FireAllClients("SystemMessage", msg, Color3.fromRGB(255, 50, 50))
            targetPlayer:Kick("You have been votekicked out of the server")
        end
    end
end

Players.PlayerAdded:Connect(function(player)
    player.Chatted:Connect(function(message)
        if string.sub(string.lower(message), 1, 10) ~= "/votekick " then return end
        
        local targetName = string.sub(message, 11)
        targetName = string.match(targetName, "^%s*(.-)%s*$")
        
        if not targetName or targetName == "" then
            voteKickEvent:FireClient(player, "SystemMessage", "Usage: /votekick <username>", Color3.fromRGB(180, 180, 180))
            return
        end
        
        if #Players:GetPlayers() < MIN_PLAYERS_TO_VOTEKICK then
            voteKickEvent:FireClient(player, "SystemMessage", "Not enough players to start a votekick.", Color3.fromRGB(180, 180, 180))
            return
        end
        
        local targetPlayer = getTargetPlayer(targetName)
        
        if not targetPlayer then
            voteKickEvent:FireClient(player, "SystemMessage", "Player \"" .. targetName .. "\" not found.", Color3.fromRGB(180, 180, 180))
            return
        end
        
        if targetPlayer == player then
            voteKickEvent:FireClient(player, "SystemMessage", "You cannot votekick yourself.", Color3.fromRGB(180, 180, 180))
            return
        end
        
        if targetPlayer.UserId < 0 then
            voteKickEvent:FireClient(player, "SystemMessage", "You cannot votekick a guest.", Color3.fromRGB(180, 180, 180))
            return
        end
        
        for _, data in pairs(activeVotes) do
            if data.InitiatorId == player.UserId then
                voteKickEvent:FireClient(player, "SystemMessage", "You already have a votekick in progress.", Color3.fromRGB(180, 180, 180))
                return
            end
        end
        
        if activeVotes[targetPlayer.UserId] then
            voteKickEvent:FireClient(player, "SystemMessage", "A votekick for that player is already in progress.", Color3.fromRGB(180, 180, 180))
            return
        end
        
        local onCD, hoursLeft = isOnCooldown(player.UserId)
        if onCD then
            voteKickEvent:FireClient(player, "SystemMessage", "You are on votekick cooldown. Try again in " .. hoursLeft .. " hour(s).", Color3.fromRGB(180, 180, 180))
            return
        end
        
        setCooldown(player.UserId)
        
        local eligibleVoters = {}
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= targetPlayer then
                eligibleVoters[p.UserId] = true
            end
        end
        
        activeVotes[targetPlayer.UserId] = {
        Yes = 0,
        No = 0,
        Voted = {},
        Target = targetPlayer,
        InitiatorId = player.UserId,
        TimeLeft = VOTE_DURATION,
        EligibleVoters = eligibleVoters
        }
        
        task.spawn(function()
            while activeVotes[targetPlayer.UserId] do
                task.wait(1)
                if activeVotes[targetPlayer.UserId] then
                    activeVotes[targetPlayer.UserId].TimeLeft -= 1
                end
            end
        end)
        
        voteKickEvent:FireAllClients("SystemMessage", "Votekicking " .. targetPlayer.DisplayName .. " (@" .. targetPlayer.Name .. ")", Color3.fromRGB(255, 215, 0))
        
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= targetPlayer then
                voteKickEvent:FireClient(p, "ShowPrompt", targetPlayer.DisplayName, targetPlayer.Name, targetPlayer.UserId, VOTE_DURATION)
            end
        end
        
        task.delay(VOTE_DURATION, function()
        endVote(targetPlayer.UserId)
        end)
        end)
        end)
            
            Players.PlayerRemoving:Connect(function(player)
                if activeVotes[player.UserId] then
                    activeVotes[player.UserId] = nil
                    voteKickEvent:FireAllClients("ClosePrompt", player.UserId)
                    return
                end
                
                for targetUserId, voteData in pairs(activeVotes) do
                    if voteData.EligibleVoters[player.UserId] then
                        if not voteData.Voted[player.UserId] then
                            voteData.Voted[player.UserId] = true
                        end
                        checkAllVoted(targetUserId)
                        break
                    end
                end
            end)
            
            voteKickFunction.OnServerInvoke = function(player, action, targetUserId, choice)
                if typeof(action) ~= "string" then return false end
                if typeof(targetUserId) ~= "number" then return false end
                if typeof(choice) ~= "string" then return false end
                
                if action == "SubmitVote" then
                    if choice ~= "Yes" and choice ~= "No" then return false end
                    
                    local voteData = activeVotes[targetUserId]
                    if not voteData then return false end
                    if player.UserId == targetUserId then return false end
                    if voteData.Voted[player.UserId] then return false end
                    if not voteData.EligibleVoters[player.UserId] then return false end
                    
                    local validVoter = false
                    for _, p in pairs(Players:GetPlayers()) do
                        if p.UserId == player.UserId then
                            validVoter = true
                            break
                        end
                    end
                    if not validVoter then return false end
                    
                    voteData.Voted[player.UserId] = true
                    if choice == "Yes" then
                        voteData.Yes += 1
                    else
                        voteData.No += 1
                    end
                    
                    checkAllVoted(targetUserId)
                    return true
                end
                
                return false
            end
           