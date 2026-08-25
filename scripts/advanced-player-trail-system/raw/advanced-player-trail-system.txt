-- made by @simplyIeaf1 on youtube

local DifferentColors = true
local TrailLength = 1.75
local FadeTime = 2
local DebugMode = false
local RunService = game:GetService("RunService")
local TextChatService = game:GetService("TextChatService")
local Players = game:GetService("Players")
local ColorNames = {
    ["blue"] = Color3.new(0, 0, 1),
    ["darkblue"] = Color3.new(0, 0, 0.545),
    ["lightblue"] = Color3.new(0.678, 0.847, 0.902),
    ["brown"] = Color3.new(0.647, 0.165, 0.165),
    ["darkbrown"] = Color3.new(0.396, 0.102, 0.102),
    ["lightbrown"] = Color3.new(0.824, 0.412, 0.118),
    ["cyan"] = Color3.new(0, 1, 1),
    ["darkcyan"] = Color3.new(0, 0.545, 0.545),
    ["lightcyan"] = Color3.new(0.878, 1, 1),
    ["gray"] = Color3.new(0.502, 0.502, 0.502),
    ["darkgray"] = Color3.new(0.412, 0.412, 0.412),
    ["lightgray"] = Color3.new(0.827, 0.827, 0.827),
    ["green"] = Color3.new(0, 0.502, 0),
    ["darkgreen"] = Color3.new(0, 0.392, 0),
    ["lightgreen"] = Color3.new(0.565, 0.933, 0.565),
    ["magenta"] = Color3.new(1, 0, 1),
    ["darkmagenta"] = Color3.new(0.545, 0, 0.545),
    ["lightmagenta"] = Color3.new(1, 0.412, 0.706),
    ["orange"] = Color3.new(1, 0.647, 0),
    ["darkorange"] = Color3.new(1, 0.549, 0),
    ["lightorange"] = Color3.new(1, 0.804, 0.314),
    ["pink"] = Color3.new(1, 0.753, 0.796),
    ["darkpink"] = Color3.new(1, 0.078, 0.576),
    ["lightpink"] = Color3.new(1, 0.714, 0.757),
    ["purple"] = Color3.new(0.502, 0, 0.502),
    ["darkpurple"] = Color3.new(0.294, 0, 0.51),
    ["lightpurple"] = Color3.new(0.729, 0.333, 0.827),
    ["red"] = Color3.new(1, 0, 0),
    ["darkred"] = Color3.new(0.545, 0, 0),
    ["lightred"] = Color3.new(1, 0.502, 0.502),
    ["white"] = Color3.new(1, 1, 1),
    ["yellow"] = Color3.new(1, 1, 0),
    ["darkyellow"] = Color3.new(0.855, 0.647, 0),
    ["lightyellow"] = Color3.new(1, 1, 0.878),
    ["violet"] = Color3.new(0.933, 0.51, 0.933),
    ["darkviolet"] = Color3.new(0.58, 0, 0.827),
    ["lightviolet"] = Color3.new(0.937, 0.737, 0.937),
    ["gold"] = Color3.new(1, 0.843, 0),
    ["darkgold"] = Color3.new(0.722, 0.525, 0.043),
    ["lightgold"] = Color3.new(1, 0.922, 0.459),
    ["silver"] = Color3.new(0.753, 0.753, 0.753),
    ["darksilver"] = Color3.new(0.412, 0.412, 0.412),
    ["lightsilver"] = Color3.new(0.867, 0.867, 0.867)
}
local function AddTrailToCharacter(character, player)
    if not character then return end
   
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then
        task.wait(5)
        humanoid = character:FindFirstChildOfClass("Humanoid")
        if not humanoid then
            if DebugMode then warn("No humanoid found for character: " .. player.Name) end
            return
        end
    end
   
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then
        task.wait(5)
        rootPart = character:FindFirstChild("HumanoidRootPart")
        if not rootPart then
            if DebugMode then warn("No HumanoidRootPart found for character: " .. player.Name) end
            return
        end
    end
   
    local existingTrail = character:FindFirstChild("PlayerTrail", true)
    if existingTrail then
        existingTrail:Destroy()
    end
   
    local attachmentTop = Instance.new("Attachment")
    attachmentTop.Name = "TrailAttachmentTop"
    attachmentTop.Position = Vector3.new(0, TrailLength / 2, 0)
    attachmentTop.Parent = rootPart
   
    local attachmentBottom = Instance.new("Attachment")
    attachmentBottom.Name = "TrailAttachmentBottom"
    attachmentBottom.Position = Vector3.new(0, -TrailLength / 2, 0)
    attachmentBottom.Parent = rootPart
   
    local trail = Instance.new("Trail")
    trail.Name = "PlayerTrail"
    trail.Attachment0 = attachmentTop
    trail.Attachment1 = attachmentBottom
    trail.Lifetime = FadeTime
    trail.MinLength = 0.1
    trail.WidthScale = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.6),
        NumberSequenceKeypoint.new(1, 0)
    })
    trail.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(0.5, 0.5),
        NumberSequenceKeypoint.new(1, 1)
    })
    trail.LightEmission = 1
    trail.FaceCamera = false
    trail.Enabled = true
    trail.Parent = rootPart
   
    if DifferentColors then
        local hue = (math.abs(player.UserId) % 1000) / 1000
        trail.Color = ColorSequence.new(Color3.fromHSV(hue, 1, 1))
    else
        trail.Color = ColorSequence.new(Color3.new(0, 0.5, 1))
    end
   
    local connection
    connection = RunService.Heartbeat:Connect(function()
        if not character.Parent or not humanoid.Parent or humanoid.Health <= 0 or not player.Parent then
            if trail then trail:Destroy() end
            if attachmentTop then attachmentTop:Destroy() end
            if attachmentBottom then attachmentBottom:Destroy() end
            connection:Disconnect()
        end
    end)
   
    return trail
