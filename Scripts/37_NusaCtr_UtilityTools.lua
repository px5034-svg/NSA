-- ============================================================
-- NusaCtr Utility Tools
-- Clear stuck jobs / Fill item ling / Cancel blueprints
-- ============================================================

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

local function iter_list(list, fn)
  if list == nil then return 0 end
  local n = 0
  local count = 0
  pcall(function() count = list.Count end)
  if count and count > 0 then
    for i = 0, count - 1 do
      local item = nil
      pcall(function() item = list[i] end)
      if item == nil then pcall(function() item = list:get_Item(i) end) end
      if item ~= nil then
        local ok = false
        pcall(function() ok = fn(item) == true end)
        if ok then n = n + 1 end
      end
    end
    return n
  end
  pcall(function()
    for _, item in pairs(list) do
      if item ~= nil then
        local ok = false
        pcall(function() ok = fn(item) == true end)
        if ok then n = n + 1 end
      end
    end
  end)
  return n
end

local function clear_npc_jobs(npc)
  local ok = false
  pcall(function()
    local je = npc.JobEngine
    if je == nil then return end
    if je.ClearAllJobs then je:ClearAllJobs(); ok = true end
    if je.ClearJob then je:ClearJob(); ok = true end
    pcall(function() je.SearchTree = nil end)
    pcall(function() je.CurJob = nil end)
  end)
  pcall(function()
    if npc.ClearAllCommand then npc:ClearAllCommand(); ok = true end
  end)
  pcall(function()
    if npc.InitBehaviour then npc:InitBehaviour() end
  end)
  return ok
end

local function is_player_npc(npc)
  local yes = false
  pcall(function()
    if npc.Camp == CS.XiaWorld.Fight.g_emFightCamp.Player then yes = true end
  end)
  pcall(function() if npc.IsPlayerThing == true then yes = true end end)
  pcall(function()
    local r = npc.Rank
    local e = CS.XiaWorld.g_emNpcRank
    if e and (r == e.Disciple or r == e.Worker or r == e.Joiner) then yes = true end
  end)
  return yes
end

local function destroy_thing(thing)
  local done = false
  pcall(function() if thing.Destroy then thing:Destroy(true); done = true end end)
  if not done then pcall(function() if thing.DestroySelf then thing:DestroySelf(); done = true end end) end
  if not done then
    pcall(function()
      local tm = CS.XiaWorld.ThingMgr.Instance or ThingMgr
      if tm and tm.RemoveThing then tm:RemoveThing(thing); done = true end
    end)
  end
  return done
end

function NusaCtr_ClearStuckJobs()
  local cleared, checked = 0, 0
  local sel = _G.NusaCtr_LastTarget
  if sel ~= nil then
    checked = checked + 1
    if clear_npc_jobs(sel) then cleared = cleared + 1 end
  end
  pcall(function()
    local map = World and World.map or Map
    local lis = nil
    pcall(function() lis = map.Things.m_lisNpcs end)
    if lis == nil then pcall(function() lis = Map.Things.m_lisNpcs end) end
    iter_list(lis, function(npc)
      if npc == sel then return false end
      checked = checked + 1
      if is_player_npc(npc) and clear_npc_jobs(npc) then
        cleared = cleared + 1
      end
      return false
    end)
  end)
  Msg("Jobs cleared.\nNPCs: " .. tostring(cleared) .. " / checked " .. tostring(checked))
  return cleared > 0
end

function NusaCtr_FillAllItemsLing()
  local filled, checked, skip = 0, 0, 0
  local list = nil
  pcall(function()
    local tm = CS.XiaWorld.ThingMgr.Instance or ThingMgr
    local ty = CS.XiaWorld.g_emThingType and CS.XiaWorld.g_emThingType.Item
    if tm and ty then list = tm:GetThingList(ty) end
  end)
  if list == nil then
    pcall(function()
      if ThingMgr and g_emThingType then list = ThingMgr:GetThingList(g_emThingType.Item) end
    end)
  end
  iter_list(list, function(item)
    checked = checked + 1
    local did = false
    pcall(function()
      if item.AddLing == nil or item.MaxLing == nil then
        skip = skip + 1
        return
      end
      local maxv = tonumber(item.MaxLing) or 0
      local curv = tonumber(item.LingV) or 0
      if maxv <= 0 then
        skip = skip + 1
        return
      end
      local need = maxv - curv
      if need > 0 then
        item:AddLing(need)
        did = true
      end
    end)
    if not did then
      pcall(function()
        if item.MaxLing and item.LingV ~= nil then
          local maxv = tonumber(item.MaxLing) or 0
          if maxv > 0 and (tonumber(item.LingV) or 0) < maxv then
            item.LingV = maxv
            did = true
          end
        end
      end)
    end
    if did then filled = filled + 1 end
    return false
  end)
  Msg("Item ling filled.\nFilled: " .. tostring(filled)
    .. " | checked: " .. tostring(checked)
    .. " | no ling slot: " .. tostring(skip))
  return filled > 0
