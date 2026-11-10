-- NusaCtr Item Spawner Core
-- Data + spawn logic (no UI)
-- Filter: no Lost Item, no blank icon, no *Base templates, better categories

NusaCtr_ItemSpawner = NusaCtr_ItemSpawner or {}

local itemList, itemMap = nil, nil

local CAT_MAP = {
  ["food"] = "Food", ["Food"] = "Food",
  ["pill"] = "Pills", ["pills"] = "Pills", ["Pills"] = "Pills", ["Pil"] = "Pills",
  ["material"] = "Materials", ["materials"] = "Materials", ["Materials"] = "Materials",
  ["weapon"] = "Weapons", ["weapons"] = "Weapons", ["Weapons"] = "Weapons",
  ["book"] = "Books", ["books"] = "Books", ["Books"] = "Books",
  ["artifact"] = "Artifacts", ["Artifacts"] = "Artifacts",
  ["medicine"] = "Pills", ["Medicine"] = "Pills", ["Obat"] = "Pills",
  ["other"] = "Other", ["Other"] = "Other", ["Lain"] = "Other",
  ["essence"] = "Materials", ["Essence"] = "Materials",
  ["ores"] = "Materials", ["Ores"] = "Materials",
  ["fabric"] = "Materials", ["Fabric"] = "Materials",
  ["Jimat"] = "Artifacts", ["Senjata"] = "Weapons",
  ["Bahan baku"] = "Materials", ["vkski"] = "Food",
}


-- Drawn talismans (Spell_*). Not ThingDefs — spawn via LuaHelper:DropSpell.
local TALISMAN_SPELLS = {
 -- Default
  { id = "Spell_MoveSpeed1", name = "Agility Talisman" },
  { id = "Spell_TempLow1", name = "Cold-resistant Talisman" },
  { id = "Spell_TempHigh1", name = "Heat-resistant Talisman" },
  { id = "Spell_ReadNovel", name = "Story Talisman" },
  { id = "Spell_Hide", name = "Invisibility Talisman" },
 -- Six Edicts / Basic
  { id = "Spell_MoveSpeed2", name = "Spiritual Travelling" },
  { id = "Spell_RecoveryPower", name = "Curer Talisman" },
  { id = "Spell_VisionRadius", name = "Foreseer Talisman" },
  { id = "Spell_Fatigue", name = "Spiritual Cleansing" },
  { id = "Spell_Nutrition", name = "Qi Absorption Talisman" },
  { id = "Spell_Nutrition1", name = "Fasting Talisman" },
  { id = "Spell_Happy", name = "Lasting Joy Talisman" },
  { id = "Spell_LunHui_ShenShen", name = "Prayer Talisman" },
 -- Emperor / Basic books
  { id = "Spell_TempLow2", name = "Supreme Yang Talisman" },
  { id = "Spell_TempHigh2", name = "Supreme Yin Talisman" },
  { id = "Spell_Intelligence", name = "Civil Prosperity" },
  { id = "Spell_Fight", name = "Military Prosperity" },
  { id = "Spell_GlobalEfficiency", name = "Diligence Talisman" },
  { id = "Spell_MadeQualityAddValue", name = "Craftsmanship Talisman" },
  { id = "Spell_Yield", name = "Fertility Talisman" },
  { id = "Spell_Treatment", name = "Medicinal Mastery" },
 -- Five Elemental Qi / Three Caves
  { id = "Spell_MindState1", name = "Tranquil Heart" },
  { id = "Spell_DeepPracticeSpeedSpecialCoefficient1", name = "Heavenly Heart" },
  { id = "Spell_MindState2", name = "Divine Comprehension" },
  { id = "Spell_MindState2_LunHui", name = "Divinity Mind" },
  { id = "Spell_SpeedOfMindStateCoefficientByMoods", name = "Truth Comprehension" },
  { id = "Spell_DeepPracticeSpeedSpecialCoefficient2", name = "Oblivion Comprehension" },
  { id = "Spell_WorldMapFlySpeed", name = "Departing Shadow" },
 -- Craft / Alchemy
  { id = "Spell_FabaoMake_SuccessRateAddV", name = "Riches Talisman" },
  { id = "Spell_FabaoMake_LingInheritRateAddV", name = "Wonder Talisman" },
  { id = "Spell_DanMake_SuccessRateAddV", name = "Tusita Talisman" },
  { id = "Spell_DanMake_YieldAddP", name = "Impermanence Talisman" },
 -- Spring illustrations
  { id = "Spell_Fu", name = "Everlasting Prosperity" },
  { id = "Spell_Lu", name = "Everlasting Status" },
  { id = "Spell_Shou", name = "Everlasting Longevity" },
 -- Armor / barrier
  { id = "Spell_Shield1", name = "Darkarmor Talisman" },
  { id = "Spell_Shield2", name = "Heavenarmor Talisman" },
  { id = "Spell_Shield_Jin", name = "Metalarmor Talisman" },
  { id = "Spell_Shield_Mu", name = "Woodarmor Talisman" },
  { id = "Spell_Shield_Shui", name = "Waterarmor Talisman" },
  { id = "Spell_Shield_Huo", name = "Firearmor Talisman" },
  { id = "Spell_Shield_Tu", name = "Eartharmor Talisman" },
 -- Sword
  { id = "Spell_FaBao1", name = "Sharpsword Talisman" },
  { id = "Spell_FaBao2", name = "Divinesword Talisman" },
  { id = "Spell_FaBao3", name = "Spiritsword Talisman" },
  { id = "Spell_FaBao4", name = "Sacredsword Talisman" },
 -- Curse
  { id = "Spell_FightSkill1", name = "Vilecurse Talisman" },
  { id = "Spell_FightSkill2", name = "Divine Curse Talisman" },
  { id = "Spell_FightSkill3", name = "Spiritcurse Talisman" },
  { id = "Spell_FightSkill4", name = "Sacredcurse Talisman" },
 -- Heaven / latent
  { id = "Spell_TongTian1", name = "Heavensent Talisman" },
  { id = "Spell_TongTian2", name = "Heavenshrouding Talisman" },
  { id = "Spell_TongTian3", name = "Latent Talisman" },
  { id = "Spell_JieTian1", name = "Heavenlent Talisman" },
 -- Shendao (Primordial Symbols)
  { id = "Spell_GodPractice1", name = "Divine Residence" },
  { id = "Spell_GodPractice2", name = "Divine Perception" },
  { id = "Spell_GodPractice3", name = "Divine Authority" },
  { id = "Spell_GodPractice4", name = "Divine Concealment" },
}

