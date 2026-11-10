-- NusaCtr Boss Summon Window (standalone, no separate core)

local PKG  = "NusaCtr"
local PATH = "UI/NusaCtr"
local WIN  = "BossSummon"

local View = nil
local Page = 1
local PageSize = 3

local BossList = {
  {
    name = "Azure Dragon",
    bossId = "Boss_Long",
    desc = "Dragon-type boss\nTest boss summon combat",
  },
  {
    name = "Fire Phoenix",
    bossId = "Boss_Feng",
    desc = "Fire-type boss\nSummon via GameUlt.CallBoss",
  },
  {
    name = "Zhu Long",
    bossId = "Boss_Zhulong",
    desc = "High-tier test boss\nMay not spawn if ID differs",
  },
  {
    name = "Calamity Fei",
    kind = "godAnimal",
    bossId = "Fei",
    desc = "Summon divine beast Fei\nvia Map:AddGodAnimal",
  },
  {
    name = "Elite Enemy",
    kind = "elite",
    bossId = "EliteEnemy",
    desc = "Spawn elite enemy at map edge\nGeneral combat test",
  },
  {
    name = "Text Test",
    kind = "test",
    bossId = "TEST",
    desc = "Test button only\nShows message, no real boss",
  },
  {
    name = "Empty Slot 1",
    kind = "test",
    bossId = "EMPTY_1",
    desc = "Reserved for a new boss",
  },
  {
    name = "Empty Slot 2",
    kind = "test",
    bossId = "EMPTY_2",
    desc = "Reserved for a new boss",
  },
  {
    name = "Empty Slot 3",
    kind = "test",
    bossId = "EMPTY_3",
    desc = "Reserved for a new boss",
  },
}

local function Pkg()
  local p = UIPackage or (CS and CS.FairyGUI and CS.FairyGUI.UIPackage)
  if p then pcall(function() p.AddPackage(PATH) end) end
  return p
end

local function Root()
  return (GRoot and GRoot.inst)
    or (CS and CS.FairyGUI and CS.FairyGUI.GRoot and CS.FairyGUI.GRoot.inst)
end

local function Child(view, ...)
  if not view then return nil end
  for i = 1, select("#", ...) do
    local name = select(i, ...)
    local c = nil
    pcall(function() c = view:GetChild(name) end)
    if c ~= nil then return c end
  end
  return nil
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

local function Visible(obj, v)
  if obj then pcall(function() obj.visible = (v == true) end) end
end

local function Touchable(obj, flag)
  if not obj then return end
  pcall(function() obj.touchable = flag end)
  pcall(function() obj.enabled = flag end)
  pcall(function() obj.grayed = not flag end)
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

local function GetIcon(data)
  if data == nil then return "" end
  if data.icon and tostring(data.icon) ~= "" then return tostring(data.icon) end
  local icon = ""
  pcall(function()
    local mgr = NpcMgr or (CS and CS.XiaWorld and CS.XiaWorld.NpcMgr and CS.XiaWorld.NpcMgr.Instance)
    if mgr then
      local def = mgr:GetRaceDef(tostring(data.bossId or ""))
      if def and def.TexPath then icon = tostring(def.TexPath) end
    end
  end)
  return icon
end

local function SetIcon(loader, data)
  if not loader then return end
  local icon = GetIcon(data)
  pcall(function() loader.url = icon end)
  pcall(function() loader.icon = icon end)
  Visible(loader, icon ~= "")
end

local function CallBoss(data)
  if data == nil then return end
  local kind = data.kind or "boss"
  if kind == "test" then
    Msg("Test: " .. tostring(data.name))
    return
  end
  local ok = false
  if kind == "godAnimal" then
    if Map and Map.AddGodAnimal then
      ok = pcall(function() Map:AddGodAnimal(data.bossId, 0) end)
    end
    Msg(ok and ("Summoned: " .. data.name) or ("Failed: " .. data.name))
    return
  end
  if kind == "elite" then
    if NpcMgr and NpcMgr.CreateEliteEnemysAtSide then
      ok = pcall(function()
        NpcMgr:CreateEliteEnemysAtSide("", CS.XiaWorld.g_emThingDir.None, Map, 0)
      end)
    end
    Msg(ok and "Elite enemy spawned" or "Elite spawn failed")
    return
  end
  if not GameUlt or not GameUlt.CallBoss then
    Msg("GameUlt.CallBoss not found")
    return
  end
  ok = pcall(function()
    return GameUlt.CallBoss(data.bossId, nil, nil, false)
  end)
  Msg(ok and ("Summoned: " .. data.name) or ("Failed: " .. data.name))
end

