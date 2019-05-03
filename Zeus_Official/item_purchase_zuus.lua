-- This file overrides the default dota2 bot settings for item buying of Zeus Champ
local items = require(GetScriptDirectory() .. "/item_receipe" )
local purchase = require(GetScriptDirectory() .. "/item_build_zuus" )

local bot = GetBot();

bot.itemToBuy = {};                  
bot.currentItemToBuy = nil;       
bot.currentComponentToBuy = nil;    --This is a path for more powerful items 
bot.currListItemToBuy = {};         
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
local itemCost = 0;


-- This function is the one used to BUY the item
local function GeneralPurchase()
	-- Cache all needed item properties when the last item to buy not equal to current item component to buy
	if lastItemToBuy ~= bot.currentComponentToBuy then
		lastItemToBuy = bot.currentComponentToBuy;
		bot:SetNextItemPurchaseValue( GetItemCost( bot.currentComponentToBuy ) );
		itemCost = GetItemCost( bot.currentComponentToBuy );
	end
	
	local cost = itemCost;
	
	-- Buy the item if there is enough gold
	if ( bot:GetGold() >= cost and bot:GetItemInSlot(13) == nil ) 
	then
		print("buying... "..bot.currentComponentToBuy);
    if bot:ActionImmediate_PurchaseItem( bot.currentComponentToBuy ) == PURCHASE_ITEM_SUCCESS then
      bot.currentComponentToBuy = nil;                  
      bot.currListItemToBuy[#bot.currListItemToBuy] = nil;
      return
    else
      print("failed to buy "..bot.currentComponentToBuy.." : "..tostring(bot:ActionImmediate_PurchaseItem( bot.currentComponentToBuy )))	
    end
	end
end

local lastInvCheck = -90;
local fullInvCheck = -90;
local lastBootsCheck = -90;
local buyBootsStatus = false;
local addVeryLateGameItem = false
local buyRD = false;
local buyTP = false;

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
    print("Buying tango")
		bot:ActionImmediate_PurchaseItem("item_tango"); 
		buyAnotherTango = true;
		return;
	end
	
	-- Swap ward, flask, and tango_singe 
	if currentTime > 60 and botLevel < 25
	then
		check_time = currentTime;
		
		local tango_single = bot:FindItemSlot('item_tango_single');
		if tango_single >= 0 and tango_single <= 5 and GetItemCount(bot, "item_tango_single") >= 2 then
			local mostCostItem = FindMostItemToSwap();
			if mostCostItem ~= -1 then
        print("Swaping tango for "..mostCostItem)
				bot:ActionImmediate_SwapItems( tango_single, mostCostItem );
				return;
			end
		end
	end
	
	-- Sell early game item   
	if  ( GetGameMode() ~= 23 and botLevel > 12 and currentTime > fullInvCheck + 1.0 ) 
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
	
	-- Insert tp scroll to list item to buy and then change the buyTP flag so the bot don't reapeatedly add the tp scroll to list item to buy 
	if  currentTime > 2 *60 
    and buyTP == false
		and (bot:FindItemSlot('item_tpscroll') == -1 
		      or (botLevel >= 10 and items.GetItemCharges(bot, 'item_tpscroll') <= 1)) 
		and botGold >= 50
	then
			
		local tCharges = items.GetItemCharges(bot, 'item_tpscroll');
		
		if botLevel < 10 or (botLevel >= 10 and tCharges == 1)
		then
			buyTP = true;
      print("Buying tp scroll")
			bot:ActionImmediate_PurchaseItem("item_tpscroll");
			return;
		end
		
		if botLevel >= 10 and tCharges == 0 and botGold >= 100
		then
			buyTP = true;
      print("Buying tp scroll")
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
			'item_moon_shard'	
		}
		addVeryLateGameItem = true;
	end
	
	-- No need to purchase an item when there's none in the list
	if #bot.itemToBuy == 0 then bot:SetNextItemPurchaseValue( 0 ); return; end
	
	--Get the next item to buy and break it to item components then add it to currListItemToBuy. 
	if  bot.currentItemToBuy == nil and #bot.currListItemToBuy == 0 then    
		bot.currentItemToBuy = bot.itemToBuy[#bot.itemToBuy];
    print("Item to buy.. "..bot.currentItemToBuy)
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
