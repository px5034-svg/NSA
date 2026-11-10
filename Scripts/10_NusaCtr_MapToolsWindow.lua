-- NusaCtr Map Tools Window (standalone, no separate core)

local PKG  = "NusaCtr"
local PATH = "UI/NusaCtr"
local WIN  = "NusaMapToolsWindow"

local View = nil
local NoFog = false

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

local function ReadNoFog()
  local v = NoFog
  pcall(function()
    if CS and CS.GameMain and CS.GameMain.Instance then
      v = (CS.GameMain.Instance.NoFog == true)
    end
  end)
  NoFog = v == true
  return NoFog
end

local function SetNoFog(enabled)
  enabled = enabled == true
  local ok = pcall(function()
    if CS and CS.GameMain and CS.GameMain.Instance then
      CS.GameMain.Instance.NoFog = enabled
    end
    if CS and CS.MapRender and CS.MapRender.Instance and CS.MapRender.Instance.Fog then
      CS.MapRender.Instance.Fog.enabled = not enabled
    end
  end)
  if ok then NoFog = enabled end
  return ok
end

local function UnlockMap()
 -- Prefer robust Agency unlock if available
  if NusaCtr_Agency_UnlockAllPlaces then
    local ok, result = pcall(NusaCtr_Agency_UnlockAllPlaces)
    if ok and result ~= false then return true end
  end
  local ok = pcall(function()
    if CS and CS.XiaWorld and CS.XiaWorld.PlacesMgr and CS.XiaWorld.PlacesMgr.Instance then
      CS.XiaWorld.PlacesMgr.Instance:UnlockAll()
    else
      error("PlacesMgr not found")
    end
  end)
  return ok
end

local function Refresh(message)
  if not View then return end
  local noFog = ReadNoFog()
  Text(Child(View, "title"), (NusaCtr_T and NusaCtr_T("Map Management") or "Map Management"))
  Text(Child(View, "subtitle"), (NusaCtr_T and NusaCtr_T("Control fog and world-map locations") or "Control fog and world-map locations"))
  Text(Child(View, "fogTitle"), (NusaCtr_T and NusaCtr_T("Map Fog") or "Map Fog"))
  Text(Child(View, "fogDescription"), (NusaCtr_T and NusaCtr_T("Disable fog to reveal the map.\nEnable fog to restore normal visibility.")) or "Disable fog to reveal the map.\nEnable fog to restore normal visibility.")
  Text(Child(View, "fogStatus"), noFog and ((NusaCtr_T and NusaCtr_T("Status: Fog Off")) or "Status: Fog Off") or ((NusaCtr_T and NusaCtr_T("Status: Fog On")) or "Status: Fog On"))
  Text(Child(View, "btnFogToggle"), noFog and ((NusaCtr_T and NusaCtr_T("Enable Fog")) or "Enable Fog") or ((NusaCtr_T and NusaCtr_T("Disable Fog")) or "Disable Fog"))
  Text(Child(View, "worldTitle"), (NusaCtr_T and NusaCtr_T("World Map") or "World Map"))
  Text(Child(View, "worldDescription"), (NusaCtr_T and NusaCtr_T("Unlock every discoverable location on the world map.") or "Unlock every discoverable location on the world map."))
  Text(Child(View, "btnUnlockMap"), (NusaCtr_T and NusaCtr_T("Unlock All Locations") or "Unlock All Locations"))
  Text(Child(View, "statusText"), message or ((NusaCtr_T and NusaCtr_T("NusaCtr · Map Management")) or "NusaCtr · Map Management"))
  Text(Child(View, "btnClose"), "X")
end

function NusaCtr_CloseMapTools()
  if View then
    pcall(function() View:RemoveFromParent() end)
    pcall(function() View:Dispose() end)
    View = nil
  end
end

function NusaCtr_OpenMapTools()
  NusaCtr_CloseMapTools()
  local pkg, root = Pkg(), Root()
  if not pkg or not root then Msg("UI missing"); return false end
  local view = nil
  pcall(function() view = pkg.CreateObject(PKG, WIN) end)
  if not view then Msg("Failed open NusaMapToolsWindow"); return false end
  View = view
  pcall(function()
    root:AddChild(view)
    view.x = (root.width - view.width) / 2
    view.y = (root.height - view.height) / 2
  end)

  local close = Child(view, "btnClose")
  if close then
    pcall(function()
      close.onClick:Clear()
      close.onClick:Add(function()
        NusaCtr_CloseMapTools()
        if NusaCtr_OpenMain then
          pcall(function() NusaCtr_OpenMain(_G.NusaCtr_LastTarget) end)
        end
      end)
    end)
  end

  local fog = Child(view, "btnFogToggle")
  if fog then
    pcall(function()
      fog.onClick:Clear()
      fog.onClick:Add(function()
        local nextVal = not ReadNoFog()
        if SetNoFog(nextVal) then
          Refresh(nextVal and "Map fog disabled" or "Map fog enabled")
          Msg(nextVal and "Map fog disabled" or "Map fog enabled")
        else
          Msg("Failed to change fog state")
        end
      end)
    end)
  end

  local unlock = Child(view, "btnUnlockMap")
  if unlock then
    pcall(function()
      unlock.onClick:Clear()
      unlock.onClick:Add(function()
        if UnlockMap() then
          Refresh("All world-map locations unlocked")
          Msg("All world-map locations unlocked")
        else
          Msg("Failed to unlock the map")
        end
      end)
    end)
  end

  Refresh()
  return true
end

_G.NusaCtr_OpenMapTools = NusaCtr_OpenMapTools
_G.NusaCtr_CloseMapTools = NusaCtr_CloseMapTools
print("[NusaCtr] MapTools Window loaded")
