local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "LoadingUI"
screenGui.IgnoreGuiInset = true
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

local blackFrame = Instance.new("Frame")
blackFrame.BackgroundColor3 = Color3.new(0, 0, 0)
blackFrame.Size = UDim2.new(1, 0, 1, 0)
blackFrame.Position = UDim2.new(0, 0, 0, 0)
blackFrame.Parent = screenGui

local titleText = Instance.new("TextLabel")
titleText.Text = ""
titleText.TextColor3 = Color3.new(1, 1, 1)
titleText.Font = Enum.Font.GothamBlack
titleText.TextSize = 30
titleText.Size = UDim2.new(0.6, 0, 0.15, 0)
titleText.Position = UDim2.new(0.2, 0, 0.42, 0)
titleText.BackgroundTransparency = 1
titleText.TextTransparency = 1
titleText.Parent = screenGui

task.wait(0.3)
TweenService:Create(titleText, TweenInfo.new(1), {TextTransparency = 0}):Play()
task.wait(1)

local typingSound = Instance.new("Sound")
typingSound.SoundId = "rbxassetid://9120299506"
typingSound.Volume = 1
typingSound.Parent = screenGui

local fullText = "Leaf Games"
for i = 1, #fullText do
    titleText.Text = fullText:sub(1, i) .. "_"
    typingSound:Play()
    task.wait(0.11)
end
titleText.Text = fullText

local progressBarBg = Instance.new("Frame")
progressBarBg.Size = UDim2.new(0.4, 0, 0.025, 0)
progressBarBg.Position = UDim2.new(0.3, 0, 0.6, 0)
progressBarBg.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
progressBarBg.BackgroundTransparency = 1
progressBarBg.Parent = screenGui

local bgCorner = Instance.new("UICorner")
bgCorner.CornerRadius = UDim.new(0.5, 0)
bgCorner.Parent = progressBarBg

local progressBarFill = Instance.new("Frame")
progressBarFill.Size = UDim2.new(0, 0, 1, 0)
progressBarFill.BackgroundColor3 = Color3.fromRGB(0, 183, 235)
progressBarFill.BorderSizePixel = 0
progressBarFill.BackgroundTransparency = 0
progressBarFill.Parent = progressBarBg

local fillCorner = Instance.new("UICorner")
fillCorner.CornerRadius = UDim.new(0.5, 0)
fillCorner.Parent = progressBarFill

local counterLabel = Instance.new("TextLabel")
counterLabel.Size = UDim2.new(0, 120, 0, 20)
counterLabel.Position = UDim2.new(0.5, -60, 0.63, 0)
counterLabel.BackgroundTransparency = 1
counterLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
counterLabel.Font = Enum.Font.GothamSemibold
counterLabel.TextSize = 15
counterLabel.Text = ""
counterLabel.TextTransparency = 1
counterLabel.Parent = screenGui

TweenService:Create(progressBarBg, TweenInfo.new(1), {BackgroundTransparency = 0}):Play()
TweenService:Create(counterLabel, TweenInfo.new(1), {TextTransparency = 0}):Play()
task.wait(1.5)

local skipButtonCreated = false
local loadingSkipped = false

local skipButton = Instance.new("TextButton")
skipButton.Text = "Skip"
skipButton.Size = UDim2.new(0, 60, 0, 22)
skipButton.Position = UDim2.new(0.5, -30, 0.68, 0)
skipButton.BackgroundColor3 = Color3.fromRGB(245, 245, 245)
skipButton.TextColor3 = Color3.fromRGB(20, 20, 20)
skipButton.Font = Enum.Font.GothamBold
skipButton.TextSize = 14
skipButton.BackgroundTransparency = 1
skipButton.TextTransparency = 1
skipButton.Visible = false
skipButton.Parent = screenGui

local skipCorner = Instance.new("UICorner")
skipCorner.CornerRadius = UDim.new(0.25, 0)
skipCorner.Parent = skipButton

skipButton.MouseButton1Click:Connect(function()
    if loadingSkipped then return end
    loadingSkipped = true
end)

local allObjects = {}
for _, service in ipairs({workspace, game:GetService("ReplicatedStorage"), game:GetService("Lighting")}) do
    for _, obj in ipairs(service:GetDescendants()) do
        table.insert(allObjects, obj)
    end
end

local total = #allObjects
local processed = 0

for i, _ in ipairs(allObjects) do
    if loadingSkipped then 
        progressBarFill.Size = UDim2.new(1, 0, 1, 0)
        counterLabel.Text = string.format("(%d/%d)", total, total)
        break 
    end
    
    processed += 1
    local progress = processed / total
    
    progressBarFill.Size = UDim2.new(progress, 0, 1, 0)
    counterLabel.Text = string.format("(%d/%d)", processed, total)

    if not skipButtonCreated and processed >= 100 then
        skipButtonCreated = true
        skipButton.Visible = true
        TweenService:Create(skipButton, TweenInfo.new(1), {
            BackgroundTransparency = 0,
            TextTransparency = 0
        }):Play()
    end

    if i % 25 == 0 then
        RunService.RenderStepped:Wait()
    end
end

if not loadingSkipped then task.wait(1) end

local fadeOutTime = 1.5
TweenService:Create(progressBarBg, TweenInfo.new(fadeOutTime), {BackgroundTransparency = 1}):Play()
TweenService:Create(progressBarFill, TweenInfo.new(fadeOutTime), {BackgroundTransparency = 1}):Play()
TweenService:Create(titleText, TweenInfo.new(fadeOutTime), {TextTransparency = 1}):Play()
TweenService:Create(counterLabel, TweenInfo.new(fadeOutTime), {TextTransparency = 1}):Play()
TweenService:Create(skipButton, TweenInfo.new(fadeOutTime), {
    BackgroundTransparency = 1,
    TextTransparency = 1
}):Play()

task.wait(fadeOutTime)

TweenService:Create(blackFrame, TweenInfo.new(1.5), {BackgroundTransparency = 1}):Play()
task.wait(1.5)
screenGui:Destroy()