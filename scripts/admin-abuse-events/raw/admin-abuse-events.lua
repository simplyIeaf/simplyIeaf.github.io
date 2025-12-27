-- made by @simplyIeaf1 on youtube

local EVENTS = {
    DiscoEvent = {
        TopicName = "DiscoEvent",
        Command = "?globaldisco",
        AnimIds = {"rbxassetid://182435998", "rbxassetid://182436842"},
        SoundId = "rbxassetid://142376088",
        FadeInDuration = 2,
        FadeOutDuration = 2,
        MaxVolume = 0.75,
        DiscoSpeed = 1
    },
    BlackholeEvent = {
        TopicName = "BlackholeEvent",
        Command = "?globalblackhole",
        AnimIds = {},
        SoundId = "rbxassetid://1837835120",
        FadeInDuration = 1.5,
        FadeOutDuration = 1.5,
        MaxVolume = 0.6,
        LowGravityValue = 75,
        DefaultGravity = 196.2,
        GravityTweenTime = 2,
        TransitionTime = 2,
        EffectDuration = 60
    }
}

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local MessagingService = game:GetService("MessagingService")

local adminUserIds = {8033814042}
local isEventActive = false

local STARRY_SKYBOX = {
    SkyboxBk = "rbxassetid://1012894",
    SkyboxDn = "rbxassetid://1012895",
    SkyboxFt = "rbxassetid://1012892",
    SkyboxLf = "rbxassetid://1012893",
    SkyboxRt = "rbxassetid://1012890",
    SkyboxUp = "rbxassetid://1012891"
}

