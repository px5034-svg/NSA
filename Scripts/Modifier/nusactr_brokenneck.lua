-- NusaCtr: instant bottleneck breakthrough via modifier (fallback path)
local modifierScript = GameMain:GetMod("_ModifierScript")
local modifierClass = modifierScript:GetModifier("modifier_nusactr_brokenneck")

function modifierClass:Enter(modifier, npc)
  pcall(function()
    if npc == nil or npc.PropertyMgr == nil then return end
    local practice = npc.PropertyMgr.Practice
    if practice == nil then return end
    local neck = practice.CurNeck
    if neck == nil then return end
    pcall(function()
      if CS and CS.XiaWorld and CS.XiaWorld.g_emGongBottleNeckType
        and neck.Kind == CS.XiaWorld.g_emGongBottleNeckType.Die then
        return
      end
    end)
    pcall(function() practice:BrokenNeck(false) end)
  end)
end

function modifierClass:Step(modifier, npc, dt) end
function modifierClass:UpdateStack(modifier, npc, add) end
function modifierClass:Leave(modifier, npc) end
function modifierClass:OnGetSaveData() return nil end
function modifierClass:OnLoadData(modifier, npc, data) end
