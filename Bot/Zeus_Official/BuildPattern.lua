local X = {}

-- Change to false to disable random talent choice (this is used for random evolutive growth)
local rand = false;

-- This function will return the Talent Tree that Zeus currently has
function X.FillTalenTable(npcBot)
	local talents = {};
	for i = 0, 23 
	do
		local ability = npcBot:GetAbilityInSlot(i);
		if ability ~= nil and ability:IsTalent() then
			table.insert(talents, ability:GetName());
		end
	end
	return talents;
end

-- This function will retun the current available skills Zeus has
function X.FillSkillTable(npcBot, slots)
	local skills = {};
	for _,slot in pairs(slots)
	do
		table.insert(skills, npcBot:GetAbilityInSlot(slot):GetName());
	end
	return skills;
end

-- This function will return the slot pattern for the bot
function X.GetSlotPattern()
		return {0,1,2,5};
end

-- This function will decide the skills
function X.GetBuildPattern(s, skills, t, talents)	
  if rand then
    return {
      skills[s[1]],    skills[s[2]],    skills[s[3]],    skills[s[4]],    skills[s[5]],
      skills[s[6]],    skills[s[7]],    skills[s[8]],    skills[s[9]],    talents[RandomInt(1,2)],
      skills[s[10]],   skills[s[11]],   skills[s[12]],   skills[s[13]],   talents[RandomInt(3,4)],
      skills[s[14]],    	"-1",      	  skills[s[15]],    	"-1",   	talents[RandomInt(5,6)],
        "-1",   		"-1",   		"-1",       		"-1",       talents[RandomInt(7,8)]
    }
  else
    return {
      skills[s[1]],    skills[s[2]],    skills[s[3]],    skills[s[4]],    skills[s[5]],
      skills[s[6]],    skills[s[7]],    skills[s[8]],    skills[s[9]],    talents[t[1]],
      skills[s[10]],   skills[s[11]],   skills[s[12]],   skills[s[13]],   talents[t[2]],
      skills[s[14]],    	"-1",      	  skills[s[15]],    	"-1",   	talents[t[3]],
        "-1",   		"-1",   		"-1",       		"-1",       talents[t[4]]
    }
  end
end

-- This will generate a random skill leveling up depending on Zeus capabilities
function X.GetRandomBuild(tBuilds)
	return tBuilds[RandomInt(1,#tBuilds)]
end	

return X;