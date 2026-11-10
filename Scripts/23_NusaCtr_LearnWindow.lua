-- NusaCtr Learn Window — learn all / current / library arts

local PKG, PATH, WIN = "NusaCtr", "UI/NusaCtr", "NusaModCenterWindow"
local View, Target, Mode = nil, nil, "all"

local function Pkg()
  local p = UIPackage or (CS and CS.FairyGUI and CS.FairyGUI.UIPackage)
  if p then pcall(function() p.AddPackage(PATH) end) end
  return p
end
local function Root()
  return (GRoot and GRoot.inst) or (CS and CS.FairyGUI and CS.FairyGUI.GRoot and CS.FairyGUI.GRoot.inst)
end
local function Child(v, n)
  local c = nil; if v then pcall(function() c = v:GetChild(n) end) end; return c
end
local function Text(o, s)
  if not o then return end
  s = tostring(s or "")
  pcall(function() o.text = s end); pcall(function() o.title = s end)
  pcall(function() local t = o:GetChild("title"); if t then t.text = s end end)
end
local function Vis(o, v)
  if not o then return end
  pcall(function() o.visible = v == true end); pcall(function() o.touchable = v == true end)
end
local function Msg(s)
  s = tostring(s or "")
  if NusaCtr_T then s = NusaCtr_T(s) end
  pcall(function() CS.Wnd_Message.Show(s, 1, nil, true, "NusaCtr", 0, 0, "") end)
  pcall(function() if world then world:ShowMsgBox(s) end end)
end
local function NpcName(npc)
  local n = "NPC"
  pcall(function() n = tostring(npc.Name or npc:GetName()) end)
  return n
end


local function RealNpc(npc)
  return npc
end
local function NpcIcon(npc)
  local r = RealNpc(npc)
  if r == nil then return "" end
  local icon = ""
  pcall(function()
    if r.Race then
      icon = tostring(r.Race.TexPath or r.Race.Rolepaint or r.Race.Head or r.Race.Body or "")
    end
  end)
  if icon == "" then
    pcall(function() icon = tostring(r.TexPath or r.HeadIcon or r.Icon or "") end)
  end
  if icon == "" then
    pcall(function()
      if r.RaceDef then
        icon = tostring(r.RaceDef.TexPath or r.RaceDef.Rolepaint or "")
      end
    end)
  end
  return icon or ""
end
local function ApplyPortrait(view, npc)
  local portrait = Child(view, "npcPortrait")
  if not portrait then return end
  Vis(portrait, true)
  local icon = NpcIcon(npc)
  if icon and icon ~= "" then
    pcall(function() portrait.url = icon end)
    pcall(function() portrait.icon = icon end)
  end
end

local function ModeTitle()
  local function L(s) return (NusaCtr_T and NusaCtr_T(s)) or s end
  if Mode == "current" then return L("Learn Current Art") end
  if Mode == "library" then return L("Learn All Library Manuals") end
  return L("Learn All Sect Arts")
end

local function ModeDesc()
  local function L(s) return (NusaCtr_T and NusaCtr_T(s)) or s end
  if Mode == "current" then
    return L("Learn only the art this NPC is currently practicing.")
  end
  if Mode == "library" then
    return L("Learn every manual stored in the library. Already-known ones are skipped.")
  end
  return L("Learn all sect arts and automatically skip unsupported arts or nodes.")
end

function NusaCtr_CloseLearnWindow()
  if View then
    pcall(function() View:RemoveFromParent() end)
    pcall(function() View:Dispose() end)
    View = nil
  end
end

