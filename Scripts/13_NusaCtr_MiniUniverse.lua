-- NusaCtr Mini Universe (SpaceRing path)
-- Per-item button on ground selection via proper mod OnEnter

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

local function GetMap()
  if Map ~= nil then return Map end
  local m = nil
  pcall(function() if World and World.Map then m = World.Map end end)
  return m
end

local function GetThingMgr()
  if ThingMgr ~= nil then return ThingMgr end
  local mgr = nil
  pcall(function()
    if CS and CS.XiaWorld and CS.XiaWorld.ThingMgr then
      mgr = CS.XiaWorld.ThingMgr.Instance
    end
  end)
  return mgr
end

local function GetSpaceRing(map)
  if map == nil then return nil end
  local ok, value = pcall(function() return map.SpaceRing end)
  if ok then return value end
  return nil
end

local function GetRemoteItemType()
  local ok, value = pcall(function()
    if ThingMgr and ThingMgr.RemoteItemType then return ThingMgr.RemoteItemType end
    if CS and CS.XiaWorld and CS.XiaWorld.ThingMgr then
      return CS.XiaWorld.ThingMgr.RemoteItemType
    end
    return nil
  end)
  if ok then return value end
  return nil
end

local function ListCount(list)
  if list == nil then return 0 end
  local n = nil
  pcall(function() n = list.Count end)
  if n ~= nil then return tonumber(n) or 0 end
  pcall(function() n = list:get_Count() end)
  return tonumber(n) or 0
end

local function ListItem(list, index)
  if list == nil then return nil end
  local v = nil
  pcall(function() v = list[index] end)
  if v ~= nil then return v end
  pcall(function() v = list:get_Item(index) end)
  return v
end

local function IsSleeveBuilding(thing)
  if thing == nil then return false end
  local ok = false
  pcall(function()
    if thing.IsSleeveSpace and thing:IsSleeveSpace() == true then ok = true end
  end)
  pcall(function()
    if thing.def and tostring(thing.def.Name or "") == "Building_SleeveSpace" then ok = true end
  end)
  return ok
end

local function FindSleeveBuilding()
  local mgr = GetThingMgr()
  if mgr == nil then return nil end
  local list = nil
  pcall(function()
    if g_emThingType then list = mgr:GetThingList(g_emThingType.Building) end
  end)
  if list == nil then
    pcall(function()
      if CS and CS.XiaWorld and CS.XiaWorld.g_emThingType then
        list = mgr:GetThingList(CS.XiaWorld.g_emThingType.Building)
      end
    end)
  end
  if list == nil then return nil end
  for i = 0, ListCount(list) - 1 do
    local thing = ListItem(list, i)
    if IsSleeveBuilding(thing) then return thing end
  end
  return nil
end

local function GetRemoteStorageWnd()
  local wnd = nil
  pcall(function()
    if CS and CS.Wnd_RemoteStorage and CS.Wnd_RemoteStorage.Instance then
      wnd = CS.Wnd_RemoteStorage.Instance
    end
  end)
  if wnd then return wnd end
  pcall(function()
    if Wnd_RemoteStorage and Wnd_RemoteStorage.Instance then
      wnd = Wnd_RemoteStorage.Instance
    end
  end)
  return wnd
end

local function ItemName(item)
  local name = ""
  pcall(function()
    if item.def and item.def.Name then name = tostring(item.def.Name) end
  end)
  if name == "" then
    pcall(function() if item.Def and item.Def.Name then name = tostring(item.Def.Name) end end)
  end
  if name == "" then pcall(function() name = tostring(item.Name or "") end) end
  return name
end

local function ItemTitle(item, item_name)
  local ok, value = pcall(function() return item:GetName() end)
  if ok and value and tostring(value) ~= "" then return tostring(value) end
  ok, value = pcall(function()
    if item.def then return item.def.ThingName end
    return nil
  end)
  if ok and value and tostring(value) ~= "" then return tostring(value) end
  return tostring(item_name or "")
end

-- FreeCount first, then Count
local function ItemCount(item)
  if item == nil then return 0 end
  local ok, value = pcall(function() return item.FreeCount end)
  if ok and tonumber(value) ~= nil and tonumber(value) > 0 then return tonumber(value) end
  ok, value = pcall(function() return item.Count end)
  if ok and tonumber(value) ~= nil and tonumber(value) > 0 then return tonumber(value) end
  return 1
end

