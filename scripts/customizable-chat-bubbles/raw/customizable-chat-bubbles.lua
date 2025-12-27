-- made by @simplyIeaf1 on youtube

local TextChatService = game:GetService("TextChatService")
 
local bubbleConfig = TextChatService:FindFirstChildOfClass("BubbleChatConfiguration")
 
bubbleConfig.BackgroundColor3 = Color3.fromRGB(250, 250, 250)
bubbleConfig.BackgroundTransparency = 0.1
bubbleConfig.BubbleDuration = 15
bubbleConfig.BubblesSpacing = 6
bubbleConfig.Enabled = true
bubbleConfig.LocalPlayerStudsOffset = Vector3.new(0, 0, 0)
bubbleConfig.MaxBubbles = 3
bubbleConfig.MaxDistance = 100
bubbleConfig.MinimizeDistance = 40
bubbleConfig.TailVisible = true
bubbleConfig.TextColor3 = Color3.fromRGB(57, 59, 61)
bubbleConfig.TextSize = 16
bubbleConfig.VerticalStudsOffset = 0