-- Ancient Essence Pill (JingYuan 4-9) — no overlap with Sample/JingYuan1-3
NusaCtr_ExtraItems = NusaCtr_ExtraItems or {}
NusaCtr_ItemPacks = NusaCtr_ItemPacks or {}

local Rows = {
  { id = "Item_Dan_JingYuan4", count = 1, cat = "Pills" },
  { id = "Item_Dan_JingYuan5", count = 1, cat = "Pills" },
  { id = "Item_Dan_JingYuan6", count = 1, cat = "Pills" },
  { id = "Item_Dan_JingYuan7", count = 1, cat = "Pills" },
  { id = "Item_Dan_JingYuan8", count = 1, cat = "Pills" },
  { id = "Item_Dan_JingYuan9", count = 1, cat = "Pills" },
}

for _, row in ipairs(Rows) do
  NusaCtr_ExtraItems[#NusaCtr_ExtraItems + 1] = row
end
NusaCtr_ItemPacks["Ancient Essence"] = Rows
print("[NusaCtr] Ancient Essence pills: " .. tostring(#Rows))
