-- NusaCtr Item Tools
-- Select item on ground, then use tools from this window

local PKG  = "NusaCtr"
local PATH = "UI/NusaCtr"
local WIN  = "NusaModCenterWindow"

local View = nil
NusaCtr_ItemToolsState = NusaCtr_ItemToolsState or {
  SelectedItem = nil,
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

local function SetVisible(obj, value)
  if not obj then return end
  pcall(function() obj.visible = value == true end)
  pcall(function() obj.touchable = value == true end)
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

local function ItemName(item)
  local name = "Item"
  pcall(function() name = tostring(item:GetName()) end)
  return name
end

local function ItemCount(item)
  if item == nil then return 0 end
  local count = nil
  pcall(function() count = tonumber(item.Count) end)
  if count == nil or count < 1 then
    pcall(function() count = tonumber(item.FreeCount) end)
  end
  return count or 0
end

-- Item stack / refine / energy / tribulation actions
local function RunItem(item, action)
  if item == nil then return false, "Select an item on the ground first" end

  if action == "double" then
    local count = ItemCount(item)
    if count < 1 then return false, "Could not read item count" end
    local ok, err = pcall(function() item:ChangeCount(count * 2) end)
    if not ok then
      ok, err = pcall(function() item:ChangeCount(count * 2, false) end)
    end
    if not ok then
      return false, "Failed to double stack\n" .. tostring(err)
    end
    return true, "Doubled stack ×2\n" .. ItemName(item) .. "\nNow: " .. tostring(ItemCount(item))
  end

  if action == "youcui" then
    if item.SoulCrystalYouPowerUp == nil then
      return false, "This item does not support Demon Refining"
    end
    if item.Rate ~= nil and tonumber(item.Rate) >= 12 then
      return false, "Item is already at max tier"
    end
    item:SoulCrystalYouPowerUp(100)
    return true, "Demon Refining done\n" .. ItemName(item)
  end

  if action == "lingcui" then
    if item.SoulCrystalLingPowerUp == nil then
      return false, "This item does not support Spirit Refining"
    end
    item:SoulCrystalLingPowerUp(100)
    return true, "Spirit Refining done\n" .. ItemName(item)
  end

  if action == "full_ling" then
    if item.AddLing == nil or item.MaxLing == nil or item.LingV == nil then
      return false, "This item has no spiritual energy capacity"
    end
    local need = math.max(0, (tonumber(item.MaxLing) or 0) - (tonumber(item.LingV) or 0))
    item:AddLing(need)
    return true, "Spiritual energy filled\n" .. ItemName(item)
  end

  if action == "tribulation" then
    if item.Fabao == nil or item.Fabao.AddGodCount == nil then
      return false, "Only works on artifacts (Fabao)"
    end
    for _ = 1, 36 do item.Fabao:AddGodCount(1) end
    return true, "36 Artifact Tribulations applied\n" .. ItemName(item)
  end

  return false, "Unknown action"
end

local function SelectedLabel()
  local item = NusaCtr_ItemToolsState.SelectedItem
  if item == nil then return "No item selected — pick one on the ground" end
  local ok = true
  pcall(function()
 -- soft check still exists
    if item.ThingType and g_emThingType and item.ThingType ~= g_emThingType.Item then
      ok = false
    end
  end)
  if not ok then return "No item selected — pick one on the ground" end
  return ItemName(item) .. "  x" .. tostring(ItemCount(item))
end

local ACTIONS = {
  { "Double Item Stack ×2", "double" },
  { "Demon Refining / Raise Tier", "youcui" },
  { "Spirit Refining", "lingcui" },
  { "Fill Spiritual Energy", "full_ling" },
  { "36 Artifact Tribulations", "tribulation" },
}

local function Refresh(view)
  if not view then return end
  Text(Child(view, "title"), (NusaCtr_T and NusaCtr_T("Item Tools") or "Item Tools"))
  Text(Child(view, "subtitle"), (NusaCtr_T and NusaCtr_T("Modify the selected ground item") or "Modify the selected ground item"))
  Text(Child(view, "npcName"), (NusaCtr_T and NusaCtr_T("Selected Item") or "Selected Item"))
  Text(Child(view, "npcStatus"), SelectedLabel())
  Text(Child(view, "brand"), "NusaCtr")
  SetVisible(Child(view, "npcPortrait"), false)

  SetVisible(Child(view, "menuPanel"), false)
  for _, mn in ipairs({"menuQuick", "menuSystem", "menuBook", "menuWorld", "menuDeveloper"}) do
    SetVisible(Child(view, mn), false)
  end

  Text(Child(view, "sectionTitle"), (NusaCtr_T and NusaCtr_T("Item Tools") or "Item Tools"))
  Text(Child(view, "description"), (NusaCtr_T and NusaCtr_T("Select an item on the ground, then tap a tool.") or "Select an item on the ground, then tap a tool."))
  Text(Child(view, "btnLanguage"), (NusaCtr_T and NusaCtr_T("Back to Mod") or "Back to Mod"))
  Text(Child(view, "btnClose"), "X")
  Text(Child(view, "hint"), "")

  for i = 1, 8 do
    local btn = Child(view, "feature" .. i)
    local data = ACTIONS[i]
    if data then
      SetVisible(btn, true)
      Text(btn, (NusaCtr_T and NusaCtr_T(data[1])) or data[1])
    else
      SetVisible(btn, false)
      Text(btn, "")
    end
  end
end

local function DoAction(view, action)
  local item = NusaCtr_ItemToolsState.SelectedItem
  local ok, result, message = pcall(function()
    local success, reason = RunItem(item, action)
    return success, reason
  end)
  if not ok then
    Msg("Action failed\n" .. tostring(result))
  else
    Msg(tostring(message))
  end
  Refresh(view)
end

function NusaCtr_CloseItemTools()
  if View then
    pcall(function() View:RemoveFromParent() end)
    pcall(function() View:Dispose() end)
    View = nil
  end
end

function NusaCtr_OpenItemTools(item)
  if item ~= nil then
    NusaCtr_ItemToolsState.SelectedItem = item
  end
  NusaCtr_CloseItemTools()

  local pkg = Pkg()
  local root = Root()
  if not pkg or not root then
    Msg("FairyGUI not ready")
    return false
  end

  local view = nil
  local ok, err = pcall(function()
    view = pkg.CreateObject(PKG, WIN)
  end)
  if not ok or not view then
    Msg("Failed to open Item Tools\n" .. tostring(err))
    return false
  end

  View = view
  root:AddChild(view)
  pcall(function()
    view.x = (root.width - view.width) / 2
    view.y = (root.height - view.height) / 2
  end)

  local close = Child(view, "btnClose")
  if close then
    pcall(function()
      close.onClick:Clear()
      close.onClick:Add(NusaCtr_CloseItemTools)
    end)
  end

  for i = 1, 8 do
    local index = i
    local btn = Child(view, "feature" .. i)
    if btn then
      pcall(function()
        btn.onClick:Clear()
        btn.onClick:Add(function()
          local data = ACTIONS[index]
          if data then DoAction(view, data[2]) end
        end)
      end)
    end
  end

  local back = Child(view, "btnLanguage")
  if back then
    pcall(function()
      back.onClick:Clear()
      back.onClick:Add(function()
        NusaCtr_CloseItemTools()
        if NusaCtr_OpenMain then
          pcall(function() NusaCtr_OpenMain(_G.NusaCtr_LastTarget) end)
        end
      end)
    end)
  end

  Refresh(view)
  return true
end

_G.NusaCtr_OpenItemTools = NusaCtr_OpenItemTools
_G.NusaCtr_CloseItemTools = NusaCtr_CloseItemTools

-- Track selected item + optional quick button (English)
local Mod = GameMain:NewMod("NusaCtrItemTools")

function Mod:OnEnter()
  local event = GameMain:GetMod("_Event")
  if event == nil then return end
  event:RegisterEvent(g_emEvent.SelectItem, function(_, item)
    NusaCtr_ItemToolsState.SelectedItem = item
    if item == nil then return end
    local is_item = false
    pcall(function() is_item = item.ThingType == g_emThingType.Item end)
    if not is_item then return end
    pcall(function() item:RemoveBtnData("Item Tools") end)
    pcall(function()
      item:AddBtnData(
        "Item Tools",
        "res/Sprs/ui/icon_hand",
        "NusaCtr_OpenItemTools(bind)",
        "Double, refine, fill energy, artifact tribulations",
        nil
      )
    end)
  end, "NusaCtr_ItemTools_SelectItem")
  print("[NusaCtr] Item Tools SelectItem registered")
end

print("[NusaCtr] Item Tools loaded")
