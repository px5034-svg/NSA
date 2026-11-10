-- NusaCtr MainWindow (standalone)
-- UI: NusaModCenterWindow in package NusaCtr
-- Child names must match Fairy Project exactly.

local PKG  = "NusaCtr"
local PATH = "UI/NusaCtr"
local WIN  = "NusaModCenterWindow"

local View = nil
local TargetNpc = nil
local Section = "quick"
local AdvancedTool = nil
local AdvancedPage = 1
local AdvancedStatus = ""
local NpcPage = 1
local WorldPage = 1
local QuickPage = 1
local TemperatureMode = false
-- Edit NPC sidebar category (uses the existing NusaCtr sidebar buttons).
local AdvancedCategory = "quick"
-- Keep last selected NPC so portrait survives feature open/close
if _G.NusaCtr_LastTarget == nil then _G.NusaCtr_LastTarget = nil end

---------------------------------------------------------------- helpers
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

local function RealNpc(npc)
  if not npc then return nil end
  local r = npc
  pcall(function() if npc.npcObj then r = npc.npcObj end end)
  return r
end

local function NpcName(npc)
  local r = RealNpc(npc)
  if not r then return "—" end
  local n = "NPC"
  pcall(function() n = tostring(r.Name or r:GetName() or n) end)
  return n
end

local function NpcStatus(npc)
  local r = RealNpc(npc)
  if not r then
    return (NusaCtr_T and NusaCtr_T("Select NPC")) or "Select NPC"
  end
  local sect, stage = "-", "-"
  pcall(function()
    if r.School then sect = tostring(r.School.Name or r.School) end
  end)
  pcall(function()
    if r.Practice then stage = tostring(r.Practice.GongStage or "-") end
  end)
  local a = (NusaCtr_T and NusaCtr_T("Sect: ")) or "Sect: "
  local b = (NusaCtr_T and NusaCtr_T(" | Stage: ")) or " | Stage: "
  return a .. sect .. b .. stage
end

local function NpcIcon(npc)
  local r = RealNpc(npc)
  if not r then return "" end
  local icon = ""
  pcall(function()
    if r.Race then
      icon = tostring(r.Race.TexPath or r.Race.Rolepaint or r.Race.Head or r.Race.Body or "")
    end
  end)
  if icon == "" or icon == "nil" then
    pcall(function() icon = tostring(r.TexPath or r.HeadIcon or r.Icon or "") end)
  end
  if icon == "nil" then icon = "" end
  return icon or ""
end

---------------------------------------------------------------- sections
-- Only labels that map to feature1..feature8 on UI
local Labels = {
  npc = {
    title = "NPC Tools",
    features = {
      "Open Heart + Max Favor",
      "Sect Favor",
      "Jianghu Favor",
      "Open Mini Universe",
      "School Capacity",
      "Body Cultivation Tools",
      "Divine Cultivation Stats",
      "Edit NPC",
      "Instant Pet Growth",
      "Full Pet Awakening",
      "Revive NPC",
      "Secret Treasure",
      "Delay Heavenly Tribulation",
      "Boost 5 Stats",
      "Breakthrough",
      "Toggle Invincible",
      "Copy Attributes",
      "Paste Attributes",
    },
  },
  quick = {
    title = "Function Menu",
    features = {
      "Spawn Items",
      "Open Heart + Max Favor",
      "Open Mini Universe",
      "School Capacity",
      "Item Tools",
      "Construction Tools",
      "Time / Season / Weather",
      "Boss Summon",
      "Damage Numbers",
      "Open Taiyi Boxes",
      "Open Other Boxes",
      "Fill All Ling",
      "Clear Stuck Jobs",
      "Cancel Blueprints",
      "FPS Tools",
    },
  },
  book = {
    title = "Manuals",
    features = {
      "Store Manuals in Library",
      "Learn Cultivation Arts",
      "Manual Book Tools",
    },
  },
  world = {
    title = "World",
    features = {
      "Map Tools",
      "Agency Tools",
      "City Event Helper",
      "Merchant Tools",
      "Item Tools",
      "Construction Tools",
      "Time / Season / Weather",
      "Temperature",
      "Boss Summon",
      "Sect Alignment",
      "Map Cleanup",
      "Auto Loot",
    },
  },
  developer = {
    title = "Developer",
    features = {
      "Facebook",
      "GitHub",
      "YouTube",
    },
  },
}

local TabOrder = { "quick", "npc", "book", "world", "developer" }
local TabLabels = {
  quick = "Functions", npc = "NPC", book = "Manuals",
  world = "World", developer = "Developer"
}
-- UI child names from Fairy Project
local TabChild = {
  "menuQuick", "menuSystem", "menuBook", "menuWorld", "menuDeveloper"
}

-- Developer social links (edit these to your own pages)
NusaCtr_SocialLinks = NusaCtr_SocialLinks or {
  Facebook = "https://facebook.com/",
  GitHub   = "https://github.com/",
  YouTube  = "https://youtube.com/",
}

