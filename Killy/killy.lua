----------------------------------------
-- GLOBALS
----------------------------------------

-- queue containing the updates that need to be applied to the minecraft world
UpdateQueue = nil
-- array of container objects
Containers = {}
--
SignsToUpdate = {}
-- as a lua array cannot contain nil values, we store references to this object
-- in the "Containers" array to indicate that there is no container at an index
EmptyContainerSpace = {}

----------------------------------------
-- FUNCTIONS
----------------------------------------

-- Tick is triggered by cPluginManager.HOOK_TICK
function Tick(TimeDelta)
  UpdateQueue:update(MAX_BLOCK_UPDATE_PER_TICK)
end

-- Plugin initialization
function Initialize(Plugin)
  Plugin:SetName("Killy")
  Plugin:SetVersion(1)

  UpdateQueue = NewUpdateQueue()

  -- Hooks

  cPluginManager:AddHook(cPluginManager.HOOK_PLAYER_JOINED, PlayerJoined);
  cPluginManager:AddHook(cPluginManager.HOOK_PLAYER_USING_BLOCK, PlayerUsingBlock);
  cPluginManager:AddHook(cPluginManager.HOOK_PLAYER_FOOD_LEVEL_CHANGE, OnPlayerFoodLevelChange);
  cPluginManager:AddHook(cPluginManager.HOOK_TAKE_DAMAGE, OnTakeDamage);
  cPluginManager:AddHook(cPluginManager.HOOK_WEATHER_CHANGING, OnWeatherChanging);
  cPluginManager:AddHook(cPluginManager.HOOK_SERVER_PING, OnServerPing);
  cPluginManager:AddHook(cPluginManager.HOOK_TICK, Tick);

  -- Command Bindings

  -- TODO
  cPluginManager.BindCommand("/killy", "*", KillyCommand, " - docker CLI commands")

  -- make all players admin
  cRankManager:SetDefaultRank("Admin")

  cNetwork:Connect("127.0.0.1",25566,TCP_CLIENT)

  LOG("Initialised " .. Plugin:GetName() .. " v." .. Plugin:GetVersion())

  return true
end

-- updateStats update CPU and memory usage displayed
-- on container sign (container identified by id)
-- function updateStats(id, mem, cpu)
--   for i=1, table.getn(Containers)
--   do
--     if Containers[i] ~= EmptyContainerSpace and Containers[i].id == id
--     then
--       Containers[i]:updateMemSign(mem)
--       Containers[i]:updateCPUSign(cpu)
--       break
--     end
--   end
-- end

-- getStartStopLeverContainer returns the container
-- id that corresponds to lever at x,y coordinates
function getStartStopLeverContainer(x, z)
  for i=1, table.getn(Containers)
  do
    if Containers[i] ~= EmptyContainerSpace and x == Containers[i].x + 1 and z == Containers[i].z + 1
    then
      return Containers[i].id
    end
  end
  return ""
end

-- getRemoveButtonContainer returns the container
-- id and state for the button at x,y coordinates
function getRemoveButtonContainer(x, z)
  for i=1, table.getn(Containers)
  do
    if Containers[i] ~= EmptyContainerSpace and x == Containers[i].x + 2 and z == Containers[i].z + 3
    then
      return Containers[i].id, Containers[i].running
    end
  end
  return "", true
end

--
function PlayerJoined(Player)
  -- enable flying
  Player:SetCanFly(true)
  LOG("player joined")
  -- updateTableRecordContainer(1,"?", "??")
  -- updateTableRecordContainer(2,"!", "!!")
  -- updateActiveInstanceContainer(1,"??",true)
  -- updateActiveInstanceContainer(2,"!!",true)
end

--
function PlayerUsingBlock(Player, BlockX, BlockY, BlockZ, BlockFace, CursorX, CursorY, CursorZ, BlockType, BlockMeta)
  LOG("Using block: " .. tostring(BlockX) .. "," .. tostring(BlockY) .. "," .. tostring(BlockZ) .. " - " .. tostring(BlockType) .. " - " .. tostring(BlockMeta))

  -- lever: 1->OFF 9->ON (in that orientation)
  -- lever
  if BlockType == 69
  then
    local containerID = getStartStopLeverContainer(BlockX,BlockZ)
    LOG("Using lever associated with container ID: " .. containerID)

    if containerID ~= ""
    then
      -- stop
      if BlockMeta == 1
      then
        Player:SendMessage("docker stop " .. string.sub(containerID,1,8))
        SendTCPMessage("docker",{"stop",containerID},0)
        -- start
      else
        Player:SendMessage("docker start " .. string.sub(containerID,1,8))
        SendTCPMessage("docker",{"start",containerID},0)
      end
    else
      LOG("WARNING: no docker container ID attached to this lever")
    end
  end

  -- stone button
  if BlockType == 77
  then
    local containerID, running = getRemoveButtonContainer(BlockX,BlockZ)

    if running
    then
      Player:SendMessage("A running container can't be removed.")
    else
      Player:SendMessage("docker rm " .. string.sub(containerID,1,8))
      SendTCPMessage("docker",{"rm",containerID},0)
    end
  end
end

function OnPlayerFoodLevelChange(Player, NewFoodLevel)
  -- Don't allow the player to get hungry
  return true, Player, NewFoodLevel
end

function OnTakeDamage(Receiver, TDI)
  -- Don't allow the player to take falling or explosion damage
  if Receiver:GetClass() == 'cPlayer'
  then
    if TDI.DamageType == dtFall or TDI.DamageType == dtExplosion then
      return true, Receiver, TDI
    end
  end
  return false, Receiver, TDI
end

function OnServerPing(ClientHandle, ServerDescription, OnlinePlayers, MaxPlayers, Favicon)
  -- Change Server Description
  local serverDescription = "A Docker client for Minecraft"
  -- Change favicon
  if cFile:IsFile("/srv/logo.png") then
    local FaviconData = cFile:ReadWholeFile("/srv/logo.png")
    if (FaviconData ~= "") and (FaviconData ~= nil) then
      Favicon = Base64Encode(FaviconData)
    end
  end
  return false, serverDescription, OnlinePlayers, MaxPlayers, Favicon
end

-- Make it sunny all the time!
function OnWeatherChanging(World, Weather)
  return true, wSunny
end

