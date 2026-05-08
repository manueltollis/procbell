local addonName, ns = ...

local LSM_TYPE = "sound"

local function lsm()
    return LibStub and LibStub("LibSharedMedia-3.0", true) or nil
end

local function loadDB()
    if type(ProcBellDB) ~= "table" then ProcBellDB = {} end
    if type(ProcBellDB.spellBindings) ~= "table" then ProcBellDB.spellBindings = {} end
    if type(ProcBellDB.auraBindings)  ~= "table" then ProcBellDB.auraBindings  = {} end

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
    t[spellID] = {
        name = sound.name,
        kind = sound.kind,
        source = sound.source,
    }
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
        if binding then ns.PlayBoundSound(binding) end
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
                if binding then ns.PlayBoundSound(binding) end
            end
        end
    end
end)

SLASH_PROCBELL1 = "/procbell"
SLASH_PROCBELL2 = "/pb"
SlashCmdList.PROCBELL = function()
    if ns.OpenUI then ns.OpenUI() end
end
