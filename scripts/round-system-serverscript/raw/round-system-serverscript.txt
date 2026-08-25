local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local TextChatService = game:GetService("TextChatService")
local DataStoreService = game:GetService("DataStoreService")

local DataStoreName = "WinsLeaderboard1"
local LeaderstatName = "Wins"
local TieGrantsWin = true
local LobbySpawnName = "SpawnLocation"

local WinsLeaderboard = DataStoreService:GetDataStore(DataStoreName)
local lobbySpawn = Workspace:WaitForChild(LobbySpawnName)
local mapsFolder = ServerStorage:WaitForChild("Maps")
local serverToolsFolder = ServerStorage:WaitForChild("Tools")

local config = {
    RoundTime = 120,
    WinsReward = 1,
    MinPlayers = 2
}

local adminIds = {
    [8033814042] = true -- replace with your roblox user id
}

local activeRoundPlayers = {}
local activeSet = {}
local currentMap = nil
local previousMaps = {}
local forcedNextMap = ""
local isRoundActive = false
local isSystemPaused = false
local currentRoundId = 0
local currentCancelToken = nil

local roundBindable = Instance.new("BindableEvent")

local chatCommandsFolder = TextChatService:FindFirstChild("TextChatCommands")
if not chatCommandsFolder then
    chatCommandsFolder = Instance.new("Folder")
    chatCommandsFolder.Name = "TextChatCommands"
    chatCommandsFolder.Parent = TextChatService
end

local skipCmd = Instance.new("TextChatCommand")
skipCmd.Name = "SkipRound"
skipCmd.PrimaryAlias = "/skipround"
skipCmd.Parent = chatCommandsFolder

local nextMapCmd = Instance.new("TextChatCommand")
nextMapCmd.Name = "NextMap"
nextMapCmd.PrimaryAlias = "/nextmap"
nextMapCmd.Parent = chatCommandsFolder

local pauseCmd = Instance.new("TextChatCommand")
pauseCmd.Name = "PauseRound"
pauseCmd.PrimaryAlias = "/pauseround"
pauseCmd.Parent = chatCommandsFolder

local function savePlayerData(player)
    if not player then return end
    local leaderstats = player:FindFirstChild("leaderstats")
    if not leaderstats then return end
    local wins = leaderstats:FindFirstChild(LeaderstatName)
    if not wins then return end
    pcall(function()
        WinsLeaderboard:SetAsync(player.UserId, wins.Value)
    end)
end

local function loadPlayerData(player)
    local leaderstats = player:FindFirstChild("leaderstats")
    if not leaderstats then return end
    local wins = leaderstats:FindFirstChild(LeaderstatName)
    if not wins then return end
    local success, data = pcall(function()
        return WinsLeaderboard:GetAsync(player.UserId)
    end)
    if success and data then
        wins.Value = data
    else
        wins.Value = 0
    end
end

local function awardAndSave(player, amount)
    if player and player:FindFirstChild("leaderstats") then
        local stat = player.leaderstats:FindFirstChild(LeaderstatName)
        if stat then
            stat.Value = stat.Value + amount
            savePlayerData(player)
        end
    end
end

local function saveAllPlayers()
    for _, player in ipairs(Players:GetPlayers()) do
        savePlayerData(player)
    end
end

