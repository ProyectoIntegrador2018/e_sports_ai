X = {}

local IBUtil = require(GetScriptDirectory() .. "/ItemBuildUtility");
local npcBot = GetBot();
local talents = IBUtil.FillTalenTable(npcBot);
local skills  = IBUtil.FillSkillTable(npcBot, IBUtil.GetSlotPattern(1));

-- This is the suggested and optimal item build for zeus champ
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

-- Indicates the order to buy the items, other orders are also listed as comments
X["builds"] = {
--	{1,2,2,1,2,4,2,1,1,3,4,3,3,3,4},
--	{1,2,2,3,2,4,2,1,1,1,4,3,3,3,4}
	{2,1,2,3,2,4,2,1,1,1,4,3,3,3,4}
}

X["skills"] = IBUtil.GetBuildPattern(
	  "normal", 
	  IBUtil.GetRandomBuild(X['builds']), skills, 
	  {2,4,5,8}, talents
);

return X