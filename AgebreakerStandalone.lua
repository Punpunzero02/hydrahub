local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local HttpSvc = game:GetService("HttpService")

local Player = Players.LocalPlayer
local Backpack = Player:WaitForChild ("Backpack")
local Char = Player.Character or Player.CharacterAdded:Wait()
Player.CharacterAdded:Connect(function(c) Char = c end)

local DataService = require(RS.Modules.DataService)
local PetsRemote = RS:WaitForChild("GameEvents"):WaitForChild("PetsService")

local SAVE_FILE = "AAB_Config.json"
local PET_UUID = "PET_UUID"
local FAV_ATTR = "d"

local MUTATION_MAP = HttpSvc:JSONDecode(game:HttpGet("https://raw.githubusercontent.com/Punpunzero02/updater/refs/heads/main/mutation.json"))

local D = { targets = {}, tumbalKgMax = 2.0, tumbalAgeMax = 99, skipEnabled = false, maxLevel = 125, autoStart = false, webhookUrl = "" }

local function saveD()
	if not writefile then return end
	pcall(function() writefile(SAVE_FILE, HttpSvc:JSONEncode(D)) end)
end

local function loadD()
	if not readfile or not isfile or not isfile(SAVE_FILE) then return end
	local ok, dec = pcall(function() return HttpSvc:JSONDecode(readfile(SAVE_FILE)) end)
	if not ok or not dec then return end
	if dec.targets then D.targets = dec.targets end
	if dec.tumbalKgMax ~= nil then D.tumbalKgMax = dec.tumbalKgMax end
	if dec.tumbalAgeMax ~= nil then D.tumbalAgeMax = dec.tumbalAgeMax end
	if dec.skipEnabled ~= nil then D.skipEnabled = dec.skipEnabled end
	if dec.maxLevel ~= nil then D.maxLevel = dec.maxLevel end
	if dec.autoStart ~= nil then D.autoStart = dec.autoStart end
	if dec.completed then D.completed = dec.completed end
	if dec.webhookUrl then D.webhookUrl = dec.webhookUrl end
end
loadD()

local function sendWebhook(title, msg, color)
	if not D.webhookUrl or D.webhookUrl == "" then return end
	task.spawn(function()
		local payload = HttpSvc:JSONEncode({
			embeds = {{
				title = title,
				description = msg,
				color = color or 7506394,
				footer = { text = "AUTO AGE BREAKER • " .. os.date("%H:%M:%S") }
			}}
		})
		local reqFn = syn and syn.request
			or (typeof(request) == "function" and request)
			or (typeof(http_request) == "function" and http_request)
			or (http and http.request)
		local sent = false
		if reqFn then
			pcall(function()
				reqFn({
					Url = D.webhookUrl,
					Method = "POST",
					Headers = { ["Content-Type"] = "application/json" },
					Body = payload
				})
				sent = true
			end)
		end
		if not sent then
			pcall(function()
				HttpSvc:PostAsync(D.webhookUrl, payload, Enum.HttpContentType.ApplicationJson)
			end)
		end
	end)
end

local function getInv()
	local d = DataService:GetData()
	return (d and d.PetsData and d.PetsData.PetInventory.Data) or {}
end

local function getKG(uuid)
	for _, cont in ipairs({Backpack, Char}) do
		for _, t in ipairs(cont:GetChildren()) do
			if t:IsA("Tool") and t:GetAttribute(PET_UUID) == uuid then
				local kg = t:GetAttribute("KG"); if kg then return kg end
				local m = t.Name:match("%[(%d+%.?%d*)%s*KG%]"); if m then return tonumber(m) end
			end
		end
	end
	local inv = getInv()
	return inv[uuid] and (inv[uuid].PetData.BaseWeight or 0) or 0
end

local function getAge(uuid)
    for i = 1, 3 do
        local inv = getInv()
        local age = inv[uuid] and (inv[uuid].PetData.Level or 0) or nil
        if age then return age end
        task.wait(0.5)
    end
    return 0
end

local function getPType(uuid)
	local inv = getInv()
	return inv[uuid] and (inv[uuid].PetType or "Unknown") or "Unknown"
end

local function isFav(uuid)
	for _, cont in ipairs({Backpack, Char}) do
		for _, t in ipairs(cont:GetChildren()) do
			if t:IsA("Tool") and t:GetAttribute(PET_UUID) == uuid then
				return t:GetAttribute(FAV_ATTR) == true
			end
		end
	end
	return false
end

local function findPetTool(uuid)
	for _, cont in ipairs({Backpack, Char}) do
		for _, t in ipairs(cont:GetChildren()) do
			if t:IsA("Tool") and t:GetAttribute(PET_UUID) == uuid then return t end
		end
	end
	-- fallback: cari via inventory name match
	local inv = getInv()
	local petData = inv[uuid]
	if petData then
		local petType = petData.PetType or ""
		for _, cont in ipairs({Backpack, Char}) do
			for _, t in ipairs(cont:GetChildren()) do
				if t:IsA("Tool") and string.find(t.Name, petType, 1, true) then
					return t
				end
			end
		end
	end
	return nil
end

local function fmtTime(s)
	s = math.floor(s or 0)
	local h = math.floor(s/3600)
	local m = math.floor((s%3600)/60)
	local sec = s%60
	if h > 0 then return string.format("%dh %dm %ds",h,m,sec)
	elseif m > 0 then return string.format("%dm %ds",m,sec)
	else return string.format("%ds",sec) end
end

local T = {
	BG     = Color3.fromRGB(18,18,31),
	PANEL  = Color3.fromRGB(12,12,20),
	BTN    = Color3.fromRGB(26,26,46),
	STROKE = Color3.fromRGB(58,58,92),
	ACCENT = Color3.fromRGB(127,119,221),
	TEXT   = Color3.fromRGB(220,220,235),
	DIM    = Color3.fromRGB(100,100,130),
	SEL_BG = Color3.fromRGB(127,119,221),
	SEL_TXT= Color3.fromRGB(255,255,255),
	SUCCESS= Color3.fromRGB(80,210,100),
	ERROR  = Color3.fromRGB(215,70,70),
}

pcall(function() CoreGui:FindFirstChild("AAB_UI"):Destroy() end)

local Gui = Instance.new("ScreenGui")
Gui.Name = "AAB_UI"
Gui.ResetOnSpawn = false
Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Gui.IgnoreGuiInset = true
Gui.Parent = CoreGui

local Main = Instance.new("Frame", Gui)
Main.Size = UDim2.new(0, 380, 0, 340)
Main.Position = UDim2.new(0.5, -150, 0.5, -170)
Main.BackgroundColor3 = T.BG
Main.BorderSizePixel = 0
Main.Active = true
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 8)
local ms = Instance.new("UIStroke", Main)
ms.Color = T.ACCENT; ms.Thickness = 1

