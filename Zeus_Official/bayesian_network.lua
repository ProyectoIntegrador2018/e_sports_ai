local BotsInit = require( "game/botsinit" );
local Idea = BotsInit.CreateGeneric();

local map_awareness = require(GetScriptDirectory() ..  "/map_awareness");

local npcBot = GetBot();

local botStatus = -1;

local enemycreepcount = 0;

-- Probability Matrixes (nodes of bayesian network)
local BotHealthProb = {0.7,0.2,0.1};
local EnemyHealthProb = {0.7,0.2,0.1};
local DistanceEnemyTowerProb = {0.3, 0.7};
local MinionsAmountProb = {0.5,0.5};
local AttackProb = {{0.5,0.5},{0.2,0.8},{0.7,0.3},{0.3,0.7},{0.9,0.1},{0.85,0.15},{0.25,0.75},{0.2,0.8},{0.5,0.5},{0.3,0.7},
                    {0.8,0.2},{0.6,0.4},{0.05,0.95},{0,1},{0.15,0.85},{0.1,0.9},{0.2,0.8},{0.15,0.5}};
local PushProb = {{0.4,0.6},
                  {0.7,0.3},
                  {0.3,0.7},
                  {0.5,0.5},
                  {0.6,0.4},
                  {0.75,0.25},
                  {0.35,0.65},
                  {0.8,0.2},
                  {0.8,0.2},
                  {0.95,0.05},
                  {0.45,0.55},
                  {1.0,0.0},
                  {0.35,0.65},
                  {0.4,0.6},
                  {0.15,0.85},
                  {0.35,0.65},
                  {0.4,0.6},
                  {0.6,0.4},
                  {0.2,0.8},
                  {0.65,0.35},
                  {0.55,0.45},
                  {0.85,0.15},
                  {0.3,0.7},
                  {0.85,0.15},
                  {0,1},
                  {0.05,1},
                  {0,1},
                  {0.75,0.25},
                  {0,1},
                  {0.3,0.7},
                  {0,1},
                  {0.05,0.95},
                  {0,2},
                  {0.5,0.5},
                  {0,1},
                  {0.7,0.3}};
local RetreatProb = {{0.4,0.6},
                    {0.2,0.8},
                    {0.25,0.75},
                    {0.1,0.9},
                    {0.15,0.85},
                    {0,1},
                    {0.7,0.3},
                    {0.6,0.4},
                    {0.55,0.45},
                    {0.5,0.5},
                    {0.1,0.9},
                    {0.05,0.95},
                    {1,0},
                    {1,0.2},
                    {0.85,0.25},
                    {0.8,0.4},
                    {1,0.2},
                    {0.9,0.5}};
local FarmProb = {{0.3,0.7},
                  {0.8,0.3},
                  {0.15,0.85},
                  {0.85,0.2}};
local LaningProb = {{0.35,0.65},
                    {0.75,0.25},
                    {0.2,0.8},
                    {0.77,0.23}};

