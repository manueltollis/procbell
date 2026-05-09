local _, ns = ...

local visuals = {}

-- `extras` is an optional table merged into the entry, used for spritesheet
-- metadata (cols, rows, frameCount, fps). Static images leave it nil.
local function add(name, kind, source, extras)
    if source == nil then return end
    local entry = { name = name, kind = kind, source = source }
    if extras then
        for k, v in pairs(extras) do entry[k] = v end
    end
    visuals[#visuals + 1] = entry
end

-- Custom textures bundled with the addon. Only .tga and .blp load (PNG/JPG do
-- not). Dimensions must be powers of two (32, 64, 128, 256, 512, 1024). Drop
-- more files into the addon folder and add a line below to expose them.
-- Example (uncomment after dropping the file in):
-- add("ProcBell Star", "file", "Interface\\AddOns\\procbell\\star.tga")

-- Spritesheet animation. Source TGA is a grid of equally-sized cells; the
-- renderer steps through `frameCount` cells at `fps`, left-to-right then
-- top-to-bottom. Build via scripts/build_spritesheet.py.
add("Dix Animation", "spritesheet", "Interface\\AddOns\\procbell\\anim.tga", {
    cols = 8, rows = 16, frameCount = 100, fps = 30,
})

-- Built-in game art. "file" kind accepts any path or numeric FileDataID that
-- Texture:SetTexture accepts -- this includes spell icons, raid markers,
-- targeting overlays, etc. Easy to extend.
add("Frost Bolt Icon",   "file", "Interface\\Icons\\Spell_Frost_FrostBolt02")
add("Fire Bolt Icon",    "file", "Interface\\Icons\\Spell_Fire_FlameBolt")
add("Holy Bolt Icon",    "file", "Interface\\Icons\\Spell_Holy_HolyBolt")
add("Shadow Bolt Icon",  "file", "Interface\\Icons\\Spell_Shadow_ShadowBolt")
add("Nature Lightning",  "file", "Interface\\Icons\\Spell_Nature_Lightning")
add("Arcane Blast",      "file", "Interface\\Icons\\Spell_Arcane_Blast")

add("Raid Mark: Star",     "file", "Interface\\TargetingFrame\\UI-RaidTargetingIcon_1")
add("Raid Mark: Circle",   "file", "Interface\\TargetingFrame\\UI-RaidTargetingIcon_2")
add("Raid Mark: Diamond",  "file", "Interface\\TargetingFrame\\UI-RaidTargetingIcon_3")
add("Raid Mark: Triangle", "file", "Interface\\TargetingFrame\\UI-RaidTargetingIcon_4")
add("Raid Mark: Moon",     "file", "Interface\\TargetingFrame\\UI-RaidTargetingIcon_5")
add("Raid Mark: Square",   "file", "Interface\\TargetingFrame\\UI-RaidTargetingIcon_6")
add("Raid Mark: Cross",    "file", "Interface\\TargetingFrame\\UI-RaidTargetingIcon_7")
add("Raid Mark: Skull",    "file", "Interface\\TargetingFrame\\UI-RaidTargetingIcon_8")

ns.visuals = visuals
