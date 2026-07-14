local MPS = game:GetService("MarketplaceService")
local Players = game:GetService("Players")


MPS.PromptGamePassPurchaseFinished:Connect(function(player, id, purchased)
	if purchased and id == 12345 then -- replace with gamepass id
		for _, v in pairs(Players:GetPlayers()) do -- replace with your own logic (currently it kills everyone when bought)
			local char = v.Character
			if char and char:FindFirstChild("Humanoid") then
				char.Humanoid.Health = 0
			end
		end
	end
end)
