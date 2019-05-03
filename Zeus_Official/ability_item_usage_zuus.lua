
if GetBot():IsInvulnerable() or not GetBot():IsHero() or not string.find(GetBot():GetUnitName(), "hero") or  GetBot():IsIllusion() then
	return;
end

local mutil = require(GetScriptDirectory() ..  "/awareness");
levelUpThink = require(GetScriptDirectory() .. "/levelUpThink");

function AbilityLevelUpThink()  
	 levelUpThink.AbilityLevelUpThink();
end

function BuybackUsageThink()
	
end

function CourierUsageThink()
	
end

local bot = GetBot();
local npcBot = bot;

local abilities = {};

local castQDesire = 0;
local castWDesire = 0;
local castWWDesire= 0;
local castDDesire = 0;
local castRDesire = 0;

local nComboMana,nManaPercentage,nHealthPercentage,nAllEnemyHeroes;

function AbilityUsageThink()
	if #abilities == 0 then abilities = mutil.InitiateAbilities(bot, {0,1,3,5}) end
	
	if mutil.CantUseAbility(bot) then return end
	
	nComboMana = 220 
	nManaPercentage = npcBot:GetMana()/npcBot:GetMaxMana();
	nHealthPercentage = npcBot:GetHealth()/npcBot:GetMaxHealth();
	
	castQDesire, targetQ = ConsiderQ();
	castWDesire, targetW = ConsiderW();
	castWWDesire,locWW   = ConsiderWW();
	castDDesire, targetD = ConsiderD();
	castRDesire          = ConsiderR();
	
	if castRDesire > 0 then
		print("Queued R ");
    npcBot:ActionImmediate_Chat("It's showtime baby!! ",true)
		npcBot:Action_ClearActions(true);
		npcBot:ActionQueue_UseAbility(abilities[4]);		
		return
	end
	
	if castWDesire > 0 then
    print("Queued W ");
	
		npcBot:Action_ClearActions(true);
		npcBot:ActionQueue_UseAbilityOnEntity(abilities[2], targetW);		
		return
	end
	
	if castWWDesire > 0 then
    print("Queued W ");
    
		npcBot:Action_ClearActions(true);
		npcBot:ActionQueue_UseAbilityOnLocation(abilities[2], locWW);		
		return
	end
	
	if castQDesire > 0 then
    print("Queued Q ");
  
		npcBot:Action_ClearActions(true);
		npcBot:ActionQueue_UseAbilityOnEntity(abilities[1], targetQ);		
		return
	end
	
	if castDDesire > 0 then
    print("Queued D ");
    
		npcBot:Action_ClearActions(true);
		npcBot:ActionQueue_UseAbilityOnLocation(abilities[3], targetD);		
		return
	end
	
end

function ConsiderQ()
	if not mutil.CanBeCast(abilities[1]) then
		return BOT_ACTION_DESIRE_NONE, nil;
	end
	
	local nCastRange = abilities[1]:GetCastRange();
	local nCastPoint = abilities[1]:GetCastPoint();
	local manaCost  = abilities[1]:GetManaCost();
	local nRadius   = abilities[1]:GetSpecialValueInt( "radius" );
	local nEnemyHeroesInSkillRange = bot:GetNearbyHeroes(nCastRange,true,BOT_MODE_NONE);
	
	for _,enemy in pairs(nEnemyHeroesInSkillRange)
	do
		if mutil.IsValidTarget(enemy)
			and mutil.CanCastOnNonMagicImmune(enemy)
			and mutil.GetHPR(enemy) <= 0.2
		then
			return BOT_ACTION_DESIRE_HIGH, enemy;
		end
	end
	
	if bot:GetActiveMode() == BOT_MODE_LANING then
		local target = mutil.GetSpellKillTarget(bot, false, nCastRange, abilities[1]:GetAbilityDamage(), DAMAGE_TYPE_MAGICAL);
		if target ~= nil and mutil.IsEnemyTargetMyTarget(bot, target) then
			return BOT_ACTION_DESIRE_HIGH, target;
		end
	end
	
	if mutil.IsRetreating(bot) and bot:WasRecentlyDamagedByAnyHero(2.0)
	then
		local target = mutil.GetVulnerableWeakestUnit(true, true, nCastRange, bot);
		if target ~= nil and bot:IsFacingLocation(target:GetLocation(),45) then
			return BOT_ACTION_DESIRE_HIGH, target;
		end
	end
	
	if ( mutil.IsPushing(bot) or mutil.IsDefending(bot) ) and mutil.CanSpamSpell(bot, manaCost)
	then
		local locationAoE = bot:FindAoELocation( true, false, bot:GetLocation(), nCastRange, nRadius, 0, 0 );
		if ( locationAoE.count >= 3 ) then
			local target = mutil.GetVulnerableUnitNearLoc(false, true, nCastRange, nRadius, locationAoE.targetloc, bot);
			if target ~= nil then
				return BOT_ACTION_DESIRE_HIGH, target;
			end
		end
	end
	
	if mutil.IsGoingOnSomeone(bot)
	then
		local target = mutil.GetProperTarget(bot);
		if mutil.IsValidTarget(target) and mutil.CanCastOnNonMagicImmune(target) and mutil.IsInRange(target, bot, nCastRange)
		then
			return BOT_ACTION_DESIRE_HIGH, target;
		end
	end
	
	return BOT_ACTION_DESIRE_NONE, nil;
