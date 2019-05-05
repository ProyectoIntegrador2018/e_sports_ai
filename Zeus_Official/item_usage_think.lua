local BotsInit = require( "game/botsinit" );
local MyModule = BotsInit.CreateGeneric();

local bot = GetBot();

local map_awareness = require(GetScriptDirectory() ..  "/map_awareness");

local lasItemCheckTime = -100;

function ItemUsageThink()
	
  -- If bot can't use items by obious reasons, then return
	if not bot:IsAlive() 
	   or bot:NumQueuedActions() > 0 
	   or bot:IsMuted() 
	   or bot:HasModifier("modifier_doom_bringer_doom")
	   or bot:IsStunned()
	   or bot:IsHexed()
    then 
	    return ;
	end
	
-- Local variables defining what the bot sees  
	local tableNearbyEnemyHeroes = bot:GetNearbyHeroes( 1000, true, BOT_MODE_NONE );
	local nearbyEnemyTower = bot:GetNearbyTowers(888,true); 
	local npcTarget = map_awareness.GetProperTarget(bot);
	local mode = bot:GetActiveMode();
	local npcBot = bot;

-- If the bot can't use items because he is casting or channeling then return
	if  bot:IsChanneling() or bot:IsUsingAbility() or bot:IsCastingAbility( ) then
		return;
	end
	
-- Check whether the power treads are on the inventory, then uses them if in a hurry		
	local pt = IsItemAvailable("item_power_treads");
	if pt~=nil and pt:IsFullyCastable() 
		and not map_awareness.IsPTHero(bot)
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
				bot:Action_UseAbility(pt);
				return	
			end
		elseif  ( mode == BOT_MODE_RETREAT and bot:GetActiveModeDesire() > BOT_MODE_DESIRE_MODERATE ) 
				or (bot:GetHealth()/bot:GetMaxHealth() < 0.2)
				or (pt:GetPowerTreadsStat() == ATTRIBUTE_STRENGTH and bot:GetHealth()/bot:GetMaxHealth() < 0.25)
				or (mode ~= BOT_MODE_LANING and bot:GetLevel() < 12 and map_awareness.IsEnemyFacingUnit(800,bot,30))
			then
				if pt:GetPowerTreadsStat() ~= ATTRIBUTE_STRENGTH
				then
					bot:Action_UseAbility(pt);
					return
				end
		elseif  mode == BOT_MODE_ATTACK 
				or mode == BOT_MODE_TEAM_ROAM
			then
				if  CanSwitchPTStat(pt) 
				then
					bot:Action_UseAbility(pt);
					return
				end
		else
			local enemies = bot:GetNearbyHeroes( 1600, true, BOT_MODE_NONE );
			local creeps  = bot:GetNearbyCreeps(1200,true);
			local target  = map_awareness.GetProperTarget(bot);
			if  #creeps == 0
				and  #enemies == 0 
				and  target == nil
				and  bot:DistanceFromFountain() > 400
			then
				if pt:GetPowerTreadsStat() ~= ATTRIBUTE_INTELLECT
				then
					bot:Action_UseAbility(pt);
					return
				end
			elseif CanSwitchPTStat(pt)
				then
					bot:Action_UseAbility(pt);
					return			 
			end
		end
	end
	
-- This will prevent the item usage think happening too fast to avid innecesary item usage actions
	if DotaTime() < lasItemCheckTime + 0.06 then return end;
	
