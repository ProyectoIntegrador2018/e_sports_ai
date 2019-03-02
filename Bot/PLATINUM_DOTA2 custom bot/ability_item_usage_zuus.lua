------------------------------------------------------------
--- AUTHOR: PLATINUM_DOTA2 (Pooya J.)
--- EMAIL ADDRESS: platinum.dota2@gmail.com
------------------------------------------------------------

Utility = require( GetScriptDirectory().."/Utility");

local Abilities={
"zuus_arc_lightning",
"zuus_lightning_bolt",
"zuus_static_field",
"zuus_thundergods_wrath"
};

local UltDamage={225,325,425};

local function UltKills(unit,damage)
	local npcBot=GetBot();

	--we get ultimate skill that is the fourth in the abilities array
	local ar=npcBot:GetAbilityByName(Abilities[4]);
	--if the ultimate skill is castable and the damage done by skill is higher than the current health then it can kill
	if ar:IsFullyCastable() and unit:GetActualDamage(UltDamage[ar:GetLevel()]+damage,DAMAGE_TYPE_MAGICAL) > unit:GetHealth() then
		return true;
	end
end

local function GetComboMana()
	local npcBot=GetBot();
	--we get the abilities 1 2 and 4
	local aq=npcBot:GetAbilityByName(Abilities[1]);
	local aw=npcBot:GetAbilityByName(Abilities[2]);
	local ar=npcBot:GetAbilityByName(Abilities[4]);
	
	--if any level of the abilities we got is less then 1 we return 10000 
	if aq:GetLevel()<1 or aw:GetLevel()<1 or ar:GetLevel()<1 then
		return 10000;
	end
	-- return  the sum of their cost
	return aq:GetManaCost()+aw:GetManaCost()+ar:GetManaCost();
end

local function ConsiderCombo()
	local npcBot=GetBot();
	
	local aq=npcBot:GetAbilityByName(Abilities[1]);
	local aw=npcBot:GetAbilityByName(Abilities[2]);
	local ar=npcBot:GetAbilityByName(Abilities[4]);
	
	--if any level of the abilities we got is less then we dont consider it
	if aq:GetLevel()<1 or aw:GetLevel()<1 or ar:GetLevel()<1 then
		return false;
	end

	--we consider the combo
	return true;
end


local function UseUlt()
	local npcBot=GetBot();
	
	--we get the fourth ability that correposnds with the ultimate skill
	local ability=npcBot:GetAbilityByName(Abilities[4]);

	--if the ability is not fully catable then
	if not ability:IsFullyCastable() then
		--stop
		return;
	end
	
	--we create extra variable to se who would be tha weakest enemy and the lowest hp of enemy team
	local WeakestEnemy=nil;
	local LowestHP=10000.0;
	
	for p=1,5,1 do
		--we get a member of the enemy team based on p range of 1 to 5
		local Enemy=GetTeamMember(Utility.GetOtherTeam(),p);

		--if enemy variable has a value
		if Enemy~=nil then
			--and if the enemmy is alive
			if Enemy:IsAlive() then
--				print(Enemy:GetUnitName(),Enemy:GetHealth());	
				--the chceck if the enemy has hp remaining and is less health than he current value of lowest health
				if LowestHP>Enemy:GetHealth() and Enemy:GetHealth()>0 then
					WeakestEnemy=Enemy;
					LowestHP=Enemy:GetHealth();
				end
			end
		end
	end
	
--	print(npcBot:GetUnitName(),LowestHP);
	
	--if there isn't any enemy or the lowest health is less than 1
	if WeakestEnemy==nil or LowestHP<1 then
		--stop
		return;
	end
--	print(WeakestEnemy:GetUnitName());

	--we get the damage the ultimate skill will do to the weakest enemy
	local ultDamage=WeakestEnemy:GetActualDamage(UltDamage[ability:GetLevel()],DAMAGE_TYPE_MAGICAL);
--	print(ultDamage);
	
	--if the damge that will be dealt is more or equal to his reamaing hp
	if LowestHP<=ultDamage then
--		print("Zeus is ulting for ",WeakestEnemy:GetUnitName());
		--use the bility
		npcBot:Action_UseAbility(ability);
	end
end

local function UseQ()
	local npcBot = GetBot();
	
	--we get th biliti in the first position
	local ability=npcBot:GetAbilityByName(Abilities[1]);
	--if the ability is not castable
	if not ability:IsFullyCastable() then
		--stop
		return;
	end
	--we get the ability damage
	local damage=ability:GetAbilityDamage();
	
	local enemy=nil;
	local health=10000;
	
	--get the enemy with lowest hp in the skill range
	enemy,health=Utility.GetWeakestHero(ability:GetCastRange());
	--if there is a enemy inrange and has more hp than the double od damage donde by he skill
	-- or if the enemy would be left in a range to finish wit the ultiate skill
	if enemy~=nil and (health<enemy:GetActualDamage(damage,DAMAGE_TYPE_MAGICAL)*2 or UltKills(enemy,damage)) then
		--cast the skill
		npcBot:Action_UseAbilityOnEntity(ability,enemy);
		return;
	end
	
	--we get values for creeps
	local creep=nil;
	local chealth=10000;
	
	--we fill the values of the varibales based on which creep is the weakest in range of the bot
	creep,chealth=Utility.GetWeakestCreep(ability:GetCastRange());
	--if there is a creep in range and it heath is less than the damege done by the skill
	if creep~=nil and chealth<creep:GetActualDamage(damage,DAMAGE_TYPE_MAGICAL) then
		--if the creep is in range of the skill and the bot has the mana to cast the skill
		if Utility.GetDistance(creep:GetLocation(),npcBot:GetLocation())>npcBot:GetAttackRange()+150 and (npcBot:GetMana()/npcBot:GetMaxMana()>0.65 or npcBot:GetMana()>=GetComboMana()) then
			--use the skill on the creep
			npcBot:Action_UseAbilityOnEntity(ability,creep);
			return;
		end
	end
	
	--if there a enemy in range and we still have mana to cast
	if enemy~=nil and npcBot:GetMana()/npcBot:GetMaxMana()>0.50 and RandomInt(0,(1.1-npcBot:GetMana()/npcBot:GetMaxMana())*500)==0 then
		npcBot:Action_UseAbilityOnEntity(ability,enemy);
		return;
	end
