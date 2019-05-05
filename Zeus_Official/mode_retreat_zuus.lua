local idea = require(GetScriptDirectory() .. "/bayesian_network");
local map_awareness = require(GetScriptDirectory() .. "/map_awareness");

local CurLane = LANE_MID;
local npcBot = GetBot();

function  OnStart()
  print("Retreat");
end

function GetDesire()
	return realDesire();
end

function Think()
  npcBot:Action_MoveToLocation(map_awareness.GetTeamFountain());
end

function OnEnd()
end

-- For some reason dota modifies the ACTIVE_MODE_DESIRE so this will set the desire to a reaal desire
function realDesire()
  local retreatDesire = idea.calculateRetreatDesire();
  local laningDesire = idea.calculateLaningDesire();
  local farmDesire = idea.calculateFarmDesire();
  local attackDesire = idea.calculateAttackDesire();
  
  if retreatDesire > laningDesire and retreatDesire > farmDesire and retreatDesire > attackDesire then return 1
    else return retreatDesire end
  
end