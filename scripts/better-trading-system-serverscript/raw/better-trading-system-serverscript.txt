local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
 
local tradingSys = Instance.new("Folder")
tradingSys.Name = "TradingSys"
tradingSys.Parent = ReplicatedStorage
 
local tradeEvent = Instance.new("RemoteEvent")
tradeEvent.Name = "TradeEvent"
tradeEvent.Parent = tradingSys
 
local tradeFunction = Instance.new("RemoteFunction")
tradeFunction.Name = "TradeFunction"
tradeFunction.Parent = tradingSys
 
local activeTraders = {}
local pendingRequests = {}
local playerCooldowns = {}
local outgoingRequests = {}
local DEBOUNCE = 0.5
 
local function generateId()
    return HttpService:GenerateGUID(false)
end
 
local function tagTool(tool)
    if not tool:FindFirstChild("__TradeID") then
        local tag = Instance.new("StringValue")
        tag.Name = "__TradeID"
        tag.Value = generateId()
        tag.Parent = tool
    end
end
 
local function getToolId(tool)
    local tag = tool:FindFirstChild("__TradeID")
    return tag and tag.Value or nil
end
 
local function findToolById(container, id)
    for _, tool in ipairs(container:GetChildren()) do
        if tool:IsA("Tool") then
            if getToolId(tool) == id then
                return tool
            end
        end
    end
    return nil
end
 
local function findToolByIdInPlayerContainers(player, id)
    local backpack = player:FindFirstChild("Backpack")
    if backpack then
        local t = findToolById(backpack, id)
        if t then return t end
    end
    local char = player.Character
    if char then
        local t = findToolById(char, id)
        if t then return t end
    end
    return nil
end
 
local function getSession(player)
    return activeTraders[player]
end
 
local function cleanSession(session)
    if not session then return end
    session.TimerToken = (session.TimerToken or 0) + 1
    if session.Player1 then
        activeTraders[session.Player1] = nil
        tradeEvent:FireClient(session.Player1, "Close")
    end
    if session.Player2 then
        activeTraders[session.Player2] = nil
        tradeEvent:FireClient(session.Player2, "Close")
    end
end
 
local function tagAllTools(player)
    local backpack = player:FindFirstChild("Backpack")
    if backpack then
        for _, tool in ipairs(backpack:GetChildren()) do
            if tool:IsA("Tool") then tagTool(tool) end
        end
    end
    local char = player.Character
    if char then
        for _, tool in ipairs(char:GetChildren()) do
            if tool:IsA("Tool") then tagTool(tool) end
        end
    end
end
 
local function syncOffers(session)
    local p1Data, p2Data = {}, {}
    
    for i = #session.P1Offer, 1, -1 do
        local id = session.P1Offer[i]
        local item = findToolByIdInPlayerContainers(session.Player1, id)
        if item then
            table.insert(p1Data, {Name = item.Name, Texture = item.TextureId, ID = id})
        else
            table.remove(session.P1Offer, i)
        end
    end
    
    for i = #session.P2Offer, 1, -1 do
        local id = session.P2Offer[i]
        local item = findToolByIdInPlayerContainers(session.Player2, id)
        if item then
            table.insert(p2Data, {Name = item.Name, Texture = item.TextureId, ID = id})
        else
            table.remove(session.P2Offer, i)
        end
    end
    
    tradeEvent:FireClient(session.Player1, "UpdateView", p1Data, p2Data)
    tradeEvent:FireClient(session.Player2, "UpdateView", p2Data, p1Data)
end
 
local function stopTimer(session)
    session.TimerToken = (session.TimerToken or 0) + 1
    if session.Player1 then tradeEvent:FireClient(session.Player1, "HideTimer") end
    if session.Player2 then tradeEvent:FireClient(session.Player2, "HideTimer") end
end
 
