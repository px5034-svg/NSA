-- NusaCtr Jianghu Core (Ready-style heart unlock)

local function Msg(text)
  text = tostring(text or "")
  local shown = false
  pcall(function()
    CS.Wnd_Message.Show(text, 1, nil, true, "NusaCtr", 0, 0, "")
    shown = true
  end)
  if not shown then
    pcall(function() if world and world.ShowMsgBox then world:ShowMsgBox(text) end end)
  end
end

local function Manager()
  local mgr = nil
  pcall(function() mgr = JianghuMgr end)
  if not mgr then pcall(function() mgr = CS.XiaWorld.JianghuMgr.Instance end) end
  return mgr
end

function NusaCtr_OpenHeartBySeed(seed, addFavor)
  local ok, err = pcall(function()
    if seed == nil then error("NPC seed missing") end
    seed = tonumber(seed) or seed
    local mgr = Manager()
    if not mgr then error("JianghuMgr not found") end

 -- Create persistent relationship record first
    mgr:AddKnowNpcData(seed)
    local data = mgr:GetKnowNpcData(seed)
    if not data then error("Cannot create KnowNpcData") end

    data:UnlockHeart()
    pcall(function() data.hlock = 1 end)

    if addFavor == true then
      local current = tonumber(data.favour) or 0
      local delta = 100 - current
      if delta > 0 then
        local added = false
        pcall(function()
          mgr:AddKnowNpcData(seed, CS.XiaWorld.g_emJHNpcDataType.None, delta, nil)
          added = true
        end)
        if not added then data.favour = 100 end
      end
    end
  end)
  if ok then
    Msg(addFavor and "Open Heart + Max Favor OK" or "Open Heart OK")
    return true
  end
  Msg("Failed:\n" .. tostring(err))
  return false
end

function NusaCtr_ReadHeartState(seed)
  local state = { favor = "-", vigilance = "-", heart = "No" }
  if seed == nil then return state end
  pcall(function()
    local mgr = Manager()
    local data = mgr and mgr:GetKnowNpcData(seed) or nil
    if data ~= nil then
      state.favor = tostring(data.favour or data.Favour or 0)
      state.vigilance = tostring(data.Vigilance or data.vigilance or 0)
      local h = tonumber(data.hlock or data.HLock or 0) or 0
      state.heart = (h == 1) and "Yes" or "No"
    else
      state.favor = "Unknown"
      state.heart = "No"
    end
  end)
  return state
end

_G.NusaCtr_OpenHeartBySeed = NusaCtr_OpenHeartBySeed
_G.NusaCtr_ReadHeartState = NusaCtr_ReadHeartState
print("[NusaCtr] Jianghu Core loaded")
