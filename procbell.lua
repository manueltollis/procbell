local addonName, ns = ...

local LSM_TYPE = "sound"
local LSM_VISUAL_TYPES = { "statusbar", "border", "background" }

local function lsm()
    return LibStub and LibStub("LibSharedMedia-3.0", true) or nil
end

local function loadDB()
    if type(ProcBellDB) ~= "table" then ProcBellDB = {} end
    if type(ProcBellDB.spellBindings) ~= "table" then ProcBellDB.spellBindings = {} end
    if type(ProcBellDB.auraBindings)  ~= "table" then ProcBellDB.auraBindings  = {} end
    if type(ProcBellDB.visualPosition) ~= "table" then
        ProcBellDB.visualPosition = { point = "CENTER", relativePoint = "CENTER", x = 0, y = 120 }
    end
    if type(ProcBellDB.visualSize) ~= "table" then
        ProcBellDB.visualSize = { width = 256, height = 256 }
    end

    -- First-run seed: bind Ray of Frost to the bundled sound.
    if next(ProcBellDB.spellBindings) == nil and next(ProcBellDB.auraBindings) == nil then
        ProcBellDB.spellBindings[205021] = {
            name = "ProcBell",
            kind = "file",
            source = "Interface\\AddOns\\procbell\\procbell.ogg",
        }
    end
end

local function bindingTable(triggerType)
    if triggerType == "aura" then return ProcBellDB.auraBindings end
    return ProcBellDB.spellBindings
end

function ns.PlayBoundSound(binding)
    if not binding then return end
    if binding.kind == "lsm" then
        local LSM = lsm()
        if not LSM then return end
        local file = LSM:Fetch(LSM_TYPE, binding.source)
        if file then return PlaySoundFile(file, "Master") end
    elseif binding.kind == "file" then
        return PlaySoundFile(binding.source, "Master")
    elseif binding.kind == "soundkit" then
        return PlaySound(binding.source, "Master")
    end
end

function ns.GetBinding(triggerType, spellID)
    local t = bindingTable(triggerType)
    return t and t[spellID] or nil
end

function ns.SetBinding(triggerType, spellID, sound)
    local t = bindingTable(triggerType)
    if not t then return end
    -- Preserve any existing visual sub-binding when overwriting the sound.
    local existing = t[spellID]
    t[spellID] = {
        name = sound.name,
        kind = sound.kind,
        source = sound.source,
        visual = existing and existing.visual or nil,
    }
end

function ns.GetVisualBinding(triggerType, spellID)
    local b = ns.GetBinding(triggerType, spellID)
    return b and b.visual or nil
end

function ns.SetVisualBinding(triggerType, spellID, visual)
    local b = ns.GetBinding(triggerType, spellID)
    if not b then return end
    if visual then
        b.visual = {
            name = visual.name,
            kind = visual.kind,
            source = visual.source,
            cols = visual.cols,
            rows = visual.rows,
            frameCount = visual.frameCount,
            fps = visual.fps,
        }
    else
        b.visual = nil
    end
end

function ns.RemoveVisualBinding(triggerType, spellID)
    ns.SetVisualBinding(triggerType, spellID, nil)
end

function ns.RemoveBinding(triggerType, spellID)
    local t = bindingTable(triggerType)
    if t then t[spellID] = nil end
end

function ns.AddBinding(triggerType, spellID)
    local t = bindingTable(triggerType)
    if not t or t[spellID] ~= nil then return end
    local default = ns.sounds and ns.sounds[1]
    if default then ns.SetBinding(triggerType, spellID, default) end
end

function ns.IterBindings(triggerType)
    local t = bindingTable(triggerType)
    return pairs(t or {})
end

