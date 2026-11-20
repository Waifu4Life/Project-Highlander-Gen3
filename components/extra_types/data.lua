-- Extra Types (Gen 3): every fixed table the part uses.
--
-- TM numbers match Project Highlander Gen1+2: TM51-57 are the Fairy TMs.
-- Species are national dex numbers; the game's own species ids are looked
-- up at run time (Hoenn Pokémon have different internal numbers).
local D = {}

-- The custom type's index. 18-22 are the contest categories on the Ruby/
-- Sapphire/Emerald summary sheet, so FAIRY comes right after them.
D.FAIRY = 23

-- Fixed numbers, so a save always means the same move and the same TM.
-- Move 400 + n and item 650 + n for TM(50 + n).
D.MOVE_BASE = 400
D.ITEM_BASE = 650

-- effect / target / flags use the games' own values (pret battle_moves.h).
-- animFrom = the game's move whose animation is borrowed.
D.MOVES = {
  { tm = 51, id = "DAZZLING_GLEAM", name = "DAZZLE GLEAM", power = 80, accuracy = 100, pp = 10,
    effect = 0, chance = 0, target = 8, flags = 50, animFrom = 148, -- FLASH
    text = "Damages the foe\nwith a flash of\nstrong light." },
  { tm = 52, id = "DISARMING_VOICE", name = "DISARM VOICE", power = 40, accuracy = 0, pp = 15,
    effect = 17, chance = 0, target = 8, flags = 50, animFrom = 48, -- SUPERSONIC
    text = "A charming cry\nthat damages the\nfoe. It never\nmisses." },
  { tm = 53, id = "DRAINING_KISS", name = "DRAININGKISS", power = 50, accuracy = 100, pp = 10,
    effect = 3, chance = 0, target = 0, flags = 51, animFrom = 186, -- SWEET KISS
    drain = 3 / 4,
    text = "A kiss that steals\nHP. The user heals\n3/4 of the damage." },
  { tm = 54, id = "PLAY_ROUGH", name = "PLAY ROUGH", power = 90, accuracy = 90, pp = 10,
    effect = 68, chance = 10, target = 0, flags = 51, animFrom = 4, -- COMET PUNCH
    text = "Plays rough with\nthe foe. May lower\nits ATTACK." },
  { tm = 55, id = "MOONBLAST", name = "MOONBLAST", power = 95, accuracy = 100, pp = 15,
    effect = 71, chance = 30, target = 0, flags = 50, animFrom = 62, -- AURORA BEAM
    text = "Attacks with the\npower of the moon.\nMay lower SP. ATK." },
  { tm = 56, id = "FAIRY_WIND", name = "FAIRY WIND", power = 40, accuracy = 100, pp = 30,
    effect = 0, chance = 0, target = 0, flags = 50, animFrom = 16, -- GUST
    text = "Stirs up a fairy\nwind to strike the\nfoe." },
  { tm = 57, id = "BABY_DOLL_EYES", name = "BABYDOLLEYES", power = 0, accuracy = 100, pp = 30,
    effect = 18, chance = 0, target = 0, flags = 22, priority = 1, animFrom = 204, -- CHARM
    text = "Teary eyes lower\nthe foe's ATTACK.\nAlways goes first." },
}

-- Old moves that become Fairy (their own type, Normal, when the setting is off).
D.OLD_FAIRY_MOVES = { 186, 204, 236 } -- SWEET KISS, CHARM, MOONLIGHT

-- Who learns each TM (national dex numbers). Evolutions are already in the
-- lists. TM56 is the Fairy-type Pokémon only, whatever the settings say.
D.LEARNERS = {
  [51] = { 35, 36, 39, 40, 43, 44, 45, 63, 64, 65, 72, 73, 92, 93, 94, 96, 97, 113, 120, 121, 122, 151,
    170, 171, 175, 176, 177, 178, 182, 187, 188, 189, 196, 200, 203, 209, 210, 242, 251,
    280, 281, 282, 299, 302, 313, 314, 315, 333, 334, 343, 344, 353, 354, 358, 385 },
  [52] = { 35, 36, 39, 40, 280, 281, 282, 300, 301, 333, 334, 350 },
  [53] = { 124, 280, 281, 282, 368, 370 },
  [54] = { 40, 53, 183, 184, 209, 210, 261, 262, 264, 287, 288, 289, 300, 301, 303, 313, 314 },
  [55] = { 35, 36, 43, 44, 45, 163, 164, 182, 282, 333, 334, 337 },
  [56] = { 35, 36, 39, 40, 122, 173, 174, 175, 176, 183, 184, 209, 210, 280, 281, 282, 298, 303 },
  [57] = { 37, 38, 133, 134, 135, 136, 196, 197, 216, 217, 263, 264 },
}

