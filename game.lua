--= Game API =--



--os.loadAPI("rom/game/core")

function getTurn()
  return tonumber(core.turn)
end


location = core.location
location.get = function(loc)
  if type(loc) ~= "table" or (loc.xloc == nil or loc.zloc == nil) then
    return nil,"invalid location"
  end
  
  return loc.xloc,loc.zloc
end


arena = {}
function arena.getw()
  return core.arena.w
end
function arena.geth()
  return core.arena.w
end
arena.isInPerimiter = core.arena.isInPerimiter
arena = table.protect(arena)


function getPlayer(name)
  for i=1,#core.getPlayers() do
    if core.getPlayers()[i].name == name then
	  return table.copy(core.getPlayers()[i])
	end
  end
  
  return false,"cannot get player: no player named "..name..""
end
function getActivePlayer()
  local ap = core.activePlayer
  if ap ~= nil then
    return ap
  end
  return false,"cannot get player: no active player"
end

function getAllPlayers()
  return core.getPlayers()
end
function getActivePlayers()
  local activePlayers = {}
  for i=1,#core.getPlayers() do -- count active players
	if core.getPlayers()[i].isActive then
	  table.insert(activePlayers,core.getPlayers()[i])
	end
  end
  
  if not table.isEmpty(activePlayers) then
    return activePlayers
  end
  return {},"cannot get players: no players active"
end

function activePlayersCount()
  return #getActivePlayers()
end


function getAllPirates()
  return core.getPirates()
end
function getMyPirates()
  local my = {}
  for i=0,core.pirate.lastPirateID do
    if core.getPirates()[i] then
	  if core.getPirates()[i].owner == getActivePlayer().name then
	    table.insert(my,core.getPirates()[i])
	  end
	end
  end
  
  if not table.isEmpty(my) then
    return my
  end
  return nil,"cannot get pirates: you dont own any pirates"
end
function getMySoberPirates()
  local soberPirates = {}
  for i,p in pairs(game.getMyPirates()) do
    if p then
	  if p.drunkTime < 1 then
	    table.insert(soberPirates,p)
	  end
	end
  end
  return soberPirates
end
function getPirate(p1,p2)
  if p1 == nil then
    return false,"cannot get pirate: no pirate specified"
  end

  local xloc
  local zloc
  local id
  local p
  
  if p2 == nil then -- assume p1 is pirate id
    id = p1
  else -- assume p1,p2 are pirate loc
    xloc = p1
	zloc = p2
  end
  
  for i=0,#core.pirate do
    p = core.getPirates()[i]
    if id == nil then
      if p.xloc == xloc and p.zloc == zloc then
	    return table.copy(p)
	  end
    elseif p.id == id then
	  return table.copy(p)
    end
  end
  
  return false,"cannot get pirate: no pirate matches the data"
end


pirate = {}
function pirate.deffend(ID)
  if core.pirates[ID] == nil then
    return false,"cannot deffend pirate: invalid pirate"
  end
  if core.pirates[ID].owner ~= core.getActivePlayer().name then
    return false,"cannot deffend pirate: you do not own this pirate"
  end
  
  core.pirates[ID].vulnerableTime = 0
  return true
end
function pirate.attack(atkrID,trgtID)
  if core.pirates[atkrID] == nil then
    return false,"attack failed: not a valid attacker"
  end
  if core.pirates[trgtID] == nil then
    return false,"attack failed: not a valid target"
  end
  
  if core.pirates[atkrID].owner ~= core.getActivePlayer().name then
    return false,"attack failed: you do not own the attacker"
  end
  if core.pirates[trgtID].owner == core.getActivePlayer().name then
    return false,"attack failed: you cannot attack yourself"
  end
  
  power = constants.FirePower
  
  if core.pirate[atkrID].attackCooldowm > 0 then
    return false,"attack failed: must wait "..core.pirate[atkrID].attackCooldowm.." turns until next attack"
  else
    io.write("Pirate #")
	io.write(atkrID,colors.info)
	io.write(" attacked Pirate #")
	io.write(trgtID,colors.info)
	io.write("- ")
    core.pirate[atkrID].attackCooldowm = constants.AttackCooldowm
  end
  
  core.moves.attack.queue(atkrID,trgtID,power)
  
  return true
end


function getTreasures()
  return table.copy(core.treasures)
end

function getDistance(loc1,loc2)
  if type(loc1) ~= "table"
  or type(loc2) ~= "table"
  then
    return -1,"cannot calculate distance: not valid locations"
  end
  if type(loc1.xloc) ~= "number" or type(loc1.zloc) ~= "number"
  or type(loc2.xloc) ~= "number" or type(loc2.zloc) ~= "number"
  then
    return -1,"cannot calculate distance: not valid locations"
  end
  
  local dist = 0
  
  if loc1.xloc == loc2.xloc and loc1.zloc == loc2.zloc then
    return 0
  end
  
  for x=math.abs(loc1.xloc),math.abs(loc2.xloc) do
    dist = dist + 1
  end
  for z=math.abs(loc1.zloc),math.abs(loc2.zloc) do
    dist = dist + 1
  end
  
  return dist
end

