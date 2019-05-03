ItemModule = {}

ItemModule['earlyGameItem'] = {
	 "item_clarity",
	 "item_faerie_fire",
	 "item_tango",  
	 "item_flask", 
	 "item_stout_shield",
	 "item_quelling_blade",
	 "item_branches",
	 "item_magic_stick",
	 "item_orb_of_venom",
	 "item_bracer",
	 "item_wraith_band",
	 "item_null_talisman",
	 "item_magic_wand",  
	 "item_dust",
	 "item_ancient_janggo"
}

ItemModule['earlyBoots'] = {  
	"item_phase_boots", 
	"item_power_treads", 
	"item_tranquil_boots", 
	"item_arcane_boots"  
}

ItemModule["basic_items"] = {
	"item_aegis";
	"item_courier";
	"item_boots_of_elves";
	"item_belt_of_strength";
	"item_blade_of_alacrity";
	"item_blades_of_attack";
	"item_blight_stone";
	"item_blink";
	"item_boots";
	"item_bottle";
	"item_broadsword";
	"item_chainmail";
	"item_cheese";
	"item_circlet";
	"item_clarity";
	"item_claymore";
	"item_cloak";
	"item_demon_edge";
	"item_dust";
	"item_eagle";
	"item_enchanted_mango";
	"item_energy_booster";
	"item_faerie_fire";
	"item_flying_courier";
	"item_gauntlets";
	"item_gem";
	"item_ghost";
	"item_gloves";
	"item_flask";
	"item_helm_of_iron_will";
	"item_hyperstone";
	"item_branches";
	"item_javelin";
	"item_magic_stick";
	"item_mantle";
	"item_mithril_hammer";
	"item_lifesteal";
	"item_mystic_staff";
	"item_ward_observer";
	"item_ogre_axe";
	"item_orb_of_venom";
	"item_platemail";
	"item_point_booster";
	"item_quarterstaff";
	"item_quelling_blade";
	"item_reaver";
	"item_refresher_shard";
	"item_ring_of_health";
	"item_ring_of_protection";
	"item_ring_of_regen";
	"item_robe";
	"item_relic";
	"item_sobi_mask";
	"item_ward_sentry";
	"item_shadow_amulet";
	"item_slippers";
	"item_smoke_of_deceit";
	"item_staff_of_wizardry";
	"item_stout_shield";
	"item_talisman_of_evasion";
	"item_tango";
	"item_tango_single";
	"item_tome_of_knowledge";
	"item_tpscroll";
	"item_ultimate_orb";
	"item_vitality_booster";
	"item_void_stone";
	"item_wind_lace";
	"item_ring_of_tarrasque";
	"item_crown";
}

ItemModule["item_arcane_boots"] = { "item_boots"; "item_energy_booster"}
ItemModule["item_magic_wand"] = { "item_branches"; "item_branches"; "item_magic_stick"; "item_recipe_magic_wand" }
ItemModule["item_pipe"] = { "item_hood_of_defiance"; "item_headdress"; "item_recipe_pipe" }
ItemModule["item_veil_of_discord"] = { "item_crown"; "item_helm_of_iron_will"; "item_recipe_veil_of_discord" }
ItemModule["item_cyclone"] = { "item_wind_lace"; "item_void_stone"; "item_staff_of_wizardry"; "item_recipe_cyclone" }
ItemModule["item_ultimate_scepter"] = { "item_point_booster"; "item_ogre_axe"; "item_blade_of_alacrity";"item_staff_of_wizardry"  }
ItemModule["item_sheepstick"] = {"item_ultimate_orb"; "item_void_stone"; "item_mystic_staff" }
ItemModule["item_guardian_greaves"] = { "item_arcane_boots"; "item_mekansm"; "item_recipe_guardian_greaves" }

