-- NusaCtr Advanced NPC Tools
-- Ports the working logic of Body Practice, Divine Practice and NPC editing.
-- UI is NOT provided here: the existing NusaCtr window is used by MainWindow.

local function RealNpc(npc)
  if not npc then return nil end
  local r = npc
  pcall(function() if npc.npcObj then r = npc.npcObj end end)
  return r
end

local function Msg(text)
  text = tostring(text or "")
  local shown = false
  pcall(function()
    if CS and CS.Wnd_Message then
      CS.Wnd_Message.Show(text, 1, nil, true, "NusaCtr", 0, 0, "")
      shown = true
    end
  end)
  if not shown then pcall(function() if world and world.ShowMsgBox then world:ShowMsgBox(text) end end) end
end

local function Modifier(npc, prop, value)
  local real = RealNpc(npc)
  if not real then return false, "NPC object not found" end
  local pm = nil
  pcall(function() pm = real.PropertyMgr end)
  if pm then
    local ok, err = pcall(function() pm:ModifierProperty(prop, value, 0, 0, 0) end)
    if ok then return true end
    ok, err = pcall(function() pm:ModifierProperty(prop, value) end)
    if ok then return true end
  end
  local ok, err = pcall(function() real:ModifierProperty(prop, value) end)
  if ok then return true end
  return false, "ModifierProperty failed: " .. tostring(prop)
end

local BodyActions = {
  {en="Refill Body Qi", kind="qi"},
  {en="Body Progress +5,000", kind="practice", value=5000},
  {en="Unlock Normal Stance", kind="attitude", id="SYS_NORMAL"},
  {en="Unlock Attack Stance", kind="attitude", id="SYS_ATK"},
  {en="Unlock Manji Battle Will", kind="attitude", id="BPAttitudes_ManJi"},
  {en="Unlock King Battle Will", kind="attitude", id="BPAttitudes_WangZhe"},
  {en="Unlock Basic Quenching", kind="method", id="BPQuenchingMethods_1"},
  {en="Unlock Re-quenching", kind="method", id="BPQuenchingMethods_ReQuenching"},
  {en="Unlock Flesh Quenching", kind="method", id="BPQuenchingMethods_1_1"},
  {en="Unlock Bone Quenching", kind="method", id="BPQuenchingMethods_2"},
  {en="Unlock Marrow Quenching", kind="method", id="BPQuenchingMethods_3"},
  {en="Unlock Organ Quenching", kind="method", id="BPQuenchingMethods_4"},
  {en="Unlock Night Quenching", kind="method", id="BPQuenchingMethods_5"},
  {en="Unlock Advanced Quenching", kind="method", id="BPQuenchingMethods_6"},
  {en="Unlock Body Core", kind="superpart", id="_SYS_CORE_"},
  {en="Unlock Current Art Body Parts", kind="gong_parts"},
  {en="Unlock Racial Body Parts", kind="race_parts"},
  {en="Body Training Essence +1,000", kind="need", value=1000},
  {en="Quenching Speed +10", kind="property", prop="BodyPratice_QuenchingSpeed", value=10},
  {en="Maximum Body Qi +100,000", kind="property", prop="BodyPratice_MaxZhenQi", value=100000},
  {en="Body Qi Recovery +1,000", kind="property", prop="BodyPratice_RecoverZhenQi", value=1000},
  {en="Body Recovery +10", kind="property", prop="BodyPratice_BodyRecover", value=10},
  {en="Body Strength +10", kind="property", prop="BodyPratice_BodyStrong", value=10},
  {en="Attack Body-Part Slot +1", kind="property", prop="BodyPractice_SuperPartAtk_EquptMaxCount", value=1},
  {en="Defense Body-Part Slot +1", kind="property", prop="BodyPractice_SuperPartDef_EquptMaxCount", value=1},
  {en="Effect Body-Part Slot +1", kind="property", prop="BodyPractice_SuperPartBuff_EquptMaxCount", value=1},
  {en="Body-Part Attack Power +100", kind="property", prop="BodyPractice_SuperPartAddv_AtkPower", value=100},
  {en="Body-Part Defense Power +100", kind="property", prop="BodyPractice_SuperPartAddv_DefPower", value=100},
  {en="Body-Part Accuracy +10", kind="property", prop="BodyPractice_SuperPartAddv_AtkRate", value=10},
  {en="Body-Part Defense Rate +10", kind="property", prop="BodyPractice_SuperPartAddv_DefRate", value=10},
  {en="Qi Shield Penetration +100", kind="property", prop="BodyPractice_SuperPartAddv_ArmorPenetration", value=100},
  {en="Artifact Suppression +10", kind="property", prop="BodyPractice_SuperPartAddv_CatchFabao", value=10},
  {en="Devour Item Rank +5", kind="property", prop="BodyPractice_EatItemMaxRate", value=5},
  {en="Devour Essence Amount +10", kind="property", prop="BodyPractice_EatItemProduceCountAddp", value=10},
  {en="Devour Essence Chance +10", kind="property", prop="BodyPractice_EatItemProduceRateAddp", value=10},
  {en="Rare Quenching Chance +10", kind="property", prop="BodyPractice_RollAddtion_Cache1", value=10},
  {en="Epic Quenching Chance +10", kind="property", prop="BodyPractice_RollAddtion_Cache4", value=10},
  {en="Metal Essence +999", kind="material", id="Item_BodyPractice_Jin", value=999},
  {en="Wood Essence +999", kind="material", id="Item_BodyPractice_Mu", value=999},
  {en="Water Essence +999", kind="material", id="Item_BodyPractice_Shui", value=999},
  {en="Fire Essence +999", kind="material", id="Item_BodyPractice_Huo", value=999},
  {en="Earth Essence +999", kind="material", id="Item_BodyPractice_Tu", value=999},
  {en="Life Essence I +999", kind="material", id="Item_BodyPractice_ShengMingLv1", value=999},
  {en="Life Essence II +999", kind="material", id="Item_BodyPractice_ShengMingLv2", value=999},
  {en="Life Essence III +999", kind="material", id="Item_BodyPractice_ShengMingLv3", value=999},
  {en="Death Essence +999", kind="material", id="Item_BodyPractice_SiWang", value=999},
  {en="All Quenching Materials +999", kind="all_materials", value=999},
  {en="Use Normal Stance", kind="set_attitude", id="SYS_NORMAL"},
  {en="Use Attack Stance", kind="set_attitude", id="SYS_ATK"},
  {en="Use Manji Battle Will", kind="set_attitude", id="BPAttitudes_ManJi"},
  {en="Use King Battle Will", kind="set_attitude", id="BPAttitudes_WangZhe"},
  {en="Restore All Missing Body Parts", kind="revive_parts"},
  {en="Randomly Upgrade All Body Parts", kind="upgrade_parts"},
  {en="Clear Current Stance", kind="clear_attitude"},
  {en="View Body Cultivation Status", kind="report"},
}

