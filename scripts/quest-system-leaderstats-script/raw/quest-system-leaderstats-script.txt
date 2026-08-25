local Players = game:GetService("Players")

Players.PlayerAdded:Connect(function(plr)
    local ls = Instance.new("Folder")
    ls.Name = "leaderstats"
    ls.Parent = plr
    
    local kills = Instance.new("IntValue")
    kills.Name = "Kills"
    kills.Value = 0
    kills.Parent = ls
    
    local cash = Instance.new("IntValue")
    cash.Name = "Cash"
    cash.Value = 0
    cash.Parent = ls
end)

local function onHumanoidAdded(hum)
    hum.Died:Connect(function()
        local tag = hum:FindFirstChild("creator")
        if not tag or not tag.Value then
            return
        end
        
        local killer = tag.Value
        local killerPlr = nil
        
        if killer:IsA("Player") then
            killerPlr = killer
        elseif killer:IsA("Model") then
            killerPlr = Players:GetPlayerFromCharacter(killer)
        end
        
        if killerPlr then
            local kls = killerPlr:FindFirstChild("leaderstats")
            if kls then
                local kKills = kls:FindFirstChild("Kills")
                if kKills then
                    kKills.Value = kKills.Value + 1
                end
            end
        end
    end)
end

local function checkObject(obj)
    if obj:IsA("Humanoid") then
        onHumanoidAdded(obj)
    end
end

for _, obj in ipairs(workspace:GetDescendants()) do
    checkObject(obj)
end

workspace.DescendantAdded:Connect(checkObject)