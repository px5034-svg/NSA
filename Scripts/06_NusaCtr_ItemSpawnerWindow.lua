-- NusaCtr Item Spawner Window
-- UI only: NusaItemSpawnerWindow (standalone)

local PKG  = "NusaCtr"
local PATH = "UI/NusaCtr"
local WIN  = "NusaItemSpawnerWindow"

local View = nil
local Items = {}
local Category = "all"
local Search = ""
local Page = 1
local PageSize = 12
local Amount = 1
local Selected = nil

local CATS = {
  { key = "all",       label = "All" },
  { key = "Food",      label = "Food" },
  { key = "Pills",     label = "Pills" },
  { key = "Materials", label = "Materials" },
  { key = "Weapons",   label = "Weapons" },
  { key = "Books",     label = "Books" },
  { key = "Other",     label = "Other" },
  { key = "Talisman",  label = "Talisman" },
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

local function RefreshDetail()
  if not View then return end
  local sid = Selected and Selected.id or nil
  local is_fu = sid and NusaCtr_IsTalismanSpell and NusaCtr_IsTalismanSpell(sid)
  local def = (sid and not is_fu) and NusaCtr_GetSpawnerItemDef(sid) or nil
  local name = Selected and NusaCtr_SpawnerDisplayName(sid, def) or ((NusaCtr_T and NusaCtr_T("Select item")) or "Select item")
  if Selected and NusaCtr_T then name = NusaCtr_T(name) end
  local desc
  if not Selected then
    desc = (NusaCtr_T and NusaCtr_T("Tap an item for details")) or "Tap an item for details"
  elseif is_fu then
    desc = (NusaCtr_T and NusaCtr_T("Drawn talisman (DropSpell · 95% quality)")) or "Drawn talisman (DropSpell · 95% quality)"
  else
    desc = ((NusaCtr_T and NusaCtr_T("Category: ")) or "Category: ") .. tostring(Selected.cat or "Other")
    pcall(function()
      if def and def.Desc then
        local d = tostring(def.Desc)
        if d ~= "" and not d:find("lost", 1, true) and not d:find("Lost", 1, true) and not d:find("SYSLOST", 1, true) then
          desc = d
        end
      end
    end)
  end
  Text(Child(View, "detailName"), name)
  Text(Child(View, "detailDesc"), desc)
  Text(Child(View, "amountLabel"), ((NusaCtr_T and NusaCtr_T("Amount: ")) or "Amount: ") .. tostring(Amount))
  local loader = Child(View, "detailIcon")
  if loader then
    local icon = ""
    if sid and NusaCtr_SpawnerIconForId then
      icon = NusaCtr_SpawnerIconForId(sid) or ""
    elseif def then
      icon = NusaCtr_SpawnerIconUrl(def) or ""
    end
    pcall(function() loader.url = icon end)
  end
end

local function Refresh(rebuild)
  if not View then return end
  Text(Child(View, "title"), (NusaCtr_T and NusaCtr_T("Spawn Items") or "Spawn Items"))
  Text(Child(View, "subtitle"), (NusaCtr_T and NusaCtr_T("Choose a category and an item") or "Choose a category and an item"))
  Text(Child(View, "btnClose"), "X")
  Text(Child(View, "btnRefresh"), (NusaCtr_T and NusaCtr_T("Refresh") or "Refresh"))
  Text(Child(View, "btnSpawn"), (NusaCtr_T and NusaCtr_T("Spawn") or "Spawn"))
  Text(Child(View, "btnPrev"), "◀")
  Text(Child(View, "btnNext"), "▶")
  Text(Child(View, "amount1"), "1")
  Text(Child(View, "amount10"), "10")
  Text(Child(View, "amount100"), "99")
  Text(Child(View, "amount999"), "999")

  for i, c in ipairs(CATS) do
    local btn = Child(View, "cat" .. i)
    if btn then
      local lab = c.label
      if c.key == Category then lab = "▶ " .. lab end
      Text(btn, (NusaCtr_T and NusaCtr_T(lab)) or lab)
    end
  end

 -- rebuild:
 -- true = soft refresh list (use cache; only build if empty)
 -- "force" = invalidate + full rebuild (Refresh button only)
  if rebuild == true or rebuild == "force" then
    if rebuild == "force" then
      if NusaCtr_InvalidateSpawnerItems then pcall(NusaCtr_InvalidateSpawnerItems) end
      if NusaCtr_RebuildSpawnerItems then pcall(function() NusaCtr_RebuildSpawnerItems(true) end) end
    else
      if NusaCtr_RebuildSpawnerItems then pcall(function() NusaCtr_RebuildSpawnerItems(false) end) end
    end
    if NusaCtr_GetSpawnerItems then
      local ok, value = pcall(function()
        return NusaCtr_GetSpawnerItems(Category, Search)
      end)
      Items = (ok and type(value) == "table") and value or {}
    else
      Items = {}
    end
  end

  local maxPage = math.max(1, math.ceil(#Items / PageSize))
  Page = math.max(1, math.min(Page, maxPage))
  Text(Child(View, "txtPage"), Page .. "/" .. maxPage)
  Text(Child(View, "status"), tostring(#Items) .. " items | " .. tostring(Category))

  local first = (Page - 1) * PageSize
  for i = 1, PageSize do
    local btn = Child(View, "item" .. i)
    local data = Items[first + i]
    if btn then
      if data then
        Visible(btn, true)
        pcall(function() btn.touchable = true end)
        pcall(function() btn.alpha = 1 end)
        local label = data.name
        do
          local def = (NusaCtr_IsTalismanSpell and NusaCtr_IsTalismanSpell(data.id)) and nil or (NusaCtr_GetSpawnerItemDef and NusaCtr_GetSpawnerItemDef(data.id) or nil)
          label = (NusaCtr_SpawnerDisplayName and NusaCtr_SpawnerDisplayName(data.id, def)) or label or data.id
          if NusaCtr_T then label = NusaCtr_T(label) end
        end
        Text(btn, label)
        pcall(function()
          local ic = btn:GetChild("icon")
          if ic then
            local url = data.icon or ""
            if url == "" and NusaCtr_SpawnerIconForId then
              url = NusaCtr_SpawnerIconForId(data.id) or ""
            end
            if url == "" and NusaCtr_GetSpawnerItemDef and NusaCtr_SpawnerIconUrl then
              url = NusaCtr_SpawnerIconUrl(NusaCtr_GetSpawnerItemDef(data.id)) or ""
            end
            ic.url = url
          end
        end)
        pcall(function()
          btn.onClick:Clear()
          local d = data
          btn.onClick:Add(function()
            Selected = d
            RefreshDetail()
          end)
        end)
      else
        Text(btn, "")
        pcall(function()
          local ic = btn:GetChild("icon")
          if ic then ic.url = "" end
        end)
        Visible(btn, false)
        pcall(function() btn.touchable = false end)
        pcall(function() btn.alpha = 0 end)
      end
    end
  end
  RefreshDetail()
end

function NusaCtr_CloseItemSpawner()
  if View then
    pcall(function() View:RemoveFromParent() end)
    pcall(function() View:Dispose() end)
    View = nil
  end
  Selected = nil
end

function NusaCtr_OpenItemSpawner()
  NusaCtr_CloseItemSpawner()
  local pkg, root = Pkg(), Root()
  if not pkg or not root then Msg("UI missing"); return false end
  local view = nil
  pcall(function() view = pkg.CreateObject(PKG, WIN) end)
  if not view then Msg("Failed open NusaItemSpawnerWindow"); return false end
  View = view
  Category, Search, Page, Amount, Selected = "all", "", 1, 1, nil
  pcall(function()
    root:AddChild(view)
    view.x = (root.width - view.width) / 2
    view.y = (root.height - view.height) / 2
  end)

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
    NusaCtr_CloseItemSpawner()
    if NusaCtr_OpenMain then pcall(function() NusaCtr_OpenMain(_G.NusaCtr_LastTarget) end) end
  end)
  bind("btnRefresh", function() Refresh("force") end)
  bind("btnClearSearch", function()
    Search = ""
    local inp = Child(view, "inputSearch")
    if inp then pcall(function() inp.text = "" end) end
    Page = 1
    Refresh(true)
  end)
  bind("btnPrev", function()
    if Page > 1 then Page = Page - 1; Refresh(false) end
  end)
  bind("btnNext", function()
    local m = math.max(1, math.ceil(#Items / PageSize))
    if Page < m then Page = Page + 1; Refresh(false) end
  end)
  bind("btnSpawn", function()
    if not Selected then Msg("Select an item first"); return end
    local ok, err = NusaCtr_SpawnItemDirect(Selected.id, Amount)
    if ok then Msg("Spawned x" .. tostring(Amount))
    else Msg("Spawn failed: " .. tostring(err)) end
  end)
  bind("amount1", function() Amount = 1; RefreshDetail() end)
  bind("amount10", function() Amount = 10; RefreshDetail() end)
  bind("amount100", function() Amount = 99; RefreshDetail() end)
  bind("amount999", function() Amount = 999; RefreshDetail() end)

  for i, c in ipairs(CATS) do
    local key = c.key
    bind("cat" .. i, function()
      Category = key
      Page = 1
      Refresh(true)
    end)
  end

  local inp = Child(view, "inputSearch")
  if inp then
    pcall(function()
      if inp.onChanged then
        inp.onChanged:Clear()
        inp.onChanged:Add(function()
          local v = ""
          pcall(function() v = tostring(inp.text or "") end)
          Search = v
          Page = 1
          Refresh(true)
        end)
      end
    end)
  end

  Refresh(true)
  return true
end

_G.NusaCtr_OpenItemSpawner = NusaCtr_OpenItemSpawner
_G.NusaCtr_CloseItemSpawner = NusaCtr_CloseItemSpawner
print("[NusaCtr] ItemSpawner Window loaded")
