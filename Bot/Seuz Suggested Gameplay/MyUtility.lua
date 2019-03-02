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
	"modifier_necrolyte_reapers_scythe",
	--"modifier_modifier_dazzle_shallow_grave",
	--"modifier_oracle_false_promise_timer",
	--"modifier_oracle_fates_edict"
}

local secondModifier = {
	"modifier_dazzle_shallow_grave",
	"modifier_oracle_false_promise_timer",
	"modifier_abaddon_borrowed_time",
--	"modifier_item_blade_mail_reflect"

}

-- Sets the hero abilities to variable abilities[]
function U.InitiateAbilities(hUnit, tSlots)
	local abilities = {};
	for i = 1, #tSlots do
		abilities[i] = hUnit:GetAbilityInSlot(tSlots[i]);
	end
	return abilities;
end

-- Returns wether the bot can't use and ability
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

-- Returns true cast range of the ability
function U.GetProperCastRange(bIgnore, hUnit, abilityCR)
	local attackRng = hUnit:GetAttackRange();
	if bIgnore then
		return abilityCR;
	elseif abilityCR <= attackRng then
		return attackRng + maxAddedRange;
	elseif abilityCR + maxAddedRange <= maxGetRange then
		return abilityCR + maxAddedRange;
	elseif abilityCR > maxGetRange then
		return maxGetRange;
	else
		return abilityCR;
	end
end

-- Returns the wekes unit in a radious
function U.GetVulnerableWeakestUnit(bHero, bEnemy, nRadius, bot)
	local units = {};
	local weakest = nil;
	local weakestHP = 10000;
	if bHero then
		units = bot:GetNearbyHeroes(nRadius, bEnemy, BOT_MODE_NONE);
	else
		units = bot:GetNearbyLaneCreeps(nRadius, bEnemy);
	end
	for _,u in pairs(units) do
		if u:GetHealth() < weakestHP 
		   and U.CanCastOnNonMagicImmune(u) 
		then
			weakest = u;
			weakestHP = u:GetHealth();
		end
	end
	return weakest;
end

-- Returns the amount of creeps and allies in a radious surrounding target
function U.GetUnitCountAroundEnemyTarget(target, nRadius)
	local heroes = target:GetNearbyHeroes(nRadius, false, BOT_MODE_NONE);	
	local creeps = target:GetNearbyLaneCreeps(nRadius, false);	
	local Nh,Nc = 0,0;
	if heroes ~= nil then Nh = #heroes end
	if creeps ~= nil then Nc = #heroes end
	
	return Nh + Nc ;
--	return #heroes + #creeps;
end

-- Returns the list of enemy heroes surroinding the bot
function U.GetNumEnemyAroundMe(npcBot)
	local heroes = npcBot:GetNearbyHeroes(1000, true, BOT_MODE_NONE);	
	return #heroes;
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

-- Returns the nearest ally with no buff
function U.GetAllyWithNoBuff(nCastRange, sModifier, bot)
	local target = nil;
	local allies = bot:GetNearbyHeroes(nCastRange, false, BOT_MODE_NONE);
	for _,u in pairs(allies) do
		if U.IsValid(u) 
		   and not u:HasModifier(sModifier) 
		   and U.CanCastOnNonMagicImmune(u) 
		then
			target = u;
			break;
		end
	end
	return target;
end

-- Returns the nearest building with no buff
function U.GetBuildingWithNoBuff(nCastRange, sModifier, bot)
	local ancient = GetAncient(GetTeam());
	if not ancient:IsInvulnerable() and GetUnitToUnitDistance(ancient, bot) < nCastRange then
		return ancient;
	end
	local barracks = bot:GetNearbyBarracks(nCastRange, false);
	for _,u in pairs(barracks) do
		if not u:HasModifier(sModifier) and not u:IsInvulnerable() then
			return u;
		end
	end
	local towers = bot:GetNearbyTowers(nCastRange, false);
	for _,u in pairs(towers) do
		if not u:HasModifier(sModifier) and not u:IsInvulnerable() then
			return u;
		end
	end
	return nil;
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

-- Retruns wether the enemy is your target
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

-- Returns the real target of the bot
function U.GetProperTarget(bot)
	local target = bot:GetTarget();
	if target == nil then
		target = bot:GetAttackTarget();
	end
	return target;
end

-- Returns the list of human players
function U.GetHumanPlayers()
	local listHumanPlayer = {};
	for i,id in pairs(GetTeamPlayers(GetTeam())) do
		if not IsPlayerBot(id) then
			local humanPlayer = GetTeamMember(i);
			if humanPlayer ~=  nil then
				table.insert(listHumanPlayer, humanPlayer);
			end
		end
	end
	return listHumanPlayer;
end

function U.IsHumanPlayerCanKill(target)
	-- local bot = GetBot();
	-- if target:GetTeam() ~= bot:GetTeam() and target:IsHero() then
		-- local humanPlayers = U.GetHumanPlayers();
		-- if U.IsHumanPingNotToKill(target, humanPlayers) then
			-- print("Human Pinging! You're not Allowed to Kill The Target!");
			-- return true;
		-- elseif U.IsHumanCanKillTheTarget(target, humanPlayers) then
			-- print("Human Can Kill The Target! You're not Allowed to Kill The Target!");	
			-- return true;
		-- end
	-- end
	return false;
end

-- Returns wether a ping indicates to not kill a target
function U.IsHumanPingNotToKill(target, listHumanPlayer)
	for _,human in pairs(listHumanPlayer) do
		if human ~= nil and not human:IsNull() and human:GetAttackTarget() == target then
			local ping = human:GetMostRecentPing();
			if ping ~= nil and not ping.normal_ping and GetUnitToLocationDistance(target, ping.location) <= 1200 and GameTime() - ping.time < 3.0 then
				return true;
			end	
		end	
	end
	return false;
end

-- Returns wether the human player can kill his target
function U.IsHumanCanKillTheTarget(target, listHumanPlayer)
	local total_damage = 0;
	for _,human in pairs(listHumanPlayer) do
		if human ~= nil and not human:IsNull() and human:GetAttackTarget() == target then
			local damage = human:GetEstimatedDamageToTarget(true, target, 2.0, DAMAGE_TYPE_ALL);
			total_damage = total_damage + damage;
		end	
	end
	if total_damage > target:GetHealth() then
		print("Total Damage:"..tostring(total_damage))
		return true;
	end
	return false;
