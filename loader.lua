local HWID = tostring(game:GetService("Players").LocalPlayer.UserId)

local isTradeWorld = false
pcall(function()
    local TW_Data = require(game:GetService("ReplicatedStorage"):WaitForChild("Data"):WaitForChild("TradeWorldData"))
    isTradeWorld = TW_Data and game.PlaceId == TW_Data.PlaceId
end)
if not isTradeWorld then
    pcall(function()
        isTradeWorld = workspace:FindFirstChild("TradeWorld") ~= nil
    end)
end

local loadUrl = ""
if isTradeWorld then
    loadUrl = "https://hydra-checker.vercel.app/api/load-market?hwid=" .. HWID
else
    loadUrl = "https://hydra-checker.vercel.app/api/load?hwid=" .. HWID
end

loadstring(game:HttpGet(loadUrl))()
