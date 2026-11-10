-- NusaCtr Construction Tools
-- Quick Build + Free Build toggles

local PKG  = "NusaCtr"
local PATH = "UI/NusaCtr"
local WIN  = "NusaModCenterWindow"

local View = nil
NusaCtr_ConstructionToolsState = NusaCtr_ConstructionToolsState or {
  QuickBuildEnable = false,
  FreeBuildEnable = false,
  FreeBuildBackup = {},
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

local function SetVisible(obj, value)
  if not obj then return end
  pcall(function() obj.visible = value == true end)
  pcall(function() obj.touchable = value == true end)
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

local function StateText(on)
  return on and "ON" or "OFF"
end

local function BuildingDefs()
  local map = nil
  pcall(function() map = CS.XiaWorld.ThingMgr.s_mapThingDefs end)
  if not map then return nil end
  local buildings = nil
  pcall(function() buildings = map[4] end)
  if not buildings then pcall(function() buildings = map:get_Item(4) end) end
  return buildings
end

local function ToggleQuickBuild()
  local state = NusaCtr_ConstructionToolsState
  state.QuickBuildEnable = not state.QuickBuildEnable
  local ok, err = pcall(function()
    CS.GameMain.Instance.QuickBuild = state.QuickBuildEnable
  end)
  return ok, err
end

local function EnableFreeBuild()
  local state = NusaCtr_ConstructionToolsState
  local defs = BuildingDefs()
  if not defs then return false, "Building defs not found" end
  local ok, err = pcall(function()
    local e = defs:GetEnumerator()
    while e:MoveNext() do
      local def = e.Current.Value
      if def and def.Building and def.Building.BeMade then
        local made = def.Building.BeMade
        local name = tostring(def.Name)
        if not state.FreeBuildBackup[name] then
          state.FreeBuildBackup[name] = {
            CostStuffCount = made.CostStuffCount,
            CostStuffScale = made.CostStuffScale,
            CostItems = made.CostItems,
          }
        end
        made.CostStuffCount = 0
        made.CostStuffScale = 0
        made.CostItems = nil
      end
    end
    state.FreeBuildEnable = true
  end)
  return ok, err
end

local function DisableFreeBuild()
  local state = NusaCtr_ConstructionToolsState
  local defs = BuildingDefs()
  if not defs then return false, "Building defs not found" end
  local ok, err = pcall(function()
    local e = defs:GetEnumerator()
    while e:MoveNext() do
      local def = e.Current.Value
      if def and def.Building and def.Building.BeMade then
        local old = state.FreeBuildBackup[tostring(def.Name)]
        if old then
          local made = def.Building.BeMade
          made.CostStuffCount = old.CostStuffCount
          made.CostStuffScale = old.CostStuffScale
          made.CostItems = old.CostItems
        end
      end
    end
    state.FreeBuildEnable = false
  end)
  return ok, err
end

local function ToggleFreeBuild()
  if NusaCtr_ConstructionToolsState.FreeBuildEnable then
    return DisableFreeBuild()
  end
  return EnableFreeBuild()
end

local function Refresh(view)
  if not view then return end
  local state = NusaCtr_ConstructionToolsState
  local quick = state.QuickBuildEnable == true
  local free = state.FreeBuildEnable == true

  Text(Child(view, "title"), (NusaCtr_T and NusaCtr_T("Construction Tools") or "Construction Tools"))
  Text(Child(view, "subtitle"), (NusaCtr_T and NusaCtr_T("Quick Build & Free Build helpers") or "Quick Build & Free Build helpers"))
  Text(Child(view, "npcName"), (NusaCtr_T and NusaCtr_T("Construction Status") or "Construction Status"))
  Text(Child(view, "npcStatus"),
    ((NusaCtr_T and NusaCtr_T("Quick Build: ")) or "Quick Build: ") .. StateText(quick) .. "  |  " .. ((NusaCtr_T and NusaCtr_T("Free Build: ")) or "Free Build: ") .. StateText(free))
  Text(Child(view, "brand"), "NusaCtr")
  SetVisible(Child(view, "npcPortrait"), false)

  SetVisible(Child(view, "menuPanel"), false)
  for _, mn in ipairs({"menuQuick", "menuSystem", "menuBook", "menuWorld", "menuDeveloper"}) do
    SetVisible(Child(view, mn), false)
  end

  Text(Child(view, "sectionTitle"), (NusaCtr_T and NusaCtr_T("Choose Construction Mode") or "Choose Construction Mode"))
  Text(Child(view, "description"), (NusaCtr_T and NusaCtr_T("Tap a button to toggle. Status updates immediately.") or "Tap a button to toggle. Status updates immediately."))
  Text(Child(view, "feature1"), ((NusaCtr_T and NusaCtr_T("Quick Build")) or "Quick Build") .. "\n" .. StateText(quick))
  Text(Child(view, "feature2"), ((NusaCtr_T and NusaCtr_T("Free Build")) or "Free Build") .. "\n" .. StateText(free))
  Text(Child(view, "feature3"), (NusaCtr_T and NusaCtr_T("Disable All Tools") or "Disable All Tools"))
  Text(Child(view, "feature4"), (NusaCtr_T and NusaCtr_T("Refresh Status") or "Refresh Status"))
  Text(Child(view, "btnLanguage"), (NusaCtr_T and NusaCtr_T("Back to Mod") or "Back to Mod"))
  Text(Child(view, "btnClose"), "X")
  Text(Child(view, "hint"), "")

  for i = 1, 4 do SetVisible(Child(view, "feature" .. i), true) end
  for i = 5, 8 do SetVisible(Child(view, "feature" .. i), false) end
end

local function Toggle(view, which)
  local ok, err
  if which == "quick" then
    ok, err = ToggleQuickBuild()
  else
    ok, err = ToggleFreeBuild()
  end
  if not ok then Msg("Failed to change mode\n" .. tostring(err)) end
  Refresh(view)
end

local function DisableAll(view)
  local ok, err = pcall(function()
    if NusaCtr_ConstructionToolsState.QuickBuildEnable then
      ToggleQuickBuild()
    end
    if NusaCtr_ConstructionToolsState.FreeBuildEnable then
      local restored, restoreError = DisableFreeBuild()
      if not restored then error(restoreError) end
    end
  end)
  if not ok then Msg("Failed to disable tools\n" .. tostring(err)) end
  Refresh(view)
end

function NusaCtr_CloseConstructionTools()
  if View then
    pcall(function() View:RemoveFromParent() end)
    pcall(function() View:Dispose() end)
    View = nil
  end
end

function NusaCtr_OpenConstructionTools()
  NusaCtr_CloseConstructionTools()
  local pkg = Pkg()
  local root = Root()
  if not pkg or not root then
    Msg("FairyGUI not ready")
    return false
  end

  local view = nil
  local ok, err = pcall(function()
    view = pkg.CreateObject(PKG, WIN)
  end)
  if not ok or not view then
    Msg("Failed to open Construction Tools\n" .. tostring(err))
    return false
  end

  View = view
  root:AddChild(view)
  pcall(function()
    view.x = (root.width - view.width) / 2
    view.y = (root.height - view.height) / 2
  end)

  local close = Child(view, "btnClose")
  if close then
    pcall(function()
      close.onClick:Clear()
      close.onClick:Add(NusaCtr_CloseConstructionTools)
    end)
  end

  local function Bind(name, fn)
    local b = Child(view, name)
    if b then
      pcall(function()
        b.onClick:Clear()
        b.onClick:Add(fn)
      end)
    end
  end

  Bind("feature1", function() Toggle(view, "quick") end)
  Bind("feature2", function() Toggle(view, "free") end)
  Bind("feature3", function() DisableAll(view) end)
  Bind("feature4", function() Refresh(view) end)
  Bind("btnLanguage", function()
    NusaCtr_CloseConstructionTools()
    if NusaCtr_OpenMain then
      pcall(function() NusaCtr_OpenMain(_G.NusaCtr_LastTarget) end)
    end
  end)

  Refresh(view)
  return true
end

_G.NusaCtr_OpenConstructionTools = NusaCtr_OpenConstructionTools
_G.NusaCtr_CloseConstructionTools = NusaCtr_CloseConstructionTools

print("[NusaCtr] Construction Tools loaded")
