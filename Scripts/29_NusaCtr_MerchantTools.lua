-- ============================================================
-- NusaCtr Merchant Tools
-- NusaCtr Merchant Tools
-- API: WalkTrader / WalkTraderData / TradeMgr (ACS)
-- UI: NusaWorldToolsWindow
-- ============================================================

local PKG  = "NusaCtr"
local PATH = "UI/NusaCtr"
local WIN  = "NusaWorldToolsWindow"

local View = nil
local Page = 1

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

---------------------------------------------------------------- Trade API
local function trade_mgr()
  local tm = nil
  pcall(function() tm = CS.XiaWorld.TradeMgr.Instance end)
  return tm
end

local function walk_data()
  local d = nil
  pcall(function() d = CS.XiaWorld.WalkTraderData end)
  return d
end

local function day_second()
  local sj = nil
  pcall(function()
    if CS.WorldLuaHelper then
      local h = CS.WorldLuaHelper()
      sj = h.DaySecond
    end
  end)
  if sj == nil then
    pcall(function()
      if WorldLuaHelper then sj = WorldLuaHelper.DaySecond end
    end)
  end
  if sj == nil then
    pcall(function()
      if World and World.DayCount then sj = tostring(World.DayCount) end
    end)
  end
  return tostring(sj or "0")
end

function NusaCtr_Merchant_SetSchedule(min_days, max_days, first_day)
  min_days = tonumber(min_days) or 1
  max_days = tonumber(max_days) or min_days
  if max_days < min_days then max_days = min_days end
  first_day = tonumber(first_day) or 20
  local d = walk_data()
  if d == nil then
    Msg("WalkTraderData missing")
    return false
  end
  local ok = pcall(function()
    d.NextComeDay_Min = min_days
    d.NextComeDay_Max = max_days
    d.FirstComeDay = first_day
    if d.WalkTradeStaySec == 0 then d.WalkTradeStaySec = 601 end
  end)
  if ok then
    Msg("Merchant schedule: " .. tostring(min_days) .. "~" .. tostring(max_days) .. " day(s)")
  else
    Msg("Failed to set schedule")
  end
  return ok
end

function NusaCtr_Merchant_ShowRange()
  local d = walk_data()
  if d == nil then
    Msg("No merchant data")
    return false
  end
  local a, b = "?", "?"
  pcall(function() a = tostring(d.NextComeDay_Min) end)
  pcall(function() b = tostring(d.NextComeDay_Max) end)
  Msg("Merchant arrives in: " .. a .. "~" .. b .. " day(s)")
  return true
end

function NusaCtr_Merchant_MoreItems()
  local ok = pcall(function()
    local tm = trade_mgr()
    tm.default_walkdef.AllRandomCount = 10000
  end)
  Msg(ok and "Merchant stock expanded" or "Failed to change stock")
  return ok
end

function NusaCtr_Merchant_ResetGoods()
  local ok = pcall(function()
    local tm = trade_mgr()
    tm.default_walkdef.AllRandomCount = 6
  end)
  Msg(ok and "Merchant stock reset" or "Failed to reset stock")
  return ok
end

function NusaCtr_Merchant_Call(instant)
  local ok, err = pcall(function()
    local tm = trade_mgr()
    if tm == nil or tm.WalkTrader == nil then error("WalkTrader nil") end
    if instant then
      pcall(function() tm.WalkTrader.KillTrader = 0 end)
    end
    local sj = day_second()
    tm.WalkTrader:AddTraderNpc(sj)
  end)
  if ok then
    Msg(instant and "Merchant called now" or "Merchant scheduled (Call2)")
  else
    Msg("Failed to call merchant\n" .. tostring(err))
  end
  return ok
end

function NusaCtr_Merchant_FindActiveMerchant()
  local found = nil
  pcall(function()
    if CS and CS.WorldLuaHelper then
      found = CS.WorldLuaHelper():GetSelectThing()
    end
  end)
  pcall(function()
    if found == nil and WorldLua and WorldLua.GetSelectThing then
      found = WorldLua:GetSelectThing()
    end
  end)
  pcall(function()
    if found ~= nil then return end
    local tm = CS.XiaWorld.TradeMgr and CS.XiaWorld.TradeMgr.Instance
    if tm and tm.WalkTrader then
      local wt = tm.WalkTrader
      pcall(function() found = wt.TraderNpc end)
      pcall(function() if found == nil then found = wt.Npc end end)
      pcall(function() if found == nil then found = wt.m_npc end end)
    end
  end)
  return found
end

function NusaCtr_Merchant_Cancel()
  local ok_any = false

  pcall(function()
    local tm = CS.XiaWorld.TradeMgr and CS.XiaWorld.TradeMgr.Instance
    if tm == nil or tm.WalkTrader == nil then return end
    local wt = tm.WalkTrader
    pcall(function() wt.KillTrader = 1 end)
    pcall(function() if wt.SendTraderHome then wt:SendTraderHome() end end)
    pcall(function() if wt.RemoveTrader then wt:RemoveTrader() end end)
    ok_any = true
  end)

  local npc = nil
  pcall(function() npc = NusaCtr_Merchant_FindActiveMerchant() end)
  if npc ~= nil then
    pcall(function()
      local mgr = CS.XiaWorld.ThingMgr and CS.XiaWorld.ThingMgr.Instance
      if mgr and mgr.RemoveThing then
        mgr:RemoveThing(npc, true, true)
        ok_any = true
      end
    end)
    pcall(function()
      if npc.Destroy then npc:Destroy(true); ok_any = true end
    end)
  end

  if ok_any then
    Msg("Merchant sent home / removed.")
  else
    Msg("No merchant found.\nSelect the merchant on the map first, then try again.")
  end
  return true
