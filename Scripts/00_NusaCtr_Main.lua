-- NusaCtr Main (standalone bootstrap)
-- All feature scripts are required here so the mod knows what is loaded.

local Mod = GameMain:NewMod("NusaCtrMobile")

 ----------------------------------------------------------------
 -- UI / Main window (must load early for Open())
 ----------------------------------------------------------------
  pcall(require, 'Scripts/02_NusaCtr_Language.lua')  -- ID/EN (before UI)
  pcall(require, 'Scripts/01_NusaCtr_MainWindow.lua')

 ----------------------------------------------------------------
 -- Item spawner / packs
 ----------------------------------------------------------------
  pcall(require, 'Scripts/03_NusaCtr_ExtraItems.lua')
  pcall(require, 'Scripts/04_NusaCtr_ItemPacks.lua')
  pcall(require, 'Scripts/05_NusaCtr_ItemSpawner_Core.lua')
  pcall(require, 'Scripts/06_NusaCtr_ItemSpawnerWindow.lua')
  pcall(require, 'Scripts/39_NusaCtr_NusaCustom_ItemList.lua')
  pcall(require, 'Scripts/40_NusaCtr_SupplementalItems.lua')
  pcall(require, 'Scripts/41_NusaCtr_BlackMarketWhitelist.lua')
  pcall(require, 'Scripts/45_NusaCtr_AncientEssence_ItemList.lua')

 ----------------------------------------------------------------
 -- Jianghu / Heart / Favor
 ----------------------------------------------------------------
  pcall(require, 'Scripts/07_NusaCtr_Jianghu_Core.lua')
  pcall(require, 'Scripts/08_NusaCtr_JianghuWindow.lua')
  pcall(require, 'Scripts/32_NusaCtr_SectFavor.lua')      -- max favor all sects
  pcall(require, 'Scripts/33_NusaCtr_JianghuFavor.lua')   -- mass Jianghu favor

 ----------------------------------------------------------------
 -- Boss / Map / World tools
 ----------------------------------------------------------------
  pcall(require, 'Scripts/09_NusaCtr_BossSummonWindow.lua')
  pcall(require, 'Scripts/10_NusaCtr_MapToolsWindow.lua')
  pcall(require, 'Scripts/11_NusaCtr_WorldTools_Core.lua')
  pcall(require, 'Scripts/12_NusaCtr_WorldToolsWindow.lua')
  pcall(require, 'Scripts/42_NusaCtr_Temperature_Window.lua')

 ----------------------------------------------------------------
 -- Construction / Items / Mini universe / School
 ----------------------------------------------------------------
  pcall(require, 'Scripts/13_NusaCtr_MiniUniverse.lua')
  pcall(require, 'Scripts/14_NusaCtr_ConstructionToolsWindow.lua')
  pcall(require, 'Scripts/15_NusaCtr_ItemToolsWindow.lua')
  pcall(require, 'Scripts/16_NusaCtr_SchoolCapacity.lua')

 ----------------------------------------------------------------
 -- Books / Learn / Esoterica
 ----------------------------------------------------------------
  pcall(require, 'Scripts/17_NusaCtr_BulkEsoterica_Core.lua')
  pcall(require, 'Scripts/18_NusaCtr_BookMenu_Core.lua')
  pcall(require, 'Scripts/19_NusaCtr_LibraryLearn_Core.lua')
  pcall(require, 'Scripts/20_NusaCtr_LearnFullGong_Core.lua')
  pcall(require, 'Scripts/21_NusaCtr_BulkEsoterica_Window.lua')
  pcall(require, 'Scripts/22_NusaCtr_BookMenu_Window.lua')
  pcall(require, 'Scripts/23_NusaCtr_LearnWindow.lua')

 ----------------------------------------------------------------
 -- Advanced NPC / Pet / Special actions
 ----------------------------------------------------------------
  pcall(require, 'Scripts/24_NusaCtr_AdvancedNpcTools.lua')
  pcall(require, 'Scripts/25_NusaCtr_PetGrowth_Core.lua')
  pcall(require, 'Scripts/26_NusaCtr_NpcSpecialActions_Core.lua')

 ----------------------------------------------------------------
 -- Agency / City / Merchant / Sect status
 ----------------------------------------------------------------
  pcall(require, 'Scripts/27_NusaCtr_AgencyUnlock.lua')       -- map unlock + influence
  pcall(require, 'Scripts/28_NusaCtr_CityEventHelper.lua')    -- (+)/(-)/(~) on agency events
  pcall(require, 'Scripts/29_NusaCtr_MerchantTools.lua')      -- call walking merchant
  pcall(require, 'Scripts/30_NusaCtr_SectStatus.lua')         -- reputation + Good/Evil

 ----------------------------------------------------------------
 -- Map cleanup / Auto loot / Damage / Taiyi / Utility / FPS
 ----------------------------------------------------------------
  pcall(require, 'Scripts/31_NusaCtr_MapCleanup.lua')         -- weeds / trash / poop / corpses
  pcall(require, 'Scripts/34_NusaCtr_AutoLoot.lua')           -- auto loot
  pcall(require, 'Scripts/35_NusaCtr_DamageNumbers.lua')      -- damage numbers
  pcall(require, 'Scripts/36_NusaCtr_TaiyiBox_Core.lua')      -- open Taiyi boxes
  pcall(require, 'Scripts/37_NusaCtr_UtilityTools.lua')       -- misc utility
  pcall(require, 'Scripts/38_NusaCtr_FpsWindow.lua')          -- FPS tools
  pcall(require, 'Scripts/43_NusaCtr_BreakthroughMenu.lua')  -- breakthrough + auto

