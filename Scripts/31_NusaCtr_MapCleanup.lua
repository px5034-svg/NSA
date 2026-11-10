-- ============================================================
-- NusaCtr Map Cleanup
-- NusaCtr Map Cleanup
-- Clean weeds / ground trash / poop / corpses
-- UI: NusaWorldToolsWindow
-- ============================================================

local PKG  = "NusaCtr"
local PATH = "UI/NusaCtr"
local WIN  = "NusaWorldToolsWindow"

local View = nil

-- Settings
NusaCtr_MapCleanup_Radius = tonumber(NusaCtr_MapCleanup_Radius) or 0  -- 0 = unlimited
NusaCtr_MapCleanup_AutoEnabled = NusaCtr_MapCleanup_AutoEnabled or false
NusaCtr_MapCleanup_Page = NusaCtr_MapCleanup_Page or 1
local RADIUS_STEPS = { 0, 20, 50, 100, 200, 500 }
local _auto_tick = 0
local AUTO_TICK_EVERY = 180

local function get_pos(thing)
  local x, y = nil, nil
  pcall(function()
    local p = thing.Pos or thing.Key or thing.m_Key
    if p == nil then return end
    if type(p) == "number" then return end
    x = tonumber(p.x or p.X or p[0] or p[1])
    y = tonumber(p.y or p.Y or p[1] or p[2])
  end)
  pcall(function()
    if x == nil and thing.Key then
      local k = thing.Key
      x = tonumber(k.x or k.X)
      y = tonumber(k.y or k.Y)
    end
  end)
  pcall(function()
    if x == nil and thing.GetPos then
      local p = thing:GetPos()
      if p then x = tonumber(p.x or p.X); y = tonumber(p.y or p.Y) end
    end
  end)
  return x, y
end

local function dist2(ax, ay, bx, by)
  if ax == nil or ay == nil or bx == nil or by == nil then return nil end
  local dx, dy = ax - bx, ay - by
  return dx * dx + dy * dy
end

local function is_player_npc(npc)
  local ok = false
  pcall(function() if npc.IsPlayerThing == true then ok = true end end)
  pcall(function()
    if CS and CS.XiaWorld and CS.XiaWorld.Fight and npc.Camp == CS.XiaWorld.Fight.g_emFightCamp.Player then ok = true end
  end)
  return ok
end

