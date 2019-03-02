--This function prevents items to be used if the hero is not a correct target --
if GetBot():IsInvulnerable() or not GetBot():IsHero() or not string.find(GetBot():GetUnitName(), "hero") or  GetBot():IsIllusion() then
	return;
end

-- 
local ability_item_usage_generic = dofile( GetScriptDirectory().."/ability_item_usage_generic" )
local utils = require(GetScriptDirectory() ..  "/util")
local mutils = require(GetScriptDirectory() ..  "/MyUtility")

-- The bot will decide which ability use based on current bot and enemy location and status
function AbilityLevelUpThink()  
	ability_item_usage_generic.AbilityLevelUpThink(); 
end
-- The bot will decide when and which itemm buy based on current location and status
function BuybackUsageThink()
	ability_item_usage_generic.BuybackUsageThink();
end
-- The bot will decide if it must use the courier (flying donkey) and what for
function CourierUsageThink()
	ability_item_usage_generic.CourierUsageThink();
end

local bot = GetBot();
local npcBot = bot;

--[[
"Ability1"		"zuus_arc_lightning"
"Ability2"		"zuus_lightning_bolt"
"Ability3"		"zuus_static_field"
"Ability4"		"zuus_cloud"
"Ability5"		"generic_hidden"
"Ability6"		"zuus_thundergods_wrath"
]]

local abilities = {};

local castCombo1Desire = 0;
local castCombo2Desire = 0;
local castQDesire = 0;
local castWDesire = 0;
local castWWDesire= 0;
local castDDesire = 0;
local castRDesire = 0;

local nComboMana,nManaPercentage,nHealthPercentage,nAllEnemyHeroes;

function AbilityUsageThink()
	
	if #abilities == 0 then abilities = mutils.InitiateAbilities(bot, {0,1,3,5}) end
	
  -- If the bot can't use any ability (due to death, stunt or any other external effect preventing that) then this will return to evaluate other item usage possibility --
	if mutils.CantUseAbility(bot) then return end
	
  -- This is a predefined needed mana to execute a Zeus combo of abilities
	nComboMana = 220 
	-- This variabe indicates current mana
  nManaPercentage = npcBot:GetMana()/npcBot:GetMaxMana();
  -- This variable indicates current health
	nHealthPercentage = npcBot:GetHealth()/npcBot:GetMaxHealth();
	
	castQDesire, targetQ = ConsiderQ();
	castWDesire, targetW = ConsiderW();
	castWWDesire,locWW   = ConsiderWW();
	castDDesire, targetD = ConsiderD();
	castRDesire          = ConsiderR();
	
	if castRDesire > 0 then
		bot:Action_UseAbility(abilities[4]);		
		return
	end
	
	if castWDesire > 0 then
		bot:Action_UseAbilityOnEntity(abilities[2], targetW);		
		return
	end
	
	if castWWDesire > 0 then
		bot:Action_UseAbilityOnLocation(abilities[2], locWW);		
		return
	end
	
	if castQDesire > 0 then
		bot:Action_UseAbilityOnEntity(abilities[1], targetQ);		
		return
	end
	
	if castDDesire > 0 then
		bot:Action_UseAbilityOnLocation(abilities[3], targetD);		
		return
	end
	
end

