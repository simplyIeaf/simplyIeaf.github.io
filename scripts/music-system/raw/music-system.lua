-- made by @simplyIeaf1 on youtube

local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")

local player = Players.LocalPlayer

-- replace the ids if you want
local audioList = {
    {Id = 1840684529, Name = "Cool Vibes"},
    {Id = 1848354536, Name = "Relaxed Scene"},
    {Id = 1841647093, Name = "Life in an Elevator"}
}

local CONFIG = {
    DEFAULT_VOLUME = 0.5,
    FADE_DURATION = 1,
    SKIP_COOLDOWN = 2
}

local sounds = {}
local currentIndex = 1
local isPaused = false
local pauseTime = 0
local lastSkip = 0

-- folder to hold sounds
local folder = Instance.new("Folder")
folder.Name = "MusicFolder"
folder.Parent = player:WaitForChild("PlayerGui") -- stays client-side

-- create sounds
for _, track in ipairs(audioList) do
    local sound = Instance.new("Sound")
    sound.Name = "Sound_" .. track.Id
    sound.SoundId = "rbxassetid://" .. track.Id
    sound.Volume = CONFIG.DEFAULT_VOLUME
    sound.Looped = false
    sound.Parent = folder
    table.insert(sounds, {Track = track, Sound = sound})
end

-- tweenservice
local function fadeSound(sound, targetVolume, duration)
    local tween = TweenService:Create(sound, TweenInfo.new(duration), {Volume = targetVolume})
    tween:Play()
    return tween
end

-- play current song
local function playCurrentTrack(fadeIn)
    local current = sounds[currentIndex]
    if not current then return end

    local sound = current.Sound
    sound.TimePosition = pauseTime or 0

    if fadeIn then
        sound.Volume = 0
        sound:Play()
        fadeSound(sound, CONFIG.DEFAULT_VOLUME, CONFIG.FADE_DURATION)
    else
        sound:Play()
    end

    sound.Ended:Connect(function()
        if isPaused then return end
        pauseTime = 0
        currentIndex += 1
        if currentIndex > #sounds then
            currentIndex = 1
        end
        playCurrentTrack(true)
    end)
end

-- skip song
local function skipTrack()
    local current = sounds[currentIndex]
    if current and current.Sound.IsPlaying then
        fadeSound(current.Sound, 0, CONFIG.FADE_DURATION).Completed:Wait()
        current.Sound:Stop()
        pauseTime = 0
        currentIndex += 1
        if currentIndex > #sounds then
            currentIndex = 1
        end
        playCurrentTrack(true)
    end
end

-- handle chat commands
local function handleCommand(msg)
    local lowerMsg = msg:lower()

    if lowerMsg == "/skip" then
        if tick() - lastSkip >= CONFIG.SKIP_COOLDOWN then
            skipTrack()
            lastSkip = tick()
        end

    elseif lowerMsg == "/pause" then
        local current = sounds[currentIndex]
        if current and current.Sound.IsPlaying then
            pauseTime = current.Sound.TimePosition
            fadeSound(current.Sound, 0, CONFIG.FADE_DURATION).Completed:Wait()
            current.Sound:Pause()
            isPaused = true
        end

    elseif lowerMsg == "/resume" then
        local current = sounds[currentIndex]
        if current and not current.Sound.IsPlaying and isPaused then
            current.Sound.TimePosition = pauseTime
            current.Sound.Volume = 0
            current.Sound:Play()
            fadeSound(current.Sound, CONFIG.DEFAULT_VOLUME, CONFIG.FADE_DURATION)
            isPaused = false
        end

    elseif lowerMsg:match("^/volume%s+%d+$") then
        local vol = tonumber(lowerMsg:match("%d+"))
        if vol then
            vol = math.clamp(vol, 0, 100) / 100
            for _, s in ipairs(sounds) do
                fadeSound(s.Sound, vol, 0.5)
            end
        end
    end
end

-- chat listener (new TextChatService)
if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
    TextChatService.OnIncomingMessage = function(messageData)
        if messageData.TextSource and messageData.TextSource.UserId == player.UserId then
            handleCommand(messageData.Text)
        end
    end
else
    -- Legacy chat support
    player.Chatted:Connect(handleCommand)
end

-- start playing
playCurrentTrack(true)