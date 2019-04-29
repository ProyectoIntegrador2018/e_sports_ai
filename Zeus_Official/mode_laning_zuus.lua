Utility = require( GetScriptDirectory().."/Utility")
----------

local CurLane = Utility.Lanes[1];
local EyeRange=1200;
local BaseDamage=50;
local AttackRange=150;
local AttackSpeed=0.6;
local LastTiltTime=0.0;

local DamageThreshold=1.0;
local MoveThreshold=1.0;

local BackTimerGen=-1000;

local ShouldPush=false;
local IsCore=false;

local LanePos = 0.0;

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

local LaningState=LaningStates.Moving;

local CurLane = LANE_MID;
local LaningState = LaningStates.Start;
local LanePos = 0.0;
local ShouldPush=false;
local backTimer=-10000;
local IsCore=true;

local DamageThreshold=1.0;
local MoveThreshold=1.0;



function  OnStart()
	print("Laning TEC!");
	local npcBot=GetBot();
	npcBot.BackTimerGen = -1000;
	
	if DotaTime()>10 and npcBot:GetGold()>50 and GetUnitToLocationDistance(npcBot,GetLocationAlongLane(CurLane,0.0))<700 and Utility.NumberOfItems()<=5 then
		--npcBot:Action_PurchaseItem("item_tpscroll");
		return;
	end
	
	if npcBot:IsChanneling() or npcBot:IsUsingAbility() then
		return;
	end
		
	local dest=GetLocationAlongLane(CurLane,GetLaneFrontAmount(GetTeam(),CurLane,true)-0.04);
	if DotaTime()>1 and GetUnitToLocationDistance(npcBot,dest)>1500 then
		Utility.InitPath();
		npcBot.LaningState=LaningStates.MovingToLane;
	end
	
end


local function MovingToPos()
	local npcBot=GetBot();
	
	local EnemyCreeps=npcBot:GetNearbyCreeps(EyeRange,true);
	
	local cpos=GetLaneFrontLocation(Utility.GetOtherTeam(),CurLane,0.0);
	local bpos=GetLocationAlongLane(CurLane,LanePos-0.02);
	
	local dest=Utility.VectorTowards(cpos,bpos,CreepDist);
	
	local rndtilt=RandomVector(200);
	
	dest=dest+rndtilt;
	
	npcBot:Action_MoveToLocation(dest);
	
	LaningState=LaningStates.CSing;
	--npcBot:Action_Chat("Hola  soy cupo " ,true);
	--print("Laning!");
end




function OnEnd()
	return 0
end

function GetDesire()
	return 0.1;
end

function  empty( table )
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