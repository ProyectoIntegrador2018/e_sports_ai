--_G._savedEnv = getfenv()
--module("ability_item_usage_generic", package.seeall)

local BotsInit = require( "game/botsinit" );
local MyModule = BotsInit.CreateGeneric();

local bot = GetBot();

-- Monkey king plays differntly that is why we check if the bot is monkey king
if bot:GetUnitName() == 'npc_dota_hero_monkey_king' then
	local trueMK = nil;
	for i, id in pairs(GetTeamPlayers(GetTeam())) do
		if IsPlayerBot(id) and GetSelectedHeroName(id) == 'npc_dota_hero_monkey_king' then
			local member = GetTeamMember(i);
			if member ~= nil then
				trueMK = member;
			end
		end
	end
	
	if trueMK ~= nil and bot ~= trueMK then
		print("AbilityItemUsage "..tostring(bot).." isn't true MK")
		return;
	elseif trueMK == nil or bot == trueMK then
		print("AbilityItemUsage "..tostring(bot).." is true MK")
	end
end

-- If target isn't invulnerable, heroe or is an ilusion then do nothing and exit
if bot:IsInvulnerable() or bot:IsHero() == false or bot:IsIllusion()
then
	return;
end

local build = "NOT IMPLEMENTED";


if bot:IsHero() then
	build = require(GetScriptDirectory() .. "/builds/item_build_" .. string.gsub(GetBot():GetUnitName(), "npc_dota_hero_", ""));
end

if build == "NOT IMPLEMENTED" then 
	return 
end

local role = require(GetScriptDirectory() .. "/RoleUtility");
local mutil = require(GetScriptDirectory() ..  "/MyUtility")
local utils = require(GetScriptDirectory() ..  "/util")
local eUtils = require(GetScriptDirectory() ..  "/EnemyUtility")

local IdleTime = 0;
local AllowedIddle = 15;
local TimeDeath = nil;
local count = 1;
local humanInTeam = nil;


--clone skill build to bot.abilities in reverse order 
--plus overcome the usage of the same memory address problem for bot.abilities in same heroes game which result in bot failed to level up correctly 
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

	if GetGameState() ~= GAME_STATE_PRE_GAME and GetGameState() ~= GAME_STATE_GAME_IN_PROGRESS 
	then
		return;
	end

	UseGlyph();	
	UnImplementedItemUsage();
	
	if not bot:IsAlive() then
		 bot:Action_ClearActions( false ) 
		 return
	end	
		
	if DotaTime() < 15 then
		bot.theRole = role.GetCurrentSuitableRole(bot, bot:GetUnitName());	
	end	
		
	local botLoc = bot:GetLocation();
	if bot:IsAlive() and bot:GetCurrentActionType() == BOT_ACTION_TYPE_MOVE_TO and not IsLocationPassable(botLoc) then
		if bot.stuckLoc == nil then
			bot.stuckLoc = botLoc
			bot.stuckTime = DotaTime();
		elseif bot.stuckLoc ~= botLoc then
			bot.stuckLoc = botLoc
			bot.stuckTime = DotaTime();
		end
	else	
		bot.stuckTime = nil;
		bot.stuckLoc = nil;
	end
	
	if bot:GetAbilityPoints() > 0 then
		local lastIdx = #bot.abilities;
		local ability = bot:GetAbilityByName(bot.abilities[lastIdx]);
		if ability ~= nil and ability:CanAbilityBeUpgraded() and ability:GetLevel() < ability:GetMaxLevel() then
			if bot:GetUnitName() == "npc_dota_hero_troll_warlord" and bot.abilities[lastIdx] == "troll_warlord_whirling_axes_ranged" and ability:IsHidden() then
				bot:ActionImmediate_LevelAbility("troll_warlord_whirling_axes_melee");
			elseif bot:GetUnitName() == "npc_dota_hero_keeper_of_the_light" and bot.abilities[lastIdx] == "keeper_of_the_light_illuminate" and bot:HasScepter() then
				local ability_alt = bot:GetAbilityByName("keeper_of_the_light_spirit_form_illuminate");
				if ability_alt:IsHidden() then
					return;
				else
					bot:ActionImmediate_LevelAbility("keeper_of_the_light_spirit_form_illuminate");
				end			
			elseif ability:IsHidden() then
				return;	
			else
				bot:ActionImmediate_LevelAbility(bot.abilities[lastIdx]);
			end	
			bot.abilities[lastIdx] = nil;
		end
	end
	
end

function GetNumEnemyNearby(building)
	local nearbynum = 0;
	for i,id in pairs(GetTeamPlayers(GetOpposingTeam())) do
		if IsHeroAlive(id) then
			local info = GetHeroLastSeenInfo(id);
			if info ~= nil then
				local dInfo = info[1]; 
				if dInfo ~= nil and GetUnitToLocationDistance(building, dInfo.location) <= 2750 and dInfo.time_since_seen < 1.0 then
					nearbynum = nearbynum + 1;
				end
			end
		end
	end
	return nearbynum;
end

function GetNumOfAliveHeroes(team)
	local nearbynum = 0;
	for i,id in pairs(GetTeamPlayers(team)) do
		if IsHeroAlive(id) then
			nearbynum = nearbynum + 1;
		end
	end
	return nearbynum;
end

function GetRemainingRespawnTime()
	if TimeDeath == nil then
		return 0;
	else
		return bot:GetRespawnTime() - ( DotaTime() - TimeDeath );
	end
end

function IsMeepoClone()
	if bot:GetUnitName() == "npc_dota_hero_meepo" and bot:GetLevel() > 1 
	then
		for i=0, 5 do
			local item = bot:GetItemInSlot(i);
			if item ~= nil and not ( string.find(item:GetName(),"boots") or string.find(item:GetName(),"treads") )  
			then
				return false;
			end
		end
		return true;
    end
	return false;
end

local IsArcWardenClone = false;
function BuybackUsageThink() 
	
	if bot:IsInvulnerable() 
	   or not bot:IsHero() 
	   or bot:IsIllusion() 
	   or IsMeepoClone() 
	   or IsArcWardenClone == true
	   or role.ShouldBuyBack() == false 
	then
		return;
	end
	
	if bot:HasModifier('modifier_arc_warden_tempest_double') then
		IsArcWardenClone = true;
	end
	
	if bot:IsAlive() and TimeDeath ~= nil then
		TimeDeath = nil;
	end
	
	if not bot:HasBuyback() then
		return;
	end

	if not bot:IsAlive() then
		if TimeDeath == nil then
			TimeDeath = DotaTime();
		end
		--print(bot:GetUnitName()..":"..tostring(bot:GetRespawnTime()).."><"..tostring(RespawnTime))
	end
	
	local RespawnTime = GetRemainingRespawnTime();
	
	
	if RespawnTime > 116 --or (bot:GetLevel()==25 and RespawnTime > 96) 
	then
		bot:ActionImmediate_Chat("复活时间太长了:"..string.gsub(tostring(RespawnTime),"npc_dota_",""),true);
		bot:ActionImmediate_Buyback();
		role['lastbbtime'] = DotaTime();
		return;
	end	
	
	if bot:GetRespawnTime() < 60 then
		return;
	end
	
	if RespawnTime < 60 then
		return;
	end
	
	local ancient = GetAncient(GetTeam());
	
	if ancient ~= nil 
	then
		local nEnemies = GetNumEnemyNearby(ancient);
		local nAllies  = GetNumOfAliveHeroes(GetTeam())
		if  nEnemies > 0 and nEnemies >= nAllies and nEnemies - nAllies <= 3 then
			role['lastbbtime'] = DotaTime();
			bot:ActionImmediate_Chat("赶紧支援队友:"..string.gsub(tostring(RespawnTime),"npc_dota_",""),true);
			bot:ActionImmediate_Buyback();
			return;
		end	
	end

end

--[[function ItemUsageThink()
	--print(bot:GetUnitName().."item usage")
	if GetGameState()~=GAME_STATE_PRE_GAME and GetGameState()~= GAME_STATE_GAME_IN_PROGRESS then
		return;
	end
	
	UnImplementedItemUsage()
	--UseShrine()
end]]--

function PrintCourierState(state)
	
		if state == 0 then
			print("COURIER_STATE_IDLE ");
		elseif state == 1 then
			print("COURIER_STATE_AT_BASE");
		elseif state == 2 then
			print("COURIER_STATE_MOVING");
		elseif state == 3 then
			print("COURIER_STATE_DELIVERING_ITEMS");
		elseif state == 4 then
			print("COURIER_STATE_RETURNING_TO_BASE");
		elseif state == 5 then
			print("COURIER_STATE_DEAD");
		else
			print("UNKNOWN");
		end
		
end



local courierTime = -90;
local cState = -1;
bot.SShopUser = false;
local returnTime = -90;
local apiAvailable = false;
function CourierUsageThink()

	if DotaTime() < 60 and bot:GetAssignedLane() ~= LANE_MID 
	then
		return
	end

	if GetGameMode() == 23 or bot:IsInvulnerable() or not bot:IsHero() or bot:IsIllusion() or bot:HasModifier("modifier_arc_warden_tempest_double") or GetNumCouriers() == 0 then
		return;
	end
	
	local npcCourier = GetCourier(0);	
	local cState = GetCourierState( npcCourier );

	local courierPHP = npcCourier:GetHealth() / npcCourier:GetMaxHealth(); 
	
	if cState == COURIER_STATE_DEAD then
		npcCourier.latestUser = nil;
		return
	end
	
	if IsFlyingCourier(npcCourier) then
		local burst = npcCourier:GetAbilityByName('courier_shield');
		if IsTargetedByUnit(npcCourier) then
			if burst:IsFullyCastable() and apiAvailable == true 
			then
				bot:ActionImmediate_Courier( npcCourier, COURIER_ACTION_BURST );
				return
			elseif DotaTime() > returnTime + 3.0
			       --and not burst:IsFullyCastable() and not npcCourier:HasModifier('modifier_courier_shield') 
			then
				bot:ActionImmediate_Courier( npcCourier, COURIER_ACTION_RETURN );
				returnTime = DotaTime();
				return
			end
		end
	else	
		if IsTargetedByUnit(npcCourier) then
			if DotaTime() - returnTime > 3.0 then
				bot:ActionImmediate_Courier( npcCourier, COURIER_ACTION_RETURN );
				returnTime = DotaTime();
				return
			end
		end
	end
	
	if ( IsCourierAvailable() and cState ~= COURIER_STATE_IDLE )  then
		npcCourier.latestUser = "temp";
	end
	
	--FREE UP THE COURIER FOR HUMAN PLAYER
	if cState == COURIER_STATE_MOVING or IsHumanHaveItemInCourier() then
		npcCourier.latestUser = nil;
	end
	
	if bot.SShopUser and ( not bot:IsAlive() or bot:GetActiveMode() == BOT_MODE_SECRET_SHOP or not bot.SecretShop  ) then
		--bot:ActionImmediate_Chat( "Releasing the courier to anticipate secret shop stuck", true );
		npcCourier.latestUser = "temp";
		bot.SShopUser = false;
		bot:ActionImmediate_Courier( npcCourier, COURIER_ACTION_RETURN );
		return
	end
	
	if npcCourier.latestUser ~= nil and ( IsCourierAvailable() or cState == COURIER_STATE_RETURNING_TO_BASE ) and DotaTime() - returnTime > 3.0  then 
		
		if cState == COURIER_STATE_AT_BASE and courierPHP < 1.0 then
			return;
		end
		
		--RETURN COURIER TO BASE WHEN IDLE 
		if cState == COURIER_STATE_IDLE then
			bot:ActionImmediate_Courier( npcCourier, COURIER_ACTION_RETURN );
			return
		end
		
		--TAKE ITEM FROM STASH
		if  bot:IsAlive() and cState == COURIER_STATE_AT_BASE  then
			local nCSlot = GetCourierEmptySlot(npcCourier);
			local nMSlot = GetNumStashItem(bot);
			if nMSlot > 0 and nMSlot <= nCSlot and bot:GetStashValue() > 99
			then
				bot:ActionImmediate_Courier( npcCourier, COURIER_ACTION_TAKE_STASH_ITEMS );
				courierTime = DotaTime();
			end
		end
		
		--MAKE COURIER GOES TO SECRET SHOP
		if  bot:IsAlive() and bot.SecretShop and npcCourier:DistanceFromFountain() < 7000 and DotaTime() > courierTime + 2.0 then
			--bot:ActionImmediate_Chat( "Using Courier for secret shop.", true );
			bot:ActionImmediate_Courier( npcCourier, COURIER_ACTION_SECRET_SHOP )
			npcCourier.latestUser = bot;
			bot.SShopUser = true;
			UpdateSShopUserStatus(bot);
			courierTime = DotaTime();
			return
		end
		
		--TRANSFER ITEM IN COURIER
		if bot:IsAlive() and bot:GetCourierValue( ) > 0 and IsTheClosestToCourier(bot, npcCourier)
		   and ( npcCourier:DistanceFromFountain() < 7000 or GetUnitToUnitDistance(bot, npcCourier) < 1600 ) and DotaTime() > courierTime + 2.0
		then
			bot:ActionImmediate_Courier( npcCourier, COURIER_ACTION_TRANSFER_ITEMS )
			npcCourier.latestUser = bot;
			courierTime = DotaTime();
			return
		end
		
		--RETURN STASH ITEM WHEN DEATH
		if  not bot:IsAlive() and cState == COURIER_STATE_AT_BASE --COURIER_STATE_DELIVERING_ITEMS  
			and bot:GetCourierValue( ) > 0 and DotaTime() > courierTime + 2.0
		then
			bot:ActionImmediate_Courier( npcCourier, COURIER_ACTION_RETURN_STASH_ITEMS );
			npcCourier.latestUser = bot;
			courierTime = DotaTime();
			return
		end
		
	
	end