--
-- Information received by the bot
function updateData()
  ------------------ Observable enviroment variables --------------------------
  local botMaxHealt = npcBot:GetMaxHealth();
  local botHealth = npcBot:GetHealth();

  local enemyMaxHealt;
  local enemyHealth;
  local enemyStatus = -1;

  local enemyteam = npcBot:GetTeam();
  if enemyteam == 3 then enemyteam = 2 elseif enemyteam == 2 then enemyteam = 3 end
  local tower = GetTower(enemyteam,TOWER_MID_1);
  local inRangeofEnemyTower = GetUnitToUnitDistance(npcBot,tower) < 700;

  local nearbylanecreeps = npcBot:GetNearbyLaneCreeps(700,false);
  local allycreepcount = 0;
  for _,creep in pairs(nearbylanecreeps) do	
      allycreepcount = allycreepcount + 1;
  end

  local nearbyEnemylanecreeps = npcBot:GetNearbyLaneCreeps(700,true);
  enemycreepcount = 0;
  for _,creep in pairs(nearbyEnemylanecreeps) do	
      enemycreepcount = enemycreepcount + 1;
  end

  local moreAllyCreeps = (allycreepcount*1.5) > enemycreepcount;
  -------------------------------------------------------------------------------

  -- Calculates enemy health
  local enemies = npcBot:GetNearbyHeroes(1000, true, BOT_MODE_NONE);
  if enemies ~= nil then
    for _,e in pairs(enemies) do
      enemyMaxHealt = e:GetMaxHealth();
      enemyHealth = e:GetHealth();
    end
  end
  
  -- Define bot status (Healty, Wounded, Dying)
  if botHealth ~= nil then
    if botHealth/botMaxHealt > 0.8 then
      botStatus = 1;
    elseif botHealth/botMaxHealt > 0.5 then
      botStatus = 2;
    else
      botStatus = 3;
    end
  end
  
   -- Define enemy status (Healthy, Wounded, Dying)
  if enemyHealth ~= nil then
    if enemyHealth/enemyMaxHealt > 0.75 then
      enemyStatus = 1;
    elseif enemyHealth/enemyMaxHealt > 0.3 then
      enemyStatus = 2;
    else
      enemyStatus = 3;
    end
  end
  
end

-- Desire Variables
local attackDesire = 0.0;
local pushdesire = 0.0;
local retreatDesire = 0.0;
local farmDesire = 0.0;
local laneDesire = 0.0;

-- Function to calculate the probability of Attacking given Bot Health, Enemy Health, and Distance to enemy tower
function calculateAttackDesire()
    attackDesire = 0.0;
    updateData();
    
    local _botVal;
    local _enemyVal;
    local _towerVal;
    
    -- The mapping matrix has the class attributes of the Attack node ({1,1,1} = true true true, {1,1,0} = true true false, etc...)
    local mappingMatrix = {{1,1,1},{1,1,0},{1,2,1},{1,2,0},{1,3,1},{1,3,0},{2,1,1},{2,1,0},{2,2,1},
                            {2,2,0},{2,3,1},{2,3,0},{3,1,1},{3,1,0},{3,2,1},{3,2,0},{3,3,1},{3,3,0}};
    
    if botStatus ~= -1 then
      _botVal = BotHealthProb[botStatus];
    end
    
    if enemyStatus ~= -1 then
      _enemyVal = EnemyHealthProb[enemyStatus];
    end
    
    if inRangeofEnemyTower then
      _towerVal = DistanceEnemyTowerProb[1];
    else
      _towerVal = DistanceEnemyTowerProb[2];
    end
    
    local y = 1;
    local enemyStatusAux = 1;
    local probValues = {};
    local probValuesBotVal = {};
    local probValuesEnemyVal = {};
    local probValuesTowerVal = {};
    
-- Using the mapping matrix we get the probabilities of every posible outcome and store tem in 4 different arrays P(A,BH,EH,DT)
    for x = 1, 18 do
      if mappingMatrix[x][1] == botStatus or botStatus == -1 then
        if mappingMatrix[x][2] == botStatus or enemyStatus == -1 then
          if (mappingMatrix[x][3] == 1 and inRangeofEnemyTower) or (mappingMatrix[x][3] == 0 and not inRangeofEnemyTower) then
            probValues[y] = AttackProb[x][1];
            probValuesBotVal[y] = _botVal;
            
            if enemyStatus == -1 then 
              probValuesEnemyVal[y] = EnemyHealthProb[enemyStatusAux];
              enemyStatusAux = enemyStatusAux + 1;
              if enemyStatusAux > 3 then
                enemyStatusAux = 1;
              end
            else
              probValuesEnemyVal[y] = _enemyVal;
            end
            
            probValuesTowerVal[y] = _towerVal;
            
            y = y+1;
            
          end
        end
      end
    end
    