end

function ConsiderW()
	if not mutil.CanBeCast(abilities[2]) then
		return BOT_ACTION_DESIRE_NONE, nil;
	end
	
	local nCastRange = abilities[2]:GetCastRange();
	local nCastPoint = abilities[2]:GetCastPoint();
	local manaCost  = abilities[2]:GetManaCost();
	local nDamage   = abilities[2]:GetAbilityDamage();
	
	local targetRanged = GetRanged(bot,nCastRange);	
	
	if mutil.IsRetreating(bot) and bot:WasRecentlyDamagedByAnyHero(2.0)
	then
		local target = mutil.GetVulnerableWeakestUnit(true, true, nCastRange, bot);
		if target ~= nil then
			return BOT_ACTION_DESIRE_HIGH, target;
		end
	end
	
	
	if mutil.IsGoingOnSomeone(bot)
	then
		local target = mutil.GetProperTarget(bot);
		if mutil.IsValidTarget(target) and mutil.CanCastOnNonMagicImmune(target) and mutil.IsInRange(target, bot, nCastRange)
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

function ConsiderWW()
	if not mutil.CanBeCast(abilities[2]) then
		return BOT_ACTION_DESIRE_NONE, nil;
	end
	
	local nCastRange = abilities[2]:GetCastRange();
	local nCastPoint = abilities[2]:GetCastPoint();
	local manaCost  = abilities[2]:GetManaCost();
	local nDamage   = abilities[2]:GetAbilityDamage();
	local nRadius   = 325;
	
	local nEnemyHeroesInSkillRange  = bot:GetNearbyHeroes(nCastRange + nRadius,true,BOT_MODE_NONE);
	local nWeakestEnemyHeroInSkillRange = mutil.GetVulnerableWeakestUnit(true, true, nCastRange + nRadius, bot);
	local nCanKillHeroLocationAoE = npcBot:FindAoELocation( true, true, npcBot:GetLocation(), nCastRange, nRadius , 0, 0.7*nDamage);
	
	if nCanKillHeroLocationAoE.count >= 1
	then
		if mutil.IsValid(nWeakestEnemyHeroInSkillRange) 
		then
		    local nTargetLocation = mutil.GetCastLocation(npcBot,nWeakestEnemyHeroInSkillRange,nCastRange,nRadius);
			if nTargetLocation ~= nil
			then
				return BOT_ACTION_DESIRE_HIGH, nTargetLocation;
			end
		end
	end
	
	for _,enemy in pairs(nEnemyHeroesInSkillRange)
	do
		if mutil.IsValid(enemy)
			and enemy:IsChanneling()
			and not enemy:IsMagicImmune()
		then
			local nTargetLocation = mutil.GetCastLocation(npcBot,enemy,nCastRange,nRadius);
			if nTargetLocation ~= nil
			then
				return BOT_ACTION_DESIRE_HIGH, nTargetLocation;
			end
		end
	end
	
	if  npcBot:GetActiveMode() == BOT_MODE_RETREAT 
	    and not npcBot:IsInvisible() 
		and (npcBot:WasRecentlyDamagedByAnyHero(2.0))
	then
		local nCanHurtHeroLocationAoENearby = npcBot:FindAoELocation( true, true, npcBot:GetLocation(), nCastRange - 300, nRadius, 0.8, 0);
		if nCanHurtHeroLocationAoENearby.count >= 1 
		then
			return BOT_ACTION_DESIRE_HIGH, nCanHurtHeroLocationAoENearby.targetloc;
		end
	end
	
	
	if bot:GetActiveMode() ~= BOT_MODE_RETREAT and not bot:IsInvisible()
	then
		local npcEnemy = mutil.GetProperTarget(bot)
		if  mutil.IsValidTarget(npcEnemy)
            and mutil.CanCastOnNonMagicImmune(npcEnemy) 
			and GetUnitToUnitDistance(npcEnemy,bot) <= nRadius + nCastRange		
		then
			
			if nManaPercentage > 0.65 
			   or npcBot:GetMana() > nComboMana *2
			then
				local nTargetLocation = mutil.GetCastLocation(npcBot,npcEnemy,nCastRange,nRadius);
				if nTargetLocation ~= nil
				then
					return BOT_ACTION_DESIRE_HIGH, nTargetLocation;
				end
			end
			
			if npcEnemy:GetHealth()/npcEnemy:GetMaxHealth() < 0.45            
		    then
			    local nTargetLocation = mutil.GetCastLocation(npcBot,npcEnemy,nCastRange,nRadius);
				if nTargetLocation ~= nil
				then
					return BOT_ACTION_DESIRE_HIGH, nTargetLocation;
				end			   
			end
			
		end	
		
		local npcEnemy = nWeakestEnemyHeroInSkillRange;
		if  mutil.IsValid(npcEnemy) and DotaTime() > 0
			and (npcEnemy:GetHealth()/npcEnemy:GetMaxHealth() < 0.4 or npcBot:GetMana() > nComboMana * 2.3)
			and GetUnitToUnitDistance(npcEnemy,npcBot) <= nRadius + nCastRange
		then
			local nTargetLocation = mutil.GetCastLocation(npcBot,npcEnemy,nCastRange,nRadius);
			if nTargetLocation ~= nil
			then
				return BOT_ACTION_DESIRE_HIGH, nTargetLocation;
			end			   
		end 
	end
	
	return BOT_ACTION_DESIRE_NONE, nil;
