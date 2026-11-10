-- NusaCtr Heavenly Tribulation modifier.
-- Uses the same modifier behavior as the working reference implementation implementation:
-- only extend an already-active Heavenly Tribulation cooldown; otherwise
-- leave the NPC unchanged without throwing an error.
local modifierScript = GameMain:GetMod("_ModifierScript")
local modifierClass = modifierScript:GetModifier("modifier_nusactr_tribulation")

function modifierClass:Enter(modifier, npc)
    xlua.private_accessible(CS.XiaWorld.GodPractice)

    local practice = nil
    pcall(function()
        practice = npc.PropertyMgr.Practice
    end)

    if practice and practice.GodPracticeData then
        local godPractice = practice.GodPracticeData
        local cooldown = 0
        pcall(function() cooldown = godPractice.FeishengJieColdDown or 0 end)
        if cooldown > 0 then
            godPractice.FeishengJieColdDown =
                cooldown + 600 * 100 * (modifier.Scale or 1)
        end
    end
end

function modifierClass:Step(modifier, npc, dt) end
function modifierClass:UpdateStack(modifier, npc, add) end
function modifierClass:Leave(modifier, npc) end
function modifierClass:OnGetSaveData() return nil end
function modifierClass:OnLoadData(modifier, npc, data) end
