local movement_assitant = require( GetScriptDirectory().."/movement_assitant")
local map_awareness = require( GetScriptDirectory().."/map_awareness");
local idea = require(GetScriptDirectory() .. "/bayesian_network");

local EnemyLaneCreeps = {};
local AllyLaneCreeps = {};

local npcBot = GetBot();

local abilities = map_awareness.InitiateAbilities(npcBot, {0,1,3,5});

function  OnStart()
	print("Farming")
end

function OnEnd()
end

function GetDesire()
	return realDesire();
end

function Think()
  local npcBot = GetBot();
  
  local qManaCost  = abilities[1]:GetManaCost();
  local qCastRange = abilities[1]:GetCastRange();
  local qRadius = abilities[1]:GetSpecialValueInt( "radius" );

--we get two points based on the postion on the
  local cpos=GetLaneFrontLocation(movement_assitant.GetOtherTeam(),LANE_MID,0.0);
  local bpos=GetLocationAlongLane(LANE_MID,0.0-0.02);
--we create a vector based on the prevoius two points
  local dest=movement_assitant.VectorTowards(cpos,bpos,220);
  --we create a small random vector 
  local rndtilt=RandomVector(200);
  --we combien both vectors
  dest=dest+rndtilt;
  --we move the bot a little so creeps may lose tracking of the bot
  npcBot:Action_MoveToLocation(dest);


  local target = map_awareness.GetVulnerableWeakestUnit(false,true,qCastRange,npcBot);
  
	--if there is a creep in range and has less than 20 percent hp
	if target~=nil and (map_awareness.GetHPR(target)<.15) then
		--if the creep is in range of the skill and the bot has the mana to cast the skill and the bot has the ability
		if map_awareness.IsInRange(target,npcBot,qCastRange) 
      and not map_awareness.CantUseAbility(npcBot) 
      and map_awareness.CanSpamSpell(npcBot, qManaCost) then
			--use the skill on the creep
			npcBot:Action_UseAbilityOnEntity(abilities[1],target);
		else
			--if we cannot use the skill we use normal attack
			npcBot:Action_AttackUnit(target, false);
		end
	end

end

-- For some reason dota modifies the ACTIVE_MODE_DESIRE so this will set the desire to a reaal desire
function realDesire()
  local retreatDesire = idea.calculateRetreatDesire();
  local laningDesire = idea.calculateLaningDesire();
  local farmDesire = idea.calculateFarmDesire();
  local attackDesire = idea.calculateAttackDesire();
  
  if farmDesire > laningDesire and farmDesire > retreatDesire and farmDesire > attackDesire then return 1
    else return farmDesire end
  
end
