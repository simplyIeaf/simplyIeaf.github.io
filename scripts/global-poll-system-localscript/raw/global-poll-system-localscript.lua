local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local RemotesFolder = ReplicatedStorage:WaitForChild("PollRemotes")
local PollEvent = RemotesFolder:WaitForChild("PollEvent")
local PollFunction = RemotesFolder:WaitForChild("PollFunction")

local adminPanelOpen = false
local adminPanelGui = nil
local adminRefs = {}
local activeTabIdx = 0

local pollGui = nil
local pollRefs = {}
local currentPollId = nil
local playerVote = nil

local function destroyPollGui(slideUp)
    if not pollGui then return end
    local container = pollGui:FindFirstChild("Container", true)
    if slideUp and container then
        local tween = TweenService:Create(
        container,
        TweenInfo.new(0.55, Enum.EasingStyle.Quint, Enum.EasingDirection.In),
        { Position = UDim2.new(0.5, 0, -0.25, 0) }
        )
        tween:Play()
        local guiRef = pollGui
        tween.Completed:Connect(function()
            if guiRef then guiRef:Destroy() end
            if pollGui == guiRef then
                pollGui = nil
                pollRefs = {}
                currentPollId = nil
                playerVote = nil
            end
        end)
    else
        pollGui:Destroy()
        pollGui = nil
        pollRefs = {}
        currentPollId = nil
        playerVote = nil
    end
end

local function destroyAdminPanel()
    if adminPanelGui then
        adminPanelGui:Destroy()
        adminPanelGui = nil
        adminRefs = {}
        adminPanelOpen = false
        activeTabIdx = 0
    end
end

player.CharacterAdded:Connect(function()
    destroyPollGui(false)
    destroyAdminPanel()
end)

local function corner(parent, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 6)
    c.Parent = parent
    return c
end

local function stroke(parent, t, col)
    local s = Instance.new("UIStroke")
    s.Thickness = t or 1.5
    s.Color = col or Color3.fromRGB(46, 46, 46)
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = parent
    return s
end

local function shadowStroke(parent, t)
    local s = Instance.new("UIStroke")
    s.Thickness = t or 2
    s.Color = Color3.fromRGB(0, 0, 0)
    s.Parent = parent
    return s
end

local function fmt(n)
    local s = tostring(math.floor(n))
    local out, len = "", #s
    for i = 1, len do
        if i > 1 and (len - i + 1) % 3 == 0 then out = out .. "," end
        out = out .. s:sub(i, i)
    end
    return out
end

local function tweenBar(refs, lv, rv)
    if not refs or not refs.red then return end
    local total = lv + rv
    local lr = total > 0 and (lv / total) or 0.5
    local ti = TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
    TweenService:Create(refs.red, ti, { Size = UDim2.new(lr, 0, 1, 0) }):Play()
    TweenService:Create(refs.blue, ti, {
    Size = UDim2.new(1 - lr, 0, 1, 0),
    Position = UDim2.new(lr, 0, 0, 0),
    }):Play()
    TweenService:Create(refs.sep, ti, { Position = UDim2.new(lr, -1, 0, 0) }):Play()
    if refs.leftNum then refs.leftNum.Text = fmt(lv) end
    if refs.rightNum then refs.rightNum.Text = fmt(rv) end
end

local function showPollGui(pollData)
    destroyPollGui(false)
    currentPollId = pollData.id
    playerVote = nil
    pollRefs = {}
    
    local gui = Instance.new("ScreenGui")
    gui.Name = "PollUI"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = playerGui
    pollGui = gui
    
    local container = Instance.new("Frame")
    container.Name = "Container"
    container.Size = UDim2.new(0.42, 0, 0.1, 0)
    container.Position = UDim2.new(0.5, 0, -0.25, 0)
    container.AnchorPoint = Vector2.new(0.5, 0)
    container.BackgroundTransparency = 1
    container.Parent = gui
    
    local aspect = Instance.new("UIAspectRatioConstraint")
    aspect.AspectRatio = 6.5
    aspect.Parent = container
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0.32, 0)
    title.Position = UDim2.new(0, 0, -0.06, 0)
    title.BackgroundTransparency = 1
    title.Text = pollData.question or "Who has more aura?"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.Font = Enum.Font.GothamBlack
    title.TextScaled = true
    title.Parent = container
    shadowStroke(title, 2.5)
    
    local leftNum = Instance.new("TextLabel")
    leftNum.Size = UDim2.new(0.15, 0, 0.28, 0)
    leftNum.Position = UDim2.new(-0.01, 0, 0.38, 0)
    leftNum.BackgroundTransparency = 1
    leftNum.Text = fmt(pollData.leftVotes or 0)
    leftNum.TextColor3 = Color3.fromRGB(255, 255, 255)
    leftNum.Font = Enum.Font.GothamBlack
    leftNum.TextScaled = true
    leftNum.TextXAlignment = Enum.TextXAlignment.Right
    leftNum.Parent = container
    shadowStroke(leftNum, 2)
    
    local rightNum = Instance.new("TextLabel")
    rightNum.Size = UDim2.new(0.15, 0, 0.28, 0)
    rightNum.Position = UDim2.new(0.86, 0, 0.38, 0)
    rightNum.BackgroundTransparency = 1
    rightNum.Text = fmt(pollData.rightVotes or 0)
    rightNum.TextColor3 = Color3.fromRGB(255, 255, 255)
    rightNum.Font = Enum.Font.GothamBlack
    rightNum.TextScaled = true
    rightNum.TextXAlignment = Enum.TextXAlignment.Left
    rightNum.Parent = container
    shadowStroke(rightNum, 2)
    
    local barBg = Instance.new("Frame")
    barBg.Size = UDim2.new(0.7, 0, 0.26, 0)
    barBg.Position = UDim2.new(0.15, 0, 0.38, 0)
    barBg.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    barBg.BorderSizePixel = 0
    barBg.ClipsDescendants = true
    barBg.Parent = container
    do
    local s = Instance.new("UIStroke")
    s.Color = Color3.fromRGB(0, 0, 0)
    s.Thickness = 2.5
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = barBg
end

