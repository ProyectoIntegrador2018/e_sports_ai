
local CurLane = LANE_MID;

function  OnStart()
	print("Back TEC!")
end

local function StayBack()
	local npcBot=GetBot();
	
	local LaneFront=GetLaneFrontAmount(GetTeam(),CurLane,true);
	local LaneEnemyFront=GetLaneFrontAmount(GetTeam(),CurLane,false);
	
	local BackPos=GetLocationAlongLane(CurLane,Min(LaneFront-0.05,LaneEnemyFront-0.05)) + RandomVector(200);
	npcBot:Action_MoveToLocation(BackPos);
end


function OnEnd()
end
-- dara un numero entre 0 y 1 que determina que tanto quieres hacer esta acion 
function GetDesire()
	local npcBot=GetBot();
	local EyeRange=1200;
	if(npcBot:GetHealth()>npcBot:GetMaxHealth()*.3) then 
		return 0
	end 
     return .9;
end

function Think()
	StayBack();
end
