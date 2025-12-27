local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local workspace = game:GetService("Workspace")

local rf = ReplicatedStorage:WaitForChild("FeedbackRF", 10)

if not rf then
    warn("FeedbackRF not found in ReplicatedStorage")
    return
end

local MAX_REVIEWS_PER_PAGE = 5
local allFeedbackData = {}
local totalPages = 1
local currentPage = 1

local canSubmit = false
local isAdmin = false
local selectedRating = nil

task.spawn(function()
    local success, result = pcall(function()
        return rf:InvokeServer("IsAdmin")
    end)
    if success then
        isAdmin = result
    end
end)

task.spawn(function()
    local success, result = pcall(function()
        return rf:InvokeServer("CanSubmit")
    end)
    if success then
        canSubmit = result
    end
end)

local gui = Instance.new("ScreenGui")
gui.Name = "FeedbackSystem"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

local main = Instance.new("Frame")
main.Name = "FeedbackFrame"
main.Size = UDim2.fromScale(0.28, 0.45) -- Changed
main.Position = UDim2.fromScale(0.5, 0.5)
main.AnchorPoint = Vector2.new(0.5, 0.5)
main.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
main.BorderSizePixel = 0
main.Visible = false
main.Parent = gui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 20)
mainCorner.Parent = main

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = Color3.fromRGB(40, 40, 40)
mainStroke.Thickness = 1.5
mainStroke.Parent = main

local mainAspect = Instance.new("UIAspectRatioConstraint")
mainAspect.AspectRatio = 460 / 440
mainAspect.Parent = main

local mainSize = Instance.new("UISizeConstraint")
mainSize.MinSize = Vector2.new(350, 334) -- Changed
mainSize.MaxSize = Vector2.new(700, 669) -- Changed
mainSize.Parent = main

local topBar = Instance.new("Frame")
topBar.Name = "TopBar"
topBar.Size = UDim2.new(1, 0, 0, 70)
topBar.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
topBar.BorderSizePixel = 0
topBar.Parent = main

local topBarCorner = Instance.new("UICorner")
topBarCorner.CornerRadius = UDim.new(0, 20)
topBarCorner.Parent = topBar

local topBarFix = Instance.new("Frame")
topBarFix.Size = UDim2.new(1, 0, 0, 20)
topBarFix.Position = UDim2.fromOffset(0, 50)
topBarFix.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
topBarFix.BorderSizePixel = 0
topBarFix.Parent = topBar

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -80, 1, 0)
title.Position = UDim2.fromOffset(24, 0)
title.BackgroundTransparency = 1
title.Text = "Submit Feedback"
title.TextColor3 = Color3.fromRGB(240, 240, 240)
title.TextSize = 22
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left
title.TextScaled = true
title.Parent = topBar

local titleConstraint = Instance.new("UITextSizeConstraint")
titleConstraint.MinTextSize = 14
titleConstraint.MaxTextSize = 22
titleConstraint.Parent = title

local closeMain = Instance.new("TextButton")
closeMain.Name = "CloseBtn"
closeMain.Size = UDim2.fromOffset(40, 40)
closeMain.Position = UDim2.new(1, -55, 0.5, -20)
closeMain.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
closeMain.Text = ""
closeMain.AutoButtonColor = false
closeMain.Parent = topBar

local closeBtnCorner = Instance.new("UICorner")
closeBtnCorner.CornerRadius = UDim.new(0, 10)
closeBtnCorner.Parent = closeMain

local closeIcon = Instance.new("ImageLabel")
closeIcon.Size = UDim2.fromOffset(18, 18)
closeIcon.Position = UDim2.fromScale(0.5, 0.5)
closeIcon.AnchorPoint = Vector2.new(0.5, 0.5)
closeIcon.BackgroundTransparency = 1
closeIcon.Image = "rbxassetid://7072725342"
closeIcon.ImageColor3 = Color3.fromRGB(200, 200, 200)
closeIcon.Parent = closeMain

local contentFrame = Instance.new("Frame")
contentFrame.Size = UDim2.new(1, 0, 0, 310)
contentFrame.Position = UDim2.fromOffset(0, 70)
contentFrame.BackgroundTransparency = 1
contentFrame.Parent = main

local contentPadding = Instance.new("UIPadding")
contentPadding.PaddingLeft = UDim.new(0, 24)
contentPadding.PaddingRight = UDim.new(0, 24)
contentPadding.PaddingTop = UDim.new(0, 16)
contentPadding.PaddingBottom = UDim.new(0, 16)
contentPadding.Parent = contentFrame

