Utility = require( GetScriptDirectory().."/Utility");

local Abilities={
"zuus_arc_lightning",
"zuus_lightning_bolt",
"zuus_static_field",
"zuus_thundergods_wrath"
};

local EnemyLaneCreeps = {};
local AllyLaneCreeps = {};

function  OnStart()
	print("Farming...");
end

function OnEnd()
end

function GetDesire()
	local npcBot=GetBot();
	local creep=nil;
	local chealth=10000;
	local ability=npcBot:GetAbilityByName(Abilities[1]);

	
	--we fill the values of the varibales based on which creep is the weakest in range of the bot
	creep,chealth=Utility.GetWeakestCreep(400);

	--we get the numbers of creeps of the enemy
	EnemyLaneCreeps = npcBot:GetNearbyLaneCreeps(400, true);

	--we get the total numbers of creeps
	AllyLaneCreeps = npcBot:GetNearbyLaneCreeps(400, false);

	--we check if there are creeps, if the weakest creep has less than 25% of life and the bot has enought heath and the bot has more creeps than the enemy
	if creep~=nil and (chealth < creep:GetMaxHealth()*.25) and (npcBot:GetHealth() > npcBot:GetMaxHealth()*.4) and (#AllyLaneCreeps - #EnemyLaneCreeps >-1)then
		return 0.5;
	else
		return 0.0;
	end

end

function Think()
	local npcBot=GetBot();
	local creep=nil;
	local chealth=10000;
	local ability=npcBot:GetAbilityByName(Abilities[1]);
	
	--we get the ability damage
	local damage=ability:GetAbilityDamage();
	
	--we fill the values of the varibales based on which creep is the weakest in range of the bot
	creep,chealth=Utility.GetWeakestCreep(ability:GetCastRange());
	--if there is a creep in range
	if creep~=nil then
		--if the creep is in range of the skill and the bot has the mana to cast the skill and the bot has the ability
		if Utility.GetDistance(creep:GetLocation(),npcBot:GetLocation())>npcBot:GetAttackRange()+150 and npcBot:GetMana()/npcBot:GetMaxMana()>0.65 and  ability:IsFullyCastable() then
			--use the skill on the creep
			npcBot:Action_UseAbilityOnEntity(ability,creep);
			return;
		else
			--if we cannot use the skill we use normal attack
			npcBot:Action_AttackUnit(creep, false);
		end
	end

end