function Mod:OnEnter()
  local event = GameMain:GetMod("_Event")
  if not event then return end
  event:RegisterEvent(g_emEvent.SelectNpc, function(evt, npc, objs)
    if not npc then return end
    local isNpc = true
    pcall(function()
      if g_emThingType and npc.ThingType and npc.ThingType ~= g_emThingType.Npc then
        isNpc = false
      end
    end)
    if not isNpc then return end
    pcall(function()
      npc:RemoveBtnData("NusaCtr")
      npc:AddBtnData(
        "NusaCtr",
        "res/Sprs/ui/icon_hand",
        "GameMain:GetMod('NusaCtrMobile'):Open(bind)",
        "NusaCtr Tools",
        nil
      )
    end)
  end, "NusaCtrMobile_SelectNpc")

 -- Ensure City Event Helper hooks the city window when entering world
  pcall(function()
    local helper = GameMain:GetMod("NusaCtr_CityEventHelper")
    if helper and helper.OnEnter then helper:OnEnter() end
  end)
end

function Mod:OnRender(dt)
  if NusaCtr_AutoLoot_OnRender then
    pcall(NusaCtr_AutoLoot_OnRender)
  end
  if NusaCtr_MapCleanup_OnRender then
    pcall(NusaCtr_MapCleanup_OnRender)
  end
  if NusaCtr_Fps_OnRender then
    pcall(NusaCtr_Fps_OnRender)
  end
  if NusaCtr_DamageNumbers_OnRender then
    pcall(NusaCtr_DamageNumbers_OnRender)
  end
  if NusaCtr_AutoBreakthrough_OnRender then
    pcall(NusaCtr_AutoBreakthrough_OnRender)
  end
end

function Mod:OnSave()
  local data = {}
  if NusaCtr_Lang then data.Lang = NusaCtr_Lang end
  if NusaCtr_AutoLoot_GetSaveData then
    local ok, al = pcall(NusaCtr_AutoLoot_GetSaveData)
    if ok and type(al) == "table" then
      data.AutoLoot = al
    end
  end
  if NusaCtr_MapCleanup_GetSaveData then
    local okm, mc = pcall(NusaCtr_MapCleanup_GetSaveData)
    if okm and type(mc) == "table" then data.MapCleanup = mc end
  end
  return data
end

function Mod:OnLoad(data)
  data = data or {}
  if data.Lang == "en" or data.Lang == "id" then
    NusaCtr_Lang = data.Lang
  end
  if data.AutoLoot and NusaCtr_AutoLoot_ApplySaveData then
    pcall(function() NusaCtr_AutoLoot_ApplySaveData(data.AutoLoot) end)
  end
  if data.MapCleanup and NusaCtr_MapCleanup_ApplySaveData then
    pcall(function() NusaCtr_MapCleanup_ApplySaveData(data.MapCleanup) end)
  end
end

function Mod:NeedSyncData()
  return false
end

function Mod:Open(npc)
 -- bind from button is the NPC; keep global for portrait restore
  if npc ~= nil then
    _G.NusaCtr_LastTarget = npc
  end
  if NusaCtr_OpenMain then
    pcall(function() NusaCtr_OpenMain(npc or _G.NusaCtr_LastTarget) end)
  end
end

print("[NusaCtr] Main standalone loaded — all feature modules required")