local AllMaterials = {
  "Item_BodyPractice_TaiXu","Item_BodyPractice_XuanTian","Item_BodyPractice_JieMie","Item_BodyPractice_JiuYang","Item_BodyPractice_XuanYue","Item_BodyPractice_TaiYang","Item_BodyPractice_TaiYin",
  "Item_BodyPractice_EXJin","Item_BodyPractice_EXMu","Item_BodyPractice_EXShui","Item_BodyPractice_EXHuo","Item_BodyPractice_EXTu",
  "Item_BodyPractice_Jin","Item_BodyPractice_Mu","Item_BodyPractice_Shui","Item_BodyPractice_Huo","Item_BodyPractice_Tu",
  "Item_BodyPractice_FengShuiLing","Item_BodyPractice_FengShuiSha","Item_BodyPractice_Chun","Item_BodyPractice_Xia","Item_BodyPractice_Qiu","Item_BodyPractice_Dong","Item_BodyPractice_YongYe",
  "Item_BodyPractice_JiaoLongYuanJing","Item_BodyPractice_XiongFengYuanJing","Item_BodyPractice_ZhuLongYuanJing","Item_BodyPractice_GuShouJingXue","Item_BodyPractice_GuShouGuFen","Item_BodyPractice_DaYaoYuanJing",
  "Item_BodyPractice_ShengMingLv1","Item_BodyPractice_ShengMingLv2","Item_BodyPractice_ShengMingLv3","Item_BodyPractice_SiWang","Item_BodyPractice_WuHui",
  "Item_BodyPractice_DiMu","Item_BodyPractice_XieMai","Item_BodyPractice_WuXing","Item_BodyPractice_XianDaoJingHua","Item_BodyPractice_XianSui","Item_BodyPractice_ShenSui","Item_BodyPractice_BaBao","Item_BodyPractice_WanDao","Item_BodyPractice_QiQing","Item_BodyPractice_ZhouTian","Item_BodyPractice_XuanYang","Item_BodyPractice_Jian","Item_BodyPractice_LingYu","Item_BodyPractice_WanGu","Item_BodyPractice_XuanCi","Item_BodyPractice_QiSha","Item_BodyPractice_XuanYin"
}