local feedBox = Instance.new("TextBox")
feedBox.Name = "Feedback"
feedBox.Size = UDim2.new(1, 0, 0, 200)
feedBox.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
feedBox.Text = ""
feedBox.PlaceholderText = "Share your thoughts with us..."
feedBox.PlaceholderColor3 = Color3.fromRGB(100, 100, 100)
feedBox.TextColor3 = Color3.fromRGB(220, 220, 220)
feedBox.TextSize = 15
feedBox.Font = Enum.Font.Gotham
feedBox.TextXAlignment = Enum.TextXAlignment.Left
feedBox.TextYAlignment = Enum.TextYAlignment.Top
feedBox.MultiLine = true
feedBox.TextWrapped = true
feedBox.ClearTextOnFocus = false
feedBox.BorderSizePixel = 0
feedBox.TextScaled = true
feedBox.Parent = contentFrame

local feedPadding = Instance.new("UIPadding")
feedPadding.PaddingTop = UDim.new(0, 12)
feedPadding.PaddingLeft = UDim.new(0, 12)
feedPadding.PaddingRight = UDim.new(0, 12)
feedPadding.PaddingBottom = UDim.new(0, 12)
feedPadding.Parent = feedBox

local feedCorner = Instance.new("UICorner")
feedCorner.CornerRadius = UDim.new(0, 14)
feedCorner.Parent = feedBox

local feedTextConstraint = Instance.new("UITextSizeConstraint")
feedTextConstraint.MinTextSize = 10
feedTextConstraint.MaxTextSize = 15
feedTextConstraint.Parent = feedBox

local feedStroke = Instance.new("UIStroke")
feedStroke.Color = Color3.fromRGB(35, 35, 35)
feedStroke.Thickness = 1
feedStroke.Parent = feedBox

local ratingFrame = Instance.new("Frame")
ratingFrame.Size = UDim2.fromOffset(116, 40)
ratingFrame.Position = UDim2.fromOffset(0, 220)
ratingFrame.BackgroundTransparency = 1
ratingFrame.Parent = contentFrame

local thumbsUpBtn = Instance.new("ImageButton")
thumbsUpBtn.Name = "ThumbsUp"
thumbsUpBtn.Size = UDim2.fromOffset(40, 40)
thumbsUpBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
thumbsUpBtn.BackgroundTransparency = 0.4
thumbsUpBtn.Image = "rbxthumb://type=Asset&id=6376283963&w=150&h=150"
thumbsUpBtn.ImageColor3 = Color3.fromRGB(150, 150, 150)
thumbsUpBtn.AutoButtonColor = false
thumbsUpBtn.BorderSizePixel = 0
thumbsUpBtn.Parent = ratingFrame

local thumbsUpCorner = Instance.new("UICorner")
thumbsUpCorner.CornerRadius = UDim.new(0, 10)
thumbsUpCorner.Parent = thumbsUpBtn

local thumbsDownBtn = Instance.new("ImageButton")
thumbsDownBtn.Name = "ThumbsDown"
thumbsDownBtn.Size = UDim2.fromOffset(40, 40)
thumbsDownBtn.Position = UDim2.fromOffset(60, 0)
thumbsDownBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
thumbsDownBtn.BackgroundTransparency = 0.4
thumbsDownBtn.Image = "rbxthumb://type=Asset&id=6376285529&w=150&h=150"
thumbsDownBtn.ImageColor3 = Color3.fromRGB(150, 150, 150)
thumbsDownBtn.AutoButtonColor = false
thumbsDownBtn.BorderSizePixel = 0
thumbsDownBtn.Parent = ratingFrame

local thumbsDownCorner = Instance.new("UICorner")
thumbsDownCorner.CornerRadius = UDim.new(0, 10)
thumbsDownCorner.Parent = thumbsDownBtn

local charCount = Instance.new("TextLabel")
charCount.Size = UDim2.fromOffset(80, 20)
charCount.Position = UDim2.new(1, -80, 0, 220)
charCount.BackgroundTransparency = 1
charCount.Text = "0/500"
charCount.TextColor3 = Color3.fromRGB(120, 120, 120)
charCount.TextSize = 14
charCount.Font = Enum.Font.Gotham
charCount.TextXAlignment = Enum.TextXAlignment.Right
charCount.TextScaled = true
charCount.Parent = contentFrame