local function collect_player_anchors()
  local anchors = {}
  local lis = nil
  pcall(function()
    local map = World and World.map or Map
    if map and map.Things then lis = map.Things.m_lisNpcs or map.Things.npcs end
  end)
  if lis == nil then return anchors end
  local count = 0
  pcall(function() count = lis.Count end)
  local function add(npc)
    if npc == nil then return end
    if not is_player_npc(npc) then return end
    local dead = false
    pcall(function() if npc.IsDead == true then dead = true end end)
    if dead then return end
    local x, y = get_pos(npc)
    if x and y then anchors[#anchors + 1] = { x = x, y = y } end
  end
  if count and count > 0 then
    for i = 0, count - 1 do
      local npc = nil
      pcall(function() npc = lis[i] end)
      if npc == nil then pcall(function() npc = lis:get_Item(i) end) end
      add(npc)
    end
  else
    pcall(function() for _, npc in pairs(lis) do add(npc) end end)
  end
  return anchors
end

local function within_radius(thing, anchors, radius)
  if radius == nil or radius <= 0 then return true end
  if anchors == nil or #anchors == 0 then return true end -- no disciples found → don't block
  local nx, ny = get_pos(thing)
  if nx == nil or ny == nil then return true end
  local r2 = radius * radius
  for i = 1, #anchors do
    local a = anchors[i]
    local d = dist2(nx, ny, a.x, a.y)
    if d ~= nil and d <= r2 then return true end
  end
  return false
end

local function current_radius_ctx()
  local radius = tonumber(NusaCtr_MapCleanup_Radius) or 0
  local anchors = nil
  if radius > 0 then anchors = collect_player_anchors() end
  return radius, anchors
end

function NusaCtr_MapCleanup_RadiusText()
  local r = tonumber(NusaCtr_MapCleanup_Radius) or 0
  if r <= 0 then return "Unlimited" end
  return tostring(r)
end

function NusaCtr_MapCleanup_CycleRadius()
  local cur = tonumber(NusaCtr_MapCleanup_Radius) or 0
  local idx = 1
  for i, v in ipairs(RADIUS_STEPS) do
    if v == cur then idx = i; break end
  end
  idx = idx + 1
  if idx > #RADIUS_STEPS then idx = 1 end
  NusaCtr_MapCleanup_Radius = RADIUS_STEPS[idx]
  return NusaCtr_MapCleanup_Radius
end

function NusaCtr_MapCleanup_ResetRadius()
  NusaCtr_MapCleanup_Radius = 0
  return 0
end


local function Pkg()
  local p = UIPackage or (CS and CS.FairyGUI and CS.FairyGUI.UIPackage)
  if p then pcall(function() p.AddPackage(PATH) end) end
  return p
end

local function Root()
  return (GRoot and GRoot.inst)
    or (CS and CS.FairyGUI and CS.FairyGUI.GRoot and CS.FairyGUI.GRoot.inst)
end

local function Child(view, name)
  local c = nil
  if view then pcall(function() c = view:GetChild(name) end) end
  return c
end

local function Text(obj, value)
  if not obj then return end
  value = tostring(value or "")
  pcall(function() obj.text = value end)
  pcall(function() obj.title = value end)
  pcall(function()
    local t = obj:GetChild("title")
    if t then t.text = value end
  end)
end

local function Visible(obj, on)
  if not obj then return end
  pcall(function() obj.visible = on == true end)
  pcall(function() obj.touchable = on == true end)
end

local function Msg(s)
  s = tostring(s or "")
  if NusaCtr_T then s = NusaCtr_T(s) end
  pcall(function()
    if CS and CS.Wnd_Message then
      CS.Wnd_Message.Show(s, 1, nil, true, "NusaCtr", 0, 0, "")
    end
  end)
  pcall(function()
    if world and world.ShowMsgBox then world:ShowMsgBox(s) end
  end)
end

---------------------------------------------------------------- helpers
local function iter_list(list, fn)
  if list == nil then return 0 end
  local n = 0
  local count = 0
  pcall(function() count = list.Count end)
  if count and count > 0 then
    for i = 0, count - 1 do
      local item = nil
      pcall(function() item = list[i] end)
      if item == nil then pcall(function() item = list:get_Item(i) end) end
      if item ~= nil then
        local ok = false
        pcall(function() ok = fn(item) == true end)
        if ok then n = n + 1 end
      end
    end
    return n
  end
  pcall(function()
    for _, item in pairs(list) do
      if item ~= nil then
        local ok = false
        pcall(function() ok = fn(item) == true end)
        if ok then n = n + 1 end
      end
    end
  end)
  return n
end

local function destroy_thing(thing)
  local done = false
  pcall(function() if thing.Destroy then thing:Destroy(true); done = true end end)
  if not done then pcall(function() if thing.DestroySelf then thing:DestroySelf(); done = true end end) end
  if not done then
    pcall(function()
      local tm = CS.XiaWorld.ThingMgr.Instance or ThingMgr
      if tm and tm.RemoveThing then tm:RemoveThing(thing); done = true end
    end)
  end
  return done
end

local function plant_name(plant)
  local n = ""
  pcall(function() if plant.def and plant.def.Name then n = tostring(plant.def.Name) end end)
  if n == "" then pcall(function() if plant.Def and plant.Def.Name then n = tostring(plant.Def.Name) end end) end
  if n == "" then pcall(function() n = tostring(plant.Name or "") end) end
  return n
end

local function item_def_name(it)
  local n = ""
  pcall(function() if it.def and it.def.Name then n = tostring(it.def.Name) end end)
  if n == "" then pcall(function() if it.Def and it.Def.Name then n = tostring(it.Def.Name) end end) end
  if n == "" then pcall(function() n = tostring(it.Name or "") end) end
  return n
end

---------------------------------------------------------------- Weeds
local WEED_PATTERNS = {
  "Weed", "weed", "Grass", "grass", "Moss", "moss",
  "Wild", "wild", "Liar", "Rumput", "Lumut",
  "Plant_Weed", "Plant_Grass", "Plant_Moss",
  "Thorn", "Bush_Wild", "Flower_Wild",
  "DeadPlant", "Withered", "withered",
}
local CROP_KEEP = {
  "Lingzhi", "Spirit", "Herb_Gong", "Tree_", "Fruit",
  "Rice", "Wheat", "Corn", "Cotton", "Tea", "Bamboo",
  "Ginseng", "Lotus", "Peach", "Farm", "Crop",
}

local function is_likely_weed(plant)
  local yes = false
  pcall(function() if plant.IsWeed == true then yes = true end end)
  pcall(function() if plant.IsWild == true then yes = true end end)
  pcall(function()
    local def = plant.def or plant.Def
    if def and (def.IsWeed == true or def.Wild == true) then yes = true end
  end)
  local name = plant_name(plant)
  if name == "" then return yes end
  for _, k in ipairs(CROP_KEEP) do
    if name:find(k, 1, true) then return false end
  end
  for _, k in ipairs(WEED_PATTERNS) do
    if name:find(k, 1, true) then return true end
  end
  pcall(function()
    if plant.IsDead == true or plant.Withered == true then yes = true end
  end)
  return yes
end

function NusaCtr_CleanWildPlants()
  local removed, checked = 0, 0
  local radius, anchors = current_radius_ctx()
  local list = nil
  pcall(function()
    local tm = CS.XiaWorld.ThingMgr.Instance or ThingMgr
    local ty = nil
    pcall(function() ty = CS.XiaWorld.g_emThingType.Plant end)
    if tm and ty then list = tm:GetThingList(ty) end
  end)
  if list == nil then
    pcall(function()
      if ThingMgr and g_emThingType then
        list = ThingMgr:GetThingList(g_emThingType.Plant)
      end
    end)
  end
  local to_kill = {}
  iter_list(list, function(p)
    checked = checked + 1
    if is_likely_weed(p) then to_kill[#to_kill + 1] = p end
    return false
  end)
  for _, p in ipairs(to_kill) do
    if within_radius(p, anchors, radius) and destroy_thing(p) then removed = removed + 1 end
  end
  Msg("Wild plants cleaned.\nRemoved: " .. tostring(removed) .. " / checked " .. tostring(checked))
  return true
end

---------------------------------------------------------------- Trash
local TRASH_NAME = {
  "Corpse", "Body", "Blood", "Bone", "Ash", "Dust", "Junk", "Trash",
  "Garbage", "Waste", "Rubble", "Debris", "Scrap", "Shell_Empty",
  "Item_Blood", "Item_Bone", "Item_Ash", "Item_Meat_Rot", "Rotten",
  "Poop", "Shit", "Dung", "Manure", "Filth",
}
local KEEP_NAME = {
  "LingStone", "SpiritStone", "Fabao", "Gong_", "Esoterica", "Dan_",
  "Spell", "Manual", "Treasure", "Ring", "Space", "Taiyi",
  "Weapon", "Armor", "Cloth", "Jade", "Crystal",
}

local function is_on_ground(item)
  local in_bag = false
  pcall(function() if item.InBag == true then in_bag = true end end)
  pcall(function() if item.Bag ~= nil then in_bag = true end end)
  pcall(function() if item.AtBag ~= nil then in_bag = true end end)
  pcall(function() if item.OwnerNpc ~= nil then in_bag = true end end)
  pcall(function() if item.IsInBag == true then in_bag = true end end)
  if in_bag then return false end
  local has_key = false
  pcall(function() if item.Key ~= nil and item.Key ~= 0 then has_key = true end end)
  pcall(function() if item.AtMap ~= nil then has_key = true end end)
  return has_key and not in_bag
end

local function is_trash_item(item)
  local name = item_def_name(item)
  for _, k in ipairs(KEEP_NAME) do
    if name:find(k, 1, true) then return false end
  end
  for _, k in ipairs(TRASH_NAME) do
    if name:find(k, 1, true) then return true end
  end
  local junk = false
  pcall(function() if item.IsBroken == true then junk = true end end)
  pcall(function() if tonumber(item.Count or 1) <= 0 then junk = true end end)
  pcall(function() if item.IsTrash == true then junk = true end end)
  return junk
end

function NusaCtr_CleanGroundTrash()
  local radius, anchors = current_radius_ctx()
  local removed, checked, skipped = 0, 0, 0
  local list = nil
  pcall(function()
    local tm = CS.XiaWorld.ThingMgr.Instance or ThingMgr
    local ty = CS.XiaWorld.g_emThingType and CS.XiaWorld.g_emThingType.Item
    if tm and ty then list = tm:GetThingList(ty) end
  end)
  if list == nil then
    pcall(function()
      if ThingMgr and g_emThingType then list = ThingMgr:GetThingList(g_emThingType.Item) end
    end)
  end
  local to_kill = {}
  iter_list(list, function(it)
    checked = checked + 1
    if not is_on_ground(it) then
      skipped = skipped + 1
      return false
    end
    if is_trash_item(it) then to_kill[#to_kill + 1] = it end
    return false
  end)
  for _, it in ipairs(to_kill) do
    if within_radius(it, anchors, radius) and destroy_thing(it) then removed = removed + 1 end
  end
  Msg("Ground trash cleaned.\nRemoved: " .. tostring(removed)
    .. " | checked: " .. tostring(checked)
    .. " | skipped: " .. tostring(skipped))
  return true
end

---------------------------------------------------------------- Poop
local POOP_NAMES = {
  "Item_Shit", "Item_Poop", "Item_Faeces", "Item_Feces",
  "Shit", "Poop", "Faeces", "Feces",
  "Item_AnimalShit", "Item_MonsterShit",
}

local function is_poop_item(it)
  if it == nil then return false end
  local name = item_def_name(it)
  if name == "" then return false end
  for _, k in ipairs(POOP_NAMES) do
    if name == k or name:find(k, 1, true) then return true end
  end
  local low = name:lower()
  if low:find("shit", 1, true) or low:find("poop", 1, true)
    or low:find("faeces", 1, true) or low:find("feces", 1, true) then
    return true
  end
  return false
end

function NusaCtr_CleanPoop(quiet)
  local radius, anchors = current_radius_ctx()
  local removed, checked = 0, 0
  pcall(function()
    if Map and Map.Things and Map.Things.GetNameItemList then
      local shitlist = Map.Things:GetNameItemList("Item_Shit")
      if shitlist ~= nil then
        local tm = CS.XiaWorld.ThingMgr.Instance or ThingMgr
        local kill = {}
        for _, id in pairs(shitlist) do
          local th = nil
          pcall(function() th = tm:FindThingByID(id) end)
          if th then kill[#kill + 1] = th end
        end
        for _, th in ipairs(kill) do
          if within_radius(th, anchors, radius) and destroy_thing(th) then removed = removed + 1 end
        end
      end
    end
  end)
  local list = nil
  pcall(function()
    local tm = CS.XiaWorld.ThingMgr.Instance or ThingMgr
    local ty = CS.XiaWorld.g_emThingType and CS.XiaWorld.g_emThingType.Item
    if tm and ty then list = tm:GetThingList(ty) end
  end)
  if list == nil then
    pcall(function()
      if ThingMgr and g_emThingType then list = ThingMgr:GetThingList(g_emThingType.Item) end
    end)
  end
  local kill2 = {}
  iter_list(list, function(it)
    checked = checked + 1
    if is_poop_item(it) and is_on_ground(it) then
      kill2[#kill2 + 1] = it
    end
    return false
  end)
  for _, it in ipairs(kill2) do
    if within_radius(it, anchors, radius) and destroy_thing(it) then removed = removed + 1 end
  end
  if quiet ~= true then
    Msg("Poop cleaned.\nRemoved: " .. tostring(removed) .. " | checked: " .. tostring(checked))
  end
  return removed
end

---------------------------------------------------------------- Corpses
local function is_corpse(thing)
  local yes = false
  pcall(function() if thing.IsCorpse == true then yes = true end end)
  pcall(function() if thing.Corpse == true then yes = true end end)
  pcall(function()
    local def = thing.def or thing.Def
    if def and def.Name then
      local name = tostring(def.Name)
      if name:find("Corpse") or name:find("corpse") or name:find("Body") then
        yes = true
      end
    end
  end)
  pcall(function()
    if thing.HasSpecialFlag and CS and CS.XiaWorld and CS.XiaWorld.g_emNpcSpecailFlag then
      local f = CS.XiaWorld.g_emNpcSpecailFlag
      if f.FLAG_DEADBODY and thing:HasSpecialFlag(f.FLAG_DEADBODY) then yes = true end
    end
  end)
  return yes
end

function NusaCtr_CleanMapCorpses()
  local removed, checked = 0, 0
  local radius, anchors = current_radius_ctx()
  pcall(function()
    local map = World and World.map or Map
    local lis = nil
    pcall(function() lis = map.Things.m_lisNpcs end)
    if lis == nil then pcall(function() lis = Map.Things.m_lisNpcs end) end
    removed = removed + iter_list(lis, function(npc)
      checked = checked + 1
      local dead = false
      pcall(function() if npc.IsDeath or npc.IsDead then dead = true end end)
      pcall(function() if npc.IsCorpse then dead = true end end)
      if dead then
        local is_player = false
        pcall(function()
          if npc.IsPlayerThing or (CS and CS.XiaWorld and CS.XiaWorld.Fight
            and npc.Camp == CS.XiaWorld.Fight.g_emFightCamp.Player) then
            is_player = true
          end
        end)
        if is_player then return false end
        if not within_radius(npc, anchors, radius) then return false end
          return destroy_thing(npc)
      end
      return false
    end)
  end)
  pcall(function()
    local tm = CS.XiaWorld.ThingMgr.Instance or ThingMgr
    if tm == nil or tm.GetThingList == nil then return end
    local types = {}
    pcall(function()
      local et = CS.XiaWorld.g_emThingType
      if et then
        if et.Item then types[#types + 1] = et.Item end
        if et.Npc then types[#types + 1] = et.Npc end
        if et.None then types[#types + 1] = et.None end
      end
    end)
    if #types == 0 then types = {1, 2, 0} end
    for _, ty in ipairs(types) do
      local list = nil
      pcall(function() list = tm:GetThingList(ty) end)
      removed = removed + iter_list(list, function(th)
        checked = checked + 1
        if is_corpse(th) then if not within_radius(th, anchors, radius) then return false end
          return destroy_thing(th) end
        return false
      end)
    end
  end)
  pcall(function() if Map and Map.ClearCorpses then Map:ClearCorpses() end end)
  pcall(function() if World and World.ClearCorpses then World:ClearCorpses() end end)
  Msg("Corpse cleanup done.\nRemoved: " .. tostring(removed) .. " (checked " .. tostring(checked) .. ")")
  return true
end





---------------------------------------------------------------- Rocks (mineable / blocking) + rocky terrain
local ROCK_KEYS = {
  "RockBrown", "RockGray", "RockJade", "RockLing", "RockMarble", "RockCinnabar",
  "BrownRock", "GrayRock", "IronRock", "CopperRock", "SilverRock", "DarksteelRock",
  "Rock_Brown", "Rock_Gray", "Rock_Jade", "Rock_Ling", "Rock_Marble",
  "MineRock", "MountainRock", "StoneRock", "LittleRock",
  "RockIron", "RockCopper", "RockSilver", "RockDarksteel",
  "Mineral", "OreRock", "StoneLand", "Rocky",
}

local function rock_name(th)
  local n = ""
  pcall(function() if th.def and th.def.Name then n = tostring(th.def.Name) end end)
  if n == "" then pcall(function() if th.Def and th.Def.Name then n = tostring(th.Def.Name) end end) end
  if n == "" then pcall(function() n = tostring(th.Name or th.ThingName or "") end) end
  return n
end

local function is_blocking_rock(th)
  if th == nil then return false end
  local skip = false
  pcall(function() if th.IsPlayerThing == true then skip = true end end)
  if skip then return false end
 -- flag-based (mineable nodes)
  local flagged = false
  pcall(function() if th.CanMine == true then flagged = true end end)
  pcall(function() if th.IsRock == true then flagged = true end end)
  pcall(function() if th.IsMineral == true then flagged = true end end)
  pcall(function() if th.Mineable == true then flagged = true end end)
  pcall(function()
    if th.def and th.def.Mineable == true then flagged = true end
  end)
  if flagged then return true end
  local n = rock_name(th)
  if n == "" then return false end
  for _, k in ipairs(ROCK_KEYS) do
    if n:find(k, 1, true) then return true end
  end
  if n:find("Rock", 1, true) then
    if n:find("Item_", 1, true) and (n:find("Leftover", 1, true) or n:find("Block", 1, true)) then
      return false
    end
    if not n:find("Item_", 1, true) then return true end
  end
  return false
end

function NusaCtr_ClearRocks()
  local removed, checked = 0, 0
  local radius, anchors = current_radius_ctx()
  local tm = nil
  pcall(function() tm = CS.XiaWorld.ThingMgr.Instance or ThingMgr end)
  local types = {}
  pcall(function()
    local et = CS.XiaWorld.g_emThingType
    if et then
      if et.Plant then types[#types + 1] = et.Plant end
      if et.Item then types[#types + 1] = et.Item end
      if et.Building then types[#types + 1] = et.Building end
      if et.None then types[#types + 1] = et.None end
    end
  end)
  if #types == 0 then types = { 1, 2, 3, 0 } end

  local to_kill = {}
  for _, ty in ipairs(types) do
    local list = nil
    pcall(function() if tm then list = tm:GetThingList(ty) end end)
    iter_list(list, function(th)
      checked = checked + 1
      if is_blocking_rock(th) and within_radius(th, anchors, radius) then
        to_kill[#to_kill + 1] = th
      end
      return false
    end)
  end
  pcall(function()
    local map = World and World.map or Map
    if map and map.Things then
      local lis = map.Things.m_lisThings or map.Things.things
      iter_list(lis, function(th)
        checked = checked + 1
        if is_blocking_rock(th) and within_radius(th, anchors, radius) then
          to_kill[#to_kill + 1] = th
        end
        return false
      end)
    end
  end)

  local seen = {}
  for _, th in ipairs(to_kill) do
    local id = tostring(th)
    if not seen[id] then
      seen[id] = true
      if destroy_thing(th) then removed = removed + 1 end
    end
  end

  Msg("Clear rocks done.\nRemoved: " .. tostring(removed)
    .. " / checked " .. tostring(checked)
    .. "\nRock radius: " .. NusaCtr_MapCleanup_RadiusText())
  return removed
end

function NusaCtr_LootAndCleanCorpses()
  local looted, deleted = 0, 0
 -- Prefer AutoLoot if loaded (same radius setting for consistency optional)
  if NusaCtr_AutoLoot_RunOnce then
    local oldR = NusaCtr_AutoLoot_Radius
    local oldDel = NusaCtr_AutoLoot_DeleteAfter
    pcall(function()
      NusaCtr_AutoLoot_Radius = tonumber(NusaCtr_MapCleanup_Radius) or 0
      NusaCtr_AutoLoot_DeleteAfter = true
      local a, b = NusaCtr_AutoLoot_RunOnce()
      looted = tonumber(a) or 0
      deleted = tonumber(b) or 0
      NusaCtr_AutoLoot_Radius = oldR
      NusaCtr_AutoLoot_DeleteAfter = oldDel
    end)
  else
 -- fallback: just clean corpses
    pcall(NusaCtr_CleanMapCorpses)
  end
  Msg("Loot + delete corpses.\nLooted: " .. tostring(looted) .. "\nDeleted: " .. tostring(deleted)
    .. "\nRadius: " .. NusaCtr_MapCleanup_RadiusText())
  return looted, deleted
end

function NusaCtr_MapCleanup_ToggleAuto()
  NusaCtr_MapCleanup_AutoEnabled = not NusaCtr_MapCleanup_AutoEnabled
  return NusaCtr_MapCleanup_AutoEnabled
end

function NusaCtr_MapCleanup_OnRender()
  if not NusaCtr_MapCleanup_AutoEnabled then return end
  _auto_tick = _auto_tick + 1
  if _auto_tick < AUTO_TICK_EVERY then return end
  _auto_tick = 0
 -- auto: poop + weeds only (safer than trash/corpses)
  pcall(function() NusaCtr_CleanPoop(true) end)
  pcall(function() NusaCtr_CleanWildPlants() end)
end

function NusaCtr_MapCleanup_GetSaveData()
  return {
    Radius = tonumber(NusaCtr_MapCleanup_Radius) or 0,
    AutoEnabled = NusaCtr_MapCleanup_AutoEnabled and true or false,
  }
end

function NusaCtr_MapCleanup_ApplySaveData(data)
  if type(data) ~= "table" then return end
  NusaCtr_MapCleanup_Radius = tonumber(data.Radius) or 0
  NusaCtr_MapCleanup_AutoEnabled = data.AutoEnabled and true or false
end

function NusaCtr_CleanAllMapJunk()
  pcall(NusaCtr_CleanWildPlants)
  pcall(NusaCtr_CleanGroundTrash)
  local poop = NusaCtr_CleanPoop(true) or 0
  Msg("Map cleaned (weeds + trash + poop).\nPoop removed: " .. tostring(poop))
  return true
end

---------------------------------------------------------------- UI

local function Lbtn(s)
  s = tostring(s or "")
  if not NusaCtr_T then return s end
  local t = NusaCtr_T(s)
  if t ~= s then return t end
  local prefixes = {
    "Cleanup radius: ", "Rock radius: ", "Auto weeds/poop: ",
    "Radius: ", "Filter: ", "Reputation: ", "Good: ", "Evil: ",
  }
  for i = 1, #prefixes do
    local p = prefixes[i]
    if s:sub(1, #p) == p then
      return NusaCtr_T(p) .. s:sub(#p + 1)
    end
  end
  return s
end

function NusaCtr_MapCleanup_Refresh()
  if not View then return end
  Text(Child(View, "title"), (NusaCtr_T and NusaCtr_T("Map Cleanup") or "Map Cleanup"))
  Text(Child(View, "subtitle"), (NusaCtr_T and NusaCtr_T("Weeds · Trash · Rocks · Corpses · Radius") or "Weeds · Trash · Rocks · Corpses · Radius"))
  Text(Child(View, "brand"), "NusaCtr")
  Text(Child(View, "infoTitle"), (NusaCtr_T and NusaCtr_T("Map Cleanup") or "Map Cleanup"))
  Text(Child(View, "infoStatus"), ((NusaCtr_T and NusaCtr_T("Clean the current map · page ")) or "Clean the current map · page ") .. tostring(NusaCtr_MapCleanup_Page or 1) .. "/2")
  Text(Child(View, "sectionTitle"), (NusaCtr_T and NusaCtr_T("Quick actions") or "Quick actions"))
  Text(Child(View, "description"), (NusaCtr_T and NusaCtr_T("Cleanup radius & Rock radius share the same setting.\n0 = whole map. >0 = around living disciples. Rocky terrain cannot be removed.")) or "Cleanup radius & Rock radius share the same setting.\n0 = whole map. >0 = around living disciples. Rocky terrain cannot be removed.")
  Text(Child(View, "statusText"), ((NusaCtr_T and NusaCtr_T("Page ")) or "Page ") .. tostring(NusaCtr_MapCleanup_Page or 1) .. "/2 | " .. ((NusaCtr_T and NusaCtr_T("Radius: ")) or "Radius: ") .. NusaCtr_MapCleanup_RadiusText() .. " | Auto: " .. (NusaCtr_MapCleanup_AutoEnabled and "ON" or "OFF"))
  Text(Child(View, "btnBack"), (NusaCtr_T and NusaCtr_T("Back") or "Back"))
  Text(Child(View, "btnClose"), "X")

  local page = tonumber(NusaCtr_MapCleanup_Page) or 1
  if page < 1 then page = 1 end
  if page > 2 then page = 2 end
  NusaCtr_MapCleanup_Page = page

  local page1 = {
    { "Weeds", function() NusaCtr_CleanWildPlants() end },
    { "Trash", function() NusaCtr_CleanGroundTrash() end },
    { "Poop", function() NusaCtr_CleanPoop(false) end },
    { "All junk", function() NusaCtr_CleanAllMapJunk() end },
    { "Corpses", function() NusaCtr_CleanMapCorpses() end },
    { "Loot + delete corpses", function() NusaCtr_LootAndCleanCorpses() end },
    {
      "Cleanup radius: " .. NusaCtr_MapCleanup_RadiusText(),
      function()
        local r = NusaCtr_MapCleanup_CycleRadius()
        Msg("Cleanup radius: " .. NusaCtr_MapCleanup_RadiusText()
          .. (r <= 0 and " (whole map)" or " from living disciples"))
        NusaCtr_MapCleanup_Refresh()
      end,
    },
    {
      "Next page ►",
      function()
        NusaCtr_MapCleanup_Page = 2
        NusaCtr_MapCleanup_Refresh()
      end,
    },
  }

  local page2 = {
    {
      "Clear rocks",
      function() NusaCtr_ClearRocks() end,
    },
    {
      "Rock radius: " .. NusaCtr_MapCleanup_RadiusText(),
      function()
        local r = NusaCtr_MapCleanup_CycleRadius()
        Msg("Rock radius: " .. NusaCtr_MapCleanup_RadiusText()
          .. (r <= 0 and " (whole map)" or " from living disciples"))
        NusaCtr_MapCleanup_Refresh()
      end,
    },
    {
      "Reset rock radius",
      function()
        NusaCtr_MapCleanup_ResetRadius()
        Msg("Rock radius reset to Unlimited (whole map)")
        NusaCtr_MapCleanup_Refresh()
      end,
    },
    {
      "Auto weeds/poop: " .. (NusaCtr_MapCleanup_AutoEnabled and "ON" or "OFF"),
      function()
        local on = NusaCtr_MapCleanup_ToggleAuto()
        Msg(on and "Auto cleanup ON (weeds+poop, uses radius)" or "Auto cleanup OFF")
        NusaCtr_MapCleanup_Refresh()
      end,
    },
    {
      "◄ Prev page",
      function()
        NusaCtr_MapCleanup_Page = 1
        NusaCtr_MapCleanup_Refresh()
      end,
    },
  }

  local actions = (page == 2) and page2 or page1
  for i = 1, 8 do
    local btn = Child(View, "feature" .. i)
    local act = actions[i]
    if btn and act and act[1] then
      Visible(btn, true)
      Text(btn, Lbtn(act[1]))
      pcall(function()
        if btn.onClick and btn.onClick.Clear then btn.onClick:Clear() end
        btn.onClick:Add(function()
          if act[2] then pcall(act[2]) end
        end)
      end)
    elseif btn then
      Text(btn, "")
      Visible(btn, false)
    end
  end
end

function NusaCtr_CloseMapCleanup()
  if View then
    pcall(function() View:RemoveFromParent() end)
    pcall(function() View:Dispose() end)
    View = nil
  end
end

function NusaCtr_OpenMapCleanup()
  NusaCtr_CloseMapCleanup()
  local pkg, root = Pkg(), Root()
  if not pkg or not root then Msg("UI missing"); return false end
  local view = nil
  pcall(function() view = pkg.CreateObject(PKG, WIN) end)
  if not view then Msg("Failed to open Map Cleanup window"); return false end
  View = view
  pcall(function()
    root:AddChild(view)
    view.x = (root.width - view.width) / 2
    view.y = (root.height - view.height) / 2
  end)
  local function go_back()
    NusaCtr_CloseMapCleanup()
    if NusaCtr_OpenMain then
      pcall(function() NusaCtr_OpenMain(_G.NusaCtr_LastTarget) end)
    end
  end
  local close = Child(view, "btnClose")
  if close then
    pcall(function()
      if close.onClick and close.onClick.Clear then close.onClick:Clear() end
      close.onClick:Add(go_back)
    end)
  end
  local back = Child(view, "btnBack")
  if back then
    pcall(function()
      if back.onClick and back.onClick.Clear then back.onClick:Clear() end
      back.onClick:Add(go_back)
    end)
  end
  NusaCtr_MapCleanup_Refresh()
  return true
end

_G.NusaCtr_OpenMapCleanup = NusaCtr_OpenMapCleanup
_G.NusaCtr_MapCleanup_OnRender = NusaCtr_MapCleanup_OnRender
_G.NusaCtr_MapCleanup_GetSaveData = NusaCtr_MapCleanup_GetSaveData
_G.NusaCtr_MapCleanup_ApplySaveData = NusaCtr_MapCleanup_ApplySaveData
_G.NusaCtr_LootAndCleanCorpses = NusaCtr_LootAndCleanCorpses
_G.NusaCtr_ClearRocks = NusaCtr_ClearRocks
_G.NusaCtr_CloseMapCleanup = NusaCtr_CloseMapCleanup
_G.NusaCtr_CleanWildPlants = NusaCtr_CleanWildPlants
_G.NusaCtr_CleanGroundTrash = NusaCtr_CleanGroundTrash
_G.NusaCtr_CleanPoop = NusaCtr_CleanPoop
_G.NusaCtr_CleanMapCorpses = NusaCtr_CleanMapCorpses
_G.NusaCtr_CleanAllMapJunk = NusaCtr_CleanAllMapJunk

print("[NusaCtr] Map Cleanup loaded")
