local map_awareness = require( GetScriptDirectory().."/map_awareness");
local idea = require(GetScriptDirectory() .. "/bayesian_network");

local npcBot = GetBot();

local abilities = map_awareness.InitiateAbilities(npcBot, {0,1,3,5});

function  OnStart()
	print("Attaaaaack!!!")
end

function OnEnd()
end

function GetDesire()
	return realDesire();
end

function Think()
	local npcBot = GetBot();
	
  local enemyteam = npcBot:GetTeam();
  if enemyteam == 3 then enemyteam = 2 elseif enemyteam == 2 then enemyteam = 3 end
  local target = GetTower(enemyteam,TOWER_MID_1);
  
	--if target is visible
	if target~=nil then
		--if target is in range
		if map_awareness.IsInRange(target,npcBot,700) then
			npcBot:Action_AttackUnit(target, false);
		else
      npcBot:Action_MoveToUnit(target);
    end
	end
end

-- For some reason dota modifies the ACTIVE_MODE_DESIRE so this will set the desire to a reaal desire
function realDesire()
  local retreatDesire = idea.calculateRetreatDesire();
  local laningDesire = idea.calculateLaningDesire();
  local farmDesire = idea.calculateFarmDesire();
  local attackDesire = idea.calculateAttackDesire();
  
  if attackDesire > laningDesire and attackDesire > retreatDesire and attackDesire > farmDesire then return 1
    else return attackDesire end
  
end