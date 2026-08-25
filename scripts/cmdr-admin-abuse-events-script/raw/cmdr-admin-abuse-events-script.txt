-- made by @simplyIeaf1 on youtube

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local MessagingService = game:GetService("MessagingService")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local adminUserIds = {8033814042}
local isEventActive = false

local EVENTS = {
    DiscoEvent = {
        TopicName = "DiscoEvent",
        Command = "globaldisco",
        AnimIds = {"rbxassetid://182435998", "rbxassetid://182436842"},
        SoundId = "rbxassetid://142376088",
        FadeInDuration = 2,
        FadeOutDuration = 2,
        MaxVolume = 0.75,
        DiscoSpeed = 1
    },
    BlackholeEvent = {
        TopicName = "BlackholeEvent",
        Command = "globalblackhole",
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
    },
    CheeseEvent = {
        TopicName = "CheeseEvent",
        Command = "globalcheese",
        AnimIds = {"rbxassetid://182435998", "rbxassetid://182436842"},
        SoundId = "rbxassetid://142376088",
        FadeInDuration = 2,
        FadeOutDuration = 2,
        MaxVolume = 0.75,
        TacosPerSpawn = 25,
        SpawnInterval = 1.2,
        SpawnHeight = 800,
        SpawnRadius = 500,
        TacoLifetime = 10,
        TacoScale = 8,
        Velocity = Vector3.new(0, -150, 0),
        CanCollide = false,
        Spin = true
    },
    MeteorEvent = {
        TopicName = "MeteorEvent",
        Command = "globalmeteor",
        AnimIds = {},
        SoundId = "rbxassetid://9112759731",
        FadeInDuration = 2,
        FadeOutDuration = 2,
        MaxVolume = 0.5,
        SpawnHeight = 500,
        SpawnRadius = 500,
        Velocity = Vector3.new(0, -150, 0),
        CanCollide = false,
        EventDuration = 60
    }
}

local STARRY_SKYBOX = {
    SkyboxBk = "rbxassetid://1012894",
    SkyboxDn = "rbxassetid://1012895",
    SkyboxFt = "rbxassetid://1012892",
    SkyboxLf = "rbxassetid://1012893",
    SkyboxRt = "rbxassetid://1012890",
    SkyboxUp = "rbxassetid://1012891"
}

local function randomVector3InRange(center, range)
    return Vector3.new(
        center.X + math.random(-range.X/2, range.X/2),
        center.Y + math.random(-range.Y/2, range.Y/2),
        center.Z + math.random(-range.Z/2, range.Z/2)
    )
end