local function processTrade(session)
    local p1Backpack = session.Player1:FindFirstChild("Backpack")
    local p2Backpack = session.Player2:FindFirstChild("Backpack")
    local p1Char = session.Player1.Character
    local p2Char = session.Player2.Character
    
    if not p1Backpack or not p2Backpack then return end
    
    local p1Tools = {}
    local p2Tools = {}
    
    for _, id in ipairs(session.P1Offer) do
        local tool = findToolByIdInPlayerContainers(session.Player1, id)
        if tool then table.insert(p1Tools, tool) end
    end
    
    for _, id in ipairs(session.P2Offer) do
        local tool = findToolByIdInPlayerContainers(session.Player2, id)
        if tool then table.insert(p2Tools, tool) end
    end
    
    local function unequipIfNeeded(char, toolList)
        if not char then return end
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        if not humanoid then return end
        for _, tool in ipairs(char:GetChildren()) do
            if tool:IsA("Tool") and table.find(toolList, tool) then
                humanoid:UnequipTools()
                break
            end
        end
    end
    
    unequipIfNeeded(p1Char, p1Tools)
    unequipIfNeeded(p2Char, p2Tools)
    
    task.wait()
    
    for _, tool in ipairs(p1Tools) do
        if tool and tool.Parent then
            tool.Parent = p2Backpack
        end
    end
    
    for _, tool in ipairs(p2Tools) do
        if tool and tool.Parent then
            tool.Parent = p1Backpack
        end
    end
end
 
local function startTimer(session)
    session.TimerToken = (session.TimerToken or 0) + 1
    local currentToken = session.TimerToken
    
    task.spawn(function()
        for i = 5, 1, -1 do
            if session.TimerToken ~= currentToken then return end
            if not session.Player1 or not session.Player1.Parent then return end
            if not session.Player2 or not session.Player2.Parent then return end
            tradeEvent:FireClient(session.Player1, "TimerUpdate", i)
            tradeEvent:FireClient(session.Player2, "TimerUpdate", i)
            task.wait(1)
        end
        
        if session.TimerToken ~= currentToken then return end
        if not session.Player1 or not session.Player1.Parent then return end
        if not session.Player2 or not session.Player2.Parent then return end
        
        tradeEvent:FireClient(session.Player1, "TimerUpdate", 0)
        tradeEvent:FireClient(session.Player2, "TimerUpdate", 0)
        
        task.wait(1.5)
        
        if session.TimerToken ~= currentToken then return end
        
        processTrade(session)
        cleanSession(session)
    end)
end
 
local function handleDeath(character, player)
    local humanoid = character:WaitForChild("Humanoid", 5)
    if humanoid then
        humanoid.Died:Connect(function()
            local session = getSession(player)
            if session then cleanSession(session) end
        end)
    end
end
 
local function watchCharacterTools(character)
    character.ChildAdded:Connect(function(child)
        if child:IsA("Tool") then tagTool(child) end
    end)
    for _, child in ipairs(character:GetChildren()) do
        if child:IsA("Tool") then tagTool(child) end
    end
end
 
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(character)
        handleDeath(character, player)
        watchCharacterTools(character)
    end)
    if player.Character then
        handleDeath(player.Character, player)
        watchCharacterTools(player.Character)
    end
    
    player.ChildAdded:Connect(function(child)
        if child:IsA("Backpack") then
            child.ChildAdded:Connect(function(tool)
                if tool:IsA("Tool") then tagTool(tool) end
            end)
            for _, tool in ipairs(child:GetChildren()) do
                if tool:IsA("Tool") then tagTool(tool) end
            end
        end
    end)
    
    local backpack = player:FindFirstChild("Backpack")
    if backpack then
        for _, tool in ipairs(backpack:GetChildren()) do
            if tool:IsA("Tool") then tagTool(tool) end
        end
        backpack.ChildAdded:Connect(function(tool)
            if tool:IsA("Tool") then tagTool(tool) end
        end)
    end
end)
 
tradeFunction.OnServerInvoke = function(player, target)
    local now = tick()
    if now - (playerCooldowns[player] or 0) < DEBOUNCE then return false, "cooldown" end
    playerCooldowns[player] = now
    
    if not target or target == player or not target.Parent then return false, "invalid" end
    if activeTraders[player] or activeTraders[target] then return false, "busy" end
    if outgoingRequests[player] then return false, "pending" end
    if pendingRequests[target] or outgoingRequests[target] then return false, "targetbusy" end
    
    local pRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    local tRoot = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
    
    if pRoot and tRoot and (pRoot.Position - tRoot.Position).Magnitude <= 15 then
        pendingRequests[target] = player
        outgoingRequests[player] = target
        tradeEvent:FireClient(target, "Prompt", player)
        
        task.delay(10, function()
            if pendingRequests[target] == player then
                pendingRequests[target] = nil
            end
            if outgoingRequests[player] == target then
                outgoingRequests[player] = nil
                tradeEvent:FireClient(player, "RequestExpired")
            end
        end)
        return true
    end
    
    return false, "range"
