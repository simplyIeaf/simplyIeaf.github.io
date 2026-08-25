-- made by @simplyIeaf1 on youtube

local MapThumbnails = {
-- Example: ["DesertArena"] = "rbxthumb://type=Asset&id=9876543210&w=420&h=420",
}

local VOTING_TIME = 10
local ROUND_TIME = 420
local CLEANUP_DELAY = 3
local NO_VOTES_RANDOM_ATTEMPTS = 3
local TELEPORT_TO_MAP_PART = "TeleportToMap"
local TELEPORT_BACK_PART = "SpawnTeleport"

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")

local remotesFolder = Instance.new("Folder")
remotesFolder.Name = "MapVotingRemotes"
remotesFolder.Parent = ReplicatedStorage

local startVotingRemote = Instance.new("RemoteEvent")
startVotingRemote.Name = "StartVoting"
startVotingRemote.Parent = remotesFolder

local voteMapRemote = Instance.new("RemoteEvent")
voteMapRemote.Name = "VoteMap"
voteMapRemote.Parent = remotesFolder

local updateVotesRemote = Instance.new("RemoteEvent")
updateVotesRemote.Name = "UpdateVotes"
updateVotesRemote.Parent = remotesFolder

local endVotingRemote = Instance.new("RemoteEvent")
endVotingRemote.Name = "EndVoting"
endVotingRemote.Parent = remotesFolder

local allMaps = {}
local currentMaps = {}
local playerVotes = {}
local voteCounts = {}
local currentMapModel = nil
local isVoting = false
local isRoundRunning = false
local isMapLoaded = false
local isCleaning = false
local playerDebounce = {}
 
local scriptEnabled = true
 