local DivineActions = {
  {en="Current Believers +1,000", kind="population", value=1000},
  {en="Current Faith +50,000", kind="faith", value=50000},
  {en="Divine Mind State +100", kind="mind_add", value=100},
  {en="Maximum Divine Mind State", kind="mind_max", value=1000},
  {en="Divine Cultivation +5,000", kind="practice", value=5000},
  {en="Divine Power +999", kind="property", prop="GodPractice_GodPowerAddV", value=999},
  {en="Faith Conversion +999", kind="property", prop="GodPractice_LingConvert", value=999},
  {en="Divine Realm Believer Cap +9,999", kind="property", prop="GodCity_MaxResident", value=9999},
  {en="Core Believers +999", kind="property", prop="GodCity_MaxCoreBeliever", value=999},
  {en="Divine Practice Effect +9", kind="property", prop="GodCity_PracticeEffect", value=9},
  {en="Divine Guard Effect +5", kind="property", prop="GodCity_GuardEffect", value=5},
  {en="Maximum Age +500", kind="property", prop="MaxAge", value=500},
  {en="Maximum Qi +100,000", kind="property", prop="NpcLingMaxValue", value=100000},
  {en="World Travel Speed +10", kind="property", prop="WorldMapFlySpeedAddP", value=10},
  {en="Improve Cold Resistance", kind="property", prop="ToleranceTMin", value=-100},
  {en="Improve Heat Resistance", kind="property", prop="ToleranceTMax", value=1000},
}

local QuickActions = {
  {en="Survival Mode", props={{"RecoveryPower",999},{"MagicDamageRecoveryPowerAddV",9999},{"LingAbsorbSpeed",1000},{"NutritionToJingYuanK",1000},{"NutritionWaterAutoRecover",1000}}},
  {en="No Hunger / Thirst / Fatigue", props={{"FatigueConsumeConstant",-10},{"WaterConsumeConstant",-10},{"HappyConsumeConstant",-10},{"NutritionConsumeConstant",-10},{"PracticeFoodConsumeConstant",-10}}},
  {en="Maximum Talent", props={{"IntelligenceSkillEXPConstant",999},{"PotentialOfBasepracticeAddValue",1000},{"BasepracticeSpeedCoefficient",1000},{"DeepPracticeSpeedSpecialCoefficient",1000},{"MindStateBaseValue",1000},{"SpeedOfMindStateCoefficient",1000},{"SpeedOfMindStateCoefficientByMoods",-1000},{"InspirationCoefficient",1000}}},
  {en="Divine Artifact / Pill Refining", props={{"FabaoMake_SpeedAddV",100000},{"FabaoMake_SuccessRateAddV",100000},{"FabaoMake_LingInheritRateAddV",100000},{"FabaoMake_QualityAddV",100000},{"FabaoMake_TwelveRateChance",100000},{"DanMake_Speed",100000},{"DanMake_SpeedAddV",100000},{"DanMake_SuccessRate",100000},{"DanMake_SuccessRateAddV",100000}}},
  {en="Pill Output ×100", kind="property", prop="DanMake_YieldAddP", value=100},
  {en="Maximum Combat Power", props={{"NpcFight_BaseHitChance",1000},{"NpcFight_BaseDodgeChance",1000},{"NpcFight_ShieldConversionEquipAdd",1000},{"NpcFight_FabaoNum",5},{"NpcFight_FabaoPowerAddP",1000},{"NpcFight_SpellPowerAddP",1000},{"NpcFight_ShieldConversionRateAddP",1000}}},
  {en="Cultivation Bonus", props={{"LeadExperienceAddtion",999},{"WorldMapFlySpeed",1000},{"WorldMapFlySpeedAddP",1000},{"ExperiencePrestigeAddP",1000},{"ExperienceFindSpeedAddV",1000}}},
  {en="Maximum Work Speed", props={{"GlobalEfficiency",100000},{"BaseWorkSpeed",999}}},
}

