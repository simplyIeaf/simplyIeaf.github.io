local players = game:GetService("Players")
local tweenService = game:GetService("TweenService")
local contentProvider = game:GetService("ContentProvider")
local starterGui = game:GetService("StarterGui")
local runService = game:GetService("RunService")
 
local accentColors = {
green  = ColorSequence.new(Color3.fromRGB(60, 220, 60), Color3.fromRGB(20, 120, 20)),
blue   = ColorSequence.new(Color3.fromRGB(60, 160, 255), Color3.fromRGB(20, 80, 200)),
red    = ColorSequence.new(Color3.fromRGB(255, 60, 60), Color3.fromRGB(180, 20, 20)),
purple = ColorSequence.new(Color3.fromRGB(180, 60, 255), Color3.fromRGB(100, 20, 200)),
orange = ColorSequence.new(Color3.fromRGB(255, 150, 30), Color3.fromRGB(200, 90, 10)),
white  = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(180, 180, 180)),
}
 
local accent = accentColors.green
 
local player = players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local camera = workspace.CurrentCamera
 
local decals = {
{id = "958660553", text = "This is Denis"},
{id = "12654811722", text = "This is KreekCraft"}
}
 
local studTexture = "rbxthumb://type=Asset&id=14905298664&w=150&h=150"
 
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "LoadingScreen"
screenGui.IgnoreGuiInset = true
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui
 
local uiScale = Instance.new("UIScale")
uiScale.Parent = screenGui
 
local safeFrame = Instance.new("Frame")
safeFrame.Name = "SafeFrame"
safeFrame.AnchorPoint = Vector2.new(0.5, 0.5)
safeFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
safeFrame.BackgroundTransparency = 1
safeFrame.Parent = screenGui
 
local function UpdateScale()
    local vp = camera.ViewportSize
    if vp.X <= 0 or vp.Y <= 0 then
        return
    end
    local scale = math.min(vp.X / 1920, vp.Y / 1080)
    uiScale.Scale = scale
    safeFrame.Size = UDim2.new(0, vp.X / scale, 0, vp.Y / scale)
end
 
camera:GetPropertyChangedSignal("ViewportSize"):Connect(UpdateScale)
runService.RenderStepped:Wait()
UpdateScale()
 
local background = Instance.new("Frame", safeFrame)
background.Size = UDim2.new(1, 400, 1, 400)
background.Position = UDim2.new(0, -200, 0, -200)
background.BackgroundColor3 = Color3.new(0, 0, 0)
background.BorderSizePixel = 0
background.ZIndex = 1
 
local pattern = Instance.new("ImageLabel", background)
pattern.Size = UDim2.new(1, 0, 1, 0)
pattern.BackgroundTransparency = 1
pattern.Image = studTexture
pattern.ScaleType = Enum.ScaleType.Tile
pattern.TileSize = UDim2.new(0, 150, 0, 150)
pattern.ImageTransparency = 0.85
pattern.ZIndex = 2
 
local previewImage = Instance.new("ImageLabel", background)
previewImage.Size = UDim2.new(0, 400, 0, 400)
previewImage.AnchorPoint = Vector2.new(0.5, 0.5)
previewImage.Position = UDim2.new(0.5, 0, 0.5, 0)
previewImage.BackgroundTransparency = 1
previewImage.ImageTransparency = 1
previewImage.ZIndex = 3
 
local altText = Instance.new("TextLabel", previewImage)
altText.Size = UDim2.new(1, 0, 0, 30)
altText.Position = UDim2.new(0, 0, 1, 15)
altText.BackgroundTransparency = 1
altText.TextTransparency = 1
altText.Text = ""
altText.TextColor3 = Color3.fromRGB(160, 160, 160)
altText.TextSize = 14
altText.Font = Enum.Font.Gotham
altText.ZIndex = 3
 
local bottomLeftFrame = Instance.new("Frame", background)
bottomLeftFrame.Size = UDim2.new(0, 350, 0, 60)
bottomLeftFrame.AnchorPoint = Vector2.new(0, 1)
bottomLeftFrame.Position = UDim2.new(0, 250, 1, 350)
bottomLeftFrame.BackgroundTransparency = 1
bottomLeftFrame.ZIndex = 4
 
local percentText = Instance.new("TextLabel", bottomLeftFrame)
percentText.Size = UDim2.new(1, 0, 0, 40)
percentText.BackgroundTransparency = 1
percentText.Text = "0%"
percentText.TextColor3 = Color3.new(1, 1, 1)
percentText.TextSize = 45
percentText.Font = Enum.Font.GothamBold
percentText.TextXAlignment = Enum.TextXAlignment.Left
 
local barBg = Instance.new("Frame", bottomLeftFrame)
barBg.Size = UDim2.new(1, 0, 0, 8)
barBg.Position = UDim2.new(0, 0, 1, -8)
barBg.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
barBg.BorderSizePixel = 0
 
local barBgCorner = Instance.new("UICorner", barBg)
barBgCorner.CornerRadius = UDim.new(1, 0)
 
local barFill = Instance.new("Frame", barBg)
barFill.Size = UDim2.new(0, 0, 1, 0)
barFill.BackgroundColor3 = Color3.new(1, 1, 1)
barFill.BorderSizePixel = 0
 
local barFillCorner = Instance.new("UICorner", barFill)
barFillCorner.CornerRadius = UDim.new(1, 0)
 
