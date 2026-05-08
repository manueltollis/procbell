local _, ns = ...

local mainFrame
local rowPool = {}
local currentTab = "cast"

local ROW_HEIGHT = 36

local function GetOrCreateRow(parent, index)
    local row = rowPool[index]
    if row then return row end

    row = CreateFrame("Frame", nil, parent)
    row:SetSize(460, 32)

    local icon = row:CreateTexture(nil, "ARTWORK")
    icon:SetSize(24, 24)
    icon:SetPoint("LEFT", 0, 0)
    row.icon = icon

    local label = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("LEFT", icon, "RIGHT", 6, 0)
    label:SetWidth(150)
    label:SetJustifyH("LEFT")
    row.label = label

    -- Unique global name per pool slot, reused across refreshes.
    local dd = CreateFrame("Frame", "ProcBellDropdown" .. index, row, "UIDropDownMenuTemplate")
    dd:SetPoint("LEFT", label, "RIGHT", -6, -2)
    UIDropDownMenu_SetWidth(dd, 170)
    row.dd = dd

    local play = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
    play:SetSize(28, 22)
    play:SetPoint("LEFT", dd, "RIGHT", -6, 2)
    play:SetText("|cffffd200>|r")
    row.play = play

    local rm = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
    rm:SetSize(28, 22)
    rm:SetPoint("LEFT", play, "RIGHT", 4, 0)
    rm:SetText("X")
    row.rm = rm

    rowPool[index] = row
    return row
end

local function ConfigureRow(row, triggerType, spellID, index)
    row:ClearAllPoints()
    row:SetPoint("TOPLEFT", 0, -((index - 1) * ROW_HEIGHT))
    row:Show()
    row.spellID = spellID
    row.triggerType = triggerType

    local spellName, iconID = ns.GetSpellNameAndIcon(spellID)
    spellName = spellName or ("Spell " .. spellID)
    iconID = iconID or 134400

    row.icon:SetTexture(iconID)
    row.label:SetText(spellName .. " |cff999999(" .. spellID .. ")|r")

    UIDropDownMenu_Initialize(row.dd, function(_, level)
        local all = ns.GetAllSounds and ns.GetAllSounds() or ns.sounds or {}
        for _, s in ipairs(all) do
            local entry = UIDropDownMenu_CreateInfo()
            entry.text = s.name
            local cur = ns.GetBinding(row.triggerType, row.spellID)
            entry.checked = cur and cur.source == s.source and cur.kind == s.kind
            entry.func = function()
                ns.SetBinding(row.triggerType, row.spellID, s)
                UIDropDownMenu_SetText(row.dd, s.name)
                CloseDropDownMenus()
            end
            UIDropDownMenu_AddButton(entry, level)
        end
    end)

    local cur = ns.GetBinding(triggerType, spellID)
    UIDropDownMenu_SetText(row.dd, cur and cur.name or "<choose>")

    row.play:SetScript("OnClick", function()
        ns.PlayBoundSound(ns.GetBinding(row.triggerType, row.spellID))
    end)
    row.rm:SetScript("OnClick", function()
        ns.RemoveBinding(row.triggerType, row.spellID)
        ns.RefreshUI()
    end)
end

local function HideUnusedRows(from)
    for i = from, #rowPool do
        rowPool[i]:Hide()
    end
end

local function BuildFrame()
    local f = CreateFrame("Frame", "ProcBellConfigFrame", UIParent, "BasicFrameTemplateWithInset")
    f:SetSize(560, 460)
    f:SetPoint("CENTER")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:SetClampedToScreen(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:SetFrameStrata("HIGH")
    f:Hide()

    if f.SetTitle then
        f:SetTitle("ProcBell")
    elseif f.TitleText then
        f.TitleText:SetText("ProcBell")
    elseif f.TitleContainer and f.TitleContainer.TitleText then
        f.TitleContainer.TitleText:SetText("ProcBell")
    else
        local t = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        t:SetPoint("TOP", 0, -6)
        t:SetText("ProcBell")
    end

    local castTab = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    castTab:SetSize(96, 22)
    castTab:SetPoint("TOPLEFT", 16, -32)
    castTab:SetText("Spell Casts")
    f.castTab = castTab

    local auraTab = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    auraTab:SetSize(96, 22)
    auraTab:SetPoint("LEFT", castTab, "RIGHT", 4, 0)
    auraTab:SetText("Auras")
    f.auraTab = auraTab

    local hint = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    hint:SetPoint("TOPLEFT", 16, -64)
    f.hint = hint

    local input = CreateFrame("EditBox", nil, f, "InputBoxTemplate")
    input:SetPoint("LEFT", hint, "RIGHT", 12, 0)
    input:SetSize(80, 22)
    input:SetAutoFocus(false)
    input:SetNumeric(true)
    f.input = input

    local addBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    addBtn:SetSize(80, 22)
    addBtn:SetPoint("LEFT", input, "RIGHT", 8, 0)
    addBtn:SetText("Add")
    f.addBtn = addBtn

    local function tryAdd()
        local id = tonumber(input:GetText())
        if id and id > 0 then
            ns.AddBinding(currentTab, id)
            input:SetText("")
            input:ClearFocus()
            ns.RefreshUI()
        end
    end
    addBtn:SetScript("OnClick", tryAdd)
    input:SetScript("OnEnterPressed", tryAdd)

    local scroll = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 16, -96)
    scroll:SetPoint("BOTTOMRIGHT", -36, 16)

    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(470, 360)
    scroll:SetScrollChild(content)
    f.content = content
    f.scroll = scroll

    local empty = content:CreateFontString(nil, "OVERLAY", "GameFontDisable")
    empty:SetPoint("TOP", 0, -16)
    f.empty = empty

    castTab:SetScript("OnClick", function() ns.SetTab("cast") end)
    auraTab:SetScript("OnClick", function() ns.SetTab("aura") end)

    return f
end

function ns.SetTab(t)
    currentTab = t
    if not mainFrame then return end
    mainFrame.castTab:SetEnabled(t ~= "cast")
    mainFrame.auraTab:SetEnabled(t ~= "aura")
    mainFrame.hint:SetText(t == "aura" and "Add aura by spell ID:" or "Add spell cast by ID:")
    mainFrame.empty:SetText(t == "aura"
        and "No auras configured. Type an aura's spell ID above and click Add."
        or "No spell casts configured. Type a spell ID above and click Add.")
    ns.RefreshUI()
end

function ns.RefreshUI()
    if not mainFrame then return end

    local list = {}
    if ns.IterBindings then
        for spellID in ns.IterBindings(currentTab) do
            list[#list + 1] = spellID
        end
    end
    table.sort(list)

    for i, spellID in ipairs(list) do
        local row = GetOrCreateRow(mainFrame.content, i)
        ConfigureRow(row, currentTab, spellID, i)
    end
    HideUnusedRows(#list + 1)

    mainFrame.empty:SetShown(#list == 0)
    mainFrame.content:SetHeight(math.max(360, #list * ROW_HEIGHT + 8))
end

function ns.OpenUI()
    if not mainFrame then
        mainFrame = BuildFrame()
        ns.SetTab(currentTab)
    end
    if mainFrame:IsShown() then
        mainFrame:Hide()
    else
        mainFrame:Show()
        ns.RefreshUI()
    end
end

