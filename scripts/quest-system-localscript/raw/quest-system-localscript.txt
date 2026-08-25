local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ContentProvider = game:GetService("ContentProvider")
local Debris = game:GetService("Debris")

local plr = Players.LocalPlayer
local cam = workspace.CurrentCamera
local questEvent = RS:WaitForChild("QuestEvent")

local SOUND_ID = "rbxassetid://9120299323"
local INTERACT_DIST = 15
local FIXED_DIST = 20
local TW, TH = 280, 118
local studTex = "rbxthumb://type=Asset&id=14905298664&w=150&h=150"

ContentProvider:PreloadAsync({SOUND_ID})

local npc = questEvent:InvokeServer("GetNPC")
local npcHead = npc:WaitForChild("Head")
local npcRoot = npc:WaitForChild("HumanoidRootPart")

local hl = Instance.new("Highlight")
hl.FillTransparency = 1
hl.OutlineColor = Color3.new(0, 0, 0)
hl.OutlineTransparency = 0
hl.Enabled = false
hl.Parent = npc

local pgui = plr:WaitForChild("PlayerGui")

local conns = {}
local dialogOpen = false
local pollThread = nil

local function playLetterSound(part)
    local snd = Instance.new("Sound")
    snd.SoundId = SOUND_ID
    snd.Volume = 65
    snd.Parent = part
    snd:Play()
    Debris:AddItem(snd, 3)
end

local function studTexture(parent, z)
    local img = Instance.new("ImageLabel")
    img.Size = UDim2.new(1, 0, 1, 0)
    img.BackgroundTransparency = 1
    img.Image = studTex
    img.ImageTransparency = 0.88
    img.ScaleType = Enum.ScaleType.Tile
    img.TileSize = UDim2.new(0, 50, 0, 50)
    img.ZIndex = z
    img.Parent = parent
    return img
end

local function topBar(parent, w, h)
    local clip = Instance.new("Frame")
    clip.Size = UDim2.new(0, w, 0, h)
    clip.BackgroundTransparency = 1
    clip.ClipsDescendants = true
    clip.ZIndex = 2
    clip.Parent = parent
    
    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(0, w, 0, h + 10)
    bar.BackgroundColor3 = Color3.new(1, 1, 1)
    bar.BorderSizePixel = 0
    bar.ZIndex = 2
    bar.Parent = clip
    
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 10)
    c.Parent = bar
    
    local g = Instance.new("UIGradient")
    g.Color = ColorSequence.new(Color3.fromRGB(28, 175, 28), Color3.fromRGB(10, 95, 10))
    g.Rotation = 90
    g.Parent = bar
    
    local st = studTexture(bar, 3)
    local sc = Instance.new("UICorner")
    sc.CornerRadius = UDim.new(0, 10)
    sc.Parent = st
    
    local border = Instance.new("Frame")
    border.Size = UDim2.new(0, w, 0, 2)
    border.Position = UDim2.new(0, 0, 1, -2)
    border.BackgroundColor3 = Color3.new(0, 0, 0)
    border.BorderSizePixel = 0
    border.ZIndex = 4
    border.Parent = clip
    
    return clip
end

local function makeBtn(parent, txt, x, y, w, h, z)
    z = z or 5
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, w, 0, h)
    btn.Position = UDim2.new(0, x, 0, y)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.ZIndex = z
    btn.AutoButtonColor = false
    btn.Parent = parent
    
    local bg = Instance.new("Frame")
    bg.Size = UDim2.new(1, 0, 1, 0)
    bg.BackgroundColor3 = Color3.new(1, 1, 1)
    bg.BorderSizePixel = 0
    bg.ZIndex = z
    bg.Parent = btn
    
    local bc = Instance.new("UICorner")
    bc.CornerRadius = UDim.new(0, 8)
    bc.Parent = bg
    
    local bs = Instance.new("UIStroke")
    bs.Thickness = 2
    bs.Color = Color3.new(0, 0, 0)
    bs.Parent = bg
    
    local g = Instance.new("UIGradient")
    g.Color = ColorSequence.new(Color3.fromRGB(28, 175, 28), Color3.fromRGB(10, 95, 10))
    g.Rotation = 90
    g.Parent = bg
    
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = txt
    lbl.TextColor3 = Color3.new(1, 1, 1)
    lbl.Font = Enum.Font.FredokaOne
    lbl.TextSize = math.max(13, math.floor(h * 0.44))
    lbl.ZIndex = z + 1
    lbl.Parent = btn
    
    local ls = Instance.new("UIStroke")
    ls.Thickness = 2
    ls.Color = Color3.new(0, 0, 0)
    ls.Parent = lbl
    
    return btn
