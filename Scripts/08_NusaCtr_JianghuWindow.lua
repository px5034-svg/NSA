-- NusaCtr Jianghu Window — selection via button.data

local PKG  = "NusaCtr"
local PATH = "UI/NusaCtr"
local WIN  = "JianghuRelationWindow"

local View = nil
local Rows = {}
local Page = 1
local PageSize = 6
local Selected = nil

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
  if obj then pcall(function() obj.visible = (v == true) end) end
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

local function Manager()
  local mgr = nil
  pcall(function() mgr = JianghuMgr end)
  if not mgr then pcall(function() mgr = CS.XiaWorld.JianghuMgr.Instance end) end
  return mgr
end

local function AddSeedKeys(dict, seeds, seen)
  if dict == nil then return end
  pcall(function()
    local e = dict.Keys:GetEnumerator()
    while e:MoveNext() do
      local k = e.Current
      local s = tostring(k)
      if not seen[s] then
        seen[s] = true
        seeds[#seeds + 1] = k
      end
    end
    pcall(function() e:Dispose() end)
  end)
end

local function ResolveDef(mgr, school, seed)
  local def = nil
  pcall(function() def = mgr:GetJHNpcDataByRandomSeed(seed) end)
  if def == nil then pcall(function() def = mgr:GetJHNpcDataBySeed(seed) end) end
  if def == nil and school ~= nil then
    pcall(function()
      local template = school.JianghuNpcs[seed]
      if template ~= nil then def = mgr:GetJianghuNpcDef(template) end
    end)
  end
  return def
end

local function ResolveName(mgr, def, seed)
  local name = tostring(seed)
  if def ~= nil then
    pcall(function()
      local n = def.Name or def.NpcName or def.DisplayName
      if n and tostring(n) ~= "" then name = tostring(n) end
    end)
  end
  pcall(function()
    local gameName = mgr:GetJHNpcName(seed, true, false)
    if gameName ~= nil and tostring(gameName) ~= "" then name = tostring(gameName) end
  end)
  return name
end

local function ResolveStatus(school, seed)
  local status = "Alive"
  pcall(function()
    if school and school:IsJianghuNpcDie(seed) then status = "Dead"
    elseif school and school:IsJianghuNpcLeave(seed) then status = "Left" end
  end)
  return status
end

local function ReadState(row)
  if row and row.seed and NusaCtr_ReadHeartState then
    return NusaCtr_ReadHeartState(row.seed)
  end
  return { favor = "-", vigilance = "-", heart = "No" }
end

local function PortraitUrl(row)
  local value = ""
  if not row then return value end
  pcall(function()
    local mgr = Manager()
    local npc = mgr and mgr:GetNpc(row.seed) or nil
    if npc ~= nil and npc.Race ~= nil then
      value = tostring(npc.Race.TexPath or npc.Race.Rolepaint or "")
    end
  end)
  if value == "" and row.def ~= nil then
    pcall(function()
      local npcMgr = NpcMgr or CS.XiaWorld.NpcMgr.Instance
      local race = npcMgr and npcMgr:GetRaceDef(tostring(row.def.Race or "")) or nil
      if race ~= nil then
        value = tostring(race.TexPath or race.Rolepaint or "")
      end
    end)
  end
  return value
end

-- Known NPCs only (met / known)
local function BuildRows()
  local rows, seeds, seen = {}, {}, {}
  local ok = pcall(function()
    local school = CS.XiaWorld.SchoolGlobleMgr.Instance
    local mgr = Manager()
    AddSeedKeys(school and school.JianghuNpcs or nil, seeds, seen)
    AddSeedKeys(mgr and mgr.KnowNpcData or nil, seeds, seen)
    table.sort(seeds, function(a, b)
      return (tonumber(a) or 0) < (tonumber(b) or 0)
    end)
    for _, seed in ipairs(seeds) do
      local know = nil
      pcall(function() know = mgr:GetKnowNpcData(seed) end)
      if know ~= nil then
        local def = ResolveDef(mgr, school, seed)
        rows[#rows + 1] = {
          seed = seed,
          def = def,
          name = ResolveName(mgr, def, seed),
          status = ResolveStatus(school, seed),
        }
      end
    end
  end)
  if not ok then return {} end
  return rows
end

local function RefreshDetail()
  if not View then return end
  local row = Selected
  local state = ReadState(row)
  Text(Child(View, "npcName"), row and row.name or "Select NPC")
  if row then
    Text(Child(View, "npcStatus"),
      "Status: " .. tostring(row.status) ..
      "\nFavor: " .. tostring(state.favor) ..
      "\nVigilance: " .. tostring(state.vigilance) ..
      "\nHeart: " .. tostring(state.heart))
  else
    Text(Child(View, "npcStatus"), "Status: -\nFavor: -\nVigilance: -\nHeart: -")
  end
  Text(Child(View, "hint"), (NusaCtr_T and NusaCtr_T("Uses the game relationship system") or "Uses the game relationship system"))
  local portrait = Child(View, "portrait")
  local url = PortraitUrl(row)
  if portrait then
    pcall(function() portrait.url = url end)
    pcall(function() portrait.icon = url end)
    Visible(portrait, url ~= "")
  end
end

local function Refresh(rebuild)
  if not View then return end
  Text(Child(View, "title"), (NusaCtr_T and NusaCtr_T("Other Sect NPCs") or "Other Sect NPCs"))
  Text(Child(View, "subtitle"), (NusaCtr_T and NusaCtr_T("Select a character to open their heart or increase favor.") or "Select a character to open their heart or increase favor."))
  Text(Child(View, "btnOpenHeart"), (NusaCtr_T and NusaCtr_T("Open Heart") or "Open Heart"))
  Text(Child(View, "btnMaxFavor"), (NusaCtr_T and NusaCtr_T("Open Heart + Max") or "Open Heart + Max"))
  Text(Child(View, "btnRefresh"), (NusaCtr_T and NusaCtr_T("Refresh") or "Refresh"))
  Text(Child(View, "btnPrev"), "◀")
  Text(Child(View, "btnNext"), "▶")
  Text(Child(View, "btnClose"), "X")

  if rebuild == true then Rows = BuildRows() end
  local maxPage = math.max(1, math.ceil(#Rows / PageSize))
  Page = math.max(1, math.min(Page, maxPage))
  Text(Child(View, "txtPage"), tostring(Page) .. "/" .. tostring(maxPage))

 -- 1-based first index
  local first = (Page - 1) * PageSize + 1
  for i = 1, PageSize do
    local button = Child(View, "npcBtn" .. tostring(i))
    local row = Rows[first + i - 1]
    if button ~= nil then
      if row ~= nil then
        local state = ReadState(row)
        local mark = (Selected == row) and "▶ " or ""
        local short = row.name
        if #short > 30 then short = string.sub(short, 1, 28) .. ".." end
        Text(button, mark .. short .. " | Heart: " .. state.heart)
 -- Store row on button.data for click handler
        pcall(function() button.data = row end)
        Visible(button, true)
      else
        Text(button, "")
        pcall(function() button.data = nil end)
        Visible(button, false)
      end
    end
  end
  RefreshDetail()
end

function NusaCtr_CloseJianghuWindow()
  if View then
    pcall(function() View:RemoveFromParent() end)
    pcall(function() View:Dispose() end)
    View = nil
  end
  Selected = nil
end

function NusaCtr_OpenJianghuWindow()
  NusaCtr_CloseJianghuWindow()
  local pkg, root = Pkg(), Root()
  if not pkg or not root then Msg("UI missing"); return false end

  local view = nil
  local errors = {}
  local function try_create(label, creator)
    if view ~= nil then return end
    local ok, value = pcall(creator)
    if ok and value ~= nil then view = value
    else errors[#errors + 1] = label .. ": " .. tostring(value) end
  end
  try_create("CreateObject", function() return pkg.CreateObject(PKG, WIN) end)
  try_create("CreateObject.xml", function() return pkg.CreateObject(PKG, WIN .. ".xml") end)
  if view == nil then
    Msg("Failed open window\n" .. table.concat(errors, "\n"))
    return false
  end

  View = view
  Page = 1
  Selected = nil
  pcall(function()
    root:AddChild(view)
    view.x = (root.width - view.width) / 2
    view.y = (root.height - view.height) / 2
  end)

 -- Bind NPC row clicks ONCE (read button.data)
  for i = 1, PageSize do
    local button = Child(view, "npcBtn" .. tostring(i))
    if button ~= nil then
      pcall(function()
        button.onClick:Clear()
        button.onClick:Add(function()
          if button.data ~= nil then
            Selected = button.data
            Refresh(false)
          end
        end)
      end)
    end
  end

  local function bind(name, fn)
    local b = Child(view, name)
    if b then
      pcall(function()
        b.onClick:Clear()
        b.onClick:Add(fn)
      end)
    end
  end

  bind("btnClose", function()
    NusaCtr_CloseJianghuWindow()
    if NusaCtr_OpenMain then pcall(function() NusaCtr_OpenMain(_G.NusaCtr_LastTarget) end) end
  end)
  bind("btnRefresh", function() Refresh(true) end)
  bind("btnPrev", function()
    Page = Page - 1
    Refresh(false)
  end)
  bind("btnNext", function()
    Page = Page + 1
    Refresh(false)
  end)
  bind("btnOpenHeart", function()
    if Selected == nil then
      Msg("Select an NPC first")
      return
    end
    if NusaCtr_OpenHeartBySeed and NusaCtr_OpenHeartBySeed(Selected.seed, false) then
      Refresh(true)
    end
  end)
  bind("btnMaxFavor", function()
    if Selected == nil then
      Msg("Select an NPC first")
      return
    end
    if NusaCtr_OpenHeartBySeed and NusaCtr_OpenHeartBySeed(Selected.seed, true) then
      Refresh(true)
    end
  end)

  Refresh(true)
  pcall(function() view:BringToFront() end)
  return true
end

_G.NusaCtr_OpenJianghuWindow = NusaCtr_OpenJianghuWindow
_G.NusaCtr_CloseJianghuWindow = NusaCtr_CloseJianghuWindow
print("[NusaCtr] Jianghu Window loaded")