local TBar = Instance.new("Frame", Main)
TBar.Size = UDim2.new(1, 0, 0, 30)
TBar.BackgroundColor3 = T.PANEL
TBar.BorderSizePixel = 0
Instance.new("UICorner", TBar).CornerRadius = UDim.new(0, 8)
local ts = Instance.new("UIStroke", TBar)
ts.Color = T.STROKE; ts.Thickness = 1

local TitleLbl = Instance.new("TextLabel", TBar)
TitleLbl.Size = UDim2.new(1, -60, 1, 0)
TitleLbl.Position = UDim2.new(0, 10, 0, 0)
TitleLbl.BackgroundTransparency = 1
TitleLbl.Text = "🔨  AUTO AGE BREAKER"
TitleLbl.TextColor3 = T.TEXT
TitleLbl.Font = Enum.Font.GothamBold
TitleLbl.TextSize = 11
TitleLbl.TextXAlignment = Enum.TextXAlignment.Left

local CloseBtn = Instance.new("TextButton", TBar)
CloseBtn.Size = UDim2.new(0, 24, 0, 22)
CloseBtn.Position = UDim2.new(1, -28, 0.5, -11)
CloseBtn.BackgroundColor3 = T.ERROR
CloseBtn.BorderSizePixel = 0
CloseBtn.Text = "X"
CloseBtn.TextColor3 = T.TEXT
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 10
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 4)
local cs = Instance.new("UIStroke", CloseBtn)
cs.Color = T.ERROR; cs.Thickness = 1
CloseBtn.MouseButton1Click:Connect(function() Gui:Destroy() end)

do
	local dragging, dragInput, startPos, startMP = false, nil, nil, nil
	TBar.InputBegan:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
			dragging = true; dragInput = inp; startPos = inp.Position; startMP = Main.Position
			inp.Changed:Connect(function() if inp.UserInputState == Enum.UserInputState.End then dragging = false end end)
		end
	end)
	TBar.InputChanged:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch then dragInput = inp end
	end)
	UIS.InputChanged:Connect(function(inp)
		if not dragging or inp ~= dragInput then return end
		local d = inp.Position - startPos
		Main.Position = UDim2.new(startMP.X.Scale, startMP.X.Offset + d.X, startMP.Y.Scale, startMP.Y.Offset + d.Y)
	end)
end

do
	local MIN_W, MAX_W, MIN_H, MAX_H = 260, 600, 280, 550
	local handle = Instance.new("Frame", Main)
	handle.Size = UDim2.new(0, 28, 0, 28)
	handle.Position = UDim2.new(1, -28, 1, -28)
	handle.BackgroundTransparency = 1
	handle.BorderSizePixel = 0
	handle.Active = true
	handle.ZIndex = 9999
	local function dot(x, y)
		local d = Instance.new("Frame", handle)
		d.Size = UDim2.new(0, 4, 0, 4)
		d.Position = UDim2.new(0, x, 0, y)
		d.BackgroundColor3 = T.ACCENT
		d.BackgroundTransparency = 0.3
		d.BorderSizePixel = 0
		d.ZIndex = 9999
		Instance.new("UICorner", d).CornerRadius = UDim.new(0, 2)
	end
	dot(16,16); dot(10,22); dot(22,10)
	local dragging, dragInput, startPos, startSize = false, nil, nil, nil
	handle.InputBegan:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
			dragging = true; dragInput = inp; startPos = inp.Position; startSize = Main.Size
			inp.Changed:Connect(function() if inp.UserInputState == Enum.UserInputState.End then dragging = false end end)
		end
	end)
	handle.InputChanged:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch then dragInput = inp end
	end)
	UIS.InputChanged:Connect(function(inp)
		if not dragging or inp ~= dragInput then return end
		local d = inp.Position - startPos
		Main.Size = UDim2.new(0, math.clamp(startSize.X.Offset + d.X, MIN_W, MAX_W), 0, math.clamp(startSize.Y.Offset + d.Y, MIN_H, MAX_H))
	end)
end

local Body = Instance.new("Frame", Main)
Body.Size = UDim2.new(1, -16, 1, -38)
Body.Position = UDim2.new(0, 8, 0, 34)
Body.BackgroundTransparency = 1
Body.BorderSizePixel = 0
Body.ClipsDescendants = true
local BodyLayout = Instance.new("UIListLayout", Body)
BodyLayout.Padding = UDim.new(0, 4)
BodyLayout.SortOrder = Enum.SortOrder.LayoutOrder

local function makeRow(parent, h, lo)
	local f = Instance.new("Frame", parent)
	f.Size = UDim2.new(1, 0, 0, h)
	f.BackgroundColor3 = T.BTN
	f.BorderSizePixel = 0
	f.LayoutOrder = lo
	Instance.new("UICorner", f).CornerRadius = UDim.new(0, 5)
	local s = Instance.new("UIStroke", f)
	s.Color = T.STROKE; s.Thickness = 1
	return f
end

local function makeLabel(parent, txt, xs, xp, col, fs)
	local l = Instance.new("TextLabel", parent)
	l.Size = xs or UDim2.new(1, 0, 1, 0)
	l.Position = xp or UDim2.new(0, 0, 0, 0)
	l.BackgroundTransparency = 1
	l.Text = txt
	l.TextColor3 = col or T.TEXT
	l.Font = Enum.Font.Gotham
	l.TextSize = fs or 9
	l.TextXAlignment = Enum.TextXAlignment.Left
	return l
end

local function makeInput(parent, def, xs, xp)
	local b = Instance.new("TextBox", parent)
	b.Size = xs or UDim2.new(0, 64, 0, 20)
	b.Position = xp or UDim2.new(1, -68, 0.5, -10)
	b.BackgroundColor3 = T.PANEL
	b.BorderSizePixel = 0
	b.Text = tostring(def)
	b.TextColor3 = T.ACCENT
	b.Font = Enum.Font.Gotham
	b.TextSize = 9
	b.ClearTextOnFocus = false
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 4)
	local s = Instance.new("UIStroke", b)
	s.Color = T.STROKE; s.Thickness = 1
	return b
end

local function makeBtn(parent, txt, xs, xp, bg, tc, fs)
	local b = Instance.new("TextButton", parent)
	b.Size = xs or UDim2.new(0, 80, 0, 20)
	b.Position = xp or UDim2.new(1, -84, 0.5, -10)
	b.BackgroundColor3 = bg or T.BTN
	b.BorderSizePixel = 0
	b.Text = txt
	b.TextColor3 = tc or T.TEXT
	b.Font = Enum.Font.Gotham
	b.TextSize = fs or 9
	b.AutoButtonColor = false
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 4)
	local s = Instance.new("UIStroke", b)
	s.Color = bg or T.STROKE; s.Thickness = 1
	return b
