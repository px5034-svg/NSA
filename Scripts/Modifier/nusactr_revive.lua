local modifierScript = GameMain:GetMod("_ModifierScript")
local modifierClass = modifierScript:GetModifier("modifier_nusactr_revive")

function modifierClass:Enter(modifier, npc)
    local info = {
        KC = "Npc",
        Line = {StartObj = npc},
        HeadMsg = "Select an NPC to revive",
        Apply = function(_, map, key, mode)
            local target = mode:GetThing(g_emThingType.Npc, key, map)
            if target == nil then error("Target NPC not found") end
            if not target.IsDeath then error("This NPC is still alive") end
            if not target:CanResurrection() then
                error("This NPC has no spirit and cannot be revived")
            end

            target:Resurrection()

            local school = CS.XiaWorld.SchoolGlobleMgr.Instance
            if school ~= nil then
                local seeds = {}
                local function add_seed(v)
                    v = tonumber(v) or 0
                    if v > 0 and not seeds[v] then
                        seeds[v] = true
                        school:RemoveJianghuNpcDie(v)
                        pcall(function() school:AddJianghuNpcBack(v) end)
                    end
                end
                pcall(function() add_seed(target.JiangHuSeed) end)
                pcall(function()
                    add_seed(target:CheckSpecialFlag(
                        CS.XiaWorld.g_emNpcSpecailFlag.JianghuLocaltionSeed))
                end)
            end

            pcall(function()
                CS.XiaWorld.EventMgr.Instance:EventTrigger(
                    CS.XiaWorld.g_emEvent.ThingUpdate, target)
            end)
            if target.IsDeath then error("The game still reports the NPC as dead") end
            pcall(function() world:ShowMsgBox("NPC revived successfully") end)
        end,
        Check = function(_, map, key, mode)
            local target = mode:GetThing(g_emThingType.Npc, key, map)
            return target ~= nil
                and target.ThingType == g_emThingType.Npc
                and target.IsDeath
                and target:CanResurrection()
        end,
    }

    world:EnterUILuaMode("TableCtrl", info)
end

function modifierClass:Step(modifier, npc, dt) end
function modifierClass:UpdateStack(modifier, npc, add) end
function modifierClass:Leave(modifier, npc) end
function modifierClass:OnGetSaveData() return nil end
function modifierClass:OnLoadData(modifier, npc, data) end
