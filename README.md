# ProcBell

A small World of Warcraft addon that plays a sound when you cast specific spells or gain specific auras. Useful for proc cues, cooldown alerts, ability reminders, etc.

## Features

- Play any sound when you successfully cast a spell (e.g. Ray of Frost — spell ID `205021`)
- Play any sound when an aura newly appears on you (e.g. Vengeance Metamorphosis — spell ID `187827`)
- Pick from a curated list of WoW built-in SoundKits + a bundled custom sound (`procbell.ogg`)
- Reads the SharedMedia (LibSharedMedia-3.0) sound registry — every sound any other addon registers shows up in the dropdown automatically
- Settings persist across sessions per character

## Installation

### WowUp-CF (recommended)

1. Open WowUp-CF
2. **Get Addons** → menu (⋮) → **Install from URL**
3. Paste this repo's GitHub URL
4. WowUp-CF reads the latest GitHub release (via `release.json`) and updates automatically when new versions are tagged

### Manual

1. Download the latest `procbell-vX.Y.Z.zip` from [Releases](../../releases)
2. Extract into `World of Warcraft\_retail_\Interface\AddOns\`
3. `/reload` in-game (or restart the client)

## Usage

- `/procbell` (or `/pb`) — open the configuration window
- **Spell Casts** tab — bind a sound to a spell ID; sound plays on a successful cast
- **Auras** tab — bind a sound to an aura's spell ID; sound plays when the aura newly appears on you

Find spell/aura IDs on Wowhead — the URL ends in the ID, e.g. `wowhead.com/spell=205021`.

## Adding custom sounds

ProcBell embeds **LibSharedMedia-3.0**. Any sound registered into the LSM "sound" type from any other addon appears in the dropdown automatically — that's WeakAuras, BigWigs, Plater, Details, etc., plus the dedicated user-media addon below.

To add your own `.ogg` files, install **SharedMedia_MyMedia**:

1. Get [SharedMedia](https://www.curseforge.com/wow/addons/shared-media-3-0) and [SharedMedia_MyMedia](https://www.curseforge.com/wow/addons/sharedmedia_mymedia) (any source — CurseForge, Wago, GitHub).
2. Drop your `.ogg` files into `Interface\AddOns\SharedMedia_MyMedia\sound\` (or wherever the addon expects — its README will say).
3. Edit `SharedMedia_MyMedia\MyMedia.lua` to register them, e.g.:
   ```lua
   LSM:Register("sound", "MyAlert", [[Interface\AddOns\SharedMedia_MyMedia\sound\my-alert.ogg]])
   ```
4. `/reload` — the sound now appears in ProcBell's dropdown alongside everything else.

This is the standard ecosystem pattern — once you've registered a sound there, it's also available to WeakAuras, BigWigs, etc.

## Releasing

Versions are published via GitHub Actions on tag push. The [BigWigs packager](https://github.com/BigWigsMods/packager) builds the zip, embeds the bundled libraries declared in `.pkgmeta`, and writes a `release.json` that WowUp-CF reads.

```bash
git tag v1.0.1
git push origin v1.0.1
```

Or just push to `main` and the auto-tag workflow bumps the patch automatically.

## License

No license declared. Add one (e.g. MIT) if you intend others to use or contribute.