end
 
tradeEvent.OnServerEvent:Connect(function(player, action, data)
    if action == "AcceptRequest" then
        local requesterId = data
        local requester = Players:GetPlayerByUserId(requesterId)
        if not requester then return end
        if pendingRequests[player] ~= requester then return end
        if activeTraders[player] or activeTraders[requester] then return end
        
        pendingRequests[player] = nil
        outgoingRequests[requester] = nil
        
        tagAllTools(requester)
        tagAllTools(player)
        
        local session = {
        Player1 = requester,
        Player2 = player,
        P1Offer = {},
        P2Offer = {},
        P1Ready = false,
        P2Ready = false,
        TimerToken = 0
        }
        
        activeTraders[requester] = session
        activeTraders[player] = session
        
        tradeEvent:FireClient(requester, "StartSession", player)
        tradeEvent:FireClient(player, "StartSession", requester)
        
    elseif action == "DeclineRequest" then
        local requesterId = data
        local requester = Players:GetPlayerByUserId(requesterId)
        if not requester then return end
        if pendingRequests[player] == requester then
            pendingRequests[player] = nil
            if outgoingRequests[requester] == player then
                outgoingRequests[requester] = nil
                tradeEvent:FireClient(requester, "RequestDeclined", player)
            end
        end
        
    elseif action == "ToggleItem" then
        local session = getSession(player)
        if not session then return end
        
        local itemId = data
        if not itemId then return end
        
        local item = findToolByIdInPlayerContainers(player, itemId)
        if not item or not item:IsA("Tool") then return end
        
        local isP1 = (session.Player1 == player)
        local offer = isP1 and session.P1Offer or session.P2Offer
        local index = table.find(offer, itemId)
        
        if index then
            table.remove(offer, index)
        else
            table.insert(offer, itemId)
        end
        
        session.P1Ready = false
        session.P2Ready = false
        stopTimer(session)
        tradeEvent:FireClient(session.Player1, "UpdateStatus", false, false)
        tradeEvent:FireClient(session.Player2, "UpdateStatus", false, false)
        
        syncOffers(session)
        
    elseif action == "ToggleReady" then
        local session = getSession(player)
        if not session then return end
        
        if session.Player1 == player then
            session.P1Ready = not session.P1Ready
        else
            session.P2Ready = not session.P2Ready
        end
        
        tradeEvent:FireClient(session.Player1, "UpdateStatus", session.P1Ready, session.P2Ready)
        tradeEvent:FireClient(session.Player2, "UpdateStatus", session.P2Ready, session.P1Ready)
        
        if session.P1Ready and session.P2Ready then
            startTimer(session)
        else
            stopTimer(session)
        end
        
    elseif action == "Cancel" then
        local session = getSession(player)
        if session then cleanSession(session) end
        
        local outTarget = outgoingRequests[player]
        if outTarget then
            if pendingRequests[outTarget] == player then
                pendingRequests[outTarget] = nil
            end
            outgoingRequests[player] = nil
        end
        
        local inRequester = pendingRequests[player]
        if inRequester then
            outgoingRequests[inRequester] = nil
            pendingRequests[player] = nil
        end
    end
end)
 
Players.PlayerRemoving:Connect(function(player)
    playerCooldowns[player] = nil
    
    local outTarget = outgoingRequests[player]
    if outTarget then
        if pendingRequests[outTarget] == player then
            pendingRequests[outTarget] = nil
        end
        outgoingRequests[player] = nil
    end
    
    local inRequester = pendingRequests[player]
    if inRequester then
        outgoingRequests[inRequester] = nil
        pendingRequests[player] = nil
    end
    
    cleanSession(getSession(player))
end)
