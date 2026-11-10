-- ============================================================
-- NusaCtr Agency Unlock
-- World menu: unlock map places + set Agency Influence
-- UI: reuses NusaWorldToolsWindow (feature1..feature8)
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

---------------------------------------------------------------- managers
local function get_places_mgr()
  local mgr = nil
  pcall(function() mgr = CS.XiaWorld.PlacesMgr.Instance end)
  if mgr == nil then pcall(function() mgr = PlacesMgr end) end
  if mgr == nil then pcall(function() mgr = PlacesMgr and PlacesMgr.Instance end) end
  return mgr
end

local function get_outspread_mgr()
  local mgr = nil
  pcall(function() mgr = CS.XiaWorld.OutspreadMgr.Instance end)
  if mgr == nil then
    pcall(function()
      if CS and CS.XiaWorld and CS.XiaWorld.OutspreadMgr then
        mgr = CS.XiaWorld.OutspreadMgr.Instance
      end
    end)
  end
  return mgr
end

local function get_influence()
  local v = nil
  local mgr = get_outspread_mgr()
  if mgr then
    pcall(function() v = tonumber(mgr.Influence) end)
  end
  return v
end

local function force_unlock_each(mgr)
  if mgr == nil then return 0 end
  local n = 0
  pcall(function()
    if mgr.Places then
      local count = mgr.Places.Count
      if count then
        for i = 0, count - 1 do
          local p = nil
          pcall(function() p = mgr.Places:get_Item(i) end)
          if p == nil then pcall(function() p = mgr.Places[i] end) end
          if p then
            pcall(function() p.Unlocked = true end)
            pcall(function() p.IsUnlock = true end)
            pcall(function() if p.SetUnlock then p:SetUnlock(true) end end)
            n = n + 1
          end
        end
      else
        for key, p in pairs(mgr.Places) do
          if type(p) == "table" or type(p) == "userdata" then
            pcall(function() p.Unlocked = true end)
            pcall(function() p.IsUnlock = true end)
            pcall(function() if p.SetUnlock then p:SetUnlock(true) end end)
            pcall(function() if mgr.UnLockPlace then mgr:UnLockPlace(key) end end)
            n = n + 1
          end
        end
      end
    end
  end)
  pcall(function()
    if mgr.m_mapPlaces then
      for key, p in pairs(mgr.m_mapPlaces) do
        pcall(function() p.Unlocked = true end)
        pcall(function() p.IsUnlock = true end)
        pcall(function() if p.SetUnlock then p:SetUnlock(true) end end)
        pcall(function() if mgr.UnLockPlace then mgr:UnLockPlace(key) end end)
        n = n + 1
      end
    end
  end)
  return n
end

---------------------------------------------------------------- public API
function NusaCtr_Agency_UnlockAllPlaces()
 -- Prefer existing MapTools unlock if present, then force-unlock
  if NusaCtr_OpenMapTools and false then end -- no-op, keep style

  local mgr = get_places_mgr()
  if mgr == nil then
    Msg("PlacesMgr not found.\nThis feature needs the ACS world map API.")
    return false
  end

  local ok_api = pcall(function() mgr:UnlockAll() end)
  pcall(function() if mgr.UnlockAllPlaces then mgr:UnlockAllPlaces() end end)
  pcall(function() if mgr.UnLockAll then mgr:UnLockAll() end end)
  local forced = force_unlock_each(mgr)

  if ok_api or forced > 0 then
    Msg("All world map places unlocked.\n(Includes Agency locations.)")
    return true
  end
  Msg("Failed to unlock map places.\nPlacesMgr API did not respond on this build.")
  return false
end

function NusaCtr_Agency_SetInfluence(value)
  value = tonumber(value) or 1000
  local mgr = get_outspread_mgr()
  if mgr == nil then
    Msg("OutspreadMgr not found")
    return false
  end
  local ok = pcall(function() mgr.Influence = value end)
  if not ok then
    ok = pcall(function()
      if mgr.SetInfluence then mgr:SetInfluence(value) end
    end)
  end
  if ok then
    Msg("Agency Influence set to " .. tostring(value))
    return true
  end
  Msg("Failed to set Influence")
  return false
end

function NusaCtr_Agency_ShowInfluence()
  local v = get_influence()
  if v == nil then
    Msg("Could not read Influence (OutspreadMgr?).")
    return false
  end
  Msg("Current Agency Influence: " .. tostring(v))
  return true
end

