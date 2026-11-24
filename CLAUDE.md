# Order Quests By Exp

World of Warcraft addon for **WoW: Forever**. Shows a small window that lists the
quests in your quest log ordered by the experience they reward, with the quest
name, location (zone / quest-log header), level and XP amount.

## Environment

- WoW: Forever runs on the modern (Mainline) addon API, **not** the Classic Era API.
- Midnight-era combat restrictions apply: do not rely on combat log parsing or
  hidden combat data. Some API returns may be "secret values"; treat them as unknown.
- TOC uses `## Interface: 16001`.
- Game AddOns folder: `E:\World of Warcraft\_forever_\Interface\AddOns`
  (this repo lives directly in it as `OrderQuestsByExp`).
- Windows. No build step. Test in game with `/reload`; errors are caught by BugSack.

## Conventions

- Every Lua file starts with `local addonName, ns = ...` and shares state and
  functions through `ns` (the addon's private namespace table).
- No globals except the SavedVariables table `OrderQuestsByExpDB`, plus the
  `SLASH_ORDERQUESTSBYEXP1` / `SlashCmdList` entries the slash-command API requires.
- One feature per file (e.g. `QuestData.lua`, `Window.lua`, `Events.lua`); list
  files in the TOC in load order, `Core.lua` first.
- `OrderQuestsByExpDB` is initialised in `ADDON_LOADED` for this addon, never at file scope.
- Guard APIs that may be missing or error on this client:
  `type(fn) == "function"` checks and `pcall` around quest-log calls.
  Use `issecretvalue(v)` (when it exists) before reading values that could be secret.
- Frames are created without global names (no `_G` pollution), including the
  minimap button.
- Reuse Blizzard's own dialogs (e.g. `ABANDON_QUEST`) instead of adding
  `StaticPopupDialogs` entries.
- Chat output goes through `ns.Print`, which prefixes the addon tag.
- Cache frequently used API functions as locals at the top of the file that uses them.
- Slash command: `/ordq`.
