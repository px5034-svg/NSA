-- NusaCtr: permanent +10 to all five base stats (and skill levels from Modifier XML)
local modifierScript = GameMain:GetMod("_ModifierScript")
local modifierClass = modifierScript:GetModifier("modifier_nusactr_fivebasedan")

function modifierClass:Enter(modifier, npc)
  pcall(function()
    if xlua and xlua.private_accessible then
      xlua.private_accessible(CS.XiaWorld.Modifier.modifierBase)
    end
  end)
  pcall(function() modifier.Version = 0 end)
  pcall(function()
    if modifier.ModifyBaseFive and npc and npc.PropertyMgr then
      modifier:ModifyBaseFive(npc.PropertyMgr, modifier.Scale)
    end
  end)
end

function modifierClass:Step(modifier, npc, dt) end
function modifierClass:UpdateStack(modifier, npc, add) end
function modifierClass:Leave(modifier, npc) end
function modifierClass:OnGetSaveData() return nil end
function modifierClass:OnLoadData(modifier, npc, data) end
