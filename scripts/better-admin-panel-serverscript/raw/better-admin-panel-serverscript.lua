local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")
local InsertService = game:GetService("InsertService")
local Lighting = game:GetService("Lighting")
local TextService = game:GetService("TextService")
local TeleportService = game:GetService("TeleportService")
local Teams = game:GetService("Teams")
local RunService = game:GetService("RunService")

local AdminFunction = ReplicatedStorage:FindFirstChild("AdminFunction") or Instance.new("RemoteFunction")
AdminFunction.Name = "AdminFunction"
AdminFunction.Parent = ReplicatedStorage

local AdminEvent = ReplicatedStorage:FindFirstChild("AdminEvent") or Instance.new("RemoteEvent")
AdminEvent.Name = "AdminEvent"
AdminEvent.Parent = ReplicatedStorage

local PREFIX = "/"
local ADMINS = {
	[12345678] = true,
}

local dayNightCycleRunning = false
local loopKillers = {}

local function isAdmin(player)
	return ADMINS[player.UserId] or player.UserId == game.CreatorId or false
end

local function getTargets(caller, targetString)
	local targets = {}
	if not targetString then return targets end
	local lowerTarget = string.lower(targetString)
	if lowerTarget == "all" then
		return Players:GetPlayers()
	elseif lowerTarget == "others" then
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= caller then table.insert(targets, p) end
		end
	elseif lowerTarget == "me" then
		table.insert(targets, caller)
	else
		for _, p in ipairs(Players:GetPlayers()) do
			if string.find(string.lower(p.Name), lowerTarget) == 1 or string.find(string.lower(p.DisplayName), lowerTarget) == 1 then
				table.insert(targets, p)
			end
		end
	end
	return targets
end

local function getCharPart(target, partName)
	if target.Character then
		return target.Character:FindFirstChild(partName)
	end
	return nil
end

local function scaleChar(target, scaleType, value)
	local hum = getCharPart(target, "Humanoid")
	if hum and hum:FindFirstChild(scaleType) then
		hum[scaleType].Value = value
	end
end

local function hexToColor3(hex)
	hex = hex:gsub("#", "")
	local r = tonumber("0x" .. hex:sub(1, 2)) or 255
	local g = tonumber("0x" .. hex:sub(3, 4)) or 255
	local b = tonumber("0x" .. hex:sub(5, 6)) or 255
	return Color3.fromRGB(r, g, b)
end