local total = (pollData.leftVotes or 0) + (pollData.rightVotes or 0)
local lr = total > 0 and ((pollData.leftVotes or 0) / total) or 0.5

local red = Instance.new("Frame")
red.Size = UDim2.new(lr, 0, 1, 0)
red.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
red.BorderSizePixel = 0
red.Parent = barBg

local blue = Instance.new("Frame")
blue.Size = UDim2.new(1 - lr, 0, 1, 0)
blue.Position = UDim2.new(lr, 0, 0, 0)
blue.BackgroundColor3 = Color3.fromRGB(65, 155, 255)
blue.BorderSizePixel = 0
blue.Parent = barBg

local sep = Instance.new("Frame")
sep.Size = UDim2.new(0, 2, 1, 0)
sep.Position = UDim2.new(lr, -1, 0, 0)
sep.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
sep.BorderSizePixel = 0
sep.Parent = barBg

local btnsArea = Instance.new("Frame")
btnsArea.Size = UDim2.new(0.5, 0, 0.36, 0)
btnsArea.Position = UDim2.new(0.25, 0, 0.72, 0)
btnsArea.BackgroundTransparency = 1
btnsArea.Parent = container

local function makeVoteBtn(xPos, bgCol, label)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.44, 0, 1, 0)
    btn.Position = UDim2.new(xPos, 0, 0, 0)
    btn.BackgroundColor3 = bgCol
    btn.BorderSizePixel = 0
    btn.Text = label
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBlack
    btn.TextScaled = true
    btn.Parent = btnsArea
    do
    local s = Instance.new("UIStroke")
    s.Color = Color3.fromRGB(0, 0, 0)
    s.Thickness = 3
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = btn
end
do
local p = Instance.new("UIPadding")
p.PaddingTop = UDim.new(0.1, 0)
p.PaddingBottom = UDim.new(0.1, 0)
p.Parent = btn
end
shadowStroke(btn, 1.5)
return btn
end

local leftBtn = makeVoteBtn(0.03, Color3.fromRGB(220, 50, 50), pollData.leftLabel or "Left")
local rightBtn = makeVoteBtn(0.53, Color3.fromRGB(65, 155, 255), pollData.rightLabel or "Right")

pollRefs.red = red
pollRefs.blue = blue
pollRefs.sep = sep
pollRefs.leftNum = leftNum
pollRefs.rightNum = rightNum

local function applyHighlight(side)
    if side == "left" then
        leftBtn.BackgroundColor3 = Color3.fromRGB(255, 85, 85)
        rightBtn.BackgroundColor3 = Color3.fromRGB(40, 100, 180)
    else
        leftBtn.BackgroundColor3 = Color3.fromRGB(155, 28, 28)
        rightBtn.BackgroundColor3 = Color3.fromRGB(105, 195, 255)
    end
end
pollRefs.applyHighlight = applyHighlight

leftBtn.MouseButton1Click:Connect(function()
    if playerVote == "left" then return end
    playerVote = "left"
    applyHighlight("left")
    PollEvent:FireServer("vote", { pollId = currentPollId, side = "left" })
end)

rightBtn.MouseButton1Click:Connect(function()
    if playerVote == "right" then return end
    playerVote = "right"
    applyHighlight("right")
    PollEvent:FireServer("vote", { pollId = currentPollId, side = "right" })
end)

TweenService:Create(container, TweenInfo.new(0.65, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
Position = UDim2.new(0.5, 0, 0.03, 0),
}):Play()
end

local TIMEZONES = {
{ label = "UTC-12",         offset = -12  },
{ label = "UTC-11",         offset = -11  },
{ label = "UTC-10  (HST)",  offset = -10  },
{ label = "UTC-9   (AKST)", offset = -9   },
{ label = "UTC-8   (PST)",  offset = -8   },
{ label = "UTC-7   (MST)",  offset = -7   },
{ label = "UTC-6   (CST)",  offset = -6   },
{ label = "UTC-5   (EST)",  offset = -5   },
{ label = "UTC-4   (AST)",  offset = -4   },
{ label = "UTC-3",          offset = -3   },
{ label = "UTC-2",          offset = -2   },
{ label = "UTC-1",          offset = -1   },
{ label = "UTC+0   (GMT)",  offset = 0    },
{ label = "UTC+1   (CET)",  offset = 1    },
{ label = "UTC+2   (EET)",  offset = 2    },
{ label = "UTC+3   (MSK)",  offset = 3    },
{ label = "UTC+4",          offset = 4    },
{ label = "UTC+5",          offset = 5    },
{ label = "UTC+5:30 (IST)", offset = 5.5  },
{ label = "UTC+6",          offset = 6    },
{ label = "UTC+7   (WIB)",  offset = 7    },
{ label = "UTC+8   (CST)",  offset = 8    },
{ label = "UTC+9   (JST)",  offset = 9    },
{ label = "UTC+10  (AEST)", offset = 10   },
{ label = "UTC+11",         offset = 11   },
{ label = "UTC+12  (NZST)", offset = 12   },
}