local TALISMAN_NAME = {}
for _, t in ipairs(TALISMAN_SPELLS) do TALISMAN_NAME[t.id] = t.name end

local function is_talisman_spell(id)
  id = tostring(id or "")
  return id:sub(1, 6) == "Spell_"
end
function NusaCtr_IsTalismanSpell(id)
  return is_talisman_spell(id)
end
_G.NusaCtr_IsTalismanSpell = NusaCtr_IsTalismanSpell

local function find_drop_helper()
  local helper = nil
  local npc = _G.NusaCtr_LastTarget
  if npc then pcall(function() helper = npc.LuaHelper end) end
  if helper then return helper end
  pcall(function()
    local world = CS and CS.XiaWorld and CS.XiaWorld.World and CS.XiaWorld.World.Instance
    local list = nil
    if world and world.PlayerSchool then
      pcall(function() list = world.PlayerSchool.DiscipleList end)
    end
    if list == nil then return end
    local n = 0
    pcall(function() n = tonumber(list.Count) or 0 end)
    for i = 0, math.max(0, n - 1) do
      local d = nil
      pcall(function() d = list[i] end)
      if d and helper == nil then
        pcall(function() helper = d.LuaHelper end)
      end
    end
  end)
  return helper
end

local function NormCat(c)
  c = tostring(c or "Other")
  if CAT_MAP[c] then return CAT_MAP[c] end
  if CAT_MAP[string.lower(c)] then return CAT_MAP[string.lower(c)] end
  return c
end

local BLANK_ICON_NAMES = {
  [""] = true, ["-"] = true, ["nil"] = true, ["null"] = true,
  ["none"] = true, ["unknown"] = true, ["template"] = true,
  ["lost item"] = true, ["lostitem"] = true,
}

local defCache = {}

local function has_cjk(s)
  if s == nil then return false end
  s = tostring(s)
  for i = 1, #s do
    local b = string.byte(s, i)
 -- rough UTF-8 CJK lead bytes
    if b and b >= 0xE4 and b <= 0xE9 then return true end
  end
  return false
end

