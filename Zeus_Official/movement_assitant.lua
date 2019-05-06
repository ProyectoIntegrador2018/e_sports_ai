Assistant={}

function Assistant.GetDistance(s,t)
	return math.sqrt((s[1]-t[1])*(s[1]-t[1]) + (s[2]-t[2])*(s[2]-t[2]));
end

function Assistant.VectorTowards(s,t,d)
	local f=t-s;
	f=f / Assistant.GetDistance(f,Vector(0,0));
	return s+(f*d);
end

function Assistant.InitPath()
	local npcBot=GetBot();
	npcBot.FinalHop=false;
	npcBot.LastHop=nil;
end

function Assistant.GetOtherTeam()
	if GetTeam()==TEAM_RADIANT then
		return TEAM_DIRE;
	else
		return TEAM_RADIANT;
	end
	
end

return Assistant