end

-- Returns a list of all allies near a location
function U.GetAlliesNearLoc(vLoc, nRadius)
	local allies = {};
	for i,id in pairs(GetTeamPlayers(GetTeam())) do
		local member = GetTeamMember(i);
		if member ~= nil and member:IsAlive() and GetUnitToLocationDistance(member, vLoc) <= nRadius then
			table.insert(allies, member);
		end
	end
	return allies;
end

-- Returns wheter an enemy creep is between the bot and its target
function U.IsEnemyCreepBetweenMeAndTarget(hSource, hTarget, vLoc, nRadius)
	local vStart = hSource:GetLocation();
	local vEnd = vLoc;
	local creeps = hSource:GetNearbyLaneCreeps(1600, true);
	for i,creep in pairs(creeps) do
		local tResult = PointToLineDistance(vStart, vEnd, creep:GetLocation());
		if tResult ~= nil and tResult.within and tResult.distance <= nRadius + 50 then
			return true;
		end
	end
	creeps = hTarget:GetNearbyLaneCreeps(1600, false);
	for i,creep in pairs(creeps) do
		local tResult = PointToLineDistance(vStart, vEnd, creep:GetLocation());
		if tResult ~= nil and tResult.within and tResult.distance <= nRadius + 50 then
			return true;
		end
	end
	return false;
end

-- Returns wheter an ally creep is between the bot and its target
function U.IsAllyCreepBetweenMeAndTarget(hSource, hTarget, vLoc, nRadius)
	local vStart = hSource:GetLocation();
	local vEnd = vLoc;
	local creeps = hSource:GetNearbyLaneCreeps(1600, false);
	for i,creep in pairs(creeps) do
		local tResult = PointToLineDistance(vStart, vEnd, creep:GetLocation());
		if tResult ~= nil and tResult.within and tResult.distance <= nRadius + 50 then
			return true;
		end
	end
	creeps = hTarget:GetNearbyLaneCreeps(1600, true);
	for i,creep in pairs(creeps) do
		local tResult = PointToLineDistance(vStart, vEnd, creep:GetLocation());
		if tResult ~= nil and tResult.within and tResult.distance <= nRadius + 50 then
			return true;
		end
	end
	return false;
end

-- Returns wheter a creep is between the bot and its target
function U.IsCreepBetweenMeAndTarget(hSource, hTarget, vLoc, nRadius)
	if not U.IsAllyCreepBetweenMeAndTarget(hSource, hTarget, vLoc, nRadius) then
		return U.IsEnemyCreepBetweenMeAndTarget(hSource, hTarget, vLoc, nRadius);
	end
	return true;
end

-- Returns wheter an enemy is between the bot and its target
function U.IsEnemyHeroBetweenMeAndTarget(hSource, hTarget, vLoc, nRadius)
	local vStart = hSource:GetLocation();
	local vEnd = vLoc;
	local heroes = hSource:GetNearbyHeroes(1600, true, BOT_MODE_NONE);
	for i,hero in pairs(heroes) do
		if hero ~= hTarget  then
			local tResult = PointToLineDistance(vStart, vEnd, hero:GetLocation());
			if tResult ~= nil and tResult.within and tResult.distance <= nRadius + 50 then
				return true;
			end
		end
	end
	heroes = hTarget:GetNearbyHeroes(1600, false, BOT_MODE_NONE);
	for i,hero in pairs(heroes) do
		if hero ~= hTarget  then
			local tResult = PointToLineDistance(vStart, vEnd, hero:GetLocation());
			if tResult ~= nil and tResult.within and tResult.distance <= nRadius + 50 then
				return true;
			end
		end
	end
	return false;
end

-- Returns wheter an ally is between the bot and its target
function U.IsAllyHeroBetweenMeAndTarget(hSource, hTarget, vLoc, nRadius)
	local vStart = hSource:GetLocation();
	local vEnd = vLoc;
	local heroes = hSource:GetNearbyHeroes(1600, false, BOT_MODE_NONE);
	for i,hero in pairs(heroes) do
		if hero ~= hSource then
			local tResult = PointToLineDistance(vStart, vEnd, hero:GetLocation());
			if tResult ~= nil and tResult.within and tResult.distance <= nRadius + 50 then
				return true;
			end
		end
	end
	heroes = hTarget:GetNearbyHeroes(1600, true, BOT_MODE_NONE);
	for i,hero in pairs(heroes) do
		if hero ~= hSource then
			local tResult = PointToLineDistance(vStart, vEnd, hero:GetLocation());
			if tResult ~= nil and tResult.within and tResult.distance <= nRadius + 50 then
				return true;
			end
		end
	end
	return false;
end

-- Returns wheter a hero is between the bot and its target
function U.IsHeroBetweenMeAndTarget(hSource, hTarget, vLoc, nRadius)
	if not U.IsAllyHeroBetweenMeAndTarget(hSource, hTarget, vLoc, nRadius) then
		return U.IsEnemyHeroBetweenMeAndTarget(hSource, hTarget, vLoc, nRadius);
	end
	return true;
end

-- Returns wheter the sand king minon is nearby
function U.IsSandKingThere(bot, nCastRange, fTime)
	local enemies = bot:GetNearbyHeroes(1600, true, BOT_MODE_NONE);
	for _,enemy in pairs(enemies) do
		if enemy:GetUnitName() == "npc_dota_hero_sand_king" and enemy:HasModifier('modifier_sandking_sand_storm_invis') then
			return true,  enemy:GetLocation();
		end
	end
	return false, nil;
end

-- Returns the ultimate ability
function U.GetUltimateAbility(bot)
	--print(tostring(bot:GetAbilityInSlot(5):GetName()))
	return bot:GetAbilityInSlot(5);
end

-- Returns wether the bot can use the refreshener shard
function U.CanUseRefresherShard(bot)
	local ult = U.GetUltimateAbility(bot);
	if ult ~= nil and ult:IsPassive() == false then
		local ultCD = ult:GetCooldown();
		local manaCost = ult:GetManaCost();
		if bot:GetMana() >= manaCost and ult:GetCooldownTimeRemaining() >= ultCD/2 then
			return true;
		end
	end
	return false;
end

