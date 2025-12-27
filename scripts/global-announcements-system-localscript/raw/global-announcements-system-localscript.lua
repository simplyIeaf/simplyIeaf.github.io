-- made by @simplyIeaf1 on youtube

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local remote = ReplicatedStorage:WaitForChild("MessageEvent")

remote.OnClientEvent:Connect(function(message)
    local gui = Instance.new("ScreenGui")
    gui.Name = "Message"
    gui.IgnoreGuiInset = true
    gui.ResetOnSpawn = false
    gui.Parent = player:WaitForChild("PlayerGui")
    
    local frame = Instance.new("Frame")
    frame.AnchorPoint = Vector2.new(0.5, 0)
    frame.Position = UDim2.new(0.5, 0, 0.05, 0)
    frame.BackgroundColor3 = Color3.new(0, 0, 0)
    frame.BackgroundTransparency = 1
    frame.BorderSizePixel = 0
    frame.AutomaticSize = Enum.AutomaticSize.XY
    frame.Size = UDim2.new(0, 0, 0, 0)
    frame.Parent = gui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0.1, 0)
    corner.Parent = frame
    
    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, 10)
    padding.PaddingBottom = UDim.new(0, 10)
    padding.PaddingLeft = UDim.new(0, 20)
    padding.PaddingRight = UDim.new(0, 20)
    padding.Parent = frame
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 0)
    label.AutomaticSize = Enum.AutomaticSize.Y
    label.BackgroundTransparency = 1
    label.Text = message
    label.TextWrapped = true
    label.TextSize = 16
    label.Font = Enum.Font.GothamBold
    label.TextColor3 = Color3.new(1, 1, 1)
    label.TextXAlignment = Enum.TextXAlignment.Center
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.TextTransparency = 1
    label.Parent = frame
    
    local fadeIn = TweenService:Create(frame, TweenInfo.new(0.5), {BackgroundTransparency = 0.2})
    local textFadeIn = TweenService:Create(label, TweenInfo.new(0.5), {TextTransparency = 0})
    
    fadeIn:Play()
    textFadeIn:Play()
    
    task.wait(2)
    
    local fadeOut = TweenService:Create(frame, TweenInfo.new(0.5), {BackgroundTransparency = 1})
    local textFadeOut = TweenService:Create(label, TweenInfo.new(0.5), {TextTransparency = 1})
    
    fadeOut:Play()
    textFadeOut:Play()
    
    fadeOut.Completed:Wait()
    gui:Destroy()
end)