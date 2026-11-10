-- ============================================================
-- NusaCtr Auto Loot
-- NusaCtr Auto Loot
-- Auto loot mayat / NPC mati + opsi hapus setelah loot
-- UI: NusaWorldToolsWindow
-- ============================================================

local PKG  = "NusaCtr"
local PATH = "UI/NusaCtr"
local WIN  = "NusaWorldToolsWindow"

local View = nil
local _tick = 0

-- Settings (persisted via Mod OnSave/OnLoad)
NusaCtr_AutoLoot_Enabled         = NusaCtr_AutoLoot_Enabled or false
NusaCtr_AutoLoot_DeleteAfter     = (NusaCtr_AutoLoot_DeleteAfter ~= false) -- default true
NusaCtr_AutoLoot_IncludeAnimals  = NusaCtr_AutoLoot_IncludeAnimals or false
-- Radius in tiles; 0 = unlimited
NusaCtr_AutoLoot_Radius          = tonumber(NusaCtr_AutoLoot_Radius) or 0
-- Filter: "all" | "equip" | "bag" | "no_junk"
NusaCtr_AutoLoot_Filter          = NusaCtr_AutoLoot_Filter or "all"

local RADIUS_STEPS = { 0, 20, 50, 100, 200 }
local FILTER_STEPS = { "all", "equip", "bag", "no_junk" }

---------------------------------------------------------------- helpers
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

local function is_player(npc)
  local ok = false
  pcall(function()
    if npc.IsPlayerThing == true then ok = true end
    if npc.Camp == CS.XiaWorld.Fight.g_emFightCamp.Player then ok = true end
  end)
  return ok
end

local function is_dead(npc)
  local dead = false
  pcall(function() if npc.IsDead == true then dead = true end end)
  pcall(function() if npc.Die == true then dead = true end end)
  pcall(function() if npc.IsCorpse == true then dead = true end end)
  return dead
end

local function is_animal(npc)
  local yes = false
  pcall(function()
    if npc.IsAnimal == true or npc.IsBeast == true then yes = true end
  end)
  pcall(function()
    local race = tostring(npc.RaceDefName or npc.Race or "")
    if race:find("Rabbit") or race:find("Boar") or race:find("Chicken")
        or race:find("Turtle") or race:find("Dog") or race:find("Cat")
        or race:find("Beast") or race:find("Animal") then
      yes = true
    end
  end)
  return yes
end

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
      if p then
        x = tonumber(p.x or p.X)
        y = tonumber(p.y or p.Y)
      end
    end
  end)
  return x, y
end

local function dist2(ax, ay, bx, by)
  if ax == nil or ay == nil or bx == nil or by == nil then return nil end
  local dx = ax - bx
  local dy = ay - by
  return dx * dx + dy * dy
end

local function collect_player_anchors()
  local anchors = {}
  local lis = nil
  pcall(function()
    local map = World and World.map or Map
    if map and map.Things then
      lis = map.Things.m_lisNpcs or map.Things.npcs
    end
  end)
  if lis == nil then return anchors end
  local count = 0
  pcall(function() count = lis.Count end)
  local function add(npc)
    if npc == nil then return end
    if not is_player(npc) then return end
    if is_dead(npc) then return end
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

local function within_radius(npc, anchors, radius)
  if radius == nil or radius <= 0 then return true end
  if anchors == nil or #anchors == 0 then return true end
  local nx, ny = get_pos(npc)
  if nx == nil or ny == nil then return true end
  local r2 = radius * radius
  for i = 1, #anchors do
    local a = anchors[i]
    local d = dist2(nx, ny, a.x, a.y)
    if d ~= nil and d <= r2 then return true end
  end
  return false
end