function getSailOptions(startPos,endPos,r,path,paths)
  if type(startPos) ~= "table" or startPos.xloc == nil or startPos.zloc == nil then
    return nil,"no sail options: not a valid start position"
  end
  if type(endPos) ~= "table" or endPos.xloc == nil or endPos.zloc == nil then
    return nil,"no sail options: not a valid end position"
  end
  if r == nil then
    return nil,"no sail options: must enter radius"
  end
  
  if path == nil then
    path = {}
  end
  if paths == nil then
    paths = {}
  end
  
  io.writeDebug('path',"s: ["..startPos.xloc..","..startPos.zloc.."] ".."e: ["..endPos.xloc..","..endPos.zloc.."]\n",colors.info)
  
  -- path end exit point
  if (startPos.xloc == endPos.xloc) and (startPos.zloc == endPos.zloc) then
    table.insert(paths,path)
	return paths
  end
  -- radius limit exit point
  if r < 1 then
    table.insert(paths,path)
    return nil,"no sail options: radius must be at least 1"
  end
  
  local xInc,zInc
  if startPos.xloc < endPos.xloc then
    -- X+ left
	xInc = 1
  elseif startPos.xloc < endPos.xloc then
    -- X- right
	xInc = -1
  else
    xInc = 0
  end
  if startPos.zloc < endPos.zloc then
    -- Z+ left
	zInc = 1
  elseif startPos.zloc < endPos.zloc then
    -- Z- right
	zInc = -1
  else
    zInc = 0
  end
  
  io.writeDebug('path',xInc..","..zInc.."\n",colors.cyan)
  
  local x,z = startPos.xloc,startPos.zloc
  local plen = table.getn()
  path = table.copy(path)
  local path2 = table.copy(path)
  
  io.writeDebug('path',"Z:"..z.." ",colors.orange)
  -- add z directions
  if zInc > 0 then
	io.writeDebug('path',"[up]\n",colors.path)
	table.insert(path,"up")
	getSailOptions({xloc = startPos.xloc,zloc = z+1},endPos,r-1,path,paths)
  elseif zInc < 0 then
	io.writeDebug('path',"[down]\n",colors.path)
	table.insert(path,"down")
	getSailOptions({xloc = startPos.xloc,zloc = z-1},endPos,r-1,path,paths)
  end
  
  io.writeDebug('path',"X:"..x.."\n",colors.orange)
  -- add x directions
  if xInc > 0 then
	io.writeDebug('path',"[left]\n",colors.path)
	table.insert(path2,"left")
	getSailOptions({xloc = x+1,zloc = startPos.zloc},endPos,r-1,path2,paths)
  elseif xInc < 0 then
	io.writeDebug('path',"[right]\n",colors.path)
	table.insert(path2,"right")
	getSailOptions({xloc = x-1,zloc = startPos.zloc},endPos,r-1,path2,paths)
  end
  
  return paths
end
function setSail(pirateID,path)
  if type(path) ~= "table" then
    return false,"invalid path: expected table, got "..tostring(type(path))..""
  end
  
  local p,err = core.pirate.find(pirateID)
  if not p then return false,err end
  
  if p.owner ~= getActivePlayer().name then
    return false,"cannot sail: you do not own this pirate"
  end
  
  if p.drunkTime > 0 then return false,"cannot sail: pirate #"..pirateID.." is drunk" end
  
  local des,err = location.new(p.xloc,p.zloc)
  if des == nil then return false,err end
  
  local steps = 0
  for _,a in ipairs(path) do
    if a == "up" then
      des.zloc = des.zloc + 1
    elseif a == "right" then
      des.xloc = des.xloc - 1
    elseif a == "down" then
      des.zloc = des.zloc - 1
    elseif a == "left" then
      des.xloc = des.xloc + 1
	else
	  return false,"invalid path: direction '"..a.."' is not a valid direction"
	end
	steps = steps + 1
  end
  
  local s,err = arena.isInPerimiter(des)
  if not s then
    return false,"invalid path: final location out of arena ("..err..")"
  end
  if steps > core.getPlayer(p.owner).moves then
    return false,"cannot sail: needs "..steps.." moves, has "..core.getPlayer(p.owner).moves..""
  end
  core.getPlayer(p.owner).moves = core.getPlayer(p.owner).moves - steps
  
  --= Queue Sailing =--
  
  core.moves.sail.queue(pirateID,path)
  
  --[[
  1.queue sailing
  2.run core.doSails(sailQueue) at the end of the player AI loop:
    >handle collisions:
	  >save collision point & crashing pirates
	  >remove collision point from colliding pirates' path
	  >run later:
	    >pirate.remove(crashed_pirates) [for loop]
	    >print text
	    >if core.isVis then -- DO EXPLOSION PARTICLES -- end
	>run all in parrallel [parrallel.waitForAll(dequeue1,dequeue2,...)]
  --]]

  return true
end


function name(short)
  if short == nil then
    short = false
  end

  if short then
    io.write("TCCAIC",colors.name,nil,true)
  else
    io.write("The Computer Craft AI Challenge",colors.name,nil,true)
  end
end
function getName(short)
  if short == nil then
    short = false
  end
  
  if short then
    return "TCCAIC"
  else
    return "The Computer Craft AI Challenge"
  end
end