"""Builds Craft Compass's craft index over AtlasLoot's real Profession/Recipe data.

Usage: python tests/atlasloot_index.py [path to Interface\AddOns]

Runs as Classic Era and, with AtlasLoot Continued, as Forever too: there its own recipes are
indexed, and Season of Discovery's (in the same table) are left out, their spells missing.
"""
import pathlib
import re
import sys

import lupa

ADDONS = pathlib.Path(sys.argv[1] if len(sys.argv) > 1 else r"C:\Program Files (x86)\World of Warcraft\_classic_era_\Interface\AddOns")
PROJECT = pathlib.Path(__file__).resolve().parent.parent
# AtlasLoot Continued and AtlasLoot Classic (with its fork) differ only in the folder.
FOLDER = next(name for name in ("AtlasLootContinued", "AtlasLootClassic") if (ADDONS / name).is_dir())
PROFESSION_FILE = (ADDONS / FOLDER / "Data/Profession.lua").read_text(encoding="utf-8")


def sod_spell_ids():
    """The spells listed after "-- SoD" in AtlasLoot's Classic table."""
    classic = PROFESSION_FILE.split("PROFESSION_DATA.CLASSIC = {", 1)[1].split("\n}", 1)[0]
    sod = classic.split("-- SoD", 1)[1] if "-- SoD" in classic else ""
    return [int(i) for i in re.findall(r"^\s*\[(\d+)\]\s*=", sod, re.M)]


def build(forever):
    lua = lupa.LuaRuntime(unpack_returned_tuples=True)
    lua.execute(r"""
    unpack = table.unpack
    UNKNOWN = "Unknown"
    MISSING_SPELLS = {}
    GetSpellTexture = function(id) return id end
    GetSpellInfo = function(id) if not MISSING_SPELLS[id] then return "Spell" .. id end end
    local passthrough = setmetatable({}, {__index = function(_, k) return k end})
    AtlasLoot = {Data = {}, Locales = passthrough, IngameLocales = passthrough}
    -- AtlasLoot Continued reaches the client's API through its own AtlasLoot.Compat.
    AtlasLoot.Compat = {GetSpellTexture = GetSpellTexture, GetSpellName = GetSpellInfo}
    function AtlasLoot:GetGameVersionDataTable()
        local useTable = {}
        local dataTable = setmetatable({}, {__newindex = function(t, k, v) for k2, v2 in pairs(v) do useTable[k2] = v2 end end})
        return useTable, dataTable
    end
    function AtlasLoot:AddInitFunc(f) INIT = f end
    AtlasLoot.BC_VERSION_NUM = "BC"; AtlasLoot.WRATH_VERSION_NUM = "WRATH"; AtlasLoot.FOREVER_VERSION_NUM = "FOREVER"
    C_Timer = {NewTicker = function() return {Cancel = function() end} end}
    geterrorhandler = function() return error end
    """)
    if forever:
        # Forever has Classic's content and its own, but no TBC, and no Season of Discovery spells.
        lua.execute("""
        function AtlasLoot:GameVersion_GE(v) return false end
        function AtlasLoot:GameVersion_EQ(v) return v == "FOREVER" end
        GetBuildInfo = function() return "1.60.1", "", "", 16001 end
        """)
        missing = lua.eval("MISSING_SPELLS")
        for spell_id in sod_spell_ids():
            missing[spell_id] = True
    else:
        lua.execute("""
        function AtlasLoot:GameVersion_GE(v) return v == "BC" end
        function AtlasLoot:GameVersion_EQ(v) return false end
        GetBuildInfo = function() return "1.15.9", "", "", 11509 end
        """)
    load = lua.eval("function(code, name, ...) return assert(load(code, '@' .. name))(...) end")
    private = lua.eval("{IS_CLASSIC = true}")
    for f in ("Data/Profession.lua", "Data/Recipe.lua"):
        load((ADDONS / FOLDER / f).read_text(encoding="utf-8"), f, FOLDER, private)
    lua.execute("INIT()")

    ns = lua.eval("{}")
    lua.execute("NS_CALLBACKS = {}")
    ns.OnLogin = lua.eval("function(cb) table.insert(NS_CALLBACKS, cb) end")
    for f in ("Core/Util.lua", "Sources/AtlasLoot.lua"):
        load((PROJECT / f).read_text(encoding="utf-8"), f, "CraftCompass", ns)
    lua.execute("for _, cb in ipairs(NS_CALLBACKS) do cb() end")
    return ns.Crafts


print("AtlasLoot folder:", FOLDER)
crafts = build(forever=False)
for name, item in (("Light Leather", 2318), ("Linen Cloth", 2589), ("Peacebloom", 2447), ("Copper Bar", 2840)):
    print(f"{name} ({item}) is a reagent in {len(crafts.ForReagent(item))} crafts")
spell = crafts.ForCreatedItem(2302)
craft = crafts.Get(spell)
print("Handstitched Leather Boots (2302) <- spell", spell, "reagents", list(craft[6].values()), "counts", list(craft[7].values()))
print("Minor Healing Potion (118) <- spell", crafts.ForCreatedItem(118), "recipe item", crafts.GetRecipeItem(crafts.ForCreatedItem(118)))
print("Elixir of Minor Agility (2457) recipe item", crafts.GetRecipeItem(crafts.ForCreatedItem(2457)))

if "PROFESSION_DATA.FOREVER = {" in PROFESSION_FILE:
    crafts = build(forever=True)
    print("Forever: Prowler Steak (238637) <- spell", crafts.ForCreatedItem(238637))
    print("Forever: Tender Wolf Meat (12202) is a reagent in", len(crafts.ForReagent(12202)), "crafts")
    print("Forever: Light Leather (2318) is a reagent in", len(crafts.ForReagent(2318)), "crafts")
    # Forever moved the healing potions to First Aid with new spells, which replace Alchemy's.
    spell = crafts.ForCreatedItem(118)
    print("Forever: Minor Healing Potion (118) <- spell", spell, "profession", crafts.Get(spell)[2])
    print("Forever: Peacebloom (2447) crafts include Alchemy's 2330:", 2330 in list(crafts.ForReagent(2447).values()),
          "and First Aid's 1244431:", 1244431 in list(crafts.ForReagent(2447).values()))
    late_sod = [i for i in sod_spell_ids() if i > 1225000]
    indexed = [i for i in late_sod if crafts.Get(i) and crafts.ForCreatedItem(crafts.Get(i)[1]) == i]
    print(f"Forever: Season of Discovery spells past 1225000: {len(late_sod)}, indexed {len(indexed)}")