local function iter_npcs(fn)
  local lis = nil
  pcall(function()
    local map = World and World.map or Map
    if map and map.Things then
      lis = map.Things.m_lisNpcs or map.Things.npcs
    end
  end)
  if lis == nil then return 0 end
  local n = 0
  local count = 0
  pcall(function() count = lis.Count end)
  local function one(npc)
    if npc == nil then return end
    local ok = false
    pcall(function() ok = fn(npc) == true end)
    if ok then n = n + 1 end
  end
  if count and count > 0 then
    for i = 0, count - 1 do
      local npc = nil
      pcall(function() npc = lis[i] end)
      if npc == nil then pcall(function() npc = lis:get_Item(i) end) end
      one(npc)
    end
  else
    pcall(function() for _, npc in pairs(lis) do one(npc) end end)
  end
  return n
end

local function drop_item_near(item, npc)
  if item == nil then return false end
  local ok = false
  pcall(function()
    if item.Drop then item:Drop(); ok = true end
  end)
  pcall(function()
    if item.PutDown then item:PutDown(); ok = true end
  end)
  pcall(function()
    local pos = npc.Pos or npc.Key
    if item.SetPos and pos then item:SetPos(pos); ok = true end
  end)
  pcall(function()
    if Map and Map.Things and Map.Things.DropItem then
      Map.Things:DropItem(item, npc.Pos)
      ok = true
    end
  end)
  return ok
end

local function is_junk_item(item)
  if item == nil then return true end
  local name = ""
  pcall(function()
    name = tostring(item.def and (item.def.Name or item.def.DisplayName) or item.Name or item.ThingName or "")
  end)
  name = string.lower(name)
  if name == "" or name == "nil" then return false end
  local junk_keys = {
    "poop", "dung", "feces", "shit",
    "trash", "junk", "garbage", "rubbish",
    "weed", "grass", "straw",
    "bone", "scrap",
    "dirt", "mud", "stonechip",
    "rotten", "spoiled",
  }
  for i = 1, #junk_keys do
    if name:find(junk_keys[i], 1, true) then return true end
  end
  local rate = nil
  pcall(function() rate = tonumber(item.Rate or item.rate or item.Quality or item.quality) end)
  if rate ~= nil and rate <= 1 then
    if name:find("meat") or name:find("leaf") or name:find("seed") then
      return true
    end
  end
  return false
end

local function loot_equip(npc)
  local dropped = 0
  pcall(function()
    local eq = npc.Equip
    if eq == nil then return end
    for i = 0, 20 do
      local it = nil
      pcall(function() if eq.GetEquip then it = eq:GetEquip(i) end end)
      if it ~= nil then
        if NusaCtr_AutoLoot_Filter == "no_junk" and is_junk_item(it) then
 -- skip junk
        else
          pcall(function()
            if eq.Unequip then eq:Unequip(i) end
          end)
          if drop_item_near(it, npc) then dropped = dropped + 1 end
        end
      end
    end
    for i = 101, 106 do
      local it = nil
      pcall(function() if eq.GetEquip then it = eq:GetEquip(i) end end)
      if it ~= nil then
        if NusaCtr_AutoLoot_Filter == "no_junk" and is_junk_item(it) then
 -- skip
        else
          pcall(function()
            if eq.Unequip then eq:Unequip(i) end
          end)
          if drop_item_near(it, npc) then dropped = dropped + 1 end
        end
      end
    end
  end)
  return dropped
end

local function loot_bag(npc)
  local dropped = 0
  local filter = NusaCtr_AutoLoot_Filter or "all"

  if filter == "all" then
    local used_all = false
    pcall(function()
      if npc.DropAllItems then
        npc:DropAllItems()
        dropped = dropped + 1
        used_all = true
      end
    end)
    if used_all then return dropped end
  end

  pcall(function()
    if npc.Bag and npc.Bag.GetItems then
      local items = npc.Bag:GetItems()
      if items then
        for _, it in pairs(items) do
          if filter == "no_junk" and is_junk_item(it) then
 -- skip
          else
            if drop_item_near(it, npc) then dropped = dropped + 1 end
          end
        end
      end
    end
  end)
  pcall(function()
    local bag = npc.m_Bag or npc.bag
    if bag and bag.Count then
      for i = 0, bag.Count - 1 do
        local it = nil
        pcall(function() it = bag[i] end)
        if it then
          if filter == "no_junk" and is_junk_item(it) then
 -- skip
          else
            if drop_item_near(it, npc) then dropped = dropped + 1 end
          end
        end
      end
    end
  end)
  return dropped
