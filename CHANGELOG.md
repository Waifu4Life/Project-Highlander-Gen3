# Project Highlander Gen3 — Changelog

## 1.71.0 (BETA)
- First public BETA on GitHub: github.com/Waifu4Life/Project-Highlander-Gen3
- manifest.json now points to the GitHub repo, so G1R Deluxe can check for and install updates.

## 1.70.0
- New sub-menu: JOHTO POKéMON HELPER (all five games, every option On, each game only shows its own
  rows). Still no National Dex in a single game: it helps the players who fill it by trading.
  - FireRed/LeafGreen:
    - GET OTHER GAME EXCLUSIVES: every wild slot where your other Kanto game has a different Johto
      Pokémon (read from its installed cache) is 50% yours, 50% the other game's, at the other
      game's levels and in the same spot (grass, water, fishing, rocks). Works with Wilds of Hoenn
      and the Pokédex LOCATION tab. Without the other game installed: Murkrow/Misdreavus,
      Qwilfish/Remoraid, Delibird/Sneasel and Skarmory/Mantine swap at 50% instead.
    - GET ALL ROAMING BEASTS: when the game's roaming beast appears, the other two start roaming
      Kanto too (kept in the save). Each moves on its own.
    - ROAMING HUNTER: on a roaming beast's route, every encounter is it, and it never flees.
    - OBTAIN MYSTIC TICKET: RAIKOU, ENTEI and SUICUNE in the 1st, 2nd and 3rd slots, talk to Mom:
      "Honey, there was a letter in the mail for you, there you go." The MYSTIC TICKET goes to the
      Key Items pocket and the Navel Rock ship opens like the real event.
    - GUARDIAN OF THE FOREST: LUGIA and HO-OH caught: CELEBI waits in Viridian Forest on dirt patch 1.
      Talk to it and it vanishes to patch 2, 3, 4, then 5, where you battle it (Lv10). Once it's
      gone it leaves an item ball with the AURORA TICKET (Birth Island).
    - FILL KANTO REGIONAL DEX > INFINITE TRIES FOR RARE PKMN now also keeps the roaming beasts
      roaming, LUGIA, HO-OH, DEOXYS and CELEBI in place when they aren't caught.
  - Ruby/Sapphire: GET EMERALD GAME EXCLUSIVES (Champion): the 16 Johto Pokémon of Emerald's Safari
    Zone 5/6 (levels from your installed Emerald) split 4 by 4 over the four Safari Zone areas, plus
    SMEARGLE and SUDOWOODO. A new Pokémon only takes a slot whose Pokémon stays in another slot.
  - Emerald: EXTRAS IN SAFARI ZONE 5&6: SMEARGLE in area 5, SUDOWOODO in area 6.
  - GET ALL JOHTO STARTERS: Emerald: Birch's lines say to take all three; the first ball works as
    usual and the other two can be taken too. Ruby/Sapphire: Hoenn Dex complete (#200), talk to
    Birch: Emerald's lab table (borrowed from your installed Emerald) appears with three Poké Balls.
- Always on: after the Champion, the Lilycove Dept. Store 2F Potion clerk (R/S/E) and the Celadon
  Dept. Store evolution stone clerk (FR/LG) also sell METAL COAT, KING'S ROCK, DRAGON SCALE and
  UP-GRADE at $20,000 each.

## 1.69.0
- FILL HOENN REGIONAL DEX > GET A SPECIAL WISH, Ruby/Sapphire: the AURORA TICKET and BIRTH ISLAND,
  borrowed from your installed Emerald (read from its cache while needed; nothing of Emerald's is
  shipped with the mod). Without Emerald installed, Ruby/Sapphire stay as before.
  - After catching Jirachi, its item ball now holds the AURORA TICKET in Ruby/Sapphire too: a real
    Key Item (id 371) with Emerald's name, description and bag icon.
  - Lilycove harbor: with the ticket, the sailor offers BIRTH ISLAND. NO hands over to his own lines
    (so the EON TICKET's Southern Island still works).
  - Birth Island: Emerald's harbor and island maps and tilesets. The dock sailor sails you back to
    where you left Lilycove; the harbor doorway and the pier door link the two maps.
  - The Deoxys triangle uses Emerald's 11 positions, step limits and colours: touch it again within
    the step limit or it goes back to the start. The last touch shatters it and DEOXYS appears
    (Lv30, Normal Forme, Wilds of Hoenn's HGSS sprite). With INFINITE TRIES FOR RARE PKMN On it stays
    until caught; Off, one try.
  - The triangle is drawn by the mod in Emerald's colours (Emerald's overworld sprites weren't
    needed for the rest).
- Fixed a Lua limit: Birth Island lives in its own file, components/hoenn_all/birth_island.lua.

## 1.68.0
- RUMBLE SETTINGS: PRESS SELECT TO TEST moved right under INTENSITY.
- FILL HOENN REGIONAL DEX, new order: GET OTHER GAME EXCLUSIVES, TRADE WITH LINK C., INFINITE TRIES
  FOR RARE PKMN, GET ALL STARTERS, GET OTHER FOSSIL (Ruby/Sapphire), GET OTHER DEEP SEA ITEM,
  ROAMING HUNTER, GET OTHER BOX LEGENDARY (Ruby/Sapphire), GET EON TICKET, GET A SPECIAL WISH.
- FILL KANTO REGIONAL DEX, new order: GET OTHER GAME EXCLUSIVES, TRADE WITH LINK C., INFINITE TRIES
  FOR RARE PKMN, GET ALL STARTERS, GET OTHER FOSSIL, GET ???.

## 1.67.0
- Fixed: the SELECT box theme from 1.66.0 never switched on (the check for the open box couldn't
  see it from inside the mod sandbox). Its frame now follows the Start Menu theme in all five games.

## 1.66.0
- SELECT box (Item Shortcuts / Instant TMs/HMs) now follows the Start Menu theme: its frame is
  recoloured with the selected theme (Auto follows the game), keeping the game's own frame shape and
  shading. In Ruby/Sapphire the highlight outline on the selected row follows the theme too. The
  inside, the text and the arrow stay as they are, and every other menu keeps the game's own frame.

## 1.65.0
- Fixed (Ruby/Sapphire): Pokédex 2nd screen. Ruby/Sapphire's small font prints lower than
  FireRed's, so the whole screen's small text is raised: the type badges (top right and MOVES tab),
  the LOCATION tab's terrain pills, the STATS lines under the picture (also one row higher, so all
  three stay in the panel), the tab names, and the MOVES / LOCATION rows, which now line up with
  their highlight band. The selection arrow is raised 2 px to match.
- ANIMATED SPRITES only shows each game's own rows: FIRE RED & LEAF GREEN only in FireRed/LeafGreen,
  RUBY & SAPPHIRE only in Ruby/Sapphire, and no scrolling note in Emerald.
- OTHER SYSTEM SETTINGS: SKIP FR & LG RECAPS is hidden in Ruby/Sapphire/Emerald.
- RUMBLE SETTINGS, like the Gen 1/2 mod:
  - ENABLE removed: INTENSITY now has OFF (Off / Low / Medium / High). A save with ENABLE Off gets
    INTENSITY Off. PRESS SELECT TO TEST still plays (at Medium) when it's Off.
  - New: BEFORE WILD BATTLE (one pulse) and BEFORE TRAINER BATTLE (two pulses), both On, as the
    battle transition starts.
  - INTENSITY is on top (its OFF is how rumble is turned off), the other rows alphabetical.

## 1.64.0
- Always on (all five games): OPTION > BUTTON MODE is locked on LR, so L and R always work as L and
  R (several mods need them; L=A turned L into a second A button). The row always shows LR.
- Fixed (Ruby/Sapphire): the Pokédex's "SELECT 2ND SCREEN" hint now sits inside its box (raised into
  it, a bit more room; Ruby/Sapphire have no button icon, so SELECT is written out).