local function OpenSocial(key)
  local url = NusaCtr_SocialLinks and NusaCtr_SocialLinks[key]
  if not url or url == "" then
    Msg(tostring(key) .. " link is not set yet")
    return
  end
  local opened = false
  pcall(function()
    if CS and CS.UnityEngine and CS.UnityEngine.Application and CS.UnityEngine.Application.OpenURL then
      CS.UnityEngine.Application.OpenURL(url)
      opened = true
    end
  end)
  if not opened then
    pcall(function()
      if Application and Application.OpenURL then Application.OpenURL(url); opened = true end
    end)
  end
  if opened then
    Msg(tostring(key) .. "\n" .. tostring(url))
  else
    Msg(tostring(key) .. "\n" .. tostring(url) .. "\n(Could not open browser — copy the URL)")
  end
end

---------------------------------------------------------------- advanced NPC tools
local function AdvancedActions()
  if not AdvancedTool or not NusaCtr_GetAdvancedActions then return {} end
  local ok, value = pcall(function() return NusaCtr_GetAdvancedActions(AdvancedTool) end)
  return ok and type(value) == "table" and value or {}
end

local function CloseAdvancedTool()
  AdvancedTool = nil
  AdvancedPage = 1
  AdvancedStatus = ""
  AdvancedCategory = "quick"
  Section = "npc"
  _G.NusaCtr_LastSection = "npc"
end

local function OpenAdvancedTool(tool)
  if not TargetNpc then
    Msg("Please select an NPC first")
    return
  end
  if not NusaCtr_GetAdvancedActions or not NusaCtr_ApplyAdvancedAction then
    Msg("Advanced NPC Tools is not loaded")
    return
  end
  AdvancedTool = tool
  AdvancedPage = 1
  AdvancedStatus = ""
  AdvancedCategory = "quick"
end

