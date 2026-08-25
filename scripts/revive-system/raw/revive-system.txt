-- made by @simplyIeaf1 on YouTube

local Players = game:GetService("Players")

Players.RespawnTime = math.huge
Players.CharacterAutoLoads = false

for _, player in pairs(Players:GetPlayers()) do
    if player.Character then
        local humanoid = player.Character:FindFirstChild("Humanoid")
        if humanoid then
            humanoid.BreakJointsOnDeath = false
        end
    end
end

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(char)
        local humanoid = char:WaitForChild("Humanoid", 5)
        if humanoid then
            humanoid.BreakJointsOnDeath = false
        end
    end)
end)

local function ragdollR6(char)
    for _, joint in ipairs(char:GetDescendants()) do
        if joint:IsA("Motor6D") then
            local socket = Instance.new("BallSocketConstraint")
            local att0 = Instance.new("Attachment")
            local att1 = Instance.new("Attachment")
            att0.Parent = joint.Part0
            att1.Parent = joint.Part1
            att0.CFrame = joint.C0
            att1.CFrame = joint.C1
            socket.Attachment0 = att0
            socket.Attachment1 = att1
            socket.LimitsEnabled = true
            socket.TwistLimitsEnabled = true
            socket.Parent = joint.Parent
            joint:Destroy()
        end
    end
    for _, part in ipairs(char:GetChildren()) do
        if part:IsA("BasePart") then
            part.CanCollide = true
            part.Anchored = false
        end
    end
end

local function ragdollR15(char)
    for _, joint in ipairs(char:GetDescendants()) do
        if joint:IsA("Motor6D") then
            local socket = Instance.new("BallSocketConstraint")
            local att0 = Instance.new("Attachment")
            local att1 = Instance.new("Attachment")
            att0.Parent = joint.Part0
            att1.Parent = joint.Part1
            att0.CFrame = joint.C0
            att1.CFrame = joint.C1
            socket.Attachment0 = att0
            socket.Attachment1 = att1
            socket.LimitsEnabled = true
            socket.TwistLimitsEnabled = true
            socket.Parent = joint.Parent
            joint:Destroy()
        elseif joint:IsA("Attachment") then
            joint:Destroy()
        end
    end
    local partsToCollide = {"Head","LeftHand","RightHand","RightFoot","LeftFoot","UpperTorso","LowerTorso","LeftUpperLeg","RightUpperLeg","LeftUpperArm","RightUpperArm","LeftLowerLeg","RightLowerLeg","LeftLowerArm","RightLowerArm"}
    for _, partName in ipairs(partsToCollide) do
        local part = char:FindFirstChild(partName)
        if part and part:IsA("BasePart") then
            part.CanCollide = true
        end
    end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local torso = char:FindFirstChild("LowerTorso")
    if hrp and torso then
        hrp.CanCollide = false
        hrp.Velocity = torso.CFrame.LookVector
    end
end

local function respawnAtDeathCFrame(player)
    if not player or not player:FindFirstChild("DeathCFrame") then return end
    local connection
    connection = player.CharacterAdded:Connect(function(char)
        if connection then
            connection:Disconnect()
            connection = nil
        end
        local hrp = char:WaitForChild("HumanoidRootPart", 5)
        if hrp and player.DeathCFrame.Value ~= CFrame.new() then
            for i = 1, 5 do
                hrp.CFrame = player.DeathCFrame.Value
                task.wait(0.01)
            end
            player.DeathCFrame.Value = CFrame.new()
        end
    end)
    player:LoadCharacter()
end

local function createRevivalPrompt(character, deadPlayer)
    if not character then return end
    local torso = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
    if not torso then return end
    if torso:FindFirstChild("ProximityPrompt") then return end
    
    local prompt = Instance.new("ProximityPrompt")
    prompt.ActionText = "Revive"
    prompt.ObjectText = ""
    prompt.HoldDuration = 2
    prompt.MaxActivationDistance = 10
    prompt.Parent = torso
    
    local connection
    connection = prompt.Triggered:Connect(function(triggeringPlayer)
        if triggeringPlayer == deadPlayer then
            return
        end
        if connection then
            connection:Disconnect()
            connection = nil
        end
        prompt:Destroy()
        respawnAtDeathCFrame(deadPlayer)
    end)
end

local function setupCharacter(character, player)
    if not character then return end
    local humanoid = character:WaitForChild("Humanoid", 5)
    if not humanoid then return end
    
    if not player:FindFirstChild("DeathCFrame") then
        local deathCFrame = Instance.new("CFrameValue")
        deathCFrame.Name = "DeathCFrame"
        deathCFrame.Value = CFrame.new()
        deathCFrame.Parent = player
    end
    
    humanoid.Died:Connect(function()
        if player:FindFirstChild("DeathCFrame") and character:FindFirstChild("HumanoidRootPart") then
            player.DeathCFrame.Value = character.HumanoidRootPart.CFrame
        end
        
        if humanoid.RigType == Enum.HumanoidRigType.R6 then
            ragdollR6(character)
        else
            ragdollR15(character)
        end
        
        task.delay(0.5, function()
            createRevivalPrompt(character, player)
        end)
    end)
end

local function setupDeathHandler(player)
    if not player then return end
    player.CharacterAdded:Connect(function(char)
        setupCharacter(char, player)
    end)
    if player.Character then
        setupCharacter(player.Character, player)
    end
end

Players.PlayerAdded:Connect(function(player)
    setupDeathHandler(player)
    task.wait()
    player:LoadCharacter()
end)

Players.PlayerRemoving:Connect(function(player)
    if player:FindFirstChild("DeathCFrame") then
        player.DeathCFrame:Destroy()
    end
end)

for _, player in pairs(Players:GetPlayers()) do
    setupDeathHandler(player)
    if not player.Character then
        task.wait()
        player:LoadCharacter()
    end
end