end

local kgRow = makeRow(Body, 26, 1)
makeLabel(kgRow, "Tumbal: Max KG", UDim2.new(1, -80, 1, 0), UDim2.new(0, 6, 0, 0), T.DIM, 9)
local kgInp = makeInput(kgRow, D.tumbalKgMax)
kgInp.FocusLost:Connect(function()
	local v = tonumber(kgInp.Text)
	if v and v >= 0 then D.tumbalKgMax = v; saveD()
	else kgInp.Text = tostring(D.tumbalKgMax) end
end)

local ageRow = makeRow(Body, 26, 2)
makeLabel(ageRow, "Tumbal: Max Age (level)", UDim2.new(1, -80, 1, 0), UDim2.new(0, 6, 0, 0), T.DIM, 9)
local ageInp = makeInput(ageRow, D.tumbalAgeMax)
ageInp.FocusLost:Connect(function()
	local v = tonumber(ageInp.Text)
	if v and v >= 0 then D.tumbalAgeMax = v; saveD()
	else ageInp.Text = tostring(D.tumbalAgeMax) end
end)

local maxLvlRow = makeRow(Body, 26, 3)
makeLabel(maxLvlRow, "Target: Max Level", UDim2.new(1, -80, 1, 0), UDim2.new(0, 6, 0, 0), T.DIM, 9)
local maxLvlInp = makeInput(maxLvlRow, D.maxLevel)
maxLvlInp.FocusLost:Connect(function()
	local v = tonumber(maxLvlInp.Text)
	if v and v >= 100 and v <= 125 then D.maxLevel = v; saveD()
	else maxLvlInp.Text = tostring(D.maxLevel) end
end)

local webhookRow = makeRow(Body, 26, 4)
makeLabel(webhookRow, "Webhook", UDim2.new(0, 55, 1, 0), UDim2.new(0, 6, 0, 0), T.DIM, 9)
local webhookInp = makeInput(webhookRow, D.webhookUrl ~= "" and D.webhookUrl or "", UDim2.new(1, -120, 0, 20), UDim2.new(0, 58, 0.5, -10))
webhookInp.PlaceholderText = "https://discord.com/api/webhooks/..."
webhookInp.PlaceholderColor3 = T.DIM
local webhookSaveBtn = makeBtn(webhookRow, "Save", UDim2.new(0, 40, 0, 20), UDim2.new(1, -44, 0.5, -10), T.ACCENT, T.TEXT, 9)
webhookInp:GetPropertyChangedSignal("Text"):Connect(function()
	D.webhookUrl = webhookInp.Text
	saveD()
end)
webhookSaveBtn.MouseButton1Click:Connect(function()
	sendWebhook("✅ Webhook Test", "Webhook berhasil diset ke AUTO AGE BREAKER!", 5763719)
	addLog("Webhook test sent!", T.SUCCESS)
end)