local function StartsWith(text, prefix)
  return string.sub(tostring(text or ""), 1, #tostring(prefix or "")) == tostring(prefix or "")
end

local function InferRemoteType(item, item_name)
  item_name = tostring(item_name or "")
  if StartsWith(item_name, "Item_Dan_") then return "Pills" end
  if StartsWith(item_name, "Item_Fabao_") then return "Artifacts" end
  if StartsWith(item_name, "Item_Equip_") then return "Equipment" end
  if StartsWith(item_name, "Item_Plant_") then return "Materials" end
  if StartsWith(item_name, "Item_Material_") then return "Materials" end
  local remote_type = nil
  pcall(function()
    if item and item.def and item.def.ItemType then
      remote_type = tostring(item.def.ItemType)
    end
  end)
  if remote_type and remote_type ~= "" then return remote_type end
  return "Other"
end

local function RemoteAllowed(item_name)
  item_name = tostring(item_name or "")
  if item_name == "" then return false, "empty" end
  local remote = GetRemoteItemType()
  if remote == nil then return false, "RemoteItemType=nil" end

  local ok, value = pcall(function()
    if remote.ContainsKey then return remote:ContainsKey(item_name) end
    return nil
  end)
  if ok and value == true then return true, "ContainsKey" end

  ok, value = pcall(function() return remote[item_name] end)
  if ok and value ~= nil then return true, "index" end

  ok, value = pcall(function()
    if remote.TryGetValue then return remote:TryGetValue(item_name) end
    return nil
  end)
  if ok and value == true then return true, "TryGetValue" end

  return false, "not registered"
end

local function RegisterRemoteItem(item_name, remote_type)
  item_name = tostring(item_name or "")
  if item_name == "" then return false, "empty" end
  local remote = GetRemoteItemType()
  if remote == nil then return false, "RemoteItemType=nil" end
  if RemoteAllowed(item_name) then return true, "already" end

  remote_type = tostring(remote_type or "Other")
  local ok = pcall(function() remote[item_name] = remote_type end)
  if ok then return true, "index" end
  ok = pcall(function()
    if remote.set_Item then remote:set_Item(item_name, remote_type) else error("x") end
  end)
  if ok then return true, "set_Item" end
  ok = pcall(function()
    if remote.Add then remote:Add(item_name, remote_type) else error("x") end
  end)
  if ok then return true, "Add" end
  return false, "register failed"
end

local function CountInRing(map, ring, item_name)
  local ok, value = pcall(function()
    if ring and ring.GetItemCount then return ring:GetItemCount(item_name) end
    return nil
  end)
  if ok and value ~= nil then return tonumber(value) or 0 end
  ok, value = pcall(function()
    if map and map.GetSpaceRingItemCount then return map:GetSpaceRingItemCount(item_name) end
    return nil
  end)
  if ok and value ~= nil then return tonumber(value) or 0 end
  return 0
end

local function IsSpaceRingOpen(map)
  if map == nil then return false, "Map=nil" end
  local ok, value = pcall(function() return map:IsSpaceRingOpen() end)
  if ok then return value == true, "IsSpaceRingOpen=" .. tostring(value) end
  return false, "error"
end

local function AddItemNameToSpaceRing(item_name, count, source_item, quiet)
  item_name = tostring(item_name or "")
  count = tonumber(count) or 1
  if count <= 0 then count = 1 end

  local map = GetMap()
  local ring = GetSpaceRing(map)
  if map == nil or ring == nil then
    if quiet ~= true then Msg("SpaceRing not ready") end
    return false, 0, "no ring"
  end

  local allowed = RemoteAllowed(item_name)
  if allowed ~= true then
    local rtype = InferRemoteType(source_item, item_name)
    local reg_ok = RegisterRemoteItem(item_name, rtype)
    if reg_ok ~= true then
      if quiet ~= true then Msg("Cannot register item\n" .. item_name) end
      return false, 0, "register fail"
    end
    allowed = RemoteAllowed(item_name)
    if allowed ~= true then
      if quiet ~= true then Msg("Item still not allowed\n" .. item_name) end
      return false, 0, "not allowed"
    end
  end

  local open = IsSpaceRingOpen(map)
  local before = CountInRing(map, ring, item_name)

 -- Add order: Map then SpaceRing
  local ok, ret = pcall(function() return map:AddToSpaceRing(item_name, count) end)
  local route = "Map:AddToSpaceRing"
  local err = ret

  if not (ok and ret == true) then
    ok, ret = pcall(function()
      ring:AddStorage(item_name, count, false)
      return true
    end)
    route = open and "SpaceRing:AddStorage" or "SpaceRing:AddStorage(closed)"
    err = ret
  end

  local after = CountInRing(map, ring, item_name)
  if ok and after >= before + count then
    return true, after, route
  end

 -- force AddStorage once more
  ok, ret = pcall(function()
    ring:AddStorage(item_name, count, false)
    return true
  end)
  after = CountInRing(map, ring, item_name)
  if ok and after >= before + count then
    return true, after, "SpaceRing:AddStorage(forced)"
  end

  if quiet ~= true then
    Msg("Store failed\n" .. item_name ..
        "\nbefore=" .. tostring(before) ..
        " after=" .. tostring(after) ..
        " want+" .. tostring(count) ..
        "\n" .. tostring(err))
  end
  return false, after, "mismatch"
end

local function RemoveSource(item, count)
  if item == nil then return false end
  local total = nil
  pcall(function() total = tonumber(item.Count) end)
  if total ~= nil and total > count then
    if pcall(function() item:SubCount(count) end) then return true end
  end
  if pcall(function() item:ChangeCount(0, false) end) then return true end
  if pcall(function() item:ChangeCount(0) end) then return true end
  return pcall(function()
    local mgr = GetThingMgr()
    if mgr then mgr:RemoveThing(item, false, false) end
  end)
end

---------------------------------------------------------------- open UI (menu)
function NusaCtr_OpenMiniUniverse(source)
  local from_thing = FindSleeveBuilding()
  if from_thing == nil then from_thing = source or _G.NusaCtr_LastTarget end
  if from_thing == nil then
    Msg("Need Sleeve Space building or selected NPC")
    return false
  end
  local wnd = GetRemoteStorageWnd()
  if wnd == nil then Msg("Wnd_RemoteStorage not found"); return false end
  local ok, err = pcall(function() wnd:ShowStorage(from_thing) end)
  if ok then return true end
  ok, err = pcall(function() if wnd.Show then wnd:Show(from_thing) end end)
  if ok then return true end
  Msg("Failed to open Mini Universe\n" .. tostring(err))
  return false
end

---------------------------------------------------------------- store selected — global for AddBtnData callback
function NusaCtr_StoreSelectedItem(bind)
  local item = bind
  if item == nil then Msg("No item selected"); return false end

  local item_name = ItemName(item)
  local count = ItemCount(item)
  local title = ItemTitle(item, item_name)
  if item_name == "" then Msg("Could not read item ID"); return false end

  local ok, after, route = AddItemNameToSpaceRing(item_name, count, item, false)
  if not ok then return false end

  local removed = RemoveSource(item, count)
  Msg("Stored in Mini Universe\n" .. title ..
      "\nCount: " .. tostring(count) ..
      "\nIn storage: " .. tostring(after) ..
      "\nRoute: " .. tostring(route) ..
      "\nRemoved: " .. tostring(removed))
  return true
end

_G.NusaCtr_StoreSelectedItem = NusaCtr_StoreSelectedItem
_G.NusaCtr_OpenMiniUniverse = NusaCtr_OpenMiniUniverse

---------------------------------------------------------------- button on selected item
local BTN = "To Mini Universe"
local BTN_TIP = "Store this item into Mini Universe"

local function AddBtn2Item(item)
  if item == nil then return end
 -- only items
  local is_item = true
  pcall(function()
    if g_emThingType and item.ThingType and item.ThingType ~= g_emThingType.Item then
      is_item = false
    end
  end)
  if not is_item then return end

  pcall(function() item:RemoveBtnData(BTN) end)
 -- cleanup leftover labels from other mods
  pcall(function() item:RemoveBtnData("Store All to Mini Universe") end)

  pcall(function()
    item:AddBtnData(
      BTN,
      "res/Sprs/ui/icon_hand",
      "NusaCtr_StoreSelectedItem(bind)",
      BTN_TIP,
      nil
    )
  end)
end

---------------------------------------------------------------- proper mod lifecycle (required for SelectItem event)
local Mod = GameMain:NewMod("NusaCtrMiniUniverse")

function Mod:OnEnter()
  local event_mod = GameMain:GetMod("_Event")
  if event_mod == nil then
    print("[NusaCtr] MiniUniverse OnEnter: _Event missing")
    return
  end
  event_mod:RegisterEvent(g_emEvent.SelectItem, function(evt, item, objs)
    AddBtn2Item(item)
  end, "NusaCtr_MiniUniverse_SelectItem")
  print("[NusaCtr] MiniUniverse SelectItem registered")
end

function Mod:OnLeave()
end

print("[NusaCtr] Mini Universe mod defined (button on item select)")
