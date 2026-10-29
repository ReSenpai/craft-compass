"""Builds Craft Compass's craft index over AtlasLoot's real Profession/Recipe data.

Usage: python tests/atlasloot_index.py [path to Interface\AddOns]
"""
import pathlib
import sys

import lupa

ADDONS = pathlib.Path(sys.argv[1] if len(sys.argv) > 1 else r"C:\Program Files (x86)\World of Warcraft\_classic_era_\Interface\AddOns")
PROJECT = pathlib.Path(__file__).resolve().parent.parent
lua = lupa.LuaRuntime(unpack_returned_tuples=True)
lua.execute(r"""
unpack = table.unpack
UNKNOWN = "Unknown"
GetSpellTexture = function(id) return id end
GetSpellInfo = function(id) return "Spell" .. id end
local passthrough = setmetatable({}, {__index = function(_, k) return k end})
AtlasLoot = {Data = {}, Locales = passthrough, IngameLocales = passthrough}
function AtlasLoot:GetGameVersionDataTable()
    local useTable = {}
    local dataTable = setmetatable({}, {__newindex = function(t, k, v) for k2, v2 in pairs(v) do useTable[k2] = v2 end end})
    return useTable, dataTable
end
function AtlasLoot:AddInitFunc(f) INIT = f end
function AtlasLoot:GameVersion_GE(v) return v == "BC" end
AtlasLoot.BC_VERSION_NUM = "BC"; AtlasLoot.WRATH_VERSION_NUM = "WRATH"
C_Timer = {NewTicker = function() return {Cancel = function() end} end}
geterrorhandler = function() return error end
""")
load = lua.eval("function(code, name, ...) return assert(load(code, '@' .. name))(...) end")
private = lua.eval("{IS_CLASSIC = true}")
for f in ("Data/Profession.lua", "Data/Recipe.lua"):
    load((ADDONS / "AtlasLootClassic" / f).read_text(encoding="utf-8"), f, "AtlasLootClassic", private)
lua.execute("INIT()")

ns = lua.eval("{}")
lua.execute("NS_CALLBACKS = {}")
lua.execute("ns_holder = nil")
ns.OnLogin = lua.eval("function(cb) table.insert(NS_CALLBACKS, cb) end")
for f in ("Core/Util.lua", "Sources/AtlasLoot.lua"):
    load((PROJECT / f).read_text(encoding="utf-8"), f, "CraftCompass", ns)
lua.execute("for _, cb in ipairs(NS_CALLBACKS) do cb() end")

crafts = ns.Crafts
for name, item in (("Light Leather", 2318), ("Linen Cloth", 2589), ("Peacebloom", 2447), ("Copper Bar", 2840)):
    print(f"{name} ({item}) is a reagent in {len(crafts.ForReagent(item))} crafts")
spell = crafts.ForCreatedItem(2302)
craft = crafts.Get(spell)
print("Handstitched Leather Boots (2302) <- spell", spell, "reagents", list(craft[6].values()), "counts", list(craft[7].values()))
print("Minor Healing Potion (118) <- spell", crafts.ForCreatedItem(118), "recipe item", crafts.GetRecipeItem(crafts.ForCreatedItem(118)))
print("Elixir of Minor Agility (2457) recipe item", crafts.GetRecipeItem(crafts.ForCreatedItem(2457)))