-- Fairy typings (Gen 6 order). "FAIRY" alone = a pure Fairy type.
D.FAIRY_PKMN = {
  [35] = { "FAIRY" }, [36] = { "FAIRY" },                 -- Clefairy, Clefable
  [39] = { "NORMAL", "FAIRY" }, [40] = { "NORMAL", "FAIRY" }, -- Jigglypuff, Wigglytuff
  [122] = { "PSYCHIC", "FAIRY" },                          -- Mr. Mime
  [173] = { "FAIRY" }, [175] = { "FAIRY" },                -- Cleffa, Togepi
  [209] = { "FAIRY" }, [210] = { "FAIRY" },                -- Snubbull, Granbull
  [174] = { "NORMAL", "FAIRY" },                           -- Igglybuff
  [176] = { "FAIRY", "FLYING" },                           -- Togetic
  [183] = { "WATER", "FAIRY" }, [184] = { "WATER", "FAIRY" }, -- Marill, Azumarill
  [280] = { "PSYCHIC", "FAIRY" }, [281] = { "PSYCHIC", "FAIRY" }, [282] = { "PSYCHIC", "FAIRY" }, -- Ralts line
  [298] = { "NORMAL", "FAIRY" },                           -- Azurill
  [303] = { "STEEL", "FAIRY" },                            -- Mawile
}

-- Gen 6 chart rows for Fairy, x10 (20 = 2x, 5 = 1/2x, 0 = no effect).
D.FAIRY_ROWS = {
  { "FAIRY", "FIGHTING", 20 }, { "FAIRY", "DRAGON", 20 }, { "FAIRY", "DARK", 20 },
  { "FAIRY", "FIRE", 5 }, { "FAIRY", "POISON", 5 }, { "FAIRY", "STEEL", 5 },
  { "FIGHTING", "FAIRY", 5 }, { "BUG", "FAIRY", 5 }, { "DARK", "FAIRY", 5 },
  { "POISON", "FAIRY", 20 }, { "STEEL", "FAIRY", 20 }, { "DRAGON", "FAIRY", 0 },
}

-- The extra Nurse Joy. Map names without the game prefix and underscores.
-- She stands on the floor just right of the PC (1.x: she used to stand at
-- 9,2, which is counter top in every Gen 3 center).
-- FireRed/LeafGreen: PC at 11,1, so 12,2.
-- Ruby/Sapphire/Emerald: PC at 10,1, so 11,2. Petalburg's center already has
-- someone standing there, so she is one step further right (12,2).
-- A row's own x/y wins over the list's.
D.NURSES = {
  kanto = {
    x = 12, y = 2,
    { map = "PEWTERCITYPOKEMONCENTER1F", tm = 51 },
    { map = "ROUTE4POKEMONCENTER1F", tm = 57 },
    { map = "CERULEANCITYPOKEMONCENTER1F", tm = 52 },
    { map = "VERMILIONCITYPOKEMONCENTER1F", tm = 55 },
    { map = "ROUTE10POKEMONCENTER1F", tm = 53 },
    { map = "LAVENDERTOWNPOKEMONCENTER1F", tm = 54 },
    { map = "CELADONCITYPOKEMONCENTER1F", tm = 56 },
  },
  hoenn = {
    x = 11, y = 2,
    { map = "PETALBURGCITYPOKEMONCENTER1F", tm = 51, x = 12 },
    { map = "DEWFORDTOWNPOKEMONCENTER1F", tm = 52 },
    { map = "MAUVILLECITYPOKEMONCENTER1F", tm = 53 },
    { map = "FALLARBORTOWNPOKEMONCENTER1F", tm = 57 },
    { map = "FORTREECITYPOKEMONCENTER1F", tm = 54 },
    { map = "MOSSDEEPCITYPOKEMONCENTER1F", tm = 55 },
    { map = "PACIFIDLOGTOWNPOKEMONCENTER1F", tm = 56 },
  },
}
D.NURSE_LID = 0x6E

D.TEXT = {
  gift = "Thank you for being a loyal customer of the POKéMON CENTER.\fHere's a free TM for you!",
  got = "%s got %s %s!",
  full = "Oh, your BAG has no room for this TM...",
  bye = "Have a nice day!",
}

return D
