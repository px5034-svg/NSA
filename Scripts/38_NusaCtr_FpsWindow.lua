-- ============================================================
-- NusaCtr FPS Tools
-- Rendering only; does not change game speed / physics
-- UI: NusaWorldToolsWindow
-- ============================================================

local PKG  = "NusaCtr"
local PATH = "UI/NusaCtr"
local WIN  = "NusaWorldToolsWindow"

local View = nil
NusaCtr_FpsTarget = NusaCtr_FpsTarget or -1
NusaCtr_ActualFps = NusaCtr_ActualFps or 0

local _fpsFrames, _fpsStarted = 0, nil

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

local function read_target()
  local value = NusaCtr_FpsTarget
  pcall(function() value = tonumber(CS.UnityEngine.Application.targetFrameRate) or value end)
  return value
end

local function apply_fps(value)
  value = tonumber(value) or -1
  pcall(function() CS.UnityEngine.QualitySettings.vSyncCount = 0 end)
  local ok, err = pcall(function()
    CS.UnityEngine.Application.targetFrameRate = value
  end)
  if not ok then
    ok, err = pcall(function()
      CS.UnityEngine.Application.set_targetFrameRate(value)
    end)
  end
  if ok then NusaCtr_FpsTarget = value end
  return ok, err
end

local function target_label(value)
  if tonumber(value) == nil or tonumber(value) < 0 then return "Automatic" end
  return tostring(value) .. " FPS"
end

function NusaCtr_Fps_OnRender()
  _fpsFrames = _fpsFrames + 1
  local now = nil
  pcall(function() now = tonumber(CS.UnityEngine.Time.realtimeSinceStartup) end)
  if now == nil then return end
  if _fpsStarted == nil then _fpsStarted = now; return end
  local elapsed = now - _fpsStarted
  if elapsed < 0.5 then return end
  NusaCtr_ActualFps = _fpsFrames / elapsed
  _fpsFrames = 0
  _fpsStarted = now
  if View then pcall(NusaCtr_Fps_Refresh) end
end

function NusaCtr_Fps_Refresh()
  if not View then return end
  local current = read_target()
  local measured = tonumber(NusaCtr_ActualFps) or 0
  local measuredText = measured > 0 and string.format("%.1f FPS", measured) or "Measuring..."

  Text(Child(View, "title"), (NusaCtr_T and NusaCtr_T("FPS Tools") or "FPS Tools"))
  Text(Child(View, "subtitle"), (NusaCtr_T and NusaCtr_T("Mobile frame rate only") or "Mobile frame rate only"))
  Text(Child(View, "brand"), "NusaCtr")
  Text(Child(View, "infoTitle"), (NusaCtr_T and NusaCtr_T("FPS Tools") or "FPS Tools"))
  Text(Child(View, "infoStatus"), ((NusaCtr_T and NusaCtr_T("Target: ")) or "Target: ") .. target_label(current))
  Text(Child(View, "sectionTitle"), (NusaCtr_T and NusaCtr_T("Select frame rate") or "Select frame rate"))
  Text(Child(View, "description"),
    "Does not change game speed or physics.\nActual FPS depends on device.")
  Text(Child(View, "statusText"), ((NusaCtr_T and NusaCtr_T("Measured: ")) or "Measured: ") .. measuredText)
  Text(Child(View, "btnBack"), (NusaCtr_T and NusaCtr_T("Back") or "Back"))
  Text(Child(View, "btnClose"), "X")

  local options = {
    { 30, "30 FPS" },
    { 60, "60 FPS" },
    { 90, "90 FPS" },
    { 120, "120 FPS" },
    { -1, "Automatic" },
  }
  for i = 1, 8 do
    local btn = Child(View, "feature" .. i)
    local opt = options[i]
    if btn and opt then
      Visible(btn, true)
      local selected = tonumber(current) == opt[1]
      Text(btn, (selected and "▶ " or "") .. ((NusaCtr_T and NusaCtr_T(opt[2])) or opt[2]))
      pcall(function()
        if btn.onClick and btn.onClick.Clear then btn.onClick:Clear() end
        local fps = opt[1]
        btn.onClick:Add(function()
          local ok, err = apply_fps(fps)
          if not ok then
            Msg("Failed to set FPS\n" .. tostring(err))
          else
            Msg("FPS set to: " .. target_label(fps))
          end
          NusaCtr_Fps_Refresh()
        end)
      end)
    elseif btn then
      Text(btn, "")
      Visible(btn, false)
    end
  end
end

function NusaCtr_CloseFps()
  if View then
    pcall(function() View:RemoveFromParent() end)
    pcall(function() View:Dispose() end)
    View = nil
  end
end

function NusaCtr_OpenFps()
  NusaCtr_CloseFps()
  local pkg, root = Pkg(), Root()
  if not pkg or not root then Msg("UI missing"); return false end
  local view = nil
  pcall(function() view = pkg.CreateObject(PKG, WIN) end)
  if not view then Msg("Failed to open FPS window"); return false end
  View = view
  pcall(function()
    root:AddChild(view)
    view.x = (root.width - view.width) / 2
    view.y = (root.height - view.height) / 2
  end)
  local function go_back()
    NusaCtr_CloseFps()
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
  NusaCtr_Fps_Refresh()
  return true
end

_G.NusaCtr_OpenFps = NusaCtr_OpenFps
_G.NusaCtr_CloseFps = NusaCtr_CloseFps
_G.NusaCtr_Fps_OnRender = NusaCtr_Fps_OnRender

print("[NusaCtr] FPS Tools loaded")