local charCountConstraint = Instance.new("UITextSizeConstraint")
charCountConstraint.MinTextSize = 9
charCountConstraint.MaxTextSize = 14
charCountConstraint.Parent = charCount

local submitBtn = Instance.new("TextButton")
submitBtn.Name = "SubmitBtn"
submitBtn.Size = UDim2.new(1, -48, 0, 50)
submitBtn.Position = UDim2.new(0, 24, 1, -26)
submitBtn.AnchorPoint = Vector2.new(0, 1)
submitBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
submitBtn.Text = "Submit"
submitBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
submitBtn.TextSize = 18
submitBtn.Font = Enum.Font.GothamBold
submitBtn.AutoButtonColor = false
submitBtn.BorderSizePixel = 0
submitBtn.TextScaled = true
submitBtn.Parent = main

local submitCorner = Instance.new("UICorner")
submitCorner.CornerRadius = UDim.new(0, 14)
submitCorner.Parent = submitBtn

local submitTextConstraint = Instance.new("UITextSizeConstraint")
submitTextConstraint.MinTextSize = 12
submitTextConstraint.MaxTextSize = 18
submitTextConstraint.Parent = submitBtn

local viewer = Instance.new("Frame")
viewer.Name = "ViewerFrame"
viewer.Size = UDim2.fromScale(0.33, 0.63) -- Changed
viewer.Position = UDim2.fromScale(0.5, 0.5)
viewer.AnchorPoint = Vector2.new(0.5, 0.5)
viewer.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
viewer.BorderSizePixel = 0
viewer.Visible = false
viewer.Parent = gui

local viewerCorner = Instance.new("UICorner")
viewerCorner.CornerRadius = UDim.new(0, 20)
viewerCorner.Parent = viewer

local viewerStroke = Instance.new("UIStroke")
viewerStroke.Color = Color3.fromRGB(40, 40, 40)
viewerStroke.Thickness = 1.5
viewerStroke.Parent = viewer

local viewerAspect = Instance.new("UIAspectRatioConstraint")
viewerAspect.AspectRatio = 560 / 640
viewerAspect.Parent = viewer

local viewerSize = Instance.new("UISizeConstraint")
viewerSize.MinSize = Vector2.new(400, 457) -- Changed
viewerSize.MaxSize = Vector2.new(900, 1028) -- Changed
viewerSize.Parent = viewer

local viewerTopBar = Instance.new("Frame")
viewerTopBar.Name = "TopBar"
viewerTopBar.Size = UDim2.new(1, 0, 0, 70)
viewerTopBar.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
viewerTopBar.BorderSizePixel = 0
viewerTopBar.Parent = viewer

local viewerTopCorner = Instance.new("UICorner")
viewerTopCorner.CornerRadius = UDim.new(0, 20)
viewerTopCorner.Parent = viewerTopBar

local viewerTopFix = Instance.new("Frame")
viewerTopFix.Size = UDim2.new(1, 0, 0, 20)
viewerTopFix.Position = UDim2.fromOffset(0, 50)
viewerTopFix.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
viewerTopFix.BorderSizePixel = 0
viewerTopFix.Parent = viewerTopBar

local viewerTitle = Instance.new("TextLabel")
viewerTitle.Size = UDim2.new(1, -80, 1, 0)
viewerTitle.Position = UDim2.fromOffset(24, 0)
viewerTitle.BackgroundTransparency = 1
viewerTitle.Text = "Feedback"
viewerTitle.TextColor3 = Color3.fromRGB(240, 240, 240)
viewerTitle.TextSize = 22
viewerTitle.Font = Enum.Font.GothamBold
viewerTitle.TextXAlignment = Enum.TextXAlignment.Left
viewerTitle.TextScaled = true
viewerTitle.Parent = viewerTopBar

local viewerTitleConstraint = Instance.new("UITextSizeConstraint")
viewerTitleConstraint.MinTextSize = 14
viewerTitleConstraint.MaxTextSize = 22
viewerTitleConstraint.Parent = viewerTitle

local closeViewer = Instance.new("TextButton")
closeViewer.Name = "CloseViewerBtn"
closeViewer.Size = UDim2.fromOffset(40, 40)
closeViewer.Position = UDim2.new(1, -50, 0.5, -20)
closeViewer.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
closeViewer.Text = ""
closeViewer.AutoButtonColor = false
closeViewer.Parent = viewerTopBar

