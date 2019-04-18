-- This script contains functions used to determine map and enemy awareness

local U = {};

local RB = Vector(-7174.000000, -6671.00000,  0.000000)
local DB = Vector(7023.000000, 6450.000000, 0.000000)
local maxGetRange = 1600;
local maxAddedRange = 200;
local fSpamThreshold = 0.38;
----------------------------

local listBoots = {
	['item_boots'] = 45, 
	['item_tranquil_boots'] = 90, 
	['item_power_treads'] = 45, 
	['item_phase_boots'] = 45, 
	['item_arcane_boots'] = 50, 
	['item_guardian_greaves'] = 55,
	['item_travel_boots'] = 100,
	['item_travel_boots_2'] = 100
}

local modifier = {
	"modifier_winter_wyvern_winters_curse",
	"modifier_winter_wyvern_winters_curse_aura",
	"modifier_fountain_glyph",
	"modifier_necrolyte_reapers_scythe"
}

local secondModifier = {
	"modifier_dazzle_shallow_grave",
	"modifier_oracle_false_promise_timer",
	"modifier_abaddon_borrowed_time",
--	"modifier_item_blade_mail_reflect"

}

-- Saves the hero abilities in abilities[] array
function U.InitiateAbilities(hUnit, tSlots)
	local abilities = {};
	for i = 1, #tSlots do
		abilities[i] = hUnit:GetAbilityInSlot(tSlots[i]);
	end
	return abilities;
end

-- Returns wether the bot can't use and ability due to a modifier or if he is doing something else at the time
function U.CantUseAbility(bot)
	return bot:NumQueuedActions() > 0 
		   or not bot:IsAlive()
		   or bot:IsInvulnerable() 
		   or bot:IsCastingAbility() 
		   or bot:IsUsingAbility() 
		   or bot:IsChanneling()  
	       or bot:IsSilenced() 
		   or bot:IsStunned() 
		   or bot:IsHexed()  
		   or bot:HasModifier("modifier_doom_bringer_doom")
		   or bot:HasModifier('modifier_item_forcestaff_active')
end

-- Returns wether an ability can be casted
function U.CanBeCast(ability)
	return ability:IsTrained() and ability:IsFullyCastable() and ability:IsHidden() == false;
end

-- Returns the weakest unit in a radious
function U.GetVulnerableWeakestUnit(bHero, bEnemy, nRadius, bot)
	local units = {};
	local weakest = nil;
	local weakestHP = 10000;
	if bHero then
		units = bot:GetNearbyHeroes(nRadius, bEnemy, BOT_MODE_NONE);
	else
		units = bot:GetNearbyLaneCreeps(nRadius, bEnemy);
	end
  -- For each nerby unit (creeps and heroes) will search the one with the lowest hp
	for _,u in pairs(units) do
		if u:GetHealth() < weakestHP and U.CanCastOnNonMagicImmune(u) 
		then
			weakest = u;
			weakestHP = u:GetHealth();
		end
	end
	return weakest;
end

-- Returns the weakest unit near a location in a radious
function U.GetVulnerableUnitNearLoc(bHero, bEnemy, nCastRange, nRadius, vLoc, bot)
	local units = {};
	local weakest = nil;
	if bHero then
		units = bot:GetNearbyHeroes(nCastRange, bEnemy, BOT_MODE_NONE);
	else
		units = bot:GetNearbyLaneCreeps(nCastRange, bEnemy);
	end
	for _,u in pairs(units) do
		if GetUnitToLocationDistance(u, vLoc) < nRadius and U.CanCastOnNonMagicImmune(u) then
			weakest = u;
			break;
		end
	end
	return weakest;
end

-- Returns wether the bot can or can't spam an spell
function U.CanSpamSpell(bot, manaCost)
	local initialRatio = 1.0;
	if manaCost < 100 then
		initialRatio = 0.6;
	end
	return ( bot:GetMana() - manaCost ) / bot:GetMaxMana() >= ( initialRatio - bot:GetLevel()/(2*25) );
end

-- Returns the unit that will die against the spell
function U.GetSpellKillTarget(bot, bHero, nRadius, nDamage, nDamageType)
	local units = {};
	if bHero then
		units = bot:GetNearbyHeroes(nRadius, true, BOT_MODE_NONE);
	else
		units = bot:GetNearbyLaneCreeps(nRadius, true);
	end
	for _,unit in pairs(units) do
		if unit ~= nil and unit:GetHealth() <= unit:GetActualIncomingDamage(nDamage, nDamageType) then
			return unit;
		end
	end
	return nil;