end


function ConsiderD()
	if not mutil.CanBeCast(abilities[3]) or bot:HasScepter() == false or bot:IsInvisible() then
		return BOT_ACTION_DESIRE_NONE, nil;
	end
	
	local numPlayer =  GetTeamPlayers(GetTeam());
	for i = 1, #numPlayer
	do
		local member =  GetTeamMember(i);
		if mutil.IsValid(member)
			and mutil.IsGoingOnSomeone(member)
		then
			local target = mutil.GetProperTarget(member);
			if mutil.IsValidTarget(target) 
			   and mutil.IsInRange(member, target, 1200)
			   and mutil.CanCastOnNonMagicImmune(target)
			then
				return BOT_ACTION_DESIRE_HIGH, target:GetExtrapolatedLocation(1.0);
			end
		end
	end
	
	return BOT_ACTION_DESIRE_NONE, nil;
end

function ConsiderR()
	if not mutil.CanBeCast(abilities[4]) then
		return BOT_ACTION_DESIRE_NONE;
	end
	
	local nCastRange = 1600;
	local nCastPoint = abilities[4]:GetCastPoint();
	local manaCost  = abilities[4]:GetManaCost();
	local nDamage  = abilities[4]:GetSpecialValueInt('damage');
	local nDamageType  = DAMAGE_TYPE_MAGICAL
	
	
	if mutil.IsRetreating(bot) and bot:WasRecentlyDamagedByAnyHero(2.0)
	then
		local target = mutil.GetSpellKillTarget(bot, true, nCastRange, nDamage, nDamageType);
		if target ~= nil then
			return BOT_ACTION_DESIRE_HIGH;
		end
		
		if bot:GetRespawnTime() > abilities[4]:GetCooldown()
		   and nHealthPercentage <= 0.28
		then
			return BOT_ACTION_DESIRE_HIGH;
		end
	end
	
	-- modifier_warlock_fatal_bonds
	local lowHPCount = 0;
	local fatalCount = 0;	
	local gEnemies = GetUnitList(UNIT_LIST_ENEMY_HEROES);
	for _,e in pairs (gEnemies) 
	do
		if e ~= nil 
		   and mutil.CanCastOnNonMagicImmune(e) 
		then
			if e:GetHealth() > 0 and e:GetHealth() <= e:GetActualIncomingDamage(nDamage, nDamageType) 
			then
				lowHPCount = lowHPCount + 1;
			end
			if e:HasModifier("modifier_warlock_fatal_bonds") 
			then
				fatalCount = fatalCount + 1;
			end
		end
	end	
	if lowHPCount >= 1 or fatalCount >= 2 then
		return BOT_ACTION_DESIRE_MODERATE;
	end
	
	return BOT_ACTION_DESIRE_NONE;
end

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
		or nManaPercentage <= 0.15
	then
		return nil;
	end
	
	if mode == BOT_MODE_LANING or nManaPercentage >= 0.56
	then
		local nTowers = bot:GetNearbyTowers(1600,false);
		if nTowers[1] ~= nil
		then
			local nTowerTarget = nTowers[1]:GetAttackTarget();
			if mutil.IsValid(nTowerTarget)
				and GetUnitToUnitDistance(nTowerTarget,bot) <= 1400
				and mutil.IsKeyWordUnitClass("ranged",nTowerTarget)
				and not nTowerTarget:WasRecentlyDamagedByAnyHero(1.0)
			then
				return nTowerTarget;
			end
		end
		
		if nManaPercentage > 0.7 and bot:GetMana() > 500
		then
			local nLaneCreeps = bot:GetNearbyLaneCreeps(800,true);
			for _,creep in pairs(nLaneCreeps)
			do
				if mutil.IsValid(creep)
					and mutil.IsKeyWordUnitClass("ranged",creep)
					and not creep:WasRecentlyDamagedByAnyHero(1.0)
				then
					return creep;
				end
			
			end
		end
		
	end

	return nil;

end