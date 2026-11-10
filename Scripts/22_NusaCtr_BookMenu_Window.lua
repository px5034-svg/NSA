-- NusaCtr Book Menu Window

local PKG, PATH, WIN = "NusaCtr", "UI/NusaCtr", "NusaModCenterWindow"
local View, Target, Category, Page = nil, nil, "all", 1
local PAGE_SIZE = 6

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

local function Commands()
  if NusaCtr_GetNewBookCommands then return NusaCtr_GetNewBookCommands(Category) end
  return {}
end

function NusaCtr_CloseBookMenu()
  if View then
    pcall(function() View:RemoveFromParent() end)
    pcall(function() View:Dispose() end)
    View = nil
  end
end

local function Refresh(view)
  local list = Commands()
  local pages = math.max(1, math.ceil(#list / PAGE_SIZE))
  if Page > pages then Page = pages end
  if Page < 1 then Page = 1 end
  local start = (Page - 1) * PAGE_SIZE

  Text(Child(view, "title"), (NusaCtr_T and NusaCtr_T("Manual Menu") or "Manual Menu"))
  Text(Child(view, "subtitle"), ((NusaCtr_T and NusaCtr_T("Target NPC: ")) or "Target NPC: ") .. NpcName(Target))
  Text(Child(view, "npcName"), NpcName(Target))
  Text(Child(view, "npcStatus"), (NusaCtr_T and NusaCtr_T("Recipient for manuals and cultivation-art commands") or "Recipient for manuals and cultivation-art commands"))
  Text(Child(view, "brand"), "NusaCtr")
  ApplyPortrait(view, Target)

 -- sidebar categories
  local cats = NusaCtr_NewBookCategories or {
    {id="all",text="All"},{id="unlock",text="Unlock Arts"},{id="manual",text="Manual Books"},{id="warp",text="Teleport"}
  }
  local menuNames = {"menuQuick","menuSystem","menuBook","menuWorld","menuDeveloper"}
  for i, mn in ipairs(menuNames) do
    local btn = Child(view, mn)
    local cat = cats[i]
    if cat then
      Vis(btn, true)
      local label = (NusaCtr_T and NusaCtr_T(cat.text)) or cat.text
      if cat.id == Category then label = "▶ " .. label end
      Text(btn, label)
    else
      Vis(btn, false)
    end
  end
  Vis(Child(view, "menuPanel"), true)

  local catTitle = Category
  for _, c in ipairs(cats) do if c.id == Category then catTitle = c.text end end
  Text(Child(view, "sectionTitle"), (NusaCtr_T and NusaCtr_T(catTitle)) or catTitle)
  Text(Child(view, "description"), ((NusaCtr_T and NusaCtr_T("Choose a command | Page ")) or "Choose a command | Page ") .. tostring(Page) .. "/" .. tostring(pages))
  Text(Child(view, "btnLanguage"), (NusaCtr_T and NusaCtr_T("Back to Mod") or "Back to Mod"))
  Text(Child(view, "btnClose"), "X")

  for i = 1, 6 do
    local cmd = list[start + i]
    local btn = Child(view, "feature" .. i)
    if cmd then
      Vis(btn, true)
      do
        local tx = cmd.text or ""
        if NusaCtr_T then
          local prefix = "Receive 20 manuals set "
          if tx:sub(1, #prefix) == prefix then
            tx = NusaCtr_T(prefix) .. tx:sub(#prefix + 1)
          else
            tx = NusaCtr_T(tx)
          end
        end
        Text(btn, tx)
      end
    else
      Vis(btn, false)
      Text(btn, "")
    end
  end
 -- feature7 previous, feature8 next
  Vis(Child(view, "feature7"), true)
  Vis(Child(view, "feature8"), true)
  Text(Child(view, "feature7"), (NusaCtr_T and NusaCtr_T("◀ Previous") or "◀ Previous"))
  Text(Child(view, "feature8"), (NusaCtr_T and NusaCtr_T("Next ▶") or "Next ▶"))
end

function NusaCtr_OpenBookMenu(npc, category)
  NusaCtr_CloseBookMenu()
  Target = npc or _G.NusaCtr_LastTarget
  Category = category or "all"
  Page = 1
  local pkg, root = Pkg(), Root()
  if not pkg or not root then Msg("FairyGUI not ready"); return false end
  local view = nil
  local ok, err = pcall(function() view = pkg.CreateObject(PKG, WIN) end)
  if not ok or not view then Msg("Failed to open Manual Menu\n" .. tostring(err)); return false end
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

  bind("btnClose", NusaCtr_CloseBookMenu)
  bind("btnLanguage", function()
    NusaCtr_CloseBookMenu()
    if NusaCtr_OpenMain then pcall(function() NusaCtr_OpenMain(Target) end) end
  end)

  local cats = {"all", "unlock", "manual", "warp"}
  local menuNames = {"menuQuick","menuSystem","menuBook","menuWorld"}
  for i, mn in ipairs(menuNames) do
    local cat = cats[i]
    bind(mn, function() Category = cat; Page = 1; Refresh(view) end)
  end

  for i = 1, 6 do
    local index = i
    bind("feature" .. i, function()
      local list = Commands()
      local start = (Page - 1) * PAGE_SIZE
      local cmd = list[start + index]
      if not cmd then return end
      if not NusaCtr_RunNewBookCommand then Msg("Core not loaded"); return end
      local ok2, msg = NusaCtr_RunNewBookCommand(Target, cmd)
      Msg(tostring(msg or (ok2 and "OK" or "Failed")))
    end)
  end
  bind("feature7", function()
    if Page > 1 then Page = Page - 1; Refresh(view) end
  end)
  bind("feature8", function()
    local list = Commands()
    local pages = math.max(1, math.ceil(#list / PAGE_SIZE))
    if Page < pages then Page = Page + 1; Refresh(view) end
  end)

  Refresh(view)
  return true
end

_G.NusaCtr_OpenBookMenu = NusaCtr_OpenBookMenu
_G.NusaCtr_CloseBookMenu = NusaCtr_CloseBookMenu
print("[NusaCtr] Book Menu window loaded")