- Fixed (Ruby/Sapphire): the Bag's "Items x/255" box moved up to the strip above the bag picture so
  it no longer covers the bag, sized to its text, with the text inside the box.
- Fixed (Ruby/Sapphire): the Battle HUD's type-colour move frames now go around the move names
  (Ruby/Sapphire's bigger font starts further left and lower than FireRed's).

## 1.63.0
- New sub-menu: FILL HOENN REGIONAL DEX (Ruby/Sapphire/Emerald only; Fill Kanto Regional Dex stays
  FireRed/LeafGreen only). Every option On, alphabetical; the Ruby/Sapphire-only rows are hidden in Emerald.
  - GET A SPECIAL WISH: every Hoenn Pokémon up to #200 caught, talk to Mom. JIRACHI (Lv5) is in your
    room; talk to it and it circles you, then flies down and out. It waits in front of your house.
    In Emerald, catching it leaves an item ball with the AURORA TICKET (Birth Island). Ruby/Sapphire's
    ticket and Birth Island come with the last build of this sub-menu. Jirachi uses Wilds of Hoenn's
    HGSS overworld sprite (assets/sprites/jirachi.png, thanks to poooooby).
  - GET ALL STARTERS: 8 badges, talk to Birch: the last starter waits in a Poké Ball on the lab table.
    Champion, with LATIAS or LATIOS first in the party: Birch gives the starter your rival picked
    (Lv5). Both ask for a nickname.
  - GET EON TICKET: Champion with LATIAS or LATIOS caught, talk to Dad at the Petalburg Gym. The
    ticket opens the Southern Island ferry in Lilycove.
  - GET OTHER BOX LEGENDARY (Ruby/Sapphire): Champion, RAYQUAZA caught, and RAYQUAZA plus your game's
    weather legend in the 1st and 2nd slots (either order): the other one (Lv45) is at the bottom of
    the Cave of Origin, where yours was.
  - GET OTHER DEEP SEA ITEM: 8 badges, Storage Key used and the Scanner given to Captain Stern: he
    trades the other Deep Sea item for the Storage Key.
  - GET OTHER FOSSIL (Ruby/Sapphire): 8 badges, your fully evolved fossil Pokémon first in the party:
    the Devon scientist gives you the other one (Lv20).
  - GET OTHER GAME EXCLUSIVES: Ruby/Sapphire: Seedot/Lotad, Nuzleaf/Lombre, Mawile/Sableye,
    Zangoose/Seviper, Solrock/Lunatone each have a 50% chance to be the other version's. Emerald:
    Seviper -> Zangoose and Solrock -> Lunatone at 50%, and Surskit, Meditite, Medicham and Roselia
    get Ruby/Sapphire's own slots (levels and rates read from your installed Ruby or Sapphire; a slot
    is only used if its Emerald Pokémon is still in another slot of that spot). Works with Wilds of
    Hoenn's visible Pokémon and the Pokédex LOCATION tab.
  - INFINITE TRIES FOR RARE PKMN: the Regis, Groudon, Kyogre, Rayquaza, Latias/Latios (Southern
    Island and roaming), Jirachi, Deoxys, Mew, Lugia, Ho-Oh and Sudowoodo stay when they aren't
    caught (beaten, ran, whited out). Story flags are still set; only their own hide/beaten flags
    are skipped.
  - ROAMING HUNTER: on the roaming Latias/Latios's route, every encounter is it, and it never runs
    from the battle. Its roaming is unchanged. With Wilds of Hoenn, only one shows at a time.
  - TRADE WITH LINK C.: the GameCube in your room, with KADABRA, GRAVELER, MACHOKE, SEADRA holding a
    DRAGON SCALE or CLAMPERL holding a DEEPSEATOOTH / DEEPSEASCALE in the party: Link C. trades them,
    they evolve, and he trades them back (once each, 6 trades).
- Built against G1R Deluxe 0.3.97's source.

## 1.62.0
- FILL KANTO REGIONAL DEX > GET OTHER GAME EXCLUSIVES (FireRed/LeafGreen): Electabuzz and Magmar
  are back in the other game's spots, now as part of this option (no separate toggle).
  LeafGreen's Power Plant has Electabuzz (Lv32/35, where FireRed has it, instead of Magneton)
  and FireRed's Mt. Ember has Magmar (Lv38/40, instead of Spearow), so both games have
  Electabuzz in the Power Plant and Magmar on Mt. Ember. 1.61.0 had taken them out along
  with the Wilds of Hoenn Fix toggle.
  - The pair is left out of the 50% swap: an Electabuzz stays an Electabuzz, a Magmar a Magmar.
  - Shows in Wilds of Hoenn (visible and Classic Encounters) and in the Pokédex LOCATION tab.
  - With the option Off, both games have their own tables again.

## 1.61.0
- Removed: OVERWORLD SCREEN > WILDS OF HOENN FIX. With Wilds of Hoenn 1.10.4+, GET OTHER GAME
  EXCLUSIVES already shows Electabuzz and Magmar (and every other exclusive) as visible
  Pokémon, so the extra Power Plant / Mt. Ember slots aren't needed. Electabuzz and Magmar
  now take part in the 50% swap like every other exclusive pair (FireRed's Power Plant
  Electabuzz can be Magmar, LeafGreen's Mt. Ember Magmar can be Electabuzz), and the
  Pokédex LOCATION tab shows them that way.

## 1.60.0
- FILL KANTO REGIONAL DEX > GET OTHER GAME EXCLUSIVES now works with Wilds of Hoenn 1.10.4+
  (its new spawn filter): the 50% swap happens when a visible Pokémon appears, not when the
  battle starts. You now see the other game's exclusives walking around (Growlithe in the
  Pokémon Mansion in LeafGreen, not just Vulpix), and the one you touch is the one you fight.
  - Battles against a visible Wilds of Hoenn Pokémon are no longer swapped a second time.
  - Classic step encounters, fishing and Rock Smash keep the battle-time swap as before.
  - With an older Wilds of Hoenn, nothing changes (battle-time swap only).

