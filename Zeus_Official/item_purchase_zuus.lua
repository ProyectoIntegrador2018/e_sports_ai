-- This file overrides the default dota2 bot settings for item buying of Zeus Champ
local items = require(GetScriptDirectory() .. "/item_receipe" )

local bot = GetBot();

bot.itemToBuy = {};                  
bot.currentItemToBuy = nil;       
bot.currentComponentToBuy = nil;    --This is a path for more powerful items 
bot.currListItemToBuy = {};         
bot.SecretShop = false;             -- I can't remember if this was forbbiden in the game mode so just prograamed it anyways
bot.SideShop = false;               -- I can't remember if this was forbbiden in the game mode so just prograamed it anyways
local unitName = bot:GetUnitName();

-- Swap items order to buy what's "buyable"
for i=1, math.ceil(#purchase['items']/2) do
	bot.itemToBuy[i] = purchase['items'][#purchase['items']-i+1]; 
	bot.itemToBuy[#purchase['items']-i+1] = purchase['items'][i];
end


-- Add tango and healing salve as starting consumables item
if DotaTime() < 0 then
	bot.itemToBuy[#bot.itemToBuy+1] = 'item_flask';
	bot.itemToBuy[#bot.itemToBuy+1] = 'item_tango';
end

local lastItemToBuy = nil;
local CanPurchaseFromSecret = false;  -- I can't remember if this was forbbiden in the game mode so just prograamed it anyways
local CanPurchaseFromSide = false;    -- I can't remember if this was forbbiden in the game mode so just prograamed it anyways
local itemCost = 0;


-- This function is the one used to BUY the item
local function GeneralPurchase()

	-- Cache all needed item properties when the last item to buy not equal to current item component to buy
	if lastItemToBuy ~= bot.currentComponentToBuy then
		lastItemToBuy = bot.currentComponentToBuy;
		bot:SetNextItemPurchaseValue( GetItemCost( bot.currentComponentToBuy ) );
		CanPurchaseFromSecret = IsItemPurchasedFromSecretShop(bot.currentComponentToBuy); -- Again this is secret shop buying so comment the section to
		CanPurchaseFromSide   = IsItemPurchasedFromSideShop(bot.currentComponentToBuy);   -- prevent secret and side shop usage
		itemCost = GetItemCost( bot.currentComponentToBuy );
		if bot.currentComponentToBuy == "item_ring_of_health" or bot.currentComponentToBuy== "item_void_stone" 
		then CanPurchaseFromSecret = false end

	end
	
	local cost = itemCost;
	
	-- Buy the item if there is enough gold
	if ( bot:GetGold() >= cost and bot:GetItemInSlot(13) == nil ) 
	then
		
    if bot:ActionImmediate_PurchaseItem( bot.currentComponentToBuy ) == PURCHASE_ITEM_SUCCESS then
      bot.currentComponentToBuy = nil;                  
      bot.currListItemToBuy[#bot.currListItemToBuy] = nil;  
      bot.SecretShop = false;                               
      bot.SideShop = false;	                              
      return
    else
      print("[ITEM PURCHASE] "..bot:GetUnitName().." failed to purchase "..bot.currentComponentToBuy.." : "..tostring(bot:ActionImmediate_PurchaseItem( bot.currentComponentToBuy )))	
    end
    
	else
		bot.SecretShop = false;              
		bot.SideShop = false;
	end
end

local lastInvCheck = -90;
local fullInvCheck = -90;
local lastBootsCheck = -90;
local buyBootsStatus = false;
local addVeryLateGameItem = false
local buyRD = false;
local buyTP = false;
local buyBottle = false;

local buyAnotherRD = false
local buyAnotherTango = false
local switchTime = 0
local buyWardTime = -999
local checkMoonShareTime = 0

local addHandofMidas = false
local sellHandofMidas = false


-- This function is called every frame and does the thinking to purchase items
function ItemPurchaseThink()  
	-- No item is bought in pre game
	if ( GetGameState() ~= GAME_STATE_PRE_GAME and GetGameState() ~= GAME_STATE_GAME_IN_PROGRESS )
	then
		return;
	end
	
	local currentTime = DotaTime();
	local botName     = bot:GetUnitName();
	local botLevel    = bot:GetLevel();
	local botGold     = bot:GetGold();
	local botMode     = bot:GetActiveMode();
	
	-- Buy another tango for midlaner
	if currentTime > 60 and currentTime < 4*60 
	   and buyAnotherTango == false
	   and not items.HasItem(bot,"item_tango_single")
	   and botGold > GetItemCost( "item_tango" ) 
	   and items.GetEmptyInventoryAmount(bot) >= 5
	then
		bot:ActionImmediate_PurchaseItem("item_tango"); 
		buyAnotherTango = true;
		return;
	end
		
	-- Buy bottle usefull to zeus
	if currentTime > 0 and currentTime < 15 
     and #bot.currListItemToBuy > 0
     and buyBottle == false
	then
		bot.currListItemToBuy[#bot.currListItemToBuy+1]  =  "item_bottle";
		bot.currentComponentToBuy = nil;
		buyBottle = true;
		return
	end
	
  -- Buy ward
	if currentTime < 0 and 
		and GetItemStockCount( "item_ward_observer" ) >= 1
		and botGold >= GetItemCost( "item_ward_observer" ) 
		and items.GetItemCharges(bot, "item_ward_observer") < 1
	then
		bot:ActionImmediate_PurchaseItem("item_ward_observer"); 
	end

	-- Buy raindrop (mana regen and magic damage block)
	if buyRD == false
	   and currentTime > 3 *60
	   and buyBootsStatus == true
	   and GetItemStockCount( "item_infused_raindrop" ) > 0 
	   and botGold >= GetItemCost( "item_infused_raindrop" ) 
	   and items.HasItem(bot, 'item_boots')
	then
		bot:ActionImmediate_PurchaseItem("item_infused_raindrop"); 
		buyRD = true;
		return;
	end
	
	-- Re-Buy Raindrop
	if currentTime > 5 *60 and buyAnotherRD == false and botLevel < 21
	then
		local recipe_urn_of_shadows = bot:FindItemSlot("item_recipe_urn_of_shadows");
		local raindrop = bot:FindItemSlot("item_infused_raindrop");
		if  recipe_urn_of_shadows >= 0 and recipe_urn_of_shadows <= 8 and raindrop == -1
			and botGold >= GetItemCost( "item_infused_raindrop" ) 
			and GetItemStockCount( "item_infused_raindrop" ) > 0 
		then
			bot:ActionImmediate_PurchaseItem("item_infused_raindrop"); 
			buyAnotherRD = true;
			return;
		end
	end
  
	-- Swap Raindrop before it breaks
	if currentTime > 180 and currentTime < 1800
	   and switchTime < currentTime - 5.6
	then
		local raindrop = bot:FindItemSlot("item_infused_raindrop");
		local raindropCharge = items.GetItemCharges(bot, "item_infused_raindrop");
		local nEnemyHeroes = bot:GetNearbyHeroes(1600,true,BOT_MODE_NONE)
		if (raindrop >= 0 and raindrop <= 5)
		   and  ( nEnemyHeroes[1] ~= nil 
		          or bot:WasRecentlyDamagedByAnyHero(3.1))
		   and  raindropCharge == 1
		then
		    switchTime = currentTime;
			bot:ActionImmediate_SwapItems( raindrop, 8 );
			return;
		end
	end
	
	-- Swap ward, flask, and tango_singe 
	if currentTime > 60 and botLevel < 25
		and bot:GetActiveMode() ~= BOT_MODE_WARD
		and check_time < currentTime - 10
	then
		check_time = currentTime;
		local wardSlot = bot:FindItemSlot('item_ward_observer');
		if wardSlot >=0 and wardSlot <= 5 then
			local mostCostItem = FindMostItemToSwap();
			if mostCostItem ~= -1 then
				bot:ActionImmediate_SwapItems( wardSlot, mostCostItem );
				return;
			end
		end
		
		local tango_single = bot:FindItemSlot('item_tango_single');
		if tango_single >= 0 and tango_single <= 5 and GetItemCount(bot, "item_tango_single") >= 2 then
			local mostCostItem = FindMostItemToSwap();
			if mostCostItem ~= -1 then
				bot:ActionImmediate_SwapItems( tango_single, mostCostItem );
				return;
			end
		end
		
	end
	
	-- Sell early game item   
	if  ( GetGameMode() ~= 23 and botLevel > 12 and currentTime > fullInvCheck + 1.0 
	      and ( bot:DistanceFromFountain() <= 150 or bot:DistanceFromSecretShop() <= 150 ) ) 
		or ( GetGameMode() == 23 and botLevel > 10 and currentTime > fullInvCheck + 1.0  )
	then
		local emptySlot = items.GetEmptyInventoryAmount(bot);
		local slotToSell = nil;
		local preEmpty = 2;
		if botLevel < 18 then preEmpty = 1; end
		if emptySlot < preEmpty then
			for i=1,#items['earlyGameItem'] do
				local item = items['earlyGameItem'][i];
				local itemSlot = bot:FindItemSlot(item);
				if itemSlot >= 0 and itemSlot <= 8 then
					if item == "item_stout_shield" then
						if buildVanguard == false  then
							slotToSell = itemSlot;
							break;
						end
					elseif item == "item_quelling_blade" then
						if buildBFury == false then
							slotToSell = itemSlot;
							break;
						end
					else
						slotToSell = itemSlot;
						break;
					end
				end
			end
		end	
		if slotToSell ~= nil then
			bot:ActionImmediate_SellItem(bot:GetItemInSlot(slotToSell));
		end
		fullInvCheck = currentTime;
	end
	
	-- Sell non Boots of Travel boots when geeting the Boots of Travel
	if currentTime > 30 *60 
	   and  ( bot:DistanceFromFountain() == 0 or bot:DistanceFromSecretShop() == 0 )
	   and ( items.HasItem( bot, "item_travel_boots") or items.HasItem( bot, "item_travel_boots_2")) 
	then	
		for i=1,#items['earlyBoots']
		do
			local bootsSlot = bot:FindItemSlot(items['earlyBoots'][i]);
			if bootsSlot >= 0 then
				bot:ActionImmediate_SellItem(bot:GetItemInSlot(bootsSlot));
			end
		end
	end
	
	-- Insert tp scroll to list item to buy and then change the buyTP flag so the bot don't reapeatedly add the tp scroll to list item to buy 
	if  currentTime > 2 *60 
	    and buyTP == false 
		and items.HasItem(bot, 'item_travel_boots') == false 
		and items.HasItem(bot, 'item_travel_boots_2') == false  
		and bot:GetCourierValue() == 0 
		and (bot:FindItemSlot('item_tpscroll') == -1 
		      or (botLevel >= 10 and items.GetItemCharges(bot, 'item_tpscroll') <= 1)) 
		and botGold >= 50
	then
			
		local tCharges = items.GetItemCharges(bot, 'item_tpscroll');
		
		if botLevel < 10 or (botLevel >= 10 and tCharges == 1)
		then
			buyTP = true;
			bot:ActionImmediate_PurchaseItem("item_tpscroll");
			return;
		end
		
		if botLevel >= 10 and tCharges == 0 and botGold >= 100
		then
			buyTP = true;
			bot:ActionImmediate_PurchaseItem("item_tpscroll");
			bot:ActionImmediate_PurchaseItem("item_tpscroll");
			return;
		end
	end
	
	-- After getting the TP request it again for next "brb"
	if buyTP == true 
		and ( (botLevel < 10 and bot:FindItemSlot('item_tpscroll') > -1)
				or (botLevel >= 10 and items.GetItemCharges(bot, 'item_tpscroll') >= 2) )
	then
		buyTP = false;
	end
	
	-- Fill purchase table with super late game item
	if false and #bot.itemToBuy == 0 and addVeryLateGameItem == false then
		bot.itemToBuy = {
			'item_travel_boots_2',
			'item_moon_shard',	
		}
		if items.HasItem(bot, 'item_travel_boots') == false then
			bot.itemToBuy[#bot.itemToBuy+1] = 'item_travel_boots';
		end
		addVeryLateGameItem = true;
	end
	
	-- No need to purchase an item when there's none in the list
	if #bot.itemToBuy == 0 then bot:SetNextItemPurchaseValue( 0 ); return; end
	
	--Get the next item to buy and break it to item components then add it to currListItemToBuy. 
	if  bot.currentItemToBuy == nil and #bot.currListItemToBuy == 0 then    
		bot.currentItemToBuy = bot.itemToBuy[#bot.itemToBuy];               
		local tempTable = items.GetBasicItems({items.NormItemName(bot.currentItemToBuy)})   
		for i=1,math.ceil(#tempTable/2)                                                     
		do	
			bot.currListItemToBuy[i] = tempTable[#tempTable-i+1];
			bot.currListItemToBuy[#tempTable-i+1] = tempTable[i];
		end
		
	end
	
	--Check if the bot already has the item formed from its components in their inventory (not stash)
	if  #bot.currListItemToBuy == 0 and currentTime > lastInvCheck + 3.0 then  
	    if items.IsItemInHero(bot.currentItemToBuy) 
		then   
			bot.currentItemToBuy = nil;                         
			bot.itemToBuy[#bot.itemToBuy] = nil;           
		else
			lastInvCheck = currentTime;
		end
	--Added item component to current item component to buy and do the purchase	
	elseif #bot.currListItemToBuy > 0 then           
		if bot.currentComponentToBuy == nil then      
			bot.currentComponentToBuy = bot.currListItemToBuy[#bot.currListItemToBuy];  
		else                                          
      GeneralPurchase();
		end
	end

end

-- This function will choose the best item to swap with the item currently being bough (Swap = sell for gold)
function FindMostItemToSwap()
	local maxCost = 0;
	local idx = -1;
	for i=6,8 do
		if  bot:GetItemInSlot(i) ~= nil  then
			local _item = bot:GetItemInSlot(i):GetName()
			if( GetItemCost(_item) > maxCost ) then
				maxCost = GetItemCost(_item);
				idx = i;
			end
		end
	end
	return idx;
end

-- Returns the number of items in bag
function GetItemCount(unit, item_name)
	local count = 0;
	for i = 0, 5 
	do
		local item = unit:GetItemInSlot(i)
		if item ~= nil and item:GetName() == item_name then
			count = count + 1;
		end
	end
	return count;
end
