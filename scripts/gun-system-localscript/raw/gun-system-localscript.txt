local tool = script.Parent
local player = game.Players.LocalPlayer
local UIS = game:GetService("UserInputService")
local camera = workspace.CurrentCamera
local GuiService = game:GetService("GuiService")

local remoteFunction = tool:FindFirstChildOfClass("RemoteFunction")
while not remoteFunction do
    task.wait()
    remoteFunction = tool:FindFirstChildOfClass("RemoteFunction")
end

local remoteEvent = tool:FindFirstChildOfClass("RemoteEvent")
while not remoteEvent do
    task.wait()
    remoteEvent = tool:FindFirstChildOfClass("RemoteEvent")
end

local CONFIG = remoteFunction:InvokeServer()

local fireSound = tool:WaitForChild("Fire", 5)
local reloadSound = tool:WaitForChild("Reload", 5)
local equipSound = tool:WaitForChild("Equip", 5)

local playerGui = player:WaitForChild("PlayerGui")
local gui = playerGui:FindFirstChild("GunShoot") or Instance.new("ScreenGui")
gui.Name = "GunShoot"
gui.ResetOnSpawn = false
gui.Enabled = false
gui.IgnoreGuiInset = true
gui.Parent = playerGui

local crosshair = Instance.new("Frame")
crosshair.Name = "Crosshair"
crosshair.Size = UDim2.new(0, 0, 0, 0)
crosshair.Position = UDim2.new(0.5, 0, 0.5, 0)
crosshair.AnchorPoint = Vector2.new(0.5, 0.5)
crosshair.BackgroundTransparency = 1
crosshair.Visible = true
crosshair.Parent = gui

local function makeLine(name, size, pos)
    local line = Instance.new("Frame")
    line.Name = name
    line.Size = size
    line.Position = pos
    line.BackgroundColor3 = Color3.new(1, 1, 1)
    line.BorderSizePixel = 0
    line.Parent = crosshair
end

makeLine("Horizontal", UDim2.new(0, 10, 0, 2), UDim2.new(0.5, -5, 0.5, -1))
makeLine("Vertical", UDim2.new(0, 2, 0, 10), UDim2.new(0.5, -1, 0.5, -5))

local ammoLabel = Instance.new("TextLabel")
ammoLabel.Name = "AmmoLabel"
ammoLabel.AnchorPoint = Vector2.new(0.5, 0)
ammoLabel.Size = UDim2.new(0.15, 0, 0.05, 0)
ammoLabel.Position = UDim2.new(0.5, 0, 0.05, 0)
ammoLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
ammoLabel.BackgroundTransparency = 0.3
ammoLabel.TextColor3 = Color3.new(1, 1, 1)
ammoLabel.Font = CONFIG.TextFont
ammoLabel.TextScaled = true
ammoLabel.Text = ""
ammoLabel.Parent = gui

local ammoCorner = Instance.new("UICorner")
ammoCorner.CornerRadius = UDim.new(0.2, 0)
ammoCorner.Parent = ammoLabel

local ammoTextConstraint = Instance.new("UITextSizeConstraint")
ammoTextConstraint.MinTextSize = 14
ammoTextConstraint.MaxTextSize = 35
ammoTextConstraint.Parent = ammoLabel

local shootButton = Instance.new("TextButton")
shootButton.Name = "ShootButton"
shootButton.Size = UDim2.new(0, 150, 0, 150)
shootButton.AnchorPoint = Vector2.new(1, 0.5)
shootButton.Position = UDim2.new(0.95, 0, 0.5, 0)
shootButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
shootButton.BackgroundTransparency = 0.3
shootButton.TextColor3 = Color3.new(1, 1, 1)
shootButton.Font = CONFIG.TextFont
shootButton.TextScaled = true
shootButton.Text = "Shoot"
shootButton.Visible = false
shootButton.Parent = gui

local buttonTextConstraint = Instance.new("UITextSizeConstraint")
buttonTextConstraint.MinTextSize = 14
buttonTextConstraint.MaxTextSize = 30
buttonTextConstraint.Parent = shootButton

local ratioConstraint = Instance.new("UIAspectRatioConstraint")
ratioConstraint.Parent = shootButton

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0.5, 0)
corner.Parent = shootButton

local ammo = 20
local reloading = false
local shooting = false
local lastShot = 0
local shoot

local function updateAmmoDisplay(textOverride)
    ammoLabel.Text = textOverride or (ammo .. "/20")
end

local function reloadGun()
    reloading = true
    shootButton.Text = "Reloading..."
    updateAmmoDisplay("Reloading...")
    if reloadSound then
        reloadSound:Play()
    end
    task.delay(CONFIG.ReloadTime, function()
        ammo = 20
        reloading = false
        updateAmmoDisplay()
        shootButton.Text = "Shoot"
        if shooting and shoot then shoot() end
    end)
end

shoot = function()
    if reloading or ammo <= 0 then
        if ammo <= 0 and not reloading then reloadGun() end
        return
    end
    
    local now = tick()
    if now - lastShot < CONFIG.FireRate then return end
    lastShot = now
    
    ammo -= 1
    updateAmmoDisplay()
    
    local viewportSize = camera.ViewportSize
    local center = Vector2.new(viewportSize.X / 2, viewportSize.Y / 2)
    local ray = camera:ViewportPointToRay(center.X, center.Y)
    
    remoteEvent:FireServer({
        origin = ray.Origin,
        direction = ray.Direction
    })
end

shootButton.MouseButton1Down:Connect(function()
    if not reloading then
        shooting = true
        while shooting do
            shoot()
            task.wait(CONFIG.FireRate)
        end
    end
end)

shootButton.MouseButton1Up:Connect(function()
    shooting = false
end)

UIS.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 and gui.Enabled then
        shooting = true
        while shooting do
            shoot()
            task.wait(CONFIG.FireRate)
        end
    end
end)

UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        shooting = false
    end
end)

tool.Equipped:Connect(function()
    gui.Enabled = true
    updateAmmoDisplay()
    crosshair.Visible = true
    shootButton.Visible = UIS.TouchEnabled
    if equipSound then
        equipSound:Play()
    end
    player.CameraMode = Enum.CameraMode.LockFirstPerson
end)

tool.Unequipped:Connect(function()
    gui.Enabled = false
    crosshair.Visible = false
    shooting = false
    shootButton.Visible = false
    player.CameraMode = Enum.CameraMode.Classic
end)

local function cleanupTool()
    if gui then
        gui:Destroy()
    end
    if player.CameraMode == Enum.CameraMode.LockFirstPerson then
        player.CameraMode = Enum.CameraMode.Classic
    end
end

tool.AncestryChanged:Connect(function(_, parent)
    if not parent then
        cleanupTool()
    end
end)

local function onCharacterAdded(character)
    local humanoid = character:WaitForChild("Humanoid")
    humanoid.Died:Connect(cleanupTool)
end

if player.Character then
    onCharacterAdded(player.Character)
end

player.CharacterAdded:Connect(onCharacterAdded)