# Project Highlander Gen3 (BETA)

Project Highlander for the **Gen 3 games of G1R Deluxe**: **FireRed, LeafGreen, Ruby, Sapphire and Emerald**.

A modern Start Menu, PC, Party, Bag and Pokédex upgrades, quality-of-life options, controller rumble, animated sprites, custom borders and tools to fill your Regional Dex in a single cartridge — all from one hub.

**Hub:** `Options → PROJECT HIGHLANDER`

> [!IMPORTANT]
> **This is a BETA.** Everything has been tested, but not on every save, route and game combination. Back up your saves before installing and please report anything odd (see [Reporting issues](#reporting-issues)).

> [!NOTE]
> Project Highlander Gen3 only runs in the five Gen 3 games. For Red / Blue / Yellow / Gold / Silver / Crystal, use [Project Highlander](https://github.com/Waifu4Life/Project-Highlander-A-Modern-UI-Suite-Fork), a separate mod.

**Current release:** 1.70.0 (BETA)
**Requires:** G1R Deluxe 0.3.89 or newer (built against 0.3.97)

---

## Table of contents

- [Defaults](#defaults)
- [Optional extras](#optional-extras)
- [Always on](#always-on)
- [Hub layout](#hub-layout)
- [Start Menu Settings](#start-menu-settings)
- [Party](#party)
- [Bag](#bag)
- [PC](#pc)
- [Pokédex](#pokédex)
- [Battle Screen](#battle-screen)
- [Overworld Screen](#overworld-screen)
- [Other System Settings](#other-system-settings)
- [Animated Sprites](#animated-sprites)
- [Rumble Settings](#rumble-settings)
- [PokéMoves](#pokémoves)
- [Full Control](#full-control)
- [Jukebox](#jukebox)
- [Shortcuts Settings](#shortcuts-settings)
- [Custom Borders](#custom-borders)
- [Game Corner Cheats](#game-corner-cheats)
- [Fill Kanto Regional Dex](#fill-kanto-regional-dex)
- [Fill Hoenn Regional Dex](#fill-hoenn-regional-dex)
- [Johto Pokémon Helper](#johto-pokémon-helper)
- [Reporting issues](#reporting-issues)
- [Credits](#credits)

---

## Defaults

Every setting is **On** out of the box. Multiple-choice settings start on **Automatic** or **By Game** where they have one, otherwise:

| Setting | Default |
|---|---|
| Bag on Specific Pouch | Off |
| Low HP Warning | Normal |
| Loop Animations | Medium |
| Rumble Intensity | Medium |
| Slot Odds | Normal |
| Screen Ratio | 16:9 |
| Ball Shortcuts | Up: Poké Ball, Down: Ultra Ball, Left: Great Ball, Right: None |
| Jukebox Button | None (set it in Full Control) |

Rows that don't concern the game you're playing are hidden (FireRed / LeafGreen-only rows don't show in Hoenn, Ruby / Sapphire-only rows don't show in Emerald, and so on).

---

## Optional extras

Nothing from another game is shipped with the mod. Some features borrow data from your **other installed G1R Deluxe games** while they need it:

| Feature | Needs |
|---|---|
| Animated Sprites in FireRed / LeafGreen / Ruby / Sapphire | Emerald installed |
| Aurora Ticket and Birth Island in Ruby / Sapphire | Emerald installed |
| Get All Johto Starters / Get Emerald Game Exclusives (Ruby / Sapphire) | Emerald installed |
| Emerald's Ruby / Sapphire slots (Get Other Game Exclusives) | Ruby or Sapphire installed |
| Johto exclusives in FireRed / LeafGreen | The other Kanto game installed (a fallback swap is used otherwise) |

**Wilds of Hoenn** (1.10.4 or newer) is supported: other-game exclusives show up as visible Pokémon, and Jirachi / Deoxys use its HGSS overworld sprites.

---

## Always on

These run whenever the matching screen or event is in play. There is no toggle.

| Area | What you get |
|---|---|
| Party | **Select** quick switch: Select on a Pokémon, then A or Select on another swaps them, B cancels. |
| Party A-menu | Always in this order: Summary, Role, Switch, Item, Relearn, HM moves, TM moves, Cancel. Works with Wilds of Hoenn's Role row. More than 8 entries scroll with a scroll bar. |
| Bag | 255-item limit with an **Items x/255** counter (red when full). In FireRed / LeafGreen the TM Case and Berry Pouch count as one item each. |
| Bag | **Start** opens a Sort By menu. **Select** opens the TM Case (FireRed / LeafGreen, outside battle). |
| PC | **Select** toggles Auto-Grab. **Multiple** in the A-menu moves a group between boxes or in and out of the party. |
| Pokédex | **Select** on an entry opens a 2nd screen with Stats / Family / Moves / Location tabs. |
| Options | **Button Mode** is locked on **LR**, so L and R always work as L and R. |
| Select box | The Item Shortcuts / Instant TMs/HMs box follows your Start Menu theme. |
| Shops | After the Champion, Lilycove Dept. Store 2F (Ruby / Sapphire / Emerald) and the Celadon Dept. Store stone clerk (FireRed / LeafGreen) also sell Metal Coat, King's Rock, Dragon Scale and Up-Grade at $20,000 each. |
| Launch | The game window takes focus when launched from a frontend, Playnite or a shortcut. |

---

## Hub layout

| Sub-menu | What it covers |
|---|---|
| Animated Sprites | Emerald's animated Pokémon in every game. |
| Battle Screen | HUD and battle gameplay options. |
| Custom Borders | Themed art around the GBA screen. |
| Fill Kanto Regional Dex | **FireRed / LeafGreen only.** Every Kanto Pokémon in one cartridge. |
| Fill Hoenn Regional Dex | **Ruby / Sapphire / Emerald only.** Every Hoenn Pokémon in one cartridge. |
| Full Control | Button rebinding. |
| Game Corner Cheats | Stack the odds in your favor. |
| Johto Pokémon Helper | Helps fill the National Dex by trading between games. |
| Jukebox | Pick the songs you like and play them instead of the area music. |
| Other System Settings | Everything else. |
| Overworld Screen | Travel and exploration options. |
| PokéMoves | HM / TM / relearn tools. |
| Rumble Settings | Controller rumble. |
| Shortcuts Settings | Ball shortcuts in battle and Key Item shortcuts on Select. |
| Start Menu Settings | Modern Start Menu. Has its own **Enable** switch. |

The hub is alphabetical. Inside a sub-menu, **Enable** is on top and the rest is alphabetical, except where a fixed order makes more sense (controller order for buttons, the Regional Dex pages). Option values are right-aligned at the end of each row.

---

## Start Menu Settings

A two-column, five-row Start Menu with flat coloured icon buttons.

- **FireRed / LeafGreen:** Pokédex, Pokémon, Bag, PokéBox, Trainer, Save, Options, Mods, Exit.
- **Ruby / Sapphire / Emerald:** the same, plus PokéNav.
- **Exit** always stays bottom-right.
- **Save** stays in the Start Menu: the save prompts appear on top of it and you're back on Save afterwards.
- **Select** on the Start Menu opens the Sort Menu.

| Option | Values |
|---|---|
| Enable | On / Off |
| Clock | Day, date and device time bar (Hoenn alternates with the in-game clock). |
| PokéBox | Bill's PC "Move Pokémon" from anywhere; leaving it returns to the Start Menu. |
| Save Theme | **Per Game** or Per Save |
| Sort Menu | Arrange the Start Menu items. |
| Theme | **Auto** (follows the game), FireRed, LeafGreen, Ruby, Sapphire, Emerald |

## Party

- **Select** quick switch and the fixed A-menu order (see [Always on](#always-on)).
- **Display XP in Party Menu** (Other System Settings): an XP bar in every box; the first Pokémon's box is taller and shows its XP numbers.
- **Relearn** appears in the A-menu when Move Relearning is on and there's something to relearn.

## Bag

- 255-item limit with a counter bar.
- **Start → Sort By:** Category Asc / Desc, Names A–Z / Z–A. Sorts every pocket at once; the cursor stays on its item.
- Category sort uses Project Highlander's own order (weakest to strongest healing, then status, PP, held items and so on).
- **Select** opens the TM Case in FireRed / LeafGreen.
- **Bag on Specific Pouch** (Other System Settings): open the bag on the pocket of your choice, in and out of battle.

## PC

- **Auto-Grab** (Select): A picks a Pokémon up at once. Turns off when you leave the PC.
- **Multiple:** mark a group, move it between boxes, or swap it in and out of the party.
- **Box Exclusive** (Other System Settings): the D-pad stays inside the current box.

## Pokédex

**Select** on an entry page opens a 2nd screen. LB / RB switch tabs, B goes back.

| Tab | What it shows |
|---|---|
| Stats | Base stats with bars and total, catch rate, base EXP, growth rate, abilities. |
| Family | The evolution line and how each step evolves. A jumps to that entry. |
| Moves | Level-up, TM / HM, tutor and egg moves with type badges. A shows a move's details. |
| Location | Where it's found in the game you're playing, with levels and rate. A sorts. Follows Get Other Game Exclusives. |

---

## Battle Screen

| Option | What it does |
|---|---|
| Always Boosted EXP | Every Pokémon gets the traded-Pokémon EXP bonus. Your Trainer ID is untouched and nothing starts disobeying. |
| Colored Move Names | A frame in each move's type colour. |
| Display Enemy HP | The enemy's HP in numbers. |
| Low HP Warning | **Normal** (the game's looping beep) / Reduced (a few beeps when the bar turns red) / Off |
| Modern EXP Sharing | Every other living party Pokémon gets half a battler's share, with one "The others gained…" line. |
| Unlimited PP | Your moves never lose PP. Not in link battles. |

## Overworld Screen

| Option | What it does |
|---|---|
| Infinite Safari Steps | The Kanto and Hoenn Safari Zone steps never run out. The game ends when you're out of Safari Balls or you leave. |
| Rematch Anyone, Anytime | Talk to a beaten trainer for a rematch. Their team is set to your lowest Pokémon's level, evolved, with level-up moves. Gym Leaders included (no second badge or TM). |
| Run Everywhere | Run inside buildings in Ruby / Sapphire / Emerald. |
| Sparkling Hidden Items | A pulsing sparkle marks every hidden item you haven't found yet. |
| Use Repel Again? | When a Repel wears off and you still have that kind, the game asks to use another. |

## Other System Settings

| Option | What it does |
|---|---|
| Bag on Specific Pouch | Off / the pocket of your choice (per region). |
| Box Exclusive | The PC D-pad stays inside the current box. |
| Decapitalize Words | Pokémon, Potion, Brock… instead of all capitals. HP, PP, PC, TMs, HMs, PKMN, XP and the like stay. |
| Display XP in Party Menu | XP bars in the party screen. |
| Skip FR & LG Recaps | **FireRed / LeafGreen only.** No "Previously on your quest…" when loading. |

---

## Animated Sprites

Emerald's animated Pokémon sprites (front and back, normal and shiny) everywhere: battles, Summary, Pokédex, PC, evolutions, trades and eggs. Read from your installed Emerald; nothing is shipped with the mod.

| Option | What it does |
|---|---|
| Back Animation | Your Pokémon's back animation when it's sent out and while looping. |
| Fire Red & Leaf Green | **FireRed / LeafGreen only.** Use Emerald's animated sprites. |
| Loop Animations | Off / Slow / **Medium** / Fast — replays the animation on the battle menu, without the cry. Stops the moment you pick an action. |
| Ruby & Sapphire | **Ruby / Sapphire only.** Use Emerald's animated sprites. |

Deoxys keeps its own game's form and Spinda keeps its own spots.

## Rumble Settings

Rumbles your controller in time with the hit. With no controller (phones), the device vibrates instead.

| Option | What it does |
|---|---|
| Intensity | Off / Low / **Medium** / High — strength and length. Off is how rumble is turned off. |
| Press Select to Test | Left / Right picks a hit type; **Select** plays it. |
| Before Trainer Battle | Two pulses as the battle transition starts. |
| Before Wild Battle | One pulse as the battle transition starts. |
| When I Get Hit | Rumble when your Pokémon is hit (left motor leads). |
| When I Hit | Rumble when you hit the foe (right motor leads). |

Hits follow effectiveness: not very effective = a light tap, effective = one solid pulse, super effective = two strong pulses, no effect = nothing. Works in singles and doubles.

## PokéMoves

| Option | What it does |
|---|---|
| Forgettable HMs | HM moves can be replaced like any other move. |
| Instant TMs/HMs | Press A in front of a tree, rock, boulder, water, waterfall or dive spot to use Cut / Rock Smash / Strength / Surf / Waterfall / Dive at once. Sweet Scent, Teleport, Dig, Secret Power (Hoenn), Fly and Flash from the Select box. |
| Move Relearning | **Relearn** in the Party A-menu, including moves skipped by stone evolutions. |
| No Learn HMs | With the badge, a party Pokémon that *can* learn an HM counts as knowing it. |
| TMs Forever | Teaching a TM doesn't use it up. |

## Full Control

- Rebind Up, Down, Left, Right, A, B, Start, Select, **L, R**, Speed+ and Speed− (one key and one pad control each). Delete clears a binding.
- **Jukebox Button:** the button that controls the [Jukebox](#jukebox). No key or pad by default.
- Left Analog for D-Pad and Right Analog for D-Pad.
- **Select Visual Combos:** turn it off to use Select + pad buttons normally instead of the display shortcuts.
- The stock Controls page is hidden while Full Control is on.

## Jukebox

**All five games.** Tired of the Safari Zone music? Play the songs you like instead.

The sub-menu lists every background song of the game you're playing, A–Z, each **On** by default. Each game keeps its own list. The songs that are On make the playlist, in the menu's order. Short jingles (item, badge, heal, level up…) aren't listed.

| Option | What it does |
|---|---|
| All Songs | Shows On / Off / Some. One press turns every song Off, or every song On when none is. |
| *Each song* | On / Off: in the playlist or not. |

Set a **Jukebox Button** in [Full Control](#full-control), then in the overworld hold it and press a direction. The button alone does nothing, and while it's held you stay put.

| Combo | What it does |
|---|---|
| Button + Up | Play the playlist, from the song it was on last. Already playing: shows the song's name. |
| Button + Down | Stop it and go back to the game's own music. |
| Button + Left | Previous song (from the first, goes round to the last). Only while playing. |
| Button + Right | Next song (from the last, goes round to the first). Only while playing. |

- The Jukebox song stays on through new maps, Surf, Bicycle and Dive.
- Battles, trainer encounters, evolutions, scripted events and jingles keep the game's music; your song comes back after them.
- A short note at the top left shows the song's name, in your Start Menu theme's colours.
- Needs **Full Control → Enable** On. In menus, battles and the naming screen the button does what it did before.

## Shortcuts Settings

- **Ball Shortcuts:** Select + a D-pad direction throws a ball in a wild battle. Up to 4 can be set (Poké, Great, Ultra, Net, Dive, Nest, Repeat, Timer, Luxury, Premier — no Master or Safari Ball). Not in the Safari Zone, against trainers, or in link, double, Frontier / Pyramid or scripted battles. A red note shows when it's active.
- **Item Shortcuts:** up to 3 Key Items in a Select box on the overworld (saved per save).
  - FireRed / LeafGreen: Town Map, Bicycle, Itemfinder, Old / Good / Super Rod, Vs. Seeker, Berry Pouch, TM Case.
  - Ruby / Sapphire / Emerald: Acro Bike, Mach Bike, Itemfinder, Old / Good / Super Rod, Go-Goggles, Devon Scope, Wailmer Pail, Pokéblock Case, Town Map (via the PokéNav).

## Custom Borders

| Option | Values |
|---|---|
| Enable | On / Off |
| Border | **Automatic** (follows the cartridge), FireRed, LeafGreen, Ruby, Sapphire, Emerald, Custom 1–4 |
| Border Scope | **By Game** or By Save |
| Screen Ratio | Off / **16:9** — for odd-ratio screens like the Steam Deck |

Borders show around the GBA screen on battles, full-screen menus, the shop view and the title / boot screens. G1R Deluxe draws the overworld across the whole window, so it has none.

`assets/borders/custom1–4.png` are 3840×2160 templates (game window at 360,40, 3120×2080). Any size with the same proportions works.

## Game Corner Cheats

Celadon (FireRed / LeafGreen) and Mauville (Ruby / Sapphire / Emerald).

| Option | What it does |
|---|---|
| 2× Coins for Cash | 100 coins for $1,000 and 1,000 coins for $10,000. |
| All Lucky Machines | Every machine plays like the luckiest one. |
| Bigger Payouts | Every slot win pays double (coins still stop at 9,999). |
| Slot Odds | **Normal** / Generous / Lucky |

---

## Fill Kanto Regional Dex

**FireRed / LeafGreen only.** Every Kanto Pokémon in a single cartridge, no trading needed. 

| Option | How it works |
|---|---|
| Get Other Game Exclusives | Each exclusive pair (Ekans / Sandshrew, Oddish / Bellsprout, Psyduck / Slowpoke, Growlithe / Vulpix, Shellder / Staryu, Scyther / Pinsir and their evolutions) has a 50% chance to be the other game's. Both games get Electabuzz in the Power Plant and Magmar on Mt. Ember. |
| Trade with Link C. | The Game Boy kid on his own in the Celadon Dept. Store trade-evolves Kadabra, Haunter, Graveler and Machoke with the trade and evolution scenes, then trades them back. |
| Infinite Tries for Rare PKMN | Articuno, Zapdos, Moltres, Mewtwo, both Snorlax, the roaming beasts, Lugia, Ho-Oh, etc. |
| Get All Starters | Two steps. **1.** With 8 badges, Oak offers the Poké Ball left on his table: the starter neither you nor your rival picked (your 2nd). **2.** Then, as Champion with Mewtwo first in your party, he gives you a baby of your rival's starter (Lv 5, your 3rd). |
| Get Other Fossil | With 8 badges, Miguel on Mt. Moon B2F trades you the fossil you didn't pick. |
| Get ??? | The final Pokémon. |

## Fill Hoenn Regional Dex

**Ruby / Sapphire / Emerald only.** Every Hoenn Pokémon in a single cartridge.

| Option | How it works |
|---|---|
| Get Other Game Exclusives | Ruby / Sapphire: Seedot / Lotad, Nuzleaf / Lombre, Mawile / Sableye, Zangoose / Seviper and Solrock / Lunatone each have a 50% chance to be the other version's. Emerald: Seviper → Zangoose and Solrock → Lunatone at 50%, and Surskit, Meditite, Medicham and Roselia get Ruby / Sapphire's slots. |
| Trade with Link C. | The GameCube in your room trade-evolves Kadabra, Graveler, Machoke, Seadra (Dragon Scale) and Clamperl (DeepSeaTooth / DeepSeaScale), then trades them back. |
| Infinite Tries for Rare PKMN | The Regis, Groudon, Kyogre, Rayquaza, Latias / Latios, Jirachi, Deoxys, Mew, Lugia, Ho-Oh and Sudowoodo stay until you catch them. |
| Get All Starters | Two steps. **1.** With 8 badges, talk to Birch: the starter neither you nor your rival picked waits on his lab table (your 2nd). **2.** Then, as Champion with Latias or Latios first in your party, Birch gives you a baby of your rival's starter (Lv 5, your 3rd). |
| Get Other Fossil | **Ruby / Sapphire.** With 8 badges and your fully evolved fossil Pokémon first in the party, the Devon scientist gives you the other one. |
| Get Other Deep Sea Item | With 8 badges, Captain Stern trades the other Deep Sea item for the Storage Key (but only if you have used it to get the TM). |
| Roaming Hunter | On the roaming Latias / Latios's route, every encounter is it, and it never flees. |
| Get Other Box Legendary | **Ruby / Sapphire.** As Champion, with Rayquaza and your version's legend in slots 1 and 2, the other one waits in the Cave of Origin. |
| Get Eon Ticket | As Champion with Latias or Latios caught, talk to Dad at the Petalburg Gym. |
| Get a Special Wish | Every Hoenn Pokémon up to #200 caught? Talk to Mom… ??? awaits.|

## Johto Pokémon Helper

**All five games.** Still no full National Dex in one game: this helps players who fill it by trading between games. Each game only shows its own rows.

**FireRed / LeafGreen**

| Option | How it works |
|---|---|
| Get Other Game Exclusives | Wild slots where your other Kanto game has a different Johto Pokémon are 50% yours, 50% the other game's, at its levels and in the same spot. Without the other game installed, Murkrow / Misdreavus, Qwilfish / Remoraid, Delibird / Sneasel and Skarmory / Mantine swap at 50%. |
| Get All Roaming Beasts | When your game's beast appears, the other two start roaming Kanto too. |
| Roaming Hunter | On a roaming beast's route, every encounter is it, and it never flees. |
| Obtain Mystic Ticket | Raikou, Entei and Suicune in slots 1, 2 and 3? Talk to Mom. The Navel Rock ship opens like the real event. |
| Guardian of the Forest | With Lugia and Ho-Oh caught, ??? waits in Viridian Forest and wants to play a game. |

**Ruby / Sapphire / Emerald**

| Option | How it works |
|---|---|
| Get Emerald Game Exclusives | **Ruby / Sapphire.** After the Champion, Emerald's 16 Johto Safari Zone Pokémon spread over the four Safari Zone areas, plus Smeargle and Sudowoodo. |
| Extras in Safari Zone 5&6 | **Emerald.** Smeargle in area 5, Sudowoodo in area 6. |
| Get All Johto Starters | All three games: complete the Hoenn Dex (up to No. 200) and talk to Birch, then take all three Johto starters instead of one. Emerald uses its own lab table; Ruby / Sapphire borrow Emerald's. |

---

## Reporting issues

This is a **BETA**, so feedback helps a lot. When reporting a bug, please include:

- Your G1R Deluxe version and the Project Highlander Gen3 version.
- Which game (FireRed, LeafGreen, Ruby, Sapphire or Emerald) and your platform (Windows, Steam Deck, Android…).
- Any other mods you use (Wilds of Hoenn version, etc.).
- What you did, what you expected, and what happened. A screenshot helps.

---

## Credits

- **poooooby** — Wilds of Hoenn; Jirachi and Deoxys HGSS overworld sprites used with permission (see Wilds of Hoenn's THIRD_PARTY_NOTICES.md for the art's original credits)
- **Waifu4Life** — Project Highlander Gen3: menus, QoL, Regional Dex tools, Johto Pokémon Helper, rumble, integration
