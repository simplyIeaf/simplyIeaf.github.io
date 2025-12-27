local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")

local DailyDataStore = DataStoreService:GetDataStore("DailyRewards_System_V3")
local RewardFunc = ReplicatedStorage:WaitForChild("DailyRewardFunction")

local COOLDOWN_HOURS = 24
local BUFFER_HOURS = 48

local DAILY_REWARDS = {
{day = 1, rewardName = "50 Coins", rewardType = "leaderstat", leaderstatName = "Coins", amount = 50},
{day = 2, rewardName = "75 Coins", rewardType = "leaderstat", leaderstatName = "Coins", amount = 75},
{day = 3, rewardName = "100 Coins", rewardType = "leaderstat", leaderstatName = "Coins", amount = 100},
}

local function giveReward(player, dayIndex)
    local rewardData = DAILY_REWARDS[dayIndex]
    if not rewardData then return false end
    
    if rewardData.rewardType == "leaderstat" then
        local leaderstats = player:FindFirstChild("leaderstats")
        if leaderstats then
            if leaderstats:FindFirstChild(rewardData.leaderstatName) then
                local statName = rewardData.leaderstatName
                local stat = leaderstats[statName]
                if stat and (stat:IsA("IntValue") or stat:IsA("NumberValue")) then
                    stat.Value = stat.Value + rewardData.amount
                    return true
                end
            end
        end
    elseif rewardData.rewardType == "tool" then
        local rewardTools = ServerStorage:FindFirstChild("RewardTools")
        if rewardTools then
            local tool = rewardTools:FindFirstChild(rewardData.toolName)
            if tool then
                local backpack = player:FindFirstChild("Backpack")
                if backpack then
                    local clonedTool = tool:Clone()
                    clonedTool.Parent = backpack
                    return true
                end
            end
        end
    end
    return false
end

RewardFunc.OnServerInvoke = function(player, action)
    local key = "User_" .. player.UserId
    local success, data = pcall(function()
        return DailyDataStore:GetAsync(key)
    end)
    
    if not success then return {error = "DataStore Error"} end
    
    data = data or {LastClaimTime = 0, Streak = 1}
    
    local currentTime = os.time()
    local timeSinceLastClaim = currentTime - data.LastClaimTime
    local cooldownSeconds = COOLDOWN_HOURS * 3600
    local bufferSeconds = BUFFER_HOURS * 3600
    
    if data.LastClaimTime > 0 and timeSinceLastClaim > bufferSeconds then
        data.Streak = 1
    end
    
    local nextClaimTimestamp = data.LastClaimTime + cooldownSeconds
    local canClaim = currentTime >= nextClaimTimestamp
    
    local currentRewardDay = data.Streak
    if currentRewardDay > #DAILY_REWARDS then
        currentRewardDay = 1
        data.Streak = 1 
    end
    
    if action == "GetInfo" then
        return {
        streak = currentRewardDay,
        nextClaimTime = nextClaimTimestamp,
        rewardsTable = DAILY_REWARDS,
        isReady = canClaim
        }
        
    elseif action == "Claim" then
        if canClaim then
            local rewardGiven = giveReward(player, currentRewardDay)
            
            if rewardGiven then
                data.LastClaimTime = currentTime
                data.Streak = data.Streak + 1
                
                task.spawn(function()
                    pcall(function()
                        DailyDataStore:SetAsync(key, data)
                    end)
                end)
                
                return {success = true, newStreak = data.Streak}
            else
                return {success = false, msg = "Reward Error"}
            end
        else
            return {success = false, msg = "Wait longer"}
        end
    end
end
