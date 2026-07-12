local HttpService = game:GetService("HttpService")

if not isfolder("HydraHub") then
    makefolder("HydraHub")
end
if not isfolder("HydraHub/Config") then
    makefolder("HydraHub/Config")
end

local gameName   = tostring(game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name)
gameName         = gameName:gsub("[^%w_ ]", "")
gameName         = gameName:gsub("%s+", "_")

local ConfigFile = "HydraHub/Config/" .. gameName .. ".json"
local ConfigFolder = "HydraHub/Configs"
local GameConfigFolder = ConfigFolder .. "/" .. gameName

ConfigData       = {}
Elements         = {}
CURRENT_VERSION  = nil
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
    if mode ~= nil then
        ActiveConfigMode = mode
    elseif name == nil then
        ActiveConfigMode = nil
    end
    if autoSave ~= nil then
        AutoSaveEnabled = autoSave
    end
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

    local ok, auto = pcall(function()
        return HttpService:JSONDecode(readfile(autoPath))
    end)
    local autoName = ok and type(auto) == "table" and tostring(auto.Name or "") or ""
    if autoName == "" then return end

    local configPath = GameConfigFolder .. "/" .. autoName .. ".json"
    if isfile and isfile(configPath) then
        local success, result = pcall(function()
            return HttpService:JSONDecode(readfile(configPath))
        end)
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

local Icons = {
    player    = "rbxassetid://12120698352",
    web       = "rbxassetid://137601480983962",
    bag       = "rbxassetid://8601111810",
    shop      = "rbxassetid://4985385964",
    cart      = "rbxassetid://128874923961846",
    plug      = "rbxassetid://137601480983962",
    settings  = "rbxassetid://70386228443175",
    loop      = "rbxassetid://122032243989747",
    gps       = "rbxassetid://17824309485",
    compas    = "rbxassetid://125300760963399",
    gamepad   = "rbxassetid://84173963561612",
    boss      = "rbxassetid://13132186360",
    scroll    = "rbxassetid://114127804740858",
    menu      = "rbxassetid://6340513838",
    crosshair = "rbxassetid://12614416478",
    user      = "rbxassetid://108483430622128",
    stat      = "rbxassetid://12094445329",
    eyes      = "rbxassetid://14321059114",
    sword     = "rbxassetid://82472368671405",
    discord   = "rbxassetid://94434236999817",
    star      = "rbxassetid://107005941750079",
    skeleton  = "rbxassetid://17313330026",
    payment   = "rbxassetid://18747025078",
    scan      = "rbxassetid://109869955247116",
    alert     = "rbxassetid://73186275216515",
    question  = "rbxassetid://17510196486",
    idea      = "rbxassetid://16833255748",
    strom     = "rbxassetid://13321880293",
    water     = "rbxassetid://100076212630732",
    dcs       = "rbxassetid://15310731934",
    start     = "rbxassetid://108886429866687",
    next      = "rbxassetid://12662718374",
    rod       = "rbxassetid://103247953194129",
    fish      = "rbxassetid://97167558235554",
}

local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = game:GetService("Players").LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local CoreGui = game:GetService("CoreGui")
local viewport = workspace.CurrentCamera.ViewportSize

local function isMobileDevice()
    return UserInputService.TouchEnabled
        and not UserInputService.KeyboardEnabled
        and not UserInputService.MouseEnabled
end

local isMobile = isMobileDevice()

local function safeSize(pxWidth, pxHeight)
    local scaleX = pxWidth / viewport.X
    local scaleY = pxHeight / viewport.Y

    if isMobile then
        if scaleX > 0.5 then scaleX = 0.5 end
        if scaleY > 0.3 then scaleY = 0.3 end
    end

    return UDim2.new(scaleX, 0, scaleY, 0)
end

local function MakeDraggable(topbarobject, object)
    local function CustomPos(topbarobject, object)
        local Dragging, DragInput, DragStart, StartPosition

        local function UpdatePos(input)
            local Delta = input.Position - DragStart
            local pos = UDim2.new(
                StartPosition.X.Scale,
                StartPosition.X.Offset + Delta.X,
                StartPosition.Y.Scale,
                StartPosition.Y.Offset + Delta.Y
            )
            object.Position = pos
        end

        topbarobject.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                Dragging = true
                DragStart = input.Position
                StartPosition = object.Position
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        Dragging = false
                    end
                end)
            end
        end)

        topbarobject.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                DragInput = input
            end
        end)

        UserInputService.InputChanged:Connect(function(input)
            if input == DragInput and Dragging then
                UpdatePos(input)
            end
        end)
    end

    local function CustomSize(object)
        local Dragging, DragInput, DragStart, StartSize

        local minSizeX, minSizeY
        local defSizeX, defSizeY

        if isMobile then
            minSizeX, minSizeY = 100, 100
            defSizeX, defSizeY = 470, 270
        else
            minSizeX, minSizeY = 100, 100
            defSizeX, defSizeY = 640, 400
        end

        object.Size = UDim2.new(0, defSizeX, 0, defSizeY)

        local changesizeobject = Instance.new("Frame")
        changesizeobject.AnchorPoint = Vector2.new(1, 1)
        changesizeobject.BackgroundTransparency = 1
        changesizeobject.Size = UDim2.new(0, 40, 0, 40)
        changesizeobject.Position = UDim2.new(1, 20, 1, 20)
        changesizeobject.Name = "changesizeobject"
        changesizeobject.Parent = object

        local function UpdateSize(input)
            local Delta = input.Position - DragStart
            local newWidth = StartSize.X.Offset + Delta.X
            local newHeight = StartSize.Y.Offset + Delta.Y

            newWidth = math.max(newWidth, minSizeX)
            newHeight = math.max(newHeight, minSizeY)

            object.Size = UDim2.new(0, newWidth, 0, newHeight)
        end

        changesizeobject.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                Dragging = true
                DragStart = input.Position
                StartSize = object.Size
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        Dragging = false
                    end
                end)
            end
        end)

        changesizeobject.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                DragInput = input
            end
        end)

        UserInputService.InputChanged:Connect(function(input)
            if input == DragInput and Dragging then
                UpdateSize(input)
            end
        end)

        -- ===== RESIZE HANDLE: TOP-LEFT =====
        local DraggingTL, DragInputTL, DragStartTL, StartSizeTL, StartPosTL

        local changesizeobjectTL = Instance.new("Frame")
        changesizeobjectTL.AnchorPoint = Vector2.new(0, 0)
        changesizeobjectTL.BackgroundTransparency = 1
        changesizeobjectTL.Size = UDim2.new(0, 40, 0, 40)
        changesizeobjectTL.Position = UDim2.new(0, -20, 0, -20)
        changesizeobjectTL.Name = "changesizeobjectTL"
        changesizeobjectTL.Parent = object

        local function UpdateSizeTL(input)
            local Delta = input.Position - DragStartTL

            local newWidth = StartSizeTL.X.Offset - Delta.X
            local newHeight = StartSizeTL.Y.Offset - Delta.Y

            newWidth = math.max(newWidth, minSizeX)
            newHeight = math.max(newHeight, minSizeY)

            local actualDeltaW = StartSizeTL.X.Offset - newWidth
            local actualDeltaH = StartSizeTL.Y.Offset - newHeight

            object.Size = UDim2.new(0, newWidth, 0, newHeight)
            object.Position = UDim2.new(
                StartPosTL.X.Scale,
                StartPosTL.X.Offset + actualDeltaW,
                StartPosTL.Y.Scale,
                StartPosTL.Y.Offset + actualDeltaH
            )
        end

        changesizeobjectTL.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                DraggingTL = true
                DragStartTL = input.Position
                StartSizeTL = object.Size
                StartPosTL = object.Position
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        DraggingTL = false
                    end
                end)
            end
        end)

        changesizeobjectTL.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                DragInputTL = input
            end
        end)

        UserInputService.InputChanged:Connect(function(input)
            if input == DragInputTL and DraggingTL then
                UpdateSizeTL(input)
            end
        end)
        -- ===== END TOP-LEFT =====
    end

    CustomSize(object)
    CustomPos(topbarobject, object)
end

function CircleClick(Button, X, Y)
    spawn(function()
        Button.ClipsDescendants = true
        local Circle = Instance.new("ImageLabel")
        Circle.Image = "rbxassetid://266543268"
        Circle.ImageColor3 = Color3.fromRGB(80, 80, 80)
        Circle.ImageTransparency = 0.8999999761581421
        Circle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
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
        elseif Button.AbsoluteSize.X == Button.AbsoluteSize.Y then
            Size = Button.AbsoluteSize.X * 1.5
        end

        local Time = 0.5
        Circle:TweenSizeAndPosition(UDim2.new(0, Size, 0, Size), UDim2.new(0.5, -Size / 2, 0.5, -Size / 2), "Out", "Quad",
            Time, false, nil)
        TweenService:Create(Circle, TweenInfo.new(Time, Enum.EasingStyle.Quad), { ImageTransparency = 1 }):Play()
        task.wait(Time)
        Circle:Destroy()
    end)
end

local Chloex = {}
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
            local NotifyGui = Instance.new("ScreenGui");
            NotifyGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
            NotifyGui.Name = "NotifyGui"
            NotifyGui.Parent = CoreGui
        end
        if not CoreGui.NotifyGui:FindFirstChild("NotifyLayout") then
            local NotifyLayout = Instance.new("Frame");
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
        local NotifyFrame = Instance.new("Frame");
        local NotifyFrameReal = Instance.new("Frame");
        local UICorner = Instance.new("UICorner");
        local DropShadowHolder = Instance.new("Frame");
        local DropShadow = Instance.new("ImageLabel");
        local Top = Instance.new("Frame");
        local TextLabel = Instance.new("TextLabel");
        local UICorner1 = Instance.new("UICorner");
        local TextLabel1 = Instance.new("TextLabel");
        local Close = Instance.new("TextButton");
        local ImageLabel = Instance.new("ImageLabel");
        local TextLabel2 = Instance.new("TextLabel");

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
        TextLabel2.TextColor3 = Color3.fromRGB(150.0000062584877, 150.0000062584877, 150.0000062584877)
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

local InventoryPickerGui = nil

local function ShowInventoryPicker(config)
    config = config or {}
    local items = config.Items or {}
    local selectedSet = config.SelectedSet or {}
    local onToggle = config.OnToggle or function(name, nowSelected) end
    local accentColor = config.Color or Color3.fromRGB(100, 200, 255)

    if InventoryPickerGui then
        InventoryPickerGui:Destroy()
        InventoryPickerGui = nil
    end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "InventoryPickerGui"
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.Parent = game:GetService("CoreGui")
    InventoryPickerGui = ScreenGui

    local Overlay = Instance.new("Frame")
    Overlay.Size = UDim2.new(1, 0, 1, 0)
    Overlay.BackgroundTransparency = 1
    Overlay.ZIndex = 100
    Overlay.Parent = ScreenGui

    local Box = Instance.new("Frame")
    Box.AnchorPoint = Vector2.new(0.5, 0.5)
    Box.Position = UDim2.new(0.5, 0, 0.5, 0)
    Box.Size = UDim2.new(0, 260, 0, 320)
    Box.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
    Box.BorderSizePixel = 0
    Box.ZIndex = 101
    Box.Parent = Overlay

    local BoxCorner = Instance.new("UICorner")
    BoxCorner.CornerRadius = UDim.new(0, 8)
    BoxCorner.Parent = Box

    local BoxStroke = Instance.new("UIStroke")
    BoxStroke.Color = accentColor
    BoxStroke.Thickness = 1
    BoxStroke.Transparency = 0.5
    BoxStroke.Parent = Box

    local TitleBar = Instance.new("Frame")
    TitleBar.Size = UDim2.new(1, 0, 0, 32)
    TitleBar.BackgroundTransparency = 1
    TitleBar.ZIndex = 102
    TitleBar.Name = "TitleBar"
    TitleBar.Parent = Box

    local TitleLbl = Instance.new("TextLabel")
    TitleLbl.Font = Enum.Font.GothamBold
    TitleLbl.Text = config.Title or "Select Items"
    TitleLbl.TextColor3 = Color3.fromRGB(230, 230, 230)
    TitleLbl.TextSize = 13
    TitleLbl.TextXAlignment = Enum.TextXAlignment.Left
    TitleLbl.BackgroundTransparency = 1
    TitleLbl.Position = UDim2.new(0, 10, 0, 0)
    TitleLbl.Size = UDim2.new(1, -40, 1, 0)
    TitleLbl.ZIndex = 102
    TitleLbl.Parent = TitleBar

    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.Text = "x"
    CloseBtn.TextColor3 = Color3.fromRGB(255, 107, 107)
    CloseBtn.TextSize = 14
    CloseBtn.AnchorPoint = Vector2.new(1, 0.5)
    CloseBtn.Position = UDim2.new(1, -8, 0.5, 0)
    CloseBtn.BackgroundColor3 = Color3.fromRGB(226, 75, 74)
    CloseBtn.BackgroundTransparency = 0.88
    CloseBtn.Size = UDim2.new(0, 22, 0, 22)
    CloseBtn.ZIndex = 102
    CloseBtn.Parent = TitleBar

    local CloseCorner = Instance.new("UICorner")
    CloseCorner.CornerRadius = UDim.new(0, 4)
    CloseCorner.Parent = CloseBtn

    CloseBtn.Activated:Connect(function()
        ScreenGui:Destroy()
        if InventoryPickerGui == ScreenGui then InventoryPickerGui = nil end
    end)

    local dragging, dragStart, startPos
    TitleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = Box.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    game:GetService("UserInputService").InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            Box.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    local SearchBar = Instance.new("Frame")
    SearchBar.Position = UDim2.new(0, 8, 0, 36)
    SearchBar.Size = UDim2.new(1, -16, 0, 26)
    SearchBar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    SearchBar.BackgroundTransparency = 0.93
    SearchBar.ZIndex = 102
    SearchBar.Parent = Box
    local SearchCorner = Instance.new("UICorner")
    SearchCorner.CornerRadius = UDim.new(0, 4)
    SearchCorner.Parent = SearchBar

    local SearchBox = Instance.new("TextBox")
    SearchBox.Font = Enum.Font.Gotham
    SearchBox.PlaceholderText = "Search..."
    SearchBox.PlaceholderColor3 = Color3.fromRGB(130, 130, 130)
    SearchBox.Text = ""
    SearchBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    SearchBox.TextSize = 12
    SearchBox.TextXAlignment = Enum.TextXAlignment.Left
    SearchBox.ClearTextOnFocus = false
    SearchBox.BackgroundTransparency = 1
    SearchBox.Position = UDim2.new(0, 8, 0, 0)
    SearchBox.Size = UDim2.new(1, -16, 1, 0)
    SearchBox.ZIndex = 102
    SearchBox.Parent = SearchBar

    local ListScroll = Instance.new("ScrollingFrame")
    ListScroll.Position = UDim2.new(0, 8, 0, 68)
    ListScroll.Size = UDim2.new(1, -16, 1, -76)
    ListScroll.BackgroundTransparency = 1
    ListScroll.BorderSizePixel = 0
    ListScroll.ScrollBarThickness = 3
    ListScroll.ScrollBarImageColor3 = accentColor
    ListScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    ListScroll.ZIndex = 102
    ListScroll.Parent = Box

    local ListLayout = Instance.new("UIListLayout")
    ListLayout.Padding = UDim.new(0, 4)
    ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    ListLayout.Parent = ListScroll
    ListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        ListScroll.CanvasSize = UDim2.new(0, 0, 0, ListLayout.AbsoluteContentSize.Y + 8)
    end)

    local rowsByName = {}

    local function buildRow(itemData)
        local name = itemData.Name
        local stock = itemData.Stock or 0
        local isSelected = selectedSet[name] == true

        local Row = Instance.new("Frame")
        Row.BackgroundColor3 = isSelected and accentColor or Color3.fromRGB(255, 255, 255)
        Row.BackgroundTransparency = isSelected and 0.85 or 0.96
        Row.Size = UDim2.new(1, 0, 0, 30)
        Row.ZIndex = 102
        Row.Name = "Row"
        Row.Parent = ListScroll

        local RowCorner = Instance.new("UICorner")
        RowCorner.CornerRadius = UDim.new(0, 4)
        RowCorner.Parent = Row

        local NameLbl = Instance.new("TextLabel")
        NameLbl.Font = Enum.Font.GothamBold
        NameLbl.Text = name
        NameLbl.TextColor3 = isSelected and accentColor or Color3.fromRGB(220, 220, 220)
        NameLbl.TextSize = 12
        NameLbl.TextXAlignment = Enum.TextXAlignment.Left
        NameLbl.BackgroundTransparency = 1
        NameLbl.Position = UDim2.new(0, 8, 0, config.ShowStock == false and 8 or 3)
        NameLbl.Size = UDim2.new(0.6, 0, 0, 12)
        NameLbl.ZIndex = 103
        NameLbl.Parent = Row

        if config.ShowStock ~= false then
            local StockLbl = Instance.new("TextLabel")
            StockLbl.Font = Enum.Font.Gotham
            StockLbl.Text = tostring(stock)
            StockLbl.TextColor3 = Color3.fromRGB(150, 220, 150)
            StockLbl.TextSize = 10
            StockLbl.TextXAlignment = Enum.TextXAlignment.Left
            StockLbl.BackgroundTransparency = 1
            StockLbl.Position = UDim2.new(0, 8, 0, 16)
            StockLbl.Size = UDim2.new(0.6, 0, 0, 10)
            StockLbl.ZIndex = 103
            StockLbl.Parent = Row
        end

        local CheckMark = Instance.new("TextLabel")
        CheckMark.Font = Enum.Font.GothamBold
        CheckMark.Text = isSelected and "✓" or ""
        CheckMark.TextColor3 = accentColor
        CheckMark.TextSize = 14
        CheckMark.AnchorPoint = Vector2.new(1, 0.5)
        CheckMark.Position = UDim2.new(1, -8, 0.5, 0)
        CheckMark.Size = UDim2.new(0, 20, 0, 20)
        CheckMark.BackgroundTransparency = 1
        CheckMark.ZIndex = 103
        CheckMark.Name = "CheckMark"
        CheckMark.Parent = Row

        local Btn = Instance.new("TextButton")
        Btn.Text = ""
        Btn.BackgroundTransparency = 1
        Btn.Size = UDim2.new(1, 0, 1, 0)
        Btn.ZIndex = 104
        Btn.Parent = Row

        Btn.Activated:Connect(function()
            local nowSelected = not selectedSet[name]
            selectedSet[name] = nowSelected or nil
            Row.BackgroundColor3 = nowSelected and accentColor or Color3.fromRGB(255, 255, 255)
            Row.BackgroundTransparency = nowSelected and 0.85 or 0.96
            NameLbl.TextColor3 = nowSelected and accentColor or Color3.fromRGB(220, 220, 220)
            CheckMark.Text = nowSelected and "✓" or ""
            onToggle(name, nowSelected)
        end)

        rowsByName[name] = { row = Row, nameLbl = NameLbl }
        return Row
    end

    for _, itemData in ipairs(items) do
        buildRow(itemData)
    end

    if config.OnRefresh then
        task.spawn(function()
            while ScreenGui.Parent do
                task.wait(1)
                local ok, freshItems = pcall(config.OnRefresh)
                if ok and type(freshItems) == "table" then
                    for _, itemData in ipairs(freshItems) do
                        local r = rowsByName[itemData.Name]
                        if r then
                            local stockLbl = r.row:FindFirstChild("StockLbl") or r.row:FindFirstChildWhichIsA("TextLabel", true)
                            for _, child in ipairs(r.row:GetChildren()) do
                                if child:IsA("TextLabel") and child ~= r.nameLbl and child.Name ~= "CheckMark" then
                                    child.Text = tostring(itemData.Stock or 0)
                                end
                            end
                        end
                    end
                end
            end
        end)
    end

    local searchTicket = 0
    SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
        searchTicket = searchTicket + 1
        local ticket = searchTicket
        task.delay(0.08, function()
            if ticket ~= searchTicket then return end
            local q = string.lower(SearchBox.Text)
            for name, r in pairs(rowsByName) do
                r.row.Visible = (q == "") or string.find(string.lower(name), q, 1, true) ~= nil
            end
        end)
    end)

    Overlay.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            if input.Position.X < Box.AbsolutePosition.X or input.Position.X > Box.AbsolutePosition.X + Box.AbsoluteSize.X
                or input.Position.Y < Box.AbsolutePosition.Y or input.Position.Y > Box.AbsolutePosition.Y + Box.AbsoluteSize.Y then
                ScreenGui:Destroy()
                if InventoryPickerGui == ScreenGui then InventoryPickerGui = nil end
            end
        end
    end)
end