-- Returns the unit with the highest cooldoown on its ult
function U.GetMostUltimateCDUnit()
	local unit = nil;
	local maxCD = 0;
	for i,id in pairs(GetTeamPlayers(GetTeam())) do
		if IsHeroAlive(id) then
			local member = GetTeamMember(i);
			if member ~= nil and member:IsAlive() and member:GetUnitName() ~= "npc_dota_hero_nevermore" 
			then
			    if member:GetUnitName() == "npc_dota_hero_silencer" or member:GetUnitName() == "npc_dota_hero_warlock"
				then
				    return member;
				end
				local ult = U.GetUltimateAbility(member);
				--print(member:GetUnitName()..tostring(ult:GetName())..tostring(ult:GetCooldown()))
				if ult ~= nil and ult:IsPassive() == false and ult:GetCooldown() >= maxCD then
					unit = member;
					maxCD = ult:GetCooldown();
				end
			end
		end
	end
	return unit;
end

-- Returns wheter the bot may use the refreshener orb
function U.CanUseRefresherOrb(bot)
	local ult = U.GetUltimateAbility(bot);
	if ult ~= nil and ult:IsPassive() == false then
		local ultCD = ult:GetCooldown();
		local manaCost = ult:GetManaCost();
		if bot:GetMana() >= manaCost+375 and ult:GetCooldownTimeRemaining() >= ultCD/2 then
			return true;
		end
	end
	return false;
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

function U.IsSuspiciousIllusionOld(npcTarget)
	--TO DO Need to detect enemy hero's illusions better
	local bot = GetBot();
	--Detect allies's illusions
	if npcTarget:IsIllusion() 
		or npcTarget:HasModifier('modifier_illusion') 
		or npcTarget:HasModifier('modifier_phantom_lancer_doppelwalk_illusion') 
		or npcTarget:HasModifier('modifier_phantom_lancer_juxtapose_illusion')
		or npcTarget:HasModifier('modifier_darkseer_wallofreplica_illusion') 
		or npcTarget:HasModifier('modifier_terrorblade_conjureimage')	   
	then
		return true;
	else
	    -- Detect replicate and wall of replica illusions
	    if GetGameMode() ~= GAMEMODE_MO then
			if npcTarget:GetTeam() ~= bot:GetTeam() then
				local TeamMember = GetTeamPlayers(GetTeam()); 
				for i = 1, #TeamMember
				do
					local ally = GetTeamMember(i);  
					if ally ~= nil 
						and ally:GetUnitName() == npcTarget:GetUnitName() 
					then
						return true;
					end
				end
			end
		end
		return false;
	end
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
			U.Report("真身已死这是幻像:",npcTarget:GetUnitName());
			return true;
		end	

		if GetHeroLevel( tID ) > npcTarget:GetLevel()
		then
			U.Report("等级比真身低这是幻像:",npcTarget:GetUnitName());
			return true;
		end
		
		-- local TeamMember = GetTeamPlayers(GetTeam()); 
		-- for i = 1, #TeamMember
		-- do
			-- local ally = GetTeamMember(i);  
			-- if ally ~= nil 
				-- and ally:GetUnitName() == npcTarget:GetUnitName() 
				-- and ally:GetUnitName() ~= GetSelectedHeroName(tID)
			-- then
				-- U.Report("和真身不一致这是幻像:",npcTarget:GetUnitName());
				-- return true;
			-- end
		-- end	
		
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

-- This function decides weather you can cast on targt (depending on external advanced conditions)
function U.CanCastOnTargetAdvanced( npcTarget )
	return npcTarget:CanBeSeen() and not npcTarget:IsMagicImmune() and not npcTarget:IsInvulnerable() and not U.HasForbiddenModifier(npcTarget)
end

-- Returns weter the dmg will kill the target
function U.CanKillTarget(npcTarget, dmg, dmgType)
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

