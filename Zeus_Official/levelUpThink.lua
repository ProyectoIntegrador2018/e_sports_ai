local BotsInit = require( "game/botsinit" );
local bot = GetBot();

local mmodule = BotsInit.CreateGeneric();

local build = require(GetScriptDirectory() .. "/item_build_zuus");

bot.abilities = {};

for i=1, math.ceil(#build['skills']/2) do
	bot.abilities[i] = build['skills'][#build['skills']-i+1]; 
	bot.abilities[#build['skills']-i+1] = build['skills'][i];
end

--prevent dota_bot_reload_script for breaking skill build
local first_ability = bot:GetAbilityByName(bot.abilities[#bot.abilities]);
if first_ability ~= nil and first_ability:GetLevel() > 0 then
	for i=#bot.abilities, #bot.abilities-bot:GetLevel()+1, -1 do
		bot.abilities[i] = nil;
	end
end

--Remove "-1" value
local function RemoveMinusOne(tableSkill)
	local temp = {};
	for i=1, #bot.abilities do
		if bot.abilities[i] ~= "-1" then
			temp[#temp+1] = bot.abilities[i];
		end
	end
	return temp;
end

bot.abilities = RemoveMinusOne(bot.abilities);

local checkStuckTime = 0
function AbilityLevelUpThink()  

	if not bot:IsAlive() then
		 bot:Action_ClearActions( false ) 
		 return
	end	
		
	if DotaTime() < 15 then
		bot.theRole = "midlaner";	
	end	
	
	if bot:GetAbilityPoints() > 0 then
    print("Got "..bot:GetAbilityPoints().." points");
		local lastIdx = #bot.abilities;
		local ability = bot:GetAbilityByName(bot.abilities[lastIdx]);
		if ability ~= nil and ability:CanAbilityBeUpgraded() and ability:GetLevel() < ability:GetMaxLevel() then
      print("Leveling up "..bot.abilities[lastIdx]);
      bot:ActionImmediate_LevelAbility(bot.abilities[lastIdx]);
			bot.abilities[lastIdx] = nil;
		end
	end
	
end

return mmodule;