function Chloex:Window(GuiConfig)
    GuiConfig              = GuiConfig or {}
    GuiConfig.Title        = GuiConfig.Title or "HydraHub"
    GuiConfig.Footer       = GuiConfig.Footer or ""
    GuiConfig.Color        = GuiConfig.Color or Color3.fromRGB(255, 0, 255)
    GuiConfig["Tab Width"] = GuiConfig["Tab Width"] or 120
    GuiConfig.Version      = GuiConfig.Version or 1
    if GuiConfig.Search == nil then GuiConfig.Search = true end

    CURRENT_VERSION        = GuiConfig.Version
    LoadConfigFromFile()

    local GuiFunc = {}

    local SearchRegistry = {}
    local TabRegistry = {}

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
        if qi > #q then
            return 200 - (lastIdx - #q) * 2
        end
        return 0
    end

    local function RegisterSearch(entry)
        table.insert(SearchRegistry, entry)
    end

    local function ExtractConfigPayload(payload)
        local data = payload
        if type(payload.Data) == "table" then
            data = payload.Data
        elseif type(payload.Config) == "table" then
            data = payload.Config
        elseif type(payload.Settings) == "table" then
            data = payload.Settings
        end

        if type(data) ~= "table" then return nil end

        local cleaned = {}
        for key, value in pairs(data) do
            if key ~= "_version"
                and key ~= "Game"
                and key ~= "Version"
                and key ~= "PlaceId"
                and key ~= "Hub"
                and key ~= "SavedAt"
                and key ~= "ActiveConfig"
                and key ~= "AutoLoad"
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
                pcall(function()
                    Elements[key]:Set(value, true)
                end)
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
            ActiveConfig = ActiveConfigName or "",
            AutoLoad = GuiFunc:GetAutoLoad(),
            Data = GetConfigSnapshot(),
        })
        if setclipboard then
            setclipboard(payload)
            than("Config copied to clipboard", 4, GuiConfig.Color, "HydraHub", "Export")
        end
        return payload
    end

    function GuiFunc:ImportConfig(str)
        if not str or str == "" then
            than("Paste a config string first", 4, Color3.fromRGB(255, 90, 90), "HydraHub", "Import")
            return false
        end
        local ok, dec = pcall(function() return HttpService:JSONDecode(str) end)
        if not ok or type(dec) ~= "table" then
            than("Invalid config format", 4, Color3.fromRGB(255, 90, 90), "HydraHub", "Import")
            return false
        end
        local data = ExtractConfigPayload(dec)
        if not data then
            than("Config data is empty", 4, Color3.fromRGB(255, 90, 90), "HydraHub", "Import")
            return false
        end

        ApplyConfigData(data)
        QueueSaveConfig(AutoSaveEnabled)
        than("Config imported", 4, GuiConfig.Color, "HydraHub", "Import")
        return true
    end

    local ConfigFolder = "HydraHub/Configs"
    local GameConfigFolder = ConfigFolder .. "/" .. gameName

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
            if n and n ~= "_autoload" then
                table.insert(out, n)
            end
        end
        return out
    end

    function GuiFunc:SaveConfigAs(name)
        if not name or name == "" then
            than("Enter a config name first", 4, Color3.fromRGB(255, 90, 90), "HydraHub", "Config")
            return false
        end
        if not writefile then return false end
        EnsureConfigFolder()
        local path = GameConfigFolder .. "/" .. name .. ".json"
        writefile(path, HttpService:JSONEncode(GetConfigSnapshot()))
        SetActiveConfig(name, path, AutoSaveEnabled or GuiFunc:GetAutoLoad() == name, "saved")
        than("Saved '" .. name .. "'", 4, GuiConfig.Color, "HydraHub", "Config")
        return true
    end

    function GuiFunc:LoadConfigByName(name)
        if not name or name == "" then return false end
        local path = GameConfigFolder .. "/" .. name .. ".json"
        if not (isfile and isfile(path)) then
            than("Config '" .. tostring(name) .. "' not found", 4, Color3.fromRGB(255, 90, 90), "HydraHub", "Config")
            return false
        end
        local ok, dec = pcall(function() return HttpService:JSONDecode(readfile(path)) end)
        if not ok or type(dec) ~= "table" then
            than("Failed to read config", 4, Color3.fromRGB(255, 90, 90), "HydraHub", "Config")
            return false
        end
        local data = ExtractConfigPayload(dec)
        if not data then
            than("Config data is empty", 4, Color3.fromRGB(255, 90, 90), "HydraHub", "Config")
            return false
        end

        ApplyConfigData(data)
        SetActiveConfig(name, path, true, "manual")
        than("Loaded '" .. name .. "'", 4, GuiConfig.Color, "HydraHub", "Config")
        return true
    end

    function GuiFunc:DeleteConfig(name)
        local path = GameConfigFolder .. "/" .. name .. ".json"
        if isfile and isfile(path) and delfile then
            delfile(path)
            if ActiveConfigName == name then
                SetActiveConfig(nil, nil, false, nil)
            end
            if GuiFunc:GetAutoLoad() == name then
                GuiFunc:SetAutoLoad("")
            end
            than("Deleted '" .. name .. "'", 4, Color3.fromRGB(255, 170, 0), "HydraHub", "Config")
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

    local NatUI = Instance.new("ScreenGui");
    local DropShadowHolder = Instance.new("Frame");
    local DropShadow = Instance.new("ImageLabel");
    local Main = Instance.new("Frame");
    local UICorner = Instance.new("UICorner");
    local Top = Instance.new("Frame");
    local TextLabel = Instance.new("TextLabel");
    local UICorner1 = Instance.new("UICorner");
    local TextLabel1 = Instance.new("TextLabel");
    local Close = Instance.new("TextButton");
    local ImageLabel1 = Instance.new("ImageLabel");
    local Min = Instance.new("TextButton");
    local ImageLabel2 = Instance.new("ImageLabel");
    local LayersTab = Instance.new("Frame");
    local UICorner2 = Instance.new("UICorner");
    local DecideFrame = Instance.new("Frame");
    local Layers = Instance.new("Frame");
    local UICorner6 = Instance.new("UICorner");
    local NameTab = Instance.new("TextLabel");
    local LayersReal = Instance.new("Frame");
    local LayersFolder = Instance.new("Folder");
    local LayersPageLayout = Instance.new("UIPageLayout");

    NatUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    NatUI.Name = "NatUI"
    NatUI.ResetOnSpawn = false
    NatUI.Parent = game:GetService("CoreGui")

    DropShadowHolder.BackgroundTransparency = 1
    DropShadowHolder.BorderSizePixel = 0
    DropShadowHolder.AnchorPoint = Vector2.new(0.5, 0.5)
    DropShadowHolder.Position = UDim2.new(0.5, 0, 0.5, 0)
    if isMobile then
        DropShadowHolder.Size = safeSize(470, 270)
    else
        DropShadowHolder.Size = safeSize(640, 400)
    end
    DropShadowHolder.ZIndex = 0
    DropShadowHolder.Name = "DropShadowHolder"
    DropShadowHolder.Parent = NatUI

    DropShadowHolder.Position = UDim2.new(0, (NatUI.AbsoluteSize.X // 2 - DropShadowHolder.Size.X.Offset // 2), 0,
        (NatUI.AbsoluteSize.Y // 2 - DropShadowHolder.Size.Y.Offset // 2))
    DropShadow.Image = "rbxassetid://6015897843"
    DropShadow.ImageColor3 = Color3.fromRGB(15, 15, 15)
    DropShadow.ImageTransparency = 1
    DropShadow.ScaleType = Enum.ScaleType.Slice
    DropShadow.SliceCenter = Rect.new(49, 49, 450, 450)
    DropShadow.AnchorPoint = Vector2.new(0.5, 0.5)
    DropShadow.BackgroundTransparency = 1
    DropShadow.BorderSizePixel = 0
    DropShadow.Position = UDim2.new(0.5, 0, 0.5, 0)
    DropShadow.Size = UDim2.new(1, 47, 1, 47)
    DropShadow.ZIndex = 0
    DropShadow.Name = "DropShadow"
    DropShadow.Parent = DropShadowHolder

    if GuiConfig.Theme then
        Main:Destroy()
        Main = Instance.new("ImageLabel")
        Main.Image = "rbxassetid://" .. GuiConfig.Theme
        Main.ScaleType = Enum.ScaleType.Crop
        Main.BackgroundTransparency = 1
        Main.ImageTransparency = GuiConfig.ThemeTransparency or 0.15
    else
        Main.BackgroundColor3 = Color3.fromRGB(14, 22, 48)
        Main.BackgroundTransparency = GuiConfig.GlassTransparency or 0.08
    end

    Main.AnchorPoint = Vector2.new(0.5, 0.5)
    Main.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Main.BorderSizePixel = 0
    Main.Position = UDim2.new(0.5, 0, 0.5, 0)
    Main.Size = UDim2.new(1, -47, 1, -47)
    Main.Name = "Main"
    Main.Parent = DropShadow

    UICorner.Parent = Main

    if not GuiConfig.Theme then
        local GlassStroke = Instance.new("UIStroke")
        GlassStroke.Color = Color3.fromRGB(90, 140, 255)
        GlassStroke.Thickness = 1
        GlassStroke.Transparency = 0.55
        GlassStroke.Parent = Main
    end

    Top.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    Top.BackgroundTransparency = 0.9990000128746033
    Top.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Top.BorderSizePixel = 0
    Top.Size = UDim2.new(1, 0, 0, 38)
    Top.Name = "Top"
    Top.Parent = Main

    local HeaderLogo = Instance.new("ImageLabel")
    HeaderLogo.BackgroundTransparency = 1
    HeaderLogo.AnchorPoint = Vector2.new(0, 0.5)
    HeaderLogo.Position = UDim2.new(0, 8, 0.5, 0)
    HeaderLogo.Size = UDim2.new(0, 20, 0, 20)
    HeaderLogo.ScaleType = Enum.ScaleType.Fit
    HeaderLogo.Name = "HeaderLogo"
    HeaderLogo.Parent = Top
    do
        local rawLogo = tostring(GuiConfig.Image or "")
        if string.find(rawLogo, "rbxthumb://") or string.find(rawLogo, "rbxassetid://") then
            HeaderLogo.Image = rawLogo
        elseif rawLogo ~= "" then
            HeaderLogo.Image = "rbxassetid://" .. rawLogo
        end
    end

    TextLabel.Font = Enum.Font.GothamBold
    TextLabel.Text = GuiConfig.Title
    TextLabel.TextColor3 = GuiConfig.Color
    TextLabel.TextSize = 14
    TextLabel.TextXAlignment = Enum.TextXAlignment.Left
    TextLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    TextLabel.BackgroundTransparency = 0.9990000128746033
    TextLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
    TextLabel.BorderSizePixel = 0
    TextLabel.Size = UDim2.new(1, -190, 1, 0)
    TextLabel.Position = UDim2.new(0, 34, 0, 0)
    TextLabel.Parent = Top

    UICorner1.Parent = Top

    do
        local Players = game:GetService("Players")
        local LP = Players.LocalPlayer

        local PlayerBadge = Instance.new("Frame")
        PlayerBadge.BackgroundTransparency = 1
        PlayerBadge.AnchorPoint = Vector2.new(1, 0.5)
        PlayerBadge.Position = UDim2.new(1, -70, 0.5, 0)
        PlayerBadge.Size = UDim2.new(0, 100, 0, 24)
        PlayerBadge.Name = "PlayerBadge"
        PlayerBadge.ZIndex = 5
        PlayerBadge.Parent = Top

        local AvatarImg = Instance.new("ImageLabel")
        AvatarImg.BackgroundTransparency = 1
        AvatarImg.AnchorPoint = Vector2.new(1, 0.5)
        AvatarImg.Position = UDim2.new(1, 0, 0.5, 0)
        AvatarImg.Size = UDim2.new(0, 20, 0, 20)
        AvatarImg.ZIndex = 6
        AvatarImg.Name = "AvatarImg"
        AvatarImg.Parent = PlayerBadge
        local avatarCorner = Instance.new("UICorner")
        avatarCorner.CornerRadius = UDim.new(1, 0)
        avatarCorner.Parent = AvatarImg

        local NameLbl = Instance.new("TextLabel")
        NameLbl.Font = Enum.Font.GothamBold
        NameLbl.Text = LP.DisplayName or LP.Name
        NameLbl.TextColor3 = Color3.fromRGB(230, 230, 230)
        NameLbl.TextSize = 11
        NameLbl.TextTruncate = Enum.TextTruncate.AtEnd
        NameLbl.TextXAlignment = Enum.TextXAlignment.Right
        NameLbl.BackgroundTransparency = 1
        NameLbl.AnchorPoint = Vector2.new(1, 0.5)
        NameLbl.Position = UDim2.new(1, -26, 0.5, 0)
        NameLbl.Size = UDim2.new(0, 76, 0, 16)
        NameLbl.ZIndex = 6
        NameLbl.Name = "NameLbl"
        NameLbl.Parent = PlayerBadge

        task.spawn(function()
            local ok, content = pcall(function()
                return Players:GetUserThumbnailAsync(
                    LP.UserId,
                    Enum.ThumbnailType.HeadShot,
                    Enum.ThumbnailSize.Size48x48
                )
            end)
            if ok and content and AvatarImg.Parent then
                AvatarImg.Image = content
            end
        end)
    end

    local discordOffset = 0
    local DiscordButtonRef = nil
    if GuiConfig.Discord and GuiConfig.Discord ~= "" then
        local baseX = TextLabel.TextBounds.X + 18

        local Divider = Instance.new("Frame")
        Divider.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        Divider.BackgroundTransparency = 0.75
        Divider.BorderSizePixel = 0
        Divider.AnchorPoint = Vector2.new(0, 0.5)
        Divider.Position = UDim2.new(0, baseX, 0.5, 0)
        Divider.Size = UDim2.new(0, 1, 0, 16)
        Divider.Name = "DiscordDivider"
        Divider.Parent = Top

        local DividerCorner = Instance.new("UICorner")
        DividerCorner.CornerRadius = UDim.new(1, 0)
        DividerCorner.Parent = Divider

        local DiscordImg = Instance.new("ImageLabel")
        DiscordImg.Image = Icons.discord
        DiscordImg.ImageColor3 = Color3.fromRGB(88, 101, 242)
        DiscordImg.BackgroundTransparency = 1
        DiscordImg.ScaleType = Enum.ScaleType.Fit
        DiscordImg.AnchorPoint = Vector2.new(0, 0.5)
        DiscordImg.Position = UDim2.new(0, baseX + 10, 0.5, 0)
        DiscordImg.Size = UDim2.new(0, 16, 0, 16)
        DiscordImg.Name = "DiscordImg"
        DiscordImg.Parent = Top

        local DiscordBtn = Instance.new("TextButton")
        DiscordBtn.Text = ""
        DiscordBtn.AutoButtonColor = false
        DiscordBtn.BackgroundTransparency = 1
        DiscordBtn.BorderSizePixel = 0
        DiscordBtn.AnchorPoint = Vector2.new(0, 0.5)
        DiscordBtn.Position = UDim2.new(0, baseX + 8, 0.5, 0)
        DiscordBtn.Size = UDim2.new(0, 0, 1, 0)
        DiscordBtn.Name = "DiscordBtn"
        DiscordBtn.Parent = Top

        DiscordBtn.MouseEnter:Connect(function()
            TweenService:Create(DiscordImg, TweenInfo.new(0.2), { ImageColor3 = Color3.fromRGB(120, 132, 255) }):Play()
            TweenService:Create(Divider, TweenInfo.new(0.2), { BackgroundTransparency = 0.5 }):Play()
        end)
        DiscordBtn.MouseLeave:Connect(function()
            TweenService:Create(DiscordImg, TweenInfo.new(0.2), { ImageColor3 = Color3.fromRGB(88, 101, 242) }):Play()
            TweenService:Create(Divider, TweenInfo.new(0.2), { BackgroundTransparency = 0.75 }):Play()
        end)
        DiscordBtn.Activated:Connect(function()
            if setclipboard then
                setclipboard(GuiConfig.Discord)
                than("Discord invite copied", 4, GuiConfig.Color, "HydraHub", "Community")
            end
        end)

        discordOffset = 36
        DiscordButtonRef = DiscordBtn
    end

    TextLabel1.Font = Enum.Font.GothamBold
    TextLabel1.Text = GuiConfig.Footer
    TextLabel1.TextColor3 = Color3.fromRGB(255, 255, 255)
    TextLabel1.TextSize = 12
    TextLabel1.TextTransparency = 0
    TextLabel1.TextXAlignment = Enum.TextXAlignment.Left
    TextLabel1.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    TextLabel1.BackgroundTransparency = 0.9990000128746033
    TextLabel1.BorderColor3 = Color3.fromRGB(0, 0, 0)
    TextLabel1.BorderSizePixel = 0
    TextLabel1.Size = UDim2.new(1, -(TextLabel.TextBounds.X + 104 + discordOffset), 1, 0)
    TextLabel1.Position = UDim2.new(0, TextLabel.TextBounds.X + 15 + discordOffset, 0, 0)
    TextLabel1.Parent = Top

    if DiscordButtonRef then
        DiscordButtonRef.Size = UDim2.new(0, discordOffset + TextLabel1.TextBounds.X + 6, 1, 0)
    end

    Close.Font = Enum.Font.SourceSans
    Close.Text = ""
    Close.TextColor3 = Color3.fromRGB(0, 0, 0)
    Close.TextSize = 14
    Close.AnchorPoint = Vector2.new(1, 0.5)
    Close.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Close.BackgroundTransparency = 0.9990000128746033
    Close.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Close.BorderSizePixel = 0
    Close.Position = UDim2.new(1, -8, 0.5, 0)
    Close.Size = UDim2.new(0, 25, 0, 25)
    Close.Name = "Close"
    Close.Parent = Top

    ImageLabel1.Image = "rbxassetid://9886659671"
    ImageLabel1.AnchorPoint = Vector2.new(0.5, 0.5)
    ImageLabel1.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    ImageLabel1.BackgroundTransparency = 0.9990000128746033
    ImageLabel1.BorderColor3 = Color3.fromRGB(0, 0, 0)
    ImageLabel1.BorderSizePixel = 0
    ImageLabel1.Position = UDim2.new(0.49, 0, 0.5, 0)
    ImageLabel1.Size = UDim2.new(1, -8, 1, -8)
    ImageLabel1.Parent = Close

    Min.Font = Enum.Font.SourceSans
    Min.Text = ""
    Min.TextColor3 = Color3.fromRGB(0, 0, 0)
    Min.TextSize = 14
    Min.AnchorPoint = Vector2.new(1, 0.5)
    Min.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Min.BackgroundTransparency = 0.9990000128746033
    Min.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Min.BorderSizePixel = 0
    Min.Position = UDim2.new(1, -38, 0.5, 0)
    Min.Size = UDim2.new(0, 25, 0, 25)
    Min.Name = "Min"
    Min.Parent = Top

    ImageLabel2.Image = "rbxassetid://9886659276"
    ImageLabel2.AnchorPoint = Vector2.new(0.5, 0.5)
    ImageLabel2.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    ImageLabel2.BackgroundTransparency = 0.9990000128746033
    ImageLabel2.ImageTransparency = 0.2
    ImageLabel2.BorderColor3 = Color3.fromRGB(0, 0, 0)
    ImageLabel2.BorderSizePixel = 0
    ImageLabel2.Position = UDim2.new(0.5, 0, 0.5, 0)
    ImageLabel2.Size = UDim2.new(1, -9, 1, -9)
    ImageLabel2.Parent = Min

    LayersTab.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    LayersTab.BackgroundTransparency = 0.9990000128746033
    LayersTab.BorderColor3 = Color3.fromRGB(0, 0, 0)
    LayersTab.BorderSizePixel = 0
    LayersTab.Position = UDim2.new(0, 9, 0, 50)
    LayersTab.Size = UDim2.new(0, GuiConfig["Tab Width"], 1, -59)
    LayersTab.Name = "LayersTab"
    LayersTab.Parent = Main

    UICorner2.CornerRadius = UDim.new(0, 2)
    UICorner2.Parent = LayersTab

    DecideFrame.AnchorPoint = Vector2.new(0.5, 0)
    DecideFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    DecideFrame.BackgroundTransparency = 0.85
    DecideFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
    DecideFrame.BorderSizePixel = 0
    DecideFrame.Position = UDim2.new(0.5, 0, 0, 38)
    DecideFrame.Size = UDim2.new(1, 0, 0, 1)
    DecideFrame.Name = "DecideFrame"
    DecideFrame.Parent = Main

    Layers.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Layers.BackgroundTransparency = 0.9990000128746033
    Layers.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Layers.BorderSizePixel = 0
    Layers.Position = UDim2.new(0, GuiConfig["Tab Width"] + 18, 0, 50)
    Layers.Size = UDim2.new(1, -(GuiConfig["Tab Width"] + 9 + 18), 1, -59)
    Layers.Name = "Layers"
    Layers.Parent = Main

    UICorner6.CornerRadius = UDim.new(0, 2)
    UICorner6.Parent = Layers

    NameTab.Font = Enum.Font.GothamBold
    NameTab.Text = ""
    NameTab.TextColor3 = Color3.fromRGB(255, 255, 255)
    NameTab.TextSize = 24
    NameTab.TextWrapped = true
    NameTab.TextXAlignment = Enum.TextXAlignment.Left
    NameTab.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    NameTab.BackgroundTransparency = 0.9990000128746033
    NameTab.BorderColor3 = Color3.fromRGB(0, 0, 0)
    NameTab.BorderSizePixel = 0
    NameTab.Size = UDim2.new(1, 0, 0, 30)
    NameTab.Name = "NameTab"
    NameTab.Parent = Layers

    LayersReal.AnchorPoint = Vector2.new(0, 1)
    LayersReal.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    LayersReal.BackgroundTransparency = 0.9990000128746033
    LayersReal.BorderColor3 = Color3.fromRGB(0, 0, 0)
    LayersReal.BorderSizePixel = 0
    LayersReal.ClipsDescendants = true
    LayersReal.Position = UDim2.new(0, 0, 1, 0)
    LayersReal.Size = UDim2.new(1, 0, 1, -33)
    LayersReal.Name = "LayersReal"
    LayersReal.Parent = Layers

    LayersFolder.Name = "LayersFolder"
    LayersFolder.Parent = LayersReal

    LayersPageLayout.SortOrder = Enum.SortOrder.LayoutOrder
    LayersPageLayout.Name = "LayersPageLayout"
    LayersPageLayout.Parent = LayersFolder
    LayersPageLayout.TweenTime = 0.5
    LayersPageLayout.EasingDirection = Enum.EasingDirection.InOut
    LayersPageLayout.EasingStyle = Enum.EasingStyle.Quad

    local ScrollTab = Instance.new("ScrollingFrame");
    local UIListLayout = Instance.new("UIListLayout");

    ScrollTab.AutomaticCanvasSize = Enum.AutomaticSize.Y
    ScrollTab.ScrollBarImageColor3 = Color3.fromRGB(0, 0, 0)
    ScrollTab.ScrollBarThickness = 0
    ScrollTab.Active = true
    ScrollTab.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    ScrollTab.BackgroundTransparency = 0.9990000128746033
    ScrollTab.BorderColor3 = Color3.fromRGB(0, 0, 0)
    ScrollTab.BorderSizePixel = 0
    if GuiConfig.Search then
        ScrollTab.Position = UDim2.new(0, 0, 0, 34)
        ScrollTab.Size = UDim2.new(1, 0, 1, -34)
    else
        ScrollTab.Size = UDim2.new(1, 0, 1, 0)
    end
    ScrollTab.Name = "ScrollTab"
    ScrollTab.Parent = LayersTab

    UIListLayout.Padding = UDim.new(0, 3)
    UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    UIListLayout.Parent = ScrollTab

    local SearchResults, SearchResultsLayout, SearchBox
    if GuiConfig.Search then
        local SearchBar = Instance.new("Frame")
        SearchBar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        SearchBar.BackgroundTransparency = 0.93
        SearchBar.BorderSizePixel = 0
        SearchBar.Position = UDim2.new(0, 0, 0, 0)
        SearchBar.Size = UDim2.new(1, 0, 0, 28)
        SearchBar.Name = "SearchBar"
        SearchBar.Parent = LayersTab

        local SearchCorner = Instance.new("UICorner")
        SearchCorner.CornerRadius = UDim.new(0, 4)
        SearchCorner.Parent = SearchBar

        local SearchIcon = Instance.new("ImageLabel")
        SearchIcon.Image = Icons.scan
        SearchIcon.ImageColor3 = Color3.fromRGB(200, 200, 200)
        SearchIcon.BackgroundTransparency = 1
        SearchIcon.ScaleType = Enum.ScaleType.Fit
        SearchIcon.Position = UDim2.new(0, 7, 0.5, 0)
        SearchIcon.AnchorPoint = Vector2.new(0, 0.5)
        SearchIcon.Size = UDim2.new(0, 14, 0, 14)
        SearchIcon.Name = "SearchIcon"
        SearchIcon.Parent = SearchBar

        SearchBox = Instance.new("TextBox")
        SearchBox.Font = Enum.Font.GothamBold
        SearchBox.PlaceholderText = "Search..."
        SearchBox.PlaceholderColor3 = Color3.fromRGB(130, 130, 130)
        SearchBox.Text = ""
        SearchBox.TextColor3 = Color3.fromRGB(255, 255, 255)
        SearchBox.TextSize = 12
        SearchBox.TextXAlignment = Enum.TextXAlignment.Left
        SearchBox.ClearTextOnFocus = false
        SearchBox.BackgroundTransparency = 1
        SearchBox.AnchorPoint = Vector2.new(0, 0.5)
        SearchBox.Position = UDim2.new(0, 28, 0.5, 0)
        SearchBox.Size = UDim2.new(1, -34, 1, -6)
        SearchBox.Name = "SearchBox"
        SearchBox.Parent = SearchBar

        SearchResults = Instance.new("ScrollingFrame")
        SearchResults.Active = true
        SearchResults.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
        SearchResults.BackgroundTransparency = 0.05
        SearchResults.BorderSizePixel = 0
        SearchResults.ScrollBarThickness = 2
        SearchResults.ScrollBarImageColor3 = GuiConfig.Color
        SearchResults.CanvasSize = UDim2.new(0, 0, 0, 0)
        SearchResults.Position = UDim2.new(0, 0, 0, 34)
        SearchResults.Size = UDim2.new(1, 0, 1, -34)
        SearchResults.Visible = false
        SearchResults.ZIndex = 20
        SearchResults.Name = "SearchResults"
        SearchResults.Parent = LayersTab

        local SearchResultsCorner = Instance.new("UICorner")
        SearchResultsCorner.CornerRadius = UDim.new(0, 4)
        SearchResultsCorner.Parent = SearchResults

        SearchResultsLayout = Instance.new("UIListLayout")
        SearchResultsLayout.Padding = UDim.new(0, 4)
        SearchResultsLayout.SortOrder = Enum.SortOrder.LayoutOrder
        SearchResultsLayout.Parent = SearchResults

        local SearchPad = Instance.new("UIPadding")
        SearchPad.PaddingTop = UDim.new(0, 4)
        SearchPad.PaddingBottom = UDim.new(0, 4)
        SearchPad.PaddingLeft = UDim.new(0, 4)
        SearchPad.PaddingRight = UDim.new(0, 4)
        SearchPad.Parent = SearchResults

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
                ScrollTab.Visible = true
                return
            end
            ScrollTab.Visible = false
            SearchResults.Visible = true

            local scored = {}
            for _, entry in ipairs(SearchRegistry) do
                local score = SmartMatch(q, entry.label)
                if score > 0 then
                    table.insert(scored, { entry = entry, score = score })
                end
            end
            table.sort(scored, function(a, b) return a.score > b.score end)

            local found = 0
            for _, s in ipairs(scored) do
                local entry = s.entry
                local Row = Instance.new("Frame")
                Row.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                Row.BackgroundTransparency = 0.93
                Row.BorderSizePixel = 0
                Row.Size = UDim2.new(1, 0, 0, 40)
                Row.LayoutOrder = found
                Row.ZIndex = 21
                Row.Name = "Result"
                Row.Parent = SearchResults

                local RowCorner = Instance.new("UICorner")
                RowCorner.CornerRadius = UDim.new(0, 4)
                RowCorner.Parent = Row

                local RowLabel = Instance.new("TextLabel")
                RowLabel.Font = Enum.Font.GothamBold
                RowLabel.Text = entry.label
                RowLabel.TextColor3 = Color3.fromRGB(235, 235, 235)
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
                Empty.TextColor3 = Color3.fromRGB(150, 150, 150)
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
                if ticket == searchTicket then
                    RunSearch()
                end
            end)
        end)
        GuiFunc.FocusSearch = function()
            SearchBox:CaptureFocus()
        end
    end

    function GuiFunc:DestroyGui()
        if CoreGui:FindFirstChild("NatUI") then
            NatUI:Destroy()
        end
    end

    Min.Activated:Connect(function()
        CircleClick(Min, Mouse.X, Mouse.Y)
        DropShadowHolder.Visible = false
    end)
    Close.Activated:Connect(function()
        CircleClick(Close, Mouse.X, Mouse.Y)

        local Overlay = Instance.new("Frame")
        Overlay.Size = UDim2.new(1, 0, 1, 0)
        Overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        Overlay.BackgroundTransparency = 0.3
        Overlay.ZIndex = 50
        Overlay.Parent = DropShadowHolder

        local Dialog = Instance.new("ImageLabel")
        Dialog.Size = UDim2.new(0, 300, 0, 150)
        Dialog.Position = UDim2.new(0.5, -150, 0.5, -75)
        Dialog.Image = "rbxassetid://9542022979"
        Dialog.ImageTransparency = 0
        Dialog.BorderSizePixel = 0
        Dialog.ZIndex = 51
        Dialog.Parent = Overlay
        local UICorner = Instance.new("UICorner", Dialog)
        UICorner.CornerRadius = UDim.new(0, 8)

        local DialogGlow = Instance.new("Frame")
        DialogGlow.Size = UDim2.new(0, 310, 0, 160)
        DialogGlow.Position = UDim2.new(0.5, -155, 0.5, -80)
        DialogGlow.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        DialogGlow.BackgroundTransparency = 0.75
        DialogGlow.BorderSizePixel = 0
        DialogGlow.ZIndex = 50
        DialogGlow.Parent = Overlay

        local GlowCorner = Instance.new("UICorner", DialogGlow)
        GlowCorner.CornerRadius = UDim.new(0, 10)

        local Gradient = Instance.new("UIGradient")
        Gradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0.0, Color3.fromRGB(0, 191, 255)),
            ColorSequenceKeypoint.new(0.25, Color3.fromRGB(255, 255, 255)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 140, 255)),
            ColorSequenceKeypoint.new(0.75, Color3.fromRGB(255, 255, 255)),
            ColorSequenceKeypoint.new(1.0, Color3.fromRGB(0, 191, 255))
        })
        Gradient.Rotation = 90
        Gradient.Parent = DialogGlow

        local Title = Instance.new("TextLabel")
        Title.Size = UDim2.new(1, 0, 0, 40)
        Title.Position = UDim2.new(0, 0, 0, 4)
        Title.BackgroundTransparency = 1
        Title.Font = Enum.Font.GothamBold
        Title.Text = "HydraHub Window"
        Title.TextSize = 22
        Title.TextColor3 = Color3.fromRGB(255, 255, 255)
        Title.ZIndex = 52
        Title.Parent = Dialog

        local Message = Instance.new("TextLabel")
        Message.Size = UDim2.new(1, -20, 0, 60)
        Message.Position = UDim2.new(0, 10, 0, 30)
        Message.BackgroundTransparency = 1
        Message.Font = Enum.Font.Gotham
        Message.Text = "Do you want to close this window?\nYou will not be able to open it again"
        Message.TextSize = 14
        Message.TextColor3 = Color3.fromRGB(200, 200, 200)
        Message.TextWrapped = true
        Message.ZIndex = 52
        Message.Parent = Dialog

        local Yes = Instance.new("TextButton")
        Yes.Size = UDim2.new(0.45, -10, 0, 35)
        Yes.Position = UDim2.new(0.05, 0, 1, -55)
        Yes.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        Yes.BackgroundTransparency = 0.935
        Yes.Text = "Yes"
        Yes.Font = Enum.Font.GothamBold
        Yes.TextSize = 15
        Yes.TextColor3 = Color3.fromRGB(255, 255, 255)
        Yes.TextTransparency = 0.3
        Yes.ZIndex = 52
        Yes.Name = "Yes"
        Yes.Parent = Dialog
        Instance.new("UICorner", Yes).CornerRadius = UDim.new(0, 6)

        local Cancel = Instance.new("TextButton")
        Cancel.Size = UDim2.new(0.45, -10, 0, 35)
        Cancel.Position = UDim2.new(0.5, 10, 1, -55)
        Cancel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        Cancel.BackgroundTransparency = 0.935
        Cancel.Text = "Cancel"
        Cancel.Font = Enum.Font.GothamBold
        Cancel.TextSize = 15
        Cancel.TextColor3 = Color3.fromRGB(255, 255, 255)
        Cancel.TextTransparency = 0.3
        Cancel.ZIndex = 52
        Cancel.Name = "Cancel"
        Cancel.Parent = Dialog
        Instance.new("UICorner", Cancel).CornerRadius = UDim.new(0, 6)

        Yes.MouseButton1Click:Connect(function()
            if NatUI then NatUI:Destroy() end
            if game.CoreGui:FindFirstChild("ToggleUIButton") then
                game.CoreGui.ToggleUIButton:Destroy()
            end
        end)

        Cancel.MouseButton1Click:Connect(function()
            Overlay:Destroy()
        end)
    end)

    function GuiFunc:ToggleUI()
        local ScreenGui = Instance.new("ScreenGui")
        ScreenGui.Parent = game:GetService("CoreGui")
        ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        ScreenGui.Name = "ToggleUIButton"

        local FloatFrame = Instance.new("Frame")
        FloatFrame.Parent = ScreenGui
        FloatFrame.Size = UDim2.new(0, 60, 0, 74)
        FloatFrame.Position = UDim2.new(0, 20, 0, 100)
        FloatFrame.BackgroundTransparency = 1
        FloatFrame.Name = "FloatFrame"

        local MainButton = Instance.new("ImageLabel")
        MainButton.Parent = FloatFrame
        MainButton.Size = UDim2.new(0, 50, 0, 50)
        MainButton.Position = UDim2.new(0.5, 0, 0, 0)
        MainButton.AnchorPoint = Vector2.new(0.5, 0)
        MainButton.BackgroundColor3 = Color3.fromRGB(18, 18, 20)
        MainButton.BackgroundTransparency = 0.15
        local rawImage = tostring(GuiConfig.Image or "")
        if string.find(rawImage, "rbxthumb://") or string.find(rawImage, "rbxassetid://") then
            MainButton.Image = rawImage
        else
            MainButton.Image = "rbxassetid://" .. rawImage
        end
        MainButton.ScaleType = Enum.ScaleType.Fit

        local UICorner = Instance.new("UICorner")
        UICorner.CornerRadius = UDim.new(0, 10)
        UICorner.Parent = MainButton

        local NameLabel = Instance.new("TextLabel")
        NameLabel.Parent = FloatFrame
        NameLabel.AnchorPoint = Vector2.new(0.5, 0)
        NameLabel.Position = UDim2.new(0.5, 0, 0, 54)
        NameLabel.Size = UDim2.new(1, 10, 0, 16)
        NameLabel.BackgroundTransparency = 1
        NameLabel.Font = Enum.Font.GothamBold
        NameLabel.Text = ""
        NameLabel.TextSize = 12
        NameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        NameLabel.TextStrokeTransparency = 0.7
        NameLabel.Name = "NameLabel"

        local Button = Instance.new("TextButton")
        Button.Parent = MainButton
        Button.Size = UDim2.new(1, 0, 1, 0)
        Button.BackgroundTransparency = 1
        Button.Text = ""

        Button.MouseButton1Click:Connect(function()
            if DropShadowHolder then
                DropShadowHolder.Visible = not DropShadowHolder.Visible
            end
        end)

        local dragging = false
        local dragStart, startPos

        local function update(input)
            local delta = input.Position - dragStart
            FloatFrame.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end

        Button.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                dragStart = input.Position
                startPos = FloatFrame.Position
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragging = false
                    end
                end)
            end
        end)

        game:GetService("UserInputService").InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                update(input)
            end
        end)
    end

    GuiFunc:ToggleUI()

    DropShadowHolder.Size = UDim2.new(0, 115 + TextLabel.TextBounds.X + 1 + TextLabel1.TextBounds.X, 0, 350)
    MakeDraggable(Top, DropShadowHolder)

    local MoreBlur = Instance.new("Frame");
    local DropShadowHolder1 = Instance.new("Frame");
    local DropShadow1 = Instance.new("ImageLabel");
    local UICorner28 = Instance.new("UICorner");
    local ConnectButton = Instance.new("TextButton");

    MoreBlur.AnchorPoint = Vector2.new(1, 1)
    MoreBlur.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    MoreBlur.BackgroundTransparency = 0.999
    MoreBlur.BorderColor3 = Color3.fromRGB(0, 0, 0)
    MoreBlur.BorderSizePixel = 0
    MoreBlur.ClipsDescendants = true
    MoreBlur.Position = UDim2.new(1, 8, 1, 8)
    MoreBlur.Size = UDim2.new(1, 154, 1, 54)
    MoreBlur.Visible = false
    MoreBlur.Name = "MoreBlur"
    MoreBlur.Parent = Layers

    DropShadowHolder1.BackgroundTransparency = 1
    DropShadowHolder1.BorderSizePixel = 0
    DropShadowHolder1.Size = UDim2.new(1, 0, 1, 0)
    DropShadowHolder1.ZIndex = 0
    DropShadowHolder1.Name = "DropShadowHolder"
    DropShadowHolder1.Parent = MoreBlur

    DropShadow1.Image = "rbxassetid://6015897843"
    DropShadow1.ImageColor3 = Color3.fromRGB(0, 0, 0)
    DropShadow1.ImageTransparency = 1
    DropShadow1.ScaleType = Enum.ScaleType.Slice
    DropShadow1.SliceCenter = Rect.new(49, 49, 450, 450)
    DropShadow1.AnchorPoint = Vector2.new(0.5, 0.5)
    DropShadow1.BackgroundTransparency = 1
    DropShadow1.BorderSizePixel = 0
    DropShadow1.Position = UDim2.new(0.5, 0, 0.5, 0)
    DropShadow1.Size = UDim2.new(1, 35, 1, 35)
    DropShadow1.ZIndex = 0
    DropShadow1.Name = "DropShadow"
    DropShadow1.Parent = DropShadowHolder1

    UICorner28.Parent = MoreBlur

    ConnectButton.Font = Enum.Font.SourceSans
    ConnectButton.Text = ""
    ConnectButton.TextColor3 = Color3.fromRGB(0, 0, 0)
    ConnectButton.TextSize = 14
    ConnectButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    ConnectButton.BackgroundTransparency = 0.999
    ConnectButton.BorderColor3 = Color3.fromRGB(0, 0, 0)
    ConnectButton.BorderSizePixel = 0
    ConnectButton.Size = UDim2.new(1, 0, 1, 0)
    ConnectButton.Name = "ConnectButton"
    ConnectButton.Parent = MoreBlur

    local DropdownSelect = Instance.new("Frame");
    local UICorner36 = Instance.new("UICorner");
    local UIStroke14 = Instance.new("UIStroke");
    local DropdownSelectReal = Instance.new("Frame");
    local DropdownFolder = Instance.new("Folder");
    local DropPageLayout = Instance.new("UIPageLayout");

    DropdownSelect.AnchorPoint = Vector2.new(1, 0.5)
    DropdownSelect.BackgroundColor3 = Color3.fromRGB(30.00000011175871, 30.00000011175871, 30.00000011175871)
    DropdownSelect.BorderColor3 = Color3.fromRGB(0, 0, 0)
    DropdownSelect.BorderSizePixel = 0
    DropdownSelect.LayoutOrder = 1
    DropdownSelect.Position = UDim2.new(1, 172, 0.5, 0)
    DropdownSelect.Size = UDim2.new(0, 160, 1, -16)
    DropdownSelect.Name = "DropdownSelect"
    DropdownSelect.ClipsDescendants = true
    DropdownSelect.Parent = MoreBlur

    ConnectButton.Activated:Connect(function()
        if MoreBlur.Visible then
            TweenService:Create(MoreBlur, TweenInfo.new(0.3), { BackgroundTransparency = 0.999 }):Play()
            TweenService:Create(DropdownSelect, TweenInfo.new(0.3), { Position = UDim2.new(1, 172, 0.5, 0) }):Play()
            task.wait(0.3)
            MoreBlur.Visible = false
        end
    end)
    UICorner36.CornerRadius = UDim.new(0, 3)
    UICorner36.Parent = DropdownSelect

    UIStroke14.Color = Color3.fromRGB(12, 159, 255)
    UIStroke14.Thickness = 2.5
    UIStroke14.Transparency = 0.8
    UIStroke14.Parent = DropdownSelect

    DropdownSelectReal.AnchorPoint = Vector2.new(0.5, 0.5)
    DropdownSelectReal.BackgroundColor3 = Color3.fromRGB(0, 27, 98)
    DropdownSelectReal.BackgroundTransparency = 0.7
    DropdownSelectReal.BorderColor3 = Color3.fromRGB(0, 0, 0)
    DropdownSelectReal.BorderSizePixel = 0
    DropdownSelectReal.LayoutOrder = 1
    DropdownSelectReal.Position = UDim2.new(0.5, 0, 0.5, 0)
    DropdownSelectReal.Size = UDim2.new(1, 1, 1, 1)
    DropdownSelectReal.Name = "DropdownSelectReal"
    DropdownSelectReal.Parent = DropdownSelect

    DropdownFolder.Name = "DropdownFolder"
    DropdownFolder.Parent = DropdownSelectReal

    DropPageLayout.EasingDirection = Enum.EasingDirection.InOut
    DropPageLayout.EasingStyle = Enum.EasingStyle.Quad
    DropPageLayout.TweenTime = 0.009999999776482582
    DropPageLayout.SortOrder = Enum.SortOrder.LayoutOrder
    DropPageLayout.FillDirection = Enum.FillDirection.Vertical
    DropPageLayout.Archivable = false
    DropPageLayout.Name = "DropPageLayout"
    DropPageLayout.Parent = DropdownFolder
    local Tabs = {}
    local CountTab = 0
    local CountDropdown = 0
    function Tabs:AddTab(TabConfig)
        local TabConfig = TabConfig or {}
        TabConfig.Name = TabConfig.Name or "Tab"
        TabConfig.Icon = TabConfig.Icon or ""

        local ScrolLayers = Instance.new("ScrollingFrame");
        local UIListLayout1 = Instance.new("UIListLayout");

        ScrolLayers.AutomaticCanvasSize = Enum.AutomaticSize.Y
        ScrolLayers.ScrollBarImageColor3 = Color3.fromRGB(80.00000283122063, 80.00000283122063, 80.00000283122063)
        ScrolLayers.ScrollBarThickness = 0
        ScrolLayers.Active = true
        ScrolLayers.LayoutOrder = CountTab
        ScrolLayers.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        ScrolLayers.BackgroundTransparency = 0.9990000128746033
        ScrolLayers.BorderColor3 = Color3.fromRGB(0, 0, 0)
        ScrolLayers.BorderSizePixel = 0
        ScrolLayers.Size = UDim2.new(1, 0, 1, 0)
        ScrolLayers.Name = "ScrolLayers"
        ScrolLayers.Parent = LayersFolder

        UIListLayout1.Padding = UDim.new(0, 3)
        UIListLayout1.SortOrder = Enum.SortOrder.LayoutOrder
        UIListLayout1.Parent = ScrolLayers

        local Tab = Instance.new("Frame");
        local UICorner3 = Instance.new("UICorner");
        local TabButton = Instance.new("TextButton");
        local TabName = Instance.new("TextLabel")
        local FeatureImg = Instance.new("ImageLabel");
        local UIStroke2 = Instance.new("UIStroke");
        local UICorner4 = Instance.new("UICorner");

        Tab.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        if CountTab == 0 then
            Tab.BackgroundTransparency = 0.9200000166893005
        else
            Tab.BackgroundTransparency = 0.9990000128746033
        end
        Tab.BorderColor3 = Color3.fromRGB(0, 0, 0)
        Tab.BorderSizePixel = 0
        Tab.LayoutOrder = CountTab
        Tab.Size = UDim2.new(1, 0, 0, 30)
        Tab.Name = "Tab"
        Tab.Parent = ScrollTab

        UICorner3.CornerRadius = UDim.new(0, 4)
        UICorner3.Parent = Tab

        TabButton.Font = Enum.Font.GothamBold
        TabButton.Text = ""
        TabButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        TabButton.TextSize = 13
        TabButton.TextXAlignment = Enum.TextXAlignment.Left
        TabButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        TabButton.BackgroundTransparency = 0.9990000128746033
        TabButton.BorderColor3 = Color3.fromRGB(0, 0, 0)
        TabButton.BorderSizePixel = 0
        TabButton.Size = UDim2.new(1, 0, 1, 0)
        TabButton.Name = "TabButton"
        TabButton.Parent = Tab

        TabName.Font = Enum.Font.GothamBold
        TabName.Text = "[ " .. tostring(TabConfig.Name) .. " ]"
        TabName.TextColor3 = Color3.fromRGB(255, 255, 255)
        TabName.TextSize = 13
        TabName.TextXAlignment = Enum.TextXAlignment.Left
        TabName.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        TabName.BackgroundTransparency = 0.9990000128746033
        TabName.BorderColor3 = Color3.fromRGB(0, 0, 0)
        TabName.BorderSizePixel = 0
        TabName.Size = UDim2.new(1, 0, 1, 0)
        TabName.Position = UDim2.new(0, 30, 0, 0)
        TabName.Name = "TabName"
        TabName.Parent = Tab

        FeatureImg.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        FeatureImg.BackgroundTransparency = 0.9990000128746033
        FeatureImg.BorderColor3 = Color3.fromRGB(0, 0, 0)
        FeatureImg.BorderSizePixel = 0
        FeatureImg.Position = UDim2.new(0, 9, 0, 7)
        FeatureImg.Size = UDim2.new(0, 16, 0, 16)
        FeatureImg.Name = "FeatureImg"
        FeatureImg.Parent = Tab
        if CountTab == 0 then
            LayersPageLayout:JumpToIndex(0)
            NameTab.Text = TabConfig.Name
            local ChooseFrame = Instance.new("Frame");
            ChooseFrame.BackgroundColor3 = GuiConfig.Color
            ChooseFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
            ChooseFrame.BorderSizePixel = 0
            ChooseFrame.Position = UDim2.new(0, 2, 0, 9)
            ChooseFrame.Size = UDim2.new(0, 1, 0, 12)
            ChooseFrame.Name = "ChooseFrame"
            ChooseFrame.Parent = Tab

            UIStroke2.Color = GuiConfig.Color
            UIStroke2.Thickness = 1.600000023841858
            UIStroke2.Parent = ChooseFrame

            UICorner4.Parent = ChooseFrame
        end

        if TabConfig.Icon ~= "" then
            if Icons[TabConfig.Icon] then
                FeatureImg.Image = Icons[TabConfig.Icon]
            else
                FeatureImg.Image = TabConfig.Icon
            end
        end

        local function switchToTab(force)
            local FrameChoose
            for a, s in ScrollTab:GetChildren() do
                for i, v in s:GetChildren() do
                    if v.Name == "ChooseFrame" then
                        FrameChoose = v
                        break
                    end
                end
            end
            if FrameChoose ~= nil and (force or Tab.LayoutOrder ~= LayersPageLayout.CurrentPage.LayoutOrder) then
                for _, TabFrame in ScrollTab:GetChildren() do
                    if TabFrame.Name == "Tab" then
                        TweenService:Create(
                            TabFrame,
                            TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.InOut),
                            { BackgroundTransparency = 0.9990000128746033 }
                        ):Play()
                    end
                end
                TweenService:Create(
                    Tab,
                    TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.InOut),
                    { BackgroundTransparency = 0.9200000166893005 }
                ):Play()
                TweenService:Create(
                    FrameChoose,
                    TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
                    { Position = UDim2.new(0, 2, 0, 9 + (33 * Tab.LayoutOrder)) }
                ):Play()
                LayersPageLayout:JumpToIndex(Tab.LayoutOrder)
                task.wait(0.05)
                NameTab.Text = TabConfig.Name
                TweenService:Create(
                    FrameChoose,
                    TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
                    { Size = UDim2.new(0, 1, 0, 20) }
                ):Play()
                task.wait(0.2)
                TweenService:Create(
                    FrameChoose,
                    TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
                    { Size = UDim2.new(0, 1, 0, 12) }
                ):Play()
            end
        end

        TabButton.Activated:Connect(function()
            CircleClick(TabButton, Mouse.X, Mouse.Y)
            switchToTab(false)
        end)

        local function SearchSwitch()
            if SearchResults then
                SearchResults.Visible = false
                ScrollTab.Visible = true
            end
            switchToTab(true)
        end

        TabRegistry[TabConfig.Name] = SearchSwitch
        RegisterSearch({ label = TabConfig.Name, tab = TabConfig.Name, kind = "Tab", switch = SearchSwitch })
        local Sections = {}
        local CountSection = 0
        function Sections:AddSection(Title, AlwaysOpen)
            local Title = Title or "Title"
            local Section = Instance.new("Frame");
            local SectionDecideFrame = Instance.new("Frame");
            local UICorner1 = Instance.new("UICorner");
            local UIGradient = Instance.new("UIGradient");

            Section.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Section.BackgroundTransparency = 0.9990000128746033
            Section.BorderColor3 = Color3.fromRGB(0, 0, 0)
            Section.BorderSizePixel = 0
            Section.LayoutOrder = CountSection
            Section.ClipsDescendants = true
            Section.LayoutOrder = 1
            Section.Size = UDim2.new(1, 0, 0, 30)
            Section.Name = "Section"
            Section.Parent = ScrolLayers

            local SectionReal = Instance.new("Frame");
            local UICorner = Instance.new("UICorner");
            local UIStroke = Instance.new("UIStroke");
            local SectionButton = Instance.new("TextButton");
            local FeatureFrame = Instance.new("Frame");
            local FeatureImg = Instance.new("ImageLabel");
            local SectionTitle = Instance.new("TextLabel");

            SectionReal.AnchorPoint = Vector2.new(0.5, 0)
            SectionReal.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            SectionReal.BackgroundTransparency = 0.9350000023841858
            SectionReal.BorderColor3 = Color3.fromRGB(0, 0, 0)
            SectionReal.BorderSizePixel = 0
            SectionReal.LayoutOrder = 1
            SectionReal.Position = UDim2.new(0.5, 0, 0, 0)
            SectionReal.Size = UDim2.new(1, 1, 0, 30)
            SectionReal.Name = "SectionReal"
            SectionReal.Parent = Section

            UICorner.CornerRadius = UDim.new(0, 4)
            UICorner.Parent = SectionReal

            SectionButton.Font = Enum.Font.SourceSans
            SectionButton.Text = ""
            SectionButton.TextColor3 = Color3.fromRGB(0, 0, 0)
            SectionButton.TextSize = 14
            SectionButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            SectionButton.BackgroundTransparency = 0.9990000128746033
            SectionButton.BorderColor3 = Color3.fromRGB(0, 0, 0)
            SectionButton.BorderSizePixel = 0
            SectionButton.Size = UDim2.new(1, 0, 1, 0)
            SectionButton.Name = "SectionButton"
            SectionButton.Parent = SectionReal

            FeatureFrame.AnchorPoint = Vector2.new(1, 0.5)
            FeatureFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
            FeatureFrame.BackgroundTransparency = 0.9990000128746033
            FeatureFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
            FeatureFrame.BorderSizePixel = 0
            FeatureFrame.Position = UDim2.new(1, -5, 0.5, 0)
            FeatureFrame.Size = UDim2.new(0, 20, 0, 20)
            FeatureFrame.Name = "FeatureFrame"
            FeatureFrame.Parent = SectionReal

            FeatureImg.Image = "rbxassetid://16851841101"
            FeatureImg.AnchorPoint = Vector2.new(0.5, 0.5)
            FeatureImg.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            FeatureImg.BackgroundTransparency = 0.9990000128746033
            FeatureImg.BorderColor3 = Color3.fromRGB(0, 0, 0)
            FeatureImg.BorderSizePixel = 0
            FeatureImg.Position = UDim2.new(0.5, 0, 0.5, 0)
            FeatureImg.Rotation = -90
            FeatureImg.Size = UDim2.new(1, 6, 1, 6)
            FeatureImg.Name = "FeatureImg"
            FeatureImg.Parent = FeatureFrame

            SectionTitle.Font = Enum.Font.GothamBold
            SectionTitle.Text = Title
            SectionTitle.TextColor3 = Color3.fromRGB(230.77499270439148, 230.77499270439148, 230.77499270439148)
            SectionTitle.TextSize = 13
            SectionTitle.TextXAlignment = Enum.TextXAlignment.Left
            SectionTitle.TextYAlignment = Enum.TextYAlignment.Top
            SectionTitle.AnchorPoint = Vector2.new(0, 0.5)
            SectionTitle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            SectionTitle.BackgroundTransparency = 0.9990000128746033
            SectionTitle.BorderColor3 = Color3.fromRGB(0, 0, 0)
            SectionTitle.BorderSizePixel = 0
            SectionTitle.Position = UDim2.new(0, 10, 0.5, 0)
            SectionTitle.Size = UDim2.new(1, -50, 0, 13)
            SectionTitle.Name = "SectionTitle"
            SectionTitle.Parent = SectionReal

            SectionDecideFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            SectionDecideFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
            SectionDecideFrame.AnchorPoint = Vector2.new(0.5, 0)
            SectionDecideFrame.BorderSizePixel = 0
            SectionDecideFrame.Position = UDim2.new(0.5, 0, 0, 33)
            SectionDecideFrame.Size = UDim2.new(0, 0, 0, 2)
            SectionDecideFrame.Name = "SectionDecideFrame"
            SectionDecideFrame.Parent = Section

            UICorner1.Parent = SectionDecideFrame

            UIGradient.Color = ColorSequence.new {
                ColorSequenceKeypoint.new(0, Color3.fromRGB(20, 20, 20)),
                ColorSequenceKeypoint.new(0.5, GuiConfig.Color),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 20, 20))
            }
            UIGradient.Parent = SectionDecideFrame

            local SectionAdd = Instance.new("Frame");
            local UICorner8 = Instance.new("UICorner");
            local UIListLayout2 = Instance.new("UIListLayout");

            SectionAdd.AnchorPoint = Vector2.new(0.5, 0)
            SectionAdd.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            SectionAdd.BackgroundTransparency = 0.9990000128746033
            SectionAdd.BorderColor3 = Color3.fromRGB(0, 0, 0)
            SectionAdd.BorderSizePixel = 0
            SectionAdd.ClipsDescendants = true
            SectionAdd.LayoutOrder = 1
            SectionAdd.Position = UDim2.new(0.5, 0, 0, 38)
            SectionAdd.Size = UDim2.new(1, 0, 0, 100)
            SectionAdd.Name = "SectionAdd"
            SectionAdd.Parent = Section

            UICorner8.CornerRadius = UDim.new(0, 2)
            UICorner8.Parent = SectionAdd

            UIListLayout2.Padding = UDim.new(0, 3)
            UIListLayout2.SortOrder = Enum.SortOrder.LayoutOrder
            UIListLayout2.Parent = SectionAdd

            local OpenSection = false

            local function UpdateSizeScroll()
                local OffsetY = 0
                for _, child in ScrolLayers:GetChildren() do
                    if child.Name ~= "UIListLayout" then
                        OffsetY = OffsetY + 3 + child.Size.Y.Offset
                    end
                end
                ScrolLayers.CanvasSize = UDim2.new(0, 0, 0, OffsetY)
            end

            local SectionResizePending = false

            local function UpdateSizeSection()
                if not OpenSection then return end
                if SectionResizePending then return end
                SectionResizePending = true

                task.defer(function()
                    SectionResizePending = false

                    local SectionSizeYWitdh = 38
                    for _, v in SectionAdd:GetChildren() do
                        if v.Name ~= "UIListLayout" and v.Name ~= "UICorner" then
                            SectionSizeYWitdh = SectionSizeYWitdh + v.Size.Y.Offset + 3
                        end
                    end
                    TweenService:Create(FeatureFrame, TweenInfo.new(0.3), { Rotation = 90 }):Play()
                    TweenService:Create(Section, TweenInfo.new(0.3), { Size = UDim2.new(1, 1, 0, SectionSizeYWitdh) })
                        :Play()
                    TweenService:Create(SectionAdd, TweenInfo.new(0.3),
                        { Size = UDim2.new(1, 0, 0, SectionSizeYWitdh - 38) }):Play()
                    TweenService:Create(SectionDecideFrame, TweenInfo.new(0.3), { Size = UDim2.new(1, 0, 0, 2) }):Play()
                    UpdateSizeScroll()
                end)
            end

            if AlwaysOpen == true then
                SectionButton:Destroy()
                FeatureFrame:Destroy()
                OpenSection = true
                UpdateSizeSection()
            elseif AlwaysOpen == false then
                OpenSection = true
                UpdateSizeSection()
            else
                OpenSection = false
            end

            if AlwaysOpen ~= true then
                SectionButton.Activated:Connect(function()
                    CircleClick(SectionButton, Mouse.X, Mouse.Y)
                    if OpenSection then
                        TweenService:Create(FeatureFrame, TweenInfo.new(0.5), { Rotation = 0 }):Play()
                        TweenService:Create(Section, TweenInfo.new(0.5), { Size = UDim2.new(1, 1, 0, 30) }):Play()
                        TweenService:Create(SectionDecideFrame, TweenInfo.new(0.5), { Size = UDim2.new(0, 0, 0, 2) })
                            :Play()
                        OpenSection = false
                        task.wait(0.5)
                        UpdateSizeScroll()
                    else
                        OpenSection = true
                        UpdateSizeSection()
                    end
                end)
            end

            SectionAdd.ChildAdded:Connect(UpdateSizeSection)
            SectionAdd.ChildRemoved:Connect(UpdateSizeSection)

            local layout = ScrolLayers:FindFirstChildOfClass("UIListLayout")
            if layout then
                layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                    ScrolLayers.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 10)
                end)
            end

            local Items = {}
            local CountItem = 0

            function Items:AddParagraph(ParagraphConfig)
                local ParagraphConfig = ParagraphConfig or {}
                ParagraphConfig.Title = ParagraphConfig.Title or "Title"
                ParagraphConfig.Content = ParagraphConfig.Content or "Content"
                local ParagraphFunc = {}

                local Paragraph = Instance.new("Frame")
                local UICorner14 = Instance.new("UICorner")
                local ParagraphTitle = Instance.new("TextLabel")
                local ParagraphContent = Instance.new("TextLabel")

                Paragraph.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                Paragraph.BackgroundTransparency = 0.935
                Paragraph.BorderSizePixel = 0
                Paragraph.LayoutOrder = CountItem
                Paragraph.Size = UDim2.new(1, 0, 0, 46)
                Paragraph.Name = "Paragraph"
                Paragraph.Parent = SectionAdd

                UICorner14.CornerRadius = UDim.new(0, 4)
                UICorner14.Parent = Paragraph

                local iconOffset = 10
                if ParagraphConfig.Icon then
                    local IconImg = Instance.new("ImageLabel")
                    IconImg.Size = UDim2.new(0, 20, 0, 20)
                    IconImg.Position = UDim2.new(0, 8, 0, 12)
                    IconImg.BackgroundTransparency = 1
                    IconImg.Name = "ParagraphIcon"
                    IconImg.Parent = Paragraph

                    if Icons and Icons[ParagraphConfig.Icon] then
                        IconImg.Image = Icons[ParagraphConfig.Icon]
                    else
                        IconImg.Image = ParagraphConfig.Icon
                    end

                    iconOffset = 30
                end

                ParagraphTitle.Font = Enum.Font.GothamBold
                ParagraphTitle.Text = ParagraphConfig.Title
                ParagraphTitle.TextColor3 = Color3.fromRGB(231, 231, 231)
                ParagraphTitle.TextSize = 13
                ParagraphTitle.TextXAlignment = Enum.TextXAlignment.Left
                ParagraphTitle.TextYAlignment = Enum.TextYAlignment.Top
                ParagraphTitle.BackgroundTransparency = 1
                ParagraphTitle.Position = UDim2.new(0, iconOffset, 0, 10)
                ParagraphTitle.Size = UDim2.new(1, -16, 0, 13)
                ParagraphTitle.Name = "ParagraphTitle"
                ParagraphTitle.Parent = Paragraph

                ParagraphContent.Font = Enum.Font.Gotham
                ParagraphContent.Text = ParagraphConfig.Content
                ParagraphContent.TextColor3 = Color3.fromRGB(255, 255, 255)
                ParagraphContent.TextSize = 12
                ParagraphContent.TextXAlignment = Enum.TextXAlignment.Left
                ParagraphContent.TextYAlignment = Enum.TextYAlignment.Top
                ParagraphContent.BackgroundTransparency = 1
                ParagraphContent.Position = UDim2.new(0, iconOffset, 0, 25)
                ParagraphContent.Name = "ParagraphContent"
                ParagraphContent.TextWrapped = false
                ParagraphContent.RichText = true
                ParagraphContent.Parent = Paragraph

                ParagraphContent.Size = UDim2.new(1, -16, 0, ParagraphContent.TextBounds.Y)

                local ParagraphButton
                if ParagraphConfig.ButtonText then
                    ParagraphButton = Instance.new("TextButton")
                    ParagraphButton.Position = UDim2.new(0, 10, 0, 42)
                    ParagraphButton.Size = UDim2.new(1, -22, 0, 28)
                    ParagraphButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                    ParagraphButton.BackgroundTransparency = 0.935
                    ParagraphButton.Font = Enum.Font.GothamBold
                    ParagraphButton.TextSize = 12
                    ParagraphButton.TextTransparency = 0.3
                    ParagraphButton.TextColor3 = Color3.fromRGB(255, 255, 255)
                    ParagraphButton.Text = ParagraphConfig.ButtonText
                    ParagraphButton.Parent = Paragraph

                    local btnCorner = Instance.new("UICorner")
                    btnCorner.CornerRadius = UDim.new(0, 6)
                    btnCorner.Parent = ParagraphButton

                    if ParagraphConfig.ButtonCallback then
                        ParagraphButton.MouseButton1Click:Connect(ParagraphConfig.ButtonCallback)
                    end
                end

               local function UpdateSize()
    task.spawn(function()
        task.wait()
        task.wait()  
        ParagraphContent.TextWrapped = true
        ParagraphContent.Size = UDim2.new(1, -16, 0, 9999)  
        task.wait()
        local contentHeight = ParagraphContent.TextBounds.Y
        ParagraphContent.Size = UDim2.new(1, -16, 0, contentHeight)
        local totalHeight = contentHeight + 33
        if ParagraphButton then
            totalHeight = totalHeight + ParagraphButton.Size.Y.Offset + 5
        end
        Paragraph.Size = UDim2.new(1, 0, 0, totalHeight)
        UpdateSizeSection()
    end)