local function makeInput(parent, placeholder, lo)
    local bg = Instance.new("Frame")
    bg.Size = UDim2.new(1, 0, 0, 34)
    bg.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
    bg.BorderSizePixel = 0
    bg.LayoutOrder = lo or 0
    bg.Parent = parent
    corner(bg, 6)
    stroke(bg, 1, Color3.fromRGB(46, 46, 46))
    local tb = Instance.new("TextBox")
    tb.Size = UDim2.new(1, -16, 1, 0)
    tb.Position = UDim2.new(0, 8, 0, 0)
    tb.BackgroundTransparency = 1
    tb.PlaceholderText = placeholder or ""
    tb.PlaceholderColor3 = Color3.fromRGB(60, 60, 60)
    tb.Text = ""
    tb.TextColor3 = Color3.fromRGB(215, 215, 215)
    tb.Font = Enum.Font.Gotham
    tb.TextSize = 12
    tb.TextXAlignment = Enum.TextXAlignment.Left
    tb.ClearTextOnFocus = false
    tb.Parent = bg
    return tb, bg
end

local function makeBtn(parent, text, bgCol, txtCol, lo)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 34)
    btn.BackgroundColor3 = bgCol or Color3.fromRGB(26, 26, 26)
    btn.BorderSizePixel = 0
    btn.Text = text
    btn.TextColor3 = txtCol or Color3.fromRGB(215, 215, 215)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 12
    btn.LayoutOrder = lo or 0
    btn.Parent = parent
    corner(btn, 6)
    stroke(btn, 1, Color3.fromRGB(50, 50, 50))
    return btn
end

local function secLabel(parent, text, lo)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 0, 13)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = Color3.fromRGB(85, 85, 85)
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 10
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.LayoutOrder = lo
    lbl.Parent = parent
    return lbl
end

local function makeScopeRow(parent, lo)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 34)
    row.BackgroundTransparency = 1
    row.LayoutOrder = lo or 0
    row.Parent = parent
    
    local sl = Instance.new("UIListLayout")
    sl.FillDirection = Enum.FillDirection.Horizontal
    sl.SortOrder = Enum.SortOrder.LayoutOrder
    sl.Padding = UDim.new(0, 8)
    sl.Parent = row
    
    local isGlobal = false
    
    local serverBtn = Instance.new("TextButton")
    serverBtn.Size = UDim2.new(0.5, -4, 1, 0)
    serverBtn.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
    serverBtn.BorderSizePixel = 0
    serverBtn.Text = "Server"
    serverBtn.TextColor3 = Color3.fromRGB(10, 10, 10)
    serverBtn.Font = Enum.Font.GothamBold
    serverBtn.TextSize = 12
    serverBtn.LayoutOrder = 1
    serverBtn.Parent = row
    corner(serverBtn, 6)
    stroke(serverBtn, 1, Color3.fromRGB(68, 68, 68))
    
    local globalBtn = Instance.new("TextButton")
    globalBtn.Size = UDim2.new(0.5, -4, 1, 0)
    globalBtn.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
    globalBtn.BorderSizePixel = 0
    globalBtn.Text = "Global"
    globalBtn.TextColor3 = Color3.fromRGB(100, 100, 100)
    globalBtn.Font = Enum.Font.GothamBold
    globalBtn.TextSize = 12
    globalBtn.LayoutOrder = 2
    globalBtn.Parent = row
    corner(globalBtn, 6)
    stroke(globalBtn, 1, Color3.fromRGB(44, 44, 44))
    
    serverBtn.MouseButton1Click:Connect(function()
        isGlobal = false
        serverBtn.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
        serverBtn.TextColor3 = Color3.fromRGB(10, 10, 10)
        globalBtn.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
        globalBtn.TextColor3 = Color3.fromRGB(100, 100, 100)
    end)
    
    globalBtn.MouseButton1Click:Connect(function()
        isGlobal = true
        globalBtn.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
        globalBtn.TextColor3 = Color3.fromRGB(10, 10, 10)
        serverBtn.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
        serverBtn.TextColor3 = Color3.fromRGB(100, 100, 100)
    end)
    
    return function() return isGlobal end
end

