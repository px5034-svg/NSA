-- ============================================================
-- NusaCtr Sect Status (Reputation + Good/Evil Alignment)
-- NusaCtr Sect Status
-- Sect status menu
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

local function to_number(value)
  if value == nil then return nil end
  if type(value) == "number" then return value end
  local n = tonumber(value)
  if n ~= nil then return n end
  pcall(function() n = tonumber(value.value) end)
  if n ~= nil then return n end
  local text = nil
  pcall(function() text = value:ToString() end)
  text = text or tostring(value)
  return tonumber(string.match(text, "%-?%d+%.?%d*"))
end

local function get_school()
  local school = nil
  pcall(function() school = CS.XiaWorld.SchoolMgr.Instance end)
  return school
end

---------------------------------------------------------------- Reputation
function NusaCtr_GetSectReputation()
  local school = get_school()
  if school == nil then return nil, "SchoolMgr nil" end
  local value = nil
  pcall(function() value = to_number(school.BaseScore) end)
  if value ~= nil then return value, "BaseScore" end
  pcall(function() value = to_number(school.Score) end)
  if value ~= nil then return value, "Score" end
  pcall(function()
    if g_emSchoolData and g_emSchoolData.BaseScore then
      value = to_number(school:GetSchoolData(g_emSchoolData.BaseScore))
    end
  end)
  if value ~= nil then return value, "GetSchoolData.BaseScore" end
  pcall(function()
    if g_emSchoolData and g_emSchoolData.Score then
      value = to_number(school:GetSchoolData(g_emSchoolData.Score))
    end
  end)
  if value ~= nil then return value, "GetSchoolData.Score" end
  pcall(function() value = to_number(school.Prestige) end)
  if value ~= nil then return value, "Prestige" end
  return nil, "Could not read reputation"
end

function NusaCtr_ChangeSectReputation(delta)
  delta = to_number(delta)
  if delta == nil then return false, "delta invalid" end
  if delta == 0 then
    local cur = select(1, NusaCtr_GetSectReputation()) or 0
    return true, cur, cur
  end
  local school = get_school()
  if school == nil then return false, "SchoolMgr.Instance is nil" end
  local before = select(1, NusaCtr_GetSectReputation()) or 0
  local target = before + delta
  if target < 0 then target = 0 end
  local applied = false
  pcall(function()
    local helper = CS.XiaWorld.NpcLuaHelper
    if helper and helper.AddSchoolScore then
      helper.AddSchoolScore(delta)
      applied = true
    end
  end)
  if not applied then
    pcall(function()
      if school.BaseScore ~= nil then school.BaseScore = target; applied = true end
    end)
  end
  if not applied then
    pcall(function()
      if school.Score ~= nil then school.Score = target; applied = true end
    end)
  end
  if not applied then
    pcall(function()
      if g_emSchoolData and g_emSchoolData.BaseScore and school.SetSchoolData then
        school:SetSchoolData(g_emSchoolData.BaseScore, target)
        applied = true
      end
    end)
  end
  if not applied then
    pcall(function()
      if g_emSchoolData and g_emSchoolData.Score and school.SetSchoolData then
        school:SetSchoolData(g_emSchoolData.Score, target)
        applied = true
      end
    end)
  end
  if not applied then
    pcall(function()
      if school.ChangeBaseScore then school:ChangeBaseScore(delta); applied = true end
    end)
  end
  if not applied then return false, "No absolute reputation API" end
  pcall(function() school:UpdateCount() end)
  pcall(function() school:ScoreUpdate() end)
  pcall(function() school:UpdateSchoolScore() end)
  local after = select(1, NusaCtr_GetSectReputation())
  if after == nil then after = target end
  return true, after, before
end

---------------------------------------------------------------- Alignment
local GOOD_NAMES = {
  "GoodScore", "Good", "GoodValue", "ZhengScore", "Zheng", "ZhengDao",
  "nGoodScore", "m_nGoodScore", "GoodOrEvilGood", "JustScore",
  "PrestigeGood", "GoodPoint", "nZheng", "m_nZheng",
}
local EVIL_NAMES = {
  "EvilScore", "Evil", "EvilValue", "XieScore", "Xie", "XieDao",
  "nEvilScore", "m_nEvilScore", "GoodOrEvilEvil", "BadScore", "Bad",
  "PrestigeEvil", "EvilPoint", "nXie", "m_nXie", "MoScore", "DevilScore",
  "XieE", "XieEScore", "EvilAlignment", "GoodOrEvilBad",
}

local function read_field(school, names)
  for _, name in ipairs(names) do
    local v = nil
    pcall(function() v = to_number(school[name]) end)
    if v ~= nil then return v, name end
  end
  return nil, nil
end

