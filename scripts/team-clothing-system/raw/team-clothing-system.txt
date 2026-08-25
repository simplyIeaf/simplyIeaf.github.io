-- made by @simplyIeaf1 on YouTube

local Players = game:GetService("Players")
local Teams = game:GetService("Teams")
local InsertService = game:GetService("InsertService")

local ClothesID = {
Red = {
Shirt = 7686009896,
Pants = 14764019035,
Color = "#FF0000"
},
Blue = {
Shirt = 6279631650,
Pants = 14764019035,
Color = "#0000FF"
}
-- Example: Green = {Shirt = 1234567, Pants = 7654321, Color = "#00FF00"}
}

local autoCreateTeams = true
local autoAssignRandomTeam = false

local function createTeams()
    for teamName, data in pairs(ClothesID) do
        if not Teams:FindFirstChild(teamName) then
            local team = Instance.new("Team")
            team.Name = teamName
            team.AutoAssignable = false
            team.Parent = Teams
            
            if data.Color then
                local success, color = pcall(function()
                    return Color3.fromHex(data.Color)
                end)
                if success then
                    team.TeamColor = BrickColor.new(color)
                end
            end
        end
    end
end

local function assignRandomTeam(player)
    local availableTeams = {}
    for teamName, data in pairs(ClothesID) do
        local team = Teams:FindFirstChild(teamName)
        if team then
            table.insert(availableTeams, team)
        end
    end
    
    if #availableTeams > 0 then
        local randomTeam = availableTeams[math.random(1, #availableTeams)]
        player.Team = randomTeam
    end
end

local function FetchFit(AssetId, Parent) 
    local Succ, Result = pcall(InsertService.LoadAsset, InsertService, AssetId)
    if not Succ then 
        return 
    end
    
    local Children = Result:GetChildren()
    if #Children > 0 then
        local Child = Children[1]
        Child.Parent = Parent
    end
    
    Result:Destroy()
end

local function TeamChanged(Player)
    local Character = Player.Character
    if not Character or not Player.Team then 
        return 
    end
    
    local Team = Player.Team.Name
    local ClothesData = ClothesID[Team]
    if not ClothesData then 
        return 
    end
    
    local Shirt = Character:FindFirstChildOfClass("Shirt")
    local Pants = Character:FindFirstChildOfClass("Pants")
    if Shirt then 
        Shirt:Destroy() 
    end
    if Pants then 
        Pants:Destroy() 
    end
    
    wait(0.1)
    
    if ClothesData.Shirt then
        FetchFit(ClothesData.Shirt, Character)
    end
    if ClothesData.Pants then
        FetchFit(ClothesData.Pants, Character)
    end
end

local function handlePlayer(player)
    if autoAssignRandomTeam and not player.Team then
        assignRandomTeam(player)
    end
    
    local function onCharacterAdded(character)
        local humanoid = character:WaitForChild("Humanoid", 10)
        if humanoid then
            wait(1)
            TeamChanged(player)
        end
    end
    
    player.CharacterAdded:connect(onCharacterAdded)
    
    player.Changed:connect(function(property)
        if property == "Team" then
            wait(0.5)
            TeamChanged(player)
        end
    end)
    
    if player.Character then
        onCharacterAdded(player.Character)
    end
end

if autoCreateTeams then
    createTeams()
end

Players.PlayerAdded:connect(handlePlayer)

local existingPlayers = Players:GetPlayers()
for i = 1, #existingPlayers do
    local player = existingPlayers[i]
    spawn(function()
        handlePlayer(player)
    end)
end