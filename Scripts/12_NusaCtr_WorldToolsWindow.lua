-- NusaCtr World Tools Window (dedicated UI)

local PKG  = "NusaCtr"
local PATH = "UI/NusaCtr"
local WIN  = "NusaWorldToolsWindow"

local View = nil
local Section = "climate"

local Sections = {
  climate = {
    title = "Time / Season / Weather",
    description = "Choose a time of day, season, or weather setting.",
    actions = {
      { "Dawn", "time_dawn" },
      { "Morning", "time_morning" },
      { "Noon", "time_noon" },
      { "Afternoon", "time_afternoon" },
      { "Evening", "time_evening" },
      { "Night", "time_night" },
      { "Choose Season", "open_season" },
      { "Choose Weather", "open_weather" },
    },
  },
  season = {
    title = "Choose Season",
    description = "Move the world date to early / mid of each season.",
    actions = {
      { "Early Spring", "spring_early" },
      { "Mid Spring", "spring" },
      { "Early Summer", "summer_early" },
      { "Mid Summer", "summer" },
      { "Early Autumn", "autumn_early" },
      { "Mid Autumn", "autumn" },
      { "Early Winter", "winter_early" },
      { "Mid Winter", "winter" },
    },
  },
 -- Weather page 1 (common + special)
  weather = {
    title = "Choose Weather (1/2)",
    description = "Common weathers. Next page has special / breakthrough weathers.",
    actions = {
      { "Clear / Sunny", "weather_clear" },
      { "Cloudy", "weather_cloudy" },
      { "Light Rain", "weather_light" },
      { "Light Snow", "weather_lightsnow" },
      { "Heavy Rain", "weather_heavy" },
      { "Heavy Snow", "weather_heavysnow" },
      { "Thick Fog", "weather_fog" },
      { "More Weather ▶", "open_weather2" },
    },
  },
 -- Weather page 2 (special / breakthrough-relevant)
  weather2 = {
    title = "Choose Weather (2/2)",
    description = "Special weathers used for breakthroughs and events.",
    actions = {
      { "Dust Storm", "weather_dust" },
      { "Thunderstorm", "weather_lightning" },
      { "Rainstorm", "weather_rainstorm" },
      { "Drought", "weather_drought" },
      { "Foehn Wind", "weather_foehn" },
      { "Noxious Miasma", "weather_miasma" },
      { "Heat Wave", "weather_heat" },
      { "Permanent Night", "weather_night" },
    },
  },
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

local function Visible(obj, v)
  if obj then
    pcall(function() obj.visible = (v == true) end)
    pcall(function() obj.touchable = (v == true) end)
  end
end

local function Run(action)
 -- Time slots
  if action == "time_dawn" then return NusaCtr_WorldTools_SetTime(5, "Dawn") end
  if action == "time_morning" then return NusaCtr_WorldTools_SetTime(8, "Morning") end
  if action == "time_noon" then return NusaCtr_WorldTools_SetTime(12, "Noon") end
  if action == "time_afternoon" then return NusaCtr_WorldTools_SetTime(15, "Afternoon") end
  if action == "time_evening" then return NusaCtr_WorldTools_SetTime(18, "Evening") end
  if action == "time_night" then return NusaCtr_WorldTools_SetTime(22, "Night") end
 -- Season early + mid (28-day seasons)
  if action == "spring_early" then return NusaCtr_WorldTools_SetSeason(3, "Early Spring") end
  if action == "spring" then return NusaCtr_WorldTools_SetSeason(14, "Mid Spring") end
  if action == "summer_early" then return NusaCtr_WorldTools_SetSeason(31, "Early Summer") end
  if action == "summer" then return NusaCtr_WorldTools_SetSeason(42, "Mid Summer") end
  if action == "autumn_early" then return NusaCtr_WorldTools_SetSeason(59, "Early Autumn") end
  if action == "autumn" then return NusaCtr_WorldTools_SetSeason(75, "Mid Autumn") end
  if action == "winter_early" then return NusaCtr_WorldTools_SetSeason(87, "Early Winter") end
  if action == "winter" then return NusaCtr_WorldTools_SetSeason(98, "Mid Winter") end
 -- Weather (wiki + game IDs)
  if action == "weather_clear" then return NusaCtr_WorldTools_SetWeather("Clear", "Clear / Sunny") end
  if action == "weather_cloudy" then return NusaCtr_WorldTools_SetWeather("Overcast", "Cloudy") end
  if action == "weather_light" then return NusaCtr_WorldTools_SetWeather("LightRain", "Light Rain") end
  if action == "weather_lightsnow" then return NusaCtr_WorldTools_SetWeather("LightSnow", "Light Snow") end
  if action == "weather_heavy" then return NusaCtr_WorldTools_SetWeather("HeavyRain", "Heavy Rain") end
  if action == "weather_heavysnow" then return NusaCtr_WorldTools_SetWeather("HeavySnow", "Heavy Snow") end
  if action == "weather_fog" then return NusaCtr_WorldTools_SetWeather("DenseFog", "Thick Fog") end
  if action == "weather_dust" then return NusaCtr_WorldTools_SetWeather("DustStorm", "Dust Storm") end
  if action == "weather_lightning" then return NusaCtr_WorldTools_SetWeather("LightningStorm", "Thunderstorm") end
  if action == "weather_rainstorm" then return NusaCtr_WorldTools_SetWeather("Rainstorm", "Rainstorm") end
  if action == "weather_drought" then return NusaCtr_WorldTools_SetWeather("Drought", "Drought") end
  if action == "weather_foehn" then return NusaCtr_WorldTools_SetWeather("Fohn", "Foehn Wind") end
  if action == "weather_miasma" then return NusaCtr_WorldTools_SetWeather("Miasma", "Noxious Miasma") end
  if action == "weather_heat" then return NusaCtr_WorldTools_SetWeather("HeatWave", "Heat Wave") end
  if action == "weather_night" then return NusaCtr_WorldTools_SetWeather("PermanentNight", "Permanent Night") end
  return false
end

local function Refresh()
  if not View then return end
  local sec = Sections[Section] or Sections.climate

  Text(Child(View, "title"), (NusaCtr_T and NusaCtr_T("World Tools") or "World Tools"))
  Text(Child(View, "subtitle"), (NusaCtr_T and NusaCtr_T("Time, season, and weather controls") or "Time, season, and weather controls"))
  Text(Child(View, "brand"), "NusaCtr")
  Text(Child(View, "infoTitle"), (NusaCtr_T and NusaCtr_T("Shared Tools") or "Shared Tools"))
  Text(Child(View, "infoStatus"), (NusaCtr_T and NusaCtr_T("Time · Season · Weather (expanded)") or "Time · Season · Weather (expanded)"))
  Text(Child(View, "sectionTitle"), (NusaCtr_T and NusaCtr_T(sec.title) or sec.title))
  Text(Child(View, "description"), (NusaCtr_T and NusaCtr_T(sec.description) or sec.description))
  Text(Child(View, "btnBack"), (NusaCtr_T and NusaCtr_T("Back") or "Back"))
  Text(Child(View, "btnClose"), "X")

  for i = 1, 8 do
    local btn = Child(View, "feature" .. i)
    local data = sec.actions[i]
    if btn then
      if data then
        Visible(btn, true)
        Text(btn, (NusaCtr_T and NusaCtr_T(data[1]) or data[1]))
      else
        Text(btn, "")
        Visible(btn, false)
      end
    end
  end
end

function NusaCtr_CloseWorldTools()
  if View then
    pcall(function() View:RemoveFromParent() end)
    pcall(function() View:Dispose() end)
    View = nil
  end
end

function NusaCtr_OpenWorldTools(section)
  NusaCtr_CloseWorldTools()
  Section = section or "climate"
  local pkg, root = Pkg(), Root()
  if not pkg or not root then return false end
  local view = nil
  pcall(function() view = pkg.CreateObject(PKG, WIN) end)
  if not view then return false end
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
        NusaCtr_CloseWorldTools()
        if NusaCtr_OpenMain then
          pcall(function() NusaCtr_OpenMain(_G.NusaCtr_LastTarget) end)
        end
      end)
    end)
  end

  local back = Child(view, "btnBack")
  if back then
    pcall(function()
      back.onClick:Clear()
      back.onClick:Add(function()
        if Section == "weather2" then
          Section = "weather"
          Refresh()
        elseif Section == "season" or Section == "weather" then
          Section = "climate"
          Refresh()
        else
          NusaCtr_CloseWorldTools()
          if NusaCtr_OpenMain then
            pcall(function() NusaCtr_OpenMain(_G.NusaCtr_LastTarget) end)
          end
        end
      end)
    end)
  end

  for i = 1, 8 do
    local index = i
    local btn = Child(view, "feature" .. i)
    if btn then
      pcall(function()
        btn.onClick:Clear()
        btn.onClick:Add(function()
          local sec = Sections[Section]
          local data = sec and sec.actions[index]
          if not data then return end
          local act = data[2]
          if act == "open_season" then
            Section = "season"
            Refresh()
          elseif act == "open_weather" then
            Section = "weather"
            Refresh()
          elseif act == "open_weather2" then
            Section = "weather2"
            Refresh()
          else
            Run(act)
          end
        end)
      end)
    end
  end

  Refresh()
  return true
end

_G.NusaCtr_OpenWorldTools = NusaCtr_OpenWorldTools
_G.NusaCtr_CloseWorldTools = NusaCtr_CloseWorldTools
print("[NusaCtr] WorldTools Window loaded (expanded)")