-- We then calculate the probabilities of the outcome given the results
    if y < 3 then
      attackDesire = probValues[1];
    else
      for x = 1,(y-1) do
        local prob = probValues[x] * probValuesBotVal[x] * probValuesEnemyVal[x] * probValuesTowerVal[x];
        --print(probValues[x].." * "..probValuesBotVal[x].." * "..probValuesEnemyVal[x].." * "..probValuesTowerVal[x].." = "..prob);
        attackDesire = attackDesire + prob;
      end
      --print("= "..attackDesire);
    end
    
    return attackDesire;
end

-- Function to calculate the probability of Retreating given Bot Health, Enemy Health, and Distance to enemy tower
function calculateRetreatDesire()
    retreatDesire = 0.0;
    updateData();
    
    local _botVal;
    local _enemyVal;
    local _towerVal;
    
    -- The mapping matrix has the class attributes of the Attack node ({1,1,1} = true true true, {1,1,0} = true true false, etc...)
    local mappingMatrix = {{1,1,1},{1,1,0},{1,2,1},{1,2,0},{1,3,1},{1,3,0},{2,1,1},{2,1,0},{2,2,1},
                            {2,2,0},{2,3,1},{2,3,0},{3,1,1},{3,1,0},{3,2,1},{3,2,0},{3,3,1},{3,3,0}};
    
    if botStatus ~= -1 then
      _botVal = BotHealthProb[botStatus];
    end
    
    if enemyStatus ~= -1 then
      _enemyVal = EnemyHealthProb[enemyStatus];
    end
    
    if inRangeofEnemyTower then
      _towerVal = DistanceEnemyTowerProb[1];
    else
      _towerVal = DistanceEnemyTowerProb[2];
    end
    
    local y = 1;
    local enemyStatusAux = 1;
    local probValues = {};
    local probValuesBotVal = {};
    local probValuesEnemyVal = {};
    local probValuesTowerVal = {};
    
-- Using the mapping matrix we get the probabilities of every posible outcome and store tem in 4 different arrays P(R,BH,EH,DT)
    for x = 1, 18 do
      if mappingMatrix[x][1] == botStatus or botStatus == -1 then
        if mappingMatrix[x][2] == botStatus or enemyStatus == -1 then
          if (mappingMatrix[x][3] == 1 and inRangeofEnemyTower) or (mappingMatrix[x][3] == 0 and not inRangeofEnemyTower) then
            probValues[y] = RetreatProb[x][1];
            probValuesBotVal[y] = _botVal;
            
            if enemyStatus == -1 then 
              probValuesEnemyVal[y] = EnemyHealthProb[enemyStatusAux];
              enemyStatusAux = enemyStatusAux + 1;
              if enemyStatusAux > 3 then
                enemyStatusAux = 1;
              end
            else
              probValuesEnemyVal[y] = _enemyVal;
            end
            
            probValuesTowerVal[y] = _towerVal;
            
            y = y+1;
            
          end
        end
      end
    end
    
-- We then calculate the probabilities of the outcome given the results
    if y < 3 then
      retreatDesire = probValues[1];
    else
      for x = 1,(y-1) do
        local prob = probValues[x] * probValuesBotVal[x] * probValuesEnemyVal[x] * probValuesTowerVal[x];
        --print(probValues[x].." * "..probValuesBotVal[x].." * "..probValuesEnemyVal[x].." * "..probValuesTowerVal[x].." = "..prob);
        retreatDesire = retreatDesire + prob;
      end
      --print("= ".. retreatDesire );
    end
    
    return retreatDesire;
end

