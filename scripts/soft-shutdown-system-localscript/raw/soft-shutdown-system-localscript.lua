-- StarterPlayerScripts script for soft shutdown system
-- made by @simplyIeaf1 on YouTube

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
 
local function showShutdownUI()
    if player.PlayerGui:FindFirstChild("ShutdownScreenGui") then return end
    
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "ShutdownScreenGui"
    screenGui.IgnoreGuiInset = true
    screenGui.ResetOnSpawn = false
    screenGui.DisplayOrder = 1000
    screenGui.Parent = player:WaitForChild("PlayerGui")
    
    local blackFrame = Instance.new("Frame")
    blackFrame.BackgroundColor3 = Color3.new(0, 0, 0)
    blackFrame.BackgroundTransparency = 1
    blackFrame.Size = UDim2.new(1, 0, 1, 0)
    blackFrame.Position = UDim2.new(0, 0, 0, 0)
    blackFrame.Parent = screenGui
    
    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, 0, 0.2, 0)
    textLabel.Position = UDim2.new(0, 0, 0.4, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = "Restarting servers..."
    textLabel.TextColor3 = Color3.new(1, 1, 1)
    textLabel.TextSize = 28
    textLabel.Font = Enum.Font.SourceSansBold
    textLabel.RichText = true
    textLabel.TextTransparency = 1
    textLabel.Parent = blackFrame
    
    local fadeIn = TweenService:Create(blackFrame, TweenInfo.new(0.5), {
    BackgroundTransparency = 0
    })
    fadeIn:Play()
    fadeIn.Completed:Wait()
    
    local textFadeIn = TweenService:Create(textLabel, TweenInfo.new(0.6), {
    TextTransparency = 0
    })
    textFadeIn:Play()
end

if game.PrivateServerId ~= "" and game.PrivateServerOwnerId == 0 then
    showShutdownUI()
end

local shutdownEvent = ReplicatedStorage:WaitForChild("SofShudowEvent")
shutdownEvent.OnClientEvent:Connect(function()
    showShutdownUI()
end)