local function humanize_item_id(id)
  id = tostring(id or "")
  id = id:gsub("^Item_", "")
  id = id:gsub("^Dan_", "Dan ")
  id = id:gsub("_", " ")
  return id
end

function NusaCtr_GetSpawnerItemDef(id)
  id = tostring(id or "")
  if is_talisman_spell(id) then return nil end
  id = tostring(id or "")
  if id == "" then return nil end
  local cached = defCache[id]
  if cached ~= nil then
    if cached == false then return nil end
    return cached
  end
  local def = nil
  pcall(function()
    local mgr = ThingMgr or CS.XiaWorld.ThingMgr.Instance
    local kind = g_emThingType and g_emThingType.Item or CS.XiaWorld.g_emThingType.Item
    def = mgr:GetDef(kind, id)
  end)
  defCache[id] = def or false
  return def
end

function NusaCtr_SpawnerDisplayName(id, def)
  id = tostring(id or "")
  if TALISMAN_NAME and TALISMAN_NAME[id] then
    return TALISMAN_NAME[id]
  end
  local thing = nil
  if def then
    pcall(function()
      thing = def.ThingName or def.DisplayName or def.Name
    end)
  end
  thing = thing and tostring(thing) or ""
 -- Prefer non-Chinese display name
  if thing ~= "" and not has_cjk(thing) then
    return thing
  end
  local nice = humanize_item_id(id)
  if nice ~= "" then return nice end
  if thing ~= "" then return thing end
  return tostring(id)
end

function NusaCtr_SpawnerIconUrl(def)
  local u = ""
  if def then
 -- Prefer FabaoTexPath (MiBao/fabao real art), then TexPath
    pcall(function()
      local fab = def.FabaoTexPath
      if fab ~= nil then
        local s = tostring(fab)
        if s ~= "" and s ~= "nil" and s ~= "null" then u = s end
      end
    end)
    if u == "" then
      pcall(function()
        local tp = def.TexPath
        if tp ~= nil then
          local s = tostring(tp)
          if s ~= "" and s ~= "nil" and s ~= "null" then u = s end
        end
      end)
    end
    if u == "" then
      pcall(function()
        local alt = def.IconPath or def.Icon or def.SpritePath
        if alt ~= nil then
          local s = tostring(alt)
          if s ~= "" and s ~= "nil" and s ~= "null" then u = s end
        end
      end)
    end
  end
  if u == "nil" or u == "null" then u = "" end
  u = tostring(u or "")
  u = string.gsub(u, "\\", "/")
  return u
end

-- Generic scroll / blank shared icons that usually mean unusable junk entries
local function is_generic_scroll_icon(tp, id, cat)
 -- Only drop known junk system scrolls; empty icon handled elsewhere.
  local low = string.lower(tostring(id or ""))
  if low:find("miraclesite", 1, true) then return true end
  return false
end

-- Abstract / unspawnable / building junk IDs
local function is_junk_id(id)
  id = tostring(id or "")
  if id == "" then return true end
 -- BlackMarket whitelist always keep
  if NusaCtr_BlackMarketWhitelist and NusaCtr_BlackMarketWhitelist[id] then
    return false
  end
  local low = string.lower(id)

 -- abstract base classes only (exact suffix Base)
  if id:match("Base$") and not id:find("Item_", 1, true) then return true end
  if id == "Item" or id == "None" or id == "null" or id == "-" or id == "=" then return true end
 -- Item_*Base abstract (DanBase style without Item_ prefix already handled)
  if id:match("^%a+Base$") then return true end

 -- combat placeholders
  if id:find("Attack", 1, true) and not id:find("Item_", 1, true) then return true end
  if id:match("Attack$") then return true end

 -- lost / empty / template (not "LostSoul" pills — those are Item_Dan_LostSoul handled carefully)
  if low == "lost" or low:find("lostitem", 1, true) then return true end
  if low:find("_lost", 1, true) or low:find("lost_", 1, true) then return true end
  if low == "empty" or low:find("emptyitem", 1, true) then return true end
  if low:find("template", 1, true) then return true end
  if low:find("unknown", 1, true) then return true end
  if low:find("dummy", 1, true) then return true end
  if low:find("testknife", 1, true) or low == "test" then return true end

 -- buildings / furniture (skip if Item_ prefix — real items)
  if not id:find("Item_", 1, true) and not id:find("FengShuiItem_", 1, true) then
    if low:find("building", 1, true) then return true end
    if id:find("Door", 1, true) or id:find("Wall", 1, true) or id:find("Roof", 1, true) then return true end
    if id:find("Gate", 1, true) or id:find("Barrier", 1, true) then return true end
    if id:find("Bed", 1, true) or id:find("Table", 1, true) or id:find("Lantern", 1, true) then return true end
    if id:find("Cushion", 1, true) or id:find("Screen", 1, true) or id:find("Shelf", 1, true) then return true end
    if id:find("BornPoint", 1, true) or id:find("CarryPlace", 1, true) then return true end
    if id:find("WorkPlace", 1, true) or id:find("Stove", 1, true) then return true end
  end

 -- NPC / system tokens but NOT Item_Sys* tools
  if id:find("NPC", 1, true) then return true end
  if id:find("CMD", 1, true) then return true end
  if low:find("npc_", 1, true) then return true end

 -- map plants without Item_
  if id:find("Tree", 1, true) and not id:find("Item", 1, true) then return true end
  if id:find("HideBuild", 1, true) then return true end

  if low:find("miraclesite", 1, true) then return true end
  return false
