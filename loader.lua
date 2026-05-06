if getgenv().HydraLoaded then return end
getgenv().HydraLoaded = true

local HWID = tostring(game:GetService("RbxAnalyticsService"):GetClientId())

local ok, res = pcall(function()
    return game:HttpGet("https://hydra-checker.vercel.app/api/load?hwid=" .. HWID)
end)

if not ok or not res or res == "return" or #res < 10 then
    return
end


task.wait(40) 

loadstring(res)()
