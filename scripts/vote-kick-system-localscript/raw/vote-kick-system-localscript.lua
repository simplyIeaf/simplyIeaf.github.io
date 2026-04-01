local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local voteKickEvent = ReplicatedStorage:WaitForChild("VoteKickEvent")
local voteKickFunction = ReplicatedStorage:WaitForChild("VoteKickFunction")

local textChannel = TextChatService:WaitForChild("TextChannels"):WaitForChild("RBXGeneral")

local pendingMessages = {}

TextChatService.OnIncomingMessage = function(Message)
    local properties = Instance.new("TextChatMessageProperties")
    
    if not Message.TextSource then
        local data = pendingMessages[Message.Text]
        if data then
            pendingMessages[Message.Text] = nil
            properties.Text = "<font color='#" .. data.color .. "'>" .. data.text .. "</font>"
        end
    end
    
    return properties
end

local function sendSystemMessage(text, color3)
    local hex = color3:ToHex()
    local tagged = "<font color='#" .. hex .. "'>" .. text .. "</font>"
    pendingMessages[tagged] = { text = text, color = hex }
    textChannel:DisplaySystemMessage(tagged)
end

local studTextureId = "rbxthumb://type=Asset&id=14905298664&w=150&h=150"

local debounce = false

local function checkDebounce()
    if debounce then return false end
    debounce = true
    task.delay(0.2, function() debounce = false end)
        return true
    end
    
    local function addStudTexture(parent, zIndex)
        local tex = Instance.new("ImageLabel")
        tex.Size = UDim2.new(1, 0, 1, 0)
        tex.Position = UDim2.new(0, 0, 0, 0)
        tex.BackgroundTransparency = 1
        tex.Image = studTextureId
        tex.ImageTransparency = 0.88
        tex.ScaleType = Enum.ScaleType.Tile
        tex.TileSize = UDim2.new(0, 50, 0, 50)
        tex.ZIndex = zIndex
        tex.Parent = parent
        return tex
    end
    
    local function makeTopBar(parent, w, h)
        local clipper = Instance.new("Frame")
        clipper.Size = UDim2.new(0, w, 0, h)
        clipper.Position = UDim2.new(0, 0, 0, 0)
        clipper.BackgroundTransparency = 1
        clipper.ClipsDescendants = true
        clipper.ZIndex = 2
        clipper.Parent = parent
        
        local bar = Instance.new("Frame")
        bar.Size = UDim2.new(0, w, 0, h + 10)
        bar.Position = UDim2.new(0, 0, 0, 0)
        bar.BackgroundColor3 = Color3.new(1, 1, 1)
        bar.BorderSizePixel = 0
        bar.ZIndex = 2
        bar.Parent = clipper
        
        local barCorner = Instance.new("UICorner")
        barCorner.CornerRadius = UDim.new(0, 10)
        barCorner.Parent = bar
        
        local barGrad = Instance.new("UIGradient")
        barGrad.Color = ColorSequence.new(Color3.fromRGB(28, 175, 28), Color3.fromRGB(10, 95, 10))
        barGrad.Rotation = 90
        barGrad.Parent = bar
        
        local barStudTex = addStudTexture(bar, 3)
        
        local barStudCorner = Instance.new("UICorner")
        barStudCorner.CornerRadius = UDim.new(0, 10)
        barStudCorner.Parent = barStudTex
        
        local bottomBorder = Instance.new("Frame")
        bottomBorder.Size = UDim2.new(0, w, 0, 2)
        bottomBorder.Position = UDim2.new(0, 0, 1, -2)
        bottomBorder.BackgroundColor3 = Color3.new(0, 0, 0)
        bottomBorder.BorderSizePixel = 0
        bottomBorder.ZIndex = 4
        bottomBorder.Parent = clipper
        
        return clipper, bar
    end
    
    local function createStyledButton(parent, text, styleType, px, py, sw, sh, zBase)
        local z = zBase or 5
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, sw, 0, sh)
        btn.Position = UDim2.new(0, px, 0, py)
        btn.BackgroundTransparency = 1
        btn.Text = ""
        btn.ZIndex = z
        btn.AutoButtonColor = false
        btn.Parent = parent
        
        local bg = Instance.new("Frame")
        bg.Size = UDim2.new(1, 0, 1, 0)
        bg.Position = UDim2.new(0, 0, 0, 0)
        bg.BackgroundColor3 = Color3.new(1, 1, 1)
        bg.BorderSizePixel = 0
        bg.ZIndex = z
        bg.Parent = btn
        
        local bgCorner = Instance.new("UICorner")
        bgCorner.CornerRadius = UDim.new(0, 8)
        bgCorner.Parent = bg
        
        local bgStroke = Instance.new("UIStroke")
        bgStroke.Thickness = 2
        bgStroke.Color = Color3.new(0, 0, 0)
        bgStroke.Parent = bg
        
        local grad = Instance.new("UIGradient")
        if styleType == "Green" then
            grad.Color = ColorSequence.new(Color3.fromRGB(20, 150, 20), Color3.fromRGB(8, 80, 8))
        elseif styleType == "Red" then
            grad.Color = ColorSequence.new(Color3.fromRGB(170, 22, 22), Color3.fromRGB(90, 8, 8))
        else
            grad.Color = ColorSequence.new(Color3.fromRGB(90, 90, 90), Color3.fromRGB(50, 50, 50))
        end
        grad.Rotation = 90
        grad.Parent = bg
        
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, 0, 1, 0)
        lbl.Position = UDim2.new(0, 0, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = text
        lbl.TextColor3 = Color3.new(1, 1, 1)
        lbl.Font = Enum.Font.FredokaOne
        lbl.TextScaled = false
        lbl.TextSize = math.max(13, math.floor(sh * 0.44))
        lbl.ZIndex = z + 1
        lbl.Parent = btn
        
        local txtStroke = Instance.new("UIStroke")
        txtStroke.Thickness = 2
        txtStroke.Color = Color3.new(0, 0, 0)
        txtStroke.Parent = lbl
        
        return btn
    end
    
    local function showPrompt(targetDisplayName, targetUsername, targetUserId, voteDuration)
        local uiName = "VoteKickPrompt_" .. targetUserId
        if player.PlayerGui:FindFirstChild(uiName) then return end
        
        local sg = Instance.new("ScreenGui")
        sg.Name = uiName
        sg.ResetOnSpawn = false
        sg.IgnoreGuiInset = true
        sg.Parent = player.PlayerGui
        
        local uiScale = Instance.new("UIScale")
        uiScale.Parent = sg
        
        local safeFrame = Instance.new("Frame")
        safeFrame.Name = "SafeFrame"
        safeFrame.AnchorPoint = Vector2.new(0.5, 0.5)
        safeFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
        safeFrame.BackgroundTransparency = 1
        safeFrame.Parent = sg
        
        local promptConnections = {}
        local function update()
            local vp = camera.ViewportSize
            if vp.X <= 0 or vp.Y <= 0 then return end
            local scale = math.min(vp.X / 1920, vp.Y / 1080)
            uiScale.Scale = scale
            safeFrame.Size = UDim2.new(0, vp.X / scale, 0, vp.Y / scale)
        end
        table.insert(promptConnections, camera:GetPropertyChangedSignal("ViewportSize"):Connect(update))
        update()
        
        local PW, PH = 420, 225
        
        local fr = Instance.new("Frame")
        fr.Size = UDim2.new(0, PW, 0, PH)
        fr.AnchorPoint = Vector2.new(0.5, 0.5)
        fr.Position = UDim2.new(0.5, 0, 0.5, 0)
        fr.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
        fr.BorderSizePixel = 0
        fr.Parent = safeFrame
        
        local frCorner = Instance.new("UICorner")
        frCorner.CornerRadius = UDim.new(0, 10)
        frCorner.Parent = fr
        
        local frStroke = Instance.new("UIStroke")
        frStroke.Thickness = 3
        frStroke.Color = Color3.fromRGB(50, 50, 50)
        frStroke.Parent = fr
        
        local frStudTex = addStudTexture(fr, 2)
        
        local frStudCorner = Instance.new("UICorner")
        frStudCorner.CornerRadius = UDim.new(0, 10)
        frStudCorner.Parent = frStudTex
        
        local topH = 44
        local topClipper, topAccent = makeTopBar(fr, PW, topH)
        
        local headerLbl = Instance.new("TextLabel")
        headerLbl.Size = UDim2.new(0, PW - 16, 0, topH)
        headerLbl.Position = UDim2.new(0, 8, 0, 0)
        headerLbl.BackgroundTransparency = 1
        headerLbl.Text = "Votekick Initiated"
        headerLbl.TextColor3 = Color3.new(1, 1, 1)
        headerLbl.Font = Enum.Font.FredokaOne
        headerLbl.TextScaled = false
        headerLbl.TextSize = 20
        headerLbl.ZIndex = 5
        headerLbl.Parent = topClipper
        
        local headerStroke = Instance.new("UIStroke")
        headerStroke.Thickness = 2
        headerStroke.Color = Color3.new(0, 0, 0)
        headerStroke.Parent = headerLbl
        
        local txt = Instance.new("TextLabel")
        txt.Text = "Do you want to votekick " .. targetDisplayName .. " (@" .. targetUsername .. ")?"
        txt.TextColor3 = Color3.fromRGB(200, 200, 200)
        txt.Size = UDim2.new(0, PW - 24, 0, 52)
        txt.Position = UDim2.new(0, 12, 0, topH + 16)
        txt.BackgroundTransparency = 1
        txt.Font = Enum.Font.FredokaOne
        txt.TextScaled = false
        txt.TextSize = 17
        txt.TextWrapped = true
        txt.ZIndex = 3
        txt.Parent = fr
        
        local txtStroke = Instance.new("UIStroke")
        txtStroke.Thickness = 1
        txtStroke.Color = Color3.new(0, 0, 0)
        txtStroke.Parent = txt
        
        local btnBW = math.floor((PW - 30) / 2)
        local btnBH = 40
        local btnBY = PH - btnBH - 30
        
        local yBtn = createStyledButton(fr, "Yes", "Green", 10, btnBY, btnBW, btnBH, 5)
        local nBtn = createStyledButton(fr, "No", "Red", 20 + btnBW, btnBY, btnBW, btnBH, 5)
        
        local timerLbl = Instance.new("TextLabel")
        timerLbl.Size = UDim2.new(0, PW - 20, 0, 20)
        timerLbl.Position = UDim2.new(0, 10, 0, btnBY + btnBH + 5)
        timerLbl.BackgroundTransparency = 1
        timerLbl.Text = tostring(voteDuration) .. " seconds left"
        timerLbl.TextColor3 = Color3.new(1, 1, 1)
        timerLbl.Font = Enum.Font.GothamBold
        timerLbl.TextScaled = false
        timerLbl.TextSize = 14
        timerLbl.TextXAlignment = Enum.TextXAlignment.Center
        timerLbl.ZIndex = 5
        timerLbl.Parent = fr
        
        local timerStroke = Instance.new("UIStroke")
        timerStroke.Thickness = 1.5
        timerStroke.Color = Color3.new(0, 0, 0)
        timerStroke.Parent = timerLbl
        
        local timeLeft = voteDuration
        local timerConn
        timerConn = game:GetService("RunService").Heartbeat:Connect(function(dt)
            timeLeft = timeLeft - dt
            local display = math.max(0, math.ceil(timeLeft))
            if timerLbl and timerLbl.Parent then
                timerLbl.Text = tostring(display) .. " seconds left"
            else
                timerConn:Disconnect()
            end
        end)
        table.insert(promptConnections, timerConn)
        
        local function destroyPrompt()
            for _, conn in ipairs(promptConnections) do
                if conn.Connected then conn:Disconnect() end
            end
            if sg and sg.Parent then sg:Destroy() end
        end
        
        yBtn.Activated:Connect(function()
            if not checkDebounce() then return end
            local success = voteKickFunction:InvokeServer("SubmitVote", targetUserId, "Yes")
            if success then destroyPrompt() end
        end)
        
        nBtn.Activated:Connect(function()
            if not checkDebounce() then return end
            local success = voteKickFunction:InvokeServer("SubmitVote", targetUserId, "No")
            if success then destroyPrompt() end
        end)
    end
    
    voteKickEvent.OnClientEvent:Connect(function(action, arg1, arg2, arg3, arg4)
        if action == "SystemMessage" then
            sendSystemMessage(arg1, arg2)
        elseif action == "ShowPrompt" then
            showPrompt(arg1, arg2, arg3, arg4)
        elseif action == "ClosePrompt" then
            local uiName = "VoteKickPrompt_" .. tostring(arg1)
            if player.PlayerGui:FindFirstChild(uiName) then
                player.PlayerGui[uiName]:Destroy()
            end
        end
    end)
   