

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

if not isfolder("HydraHub") then makefolder("HydraHub") end
if not isfolder("HydraHub/Config") then makefolder("HydraHub/Config") end

local gameName = tostring(game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name)
gameName = gameName:gsub("[^%w_ ]", "")
gameName = gameName:gsub("%s+", "_")

local ConfigFile = "HydraHub/Config/" .. gameName .. ".json"
local ConfigFolder = "HydraHub/Configs"
local GameConfigFolder = ConfigFolder .. "/" .. gameName

ConfigData = {}
Elements = {}
CURRENT_VERSION = nil
ActiveConfigName = nil
ActiveConfigPath = nil
ActiveConfigMode = nil
AutoSaveEnabled = true
ApplyingConfig = false
SaveQueued = false

local InternalConfigKeys = {
    ["Input_Config Name"] = true,
    ["Dropdown_Saved Configs"] = true,
    ["Toggle_Auto Load"] = true,
}

local function CopyConfigValue(value, seen)
    if type(value) ~= "table" then return value end
    seen = seen or {}
    if seen[value] then return seen[value] end
    local copy = {}
    seen[value] = copy
    for k, v in pairs(value) do
        copy[CopyConfigValue(k, seen)] = CopyConfigValue(v, seen)
    end
    return copy
end

function GetConfigSnapshot()
    local snapshot = {}
    for key, value in pairs(ConfigData or {}) do
        if key ~= "_version" and not InternalConfigKeys[key] then
            snapshot[key] = CopyConfigValue(value)
        end
    end
    for key, element in pairs(Elements or {}) do
        if element and element.Value ~= nil then
            snapshot[key] = CopyConfigValue(element.Value)
        end
    end
    snapshot._version = CURRENT_VERSION
    return snapshot
end

function SetActiveConfig(name, path, autoSave, mode)
    ActiveConfigName = name
    ActiveConfigPath = path
    if mode ~= nil then ActiveConfigMode = mode
    elseif name == nil then ActiveConfigMode = nil end
    if autoSave ~= nil then AutoSaveEnabled = autoSave end
end

function SaveConfig(force)
    if not writefile or not CURRENT_VERSION then return false end
    if ApplyingConfig and not force then return false end
    if not force and not AutoSaveEnabled then return false end
    local target = ActiveConfigPath or ConfigFile
    if not target or target == "" then return false end
    ConfigData = GetConfigSnapshot()
    writefile(target, HttpService:JSONEncode(ConfigData))
    return true
end

function QueueSaveConfig(force)
    if force then return SaveConfig(true) end
    if ApplyingConfig or not AutoSaveEnabled then return false end
    if SaveQueued then return true end
    SaveQueued = true
    task.delay(0.35, function()
        SaveQueued = false
        SaveConfig(false)
    end)
    return true
end

function LoadConfigFromFile()
    if not CURRENT_VERSION then return end
    ConfigData = { _version = CURRENT_VERSION }
    SetActiveConfig(nil, nil, false, nil)
    local autoPath = GameConfigFolder .. "/_autoload.json"
    if not (isfile and isfile(autoPath)) then return end
    local ok, auto = pcall(function() return HttpService:JSONDecode(readfile(autoPath)) end)
    local autoName = ok and type(auto) == "table" and tostring(auto.Name or "") or ""
    if autoName == "" then return end
    local configPath = GameConfigFolder .. "/" .. autoName .. ".json"
    if isfile and isfile(configPath) then
        local success, result = pcall(function() return HttpService:JSONDecode(readfile(configPath)) end)
        if success and type(result) == "table" then
            ConfigData = result
            ConfigData._version = CURRENT_VERSION
            SetActiveConfig(autoName, configPath, true, "autoload")
        end
    end
end

function LoadConfigElements()
    ApplyingConfig = true
    for key, element in pairs(Elements) do
        if ConfigData[key] ~= nil and element.Set then
            element:Set(ConfigData[key], true)
        end
    end
    ApplyingConfig = false
end



local C_BG      = Color3.fromRGB(9, 10, 16)
local C_SIDEBAR = Color3.fromRGB(12, 13, 20)
local C_PANEL   = Color3.fromRGB(15, 16, 24)
local C_PANEL2  = Color3.fromRGB(20, 22, 32)
local C_ACCENT  = Color3.fromRGB(90, 140, 255)
local C_TEXT    = Color3.fromRGB(235, 235, 240)
local C_SUBTEXT = Color3.fromRGB(140, 145, 165)
local C_BORDER  = Color3.fromRGB(40, 43, 58)
local C_GREEN   = Color3.fromRGB(120, 220, 140)



local function corner(inst, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 8)
    c.Parent = inst
    return c
end

local function stroke(inst, color, t)
    local s = Instance.new("UIStroke")
    s.Color = color or C_BORDER
    s.Thickness = t or 1
    s.Parent = inst
    return s
end

local function pad(inst, l, t, r, b)
    local p = Instance.new("UIPadding")
    p.PaddingLeft = UDim.new(0, l or 0)
    p.PaddingTop = UDim.new(0, t or 0)
    p.PaddingRight = UDim.new(0, r or 0)
    p.PaddingBottom = UDim.new(0, b or 0)
    p.Parent = inst
    return p
end

local function isMobileDevice()
    return UserInputService.TouchEnabled
        and not UserInputService.KeyboardEnabled
        and not UserInputService.MouseEnabled
end
local isMobile = isMobileDevice()

local viewport = workspace.CurrentCamera.ViewportSize

local function safeSize(pxWidth, pxHeight)
    local scaleX = pxWidth / viewport.X
    local scaleY = pxHeight / viewport.Y

    if isMobile then
        if scaleX > 0.5 then scaleX = 0.5 end
        if scaleY > 0.3 then scaleY = 0.3 end
    end

    return UDim2.new(scaleX, 0, scaleY, 0)
end


function CircleClick(Button, X, Y)
    spawn(function()
        Button.ClipsDescendants = true
        local Circle = Instance.new("ImageLabel")
        Circle.Image = "rbxassetid://266543268"
        Circle.ImageColor3 = Color3.fromRGB(80, 80, 80)
        Circle.ImageTransparency = 0.9
        Circle.BackgroundTransparency = 1
        Circle.ZIndex = 10
        Circle.Name = "Circle"
        Circle.Parent = Button

        local NewX = X - Circle.AbsolutePosition.X
        local NewY = Y - Circle.AbsolutePosition.Y
        Circle.Position = UDim2.new(0, NewX, 0, NewY)
        local Size = 0
        if Button.AbsoluteSize.X > Button.AbsoluteSize.Y then
            Size = Button.AbsoluteSize.X * 1.5
        elseif Button.AbsoluteSize.X < Button.AbsoluteSize.Y then
            Size = Button.AbsoluteSize.Y * 1.5
        else
            Size = Button.AbsoluteSize.X * 1.5
        end

        local Time = 0.5
        Circle:TweenSizeAndPosition(
            UDim2.new(0, Size, 0, Size),
            UDim2.new(0.5, -Size / 2, 0.5, -Size / 2),
            "Out", "Quad", Time, false, nil
        )
        TweenService:Create(Circle, TweenInfo.new(Time, Enum.EasingStyle.Quad), { ImageTransparency = 1 }):Play()
        task.wait(Time)
        Circle:Destroy()
    end)
end


local Chloex = {}

