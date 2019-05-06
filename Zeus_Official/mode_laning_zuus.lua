local movement_assitant = require( GetScriptDirectory().."/movement_assitant")
local idea = require(GetScriptDirectory() .. "/bayesian_network");

local EyeRange=1200;
local BaseDamage=50;
local AttackRange=150;
local AttackSpeed=0.6;
local LastTiltTime=0.0;

local BackTimerGen=-1000;

local CreepDist=220;

local LaningStates={
	Start=0,
	Moving=1,
	WaitingForCS=2,
	CSing=3,
	WaitingForCreeps=4,
	MovingToPos=5,
	GetReadyForCS=6,
	GettingBack=7,
	MovingToLane=8
}

local CurLane = LANE_MID;
local LaningState = LaningStates.Start;
local LanePos = 0.0;
local ShouldPush=false;
local backTimer=-10000;
local IsCore=true;

local DamageThreshold=1.0;
local MoveThreshold=1.0;

local npcBot = GetBot();

function  OnStart()
	print("Laning");
	local npcBot=GetBot();
	npcBot.BackTimerGen = -1000;
	
	if npcBot:IsChanneling() or npcBot:IsUsingAbility() then
		return;
	end
		
	local dest=GetLocationAlongLane(CurLane,GetLaneFrontAmount(GetTeam(),CurLane,true)-0.04);
	if DotaTime()>1 and GetUnitToLocationDistance(npcBot,dest)>1500 then
		movement_assitant.InitPath();
		npcBot.LaningState=LaningStates.MovingToLane;
	end
	
end


local function MovingToPos()
	local npcBot=GetBot();
	
	local EnemyCreeps=npcBot:GetNearbyCreeps(EyeRange,true);
	
	local cpos=GetLaneFrontLocation(movement_assitant.GetOtherTeam(),CurLane,0.0);
	local bpos=GetLocationAlongLane(CurLane,LanePos-0.02);
	
	local dest=movement_assitant.VectorTowards(cpos,bpos,CreepDist);
	
	local rndtilt=RandomVector(200);
	
	dest=dest+rndtilt;
	
	npcBot:Action_MoveToLocation(dest);
	
	LaningState=LaningStates.CSing;
end

function OnEnd()
end

function GetDesire()
	return realDesire();
end 

function empty( table )
	if next(myTable) == nil then
   return true
end
return false 
end

function Think()
  local npcBot=GetBot();
	local AllyCreeps=npcBot:GetNearbyCreeps(EyeRange,false);

	local contdos=0
    local enemies = npcBot:GetNearbyLaneCreeps(1599, true);

    if (DotaTime()>1)then 	
	MovingToPos();
	end
end

-- For some reason dota modifies the ACTIVE_MODE_DESIRE so this will set the desire to a reaal desire
function realDesire()
  local retreatDesire = idea.calculateRetreatDesire();
  local laningDesire = idea.calculateLaningDesire();
  local farmDesire = idea.calculateFarmDesire();
  local attackDesire = idea.calculateAttackDesire();
  
  if laningDesire > retreatDesire and laningDesire > farmDesire and  laningDesire > attackDesire  then 
    return 1
  else 
    return laningDesire
  end
end