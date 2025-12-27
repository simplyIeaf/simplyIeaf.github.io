-- made by @simplyIeaf1 on YouTube
-- press a player to open their profile

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")
local StarterGui = game:GetService("StarterGui")

-- Disable default inspect menu
GuiService:SetInspectMenuEnabled(false)

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Function to get current camera
local function getCurrentCamera()
    return workspace.CurrentCamera
end

-- Create ScreenGui
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "PlayerProfileGui"
ScreenGui.Parent = PlayerGui

-- Main Profile Frame
local Frame = Instance.new("Frame")
Frame.Name = "ProfileFrame"
Frame.Size = UDim2.new(0, 520, 0, 280)
Frame.Position = UDim2.new(0.5, 0, 0.5, 0)
Frame.AnchorPoint = Vector2.new(0.5, 0.5)
Frame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
Frame.BorderSizePixel = 0
Frame.Visible = false
Frame.Parent = ScreenGui

-- UIScale for dynamic resolution scaling
local UIScale = Instance.new("UIScale")
UIScale.Parent = Frame

local function updateScale()
    local camera = workspace.CurrentCamera
    if not camera then return end
    local screenSize = camera.ViewportSize
    
    local baseWidth, baseHeight = 1920, 1080
    local scaleX = screenSize.X / baseWidth
    local scaleY = screenSize.Y / baseHeight
    local scale = math.min(scaleX, scaleY)
    
    scale = math.clamp(scale, 0.6, 1)
    UIScale.Scale = scale
    
    -- Keep frame centered
    Frame.Position = UDim2.new(0.5, 0, 0.5, 0)
end

updateScale()
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale)

local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0, 12)
Corner.Parent = Frame

-- Header Frame
local HeaderFrame = Instance.new("Frame")
HeaderFrame.Size = UDim2.new(1, 0, 0, 50)
HeaderFrame.Position = UDim2.new(0, 0, 0, 0)
HeaderFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
HeaderFrame.BorderSizePixel = 0
HeaderFrame.Parent = Frame

local HeaderCorner = Instance.new("UICorner")
HeaderCorner.CornerRadius = UDim.new(0, 12)
HeaderCorner.Parent = HeaderFrame

local HeaderBottomCover = Instance.new("Frame")
HeaderBottomCover.Size = UDim2.new(1, 0, 0, 12)
HeaderBottomCover.Position = UDim2.new(0, 0, 1, -12)
HeaderBottomCover.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
HeaderBottomCover.BorderSizePixel = 0
HeaderBottomCover.Parent = HeaderFrame

-- Profile Title
local ProfileTitle = Instance.new("TextLabel")
ProfileTitle.Size = UDim2.new(0, 200, 1, 0)
ProfileTitle.Position = UDim2.new(0, 15, 0, 0)
ProfileTitle.BackgroundTransparency = 1
ProfileTitle.Text = "Player's Profile"
ProfileTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
ProfileTitle.TextSize = 18
ProfileTitle.TextXAlignment = Enum.TextXAlignment.Left
ProfileTitle.Font = Enum.Font.GothamBold
ProfileTitle.Parent = HeaderFrame

-- Close Button
local CloseButton = Instance.new("TextButton")
CloseButton.Size = UDim2.new(0, 30, 0, 30)
CloseButton.Position = UDim2.new(1, -40, 0, 10)
CloseButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
CloseButton.BorderSizePixel = 0
CloseButton.Text = "×"
CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseButton.TextSize = 20
CloseButton.Font = Enum.Font.GothamBold
CloseButton.Parent = HeaderFrame

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 15)
CloseCorner.Parent = CloseButton

-- Avatar Frame
local AvatarFrame = Instance.new("Frame")
AvatarFrame.Size = UDim2.new(0, 100, 0, 100)
AvatarFrame.Position = UDim2.new(0, 25, 0, 70)
AvatarFrame.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
AvatarFrame.BorderSizePixel = 0
AvatarFrame.Parent = Frame

local AvatarCorner = Instance.new("UICorner")
AvatarCorner.CornerRadius = UDim.new(0, 50)
AvatarCorner.Parent = AvatarFrame

local AvatarImage = Instance.new("ImageLabel")
AvatarImage.Size = UDim2.new(1, -6, 1, -6)
AvatarImage.Position = UDim2.new(0, 3, 0, 3)
AvatarImage.BackgroundTransparency = 1
AvatarImage.Image = ""
AvatarImage.Parent = AvatarFrame

