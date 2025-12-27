-- made by @simplyieaf1 on youtube
-- place in startercharacterscripts instead of starterplayerscripts

local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")

local RoleConfig = {
[8033814042] = {Tag = "Owner", Color = "#FF0000", Priority = 7},
[67890] = {Tag = "Admin", Color = "#0000FF", Priority = 6},
[11111] = {Tag = "Contributor", Color = "#800080", Priority = 2},
[22222] = {Tag = "Developer", Color = "#00CED1", Priority = 4},
[33333] = {Tag = "Scripter", Color = "#FF4500", Priority = 3},
[44444] = {Tag = "Moderator", Color = "#228B22", Priority = 5},
[55555] = {Tag = "Tester", Color = "#4169E1", Priority = 1},
}

local TagFormat = "[%s] "

local function color3ToRgb(color3)
    local r = math.floor(color3.R * 255 + 0.5)
    local g = math.floor(color3.G * 255 + 0.5)
    local b = math.floor(color3.B * 255 + 0.5)
    return string.format("rgb(%d,%d,%d)", r, g, b)
end

local function createColoredTag(tag, color)
    local color3
    if type(color) == "string" then
        local success, result = pcall(function()
            return Color3.fromHex(color)
        end)
        if success then
            color3 = result
        else
            color3 = Color3.new(1, 1, 1)
        end
    else
        color3 = Color3.new(1, 1, 1)
    end
    
    local rgbColor = color3ToRgb(color3)
    local formattedTag = string.format(TagFormat, tag)
    local coloredTag = string.format('<font color="%s">%s</font>', rgbColor, formattedTag)
    
    return coloredTag
end

local function getHighestPriorityRole(userId)
    local roleData = RoleConfig[userId]
    if roleData and roleData.Priority then
        return roleData
    end
    return nil
end

TextChatService.OnIncomingMessage = function(message)
    local textSource = message.TextSource
    if not textSource then
        return nil
    end
    
    local player = Players:GetPlayerByUserId(textSource.UserId)
    if not player then
        return nil
    end
    
    local roleData = getHighestPriorityRole(player.UserId)
    if roleData then
        local overrideProperties = Instance.new("TextChatMessageProperties")
        local coloredTag = createColoredTag(roleData.Tag, roleData.Color)
        overrideProperties.PrefixText = coloredTag .. (message.PrefixText or "")
        return overrideProperties
    end
    
    return nil
end