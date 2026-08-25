local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local InsertService = game:GetService("InsertService")

local eventFolder = Instance.new("Folder")
eventFolder.Name = "TrollSystemEvents"
eventFolder.Parent = ReplicatedStorage

local trollFunction = Instance.new("RemoteFunction")
trollFunction.Name = "TrollFunction"
trollFunction.Parent = eventFolder

local trollEvent = Instance.new("RemoteEvent")
trollEvent.Name = "TrollEvent"
trollEvent.Parent = eventFolder

local trollActions = {
	{Name = "Kill", ProductId = 10000001, Icon = "10568600100"},
	{Name = "Explode", ProductId = 10000002, Icon = "10568600100"},
	{Name = "Fling", ProductId = 10000003, Icon = "10568600100"},
	{Name = "Freeze", ProductId = 10000004, Icon = "10568600100"},
	{Name = "Jumpscare", ProductId = 10000005, Icon = "10568600100"},
	{Name = "Sword", ProductId = 10000006, Icon = "10568600100"},
	{Name = "Speed", ProductId = 10000008, Icon = "10568600100"},
	{Name = "Slow", ProductId = 10000009, Icon = "10568600100"},
	{Name = "Jump", ProductId = 10000010, Icon = "10568600100"},
	{Name = "Sit", ProductId = 10000011, Icon = "10568600100"},
	{Name = "Spin", ProductId = 10000012, Icon = "10568600100"}
}

local pendingPurchases = {}

trollFunction.OnServerInvoke = function(player)
	return trollActions
end

MarketplaceService.ProcessReceipt = function(receiptInfo)
	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if not player then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	
	local actionData = nil
	for _, action in ipairs(trollActions) do
		if action.ProductId == receiptInfo.ProductId then
			actionData = action
			break
		end
	end
	
	if actionData then
		if not pendingPurchases[player.UserId] then
			pendingPurchases[player.UserId] = {}
		end
		pendingPurchases[player.UserId][actionData.Name] = (pendingPurchases[player.UserId][actionData.Name] or 0) + 1
		trollEvent:FireClient(player, actionData.Name)
	end
	
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

trollEvent.OnServerEvent:Connect(function(player, actionName, targetPlayer)
	if pendingPurchases[player.UserId] and pendingPurchases[player.UserId][actionName] and pendingPurchases[player.UserId][actionName] > 0 then
		pendingPurchases[player.UserId][actionName] = pendingPurchases[player.UserId][actionName] - 1
		
		if targetPlayer and targetPlayer.Character then
			local char = targetPlayer.Character
			local humanoid = char:FindFirstChildOfClass("Humanoid")
			local hrp = char:FindFirstChild("HumanoidRootPart")
			
			if char and humanoid and hrp then
				if actionName == "Kill" then
					humanoid.Health = 0
				elseif actionName == "Explode" then
					local exp = Instance.new("Explosion")
					exp.Position = hrp.Position
					exp.Parent = workspace
				elseif actionName == "Fling" then
					local BodyVelocity = Instance.new("BodyVelocity", hrp)
					BodyVelocity.Velocity = Vector3.new(math.huge, math.huge, math.huge)
					hrp.Velocity = Vector3.new(math.huge, math.huge, math.huge)
				elseif actionName == "Freeze" then
					hrp.Anchored = true
					task.delay(5, function()
						if hrp then hrp.Anchored = false end
					end)
				elseif actionName == "Sword" then
					local success, model = pcall(function()
						return InsertService:LoadAsset(47433)
					end)
					if success and model then
						local item = model:GetChildren()[1]
						if item then
							item.Parent = ReplicatedStorage
							local clonedSword = item:Clone()
							clonedSword.Parent = targetPlayer.Backpack
							item:Destroy()
						end
						model:Destroy()
					end
				elseif actionName == "Speed" then
					humanoid.WalkSpeed = 100
					task.delay(10, function()
						if humanoid then humanoid.WalkSpeed = 16 end
					end)
				elseif actionName == "Slow" then
					humanoid.WalkSpeed = 2
					task.delay(10, function()
						if humanoid then humanoid.WalkSpeed = 16 end
					end)
				elseif actionName == "Jump" then
					humanoid.JumpPower = 150
					humanoid.UseJumpPower = true
					task.delay(10, function()
						if humanoid then humanoid.JumpPower = 50 end
					end)
				elseif actionName == "Sit" then
					humanoid.Sit = true
				end
			end
			
			trollEvent:FireClient(targetPlayer, actionName, player.Name)
		end
	end
end)