local function createUI(player)
    local playerGui = player:WaitForChild("PlayerGui", 5)
    if not playerGui then return end
    if playerGui:FindFirstChild("RoundUI") then return end
    local pg = Instance.new("ScreenGui")
    pg.Name = "RoundUI"
    pg.ResetOnSpawn = false
    pg.IgnoreGuiInset = true
    pg.Parent = playerGui
    local mf = Instance.new("Frame")
    mf.Name = "MainFrame"
    mf.Size = UDim2.new(0.3, 0, 0.05, 0)
    mf.Position = UDim2.new(0.5, 0, 0, 45)
    mf.AnchorPoint = Vector2.new(0.5, 0)
    mf.BackgroundTransparency = 1
    mf.Parent = pg
    local ar = Instance.new("UIAspectRatioConstraint")
    ar.AspectRatio = 6
    ar.Parent = mf
    local lbl = Instance.new("TextLabel")
    lbl.Name = "StatusLabel"
    lbl.Size = UDim2.new(1, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = "Waiting..."
    lbl.Font = Enum.Font.MontserratBold
    lbl.TextColor3 = Color3.new(1, 1, 1)
    lbl.TextScaled = true
    lbl.Parent = mf
    local str = Instance.new("UIStroke")
    str.Thickness = 2
    str.Parent = lbl
end

local function createLeaderstats(player)
    if player:FindFirstChild("leaderstats") then return end
    local ls = Instance.new("Folder")
    ls.Name = "leaderstats"
    ls.Parent = player
    local w = Instance.new("IntValue")
    w.Name = LeaderstatName
    w.Parent = ls
end

local function updateAllUI(text)
    for _, player in ipairs(Players:GetPlayers()) do
        local gui = player:FindFirstChild("PlayerGui")
        if gui and gui:FindFirstChild("RoundUI") then
            gui.RoundUI.MainFrame.StatusLabel.Text = text
        end
    end
end

local function clearTools(player)
    if not player then return end
    local backpack = player:FindFirstChild("Backpack")
    if backpack then backpack:ClearAllChildren() end
    if player.Character then
        for _, tool in ipairs(player.Character:GetChildren()) do
            if tool:IsA("Tool") then tool:Destroy() end
        end
    end
end

local function cleanupCharacterEffects(player)
    if not player or not player.Character then return end
    for _, obj in ipairs(player.Character:GetChildren()) do
        if obj:IsA("SelectionBox") or obj:IsA("Highlight")
            or obj:IsA("BodyVelocity") or obj:IsA("BodyForce") or obj:IsA("BodyGyro")
            or obj:IsA("BodyPosition") or obj:IsA("BodyAngularVelocity") or obj:IsA("AlignPosition")
            or obj:IsA("AlignOrientation") or obj:IsA("LinearVelocity") or obj:IsA("AngularVelocity")
            or obj:IsA("VectorForce") or obj:IsA("Torque") or obj:IsA("Fire") or obj:IsA("Smoke")
            or obj:IsA("Sparkles") or obj:IsA("ParticleEmitter") then
            obj:Destroy()
        end
    end
    for _, part in ipairs(player.Character:GetDescendants()) do
        if part:IsA("Fire") or part:IsA("Smoke") or part:IsA("Sparkles") or part:IsA("ParticleEmitter") then
            part:Destroy()
        end
    end
end

local function returnPlayerToLobby(player)
    if not player or not player.Parent then return end
    clearTools(player)
    cleanupCharacterEffects(player)
    if player.Character then
        local hum = player.Character:FindFirstChild("Humanoid")
        if hum then
            hum.Health = hum.MaxHealth
        end
        player.Character:PivotTo(lobbySpawn.CFrame + Vector3.new(0, 3, 0))
    end
end

local function handleToolDistribution(mapName)
    local mapToolFolder = serverToolsFolder:FindFirstChild(mapName)
    if not mapToolFolder then return end
    local val = mapToolFolder:FindFirstChild("Value")
    local mode = "none"
    if val then mode = val.Value end
    local tools = {}
    for _, item in ipairs(mapToolFolder:GetChildren()) do
        if item:IsA("Tool") then table.insert(tools, item) end
    end
    if #tools == 0 or mode == "none" then return end
    
    local function giveAndEquip(p, toolsList)
        if p and p.Parent and p.Character then
            local hum = p.Character:FindFirstChild("Humanoid")
            local backpack = p:FindFirstChild("Backpack")
            if hum and backpack and hum.Health > 0 then
                local lastTool = nil
                for _, t in ipairs(toolsList) do
                    local clone = t:Clone()
                    clone.Parent = backpack
                    lastTool = clone
                end
                if lastTool then
                    hum:EquipTool(lastTool)
                end
            end
        end
    end
    
    if mode == "all" then
        for _, p in ipairs(activeRoundPlayers) do
            giveAndEquip(p, tools)
        end
    elseif mode == "random" then
        if #activeRoundPlayers > 0 then
            local p = activeRoundPlayers[math.random(1, #activeRoundPlayers)]
            giveAndEquip(p, tools)
        end
    end
end

local function removeFromActive(player)
    if not activeSet[player] then return end
    activeSet[player] = nil
    for i = #activeRoundPlayers, 1, -1 do
        if activeRoundPlayers[i] == player then
            table.remove(activeRoundPlayers, i)
            break
        end
    end
end

local function addToActive(player)
    if activeSet[player] then return end
    activeSet[player] = true
    table.insert(activeRoundPlayers, player)
end

local function isActivePlayerAlive(player)
    if not player or not player.Parent then return false end
    if not Players:GetPlayerByUserId(player.UserId) then return false end
    if player.Character then
        local hum = player.Character:FindFirstChild("Humanoid")
        if hum and hum.Health > 0 then return true end
    end
    return false
end

local function doCancellableWait(seconds, textFunc, roundId, abortCondition)
    local timeRemaining = seconds
    while timeRemaining > 0 do
        if roundId and (currentRoundId ~= roundId) then return false end
        if currentCancelToken and currentCancelToken.cancelled then return false end
        if isSystemPaused then return false end
        if abortCondition and abortCondition() then return false end
        if textFunc then
            updateAllUI(textFunc(timeRemaining))
        end
        task.wait(1)
        timeRemaining = timeRemaining - 1
    end
    return true
end

skipCmd.Triggered:Connect(function(origin)
    if adminIds[origin.UserId] then
        if isRoundActive then
            isRoundActive = false
            currentRoundId = currentRoundId + 1
            if currentCancelToken then currentCancelToken.cancelled = true end
            roundBindable:Fire({}, "Round Skipped!")
        else
            if currentCancelToken then currentCancelToken.cancelled = true end
        end
    end
end)

nextMapCmd.Triggered:Connect(function(origin, message)
    if adminIds[origin.UserId] then
        local args = {}
        for word in string.gmatch(message, "%S+") do
            table.insert(args, word)
        end
        if #args >= 2 then
            forcedNextMap = args[2]
        end
    end
end)

pauseCmd.Triggered:Connect(function(origin)
    if adminIds[origin.UserId] then
        isSystemPaused = not isSystemPaused
        if isSystemPaused then
            updateAllUI("Game paused!")
            if isRoundActive then
                isRoundActive = false
                currentRoundId = currentRoundId + 1
                if currentCancelToken then currentCancelToken.cancelled = true end
                roundBindable:Fire({}, "Round Skipped & Paused!")
            else
                if currentCancelToken then currentCancelToken.cancelled = true end
            end
        else
            updateAllUI("Resuming...")
        end
    end
end)

Players.PlayerAdded:Connect(function(player)
    createLeaderstats(player)
    loadPlayerData(player)
    player.CharacterAdded:Connect(function(character)
        createUI(player)
        if not isRoundActive then
            removeFromActive(player)
        else
            removeFromActive(player)
        end
    end)
    createUI(player)
end)

Players.PlayerRemoving:Connect(function(player)
    savePlayerData(player)
    removeFromActive(player)
end)

for _, player in ipairs(Players:GetPlayers()) do
    createLeaderstats(player)
    loadPlayerData(player)
    createUI(player)
end

game:BindToClose(function()
    saveAllPlayers()
    task.wait(2)
end)

task.spawn(function()
    while true do
        isRoundActive = false
        if currentMap then currentMap:Destroy() currentMap = nil end
        currentCancelToken = { cancelled = false }
        activeRoundPlayers = {}
        activeSet = {}

        while true do
            local readyCount = #Players:GetPlayers()
            if readyCount < config.MinPlayers or isSystemPaused then
                if isSystemPaused then
                    updateAllUI("Game paused!")
                else
                    updateAllUI("Waiting for players (" .. readyCount .. "/" .. config.MinPlayers .. ")")
                end
                task.wait(1)
            else
                break
            end
        end

        if not doCancellableWait(3, function() return "Selecting map (1/2)" end, nil) then continue end

        local mapModels = mapsFolder:GetChildren()
        local selectedMapModel = nil

        if forcedNextMap ~= "" then
            for _, m in ipairs(mapModels) do
                if string.lower(m.Name) == string.lower(forcedNextMap) then
                    selectedMapModel = m
                    break
                end
            end
        end

        if not selectedMapModel and #mapModels >= 1 then
            local possible = {}
            for _, m in ipairs(mapModels) do
                if not table.find(previousMaps, m.Name) then
                    table.insert(possible, m)
                end
            end
            if #possible > 0 then
                selectedMapModel = possible[math.random(1, #possible)]
            else
                selectedMapModel = mapModels[math.random(1, #mapModels)]
            end
        end

        if not selectedMapModel then continue end

        table.insert(previousMaps, 1, selectedMapModel.Name)
        if #previousMaps > 3 then table.remove(previousMaps, 4) end

        forcedNextMap = ""

        if not doCancellableWait(3, function() return "Teleporting players (2/2)" end, nil) then continue end

        currentMap = selectedMapModel:Clone()
        currentMap.Parent = Workspace

        task.wait(2)

        if currentCancelToken and currentCancelToken.cancelled then
            if currentMap then currentMap:Destroy() currentMap = nil end
            continue
        end

        for _, player in ipairs(Players:GetPlayers()) do
            if player.Character and player.Character:FindFirstChild("Humanoid") then
                player.Character.Humanoid.Health = player.Character.Humanoid.MaxHealth
                addToActive(player)
            end
        end

        if #activeRoundPlayers < config.MinPlayers then
            if currentMap then currentMap:Destroy() currentMap = nil end
            updateAllUI("Not enough players ready!")
            task.wait(2)
            continue
        end

        local spawns = {}
        local sFolder = currentMap:FindFirstChild("Spawns")
        if sFolder then
            for _, v in ipairs(sFolder:GetChildren()) do
                if v:IsA("BasePart") then table.insert(spawns, v) end
            end
        end

        local shuffledSpawns = {}
        for i, v in ipairs(spawns) do shuffledSpawns[i] = v end
        for i = #shuffledSpawns, 2, -1 do
            local j = math.random(1, i)
            shuffledSpawns[i], shuffledSpawns[j] = shuffledSpawns[j], shuffledSpawns[i]
        end

        local mapRoot = currentMap.PrimaryPart or currentMap:FindFirstChildWhichIsA("BasePart")

        for i, player in ipairs(activeRoundPlayers) do
            local dest = mapRoot
            if #shuffledSpawns > 0 then
                dest = shuffledSpawns[(i - 1) % #shuffledSpawns + 1]
            end
            if dest and player.Character then
                player.Character:PivotTo(dest.CFrame + Vector3.new(0, 3, 0))
            end
        end

        handleToolDistribution(selectedMapModel.Name)

        isRoundActive = true
        currentRoundId = currentRoundId + 1
        local thisRound = currentRoundId
        local cancelToken = currentCancelToken
        local timeRemaining = config.RoundTime

        while timeRemaining > 0 and isRoundActive and thisRound == currentRoundId and not cancelToken.cancelled do
            local alivePlayers = {}
            for _, p in ipairs(activeRoundPlayers) do
                if isActivePlayerAlive(p) then
                    table.insert(alivePlayers, p)
                else
                    if activeSet[p] then
                        removeFromActive(p)
                    end
                end
            end
            
            activeRoundPlayers = alivePlayers

            if #activeRoundPlayers <= 1 then
                break
            end

            updateAllUI("Time left: " .. timeRemaining)
            task.wait(1)
            timeRemaining = timeRemaining - 1
        end

        isRoundActive = false
        if currentCancelToken then currentCancelToken.cancelled = true end

        local finalSurvivors = {}
        for _, p in ipairs(activeRoundPlayers) do
            if isActivePlayerAlive(p) then
                table.insert(finalSurvivors, p)
            end
        end

        if #finalSurvivors == 1 then
            updateAllUI(finalSurvivors[1].Name .. " won!")
            awardAndSave(finalSurvivors[1], config.WinsReward)
        elseif #finalSurvivors > 1 then
            local winnerNames = {}
            for _, winner in ipairs(finalSurvivors) do
                table.insert(winnerNames, winner.Name)
                if TieGrantsWin then
                    awardAndSave(winner, config.WinsReward)
                end
            end
            
            local joinedNames = table.concat(winnerNames, ", ")
            
            if TieGrantsWin then
                updateAllUI(joinedNames .. " won!")
            else
                updateAllUI("Tie! " .. joinedNames .. " survived!")
            end
        else
            updateAllUI("Nobody won!")
        end

        task.wait(2)

        local playersToReturn = {}
        for _, p in ipairs(Players:GetPlayers()) do
            table.insert(playersToReturn, p)
        end

        for _, p in ipairs(playersToReturn) do
            returnPlayerToLobby(p)
        end
    end
end)
