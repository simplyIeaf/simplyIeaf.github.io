local Players = game:GetService("Players")

local NAME_TAG_CONFIG = {
    textSize = 24,
    textColor = Color3.fromRGB(255, 255, 255),
    backgroundColor = Color3.fromRGB(0, 0, 0),
    backgroundTransparency = 0.3,
    strokeColor = Color3.fromRGB(0, 0, 0),
    strokeTransparency = 0,
    strokeThickness = 2,
    offsetY = 1.8, 
    maxDistance = 100 
}

local ROLE_CONFIG = {
    Creator = { userIds = {12345678} },
    Developer = { userIds = {} },
    Admin = { userIds = {} },
    Moderator = { userIds = {} },
    Tester = { userIds = {} }
}

local function getPlayerRole(player)
    for roleName, roleData in pairs(ROLE_CONFIG) do
        if table.find(roleData.userIds, player.UserId) then
            return roleName
        end
    end
    return nil
end

local function createNameTag(player)
    local character = player.Character
    if not character then return end
        
    local head = character:WaitForChild("Head", 5)
    local humanoid = character:WaitForChild("Humanoid", 5)
    if not head or not humanoid then return end
            
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
        roleBillboard.Size = UDim2.new(4, 0, 0.6, 0)
        roleBillboard.StudsOffset = Vector3.new(0, NAME_TAG_CONFIG.offsetY + 0.8, 0)
        roleBillboard.AlwaysOnTop = true
        roleBillboard.MaxDistance = NAME_TAG_CONFIG.maxDistance
        roleBillboard.LightInfluence = 0
                        
        local roleLabel = Instance.new("TextLabel")
        roleLabel.Parent = roleBillboard
        roleLabel.Size = UDim2.new(1, 0, 1, 0)
        roleLabel.BackgroundTransparency = 1
        roleLabel.Text = roleName
        roleLabel.TextColor3 = NAME_TAG_CONFIG.textColor
        roleLabel.TextScaled = true
        roleLabel.Font = Enum.Font.GothamBold
                        
        local roleStroke = Instance.new("UIStroke")
        roleStroke.Parent = roleLabel
        roleStroke.Color = NAME_TAG_CONFIG.strokeColor
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
                    
    local textLabel = Instance.new("TextLabel")
    textLabel.Parent = billboardGui
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = "@" .. player.Name
    textLabel.TextColor3 = NAME_TAG_CONFIG.textColor
    textLabel.TextScaled = true
    textLabel.Font = Enum.Font.GothamBold
                    
    local textStroke = Instance.new("UIStroke")
    textStroke.Parent = textLabel
    textStroke.Color = NAME_TAG_CONFIG.strokeColor
    textStroke.Thickness = NAME_TAG_CONFIG.strokeThickness
                    
    local textSizeConstraint = Instance.new("UITextSizeConstraint")
    textSizeConstraint.Parent = textLabel
    textSizeConstraint.MaxTextSize = NAME_TAG_CONFIG.textSize
    textSizeConstraint.MinTextSize = 8
                    
    billboardGui.Parent = character
end

local function onPlayerAdded(player)
    player.CharacterAdded:Connect(function(character)
        task.wait(0.5)
        createNameTag(player)
    end)
                    
    if player.Character then
        createNameTag(player)
    end
end

Players.PlayerAdded:Connect(onPlayerAdded)

for _, player in ipairs(Players:GetPlayers()) do
    onPlayerAdded(player)
end