## 1.59.0
- Pokédex 2nd screen > LOCATION (FireRed/LeafGreen) now follows FILL KANTO REGIONAL DEX >
  GET OTHER GAME EXCLUSIVES. With it On, each exclusive shows where it can really be met:
  its own spots and its counterpart's spots, each at half the rate, since every encounter of
  either one has a 50% chance to be the other (e.g. Shellder in LeafGreen: Staryu's fishing
  spots at half Staryu's rate). Its counterpart's rates are halved the same way.
  - Electabuzz and Magmar keep their own spots only while the WILDS OF HOENN FIX is On (they're
    left out of the swap then, and the fix already puts them in both games).
  - Rates that end in a half show one decimal (e.g. 7.5%). With the option Off, or in
    Ruby/Sapphire/Emerald, nothing changes.

## 1.58.0
- Fixed (FireRed/LeafGreen, GET OTHER FOSSIL): the Cinnabar Lab scientist wouldn't revive the
  fossil traded from Miguel ("Aiyah! You come again!"). Found in the game's own script: he
  decides which fossils you have from the Mt. Moon "got Helix / got Dome" flags, not from the
  bag, and after the Old Amber he checks only one of them to decide he's done.
  - Miguel's trade now sets the "got" flag of the fossil he gives; saves that already traded
    get it on load.
  - While you're in the scientist's room with one Mt. Moon fossil revived and the other not,
    the revived one's "got" flag is hidden so he sees the one still to do. It's back the moment
    you leave the room (or on the next load if you saved in there). Once both are revived,
    nothing is hidden.
- Removed 1.56.0/1.57.0's fossil fixes (they were aimed at the wrong values).

## 1.57.0
- Fixed (FireRed/LeafGreen): the Cinnabar Lab scientist saying "Aiyah! You come again!" and
  never asking for another fossil. He kept the last fossil (e.g. Old Amber) on record after
  already handing its Pokémon over (seen with an edited save). That leftover is now cleared
  when you change maps, but only when that fossil's "revived" flag is set, so a fossil he's
  really working on is never touched. Replaces 1.56.0's revive safety net, which looked at
  the wrong value. Always on.

## 1.56.0
- New: RUMBLE SETTINGS > PRESS SELECT TO TEST (under INTENSITY). Left/Right or A picks NOT VERY
  EFF. / EFFECTIVE / SUPER EFF., and SELECT plays that hit's rumble at the current INTENSITY,
  so you can set the intensity right there. Works even with ENABLE off. All five games.
- Fixed: changing INTENSITY gave no sample pulse since 1.55.0's new rumble patterns.
- Fixed (FireRed/LeafGreen): the Cinnabar Lab scientist could keep saying "Aiyah! You come
  again!" forever if the game missed you leaving his room (e.g. with an edited save). Now,
  whenever you're anywhere else while he's still reviving a fossil, it's marked ready, the same
  as leaving the room. Always on.

## 1.55.0
- BAG > SORT BY CATEGORY now uses Project Highlander's own order (DESC is the same list
  upside down), in all five games:
  - ITEMS: HP healing from weak to strong (Potion, Berry Juice, Fresh Water, Super Potion,
    Energy Powder, Soda Pop, Lemonade, Moomoo Milk, Hyper Potion, Energy Root, Max Potion,
    then Revive, Revival Herb, Max Revive, Sacred Ash), status healing, HP + status (Full
    Restore), PP healing, held & battle-enhancing items, valuable / sellable items (cheapest
    first), battle / misc items (X items, Poké Doll, Fluffy Tail, mail), stat-boosting items &
    vitamins, evolution stones, repels & dungeon items (Repels, Escape Rope, White/Black Flute).
  - KEY ITEMS: bikes, Town Map, Teachy TV, rods, cases / pouches / jars, fossils & Old Amber,
    keys, passes & tickets, then everything else.
  - POKé BALLS: Poké Ball, Great Ball, Ultra Ball, Master Ball, then the others.
- Fixed: the 255-item bag limit stopped at each pocket's own limit (FireRed/LeafGreen: Items
  42, Key Items 30, Poké Balls 13). The game puts those limits back every time the Bag opens;
  they're now raised in the game's own settings and again after every reset.
- New: BATTLE SCREEN > LOW HP WARNING: NORMAL (the game's looping beep), REDUCED (a few beeps
  when your HP bar turns red, then quiet until it leaves the red and comes back, or another
  Pokémon comes out), OFF. Default NORMAL.
- Fixed (FireRed/LeafGreen): TM CASE type badges showing two types' colours (same badge sheet
  as the Pokédex fix in 1.29.0). The TM Case, Summary and Move Relearner now use the mod's
  one-colour badges.
- RUMBLE SETTINGS: the hit kinds now feel different, not just a little stronger or weaker:
  not very effective = one light tap, effective = one solid pulse, super effective = two
  strong pulses. INTENSITY now changes length as well as strength (phones only use length).

