local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local CHAR_FOLDER_NAME = "Characters"
local REMOTE_NAME = "CharacterSelectEvent"
local PREVIEW_FOLDER_NAME = "ClientCharacterPreviews"

local remoteEvent = ReplicatedStorage:FindFirstChild(REMOTE_NAME)
if not remoteEvent then
    remoteEvent = Instance.new("RemoteEvent")
    remoteEvent.Name = REMOTE_NAME
    remoteEvent.Parent = ReplicatedStorage
end

local previewFolder = ReplicatedStorage:FindFirstChild(PREVIEW_FOLDER_NAME)
if previewFolder then previewFolder:Destroy() end
previewFolder = Instance.new("Folder")
previewFolder.Name = PREVIEW_FOLDER_NAME
previewFolder.Parent = ReplicatedStorage

local success, serverCharFolder = pcall(function()
    return ServerStorage:WaitForChild(CHAR_FOLDER_NAME)
end)

if not success or not serverCharFolder then
    error("FATAL ERROR: Could not find '" .. CHAR_FOLDER_NAME .. "' folder in ServerStorage. Morphing system is disabled.")
end

local function updatePreviews()
    previewFolder:ClearAllChildren()
    
    for _, charFolder in ipairs(serverCharFolder:GetChildren()) do
        local rigFound = nil
        for _, child in ipairs(charFolder:GetChildren()) do
            if child:IsA("Model") and child:FindFirstChild("Humanoid") then
                rigFound = child
                break
            end
        end
        
        if rigFound then
            local s, e = pcall(function()
                local slotData = Instance.new("Model")
                slotData.Name = charFolder.Name
                slotData.Parent = previewFolder
                
                local visualRig = rigFound:Clone()
                visualRig.Name = "VisualRig"
                
                for _, d in pairs(visualRig:GetDescendants()) do
                    if d:IsA("Script") or d:IsA("LocalScript") or d:IsA("Tool") then
                        d:Destroy()
                    elseif d:IsA("BasePart") then
                        d.Anchored = true
                        d.CanCollide = false
                    end
                end
                
                visualRig.Parent = slotData
                
                -- **IMPROVEMENT START:** Copy ImageLabel for client view
                for _, item in ipairs(charFolder:GetChildren()) do
                    if item:IsA("ImageLabel") then
                        item:Clone().Parent = slotData
                    end
                end
                -- **IMPROVEMENT END**
            end)
            if not s then warn("Error creating preview: " .. e) end
        end
    end
end

updatePreviews()

local function onCharacterAdded(character)
    local player = Players:GetPlayerFromCharacter(character)
    if not player then return end
    
    if player:GetAttribute("IsMorphing") == true then
        return 
    end
    
    pcall(function()
        task.wait(0.2) 
        local hum = character:WaitForChild("Humanoid", 5)
        local hrp = character:WaitForChild("HumanoidRootPart", 5)
        
        if hum and hrp then
            hum.WalkSpeed = 0
            hum.JumpPower = 0
            hrp.Anchored = true
            
            local ff = Instance.new("ForceField")
            ff.Name = "LobbyProtection"
            ff.Visible = true
            ff.Parent = character
        end
    end)
end

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(onCharacterAdded)
end)

remoteEvent.OnServerEvent:Connect(function(player, charName)
    if not player or not player.Character then return end
    
    local success, err = pcall(function()
        player:SetAttribute("IsMorphing", true) 
        
        local targetFolder = serverCharFolder:FindFirstChild(charName)
        if not targetFolder then error("Invalid Character Name: " .. charName) end
        
        local morphModel = nil
        for _, child in ipairs(targetFolder:GetChildren()) do
            if child:IsA("Model") and child:FindFirstChild("Humanoid") then
                morphModel = child
                break
            end
        end
        if not morphModel then error("No Valid Model Found in folder: " .. charName) end
        
        local character = player.Character
        local humanoid = character:WaitForChild("Humanoid", 5)
        local hrp = character:WaitForChild("HumanoidRootPart", 5)
        
        if not humanoid or not hrp then error("Character missing Humanoid or HumanoidRootPart") end
        
        local morphClone = morphModel:Clone()
        morphClone.Parent = Workspace
        
        task.wait(1)
        
        local morphHumanoid = morphClone:FindFirstChild("Humanoid")
        if morphHumanoid then
            local desc = morphHumanoid:GetAppliedDescription()
            humanoid:ApplyDescription(desc)
        end
        
        morphClone:Destroy()
        
        local backpack = player:FindFirstChild("Backpack")
        if backpack then backpack:ClearAllChildren() end
        
        for _, item in ipairs(targetFolder:GetChildren()) do
            if item:IsA("Tool") then
                item:Clone().Parent = backpack
            end
        end
        
        task.wait(0.5)
        
        if humanoid then
            humanoid.WalkSpeed = 16
            humanoid.JumpPower = 50
        end
        
        if hrp then
            hrp.Anchored = false 
        end
        
        local ff = character:FindFirstChild("LobbyProtection")
        if ff then ff:Destroy() end
        
        player:SetAttribute("IsMorphing", false)
    end)
    
    if not success then 
        warn("Server Morph failed: " .. err)
        player:SetAttribute("IsMorphing", false)
    end
end)