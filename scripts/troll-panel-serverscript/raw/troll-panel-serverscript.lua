local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local InsertService = game:GetService("InsertService")

local Whitelist = {
	8033814042
}

local JumpscareData = {
	["Glitch"] = {Image = "rbxthumb://type=Asset&id=12293699481&w=420&h=420", Sound = "rbxassetid://117969258532897"},
	["Markiplier"] = {Image = "rbxthumb://type=Asset&id=6079514529&w=420&h=420", Sound = "rbxassetid://118918477596951"},
	["Flamingo"] = {Image = "rbxthumb://type=Asset&id=6281423275&w=420&h=420", Sound = "rbxassetid://93087025399161"},
	["MrBeast"] = {Image = "rbxthumb://type=Asset&id=12179308494&w=420&h=420", Sound = "rbxassetid://104072406395555"},
	["Steak"] = {Image = "rbxthumb://type=Asset&id=17115969822&w=420&h=420", Sound = "rbxassetid://112548408006777"},
	["KreekCraft"] = {Image = "rbxthumb://type=Asset&id=12654811722&w=420&h=420", Sound = "rbxassetid://93087025399161"}
}

local AudioData = {
	["FAHHH"] = "rbxassetid://122236529083711",
	["GET OUT!"] = "rbxassetid://137793670040206",
	["what da dog doin"] = "rbxassetid://9078127694",
	["oh hell nah"] = "rbxassetid://3923569042",
	["door knock"] = "rbxassetid://366115240",
	["WOW Clap"] = "rbxassetid://139002442908771",
	["Cat Laughing"] = "rbxassetid://138402803334891",
	["Plankton Meme"] = "rbxassetid://138459150292660",
	["Siren"] = "rbxassetid://130818546670423"
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

local ActiveEffects = {}

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

local function registerEffect(userId, effectType, thread)
	if not ActiveEffects[userId] then ActiveEffects[userId] = {} end
	if ActiveEffects[userId][effectType] then
		task.cancel(ActiveEffects[userId][effectType])
	end
	ActiveEffects[userId][effectType] = thread
end

local function clearEffects(player)
	local userId = player.UserId
	if ActiveEffects[userId] then
		for _, thread in pairs(ActiveEffects[userId]) do
			task.cancel(thread)
		end
		ActiveEffects[userId] = {}
	end

	if player.Character then
		local hum = player.Character:FindFirstChild("Humanoid")
		local root = player.Character:FindFirstChild("HumanoidRootPart")
		if hum then
			hum.WalkSpeed = 16
			hum.JumpPower = 50
		end
		if root then
			root.Anchored = false
			for _, child in ipairs(root:GetChildren()) do
				if child:IsA("BodyVelocity") or child:IsA("BodyAngularVelocity") then
					child:Destroy()
				end
			end
		end
	end
	EffectEvent:FireClient(player, {Type = "Reset"})
end

local function spawnModel(target, modelId)
	if not target.Character or not target.Character:FindFirstChild("HumanoidRootPart") then return end
	local success, asset = pcall(function()
		return InsertService:LoadAsset(tonumber(modelId))
	end)
	if success and asset then
		for _, child in ipairs(asset:GetChildren()) do
			child.Parent = workspace
			if child:IsA("Model") then
				child:PivotTo(target.Character.HumanoidRootPart.CFrame * CFrame.new(5, 0, 0))
			elseif child:IsA("BasePart") then
				child.CFrame = target.Character.HumanoidRootPart.CFrame * CFrame.new(5, 0, 0)
			end
		end
		asset:Destroy()
	end
end

ActionRemote.OnServerInvoke = function(player, category, option, targetInput, extraInput, timeInput)
	if not isWhitelisted(player) then return false end
	local targets = getTargets(player, targetInput)
	if #targets == 0 then return false end

	local duration = tonumber(timeInput) or 0

	if category == "Reset" then
		for _, t in ipairs(targets) do
			clearEffects(t)
		end
		return true
	end

	local payload = {}

	if category == "Jumpscare" then
		local data = JumpscareData[option]
		if data then payload = {Type = "Jumpscare", Image = data.Image, Sound = data.Sound} end
	elseif category == "Audio" then
		local snd = AudioData[option]
		if snd then payload = {Type = "Audio", Sound = snd} end
	elseif category == "Fake Lag" then
		payload = {Type = "FakeLag", Duration = duration}
	elseif category == "Invert Controls" then
		payload = {Type = "InvertControls", Duration = duration}
	elseif category == "Flip Camera" then
		payload = {Type = "FlipCamera", Duration = duration}
	elseif category == "Anti-Jump" then
		payload = {Type = "AntiJump", Duration = duration}
	elseif category == "Night" then
		payload = {Type = "Night", Duration = duration}
	elseif category == "Fake Admin" then
		payload = {Type = "FakeAdmin", TargetName = targets[1].Name}
	elseif category == "Fling" then
		for _, t in ipairs(targets) do
			task.spawn(function()
				if t.Character and t.Character:FindFirstChild("HumanoidRootPart") then
					local vel = Instance.new("BodyVelocity")
					vel.Velocity = Vector3.new(math.random(-1000, 1000), 1000, math.random(-1000, 1000))
					vel.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
					vel.Parent = t.Character.HumanoidRootPart

					local ang = Instance.new("BodyAngularVelocity")
					ang.AngularVelocity = Vector3.new(100, 100, 100)
					ang.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
					ang.Parent = t.Character.HumanoidRootPart

					task.wait(1)
					vel:Destroy()
					ang:Destroy()
				end
			end)
		end
		return true
	elseif category == "Explode" then
		for _, t in ipairs(targets) do
			if t.Character and t.Character:FindFirstChild("HumanoidRootPart") then
				local exp = Instance.new("Explosion")
				exp.Position = t.Character.HumanoidRootPart.Position
				exp.Parent = t.Character.HumanoidRootPart
			end
		end
		return true
	elseif category == "Sword" then
		for _, t in ipairs(targets) do
			task.spawn(function()
				local s, m = pcall(function() return InsertService:LoadAsset(47433) end)
				if s and m then
					local tool = m:FindFirstChildOfClass("Tool")
					if tool then tool.Parent = t.Backpack end
					m:Destroy()
				end
			end)
		end
		return true
	elseif category == "Freeze" then
		for _, t in ipairs(targets) do
			local thread = task.spawn(function()
				if t.Character and t.Character:FindFirstChild("HumanoidRootPart") then
					t.Character.HumanoidRootPart.Anchored = true
					if duration > 0 then
						task.wait(duration)
						if t.Character and t.Character:FindFirstChild("HumanoidRootPart") then
							t.Character.HumanoidRootPart.Anchored = false
						end
					end
				end
			end)
			registerEffect(t.UserId, "Freeze", thread)
		end
		return true
	elseif category == "Clone" then
		local amount = tonumber(extraInput) or 1
		if amount > 20 then amount = 20 end
		for _, t in ipairs(targets) do
			if t.Character then
				t.Character.Archivable = true
				for i = 1, amount do
					local clone = t.Character:Clone()
					clone.Parent = workspace
					clone:PivotTo(t.Character.PrimaryPart.CFrame * CFrame.new(math.random(-5,5), 0, math.random(-5,5)))
				end
				t.Character.Archivable = false
			end
		end
		return true
	elseif category == "Speed" then
		local speedVal = tonumber(extraInput) or 16
		for _, t in ipairs(targets) do
			local thread = task.spawn(function()
				if t.Character and t.Character:FindFirstChild("Humanoid") then
					t.Character.Humanoid.WalkSpeed = speedVal
					if duration > 0 then
						task.wait(duration)
						if t.Character and t.Character:FindFirstChild("Humanoid") then
							t.Character.Humanoid.WalkSpeed = 16
						end
					end
				end
			end)
			registerEffect(t.UserId, "Speed", thread)
		end
		return true
	elseif category == "Morph" then
		local morphId = 0
		local success, err = pcall(function()
			morphId = Players:GetUserIdFromNameAsync(extraInput)
		end)
		if success and morphId > 0 then
			for _, t in ipairs(targets) do
				task.spawn(function()
					if t.Character and t.Character:FindFirstChild("Humanoid") then
						local desc = Players:GetHumanoidDescriptionFromUserId(morphId)
						t.Character.Humanoid:ApplyDescription(desc)
					end
				end)
			end
			return true
		end
		return false
	elseif category == "Model" then
		for _, t in ipairs(targets) do
			task.spawn(function() spawnModel(t, extraInput) end)
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