end

local function destroy_corpse(npc)
  local ok = false
  pcall(function() if npc.Destroy then npc:Destroy(); ok = true end end)
  pcall(function() if npc.RemoveSelf then npc:RemoveSelf(); ok = true end end)
  pcall(function()
    if Map and Map.Things and Map.Things.RemoveThing then
      Map.Things:RemoveThing(npc)
      ok = true
    end
  end)
  return ok
end

---------------------------------------------------------------- core
function NusaCtr_AutoLoot_RunOnce()
  local looted, deleted = 0, 0
  local radius = tonumber(NusaCtr_AutoLoot_Radius) or 0
  local filter = NusaCtr_AutoLoot_Filter or "all"
  local anchors = nil
  if radius > 0 then
    anchors = collect_player_anchors()
  end

  iter_npcs(function(npc)
    if is_player(npc) then return false end
    if not is_dead(npc) then return false end
    if (not NusaCtr_AutoLoot_IncludeAnimals) and is_animal(npc) then return false end
    if not within_radius(npc, anchors, radius) then return false end

    local d = 0
    if filter == "all" or filter == "equip" or filter == "no_junk" then
      d = d + loot_equip(npc)
    end
    if filter == "all" or filter == "bag" or filter == "no_junk" then
      d = d + loot_bag(npc)
    end
    if d > 0 then looted = looted + 1 end

    if NusaCtr_AutoLoot_DeleteAfter then
      if destroy_corpse(npc) then deleted = deleted + 1 end
    end
    return true
  end)
  return looted, deleted
end

function NusaCtr_AutoLoot_Tick()
  if not NusaCtr_AutoLoot_Enabled then return end
  pcall(NusaCtr_AutoLoot_RunOnce)
end

function NusaCtr_AutoLoot_OnRender()
  if not NusaCtr_AutoLoot_Enabled then return end
  _tick = _tick + 1
  if _tick < 120 then return end
  _tick = 0
  pcall(NusaCtr_AutoLoot_Tick)
end

function NusaCtr_AutoLoot_Toggle()
  NusaCtr_AutoLoot_Enabled = not NusaCtr_AutoLoot_Enabled
  return NusaCtr_AutoLoot_Enabled
end

function NusaCtr_AutoLoot_CycleRadius()
  local cur = tonumber(NusaCtr_AutoLoot_Radius) or 0
  local idx = 1
  for i = 1, #RADIUS_STEPS do
    if RADIUS_STEPS[i] == cur then idx = i; break end
  end
  idx = idx + 1
  if idx > #RADIUS_STEPS then idx = 1 end
  NusaCtr_AutoLoot_Radius = RADIUS_STEPS[idx]
  return NusaCtr_AutoLoot_Radius
end

function NusaCtr_AutoLoot_CycleFilter()
  local cur = NusaCtr_AutoLoot_Filter or "all"
  local idx = 1
  for i = 1, #FILTER_STEPS do
    if FILTER_STEPS[i] == cur then idx = i; break end
  end
  idx = idx + 1
  if idx > #FILTER_STEPS then idx = 1 end
  NusaCtr_AutoLoot_Filter = FILTER_STEPS[idx]
  return NusaCtr_AutoLoot_Filter
end

function NusaCtr_AutoLoot_RadiusText()
  local r = tonumber(NusaCtr_AutoLoot_Radius) or 0
  if r <= 0 then return "Unlimited" end
  return tostring(r) .. " tiles"
end

function NusaCtr_AutoLoot_FilterText()
  local f = NusaCtr_AutoLoot_Filter or "all"
  if f == "equip" then return "Equipment only" end
  if f == "bag" then return "Bag only" end
  if f == "no_junk" then return "Skip junk" end
  return "All items"
end

function NusaCtr_AutoLoot_ResetRadius()
  NusaCtr_AutoLoot_Radius = 0
  return NusaCtr_AutoLoot_Radius
end

