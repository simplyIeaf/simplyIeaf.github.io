local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
 
local questEvent = Instance.new("RemoteFunction")
questEvent.Name = "QuestEvent"
questEvent.Parent = RS
 
local npc = workspace:WaitForChild("QuestNPC")
 
local quests = {
{Type = "Kills", Target = 3, Desc = "Kill 3 players", Reward = 100, RewardStat = "Cash"},
{Type = "Survive", Target = 30, Desc = "Survive for 30 seconds", Reward = 50, RewardStat = "Cash"},
{Type = "Survive", Target = 10, Desc = "Survive for 10 seconds", Reward = 25, RewardStat = "Cash"}, 
}
 
 
local data = {}
local killConnections = {}
 
local function assignQuest(d, plr)
    local availableQuests = {}
    for _, q in ipairs(quests) do
        if d.Quest ~= q then
            table.insert(availableQuests, q)
        end
    end
    
    if #availableQuests == 0 then
        availableQuests = quests
    end
    
    local q = availableQuests[math.random(1, #availableQuests)]
    d.Quest = q
    d.Progress = 0
    d.AcceptTime = os.time()
    d.NoDamageFailed = false
    d.NoDamageStart = os.time()
    d.Streak = 0
    d.State = 1
    
    if q.Type == "Kills" then
        local ls = plr:FindFirstChild("leaderstats")
        if ls and ls:FindFirstChild("Kills") then
            d.KillsAtAccept = ls.Kills.Value
            d.Progress = 0
        end
    end
    
    return q
end
 
local function setupChar(plr, char)
    local d = data[plr.UserId]
    if not d then
        return
    end
    
    local hum = char:WaitForChild("Humanoid")
    
    hum.HealthChanged:Connect(function(hp)
        if hp < hum.MaxHealth and d.State == 1 and d.Quest and d.Quest.Type == "NoDamage" then
            d.NoDamageFailed = true
        end
    end)
    
    hum.Died:Connect(function()
        if d.State == 1 and d.Quest then
            if d.Quest.Streak then
                d.Streak = 0
                d.Progress = 0
            end
            if d.Quest.Type == "Survive" or d.Quest.Type == "NoDamage" then
                d.AcceptTime = os.time()
                d.NoDamageFailed = false
                d.NoDamageStart = os.time()
                d.Progress = 0
            end
            if d.Quest.Type == "Kills" then
                d.KillsAtAccept = nil
                d.Progress = 0
            end
        end
    end)
end
 
Players.PlayerAdded:Connect(function(plr)
    data[plr.UserId] = {
    State = 0,
    Quest = nil,
    Progress = 0,
    AcceptTime = 0,
    NoDamageFailed = false,
    NoDamageStart = 0,
    Streak = 0,
    KillsAtAccept = nil,
    }
    
    local ls = plr:WaitForChild("leaderstats", 10)
    if ls then
        local killsVal = ls:WaitForChild("Kills", 10)
        if killsVal then
            local conn = killsVal.Changed:Connect(function(newVal)
                local d = data[plr.UserId]
                if not d or d.State ~= 1 or not d.Quest or d.Quest.Type ~= "Kills" then
                    return
                end
                if d.KillsAtAccept == nil then
                    d.KillsAtAccept = newVal - 1
                end
                d.Progress = newVal - d.KillsAtAccept
                if d.Progress < 0 then
                    d.Progress = 0
                end
                if d.Progress >= d.Quest.Target then
                    d.Progress = d.Quest.Target
                    d.State = 2
                end
            end)
            killConnections[plr.UserId] = conn
        end
    end
    
    if plr.Character then
        setupChar(plr, plr.Character)
    end
    plr.CharacterAdded:Connect(function(char)
        setupChar(plr, char)
    end)
end)
 
Players.PlayerRemoving:Connect(function(plr)
    data[plr.UserId] = nil
    if killConnections[plr.UserId] then
        killConnections[plr.UserId]:Disconnect()
        killConnections[plr.UserId] = nil
    end
end)
 
local function tickQuest(plr)
    local d = data[plr.UserId]
    if not d or d.State ~= 1 or not d.Quest then
        return
    end
    local q = d.Quest
    
    if q.Type == "Survive" then
        d.Progress = os.time() - d.AcceptTime
        if d.Progress >= q.Target then
            d.Progress = q.Target
            d.State = 2
        end
    elseif q.Type == "Collect" then
        local ls = plr:FindFirstChild("leaderstats")
        if ls and ls:FindFirstChild("Cash") then
            d.Progress = ls.Cash.Value
            if d.Progress >= q.Target then
                d.State = 2
            end
        end
    elseif q.Type == "Playtime" then
        d.Progress = os.time() - d.AcceptTime
        if d.Progress >= q.Target then
            d.Progress = q.Target
            d.State = 2
        end
    elseif q.Type == "NoDamage" then
        if d.NoDamageFailed then
            d.Progress = 0
            d.State = 0
            d.Quest = nil
        else
            d.Progress = os.time() - d.NoDamageStart
            if d.Progress >= q.Target then
                d.Progress = q.Target
                d.State = 2
            end
        end
    end
end
 
questEvent.OnServerInvoke = function(plr, action, arg)
    if typeof(plr) ~= "Instance" or not plr:IsA("Player") then
        return
    end
    
    if action == "GetNPC" then
        return npc
    end
    
    local d = data[plr.UserId]
    if not d then
        return
    end
    
    tickQuest(plr)
    
    if action == "GetState" then
        return d
        
    elseif action == "Interact" then
        if d.State == 0 then
            return "Hey, what do you want?", {"Give me a quest", "Bye"}
        elseif d.State == 1 then
            return "Hey, what do you want?", {"I completed the quest", "Give me a new quest", "Bye"}
        elseif d.State == 2 then
            return "Hey, what do you want?", {"I completed the quest", "Give me a new quest", "Bye"}
        end
        
    elseif action == "SelectOption" then
        if typeof(arg) ~= "string" then
            return
        end
        
        if arg == "Give me a quest" then
            if d.State ~= 0 then
                return
            end
            local q = assignQuest(d, plr)
            return "Okay, " .. q.Desc
            
        elseif arg == "I completed the quest" then
            if d.State == 0 then
                return
            end
            if d.State == 1 then
                return "You haven't finished the quest."
            end
            if d.State == 2 then
                local savedQuest = d.Quest
                if not savedQuest then
                    return
                end
                
                local reward = savedQuest.Reward
                local rewardStat = savedQuest.RewardStat
                
                if type(reward) ~= "number" or reward <= 0 or reward > 10000 then
                    return
                end
                local ls = plr:FindFirstChild("leaderstats")
                if not ls then
                    return
                end
                
                local statVal = ls:FindFirstChild(rewardStat)
                if not statVal then
                    return
                end
                
                d.State = 0
                d.Quest = nil
                d.Progress = 0
                d.KillsAtAccept = nil
                statVal.Value = statVal.Value + reward
                return "Okay, Here's " .. reward .. " " .. rewardStat .. "."
            end
            
        elseif arg == "Give me a new quest" then
            if d.State == 0 then
                return "You don't have any active quests."
            end
            assignQuest(d, plr)
            return "Done, I gave you a new quest."
            
        elseif arg == "Bye" then
            return "See ya."
        end
    end
end