-- If tango is available and bot is low on health or running then use tango
	local tango =IsItemAvailable("item_tango");
	local item_tango_rate = 200;
	if tango ~= nil and DotaTime() > 0 and tango:IsFullyCastable() and bot:DistanceFromFountain() > 4000 then
		if not bot:HasModifier("modifier_tango_heal")
		   and not bot:HasModifier("modifier_filler_heal")
		   and not bot:HasModifier("modifier_flask_healing")
		then
			local trees = bot:GetNearbyTrees(800);
			local nEnemies = bot:GetNearbyHeroes(800,true,BOT_MODE_NONE);
			local nTowers  = bot:GetNearbyTowers(1500,true)
			if trees[1] ~= nil  			   
			   and  IsLocationVisible(GetTreeLocation(trees[1])) 
			   and  IsLocationPassable(GetTreeLocation(trees[1])) 
			   and  #nEnemies == 0 
			   and  #nTowers == 0
			   and bot:GetMaxHealth() - bot:GetHealth() > item_tango_rate
			then
        print("Using tango!");
				npcBot:Action_UseAbilityOnTree(tango, trees[1]);
				return;
			end
			
			local nearbyTrees = bot:GetNearbyTrees(200);
			if nearbyTrees[1] ~= nil
				and  IsLocationVisible(GetTreeLocation(nearbyTrees[1])) 
				and  IsLocationPassable(GetTreeLocation(nearbyTrees[1])) 
			then
				if  bot:GetMaxHealth() - bot:GetHealth() > item_tango_rate
				then
          print("Using tango!");
					npcBot:Action_UseAbilityOnTree(tango, nearbyTrees[1]);
					return;
				end
				
				if bot:GetMaxHealth() - bot:GetHealth() > item_tango_rate *0.38
				   and bot:WasRecentlyDamagedByAnyHero(1.0)
				   and ( bot:GetActiveMode() == BOT_MODE_ATTACK 
				         or ( bot:GetActiveMode() == BOT_MODE_RETREAT 
						      and bot:GetActiveModeDesire() > BOT_MODE_DESIRE_HIGH ) )
				then
          print("Using tango!");
					npcBot:Action_UseAbilityOnTree(tango, nearbyTrees[1]);
					return;
				end
			end
		end
	end
	
-- If flask is available and bot is safe then use it	
	local ifl = IsItemAvailable("item_flask");
	if ifl~=nil and ifl:IsFullyCastable() 
		and npcBot:DistanceFromFountain() > 4000 
	then
		if DotaTime() > 60 
		then
			local tableNearbyEnemyHeroes = npcBot:GetNearbyHeroes( 1000, true, BOT_MODE_NONE );
			if  (npcBot:GetMaxHealth() - npcBot:GetHealth() )  > 600
				and #tableNearbyEnemyHeroes == 0 
				and not bot:WasRecentlyDamagedByAnyHero(3.1)
				and not bot:HasModifier("modifier_filler_heal") 
			then
        print("Using flask!");
				npcBot:Action_UseAbilityOnEntity(ifl, npcBot);
				return;
			end
		end
	end
	
-- If magic stick is available and mp is low then use it
	local stick=IsItemAvailable("item_magic_stick");
	if stick ~= nil and stick:IsFullyCastable()
	then
		local tableNearbyEnemyHeroes = npcBot:GetNearbyHeroes( 800, true, BOT_MODE_NONE );
		local nEnemyCount = #tableNearbyEnemyHeroes;
		local nHP_rate = npcBot:GetHealth()/npcBot:GetMaxHealth();
		local nMP_rate = npcBot:GetMana()/npcBot:GetMaxMana();
		local nCharges = GetItemCharges(npcBot,"item_magic_stick");
		
		if ( ((nHP_rate < 0.5 or nMP_rate < 0.3) and  nEnemyCount >= 1 and nCharges >= 1 )
			or( nHP_rate + nMP_rate < 1.1 and nCharges >= 7  and  nEnemyCount >= 1 )
			or(nCharges >= 9 and bot:GetCourierValue() > 200 and (nHP_rate <= 0.7 or nMP_rate <= 0.6)) )  
		then
      print("Using stick, its magical btw..");
			npcBot:Action_UseAbility(stick);
			return;
		end
	end	
	