end

local function buildTracker()
    local old = pgui:FindFirstChild("QuestTrackerGui")
    if old then
        old:Destroy()
    end
    
    local gui = Instance.new("ScreenGui")
    gui.Name = "QuestTrackerGui"
    gui.ResetOnSpawn = false
    gui.Parent = pgui
    
    local scale = Instance.new("UIScale")
    scale.Parent = gui
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, TW, 0, TH)
    frame.Position = UDim2.new(0, 20, 0.5, 60)
    frame.AnchorPoint = Vector2.new(0, 0.5)
    frame.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
    frame.BorderSizePixel = 0
    frame.Visible = false
    frame.Parent = gui
    
    local fc = Instance.new("UICorner")
    fc.CornerRadius = UDim.new(0, 10)
    fc.Parent = frame
    
    local fs = Instance.new("UIStroke")
    fs.Thickness = 3
    fs.Color = Color3.fromRGB(50, 50, 50)
    fs.Parent = frame
    
    local fst = studTexture(frame, 2)
    local fsc = Instance.new("UICorner")
    fsc.CornerRadius = UDim.new(0, 10)
    fsc.Parent = fst
    
    local topH = 36
    local clip = topBar(frame, TW, topH)
    
    local titleLbl = Instance.new("TextLabel")
    titleLbl.Size = UDim2.new(0, TW - 16, 0, topH)
    titleLbl.Position = UDim2.new(0, 8, 0, 0)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Text = "Quest"
    titleLbl.TextColor3 = Color3.new(1, 1, 1)
    titleLbl.Font = Enum.Font.FredokaOne
    titleLbl.TextSize = 18
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.ZIndex = 5
    titleLbl.Parent = clip
    
    local tts = Instance.new("UIStroke")
    tts.Thickness = 2
    tts.Color = Color3.new(0, 0, 0)
    tts.Parent = titleLbl
    
    local descLbl = Instance.new("TextLabel")
    descLbl.Size = UDim2.new(0, TW - 20, 0, 36)
    descLbl.Position = UDim2.new(0, 10, 0, topH + 6)
    descLbl.BackgroundTransparency = 1
    descLbl.Text = ""
    descLbl.TextColor3 = Color3.fromRGB(200, 200, 200)
    descLbl.Font = Enum.Font.FredokaOne
    descLbl.TextSize = 15
    descLbl.TextWrapped = true
    descLbl.TextXAlignment = Enum.TextXAlignment.Left
    descLbl.ZIndex = 3
    descLbl.Parent = frame
    
    local ds = Instance.new("UIStroke")
    ds.Thickness = 1
    ds.Color = Color3.new(0, 0, 0)
    ds.Parent = descLbl
    
    local progLbl = Instance.new("TextLabel")
    progLbl.Size = UDim2.new(0, TW - 20, 0, 22)
    progLbl.Position = UDim2.new(0, 10, 0, topH + 46)
    progLbl.BackgroundTransparency = 1
    progLbl.Text = ""
    progLbl.TextColor3 = Color3.new(1, 1, 1)
    progLbl.Font = Enum.Font.GothamBold
    progLbl.TextSize = 13
    progLbl.TextXAlignment = Enum.TextXAlignment.Left
    progLbl.ZIndex = 3
    progLbl.Parent = frame
    
    local ps = Instance.new("UIStroke")
    ps.Thickness = 1
    ps.Color = Color3.new(0, 0, 0)
    ps.Parent = progLbl
    
    local scaleConn = RunService.RenderStepped:Connect(function()
        local vp = cam.ViewportSize
        if vp.X > 0 and vp.Y > 0 then
            scale.Scale = math.min(vp.X / 1920, vp.Y / 1080)
        end
    end)
    table.insert(conns, scaleConn)
    
    local function refresh(d)
        if not frame.Parent then
            return
        end
        if d and d.State > 0 and d.Quest then
            frame.Visible = true
            descLbl.Text = d.Quest.Desc
            if d.State == 2 then
                progLbl.Text = "Completed, return to NPC"
                progLbl.TextColor3 = Color3.fromRGB(50, 255, 50)
            else
                progLbl.Text = math.floor(d.Progress) .. " / " .. d.Quest.Target
                progLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
            end
        else
            frame.Visible = false
        end
    end
    
    if pollThread then
        task.cancel(pollThread)
        pollThread = nil
    end
    
    pollThread = task.spawn(function()
        while true do
            task.wait(1)
            if not frame.Parent then
                break
            end
            local ok, result = pcall(function()
                return questEvent:InvokeServer("GetState")
            end)
            if ok then
                refresh(result)
            end
        end
    end)
    
    task.wait(1)
    local ok, result = pcall(function()
        return questEvent:InvokeServer("GetState")
    end)
    if ok then
        refresh(result)
    end