end

local function UseW()
	local npcBot = GetBot();
	
	--we get the skill in the secon position
	local ability=npcBot:GetAbilityByName(Abilities[2]);
	--if the ability is not castable
	if not ability:IsFullyCastable() then
		--stop
		return;
	end
	
	local damage=ability:GetAbilityDamage();
	--we get the ability damage
	local damage=ability:GetAbilityDamage();
	
	local enemy=nil;
	local health=10000;
	
	--get the enemy with lowest hp in the skill range + 100
	enemy,health=Utility.GetWeakestHero(ability:GetCastRange()+100);
	
	--if there isn't an enemy in range
	if enemy==nil then
		--stop
		return;
	end
	
	--if we can don a combo of skills and the ultimate can finish of enemy
	if GetComboMana()<=npcBot:GetMana() and UltKills(enemy,damage+60) then
		--we use the skill
		npcBot:Action_UseAbilityOnEntity(ability,enemy);
		return;
	end
	
	--if there is a enemy in range and has less health than the skill damge + 50
	if enemy~=nil and health<enemy:GetActualDamage(damage,DAMAGE_TYPE_MAGICAL)+50 then
--		print("Zeus is using W on ",enemy:GetUnitName());
		--use the skill
		npcBot:Action_UseAbilityOnEntity(ability,enemy);
		return;
	end
	--if ther an enemy in range and we have more than 90 of mana or can manage a combo with the remaing mana and the abilñity level is more than 1
	if enemy~=nil and (npcBot:GetMana()/npcBot:GetMaxMana()>0.9 or GetComboMana()<=npcBot:GetMana()-ability:GetManaCost()) and ability:GetLevel()>1 then
--		print("Zeus is using W on ",enemy:GetUnitName());
		--we use the skill
		npcBot:Action_UseAbilityOnEntity(ability,enemy);
		return;
	end
end

--local strings to say during the match
local TrashTalk=
{
[1]="OMFG we have a jungler and a cliff jungler",
[3]="GG ff",
[764]="is our furion feeding again?",
[620]="we dont have a support...",
[630]="no one ganks my lane ..."
}

--string to represnt the  chracters in the bot team
local TrashTalkHero=
{
[1]="zuus",
[3]="zuus",
[8]="bloodseeker",
[10]="bloodseeker",
[550]="shredder",
[764]="furion",
[620]="zuus",
[630]="zuus"
}


local function HeroIsHere(heroname)
	for i=1,5,1 do
		--we check is an ally is here
		local Ally=GetTeamMember(GetTeam(),i);
		if Ally~=nil then
			--if the ally name correponds to the hero name
			if string.find(Ally:GetUnitName(),heroname)~=nil then
				return true;
			end
		end
	end
	
	return false;
end

local function ShitTalk()
	local npcBot=GetBot();
	--we get the local time
	local now = math.floor(DotaTime());
	--if there a string in the position of the current time in both tables
	if TrashTalk[now]~=nil and HeroIsHere(TrashTalkHero[now]) then
		--then say the string in chat
		npcBot:Action_Chat(TrashTalk[now],true);
		--we erase the string
		TrashTalk[now]=nil;
	end
	
	--if the bot doesn´t have gold previous gold ariable
	if npcBot.PrevGold==nil then
		--we update the previous gold value
		npcBot.PrevGold=npcBot:GetGold();
	end
	
	--if the current gold - the prvoiu gold quantitiy is more than 281
	if npcBot:GetGold()-npcBot.PrevGold>281 then
		--we add a question mark string to chat
		npcBot:Action_Chat("?",true);
	end
	
	--we update the gold
	npcBot.PrevGold=npcBot:GetGold();
end

-----------
function AbilityUsageThink()
	local npcBot=GetBot();
	--we use the ultimate skill
	UseUlt();

	--if the other player/npc retreats we don't use the others skills
	if npcBot:GetActiveMode()==BOT_MODE_RETREAT then
		return;
	end
	--the enemy is still around so we use the others skills to defeat it
	UseQ();
	UseW();
	
end

function CourierUsageThink()
	--we chat before thinking of using the courier
	ShitTalk();
	local npcBot=GetBot();
	--if the bot is alive and has the money for courier and is available
	if (npcBot:IsAlive() and (npcBot:GetStashValue()>900 or npcBot:GetCourierValue()>0 or Utility.HasRecipe()) and IsCourierAvailable()) then
		npcBot:Action_CourierDeliver();
	end
end


function ItemUsageThink()
	Utility.UseItems();
end


function BuybackUsageThink()
end
