local RepStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Button = script.Parent
local PlayButtonAnim = RepStorage:WaitForChild("PlayButtonAnim")
local AnimName = Button.Name
local originalText = Button:IsA("TextButton") and Button.Text or nil

local countdownToken = 0

local function enableButton()
    Button.Active = true
    Button.AutoButtonColor = true
    if Button:IsA("TextButton") and originalText then
        Button.Text = originalText
    end
end

local function startCountdown(seconds)
    countdownToken += 1
    local myToken = countdownToken
    local endTime = os.clock() + seconds
    
    task.spawn(function()
        while true do
            if countdownToken ~= myToken then return end
            local remaining = endTime - os.clock()
            if remaining <= 0 then
                enableButton()
                return
            end
            if Button:IsA("TextButton") then
                Button.Text = tostring(math.ceil(remaining))
            end
            task.wait(0.1)
        end
    end)
end

local function stopCountdown()
    countdownToken += 1
    enableButton()
end

Button.MouseButton1Click:Connect(function()
    local player = Players.LocalPlayer
    local char = player.Character
    
    if char and char:FindFirstChild("UpperTorso") then return end
    if not Button.Active then return end
    
    PlayButtonAnim:FireServer("Play", AnimName)
end)

PlayButtonAnim.OnClientEvent:Connect(function(action, animName, totalTime)
    if action ~= "DisableButton" then return end
    if animName ~= AnimName then return end
    
    Button.Active = false
    Button.AutoButtonColor = false
    if totalTime and totalTime > 0 then
        startCountdown(totalTime)
    end
end)