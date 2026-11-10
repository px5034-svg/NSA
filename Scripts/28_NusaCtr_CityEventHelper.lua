-- ============================================================
-- NusaCtr City Event Helper
-- NusaCtr City Event Helper
-- Shows (+)/(-)/(~) on Agency/city event choice buttons
-- Toggle: World → Agency Tools → page 2
-- Note: depends on PC UI (Wnd_QuickCityWindow). On mobile it may be
-- unavailable; everything is pcall-wrapped for safety.
-- NusaCtr city event tools
-- ============================================================

NusaCtr_CityEventHelper_Enabled = NusaCtr_CityEventHelper_Enabled
if NusaCtr_CityEventHelper_Enabled == nil then NusaCtr_CityEventHelper_Enabled = true end

local CityEventHelper = nil
pcall(function()
  CityEventHelper = GameMain:GetMod("NusaCtr_CityEventHelper")
end)
if CityEventHelper == nil then
  pcall(function()
    CityEventHelper = GameMain:NewMod("NusaCtr_CityEventHelper")
  end)
end
if CityEventHelper == nil then
  CityEventHelper = {}
end

local SolveWayEnumMapping = {
  [0] = nil, [1] = nil, [2] = nil, [3] = nil, [4] = nil,
  [5] = nil, [6] = nil, [7] = nil, [8] = nil, [9] = nil,
}

local function fill_solve_way()
  pcall(function()
    local SW = CS.XiaWorld.OutspreadMgr.Region.SolveWay
    SolveWayEnumMapping[0] = SW.None
    SolveWayEnumMapping[1] = SW.Social
    SolveWayEnumMapping[2] = SW.Fight
    SolveWayEnumMapping[3] = SW.Charm
    SolveWayEnumMapping[4] = SW.Intelligence
    SolveWayEnumMapping[5] = SW.Food
    SolveWayEnumMapping[6] = SW.LingStone
    SolveWayEnumMapping[7] = SW.Wood
    SolveWayEnumMapping[8] = SW.Rock
    SolveWayEnumMapping[9] = SW.Member
  end)
end

local EventResultPositive = {
  IncreaseAllPop = 1, SlightlyIncreaseAllPop = 2,
  IncreasePop = 3, SlightlyIncreasePop = 4,
  HugeIncreaseStab = 5, IncreaseStab = 6, SlightlyIncreaseStab = 7,
  GreatlyIncreaseAttra = 8, IncreaseAttra = 9, SlightlyIncreaseAttra = 10,
  DecreaseOtherAttra = 11, SlightlyDecreaseOtherAttra = 12,
  DecreaseOtherPop = 13, SlightlyDecreaseOtherPop = 14,
  DirectlyGrabOtherPop = 15, DirectlyGrabOtherPopSlightly = 16,
  AddGodPopulation = 17,
}

local EventResultNegative = {
  DecreasePop = 1, SlightlyDecreasePop = 2,
  DecreaseAllPop = 3, SlightlyDecreaseAllPop = 4,
  IncreaseOtherPop = 5, SlightlyIncreaseOtherPop = 6,
  IncreaseOtherAttra = 7, SlightlyIncreaseOtherAttra = 8,
  HugeDecreaseStab = 9, DecreaseStab = 10, SlightlyDecreaseStab = 11,
  DecreaseAttra = 12, SlightlyDecreaseAttra = 13,
  DisasterAffectAllPop = 14, DisasterDecreaseAllPop = 15,
}

local EventResultNeutral = { NoEvent = 1 }

local CityWindowHookRegistered = false
local CityEventWindowHookRegistered = false
local ChangeFlag = false
local TimePassed = 0
local HookAvailable = nil -- nil=unknown, true/false