---------------------------------------------------------------- refresh
local function Refresh()
  if not View then return end
  local sec = Labels[Section] or Labels.quick

  if AdvancedTool then
    local allActions = AdvancedActions()

 -- Edit NPC uses a compact sidebar inside the existing NusaCtr UI.
 -- but all buttons remain inside the existing NusaCtr UI.
    local editCategories = {
 -- Indices are on the MERGED list: QuickActions (1-8) + EditActions (9-101)
      {key="quick",     label="Quick",          first=1,   last=8},
      {key="character", label="Character",      first=9,   last=58},
      {key="combat",    label="Combat",         first=59,  last=83},
      {key="alchemy",   label="Alchemy",        first=84,  last=89},
      {key="more",      label="More",           first=90,  last=101},
    }

    local actions = allActions
    local categoryLabel = nil

    if AdvancedTool == "edit" then
      local cat
      for _, c in ipairs(editCategories) do
        if c.key == AdvancedCategory then cat = c break end
      end
      cat = cat or editCategories[1]
      AdvancedCategory = cat.key
      categoryLabel = (NusaCtr_T and NusaCtr_T(cat.label)) or cat.label

 -- Build a compact page list from the selected category.
      actions = {}
      for i = cat.first, math.min(cat.last, #allActions) do
        if allActions[i] then actions[#actions + 1] = allActions[i] end
      end

 -- Reuse the five existing NusaCtr sidebar buttons.
      local sidebarNames = {"menuQuick","menuSystem","menuBook","menuWorld","menuDeveloper"}
      for i, c in ipairs(editCategories) do
        local b = Child(View, sidebarNames[i])
        if b then
          Text(b, (AdvancedCategory == c.key and "▶ " or "") .. ((NusaCtr_T and NusaCtr_T(c.label)) or c.label))
          pcall(function() b.visible = true; b.alpha = 1 end)
          pcall(function()
            b.onClick:Clear()
            local key = c.key
            b.onClick:Add(function()
              AdvancedCategory = key
              AdvancedPage = 1
              AdvancedStatus = ""
              Refresh()
            end)
          end)
        end
      end
    else
 -- Body / Divine tools keep the clean full-width advanced view.
      for _, mn in ipairs({"menuQuick","menuSystem","menuBook","menuWorld","menuDeveloper"}) do
        local b = Child(View, mn)
        if b then pcall(function() b.visible = false end) end
      end
    end

    local title = NusaCtr_GetAdvancedTitle and NusaCtr_GetAdvancedTitle(AdvancedTool) or "NPC Tools"
    local maxPage = math.max(1, math.ceil(#actions / 6))
    AdvancedPage = math.max(1, math.min(AdvancedPage, maxPage))
    local first = (AdvancedPage - 1) * 6 + 1

    local function L(s) return (NusaCtr_T and NusaCtr_T(s)) or s end
    Text(Child(View, "title"), L("NusaCtr Tools"))
    Text(Child(View, "subtitle"), L("NPC Advanced Tools"))
    Text(Child(View, "brand"), "NusaCtr")
    Text(Child(View, "sectionTitle"),
      L((AdvancedTool == "edit" and categoryLabel) or title))
    Text(Child(View, "description"),
      (AdvancedStatus ~= "" and AdvancedStatus or
        (L("Target NPC: ") .. NpcName(TargetNpc))) ..
        " | " .. L("Page ") .. AdvancedPage .. "/" .. maxPage)
    Text(Child(View, "hint"), L("Select an option to apply it to the selected NPC"))
    Text(Child(View, "btnLanguage"), (NusaCtr_T and NusaCtr_T("Back to NPC")) or "Back to NPC")
    Text(Child(View, "npcName"), NpcName(TargetNpc))
    Text(Child(View, "npcStatus"), NpcStatus(TargetNpc))

    local portrait = Child(View, "npcPortrait")
    if portrait then
      local icon = NpcIcon(TargetNpc)
      if icon ~= "" then pcall(function() portrait.url = icon end) end
      pcall(function() portrait.visible = true end)
    end

    for i = 1, 6 do
      local btn = Child(View, "feature" .. i)
      local a = actions[first + i - 1]
      if btn then
        if a then
          Text(btn, L(a.en or "Action"))
          pcall(function() btn.visible = true; btn.alpha = 1 end)
          pcall(function()
            btn.onClick:Clear()
            local idx = first + i - 1
            btn.onClick:Add(function()
              local ok, result, detail = pcall(function()
                return NusaCtr_ApplyAdvancedAction(TargetNpc, AdvancedTool, actions[idx])
              end)
              if ok and result == true then
                AdvancedStatus = ((NusaCtr_T and NusaCtr_T("Applied: ")) or "Applied: ")
                  .. ((NusaCtr_T and NusaCtr_T(tostring(actions[idx].en))) or tostring(actions[idx].en))
                  .. (detail and ("\n" .. tostring(detail)) or "")
              else
                AdvancedStatus = ((NusaCtr_T and NusaCtr_T("Failed: ")) or "Failed: ") .. tostring(detail or result)
              end
              Refresh()
            end)
          end)
        else
          Text(btn, "")
          pcall(function() btn.visible = false end)
        end
      end
    end

    local prev = Child(View, "feature7")
    local nextb = Child(View, "feature8")
    Text(prev, L("◀ Previous"))
    Text(nextb, L("Next ▶"))
    pcall(function()
      prev.visible = true
      prev.alpha = (AdvancedPage > 1) and 1 or 0.45
    end)
    pcall(function()
      nextb.visible = true
      nextb.alpha = (AdvancedPage < maxPage) and 1 or 0.45
    end)
    pcall(function()
      prev.onClick:Clear()
      prev.onClick:Add(function()
        if AdvancedPage > 1 then
          AdvancedPage = AdvancedPage - 1
          Refresh()
        end
      end)
    end)
    pcall(function()
      nextb.onClick:Clear()
      nextb.onClick:Add(function()
        if AdvancedPage < maxPage then
          AdvancedPage = AdvancedPage + 1
          Refresh()
        end
      end)
    end)

    local back = Child(View, "btnLanguage")
    if back then
      pcall(function()
        back.onClick:Clear()
        back.onClick:Add(function()
          CloseAdvancedTool()
          Refresh()
        end)
      end)
    end
    return
  end

  if TemperatureMode and NusaCtr_Temperature_Refresh then
 -- Keep the exact NusaCtr_Mobile header/portrait. Temperature owns only the content area.
    NusaCtr_Temperature_Refresh(View)
    return
  end

  local function L(s)
    if NusaCtr_T then return NusaCtr_T(s) end
    return s
  end
  Text(Child(View, "title"), L("NusaCtr Tools"))
  Text(Child(View, "subtitle"), L("Pusat alat Amazing Cultivation Simulator"))
  Text(Child(View, "brand"), "NusaCtr")
  Text(Child(View, "sectionTitle"), L(sec.title))
  local standardPageMax = (Section == "quick") and 3 or ((Section == "npc") and 3 or ((Section == "world") and 2 or 1))
  local curPage = (Section == "quick") and QuickPage or ((Section == "npc") and NpcPage or ((Section == "world") and WorldPage or 1))
  Text(Child(View, "description"), L("Available NusaCtr features | Page ") .. tostring(curPage) .. "/" .. tostring(standardPageMax))
  Text(Child(View, "hint"), "")
  if NusaCtr_LangButtonLabel then
    Text(Child(View, "btnLanguage"), NusaCtr_LangButtonLabel())
  else
    Text(Child(View, "btnLanguage"), "Language: E")
  end
  do
    local langBtn = Child(View, "btnLanguage")
    if langBtn then
      pcall(function()
        langBtn.onClick:Clear()
        langBtn.onClick:Add(function()
          if AdvancedTool then return end
          if NusaCtr_ToggleLanguage then NusaCtr_ToggleLanguage() end
          Refresh()
        end)
      end)
    end
  end
  Text(Child(View, "btnClose"), "X")
  Text(Child(View, "npcName"), NpcName(TargetNpc))
  Text(Child(View, "npcStatus"), NpcStatus(TargetNpc))

  local portrait = Child(View, "npcPortrait")
  if portrait then
    local icon = NpcIcon(TargetNpc)
    pcall(function() portrait.visible = true end)
    if icon and icon ~= "" then
      pcall(function() portrait.url = icon end)
      pcall(function() portrait.icon = icon end)
    else
 -- still try race body path from def
      pcall(function()
        local r = RealNpc(TargetNpc)
        if r and r.RaceDef then
          local u = tostring(r.RaceDef.TexPath or r.RaceDef.Rolepaint or "")
          if u ~= "" then portrait.url = u end
        end
      end)
    end
  end

  for i, key in ipairs(TabOrder) do
    local btn = Child(View, TabChild[i])
    if btn then
      local lab = TabLabels[key] or key
      if NusaCtr_T then lab = NusaCtr_T(lab) end
      if key == Section then lab = "▶ " .. tostring(lab) end
      Text(btn, tostring(lab))
      pcall(function() btn.visible = true end)
      pcall(function() btn.alpha = 1 end)
      pcall(function()
        btn.onClick:Clear()
        local k = key
        btn.onClick:Add(function()
          Section = k
          _G.NusaCtr_LastSection = k
          if k == "npc" then NpcPage = 1 end
          if k == "world" then WorldPage = 1 end
          if k == "quick" then QuickPage = 1 end
          Refresh()
        end)
      end)
    end
  end

  
 -- Force sidebar labels (rebrand UI child names)
  do
    local function tabLab(key, en)
      local lab = (NusaCtr_T and NusaCtr_T(en)) or en
      if Section == key then lab = "▶ " .. lab end
      return lab
    end
    Text(Child(View, "menuQuick"), tabLab("quick", "Functions"))
    Text(Child(View, "menuSystem"), tabLab("npc", "NPC"))
    Text(Child(View, "menuBook"), tabLab("book", "Manuals"))
    Text(Child(View, "menuWorld"), tabLab("world", "World"))
    Text(Child(View, "menuDeveloper"), tabLab("developer", "Developer"))
  end
  for _, mn in ipairs({"menuQuick","menuSystem","menuBook","menuWorld","menuDeveloper"}) do
    local b = Child(View, mn)
    if b then
      pcall(function() b.visible = true end)
      pcall(function() b.alpha = 1 end)
    end
  end

for i = 1, 8 do
    local btn = Child(View, "feature" .. i)
    local lab = sec.features[i]
    if Section == "npc" then
      if i <= 6 then
        local first = (NpcPage - 1) * 6 + 1
        lab = sec.features[first + i - 1]
      elseif i == 7 then
        lab = "◀ Previous"
      elseif i == 8 then
        lab = "Next ▶"
      end
    elseif Section == "world" then
      if i <= 6 then
        local first = (WorldPage - 1) * 6 + 1
        lab = sec.features[first + i - 1]
      elseif i == 7 then
        lab = "◀ Previous"
      elseif i == 8 then
        lab = "Next ▶"
      end
    elseif Section == "quick" then
      if i <= 6 then
        local first = (QuickPage - 1) * 6 + 1
        lab = sec.features[first + i - 1]
      elseif i == 7 then
        lab = "◀ Previous"
      elseif i == 8 then
        lab = "Next ▶"
      end
    end
    if btn then
      if lab then
        pcall(function() btn.visible = true end)
        Text(btn, (NusaCtr_T and NusaCtr_T(lab)) or lab)
        pcall(function()
          btn.onClick:Clear()
          local name = lab  -- keep English key for handlers
          btn.onClick:Add(function()
            if TemperatureMode then return end
            if Section == "npc" and name == "◀ Previous" then
              if NpcPage > 1 then
                NpcPage = NpcPage - 1
                Refresh()
              end
              return
            elseif Section == "npc" and name == "Next ▶" then
              if NpcPage < 3 then
                NpcPage = NpcPage + 1
                Refresh()
              end
              return
            elseif Section == "world" and name == "◀ Previous" then
              if WorldPage > 1 then
                WorldPage = WorldPage - 1
                Refresh()
              end
              return
            elseif Section == "world" and name == "Next ▶" then
              if WorldPage < 2 then
                WorldPage = WorldPage + 1
                Refresh()
              end
              return
            elseif Section == "quick" and name == "◀ Previous" then
              if QuickPage > 1 then
                QuickPage = QuickPage - 1
                Refresh()
              end
              return
            elseif Section == "quick" and name == "Next ▶" then
              if QuickPage < 3 then
                QuickPage = QuickPage + 1
                Refresh()
              end
              return
            elseif Section == "npc" and name == "Instant Pet Growth" then
              local target = TargetNpc or _G.NusaCtr_LastTarget
              if not target then
                Msg("Please select a pet first")
              elseif NusaCtr_InstantGrowPet then
                pcall(function() NusaCtr_InstantGrowPet(target) end)
              else
                Msg("Pet growth system not loaded")
              end
              return
            elseif Section == "npc" and name == "Full Pet Awakening" then
              local target = TargetNpc or _G.NusaCtr_LastTarget
              if not target then
                Msg("Please select a pet first")
              elseif NusaCtr_AwakenPetIntelligence then
                pcall(function() NusaCtr_AwakenPetIntelligence(target) end)
              else
                Msg("Pet awakening system not loaded")
              end
              return
            elseif Section == "npc" and name == "Revive NPC" then
              local target = TargetNpc or _G.NusaCtr_LastTarget
              if not target then
                Msg("Please select an NPC first")
              elseif NusaCtr_ReviveNpc then
                NusaCtr_CloseMain()
                local ok, result = pcall(function() return NusaCtr_ReviveNpc(target) end)
                if not ok or result == false then Msg("Failed to start NPC revival") end
              else
                Msg("NPC revival system not loaded")
              end
              return
            elseif Section == "npc" and name == "Secret Treasure" then
              local target = TargetNpc or _G.NusaCtr_LastTarget
              if not target then
                Msg("Please select an NPC first")
              elseif NusaCtr_TakeSecretTreasure then
                NusaCtr_CloseMain()
                local ok, result = pcall(function() return NusaCtr_TakeSecretTreasure(target) end)
                if not ok or result == false then Msg("Failed to open secret treasure picker") end
              else
                Msg("Secret treasure system not loaded")
              end
              return
            elseif Section == "npc" and name == "Delay Heavenly Tribulation" then
              local target = TargetNpc or _G.NusaCtr_LastTarget
              if not target then
                Msg("Please select an NPC first")
              elseif NusaCtr_DelayHeavenlyTribulation then
                local ok, result = pcall(function() return NusaCtr_DelayHeavenlyTribulation(target) end)
                if not ok or result == false then
                  Msg("Failed to delay Heavenly Tribulation")
                else
                  Msg("Heavenly Tribulation delayed by 100 days")
                end
              else
                Msg("Heavenly Tribulation system not loaded")
              end
              return
            elseif Section == "npc" and name == "Boost 5 Stats" then
              local target = TargetNpc or _G.NusaCtr_LastTarget
              if not target then
                Msg("Please select an NPC first")
              elseif NusaCtr_BoostFiveStats then
                local ok, result = pcall(function() return NusaCtr_BoostFiveStats(target) end)
                if not ok or result == false then
                  Msg("Failed to boost 5 base stats")
                else
                  Msg("All five attributes were increased")
                end
              else
                Msg("Boost 5 Stats system not loaded")
              end
              return
            elseif Section == "npc" and name == "Breakthrough" then
              NusaCtr_CloseMain()
              if NusaCtr_OpenBreakthroughMenu then
                pcall(NusaCtr_OpenBreakthroughMenu)
              else
                pcall(require, "Scripts/43_NusaCtr_BreakthroughMenu.lua")
                if NusaCtr_OpenBreakthroughMenu then
                  pcall(NusaCtr_OpenBreakthroughMenu)
                else
                  Msg("Breakthrough menu not loaded")
                end
              end
              return
            elseif Section == "npc" and name == "Toggle Invincible" then
              local target = TargetNpc or _G.NusaCtr_LastTarget
              if not target then
                Msg("Please select an NPC first")
              elseif NusaCtr_ToggleInvincible then
                pcall(function() NusaCtr_ToggleInvincible(target) end)
              else
                pcall(require, "Scripts/37_NusaCtr_UtilityTools.lua")
                if NusaCtr_ToggleInvincible then
                  pcall(function() NusaCtr_ToggleInvincible(target) end)
                else
                  Msg("Invincible system not loaded")
                end
              end
              return
            elseif Section == "npc" and name == "Copy Attributes" then
              local target = TargetNpc or _G.NusaCtr_LastTarget
              if not target then
                Msg("Please select source NPC first")
              elseif NusaCtr_CopyNpcAttributes then
                pcall(function() NusaCtr_CopyNpcAttributes(target) end)
              else
                pcall(require, "Scripts/37_NusaCtr_UtilityTools.lua")
                if NusaCtr_CopyNpcAttributes then
                  pcall(function() NusaCtr_CopyNpcAttributes(target) end)
                else
                  Msg("Copy Attributes not loaded")
                end
              end
              return
            elseif Section == "npc" and name == "Paste Attributes" then
              local target = TargetNpc or _G.NusaCtr_LastTarget
              if not target then
                Msg("Please select target NPC first")
              elseif NusaCtr_PasteNpcAttributes then
                pcall(function() NusaCtr_PasteNpcAttributes(target) end)
              else
                pcall(require, "Scripts/37_NusaCtr_UtilityTools.lua")
                if NusaCtr_PasteNpcAttributes then
                  pcall(function() NusaCtr_PasteNpcAttributes(target) end)
                else
                  Msg("Paste Attributes not loaded")
                end
              end
              return
            elseif name == "Spawn Items" then
              NusaCtr_CloseMain()
              if NusaCtr_OpenItemSpawner then
                pcall(NusaCtr_OpenItemSpawner)
              else
                Msg("Spawner not loaded")
              end
            elseif name == "Open Heart + Max Favor" then
              NusaCtr_CloseMain()
              if NusaCtr_OpenJianghuWindow then
                pcall(NusaCtr_OpenJianghuWindow)
              else
                Msg("Jianghu window not loaded")
              end
            elseif name == "Sect Favor" then
              NusaCtr_CloseMain()
              if NusaCtr_OpenSectFavor then
                pcall(NusaCtr_OpenSectFavor)
              else
                pcall(require, "Scripts/32_NusaCtr_SectFavor.lua")
                if NusaCtr_OpenSectFavor then
                  pcall(NusaCtr_OpenSectFavor)
                else
                  Msg("Sect Favor not loaded")
                end
              end
            elseif name == "Jianghu Favor" then
              NusaCtr_CloseMain()
              if NusaCtr_OpenJianghuFavor then
                pcall(NusaCtr_OpenJianghuFavor)
              else
                pcall(require, "Scripts/33_NusaCtr_JianghuFavor.lua")
                if NusaCtr_OpenJianghuFavor then
                  pcall(NusaCtr_OpenJianghuFavor)
                else
                  Msg("Jianghu Favor not loaded")
                end
              end
            elseif name == "Boss Summon" then
              NusaCtr_CloseMain()
              if NusaCtr_OpenBossSummon then
                pcall(NusaCtr_OpenBossSummon)
              else
                Msg("BossSummon not loaded")
              end
            elseif name == "Open Mini Universe" then
 -- keep Main open behind; native UI is modal-like
              if NusaCtr_OpenMiniUniverse then
                pcall(function() NusaCtr_OpenMiniUniverse(TargetNpc or _G.NusaCtr_LastTarget) end)
              else
                Msg("Mini Universe not loaded")
              end
            elseif name == "Time / Season / Weather" then
              NusaCtr_CloseMain()
              if NusaCtr_OpenWorldTools then
                pcall(function() NusaCtr_OpenWorldTools("climate") end)
              else
                Msg("WorldTools not loaded")
              end
            elseif name == "Temperature" then
              if NusaCtr_OpenTemperatureWindow then
                pcall(NusaCtr_OpenTemperatureWindow)
              else
                Msg("Temperature Window not loaded")
              end
            
            elseif name == "Store Manuals in Library" then
              NusaCtr_CloseMain()
              if NusaCtr_OpenBulkEsoterica then
                pcall(function() NusaCtr_OpenBulkEsoterica(TargetNpc or _G.NusaCtr_LastTarget) end)
              else
                Msg("Bulk Esoterica not loaded")
              end
            elseif name == "Learn Cultivation Arts" then
              NusaCtr_CloseMain()
              if NusaCtr_OpenLearnWindow then
                pcall(function() NusaCtr_OpenLearnWindow(TargetNpc or _G.NusaCtr_LastTarget) end)
              else
                Msg("Learn window not loaded")
              end
            elseif name == "Manual Book Tools" then
              NusaCtr_CloseMain()
              if NusaCtr_OpenBookMenu then
                pcall(function() NusaCtr_OpenBookMenu(TargetNpc or _G.NusaCtr_LastTarget) end)
              else
                Msg("Book Menu not loaded")
              end

            elseif name == "Body Cultivation Tools" then
              OpenAdvancedTool("body")
              Refresh()
            elseif name == "Divine Cultivation Stats" then
              OpenAdvancedTool("divine")
              Refresh()
            elseif name == "Edit NPC" then
              OpenAdvancedTool("edit")
              Refresh()
            elseif name == "School Capacity" then
              if NusaCtr_OpenSchoolCapacity then
                pcall(NusaCtr_OpenSchoolCapacity)
              else
                Msg("School Capacity not loaded")
              end
            elseif name == "Item Tools" then
              NusaCtr_CloseMain()
              if NusaCtr_OpenItemTools then
                pcall(NusaCtr_OpenItemTools)
              else
                Msg("Item Tools not loaded")
              end
            elseif name == "Construction Tools" then
              NusaCtr_CloseMain()
              if NusaCtr_OpenConstructionTools then
                pcall(NusaCtr_OpenConstructionTools)
              else
                Msg("Construction Tools not loaded")
              end
            elseif name == "Map Tools" then
              NusaCtr_CloseMain()
              if NusaCtr_OpenMapTools then
                pcall(NusaCtr_OpenMapTools)
              else
                Msg("MapTools not loaded")
              end
            elseif name == "Agency Tools" then
              NusaCtr_CloseMain()
              if NusaCtr_OpenAgencyTools then
                pcall(NusaCtr_OpenAgencyTools)
              else
                pcall(require, "Scripts/27_NusaCtr_AgencyUnlock.lua")
                if NusaCtr_OpenAgencyTools then
                  pcall(NusaCtr_OpenAgencyTools)
                else
                  Msg("Agency Tools not loaded")
                end
              end
            elseif name == "City Event Helper" then
              NusaCtr_CloseMain()
              if NusaCtr_OpenCityEventHelper then
                pcall(NusaCtr_OpenCityEventHelper)
              else
                pcall(require, "Scripts/28_NusaCtr_CityEventHelper.lua")
                if NusaCtr_OpenCityEventHelper then
                  pcall(NusaCtr_OpenCityEventHelper)
                else
                  Msg("City Event Helper not loaded")
                end
              end
            elseif name == "Merchant Tools" then
              NusaCtr_CloseMain()
              if NusaCtr_OpenMerchantTools then
                pcall(NusaCtr_OpenMerchantTools)
              else
                pcall(require, "Scripts/29_NusaCtr_MerchantTools.lua")
                if NusaCtr_OpenMerchantTools then
                  pcall(NusaCtr_OpenMerchantTools)
                else
                  Msg("Merchant Tools not loaded")
                end
              end
            elseif name == "Sect Alignment" then
              NusaCtr_CloseMain()
              if NusaCtr_OpenSectStatus then
                pcall(NusaCtr_OpenSectStatus)
              else
                pcall(require, "Scripts/30_NusaCtr_SectStatus.lua")
                if NusaCtr_OpenSectStatus then
                  pcall(NusaCtr_OpenSectStatus)
                else
                  Msg("Sect Alignment not loaded")
                end
              end
            elseif name == "Map Cleanup" then
              NusaCtr_CloseMain()
              if NusaCtr_OpenMapCleanup then
                pcall(NusaCtr_OpenMapCleanup)
              else
                pcall(require, "Scripts/31_NusaCtr_MapCleanup.lua")
                if NusaCtr_OpenMapCleanup then
                  pcall(NusaCtr_OpenMapCleanup)
                else
                  Msg("Map Cleanup not loaded")
                end
              end
            elseif name == "Auto Loot" then
              NusaCtr_CloseMain()
              if NusaCtr_OpenAutoLoot then
                pcall(NusaCtr_OpenAutoLoot)
              else
                pcall(require, "Scripts/34_NusaCtr_AutoLoot.lua")
                if NusaCtr_OpenAutoLoot then
                  pcall(NusaCtr_OpenAutoLoot)
                else
                  Msg("Auto Loot not loaded")
                end
              end
            elseif name == "Damage Numbers" then
              if NusaCtr_ToggleDamageNumbers then
                pcall(NusaCtr_ToggleDamageNumbers)
              else
                pcall(require, "Scripts/37_NusaCtr_UtilityTools.lua")
                if NusaCtr_ToggleDamageNumbers then
                  pcall(NusaCtr_ToggleDamageNumbers)
                else
                  Msg("Damage Numbers not loaded")
                end
              end
            elseif name == "Open Taiyi Boxes" then
              local target = TargetNpc or _G.NusaCtr_LastTarget
              if not target then
                Msg("Please select an NPC first")
              elseif NusaCtr_ConfirmOpenAllTaiyiBoxes then
                pcall(function() NusaCtr_ConfirmOpenAllTaiyiBoxes(target) end)
              else
                pcall(require, "Scripts/36_NusaCtr_TaiyiBox_Core.lua")
                if NusaCtr_ConfirmOpenAllTaiyiBoxes then
                  pcall(function() NusaCtr_ConfirmOpenAllTaiyiBoxes(target) end)
                else
                  Msg("Taiyi Boxes not loaded")
                end
              end
            elseif name == "Open Other Boxes" then
              local target = TargetNpc or _G.NusaCtr_LastTarget
              if not target then
                Msg("Please select an NPC first")
              elseif NusaCtr_ConfirmOpenAllOtherBoxes then
                pcall(function() NusaCtr_ConfirmOpenAllOtherBoxes(target) end)
              else
                pcall(require, "Scripts/36_NusaCtr_TaiyiBox_Core.lua")
                if NusaCtr_ConfirmOpenAllOtherBoxes then
                  pcall(function() NusaCtr_ConfirmOpenAllOtherBoxes(target) end)
                else
                  Msg("Other Boxes not loaded")
                end
              end
            elseif name == "Fill All Ling" then
              if NusaCtr_FillAllItemsLing then
                pcall(NusaCtr_FillAllItemsLing)
              else
                pcall(require, "Scripts/37_NusaCtr_UtilityTools.lua")
                if NusaCtr_FillAllItemsLing then pcall(NusaCtr_FillAllItemsLing)
                else Msg("Fill All Ling not loaded") end
              end
            elseif name == "Clear Stuck Jobs" then
              if NusaCtr_ClearStuckJobs then
                pcall(NusaCtr_ClearStuckJobs)
              else
                pcall(require, "Scripts/37_NusaCtr_UtilityTools.lua")
                if NusaCtr_ClearStuckJobs then pcall(NusaCtr_ClearStuckJobs)
                else Msg("Clear Stuck Jobs not loaded") end
              end
            elseif name == "Cancel Blueprints" then
              if NusaCtr_CancelUnfinishedBuildings then
                pcall(NusaCtr_CancelUnfinishedBuildings)
              else
                pcall(require, "Scripts/37_NusaCtr_UtilityTools.lua")
                if NusaCtr_CancelUnfinishedBuildings then pcall(NusaCtr_CancelUnfinishedBuildings)
                else Msg("Cancel Blueprints not loaded") end
              end
            elseif name == "FPS Tools" then
              NusaCtr_CloseMain()
              if NusaCtr_OpenFps then
                pcall(NusaCtr_OpenFps)
              else
                pcall(require, "Scripts/38_NusaCtr_FpsWindow.lua")
                if NusaCtr_OpenFps then
                  pcall(NusaCtr_OpenFps)
                else
                  Msg("FPS Tools not loaded")
                end
              end
            elseif name == "Facebook" then
              OpenSocial("Facebook")
            elseif name == "GitHub" then
              OpenSocial("GitHub")
            elseif name == "YouTube" then
              OpenSocial("YouTube")
            else
              Msg(tostring(name) .. " — coming soon")
            end
          end)
        end)
      else
        Text(btn, "")
        pcall(function() btn.visible = false end)
      end
    end
  end
end

---------------------------------------------------------------- open / close
function NusaCtr_CloseMain()
 -- Remember where the user was so Back from sub-menus can restore NPC/World/etc.
  if Section ~= nil and Section ~= "" then
    _G.NusaCtr_LastSection = Section
  end
  _G.NusaCtr_LastNpcPage = NpcPage or 1
  _G.NusaCtr_LastWorldPage = WorldPage or 1
  _G.NusaCtr_LastQuickPage = QuickPage or 1
  if TargetNpc ~= nil then
    _G.NusaCtr_LastTarget = TargetNpc
  end

  AdvancedTool = nil
  AdvancedPage = 1
  AdvancedStatus = ""
  AdvancedCategory = "quick"
  NpcPage = 1
  WorldPage = 1
  QuickPage = 1
  if View then
    pcall(function() View:RemoveFromParent() end)
    pcall(function() View:Dispose() end)
    View = nil
  end
end

function NusaCtr_OpenMain(npc, preferredSection)
 -- Capture restore targets BEFORE CloseMain (which resets local page counters).
  local restoreSection = preferredSection or _G.NusaCtr_LastSection or Section or "quick"
  local restoreNpcPage = _G.NusaCtr_LastNpcPage or NpcPage or 1
  local restoreWorldPage = _G.NusaCtr_LastWorldPage or WorldPage or 1
  local restoreQuickPage = _G.NusaCtr_LastQuickPage or QuickPage or 1

  NusaCtr_CloseMain()
  if npc ~= nil then
    TargetNpc = npc
    _G.NusaCtr_LastTarget = npc
  else
    TargetNpc = _G.NusaCtr_LastTarget
  end

 -- Stay on the tab the user left (NPC / World / …). Only fall back to Functions
 -- when there is no remembered section or it is invalid.
  if type(restoreSection) ~= "string" or Labels[restoreSection] == nil then
    restoreSection = "quick"
  end
  Section = restoreSection
  _G.NusaCtr_LastSection = Section
  NpcPage = tonumber(restoreNpcPage) or 1
  WorldPage = tonumber(restoreWorldPage) or 1
  QuickPage = tonumber(restoreQuickPage) or 1
  if NpcPage < 1 then NpcPage = 1 end
  if WorldPage < 1 then WorldPage = 1 end
  if QuickPage < 1 then QuickPage = 1 end
  TemperatureMode = false

  local pkg = Pkg()
  local root = Root()
  if not pkg then
    Msg("UIPackage missing")
    return false
  end
  if not root then
    Msg("GRoot missing")
    return false
  end

  local view = nil
  pcall(function() view = pkg.CreateObject(PKG, WIN) end)
  if not view then
    Msg("Failed to open NusaModCenterWindow")
    return false
  end

  View = view
  pcall(function()
    root:AddChild(view)
    view.x = (root.width - view.width) / 2
    view.y = (root.height - view.height) / 2
  end)

  local closeBtn = Child(view, "btnClose")
  if closeBtn then
    pcall(function()
      closeBtn.onClick:Clear()
      closeBtn.onClick:Add(function() NusaCtr_CloseMain() end)
    end)
  end

  local langBtn = Child(view, "btnLanguage")
  if langBtn then
    pcall(function()
      langBtn.onClick:Clear()
      langBtn.onClick:Add(function()
 -- In advanced NPC tools this button means Back; Refresh rebinds it.
        if AdvancedTool then return end
        if NusaCtr_ToggleLanguage then
          NusaCtr_ToggleLanguage()
        end
        Refresh()
      end)
    end)
  end

  Refresh()
  return true
end

function NusaCtr_GetMainView()
  return View
end

function NusaCtr_ShowTemperaturePage()
  if not View then
    NusaCtr_OpenMain(_G.NusaCtr_LastTarget)
  end
  TemperatureMode = true
  Section = "world"
  Refresh()
  return View
end

function NusaCtr_ShowWorldPage()
  TemperatureMode = false
  Section = "world"
  NpcPage = 1
  WorldPage = 1
  Refresh()
end

function NusaCtr_IsTemperaturePage()
  return TemperatureMode == true
end

_G.NusaCtr_OpenMain = NusaCtr_OpenMain
_G.NusaCtr_CloseMain = NusaCtr_CloseMain

print("[NusaCtr] MainWindow standalone loaded")
