local players = game:GetService("Players")
local runService = game:GetService("RunService")
local debris = game:GetService("Debris")
local tweens = game:GetService("TweenService")
local userInputService = game:GetService("UserInputService")

local lp = players.LocalPlayer
local char = lp.Character or lp.CharacterAdded:Wait()
local hum = char:WaitForChild("Humanoid")
local root = char:WaitForChild("HumanoidRootPart")

local CD_TIME = 5
local POWER = 75
local DUR = 0.2

-- Detect if player is on PC
local isMobile = userInputService.TouchEnabled and not userInputService.KeyboardEnabled

local gui = Instance.new("ScreenGui")
gui.Name = "DashSystemGui"
gui.ResetOnSpawn = true
gui.Parent = lp:WaitForChild("PlayerGui")

local btn = Instance.new("TextButton")
btn.Name = "DashBtn"
btn.Size = UDim2.fromScale(0.12, 0.12)
btn.Position = UDim2.fromScale(0.86, 0.55)
btn.AnchorPoint = Vector2.new(0.5, 0.5)
btn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
btn.BackgroundTransparency = 0.4
btn.Text = "Dash"
btn.TextColor3 = Color3.fromRGB(255, 255, 255)
btn.Font = Enum.Font.GothamBold
btn.TextScaled = false
btn.TextSize = 23
btn.Visible = isMobile -- Hide on PC, show on mobile
btn.Parent = gui

local round = Instance.new("UICorner")
round.CornerRadius = UDim.new(0.5, 0)
round.Parent = btn

local stroke = Instance.new("UIStroke")
stroke.Color = btn.BackgroundColor3
stroke.Thickness = 3
stroke.Transparency = 0.5
stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
stroke.Parent = btn

local pad = Instance.new("UIPadding")
local spacing = UDim.new(0.20, 0)
pad.PaddingBottom = spacing
pad.PaddingTop = spacing
pad.PaddingLeft = spacing
pad.PaddingRight = spacing
pad.Parent = btn

Instance.new("UIAspectRatioConstraint", btn).AspectRatio = 1

lp.CharacterAdded:Connect(function(newChar)
    char = newChar
        hum = newChar:WaitForChild("Humanoid")
            root = newChar:WaitForChild("HumanoidRootPart")
                
                    hum.Died:Connect(function()
                            gui:Destroy()
                                end)
                                end)

                                local function doDash()
                                    local state = hum:GetState()
                                        if state == Enum.HumanoidStateType.Jumping or state == Enum.HumanoidStateType.Freefall then return end
                                            
                                                local stamp = lp:GetAttribute("DashCD") or 0
                                                    if os.clock() < stamp then return end
                                                        
                                                            lp:SetAttribute("DashCD", os.clock() + CD_TIME)
                                                                
                                                                    local dir = hum.MoveDirection
                                                                        if dir.Magnitude < 0.1 then
                                                                                dir = root.CFrame.LookVector
                                                                                    end
                                                                                        
                                                                                            local att = Instance.new("Attachment", root)
                                                                                                local vel = Instance.new("LinearVelocity", att)
                                                                                                    
                                                                                                        vel.MaxForce = 9999999
                                                                                                            vel.VectorVelocity = dir * POWER
                                                                                                                vel.Attachment0 = att
                                                                                                                    vel.RelativeTo = Enum.ActuatorRelativeTo.World
                                                                                                                        
                                                                                                                            debris:AddItem(att, DUR)
                                                                                                                            end

                                                                                                                            -- Button click for mobile
                                                                                                                            btn.MouseButton1Click:Connect(doDash)

                                                                                                                            -- F key input for PC
                                                                                                                            userInputService.InputBegan:Connect(function(input, gameProcessed)
                                                                                                                                if gameProcessed then return end
                                                                                                                                    
                                                                                                                                        if input.KeyCode == Enum.KeyCode.F then
                                                                                                                                                doDash()
                                                                                                                                                    end
                                                                                                                                                    end)

                                                                                                                                                    -- Update button text with cooldown
                                                                                                                                                    runService.RenderStepped:Connect(function()
                                                                                                                                                        if not isMobile then return end -- Skip rendering if on PC
                                                                                                                                                            
                                                                                                                                                                local stamp = lp:GetAttribute("DashCD") or 0
                                                                                                                                                                    local diff = stamp - os.clock()
                                                                                                                                                                        
                                                                                                                                                                            if diff > 0 then
                                                                                                                                                                                    btn.Text = string.format("%.1f", diff)
                                                                                                                                                                                            btn.BackgroundTransparency = 0.7
                                                                                                                                                                                                    stroke.Transparency = 0.8
                                                                                                                                                                                                        else
                                                                                                                                                                                                                btn.Text = "Dash"
                                                                                                                                                                                                                        btn.BackgroundTransparency = 0.4
                                                                                                                                                                                                                                stroke.Transparency = 0.5
                                                                                                                                                                                                                                    end
                                                                                                                                                                                                                                    end)

                                                                                                                                                                                                                                    if hum then
                                                                                                                                                                                                                                        hum.Died:Connect(function()
                                                                                                                                                                                                                                                gui:Destroy()
                                                                                                                                                                                                                                                    end)
                                                                                                                                                                                                                                                    end