local function write_field(school, names, value)
  for _, name in ipairs(names) do
    local ok = pcall(function() school[name] = value end)
    if ok then
      local check = nil
      pcall(function() check = to_number(school[name]) end)
      if check ~= nil then return true, name end
    end
  end
  return false, nil
end

function NusaCtr_GetAlignment()
  local school = get_school()
  if school == nil then return nil, nil, "SchoolMgr nil" end
  local good = select(1, read_field(school, GOOD_NAMES))
  local evil = select(1, read_field(school, EVIL_NAMES))
  pcall(function()
    if not g_emSchoolData then return end
    if good == nil then
      for _, key in ipairs({"Good", "GoodScore", "Zheng", "ZhengScore", "Just"}) do
        if g_emSchoolData[key] ~= nil then
          local v = to_number(school:GetSchoolData(g_emSchoolData[key]))
          if v ~= nil then good = v; break end
        end
      end
    end
    if evil == nil then
      for _, key in ipairs({"Evil", "EvilScore", "Xie", "XieScore", "Bad"}) do
        if g_emSchoolData[key] ~= nil then
          local v = to_number(school:GetSchoolData(g_emSchoolData[key]))
          if v ~= nil then evil = v; break end
        end
      end
    end
  end)
  return good, evil, nil
end

local function try_add_school_score_triple(base, good_d, evil_d)
  local school = get_school()
  local helper = nil
  pcall(function() helper = CS.XiaWorld.NpcLuaHelper end)
  local applied = false
  pcall(function()
    if helper and helper.AddSchoolScore then
      helper.AddSchoolScore(base or 0, good_d or 0, evil_d or 0)
      applied = true
    end
  end)
  if applied then return true end
  pcall(function()
    if school and school.AddSchoolScore then
      school:AddSchoolScore(base or 0, good_d or 0, evil_d or 0)
      applied = true
    end
  end)
  if applied then return true end
  pcall(function()
    if helper and helper.AddSchoolScore then
      if (good_d or 0) ~= 0 then helper.AddSchoolScore(1, good_d) end
      if (evil_d or 0) ~= 0 then helper.AddSchoolScore(2, evil_d) end
      applied = true
    end
  end)
  if applied then return true end
  pcall(function()
    if school and school.AddSchoolScore then
      if (good_d or 0) ~= 0 then school:AddSchoolScore(1, good_d) end
      if (evil_d or 0) ~= 0 then school:AddSchoolScore(2, evil_d) end
      applied = true
    end
  end)
  return applied
end

local function change_side(side, delta)
  delta = to_number(delta)
  if delta == nil then return false, "delta invalid" end
  local school = get_school()
  if school == nil then return false, "SchoolMgr nil" end
  local good, evil = NusaCtr_GetAlignment()
  good = good or 0
  evil = evil or 0
  local before = (side == "good") and good or evil
  local target = before + delta
  if target < 0 then target = 0 end
  if delta == 0 then return true, target, before end
  local applied = false
  local names = (side == "good") and GOOD_NAMES or EVIL_NAMES
  pcall(function()
    if side == "good" then
      if school.AddGoodScore then school:AddGoodScore(delta); applied = true
      elseif school.ChangeGoodScore then school:ChangeGoodScore(delta); applied = true
      elseif school.AddZheng then school:AddZheng(delta); applied = true
      elseif school.ChangeZheng then school:ChangeZheng(delta); applied = true
      end
    else
      if school.AddEvilScore then school:AddEvilScore(delta); applied = true
      elseif school.ChangeEvilScore then school:ChangeEvilScore(delta); applied = true
      elseif school.AddXie then school:AddXie(delta); applied = true
      elseif school.ChangeXie then school:ChangeXie(delta); applied = true
      elseif school.AddBadScore then school:AddBadScore(delta); applied = true
      end
    end
  end)
  if not applied then
    pcall(function()
      local helper = CS.XiaWorld.NpcLuaHelper
      if not helper then return end
      if side == "good" then
        if helper.AddGoodScore then helper.AddGoodScore(delta); applied = true
        elseif helper.ChangeGoodScore then helper.ChangeGoodScore(delta); applied = true
        end
      else
        if helper.AddEvilScore then helper.AddEvilScore(delta); applied = true
        elseif helper.ChangeEvilScore then helper.ChangeEvilScore(delta); applied = true
        end
      end
    end)
  end
  if not applied then
    if side == "good" then
      applied = try_add_school_score_triple(0, delta, 0)
    else
      applied = try_add_school_score_triple(0, 0, delta)
    end
  end
  if not applied then
    local ok = write_field(school, names, target)
    if ok then applied = true end
  end
  if not applied then
    pcall(function()
      if not school.SetSchoolData or not g_emSchoolData then return end
      local keys = (side == "good")
        and {"Good", "GoodScore", "Zheng", "ZhengScore", "Just"}
        or  {"Evil", "EvilScore", "Xie", "XieScore", "Bad"}
      for _, key in ipairs(keys) do
        if g_emSchoolData[key] ~= nil then
          school:SetSchoolData(g_emSchoolData[key], target)
          applied = true
          break
        end
      end
    end)
  end
  if not applied then return false, "No alignment API (Good/Evil)" end
  pcall(function() school:ScoreUpdate() end)
  pcall(function() school:UpdateSchoolScore() end)
  pcall(function() school:UpdateCount() end)
  local g2, e2 = NusaCtr_GetAlignment()
  local after = (side == "good") and (g2 or target) or (e2 or target)
  return true, after, before
