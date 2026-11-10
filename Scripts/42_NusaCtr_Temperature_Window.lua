-- NusaCtr Mobile - Temperature_Window.lua
-- Temperature ONLY. Uses the existing NusaCtr_Mobile MainWindow.
-- No Temperature_Core and no WorldTools core dependency.

local XTW_Value = 20
local XTW_View = nil

NusaCtr_TemperatureState = NusaCtr_TemperatureState or {
  LockTemp = false,
  LockedTempC = 20,
  LockedRooms = {},
  LastRoom = nil,
  LastRoomSrc = nil,
  ApplyNearbyRooms = false,
  _tempTick = 0,
}

local function show(text)
  text = tostring(text or "")
  if NusaCtr_T then text = NusaCtr_T(text) end
  pcall(function() world:ShowMsgBox(text) end)
end

local function child(view, name)
  if view == nil then return nil end
  local value = nil
  pcall(function() value = view:GetChild(name) end)
  return value
end

local function set_text(obj, value)
  if obj == nil then return end
  value = tostring(value or "")
  if NusaCtr_T and value ~= "" then value = NusaCtr_T(value) end
  pcall(function() obj.text = value end)
  pcall(function() obj.title = value end)
  pcall(function()
    local t = obj:GetChild("title")
    if t then t.text = value end
  end)
end

local function set_visible(obj, value)
  if obj == nil then return end
  pcall(function() obj.visible = value == true end)
  pcall(function() obj.touchable = value == true end)
end

local function real_npc(npc)
  if not npc then return nil end
  local r=npc
  pcall(function() if npc.npcObj then r=npc.npcObj end end)
  return r
end

-- EXACT selection path from the reference mod, kept only for Temperature.
local function remember_room_from_thing(th, label)
  if th == nil then return nil end
  label=tostring(label or "thing")
  local is_npc=false
  pcall(function()
    if th.ThingType ~= nil and g_emThingType and th.ThingType == g_emThingType.Npc then is_npc=true end
  end)
  pcall(function()
    if th.IsNpc or th.Race or th.GongKind then is_npc=true end
  end)
  if is_npc then return nil end

  local room=nil; local src=label
  pcall(function() if th.AtRoom ~= nil then room=th.AtRoom; src=label..".AtRoom" end end)
  pcall(function() if room==nil and th.Room ~= nil then room=th.Room; src=label..".Room" end end)
  pcall(function() if room==nil and th.GetRoom then room=th:GetRoom(); src=label..".GetRoom" end end)

  if room==nil then
    local key=nil
    pcall(function() key=th.Key end)
    if key==nil then pcall(function() key=th.AtKey or th.GridKey end) end
    if key~=nil then
      pcall(function()
        local rm=CS.XiaWorld.RoomMgr and CS.XiaWorld.RoomMgr.Instance
        if rm and rm.GetRoom then room=rm:GetRoom(key); src=label..".Key→RoomMgr" end
      end)
      pcall(function()
        if room==nil then
          local map=Map or (World and World.map)
          if map and map.Rooms and map.Rooms.GetRoom then room=map.Rooms:GetRoom(key); src=label..".Key→MapRooms" end
        end
      end)
      pcall(function()
        if room==nil then
          local rm=CS.XiaWorld.RoomMgr and CS.XiaWorld.RoomMgr.Instance
          if rm and rm.m_mapKey2Room then
            local ok,r=pcall(function() return rm.m_mapKey2Room[key] end)
            if ok and r then room=r; src=label..".Key→mapKey2Room" end
          end
        end
      end)
    end
  end
  if room~=nil then
    NusaCtr_TemperatureState.LastRoom=room
    NusaCtr_TemperatureState.LastRoomSrc=src
    pcall(function() NusaCtr_TemperatureState.LastRoomID=room.ID or room.Id end)
  end
  return room,src
end

