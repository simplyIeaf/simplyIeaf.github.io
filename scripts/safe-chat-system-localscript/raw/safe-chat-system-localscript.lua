local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")

local player = Players.LocalPlayer
local chatRemote = ReplicatedStorage:WaitForChild("SafeChatEvent")
local getMessagesFunc = ReplicatedStorage:WaitForChild("GetMessages")

local messages = getMessagesFunc:InvokeServer()
local uiOpen = false

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SafeChatGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

local blur = Instance.new("BlurEffect")
blur.Size = 0
blur.Parent = Lighting

local button = Instance.new("ImageButton")
button.Parent = screenGui
button.BackgroundColor3 = Color3.fromRGB(0,0,0)
button.BorderSizePixel = 0
button.AnchorPoint = Vector2.new(1, 0.5)
button.Position = UDim2.new(1, -20, 0.45, 0)
button.Size = UDim2.new(0.08, 0, 0.08, 0)

local aspect = Instance.new("UIAspectRatioConstraint")
aspect.AspectRatio = 1
aspect.Parent = button

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(1, 0)
corner.Parent = button

local icon = Instance.new("ImageLabel")
icon.Parent = button
icon.BackgroundTransparency = 1
icon.AnchorPoint = Vector2.new(0.5, 0.5)
icon.Position = UDim2.new(0.5, 0, 0.5, 0)
icon.Size = UDim2.new(0.6, 0, 0.6, 0)
icon.Image = "rbxthumb://type=Asset&id=104639538354109&w=420&h=420"

local mainFrame = Instance.new("Frame")
mainFrame.Parent = screenGui
mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
mainFrame.Size = UDim2.new(0.3, 0, 0.4, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
mainFrame.Visible = false
mainFrame.Active = true
mainFrame.Draggable = true

local frameCorner = Instance.new("UICorner")
frameCorner.CornerRadius = UDim.new(0, 12)
frameCorner.Parent = mainFrame

local title = Instance.new("TextLabel")
title.Parent = mainFrame
title.BackgroundTransparency = 1
title.Size = UDim2.new(1, 0, 0, 40)
title.Text = "Select Message"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 18

local closeButton = Instance.new("TextButton")
closeButton.Parent = mainFrame
closeButton.Size = UDim2.new(0, 30, 0, 30)
closeButton.Position = UDim2.new(1, -35, 0, 5)
closeButton.Text = "X"
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.BackgroundTransparency = 1

local scrolling = Instance.new("ScrollingFrame")
scrolling.Parent = mainFrame
scrolling.Position = UDim2.new(0, 10, 0, 45)
scrolling.Size = UDim2.new(1, -20, 1, -55)
scrolling.BackgroundTransparency = 1
scrolling.CanvasSize = UDim2.new(0, 0, 0, 0)
scrolling.AutomaticCanvasSize = Enum.AutomaticSize.Y
scrolling.ScrollBarThickness = 2

local layout = Instance.new("UIListLayout")
layout.Parent = scrolling
layout.Padding = UDim.new(0, 5)

local function toggleUI()
	uiOpen = not uiOpen
	mainFrame.Visible = uiOpen
	TweenService:Create(blur, TweenInfo.new(0.2), {Size = uiOpen and 15 or 0}):Play()
end

for _, message in ipairs(messages) do
	local msgButton = Instance.new("TextButton")
	msgButton.Parent = scrolling
	msgButton.Size = UDim2.new(1, 0, 0, 35)
	msgButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	msgButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	msgButton.Text = message
	msgButton.Font = Enum.Font.Gotham
	msgButton.TextSize = 14
	local bCorner = Instance.new("UICorner")
	bCorner.CornerRadius = UDim.new(0, 6)
	bCorner.Parent = msgButton
	msgButton.MouseButton1Click:Connect(function()
		chatRemote:FireServer(message)
		toggleUI()
	end)
end

button.MouseButton1Click:Connect(toggleUI)
closeButton.MouseButton1Click:Connect(toggleUI)

chatRemote.OnClientEvent:Connect(function(sender, messageText)
	if sender and sender.Character then
		TextChatService:DisplayBubble(sender.Character, messageText)
	end
end)