end

function NusaCtr_ChangeGood(delta) return change_side("good", delta) end
function NusaCtr_ChangeEvil(delta) return change_side("evil", delta) end

function NusaCtr_ShowAlignment()
  local good, evil, err = NusaCtr_GetAlignment()
  if err and good == nil and evil == nil then
    Msg("Could not read alignment\n" .. tostring(err))
    return false
  end
  good = good or 0
  evil = evil or 0
  local label = "Unknown"
  if good >= 300 and evil >= 300 then label = "Controversial"
  elseif good >= 1600 and evil < 300 then label = "Celebrated (Good)"
  elseif good >= 800 and evil < 300 then label = "Honored (Good)"
  elseif good >= 300 and evil < 300 then label = "Respected (Good)"
  elseif evil >= 1600 and good < 300 then label = "Infamous (Evil)"
  elseif evil >= 800 and good < 300 then label = "Notorious (Evil)"
  elseif evil >= 300 and good < 300 then label = "Shady (Evil)"
  end
  Msg("Good: " .. tostring(good) .. "\nEvil: " .. tostring(evil) .. "\n→ " .. label)
  return true
end

---------------------------------------------------------------- UI
local function status_line()
  local rep_txt, g_txt, e_txt = "?", "?", "?"
  pcall(function()
    local r = select(1, NusaCtr_GetSectReputation())
    if r ~= nil then rep_txt = tostring(math.floor(tonumber(r) + 0.5)) end
  end)
  pcall(function()
    local g, e = NusaCtr_GetAlignment()
    if g ~= nil then g_txt = tostring(math.floor(tonumber(g) + 0.5)) end
    if e ~= nil then e_txt = tostring(math.floor(tonumber(e) + 0.5)) end
  end)
  return "Rep: " .. rep_txt .. "  |  G:" .. g_txt .. " E:" .. e_txt
end

local function page_actions()
  if Page == 1 then
    local function do_rep(delta)
      local ok2, after, before = NusaCtr_ChangeSectReputation(delta)
      if ok2 then
        Msg("Reputation: " .. tostring(before or "?") .. " → " .. tostring(after))
      else
        Msg("Failed to change reputation\n" .. tostring(after))
      end
    end
    return {
      title = "Sect Reputation (1/3)",
      description = "Raise/lower sect reputation (absolute points).",
      actions = {
        { "Reputation +500", function() do_rep(500) end },
        { "Reputation +1000", function() do_rep(1000) end },
        { "Reputation +2000", function() do_rep(2000) end },
        { "Reputation −500", function() do_rep(-500) end },
        { "Reputation −1000", function() do_rep(-1000) end },
        { "Reputation −2000", function() do_rep(-2000) end },
        { "◀ Prev page", function() Page = 3; NusaCtr_SectStatus_Refresh() end },
        { "Next page ▶", function() Page = 2; NusaCtr_SectStatus_Refresh() end },
      },
    }
  elseif Page == 2 then
    local function do_g(delta)
      local ok2, after, before = NusaCtr_ChangeGood(delta)
      if ok2 then Msg("Good: " .. tostring(before or "?") .. " → " .. tostring(after))
      else Msg("Failed to change Good\n" .. tostring(after)) end
    end
    local function do_e(delta)
      local ok2, after, before = NusaCtr_ChangeEvil(delta)
      if ok2 then Msg("Evil: " .. tostring(before or "?") .. " → " .. tostring(after))
      else Msg("Failed to change Evil\n" .. tostring(after)) end
    end
    return {
      title = "Good / Evil + (2/3)",
      description = "Increase Good or Evil (alignment path).",
      actions = {
        { "Good +300", function() do_g(300) end },
        { "Good +500", function() do_g(500) end },
        { "Good +1000", function() do_g(1000) end },
        { "Evil +300", function() do_e(300) end },
        { "Evil +500", function() do_e(500) end },
        { "Evil +1000", function() do_e(1000) end },
        { "◀ Prev page", function() Page = 1; NusaCtr_SectStatus_Refresh() end },
        { "Next page ▶", function() Page = 3; NusaCtr_SectStatus_Refresh() end },
      },
    }
  end
  local function do_g(delta)
    local ok2, after, before = NusaCtr_ChangeGood(delta)
    if ok2 then Msg("Good: " .. tostring(before or "?") .. " → " .. tostring(after))
    else Msg("Failed to change Good\n" .. tostring(after)) end
  end
  local function do_e(delta)
    local ok2, after, before = NusaCtr_ChangeEvil(delta)
    if ok2 then Msg("Evil: " .. tostring(before or "?") .. " → " .. tostring(after))
    else Msg("Failed to change Evil\n" .. tostring(after)) end
  end
  return {
    title = "Good / Evil − (3/3)",
    description = "Decrease Good or Evil. Show Alignment shows path label.",
    actions = {
      { "Good −300", function() do_g(-300) end },
      { "Good −500", function() do_g(-500) end },
      { "Good −1000", function() do_g(-1000) end },
      { "Evil −300", function() do_e(-300) end },
      { "Evil −500", function() do_e(-500) end },
      { "Evil −1000", function() do_e(-1000) end },
      { "◀ Prev page", function() Page = 2; NusaCtr_SectStatus_Refresh() end },
      { "Show Alignment", function() NusaCtr_ShowAlignment() end },
    },
  }