-- If wand is available and enemies are nearby then use it
	local wand=IsItemAvailable("item_magic_wand");
	if wand ~= nil and wand:IsFullyCastable()
	then
		local tableNearbyEnemyHeroes = npcBot:GetNearbyHeroes( 800, true, BOT_MODE_NONE );
		local nEnemyCount = #tableNearbyEnemyHeroes;
		local nHP_rate = npcBot:GetHealth()/npcBot:GetMaxHealth();
		local nMP_rate = npcBot:GetMana()/npcBot:GetMaxMana();
		local nLostHP = npcBot:GetMaxHealth() - npcBot:GetHealth();
		local nLostMP = npcBot:GetMaxMana() - npcBot:GetMana();
		local nCharges = GetItemCharges(npcBot,"item_magic_wand");
		
		if ( ((nHP_rate < 0.4 or nMP_rate < 0.3) and  nEnemyCount >= 1 and nCharges >= 1 )
			or( nHP_rate < 0.7  and nMP_rate < 0.7 and nCharges >= 12  and  nEnemyCount >= 1 ) 
			or(nCharges >= 19 and bot:GetCourierValue() > 500 and (nHP_rate <= 0.7 or nMP_rate <= 0.6)) ) 				
		then
			npcBot:Action_UseAbility(wand);
			return;
		end
	end
	
	-- If cyclone is available use it to stop enemy
	local cyclone=IsItemAvailable("item_cyclone");
	if cyclone~=nil and cyclone:IsFullyCastable() then
		local nCastRange = 650;
		if map_awareness.IsValid(npcTarget)
		   and map_awareness.CanCastOnNonMagicImmune(npcTarget) 
		   and GetUnitToUnitDistance(bot, npcTarget) < nCastRange +200
		   and ( npcTarget:HasModifier('modifier_teleporting') 
		         or npcTarget:HasModifier('modifier_abaddon_borrowed_time') 
				 or npcTarget:HasModifier("modifier_ursa_enrage")
				 or npcTarget:HasModifier("modifier_item_satanic_unholy")
				 or npcTarget:IsChanneling()
				 or ( map_awareness.IsRunning(npcTarget) and npcTarget:GetCurrentMovementSpeed() > 440)) 
		then
			bot:Action_UseAbilityOnEntity(cyclone, npcTarget);
			return;
		end
		
		if CanCastOnTarget(bot)
		   and tableNearbyEnemyHeroes[1] ~= nil 
		   and ( bot:GetHealth() < 188
				  or ( bot:GetPrimaryAttribute() == ATTRIBUTE_INTELLECT 
					   and bot:IsSilenced() )
				  or bot:IsRooted())
		then
			bot:Action_UseAbilityOnEntity(cyclone, bot);
			return;
		end
	end
	
-- If sheepstick is available use it to engage or retreat
	local sheep=IsItemAvailable("item_sheepstick");
	if sheep ~= nil and sheep:IsFullyCastable() and not bot:IsInvisible()
	then
		local nCastRange = 800;
		local nEnemysHerosInCastRange = bot:GetNearbyHeroes(nCastRange,true,BOT_MODE_NONE)
		for _,npcEnemy in pairs( nEnemysHerosInCastRange )
		do
			if map_awareness.IsValid(npcEnemy)
			   and (npcEnemy:IsChanneling() or npcEnemy:IsCastingAbility())
			   and map_awareness.CanCastOnNonMagicImmune(npcEnemy)
			then
				bot:Action_UseAbilityOnEntity(sheep,npcEnemy);
				return
			end
		end
		
		if mode == BOT_MODE_RETREAT 
		   and  bot:GetActiveModeDesire() > BOT_MODE_DESIRE_MODERATE
		   and	map_awareness.IsValid(nEnemysHerosInCastRange[1])
		   and  map_awareness.CanCastOnNonMagicImmune(nEnemysHerosInCastRange[1])
		   and  not IsDisabled(nEnemysHerosInCastRange[1])
		then
			bot:Action_UseAbilityOnEntity(sheep,nEnemysHerosInCastRange[1]);
			return;
	    end	
	
		if ( mode == BOT_MODE_ATTACK or
			 mode == BOT_MODE_ROAM or
			 mode == BOT_MODE_TEAM_ROAM or
			 mode == BOT_MODE_DEFEND_ALLY )
		then		
			local npcTarget = map_awareness.GetProperTarget(bot);
			if  map_awareness.IsValid(npcTarget)
				and npcTarget:IsHero() 
				and CanCastOnTarget(npcTarget) 
				and not IsDisabled(npcTarget)
                and map_awareness.CanCastOnNonMagicImmune(npcTarget)				
				and GetUnitToUnitDistance(npcTarget, bot) < nCastRange
			then
			    bot:Action_UseAbilityOnEntity(sheep,npcTarget);
				return;
			end
		end
	
	end
	
-- If arcane boots are available use them to recover mp
	local arcane=IsItemAvailable("item_arcane_boots");
  if arcane~=nil and arcane:IsFullyCastable() and not bot:IsInvisible() 
	then
		if bot:GetMana()/bot:GetMaxMana() < 0.55 
		then  
			bot:Action_UseAbility(arcane);
			return ;
		end
	end
	
