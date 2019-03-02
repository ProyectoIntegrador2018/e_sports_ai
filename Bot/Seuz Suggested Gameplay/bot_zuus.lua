local minionutils = dofile( GetScriptDirectory().."/NewMinionUtil" )

-- This will decide wheter to attack minions (Farm) or prioritize other targets
function MinionThink(  hMinionUnit ) 
	if minionutils.IsValidUnit(hMinionUnit) then
		if hMinionUnit:IsIllusion() then
			minionutils.IllusionThink(hMinionUnit);
		elseif minionutils.IsAttackingWard(hMinionUnit:GetUnitName()) then
			minionutils.AttackingWardThink(hMinionUnit);
		else
			return;
		end
	end
end	