end
local trailColorCommand = Instance.new("TextChatCommand")
trailColorCommand.Name = "TrailColorCommand"
trailColorCommand.PrimaryAlias = "/trailcolor"
trailColorCommand.SecondaryAlias = "/tc"
trailColorCommand.Parent = TextChatService
trailColorCommand.Triggered:Connect(function(textSource, message)
    local player = Players:GetPlayerByUserId(textSource.UserId)
    if not player then return end
   
    local colorName = message:match("^/trailcolor%s+([%w]+)$") or message:match("^/tc%s+([%w]+)$")
    if not colorName then
        if DebugMode then warn("No color name provided by player: " .. player.Name) end
        return
    end
   
    colorName = colorName:lower()
    local color3 = ColorNames[colorName]
    if not color3 then
        if DebugMode then warn("Invalid color name: " .. colorName .. " - using default white") end
        color3 = Color3.new(1, 1, 1)
    end
   
    if player.Character then
        local trail = player.Character:FindFirstChild("PlayerTrail", true)
        if trail then
            trail.Color = ColorSequence.new(color3)
        end
    end
end)
local trailToggleCommand = Instance.new("TextChatCommand")
trailToggleCommand.Name = "TrailToggleCommand"
trailToggleCommand.PrimaryAlias = "/toggletrail"
trailToggleCommand.SecondaryAlias = "/tt"
trailToggleCommand.Parent = TextChatService
trailToggleCommand.Triggered:Connect(function(textSource)
    local player = Players:GetPlayerByUserId(textSource.UserId)
    if not player then return end
   
    if player.Character then
        local trail = player.Character:FindFirstChild("PlayerTrail", true)
        if trail then
            trail.Enabled = not trail.Enabled
        end
    end
end)
for _, player in ipairs(Players:GetPlayers()) do
    if player.Character then
        task.spawn(function()
            AddTrailToCharacter(player.Character, player)
        end)
    end
    player.CharacterAdded:Connect(function(character)
        task.spawn(function()
            AddTrailToCharacter(character, player)
        end)
    end)
end
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(character)
        task.spawn(function()
            AddTrailToCharacter(character, player)
        end)
    end)
end)
Players.PlayerRemoving:Connect(function(player)
    if player.Character then
        local trail = player.Character:FindFirstChild("PlayerTrail", true)
        if trail then
            trail:Destroy()
        end
        local attachmentTop = player.Character:FindFirstChild("TrailAttachmentTop", true)
        if attachmentTop then
            attachmentTop:Destroy()
        end
        local attachmentBottom = player.Character:FindFirstChild("TrailAttachmentBottom", true)
        if attachmentBottom then
            attachmentBottom:Destroy()
        end
    end
end)