-- If the guardinag greaves are available use them to engave or retreat
	local guardian=IsItemAvailable("item_guardian_greaves");
	if guardian~=nil and guardian:IsFullyCastable() and not bot:IsInvisible() 
	then
		local needHPCount = 0;
		if bot:GetHealth()/bot:GetMaxHealth() < 0.4
			or bot:IsSilenced()
			or bot:IsRooted()
			or bot:HasModifier("modifier_item_urn_damage") 
		    or bot:HasModifier("modifier_item_spirit_vessel_damage")
		then  
			bot:Action_UseAbility(guardian);
			return ;
		end
	end
	
-- If the pipe is available use it to defend
	local pipe=IsItemAvailable("item_pipe");
    if pipe~=nil and pipe:IsFullyCastable() and not bot:IsInvisible() 
	then
		local nNearbyEnemyHeroes  = npcBot:GetNearbyHeroes( 1600, true, BOT_MODE_NONE );
		local nNearbyAlliedTowers = npcBot:GetNearbyTowers(1200,true); 
		if (#nNearbyEnemyHeroes > 0 and #nNearbyAlliedTowers > 0) then
			bot:Action_UseAbility(pipe);
			return;
		end	
	end
	
-- If the veil of discord is available use it to attack
	local veil=IsItemAvailable("item_veil_of_discord");
    if veil~=nil and veil:IsFullyCastable() and not npcBot:IsInvisible()
	then
		local nCastRange = 1000;
		local Enemies= npcBot:GetNearbyHeroes(1600,true,BOT_MODE_NONE);		
		if Enemies~=nil and #Enemies~=0 then
			local nAOELocation = bot:FindAoELocation(true, true, npcBot:GetLocation(), nCastRange, 600 , 0, 0);
			if nAOELocation.count >= 2
			   and GetUnitToLocationDistance(bot,nAOELocation.targetloc) <= nCastRange
			then
			    npcBot:Action_UseAbilityOnLocation(veil,nAOELocation.targetloc);
				return ;
			end
		end
		
		Enemies = npcBot:GetNearbyHeroes(1000,true,BOT_MODE_NONE);		
		if Enemies~=nil and #Enemies ~=0 
		then
			local nAOELocation = bot:FindAoELocation(true, true, npcBot:GetLocation(), 800, 600 , 0, 0);
			if nAOELocation.count >= 1  
			   and GetUnitToLocationDistance(bot,nAOELocation.targetloc) <= 1000
			then
			    npcBot:Action_UseAbilityOnLocation(veil,nAOELocation.targetloc);
				return ;
			end
		end
		
		local LaneCreeps=npcBot:GetNearbyLaneCreeps(1500,true);		
		if LaneCreeps~=nil and #LaneCreeps >= 6 then
			local nAOELocation = bot:FindAoELocation(true, false, npcBot:GetLocation(), nCastRange, 600 , 0, 0);
			if nAOELocation.count >= 7
			   and GetUnitToLocationDistance(bot,nAOELocation.targetloc) <= nCastRange
			then
			    npcBot:Action_UseAbilityOnLocation(veil,nAOELocation.targetloc);
				return ;
			end
		end
	end
	
	lasItemCheckTime = DotaTime();
	return;
	
end

-- Returns whether target is disabled
function IsDisabled(npcTarget)
	if npcTarget:IsRooted( ) or npcTarget:IsStunned( ) or npcTarget:IsHexed( ) or npcTarget:IsSilenced() or npcTarget:IsNightmared() then
		return true;
	end
	return false;
end

-- Returns whether an specific item is avialable
function IsItemAvailable(item_name)
    local slot = bot:FindItemSlot(item_name);
	
	if slot < 0 then return nil end
	
	if bot:GetItemSlotType(slot) == ITEM_SLOT_TYPE_MAIN then
		return bot:GetItemInSlot(slot);
	end
	
    return nil;
end

-- Returns whether you may switch the power tread attribute
function CanSwitchPTStat(pt)
	if pt:GetPowerTreadsStat() ~= ATTRIBUTE_AGILITY then
		return true;
	end 
	return false;
end

-- Returns whether casting on target is avialable
function CanCastOnTarget( npcTarget )
	return npcTarget:CanBeSeen() and not npcTarget:IsMagicImmune() and not npcTarget:IsInvulnerable();
end

-- Return the amount of remaining charges on an item
function GetItemCharges(unit, item_name) 
	local count = 0;
	for i = 0, 8 
	do
		local item = unit:GetItemInSlot(i)
		if item ~= nil and item:GetName() == item_name then
			count = count + item:GetCurrentCharges();
		end
	end
	return count;
end

return MyModule;