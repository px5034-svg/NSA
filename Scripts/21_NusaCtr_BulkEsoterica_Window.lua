-- NusaCtr Bulk Esoterica Window — store map manuals into library

local PKG, PATH, WIN = "NusaCtr", "UI/NusaCtr", "NusaModCenterWindow"
local View, Target = nil, nil

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

function NusaCtr_CloseBulkEsoterica()
  if View then
    pcall(function() View:RemoveFromParent() end)
    pcall(function() View:Dispose() end)
    View = nil
  end
end

local function Refresh(view)
  local entries = nil
  if NusaCtr_ScanMapEsoterica then
    entries = NusaCtr_ScanMapEsoterica()
  end
  local count = entries and #entries or 0

  Text(Child(view, "title"), (NusaCtr_T and NusaCtr_T("Store Manuals in Library") or "Store Manuals in Library"))
  Text(Child(view, "subtitle"), ((NusaCtr_T and NusaCtr_T("Operator: ")) or "Operator: ") .. NpcName(Target))
  Text(Child(view, "npcName"), NpcName(Target))
  Text(Child(view, "npcStatus"), (NusaCtr_T and NusaCtr_T("Register manuals from the map into the library") or "Register manuals from the map into the library"))
  Text(Child(view, "brand"), "NusaCtr")
  ApplyPortrait(view, Target)
  Vis(Child(view, "menuPanel"), false)
  for _, mn in ipairs({"menuQuick","menuSystem","menuBook","menuWorld","menuDeveloper"}) do
    Vis(Child(view, mn), false)
  end
  Text(Child(view, "sectionTitle"), (NusaCtr_T and NusaCtr_T("Manuals on the Map") or "Manuals on the Map"))
  local function L(s) return (NusaCtr_T and NusaCtr_T(s)) or s end
  Text(Child(view, "description"),
    L("Manuals found on map: ") .. tostring(count) ..
    L("\nEach manual is added to the library, then removed from the ground."))
  Text(Child(view, "feature1"), L("Store all ") .. tostring(count) .. L(" manuals"))
  Text(Child(view, "feature2"), (NusaCtr_T and NusaCtr_T("Refresh") or "Refresh"))
  Text(Child(view, "feature3"), (NusaCtr_T and NusaCtr_T("Back to Mod") or "Back to Mod"))
  Text(Child(view, "btnLanguage"), (NusaCtr_T and NusaCtr_T("Back to Mod") or "Back to Mod"))
  Text(Child(view, "btnClose"), "X")
  for i = 1, 3 do Vis(Child(view, "feature" .. i), true) end
  for i = 4, 8 do Vis(Child(view, "feature" .. i), false) end
end

function NusaCtr_OpenBulkEsoterica(npc)
  NusaCtr_CloseBulkEsoterica()
  Target = npc or _G.NusaCtr_LastTarget
  local pkg, root = Pkg(), Root()
  if not pkg or not root then Msg("FairyGUI not ready"); return false end
  local view = nil
  local ok, err = pcall(function() view = pkg.CreateObject(PKG, WIN) end)
  if not ok or not view then Msg("Failed to open window\n" .. tostring(err)); return false end
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
  bind("btnClose", NusaCtr_CloseBulkEsoterica)
  bind("feature1", function()
    if not NusaCtr_CollectAllMapEsoterica then Msg("Core not loaded"); return end
    local result = NusaCtr_CollectAllMapEsoterica(Target)
    if result and result.ok then
      Msg("Stored manuals\n" .. tostring(result.summary or ""))
    else
      Msg(tostring(result and (result.reason or result.summary) or "Failed"))
    end
    Refresh(view)
  end)
  bind("feature2", function() Refresh(view) end)
  bind("feature3", function()
    NusaCtr_CloseBulkEsoterica()
    if NusaCtr_OpenMain then pcall(function() NusaCtr_OpenMain(Target) end) end
  end)
  bind("btnLanguage", function()
    NusaCtr_CloseBulkEsoterica()
    if NusaCtr_OpenMain then pcall(function() NusaCtr_OpenMain(Target) end) end
  end)
  Refresh(view)
  return true
end

_G.NusaCtr_OpenBulkEsoterica = NusaCtr_OpenBulkEsoterica
_G.NusaCtr_CloseBulkEsoterica = NusaCtr_CloseBulkEsoterica
print("[NusaCtr] Bulk Esoterica window loaded")