local barGradient = Instance.new("UIGradient", barFill)
barGradient.Color = accent
 
local skipBtn = Instance.new("TextButton", background)
skipBtn.Size = UDim2.new(0, 140, 0, 45)
skipBtn.AnchorPoint = Vector2.new(1, 1)
skipBtn.Position = UDim2.new(1, -250, 1, 350)
skipBtn.Text = "Skip"
skipBtn.TextColor3 = Color3.new(1, 1, 1)
skipBtn.TextSize = 22
skipBtn.Font = Enum.Font.GothamBold
skipBtn.BackgroundColor3 = Color3.new(1, 1, 1)
skipBtn.ZIndex = 4
 
local skipCorner = Instance.new("UICorner", skipBtn)
skipCorner.CornerRadius = UDim.new(0, 6)
 
local btnBorder = Instance.new("UIStroke", skipBtn)
btnBorder.Thickness = 3
btnBorder.Color = Color3.new(0, 0, 0)
btnBorder.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
 
local btnTextStroke = Instance.new("UIStroke")
btnTextStroke.Thickness = 1.7
btnTextStroke.Color = Color3.new(0, 0, 0)
btnTextStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
btnTextStroke.Parent = skipBtn
 
starterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)
 
local touchGui = playerGui:FindFirstChild("TouchGui")
if touchGui then
    touchGui.Enabled = false
end
 
tweenService:Create(bottomLeftFrame, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = UDim2.new(0, 250, 1, -250)}):Play()
 
local isDone = false
local skipVisible = false
 
local function CleanUp()
    if isDone then
        return
    end
    isDone = true
 
    local char = player.Character
    local humanoid = char and char:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.PlatformStand = true
    end
 
    tweenService:Create(bottomLeftFrame, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Position = UDim2.new(-0.5, 0, 1, -250)}):Play()
 
    if skipVisible then
        tweenService:Create(skipBtn, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Position = UDim2.new(1.5, 0, 1, -250)}):Play()
    end
 
    task.wait(0.4)
 
    local fade = tweenService:Create(background, TweenInfo.new(0.3), {BackgroundTransparency = 1})
    tweenService:Create(pattern, TweenInfo.new(0.3), {ImageTransparency = 1}):Play()
    tweenService:Create(previewImage, TweenInfo.new(0.3), {ImageTransparency = 1}):Play()
    tweenService:Create(altText, TweenInfo.new(0.3), {TextTransparency = 1}):Play()
    fade:Play()
    fade.Completed:Wait()
 
    if humanoid then
        humanoid.PlatformStand = false
    end
 
    starterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, true)
 
    if touchGui then
        touchGui.Enabled = true
    end
 
    screenGui:Destroy()
end
 
skipBtn.MouseButton1Click:Connect(CleanUp)
 
task.spawn(function()
    local index = 1
    while not isDone do
        local current = decals[index]
        previewImage.Image = "rbxthumb://type=Asset&id=" .. current.id .. "&w=420&h=420"
        altText.Text = current.text
 
        tweenService:Create(previewImage, TweenInfo.new(0.3), {ImageTransparency = 0}):Play()
        tweenService:Create(altText, TweenInfo.new(0.3), {TextTransparency = 0}):Play()
 
        local t = 0
        while t < 5 and not isDone do
            task.wait(0.1)
            t += 0.1
        end
 
        if not isDone then
            local hide = tweenService:Create(previewImage, TweenInfo.new(0.3), {ImageTransparency = 1})
            tweenService:Create(altText, TweenInfo.new(0.3), {TextTransparency = 1}):Play()
            hide:Play()
            hide.Completed:Wait()
        end
 
        index = index % #decals + 1
    end
end)
 
task.spawn(function()
    local assets = {}
    local seen = {}
 
    local function Gather(root)
        local ok, list = pcall(function()
            return root:GetDescendants()
        end)
        if not ok then
            return
        end
        for _, obj in ipairs(list) do
            if not seen[obj] then
                seen[obj] = true
                table.insert(assets, obj)
            end
        end
    end
 
    for _, service in ipairs(game:GetChildren()) do
        Gather(service)
    end
 
    local char = player.Character or player.CharacterAdded:Wait()
    Gather(char)
    Gather(playerGui)
 
    local total = #assets
 
    if total == 0 then
        for i = 1, 100 do
            if isDone then
                break
            end
            local p = i / 100
            percentText.Text = math.floor(p * 100) .. "%"
            tweenService:Create(barFill, TweenInfo.new(0.1), {Size = UDim2.new(p, 0, 1, 0)}):Play()
            if p >= 0.2 and not skipVisible then
                skipVisible = true
                tweenService:Create(skipBtn, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = UDim2.new(1, -250, 1, -250)}):Play()
            end
            task.wait(0.05)
        end
    else
        for i, obj in ipairs(assets) do
            if isDone then
                break
            end
            pcall(function()
                contentProvider:PreloadAsync({obj})
            end)
            local p = i / total
            percentText.Text = math.floor(p * 100) .. "%"
            tweenService:Create(barFill, TweenInfo.new(0.1), {Size = UDim2.new(p, 0, 1, 0)}):Play()
            if p >= 0.2 and not skipVisible then
                skipVisible = true
                tweenService:Create(skipBtn, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = UDim2.new(1, -250, 1, -250)}):Play()
            end
        end
    end
 
    if not isDone then
        CleanUp()
    end
end)