end

-- Returns wether the hero is your target
function U.IsEnemyTargetMyTarget(bot, hTarget)
	local enemies = bot:GetNearbyHeroes(1600, true, BOT_MODE_NONE);
	for _,enemy in pairs(enemies) do
		local eaTarget = enemy:GetAttackTarget(); 
		if eaTarget ~= nil and eaTarget == hTarget then
			return true;
		end	
	end
	return false;
end

-- Returns a target for the bot
function U.GetProperTarget(bot)
	local target = bot:GetTarget();
	if target == nil then
		target = bot:GetAttackTarget();
	end
	return target;
end

	local allies = {};
	for i,id in pairs(GetTeamPlayers(GetTeam())) do
		local member = GetTeamMember(i);
		if member ~= nil and member:IsAlive() and GetUnitToLocationDistance(member, vLoc) <= nRadius then
			table.insert(allies, member);
		end
	end
	return allies;
end

	--print(tostring(bot:GetAbilityInSlot(5):GetName()))
	return bot:GetAbilityInSlot(5);
end
-- Returns wheter the bot is retreating
function U.IsRetreating(npcBot)
	return ( npcBot:GetActiveMode() == BOT_MODE_RETREAT and npcBot:GetActiveModeDesire() > BOT_MODE_DESIRE_MODERATE  )
--	         and (npcBot:DistanceFromFountain() > 0 or (npcBot:DistanceFromFountain() < 300 and U.GetNumEnemyAroundMe(npcBot) > 0)) ) 
		  or ( npcBot:GetActiveMode() == BOT_MODE_EVASIVE_MANEUVERS and npcBot:WasRecentlyDamagedByAnyHero(3.0) ) 
		  or ( npcBot:HasModifier('modifier_bloodseeker_rupture') and npcBot:WasRecentlyDamagedByAnyHero(2.0) )
end

-- Return wheter the target is a valid target
function U.IsValidTarget(npcTarget)
	return npcTarget ~= nil and npcTarget:IsAlive() and npcTarget:IsHero() and npcTarget:CanBeSeen(); 
end

-- Returns wheter the bot suspects the target is an illusion
function U.IsSuspiciousIllusion(npcTarget)
	
	if not U.IsValidTarget(npcTarget) or npcTarget:IsCastingAbility()
	then
		return false;
	end

	--TO DO Need to detect enemy hero's illusions better
	local bot = GetBot();
	--Detect allies's illusions
	if npcTarget:GetTeam() == bot:GetTeam()
	then
		return npcTarget:IsIllusion() 
--		       or ( npcTarget:HasModifier("modifier_arc_warden_tempest_double") and npcTarget:GetRemainingLifespan() < 3.0 );
	elseif npcTarget:GetTeam() == GetOpposingTeam()	then
		
		local tID = npcTarget:GetPlayerID();
		
		if not IsHeroAlive( tID )
		then
			U.Report("This nigga is an illusion!! ",npcTarget:GetUnitName());
			return true;
		end	

		if GetHeroLevel( tID ) > npcTarget:GetLevel()
		then
			U.Report("This nigga is an illusion!! ",npcTarget:GetUnitName());
			return true;
		end
		
	end
	
	return false;
end

-- Returns wheter magic can be casted on target
function U.CanCastOnMagicImmune(npcTarget)
	return npcTarget:CanBeSeen() and not npcTarget:IsInvulnerable() and not U.IsSuspiciousIllusion(npcTarget) and not U.HasForbiddenModifier(npcTarget) and not U.IsHumanPlayerCanKill(npcTarget);
end

-- Returns wheter magic can be casted on non immune to magic target
function U.CanCastOnNonMagicImmune(npcTarget)
	return npcTarget:CanBeSeen() 
	       and not npcTarget:IsMagicImmune() 
		   and not npcTarget:IsInvulnerable() 
		   and not U.IsSuspiciousIllusion(npcTarget) 
		   and not U.HasForbiddenModifier(npcTarget) 
		   and not U.IsHumanPlayerCanKill(npcTarget);
end

	return npcTarget:GetActualIncomingDamage( dmg, dmgType ) >= npcTarget:GetHealth(); 
end