local AvatarImageCorner = Instance.new("UICorner")
AvatarImageCorner.CornerRadius = UDim.new(0, 47)
AvatarImageCorner.Parent = AvatarImage

-- User Info Labels
local UserIDLabel = Instance.new("TextLabel")
UserIDLabel.Size = UDim2.new(0, 200, 0, 20)
UserIDLabel.Position = UDim2.new(0, 145, 0, 70)
UserIDLabel.BackgroundTransparency = 1
UserIDLabel.Text = "User ID: ---"
UserIDLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
UserIDLabel.TextSize = 14
UserIDLabel.TextXAlignment = Enum.TextXAlignment.Left
UserIDLabel.Font = Enum.Font.Gotham
UserIDLabel.Parent = Frame

local JoinDateLabel = Instance.new("TextLabel")
JoinDateLabel.Size = UDim2.new(0, 200, 0, 20)
JoinDateLabel.Position = UDim2.new(0, 145, 0, 95)
JoinDateLabel.BackgroundTransparency = 1
JoinDateLabel.Text = "Join Date: ---"
JoinDateLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
JoinDateLabel.TextSize = 14
JoinDateLabel.TextXAlignment = Enum.TextXAlignment.Left
JoinDateLabel.Font = Enum.Font.Gotham
JoinDateLabel.Parent = Frame

local AgeLabel = Instance.new("TextLabel")
AgeLabel.Size = UDim2.new(0, 200, 0, 20)
AgeLabel.Position = UDim2.new(0, 145, 0, 120)
AgeLabel.BackgroundTransparency = 1
AgeLabel.Text = "Age: ---"
AgeLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
AgeLabel.TextSize = 14
AgeLabel.TextXAlignment = Enum.TextXAlignment.Left
AgeLabel.Font = Enum.Font.Gotham
AgeLabel.Parent = Frame

-- Buttons Frame
local ButtonsFrame = Instance.new("Frame")
ButtonsFrame.Size = UDim2.new(0, 35, 0, 77)
ButtonsFrame.Position = UDim2.new(1, -50, 0, 70)
ButtonsFrame.BackgroundTransparency = 1
ButtonsFrame.Parent = Frame

-- Friend Button
local FriendButton = Instance.new("TextButton")
FriendButton.Size = UDim2.new(0, 35, 0, 35)
FriendButton.Position = UDim2.new(0, 0, 0, 0)
FriendButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
FriendButton.BorderSizePixel = 0
FriendButton.Text = "+"
FriendButton.TextColor3 = Color3.fromRGB(255, 255, 255)
FriendButton.TextSize = 20
FriendButton.Font = Enum.Font.GothamBold
FriendButton.Parent = ButtonsFrame

local FriendCorner = Instance.new("UICorner")
FriendCorner.CornerRadius = UDim.new(0, 17)
FriendCorner.Parent = FriendButton

-- Inspect Button
local InspectButton = Instance.new("TextButton")
InspectButton.Size = UDim2.new(0, 35, 0, 35)
InspectButton.Position = UDim2.new(0, 0, 0, 42)
InspectButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
InspectButton.BorderSizePixel = 0
InspectButton.Text = "👁"
InspectButton.TextColor3 = Color3.fromRGB(255, 255, 255)
InspectButton.TextSize = 16
InspectButton.Font = Enum.Font.GothamBold
InspectButton.Parent = ButtonsFrame

local InspectCorner = Instance.new("UICorner")
InspectCorner.CornerRadius = UDim.new(0, 17)
InspectCorner.Parent = InspectButton

-- Current player tracking
local currentPlayer = nil
local lastProfileOpen = 0
local PROFILE_COOLDOWN = 1
local currentFriendStatus = "Unknown"

