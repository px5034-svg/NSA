-- ============================================================
-- NusaCtr Jianghu Favor (mass)
-- NusaCtr Jianghu Favor
-- Max favor for ALL known Jianghu NPCs (NOT single Open Heart picker)
-- Uses NusaCtr_OpenHeartBySeed when available
-- UI: NusaWorldToolsWindow
-- ============================================================

local PKG  = "NusaCtr"
local PATH = "UI/NusaCtr"
local WIN  = "NusaWorldToolsWindow"

local View = nil

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

local function jh_mgr()
  local m = nil
  pcall(function() m = JianghuMgr end)
  if m == nil then pcall(function() m = CS.XiaWorld.JianghuMgr.Instance end) end
  return m
end

local function collect_jh_seeds()
  local seeds, seen = {}, {}
  local function add_key(k)
    if k == nil then return end
    local s = tonumber(k) or k
    local key = tostring(s)
    if seen[key] then return end
    seen[key] = true
    seeds[#seeds + 1] = s
  end
  local function add_from(map)
    if map == nil then return end
    pcall(function()
      for k, v in pairs(map) do
        if type(k) == "number" or tonumber(k) then
          add_key(k)
        elseif v ~= nil then
          local id = nil
          pcall(function() id = v.Seed or v.seed or v.ID or v.Id end)
          if id ~= nil then add_key(id) else add_key(k) end
        end
      end
    end)
    local count = 0
    pcall(function() count = map.Count end)
    if count and count > 0 then
      for i = 0, count - 1 do
        local v = nil
        pcall(function() v = map[i] end)
        if v == nil then pcall(function() v = map:get_Item(i) end) end
        if v ~= nil then
          local id = nil
          pcall(function() id = v.Seed or v.seed or v.ID end)
          add_key(id or v)
        end
      end
    end
    pcall(function()
      if map.Keys then
        for _, k in pairs(map.Keys) do add_key(k) end
      end
    end)
  end

  local mgr = jh_mgr()
  local school = nil
  pcall(function() school = CS.XiaWorld.SchoolGlobleMgr.Instance end)
  add_from(mgr and mgr.KnowNpcData)
  add_from(school and school.JianghuNpcs)
  return seeds
end

function NusaCtr_MaxAllJianghuFavor()
  local mgr = jh_mgr()
  if mgr == nil then
    Msg("JianghuMgr not found")
    return false
  end
 -- ensure heart core is available
  if NusaCtr_OpenHeartBySeed == nil then
    pcall(require, "Scripts/07_NusaCtr_Jianghu_Core.lua")
  end

  local seeds = collect_jh_seeds()
  local ok_n, fail_n = 0, 0
  for _, seed in ipairs(seeds) do
    local ok = false
    pcall(function()
      if NusaCtr_OpenHeartBySeed then
        if NusaCtr_OpenHeartBySeed(seed, true) then ok = true end
      else
        mgr:AddKnowNpcData(seed)
        local data = mgr:GetKnowNpcData(seed)
        if data then
          pcall(function() data:UnlockHeart() end)
          local current = tonumber(data.favour) or 0
          local delta = 100 - current
          if delta > 0 then
            local added = false
            pcall(function()
              mgr:AddKnowNpcData(seed, CS.XiaWorld.g_emJHNpcDataType.None, delta, nil)
              added = true
            end)
            if not added then data.favour = 100 end
          end
          ok = true
        end
      end
    end)
    if ok then ok_n = ok_n + 1 else fail_n = fail_n + 1 end
  end

  Msg("Mass Jianghu favor done.\nOK: " .. tostring(ok_n)
    .. " | fail: " .. tostring(fail_n)
    .. " | seeds " .. tostring(#seeds))
  return ok_n > 0
end

---------------------------------------------------------------- UI
function NusaCtr_JianghuFavor_Refresh()
  if not View then return end
  Text(Child(View, "title"), (NusaCtr_T and NusaCtr_T("Jianghu Favor") or "Jianghu Favor"))
  Text(Child(View, "subtitle"), (NusaCtr_T and NusaCtr_T("Max favor for all known Jianghu NPCs") or "Max favor for all known Jianghu NPCs"))
  Text(Child(View, "brand"), "NusaCtr")
  Text(Child(View, "infoTitle"), (NusaCtr_T and NusaCtr_T("Jianghu Favor") or "Jianghu Favor"))
  Text(Child(View, "infoStatus"), (NusaCtr_T and NusaCtr_T("Mass Open Heart + Favor 100") or "Mass Open Heart + Favor 100"))
  Text(Child(View, "sectionTitle"), (NusaCtr_T and NusaCtr_T("Actions") or "Actions"))
  Text(Child(View, "description"),
    "Applies Open Heart + max favor to every known Jianghu NPC seed.\nDifferent from the single-NPC picker (Open Heart + Max Favor).")
  Text(Child(View, "statusText"), (NusaCtr_T and NusaCtr_T("NusaCtr · Jianghu Favor") or "NusaCtr · Jianghu Favor"))
  Text(Child(View, "btnBack"), (NusaCtr_T and NusaCtr_T("Back") or "Back"))
  Text(Child(View, "btnClose"), "X")

  local actions = {
    { "Max all Jianghu favor", function() NusaCtr_MaxAllJianghuFavor() end },
  }
  for i = 1, 8 do
    local btn = Child(View, "feature" .. i)
    local act = actions[i]
    if btn and act and act[1] then
      Visible(btn, true)
      Text(btn, (NusaCtr_T and NusaCtr_T(act[1])) or act[1])
      pcall(function()
        if btn.onClick and btn.onClick.Clear then btn.onClick:Clear() end
        btn.onClick:Add(function() if act[2] then pcall(act[2]) end end)
      end)
    elseif btn then
      Text(btn, "")
      Visible(btn, false)
    end
  end
end

function NusaCtr_CloseJianghuFavor()
  if View then
    pcall(function() View:RemoveFromParent() end)
    pcall(function() View:Dispose() end)
    View = nil
  end
end

function NusaCtr_OpenJianghuFavor()
  NusaCtr_CloseJianghuFavor()
  local pkg, root = Pkg(), Root()
  if not pkg or not root then Msg("UI missing"); return false end
  local view = nil
  pcall(function() view = pkg.CreateObject(PKG, WIN) end)
  if not view then Msg("Failed to open Jianghu Favor window"); return false end
  View = view
  pcall(function()
    root:AddChild(view)
    view.x = (root.width - view.width) / 2
    view.y = (root.height - view.height) / 2
  end)
  local function go_back()
    NusaCtr_CloseJianghuFavor()
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
  NusaCtr_JianghuFavor_Refresh()
  return true
end

_G.NusaCtr_OpenJianghuFavor = NusaCtr_OpenJianghuFavor
_G.NusaCtr_CloseJianghuFavor = NusaCtr_CloseJianghuFavor
_G.NusaCtr_MaxAllJianghuFavor = NusaCtr_MaxAllJianghuFavor

print("[NusaCtr] Jianghu Favor (mass) loaded")
