------------------------------------------------------------
--- AUTHOR: PLATINUM_DOTA2 (Pooya J.)
--- EMAIL ADDRESS: platinum.dota2@gmail.com
------------------------------------------------------------

-------
require( GetScriptDirectory().."/mode_attack_generic" )
Utility = require(GetScriptDirectory().."/Utility")
----------

local Abilities={
"zuus_arc_lightning",
"zuus_lightning_bolt",
"zuus_static_field",
"zuus_thundergods_wrath"
};

local UltDamage={225,325,425};

function OnStart()
	mode_generic_attack.OnStart();
end

function OnEnd()
	mode_generic_attack.OnEnd();
end

function GetDesire()
	return mode_generic_attack.GetDesire();
end

local function UseW()
	local npcBot = GetBot();
	
	local ability=npcBot:GetAbilityByName(Abilities[2]);
	--if we don´t have the ability or cannot cast it stop 
	if ability==nil or (not ability:IsFullyCastable()) then
		return false;
	end
	--if the enemy is in range of the skill cast it
	if GetUnitToUnitDistance(npcBot.Target,npcBot)<ability:GetCastRange() then
		npcBot:Action_UseAbilityOnEntity(ability,npcBot.Target);
		return true;
	end
	
	return false;
end

local function UseQ()
	local npcBot = GetBot();
	
	local ability=npcBot:GetAbilityByName(Abilities[1]);
	--if we don´t have the ability or cannot cast it stop 
	if ability==nil or (not ability:IsFullyCastable()) then
		return false;
	end

	--if the enemy is in range of the skill cast it
	if GetUnitToUnitDistance(npcBot.Target,npcBot)<ability:GetCastRange() then
		npcBot:Action_UseAbilityOnEntity(ability,npcBot.Target);
		return true;
	end
	
	return false;
end

function Think()
	mode_generic_attack.Think();
	
	local npcBot=GetBot();
	
	--if the bot is usng a skill or channeling stop
	if npcBot:IsUsingAbility() or npcBot:IsChanneling() then
		return;
	end
	
	--if the bot is attacking or dont have a target
	if not npcBot.IsAttacking or npcBot.Target==nil then
		return;
	end
	
	--if the bot isn´t using abilities attack something
	if (not UseW()) and (not UseQ()) then
		npcBot:Action_AttackUnit(npcBot.Target,true);
	end
end

--------
