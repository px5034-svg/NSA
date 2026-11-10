-- NusaCtr NPC special actions.
-- These actions intentionally use the game's modifier flow, matching the
-- working reference implementation implementation while keeping NusaCtr's own modifier IDs.

local function nctr_real_npc(npc)
  if npc == nil then return nil end
  local candidates = { npc }
  local function add(v)
    if v ~= nil then candidates[#candidates + 1] = v end
  end

  pcall(function() add(npc.npcObj) end)
  pcall(function() add(npc.NpcObj) end)
  pcall(function() add(npc.Npc) end)
  pcall(function() add(npc.npc) end)
  pcall(function() add(npc.thing) end)
  pcall(function() add(npc.bind) end)
  pcall(function() add(npc.obj) end)

  for _, c in ipairs(candidates) do
    local ok, pm = pcall(function() return c.PropertyMgr end)
    if ok and pm ~= nil then return c end
  end
  for _, c in ipairs(candidates) do
    local ok, mp = pcall(function() return c.ModifierProperty end)
    if ok and mp ~= nil then return c end
  end
  return candidates[1]
end

local function nctr_try_add_modifier(npc, id)
  local real = nctr_real_npc(npc)
  if real == nil then return false, "NPC object not found" end

  local ok, err = pcall(function()
    if real.AddModifier == nil then error("AddModifier is unavailable") end
    real:AddModifier(id)
  end)
  if ok then return true end

  local ok2, pm = pcall(function() return real.PropertyMgr end)
  if ok2 and pm ~= nil then
    local ok3, err3 = pcall(function()
      if pm.AddModifier == nil then error("PropertyMgr.AddModifier is unavailable") end
      pm:AddModifier(id)
    end)
    if ok3 then return true end
    err = err3 or err
  end

  return false, tostring(err)
end

function NusaCtr_ReviveNpc(npc)
  if npc == nil then
    return false, "Please select an NPC first"
  end
 -- Exactly the same mechanism as reference implementation: add the special-action modifier to
 -- the selected NPC and let the modifier's Enter() perform resurrection.
  return nctr_try_add_modifier(npc, "NusaCtr_ReviveNPC")
end

function NusaCtr_DelayHeavenlyTribulation(npc)
  if npc == nil then
    return false, "Please select an NPC first"
  end
 -- Do NOT read PropertyMgr.Practice here. The working source mod adds its
 -- modifier and lets the game's modifier callback receive the real NPC.
  return nctr_try_add_modifier(npc, "NusaCtr_DelayTribulation")
end

function NusaCtr_BoostFiveStats(npc)
  if npc == nil then
    return false, "Please select an NPC first"
  end
 -- Same mechanism as reference: add QuanBu-style modifier; Enter() applies BaseFive.
  return nctr_try_add_modifier(npc, "NusaCtr_FiveStats")
end

_G.NusaCtr_BoostFiveStats = NusaCtr_BoostFiveStats

function NusaCtr_TakeSecretTreasure(npc)
  if npc == nil then
    return false, "Please select an NPC first"
  end
 -- Same mechanism as Revive: add modifier so Enter() opens TableCtrl to pick MiBao.
  return nctr_try_add_modifier(npc, "NusaCtr_TakeSecretTreasure")
end

_G.NusaCtr_TakeSecretTreasure = NusaCtr_TakeSecretTreasure
_G.NusaCtr_ReviveNpc = NusaCtr_ReviveNpc
_G.NusaCtr_DelayHeavenlyTribulation = NusaCtr_DelayHeavenlyTribulation

function NusaCtr_BreakthroughNow(npc)
  if npc == nil then
    return false, "Please select an NPC first"
  end
  local real = nctr_real_npc(npc)
  if real == nil then return false, "NPC object not found" end

  local practice = nil
  local okPractice = pcall(function() practice = real.PropertyMgr.Practice end)
  if not okPractice or practice == nil then
    return false, "This NPC has no cultivation practice system"
  end

  local neck = nil
  pcall(function() neck = practice.CurNeck end)
  if neck == nil then
    return false, "No next bottleneck to break through"
  end

  local kind = nil
  pcall(function() kind = neck.Kind end)
  if kind ~= nil and CS and CS.XiaWorld and CS.XiaWorld.g_emGongBottleNeckType then
    if kind == CS.XiaWorld.g_emGongBottleNeckType.Die then
      return false, "Death bottleneck cannot be forced"
    end
  end

  local beforeStage, beforeTouch, beforeGod = nil, nil, nil
  pcall(function() beforeStage = practice.LogicStage end)
  pcall(function() beforeTouch = practice.TouchNeck == true end)
  pcall(function() beforeGod = practice.GodCount end)

  local result = false
  local okBreak, breakErr = pcall(function()
    result = practice:BrokenNeck(false) == true
  end)
  if not okBreak then return false, tostring(breakErr) end
  if not result then return false, "Game rejected breakthrough" end

  local afterStage, afterTouch, afterGod = nil, nil, nil
  pcall(function() afterStage = practice.LogicStage end)
  pcall(function() afterTouch = practice.TouchNeck == true end)
  pcall(function() afterGod = practice.GodCount end)
  if afterStage ~= beforeStage or afterTouch ~= beforeTouch or afterGod ~= beforeGod then
    return true, "Breakthrough successful"
  end
  return false, "Game reported success but stage did not change"
end

_G.NusaCtr_BreakthroughNow = NusaCtr_BreakthroughNow

