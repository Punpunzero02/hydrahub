if _G.HydraLoaded then return end
_G.HydraLoaded = true

local HWID = "unknown"
pcall(function()
    HWID = tostring(game:GetService("RbxAnalyticsService"):GetClientId())
end)
if HWID == "unknown" or HWID == "" then
    HWID = tostring(game:GetService("Players").LocalPlayer.UserId)
end

print("HWID: " .. HWID)
print("HWID len: " .. #HWID)

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

print("URL: " .. loadUrl)

local ok, res = pcall(function()
    return game:HttpGet(loadUrl)
end)

if not ok or not res or res == "return" or #res < 10 then
    warn("fetch failed: ok=" .. tostring(ok) .. " res=" .. tostring(res))
    return
end

print("res len: " .. #res)

local fn, err = loadstring(res)
if not fn then
    warn("loadstring error: " .. tostring(err))
    return
end

task.wait(2)
fn()