local function log(...)
  local parts = { "[NusaCtrCityEventHelper]" }
  for i = 1, select("#", ...) do
    parts[#parts + 1] = tostring(select(i, ...) or "nil")
  end
  pcall(function() print(table.concat(parts, " ")) end)
end

function NusaCtr_CityEventHelper_IsEnabled()
  return NusaCtr_CityEventHelper_Enabled == true
end

function NusaCtr_CityEventHelper_Toggle()
  NusaCtr_CityEventHelper_Enabled = not NusaCtr_CityEventHelper_Enabled
  return NusaCtr_CityEventHelper_Enabled
end

function NusaCtr_CityEventHelper_StatusText()
  if HookAvailable == false then
    return "N/A"
  end
  if NusaCtr_CityEventHelper_Enabled then return "ON" end
  return "OFF"
end

function NusaCtr_CityEventHelper_IsSupported()
  if HookAvailable ~= nil then return HookAvailable end
  local ok = false
  pcall(function()
    if CS and CS.Wnd_QuickCityWindow and CS.Wnd_QuickCityWindow.Instance then
      ok = true
    end
  end)
  HookAvailable = ok
  return ok
end

function CityEventHelper:OnInit()
  pcall(function()
    if xlua and xlua.private_accessible then
      pcall(function() xlua.private_accessible(CS.Wnd_QuickCityWindow) end)
      pcall(function() xlua.private_accessible(CS.XiaWorld.MapStoryMgr) end)
      pcall(function() xlua.private_accessible(CS.FairyGUI.GObject) end)
    end
  end)
  fill_solve_way()
  log("OnInit")
end

function CityEventHelper:OnEnter()
  if CityWindowHookRegistered then return end
  local ok = pcall(function()
    local wnd = CS.Wnd_QuickCityWindow.Instance
    if wnd == nil or wnd.onAddedToStage == nil then
      error("no city window")
    end
    wnd.onAddedToStage:Add(function()
      CityEventHelper:OnWnd_QuickCityWindowAdded(wnd)
    end)
    CityWindowHookRegistered = true
    HookAvailable = true
    log("Hooked city window")
  end)
  if not ok then
    HookAvailable = false
    log("City window hook unavailable (maybe mobile / different build)")
  end
end

function CityEventHelper:OnWnd_QuickCityWindowAdded(wnd)
  if CityEventWindowHookRegistered then return end
  pcall(function()
    wnd.UIInfo.m_buildtype.onChanged:Add(function()
      if not NusaCtr_CityEventHelper_Enabled then return end
      pcall(function()
        if wnd.UIInfo.m_buildtype.selectedIndex == 2 then
          ChangeFlag = true
        end
      end)
    end)
    CityEventWindowHookRegistered = true
    log("Hooked city event tab")
  end)
end

function CityEventHelper:OnRender(dt)
  if not NusaCtr_CityEventHelper_Enabled then return end
  if ChangeFlag ~= true then return end
  TimePassed = TimePassed + (tonumber(dt) or 0)
  if TimePassed > 0.1 then
    ChangeFlag = false
    TimePassed = 0
    pcall(function() CityEventHelper:UpdateCityEventWindow() end)
  end
end

function CityEventHelper:UpdateCityEventWindow()
  if not NusaCtr_CityEventHelper_Enabled then return end
  local wnd = nil
  pcall(function() wnd = CS.Wnd_QuickCityWindow.Instance end)
  if wnd == nil then return end

  local region = nil
  pcall(function() region = wnd.curregion end)
  if region == nil then return end

  local policyName = nil
  local eventResultCode = nil
  pcall(function()
    local policyStoryDef = CS.XiaWorld.OutspreadMgr.Instance:GetPolicyStoryDef(region.RegionPolicy.PolicyStory)
    policyName = policyStoryDef.Story
    local storyDef = MapStoryMgr:GetStoryDef(policyName)
    eventResultCode = storyDef.Selections[0].OKResult
  end)
  if eventResultCode == nil then return end

  log("Event:", tostring(policyName), "Region:", tostring(region.RegionName))

  pcall(function()
    local buttonsList = wnd.UIInfo.m_n31
    for i = 0, 8 do
      local button = buttonsList:GetChildAt(i)
      local decisionId = button.data
      local result = CityEventHelper:EvaluateEventCode(eventResultCode, region, decisionId)

      local titleUpdate = ""
      local descriptionUpdate = ""
      local positiveEffectsCount = 0
      local negativeEffectsCount = 0

      for key, _ in pairs(result) do
        if EventResultPositive[key] ~= nil then
          positiveEffectsCount = positiveEffectsCount + 1
          descriptionUpdate = descriptionUpdate .. "\n" .. "<font color=#009600>" .. key .. "</font>"
        end
        if EventResultNegative[key] ~= nil then
          negativeEffectsCount = negativeEffectsCount + 1
          descriptionUpdate = descriptionUpdate .. "\n" .. "<font color=#D06508>" .. key .. "</font>"
        end
        if EventResultNeutral[key] ~= nil then
          descriptionUpdate = descriptionUpdate .. "\n" .. key
        end
      end

      if positiveEffectsCount > 0 and negativeEffectsCount > 0 then
        titleUpdate = "(~)"
      elseif positiveEffectsCount > 0 then
        titleUpdate = "(+)"
      elseif negativeEffectsCount > 0 then
        titleUpdate = "(-)"
      end

      pcall(function()
        if decisionId == 6 then
          button.title = "Spirit" .. titleUpdate
        else
          button.title = CS.XiaWorld.GameDefine.SolveWayToStr[decisionId] .. titleUpdate
        end
      end)
      if descriptionUpdate ~= "" then
        pcall(function()
          button.tooltips = CS.XiaWorld.GameDefine.SolveWayToDes[decisionId] .. "\n" .. descriptionUpdate
        end)
      end
    end
  end)
end

function CityEventHelper:EvaluateEventCode(eventResultCode, region, decision)
  local RealMapStoryHelper = nil
  pcall(function() RealMapStoryHelper = GameMain:GetMod("MapStoryHelper") end)

  local EventResult = {}
  local MockMetaTable = {}
  function MockMetaTable.__index(_, k)
    EventResult[k] = 1
    if RealMapStoryHelper then
      if k == "MPL" then return RealMapStoryHelper.MPL end
      if k == "SPL" then return RealMapStoryHelper.SPL end
      if k == "SML" then return RealMapStoryHelper.SML end
      if k == "MPP" then return RealMapStoryHelper.MPP end
      if k == "SPP" then return RealMapStoryHelper.SPP end
      if k == "SMP" then return RealMapStoryHelper.SMP end
    end
    return function() end
  end
  local MockStoryHelper = {}
  setmetatable(MockStoryHelper, MockMetaTable)

  local testContext = {
    story = {
      target = {
        region = {
          UnionData = region.UnionData,
          RegionPolicy = {
            Way = SolveWayEnumMapping[decision],
          },
          GetNotSelfRegionSchool = function()
            local r = nil
            pcall(function() r = region:GetNotSelfRegionSchool() end)
            return r
          end,
          GetReligion = function(idx)
            local r = nil
            pcall(function() r = region:GetReligion(idx) end)
            return r
          end,
          FaithNpc = { LuaHelper = MockStoryHelper },
        },
        schools = region.RegionPolicy and region.RegionPolicy.Schools,
      },
    },
    GameMain = {
      GetMod = function() return MockStoryHelper end,
    },
    WorldLua = { AddMsg = function() end },
    CS = {
      XiaWorld = {
        OutspreadMgr = {
          Region = {
            SolveWay = (CS and CS.XiaWorld and CS.XiaWorld.OutspreadMgr and CS.XiaWorld.OutspreadMgr.Region and CS.XiaWorld.OutspreadMgr.Region.SolveWay) or {},
          },
          Instance = {
            CanCostItem = function(_, item, amount)
              local r = false
              pcall(function()
                r = CS.XiaWorld.OutspreadMgr.Instance:CanCostItem(item, amount)
              end)
              return r
            end,
            CostItem = function() end,
          },
        },
      },
    },
    XT = function() end,
  }

  pcall(function()
    local loader = load
    if loader == nil then loader = loadstring end
    if loader == nil then return end
    local fn = loader(eventResultCode, nil, "t", testContext)
    if fn then fn() end
  end)
  return EventResult
end

---------------------------------------------------------------- Dedicated UI window
local PKG  = "NusaCtr"
local PATH = "UI/NusaCtr"
local WIN  = "NusaWorldToolsWindow"
local CEH_View = nil

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

function NusaCtr_CityEventHelper_Refresh()
  if not CEH_View then return end
  local st = NusaCtr_CityEventHelper_StatusText and NusaCtr_CityEventHelper_StatusText() or "?"
  local supported = true
  pcall(function()
    if NusaCtr_CityEventHelper_IsSupported then
      supported = NusaCtr_CityEventHelper_IsSupported()
    end
  end)
  local apiLine = supported and "City API: available" or "City API: missing (mobile build?)"

  Text(Child(CEH_View, "title"), (NusaCtr_T and NusaCtr_T("City Event Helper") or "City Event Helper"))
  Text(Child(CEH_View, "subtitle"), (NusaCtr_T and NusaCtr_T("Agency event choice markers") or "Agency event choice markers"))
  Text(Child(CEH_View, "brand"), "NusaCtr")
  Text(Child(CEH_View, "infoTitle"), (NusaCtr_T and NusaCtr_T("City Event Helper") or "City Event Helper"))
  Text(Child(CEH_View, "infoStatus"), (NusaCtr_T and NusaCtr_T("Mark choices with (+)/(-)/(~)") or "Mark choices with (+)/(-)/(~)"))
  Text(Child(CEH_View, "sectionTitle"), (NusaCtr_T and NusaCtr_T("Controls") or "Controls"))
  Text(Child(CEH_View, "description"),
    ((NusaCtr_T and NusaCtr_T("Marks Agency event choices with (+)/(-)/(~).\nStatus: ")) or "Marks Agency event choices with (+)/(-)/(~).\nStatus: ")
      .. tostring(st) .. "\n" .. apiLine)
  Text(Child(CEH_View, "statusText"), ((NusaCtr_T and NusaCtr_T("NusaCtr · City Event Helper | ")) or "NusaCtr · City Event Helper | ") .. tostring(st))
  Text(Child(CEH_View, "btnBack"), (NusaCtr_T and NusaCtr_T("Back") or "Back"))
  Text(Child(CEH_View, "btnClose"), "X")

  local actions = {
    { "Toggle Helper", function()
      if NusaCtr_CityEventHelper_Toggle then
        local on = NusaCtr_CityEventHelper_Toggle()
        Msg(on and "City Event Helper: ON" or "City Event Helper: OFF")
      else
        Msg("Module not loaded")
      end
    end },
    { "Show status", function()
      local s = NusaCtr_CityEventHelper_StatusText and NusaCtr_CityEventHelper_StatusText() or "?"
      Msg("City Event Helper: " .. tostring(s) .. "\n" .. apiLine
        .. "\n\nWhen an Agency event appears, choices are marked (+)/(-)/(~).")
    end },
    { "Helper ON", function()
      NusaCtr_CityEventHelper_Enabled = true
      _G.NusaCtr_CityEventHelper_Enabled = true
      Msg("City Event Helper: ON")
    end },
    { "Helper OFF", function()
      NusaCtr_CityEventHelper_Enabled = false
      _G.NusaCtr_CityEventHelper_Enabled = false
      Msg("City Event Helper: OFF")
    end },
  }

  for i = 1, 8 do
    local btn = Child(CEH_View, "feature" .. i)
    local act = actions[i]
    if btn and act and act[1] then
      Visible(btn, true)
      Text(btn, (NusaCtr_T and NusaCtr_T(act[1])) or act[1])
      pcall(function()
        if btn.onClick and btn.onClick.Clear then btn.onClick:Clear() end
        btn.onClick:Add(function()
          if act[2] then pcall(act[2]) end
          NusaCtr_CityEventHelper_Refresh()
        end)
      end)
    elseif btn then
      Text(btn, "")
      Visible(btn, false)
    end
  end
end

function NusaCtr_CloseCityEventHelper()
  if CEH_View then
    pcall(function() CEH_View:RemoveFromParent() end)
    pcall(function() CEH_View:Dispose() end)
    CEH_View = nil
  end
end

function NusaCtr_OpenCityEventHelper()
  NusaCtr_CloseCityEventHelper()

  local pkg, root = Pkg(), Root()
  if not pkg or not root then
    Msg("UI missing")
    return false
  end

  local view = nil
  pcall(function() view = pkg.CreateObject(PKG, WIN) end)
  if not view then
    Msg("Failed to open City Event Helper window")
    return false
  end

  CEH_View = view
  pcall(function()
    root:AddChild(view)
    view.x = (root.width - view.width) / 2
    view.y = (root.height - view.height) / 2
  end)

  local function go_back()
    NusaCtr_CloseCityEventHelper()
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

  NusaCtr_CityEventHelper_Refresh()
  return true
end

_G.NusaCtr_CityEventHelper_Enabled = NusaCtr_CityEventHelper_Enabled
_G.NusaCtr_CityEventHelper_Toggle = NusaCtr_CityEventHelper_Toggle
_G.NusaCtr_CityEventHelper_StatusText = NusaCtr_CityEventHelper_StatusText
_G.NusaCtr_CityEventHelper_IsSupported = NusaCtr_CityEventHelper_IsSupported
_G.NusaCtr_CityEventHelper_IsEnabled = NusaCtr_CityEventHelper_IsEnabled
_G.NusaCtr_OpenCityEventHelper = NusaCtr_OpenCityEventHelper
_G.NusaCtr_CloseCityEventHelper = NusaCtr_CloseCityEventHelper

pcall(function()
  if CityEventHelper and CityEventHelper.OnInit then
    CityEventHelper:OnInit()
  end
end)

print("[NusaCtr] City Event Helper loaded")
