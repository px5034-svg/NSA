-- ============================================================
-- NusaCtr Breakthrough Menu
-- Instant (selected NPC) + Auto / batch breakthrough
-- NusaCtr Breakthrough Menu
-- UI: NusaWorldToolsWindow
-- ============================================================

local PKG  = "NusaCtr"
local PATH = "UI/NusaCtr"
local WIN  = "NusaWorldToolsWindow"

local View = nil
local _tick = 0
local _lastReady = 0
local _lastDone = 0

NusaCtr_AutoBreakthrough_Enabled = NusaCtr_AutoBreakthrough_Enabled or false
if NusaCtr_AutoBreakthrough_RequireTouch == nil then
  NusaCtr_AutoBreakthrough_RequireTouch = true
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
local function real_npc(npc)
  if npc == nil then return nil end
  local candidates = { npc }
  local function add(v)
    if v ~= nil then candidates[#candidates + 1] = v end
  end
  pcall(function() add(npc.npcObj) end)
  pcall(function() add(npc.NpcObj) end)
  pcall(function() add(npc.Npc) end)
  pcall(function() add(npc.npc) end)
  pcall(function() add(npc.thing) end)
  pcall(function() add(npc.bind) end)
  for _, c in ipairs(candidates) do
    local ok, pm = pcall(function() return c.PropertyMgr end)
    if ok and pm ~= nil then return c end
  end
  return candidates[1]
end

local function get_practice(npc)
  local real = real_npc(npc) or npc
  local practice = nil
  pcall(function() practice = real.PropertyMgr.Practice end)
  return practice, real
end

local function is_player_npc(npc)
  if npc == nil then return false end
  local ok = false
  pcall(function()
    if npc.IsPlayerThing == true then ok = true end
    if CS and CS.XiaWorld and CS.XiaWorld.Fight
      and npc.Camp == CS.XiaWorld.Fight.g_emFightCamp.Player then
      ok = true
    end
  end)
  return ok
end

local function is_alive(npc)
  local dead = false
  pcall(function() if npc.IsDead == true then dead = true end end)
  return not dead
end

local function iter_player_npcs(fn)
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
    if not is_player_npc(npc) then return end
    if not is_alive(npc) then return end
    local can = true
    pcall(function() if npc.CanDoAction == false then can = false end end)
    if not can then return end
    pcall(function() fn(npc) end)
    n = n + 1
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

local function npc_name(npc)
  local nm = "?"
  pcall(function() nm = tostring(npc.Name or npc.name or "?") end)
  return nm
end

---------------------------------------------------------------- core break
function NusaCtr_BreakthroughNow(npc)
  if npc == nil then return false, "Please select an NPC first" end
  local practice, real = get_practice(npc)
  if practice == nil then
    return false, "This NPC has no cultivation practice system"
  end
  local neck = nil
  pcall(function() neck = practice.CurNeck end)
  if neck == nil then return false, "No next bottleneck to break through" end
  local kind = nil
  pcall(function() kind = neck.Kind end)
  if kind ~= nil and CS and CS.XiaWorld and CS.XiaWorld.g_emGongBottleNeckType then
    if kind == CS.XiaWorld.g_emGongBottleNeckType.Die then
      return false, "Death bottleneck cannot be forced"
    end
  end
  local beforeStage, beforeTouch, beforeGod = nil, nil, nil
  pcall(function() beforeStage = practice.LogicStage end)
  pcall(function() beforeTouch = practice.TouchNeck == true end)
  pcall(function() beforeGod = practice.GodCount end)
  local result = false
  local okBreak, breakErr = pcall(function()
    result = practice:BrokenNeck(false) == true
  end)
  if not okBreak then return false, tostring(breakErr) end
  if not result then return false, "Game rejected breakthrough" end
  local afterStage, afterTouch, afterGod = nil, nil, nil
  pcall(function() afterStage = practice.LogicStage end)
  pcall(function() afterTouch = practice.TouchNeck == true end)
  pcall(function() afterGod = practice.GodCount end)
  if afterStage ~= beforeStage or afterTouch ~= beforeTouch or afterGod ~= beforeGod then
    return true, "Breakthrough successful"
  end
  return false, "Game reported success but stage did not change"
end

function NusaCtr_AutoBreakthrough_IsReady(npc)
  local practice = select(1, get_practice(npc))
  if practice == nil then return false, "no practice" end
  local neck = nil
  pcall(function() neck = practice.CurNeck end)
  if neck == nil then return false, "no neck" end
  local kind = nil
  pcall(function() kind = neck.Kind end)
  if kind ~= nil and CS and CS.XiaWorld and CS.XiaWorld.g_emGongBottleNeckType then
    if kind == CS.XiaWorld.g_emGongBottleNeckType.Die then
      return false, "death bottleneck"
    end
  end
  if NusaCtr_AutoBreakthrough_RequireTouch then
    local touch = false
    pcall(function() touch = practice.TouchNeck == true end)
    if not touch then return false, "not at bottleneck" end
  end
  return true, "ready"
end

local function try_break_one(npc)
  local ok, detail = NusaCtr_BreakthroughNow(npc)
  return ok == true, detail
end

function NusaCtr_AutoBreakthrough_CountReady()
  local n = 0
  iter_player_npcs(function(npc)
    if NusaCtr_AutoBreakthrough_IsReady(npc) then n = n + 1 end
  end)
  _lastReady = n
  return n
end

function NusaCtr_AutoBreakthrough_DoAll()
  local success, fail, names = 0, 0, {}
  iter_player_npcs(function(npc)
    if not NusaCtr_AutoBreakthrough_IsReady(npc) then return end
    local ok = try_break_one(npc)
    if ok then
      success = success + 1
      table.insert(names, npc_name(npc))
    else
      fail = fail + 1
    end
  end)
  _lastDone = success
  local list = ""
  if #names > 0 then
    list = "\n" .. table.concat(names, ", ")
    if #list > 120 then list = string.sub(list, 1, 117) .. "..." end
  end
  Msg("Breakthrough done.\nSuccess: " .. success .. " | Fail: " .. fail .. list)
  return success, fail
end

function NusaCtr_AutoBreakthrough_Tick()
  if not NusaCtr_AutoBreakthrough_Enabled then return end
  local success = 0
  iter_player_npcs(function(npc)
    if not NusaCtr_AutoBreakthrough_IsReady(npc) then return end
    if try_break_one(npc) then success = success + 1 end
  end)
  if success > 0 then
    _lastDone = success
    Msg("Auto Breakthrough: " .. success .. " disciple(s) broke through")
  end
  NusaCtr_AutoBreakthrough_CountReady()
end

function NusaCtr_AutoBreakthrough_OnRender()
  if not NusaCtr_AutoBreakthrough_Enabled then return end
  _tick = _tick + 1
  if _tick < 90 then return end
  _tick = 0
  pcall(NusaCtr_AutoBreakthrough_Tick)
end

function NusaCtr_AutoBreakthrough_Toggle()
  NusaCtr_AutoBreakthrough_Enabled = not NusaCtr_AutoBreakthrough_Enabled
  return NusaCtr_AutoBreakthrough_Enabled
end

function NusaCtr_AutoBreakthrough_ToggleRequireTouch()
  NusaCtr_AutoBreakthrough_RequireTouch = not NusaCtr_AutoBreakthrough_RequireTouch
  return NusaCtr_AutoBreakthrough_RequireTouch
end

function NusaCtr_AutoBreakthrough_StatusText()
  local ready = NusaCtr_AutoBreakthrough_CountReady()
  if not NusaCtr_AutoBreakthrough_Enabled then
    return "Auto: OFF | Ready: " .. tostring(ready)
  end
  local mode = NusaCtr_AutoBreakthrough_RequireTouch and "Touch" or "Force"
  return "Auto: ON (" .. mode .. ") | Ready: " .. tostring(ready)
end

function NusaCtr_AutoBreakthrough_GetSaveData()
  return {
    Enabled = NusaCtr_AutoBreakthrough_Enabled == true,
    RequireTouch = NusaCtr_AutoBreakthrough_RequireTouch ~= false,
  }
end

function NusaCtr_AutoBreakthrough_ApplySaveData(data)
  if type(data) ~= "table" then return end
  if data.Enabled ~= nil then NusaCtr_AutoBreakthrough_Enabled = data.Enabled == true end
  if data.RequireTouch ~= nil then NusaCtr_AutoBreakthrough_RequireTouch = data.RequireTouch ~= false end
end

---------------------------------------------------------------- UI
local function status_line()
  return NusaCtr_AutoBreakthrough_StatusText()
end

function NusaCtr_BreakthroughMenu_Refresh()
  if not View then return end
  local st = status_line()
  Text(Child(View, "title"), (NusaCtr_T and NusaCtr_T("Breakthrough") or "Breakthrough"))
  Text(Child(View, "subtitle"), (NusaCtr_T and NusaCtr_T("Instant · Auto · Batch") or "Instant · Auto · Batch"))
  Text(Child(View, "brand"), "NusaCtr")
  Text(Child(View, "infoTitle"), (NusaCtr_T and NusaCtr_T("Breakthrough") or "Breakthrough"))
  Text(Child(View, "infoStatus"), st)
  Text(Child(View, "sectionTitle"), (NusaCtr_T and NusaCtr_T("Actions") or "Actions"))
  Text(Child(View, "description"),
    "Selected NPC breakthrough, or auto/batch all disciples at bottleneck.\n"
    .. st)
  Text(Child(View, "statusText"), ((NusaCtr_T and NusaCtr_T("NusaCtr · Breakthrough | ")) or "NusaCtr · Breakthrough | ") .. st)
  Text(Child(View, "btnBack"), (NusaCtr_T and NusaCtr_T("Back") or "Back"))
  Text(Child(View, "btnClose"), "X")

  local auto_lab = NusaCtr_AutoBreakthrough_Enabled and "Auto: ON (toggle)" or "Auto: OFF (toggle)"
  local mode_lab = NusaCtr_AutoBreakthrough_RequireTouch
    and "Mode: Touch only" or "Mode: Force"

  local actions = {
    { "Selected NPC breakthrough", function()
      local target = _G.NusaCtr_LastTarget
      if not target then
        Msg("Please select an NPC first")
        return
      end
      local ok, detail = NusaCtr_BreakthroughNow(target)
      if ok then Msg("Breakthrough completed")
      else Msg("Breakthrough failed\n" .. tostring(detail)) end
    end },
    { "Break all ready", function() NusaCtr_AutoBreakthrough_DoAll() end },
    { auto_lab, function()
      local on = NusaCtr_AutoBreakthrough_Toggle()
      Msg(on and "Auto Breakthrough: ON" or "Auto Breakthrough: OFF")
    end },
    { mode_lab, function()
      local touch = NusaCtr_AutoBreakthrough_ToggleRequireTouch()
      Msg(touch and "Mode: only at bottleneck (Touch)"
        or "Mode: force if CurNeck is not death")
    end },
    { "Refresh status", function()
      Msg(status_line())
    end },
  }

  for i = 1, 8 do
    local btn = Child(View, "feature" .. i)
    local act = actions[i]
    if btn and act and act[1] then
      Visible(btn, true)
      Text(btn, (NusaCtr_T and NusaCtr_T(act[1])) or act[1])
      pcall(function()
        if btn.onClick and btn.onClick.Clear then btn.onClick:Clear() end
        btn.onClick:Add(function()
          if act[2] then pcall(act[2]) end
          NusaCtr_BreakthroughMenu_Refresh()
        end)
      end)
    elseif btn then
      Text(btn, "")
      Visible(btn, false)
    end
  end
end

function NusaCtr_CloseBreakthroughMenu()
  if View then
    pcall(function() View:RemoveFromParent() end)
    pcall(function() View:Dispose() end)
    View = nil
  end
end

function NusaCtr_OpenBreakthroughMenu()
  NusaCtr_CloseBreakthroughMenu()
  local pkg, root = Pkg(), Root()
  if not pkg or not root then Msg("UI missing"); return false end
  local view = nil
  pcall(function() view = pkg.CreateObject(PKG, WIN) end)
  if not view then Msg("Failed to open Breakthrough menu"); return false end
  View = view
  pcall(function()
    root:AddChild(view)
    view.x = (root.width - view.width) / 2
    view.y = (root.height - view.height) / 2
  end)
  local function go_back()
    NusaCtr_CloseBreakthroughMenu()
    if NusaCtr_OpenMain then
      pcall(function() NusaCtr_OpenMain(_G.NusaCtr_LastTarget) end)
    end
  end
  for _, name in ipairs({"btnClose", "btnBack"}) do
    local b = Child(view, name)
    if b then
      pcall(function()
        if b.onClick and b.onClick.Clear then b.onClick:Clear() end
        b.onClick:Add(go_back)
      end)
    end
  end
  NusaCtr_BreakthroughMenu_Refresh()
  return true
end

_G.NusaCtr_OpenBreakthroughMenu = NusaCtr_OpenBreakthroughMenu
_G.NusaCtr_CloseBreakthroughMenu = NusaCtr_CloseBreakthroughMenu
_G.NusaCtr_BreakthroughNow = NusaCtr_BreakthroughNow
_G.NusaCtr_AutoBreakthrough_OnRender = NusaCtr_AutoBreakthrough_OnRender
_G.NusaCtr_AutoBreakthrough_Toggle = NusaCtr_AutoBreakthrough_Toggle
_G.NusaCtr_AutoBreakthrough_DoAll = NusaCtr_AutoBreakthrough_DoAll
_G.NusaCtr_AutoBreakthrough_GetSaveData = NusaCtr_AutoBreakthrough_GetSaveData
_G.NusaCtr_AutoBreakthrough_ApplySaveData = NusaCtr_AutoBreakthrough_ApplySaveData

print("[NusaCtr] Breakthrough Menu (instant + auto) loaded")