local EditActions = {
  {en="Five-Element Resistance +999", props={{"NpcFight_ShieldResistanceToJin",999},{"NpcFight_ShieldResistanceToMu",999},{"NpcFight_ShieldResistanceToShui",999},{"NpcFight_ShieldResistanceToHuo",999},{"NpcFight_ShieldResistanceToTu",999}}},
  {en="Recovery Power +999", kind="property", prop="RecoveryPower", value=999},
  {en="Move Speed +999", kind="property", prop="MoveSpeed", value=999},
  {en="Base Emotion +999", kind="property", prop="BaseEmotionAddV", value=999},
  {en="Cold Comfort +999", kind="property", prop="ComfyTMin", value=999},
  {en="Heat Comfort +999", kind="property", prop="ComfyTMax", value=999},
  {en="Cold Tolerance +999", kind="property", prop="ToleranceTMin", value=999},
  {en="Heat Tolerance +999", kind="property", prop="ToleranceTMax", value=999},
  {en="Pain Tolerance +999", kind="property", prop="PainTolerance", value=999},
  {en="Nightmare Chance +0.1", kind="property", prop="NightmareHappenPercent", value=0.1},
  {en="Good Dream Chance +1", kind="property", prop="NiceDreamHappenPercent", value=1},
  {en="Energy Consumption +999", kind="property", prop="FatigueConsumeConstant", value=999},
  {en="Energy Recovery Bonus +999", kind="property", prop="FatigueRecoveryConstant", value=999},
  {en="Food Consumption +999", kind="property", prop="NutritionConsumeConstant", value=999},
  {en="Food Recovery Bonus +999", kind="property", prop="NutritionRecoveryConstant", value=999},
  {en="Water Consumption +999", kind="property", prop="WaterConsumeConstant", value=999},
  {en="Water Recovery Bonus +999", kind="property", prop="WaterRecoveryConstant", value=999},
  {en="Entertainment Consumption +999", kind="property", prop="HappyConsumeConstant", value=999},
  {en="Entertainment Recovery Bonus +999", kind="property", prop="HappyRecoveryConstant", value=999},
  {en="True Qi Consumption +999", kind="property", prop="PracticeFoodConsumeConstant", value=999},
  {en="True Qi Recovery Bonus +999", kind="property", prop="PracticeFoodRecoveryConstant", value=999},
  {en="Internal Injury Recovery Bonus +999", kind="property", prop="MagicDamageRecoveryPowerAddV", value=999},
  {en="Potential Bonus +999", kind="property", prop="PotentialOfBasepracticeAddValue", value=999},
  {en="Heavenly Tribulation Penalty Bonus +999", kind="property", prop="GodPenaltyAddV", value=999},
  {en="Mind State Stability +999", kind="property", prop="SpeedOfMindStateCoefficient", value=999},
  {en="Base Mind State +999", kind="property", prop="MindStateBaseValue", value=999},
  {en="Mood Effect on Mind State +999", kind="property", prop="SpeedOfMindStateCoefficientByMoods", value=999},
  {en="Qi Absorption Speed Bonus +999", kind="property", prop="LingAbsorbSpeed", value=999},
  {en="Base Qi +999", kind="property", prop="_SPECIAL_NOADD_NpcLingMaxValue", value=999},
  {en="Maximum NPC Spirit Power +999", kind="property", prop="NpcLingMaxValue", value=999},
  {en="Lifespan +999", kind="property", prop="MaxAge", value=999},
  {en="Bottleneck Breakthrough Chance +999", kind="property", prop="PracticeRateAddPFromDan", value=999},
  {en="Adventure Flight Speed +999", kind="property", prop="WorldMapFlySpeed", value=999},
  {en="Adventure Flight Speed Bonus +999", kind="property", prop="WorldMapFlySpeedAddP", value=999},
  {en="Adventure Bottleneck Time Multiplier +999", kind="property", prop="ExperienceNeckTimeCostCoefficient", value=999},
  {en="Bottleneck Countdown Delay +999", kind="property", prop="NeckCountdownAddV", value=999},
  {en="Maximum Secret Manuals +999", kind="property", prop="EsotericaNum", value=999},
  {en="Additional Cultivation Power +999", kind="property", prop="AbilityLvAddV", value=999},
  {en="Adventure Prestige Multiplier +999", kind="property", prop="ExperiencePrestigeAddP", value=999},
  {en="Adventure Exploration Speed +999", kind="property", prop="ExperienceFindSpeedAddV", value=999},
  {en="True Qi Gain Rate +999", kind="property", prop="NutritionToJingYuanK", value=999},
  {en="Qi Absorption Efficiency +999", kind="property", prop="NutritionWaterAutoRecover", value=999},
  {en="Learning Speed +999", kind="property", prop="IntelligenceSkillEXPConstant", value=999},
  {en="Inspiration Coefficient +999", kind="property", prop="InspirationCoefficient", value=999},
  {en="Deep Cultivation Speed Bonus +999", kind="property", prop="DeepPracticeSpeedSpecialCoefficient", value=999},
  {en="Foundation Cultivation Speed Bonus +999", kind="property", prop="BasepracticeSpeedCoefficient", value=999},
  {en="Base Work Speed +999", kind="property", prop="BaseWorkSpeed", value=999},
  {en="Experience Gain Bonus +999", kind="property", prop="LeadExperienceAddtion", value=999},
  {en="Global Work Efficiency +999", kind="property", prop="GlobalEfficiency", value=999},
  {en="Furnace Capacity Bonus +999", kind="property", prop="MaxAccumulativeLingAddV", value=999},
  {en="Equipment Shield Conversion Bonus +999", kind="property", prop="NpcFight_ShieldConversionEquipAdd", value=999},
  {en="Artifact Spirit Recovery Multiplier +999", kind="property", prop="NpcFight_FabaoLingRecoverK", value=999},
  {en="Artifact Power Bonus +999", kind="property", prop="NpcFight_FabaoPowerAddP", value=999},
  {en="Artifact Spirit Recovery Bonus +999", kind="property", prop="NpcFight_FabaoLingRecoverAddP", value=999},
  {en="Artifact Attack Speed Bonus +999", kind="property", prop="NpcFight_FabaoCoolDownAddP", value=999},
  {en="Formation Capacity +999", kind="property", prop="NpcFight_ZhenEnginePower", value=999},
  {en="Maximum Health +999", kind="property", prop="MaxHp", value=999},
  {en="Hit Chance +999", kind="property", prop="NpcFight_BaseHitChance", value=999},
  {en="Dodge Chance +999", kind="property", prop="NpcFight_BaseDodgeChance", value=999},
  {en="Artifact Slots +5", kind="property", prop="NpcFight_FabaoNum", value=5},
  {en="Spell Power +999", kind="property", prop="NpcFight_SpellPowerAddP", value=999},
  {en="Vision Radius +999", kind="property", prop="VisionRadius", value=999},
  {en="Artifact Flight Speed +999", kind="property", prop="NpcFight_FabaoFlySpeedAddP", value=999},
  {en="Artifact Turn Speed Bonus +999", kind="property", prop="NpcFight_FabaoTurnSpeedAddP", value=999},
  {en="Artifact Knockback Resistance +999", kind="property", prop="NpcFight_FabaoRepelResist", value=999},
  {en="Artifact Trail Length Bonus +999", kind="property", prop="NpcFight_FabaoTrailingLengthAddP", value=999},
  {en="Spell Duration Bonus +999", kind="property", prop="NpcFight_SpellCastTimeAddP", value=999},
  {en="Stealth Value +999", kind="property", prop="NpcFight_SneakValue", value=999},
  {en="Artifact Maximum Spirit Bonus +999", kind="property", prop="NpcFight_FabaoMaxLingAddP", value=999},
  {en="Artifact Knockback Distance Bonus +999", kind="property", prop="NpcFight_FabaoRepelDistanceAddV", value=999},
  {en="Spell Spirit Cost Bonus +999", kind="property", prop="NpcFight_SpellLingCostAddP", value=999},
  {en="Spell Cooldown Bonus +999", kind="property", prop="NpcFight_SpellCoolDownAddP", value=999},
  {en="Shield Power Bonus +999", kind="property", prop="NpcFight_ShieldConversionRate", value=999},
  {en="Shield Power Multiplier +999", kind="property", prop="NpcFight_ShieldConversionRateAddP", value=999},
  {en="Formation Area Size +999", kind="property", prop="NpcFight_ZhenKeyPointNum", value=999},
  {en="Alchemy Speed +999", kind="property", prop="DanMake_Speed", value=999},
  {en="Alchemy Speed Bonus +999", kind="property", prop="DanMake_SpeedAddV", value=999},
  {en="Alchemy Skill Success Rate Bonus +999", kind="property", prop="DanMake_SuccessRate", value=999},
  {en="Alchemy Success Rate Bonus +999", kind="property", prop="DanMake_SuccessRateAddV", value=999},
  {en="Alchemy Skill Yield Bonus +999", kind="property", prop="DanMake_Yield", value=999},
  {en="Alchemy Yield Bonus +999", kind="property", prop="DanMake_YieldAddP", value=999},
  {en="Artifact Refining Speed Bonus +999", kind="property", prop="FabaoMake_SpeedAddV", value=999},
  {en="Artifact Refining Success Rate Bonus +999", kind="property", prop="FabaoMake_SuccessRateAddV", value=999},
  {en="Artifact Tier Bonus +999", kind="property", prop="FabaoMake_LingInheritRateAddV", value=999},
  {en="Artifact Quality Bonus +999", kind="property", prop="FabaoMake_QualityAddV", value=999},
  {en="Base Divine Artifact Success Rate +999", kind="property", prop="FabaoMake_TwelveRateChance", value=999},
  {en="Faith Conversion Bonus +999", kind="property", prop="GodPractice_LingConvert", value=999},
  {en="Divine Realm Believer Cap +9,999", kind="property", prop="GodCity_MaxResident", value=9999},
  {en="Core Believer Cap +999", kind="property", prop="GodCity_MaxCoreBeliever", value=999},
  {en="Divine Heavenly Tribulation Bonus +999", kind="property", prop="GodCity_ThunderAddion", value=999},
  {en="Divine Realm Faith Gain Bonus +999", kind="property", prop="GodCity_PracticeEffect", value=999},
  {en="Divine Guard Stat Multiplier +5", kind="property", prop="GodCity_GuardEffect", value=5},
  {en="Divine Power Bonus +999", kind="property", prop="GodPractice_GodPowerAddV", value=999}
}
local function body_data(npc)
  local real=RealNpc(npc); if not real then return nil,nil,nil end
  local practice,body=nil,nil
  pcall(function() practice=real.PropertyMgr.Practice end)
  if practice then pcall(function() body=practice.BodyPracticeData end) end
  return body,practice,real