end

local function typeText(part, txt, cb)
    local bb = Instance.new("BillboardGui")
    bb.Size = UDim2.new(0, 250, 0, 50)
    bb.StudsOffset = Vector3.new(0, 3, 0)
    bb.AlwaysOnTop = true
    bb.DistanceLowerLimit = FIXED_DIST
    bb.DistanceUpperLimit = FIXED_DIST
    bb.Parent = part
    
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = ""
    lbl.TextColor3 = Color3.new(1, 1, 1)
    lbl.TextStrokeTransparency = 0
    lbl.Font = Enum.Font.GothamBold
    lbl.TextWrapped = true
    lbl.TextSize = 18
    lbl.Parent = bb
    
    task.spawn(function()
        for i = 1, #txt do
            lbl.Text = txt:sub(1, i)
            playLetterSound(part)
            task.wait(0.03)
        end
        task.wait(1.5)
        if cb then
            cb(bb)
        else
            local tw = TweenService:Create(lbl, TweenInfo.new(0.5), {TextTransparency = 1, TextStrokeTransparency = 1})
            tw:Play()
            tw.Completed:Wait()
            bb:Destroy()
            dialogOpen = false
        end
    end)
end

local function showOptions(opts)
    local old = pgui:FindFirstChild("DialogueOptions")
    if old then
        old:Destroy()
    end
    
    local sg = Instance.new("ScreenGui")
    sg.Name = "DialogueOptions"
    sg.IgnoreGuiInset = true
    sg.ResetOnSpawn = false
    sg.Parent = pgui
    
    local uiScale = Instance.new("UIScale")
    uiScale.Parent = sg
    
    local safe = Instance.new("Frame")
    safe.AnchorPoint = Vector2.new(0.5, 0.5)
    safe.Position = UDim2.new(0.5, 0, 0.5, 0)
    safe.BackgroundTransparency = 1
    safe.Parent = sg
    
    local function updateSafe()
        local vp = cam.ViewportSize
        if vp.X <= 0 or vp.Y <= 0 then
            return
        end
        local s = math.min(vp.X / 1920, vp.Y / 1080)
        uiScale.Scale = s
        safe.Size = UDim2.new(0, vp.X / s, 0, vp.Y / s)
    end
    local vpConn = cam:GetPropertyChangedSignal("ViewportSize"):Connect(updateSafe)
    updateSafe()
    
    local BW = math.floor(275 * 1.1)
    local BH = math.floor(44 * 1.1)
    local GAP = math.floor(49 * 1.1)
    
    local cont = Instance.new("Frame")
    cont.Size = UDim2.new(0, BW, 0, #opts * GAP + 10)
    cont.AnchorPoint = Vector2.new(1, 0.5)
    cont.Position = UDim2.new(1, BW, 0.5, 0)
    cont.BackgroundTransparency = 1
    cont.Parent = safe
    
    local picked = false
    
    for i, optTxt in ipairs(opts) do
        local btn = makeBtn(cont, optTxt, 0, (i - 1) * GAP, BW, BH, 5)
        
        btn.Activated:Connect(function()
            if picked then
                return
            end
            picked = true
            
            local slideOut = TweenService:Create(
            cont,
            TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            {Position = UDim2.new(1, BW, 0.5, 0)}
            )
            slideOut:Play()
            slideOut.Completed:Connect(function()
                vpConn:Disconnect()
                sg:Destroy()
            end)
            
            local char = plr.Character
            if char and char:FindFirstChild("Head") then
                typeText(char.Head, optTxt, function(pBB)
                    local resp = questEvent:InvokeServer("SelectOption", optTxt)
                    local tw = TweenService:Create(
                    pBB:FindFirstChild("TextLabel"),
                    TweenInfo.new(0.5),
                    {TextTransparency = 1, TextStrokeTransparency = 1}
                    )
                    tw:Play()
                    tw.Completed:Connect(function()
                        pBB:Destroy()
                    end)
                    if resp then
                        typeText(npcHead, resp)
                    else
                        dialogOpen = false
                    end
                end)
            end
        end)
    end
    
    local slideIn = TweenService:Create(
    cont,
    TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    {Position = UDim2.new(1, -20, 0.5, 0)}
    )
    slideIn:Play()
end

local function cleanup()
    for _, c in ipairs(conns) do
        if typeof(c) == "RBXScriptConnection" and c.Connected then
            c:Disconnect()
        end
    end
    conns = {}
    local dg = pgui:FindFirstChild("DialogueOptions")
    if dg then
        dg:Destroy()
    end
    dialogOpen = false
end

local function setupChar(char)
    cleanup()
    
    local hum = char:WaitForChild("Humanoid")
    
    table.insert(conns, RunService.Heartbeat:Connect(function()
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then
            return
        end
        local dist = (root.Position - npcRoot.Position).Magnitude
        
        if dist <= INTERACT_DIST then
            hl.Enabled = true
        else
            hl.Enabled = false
        end
    end))
    
    table.insert(conns, UIS.InputBegan:Connect(function(input, proc)
        if proc or dialogOpen then
            return
        end
        if input.UserInputType ~= Enum.UserInputType.MouseButton1
            and input.UserInputType ~= Enum.UserInputType.Touch
            then
            return
        end
        
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then
            return
        end
        if (root.Position - npcRoot.Position).Magnitude > INTERACT_DIST then
            return
        end
        
        local mousePos = UIS:GetMouseLocation()
        local ray = cam:ViewportPointToRay(mousePos.X, mousePos.Y)
        local hit = workspace:Raycast(ray.Origin, ray.Direction * 1000)
        
        if not hit then
            return
        end
        local model = hit.Instance:FindFirstAncestorOfClass("Model")
        if model ~= npc then
            return
        end
        
        dialogOpen = true
        local txt, opts = questEvent:InvokeServer("Interact")
        if not txt then
            dialogOpen = false
            return
        end
        typeText(npcHead, txt, function(bb)
            local tw = TweenService:Create(
            bb:FindFirstChild("TextLabel"),
            TweenInfo.new(0.5),
            {TextTransparency = 1, TextStrokeTransparency = 1}
            )
            tw:Play()
            tw.Completed:Connect(function()
                bb:Destroy()
            end)
            if opts then
                showOptions(opts)
            else
                dialogOpen = false
            end
        end)
    end))
    
    table.insert(conns, hum.Died:Connect(function()
        hl.Enabled = false
        cleanup()
        if pollThread then
            task.cancel(pollThread)
            pollThread = nil
        end
        local tg = pgui:FindFirstChild("QuestTrackerGui")
        if tg then
            tg:Destroy()
        end
    end))
    
    buildTracker()
end

if plr.Character then
    setupChar(plr.Character)
end
plr.CharacterAdded:Connect(setupChar)