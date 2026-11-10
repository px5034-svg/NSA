-- ============================================================
-- NusaCtr NusaCustom Item List
-- NusaCtr custom items (needs Settings/ThingDef XML)
-- Icons: FabaoTexPath preferred in spawner UI
-- ============================================================

NusaCtr_ExtraItems = NusaCtr_ExtraItems or {}
NusaCtr_ItemPacks = NusaCtr_ItemPacks or {}

local NusaCustomRows = {
  { id = "Item_BeefUJI01", count = 1, cat = "Other" },
  { id = "Item_BonecrushMace", count = 1, cat = "Weapons" },
  { id = "Item_Cape_Nomal1U01", count = 1, cat = "Other" },
  { id = "Item_Cape_Nomal2U01", count = 1, cat = "Other" },
  { id = "Item_Cape_Nomal3U01", count = 1, cat = "Other" },
  { id = "Item_Cape_Nomal4U01", count = 1, cat = "Other" },
  { id = "Item_Cape_Sp10U3", count = 1, cat = "Other" },
  { id = "Item_Cape_Sp1U01U2", count = 1, cat = "Other" },
  { id = "Item_Cape_Sp2U3", count = 1, cat = "Other" },
  { id = "Item_Cape_Sp3U3", count = 1, cat = "Other" },
  { id = "Item_Cape_Sp4U3", count = 1, cat = "Other" },
  { id = "Item_Cape_Sp5U3", count = 1, cat = "Other" },
  { id = "Item_Cape_Sp6U3", count = 1, cat = "Other" },
  { id = "Item_Cape_Sp7U3", count = 1, cat = "Other" },
  { id = "Item_Cape_Sp8U3", count = 1, cat = "Other" },
  { id = "Item_Cape_Sp9U3", count = 1, cat = "Other" },
  { id = "Item_Dan_BlissfogTranquilityPill", count = 1, cat = "Pills" },
  { id = "Item_Dan_CelestialQiSurgePowder", count = 1, cat = "Pills" },
  { id = "Item_Dan_CelestialQiSurgePowderV2", count = 1, cat = "Pills" },
  { id = "Item_Dan_CelestialQiSurgePowderV3", count = 1, cat = "Pills" },
  { id = "Item_Dan_CelestialQiSurgePowderV4", count = 1, cat = "Pills" },
  { id = "Item_Dan_CelestialQiSurgePowderV5", count = 1, cat = "Pills" },
  { id = "Item_Dan_CelestialQiSurgePowderV6", count = 1, cat = "Pills" },
  { id = "Item_Dan_CondensedNutrientPill", count = 1, cat = "Pills" },
  { id = "Item_Dan_DilutedMindResinPowder", count = 1, cat = "Pills" },
  { id = "Item_Dan_EurekaInsightPill", count = 1, cat = "Pills" },
  { id = "Item_Dan_FivefoldAscensionPill", count = 1, cat = "Pills" },
  { id = "Item_Dan_FivefoldMeridianRemedyPill", count = 1, cat = "Pills" },
  { id = "Item_Dan_HeavenboundRevivalPill", count = 1, cat = "Pills" },
  { id = "Item_Dan_HeavenflowElixir", count = 1, cat = "Pills" },
  { id = "Item_Dan_InsightCatalystPill", count = 1, cat = "Pills" },
  { id = "Item_Dan_Mind-CleansingPurityPill", count = 1, cat = "Pills" },
  { id = "Item_Dan_QiCirculationPill", count = 1, cat = "Pills" },
  { id = "Item_Dan_QiSustenancePill", count = 1, cat = "Pills" },
  { id = "Item_Dan_RealmInsightInnerPill", count = 1, cat = "Pills" },
  { id = "Item_Dan_Sample", count = 1, cat = "Pills" },
  { id = "Item_Dan_Soul-AnchorAscensionPill", count = 1, cat = "Pills" },
  { id = "Item_Dan_SoulforgeReconstitutionPill", count = 1, cat = "Pills" },
  { id = "Item_Dan_SpiritCoreExpansionPill", count = 1, cat = "Pills" },
  { id = "Item_Dan_VitalResinEssencePowder", count = 1, cat = "Pills" },
  { id = "Item_DeepfangSpear", count = 1, cat = "Weapons" },
  { id = "Item_GoldenSustenanceFruit", count = 1, cat = "Materials" },
  { id = "Item_LongreachHuntingBow", count = 1, cat = "Weapons" },
  { id = "Item_MiBao_HuoFabaoUJI", count = 1, cat = "Artifacts" },
  { id = "Item_MiBao_XiXingShenSuoUJI", count = 1, cat = "Artifacts" },
  { id = "Item_PracticeClothes089281", count = 1, cat = "Other" },
  { id = "Item_RazorboundChakram", count = 1, cat = "Weapons" },
  { id = "Item_SP_Clothes01U02", count = 1, cat = "Other" },
  { id = "Item_SP_Clothes01U03", count = 1, cat = "Other" },
  { id = "Item_SP_Trousers1U01", count = 1, cat = "Other" },
  { id = "Item_SP_Trousers1U02", count = 1, cat = "Other" },
  { id = "Item_SereneSpiritLeaf", count = 1, cat = "Materials" },
  { id = "Item_SpiritualResinEssence", count = 1, cat = "Materials" },
  { id = "Item_SwiftsteelBlade", count = 1, cat = "Weapons" },
  { id = "Item_TerrafluxVitalCream", count = 1, cat = "Materials" },
  { id = "Item_VitalBloomEssence", count = 1, cat = "Materials" },
  { id = "Item_YaoLeather101U01", count = 1, cat = "Other" },
}

do
  local seen = {}
  for _, row in ipairs(NusaCtr_ExtraItems) do
    if type(row) == 'string' then seen[row] = true
    elseif type(row) == 'table' and row.id then seen[tostring(row.id)] = true end
  end
  local added = 0
  for _, row in ipairs(NusaCustomRows) do
    if row.id and not seen[row.id] then
      NusaCtr_ExtraItems[#NusaCtr_ExtraItems + 1] = row
      seen[row.id] = true
      added = added + 1
    end
  end
  NusaCtr_ItemPacks[#NusaCtr_ItemPacks + 1] = {
    name = "NusaCustom",
    items = NusaCustomRows,
  }
  print("[NusaCtr] NusaCustom items loaded: " .. tostring(#NusaCustomRows) .. " (+" .. tostring(added) .. " new to ExtraItems)")
end
