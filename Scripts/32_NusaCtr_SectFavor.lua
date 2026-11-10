-- ============================================================
-- NusaCtr Sect Favor
-- NusaCtr Sect Favor
-- Max relation / favor with all other sects (NOT Open Heart)
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

function NusaCtr_MaxAllSchoolFavor()
  local updated, failed, tried = 0, 0, 0
  local target_relation = 9999

  local sm = nil
  pcall(function() sm = CS.XiaWorld.SchoolMgr.Instance end)
  if sm == nil then pcall(function() sm = SchoolMgr and SchoolMgr.Instance end) end
  if sm == nil then pcall(function() sm = SchoolMgr end) end

  local gsm = nil
  pcall(function() gsm = CS.XiaWorld.SchoolGlobleMgr.Instance end)
  if gsm == nil then pcall(function() gsm = SchoolGlobleMgr and SchoolGlobleMgr.Instance end) end
  if gsm == nil then pcall(function() gsm = CS.XiaWorld.SchoolGlobleMgr end) end

  local schools = nil
  pcall(function()
    if gsm then
      schools = gsm.m_mapSchoools or gsm.m_mapSchools or gsm.Schools or gsm.mapSchools
    end
  end)
  if schools == nil then pcall(function() schools = CS.XiaWorld.SchoolGlobleMgr.m_mapSchoools end) end
  if schools == nil then pcall(function() schools = CS.XiaWorld.SchoolGlobleMgr.m_mapSchools end) end

  local ids = {}
  local seen = {}
  local function add_id(id)
    if id == nil then return end
    local k = tostring(id)
    if seen[k] then return end
    seen[k] = true
    ids[#ids + 1] = id
  end

  local function from_school(school)
    if school == nil then return end
    local id = nil
    pcall(function() id = school.ID end)
    if id == nil then pcall(function() id = school.Id end) end
    if id == nil then pcall(function() id = school.id end) end
    if id == nil then pcall(function() id = school.SchoolID end) end
    if id == nil then pcall(function() id = school.Name end) end
    add_id(id)
  end

  pcall(function()
    if schools == nil then return end
    for k, v in pairs(schools) do
      if type(k) == "number" or type(k) == "string" then add_id(k) end
      from_school(v)
    end
  end)
  pcall(function()
    if schools and schools.Values then
      for _, v in pairs(schools.Values) do from_school(v) end
    end
  end)
  pcall(function()
    if schools and schools.Keys then
      for _, k in pairs(schools.Keys) do add_id(k) end
    end
  end)
  local count = 0
  pcall(function() count = schools and schools.Count or 0 end)
  if count and count > 0 then
    for i = 0, count - 1 do
      local school = nil
      pcall(function() school = schools[i] end)
      if school == nil then pcall(function() school = schools:get_Item(i) end) end
      from_school(school)
    end
  end

  pcall(function()
    if sm == nil then return end
    local list = sm.AllSchools or sm.Schools or sm.m_lisSchools
    if list == nil then return end
    local c = 0
    pcall(function() c = list.Count end)
    if c and c > 0 then
      for i = 0, c - 1 do
        local s = nil
        pcall(function() s = list[i] end)
        if s == nil then pcall(function() s = list:get_Item(i) end) end
        from_school(s)
      end
    else
      for _, s in pairs(list) do from_school(s) end
    end
  end)

  if #ids == 0 then
    Msg("School data not found")
    return false
  end

  for _, id in ipairs(ids) do
    tried = tried + 1
    local ok = false

    pcall(function()
      if sm and sm.AddSchoolRelation then
        local cur = 0
        if sm.GetSchoolRelation then
          cur = tonumber(sm:GetSchoolRelation(id)) or 0
        end
        local delta = target_relation - cur
        if delta < 1 then delta = target_relation end
        sm:AddSchoolRelation(id, delta)
        ok = true
      end
    end)

    pcall(function()
      if sm and sm.SetSchoolRelation then
        sm:SetSchoolRelation(id, target_relation)
        ok = true
      end
    end)

    pcall(function()
      if sm and sm.ChangeSchoolRelation then
        sm:ChangeSchoolRelation(id, target_relation)
        ok = true
      end
    end)

    pcall(function()
      local trd = CS.XiaWorld.TradeMgr.Instance
      if trd == nil then return end
      local def = nil
      pcall(function() def = trd:GetSchoolTradeDef(id) end)
      if def then
        pcall(function() def.LikeFriendPoint = target_relation end)
        pcall(function() def.LikeRelation = target_relation end)
        pcall(function() def.FriendPoint = target_relation end)
        ok = true
      end
    end)

    pcall(function()
      if gsm == nil then return end
      local school = nil
      pcall(function() school = gsm:GetSchool(id) end)
      if school == nil and schools then
        pcall(function() school = schools[id] end)
        pcall(function()
          if school == nil and schools.get_Item then school = schools:get_Item(id) end
        end)
      end
      if school then
        pcall(function() school.Relation = target_relation end)
        pcall(function() school.relation = target_relation end)
        pcall(function() school.FriendPoint = target_relation end)
        pcall(function()
          local ranks = CS.XiaWorld.g_emSchoolRelationRank
          if ranks and ranks.Respect then school.Relation = ranks.Respect end
        end)
        ok = true
      end
    end)

    if ok then updated = updated + 1 else failed = failed + 1 end
  end

  Msg("All sect favor maxed.\nSchools: " .. tostring(tried)
    .. " | OK: " .. tostring(updated) .. " | failed: " .. tostring(failed))
  return updated > 0
end

---------------------------------------------------------------- UI
function NusaCtr_SectFavor_Refresh()
  if not View then return end
  Text(Child(View, "title"), (NusaCtr_T and NusaCtr_T("Sect Favor") or "Sect Favor"))
  Text(Child(View, "subtitle"), (NusaCtr_T and NusaCtr_T("Max relation with all other sects") or "Max relation with all other sects"))
  Text(Child(View, "brand"), "NusaCtr")
  Text(Child(View, "infoTitle"), (NusaCtr_T and NusaCtr_T("Sect Favor") or "Sect Favor"))
  Text(Child(View, "infoStatus"), (NusaCtr_T and NusaCtr_T("School relation (not Open Heart)") or "School relation (not Open Heart)"))
  Text(Child(View, "sectionTitle"), (NusaCtr_T and NusaCtr_T("Actions") or "Actions"))
  Text(Child(View, "description"),
    "Sets favor/relation with every known sect to max.\nDifferent from Open Heart + Max Favor (Jianghu NPC).")
  Text(Child(View, "statusText"), (NusaCtr_T and NusaCtr_T("NusaCtr · Sect Favor") or "NusaCtr · Sect Favor"))
  Text(Child(View, "btnBack"), (NusaCtr_T and NusaCtr_T("Back") or "Back"))
  Text(Child(View, "btnClose"), "X")

  local actions = {
    { "Max all sect favor", function() NusaCtr_MaxAllSchoolFavor() end },
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

function NusaCtr_CloseSectFavor()
  if View then
    pcall(function() View:RemoveFromParent() end)
    pcall(function() View:Dispose() end)
    View = nil
  end
end

function NusaCtr_OpenSectFavor()
  NusaCtr_CloseSectFavor()
  local pkg, root = Pkg(), Root()
  if not pkg or not root then Msg("UI missing"); return false end
  local view = nil
  pcall(function() view = pkg.CreateObject(PKG, WIN) end)
  if not view then Msg("Failed to open Sect Favor window"); return false end
  View = view
  pcall(function()
    root:AddChild(view)
    view.x = (root.width - view.width) / 2
    view.y = (root.height - view.height) / 2
  end)
  local function go_back()
    NusaCtr_CloseSectFavor()
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
  NusaCtr_SectFavor_Refresh()
  return true
end

_G.NusaCtr_OpenSectFavor = NusaCtr_OpenSectFavor
_G.NusaCtr_CloseSectFavor = NusaCtr_CloseSectFavor
_G.NusaCtr_MaxAllSchoolFavor = NusaCtr_MaxAllSchoolFavor

print("[NusaCtr] Sect Favor loaded")
