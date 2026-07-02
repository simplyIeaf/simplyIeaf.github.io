local tool = script.Parent

local equipSoundId = ""
local reloadSoundId = ""
local shootSoundId = ""

local function generateRandomName()
    local str = ""
    for i = 1, 8 do
        if math.random() > 0.5 then
            str = str .. string.char(math.random(65, 90))
        else
            str = str .. string.char(math.random(97, 122))
        end
    end
    return str
end

local remoteEvent = Instance.new("RemoteEvent")
remoteEvent.Name = generateRandomName()
remoteEvent.Parent = tool

local remoteFunction = Instance.new("RemoteFunction")
remoteFunction.Name = generateRandomName()
remoteFunction.Parent = tool

local CONFIG = {
    FireRate = 0.13,
    ReloadTime = 2,
    BaseDamage = 31,
    EnableHeadshots = true,
    HeadshotMultiplier = 1.7,
    FireVolume = 1,
    ReloadVolume = 0.9,
    EquipVolume = 0.6,
    TextFont = Enum.Font.SourceSansBold
}

local handle = tool:FindFirstChild("Handle")
if not handle then
    handle = Instance.new("Part")
    handle.Name = "Handle"
    handle.Parent = tool
end

local function createSound(name, id, volume)
    if id and id ~= "" then
        local sound = Instance.new("Sound")
        sound.Name = name
        sound.SoundId = id
        sound.Volume = volume
        sound.Parent = handle
    end
end

createSound("Equip", equipSoundId, CONFIG.EquipVolume)
createSound("Reload", reloadSoundId, CONFIG.ReloadVolume)
createSound("Fire", shootSoundId, CONFIG.FireVolume)

remoteFunction.OnServerInvoke = function(player)
    return CONFIG
end

remoteEvent.OnServerEvent:Connect(function(player, data)
    if typeof(data) ~= "table" then return end
    if not data.origin or not data.direction then return end
    
    local character = player.Character
    if not character then return end
    
    local equippedTool = character:FindFirstChild(tool.Name)
    if not equippedTool then return end
    
    local toolHandle = equippedTool:FindFirstChild("Handle")
    if not toolHandle then return end
    
    local distance = (data.origin - toolHandle.Position).Magnitude
    if distance > 25 then return end
    
    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = {character}
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.IgnoreWater = true
    
    local rayResult = workspace:Raycast(data.origin, data.direction * 5000, rayParams)
    
    if rayResult then
        local hitPart = rayResult.Instance
        local hitParent = hitPart:FindFirstAncestorOfClass("Model")
        
        if hitParent then
            local humanoid = hitParent:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid.Health > 0 then
                local damage = CONFIG.BaseDamage
                
                if CONFIG.EnableHeadshots and hitPart.Name == "Head" then
                    damage = damage * CONFIG.HeadshotMultiplier
                end
                
                humanoid:TakeDamage(damage)
            end
        end
    end
    
    local fireSound = toolHandle:FindFirstChild("Fire")
    if fireSound then
        fireSound:Play()
    end
end)