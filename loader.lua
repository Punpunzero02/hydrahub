if getenv().HydraLoaded then return end
getenv().HydraLoaded = true

local HWID = tostring(game:GetService("RbxAnalyticsService"):GetClientId())

-- Deteksi trade world
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

local ok, res = pcall(function()
    return game:HttpGet(loadUrl)
end)

if not ok or not res or res == "return" or #res < 10 then
    return
end

task.wait(2)

loadstring(res)()
