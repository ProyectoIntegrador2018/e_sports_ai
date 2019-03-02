------------------------------------------------------------
--- AUTHOR: PLATINUM_DOTA2 (Pooya J.)
--- EMAIL ADDRESS: platinum.dota2@gmail.com
------------------------------------------------------------

-------
require( GetScriptDirectory().."/mode_defend_ally_generic" )
Utility = require(GetScriptDirectory().."/Utility")
----------

local Abilities={
"zuus_arc_lightning",
"zuus_lightning_bolt",
"zuus_static_field",
"zuus_thundergods_wrath"
};

function OnStart()
	mode_generic_defend_ally.OnStart();
end

function OnEnd()
	mode_generic_defend_ally.OnEnd();
end

local function UseQ(Enemy)
	local npcBot = GetBot();
	--we get the skill in the q key
	local ability=npcBot:GetAbilityByName(Abilities[1]);
	if not ability:IsFullyCastable() then
		return false;
	end
	
	local damage=ability:GetAbilityDamage();
	
	local enemy=Enemy;
	--if the enemy is out of range dont cat the skill
	if GetUnitToUnitDistance(npcBot,Enemy)>ability:GetCastRange() then
		return false;
	end
	--if the bot has the mana to cast the skill the use the skill
	if enemy~=nil and npcBot:GetMana()/npcBot:GetMaxMana()>0.40 then
		npcBot:Action_UseAbilityOnEntity(ability,enemy);
		return true;
	end
end

local function UseW(Enemy)
	local npcBot = GetBot();
	--we get the skill in the w key
	local ability=npcBot:GetAbilityByName(Abilities[2]);

	--we check if the skill can be used
	if not ability:IsFullyCastable() then
		return false;
	end
	
	local enemy=Enemy;
	--if the enemy is in the range of the skill cast it
	if GetUnitToUnitDistance(npcBot,Enemy)<ability:GetCastRange() then
		npcBot:Action_UseAbilityOnEntity(ability,enemy)
		return true;
	end
end
 --function to know to tell the bot if he should engage an eneamy
function GetDesire()
	local npcBot=GetBot();
	--if the reamaning health is less than half don´t risk engaging
	if npcBot:GetHealth()/npcBot:GetMaxHealth()<0.5 then
		return 0.0;
	end
	
	
	local Enemy=Utility.GetOurEnemy();
	--if there a enemy can engage
	if Enemy~=nil then
		return 0.4;
	end
	
	return 0.0;
end

function Think()
	--we use the generic api to defend
	mode_generic_defend_ally.Think();
	
	--we get the bot we using
	local npcBot=GetBot();
	
	local Enemy=Utility.GetOurEnemy();
	
	if npcBot:IsUsingAbility() or npcBot:IsChanneling() or Enemy==nil then
		return;
	end
	--if we cant use any skill attack normal
	if (not UseW(Enemy)) and (not UseQ(Enemy)) then
		npcBot:Action_AttackUnit(Enemy,true);
	end
end

--------