end

---------------------------------------------------------------- UI pages
local function page_actions()
  if Page == 1 then
    return {
      title = "Merchant (1/2)",
      description = "Call = arrive now. Schedule = visit frequency.",
      actions = {
        { "Call now", function() NusaCtr_Merchant_Call(true) end },
        { "Schedule tomorrow", function() NusaCtr_Merchant_SetSchedule(1, 1, 20) end },
        { "1–10 days", function() NusaCtr_Merchant_SetSchedule(1, 10, 20) end },
        { "More items", function() NusaCtr_Merchant_MoreItems() end },
        { "Show schedule", function() NusaCtr_Merchant_ShowRange() end },
        { "Send home", function() pcall(NusaCtr_Merchant_Cancel) end },
        { "◀ Prev page", function() Page = 2; NusaCtr_Merchant_Refresh() end },
        { "Next page ▶", function() Page = 2; NusaCtr_Merchant_Refresh() end },
      },
    }
  end
  return {
    title = "Merchant (2/2)",
    description = "Extra schedules and stock options.",
    actions = {
      { "10–20 days", function() NusaCtr_Merchant_SetSchedule(10, 20, 20) end },
      { "10–30 days", function() NusaCtr_Merchant_SetSchedule(10, 30, 20) end },
      { "Vanilla 10–40", function() NusaCtr_Merchant_SetSchedule(10, 40, 20) end },
      { "Reset stock", function() NusaCtr_Merchant_ResetGoods() end },
      { "Call2 (schedule)", function() NusaCtr_Merchant_Call(false) end },
      { "Show schedule", function() NusaCtr_Merchant_ShowRange() end },
      { "◀ Prev page", function() Page = 1; NusaCtr_Merchant_Refresh() end },
      { "Next page ▶", function() Page = 1; NusaCtr_Merchant_Refresh() end },
    },
  }
end

function NusaCtr_Merchant_Refresh()
  if not View then return end
  local data = page_actions()

  Text(Child(View, "title"), (NusaCtr_T and NusaCtr_T(data.title)) or data.title)
  Text(Child(View, "subtitle"), (NusaCtr_T and NusaCtr_T("Call & schedule walking merchant") or "Call & schedule walking merchant"))
  Text(Child(View, "brand"), "NusaCtr")
  Text(Child(View, "infoTitle"), (NusaCtr_T and NusaCtr_T("Merchant Tools") or "Merchant Tools"))
  Text(Child(View, "infoStatus"), (NusaCtr_T and NusaCtr_T("Call · Schedule · Stock · Send home") or "Call · Schedule · Stock · Send home"))
  Text(Child(View, "sectionTitle"), (NusaCtr_T and NusaCtr_T(data.title)) or data.title)
  Text(Child(View, "description"), (NusaCtr_T and NusaCtr_T(data.description)) or data.description)
  Text(Child(View, "statusText"), (NusaCtr_T and NusaCtr_T("NusaCtr · Merchant Tools") or "NusaCtr · Merchant Tools"))
  Text(Child(View, "btnBack"), (NusaCtr_T and NusaCtr_T("Back") or "Back"))
  Text(Child(View, "btnClose"), "X")

  for i = 1, 8 do
    local btn = Child(View, "feature" .. i)
    local act = data.actions[i]
    if btn and act and act[1] then
      Visible(btn, true)
      Text(btn, (NusaCtr_T and NusaCtr_T(act[1])) or act[1])
      pcall(function()
        if btn.onClick and btn.onClick.Clear then btn.onClick:Clear() end
        btn.onClick:Add(function()
          if act[2] then pcall(act[2]) end
          NusaCtr_Merchant_Refresh()
        end)
      end)
    elseif btn then
      Text(btn, "")
      Visible(btn, false)
    end
  end
end

function NusaCtr_CloseMerchantTools()
  if View then
    pcall(function() View:RemoveFromParent() end)
    pcall(function() View:Dispose() end)
    View = nil
  end
end

function NusaCtr_OpenMerchantTools()
  NusaCtr_CloseMerchantTools()
  Page = 1

  local pkg, root = Pkg(), Root()
  if not pkg or not root then
    Msg("UI missing")
    return false
  end

  local view = nil
  pcall(function() view = pkg.CreateObject(PKG, WIN) end)
  if not view then
    Msg("Failed to open Merchant Tools window")
    return false
  end

  View = view
  pcall(function()
    root:AddChild(view)
    view.x = (root.width - view.width) / 2
    view.y = (root.height - view.height) / 2
  end)

  local function go_back()
    NusaCtr_CloseMerchantTools()
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

  NusaCtr_Merchant_Refresh()
  return true
end

_G.NusaCtr_OpenMerchantTools = NusaCtr_OpenMerchantTools
_G.NusaCtr_CloseMerchantTools = NusaCtr_CloseMerchantTools
_G.NusaCtr_Merchant_Call = NusaCtr_Merchant_Call
_G.NusaCtr_Merchant_Cancel = NusaCtr_Merchant_Cancel
_G.NusaCtr_Merchant_SetSchedule = NusaCtr_Merchant_SetSchedule
_G.NusaCtr_Merchant_ShowRange = NusaCtr_Merchant_ShowRange
_G.NusaCtr_Merchant_MoreItems = NusaCtr_Merchant_MoreItems
_G.NusaCtr_Merchant_ResetGoods = NusaCtr_Merchant_ResetGoods

print("[NusaCtr] Merchant Tools loaded")