function Chloex:Window(GuiConfig)
    GuiConfig = GuiConfig or {}
    GuiConfig.Title = GuiConfig.Title or "HydraHub"
    GuiConfig.Footer = GuiConfig.Footer or ""
    GuiConfig.Color = GuiConfig.Color or C_ACCENT
    if GuiConfig.Search == nil then GuiConfig.Search = true end
    GuiConfig.Version = GuiConfig.Version or 1

    CURRENT_VERSION = GuiConfig.Version
    LoadConfigFromFile()

    local GuiFunc = {}
    local SearchRegistry = {}
    local TabRegistry = {}
    local CategoryButtons = {}
    local CategoryPages = {}
    local ActiveCategory = nil
    local ActiveCategoryBtn = nil
    local CountDropdown = 0

    local function SmartMatch(query, target)
        if query == "" then return 0 end
        local q, t = string.lower(query), string.lower(target)
        if q == t then return 1000 end
        if string.sub(t, 1, #q) == q then return 800 end
        local idx = string.find(t, q, 1, true)
        if idx then return 600 - idx end
        local qi, ti, lastIdx = 1, 1, 0
        while qi <= #q and ti <= #t do
            if string.sub(q, qi, qi) == string.sub(t, ti, ti) then
                lastIdx = ti
                qi = qi + 1
            end
            ti = ti + 1
        end
        if qi > #q then return 200 - (lastIdx - #q) * 2 end
        return 0
    end

    local function RegisterSearch(entry)
        table.insert(SearchRegistry, entry)
    end

    local function ExtractConfigPayload(payload)
        local data = payload
        if type(payload.Data) == "table" then data = payload.Data
        elseif type(payload.Config) == "table" then data = payload.Config
        elseif type(payload.Settings) == "table" then data = payload.Settings end
        if type(data) ~= "table" then return nil end
        local cleaned = {}
        for key, value in pairs(data) do
            if key ~= "_version" and key ~= "Game" and key ~= "Version"
                and key ~= "PlaceId" and key ~= "Hub" and key ~= "SavedAt"
                and key ~= "ActiveConfig" and key ~= "AutoLoad"
                and not InternalConfigKeys[key] then
                cleaned[key] = value
            end
        end
        return cleaned
    end

    local function ApplyConfigData(data)
        ApplyingConfig = true
        ConfigData = { _version = CURRENT_VERSION }
        for key, value in pairs(data) do
            ConfigData[key] = value
            if Elements[key] and Elements[key].Set then
                pcall(function() Elements[key]:Set(value, true) end)
            end
        end
        ConfigData._version = CURRENT_VERSION
        ApplyingConfig = false
    end

    function GuiFunc:ExportConfig()
        local payload = HttpService:JSONEncode({
            Hub = "HydraHub",
            Game = gameName,
            PlaceId = game.PlaceId,
            Version = CURRENT_VERSION,
            Data = GetConfigSnapshot(),
        })
        if setclipboard then setclipboard(payload) end
        return payload
    end

    function GuiFunc:ImportConfig(str)
        if not str or str == "" then return false end
        local ok, dec = pcall(function() return HttpService:JSONDecode(str) end)
        if not ok or type(dec) ~= "table" then return false end
        local data = ExtractConfigPayload(dec)
        if not data then return false end
        ApplyConfigData(data)
        QueueSaveConfig(AutoSaveEnabled)
        return true
    end

    local function EnsureConfigFolder()
        if not isfolder("HydraHub") then makefolder("HydraHub") end
        if not isfolder(ConfigFolder) then makefolder(ConfigFolder) end
        if not isfolder(GameConfigFolder) then makefolder(GameConfigFolder) end
    end

    function GuiFunc:GetConfigs()
        local out = {}
        if not listfiles then return out end
        EnsureConfigFolder()
        for _, f in ipairs(listfiles(GameConfigFolder)) do
            local n = string.match(f, "([^/\\]+)%.json$")
            if n and n ~= "_autoload" then table.insert(out, n) end
        end
        return out
    end

    function GuiFunc:SaveConfigAs(name)
        if not name or name == "" then return false end
        if not writefile then return false end
        EnsureConfigFolder()
        local path = GameConfigFolder .. "/" .. name .. ".json"
        writefile(path, HttpService:JSONEncode(GetConfigSnapshot()))
        SetActiveConfig(name, path, AutoSaveEnabled, "saved")
        return true
    end

    function GuiFunc:LoadConfigByName(name)
        if not name or name == "" then return false end
        local path = GameConfigFolder .. "/" .. name .. ".json"
        if not (isfile and isfile(path)) then return false end
        local ok, dec = pcall(function() return HttpService:JSONDecode(readfile(path)) end)
        if not ok or type(dec) ~= "table" then return false end
        local data = ExtractConfigPayload(dec)
        if not data then return false end
        ApplyConfigData(data)
        SetActiveConfig(name, path, true, "manual")
        return true
    end

    function GuiFunc:DeleteConfig(name)
        local path = GameConfigFolder .. "/" .. name .. ".json"
        if isfile and isfile(path) and delfile then
            delfile(path)
            if ActiveConfigName == name then SetActiveConfig(nil, nil, false, nil) end
            if GuiFunc:GetAutoLoad() == name then GuiFunc:SetAutoLoad("") end
            return true
        end
        return false
    end

    function GuiFunc:SetAutoLoad(name)
        if not writefile then return end
        EnsureConfigFolder()
        name = name or ""
        writefile(GameConfigFolder .. "/_autoload.json", HttpService:JSONEncode({ Name = name }))
        if name ~= "" then
            SetActiveConfig(name, GameConfigFolder .. "/" .. name .. ".json", true, "autoload")
        elseif ActiveConfigMode == "autoload" then
            SetActiveConfig(nil, nil, false, nil)
        end
    end

    function GuiFunc:GetAutoLoad()
        local path = GameConfigFolder .. "/_autoload.json"
        if isfile and isfile(path) then
            local ok, dec = pcall(function() return HttpService:JSONDecode(readfile(path)) end)
            if ok and type(dec) == "table" then return dec.Name or "" end
        end
        return ""
    end

    local ok, CoreGui = pcall(function() return game:GetService("CoreGui") end)
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "HydraLibrary"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.DisplayOrder = 999

    if ok and syn and syn.protect_gui then
        syn.protect_gui(ScreenGui)
        ScreenGui.Parent = CoreGui
    elseif ok and gethui then
        ScreenGui.Parent = gethui()
    elseif ok then
        ScreenGui.Parent = CoreGui
    else
        ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end


    local Main = Instance.new("Frame")
    Main.AnchorPoint = Vector2.new(0.5, 0.5)
    if isMobile then
        Main.Size = safeSize(470, 270)
    else
        Main.Size = safeSize(760, 560)
    end
    Main.Position = UDim2.fromScale(0.5, 0.5)
    Main.BackgroundColor3 = C_BG
    Main.BorderSizePixel = 0
    Main.ClipsDescendants = true
    Main.Parent = ScreenGui
    corner(Main, 12)
    stroke(Main, C_BORDER, 1)


    local TopBar = Instance.new("Frame")
    TopBar.Size = UDim2.new(1, 0, 0, 46)
    TopBar.BackgroundColor3 = C_SIDEBAR
    TopBar.BorderSizePixel = 0
    TopBar.Parent = Main
    corner(TopBar, 12)
    local topFix = Instance.new("Frame")
    topFix.Size = UDim2.new(1, 0, 0, 12)
    topFix.Position = UDim2.new(0, 0, 1, -12)
    topFix.BackgroundColor3 = C_SIDEBAR
    topFix.BorderSizePixel = 0
    topFix.Parent = TopBar

    local LogoIcon = Instance.new("Frame")
    LogoIcon.Size = UDim2.fromOffset(28, 28)
    LogoIcon.Position = UDim2.fromOffset(12, 9)
    LogoIcon.BackgroundColor3 = GuiConfig.Color
    LogoIcon.Parent = TopBar
    corner(LogoIcon, 7)
    local LogoLabel = Instance.new("TextLabel")
    LogoLabel.BackgroundTransparency = 1
    LogoLabel.Size = UDim2.fromScale(1, 1)
    LogoLabel.Text = string.sub(tostring(GuiConfig.Title or "H"), 1, 1)
    LogoLabel.TextColor3 = Color3.new(1, 1, 1)
    LogoLabel.Font = Enum.Font.GothamBold
    LogoLabel.TextSize = 15
    LogoLabel.Parent = LogoIcon

    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Position = UDim2.fromOffset(48, 4)
    TitleLabel.Size = UDim2.fromOffset(240, 18)
    TitleLabel.Text = GuiConfig.Title
    TitleLabel.TextColor3 = GuiConfig.Color
    TitleLabel.Font = Enum.Font.GothamBold
    TitleLabel.TextSize = 15
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.Parent = TopBar

    local SubtitleLabel = Instance.new("TextLabel")
    SubtitleLabel.BackgroundTransparency = 1
    SubtitleLabel.Position = UDim2.fromOffset(48, 22)
    SubtitleLabel.Size = UDim2.fromOffset(240, 14)
    SubtitleLabel.Text = GuiConfig.Footer
    SubtitleLabel.TextColor3 = C_SUBTEXT
    SubtitleLabel.Font = Enum.Font.Gotham
    SubtitleLabel.TextSize = 11
    SubtitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    SubtitleLabel.Parent = TopBar

    local MinimizeBtn = Instance.new("TextButton")
    MinimizeBtn.Size = UDim2.fromOffset(24, 24)
    MinimizeBtn.Position = UDim2.new(1, -66, 0, 11)
    MinimizeBtn.BackgroundTransparency = 1
    MinimizeBtn.Text = "-"
    MinimizeBtn.TextColor3 = C_SUBTEXT
    MinimizeBtn.Font = Enum.Font.GothamBold
    MinimizeBtn.TextSize = 20
    MinimizeBtn.Parent = TopBar

    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Size = UDim2.fromOffset(24, 24)
    CloseBtn.Position = UDim2.new(1, -32, 0, 11)
    CloseBtn.BackgroundTransparency = 1
    CloseBtn.Text = "X"
    CloseBtn.TextColor3 = C_SUBTEXT
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.TextSize = 16
    CloseBtn.Parent = TopBar


    local SidebarWidth = isMobile and 100 or 150

    local Sidebar = Instance.new("Frame")
    Sidebar.Size = UDim2.new(0, SidebarWidth, 1, -46)
    Sidebar.Position = UDim2.new(0, 0, 0, 46)
    Sidebar.BackgroundColor3 = C_SIDEBAR
    Sidebar.BorderSizePixel = 0
    Sidebar.Parent = Main

    local SidebarList = Instance.new("UIListLayout")
    SidebarList.Padding = UDim.new(0, 3)
    SidebarList.Parent = Sidebar
    pad(Sidebar, 8, 12, 8, 8)

    local SearchBar = nil
    local SearchResults = nil
    local SearchResultsLayout = nil
    local SearchBox = nil

    if GuiConfig.Search then
        SearchBar = Instance.new("Frame")
        SearchBar.BackgroundColor3 = C_PANEL2
        SearchBar.BorderSizePixel = 0
        SearchBar.Size = UDim2.new(1, 0, 0, 28)
        SearchBar.Name = "SearchBar"
        SearchBar.Parent = Sidebar
        corner(SearchBar, 6)
        stroke(SearchBar, C_BORDER, 1)

        SearchBox = Instance.new("TextBox")
        SearchBox.Font = Enum.Font.GothamBold
        SearchBox.PlaceholderText = "Search..."
        SearchBox.PlaceholderColor3 = Color3.fromRGB(130, 130, 130)
        SearchBox.Text = ""
        SearchBox.TextColor3 = C_TEXT
        SearchBox.TextSize = 12
        SearchBox.TextXAlignment = Enum.TextXAlignment.Left
        SearchBox.ClearTextOnFocus = false
        SearchBox.BackgroundTransparency = 1
        SearchBox.Position = UDim2.new(0, 8, 0, 0)
        SearchBox.Size = UDim2.new(1, -16, 1, 0)
        SearchBox.Name = "SearchBox"
        SearchBox.Parent = SearchBar

        SearchResults = Instance.new("ScrollingFrame")
        SearchResults.Active = true
        SearchResults.BackgroundColor3 = C_PANEL
        SearchResults.BackgroundTransparency = 0.05
        SearchResults.BorderSizePixel = 0
        SearchResults.ScrollBarThickness = 2
        SearchResults.ScrollBarImageColor3 = GuiConfig.Color
        SearchResults.CanvasSize = UDim2.new(0, 0, 0, 0)
        SearchResults.Size = UDim2.new(1, 0, 1, 0)
        SearchResults.Visible = false
        SearchResults.ZIndex = 20
        SearchResults.Name = "SearchResults"
        SearchResults.Parent = Sidebar
        corner(SearchResults, 4)
        pad(SearchResults, 4, 4, 4, 4)

        SearchResultsLayout = Instance.new("UIListLayout")
        SearchResultsLayout.Padding = UDim.new(0, 4)
        SearchResultsLayout.SortOrder = Enum.SortOrder.LayoutOrder
        SearchResultsLayout.Parent = SearchResults

        SearchResultsLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            SearchResults.CanvasSize = UDim2.new(0, 0, 0, SearchResultsLayout.AbsoluteContentSize.Y + 8)
        end)

        local function RunSearch()
            local q = string.gsub(string.gsub(string.lower(SearchBox.Text), "^%s+", ""), "%s+$", "")
            for _, c in pairs(SearchResults:GetChildren()) do
                if c:IsA("GuiObject") then c:Destroy() end
            end
            if q == "" then
                SearchResults.Visible = false
                return
            end
            SearchResults.Visible = true
            local scored = {}
            for _, entry in ipairs(SearchRegistry) do
                local s = SmartMatch(q, entry.label)
                if s > 0 then table.insert(scored, { entry = entry, score = s }) end
            end
            table.sort(scored, function(a, b) return a.score > b.score end)
            local found = 0
            for _, s in ipairs(scored) do
                local entry = s.entry
                local Row = Instance.new("Frame")
                Row.BackgroundColor3 = C_PANEL2
                Row.BackgroundTransparency = 0.07
                Row.BorderSizePixel = 0
                Row.Size = UDim2.new(1, 0, 0, 40)
                Row.LayoutOrder = found
                Row.ZIndex = 21
                Row.Parent = SearchResults
                corner(Row, 4)

                local RowLabel = Instance.new("TextLabel")
                RowLabel.Font = Enum.Font.GothamBold
                RowLabel.Text = entry.label
                RowLabel.TextColor3 = C_TEXT
                RowLabel.TextSize = 12
                RowLabel.TextXAlignment = Enum.TextXAlignment.Left
                RowLabel.TextTruncate = Enum.TextTruncate.AtEnd
                RowLabel.BackgroundTransparency = 1
                RowLabel.Position = UDim2.new(0, 8, 0, 6)
                RowLabel.Size = UDim2.new(1, -16, 0, 14)
                RowLabel.ZIndex = 22
                RowLabel.Parent = Row

                local RowTab = Instance.new("TextLabel")
                RowTab.Font = Enum.Font.Gotham
                RowTab.Text = entry.tab .. (entry.kind and (" • " .. entry.kind) or "")
                RowTab.TextColor3 = GuiConfig.Color
                RowTab.TextSize = 10
                RowTab.TextXAlignment = Enum.TextXAlignment.Left
                RowTab.BackgroundTransparency = 1
                RowTab.Position = UDim2.new(0, 8, 0, 22)
                RowTab.Size = UDim2.new(1, -16, 0, 12)
                RowTab.ZIndex = 22
                RowTab.Parent = Row

                local RowButton = Instance.new("TextButton")
                RowButton.Text = ""
                RowButton.BackgroundTransparency = 1
                RowButton.Size = UDim2.new(1, 0, 1, 0)
                RowButton.ZIndex = 23
                RowButton.Parent = Row
                RowButton.Activated:Connect(function()
                    if entry.kind == "Toggle" and entry.element and entry.element.Set then
                        entry.element.Value = not entry.element.Value
                        entry.element:Set(entry.element.Value)
                    else
                        SearchBox.Text = ""
                        SearchResults.Visible = false
                        if entry.switch then entry.switch() end
                    end
                end)
                found = found + 1
                if found >= 15 then break end
            end
            if found == 0 then
                local Empty = Instance.new("TextLabel")
                Empty.Font = Enum.Font.GothamBold
                Empty.Text = "No results"
                Empty.TextColor3 = C_SUBTEXT
                Empty.TextSize = 12
                Empty.BackgroundTransparency = 1
                Empty.Size = UDim2.new(1, 0, 0, 40)
                Empty.ZIndex = 22
                Empty.Parent = SearchResults
            end
        end

        local searchTicket = 0
        SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
            searchTicket = searchTicket + 1
            local ticket = searchTicket
            task.delay(0.08, function()
                if ticket == searchTicket then RunSearch() end
            end)
        end)
    end


    local Content = Instance.new("Frame")
    Content.Size = UDim2.new(1, -SidebarWidth, 1, -74)
    Content.Position = UDim2.new(0, SidebarWidth, 0, 46)
    Content.BackgroundColor3 = C_BG
    Content.BorderSizePixel = 0
    Content.Parent = Main
    pad(Content, 14, 12, 14, 12)

    local HeaderLabel = Instance.new("TextLabel")
    HeaderLabel.BackgroundTransparency = 1
    HeaderLabel.Size = UDim2.new(1, 0, 0, 24)
    HeaderLabel.Text = ""
    HeaderLabel.TextColor3 = C_TEXT
    HeaderLabel.Font = Enum.Font.GothamBold
    HeaderLabel.TextSize = 18
    HeaderLabel.TextXAlignment = Enum.TextXAlignment.Left
    HeaderLabel.Parent = Content


    local PageHolder = Instance.new("Frame")
    PageHolder.Size = UDim2.new(1, 0, 1, -30)
    PageHolder.Position = UDim2.fromOffset(0, 30)
    PageHolder.BackgroundTransparency = 1
    PageHolder.BorderSizePixel = 0
    PageHolder.ClipsDescendants = true
    PageHolder.Parent = Content

    local PageLayout = Instance.new("UIPageLayout")
    PageLayout.SortOrder = Enum.SortOrder.LayoutOrder
    PageLayout.TweenTime = 0.3
    PageLayout.EasingDirection = Enum.EasingDirection.InOut
    PageLayout.EasingStyle = Enum.EasingStyle.Quad
    PageLayout.Parent = PageHolder

    local FooterBar = Instance.new("Frame")
    FooterBar.Size = UDim2.new(1, 0, 0, 28)
    FooterBar.Position = UDim2.new(0, 0, 1, -28)
    FooterBar.BackgroundColor3 = C_SIDEBAR
    FooterBar.BorderSizePixel = 0
    FooterBar.ZIndex = 5
    FooterBar.Parent = Main

    local FooterLabel = Instance.new("TextLabel")
    FooterLabel.BackgroundTransparency = 1
    FooterLabel.Size = UDim2.new(1, -16, 1, 0)
    FooterLabel.Position = UDim2.fromOffset(16, 0)
    FooterLabel.Text = GuiConfig.Footer ~= "" and GuiConfig.Footer or "HydraHub"
    FooterLabel.TextColor3 = C_SUBTEXT
    FooterLabel.Font = Enum.Font.Gotham
    FooterLabel.TextSize = 11
    FooterLabel.TextXAlignment = Enum.TextXAlignment.Left
    FooterLabel.ZIndex = 5
    FooterLabel.Parent = FooterBar



    -- Drag
    local dragging, dragInput, dragStart, startPos
    TopBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = Main.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    TopBar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)


    local ResizeHandle = Instance.new("Frame")
    ResizeHandle.Size = UDim2.fromOffset(18, 18)
    ResizeHandle.Position = UDim2.new(1, -18, 1, -18)
    ResizeHandle.BackgroundTransparency = 1
    ResizeHandle.ZIndex = 10
    ResizeHandle.Parent = Main

    local ResizeIcon = Instance.new("TextLabel")
    ResizeIcon.BackgroundTransparency = 1
    ResizeIcon.Size = UDim2.fromScale(1, 1)
    ResizeIcon.Text = "◢"
    ResizeIcon.TextColor3 = C_SUBTEXT
    ResizeIcon.Font = Enum.Font.GothamBold
    ResizeIcon.TextSize = 14
    ResizeIcon.ZIndex = 10
    ResizeIcon.Parent = ResizeHandle

    local MIN_W, MIN_H
    local MAX_W, MAX_H
    if isMobile then
        MIN_W, MIN_H = 200, 150
        MAX_W, MAX_H = 600, 500
    else
        MIN_W, MIN_H = 480, 360
        MAX_W, MAX_H = 1100, 800
    end
    local resizing, resizeStart, sizeStart

    ResizeHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            resizing = true
            resizeStart = input.Position
            sizeStart = Main.Size
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then resizing = false end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if resizing and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - resizeStart
            local newW = math.clamp(sizeStart.X.Offset + delta.X, MIN_W, MAX_W)
            local newH = math.clamp(sizeStart.Y.Offset + delta.Y, MIN_H, MAX_H)
            Main.Size = UDim2.fromOffset(newW, newH)
        end
    end)

    local minimized = false
    local lastFullSize = Main.Size
    MinimizeBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        if minimized then
            lastFullSize = Main.Size
            TweenService:Create(Main, TweenInfo.new(0.25), {Size = UDim2.fromOffset(lastFullSize.X.Offset, 46)}):Play()
        else
            TweenService:Create(Main, TweenInfo.new(0.25), {Size = lastFullSize}):Play()
        end
        Sidebar.Visible = not minimized
        Content.Visible = not minimized
        FooterBar.Visible = not minimized
        ResizeHandle.Visible = not minimized
    end)

    CloseBtn.MouseButton1Click:Connect(function()
        ScreenGui:Destroy()
    end)

    function GuiFunc:DestroyGui()
        if ScreenGui then ScreenGui:Destroy() end
    end

    function GuiFunc:ToggleUI()
        Main.Visible = not Main.Visible
    end

    -- Expose MakeNotify on GuiFunc so Gui:MakeNotify() works
    -- Global notify helper
    function than(text, duration, color, title, kind)
        Chloex:MakeNotify({
            Title = title or "HydraHub",
            Description = kind or "Notification",
            Content = text or "Content",
            Color = color or Color3.fromRGB(0, 208, 255),
            Delay = duration or 4
        })
    end



    function GuiFunc:Confirm(config)
        config = config or {}
        local ConfirmGui = Instance.new("ScreenGui")
        ConfirmGui.Name = "HydraHubConfirm"
        ConfirmGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        ConfirmGui.DisplayOrder = 1000
        ConfirmGui.Parent = ScreenGui

        local Overlay = Instance.new("Frame")
        Overlay.Size = UDim2.new(1, 0, 1, 0)
        Overlay.BackgroundColor3 = Color3.new(0, 0, 0)
        Overlay.BackgroundTransparency = 0.3
        Overlay.ZIndex = 50
        Overlay.Parent = ConfirmGui

        local Dialog = Instance.new("Frame")
        Dialog.Size = UDim2.new(0, 300, 0, 150)
        Dialog.Position = UDim2.new(0.5, -150, 0.5, -75)
        Dialog.BackgroundColor3 = C_PANEL
        Dialog.BorderSizePixel = 0
        Dialog.ZIndex = 51
        Dialog.Parent = Overlay
        corner(Dialog, 8)
        stroke(Dialog, GuiConfig.Color, 1)

        local Title = Instance.new("TextLabel")
        Title.Size = UDim2.new(1, -20, 0, 30)
        Title.Position = UDim2.new(0, 10, 0, 8)
        Title.BackgroundTransparency = 1
        Title.Font = Enum.Font.GothamBold
        Title.Text = config.Title or "Confirm"
        Title.TextSize = 16
        Title.TextColor3 = GuiConfig.Color
        Title.TextXAlignment = Enum.TextXAlignment.Left
        Title.ZIndex = 52
        Title.Parent = Dialog

        local Message = Instance.new("TextLabel")
        Message.Size = UDim2.new(1, -20, 0, 50)
        Message.Position = UDim2.new(0, 10, 0, 36)
        Message.BackgroundTransparency = 1
        Message.Font = Enum.Font.Gotham
        Message.Text = config.Message or "Are you sure?"
        Message.TextSize = 13
        Message.TextColor3 = C_TEXT
        Message.TextWrapped = true
        Message.TextYAlignment = Enum.TextYAlignment.Top
        Message.ZIndex = 52
        Message.Parent = Dialog

        local Yes = Instance.new("TextButton")
        Yes.Size = UDim2.new(0.4, -10, 0, 32)
        Yes.Position = UDim2.new(0.05, 0, 1, -44)
        Yes.BackgroundColor3 = C_GREEN
        Yes.Text = config.YesText or "Yes"
        Yes.Font = Enum.Font.GothamBold
        Yes.TextSize = 13
        Yes.TextColor3 = C_TEXT
        Yes.ZIndex = 52
        Yes.Parent = Dialog
        corner(Yes, 6)

        local Cancel = Instance.new("TextButton")
        Cancel.Size = UDim2.new(0.4, -10, 0, 32)
        Cancel.Position = UDim2.new(0.55, 0, 1, -44)
        Cancel.BackgroundColor3 = C_BORDER
        Cancel.Text = config.CancelText or "Cancel"
        Cancel.Font = Enum.Font.GothamBold
        Cancel.TextSize = 13
        Cancel.TextColor3 = C_TEXT
        Cancel.ZIndex = 52
        Cancel.Parent = Dialog
        corner(Cancel, 6)

        local resolved = false
        local function resolve(fn)
            if resolved then return end
            resolved = true
            ConfirmGui:Destroy()
            if fn then pcall(fn) end
        end

        Yes.MouseButton1Click:Connect(function() resolve(config.OnYes) end)
        Cancel.MouseButton1Click:Connect(function() resolve(config.OnCancel) end)
        return ConfirmGui
    end


    local function CreateToggleUI()
        local ToggleGui = Instance.new("ScreenGui")
        ToggleGui.Name = "ToggleUIButton"
        ToggleGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        ToggleGui.Parent = (ok and CoreGui) or LocalPlayer:WaitForChild("PlayerGui")

        local FloatFrame = Instance.new("Frame")
        FloatFrame.Parent = ToggleGui
        FloatFrame.Size = UDim2.fromOffset(40, 40)
        FloatFrame.Position = UDim2.new(0, 10, 0.5, -20)
        FloatFrame.BackgroundColor3 = C_SIDEBAR
        FloatFrame.BorderSizePixel = 0
        corner(FloatFrame, 10)
        stroke(FloatFrame, GuiConfig.Color, 1)

        local FloatBtn = Instance.new("TextButton")
        FloatBtn.Size = UDim2.new(1, 0, 1, 0)
        FloatBtn.BackgroundTransparency = 1
        FloatBtn.Text = "H"
        FloatBtn.TextColor3 = GuiConfig.Color
        FloatBtn.Font = Enum.Font.GothamBold
        FloatBtn.TextSize = 16
        FloatBtn.Parent = FloatFrame

        FloatBtn.MouseButton1Click:Connect(function()
            Main.Visible = true
            ToggleGui:Destroy()
        end)


        local fDrag, fDragInput, fDragStart, fStartPos
        FloatBtn.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                fDrag = true
                fDragStart = input.Position
                fStartPos = FloatFrame.Position
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then fDrag = false end
                end)
            end
        end)
        FloatBtn.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                fDragInput = input
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if input == fDragInput and fDrag then
                local delta = input.Position - fDragStart
                FloatFrame.Position = UDim2.new(fStartPos.X.Scale, fStartPos.X.Offset + delta.X, fStartPos.Y.Scale, fStartPos.Y.Offset + delta.Y)
            end
        end)
    end

    MinimizeBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        if minimized then
            lastFullSize = Main.Size
            Main.Visible = false
            CreateToggleUI()
        else
            Main.Visible = true
        end
    end)


    local Tabs = {}
    local CountTab = 0

    function Tabs:AddTab(TabConfig)
        TabConfig = TabConfig or {}
        TabConfig.Name = TabConfig.Name or "Tab"
        TabConfig.Icon = TabConfig.Icon or ""

        local Page = Instance.new("ScrollingFrame")
        Page.AutomaticCanvasSize = Enum.AutomaticSize.Y
        Page.ScrollBarThickness = 4
        Page.ScrollBarImageColor3 = GuiConfig.Color
        Page.Active = true
        Page.LayoutOrder = CountTab
        Page.BackgroundTransparency = 1
        Page.BorderSizePixel = 0
        Page.Size = UDim2.new(1, 0, 1, 0)
        Page.Name = "Page_" .. TabConfig.Name
        Page.Parent = PageHolder

        local PageList = Instance.new("UIListLayout")
        PageList.Padding = UDim.new(0, 6)
        PageList.SortOrder = Enum.SortOrder.LayoutOrder
        PageList.Parent = Page

        PageList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            Page.CanvasSize = UDim2.new(0, 0, 0, PageList.AbsoluteContentSize.Y + 10)
        end)

        local function makeCatButton(name, active)
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, 0, 0, 32)
            btn.BackgroundColor3 = C_PANEL
            btn.BackgroundTransparency = active and 0 or 1
            btn.AutoButtonColor = false
            btn.Text = ""
            btn.Parent = Sidebar
            corner(btn, 6)

            local indicator = Instance.new("Frame")
            indicator.Size = UDim2.new(0, 3, 0, 16)
            indicator.Position = UDim2.new(0, 0, 0.5, -8)
            indicator.BackgroundColor3 = GuiConfig.Color
            indicator.Visible = active
            indicator.Parent = btn
            corner(indicator, 2)

            local lbl = Instance.new("TextLabel")
            lbl.BackgroundTransparency = 1
            lbl.Position = UDim2.fromOffset(12, 0)
            lbl.Size = UDim2.new(1, -18, 1, 0)
            lbl.Text = name
            lbl.TextColor3 = active and C_TEXT or C_SUBTEXT
            lbl.Font = active and Enum.Font.GothamBold or Enum.Font.Gotham
            lbl.TextSize = 12
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.Parent = btn

            return btn
        end

        local isActive = (CountTab == 0)
        local catBtn = makeCatButton(TabConfig.Name, isActive)
        table.insert(CategoryButtons, catBtn)
        CategoryPages[TabConfig.Name] = Page

        catBtn.MouseButton1Click:Connect(function()
            -- Deactivate all
            for _, b in ipairs(CategoryButtons) do
                for _, child in ipairs(b:GetChildren()) do
                    if child:IsA("Frame") and child.Size.Y.Offset == 16 then
                        child.Visible = false
                    end
                end
                for _, child in ipairs(b:GetChildren()) do
                    if child:IsA("TextLabel") then
                        child.TextColor3 = C_SUBTEXT
                        child.Font = Enum.Font.Gotham
                    end
                end
                b.BackgroundTransparency = 1
            end
            -- Activate this
            for _, child in ipairs(catBtn:GetChildren()) do
                if child:IsA("Frame") and child.Size.Y.Offset == 16 then
                    child.Visible = true
                end
            end
            for _, child in ipairs(catBtn:GetChildren()) do
                if child:IsA("TextLabel") then
                    child.TextColor3 = C_TEXT
                    child.Font = Enum.Font.GothamBold
                end
            end
            catBtn.BackgroundTransparency = 0
            HeaderLabel.Text = TabConfig.Name
            PageLayout:JumpTo(Page)
            ActiveCategory = TabConfig.Name
            ActiveCategoryBtn = catBtn
        end)

        local SearchSwitch = function()
            PageLayout:JumpTo(Page)
            HeaderLabel.Text = TabConfig.Name
            ActiveCategory = TabConfig.Name
        end

        TabRegistry[TabConfig.Name] = SearchSwitch
        RegisterSearch({ label = TabConfig.Name, tab = TabConfig.Name, kind = "Tab", switch = SearchSwitch })

        if isActive then
            HeaderLabel.Text = TabConfig.Name
            PageLayout:JumpToIndex(0)
            ActiveCategory = TabConfig.Name
            ActiveCategoryBtn = catBtn
        end

        CountTab = CountTab + 1


        local Sections = {}
        local CountSection = 0

        function Sections:AddSection(Title, AlwaysOpen)
            Title = Title or "Title"

            local Section = Instance.new("Frame")
            Section.Size = UDim2.new(1, 0, 0, 38)
            Section.BackgroundTransparency = 1
            Section.ClipsDescendants = true
            Section.LayoutOrder = CountSection
            Section.Parent = Page

            -- Header button
            local Header = Instance.new("TextButton")
            Header.Size = UDim2.new(1, 0, 0, 38)
            Header.BackgroundColor3 = C_PANEL
            Header.AutoButtonColor = false
            Header.Text = ""
            Header.Parent = Section
            corner(Header, 8)
            stroke(Header, C_BORDER, 1)

            local HeaderTitle = Instance.new("TextLabel")
            HeaderTitle.BackgroundTransparency = 1
            HeaderTitle.Position = UDim2.fromOffset(14, 0)
            HeaderTitle.Size = UDim2.new(1, -46, 1, 0)
            HeaderTitle.Text = Title
            HeaderTitle.TextColor3 = C_TEXT
            HeaderTitle.Font = Enum.Font.GothamBold
            HeaderTitle.TextSize = 13
            HeaderTitle.TextXAlignment = Enum.TextXAlignment.Left
            HeaderTitle.Parent = Header

            local Chevron = Instance.new("TextLabel")
            Chevron.BackgroundTransparency = 1
            Chevron.Position = UDim2.new(1, -30, 0, 0)
            Chevron.Size = UDim2.fromOffset(20, 38)
            Chevron.Text = ">"
            Chevron.TextColor3 = GuiConfig.Color
            Chevron.Font = Enum.Font.GothamBold
            Chevron.TextSize = 14
            Chevron.Parent = Header

            -- Accent line
            local AccentLine = Instance.new("Frame")
            AccentLine.Size = UDim2.new(0, 0, 0, 2)
            AccentLine.Position = UDim2.new(0.5, 0, 0, 38)
            AccentLine.BackgroundColor3 = GuiConfig.Color
            AccentLine.BorderSizePixel = 0
            AccentLine.Parent = Section
            corner(AccentLine, 1)

            -- Body (content container)
            local Body = Instance.new("Frame")
            Body.Size = UDim2.new(1, 0, 0, 0)
            Body.Position = UDim2.fromOffset(0, 44)
            Body.BackgroundTransparency = 1
            Body.ClipsDescendants = true
            Body.Parent = Section

            local BodyLayout = Instance.new("UIListLayout")
            BodyLayout.Padding = UDim.new(0, 6)
            BodyLayout.SortOrder = Enum.SortOrder.LayoutOrder
            BodyLayout.Parent = Body

            -- Accordion logic
            local OpenSection = false

            local function setBodyHeight()
                local h = 0
                for _, r in ipairs(Body:GetChildren()) do
                    if r:IsA("Frame") or r:IsA("TextButton") or r:IsA("ScrollingFrame") then
                        h = h + r.Size.Y.Offset + 6
                    end
                end
                return h
            end

            local function UpdateSizeSection()
                if not OpenSection then return end
                local bodyH = setBodyHeight()
                local totalH = 38 + (6 + bodyH)
                TweenService:Create(Section, TweenInfo.new(0.25), {Size = UDim2.new(1, 0, 0, totalH)}):Play()
                TweenService:Create(Chevron, TweenInfo.new(0.25), {Rotation = 90}):Play()
                TweenService:Create(AccentLine, TweenInfo.new(0.25), {Size = UDim2.new(1, 0, 0, 2)}):Play()
            end

            Body.ChildAdded:Connect(UpdateSizeSection)
            Body.ChildRemoved:Connect(UpdateSizeSection)

            if AlwaysOpen == true then
                OpenSection = true
                task.defer(UpdateSizeSection)
            elseif AlwaysOpen == false then
                OpenSection = true
                task.defer(UpdateSizeSection)
            else
                OpenSection = false
            end

            if AlwaysOpen ~= true then
                Header.MouseButton1Click:Connect(function()
                    if OpenSection then
                        OpenSection = false
                        TweenService:Create(Chevron, TweenInfo.new(0.25), {Rotation = 0}):Play()
                        TweenService:Create(AccentLine, TweenInfo.new(0.25), {Size = UDim2.new(0, 0, 0, 2)}):Play()
                        local bodyH = setBodyHeight()
                        TweenService:Create(Section, TweenInfo.new(0.25), {Size = UDim2.new(1, 0, 0, 38)}):Play()
                    else
                        OpenSection = true
                        UpdateSizeSection()
                    end
                end)
            end


            local Items = {}
            local CountItem = 0

            -- AddParagraph
            function Items:AddParagraph(ParagraphConfig)
                ParagraphConfig = ParagraphConfig or {}
                ParagraphConfig.Title = ParagraphConfig.Title or "Title"
                ParagraphConfig.Content = ParagraphConfig.Content or "Content"

                local Para = Instance.new("Frame")
                Para.Size = UDim2.new(1, 0, 0, 40)
                Para.BackgroundColor3 = C_PANEL2
                Para.BorderSizePixel = 0
                Para.LayoutOrder = CountItem
                Para.Parent = Body
                corner(Para, 6)
                stroke(Para, C_BORDER, 1)

                local TitleLbl = Instance.new("TextLabel")
                TitleLbl.LayoutOrder = 0
                TitleLbl.BackgroundTransparency = 1
                TitleLbl.Position = UDim2.new(0, 12, 0, 6)
                TitleLbl.Size = UDim2.new(1, -24, 0, 14)
                TitleLbl.Text = ParagraphConfig.Title
                TitleLbl.TextColor3 = C_TEXT
                TitleLbl.Font = Enum.Font.GothamBold
                TitleLbl.TextSize = 12
                TitleLbl.TextXAlignment = Enum.TextXAlignment.Left
                TitleLbl.Parent = Para

                local ContentLbl = Instance.new("TextLabel")
                ContentLbl.LayoutOrder = 1
                ContentLbl.BackgroundTransparency = 1
                ContentLbl.Position = UDim2.new(0, 12, 0, 22)
                ContentLbl.Size = UDim2.new(1, -24, 0, 12)
                ContentLbl.Text = ParagraphConfig.Content
                ContentLbl.TextColor3 = C_SUBTEXT
                ContentLbl.Font = Enum.Font.Gotham
                ContentLbl.TextSize = 11
                ContentLbl.TextXAlignment = Enum.TextXAlignment.Left
                ContentLbl.Parent = Para

                CountItem = CountItem + 1
                RegisterSearch({ label = ParagraphConfig.Title, tab = TabConfig.Name, kind = "Paragraph", switch = SearchSwitch })

                -- Return wrapper with SetContent for dynamic updates
                local ParaAPI = { Frame = Para }
                function ParaAPI:SetContent(text)
                    text = tostring(text or "")
                    for _, child in ipairs(Para:GetChildren()) do
                        if child:IsA("TextLabel") and child.LayoutOrder == 1 then
                            child.Text = text
                        end
                    end
                end
                function ParaAPI:SetTitle(text)
                    for _, child in ipairs(Para:GetChildren()) do
                        if child:IsA("TextLabel") and child.LayoutOrder == 0 then
                            child.Text = tostring(text or "")
                        end
                    end
                end
                setmetatable(ParaAPI, { __index = Para })
                return ParaAPI
            end

            -- AddButton
            function Items:AddButton(ButtonConfig)
                ButtonConfig = ButtonConfig or {}
                ButtonConfig.Title = ButtonConfig.Title or "Confirm"
                ButtonConfig.Callback = ButtonConfig.Callback or function() end
                ButtonConfig.SubTitle = ButtonConfig.SubTitle or nil
                ButtonConfig.SubCallback = ButtonConfig.SubCallback or function() end

                local BtnFrame = Instance.new("Frame")
                BtnFrame.Size = UDim2.new(1, 0, 0, 36)
                BtnFrame.BackgroundColor3 = C_PANEL2
                BtnFrame.BorderSizePixel = 0
                BtnFrame.LayoutOrder = CountItem
                BtnFrame.Parent = Body
                corner(BtnFrame, 6)
                stroke(BtnFrame, C_BORDER, 1)

                local MainButton = Instance.new("TextButton")
                MainButton.Font = Enum.Font.GothamBold
                MainButton.Text = ButtonConfig.Title
                MainButton.TextSize = 12
                MainButton.TextColor3 = C_TEXT
                MainButton.BackgroundColor3 = C_BORDER
                MainButton.BackgroundTransparency = 0.7
                MainButton.Size = ButtonConfig.SubTitle and UDim2.new(0.5, -8, 1, -8) or UDim2.new(1, -16, 1, -8)
                MainButton.Position = UDim2.new(0, 6, 0, 4)
                MainButton.Parent = BtnFrame
                corner(MainButton, 5)

                MainButton.MouseButton1Click:Connect(function()
                    pcall(ButtonConfig.Callback)
                end)

                if ButtonConfig.SubTitle then
                    local SubButton = Instance.new("TextButton")
                    SubButton.Font = Enum.Font.GothamBold
                    SubButton.Text = ButtonConfig.SubTitle
                    SubButton.TextSize = 12
                    SubButton.TextColor3 = C_TEXT
                    SubButton.BackgroundColor3 = C_BORDER
                    SubButton.BackgroundTransparency = 0.7
                    SubButton.Size = UDim2.new(0.5, -8, 1, -8)
                    SubButton.Position = UDim2.new(0.5, 2, 0, 4)
                    SubButton.Parent = BtnFrame
                    corner(SubButton, 5)

                    SubButton.MouseButton1Click:Connect(function()
                        pcall(ButtonConfig.SubCallback)
                    end)
                end

                CountItem = CountItem + 1
                RegisterSearch({ label = ButtonConfig.Title, tab = TabConfig.Name, kind = "Button", switch = SearchSwitch })
            end

            function Items:AddToggle(ToggleConfig)
                ToggleConfig = ToggleConfig or {}
                ToggleConfig.Title = ToggleConfig.Title or "Title"
                ToggleConfig.Title2 = ToggleConfig.Title2 or ""
                ToggleConfig.Content = ToggleConfig.Content or ""
                ToggleConfig.Default = ToggleConfig.Default or false
                ToggleConfig.Callback = ToggleConfig.Callback or function() end

                local configKey = "Toggle_" .. ToggleConfig.Title
                local shouldSave = ToggleConfig.Save ~= false
                if shouldSave and ConfigData[configKey] ~= nil then
                    ToggleConfig.Default = ConfigData[configKey]
                end

                local ToggleFunc = { Value = ToggleConfig.Default }

                local Toggle = Instance.new("Frame")
                Toggle.BackgroundColor3 = C_PANEL2
                Toggle.BorderSizePixel = 0
                Toggle.LayoutOrder = CountItem
                Toggle.Name = "Toggle"
                Toggle.Parent = Body
                corner(Toggle, 6)
                stroke(Toggle, C_BORDER, 1)

                local ToggleTitle = Instance.new("TextLabel")
                ToggleTitle.Font = Enum.Font.GothamBold
                ToggleTitle.Text = ToggleConfig.Title
                ToggleTitle.TextSize = 13
                ToggleTitle.TextColor3 = C_TEXT
                ToggleTitle.TextXAlignment = Enum.TextXAlignment.Left
                ToggleTitle.TextYAlignment = Enum.TextYAlignment.Top
                ToggleTitle.BackgroundTransparency = 1
                ToggleTitle.Position = UDim2.new(0, 10, 0, 10)
                ToggleTitle.Size = UDim2.new(1, -100, 0, 13)
                ToggleTitle.Parent = Toggle

                local ToggleTitle2 = Instance.new("TextLabel")
                ToggleTitle2.Font = Enum.Font.Gotham
                ToggleTitle2.Text = ToggleConfig.Title2
                ToggleTitle2.TextSize = 12
                ToggleTitle2.TextColor3 = C_SUBTEXT
                ToggleTitle2.TextXAlignment = Enum.TextXAlignment.Left
                ToggleTitle2.TextYAlignment = Enum.TextYAlignment.Top
                ToggleTitle2.BackgroundTransparency = 1
                ToggleTitle2.Position = UDim2.new(0, 10, 0, 23)
                ToggleTitle2.Size = UDim2.new(1, -100, 0, 12)
                ToggleTitle2.Visible = ToggleConfig.Title2 ~= ""
                ToggleTitle2.Parent = Toggle

                local ToggleContent = Instance.new("TextLabel")
                ToggleContent.Font = Enum.Font.Gotham
                ToggleContent.Text = ToggleConfig.Content
                ToggleContent.TextColor3 = C_SUBTEXT
                ToggleContent.TextSize = 11
                ToggleContent.TextTransparency = 0.4
                ToggleContent.TextXAlignment = Enum.TextXAlignment.Left
                ToggleContent.TextYAlignment = Enum.TextYAlignment.Bottom
                ToggleContent.TextWrapped = true
                ToggleContent.BackgroundTransparency = 1
                ToggleContent.Parent = Toggle

                if ToggleConfig.Title2 ~= "" then
                    Toggle.Size = UDim2.new(1, 0, 0, 57)
                    ToggleContent.Position = UDim2.new(0, 10, 0, 36)
                    ToggleContent.Size = UDim2.new(1, -100, 0, 16)
                else
                    Toggle.Size = UDim2.new(1, 0, 0, 46)
                    ToggleContent.Position = UDim2.new(0, 10, 0, 23)
                    ToggleContent.Size = UDim2.new(1, -100, 0, 16)
                end

                local ToggleButton = Instance.new("TextButton")
                ToggleButton.Font = Enum.Font.SourceSans
                ToggleButton.Text = ""
                ToggleButton.BackgroundTransparency = 1
                ToggleButton.Size = UDim2.new(1, 0, 1, 0)
                ToggleButton.Parent = Toggle

                local FeatureFrame = Instance.new("Frame")
                FeatureFrame.AnchorPoint = Vector2.new(1, 0.5)
                FeatureFrame.BackgroundColor3 = C_BORDER
                FeatureFrame.BackgroundTransparency = 0
                FeatureFrame.BorderSizePixel = 0
                FeatureFrame.Position = UDim2.new(1, -15, 0.5, 0)
                FeatureFrame.Size = UDim2.new(0, 38, 0, 20)
                FeatureFrame.Parent = Toggle
                corner(FeatureFrame, 10)

                local ToggleCircle = Instance.new("Frame")
                ToggleCircle.BackgroundColor3 = C_TEXT
                ToggleCircle.BorderSizePixel = 0
                ToggleCircle.Size = UDim2.new(0, 16, 0, 16)
                ToggleCircle.Position = UDim2.fromOffset(2, 2)
                ToggleCircle.Parent = FeatureFrame
                corner(ToggleCircle, 8)

                ToggleButton.Activated:Connect(function()
                    ToggleFunc.Value = not ToggleFunc.Value
                    ToggleFunc:Set(ToggleFunc.Value)
                end)

                function ToggleFunc:Set(Value, noSave)
                    Value = Value and true or false
                    ToggleFunc.Value = Value
                    if typeof(ToggleConfig.Callback) == "function" then
                        pcall(function() ToggleConfig.Callback(Value) end)
                    end
                    if shouldSave then
                        ConfigData[configKey] = Value
                        if not noSave then QueueSaveConfig() end
                    end
                    if Value then
                        TweenService:Create(ToggleTitle, TweenInfo.new(0.2), {TextColor3 = GuiConfig.Color}):Play()
                        TweenService:Create(FeatureFrame, TweenInfo.new(0.2), {BackgroundColor3 = GuiConfig.Color}):Play()
                        TweenService:Create(ToggleCircle, TweenInfo.new(0.2), {Position = UDim2.fromOffset(20, 2)}):Play()
                    else
                        TweenService:Create(ToggleTitle, TweenInfo.new(0.2), {TextColor3 = C_TEXT}):Play()
                        TweenService:Create(FeatureFrame, TweenInfo.new(0.2), {BackgroundColor3 = C_BORDER}):Play()
                        TweenService:Create(ToggleCircle, TweenInfo.new(0.2), {Position = UDim2.fromOffset(2, 2)}):Play()
                    end
                end

                ToggleFunc:Set(ToggleFunc.Value, true)
                CountItem = CountItem + 1
                if shouldSave then Elements[configKey] = ToggleFunc end
                RegisterSearch({ label = ToggleConfig.Title, tab = TabConfig.Name, kind = "Toggle", element = ToggleFunc, switch = SearchSwitch })
                return ToggleFunc
            end


            function Items:AddSlider(SliderConfig)
                SliderConfig = SliderConfig or {}
                SliderConfig.Title = SliderConfig.Title or "Slider"
                SliderConfig.Content = SliderConfig.Content or ""
                SliderConfig.Min = tonumber(SliderConfig.Min) or 0
                SliderConfig.Max = tonumber(SliderConfig.Max) or 100
                if SliderConfig.Max < SliderConfig.Min then
                    SliderConfig.Min, SliderConfig.Max = SliderConfig.Max, SliderConfig.Min
                end
                SliderConfig.Default = tonumber(SliderConfig.Default) or SliderConfig.Min
                SliderConfig.Increment = tonumber(SliderConfig.Increment or SliderConfig.Step) or 1
                local sliderSpan = SliderConfig.Max - SliderConfig.Min
                if SliderConfig.Increment <= 0 then
                    SliderConfig.Increment = sliderSpan >= 1 and 1 or (sliderSpan > 0 and math.max(sliderSpan / 100, 0.01) or 1)
                elseif sliderSpan > 0 and SliderConfig.Increment >= sliderSpan then
                    SliderConfig.Increment = sliderSpan >= 1 and 1 or math.max(sliderSpan / 100, 0.01)
                end
                SliderConfig.Live = SliderConfig.Live == true
                SliderConfig.Callback = SliderConfig.Callback or function() end

                local configKey = "Slider_" .. SliderConfig.Title
                local shouldSave = SliderConfig.Save ~= false
                if shouldSave and ConfigData[configKey] ~= nil then
                    SliderConfig.Default = tonumber(ConfigData[configKey]) or SliderConfig.Default
                end

                local SliderFunc = { Value = SliderConfig.Default }

                local Slider = Instance.new("Frame")
                Slider.BackgroundColor3 = C_PANEL2
                Slider.BorderSizePixel = 0
                Slider.LayoutOrder = CountItem
                Slider.Size = UDim2.new(1, 0, 0, 52)
                Slider.Name = "Slider"
                Slider.Parent = Body
                corner(Slider, 6)
                stroke(Slider, C_BORDER, 1)

                local SliderTitle = Instance.new("TextLabel")
                SliderTitle.Font = Enum.Font.GothamBold
                SliderTitle.Text = SliderConfig.Title
                SliderTitle.TextColor3 = C_TEXT
                SliderTitle.TextSize = 13
                SliderTitle.TextXAlignment = Enum.TextXAlignment.Left
                SliderTitle.TextYAlignment = Enum.TextYAlignment.Top
                SliderTitle.BackgroundTransparency = 1
                SliderTitle.Position = UDim2.new(0, 10, 0, 8)
                SliderTitle.Size = UDim2.new(1, -180, 0, 13)
                SliderTitle.Parent = Slider

                local SliderContent = Instance.new("TextLabel")
                SliderContent.Font = Enum.Font.Gotham
                SliderContent.Text = SliderConfig.Content
                SliderContent.TextColor3 = C_SUBTEXT
                SliderContent.TextSize = 11
                SliderContent.TextXAlignment = Enum.TextXAlignment.Left
                SliderContent.TextYAlignment = Enum.TextYAlignment.Bottom
                SliderContent.BackgroundTransparency = 1
                SliderContent.Position = UDim2.new(0, 10, 0, 24)
                SliderContent.Size = UDim2.new(1, -180, 0, 12)
                SliderContent.Parent = Slider

                -- Value display
                local ValueLabel = Instance.new("TextLabel")
                ValueLabel.Font = Enum.Font.GothamBold
                ValueLabel.Text = tostring(SliderConfig.Default)
                ValueLabel.TextColor3 = GuiConfig.Color
                ValueLabel.TextSize = 12
                ValueLabel.BackgroundTransparency = 1
                ValueLabel.AnchorPoint = Vector2.new(1, 0)
                ValueLabel.Position = UDim2.new(1, -10, 0, 8)
                ValueLabel.Size = UDim2.new(0, 60, 0, 16)
                ValueLabel.Parent = Slider

                -- Slider track
                local SliderFrame = Instance.new("Frame")
                SliderFrame.AnchorPoint = Vector2.new(1, 0.5)
                SliderFrame.BackgroundColor3 = C_BORDER
                SliderFrame.BackgroundTransparency = 0.5
                SliderFrame.BorderSizePixel = 0
                SliderFrame.Position = UDim2.new(1, -10, 0.5, 8)
                SliderFrame.Size = UDim2.new(0, 180, 0, 4)
                SliderFrame.Name = "SliderFrame"
                SliderFrame.Parent = Slider
                corner(SliderFrame, 2)

                local SliderDraggable = Instance.new("Frame")
                SliderDraggable.AnchorPoint = Vector2.new(0, 0.5)
                SliderDraggable.BackgroundColor3 = GuiConfig.Color
                SliderDraggable.BorderSizePixel = 0
                SliderDraggable.Position = UDim2.new(0, 0, 0.5, 0)
                SliderDraggable.Size = UDim2.new(0, 0, 1, 0)
                SliderDraggable.Name = "SliderDraggable"
                SliderDraggable.Parent = SliderFrame
                corner(SliderDraggable, 2)

                local SliderCircle = Instance.new("Frame")
                SliderCircle.AnchorPoint = Vector2.new(1, 0.5)
                SliderCircle.BackgroundColor3 = GuiConfig.Color
                SliderCircle.BorderSizePixel = 0
                SliderCircle.Position = UDim2.new(1, 4, 0.5, 0)
                SliderCircle.Size = UDim2.new(0, 10, 0, 10)
                SliderCircle.Name = "SliderCircle"
                SliderCircle.Parent = SliderDraggable
                corner(SliderCircle, 5)

                local Dragging = false

                local function Round(Number, Factor)
                    if sliderSpan <= 0 then return SliderConfig.Min end
                    local Steps = math.floor(((Number - SliderConfig.Min) / Factor) + 0.5)
                    return SliderConfig.Min + (Steps * Factor)
                end

                local function FormatValue(Value)
                    if math.abs(Value - math.floor(Value)) < 0.000001 then
                        return tostring(math.floor(Value))
                    end
                    local text = string.format("%.2f", Value)
                    text = text:gsub("0+$", ""):gsub("%.$", "")
                    return text
                end

                local function ValueScale(Value)
                    if sliderSpan <= 0 then return 0 end
                    return math.clamp((Value - SliderConfig.Min) / sliderSpan, 0, 1)
                end

                local function ApplySliderValue(Value, noSave, instant, fireCallback)
                    Value = tonumber(Value) or SliderConfig.Min
                    Value = math.clamp(Round(Value, SliderConfig.Increment), SliderConfig.Min, SliderConfig.Max)
                    SliderFunc.Value = Value
                    if shouldSave then ConfigData[configKey] = Value end

                    ValueLabel.Text = FormatValue(Value)

                    local targetSize = UDim2.fromScale(ValueScale(Value), 1)
                    if instant then
                        SliderDraggable.Size = targetSize
                    else
                        TweenService:Create(SliderDraggable, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = targetSize}):Play()
                    end

                    if fireCallback then
                        pcall(function() SliderConfig.Callback(Value) end)
                    end

                    if shouldSave and not noSave then QueueSaveConfig() end
                end

                function SliderFunc:Set(Value, noSave)
                    ApplySliderValue(Value, noSave, false, true)
                end

                SliderFrame.InputBegan:Connect(function(Input)
                    if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                        Dragging = true
                        TweenService:Create(SliderCircle, TweenInfo.new(0.2), {Size = UDim2.new(0, 14, 0, 14)}):Play()
                        local SizeScale = math.clamp(
                            (Input.Position.X - SliderFrame.AbsolutePosition.X) / SliderFrame.AbsoluteSize.X, 0, 1)
                        ApplySliderValue(SliderConfig.Min + (sliderSpan * SizeScale), true, true, SliderConfig.Live)
                    end
                end)

                local function FinishSliderDrag(Input)
                    if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                        if not Dragging then return end
                        Dragging = false
                        ApplySliderValue(SliderFunc.Value, false, false, not SliderConfig.Live)
                        TweenService:Create(SliderCircle, TweenInfo.new(0.2), {Size = UDim2.new(0, 10, 0, 10)}):Play()
                    end
                end

                SliderFrame.InputEnded:Connect(FinishSliderDrag)
                UserInputService.InputEnded:Connect(FinishSliderDrag)

                UserInputService.InputChanged:Connect(function(Input)
                    if Dragging and (Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch) then
                        local SizeScale = math.clamp(
                            (Input.Position.X - SliderFrame.AbsolutePosition.X) / SliderFrame.AbsoluteSize.X, 0, 1)
                        ApplySliderValue(SliderConfig.Min + (sliderSpan * SizeScale), true, true, SliderConfig.Live)
                    end
                end)

                SliderFunc:Set(SliderConfig.Default, true)
                CountItem = CountItem + 1
                if shouldSave then Elements[configKey] = SliderFunc end
                RegisterSearch({ label = SliderConfig.Title, tab = TabConfig.Name, kind = "Slider", element = SliderFunc, switch = SearchSwitch })
                return SliderFunc
            end

            -- AddInput
            function Items:AddInput(InputConfig)
                InputConfig = InputConfig or {}
                InputConfig.Title = InputConfig.Title or "Title"
                InputConfig.Content = InputConfig.Content or ""
                InputConfig.Callback = InputConfig.Callback or function() end
                InputConfig.Default = InputConfig.Default or ""
                InputConfig.Placeholder = InputConfig.Placeholder or "Input Here"

                local configKey = "Input_" .. InputConfig.Title
                local shouldSave = InputConfig.Save ~= false
                if shouldSave and ConfigData[configKey] ~= nil then
                    InputConfig.Default = ConfigData[configKey]
                end

                local InputFunc = { Value = InputConfig.Default }

                local Input = Instance.new("Frame")
                Input.BackgroundColor3 = C_PANEL2
                Input.BorderSizePixel = 0
                Input.LayoutOrder = CountItem
                Input.Size = UDim2.new(1, 0, 0, 50)
                Input.Name = "Input"
                Input.Parent = Body
                corner(Input, 6)
                stroke(Input, C_BORDER, 1)

                local InputTitle = Instance.new("TextLabel")
                InputTitle.Font = Enum.Font.GothamBold
                InputTitle.Text = InputConfig.Title
                InputTitle.TextColor3 = C_TEXT
                InputTitle.TextSize = 13
                InputTitle.TextXAlignment = Enum.TextXAlignment.Left
                InputTitle.TextYAlignment = Enum.TextYAlignment.Top
                InputTitle.BackgroundTransparency = 1
                InputTitle.Position = UDim2.new(0, 10, 0, 8)
                InputTitle.Size = UDim2.new(1, -180, 0, 13)
                InputTitle.Parent = Input

                local InputContent = Instance.new("TextLabel")
                InputContent.Font = Enum.Font.Gotham
                InputContent.Text = InputConfig.Content
                InputContent.TextColor3 = C_SUBTEXT
                InputContent.TextSize = 11
                InputContent.TextWrapped = true
                InputContent.TextXAlignment = Enum.TextXAlignment.Left
                InputContent.TextYAlignment = Enum.TextYAlignment.Bottom
                InputContent.BackgroundTransparency = 1
                InputContent.Position = UDim2.new(0, 10, 0, 24)
                InputContent.Size = UDim2.new(1, -180, 0, 12)
                InputContent.Parent = Input

                local InputFrame = Instance.new("Frame")
                InputFrame.AnchorPoint = Vector2.new(1, 0.5)
                InputFrame.BackgroundColor3 = C_BORDER
                InputFrame.BackgroundTransparency = 0.5
                InputFrame.BorderSizePixel = 0
                InputFrame.ClipsDescendants = true
                InputFrame.Position = UDim2.new(1, -7, 0.5, 0)
                InputFrame.Size = UDim2.new(0, 148, 0, 30)
                InputFrame.Parent = Input
                corner(InputFrame, 5)

                local InputTextBox = Instance.new("TextBox")
                InputTextBox.CursorPosition = -1
                InputTextBox.Font = Enum.Font.GothamBold
                InputTextBox.PlaceholderColor3 = C_SUBTEXT
                InputTextBox.PlaceholderText = InputConfig.Placeholder
                InputTextBox.Text = InputConfig.Default
                InputTextBox.TextColor3 = C_TEXT
                InputTextBox.TextSize = 12
                InputTextBox.TextXAlignment = Enum.TextXAlignment.Left
                InputTextBox.AnchorPoint = Vector2.new(0, 0.5)
                InputTextBox.BackgroundTransparency = 1
                InputTextBox.Position = UDim2.new(0, 8, 0.5, 0)
                InputTextBox.Size = UDim2.new(1, -16, 1, -8)
                InputTextBox.Parent = InputFrame

                function InputFunc:Set(Value, noSave)
                    Value = tostring(Value or "")
                    InputTextBox.Text = Value
                    InputFunc.Value = Value
                    pcall(function() InputConfig.Callback(Value) end)
                    if shouldSave then
                        ConfigData[configKey] = Value
                        if not noSave then QueueSaveConfig() end
                    end
                end

                InputFunc:Set(InputFunc.Value, true)
                InputTextBox.FocusLost:Connect(function() InputFunc:Set(InputTextBox.Text) end)

                CountItem = CountItem + 1
                if shouldSave then Elements[configKey] = InputFunc end
                RegisterSearch({ label = InputConfig.Title, tab = TabConfig.Name, kind = "Input", element = InputFunc, switch = SearchSwitch })
                return InputFunc
            end

            -- AddDropdown
            function Items:AddDropdown(DropdownConfig)
                DropdownConfig = DropdownConfig or {}
                DropdownConfig.Title = DropdownConfig.Title or "Title"
                DropdownConfig.Content = DropdownConfig.Content or ""
                DropdownConfig.Multi = DropdownConfig.Multi or false
                DropdownConfig.Options = DropdownConfig.Options or {}
                DropdownConfig.Default = DropdownConfig.Default or (DropdownConfig.Multi and {} or nil)
                DropdownConfig.Callback = DropdownConfig.Callback or function() end

                local configKey = "Dropdown_" .. DropdownConfig.Title
                local shouldSave = DropdownConfig.Save ~= false
                if shouldSave and ConfigData[configKey] ~= nil then
                    DropdownConfig.Default = ConfigData[configKey]
                end

                local DropdownFunc = { Value = DropdownConfig.Default, Options = DropdownConfig.Options }

                local Dropdown = Instance.new("Frame")
                Dropdown.BackgroundColor3 = C_PANEL2
                Dropdown.BorderSizePixel = 0
                Dropdown.LayoutOrder = CountItem
                Dropdown.Size = UDim2.new(1, 0, 0, 50)
                Dropdown.Name = "Dropdown"
                Dropdown.Parent = Body
                corner(Dropdown, 6)
                stroke(Dropdown, C_BORDER, 1)

                local DropdownButton = Instance.new("TextButton")
                DropdownButton.Text = ""
                DropdownButton.BackgroundTransparency = 1
                DropdownButton.Size = UDim2.new(1, 0, 1, 0)
                DropdownButton.Parent = Dropdown

                local DropdownTitle = Instance.new("TextLabel")
                DropdownTitle.Font = Enum.Font.GothamBold
                DropdownTitle.Text = DropdownConfig.Title
                DropdownTitle.TextColor3 = C_TEXT
                DropdownTitle.TextSize = 13
                DropdownTitle.TextXAlignment = Enum.TextXAlignment.Left
                DropdownTitle.BackgroundTransparency = 1
                DropdownTitle.Position = UDim2.new(0, 10, 0, 8)
                DropdownTitle.Size = UDim2.new(1, -180, 0, 13)
                DropdownTitle.Parent = Dropdown

                local DropdownContent = Instance.new("TextLabel")
                DropdownContent.Font = Enum.Font.Gotham
                DropdownContent.Text = DropdownConfig.Content
                DropdownContent.TextColor3 = C_SUBTEXT
                DropdownContent.TextSize = 11
                DropdownContent.TextWrapped = true
                DropdownContent.TextXAlignment = Enum.TextXAlignment.Left
                DropdownContent.BackgroundTransparency = 1
                DropdownContent.Position = UDim2.new(0, 10, 0, 24)
                DropdownContent.Size = UDim2.new(1, -180, 0, 12)
                DropdownContent.Parent = Dropdown

                local SelectFrame = Instance.new("Frame")
                SelectFrame.AnchorPoint = Vector2.new(1, 0.5)
                SelectFrame.BackgroundColor3 = C_BORDER
                SelectFrame.BackgroundTransparency = 0.5
                SelectFrame.BorderSizePixel = 0
                SelectFrame.Position = UDim2.new(1, -7, 0.5, 0)
                SelectFrame.Size = UDim2.new(0, 148, 0, 30)
                SelectFrame.Parent = Dropdown
                corner(SelectFrame, 5)

                local OptionSelecting = Instance.new("TextLabel")
                OptionSelecting.Font = Enum.Font.GothamBold
                OptionSelecting.Text = DropdownConfig.Multi and "Select Options" or "Select Option"
                OptionSelecting.TextColor3 = C_SUBTEXT
                OptionSelecting.TextSize = 11
                OptionSelecting.TextXAlignment = Enum.TextXAlignment.Left
                OptionSelecting.BackgroundTransparency = 1
                OptionSelecting.Position = UDim2.new(0, 8, 0.5, 0)
                OptionSelecting.AnchorPoint = Vector2.new(0, 0.5)
                OptionSelecting.Size = UDim2.new(1, -24, 1, -8)
                OptionSelecting.Parent = SelectFrame

                local ArrowLabel = Instance.new("TextLabel")
                ArrowLabel.BackgroundTransparency = 1
                ArrowLabel.Text = ">"
                ArrowLabel.TextColor3 = C_SUBTEXT
                ArrowLabel.Font = Enum.Font.GothamBold
                ArrowLabel.TextSize = 12
                ArrowLabel.Size = UDim2.new(0, 16, 1, 0)
                ArrowLabel.Position = UDim2.new(1, -18, 0, 0)
                ArrowLabel.Parent = SelectFrame

                -- Dropdown overlay
                local DropdownOverlay = Instance.new("Frame")
                DropdownOverlay.Size = UDim2.new(1, 0, 1, 0)
                DropdownOverlay.BackgroundColor3 = Color3.new(0, 0, 0)
                DropdownOverlay.BackgroundTransparency = 0.4
                DropdownOverlay.BorderSizePixel = 0
                DropdownOverlay.Visible = false
                DropdownOverlay.ZIndex = 30
                DropdownOverlay.Parent = Main

                local DropPanel = Instance.new("Frame")
                DropPanel.AnchorPoint = Vector2.new(0.5, 0.5)
                DropPanel.BackgroundColor3 = C_PANEL
                DropPanel.BorderSizePixel = 0
                DropPanel.Position = UDim2.new(0.5, 0, 0.5, 0)
                DropPanel.Size = UDim2.new(0, 280, 0, 300)
                DropPanel.ZIndex = 31
                DropPanel.Parent = DropdownOverlay
                corner(DropPanel, 8)
                stroke(DropPanel, GuiConfig.Color, 1)

                local DropTitle = Instance.new("TextLabel")
                DropTitle.BackgroundTransparency = 1
                DropTitle.Position = UDim2.new(0, 12, 0, 8)
                DropTitle.Size = UDim2.new(1, -24, 0, 18)
                DropTitle.Text = DropdownConfig.Title
                DropTitle.TextColor3 = GuiConfig.Color
                DropTitle.Font = Enum.Font.GothamBold
                DropTitle.TextSize = 13
                DropTitle.TextXAlignment = Enum.TextXAlignment.Left
                DropTitle.ZIndex = 32
                DropTitle.Parent = DropPanel

                local DropSearch = Instance.new("TextBox")
                DropSearch.PlaceholderText = "Search..."
                DropSearch.PlaceholderColor3 = C_SUBTEXT
                DropSearch.Font = Enum.Font.Gotham
                DropSearch.Text = ""
                DropSearch.TextColor3 = C_TEXT
                DropSearch.TextSize = 12
                DropSearch.BackgroundColor3 = C_PANEL2
                DropSearch.BackgroundTransparency = 0
                DropSearch.BorderSizePixel = 0
                DropSearch.ClearTextOnFocus = false
                DropSearch.Position = UDim2.new(0, 8, 0, 30)
                DropSearch.Size = UDim2.new(1, -16, 0, 26)
                DropSearch.ZIndex = 32
                DropSearch.Parent = DropPanel
                corner(DropSearch, 5)

                local DropScroll = Instance.new("ScrollingFrame")
                DropScroll.Size = UDim2.new(1, -16, 1, -66)
                DropScroll.Position = UDim2.new(0, 8, 0, 60)
                DropScroll.BackgroundTransparency = 1
                DropScroll.BorderSizePixel = 0
                DropScroll.ScrollBarThickness = 3
                DropScroll.ScrollBarImageColor3 = GuiConfig.Color
                DropScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
                DropScroll.ZIndex = 32
                DropScroll.Parent = DropPanel

                local DropList = Instance.new("UIListLayout")
                DropList.Padding = UDim.new(0, 3)
                DropList.SortOrder = Enum.SortOrder.LayoutOrder
                DropList.Parent = DropScroll

                DropList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                    DropScroll.CanvasSize = UDim2.new(0, 0, 0, DropList.AbsoluteContentSize.Y + 8)
                end)

                local DropCount = 0
                local function RefreshOptions()
                    for _, child in ipairs(DropScroll:GetChildren()) do
                        if child:IsA("Frame") then child:Destroy() end
                    end
                    DropCount = 0
                    for _, opt in ipairs(DropdownFunc.Options) do
                        local label, value
                        if typeof(opt) == "table" and opt.Label and opt.Value ~= nil then
                            label = tostring(opt.Label)
                            value = opt.Value
                        else
                            label = tostring(opt)
                            value = opt
                        end

                        local OptFrame = Instance.new("Frame")
                        OptFrame.Size = UDim2.new(1, 0, 0, 30)
                        OptFrame.BackgroundTransparency = 1
                        OptFrame.LayoutOrder = DropCount
                        OptFrame.ZIndex = 33
                        OptFrame.Parent = DropScroll

                        local OptBtn = Instance.new("TextButton")
                        OptBtn.Size = UDim2.new(1, 0, 1, 0)
                        OptBtn.BackgroundTransparency = 1
                        OptBtn.Text = ""
                        OptBtn.ZIndex = 34
                        OptBtn.Parent = OptFrame

                        local OptLabel = Instance.new("TextLabel")
                        OptLabel.BackgroundTransparency = 1
                        OptLabel.Position = UDim2.new(0, 8, 0, 0)
                        OptLabel.Size = UDim2.new(1, -16, 1, 0)
                        OptLabel.Text = label
                        OptLabel.TextColor3 = C_TEXT
                        OptLabel.Font = Enum.Font.GothamBold
                        OptLabel.TextSize = 12
                        OptLabel.TextXAlignment = Enum.TextXAlignment.Left
                        OptLabel.ZIndex = 34
                        OptLabel.Parent = OptFrame

                        local CheckMark = Instance.new("TextLabel")
                        CheckMark.BackgroundTransparency = 1
                        CheckMark.Text = "✓"
                        CheckMark.TextColor3 = GuiConfig.Color
                        CheckMark.Font = Enum.Font.GothamBold
                        CheckMark.TextSize = 14
                        CheckMark.Size = UDim2.new(0, 20, 1, 0)
                        CheckMark.Position = UDim2.new(1, -24, 0, 0)
                        CheckMark.ZIndex = 34
                        CheckMark.Visible = false
                        CheckMark.Parent = OptFrame

                        OptBtn.MouseButton1Click:Connect(function()
                            if DropdownConfig.Multi then
                                if not table.find(DropdownFunc.Value, value) then
                                    table.insert(DropdownFunc.Value, value)
                                else
                                    for i, v in pairs(DropdownFunc.Value) do
                                        if v == value then
                                            table.remove(DropdownFunc.Value, i)
                                            break
                                        end
                                    end
                                end
                            else
                                DropdownFunc.Value = value
                                DropdownOverlay.Visible = false
                            end
                            DropdownFunc:Set(DropdownFunc.Value)
                        end)

                        OptFrame:SetAttribute("RealValue", value)
                        DropCount = DropCount + 1
                    end
                end

                local function UpdateDropdownVisual()
                    for _, OptFrame in ipairs(DropScroll:GetChildren()) do
                        if OptFrame:IsA("Frame") then
                            local v = OptFrame:GetAttribute("RealValue")
                            local selected = DropdownConfig.Multi and table.find(DropdownFunc.Value, v) or DropdownFunc.Value == v
                            local checkMark = OptFrame:FindFirstChild("TextLabel", true)
                            -- Find the checkmark (3rd child usually)
                            for _, child in ipairs(OptFrame:GetChildren()) do
                                if child:IsA("TextLabel") and child.Text == "✓" then
                                    child.Visible = selected
                                end
                            end
                            OptFrame.BackgroundTransparency = selected and 0.9 or 1
                        end
                    end

                    local texts = {}
                    for _, OptFrame in ipairs(DropScroll:GetChildren()) do
                        if OptFrame:IsA("Frame") then
                            local v = OptFrame:GetAttribute("RealValue")
                            local selected = DropdownConfig.Multi and table.find(DropdownFunc.Value, v) or DropdownFunc.Value == v
                            if selected then
                                local lbl = OptFrame:FindFirstChildWhichIsA("TextLabel")
                                if lbl then table.insert(texts, lbl.Text) end
                            end
                        end
                    end

                    OptionSelecting.Text = (#texts == 0)
                        and (DropdownConfig.Multi and "Select Options" or "Select Option")
                        or table.concat(texts, ", ")
                    OptionSelecting.TextColor3 = (#texts > 0) and C_TEXT or C_SUBTEXT
                end

                function DropdownFunc:Clear()
                    DropdownFunc.Value = DropdownConfig.Multi and {} or nil
                    DropdownFunc.Options = {}
                    OptionSelecting.Text = DropdownConfig.Multi and "Select Options" or "Select Option"
                    RefreshOptions()
                end

                function DropdownFunc:AddOption(option)
                    table.insert(DropdownFunc.Options, option)
                    RefreshOptions()
                end

                function DropdownFunc:Set(Value, noSave)
                    if DropdownConfig.Multi then
                        DropdownFunc.Value = type(Value) == "table" and Value or {}
                    else
                        DropdownFunc.Value = (type(Value) == "table" and Value[1]) or Value
                    end

                    if shouldSave then
                        ConfigData[configKey] = DropdownFunc.Value
                        if not noSave then QueueSaveConfig() end
                    end

                    RefreshOptions()
                    UpdateDropdownVisual()

                    if DropdownConfig.Callback then
                        if DropdownConfig.Multi then
                            pcall(function() DropdownConfig.Callback(DropdownFunc.Value) end)
                        else
                            local str = (DropdownFunc.Value ~= nil) and tostring(DropdownFunc.Value) or ""
                            pcall(function() DropdownConfig.Callback(str) end)
                        end
                    end
                end

                function DropdownFunc:SetValue(val) self:Set(val) end
                function DropdownFunc:GetValue() return self.Value end

                function DropdownFunc:SetValues(newList, selecting, noSave)
                    newList = newList or {}
                    selecting = selecting or (DropdownConfig.Multi and {} or nil)
                    DropdownFunc:Clear()
                    for _, v in ipairs(newList) do DropdownFunc:AddOption(v) end
                    DropdownFunc:Set(selecting, noSave)
                    DropdownFunc.Options = newList
                end

                -- Open dropdown
                DropdownButton.Activated:Connect(function()
                    RefreshOptions()
                    UpdateDropdownVisual()
                    DropdownOverlay.Visible = true
                    DropSearch.Text = ""
                end)

                -- Close on overlay click
                DropdownOverlay.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        DropdownOverlay.Visible = false
                    end
                end)

                -- Search in dropdown
                DropSearch:GetPropertyChangedSignal("Text"):Connect(function()
                    local q = string.lower(DropSearch.Text)
                    for _, OptFrame in ipairs(DropScroll:GetChildren()) do
                        if OptFrame:IsA("Frame") then
                            local lbl = OptFrame:FindFirstChildWhichIsA("TextLabel")
                            if lbl then
                                OptFrame.Visible = q == "" or string.find(string.lower(lbl.Text), q, 1, true)
                            end
                        end
                    end
                end)

                DropdownFunc:SetValues(DropdownFunc.Options, DropdownFunc.Value, true)
                CountItem = CountItem + 1
                if shouldSave then Elements[configKey] = DropdownFunc end
                RegisterSearch({ label = DropdownConfig.Title, tab = TabConfig.Name, kind = "Dropdown", element = DropdownFunc, switch = SearchSwitch })
                return DropdownFunc
            end

            -- AddConfig
            function Items:AddConfig(ConfigCfg)
                ConfigCfg = ConfigCfg or {}
                local autoName = GuiFunc:GetAutoLoad()
                local currentName = ""
                local selectedConfig = autoName ~= "" and autoName or nil

                local NameInput = Items:AddInput({
                    Title       = "Config Name",
                    Content     = "Name for saving",
                    Placeholder = "MyConfig",
                    Save        = false,
                    Callback    = function(text) currentName = text end,
                })

                local ConfigList
                local function RefreshList()
                    local list = GuiFunc:GetConfigs()
                    if ConfigList and ConfigList.SetValues then
                        ConfigList:SetValues(list, selectedConfig, true)
                    end
                end

                ConfigList = Items:AddDropdown({
                    Title    = "Saved Configs",
                    Content  = "Select a config",
                    Multi    = false,
                    Options  = GuiFunc:GetConfigs(),
                    Default  = selectedConfig,
                    Save     = false,
                    Callback = function(choice)
                        selectedConfig = choice ~= "" and choice or nil
                    end,
                })

                Items:AddButton({
                    Title    = "Save",
                    SubTitle = "Load",
                    Callback = function()
                        if GuiFunc:SaveConfigAs(currentName) then
                            selectedConfig = currentName
                            RefreshList()
                        end
                    end,
                    SubCallback = function()
                        if selectedConfig then GuiFunc:LoadConfigByName(selectedConfig) end
                    end,
                })

                Items:AddButton({
                    Title    = "Delete",
                    SubTitle = "Refresh List",
                    Callback = function()
                        if selectedConfig then
                            GuiFunc:DeleteConfig(selectedConfig)
                            selectedConfig = nil
                            RefreshList()
                        end
                    end,
                    SubCallback = function() RefreshList() end,
                })

                local AutoToggle
                local initAuto = true
                AutoToggle = Items:AddToggle({
                    Title    = "Auto Load",
                    Content  = autoName ~= "" and ("Auto: " .. autoName) or "Load selected on startup",
                    Default  = autoName ~= "",
                    Save     = false,
                    Callback = function(value)
                        if initAuto then return end
                        if value and selectedConfig then
                            GuiFunc:SetAutoLoad(selectedConfig)
                        elseif value then
                            GuiFunc:SetAutoLoad("")
                            if AutoToggle then AutoToggle:Set(false, true) end
                        else
                            GuiFunc:SetAutoLoad("")
                        end
                    end,
                })
                initAuto = false

                Items:AddButton({
                    Title    = "Export to Clipboard",
                    Callback = function()
                        GuiFunc:ExportConfig()
                    end,
                })

                return { Refresh = RefreshList }
            end

            -- AddBanner
            function Items:AddBanner(BannerConfig)
                BannerConfig = BannerConfig or {}
                local asset = tostring(BannerConfig.Image or BannerConfig.Banner or "")
                if asset ~= "" and not string.find(asset, "rbxassetid://") then
                    asset = "rbxassetid://" .. asset
                end

                local Banner = Instance.new("Frame")
                Banner.BackgroundColor3 = C_PANEL2
                Banner.BorderSizePixel = 0
                Banner.ClipsDescendants = true
                Banner.LayoutOrder = CountItem
                Banner.Size = UDim2.new(1, 0, 0, 80)
                Banner.Parent = Body
                corner(Banner, 8)

                if asset ~= "" then
                    local Img = Instance.new("ImageLabel")
                    Img.Image = asset
                    Img.BackgroundTransparency = 1
                    Img.ScaleType = Enum.ScaleType.Crop
                    Img.Size = UDim2.new(1, 0, 1, 0)
                    Img.Parent = Banner
                else
                    local Grad = Instance.new("UIGradient")
                    Grad.Color = ColorSequence.new {
                        ColorSequenceKeypoint.new(0, C_PANEL2),
                        ColorSequenceKeypoint.new(0.5, GuiConfig.Color),
                        ColorSequenceKeypoint.new(1, C_PANEL2),
                    }
                    Grad.Rotation = 25
                    Grad.Parent = Banner
                end

                if BannerConfig.Version then
                    local VerPill = Instance.new("TextLabel")
                    VerPill.BackgroundTransparency = 0.35
                    VerPill.BackgroundColor3 = Color3.new(0, 0, 0)
                    VerPill.Text = tostring(BannerConfig.Version)
                    VerPill.TextColor3 = C_TEXT
                    VerPill.Font = Enum.Font.GothamBold
                    VerPill.TextSize = 10
                    VerPill.Size = UDim2.new(0, 52, 0, 20)
                    VerPill.AnchorPoint = Vector2.new(1, 0)
                    VerPill.Position = UDim2.new(1, -8, 0, 8)
                    VerPill.ZIndex = 3
                    VerPill.Parent = Banner
                    corner(VerPill, 10)
                end

                CountItem = CountItem + 1
                return Banner
            end

            -- AddDivider
            function Items:AddDivider()
                local Divider = Instance.new("Frame")
                Divider.Name = "Divider"
                Divider.Parent = Body
                Divider.Size = UDim2.new(1, 0, 0, 2)
                Divider.BackgroundColor3 = GuiConfig.Color
                Divider.BackgroundTransparency = 0.7
                Divider.BorderSizePixel = 0
                Divider.LayoutOrder = CountItem

                local UIGradient = Instance.new("UIGradient")
                UIGradient.Color = ColorSequence.new {
                    ColorSequenceKeypoint.new(0, C_PANEL2),
                    ColorSequenceKeypoint.new(0.5, GuiConfig.Color),
                    ColorSequenceKeypoint.new(1, C_PANEL2),
                }
                UIGradient.Parent = Divider
                corner(Divider, 1)

                CountItem = CountItem + 1
                return Divider
            end

            -- AddSubSection
            function Items:AddSubSection(title)
                title = title or "Sub Section"
                local SubSection = Instance.new("Frame")
                SubSection.Size = UDim2.new(1, 0, 0, 28)
                SubSection.BackgroundTransparency = 1
                SubSection.LayoutOrder = CountItem
                SubSection.Parent = Body

                local SubLabel = Instance.new("TextLabel")
                SubLabel.BackgroundTransparency = 1
                SubLabel.Position = UDim2.new(0, 4, 0, 0)
                SubLabel.Size = UDim2.new(1, -8, 1, 0)
                SubLabel.Text = title
                SubLabel.TextColor3 = GuiConfig.Color
                SubLabel.Font = Enum.Font.GothamBold
                SubLabel.TextSize = 12
                SubLabel.TextXAlignment = Enum.TextXAlignment.Left
                SubLabel.Parent = SubSection

                CountItem = CountItem + 1
                return SubSection
            end

            -- AddCard
            function Items:AddCard(CardConfig)
                CardConfig = CardConfig or {}
                CardConfig.Title = CardConfig.Title or "Card"
                CardConfig.Description = CardConfig.Description or ""
                local btns = CardConfig.Buttons or {}
                local cardHeight = 60 + (#btns > 0 and 36 or 0)

                local Card = Instance.new("Frame")
                Card.BackgroundColor3 = C_PANEL2
                Card.BorderSizePixel = 0
                Card.LayoutOrder = CountItem
                Card.Size = UDim2.new(1, 0, 0, cardHeight)
                Card.Parent = Body
                corner(Card, 8)
                stroke(Card, C_BORDER, 1)

                local CardTitle = Instance.new("TextLabel")
                CardTitle.Font = Enum.Font.GothamBold
                CardTitle.Text = CardConfig.Title
                CardTitle.TextColor3 = C_TEXT
                CardTitle.TextSize = 13
                CardTitle.TextXAlignment = Enum.TextXAlignment.Left
                CardTitle.BackgroundTransparency = 1
                CardTitle.Position = UDim2.new(0, 12, 0, 8)
                CardTitle.Size = UDim2.new(1, -24, 0, 16)
                CardTitle.Parent = Card

                local CardDesc = Instance.new("TextLabel")
                CardDesc.Font = Enum.Font.Gotham
                CardDesc.Text = CardConfig.Description
                CardDesc.TextColor3 = C_SUBTEXT
                CardDesc.TextSize = 11
                CardDesc.TextXAlignment = Enum.TextXAlignment.Left
                CardDesc.TextYAlignment = Enum.TextYAlignment.Top
                CardDesc.TextWrapped = true
                CardDesc.BackgroundTransparency = 1
                CardDesc.Position = UDim2.new(0, 12, 0, 26)
                CardDesc.Size = UDim2.new(1, -24, 0, 24)
                CardDesc.Parent = Card

                if #btns > 0 then
                    local Row = Instance.new("Frame")
                    Row.BackgroundTransparency = 1
                    Row.Position = UDim2.new(0, 8, 0, cardHeight - 34)
                    Row.Size = UDim2.new(1, -16, 0, 28)
                    Row.Parent = Card

                    local RowLayout = Instance.new("UIListLayout")
                    RowLayout.FillDirection = Enum.FillDirection.Horizontal
                    RowLayout.Padding = UDim.new(0, 6)
                    RowLayout.Parent = Row

                    for _, bd in ipairs(btns) do
                        local Btn = Instance.new("TextButton")
                        Btn.Font = Enum.Font.GothamBold
                        Btn.Text = bd.Name or "Button"
                        Btn.TextColor3 = C_TEXT
                        Btn.TextSize = 11
                        Btn.BackgroundColor3 = bd.Color or GuiConfig.Color
                        Btn.BorderSizePixel = 0
                        Btn.Size = UDim2.new(0, #btns == 1 and 200 or 100, 0, 28)
                        Btn.Parent = Row
                        corner(Btn, 6)
                        if bd.Callback then
                            Btn.MouseButton1Click:Connect(bd.Callback)
                        end
                    end
                end

                RegisterSearch({ label = CardConfig.Title, tab = TabConfig.Name, kind = "Card", switch = SearchSwitch })
                CountItem = CountItem + 1
                return Card
            end

            -- AddPanel
            function Items:AddPanel(PanelConfig)
                PanelConfig = PanelConfig or {}
                PanelConfig.Title = PanelConfig.Title or "Title"
                PanelConfig.Content = PanelConfig.Content or ""
                PanelConfig.Placeholder = PanelConfig.Placeholder or nil
                PanelConfig.Default = PanelConfig.Default or ""
                PanelConfig.ButtonText = PanelConfig.Button or PanelConfig.ButtonText or "Confirm"
                PanelConfig.ButtonCallback = PanelConfig.Callback or PanelConfig.ButtonCallback or function() end
                PanelConfig.SubButtonText = PanelConfig.SubButton or PanelConfig.SubButtonText or nil
                PanelConfig.SubButtonCallback = PanelConfig.SubCallback or PanelConfig.SubButtonCallback or function() end

                local configKey = "Panel_" .. PanelConfig.Title
                local shouldSave = PanelConfig.Save ~= false
                if shouldSave and ConfigData[configKey] ~= nil then
                    PanelConfig.Default = ConfigData[configKey]
                end

                local PanelFunc = { Value = PanelConfig.Default }

                local baseHeight = 50
                if PanelConfig.Placeholder then baseHeight = baseHeight + 40 end
                if PanelConfig.SubButtonText then baseHeight = baseHeight + 40 else baseHeight = baseHeight + 36 end

                local Panel = Instance.new("Frame")
                Panel.BackgroundColor3 = C_PANEL2
                Panel.BorderSizePixel = 0
                Panel.LayoutOrder = CountItem
                Panel.Size = UDim2.new(1, 0, 0, baseHeight)
                Panel.Parent = Body
                corner(Panel, 6)
                stroke(Panel, C_BORDER, 1)

                local TitleLbl = Instance.new("TextLabel")
                TitleLbl.Font = Enum.Font.GothamBold
                TitleLbl.Text = PanelConfig.Title
                TitleLbl.TextSize = 13
                TitleLbl.TextColor3 = C_TEXT
                TitleLbl.TextXAlignment = Enum.TextXAlignment.Left
                TitleLbl.BackgroundTransparency = 1
                TitleLbl.Position = UDim2.new(0, 10, 0, 10)
                TitleLbl.Size = UDim2.new(1, -20, 0, 13)
                TitleLbl.Parent = Panel

                local ContentLbl = Instance.new("TextLabel")
                ContentLbl.Font = Enum.Font.Gotham
                ContentLbl.Text = PanelConfig.Content
                ContentLbl.TextSize = 12
                ContentLbl.TextColor3 = C_SUBTEXT
                ContentLbl.TextXAlignment = Enum.TextXAlignment.Left
                ContentLbl.RichText = true
                ContentLbl.BackgroundTransparency = 1
                ContentLbl.Position = UDim2.new(0, 10, 0, 28)
                ContentLbl.Size = UDim2.new(1, -20, 0, 14)
                ContentLbl.Parent = Panel

                local InputBox
                if PanelConfig.Placeholder then
                    local InputFrame = Instance.new("Frame")
                    InputFrame.AnchorPoint = Vector2.new(0.5, 0)
                    InputFrame.BackgroundColor3 = C_BORDER
                    InputFrame.BackgroundTransparency = 0.5
                    InputFrame.Position = UDim2.new(0.5, 0, 0, 48)
                    InputFrame.Size = UDim2.new(1, -20, 0, 30)
                    InputFrame.Parent = Panel
                    corner(InputFrame, 5)

                    InputBox = Instance.new("TextBox")
                    InputBox.Font = Enum.Font.GothamBold
                    InputBox.PlaceholderText = PanelConfig.Placeholder
                    InputBox.PlaceholderColor3 = C_SUBTEXT
                    InputBox.Text = PanelConfig.Default
                    InputBox.TextSize = 11
                    InputBox.TextColor3 = C_TEXT
                    InputBox.BackgroundTransparency = 1
                    InputBox.TextXAlignment = Enum.TextXAlignment.Left
                    InputBox.Size = UDim2.new(1, -10, 1, -6)
                    InputBox.Position = UDim2.new(0, 5, 0, 3)
                    InputBox.Parent = InputFrame
                end

                local yBtn = PanelConfig.Placeholder and 88 or 48

                local ButtonMain = Instance.new("TextButton")
                ButtonMain.Font = Enum.Font.GothamBold
                ButtonMain.Text = PanelConfig.ButtonText
                ButtonMain.TextColor3 = C_TEXT
                ButtonMain.TextSize = 12
                ButtonMain.BackgroundColor3 = C_BORDER
                ButtonMain.BackgroundTransparency = 0.7
                ButtonMain.Size = PanelConfig.SubButtonText and UDim2.new(0.5, -12, 0, 30) or UDim2.new(1, -20, 0, 30)
                ButtonMain.Position = UDim2.new(0, 10, 0, yBtn)
                ButtonMain.Parent = Panel
                corner(ButtonMain, 6)
                ButtonMain.MouseButton1Click:Connect(function()
                    pcall(function() PanelConfig.ButtonCallback(InputBox and InputBox.Text or "") end)
                end)

                if PanelConfig.SubButtonText then
                    local SubButton = Instance.new("TextButton")
                    SubButton.Font = Enum.Font.GothamBold
                    SubButton.Text = PanelConfig.SubButtonText
                    SubButton.TextColor3 = C_TEXT
                    SubButton.TextSize = 12
                    SubButton.BackgroundColor3 = C_BORDER
                    SubButton.BackgroundTransparency = 0.7
                    SubButton.Size = UDim2.new(0.5, -12, 0, 30)
                    SubButton.Position = UDim2.new(0.5, 2, 0, yBtn)
                    SubButton.Parent = Panel
                    corner(SubButton, 6)
                    SubButton.MouseButton1Click:Connect(function()
                        pcall(function() PanelConfig.SubButtonCallback(InputBox and InputBox.Text or "") end)
                    end)
                end

                if InputBox then
                    InputBox.FocusLost:Connect(function() PanelFunc:Set(InputBox.Text) end)
                end

                function PanelFunc:Set(Value, noSave)
                    Value = tostring(Value or "")
                    PanelFunc.Value = Value
                    if InputBox then InputBox.Text = Value end
                    if shouldSave then
                        ConfigData[configKey] = Value
                        if not noSave then QueueSaveConfig() end
                    end
                end

                function PanelFunc:GetInput() return InputBox and InputBox.Text or "" end

                PanelFunc:Set(PanelFunc.Value, true)
                CountItem = CountItem + 1
                if shouldSave then Elements[configKey] = PanelFunc end
                RegisterSearch({ label = PanelConfig.Title, tab = TabConfig.Name, kind = "Panel", switch = SearchSwitch })
                return PanelFunc
            end

            -- AddLogPanel
            function Items:AddLogPanel(LogConfig)
                LogConfig = LogConfig or {}
                LogConfig.Title = LogConfig.Title or "Logs"
                LogConfig.Height = LogConfig.Height or 160
                LogConfig.MaxLines = LogConfig.MaxLines or 100
                LogConfig.Timestamps = LogConfig.Timestamps ~= false

                local LogFunc = { Lines = {} }

                local Root = Instance.new("Frame")
                Root.BackgroundColor3 = C_PANEL2
                Root.BorderSizePixel = 0
                Root.LayoutOrder = CountItem
                Root.Size = UDim2.new(1, 0, 0, LogConfig.Height)
                Root.Parent = Body
                corner(Root, 6)
                stroke(Root, GuiConfig.Color, 1)
                Root.UIStroke.Transparency = 0.85

                local Header = Instance.new("Frame")
                Header.BackgroundTransparency = 1
                Header.Size = UDim2.new(1, 0, 0, 24)
                Header.Parent = Root

                local TitleLbl = Instance.new("TextLabel")
                TitleLbl.Font = Enum.Font.GothamBold
                TitleLbl.Text = LogConfig.Title
                TitleLbl.TextColor3 = GuiConfig.Color
                TitleLbl.TextSize = 13
                TitleLbl.TextXAlignment = Enum.TextXAlignment.Left
                TitleLbl.BackgroundTransparency = 1
                TitleLbl.Position = UDim2.new(0, 10, 0, 0)
                TitleLbl.Size = UDim2.new(1, -60, 1, 0)
                TitleLbl.Parent = Header

                local ClearBtn = Instance.new("TextButton")
                ClearBtn.Font = Enum.Font.GothamBold
                ClearBtn.Text = "Clear"
                ClearBtn.TextSize = 11
                ClearBtn.TextColor3 = C_TEXT
                ClearBtn.TextTransparency = 0.3
                ClearBtn.BackgroundColor3 = C_BORDER
                ClearBtn.BackgroundTransparency = 0.7
                ClearBtn.AnchorPoint = Vector2.new(1, 0.5)
                ClearBtn.Position = UDim2.new(1, -8, 0.5, 0)
                ClearBtn.Size = UDim2.new(0, 44, 0, 18)
                ClearBtn.Parent = Header
                corner(ClearBtn, 4)

                local ScrollLog = Instance.new("ScrollingFrame")
                ScrollLog.BackgroundTransparency = 1
                ScrollLog.BorderSizePixel = 0
                ScrollLog.Position = UDim2.new(0, 0, 0, 26)
                ScrollLog.Size = UDim2.new(1, 0, 1, -30)
                ScrollLog.ScrollBarThickness = 3
                ScrollLog.ScrollBarImageTransparency = 0.5
                ScrollLog.AutomaticCanvasSize = Enum.AutomaticSize.Y
                ScrollLog.CanvasSize = UDim2.new(0, 0, 0, 0)
                ScrollLog.Parent = Root
                pad(ScrollLog, 10, 0, 8, 0)

                local LogList = Instance.new("UIListLayout")
                LogList.Padding = UDim.new(0, 2)
                LogList.SortOrder = Enum.SortOrder.LayoutOrder
                LogList.Parent = ScrollLog

                local logOrder = 0

                local function ScrollToBottom()
                    task.defer(function()
                        ScrollLog.CanvasPosition = Vector2.new(0, math.max(0, ScrollLog.AbsoluteCanvasSize.Y))
                    end)
                end

                function LogFunc:Push(text, color)
                    text = tostring(text or "")
                    logOrder = logOrder + 1
                    local prefix = LogConfig.Timestamps and os.date("[%H:%M:%S] ") or ""

                    local Line = Instance.new("TextLabel")
                    Line.Font = Enum.Font.Code
                    Line.Text = prefix .. text
                    Line.TextColor3 = color or Color3.fromRGB(220, 220, 220)
                    Line.TextSize = 12
                    Line.TextXAlignment = Enum.TextXAlignment.Left
                    Line.TextWrapped = true
                    Line.BackgroundTransparency = 1
                    Line.Size = UDim2.new(1, 0, 0, 14)
                    Line.LayoutOrder = logOrder
                    Line.Parent = ScrollLog

                    local function fit() Line.Size = UDim2.new(1, 0, 0, math.max(14, Line.TextBounds.Y)) end
                    Line:GetPropertyChangedSignal("TextBounds"):Connect(fit)
                    fit()

                    table.insert(LogFunc.Lines, prefix .. text)

                    local count = 0
                    for _, c in ScrollLog:GetChildren() do
                        if c:IsA("TextLabel") then count = count + 1 end
                    end
                    if count > LogConfig.MaxLines then
                        local oldest, oldestOrder = nil, math.huge
                        for _, c in ScrollLog:GetChildren() do
                            if c:IsA("TextLabel") and c.LayoutOrder < oldestOrder then
                                oldest, oldestOrder = c, c.LayoutOrder
                            end
                        end
                        if oldest then oldest:Destroy() end
                        table.remove(LogFunc.Lines, 1)
                    end

                    ScrollToBottom()
                end

                function LogFunc:Clear()
                    for _, c in ScrollLog:GetChildren() do
                        if c:IsA("TextLabel") then c:Destroy() end
                    end
                    LogFunc.Lines = {}
                    logOrder = 0
                end

                ClearBtn.MouseButton1Click:Connect(function() LogFunc:Clear() end)

                CountItem = CountItem + 1
                RegisterSearch({ label = LogConfig.Title, tab = TabConfig.Name, kind = "Log", switch = SearchSwitch })
                return LogFunc
            end

            -- AddListView
            function Items:AddListView(ListConfig)
                ListConfig = ListConfig or {}
                ListConfig.Title = ListConfig.Title or "List"
                ListConfig.Height = ListConfig.Height or 220
                ListConfig.Search = ListConfig.Search ~= false
                ListConfig.RenderRow = ListConfig.RenderRow or function(item, RowAPI)
                    local Label = Instance.new("TextLabel")
                    Label.Font = Enum.Font.Gotham
                    Label.Text = tostring(item)
                    Label.TextColor3 = C_TEXT
                    Label.TextSize = 12
                    Label.TextXAlignment = Enum.TextXAlignment.Left
                    Label.BackgroundTransparency = 1
                    Label.Size = UDim2.new(1, -16, 1, 0)
                    Label.Position = UDim2.new(0, 8, 0, 0)
                    Label.Parent = RowAPI.Container
                end
                ListConfig.GetLabel = ListConfig.GetLabel or function(item) return tostring(item) end
                ListConfig.OnSelect = ListConfig.OnSelect or function(item) end
                ListConfig.RowHeight = ListConfig.RowHeight or 34

                local ListFunc = { Items = {} }

                local Root = Instance.new("Frame")
                Root.BackgroundColor3 = C_PANEL2
                Root.BorderSizePixel = 0
                Root.LayoutOrder = CountItem
                Root.Size = UDim2.new(1, 0, 0, ListConfig.Height)
                Root.Parent = Body
                corner(Root, 6)
                stroke(Root, GuiConfig.Color, 1)
                Root.UIStroke.Transparency = 0.85

                local topOffset = 8
                local TitleLbl = Instance.new("TextLabel")
                TitleLbl.Font = Enum.Font.GothamBold
                TitleLbl.Text = ListConfig.Title
                TitleLbl.TextColor3 = GuiConfig.Color
                TitleLbl.TextSize = 13
                TitleLbl.TextXAlignment = Enum.TextXAlignment.Left
                TitleLbl.BackgroundTransparency = 1
                TitleLbl.Position = UDim2.new(0, 10, 0, topOffset)
                TitleLbl.Size = UDim2.new(1, -20, 0, 16)
                TitleLbl.Parent = Root
                topOffset = topOffset + 20

                local SearchBox
                if ListConfig.Search then
                    SearchBox = Instance.new("TextBox")
                    SearchBox.PlaceholderText = "Search..."
                    SearchBox.Font = Enum.Font.Gotham
                    SearchBox.Text = ""
                    SearchBox.TextSize = 12
                    SearchBox.TextColor3 = C_TEXT
                    SearchBox.ClearTextOnFocus = false
                    SearchBox.BackgroundColor3 = C_BORDER
                    SearchBox.BackgroundTransparency = 0.7
                    SearchBox.BorderSizePixel = 0
                    SearchBox.Position = UDim2.new(0, 8, 0, topOffset)
                    SearchBox.Size = UDim2.new(1, -16, 0, 24)
                    SearchBox.Parent = Root
                    corner(SearchBox, 4)
                    pad(SearchBox, 8, 0, 0, 0)
                    topOffset = topOffset + 30
                end

                local ScrollList = Instance.new("ScrollingFrame")
                ScrollList.BackgroundTransparency = 1
                ScrollList.BorderSizePixel = 0
                ScrollList.Position = UDim2.new(0, 0, 0, topOffset)
                ScrollList.Size = UDim2.new(1, 0, 1, -(topOffset + 6))
                ScrollList.ScrollBarThickness = 3
                ScrollList.ScrollBarImageTransparency = 0.5
                ScrollList.CanvasSize = UDim2.new(0, 0, 0, 0)
                ScrollList.Parent = Root
                pad(ScrollList, 8, 0, 8, 0)

                local RowsList = Instance.new("UIListLayout")
                RowsList.Padding = UDim.new(0, 4)
                RowsList.SortOrder = Enum.SortOrder.LayoutOrder
                RowsList.Parent = ScrollList

                RowsList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                    ScrollList.CanvasSize = UDim2.new(0, 0, 0, RowsList.AbsoluteContentSize.Y)
                end)

                local selectedRow = nil

                local function BuildRow(item, order)
                    local RowFrame = Instance.new("Frame")
                    RowFrame.BackgroundColor3 = C_BORDER
                    RowFrame.BackgroundTransparency = 0.94
                    RowFrame.BorderSizePixel = 0
                    RowFrame.Size = UDim2.new(1, 0, 0, ListConfig.RowHeight)
                    RowFrame.LayoutOrder = order
                    RowFrame.Name = "Row"
                    RowFrame.Parent = ScrollList
                    corner(RowFrame, 4)

                    local RowStroke = Instance.new("UIStroke")
                    RowStroke.Color = GuiConfig.Color
                    RowStroke.Thickness = 1
                    RowStroke.Transparency = 1
                    RowStroke.Parent = RowFrame

                    local RowBtn = Instance.new("TextButton")
                    RowBtn.Text = ""
                    RowBtn.BackgroundTransparency = 1
                    RowBtn.Size = UDim2.new(1, 0, 1, 0)
                    RowBtn.ZIndex = 1
                    RowBtn.Parent = RowFrame

                    local RowAPI = {
                        Container = RowFrame,
                        SetHighlight = function(on)
                            RowStroke.Transparency = on and 0.4 or 1
                            RowFrame.BackgroundTransparency = on and 0.85 or 0.94
                        end,
                    }

                    ListConfig.RenderRow(item, RowAPI)

                    RowBtn.MouseButton1Click:Connect(function()
                        if selectedRow and selectedRow ~= RowAPI then
                            selectedRow.SetHighlight(false)
                        end
                        RowAPI.SetHighlight(true)
                        selectedRow = RowAPI
                        ListConfig.OnSelect(item)
                    end)

                    return RowFrame
                end

                function ListFunc:Clear()
                    for _, c in ScrollList:GetChildren() do
                        if c.Name == "Row" then c:Destroy() end
                    end
                    selectedRow = nil
                end

                function ListFunc:SetItems(items)
                    ListFunc.Items = items or {}
                    ListFunc:Refresh()
                end

                function ListFunc:Refresh()
                    ListFunc:Clear()
                    local query = SearchBox and string.lower(SearchBox.Text) or ""
                    local order = 0
                    for _, item in ipairs(ListFunc.Items) do
                        local label = string.lower(ListConfig.GetLabel(item))
                        if query == "" or string.find(label, query, 1, true) then
                            order = order + 1
                            BuildRow(item, order)
                        end
                    end
                end

                if SearchBox then
                    local searchTicket = 0
                    SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
                        searchTicket = searchTicket + 1
                        local ticket = searchTicket
                        task.delay(0.08, function()
                            if ticket == searchTicket then ListFunc:Refresh() end
                        end)
                    end)
                end

                CountItem = CountItem + 1
                RegisterSearch({ label = ListConfig.Title, tab = TabConfig.Name, kind = "List", switch = SearchSwitch })
                return ListFunc
            end


            function Items:AddInlinePicker(PickerConfig)
                PickerConfig = PickerConfig or {}
                PickerConfig.Title = PickerConfig.Title or "Picker"
                PickerConfig.Options = PickerConfig.Options or {}
                PickerConfig.Multi = PickerConfig.Multi or false
                PickerConfig.Callback = PickerConfig.Callback or function(_) end
                PickerConfig.Default = PickerConfig.Default or (PickerConfig.Multi and {} or nil)

                local configKey = "InlinePicker_" .. PickerConfig.Title
                local shouldSave = PickerConfig.Save ~= false
                if shouldSave and ConfigData[configKey] ~= nil then
                    PickerConfig.Default = ConfigData[configKey]
                end

                local PickerFunc = { Value = PickerConfig.Default, Options = PickerConfig.Options }

                local function Persist()
                    if not shouldSave then return end
                    ConfigData[configKey] = PickerFunc.Value
                    QueueSaveConfig()
                end

                local function CurrentLabel()
                    if PickerConfig.Multi then
                        local n = 0
                        for _ in pairs(PickerFunc.Value or {}) do n = n + 1 end
                        return n == 0 and "None selected" or (n .. " selected")
                    else
                        return PickerFunc.Value and tostring(PickerFunc.Value) or "None selected"
                    end
                end

                local Root = Instance.new("Frame")
                Root.BackgroundColor3 = C_PANEL2
                Root.BorderSizePixel = 0
                Root.LayoutOrder = CountItem
                Root.ClipsDescendants = true
                Root.Size = UDim2.new(1, 0, 0, 46)
                Root.Parent = Body
                corner(Root, 6)

                local HeaderBtn = Instance.new("TextButton")
                HeaderBtn.Text = ""
                HeaderBtn.BackgroundTransparency = 1
                HeaderBtn.Size = UDim2.new(1, 0, 0, 46)
                HeaderBtn.Parent = Root

                local PTitle = Instance.new("TextLabel")
                PTitle.Font = Enum.Font.GothamBold
                PTitle.Text = PickerConfig.Title
                PTitle.TextColor3 = C_TEXT
                PTitle.TextSize = 13
                PTitle.TextXAlignment = Enum.TextXAlignment.Left
                PTitle.BackgroundTransparency = 1
                PTitle.Position = UDim2.new(0, 10, 0, 10)
                PTitle.Size = UDim2.new(1, -160, 0, 13)
                PTitle.Parent = Root

                local PValue = Instance.new("TextLabel")
                PValue.Font = Enum.Font.Gotham
                PValue.Text = CurrentLabel()
                PValue.TextColor3 = C_SUBTEXT
                PValue.TextSize = 12
                PValue.TextXAlignment = Enum.TextXAlignment.Left
                PValue.BackgroundTransparency = 1
                PValue.Position = UDim2.new(0, 10, 0, 25)
                PValue.Size = UDim2.new(1, -160, 0, 12)
                PValue.Parent = Root

                local Chevron = Instance.new("TextLabel")
                Chevron.Font = Enum.Font.GothamBold
                Chevron.Text = "\226\150\182"
                Chevron.TextColor3 = GuiConfig.Color
                Chevron.TextSize = 16
                Chevron.AnchorPoint = Vector2.new(1, 0.5)
                Chevron.BackgroundTransparency = 1
                Chevron.Position = UDim2.new(1, -10, 0, 23)
                Chevron.Size = UDim2.new(0, 20, 0, 20)
                Chevron.Parent = Root

                local BodyF = Instance.new("Frame")
                BodyF.BackgroundTransparency = 1
                BodyF.Position = UDim2.new(0, 0, 0, 46)
                BodyF.Size = UDim2.new(1, 0, 0, 0)
                BodyF.Parent = Root
                pad(BodyF, 8, 0, 8, 8)

                local SearchBox = Instance.new("TextBox")
                SearchBox.PlaceholderText = "Search..."
                SearchBox.Font = Enum.Font.Gotham
                SearchBox.Text = ""
                SearchBox.TextSize = 12
                SearchBox.TextColor3 = C_TEXT
                SearchBox.ClearTextOnFocus = false
                SearchBox.BackgroundColor3 = C_BORDER
                SearchBox.BackgroundTransparency = 0.7
                SearchBox.BorderSizePixel = 0
                SearchBox.Position = UDim2.new(0, 0, 0, 0)
                SearchBox.Size = UDim2.new(1, 0, 0, 24)
                SearchBox.Parent = BodyF
                corner(SearchBox, 4)
                pad(SearchBox, 8, 0, 0, 0)

                local OptList = Instance.new("Frame")
                OptList.BackgroundTransparency = 1
                OptList.Position = UDim2.new(0, 0, 0, 30)
                OptList.Size = UDim2.new(1, 0, 0, 0)
                OptList.AutomaticSize = Enum.AutomaticSize.Y
                OptList.Parent = BodyF

                local OptListLayout = Instance.new("UIListLayout")
                OptListLayout.Padding = UDim.new(0, 3)
                OptListLayout.SortOrder = Enum.SortOrder.LayoutOrder
                OptListLayout.Parent = OptList

                local expanded = false
                local optionButtons = {}

                local function IsSelected(opt)
                    if PickerConfig.Multi then
                        return PickerFunc.Value and PickerFunc.Value[opt] == true
                    else
                        return PickerFunc.Value == opt
                    end
                end

                local function RefreshVisuals()
                    PValue.Text = CurrentLabel()
                    for opt, btn in pairs(optionButtons) do
                        if btn and btn.Parent then
                            btn.BackgroundTransparency = IsSelected(opt) and 0.7 or 0.94
                        end
                    end
                end

                local function Resize()
                    task.defer(function()
                        local bodyH = expanded and (30 + OptListLayout.AbsoluteContentSize.Y + 8) or 0
                        BodyF.Size = UDim2.new(1, 0, 0, bodyH)
                        Root.Size = UDim2.new(1, 0, 0, 46 + bodyH)
                        UpdateSizeSection()
                    end)
                end

                local function SelectOption(opt)
                    if PickerConfig.Multi then
                        PickerFunc.Value = PickerFunc.Value or {}
                        if PickerFunc.Value[opt] then
                            PickerFunc.Value[opt] = nil
                        else
                            PickerFunc.Value[opt] = true
                        end
                    else
                        PickerFunc.Value = opt
                    end
                    RefreshVisuals()
                    Persist()
                    pcall(function() PickerConfig.Callback(PickerFunc.Value) end)
                end

                local function BuildOptions()
                    for _, c in OptList:GetChildren() do
                        if c:IsA("GuiObject") then c:Destroy() end
                    end
                    optionButtons = {}

                    local query = string.lower(SearchBox.Text)
                    local order = 0
                    for _, opt in ipairs(PickerConfig.Options) do
                        local label = string.lower(tostring(opt))
                        if query == "" or string.find(label, query, 1, true) then
                            order = order + 1
                            local OptBtn = Instance.new("TextButton")
                            OptBtn.Font = Enum.Font.Gotham
                            OptBtn.Text = tostring(opt)
                            OptBtn.TextColor3 = C_TEXT
                            OptBtn.TextSize = 12
                            OptBtn.TextXAlignment = Enum.TextXAlignment.Left
                            OptBtn.BackgroundColor3 = C_BORDER
                            OptBtn.BackgroundTransparency = IsSelected(opt) and 0.7 or 0.94
                            OptBtn.Size = UDim2.new(1, 0, 0, 24)
                            OptBtn.LayoutOrder = order
                            OptBtn.Parent = OptList
                            corner(OptBtn, 4)
                            pad(OptBtn, 8, 0, 0, 0)

                            optionButtons[opt] = OptBtn
                            OptBtn.MouseButton1Click:Connect(function() SelectOption(opt) end)
                        end
                    end
                    Resize()
                end

                HeaderBtn.MouseButton1Click:Connect(function()
                    expanded = not expanded
                    Chevron.Text = expanded and "\226\150\180" or "\226\150\182"
                    Root.ClipsDescendants = not expanded
                    if expanded then BuildOptions() else Resize() end
                end)

                local searchTicket = 0
                SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
                    searchTicket = searchTicket + 1
                    local ticket = searchTicket
                    task.delay(0.08, function()
                        if ticket == searchTicket then BuildOptions() end
                    end)
                end)

                function PickerFunc:Get() return PickerFunc.Value end
                function PickerFunc:Set(value)
                    PickerFunc.Value = value
                    RefreshVisuals()
                    Persist()
                end
                function PickerFunc:SetOptions(list)
                    PickerConfig.Options = list or {}
                    PickerFunc.Options = PickerConfig.Options
                    if expanded then BuildOptions() end
                end

                CountItem = CountItem + 1
                RegisterSearch({ label = PickerConfig.Title, tab = TabConfig.Name, kind = "Picker", switch = SearchSwitch })
                return PickerFunc
            end

            CountSection = CountSection + 1
            return Items
        end

        local safeName = TabConfig.Name:gsub("%s+", "_")
        _G[safeName] = Sections
        return Sections
    end


    task.defer(function()
        LoadConfigElements()
    end)

    Tabs.Window = GuiFunc
    Tabs.ExportConfig = function() return GuiFunc:ExportConfig() end
    Tabs.ImportConfig = function(_, str) return GuiFunc:ImportConfig(str) end
    Tabs.Confirm = function(_, config) return GuiFunc:Confirm(config) end

    return Tabs
