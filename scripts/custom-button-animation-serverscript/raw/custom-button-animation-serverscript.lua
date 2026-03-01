local RepStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local PlayButtonAnim = RepStorage:FindFirstChild("PlayButtonAnim")
if not PlayButtonAnim then
    PlayButtonAnim = Instance.new("RemoteEvent")
    PlayButtonAnim.Name = "PlayButtonAnim"
    PlayButtonAnim.Parent = RepStorage
end

local ButtonAnimationsFolder = RepStorage:FindFirstChild("ButtonAnimations")
if not ButtonAnimationsFolder then
    ButtonAnimationsFolder = Instance.new("Folder")
    ButtonAnimationsFolder.Name = "ButtonAnimations"
    ButtonAnimationsFolder.Parent = RepStorage
end

local PlayerStates = {}

local function getAnimLength(anim)
    local length = 0
    for _, kf in ipairs(anim:GetKeyframes()) do
        if kf.Time > length then length = kf.Time end
    end
    return length
end

local function waitFor(seconds, callback)
    task.spawn(function()
        local endTime = os.clock() + seconds
        while os.clock() < endTime do
            task.wait()
        end
        callback()
    end)
end

local function getState(player)
    if not PlayerStates[player] then
        PlayerStates[player] = {
            IsPlaying = false,
            CooldownEnd = 0,
            Generation = 0,
        }
    end
    return PlayerStates[player]
end

local function fireToAll(action, targetPlayer, animName, extra)
    for _, player in ipairs(Players:GetPlayers()) do
        PlayButtonAnim:FireClient(player, action, targetPlayer, animName, extra)
    end
end

PlayButtonAnim.OnServerEvent:Connect(function(player, action, animName)
    if action ~= "Play" then return end
    if typeof(animName) ~= "string" or #animName == 0 or #animName > 50 then return end
    
    local char = player.Character
    if not char then return end
    if char:FindFirstChild("UpperTorso") then return end
    local hum = char:FindFirstChild("Humanoid")
    if not hum or hum.Health <= 0 then return end
    
    local state = getState(player)
    if state.IsPlaying or os.clock() < state.CooldownEnd then return end
    
    local anim = ButtonAnimationsFolder:FindFirstChild(animName)
    if not anim or not anim:IsA("KeyframeSequence") then return end
    
    local animLength = getAnimLength(anim)
    local cooldownTime = 2
    local totalTime = animLength + cooldownTime
    
    state.IsPlaying = true
    state.Generation += 1
    local myGen = state.Generation
    state.CooldownEnd = os.clock() + totalTime
    
    fireToAll("Play", player, animName)
    PlayButtonAnim:FireClient(player, "DisableButton", animName, totalTime)
    
    waitFor(animLength, function()
        local current = PlayerStates[player]
        if not current or current.Generation ~= myGen then return end
        current.IsPlaying = false
        fireToAll("AnimDone", player, animName)
    end)
end)

local function cancelPlayerAnim(player)
    local state = PlayerStates[player]
    if not state or not state.IsPlaying then return end
    state.IsPlaying = false
    state.Generation += 1
    state.CooldownEnd = 0
    fireToAll("AnimDone", player, "")
end

local function onPlayerAdded(player)
    player.CharacterRemoving:Connect(function()
        cancelPlayerAnim(player)
    end)
end

for _, player in ipairs(Players:GetPlayers()) do
    onPlayerAdded(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)

Players.PlayerRemoving:Connect(function(player)
    cancelPlayerAnim(player)
    PlayerStates[player] = nil
end)