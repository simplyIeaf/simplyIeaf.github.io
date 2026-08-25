-- made by @simplyIeaf1 on YouTube
 
local TweenSvc = game:GetService("TweenService")
local RunSvc = game:GetService("RunService")
local RepStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Task = task
 
local ENABLE_INTERPOLATION = true
local ENABLE_BLENDING = true
 
local Char = script.Parent
local Hum = Char:WaitForChild("Humanoid")
local LocalPlayer = Players:GetPlayerFromCharacter(Char)
 
if not LocalPlayer then return end
 
local AnimationsFolder = RepStorage:WaitForChild("Animations", 20)
local PlayAnimationState = RepStorage:WaitForChild("PlayAnimationState", 20)
 
if not AnimationsFolder or not PlayAnimationState then return end
 
local AnimSequences = {
Idle = AnimationsFolder:FindFirstChild("IdleAnim"),
Walk = AnimationsFolder:FindFirstChild("WalkAnim"),
Swim = AnimationsFolder:FindFirstChild("SwimAnim"),
Jump = AnimationsFolder:FindFirstChild("JumpAnim"),
Climb = AnimationsFolder:FindFirstChild("ClimbAnim"),
}
 
local EasingStyles = {
[Enum.PoseEasingStyle.Linear] = Enum.EasingStyle.Linear,
[Enum.PoseEasingStyle.Constant] = Enum.EasingStyle.Linear,
[Enum.PoseEasingStyle.Elastic] = Enum.EasingStyle.Elastic,
[Enum.PoseEasingStyle.Cubic] = Enum.EasingStyle.Cubic,
[Enum.PoseEasingStyle.Bounce] = Enum.EasingStyle.Bounce,
}
 
local EasingDirections = {
[Enum.PoseEasingDirection.In] = Enum.EasingDirection.In,
[Enum.PoseEasingDirection.Out] = Enum.EasingDirection.Out,
[Enum.PoseEasingDirection.InOut] = Enum.EasingDirection.InOut,
}
 
local R6SequencePlayer = {}
R6SequencePlayer.__index = R6SequencePlayer
 
local function destroyAllSeats()
    for _, descendant in ipairs(game.Workspace:GetDescendants()) do
        if descendant:IsA("Seat") then
            descendant:Destroy()
        end
    end
end
destroyAllSeats()
 
function R6SequencePlayer.new(character, sequence, isLooping)
    local self = setmetatable({}, R6SequencePlayer)
    self.Character = character
    self.Sequence = sequence
    self.IsLooping = isLooping
    self.MotorCache = {}
    self.TweenTracks = {}
    self.ActiveTweens = {}
    self.keyframePoses = {}
    self.IsPlaying = false
    self.ExcessTime = 0
    return self
end
 
function R6SequencePlayer:FindMotor(pose)
    local part1Name = pose.Name
    local part0Name = pose.Parent.Name
    for _, motor in pairs(self.Character:GetDescendants()) do
        if motor:IsA("Motor6D") and motor.Part1 and motor.Part0 then
            if motor.Part1.Name == part1Name and motor.Part0.Name == part0Name then
                return motor
            end
        end
    end
    return nil
end
 
function R6SequencePlayer:ResetPoses(transitionTime)
    local timeToUse = (ENABLE_BLENDING and (transitionTime or 0.15)) or 0
    for _, motor in pairs(self.MotorCache) do
        if motor and motor.Parent then
            local tweenInfo = TweenInfo.new(timeToUse, Enum.EasingStyle.Linear)
            local resetTween = TweenSvc:Create(motor, tweenInfo, {Transform = CFrame.new()})
            resetTween:Play()
        end
    end
end
 
function R6SequencePlayer:PlayCycle()
    for i, group in ipairs(self.TweenTracks) do
        if not self.IsPlaying then return end
        
        self.ActiveTweens = {}
        local longestTween
        local longestTime = 0
        
        for name, tween in pairs(group.Tweens) do
            tween:Play()
            table.insert(self.ActiveTweens, tween)
            
            local tweenLength = tween.TweenInfo.Time
            if tweenLength > longestTime then
                longestTime = tweenLength
                longestTween = tween
            end
        end
        
        if longestTween and longestTime > 0 then
            longestTween.Completed:Wait()
        elseif group.Time > 0 then
            Task.wait(group.Time)
        elseif group.Time == 0 then
            RunSvc.Heartbeat:Wait()
        end
        
        self.ActiveTweens = {}
    end
end
 
