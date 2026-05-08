local _, ns = ...

local function sk(name)
    return SOUNDKIT and SOUNDKIT[name] or nil
end

local sounds = {}

local function add(name, kind, source)
    if source ~= nil then
        sounds[#sounds + 1] = { name = name, kind = kind, source = source }
    end
end

-- Custom sounds bundled with the addon. Drop more .ogg files into the addon
-- folder and add another line below to expose them in the picker.
add("ProcBell", "file", "Interface\\AddOns\\procbell\\procbell.ogg")

-- WoW built-in SoundKits. The sk() helper silently skips any name that
-- doesn't exist on the current client, so this list is safe to extend.
add("Level Up",                  "soundkit", sk("LEVEL_UP"))
add("Ready Check",               "soundkit", sk("READY_CHECK"))
add("Raid Warning",              "soundkit", sk("RAID_WARNING"))
add("Alarm Clock",               "soundkit", sk("ALARM_CLOCK_WARNING_3"))
add("Map Ping",                  "soundkit", sk("MAP_PING"))
add("Player Invite",             "soundkit", sk("IG_PLAYER_INVITE"))
add("Quest List Open",           "soundkit", sk("IG_QUEST_LIST_OPEN"))
add("Quest Failed",              "soundkit", sk("IG_QUEST_FAILED"))
add("Main Menu Open",            "soundkit", sk("IG_MAINMENU_OPEN"))
add("Coin Select",               "soundkit", sk("IG_BACKPACK_COIN_SELECT"))
add("Auction Window Open",       "soundkit", sk("AUCTION_WINDOW_OPEN"))
add("LFG Denied",                "soundkit", sk("LFG_DENIED"))
add("LFG Rewards",               "soundkit", sk("LFG_REWARDS"))
add("Legendary Loot Toast",      "soundkit", sk("UI_LEGENDARY_LOOT_TOAST"))
add("Epic Loot Toast",           "soundkit", sk("UI_EPICLOOT_TOAST"))
add("Raid Boss Defeated",        "soundkit", sk("UI_RAID_BOSS_DEFEATED"))
add("Raid Boss Whisper",         "soundkit", sk("UI_RAID_BOSS_WHISPER"))
add("Achievement Menu",          "soundkit", sk("ACHIEVEMENT_MENU_OPEN"))
add("Tutorial Popup",            "soundkit", sk("TUTORIAL_POPUP"))

ns.sounds = sounds