end

local function list_count(list)
  local n=0; pcall(function() n=tonumber(list.Count) or 0 end); return n
end
local function list_item(list,i)
  local v=nil; pcall(function() v=list:get_Item(i) end); if v==nil then pcall(function() v=list[i] end) end; return v
end
local function unlock_list(body,list)
  local okc=0; local total=list_count(list)
  for i=0,total-1 do
    local id=list_item(list,i)
    if id~=nil and tostring(id)~="" then
      local ok=pcall(function() body:UnLockSuperPart(tostring(id),false) end)
      local got=nil; pcall(function() got=body:GetSuperPartData(tostring(id)) end)
      if ok and got~=nil then okc=okc+1 end
    end
  end
  return okc,total
end
local function add_material(body,id,count)
  local def=nil
  pcall(function() def=ThingMgr.Instance:GetDef(g_emThingType.Item,id) end)
  if def==nil then pcall(function() def=CS.XiaWorld.ThingMgr.Instance:GetDef(CS.XiaWorld.g_emThingType.Item,id) end) end
  if def==nil then return false,"item definition not found: "..tostring(id) end
  local before=0; pcall(function() before=tonumber(body:GetQuenchingItemCount(id)) or 0 end)
  local ok,err=pcall(function() body:AddQuenchingItem(id,tonumber(count) or 1) end)
  local after=before; pcall(function() after=tonumber(body:GetQuenchingItemCount(id)) or before end)
  return ok and after>before, ok and (tostring(before).." -> "..tostring(after)) or tostring(err)