-- Check if hero have the current itemToBuy in main inventory
function ItemModule.IsItemInHero(item_name)
	-- Raindrops break often so ignore
  if item_name == 'item_infused_raindrop' then 
		return false; 
	else 
		local bot = GetBot();
		item_name = ItemModule.NormItemName(item_name);
		
		if(item_name == 'item_double_branches')
		then 
			return ItemModule.GetItemCount(bot,"item_branches") == 2
		end
		if(item_name == 'item_double_wraith_band')
		then 
			return ItemModule.GetItemCount(bot,"item_wraith_band") == 2
		end
		if(item_name == 'item_viper_outfit' 
		   or item_name == "item_razor_outfit"
		   or item_name == 'item_sniper_outfit')
		then			
			return ItemModule.IsItemInHero("item_urn_of_shadows")
		end
		if(item_name == 'item_nevermore_outfit'
		   or item_name == "item_clinkz_outfit"
		   or item_name == 'item_terrorblade_outfit'
		   or item_name == "item_luna_outfit"
		   or item_name == 'item_medusa_outfit')
		then			
			return ItemModule.IsItemInHero("item_vladmir")
		end
		if(item_name == 'item_drow_ranger_outfit')
		then 
			return ItemModule.IsItemInHero("item_lifesteal")
		end
		if(item_name == 'item_arc_warden_outfit')
		then 
			return ItemModule.IsItemInHero("item_hand_of_midas")
		end
		if(item_name == 'item_chaos_knight_outfit')
		then 
			return ItemModule.IsItemInHero("item_echo_sabre")
		end
		if(item_name == 'item_dragon_knight_outfit' 
			or item_name == "item_kunkka_outfit"
			or item_name == "item_bristleback_outfit")
		then 
			return ItemModule.IsItemInHero("item_crimson_guard")
		end
		if(item_name == 'item_silencer_outfit'
		   or item_name == "item_crystal_maiden_outfit")
		then 
			return ItemModule.IsItemInHero("item_magic_wand")
		end
				
		local slot = bot:FindItemSlot(item_name);
		local slotType = bot:GetItemSlotType(slot);
		return slotType == ITEM_SLOT_TYPE_MAIN or slotType == ITEM_SLOT_TYPE_BACKPACK;	
	end
end

function ItemModule.GetBasicItems( ... )
    local basicItemTable = {}  
    for i,v in pairs(...) do    
        if ItemModule[v] ~= nil      
		   and ItemModule.IsItemInHero(v) == false 
		then                                        
            for _,w in pairs(ItemModule.GetBasicItems(ItemModule[v])) do  
				basicItemTable[#basicItemTable+1] = w;  
            end
        elseif ItemModule[v] == nil and ItemModule.IsItemInHero(v) == false then
			basicItemTable[#basicItemTable+1] = v;
        end
    end
    return basicItemTable
end

-- Amount of empty slots in inventory
function ItemModule.GetEmptyInventoryAmount(bot)
	local amount = 0;
	for i=0,8 do	
		local item = bot:GetItemInSlot(i);
		if item == nil then
			amount = amount + 1;
		end
	end
	return amount;
end

-- Return item charges
function ItemModule.GetItemCharges(bot, item_name)
	local charges = 0;
	for i = 0, 15 do
		local item = bot:GetItemInSlot(i);
		if item ~= nil and item:GetName() == item_name then
			charges = charges + item:GetCurrentCharges();
		end
	end
	return charges;
end

-- Return amount of items
function ItemModule.GetItemCount(unit, item_name)
	local count = 0;
	for i = 0, 15 
	do
		local item = unit:GetItemInSlot(i)
		if item ~= nil and item:GetName() == item_name then
			count = count + 1;
		end
	end
	return count;
end

-- Check if the bot has the item
function ItemModule.HasItem(bot, item_name)
	return bot:FindItemSlot(item_name) >= 0;
end

-- Returns the boot status (early to late game)
function ItemModule.UpdateBuyBootStatus(bot)
	local bootsSlot = bot:FindItemSlot('item_boots');
	if bootsSlot == - 1 then
		for i=1,#ItemModule['earlyBoots'] do
		    bootsSlot = bot:FindItemSlot(ItemModule['earlyBoots'][i]);
			if bootsSlot >= 0 then
				break;
			end
		end
	end
	return bootsSlot >= 0;
end

-- returns the normal item name (advanced items and game modes only)
function ItemModule.NormItemName(item_name)
	return item_name;
end

return ItemModule