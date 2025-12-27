local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local StartCountdown = ReplicatedStorage:WaitForChild("StartCountdown", 10)
if not StartCountdown then
    warn("StartCountdown RemoteEvent not found")
    return
end

local MAX_COUNTDOWN_TIME = 31536000
local currentGui = nil
local isProcessing = false

local function validateData(endTime, format)
    if type(endTime) ~= "number" then return false end
    if endTime < 0 or endTime > os.time() + MAX_COUNTDOWN_TIME then return false end
    if type(format) ~= "table" then return false end
    
    for _, v in ipairs(format) do
        if type(v) ~= "string" then return false end
        if v ~= "days" and v ~= "hours" and v ~= "minutes" and v ~= "seconds" then
            return false
        end
    end
    
    return true
end

local function formatTime(rem, format)
    if type(rem) ~= "number" or rem < 0 then return "00:00:00:00" end
    
    local days = math.floor(rem / 86400)
    local hours = math.floor((rem % 86400) / 3600)
    local minutes = math.floor((rem % 3600) / 60)
    local seconds = rem % 60
    
    if #format == 0 then
        return string.format("%02d:%02d:%02d:%02d", days, hours, minutes, seconds)
    end
    
    local hasDay = table.find(format, "days")
    local hasHour = table.find(format, "hours")
    local hasMinute = table.find(format, "minutes")
    local hasSecond = table.find(format, "seconds")
    
    local parts = {}
    
    if hasDay then
        table.insert(parts, string.format("%02d", days))
        table.insert(parts, string.format("%02d", hours))
        table.insert(parts, string.format("%02d", minutes))
        table.insert(parts, string.format("%02d", seconds))
    elseif hasHour then
        table.insert(parts, string.format("%02d", hours))
        table.insert(parts, string.format("%02d", minutes))
        table.insert(parts, string.format("%02d", seconds))
    elseif hasMinute then
        table.insert(parts, string.format("%02d", minutes))
        table.insert(parts, string.format("%02d", seconds))
    elseif hasSecond then
        table.insert(parts, string.format("%02d", seconds))
    end
    
    if #parts == 0 then
        return "00:00:00:00"
    end
    
    return table.concat(parts, ":")
end

StartCountdown.OnClientEvent:Connect(function(endTime, format)
    if isProcessing then return end
    isProcessing = true
    
    if currentGui and currentGui.Parent then
        local label = currentGui:FindFirstChild("CountdownLabel")
        if label then
            local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
            local slideOut = TweenService:Create(label, tweenInfo, {
                Position = UDim2.new(0.5, 0, -0.1, 0),
                TextTransparency = 1,
                TextStrokeTransparency = 1
            })
            slideOut:Play()
            slideOut.Completed:Wait()
        end
        currentGui:Destroy()
        currentGui = nil
    end
    
    if not endTime or endTime <= 0 then
        isProcessing = false
        return
    end
    
    if not validateData(endTime, format) then
        isProcessing = false
        return
    end
    
    local player = Players.LocalPlayer
    if not player then
        isProcessing = false
        return
    end
    
    local playerGui = player:FindFirstChildOfClass("PlayerGui")
    if not playerGui then
        isProcessing = false
        return
    end
    
    local existingGui = playerGui:FindFirstChild("CountdownGui")
    if existingGui then
        existingGui:Destroy()
    end
    
    local remaining = endTime - os.time()
    if remaining <= 0 then
        isProcessing = false
        return
    end
    
    format = format or {}
    
    -- Create ScreenGui with responsive scaling
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "CountdownGui"
    screenGui.ResetOnSpawn = false
    screenGui.DisplayOrder = 100
    screenGui.IgnoreGuiInset = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    -- Create UIScale constraint for responsive sizing
    local uiScale = Instance.new("UIScale")
    uiScale.Parent = screenGui
    
    -- Create container frame for better positioning and scaling
    local container = Instance.new("Frame")
    container.Name = "Container"
    container.Size = UDim2.new(0, 400, 0, 80)
    container.Position = UDim2.new(0.5, 0, 0.1, 0)
    container.AnchorPoint = Vector2.new(0.5, 0.5)
    container.BackgroundTransparency = 1
    container.Parent = screenGui
    
    -- Add UIAspectRatioConstraint to maintain proportions
    local aspectRatio = Instance.new("UIAspectRatioConstraint")
    aspectRatio.AspectRatio = 5
    aspectRatio.Parent = container
    
    -- Create text label with scale constraints
    local textLabel = Instance.new("TextLabel")
    textLabel.Name = "CountdownLabel"
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.Position = UDim2.new(0.5, 0, 0.5, 0)
    textLabel.AnchorPoint = Vector2.new(0.5, 0.5)
    textLabel.BackgroundTransparency = 1
    textLabel.TextColor3 = Color3.new(1, 1, 1)
    textLabel.Font = Enum.Font.GothamBold
    textLabel.TextScaled = true
    textLabel.TextStrokeTransparency = 1
    textLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    textLabel.TextTransparency = 1
    textLabel.Text = formatTime(remaining, format)
    textLabel.Parent = container
    
    -- Add UITextSizeConstraint for better control
    local textSizeConstraint = Instance.new("UITextSizeConstraint")
    textSizeConstraint.MaxTextSize = 48
    textSizeConstraint.MinTextSize = 16
    textSizeConstraint.Parent = textLabel
    
    -- Position container off-screen initially for animation
    container.Position = UDim2.new(0.5, 0, -0.1, 0)
    
    screenGui.Parent = playerGui
    currentGui = screenGui
    
    -- Animate container instead of label for smoother scaling
    local tweenInfo = TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local slideIn = TweenService:Create(container, tweenInfo, {
        Position = UDim2.new(0.5, 0, 0.1, 0)
    })
    local fadeIn = TweenService:Create(textLabel, tweenInfo, {
        TextTransparency = 0,
        TextStrokeTransparency = 0
    })
    
    slideIn:Play()
    fadeIn:Play()
    
    isProcessing = false
    
    local updateThread = task.spawn(function()
        local lastUpdate = os.time()
        
        while screenGui.Parent and textLabel.Parent do
            task.wait(0.5)
            
            local currentTime = os.time()
            if currentTime == lastUpdate then continue end
            lastUpdate = currentTime
            
            remaining = endTime - currentTime
            
            if remaining > 0 and remaining <= MAX_COUNTDOWN_TIME then
                textLabel.Text = formatTime(remaining, format)
            else
                break
            end
        end
        
        if not screenGui.Parent then return end
        
        textLabel.Text = formatTime(0, format)
        task.wait(2)
        
        if not screenGui.Parent then return end
        
        local fadeOutContainer = TweenService:Create(container, tweenInfo, {
            Position = UDim2.new(0.5, 0, -0.1, 0)
        })
        local fadeOutText = TweenService:Create(textLabel, tweenInfo, {
            TextTransparency = 1,
            TextStrokeTransparency = 1
        })
        
        fadeOutContainer:Play()
        fadeOutText:Play()
        fadeOutContainer.Completed:Wait()
        
        if screenGui.Parent then
            screenGui:Destroy()
        end
        
        if currentGui == screenGui then
            currentGui = nil
        end
    end)
end)