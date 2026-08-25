-- made by @simplyIeaf1 on youtube
 
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
 
local ADMIN_UIDS = {8033814042}
 
local function isAdmin(player)
    for _, uid in ipairs(ADMIN_UIDS) do
        if player.UserId == uid then
            return true
        end
    end
    return false
end
 
local AdminCommand = Instance.new("RemoteEvent")
AdminCommand.Name = "AdminCommand"
AdminCommand.Parent = ReplicatedStorage
 
local function findPlayersByName(searchName)
    local matches = {}
    searchName = searchName:lower()
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Name:lower():find(searchName, 1, true) then
            table.insert(matches, p)
        end
    end
    return matches
end

local function getRandomPlayer(excludePlayer)
    local players = Players:GetPlayers()
    local validPlayers = {}
    for _, p in ipairs(players) do
        if p ~= excludePlayer then
            table.insert(validPlayers, p)
        end
    end
    if #validPlayers > 0 then
        return validPlayers[math.random(1, #validPlayers)]
    end
    return nil
end

AdminCommand.OnServerEvent:Connect(function(player, fullCommand)
    if not isAdmin(player) then return end
    
    local parts = string.split(fullCommand, " ")
    local cmd = parts[1]:sub(2):lower()
    table.remove(parts, 1)
    local args = parts
    local targetName = args[1] or "me"
    
    local lowerTarget = targetName:lower()
    local targetPlayer
    
    if lowerTarget == "me" then
        targetPlayer = player
    elseif lowerTarget == "all" then
        for _, p in ipairs(Players:GetPlayers()) do
            executeCommandOnPlayer(p, cmd, args, player)
        end
        return
    elseif lowerTarget == "others" then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= player then
                executeCommandOnPlayer(p, cmd, args, player)
            end
        end
        return
    elseif lowerTarget == "random" then
        targetPlayer = getRandomPlayer(player)
    else
        local success, uid = pcall(Players.GetUserIdFromNameAsync, Players, targetName)
        if success and uid > 0 then
            targetPlayer = Players:GetPlayerByUserId(uid)
        end
        
        if not targetPlayer then
            local matches = findPlayersByName(lowerTarget)
            if #matches == 1 then
                targetPlayer = matches[1]
            elseif #matches > 1 then
                for _, p in ipairs(matches) do
                    executeCommandOnPlayer(p, cmd, args, player)
                end
                return
            end
        end
    end
    
    if targetPlayer then
        executeCommandOnPlayer(targetPlayer, cmd, args, player)
    end
end)

function executeCommandOnPlayer(target, cmd, args, admin)
    local char = target.Character
    if not char and cmd ~= "kick" and cmd ~= "givetools" and cmd ~= "removetools" and cmd ~= "respawn" then return end
    local humanoid = char and char:FindFirstChild("Humanoid")
    local root = char and char:FindFirstChild("HumanoidRootPart")
    
    if cmd == "kill" then
        if humanoid then humanoid.Health = 0 end
    elseif cmd == "respawn" or cmd == "reset" or cmd == "re" then
        target:LoadCharacter()
    elseif cmd == "freeze" then
        for _, part in ipairs(char:GetChildren()) do
            if part:IsA("BasePart") then
                part.Anchored = true
            end
        end
        if root then
            local ice = Instance.new("Part")
            ice.Name = "IceCube"
            ice.Size = Vector3.new(10,10,10)
            ice.Transparency = 0.3
            ice.Material = Enum.Material.Ice
            ice.Anchored = true
            ice.CFrame = root.CFrame
            ice.Parent = workspace
            char.Parent = ice
        end
    elseif cmd == "unfreeze" then
        for _, part in ipairs(char:GetChildren()) do
            if part:IsA("BasePart") then
                part.Anchored = false
            end
        end
        if char and char.Parent and char.Parent.Name == "IceCube" then
            local oldParent = char.Parent
            char.Parent = workspace
            oldParent:Destroy()
        end
    elseif cmd == "ff" or cmd == "forcefield" then
        local ff = Instance.new("ForceField")
        ff.Parent = char
    elseif cmd == "unff" or cmd == "unforcefield" then
        for _, ff in ipairs(char:GetChildren()) do
            if ff:IsA("ForceField") then ff:Destroy() end
        end
    elseif cmd == "fire" then
        if root then
            local fire = Instance.new("Fire")
            fire.Parent = root
        end
    elseif cmd == "unfire" then
        for _, f in ipairs(char:GetDescendants()) do
            if f:IsA("Fire") then f:Destroy() end
        end
    elseif cmd == "smoke" then
        if root then
            local smoke = Instance.new("Smoke")
            smoke.Parent = root
        end
    elseif cmd == "unsmoke" then
        for _, s in ipairs(char:GetDescendants()) do
            if s:IsA("Smoke") then s:Destroy() end
        end
    elseif cmd == "sparkles" then
        if root then
            local sparkles = Instance.new("Sparkles")
            sparkles.Parent = root
        end
    elseif cmd == "unsparkles" then
        for _, sp in ipairs(char:GetDescendants()) do
            if sp:IsA("Sparkles") then sp:Destroy() end
        end
    elseif cmd == "jump" then
        if humanoid and root then
            root.Velocity = Vector3.new(0, 50, 0)
        end
    elseif cmd == "sit" then
        if humanoid then humanoid.Sit = true end
    elseif cmd == "smallhead" then
        local head = char:FindFirstChild("Head")
        if head then head.Size = head.Size * 0.5 end
    elseif cmd == "normalhead" then
        local head = char:FindFirstChild("Head")
        if head then head.Size = Vector3.new(2, 1, 1) end
    elseif cmd == "invisible" then
        for _, part in ipairs(char:GetChildren()) do
            if part:IsA("BasePart") then part.Transparency = 1 end
        end
    elseif cmd == "visible" then
        for _, part in ipairs(char:GetChildren()) do
            if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                part.Transparency = 0
            end
        end
    elseif cmd == "god" or cmd == "godmode" then
        if humanoid then humanoid.MaxHealth = math.huge; humanoid.Health = math.huge end
    elseif cmd == "ungod" or cmd == "ungodmode" then
        if humanoid then humanoid.MaxHealth = 100; humanoid.Health = 100 end
    elseif cmd == "heal" then
        if humanoid then humanoid.Health = humanoid.MaxHealth end
    elseif cmd == "explode" then
        if root then
            local explosion = Instance.new("Explosion")
            explosion.Position = root.Position
            explosion.Parent = workspace
        end
    elseif cmd == "stun" then
        if humanoid then humanoid.PlatformStand = true end
    elseif cmd == "unstun" then
        if humanoid then humanoid.PlatformStand = false end
    elseif cmd == "trip" then
        if root then root.Velocity = Vector3.new(0, 0, 0); root.RotVelocity = Vector3.new(math.random(-50,50), 0, math.random(-50,50)) end
    elseif cmd == "loopkill" then
        spawn(function()
            while target.Parent do
                wait(1)
                local currentChar = target.Character
                if currentChar then
                    local h = currentChar:FindFirstChild("Humanoid")
                    if h then h.Health = 0 end
                end
            end
        end)
    elseif cmd == "kick" then
        print("Kicking UserId:", target.UserId, "by", admin.Name)
        local success, err = pcall(function()
            target:Kick("Kicked by " .. admin.Name)
        end)
        if success then
            print("Kick successful for UserId:", target.UserId)
        else
            warn("Kick failed for UserId", target.UserId, ":", err)
        end
    elseif cmd == "givetools" then
        local backpack = target:FindFirstChild("Backpack")
        if backpack then
            for _, tool in ipairs(game.StarterPack:GetChildren()) do
                if tool:IsA("Tool") then
                    local clone = tool:Clone()
                    clone.Parent = backpack
                end
            end
        end
    elseif cmd == "removetools" then
        local backpack = target:FindFirstChild("Backpack")
        if backpack then backpack:ClearAllChildren() end
    elseif cmd == "shirt" then
        local shirtId = tonumber(args[2])
        if shirtId and char then
            local shirt = Instance.new("Shirt")
            shirt.ShirtTemplate = "rbxassetid://" .. shirtId
            shirt.Parent = char
        end
    elseif cmd == "pants" then
        local pantsId = tonumber(args[2])
        if pantsId and char then
            local pants = Instance.new("Pants")
            pants.PantsTemplate = "rbxassetid://" .. pantsId
            pants.Parent = char
        end
    elseif cmd == "hat" then
        local hatId = tonumber(args[2])
        if hatId and char then
            local hat = Instance.new("Accessory")
            hat.AccessoryType = Enum.AccessoryType.Hat
            local handle = Instance.new("Part")
            handle.Name = "Handle"
            handle.Size = Vector3.new(1,1,1)
            handle.Parent = hat
            local mesh = Instance.new("SpecialMesh")
            mesh.MeshId = "rbxassetid://" .. hatId
            mesh.Parent = handle
            hat.Parent = char
        end
    elseif cmd == "clearhats" then
        for _, acc in ipairs(char:GetChildren()) do
            if acc:IsA("Accessory") then acc:Destroy() end
        end
    elseif cmd == "paint" then
        local hex = args[2]
        local color = Color3.fromHex(hex) or Color3.new(1,0,0)
        for _, part in ipairs(char:GetChildren()) do
            if part:IsA("BasePart") then part.Color = color end
        end
    elseif cmd == "transparency" then
        local trans = tonumber(args[2]) or 1
        for _, part in ipairs(char:GetChildren()) do
            if part:IsA("BasePart") then part.Transparency = trans end
        end
    elseif cmd == "spin" then
        local speed = tonumber(args[2]) or 10
        if root then
            local spin = Instance.new("BodyAngularVelocity")
            spin.AngularVelocity = Vector3.new(0, speed, 0)
            spin.MaxTorque = Vector3.new(0, math.huge, 0)
            spin.Parent = root
            Debris:AddItem(spin, 10)
        end
    elseif cmd == "refresh" then
        for _, eff in ipairs({"Fire", "Smoke", "Sparkles", "ForceField"}) do
            for _, inst in ipairs(char:GetDescendants()) do
                if inst:IsA(eff) then inst:Destroy() end
            end
        end
        if humanoid then humanoid.PlatformStand = false end
        for _, part in ipairs(char:GetChildren()) do
            if part:IsA("BasePart") then part.Anchored = false end
        end
    elseif cmd == "punish" then
        executeCommandOnPlayer(target, "loopkill", {}, admin)
        executeCommandOnPlayer(target, "freeze", {}, admin)
    elseif cmd == "unpunish" then
        executeCommandOnPlayer(target, "unfreeze", {}, admin)
    elseif cmd == "ice" then
        if root then
            local ice = Instance.new("Part")
            ice.Name = "IceCube"
            ice.Size = Vector3.new(10,10,10)
            ice.Transparency = 0.3
            ice.Material = Enum.Material.Ice
            ice.Anchored = true
            ice.CFrame = root.CFrame
            ice.Parent = workspace
            char.Parent = ice
            spawn(function()
                wait(10)
                if char and ice then
                    char.Parent = workspace
                    ice:Destroy()
                end
            end)
        end
    elseif cmd == "ghost" then
        for _, part in ipairs(char:GetChildren()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
                part.Transparency = 0.5
            end
        end
    elseif cmd == "neon" then
        for _, part in ipairs(char:GetChildren()) do
            if part:IsA("BasePart") then part.Material = Enum.Material.Neon end
        end
    elseif cmd == "glass" then
        for _, part in ipairs(char:GetChildren()) do
            if part:IsA("BasePart") then part.Material = Enum.Material.Glass end
        end
    elseif cmd == "gold" then
        for _, part in ipairs(char:GetChildren()) do
            if part:IsA("BasePart") then part.Color = Color3.new(1,0.8,0); part.Material = Enum.Material.Metal end
        end
    elseif cmd == "shine" then
        if root then
            local light = Instance.new("PointLight")
            light.Brightness = 2
            light.Parent = root
        end
    elseif cmd == "fart" then
        if root then
            local sound = Instance.new("Sound")
            sound.SoundId = "rbxassetid://131961136"
            sound.Volume = 0.5
            sound.Parent = root
            sound:Play()
            Debris:AddItem(sound, 5)
        end
    elseif cmd == "tp" then
        local t2name = args[2]
        if t2name then
            local t2 = Players:FindFirstChild(t2name)
            if t2 and t2.Character and t2.Character:FindFirstChild("HumanoidRootPart") and root then
                root.CFrame = t2.Character.HumanoidRootPart.CFrame
            end
        end
    elseif cmd == "speed" then
        local val = tonumber(args[2]) or 16
        if humanoid then humanoid.WalkSpeed = val end
    elseif cmd == "jumppower" then
        local val = tonumber(args[2]) or 50
        if humanoid then humanoid.JumpPower = val end
    end
end
