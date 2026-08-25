local Marketplaceservice = game:GetService("MarketplaceService")
local Players = game:GetService("Players")

 
Marketplaceservice.ProcessReceipt = function(receiptInf)
    if receiptInf.ProductId == 3609650354 then -- replace the id with your developer product id
        -- replace this with your own logic (current logic kills everyone in the server)
        for _, player in ipairs(Players:GetPlayers()) do
            local character = player.Character 
            if character then
                local humanoid = character:FindFirstChildOfClass("Humanoid")
                if humanoid then
                    humanoid.Health = 0
                end
            end
        end    
        return Enum.ProductPurchaseDecision.PurchaseGranted
    end
    return Enum.ProductPurchaseDecision.NotProccesedYet
end