local closeViewerCorner = Instance.new("UICorner")
closeViewerCorner.CornerRadius = UDim.new(0, 10)
closeViewerCorner.Parent = closeViewer

local closeViewerIcon = Instance.new("ImageLabel")
closeViewerIcon.Size = UDim2.fromOffset(18, 18)
closeViewerIcon.Position = UDim2.fromScale(0.5, 0.5)
closeViewerIcon.AnchorPoint = Vector2.new(0.5, 0.5)
closeViewerIcon.BackgroundTransparency = 1
closeViewerIcon.Image = "rbxassetid://7072725342"
closeViewerIcon.ImageColor3 = Color3.fromRGB(200, 200, 200)
closeViewerIcon.Parent = closeViewer

local refreshBtn = Instance.new("ImageButton")
refreshBtn.Name = "RefreshButton"
refreshBtn.Size = UDim2.fromOffset(36, 36)
refreshBtn.Position = UDim2.new(1, -90, 0.5, -18)
refreshBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
refreshBtn.Image = "rbxthumb://type=Asset&id=12662723759&w=150&h=150"
refreshBtn.ImageColor3 = Color3.fromRGB(200, 200, 200)
refreshBtn.AutoButtonColor = false
refreshBtn.BorderSizePixel = 0
refreshBtn.Parent = viewerTopBar

local refreshCorner = Instance.new("UICorner")
refreshCorner.CornerRadius = UDim.new(0, 8)
refreshCorner.Parent = refreshBtn

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -48, 1, -140)
scroll.Position = UDim2.fromOffset(24, 86)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 4
scroll.ScrollBarImageColor3 = Color3.fromRGB(60, 60, 60)
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.Parent = viewer

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 10)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = scroll

local controlsFrame = Instance.new("Frame")
controlsFrame.Name = "PageControls"
controlsFrame.Size = UDim2.new(1, -48, 0, 50)
controlsFrame.Position = UDim2.new(0.5, 0, 1, -36)
controlsFrame.AnchorPoint = Vector2.new(0.5, 1)
controlsFrame.BackgroundTransparency = 1
controlsFrame.Parent = viewer

local pageControls = Instance.new("Frame")
pageControls.Name = "PageSwitch"
pageControls.Size = UDim2.fromOffset(160, 40)
pageControls.Position = UDim2.fromScale(0.5, 0.5)
pageControls.AnchorPoint = Vector2.new(0.5, 0.5)
pageControls.BackgroundTransparency = 1
pageControls.Parent = controlsFrame

local prevBtn = Instance.new("TextButton")
prevBtn.Name = "PrevButton"
prevBtn.Size = UDim2.fromOffset(40, 40)
prevBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
prevBtn.Text = "<"
prevBtn.TextColor3 = Color3.fromRGB(240, 240, 240)
prevBtn.TextSize = 20
prevBtn.Font = Enum.Font.GothamBold
prevBtn.AutoButtonColor = false
prevBtn.BorderSizePixel = 0
prevBtn.Parent = pageControls

local prevCorner = Instance.new("UICorner")
prevCorner.CornerRadius = UDim.new(0, 10)
prevCorner.Parent = prevBtn

local pageBox = Instance.new("TextBox")
pageBox.Name = "PageInput"
pageBox.Size = UDim2.fromOffset(70, 40)
pageBox.Position = UDim2.fromOffset(45, 0)
pageBox.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
pageBox.Text = "1/1"
pageBox.TextColor3 = Color3.fromRGB(240, 240, 240)
pageBox.TextSize = 16
pageBox.Font = Enum.Font.GothamBold
pageBox.TextXAlignment = Enum.TextXAlignment.Center
pageBox.ClearTextOnFocus = false
pageBox.BorderSizePixel = 0
pageBox.TextScaled = true
pageBox.Parent = pageControls

local pageCorner = Instance.new("UICorner")
pageCorner.CornerRadius = UDim.new(0, 10)
pageCorner.Parent = pageBox

local pageTextConstraint = Instance.new("UITextSizeConstraint")
pageTextConstraint.MinTextSize = 12
pageTextConstraint.MaxTextSize = 16
pageTextConstraint.Parent = pageBox