-- Returns wether the modifier is forbidden on target (support abilities)
function U.HasForbiddenModifier(npcTarget)
	for _,mod in pairs(modifier)
	do
		if npcTarget:HasModifier(mod) then
			return true
		end	
	end

	local enemies = GetBot():GetNearbyHeroes(800,true,BOT_MODE_NONE);
	if #enemies >= 2
	then
		for _,mod in pairs(secondModifier)
		do
			if npcTarget:HasModifier(mod) then
				return true
			end	
		end
	end
	
	return false;
end

-- Returns wheter the target is disabled
function U.IsDisabled(enemy, npcTarget)
	if enemy then
		return npcTarget:IsRooted( ) or npcTarget:IsStunned( ) or npcTarget:IsHexed( ) or npcTarget:IsNightmared() or U.IsTaunted(npcTarget); 
	else
		return npcTarget:IsRooted( ) or npcTarget:IsStunned( ) or npcTarget:IsHexed( ) or npcTarget:IsNightmared() or npcTarget:IsSilenced( ) or U.IsTaunted(npcTarget);
	end
end

-- Returns wheter the unit has been taunted
function U.IsTaunted(npcTarget)
	return npcTarget:HasModifier("modifier_axe_berserkers_call") 
	    or npcTarget:HasModifier("modifier_legion_commander_duel") 
	    or npcTarget:HasModifier("modifier_winter_wyvern_winters_curse") 
		or npcTarget:HasModifier(" modifier_winter_wyvern_winters_curse_aura");
end

-- Return wheter the target is in casting range
function U.IsInRange(npcTarget, npcBot, nCastRange)
	return GetUnitToUnitDistance( npcTarget, npcBot ) <= nCastRange;
end

-- Returns wether the target is in a team fight
function U.IsInTeamFight(npcBot, range)
	if range == nil then range = 1200 end;
	local tableNearbyAttackingAlliedHeroes = npcBot:GetNearbyHeroes( range, false, BOT_MODE_ATTACK );
	return tableNearbyAttackingAlliedHeroes ~= nil and #tableNearbyAttackingAlliedHeroes >= 2;
end

-- Returns wheter the unit is going on someone
function U.IsGoingOnSomeone(npcBot)
	local mode = npcBot:GetActiveMode();
	return mode == BOT_MODE_ROAM or
		   mode == BOT_MODE_TEAM_ROAM or
		   mode == BOT_MODE_ATTACK or
		   mode == BOT_MODE_DEFEND_ALLY
end

-- Returns wheter the unit is defending
function U.IsDefending(npcBot)
	local mode = npcBot:GetActiveMode();
	return mode == BOT_MODE_DEFEND_TOWER_TOP or
		   mode == BOT_MODE_DEFEND_TOWER_MID or
		   mode == BOT_MODE_DEFEND_TOWER_BOT 
end

-- Returns wheter the unit is pushing lane
function U.IsPushing(npcBot)
	local mode = npcBot:GetActiveMode();
	return mode == BOT_MODE_PUSH_TOWER_TOP or
		   mode == BOT_MODE_PUSH_TOWER_MID or
		   mode == BOT_MODE_PUSH_TOWER_BOT 
end

	local incProj = npcBot:GetIncomingTrackingProjectiles()
	for _,p in pairs(incProj)
	do
		if GetUnitToLocationDistance(npcBot, p.location) < range and not p.is_attack and p.is_dodgeable then
			return true;
		end
	end
	return false;
end
	if delay == 0 then
		return target:GetLocation();
	elseif target:GetMovementDirectionStability() < 0.9 
		then
			return target:GetLocation();
--			local nDis = target:GetCurrentMovementSpeed() *delay;
--			return U.GetFaceTowardDistanceLocation(target,nDis);
	else
		return target:GetExtrapolatedLocation(delay);	
	end
end
	local Team = GetTeam();
	if Team == TEAM_DIRE then
		return RB;
	else
		return DB;
	end
end
	for _,t in pairs(tUnit) do
		if u:GetUnitName() == t:GetUnitName() then
			return true;
		end
	end
	return false;
end 

-- Returns the number of invincible units
function U.CountInvUnits(pierceImmune, units)
	local nUnits = 0;
	if units ~= nil then
		for _,u in pairs(units) do
			if ( pierceImmune and U.CanCastOnMagicImmune(u) ) or ( not pierceImmune and U.CanCastOnNonMagicImmune(u) )  then
				nUnits = nUnits + 1;
			end
		end
	end
	return nUnits;
end

	local Team = GetTeam();
	if Team == TEAM_DIRE then
		return DB;
	else
		return RB;
	end
