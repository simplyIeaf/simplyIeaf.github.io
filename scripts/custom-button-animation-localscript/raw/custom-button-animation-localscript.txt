local TweenSvc = game:GetService("TweenService")
local RunSvc = game:GetService("RunService")
local RepStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local ButtonAnimationsFolder = RepStorage:WaitForChild("ButtonAnimations", 20)
local PlayButtonAnim = RepStorage:WaitForChild("PlayButtonAnim", 20)
if not ButtonAnimationsFolder or not PlayButtonAnim then return end

local localPlayer = Players.LocalPlayer

task.spawn(function()
    local char = localPlayer.Character or localPlayer.CharacterAdded:Wait()
    if char:WaitForChild("UpperTorso", 3) then
    end
end)

local ButtonEasingStyles = {
    [Enum.PoseEasingStyle.Linear] = Enum.EasingStyle.Linear,
    [Enum.PoseEasingStyle.Constant] = Enum.EasingStyle.Linear,
    [Enum.PoseEasingStyle.Elastic] = Enum.EasingStyle.Elastic,
    [Enum.PoseEasingStyle.Cubic] = Enum.EasingStyle.Cubic,
    [Enum.PoseEasingStyle.Bounce] = Enum.EasingStyle.Bounce,
}

local ButtonEasingDirections = {
    [Enum.PoseEasingDirection.In] = Enum.EasingDirection.In,
    [Enum.PoseEasingDirection.Out] = Enum.EasingDirection.Out,
    [Enum.PoseEasingDirection.InOut] = Enum.EasingDirection.InOut,
}

local ButtonR6SequencePlayer = {}
ButtonR6SequencePlayer.__index = ButtonR6SequencePlayer

local function newButtonSequencePlayer(character, sequence, isLooping)
    local self = setmetatable({}, ButtonR6SequencePlayer)
    self.Character = character
    self.Sequence = sequence
    self.IsLooping = isLooping
    self.MotorCache = {}
    self.OriginalC0s = {}
    self.keyframePoses = {}
    self.TweenTracks = {}
    self.ActiveTweens = {}
    self.IsPlaying = false
    self.ExcessTime = 0
    self.OnStopped = nil
    self.StopToken = 0
    self._allKeyframes = {}
    return self
end

local function findButtonMotor(self, pose)
    if not pose or not pose.Parent then return nil end
    if not self.Character then return nil end
    for _, motor in ipairs(self.Character:GetDescendants()) do
        if motor:IsA("Motor6D") and motor.Part0 and motor.Part1 then
            if motor.Part1.Name == pose.Name and motor.Part0.Name == pose.Parent.Name then
                return motor
            end
        end
    end
    return nil
end

local function resetButtonPoses(self, transitionTime)
    local timeToUse = transitionTime or 0.15
    for name, motor in pairs(self.MotorCache) do
        local origC0 = self.OriginalC0s[name]
        if motor and motor.Parent and origC0 then
            local tweenInfo = TweenInfo.new(timeToUse, Enum.EasingStyle.Linear)
            local tw = TweenSvc:Create(motor, tweenInfo, {C0 = origC0})
            tw:Play()
            table.insert(self.ActiveTweens, tw)
        end
    end
end

