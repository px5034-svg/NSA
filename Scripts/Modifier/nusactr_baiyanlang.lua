-- NusaCtr: bind a secret treasure (MiBao) from the map to the selected NPC.
-- Port of modifier_baiyanlang ( "Ambil harta" / Secret treasure).
local modifierScript = GameMain:GetMod("_ModifierScript")
local modifierClass = modifierScript:GetModifier("modifier_nusactr_baiyanlang")

function modifierClass:Enter(modifier, npc)
  local info = {
    KC = "Item",
    Line = { StartObj = npc },
    HeadMsg = "Select a secret treasure to bind",
    Apply = function(_, map, key, mode)
      local target = mode:GetThing(g_emThingType.Item, key, map)
      if target == nil then error("Item not found") end
      if not target.IsMiBao then error("Selected item is not a secret treasure (MiBao)") end
      target:BindItem2Npc(npc)
      pcall(function()
        if world and world.ShowMsgBox then
          world:ShowMsgBox("Secret treasure bound to NPC")
        end
      end)
    end,
    Check = function(_, map, key, mode)
      local target = mode:GetThing(g_emThingType.Item, key, map)
      return target ~= nil and target.IsMiBao
    end,
  }

  world:EnterUILuaMode("TableCtrl", info)
end

function modifierClass:Step(modifier, npc, dt) end
function modifierClass:UpdateStack(modifier, npc, add) end
function modifierClass:Leave(modifier, npc) end
function modifierClass:OnGetSaveData() return nil end
function modifierClass:OnLoadData(modifier, npc, data) end