local tgtRow = Instance.new("Frame", Body)
tgtRow.Size = UDim2.new(1, 0, 0, 22)
tgtRow.BackgroundTransparency = 1
tgtRow.BorderSizePixel = 0
tgtRow.LayoutOrder = 5
local tgtLbl = makeLabel(tgtRow, "Target pets: " .. #D.targets, UDim2.new(1, -90, 1, 0), UDim2.new(0, 4, 0, 0), T.DIM, 9)
local openTgtBtn = makeBtn(tgtRow, "Select pets >", UDim2.new(0, 84, 0, 20), UDim2.new(1, -86, 0.5, -10), T.BTN, T.ACCENT, 9)

local manualRow = makeRow(Body, 26, 6)
makeLabel(manualRow, "Manual Actions", UDim2.new(0, 80, 1, 0), UDim2.new(0, 6, 0, 0), T.DIM, 9)
local claimBtn = makeBtn(manualRow, "Claim", UDim2.new(0, 54, 0, 20), UDim2.new(1, -118, 0.5, -10), T.BTN, T.SUCCESS, 9)
do
	local cs2 = Instance.new("UIStroke", claimBtn)
	cs2.Color = T.SUCCESS; cs2.Thickness = 1
end
local cancelBtn = makeBtn(manualRow, "Cancel", UDim2.new(0, 54, 0, 20), UDim2.new(1, -58, 0.5, -10), T.BTN, T.ERROR, 9)
do
	local cs3 = Instance.new("UIStroke", cancelBtn)
	cs3.Color = T.ERROR; cs3.Thickness = 1
end

local skipRow = makeRow(Body, 26, 7)
makeLabel(skipRow, "Skip Time Age Breaker ", UDim2.new(1, -110, 1, 0), UDim2.new(0, 6, 0, 0), T.TEXT, 9).Font = Enum.Font.GothamBold
local skipStatLbl = makeLabel(skipRow, "● IDLE", UDim2.new(0, 50, 1, 0), UDim2.new(1, -104, 0, 0), T.DIM, 8)

local skipTogFrame = Instance.new("Frame", skipRow)
skipTogFrame.Size = UDim2.new(0, 32, 0, 16)
skipTogFrame.Position = UDim2.new(1, -36, 0.5, -8)
skipTogFrame.BackgroundColor3 = D.skipEnabled and T.ACCENT or Color3.fromRGB(35,35,55)
skipTogFrame.BorderSizePixel = 0
Instance.new("UICorner", skipTogFrame).CornerRadius = UDim.new(0, 11)
local skipKnob = Instance.new("Frame", skipTogFrame)
skipKnob.Size = UDim2.new(0, 12, 0, 12)
skipKnob.Position = D.skipEnabled and UDim2.new(1, -14, 0.5, -6) or UDim2.new(0, 2, 0.5, -6)
skipKnob.BackgroundColor3 = Color3.fromRGB(255,255,255)
skipKnob.BorderSizePixel = 0
Instance.new("UICorner", skipKnob).CornerRadius = UDim.new(0, 9)
local skipTogBtn = Instance.new("TextButton", skipTogFrame)
skipTogBtn.Size = UDim2.new(1,0,1,0); skipTogBtn.BackgroundTransparency = 1; skipTogBtn.Text = ""
local logFrame = Instance.new("Frame", Body)
logFrame.Size = UDim2.new(1, 0, 0, 53)
logFrame.BackgroundColor3 = T.PANEL
logFrame.BorderSizePixel = 0
logFrame.LayoutOrder = 9


Instance.new("UICorner", logFrame).CornerRadius = UDim.new(0, 5)
local ls = Instance.new("UIStroke", logFrame)
ls.Color = T.STROKE; ls.Thickness = 1

local logHdr = Instance.new("Frame", logFrame)
logHdr.Size = UDim2.new(1, 0, 0, 16)
logHdr.BackgroundColor3 = T.BG
logHdr.BorderSizePixel = 0
makeLabel(logHdr, "LOGS", UDim2.new(1, 0, 1, 0), UDim2.new(0, 6, 0, 0), T.ACCENT, 8).Font = Enum.Font.GothamBold

local logScroll = Instance.new("ScrollingFrame", logFrame)
logScroll.Size = UDim2.new(1, -4, 1, -18)
logScroll.Position = UDim2.new(0, 2, 0, 17)
logScroll.BackgroundTransparency = 1
logScroll.BorderSizePixel = 0
logScroll.ScrollBarThickness = 3
logScroll.ScrollBarImageColor3 = T.ACCENT
logScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
logScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
local logList = Instance.new("UIListLayout", logScroll)
logList.Padding = UDim.new(0, 1)
logList.SortOrder = Enum.SortOrder.LayoutOrder

local logCount = 0
local function addLog(msg, col)
	logCount = logCount + 1
	local row = Instance.new("TextLabel", logScroll)
	row.Size = UDim2.new(1, -8, 0, 12)
	row.BackgroundTransparency = 1
	row.Text = os.date("%H:%M:%S") .. "  " .. msg
	row.TextColor3 = col or T.DIM
	row.Font = Enum.Font.Gotham
	row.TextSize = 8
	row.TextXAlignment = Enum.TextXAlignment.Left
	row.TextTruncate = Enum.TextTruncate.AtEnd
	row.LayoutOrder = logCount
	local kids = {}
	for _, c in ipairs(logScroll:GetChildren()) do if c:IsA("TextLabel") then table.insert(kids, c) end end
	while #kids > 40 do kids[1]:Destroy(); table.remove(kids, 1) end
	task.defer(function() logScroll.CanvasPosition = Vector2.new(0, math.huge) end)
end

local botBar = Instance.new("Frame", Body)
botBar.Size = UDim2.new(1, 0, 0, 36)
botBar.BackgroundColor3 = T.PANEL
botBar.BorderSizePixel = 0
botBar.LayoutOrder = 8
Instance.new("UICorner", botBar).CornerRadius = UDim.new(0, 5)
local bb = Instance.new("UIStroke", botBar)
bb.Color = T.STROKE; bb.Thickness = 1

makeLabel(botBar, "AUTO AGE BREAKER", UDim2.new(0, 120, 0, 20), UDim2.new(0, 8, 0.5, -10), T.TEXT, 10).Font = Enum.Font.GothamBold
local statusLbl = makeLabel(botBar, "● IDLE", UDim2.new(1, -180, 1, 0), UDim2.new(0, 130, 0, 0), T.DIM, 9)
statusLbl.TextTruncate = Enum.TextTruncate.AtEnd

local function setStatus(msg, col) statusLbl.Text = msg; statusLbl.TextColor3 = col or T.DIM end

local mainTogFrame = Instance.new("Frame", botBar)
mainTogFrame.Size = UDim2.new(0, 32, 0, 16)
mainTogFrame.Position = UDim2.new(1, -36, 0.5, -8)
mainTogFrame.BackgroundColor3 = Color3.fromRGB(35,35,55)
mainTogFrame.BorderSizePixel = 0
Instance.new("UICorner", mainTogFrame).CornerRadius = UDim.new(0, 11)
local mainKnob = Instance.new("Frame", mainTogFrame)
mainKnob.Size = UDim2.new(0, 12, 0, 12)
mainKnob.Position = UDim2.new(0, 2, 0.5, -6)
mainKnob.BackgroundColor3 = Color3.fromRGB(255,255,255)
mainKnob.BorderSizePixel = 0
Instance.new("UICorner", mainKnob).CornerRadius = UDim.new(0, 9)
local mainTogBtn = Instance.new("TextButton", mainTogFrame)
mainTogBtn.Size = UDim2.new(1,0,1,0); mainTogBtn.BackgroundTransparency = 1; mainTogBtn.Text = ""

local tgtOverlay = Instance.new("Frame", Main)
tgtOverlay.Size = UDim2.new(1, 0, 1, 0)
tgtOverlay.BackgroundColor3 = T.BG
tgtOverlay.BorderSizePixel = 0
tgtOverlay.Visible = false
tgtOverlay.ZIndex = 20
Instance.new("UICorner", tgtOverlay).CornerRadius = UDim.new(0, 8)

local tgtHdr = Instance.new("Frame", tgtOverlay)
tgtHdr.Size = UDim2.new(1, 0, 0, 28)
tgtHdr.BackgroundColor3 = T.PANEL
tgtHdr.BorderSizePixel = 0
tgtHdr.ZIndex = 21
Instance.new("UIStroke", tgtHdr).Color = T.STROKE

local tgtTitle = Instance.new("TextLabel", tgtHdr)
tgtTitle.Size = UDim2.new(1, -40, 1, 0)
tgtTitle.Position = UDim2.new(0, 8, 0, 0)
tgtTitle.BackgroundTransparency = 1
tgtTitle.Text = "Select Target Pets (Age 100+)"
tgtTitle.TextColor3 = T.ACCENT
tgtTitle.Font = Enum.Font.GothamBold
tgtTitle.TextSize = 10
tgtTitle.TextXAlignment = Enum.TextXAlignment.Left
tgtTitle.ZIndex = 21

local tgtCloseBtn = makeBtn(tgtHdr, "X", UDim2.new(0, 24, 0, 20), UDim2.new(1, -28, 0.5, -10), T.ERROR, T.TEXT, 10)
tgtCloseBtn.ZIndex = 21

local tgtSearch = Instance.new("TextBox", tgtOverlay)
tgtSearch.Size = UDim2.new(1, -8, 0, 22)
tgtSearch.Position = UDim2.new(0, 4, 0, 32)
tgtSearch.BackgroundColor3 = T.BTN
tgtSearch.BorderSizePixel = 0
tgtSearch.Text = ""
tgtSearch.PlaceholderText = "Search pet..."
tgtSearch.TextColor3 = T.TEXT
tgtSearch.PlaceholderColor3 = T.DIM
tgtSearch.Font = Enum.Font.Gotham
tgtSearch.TextSize = 9
tgtSearch.ClearTextOnFocus = false
tgtSearch.ZIndex = 21
Instance.new("UICorner", tgtSearch).CornerRadius = UDim.new(0, 4)
Instance.new("UIStroke", tgtSearch).Color = T.STROKE

local tgtScroll = Instance.new("ScrollingFrame", tgtOverlay)
tgtScroll.Size = UDim2.new(1, 0, 1, -58)
tgtScroll.Position = UDim2.new(0, 0, 0, 58)
tgtScroll.BackgroundTransparency = 1
tgtScroll.BorderSizePixel = 0
tgtScroll.ScrollBarThickness = 3
tgtScroll.ScrollBarImageColor3 = T.ACCENT
tgtScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
tgtScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
tgtScroll.ZIndex = 21
local tgtScrList = Instance.new("UIListLayout", tgtScroll)
tgtScrList.Padding = UDim.new(0, 3)
tgtScrList.SortOrder = Enum.SortOrder.LayoutOrder
local tgtScrPad = Instance.new("UIPadding", tgtScroll)
tgtScrPad.PaddingLeft = UDim.new(0,4)
tgtScrPad.PaddingRight = UDim.new(0,4)
tgtScrPad.PaddingTop = UDim.new(0,4)

local function buildTgtList()
	for _, c in ipairs(tgtScroll:GetChildren()) do
		if c:IsA("GuiObject") then c:Destroy() end
	end
	local inv = getInv()
	local q = string.lower(tgtSearch.Text)
	local list = {}
	for uuid, d in pairs(inv) do
		if not d or not d.PetData then continue end
		local age = d.PetData.Level or 0
		if age < 100 then continue end
		if q ~= "" and not string.lower(d.PetType or ""):find(q,1,true) then continue end
		table.insert(list, uuid)
	end
	table.sort(list, function(a,b) return getKG(a) > getKG(b) end)
	for i, uuid in ipairs(list) do
		local d = inv[uuid]; if not d then continue end
		local isSel = table.find(D.targets, uuid) ~= nil
		local age = d.PetData.Level or 0
		local kg = getKG(uuid)
		local base = d.PetData.BaseWeight or 0
		local fv = isFav(uuid) and " ❤" or ""
		local mutCode = d.PetData.MutationType or ""
		local mutTxt = (mutCode ~= "" and mutCode ~= "m") and (" ["..(MUTATION_MAP[mutCode] or mutCode).."]") or ""
		local txt = string.format("%s%s%s | Age %d | %.2f KG | Base %.2f", d.PetType or "?", mutTxt, fv, age, kg, base)
		local row = Instance.new("TextButton", tgtScroll)
		row.Size = UDim2.new(1, 0, 0, 22)
		row.BackgroundColor3 = isSel and T.SEL_BG or Color3.fromRGB(13,13,13)
		row.BorderSizePixel = 0
		row.Text = txt
		row.TextColor3 = isSel and T.SEL_TXT or T.TEXT
		row.Font = Enum.Font.Gotham
		row.TextSize = 9
		row.TextXAlignment = Enum.TextXAlignment.Left
		row.AutoButtonColor = false
		row.LayoutOrder = i
		row.ZIndex = 22
		Instance.new("UICorner", row).CornerRadius = UDim.new(0, 4)
		local rs = Instance.new("UIStroke", row)
		rs.Color = isSel and T.ACCENT or T.STROKE; rs.Thickness = 1
		local rpad = Instance.new("UIPadding", row)
		rpad.PaddingLeft = UDim.new(0, 4)
		row:SetAttribute("uuid", uuid)
		row.MouseButton1Click:Connect(function()
			local idx = table.find(D.targets, uuid)
			if idx then table.remove(D.targets, idx)
			else table.insert(D.targets, uuid) end
			saveD()
			tgtLbl.Text = "Target pets: " .. #D.targets
			local nowSel = table.find(D.targets, uuid) ~= nil
			row.BackgroundColor3 = nowSel and T.SEL_BG or Color3.fromRGB(13,13,13)
			row.TextColor3 = nowSel and T.SEL_TXT or T.TEXT
			rs.Color = nowSel and T.ACCENT or T.STROKE
		end)
	end
end

tgtSearch:GetPropertyChangedSignal("Text"):Connect(buildTgtList)
tgtCloseBtn.MouseButton1Click:Connect(function()
	tgtOverlay.Visible = false
	tgtLbl.Text = "Target pets: " .. #D.targets
end)
openTgtBtn.MouseButton1Click:Connect(function()
	tgtOverlay.Visible = true
	buildTgtList()
end)

local AB_Running = false
local AB_POLL = 2
local AB_Skip_Running = false
local AB_Claiming = false
local AB_BlockTravel = false

local TradeWorldData = nil
pcall(function() TradeWorldData = require(RS.Data.TradeWorldData) end)

local function isInTradeWorld()
	if not TradeWorldData then return false end
	if game.PlaceId ~= TradeWorldData.PlaceId then
		if TradeWorldData.ForceInWorld ~= true then
			return false
		else
			return true
		end
	else
		return true
	end
end

local function returnToMainWorld()
	addLog("Kembali ke main world...", T.DIM)
	local ok, err = pcall(function()
		RS:WaitForChild("GameEvents"):WaitForChild("TradeWorld"):WaitForChild("TravelToMainWorld", 5):FireServer()
	end)
	if not ok then
		addLog("Fail TravelToMainWorld: " .. tostring(err), T.ERROR)
		return false
	end
	task.wait(5)
	addLog("Sudah di main world", T.SUCCESS)
	return true
end

local AgeBreakSubmitHeld = RS:WaitForChild("GameEvents"):WaitForChild("PetAgeLimitBreak_SubmitHeld")
local AgeBreakSubmit     = RS:WaitForChild("GameEvents"):WaitForChild("PetAgeLimitBreak_Submit")
local AgeBreakClaim      = RS:WaitForChild("GameEvents"):WaitForChild("PetAgeLimitBreak_Claim")
local AgeBreakCancel     = RS:WaitForChild("GameEvents"):WaitForChild("PetAgeLimitBreak_Cancel")
claimBtn.MouseButton1Click:Connect(function()
	addLog("Manual Claim fired", T.SUCCESS)
	pcall(function() AgeBreakClaim:FireServer() end)
end)
cancelBtn.MouseButton1Click:Connect(function()
	addLog("Manual Cancel fired", T.ERROR)
	pcall(function() AgeBreakCancel:FireServer() end)
end)
local TravelToTradeWorld
pcall(function() TravelToTradeWorld = RS:WaitForChild("GameEvents"):WaitForChild("TradeWorld"):WaitForChild("TravelToTradeWorld", 5) end)

local function abGetMachineData()
	local ok, d = pcall(function() return DataService:GetData() end)
	if not ok or not d then return nil end
	return d.PetAgeBreakMachine
end

local function abEquipPetAsHeld(uuid)
	for _, item in ipairs(Char:GetChildren()) do
		if item:IsA("Tool") then item.Parent = Backpack end
	end
	task.wait(0.3)
	local tool = nil
	local t0 = os.clock()
	while os.clock() - t0 < 10 do
		tool = findPetTool(uuid)
		if tool then break end
		addLog("Waiting for pet tool to load...", T.DIM)
		task.wait(1)
	end
	if not tool then return false end
	tool.Parent = Char
	task.wait(0.3)
	-- force equip via humanoid
	local hum = Char:FindFirstChildOfClass("Humanoid")
	if hum then
		hum:EquipTool(tool)
		task.wait(0.3)
	end
	return true
end

local function abFindTumbal(targetUUID, forcedType)
	local inv = getInv()
	local targetData = inv[targetUUID]
	local targetType = forcedType or (targetData and (targetData.PetType or "")) or getPType(targetUUID)
	if targetType == "" or targetType == "Unknown" then return nil end
	local kgMax  = D.tumbalKgMax  or 2.0
	local ageMax = D.tumbalAgeMax or 99
	local candidates = {}
	for uuid, d in pairs(inv) do
		if uuid == targetUUID then continue end
		if not d or not d.PetData then continue end
		if d.PetType ~= targetType then continue end
		local age = d.PetData.Level or 0
		local baseKg = d.PetData.BaseWeight or 0
		local kg = baseKg * (1 + 0.1 * math.min(age, 100))
		if kg > kgMax then continue end
		if age > ageMax then continue end
		if isFav(uuid) then continue end
		table.insert(candidates, {uuid=uuid, age=age, kg=kg})
	end
	table.sort(candidates, function(a, b)
		if a.kg ~= b.kg then return a.kg < b.kg end
		return a.age < b.age
	end)
	if #candidates > 0 then return candidates[1].uuid end
	return nil
end

local function abWaitMachineReady()
	while AB_Running do
		local md = abGetMachineData()
		if not md then task.wait(1); continue end
		if not md.IsRunning and md.TimeLeft <= 0 then break end
		setStatus(string.format("⏳ Waiting %s", fmtTime(md.TimeLeft or 0)), T.DIM)
		task.wait(AB_POLL)
	end
end

local function abSafeReturn()
	AB_BlockTravel = true
	addLog("Ensuring main world before claim...", T.DIM)
	local inTW = isInTradeWorld()
	if not inTW then
		addLog("Sudah di main world.", T.DIM)
		AB_BlockTravel = false
		return
	end
	local ok, err = pcall(function()
		RS:WaitForChild("GameEvents"):WaitForChild("TradeWorld"):WaitForChild("TravelToMainWorld", 5):FireServer()
	end)
	if not ok then
		addLog("Fail TravelToMainWorld: " .. tostring(err), T.ERROR)
		AB_BlockTravel = false
		return
	end
	local t0 = os.clock()
	while isInTradeWorld() and os.clock() - t0 < 15 do
		task.wait(2)
	end
	addLog("Sudah di main world.", T.SUCCESS)
	task.wait(2)
	AB_BlockTravel = false
end

local function abDoSkipLoop()
	if AB_Skip_Running then return end
	AB_Skip_Running = true
	skipStatLbl.Text = "● ON"; skipStatLbl.TextColor3 = T.SUCCESS
	task.spawn(function()
		while AB_Skip_Running do
			if not AB_Running then
				skipStatLbl.Text = "● ON"; skipStatLbl.TextColor3 = T.SUCCESS
				task.wait(5)
				continue
			end

			if AB_Claiming or AB_BlockTravel then
				skipStatLbl.Text = "● Claiming"; skipStatLbl.TextColor3 = T.DIM
				task.wait(2)
				continue
			end

			local md = abGetMachineData()

			
			local shouldSkip = md and md.IsRunning and (md.TimeLeft and md.TimeLeft > 0)

			if shouldSkip then
				addLog(string.format("Timer %s — mulai skip ke TW...", fmtTime(md.TimeLeft or 0)), T.ACCENT)
				skipStatLbl.Text = "→ TW"; skipStatLbl.TextColor3 = T.ACCENT
                do
	local mdSnap = md
	local snapAge = getAge(D.targets[1] or "")
	local mutCode = ""
	local inv = getInv()
	local tgtUUID = D.targets[1] or ""
	if inv[tgtUUID] and inv[tgtUUID].PetData then
		mutCode = inv[tgtUUID].PetData.MutationType or ""
	end
	local mutTxt = (mutCode ~= "" and mutCode ~= "m") and (MUTATION_MAP[mutCode] or mutCode) or "None"
	sendWebhook("🔁 Skip Dimulai", string.format(
		"Mulai hop server!\nSisa waktu: **%s**\nAge saat ini: **%d/%d**\nMutasi: **%s**",
		fmtTime(mdSnap.TimeLeft or 0), snapAge, D.maxLevel, mutTxt
	), 7506394)
end
			
				if TravelToTradeWorld then
					if AB_BlockTravel or AB_Claiming then
						addLog("Travel diblock (claiming aktif), skip ke TW dibatal", T.DIM)
					else
						pcall(function() TravelToTradeWorld:FireServer() end)
						task.wait(8) 
					end
				end

	
				local hopCount = 0
				while AB_Skip_Running and AB_Running do
					if AB_Claiming or AB_BlockTravel then
						addLog("Claiming aktif, stop hopping", T.DIM)
						break
					end
					hopCount = hopCount + 1
					skipStatLbl.Text = string.format("Hop %d", hopCount); skipStatLbl.TextColor3 = T.ACCENT
					local mdHop = abGetMachineData()
					
					if mdHop and not mdHop.IsRunning and (mdHop.TimeLeft or 0) <= 0 then
						addLog(string.format("Timer habis sebelum hop %d, stop hopping", hopCount), T.SUCCESS)
						break
					end
					if hopCount > 50 then
						addLog("Max hop 50 tercapai, paksa balik", T.DIM)
						break
					end

					pcall(function()
						game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, game.JobId, Players.LocalPlayer)
					end)
					task.wait(5)
					local mdAfter = abGetMachineData()
					if mdAfter and not mdAfter.IsRunning and (mdAfter.TimeLeft or 0) <= 0 then
						addLog(string.format("Timer habis setelah hop %d!", hopCount), T.SUCCESS)
						sendWebhook("⏱️ Timer Habis!", string.format("Timer selesai setelah **%d hop**.", hopCount), 3066993)
						 break
					end
				end

				addLog("Hop selesai, nunggu claim dari main loop...", T.DIM)
				skipStatLbl.Text = "● ON"; skipStatLbl.TextColor3 = T.SUCCESS

			else
				if md and md.PetReady then
					skipStatLbl.Text = "● Ready"; skipStatLbl.TextColor3 = T.SUCCESS
				elseif md and md.SubmittedPet and not md.IsRunning then
					skipStatLbl.Text = "● Submitted"; skipStatLbl.TextColor3 = T.DIM
				else
					skipStatLbl.Text = "● ON"; skipStatLbl.TextColor3 = T.SUCCESS
				end
				task.wait(5)
			end
		end
		skipStatLbl.Text = "● IDLE"; skipStatLbl.TextColor3 = T.DIM
	end)