end

UpdateSize()

ParagraphContent:GetPropertyChangedSignal("TextBounds"):Connect(UpdateSize)

function ParagraphFunc:SetContent(content)
    content = content or "Content"
    ParagraphContent.Text = content
    task.spawn(function()
        task.wait()
        task.wait()
        UpdateSize()
    end)
end
                CountItem = CountItem + 1
                RegisterSearch({ label = ParagraphConfig.Title, tab = TabConfig.Name, kind = "Info", switch = SearchSwitch })
                return ParagraphFunc
            end

            function Items:AddPanel(PanelConfig)
                PanelConfig = PanelConfig or {}
                PanelConfig.Title = PanelConfig.Title or "Title"
                PanelConfig.Content = PanelConfig.Content or ""
                PanelConfig.Placeholder = PanelConfig.Placeholder or nil
                PanelConfig.Default = PanelConfig.Default or ""
                PanelConfig.ButtonText = PanelConfig.Button or PanelConfig.ButtonText or "Confirm"
                PanelConfig.ButtonCallback = PanelConfig.Callback or PanelConfig.ButtonCallback or function() end
                PanelConfig.SubButtonText = PanelConfig.SubButton or PanelConfig.SubButtonText or nil
                PanelConfig.SubButtonCallback = PanelConfig.SubCallback or PanelConfig.SubButtonCallback or
                    function() end

                local configKey = "Panel_" .. PanelConfig.Title
                local shouldSave = PanelConfig.Save ~= false
                if shouldSave and ConfigData[configKey] ~= nil then
                    PanelConfig.Default = ConfigData[configKey]
                end

                local PanelFunc = { Value = PanelConfig.Default }

                local baseHeight = 50

                if PanelConfig.Placeholder then
                    baseHeight = baseHeight + 40
                end

                if PanelConfig.SubButtonText then
                    baseHeight = baseHeight + 40
                else
                    baseHeight = baseHeight + 36
                end

                local Panel = Instance.new("Frame")
                Panel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                Panel.BackgroundTransparency = 0.935
                Panel.Size = UDim2.new(1, 0, 0, baseHeight)
                Panel.LayoutOrder = CountItem
                Panel.Parent = SectionAdd

                local UICorner = Instance.new("UICorner")
                UICorner.CornerRadius = UDim.new(0, 4)
                UICorner.Parent = Panel

                local Title = Instance.new("TextLabel")
                Title.Font = Enum.Font.GothamBold
                Title.Text = PanelConfig.Title
                Title.TextSize = 13
                Title.TextColor3 = Color3.fromRGB(255, 255, 255)
                Title.TextXAlignment = Enum.TextXAlignment.Left
                Title.BackgroundTransparency = 1
                Title.Position = UDim2.new(0, 10, 0, 10)
                Title.Size = UDim2.new(1, -20, 0, 13)
                Title.Parent = Panel

                local Content = Instance.new("TextLabel")
                Content.Font = Enum.Font.Gotham
                Content.Text = PanelConfig.Content
                Content.TextSize = 12
                Content.TextColor3 = Color3.fromRGB(255, 255, 255)
                Content.TextTransparency = 0
                Content.TextXAlignment = Enum.TextXAlignment.Left
                Content.BackgroundTransparency = 1
                Content.RichText = true
                Content.Position = UDim2.new(0, 10, 0, 28)
                Content.Size = UDim2.new(1, -20, 0, 14)
                Content.Parent = Panel

                local InputBox
                if PanelConfig.Placeholder then
                    local InputFrame = Instance.new("Frame")
                    InputFrame.AnchorPoint = Vector2.new(0.5, 0)
                    InputFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                    InputFrame.BackgroundTransparency = 0.95
                    InputFrame.Position = UDim2.new(0.5, 0, 0, 48)
                    InputFrame.Size = UDim2.new(1, -20, 0, 30)
                    InputFrame.Parent = Panel

                    local inputCorner = Instance.new("UICorner")
                    inputCorner.CornerRadius = UDim.new(0, 4)
                    inputCorner.Parent = InputFrame

                    InputBox = Instance.new("TextBox")
                    InputBox.Font = Enum.Font.GothamBold
                    InputBox.PlaceholderText = PanelConfig.Placeholder
                    InputBox.PlaceholderColor3 = Color3.fromRGB(120, 120, 120)
                    InputBox.Text = PanelConfig.Default
                    InputBox.TextSize = 11
                    InputBox.TextColor3 = Color3.fromRGB(255, 255, 255)
                    InputBox.BackgroundTransparency = 1
                    InputBox.TextXAlignment = Enum.TextXAlignment.Left
                    InputBox.Size = UDim2.new(1, -10, 1, -6)
                    InputBox.Position = UDim2.new(0, 5, 0, 3)
                    InputBox.Parent = InputFrame
                end

                local yBtn = 0
                if PanelConfig.Placeholder then
                    yBtn = 88
                else
                    yBtn = 48
                end

                local ButtonMain = Instance.new("TextButton")
                ButtonMain.Font = Enum.Font.GothamBold
                ButtonMain.Text = PanelConfig.ButtonText
                ButtonMain.TextColor3 = Color3.fromRGB(255, 255, 255)
                ButtonMain.TextSize = 12
                ButtonMain.TextTransparency = 0.3
                ButtonMain.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                ButtonMain.BackgroundTransparency = 0.935
                ButtonMain.Size = PanelConfig.SubButtonText and UDim2.new(0.5, -12, 0, 30) or UDim2.new(1, -20, 0, 30)
                ButtonMain.Position = UDim2.new(0, 10, 0, yBtn)
                ButtonMain.Parent = Panel

                local btnCorner = Instance.new("UICorner")
                btnCorner.CornerRadius = UDim.new(0, 6)
                btnCorner.Parent = ButtonMain

                ButtonMain.MouseButton1Click:Connect(function()
                    PanelConfig.ButtonCallback(InputBox and InputBox.Text or "")
                end)

                if PanelConfig.SubButtonText then
                    local SubButton = Instance.new("TextButton")
                    SubButton.Font = Enum.Font.GothamBold
                    SubButton.Text = PanelConfig.SubButtonText
                    SubButton.TextColor3 = Color3.fromRGB(255, 255, 255)
                    SubButton.TextSize = 12
                    SubButton.TextTransparency = 0.3
                    SubButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                    SubButton.BackgroundTransparency = 0.935
                    SubButton.Size = UDim2.new(0.5, -12, 0, 30)
                    SubButton.Position = UDim2.new(0.5, 2, 0, yBtn)
                    SubButton.Parent = Panel

                    local subCorner = Instance.new("UICorner")
                    subCorner.CornerRadius = UDim.new(0, 6)
                    subCorner.Parent = SubButton

                    SubButton.MouseButton1Click:Connect(function()
                        PanelConfig.SubButtonCallback(InputBox and InputBox.Text or "")
                    end)
                end

                if InputBox then
                    InputBox.FocusLost:Connect(function()
                        PanelFunc:Set(InputBox.Text)
                    end)
                end

                function PanelFunc:Set(Value, noSave)
                    Value = tostring(Value or "")
                    PanelFunc.Value = Value
                    if shouldSave then
                        ConfigData[configKey] = Value
                    end
                    if InputBox then
                        InputBox.Text = Value
                    end
                    if shouldSave and not noSave then QueueSaveConfig() end
                end

                function PanelFunc:GetInput()
                    return InputBox and InputBox.Text or ""
                end

                PanelFunc:Set(PanelFunc.Value, true)
                CountItem = CountItem + 1
                if shouldSave then
                    Elements[configKey] = PanelFunc
                end
                return PanelFunc
            end

            function Items:AddButton(ButtonConfig)
                ButtonConfig = ButtonConfig or {}
                ButtonConfig.Title = ButtonConfig.Title or "Confirm"
                ButtonConfig.Callback = ButtonConfig.Callback or function() end
                ButtonConfig.SubTitle = ButtonConfig.SubTitle or nil
                ButtonConfig.SubCallback = ButtonConfig.SubCallback or function() end

                local Button = Instance.new("Frame")
                Button.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                Button.BackgroundTransparency = 0.935
                Button.Size = UDim2.new(1, 0, 0, 40)
                Button.LayoutOrder = CountItem
                Button.Parent = SectionAdd

                local UICorner = Instance.new("UICorner")
                UICorner.CornerRadius = UDim.new(0, 4)
                UICorner.Parent = Button

                local MainButton = Instance.new("TextButton")
                MainButton.Font = Enum.Font.GothamBold
                MainButton.Text = ButtonConfig.Title
                MainButton.TextSize = 12
                MainButton.TextColor3 = Color3.fromRGB(255, 255, 255)
                MainButton.TextTransparency = 0.3
                MainButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                MainButton.BackgroundTransparency = 0.935
                MainButton.Size = ButtonConfig.SubTitle and UDim2.new(0.5, -8, 1, -10) or UDim2.new(1, -12, 1, -10)
                MainButton.Position = UDim2.new(0, 6, 0, 5)
                MainButton.Parent = Button

                local mainCorner = Instance.new("UICorner")
                mainCorner.CornerRadius = UDim.new(0, 4)
                mainCorner.Parent = MainButton

                MainButton.MouseButton1Click:Connect(ButtonConfig.Callback)

                if ButtonConfig.SubTitle then
                    local SubButton = Instance.new("TextButton")
                    SubButton.Font = Enum.Font.GothamBold
                    SubButton.Text = ButtonConfig.SubTitle
                    SubButton.TextSize = 12
                    SubButton.TextTransparency = 0.3
                    SubButton.TextColor3 = Color3.fromRGB(255, 255, 255)
                    SubButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                    SubButton.BackgroundTransparency = 0.935
                    SubButton.Size = UDim2.new(0.5, -8, 1, -10)
                    SubButton.Position = UDim2.new(0.5, 2, 0, 5)
                    SubButton.Parent = Button

                    local subCorner = Instance.new("UICorner")
                    subCorner.CornerRadius = UDim.new(0, 4)
                    subCorner.Parent = SubButton

                    SubButton.MouseButton1Click:Connect(ButtonConfig.SubCallback)
                end

                CountItem = CountItem + 1
                RegisterSearch({ label = ButtonConfig.Title, tab = TabConfig.Name, kind = "Button", switch = SearchSwitch })
            end

            function Items:AddToggle(ToggleConfig)
                local ToggleConfig = ToggleConfig or {}
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
                local UICorner20 = Instance.new("UICorner")
                local ToggleTitle = Instance.new("TextLabel")
                local ToggleContent = Instance.new("TextLabel")
                local ToggleButton = Instance.new("TextButton")
                local FeatureFrame2 = Instance.new("Frame")
                local UICorner22 = Instance.new("UICorner")
                local UIStroke8 = Instance.new("UIStroke")
                local ToggleCircle = Instance.new("Frame")
                local UICorner23 = Instance.new("UICorner")

                Toggle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                Toggle.BackgroundTransparency = 0.935
                Toggle.BorderSizePixel = 0
                Toggle.LayoutOrder = CountItem
                Toggle.Name = "Toggle"
                Toggle.Parent = SectionAdd

                UICorner20.CornerRadius = UDim.new(0, 4)
                UICorner20.Parent = Toggle

                ToggleTitle.Font = Enum.Font.GothamBold
                ToggleTitle.Text = ToggleConfig.Title
                ToggleTitle.TextSize = 13
                ToggleTitle.TextColor3 = Color3.fromRGB(231, 231, 231)
                ToggleTitle.TextXAlignment = Enum.TextXAlignment.Left
                ToggleTitle.TextYAlignment = Enum.TextYAlignment.Top
                ToggleTitle.BackgroundTransparency = 1
                ToggleTitle.Position = UDim2.new(0, 10, 0, 10)
                ToggleTitle.Size = UDim2.new(1, -100, 0, 13)
                ToggleTitle.Name = "ToggleTitle"
                ToggleTitle.Parent = Toggle

                local ToggleTitle2 = Instance.new("TextLabel")
                ToggleTitle2.Font = Enum.Font.GothamBold
                ToggleTitle2.Text = ToggleConfig.Title2
                ToggleTitle2.TextSize = 12
                ToggleTitle2.TextColor3 = Color3.fromRGB(231, 231, 231)
                ToggleTitle2.TextXAlignment = Enum.TextXAlignment.Left
                ToggleTitle2.TextYAlignment = Enum.TextYAlignment.Top
                ToggleTitle2.BackgroundTransparency = 1
                ToggleTitle2.Position = UDim2.new(0, 10, 0, 23)
                ToggleTitle2.Size = UDim2.new(1, -100, 0, 12)
                ToggleTitle2.Name = "ToggleTitle2"
                ToggleTitle2.Parent = Toggle

                ToggleContent.Font = Enum.Font.GothamBold
                ToggleContent.Text = ToggleConfig.Content
                ToggleContent.TextColor3 = Color3.fromRGB(255, 255, 255)
                ToggleContent.TextSize = 12
                ToggleContent.TextTransparency = 0.6
                ToggleContent.TextXAlignment = Enum.TextXAlignment.Left
                ToggleContent.TextYAlignment = Enum.TextYAlignment.Bottom
                ToggleContent.BackgroundTransparency = 1
                ToggleContent.Size = UDim2.new(1, -100, 0, 12)
                ToggleContent.Name = "ToggleContent"
                ToggleContent.Parent = Toggle

                if ToggleConfig.Title2 ~= "" then
                    Toggle.Size = UDim2.new(1, 0, 0, 57)
                    ToggleContent.Position = UDim2.new(0, 10, 0, 36)
                    ToggleTitle2.Visible = true
                else
                    Toggle.Size = UDim2.new(1, 0, 0, 46)
                    ToggleContent.Position = UDim2.new(0, 10, 0, 23)
                    ToggleTitle2.Visible = false
                end

                ToggleContent.Size = UDim2.new(1, -100, 0,
                    12 + (12 * (ToggleContent.TextBounds.X // ToggleContent.AbsoluteSize.X)))
                ToggleContent.TextWrapped = true
                if ToggleConfig.Title2 ~= "" then
                    Toggle.Size = UDim2.new(1, 0, 0, ToggleContent.AbsoluteSize.Y + 47)
                else
                    Toggle.Size = UDim2.new(1, 0, 0, ToggleContent.AbsoluteSize.Y + 33)
                end

                ToggleContent:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
                    ToggleContent.TextWrapped = false
                    ToggleContent.Size = UDim2.new(1, -100, 0,
                        12 + (12 * (ToggleContent.TextBounds.X // ToggleContent.AbsoluteSize.X)))
                    if ToggleConfig.Title2 ~= "" then
                        Toggle.Size = UDim2.new(1, 0, 0, ToggleContent.AbsoluteSize.Y + 47)
                    else
                        Toggle.Size = UDim2.new(1, 0, 0, ToggleContent.AbsoluteSize.Y + 33)
                    end
                    ToggleContent.TextWrapped = true
                    UpdateSizeSection()
                end)

                ToggleButton.Font = Enum.Font.SourceSans
                ToggleButton.Text = ""
                ToggleButton.BackgroundTransparency = 1
                ToggleButton.Size = UDim2.new(1, 0, 1, 0)
                ToggleButton.Name = "ToggleButton"
                ToggleButton.Parent = Toggle

                FeatureFrame2.AnchorPoint = Vector2.new(1, 0.5)
                FeatureFrame2.BackgroundTransparency = 0.92
                FeatureFrame2.BorderSizePixel = 0
                FeatureFrame2.Position = UDim2.new(1, -15, 0.5, 0)
                FeatureFrame2.Size = UDim2.new(0, 30, 0, 15)
                FeatureFrame2.Name = "FeatureFrame"
                FeatureFrame2.Parent = Toggle

                UICorner22.Parent = FeatureFrame2

                UIStroke8.Color = Color3.fromRGB(255, 255, 255)
                UIStroke8.Thickness = 2
                UIStroke8.Transparency = 0.9
                UIStroke8.Parent = FeatureFrame2

                ToggleCircle.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
                ToggleCircle.BorderSizePixel = 0
                ToggleCircle.Size = UDim2.new(0, 14, 0, 14)
                ToggleCircle.Name = "ToggleCircle"
                ToggleCircle.Parent = FeatureFrame2

                UICorner23.CornerRadius = UDim.new(0, 15)
                UICorner23.Parent = ToggleCircle

                ToggleButton.Activated:Connect(function()
                    ToggleFunc.Value = not ToggleFunc.Value
                    ToggleFunc:Set(ToggleFunc.Value)
                end)

                function ToggleFunc:Set(Value, noSave)
                    Value = Value and true or false
                    ToggleFunc.Value = Value
                    if typeof(ToggleConfig.Callback) == "function" then
                        local ok, err = pcall(function()
                            ToggleConfig.Callback(Value)
                        end)
                        if not ok then warn("Toggle Callback error:", err) end
                    end
                    if shouldSave then
                        ConfigData[configKey] = Value
                        if not noSave then QueueSaveConfig() end
                    end
                    if Value then
                        TweenService:Create(ToggleTitle, TweenInfo.new(0.2), { TextColor3 = GuiConfig.Color }):Play()
                        TweenService:Create(ToggleCircle, TweenInfo.new(0.2), { Position = UDim2.new(0, 15, 0, 0) })
                            :Play()
                        TweenService:Create(UIStroke8, TweenInfo.new(0.2), { Color = GuiConfig.Color, Transparency = 0 })
                            :Play()
                        TweenService:Create(FeatureFrame2, TweenInfo.new(0.2),
                            { BackgroundColor3 = GuiConfig.Color, BackgroundTransparency = 0 }):Play()
                    else
                        TweenService:Create(ToggleTitle, TweenInfo.new(0.2),
                            { TextColor3 = Color3.fromRGB(230, 230, 230) }):Play()
                        TweenService:Create(ToggleCircle, TweenInfo.new(0.2), { Position = UDim2.new(0, 0, 0, 0) }):Play()
                        TweenService:Create(UIStroke8, TweenInfo.new(0.2),
                            { Color = Color3.fromRGB(255, 255, 255), Transparency = 0.9 }):Play()
                        TweenService:Create(FeatureFrame2, TweenInfo.new(0.2),
                            { BackgroundColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 0.92 }):Play()
                    end
                end

                ToggleFunc:Set(ToggleFunc.Value, true)
                CountItem = CountItem + 1
                if shouldSave then
                    Elements[configKey] = ToggleFunc
                end
                RegisterSearch({ label = ToggleConfig.Title, tab = TabConfig.Name, kind = "Toggle", element = ToggleFunc, switch = SearchSwitch })
                return ToggleFunc
            end

            function Items:AddSlider(SliderConfig)
                local SliderConfig = SliderConfig or {}
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

                local Slider = Instance.new("Frame");
                local UICorner15 = Instance.new("UICorner");
                local SliderTitle = Instance.new("TextLabel");
                local SliderContent = Instance.new("TextLabel");
                local SliderInput = Instance.new("Frame");
                local UICorner16 = Instance.new("UICorner");
                local TextBox = Instance.new("TextBox");
                local SliderFrame = Instance.new("Frame");
                local UICorner17 = Instance.new("UICorner");
                local SliderDraggable = Instance.new("Frame");
                local UICorner18 = Instance.new("UICorner");
                local UIStroke5 = Instance.new("UIStroke");
                local SliderCircle = Instance.new("Frame");
                local UICorner19 = Instance.new("UICorner");
                local UIStroke6 = Instance.new("UIStroke");
                local UIStroke7 = Instance.new("UIStroke");

                Slider.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                Slider.BackgroundTransparency = 0.9350000023841858
                Slider.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Slider.BorderSizePixel = 0
                Slider.LayoutOrder = CountItem
                Slider.Size = UDim2.new(1, 0, 0, 46)
                Slider.Name = "Slider"
                Slider.Parent = SectionAdd

                UICorner15.CornerRadius = UDim.new(0, 4)
                UICorner15.Parent = Slider

                SliderTitle.Font = Enum.Font.GothamBold
                SliderTitle.Text = SliderConfig.Title
                SliderTitle.TextColor3 = Color3.fromRGB(230.77499270439148, 230.77499270439148, 230.77499270439148)
                SliderTitle.TextSize = 13
                SliderTitle.TextXAlignment = Enum.TextXAlignment.Left
                SliderTitle.TextYAlignment = Enum.TextYAlignment.Top
                SliderTitle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                SliderTitle.BackgroundTransparency = 0.9990000128746033
                SliderTitle.BorderColor3 = Color3.fromRGB(0, 0, 0)
                SliderTitle.BorderSizePixel = 0
                SliderTitle.Position = UDim2.new(0, 10, 0, 10)
                SliderTitle.Size = UDim2.new(1, -230, 0, 13)
                SliderTitle.Name = "SliderTitle"
                SliderTitle.Parent = Slider

                SliderContent.Font = Enum.Font.GothamBold
                SliderContent.Text = SliderConfig.Content
                SliderContent.TextColor3 = Color3.fromRGB(255, 255, 255)
                SliderContent.TextSize = 12
                SliderContent.TextTransparency = 0.6000000238418579
                SliderContent.TextXAlignment = Enum.TextXAlignment.Left
                SliderContent.TextYAlignment = Enum.TextYAlignment.Bottom
                SliderContent.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                SliderContent.BackgroundTransparency = 0.9990000128746033
                SliderContent.BorderColor3 = Color3.fromRGB(0, 0, 0)
                SliderContent.BorderSizePixel = 0
                SliderContent.Position = UDim2.new(0, 10, 0, 25)
                SliderContent.Size = UDim2.new(1, -230, 0, 12)
                SliderContent.Name = "SliderContent"
                SliderContent.Parent = Slider

                SliderContent.Size = UDim2.new(1, -230, 0,
                    12 + (12 * (SliderContent.TextBounds.X // SliderContent.AbsoluteSize.X)))
                SliderContent.TextWrapped = true
                Slider.Size = UDim2.new(1, 0, 0, SliderContent.AbsoluteSize.Y + 33)

                SliderContent:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
                    SliderContent.TextWrapped = false
                    SliderContent.Size = UDim2.new(1, -230, 0,
                        12 + (12 * (SliderContent.TextBounds.X // SliderContent.AbsoluteSize.X)))
                    Slider.Size = UDim2.new(1, 0, 0, SliderContent.AbsoluteSize.Y + 33)
                    SliderContent.TextWrapped = true
                    UpdateSizeSection()
                end)

                SliderInput.AnchorPoint = Vector2.new(0, 0.5)
                SliderInput.BackgroundColor3 = GuiConfig.Color
                SliderInput.BorderColor3 = Color3.fromRGB(0, 0, 0)
                SliderInput.BackgroundTransparency = 1
                SliderInput.BorderSizePixel = 0
                SliderInput.Position = UDim2.new(1, -200, 0.5, 0)
                SliderInput.Size = UDim2.new(0, 44, 0, 20)
                SliderInput.Name = "SliderInput"
                SliderInput.Parent = Slider

                UICorner16.CornerRadius = UDim.new(0, 2)
                UICorner16.Parent = SliderInput

                TextBox.Font = Enum.Font.GothamBold
                TextBox.Text = "90"
                TextBox.TextColor3 = Color3.fromRGB(255, 255, 255)
                TextBox.TextSize = 13
                TextBox.TextWrapped = true
                TextBox.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                TextBox.BackgroundTransparency = 0.9990000128746033
                TextBox.BorderColor3 = Color3.fromRGB(0, 0, 0)
                TextBox.BorderSizePixel = 0
                TextBox.Position = UDim2.new(0, -1, 0, 0)
                TextBox.Size = UDim2.new(1, 0, 1, 0)
                TextBox.Parent = SliderInput

                SliderFrame.AnchorPoint = Vector2.new(1, 0.5)
                SliderFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                SliderFrame.BackgroundTransparency = 0.800000011920929
                SliderFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
                SliderFrame.BorderSizePixel = 0
                SliderFrame.Position = UDim2.new(1, -20, 0.5, 0)
                SliderFrame.Size = UDim2.new(0, 140, 0, 3)
                SliderFrame.Name = "SliderFrame"
                SliderFrame.Parent = Slider

                UICorner17.Parent = SliderFrame

                SliderDraggable.AnchorPoint = Vector2.new(0, 0.5)
                SliderDraggable.BackgroundColor3 = GuiConfig.Color
                SliderDraggable.BorderColor3 = Color3.fromRGB(0, 0, 0)
                SliderDraggable.BorderSizePixel = 0
                SliderDraggable.Position = UDim2.new(0, 0, 0.5, 0)
                SliderDraggable.Size = UDim2.new(0.899999976, 0, 0, 1)
                SliderDraggable.Name = "SliderDraggable"
                SliderDraggable.Parent = SliderFrame

                UICorner18.Parent = SliderDraggable

                SliderCircle.AnchorPoint = Vector2.new(1, 0.5)
                SliderCircle.BackgroundColor3 = GuiConfig.Color
                SliderCircle.BorderColor3 = Color3.fromRGB(0, 0, 0)
                SliderCircle.BorderSizePixel = 0
                SliderCircle.Position = UDim2.new(1, 4, 0.5, 0)
                SliderCircle.Size = UDim2.new(0, 8, 0, 8)
                SliderCircle.Name = "SliderCircle"
                SliderCircle.Parent = SliderDraggable

                UICorner19.Parent = SliderCircle

                UIStroke6.Color = GuiConfig.Color
                UIStroke6.Parent = SliderCircle

                local Dragging = false
                local UpdatingText = false

                local function Round(Number, Factor)
                    if sliderSpan <= 0 then return SliderConfig.Min end
                    local Steps = math.floor(((Number - SliderConfig.Min) / Factor) + 0.5)
                    return SliderConfig.Min + (Steps * Factor)
                end

                local function FormatValue(Value)
                    if math.abs(Value - math.floor(Value)) < 0.000001 then
                        return tostring(math.floor(Value))
                    end
                    local text = string.format("%.4f", Value)
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
                    if shouldSave then
                        ConfigData[configKey] = Value
                    end

                    UpdatingText = true
                    TextBox.Text = FormatValue(Value)
                    UpdatingText = false

                    local targetSize = UDim2.fromScale(ValueScale(Value), 1)
                    if instant then
                        SliderDraggable.Size = targetSize
                    else
                        TweenService:Create(
                            SliderDraggable,
                            TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                            { Size = targetSize }
                        ):Play()
                    end

                    if fireCallback then
                        local ok, err = pcall(function()
                            SliderConfig.Callback(Value)
                        end)
                        if not ok then warn("Slider Callback error:", err) end
                    end

                    if shouldSave and not noSave then QueueSaveConfig() end
                end

                function SliderFunc:Set(Value, noSave)
                    ApplySliderValue(Value, noSave, false, true)
                end

                SliderFrame.InputBegan:Connect(function(Input)
                    if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                        Dragging = true
                        TweenService:Create(
                            SliderCircle,
                            TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                            { Size = UDim2.new(0, 14, 0, 14) }
                        ):Play()
                        local SizeScale = math.clamp(
                            (Input.Position.X - SliderFrame.AbsolutePosition.X) / SliderFrame.AbsoluteSize.X,
                            0,
                            1
                        )
                        ApplySliderValue(SliderConfig.Min + (sliderSpan * SizeScale), true, true, SliderConfig.Live)
                    end
                end)

                local function FinishSliderDrag(Input)
                    if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                        if not Dragging then return end
                        Dragging = false
                        ApplySliderValue(SliderFunc.Value, false, false, not SliderConfig.Live)
                        TweenService:Create(
                            SliderCircle,
                            TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                            { Size = UDim2.new(0, 8, 0, 8) }
                        ):Play()
                    end
                end

                SliderFrame.InputEnded:Connect(FinishSliderDrag)
                UserInputService.InputEnded:Connect(FinishSliderDrag)

                UserInputService.InputChanged:Connect(function(Input)
                    if Dragging and (Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch) then
                        local SizeScale = math.clamp(
                            (Input.Position.X - SliderFrame.AbsolutePosition.X) / SliderFrame.AbsoluteSize.X,
                            0,
                            1
                        )
                        ApplySliderValue(SliderConfig.Min + (sliderSpan * SizeScale), true, true, SliderConfig.Live)
                    end
                end)

                TextBox.FocusLost:Connect(function()
                    if UpdatingText then return end
                    local raw = TextBox.Text:gsub(",", ".")
                    local number = tonumber(raw)
                    if number then
                        SliderFunc:Set(number)
                    else
                        TextBox.Text = FormatValue(SliderFunc.Value)
                    end
                end)
                SliderFunc:Set(SliderConfig.Default, true)
                CountItem = CountItem + 1
                if shouldSave then
                    Elements[configKey] = SliderFunc
                end
                RegisterSearch({ label = SliderConfig.Title, tab = TabConfig.Name, kind = "Slider", element = SliderFunc, switch = SearchSwitch })
                return SliderFunc
            end

            function Items:AddInput(InputConfig)
                local InputConfig = InputConfig or {}
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

                local Input = Instance.new("Frame");
                local UICorner12 = Instance.new("UICorner");
                local InputTitle = Instance.new("TextLabel");
                local InputContent = Instance.new("TextLabel");
                local InputFrame = Instance.new("Frame");
                local UICorner13 = Instance.new("UICorner");
                local InputTextBox = Instance.new("TextBox");

                Input.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                Input.BackgroundTransparency = 0.9350000023841858
                Input.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Input.BorderSizePixel = 0
                Input.LayoutOrder = CountItem
                Input.Size = UDim2.new(1, 0, 0, 46)
                Input.Name = "Input"
                Input.Parent = SectionAdd

                UICorner12.CornerRadius = UDim.new(0, 4)
                UICorner12.Parent = Input

                InputTitle.Font = Enum.Font.GothamBold
                InputTitle.Text = InputConfig.Title or "TextBox"
                InputTitle.TextColor3 = Color3.fromRGB(230.77499270439148, 230.77499270439148, 230.77499270439148)
                InputTitle.TextSize = 13
                InputTitle.TextXAlignment = Enum.TextXAlignment.Left
                InputTitle.TextYAlignment = Enum.TextYAlignment.Top
                InputTitle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                InputTitle.BackgroundTransparency = 0.9990000128746033
                InputTitle.BorderColor3 = Color3.fromRGB(0, 0, 0)
                InputTitle.BorderSizePixel = 0
                InputTitle.Position = UDim2.new(0, 10, 0, 10)
                InputTitle.Size = UDim2.new(1, -180, 0, 13)
                InputTitle.Name = "InputTitle"
                InputTitle.Parent = Input

                InputContent.Font = Enum.Font.GothamBold
                InputContent.Text = InputConfig.Content or "This is a TextBox"
                InputContent.TextColor3 = Color3.fromRGB(255, 255, 255)
                InputContent.TextSize = 12
                InputContent.TextTransparency = 0.6000000238418579
                InputContent.TextWrapped = true
                InputContent.TextXAlignment = Enum.TextXAlignment.Left
                InputContent.TextYAlignment = Enum.TextYAlignment.Bottom
                InputContent.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                InputContent.BackgroundTransparency = 0.9990000128746033
                InputContent.BorderColor3 = Color3.fromRGB(0, 0, 0)
                InputContent.BorderSizePixel = 0
                InputContent.Position = UDim2.new(0, 10, 0, 25)
                InputContent.Size = UDim2.new(1, -180, 0, 12)
                InputContent.Name = "InputContent"
                InputContent.Parent = Input

                InputContent.Size = UDim2.new(1, -180, 0,
                    12 + (12 * (InputContent.TextBounds.X // InputContent.AbsoluteSize.X)))
                InputContent.TextWrapped = true
                Input.Size = UDim2.new(1, 0, 0, InputContent.AbsoluteSize.Y + 33)

                InputContent:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
                    InputContent.TextWrapped = false
                    InputContent.Size = UDim2.new(1, -180, 0,
                        12 + (12 * (InputContent.TextBounds.X // InputContent.AbsoluteSize.X)))
                    Input.Size = UDim2.new(1, 0, 0, InputContent.AbsoluteSize.Y + 33)
                    InputContent.TextWrapped = true
                    UpdateSizeSection()
                end)

                InputFrame.AnchorPoint = Vector2.new(1, 0.5)
                InputFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                InputFrame.BackgroundTransparency = 0.949999988079071
                InputFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
                InputFrame.BorderSizePixel = 0
                InputFrame.ClipsDescendants = true
                InputFrame.Position = UDim2.new(1, -7, 0.5, 0)
                InputFrame.Size = UDim2.new(0, 148, 0, 30)
                InputFrame.Name = "InputFrame"
                InputFrame.Parent = Input

                UICorner13.CornerRadius = UDim.new(0, 4)
                UICorner13.Parent = InputFrame

                InputTextBox.CursorPosition = -1
                InputTextBox.Font = Enum.Font.GothamBold
                InputTextBox.PlaceholderColor3 = Color3.fromRGB(120.00000044703484, 120.00000044703484,
                    120.00000044703484)
                InputTextBox.PlaceholderText = InputConfig.Placeholder
                InputTextBox.Text = InputConfig.Default
                InputTextBox.TextColor3 = Color3.fromRGB(255, 255, 255)
                InputTextBox.TextSize = 12
                InputTextBox.TextXAlignment = Enum.TextXAlignment.Left
                InputTextBox.AnchorPoint = Vector2.new(0, 0.5)
                InputTextBox.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                InputTextBox.BackgroundTransparency = 0.9990000128746033
                InputTextBox.BorderColor3 = Color3.fromRGB(0, 0, 0)
                InputTextBox.BorderSizePixel = 0
                InputTextBox.Position = UDim2.new(0, 5, 0.5, 0)
                InputTextBox.Size = UDim2.new(1, -10, 1, -8)
                InputTextBox.Name = "InputTextBox"
                InputTextBox.Parent = InputFrame
                function InputFunc:Set(Value, noSave)
                    Value = tostring(Value or "")
                    InputTextBox.Text = Value
                    InputFunc.Value = Value
                    InputConfig.Callback(Value)
                    if shouldSave then
                        ConfigData[configKey] = Value
                        if not noSave then QueueSaveConfig() end
                    end
                end

                InputFunc:Set(InputFunc.Value, true)

                InputTextBox.FocusLost:Connect(function()
                    InputFunc:Set(InputTextBox.Text)
                end)
                CountItem = CountItem + 1
                if shouldSave then
                    Elements[configKey] = InputFunc
                end
                RegisterSearch({ label = InputConfig.Title, tab = TabConfig.Name, kind = "Input", element = InputFunc, switch = SearchSwitch })
                return InputFunc
            end

            function Items:AddDropdown(DropdownConfig)
                local DropdownConfig = DropdownConfig or {}
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
                local DropdownButton = Instance.new("TextButton")
                local UICorner10 = Instance.new("UICorner")
                local DropdownTitle = Instance.new("TextLabel")
                local DropdownContent = Instance.new("TextLabel")
                local SelectOptionsFrame = Instance.new("Frame")
                local UICorner11 = Instance.new("UICorner")
                local OptionSelecting = Instance.new("TextLabel")
                local OptionImg = Instance.new("ImageLabel")

                Dropdown.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                Dropdown.BackgroundTransparency = 0.935
                Dropdown.BorderSizePixel = 0
                Dropdown.LayoutOrder = CountItem
                Dropdown.Size = UDim2.new(1, 0, 0, 46)
                Dropdown.Name = "Dropdown"
                Dropdown.Parent = SectionAdd

                DropdownButton.Text = ""
                DropdownButton.BackgroundTransparency = 1
                DropdownButton.Size = UDim2.new(1, 0, 1, 0)
                DropdownButton.Name = "ToggleButton"
                DropdownButton.Parent = Dropdown

                UICorner10.CornerRadius = UDim.new(0, 4)
                UICorner10.Parent = Dropdown

                DropdownTitle.Font = Enum.Font.GothamBold
                DropdownTitle.Text = DropdownConfig.Title
                DropdownTitle.TextColor3 = Color3.fromRGB(230, 230, 230)
                DropdownTitle.TextSize = 13
                DropdownTitle.TextXAlignment = Enum.TextXAlignment.Left
                DropdownTitle.BackgroundTransparency = 1
                DropdownTitle.Position = UDim2.new(0, 10, 0, 10)
                DropdownTitle.Size = UDim2.new(1, -180, 0, 13)
                DropdownTitle.Name = "DropdownTitle"
                DropdownTitle.Parent = Dropdown

                DropdownContent.Font = Enum.Font.GothamBold
                DropdownContent.Text = DropdownConfig.Content
                DropdownContent.TextColor3 = Color3.fromRGB(255, 255, 255)
                DropdownContent.TextSize = 12
                DropdownContent.TextTransparency = 0.6
                DropdownContent.TextWrapped = true
                DropdownContent.TextXAlignment = Enum.TextXAlignment.Left
                DropdownContent.BackgroundTransparency = 1
                DropdownContent.Position = UDim2.new(0, 10, 0, 25)
                DropdownContent.Size = UDim2.new(1, -180, 0, 12)
                DropdownContent.Name = "DropdownContent"
                DropdownContent.Parent = Dropdown

                SelectOptionsFrame.AnchorPoint = Vector2.new(1, 0.5)
                SelectOptionsFrame.BackgroundTransparency = 0.95
                SelectOptionsFrame.Position = UDim2.new(1, -7, 0.5, 0)
                SelectOptionsFrame.Size = UDim2.new(0, 148, 0, 30)
                SelectOptionsFrame.Name = "SelectOptionsFrame"
                SelectOptionsFrame.LayoutOrder = CountDropdown
                SelectOptionsFrame.Parent = Dropdown

                UICorner11.CornerRadius = UDim.new(0, 4)
                UICorner11.Parent = SelectOptionsFrame

                DropdownButton.Activated:Connect(function()
                    if not MoreBlur.Visible then
                        MoreBlur.Visible = true
                        DropPageLayout:JumpToIndex(SelectOptionsFrame.LayoutOrder)
                        TweenService:Create(MoreBlur, TweenInfo.new(0.3), { BackgroundTransparency = 1 }):Play()
                        TweenService:Create(DropdownSelect, TweenInfo.new(0.3), { Position = UDim2.new(1, -11, 0.5, 0) })
                            :Play()
                    end
                end)

                OptionSelecting.Font = Enum.Font.GothamBold
                OptionSelecting.Text = DropdownConfig.Multi and "Select Options" or "Select Option"
                OptionSelecting.TextColor3 = Color3.fromRGB(255, 255, 255)
                OptionSelecting.TextSize = 12
                OptionSelecting.TextTransparency = 0.6
                OptionSelecting.TextXAlignment = Enum.TextXAlignment.Left
                OptionSelecting.AnchorPoint = Vector2.new(0, 0.5)
                OptionSelecting.BackgroundTransparency = 1
                OptionSelecting.Position = UDim2.new(0, 5, 0.5, 0)
                OptionSelecting.Size = UDim2.new(1, -30, 1, -8)
                OptionSelecting.Name = "OptionSelecting"
                OptionSelecting.Parent = SelectOptionsFrame

                OptionImg.Image = "rbxassetid://16851841101"
                OptionImg.ImageColor3 = Color3.fromRGB(230, 230, 230)
                OptionImg.AnchorPoint = Vector2.new(1, 0.5)
                OptionImg.BackgroundTransparency = 1
                OptionImg.Position = UDim2.new(1, 0, 0.5, 0)
                OptionImg.Size = UDim2.new(0, 25, 0, 25)
                OptionImg.Name = "OptionImg"
                OptionImg.Parent = SelectOptionsFrame

                local DropdownContainer = Instance.new("Frame")
                DropdownContainer.Size = UDim2.new(1, 0, 1, 0)
                DropdownContainer.BackgroundTransparency = 1
                DropdownContainer.Parent = DropdownFolder

                local SearchBox = Instance.new("TextBox")
                SearchBox.PlaceholderText = "Search"
                SearchBox.Font = Enum.Font.Gotham
                SearchBox.Text = ""
                SearchBox.TextSize = 12
                SearchBox.TextColor3 = Color3.fromRGB(255, 255, 255)
                SearchBox.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
                SearchBox.BackgroundTransparency = 0.9
                SearchBox.BorderSizePixel = 0
                SearchBox.Size = UDim2.new(1, 0, 0, 25)
                SearchBox.Position = UDim2.new(0, 0, 0, 0)
                SearchBox.ClearTextOnFocus = false
                SearchBox.Name = "SearchBox"
                SearchBox.Parent = DropdownContainer

                local ScrollSelect = Instance.new("ScrollingFrame")
                ScrollSelect.Size = UDim2.new(1, 0, 1, -30)
                ScrollSelect.Position = UDim2.new(0, 0, 0, 30)
                ScrollSelect.ScrollBarImageTransparency = 1
                ScrollSelect.BorderSizePixel = 0
                ScrollSelect.BackgroundTransparency = 1
                ScrollSelect.ScrollBarThickness = 0
                ScrollSelect.CanvasSize = UDim2.new(0, 0, 0, 0)
                ScrollSelect.Name = "ScrollSelect"
                ScrollSelect.Parent = DropdownContainer

                local UIListLayout4 = Instance.new("UIListLayout")
                UIListLayout4.Padding = UDim.new(0, 3)
                UIListLayout4.SortOrder = Enum.SortOrder.LayoutOrder
                UIListLayout4.Parent = ScrollSelect

                UIListLayout4:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                    ScrollSelect.CanvasSize = UDim2.new(0, 0, 0, UIListLayout4.AbsoluteContentSize.Y)
                end)

                local dropdownSearchTicket = 0
                local function RunDropdownSearch()
                    local query = string.lower(SearchBox.Text)
                    for _, option in pairs(ScrollSelect:GetChildren()) do
                        if option.Name == "Option" and option:FindFirstChild("OptionText") then
                            local text = string.lower(option.OptionText.Text)
                            option.Visible = query == "" or string.find(text, query, 1, true)
                        end
                    end
                    ScrollSelect.CanvasSize = UDim2.new(0, 0, 0, UIListLayout4.AbsoluteContentSize.Y)
                end

                SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
                    dropdownSearchTicket = dropdownSearchTicket + 1
                    local ticket = dropdownSearchTicket
                    task.delay(0.08, function()
                        if ticket == dropdownSearchTicket then
                            RunDropdownSearch()
                        end
                    end)
                end)

                local DropCount = 0

                function DropdownFunc:Clear()
                    for _, DropFrame in ScrollSelect:GetChildren() do
                        if DropFrame.Name == "Option" then
                            DropFrame:Destroy()
                        end
                    end
                    DropdownFunc.Value = DropdownConfig.Multi and {} or nil
                    DropdownFunc.Options = {}
                    OptionSelecting.Text = DropdownConfig.Multi and "Select Options" or "Select Option"
                    DropCount = 0
                end

                function DropdownFunc:AddOption(option)
                    local label, value
                    if typeof(option) == "table" and option.Label and option.Value ~= nil then
                        label = tostring(option.Label)
                        value = option.Value
                    else
                        label = tostring(option)
                        value = option
                    end

                    local Option = Instance.new("Frame")
                    local OptionButton = Instance.new("TextButton")
                    local OptionText = Instance.new("TextLabel")
                    local ChooseFrame = Instance.new("Frame")
                    local UIStroke15 = Instance.new("UIStroke")
                    local UICorner38 = Instance.new("UICorner")
                    local UICorner37 = Instance.new("UICorner")

                    Option.BackgroundTransparency = 1
                    Option.Size = UDim2.new(1, 0, 0, 30)
                    Option.Name = "Option"
                    Option.Parent = ScrollSelect

                    UICorner37.CornerRadius = UDim.new(0, 3)
                    UICorner37.Parent = Option

                    OptionButton.BackgroundTransparency = 1
                    OptionButton.Size = UDim2.new(1, 0, 1, 0)
                    OptionButton.Text = ""
                    OptionButton.Name = "OptionButton"
                    OptionButton.Parent = Option

                    OptionText.Font = Enum.Font.GothamBold
                    OptionText.Text = label
                    OptionText.TextSize = 13
                    OptionText.TextColor3 = Color3.fromRGB(230, 230, 230)
                    OptionText.Position = UDim2.new(0, 8, 0, 8)
                    OptionText.Size = UDim2.new(1, -100, 0, 13)
                    OptionText.BackgroundTransparency = 1
                    OptionText.TextXAlignment = Enum.TextXAlignment.Left
                    OptionText.Name = "OptionText"
                    OptionText.Parent = Option

                    Option:SetAttribute("RealValue", value)

                    ChooseFrame.AnchorPoint = Vector2.new(0, 0.5)
                    ChooseFrame.BackgroundColor3 = GuiConfig.Color
                    ChooseFrame.Position = UDim2.new(0, 2, 0.5, 0)
                    ChooseFrame.Size = UDim2.new(0, 0, 0, 0)
                    ChooseFrame.Name = "ChooseFrame"
                    ChooseFrame.Parent = Option

                    UIStroke15.Color = GuiConfig.Color
                    UIStroke15.Thickness = 1.6
                    UIStroke15.Transparency = 0.999
                    UIStroke15.Parent = ChooseFrame
                    UICorner38.Parent = ChooseFrame

                    OptionButton.Activated:Connect(function()
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
                        end
                        DropdownFunc:Set(DropdownFunc.Value)
                    end)
                end

                function DropdownFunc:Set(Value, noSave)
                    task.spawn(function()
                        if DropdownConfig.Multi then
                            DropdownFunc.Value = type(Value) == "table" and Value or {}
                        else
                            DropdownFunc.Value = (type(Value) == "table" and Value[1]) or Value
                        end

                        if shouldSave then
                            ConfigData[configKey] = DropdownFunc.Value
                            if not noSave then QueueSaveConfig() end
                        end

                        local texts = {}
                        for _, Drop in ScrollSelect:GetChildren() do
                            if Drop.Name == "Option" and Drop:FindFirstChild("OptionText") then
                                local v = Drop:GetAttribute("RealValue")
                                local selected = DropdownConfig.Multi and table.find(DropdownFunc.Value, v) or
                                    DropdownFunc.Value == v

                                if selected then
                                    TweenService:Create(Drop.ChooseFrame, TweenInfo.new(0.2),
                                        { Size = UDim2.new(0, 1, 0, 12) }):Play()
                                    TweenService:Create(Drop.ChooseFrame.UIStroke, TweenInfo.new(0.2), { Transparency = 0 })
                                        :Play()
                                    TweenService:Create(Drop, TweenInfo.new(0.2), { BackgroundTransparency = 0.935 }):Play()
                                    table.insert(texts, Drop.OptionText.Text)
                                else
                                    TweenService:Create(Drop.ChooseFrame, TweenInfo.new(0.1),
                                        { Size = UDim2.new(0, 0, 0, 0) }):Play()
                                    TweenService:Create(Drop.ChooseFrame.UIStroke, TweenInfo.new(0.1),
                                        { Transparency = 0.999 }):Play()
                                    TweenService:Create(Drop, TweenInfo.new(0.1), { BackgroundTransparency = 0.999 }):Play()
                                end
                            end
                        end

                        OptionSelecting.Text = (#texts == 0)
                            and (DropdownConfig.Multi and "Select Options" or "Select Option")
                            or table.concat(texts, ", ")

                        if DropdownConfig.Callback then
                            if DropdownConfig.Multi then
                                DropdownConfig.Callback(DropdownFunc.Value)
                            else
                                local str = (DropdownFunc.Value ~= nil) and tostring(DropdownFunc.Value) or ""
                                DropdownConfig.Callback(str)
                            end
                        end
                    end)
                end

                function DropdownFunc:SetValue(val)
                    self:Set(val)
                end

                function DropdownFunc:GetValue()
                    return self.Value
                end

                function DropdownFunc:SetValues(newList, selecting, noSave)
                    newList = newList or {}
                    selecting = selecting or (DropdownConfig.Multi and {} or nil)
                    DropdownFunc:Clear()
                    for _, v in ipairs(newList) do
                        DropdownFunc:AddOption(v)
                    end
                    DropdownFunc:Set(selecting, noSave)
                    DropdownFunc.Options = newList
                end

                DropdownFunc:SetValues(DropdownFunc.Options, DropdownFunc.Value, true)

                CountItem = CountItem + 1
                CountDropdown = CountDropdown + 1
                if shouldSave then
                    Elements[configKey] = DropdownFunc
                end
                RegisterSearch({ label = DropdownConfig.Title, tab = TabConfig.Name, kind = "Dropdown", element = DropdownFunc, switch = SearchSwitch })
                return DropdownFunc
            end

            function Items:AddConfig(ConfigCfg)
                ConfigCfg = ConfigCfg or {}

                local autoName = GuiFunc:GetAutoLoad()
                local currentName = ""
                local importJson = ""
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
                    SubCallback = function()
                        RefreshList()
                    end,
                })

                local AutoToggle
                local initializingAutoToggle = true
                AutoToggle = Items:AddToggle({
                    Title    = "Auto Load",
                    Content  = autoName ~= "" and ("Auto: " .. autoName) or "Load selected on startup",
                    Default  = autoName ~= "",
                    Save     = false,
                    Callback = function(value)
                        if initializingAutoToggle then return end
                        if value and selectedConfig then
                            GuiFunc:SetAutoLoad(selectedConfig)
                            than("Auto load set to '" .. selectedConfig .. "'", 4, GuiConfig.Color, "HydraHub", "Config")
                        elseif value then
                            GuiFunc:SetAutoLoad("")
                            if AutoToggle then AutoToggle:Set(false, true) end
                            than("Select a config first", 4, Color3.fromRGB(255, 170, 0), "HydraHub", "Config")
                        else
                            GuiFunc:SetAutoLoad("")
                        end
                    end,
                })
                initializingAutoToggle = false

                local ImportInput = Items:AddInput({
                    Title       = "Import JSON",
                    Content     = "Paste exported config",
                    Placeholder = "{...}",
                    Save        = false,
                    Callback    = function(text) importJson = text end,
                })

                Items:AddButton({
                    Title    = "Import JSON",
                    SubTitle = "Import from Clipboard",
                    Callback = function()
                        if GuiFunc:ImportConfig(importJson) then
                            RefreshList()
                        end
                    end,
                    SubCallback = function()
                        local clip = (getclipboard and getclipboard()) or ""
                        if GuiFunc:ImportConfig(clip) then
                            RefreshList()
                        end
                    end,
                })

                Items:AddButton({
                    Title    = "Export to Clipboard",
                    Callback = function()
                        GuiFunc:ExportConfig()
                    end,
                })

                return { Refresh = RefreshList }
            end

            function Items:AddBanner(BannerConfig)
                BannerConfig = BannerConfig or {}
                local asset = tostring(BannerConfig.Image or BannerConfig.Banner or "")
                if asset ~= "" and not string.find(asset, "rbxassetid://") then
                    asset = "rbxassetid://" .. asset
                end

                local ratio = BannerConfig.AspectRatio or (16 / 5)

                local Banner = Instance.new("Frame")
                Banner.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
                Banner.BackgroundTransparency = 0.2
                Banner.BorderSizePixel = 0
                Banner.ClipsDescendants = true
                Banner.LayoutOrder = CountItem
                Banner.Size = UDim2.new(1, 0, 0, 110)
                Banner.Name = "Banner"
                Banner.Parent = SectionAdd

                local BannerCorner = Instance.new("UICorner")
                BannerCorner.CornerRadius = UDim.new(0, 8)
                BannerCorner.Parent = Banner

                local function FitHeight()
                    local w = Banner.AbsoluteSize.X
                    if w > 0 then
                        local h = math.floor(w / ratio)
                        if math.abs(Banner.Size.Y.Offset - h) > 1 then
                            Banner.Size = UDim2.new(1, 0, 0, h)
                            UpdateSizeSection()
                        end
                    end
                end

                if asset ~= "" then
                    local Img = Instance.new("ImageLabel")
                    Img.Image = asset
                    Img.BackgroundTransparency = 1
                    Img.ScaleType = Enum.ScaleType.Crop
                    Img.Size = UDim2.new(1, 0, 1, 0)
                    Img.Name = "BannerImage"
                    Img.Parent = Banner
                else
                    local Grad = Instance.new("UIGradient")
                    Grad.Color = ColorSequence.new {
                        ColorSequenceKeypoint.new(0, Color3.fromRGB(20, 20, 20)),
                        ColorSequenceKeypoint.new(0.5, GuiConfig.Color),
                        ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 20, 20))
                    }
                    Grad.Rotation = 25
                    Grad.Parent = Banner
                end

                if BannerConfig.Version then
                    local VerPill = Instance.new("Frame")
                    VerPill.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                    VerPill.BackgroundTransparency = 0.35
                    VerPill.BorderSizePixel = 0
                    VerPill.AnchorPoint = Vector2.new(1, 0)
                    VerPill.Position = UDim2.new(1, -8, 0, 8)
                    VerPill.Size = UDim2.new(0, 52, 0, 20)
                    VerPill.ZIndex = 3
                    VerPill.Name = "VersionPill"
                    VerPill.Parent = Banner

                    local VerCorner = Instance.new("UICorner")
                    VerCorner.CornerRadius = UDim.new(0, 10)
                    VerCorner.Parent = VerPill

                    local VerLabel = Instance.new("TextLabel")
                    VerLabel.Font = Enum.Font.GothamBold
                    VerLabel.Text = tostring(BannerConfig.Version)
                    VerLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                    VerLabel.TextSize = 10
                    VerLabel.BackgroundTransparency = 1
                    VerLabel.Size = UDim2.new(1, 0, 1, 0)
                    VerLabel.ZIndex = 4
                    VerLabel.Parent = VerPill
                end

                Banner:GetPropertyChangedSignal("AbsoluteSize"):Connect(FitHeight)
                task.spawn(function()
                    task.wait()
                    FitHeight()
                end)

                CountItem = CountItem + 1
                return Banner
            end

            function Items:AddCard(CardConfig)
                CardConfig = CardConfig or {}
                CardConfig.Title = CardConfig.Title or "Card"
                CardConfig.Description = CardConfig.Description or ""
                local btns = CardConfig.Buttons or {}
                local cardHeight = 70 + (#btns > 0 and 40 or 0)

                local Card = Instance.new("Frame")
                Card.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                Card.BackgroundTransparency = 0.935
                Card.BorderSizePixel = 0
                Card.LayoutOrder = CountItem
                Card.Size = UDim2.new(1, 0, 0, cardHeight)
                Card.Name = "Card"
                Card.Parent = SectionAdd

                local CardCorner = Instance.new("UICorner")
                CardCorner.CornerRadius = UDim.new(0, 6)
                CardCorner.Parent = Card

                local cx = 12
                if CardConfig.Logo and CardConfig.Logo ~= "" then
                    local logo = tostring(CardConfig.Logo)
                    if not string.find(logo, "rbxassetid://") then logo = "rbxassetid://" .. logo end
                    local Logo = Instance.new("ImageLabel")
                    Logo.Image = logo
                    Logo.BackgroundTransparency = 1
                    Logo.ScaleType = Enum.ScaleType.Fit
                    Logo.Position = UDim2.new(0, 12, 0, 14)
                    Logo.Size = UDim2.new(0, 32, 0, 32)
                    Logo.Parent = Card
                    cx = 52
                end

                local CardTitle = Instance.new("TextLabel")
                CardTitle.Font = Enum.Font.GothamBold
                CardTitle.Text = CardConfig.Title
                CardTitle.TextColor3 = Color3.fromRGB(235, 235, 235)
                CardTitle.TextSize = 13
                CardTitle.TextXAlignment = Enum.TextXAlignment.Left
                CardTitle.BackgroundTransparency = 1
                CardTitle.Position = UDim2.new(0, cx, 0, 12)
                CardTitle.Size = UDim2.new(1, -cx - 12, 0, 16)
                CardTitle.Parent = Card

                local CardDesc = Instance.new("TextLabel")
                CardDesc.Font = Enum.Font.Gotham
                CardDesc.Text = CardConfig.Description
                CardDesc.TextColor3 = Color3.fromRGB(180, 180, 180)
                CardDesc.TextSize = 11
                CardDesc.TextXAlignment = Enum.TextXAlignment.Left
                CardDesc.TextYAlignment = Enum.TextYAlignment.Top
                CardDesc.TextWrapped = true
                CardDesc.BackgroundTransparency = 1
                CardDesc.Position = UDim2.new(0, cx, 0, 30)
                CardDesc.Size = UDim2.new(1, -cx - 12, 0, 28)
                CardDesc.Parent = Card

                if #btns > 0 then
                    local Row = Instance.new("Frame")
                    Row.BackgroundTransparency = 1
                    Row.Position = UDim2.new(0, 8, 0, cardHeight - 38)
                    Row.Size = UDim2.new(1, -16, 0, 30)
                    Row.Parent = Card

                    local RowLayout = Instance.new("UIListLayout")
                    RowLayout.FillDirection = Enum.FillDirection.Horizontal
                    RowLayout.Padding = UDim.new(0, 6)
                    RowLayout.Parent = Row

                    local bw = (#btns == 1) and UDim2.new(1, 0, 1, 0) or UDim2.new(0.5, -3, 1, 0)
                    for _, bd in ipairs(btns) do
                        local Btn = Instance.new("TextButton")
                        Btn.Font = Enum.Font.GothamBold
                        Btn.Text = bd.Name or "Button"
                        Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
                        Btn.TextSize = 11
                        Btn.TextTransparency = 0.2
                        Btn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                        Btn.BackgroundTransparency = 0.9
                        Btn.BorderSizePixel = 0
                        Btn.Size = bw
                        Btn.Parent = Row

                        local BtnCorner = Instance.new("UICorner")
                        BtnCorner.CornerRadius = UDim.new(0, 6)
                        BtnCorner.Parent = Btn

                        if bd.Callback then
                            Btn.MouseButton1Click:Connect(bd.Callback)
                        end
                    end
                end

                RegisterSearch({ label = CardConfig.Title, tab = TabConfig.Name, kind = "Card", switch = SearchSwitch })
                CountItem = CountItem + 1
                return Card
            end

            function Items:AddDivider()
                local Divider = Instance.new("Frame")
                Divider.Name = "Divider"
                Divider.Parent = SectionAdd
                Divider.AnchorPoint = Vector2.new(0.5, 0)
                Divider.Position = UDim2.new(0.5, 0, 0, 0)
                Divider.Size = UDim2.new(1, 0, 0, 2)
                Divider.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                Divider.BackgroundTransparency = 0
                Divider.BorderSizePixel = 0
                Divider.LayoutOrder = CountItem

                local UIGradient = Instance.new("UIGradient")
                UIGradient.Color = ColorSequence.new {
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(20, 20, 20)),
                    ColorSequenceKeypoint.new(0.5, GuiConfig.Color),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 20, 20))
                }
                UIGradient.Parent = Divider

                local UICorner = Instance.new("UICorner")
                UICorner.CornerRadius = UDim.new(0, 2)
                UICorner.Parent = Divider

                CountItem = CountItem + 1
                return Divider
            end

        

function Items:AddMailQueue(MailConfig)
    MailConfig = MailConfig or {}
    MailConfig.Title = MailConfig.Title or "Mail Targets"
    MailConfig.Placeholder = MailConfig.Placeholder or "Type username"
    MailConfig.Categories = MailConfig.Categories or {}
        -- Categories = { { Key = "Seeds", Options = {"Carrot","Wheat"} }, ... }

    MailConfig.OnAddTarget = MailConfig.OnAddTarget or function(username) end
    MailConfig.OnRemoveTarget = MailConfig.OnRemoveTarget or function(username) end
    MailConfig.OnSetActiveTarget = MailConfig.OnSetActiveTarget or function(username) end

    MailConfig.OnAddFromInventory = MailConfig.OnAddFromInventory or function(categoryKey) end
    MailConfig.OnGetInventoryItems = MailConfig.OnGetInventoryItems or function(categoryKey) return {} end
    MailConfig.OnQuantityChange = MailConfig.OnQuantityChange or function(categoryKey, itemName, newQty) end
    MailConfig.OnRemoveItem = MailConfig.OnRemoveItem or function(categoryKey, itemName) end

    MailConfig.OnSaveConfig = MailConfig.OnSaveConfig or function() end
    MailConfig.OnLoadConfig = MailConfig.OnLoadConfig or function() end
    MailConfig.OnAutoSendToggle = MailConfig.OnAutoSendToggle or function(state) end
    MailConfig.OnIntervalChange = MailConfig.OnIntervalChange or function(hours) end

    local configKey = "MailQueue_" .. MailConfig.Title
    local shouldSave = MailConfig.Save ~= false

    -- persisted state: { Targets = {name=..}, ActiveTarget = name,
    --                    Categories = { [Key] = { {Name=.., Qty=..}, ... } },
    --                    AutoSend = bool, IntervalHours = n }
    local State = {
        Targets = {},
        ActiveTarget = nil,
        CategoryItems = {},
        AutoSend = false,
        IntervalHours = 6,
        KnownUsernames = {},
    }
    if shouldSave and ConfigData[configKey] ~= nil and type(ConfigData[configKey]) == "table" then
        local saved = ConfigData[configKey]
        State.Targets = saved.Targets or {}
        State.ActiveTarget = saved.ActiveTarget
        State.CategoryItems = saved.CategoryItems or {}
        State.AutoSend = saved.AutoSend or false
        State.IntervalHours = saved.IntervalHours or 6
        State.KnownUsernames = saved.KnownUsernames or {}
    end

    local MailFunc = { Value = State }

    local function Persist(noSave)
        if not shouldSave then return end
        ConfigData[configKey] = State
        if not noSave then QueueSaveConfig() end
    end

    function MailFunc:Set(newState, noSave)
        if type(newState) ~= "table" then return end

        State.Targets = newState.Targets or {}
        State.ActiveTarget = newState.ActiveTarget
        State.CategoryItems = newState.CategoryItems or {}
        State.AutoSend = newState.AutoSend or false
        State.IntervalHours = newState.IntervalHours or 6
        State.KnownUsernames = newState.KnownUsernames or {}

        MailFunc:RefreshTargets()
        for _, cat in pairs(MailFunc.Categories) do
            cat:Refresh()
        end

        SwitchBg.BackgroundColor3 = State.AutoSend and GuiConfig.Color or Color3.fromRGB(255, 255, 255)
        SwitchBg.BackgroundTransparency = State.AutoSend and 0 or 0.92
        SwitchDot.AnchorPoint = Vector2.new(State.AutoSend and 1 or 0, 0.5)
        SwitchDot.Position = UDim2.new(State.AutoSend and 1 or 0, 0, 0.5, 0)
        IntLabel.Text = State.IntervalHours .. " hours"

        if not noSave then Persist() end
    end

  
    local Root = Instance.new("Frame")
    Root.BackgroundTransparency = 1
    Root.LayoutOrder = CountItem
    Root.Name = "MailQueue"
    Root.Parent = SectionAdd

    local RootList = Instance.new("UIListLayout")
    RootList.Padding = UDim.new(0, 6)
    RootList.SortOrder = Enum.SortOrder.LayoutOrder
    RootList.Parent = Root

    local function ResizeRoot()
        task.defer(function()
            local h = 0
            for _, c in Root:GetChildren() do
                if c:IsA("GuiObject") then
                    h = h + c.Size.Y.Offset + 6
                end
            end
            Root.Size = UDim2.new(1, 0, 0, h)
            UpdateSizeSection()
        end)
    end

   
    local function MakeIconButton(parent, text, w, color)
        local Btn = Instance.new("TextButton")
        Btn.Font = Enum.Font.GothamBold
        Btn.Text = text
        Btn.TextSize = 12
        Btn.TextColor3 = color or Color3.fromRGB(255, 255, 255)
        Btn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        Btn.BackgroundTransparency = 0.94
        Btn.Size = UDim2.new(0, w, 0, 20)
        Btn.Parent = parent
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, 4)
        c.Parent = Btn
        return Btn
    end

 
 
    local TargetsBlock = Instance.new("Frame")
    TargetsBlock.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    TargetsBlock.BackgroundTransparency = 0.965
    TargetsBlock.Size = UDim2.new(1, 0, 0, 40)
    TargetsBlock.LayoutOrder = 1
    TargetsBlock.Name = "TargetsBlock"
    TargetsBlock.Parent = Root

    local TargetsCorner = Instance.new("UICorner")
    TargetsCorner.CornerRadius = UDim.new(0, 6)
    TargetsCorner.Parent = TargetsBlock

    local TargetsPad = Instance.new("UIPadding")
    TargetsPad.PaddingTop = UDim.new(0, 8)
    TargetsPad.PaddingBottom = UDim.new(0, 8)
    TargetsPad.PaddingLeft = UDim.new(0, 8)
    TargetsPad.PaddingRight = UDim.new(0, 8)
    TargetsPad.Parent = TargetsBlock

    local TargetsList = Instance.new("UIListLayout")
    TargetsList.Padding = UDim.new(0, 6)
    TargetsList.SortOrder = Enum.SortOrder.LayoutOrder
    TargetsList.Parent = TargetsBlock

    local TargetsTitle = Instance.new("TextLabel")
    TargetsTitle.Font = Enum.Font.GothamBold
    TargetsTitle.Text = MailConfig.Title
    TargetsTitle.TextColor3 = GuiConfig.Color
    TargetsTitle.TextSize = 13
    TargetsTitle.TextXAlignment = Enum.TextXAlignment.Left
    TargetsTitle.BackgroundTransparency = 1
    TargetsTitle.Size = UDim2.new(1, 0, 0, 14)
    TargetsTitle.LayoutOrder = 0
    TargetsTitle.Parent = TargetsBlock

    local ResizeTargetsBlockOuter

    local InputRow = Instance.new("Frame")
    InputRow.BackgroundTransparency = 1
    InputRow.Size = UDim2.new(1, 0, 0, 26)
    InputRow.LayoutOrder = 1
    InputRow.Parent = TargetsBlock

    local UsernameBox = Instance.new("TextBox")
    UsernameBox.Font = Enum.Font.GothamBold
    UsernameBox.PlaceholderText = MailConfig.Placeholder
    UsernameBox.PlaceholderColor3 = Color3.fromRGB(120, 120, 120)
    UsernameBox.Text = ""
    UsernameBox.TextSize = 12
    UsernameBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    UsernameBox.TextXAlignment = Enum.TextXAlignment.Left
    UsernameBox.ClearTextOnFocus = false
    UsernameBox.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    UsernameBox.BackgroundTransparency = 0.94
    UsernameBox.Size = UDim2.new(1, -58, 1, 0)
    UsernameBox.Parent = InputRow

    local UsernameBoxPad = Instance.new("UIPadding")
    UsernameBoxPad.PaddingLeft = UDim.new(0, 8)
    UsernameBoxPad.Parent = UsernameBox

    local UsernameBoxCorner = Instance.new("UICorner")
    UsernameBoxCorner.CornerRadius = UDim.new(0, 4)
    UsernameBoxCorner.Parent = UsernameBox

    local SavedUserBtn = Instance.new("TextButton")
    SavedUserBtn.Text = ""
    SavedUserBtn.AnchorPoint = Vector2.new(1, 0)
    SavedUserBtn.Position = UDim2.new(1, -30, 0, 0)
    SavedUserBtn.BackgroundColor3 = GuiConfig.Color
    SavedUserBtn.BackgroundTransparency = 0.88
    SavedUserBtn.Size = UDim2.new(0, 24, 1, 0)
    SavedUserBtn.Parent = InputRow

    local SavedUserCorner = Instance.new("UICorner")
    SavedUserCorner.CornerRadius = UDim.new(0, 4)
    SavedUserCorner.Parent = SavedUserBtn

    local SavedUserIcon = Instance.new("ImageLabel")
    SavedUserIcon.Image = "rbxassetid://108483430622128"
    SavedUserIcon.ImageColor3 = GuiConfig.Color
    SavedUserIcon.BackgroundTransparency = 1
    SavedUserIcon.ScaleType = Enum.ScaleType.Fit
    SavedUserIcon.AnchorPoint = Vector2.new(0.5, 0.5)
    SavedUserIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
    SavedUserIcon.Size = UDim2.new(0, 16, 0, 16)
    SavedUserIcon.Parent = SavedUserBtn

    local AddTargetBtn = Instance.new("TextButton")
    AddTargetBtn.Font = Enum.Font.GothamBold
    AddTargetBtn.Text = "+"
    AddTargetBtn.TextSize = 16
    AddTargetBtn.TextColor3 = GuiConfig.Color
    AddTargetBtn.AnchorPoint = Vector2.new(1, 0)
    AddTargetBtn.Position = UDim2.new(1, 0, 0, 0)
    AddTargetBtn.BackgroundColor3 = GuiConfig.Color
    AddTargetBtn.BackgroundTransparency = 0.88
    AddTargetBtn.Size = UDim2.new(0, 26, 1, 0)
    AddTargetBtn.Parent = InputRow

    local AddTargetCorner = Instance.new("UICorner")
    AddTargetCorner.CornerRadius = UDim.new(0, 4)
    AddTargetCorner.Parent = AddTargetBtn

    local SavedUserPicker = Instance.new("Frame")
    SavedUserPicker.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    SavedUserPicker.BackgroundTransparency = 0.1
    SavedUserPicker.Size = UDim2.new(1, 0, 0, 0)
    SavedUserPicker.ClipsDescendants = true
    SavedUserPicker.Visible = false
    SavedUserPicker.LayoutOrder = 2
    SavedUserPicker.Name = "SavedUserPicker"
    SavedUserPicker.Parent = TargetsBlock
    local SavedUserPickerCorner = Instance.new("UICorner")
    SavedUserPickerCorner.CornerRadius = UDim.new(0, 4)
    SavedUserPickerCorner.Parent = SavedUserPicker
    local SavedUserPickerLayout = Instance.new("UIListLayout")
    SavedUserPickerLayout.SortOrder = Enum.SortOrder.LayoutOrder
    SavedUserPickerLayout.Parent = SavedUserPicker

    local function RefreshSavedUserPicker()
        for _, c in ipairs(SavedUserPicker:GetChildren()) do
            if c:IsA("GuiObject") then c:Destroy() end
        end
        for _, uname in ipairs(State.KnownUsernames) do
            local OptBtn = Instance.new("TextButton")
            OptBtn.Font = Enum.Font.GothamBold
            OptBtn.Text = uname
            OptBtn.TextSize = 11
            OptBtn.TextColor3 = Color3.fromRGB(220, 220, 220)
            OptBtn.TextXAlignment = Enum.TextXAlignment.Left
            OptBtn.BackgroundTransparency = 1
            OptBtn.Size = UDim2.new(1, 0, 0, 24)
            OptBtn.Parent = SavedUserPicker
            local OptPad = Instance.new("UIPadding")
            OptPad.PaddingLeft = UDim.new(0, 8)
            OptPad.Parent = OptBtn

            OptBtn.Activated:Connect(function()
                UsernameBox.Text = uname
                SavedUserPicker.Visible = false
                SavedUserPicker.Size = UDim2.new(1, 0, 0, 0)
                ResizeTargetsBlockOuter()
            end)
        end
    end

    SavedUserBtn.Activated:Connect(function()
        CircleClick(SavedUserBtn, Mouse.X, Mouse.Y)
        RefreshSavedUserPicker()
        SavedUserPicker.Visible = not SavedUserPicker.Visible
        if SavedUserPicker.Visible then
            SavedUserPicker.Size = UDim2.new(1, 0, 0, #State.KnownUsernames * 24)
        else
            SavedUserPicker.Size = UDim2.new(1, 0, 0, 0)
        end
        ResizeTargetsBlockOuter()
    end)

    local TargetListFrame = Instance.new("Frame")
    TargetListFrame.BackgroundTransparency = 1
    TargetListFrame.Size = UDim2.new(1, 0, 0, 0)
    TargetListFrame.LayoutOrder = 3
    TargetListFrame.Name = "TargetListFrame"
    TargetListFrame.Parent = TargetsBlock

    local TargetListLayout = Instance.new("UIListLayout")
    TargetListLayout.Padding = UDim.new(0, 4)
    TargetListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    TargetListLayout.Parent = TargetListFrame

    local function ResizeTargetsBlock()
        task.defer(function()
            local rowsH = 0
            for _, c in TargetListFrame:GetChildren() do
                if c:IsA("GuiObject") then rowsH = rowsH + c.Size.Y.Offset + 4 end
            end
            TargetListFrame.Size = UDim2.new(1, 0, 0, rowsH)
            local pickerH = SavedUserPicker.Visible and SavedUserPicker.Size.Y.Offset or 0
            TargetsBlock.Size = UDim2.new(1, 0, 0, 16 + 14 + 6 + 26 + 6 + pickerH + rowsH)
            ResizeRoot()
        end)
    end
    ResizeTargetsBlockOuter = ResizeTargetsBlock

    local targetRows = {}

    local function RenderTargetRow(username)
        local isActive = State.ActiveTarget == username

        local Row = Instance.new("Frame")
        Row.BackgroundColor3 = isActive and GuiConfig.Color or Color3.fromRGB(255, 255, 255)
        Row.BackgroundTransparency = isActive and 0.88 or 0.965
        Row.Size = UDim2.new(1, 0, 0, 30)
        Row.Name = "TargetRow"
        Row.Parent = TargetListFrame

        local RowCorner = Instance.new("UICorner")
        RowCorner.CornerRadius = UDim.new(0, 4)
        RowCorner.Parent = Row

        local Dot = Instance.new("Frame")
        Dot.AnchorPoint = Vector2.new(0, 0.5)
        Dot.Position = UDim2.new(0, 8, 0.5, 0)
        Dot.Size = UDim2.new(0, 8, 0, 8)
        Dot.BackgroundColor3 = isActive and GuiConfig.Color or Color3.fromRGB(120, 120, 120)
        Dot.BackgroundTransparency = isActive and 0 or 1
        if not isActive then
            local Stroke = Instance.new("UIStroke")
            Stroke.Color = Color3.fromRGB(120, 120, 120)
            Stroke.Thickness = 1
            Stroke.Parent = Dot
        end
        Dot.Parent = Row
        local DotCorner = Instance.new("UICorner")
        DotCorner.CornerRadius = UDim.new(1, 0)
        DotCorner.Parent = Dot

        local Avatar = Instance.new("ImageLabel")
        Avatar.AnchorPoint = Vector2.new(0, 0.5)
        Avatar.Position = UDim2.new(0, 22, 0.5, 0)
        Avatar.Size = UDim2.new(0, 20, 0, 20)
        Avatar.BackgroundColor3 = Color3.fromRGB(58, 74, 122)
        Avatar.Parent = Row
        local AvatarCorner = Instance.new("UICorner")
        AvatarCorner.CornerRadius = UDim.new(1, 0)
        AvatarCorner.Parent = Avatar

        task.spawn(function()
            local Players = game:GetService("Players")
            local ok, userId = pcall(function()
                return Players:GetUserIdFromNameAsync(username)
            end)
            if ok and userId then
                local ok2, content = pcall(function()
                    return Players:GetUserThumbnailAsync(
                        userId,
                        Enum.ThumbnailType.HeadShot,
                        Enum.ThumbnailSize.Size48x48
                    )
                end)
                if ok2 and content and Avatar.Parent then
                    Avatar.Image = content
                end
            end
        end)

        local NameLbl = Instance.new("TextLabel")
        NameLbl.Font = Enum.Font.GothamBold
        NameLbl.Text = username
        NameLbl.TextColor3 = isActive and GuiConfig.Color or Color3.fromRGB(230, 230, 230)
        NameLbl.TextSize = 12
        NameLbl.TextXAlignment = Enum.TextXAlignment.Left
        NameLbl.BackgroundTransparency = 1
        NameLbl.Position = UDim2.new(0, 48, 0, 3)
        NameLbl.Size = UDim2.new(1, -80, 0, 12)
        NameLbl.Parent = Row

        local SubLbl = Instance.new("TextLabel")
        SubLbl.Font = Enum.Font.Gotham
        SubLbl.Text = isActive and "active target" or ""
        SubLbl.TextColor3 = GuiConfig.Color
        SubLbl.TextTransparency = 0.2
        SubLbl.TextSize = 10
        SubLbl.TextXAlignment = Enum.TextXAlignment.Left
        SubLbl.BackgroundTransparency = 1
        SubLbl.Position = UDim2.new(0, 48, 0, 15)
        SubLbl.Size = UDim2.new(1, -80, 0, 10)
        SubLbl.Parent = Row

        local RowClick = Instance.new("TextButton")
        RowClick.Text = ""
        RowClick.BackgroundTransparency = 1
        RowClick.Size = UDim2.new(1, -26, 1, 0)
        RowClick.Parent = Row

        local RemoveBtn = Instance.new("TextButton")
        RemoveBtn.Font = Enum.Font.GothamBold
        RemoveBtn.Text = "x"
        RemoveBtn.TextColor3 = Color3.fromRGB(255, 107, 107)
        RemoveBtn.TextSize = 12
        RemoveBtn.AnchorPoint = Vector2.new(1, 0.5)
        RemoveBtn.Position = UDim2.new(1, -6, 0.5, 0)
        RemoveBtn.BackgroundColor3 = Color3.fromRGB(226, 75, 74)
        RemoveBtn.BackgroundTransparency = 0.88
        RemoveBtn.Size = UDim2.new(0, 18, 0, 18)
        RemoveBtn.Parent = Row
        local RemoveCorner = Instance.new("UICorner")
        RemoveCorner.CornerRadius = UDim.new(0, 3)
        RemoveCorner.Parent = RemoveBtn

        RowClick.Activated:Connect(function()
            State.ActiveTarget = username
            Persist()
            MailConfig.OnSetActiveTarget(username)
            MailFunc:RefreshTargets()
        end)

        RemoveBtn.Activated:Connect(function()
            CircleClick(RemoveBtn, Mouse.X, Mouse.Y)
            for i, v in ipairs(State.Targets) do
                if v == username then
                    table.remove(State.Targets, i)
                    break
                end
            end
            if State.ActiveTarget == username then
                State.ActiveTarget = State.Targets[1]
            end
            Persist()
            MailConfig.OnRemoveTarget(username)
            MailFunc:RefreshTargets()
        end)

        return Row
    end

    function MailFunc:RefreshTargets()
        for _, r in ipairs(targetRows) do
            if r and r.Parent then r:Destroy() end
        end
        targetRows = {}
        for _, username in ipairs(State.Targets) do
            table.insert(targetRows, RenderTargetRow(username))
        end
        ResizeTargetsBlock()
    end

    AddTargetBtn.Activated:Connect(function()
        CircleClick(AddTargetBtn, Mouse.X, Mouse.Y)
        local username = UsernameBox.Text
        if username == "" then return end
        for _, v in ipairs(State.Targets) do
            if v == username then
                than("That target is already in the list", 3, Color3.fromRGB(255, 170, 0), "HydraHub", "Mail")
                return
            end
        end
        table.insert(State.Targets, username)
        if not table.find(State.KnownUsernames, username) then
            table.insert(State.KnownUsernames, username)
        end
        if not State.ActiveTarget then State.ActiveTarget = username end
        UsernameBox.Text = ""
        Persist()
        MailConfig.OnAddTarget(username)
        MailFunc:RefreshTargets()
    end)

    MailFunc:RefreshTargets()

  
    -- SECTION 2: category queues (Seeds / Eggs / Pets / Gear / ...)
   
    local Divider = Instance.new("Frame")
    Divider.Size = UDim2.new(1, 0, 0, 1)
    Divider.BorderSizePixel = 0
    Divider.LayoutOrder = 2
    Divider.Parent = Root
    local DividerGrad = Instance.new("UIGradient")
    DividerGrad.Color = ColorSequence.new {
        ColorSequenceKeypoint.new(0, Color3.fromRGB(20, 20, 20)),
        ColorSequenceKeypoint.new(0.5, GuiConfig.Color),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 20, 20)),
    }
    DividerGrad.Parent = Divider

    MailFunc.Categories = {}

    local categoryOrder = 3
    for _, catDef in ipairs(MailConfig.Categories) do
        categoryOrder = categoryOrder + 1
        local catKey = catDef.Key or "Category"
        local catOptions = catDef.Options or {}

        if not State.CategoryItems[catKey] then
            State.CategoryItems[catKey] = {}
        end

        local CatBlock = Instance.new("Frame")
        CatBlock.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        CatBlock.BackgroundTransparency = 0.965
        CatBlock.Size = UDim2.new(1, 0, 0, 40)
        CatBlock.LayoutOrder = categoryOrder
        CatBlock.Name = "Cat_" .. catKey
        CatBlock.Parent = Root

        local CatCorner = Instance.new("UICorner")
        CatCorner.CornerRadius = UDim.new(0, 6)
        CatCorner.Parent = CatBlock

        local CatPad = Instance.new("UIPadding")
        CatPad.PaddingTop = UDim.new(0, 8)
        CatPad.PaddingBottom = UDim.new(0, 8)
        CatPad.PaddingLeft = UDim.new(0, 8)
        CatPad.PaddingRight = UDim.new(0, 8)
        CatPad.Parent = CatBlock

        local CatList = Instance.new("UIListLayout")
        CatList.Padding = UDim.new(0, 6)
        CatList.SortOrder = Enum.SortOrder.LayoutOrder
        CatList.Parent = CatBlock

        local CatTitle = Instance.new("TextLabel")
        CatTitle.Font = Enum.Font.GothamBold
        CatTitle.Text = catKey
        CatTitle.TextColor3 = GuiConfig.Color
        CatTitle.TextSize = 13
        CatTitle.TextXAlignment = Enum.TextXAlignment.Left
        CatTitle.BackgroundTransparency = 1
        CatTitle.Size = UDim2.new(1, 0, 0, 14)
        CatTitle.LayoutOrder = 0
        CatTitle.Parent = CatBlock

        local CatBtnRow = Instance.new("Frame")
        CatBtnRow.BackgroundTransparency = 1
        CatBtnRow.Size = UDim2.new(1, 0, 0, 24)
        CatBtnRow.LayoutOrder = 1
        CatBtnRow.Parent = CatBlock

        local CatBtnLayout = Instance.new("UIListLayout")
        CatBtnLayout.FillDirection = Enum.FillDirection.Horizontal
        CatBtnLayout.Padding = UDim.new(0, 6)
        CatBtnLayout.Parent = CatBtnRow

        local AddFromListBtn = MakeIconButton(CatBtnRow, "Add from list", 0, nil)
        AddFromListBtn.Size = UDim2.new(0.5, -3, 1, 0)
        local AddFromInvBtn = MakeIconButton(CatBtnRow, "Add from inventory", 0, nil)
        AddFromInvBtn.Size = UDim2.new(0.5, -3, 1, 0)

        local ItemListFrame = Instance.new("Frame")
        ItemListFrame.BackgroundTransparency = 1
        ItemListFrame.Size = UDim2.new(1, 0, 0, 0)
        ItemListFrame.LayoutOrder = 2
        ItemListFrame.Parent = CatBlock

        local ItemListLayout = Instance.new("UIListLayout")
        ItemListLayout.Padding = UDim.new(0, 4)
        ItemListLayout.SortOrder = Enum.SortOrder.LayoutOrder
        ItemListLayout.Parent = ItemListFrame

        local function ResizeCatBlock()
            task.defer(function()
                local rowsH = 0
                for _, c in ItemListFrame:GetChildren() do
                    if c:IsA("GuiObject") then rowsH = rowsH + c.Size.Y.Offset + 4 end
                end
                ItemListFrame.Size = UDim2.new(1, 0, 0, rowsH)
                CatBlock.Size = UDim2.new(1, 0, 0, 16 + 14 + 6 + 24 + 6 + rowsH)
                ResizeRoot()
            end)
        end

        local CategoryFunc = { Key = catKey }
        local itemRows = {}

        local function RenderItemRow(entry)
            local Row = Instance.new("Frame")
            Row.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Row.BackgroundTransparency = 0.965
            Row.Size = UDim2.new(1, 0, 0, 30)
            Row.Name = "ItemRow"
            Row.Parent = ItemListFrame

            local RowCorner = Instance.new("UICorner")
            RowCorner.CornerRadius = UDim.new(0, 4)
            RowCorner.Parent = Row

            local NameLbl = Instance.new("TextLabel")
            NameLbl.Font = Enum.Font.GothamBold
            NameLbl.Text = entry.Name
            NameLbl.TextColor3 = Color3.fromRGB(230, 230, 230)
            NameLbl.TextSize = 12
            NameLbl.TextXAlignment = Enum.TextXAlignment.Left
            NameLbl.BackgroundTransparency = 1
            NameLbl.Position = UDim2.new(0, 8, 0, 3)
            NameLbl.Size = UDim2.new(0.4, 0, 0, 12)
            NameLbl.Parent = Row

            local StockLbl = Instance.new("TextLabel")
            StockLbl.Font = Enum.Font.Gotham
            StockLbl.Text = tostring(entry.Stock or 0)
            StockLbl.TextColor3 = Color3.fromRGB(150, 220, 150)
            StockLbl.TextSize = 10
            StockLbl.TextXAlignment = Enum.TextXAlignment.Left
            StockLbl.BackgroundTransparency = 1
            StockLbl.Position = UDim2.new(0, 8, 0, 16)
            StockLbl.Size = UDim2.new(0.4, 0, 0, 10)
            StockLbl.Parent = Row

            if entry.Note then
                local NoteLbl = Instance.new("TextLabel")
                NoteLbl.Font = Enum.Font.Gotham
                NoteLbl.Text = entry.Note
                NoteLbl.TextColor3 = Color3.fromRGB(120, 220, 130)
                NoteLbl.TextSize = 10
                NoteLbl.TextXAlignment = Enum.TextXAlignment.Left
                NoteLbl.BackgroundTransparency = 1
                NoteLbl.Position = UDim2.new(0.4, 4, 0, 16)
                NoteLbl.Size = UDim2.new(0.2, 0, 0, 10)
                NoteLbl.Parent = Row
            end

            local StepRow = Instance.new("Frame")
            StepRow.AnchorPoint = Vector2.new(1, 0.5)
            StepRow.Position = UDim2.new(1, -6, 0.5, 0)
            StepRow.Size = UDim2.new(0, 118, 0, 20)
            StepRow.BackgroundTransparency = 1
            StepRow.Parent = Row

            local StepLayout = Instance.new("UIListLayout")
            StepLayout.FillDirection = Enum.FillDirection.Horizontal
            StepLayout.Padding = UDim.new(0, 4)
            StepLayout.Parent = StepRow

            local MinusBtn = MakeIconButton(StepRow, "-", 20, GuiConfig.Color)
            local QtyBox = Instance.new("TextBox")
            QtyBox.Font = Enum.Font.GothamBold
            QtyBox.Text = tostring(entry.Qty)
            QtyBox.TextSize = 11
            QtyBox.TextColor3 = Color3.fromRGB(230, 230, 230)
            QtyBox.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            QtyBox.BackgroundTransparency = 0.93
            QtyBox.Size = UDim2.new(0, 56, 1, 0)
            QtyBox.ClearTextOnFocus = false
            QtyBox.Parent = StepRow
            local QtyCorner = Instance.new("UICorner")
            QtyCorner.CornerRadius = UDim.new(0, 3)
            QtyCorner.Parent = QtyBox

            local PlusBtn = MakeIconButton(StepRow, "+", 20, GuiConfig.Color)
            local RemoveBtn = MakeIconButton(StepRow, "x", 18, Color3.fromRGB(255, 107, 107))
            RemoveBtn.BackgroundColor3 = Color3.fromRGB(226, 75, 74)
            RemoveBtn.BackgroundTransparency = 0.88

            local function SetQty(newQty, noSave)
                newQty = math.max(0, math.floor(tonumber(newQty) or entry.Qty))
                entry.Qty = newQty
                QtyBox.Text = tostring(newQty)
                if not noSave then
                    Persist()
                    MailConfig.OnQuantityChange(catKey, entry.Name, newQty)
                end
            end

            MinusBtn.Activated:Connect(function() SetQty(entry.Qty - 1) end)
            PlusBtn.Activated:Connect(function() SetQty(entry.Qty + 1) end)
            QtyBox.FocusLost:Connect(function() SetQty(QtyBox.Text) end)

            RemoveBtn.Activated:Connect(function()
                CircleClick(RemoveBtn, Mouse.X, Mouse.Y)
                for i, v in ipairs(State.CategoryItems[catKey]) do
                    if v.Name == entry.Name then
                        table.remove(State.CategoryItems[catKey], i)
                        break
                    end
                end
                Persist()
                MailConfig.OnRemoveItem(catKey, entry.Name)
                CategoryFunc:Refresh()
            end)

            return Row
        end

        function CategoryFunc:Refresh()
            for _, r in ipairs(itemRows) do
                if r and r.Parent then r:Destroy() end
            end
            itemRows = {}
            for _, entry in ipairs(State.CategoryItems[catKey]) do
                table.insert(itemRows, RenderItemRow(entry))
            end
            ResizeCatBlock()
        end

        function CategoryFunc:AddItem(name, qty, note, noSave, stockVal)
            for _, v in ipairs(State.CategoryItems[catKey]) do
                if v.Name == name then return end
            end
            table.insert(State.CategoryItems[catKey], { Name = name, Qty = qty or 0, Note = note, Stock = stockVal })
            if not noSave then Persist() end
            CategoryFunc:Refresh()
        end

        -- "Add from list": pakai popup picker sama kayak "Add from inventory", tanpa harga/stock
        AddFromListBtn.Activated:Connect(function()
            CircleClick(AddFromListBtn, Mouse.X, Mouse.Y)
            local listItems = {}
            for _, optName in ipairs(catOptions) do
                table.insert(listItems, { Name = optName, Stock = nil })
            end
            local selectedSet = {}
            for _, entry in ipairs(State.CategoryItems[catKey]) do
                selectedSet[entry.Name] = true
            end
            ShowInventoryPicker({
                Title = catKey .. " — from list",
                Items = listItems,
                SelectedSet = selectedSet,
                Color = GuiConfig.Color,
                ShowStock = false,
                OnToggle = function(name, nowSelected)
                    if nowSelected then
                        CategoryFunc:AddItem(name, 0)
                    else
                        for i, v in ipairs(State.CategoryItems[catKey]) do
                            if v.Name == name then
                                table.remove(State.CategoryItems[catKey], i)
                                break
                            end
                        end
                        Persist()
                        CategoryFunc:Refresh()
                    end
                end,
            })
        end)

        AddFromInvBtn.Activated:Connect(function()
            CircleClick(AddFromInvBtn, Mouse.X, Mouse.Y)
            local invItems = MailConfig.OnGetInventoryItems and MailConfig.OnGetInventoryItems(catKey) or {}
            local selectedSet = {}
            for _, entry in ipairs(State.CategoryItems[catKey]) do
                selectedSet[entry.Name] = true
            end
            ShowInventoryPicker({
                Title = catKey .. " — from inventory",
                Items = invItems,
                SelectedSet = selectedSet,
                Color = GuiConfig.Color,
                OnRefresh = function()
                    return MailConfig.OnGetInventoryItems and MailConfig.OnGetInventoryItems(catKey) or {}
                end,
                OnToggle = function(name, nowSelected)
                    if nowSelected then
                        local stock = 0
                        local target = tostring(name):lower():gsub("^%s+", ""):gsub("%s+$", "")
                        for _, it in ipairs(invItems) do
                            local itName = tostring(it.Name or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
                            if itName == target then
                                stock = tonumber(it.Stock) or 0
                                break
                            end
                        end
                        if stock == 0 then
                            warn("[MailQueue] No stock match for '" .. tostring(name) .. "' in category '" .. catKey .. "' — check OnGetInventoryItems for this category")
                        end
                        CategoryFunc:AddItem(name, stock, nil, false, stock)
                    else
                        for i, v in ipairs(State.CategoryItems[catKey]) do
                            if v.Name == name then
                                table.remove(State.CategoryItems[catKey], i)
                                break
                            end
                        end
                        Persist()
                        CategoryFunc:Refresh()
                    end
                end,
            })
        end)

        CategoryFunc:Refresh()
        MailFunc.Categories[catKey] = CategoryFunc
    end

    
    local FooterDivider = Instance.new("Frame")
    FooterDivider.Size = UDim2.new(1, 0, 0, 1)
    FooterDivider.BorderSizePixel = 0
    FooterDivider.LayoutOrder = categoryOrder + 1
    FooterDivider.Parent = Root
    local FooterGrad = Instance.new("UIGradient")
    FooterGrad.Color = ColorSequence.new {
        ColorSequenceKeypoint.new(0, Color3.fromRGB(20, 20, 20)),
        ColorSequenceKeypoint.new(0.5, GuiConfig.Color),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 20, 20)),
    }
    FooterGrad.Parent = FooterDivider

    -- === Mail Presets: nama + save + load terpisah dari config hub ===
    local PresetFolderBase = "HydraHub/Configs/" .. gameName .. "/_mailpresets"

    local function EnsurePresetFolder()
        if not isfolder("HydraHub") then makefolder("HydraHub") end
        if not isfolder("HydraHub/Configs") then makefolder("HydraHub/Configs") end
        if not isfolder("HydraHub/Configs/" .. gameName) then makefolder("HydraHub/Configs/" .. gameName) end
        if not isfolder(PresetFolderBase) then makefolder(PresetFolderBase) end
    end

    local function GetMailPresets()
        local out = {}
        if not listfiles then return out end
        EnsurePresetFolder()
        for _, f in ipairs(listfiles(PresetFolderBase)) do
            local n = string.match(f, "([^/\\]+)%.json$")
            if n then table.insert(out, n) end
        end
        return out
    end

    local function SaveMailPreset(name)
        if not name or name == "" then
            than("Enter a preset name first", 4, Color3.fromRGB(255, 90, 90), "HydraHub", "Mail")
            return false
        end
        if not writefile then return false end
        EnsurePresetFolder()
        local path = PresetFolderBase .. "/" .. name .. ".json"
        local payload = {
            Targets = State.Targets,
            ActiveTarget = State.ActiveTarget,
            CategoryItems = State.CategoryItems,
            AutoSend = State.AutoSend,
            IntervalHours = State.IntervalHours,
            KnownUsernames = State.KnownUsernames,
        }
        writefile(path, HttpService:JSONEncode(payload))
        than("Mail preset '" .. name .. "' saved", 4, GuiConfig.Color, "HydraHub", "Mail")
        return true
    end

    local function LoadMailPreset(name)
        if not name or name == "" then return false end
        local path = PresetFolderBase .. "/" .. name .. ".json"
        if not (isfile and isfile(path)) then
            than("Preset '" .. tostring(name) .. "' not found", 4, Color3.fromRGB(255, 90, 90), "HydraHub", "Mail")
            return false
        end
        local ok, dec = pcall(function() return HttpService:JSONDecode(readfile(path)) end)
        if not ok or type(dec) ~= "table" then
            than("Failed to read preset", 4, Color3.fromRGB(255, 90, 90), "HydraHub", "Mail")
            return false
        end
        MailFunc:Set(dec)
        than("Mail preset '" .. name .. "' loaded", 4, GuiConfig.Color, "HydraHub", "Mail")
        return true
    end

    local function DeleteMailPreset(name)
        local path = PresetFolderBase .. "/" .. name .. ".json"
        if isfile and isfile(path) and delfile then
            delfile(path)
            than("Preset '" .. name .. "' deleted", 4, Color3.fromRGB(255, 170, 0), "HydraHub", "Mail")
            return true
        end
        return false
    end

    local PresetNameBlock = Instance.new("Frame")
    PresetNameBlock.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    PresetNameBlock.BackgroundTransparency = 0.965
    PresetNameBlock.Size = UDim2.new(1, 0, 0, 40)
    PresetNameBlock.LayoutOrder = categoryOrder + 2
    PresetNameBlock.Name = "PresetNameBlock"
    PresetNameBlock.Parent = Root

    local PresetNameCorner = Instance.new("UICorner")
    PresetNameCorner.CornerRadius = UDim.new(0, 6)
    PresetNameCorner.Parent = PresetNameBlock

    local PresetNameTitle = Instance.new("TextLabel")
    PresetNameTitle.Font = Enum.Font.GothamBold
    PresetNameTitle.Text = "Preset Name"
    PresetNameTitle.TextColor3 = GuiConfig.Color
    PresetNameTitle.TextSize = 12
    PresetNameTitle.TextXAlignment = Enum.TextXAlignment.Left
    PresetNameTitle.BackgroundTransparency = 1
    PresetNameTitle.Position = UDim2.new(0, 10, 0, 6)
    PresetNameTitle.Size = UDim2.new(1, -20, 0, 12)
    PresetNameTitle.Parent = PresetNameBlock

    local PresetNameBox = Instance.new("TextBox")
    PresetNameBox.Font = Enum.Font.GothamBold
    PresetNameBox.PlaceholderText = "MyMailPreset"
    PresetNameBox.PlaceholderColor3 = Color3.fromRGB(120, 120, 120)
    PresetNameBox.Text = ""
    PresetNameBox.TextSize = 12
    PresetNameBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    PresetNameBox.TextXAlignment = Enum.TextXAlignment.Left
    PresetNameBox.ClearTextOnFocus = false
    PresetNameBox.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    PresetNameBox.BackgroundTransparency = 0.94
    PresetNameBox.Position = UDim2.new(0, 8, 0, 20)
    PresetNameBox.Size = UDim2.new(1, -16, 0, 16)
    PresetNameBox.Parent = PresetNameBlock

    local PresetNameBoxPad = Instance.new("UIPadding")
    PresetNameBoxPad.PaddingLeft = UDim.new(0, 6)
    PresetNameBoxPad.Parent = PresetNameBox

    local currentPresetName = ""
    PresetNameBox:GetPropertyChangedSignal("Text"):Connect(function()
        currentPresetName = PresetNameBox.Text
    end)

    local PresetListBlock = Instance.new("Frame")
    PresetListBlock.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    PresetListBlock.BackgroundTransparency = 0.965
    PresetListBlock.Size = UDim2.new(1, 0, 0, 40)
    PresetListBlock.LayoutOrder = categoryOrder + 3
    PresetListBlock.Name = "PresetListBlock"
    PresetListBlock.Parent = Root

    local PresetListCorner = Instance.new("UICorner")
    PresetListCorner.CornerRadius = UDim.new(0, 6)
    PresetListCorner.Parent = PresetListBlock

    local PresetListTitle = Instance.new("TextLabel")
    PresetListTitle.Font = Enum.Font.GothamBold
    PresetListTitle.Text = "Saved Presets"
    PresetListTitle.TextColor3 = GuiConfig.Color
    PresetListTitle.TextSize = 12
    PresetListTitle.TextXAlignment = Enum.TextXAlignment.Left
    PresetListTitle.BackgroundTransparency = 1
    PresetListTitle.Position = UDim2.new(0, 10, 0, 6)
    PresetListTitle.Size = UDim2.new(1, -20, 0, 12)
    PresetListTitle.Parent = PresetListBlock

    local selectedPreset = nil

    local PresetDropdownBtn = Instance.new("TextButton")
    PresetDropdownBtn.Font = Enum.Font.GothamBold
    PresetDropdownBtn.Text = "Select preset..."
    PresetDropdownBtn.TextSize = 12
    PresetDropdownBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
    PresetDropdownBtn.TextXAlignment = Enum.TextXAlignment.Left
    PresetDropdownBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    PresetDropdownBtn.BackgroundTransparency = 0.94
    PresetDropdownBtn.Position = UDim2.new(0, 8, 0, 20)
    PresetDropdownBtn.Size = UDim2.new(1, -16, 0, 16)
    PresetDropdownBtn.Parent = PresetListBlock
    local PresetDropdownCorner = Instance.new("UICorner")
    PresetDropdownCorner.CornerRadius = UDim.new(0, 4)
    PresetDropdownCorner.Parent = PresetDropdownBtn
    local PresetDropdownPad = Instance.new("UIPadding")
    PresetDropdownPad.PaddingLeft = UDim.new(0, 6)
    PresetDropdownPad.Parent = PresetDropdownBtn

    local PresetPicker = Instance.new("Frame")
    PresetPicker.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    PresetPicker.BackgroundTransparency = 0.1
    PresetPicker.Size = UDim2.new(1, 0, 0, 0)
    PresetPicker.ClipsDescendants = true
    PresetPicker.Visible = false
    PresetPicker.LayoutOrder = 1
    PresetPicker.Name = "PresetPicker"
    PresetPicker.Parent = PresetListBlock
    local PresetPickerCorner = Instance.new("UICorner")
    PresetPickerCorner.CornerRadius = UDim.new(0, 4)
    PresetPickerCorner.Parent = PresetPicker
    local PresetPickerLayout = Instance.new("UIListLayout")
    PresetPickerLayout.SortOrder = Enum.SortOrder.LayoutOrder
    PresetPickerLayout.Parent = PresetPicker

    local function ResizePresetListBlock()
        task.defer(function()
            local pickerH = PresetPicker.Visible and PresetPicker.Size.Y.Offset or 0
            PresetListBlock.Size = UDim2.new(1, 0, 0, 40 + pickerH)
            ResizeRoot()
        end)
    end

    local function RefreshPresetPicker()
        for _, c in ipairs(PresetPicker:GetChildren()) do
            if c:IsA("GuiObject") then c:Destroy() end
        end
        local presets = GetMailPresets()
        for _, pname in ipairs(presets) do
            local OptBtn = Instance.new("TextButton")
            OptBtn.Font = Enum.Font.GothamBold
            OptBtn.Text = pname
            OptBtn.TextSize = 11
            OptBtn.TextColor3 = Color3.fromRGB(220, 220, 220)
            OptBtn.TextXAlignment = Enum.TextXAlignment.Left
            OptBtn.BackgroundTransparency = 1
            OptBtn.Size = UDim2.new(1, 0, 0, 24)
            OptBtn.Parent = PresetPicker
            local OptPad = Instance.new("UIPadding")
            OptPad.PaddingLeft = UDim.new(0, 8)
            OptPad.Parent = OptBtn

            OptBtn.Activated:Connect(function()
                selectedPreset = pname
                PresetDropdownBtn.Text = pname
                PresetDropdownBtn.TextColor3 = GuiConfig.Color
                PresetPicker.Visible = false
                PresetPicker.Size = UDim2.new(1, 0, 0, 0)
                ResizePresetListBlock()
            end)
        end
    end

    PresetDropdownBtn.Activated:Connect(function()
        CircleClick(PresetDropdownBtn, Mouse.X, Mouse.Y)
        RefreshPresetPicker()
        PresetPicker.Visible = not PresetPicker.Visible
        if PresetPicker.Visible then
            PresetPicker.Size = UDim2.new(1, 0, 0, #GetMailPresets() * 24)
        else
            PresetPicker.Size = UDim2.new(1, 0, 0, 0)
        end
        ResizePresetListBlock()
    end)

    local SaveLoadRow = Instance.new("Frame")
    SaveLoadRow.BackgroundTransparency = 1
    SaveLoadRow.Size = UDim2.new(1, 0, 0, 32)
    SaveLoadRow.LayoutOrder = categoryOrder + 4
    SaveLoadRow.Parent = Root
    local SaveLoadLayout = Instance.new("UIListLayout")
    SaveLoadLayout.FillDirection = Enum.FillDirection.Horizontal
    SaveLoadLayout.Padding = UDim.new(0, 6)
    SaveLoadLayout.Parent = SaveLoadRow

    local SaveBtn = MakeIconButton(SaveLoadRow, "Save preset", 0, nil)
    SaveBtn.Size = UDim2.new(0.33, -4, 1, 0)
    local LoadBtn = MakeIconButton(SaveLoadRow, "Load preset", 0, nil)
    LoadBtn.Size = UDim2.new(0.33, -4, 1, 0)
    local DeleteBtn = MakeIconButton(SaveLoadRow, "Delete", 0, Color3.fromRGB(255, 107, 107))
    DeleteBtn.Size = UDim2.new(0.33, -4, 1, 0)

    SaveBtn.Activated:Connect(function()
        CircleClick(SaveBtn, Mouse.X, Mouse.Y)
        if SaveMailPreset(currentPresetName) then
            selectedPreset = currentPresetName
            PresetDropdownBtn.Text = currentPresetName
            PresetDropdownBtn.TextColor3 = GuiConfig.Color
        end
        MailConfig.OnSaveConfig()
    end)
    LoadBtn.Activated:Connect(function()
        CircleClick(LoadBtn, Mouse.X, Mouse.Y)
        LoadMailPreset(selectedPreset)
        MailConfig.OnLoadConfig()
    end)
    DeleteBtn.Activated:Connect(function()
        CircleClick(DeleteBtn, Mouse.X, Mouse.Y)
        if selectedPreset then
            DeleteMailPreset(selectedPreset)
            selectedPreset = nil
            PresetDropdownBtn.Text = "Select preset..."
            PresetDropdownBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
        end
    end)

    local AutoSendBlock = Instance.new("Frame")
    AutoSendBlock.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    AutoSendBlock.BackgroundTransparency = 0.965
    AutoSendBlock.Size = UDim2.new(1, 0, 0, 40)
    AutoSendBlock.LayoutOrder = categoryOrder + 5
    AutoSendBlock.Parent = Root
    local AutoSendCorner = Instance.new("UICorner")
    AutoSendCorner.CornerRadius = UDim.new(0, 6)
    AutoSendCorner.Parent = AutoSendBlock

    local AutoSendTitle = Instance.new("TextLabel")
    AutoSendTitle.Font = Enum.Font.GothamBold
    AutoSendTitle.Text = "Auto Send Mail"
    AutoSendTitle.TextColor3 = Color3.fromRGB(230, 230, 230)
    AutoSendTitle.TextSize = 13
    AutoSendTitle.TextXAlignment = Enum.TextXAlignment.Left
    AutoSendTitle.BackgroundTransparency = 1
    AutoSendTitle.Position = UDim2.new(0, 10, 0, 8)
    AutoSendTitle.Size = UDim2.new(1, -60, 0, 13)
    AutoSendTitle.Parent = AutoSendBlock

    local AutoSendSub = Instance.new("TextLabel")
    AutoSendSub.Font = Enum.Font.Gotham
    AutoSendSub.Text = "Loop send to active target"
    AutoSendSub.TextColor3 = Color3.fromRGB(255, 255, 255)
    AutoSendSub.TextTransparency = 0.6
    AutoSendSub.TextSize = 11
    AutoSendSub.TextXAlignment = Enum.TextXAlignment.Left
    AutoSendSub.BackgroundTransparency = 1
    AutoSendSub.Position = UDim2.new(0, 10, 0, 21)
    AutoSendSub.Size = UDim2.new(1, -60, 0, 11)
    AutoSendSub.Parent = AutoSendBlock

    local SwitchBg = Instance.new("Frame")
    SwitchBg.AnchorPoint = Vector2.new(1, 0.5)
    SwitchBg.Position = UDim2.new(1, -10, 0.5, 0)
    SwitchBg.Size = UDim2.new(0, 30, 0, 15)
    SwitchBg.BackgroundColor3 = State.AutoSend and GuiConfig.Color or Color3.fromRGB(255, 255, 255)
    SwitchBg.BackgroundTransparency = State.AutoSend and 0 or 0.92
    SwitchBg.Parent = AutoSendBlock
    local SwitchCorner = Instance.new("UICorner")
    SwitchCorner.CornerRadius = UDim.new(1, 0)
    SwitchCorner.Parent = SwitchBg

    local SwitchDot = Instance.new("Frame")
    SwitchDot.Size = UDim2.new(0, 14, 0, 14)
    SwitchDot.AnchorPoint = Vector2.new(State.AutoSend and 1 or 0, 0.5)
    SwitchDot.Position = UDim2.new(State.AutoSend and 1 or 0, 0, 0.5, 0)
    SwitchDot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    SwitchDot.Parent = SwitchBg
    local SwitchDotCorner = Instance.new("UICorner")
    SwitchDotCorner.CornerRadius = UDim.new(1, 0)
    SwitchDotCorner.Parent = SwitchDot

    local SwitchBtn = Instance.new("TextButton")
    SwitchBtn.Text = ""
    SwitchBtn.BackgroundTransparency = 1
    SwitchBtn.Size = UDim2.new(1, 0, 1, 0)
    SwitchBtn.Parent = AutoSendBlock

    SwitchBtn.Activated:Connect(function()
        State.AutoSend = not State.AutoSend
        Persist()
        TweenService:Create(SwitchBg, TweenInfo.new(0.2), {
            BackgroundColor3 = State.AutoSend and GuiConfig.Color or Color3.fromRGB(255, 255, 255),
            BackgroundTransparency = State.AutoSend and 0 or 0.92,
        }):Play()
        TweenService:Create(SwitchDot, TweenInfo.new(0.2), {
            Position = UDim2.new(State.AutoSend and 1 or 0, 0, 0.5, 0),
        }):Play()
        SwitchDot.AnchorPoint = Vector2.new(State.AutoSend and 1 or 0, 0.5)
        MailConfig.OnAutoSendToggle(State.AutoSend)
    end)

    local IntervalBlock = Instance.new("Frame")
    IntervalBlock.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    IntervalBlock.BackgroundTransparency = 0.965
    IntervalBlock.Size = UDim2.new(1, 0, 0, 36)
    IntervalBlock.LayoutOrder = categoryOrder + 6
    IntervalBlock.Parent = Root
    local IntervalCorner = Instance.new("UICorner")
    IntervalCorner.CornerRadius = UDim.new(0, 6)
    IntervalCorner.Parent = IntervalBlock

    local IntervalTitle = Instance.new("TextLabel")
    IntervalTitle.Font = Enum.Font.GothamBold
    IntervalTitle.Text = "Send every"
    IntervalTitle.TextColor3 = Color3.fromRGB(230, 230, 230)
    IntervalTitle.TextSize = 12
    IntervalTitle.TextXAlignment = Enum.TextXAlignment.Left
    IntervalTitle.BackgroundTransparency = 1
    IntervalTitle.Position = UDim2.new(0, 10, 0, 0)
    IntervalTitle.Size = UDim2.new(0.5, 0, 0, 24)
    IntervalTitle.Parent = IntervalBlock

    local IntervalStepRow = Instance.new("Frame")
    IntervalStepRow.AnchorPoint = Vector2.new(1, 0)
    IntervalStepRow.Position = UDim2.new(1, -8, 0, 4)
    IntervalStepRow.Size = UDim2.new(0, 130, 0, 20)
    IntervalStepRow.BackgroundTransparency = 1
    IntervalStepRow.Parent = IntervalBlock
    local IntervalStepLayout = Instance.new("UIListLayout")
    IntervalStepLayout.FillDirection = Enum.FillDirection.Horizontal
    IntervalStepLayout.Padding = UDim.new(0, 4)
    IntervalStepLayout.Parent = IntervalStepRow

    local IntMinusBtn = MakeIconButton(IntervalStepRow, "-", 20, GuiConfig.Color)
    local IntLabel = Instance.new("TextLabel")
    IntLabel.Font = Enum.Font.GothamBold
    IntLabel.Text = State.IntervalHours .. " hours"
    IntLabel.TextSize = 11
    IntLabel.TextColor3 = Color3.fromRGB(230, 230, 230)
    IntLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    IntLabel.BackgroundTransparency = 0.93
    IntLabel.Size = UDim2.new(0, 66, 1, 0)
    IntLabel.Parent = IntervalStepRow
    local IntLabelCorner = Instance.new("UICorner")
    IntLabelCorner.CornerRadius = UDim.new(0, 3)
    IntLabelCorner.Parent = IntLabel
    local IntPlusBtn = MakeIconButton(IntervalStepRow, "+", 20, GuiConfig.Color)

    local NextSendLbl = Instance.new("TextLabel")
    NextSendLbl.Font = Enum.Font.Gotham
    NextSendLbl.Text = ""
    NextSendLbl.TextColor3 = Color3.fromRGB(150, 150, 150)
    NextSendLbl.TextSize = 10
    NextSendLbl.TextXAlignment = Enum.TextXAlignment.Left
    NextSendLbl.BackgroundTransparency = 1
    NextSendLbl.Position = UDim2.new(0, 10, 0, 22)
    NextSendLbl.Size = UDim2.new(1, -20, 0, 12)
    NextSendLbl.Parent = IntervalBlock

    function MailFunc:SetNextSendText(text)
        NextSendLbl.Text = text or ""
    end

    local function SetInterval(hours)
        hours = math.max(1, math.floor(hours))
        State.IntervalHours = hours
        IntLabel.Text = hours .. " hours"
        Persist()
        MailConfig.OnIntervalChange(hours)
    end

    IntMinusBtn.Activated:Connect(function() SetInterval(State.IntervalHours - 1) end)
    IntPlusBtn.Activated:Connect(function() SetInterval(State.IntervalHours + 1) end)

    ResizeRoot()

    if shouldSave then
        Elements[configKey] = MailFunc
    end
    RegisterSearch({ label = MailConfig.Title, tab = TabConfig.Name, kind = "MailQueue", switch = SearchSwitch })

    CountItem = CountItem + 1
    return MailFunc
end

            function Items:AddSubSection(title)
                title = title or "Sub Section"

                local SubSection = Instance.new("Frame")
                SubSection.Name = "SubSection"
                SubSection.Parent = SectionAdd
                SubSection.BackgroundTransparency = 1
                SubSection.Size = UDim2.new(1, 0, 0, 28)
                SubSection.LayoutOrder = CountItem

                local Background = Instance.new("Frame")
                Background.Parent = SubSection
                Background.Size = UDim2.new(1, 0, 0, 22)
                Background.Position = UDim2.new(0, 0, 0, 0)
                Background.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                Background.BackgroundTransparency = 0.935
                Background.BorderSizePixel = 0
                Instance.new("UICorner", Background).CornerRadius = UDim.new(0, 6)

                local Label = Instance.new("TextLabel")
                Label.Parent = Background
                Label.AnchorPoint = Vector2.new(0, 0.5)
                Label.Position = UDim2.new(0, 10, 0.5, 0)
                Label.Size = UDim2.new(1, -20, 1, 0)
                Label.BackgroundTransparency = 1
                Label.Font = Enum.Font.GothamBold
                Label.Text = title
                Label.TextColor3 = Color3.fromRGB(230, 230, 230)
                Label.TextSize = 12
                Label.TextWrapped = true
                Label.TextXAlignment = Enum.TextXAlignment.Left
                Label.TextYAlignment = Enum.TextYAlignment.Center

                local function UpdateSubSectionHeight()
                    task.defer(function()
                        local lines = math.ceil(Label.TextBounds.X / math.max(Label.AbsoluteSize.X, 1))
                        local bgH = math.max(22, 14 * lines + 8)
                        Background.Size = UDim2.new(1, 0, 0, bgH)
                        SubSection.Size = UDim2.new(1, 0, 0, bgH + 6)
                        UpdateSizeSection()
                    end)
                end
                Label:GetPropertyChangedSignal("TextBounds"):Connect(UpdateSubSectionHeight)
                UpdateSubSectionHeight()

                CountItem = CountItem + 1
                return SubSection
            end

            function Items:AddFruitTargetList(FruitTargetConfig)
    FruitTargetConfig = FruitTargetConfig or {}
    FruitTargetConfig.Title = FruitTargetConfig.Title or "Fruit Targets"
    FruitTargetConfig.SeedOptions = FruitTargetConfig.SeedOptions or {}
    FruitTargetConfig.OnAdd = FruitTargetConfig.OnAdd or function(entry) end
    FruitTargetConfig.OnRemove = FruitTargetConfig.OnRemove or function(entry) end
    FruitTargetConfig.OnChange = FruitTargetConfig.OnChange or function(list) end
    FruitTargetConfig.OnGetSeedStock = FruitTargetConfig.OnGetSeedStock or function(seedName) return 0 end

    local configKey = "FruitTargetList_" .. FruitTargetConfig.Title
    local shouldSave = FruitTargetConfig.Save ~= false

    local State = { Entries = {} }
    if shouldSave and ConfigData[configKey] ~= nil and type(ConfigData[configKey]) == "table" then
        State.Entries = ConfigData[configKey].Entries or {}
    end

    local FruitTargetFunc = { Value = State }

    local function Persist(noSave)
        if not shouldSave then return end
        ConfigData[configKey] = State
        if not noSave then QueueSaveConfig() end
    end

    local Root = Instance.new("Frame")
    Root.BackgroundTransparency = 1
    Root.LayoutOrder = CountItem
    Root.Name = "FruitTargetList"
    Root.Parent = SectionAdd

    local RootList = Instance.new("UIListLayout")
    RootList.Padding = UDim.new(0, 10)
    RootList.SortOrder = Enum.SortOrder.LayoutOrder
    RootList.Parent = Root

    local function ResizeRoot()
        task.defer(function()
            local h = 0
            for _, c in Root:GetChildren() do
                if c:IsA("GuiObject") then
                    h = h + c.Size.Y.Offset + 10
                end
            end
            Root.Size = UDim2.new(1, 0, 0, h)
            UpdateSizeSection()
        end)
    end

    local function MakeIconButton(parent, text, w, color)
        local Btn = Instance.new("TextButton")
        Btn.Font = Enum.Font.GothamBold
        Btn.Text = text
        Btn.TextSize = 12
        Btn.TextColor3 = color or Color3.fromRGB(255, 255, 255)
        Btn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        Btn.BackgroundTransparency = 0.94
        Btn.Size = UDim2.new(0, w, 0, 20)
        Btn.Parent = parent
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, 4)
        c.Parent = Btn
        return Btn
    end

    local InputBlock = Instance.new("Frame")
    InputBlock.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    InputBlock.BackgroundTransparency = 0.955
    InputBlock.Size = UDim2.new(1, 0, 0, 40)
    InputBlock.LayoutOrder = 1
    InputBlock.Name = "InputBlock"
    InputBlock.Parent = Root

    local InputCorner = Instance.new("UICorner")
    InputCorner.CornerRadius = UDim.new(0, 8)
    InputCorner.Parent = InputBlock

    local InputStroke = Instance.new("UIStroke")
    InputStroke.Color = GuiConfig.Color
    InputStroke.Thickness = 1
    InputStroke.Transparency = 0.85
    InputStroke.Parent = InputBlock

    local InputPad = Instance.new("UIPadding")
    InputPad.PaddingTop = UDim.new(0, 12)
    InputPad.PaddingBottom = UDim.new(0, 12)
    InputPad.PaddingLeft = UDim.new(0, 12)
    InputPad.PaddingRight = UDim.new(0, 12)
    InputPad.Parent = InputBlock

    local InputList = Instance.new("UIListLayout")
    InputList.Padding = UDim.new(0, 10)
    InputList.SortOrder = Enum.SortOrder.LayoutOrder
    InputList.Parent = InputBlock

    local InputTitle = Instance.new("TextLabel")
    InputTitle.Font = Enum.Font.GothamBold
    InputTitle.Text = FruitTargetConfig.Title
    InputTitle.TextColor3 = GuiConfig.Color
    InputTitle.TextSize = 15
    InputTitle.TextXAlignment = Enum.TextXAlignment.Left
    InputTitle.BackgroundTransparency = 1
    InputTitle.Size = UDim2.new(1, 0, 0, 18)
    InputTitle.LayoutOrder = 0
    InputTitle.Parent = InputBlock

    local InputTitleDivider = Instance.new("Frame")
    InputTitleDivider.BackgroundColor3 = GuiConfig.Color
    InputTitleDivider.BackgroundTransparency = 0.8
    InputTitleDivider.BorderSizePixel = 0
    InputTitleDivider.Size = UDim2.new(1, 0, 0, 1)
    InputTitleDivider.LayoutOrder = 1
    InputTitleDivider.Name = "InputTitleDivider"
    InputTitleDivider.Parent = InputBlock

    local SeedPickRow = Instance.new("Frame")
    SeedPickRow.BackgroundTransparency = 1
    SeedPickRow.Size = UDim2.new(1, 0, 0, 26)
    SeedPickRow.LayoutOrder = 2
    SeedPickRow.Parent = InputBlock

    local selectedSeedName = nil

    local SeedPickBtn = Instance.new("TextButton")
    SeedPickBtn.Font = Enum.Font.GothamBold
    SeedPickBtn.Text = "Pilih seed..."
    SeedPickBtn.TextSize = 12
    SeedPickBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
    SeedPickBtn.TextXAlignment = Enum.TextXAlignment.Left
    SeedPickBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    SeedPickBtn.BackgroundTransparency = 0.94
    SeedPickBtn.Size = UDim2.new(1, 0, 1, 0)
    SeedPickBtn.Parent = SeedPickRow

    local SeedPickCorner = Instance.new("UICorner")
    SeedPickCorner.CornerRadius = UDim.new(0, 4)
    SeedPickCorner.Parent = SeedPickBtn

    local SeedPickPad = Instance.new("UIPadding")
    SeedPickPad.PaddingLeft = UDim.new(0, 8)
    SeedPickPad.Parent = SeedPickBtn

    local ValuesRow = Instance.new("Frame")
    ValuesRow.BackgroundTransparency = 1
    ValuesRow.Size = UDim2.new(1, 0, 0, 26)
    ValuesRow.LayoutOrder = 3
    ValuesRow.Parent = InputBlock

    local ValuesLayout = Instance.new("UIListLayout")
    ValuesLayout.FillDirection = Enum.FillDirection.Horizontal
    ValuesLayout.Padding = UDim.new(0, 6)
    ValuesLayout.Parent = ValuesRow

    local function ResizeInputBlock()
        task.defer(function()
            -- padding(12*2) + title(18) + divider(1) + row1(26) + row2(26) + gaps(10*3)
            InputBlock.Size = UDim2.new(1, 0, 0, 24 + 18 + 1 + 26 + 26 + 30)
            ResizeRoot()
        end)
    end

    local KgBox = Instance.new("TextBox")
    KgBox.Font = Enum.Font.GothamBold
    KgBox.PlaceholderText = "KG (mis. 100)"
    KgBox.PlaceholderColor3 = Color3.fromRGB(120, 120, 120)
    KgBox.Text = ""
    KgBox.TextSize = 12
    KgBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    KgBox.TextXAlignment = Enum.TextXAlignment.Left
    KgBox.ClearTextOnFocus = false
    KgBox.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    KgBox.BackgroundTransparency = 0.94
    KgBox.Size = UDim2.new(0.5, -17, 1, 0)
    KgBox.Parent = ValuesRow
    local KgBoxCorner = Instance.new("UICorner")
    KgBoxCorner.CornerRadius = UDim.new(0, 4)
    KgBoxCorner.Parent = KgBox
    local KgBoxPad = Instance.new("UIPadding")
    KgBoxPad.PaddingLeft = UDim.new(0, 6)
    KgBoxPad.Parent = KgBox

    local CountBox = Instance.new("TextBox")
    CountBox.Font = Enum.Font.GothamBold
    CountBox.PlaceholderText = "Jumlah (mis. 40)"
    CountBox.PlaceholderColor3 = Color3.fromRGB(120, 120, 120)
    CountBox.Text = ""
    CountBox.TextSize = 12
    CountBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    CountBox.TextXAlignment = Enum.TextXAlignment.Left
    CountBox.ClearTextOnFocus = false
    CountBox.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    CountBox.BackgroundTransparency = 0.94
    CountBox.Size = UDim2.new(0.5, -17, 1, 0)
    CountBox.Parent = ValuesRow
    local CountBoxCorner = Instance.new("UICorner")
    CountBoxCorner.CornerRadius = UDim.new(0, 4)
    CountBoxCorner.Parent = CountBox
    local CountBoxPad = Instance.new("UIPadding")
    CountBoxPad.PaddingLeft = UDim.new(0, 6)
    CountBoxPad.Parent = CountBox

    local AddEntryBtn = Instance.new("TextButton")
    AddEntryBtn.Font = Enum.Font.GothamBold
    AddEntryBtn.Text = "+"
    AddEntryBtn.TextSize = 16
    AddEntryBtn.TextColor3 = GuiConfig.Color
    AddEntryBtn.BackgroundColor3 = GuiConfig.Color
    AddEntryBtn.BackgroundTransparency = 0.88
    AddEntryBtn.Size = UDim2.new(0, 26, 1, 0)
    AddEntryBtn.Parent = ValuesRow
    local AddEntryCorner = Instance.new("UICorner")
    AddEntryCorner.CornerRadius = UDim.new(0, 4)
    AddEntryCorner.Parent = AddEntryBtn

    SeedPickBtn.Activated:Connect(function()
        CircleClick(SeedPickBtn, Mouse.X, Mouse.Y)
        local listItems = {}
        for _, optName in ipairs(FruitTargetConfig.SeedOptions) do
            local stock = 0
            pcall(function() stock = FruitTargetConfig.OnGetSeedStock(optName) or 0 end)
            table.insert(listItems, { Name = optName, Stock = stock })
        end
        local selectedSet = {}
        if selectedSeedName then selectedSet[selectedSeedName] = true end
        ShowInventoryPicker({
            Title = "Pilih Seed",
            Items = listItems,
            SelectedSet = selectedSet,
            Color = GuiConfig.Color,
            ShowStock = true,
            OnRefresh = function()
                local fresh = {}
                for _, optName in ipairs(FruitTargetConfig.SeedOptions) do
                    local stock = 0
                    pcall(function() stock = FruitTargetConfig.OnGetSeedStock(optName) or 0 end)
                    table.insert(fresh, { Name = optName, Stock = stock })
                end
                return fresh
            end,
            OnToggle = function(name, nowSelected)
                if nowSelected then
                    selectedSeedName = name
                    SeedPickBtn.Text = name
                    SeedPickBtn.TextColor3 = GuiConfig.Color
                else
                    if selectedSeedName == name then
                        selectedSeedName = nil
                        SeedPickBtn.Text = "Pilih seed..."
                        SeedPickBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
                    end
                end
            end,
        })
    end)

    local ListWrapper = Instance.new("Frame")
    ListWrapper.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    ListWrapper.BackgroundTransparency = 0.965
    ListWrapper.Size = UDim2.new(1, 0, 0, 0)
    ListWrapper.LayoutOrder = 2
    ListWrapper.Name = "FruitTargetListWrapper"
    ListWrapper.Visible = false
    ListWrapper.Parent = Root

    local ListWrapperCorner = Instance.new("UICorner")
    ListWrapperCorner.CornerRadius = UDim.new(0, 8)
    ListWrapperCorner.Parent = ListWrapper

    local ListWrapperStroke = Instance.new("UIStroke")
    ListWrapperStroke.Color = Color3.fromRGB(255, 255, 255)
    ListWrapperStroke.Thickness = 1
    ListWrapperStroke.Transparency = 0.92
    ListWrapperStroke.Parent = ListWrapper

    local ListWrapperPad = Instance.new("UIPadding")
    ListWrapperPad.PaddingTop = UDim.new(0, 8)
    ListWrapperPad.PaddingBottom = UDim.new(0, 8)
    ListWrapperPad.PaddingLeft = UDim.new(0, 8)
    ListWrapperPad.PaddingRight = UDim.new(0, 8)
    ListWrapperPad.Parent = ListWrapper

    local ListFrame = Instance.new("Frame")
    ListFrame.BackgroundTransparency = 1
    ListFrame.Size = UDim2.new(1, 0, 0, 0)
    ListFrame.Name = "FruitTargetListFrame"
    ListFrame.Parent = ListWrapper

    local ListLayout2 = Instance.new("UIListLayout")
    ListLayout2.Padding = UDim.new(0, 6)
    ListLayout2.SortOrder = Enum.SortOrder.LayoutOrder
    ListLayout2.Parent = ListFrame

    local function ResizeListFrame()
        task.defer(function()
            local h = 0
            for _, c in ListFrame:GetChildren() do
                if c:IsA("GuiObject") then h = h + c.Size.Y.Offset + 6 end
            end
            ListFrame.Size = UDim2.new(1, 0, 0, h)

            local hasEntries = #State.Entries > 0
            ListWrapper.Visible = hasEntries
            if hasEntries then
                ListWrapper.Size = UDim2.new(1, 0, 0, h + 16)
            else
                ListWrapper.Size = UDim2.new(1, 0, 0, 0)
            end
            ResizeRoot()
        end)
    end

    local entryRows = {}

    local function RenderEntryRow(entry, index)
        local Row = Instance.new("Frame")
        Row.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        Row.BackgroundTransparency = 0.94
        Row.Size = UDim2.new(1, 0, 0, 32)
        Row.Name = "FruitTargetRow"
        Row.Parent = ListFrame

        local RowCorner = Instance.new("UICorner")
        RowCorner.CornerRadius = UDim.new(0, 4)
        RowCorner.Parent = Row

        local NameLbl = Instance.new("TextLabel")
        NameLbl.Font = Enum.Font.GothamBold
        NameLbl.Text = entry.SeedName
        NameLbl.TextColor3 = Color3.fromRGB(230, 230, 230)
        NameLbl.TextSize = 12
        NameLbl.TextXAlignment = Enum.TextXAlignment.Left
        NameLbl.BackgroundTransparency = 1
        NameLbl.Position = UDim2.new(0, 8, 0, 4)
        NameLbl.Size = UDim2.new(1, -120, 0, 12)
        NameLbl.Parent = Row

        local DetailLbl = Instance.new("TextLabel")
        DetailLbl.Font = Enum.Font.Gotham
        DetailLbl.Text = string.format("%sx  \xE2\x89\xA5%skg", tostring(entry.Count), tostring(entry.Kg))
        DetailLbl.TextColor3 = GuiConfig.Color
        DetailLbl.TextSize = 10
        DetailLbl.TextXAlignment = Enum.TextXAlignment.Left
        DetailLbl.BackgroundTransparency = 1
        DetailLbl.Position = UDim2.new(0, 8, 0, 18)
        DetailLbl.Size = UDim2.new(1, -120, 0, 10)
        DetailLbl.Parent = Row

        local RemoveBtn = MakeIconButton(Row, "x", 18, Color3.fromRGB(255, 107, 107))
        RemoveBtn.AnchorPoint = Vector2.new(1, 0.5)
        RemoveBtn.Position = UDim2.new(1, -6, 0.5, 0)
        RemoveBtn.BackgroundColor3 = Color3.fromRGB(226, 75, 74)
        RemoveBtn.BackgroundTransparency = 0.88

        RemoveBtn.Activated:Connect(function()
            CircleClick(RemoveBtn, Mouse.X, Mouse.Y)
            for i, v in ipairs(State.Entries) do
                if v == entry then
                    table.remove(State.Entries, i)
                    break
                end
            end
            Persist()
            FruitTargetConfig.OnRemove(entry)
            FruitTargetConfig.OnChange(State.Entries)
            FruitTargetFunc:Refresh()
        end)

        local StepRow = Instance.new("Frame")
        StepRow.AnchorPoint = Vector2.new(1, 0.5)
        StepRow.Position = UDim2.new(1, -30, 0.5, 0)
        StepRow.Size = UDim2.new(0, 76, 0, 20)
        StepRow.BackgroundTransparency = 1
        StepRow.Parent = Row

        local StepLayout = Instance.new("UIListLayout")
        StepLayout.FillDirection = Enum.FillDirection.Horizontal
        StepLayout.Padding = UDim.new(0, 4)
        StepLayout.Parent = StepRow

        local MinusBtn = MakeIconButton(StepRow, "-", 18, GuiConfig.Color)

        local CountLbl = Instance.new("TextLabel")
        CountLbl.Font = Enum.Font.GothamBold
        CountLbl.Text = tostring(entry.Count)
        CountLbl.TextSize = 11
        CountLbl.TextColor3 = Color3.fromRGB(230, 230, 230)
        CountLbl.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        CountLbl.BackgroundTransparency = 0.93
        CountLbl.Size = UDim2.new(0, 30, 1, 0)
        CountLbl.Parent = StepRow
        local CountLblCorner = Instance.new("UICorner")
        CountLblCorner.CornerRadius = UDim.new(0, 3)
        CountLblCorner.Parent = CountLbl

        local PlusBtn = MakeIconButton(StepRow, "+", 18, GuiConfig.Color)

        local function SetCount(newCount)
            newCount = math.max(1, math.floor(tonumber(newCount) or entry.Count))
            entry.Count = newCount
            CountLbl.Text = tostring(newCount)
            DetailLbl.Text = string.format("%sx  \xE2\x89\xA5%skg", tostring(entry.Count), tostring(entry.Kg))
            Persist()
            FruitTargetConfig.OnChange(State.Entries)
        end

        MinusBtn.Activated:Connect(function() SetCount(entry.Count - 1) end)
        PlusBtn.Activated:Connect(function() SetCount(entry.Count + 1) end)

        return Row
    end

    function FruitTargetFunc:Refresh()
        for _, r in ipairs(entryRows) do
            if r and r.Parent then r:Destroy() end
        end
        entryRows = {}
        for i, entry in ipairs(State.Entries) do
            table.insert(entryRows, RenderEntryRow(entry, i))
        end
        ResizeListFrame()
    end

    function FruitTargetFunc:AddEntry(seedName, kg, count, noSave)
        if not seedName or seedName == "" then return false end
        kg = tonumber(kg) or 0
        count = tonumber(count) or 0
        if count <= 0 then return false end

        for _, v in ipairs(State.Entries) do
            if v.SeedName == seedName and v.Kg == kg then
                return false
            end
        end

        local entry = { SeedName = seedName, Kg = kg, Count = count }
        table.insert(State.Entries, entry)
        if not noSave then Persist() end
        FruitTargetConfig.OnAdd(entry)
        FruitTargetConfig.OnChange(State.Entries)
        FruitTargetFunc:Refresh()
        return true
    end

    function FruitTargetFunc:RemoveEntry(seedName, kg)
        for i, v in ipairs(State.Entries) do
            if v.SeedName == seedName and v.Kg == kg then
                table.remove(State.Entries, i)
                Persist()
                FruitTargetConfig.OnChange(State.Entries)
                FruitTargetFunc:Refresh()
                return true
            end
        end
        return false
    end

    function FruitTargetFunc:Clear(noSave)
        State.Entries = {}
        if not noSave then Persist() end
        FruitTargetFunc:Refresh()
    end

    function FruitTargetFunc:Set(newValue, noSave)
        if type(newValue) == "table" and newValue.Entries ~= nil then
            State.Entries = newValue.Entries
        elseif type(newValue) == "table" then
            State.Entries = newValue
        else
            State.Entries = {}
        end
        FruitTargetFunc:Refresh()
        if not noSave then Persist() end
    end

    AddEntryBtn.Activated:Connect(function()
        CircleClick(AddEntryBtn, Mouse.X, Mouse.Y)
        if not selectedSeedName then
            than("Pilih seed dulu", 3, Color3.fromRGB(255, 170, 0), "HydraHub", FruitTargetConfig.Title)
            return
        end
        local kgVal = tonumber(KgBox.Text)
        local countVal = tonumber(CountBox.Text)
        if not kgVal or kgVal <= 0 then
            than("KG tidak valid", 3, Color3.fromRGB(255, 170, 0), "HydraHub", FruitTargetConfig.Title)
            return
        end
        if not countVal or countVal <= 0 then
            than("Jumlah tidak valid", 3, Color3.fromRGB(255, 170, 0), "HydraHub", FruitTargetConfig.Title)
            return
        end

        local added = FruitTargetFunc:AddEntry(selectedSeedName, kgVal, countVal)
        if added then
            KgBox.Text = ""
            CountBox.Text = ""
            selectedSeedName = nil
            SeedPickBtn.Text = "Pilih seed..."
            SeedPickBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
        else
            than("Target seed+kg ini sudah ada di list", 3, Color3.fromRGB(255, 170, 0), "HydraHub", FruitTargetConfig.Title)
        end
    end)

    FruitTargetFunc:Refresh()
    ResizeInputBlock()
    ResizeRoot()

    if shouldSave then
        Elements[configKey] = FruitTargetFunc
    end
    RegisterSearch({ label = FruitTargetConfig.Title, tab = TabConfig.Name, kind = "FruitTargetList", switch = SearchSwitch })

    CountItem = CountItem + 1
    return FruitTargetFunc
end
            CountSection = CountSection + 1
            return Items
        end

        CountTab = CountTab + 1
        local safeName = TabConfig.Name:gsub("%s+", "_")
        _G[safeName] = Sections
        return Sections
    end

    function Tabs:InfoTab(InfoConfig)
        InfoConfig = InfoConfig or {}
        local Sections = Tabs:AddTab({
            Name = InfoConfig.Name or "Info",
            Icon = InfoConfig.Icon or "idea",
        })
        local Items = Sections:AddSection(InfoConfig.SectionTitle or "Information", true)

        if InfoConfig.Banner and InfoConfig.Banner ~= "" then
            Items:AddBanner({
                Image = InfoConfig.Banner,
                Version = InfoConfig.Version,
                AspectRatio = InfoConfig.BannerAspectRatio,
            })
        end

        if InfoConfig.DiscordLink then
            Items:AddCard({
                Title = InfoConfig.DiscordName or "Community",
                Description = InfoConfig.DiscordText or "Support, updates and announcements.",
                Logo = Icons.discord,
                Buttons = {
                    {
                        Name = "Copy Invite",
                        Callback = function()
                            if setclipboard then
                                setclipboard(InfoConfig.DiscordLink)
                                than("Discord invite copied", 4, GuiConfig.Color, "HydraHub", "Community")
                            end
                        end,
                    },
                },
            })
        end

        for _, card in ipairs(InfoConfig.Cards or {}) do
            Items:AddCard(card)
        end

        return Sections, Items
    end

    GuiFunc.InfoTab = function(_, cfg) return Tabs:InfoTab(cfg) end
    Tabs.Window = GuiFunc
    Tabs.ExportConfig = function() return GuiFunc:ExportConfig() end
    Tabs.ImportConfig = function(_, str) return GuiFunc:ImportConfig(str) end

    if GuiConfig.Search then
        UserInputService.InputBegan:Connect(function(input, gpe)
            if gpe then return end
            local ctrl = UserInputService:IsKeyDown(Enum.KeyCode.LeftControl)
                or UserInputService:IsKeyDown(Enum.KeyCode.RightControl)
                or UserInputService:IsKeyDown(Enum.KeyCode.LeftMeta)
                or UserInputService:IsKeyDown(Enum.KeyCode.RightMeta)
            local shift = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)
                or UserInputService:IsKeyDown(Enum.KeyCode.RightShift)
            if ctrl and shift and input.KeyCode == Enum.KeyCode.F then
                if DropShadowHolder then DropShadowHolder.Visible = true end
                if GuiFunc.FocusSearch then GuiFunc.FocusSearch() end
            elseif ctrl and input.KeyCode == Enum.KeyCode.O then
                if DropShadowHolder then DropShadowHolder.Visible = true end
                if GuiFunc.FocusSearch then GuiFunc.FocusSearch() end
            end
        end)
    end

    task.spawn(function()
        task.wait(0.5)
        local autoName = GuiFunc:GetAutoLoad()
        if autoName and autoName ~= "" then
            GuiFunc:LoadConfigByName(autoName)
        end
    end)

    return Tabs
end



function Chloex:CreateProgressPanel(PanelConfig)
    PanelConfig = PanelConfig or {}
    PanelConfig.Title = PanelConfig.Title or "Progress"
    PanelConfig.Color = PanelConfig.Color or Color3.fromRGB(100, 200, 255)

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "HydraProgressPanel"
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Parent = game:GetService("CoreGui")

    local Root = Instance.new("Frame")
    Root.AnchorPoint = Vector2.new(0, 0)
    Root.Position = PanelConfig.Position or UDim2.new(0, 20, 0, 400)
    Root.Size = UDim2.new(0, 260, 0, 200)
    Root.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
    Root.BackgroundTransparency = 0.05
    Root.BorderSizePixel = 0
    Root.ClipsDescendants = true
    Root.Name = "Root"
    Root.Parent = ScreenGui

    local RootCorner = Instance.new("UICorner")
    RootCorner.CornerRadius = UDim.new(0, 8)
    RootCorner.Parent = Root

    local RootStroke = Instance.new("UIStroke")
    RootStroke.Color = PanelConfig.Color
    RootStroke.Thickness = 1
    RootStroke.Transparency = 0.6
    RootStroke.Parent = Root

    local Header = Instance.new("Frame")
    Header.Size = UDim2.new(1, 0, 0, 32)
    Header.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Header.BackgroundTransparency = 0.94
    Header.BorderSizePixel = 0
    Header.Name = "Header"
    Header.Parent = Root

    local HeaderCorner = Instance.new("UICorner")
    HeaderCorner.CornerRadius = UDim.new(0, 8)
    HeaderCorner.Parent = Header

    local HeaderFix = Instance.new("Frame")
    HeaderFix.Position = UDim2.new(0, 0, 1, -8)
    HeaderFix.Size = UDim2.new(1, 0, 0, 8)
    HeaderFix.BackgroundColor3 = Header.BackgroundColor3
    HeaderFix.BackgroundTransparency = Header.BackgroundTransparency
    HeaderFix.BorderSizePixel = 0
    HeaderFix.Parent = Header

    local TitleLbl = Instance.new("TextLabel")
    TitleLbl.Font = Enum.Font.GothamBold
    TitleLbl.Text = PanelConfig.Title
    TitleLbl.TextColor3 = PanelConfig.Color
    TitleLbl.TextSize = 13
    TitleLbl.TextXAlignment = Enum.TextXAlignment.Left
    TitleLbl.BackgroundTransparency = 1
    TitleLbl.Position = UDim2.new(0, 10, 0, 0)
    TitleLbl.Size = UDim2.new(1, -70, 1, 0)
    TitleLbl.Parent = Header

    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.Text = "x"
    CloseBtn.TextColor3 = Color3.fromRGB(255, 107, 107)
    CloseBtn.TextSize = 14
    CloseBtn.AnchorPoint = Vector2.new(1, 0.5)
    CloseBtn.Position = UDim2.new(1, -6, 0.5, 0)
    CloseBtn.BackgroundColor3 = Color3.fromRGB(226, 75, 74)
    CloseBtn.BackgroundTransparency = 0.88
    CloseBtn.Size = UDim2.new(0, 22, 0, 22)
    CloseBtn.Parent = Header

    local CloseCorner = Instance.new("UICorner")
    CloseCorner.CornerRadius = UDim.new(0, 5)
    CloseCorner.Parent = CloseBtn

    local MinBtn = Instance.new("TextButton")
    MinBtn.Font = Enum.Font.GothamBold
    MinBtn.Text = "_"
    MinBtn.TextColor3 = PanelConfig.Color
    MinBtn.TextSize = 14
    MinBtn.AnchorPoint = Vector2.new(1, 0.5)
    MinBtn.Position = UDim2.new(1, -32, 0.5, 0)
    MinBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    MinBtn.BackgroundTransparency = 0.9
    MinBtn.Size = UDim2.new(0, 22, 0, 22)
    MinBtn.Parent = Header

    local MinCorner = Instance.new("UICorner")
    MinCorner.CornerRadius = UDim.new(0, 5)
    MinCorner.Parent = MinBtn

    local Body = Instance.new("ScrollingFrame")
    Body.Position = UDim2.new(0, 0, 0, 34)
    Body.Size = UDim2.new(1, 0, 1, -36)
    Body.BackgroundTransparency = 1
    Body.BorderSizePixel = 0
    Body.ScrollBarThickness = 3
    Body.ScrollBarImageColor3 = PanelConfig.Color
    Body.CanvasSize = UDim2.new(0, 0, 0, 0)
    Body.Name = "Body"
    Body.Parent = Root

    local BodyPad = Instance.new("UIPadding")
    BodyPad.PaddingTop = UDim.new(0, 6)
    BodyPad.PaddingBottom = UDim.new(0, 6)
    BodyPad.PaddingLeft = UDim.new(0, 8)
    BodyPad.PaddingRight = UDim.new(0, 8)
    BodyPad.Parent = Body

    local BodyList = Instance.new("UIListLayout")
    BodyList.Padding = UDim.new(0, 6)
    BodyList.SortOrder = Enum.SortOrder.LayoutOrder
    BodyList.Parent = Body

    BodyList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        Body.CanvasSize = UDim2.new(0, 0, 0, BodyList.AbsoluteContentSize.Y + 12)
    end)

    -- Status block (mode, sprinkler status, SWC status)
    local StatusLbl = Instance.new("TextLabel")
    StatusLbl.Font = Enum.Font.Gotham
    StatusLbl.Text = "Idle"
    StatusLbl.TextColor3 = Color3.fromRGB(220, 220, 220)
    StatusLbl.TextSize = 11
    StatusLbl.TextWrapped = true
    StatusLbl.TextXAlignment = Enum.TextXAlignment.Left
    StatusLbl.TextYAlignment = Enum.TextYAlignment.Top
    StatusLbl.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    StatusLbl.BackgroundTransparency = 0.94
    StatusLbl.LayoutOrder = 0
    StatusLbl.Size = UDim2.new(1, 0, 0, 40)
    StatusLbl.Name = "StatusLbl"
    StatusLbl.Parent = Body

    local StatusCorner = Instance.new("UICorner")
    StatusCorner.CornerRadius = UDim.new(0, 4)
    StatusCorner.Parent = StatusLbl

    local StatusPad = Instance.new("UIPadding")
    StatusPad.PaddingTop = UDim.new(0, 4)
    StatusPad.PaddingLeft = UDim.new(0, 6)
    StatusPad.PaddingRight = UDim.new(0, 6)
    StatusPad.Parent = StatusLbl

    local function ResizeStatus()
        task.defer(function()
            StatusLbl.TextWrapped = true
            local h = math.max(20, StatusLbl.TextBounds.Y + 8)
            StatusLbl.Size = UDim2.new(1, 0, 0, h)
        end)
    end

    local progressRows = {}
    local progressOrder = {}

    local function KeyFor(seedName, kg)
        return seedName .. "_" .. tostring(kg)
    end

    local Panel = {}

    function Panel:UpdateStatus(text)
        StatusLbl.Text = text or ""
        ResizeStatus()
    end

    function Panel:UpdateProgress(seedName, kg, done, total)
        done = math.max(0, tonumber(done) or 0)
        total = math.max(0, tonumber(total) or 0)
        local left = math.max(0, total - done)
        local key = KeyFor(seedName, kg)

        local row = progressRows[key]
        if not row then
            row = Instance.new("Frame")
            row.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            row.BackgroundTransparency = 0.94
            row.Size = UDim2.new(1, 0, 0, 34)
            row.LayoutOrder = #progressOrder + 1
            row.Name = key
            row.Parent = Body

            local RowCorner = Instance.new("UICorner")
            RowCorner.CornerRadius = UDim.new(0, 4)
            RowCorner.Parent = row

            local NameLbl = Instance.new("TextLabel")
            NameLbl.Font = Enum.Font.GothamBold
            NameLbl.TextColor3 = Color3.fromRGB(230, 230, 230)
            NameLbl.TextSize = 11
            NameLbl.TextXAlignment = Enum.TextXAlignment.Left
            NameLbl.BackgroundTransparency = 1
            NameLbl.Position = UDim2.new(0, 6, 0, 3)
            NameLbl.Size = UDim2.new(1, -12, 0, 12)
            NameLbl.Name = "NameLbl"
            NameLbl.Parent = row

            local BarBg = Instance.new("Frame")
            BarBg.Position = UDim2.new(0, 6, 0, 19)
            BarBg.Size = UDim2.new(1, -12, 0, 6)
            BarBg.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            BarBg.BackgroundTransparency = 0.85
            BarBg.BorderSizePixel = 0
            BarBg.Name = "BarBg"
            BarBg.Parent = row

            local BarBgCorner = Instance.new("UICorner")
            BarBgCorner.CornerRadius = UDim.new(1, 0)
            BarBgCorner.Parent = BarBg

            local BarFill = Instance.new("Frame")
            BarFill.Size = UDim2.new(0, 0, 1, 0)
            BarFill.BackgroundColor3 = PanelConfig.Color
            BarFill.BorderSizePixel = 0
            BarFill.Name = "BarFill"
            BarFill.Parent = BarBg

            local BarFillCorner = Instance.new("UICorner")
            BarFillCorner.CornerRadius = UDim.new(1, 0)
            BarFillCorner.Parent = BarFill

            row.Parent = Body
            progressRows[key] = { row = row, nameLbl = NameLbl, barFill = BarFill }
            table.insert(progressOrder, key)
        end

        local r = progressRows[key]
        r.nameLbl.Text = string.format("%s %sx \xE2\x89\xA5%dkg  |  done: %d, %d left", seedName, tostring(total), kg, done, left)

        local pct = total > 0 and math.clamp(done / total, 0, 1) or 0
        TweenService:Create(r.barFill, TweenInfo.new(0.2), { Size = UDim2.new(pct, 0, 1, 0) }):Play()
    end

    function Panel:ClearProgress()
        for _, data in pairs(progressRows) do
            if data.row and data.row.Parent then data.row:Destroy() end
        end
        progressRows = {}
        progressOrder = {}
    end

    function Panel:Destroy()
        ScreenGui:Destroy()
    end

    local minimized = false
    local expandedSize = Root.Size
    MinBtn.Activated:Connect(function()
        minimized = not minimized
        if minimized then
            Root.Size = UDim2.new(0, expandedSize.X.Offset, 0, 34)
        else
            Root.Size = expandedSize
        end
    end)

    CloseBtn.Activated:Connect(function()
        Panel:Destroy()
    end)

    MakeDraggable(Header, Root)

    return Panel
end

return Chloex