-- This function will specify wheter Q ability (zuus_arc_lightning) can or can't be casted
function ConsiderQ()
  -- If due to a paralizys, stun, death or similar conditions you can't use any skill then none is returned
	if not mutils.CanBeCast(abilities[1]) then
		return BOT_ACTION_DESIRE_NONE, nil;
	end
	
  -- Get ability's attributes
	local nCastRange = abilities[1]:GetCastRange();
	local nCastPoint = abilities[1]:GetCastPoint();
	local manaCost  = abilities[1]:GetManaCost();
	local nRadius   = abilities[1]:GetSpecialValueInt( "radius" );
	
	-- If the bot is currently laning 
	if bot:GetActiveMode() == BOT_MODE_LANING then
		-- Skill target objective set to "target" variable
    local target = mutils.GetSpellKillTarget(bot, false, nCastRange, abilities[1]:GetAbilityDamage(), abilities[1]:GetDamageType());
		-- If this target exists and is YOUR target
    if target ~= nil and mutils.IsEnemyTargetMyTarget(bot, target) then
			-- returns target for ability to be casted
      return BOT_ACTION_DESIRE_HIGH, target;
		end
	end
	
  -- If the bot is currently retreating and was damaged by a hero
	if mutils.IsRetreating(bot) and bot:WasRecentlyDamagedByAnyHero(2.0)
	then
    -- Then the bot will only target the weakest units in range
		local target = mutils.GetVulnerableWeakestUnit(true, true, nCastRange, bot);
		if target ~= nil then
      -- returns target for ability to be casted
			return BOT_ACTION_DESIRE_HIGH, target;
		end
	end
	
  -- If the bot is currently in a team figth
	if mutils.IsInTeamFight(bot, 1300)
	then
    -- This will return the aoe target location that will affect the most enemies for the ability
		local locationAoE = bot:FindAoELocation( true, true, bot:GetLocation(), nCastRange, nRadius, 0, 0 );
    if ( locationAoE.count >= 2 ) then
      -- If there is more than one suitable location then the target will be the weakest unit on that location
			local target = mutils.GetVulnerableUnitNearLoc(true, true, nCastRange, nRadius, locationAoE.targetloc, bot);
			if target ~= nil then
        -- returns target for ability to be casted
				return BOT_ACTION_DESIRE_HIGH, target;
			end
		end
	end
	
  -- If the bot is defending a turret or pushing a turret and is able to spam the ability
	if ( mutils.IsPushing(bot) or mutils.IsDefending(bot) ) and mutils.CanSpamSpell(bot, manaCost)
	then
    -- This will return the aoe target location that will affect the most enemies for the ability
		local locationAoE = bot:FindAoELocation( true, false, bot:GetLocation(), nCastRange, nRadius, 0, 0 );
		if ( locationAoE.count >= 3 ) then
      -- If there are at least 3 or more locations then the target will be the most vulnerable trget on those locations
			local target = mutils.GetVulnerableUnitNearLoc(false, true, nCastRange, nRadius, locationAoE.targetloc, bot);
			if target ~= nil then
        -- returns target for ability to be casted
				return BOT_ACTION_DESIRE_HIGH, target;
			end
		end
	end
	
  -- If the bot is chasing after an enemy
	if mutils.IsGoingOnSomeone(bot)
	then
    -- This is the target for the ability (the one the bot is chasing)
		local target = mutils.GetProperTarget(bot);
    -- If able to cst on that target
		if mutils.IsValidTarget(target) and mutils.CanCastOnNonMagicImmune(target) and mutils.IsInRange(target, bot, nCastRange)
		then
      -- returns target for ability to be casted
			return BOT_ACTION_DESIRE_HIGH, target;
		end
	end
	
  -- returns no target for ability to be casted
	return BOT_ACTION_DESIRE_NONE, nil;
end

-- This function will specify wheter W ability can or can't be casted this function works just as the funtion above
function ConsiderW()
	if not mutils.CanBeCast(abilities[2]) then
		return BOT_ACTION_DESIRE_NONE, nil;
	end
	
	local nCastRange = abilities[2]:GetCastRange();
	local nCastPoint = abilities[2]:GetCastPoint();
	local manaCost  = abilities[2]:GetManaCost();
	local nDamage   = abilities[2]:GetAbilityDamage();
	
	local targetRanged = GetRanged(bot,nCastRange);	
	
	if mutils.IsRetreating(bot) and bot:WasRecentlyDamagedByAnyHero(2.0)
	then
		local target = mutils.GetVulnerableWeakestUnit(true, true, nCastRange, bot);
		if target ~= nil then
			return BOT_ACTION_DESIRE_HIGH, target;
		end
	end
	
	
	if mutils.IsGoingOnSomeone(bot)
	then
		local target = bot:GetTarget();
		if mutils.IsValidTarget(target) and mutils.CanCastOnNonMagicImmune(target) and mutils.IsInRange(target, bot, nCastRange)
		then
			return BOT_ACTION_DESIRE_HIGH, target;
		end
	end
	
	if targetRanged ~= nil
		and targetRanged:GetHealth() > bot:GetAttackDamage()
		and targetRanged:GetHealth() < targetRanged:GetActualIncomingDamage(nDamage,DAMAGE_TYPE_MAGICAL)
	then
		return BOT_ACTION_DESIRE_HIGH, targetRanged;
	end
	
	return BOT_ACTION_DESIRE_NONE, nil;