-- Built-in registry (Sounds.lua) + every sound registered into
-- LibSharedMedia-3.0 by any other addon (including SharedMedia_MyMedia).
function ns.GetAllSounds()
    local out = {}
    if ns.sounds then
        for _, s in ipairs(ns.sounds) do
            out[#out + 1] = s
        end
    end
    local LSM = lsm()
    if LSM then
        for _, name in ipairs(LSM:List(LSM_TYPE)) do
            if name ~= "None" then
                out[#out + 1] = { name = name, kind = "lsm", source = name }
            end
        end
    end
    return out
end

-- Built-in registry (Visuals.lua) + every texture registered into
-- LibSharedMedia-3.0 by any other addon, across statusbar/border/background.
function ns.GetAllVisuals()
    local out = {}
    if ns.visuals then
        for _, v in ipairs(ns.visuals) do
            out[#out + 1] = v
        end
    end
    local LSM = lsm()
    if LSM then
        for _, lsmType in ipairs(LSM_VISUAL_TYPES) do
            for _, name in ipairs(LSM:List(lsmType)) do
                if name ~= "None" then
                    out[#out + 1] = {
                        name = name .. " (" .. lsmType .. ")",
                        kind = "lsm",
                        source = name,
                    }
                end
            end
        end
    end
    return out
end

local pulseFrame
local moveMode = false

local function applyVisualPosition(f)
    local pos = ProcBellDB and ProcBellDB.visualPosition
    f:ClearAllPoints()
    if pos then
        f:SetPoint(pos.point or "CENTER", UIParent, pos.relativePoint or "CENTER", pos.x or 0, pos.y or 120)
    else
        f:SetPoint("CENTER", UIParent, "CENTER", 0, 120)
    end
end

local function applyVisualSize(f)
    local sz = ProcBellDB and ProcBellDB.visualSize
    if sz then
        f:SetSize(sz.width or 256, sz.height or 256)
    else
        f:SetSize(256, 256)
    end
end

local function ensurePulseFrame()
    if pulseFrame then return pulseFrame end
    local f = CreateFrame("Frame", nil, UIParent)
    applyVisualSize(f)
    applyVisualPosition(f)
    f:SetFrameStrata("HIGH")
    f:SetClampedToScreen(true)
    if f.SetResizeBounds then
        f:SetResizeBounds(64, 64, 1024, 1024)
    end
    f:Hide()

    -- Edit-mode overlay: only shown while moving the frame. Lets the user see
    -- and grab the otherwise-invisible visual region.
    local editBg = f:CreateTexture(nil, "BACKGROUND")
    editBg:SetAllPoints(f)
    editBg:SetColorTexture(0.2, 0.5, 1, 0.35)
    editBg:Hide()
    f.editBg = editBg

    local editLabel = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    editLabel:SetPoint("CENTER", 0, -22)
    editLabel:SetText("ProcBell\n(drag to move, grip to resize)")
    editLabel:SetJustifyH("CENTER")
    editLabel:Hide()
    f.editLabel = editLabel

    local sizeLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    sizeLabel:SetPoint("CENTER", 0, 12)
    sizeLabel:SetJustifyH("CENTER")
    sizeLabel:Hide()
    f.sizeLabel = sizeLabel

    local function refreshSizeLabel(self)
        self.sizeLabel:SetFormattedText("%d x %d", math.floor(self:GetWidth() + 0.5), math.floor(self:GetHeight() + 0.5))
    end
    f:SetScript("OnSizeChanged", refreshSizeLabel)
    refreshSizeLabel(f)

    local grip = CreateFrame("Button", nil, f)
    grip:SetSize(16, 16)
    grip:SetPoint("BOTTOMRIGHT", -2, 2)
    grip:SetFrameLevel(f:GetFrameLevel() + 5)
    local gripTex = grip:CreateTexture(nil, "OVERLAY")
    gripTex:SetAllPoints(grip)
    gripTex:SetColorTexture(1, 1, 1, 0.85)
    grip:SetScript("OnMouseDown", function()
        if not moveMode then return end
        f:StartSizing("BOTTOMRIGHT")
    end)
    grip:SetScript("OnMouseUp", function()
        f:StopMovingOrSizing()
        local w, h = f:GetWidth(), f:GetHeight()
        ProcBellDB.visualSize = { width = math.floor(w + 0.5), height = math.floor(h + 0.5) }
        local point, _, relPoint, x, y = f:GetPoint()
        ProcBellDB.visualPosition = {
            point = point or "CENTER",
            relativePoint = relPoint or "CENTER",
            x = x or 0,
            y = y or 0,
        }
    end)
    grip:Hide()
    f.grip = grip

    local tex = f:CreateTexture(nil, "OVERLAY")
    tex:SetAllPoints(f)
    tex:SetBlendMode("BLEND")
    f.tex = tex

    -- Static-image alpha pulse (used for kind="file"/"lsm").
    local ag = f:CreateAnimationGroup()

    local fadeIn = ag:CreateAnimation("Alpha")
    fadeIn:SetFromAlpha(0)
    fadeIn:SetToAlpha(1)
    fadeIn:SetDuration(0.18)
    fadeIn:SetOrder(1)

    local fadeOut = ag:CreateAnimation("Alpha")
    fadeOut:SetFromAlpha(1)
    fadeOut:SetToAlpha(0)
    fadeOut:SetDuration(0.5)
    fadeOut:SetStartDelay(0.35)
    fadeOut:SetOrder(2)

    ag:SetScript("OnFinished", function() f:Hide() end)

    f.ag = ag

    -- Spritesheet stepper. Driven by OnUpdate; advances the texcoord window
    -- once `elapsed` crosses the next frame's threshold. play-once: hides
    -- the frame after the last frame's display time.
    f.sprite = { active = false }
    f:SetScript("OnUpdate", function(self, dt)
        local s = self.sprite
        if not s.active then return end
        s.elapsed = s.elapsed + dt
        local target = math.floor(s.elapsed * s.fps)
        if target >= s.count then
            s.active = false
            self:Hide()
            return
        end
        if target ~= s.frame then
            s.frame = target
            local col = target % s.cols
            local row = math.floor(target / s.cols)
            self.tex:SetTexCoord(
                col / s.cols, (col + 1) / s.cols,
                row / s.rows, (row + 1) / s.rows
            )
        end
    end)

    pulseFrame = f
    return f
end

local function resolveVisualSource(visual)
    if visual.kind == "file" then return visual.source end
    if visual.kind == "lsm" then
        local LSM = lsm()
        if not LSM then return nil end
        for _, lsmType in ipairs(LSM_VISUAL_TYPES) do
            local file = LSM:Fetch(lsmType, visual.source, true)
            if file then return file end
        end
    end
    return nil
end

function ns.PlayBoundVisual(visual)
    if not visual then return end
    if moveMode then return end

    if visual.kind == "spritesheet" then
        local cols = visual.cols or 1
        local rows = visual.rows or 1
        local count = visual.frameCount or (cols * rows)
        local fps = visual.fps or 30
        if count < 1 or fps <= 0 then return end

        local f = ensurePulseFrame()
        f.ag:Stop()
        f.tex:SetTexture(visual.source)
        f.tex:SetTexCoord(0, 1 / cols, 0, 1 / rows)
        f.tex:SetAlpha(1)
        f.sprite.active = true
        f.sprite.elapsed = 0
        f.sprite.frame = 0
        f.sprite.cols = cols
        f.sprite.rows = rows
        f.sprite.count = count
        f.sprite.fps = fps
        f:Show()
        return
    end

    local source = resolveVisualSource(visual)
    if not source then return end
    local f = ensurePulseFrame()
    f.sprite.active = false
    f.tex:SetTexture(source)
    f.tex:SetTexCoord(0, 1, 0, 1)
    f.ag:Stop()
    f:Show()
    f.ag:Play()
end

function ns.GetMoveMode()
    return moveMode
end

function ns.SetMoveMode(enabled)
    moveMode = enabled and true or false
    local f = ensurePulseFrame()

    if moveMode then
        -- Cancel any in-flight playback so the placeholder is the only thing visible.
        f.ag:Stop()
        f.sprite.active = false
        f.tex:Hide()
        f:SetAlpha(1)

        f.editBg:Show()
        f.editLabel:Show()
        f.sizeLabel:Show()
        f.grip:Show()

        f:SetMovable(true)
        f:SetResizable(true)
        f:EnableMouse(true)
        f:RegisterForDrag("LeftButton")
        f:SetScript("OnDragStart", f.StartMoving)
        f:SetScript("OnDragStop", function(self)
            self:StopMovingOrSizing()
            local point, _, relPoint, x, y = self:GetPoint()
            ProcBellDB.visualPosition = {
                point = point or "CENTER",
                relativePoint = relPoint or "CENTER",
                x = x or 0,
                y = y or 0,
            }
            -- Re-anchor cleanly to UIParent so saved coords stay predictable.
            applyVisualPosition(self)
        end)
        f:Show()
    else
        f.editBg:Hide()
        f.editLabel:Hide()
        f.sizeLabel:Hide()
        f.grip:Hide()
        f.tex:Show()

        f:EnableMouse(false)
        f:SetMovable(false)
        f:SetResizable(false)
        f:RegisterForDrag()
        f:SetScript("OnDragStart", nil)
        f:SetScript("OnDragStop", nil)
        f:Hide()
    end
end

function ns.GetSpellNameAndIcon(spellID)
    if C_Spell and C_Spell.GetSpellInfo then
        local info = C_Spell.GetSpellInfo(spellID)
        if type(info) == "table" then
            return info.name, info.iconID
        end
    end
    if GetSpellInfo then
        local n, _, i = GetSpellInfo(spellID)
        return n, i
    end
end

local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")

f:SetScript("OnEvent", function(_, event, ...)
    if event == "ADDON_LOADED" then
        local name = ...
        if name == addonName then
            loadDB()
            f:UnregisterEvent("ADDON_LOADED")
            f:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
            f:RegisterUnitEvent("UNIT_AURA", "player")
        end
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
        local _, _, spellID = ...
        local binding = ns.GetBinding("cast", spellID)
        if binding then
            ns.PlayBoundSound(binding)
            ns.PlayBoundVisual(binding.visual)
        end
    elseif event == "UNIT_AURA" then
        local _, info = ...
        if type(info) ~= "table" then return end
        if info.isFullUpdate then return end
        local added = info.addedAuras
        if not added then return end
        for _, aura in ipairs(added) do
            local sid = aura and aura.spellId
            if sid then
                local binding = ns.GetBinding("aura", sid)
                if binding then
                    ns.PlayBoundSound(binding)
                    ns.PlayBoundVisual(binding.visual)
                end
            end
        end
    end
end)

SLASH_PROCBELL1 = "/procbell"
SLASH_PROCBELL2 = "/pb"
SlashCmdList.PROCBELL = function()
    if ns.OpenUI then ns.OpenUI() end
end
