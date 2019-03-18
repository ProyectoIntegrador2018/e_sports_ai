X = {}

-- This file has the patterns followed for the item build
local ItemGrid = require(GetScriptDirectory() .. "/BuildPattern");
-- This is a handle to the bot the script is currently running on 
local zeusNPC = GetBot();
local talents = ItemGrid.FillTalenTable(zeusNPC);
local skills  = ItemGrid.FillSkillTable(zeusNPC, ItemGrid.GetSlotPattern());

-- This is the suggested item build for Zeus
X["items"] = { 
	"item_magic_wand",
	"item_arcane_boots",
	"item_pipe",
	"item_veil_of_discord",
	"item_cyclone",
	"item_ultimate_scepter",
	"item_sheepstick",
	"item_guardian_greaves"
};			

-- This is the available skill leveling up pattern for Zeus
X["builds"] = {
	{2,1,2,3,2,4,2,1,1,1,4,3,3,3,4}
}

X["skills"] = ItemGrid.GetBuildPattern(ItemGrid.GetRandomBuild(X['builds']), skills, {2,4,5,8}, talents);

return X