function R6SequencePlayer:Play()
    if self.IsPlaying then return end
    self.IsPlaying = true
    
    if #self.keyframePoses > 0 then
        local firstPoses = self.keyframePoses[1].Poses
        for motorName, pose in pairs(firstPoses) do
            local motor = self.MotorCache[motorName]
            if motor and motor.Parent then
                motor.Transform = pose.CFrame
            end
        end
    end
    
    Task.spawn(function()
        if self.IsLooping then
            while self.IsPlaying do
                self:PlayCycle()
            end
        else
            self:PlayCycle()
            
            if self.IsPlaying and #self.keyframePoses > 0 then
                local lastPoses = self.keyframePoses[#self.keyframePoses].Poses
                for motorName, pose in pairs(lastPoses) do
                    local motor = self.MotorCache[motorName]
                    if motor and motor.Parent then
                        motor.Transform = pose.CFrame
                    end
                end
            end
            
            self.IsPlaying = false
        end
    end)
end
 
function R6SequencePlayer:Stop()
    if not self.IsPlaying then return end
    self.IsPlaying = false
    
    for _, tween in ipairs(self.ActiveTweens) do
        if tween and tween.PlaybackState == Enum.PlaybackState.Playing then
            tween:Cancel()
        end
    end
    self.ActiveTweens = {}
    
    self:ResetPoses(0.1)
end
 
function R6SequencePlayer:Load()
    local allKeyframes = {}
    for _, kf in pairs(self.Sequence:GetKeyframes()) do
        table.insert(allKeyframes, kf)
    end
    table.sort(allKeyframes, function(a, b) return a.Time < b.Time end)
        
        self.keyframePoses = {}
        self.TweenTracks = {}
        self.ExcessTime = 0
        if #allKeyframes > 1 then
            local lastKeyframe = allKeyframes[#allKeyframes]
            local posesInLastKeyframe = 0
            for _, descendant in pairs(lastKeyframe:GetDescendants()) do
                if descendant:IsA("Pose") and descendant.Weight > 0 then
                    posesInLastKeyframe = posesInLastKeyframe + 1
                    break
                end
            end
            
            if posesInLastKeyframe == 0 then
                local secondToLastKeyframe = allKeyframes[#allKeyframes - 1]
                self.ExcessTime = lastKeyframe.Time - secondToLastKeyframe.Time
                table.remove(allKeyframes, #allKeyframes)
            end
        end
        
        if #allKeyframes == 0 then return end
        
        local keyframePoses = {}
        local motorPoseData = {}
        
        for i, keyframe in ipairs(allKeyframes) do
            keyframePoses[i] = { Time = keyframe.Time, Poses = {} }
            
            for _, pose in pairs(keyframe:GetDescendants()) do
                if pose:IsA("Pose") and pose.Weight > 0 then
                    local motorKey = pose.Name .. "." .. pose.Parent.Name
                    
                    if not motorPoseData[motorKey] then
                        local motor = self:FindMotor(pose)
                        if motor then
                            motorPoseData[motorKey] = { Motor = motor, Name = motor.Name }
                            self.MotorCache[motor.Name] = motor
                        end
                    end
                    
                    if motorPoseData[motorKey] then
                        keyframePoses[i].Poses[motorPoseData[motorKey].Name] = pose
                    end
                end
            end
        end
        
        self.keyframePoses = keyframePoses
        
        local lastPoseData = {}
        for i = 1, #allKeyframes - 1 do
            local kf1_Data = keyframePoses[i]
            local kf2_Data = keyframePoses[i+1]
            
            local timeDiff = kf2_Data.Time - kf1_Data.Time
            self.TweenTracks[i] = { Time = timeDiff, Tweens = {} }
            
            local tweenDuration = (ENABLE_INTERPOLATION and timeDiff) or 0
            
            for name, pose in pairs(kf1_Data.Poses) do
                lastPoseData[name] = pose
            end
            
            for name, pose2 in pairs(kf2_Data.Poses) do
                local pose1 = lastPoseData[name]
                
                if pose1 and self.MotorCache[name] then
                    local style = EasingStyles[pose1.EasingStyle] or Enum.EasingStyle.Linear
                    local dir = EasingDirections[pose1.EasingDirection] or Enum.EasingDirection.Out
                    
                    local tweenInfo = TweenInfo.new(tweenDuration, style, dir)
                    local motor = self.MotorCache[name]
                    
                    self.TweenTracks[i].Tweens[name] = TweenSvc:Create(motor, tweenInfo, {Transform = pose2.CFrame})
                end
            end
        end
        
        if self.IsLooping and #allKeyframes > 0 then
            local lastKfData = keyframePoses[#allKeyframes]
            local firstKfData = keyframePoses[1]
            
            local loopTime = self.ExcessTime > 0 and self.ExcessTime or 0
            
            local lastGroupIndex = #self.TweenTracks + 1
            self.TweenTracks[lastGroupIndex] = { Time = loopTime, Tweens = {} }
            
            local tweenDuration = (ENABLE_INTERPOLATION and loopTime) or 0
            
            for name, pose in pairs(lastKfData.Poses) do
                lastPoseData[name] = pose
            end
            
            for name, pose1 in pairs(firstKfData.Poses) do
                local poseLast = lastPoseData[name]
                
                if poseLast and self.MotorCache[name] then
                    local style = EasingStyles[poseLast.EasingStyle] or Enum.EasingStyle.Linear
                    local dir = EasingDirections[poseLast.EasingDirection] or Enum.EasingDirection.Out
                    
                    local tweenInfo = TweenInfo.new(tweenDuration, style, dir)
                    local motor = self.MotorCache[name]
                    
                    self.TweenTracks[lastGroupIndex].Tweens[name] = TweenSvc:Create(motor, tweenInfo, {Transform = pose1.CFrame})
                end
            end
        end
    end
    
    local CharacterStates = {}
    
    local function disableDefaultAnimations(character)
        local humanoid = character:FindFirstChild("Humanoid")
        if humanoid then
            local animator = humanoid:FindFirstChildOfClass("Animator")
            if animator then
                animator:Destroy()
            end
        end
        
        local animateScript = character:FindFirstChild("Animate")
        if animateScript then
            animateScript:Destroy()
        end
    end
    
    local function setupCharacter(targetCharacter)
        if CharacterStates[targetCharacter] then return CharacterStates[targetCharacter] end
        
        disableDefaultAnimations(targetCharacter)
        
        local animPlayerSet = {
        Idle = AnimSequences.Idle and R6SequencePlayer.new(targetCharacter, AnimSequences.Idle, true),
        Walk = AnimSequences.Walk and R6SequencePlayer.new(targetCharacter, AnimSequences.Walk, true),
        Swim = AnimSequences.Swim and R6SequencePlayer.new(targetCharacter, AnimSequences.Swim, true),
        Jump = AnimSequences.Jump and R6SequencePlayer.new(targetCharacter, AnimSequences.Jump, false),
        Climb = AnimSequences.Climb and R6SequencePlayer.new(targetCharacter, AnimSequences.Climb, true),
        }
        
        for _, player in pairs(animPlayerSet) do
            if player then player:Load() end
        end
        
        local stateTable = {
        Players = animPlayerSet,
        Current = { player = nil, state = "None" }
        }
        
        CharacterStates[targetCharacter] = stateTable
        
        targetCharacter.Destroying:Connect(function()
            local data = CharacterStates[targetCharacter]
            if data and data.Current.player then
                data.Current.player:Stop()
            end
            CharacterStates[targetCharacter] = nil
        end)
        
        return stateTable
    end
    
    local function applyState(targetCharacter, newState)
        local data = setupCharacter(targetCharacter)
        local currentAnim = data.Current
        
        if currentAnim.state == newState and newState ~= "Jump" then return end
        
        if currentAnim.player then
            currentAnim.player:Stop()
        end
        
        local playerToPlay = data.Players[newState]
        if playerToPlay then
            playerToPlay:Play()
            currentAnim.player = playerToPlay
            currentAnim.state = newState
        else
            currentAnim.player = nil
            currentAnim.state = newState
            if targetCharacter:FindFirstChild("HumanoidRootPart") then
                R6SequencePlayer.new(targetCharacter):ResetPoses(0.1)
            end
        end
    end
    
    if Char.Parent == Workspace then
        applyState(Char, "Idle")
    end
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Character and player.Character.Parent == Workspace then
            setupCharacter(player.Character)
        end
    end
    
    Players.PlayerAdded:Connect(function(player)
        player.CharacterAdded:Connect(function(character)
        end)
        end)
            
            PlayAnimationState.OnClientEvent:Connect(function(targetPlayer, newState)
                local targetCharacter = targetPlayer.Character
                if targetCharacter and targetCharacter.Parent == Workspace then
                    applyState(targetCharacter, newState)
                end
            end)
