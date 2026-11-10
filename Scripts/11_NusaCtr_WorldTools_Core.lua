-- NusaCtr World Tools Core (time / season / weather)
-- Expanded weather list

NusaCtr_WorldToolsState = NusaCtr_WorldToolsState or { NoFog = false }

local function Msg(s)
  s = tostring(s or "")
  pcall(function()
    if CS and CS.Wnd_Message then
      CS.Wnd_Message.Show(s, 1, nil, true, "NusaCtr", 0, 0, "")
    end
  end)
  pcall(function()
    if world and world.ShowMsgBox then world:ShowMsgBox(s) end
  end)
end

local function Helper()
  local h = nil
  pcall(function() h = GameMain:GetMod("BuildModeHelper") end)
  return h
end

function NusaCtr_WorldTools_SetTime(hour, label)
  local value = tonumber(hour) or 6
  local ok, err = pcall(function()
    local helper = Helper()
    if helper == nil then error("BuildModeHelper not found") end
    helper:ChangeTime(value)
  end)
  Msg(ok and ("Time set to " .. tostring(label or value)) or ("Failed to set time\n" .. tostring(err)))
  return ok
end

function NusaCtr_WorldTools_SetSeason(day, label)
  local ok, err = pcall(function()
    local helper = Helper()
    if helper == nil or helper.ChangeDay == nil then error("BuildModeHelper.ChangeDay not found") end
    helper:ChangeDay(tonumber(day))
  end)
  Msg(ok and ("Season set to " .. tostring(label or "selected")) or ("Failed to set season\n" .. tostring(err)))
  return ok
end

-- Try several API names used by BuildModeHelper / Weather system
function NusaCtr_WorldTools_SetWeather(weather, label)
  local ok, err = pcall(function()
    if weather == "Clear" or weather == "SunnyDay" then
      if World and World.Weather and World.Weather.ClearAllWeather then
        World.Weather:ClearAllWeather()
        return
      end
    end
    local helper = Helper()
    if helper and helper.ChangeWeather then
      helper:ChangeWeather(tostring(weather))
      return
    end
 -- fallback common paths
    if World and World.Weather then
      if World.Weather.SetWeather then
        World.Weather:SetWeather(tostring(weather))
        return
      end
      if World.Weather.AddWeather then
        World.Weather:AddWeather(tostring(weather))
        return
      end
    end
    error("No weather API found")
  end)
  Msg(ok and ("Weather set to " .. tostring(label or weather)) or ("Failed to set weather\n" .. tostring(err)))
  return ok
end

function NusaCtr_WorldTools_SetNoFog(enabled, quiet)
  enabled = enabled == true
  local ok, err = pcall(function()
    if CS and CS.GameMain and CS.GameMain.Instance then
      CS.GameMain.Instance.NoFog = enabled
    end
    if CS and CS.MapRender and CS.MapRender.Instance and CS.MapRender.Instance.Fog then
      CS.MapRender.Instance.Fog.enabled = not enabled
    end
    NusaCtr_WorldToolsState.NoFog = enabled
  end)
  if quiet ~= true then
    Msg(ok and (enabled and "Map fog disabled" or "Map fog enabled") or ("Fog change failed\n" .. tostring(err)))
  end
  return ok
end

print("[NusaCtr] WorldTools Core loaded (expanded weather)")