local function createCheeseModel()
    local cheeseModel = Instance.new("Model")
    cheeseModel.Name = "CheeseModel"
    
    local cheeseBase = Instance.new("Part")
    cheeseBase.Name = "Cheese"
    cheeseBase.Size = Vector3.new(1, 1, 1)
    cheeseBase.Transparency = 1
    cheeseBase.Anchored = false
    cheeseBase.CanCollide = false
    cheeseBase.CanTouch = false
    cheeseBase.Parent = cheeseModel
    cheeseModel.PrimaryPart = cheeseBase
    
    local bottomCheese = Instance.new("Part")
    bottomCheese.Name = "BottomCheese"
    bottomCheese.Size = Vector3.new(1, 0.2, 1)
    bottomCheese.Position = Vector3.new(0, -0.3, 0)
    bottomCheese.Color = Color3.fromRGB(255, 215, 0)
    bottomCheese.Material = Enum.Material.SmoothPlastic
    bottomCheese.CanCollide = false
    bottomCheese.CanTouch = false
    bottomCheese.Parent = cheeseBase
    
    local filling = Instance.new("Part")
    filling.Name = "Filling"
    filling.Size = Vector3.new(0.9, 0.3, 0.9)
    filling.Position = Vector3.new(0, 0, 0)
    filling.Color = Color3.fromRGB(200, 150, 0)
    filling.Material = Enum.Material.Plastic
    filling.CanCollide = false
    filling.CanTouch = false
    filling.Parent = cheeseBase
    
    local topCheese = Instance.new("Part")
    topCheese.Name = "TopCheese"
    topCheese.Size = Vector3.new(1, 0.2, 1)
    topCheese.Position = Vector3.new(0, 0.3, 0)
    topCheese.Color = Color3.fromRGB(255, 215, 0)
    topCheese.Material = Enum.Material.SmoothPlastic
    topCheese.CanCollide = false
    topCheese.CanTouch = false
    topCheese.Parent = cheeseBase
    
    local weldBottom = Instance.new("WeldConstraint")
    weldBottom.Name = "BottomWeld"
    weldBottom.Part0 = cheeseBase
    weldBottom.Part1 = bottomCheese
    weldBottom.Parent = cheeseBase
    
    local weldFilling = Instance.new("WeldConstraint")
    weldFilling.Name = "FillingWeld"
    weldFilling.Part0 = cheeseBase
    weldFilling.Part1 = filling
    weldFilling.Parent = cheeseBase
    
    local weldTop = Instance.new("WeldConstraint")
    weldTop.Name = "TopWeld"
    weldTop.Part0 = cheeseBase
    weldTop.Part1 = topCheese
    weldTop.Parent = cheeseBase
    
    bottomCheese.Size = bottomCheese.Size * EVENTS.CheeseEvent.TacoScale
    filling.Size = filling.Size * EVENTS.CheeseEvent.TacoScale
    topCheese.Size = topCheese.Size * EVENTS.CheeseEvent.TacoScale
    
    print("Cheese model created with cheese slices and filling using Parts")
    return cheeseModel
end

local function createMeteorModel()
    local meteorModel = Instance.new("Model")
    meteorModel.Name = "MeteorModel"
    
    local meteorCore = Instance.new("Part")
    meteorCore.Name = "Meteor"
    meteorCore.Shape = Enum.PartType.Ball
    meteorCore.Size = Vector3.new(2, 2, 2)
    meteorCore.Color = Color3.fromRGB(100, 100, 100)
    meteorCore.Material = Enum.Material.Rock
    meteorCore.Anchored = false
    meteorCore.CanCollide = false
    meteorCore.CanTouch = true
    meteorCore.Parent = meteorModel
    meteorModel.PrimaryPart = meteorCore
    
    local rock1 = Instance.new("Part")
    rock1.Name = "Rock1"
    rock1.Shape = Enum.PartType.Ball
    rock1.Size = Vector3.new(0.5, 0.5, 0.5)
    rock1.Position = Vector3.new(0.5, 0, 0)
    rock1.Color = Color3.fromRGB(80, 80, 80)
    rock1.Material = Enum.Material.Rock
    rock1.CanCollide = false
    rock1.CanTouch = true
    rock1.Parent = meteorCore
    
    local rock2 = Instance.new("Part")
    rock2.Name = "Rock2"
    rock2.Shape = Enum.PartType.Ball
    rock2.Size = Vector3.new(0.7, 0.7, 0.7)
    rock2.Position = Vector3.new(-0.5, 0, 0)
    rock2.Color = Color3.fromRGB(120, 120, 120)
    rock2.Material = Enum.Material.Rock
    rock2.CanCollide = false
    rock2.CanTouch = true
    rock2.Parent = meteorCore
    
    local weldRock1 = Instance.new("WeldConstraint")
    weldRock1.Name = "Rock1Weld"
    weldRock1.Part0 = meteorCore
    weldRock1.Part1 = rock1
    weldRock1.Parent = meteorCore
    
    local weldRock2 = Instance.new("WeldConstraint")
    weldRock2.Name = "Rock2Weld"
    weldRock2.Part0 = meteorCore
    weldRock2.Part1 = rock2
    weldRock2.Parent = meteorCore
    
    local trailAttachment0 = Instance.new("Attachment")
    trailAttachment0.Name = "TrailAttachment0"
    trailAttachment0.Position = Vector3.new(0, 0, 0)
    trailAttachment0.Parent = meteorCore
    
    local trailAttachment1 = Instance.new("Attachment")
    trailAttachment1.Name = "TrailAttachment1"
    trailAttachment1.Position = Vector3.new(0, 0, 1)
    trailAttachment1.Parent = meteorCore
    
    local trail = Instance.new("Trail")
    trail.Name = "MeteorTrail"
    trail.Color = ColorSequence.new(Color3.new(1, 1, 1))
    trail.Transparency = NumberSequence.new(0.5, 1)
    trail.Lifetime = 2
    trail.Attachment0 = trailAttachment0
    trail.Attachment1 = trailAttachment1
    trail.Parent = meteorCore
    
    print("Meteor model created with welded rocks and white trail")
    return meteorModel