end

local function is_unfinished_building(b)
  local yes = false
  pcall(function() if b.IsBlueprint == true then yes = true end end)
  pcall(function() if b.Blueprint == true then yes = true end end)
  pcall(function()
    local p = tonumber(b.BuildProgress or b.Progress or b.BuildP)
    if p ~= nil and p < 1 then yes = true end
  end)
  pcall(function()
    if b.IsFinished == false then yes = true end
  end)
  pcall(function()
    if b.Finished == false then yes = true end
  end)
  pcall(function()
    local def = b.def or b.Def
    if def and def.Name then
      local n = tostring(def.Name)
      if n:find("Blueprint") or n:find("blueprint") then yes = true end
    end
  end)
  pcall(function()
    local p = tonumber(b.BuildProgress or b.Progress)
    if p ~= nil and p >= 1 and b.IsBlueprint ~= true then yes = false end
  end)
  return yes
end

function NusaCtr_CancelUnfinishedBuildings()
  local removed, checked = 0, 0
  local list = nil
  pcall(function()
    local tm = CS.XiaWorld.ThingMgr.Instance or ThingMgr
    local ty = CS.XiaWorld.g_emThingType and CS.XiaWorld.g_emThingType.Building
    if tm and ty then list = tm:GetThingList(ty) end
  end)
  if list == nil then
    pcall(function()
      if ThingMgr and g_emThingType then list = ThingMgr:GetThingList(g_emThingType.Building) end
    end)
  end
  local to_kill = {}
  iter_list(list, function(b)
    checked = checked + 1
    if is_unfinished_building(b) then
      to_kill[#to_kill + 1] = b
    end
    return false
  end)
  for i = 1, #to_kill do
    if destroy_thing(to_kill[i]) then removed = removed + 1 end
  end
  Msg("Blueprints cancelled.\nRemoved: " .. tostring(removed) .. " / checked " .. tostring(checked))
  return removed > 0
end

function NusaCtr_ToggleDamageNumbers()
  local mod = nil
  pcall(function() mod = GameMain:GetMod("NusaCtr_DamageNumbers", true) end)
  if mod == nil then
    pcall(require, "Scripts/35_NusaCtr_DamageNumbers.lua")
    pcall(function() mod = GameMain:GetMod("NusaCtr_DamageNumbers", true) end)
  end
  if mod and mod.Toggle then
    return mod:Toggle()
  end
  Msg("Damage Numbers not loaded")
  return false
end

_G.NusaCtr_ClearStuckJobs = NusaCtr_ClearStuckJobs
_G.NusaCtr_FillAllItemsLing = NusaCtr_FillAllItemsLing
_G.NusaCtr_CancelUnfinishedBuildings = NusaCtr_CancelUnfinishedBuildings
_G.NusaCtr_ToggleDamageNumbers = NusaCtr_ToggleDamageNumbers



---------------------------------------------------------------- NPC helpers
local function get_real(npc)
  if not npc then return nil end
  local r = npc
  pcall(function() if npc.npcObj then r = npc.npcObj end end)
  return r
end

local function get_name(npc)
  local n = "NPC"
  pcall(function() n = tostring(npc.Name or npc:GetName() or n) end)
  return n
end

function NusaCtr_ToggleInvincible(npc)
  npc = get_real(npc or _G.NusaCtr_LastTarget)
  if npc == nil then
    Msg("Select an NPC first")
    return false
  end
  local name = get_name(npc)
  local now_god = false
  pcall(function() now_god = npc.IsGod == true end)
  local enable = not now_god
  local steps = {}

  pcall(function()
    npc.IsGod = enable
    steps[#steps + 1] = "IsGod=" .. tostring(enable)
  end)
  pcall(function()
    local f = CS.XiaWorld.g_emNpcSpecailFlag
    if f and f.FLAG_GODMODE then
      if enable then
        if npc.AddSpecialFlag then npc:AddSpecialFlag(f.FLAG_GODMODE, 1) end
      else
        if npc.RemoveSpecialFlag then npc:RemoveSpecialFlag(f.FLAG_GODMODE) end
      end
      steps[#steps + 1] = "FLAG_GODMODE"
    end
  end)
  pcall(function()
    local f = CS.XiaWorld.g_emNpcSpecailFlag
    if f and f.FLAG_INFHP_PUPPET and enable and npc.AddSpecialFlag then
      npc:AddSpecialFlag(f.FLAG_INFHP_PUPPET, 1)
      steps[#steps + 1] = "INFHP"
    elseif f and f.FLAG_INFHP_PUPPET and not enable and npc.RemoveSpecialFlag then
      npc:RemoveSpecialFlag(f.FLAG_INFHP_PUPPET)
    end
  end)
  pcall(function()
    local pm = npc.PropertyMgr
    if pm == nil then return end
    if enable and pm.AddModifier then
      pcall(function() pm:AddModifier("Modifier_Sys_GodMode", 1, 0) end)
      steps[#steps + 1] = "Mod GodMode"
    elseif not enable and pm.RemoveModifier then
      pcall(function() pm:RemoveModifier("Modifier_Sys_GodMode") end)
    end
  end)

  Msg((enable and "Invincible ON: " or "Invincible OFF: ") .. name
    .. "\n(" .. table.concat(steps, ", ") .. ")")
  return true
end

NusaCtr_NpcCopyBuffer = NusaCtr_NpcCopyBuffer or nil

local COPY_PROPS = {
  "Perception", "Constitution", "Charisma", "Intelligence", "Luck",
  "Physique", "Charm", "IntelligenceBase", "PerceptionBase",
  "NpcFight_BaseHitChance", "MoveSpeed", "RecoveryPower",
  "MindStateBaseValue", "MaxAge", "PotentialOfBasepracticeAddValue",
}

local function read_prop(npc, name)
  local v = nil
  pcall(function()
    local pm = npc.PropertyMgr
    if pm and pm.GetProperty then v = pm:GetProperty(name) end
  end)
  if v == nil then
    pcall(function()
      local pm = npc.PropertyMgr
      if pm and pm[name] ~= nil then v = pm[name] end
    end)
  end
  if v == nil then pcall(function() v = npc[name] end) end
  return tonumber(v)
end

local function write_prop(npc, name, value)
  if value == nil then return false end
  local ok = false
  pcall(function()
    local pm = npc.PropertyMgr
    if pm and pm.ModifierProperty then
      pm:ModifierProperty(name, value, 0, 0, 0)
      ok = true
    end
  end)
  if not ok then
    pcall(function()
      local pm = npc.PropertyMgr
      if pm and pm.SetProperty then pm:SetProperty(name, value); ok = true end
    end)
  end
  if not ok then
    pcall(function() npc[name] = value; ok = true end)
  end
  return ok
end

function NusaCtr_CopyNpcAttributes(npc)
  npc = get_real(npc or _G.NusaCtr_LastTarget)
  if npc == nil then
    Msg("Select source NPC first")
    return false
  end
  local buf = { name = get_name(npc), props = {}, age = nil }
  for _, prop in ipairs(COPY_PROPS) do
    local v = read_prop(npc, prop)
    if v ~= nil then buf.props[prop] = v end
  end
  pcall(function() buf.age = tonumber(npc.Age) end)
  local n = 0
  for _ in pairs(buf.props) do n = n + 1 end
  NusaCtr_NpcCopyBuffer = buf
  Msg("Copied from: " .. buf.name
    .. "\nProperties: " .. tostring(n)
    .. "\nSelect target NPC → Paste attributes")
  return n > 0
end

function NusaCtr_PasteNpcAttributes(npc)
  npc = get_real(npc or _G.NusaCtr_LastTarget)
  if npc == nil then
    Msg("Select target NPC first")
    return false
  end
  local buf = NusaCtr_NpcCopyBuffer
  if buf == nil or buf.props == nil then
    Msg("No copy buffer.\nCopy attributes first.")
    return false
  end
  local applied = 0
  for prop, value in pairs(buf.props) do
    if write_prop(npc, prop, value) then applied = applied + 1 end
  end
  if buf.age ~= nil then
    pcall(function() npc.Age = buf.age; applied = applied + 1 end)
  end
  Msg("Pasted to: " .. get_name(npc)
    .. "\nFrom: " .. tostring(buf.name)
    .. "\nApplied: " .. tostring(applied))
  return applied > 0
end

_G.NusaCtr_ToggleInvincible = NusaCtr_ToggleInvincible
_G.NusaCtr_CopyNpcAttributes = NusaCtr_CopyNpcAttributes
_G.NusaCtr_PasteNpcAttributes = NusaCtr_PasteNpcAttributes

print("[NusaCtr] Utility Tools loaded")
