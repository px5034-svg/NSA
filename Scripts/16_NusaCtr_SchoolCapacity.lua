-- NusaCtr School Capacity (SchoolNpcScale)
-- FIX: Do NOT re-apply scale on OnLoad/OnAfterLoad/OnEnter.
-- RuntimeVar is already in the game save; re-applying too early after load
-- can wipe founded-sect UI back to "Establish a Sect / Require Inner Disciple".

NusaCtr_SchoolCapacityState = NusaCtr_SchoolCapacityState or {
  Target = nil,
  Base = nil,
}

local Mod = GameMain:NewMod("NusaCtrSchoolCapacity")
local CAPACITY_OPTIONS = { 20, 30, 40, 50, 60, 70, 80, 90, 100, 120, 150 }

local function Msg(message)
  message = tostring(message or "")
  if NusaCtr_T then message = NusaCtr_T(message) end
  local ok = pcall(function()
    CS.Wnd_Message.Show(message, 1, nil, true, "NusaCtr", 0, 0, "")
  end)
  if not ok then pcall(function() world:ShowMsgBox(message) end) end
end

local function ToNumber(value)
  if value == nil then return nil end
  if type(value) == "number" then return value end
  local number = tonumber(value)
  if number ~= nil then return number end
  pcall(function() number = tonumber(value.value) end)
  if number ~= nil then return number end
  local text = nil
  pcall(function() text = value:ToString() end)
  text = text or tostring(value)
  return tonumber(string.match(text, "%-?%d+%.?%d*"))
end

local function SelectIndex(result)
  if type(result) == "number" or type(result) == "string" then
    return ToNumber(result)
  end
  local count = nil
  pcall(function() count = ToNumber(result.Count) end)
  if count ~= nil and count > 0 then
    local value = nil
    pcall(function() value = result:get_Item(0) end)
    if value == nil then pcall(function() value = result[0] end) end
    return ToNumber(value)
  end
  return nil
end

local function SchoolValues()
  local school = nil
  pcall(function() school = CS.XiaWorld.SchoolMgr.Instance end)
  if school == nil then return nil, nil, nil, "SchoolMgr.Instance is nil" end

  pcall(function() school:UpdateCount() end)
  local disciple_count, wait_receive, property_count, maximum = nil, nil, nil, nil
  pcall(function() disciple_count = ToNumber(school:GetSchoolData(g_emSchoolData.NumDisciple)) end)
  pcall(function() wait_receive = ToNumber(school:GetSchoolData(g_emSchoolData.WaitReceive)) end)
  pcall(function() property_count = ToNumber(school.DiscipleCount) end)
  pcall(function() maximum = ToNumber(school:GetDiscipleMax()) end)

  local active_count = disciple_count or property_count or 0
  local current = active_count + (wait_receive or 0)
  return school, current, maximum, nil
end

local function GetScale()
  local runtime = nil
  pcall(function() runtime = CS.XiaWorld.RuntimeVar.Var end)
  if runtime == nil then return nil, "RuntimeVar.Var is nil" end
  local scale = nil
  pcall(function() scale = ToNumber(runtime.SchoolNpcScale) end)
  return scale, runtime
end

local function ApplyCapacity(target, saved_base)
  target = ToNumber(target)
  if target == nil or target < 1 then return false, "invalid target" end

  local school, current, old_max, school_error = SchoolValues()
  if school == nil then return false, school_error end
  if old_max == nil or old_max <= 0 then
    return false, "GetDiscipleMax invalid — wait until sect UI is fully loaded / founded"
  end

  local scale, runtime = GetScale()
  if runtime == nil then return false, tostring(scale) end
  local old_scale = scale
  if old_scale == nil or old_scale <= 0 then old_scale = 1 end

  local base = ToNumber(saved_base)
  if base == nil or base <= 0 then
    base = old_max / old_scale
  end
  if base <= 0 then return false, "base capacity is invalid" end

  local new_scale = (target + 0.001) / base
 -- refuse absurd scales that can break sect state
  if new_scale < 0.05 or new_scale > 80 then
    return false, "computed scale out of range: " .. tostring(new_scale)
  end

  local ok_set, set_error = pcall(function()
    runtime.SchoolNpcScale = new_scale
  end)
  if not ok_set then return false, tostring(set_error) end

  pcall(function() school:UpdateCount() end)
  local actual = nil
  pcall(function() actual = ToNumber(school:GetDiscipleMax()) end)
  if actual == nil then
    return false, "GetDiscipleMax nil after set"
  end

  NusaCtr_SchoolCapacityState.Target = target
  NusaCtr_SchoolCapacityState.Base = base
  return true, actual, current
end

function NusaCtr_SetSchoolCapacity(target)
  local _, current, maximum = SchoolValues()
  target = ToNumber(target)
  if target == nil then
    Msg("Could not read the selected capacity")
    return false
  end
  if maximum == nil or maximum < 1 then
    Msg(
      "Cannot set capacity\n" ..
      "Sect data not ready (menu looks like Establish only).\n" ..
      "If your sect WAS founded before load, try:\n" ..
      "• Reset capacity scale\n" ..
      "• Reload save WITHOUT using capacity on the same frame\n" ..
      "Do not spam capacity right after load."
    )
    return false
  end
  if current ~= nil and target < current then
    Msg(
      "Cannot apply this capacity\nThe sect currently has " ..
      tostring(current) .. " members.\nChoose a value that is not lower."
    )
    return false
  end

  local ok, actual_or_error = ApplyCapacity(target, NusaCtr_SchoolCapacityState.Base)
  if not ok then
    Msg("Failed to set disciple capacity\n" .. tostring(actual_or_error))
    return false
  end
  Msg("Maximum disciple capacity is now " .. tostring(actual_or_error) .. ".")
  return true