-- Function to calculate the probability of Farming given Distance to enemy tower and Visible Minions
function calculateFarmDesire()
    farmDesire = 0.0;
    updateData();
    
    local _towerVal;
    local _minionsVal;
    
    -- The mapping matrix has the class attributes of the Attack node ({1,1,1} = true true true, {1,1,0} = true true false, etc...)
    local mappingMatrix = {{1,1},{1,0},{0,1},{0,0}};
    
    if moreAllyCreeps then
      _minionsVal = MinionsAmountProb[1];
    else
      _minionsVal = MinionsAmountProb[2];
    end
    
    if inRangeofEnemyTower then
      _towerVal = DistanceEnemyTowerProb[1];
    else
      _towerVal = DistanceEnemyTowerProb[2];
    end
    
    local y = 1;
    local probValues = {};
    local probValuesTowerVal = {};
    local probValuesMinionVal = {};
    
-- Using the mapping matrix we get the probabilities of every posible outcome and store tem in 4 different arrays P(R,BH,EH,DT)
    for x = 1, 4 do
      if (mappingMatrix[x][1] == 1 and moreAllyCreeps) or (mappingMatrix[x][1] == 0 and not moreAllyCreeps) then
        if (mappingMatrix[x][2] == 1 and inRangeofEnemyTower) or (mappingMatrix[x][2] == 0 and not inRangeofEnemyTower) then
          probValues[y] = FarmProb[x][1];
          
          probValuesTowerVal[y] = _towerVal;
          
          probValuesMinionVal[y] = _minionsVal;
          
          y = y+1;
        end
      end
    end
    
-- We then calculate the probabilities of the outcome given the results
    if y < 3 then
      farmDesire = probValues[1];
    else
      for x = 1,(y-1) do
        local prob = probValues[x] * probValuesMinionVal[x] * probValuesTowerVal[x];
        print(probValues[x].." * "..probValuesMinionVal[x].." * "..probValuesTowerVal[x].." = "..prob);
        farmDesire = farmDesire + prob;
      end
      print("= ".. farmDesire );
    end
    if enemycreepcount == 0 then
      return 0;
    else
      return farmDesire;
    end
end

-- Function to calculate the probability of Laning given Distance to enemy tower and Visible Minions
function calculateLaningDesire()
    laneDesire = 0.0;
    updateData();
    
    local _towerVal;
    local _minionsVal;
    
    -- The mapping matrix has the class attributes of the Attack node ({1,1,1} = true true true, {1,1,0} = true true false, etc...)
    local mappingMatrix = {{1,1},{1,0},{0,1},{0,0}};
    
    if moreAllyCreeps then
      _minionsVal = MinionsAmountProb[1];
    else
      _minionsVal = MinionsAmountProb[2];
    end
    
    if inRangeofEnemyTower then
      _towerVal = DistanceEnemyTowerProb[1];
    else
      _towerVal = DistanceEnemyTowerProb[2];
    end
    
    local y = 1;
    local probValues = {};
    local probValuesTowerVal = {};
    local probValuesMinionVal = {};
    
-- Using the mapping matrix we get the probabilities of every posible outcome and store tem in 4 different arrays P(R,BH,EH,DT)
    for x = 1, 4 do
      if (mappingMatrix[x][1] == 1 and moreAllyCreeps) or (mappingMatrix[x][1] == 0 and not moreAllyCreeps) then
        if (mappingMatrix[x][2] == 1 and inRangeofEnemyTower) or (mappingMatrix[x][2] == 0 and not inRangeofEnemyTower) then
          probValues[y] = LaningProb[x][1];
          
          probValuesTowerVal[y] = _towerVal;
          
          probValuesMinionVal[y] = _minionsVal;
          
          y = y+1;
        end
      end
    end
    
-- We then calculate the probabilities of the outcome given the results
    if y < 3 then
      laneDesire = probValues[1];
    else
      for x = 1,(y-1) do
        local prob = probValues[x] * probValuesMinionVal[x] * probValuesTowerVal[x];
        print(probValues[x].." * "..probValuesMinionVal[x].." * "..probValuesTowerVal[x].." = "..prob);
        laneDesire = laneDesire + prob;
      end
      print("= ".. laneDesire );
    end
    
    return laneDesire;
end