end

local function apply_body(npc,a)
  local body,practice,real=body_data(npc)
  if not body then return false,"The selected NPC is not a body cultivator" end
  if a.kind=="qi" then
    local before=tonumber(body.QiValue); local max=tonumber(body.MaxZhenQi) or 999999999
    local ok,err=pcall(function() body:AddZhenQi(max) end); local after=tonumber(body.QiValue)
    return ok and after~=nil and (before==nil or after>=before), tostring(before or "?").." -> "..tostring(after or "?")
  elseif a.kind=="practice" then
    local before=tonumber(practice.StageValue); local ok,err=pcall(function() practice:AddPractice(tonumber(a.value) or 5000,true) end); local after=tonumber(practice.StageValue)
    return ok and after~=nil and (before==nil or after>before), ok and (tostring(before or "?").." -> "..tostring(after or "?")) or tostring(err)
  elseif a.kind=="attitude" then
    local ok,err=pcall(function() body:UnLockAttitude(a.id,false) end); return ok,a.id
  elseif a.kind=="method" then
    local ok,err=pcall(function() body:AddQuenchingMethod(a.id,false) end); return ok,a.id
  elseif a.kind=="superpart" then
    local ok,err=pcall(function() body:UnLockSuperPart(a.id,false) end); return ok,a.id
  elseif a.kind=="gong_parts" then
    local list=nil; pcall(function() list=practice.Gong.SuperParts end); local s,t=unlock_list(body,list); return s>0,"Unlocked "..s.." / "..t
  elseif a.kind=="race_parts" then
    local list=nil; pcall(function() list=real.Race.RaceSuperPart end); local s,t=unlock_list(body,list); return s>0,"Unlocked "..s.." / "..t
  elseif a.kind=="need" then
    local nt=nil; pcall(function() nt=g_emNeedType.Practice end); if nt==nil then pcall(function() nt=CS.XiaWorld.g_emNeedType.Practice end) end
    if nt==nil then return false,"Practice need type not found" end
    local before=tonumber(real.Needs:GetNeedValue(nt)); local ok,err=pcall(function() real.Needs:AddNeedValue(nt,a.value or 1000) end); local after=tonumber(real.Needs:GetNeedValue(nt)); return ok and after~=nil and (before==nil or after>before), tostring(before or "?").." -> "..tostring(after or "?")
  elseif a.kind=="property" then
    return Modifier(npc,a.prop,a.value)
  elseif a.kind=="material" then
    return add_material(body,a.id,a.value)
  elseif a.kind=="all_materials" then
    local s,f=0,0; for _,id in ipairs(AllMaterials) do local ok=add_material(body,id,a.value); if ok then s=s+1 else f=f+1 end end; return s>0,"Added "..s.." types / skipped "..f
  elseif a.kind=="set_attitude" then
    pcall(function() body:UnLockAttitude(a.id,false) end); local ok,err=pcall(function() body:ChangeAttitude(a.id) end); return ok,a.id
  elseif a.kind=="revive_parts" then
    local removed=nil; pcall(function() removed=real.PropertyMgr.BodyData.RemovedParts end); local names={}; for i=0,list_count(removed)-1 do local part=list_item(removed,i); local id=nil; pcall(function() id=tostring(part.def.Name) end); if id then names[#names+1]=id end end
    local s=0; for _,id in ipairs(names) do local got=nil; local ok=pcall(function() got=real.PropertyMgr.BodyData:RevivePart(id) end); if ok and got~=nil then s=s+1 end end; return #names==0 or s>0,"Restored "..s.." / "..#names
  elseif a.kind=="upgrade_parts" then
    local dict=nil; pcall(function() dict=body.SuperParts end); local keys={}; if dict then local e=dict:GetEnumerator(); while e:MoveNext() do keys[#keys+1]=tostring(e.Current.Key) end; pcall(function() e:Dispose() end) end
    local s=0; for _,id in ipairs(keys) do if id~="_SYS_CORE_" then if pcall(function() body:UpgradSuperPart2RandomLevel(id) end) then s=s+1 end end end; return s>0,"Upgraded "..s
  elseif a.kind=="clear_attitude" then local ok=pcall(function() body:ClearAttitude() end); return ok,"Cleared"
  elseif a.kind=="report" then
    local qi,maxqi,stage="?","?","?"; pcall(function() qi=body.QiValue end); pcall(function() maxqi=body.MaxZhenQi end); pcall(function() stage=practice.StageValue end)
    return true,"Body Qi: "..tostring(qi).."/"..tostring(maxqi).." | Progress: "..tostring(stage).." | Stances: "..tostring(list_count(body.Attitudes))
  end
  return false,"Unsupported body action"
end

local function divine_data(npc)
  local real=RealNpc(npc); if not real then return nil,nil end
  local god=nil; pcall(function() god=real.PropertyMgr.Practice.GodPracticeData end); return god,real
end
local function divine_apply(npc,a)
  local god,real=divine_data(npc); if not god then return false,"This NPC has no divine cultivation data" end
  if a.kind=="population" then local ok,err=pcall(function() god:AddPopulation(a.value or 1000) end); return ok,tostring(god.Population or "")
  elseif a.kind=="faith" then local ok,err=pcall(function() god:AddFaith(a.value or 50000) end); return ok,tostring(god.Faith or "")
  elseif a.kind=="mind_add" or a.kind=="mind_max" then
    local nt=nil; pcall(function() nt=g_emNeedType.MindState end); if nt==nil then pcall(function() nt=CS.XiaWorld.g_emNeedType.MindState end) end; if nt==nil then return false,"MindState need type not found" end
    local ok,err=pcall(function() if a.kind=="mind_max" then for _=1,6 do god:MindStateLevelLevelUp() end end; real.Needs:AddNeedValue(nt,a.value or 0) end); return ok,ok and "Applied" or tostring(err)
  elseif a.kind=="practice" then
    local p=nil; pcall(function() p=real.PropertyMgr.Practice end); if not p then return false,"NpcPractice not found" end; local ok,err=pcall(function() p:AddPractice(a.value or 5000) end); return ok,ok and "Applied" or tostring(err)
  elseif a.kind=="property" then return Modifier(npc,a.prop,a.value) end
  return false,"Unsupported divine action"
end

function NusaCtr_GetAdvancedActions(tool)
  if tool=="body" then return BodyActions elseif tool=="divine" then return DivineActions elseif tool=="edit" then
    local out = {}
    for _,a in ipairs(QuickActions) do out[#out+1] = a end
    for _,a in ipairs(EditActions) do out[#out+1] = a end
    return out
  end
  return {}
end
function NusaCtr_GetAdvancedTitle(tool)
  if tool=="body" then return "Body Cultivation Tools" elseif tool=="divine" then return "Divine Cultivation Stats" elseif tool=="edit" then return "Edit NPC" end
  return "NPC Tools"
end
function NusaCtr_ApplyAdvancedAction(npc,tool,a)
  if not npc or not a then return false,"NPC target is missing" end
  if tool=="body" then return apply_body(npc,a) end
  if tool=="divine" then return divine_apply(npc,a) end
  if tool=="edit" then
    local okAll=true; local details={}
    if a.props then
      for _,p in ipairs(a.props) do local ok,err=Modifier(npc,p[1],p[2]); if not ok then okAll=false; details[#details+1]=tostring(err) end end
    else
      local ok,err=Modifier(npc,a.prop,a.value); okAll=ok; if not ok then details[#details+1]=tostring(err) end
    end
    return okAll, okAll and "Applied" or table.concat(details,"; ")
  end
  return false,"Unknown tool"
end
_G.NusaCtr_GetAdvancedActions=NusaCtr_GetAdvancedActions
_G.NusaCtr_GetAdvancedTitle=NusaCtr_GetAdvancedTitle
_G.NusaCtr_ApplyAdvancedAction=NusaCtr_ApplyAdvancedAction
print("[NusaCtr] Advanced NPC Tools loaded")