local function buildButtonTweenTracks(self, allKeyframes)
    local tracks = {}
    local lastPoseData = {}
    
    for i = 1, #allKeyframes - 1 do
        local kf1 = self.keyframePoses[i]
        local kf2 = self.keyframePoses[i + 1]
        local timeDiff = math.max(0.001, kf2.Time - kf1.Time)
        tracks[i] = { Time = timeDiff, Tweens = {} }
        
        for name, pose in pairs(kf1.Poses) do lastPoseData[name] = pose end
        
        for name, pose2 in pairs(kf2.Poses) do
            local pose1 = lastPoseData[name]
            local motor = self.MotorCache[name]
            local origC0 = self.OriginalC0s[name]
            if pose1 and motor and origC0 then
                local style = ButtonEasingStyles[pose1.EasingStyle] or Enum.EasingStyle.Linear
                local dir = ButtonEasingDirections[pose1.EasingDirection] or Enum.EasingDirection.Out
                local tInfo = TweenInfo.new(timeDiff, style, dir)
                tracks[i].Tweens[name] = TweenSvc:Create(motor, tInfo, {C0 = origC0 * pose2.CFrame})
            end
        end
    end
    
    if self.IsLooping and #allKeyframes > 0 and self.ExcessTime > 0 then
        local eTime = math.max(0.001, self.ExcessTime)
        local kfFirst = self.keyframePoses[1]
        local kfLast = self.keyframePoses[#allKeyframes]
        local idx = #tracks + 1
        tracks[idx] = { Time = eTime, Tweens = {} }
        local lastLoop = {}
        for name, pose in pairs(kfLast.Poses) do lastLoop[name] = pose end
        for name, pose1 in pairs(kfFirst.Poses) do
            local poseLast = lastLoop[name]
            local motor = self.MotorCache[name]
            local origC0 = self.OriginalC0s[name]
            if poseLast and motor and origC0 then
                local style = ButtonEasingStyles[poseLast.EasingStyle] or Enum.EasingStyle.Linear
                local dir = ButtonEasingDirections[poseLast.EasingDirection] or Enum.EasingDirection.Out
                local tInfo = TweenInfo.new(eTime, style, dir)
                tracks[idx].Tweens[name] = TweenSvc:Create(motor, tInfo, {C0 = origC0 * pose1.CFrame})
            end
        end
    end
    
    return tracks
end

local function playButtonCycle(self)
    for _, group in ipairs(self.TweenTracks) do
        if not self.IsPlaying then return end
        self.ActiveTweens = {}
        local longestTween
        local longestTime = 0
        
        for _, tween in pairs(group.Tweens) do
            tween:Play()
            table.insert(self.ActiveTweens, tween)
            if tween.TweenInfo.Time > longestTime then
                longestTime = tween.TweenInfo.Time
                longestTween = tween
            end
        end
        
        if longestTween and longestTime > 0 then
            longestTween.Completed:Wait()
        elseif group.Time > 0 then
            task.wait(group.Time)
        elseif group.Time == 0 then
            RunSvc.Heartbeat:Wait()
        end
        self.ActiveTweens = {}
    end
end

function ButtonR6SequencePlayer:Load()
    local allKeyframes = self.Sequence:GetKeyframes()
    table.sort(allKeyframes, function(a, b) return a.Time < b.Time end)
        
    self.keyframePoses = {}
    self.TweenTracks = {}
    self.ExcessTime = 0
    
    if #allKeyframes > 1 then
        local lastKeyframe = allKeyframes[#allKeyframes]
        local hasPoses = false
        for _, desc in ipairs(lastKeyframe:GetDescendants()) do
            if desc:IsA("Pose") and desc.Weight > 0 then
                hasPoses = true
                break
            end
        end
        if not hasPoses then
            self.ExcessTime = lastKeyframe.Time - allKeyframes[#allKeyframes - 1].Time
            table.remove(allKeyframes, #allKeyframes)
        end
    end
    
    if #allKeyframes == 0 then return end
    
    self._allKeyframes = allKeyframes
    
    local motorPoseData = {}
    for i, keyframe in ipairs(allKeyframes) do
        self.keyframePoses[i] = { Time = keyframe.Time, Poses = {} }
        for _, pose in ipairs(keyframe:GetDescendants()) do
            if pose:IsA("Pose") and pose.Weight > 0 and pose.Parent then
                local motorKey = pose.Name .. "." .. pose.Parent.Name
                if not motorPoseData[motorKey] then
                    local motor = findButtonMotor(self, pose)
                    if motor then
                        motorPoseData[motorKey] = motor
                        self.MotorCache[motor.Name] = motor
                        
                        if not self.OriginalC0s[motor.Name] then
                            self.OriginalC0s[motor.Name] = motor.C0
                        end
                    end
                end
                local motor = motorPoseData[motorKey]
                if motor then
                    self.keyframePoses[i].Poses[motor.Name] = pose
                end
            end
        end
    end
    
    self.TweenTracks = buildButtonTweenTracks(self, allKeyframes)
end

function ButtonR6SequencePlayer:Play()
    if self.IsPlaying or not self.Character or not self.Character.Parent then return end
    self.IsPlaying = true
    
    self.TweenTracks = buildButtonTweenTracks(self, self._allKeyframes)
    
    if #self.keyframePoses > 0 then
        for motorName, pose in pairs(self.keyframePoses[1].Poses) do
            local motor = self.MotorCache[motorName]
            local origC0 = self.OriginalC0s[motorName]
            if motor and motor.Parent and origC0 then
                motor.C0 = origC0 * pose.CFrame
            end
        end
    end
    
    task.spawn(function()
        if self.IsLooping then
            while self.IsPlaying and self.Character and self.Character.Parent do
                playButtonCycle(self)
            end
        else
            playButtonCycle(self)
            if self.IsPlaying then
                self:Stop()
            end
        end
    end)
end

function ButtonR6SequencePlayer:Stop()
    if not self.IsPlaying then return end
    self.IsPlaying = false
    
    for _, tween in ipairs(self.ActiveTweens) do
        if tween and tween.PlaybackState == Enum.PlaybackState.Playing then
            tween:Cancel()
        end
    end
    self.ActiveTweens = {}
    
    if self.Character and self.Character.Parent then
        resetButtonPoses(self, 0.2)
    end
    
    if self.OnStopped then
        self.StopToken += 1
        local myToken = self.StopToken
        local cb = self.OnStopped
        local endTime = os.clock() + 0.2
        task.spawn(function()
            while os.clock() < endTime do
                task.wait()
            end
            if self.StopToken == myToken then
                cb()
            end
        end)
    end
end

local ButtonCharacterStates = {}

local function setupButtonCharacter(char)
    if not char or not char.Parent then return nil end
    if ButtonCharacterStates[char] then return ButtonCharacterStates[char] end
    
    local stateTable = {
        Players = {},
        Current = { player = nil, state = "None", generation = 0 },
        CachedAnimate = nil
    }
    ButtonCharacterStates[char] = stateTable
    
    char.Destroying:Connect(function()
        for _, animPlayer in pairs(stateTable.Players) do
            animPlayer.IsPlaying = false
        end
        stateTable.Players = {}
        stateTable.Current.player = nil
        ButtonCharacterStates[char] = nil
    end)
    return stateTable
end

local function disableCharacterAnims(char, data)
    local humanoid = char:FindFirstChild("Humanoid")
    if humanoid then
        local animator = humanoid:FindFirstChildOfClass("Animator")
        if animator then
            for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
                track:Stop(0)
            end
        end
    end
    local animateScript = char:FindFirstChild("Animate")
    if animateScript then
        data.CachedAnimate = animateScript:Clone()
        animateScript:Destroy()
    end
end

local function restoreCharacterAnims(char, data)
    if data.CachedAnimate and not char:FindFirstChild("Animate") then
        local newAnimate = data.CachedAnimate:Clone()
        newAnimate.Parent = char
        
        local humanoid = char:FindFirstChild("Humanoid")
        if humanoid and char == localPlayer.Character then
            local currentState = humanoid:GetState()
            local ws = humanoid.WalkSpeed
            humanoid.WalkSpeed = 0
            task.wait()
            humanoid.WalkSpeed = ws
            humanoid:ChangeState(currentState)
        end
    end
end

local function applyButtonState(char, newState)
    if char:FindFirstChild("UpperTorso") then return end
    
    local data = setupButtonCharacter(char)
    if not data then return end
    
    local currentAnim = data.Current
    
    if currentAnim.state == newState and currentAnim.player and currentAnim.player.IsPlaying then
        currentAnim.player:Stop()
        return
    end
    
    if currentAnim.player then
        currentAnim.player:Stop()
    end
    
    local animSequence = ButtonAnimationsFolder:FindFirstChild(newState)
    if not animSequence then return end
    
    if not data.Players[newState] then
        local isLoop = animSequence:GetAttribute("Loop") == true
        local animPlayer = newButtonSequencePlayer(char, animSequence, isLoop)
        animPlayer:Load()
        data.Players[newState] = animPlayer
    end
    
    local animPlayer = data.Players[newState]
    
    currentAnim.generation += 1
    local myGen = currentAnim.generation
    
    animPlayer.OnStopped = function()
        if data.Current.generation ~= myGen then return end
        data.Current.state = "None"
        data.Current.player = nil
        restoreCharacterAnims(char, data)
    end
    
    disableCharacterAnims(char, data)
    
    animPlayer:Play()
    currentAnim.player = animPlayer
    currentAnim.state = newState
end

local function restoreButtonChar(targetPlayer)
    local char = targetPlayer and targetPlayer.Character
    if not char or char.Parent ~= Workspace then return end
    local data = ButtonCharacterStates[char]
    if not data then return end
    local current = data.Current
    
    if current.player then
        current.player:Stop()
    else
        restoreCharacterAnims(char, data)
    end
end

PlayButtonAnim.OnClientEvent:Connect(function(action, targetPlayer, animName)
    if action == "Play" then
        if not targetPlayer or not targetPlayer.Character then return end
        local char = targetPlayer.Character
        if char.Parent ~= Workspace then return end
        applyButtonState(char, animName)
    elseif action == "AnimDone" then
        if not targetPlayer then return end
        restoreButtonChar(targetPlayer)
    end
end)