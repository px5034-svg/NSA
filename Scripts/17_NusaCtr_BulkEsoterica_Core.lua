-- NusaCtr Bulk Esoterica: store map manuals into library (CangJingGe)

local function Count(list)
  if list == nil then return 0 end
  local value = nil
  pcall(function() value = list.Count end)
  if value == nil then pcall(function() value = list:get_Count() end) end
  return tonumber(value) or 0
end

local function ItemAt(list, index)
  if list == nil then return nil end
  local value = nil
  pcall(function() value = list:get_Item(index) end)
  if value == nil then pcall(function() value = list[index] end) end
  return value
end

local function ThingList()
  local mgr = nil
  pcall(function() mgr = CS.XiaWorld.ThingMgr.Instance end)
  if mgr == nil then return nil, 0, "ThingMgr.Instance not found" end
  local attempts = {
    function() return mgr:GetThingList(CS.XiaWorld.g_emThingType.Item) end,
    function() return mgr:GetThingList(2) end,
  }
  for _, fn in ipairs(attempts) do
    local ok, list = pcall(fn)
    if ok and list ~= nil then return list, Count(list), nil end
  end
  return nil, 0, "Could not read map item list"
end

local function ValidEsoterica(item)
  if item == nil then return false end
  local valid = true
  pcall(function() valid = item.IsValid end)
  if valid == false then return false end
  local isEso = false
  pcall(function() isEso = item.IsEsoterica end)
  if isEso ~= true then return false end
  local id = nil
  pcall(function() id = item.EsotericaID end)
  return id ~= nil and tostring(id) ~= "" and tostring(id) ~= "nil"
end

function NusaCtr_ScanMapEsoterica()
  local list, count, err = ThingList()
  if list == nil then return nil, err end
  local entries = {}
  for i = 0, count - 1 do
    local item = ItemAt(list, i)
    if ValidEsoterica(item) then
      local id = nil
      pcall(function() id = item.EsotericaID end)
      entries[#entries + 1] = { item = item, esoterica_id = id }
    end
  end
  return entries, nil
end

local function RemoveThing(mgr, item)
  local ok, value = pcall(function() return mgr:RemoveThing(item, false, false) end)
  if ok and value ~= false then return true end
  ok, value = pcall(function() return mgr:RemoveThing(item) end)
  return ok and value ~= false
end

function NusaCtr_CollectAllMapEsoterica(npc, entries)
  local result = { ok = false, found = 0, added = 0, removed = 0, add_failed = 0, remove_failed = 0 }
  if npc == nil then result.reason = "No target NPC"; return result end

  local cang, thingMgr = nil, nil
  pcall(function() cang = CS.CangJingGeMgr.Instance end)
  pcall(function() thingMgr = CS.XiaWorld.ThingMgr.Instance end)
  if cang == nil then result.reason = "CangJingGeMgr.Instance not found"; return result end
  if thingMgr == nil then result.reason = "ThingMgr.Instance not found"; return result end

  if entries == nil then
    local err = nil
    entries, err = NusaCtr_ScanMapEsoterica()
    if entries == nil then result.reason = err; return result end
  end
  result.found = #entries
  if #entries == 0 then result.reason = "No manuals found on the map"; return result end

  for _, entry in ipairs(entries) do
    local ok, value = pcall(function()
      return cang:AddEsoterica(entry.esoterica_id, npc)
    end)
    if ok and value == true then
      result.added = result.added + 1
      if RemoveThing(thingMgr, entry.item) then
        result.removed = result.removed + 1
      else
        result.remove_failed = result.remove_failed + 1
      end
    else
      result.add_failed = result.add_failed + 1
    end
  end

  result.ok = result.added > 0 and result.add_failed == 0 and result.remove_failed == 0
  result.summary = "Found " .. result.found .. " | Stored " .. result.added .. " | Removed from map " .. result.removed
  if not result.ok then
    if result.added > 0 then
      result.reason = "Partial success | " .. result.summary
    else
      result.reason = "Could not add manuals to the library"
    end
  end
  return result
end

_G.NusaCtr_ScanMapEsoterica = NusaCtr_ScanMapEsoterica
_G.NusaCtr_CollectAllMapEsoterica = NusaCtr_CollectAllMapEsoterica
print("[NusaCtr] Bulk Esoterica core loaded")