local function buildAdminPanel()
    if adminPanelOpen then
        destroyAdminPanel()
        return
    end
    adminPanelOpen = true
    
    -- ── Constants ────────────────────────────────────────────────
    local PW, PH   = 400, 440   -- panel pixel size
    local TOP_H    = 44         -- title bar height
    local TAB_H    = 34         -- tab bar height
    local PAD      = 14         -- horizontal padding inside panel
    local GAP      = 8          -- gap between title bar and tab bar
    local GAP2     = 8          -- gap between tab bar and content
    local CONTENT_Y = TOP_H + GAP + TAB_H + GAP2
    local CONTENT_H = PH - CONTENT_Y - 10
    
    -- ── ScreenGui + Panel ────────────────────────────────────────
    local sg = Instance.new("ScreenGui")
    sg.Name            = "PollAdminPanel"
    sg.ResetOnSpawn    = false
    sg.IgnoreGuiInset  = true
    sg.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
    sg.Parent          = playerGui
    adminPanelGui      = sg
    
    local panel = Instance.new("Frame")
    panel.Name             = "Panel"
    panel.Size             = UDim2.fromOffset(PW, PH)
    panel.Position         = UDim2.new(0.5, 0, 0.5, 0)
    panel.AnchorPoint      = Vector2.new(0.5, 0.5)
    panel.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
    panel.BorderSizePixel  = 0
    panel.Active           = true
    panel.Parent           = sg
    corner(panel, 10)
    stroke(panel, 1.5, Color3.fromRGB(40, 40, 40))
    
    -- ── Title bar ────────────────────────────────────────────────
    local topBar = Instance.new("Frame")
    topBar.Size             = UDim2.new(1, 0, 0, TOP_H)
    topBar.Position         = UDim2.fromOffset(0, 0)
    topBar.BackgroundColor3 = Color3.fromRGB(14, 14, 14)
    topBar.BorderSizePixel  = 0
    topBar.ZIndex           = 3
    topBar.Parent           = panel
    corner(topBar, 10)
    -- flat-bottom filler so only top corners are rounded
    local tbFill = Instance.new("Frame")
    tbFill.Size             = UDim2.new(1, 0, 0, 10)
    tbFill.Position         = UDim2.new(0, 0, 1, -10)
    tbFill.BackgroundColor3 = Color3.fromRGB(14, 14, 14)
    tbFill.BorderSizePixel  = 0
    tbFill.ZIndex           = 3
    tbFill.Parent           = topBar
    -- bottom divider
    local divider = Instance.new("Frame")
    divider.Size             = UDim2.new(1, 0, 0, 1)
    divider.Position         = UDim2.new(0, 0, 1, -1)
    divider.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
    divider.BorderSizePixel  = 0
    divider.ZIndex           = 4
    divider.Parent           = topBar
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size               = UDim2.new(1, -52, 1, 0)
    titleLabel.Position           = UDim2.fromOffset(16, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text               = "Poll Manager"
    titleLabel.TextColor3         = Color3.fromRGB(228, 228, 228)
    titleLabel.Font               = Enum.Font.GothamBold
    titleLabel.TextSize           = 14
    titleLabel.TextXAlignment     = Enum.TextXAlignment.Left
    titleLabel.ZIndex             = 4
    titleLabel.Parent             = topBar
    
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size             = UDim2.fromOffset(26, 26)
    closeBtn.Position         = UDim2.new(1, -36, 0.5, -13)
    closeBtn.BackgroundColor3 = Color3.fromRGB(26, 26, 26)
    closeBtn.BorderSizePixel  = 0
    closeBtn.Text             = "X"
    closeBtn.TextColor3       = Color3.fromRGB(150, 150, 150)
    closeBtn.Font             = Enum.Font.GothamBold
    closeBtn.TextSize         = 11
    closeBtn.ZIndex           = 4
    closeBtn.Parent           = topBar
    corner(closeBtn, 5)
    closeBtn.MouseButton1Click:Connect(destroyAdminPanel)
    
    -- drag
    local dragging, dragStart, startPos = false, nil, nil
    topBar.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
            or inp.UserInputType == Enum.UserInputType.Touch then
            dragging  = true
            dragStart = inp.Position
            startPos  = panel.Position
        end
    end)
    topBar.InputChanged:Connect(function(inp)
        if not dragging then return end
        if inp.UserInputType == Enum.UserInputType.MouseMovement
            or inp.UserInputType == Enum.UserInputType.Touch then
            local d = inp.Position - dragStart
            panel.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + d.X,
            startPos.Y.Scale, startPos.Y.Offset + d.Y
            )
        end
    end)
    topBar.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
            or inp.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    
    -- ── Tab bar ──────────────────────────────────────────────────
    -- Plain frame, no layout — two buttons manually at 0% and 50%
    local tabBar = Instance.new("Frame")
    tabBar.Size             = UDim2.new(1, -(PAD * 2), 0, TAB_H)
    tabBar.Position         = UDim2.fromOffset(PAD, TOP_H + GAP)
    tabBar.BackgroundColor3 = Color3.fromRGB(16, 16, 16)
    tabBar.BorderSizePixel  = 0
    tabBar.ClipsDescendants = true
    tabBar.ZIndex           = 3
    tabBar.Parent           = panel
    corner(tabBar, 7)
    stroke(tabBar, 1, Color3.fromRGB(36, 36, 36))
    
    local function makeTabBtn(name, xScale)
        local btn = Instance.new("TextButton")
        btn.Size             = UDim2.new(0.5, 0, 1, 0)
        btn.Position         = UDim2.new(xScale, 0, 0, 0)
        btn.BackgroundTransparency = 1
        btn.BorderSizePixel  = 0
        btn.Text             = name
        btn.TextColor3       = Color3.fromRGB(80, 80, 80)
        btn.Font             = Enum.Font.GothamBold
        btn.TextSize         = 12
        btn.ZIndex           = 4
        btn.Parent           = tabBar
        return btn
    end
    
    local btnCreate   = makeTabBtn("Create",   0)
    local btnSchedule = makeTabBtn("Schedule", 0.5)
    
    -- sliding underline indicator
    local indicator = Instance.new("Frame")
    indicator.Size             = UDim2.new(0.5, -16, 0, 2)
    indicator.Position         = UDim2.new(0, 8, 1, -2)
    indicator.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
    indicator.BorderSizePixel  = 0
    indicator.ZIndex           = 5
    indicator.Parent           = tabBar
    corner(indicator, 2)
    
    -- ── Content area ─────────────────────────────────────────────
    local contentArea = Instance.new("Frame")
    contentArea.Size             = UDim2.new(1, -(PAD * 2), 0, CONTENT_H)
    contentArea.Position         = UDim2.fromOffset(PAD, CONTENT_Y)
    contentArea.BackgroundTransparency = 1
    contentArea.ClipsDescendants = true
    contentArea.Parent           = panel
    
    local function makePage()
        local sf = Instance.new("ScrollingFrame")
        sf.Size                  = UDim2.fromScale(1, 1)
        sf.BackgroundTransparency = 1
        sf.BorderSizePixel       = 0
        sf.ScrollBarThickness    = 3
        sf.ScrollBarImageColor3  = Color3.fromRGB(55, 55, 55)
        sf.CanvasSize            = UDim2.fromScale(0, 0)
        sf.AutomaticCanvasSize   = Enum.AutomaticSize.Y
        sf.Visible               = false
        sf.Parent                = contentArea
        
        local layout = Instance.new("UIListLayout")
        layout.SortOrder    = Enum.SortOrder.LayoutOrder
        layout.Padding      = UDim.new(0, 8)
        layout.Parent       = sf
        
        local pad = Instance.new("UIPadding")
        pad.PaddingRight  = UDim.new(0, 4)
        pad.PaddingBottom = UDim.new(0, 8)
        pad.Parent        = sf
        
        return sf
    end
    
    local createPage   = makePage()
    local schedulePage = makePage()
    
    local currentTab = 0
    local function switchTab(idx)
        if currentTab == idx then return end
        currentTab = idx
        createPage.Visible   = (idx == 1)
        schedulePage.Visible = (idx == 2)
        btnCreate.TextColor3   = idx == 1
        and Color3.fromRGB(228, 228, 228) or Color3.fromRGB(80, 80, 80)
        btnSchedule.TextColor3 = idx == 2
        and Color3.fromRGB(228, 228, 228) or Color3.fromRGB(80, 80, 80)
        local targetX = idx == 1 and 8 or (PW - (PAD * 2)) / 2 + 8
        TweenService:Create(indicator, TweenInfo.new(0.18, Enum.EasingStyle.Quint), {
        Position = UDim2.new(0, targetX, 1, -2),
        }):Play()
    end
    
    btnCreate.MouseButton1Click:Connect(function()   switchTab(1) end)
        btnSchedule.MouseButton1Click:Connect(function() switchTab(2) end)
            
            adminRefs.titleLabel = titleLabel
            
            -- ── CREATE PAGE ───────────────────────────────────────────────
            secLabel(createPage, "QUESTION", 0)
            local questionInput = makeInput(createPage, "Poll question...", 1)
            
            secLabel(createPage, "OPTIONS", 2)
            local optRow = Instance.new("Frame")
            optRow.Size             = UDim2.new(1, 0, 0, 34)
            optRow.BackgroundTransparency = 1
            optRow.LayoutOrder      = 3
            optRow.Parent           = createPage
            do
            local leftBg = Instance.new("Frame")
            leftBg.Size             = UDim2.new(0.5, -4, 1, 0)
            leftBg.Position         = UDim2.fromOffset(0, 0)
            leftBg.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
            leftBg.BorderSizePixel  = 0
            leftBg.Parent           = optRow
            corner(leftBg, 6)
            stroke(leftBg, 1, Color3.fromRGB(46, 46, 46))
            local li = Instance.new("TextBox")
            li.Size                  = UDim2.new(1, -16, 1, 0)
            li.Position              = UDim2.fromOffset(8, 0)
            li.BackgroundTransparency = 1
            li.PlaceholderText       = "Left..."
            li.PlaceholderColor3     = Color3.fromRGB(60, 60, 60)
            li.Text                  = ""
            li.TextColor3            = Color3.fromRGB(215, 215, 215)
            li.Font                  = Enum.Font.Gotham
            li.TextSize              = 12
            li.TextXAlignment        = Enum.TextXAlignment.Left
            li.ClearTextOnFocus      = false
            li.Parent                = leftBg
            adminRefs.createLeftInput = li
            
            local rightBg = Instance.new("Frame")
            rightBg.Size             = UDim2.new(0.5, -4, 1, 0)
            rightBg.Position         = UDim2.new(0.5, 4, 0, 0)
            rightBg.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
            rightBg.BorderSizePixel  = 0
            rightBg.Parent           = optRow
            corner(rightBg, 6)
            stroke(rightBg, 1, Color3.fromRGB(46, 46, 46))
            local ri = Instance.new("TextBox")
            ri.Size                  = UDim2.new(1, -16, 1, 0)
            ri.Position              = UDim2.fromOffset(8, 0)
            ri.BackgroundTransparency = 1
            ri.PlaceholderText       = "Right..."
            ri.PlaceholderColor3     = Color3.fromRGB(60, 60, 60)
            ri.Text                  = ""
            ri.TextColor3            = Color3.fromRGB(215, 215, 215)
            ri.Font                  = Enum.Font.Gotham
            ri.TextSize              = 12
            ri.TextXAlignment        = Enum.TextXAlignment.Left
            ri.ClearTextOnFocus      = false
            ri.Parent                = rightBg
            adminRefs.createRightInput = ri
        end
        
        secLabel(createPage, "DURATION (seconds)", 4)
        local durationInput = makeInput(createPage, "e.g. 60", 5)
        
        secLabel(createPage, "SCOPE", 6)
        local getCreateScope = makeScopeRow(createPage, 7)
        
        local publishBtn = makeBtn(createPage, "Publish Poll", Color3.fromRGB(230, 230, 230), Color3.fromRGB(10, 10, 10), 8)
        publishBtn.MouseButton1Click:Connect(function()
            local q   = questionInput.Text
            local ll  = adminRefs.createLeftInput.Text
            local rl  = adminRefs.createRightInput.Text
            local dur = tonumber(durationInput.Text)
            if q == "" or ll == "" or rl == "" or not dur or dur <= 0 then
                titleLabel.Text = "Fill all fields"
                task.delay(2, function() if adminPanelGui then titleLabel.Text = "Poll Manager" end end)
                    return
                end
                PollEvent:FireServer("createPoll", {
                question = q, leftLabel = ll, rightLabel = rl,
                duration = dur, global = getCreateScope(),
                })
                questionInput.Text                = ""
                adminRefs.createLeftInput.Text    = ""
                adminRefs.createRightInput.Text   = ""
                durationInput.Text                = ""
                titleLabel.Text = "Poll Published"
                task.delay(2, function() if adminPanelGui then titleLabel.Text = "Poll Manager" end end)
                end)
                    
                    -- ── SCHEDULE PAGE ─────────────────────────────────────────────
                    secLabel(schedulePage, "QUESTION", 0)
                    local schQInput = makeInput(schedulePage, "Poll question...", 1)
                    
                    secLabel(schedulePage, "OPTIONS", 2)
                    local schOptRow = Instance.new("Frame")
                    schOptRow.Size             = UDim2.new(1, 0, 0, 34)
                    schOptRow.BackgroundTransparency = 1
                    schOptRow.LayoutOrder      = 3
                    schOptRow.Parent           = schedulePage
                    do
                    local leftBg = Instance.new("Frame")
                    leftBg.Size             = UDim2.new(0.5, -4, 1, 0)
                    leftBg.Position         = UDim2.fromOffset(0, 0)
                    leftBg.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
                    leftBg.BorderSizePixel  = 0
                    leftBg.Parent           = schOptRow
                    corner(leftBg, 6)
                    stroke(leftBg, 1, Color3.fromRGB(46, 46, 46))
                    local li = Instance.new("TextBox")
                    li.Size                  = UDim2.new(1, -16, 1, 0)
                    li.Position              = UDim2.fromOffset(8, 0)
                    li.BackgroundTransparency = 1
                    li.PlaceholderText       = "Left..."
                    li.PlaceholderColor3     = Color3.fromRGB(60, 60, 60)
                    li.Text                  = ""
                    li.TextColor3            = Color3.fromRGB(215, 215, 215)
                    li.Font                  = Enum.Font.Gotham
                    li.TextSize              = 12
                    li.TextXAlignment        = Enum.TextXAlignment.Left
                    li.ClearTextOnFocus      = false
                    li.Parent                = leftBg
                    adminRefs.schLeftInput   = li
                    
                    local rightBg = Instance.new("Frame")
                    rightBg.Size             = UDim2.new(0.5, -4, 1, 0)
                    rightBg.Position         = UDim2.new(0.5, 4, 0, 0)
                    rightBg.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
                    rightBg.BorderSizePixel  = 0
                    rightBg.Parent           = schOptRow
                    corner(rightBg, 6)
                    stroke(rightBg, 1, Color3.fromRGB(46, 46, 46))
                    local ri = Instance.new("TextBox")
                    ri.Size                  = UDim2.new(1, -16, 1, 0)
                    ri.Position              = UDim2.fromOffset(8, 0)
                    ri.BackgroundTransparency = 1
                    ri.PlaceholderText       = "Right..."
                    ri.PlaceholderColor3     = Color3.fromRGB(60, 60, 60)
                    ri.Text                  = ""
                    ri.TextColor3            = Color3.fromRGB(215, 215, 215)
                    ri.Font                  = Enum.Font.Gotham
                    ri.TextSize              = 12
                    ri.TextXAlignment        = Enum.TextXAlignment.Left
                    ri.ClearTextOnFocus      = false
                    ri.Parent                = rightBg
                    adminRefs.schRightInput  = ri
                end
                
                secLabel(schedulePage, "DURATION (seconds)", 4)
                local schDurInput = makeInput(schedulePage, "e.g. 60", 5)
                
                secLabel(schedulePage, "DATE  (YYYY-MM-DD)", 6)
                local schDateInput = makeInput(schedulePage, os.date("%Y-%m-%d"), 7)
                schDateInput.Text  = os.date("%Y-%m-%d")
                
                secLabel(schedulePage, "TIME  (HH:MM  24h)", 8)
                local schTimeInput = makeInput(schedulePage, "e.g. 18:30", 9)
                schTimeInput.Text  = os.date("%H:%M")
                
                secLabel(schedulePage, "TIMEZONE", 10)
                
                local tzSelectedOffset = nil
                local tzSelectedLabel  = "Auto (server UTC)"
                
                -- tz display button (part of list flow)
                local tzDisplay = Instance.new("TextButton")
                tzDisplay.Size             = UDim2.new(1, 0, 0, 34)
                tzDisplay.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
                tzDisplay.BorderSizePixel  = 0
                tzDisplay.Text             = "v  " .. tzSelectedLabel
                tzDisplay.TextColor3       = Color3.fromRGB(95, 95, 95)
                tzDisplay.Font             = Enum.Font.Gotham
                tzDisplay.TextSize         = 12
                tzDisplay.TextXAlignment   = Enum.TextXAlignment.Left
                tzDisplay.LayoutOrder      = 11
                tzDisplay.Parent           = schedulePage
                corner(tzDisplay, 6)
                stroke(tzDisplay, 1, Color3.fromRGB(46, 46, 46))
                do
                local p = Instance.new("UIPadding")
                p.PaddingLeft = UDim.new(0, 8)
                p.Parent      = tzDisplay
            end
            
            -- tz dropdown — parented to panel (overlay), not to the scroll list
            local tzDropdown = Instance.new("Frame")
            tzDropdown.Size             = UDim2.new(1, -(PAD * 2), 0, 150)
            tzDropdown.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
            tzDropdown.BorderSizePixel  = 0
            tzDropdown.Visible          = false
            tzDropdown.ZIndex           = 20
            tzDropdown.Parent           = panel
            corner(tzDropdown, 6)
            stroke(tzDropdown, 1, Color3.fromRGB(46, 46, 46))
            
            local tzScroll = Instance.new("ScrollingFrame")
            tzScroll.Size                 = UDim2.fromScale(1, 1)
            tzScroll.BackgroundTransparency = 1
            tzScroll.BorderSizePixel      = 0
            tzScroll.ScrollBarThickness   = 3
            tzScroll.ScrollBarImageColor3 = Color3.fromRGB(55, 55, 55)
            tzScroll.CanvasSize           = UDim2.fromScale(0, 0)
            tzScroll.AutomaticCanvasSize  = Enum.AutomaticSize.Y
            tzScroll.ZIndex               = 20
            tzScroll.Parent               = tzDropdown
            do
            local l = Instance.new("UIListLayout")
            l.SortOrder = Enum.SortOrder.LayoutOrder
            l.Padding   = UDim.new(0, 0)
            l.Parent    = tzScroll
        end
        
        local function addTzOpt(label, offset, lo)
            local opt = Instance.new("TextButton")
            opt.Size             = UDim2.new(1, 0, 0, 26)
            opt.BackgroundTransparency = 1
            opt.BorderSizePixel  = 0
            opt.Text             = label
            opt.TextColor3       = Color3.fromRGB(170, 170, 170)
            opt.Font             = Enum.Font.Gotham
            opt.TextSize         = 11
            opt.TextXAlignment   = Enum.TextXAlignment.Left
            opt.LayoutOrder      = lo
            opt.ZIndex           = 21
            opt.Parent           = tzScroll
            local p = Instance.new("UIPadding")
            p.PaddingLeft = UDim.new(0, 10)
            p.Parent      = opt
            opt.MouseButton1Click:Connect(function()
                tzSelectedOffset     = offset
                tzSelectedLabel      = label
                tzDisplay.Text       = "v  " .. label
                tzDisplay.TextColor3 = Color3.fromRGB(215, 215, 215)
                tzDropdown.Visible   = false
            end)
        end
        
        local autoOpt = Instance.new("TextButton")
        autoOpt.Size             = UDim2.new(1, 0, 0, 26)
        autoOpt.BackgroundTransparency = 1
        autoOpt.BorderSizePixel  = 0
        autoOpt.Text             = "Auto (server UTC)"
        autoOpt.TextColor3       = Color3.fromRGB(170, 170, 170)
        autoOpt.Font             = Enum.Font.Gotham
        autoOpt.TextSize         = 11
        autoOpt.TextXAlignment   = Enum.TextXAlignment.Left
        autoOpt.LayoutOrder      = 0
        autoOpt.ZIndex           = 21
        autoOpt.Parent           = tzScroll
        do
        local p = Instance.new("UIPadding")
        p.PaddingLeft = UDim.new(0, 10)
        p.Parent      = autoOpt
    end
    autoOpt.MouseButton1Click:Connect(function()
        tzSelectedOffset     = nil
        tzSelectedLabel      = "Auto (server UTC)"
        tzDisplay.Text       = "v  Auto (server UTC)"
        tzDisplay.TextColor3 = Color3.fromRGB(95, 95, 95)
        tzDropdown.Visible   = false
    end)
    for i, tz in ipairs(TIMEZONES) do
        addTzOpt(tz.label, tz.offset, i)
    end
    
    -- position dropdown below tzDisplay when opened
    tzDisplay.MouseButton1Click:Connect(function()
        if tzDropdown.Visible then
            tzDropdown.Visible = false
            return
        end
        -- place it just below the tzDisplay button in absolute panel coords
        local absY = tzDisplay.AbsolutePosition.Y - panel.AbsolutePosition.Y
        tzDropdown.Position = UDim2.fromOffset(PAD, absY + 34 + 4)
        tzDropdown.Visible  = true
    end)
    
    secLabel(schedulePage, "SCOPE", 12)
    local getSchScope = makeScopeRow(schedulePage, 13)
    
    local scheduleBtn = makeBtn(schedulePage, "Schedule Poll",
    Color3.fromRGB(230, 230, 230), Color3.fromRGB(10, 10, 10), 14)
    
    scheduleBtn.MouseButton1Click:Connect(function()
        tzDropdown.Visible = false
        local q       = schQInput.Text
        local ll      = adminRefs.schLeftInput.Text
        local rl      = adminRefs.schRightInput.Text
        local dur     = tonumber(schDurInput.Text)
        local dateStr = schDateInput.Text
        local timeStr = schTimeInput.Text
        
        if q == "" or ll == "" or rl == "" or not dur or dur <= 0 then
            titleLabel.Text = "Fill all fields"
            task.delay(2, function() if adminPanelGui then titleLabel.Text = "Poll Manager" end end)
                return
            end
            
            local year, month, day = dateStr:match("^(%d%d%d%d)-(%d%d)-(%d%d)$")
            local hour, min        = timeStr:match("^(%d%d?):(%d%d)$")
            if not year or not hour then
                titleLabel.Text = "Invalid date or time"
                task.delay(2, function() if adminPanelGui then titleLabel.Text = "Poll Manager" end end)
                    return
                end
                
                year, month, day = tonumber(year), tonumber(month), tonumber(day)
                hour, min        = tonumber(hour), tonumber(min)
                
                local targetUTC
                if tzSelectedOffset then
                    targetUTC = os.time({ year=year, month=month, day=day, hour=hour, min=min, sec=0 })
                    - (tzSelectedOffset * 3600)
                else
                    targetUTC = os.time({ year=year, month=month, day=day, hour=hour, min=min, sec=0 })
                end
                
                local delaySeconds = targetUTC - os.time()
                if delaySeconds <= 0 then
                    titleLabel.Text = "Time is in the past"
                    task.delay(2, function() if adminPanelGui then titleLabel.Text = "Poll Manager" end end)
                        return
                    end
                    
                    PollEvent:FireServer("schedulePoll", {
                    question = q, leftLabel = ll, rightLabel = rl,
                    duration = dur, global = getSchScope(),
                    delay = delaySeconds,
                    scheduleLabel = dateStr .. " " .. timeStr .. " "
                    .. (tzSelectedOffset ~= nil and tzSelectedLabel or "UTC"),
                    })
                    
                    schQInput.Text                = ""
                    adminRefs.schLeftInput.Text   = ""
                    adminRefs.schRightInput.Text  = ""
                    schDurInput.Text              = ""
                    schDateInput.Text             = os.date("%Y-%m-%d")
                    schTimeInput.Text             = os.date("%H:%M")
                    tzSelectedOffset              = nil
                    tzSelectedLabel               = "Auto (server UTC)"
                    tzDisplay.Text                = "v  Auto (server UTC)"
                    tzDisplay.TextColor3          = Color3.fromRGB(95, 95, 95)
                    
                    titleLabel.Text = "Poll Scheduled"
                    task.delay(2, function() if adminPanelGui then titleLabel.Text = "Poll Manager" end end)
                    end)
                        
                        switchTab(1)
                    end
                    
                    -- ── CLIENT EVENTS ─────────────────────────────────────────────────────────────
                    PollEvent.OnClientEvent:Connect(function(action, data)
                        if action == "showPoll" then
                            showPollGui(data)
                            
                        elseif action == "updatePoll" then
                            if pollGui and currentPollId == data.id then
                                tweenBar(pollRefs, data.leftVotes or 0, data.rightVotes or 0)
                            end
                            
                        elseif action == "voteChanged" then
                            if pollGui and currentPollId == data.id then
                                playerVote = data.side
                                if pollRefs.applyHighlight then pollRefs.applyHighlight(data.side) end
                                tweenBar(pollRefs, data.leftVotes or 0, data.rightVotes or 0)
                            end
                            
                        elseif action == "endPoll" then
                            destroyPollGui(true)
                            
                        elseif action == "openAdminPanel" then
                            if not adminPanelOpen then
                                buildAdminPanel()
                            end
                        end
                    end)
                    
                    player.Chatted:Connect(function(message)
                        if message:lower() == "/pollmenu" then
                            local ok = PollFunction:InvokeServer("checkAdmin", {})
                            if not ok then return end
                            buildAdminPanel()
                        end
                    end)
                    
                    local result = PollFunction:InvokeServer("requestActivePoll", {})
                    if result and result.poll then
                        showPollGui(result.poll)
                        if result.previousVote and pollRefs.applyHighlight then
                            playerVote = result.previousVote
                            pollRefs.applyHighlight(result.previousVote)
                        end
                    end