end

function Chloex:MakeNotify(NotifyConfig)
    local NotifyConfig = NotifyConfig or {}
    NotifyConfig.Title = NotifyConfig.Title or "HydraHub"
    NotifyConfig.Description = NotifyConfig.Description or "Notification"
    NotifyConfig.Content = NotifyConfig.Content or "Content"
    NotifyConfig.Color = NotifyConfig.Color or Color3.fromRGB(255, 0, 255)
    NotifyConfig.Time = NotifyConfig.Time or 0.5
    NotifyConfig.Delay = NotifyConfig.Delay or 5
    local NotifyFunction = {}
    spawn(function()
        if not CoreGui:FindFirstChild("NotifyGui") then
            local NotifyGui = Instance.new("ScreenGui")
            NotifyGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
            NotifyGui.Name = "NotifyGui"
            NotifyGui.Parent = CoreGui
        end
        if not CoreGui.NotifyGui:FindFirstChild("NotifyLayout") then
            local NotifyLayout = Instance.new("Frame")
            NotifyLayout.AnchorPoint = Vector2.new(1, 1)
            NotifyLayout.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            NotifyLayout.BackgroundTransparency = 0.9990000128746033
            NotifyLayout.BorderColor3 = Color3.fromRGB(0, 0, 0)
            NotifyLayout.BorderSizePixel = 0
            NotifyLayout.Position = UDim2.new(1, -30, 1, -30)
            NotifyLayout.Size = UDim2.new(0, 320, 1, 0)
            NotifyLayout.Name = "NotifyLayout"
            NotifyLayout.Parent = CoreGui.NotifyGui
            local Count = 0
            CoreGui.NotifyGui.NotifyLayout.ChildRemoved:Connect(function()
                Count = 0
                for i, v in CoreGui.NotifyGui.NotifyLayout:GetChildren() do
                    TweenService:Create(
                        v,
                        TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
                        { Position = UDim2.new(0, 0, 1, -((v.Size.Y.Offset + 12) * Count)) }
                    ):Play()
                    Count = Count + 1
                end
            end)
        end
        local NotifyPosHeigh = 0
        for i, v in CoreGui.NotifyGui.NotifyLayout:GetChildren() do
            NotifyPosHeigh = -(v.Position.Y.Offset) + v.Size.Y.Offset + 12
        end
        local NotifyFrame = Instance.new("Frame")
        local NotifyFrameReal = Instance.new("Frame")
        local UICorner = Instance.new("UICorner")
        local DropShadowHolder = Instance.new("Frame")
        local DropShadow = Instance.new("ImageLabel")
        local Top = Instance.new("Frame")
        local TextLabel = Instance.new("TextLabel")
        local UICorner1 = Instance.new("UICorner")
        local TextLabel1 = Instance.new("TextLabel")
        local Close = Instance.new("TextButton")
        local ImageLabel = Instance.new("ImageLabel")
        local TextLabel2 = Instance.new("TextLabel")

        NotifyFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        NotifyFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
        NotifyFrame.BorderSizePixel = 0
        NotifyFrame.Size = UDim2.new(1, 0, 0, 150)
        NotifyFrame.Name = "NotifyFrame"
        NotifyFrame.BackgroundTransparency = 1
        NotifyFrame.Parent = CoreGui.NotifyGui.NotifyLayout
        NotifyFrame.AnchorPoint = Vector2.new(0, 1)
        NotifyFrame.Position = UDim2.new(0, 0, 1, -(NotifyPosHeigh))

        NotifyFrameReal.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        NotifyFrameReal.BorderColor3 = Color3.fromRGB(0, 0, 0)
        NotifyFrameReal.BorderSizePixel = 0
        NotifyFrameReal.Position = UDim2.new(0, 400, 0, 0)
        NotifyFrameReal.Size = UDim2.new(1, 0, 1, 0)
        NotifyFrameReal.Name = "NotifyFrameReal"
        NotifyFrameReal.Parent = NotifyFrame

        UICorner.Parent = NotifyFrameReal
        UICorner.CornerRadius = UDim.new(0, 8)

        DropShadowHolder.BackgroundTransparency = 1
        DropShadowHolder.BorderSizePixel = 0
        DropShadowHolder.Size = UDim2.new(1, 0, 1, 0)
        DropShadowHolder.ZIndex = 0
        DropShadowHolder.Name = "DropShadowHolder"
        DropShadowHolder.Parent = NotifyFrameReal

        Top.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        Top.BackgroundTransparency = 0.9990000128746033
        Top.BorderColor3 = Color3.fromRGB(0, 0, 0)
        Top.BorderSizePixel = 0
        Top.Size = UDim2.new(1, 0, 0, 36)
        Top.Name = "Top"
        Top.Parent = NotifyFrameReal

        TextLabel.Font = Enum.Font.GothamBold
        TextLabel.Text = NotifyConfig.Title
        TextLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        TextLabel.TextSize = 14
        TextLabel.TextXAlignment = Enum.TextXAlignment.Left
        TextLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        TextLabel.BackgroundTransparency = 0.9990000128746033
        TextLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
        TextLabel.BorderSizePixel = 0
        TextLabel.Size = UDim2.new(1, 0, 1, 0)
        TextLabel.Parent = Top
        TextLabel.Position = UDim2.new(0, 10, 0, 0)

        UICorner1.Parent = Top
        UICorner1.CornerRadius = UDim.new(0, 5)

        TextLabel1.Font = Enum.Font.GothamBold
        TextLabel1.Text = NotifyConfig.Description
        TextLabel1.TextColor3 = NotifyConfig.Color
        TextLabel1.TextSize = 14
        TextLabel1.TextXAlignment = Enum.TextXAlignment.Left
        TextLabel1.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        TextLabel1.BackgroundTransparency = 0.9990000128746033
        TextLabel1.BorderColor3 = Color3.fromRGB(0, 0, 0)
        TextLabel1.BorderSizePixel = 0
        TextLabel1.Size = UDim2.new(1, 0, 1, 0)
        TextLabel1.Position = UDim2.new(0, TextLabel.TextBounds.X + 15, 0, 0)
        TextLabel1.Parent = Top

        Close.Font = Enum.Font.SourceSans
        Close.Text = ""
        Close.TextColor3 = Color3.fromRGB(0, 0, 0)
        Close.TextSize = 14
        Close.AnchorPoint = Vector2.new(1, 0.5)
        Close.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        Close.BackgroundTransparency = 0.9990000128746033
        Close.BorderColor3 = Color3.fromRGB(0, 0, 0)
        Close.BorderSizePixel = 0
        Close.Position = UDim2.new(1, -5, 0.5, 0)
        Close.Size = UDim2.new(0, 25, 0, 25)
        Close.Name = "Close"
        Close.Parent = Top

        ImageLabel.Image = "rbxassetid://9886659671"
        ImageLabel.AnchorPoint = Vector2.new(0.5, 0.5)
        ImageLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        ImageLabel.BackgroundTransparency = 0.9990000128746033
        ImageLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
        ImageLabel.BorderSizePixel = 0
        ImageLabel.Position = UDim2.new(0.49000001, 0, 0.5, 0)
        ImageLabel.Size = UDim2.new(1, -8, 1, -8)
        ImageLabel.Parent = Close

        TextLabel2.Font = Enum.Font.GothamBold
        TextLabel2.TextColor3 = Color3.fromRGB(255, 255, 255)
        TextLabel2.TextSize = 13
        TextLabel2.Text = NotifyConfig.Content
        TextLabel2.TextXAlignment = Enum.TextXAlignment.Left
        TextLabel2.TextYAlignment = Enum.TextYAlignment.Top
        TextLabel2.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        TextLabel2.BackgroundTransparency = 0.9990000128746033
        TextLabel2.TextColor3 = Color3.fromRGB(150, 150, 150)
        TextLabel2.BorderColor3 = Color3.fromRGB(0, 0, 0)
        TextLabel2.BorderSizePixel = 0
        TextLabel2.Position = UDim2.new(0, 10, 0, 27)
        TextLabel2.Parent = NotifyFrameReal
        TextLabel2.Size = UDim2.new(1, -20, 0, 13)

        TextLabel2.Size = UDim2.new(1, -20, 0, 13 + (13 * (TextLabel2.TextBounds.X // TextLabel2.AbsoluteSize.X)))
        TextLabel2.TextWrapped = true

        if TextLabel2.AbsoluteSize.Y < 27 then
            NotifyFrame.Size = UDim2.new(1, 0, 0, 65)
        else
            NotifyFrame.Size = UDim2.new(1, 0, 0, TextLabel2.AbsoluteSize.Y + 40)
        end
        local waitbruh = false
        function NotifyFunction:Close()
            if waitbruh then
                return false
            end
            waitbruh = true
            TweenService:Create(
                NotifyFrameReal,
                TweenInfo.new(tonumber(NotifyConfig.Time), Enum.EasingStyle.Back, Enum.EasingDirection.InOut),
                { Position = UDim2.new(0, 400, 0, 0) }
            ):Play()
            task.wait(tonumber(NotifyConfig.Time) / 1.2)
            NotifyFrame:Destroy()
        end

        Close.Activated:Connect(function()
            NotifyFunction:Close()
        end)
        TweenService:Create(
            NotifyFrameReal,
            TweenInfo.new(tonumber(NotifyConfig.Time), Enum.EasingStyle.Back, Enum.EasingDirection.InOut),
            { Position = UDim2.new(0, 0, 0, 0) }
        ):Play()
        task.wait(tonumber(NotifyConfig.Delay))
        NotifyFunction:Close()
    end)
    return NotifyFunction
end

function than(msg, delay, color, title, desc)
    return Chloex:MakeNotify({
        Title = title or "HydraHub",
        Description = desc or "Notification",
        Content = msg or "Content",
        Color = color or Color3.fromRGB(0, 208, 255),
        Delay = delay or 4
    })
end

return Chloex