end
	local AllyCreepsAll = npcBot:GetNearbyCreeps(1600, false);
	local AllyCreeps = { };
	for _,creep in pairs(AllyCreepsAll) 
	do	
		if creep ~= nil 
		   and creep:IsAlive() 
		   and GetUnitToLocationDistance(creep, vLoc) <= nRadius 
		then
			table.insert(AllyCreeps, creep);
		end
	end
	return AllyCreeps;
end 

-- Returns units (distance units) of target at distance from bot
function U.GetUnitTowardDistanceLocation(npcBot,towardTarget,nDistance)
    local npcBotLocation = npcBot:GetLocation();
    local tempVector = (towardTarget:GetLocation() - npcBotLocation) / GetUnitToUnitDistance(npcBot,towardTarget);
	return npcBotLocation + nDistance * tempVector;
end

    local npcBotLocation = npcBot:GetLocation();
    local tempVector = (towardLocation - npcBotLocation) / GetUnitToLocationDistance(npcBot,towardLocation);
	return npcBotLocation + nDistance * tempVector;
end
-- The function returns debug messages
local ReTime = 9999999;
function U.Report(nMessage,nNumber)
	if ReTime < DotaTime() - 5
	then
		ReTime = DotaTime();	
		GetBot():ActionImmediate_Chat(nMessage..string.gsub(tostring(nNumber),"npc_dota_",""),true);
	end
end

-- Get location given a certain range and radius
function U.GetCastLocation(npcBot,npcTarget,nCastRange,nRadius)

	local nDistance = GetUnitToUnitDistance(npcBot,npcTarget)

	if nDistance <= nCastRange
	then
	    return npcTarget:GetLocation();
	end
	
	if nDistance <= nCastRange + nRadius -120
	then
	    return U.GetUnitTowardDistanceLocation(npcBot,npcTarget,nCastRange);
	end
	
	if nDistance < nCastRange + nRadius -18
	   and ( ( U.IsDisabled(true, npcTarget) or npcTarget:GetCurrentMovementSpeed() <= 160) 
			or npcTarget:IsFacingLocation(npcBot:GetLocation(),45)
	        or (npcBot:IsFacingLocation(npcTarget:GetLocation(),45) and npcTarget:GetCurrentMovementSpeed() <= 220))
	then
		return U.GetUnitTowardDistanceLocation(npcBot,npcTarget,nCastRange +8);
	end
	
	if nDistance < nCastRange + nRadius + 28
		and npcTarget:IsFacingLocation(npcBot:GetLocation(),30)
		and npcBot:IsFacingLocation(npcTarget:GetLocation(),30)
		and npcTarget:GetMovementDirectionStability() > 0.95
		and npcTarget:GetCurrentMovementSpeed() >= 300 
	then
		return U.GetUnitTowardDistanceLocation(npcBot,npcTarget,nCastRange +18);
	end
    
	return nil;
end

	local bot = GetBot();
    local slot = bot:FindItemSlot(item_name);
	
	if slot < 0 then return nil end
	
	if bot:GetItemSlotType(slot) == ITEM_SLOT_TYPE_MAIN then
		return bot:GetItemInSlot(slot);
	end
	
    return nil;
end

-- Returns wheter the unit has the keyword in its name
function U.IsKeyWordUnitClass(keyWord,Unit)
	if string.find(Unit:GetUnitName(), keyWord) ~=nil 
	then
		return true;  
	end
	return false;
end

-- Returns wheter target is valid target
function U.IsValid(nTarget)
	return nTarget ~= nil and nTarget:IsAlive() and nTarget:CanBeSeen(); 
end

	if not bot:IsAlive() then return false end
	
	return bot:GetAnimActivity() == ACTIVITY_RUN ;

en

	local units = {};
	local weakest = nil;
	local weakestHP = 10000;
	if bHero then
		units = bot:GetNearbyHeroes(nRadius, bEnemy, BOT_MODE_NONE);
	else
		units = bot:GetNearbyLaneCreeps(nRadius, bEnemy);
	end
	
	for _,unit in pairs(units) do
		if  U.IsValid(unit)
			and not U.HasForbiddenModifier(unit)
			and not unit:IsAttackImmune()
			and not unit:IsInvulnerable()
			and unit:GetHealth() < weakestHP 
		then
			weakest = unit;
			weakestHP = unit:GetHealth();
		end
	end
	return weakest;
end

