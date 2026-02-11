local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local InsertService = game:GetService("InsertService")
 
local Whitelist = {
8033814042
}
 
local JumpscareData = {
["Glitch"] = {Image = "rbxthumb://type=Asset&id=12293699481&w=420&h=420", Sound = "rbxassetid://117969258532897"},
["Markiplier"] = {Image = "rbxthumb://type=Asset&id=6079514529&w=420&h=420", Sound = "rbxassetid://118918477596951"},
["Flamingo"] = {Image = "rbxthumb://type=Asset&id=6281423275&w=420&h=420", Sound = "rbxassetid://93087025399161"}
}
 
local AudioData = {
["FAHHH"] = "rbxassetid://122236529083711",
["GET OUT!"] = "rbxassetid://137793670040206",
["what da dog doin"] = "rbxassetid://9078127694",
["oh hell nah"] = "rbxassetid://3923569042",
["door knock"] = "rbxassetid://366115240"
}
 
local RemotesFolder = ReplicatedStorage:FindFirstChild("TrollRemotes") or Instance.new("Folder")
RemotesFolder.Name = "TrollRemotes"
RemotesFolder.Parent = ReplicatedStorage
 
local ActionRemote = RemotesFolder:FindFirstChild("ActionRemote") or Instance.new("RemoteFunction")
ActionRemote.Name = "ActionRemote"
ActionRemote.Parent = RemotesFolder
 
local GetAssetsRemote = RemotesFolder:FindFirstChild("GetAssetsRemote") or Instance.new("RemoteFunction")
GetAssetsRemote.Name = "GetAssetsRemote"
GetAssetsRemote.Parent = RemotesFolder
 
local EffectEvent = RemotesFolder:FindFirstChild("EffectEvent") or Instance.new("RemoteEvent")
EffectEvent.Name = "EffectEvent"
EffectEvent.Parent = RemotesFolder
 
local function isWhitelisted(player)
	for _, id in ipairs(Whitelist) do
		if player.UserId == id then
			return true
		end
	end
	return false
end
 
local function getTargets(executor, input)
	local targets = {}
	local inputLower = input:lower()
	if inputLower == "all" then
		targets = Players:GetPlayers()
	elseif inputLower == "others" then
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= executor then table.insert(targets, p) end
		end
	elseif inputLower == "me" then
		table.insert(targets, executor)
	else
		for _, p in ipairs(Players:GetPlayers()) do
			if p.Name:lower():sub(1, #inputLower) == inputLower or p.DisplayName:lower():sub(1, #inputLower) == inputLower then
				table.insert(targets, p)
				break 
			end
		end
	end
	return targets
end
 
local function flingPlayer(target)
	local character = target.Character
	if not character then return end
	
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	local humanoid = character:FindFirstChild("Humanoid")
	if not humanoidRootPart or not humanoid then return end
	
	local bodyVelocity = Instance.new("BodyVelocity")
	bodyVelocity.Velocity = Vector3.new(math.random(-100, 100), 200, math.random(-100, 100))
	bodyVelocity.MaxForce = Vector3.new(4000, 4000, 4000)
	bodyVelocity.Parent = humanoidRootPart
	
	task.wait(0.5)
	bodyVelocity:Destroy()
end
 
local function giveItem(target, assetId)
	local character = target.Character
	if not character then return end
	
	local success, model = pcall(function()
		return InsertService:LoadAsset(assetId)
	end)
	
	if not success or not model then return end
	
	local tool = model:FindFirstChildOfClass("Tool")
	if tool then
		tool.Parent = target.Backpack
		model:Destroy()
	else
		model:Destroy()
	end
end
 
ActionRemote.OnServerInvoke = function(player, category, option, targetInput)
	if not isWhitelisted(player) then return false end
	local targets = getTargets(player, targetInput)
	if #targets == 0 then return false end
	
	local payload = {}
	
	if category == "Jumpscare" then
		local data = JumpscareData[option]
		if data then payload = {Type = "Jumpscare", Image = data.Image, Sound = data.Sound} end
	elseif category == "Audio" then
		local snd = AudioData[option]
		if snd then payload = {Type = "Audio", Sound = snd} end
	elseif category == "Fake Lag" then
		payload = {Type = "FakeLag"}
	elseif category == "Invert Controls" then
		payload = {Type = "InvertControls"}
	elseif category == "Flip Camera" then
		payload = {Type = "FlipCamera"}
	elseif category == "Anti-Jump" then
		payload = {Type = "AntiJump"}
	elseif category == "Night" then
		payload = {Type = "Night"}
	elseif category == "Fling" then
		for _, t in ipairs(targets) do
			task.spawn(function()
				flingPlayer(t)
			end)
		end
		return true
	elseif category == "Sword" then
		for _, t in ipairs(targets) do
			task.spawn(function()
				giveItem(t, 47433)
			end)
		end
		return true
	end
	
	if payload.Type then
		for _, t in ipairs(targets) do
			EffectEvent:FireClient(t, payload)
		end
		return true
	end
	
	return false
end
 
GetAssetsRemote.OnServerInvoke = function(player)
	if not isWhitelisted(player) then return nil end
	return {
	Jumpscare = JumpscareData,
	Audio = AudioData
	}
end