local function Refresh()
  if not View then return end
  Text(Child(View, "title"), (NusaCtr_T and NusaCtr_T("Summon Boss") or "Summon Boss"))
  Text(Child(View, "subtitle"), (NusaCtr_T and NusaCtr_T("Select an enemy to summon onto the map") or "Select an enemy to summon onto the map"))
  Text(Child(View, "btnClose"), "X")
  Text(Child(View, "btnPrevPage", "btnPrev"), (NusaCtr_T and NusaCtr_T("◀ Prev") or "◀ Prev"))
  Text(Child(View, "btnNextpage", "btnNextPage", "btnNext"), (NusaCtr_T and NusaCtr_T("Next ▶") or "Next ▶"))

  local total = #BossList
  local maxPage = math.max(1, math.ceil(total / PageSize))
  if Page < 1 then Page = 1 end
  if Page > maxPage then Page = maxPage end
  Text(Child(View, "txtPage", "pageText"), tostring(Page) .. "/" .. tostring(maxPage))

  local slots = {
    {
      card = Child(View, "card1"),
      icon = Child(View, "card1_icon"),
      name = Child(View, "card1_name"),
      desc = Child(View, "card1_Desc", "card1_desc"),
      btn  = Child(View, "card_btn1", "card1_btn"),
    },
    {
      card = Child(View, "card2"),
      icon = Child(View, "card2_icon"),
      name = Child(View, "card2_name"),
      desc = Child(View, "card2_Desc", "card2_desc"),
      btn  = Child(View, "card_btn2", "card2_btn"),
    },
    {
      card = Child(View, "card3"),
      icon = Child(View, "card3_icon"),
      name = Child(View, "card3_name"),
      desc = Child(View, "card3_Desc", "card3_desc"),
      btn  = Child(View, "card_btn13", "card_btn3", "card3_btn"),
    },
  }

  for i = 1, PageSize do
    local index = (Page - 1) * PageSize + i
    local data = BossList[index]
    local slot = slots[i]
    if data then
      Visible(slot.card, true)
      SetIcon(slot.icon, data)
      Text(slot.name, data.name)
      Text(slot.desc, data.desc)
      Text(slot.btn, (NusaCtr_T and NusaCtr_T("Summon Boss") or "Summon Boss"))
      Touchable(slot.btn, true)
      if slot.btn then pcall(function() slot.btn.data = data end) end
    else
      Visible(slot.card, false)
      SetIcon(slot.icon, nil)
      Text(slot.name, "")
      Text(slot.desc, "")
      Text(slot.btn, "")
      Touchable(slot.btn, false)
      if slot.btn then pcall(function() slot.btn.data = nil end) end
    end
  end
end

function NusaCtr_CloseBossSummon()
  if View then
    pcall(function() View:RemoveFromParent() end)
    pcall(function() View:Dispose() end)
    View = nil
  end
end

function NusaCtr_OpenBossSummon()
  NusaCtr_CloseBossSummon()
  local pkg, root = Pkg(), Root()
  if not pkg or not root then Msg("UI missing"); return false end
  local view = nil
  pcall(function() view = pkg.CreateObject(PKG, WIN) end)
  if not view then Msg("Failed open BossSummon"); return false end
  View = view
  Page = 1
  pcall(function()
    root:AddChild(view)
    view.x = (root.width - view.width) / 2
    view.y = (root.height - view.height) / 2
  end)

  local function bindBtn(names, fn)
    local b = Child(view, unpack(names))
    if b then
      pcall(function()
        b.onClick:Clear()
        b.onClick:Add(fn)
      end)
    end
  end

  bindBtn({"card_btn1", "card1_btn"}, function()
    local b = Child(View, "card_btn1", "card1_btn")
    if b and b.data then CallBoss(b.data) end
  end)
  bindBtn({"card_btn2", "card2_btn"}, function()
    local b = Child(View, "card_btn2", "card2_btn")
    if b and b.data then CallBoss(b.data) end
  end)
  bindBtn({"card_btn13", "card_btn3", "card3_btn"}, function()
    local b = Child(View, "card_btn13", "card_btn3", "card3_btn")
    if b and b.data then CallBoss(b.data) end
  end)
  bindBtn({"btnPrevPage", "btnPrev"}, function()
    Page = Page - 1
    Refresh()
  end)
  bindBtn({"btnNextpage", "btnNextPage", "btnNext"}, function()
    Page = Page + 1
    Refresh()
  end)
  bindBtn({"btnClose"}, function()
    NusaCtr_CloseBossSummon()
    if NusaCtr_OpenMain then
      pcall(function() NusaCtr_OpenMain(_G.NusaCtr_LastTarget) end)
    end
  end)

  Refresh()
  return true
end

_G.NusaCtr_OpenBossSummon = NusaCtr_OpenBossSummon
_G.NusaCtr_CloseBossSummon = NusaCtr_CloseBossSummon
print("[NusaCtr] BossSummon Window loaded")
