local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local character = script.Parent

local keyboardModel = Workspace:WaitForChild("Keyboard")

local CHOSEN_SCHEME = "Candy"
local PRESS_DISTANCE = 4

local colorSchemes = {
	Chocolate = {
		Color3.fromRGB(62, 39, 35),
		Color3.fromRGB(93, 64, 55),
		Color3.fromRGB(141, 110, 99),
		Color3.fromRGB(188, 170, 164),
		Color3.fromRGB(215, 204, 200),
		Color3.fromRGB(109, 76, 65),
	},
	Candy = {
		Color3.fromRGB(255, 182, 193),
		Color3.fromRGB(255, 105, 180),
		Color3.fromRGB(173, 216, 230),
		Color3.fromRGB(152, 251, 152),
		Color3.fromRGB(221, 160, 221),
		Color3.fromRGB(255, 253, 208),
		Color3.fromRGB(255, 218, 185),
	},
	Sunset = {
		Color3.fromRGB(242, 196, 71),
		Color3.fromRGB(247, 98, 24),
		Color3.fromRGB(255, 29, 104),
		Color3.fromRGB(177, 0, 101),
		Color3.fromRGB(116, 5, 128),
	},
	Ocean = {
		Color3.fromRGB(24, 54, 62),
		Color3.fromRGB(95, 151, 170),
		Color3.fromRGB(45, 95, 110),
		Color3.fromRGB(62, 136, 165),
		Color3.fromRGB(147, 196, 209),
	},
	Pastel = {
		Color3.fromRGB(240, 141, 126),
		Color3.fromRGB(239, 161, 138),
		Color3.fromRGB(226, 186, 177),
		Color3.fromRGB(221, 166, 185),
		Color3.fromRGB(172, 174, 197),
	},
}

local colorScheme = colorSchemes[CHOSEN_SCHEME] or colorSchemes.Candy

local alphabet = {"A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z"}

local keyStates = {}
local previousLetter = ""

local tweenInfoDown = TweenInfo.new(0.06, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local tweenInfoUp = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

for _, element in ipairs(keyboardModel:GetDescendants()) do
	if element:IsA("BasePart") then
		if not element:GetAttribute("Initialized") then
			element:SetAttribute("Initialized", true)
			element:SetAttribute("OriginalCFrame", element.CFrame)

			local assignedColor = colorScheme[math.random(1, #colorScheme)]
			element.Color = assignedColor

			local sound = Instance.new("Sound")
			sound.Name = "KeySound"
			sound.SoundId = "rbxassetid://102855535543930"
			sound.Volume = 1
			sound.Parent = element

			local surfaceGui = Instance.new("SurfaceGui")
			surfaceGui.Name = "KeyGui"
			surfaceGui.Face = Enum.NormalId.Top
			surfaceGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
			surfaceGui.PixelsPerStud = 50
			surfaceGui.Parent = element

			local textLabel = Instance.new("TextLabel")
			textLabel.Size = UDim2.new(1, 0, 1, 0)
			textLabel.BackgroundTransparency = 1
			textLabel.Font = Enum.Font.GothamBold
			textLabel.TextColor3 = Color3.new(0, 0, 0)
			textLabel.TextScaled = true

			local chosenLetter
			repeat
				chosenLetter = alphabet[math.random(1, #alphabet)]
			until chosenLetter ~= previousLetter
			previousLetter = chosenLetter

			textLabel.Text = chosenLetter
			textLabel.Parent = surfaceGui

			local uiStroke = Instance.new("UIStroke")
			uiStroke.Color = Color3.new(0, 0, 0)
			uiStroke.Thickness = 1.5
			uiStroke.Parent = textLabel
		end

		local state = {
			originalCFrame = element:GetAttribute("OriginalCFrame"),
			pressed = false,
			activeTween = nil,
		}
		keyStates[element] = state

		local sound = element:FindFirstChild("KeySound")

		task.spawn(function()
			while character and character.Parent do
				task.wait(0.02)

				local root = character:FindFirstChild("HumanoidRootPart")

				if root then
					local dist = (root.Position - state.originalCFrame.Position).Magnitude

					if dist <= PRESS_DISTANCE and not state.pressed then
						state.pressed = true

						if state.activeTween then
							state.activeTween:Cancel()
							state.activeTween = nil
						end

						if sound then
							sound:Play()
						end

						local targetCFrame = state.originalCFrame - Vector3.new(0, 0.6, 0)
						local tween = TweenService:Create(element, tweenInfoDown, {CFrame = targetCFrame})
						tween:Play()
						state.activeTween = tween

					elseif dist > PRESS_DISTANCE and state.pressed then
						state.pressed = false

						if state.activeTween then
							state.activeTween:Cancel()
							state.activeTween = nil
						end

						local tween = TweenService:Create(element, tweenInfoUp, {CFrame = state.originalCFrame})
						tween:Play()
						state.activeTween = tween
					end
				end
			end
		end)
	end
end