end

function NusaCtr_ResetSchoolCapacityScale()
  local scale, runtime = GetScale()
  if runtime == nil then
    Msg("RuntimeVar unavailable\n" .. tostring(scale))
    return false
  end
  local ok, err = pcall(function() runtime.SchoolNpcScale = 1 end)
  if not ok then
    Msg("Reset failed\n" .. tostring(err))
    return false
  end
  NusaCtr_SchoolCapacityState.Target = nil
  NusaCtr_SchoolCapacityState.Base = nil
  local school = nil
  pcall(function() school = CS.XiaWorld.SchoolMgr.Instance end)
  pcall(function() if school then school:UpdateCount() end end)
  local _, current, maximum = SchoolValues()
  Msg(
    "SchoolNpcScale reset to 1\n" ..
    "Current read: " .. tostring(current or "-") .. "/" .. tostring(maximum or "-") ..
    "\nIf Sect menu is still empty, reload the save once."
  )
  return true
end

function NusaCtr_PromoteSelectedToInnerDisciple()
  local npc = _G.NusaCtr_LastTarget
  if npc == nil then
    Msg("Select a character on the map first (Target), then try again.")
    return false
  end

  local rankEnum = nil
  pcall(function() rankEnum = CS.XiaWorld.g_emNpcRank end)
  if rankEnum == nil then pcall(function() rankEnum = g_emNpcRank end) end
  if rankEnum == nil or rankEnum.Disciple == nil then
    Msg("g_emNpcRank.Disciple not found on this build")
    return false
  end

  local ok, err = pcall(function()
    local ok2 = pcall(function()
      npc:ChangeRank(rankEnum.Disciple, true, false, true)
    end)
    if not ok2 then
      npc:ChangeRank(rankEnum.Disciple)
    end
    pcall(function() npc.IsPlayerThing = true end)
    pcall(function()
      npc.Camp = CS.XiaWorld.Fight.g_emFightCamp.Player
    end)
  end)
  if not ok then
    Msg("Promote failed\n" .. tostring(err))
    return false
  end

  local name = ""
  pcall(function() name = tostring(npc.Name or "") end)
  Msg("Promoted to Inner Disciple:\n" .. name)
  return true
end

function NusaCtr_OpenSchoolCapacity()
  local _, current, maximum, school_error = SchoolValues()
  local scale = select(1, GetScale())

  local helper = nil
  pcall(function() helper = CS.WorldLuaHelper() end)
  if helper == nil or helper.ShowSelectBox == nil then
    Msg("Selection window is unavailable")
    return false
  end

  local choices = {
    "1) Reset capacity scale (fix if Sect menu broken after load)",
    "2) Promote selected → Inner Disciple",
  }
  if maximum ~= nil and maximum >= 1 then
    for _, value in ipairs(CAPACITY_OPTIONS) do
      choices[#choices + 1] = tostring(value) .. " disciples"
    end
  end

  local prompt =
    "School Capacity\nCurrent: " ..
    tostring(current or "-") .. "/" .. tostring(maximum or "-") ..
    "\nScale: " .. tostring(scale or "-") ..
    "\n\nNOTE: Scale is kept in the game save.\n" ..
    "This tool no longer auto-applies on load\n" ..
    "(that could clear Sect menus)."

  if maximum == nil or maximum < 1 then
    prompt = prompt .. "\n\nSect data missing — try Reset, then reload save."
    if school_error then prompt = prompt .. "\n" .. tostring(school_error) end
  end

  helper:ShowSelectBox(prompt, choices, 1, 1, function(result)
    local index = SelectIndex(result)
    if index == nil then return end
    local pick = index + 1
    local label = choices[pick] or choices[index]
    if label == nil then return end
    if string.find(label, "Reset", 1, true) then
      NusaCtr_ResetSchoolCapacityScale()
    elseif string.find(label, "Promote", 1, true) then
      NusaCtr_PromoteSelectedToInnerDisciple()
    else
      local num = tonumber(string.match(label, "(%d+)"))
      if num ~= nil then NusaCtr_SetSchoolCapacity(num) end
    end
  end)
  return true
end

_G.NusaCtr_OpenSchoolCapacity = NusaCtr_OpenSchoolCapacity
_G.NusaCtr_SetSchoolCapacity = NusaCtr_SetSchoolCapacity
_G.NusaCtr_PromoteSelectedToInnerDisciple = NusaCtr_PromoteSelectedToInnerDisciple
_G.NusaCtr_ResetSchoolCapacityScale = NusaCtr_ResetSchoolCapacityScale

-- CRITICAL: no auto re-apply on enter/load (causes founded sect → Establish only)
function Mod:OnEnter()
end

function Mod:OnSave()
  return {
    Target = NusaCtr_SchoolCapacityState.Target,
    Base = NusaCtr_SchoolCapacityState.Base,
  }
end

function Mod:OnLoad(data)
  data = data or {}
  NusaCtr_SchoolCapacityState.Target = ToNumber(data.Target)
  NusaCtr_SchoolCapacityState.Base = ToNumber(data.Base)
 -- do not ApplyCapacity here
end

function Mod:OnAfterLoad()
 -- intentionally empty — see header comment
end

function Mod:NeedSyncData() return false end

print("[NusaCtr] School Capacity: no auto-apply on load (sect UI safe)")