-- Check friendship status
local function checkFriendshipStatus(player)
    if not player or player == LocalPlayer then return "Self" end
    local success, result = pcall(function() return LocalPlayer:IsFriendsWith(player.UserId) end)
        if success then return result and "Friends" or "NotFriends" else return "Unknown" end
    end
    
    -- Update friend button
    local function updateFriendButton(status)
        if status == "Friends" then
            FriendButton.Text = "+"
            FriendButton.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
        elseif status == "NotFriends" then
            FriendButton.Text = "+"
            FriendButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        elseif status == "Self" then
            FriendButton.Text = "+"
            FriendButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
        else
            FriendButton.Text = "+"
            FriendButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        end
    end
    
    -- Show profile
    function showProfile(player)
        local currentTime = tick()
        if currentTime - lastProfileOpen < PROFILE_COOLDOWN then return end
        lastProfileOpen = currentTime
        currentPlayer = player
        
        ProfileTitle.Text = player.Name.."'s Profile"
        UserIDLabel.Text = "User ID: "..player.UserId
        
        local success, result = pcall(function()
            return Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.AvatarBust, Enum.ThumbnailSize.Size100x100)
        end)
        AvatarImage.Image = success and result or "rbxasset://textures/ui/GuiImagePlaceholder.png"
        
        local joinDate = "Unknown"
        if player.AccountAge and player.AccountAge > 0 then
            joinDate = os.date("%B %Y", os.time() - player.AccountAge * 24 * 60 * 60)
        end
        JoinDateLabel.Text = "Join Date: "..joinDate
        AgeLabel.Text = "Age: "..player.AccountAge.." days"
        
        currentFriendStatus = checkFriendshipStatus(player)
        updateFriendButton(currentFriendStatus)
        
        Frame.Visible = true
        Frame.Size = UDim2.new(0,0,0,0)
        
        TweenService:Create(Frame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0,520,0,280)
        }):Play()
    end
    
    -- Close profile
    local function closeProfile()
        local tween = TweenService:Create(Frame, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
        Size = UDim2.new(0,0,0,0)
        })
        tween:Play()
        tween.Completed:Wait()
        Frame.Visible = false
        currentPlayer = nil
    end
    
    CloseButton.MouseButton1Click:Connect(closeProfile)
    
    -- Friend button
    FriendButton.MouseButton1Click:Connect(function()
        if not currentPlayer or currentPlayer == LocalPlayer then return end
        if currentFriendStatus == "Friends" then return end
        pcall(function() StarterGui:SetCore("PromptSendFriendRequest", currentPlayer) end)
        end)
            
            -- Inspect button
            InspectButton.MouseButton1Click:Connect(function()
                if not currentPlayer or currentPlayer == LocalPlayer then
                    local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildWhichIsA("Humanoid")
                    if humanoid then
                        pcall(function()
                            local humanoidDescription = humanoid:GetAppliedDescription()
                            GuiService:InspectPlayerFromHumanoidDescription(humanoidDescription, LocalPlayer.Name)
                        end)
                    end
                    return
                end
                local humanoid = currentPlayer.Character and currentPlayer.Character:FindFirstChildWhichIsA("Humanoid")
                if humanoid then
                    pcall(function()
                        local humanoidDescription = humanoid:GetAppliedDescription()
                        GuiService:InspectPlayerFromHumanoidDescription(humanoidDescription, currentPlayer.Name)
                    end)
                end
            end)
            
            -- Click detection (disabled auto-close)
            local clickConnection
            local touchConnection
            
            local function processClick(pos)
                local camera = getCurrentCamera()
                if not camera then return end
                local ray = camera:ViewportPointToRay(pos.X, pos.Y)
                local res = workspace:Raycast(ray.Origin, ray.Direction * 1000)
                if res and res.Instance then
                    local char = res.Instance:FindFirstAncestorOfClass("Model")
                    if char and char:FindFirstChild("Humanoid") then
                        local plr = Players:GetPlayerFromCharacter(char)
                        if plr then showProfile(plr) return true end
                    end
                end
                return false
            end
            
            local function setupClickDetection()
                if clickConnection then clickConnection:Disconnect() end
                if touchConnection then touchConnection:Disconnect() end
                
                clickConnection = UserInputService.InputBegan:Connect(function(input, processed)
                    if processed then return end
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then processClick(input.Position) end
                end)
                if UserInputService.TouchEnabled then
                    touchConnection = UserInputService.InputBegan:Connect(function(input, processed)
                        if processed then return end
                        if input.UserInputType == Enum.UserInputType.Touch then processClick(input.Position) end
                    end)
                end
            end
            
            setupClickDetection()
            
            LocalPlayer.CharacterAdded:Connect(function(char)
                char:WaitForChild("Humanoid")
                task.wait(0.5)
                setupClickDetection()
            end)
            
            Players.PlayerRemoving:Connect(function(player)
                if currentPlayer == player then closeProfile() end
            end)