end

-- This function will specify wheter W ability can or can't be casted this function works just as the funtion above and will consder if a double zuus_lightning_bolt combo is suitable for killing the enemy
function ConsiderWW()
	if not mutils.CanBeCast(abilities[2]) then
		return BOT_ACTION_DESIRE_NONE, nil;
	end
	
	local nCastRange = abilities[2]:GetCastRange();
	local nCastPoint = abilities[2]:GetCastPoint();
	local manaCost  = abilities[2]:GetManaCost();
	local nDamage   = abilities[2]:GetAbilityDamage();
	local nRadius   = 300;
	
	local nAllyes = bot:GetNearbyHeroes(800,false,BOT_MODE_NONE);
	
	local nEnemyHeroesInSkillRange  = bot:GetNearbyHeroes(nCastRange + nRadius,true,BOT_MODE_NONE);
	local nWeakestEnemyHeroInSkillRange =mutils.GetVulnerableWeakestUnit(true, true, nCastRange + nRadius, bot);
	local nCanKillHeroLocationAoE = npcBot:FindAoELocation( true, true, npcBot:GetLocation(), nCastRange, nRadius , 0, 0.7*nDamage);
	
	if nCanKillHeroLocationAoE.count >= 1
	then
		if mutils.IsValid(nWeakestEnemyHeroInSkillRange) 
		then
		    local nTargetLocation = mutils.GetCastLocation(npcBot,nWeakestEnemyHeroInSkillRange,nCastRange,nRadius);
			if nTargetLocation ~= nil
			then
				return BOT_ACTION_DESIRE_HIGH, nTargetLocation;
			end
		end
	end
	
	for _,enemy in pairs(nEnemyHeroesInSkillRange)
	do
		if mutils.IsValid(enemy)
			and enemy:IsChanneling()
			and not enemy:IsMagicImmune()
		then
			local nTargetLocation = mutils.GetCastLocation(npcBot,enemy,nCastRange,nRadius);
			if nTargetLocation ~= nil
			then
				return BOT_ACTION_DESIRE_HIGH, nTargetLocation;
			end
		end
	end
	
	if  npcBot:GetActiveMode() == BOT_MODE_RETREAT 
	    and not npcBot:IsInvisible() 
		and (npcBot:WasRecentlyDamagedByAnyHero(2.0) or #nAllyes >= 3)
	then
		local nCanHurtHeroLocationAoENearby = npcBot:FindAoELocation( true, true, npcBot:GetLocation(), nCastRange - 300, nRadius, 0.8, 0);
		if nCanHurtHeroLocationAoENearby.count >= 1 
		then
			return BOT_ACTION_DESIRE_HIGH, nCanHurtHeroLocationAoENearby.targetloc;
		end
	end
	
	
	if bot:GetActiveMode() ~= BOT_MODE_RETREAT and not bot:IsInvisible()
	then
		local npcEnemy = mutils.GetProperTarget(bot)
		if  mutils.IsValidTarget(npcEnemy)
            and mutils.CanCastOnNonMagicImmune(npcEnemy) 
			and GetUnitToUnitDistance(npcEnemy,bot) <= nRadius + nCastRange		
		then
			
			if nManaPercentage > 0.65 
			   or npcBot:GetMana() > nComboMana *2
			then
				local nTargetLocation = mutils.GetCastLocation(npcBot,npcEnemy,nCastRange,nRadius);
				if nTargetLocation ~= nil
				then
					return BOT_ACTION_DESIRE_HIGH, nTargetLocation;
				end
			end
			
			if npcEnemy:GetHealth()/npcEnemy:GetMaxHealth() < 0.45 or #nAllyes >= 3             
		    then
			    local nTargetLocation = mutils.GetCastLocation(npcBot,npcEnemy,nCastRange,nRadius);
				if nTargetLocation ~= nil
				then
					return BOT_ACTION_DESIRE_HIGH, nTargetLocation;
				end			   
			end
			
		end	
		
		local npcEnemy = nWeakestEnemyHeroInSkillRange;
		if  mutils.IsValid(npcEnemy) and DotaTime() > 0
			and (npcEnemy:GetHealth()/npcEnemy:GetMaxHealth() < 0.4 or npcBot:GetMana() > nComboMana * 2.3 or #nAllyes >= 3)
			and GetUnitToUnitDistance(npcEnemy,npcBot) <= nRadius + nCastRange
		then
			local nTargetLocation = mutils.GetCastLocation(npcBot,npcEnemy,nCastRange,nRadius);
			if nTargetLocation ~= nil
			then
				return BOT_ACTION_DESIRE_HIGH, nTargetLocation;
			end			   
		end 
	end
	
	return BOT_ACTION_DESIRE_NONE, nil;
end

-- This function will specify wheter D ability (zuus_static_field) can or can't be casted
local eneLock = true;
function ConsiderD()
  -- This ability needs the scepter to be casted so it will be consider to wether it can be actually casted
	if not mutils.CanBeCast(abilities[3]) or bot:HasScepter() == false or bot:IsInvisible() then
		return BOT_ACTION_DESIRE_NONE, nil;
	end
	
	-- local arc = bot:FindItemSlot("item_arcane_boots");
	-- if arc >= 0	then
		-- bot:ActionImmediate_DisassembleItem( bot:GetItemInSlot(arc) );
	-- end
	-- local ene = bot:FindItemSlot("item_energy_booster");
	-- if ene >= 0 and eneLock then
		-- eneLock = false;
		-- bot:ActionImmediate_SetItemCombineLock( bot:GetItemInSlot(ene), false );
	-- end
	
  -- This will store the number of team players
	local numPlayer =  GetTeamPlayers(GetTeam());
	-- The followin for will be executed for each player on team as target for the ability
  for i = 1, #numPlayer
	do
		local member =  GetTeamMember(i);
    -- If the target is valid
		if mutils.IsValid(member)
      -- and the target is chasing someone
			and mutils.IsGoingOnSomeone(member)
		then
      -- Then the target position will be returned
			local target = mutils.GetProperTarget(member);
      -- If the target location is a valid location
			if mutils.IsValidTarget(target) 
        -- and the target is in range and is not immune to magic
			   and mutils.IsInRange(member, target, 1200)
			   and mutils.CanCastOnNonMagicImmune(target)
			then
        -- the spell will be casted on target
				return BOT_ACTION_DESIRE_HIGH, target:GetLocation();
			end
		end
	end
	
  -- none is return as a target
	return BOT_ACTION_DESIRE_NONE, nil;
end

-- This function will specify wheter R ability can or can't be casted
function ConsiderR()
  -- If the ability can't be casted then none is returned
	if not mutils.CanBeCast(abilities[4]) then
		return BOT_ACTION_DESIRE_NONE;
	end
	
  -- This is the ability's attributes
	local nCastRange = 1600;
	local nCastPoint = abilities[4]:GetCastPoint();
	local manaCost  = abilities[4]:GetManaCost();
	local nDamage  = abilities[4]:GetSpecialValueInt('damage');
	local nDamageType  = abilities[4]:GetDamageType();
	
	-- if the bot is retreating and was recently damaged
	if mutils.IsRetreating(bot) and bot:WasRecentlyDamagedByAnyHero(2.0)
	then
    -- search for a target who will die of this ability
		local target = mutils.GetSpellKillTarget(bot, true, nCastRange, nDamage, nDamageType);
		-- if there exists such target
    if target ~= nil then
      -- cast ability
			return BOT_ACTION_DESIRE_HIGH;
		end
		
    -- if respawn time is higher than the ability cooldown
		if bot:GetRespawnTime() > abilities[4]:GetCooldown()
      -- and low on health
		   and nHealthPercentage <= 0.38
		then
      -- cast ability (aka panic attack)
			return BOT_ACTION_DESIRE_HIGH;
		end
	end
	
  -- if the bot is on a team fight
	if mutils.IsInTeamFight(bot, 1300)
	then
    -- if the number of invincible near enemies is lower or equal than 3
		local tableNearbyEnemyHeroes = bot:GetNearbyHeroes( 1300, true, BOT_MODE_NONE );
		local nInvUnit = mutils.CountInvUnits(false, tableNearbyEnemyHeroes);
		if nInvUnit >= 3 then
      --  then cast the ability
			return BOT_ACTION_DESIRE_MODERATE;
		end
	end
	
	-- modifier_warlock_fatal_bonds
	local lowHPCount = 0;
	local fatalCount = 0;
	
	local gEnemies = GetUnitList(UNIT_LIST_ENEMY_HEROES);
	for _,e in pairs (gEnemies) do
		if e ~= nil and mutils.CanCastOnNonMagicImmune(e) and e:GetHealth() > 0 and e:GetHealth() <= e:GetActualIncomingDamage(nDamage, nDamageType) then
			lowHPCount = lowHPCount + 1;
		end
		if mutils.IsValid(e) 
			and e:HasModifier("modifier_warlock_fatal_bonds") 
			and mutils.CanCastOnNonMagicImmune(e) 
		then
			fatalCount = fatalCount + 1;
		end
	end
	
  -- if enemies are low on hp or have fatal counts then return mderate desire to cast ability
	if lowHPCount >= 1 or fatalCount >= 3 then
		return BOT_ACTION_DESIRE_MODERATE;
	end
	
	return BOT_ACTION_DESIRE_NONE;
end

-- Get enemies on certain range
function GetRanged(bot,nRadius)
	local mode = bot:GetActiveMode();
	local enemys = bot:GetNearbyHeroes(1600,true,BOT_MODE_NONE);
	local allies = bot:GetNearbyHeroes(800,false,BOT_MODE_NONE);
	
  
	if  mode == BOT_MODE_TEAM_ROAM 
		or mode == BOT_MODE_ATTACK 
		or mode == BOT_MODE_DEFEND_ALLY
		or mode == BOT_MODE_RETREAT
		or #enemys >= 1
		or #allies >= 3
		or nManaPercentage <= 0.35
	then
		return nil;
	end
	
  -- If bot is laning or its mana percentage is high then the towers will be considered as a valuavle target in range
	if mode == BOT_MODE_LANING or nManaPercentage >= 0.7
	then
		local nTowers = bot:GetNearbyTowers(1600,false);
		if nTowers[1] ~= nil
		then
			local nTowerTarget = nTowers[1]:GetAttackTarget();
			if mutils.IsValid(nTowerTarget)
				and GetUnitToUnitDistance(nTowerTarget,bot) <= 1400
				and mutils.IsKeyWordUnitClass("ranged",nTowerTarget)
				and not nTowerTarget:WasRecentlyDamagedByAnyHero(2.0)
			then
				return nTowerTarget;
			end
		end
		
    -- if you have enough mana then farming minions will be considered as a valuavle action
		if nManaPercentage > 0.7 and bot:GetMana() > 500
		then
			local nLaneCreeps = bot:GetNearbyLaneCreeps(800,true);
			for _,creep in pairs(nLaneCreeps)
			do
				if mutils.IsValid(creep)
					and mutils.IsKeyWordUnitClass("ranged",creep)
					and not creep:WasRecentlyDamagedByAnyHero(2.0)
				then
					return creep;
				end
			
			end
		end
		
	end

	return nil;

end