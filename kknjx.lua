jgn pakai file kocak jgn create file lgsg aja before after full function sensitif spacing no commentatorOke, langsung full function, tanpa file, tanpa komentar tambahan.
BEFORE (full AddFruitTargetList):
lua            function Items:AddFruitTargetList(FruitTargetConfig)
    FruitTargetConfig = FruitTargetConfig or {}
    FruitTargetConfig.Title = FruitTargetConfig.Title or "Fruit Targets"
    FruitTargetConfig.SeedOptions = FruitTargetConfig.SeedOptions or {}
    FruitTargetConfig.OnAdd = FruitTargetConfig.OnAdd or function(entry) end
    FruitTargetConfig.OnRemove = FruitTargetConfig.OnRemove or function(entry) end
    FruitTargetConfig.OnChange = FruitTargetConfig.OnChange or function(list) end

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

    local InputBlock = Instance.new("Frame")
    InputBlock.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    InputBlock.BackgroundTransparency = 0.965
    InputBlock.Size = UDim2.new(1, 0, 0, 40)
    InputBlock.LayoutOrder = 1
    InputBlock.Name = "InputBlock"
    InputBlock.Parent = Root

    local InputCorner = Instance.new("UICorner")
    InputCorner.CornerRadius = UDim.new(0, 6)
    InputCorner.Parent = InputBlock

    local InputPad = Instance.new("UIPadding")
    InputPad.PaddingTop = UDim.new(0, 8)
    InputPad.PaddingBottom = UDim.new(0, 8)
    InputPad.PaddingLeft = UDim.new(0, 8)
    InputPad.PaddingRight = UDim.new(0, 8)
    InputPad.Parent = InputBlock

    local InputList = Instance.new("UIListLayout")
    InputList.Padding = UDim.new(0, 6)
    InputList.SortOrder = Enum.SortOrder.LayoutOrder
    InputList.Parent = InputBlock

    local InputTitle = Instance.new("TextLabel")
    InputTitle.Font = Enum.Font.GothamBold
    InputTitle.Text = FruitTargetConfig.Title
    InputTitle.TextColor3 = GuiConfig.Color
    InputTitle.TextSize = 13
    InputTitle.TextXAlignment = Enum.TextXAlignment.Left
    InputTitle.BackgroundTransparency = 1
    InputTitle.Size = UDim2.new(1, 0, 0, 14)
    InputTitle.LayoutOrder = 0
    InputTitle.Parent = InputBlock

    local SeedPickRow = Instance.new("Frame")
    SeedPickRow.BackgroundTransparency = 1
    SeedPickRow.Size = UDim2.new(1, 0, 0, 26)
    SeedPickRow.LayoutOrder = 1
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
    ValuesRow.LayoutOrder = 2
    ValuesRow.Parent = InputBlock

    local ValuesLayout = Instance.new("UIListLayout")
    ValuesLayout.FillDirection = Enum.FillDirection.Horizontal
    ValuesLayout.Padding = UDim.new(0, 6)
    ValuesLayout.Parent = ValuesRow

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
    KgBox.Size = UDim2.new(0.35, -4, 1, 0)
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
    CountBox.Size = UDim2.new(0.35, -4, 1, 0)
    CountBox.Parent = ValuesRow
    local CountBoxCorner = Instance.new("UICorner")
    CountBoxCorner.CornerRadius = UDim.new(0, 4)
    CountBoxCorner.Parent = CountBox
    local CountBoxPad = Instance.new("UIPadding")
    CountBoxPad.PaddingLeft = UDim.new(0, 6)
    CountBoxPad.Parent = CountBox

    local AddEntryBtn = Instance.new("TextButton")
    AddEntryBtn.Font = Enum.Font.GothamBold
    AddEntryBtn.Text = "+ Add"
    AddEntryBtn.TextSize = 12
    AddEntryBtn.TextColor3 = GuiConfig.Color
    AddEntryBtn.BackgroundColor3 = GuiConfig.Color
    AddEntryBtn.BackgroundTransparency = 0.88
    AddEntryBtn.Size = UDim2.new(0.3, -4, 1, 0)
    AddEntryBtn.Parent = ValuesRow
    local AddEntryCorner = Instance.new("UICorner")
    AddEntryCorner.CornerRadius = UDim.new(0, 4)
    AddEntryCorner.Parent = AddEntryBtn

    SeedPickBtn.Activated:Connect(function()
        CircleClick(SeedPickBtn, Mouse.X, Mouse.Y)
        local listItems = {}
        for _, optName in ipairs(FruitTargetConfig.SeedOptions) do
            table.insert(listItems, { Name = optName, Stock = nil })
        end
        local selectedSet = {}
        if selectedSeedName then selectedSet[selectedSeedName] = true end
        ShowInventoryPicker({
            Title = "Pilih Seed",
            Items = listItems,
            SelectedSet = selectedSet,
            Color = GuiConfig.Color,
            ShowStock = false,
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

    local ListFrame = Instance.new("Frame")
    ListFrame.BackgroundTransparency = 1
    ListFrame.Size = UDim2.new(1, 0, 0, 0)
    ListFrame.LayoutOrder = 2
    ListFrame.Name = "FruitTargetListFrame"
    ListFrame.Parent = Root

    local ListLayout2 = Instance.new("UIListLayout")
    ListLayout2.Padding = UDim.new(0, 4)
    ListLayout2.SortOrder = Enum.SortOrder.LayoutOrder
    ListLayout2.Parent = ListFrame

    local function ResizeListFrame()
        task.defer(function()
            local h = 0
            for _, c in ListFrame:GetChildren() do
                if c:IsA("GuiObject") then h = h + c.Size.Y.Offset + 4 end
            end
            ListFrame.Size = UDim2.new(1, 0, 0, h)
            ResizeRoot()
        end)
    end

    local entryRows = {}

    local function RenderEntryRow(entry, index)
        local Row = Instance.new("Frame")
        Row.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        Row.BackgroundTransparency = 0.965
        Row.Size = UDim2.new(1, 0, 0, 30)
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
        NameLbl.Position = UDim2.new(0, 8, 0, 3)
        NameLbl.Size = UDim2.new(0.45, 0, 0, 12)
        NameLbl.Parent = Row

        local DetailLbl = Instance.new("TextLabel")
        DetailLbl.Font = Enum.Font.Gotham
        DetailLbl.Text = string.format("%sx  \xE2\x89\xA5%skg", tostring(entry.Count), tostring(entry.Kg))
        DetailLbl.TextColor3 = GuiConfig.Color
        DetailLbl.TextSize = 10
        DetailLbl.TextXAlignment = Enum.TextXAlignment.Left
        DetailLbl.BackgroundTransparency = 1
        DetailLbl.Position = UDim2.new(0, 8, 0, 16)
        DetailLbl.Size = UDim2.new(0.45, 0, 0, 10)
        DetailLbl.Parent = Row

        local RemoveBtn = MakeIconButton(Row, "x", 20, Color3.fromRGB(255, 107, 107))
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

    function FruitTargetFunc:Set(newEntries, noSave)
        State.Entries = type(newEntries) == "table" and newEntries or {}
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
    ResizeRoot()

    if shouldSave then
        Elements[configKey] = FruitTargetFunc
    end
    RegisterSearch({ label = FruitTargetConfig.Title, tab = TabConfig.Name, kind = "FruitTargetList", switch = SearchSwitch })

    CountItem = CountItem + 1
    return FruitTargetFunc
end

AFTER (full AddFruitTargetList):
lua            function Items:AddFruitTargetList(FruitTargetConfig)
    FruitTargetConfig = FruitTargetConfig or {}
    FruitTargetConfig.Title = FruitTargetConfig.Title or "Fruit Targets"
    FruitTargetConfig.SeedOptions = FruitTargetConfig.SeedOptions or {}
    FruitTargetConfig.OnAdd = FruitTargetConfig.OnAdd or function(entry) end
    FruitTargetConfig.OnRemove = FruitTargetConfig.OnRemove or function(entry) end
    FruitTargetConfig.OnChange = FruitTargetConfig.OnChange or function(list) end

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

    local InputBlock = Instance.new("Frame")
    InputBlock.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    InputBlock.BackgroundTransparency = 0.965
    InputBlock.Size = UDim2.new(1, 0, 0, 40)
    InputBlock.LayoutOrder = 1
    InputBlock.Name = "InputBlock"
    InputBlock.Parent = Root

    local InputCorner = Instance.new("UICorner")
    InputCorner.CornerRadius = UDim.new(0, 6)
    InputCorner.Parent = InputBlock

    local InputPad = Instance.new("UIPadding")
    InputPad.PaddingTop = UDim.new(0, 8)
    InputPad.PaddingBottom = UDim.new(0, 8)
    InputPad.PaddingLeft = UDim.new(0, 8)
    InputPad.PaddingRight = UDim.new(0, 8)
    InputPad.Parent = InputBlock

    local InputList = Instance.new("UIListLayout")
    InputList.Padding = UDim.new(0, 6)
    InputList.SortOrder = Enum.SortOrder.LayoutOrder
    InputList.Parent = InputBlock

    local InputTitle = Instance.new("TextLabel")
    InputTitle.Font = Enum.Font.GothamBold
    InputTitle.Text = FruitTargetConfig.Title
    InputTitle.TextColor3 = GuiConfig.Color
    InputTitle.TextSize = 13
    InputTitle.TextXAlignment = Enum.TextXAlignment.Left
    InputTitle.BackgroundTransparency = 1
    InputTitle.Size = UDim2.new(1, 0, 0, 14)
    InputTitle.LayoutOrder = 0
    InputTitle.Parent = InputBlock

    local SeedPickRow = Instance.new("Frame")
    SeedPickRow.BackgroundTransparency = 1
    SeedPickRow.Size = UDim2.new(1, 0, 0, 26)
    SeedPickRow.LayoutOrder = 1
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
    ValuesRow.LayoutOrder = 2
    ValuesRow.Parent = InputBlock

    local ValuesLayout = Instance.new("UIListLayout")
    ValuesLayout.FillDirection = Enum.FillDirection.Horizontal
    ValuesLayout.Padding = UDim.new(0, 6)
    ValuesLayout.Parent = ValuesRow

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
            table.insert(listItems, { Name = optName, Stock = nil })
        end
        local selectedSet = {}
        if selectedSeedName then selectedSet[selectedSeedName] = true end
        ShowInventoryPicker({
            Title = "Pilih Seed",
            Items = listItems,
            SelectedSet = selectedSet,
            Color = GuiConfig.Color,
            ShowStock = false,
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

    local ListFrame = Instance.new("Frame")
    ListFrame.BackgroundTransparency = 1
    ListFrame.Size = UDim2.new(1, 0, 0, 0)
    ListFrame.LayoutOrder = 2
    ListFrame.Name = "FruitTargetListFrame"
    ListFrame.Parent = Root

    local ListLayout2 = Instance.new("UIListLayout")
    ListLayout2.Padding = UDim.new(0, 4)
    ListLayout2.SortOrder = Enum.SortOrder.LayoutOrder
    ListLayout2.Parent = ListFrame

    local function ResizeListFrame()
        task.defer(function()
            local h = 0
            for _, c in ListFrame:GetChildren() do
                if c:IsA("GuiObject") then h = h + c.Size.Y.Offset + 4 end
            end
            ListFrame.Size = UDim2.new(1, 0, 0, h)
            ResizeRoot()
        end)
    end

    local entryRows = {}

    local function RenderEntryRow(entry, index)
        local Row = Instance.new("Frame")
        Row.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        Row.BackgroundTransparency = 0.965
        Row.Size = UDim2.new(1, 0, 0, 30)
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
        NameLbl.Position = UDim2.new(0, 8, 0, 3)
        NameLbl.Size = UDim2.new(1, -120, 0, 12)
        NameLbl.Parent = Row

        local DetailLbl = Instance.new("TextLabel")
        DetailLbl.Font = Enum.Font.Gotham
        DetailLbl.Text = string.format("%sx  \xE2\x89\xA5%skg", tostring(entry.Count), tostring(entry.Kg))
        DetailLbl.TextColor3 = GuiConfig.Color
        DetailLbl.TextSize = 10
        DetailLbl.TextXAlignment = Enum.TextXAlignment.Left
        DetailLbl.BackgroundTransparency = 1
        DetailLbl.Position = UDim2.new(0, 8, 0, 16)
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

    function FruitTargetFunc:Set(newEntries, noSave)
        State.Entries = type(newEntries) == "table" and newEntries or {}
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
    ResizeRoot()

    if shouldSave then
        Elements[configKey] = FruitTargetFunc
    end
    RegisterSearch({ label = FruitTargetConfig.Title, tab = TabConfig.Name, kind = "FruitTargetList", switch = SearchSwitch })

    CountItem = CountItem + 1
    return FruitTargetFunc
end
Tinggal replace fungsi lamanya dengan yang AFTER di atas.