-- Function to calculate the probability of Pushing given Bot Health, Enemy Health, Distance to enemy tower and Visible Minions
function calculatePushDesire()
    pushdesire = 0.0;
    updateData();
    
    local _botVal;
    local _enemyVal;
    local _towerVal;
    local _minionsVal;
    
    -- The mapping matrix has the class attributes of the Attack node ({1,1,1} = true true true, {1,1,0} = true true false, etc...)
    local mappingMatrix = {{1,1,1,1},{1,1,1,0},{1,1,0,1},
                          {1,1,0,0},{1,2,1,1},{1,2,1,0},{1,2,0,1},{1,2,0,0},{1,3,1,1},{1,3,1,0},{1,3,0,1},{1,3,0,0},{2,1,1,1},{2,1,1,0},
                          {2,1,0,1},{2,1,0,0},{2,2,1,1},{2,2,1,0},{2,2,0,1},{2,2,0,0},{2,3,1,1},{2,3,1,0},{2,3,0,1},{2,3,0,0},{3,1,1,1},
                          {3,1,1,0},{3,1,0,1},{3,1,0,0},{3,2,1,1},{3,2,1,0},{3,2,0,1},{3,2,0,0},{3,3,1,1},{3,3,1,0},{3,3,0,1},{3,3,0,0}};
    
    if moreAllyCreeps then
      _minionsVal = MinionsAmountProb[1];
    else
      _minionsVal = MinionsAmountProb[2];
    end
    
    if botStatus ~= -1 then
      _botVal = BotHealthProb[botStatus];
    end
    
    if enemyStatus ~= -1 then
      _enemyVal = EnemyHealthProb[enemyStatus];
    end
    
    if inRangeofEnemyTower then
      _towerVal = DistanceEnemyTowerProb[1];
    else
      _towerVal = DistanceEnemyTowerProb[2];
    end
    
    local y = 1;
    local enemyStatusAux = 1;
    local probValues = {};
    local probValuesBotVal = {};
    local probValuesEnemyVal = {};
    local probValuesTowerVal = {};
    local probValuesMinionVal = {};
    
-- Using the mapping matrix we get the probabilities of every posible outcome and store tem in 4 different arrays P(A,BH,EH,DT)
    for x = 1, 36 do
      if mappingMatrix[x][1] == botStatus or botStatus == -1 then
        if mappingMatrix[x][2] == botStatus or enemyStatus == -1 then
          if (mappingMatrix[x][3] == 1 and moreAllyCreeps) or (mappingMatrix[x][3] == 0 and not moreAllyCreeps) then
            if (mappingMatrix[x][4] == 1 and inRangeofEnemyTower) or (mappingMatrix[x][4] == 0 and not inRangeofEnemyTower) then
              probValues[y] = PushProb[x][1];
              probValuesBotVal[y] = _botVal;
              
              if enemyStatus == -1 then 
                probValuesEnemyVal[y] = EnemyHealthProb[enemyStatusAux];
                enemyStatusAux = enemyStatusAux + 1;
                if enemyStatusAux > 3 then
                  enemyStatusAux = 1;
                end
              else
                probValuesEnemyVal[y] = _enemyVal;
              end
              
              probValuesTowerVal[y] = _towerVal;
              
              probValuesMinionVal[y] = _minionsVal;
              
              y = y+1;
              
            end
          end
        end
      end
    end
    
-- We then calculate the probabilities of the outcome given the results
    if y < 3 then
      pushdesire = probValues[1];
    else
      for x = 1,(y-1) do
        local prob = probValues[x] * probValuesBotVal[x] * probValuesEnemyVal[x] * probValuesMinionVal[x] * probValuesTowerVal[x];
        --print(probValues[x].." * "..probValuesBotVal[x].." * "..probValuesEnemyVal[x].." * "..probValuesTowerVal[x].." * "..probValuesMinionVal[x].." = "..prob);
        pushdesire = pushdesire + prob;
      end
      --print("= "..pushdesire);
    end
    
    return pushdesire;
end


return Idea;