end

local function is_blank_icon_name(s)
  if s == nil then return true end
  local low = string.lower(tostring(s))
  if low == "" or low == "-" or low == "nil" or low == "null" then return true end
  if BLANK_ICON_NAMES and BLANK_ICON_NAMES[low] then return true end
  if low:find("template", 1, true) then return true end
  if low:find("unknown", 1, true) then return true end
  return false
end

-- Prefer real item defs (prefix heuristics)
local function looks_like_real_item(id)
  id = tostring(id or "")
  if id == "" then return false end
  if id:find("Item_", 1, true) then return true end
  if id:find("Dan_", 1, true) or id:find("Item_Dan", 1, true) then return true end
  if id:find("Fabao", 1, true) or id:find("MiBao", 1, true) then return true end
  if id:find("Food_", 1, true) or id:find("Spell_", 1, true) then return true end
  if id:find("Material_", 1, true) or id:find("Equip_", 1, true) then return true end
  if id:find("Plant_", 1, true) then return true end
  if id:find("Item_Boss", 1, true) then return true end
  if id:find("Boss_", 1, true) and id:find("Item", 1, true) then return true end
  if id:find("SP_", 1, true) then return true end
  if id:find("Yao_", 1, true) then return true end
 -- ThingMgr scan: if def exists we still accept via from_pack path; this is for direct scan
  return false
end

local function def_is_spawnable(id)
  if is_junk_id(id) then return false end
 -- Whitelist: soft pass even if GetDef is slow/missing fields
  local force = NusaCtr_BlackMarketWhitelist and NusaCtr_BlackMarketWhitelist[tostring(id or "")]
  local def = NusaCtr_GetSpawnerItemDef(id)
  if def == nil then
 -- allow known prefixes so pack lists still show even if GetDef lags
    if force then return true end
    local s = tostring(id or "")
    if is_talisman_spell(s) then return true end
    if s:find("Item_", 1, true) or s:find("FengShuiItem_", 1, true) then return true end
 -- allow NusaCtr_ / UUID-style custom items
    if s:find("NusaCtr_", 1, true) then return true end
    if s:match("^%x%x%x%x%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%x%x%x%x%x%x%x%x$") then return true end
    return false
  end

  local tn, tp, desc = "", "", ""
  pcall(function() tn = tostring(def.ThingName or def.DisplayName or def.Name or "") end)
  pcall(function() tp = tostring(def.TexPath or "") end)
  pcall(function() desc = tostring(def.Desc or def.Description or def.Tip or "") end)
  if tp == "nil" or tp == "null" then tp = "" end

  local lowtn = string.lower(tn)
  local lowdesc = string.lower(desc)

 -- Lost Item (all languages)
  if tn == "Lost Item" or tn == "丢失物品" or tn == "遺失物品" or tn == "LostItem" then return false end
  if lowtn:find("lost", 1, true) then return false end
  if lowdesc:find("lost building", 1, true) then return false end
  if lowdesc:find("nobody recognizes", 1, true) then return false end
  if lowdesc:find("(empty)", 1, true) then return false end

 -- must have some identity; icon may come from FabaoTexPath
  local fab = ""
  pcall(function() fab = tostring(def.FabaoTexPath or "") end)
  if fab == "nil" or fab == "null" then fab = "" end
  if tn == "" and tp == "" and fab == "" and not force then return false end
  if tn == "-" or tn == "=" then return false end
  if tp == "" and fab == "" and not force then return false end

  if tn:find("Template", 1, true) or tn:find("Unknown", 1, true) then return false end
  if is_blank_icon_name(tn) or is_blank_icon_name(id) then return false end
  if tostring(id):find("Template", 1, true) or tostring(id):find("Unknown", 1, true) then return false end

  if has_cjk(id) and not tostring(id):find("Item_", 1, true) then return false end

 -- Generic scroll icon on non-book items
  local lowid = string.lower(tostring(id))
  local is_bookish = lowid:find("book", 1, true) or lowid:find("esoterica", 1, true)
    or lowid:find("manual", 1, true) or lowid:find("mijuan", 1, true)
    or lowid:find("gong", 1, true) or lowid:find("spellbook", 1, true)
  if not is_bookish and is_generic_scroll_icon(tp, id, "Other") then
    return false
  end

  return true
