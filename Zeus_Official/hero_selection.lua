

----------------------------------------------------------------------------------------------------
function Think()

	if ( GetTeam() == TEAM_RADIANT )
	then
		print( "selecting radiant" );
		SelectHero( 2, "npc_dota_hero_zuus" );
		SelectHero( 3, "npc_dota_hero_axe" );
		SelectHero( 4, "npc_dota_hero_bane" );
		SelectHero( 5, "npc_dota_hero_bloodseeker" );
		SelectHero( 6, "npc_dota_hero_crystal_maiden" );
	elseif ( GetTeam() == TEAM_DIRE )
	then
		print( "selecting dire" );
		SelectHero( 7, "npc_dota_hero_zuus" );
		SelectHero( 8, "npc_dota_hero_earthshaker" );
		SelectHero( 9, "npc_dota_hero_juggernaut" );
		SelectHero( 10, "npc_dota_hero_mirana" );
		SelectHero( 11, "npc_dota_hero_nevermore" );
	end

end

----------------------------------------------------------------------------------------------------