## 1.54.0
- New: OVERWORLD SCREEN > WILDS OF HOENN FIX (FireRed/LeafGreen, On by default).
  Electabuzz and Magmar are the only exclusive pair the two games put in different places
  (checked against both ROMs' wild tables), so the 50% battle-time swap could never put them
  where the other game has them, and Wilds of Hoenn never showed them. With this on:
  - LeafGreen's Power Plant has Electabuzz (Lv32 and Lv35) in the two slots FireRed uses,
    instead of Magneton.
  - FireRed's Mt. Ember has Magmar (Lv38 and Lv40) in the two slots LeafGreen uses, instead of
    Spearow.
  - They're in the game's own wild tables, so they show up as visible Pokémon with Wilds of
    Hoenn and in normal random encounters too. Electabuzz and Magmar are left out of GET OTHER
    GAME EXCLUSIVES' battle-time swap, so you fight the one you see.
  Turning it off puts the original slots back (re-enter the area to refresh visible Pokémon).

## 1.53.0
- GAME CORNER CHEATS > 2X COINS FOR CASH: the clerk's price list now reads 100 COINS / ¥1,000
  and 1000 COINS / ¥10,000 (it still said 50 / 500). FireRed/LeafGreen draw that list in the
  Prize Corner window, not the plain choice list the mod was changing.
- FILL KANTO REGIONAL DEX > INFINITE TRIES is now INFINITE TRIES FOR RARE PKMN, and it works
  like Gen 1: Articuno, Zapdos, Moltres, Mewtwo and both Snorlax stay on the spot when a battle
  ends without a catch (beaten, ran or whited out). The game's own "fought it" flag and its
  removal are skipped, and "... flew away!" reads "... is still here!". Only a catch makes
  them go away.
- FILL KANTO REGIONAL DEX > TRADE W/ LINK C. is now TRADE WITH LINK C.

## 1.52.0
- Sub-menus reorganised (hub stays alphabetical):
  ANIMATED SPRITES, BATTLE SCREEN, CUSTOM BORDERS, FILL KANTO REGIONAL DEX (FR/LG),
  FULL CONTROL, GAME CORNER CHEATS, OTHER SYSTEM SETTINGS, OVERWORLD SCREEN, POKéMOVES,
  RUMBLE SETTINGS, SHORTCUTS SETTINGS, START MENU SETTINGS.
  - BATTLE HUD -> BATTLE SCREEN, now with ALWAYS BOOSTED EXP, MODERN EXP SHARING and
    UNLIMITED PP (from QoL).
  - New OVERWORLD SCREEN: INFINITE SAFARI STEPS (was Infinite Safari), REMATCH ANYONE,
    ANYTIME, RUN EVERYWHERE, SPARKLING HIDDEN ITEMS, USE REPEL AGAIN? (from QoL).
  - QOL -> OTHER SYSTEM SETTINGS: Bag on Specific Pouch, Box Exclusive, Decapitalize Words,
    Display XP in Party Menu, Skip FR & LG Recaps.
  - GET ALL KANTO PKMN -> FILL KANTO REGIONAL DEX, GAME CORNER -> GAME CORNER CHEATS,
    RUMBLE -> RUMBLE SETTINGS, SHORTCUTS -> SHORTCUTS SETTINGS, START MENU -> START MENU
    SETTINGS.
- Every setting is now On by default (Border: Automatic, Border/Theme scope: By Game,
  Screen Ratio: 16:9). Choices without an On, Automatic or By Game value keep their default:
  Bag on Specific Pouch (Off), Slot Odds (Normal), Loop Animations (Medium), Rumble
  Intensity (Medium) and the shortcut picks. Settings you already changed keep your value.

## 1.51.0
- ANIMATED SPRITES > LOOP ANIMATIONS is now OFF / SLOW / MEDIUM / FAST: the animation replays
  every 5 / 2.5 / 1.5 seconds. Default MEDIUM; a saved On becomes FAST, Off stays OFF.
- Ruby/Sapphire fixes:
  - Animated Sprites: the scrolling note stays inside the page's border.
  - "PokéBall Shortcuts Active": the text sits inside its box (taller box for R/S's font).
  - Display Enemy HP: the enemy's HP numbers are raised to the same row as yours.

## 1.50.0
- ANIMATED SPRITES > LOOP ANIMATIONS: really fixed. The check for "is the battle menu open?"
  read the game's module list through `package`, which mods aren't given, so it failed every
  frame and the loop never started. It now asks for the battle menu module directly.

## 1.49.0
- ANIMATED SPRITES > LOOP ANIMATIONS: fixed, the animations now loop. The loop was checked from
  a battle-menu step that doesn't run every frame; it now runs from the battle's own frame
  update. A send-out animation the game left behind no longer blocks the loop forever (it's
  ignored once finished or stopped, and given up on after 10 seconds). The Pokémon lookup
  now matches the game's own (side names in single battles).

## 1.48.0
- New sub-menu: OPTIONS > PROJECT HIGHLANDER > ANIMATED SPRITES (first on the hub).
  - BACK ANIMATION (On): your Pokémon's back animation when it's sent out (Emerald's own), and
    while looping. Off: your Pokémon stays still.
  - FIRE RED & LEAF GREEN (Off) / RUBY & SAPPHIRE (On): the game uses Emerald's Pokémon sprites
    (front and back, normal and shiny) everywhere -- battles, Summary, Pokédex, PC, evolutions,
    trades, eggs -- with Emerald's animations. Read from Emerald's own extracted files: nothing is
    shipped with the mod. Deoxys keeps its own game's form; Spinda keeps its own spots.
  - LOOP ANIMATIONS (On): on the FIGHT/BAG/POKéMON/RUN menu and the move list, the Pokémon's
    animation plays again every 1.5 seconds without the cry (the foe's, and yours with Back
    Animation on). It stops the moment you choose an action, so turns and move animations are
    never held up. Works in Emerald too; nothing plays with Battle Scene Off.
  - A scrolling note at the end: Emerald needs to be installed for Ruby, Sapphire, Fire Red and
    Leaf Green to have animated sprites.

## 1.47.0
- GET ALL KANTO PKMN > TRADE W/ LINK C.: now with the trade and evolution animations, like
  Gen 1. "Okay, connect the cable like so!" -> trade animation (your Pokémon for Link C.'s) ->
  your Pokémon evolves -> "OK, now let's trade back." -> trade animation back -> "Thank you
  friend." You keep your own (now evolved) Pokémon.
- Link C. is the Game Boy kid who's on his own in the Celadon Department Store (not one of the
  kids playing together).
- GET OTHER FOSSIL: Miguel is now found by his trainer battle (Super Nerd Miguel), so it's
  always him; standing next to the fossils is only the backup.

## 1.46.0
- New sub-menu (FireRed/LeafGreen only): OPTIONS > PROJECT HIGHLANDER > GET ALL KANTO PKMN.
  Same rules as Gen 1's Get All The Pokémon for the Kanto Regional Dex, without Mr. Fuji's extra
  Eevee and the Karate Master's other fighter (breeding covers those). All Off by default;
  alphabetical, GET ??? last. Progress is saved in the save file.
  - GET ALL STARTERS: with all 8 badges, Oak offers the last Poké Ball on his table (if it's no
    longer there, he hands it over himself). As Champion, with MEWTWO first in your party, Oak
    gives a baby of your rival's starter (Lv. 5).
  - GET OTHER FOSSIL: with all 8 badges, Miguel on Mt. Moon B2F trades the fossil you didn't
    pick for your S.S. TICKET.
  - GET OTHER GAME EXCLUSIVES: wild Ekans/Sandshrew, Oddish/Bellsprout, Psyduck/Slowpoke,
    Growlithe/Vulpix, Shellder/Staryu, Scyther/Pinsir and Electabuzz/Magmar (and their
    evolutions) have a 50% chance to be the other game's one -- grass, water, fishing, rocks,
    Safari Zone. Scripted battles are left alone.
  - INFINITE TRIES (for Limited Encounters): Articuno, Zapdos, Moltres, Mewtwo and the Route 12 /
    16 Snorlax come back the next time you enter the area when a battle ends without a catch
    (the game already brings the birds and Mewtwo back after running; now also after a KO).
  - TRADE W/ LINK C.: the GBA kid in the Celadon Department Store (the southmost one if there
    are two) trade-evolves your KADABRA, HAUNTER, GRAVELER and MACHOKE, once each, and you keep
    your own Pokémon. Pick it from the party; the game's evolution scene plays (no trade
    animation).
  - GET ???: as Champion, with all 150 other Kanto Pokémon caught, Mom has seen a strange little
    Pokémon in the house. It waits upstairs, teleports outside when you get close, then waits in
    front of your house in Pallet Town: MEW, Lv. 50, until you catch it.

## 1.45.0
- New sub-menu: OPTIONS > PROJECT HIGHLANDER > GAME CORNER (same options as Gen 1/2; all Off /
  Normal by default). Celadon (FireRed/LeafGreen) and Mauville (Ruby/Sapphire/Emerald).
  - 2X COINS FOR CASH: the coin clerk gives 100 coins for ¥1,000 and 1000 coins for ¥10,000
    (the game: 50 / 500). Her lines and menu show 100 / 1000 while it's on. (Gen3 never had it
    in QoL, so there was no setting to carry over.)
  - SLOT ODDS: NORMAL (the game's odds) / GENEROUS / LUCKY.
    FireRed/LeafGreen: each spin draws what the reels may steer toward; about half the spins
    draw nothing and can't win. GENEROUS draws twice and keeps the better result (no-win spins
    about 24%, Rocket/7 about 2x as often); LUCKY draws four times (about 6%, Rocket/7 about 4x).
    Ruby/Sapphire/Emerald: the 7s / Reel Time draw and the regular draw get a second try when
    they come up empty (GENEROUS) or three more tries (LUCKY).
  - BIGGER PAYOUTS: every slot win pays double (coins still stop at 9,999).
  - ALL LUCKY MACHINES: every machine plays like the luckiest one (FireRed/LeafGreen: the one
    best machine's table; Ruby/Sapphire/Emerald: the "luckiest" rating, always in a lucky game).

## 1.44.0
- New sub-menu: OPTIONS > PROJECT HIGHLANDER > RUMBLE (Project Highlander Gen3's own rumble).
  - ENABLE (On by default): the controller rumbles when a move hits in battle, in time with the
    hit sound (the moment the target blinks). Super effective: longer and stronger. Not very
    effective: short and light. No effect: none.
  - Your Pokémon getting hit leads with the left motor; hitting the foe leads with the right.
    Works in singles and doubles, on every connected controller that can rumble. With no such
    controller on Android/iOS, the phone's own vibration is used.
  - INTENSITY: Low / Medium / High (Medium). Changing it gives a sample pulse.
  - WHEN I GET HIT (On) and WHEN I HIT (On).

## 1.43.0
- New sub-menu: OPTIONS > PROJECT HIGHLANDER > POKéMOVES (same as Gen 1/2; all Off by default,
  rows in alphabetical order).
  - FORGETTABLE HMS: an HM move can be replaced like any other move -- level up (in and out of
    battle), TMs, HMs, move tutors and the Move Relearner.
  - INSTANT TMS/HMS: A in front of a cut tree, smashable rock, boulder, water, a waterfall (while
    surfing) or a dive spot uses Cut / Rock Smash / Strength / Surf / Waterfall / Dive straight
    away, with no question or "used..." text. Underwater, A also surfaces (B still works).
    SELECT in the overworld lists Sweet Scent, Teleport, Dig, Secret Power (R/S/E), Fly and Flash
    below the Item Shortcuts, for the moves your party can use. The box opens even with no item
    shortcuts set; more than 9 rows show in two columns.
  - MOVE RELEARNING: RELEARN in the Party A menu (after ITEM) opens the game's own Move Relearner
    for that Pokémon. The list also has its earlier forms' level-up moves up to its current level
    (e.g. moves skipped by evolving with a stone). Only shows when there's something to relearn.
    Move Tutor NPCs keep their normal list.
  - NO LEARN HMS: with the badge, a party Pokémon that CAN learn the HM counts as knowing it --
    for the field (A press, Instant TMs/HMs, the game's own scripts) and the Party A menu, which
    lists the HM for that Pokémon.
  - TMS FOREVER: teaching a TM from the Bag or TM Case doesn't use it up (HMs never did; a TM
    given to hold or sold still leaves the Bag).
- Decapitalize Words: TMS / HMS become TMs / HMs.

## 1.42.0
- New sub-menu: OPTIONS > PROJECT HIGHLANDER > FULL CONTROL (same as Gen 1/2, plus L and R).
  - ENABLE (On by default): your binds replace the game's whole button map (keyboard, gamepad,
    raw joystick) and the stock OPTIONS > CONTROLS page is hidden. Off goes back to the stock map.
  - UP, DOWN, LEFT, RIGHT, A, B, START, SELECT, L, R, SPEED+, SPEED- (controller order): one key and
    one pad control each. A on a row, then press and release a key or pad button; DELETE clears it.
    Defaults match the game: arrows / D-pad, Z / A, X / B, ESC / START, TAB / BACK, Q / LB, E / RB,
    1 / RT (SPEED+), 0 / LT (SPEED-). Triggers, stick directions and raw joystick buttons can be bound.
  - LEFT ANALOG FOR D-PAD (On) and RIGHT ANALOG FOR D-PAD (Off).
  - SELECT VISUAL COMBOS (On): Off stops SELECT + pad buttons from running the display hotkeys,
    so those buttons work normally while SELECT is held.

## 1.41.0
- New sub-menu: OPTIONS > PROJECT HIGHLANDER > SHORTCUTS (same as Gen 1/2).
  - BALL SHORTCUTS (Off by default): in a wild battle's FIGHT/BAG/POKéMON/RUN menu,
    SELECT + Up/Down/Left/Right throws the ball set for that direction.
  - SELECT W/ UP / DOWN / LEFT / RIGHT: None, Poké, Great, Ultra, Net, Dive, Nest, Repeat,
    Timer, Luxury, Premier Ball (defaults: Poké / Ultra / Great / None). No Master or Safari Ball.
  - Never in the Safari Zone, against trainers, or in link, double, Frontier/Pyramid or
    scripted battles. A red "PokéBall Shortcuts Active" note shows top-left while it works.
  - ITEM SHORTCUTS (On by default) and ITEM SHORTCUT 1-3 (saved per save; Left/Right cycles the
    allowed Key Items in the bag): SELECT in the overworld opens a box with the shortcuts and CANCEL.
    With none set, SELECT keeps the game's own registered item.
  - FR/LG: Town Map, Bicycle, Itemfinder, Old/Good/Super Rod, Vs. Seeker, Berry Pouch, TM Case.
  - R/S/E: Acro Bike, Mach Bike, Itemfinder, Old/Good/Super Rod, Go-Goggles, Devon Scope,
    Wailmer Pail, Pokéblock Case, Town Map (opens the PokéNav map; closing it returns to the overworld).

## 1.40.0
- New sub-menu: OPTIONS > PROJECT HIGHLANDER > CUSTOM BORDERS (same idea as Gen 1/2).
  - ENABLE (Off by default).
  - BORDER: Automatic (follows the cartridge), FireRed, LeafGreen, Ruby, Sapphire, Emerald,
    Custom 1-4. Art around the 240x160 GBA screen on battles, full-screen menus, the shop view
    and the title/boot screens (G1R draws the overworld across the whole window, so it has none).
  - BORDER SCOPE: By Game / By Save (By Save starts from the By Game choice).
  - SCREEN RATIO: Off / 16:9 -- runs the game in a 16:9 area for 16:10 and other screens
    (Steam Deck...). Same module as Gen 1/2.
- New art: assets/borders/firered.png (flames), leafgreen.png (forest leaves), ruby.png,
  sapphire.png, emerald.png (faceted gems). custom1-4.png are the 3840x2160 template
  (game window at 360,40, 3120x2080); any size with the same proportions works.
- Decapitalize Words: FIRERED / LEAFGREEN become FireRed / LeafGreen.

## 1.39.0 — Milestone build
- QOL section finished: Always Boosted EXP, Decapitalize Words, Infinite Safari, Modern EXP Sharing,
  Rematch Anyone Anytime, Run Everywhere, Sparkling Hidden Items, Unlimited PP and Use Repel Again?
  work in all five games.
- Removed: the temporary "Hidden: ..." test readout of Sparkling Hidden Items.
- Release notes updated for the milestone.

## 1.38.0
- Fixed (SPARKLING HIDDEN ITEMS, root cause): mods run in a sandbox without Lua's `package`
  table, so every `package.loaded[...]` lookup in the QOL code saw no game module at all
  (the readout showed "data -, bundle -, cur -"). All QOL lookups now use `require`, which hands
  back the game's real modules. The test readout stays for this build.
- Also fixed by the same change: Unlimited PP now finds a double/multi-battle partner,
  Modern EXP Sharing updates a benched Pokémon that's on the field in doubles, and Rematch
  reads your party from the save as a backup.

## 1.37.0
- Fixed (SPARKLING HIDDEN ITEMS): hidden items weren't found ("Hidden: 0") because the loaded
  map's list (signs only) was read instead of the map data the game uses for pickups. All the
  game's sources are now combined. The test readout now shows each source's count.

## 1.36.0
- SPARKLING HIDDEN ITEMS test build: while the option is on, a temporary readout at the top-left
  shows "Hidden: N (route) MAP" to find out why the sparkles don't show. Sparkles now have a dark
  outline, are drawn every frame, and have a backup route right after the field is drawn.

## 1.35.0
- Fixed (SPARKLING HIDDEN ITEMS): the sparkles were drawn under the map's top layer, so tall
  grass and tree tops (Viridian Forest...) covered them. They're now drawn over it, and the
  hidden items are read from the map the game has loaded.
- Changed (REMATCH ANYONE, ANYTIME): the "Their team will be Lv. X" line is gone; YES goes
  straight to the battle.

## 1.34.0
- Fixed (REMATCH ANYONE, ANYTIME): the team was set to Lv 5 instead of your lowest level. Party
  Pokémon store their species as names ("CHARMANDER"), which the level check skipped, so it fell
  back to 5. It now uses the game's own species/egg helpers, and re-checks against the exact party
  the battle uses. Their team is evolved for that level and given its level-up moves.
- Fixed (MODERN EXP SHARING): same species check, which would have skipped every benched Pokémon.

## 1.33.0
- Fixed (REMATCH ANYONE, ANYTIME): the team is now also scaled inside the battle start itself,
  and the accepted rematch stays "pending" until that battle begins, so the scaling no longer
  depends on when the game builds the trainer's team.
- New (REMATCH ANYONE, ANYTIME): after YES, a line shows the level their team is set to
  ("Rematch! Their team will be Lv. X."), the level of your lowest-level party Pokémon.

## 1.32.0
- Fixed (REMATCH ANYONE, ANYTIME): the opponent's team is now also scaled when the battle
  actually starts, so it works whatever path the game uses to build the team: every Pokémon
  at the level of your lowest-level party Pokémon, evolved for that level, with the moves
  it would know at that level.
- Changed (DECAPITALIZE WORDS): XP and LR also stay in capitals.

## 1.31.0
- New (QOL, all five games; all Off by default). The QOL page is now in alphabetical order.
  - ALWAYS BOOSTED EXP: every Pokémon gets the traded-Pokémon EXP bonus ("a boosted").
    Your Trainer ID is not touched and nothing starts disobeying.
  - DECAPITALIZE WORDS: words the games write in capitals are written normally
    (Pokémon, Potion, Brock, Route...). HP, PP, PC, TM, HM, ID, OT, PKMN, VS, FR, LG and
    single letters stay in capitals. Braille and text codes are left alone.
  - INFINITE SAFARI: the Safari Zone step counter (Kanto and Hoenn) never runs out; the game
    only ends when you're out of Safari Balls or you leave.
  - MODERN EXP SHARING: every other living party Pokémon gets half of a battler's share,
    with one "The others gained ... EXP. Points!" line. Their level-ups and new moves still show.
  - REMATCH ANYONE, ANYTIME: talk to a beaten trainer for "Would you like a rematch?". Their
    team is set to the level of your lowest-level Pokémon, evolved, with level-up moves. Gym
    leaders included; after a rematch win their badge/TM script is skipped.
  - RUN EVERYWHERE: with the Running Shoes you can run inside buildings in Ruby/Sapphire/Emerald.
    Long grass, hot springs, Pacifidlog logs and Fortree bridges still stop running.
  - SPARKLING HIDDEN ITEMS: a pulsing sparkle marks every hidden item not found yet; it goes
    away once picked up.
  - UNLIMITED PP: your moves never lose PP (Pressure, Spite and Grudge included); moves
    already at 0 PP can be used. Not in link battles.
  - USE REPEL AGAIN?: when a Repel wears off and you still have that kind, the game asks
    "Use another ...?".
- Built and checked against G1R Deluxe 0.3.90.

## 1.30.0
- New (Start Menu, all five games): SAVE stays in the Start Menu. The game's own save prompts
  ("Would you like to save the game?", the overwrite question, "SAVING... DON'T TURN OFF",
  "<name> saved the game.") and its save-info box appear on top of the Start Menu instead of
  over the overworld, and after saving you're back on the Start Menu with the cursor on SAVE.
  The save itself is still the game's own routine. Only when the Project Highlander Start Menu
  is on.

## 1.29.0
- Fixed (Pokédex 2nd screen, FireRed/LeafGreen): some type badges (FLYING, POISON...) showed two
  types' colours. The game's badge sheet as loaded in G1R mixes palettes on some badges, so
  all five games now use the mod's own one-colour type badges (same as Ruby/Sapphire/Emerald).

## 1.28.0
- Fixed (Pokédex 2nd screen, Ruby/Sapphire/Emerald): type badges showed as grey boxes (title
  bar and MOVES tab). Hoenn has no FireRed/LeafGreen badge sheet loaded, so the badges are drawn
  in each type's colour with its name; FireRed/LeafGreen keep the game's own badge art.
- Fixed (LOCATION, Ruby/Sapphire/Emerald): place names showed as raw map ids ("EM_ROUTE102",
  "0:29"). Names now come from the Hoenn map sections (like the map name popup), and the same
  place listed under several ids is shown once.

## 1.27.0
- Fixed (Ruby/Sapphire/Emerald): the Pokédex 2nd screen now opens. Built against the real
  G1R Deluxe 0.3.89 code: the Hoenn Pokédex (src.ui.game3.rse.pokedex) is hooked directly and
  SELECT works on the entry page (AREA / CRY / SIZE / CANCEL), with the "SELECT 2ND SCREEN"
  hint at the top right under CANCEL. FAMILY > A moves the entry page to that Pokémon the
  same way Up/Down does.

## 1.26.0
- Changed (Pokédex): the hint is drawn exactly like START CRY: the game's own SELECT button
  icon and the bottom bar's small white font ("SELECT 2ND SCREEN"). It fits in the gap before
  the right-hand text; if a page has less room it shortens to "2ND SCRN" or "MORE".

## 1.25.0
- New (Pokédex): a "Select 2nd Screen" hint. FireRed/LeafGreen: in the bottom bar right after
  START CRY, on both entry pages. Ruby/Sapphire/Emerald: top right, under CANCEL.
- Changed: SELECT no longer does anything inside the 2nd screen (B goes back).
- Ruby/Sapphire/Emerald: Pokédex screens are also looked for among the game's loaded screens
  (not only the UI stack), and the Pokémon is found from any "species" field.

## 1.24.0
- Changed (Pokédex 2nd screen): tabs switch with the shoulder buttons only (hint now "LB/RB TAB");
  d-pad Left/Right jumps a page up/down in the MOVES and LOCATION lists.
- Changed: STATS shows several abilities on one line, separated by a comma.
- Fixed: LOCATION area tags are wider with their text centred, and the tag column moved left so
  the levels and rate have room.
- Ruby/Sapphire/Emerald: the Pokédex screen is looked for more widely; if SELECT still does
  nothing on an entry page, a ph3_dex_debug.txt is written to the game's save folder.

## 1.23.0
- New (Pokédex, always on): SELECT on a Pokémon's entry page opens a 2nd screen with four tabs
  (L/R or Left/Right to switch, B or SELECT to go back). START still plays the cry.
  Works for seen and caught Pokémon.
  - STATS: picture, base stats with bars and total, catch rate, base EXP, growth rate, abilities.
    A plays the cry.
  - FAMILY: the evolution line with how each one evolves (level, stone, trade, friendship...).
    U/D selects, A jumps to that Pokémon's entry; unseen ones show as ?????.
  - MOVES: LEVEL UP, TM / HM, MOVE TUTOR and EGG MOVES sections with type badges.
    U/D scrolls, A shows the move's power, accuracy, PP and description.
  - LOCATION: where it's found in the wild in the game you're playing (grass, cave, inside,
    surf, Rock Smash, Old/Good/Super Rod) with levels and rate. A opens SORT BY: Location,
    Level, Rate (and reverse of each).
  - Same look as the bag's SORT BY menu: themed title bar and tabs, cream panels, highlight bands.
- New files: components/pokedex/main.lua, data.lua, screen.lua.

## 1.22.0 — Milestone build
- Fixed (Ruby/Sapphire/Emerald): the SORT BY menu couldn't be controlled; the d-pad moved the
  bag behind it. The Hoenn bag reads the d-pad outside its input handler, so while the sort
  menu is open the menu reads the game's own input once per frame, the bag is paused, and the
  bag's cursor and pocket are held where they were. Closing the menu hands control back.

## 1.21.0
- New (Bag, all five games, always on): START opens a SORT BY menu, with the same choices and
  rules as Project Highlander Gen 1/2: CATEGORY ASC, CATEGORY DESC, NAMES A-Z, NAMES Z-A.
  - Category = the games' own item order (balls, medicine, status heals, PP, vitamins, battle
    items, flutes, stones, valuables, held items, mail, berries, TMs then HMs); ties by name.
  - Every pocket is sorted at once; quantities stay, and the cursor stays on the same item.
  - FireRed/LeafGreen: the TM CASE and BERRY POUCH keep the game's own order inside them.
  - The menu: a framed panel with a title bar in your Start Menu theme colour, a highlight on the
    chosen row, the game's cursor arrow and an "A SORT  B CANCEL" hint; the bag dims behind it.
    B or START closes it.
- New file: components/bag/sort.lua.

## 1.20.0
- Changed: the bag counter is a long bar: "Items" on the left, the count right-aligned at the
  end, plenty of room to grow (FireRed/LeafGreen: bottom-left; Ruby/Sapphire/Emerald: top-left).
- Fixed (try 3): Ruby/Sapphire/Emerald counter. The bag screen is now recognised by the name of
  the game file it comes from, and the counter is drawn right after it on the UI stack (so
  menus and messages opened on top still cover it). If the bag isn't on the stack, it's drawn
  whenever a bag screen reports it's open.

## 1.19.0
- Changed: the bag counter is one row ("Items 123/255"): longer and less tall, so three-digit
  counts fit. Same spots as before in both regions.
- Ruby/Sapphire/Emerald: the bag screen is also looked for under "item" screen names.

## 1.18.0
- Fixed: the "Items x/255" counter now shows in Ruby/Sapphire/Emerald. Their bag screen is
  picked up when it opens (it isn't the FireRed/LeafGreen one), and BAG ON SPECIFIC POUCH
  applies to it too.
- Fixed: counter positions were swapped. Ruby/Sapphire/Emerald: top-left under the pocket
  name; FireRed/LeafGreen: bottom-left of the bag picture, above the description.
- Changed: the QOL option is renamed BAG ON SPECIFIC POUCH so its value no longer covers it.

## 1.17.0
- New (Bag, always on): 255-ITEM LIMIT. The bag holds up to 255 different items in total
  (any quantity of each) instead of each pocket's own slot limit.
  - FireRed/LeafGreen: the TM CASE and the BERRY POUCH count as 1 item each; the TMs/HMs
    and berries inside them don't count.
  - Ruby/Sapphire/Emerald: every item counts, TMs/HMs and berries included.
  - An "Items x/255" box shows the count (under the pocket name in FireRed/LeafGreen,
    bottom-left of the bag picture in Ruby/Sapphire/Emerald). It turns red when full.
- New (Bag, FireRed/LeafGreen, always on): SELECT opens the TM CASE (outside battle, when you
  have it). Closing it brings you back to the bag where you were.
- New (QOL): OPEN BAG ON SPECIFIC POUCH: Off / Items / Key Items / Poké Balls (FireRed/
  LeafGreen) and Off / Items / Poké Balls / TMs & HMs / Berries / Key Items (Ruby/Sapphire/
  Emerald). In and out of battle. Off = the game remembers the last pocket.
- New file: components/bag/main.lua.

## 1.16.0
- Fixed (Display XP in Party Menu, Ruby/Sapphire/Emerald): the bottom row of the small boxes'
  HP numbers showed under the XP bar. The HP-number area is now wiped (redrawn from the box's
  own picture) before the XP bar goes on, so nothing peeks out in any of the five games.

## 1.15.0
- Fixed (Display XP in Party Menu): the small boxes' XP frames were wrong when the party
  opened, until a small box had been highlighted once. All XP frames are now copied from
  the highlighted first box, which is on screen as soon as the party opens (its HP frame is
  the same art as the small boxes').

## 1.14.0
- Fixed (Display XP in Party Menu): on boxes that aren't highlighted, the XP frame was too
  big, out of line and white inside. Every XP frame is now copied from the highlighted box
  picture (loaded off-screen if needed), so all boxes match: same size as the HP frame,
  lined up, grey where there's no XP. The frame's corner pixels are left to the box behind.
- Fixed: the first Pokémon's XP numbers were cut off when the XP needed was large
  (e.g. 219/... or 29/3...). They now show in full, right-aligned under the bar.

## 1.13.0
- New (QOL): DISPLAY XP IN PARTY MENU (On by default).
  - First Pokémon: its box is taller, with an XP bar and the XP numbers
    (XP into this level / XP this level needs) under the HP numbers.
  - Other five: the HP numbers make room for an XP bar under the HP bar.
  - The XP frame copies the game's own HP frame, relabelled XP, with a blue fill.
  - Normal party screen only (not the double-battle layout); eggs and "ABLE/NOT ABLE"
    slots stay as they are.
- New file: components/party/xp.lua.

## 1.12.0
- Fixed: with Wilds of Hoenn, the party A menu filled up with ROLE rows. The A menu is now
  reordered in place, so Wilds of Hoenn adds its ROLE row only once, and the row texts move
  with their rows.
- The A menu order is back on: SUMMARY, ROLE, SWITCH, ITEM, RELEARN, HM moves, TM moves,
  CANCEL (in all five games, including Ruby/Sapphire/Emerald where the field moves came first).
- The cursor starts on SUMMARY when the A menu opens.
- Scroll bar for more than 8 entries works with Wilds of Hoenn's row texts.
- The ROLE submenu (Follow / Forage / Fight / Back) is left as Wilds of Hoenn makes it.

## 1.11.0
- Fixed: the party A menu showing up blank in all games. The A menu order and scroll bar
  now only switch on when the game's menu is in a layout Project Highlander recognises;
  otherwise the game's own menu is left untouched (and the reason is written to the log).
- SELECT quick switch is unchanged.

## 1.10.0
- New (Party, always on): SELECT QUICK SWITCH. Press SELECT on a Pokémon to start a switch
  straight away ("Move to where?"), then A or SELECT on the other Pokémon to swap them.
  B cancels.
- New (Party, always on): the A menu is always in this order: SUMMARY, ROLE, SWITCH, ITEM,
  RELEARN, HM moves, TM moves, CANCEL. ROLE (Wilds of Hoenn) and RELEARN (later mod) only
  show when those are added; MAIL sits with ITEM in Ruby/Sapphire/Emerald.
- New (Party): when the A menu has more than 8 entries, it shows 8 at a time with a scroll
  bar and small up/down arrows when there are more options above or below.
- New file: components/party/main.lua.
- Changed: mod.card and the mod description now list the PC, Party, Battle HUD and QOL features.

## 1.9.0
- Changed: COLORED MOVE NAMES frames are back to the earlier 1 px frame around the name
  (no more line under the letters); the type colour fills the empty rows above the name.
  All four frames stay the same size.
- Changed: enemy HUD — the dark shadow now runs unbroken from the box's right edge into
  the pointer triangle, and the left edge of the taller part is 2 px wide like the box above.

## 1.8.0
- Changed: enemy HUD follows the new design — the box simply grows a little taller,
  the HP numbers sit on the same row as the player's, and the pointer triangle ends
  level with the bottom of the box.
- Changed: COLORED MOVE NAMES — all four frames are the same size, with a thick band of
  the type colour along the top and thin type-colour sides and bottom.

## 1.7.0
- Fixed: the enemy HP numbers sit inside their panel instead of running past the bottom.
- Changed: the enemy HP panel is joined to the box — the line between them is gone, so it
  reads as one taller box — and the pointer triangle on the right is lowered to match.
- Changed: COLORED MOVE NAMES frames are thinner (1 px), leaving a gap between each name
  and its frame and between neighbouring frames.

## 1.6.0
- Changed: COLORED MOVE NAMES now draws a frame in the move's type colour with a white
  inside (no more filled 3D box). The pointing arrow stays visible.
- Changed: DISPLAY ENEMY HP is a full-width panel joined under the enemy's box, styled
  like the healthbox itself, with the numbers lined up under the end of the HP bar.
- Confirmed: no HP numbers in double battles (the game only shows the bars there).

## 1.5.0
- New sub-menu: OPTIONS > PROJECT HIGHLANDER > BATTLE HUD.
  - DISPLAY ENEMY HP (On by default): the enemy's current/max HP in numbers on a small
    plate under its HP bar, counting down with the bar. Singles only; hidden for the
    unidentified GHOST.
  - COLORED MOVE NAMES (On by default): each move name sits in a rounded box filled with
    its type colour (same palette as the Gen 1/2 Battle HUD). Hidden Power uses its real type.
- Ready for Fairy: a pink FAIRY colour is included, and Charm, Moonlight and Sweet Kiss
  switch to it once the Fairy type is turned on (components/battle_hud/types.lua).

## 1.4.0 — Milestone build
- Fixed: AUTO-GRAB turns off when you leave the PC (it only lasts while you're in the boxes).
- Fixed: MULTIPLE can now replace party members, like in Gen 1/2.
  - Marked box Pokémon + A on a party slot: they take the party places from that slot on;
    the party members there are swapped into the marked Pokémon's box slots.
  - Marked party Pokémon + A on a box slot: they take the box slots from that slot on;
    Pokémon already there are swapped into the party.
  - Moving inside the boxes still fills the empty slots from the cursor onward.
  - Last-Pokémon, party-full and (Ruby/Sapphire) MAIL rules still apply; nothing moves if a rule fails.

## 1.3.0
- Changed: values on the Project Highlander option pages (ON/OFF, themes, Save Theme)
  are right-aligned at the end of the row in all five games, so they line up and
  never cover the setting's name (fixes the overlap in Ruby/Sapphire/Emerald).
- New (PC, Move Pokémon): SELECT toggles AUTO-GRAB. While it's on, A picks a Pokémon up
  straight away (same as A > MOVE). A green frame and an AUTO-GRAB tag show it's on.
- New (PC, Move Pokémon): MULTIPLE in the A menu. A marks/unmarks Pokémon (orange frames),
  A on an empty box or party slot moves the whole group there, B ends the selection.
  Works across boxes and in/out of the party; keeps the last-Pokémon and party-full rules.
- New (QOL): BOX EXCLUSIVE. The d-pad no longer changes boxes (left/right wrap inside the box);
  use L/R or A on the box name > SWITCH BOX. Off by default.

## 1.2.0
- Changed: icons are flat — the darker shading edges are gone.
- Fixed: the Sapphire theme is a brighter blue, so its background grid shows.
- New: QOL sub-menu (OPTIONS > PROJECT HIGHLANDER > QOL) with "Skip FR & LG Recaps":
  loading a FireRed/LeafGreen save skips the "Previously on your quest..." recap. On by default.
- New: window focus on launch for the Gen 3 games (same fix as Project Highlander):
  when started from the frontend or a shortcut, the game takes keyboard and gamepad focus by itself.
  New file: core/window_focus.lua.

## 1.1.0
- Changed: coloured icons replace the white icons on coloured circles.
- Changed: SAVE now uses a floppy disk icon.
- Fixed: the background grid pattern is now visible on every theme (tinted to match the theme).
- Changed: PokéBox opens Bill's PC "Move Pokémon" directly; leaving it returns to the Start Menu.

## 1.0.0
- New: two-column, five-row Start Menu for FireRed, LeafGreen, Ruby, Sapphire and Emerald.
  - FireRed/LeafGreen: Pokédex, Pokémon, Bag, PokéBox, Trainer, Save, Options, Mods, (empty), Exit.
  - Ruby/Sapphire/Emerald: the same plus PokéNav.
  - Items the game has not unlocked yet are skipped; empty spaces go just before Exit.
  - Safari Zone, Union Room, link rooms, Battle Pyramid/Pike and the Emerald tutorial keep the game's own menu.
- New: PokéBox opens the PC boxes (Withdraw / Deposit / Move) from the Start Menu once you have a Pokémon.
- New: Themes — Auto, FireRed, LeafGreen, Ruby, Sapphire, Emerald; saved per game or per save.
- New: day, date and clock bar (device clock; Hoenn games alternate with the in-game clock every 5 seconds).
- New: Sort Menu (Options > Project Highlander > Start Menu, or SELECT on the Start Menu).
- Settings: OPTIONS > PROJECT HIGHLANDER > START MENU — Enable, Clock, PokéBox, Save Theme, Sort Menu, Theme.