end

local function DetectCat(id, def)
  if is_talisman_spell(id) then return "Talisman" end
  local s = string.lower(tostring(id or ""))
  local name = ""
  if def then
    pcall(function()
      name = string.lower(tostring(def.ThingName or def.DisplayName or def.Name or ""))
    end)
  end
  local blob = s .. " " .. name

 -- Pills / Dan first (before food "herb")
  if string.find(blob, "dan_", 1, true) or string.find(blob, "item_dan", 1, true)
    or string.find(blob, "pill", 1, true) or string.find(blob, "elixir", 1, true)
    or string.find(blob, "drug", 1, true) or string.find(blob, "medicine", 1, true)
    then return "Pills" end

 -- Books / manuals
  if string.find(blob, "book", 1, true) or string.find(blob, "manual", 1, true)
    or string.find(blob, "esoterica", 1, true) or string.find(blob, "skillbook", 1, true)
    or string.find(blob, "scroll", 1, true) or string.find(blob, "spellbook", 1, true)
    or string.find(blob, "item_book", 1, true) or string.find(blob, "item_esoterica", 1, true)
    or string.find(blob, "fabao_book", 1, true)
    then return "Books" end

 -- Weapons / equip
  if string.find(blob, "sword", 1, true) or string.find(blob, "blade", 1, true)
    or string.find(blob, "spear", 1, true) or string.find(blob, "mace", 1, true)
    or string.find(blob, "weapon", 1, true) or string.find(blob, "bow", 1, true)
    or string.find(blob, "staff", 1, true) or string.find(blob, "axe", 1, true)
    or string.find(blob, "dagger", 1, true) or string.find(blob, "item_weapon", 1, true)
    or string.find(blob, "equip_", 1, true)
    then return "Weapons" end

 -- Artifacts / fabao / talisman
  if string.find(blob, "artifact", 1, true) or string.find(blob, "fabao", 1, true)
    or string.find(blob, "talisman", 1, true) or string.find(blob, "spell_", 1, true)
    or string.find(blob, "item_boss", 1, true) or string.find(blob, "mibao", 1, true)
    or string.find(blob, "gourd", 1, true) or string.find(blob, "fu_", 1, true)
    then return "Artifacts" end

 -- Food
  if string.find(blob, "food", 1, true) or string.find(blob, "item_food", 1, true)
    or string.find(blob, "meat", 1, true) or string.find(blob, "fish", 1, true)
    or string.find(blob, "rice", 1, true) or string.find(blob, "fruit", 1, true)
    or string.find(blob, "vegetable", 1, true) or string.find(blob, "crop", 1, true)
    or string.find(blob, "grain", 1, true) or string.find(blob, "soup", 1, true)
    or string.find(blob, "meal", 1, true) or string.find(blob, "item_fish", 1, true)
    or string.find(blob, "item_meat", 1, true) or string.find(blob, "item_crop", 1, true)
    or string.find(blob, "crab", 1, true) or string.find(blob, "carp", 1, true)
    then return "Food" end

 -- Materials
  if string.find(blob, "ore", 1, true) or string.find(blob, "wood", 1, true)
    or string.find(blob, "stone", 1, true) or string.find(blob, "material", 1, true)
    or string.find(blob, "ingot", 1, true) or string.find(blob, "herb", 1, true)
    or string.find(blob, "plant", 1, true) or string.find(blob, "crystal", 1, true)
    or string.find(blob, "jade", 1, true) or string.find(blob, "item_stuff", 1, true)
    or string.find(blob, "item_mat", 1, true) or string.find(blob, "rock", 1, true)
    or string.find(blob, "metal", 1, true) or string.find(blob, "silk", 1, true)
    or string.find(blob, "cloth", 1, true) or string.find(blob, "leather", 1, true)
    then return "Materials" end

  return "Other"
