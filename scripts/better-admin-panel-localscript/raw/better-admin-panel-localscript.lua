local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")
local Remote = ReplicatedStorage:WaitForChild("AdminPanelRemote")
local CheckAdminRemote = ReplicatedStorage:WaitForChild("CheckAdmin")

local function CreateAdminPanel()
    if PlayerGui:FindFirstChild("DarkModernAdmin") then
        PlayerGui.DarkModernAdmin:Destroy()
    end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "DarkModernAdmin"
    ScreenGui.ResetOnSpawn = true
    ScreenGui.Parent = PlayerGui

    local ToggleBtn = Instance.new("ImageButton")
    ToggleBtn.Name = "Toggle"
    ToggleBtn.Size = UDim2.new(0, 50, 0, 50)
    ToggleBtn.Position = UDim2.new(1, -60, 0.5, -25)
    ToggleBtn.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    ToggleBtn.BackgroundTransparency = 0.2
    ToggleBtn.Image = "rbxassetid://11656483343"
    ToggleBtn.BorderSizePixel = 0
    ToggleBtn.Active = true
    ToggleBtn.Draggable = true
    ToggleBtn.Parent = ScreenGui

    local ToggleAspect = Instance.new("UIAspectRatioConstraint")
    ToggleAspect.Parent = ToggleBtn

    local ToggleCorner = Instance.new("UICorner")
    ToggleCorner.CornerRadius = UDim.new(1, 0)
    ToggleCorner.Parent = ToggleBtn

    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, 500, 0, 320)
    MainFrame.Position = UDim2.new(0.5, -250, 0.5, -160)
    MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    MainFrame.BorderSizePixel = 0
    MainFrame.ClipsDescendants = true
    MainFrame.Visible = false
    MainFrame.Parent = ScreenGui

    local Aspect = Instance.new("UIAspectRatioConstraint")
    Aspect.AspectRatio = 1.56
    Aspect.Parent = MainFrame

    local MainCorner = Instance.new("UICorner")
    MainCorner.CornerRadius = UDim.new(0, 8)
    MainCorner.Parent = MainFrame

    local TopBar = Instance.new("Frame")
    TopBar.Size = UDim2.new(1, 0, 0, 45)
    TopBar.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    TopBar.BorderSizePixel = 0
    TopBar.Parent = MainFrame

    local TopCorner = Instance.new("UICorner")
    TopCorner.CornerRadius = UDim.new(0, 8)
    TopCorner.Parent = TopBar

    local BottomCover = Instance.new("Frame")
    BottomCover.Size = UDim2.new(1, 0, 0, 10)
    BottomCover.Position = UDim2.new(0, 0, 1, -10)
    BottomCover.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    BottomCover.BorderSizePixel = 0
    BottomCover.Parent = TopBar

    local CmdTabBtn = Instance.new("TextButton")
    CmdTabBtn.Name = "CmdTab"
    CmdTabBtn.Size = UDim2.new(0.5, 0, 1, 0)
    CmdTabBtn.BackgroundTransparency = 1
    CmdTabBtn.Text = "Commands"
    CmdTabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    CmdTabBtn.Font = Enum.Font.GothamBold
    CmdTabBtn.TextSize = 14
    CmdTabBtn.Parent = TopBar

    local ExecTabBtn = Instance.new("TextButton")
    ExecTabBtn.Name = "ExecTab"
    ExecTabBtn.Size = UDim2.new(0.5, 0, 1, 0)
    ExecTabBtn.Position = UDim2.new(0.5, 0, 0, 0)
    ExecTabBtn.BackgroundTransparency = 1
    ExecTabBtn.Text = "Run"
    ExecTabBtn.TextColor3 = Color3.fromRGB(150, 150, 150)
    ExecTabBtn.Font = Enum.Font.GothamBold
    ExecTabBtn.TextSize = 14
    ExecTabBtn.Parent = TopBar

    local Indicator = Instance.new("Frame")
    Indicator.Name = "Indicator"
    Indicator.Size = UDim2.new(0.5, 0, 0, 2)
    Indicator.Position = UDim2.new(0, 0, 1, -2)
    Indicator.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Indicator.BorderSizePixel = 0
    Indicator.Parent = TopBar

    local Container = Instance.new("Frame")
    Container.Name = "Container"
    Container.Size = UDim2.new(2, 0, 1, -45)
    Container.Position = UDim2.new(0, 0, 0, 45)
    Container.BackgroundTransparency = 1
    Container.Parent = MainFrame

    local CommandsPage = Instance.new("Frame")
    CommandsPage.Name = "CommandsPage"
    CommandsPage.Size = UDim2.new(0.5, 0, 1, 0)
    CommandsPage.BackgroundTransparency = 1
    CommandsPage.Parent = Container

    local ExecutePage = Instance.new("Frame")
    ExecutePage.Name = "ExecutePage"
    ExecutePage.Size = UDim2.new(0.5, 0, 1, 0)
    ExecutePage.Position = UDim2.new(0.5, 0, 0, 0)
    ExecutePage.BackgroundTransparency = 1
    ExecutePage.Parent = Container

    local Scroll = Instance.new("ScrollingFrame")
    Scroll.Name = "Scroll"
    Scroll.Size = UDim2.new(1, -20, 1, -60)
    Scroll.Position = UDim2.new(0, 10, 0, 10)
    Scroll.BackgroundTransparency = 1
    Scroll.BorderSizePixel = 0
    Scroll.ScrollBarThickness = 4
    Scroll.ScrollBarImageColor3 = Color3.fromRGB(60, 60, 60)
    Scroll.Parent = CommandsPage

    local PageButtons = Instance.new("Frame")
    PageButtons.Size = UDim2.new(1, -20, 0, 30)
    PageButtons.Position = UDim2.new(0, 10, 1, -40)
    PageButtons.BackgroundTransparency = 1
    PageButtons.Parent = CommandsPage

    local PrevPage = Instance.new("TextButton")
    PrevPage.Size = UDim2.new(0.2, 0, 1, 0)
    PrevPage.Text = "<"
    PrevPage.TextColor3 = Color3.fromRGB(255, 255, 255)
    PrevPage.Font = Enum.Font.GothamBold
    PrevPage.TextSize = 14
    PrevPage.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    PrevPage.Parent = PageButtons

    local PageLabel = Instance.new("TextLabel")
    PageLabel.Size = UDim2.new(0.6, 0, 1, 0)
    PageLabel.Position = UDim2.new(0.2, 0, 0, 0)
    PageLabel.Text = "Page 1"
    PageLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    PageLabel.Font = Enum.Font.Gotham
    PageLabel.TextSize = 14
    PageLabel.BackgroundTransparency = 1
    PageLabel.Parent = PageButtons

    local NextPage = Instance.new("TextButton")
    NextPage.Size = UDim2.new(0.2, 0, 1, 0)
    NextPage.Position = UDim2.new(0.8, 0, 0, 0)
    NextPage.Text = ">"
    NextPage.TextColor3 = Color3.fromRGB(255, 255, 255)
    NextPage.Font = Enum.Font.GothamBold
    NextPage.TextSize = 14
    NextPage.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    NextPage.Parent = PageButtons

    local PrevCorner = Instance.new("UICorner")
    PrevCorner.CornerRadius = UDim.new(0, 6)
    PrevCorner.Parent = PrevPage

    local NextCorner = Instance.new("UICorner")
    NextCorner.CornerRadius = UDim.new(0, 6)
    NextCorner.Parent = NextPage

    local CmdInputBox = Instance.new("TextBox")
    CmdInputBox.Size = UDim2.new(0.8, 0, 0, 40)
    CmdInputBox.Position = UDim2.new(0.1, 0, 0.3, 0)
    CmdInputBox.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    CmdInputBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    CmdInputBox.Font = Enum.Font.Gotham
    CmdInputBox.TextSize = 14
    CmdInputBox.PlaceholderText = "Type command here..."
    CmdInputBox.TextXAlignment = Enum.TextXAlignment.Left
    CmdInputBox.ClearTextOnFocus = false
    CmdInputBox.Parent = ExecutePage

    local InputPadding = Instance.new("UIPadding")
    InputPadding.PaddingLeft = UDim.new(0, 10)
    InputPadding.Parent = CmdInputBox

    local InputCorner = Instance.new("UICorner")
    InputCorner.CornerRadius = UDim.new(0, 6)
    InputCorner.Parent = CmdInputBox

    local ExecuteBtn = Instance.new("TextButton")
    ExecuteBtn.Size = UDim2.new(0.4, 0, 0, 35)
    ExecuteBtn.Position = UDim2.new(0.3, 0, 0.5, 0)
    ExecuteBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    ExecuteBtn.Text = "Run"
    ExecuteBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    ExecuteBtn.Font = Enum.Font.GothamBold
    ExecuteBtn.TextSize = 14
    ExecuteBtn.Parent = ExecutePage

    local ExecBtnCorner = Instance.new("UICorner")
    ExecBtnCorner.CornerRadius = UDim.new(0, 6)
    ExecBtnCorner.Parent = ExecuteBtn

    local CommandsData = {}
    
    local function UpdateCommandsList(commandsFromServer)
        CommandsData = commandsFromServer
        table.sort(CommandsData)
        PopulateList()
    end
    
    local currentPage = 1
    local commandsPerPage = 24

    local function PopulateList()
        Scroll:ClearAllChildren()
        
        local Grid = Instance.new("UIGridLayout")
        Grid.CellSize = UDim2.new(0.31, 0, 0, 35)
        Grid.CellPadding = UDim2.new(0.02, 0, 0.02, 0)
        Grid.SortOrder = Enum.SortOrder.LayoutOrder
        Grid.Parent = Scroll
        
        local Pad = Instance.new("UIPadding")
        Pad.PaddingTop = UDim.new(0,5)
        Pad.PaddingLeft = UDim.new(0,5)
        Pad.Parent = Scroll
        
        local startIndex = (currentPage - 1) * commandsPerPage + 1
        local endIndex = math.min(startIndex + commandsPerPage - 1, #CommandsData)
        
        for i = startIndex, endIndex do
            local cmd = CommandsData[i]
            
            local btn = Instance.new("TextButton")
            btn.Name = cmd
            btn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
            btn.Text = cmd
            btn.TextColor3 = Color3.fromRGB(200, 200, 200)
            btn.Font = Enum.Font.GothamSemibold
            btn.TextSize = 12
            btn.Parent = Scroll
            
            local c = Instance.new("UICorner")
            c.CornerRadius = UDim.new(0, 4)
            c.Parent = btn
            
            btn.MouseButton1Click:Connect(function()
                CmdInputBox.Text = cmd .. " "
                CmdInputBox:CaptureFocus()
            end)
        end
        
        Scroll.CanvasSize = UDim2.new(0, 0, 0, Grid.AbsoluteContentSize.Y + 10)
        
        local totalPages = math.ceil(#CommandsData/commandsPerPage)
        PageLabel.Text = "Page "..currentPage.." of "..totalPages
        
        if currentPage <= 1 then
            PrevPage.Active = false
            PrevPage.BackgroundTransparency = 0.5
        else
            PrevPage.Active = true
            PrevPage.BackgroundTransparency = 0
        end
        
        if currentPage >= totalPages then
            NextPage.Active = false
            NextPage.BackgroundTransparency = 0.5
        else
            NextPage.Active = true
            NextPage.BackgroundTransparency = 0
        end
    end

    ToggleBtn.MouseButton1Click:Connect(function()
        MainFrame.Visible = not MainFrame.Visible
    end)

    local function SwitchTab(tabName)
        if tabName == "Commands" then
            Container:TweenPosition(UDim2.new(0, 0, 0, 45), "Out", "Quint", 0.4, true)
            Indicator:TweenPosition(UDim2.new(0, 0, 1, -2), "Out", "Quint", 0.3, true)
            CmdTabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            ExecTabBtn.TextColor3 = Color3.fromRGB(150, 150, 150)
        else
            Container:TweenPosition(UDim2.new(-1, 0, 0, 45), "Out", "Quint", 0.4, true)
            Indicator:TweenPosition(UDim2.new(0.5, 0, 1, -2), "Out", "Quint", 0.3, true)
            CmdTabBtn.TextColor3 = Color3.fromRGB(150, 150, 150)
            ExecTabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        end
    end

    CmdTabBtn.MouseButton1Click:Connect(function() SwitchTab("Commands") end)
    ExecTabBtn.MouseButton1Click:Connect(function() SwitchTab("Run") end)

    PrevPage.MouseButton1Click:Connect(function()
        if currentPage > 1 then
            currentPage = currentPage - 1
            PopulateList()
        end
    end)

    NextPage.MouseButton1Click:Connect(function()
        if currentPage < math.ceil(#CommandsData/commandsPerPage) then
            currentPage = currentPage + 1
            PopulateList()
        end
    end)

    CmdInputBox.FocusLost:Connect(function(enterPressed)
        if enterPressed and CmdInputBox.Text ~= "" then
            Remote:FireServer("Execute", CmdInputBox.Text)
            CmdInputBox.Text = ""
        end
    end)

    ExecuteBtn.MouseButton1Click:Connect(function()
        if CmdInputBox.Text ~= "" then
            Remote:FireServer("Execute", CmdInputBox.Text)
            CmdInputBox.Text = ""
        end
    end)

    local dragging, dragInput, dragStart, startPos
    MainFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = MainFrame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    MainFrame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    
    Remote:FireServer("RequestCommands")
end

local function CheckAdminStatus()
    local isAdmin = CheckAdminRemote:InvokeServer()
    if isAdmin then
        CreateAdminPanel()
    else
        if PlayerGui:FindFirstChild("DarkModernAdmin") then
            PlayerGui.DarkModernAdmin:Destroy()
        end
    end
end

CheckAdminStatus()
player.CharacterAdded:Connect(CheckAdminStatus)