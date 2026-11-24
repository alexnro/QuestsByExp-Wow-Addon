# Order Quests By Exp

A World of Warcraft addon for **WoW: Forever** that shows the quests in your
quest log ordered by the experience they reward, so you always know which
quest is worth doing next.

## Features

- **Quest window**: every quest in your log, sorted by XP (highest first),
  with name (colored by difficulty), zone, type, level and XP.
- **On-screen list**: a compact list of your top quests by XP with their
  objectives, styled like the default quest tracker. Drag it anywhere, click
  its header to collapse it. Finished quests show "Ready to turn in".
- **Ready to turn in**: quests you can already hand in get a green tick, in
  both the window and the on-screen list.
- **Search and filters**: search quests by name, show only quests ready to
  turn in, and hide quest types (Normal, Group / elite, Dungeon, Raid, PvP,
  Class). Filters apply to both the window and the on-screen list.
- **Quick actions**: share a quest with your group or abandon it (with the
  game's usual confirmation) straight from the window. Click any quest to
  open it in the quest log.
- **Minimap button**: left-click toggles the window, right-click toggles the
  on-screen list, drag to move it around the minimap.
- Remembers window and list positions, filters and what was open between
  sessions. Esc closes the window like any other game window.

## Installation

1. Download the latest zip.
2. Unzip it into `World of Warcraft\_forever_\Interface\AddOns`, so you end up
   with `AddOns\OrderQuestsByExp\OrderQuestsByExp.toc`.
3. Restart the game or type `/reload`.

To update, delete the old `OrderQuestsByExp` folder first, then unzip the new
one. Your settings are kept.

## Commands

| Command | What it does |
| --- | --- |
| `/ordq` | Show or hide the quest window |
| `/ordq tracker` | Show or hide the on-screen list |
| `/ordq tracker <number>` | Set how many quests the on-screen list shows (1-25, default 10) |
| `/ordq reset` | Move the window and the on-screen list back to their default spots |
| `/ordq minimap` | Show or hide the minimap button |
| `/ordq help` | List the commands |

## Notes

- XP shows `...` for a moment while the game loads a quest's data.
- At max level every quest shows 0 XP.
- Bonus objectives and world quests aren't listed.
- Quest types are detected from the quest's tag and its quest-log header
  (class quests sit under a header named after the class). If a quest is
  labeled wrong, please open an issue with the quest name.

## License

[MIT](LICENSE)
