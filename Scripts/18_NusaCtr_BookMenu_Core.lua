-- NusaCtr Book Menu commands

NusaCtr_NewBookCategories = {
  { id = "all", text = "All" },
  { id = "unlock", text = "Unlock Arts" },
  { id = "manual", text = "Manual Books" },
  { id = "warp", text = "Teleport" },
}

NusaCtr_NewBookCommands = {
  { text = "Teleport", category = "warp", action = "warp" },
  { text = "Unlock All Main Arts", category = "unlock", story = "NusaCtr_Unlock_AllGong" },
  { text = "Random Heaven-Tier Arts x2", category = "unlock", story = "NusaCtr_Unlock_RandomHeavenGong20" },
}

local storyNumbers = { 500, 501, 502, 503, 504, 505, 506, 507, 508 }
for number = 510, 524 do storyNumbers[#storyNumbers + 1] = number end
for index, number in ipairs(storyNumbers) do
  NusaCtr_NewBookCommands[#NusaCtr_NewBookCommands + 1] = {
    text = "Receive 20 manuals set " .. tostring(index),
    category = "manual",
    story = "nusa_book" .. tostring(number),
  }
end

function NusaCtr_GetNewBookCommands(category)
  category = tostring(category or "all")
  local result = {}
  for _, command in ipairs(NusaCtr_NewBookCommands) do
    if category == "all" or command.category == category then
      result[#result + 1] = command
    end
  end
  return result
end

local function RealNpc(npc)
  return npc
end

function NusaCtr_RunNewBookCommand(npc, command)
  if command == nil then return false, "Command not found" end
  local actor = RealNpc(npc)
  if actor == nil then return false, "No target NPC" end

  if command.action == "warp" then
    local ok, err = false, "no warp story"
    for _, story in ipairs({"Warp1", "warp1", "Teleport", "MapWarp"}) do
      ok, err = pcall(function() actor:TriggerStory(story) end)
      if ok then return true, "Opened teleport menu" end
    end
    return false, tostring(err)
  end

  local story = tostring(command.story or "")
  if story == "" then return false, "Command has no Story" end
  local ok, err = pcall(function()
    if actor.TriggerStory ~= nil then actor:TriggerStory(story); return end
    if CS and CS.XiaWorld and CS.XiaWorld.NpcLuaHelper then
      local helper = CS.XiaWorld.NpcLuaHelper(actor)
      if helper and helper.TriggerStory then helper:TriggerStory(story); return end
    end
    error("TriggerStory not found")
  end)
  return ok, ok and "Command started" or tostring(err)
end

_G.NusaCtr_GetNewBookCommands = NusaCtr_GetNewBookCommands
_G.NusaCtr_RunNewBookCommand = NusaCtr_RunNewBookCommand
print("[NusaCtr] Book Menu core loaded")
