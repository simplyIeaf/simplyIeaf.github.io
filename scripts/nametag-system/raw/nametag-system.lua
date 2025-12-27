local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
 
local NAME_TAG_CONFIG = {
textSize = 24,
textColor = Color3.fromRGB(255, 255, 255),
backgroundColor = Color3.fromRGB(0, 0, 0),
backgroundTransparency = 0.3,
strokeColor = Color3.fromRGB(0, 0, 0),
strokeTransparency = 0,
strokeThickness = 2,
offsetY = 1.8, -- Distance above player's head
maxDistance = 100 -- Maximum distance to show name tag
}
 
-- Role Configuration - Add User IDs here
local ROLE_CONFIG = {
Creator = {
userIds = {} -- Add creator user IDs here
},
Developer = {
userIds = {} -- Add developer user IDs here
},
Admin = {
userIds = {} -- Add admin user IDs here
},
Moderator = {
userIds = {} -- Add moderator user IDs here
},
Tester = {
userIds = {} -- Add tester user IDs here
}
}
 
local function getPlayerRole(player)
    for roleName, roleData in pairs(ROLE_CONFIG) do
        for _, userId in pairs(roleData.userIds) do
            if player.UserId == userId then
                return roleName
            end
        end
    end
    return nil
end
 
local function createNameTag(player)
    local character = player.Character
    if not character then return end
        
        local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
        local head = character:FindFirstChild("Head")
        local humanoid = character:FindFirstChild("Humanoid")
        if not humanoidRootPart or not head or not humanoid then return end
            
            humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
            
            local existingTag = character:FindFirstChild("NameTag")
            local existingRoleTag = character:FindFirstChild("RoleTag")
            if existingTag then existingTag:Destroy() end
                if existingRoleTag then existingRoleTag:Destroy() end
                    
                    local roleName = getPlayerRole(player)
                    
                    if roleName then
                        local roleBillboard = Instance.new("BillboardGui")
                        roleBillboard.Name = "RoleTag"
                        roleBillboard.Adornee = head
                        roleBillboard.Size = UDim2.new(2, 0, 0.4, 0) -- Smaller than main name tag
                        roleBillboard.StudsOffset = Vector3.new(0, NAME_TAG_CONFIG.offsetY + 0.75, 0) -- Above main name tag
                        roleBillboard.AlwaysOnTop = true
                        roleBillboard.MaxDistance = NAME_TAG_CONFIG.maxDistance
                        roleBillboard.LightInfluence = 0
                        roleBillboard.SizeOffset = Vector2.new(0, 0)
                        
                        local roleFrame = Instance.new("Frame")
                        roleFrame.Parent = roleBillboard
                        roleFrame.Size = UDim2.new(1, 0, 1, 0)
                        roleFrame.Position = UDim2.new(0, 0, 0, 0)
                        roleFrame.BackgroundTransparency = 1
                        roleFrame.BorderSizePixel = 0
                        
                        
                        local roleLabel = Instance.new("TextLabel")
                        roleLabel.Parent = roleFrame
                        roleLabel.Size = UDim2.new(1, -8, 1, 0)
                        roleLabel.Position = UDim2.new(0, 4, 0, 0)
                        roleLabel.BackgroundTransparency = 1
                        roleLabel.Text = roleName
                        roleLabel.TextColor3 = NAME_TAG_CONFIG.textColor
                        roleLabel.TextSize = NAME_TAG_CONFIG.textSize * 0.7 -- Smaller text
                        roleLabel.TextScaled = true
                        roleLabel.Font = Enum.Font.GothamBold
                        
                        local roleStroke = Instance.new("UIStroke")
                        roleStroke.Parent = roleLabel
                        roleStroke.Color = NAME_TAG_CONFIG.strokeColor
                        roleStroke.Transparency = NAME_TAG_CONFIG.strokeTransparency
                        roleStroke.Thickness = NAME_TAG_CONFIG.strokeThickness
                        
                        local roleSizeConstraint = Instance.new("UITextSizeConstraint")
                        roleSizeConstraint.Parent = roleLabel
                        roleSizeConstraint.MaxTextSize = NAME_TAG_CONFIG.textSize * 0.7
                        roleSizeConstraint.MinTextSize = 6
                        
                        roleBillboard.Parent = character
                    end
                    
                    local billboardGui = Instance.new("BillboardGui")
                    billboardGui.Name = "NameTag"
                    billboardGui.Adornee = head
                    billboardGui.Size = UDim2.new(4, 0, 1, 0)
                    billboardGui.StudsOffset = Vector3.new(0, NAME_TAG_CONFIG.offsetY, 0)
                    billboardGui.AlwaysOnTop = true
                    billboardGui.MaxDistance = NAME_TAG_CONFIG.maxDistance
                    billboardGui.LightInfluence = 0
                    billboardGui.SizeOffset = Vector2.new(0, 0)
                    
                    local frame = Instance.new("Frame")
                    frame.Parent = billboardGui
                    frame.Size = UDim2.new(1, 0, 1, 0)
                    frame.Position = UDim2.new(0, 0, 0, 0)
                    frame.BackgroundTransparency = 1
                    frame.BorderSizePixel = 0
                    
                    
                    local textLabel = Instance.new("TextLabel")
                    textLabel.Parent = frame
                    textLabel.Size = UDim2.new(1, -10, 1, 0)
                    textLabel.Position = UDim2.new(0, 5, 0, 0)
                    textLabel.BackgroundTransparency = 1
                    textLabel.Text = "@" .. player.Name
                    textLabel.TextColor3 = NAME_TAG_CONFIG.textColor
                    textLabel.TextSize = NAME_TAG_CONFIG.textSize
                    textLabel.TextScaled = true
                    textLabel.Font = Enum.Font.GothamBold
                    
                    local textStroke = Instance.new("UIStroke")
                    textStroke.Parent = textLabel
                    textStroke.Color = NAME_TAG_CONFIG.strokeColor
                    textStroke.Transparency = NAME_TAG_CONFIG.strokeTransparency
                    textStroke.Thickness = NAME_TAG_CONFIG.strokeThickness
                    
                    local textSizeConstraint = Instance.new("UITextSizeConstraint")
                    textSizeConstraint.Parent = textLabel
                    textSizeConstraint.MaxTextSize = NAME_TAG_CONFIG.textSize
                    textSizeConstraint.MinTextSize = 8
                    
                    billboardGui.Parent = character
                end
                
                local function onPlayerAdded(player)
                    local function onCharacterAdded(character)
                        wait(0.5)
                        createNameTag(player)
                    end
                    
                    player.CharacterAdded:Connect(onCharacterAdded)
                    
                    if player.Character then
                        onCharacterAdded(player.Character)
                    end
                end
                
                local function onPlayerRemoving(player)
                    -- remove is automatic when character is removed
                end
                
                Players.PlayerAdded:Connect(onPlayerAdded)
                Players.PlayerRemoving:Connect(onPlayerRemoving)
                
                for _, player in pairs(Players:GetPlayers()) do
                    onPlayerAdded(player)
                end
            