local function Refresh(view)
  Text(Child(view, "title"), (NusaCtr_T and NusaCtr_T("Automatic Learning") or "Automatic Learning"))
  Text(Child(view, "subtitle"), ((NusaCtr_T and NusaCtr_T("Target NPC: ")) or "Target NPC: ") .. NpcName(Target))
  Text(Child(view, "npcName"), NpcName(Target))
  Text(Child(view, "npcStatus"), (NusaCtr_T and NusaCtr_T("Ready to learn") or "Ready to learn"))
  Text(Child(view, "brand"), "NusaCtr")
  ApplyPortrait(view, Target)

  local modes = {
    {id="all", text="All Arts", menu="menuQuick"},
    {id="current", text="Current Art", menu="menuSystem"},
    {id="library", text="Library Manuals", menu="menuBook"},
  }
  for _, mn in ipairs({"menuQuick","menuSystem","menuBook","menuWorld","menuDeveloper"}) do
    Vis(Child(view, mn), false)
  end
  for _, m in ipairs(modes) do
    local btn = Child(view, m.menu)
    Vis(btn, true)
    local lab = m.text
    if m.id == Mode then lab = "▶ " .. lab end
    Text(btn, (NusaCtr_T and NusaCtr_T(lab)) or lab)
  end
  Vis(Child(view, "menuPanel"), true)

  Text(Child(view, "sectionTitle"), ModeTitle())
  Text(Child(view, "description"), ModeDesc())
  Text(Child(view, "feature1"), (NusaCtr_T and NusaCtr_T("Start Learning") or "Start Learning"))
  Text(Child(view, "feature2"), (NusaCtr_T and NusaCtr_T("Back to Mod") or "Back to Mod"))
  Text(Child(view, "btnLanguage"), (NusaCtr_T and NusaCtr_T("Back to Mod") or "Back to Mod"))
  Text(Child(view, "btnClose"), "X")
  Vis(Child(view, "feature1"), true)
  Vis(Child(view, "feature2"), true)
  for i = 3, 8 do Vis(Child(view, "feature" .. i), false) end
end

local function StartLearning()
  if Target == nil then Msg("No target NPC"); return end
  if Mode == "library" then
    if not NusaCtr_LearnAllLibraryEsoterica then Msg("Library learn core not loaded"); return end
    local result = NusaCtr_LearnAllLibraryEsoterica(Target)
    if result and result.ok then
      Msg(tostring(result.summary or "Library learning done"))
    else
      Msg(tostring(result and (result.reason or result.summary) or "Failed"))
    end
    return
  end
  if Mode == "current" then
    if NusaCtr_LearnCurrentGongDirect then
      local ok, err = pcall(function() return NusaCtr_LearnCurrentGongDirect(Target) end)
      Msg(ok and "Current art learning finished" or ("Failed\n" .. tostring(err)))
    else
      Msg("Learn current core not loaded")
    end
    return
  end
 -- all
  if NusaCtr_LearnAllGongsDirect then
    local ok, err = pcall(function() return NusaCtr_LearnAllGongsDirect(Target) end)
    Msg(ok and "All sect arts learning finished" or ("Failed\n" .. tostring(err)))
  elseif NusaCtr_LearnFullGong_Start then
    pcall(NusaCtr_LearnFullGong_Start)
    Msg("Learning started")
  else
    Msg("Learn core not loaded")
  end
end

function NusaCtr_OpenLearnWindow(npc)
  NusaCtr_CloseLearnWindow()
  Target = npc or _G.NusaCtr_LastTarget
  Mode = "all"
  local pkg, root = Pkg(), Root()
  if not pkg or not root then Msg("FairyGUI not ready"); return false end
  local view = nil
  local ok, err = pcall(function() view = pkg.CreateObject(PKG, WIN) end)
  if not ok or not view then Msg("Failed to open Learn window\n" .. tostring(err)); return false end
  View = view
  root:AddChild(view)
  pcall(function()
    view.x = (root.width - view.width) / 2
    view.y = (root.height - view.height) / 2
  end)

  local function bind(name, fn)
    local b = Child(view, name)
    if b then pcall(function() b.onClick:Clear(); b.onClick:Add(fn) end) end
  end
  bind("btnClose", NusaCtr_CloseLearnWindow)
  bind("menuQuick", function() Mode = "all"; Refresh(view) end)
  bind("menuSystem", function() Mode = "current"; Refresh(view) end)
  bind("menuBook", function() Mode = "library"; Refresh(view) end)
  bind("feature1", StartLearning)
  bind("feature2", function()
    NusaCtr_CloseLearnWindow()
    if NusaCtr_OpenMain then pcall(function() NusaCtr_OpenMain(Target) end) end
  end)
  bind("btnLanguage", function()
    NusaCtr_CloseLearnWindow()
    if NusaCtr_OpenMain then pcall(function() NusaCtr_OpenMain(Target) end) end
  end)
  Refresh(view)
  return true
end

_G.NusaCtr_OpenLearnWindow = NusaCtr_OpenLearnWindow
_G.NusaCtr_CloseLearnWindow = NusaCtr_CloseLearnWindow
print("[NusaCtr] Learn window loaded")