local function startEvent(eventName, triggeringPlayerName)
    if isEventActive then return end
    local config = EVENTS[eventName]
    if not config then return end
    isEventActive = true
    
    local originalSettings = {
        Gravity = workspace.Gravity,
        Ambient = Lighting.Ambient,
        Brightness = Lighting.Brightness,
        Sky = Lighting:FindFirstChildOfClass("Sky"),
        ColorCorrection = Lighting:FindFirstChildOfClass("ColorCorrectionEffect")
    }
    
    local topicName = config.TopicName
    local eventData = { originalSettings = originalSettings, animTracks = {} }
    
    local sound = nil
    if config.SoundId then
        sound = Instance.new("Sound")
        sound.Name = eventName .. "Sound"
        sound.Parent = workspace
        sound.SoundId = config.SoundId
        sound.Volume = 0
        sound:Play()
        
        local fadeInInfo = TweenInfo.new(config.FadeInDuration, Enum.EasingStyle.Linear)
        local fadeInTween = TweenService:Create(sound, fadeInInfo, {Volume = config.MaxVolume})
        fadeInTween:Play()
        eventData.sound = sound
    end
    
    if eventName == "DiscoEvent" then
        local discoConnection = RunService.Heartbeat:Connect(function()
            local hue = (tick() * config.DiscoSpeed) % 1
            Lighting.Ambient = Color3.fromHSV(hue, 1, 1)
            Lighting.Brightness = 2
        end)
        eventData.connection = discoConnection
        
        for _, player in ipairs(Players:GetPlayers()) do
            local character = player.Character
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                local animId
                if humanoid.RigType == Enum.HumanoidRigType.R15 then
                    animId = "rbxassetid://507771955"
                else
                    animId = config.AnimIds[math.random(1, #config.AnimIds)]
                end
                local animationObj = Instance.new("Animation")
                animationObj.AnimationId = animId
                local animTrack = humanoid:LoadAnimation(animationObj)
                animTrack.Looped = true
                animTrack.Priority = Enum.AnimationPriority.Action
                animTrack:Play()
                table.insert(eventData.animTracks, {track = animTrack, obj = animationObj})
            end
        end
        
        if sound then
            local soundDuration = sound.TimeLength
            if soundDuration <= 10 then
                soundDuration = 95 
            end
            wait(1)
            spawn(function()
                wait(soundDuration + config.FadeOutDuration)
                local fadeOutInfo = TweenInfo.new(config.FadeOutDuration, Enum.EasingStyle.Linear)
                local fadeOutTween = TweenService:Create(sound, fadeOutInfo, {Volume = 0})
                fadeOutTween:Play()
                fadeOutTween.Completed:Wait()
                sound:Stop()
                sound:Destroy()
                if eventData.connection then
                    eventData.connection:Disconnect()
                end
                for _, animData in ipairs(eventData.animTracks) do
                    animData.track:Stop(0)
                    animData.obj:Destroy()
                end
                Lighting.Ambient = originalSettings.Ambient
                Lighting.Brightness = originalSettings.Brightness
                isEventActive = false
            end)
        else
            wait(30)
            if eventData.connection then
                eventData.connection:Disconnect()
            end
            for _, animData in ipairs(eventData.animTracks) do
                animData.track:Stop(0)
                animData.obj:Destroy()
            end
            Lighting.Ambient = originalSettings.Ambient
            Lighting.Brightness = originalSettings.Brightness
            isEventActive = false
        end
        
    elseif eventName == "BlackholeEvent" then
        local colorCorrection = originalSettings.ColorCorrection
        if not colorCorrection then
            colorCorrection = Instance.new("ColorCorrectionEffect")
            colorCorrection.Parent = Lighting
            eventData.createdColorCorrection = true
        end
        eventData.colorCorrection = colorCorrection
        
        local nightTweenInfo = TweenInfo.new(config.TransitionTime, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
        local nightTween = TweenService:Create(colorCorrection, nightTweenInfo, {
            TintColor = Color3.fromRGB(30, 50, 90),
            Saturation = 0.4,
            Contrast = 0.2,
            Brightness = -0.1
        })
        nightTween:Play()
        
        spawn(function()
            wait(config.TransitionTime / 2)
            local originalSky = originalSettings.Sky
            if originalSky then
                originalSky:Destroy()
            end
            local newSky = Instance.new("Sky")
            for prop, id in pairs(STARRY_SKYBOX) do
                newSky[prop] = id
            end
            newSky.CelestialBodiesShown = false
            newSky.StarCount = 1000
            newSky.Parent = Lighting
            eventData.newSky = newSky
        end)
        
        Lighting.Ambient = Color3.fromRGB(20, 30, 50)
        Lighting.Brightness = 0.8
        
        local gravityTweenInfo = TweenInfo.new(config.GravityTweenTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        local gravityDownTween = TweenService:Create(workspace, gravityTweenInfo, {Gravity = config.LowGravityValue})
        gravityDownTween:Play()
        eventData.gravityTweenInfo = gravityTweenInfo
        
        local center = Instance.new("Part")
        center.Name = "BlackholeCenter"
        center.Size = Vector3.new(1, 1, 1)
        center.Position = Vector3.new(0, 1000, 0)
        center.Shape = Enum.PartType.Ball
        center.Material = Enum.Material.Neon
        center.Color = Color3.fromRGB(0, 0, 50)
        center.Transparency = 1
        center.CanCollide = false
        center.Anchored = true
        center.Parent = workspace
        
        local clone = center:Clone()
        clone.Name = "BlackholeClone"
        clone.Position = Vector3.new(0, 1200, 0)
        clone.Material = Enum.Material.Neon
        clone.Color = Color3.fromRGB(0, 64, 128)
        clone.Transparency = 1
        clone.Parent = workspace
        
        local firstSound = Instance.new("Sound")
        firstSound.Name = "FirstBlackholeSound"
        firstSound.Parent = workspace
        firstSound.SoundId = "rbxassetid://9041785975"
        firstSound.Volume = 0
        firstSound:Play()
        
        local appearInfo = TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        local centerTween = TweenService:Create(center, appearInfo, {
            Size = Vector3.new(1000, 1000, 1000),
            Transparency = 0
        })
        local cloneTween = TweenService:Create(clone, appearInfo, {
            Size = Vector3.new(1300, 1300, 1300),
            Transparency = 0.1
        })
        local firstSoundFadeIn = TweenService:Create(firstSound, appearInfo, {Volume = 0.7})
        centerTween:Play()
        cloneTween:Play()
        firstSoundFadeIn:Play()
        
        centerTween.Completed:Connect(function()
            local fadeOutInfo = TweenInfo.new(2, Enum.EasingStyle.Linear)
            local firstSoundFadeOut = TweenService:Create(firstSound, fadeOutInfo, {Volume = 0})
            firstSoundFadeOut:Play()
            firstSoundFadeOut.Completed:Connect(function()
                firstSound:Destroy()
            end)
            
            wait(2)
            local secondSound = Instance.new("Sound")
            secondSound.Name = "SecondBlackholeSound"
            secondSound.Parent = workspace
            secondSound.SoundId = "rbxassetid://118582247257657"
            secondSound.Volume = 0
            secondSound:Play()
            
            local secondSoundFadeIn = TweenService:Create(secondSound, TweenInfo.new(2, Enum.EasingStyle.Linear), {Volume = 0.65})
            secondSoundFadeIn:Play()
            eventData.secondSound = secondSound
        end)
        
        eventData.center = center
        eventData.clone = clone
        
    end
    
    spawn(function()
        if eventName == "DiscoEvent" then
            if sound then
                local soundDuration = sound.TimeLength
                if soundDuration <= 0 then
                    soundDuration = 30
                end
                wait(soundDuration + config.FadeOutDuration)
                local fadeOutInfo = TweenInfo.new(config.FadeOutDuration, Enum.EasingStyle.Linear)
                local fadeOutTween = TweenService:Create(sound, fadeOutInfo, {Volume = 0})
                fadeOutTween:Play()
                fadeOutTween.Completed:Wait()
                sound:Stop()
                sound:Destroy()
            end
            if eventData.connection then
                eventData.connection:Disconnect()
            end
            for _, animData in ipairs(eventData.animTracks) do
                animData.track:Stop(0)
                animData.obj:Destroy()
            end
            Lighting.Ambient = originalSettings.Ambient
            Lighting.Brightness = originalSettings.Brightness
            isEventActive = false
        elseif eventName == "BlackholeEvent" then
            wait(config.EffectDuration)
            local gravityUpTween = TweenService:Create(workspace, eventData.gravityTweenInfo, {Gravity = config.DefaultGravity})
            gravityUpTween:Play()
            
            local dayTweenInfo = TweenInfo.new(config.TransitionTime, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
            local dayTween = TweenService:Create(eventData.colorCorrection, dayTweenInfo, {
                TintColor = Color3.new(1, 1, 1),
                Saturation = 0,
                Contrast = 0,
                Brightness = 0
            })
            dayTween:Play()
            
            spawn(function()
                wait(config.TransitionTime)
                if eventData.newSky then
                    eventData.newSky:Destroy()
                end
                if originalSettings.Sky then
                    local restoredSky = originalSettings.Sky:Clone()
                    restoredSky.Parent = Lighting
                else
                    local defaultSky = Instance.new("Sky")
                    defaultSky.Parent = Lighting
                end
            end)
            
            local disappearInfo = TweenInfo.new(config.TransitionTime / 2, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
            if eventData.center then
                local centerDisappear = TweenService:Create(eventData.center, disappearInfo, {Transparency = 1, Size = Vector3.new(1, 1, 1)})
                centerDisappear:Play()
            end
            if eventData.clone then
                local cloneDisappear = TweenService:Create(eventData.clone, disappearInfo, {Transparency = 1, Size = Vector3.new(1, 1, 1)})
                cloneDisappear:Play()
            end
            if eventData.secondSound then
                local secondSoundFadeOut = TweenService:Create(eventData.secondSound, disappearInfo, {Volume = 0})
                secondSoundFadeOut:Play()
                secondSoundFadeOut.Completed:Connect(function()
                    eventData.secondSound:Destroy()
                end)
            end
            
            wait(config.TransitionTime / 2)
            if eventData.center then eventData.center:Destroy() end
            if eventData.clone then eventData.clone:Destroy() end
            
            Lighting.Ambient = originalSettings.Ambient
            Lighting.Brightness = originalSettings.Brightness
            
            isEventActive = false
        end
        
        if eventData.colorCorrection and eventData.createdColorCorrection then
            eventData.colorCorrection:Destroy()
        end
    end)
end

local subscriptions = {}
for eventName, config in pairs(EVENTS) do
    local topicName = config.TopicName
    subscriptions[topicName] = MessagingService:SubscribeAsync(topicName, function(message)
        local data = message.Data
        if data.JobId == game.JobId then return end
        startEvent(eventName, data.PlayerName)
    end)
end

local function onPlayerAdded(player)
    local isAdmin = false
    for _, id in ipairs(adminUserIds) do
        if player.UserId == id then
            isAdmin = true
            break
        end
    end
    if not isAdmin then return end
    
    player.Chatted:Connect(function(msg)
        local lowerMsg = msg:lower()
        for eventName, config in pairs(EVENTS) do
            if lowerMsg == config.Command then
                local topicName = config.TopicName
                local success, err = pcall(function()
                    MessagingService:PublishAsync(topicName, {
                        PlayerName = player.Name,
                        JobId = game.JobId
                    })
                end)
                if not success then
                    warn("Failed to publish " .. eventName .. ": " .. tostring(err))
                    startEvent(eventName, player.Name)
                else
                    startEvent(eventName, player.Name)
                end
                break
            end
        end
    end)
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in ipairs(Players:GetPlayers()) do
    onPlayerAdded(player)
end

game:BindToClose(function()
    for _, subscription in pairs(subscriptions) do
        if subscription then
            subscription:Disconnect()
        end
    end
end)