-- Dictates wheter the bot should escape
function U.ShouldEscape(npcBot)
	local tableNearbyEnemyHeroes = npcBot:GetNearbyHeroes( 1000, true, BOT_MODE_NONE );
	if ( npcBot:WasRecentlyDamagedByAnyHero(2.0) or npcBot:WasRecentlyDamagedByTower(2.0) or ( tableNearbyEnemyHeroes ~= nil and #tableNearbyEnemyHeroes > 1  ) )
	then
		return true;
	end
end

-- Searches for Roshan
function U.IsRoshan(npcTarget)
	return npcTarget ~= nil and npcTarget:IsAlive() and string.find(npcTarget:GetUnitName(), "roshan");
end

-- Returns wheter the target is disabled
function U.IsDisabled(enemy, npcTarget)
	if enemy then
		return npcTarget:IsRooted( ) or npcTarget:IsStunned( ) or npcTarget:IsHexed( ) or npcTarget:IsNightmared() or U.IsTaunted(npcTarget); 
	else
		return npcTarget:IsRooted( ) or npcTarget:IsStunned( ) or npcTarget:IsHexed( ) or npcTarget:IsNightmared() or npcTarget:IsSilenced( ) or U.IsTaunted(npcTarget);
	end
end

-- Returns wheter the target is slowed
function U.IsSlowed(bot)
	local speedPlusBoots =  U.GetUpgradedSpeed(bot);
	return bot:GetCurrentMovementSpeed() < speedPlusBoots;
end

-- Returns the bot upgraded speed
function U.GetUpgradedSpeed(bot)
	for i=0,5 do
		local item = bot:GetItemInSlot(i);
		if item ~= nil and listBoots[item:GetName()] ~= nil then
			return bot:GetBaseMovementSpeed()+listBoots[item:GetName()];
		end
	end
	return bot:GetBaseMovementSpeed();
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

function U.CanNotUseAbility(npcBot)

	return U.CantUseAbility(npcBot);
	
	-- return npcBot:IsCastingAbility() 
		-- or npcBot:IsUsingAbility() 
		-- or npcBot:IsInvulnerable() 
		-- or npcBot:IsChanneling() 
		-- or npcBot:IsSilenced() 
		-- or npcBot:IsStunned()
		-- or npcBot:HasModifier("modifier_doom_bringer_doom");
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

-- Returns the team fountain status
function U.GetTeamFountain()
	local Team = GetTeam();
	if Team == TEAM_DIRE then
		return DB;
	else
		return RB;
	end
end

-- Returns the combo item for the unit
function U.GetComboItem(npcBot, item_name)
	local Slot = npcBot:FindItemSlot(item_name);
	if Slot >= 0 and Slot <= 5 then
		return npcBot:GetItemInSlot(Slot);
	else
		return nil;
	end
end

-- Returns the unit whit the most hp
function U.GetMostHpUnit(ListUnit)
	local mostHpUnit = nil;
	local maxHP = 0;
	for _,unit in pairs(ListUnit)
	do
		local uHp = unit:GetHealth();
		if  uHp > maxHP then
			mostHpUnit = unit;
			maxHP = uHp;
		end
	end
	return mostHpUnit
end

-- Returns wheter a unit still has a certain modifier
function U.StillHasModifier(npcTarget, modifier)
	return npcTarget:HasModifier(modifier);
end

-- Returns wheter an ability or item is allowed to spam
function U.AllowedToSpam(npcBot, nManaCost)
	if npcBot:HasModifier("modifier_silencer_curse_of_the_silent") then return false end;

	return ( npcBot:GetMana() - nManaCost ) / npcBot:GetMaxMana() >= fSpamThreshold;
end

-- Returns wheter a proyectile is incomming
function U.IsProjectileIncoming(npcBot, range)
	local incProj = npcBot:GetIncomingTrackingProjectiles()
	for _,p in pairs(incProj)
	do
		if GetUnitToLocationDistance(npcBot, p.location) < range and not p.is_attack and p.is_dodgeable then
			return true;
		end
	end
	return false;
end

-- Returns the unit whit the most hp percentage
function U.GetMostHPPercent(listUnits, magicImmune)
	local mostPHP = 0;
	local mostPHPUnit = nil;
	for _,unit in pairs(listUnits)
	do
		local uPHP = unit:GetHealth() / unit:GetMaxHealth()
		if ( ( magicImmune and U.CanCastOnMagicImmune(unit) ) or ( not magicImmune and U.CanCastOnNonMagicImmune(unit) ) ) 
			and uPHP > mostPHP  
		then
			mostPHPUnit = unit;
			mostPHP = uPHP;
		end
	end
	return mostPHPUnit;
end

-- Returns the unit which can be killed with a certain damage
function U.GetCanBeKilledUnit(units, nDamage, nDmgType, magicImmune)
	local target = nil;
	for _,unit in pairs(units)
	do
		if ( ( magicImmune and U.CanCastOnMagicImmune(unit) ) or ( not magicImmune and U.CanCastOnNonMagicImmune(unit) ) ) 
			   and U.CanKillTarget(unit, nDamage, nDmgType) 
		then
			unitKO = target;	
		end
	end
	return target;
end

-- Returns the correct location of target (for skill shots)
function U.GetCorrectLoc(target, delay)
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

-- Returns the closest unit to a certain unit
function U.GetClosestUnit(units)
	local target = nil;
	if units ~= nil and #units >= 1 then
		return units[1];
	end
	return target;
end

-- Returns the enemy fountain status
function U.GetEnemyFountain()
	local Team = GetTeam();
	if Team == TEAM_DIRE then
		return RB;
	else
		return DB;
	end
end

-- returns the best escape rute
function U.GetEscapeLoc()
	local bot = GetBot();
	local team = GetTeam();
	if bot:DistanceFromFountain() > 2500 then
		return GetAncient(team):GetLocation();
	else
		if team == TEAM_DIRE then
			return DB;
		else
			return RB;
		end
	end
end

-- Returns wheter the bot is stuck
function U.IsStuck2(npcBot)
	if npcBot.stuckLoc ~= nil and npcBot.stuckTime ~= nil then 
		local EAd = GetUnitToUnitDistance(npcBot, GetAncient(GetOpposingTeam()));
		if DotaTime() > npcBot.stuckTime + 5.0 and GetUnitToLocationDistance(npcBot, npcBot.stuckLoc) < 25  
           and npcBot:GetCurrentActionType() == BOT_ACTION_TYPE_MOVE_TO and EAd > 2200		
		then
			print(npcBot:GetUnitName().." is stuck")
			--DebugPause();
			return true;
		end
	end
	return false
end

-- Returns wheter the bot is stuck (old)
function U.IsStuck(npcBot)
	if npcBot.stuckLoc ~= nil and npcBot.stuckTime ~= nil then 
		local attackTarget = npcBot:GetAttackTarget();
		local EAd = GetUnitToUnitDistance(npcBot, GetAncient(GetOpposingTeam()));
		local TAd = GetUnitToUnitDistance(npcBot, GetAncient(GetTeam()));
		local Et = npcBot:GetNearbyTowers(450, true);
		local At = npcBot:GetNearbyTowers(450, false);
		if npcBot:GetCurrentActionType() == BOT_ACTION_TYPE_MOVE_TO and attackTarget == nil and EAd > 2200 and TAd > 2200 and #Et == 0 and #At == 0  
		   and DotaTime() > npcBot.stuckTime + 5.0 and GetUnitToLocationDistance(npcBot, npcBot.stuckLoc) < 25    
		then
			print(npcBot:GetUnitName().." is stuck")
			return true;
		end
	end
	return false
end

-- Returns wheter the unit is in the player's table
function U.IsExistInTable(u, tUnit)
	for _,t in pairs(tUnit) do
		if u:GetUnitName() == t:GetUnitName() then
			return true;
		end
	end
	return false;
end 

-- Returns the number of invincible units in a location
function U.FindNumInvUnitInLoc(pierceImmune, bot, nRange, nRadius, loc)
	local nUnits = 0;
	if nRange > 1600 then nRange = 1600 end
	local units = bot:GetNearbyHeroes(nRange, true, BOT_MODE_NONE);
	for _,u in pairs(units) do
		if ( ( pierceImmune and U.CanCastOnMagicImmune(u) ) or ( not pierceImmune and U.CanCastOnNonMagicImmune(u) ) ) and GetUnitToLocationDistance(u, loc) <= nRadius then
			nUnits = nUnits + 1;
		end
	end
	return nUnits;
end

-- Returns the number of lane creep in a loc
function U.FindNumLaneCreepsInLoc(bot, nRange, nRadius, loc)
	local nUnits = 0;
	if nRange > 1600 then nRange = 1600 end
	local units = bot:GetNearbyLaneCreeps(nRange, true);
	for _,u in pairs(units) do
		if GetUnitToLocationDistance(u, loc) <= nRadius 
		then
			nUnits = nUnits + 1;
		end
	end
	return nUnits;
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

-- Returns if a crep can be a controlled creep
function U.CanBeDominatedCreeps(name)
	return name == "npc_dota_neutral_centaur_khan"
		 or name == "npc_dota_neutral_polar_furbolg_ursa_warrior"	
		 or name == "npc_dota_neutral_satyr_hellcaller"	
		 or name == "npc_dota_neutral_dark_troll_warlord"	
		 or name == "npc_dota_neutral_mud_golem"	
		 or name == "npc_dota_neutral_harpy_storm"	
		 or name == "npc_dota_neutral_ogre_magi"	
		 or name == "npc_dota_neutral_alpha_wolf"	
		 or name == "npc_dota_neutral_enraged_wildkin"	
		 or name == "npc_dota_neutral_satyr_trickster"	
end

-- Returns the distance to enemy fountain
function U.GetDistanceFromEnemyFountain()
    local npcBot = GetBot();
	local EnemyFountain = U.GetEnemyFountain();
	local Distance = GetUnitToLocationDistance(npcBot,EnemyFountain);
	return Distance;
end

-- Returns the dstance of an objective to the enemy fountain
function U.DistanceFromEnemyFountain(npcBot)
	local EnemyFountain = U.GetEnemyFountain();
	local Distance = GetUnitToLocationDistance(npcBot,EnemyFountain);
	return Distance;
end

-- Returns the fountain object (your tem's fountain)
function U.GetOurFountain()
	local Team = GetTeam();
	if Team == TEAM_DIRE then
		return DB;
	else
		return RB;
	end
end

-- Returns distance to the teams fountain
function U.GetDistanceFromOurFountain()
    local npcBot = GetBot();
	local OurFountain = U.GetOurFountain();
	local Distance = GetUnitToLocationDistance(npcBot,OurFountain);
	return Distance;
end

-- Returns distance of objective to the teams fountain
function U.DistanceFromOurFountain(npcBot)
	local OurFountain = U.GetOurFountain();
	local Distance = GetUnitToLocationDistance(npcBot,OurFountain);
	return Distance;
end

-- Returns the number of heroes around target
function U.GetOtherAllyHeroCountAroundTarget(target, nRadius, npcBot)
			
	local heroes = U.GetAlliesNearLoc(target:GetLocation(), nRadius)
	if heroes[1] ~= nil
	then
		for _,ally in pairs(heroes)
		do
			if U.IsValid(ally) 
			   and ally == npcBot
			then
				return #heroes - 1
			end
		end
	end
	return #heroes;
end

function U.GetAllyCreepNearLoc(vLoc, nRadius, npcBot)
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

function U.GetAllyUnitCountAroundEnemyTarget(target, nRadius,npcBot)
	local heroes = U.GetAlliesNearLoc(target:GetLocation(), nRadius)	
	local creeps = U.GetAllyCreepNearLoc(target:GetLocation(), nRadius, npcBot);	
	local Nh,Nc = 0,0;
	if heroes ~= nil then Nh = #heroes end
	if creeps ~= nil then Nc = #heroes end
	
	return Nh + Nc ;
end

function U.Num( ntable )
     if next(ntable) == nil 
	 then
           return 0
     end
	 
	 return #ntable
end

function U.GetLocationToLocationDistance(fLoc,sLoc)
	
	local x1=fLoc.x
	local x2=sLoc.x
	local y1=fLoc.y
	local y2=sLoc.y
	return math.sqrt(math.pow((y2-y1),2)+math.pow((x2-x1),2))

end

function U.GetUnitTowardDistanceLocation(npcBot,towardTarget,nDistance)
    local npcBotLocation = npcBot:GetLocation();
    local tempVector = (towardTarget:GetLocation() - npcBotLocation) / GetUnitToUnitDistance(npcBot,towardTarget);
	return npcBotLocation + nDistance * tempVector;
end

function U.GetLocationTowardDistanceLocation(npcBot,towardLocation,nDistance)
    local npcBotLocation = npcBot:GetLocation();
    local tempVector = (towardLocation - npcBotLocation) / GetUnitToLocationDistance(npcBot,towardLocation);
	return npcBotLocation + nDistance * tempVector;
end

function U.GetFaceTowardDistanceLocation(npcBot,nDistance)
	local npcBotLocation = npcBot:GetLocation();
	local tempRadians = npcBot:GetFacing() * math.pi / 180;
	local tempVector = Vector(math.cos(tempRadians),math.sin(tempRadians));
	return npcBotLocation + nDistance * tempVector;
end

local ReTime = 9999999;
function U.Report(nMessage,nNumber)
	if ReTime < DotaTime() - 5
	then
		ReTime = DotaTime();	
		GetBot():ActionImmediate_Chat(nMessage..string.gsub(tostring(nNumber),"npc_dota_",""),true);
	end
end

local PingTime = -90;
function U.PingLocation(bot,vLoc)
	if PingTime < DotaTime() - 2
	then
		PingTime = DotaTime();
		bot:ActionImmediate_Ping( vLoc.x, vLoc.y, false );
	end
end

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

function U.FindCastLocation(npcBot,npcTarget,nCastRange,nRadius,nTime)

	local nFutureLoc = U.GetCorrectLoc(npcTarget,nTime);
	local nDistance = GetUnitToLocationDistance(npcBot,nFutureLoc);
	
	if nDistance > nCastRange + nRadius
	then
		return nil;
	end
	
	if nDistance > nCastRange - nRadius *0.62
	then
		return U.GetLocationTowardDistanceLocation(npcBot,nFutureLoc,nCastRange);
	end

	return U.GetLocationTowardDistanceLocation(npcBot,nFutureLoc,nDistance + nRadius *0.38);

end

function U.Temary(one,two,three)
	 if one then return two end
	 return three;
end

function U.IsPTHero(bot)
	return  bot:GetUnitName() == "npc_dota_hero_viper"
			or bot:GetUnitName() == "npc_dota_hero_sniper"
			or bot:GetUnitName() == "npc_dota_hero_bristleback"
			or bot:GetUnitName() == "npc_dota_hero_drow_ranger"
			or bot:GetUnitName() == "npc_dota_hero_chaos_knight" 
			or bot:GetUnitName() == "npc_dota_hero_nevermore"
			or bot:GetUnitName() == "npc_dota_hero_arc_warden"
end

function U.ConsiderPT()
	local bot = GetBot();

	if     bot:IsChanneling() 
		or bot:IsCastingAbility()
		or bot:IsUsingAbility()		
		or bot:IsInvisible() 
		or bot:IsMuted()
		or bot:IsHexed()
		or bot:HasModifier("modifier_doom_bringer_doom")
		or bot:HasModifier("modifier_fountain_aura_buff")
		or bot:NumQueuedActions() > 0
		or bot:IsStunned() 		
	    or not bot:IsAlive()
	then 
		return BOT_ACTION_DESIRE_NONE;
	end	

	local mode = bot:GetActiveMode();
	local pt = U.IsItemAvailable("item_power_treads");
	if pt ~= nil and pt:IsFullyCastable()  	
	then
		if (   bot:HasModifier("modifier_flask_healing")
		   or  bot:HasModifier("modifier_clarity_potion")
		   or  bot:HasModifier("modifier_item_urn_heal")
		   or  bot:HasModifier("modifier_filler_heal")
		   or  bot:HasModifier("modifier_item_spirit_vessel_heal")
		   or  bot:HasModifier("modifier_bottle_regeneration") )
		   and  mode ~= BOT_MODE_ATTACK 
		   and  mode ~= BOT_MODE_RETREAT 
		then
			if pt:GetPowerTreadsStat() ~= ATTRIBUTE_INTELLECT
			then
				return	BOT_ACTION_DESIRE_HIGH;
			end	
		elseif  mode == BOT_MODE_RETREAT 
				or bot:GetHealth()/bot:GetMaxHealth() < 0.2
				or (pt:GetPowerTreadsStat() == ATTRIBUTE_STRENGTH and bot:GetHealth()/bot:GetMaxHealth() < 0.25)
				or U.IsProjectileIncoming(bot, 1600)
			then
				if pt:GetPowerTreadsStat() ~= ATTRIBUTE_STRENGTH
				then
					return	BOT_ACTION_DESIRE_HIGH;
				end
		elseif  mode == BOT_MODE_ATTACK 
			then
				if  U.ShouldSwitchPTStat(bot,pt) 
				then
					return	BOT_ACTION_DESIRE_HIGH;
				end
		else
			local enemies = bot:GetNearbyHeroes( 1600, true, BOT_MODE_NONE );
			local creeps  = bot:GetNearbyCreeps(1200,true);
			local target  = U.GetProperTarget(bot);
			if  #creeps == 0
				and  #enemies == 0 
				and  (target == nil or GetUnitToUnitDistance(bot,target) > 1600)
				and  bot:DistanceFromFountain() > 400
			then
				if pt:GetPowerTreadsStat() ~= ATTRIBUTE_INTELLECT
				then
					return	BOT_ACTION_DESIRE_HIGH;
				end
			elseif U.ShouldSwitchPTStat(bot,pt)
				then
					return	BOT_ACTION_DESIRE_HIGH;	
			end
		end
	end	
	
	return	BOT_ACTION_DESIRE_NONE;
end

function U.SwitchPT(bot)
	local pt = U.IsItemAvailable("item_power_treads");
	if pt~=nil and pt:IsFullyCastable()   
	then
         bot:Action_UseAbility(pt);
	end
end

function U.QueueSwitchPtToINT(bot)
	local pt = U.IsItemAvailable("item_power_treads");
	if pt~=nil and pt:IsFullyCastable()   
	then
		if pt:GetPowerTreadsStat() == ATTRIBUTE_INTELLECT
		then
			bot:ActionQueue_UseAbility(pt);
			bot:ActionQueue_UseAbility(pt);
			return;
		elseif pt:GetPowerTreadsStat() == ATTRIBUTE_STRENGTH
			then
				bot:ActionQueue_UseAbility(pt);
				return;
		end
	end
end

function U.IsItemAvailable(item_name)
	local bot = GetBot();
    local slot = bot:FindItemSlot(item_name);
	
	if slot < 0 then return nil end
	
	if bot:GetItemSlotType(slot) == ITEM_SLOT_TYPE_MAIN then
		return bot:GetItemInSlot(slot);
	end
	
    return nil;
end

function U.IsPTReady(bot,status)
	if  not bot:IsAlive()
		or bot:IsMuted()
		or bot:IsInvisible()
		or bot:GetHealth()/bot:GetMaxHealth() < 0.25
	then
		return true;
	end
	
	if status == ATTRIBUTE_INTELLECT 
	then 
		status = ATTRIBUTE_AGILITY;
	elseif status == ATTRIBUTE_AGILITY
		then
			status = ATTRIBUTE_INTELLECT;
	end
	
    local pt = U.IsItemAvailable("item_power_treads");
	if pt~=nil and pt:IsFullyCastable()
	then
		if pt:GetPowerTreadsStat() ~= status
		then
			return false;
		end
	end
	
	return true;
end

function U.ConsiderMagicWand()
	
	local bot = GetBot();
	if  DotaTime() < 0
		or not bot:IsAlive()
		or bot:IsChanneling() 
		or bot:IsCastingAbility()	
		or bot:IsInvisible() 
		or bot:IsMuted()
		or bot:IsHexed()
		or bot:HasModifier("modifier_doom_bringer_doom")
		or bot:NumQueuedActions() > 0
		or bot:IsStunned() 		
	then
		return BOT_ACTION_DESIRE_NONE;
	end
	
	local wand = U.IsItemAvailable("item_magic_wand"); --魔杖
	if wand ~=nil and wand:IsFullyCastable() 
	then
		local tableNearbyEnemyHeroes = bot:GetNearbyHeroes( 700, true, BOT_MODE_NONE );
		local nEnemyCount = #tableNearbyEnemyHeroes;
		local nHPrate = bot:GetHealth()/bot:GetMaxHealth();
		local nMPrate = bot:GetMana()/bot:GetMaxMana();
		local nLostHP = bot:GetMaxHealth() - bot:GetHealth();
		local nLostMP = bot:GetMaxMana() - bot:GetMana();
		local nCharges = wand:GetCurrentCharges();
		
		if ( ((nHPrate < 0.4 or nMPrate < 0.3) and  nEnemyCount >= 1 and nCharges >= 1 )
			or( nHPrate < 0.7  and nMPrate < 0.7 and nCharges >= 12  ) 
			or(nCharges >= 19 and bot:GetItemInSlot(5) ~= nil and (nHPrate <= 0.5 or nMPrate <= 0.5)) ) 				
		then
			return BOT_ACTION_DESIRE_HIGH;
		end		
	end
	
	return BOT_ACTION_DESIRE_NONE;
end

function U.CastWand(bot)	
	local wand = U.IsItemAvailable("item_magic_wand");
	if wand~=nil and wand:IsFullyCastable()   
	then
         bot:Action_UseAbility(wand);
	end
end

function U.ShouldSwitchPTStat(bot,pt)
	
	local ptStatus = pt:GetPowerTreadsStat();
	if ptStatus == ATTRIBUTE_INTELLECT 
	then 
		ptStatus = ATTRIBUTE_AGILITY;
	elseif ptStatus == ATTRIBUTE_AGILITY
		then
			ptStatus = ATTRIBUTE_INTELLECT;
	end
    
	return bot:GetPrimaryAttribute() ~= ptStatus;
end

function U.IsOtherAllysTarget(unit)
	local bot = GetBot();
	local allys = bot:GetNearbyHeroes(800,false,BOT_MODE_NONE);
	for _,ally in pairs(allys) do
		if U.IsValid(ally)
		    and ally ~= bot 
			and U.GetProperTarget(ally) == unit 
		then
			return true;
		end
	end
	return false;
end

function U.IsAllysTarget(unit)
	local bot = GetBot();
	local allys = bot:GetNearbyHeroes(800,false,BOT_MODE_NONE);
	for _,ally in pairs(allys) do
		if  U.IsValid(ally)
			and U.GetProperTarget(ally) == unit 
		then
			return true;
		end
	end
	return false;
end

function U.IsKeyWordUnitClass(keyWord,Unit)
	if string.find(Unit:GetUnitName(), keyWord) ~=nil 
	then
		return true;  
	end
	return false;
end

function U.IsValid(nTarget)
	return nTarget ~= nil and nTarget:IsAlive() and nTarget:CanBeSeen(); 
end

function U.DesireLowToHigh(nValue,nMin,nMax)
    return RemapValClamped(nValue,nMin,nMax,BOT_ACTION_DESIRE_LOW,BOT_ACTION_DESIRE_HIGH);	
end

function U.DesireMoToVH(nValue,nMin,nMax)
    return RemapValClamped(nValue,nMin,nMax,BOT_ACTION_DESIRE_MODERATE,BOT_ACTION_DESIRE_VERYHIGH);	
end

function U.DesireHighToVH(nValue,nMin,nMax)
    return RemapValClamped(nValue,nMin,nMax,BOT_ACTION_DESIRE_HIGH,BOT_ACTION_DESIRE_VERYHIGH);	
end

function U.IsSpecialHero(bot)
    
	return  bot:GetUnitName() == "npc_dota_hero_chaos_knight" 
		 or bot:GetUnitName() == "npc_dota_hero_drow_ranger"
		 or bot:GetUnitName() == "npc_dota_hero_viper" 
		 or bot:GetUnitName() == "npc_dota_hero_silencer"			 
		 or bot:GetUnitName() == "npc_dota_hero_crystal_maiden"

end

function U.IsMoving(bot)
	if not bot:IsAlive() then return false end
	
	local loc = bot:GetExtrapolatedLocation(0.6);
	if GetUnitToLocationDistance(bot,loc) > 120
	then
		return true;
	end
	return false;

end

function U.IsRunning(bot)
	if not bot:IsAlive() then return false end
	
	return bot:GetAnimActivity() == ACTIVITY_RUN ;

end

function U.GetModifierTime(bot,nMoName)
	local npcModifier = bot:NumModifiers();
	for i = 0, npcModifier 
	do
		if bot:GetModifierName(i) == nMoName 
		then
			return bot:GetModifierRemainingDuration(i);
		end
	end
	return 0;
end


function U.IsTeamActivityCount(bot,nCount)
	local numPlayer =  GetTeamPlayers(GetTeam());
	local nCount = 0;
	for i = 1, #numPlayer
	do
		local member =  GetTeamMember(i);
		if member ~= nil and member:IsAlive() and member ~= bot
		then
		    if U.AlliesCount(member,1400) >= nCount
			then
				return true;
			end
		end
	end
	return false;
end



function U.GetTeamFightAlliesCount(bot)
	local numPlayer =  GetTeamPlayers(GetTeam());
	local nCount = 0;
	for i = 1, #numPlayer
	do
		local member =  GetTeamMember(i);
		if member ~= nil and member:IsAlive() and member ~= bot
		then
		    if U.IsInTeamFight(member,1200)
			then
				nCount = nCount +1;
			end
		end
	end
	return nCount;
end

function U.IsHaveRoshanDesire(bot,nDesire)
	
	return GetRoshanDesire() > nDesire;

end

function U.IsHaveFarmLaneDesire(bot,nLane,nDesire)
	
	return GetFarmLaneDesire(nLane) > nDesire
	
end

function U.IsHaveDefendLaneDesire(bot,nLane,nDesire)
	
	return GetDefendLaneDesire(nLane) > nDesire   
	
end

function U.IsHavePushLaneDesire(bot,nLane,nDesire)
	
	return GetPushLaneDesire(nLane) > nDesire   
	
end


function U.GetMostFarmLaneDesire()
	local nTop = GetFarmLaneDesire(LANE_TOP);
	local nMid = GetFarmLaneDesire(LANE_MID);
	local nBot = GetFarmLaneDesire(LANE_BOT);
	
	if nTop > nMid and nTop > nBot
	then
		return LANE_TOP,nTop;
	end
	
	if nBot > nMid and nBot > nTop
	then
		return LANE_BOT,nBot;
	end
	
	return LANE_MID,nMid;
end

function U.GetMostDefendLaneDesire()
	local nTop = GetDefendLaneDesire(LANE_TOP);
	local nMid = GetDefendLaneDesire(LANE_MID);
	local nBot = GetDefendLaneDesire(LANE_BOT);
	
	if nTop > nMid and nTop > nBot
	then
		return LANE_TOP,nTop;
	end
	
	if nBot > nMid and nBot > nTop
	then
		return LANE_BOT,nBot;
	end
	
	return LANE_MID,nMid;
end

function U.GetPushLaneLaneDesire()
	local nTop = GetPushLaneDesire(LANE_TOP);
	local nMid = GetPushLaneDesire(LANE_MID);
	local nBot = GetPushLaneDesire(LANE_BOT);
	
	if nTop > nMid and nTop > nBot
	then
		return LANE_TOP,nTop;
	end
	
	if nBot > nMid and nBot > nTop
	then
		return LANE_BOT,nBot;
	end
	
	return LANE_MID,nMid;
end


function U.IsSpecialCarry(bot)
    
	return  bot:GetUnitName() == "npc_dota_hero_abaddon" 
		 or bot:GetUnitName() == "npc_dota_hero_dragon_knight"
		 or bot:GetUnitName() == "npc_dota_hero_bristleback" 
		 or bot:GetUnitName() == "npc_dota_hero_alchemist"			 
		 or bot:GetUnitName() == "npc_dota_hero_kunkka"
		 or bot:GetUnitName() == "npc_dota_hero_sniper"
		 or bot:GetUnitName() == "npc_dota_hero_phantom_assassin"
		 or bot:GetUnitName() == "npc_dota_hero_bloodseeker"
		 or bot:GetUnitName() == "npc_dota_hero_luna"
		 or bot:GetUnitName() == "npc_dota_hero_nevermore"
		 or bot:GetUnitName() == "npc_dota_hero_arc_warden"

end


function U.IsSpecialSupport(bot)
    
	return  bot:GetUnitName() == "npc_dota_hero_zuus" 
		 or bot:GetUnitName() == "npc_dota_hero_jakiro"
		 or bot:GetUnitName() == "npc_dota_hero_necrolyte" 
		 or bot:GetUnitName() == "npc_dota_hero_warlock"			 

end
	
	
function U.GetAttackableWeakestUnit(bHero, bEnemy, nRadius, bot)
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

function U.CanBeAttacked(npcTarget)
	
	return  not npcTarget:IsAttackImmune()
			and not npcTarget:IsInvulnerable()
			and not U.HasForbiddenModifier(npcTarget)
end

function U.GetHPR(bot)

	return bot:GetHealth()/bot:GetMaxHealth();

end

function U.GetMPR(bot)

	return bot:GetMana()/bot:GetMaxMana();

end

function U.Allies(bot,nRange)
	if nRange > 1600 then nRange = 1600 end
	local nRealAllies = {};
	local nCandidate = bot:GetNearbyHeroes(nRange,false,BOT_MODE_NONE);
	if nCandidate[1] == nil then return nCandidate end
	
	for _,ally in pairs(nCandidate)
	do
		if ally ~= nil and ally:IsAlive()
			and not ally:IsIllusion()
			and not U.IsExistInTable(ally, nRealAllies)
		then
			table.insert(nRealAllies, ally);
		end
	end
	
	return nRealAllies;
end

function U.AlliesCount(bot,nRange)
	if nRange > 1600 then nRange = 1600 end
	local nRealAllies = {};
	local nCandidate = bot:GetNearbyHeroes(nRange,false,BOT_MODE_NONE);
	if nCandidate[1] == nil then return 0 end
	
	for _,ally in pairs(nCandidate)
	do
		if ally ~= nil and ally:IsAlive()
			and not ally:IsIllusion()
			and not U.IsExistInTable(ally, nRealAllies)
		then
			table.insert(nRealAllies, ally);
		end
	end
	
	return #nRealAllies;
end

function U.Enemys(bot,nRange)
	if nRange > 1600 then nRange = 1600 end
	local nRealEnemys = {};
	local nCandidate = bot:GetNearbyHeroes(nRange,true,BOT_MODE_NONE);
	if nCandidate[1] == nil then return nCandidate end
	
	for _,enemy in pairs(nCandidate)
	do
		if enemy ~= nil and enemy:IsAlive()
			and not U.IsExistInTable(enemy, nRealEnemys)
		then
			table.insert(nRealEnemys, enemy);
		end
	end
	
	return nRealEnemys;
end

function U.EnemysCount(bot,nRange)
	if nRange > 1600 then nRange = 1600 end
	local nRealEnemys = {};
	local nCandidate = bot:GetNearbyHeroes(nRange,true,BOT_MODE_NONE);
	if nCandidate[1] == nil then return 0 end
	
	for _,enemy in pairs(nCandidate)
	do
		if enemy ~= nil and enemy:IsAlive()
			and not U.IsExistInTable(enemy, nRealEnemys)
		then
			table.insert(nRealEnemys, enemy);
		end
	end
	
	return #nRealEnemys;
end

function U.ConsiderTarget()

	local npcBot = GetBot();
	if not U.IsRunning(npcBot) or not npcBot:IsAlive() then return  end
	
	local npcTarget = U.GetProperTarget(npcBot);
	if not U.IsValidTarget(npcTarget) then return end

	local nAttackRange = npcBot:GetAttackRange() + 40;	
	if nAttackRange > 1600 then nAttackRange = 1600 end
	if nAttackRange < 200  then nAttackRange = 350  end
	
	local nInAttackRangeWeakestEnemyHero = U.GetAttackableWeakestUnit(true, true, nAttackRange, npcBot);
	
	local nTargetUint = nil;

	if  U.IsValidTarget(nInAttackRangeWeakestEnemyHero)
		and GetUnitToUnitDistance(npcTarget,npcBot) >  nAttackRange 		
	then
		nTargetUint = nInAttackRangeWeakestEnemyHero;
		npcBot:SetTarget(nTargetUint);
		return;
	end

end


function U.IsAttackProjectileIncoming(npcBot, range)
	local incProj = npcBot:GetIncomingTrackingProjectiles()
	for _,p in pairs(incProj)
	do
		if GetUnitToLocationDistance(npcBot, p.location) < range and p.is_attack then
			return true;
		end
	end
	return false;
end

function U.IsNotAttackProjectileIncoming(npcBot, range)
	local incProj = npcBot:GetIncomingTrackingProjectiles()
	for _,p in pairs(incProj)
	do
		if GetUnitToLocationDistance(npcBot, p.location) < range and not p.is_attack then
			return true;
		end
	end
	return false;
end

function U.IsHaveAegis(bot)

	for i = 0, 5 
	do
		local item = bot:GetItemInSlot(i)
		if item ~= nil and item:GetName() == "item_aegis" 
		then
			return true;
		end
	end

	return false;

end


return U;