local Commands = {
	mute = {Category = "Chat", Usage = "mute <player>", Execute = function(caller, args)
		for _, target in ipairs(getTargets(caller, args[1])) do
			for _, d in ipairs(TextChatService:GetDescendants()) do
				if d:IsA("TextSource") and d.UserId == target.UserId then d.CanSend = false end
			end
		end
	end},
	unmute = {Category = "Chat", Usage = "unmute <player>", Execute = function(caller, args)
		for _, target in ipairs(getTargets(caller, args[1])) do
			for _, d in ipairs(TextChatService:GetDescendants()) do
				if d:IsA("TextSource") and d.UserId == target.UserId then d.CanSend = true end
			end
		end
	end},
	fly = {Category = "Movement", Usage = "fly <player> (speed)", Execute = function(caller, args)
		local speed = tonumber(args[2]) or 50
		for _, target in ipairs(getTargets(caller, args[1])) do
			AdminEvent:FireClient(target, "Fly", true, speed)
		end
	end},
	unfly = {Category = "Movement", Usage = "unfly <player>", Execute = function(caller, args)
		for _, target in ipairs(getTargets(caller, args[1])) do
			AdminEvent:FireClient(target, "Fly", false)
		end
	end},
	speed = {Category = "Movement", Usage = "speed <player> <amount>", Execute = function(caller, args)
		local spd = tonumber(args[2]) or 16
		for _, target in ipairs(getTargets(caller, args[1])) do
			local hum = getCharPart(target, "Humanoid")
			if hum then hum.WalkSpeed = spd end
		end
	end},
	walkspeed = {Category = "Movement", Usage = "walkspeed <player> <amount>", Execute = function(caller, args)
		local spd = tonumber(args[2]) or 16
		for _, target in ipairs(getTargets(caller, args[1])) do
			local hum = getCharPart(target, "Humanoid")
			if hum then hum.WalkSpeed = spd end
		end
	end},
	unspeed = {Category = "Movement", Usage = "unspeed <player>", Execute = function(caller, args)
		for _, target in ipairs(getTargets(caller, args[1])) do
			local hum = getCharPart(target, "Humanoid")
			if hum then hum.WalkSpeed = 16 end
		end
	end},
	jumppower = {Category = "Movement", Usage = "jumppower <player> <amount>", Execute = function(caller, args)
		local pwr = tonumber(args[2]) or 50
		for _, target in ipairs(getTargets(caller, args[1])) do
			local hum = getCharPart(target, "Humanoid")
			if hum then hum.UseJumpPower = true; hum.JumpPower = pwr end
		end
	end},
	antijump = {Category = "Movement", Usage = "antijump <player>", Execute = function(caller, args)
		for _, target in ipairs(getTargets(caller, args[1])) do
			local hum = getCharPart(target, "Humanoid")
			if hum then hum.UseJumpPower = true; hum.JumpPower = 0; hum.JumpHeight = 0 end
		end
	end},
	unantijump = {Category = "Movement", Usage = "unantijump <player>", Execute = function(caller, args)
		for _, target in ipairs(getTargets(caller, args[1])) do
			local hum = getCharPart(target, "Humanoid")
			if hum then hum.UseJumpPower = true; hum.JumpPower = 50; hum.JumpHeight = 7.2 end
		end
	end},
	freeze = {Category = "Player", Usage = "freeze <player>", Execute = function(caller, args)
		for _, target in ipairs(getTargets(caller, args[1])) do
			local hrp = getCharPart(target, "HumanoidRootPart")
			if hrp then hrp.Anchored = true end
		end
	end},
	unfreeze = {Category = "Player", Usage = "unfreeze <player>", Execute = function(caller, args)
		for _, target in ipairs(getTargets(caller, args[1])) do
			local hrp = getCharPart(target, "HumanoidRootPart")
			if hrp then hrp.Anchored = false end
		end
	end},
	sit = {Category = "Player", Usage = "sit <player>", Execute = function(caller, args)
		for _, target in ipairs(getTargets(caller, args[1])) do
			local hum = getCharPart(target, "Humanoid")
			if hum then hum.Sit = true end
		end
	end},
	jump = {Category = "Player", Usage = "jump <player>", Execute = function(caller, args)
		for _, target in ipairs(getTargets(caller, args[1])) do
			local hum = getCharPart(target, "Humanoid")
			if hum then hum.Jump = true end
		end
	end},
	bring = {Category = "Teleport", Usage = "bring <player>", Execute = function(caller, args)
		local callerHrp = getCharPart(caller, "HumanoidRootPart")
		if not callerHrp then return end
		for _, target in ipairs(getTargets(caller, args[1])) do
			local targetHrp = getCharPart(target, "HumanoidRootPart")
			if targetHrp then targetHrp.CFrame = callerHrp.CFrame * CFrame.new(0, 0, -5) end
		end
	end},
	to = {Category = "Teleport", Usage = "to <player>", Execute = function(caller, args)
		local targets = getTargets(caller, args[1])
		if #targets > 0 then
			local targetHrp = getCharPart(targets[1], "HumanoidRootPart")
			local callerHrp = getCharPart(caller, "HumanoidRootPart")
			if targetHrp and callerHrp then callerHrp.CFrame = targetHrp.CFrame * CFrame.new(0, 0, 3) end
		end
	end},
	kill = {Category = "Combat", Usage = "kill <player>", Execute = function(caller, args)
		for _, target in ipairs(getTargets(caller, args[1])) do
			local hum = getCharPart(target, "Humanoid")
			if hum then hum.Health = 0 end
		end
	end},
	explode = {Category = "Combat", Usage = "explode <player>", Execute = function(caller, args)
		for _, target in ipairs(getTargets(caller, args[1])) do
			local hrp = getCharPart(target, "HumanoidRootPart")
			if hrp then
				local exp = Instance.new("Explosion")
				exp.Position = hrp.Position
				exp.Parent = workspace
			end
		end
	end},
	damage = {Category = "Combat", Usage = "damage <player> <amount>", Execute = function(caller, args)
		local dmg = tonumber(args[2]) or 20
		for _, target in ipairs(getTargets(caller, args[1])) do
			local hum = getCharPart(target, "Humanoid")
			if hum then hum.Health = math.clamp(hum.Health - dmg, 0, hum.MaxHealth) end
		end
	end},
	heal = {Category = "Combat", Usage = "heal <player>", Execute = function(caller, args)
		for _, target in ipairs(getTargets(caller, args[1])) do
			local hum = getCharPart(target, "Humanoid")
			if hum then hum.Health = hum.MaxHealth end
		end
	end},
	god = {Category = "Combat", Usage = "god <player>", Execute = function(caller, args)
		for _, target in ipairs(getTargets(caller, args[1])) do
			local hum = getCharPart(target, "Humanoid")
			if hum then hum.MaxHealth = math.huge; hum.Health = math.huge end
		end
	end},
	ungod = {Category = "Combat", Usage = "ungod <player>", Execute = function(caller, args)
		for _, target in ipairs(getTargets(caller, args[1])) do
			local hum = getCharPart(target, "Humanoid")
			if hum then hum.MaxHealth = 100; hum.Health = 100 end
		end
	end},
	ff = {Category = "Combat", Usage = "ff <player>", Execute = function(caller, args)
		for _, target in ipairs(getTargets(caller, args[1])) do
			if target.Character then Instance.new("ForceField", target.Character) end
		end
	end},
	unff = {Category = "Combat", Usage = "unff <player>", Execute = function(caller, args)
		for _, target in ipairs(getTargets(caller, args[1])) do
			if target.Character then
				for _, v in ipairs(target.Character:GetChildren()) do
					if v:IsA("ForceField") then v:Destroy() end
				end
			end
		end
	end},
	sword = {Category = "Combat", Usage = "sword <player>", Execute = function(caller, args)
		for _, target in ipairs(getTargets(caller, args[1])) do
			local success, model = pcall(function() return InsertService:LoadAsset(47433) end)
			if success and model then
				local tool = model:FindFirstChildWhichIsA("Tool")
				if tool then tool.Parent = target.Backpack end
			end
		end
	end},
	unsword = {Category = "Combat", Usage = "unsword <player>", Execute = function(caller, args)
		for _, target in ipairs(getTargets(caller, args[1])) do
			if target.Character then
				for _, v in ipairs(target.Character:GetChildren()) do if v.Name == "LinkedSword" then v:Destroy() end end
			end
			for _, v in ipairs(target.Backpack:GetChildren()) do if v.Name == "LinkedSword" then v:Destroy() end end
		end
	end},
	removetools = {Category = "Player", Usage = "removetools <player>", Execute = function(caller, args)
		for _, target in ipairs(getTargets(caller, args[1])) do
			target.Backpack:ClearAllChildren()
			if target.Character then
				for _, v in ipairs(target.Character:GetChildren()) do
					if v:IsA("Tool") then v:Destroy() end
				end
			end
		end
	end},
	re = {Category = "Player", Usage = "re <player>", Execute = function(caller, args)
		for _, target in ipairs(getTargets(caller, args[1])) do
			target:LoadCharacter()
		end
	end},
	fat = {Category = "Appearance", Usage = "fat <player>", Execute = function(caller, args)
		for _, target in ipairs(getTargets(caller, args[1])) do
			scaleChar(target, "BodyWidthScale", 2)
			scaleChar(target, "BodyDepthScale", 2)
		end
	end},
	unfat = {Category = "Appearance", Usage = "unfat <player>", Execute = function(caller, args)
		for _, target in ipairs(getTargets(caller, args[1])) do
			scaleChar(target, "BodyWidthScale", 1)
			scaleChar(target, "BodyDepthScale", 1)
		end
	end},
	thin = {Category = "Appearance", Usage = "thin <player>", Execute = function(caller, args)
		for _, target in ipairs(getTargets(caller, args[1])) do
			scaleChar(target, "BodyWidthScale", 0.5)
			scaleChar(target, "BodyDepthScale", 0.5)
		end
	end},
	unthin = {Category = "Appearance", Usage = "unthin <player>", Execute = function(caller, args)
		for _, target in ipairs(getTargets(caller, args[1])) do
			scaleChar(target, "BodyWidthScale", 1)
			scaleChar(target, "BodyDepthScale", 1)
		end
	end},
	giant = {Category = "Appearance", Usage = "giant <player>", Execute = function(caller, args)
		for _, target in ipairs(getTargets(caller, args[1])) do
			scaleChar(target, "BodyWidthScale", 3)
			scaleChar(target, "BodyDepthScale", 3)
			scaleChar(target, "BodyHeightScale", 3)
			scaleChar(target, "HeadScale", 3)
		end
	end},
	ungiant = {Category = "Appearance", Usage = "ungiant <player>", Execute = function(caller, args)
		for _, target in ipairs(getTargets(caller, args[1])) do
			scaleChar(target, "BodyWidthScale", 1)
			scaleChar(target, "BodyDepthScale", 1)
			scaleChar(target, "BodyHeightScale", 1)
			scaleChar(target, "HeadScale", 1)
		end
	end},
	bighead = {Category = "Appearance", Usage = "bighead <player>", Execute = function(caller, args)
		for _, target in ipairs(getTargets(caller, args[1])) do scaleChar(target, "HeadScale", 3) end
	end},
	unbighead = {Category = "Appearance", Usage = "unbighead <player>", Execute = function(caller, args)
		for _, target in ipairs(getTargets(caller, args[1])) do scaleChar(target, "HeadScale", 1) end
	end},
	smallhead = {Category = "Appearance", Usage = "smallhead <player>", Execute = function(caller, args)
		for _, target in ipairs(getTargets(caller, args[1])) do scaleChar(target, "HeadScale", 0.5) end
	end},
	unsmallhead = {Category = "Appearance", Usage = "unsmallhead <player>", Execute = function(caller, args)
		for _, target in ipairs(getTargets(caller, args[1])) do scaleChar(target, "HeadScale", 1) end
	end},
	blockhead = {Category = "Appearance", Usage = "blockhead <player>", Execute = function(caller, args)
		for _, target in ipairs(getTargets(caller, args[1])) do
			local head = getCharPart(target, "Head")
			if head and head:FindFirstChildOfClass("SpecialMesh") then
				head:FindFirstChildOfClass("SpecialMesh").MeshType = Enum.MeshType.Brick
			end
		end
	end},
	nolimbs = {Category = "Appearance", Usage = "nolimbs <player>", Execute = function(caller, args)
		for _, target in ipairs(getTargets(caller, args[1])) do
			if target.Character then
				local limbs = {"Left Arm", "Right Arm", "Left Leg", "Right Leg", "LeftHand", "RightHand", "LeftLowerArm", "RightLowerArm", "LeftUpperArm", "RightUpperArm", "LeftFoot", "RightFoot", "LeftLowerLeg", "RightLowerLeg", "LeftUpperLeg", "RightUpperLeg"}
				for _, partName in ipairs(limbs) do
					local p = target.Character:FindFirstChild(partName)
					if p then p:Destroy() end
				end
			end
		end
	end},
	morph = {Category = "Appearance", Usage = "morph <player> <targetuser>", Execute = function(caller, args)
		local morphTarget = getTargets(caller, args[2])[1]
		if not morphTarget then return end
		local desc = Players:GetHumanoidDescriptionFromUserId(morphTarget.UserId)
		for _, target in ipairs(getTargets(caller, args[1])) do
			local hum = getCharPart(target, "Humanoid")
			if hum then hum:ApplyDescription(desc) end
		end
	end},
	clone = {Category = "Player", Usage = "clone <player>", Execute = function(caller, args)
		for _, target in ipairs(getTargets(caller, args[1])) do
			if target.Character then
				target.Character.Archivable = true
				local c = target.Character:Clone()
				c.Parent = workspace
			end
		end
	end},
	smoke = {Category = "Appearance", Usage = "smoke <player>", Execute = function(caller, args)
		for _, target in ipairs(getTargets(caller, args[1])) do
			local hrp = getCharPart(target, "HumanoidRootPart")
			if hrp then Instance.new("Smoke", hrp) end
		end
	end},
	unsmoke = {Category = "Appearance", Usage = "unsmoke <player>", Execute = function(caller, args)
		for _, target in ipairs(getTargets(caller, args[1])) do
			local hrp = getCharPart(target, "HumanoidRootPart")
			if hrp then
				for _, v in ipairs(hrp:GetChildren()) do if v:IsA("Smoke") then v:Destroy() end end
			end
		end
	end},
	fling = {Category = "Troll", Usage = "fling <player>", Execute = function(caller, args)
		for _, target in ipairs(getTargets(caller, args[1])) do
			local hrp = getCharPart(target, "HumanoidRootPart")
			if hrp then
				local bv = Instance.new("BodyVelocity")
				bv.Velocity = Vector3.new(math.huge, math.huge, math.huge)
				bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
				bv.Parent = hrp
				task.delay(0.1, function() bv:Destroy() end)
			end
		end
	end},
	spin = {Category = "Troll", Usage = "spin <player> <amount>", Execute = function(caller, args)
		local spd = tonumber(args[2]) or 50
		for _, target in ipairs(getTargets(caller, args[1])) do
			local hrp = getCharPart(target, "HumanoidRootPart")
			if hrp then
				local bg = hrp:FindFirstChild("SpinForce") or Instance.new("BodyAngularVelocity")
				bg.Name = "SpinForce"
				bg.AngularVelocity = Vector3.new(0, spd, 0)
				bg.MaxTorque = Vector3.new(0, math.huge, 0)
				bg.Parent = hrp
			end
		end
	end},
	blur = {Category = "Troll", Usage = "blur <player>", Execute = function(caller, args)
		for _, target in ipairs(getTargets(caller, args[1])) do AdminEvent:FireClient(target, "Blur", true) end
	end},
	unblur = {Category = "Troll", Usage = "unblur <player>", Execute = function(caller, args)
		for _, target in ipairs(getTargets(caller, args[1])) do AdminEvent:FireClient(target, "Blur", false) end
	end},
	crash = {Category = "Troll", Usage = "crash <player>", Execute = function(caller, args)
		for _, target in ipairs(getTargets(caller, args[1])) do AdminEvent:FireClient(target, "Crash") end
	end},
	setfps = {Category = "Troll", Usage = "setfps <player> <amount>", Execute = function(caller, args)
		local fps = tonumber(args[2]) or 30
		for _, target in ipairs(getTargets(caller, args[1])) do AdminEvent:FireClient(target, "SetFPS", fps) end
	end},
	spectate = {Category = "Utility", Usage = "spectate <player>", Execute = function(caller, args)
		local target = getTargets(caller, args[1])[1]
		if target then AdminEvent:FireClient(caller, "Spectate", target) end
	end},
	unspectate = {Category = "Utility", Usage = "unspectate", Execute = function(caller, args)
		AdminEvent:FireClient(caller, "Spectate", nil)
	end},
	rejoin = {Category = "Utility", Usage = "rejoin <player>", Execute = function(caller, args)
		for _, target in ipairs(getTargets(caller, args[1])) do AdminEvent:FireClient(target, "Rejoin") end
	end},
	day = {Category = "Server", Usage = "day", Execute = function(caller, args)
		dayNightCycleRunning = false
		Lighting.ClockTime = 14
	end},
	night = {Category = "Server", Usage = "night", Execute = function(caller, args)
		dayNightCycleRunning = false
		Lighting.ClockTime = 0
	end},
	daynightcycle = {Category = "Server", Usage = "daynightcycle", Execute = function(caller, args)
		if dayNightCycleRunning then return end
		dayNightCycleRunning = true
		task.spawn(function()
			while dayNightCycleRunning do
				Lighting.ClockTime = Lighting.ClockTime + 0.01
				task.wait(0.1)
			end
		end)
	end},
	undaynightcycle = {Category = "Server", Usage = "undaynightcycle", Execute = function(caller, args)
		dayNightCycleRunning = false
	end},
	destroyguis = {Category = "Utility", Usage = "destroyguis <player>", Execute = function(caller, args)
		for _, target in ipairs(getTargets(caller, args[1])) do AdminEvent:FireClient(target, "DestroyGuis") end
	end},
	m = {Category = "Chat", Usage = "m <message>", Execute = function(caller, args)
		local msg = table.concat(args, " ")
		local success, result = pcall(function()
			return TextService:FilterStringAsync(msg, caller.UserId):GetNonChatStringForBroadcastAsync()
		end)
		local finalMsg = success and result or msg
		for _, p in ipairs(Players:GetPlayers()) do
			AdminEvent:FireClient(p, "Message", finalMsg, caller.Name)
		end
	end},
	flipcamera = {Category = "Troll", Usage = "flipcamera <player>", Execute = function(caller, args)
		for _, target in ipairs(getTargets(caller, args[1])) do AdminEvent:FireClient(target, "FlipCamera", true) end
	end},
	unflipcamera = {Category = "Troll", Usage = "unflipcamera <player>", Execute = function(caller, args)
		for _, target in ipairs(getTargets(caller, args[1])) do AdminEvent:FireClient(target, "FlipCamera", false) end
	end},
	invertcontrols = {Category = "Troll", Usage = "invertcontrols <player>", Execute = function(caller, args)
		for _, target in ipairs(getTargets(caller, args[1])) do AdminEvent:FireClient(target, "InvertControls", true) end
	end},
	uninvertcontrols = {Category = "Troll", Usage = "uninvertcontrols <player>", Execute = function(caller, args)
		for _, target in ipairs(getTargets(caller, args[1])) do AdminEvent:FireClient(target, "InvertControls", false) end
	end},
	jumpscare = {Category = "Troll", Usage = "jumpscare <player> <soundid> <imageid>", Execute = function(caller, args)
		local snd = args[2] or "168137470"
		local img = args[3] or "14905298664"
		for _, target in ipairs(getTargets(caller, args[1])) do AdminEvent:FireClient(target, "Jumpscare", snd, img) end
	end},
	audioplayer = {Category = "Utility", Usage = "audioplayer <audioid>", Execute = function(caller, args)
		local snd = args[1]
		if snd then AdminEvent:FireClient(caller, "AudioPlayer", snd) end
	end},
	music = {Category = "Server", Usage = "music <musicid>", Execute = function(caller, args)
		local snd = args[1]
		if snd then
			for _, p in ipairs(Players:GetPlayers()) do AdminEvent:FireClient(p, "Music", snd) end
		end
	end},
	unmusic = {Category = "Server", Usage = "unmusic", Execute = function(caller, args)
		for _, p in ipairs(Players:GetPlayers()) do AdminEvent:FireClient(p, "Music", nil) end
	end},
	wallclimb = {Category = "Movement", Usage = "wallclimb <player>", Execute = function(caller, args)
		for _, target in ipairs(getTargets(caller, args[1])) do AdminEvent:FireClient(target, "WallClimb", true) end
	end},
	unwallclimb = {Category = "Movement", Usage = "unwallclimb <player>", Execute = function(caller, args)
		for _, target in ipairs(getTargets(caller, args[1])) do AdminEvent:FireClient(target, "WallClimb", false) end
	end},
	kick = {Category = "Server", Usage = "kick <player> <reason>", Execute = function(caller, args)
		local targets = getTargets(caller, args[1])
		table.remove(args, 1)
		local reason = table.concat(args, " ")
		for _, target in ipairs(targets) do target:Kick(reason) end
	end},
	restart = {Category = "Server", Usage = "restart", Execute = function(caller, args)
		local code = TeleportService:ReserveServer(game.PlaceId)
		TeleportService:TeleportToPrivateServer(game.PlaceId, code, Players:GetPlayers())
	end},
	f3x = {Category = "Utility", Usage = "f3x <player>", Execute = function(caller, args)
		for _, target in ipairs(getTargets(caller, args[1] or "me")) do
			local success, model = pcall(function() return InsertService:LoadAsset(7950417918) end)
			if success and model then
				local tool = model:FindFirstChildWhichIsA("Tool") or model:GetChildren()[1]
				if tool then tool.Parent = target.Backpack end
			end
		end
	end},
	btools = {Category = "Utility", Usage = "btools <player>", Execute = function(caller, args)
		Commands.f3x.Execute(caller, args)
	end},
	model = {Category = "Utility", Usage = "model <player> <id>", Execute = function(caller, args)
		local id = tonumber(args[2])
		if not id then return end
		for _, target in ipairs(getTargets(caller, args[1])) do
			local success, model = pcall(function() return InsertService:LoadAsset(id) end)
			if success and model then
				model.Parent = workspace
				if target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
					model:MoveTo(target.Character.HumanoidRootPart.Position)
				end
			end
		end
	end},
	fire = {Category = "Appearance", Usage = "fire <player>", Execute = function(caller, args)
		for _, target in ipairs(getTargets(caller, args[1])) do
			local hrp = getCharPart(target, "HumanoidRootPart")
			if hrp then Instance.new("Fire", hrp) end
		end
	end},
	unfire = {Category = "Appearance", Usage = "unfire <player>", Execute = function(caller, args)
		for _, target in ipairs(getTargets(caller, args[1])) do
			local hrp = getCharPart(target, "HumanoidRootPart")
			if hrp then
				for _, v in ipairs(hrp:GetChildren()) do if v:IsA("Fire") then v:Destroy() end end
			end
		end
	end},
	invisible = {Category = "Appearance", Usage = "invisible <player>", Execute = function(caller, args)
		for _, target in ipairs(getTargets(caller, args[1])) do
			if target.Character then
				for _, v in ipairs(target.Character:GetDescendants()) do
					if v:IsA("BasePart") or v:IsA("Decal") then v.Transparency = 1 end
				end
			end
		end
	end},
	visible = {Category = "Appearance", Usage = "visible <player>", Execute = function(caller, args)
		for _, target in ipairs(getTargets(caller, args[1])) do
			if target.Character then
				for _, v in ipairs(target.Character:GetDescendants()) do
					if v:IsA("BasePart") and v.Name ~= "HumanoidRootPart" then v.Transparency = 0 end
					if v:IsA("Decal") then v.Transparency = 0 end
				end
			end
		end
	end},
	time = {Category = "Server", Usage = "time <amount>", Execute = function(caller, args)
		local t = tonumber(args[1])
		if t then Lighting.ClockTime = t end
	end},
	shutdown = {Category = "Server", Usage = "shutdown", Execute = function(caller, args)
		for _, p in ipairs(Players:GetPlayers()) do p:Kick("Server got shutdown") end
	end},
	fog = {Category = "Server", Usage = "fog", Execute = function(caller, args)
		Lighting.FogEnd = 100
	end},
	unfog = {Category = "Server", Usage = "unfog", Execute = function(caller, args)
		Lighting.FogEnd = 100000
	end},
	createteam = {Category = "Server", Usage = "createteam <name> <#color>", Execute = function(caller, args)
		local colorHex = args[#args]
		table.remove(args, #args)
		local name = table.concat(args, " ")
		local team = Instance.new("Team", Teams)
		team.Name = name
		team.TeamColor = BrickColor.new(hexToColor3(colorHex))
	end},
	deleteteam = {Category = "Server", Usage = "deleteteam <name>", Execute = function(caller, args)
		local name = table.concat(args, " ")
		for _, team in ipairs(Teams:GetChildren()) do
			if string.lower(team.Name) == string.lower(name) then team:Destroy() end
		end
	end},
	loopkill = {Category = "Combat", Usage = "loopkill <player>", Execute = function(caller, args)
		for _, target in ipairs(getTargets(caller, args[1])) do loopKillers[target.UserId] = true end
	end},
	unloopkill = {Category = "Combat", Usage = "unloopkill <player>", Execute = function(caller, args)
		for _, target in ipairs(getTargets(caller, args[1])) do loopKillers[target.UserId] = nil end
	end},
	brightness = {Category = "Server", Usage = "brightness <amount>", Execute = function(caller, args)
		local b = tonumber(args[1])
		if b then Lighting.Brightness = b end
	end},
	unbrightness = {Category = "Server", Usage = "unbrightness", Execute = function(caller, args)
		Lighting.Brightness = 2
	end},
	platformstand = {Category = "Movement", Usage = "platformstand <player>", Execute = function(caller, args)
		for _, target in ipairs(getTargets(caller, args[1])) do
			local hum = getCharPart(target, "Humanoid")
			if hum then hum.PlatformStand = true end
		end
	end},
	unplatformstand = {Category = "Movement", Usage = "unplatformstand <player>", Execute = function(caller, args)
		for _, target in ipairs(getTargets(caller, args[1])) do
			local hum = getCharPart(target, "Humanoid")
			if hum then hum.PlatformStand = false end
		end
	end},
	zombie = {Category = "Utility", Usage = "zombie <player>", Execute = function(caller, args)
		for _, target in ipairs(getTargets(caller, args[1])) do
			local success, model = pcall(function() return InsertService:LoadAsset(3924238625) end)
			if success and model then
				model.Parent = workspace
				if target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
					model:MoveTo(target.Character.HumanoidRootPart.Position + Vector3.new(3, 0, 0))
				end
			end
		end
	end},
	changestat = {Category = "Server", Usage = "changestat <player> <stat> <value>", Execute = function(caller, args)
		local value = tonumber(args[3]) or args[3]
		local statName = string.lower(args[2])
		for _, target in ipairs(getTargets(caller, args[1])) do
			local leaderstats = target:FindFirstChild("leaderstats")
			if leaderstats then
				for _, stat in ipairs(leaderstats:GetChildren()) do
					if string.lower(stat.Name) == statName then stat.Value = value end
				end
			end
		end
	end},
	fakeadmin = {Category = "Troll", Usage = "fakeadmin <player>", Execute = function(caller, args)
		for _, target in ipairs(getTargets(caller, args[1])) do
			AdminEvent:FireClient(target, "FakeAdmin", PREFIX)
		end
	end},
	createsystemmessage = {Category = "Utility", Usage = "createsystemmessage <player> <message>", Execute = function(caller, args)
		local targets = getTargets(caller, args[1])
		table.remove(args, 1)
		local msg = table.concat(args, " ")
		for _, target in ipairs(targets) do AdminEvent:FireClient(target, "SystemMessage", msg) end
	end},
	copytools = {Category = "Player", Usage = "copytools <fromplayer> <toplayer>", Execute = function(caller, args)
		local fromTarget = getTargets(caller, args[1])[1]
		local toTargets = getTargets(caller, args[2])
		if fromTarget and #toTargets > 0 then
			for _, item in ipairs(fromTarget.Backpack:GetChildren()) do
				if item:IsA("Tool") then
					for _, target in ipairs(toTargets) do
						item:Clone().Parent = target.Backpack
					end
				end
			end
		end
	end},
	cuttools = {Category = "Player", Usage = "cuttools <fromplayer> <toplayer>", Execute = function(caller, args)
		local fromTarget = getTargets(caller, args[1])[1]
		local toTargets = getTargets(caller, args[2])
		if fromTarget and #toTargets > 0 then
			for _, item in ipairs(fromTarget.Backpack:GetChildren()) do
				if item:IsA("Tool") then
					for _, target in ipairs(toTargets) do item:Clone().Parent = target.Backpack end
					item:Destroy()
				end
			end
			if fromTarget.Character then
				for _, item in ipairs(fromTarget.Character:GetChildren()) do
					if item:IsA("Tool") then
						for _, target in ipairs(toTargets) do item:Clone().Parent = target.Backpack end
						item:Destroy()
					end
				end
			end
		end
	end},
	tool = {Category = "Utility", Usage = "tool <player> <id>", Execute = function(caller, args)
		local id = tonumber(args[2])
		if not id then return end
		for _, target in ipairs(getTargets(caller, args[1])) do
			local success, model = pcall(function() return InsertService:LoadAsset(id) end)
			if success and model then
				for _, item in ipairs(model:GetChildren()) do
					if item:IsA("Tool") then item.Parent = target.Backpack end
				end
			end
		end
	end},
	script = {Category = "Server", Usage = "script <script>", Execute = function(caller, args)
		local code = table.concat(args, " ")
		local func, err = loadstring(code)
		if func then
			pcall(func)
		else
			warn("Script error:", err)
		end
	end},
	localscript = {Category = "Utility", Usage = "localscript <player> <script>", Execute = function(caller, args)
		local targets = getTargets(caller, args[1])
		table.remove(args, 1)
		local code = table.concat(args, " ")
		for _, target in ipairs(targets) do AdminEvent:FireClient(target, "RunScript", code) end
	end},
}

RunService.Heartbeat:Connect(function()
	for userId, _ in pairs(loopKillers) do
		local p = Players:GetPlayerByUserId(userId)
		if p then
			local hum = getCharPart(p, "Humanoid")
			if hum then hum.Health = 0 end
		end
	end
end)

local function handleExecute(player, inputString)
	if not inputString or inputString == "" then return false, "No command provided." end
	local args = string.split(inputString, " ")
	local cmdName = string.lower(table.remove(args, 1))
	if Commands[cmdName] then
		local success, err = pcall(function()
			Commands[cmdName].Execute(player, args)
		end)
		if success then
			return true, "Executed " .. cmdName
		else
			warn("Command Error:", err)
			return false, "Error executing command."
		end
	elseif cmdName == "cmds" then
		AdminEvent:FireClient(player, "Cmds")
		return true, "Opened commands"
	else
		return false, "Unknown command."
	end
end

AdminFunction.OnServerInvoke = function(player, action, inputString)
	if not isAdmin(player) then return false, "Not authorized." end
	if action == "GetCommands" then
		local cmdList = {}
		for name, data in pairs(Commands) do
			table.insert(cmdList, {Name = name, Usage = data.Usage, Category = data.Category or "Misc"})
		end
		return true, cmdList
	elseif action == "Execute" then
		return handleExecute(player, inputString)
	end
end

Players.PlayerAdded:Connect(function(player)
	player.Chatted:Connect(function(msg)
		if string.sub(msg, 1, string.len(PREFIX)) == PREFIX then
			local cmdString = string.sub(msg, string.len(PREFIX) + 1)
			if isAdmin(player) then
				handleExecute(player, cmdString)
			else
				local split = string.split(cmdString, " ")
				if string.lower(split[1]) == "cmds" then
					AdminEvent:FireClient(player, "Cmds")
				else
					AdminEvent:FireClient(player, "SystemMessage", "You do not have permission to use this command")
				end
			end
		end
	end)
end)