end


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

function NusaCtr_SectStatus_Refresh()
  if not View then return end
  local data = page_actions()
  local st = status_line()

  Text(Child(View, "title"), (NusaCtr_T and NusaCtr_T(data.title)) or data.title)
  Text(Child(View, "subtitle"), (NusaCtr_T and NusaCtr_T("Reputation · Good · Evil") or "Reputation · Good · Evil"))
  Text(Child(View, "brand"), "NusaCtr")
  Text(Child(View, "infoTitle"), (NusaCtr_T and NusaCtr_T("Sect Alignment") or "Sect Alignment"))
  Text(Child(View, "infoStatus"), st)
  Text(Child(View, "sectionTitle"), (NusaCtr_T and NusaCtr_T(data.title)) or data.title)
  Text(Child(View, "description"), ((NusaCtr_T and NusaCtr_T(data.description)) or data.description) .. "\n" .. st)
  Text(Child(View, "statusText"), ((NusaCtr_T and NusaCtr_T("NusaCtr · Sect | ")) or "NusaCtr · Sect | ") .. st)
  Text(Child(View, "btnBack"), (NusaCtr_T and NusaCtr_T("Back") or "Back"))
  Text(Child(View, "btnClose"), "X")

  for i = 1, 8 do
    local btn = Child(View, "feature" .. i)
    local act = data.actions[i]
    if btn and act and act[1] then
      Visible(btn, true)
      Text(btn, Lbtn(act[1]))
      pcall(function()
        if btn.onClick and btn.onClick.Clear then btn.onClick:Clear() end
        btn.onClick:Add(function()
          if act[2] then pcall(act[2]) end
          NusaCtr_SectStatus_Refresh()
        end)
      end)
    elseif btn then
      Text(btn, "")
      Visible(btn, false)
    end
  end
end

function NusaCtr_CloseSectStatus()
  if View then
    pcall(function() View:RemoveFromParent() end)
    pcall(function() View:Dispose() end)
    View = nil
  end
end

function NusaCtr_OpenSectStatus()
  NusaCtr_CloseSectStatus()
  Page = 1
  local pkg, root = Pkg(), Root()
  if not pkg or not root then Msg("UI missing"); return false end
  local view = nil
  pcall(function() view = pkg.CreateObject(PKG, WIN) end)
  if not view then Msg("Failed to open Sect Alignment window"); return false end
  View = view
  pcall(function()
    root:AddChild(view)
    view.x = (root.width - view.width) / 2
    view.y = (root.height - view.height) / 2
  end)
  local function go_back()
    NusaCtr_CloseSectStatus()
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
  NusaCtr_SectStatus_Refresh()
  return true
end

_G.NusaCtr_OpenSectStatus = NusaCtr_OpenSectStatus
_G.NusaCtr_CloseSectStatus = NusaCtr_CloseSectStatus
_G.NusaCtr_GetSectReputation = NusaCtr_GetSectReputation
_G.NusaCtr_ChangeSectReputation = NusaCtr_ChangeSectReputation
_G.NusaCtr_GetAlignment = NusaCtr_GetAlignment
_G.NusaCtr_ChangeGood = NusaCtr_ChangeGood
_G.NusaCtr_ChangeEvil = NusaCtr_ChangeEvil
_G.NusaCtr_ShowAlignment = NusaCtr_ShowAlignment

print("[NusaCtr] Sect Status (Reputation + Alignment) loaded")