end

local function startEvent(eventName, triggeringPlayerName)
    print("Starting event: " .. eventName .. " by " .. triggeringPlayerName)
    if isEventActive then
        warn("Event already active, cannot start " .. eventName)
        return
    end
    local config = EVENTS[eventName]
    if not config then
        warn("Invalid event: " .. eventName)
        return
    end
    isEventActive = true
    
    local originalSettings = {
        Gravity = workspace.Gravity,
        Ambient = Lighting.Ambient,
        Brightness = Lighting.Brightness,
        Sky = Lighting:FindFirstChildOfClass("Sky"),
        ColorCorrection = Lighting:FindFirstChildOfClass("ColorCorrectionEffect"),
        ClockTime = Lighting.ClockTime,
        OutdoorAmbient = Lighting.OutdoorAmbient,
        FogColor = Lighting.FogColor,
        FogEnd = Lighting.FogEnd,
        FogStart = Lighting.FogStart
    }
    
    local topicName = config.TopicName
    local eventData = { originalSettings = originalSettings, animTracks = {}, spawnedCheese = {}, spawnedMeteors = {} }
    
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
        
    elseif eventName == "CheeseEvent" then
        local cheeseModel = createCheeseModel()
        if not cheeseModel or not cheeseModel.PrimaryPart then
            warn("Failed to create cheese model")
            isEventActive = false
            return
        end
        eventData.cheeseTemplate = cheeseModel
        
        print("Cheese template created successfully")
        spawn(function()
            while isEventActive and eventName == "CheeseEvent" do
                pcall(function()
                    for i = 1, config.TacosPerSpawn do
                        print("Spawning cheese " .. i)
                        local cheese = eventData.cheeseTemplate:Clone()
                        cheese.Name = "CheesePart"
                        cheese:SetAttribute("IsEventObject", true)
                        cheese.PrimaryPart.Anchored = false
                        cheese.PrimaryPart.CanCollide = config.CanCollide
                        cheese.PrimaryPart.CanTouch = false
                        
                        for _, part in ipairs(cheese:GetDescendants()) do
                            if part:IsA("BasePart") then
                                part.CanCollide = false
                                part.CanTouch = false
                            end
                        end
                        
                        local spawnCenter = Vector3.new(0, config.SpawnHeight, 0)
                        local spawnRange = Vector3.new(config.SpawnRadius, 50, config.SpawnRadius)
                        cheese:PivotTo(CFrame.new(randomVector3InRange(spawnCenter, spawnRange)))
                        cheese:SetAttribute("SpawnTime", tick())
                        
                        local bv = Instance.new("BodyVelocity")
                        bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                        bv.Velocity = config.Velocity
                        bv.Parent = cheese.PrimaryPart
                        
                        if config.Spin then
                            local bav = Instance.new("BodyAngularVelocity")
                            bav.AngularVelocity = Vector3.new(math.random(-2, 2), math.random(-2, 2), math.random(-2, 2))
                            bav.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
                            bav.Parent = cheese.PrimaryPart
                            print("Applied subtle spin to cheese " .. i)
                        end
                        
                        cheese.Parent = workspace
                        table.insert(eventData.spawnedCheese, cheese)
                        Debris:AddItem(cheese, config.TacoLifetime)
                        
                        cheese.AncestryChanged:Connect(function()
                            if not cheese.Parent then
                                for i, v in ipairs(eventData.spawnedCheese) do
                                    if v == cheese then
                                        table.remove(eventData.spawnedCheese, i)
                                        break
                                    end
                                end
                            end
                        end)
                    end
                end)
                wait(config.SpawnInterval)
            end
        end)
        
        spawn(function()
            while isEventActive and eventName == "CheeseEvent" do
                for i = #eventData.spawnedCheese, 1, -1 do
                    local cheese = eventData.spawnedCheese[i]
                    if cheese and cheese.Parent and cheese.PrimaryPart then
                        if (cheese.PrimaryPart.Position.Y > config.SpawnHeight - 50) and (tick() - (cheese:GetAttribute("SpawnTime") or 0) > 2) then
                            print("Destroying stuck cheese at Y=" .. cheese.PrimaryPart.Position.Y)
                            cheese:Destroy()
                            table.remove(eventData.spawnedCheese, i)
                        end
                    else
                        table.remove(eventData.spawnedCheese, i)
                    end
                end
                wait(1)
            end
        end)
        
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
        
    elseif eventName == "MeteorEvent" then
        local originalClockTime = originalSettings.ClockTime
        TweenService:Create(Lighting, TweenInfo.new(5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {ClockTime = 18.25}):Play()
        TweenService:Create(Lighting, TweenInfo.new(5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {
            Ambient = Color3.fromRGB(10, 10, 20),
            Brightness = 1,
            OutdoorAmbient = Color3.fromRGB(10, 10, 20),
            FogColor = Color3.fromRGB(20, 20, 30),
            FogEnd = 100,
            FogStart = 50
        }):Play()
        
        local backgroundSound = Instance.new("Sound")
        backgroundSound.Name = "BackgroundSound"
        backgroundSound.Parent = workspace
        backgroundSound.SoundId = "rbxassetid://9112759731"
        backgroundSound.Volume = 0
        backgroundSound.Looped = false
        backgroundSound:Play()
        TweenService:Create(backgroundSound, TweenInfo.new(5, Enum.EasingStyle.Linear), {Volume = 0.5}):Play()
        eventData.backgroundSound = backgroundSound
        
        local meteorModel = createMeteorModel()
        if not meteorModel or not meteorModel.PrimaryPart then
            warn("Failed to create meteor model")
            isEventActive = false
            return
        end
        eventData.meteorTemplate = meteorModel
        
        print("Meteor template created successfully")
        spawn(function()
            local startTime = tick()
            while isEventActive and eventName == "MeteorEvent" and (tick() - startTime < config.EventDuration) do
                pcall(function()
                    print("Spawning meteor")
                    local meteor = eventData.meteorTemplate:Clone()
                    meteor.Name = "MeteorPart"
                    meteor:SetAttribute("IsEventObject", true)
                    meteor.PrimaryPart.Anchored = false
                    meteor.PrimaryPart.CanCollide = false
                    meteor.PrimaryPart.CanTouch = true
                    
                    for _, part in ipairs(meteor:GetDescendants()) do
                        if part:IsA("BasePart") then
                            part.CanCollide = false
                            part.CanTouch = true
                        end
                    end
                    
                    local players = Players:GetPlayers()
                    if #players > 0 then
                        local targetPlayer = players[math.random(1, #players)]
                        local targetPosition = targetPlayer.Character and targetPlayer.Character.PrimaryPart and targetPlayer.Character.PrimaryPart.Position + Vector3.new(math.random(-10, 10), 0, math.random(-10, 10)) or Vector3.new(0, 0, 0)
                        local spawnPosition = Vector3.new(targetPosition.X, config.SpawnHeight, targetPosition.Z)
                        meteor:PivotTo(CFrame.new(spawnPosition))
                        
                        local direction = (targetPosition - spawnPosition).Unit
                        local angleOffset = math.rad(math.random(-45, 45))
                        local rotatedDirection = Vector3.new(
                            direction.X * math.cos(angleOffset) - direction.Z * math.sin(angleOffset),
                            -1,
                            direction.X * math.sin(angleOffset) + direction.Z * math.cos(angleOffset)
                        ).Unit
                        local bv = Instance.new("BodyVelocity")
                        bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                        bv.Velocity = rotatedDirection * 150
                        bv.Parent = meteor.PrimaryPart
                    else
                        local spawnCenter = Vector3.new(0, config.SpawnHeight, 0)
                        local spawnRange = Vector3.new(config.SpawnRadius, 50, config.SpawnRadius)
                        meteor:PivotTo(CFrame.new(randomVector3InRange(spawnCenter, spawnRange)))
                        
                        local bv = Instance.new("BodyVelocity")
                        bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                        bv.Velocity = config.Velocity
                        bv.Parent = meteor.PrimaryPart
                    end
                    
                    meteor:SetAttribute("SpawnTime", tick())
                    
                    meteor.Parent = workspace
                    table.insert(eventData.spawnedMeteors, meteor)
                    
                    meteor.PrimaryPart.Touched:Connect(function(hit)
                        if hit and meteor.Parent then
                            local explosionSound = Instance.new("Sound")
                            explosionSound.SoundId = "rbxassetid://18249674353"
                            explosionSound.Volume = 1.0
                            explosionSound.Parent = workspace
                            explosionSound:Play()
                            Debris:AddItem(explosionSound, 5)
                            
                            local explosion = Instance.new("Explosion")
                            explosion.Position = meteor.PrimaryPart.Position
                            explosion.BlastPressure = 0
                            explosion.BlastRadius = 10
                            explosion.Parent = workspace
                            
                            meteor:Destroy()
                            
                            for i, v in ipairs(eventData.spawnedMeteors) do
                                if v == meteor then
                                    table.remove(eventData.spawnedMeteors, i)
                                    break
                                end
                            end
                        end
                    end)
                    
                    Debris:AddItem(meteor, 10)
                end)
                wait(2)
            end
        end)
        
    end
    
    spawn(function()
        if eventName == "DiscoEvent" then
            if sound then
                local soundDuration = sound.TimeLength
                if soundDuration <= 10 then
                    soundDuration = 95
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
        elseif eventName == "CheeseEvent" then
            local soundDuration = sound.TimeLength
            if soundDuration <= 10 then
                soundDuration = 95
            end
            wait(soundDuration)
            local fadeOutInfo = TweenInfo.new(config.FadeOutDuration, Enum.EasingStyle.Linear)
            local fadeOutTween = TweenService:Create(sound, fadeOutInfo, {Volume = 0})
            fadeOutTween:Play()
            fadeOutTween.Completed:Wait()
            sound:Stop()
            sound:Destroy()
            
            for _, animData in ipairs(eventData.animTracks) do
                animData.track:Stop(0)
                animData.obj:Destroy()
            end
            
            for _, cheese in ipairs(eventData.spawnedCheese) do
                if cheese then cheese:Destroy() end
            end
            
            isEventActive = false
        elseif eventName == "MeteorEvent" then
            wait(config.EventDuration)
            local fadeOutInfo = TweenInfo.new(2, Enum.EasingStyle.Linear)
            local fadeOutTween = TweenService:Create(eventData.backgroundSound, fadeOutInfo, {Volume = 0})
            fadeOutTween:Play()
            fadeOutTween.Completed:Wait()
            eventData.backgroundSound:Stop()
            eventData.backgroundSound:Destroy()
            
            TweenService:Create(Lighting, TweenInfo.new(5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {ClockTime = originalSettings.ClockTime}):Play()
            TweenService:Create(Lighting, TweenInfo.new(5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {
                Ambient = originalSettings.Ambient,
                Brightness = originalSettings.Brightness,
                OutdoorAmbient = originalSettings.OutdoorAmbient,
                FogColor = originalSettings.FogColor,
                FogEnd = originalSettings.FogEnd,
                FogStart = originalSettings.FogStart
            }):Play()
            
            for _, meteor in ipairs(eventData.spawnedMeteors) do
                if meteor then meteor:Destroy() end
            end
            
            isEventActive = false
        end
        
        if eventData.colorCorrection and eventData.createdColorCorrection then
            eventData.colorCorrection:Destroy()
        end
    end)
end

local commandRemote = Instance.new("RemoteEvent")
commandRemote.Name = "ExecuteCommand"
commandRemote.Parent = ReplicatedStorage

local getCommandsRemote = Instance.new("RemoteFunction")
getCommandsRemote.Name = "GetCommands"
getCommandsRemote.Parent = ReplicatedStorage

local checkAdminRemote = Instance.new("RemoteFunction")
checkAdminRemote.Name = "CheckAdmin"
checkAdminRemote.Parent = ReplicatedStorage

local subscriptions = {}
for eventName, config in pairs(EVENTS) do
    local topicName = config.TopicName
    subscriptions[topicName] = MessagingService:SubscribeAsync(topicName, function(message)
        local data = message.Data
        if data.JobId == game.JobId then return end
        print("Received MessagingService event: " .. eventName .. " from " .. data.PlayerName)
        startEvent(eventName, data.PlayerName)
    end)
end

local function isValidCommand(command)
    for eventName, config in pairs(EVENTS) do
        if config.Command:lower() == command:lower() then
            return eventName
        end
    end
    return nil
end

local function getClosestCommand(partialCommand)
    local closestMatch = nil
    local minDistance = math.huge
    partialCommand = partialCommand:lower()
    
    for eventName, config in pairs(EVENTS) do
        local cmd = config.Command:lower()
        if cmd:sub(1, #partialCommand) == partialCommand then
            local distance = #cmd - #partialCommand
            if distance < minDistance then
                minDistance = distance
                closestMatch = eventName
            end
        end
    end
    return closestMatch
end

local function isAdmin(player)
    if not player then return false end
    for _, id in ipairs(adminUserIds) do
        if player.UserId == id then
            return true
        end
    end
    return false
end

checkAdminRemote.OnServerInvoke = function(player)
    return isAdmin(player)
end

getCommandsRemote.OnServerInvoke = function(player)
    if not isAdmin(player) then return {} end
    
    local commands = {}
    for _, config in pairs(EVENTS) do
        table.insert(commands, config.Command)
    end
    return commands
end

commandRemote.OnServerEvent:Connect(function(player, command)
    if not isAdmin(player) then
        warn("Player " .. player.Name .. " is not an admin")
        return
    end
    
    if not command or type(command) ~= "string" or #command > 50 then
        warn("Invalid command from " .. player.Name)
        return
    end
    
    local eventName = isValidCommand(command)
    if not eventName then
        eventName = getClosestCommand(command)
        if not eventName then
            warn("No matching command for: " .. command)
            return
        end
    end
    
    print("Command matched: " .. eventName .. " for input: " .. command)
    local topicName = EVENTS[eventName].TopicName
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
        print("Published " .. eventName .. " via MessagingService")
        startEvent(eventName, player.Name)
    end
end)

game:BindToClose(function()
    for _, subscription in pairs(subscriptions) do
        if subscription then
            subscription:Disconnect()
        end
    end
end)

print("CMDR Admin Abuse Events Loaded!")