local function get_room_from_selection()
  local room=nil; local src="none"
  local function try(th,label)
    if room~=nil then return end
    local r,s=remember_room_from_thing(th,label)
    if r~=nil then room=r; src=s end
  end

  pcall(function()
    if CS and CS.Wnd_GameMain and CS.Wnd_GameMain.Instance then
      local w=CS.Wnd_GameMain.Instance
      try(w.SelectBuilding,"Building")
      try(w.SelectThing,"Thing")
      try(w.m_selectBuilding,"BuildingField")
      try(w.m_selectThing,"ThingField")
      try(w.CurSelectBuilding,"CurBuilding")
      try(w.CurSelectThing,"CurThing")
    end
  end)
  pcall(function()
    if WorldLua and WorldLua.GetSelectThing then try(WorldLua:GetSelectThing(),"WorldLua") end
  end)
  pcall(function()
    if CS and CS.WorldLuaHelper then
      local helper = CS.WorldLuaHelper()
      if helper and helper.GetSelectThing then
        try(helper:GetSelectThing(),"WorldLuaHelper")
      end
    end
  end)

  if room==nil then
    pcall(function()
      if NusaCtr_TemperatureState.LastRoom~=nil then
        room=NusaCtr_TemperatureState.LastRoom
        src="saved:"..tostring(NusaCtr_TemperatureState.LastRoomSrc or "LastRoom")
      end
    end)
  end

 -- Mobile fallback: current touch/cursor grid.
  if room==nil then
    pcall(function()
      local key=nil
      if CS.MapCamera and CS.MapCamera.Instance then
        key=CS.MapCamera.Instance.MouseKey or CS.MapCamera.Instance.CenterKey
      end
      if key==nil then return end
      local r=nil
      local rm=CS.XiaWorld.RoomMgr and CS.XiaWorld.RoomMgr.Instance
      if rm and rm.GetRoom then pcall(function() r=rm:GetRoom(key) end) end
      if r==nil then
        local map=Map or (World and (World.map or World.Map))
        if map and map.Rooms and map.Rooms.GetRoom then pcall(function() r=map.Rooms:GetRoom(key) end) end
      end
      if r~=nil then
        room=r; src="cursor grid"
        NusaCtr_TemperatureState.LastRoom=r
        NusaCtr_TemperatureState.LastRoomSrc=src
      end
    end)
  end
  return room,src
end

-- Exported so MainWindow can remember the selected furniture BEFORE the main UI closes.
function NusaCtr_RememberTemperatureRoom()
  local room,src=get_room_from_selection()
  return room~=nil,room,src
end

local function read_temp(room)
  if room==nil then return nil end
  local v=nil
  pcall(function() v=tonumber(room.Temperature) end)
  if v==nil then pcall(function() v=tonumber(room.m_fTemperature) end) end
  if v==nil then pcall(function() v=tonumber(room.temp) end) end
  return v
end

local function apply_room(room,celsius)
  if room==nil then return false end
  celsius=tonumber(celsius) or 20
  local applied=false
  pcall(function() xlua.private_accessible(CS.XiaWorld.AreaRoom) end)
  pcall(function() xlua.private_accessible(CS.XiaWorld.AreaBase) end)
  pcall(function() xlua.private_accessible(CS.XiaWorld.RoomMgr) end)
  pcall(function() room.m_fTemperature=celsius; applied=true end)
  pcall(function() room.Temperature=celsius; applied=true end)
  pcall(function() room.temp=celsius; applied=true end)
  pcall(function()
    local current=read_temp(room) or 0
    local oldOff=tonumber(room.m_fTemperatureOffset) or 0
    local natural=current-oldOff
    room.m_fTemperatureOffset=celsius-natural
    applied=true
  end)
  pcall(function()
    local current=read_temp(room)
    if current~=nil and math.abs(current-celsius)>0.5 then
      local oldOff=tonumber(room.m_fTemperatureOffset) or 0
      room.m_fTemperatureOffset=oldOff+(celsius-current)
      pcall(function() room.m_fTemperature=celsius end)
      pcall(function() room.Temperature=celsius end)
    end
  end)
  pcall(function() if room.SetTemperature then room:SetTemperature(celsius); applied=true end end)
  pcall(function() if room.ChangeTemperature then room:ChangeTemperature(celsius); applied=true end end)
  return applied
