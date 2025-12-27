-- Place this in ServerScriptService
 
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
 
-- Configuration
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
 
-- Function to get player role
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
 
-- Function to create a name tag
local function createNameTag(player)
    local character = player.Character
    if not character then return end
        
        local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
        local head = character:FindFirstChild("Head")
        local humanoid = character:FindFirstChild("Humanoid")
        if not humanoidRootPart or not head or not humanoid then return end
            
            -- Hide default Roblox name tag
            humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
            
            -- Remove existing name tags if they exist
            local existingTag = character:FindFirstChild("NameTag")
            local existingRoleTag = character:FindFirstChild("RoleTag")
            if existingTag then existingTag:Destroy() end
                if existingRoleTag then existingRoleTag:Destroy() end
                    
                    -- Check if player has a role
                    local roleName = getPlayerRole(player)
                    
                    -- Create role tag if player has a role
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
                        
                        -- Create background frame for role (transparent)
                        local roleFrame = Instance.new("Frame")
                        roleFrame.Parent = roleBillboard
                        roleFrame.Size = UDim2.new(1, 0, 1, 0)
                        roleFrame.Position = UDim2.new(0, 0, 0, 0)
                        roleFrame.BackgroundTransparency = 1
                        roleFrame.BorderSizePixel = 0
                        
                        -- Add corner rounding to role frame (removed since frame is transparent)
                        
                        -- Create role text label (same colors as main name tag)
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
                        
                        -- Add text stroke for role
                        local roleStroke = Instance.new("UIStroke")
                        roleStroke.Parent = roleLabel
                        roleStroke.Color = NAME_TAG_CONFIG.strokeColor
                        roleStroke.Transparency = NAME_TAG_CONFIG.strokeTransparency
                        roleStroke.Thickness = NAME_TAG_CONFIG.strokeThickness
                        
                        -- Add text size constraint for role
                        local roleSizeConstraint = Instance.new("UITextSizeConstraint")
                        roleSizeConstraint.Parent = roleLabel
                        roleSizeConstraint.MaxTextSize = NAME_TAG_CONFIG.textSize * 0.7
                        roleSizeConstraint.MinTextSize = 6
                        
                        -- Parent role tag to character
                        roleBillboard.Parent = character
                    end
                    
                    -- Create main BillboardGui
                    local billboardGui = Instance.new("BillboardGui")
                    billboardGui.Name = "NameTag"
                    billboardGui.Adornee = head
                    billboardGui.Size = UDim2.new(4, 0, 1, 0)
                    billboardGui.StudsOffset = Vector3.new(0, NAME_TAG_CONFIG.offsetY, 0)
                    billboardGui.AlwaysOnTop = true
                    billboardGui.MaxDistance = NAME_TAG_CONFIG.maxDistance
                    billboardGui.LightInfluence = 0
                    billboardGui.SizeOffset = Vector2.new(0, 0)
                    
                    -- Create background frame (transparent)
                    local frame = Instance.new("Frame")
                    frame.Parent = billboardGui
                    frame.Size = UDim2.new(1, 0, 1, 0)
                    frame.Position = UDim2.new(0, 0, 0, 0)
                    frame.BackgroundTransparency = 1
                    frame.BorderSizePixel = 0
                    
                    -- Add corner rounding (removed since frame is transparent)
                    
                    -- Create text label
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
                    
                    -- Add text stroke for better visibility
                    local textStroke = Instance.new("UIStroke")
                    textStroke.Parent = textLabel
                    textStroke.Color = NAME_TAG_CONFIG.strokeColor
                    textStroke.Transparency = NAME_TAG_CONFIG.strokeTransparency
                    textStroke.Thickness = NAME_TAG_CONFIG.strokeThickness
                    
                    -- Add text size constraint
                    local textSizeConstraint = Instance.new("UITextSizeConstraint")
                    textSizeConstraint.Parent = textLabel
                    textSizeConstraint.MaxTextSize = NAME_TAG_CONFIG.textSize
                    textSizeConstraint.MinTextSize = 8
                    
                    -- Parent to character
                    billboardGui.Parent = character
                end
                
                -- Function to handle player joining
                local function onPlayerAdded(player)
                    -- Wait for character to spawn
                    local function onCharacterAdded(character)
                        -- Wait a bit for character to fully load
                        wait(0.5)
                        createNameTag(player)
                    end
                    
                    -- Connect to character spawning
                    player.CharacterAdded:Connect(onCharacterAdded)
                    
                    -- If character already exists
                    if player.Character then
                        onCharacterAdded(player.Character)
                    end
                end
                
                -- Function to handle player leaving
                local function onPlayerRemoving(player)
                    -- Cleanup is automatic when character is removed
                end
                
                -- Connect events
                Players.PlayerAdded:Connect(onPlayerAdded)
                Players.PlayerRemoving:Connect(onPlayerRemoving)
                
                -- Handle players already in game
                for _, player in pairs(Players:GetPlayers()) do
                    onPlayerAdded(player)
                end
                