# Project Highlander Gen3 1.39.0 — Milestone build

For the five Gen 3 games of G1R Deluxe (FireRed, LeafGreen, Ruby, Sapphire, Emerald). Built and tested against G1R Deluxe 0.3.90 (works from 0.3.89).

## Start Menu
- Two-column, five-row Start Menu with flat coloured icons (Gen V panels + Gen VI rounded buttons).
- FireRed/LeafGreen: Pokédex, Pokémon, Bag, PokéBox, Trainer, Save, Options, Mods, (empty), Exit.
- Ruby/Sapphire/Emerald: the same with PokéNav in the empty space.
- PokéBox opens Bill's PC "Move Pokémon" from anywhere; leaving it returns to the Start Menu.
- Themes: Auto, FireRed, LeafGreen, Ruby, Sapphire, Emerald — saved per game or per save, with a themed grid background.
- Day, date and clock bar (device clock; Hoenn alternates with the in-game clock).
- Sort Menu (Options, or SELECT on the Start Menu). Exit stays bottom-right.
- Save stays in the Start Menu: the game's save prompts appear on top of it, and you're back on SAVE afterwards.

## PC (Move Pokémon)
- SELECT toggles Auto-Grab (A picks a Pokémon up at once); turns off when you leave the PC.
- MULTIPLE in the A menu: mark a group, move it between boxes, or swap it in/out of the party.

## Party menu
- SELECT quick switch (always on): SELECT on a Pokémon starts a switch; A or SELECT on the other swaps, B cancels.
- A menu order (always on): Summary, Role, Switch, Item, Relearn, HM moves, TM moves, Cancel. Works with Wilds of Hoenn's ROLE row.
- More than 8 entries: 8 at a time with a scroll bar and up/down arrows.
- Display XP in Party Menu (QOL): XP bar in every box; the first Pokémon's box is taller with its XP numbers.

## Bag
- 255-item limit (always on): up to 255 different items in total. FireRed/LeafGreen: the TM Case and Berry Pouch count as 1 each.
- "Items x/255" counter bar (bottom-left in FireRed/LeafGreen, top-left in Ruby/Sapphire/Emerald); red when full.
- START: SORT BY menu — Category Asc/Desc, Names A-Z/Z-A; every pocket at once, the cursor stays on its item.
- SELECT opens the TM Case (FireRed/LeafGreen, outside battle).
- Bag on Specific Pouch (QOL): open the bag on a chosen pocket, in and out of battle.

## Pokédex
- SELECT on an entry page opens a 2nd screen with four tabs (LB/RB to switch, B to go back):
  - Stats: base stats with bars and total, catch rate, base EXP, growth rate, abilities.
  - Family: the evolution line and how each evolves; A jumps to that Pokémon's entry.
  - Moves: level-up, TM/HM, tutor and egg moves with type badges; A shows a move's details.
  - Location: where it's found in the game you're playing, with levels and rate; A sorts the list.
- A "Select 2nd Screen" hint on the entry pages.

## Full Control (Options > Project Highlander > Full Control)
- Rebind Up, Down, Left, Right, A, B, Start, Select, L, R, Speed+ and Speed- (one key and one pad control each; Delete clears a bind).
- Left/Right analog stick as D-pad; Select+ visual combos can be turned off.
- While On, the stock Controls page is hidden and its map is replaced.

## Shortcuts (Options > Project Highlander > Shortcuts)
- Ball Shortcuts: SELECT + a direction throws a set ball in wild battles (up to 4; no Master/Safari Ball). Not in the Safari Zone or against trainers. Red "PokéBall Shortcuts Active" note.
- Item Shortcuts: up to 3 Key Items in a SELECT box in the overworld (FR/LG: Town Map, Bicycle, Itemfinder, Rods, Vs. Seeker, Berry Pouch, TM Case; R/S/E: Acro/Mach Bike, Itemfinder, Rods, Go-Goggles, Devon Scope, Wailmer Pail, Pokéblock Case, Town Map via PokéNav).

## Battle HUD (Options > Project Highlander > Battle HUD)
- Colored Move Names: a frame in each move's type colour (Fairy colour ready for later).
- Display Enemy HP: the enemy's HP in numbers (singles).

## QOL (Options > Project Highlander > QOL)
- Always Boosted EXP: every Pokémon gets the traded-Pokémon EXP bonus; obedience and your Trainer ID are unchanged.
- Bag on Specific Pouch: Off / pocket of your choice (per region).
- Box Exclusive: the d-pad stays inside the current box (Off by default).
- Decapitalize Words: Pokémon, Potion, Brock... instead of all capitals (HP, PP, PC, TM, HM, XP, LR and such stay).
- Display XP in Party Menu (On by default).
- Infinite Safari: the Kanto and Hoenn Safari Zone steps never run out.
- Modern EXP Sharing: every other living party Pokémon gets half a battler's share, with one "The others gained..." line.
- Rematch Anyone, Anytime: talk to a beaten trainer for a rematch; their team is at the level of your lowest Pokémon, evolved, with level-up moves. Gym leaders included (no second badge or TM).
- Run Everywhere: run inside buildings in Ruby/Sapphire/Emerald.
- Skip FR & LG Recaps: no "Previously on your quest..." when loading (On by default).
- Sparkling Hidden Items: a pulsing sparkle marks every hidden item you haven't found yet.
- Unlimited PP: your moves never lose PP; not in link battles.
- Use Repel Again?: when a Repel wears off, the game asks to use another of the same kind.
- New QOL options are Off by default. The QOL page is in alphabetical order.

## Other
- Window focus on launch from the frontend, Playnite or shortcuts.
- Option values on the Project Highlander pages are right-aligned at the end of each row.