end

local function collect_nearby(base_room,radius)
  local result={}
  if base_room==nil then return result end
  result[base_room]=true
  radius=tonumber(radius) or 12
  local bx,by=nil,nil
  pcall(function() if base_room.Centre then bx,by=base_room.Centre.x,base_room.Centre.y end end)
  pcall(function()
    local rm=CS.XiaWorld.RoomMgr and CS.XiaWorld.RoomMgr.Instance
    if not rm then return end
    local list=rm.Rooms or rm.m_listRooms or rm.AllRooms or rm.m_mapRooms
    if list==nil then return end
    local n=tonumber(list.Count)
    local function add(r)
      if not r or r==base_room then return end
      local rx,ry=nil,nil
      pcall(function() if r.Centre then rx,ry=r.Centre.x,r.Centre.y end end)
      if rx and bx and by then
        local dx,dy=rx-bx,ry-by
        if dx*dx+dy*dy<=radius*radius then result[r]=true end
      end
    end
    if n and n>0 then
      for i=0,n-1 do local r=nil; pcall(function() r=list:get_Item(i) end); if r==nil then pcall(function() r=list[i] end) end; add(r) end
    else pcall(function() for _,r in pairs(list) do add(r) end end) end
  end)
  local out={}
  for r,_ in pairs(result) do out[#out+1]=r end
  return out
end

local function apply_temperature(celsius,nearby)
  celsius=tonumber(celsius) or 20
  local room,src=get_room_from_selection()
  if room==nil then
    show("Gagal: room tidak terbaca.\nPastikan furniture/bangunan sudah dipilih SEBELUM membuka Temperature.")
    return false
  end
  local targets={room}
  if nearby then targets=collect_nearby(room,16) end
  local count=0
  for _,r in ipairs(targets) do
    if apply_room(r,celsius) then
      count=count+1
      NusaCtr_TemperatureState.LockedRooms[r]=celsius
    end
  end
  if count>0 then
    NusaCtr_TemperatureState.LockTemp=true
    NusaCtr_TemperatureState.LockedTempC=celsius
    NusaCtr_TemperatureState.LastRoom=room
    NusaCtr_TemperatureState.LastRoomSrc=src
    show("Target "..tostring(celsius).."°C | room: "..tostring(count).."\nKunci suhu: ON")
    return true
  end
  show("Gagal menerapkan suhu.")
  return false
end

local function unlock()
  NusaCtr_TemperatureState.LockTemp=false
  NusaCtr_TemperatureState.LockedRooms={}
  NusaCtr_TemperatureState.LastRoom=nil
  NusaCtr_TemperatureState.LastRoomSrc=nil
  show("Kunci suhu dilepas — suhu bisa berubah alami lagi")
end

-- This refresh ONLY changes the content area. Header portrait/name/status remain owned by NusaCtr MainWindow.
function NusaCtr_Temperature_Refresh(view)
  XTW_View=view
  if not view then return end

 -- Keep the original NusaCtr_Mobile Temperature page controls.
 -- Only the header is extended with Target and Lock status.
  set_text(child(view,"title"), (NusaCtr_T and NusaCtr_T("NusaCtr Tools") or "NusaCtr Tools"))
  set_text(child(view,"subtitle"), (NusaCtr_T and NusaCtr_T("Temperature Control") or "Temperature Control"))
  set_text(child(view,"brand"), "NusaCtr")

  local locked = NusaCtr_TemperatureState.LockTemp == true
  local lockC = tonumber(NusaCtr_TemperatureState.LockedTempC) or XTW_Value

 -- IMPORTANT: these are the only extra status values requested.
  set_text(child(view,"npcName"), ((NusaCtr_T and NusaCtr_T("Target: ")) or "Target: ") .. tostring(XTW_Value) .. "°C")
  set_text(child(view,"npcStatus"),
    locked and (((NusaCtr_T and NusaCtr_T("Lock: ON ")) or "Lock: ON ") .. tostring(lockC) .. "°C") or ((NusaCtr_T and NusaCtr_T("Lock: OFF")) or "Lock: OFF")
  )

  set_text(child(view,"sectionTitle"), (NusaCtr_T and NusaCtr_T("Temperature") or "Temperature"))
  set_text(child(view,"description"), (NusaCtr_T and NusaCtr_T("Set target temperature, then choose Room This or All Nearby.") or "Set target temperature, then choose Room This or All Nearby."))
  set_text(child(view,"hint"), (NusaCtr_T and NusaCtr_T("Click a furniture/building on the map before opening Temperature.") or "Click a furniture/building on the map before opening Temperature."))

 -- Temperature is a dedicated page: physically remove the five
 -- main-navigation button objects from this window instance.
 -- We do NOT merely set visible=false. Back to World closes this view
 -- and NusaCtr_OpenMain() creates a fresh main window with the sidebar.
  local sidebarNames = {
    "menuQuick",
    "menuSystem",
    "menuBook",
    "menuWorld",
    "menuDeveloper"
  }
  for _, name in ipairs(sidebarNames) do
    local b = child(view, name)
    if b then
      pcall(function() b:RemoveFromParent() end)
    end
  end

  for i=1,8 do
    local b=child(view,"feature"..tostring(i))
    if b then set_visible(b,true) end
  end

  local labels = {
    "-10°C",
    "-1°C",
    "+1°C",
    "+10°C",
    "Reset 20°C",
    "Release Lock",
    "Room This",
    "All Nearby"
  }

  local funcs = {
    function()
      XTW_Value=XTW_Value-10
      NusaCtr_Temperature_Refresh(view)
    end,
    function()
      XTW_Value=XTW_Value-1
      NusaCtr_Temperature_Refresh(view)
    end,
    function()
      XTW_Value=XTW_Value+1
      NusaCtr_Temperature_Refresh(view)
    end,
    function()
      XTW_Value=XTW_Value+10
      NusaCtr_Temperature_Refresh(view)
    end,
    function()
      XTW_Value=20
      NusaCtr_Temperature_Refresh(view)
    end,
    function()
      NusaCtr_TemperatureState.LockTemp=false
      NusaCtr_TemperatureState.LockedTempC=nil
      NusaCtr_Temperature_Refresh(view)
    end,
    function()
      apply_temperature(XTW_Value, false)
      NusaCtr_Temperature_Refresh(view)
    end,
    function()
      apply_temperature(XTW_Value, true)
      NusaCtr_Temperature_Refresh(view)
    end
  }

  for i=1,8 do
    local b=child(view,"feature"..tostring(i))
    if b then
      set_text(b, (NusaCtr_T and NusaCtr_T(labels[i])) or labels[i])
      pcall(function()
        b.onClick:Clear()
        b.onClick:Add(funcs[i])
      end)
    end
  end

  set_text(child(view,"btnLanguage"), (NusaCtr_T and NusaCtr_T("Back to World") or "Back to World"))
  local back=child(view,"btnLanguage")
  if back then
    pcall(function()
      back.onClick:Clear()
      back.onClick:Add(function()
        NusaCtr_CloseTemperatureWindow(true)
      end)
    end)
  end

  local close=child(view,"btnClose")
  if close then
    pcall(function()
      close.onClick:Clear()
      close.onClick:Add(function()
        NusaCtr_CloseTemperatureWindow(false)
      end)
    end)
  end
end

function NusaCtr_CloseTemperatureWindow(go_back)
  local target = _G.NusaCtr_LastTarget
  if go_back then
 -- The Temperature page removes the five sidebar objects from this
 -- window instance. Returning to World closes this instance and creates
 -- a fresh NusaCtr main window, so the normal sidebar is restored.
    if NusaCtr_CloseMain then pcall(NusaCtr_CloseMain) end
    if NusaCtr_OpenMain then pcall(function() NusaCtr_OpenMain(target) end) end
  else
    if NusaCtr_CloseMain then pcall(NusaCtr_CloseMain) end
  end
  XTW_View=nil
end

function NusaCtr_OpenTemperatureWindow(target)
 -- IMPORTANT: remember selected furniture BEFORE changing/closing any NusaCtr UI.
  pcall(NusaCtr_RememberTemperatureRoom)
  if NusaCtr_TemperatureState.LockTemp then
    XTW_Value=tonumber(NusaCtr_TemperatureState.LockedTempC) or 20
  else
    XTW_Value=tonumber(XTW_Value) or 20
  end
  if NusaCtr_ShowTemperaturePage then
    XTW_View=NusaCtr_ShowTemperaturePage()
    return XTW_View~=nil
  end
  show("NusaCtr MainWindow belum siap")
  return false
end

local TempMod=nil
pcall(function()
  if GameMain and GameMain.NewMod then
    TempMod=GameMain:NewMod("NusaCtrTemperature")
  end
end)

-- IMPORTANT: the reference mod does not depend only on Wnd_GameMain's
-- selection fields. It listens to the game's SelectThing/SelectBuilding
-- events and remembers the room at the exact moment the player taps a
-- furniture/building. This is the reliable mobile path.
local function register_temperature_selection_events()
  if _G.NusaCtr_TemperatureEventsRegistered then return true end

  local event_mod=nil
  pcall(function()
    event_mod=GameMain:GetMod("_Event")
  end)
  if event_mod==nil or g_emEvent==nil then return false end

  local ok_any=false

  pcall(function()
    if g_emEvent.SelectThing ~= nil then
      event_mod:RegisterEvent(
        g_emEvent.SelectThing,
        function(evt, thing, objs)
          if thing ~= nil then
            pcall(function() remember_room_from_thing(thing,"SelectThing") end)
          end
        end,
        "NusaCtr_Temperature_SelectThing"
      )
      ok_any=true
    end
  end)

  pcall(function()
    if g_emEvent.SelectBuilding ~= nil then
      event_mod:RegisterEvent(
        g_emEvent.SelectBuilding,
        function(evt, building, objs)
          if building ~= nil then
            pcall(function() remember_room_from_thing(building,"SelectBuilding") end)
          end
        end,
        "NusaCtr_Temperature_SelectBuilding"
      )
      ok_any=true
    end
  end)

  if ok_any then
    _G.NusaCtr_TemperatureEventsRegistered=true
  end
  return ok_any
end

if TempMod then
  function TempMod:OnEnter()
    register_temperature_selection_events()

    if NusaCtr_TemperatureState.LockTemp then
      for room,tc in pairs(NusaCtr_TemperatureState.LockedRooms or {}) do
        pcall(function() apply_room(room,tc) end)
      end
    end
  end

  function TempMod:OnStep(dt)
 -- Retry event registration for mobile load-order differences.
    if not _G.NusaCtr_TemperatureEventsRegistered then
      pcall(register_temperature_selection_events)
    end

    if not NusaCtr_TemperatureState.LockTemp then return end
    NusaCtr_TemperatureState._tempTick=
      (NusaCtr_TemperatureState._tempTick or 0)+(tonumber(dt) or 0.05)
    if NusaCtr_TemperatureState._tempTick<0.5 then return end
    NusaCtr_TemperatureState._tempTick=0

    for room,tc in pairs(NusaCtr_TemperatureState.LockedRooms or {}) do
      pcall(function() apply_room(room,tc) end)
    end
  end

  function TempMod:OnSave()
    return {
      LockTemp=NusaCtr_TemperatureState.LockTemp==true,
      LockedTempC=tonumber(NusaCtr_TemperatureState.LockedTempC) or 20
    }
  end

  function TempMod:OnLoad(data)
    data=data or {}
    NusaCtr_TemperatureState.LockTemp=data.LockTemp==true
    NusaCtr_TemperatureState.LockedTempC=tonumber(data.LockedTempC) or 20
  end
end

_G.NusaCtr_OpenTemperatureWindow=NusaCtr_OpenTemperatureWindow
_G.NusaCtr_CloseTemperatureWindow=NusaCtr_CloseTemperatureWindow
print("[NusaCtr] Temperature_Window loaded - integrated MainWindow")
