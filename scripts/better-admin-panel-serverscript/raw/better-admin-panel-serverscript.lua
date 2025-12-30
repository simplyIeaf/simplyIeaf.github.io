local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local ServerStorage = game:GetService("ServerStorage")
local Debris = game:GetService("Debris")
local TeleportService = game:GetService("TeleportService")

local RemoteName = "AdminPanelRemote"
local Remote = ReplicatedStorage:FindFirstChild(RemoteName) or Instance.new("RemoteEvent")
Remote.Name = RemoteName
Remote.Parent = ReplicatedStorage

local AdminUsernames = {"YourUsernameHere","AnotherAdminUser"}

local function IsAdmin(player)
	for _, adminName in pairs(AdminUsernames) do
		if player.Name:lower() == adminName:lower() then return true end
	end
	return false
end

local function GetPlayer(String, Speaker)
	if not String then return nil end
	if String == "me" then return {Speaker} end
	if String == "all" then return Players:GetPlayers() end
	if String == "others" then
		local p = {}
		for _, v in pairs(Players:GetPlayers()) do
			if v ~= Speaker then table.insert(p, v) end
		end
		return p
	end
	if String == "random" then
		local plrs = Players:GetPlayers()
		return {plrs[math.random(1, #plrs)]}
	end
	if String == "admins" then
		local p = {}
		for _, v in pairs(Players:GetPlayers()) do
			if IsAdmin(v) then table.insert(p, v) end
		end
		return p
	end
	if String == "nonadmins" then
		local p = {}
		for _, v in pairs(Players:GetPlayers()) do
			if not IsAdmin(v) then table.insert(p, v) end
		end
		return p
	end
	if String == "friends" and Speaker then
		local p = {}
		for _, v in pairs(Players:GetPlayers()) do
			if v ~= Speaker and v:IsFriendsWith(Speaker.UserId) then table.insert(p, v) end
		end
		return p
	end
	for _, v in pairs(Players:GetPlayers()) do
		if v.Name:lower():sub(1, #String) == String:lower() or v.DisplayName:lower():sub(1, #String) == String:lower() then
			return {v}
		end
	end
	return nil
end

local Commands = {}

Commands.kill = function(p) if p.Character then p.Character:BreakJoints() end end
Commands.kick = function(p) p:Kick("Admin removed you.") end
Commands.ban = function(p) p.Character:BreakJoints() task.wait(0.5) p:Kick("Banned.") end
Commands.mute = function(p) local t = Instance.new("BoolValue") t.Name = "Muted" t.Parent = p end
Commands.unmute = function(p) if p:FindFirstChild("Muted") then p.Muted:Destroy() end end
Commands.freeze = function(p) if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then p.Character.HumanoidRootPart.Anchored = true end end
Commands.thaw = function(p) if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then p.Character.HumanoidRootPart.Anchored = false end end
Commands.unfreeze = Commands.thaw
Commands.jail = function(p)
	if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
		local cf = p.Character.HumanoidRootPart.CFrame
		local m = Instance.new("Model", workspace) m.Name = "Jail_"..p.Name
		for i=1,4 do
			local w = Instance.new("Part", m) w.Size = Vector3.new(6,10,1) w.Anchored = true w.Transparency = 0.5
			w.CFrame = cf * CFrame.Angles(0, math.rad(i*90), 0) * CFrame.new(0,0,3)
		end
		local t = Instance.new("Part", m) t.Size = Vector3.new(6,1,6) t.Anchored = true t.Transparency = 0.5 t.CFrame = cf * CFrame.new(0,5,0)
		local b = t:Clone() b.Parent = m b.CFrame = cf * CFrame.new(0,-4,0)
		p.Character.HumanoidRootPart.CFrame = cf
	end
end
Commands.unjail = function(p) if workspace:FindFirstChild("Jail_"..p.Name) then workspace["Jail_"..p.Name]:Destroy() end end
Commands.respawn = function(p) p:LoadCharacter() end
Commands.refresh = function(p) local cf = p.Character and p.Character:GetPivot() p:LoadCharacter() if cf and p.Character then p.Character:PivotTo(cf) end end
Commands.rejoin = function(p) TeleportService:Teleport(game.PlaceId, p) end
Commands.god = function(p) if p.Character and p.Character:FindFirstChild("Humanoid") then p.Character.Humanoid.MaxHealth = math.huge p.Character.Humanoid.Health = math.huge end end
Commands.ungod = function(p) if p.Character and p.Character:FindFirstChild("Humanoid") then p.Character.Humanoid.MaxHealth = 100 p.Character.Humanoid.Health = 100 end end
Commands.heal = function(p) if p.Character and p.Character:FindFirstChild("Humanoid") then p.Character.Humanoid.Health = p.Character.Humanoid.MaxHealth end end
Commands.damage = function(p, a) if p.Character and p.Character:FindFirstChild("Humanoid") then p.Character.Humanoid:TakeDamage(tonumber(a[2]) or 10) end end
Commands.ff = function(p) if p.Character then Instance.new("ForceField", p.Character) end end
Commands.unff = function(p) if p.Character then for _,v in pairs(p.Character:GetChildren()) do if v:IsA("ForceField") then v:Destroy() end end end end
Commands.speed = function(p, a) if p.Character and p.Character:FindFirstChild("Humanoid") then p.Character.Humanoid.WalkSpeed = tonumber(a[2]) or 32 end end
Commands.unspeed = function(p) if p.Character and p.Character:FindFirstChild("Humanoid") then p.Character.Humanoid.WalkSpeed = 16 end end
Commands.ws = Commands.speed
Commands.unws = Commands.unspeed
Commands.jump = function(p, a) if p.Character and p.Character:FindFirstChild("Humanoid") then p.Character.Humanoid.JumpPower = tonumber(a[2]) or 100 end end
Commands.unjump = function(p) if p.Character and p.Character:FindFirstChild("Humanoid") then p.Character.Humanoid.JumpPower = 50 end end
Commands.jp = Commands.jump
Commands.unjp = Commands.unjump
Commands.fly = function(p)
	if p.Character and p.Character:FindFirstChild("Humanoid") then
		local bg = Instance.new("BodyGyro", p.Character.HumanoidRootPart)
		local bv = Instance.new("BodyVelocity", p.Character.HumanoidRootPart)
		bg.MaxTorque = Vector3.new(9e9,9e9,9e9) bv.MaxForce = Vector3.new(9e9,9e9,9e9) bg.CFrame = p.Character.HumanoidRootPart.CFrame
		local ft = Instance.new("BoolValue") ft.Name = "Flying" ft.Parent = p
		p.Character.Humanoid.PlatformStand = true
	end
end
Commands.unfly = function(p)
	if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
		for _, v in pairs(p.Character.HumanoidRootPart:GetChildren()) do if v:IsA("BodyGyro") or v:IsA("BodyVelocity") then v:Destroy() end end
		if p:FindFirstChild("Flying") then p.Flying:Destroy() end
		p.Character.Humanoid.PlatformStand = false
	end
end
Commands.noclip = function(p)
	if p.Character then
		for _, v in pairs(p.Character:GetDescendants()) do if v:IsA("BasePart") and v.CanCollide then v.CanCollide = false end end
		local t = Instance.new("BoolValue") t.Name = "Noclip" t.Parent = p
	end
end
Commands.unnoclip = function(p)
	if p.Character then
		for _, v in pairs(p.Character:GetDescendants()) do if v:IsA("BasePart") then v.CanCollide = true end end
		if p:FindFirstChild("Noclip") then p.Noclip:Destroy() end
	end
end
Commands.sit = function(p) if p.Character and p.Character:FindFirstChild("Humanoid") then p.Character.Humanoid.Sit = true end end
Commands.unsit = function(p) if p.Character and p.Character:FindFirstChild("Humanoid") then p.Character.Humanoid.Sit = false end end
Commands.stun = function(p) if p.Character and p.Character:FindFirstChild("Humanoid") then p.Character.Humanoid.PlatformStand = true end end
Commands.unstun = function(p) if p.Character and p.Character:FindFirstChild("Humanoid") then p.Character.Humanoid.PlatformStand = false end end
Commands.tp = function(p, a, s) if p.Character and s.Character then p.Character:PivotTo(s.Character:GetPivot()) end end
Commands.to = function(p, a, s) if p.Character and s.Character then s.Character:PivotTo(p.Character:GetPivot()) end end
Commands.bring = Commands.tp
Commands.teleport = Commands.tp
Commands.tppos = function(p, a) if p.Character then p.Character:PivotTo(CFrame.new(tonumber(a[2]) or 0, tonumber(a[3]) or 50, tonumber(a[4]) or 0)) end end
Commands.invisible = function(p) if p.Character then for _,v in pairs(p.Character:GetDescendants()) do if v:IsA("BasePart") or v:IsA("Decal") then v.Transparency = 1 end end end end
Commands.visible = function(p) if p.Character then for _,v in pairs(p.Character:GetDescendants()) do if v:IsA("BasePart") then v.Transparency = 0 if v:IsA("Decal") then v.Transparency = 0 end end end end end
Commands.uninvisible = Commands.visible
Commands.ghost = function(p) if p.Character then for _,v in pairs(p.Character:GetDescendants()) do if v:IsA("BasePart") or v:IsA("Decal") then v.Transparency = 0.5 end end end end
Commands.unghost = function(p) if p.Character then for _,v in pairs(p.Character:GetDescendants()) do if v:IsA("BasePart") then v.Transparency = 0 end end end end
Commands.lock = function(p) if p.Character then for _,v in pairs(p.Character:GetDescendants()) do if v:IsA("BasePart") then v.Locked = true end end end end
Commands.unlock = function(p) if p.Character then for _,v in pairs(p.Character:GetDescendants()) do if v:IsA("BasePart") then v.Locked = false end end end end
Commands.btools = function(p)
	local a = Instance.new("HopperBin", p.Backpack) a.BinType = "Hammer"
	local b = Instance.new("HopperBin", p.Backpack) b.BinType = "Clone"
	local c = Instance.new("HopperBin", p.Backpack) c.BinType = "Grab"
end
Commands.unbtools = function(p) for _,v in pairs(p.Backpack:GetChildren()) do if v:IsA("HopperBin") then v:Destroy() end end end
Commands.sword = function(p) local s = Instance.new("Tool", p.Backpack) s.Name = "IronSword" local h = Instance.new("Part", s) h.Name = "Handle" h.Size = Vector3.new(1,4,1) end
Commands.unsword = function(p) for _,v in pairs(p.Backpack:GetChildren()) do if v.Name == "IronSword" then v:Destroy() end end end
Commands.gun = function(p) local t = Instance.new("Tool", p.Backpack) t.Name = "AdminGun" local h = Instance.new("Part", t) h.Name = "Handle" h.Size = Vector3.new(1,1,3) h.BrickColor = BrickColor.new("Black") end
Commands.ungun = function(p) for _,v in pairs(p.Backpack:GetChildren()) do if v.Name == "AdminGun" then v:Destroy() end end end
Commands.explode = function(p) if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then local e = Instance.new("Explosion", workspace) e.Position = p.Character.HumanoidRootPart.Position end end
Commands.fart = function(p) if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then local s = Instance.new("Sound", p.Character.HumanoidRootPart) s.SoundId = "rbxassetid://109729458" s:Play() Debris:AddItem(s,3) end end
Commands.fire = function(p) if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then Instance.new("Fire", p.Character.HumanoidRootPart) end end
Commands.unfire = function(p) if p.Character then for _,v in pairs(p.Character:GetDescendants()) do if v:IsA("Fire") then v:Destroy() end end end end
Commands.smoke = function(p) if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then Instance.new("Smoke", p.Character.HumanoidRootPart) end end
Commands.unsmoke = Commands.unfire
Commands.sparkles = function(p) if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then Instance.new("Sparkles", p.Character.HumanoidRootPart) end end
Commands.unsparkles = function(p) if p.Character then for _,v in pairs(p.Character:GetDescendants()) do if v:IsA("Sparkles") then v:Destroy() end end end end
Commands.box = function(p) if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then local b = Instance.new("Part", workspace) b.Size = Vector3.new(5,5,5) b.CFrame = p.Character.HumanoidRootPart.CFrame b.Anchored = true b.Transparency = 0.5 b.BrickColor = BrickColor.Random() b.Name = "AdminBox" end end
Commands.unbox = function(p) for _,v in pairs(workspace:GetChildren()) do if v.Name == "AdminBox" then v:Destroy() end end end
Commands.bighead = function(p) if p.Character and p.Character:FindFirstChild("Humanoid") then p.Character.Humanoid.HeadScale.Value = 3 end end
Commands.unbighead = function(p) if p.Character and p.Character:FindFirstChild("Humanoid") then p.Character.Humanoid.HeadScale.Value = 1 end end
Commands.smallhead = function(p) if p.Character and p.Character:FindFirstChild("Humanoid") then p.Character.Humanoid.HeadScale.Value = 0.5 end end
Commands.unsmallhead = Commands.unbighead
Commands.giant = function(p)
	if p.Character and p.Character:FindFirstChild("Humanoid") then
		local h = p.Character.Humanoid
		h.BodyDepthScale.Value = 4 h.BodyHeightScale.Value = 4 h.BodyWidthScale.Value = 4 h.HeadScale.Value = 4
	end
end
Commands.ungiant = function(p)
	if p.Character and p.Character:FindFirstChild("Humanoid") then
		local h = p.Character.Humanoid
		h.BodyDepthScale.Value = 1 h.BodyHeightScale.Value = 1 h.BodyWidthScale.Value = 1 h.HeadScale.Value = 1
	end
end
Commands.tiny = function(p)
	if p.Character and p.Character:FindFirstChild("Humanoid") then
		local h = p.Character.Humanoid
		h.BodyDepthScale.Value = 0.5 h.BodyHeightScale.Value = 0.5 h.BodyWidthScale.Value = 0.5 h.HeadScale.Value = 0.5
	end
end
Commands.untiny = Commands.ungiant
Commands.fat = function(p) if p.Character and p.Character:FindFirstChild("Humanoid") then p.Character.Humanoid.BodyWidthScale.Value = 3 p.Character.Humanoid.BodyDepthScale.Value = 3 end end
Commands.unfat = function(p) if p.Character and p.Character:FindFirstChild("Humanoid") then p.Character.Humanoid.BodyWidthScale.Value = 1 p.Character.Humanoid.BodyDepthScale.Value = 1 end end
Commands.skinny = function(p) if p.Character and p.Character:FindFirstChild("Humanoid") then p.Character.Humanoid.BodyWidthScale.Value = 0.5 p.Character.Humanoid.BodyDepthScale.Value = 0.5 end end
Commands.unskinny = Commands.unfat
Commands.tall = function(p) if p.Character and p.Character:FindFirstChild("Humanoid") then p.Character.Humanoid.BodyHeightScale.Value = 2 end end
Commands.untall = function(p) if p.Character and p.Character:FindFirstChild("Humanoid") then p.Character.Humanoid.BodyHeightScale.Value = 1 end end
Commands.short = function(p) if p.Character and p.Character:FindFirstChild("Humanoid") then p.Character.Humanoid.BodyHeightScale.Value = 0.5 end end
Commands.unshort = Commands.untall
Commands.noarms = function(p) if p.Character then if p.Character:FindFirstChild("Left Arm") then p.Character["Left Arm"]:Destroy() end if p.Character:FindFirstChild("Right Arm") then p.Character["Right Arm"]:Destroy() end end end
Commands.unnoarms = Commands.respawn
Commands.nolegs = function(p) if p.Character then if p.Character:FindFirstChild("Left Leg") then p.Character["Left Leg"]:Destroy() end if p.Character:FindFirstChild("Right Leg") then p.Character["Right Leg"]:Destroy() end end end
Commands.unnolegs = Commands.respawn
Commands.nohead = function(p) if p.Character and p.Character:FindFirstChild("Head") then p.Character.Head:Destroy() end end
Commands.unnohead = Commands.respawn
Commands.neon = function(p) if p.Character then for _,v in pairs(p.Character:GetChildren()) do if v:IsA("BasePart") then v.Material = Enum.Material.Neon end end end end
Commands.unneon = function(p) if p.Character then for _,v in pairs(p.Character:GetChildren()) do if v:IsA("BasePart") then v.Material = Enum.Material.Plastic end end end end
Commands.shiny = function(p) if p.Character then for _,v in pairs(p.Character:GetChildren()) do if v:IsA("BasePart") then v.Reflectance = 1 end end end end
Commands.unshiny = function(p) if p.Character then for _,v in pairs(p.Character:GetChildren()) do if v:IsA("BasePart") then v.Reflectance = 0 end end end end
Commands.glass = function(p) if p.Character then for _,v in pairs(p.Character:GetChildren()) do if v:IsA("BasePart") then v.Material = Enum.Material.Glass end end end end
Commands.unglass = Commands.unneon
Commands.gold = function(p) if p.Character then for _,v in pairs(p.Character:GetChildren()) do if v:IsA("BasePart") then v.Material = Enum.Material.Metal v.Color = Color3.fromRGB(255,215,0) end end end end
Commands.ungold = Commands.respawn
Commands.ice = function(p) if p.Character then for _,v in pairs(p.Character:GetChildren()) do if v:IsA("BasePart") then v.Material = Enum.Material.Ice v.Color = Color3.fromRGB(150,255,255) end end end end
Commands.unice = Commands.respawn
Commands.char = function(p, a) if p.Character then p.CharacterAppearanceId = tonumber(a[2]) or p.UserId p:LoadCharacter() end end
Commands.unchar = function(p) p.CharacterAppearanceId = p.UserId p:LoadCharacter() end
Commands.creeper = function(p)
	if p.Character then
		p.Character.HumanoidRootPart.Transparency = 1
		for _,v in pairs(p.Character:GetChildren()) do
			if v:IsA("Accessory") then v:Destroy() end
			if v:IsA("BasePart") then v.BrickColor = BrickColor.new("Bright green") v.Material = "Grass" end
		end
	end
end
Commands.uncreeper = Commands.respawn
Commands.name = function(p, a) if p.Character and p.Character:FindFirstChild("Humanoid") then p.Character.Humanoid.DisplayName = a[2] or "Admin" end end
Commands.unname = function(p) if p.Character and p.Character:FindFirstChild("Humanoid") then p.Character.Humanoid.DisplayName = p.Name end end
Commands.displayname = Commands.name
Commands.undisplayname = Commands.unname
Commands.fling = function(p) if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then local v = Instance.new("BodyVelocity", p.Character.HumanoidRootPart) v.Velocity = Vector3.new(2000,2000,2000) v.MaxForce = Vector3.new(math.huge,math.huge,math.huge) Debris:AddItem(v,0.5) end end
Commands.spin = function(p) if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then local v = Instance.new("BodyAngularVelocity", p.Character.HumanoidRootPart) v.AngularVelocity = Vector3.new(0,50,0) v.MaxForce = Vector3.new(0,math.huge,0) v.Name = "AdminSpin" end end
Commands.unspin = function(p) if p.Character and p.Character:FindFirstChild("HumanoidRootPart") and p.Character.HumanoidRootPart:FindFirstChild("AdminSpin") then p.Character.HumanoidRootPart.AdminSpin:Destroy() end end
Commands.seizure = function(p)
	if p.Character then
		p.Character.Humanoid.PlatformStand = true
		local v = Instance.new("BodyAngularVelocity", p.Character.HumanoidRootPart)
		v.AngularVelocity = Vector3.new(math.random(-50,50),math.random(-50,50),math.random(-50,50))
		v.Name = "Seizure"
	end
end
Commands.unseizure = function(p)
	if p.Character then
		p.Character.Humanoid.PlatformStand = false
		if p.Character.HumanoidRootPart:FindFirstChild("Seizure") then p.Character.HumanoidRootPart.Seizure:Destroy() end
	end
end
Commands.blind = function(p) local g = Instance.new("ScreenGui", p.PlayerGui) g.Name = "BlindGui" local f = Instance.new("Frame", g) f.Size = UDim2.new(1,0,1,0) f.BackgroundColor3 = Color3.new(0,0,0) end
Commands.unblind = function(p) if p.PlayerGui:FindFirstChild("BlindGui") then p.PlayerGui.BlindGui:Destroy() end end
Commands.blur = function(p) local b = Instance.new("BlurEffect", Lighting) b.Name = "AdminBlur" b.Size = 25 end
Commands.unblur = function(p) for _,v in pairs(Lighting:GetChildren()) do if v.Name == "AdminBlur" then v:Destroy() end end end
Commands.sky = function(p, a) local s = Instance.new("Sky", Lighting) s.SkyboxBk = "rbxassetid://"..a[2] s.SkyboxDn = "rbxassetid://"..a[2] s.SkyboxFt = "rbxassetid://"..a[2] s.SkyboxLf = "rbxassetid://"..a[2] s.SkyboxRt = "rbxassetid://"..a[2] s.SkyboxUp = "rbxassetid://"..a[2] end
Commands.unsky = function(p) for _,v in pairs(Lighting:GetChildren()) do if v:IsA("Sky") then v:Destroy() end end end
Commands.time = function(p, a) Lighting.ClockTime = tonumber(a[2]) or 12 end
Commands.day = function() Lighting.ClockTime = 14 end
Commands.night = function() Lighting.ClockTime = 0 end
Commands.noon = function() Lighting.ClockTime = 12 end
Commands.midnight = function() Lighting.ClockTime = 24 end
Commands.fog = function() Lighting.FogEnd = 50 end
Commands.unfog = function() Lighting.FogEnd = 100000 end
Commands.shadows = function() Lighting.GlobalShadows = true end
Commands.unshadows = function() Lighting.GlobalShadows = false end
Commands.brightness = function(p, a) Lighting.Brightness = tonumber(a[2]) or 2 end
Commands.unbrightness = function() Lighting.Brightness = 1 end
Commands.ambient = function(p, a) Lighting.Ambient = Color3.fromRGB(tonumber(a[2]) or 100, tonumber(a[3]) or 100, tonumber(a[4]) or 100) end
Commands.unambient = function() Lighting.Ambient = Color3.fromRGB(0,0,0) end
Commands.shutdown = function() for _,v in pairs(Players:GetPlayers()) do v:Kick("Server Shutdown") end end
Commands.clean = function() for _,v in pairs(workspace:GetChildren()) do if not Players:GetPlayerFromCharacter(v) and not v:IsA("Terrain") and not v:IsA("Camera") then v:Destroy() end end end
Commands.loopkill = function(p)
	local b = Instance.new("BoolValue", p) b.Name = "LoopKill"
	task.spawn(function()
		while b.Parent do if p.Character then p.Character:BreakJoints() end task.wait(3) end
	end)
end
Commands.unloopkill = function(p) if p:FindFirstChild("LoopKill") then p.LoopKill:Destroy() end end
Commands.message = function(p, a) local m = Instance.new("Message", workspace) m.Text = table.concat(a, " ", 2) Debris:AddItem(m,4) end
Commands.hint = function(p, a) local h = Instance.new("Hint", workspace) h.Text = table.concat(a, " ", 2) Debris:AddItem(h,4) end
Commands.warn = function(p, a) local m = Instance.new("Message", workspace) m.Text = "WARNING: "..table.concat(a, " ", 2) Debris:AddItem(m,4) end
Commands.announce = function(p, a) local m = Instance.new("Message", workspace) m.Text = "ANNOUNCEMENT: "..table.concat(a, " ", 2) Debris:AddItem(m,6) end
Commands.music = function(p, a) local s = Instance.new("Sound", workspace) s.Name = "AdminMusic" s.SoundId = "rbxassetid://"..a[2] s.Looped = true s.Volume = 2 s:Play() end
Commands.stopmusic = function() for _,v in pairs(workspace:GetChildren()) do if v.Name == "AdminMusic" then v:Destroy() end end end
Commands.naked = function(p) if p.Character then for _,v in pairs(p.Character:GetChildren()) do if v:IsA("Clothing") or v:IsA("ShirtGraphic") then v:Destroy() end end end end
Commands.unnaked = Commands.respawn
Commands.rocket = function(p) if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then local v = Instance.new("BodyVelocity", p.Character.HumanoidRootPart) v.Velocity = Vector3.new(0,500,0) v.MaxForce = Vector3.new(0,math.huge,0) Debris:AddItem(v,2) end end
Commands.trip = function(p) if p.Character and p.Character:FindFirstChild("Humanoid") then p.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Physics) end end
Commands.untrip = function(p) if p.Character and p.Character:FindFirstChild("Humanoid") then p.Character.Humanoid:ChangeState(Enum.HumanoidStateType.GettingUp) end end
Commands.confuse = function(p) if p.Character and p.Character:FindFirstChild("Humanoid") then p.Character.Humanoid.WalkSpeed = -16 end end
Commands.unconfuse = function(p) if p.Character and p.Character:FindFirstChild("Humanoid") then p.Character.Humanoid.WalkSpeed = 16 end end
Commands.highgravity = function() workspace.Gravity = 500 end
Commands.lowgravity = function() workspace.Gravity = 50 end
Commands.normalgravity = function() workspace.Gravity = 196.2 end
Commands.ungravity = Commands.normalgravity
Commands.zerogravity = function() workspace.Gravity = 0 end
Commands.moon = function() workspace.Gravity = 32 end
Commands.team = function(p, a) local tName = a[2] for _,t in pairs(game:GetService("Teams"):GetTeams()) do if t.Name:lower():match(tName:lower()) then p.Team = t end end end
Commands.unteam = function(p) p.Team = nil end
Commands.tools = function(p) for _,v in pairs(ServerStorage:GetChildren()) do if v:IsA("Tool") then v:Clone().Parent = p.Backpack end end end
Commands.removetools = function(p) p.Backpack:ClearAllChildren() end
Commands.hats = function(p) if p.Character then for _,v in pairs(p.Character:GetChildren()) do if v:IsA("Accessory") then v:Destroy() end end end end
Commands.unhats = Commands.respawn
Commands.face = function(p, a) if p.Character and p.Character:FindFirstChild("Head") and p.Character.Head:FindFirstChild("face") then p.Character.Head.face.Texture = "rbxassetid://"..a[2] end end
Commands.noface = function(p) if p.Character and p.Character:FindFirstChild("Head") and p.Character.Head:FindFirstChild("face") then p.Character.Head.face:Destroy() end end
Commands.unnoface = Commands.respawn
Commands.skydive = function(p) if p.Character then p.Character:PivotTo(p.Character:GetPivot() + Vector3.new(0,500,0)) end end
Commands.platform = function(p) if p.Character then local pt = Instance.new("Part", workspace) pt.Anchored = true pt.Size = Vector3.new(20,1,20) pt.CFrame = p.Character:GetPivot() * CFrame.new(0,-4,0) pt.Name = "AdminPlatform" end end
Commands.unplatform = function() for _,v in pairs(workspace:GetChildren()) do if v.Name == "AdminPlatform" then v:Destroy() end end end
Commands.view = function(p, a, s) if s.Character and p.Character and p.Character:FindFirstChild("Humanoid") then workspace.CurrentCamera.CameraSubject = p.Character.Humanoid end end
Commands.unview = function(p, a, s) if s.Character and s.Character:FindFirstChild("Humanoid") then workspace.CurrentCamera.CameraSubject = s.Character.Humanoid end end
Commands.ball = function(p) if p.Character then p.Character.HumanoidRootPart.Shape = Enum.PartType.Ball p.Character.HumanoidRootPart.Size = Vector3.new(5,5,5) end end
Commands.unball = Commands.respawn
Commands.reset = Commands.respawn
Commands.particle = function(p, a) if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then local pa = Instance.new("ParticleEmitter", p.Character.HumanoidRootPart) pa.Texture = "rbxassetid://"..a[2] end end
Commands.unparticle = function(p) if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then for _,v in pairs(p.Character.HumanoidRootPart:GetChildren()) do if v:IsA("ParticleEmitter") then v:Destroy() end end end end
Commands.zombie = function(p) if p.Character then p.Character.Head.Color = Color3.new(0,0.6,0) p.Character.Humanoid.WalkSpeed = 8 end end
Commands.unzombie = Commands.respawn
Commands.dummy = function(p) if p.Character then p.Character.Archivable = true local d = p.Character:Clone() d.Parent = workspace d.Name = "Dummy" end end
Commands.undummy = function() if workspace:FindFirstChild("Dummy") then workspace.Dummy:Destroy() end end
Commands.blockhead = function(p) if p.Character and p.Character:FindFirstChild("Head") then local m = p.Character.Head:FindFirstChild("Mesh") if m then m:Destroy() end end end
Commands.unblockhead = Commands.respawn
Commands.r6 = function(p) if p.Character and p.Character:FindFirstChild("Humanoid") then p.Character.Humanoid.RigType = Enum.HumanoidRigType.R6 p:LoadCharacter() end end
Commands.r15 = function(p) if p.Character and p.Character:FindFirstChild("Humanoid") then p.Character.Humanoid.RigType = Enum.HumanoidRigType.R15 p:LoadCharacter() end end
Commands.control = function(p, a, s)
	if p.Character and s.Character then
		local humanoid = p.Character:FindFirstChild("Humanoid")
		if humanoid then
			humanoid.PlatformStand = true
			local bp = Instance.new("BodyPosition", p.Character.HumanoidRootPart)
			bp.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
			local bg = Instance.new("BodyGyro", p.Character.HumanoidRootPart)
			bg.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
			local t = Instance.new("BoolValue") t.Name = "Controlled" t.Parent = p
		end
	end
end
Commands.uncontrol = function(p)
	if p:FindFirstChild("Controlled") then p.Controlled:Destroy() end
	if p.Character and p.Character:FindFirstChild("Humanoid") then
		p.Character.Humanoid.PlatformStand = false
		for _, v in pairs(p.Character.HumanoidRootPart:GetChildren()) do
			if v:IsA("BodyPosition") or v:IsA("BodyGyro") then v:Destroy() end
		end
	end
end
Commands.punish = function(p) if p.Character then p.Character.Parent = ServerStorage end end
Commands.unpunish = function(p) if ServerStorage:FindFirstChild(p.Name) then ServerStorage[p.Name].Parent = workspace end end
Commands.crash = function(p) for i=1,100 do local s = Instance.new("Sound", workspace) s.SoundId = "rbxassetid://" s:Play() Debris:AddItem(s,0.1) end end
Commands.lag = function(p) for i=1,100 do local part = Instance.new("Part", workspace) part.Size = Vector3.new(100,100,100) part.Position = Vector3.new(0,1000,0) Debris:AddItem(part,10) end end
Commands.rainbow = function(p)
	if p.Character then
		local t = Instance.new("BoolValue") t.Name = "Rainbow" t.Parent = p
		task.spawn(function()
			while t.Parent do
				for _, v in pairs(p.Character:GetChildren()) do
					if v:IsA("BasePart") then v.Color = Color3.fromHSV(tick()%5/5,1,1) end
				end
				task.wait(0.1)
			end
		end)
	end
end
Commands.unrainbow = function(p) if p:FindFirstChild("Rainbow") then p.Rainbow:Destroy() end end
Commands.walkspeed = Commands.speed
Commands.jumppower = Commands.jump
Commands.hipheight = function(p, a) if p.Character and p.Character:FindFirstChild("Humanoid") then p.Character.Humanoid.HipHeight = tonumber(a[2]) or 0 end end
Commands.maxhealth = function(p, a) if p.Character and p.Character:FindFirstChild("Humanoid") then p.Character.Humanoid.MaxHealth = tonumber(a[2]) or 100 end end
Commands.health = function(p, a) if p.Character and p.Character:FindFirstChild("Humanoid") then p.Character.Humanoid.Health = tonumber(a[2]) or 100 end end
Commands.creeperloop = function(p)
	local t = Instance.new("BoolValue") t.Name = "CreeperLoop" t.Parent = p
	task.spawn(function()
		while t.Parent do Commands.creeper(p) task.wait(0.5) end
	end)
end
Commands.uncreeperloop = function(p) if p:FindFirstChild("CreeperLoop") then p.CreeperLoop:Destroy() end Commands.uncreeper(p) end
Commands.drophats = function(p)
	if p.Character then
		for _, v in pairs(p.Character:GetChildren()) do
			if v:IsA("Accessory") then
				v.Parent = workspace
				v.Handle.CFrame = p.Character.HumanoidRootPart.CFrame
				local bv = Instance.new("BodyVelocity", v.Handle)
				bv.Velocity = Vector3.new(math.random(-10,10),20,math.random(-10,10))
				Debris:AddItem(bv,1)
			end
		end
	end
end
Commands.orbit = function(p, a, s)
	if p.Character and s.Character and s.Character:FindFirstChild("HumanoidRootPart") then
		local t = Instance.new("BoolValue") t.Name = "Orbiting" t.Parent = p
		local d = tonumber(a[3]) or 10
		local sp = tonumber(a[4]) or 5
		task.spawn(function()
			local angle = 0
			while t.Parent and p.Character and p.Character:FindFirstChild("HumanoidRootPart") do
				angle = angle + sp/100
				local o = Vector3.new(math.cos(angle)*d,0,math.sin(angle)*d)
				p.Character.HumanoidRootPart.CFrame = s.Character.HumanoidRootPart.CFrame + o
				task.wait()
			end
		end)
	end
end
Commands.unorbit = function(p) if p:FindFirstChild("Orbiting") then p.Orbiting:Destroy() end end
Commands.float = function(p) if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then local bf = Instance.new("BodyForce", p.Character.HumanoidRootPart) bf.Force = Vector3.new(0,workspace.Gravity*p.Character.HumanoidRootPart:GetMass(),0) bf.Name = "FloatForce" end end
Commands.unfloat = function(p) if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then local ff = p.Character.HumanoidRootPart:FindFirstChild("FloatForce") if ff then ff:Destroy() end end end
Commands.void = function(p) if p.Character then p.Character:PivotTo(CFrame.new(0,-500,0)) end end
Commands.unvoid = function(p) if p.Character then p.Character:PivotTo(CFrame.new(0,50,0)) end end
Commands.ragdoll = function(p) if p.Character then for _, v in pairs(p.Character:GetDescendants()) do if v:IsA("Motor6D") then local h = Instance.new("HingeConstraint", v.Part1) h.Attachment0 = Instance.new("Attachment", v.Part0) h.Attachment1 = Instance.new("Attachment", v.Part1) v:Destroy() end end end end
Commands.unragdoll = Commands.respawn
Commands.clone = function(p) if p.Character then p.Character.Archivable = true local c = p.Character:Clone() c.Parent = workspace c.Name = p.Name.."_Clone" for _, v in pairs(c:GetDescendants()) do if v:IsA("Script") then v:Destroy() end end end end
Commands.unclone = function(p) for _, v in pairs(workspace:GetChildren()) do if v.Name:match("_Clone") then v:Destroy() end end end
Commands.pet = function(p, a, s) if s.Character and s.Character:FindFirstChild("HumanoidRootPart") then local pet = Instance.new("Part", workspace) pet.Name = "Pet_"..p.Name pet.Size = Vector3.new(2,2,2) pet.BrickColor = BrickColor.new("Bright blue") pet.Material = Enum.Material.Neon local w = Instance.new("Weld", pet) w.Part0 = s.Character.HumanoidRootPart w.Part1 = pet w.C0 = CFrame.new(0,0,-5) end end
Commands.unpet = function(p) for _, v in pairs(workspace:GetChildren()) do if v.Name:match("Pet_") then v:Destroy() end end end
Commands.cage = function(p)
	if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
		local cf = p.Character.HumanoidRootPart.CFrame
		local cage = Instance.new("Model", workspace) cage.Name = "Cage_"..p.Name
		for i=1,6 do
			local side = Instance.new("Part", cage) side.Anchored = true side.Transparency = 0.3 side.Color = Color3.new(1,0,0)
			if i==1 then side.Size = Vector3.new(10,10,1) side.CFrame = cf + Vector3.new(0,0,5)
			elseif i==2 then side.Size = Vector3.new(10,10,1) side.CFrame = cf + Vector3.new(0,0,-5)
			elseif i==3 then side.Size = Vector3.new(1,10,10) side.CFrame = cf + Vector3.new(5,0,0)
			elseif i==4 then side.Size = Vector3.new(1,10,10) side.CFrame = cf + Vector3.new(-5,0,0)
			elseif i==5 then side.Size = Vector3.new(10,1,10) side.CFrame = cf + Vector3.new(0,5,0)
			elseif i==6 then side.Size = Vector3.new(10,1,10) side.CFrame = cf + Vector3.new(0,-5,0) end
		end
	end
end
Commands.uncage = function(p) for _, v in pairs(workspace:GetChildren()) do if v.Name:match("Cage_") then v:Destroy() end end end
Commands.firework = function(p)
	if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
		local pos = p.Character.HumanoidRootPart.Position
		for i=1,20 do
			local part = Instance.new("Part", workspace) part.Size = Vector3.new(0.5,0.5,0.5)
			part.Position = pos + Vector3.new(math.random(-5,5),math.random(10,20),math.random(-5,5))
			part.Color = Color3.new(math.random(),math.random(),math.random()) part.Material = Enum.Material.Neon
			local bv = Instance.new("BodyVelocity", part) bv.Velocity = Vector3.new(math.random(-10,10),math.random(20,50),math.random(-10,10))
			Debris:AddItem(bv,0.5) Debris:AddItem(part,3)
		end
	end
end
Commands.dance = function(p) if p.Character and p.Character:FindFirstChild("Humanoid") then p.Character.Humanoid:LoadAnimation(Instance.new("Animation")):Play() end end
Commands.undance = function(p) if p.Character and p.Character:FindFirstChild("Humanoid") then p.Character.Humanoid:LoadAnimation(Instance.new("Animation")):Stop() end end
Commands.slay = Commands.kill
Commands.smite = function(p)
	if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
		local l = Instance.new("Part", workspace) l.Size = Vector3.new(1,50,1) l.Position = p.Character.HumanoidRootPart.Position + Vector3.new(0,25,0)
		l.Color = Color3.new(1,1,0) l.Material = Enum.Material.Neon l.Anchored = true Debris:AddItem(l,0.5)
		local e = Instance.new("Explosion", workspace) e.Position = p.Character.HumanoidRootPart.Position e.BlastPressure = 0 e.BlastRadius = 10
	end
end
Commands.lagserver = function() for i=1,1000 do local p = Instance.new("Part", workspace) p.Size = Vector3.new(1000,1000,1000) p.Position = Vector3.new(0,10000,0) Debris:AddItem(p,30) end end
Commands.unjailall = function() for _, v in pairs(workspace:GetChildren()) do if v.Name:match("Jail_") then v:Destroy() end end end
Commands.ungodall = function() for _, v in pairs(Players:GetPlayers()) do Commands.ungod(v) end end
Commands.godall = function() for _, v in pairs(Players:GetPlayers()) do Commands.god(v) end end
Commands.killall = function() for _, v in pairs(Players:GetPlayers()) do Commands.kill(v) end end
Commands.freezeall = function() for _, v in pairs(Players:GetPlayers()) do Commands.freeze(v) end end
Commands.thawall = function() for _, v in pairs(Players:GetPlayers()) do Commands.thaw(v) end end
Commands.respawnall = function() for _, v in pairs(Players:GetPlayers()) do Commands.respawn(v) end end
Commands.ffall = function() for _, v in pairs(Players:GetPlayers()) do Commands.ff(v) end end
Commands.unffall = function() for _, v in pairs(Players:GetPlayers()) do Commands.unff(v) end end
Commands.btoolsall = function() for _, v in pairs(Players:GetPlayers()) do Commands.btools(v) end end
Commands.unbtoolsall = function() for _, v in pairs(Players:GetPlayers()) do Commands.unbtools(v) end end
Commands.speedall = function(p,a) for _, v in pairs(Players:GetPlayers()) do Commands.speed(v,a) end end
Commands.unspeedall = function() for _, v in pairs(Players:GetPlayers()) do Commands.unspeed(v) end end
Commands.jumpall = function(p,a) for _, v in pairs(Players:GetPlayers()) do Commands.jump(v,a) end end
Commands.unjumpall = function() for _, v in pairs(Players:GetPlayers()) do Commands.unjump(v) end end
Commands.rocketall = function() for _, v in pairs(Players:GetPlayers()) do Commands.rocket(v) end end
Commands.flingall = function() for _, v in pairs(Players:GetPlayers()) do Commands.fling(v) end end
Commands.spinall = function() for _, v in pairs(Players:GetPlayers()) do Commands.spin(v) end end
Commands.unspinall = function() for _, v in pairs(Players:GetPlayers()) do Commands.unspin(v) end end
Commands.invisibleall = function() for _, v in pairs(Players:GetPlayers()) do Commands.invisible(v) end end
Commands.visibleall = function() for _, v in pairs(Players:GetPlayers()) do Commands.visible(v) end end
Commands.ghostall = function() for _, v in pairs(Players:GetPlayers()) do Commands.ghost(v) end end
Commands.unghostall = function() for _, v in pairs(Players:GetPlayers()) do Commands.unghost(v) end end
Commands.neonall = function() for _, v in pairs(Players:GetPlayers()) do Commands.neon(v) end end
Commands.unneonall = function() for _, v in pairs(Players:GetPlayers()) do Commands.unneon(v) end end
Commands.shinyall = function() for _, v in pairs(Players:GetPlayers()) do Commands.shiny(v) end end
Commands.unshinyall = function() for _, v in pairs(Players:GetPlayers()) do Commands.unshiny(v) end end
Commands.glassall = function() for _, v in pairs(Players:GetPlayers()) do Commands.glass(v) end end
Commands.unglassall = function() for _, v in pairs(Players:GetPlayers()) do Commands.unglass(v) end end
Commands.goldall = function() for _, v in pairs(Players:GetPlayers()) do Commands.gold(v) end end
Commands.ungoldall = function() for _, v in pairs(Players:GetPlayers()) do Commands.ungold(v) end end
Commands.iceall = function() for _, v in pairs(Players:GetPlayers()) do Commands.ice(v) end end
Commands.uniceall = function() for _, v in pairs(Players:GetPlayers()) do Commands.unice(v) end end
Commands.charall = function(p,a) for _, v in pairs(Players:GetPlayers()) do Commands.char(v,a) end end
Commands.uncharall = function() for _, v in pairs(Players:GetPlayers()) do Commands.unchar(v) end end
Commands.creeperall = function() for _, v in pairs(Players:GetPlayers()) do Commands.creeper(v) end end
Commands.uncreeperall = function() for _, v in pairs(Players:GetPlayers()) do Commands.uncreeper(v) end end
Commands.nameall = function(p,a) for _, v in pairs(Players:GetPlayers()) do Commands.name(v,a) end end
Commands.unnameall = function() for _, v in pairs(Players:GetPlayers()) do Commands.unname(v) end end
Commands.displaynameall = function(p,a) for _, v in pairs(Players:GetPlayers()) do Commands.displayname(v,a) end end
Commands.undisplaynameall = function() for _, v in pairs(Players:GetPlayers()) do Commands.undisplayname(v) end end
Commands.fartall = function() for _, v in pairs(Players:GetPlayers()) do Commands.fart(v) end end
Commands.explodeall = function() for _, v in pairs(Players:GetPlayers()) do Commands.explode(v) end end
Commands.fireall = function() for _, v in pairs(Players:GetPlayers()) do Commands.fire(v) end end
Commands.unfireall = function() for _, v in pairs(Players:GetPlayers()) do Commands.unfire(v) end end
Commands.smokeall = function() for _, v in pairs(Players:GetPlayers()) do Commands.smoke(v) end end
Commands.unsmokeall = function() for _, v in pairs(Players:GetPlayers()) do Commands.unsmoke(v) end end
Commands.sparklesall = function() for _, v in pairs(Players:GetPlayers()) do Commands.sparkles(v) end end
Commands.unsparklesall = function() for _, v in pairs(Players:GetPlayers()) do Commands.unsparkles(v) end end
Commands.rainbowall = function() for _, v in pairs(Players:GetPlayers()) do Commands.rainbow(v) end end
Commands.unrainbowall = function() for _, v in pairs(Players:GetPlayers()) do Commands.unrainbow(v) end end
Commands.danceall = function() for _, v in pairs(Players:GetPlayers()) do Commands.dance(v) end end
Commands.undanceall = function() for _, v in pairs(Players:GetPlayers()) do Commands.undance(v) end end
Commands.slayall = function() for _, v in pairs(Players:GetPlayers()) do Commands.slay(v) end end
Commands.smiteall = function() for _, v in pairs(Players:GetPlayers()) do Commands.smite(v) end end
Commands.fireworkall = function() for _, v in pairs(Players:GetPlayers()) do Commands.firework(v) end end
Commands.bigheadall = function() for _, v in pairs(Players:GetPlayers()) do Commands.bighead(v) end end
Commands.unbigheadall = function() for _, v in pairs(Players:GetPlayers()) do Commands.unbighead(v) end end
Commands.smallheadall = function() for _, v in pairs(Players:GetPlayers()) do Commands.smallhead(v) end end
Commands.unsmallheadall = function() for _, v in pairs(Players:GetPlayers()) do Commands.unsmallhead(v) end end
Commands.giantall = function() for _, v in pairs(Players:GetPlayers()) do Commands.giant(v) end end
Commands.ungiantall = function() for _, v in pairs(Players:GetPlayers()) do Commands.ungiant(v) end end
Commands.tinyall = function() for _, v in pairs(Players:GetPlayers()) do Commands.tiny(v) end end
Commands.untinyall = function() for _, v in pairs(Players:GetPlayers()) do Commands.untiny(v) end end
Commands.fatall = function() for _, v in pairs(Players:GetPlayers()) do Commands.fat(v) end end
Commands.unfatall = function() for _, v in pairs(Players:GetPlayers()) do Commands.unfat(v) end end
Commands.skinnyall = function() for _, v in pairs(Players:GetPlayers()) do Commands.skinny(v) end end
Commands.unskinnyall = function() for _, v in pairs(Players:GetPlayers()) do Commands.unskinny(v) end end
Commands.tallall = function() for _, v in pairs(Players:GetPlayers()) do Commands.tall(v) end end
Commands.untallall = function() for _, v in pairs(Players:GetPlayers()) do Commands.untall(v) end end
Commands.shortall = function() for _, v in pairs(Players:GetPlayers()) do Commands.short(v) end end
Commands.unshortall = function() for _, v in pairs(Players:GetPlayers()) do Commands.unshort(v) end end
Commands.noarmsall = function() for _, v in pairs(Players:GetPlayers()) do Commands.noarms(v) end end
Commands.unnoarmsall = function() for _, v in pairs(Players:GetPlayers()) do Commands.unnoarms(v) end end
Commands.nolegsall = function() for _, v in pairs(Players:GetPlayers()) do Commands.nolegs(v) end end
Commands.unnolegsall = function() for _, v in pairs(Players:GetPlayers()) do Commands.unnolegs(v) end end
Commands.noheadall = function() for _, v in pairs(Players:GetPlayers()) do Commands.nohead(v) end end
Commands.unnoheadall = function() for _, v in pairs(Players:GetPlayers()) do Commands.unnohead(v) end end
Commands.hatsall = function() for _, v in pairs(Players:GetPlayers()) do Commands.hats(v) end end
Commands.unhatsall = function() for _, v in pairs(Players:GetPlayers()) do Commands.unhats(v) end end
Commands.nakedall = function() for _, v in pairs(Players:GetPlayers()) do Commands.naked(v) end end
Commands.unnakedall = function() for _, v in pairs(Players:GetPlayers()) do Commands.unnaked(v) end end
Commands.sitall = function() for _, v in pairs(Players:GetPlayers()) do Commands.sit(v) end end
Commands.unsitall = function() for _, v in pairs(Players:GetPlayers()) do Commands.unsit(v) end end
Commands.stunall = function() for _, v in pairs(Players:GetPlayers()) do Commands.stun(v) end end
Commands.unstunall = function() for _, v in pairs(Players:GetPlayers()) do Commands.unstun(v) end end
Commands.confuseall = function() for _, v in pairs(Players:GetPlayers()) do Commands.confuse(v) end end
Commands.unconfuseall = function() for _, v in pairs(Players:GetPlayers()) do Commands.unconfuse(v) end end
Commands.tripall = function() for _, v in pairs(Players:GetPlayers()) do Commands.trip(v) end end
Commands.untripall = function() for _, v in pairs(Players:GetPlayers()) do Commands.untrip(v) end end
Commands.r6all = function() for _, v in pairs(Players:GetPlayers()) do Commands.r6(v) end end
Commands.r15all = function() for _, v in pairs(Players:GetPlayers()) do Commands.r15(v) end end
Commands.punishall = function() for _, v in pairs(Players:GetPlayers()) do Commands.punish(v) end end
Commands.unpunishall = function() for _, v in pairs(Players:GetPlayers()) do Commands.unpunish(v) end end
Commands.cageall = function() for _, v in pairs(Players:GetPlayers()) do Commands.cage(v) end end
Commands.uncageall = function() for _, v in pairs(Players:GetPlayers()) do Commands.uncage(v) end end
Commands.voidall = function() for _, v in pairs(Players:GetPlayers()) do Commands.void(v) end end
Commands.unvoidall = function() for _, v in pairs(Players:GetPlayers()) do Commands.unvoid(v) end end
Commands.ragdollall = function() for _, v in pairs(Players:GetPlayers()) do Commands.ragdoll(v) end end
Commands.unragdollall = function() for _, v in pairs(Players:GetPlayers()) do Commands.unragdoll(v) end end
Commands.cloneall = function() for _, v in pairs(Players:GetPlayers()) do Commands.clone(v) end end
Commands.uncloneall = function() for _, v in pairs(workspace:GetChildren()) do if v.Name:match("_Clone") then v:Destroy() end end end
Commands.petall = function(p,a,s) for _, v in pairs(Players:GetPlayers()) do if v~=s then Commands.pet(v,a,s) end end end
Commands.unpetall = function() for _, v in pairs(workspace:GetChildren()) do if v.Name:match("Pet_") then v:Destroy() end end end
Commands.crashall = function() for _, v in pairs(Players:GetPlayers()) do Commands.crash(v) end end
Commands.lagall = function() for _, v in pairs(Players:GetPlayers()) do Commands.lag(v) end end
Commands.toolsall = function() for _, v in pairs(Players:GetPlayers()) do Commands.tools(v) end end
Commands.removetoolsall = function() for _, v in pairs(Players:GetPlayers()) do Commands.removetools(v) end end
Commands.swordall = function() for _, v in pairs(Players:GetPlayers()) do Commands.sword(v) end end
Commands.unswordall = function() for _, v in pairs(Players:GetPlayers()) do Commands.unsword(v) end end
Commands.gunall = function() for _, v in pairs(Players:GetPlayers()) do Commands.gun(v) end end
Commands.ungunall = function() for _, v in pairs(Players:GetPlayers()) do Commands.ungun(v) end end
Commands.gravgunall = function() for _, v in pairs(Players:GetPlayers()) do Commands.gravgun(v) end end
Commands.ungravgunall = function() for _, v in pairs(Players:GetPlayers()) do Commands.ungravgun(v) end end
Commands.loopkillall = function() for _, v in pairs(Players:GetPlayers()) do Commands.loopkill(v) end end
Commands.unloopkillall = function() for _, v in pairs(Players:GetPlayers()) do Commands.unloopkill(v) end end
Commands.loopflingall = function() for _, v in pairs(Players:GetPlayers()) do Commands.loopfling(v) end end
Commands.unloopflingall = function() for _, v in pairs(Players:GetPlayers()) do Commands.unloopfling(v) end end
Commands.creeperloopall = function() for _, v in pairs(Players:GetPlayers()) do Commands.creeperloop(v) end end
Commands.uncreeperloopall = function() for _, v in pairs(Players:GetPlayers()) do Commands.uncreeperloop(v) end end
Commands.orbitall = function(p,a,s) for _, v in pairs(Players:GetPlayers()) do if v~=s then Commands.orbit(v,a,s) end end end
Commands.unorbitall = function() for _, v in pairs(Players:GetPlayers()) do Commands.unorbit(v) end end
Commands.floatall = function() for _, v in pairs(Players:GetPlayers()) do Commands.float(v) end end
Commands.unfloatall = function() for _, v in pairs(Players:GetPlayers()) do Commands.unfloat(v) end end
Commands.skydiveall = function() for _, v in pairs(Players:GetPlayers()) do Commands.skydive(v) end end
Commands.platformall = function() for _, v in pairs(Players:GetPlayers()) do Commands.platform(v) end end
Commands.unplatformall = Commands.unplatform
Commands.viewall = function(p,a,s) for _, v in pairs(Players:GetPlayers()) do if v~=s then Commands.view(v,a,s) end end end
Commands.unviewall = Commands.unview
Commands.ballall = function() for _, v in pairs(Players:GetPlayers()) do Commands.ball(v) end end
Commands.unballall = function() for _, v in pairs(Players:GetPlayers()) do Commands.unball(v) end end
Commands.resetall = function() for _, v in pairs(Players:GetPlayers()) do Commands.reset(v) end end
Commands.particleall = function(p,a) for _, v in pairs(Players:GetPlayers()) do Commands.particle(v,a) end end
Commands.unparticleall = function() for _, v in pairs(Players:GetPlayers()) do Commands.unparticle(v) end end
Commands.zombieall = function() for _, v in pairs(Players:GetPlayers()) do Commands.zombie(v) end end
Commands.unzombieall = function() for _, v in pairs(Players:GetPlayers()) do Commands.unzombie(v) end end
Commands.dummyall = function() for _, v in pairs(Players:GetPlayers()) do Commands.dummy(v) end end
Commands.undummyall = Commands.undummy
Commands.blockheadall = function() for _, v in pairs(Players:GetPlayers()) do Commands.blockhead(v) end end
Commands.unblockheadall = function() for _, v in pairs(Players:GetPlayers()) do Commands.unblockhead(v) end end
Commands.controlall = function(p,a,s) for _, v in pairs(Players:GetPlayers()) do if v~=s then Commands.control(v,a,s) end end end
Commands.uncontrolall = function() for _, v in pairs(Players:GetPlayers()) do Commands.uncontrol(v) end end

local AllCommandsList = {}
for name, _ in pairs(Commands) do
	table.insert(AllCommandsList, name)
end

Remote.OnServerEvent:Connect(function(player, action, data)
	if action == "RequestCommands" then
		Remote:FireClient(player, "UpdateCommands", AllCommandsList)
	elseif action == "Execute" then
		if not IsAdmin(player) then return end
		local args = data:split(" ")
		local cmdName = args[1]:lower()
		if Commands[cmdName] then
			local targetStr = args[2] or "me"
			local targets = GetPlayer(targetStr, player)
			if targets then
				for _, t in pairs(targets) do
					pcall(function() Commands[cmdName](t, args, player) end)
				end
			else
				local globalCmds = {}
				for k,_ in pairs(Commands) do
					if k:match("all$") or k=="clean" or k=="shutdown" or k=="stopmusic" or k=="day" or k=="night" or k=="noon" or k=="midnight" or k=="fog" or k=="unfog" or k=="shadows" or k=="unshadows" or k=="unplatform" or k=="undummy" or k=="unblur" or k=="unsky" or k=="time" or k=="brightness" or k=="unbrightness" or k=="ambient" or k=="unambient" or k=="highgravity" or k=="lowgravity" or k=="normalgravity" or k=="ungravity" or k=="zerogravity" or k=="moon" or k=="sky" then
						table.insert(globalCmds, k)
					end
				end
				if table.find(globalCmds, cmdName) then
					Commands[cmdName](player, args, player)
				end
			end
		end
	end
end)