end

local function AddItem(data, from_pack)
 -- Accept plain string IDs from ExtraItems list, or {id=, cat=, count=}
  if type(data) == "string" then
    data = { id = data, count = 1 }
  end
  if type(data) ~= "table" then return end
  local id = data.id or data.ID or data.Name or data.name
  if id == nil or tostring(id) == "" then return end
  id = tostring(id)

  if is_junk_id(id) then return end
  if not def_is_spawnable(id) then return end
 -- Packs always OK; ThingMgr scan prefers real prefixes but also allow any spawnable Item_* / known families
  if not from_pack and not looks_like_real_item(id) then
 -- still allow if id looks like ACS item without strict prefix
    local ok_loose = id:find("Item", 1, true) or id:find("Dan", 1, true) or id:find("Fabao", 1, true)
    if not ok_loose then return end
  end

  local def = NusaCtr_GetSpawnerItemDef(id)
  local name = NusaCtr_SpawnerDisplayName(id, def)
  local low_name = string.lower(tostring(name))
  if low_name == "lost item" or low_name:find("lost item", 1, true) then return end
  if is_blank_icon_name(name) then return end

  local cat = data.cat or data.category
  if cat == nil or tostring(cat) == "" or tostring(cat) == "Other" or tostring(cat) == "Lain" then
    cat = DetectCat(id, def)
  else
    cat = NormCat(cat)
 -- still re-detect if mapped to Other
    if cat == "Other" then cat = DetectCat(id, def) end
  end
  local count = tonumber(data.count or data.Count or 1) or 1

  local icon = NusaCtr_SpawnerIconUrl(def)
  local disp = NusaCtr_SpawnerDisplayName(id, def)
  local force = NusaCtr_BlackMarketWhitelist and NusaCtr_BlackMarketWhitelist[id]
 -- skip if still Chinese-only display and id humanize empty (not whitelist)
  if not force and has_cjk(disp) and has_cjk(id) then return end
  local lowdisp = string.lower(tostring(disp or ""))
  if lowdisp:find("miracle site", 1, true) then return end
  if lowdisp:find("auction invitation", 1, true) then return end
  if lowdisp == "rod" then return end
  if not force and is_generic_scroll_icon(icon, id, cat) then return end

  if itemMap[id] == nil then
    itemMap[id] = { id = id, count = count, cat = cat, name = disp, icon = icon }
    itemList[#itemList + 1] = itemMap[id]
  else
    itemMap[id].cat = cat
    itemMap[id].count = count
    itemMap[id].name = disp
    itemMap[id].icon = icon
  end
end

function NusaCtr_RebuildSpawnerItems(force)
  if not force and itemList ~= nil and type(itemList) == "table" and #itemList > 0 then
    return
  end
 -- ensure extra lists loaded (filename order usually loads them; this is a safety net)
  if NusaCtr_ExtraItems == nil then pcall(require, "Scripts/03_NusaCtr_ExtraItems.lua") end
  if NusaCtr_ItemPacks == nil then pcall(require, "Scripts/04_NusaCtr_ItemPacks.lua") end
 -- custom item defs — safe to re-require
  pcall(require, "Scripts/39_NusaCtr_NusaCustom_ItemList.lua")
  pcall(require, "Scripts/45_NusaCtr_AncientEssence_ItemList.lua")
  pcall(require, "Scripts/40_NusaCtr_SupplementalItems.lua")
  pcall(require, "Scripts/41_NusaCtr_BlackMarketWhitelist.lua")
  itemList, itemMap, defCache = {}, {}, {}

 -- 1) Item defs only
  pcall(function()
    local mgr = ThingMgr or CS.XiaWorld.ThingMgr.Instance
    if mgr == nil or mgr.m_mapThingDefs == nil then return end
    local function absorb(defs)
      if defs == nil then return end
      pcall(function()
        for _, def in pairs(defs) do
          if def ~= nil and def.Name ~= nil then
            AddItem({ id = tostring(def.Name), count = 1 }, false)
          end
        end
      end)
      pcall(function()
        if defs.Keys then
          for _, k in pairs(defs.Keys) do
            AddItem({ id = tostring(k), count = 1 }, false)
          end
        end
      end)
    end
    pcall(function()
      local ok, defs = mgr.m_mapThingDefs:TryGetValue(2)
      if defs ~= nil then absorb(defs) end
    end)
    pcall(function()
      local ty = g_emThingType and g_emThingType.Item
      if ty == nil and CS and CS.XiaWorld then ty = CS.XiaWorld.g_emThingType.Item end
      if ty ~= nil then
        local ok, defs = mgr.m_mapThingDefs:TryGetValue(ty)
        if defs ~= nil then absorb(defs) end
      end
    end)
  end)

 -- 2) Extra / packs (allow short names if spawnable)
  if type(NusaCtr_ExtraItems) == "table" then
    for _, d in ipairs(NusaCtr_ExtraItems) do AddItem(d, true) end
 -- also pairs in case non-array
    pcall(function()
      for _, d in pairs(NusaCtr_ExtraItems) do
        if type(d) == "string" or (type(d) == "table" and (d.id or d.Name)) then
          AddItem(d, true)
        end
      end
    end)
  end
  if type(NusaCtr_ItemPacks) == "table" then
    local function absorb_list(list)
      if type(list) ~= "table" then return end
      for _, d in ipairs(list) do AddItem(d, true) end
      pcall(function()
        for _, d in pairs(list) do
          if type(d) == "string" or (type(d) == "table" and (d.id or d.Name)) then
            AddItem(d, true)
          end
        end
      end)
    end
    for _, pack in ipairs(NusaCtr_ItemPacks) do
      if type(pack) == "table" then
        absorb_list(pack.items or pack)
      end
    end
    pcall(function()
      for _, pack in pairs(NusaCtr_ItemPacks) do
        if type(pack) == "table" then absorb_list(pack.items or pack) end
      end
    end)
  end

 -- 3) Final clean pass
  local cleaned = {}
  for _, v in ipairs(itemList) do
    local ok = true
    if is_junk_id(v.id) then ok = false end
    if ok and not def_is_spawnable(v.id) then ok = false end
    if ok then
      local def = NusaCtr_GetSpawnerItemDef(v.id)
      local disp = NusaCtr_SpawnerDisplayName(v.id, def)
      local low = string.lower(tostring(disp or ""))
      if disp == "" or disp == "-" or low == "lost item" or low:find("lost item", 1, true) then ok = false end
      if ok and (low:find("unknown", 1, true) or low:find("template", 1, true)) then ok = false end
      if ok and is_blank_icon_name(disp) then ok = false end
      if ok and NusaCtr_SpawnerIconUrl(def) == "" then ok = false end
 -- refresh category
      if ok then v.cat = DetectCat(v.id, def) end
    end
    if ok then cleaned[#cleaned + 1] = v end
  end
  itemList = cleaned
  itemMap = {}
  for _, v in ipairs(itemList) do itemMap[v.id] = v end

 -- Drawn talismans (always available)
  local fu_icon = ""
  pcall(function()
    if _G.NusaCtr_ResolveTalismanUiIcon then
      fu_icon = _G.NusaCtr_ResolveTalismanUiIcon() or ""
    elseif resolve_talisman_ui_icon then
      fu_icon = resolve_talisman_ui_icon() or ""
    end
  end)
  for _, t in ipairs(TALISMAN_SPELLS or {}) do
    if not itemMap[t.id] then
      local row = { id = t.id, cat = "Talisman", name = t.name, count = 1, icon = fu_icon }
      itemList[#itemList + 1] = row
      itemMap[t.id] = row
    else
      itemMap[t.id].icon = itemMap[t.id].icon or fu_icon
      itemMap[t.id].cat = "Talisman"
      itemMap[t.id].name = itemMap[t.id].name or t.name
    end
  end
  table.sort(itemList, function(a, b) return tostring(a.id) < tostring(b.id) end)

end

function NusaCtr_GetSpawnerItems(category, keyword)
  NusaCtr_RebuildSpawnerItems(false)
  local result = {}
  local cat = tostring(category or "all")
  local search = string.lower(tostring(keyword or ""))
  for _, data in ipairs(itemList or {}) do
    local matchCat = (cat == "all") or (tostring(data.cat) == cat)
    if matchCat then
      local matchSearch = (search == "")
      if not matchSearch then
        local name = tostring(data.name or data.id or "")
        matchSearch = string.find(string.lower(tostring(data.id)), search, 1, true) ~= nil
          or string.find(string.lower(name), search, 1, true) ~= nil
      end
      if matchSearch then result[#result + 1] = data end
    end
  end
  return result
end

function NusaCtr_InvalidateSpawnerItems()
  itemList, itemMap, defCache = nil, nil, {}
end

-- Warm cache once (call from main menu open if desired)
function NusaCtr_WarmSpawnerCache()
  pcall(function() NusaCtr_RebuildSpawnerItems(false) end)
end


local _talisman_icon_cache = nil

local function resolve_talisman_ui_icon()
  if _talisman_icon_cache and _talisman_icon_cache ~= "" then return _talisman_icon_cache end
  local u = ""
 -- 1) ThingDef TexPath / variants
  for _, fid in ipairs({ "Item_SpellLv3", "Item_SpellLv2", "Item_Spell", "Item_SpellPaperLv3", "Item_SpellPaperLv2", "Item_SpellPaper" }) do
    local d = NusaCtr_GetSpawnerItemDef(fid)
    u = NusaCtr_SpawnerIconUrl(d)
    if u == "" and d then
      pcall(function()
        for _, key in ipairs({ "TexPath", "FabaoTexPath", "IconPath", "Icon", "m_sTexPath", "Path" }) do
          local v = d[key]
          if v ~= nil and tostring(v) ~= "" and tostring(v) ~= "nil" then
            u = tostring(v):gsub("\\", "/")
            break
          end
        end
      end)
    end
    if u ~= "" then break end
  end
 -- 2) temp thing
  if u == "" then
    pcall(function()
      local thing = ItemRandomMachine.RandomItem("Item_SpellLv3", nil, 1, 12, 1, 1)
      if thing == nil then thing = ItemRandomMachine.RandomItem("Item_Spell", nil, 1, 12, 1, 1) end
      if thing then
        pcall(function()
          if thing.def then u = tostring(thing.def.TexPath or "") end
        end)
        if u == "" or u == "nil" then
          pcall(function() u = tostring(thing.TexPath or "") end)
        end
        u = tostring(u or ""):gsub("\\", "/")
        if u == "nil" then u = "" end
      end
    end)
  end
  _talisman_icon_cache = u
  return u
end

function NusaCtr_SpawnerIconForId(id)
  id = tostring(id or "")
  if is_talisman_spell(id) then
    return resolve_talisman_ui_icon()
  end
  return NusaCtr_SpawnerIconUrl(NusaCtr_GetSpawnerItemDef(id))
end
_G.NusaCtr_SpawnerIconForId = NusaCtr_SpawnerIconForId
_G.NusaCtr_ResolveTalismanUiIcon = resolve_talisman_ui_icon

function NusaCtr_SpawnItemDirect(id, count)
  local ok, err = pcall(function()
    id = tostring(id or "")
    local remain = math.max(1, tonumber(count) or 1)
 -- Drawn talisman: DropSpell (quality ~95%)
    if is_talisman_spell(id) then
      local helper = find_drop_helper()
      if helper == nil then error("No NPC helper for DropSpell (select a disciple first)") end
      local q = 0.95
      for _ = 1, remain do
        local dok, derr = pcall(function() helper:DropSpell(1, id, q) end)
        if not dok then error(tostring(derr or "DropSpell failed")) end
      end
      return
    end
    if is_junk_id(id) or not def_is_spawnable(id) then
      error("Item cannot be spawned: " .. tostring(id))
    end
    local def = NusaCtr_GetSpawnerItemDef(id)
    if def == nil then error("Item not found: " .. tostring(id)) end
    local map = Map or CS.XiaWorld.World.Instance.map
    local key = map:GetRandomInLifeArea(4)
    if key == nil then error("No drop location") end
    local maxStack = math.max(1, tonumber(def.MaxStack) or remain)
    while remain > 0 do
      local amount = math.min(remain, maxStack)
      local thing = ItemRandomMachine.RandomItem(tostring(id), nil, 1, 12, 1, amount)
      map:DropItem(thing, key, true, true, false, true, 0, false)
      remain = remain - amount
    end
  end)
  return ok, err
end

print("[NusaCtr] ItemSpawner Core loaded (filtered)")