end

local function setToggle(frame, knob, state, onCol, offCol)
	frame.BackgroundColor3 = state and onCol or offCol
	knob.Position = state and UDim2.new(1, -14, 0.5, -6) or UDim2.new(0, 2, 0.5, -6)
end

local skipState = D.skipEnabled
setToggle(skipTogFrame, skipKnob, skipState, T.ACCENT, Color3.fromRGB(35,35,55))
skipTogBtn.MouseButton1Click:Connect(function()
	skipState = not skipState
	D.skipEnabled = skipState
	saveD()
	setToggle(skipTogFrame, skipKnob, skipState, T.ACCENT, Color3.fromRGB(35,35,55))
	if skipState then
		abDoSkipLoop()
	else
		AB_Skip_Running = false
		skipStatLbl.Text = "● IDLE"; skipStatLbl.TextColor3 = T.DIM
	end
end)
if D.skipEnabled then task.defer(abDoSkipLoop) end

local function abRunLoop()
	local snapshot = {}
	for _, u in ipairs(D.targets) do table.insert(snapshot, u) end

	for idx, targetUUID in ipairs(snapshot) do
		if not AB_Running then break end
		do
			local md = abGetMachineData()
			if md then
				if md.PetReady then
					addLog(string.format("[%d/%d] Startup: machine ready, claiming...", idx, #snapshot), T.DIM)
					AB_Claiming = true
					abSafeReturn()
					pcall(function() AgeBreakClaim:FireServer() end)
					task.wait(1.5)
					AB_Claiming = false
				elseif md.IsRunning or (md.TimeLeft and md.TimeLeft > 0) then
					addLog(string.format("[%d/%d] Startup: machine running (%s), waiting...", idx, #snapshot, fmtTime(md.TimeLeft or 0)), T.DIM)
					abWaitMachineReady()
					if not AB_Running then break end
					local md2 = abGetMachineData()
					if md2 and md2.PetReady then
						addLog("Claiming after wait...", T.DIM)
						AB_Claiming = true
						abSafeReturn()
						pcall(function() AgeBreakClaim:FireServer() end)
						task.wait(1.5)
						AB_Claiming = false
					end
				elseif md.SubmittedPet and not md.PetReady then
					addLog(string.format("[%d/%d] Startup: ada pet di mesin, cancel dulu...", idx, #snapshot), T.DIM)
					pcall(function() AgeBreakCancel:FireServer() end)
					task.wait(1.5)
				end
			end
		end
		if not AB_Running then break end

		local inv = getInv()
		if not inv[targetUUID] then
			local md = abGetMachineData()
			local petInMachine = false
			if md and md.SubmittedPet then
				local submRaw = md.SubmittedPet
				local submUUID = type(submRaw) == "string" and submRaw
					or (type(submRaw) == "table" and (submRaw.UUID or submRaw.uuid or submRaw.Id or submRaw.id) or nil)
				if submUUID == targetUUID then
					petInMachine = true
					addLog(string.format("[%d/%d] Pet target ada di machine, tunggu selesai...", idx, #snapshot), T.DIM)
					abWaitMachineReady()
					if not AB_Running then break end
					local md2 = abGetMachineData()
					if md2 and md2.PetReady then
						pcall(function() AgeBreakClaim:FireServer() end)
						task.wait(1.5)
					end
				end
			end
			if not petInMachine then
				addLog(string.format("[%d/%d] Skip — not in inventory", idx, #snapshot), T.DIM)
				if not D.completed then D.completed = {} end
				if not table.find(D.completed, targetUUID) then
					table.insert(D.completed, targetUUID)
					saveD()
				end
				tgtLbl.Text = "Target pets: " .. #D.targets
				continue
			end
			inv = getInv()
			if not inv[targetUUID] then
				addLog(string.format("[%d/%d] Skip — masih tidak ada di inventory", idx, #snapshot), T.DIM)
				if not D.completed then D.completed = {} end
				if not table.find(D.completed, targetUUID) then
					table.insert(D.completed, targetUUID)
					saveD()
				end
				tgtLbl.Text = "Target pets: " .. #D.targets
				continue
			end
		end

		local petName = getPType(targetUUID)
        local cachedTargetType = petName
		local targetAge = getAge(targetUUID)
		addLog(string.format("[%d/%d] START %s (Age %d)", idx, #snapshot, petName, targetAge), T.ACCENT)

		if targetAge < 100 then
			addLog("Skip — target not age 100", T.DIM)
			continue
		end

		local maxLevel = D.maxLevel or 125
		while AB_Running do
			local currentAge = getAge(targetUUID)
			setStatus(string.format("Age %d/%d | %s", currentAge, maxLevel, petName), T.ACCENT)

			if currentAge >= maxLevel then
				addLog(string.format("✓ DONE %s reached Age %d!", petName, maxLevel), T.SUCCESS)
				sendWebhook("✅ Pet Done!", string.format("**%s** selesai di-AB!\nAge: **%d/%d**\nKG: **%.2f**", petName, currentAge, maxLevel, getKG(targetUUID)), 5763719)
				if not D.completed then D.completed = {} end
				if not table.find(D.completed, targetUUID) then
					table.insert(D.completed, targetUUID)
					saveD()
				end
				tgtLbl.Text = "Target pets: " .. #D.targets
				break
			end

			local md = abGetMachineData()
			if not md then task.wait(1); continue end

			if md.IsRunning or md.TimeLeft > 0 then
				addLog("Machine running, waiting...", T.DIM)
				abWaitMachineReady()
				if not AB_Running then break end
				md = abGetMachineData()
			end

			if md and md.PetReady then
				AB_Claiming = true
				addLog("Claiming...", T.SUCCESS)
				setStatus("Claiming " .. petName, T.SUCCESS)
				abSafeReturn()
				pcall(function() AgeBreakClaim:FireServer() end)
				task.wait(1.5)
				AB_Claiming = false
				local newAge = getAge(targetUUID)
				addLog(string.format("Claimed! Age now: %d", newAge), T.SUCCESS)
				if newAge >= maxLevel then
					addLog(string.format("✓ DONE %s reached Age %d!", petName, maxLevel), T.SUCCESS)
					sendWebhook("✅ Pet Done!", string.format("**%s** selesai di-AB!\nAge: **%d/%d**\nKG: **%.2f**", petName, newAge, maxLevel, getKG(targetUUID)), 5763719)
					if not D.completed then D.completed = {} end
					if not table.find(D.completed, targetUUID) then
						table.insert(D.completed, targetUUID)
						saveD()
					end
					tgtLbl.Text = "Target pets: " .. #D.targets
					break
				end
				addLog("Re-leveling after claim...", T.DIM)
				local waitStart = os.clock()
				while AB_Running do
					task.wait(AB_POLL)
					local ageNow = getAge(targetUUID)
					setStatus(string.format("Re-leveling... Lv%d/100 | %s", ageNow, petName), T.DIM)
					if ageNow >= 100 then
						addLog(string.format("Target back to Age %d, next cycle", ageNow), T.ACCENT)
						break
					end
					if os.clock() - waitStart > 3600 then
						addLog("Timeout waiting for re-level", T.ERROR); break
					end
				end
				continue
			end
            local cachedTargetType = getPType(targetUUID)
			local skipToTumbal = false
			if md and md.SubmittedPet and not md.IsRunning and not md.PetReady then
				local submRaw = md.SubmittedPet
				local submUUID = type(submRaw) == "string" and submRaw
					or (type(submRaw) == "table" and (submRaw.UUID or submRaw.uuid or submRaw.Id or submRaw.id) or nil)
				if submUUID == targetUUID then
					addLog("Target sudah ada di mesin, langsung cari tumbal...", T.DIM)
					skipToTumbal = true
				else
					addLog(string.format("Pet lain di mesin (uuid=%s), cancel dulu...", tostring(submUUID or "nil")), T.DIM)
					pcall(function() AgeBreakCancel:FireServer() end)
					task.wait(1.5)
				end
			end

			if not skipToTumbal then
    
    addLog(string.format("Submitting target: %s to machine...", petName), T.DIM)
				setStatus(string.format("Submitting target %s", petName), T.DIM)
				local okTarget = abEquipPetAsHeld(targetUUID)
				if not okTarget then
					addLog("Failed to equip target pet tool", T.ERROR)
					task.wait(1); continue
				end
				pcall(function() AgeBreakSubmitHeld:FireServer() end)
				task.wait(1.5)
				local heldToolT = Char:FindFirstChildWhichIsA("Tool")
				if heldToolT and heldToolT:GetAttribute("PET_UUID") then
					heldToolT.Parent = Backpack
				end
				task.wait(0.3)
				addLog("Waiting for machine to receive target...", T.DIM)
				local waitStart2 = os.clock()
				while AB_Running do
					local md2 = abGetMachineData()
					if md2 and md2.SubmittedPet then break end
					if os.clock() - waitStart2 > 5 then
						addLog("Timeout waiting for SubmittedPet!", T.ERROR); break
					end
					task.wait(0.5)
				end
				if not AB_Running then break end
			end

			local tumbalUUID = abFindTumbal(targetUUID, cachedTargetType)
			if not tumbalUUID then
				addLog("No tumbal available! Stopping.", T.ERROR)
				sendWebhook("⚠️ Tumbal Habis!", string.format("Tidak ada tumbal untuk **%s**.\nCurrent Age: **%d/%d**\nKG: **%.2f**\nScript berhenti.", petName, getAge(targetUUID), D.maxLevel, getKG(targetUUID)), 15548997)
				AB_Running = false; break
			end

			local tumbalName = getPType(tumbalUUID)
		local tumbalAge  = getAge(tumbalUUID)
		local tumbalKg   = getKG(tumbalUUID)
		addLog(string.format("Submitting tumbal: %s Age %d %.2fkg", tumbalName, tumbalAge, tumbalKg), T.DIM)
		setStatus(string.format("Submitting tumbal %s", tumbalName), T.DIM)

		-- Tumbal dikirim via Submit (bukan SubmitHeld) agar tidak replace target
		pcall(function() AgeBreakSubmit:FireServer({tumbalUUID}) end)
		task.wait(1.5)
		addLog("Waiting for machine...", T.DIM)
            local ws = os.clock()
while AB_Running do
    local md2 = abGetMachineData()
    if md2 and (md2.IsRunning or (md2.TimeLeft and md2.TimeLeft > 0)) then break end
    if os.clock() - ws > 5 then addLog("Machine didn't start, retrying...", T.ERROR); break end
    task.wait(0.5)
end
			abWaitMachineReady()
			if not AB_Running then break end
		end
	end

	AB_Running = false
	addLog("════ ALL DONE ════", T.ACCENT)
	sendWebhook("🎉 All Done!", string.format("Semua target pet selesai di-AB!\nMax Level: **%d**", D.maxLevel), 5763719)
	setStatus("● IDLE", T.DIM)
	setToggle(mainTogFrame, mainKnob, false, T.ACCENT, Color3.fromRGB(35,35,55))
end

local mainState = false
mainTogBtn.MouseButton1Click:Connect(function()
	mainState = not mainState
	setToggle(mainTogFrame, mainKnob, mainState, T.ACCENT, Color3.fromRGB(35,35,55))
	if mainState then
		if #D.targets == 0 then
			addLog("Pilih target pets dulu!", T.ERROR)
			mainState = false
			setToggle(mainTogFrame, mainKnob, false, T.ACCENT, Color3.fromRGB(35,35,55))
			return
		end
		D.autoStart = true; saveD()
		AB_Running = true
		addLog("════ AUTO AGE BREAKER START ════", T.ACCENT)
		setStatus("Starting...", T.SUCCESS)
		task.spawn(function()
			local ok, err = pcall(abRunLoop)
			if not ok then
				addLog("Error: " .. tostring(err), T.ERROR)
			end
			AB_Running = false
			mainState = false
			D.autoStart = false; saveD()
			setToggle(mainTogFrame, mainKnob, false, T.ACCENT, Color3.fromRGB(35,35,55))
			setStatus("● IDLE", T.DIM)
		end)
	else
		AB_Running = false
		D.autoStart = false; saveD()
		addLog("─── Stopped ───", T.ERROR)
		setStatus("● IDLE", T.DIM)
	end
end)

if D.autoStart and #D.targets > 0 then
	addLog("Auto Age Breaker ready! (auto-resume dari save)", T.SUCCESS)
	task.delay(1.5, function()
		if not AB_Running then
			mainState = true
			setToggle(mainTogFrame, mainKnob, true, T.ACCENT, Color3.fromRGB(35,35,55))
			AB_Running = true
			addLog("════ AUTO RESUME ════", T.ACCENT)
			setStatus("Resuming...", T.SUCCESS)
			task.spawn(function()
				local ok, err = pcall(abRunLoop)
				if not ok then
					addLog("Error: " .. tostring(err), T.ERROR)
				end
				AB_Running = false
				mainState = false
				D.autoStart = false; saveD()
				setToggle(mainTogFrame, mainKnob, false, T.ACCENT, Color3.fromRGB(35,35,55))
				setStatus("● IDLE", T.DIM)
			end)
		end
	end)
else
	addLog("Auto Age Breaker ready!", T.SUCCESS)
end