---------------------------------------------------------------- UI pages
local function page_actions()
  if Page == 1 then
    return {
      title = "Map & Agency (1/2)",
      description = "Unlock world map places and set Agency Influence.",
      actions = {
        { "Unlock all map places", function()
          NusaCtr_Agency_UnlockAllPlaces()
        end },
        { "Show Influence", function()
          NusaCtr_Agency_ShowInfluence()
        end },
        { "Influence 1,000", function()
          NusaCtr_Agency_SetInfluence(1000)
        end },
        { "Influence 5,000", function()
          NusaCtr_Agency_SetInfluence(5000)
        end },
        { "Influence 10,000", function()
          NusaCtr_Agency_SetInfluence(10000)
        end },
        { "Influence 50,000", function()
          NusaCtr_Agency_SetInfluence(50000)
        end },
        { "◀ Prev page", function()
          Page = 2
          NusaCtr_Agency_Refresh()
        end },
        { "Next page ▶", function()
          Page = 2
          NusaCtr_Agency_Refresh()
        end },
      },
    }
  end
 -- Page 2: extra Influence presets
  return {
    title = "Agency Influence (2/2)",
    description = "Extra Influence presets. Page 1 has map unlock + main presets.",
    actions = {
      { "Influence 100", function()
        NusaCtr_Agency_SetInfluence(100)
      end },
      { "Influence 500", function()
        NusaCtr_Agency_SetInfluence(500)
      end },
      { "Influence 2,000", function()
        NusaCtr_Agency_SetInfluence(2000)
      end },
      { "Influence 20,000", function()
        NusaCtr_Agency_SetInfluence(20000)
      end },
      { "Influence 100,000", function()
        NusaCtr_Agency_SetInfluence(100000)
      end },
      { "Show Influence", function()
        NusaCtr_Agency_ShowInfluence()
      end },
      { "◀ Prev page", function()
        Page = 1
        NusaCtr_Agency_Refresh()
      end },
      { "Next page ▶", function()
        Page = 1
        NusaCtr_Agency_Refresh()
      end },
    },
  }
end

function NusaCtr_Agency_Refresh()
  if not View then return end
  local data = page_actions()
  local infl = get_influence()
  local infl_txt = (infl ~= nil) and tostring(infl) or "?"

  Text(Child(View, "title"), (NusaCtr_T and NusaCtr_T(data.title)) or data.title)
  Text(Child(View, "subtitle"), (NusaCtr_T and NusaCtr_T("Map · Agency Influence") or "Map · Agency Influence"))
  Text(Child(View, "brand"), "NusaCtr")
  Text(Child(View, "infoTitle"), (NusaCtr_T and NusaCtr_T("Agency Tools") or "Agency Tools"))
  Text(Child(View, "infoStatus"), (NusaCtr_T and NusaCtr_T("Unlock map places · Set Influence") or "Unlock map places · Set Influence"))
  Text(Child(View, "sectionTitle"), (NusaCtr_T and NusaCtr_T(data.title)) or data.title)
  Text(Child(View, "description"), ((NusaCtr_T and NusaCtr_T(data.description)) or data.description) .. ((NusaCtr_T and NusaCtr_T("\nCurrent Influence: ")) or "\nCurrent Influence: ") .. infl_txt)
  Text(Child(View, "statusText"), ((NusaCtr_T and NusaCtr_T("NusaCtr · Agency | Influence: ")) or "NusaCtr · Agency | Influence: ") .. infl_txt)
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
          NusaCtr_Agency_Refresh()
        end)
      end)
    elseif btn then
      Text(btn, "")
      Visible(btn, false)
    end
  end
end

function NusaCtr_CloseAgencyTools()
  if View then
    pcall(function() View:RemoveFromParent() end)
    pcall(function() View:Dispose() end)
    View = nil
  end
end

function NusaCtr_OpenAgencyTools()
  NusaCtr_CloseAgencyTools()
  Page = 1

  local pkg, root = Pkg(), Root()
  if not pkg or not root then
    Msg("UI missing")
    return false
  end

  local view = nil
  pcall(function() view = pkg.CreateObject(PKG, WIN) end)
  if not view then
    Msg("Failed to open Agency Tools window")
    return false
  end

  View = view
  pcall(function()
    root:AddChild(view)
    view.x = (root.width - view.width) / 2
    view.y = (root.height - view.height) / 2
  end)

  local close = Child(view, "btnClose")
  if close then
    pcall(function()
      if close.onClick and close.onClick.Clear then close.onClick:Clear() end
      close.onClick:Add(function()
        NusaCtr_CloseAgencyTools()
        if NusaCtr_OpenMain then
          pcall(function() NusaCtr_OpenMain(_G.NusaCtr_LastTarget) end)
        end
      end)
    end)
  end

  local back = Child(view, "btnBack")
  if back then
    pcall(function()
      if back.onClick and back.onClick.Clear then back.onClick:Clear() end
      back.onClick:Add(function()
        NusaCtr_CloseAgencyTools()
        if NusaCtr_OpenMain then
          pcall(function() NusaCtr_OpenMain(_G.NusaCtr_LastTarget) end)
        end
      end)
    end)
  end

  NusaCtr_Agency_Refresh()
  return true
end

_G.NusaCtr_OpenAgencyTools = NusaCtr_OpenAgencyTools
_G.NusaCtr_CloseAgencyTools = NusaCtr_CloseAgencyTools
_G.NusaCtr_Agency_UnlockAllPlaces = NusaCtr_Agency_UnlockAllPlaces
_G.NusaCtr_Agency_SetInfluence = NusaCtr_Agency_SetInfluence
_G.NusaCtr_Agency_ShowInfluence = NusaCtr_Agency_ShowInfluence

print("[NusaCtr] Agency Unlock loaded")