local nextBtn = Instance.new("TextButton")
nextBtn.Name = "NextButton"
nextBtn.Size = UDim2.fromOffset(40, 40)
nextBtn.Position = UDim2.fromOffset(120, 0)
nextBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
nextBtn.Text = ">"
nextBtn.TextColor3 = Color3.fromRGB(240, 240, 240)
nextBtn.TextSize = 20
nextBtn.Font = Enum.Font.GothamBold
nextBtn.AutoButtonColor = false
nextBtn.BorderSizePixel = 0
nextBtn.Parent = pageControls

local nextCorner = Instance.new("UICorner")
nextCorner.CornerRadius = UDim.new(0, 10)
nextCorner.Parent = nextBtn

local openBtn = Instance.new("TextButton")
openBtn.Name = "OpenButton"
openBtn.Size = UDim2.fromOffset(56, 56)
openBtn.Position = UDim2.new(0, 24, 1, -80)
openBtn.AnchorPoint = Vector2.new(0, 0)
openBtn.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
openBtn.Text = ""
openBtn.AutoButtonColor = false
openBtn.BorderSizePixel = 0
openBtn.Parent = gui

local openCorner = Instance.new("UICorner")
openCorner.CornerRadius = UDim.new(0, 16)
openCorner.Parent = openBtn

local openIcon = Instance.new("ImageLabel")
openIcon.Size = UDim2.fromOffset(28, 28)
openIcon.Position = UDim2.fromScale(0.5, 0.5)
openIcon.AnchorPoint = Vector2.new(0.5, 0.5)
openIcon.BackgroundTransparency = 1
openIcon.Image = "rbxassetid://7733964719"
openIcon.ImageColor3 = Color3.fromRGB(255, 255, 255)
openIcon.Parent = openBtn

local function updateSubmitButtonState()
    local textPresent = #feedBox.Text:gsub("^%s+", ""):gsub("%s+$", "") > 0
    local ratingSelected = selectedRating ~= nil
    local isActive = textPresent and ratingSelected
    
    if isActive then
        submitBtn.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
        submitBtn.TextColor3 = Color3.fromRGB(240, 240, 240)
    else
        submitBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
        submitBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
    end
end

local function tweenIn(frame)
    frame.Visible = true
    frame.AnchorPoint = Vector2.new(0.5, 0.5)
    
    local originalSize
    if frame.Name == "FeedbackFrame" then
        originalSize = UDim2.fromScale(0.28, 0.45) -- Changed
    elseif frame.Name == "ViewerFrame" then
        originalSize = UDim2.fromScale(0.33, 0.63) -- Changed
    else
        originalSize = UDim2.fromScale(0.25, 0.4) 
    end
    
    frame.Size = UDim2.fromScale(0, 0)
    frame.Position = UDim2.fromScale(0.5, 0.5)
    
    local tween = TweenService:Create(frame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
    Size = originalSize
    })
    tween:Play()
end

local function tweenOut(frame)
    local tween = TweenService:Create(frame, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
    Size = UDim2.fromScale(0, 0)
    })
    tween:Play()
    tween.Completed:Connect(function()
        frame.Visible = false
    end)
end