end

function IsHumanHaveItemInCourier()
	local numPlayer =  GetTeamPlayers(GetTeam());
	for i = 1, #numPlayer
	do
		if not IsPlayerBot(numPlayer[i]) then
			local member = GetTeamMember(i);
			if member ~= nil and member:IsAlive() and member:GetCourierValue( ) > 0 
			then
				return true;
			end
		end
	end
	return false;
end

function IsTheClosestToCourier(bot, npcCourier)
	local numPlayer =  GetTeamPlayers(GetTeam());
	local closest = nil;
	local closestD = 100000;
	for i = 1, #numPlayer
	do
		local member =  GetTeamMember(i);
		if member ~= nil and IsPlayerBot(numPlayer[i]) and member:IsAlive() and member:GetCourierValue( ) > 0 
		then
			local invFull = IsInvFull(member);
			local nStash = GetNumStashItem(member);
			if invFull == false 
				or ( invFull == true and nStash == 0 and bot.currListItemToBuy ~= nil and #bot.currListItemToBuy == 0 ) 
			then
				local dist = GetUnitToUnitDistance(member, npcCourier);
				
				if member:GetAssignedLane() == LANE_MID and member:GetLevel() < 8 and dist > 1600 
				then dist = dist * 1.62; end
				
				if dist < closestD then
					closest = member;
					closestD = dist;
				end
			end	
		end
	end
	return closest ~= nil and closest == bot
end

function GetCourierEmptySlot(courier)
	local amount = 0;
	for i=0, 8 do
		if courier:GetItemInSlot(i) == nil then
			amount = amount + 1;
		end
	end
	return amount;
end

function GetNumStashItem(unit)
	local amount = 0;
	for i=9, 14 do
		if unit:GetItemInSlot(i) ~= nil then
			amount = amount + 1;
		end
	end
	return amount;
end

function UpdateSShopUserStatus(bot)
	local numPlayer =  GetTeamPlayers(GetTeam());
	for i = 1, #numPlayer
	do
		local member =  GetTeamMember(i);
		if member ~= nil and IsPlayerBot(numPlayer[i]) and  member:GetUnitName() ~= bot:GetUnitName() 
		then
			member.SShopUser = false;
		end
	end
end

function IsTargetedByUnit(courier)
	for i = 0, 10 do
	local tower = GetTower(GetOpposingTeam(), i)
		if tower ~= nil and tower:GetAttackTarget() == courier then
			return true;
		end
	end
	for i,id in pairs(GetTeamPlayers(GetOpposingTeam())) do
		if IsHeroAlive(id) then
			local info = GetHeroLastSeenInfo(id);
			if info ~= nil then
				local dInfo = info[1];
				if dInfo ~= nil and GetUnitToLocationDistance(courier, dInfo.location) <= 700 and dInfo.time_since_seen < 0.5 then
					return true;
				end
			end
		end
	end
	return false;
end

function IsInvFull(npcHero)
	for i=0, 8 do
		if(npcHero:GetItemInSlot(i) == nil) then
			return false;
		end
	end
	return true;
end

function CanCastOnTarget( npcTarget )
	return npcTarget:CanBeSeen() and not npcTarget:IsMagicImmune() and not npcTarget:IsInvulnerable();
end

function CanCastOnMagicImmuneTarget( npcTarget )
	return npcTarget:CanBeSeen() and not npcTarget:IsInvulnerable();
end

function IsDisabled(npcTarget)
	if npcTarget:IsRooted( ) or npcTarget:IsStunned( ) or npcTarget:IsHexed( ) or npcTarget:IsSilenced() or npcTarget:IsNightmared() then
		return true;
	end
	return false;
end

function UseConsumables()

	
 
end

function GiveToMidLaner()
	local teamPlayers = GetTeamPlayers(GetTeam())
	local target = nil;
	for k,v in pairs(teamPlayers)
	do
		local member = GetTeamMember(k);  
		if member ~= nil 
			and not member:IsIllusion() 
			and member:IsAlive() 
			and member:GetAssignedLane() == LANE_MID 
		then
			local num_sts = GetItemCount(member, "item_tango_single"); 
			local num_ff = GetItemCount(member, "item_faerie_fire");   
			local num_stg = GetItemCharges(member, "item_tango");      
			if  num_sts + num_stg <= 1 then  
				return member;               
			end
		end
	end
	return nil;
end

function GetItemCount(unit, item_name)
	local count = 0;
	for i = 0, 8 
	do
		local item = unit:GetItemInSlot(i)
		if item ~= nil and item:GetName() == item_name then
			count = count + 1;
		end
	end
	return count;
end

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

function HaveEmptyMainSlot(unit)
	
	for i = 0, 5 
	do
		local item = unit:GetItemInSlot(i)
		if item == nil 
		then
			return true;
		end
	end
	return false;
	
end

function CanSwitchPTStat(pt)
	if bot:GetPrimaryAttribute() == ATTRIBUTE_STRENGTH and pt:GetPowerTreadsStat() ~= ATTRIBUTE_STRENGTH then
		return true;
	elseif bot:GetPrimaryAttribute() == ATTRIBUTE_AGILITY  and pt:GetPowerTreadsStat() ~= ATTRIBUTE_INTELLECT then
		return true;
	elseif bot:GetPrimaryAttribute() == ATTRIBUTE_INTELLECT and pt:GetPowerTreadsStat() ~= ATTRIBUTE_AGILITY then
		return true;
	end 
	return false;
end

local myTeam = GetTeam()
local opTeam = GetOpposingTeam()
local teamT1Top = GetTower(myTeam,TOWER_TOP_1):GetLocation()
local teamT1Mid = GetTower(myTeam,TOWER_MID_1):GetLocation()
local teamT1Bot = GetTower(myTeam,TOWER_BOT_1):GetLocation()
local enemyT1Top = GetTower(opTeam,TOWER_TOP_1):GetLocation()
local enemyT1Mid = GetTower(opTeam,TOWER_MID_1):GetLocation()
local enemyT1Bot = GetTower(opTeam,TOWER_BOT_1):GetLocation()

function GetLaningTPLocation(nLane)
	if nLane == LANE_TOP then
		return teamT1Top
	elseif nLane == LANE_MID then
		return teamT1Mid
	elseif nLane == LANE_BOT then
		return teamT1Bot			
	end	
	return teamT1Mid
end	

function GetDefendTPLocation(nLane)
	return GetLaneFrontLocation(opTeam,nLane,-1600)
end

function GetPushTPLocation(nLane)
	return GetLaneFrontLocation(myTeam,nLane,0)
end

local idlt = 0;
local idlm = 0;
local idlb = 0;
function printDefendLaneDesire()
	local md = bot:GetActiveMode()
	local mdd = bot:GetActiveModeDesire()
	local dlt = GetDefendLaneDesire(LANE_TOP)
	local dlm = GetDefendLaneDesire(LANE_MID)
	local dlb = GetDefendLaneDesire(LANE_BOT)
	if bot:GetPlayerID() == 2 then
		if idlt ~= dlt then 
			idlt = dlt
			print("DefendLaneDesire TOP: "..tostring(dlt))
		elseif idlm ~= dlm then 
			idlm = dlm
			print("DefendLaneDesire MID: "..tostring(dlm))
		elseif idlb ~= dlb then 
			idlb = dlb
			print("DefendLaneDesire TOP: "..tostring(dlb))
		end	
		if md == BOT_MODE_DEFEND_TOWER_TOP then 
			print("Def Tower Des TOP: "..tostring(mdd))
		elseif md == BOT_MODE_DEFEND_TOWER_MID then
			print("Def Tower Des MID: "..tostring(mdd))
		elseif md == BOT_MODE_DEFEND_TOWER_BOT then 	
			print("Def Tower Des BOT: "..tostring(mdd))
		end
	end	
end

local enemyPids = nil;
function CanJuke()
	
	local allyTowers=bot:GetNearbyTowers(200,false); 
	if allyTowers[1] ~= nil						     
	then
		return true;
	end

	if enemyPids == nil then
		enemyPids = GetTeamPlayers(GetOpposingTeam())
	end	
	local heroHG = GetHeightLevel(bot:GetLocation())
	for i = 1, #enemyPids do
		local info = GetHeroLastSeenInfo(enemyPids[i])
		if info ~= nil then
			local dInfo = info[1]; 
			if dInfo ~= nil and dInfo.time_since_seen < 2.0  
				and GetUnitToLocationDistance(bot,dInfo.location) < 1300 
				and GetHeightLevel(dInfo.location) < heroHG  
			then
				return false;
			end
		end	
	end
	return true;
end	

function GetNumHeroWithinRange(nRange)
	if enemyPids == nil then
		enemyPids = GetTeamPlayers(GetOpposingTeam())
	end	
	local cHeroes = 0;
	for i = 1, #enemyPids do
		local info = GetHeroLastSeenInfo(enemyPids[i])
		if info ~= nil then
			local dInfo = info[1]; 
			if dInfo ~= nil and dInfo.time_since_seen < 2.0  
				and GetUnitToLocationDistance(bot,dInfo.location) < nRange 
			then
				cHeroes = cHeroes + 1;
			end
		end	
	end
	return cHeroes;
end	

function GetAlliesNumWithinRange(nRange)
	local nAllies = bot:GetNearbyHeroes(1600,false,BOT_MODE_NONE)
	return #nAllies;
end

function IsFarmingAlways(bot)
	local nTarget = bot:GetAttackTarget();	
	if mutil.IsValid(nTarget)
	   and nTarget:GetTeam() == TEAM_NEUTRAL
	   and GetNumEnemyNearby(GetAncient(GetTeam())) >= 2
	then
		return true;
	end
	
	local nAlles = bot:GetNearbyHeroes(800,false,BOT_MODE_NONE);
	if mutil.IsValid(nTarget)
		and nTarget:IsAncientCreep()
		and bot:GetPrimaryAttribute() == ATTRIBUTE_INTELLECT
		and #nAlles < 2
	then
		return true;
	end
	
	return false;
end

local tpThreshold = 4000;

function ShouldTP()
	local tpLoc = nil;
	local mode = bot:GetActiveMode();
	local modDesire = bot:GetActiveModeDesire();
	local botLoc = bot:GetLocation();
	local enemies = GetNumHeroWithinRange(1600);
	local allies  = GetAlliesNumWithinRange(1600);
	local ifl = IsItemAvailable("item_flask");
	
	if bot:HasModifier("modifier_kunkka_x_marks_the_spot")
		or ( bot:HasModifier("modifier_oracle_false_promise_timer")
			 and mutil.GetModifierTime(bot,"modifier_oracle_false_promise_timer") <= 3.6 )
		or ( bot:HasModifier("modifier_jakiro_macropyre_burn")
			 and mutil.GetModifierTime(bot,"modifier_jakiro_macropyre_burn") >= 1.4 )
		or ( bot:HasModifier("modifier_arc_warden_tempest_double")
			 and bot:GetRemainingLifespan() < 3.2 )
	then
		return false,nil;
	end	
	
	if mode == BOT_MODE_LANING and enemies == 0 then
		local assignedLane = bot:GetAssignedLane();
		if assignedLane == LANE_TOP  then
			local botAmount = GetAmountAlongLane(LANE_TOP, botLoc)
			local laneFront = GetLaneFrontAmount(myTeam, LANE_TOP, false)
			if botAmount.distance > tpThreshold or botAmount.amount < laneFront / 5 then 
				tpLoc = GetLaningTPLocation(LANE_TOP)
			end	
		elseif assignedLane == LANE_MID then
			local botAmount = GetAmountAlongLane(LANE_MID, botLoc)
			local laneFront = GetLaneFrontAmount(myTeam, LANE_MID, false)
			if botAmount.distance > tpThreshold or botAmount.amount < laneFront / 5 then 
				tpLoc = GetLaningTPLocation(LANE_MID)
			end	
		elseif assignedLane == LANE_BOT then
			local botAmount = GetAmountAlongLane(LANE_BOT, botLoc)
			local laneFront = GetLaneFrontAmount(myTeam, LANE_BOT, false)
			if botAmount.distance > tpThreshold or botAmount.amount < laneFront / 5 then 
				tpLoc = GetLaningTPLocation(LANE_BOT)
			end	
		end
	elseif mode == BOT_MODE_DEFEND_TOWER_TOP and modDesire >= BOT_MODE_DESIRE_MODERATE and enemies == 0 then
		local botAmount = GetAmountAlongLane(LANE_TOP, botLoc)
		local laneFront = GetLaneFrontAmount(myTeam, LANE_TOP, false)
		if botAmount.distance > tpThreshold or botAmount.amount < laneFront / 5 then 
			tpLoc = GetDefendTPLocation(LANE_TOP)
		end	
	elseif mode == BOT_MODE_DEFEND_TOWER_MID and modDesire >= BOT_MODE_DESIRE_MODERATE and enemies == 0 then
		local botAmount = GetAmountAlongLane(LANE_MID, botLoc)
		local laneFront = GetLaneFrontAmount(myTeam, LANE_MID, false)
		if botAmount.distance > tpThreshold or botAmount.amount < laneFront / 5 then 
			tpLoc = GetDefendTPLocation(LANE_MID)
		end	
	elseif mode == BOT_MODE_DEFEND_TOWER_BOT and modDesire >= BOT_MODE_DESIRE_MODERATE and enemies == 0 then	
		local botAmount = GetAmountAlongLane(LANE_BOT, botLoc)
		local laneFront = GetLaneFrontAmount(myTeam, LANE_BOT, false)
		if botAmount.distance > tpThreshold or botAmount.amount < laneFront / 5 then 
			tpLoc = GetDefendTPLocation(LANE_BOT)
		end	
	elseif mode == BOT_MODE_PUSH_TOWER_TOP and modDesire >= BOT_MODE_DESIRE_MODERATE and enemies == 0 then
		local botAmount = GetAmountAlongLane(LANE_TOP, botLoc)
		local laneFront = GetLaneFrontAmount(myTeam, LANE_TOP, false)
		if botAmount.distance > tpThreshold or botAmount.amount < laneFront / 5 then 
			tpLoc = GetPushTPLocation(LANE_TOP)
		end	
	elseif mode == BOT_MODE_PUSH_TOWER_MID and modDesire >= BOT_MODE_DESIRE_MODERATE and enemies == 0 then
		local botAmount = GetAmountAlongLane(LANE_MID, botLoc)
		local laneFront = GetLaneFrontAmount(myTeam, LANE_MID, false)
		if botAmount.distance > tpThreshold or botAmount.amount < laneFront / 5 then 
			tpLoc = GetPushTPLocation(LANE_MID)
		end	
	elseif mode == BOT_MODE_PUSH_TOWER_BOT and modDesire >= BOT_MODE_DESIRE_MODERATE and enemies == 0 then
		local botAmount = GetAmountAlongLane(LANE_BOT, botLoc)
		local laneFront = GetLaneFrontAmount(myTeam, LANE_BOT, false)
		if botAmount.distance > tpThreshold or botAmount.amount < laneFront / 5 then 
			tpLoc = GetPushTPLocation(LANE_BOT)
		end	
	elseif mode == BOT_MODE_DEFEND_ALLY and modDesire >= BOT_MODE_DESIRE_MODERATE and role.CanBeSupport(bot:GetUnitName()) and enemies == 0 then
		local target = bot:GetTarget()
		if target ~= nil and target:IsHero() and GetUnitToUnitDistance(bot,target) > tpThreshold then
			local nearbyTower = target:GetNearbyTowers(1300, false)    ---
			if nearbyTower ~= nil and #nearbyTower > 0 and bot:GetMana() >  0.25*bot:GetMaxMana()  then
				tpLoc = nearbyTower[1]:GetLocation()
			end
		end
	elseif mode == BOT_MODE_RETREAT and modDesire >= BOT_MODE_DESIRE_MODERATE 
	then
		if bot:GetHealth() < 0.15*bot:GetMaxHealth() 
		   and bot:WasRecentlyDamagedByAnyHero(5.0) 
		   and enemies == 0 
		   and ifl == nil
		   and not  bot:HasModifier("modifier_flask_healing")
		   and bot:DistanceFromFountain() > 3800
		then
			tpLoc = mutil.GetTeamFountain();
		elseif bot:GetHealth() < 0.25*bot:GetMaxHealth() 
		       and bot:WasRecentlyDamagedByAnyHero(8.0) 
			   and CanJuke() == true 
			   and ifl == nil
			   and not  bot:HasModifier("modifier_flask_healing")
			   and bot:DistanceFromFountain() > 3800 
			then
			   print(bot:GetUnitName().." JUKE TP")
			   tpLoc = mutil.GetTeamFountain();
		elseif  (bot:GetHealth()/bot:GetMaxHealth() < 0.25 or bot:GetHealth()/bot:GetMaxHealth() + bot:GetMana() /bot:GetMaxMana() < 0.3)
				and CanJuke() == true 
				and bot:DistanceFromFountain() > 3800
				and enemies <= 1
				and ifl == nil
				and not  bot:HasModifier("modifier_flask_healing")
				and not  bot:HasModifier("modifier_clarity_potion")
				and not  bot:HasModifier("modifier_item_urn_heal")
				and not  bot:HasModifier("modifier_filler_heal")
				and not  bot:HasModifier("modifier_item_spirit_vessel_heal")
				and not  bot:HasModifier("modifier_bottle_regeneration")
				and not  bot:HasModifier("modifier_tango_heal")
			then
				print(bot:GetUnitName().."撤退了回家补血补蓝")
				tpLoc = mutil.GetTeamFountain();
		    end			
	elseif bot:HasModifier('modifier_bloodseeker_rupture') and enemies <= 1 then
		local allies = bot:GetNearbyHeroes(1000, false, BOT_MODE_NONE);
		if #allies <= 1 then
			tpLoc = mutil.GetTeamFountain();
		end
	elseif  (bot:GetHealth()/bot:GetMaxHealth() + bot:GetMana()/bot:GetMaxMana() < 0.35 or bot:GetHealth()/bot:GetMaxHealth() < 0.25)
			and CanJuke() == true 
			and bot:DistanceFromFountain() > 4800
			and enemies <= 1 and allies <= 1
			and mutil.GetProperTarget(bot) == nil
			and ifl == nil
			and not  bot:HasModifier("modifier_flask_healing")
			and not  bot:HasModifier("modifier_clarity_potion")
			and not  bot:HasModifier("modifier_item_urn_heal")
			and not  bot:HasModifier("modifier_filler_heal")
			and not  bot:HasModifier("modifier_item_spirit_vessel_heal")
			and not  bot:HasModifier("modifier_bottle_regeneration")
			and not  bot:HasModifier("modifier_tango_heal")
		then
			print(bot:GetUnitName().."状态不好回家补血补蓝")
			tpLoc = mutil.GetTeamFountain();
	elseif IsFarmingAlways(bot) then
			print(bot:GetUnitName().."好吧,不打野了马上回家.");
			tpLoc = GetAncient(GetTeam()):GetLocation()
	elseif mutil.IsStuck(bot) and enemies == 0 then
		bot:ActionImmediate_Chat("I'm using tp while stuck.", true);
		tpLoc = GetAncient(GetTeam()):GetLocation()
	end	
	
	if tpLoc ~= nil and GetUnitToLocationDistance(bot, tpLoc) > 3800 then
		return true, tpLoc;
	end
	return false, nil;
end

local giveTime = -90;
local chattime = 0
local firstUseTime = 0;
local aetherRange = 0;

function UnImplementedItemUsage()
	
	if not bot:IsAlive() or bot:IsMuted() then return end
	
	local tableNearbyEnemyHeroes = bot:GetNearbyHeroes( 1000, true, BOT_MODE_NONE );
	local nearbyEnemyTower = bot:GetNearbyTowers(888,true); 
	local npcTarget = mutil.GetProperTarget(bot);
	local mode = bot:GetActiveMode();
	local npcBot = bot;
	
	if aetherRange == 0 then
		local aether = IsItemAvailable("item_aether_lens");
		if aether ~= nil then aetherRange = 250 end
	end

	local se = IsItemAvailable("item_silver_edge");
	if se == nil then se = IsItemAvailable("item_invis_sword") end
    if se ~= nil and se:IsFullyCastable() and not bot:IsUsingAbility()and not bot:IsCastingAbility()
	then
		if bot:GetActiveMode() == BOT_MODE_RETREAT 
			and bot:GetActiveModeDesire() > BOT_MODE_DESIRE_MODERATE
			and	tableNearbyEnemyHeroes ~= nil 
			and #tableNearbyEnemyHeroes > 0
			
		then
			bot:Action_UseAbility(se);
			return;
	    end
		
		if bot:GetHealth()/bot:GetMaxHealth() < 0.2
		   and (#tableNearbyEnemyHeroes > 0 or bot:WasRecentlyDamagedByAnyHero(5.0))
		then
			bot:Action_UseAbility(se);
			return;
	    end		
	end
	
	local shivas = IsItemAvailable("item_shivas_guard")
	if shivas ~= nil and shivas:IsFullyCastable()
	then
		local tableNearbyCreeps = bot:GetNearbyCreeps(900,true);
		if #tableNearbyCreeps >= 6 
		   or #tableNearbyEnemyHeroes >= 1
		then
			bot:Action_UseAbility(shivas);
			return;
		end
	end
	
------------------*************************************----------------------------------	


	if  bot:NumQueuedActions() > 0 
	    or bot:IsChanneling() 
--		or bot:IsUsingAbility()
		or bot:IsStunned()
		or bot:IsHexed()
		or bot:IsCastingAbility( )
		or bot:IsInvisible() 
		or bot:IsMuted() 
		or bot:HasModifier("modifier_doom_bringer_doom")
	then
		return;
	end
	
	local tps = bot:GetItemInSlot(15);
	if tps ~= nil and tps:IsFullyCastable() and DotaTime() > 0
	   and #nearbyEnemyTower == 0
	   and (not bot:WasRecentlyDamagedByAnyHero(3.1) 
	            or bot:HasModifier("modifier_bloodseeker_rupture") 
				or #tableNearbyEnemyHeroes == 0)
	then
		local tpLoc = nil
		local shouldTP = false
		shouldTP, tpLoc = ShouldTP()
		if shouldTP then 
			if tpLoc ~= mutil.GetTeamFountain()
			then
				nAncient = GetAncient(GetTeam());
				nAncientDistance = GetUnitToLocationDistance(GetAncient(GetTeam()),tpLoc);
				if nAncientDistance > 1800 and nAncientDistance < 2800
				then
					tpLoc = mutil.GetLocationTowardDistanceLocation(nAncient,tpLoc,nAncientDistance - 800);
				end
			end
			bot:Action_UseAbilityOnLocation(tps, tpLoc);
			return;
		end	
		
		if bot:GetPrimaryAttribute() == ATTRIBUTE_AGILITY 
		   and bot:GetLevel() >= 12 
		   and mode ~= BOT_MODE_ROSHAN
		   and mutil.AlliesCount(bot,1200) < 4
		then
		    local nEnemy = bot:GetNearbyHeroes(1400,true,BOT_MODE_NONE);
			local mostFarmDesireLane,mostFarmDesire = mutil.GetMostFarmLaneDesire();

			if mostFarmDesire > BOT_MODE_DESIRE_VERYHIGH *1.05
				and #nEnemy == 0
				and not IsAllyChanneling()				
			then
				tpLoc = GetLaneFrontLocation(GetTeam(),mostFarmDesireLane,0);
				local nAlles = mutil.GetAlliesNearLoc(tpLoc, 1200);
				if GetUnitToLocationDistance(bot,tpLoc) > 3000 and #nAlles == 0
				then
					bot:Action_UseAbilityOnLocation(tps, tpLoc);
					return;
				end
			end	
		end
	end	
	
	local pt = IsItemAvailable("item_power_treads");
	if pt~=nil and pt:IsFullyCastable() 
		and not mutil.IsPTHero(bot)
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
		elseif  mode == BOT_MODE_RETREAT 
				or  bot:GetHealth()/bot:GetMaxHealth() < 0.2
				or (pt:GetPowerTreadsStat() == ATTRIBUTE_STRENGTH and bot:GetHealth()/bot:GetMaxHealth() < 0.25)
				or mutil.IsNotAttackProjectileIncoming(bot, 1600)
			then
				if pt:GetPowerTreadsStat() ~= ATTRIBUTE_STRENGTH
				then
					bot:Action_UseAbility(pt);
					return
				end
		elseif  mode == BOT_MODE_ATTACK 
			then
				if  CanSwitchPTStat(pt) 
				then
					bot:Action_UseAbility(pt);
					return
				end
		else
			local enemies = bot:GetNearbyHeroes( 1600, true, BOT_MODE_NONE );
			local creeps  = bot:GetNearbyCreeps(1200,true);
			local target  = mutil.GetProperTarget(bot);
			if  #creeps == 0
				and  #enemies == 0 
				and  (target == nil or GetUnitToUnitDistance(bot,target) > 1600)
				and  bot:DistanceFromFountain() > 400
				and  mode ~= BOT_MODE_ROSHAN
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
	
	
	local bas = IsItemAvailable("item_ring_of_basilius");
	if bas~=nil and bas:IsFullyCastable() and DotaTime() % 3 < 1 
	then
		if mode == BOT_MODE_LANING and not bas:GetToggleState() then
			bot:Action_UseAbility(bas);
			return
		elseif mode ~= BOT_MODE_LANING and bas:GetToggleState() then
			bot:Action_UseAbility(bas);
			return
		end
	end
	

	local itg=IsItemAvailable("item_tango");
	if itg~=nil and itg:IsFullyCastable() then
		local tCharge = itg:GetCurrentCharges()
		if DotaTime() > -86 and DotaTime() < 0 and bot:DistanceFromFountain() < 400 and (role.CanBeSupport(bot:GetUnitName()) or bot:GetUnitName() == "npc_dota_hero_zuus")
		   and bot:GetAssignedLane() ~= LANE_MID and tCharge > 2 and DotaTime() > giveTime + 2.0 then
			local target = GiveToMidLaner()
			if target ~= nil then
				bot:ActionImmediate_Chat(string.gsub(bot:GetUnitName(),"npc_dota_hero_","")..
						" giving tango to "..
						string.gsub(target:GetUnitName(),"npc_dota_hero_","")
						, false);
--				bot:ActionImmediate_Chat(tostring(bot == bot).."每秒攻击和攻击前摇"..tostring(bot == target),true)
				bot:Action_UseAbilityOnEntity(itg, target);
				giveTime = DotaTime();
				return;
			end
		elseif bot:GetLevel() < 12
			  and #tableNearbyEnemyHeroes == 0
			  and tCharge > 1 
			  and DotaTime() > 30
			  and DotaTime() > giveTime + 2.0 
			then
			local allies = bot:GetNearbyHeroes(800, false, BOT_MODE_NONE)
			for _,ally in pairs(allies)
			do
				if mutil.IsValid(ally) and ally ~= bot
				then
					local tangoSlot = ally:FindItemSlot('item_tango');
					if tangoSlot == -1 
					   and not ally:IsIllusion() 
					   and not ally:HasModifier("modifier_arc_warden_tempest_double")
					   and not ally:GetUnitName() == "npc_dota_hero_meepo"
					   and GetItemCount(ally, "item_tango_single") == 0 
					   and HaveEmptyMainSlot(ally)
					then
						bot:Action_UseAbilityOnEntity(itg, ally);
						giveTime = DotaTime();
						return
					end
				end
			end
		end
	end
	
	
	local its=IsItemAvailable("item_tango_single");
	local tango = its;
	local item_tango_rate = 160; 
	if(its == nil or not its:IsFullyCastable())
	then
		tango = itg;
		item_tango_rate = 200;
	end
	if tango ~= nil and DotaTime() > 0 
	   and tango:IsFullyCastable() 
	   and bot:DistanceFromFountain() > 4000 
	then
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
					npcBot:Action_UseAbilityOnTree(tango, nearbyTrees[1]);
					return;
				end
				
				if bot:GetMaxHealth() - bot:GetHealth() > item_tango_rate *0.38
				   and bot:WasRecentlyDamagedByAnyHero(1.0)
				   and ( bot:GetActiveMode() == BOT_MODE_ATTACK 
				         or ( bot:GetActiveMode() == BOT_MODE_RETREAT 
						      and bot:GetActiveModeDesire() > BOT_MODE_DESIRE_HIGH ) )
				then
					npcBot:Action_UseAbilityOnTree(tango, nearbyTrees[1]);
					return;
				end
			end
		end
	end	
	
	
	local bdg=IsItemAvailable("item_blink");
	if bdg~=nil and bdg:IsFullyCastable() then
		if mutil.IsStuck(bot)
		then
			bot:ActionImmediate_Chat("I'm using blink while stuck.", true);
			bot:Action_UseAbilityOnLocation(bdg, bot:GetXUnitsTowardsLocation( GetAncient(GetTeam()):GetLocation(), 1100 ));
			return;
		end
	end
	
	
	local its=IsItemAvailable("item_tango_single");
	if its~=nil and its:IsFullyCastable() and bot:DistanceFromFountain() > 1000 and DotaTime() > 0 and npcTarget == nil then
	    local tCount = GetItemCount(bot, "item_tango_single")
		if DotaTime() > 4 *60 
		   and tCount >= 2
		then
			local tableNearbyEnemyHeroes = bot:GetNearbyHeroes( 1600, true, BOT_MODE_NONE );
			local trees = bot:GetNearbyTrees(1000);
			if trees[1] ~= nil  and ( IsLocationVisible(GetTreeLocation(trees[1])) or IsLocationPassable(GetTreeLocation(trees[1])) )
			   and #tableNearbyEnemyHeroes == 0 
			then
				bot:Action_UseAbilityOnTree(its, trees[1]);
				return;
			end
		end
	
		if DotaTime() > 7*60 
		then
			local tableNearbyEnemyHeroes = bot:GetNearbyHeroes( 1600, true, BOT_MODE_NONE );
			local trees = bot:GetNearbyTrees(1000);
			if trees[1] ~= nil  and ( IsLocationVisible(GetTreeLocation(trees[1])) or IsLocationPassable(GetTreeLocation(trees[1])) )
			   and #tableNearbyEnemyHeroes == 0 
			then
				bot:Action_UseAbilityOnTree(its, trees[1]);
				return;
			end
		end
	end
	
	
	
	local icl =IsItemAvailable("item_clarity");
	if icl~=nil and icl:IsFullyCastable() and bot:DistanceFromFountain() > 4000 then
		if DotaTime() > 0 
		then
			local tableNearbyEnemyHeroes = bot:GetNearbyHeroes( 800, true, BOT_MODE_NONE );
			if  (bot:GetMana() / bot:GetMaxMana())  < 0.35 
				and not bot:HasModifier("modifier_clarity_potion")
				and #tableNearbyEnemyHeroes == 0 
				and not bot:WasRecentlyDamagedByAnyHero(5.0)
			then
				bot:Action_UseAbilityOnEntity(icl, bot);
				return;
			end
			
			local Allies=npcBot:GetNearbyHeroes(300,false,BOT_MODE_NONE);
			local NeedManaAlly = nil
			local NeedManaAllyMana = 99999
			for _,Ally in pairs(Allies) do
				if mutil.IsValid(Ally)
				   and not Ally:HasModifier("modifier_clarity_potion")  
				   and not Ally:WasRecentlyDamagedByAnyHero(5.0)
				   and CanCastOnTarget(Ally) 
				   and not Ally:IsIllusion()
				   and not Ally:IsChanneling() 
				   and Ally:GetMaxMana() - Ally:GetMana() > 350 
				   and #tableNearbyEnemyHeroes == 0 				   				   			
				then
					if(Ally:GetMana() < NeedManaAllyMana )
					then
						NeedManaAlly = Ally
						NeedManaAllyMana = Ally:GetMana()
					end
				end
			end		
			if(NeedManaAlly ~= nil)
			then
				bot:Action_UseAbilityOnEntity(icl,NeedManaAlly );
				return;
			end
		end
	end
	
	
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
				npcBot:Action_UseAbilityOnEntity(ifl, npcBot);
				return;
			end
			
			local Allies=npcBot:GetNearbyHeroes(600,false,BOT_MODE_NONE);
			local NeedHealAlly = nil
			local NeedHealAllyHealth = 99999
			for _,Ally in pairs(Allies) do
				if mutil.IsValid(Ally)
				   and not Ally:HasModifier("modifier_filler_heal")  
				   and not Ally:WasRecentlyDamagedByAnyHero(5.0)
				   and CanCastOnTarget(Ally) 
				   and not Ally:IsIllusion()
				   and not Ally:IsChanneling()
				   and Ally:GetMaxHealth() - Ally:GetHealth() > 550 
				   and #tableNearbyEnemyHeroes == 0 				   				   			
				then
					if(Ally:GetHealth() < NeedHealAllyHealth )
					then
						NeedHealAlly = Ally
						NeedHealAllyHealth = Ally:GetHealth()
					end
				end
			end		
			if(NeedHealAlly ~= nil)
			then
				bot:Action_UseAbilityOnEntity(ifl,NeedHealAlly );
				return;
			end
			
		end
	end
	
	
	
	local mg=IsItemAvailable("item_enchanted_mango");
	if mg~=nil and mg:IsFullyCastable() then
		if bot:GetMana()/bot:GetMaxMana() < 0.10 and mode == BOT_MODE_ATTACK then
			bot:Action_UseAbility(mg);
			return;
		end
	end
	
	
	local tok=IsItemAvailable("item_tome_of_knowledge");
	if tok~=nil and tok:IsFullyCastable() then
		if firstUseTime == 0 
		then
			firstUseTime = DotaTime();
		end
		
		if firstUseTime < DotaTime() - 6.1
		then
			firstUseTime = 0;
			bot:Action_UseAbility(tok);
			return;
		end
	end
	
	
	local ff=IsItemAvailable("item_faerie_fire");
	if ff~=nil and ff:IsFullyCastable() then
		if ( mode == BOT_MODE_RETREAT and 
			bot:GetActiveModeDesire() >= BOT_MODE_DESIRE_HIGH and 
			bot:DistanceFromFountain() > 0 and
			( bot:GetHealth() / bot:GetMaxHealth() ) < 0.15 ) or DotaTime() > 10*60
		then
			bot:Action_UseAbility(ff);
			return;
		end
	end
	
	
	local bst=IsItemAvailable("item_bloodstone");
	if bst ~= nil and bst:IsFullyCastable() then
		if  mode == BOT_MODE_RETREAT and 
			bot:GetActiveModeDesire() >= BOT_MODE_DESIRE_HIGH and 
			( bot:GetHealth() / bot:GetMaxHealth() ) < 0.10 - ( bot:GetLevel() / 500 ) and
			( bot:GetMana() / bot:GetMaxMana() > 0.6 )
		then
			bot:Action_UseAbility(bst);
			return;
		end
	end
	
	
	local pb=IsItemAvailable("item_phase_boots");
	if pb~=nil and pb:IsFullyCastable() 
	then
		if mutil.IsRunning(bot) ------
		then
			bot:Action_UseAbility(pb);
			return;
		end	
	end
	
	
	local eb=IsItemAvailable("item_ethereal_blade");
	if eb~=nil and eb:IsFullyCastable() and bot:GetUnitName() ~= "npc_dota_hero_morphling"
	then
		if ( mode == BOT_MODE_ATTACK or
			 mode == BOT_MODE_ROAM or
			 mode == BOT_MODE_TEAM_ROAM or
			 mode == BOT_MODE_DEFEND_ALLY )
		then
			local npcTarget = mutil.GetProperTarget(bot);
			if ( npcTarget ~= nil and npcTarget:IsHero() and CanCastOnTarget(npcTarget) and GetUnitToUnitDistance(npcTarget, bot) < 1000 )
			then
			    bot:Action_UseAbilityOnEntity(eb,npcTarget);
				return
			end
		end
	end
	
	
	local rs=IsItemAvailable("item_refresher_shard");
	if rs~=nil and rs:IsFullyCastable() 
	then
		if ( mode == BOT_MODE_ATTACK or
			 mode == BOT_MODE_ROAM or
			 mode == BOT_MODE_TEAM_ROAM or
			 mode == BOT_MODE_GANK or
			 mode == BOT_MODE_DEFEND_ALLY ) and mutil.CanUseRefresherShard(bot)  
		then
			bot:Action_UseAbility(rs);
			return
		end
	end
	
	
	local ro=IsItemAvailable("item_refresher");
	if ro~=nil and ro:IsFullyCastable() 
	then
		if ( mode == BOT_MODE_ATTACK or
			 mode == BOT_MODE_ROAM or
			 mode == BOT_MODE_TEAM_ROAM or
			 mode == BOT_MODE_GANK or
			 mode == BOT_MODE_DEFEND_ALLY ) and mutil.CanUseRefresherOrb(bot)  
		then
			bot:Action_UseAbility(ro);
			return
		end
	end
	
	
	local sc=IsItemAvailable("item_solar_crest");
	if sc == nil then sc=IsItemAvailable("item_medallion_of_courage"); end
	if sc~=nil and sc:IsFullyCastable() 
	then
		if ( mode == BOT_MODE_ATTACK or
			 mode == BOT_MODE_ROAM or
			 mode == BOT_MODE_TEAM_ROAM or
			 mode == BOT_MODE_GANK or
			 mode == BOT_MODE_DEFEND_ALLY )
		then
			if mutil.IsValidTarget(npcTarget) 
			   and not npcTarget:HasModifier('modifier_item_solar_crest_armor_reduction') 
			   and not npcTarget:HasModifier('modifier_item_medallion_of_courage_armor_reduction') 
			   and not npcTarget:IsMagicImmune()
			   and (GetUnitToUnitDistance(npcTarget, bot) < bot:GetAttackRange()
					or (GetUnitToUnitDistance(npcTarget, bot) < 1000
					    and mutil.GetOtherAllyHeroCountAroundTarget(npcTarget, 600, bot) >= 1) )
			then
			    bot:Action_UseAbilityOnEntity(sc, npcTarget);
				return
			end
		end
	end
	
	if sc~=nil and sc:IsFullyCastable() then
		local Allies=bot:GetNearbyHeroes(1000,false,BOT_MODE_NONE);
		for _,Ally in pairs(Allies) do
			if Ally ~= bot
			   and mutil.IsValidTarget(Ally)
			   and not Ally:IsIllusion()
			   and not Ally:HasModifier('modifier_item_solar_crest_armor_addition') 
			   and not Ally:HasModifier('modifier_item_medallion_of_courage_armor_addition') 
			   and not Ally:HasModifier("modifier_arc_warden_tempest_double")
			   and (( Ally:GetHealth()/Ally:GetMaxHealth() < 0.35 and #tableNearbyEnemyHeroes > 0 and CanCastOnTarget(Ally) ) 
					  or ( mutil.IsValid(Ally:GetAttackTarget()) and GetUnitToUnitDistance(Ally,Ally:GetAttackTarget()) <= Ally:GetAttackRange() )
					  or ( IsDisabled(Ally) and CanCastOnTarget(Ally) ) )
			then
				bot:Action_UseAbilityOnEntity(sc,Ally);
				return;
			end
		end
	end
	
	
	local hood=IsItemAvailable("item_hood_of_defiance");
    if hood~=nil and hood:IsFullyCastable() and bot:GetHealth()/bot:GetMaxHealth()<0.8 and not bot:HasModifier('modifier_item_pipe_barrier')
	then
		if tableNearbyEnemyHeroes ~= nil and #tableNearbyEnemyHeroes > 0 then
			bot:Action_UseAbility(hood);
			return;
		end
	end
	
	
	local hod=IsItemAvailable("item_helm_of_the_dominator");
	if hod~=nil and hod:IsFullyCastable() 
	then
		local maxHP = 0;
		local NCreep = nil;
		local tableNearbyCreeps = bot:GetNearbyCreeps( 1000, true );
		if #tableNearbyCreeps >= 2 then
			for _,creeps in pairs(tableNearbyCreeps)
			do
				if mutil.IsValid(creeps)
				then
					local CreepHP = creeps:GetHealth();
					if CreepHP > maxHP and ( creeps:GetHealth() / creeps:GetMaxHealth() ) > .75  and not creeps:IsAncientCreep()
					then
						NCreep = creeps;
						maxHP = CreepHP;
					end
				end
			end
		end
		if NCreep ~= nil then
			bot:Action_UseAbilityOnEntity(hod,NCreep);
			return
		end	
	end
	
	
	local stick=IsItemAvailable("item_magic_stick");
	if stick ~=nil and stick:IsFullyCastable() and not bot:IsInvisible()
	then
		if DotaTime() > 0 
		then
		    local tableNearbyEnemyHeroes = npcBot:GetNearbyHeroes( 700, true, BOT_MODE_NONE );
			local nEnemyCount = #tableNearbyEnemyHeroes;
			local nHPrate = npcBot:GetHealth()/npcBot:GetMaxHealth();
			local nMPrate = npcBot:GetMana()/npcBot:GetMaxMana();
			local nCharges = GetItemCharges(npcBot,"item_magic_stick");
			
			if ( ((nHPrate < 0.5 or nMPrate < 0.3) and  nEnemyCount >= 1 and nCharges >= 1 )
			    or( nHPrate + nMPrate < 1.1 and nCharges >= 7  )
				or(nCharges == 10 and bot:GetItemInSlot(5) ~= nil and (nHPrate <= 0.6 or nMPrate <= 0.6)) )  
			then
				npcBot:Action_UseAbility(stick);
				return;
			end
			
			
		end
	end	
	
	
	local wand=IsItemAvailable("item_magic_wand");
	if wand ~=nil and wand:IsFullyCastable() and not bot:IsInvisible()
	then
		if DotaTime() > 0 and bot:GetUnitName() ~= "npc_dota_hero_chaos_knight"
		then
			local tableNearbyEnemyHeroes = npcBot:GetNearbyHeroes( 700, true, BOT_MODE_NONE );
			local nEnemyCount = #tableNearbyEnemyHeroes;
			local nHPrate = npcBot:GetHealth()/npcBot:GetMaxHealth();
			local nMPrate = npcBot:GetMana()/npcBot:GetMaxMana();
			local nLostHP = npcBot:GetMaxHealth() - npcBot:GetHealth();
			local nLostMP = npcBot:GetMaxMana() - npcBot:GetMana();
			local nCharges = GetItemCharges(npcBot,"item_magic_wand");
			
			if ( ((nHPrate < 0.4 or nMPrate < 0.3) and  nEnemyCount >= 1 and nCharges >= 1 )
			    or( nHPrate < 0.7  and nMPrate < 0.7 and nCharges >= 12  ) 
				or(nCharges == 20 and bot:GetItemInSlot(5) ~= nil and (nHPrate <= 0.6 or nMPrate <= 0.6)) ) 				
			then
				npcBot:Action_UseAbility(wand);
				return;
			end
			
		end
	end
	
	
	local cyclone=IsItemAvailable("item_cyclone");
	if cyclone~=nil and cyclone:IsFullyCastable() then
		local nCastRange = 575 +aetherRange;
		if mutil.IsValid(npcTarget)
		   and ( npcTarget:HasModifier('modifier_teleporting') 
		         or npcTarget:HasModifier('modifier_abaddon_borrowed_time') 
				 or npcTarget:IsChanneling()
--				 or (npcTarget:IsCastingAbility() and mutil.GetHPR(npcTarget) > 0.62) 
				 or (mutil.IsRunning(npcTarget) and npcTarget:GetCurrentMovementSpeed() > 440)) 
		   and CanCastOnTarget(npcTarget) 
		   and GetUnitToUnitDistance(bot, npcTarget) < nCastRange +100
		then
			bot:Action_UseAbilityOnEntity(cyclone, npcTarget);
			return;
		end
		
		local Allies=bot:GetNearbyHeroes(nCastRange,false,BOT_MODE_NONE);
		for _,Ally in pairs(Allies) do
			if  mutil.IsValid(Ally) 
			    and (Ally:GetHealth() < 150
				    or Ally:IsRooted() 
					or Ally:IsStunned() 
					or Ally:IsHexed() 
					or Ally:IsNightmared() 
					or mutil.IsTaunted(Ally) )
			    and tableNearbyEnemyHeroes[1] ~= nil 
				and CanCastOnTarget(Ally)
			then
				bot:Action_UseAbilityOnEntity(cyclone, Ally);
				return;
			end
		end
	end	
	
	
	local metham=IsItemAvailable("item_meteor_hammer");  
	if metham~=nil and metham:IsFullyCastable() then
		if mutil.IsPushing(bot) then
			local towers = bot:GetNearbyTowers(800, true);
			if #towers > 0 and towers[1] ~= nil and  towers[1]:IsInvulnerable() == false then 
				bot:Action_UseAbilityOnLocation(metham, towers[1]:GetLocation());
				return;
			end
		elseif  mutil.IsInTeamFight(bot, 1200) then
			local locationAoE = bot:FindAoELocation( true, true, bot:GetLocation(), 600, 300, 0, 0 );
			if ( locationAoE.count >= 2 ) 
			then
				bot:Action_UseAbilityOnLocation(metham, locationAoE.targetloc);
				return;
			end
		elseif mutil.IsGoingOnSomeone(bot) then
			if mutil.IsValidTarget(npcTarget) and mutil.CanCastOnNonMagicImmune(npcTarget) and mutil.IsInRange(npcTarget, bot, 800) 
			   and mutil.IsDisabled(true, npcTarget) == true	
			then
				bot:Action_UseAbilityOnLocation(metham, npcTarget:GetLocation());
				return;
			end
		end
	end
	
	
	local lotus=IsItemAvailable("item_lotus_orb");
	if lotus~=nil and lotus:IsFullyCastable() 
	then
		if  not bot:HasModifier('modifier_item_lotus_orb_active') 
			and not bot:IsMagicImmune()
			and ( bot:IsSilenced() or ( tableNearbyEnemyHeroes ~= nil and #tableNearbyEnemyHeroes > 0 and bot:GetHealth()/bot:GetMaxHealth() < 0.35 + (0.05*#tableNearbyEnemyHeroes) ) )
	    then
			bot:Action_UseAbilityOnEntity(lotus,bot);
			return;
		end
	end
	
	if lotus~=nil and lotus:IsFullyCastable() 
	then
		local Allies=bot:GetNearbyHeroes(1000,false,BOT_MODE_NONE);
		for _,Ally in pairs(Allies) do
			if  mutil.IsValid(Ally)
				and not Ally:HasModifier('modifier_item_lotus_orb_active') 
				and not Ally:IsMagicImmune()
				and Ally:WasRecentlyDamagedByAnyHero(2.0)
			    and (( Ally:GetHealth()/Ally:GetMaxHealth() < 0.35 and tableNearbyEnemyHeroes ~= nil and #tableNearbyEnemyHeroes > 0 )  or 
				IsDisabled(Ally))
			then
				bot:Action_UseAbilityOnEntity(lotus,Ally);
				return;
			end
		end
	end	
	
	
	local mjo = IsItemAvailable("item_mjollnir");
	if mjo ~= nil and mjo:IsFullyCastable()
	then
		local nCastRange = 800;
		--Use at ally who BeTargeted most in TeamFight
	
	
		if mutil.IsValidTarget(npcTarget) 
		then
			local nAllies = mutil.GetAlliesNearLoc(npcTarget:GetLocation(), 1400);
			if mutil.IsValid(nAllies[1])
			then
				local targetAlly = nil
				local targetDis  = 9999
				for _,ally in pairs(nAllies)
				do 
					if  mutil.IsValid(ally)
						and GetUnitToUnitDistance(bot,ally) <= nCastRange + 200
						and GetUnitToUnitDistance(npcTarget,ally) < targetDis
						and not mutil.IsSuspiciousIllusion(ally)
						and not ally:HasModifier("modifier_item_mjollnir_static")
					then
						targetAlly = ally;
						targetDis  = GetUnitToUnitDistance(npcTarget,ally);
					end
				end
				if targetAlly ~= nil
				then
					bot:Action_UseAbilityOnEntity(mjo, targetAlly);
					return;
				end
			end
		end
			
		if tableNearbyEnemyHeroes[1] == nil
		then
			local nAllyCreeps = bot:GetNearbyLaneCreeps(800,false);
			local nEnemyCreeps = bot:GetNearbyLaneCreeps(800,true);
			if #nAllyCreeps >= 1 and #nEnemyCreeps == 0
			then
				local targetCreep = nil
				local targetDis  = 0
				for _,creep in pairs(nAllyCreeps)
				do 
					if mutil.IsValid(creep)
						and mutil.GetHPR(creep) > 0.6
						and creep:DistanceFromFountain() > targetDis
					then
						targetCreep = creep;
						targetDis   = creep:DistanceFromFountain();
					end
				end
				if targetCreep ~= nil
				then
					bot:Action_UseAbilityOnEntity(mjo,targetCreep);
					return;
				end
			end
		end
		
		if tableNearbyEnemyHeroes[1] ~= nil
		then
			if not bot:HasModifier("modifier_item_mjollnir_static")
			then
				bot:Action_UseAbilityOnEntity(mjo,bot);
				return;
			end
		end
	end
	
	
	local sphere = IsItemAvailable("item_sphere");
	if sphere ~= nil and sphere:IsFullyCastable()
	then
		local nCastRange = 700;
		local nAllies = bot:GetNearbyHeroes(700,false,BOT_MODE_NONE)
		
		--Use at ally who BeTargeted
		for _,ally in pairs(nAllies)
		do 
			if  mutil.IsValidTarget(ally)
				and ally ~= bot
				and not mutil.IsSuspiciousIllusion(ally)
				and not ally:HasModifier("modifier_item_sphere_target")
				and mutil.IsNotAttackProjectileIncoming(ally, 1600)
			then
				bot:Action_UseAbilityOnEntity(sphere,ally);
				return;
			end
		end
	
	
		if mutil.IsValidTarget(npcTarget) 
		then			
			if mutil.IsValid(nAllies[1])
			then
				local targetAlly = nil
				local targetDis  = 9999
				for _,ally in pairs(nAllies)
				do 
					if  mutil.IsValid(ally)
						and ally ~= bot
						and GetUnitToUnitDistance(npcTarget,ally) < targetDis
						and not mutil.IsSuspiciousIllusion(ally)
						and not ally:HasModifier("modifier_item_sphere_target")
					then
						targetAlly = ally;
						targetDis  = GetUnitToUnitDistance(npcTarget,ally);
					end
				end
				if targetAlly ~= nil
				then
					bot:Action_UseAbilityOnEntity(sphere,ally);
					return;
				end
			end
		end
	end
	
	
	local glimer=IsItemAvailable("item_glimmer_cape");
	if glimer~=nil and glimer:IsFullyCastable() then
		if  not bot:HasModifier('modifier_item_glimmer_cape') 
			and not bot:IsMagicImmune()
			and ( bot:IsSilenced() or ( tableNearbyEnemyHeroes ~= nil and #tableNearbyEnemyHeroes > 0 and bot:GetHealth()/bot:GetMaxHealth() < 0.35 + (0.05*#tableNearbyEnemyHeroes) ) )
	    then	
			bot:Action_UseAbilityOnEntity(glimer,bot);
			return;
		end
	end
	
	if glimer~=nil and glimer:IsFullyCastable() then
		local Allies=bot:GetNearbyHeroes(1000,false,BOT_MODE_NONE);
		for _,Ally in pairs(Allies) do
			if mutil.IsValid(Ally)
			   and not Ally:HasModifier('modifier_item_glimmer_cape') 
			   and not Ally:IsMagicImmune()
			   and Ally:WasRecentlyDamagedByAnyHero(2.0)
			   and (( Ally:GetHealth()/Ally:GetMaxHealth() < 0.35 and #tableNearbyEnemyHeroes > 0 ) or IsDisabled(Ally))
			then
				bot:Action_UseAbilityOnEntity(glimer,Ally);
				return;
			end
		end
	end
	
	
	local atos=IsItemAvailable("item_rod_of_atos");
	if atos ~= nil and atos:IsFullyCastable() and not bot:IsInvisible()
	then
		local nCastRange = 1150 +aetherRange;
		local nEnemysHerosInCastRange = bot:GetNearbyHeroes(nCastRange,true,BOT_MODE_NONE)
		for _,npcEnemy in pairs( nEnemysHerosInCastRange )
		do
			if mutil.IsValid(npcEnemy)
			   and npcEnemy:IsChanneling()
			   and npcEnemy:HasModifier("modifier_teleporting")
			   and mutil.CanCastOnNonMagicImmune(npcEnemy)
			then
				bot:Action_UseAbilityOnEntity(atos,npcEnemy);
				return
			end
		end
		
		if mode == BOT_MODE_RETREAT 
		   and bot:GetActiveModeDesire() > BOT_MODE_DESIRE_MODERATE
		   and	mutil.IsValid(nEnemysHerosInCastRange[1])
		   and  mutil.CanCastOnNonMagicImmune(nEnemysHerosInCastRange[1])
		   and  not IsDisabled(nEnemysHerosInCastRange[1])
		then
			bot:Action_UseAbilityOnEntity(atos,nEnemysHerosInCastRange[1]);
			return;
	    end	
	
		if ( mode == BOT_MODE_ATTACK or
			 mode == BOT_MODE_ROAM or
			 mode == BOT_MODE_TEAM_ROAM or
			 mode == BOT_MODE_DEFEND_ALLY )
		then		
			local npcTarget = mutil.GetProperTarget(bot);
			if  mutil.IsValid(npcTarget) 
				and npcTarget:IsHero() 
				and CanCastOnTarget(npcTarget) 
				and not IsDisabled(npcTarget)
                and not npcTarget:IsIllusion()				
				and GetUnitToUnitDistance(npcTarget, bot) <= nCastRange
				and mutil.IsMoving(npcTarget)
			then
			    bot:Action_UseAbilityOnEntity(atos,npcTarget);
				return
			end
		end
	
	end
	
	
	local sheep=IsItemAvailable("item_sheepstick");
	if sheep ~= nil and sheep:IsFullyCastable() and not bot:IsInvisible()
	then
		local nCastRange = 800 +aetherRange;
		local nEnemysHerosInCastRange = bot:GetNearbyHeroes(nCastRange,true,BOT_MODE_NONE)
		for _,npcEnemy in pairs( nEnemysHerosInCastRange )
		do
			if mutil.IsValid(npcEnemy)
			   and (npcEnemy:IsChanneling() or npcEnemy:IsCastingAbility())
			   and mutil.CanCastOnNonMagicImmune(npcEnemy)
			then
				bot:Action_UseAbilityOnEntity(sheep,npcEnemy);
				return
			end
		end
		
		if mode == BOT_MODE_RETREAT 
		   and  bot:GetActiveModeDesire() > BOT_MODE_DESIRE_MODERATE
		   and	mutil.IsValid(nEnemysHerosInCastRange[1])
		   and  mutil.CanCastOnNonMagicImmune(nEnemysHerosInCastRange[1])
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
			local npcTarget = mutil.GetProperTarget(bot);
			if  mutil.IsValid(npcTarget)
				and npcTarget:IsHero() 
				and CanCastOnTarget(npcTarget) 
				and not IsDisabled(npcTarget)
                and not npcTarget:IsIllusion()				
				and GetUnitToUnitDistance(npcTarget, bot) < nCastRange
			then
			    bot:Action_UseAbilityOnEntity(sheep,npcTarget);
				return;
			end
		end
	
	end
	
	local abyssal=IsItemAvailable("item_abyssal_blade");
	if abyssal ~= nil and abyssal:IsFullyCastable() and not bot:IsInvisible()
	then
		local nCastRange = 150 +aetherRange;
		local nEnemysHerosInCastRange = bot:GetNearbyHeroes(nCastRange,true,BOT_MODE_NONE)
		for _,npcEnemy in pairs( nEnemysHerosInCastRange )
		do
			if mutil.IsValid(npcEnemy)
			   and (npcEnemy:IsChanneling() or npcEnemy:IsCastingAbility())
			   and mutil.CanCastOnMagicImmune(npcEnemy)
			then
				bot:Action_UseAbilityOnEntity(abyssal,npcEnemy);
				return
			end
		end
		
		if mode == BOT_MODE_RETREAT 
		   and  bot:GetActiveModeDesire() > BOT_MODE_DESIRE_MODERATE
		   and	mutil.IsValid(nEnemysHerosInCastRange[1])
		   and  mutil.CanCastOnMagicImmune(nEnemysHerosInCastRange[1])
		   and  not IsDisabled(nEnemysHerosInCastRange[1])
		then
			bot:Action_UseAbilityOnEntity(abyssal,nEnemysHerosInCastRange[1]);
			return;
	    end	
	
		if ( mode == BOT_MODE_ATTACK or
			 mode == BOT_MODE_ROAM or
			 mode == BOT_MODE_TEAM_ROAM or
			 mode == BOT_MODE_DEFEND_ALLY )
		then		
			local npcTarget = mutil.GetProperTarget(bot);
			if  mutil.IsValid(npcTarget)
				and npcTarget:IsHero() 
				and mutil.CanCastOnMagicImmune(npcTarget) 
				and not IsDisabled(npcTarget)			
				and GetUnitToUnitDistance(npcTarget, bot) < nCastRange
			then
			    bot:Action_UseAbilityOnEntity(abyssal,npcTarget);
				return;
			end
		end
	
	end
	
	local bt=IsItemAvailable("item_bloodthorn");
	if bt == nil then bt = IsItemAvailable("item_orchid") end 
	if bt~=nil and bt:IsFullyCastable() and not bot:IsInvisible()
	then
		if ( mode == BOT_MODE_ATTACK or
			 mode == BOT_MODE_ROAM or
			 mode == BOT_MODE_TEAM_ROAM or
			 mode == BOT_MODE_DEFEND_ALLY )
		then
			local npcTarget = mutil.GetProperTarget(bot);
			if  mutil.IsValid(npcTarget) 
				and npcTarget:IsHero() 
				and CanCastOnTarget(npcTarget) 
				and not npcTarget:IsSilenced()
                and not npcTarget:IsIllusion()				
				and GetUnitToUnitDistance(npcTarget, bot) < 900 
			then
			    bot:Action_UseAbilityOnEntity(bt,npcTarget);
				return
			end
		end
	end
	
	
	local heavens=IsItemAvailable("item_heavens_halberd");
	if heavens~=nil and heavens:IsFullyCastable() 
	then	
		local tableNearbyEnemyHeroes = bot:GetNearbyHeroes( 628, true ,BOT_MODE_NONE);
		local targetHero = nil;
		local targetHeroDamage = 0		
		for _,nEnemy in pairs(tableNearbyEnemyHeroes)
		do
		   if mutil.IsValid(nEnemy)
			  and not nEnemy:IsMagicImmune()
			  and not nEnemy:IsDisarmed()
			  and not mutil.IsDisabled(true, nEnemy)
			  and (nEnemy:GetPrimaryAttribute() ~= ATTRIBUTE_INTELLECT or nEnemy:GetAttackDamage() > 200)
		   then
			   local nEnemyDamage = nEnemy:GetEstimatedDamageToTarget( false, bot, 3.0, DAMAGE_TYPE_PHYSICAL);
			   if ( nEnemyDamage > targetHeroDamage )
			   then
					targetHeroDamage = nEnemyDamage;
					targetHero = nEnemy;
			   end
		   end
		end		
		if targetHero ~= nil
		then
			bot:Action_UseAbilityOnEntity(heavens, targetHero);
			return;
		end		
		
		if ( bot:GetActiveMode() == BOT_MODE_ROSHAN  ) 
		then
			local npcTarget = bot:GetAttackTarget();
			if  mutil.IsRoshan(npcTarget) 
				and not mutil.IsDisabled(true, npcTarget)
				and not npcTarget:IsDisarmed()
			then
				bot:Action_UseAbilityOnEntity(heavens, npcTarget);
				return;
			end
		end
	end
	
	
	local hom=IsItemAvailable("item_hand_of_midas");
	if hom~=nil and hom:IsFullyCastable() then
		local range = 628      
		if #tableNearbyEnemyHeroes >= 0 then   range = 600	end
		local tableNearbyCreeps = bot:GetNearbyCreeps( range, true );
		local targetCreeps = nil;
		local targetCreepsLV = 0
		
		for _,creeps in pairs(tableNearbyCreeps)
		do
		   if mutil.IsValid(creeps)
			  and not creeps:IsMagicImmune()
			  and not creeps:IsAncientCreep()
		   then
			   if creeps:GetLevel() > targetCreepsLV
			   then
				   targetCreepsLV = creeps:GetLevel();
				   targetCreeps = creeps;
			   end
		   end

		end
		
		if targetCreeps ~= nil
		then
			bot:Action_UseAbilityOnEntity(hom, targetCreeps);
			return;
		end
		
	end
	
	
	local dagon=IsDagonAvailable();
	if dagon~=nil and dagon:IsFullyCastable() and not bot:IsInvisible() 
	then
		local nCastRange = dagon:GetCastRange() +aetherRange;
		local npcTarget = mutil.GetProperTarget(bot);
		if  mutil.IsValid(npcTarget)
			and npcTarget:IsHero() 
			and CanCastOnTarget(npcTarget) 
			and not npcTarget:IsIllusion()				
			and GetUnitToUnitDistance(npcTarget, bot) < nCastRange 
		then
			bot:Action_UseAbilityOnEntity(dagon,npcTarget);
			return
		end
		
		local nEnemyHero = mutil.GetVulnerableWeakestUnit(true, true, nCastRange, bot);
		if mutil.IsValid(nEnemyHero)
		then
			bot:Action_UseAbilityOnEntity(dagon,nEnemyHero);
			return
		end		
	end
	
	
	
	local fst=IsItemAvailable("item_force_staff");
	if fst~=nil and fst:IsFullyCastable() and not bot:IsInvisible() 
	then
		if mutil.IsStuck(bot)
		then
			bot:ActionImmediate_Chat("I'm using force staff while stuck.", true);
			bot:Action_UseAbilityOnEntity(fst, bot);
			return;
		end
		
		local Allies = bot:GetNearbyHeroes(800,false,BOT_MODE_NONE);
		for _,Ally in pairs(Allies) 
		do
			if Ally ~= nil and Ally:IsAlive()
			   and CanCastOnTarget(Ally)
			   and Ally:GetUnitName() == "npc_dota_hero_crystal_maiden"
			   and (Ally:IsInvisible() or Ally:GetHealth()/Ally:GetMaxHealth() > 0.8)
			   and (Ally:IsChanneling() and not Ally:HasModifier("modifier_teleporting") )
			then
				local enemyHeroesNearbyCM = Ally:GetNearbyHeroes(1000,true,BOT_MODE_NONE)
				for _,npcEnemy in pairs( enemyHeroesNearbyCM )
				do
				   if npcEnemy ~= nil and npcEnemy:IsAlive()
						and not npcEnemy:IsMagicImmune()
						and not npcEnemy:IsInvulnerable()
						and Ally:IsFacingLocation(npcEnemy:GetLocation(),30)
				   then
						bot:Action_UseAbilityOnEntity(fst,Ally);
						return
				   end
				end
				   
			end		
		end
		
		for _,Ally in pairs(Allies) 
		do
			if Ally ~= nil and Ally:IsAlive()
				and CanCastOnTarget(Ally)
				and not Ally:IsInvisible()
				and Ally:GetActiveMode() == BOT_MODE_RETREAT
				and Ally:IsFacingLocation(GetAncient(GetTeam()):GetLocation(),20)
				and Ally:DistanceFromFountain() > 0 
			then
					bot:Action_UseAbilityOnEntity(fst,Ally);
					return
			   end		
		end
		
		for _,npcEnemy in pairs(tableNearbyEnemyHeroes) 
		do
			if npcEnemy ~= nil and npcEnemy:IsAlive()
				and CanCastOnTarget(npcEnemy)
				and npcEnemy:IsFacingLocation(GetAncient(GetTeam()):GetLocation(),40)
				and GetUnitToLocationDistance(npcEnemy,GetAncient(GetTeam()):GetLocation()) < 1000 
			then
				bot:Action_UseAbilityOnEntity(fst,npcEnemy);
				return
			end		
		end
		
	end
	
			
	local hurricanpike = IsItemAvailable("item_hurricane_pike");
	if hurricanpike~=nil and hurricanpike:IsFullyCastable() and not bot:IsInvisible() 
	then
		if ( mode == BOT_MODE_RETREAT and bot:GetActiveModeDesire() > BOT_MODE_DESIRE_HIGH )
		then
			for _,npcEnemy in pairs( tableNearbyEnemyHeroes )
			do
				if ( GetUnitToUnitDistance( npcEnemy, bot ) < 400 and CanCastOnTarget(npcEnemy) )
				then
					bot:Action_UseAbilityOnEntity(hurricanpike,npcEnemy);
					return
				end
			end
			if bot:IsFacingLocation(GetAncient(GetTeam()):GetLocation(),20) and bot:DistanceFromFountain() > 0 
			then
				bot:Action_UseAbilityOnEntity(hurricanpike,bot);
				return;
			end
		end 
		
		if mutil.IsGoingOnSomeone(bot)
		then
			if mutil.IsValidTarget(npcTarget)
				and GetUnitToUnitDistance(npcTarget,bot) > bot:GetAttackRange() + 100
				and bot:IsFacingLocation(npcTarget:GetLocation(),20)
				and npcTarget:IsFacingLocation(mutil.GetEnemyFountain(),20)
			then
				bot:Action_UseAbilityOnEntity(hurricanpike,bot);
				return;
			end
		end
		
		if bot:GetUnitName() == "npc_dota_hero_drow_ranger"
			or bot:GetUnitName() == "npc_dota_hero_sniper"
		then
			for _,npcEnemy in pairs( tableNearbyEnemyHeroes )
			do
				if npcEnemy ~= nil
				   and GetUnitToUnitDistance( npcEnemy, bot ) <= 400
				   and CanCastOnTarget(npcEnemy)
				then
					bot:SetTarget(npcEnemy);
					--mutil.Report("发现近身目标",npcEnemy:GetUnitName());
					bot:ActionQueue_UseAbilityOnEntity(hurricanpike,npcEnemy);
					bot:SetTarget(npcEnemy);
					return;
				end
		    end
		end
		
		local Allies=bot:GetNearbyHeroes(800,false,BOT_MODE_NONE);
		for _,Ally in pairs(Allies) 
		do
			if Ally ~= nil and Ally:IsAlive()
			   and CanCastOnTarget(Ally)
			   and Ally:GetUnitName() == "npc_dota_hero_crystal_maiden"
			   and (Ally:IsInvisible() or Ally:GetHealth()/Ally:GetMaxHealth() > 0.8)
			   and (Ally:IsChanneling() and not Ally:HasModifier("modifier_teleporting") )
			then
				local enemyHeroesNearbyCM = Ally:GetNearbyHeroes(1000,true,BOT_MODE_NONE)
				for _,npcEnemy in pairs( enemyHeroesNearbyCM )
				do
				   if npcEnemy ~= nil and npcEnemy:IsAlive()
						and not npcEnemy:IsMagicImmune()
						and not npcEnemy:IsInvulnerable()
						and Ally:IsFacingLocation(npcEnemy:GetLocation(),30)
				   then
						bot:Action_UseAbilityOnEntity(hurricanpike,Ally);
						return
				   end
				end
				   
			end		
		end
	end	
		
	
	local arcane=IsItemAvailable("item_arcane_boots");
    if arcane~=nil and arcane:IsFullyCastable() and not bot:IsInvisible() 
	then
		local tableNearbyAllys = bot:GetNearbyHeroes(1200,false,BOT_MODE_NONE);
		if #tableNearbyAllys >= 2
			and bot:GetHealth() <= 100
		then
			bot:Action_UseAbility(arcane);
			return;
		end
		local needMPCount = 0;
		for _,Ally in pairs(tableNearbyAllys)
		do
			if Ally ~= nil and Ally:IsAlive()
			   and Ally:GetMaxMana()- Ally:GetMana() > 180
			then
			    needMPCount = needMPCount + 1;
			end
			
			if needMPCount >= 2 
			then
				bot:Action_UseAbility(arcane);
				return;
			end
		end
	
		if bot:GetMana()/bot:GetMaxMana() < 0.55 
		then  
			bot:Action_UseAbility(arcane);
			return ;
		end
	end
	
	
	local mekansm=IsItemAvailable("item_mekansm");
    if mekansm~=nil and mekansm:IsFullyCastable() and not bot:IsInvisible() 
	then
		local tableNearbyAllys = bot:GetNearbyHeroes(1200,false,BOT_MODE_NONE);
		
		for _,Ally in pairs(tableNearbyAllys) do
			if  Ally ~= nil and Ally:IsAlive()
				and Ally:GetHealth()/Ally:GetMaxHealth() < 0.35 
			    and tableNearbyEnemyHeroes ~= nil 
				and #tableNearbyEnemyHeroes > 0 
			then
				bot:Action_UseAbility(mekansm);
				return;
			end
		end
		
		local needHPCount = 0;
		for _,Ally in pairs(tableNearbyAllys)
		do
			if Ally ~= nil
			   and Ally:GetMaxHealth()- Ally:GetHealth() > 300
			then
			    needHPCount = needHPCount + 1;
	
				if needHPCount >= 2 and  Ally:GetHealth()/Ally:GetMaxHealth() < 0.38 
				then
					bot:Action_UseAbility(mekansm);
					return;
				end
				
				if needHPCount >= 3 
				then
					bot:Action_UseAbility(mekansm);
					return;
				end
				
			end
		end
	
		if bot:GetHealth()/bot:GetMaxHealth() < 0.2 
		then  
			bot:Action_UseAbility(mekansm);
			return ;
		end
	end
	
	
	local guardian=IsItemAvailable("item_guardian_greaves");
	if guardian~=nil and guardian:IsFullyCastable() and not bot:IsInvisible() 
	then
		local Allies=bot:GetNearbyHeroes(1200,false,BOT_MODE_NONE);
		for _,Ally in pairs(Allies) do
			if  Ally ~= nil and Ally:IsAlive()
				and Ally:GetHealth()/Ally:GetMaxHealth() < 0.35 
			    and tableNearbyEnemyHeroes ~=nil 
				and #tableNearbyEnemyHeroes > 0 
			then
				bot:Action_UseAbility(guardian);
				return;
			end
		end
		
		local needHPCount = 0;
		for _,Ally in pairs(Allies)
		do
			if Ally ~= nil
			   and Ally:GetMaxHealth()- Ally:GetHealth() > 400
			then
			    needHPCount = needHPCount + 1;
	
				if needHPCount >= 2 and  Ally:GetHealth()/Ally:GetMaxHealth() < 0.4 
				then
					bot:Action_UseAbility(guardian);
					return;
				end
				
				if needHPCount >= 3 
				then
					bot:Action_UseAbility(guardian);
					return;
				end
				
			end
		end
	
		if bot:GetHealth()/bot:GetMaxHealth() < 0.2 
		then  
			bot:Action_UseAbility(guardian);
			return ;
		end
		
		local needMPCount = 0;
		for _,Ally in pairs(Allies)
		do
			if Ally ~= nil
			   and Ally:GetMaxMana()- Ally:GetMana() > 300
			then
			    needMPCount = needMPCount + 1;
			end
			if needMPCount >= 3 
			then
				bot:Action_UseAbility(guardian);
				return;
			end
		end
	end
	
	
	local crimson=IsItemAvailable("item_crimson_guard");
    if crimson~=nil and crimson:IsFullyCastable() 
		and not bot:HasModifier("modifier_item_crimson_guard_nostack") then
		local tableNearbyAllys = bot:GetNearbyHeroes(1200,false,BOT_MODE_NONE);
		
		for _,Ally in pairs(tableNearbyAllys) do
			if  mutil.IsValid(Ally) 
				and Ally:GetHealth()/Ally:GetMaxHealth() < 0.4
			    and tableNearbyEnemyHeroes ~= nil 
				and #tableNearbyEnemyHeroes > 0 
			then
				bot:Action_UseAbility(crimson);
				return;
			end
		end
		
		local nNearbyEnemyHeroes  = npcBot:GetNearbyHeroes( 1600, true, BOT_MODE_NONE );
		local nNearbyEnemyTowers = npcBot:GetNearbyTowers(800,true); 
		if (#tableNearbyAllys >= 2 and #nNearbyEnemyHeroes >= 2)
			or (#tableNearbyAllys >= 2 and #nNearbyEnemyHeroes + #nNearbyEnemyTowers >= 2 and #nNearbyEnemyHeroes >=1)
		then
			bot:Action_UseAbility(crimson);
			return;
		end	
	end
	
	
	local pipe=IsItemAvailable("item_pipe");
    if pipe~=nil and pipe:IsFullyCastable() and not bot:IsInvisible() 
	then
		local tableNearbyAllys = bot:GetNearbyHeroes(1200,false,BOT_MODE_NONE);
		
		for _,Ally in pairs(tableNearbyAllys) do
			if  mutil.IsValid(Ally) 
				and Ally:GetHealth()/Ally:GetMaxHealth() < 0.4
			    and tableNearbyEnemyHeroes ~= nil 
				and #tableNearbyEnemyHeroes > 0 
			then
				bot:Action_UseAbility(pipe);
				return;
			end
		end
		
		local nNearbyAlliedHeroes = npcBot:GetNearbyHeroes( 1200, false, BOT_MODE_NONE );
		local nNearbyEnemyHeroes  = npcBot:GetNearbyHeroes( 1600, true, BOT_MODE_NONE );
		local nNearbyAlliedTowers = npcBot:GetNearbyTowers(1200,true); 
		if (#nNearbyAlliedHeroes >= 2 and #nNearbyEnemyHeroes >= 2)
			or (#nNearbyEnemyHeroes >= 2 and #nNearbyAlliedHeroes + #nNearbyAlliedTowers >= 2 and #nNearbyAlliedHeroes >=1)
		then
			bot:Action_UseAbility(pipe);
			return;
		end	
	end
	
	
	local msh=IsItemAvailable("item_moon_shard");
	if msh~=nil and msh:IsFullyCastable() then
		if firstUseTime == 0 
		then
			firstUseTime = DotaTime();
		end
		
		if firstUseTime < DotaTime() - 6.1
		then
	
			local numPlayer = GetTeamPlayers(GetTeam());
			local targetMember = nil;
			local targetDamage = 0;
			for i = 1, #numPlayer
			do
			   local member = GetTeamMember(i);
			   if member ~= nil and member:IsAlive()		   
				  and member:GetAttackDamage() > targetDamage
				  and not member:HasModifier("modifier_item_moon_shard_consumed")
			   then
				   targetMember = member;
				   targetDamage = member:GetAttackDamage();
			   end
			end
			if targetMember ~= nil
			then
				firstUseTime = 0;	
				bot:Action_UseAbilityOnEntity(msh, targetMember);
				return;
			end
		end
	end
	
	
	local veil=IsItemAvailable("item_veil_of_discord");
    if veil~=nil and veil:IsFullyCastable() and not npcBot:IsInvisible()
	then
		local nCastRange = 1000 +aetherRange;
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
	
	
	local manta=IsItemAvailable("item_manta");
	if manta ~= nil and manta:IsFullyCastable() 
	then
	    local nNearbyAttackingAlliedHeroes = npcBot:GetNearbyHeroes( 1000, false, BOT_MODE_ATTACK );
		local nNearbyEnemyHeroes  = npcBot:GetNearbyHeroes( 1000, true, BOT_MODE_NONE );
		local nNearbyEnemyTowers = npcBot:GetNearbyTowers(800,true);
		local nNearbyEnemyBarracks = npcBot:GetNearbyBarracks(600,true);
		local nNearbyAlliedCreeps = npcBot:GetNearbyLaneCreeps(1000,false);
		local nNearbyEnemyCreeps = npcBot:GetNearbyLaneCreeps(800,true);
		
		if mutil.IsPushing(bot) 
		then
			if (#nNearbyEnemyTowers >= 1 or #nNearbyEnemyBarracks >= 1)
				and #nNearbyAlliedCreeps >= 1
			then
				bot:Action_UseAbility(manta);
				return;
			end
		end
		
		if #nNearbyAttackingAlliedHeroes + #nNearbyEnemyHeroes >= 2
			and  #nNearbyEnemyHeroes - #nNearbyAttackingAlliedHeroes < 2
			and  #nNearbyEnemyHeroes >= 1
		then
			bot:Action_UseAbility(manta);
			return;
		end
		
		if bot:GetActiveMode() == BOT_MODE_RETREAT
		   and nNearbyEnemyHeroes[1] ~= nil
		then
			bot:Action_UseAbility(manta);
			return;
		end
		
		if #nNearbyEnemyCreeps >= 8
		then
			bot:Action_UseAbility(manta);
			return;
		end
	
		if bot:WasRecentlyDamagedByAnyHero(5.0)
		   and bot:GetHealth()/bot:GetMaxHealth() < 0.18
		then
			bot:Action_UseAbility(manta);
			return;
		end
		
		if bot:HasModifier("modifier_arc_warden_tempest_double")
		    and bot:GetRemainingLifespan() < 1.5
		then
			bot:Action_UseAbility(manta);
			return;
		end
	
	end
	
	
	local satanic=IsItemAvailable("item_satanic");
	if satanic~=nil and satanic:IsFullyCastable() then
		if  bot:GetHealth()/bot:GetMaxHealth() < 0.62 
		    and tableNearbyEnemyHeroes ~= nil 
			and #tableNearbyEnemyHeroes > 0 
			and bot:GetAttackTarget() ~= nil
		then
			bot:SetTarget(bot:GetAttackTarget());
			bot:Action_UseAbility(satanic);
			return;
		end
	end	
	
	local mask =IsItemAvailable("item_mask_of_madness");
	if mask ~= nil and mask:IsFullyCastable() then
		local nAttackTarget = bot:GetAttackTarget();
		if  mutil.IsValid(nAttackTarget)
			and mutil.CanBeAttacked(nAttackTarget)
		    and GetUnitToUnitDistance(bot,nAttackTarget) < bot:GetAttackRange() + 200
		then
			bot:SetTarget(nAttackTarget);
			bot:Action_UseAbility(mask);
			return;
		end
		
	    -- if mutil.IsRunning(bot)
			-- and #tableNearbyEnemyHeroes == 0
			-- and bot:GetMana() > 300 
		-- then
			-- bot:Action_UseAbility(mask);
			-- return;
		-- end
	end	
	
	
	local buckler=IsItemAvailable("item_buckler"); 
	if buckler~=nil and buckler:IsFullyCastable() 
	then
	    if bot:DistanceFromFountain() > 3800 or tableNearbyEnemyHeroes[1] ~= nil
		then
			bot:Action_UseAbility(buckler);
		    return;	
		end
	end
	
	
	local db=IsItemAvailable("item_diffusal_blade");
	if db~=nil and db:IsFullyCastable() and not bot:IsInvisible()
	then
	
		if( mode == BOT_MODE_RETREAT and not bot:IsInvisible())
		then
			for _,npcEnemy in pairs( tableNearbyEnemyHeroes )
			do
				if  mutil.IsValid(npcEnemy)
					and mutil.IsInRange(npcEnemy, bot, 600) 
					and bot:WasRecentlyDamagedByHero( npcEnemy, 4.0 )
					and mutil.IsMoving(npcEnemy)
					and npcEnemy:GetCurrentMovementSpeed() > 200
					and mutil.CanCastOnNonMagicImmune(npcEnemy) 
					and not mutil.IsDisabled(true, npcEnemy) 					
				then
					bot:Action_UseAbilityOnEntity(db,npcEnemy);
				end
			end
		end	
	
		if ( mode == BOT_MODE_ATTACK or
			 mode == BOT_MODE_ROAM or
			 mode == BOT_MODE_TEAM_ROAM or
			 mode == BOT_MODE_DEFEND_ALLY )
		then
			local npcTarget = mutil.GetProperTarget(bot);
			if  mutil.IsValid(npcTarget)  
				and npcTarget:IsHero() 
				and GetUnitToUnitDistance(npcTarget, bot) <= 600 
				and CanCastOnTarget(npcTarget) 
				and not IsDisabled(npcTarget)
				and mutil.IsMoving(npcTarget)
				and npcTarget:GetCurrentMovementSpeed() > 200
			then
			    bot:Action_UseAbilityOnEntity(db,npcTarget);
				return
			end
		end
		
		if  mutil.IsValid(tableNearbyEnemyHeroes[1])
			and GetUnitToUnitDistance(tableNearbyEnemyHeroes[1], bot) <= 600
			and CanCastOnTarget(tableNearbyEnemyHeroes[1]) 
			and not IsDisabled(tableNearbyEnemyHeroes[1]) 
			and mutil.IsMoving(tableNearbyEnemyHeroes[1])
			and tableNearbyEnemyHeroes[1]:GetCurrentMovementSpeed() > 200
		then
			bot:Action_UseAbilityOnEntity(db,tableNearbyEnemyHeroes[1]);
			return;
		end
		
	end	
	
	
	local uos=IsItemAvailable("item_urn_of_shadows"); 
	if uos~=nil and uos:IsFullyCastable() and uos:GetCurrentCharges() > 0
	then
		if ( npcBot:GetActiveMode() == BOT_MODE_ROAM or
			 npcBot:GetActiveMode() == BOT_MODE_TEAM_ROAM or
			 npcBot:GetActiveMode() == BOT_MODE_DEFEND_ALLY or
			 npcBot:GetActiveMode() == BOT_MODE_ATTACK ) 
		then	
			if mutil.IsValidTarget(npcTarget) 
			   and CanCastOnTarget(npcTarget) 
			   and GetUnitToUnitDistance(npcBot, npcTarget) <= 980
			   and not npcTarget:HasModifier("modifier_item_urn_damage") 
			   and not npcTarget:IsIllusion() 
			   and (npcTarget:GetHealth()/npcTarget:GetMaxHealth() < 0.95 or GetUnitToUnitDistance(npcBot, npcTarget) <= 650)
			   and not npcTarget:HasModifier("modifier_item_spirit_vessel_damage")
			then
			    npcBot:Action_UseAbilityOnEntity(uos, npcTarget);
				return;
			end
		end
		
		if uos:GetCurrentCharges() >= 2 
			and	npcBot:GetActiveMode() ~= BOT_MODE_ROSHAN
		then
			local Allies=npcBot:GetNearbyHeroes(1000,false,BOT_MODE_NONE);
			local NeedHealAlly = nil
			local NeedHealAllyHealth = 99999
			for _,Ally in pairs(Allies) do
				if mutil.IsValid(Ally) 
				   and not Ally:HasModifier("modifier_item_spirit_vessel_heal")  
				   and not Ally:HasModifier("modifier_item_urn_heal")
				   and not Ally:HasModifier("modifier_fountain_aura")
				   and not Ally:WasRecentlyDamagedByAnyHero(3.1)
				   and CanCastOnTarget(Ally) 
				   and not Ally:IsIllusion()
				   and not Ally:HasModifier("modifier_illusion") 
				   and Ally:GetMaxHealth() - Ally:GetHealth() > 400 
				   and #tableNearbyEnemyHeroes == 0 				   				   			
				then
					if(Ally:GetHealth() < NeedHealAllyHealth )
					then
						NeedHealAlly = Ally
						NeedHealAllyHealth = Ally:GetHealth()
					end
				end
			end
		
			if(NeedHealAlly ~= nil)
			then
				npcBot:Action_UseAbilityOnEntity(uos,NeedHealAlly );
				return;
			end
		end
	end
	
	
	local sv=IsItemAvailable("item_spirit_vessel"); 
	if sv~=nil and sv:IsFullyCastable() and sv:GetCurrentCharges() > 0
	then
		if ( npcBot:GetActiveMode() == BOT_MODE_ROAM or
			 npcBot:GetActiveMode() == BOT_MODE_TEAM_ROAM or
			 npcBot:GetActiveMode() == BOT_MODE_DEFEND_ALLY or
			 npcBot:GetActiveMode() == BOT_MODE_ATTACK ) 
		then	
			if mutil.IsValidTarget(npcTarget)
			   and CanCastOnTarget(npcTarget) 
			   and GetUnitToUnitDistance(npcBot, npcTarget) <= 980
			   and not npcTarget:HasModifier("modifier_item_spirit_vessel_damage")
			   and not npcTarget:IsIllusion()
			   and not npcTarget:HasModifier("modifier_item_urn_damage")
			then
			    npcBot:Action_UseAbilityOnEntity(sv, npcTarget);
				return;
			end
		end
		
		if sv:GetCurrentCharges() >= 2
			and npcBot:GetActiveMode() ~= BOT_MODE_ROSHAN
		then
			local Allies=npcBot:GetNearbyHeroes(1000,false,BOT_MODE_NONE);
			local NeedHealAlly=nil
			local NeedHealAllyHealth = 99999
			for _,Ally in pairs(Allies) do
				if mutil.IsValid(Ally) 
				   and not Ally:HasModifier("modifier_item_spirit_vessel_heal")
				   and not Ally:HasModifier("modifier_item_urn_heal") 
				   and not Ally:HasModifier("modifier_fountain_aura")
				   and CanCastOnTarget(Ally) 
				   and Ally:GetMaxHealth() - Ally:GetHealth() > 500 
				   and #tableNearbyEnemyHeroes == 0 
				   and not Ally:WasRecentlyDamagedByAnyHero(3.1)		   
				   and not Ally:IsIllusion() 
				   and not Ally:HasModifier("modifier_illusion")				   
				then
					if(Ally:GetHealth() < NeedHealAllyHealth )
					then
						NeedHealAlly = Ally
						NeedHealAllyHealth = Ally:GetHealth()
					end
				end
			end
			
			if(NeedHealAlly ~= nil)
			then
				npcBot:Action_UseAbilityOnEntity(sv,NeedHealAlly );
				return;
			end
		end
	end
	
	
	local null=IsItemAvailable("item_nullifier");
	if null~=nil and null:IsFullyCastable() 
	then
		if mutil.IsGoingOnSomeone(bot)
		then	
			if mutil.IsValidTarget(npcTarget) 
			   and mutil.CanCastOnNonMagicImmune(npcTarget) 
			   and mutil.IsInRange(npcTarget, bot, 800) 
			   and npcTarget:HasModifier("modifier_item_nullifier_mute") == false 
			then
			    bot:Action_UseAbilityOnEntity(null, npcTarget);
				return;
			end
		end
	end
	
end

function IsItemAvailable(item_name)
    local slot = bot:FindItemSlot(item_name);
	
	if slot < 0 then return nil end
	
	if bot:GetItemSlotType(slot) == ITEM_SLOT_TYPE_MAIN then
		return bot:GetItemInSlot(slot);
	end
	
    return nil;
end

function IsTargetedByEnemy(building)
	local heroes = GetUnitList(UNIT_LIST_ENEMY_HEROES);
	for _,hero in pairs(heroes)
	do
		if ( GetUnitToUnitDistance(building, hero) <= hero:GetAttackRange() + 200 and hero:GetAttackTarget() == building ) then
			return true;
		end
	end
	return false;
end

function UseGlyph()

	if GetGlyphCooldown( ) > 0  or  DotaTime() < 60 then
		return
	end	
	
	local T1 = {
		TOWER_TOP_1,
		TOWER_MID_1,
		TOWER_BOT_1,
		TOWER_TOP_3,
		TOWER_MID_3, 
		TOWER_BOT_3, 
		TOWER_BASE_1, 
		TOWER_BASE_2
	}
	
	for _,t in pairs(T1)
	do
		local tower = GetTower(GetTeam(), t);
		if  tower ~= nil and tower:GetHealth() > 0 and tower:GetHealth()/tower:GetMaxHealth() < 0.15 and tower:GetAttackTarget() ~=  nil
		then
			bot:ActionImmediate_Glyph( )
			return
		end
	end
	

	local MeleeBarrack = {
		BARRACKS_TOP_MELEE,
		BARRACKS_MID_MELEE,
		BARRACKS_BOT_MELEE
	}
	
	for _,b in pairs(MeleeBarrack)
	do
		local barrack = GetBarracks(GetTeam(), b);
		if barrack ~= nil and barrack:GetHealth() > 0 and barrack:GetHealth()/barrack:GetMaxHealth() < 0.5 and IsTargetedByEnemy(barrack)
		then
			bot:ActionImmediate_Glyph( )
			return
		end
	end
	
	local Ancient = GetAncient(GetTeam())
	if Ancient ~= nil and Ancient:GetHealth() > 0 and Ancient:GetHealth()/Ancient:GetMaxHealth() < 0.5 and IsTargetedByEnemy(Ancient)
	then
		bot:ActionImmediate_Glyph( )
		return
	end

end

function IsDagonAvailable()
	local dagon = IsItemAvailable("item_dagon_1");
	if dagon ~= nil then return dagon end;
	
	dagon = IsItemAvailable("item_dagon_2");
	if dagon ~= nil then return dagon end;
	
	dagon = IsItemAvailable("item_dagon_3");
	if dagon ~= nil then return dagon end;
	
	dagon = IsItemAvailable("item_dagon_4");
	if dagon ~= nil then return dagon end;
	
	dagon = IsItemAvailable("item_dagon_5");
	if dagon ~= nil then return dagon end;
	
	return nil;	
end

function IsAllyChanneling(bot)

	local numPlayer =  GetTeamPlayers(GetTeam());
	for i = 1, #numPlayer
	do
		local member =  GetTeamMember(i);
		if member ~= nil 
		   and member ~= bot 
		   and member:IsAlive()
		   and member:IsChanneling()
		then
			return true;
		end
	end

	return false;
end

-- for k, v in pairs(ability_item_usage_generic) do
	-- _G._savedEnv[k] = v
-- end

return MyModule;