-- made by @simplyIeaf1 on youtube

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserService = game:GetService("UserService")
local GroupService = game:GetService("GroupService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local getPlatformRemote = Instance.new("RemoteFunction")
getPlatformRemote.Name = "GetPlayerPlatform"
getPlatformRemote.Parent = ReplicatedStorage

local playerPlatforms = {}

local NAME_TAG_CONFIG = {
    textSize = 24,
    textColor = Color3.fromRGB(255, 255, 255),
    backgroundColor = Color3.fromRGB(0, 0, 0),
    backgroundTransparency = 0.3,
    strokeColor = Color3.fromRGB(0, 0, 0),
    strokeTransparency = 0,
    strokeThickness = 2,
    offsetY = 1.8,
    maxDistance = 100,
    showAllIconsForOwners = false,
    idleThreshold = 30,
    iconSidePaddingScale = 0.05,
    iconSpacingScale = 0.02,
    iconScale = 0.75
}

local OWNER_USERNAMES = {
    "yourusername1",
    "yourusername2",
    "yourusername3"
}

local ROLE_ICONS = {
    mobile = "rbxthumb://type=Asset&id=14040313905&w=150&h=150",
    pc = "rbxthumb://type=Asset&id=14040311081&w=150&h=150",
    controller = "rbxthumb://type=Asset&id=12684121195&w=150&h=150",
    verified = "rbxthumb://type=Asset&id=105931397495778&w=150&h=150",
    owner = "rbxthumb://type=Asset&id=11322089619&w=150&h=150",
    premium = "rbxthumb://type=Asset&id=6071020689&w=150&h=150",
    starCreator = "rbxthumb://type=Asset&id=11322155024&w=150&h=150"
}

local function isOwner(player)
    local playerName = string.lower(player.Name)
    for _, ownerName in pairs(OWNER_USERNAMES) do
        if string.lower(ownerName) == playerName then
            return true
        end
    end
    return false
end

local function isStarCreator(player)
    local success, result = pcall(function()
        return player:GetRoleInGroup(4199740) == "Video Star"
    end)
    return success and result or false
end

local function isVerified(player)
    local success, hasVerifiedBadge = pcall(function()
        return player.HasVerifiedBadge
    end)
    return success and hasVerifiedBadge or false
end

local function hasPremium(player)
    local success, membershipType = pcall(function()
        return player.MembershipType
    end)
    return success and membershipType == Enum.MembershipType.Premium
end

local function getPlayerPlatform(player)
    -- Check if platform is already stored
    if playerPlatforms[player.UserId] then
        return playerPlatforms[player.UserId]
    end
    -- Query client for platform with retry
    local success, platform
    for _ = 1, 3 do
        success, platform = pcall(function()
            return getPlatformRemote:InvokeClient(player)
        end)
        if success and platform then
            break
        end
        task.wait(0.5)
    end
    if success and platform then
        playerPlatforms[player.UserId] = platform
        warn("Stored platform for " .. player.Name .. ": " .. platform)
        return platform
    else
        warn("Failed to get platform for " .. player.Name .. ", defaulting to pc")
        playerPlatforms[player.UserId] = "pc"
        return "pc"
    end
end

local function getPlayerRoleIcons(player)
    local icons = {}
    if isOwner(player) and NAME_TAG_CONFIG.showAllIconsForOwners then
        for _, iconUrl in pairs(ROLE_ICONS) do
            table.insert(icons, iconUrl)
        end
        return icons
    end
    if isOwner(player) then
        table.insert(icons, ROLE_ICONS.owner)
    end
    if isVerified(player) then
        table.insert(icons, ROLE_ICONS.verified)
    end
    if isStarCreator(player) then
        table.insert(icons, ROLE_ICONS.starCreator)
    end
    if hasPremium(player) then
        table.insert(icons, ROLE_ICONS.premium)
    end
    local platform = getPlayerPlatform(player)
    if platform == "mobile" then
        table.insert(icons, ROLE_ICONS.mobile)
    elseif platform == "controller" then
        table.insert(icons, ROLE_ICONS.controller)
    else
        table.insert(icons, ROLE_ICONS.pc)
    end
    return icons
end

local function createRoleIcons(player, head)
    local icons = getPlayerRoleIcons(player)
    if #icons == 0 then return end
    
    local roleIconsBillboard = Instance.new("BillboardGui")
    roleIconsBillboard.Name = "RoleIcons"
    roleIconsBillboard.Adornee = head
    roleIconsBillboard.Size = UDim2.new(6.5, 0, 1, 0)
    roleIconsBillboard.StudsOffset = Vector3.new(0, NAME_TAG_CONFIG.offsetY + 0.8, 0)
    roleIconsBillboard.AlwaysOnTop = true
    roleIconsBillboard.MaxDistance = NAME_TAG_CONFIG.maxDistance
    roleIconsBillboard.LightInfluence = 0
    
    local iconsFrame = Instance.new("Frame")
    iconsFrame.Parent = roleIconsBillboard
    iconsFrame.Size = UDim2.new(1, 0, 1, 0)
    iconsFrame.Position = UDim2.new(0, 0, 0, 0)
    iconsFrame.BackgroundTransparency = 1
    iconsFrame.BorderSizePixel = 0
    
    local listLayout = Instance.new("UIListLayout")
    listLayout.Parent = iconsFrame
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.FillDirection = Enum.FillDirection.Horizontal
    listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    listLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    listLayout.Padding = UDim.new(NAME_TAG_CONFIG.iconSpacingScale, 0)
    
    local padding = Instance.new("UIPadding")
    padding.Parent = iconsFrame
    padding.PaddingLeft = UDim.new(NAME_TAG_CONFIG.iconSidePaddingScale, 0)
    padding.PaddingRight = UDim.new(NAME_TAG_CONFIG.iconSidePaddingScale, 0)
    
    for i, iconUrl in pairs(icons) do
        local iconImage = Instance.new("ImageLabel")
        iconImage.Name = "RoleIcon" .. i
        iconImage.Parent = iconsFrame
        iconImage.Size = UDim2.new(NAME_TAG_CONFIG.iconScale, 0, NAME_TAG_CONFIG.iconScale, 0)
        iconImage.BackgroundTransparency = 1
        iconImage.Image = iconUrl
        iconImage.ScaleType = Enum.ScaleType.Fit
        iconImage.LayoutOrder = i
        
        local aspect = Instance.new("UIAspectRatioConstraint")
        aspect.Parent = iconImage
        aspect.AspectRatio = 1
        
        local iconCorner = Instance.new("UICorner")
        iconCorner.Parent = iconImage
        iconCorner.CornerRadius = UDim.new(0, 4)
    end
    
    return roleIconsBillboard
end

local function createAFKTag(head)
    local afkBillboard = Instance.new("BillboardGui")
    afkBillboard.Name = "AFKTag"
    afkBillboard.Adornee = head
    afkBillboard.Size = UDim2.new(4, 0, 1, 0)
    afkBillboard.StudsOffset = Vector3.new(0, NAME_TAG_CONFIG.offsetY + 1.6, 0)
    afkBillboard.AlwaysOnTop = true
    afkBillboard.MaxDistance = NAME_TAG_CONFIG.maxDistance
    afkBillboard.LightInfluence = 0
    afkBillboard.Enabled = false
    
    local frame = Instance.new("Frame")
    frame.Parent = afkBillboard
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.Position = UDim2.new(0, 0, 0, 0)
    frame.BackgroundTransparency = 1
    frame.BorderSizePixel = 0
    
    local textLabel = Instance.new("TextLabel")
    textLabel.Parent = frame
    textLabel.Size = UDim2.new(1, -10, 1, 0)
    textLabel.Position = UDim2.new(0, 5, 0, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = "AFK - 00:00"
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
    
    return afkBillboard, textLabel
end

local function createNameTag(player)
    local character = player.Character
    if not character then return end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    local head = character:FindFirstChild("Head")
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoidRootPart or not head or not humanoid then return end
    
    humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
    
    -- Destroy existing tags
    local existingTag = character:FindFirstChild("NameTag")
    local existingRoleIcons = character:FindFirstChild("RoleIcons")
    local existingAFKTag = character:FindFirstChild("AFKTag")
    if existingTag then existingTag:Destroy() end
    if existingRoleIcons then existingRoleIcons:Destroy() end
    if existingAFKTag then existingAFKTag:Destroy() end
    
    -- Create role icons using stored platform
    local roleIconsBillboard = createRoleIcons(player, head)
    if roleIconsBillboard then
        roleIconsBillboard.Parent = character
    end
    
    -- Create name tag
    local billboardGui = Instance.new("BillboardGui")
    billboardGui.Name = "NameTag"
    billboardGui.Adornee = head
    billboardGui.Size = UDim2.new(4, 0, 1, 0)
    billboardGui.StudsOffset = Vector3.new(0, NAME_TAG_CONFIG.offsetY, 0)
    billboardGui.AlwaysOnTop = true
    billboardGui.MaxDistance = NAME_TAG_CONFIG.maxDistance
    billboardGui.LightInfluence = 0
    
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
    
    -- Create AFK tag
    local afkBillboard, afkTextLabel = createAFKTag(head)
    afkBillboard.Parent = character
    
    -- Handle AFK monitoring
    local lastPosition = humanoidRootPart.Position
    local idleStartTime = nil
    local afkTimer = 0
    
    local monitorConnection
    monitorConnection = RunService.Heartbeat:Connect(function(dt)
        if not character or not character.Parent or not humanoidRootPart or not humanoid or humanoid.Health <= 0 then
            if monitorConnection then
                monitorConnection:Disconnect()
            end
            return
        end
        
        local currentPosition = humanoidRootPart.Position
        if (currentPosition - lastPosition).Magnitude > 0.1 or humanoid.MoveDirection.Magnitude > 0 then
            lastPosition = currentPosition
            idleStartTime = nil
            afkTimer = 0
            afkBillboard.Enabled = false
        else
            if not idleStartTime then
                idleStartTime = os.clock()
            end
            local idleTime = os.clock() - idleStartTime
            if idleTime >= NAME_TAG_CONFIG.idleThreshold then
                afkTimer = afkTimer + dt
                local minutes = math.floor(afkTimer / 60)
                local seconds = math.floor(afkTimer % 60)
                afkTextLabel.Text = string.format("AFK - %02d:%02d", minutes, seconds)
                afkBillboard.Enabled = true
            end
        end
    end)
    
    -- Handle player death and respawn
    local diedConnection
    diedConnection = humanoid.Died:Connect(function()
        if monitorConnection then
            monitorConnection:Disconnect()
        end
        if diedConnection then
            diedConnection:Disconnect()
        end
        -- Wait for the new character to spawn
        local newCharacter = player.CharacterAdded:Wait()
        if newCharacter then
            task.wait(0.5) -- Ensure character is fully loaded
            warn("Recreating name tag for " .. player.Name .. " after respawn with platform: " .. (playerPlatforms[player.UserId] or "unknown"))
            createNameTag(player) -- Recreate name tag using stored platform
        end
    end)
end

local function onPlayerAdded(player)
    local function onCharacterAdded(character)
        task.wait(0.5) -- Initial delay to ensure character is fully loaded
        -- Get and store platform on first spawn
        getPlayerPlatform(player) -- Ensure platform is stored
        createNameTag(player)
    end
    
    player.CharacterAdded:Connect(onCharacterAdded)
    if player.Character then
        onCharacterAdded(player.Character)
    end
end

local function onPlayerRemoving(player)
    -- Clean up stored platform data
    playerPlatforms[player.UserId] = nil
    warn("Removed platform data for " .. player.Name)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

for _, player in pairs(Players:GetPlayers()) do
    onPlayerAdded(player)
end