local function clearScroll()
    for _, child in ipairs(scroll:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
end

local function addReview(entry, index)
    if not entry or not entry.msg then return end
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 90)
    frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    frame.BorderSizePixel = 0
    frame.Parent = scroll
    
    local fCorner = Instance.new("UICorner")
    fCorner.CornerRadius = UDim.new(0, 14)
    fCorner.Parent = frame
    
    local fStroke = Instance.new("UIStroke")
    fStroke.Color = Color3.fromRGB(35, 35, 35)
    fStroke.Thickness = 1
    fStroke.Parent = frame
    
    local head = Instance.new("ImageLabel")
    head.Size = UDim2.fromOffset(54, 54)
    head.Position = UDim2.fromOffset(16, 18)
    head.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    head.BorderSizePixel = 0
    head.Parent = frame
    
    if entry.userId then
        task.spawn(function()
            local success, thumbnail = pcall(function()
                return Players:GetUserThumbnailAsync(entry.userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
            end)
            
            if success and thumbnail then
                head.Image = thumbnail
            end
        end)
    end
    
    local headCorner = Instance.new("UICorner")
    headCorner.CornerRadius = UDim.new(1, 0)
    headCorner.Parent = head
    
    local username = Instance.new("TextLabel")
    username.Size = UDim2.new(1, -140, 0, 20)
    username.Position = UDim2.fromOffset(82, 16)
    username.BackgroundTransparency = 1
    username.Text = entry.username or "User"
    username.TextColor3 = Color3.fromRGB(180, 180, 180)
    username.TextSize = 14
    username.Font = Enum.Font.GothamBold
    username.TextXAlignment = Enum.TextXAlignment.Left
    username.Parent = frame
    
    if entry.rating then
        local ratingIcon = Instance.new("ImageLabel")
        ratingIcon.Size = UDim2.fromOffset(28, 28)
        ratingIcon.Position = UDim2.new(1, -40, 0, 14)
        ratingIcon.BackgroundTransparency = 1
        ratingIcon.Image = entry.rating == "up" and "rbxthumb://type=Asset&id=6376283963&w=150&h=150" or "rbxthumb://type=Asset&id=6376285529&w=150&h=150"
        ratingIcon.ImageColor3 = entry.rating == "up" and Color3.fromRGB(87, 242, 135) or Color3.fromRGB(242, 87, 87)
        ratingIcon.Parent = frame
    end
    
    local textScroll = Instance.new("ScrollingFrame")
    textScroll.Size = UDim2.new(1, -90, 0, 50)
    textScroll.Position = UDim2.fromOffset(82, 36)
    textScroll.BackgroundTransparency = 1
    textScroll.BorderSizePixel = 0
    textScroll.ScrollBarThickness = 3
    textScroll.ScrollBarImageColor3 = Color3.fromRGB(60, 60, 60)
    textScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    textScroll.ClipsDescendants = true
    textScroll.Parent = frame
    
    local text = Instance.new("TextLabel")
    text.Size = UDim2.new(1, -6, 1, 0)
    text.BackgroundTransparency = 1
    text.Text = entry.msg
    text.TextColor3 = Color3.fromRGB(200, 200, 200)
    text.TextSize = 14
    text.Font = Enum.Font.Gotham
    text.TextXAlignment = Enum.TextXAlignment.Left
    text.TextYAlignment = Enum.TextYAlignment.Top
    text.TextWrapped = true
    text.Parent = textScroll
    
    task.wait()
    if text.TextBounds and text.TextBounds.Y > 0 then
        text.Size = UDim2.new(1, -6, 0, text.TextBounds.Y)
        textScroll.CanvasSize = UDim2.new(0, 0, 0, text.TextBounds.Y)
    end
    
    if isAdmin and index then
        local removeBtn = Instance.new("ImageButton")
        removeBtn.Name = "RemoveButton"
        removeBtn.Size = UDim2.fromOffset(28, 28)
        removeBtn.Position = UDim2.new(1, -78, 0, 14)
        removeBtn.BackgroundColor3 = Color3.new(0, 0, 0)
        removeBtn.BackgroundTransparency = 1
        removeBtn.Image = "rbxthumb://type=Asset&id=17307685534&w=150&h=150"
        removeBtn.ImageColor3 = Color3.fromRGB(200, 50, 50)
        removeBtn.AutoButtonColor = false
        removeBtn.BorderSizePixel = 0
        removeBtn.Parent = frame
        
        removeBtn.MouseEnter:Connect(function() TweenService:Create(removeBtn, TweenInfo.new(0.1), { ImageColor3 = Color3.fromRGB(255, 70, 70) }):Play() end)
            removeBtn.MouseLeave:Connect(function() TweenService:Create(removeBtn, TweenInfo.new(0.1), { ImageColor3 = Color3.fromRGB(200, 50, 50) }):Play() end)
                
                removeBtn.MouseButton1Click:Connect(function()
                    local indexInList = index
                    local currentPageOnRemove = currentPage
                    
                    local success, result = pcall(function()
                        return rf:InvokeServer("RemoveFeedback", indexInList)
                    end)
                    
                    if success and result then
                        warn("Admin removed feedback at index", indexInList)
                        refreshFeedback(currentPageOnRemove) 
                    else
                        warn("Failed to remove feedback at index", indexInList)
                    end
                end)
            end
            
            scroll.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 10)
        end
        
        local function calculatePages()
            local totalReviews = #allFeedbackData
            totalPages = math.max(1, math.ceil(totalReviews / MAX_REVIEWS_PER_PAGE))
            currentPage = math.max(1, math.min(currentPage, totalPages))
            pageBox.Text = currentPage .. "/" .. totalPages
        end
        
        local function loadPage(page)
            page = math.max(1, math.min(page, totalPages))
            currentPage = page
            pageBox.Text = currentPage .. "/" .. totalPages
            
            clearScroll()
            
            local startIndex = (page - 1) * MAX_REVIEWS_PER_PAGE + 1
            local endIndex = math.min(startIndex + MAX_REVIEWS_PER_PAGE - 1, #allFeedbackData)
            
            for i = startIndex, endIndex do
                addReview(allFeedbackData[i], i)
            end
            
            scroll.CanvasPosition = Vector2.new(0, 0)
        end
        
        local function refreshFeedback(pageToStayOn)
            local originalPage = pageToStayOn or currentPage
            
            refreshBtn.ImageColor3 = Color3.fromRGB(100, 100, 100)
            
            local success, list = pcall(function()
                return rf:InvokeServer("GetFeedback")
            end)
            
            if success and list and type(list) == "table" then
                allFeedbackData = list
                currentPage = originalPage
                calculatePages()
                loadPage(currentPage)
            else
                warn("Failed to get feedback list")
                allFeedbackData = {}
                currentPage = 1
                calculatePages()
                loadPage(currentPage)
            end
            
            refreshBtn.ImageColor3 = Color3.fromRGB(200, 200, 200)
        end
        
        feedBox:GetPropertyChangedSignal("Text"):Connect(function()
            local len = #feedBox.Text
            if len > 500 then
                feedBox.Text = feedBox.Text:sub(1, 500)
                len = 500
            end
            charCount.Text = len .. "/500"
            updateSubmitButtonState()
        end)
        
        thumbsUpBtn.MouseButton1Click:Connect(function()
            if selectedRating == "up" then
                selectedRating = nil
                TweenService:Create(thumbsUpBtn, TweenInfo.new(0.2), {
                ImageColor3 = Color3.fromRGB(150, 150, 150),
                BackgroundTransparency = 0.4
                }):Play()
            else
                selectedRating = "up"
                TweenService:Create(thumbsUpBtn, TweenInfo.new(0.2), {
                ImageColor3 = Color3.fromRGB(87, 242, 135),
                BackgroundTransparency = 0.2
                }):Play()
                TweenService:Create(thumbsDownBtn, TweenInfo.new(0.2), {
                ImageColor3 = Color3.fromRGB(150, 150, 150),
                BackgroundTransparency = 0.4
                }):Play()
            end
            updateSubmitButtonState()
        end)
        
        thumbsDownBtn.MouseButton1Click:Connect(function()
            if selectedRating == "down" then
                selectedRating = nil
                TweenService:Create(thumbsDownBtn, TweenInfo.new(0.2), {
                ImageColor3 = Color3.fromRGB(150, 150, 150),
                BackgroundTransparency = 0.4
                }):Play()
            else
                selectedRating = "down"
                TweenService:Create(thumbsDownBtn, TweenInfo.new(0.2), {
                ImageColor3 = Color3.fromRGB(242, 87, 87),
                BackgroundTransparency = 0.2
                }):Play()
                TweenService:Create(thumbsUpBtn, TweenInfo.new(0.2), {
                ImageColor3 = Color3.fromRGB(150, 150, 150),
                BackgroundTransparency = 0.4
                }):Play()
            end
            updateSubmitButtonState()
        end)
        
        thumbsUpBtn.MouseEnter:Connect(function()
            if selectedRating ~= "up" then
                TweenService:Create(thumbsUpBtn, TweenInfo.new(0.2), {
                ImageColor3 = Color3.fromRGB(87, 242, 135)
                }):Play()
            end
        end)
        
        thumbsUpBtn.MouseLeave:Connect(function()
            if selectedRating ~= "up" then
                TweenService:Create(thumbsUpBtn, TweenInfo.new(0.2), {
                ImageColor3 = Color3.fromRGB(150, 150, 150)
                }):Play()
            end
        end)
        
        thumbsDownBtn.MouseEnter:Connect(function()
            if selectedRating ~= "down" then
                TweenService:Create(thumbsDownBtn, TweenInfo.new(0.2), {
                ImageColor3 = Color3.fromRGB(242, 87, 87)
                }):Play()
            end
        end)
        
        thumbsDownBtn.MouseLeave:Connect(function()
            if selectedRating ~= "down" then
                TweenService:Create(thumbsDownBtn, TweenInfo.new(0.2), {
                ImageColor3 = Color3.fromRGB(150, 150, 150)
                }):Play()
            end
        end)
        
        prevBtn.MouseButton1Click:Connect(function()
            if currentPage > 1 then
                loadPage(currentPage - 1)
            end
        end)
        
        nextBtn.MouseButton1Click:Connect(function()
            if currentPage < totalPages then
                loadPage(currentPage + 1)
            end
        end)
        
        pageBox.FocusLost:Connect(function(enterPressed)
            if enterPressed then
                local newPage = tonumber(pageBox.Text:match("(%d+)"))
                if newPage and newPage >= 1 and newPage <= totalPages then
                    loadPage(newPage)
                else
                    pageBox.Text = currentPage .. "/" .. totalPages
                end
            end
        end)
        
        refreshBtn.MouseButton1Click:Connect(refreshFeedback)
        refreshBtn.MouseEnter:Connect(function() TweenService:Create(refreshBtn, TweenInfo.new(0.1), { BackgroundColor3 = Color3.fromRGB(40, 40, 40) }):Play() end)
            refreshBtn.MouseLeave:Connect(function() TweenService:Create(refreshBtn, TweenInfo.new(0.1), { BackgroundColor3 = Color3.fromRGB(25, 25, 25) }):Play() end)
                
                openBtn.MouseButton1Click:Connect(function()
                    if main.Visible or viewer.Visible then return end
                    
                    local hoverTween = TweenService:Create(openBtn, TweenInfo.new(0.1), { Size = UDim2.fromOffset(52, 52) })
                    hoverTween:Play()
                    hoverTween.Completed:Connect(function()
                        TweenService:Create(openBtn, TweenInfo.new(0.1), { Size = UDim2.fromOffset(56, 56) }):Play()
                    end)
                    
                    local success, adminStatus = pcall(function()
                        return rf:InvokeServer("IsAdmin")
                    end)
                    
                    if success and adminStatus then
                        tweenIn(viewer)
                        refreshFeedback()
                    else
                        local success3, canSubmitNow = pcall(function()
                            return rf:InvokeServer("CanSubmit")
                        end)
                        
                        if success3 and canSubmitNow then
                            tweenIn(main)
                            updateSubmitButtonState()
                        end
                    end
                end)
                
                closeMain.MouseButton1Click:Connect(function()
                    tweenOut(main)
                end)
                
                closeMain.MouseEnter:Connect(function()
                    TweenService:Create(closeMain, TweenInfo.new(0.2), {
                    BackgroundColor3 = Color3.fromRGB(242, 87, 87)
                    }):Play()
                end)
                
                closeMain.MouseLeave:Connect(function()
                    TweenService:Create(closeMain, TweenInfo.new(0.2), {
                    BackgroundColor3 = Color3.fromRGB(25, 25, 25)
                    }):Play()
                end)
                
                closeViewer.MouseButton1Click:Connect(function()
                    tweenOut(viewer)
                end)
                
                closeViewer.MouseEnter:Connect(function()
                    TweenService:Create(closeViewer, TweenInfo.new(0.2), {
                    BackgroundColor3 = Color3.fromRGB(242, 87, 87)
                    }):Play()
                end)
                
                closeViewer.MouseLeave:Connect(function()
                    TweenService:Create(closeViewer, TweenInfo.new(0.2), {
                    BackgroundColor3 = Color3.fromRGB(25, 25, 25)
                    }):Play()
                end)
                
                submitBtn.MouseButton1Click:Connect(function()
                    local txt = feedBox.Text:gsub("^%s+", ""):gsub("%s+$", "")
                    local isReady = #txt > 0 and selectedRating ~= nil
                    
                    if not isReady then return end
                    
                    submitBtn.Text = "Submitting..."
                    submitBtn.BackgroundColor3 = Color3.fromRGB(60, 70, 180)
                    
                    local success, result = pcall(function()
                        return rf:InvokeServer("Submit", txt, selectedRating)
                    end)
                    
                    if success and result then
                        canSubmit = false
                        tweenOut(main)
                        feedBox.Text = ""
                        selectedRating = nil
                        TweenService:Create(thumbsUpBtn, TweenInfo.new(0.2), {
                        ImageColor3 = Color3.fromRGB(150, 150, 150),
                        BackgroundTransparency = 0.4
                        }):Play()
                        TweenService:Create(thumbsDownBtn, TweenInfo.new(0.2), {
                        ImageColor3 = Color3.fromRGB(150, 150, 150),
                        BackgroundTransparency = 0.4
                        }):Play()
                        updateSubmitButtonState() 
                    else
                        submitBtn.Text = "Submit"
                        updateSubmitButtonState()
                    end
                end)
