-- made by @simplyIeaf1 on youtube

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local gui = Instance.new("ScreenGui")
gui.Parent = player:WaitForChild("PlayerGui")

local giveEvent = ReplicatedStorage:WaitForChild("GiveItemEvent")
local toolEquipped
local prompts = {}
local activePopups = {}
local popupOffset = 120
local pendingGifts = {}

-- Utility to get torso
local function getTorso(character)
    return character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso") or character:FindFirstChild("HumanoidRootPart")
end

-- Remove all prompts
local function removeAllPrompts()
    for _, prompt in pairs(prompts) do
        if prompt and prompt.Parent then
            prompt:Destroy()
        end
    end
    prompts = {}
end

-- Create giver prompts
local function createPrompts(tool)
    removeAllPrompts()
    for _, otherPlayer in pairs(Players:GetPlayers()) do
        if otherPlayer ~= player and otherPlayer.Character then
            local torso = getTorso(otherPlayer.Character)
            if torso then
                local prompt = Instance.new("ProximityPrompt")
                prompt.ActionText = "Give"
                prompt.ObjectText = tool.Name
                prompt.RequiresLineOfSight = false
                prompt.MaxActivationDistance = 10
                prompt.Parent = torso

                prompt.Triggered:Connect(function(triggeringPlayer)
                    if triggeringPlayer == player then
                        if pendingGifts[otherPlayer.UserId] then return end
                        pendingGifts[otherPlayer.UserId] = tool.Name
                        giveEvent:FireServer(otherPlayer.UserId, tool.Name, "Request")
                    end
                end)

                prompts[otherPlayer.UserId] = prompt
            end
        end
    end
end

-- Tool equipped/unequipped
local function onToolEquipped(tool)
    toolEquipped = tool
    createPrompts(tool)
end

local function onToolUnequipped()
    toolEquipped = nil
    removeAllPrompts()
end

local function connectTool(tool)
    if tool:IsA("Tool") then
        tool.Equipped:Connect(function() onToolEquipped(tool) end)
        tool.Unequipped:Connect(onToolUnequipped)
    end
end

for _, tool in pairs(player.Backpack:GetChildren()) do connectTool(tool) end
player.Backpack.ChildAdded:Connect(connectTool)
player.CharacterAdded:Connect(function()
    if toolEquipped then
        createPrompts(toolEquipped)
    end
end)

-- Show modern popup middle-left
local function showPopup(senderUserId, itemName)
    local sender = Players:GetPlayerByUserId(senderUserId)
    if not sender then return end

    local viewportSize = gui.AbsoluteSize
    local scale = math.max(viewportSize.X / 1920, 0.7)
    local frameWidth = 300 * scale
    local frameHeight = 100 * scale

    local frame = Instance.new("Frame")
    frame.AnchorPoint = Vector2.new(0,0.5)
    frame.Size = UDim2.new(0, frameWidth, 0, frameHeight)
    frame.Position = UDim2.new(-1,0,0.5,0)
    frame.BackgroundColor3 = Color3.fromRGB(30,30,30)
    frame.BorderSizePixel = 0
    frame.Parent = gui
    frame.ClipsDescendants = true
    local round = Instance.new("UICorner")
    round.CornerRadius = UDim.new(0,12)
    round.Parent = frame

    -- Label
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1,-20,0,frameHeight*0.5)
    label.Position = UDim2.new(0,10,0,10)
    label.BackgroundTransparency = 1
    label.Text = "Gift from @"..sender.Name.."\n"..itemName
    label.TextColor3 = Color3.fromRGB(255,255,255)
    label.TextScaled = true
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextYAlignment = Enum.TextYAlignment.Top
    label.Font = Enum.Font.Gotham
    label.Parent = frame

    -- Accept button
    local accept = Instance.new("TextButton")
    accept.Size = UDim2.new(0.45,0,0.3,0)
    accept.Position = UDim2.new(0.05,0,0.65,0)
    accept.Text = "Accept"
    accept.BackgroundColor3 = Color3.fromRGB(0,200,100)
    accept.TextColor3 = Color3.fromRGB(255,255,255)
    accept.Font = Enum.Font.Gotham
    accept.TextScaled = true
    accept.Parent = frame
    local acceptCorner = Instance.new("UICorner")
    acceptCorner.CornerRadius = UDim.new(0,8)
    acceptCorner.Parent = accept

    -- Decline button
    local decline = Instance.new("TextButton")
    decline.Size = UDim2.new(0.45,0,0.3,0)
    decline.Position = UDim2.new(0.5,0,0.65,0)
    decline.Text = "Decline"
    decline.BackgroundColor3 = Color3.fromRGB(200,50,50)
    decline.TextColor3 = Color3.fromRGB(255,255,255)
    decline.Font = Enum.Font.Gotham
    decline.TextScaled = true
    decline.Parent = frame
    local declineCorner = Instance.new("UICorner")
    declineCorner.CornerRadius = UDim.new(0,8)
    declineCorner.Parent = decline

    table.insert(activePopups, frame)

    local function updatePositions()
        for i, popup in ipairs(activePopups) do
            local targetY = viewportSize.Y*0.5 + (i-1)*popupOffset - ((#activePopups-1)*popupOffset/2)
            local tween = TweenService:Create(popup, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {Position=UDim2.new(0,20,0,targetY)})
            tween:Play()
        end
    end

    local function closePopup(action)
        local index = table.find(activePopups, frame)
        if index then
            table.remove(activePopups, index)
        end
        local tweenOut = TweenService:Create(frame, TweenInfo.new(0.5, Enum.EasingStyle.Quad), {Position=UDim2.new(-1,0,0,frame.Position.Y.Offset)})
        tweenOut:Play()
        tweenOut.Completed:Connect(function()
            frame:Destroy()
            updatePositions()
        end)
        if action then
            giveEvent:FireServer(sender.UserId, itemName, action)
        end
        pendingGifts[sender.UserId] = nil
    end

    accept.MouseButton1Click:Connect(function() closePopup("Accept") end)
    decline.MouseButton1Click:Connect(function() closePopup("Decline") end)

    -- Slide in
    local targetY = viewportSize.Y*0.5 + (#activePopups-1)*popupOffset - ((#activePopups-1)*popupOffset/2)
    local tweenIn = TweenService:Create(frame, TweenInfo.new(0.5, Enum.EasingStyle.Quad), {Position=UDim2.new(0,20,0,targetY)})
    tweenIn:Play()
end

giveEvent.OnClientEvent:Connect(showPopup)