local function initializeMapLoading()
    local mapsFolder = ServerStorage:FindFirstChild("Maps")
    if not mapsFolder then
        warn("Maps folder missing in ServerStorage!")
        return false
    end
    allMaps = mapsFolder:GetChildren()
    if #allMaps == 0 then
        warn("No maps found in ServerStorage.Maps!")
        return false
    end
    
    local teleportPart = workspace:FindFirstChild(TELEPORT_TO_MAP_PART)
    if not teleportPart then
        warn("No " .. TELEPORT_TO_MAP_PART .. " part found in Workspace!")
        return false
    end
    
    local touchConnection
    touchConnection = teleportPart.Touched:Connect(function(hit)
        if not scriptEnabled then return end
        
        local humanoid = hit.Parent:FindFirstChild("Humanoid")
        if not humanoid or humanoid.Health <= 0 then
            return
        end
        
        local player = Players:GetPlayerFromCharacter(hit.Parent)
        if not player or playerDebounce[player] or not currentMapModel or not isMapLoaded then
            return
        end
        
        playerDebounce[player] = true
        
        local success, err = pcall(function()
            local spawns = {}
            local spawn1 = currentMapModel:FindFirstChild("Spawn1")
            local spawn2 = currentMapModel:FindFirstChild("Spawn2")
            if spawn1 and spawn1:IsA("BasePart") then
                table.insert(spawns, spawn1)
            end
            if spawn2 and spawn2:IsA("BasePart") then
                table.insert(spawns, spawn2)
            end
            
            if #spawns > 0 then
                local randomSpawn = spawns[math.random(1, #spawns)]
                local char = player.Character
                if char and char:FindFirstChild("HumanoidRootPart") then
                    char.HumanoidRootPart.CFrame = randomSpawn.CFrame + Vector3.new(0, 3, 0)
                end
            else
                warn("Current map missing Spawn1 and/or Spawn2!")
            end
        end)
        
        if not success then
            warn("Teleport error:", err)
        end
        
        task.wait(1)
        playerDebounce[player] = nil
    end)
    
    return true
end

local function getRandomMaps()
    local maps = {}
    local availableMaps = {table.unpack(allMaps)}
    
    if #availableMaps <= 3 then
        maps = availableMaps
    else
        for i = #availableMaps, 2, -1 do
            local j = math.random(1, i)
            availableMaps[i], availableMaps[j] = availableMaps[j], availableMaps[i]
        end
        for i = 1, 3 do
            table.insert(maps, availableMaps[i])
        end
    end
    
    return maps
end

local function getMapData(mapModel)
    if not mapModel then
        warn("getMapData received nil mapModel!")
        return {name = "Unknown", thumbnail = "rbxthumb://type=Asset&id=0&w=420&h=420"}
    end
    local name = mapModel.Name
    local thumbnail = MapThumbnails[name] or "rbxthumb://type=Asset&id=0&w=420&h=420"
    local thumbValue = mapModel:FindFirstChild("Thumbnail")
    if thumbValue and thumbValue:IsA("StringValue") then
        thumbnail = thumbValue.Value
    end
    return {name = name, thumbnail = thumbnail}
end

local function cleanupRound()
    if isCleaning then
        print("Cleanup already in progress, waiting...")
        while isCleaning do
            task.wait(0.1)
        end
        return
    end
    
    isCleaning = true
    isRoundRunning = false
    isMapLoaded = false
    
    print("Starting cleanup...")
    
    local success, err = pcall(function()
        if currentMapModel then
            currentMapModel:Destroy()
            currentMapModel = nil
            print("Destroyed current map model")
        end
        
        local spawnTeleport = workspace:FindFirstChild(TELEPORT_BACK_PART)
        if not spawnTeleport then
            warn("No " .. TELEPORT_BACK_PART .. " part found in Workspace!")
        else
            for _, player in ipairs(Players:GetPlayers()) do
                if player.Character and player.Character:FindFirstChild("HumanoidRootPart") and 
                    player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 then
                    player.Character.HumanoidRootPart.CFrame = spawnTeleport.CFrame + Vector3.new(math.random(-5,5), 5, math.random(-5,5))
                end
            end
            print("Players teleported back to spawn")
        end
        
        currentMaps = {}
        playerVotes = {}
        voteCounts = {}
        print("Cleared voting state")
    end)
    
    if not success then
        warn("Cleanup error:", err)
    end
    
    task.wait(CLEANUP_DELAY)
    isCleaning = false
    print("Cleanup completed")
end

local function loadSelectedMap(mapModel)
    if not mapModel then
        warn("loadSelectedMap received nil mapModel!")
        task.wait(CLEANUP_DELAY)
        if scriptEnabled then
            handleVoting()
        end
        return
    end
    
    print("=== Loading Map:", mapModel.Name, "===")
    
    local success, err = pcall(function()
        cleanupRound()
        
        currentMapModel = mapModel:Clone()
        currentMapModel.Name = "CurrentMap"
        currentMapModel.Parent = workspace
        
        local spawns = {}
        local spawn1 = currentMapModel:FindFirstChild("Spawn1")
        local spawn2 = currentMapModel:FindFirstChild("Spawn2")
        if spawn1 and spawn1:IsA("BasePart") then
            table.insert(spawns, spawn1)
        end
        if spawn2 and spawn2:IsA("BasePart") then
            table.insert(spawns, spawn2)
        end
        if #spawns == 0 then
            warn("Map '" .. mapModel.Name .. "' missing Spawn1 and Spawn2!")
        end
        
        for _, obj in ipairs(currentMapModel:GetDescendants()) do
            if obj:IsA("BasePart") then
                obj.Transparency = math.min(obj.Transparency, 0)
            elseif obj:IsA("Decal") or obj:IsA("Texture") then
                obj.Transparency = math.min(obj.Transparency, 0)
            end
        end
        
        for _, player in ipairs(Players:GetPlayers()) do
            if player.Character and player.Character:FindFirstChild("HumanoidRootPart") and 
                player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 then
                if #spawns > 0 then
                    local randomSpawn = spawns[math.random(1, #spawns)]
                    player.Character.HumanoidRootPart.CFrame = randomSpawn.CFrame + Vector3.new(0, 3, 0)
                else
                    local spawnTeleport = workspace:FindFirstChild(TELEPORT_BACK_PART)
                    if spawnTeleport and spawnTeleport:IsA("BasePart") then
                        player.Character.HumanoidRootPart.CFrame = spawnTeleport.CFrame + Vector3.new(math.random(-5,5), 5, math.random(-5,5))
                    end
                end
            end
        end
        print("Players teleported to map spawns")
        
        isMapLoaded = true
        isRoundRunning = true
        print("Map loaded successfully, round started for", ROUND_TIME, "seconds")
        
        task.wait(ROUND_TIME)
        
        print("Round completed")
        isRoundRunning = false
        isMapLoaded = false
    end)
    
    if not success then
        warn("loadSelectedMap failed:", err)
        if currentMapModel then
            pcall(function()
                currentMapModel:Destroy()
                currentMapModel = nil
            end)
        end
        isMapLoaded = false
        isRoundRunning = false
        isCleaning = false
    end
    
    cleanupRound()
    
    if scriptEnabled then
        print("Starting next voting round...")
        task.wait(2)
        handleVoting()
    end
end

function handleVoting()
    if not scriptEnabled then
        print("Script disabled, stopping voting")
        return
    end
    
    if isVoting or isCleaning then
        print("Cannot start voting: isVoting =", isVoting, "isCleaning =", isCleaning)
        task.wait(2)
        if scriptEnabled then
            handleVoting()
        end
        return
    end
    
    print("=== Starting New Voting Round ===")
    
    isVoting = true
    playerVotes = {}
    voteCounts = {0, 0, 0}
    currentMaps = getRandomMaps()
    
    if #currentMaps == 0 then
        warn("No maps available for voting!")
        isVoting = false
        task.wait(CLEANUP_DELAY)
        if scriptEnabled then
            handleVoting()
        end
        return
    end
    
    local mapDataList = {}
    for i, map in ipairs(currentMaps) do
        table.insert(mapDataList, getMapData(map))
    end
    
    print("Broadcasting voting with maps:")
    for i, data in ipairs(mapDataList) do
        print(i, data.name)
    end
    
    startVotingRemote:FireAllClients(mapDataList)
    
    local voteConnection
    voteConnection = voteMapRemote.OnServerEvent:Connect(function(player, mapIndex)
        if not isVoting then
            print("Vote ignored from", player.Name, "- voting not active")
            return
        end
        if not mapIndex or mapIndex < 1 or mapIndex > 3 or mapIndex > #currentMaps then
            print("Invalid mapIndex from", player.Name, ":", mapIndex)
            return
        end
        
        if playerVotes[player] ~= mapIndex then
            local oldIndex = playerVotes[player]
            if oldIndex then
                voteCounts[oldIndex] = math.max(0, voteCounts[oldIndex] - 1)
            end
            playerVotes[player] = mapIndex
            voteCounts[mapIndex] = voteCounts[mapIndex] + 1
            
            print("Vote from", player.Name, "for map", mapIndex, "- Counts:", voteCounts)
            updateVotesRemote:FireAllClients(voteCounts)
        end
    end)
    
    print("Voting for", VOTING_TIME, "seconds...")
    task.wait(VOTING_TIME)
    
    voteConnection:Disconnect()
    isVoting = false
    
    print("=== Voting Ended ===")
    print("Final vote counts:", voteCounts)
    
    local maxVotes = 0
    local winners = {}
    for i = 1, math.min(3, #currentMaps) do
        local votes = voteCounts[i]
        if votes > maxVotes then
            maxVotes = votes
            winners = {i}
        elseif votes == maxVotes then
            table.insert(winners, i)
        end
    end
    
    local winnerIndex
    if maxVotes == 0 then
        winnerIndex = math.random(1, math.min(3, #currentMaps))
        print("No votes received - randomly selected map", winnerIndex)
    else
        winnerIndex = winners[math.random(1, #winners)]
        print("Winner selected: map", winnerIndex, "with", maxVotes, "votes")
    end
    
    local winnerMap = currentMaps[winnerIndex]
    if not winnerMap then
        warn("Winner map is nil for index:", winnerIndex)
        task.wait(CLEANUP_DELAY)
        if scriptEnabled then
            handleVoting()
        end
        return
    end
    
    print("Selected map:", winnerMap.Name)
    
endVotingRemote:FireAllClients()
task.wait(2)

print("Loading selected map:", winnerMap.Name)
task.spawn(function()
    local success, err = pcall(loadSelectedMap, winnerMap)
    if not success then
        warn("Failed to load selected map:", err)
        local fallbackMap = allMaps[math.random(1, #allMaps)]
        if fallbackMap and scriptEnabled then
            print("Trying fallback map:", fallbackMap.Name)
            pcall(loadSelectedMap, fallbackMap)
        else
            warn("No fallback map available!")
            if scriptEnabled then
                task.wait(CLEANUP_DELAY)
                handleVoting()
            end
        end
    end
end)
end

Players.PlayerRemoving:Connect(function(player)
    playerDebounce[player] = nil
    if playerVotes[player] and isVoting then
        local votedIndex = playerVotes[player]
        voteCounts[votedIndex] = math.max(0, voteCounts[votedIndex] - 1)
        playerVotes[player] = nil
        updateVotesRemote:FireAllClients(voteCounts)
        print("Player", player.Name, "left - removed their vote for map", votedIndex)
    end
end)
 
game:BindToClose(function()
    print("Server shutting down - disabling map voting script")
    scriptEnabled = false
end)
 
print("=== Map Voting System Starting ===")
if initializeMapLoading() then
    print("Initialization successful")
    task.spawn(function()
        task.wait(3)
        if scriptEnabled then
            handleVoting()
        end
    end)
else
    warn("=== Initialization failed - Map Voting System disabled ===")
end