function NusaCtr_AutoLoot_StatusText()
  if not NusaCtr_AutoLoot_Enabled then
    return "OFF"
  end
  local parts = { "ON" }
  parts[#parts + 1] = NusaCtr_AutoLoot_DeleteAfter and "Delete ON" or "Delete OFF"
  parts[#parts + 1] = NusaCtr_AutoLoot_IncludeAnimals and "Animals ON" or "Animals OFF"
  parts[#parts + 1] = "Radius " .. NusaCtr_AutoLoot_RadiusText()
  parts[#parts + 1] = NusaCtr_AutoLoot_FilterText()
  return table.concat(parts, (NusaCtr_T and NusaCtr_T(" | ") or " | "))
end

function NusaCtr_AutoLoot_GetSaveData()
  return {
    Enabled = NusaCtr_AutoLoot_Enabled == true,
    DeleteAfter = NusaCtr_AutoLoot_DeleteAfter ~= false,
    IncludeAnimals = NusaCtr_AutoLoot_IncludeAnimals == true,
    Radius = tonumber(NusaCtr_AutoLoot_Radius) or 0,
    Filter = tostring(NusaCtr_AutoLoot_Filter or "all"),
  }
end

function NusaCtr_AutoLoot_ApplySaveData(data)
  data = data or {}
  NusaCtr_AutoLoot_Enabled = data.Enabled == true
  NusaCtr_AutoLoot_DeleteAfter = data.DeleteAfter ~= false
  NusaCtr_AutoLoot_IncludeAnimals = data.IncludeAnimals == true
  NusaCtr_AutoLoot_Radius = tonumber(data.Radius) or 0
  local f = tostring(data.Filter or "all")
  local ok = false
  for i = 1, #FILTER_STEPS do
    if FILTER_STEPS[i] == f then ok = true; break end
  end
  NusaCtr_AutoLoot_Filter = ok and f or "all"
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

function NusaCtr_AutoLoot_Refresh()
  if not View then return end
  Text(Child(View, "title"), (NusaCtr_T and NusaCtr_T("Auto Loot") or "Auto Loot"))
  Text(Child(View, "subtitle"), (NusaCtr_T and NusaCtr_T("Corpses → loot → delete") or "Corpses → loot → delete"))
  Text(Child(View, "brand"), "NusaCtr")
  Text(Child(View, "infoTitle"), (NusaCtr_T and NusaCtr_T("Auto Loot") or "Auto Loot"))
  Text(Child(View, "infoStatus"), NusaCtr_AutoLoot_StatusText())
  Text(Child(View, "sectionTitle"), (NusaCtr_T and NusaCtr_T("Actions") or "Actions"))
  Text(Child(View, "description"),
    (NusaCtr_T and NusaCtr_T("Loot non-player corpses. Radius uses your living disciples.\nSettings are saved with the game.")) or "Loot non-player corpses. Radius uses your living disciples.\nSettings are saved with the game.")
  Text(Child(View, "statusText"),
    ((NusaCtr_T and NusaCtr_T("Delete: ")) or "Delete: ") .. (NusaCtr_AutoLoot_DeleteAfter and "ON" or "OFF")
    .. "  |  Animals: " .. (NusaCtr_AutoLoot_IncludeAnimals and "ON" or "OFF")
    .. "  |  Radius: " .. NusaCtr_AutoLoot_RadiusText()
    .. "  |  Filter: " .. NusaCtr_AutoLoot_FilterText()
  )
  Text(Child(View, "btnBack"), (NusaCtr_T and NusaCtr_T("Back") or "Back"))
  Text(Child(View, "btnClose"), "X")

  local actions = {
    {
      "Toggle Auto Loot",
      function()
        local on = NusaCtr_AutoLoot_Toggle()
        Msg(on and "Auto Loot: ON" or "Auto Loot: OFF")
        NusaCtr_AutoLoot_Refresh()
      end,
    },
    {
      "Toggle delete corpse",
      function()
        NusaCtr_AutoLoot_DeleteAfter = not NusaCtr_AutoLoot_DeleteAfter
        Msg(NusaCtr_AutoLoot_DeleteAfter and "Delete after loot: ON" or "Delete after loot: OFF")
        NusaCtr_AutoLoot_Refresh()
      end,
    },
    {
      "Toggle animals",
      function()
        NusaCtr_AutoLoot_IncludeAnimals = not NusaCtr_AutoLoot_IncludeAnimals
        Msg(NusaCtr_AutoLoot_IncludeAnimals and "Include animals: ON" or "Include animals: OFF")
        NusaCtr_AutoLoot_Refresh()
      end,
    },
    {
      "Radius: " .. NusaCtr_AutoLoot_RadiusText(),
      function()
        local r = NusaCtr_AutoLoot_CycleRadius()
        Msg("Radius: " .. NusaCtr_AutoLoot_RadiusText()
          .. (r <= 0 and " (whole map)" or " from your disciples"))
        NusaCtr_AutoLoot_Refresh()
      end,
    },
    {
      "Filter: " .. NusaCtr_AutoLoot_FilterText(),
      function()
        NusaCtr_AutoLoot_CycleFilter()
        Msg("Filter: " .. NusaCtr_AutoLoot_FilterText())
        NusaCtr_AutoLoot_Refresh()
      end,
    },
    {
      "Loot once now",
      function()
        local a, b = NusaCtr_AutoLoot_RunOnce()
        Msg("Done.\nLooted: " .. tostring(a) .. "\nDeleted: " .. tostring(b)
          .. "\nRadius: " .. NusaCtr_AutoLoot_RadiusText()
          .. "\nFilter: " .. NusaCtr_AutoLoot_FilterText())
        NusaCtr_AutoLoot_Refresh()
      end,
    },
    {
      "Reset radius",
      function()
        NusaCtr_AutoLoot_ResetRadius()
        Msg("Radius reset to Unlimited (whole map)")
        NusaCtr_AutoLoot_Refresh()
      end,
    },
  }

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

function NusaCtr_CloseAutoLoot()
  if View then
    pcall(function() View:RemoveFromParent() end)
    pcall(function() View:Dispose() end)
    View = nil
  end
end

function NusaCtr_OpenAutoLoot()
  NusaCtr_CloseAutoLoot()
  local pkg, root = Pkg(), Root()
  if not pkg or not root then Msg("UI missing"); return false end
  local view = nil
  pcall(function() view = pkg.CreateObject(PKG, WIN) end)
  if not view then Msg("Failed to open Auto Loot window"); return false end
  View = view
  pcall(function()
    root:AddChild(view)
    view.x = (root.width - view.width) / 2
    view.y = (root.height - view.height) / 2
  end)
  local function go_back()
    NusaCtr_CloseAutoLoot()
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
  NusaCtr_AutoLoot_Refresh()
  return true
end

_G.NusaCtr_OpenAutoLoot = NusaCtr_OpenAutoLoot
_G.NusaCtr_CloseAutoLoot = NusaCtr_CloseAutoLoot
_G.NusaCtr_AutoLoot_RunOnce = NusaCtr_AutoLoot_RunOnce
_G.NusaCtr_AutoLoot_Toggle = NusaCtr_AutoLoot_Toggle
_G.NusaCtr_AutoLoot_OnRender = NusaCtr_AutoLoot_OnRender
_G.NusaCtr_AutoLoot_StatusText = NusaCtr_AutoLoot_StatusText
_G.NusaCtr_AutoLoot_GetSaveData = NusaCtr_AutoLoot_GetSaveData
_G.NusaCtr_AutoLoot_ApplySaveData = NusaCtr_AutoLoot_ApplySaveData
_G.NusaCtr_AutoLoot_CycleRadius = NusaCtr_AutoLoot_CycleRadius
_G.NusaCtr_AutoLoot_CycleFilter = NusaCtr_AutoLoot_CycleFilter
_G.NusaCtr_AutoLoot_ResetRadius = NusaCtr_AutoLoot_ResetRadius

print("[NusaCtr] Auto Loot loaded (radius + filter + save)")
