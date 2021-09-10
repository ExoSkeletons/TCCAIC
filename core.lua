--= Core =--



dofile("game/utils")

w,h = term.getSize()

local type = type
local clearLine = term.clearLine

print = function(par,fgc,bgc)
  io.write(par,fgc,bgc)
  io.write("\n")
end

-- structures
local structures = {}
structures['location'] = {
  xloc = "number",
  zloc = "number",
}
structures['treasure'] = {
  value = "number",
}
structures['pirate'] = {
  drunkTime = "number",
  attackCooldown = "number",
  vulnerableTime = "number",
  treasure = "table",
  sxloc = "number",
  szloc = "number",
  owner = "string",
}
isStruct = function(par,t)
  local eq = true
  local exi,exv = nil
  if type(par) == "table" and structures[t] then
	for i,eltype in pairs(structures[t]) do
      --[[
	  io.write("["..i.."]: ")
      io.write(type(par[i]),colors.brown)
      io.write(" =?= ")
      io.write(eltype.."\n",colors.brown)
	  --]]
	  if not isStruct(par[i],eltype) then
		eq = false
		exi,exv = i,eltype
		break
	  end
	end
  else
    eq = (type(par) == t)
  end
  return eq,exi,exv
end
-- inheritances
for el,eltype in pairs(structures['location']) do
  structures['treasure'][el] = eltype
  structures['pirate'][el] = eltype
end

turn = -1
function initTurn()
  turn = 0
end

speedFactor = .1f

isPaused = false

buttons = {}
function addButton(button)
  if type(button) ~= "table" then
    return false
  end
  
  if button.txt == nil then button.txt = "" end
  if button.len == nil then button.len = 1 end
  if button.org == nil then button.org = 0 end
  if button.action == nil then button.action = function()
      -- Do Nothing
    end
  end
  if button.show == nil then button.show = function()
      return true
	end
  end
  
  table.insert(buttons,button)
  
  return true
end
function clearButtons()
  buttons = nil
  buttons = {}
end

function errMsg(err)
  err = string.stt(err)
  err = table.cut(err,2)
  err = table.tts(err)
  return err
end

objectives = {}
function objectives.get()
  local success,tRes = commands.scoreboard("objectives list")
  for i=2,#tRes do
    tRes[i] = string.clean(tRes[i])
	tRes[i] = string.sub(tRes[i],2,string.find(tRes[i],":")-1)
	tRes[i-1] = tRes[i]
	tRes[i] = nil
  end
  
  return tRes
end
function objectives.exists(name)
  local list = objectives.get()
  for i=1,#list do
    if list[i] == name then
	  --[[
      print(list[i],colors.success)
      print(name,colors.action)
	  --]]
	  return true
	end
  end
  return false
end
function objectives.setup()
  io.writeDebug("scoreboard","Setting up Scoreboard Objectives ... ")
  
  if not objectives.exists(constants.TValueObjective) then
    commands.exec("scoreboard objectives add "..constants.TValueObjective.." dummy",true)
  end
  if not objectives.exists(constants.ScoreObjective) then
    commands.exec("scoreboard objectives add "..constants.ScoreObjective.." dummy",true)
  end
  
  io.writeDebug('scoreboard',"Done.\n\n",colors.success)
end
function objectives.remove(name)
  if objectives.exists(name) then
    commands.scoreboard("objectives remove "..name)
  end
end
function objectives.removeAll()
  io.writeDebug('scoreboard',"Removing Scoreboard Objectives... ")
  
  objectives.remove(constants.TValueObjective)
  objectives.remove(constants.ScoreObjective)
  
  io.writeDebug('scoreboard',"Done.\n",colors.success)
end
objectives.setup()

location = {
  new = function(xloc,zloc)
    if xloc == nil then
      return {},"Incorrect location: xloc is nil"
    end
    if zloc == nil then
      return {},"Incorrect location: zloc is nil"
    end
    
    loc = {}
    loc.xloc = xloc
    loc.zloc = zloc
    
    return loc
  end
}

arena = {}
arena.w = 0
arena.h = 0

arena.isInPerimiter = function(loc)
  if (loc.xloc < 0 or loc.xloc > arena.w) then
    return false,"X limits are 0-"..arena.w
  end
  if (loc.zloc < 0 or loc.zloc > arena.h) then
    return false,"Z limits are 0-"..arena.h
  end
  return true
end

arena.border = {}
arena.border.w = function()
  return 1 + arena.w + 1
end
arena.border.h = function()
  return 1 + arena.h + 1
end
arena.border.block = {
  name = "minecraft:sea_lantern",
  val = 0
}

arena.resize = function(w,h,doRem)
  if w-1 == arena.w and h-1 == arena.h then
    return true
  end

  local res = constants.SUCCESS
  
  io.writeDebug('arena',"Setting arena size to (")
  io.writeDebug('arena',w,colors.info)
  io.writeDebug('arena',"*")
  io.writeDebug('arena',h,colors.info)
  io.writeDebug('arena',") ... ")
  
  if doRem ~= false then
    local prev = os.DIT['arena']
    os.DIT['arena'] = constants.HIDE
    res = res and arena.remove()
    os.DIT['arena'] = prev
  end
  
  arena.w = w-1
  arena.h = h-1
  
  commands.gamerule("doTileDrops",false)
  commands.exec("execute @e[type=ArmorStand,name="..constants.ArenaMarkerName.."] ~ ~ ~ /fill ~0 ~0 ~0 ~"..arena.border.w().." ~ ~ "..arena.border.block.name.." "..arena.border.block.val.." destroy")
  commands.exec("execute @e[type=ArmorStand,name="..constants.ArenaMarkerName.."] ~ ~ ~ /fill ~0 ~0 ~0 ~ ~ ~"..arena.border.h().." "..arena.border.block.name.." "..arena.border.block.val.." destroy")
  commands.exec("execute @e[type=ArmorStand,name="..constants.ArenaMarkerName.."] ~ ~ ~ /fill ~"..arena.border.w().." ~ ~"..arena.border.h().." ~"..arena.border.w().." ~ ~ "..arena.border.block.name.." "..arena.border.block.val.." destroy")
  commands.exec("execute @e[type=ArmorStand,name="..constants.ArenaMarkerName.."] ~ ~ ~ /fill ~"..arena.border.w().." ~ ~"..arena.border.h().." ~ ~ ~"..arena.border.h().." "..arena.border.block.name.." "..arena.border.block.val.." destroy")
  commands.gamerule("doTileDrops",true)

  
  if pirates then
    for i=0,pirate.lastPirateID+1 do
      if pirates[i] then
        if pirates[i].xloc - 1 > nwidth or pirates[i].zloc - 1 > nhight then
		  prev = os.DIT['pirates']
		  os.DIT['pirates'] = constants.HIDE
	      pirate.remove(i)
		  os.DIT['pirates'] = prev
	    end
	  end
    end
  end
  if treasures then
    for _,t in pairs(treasures) do
      if t.xloc - 1 > arena.w or t.zloc - 1 > arena.h then
		prev = os.DIT['treasures']
		os.DIT['treasures'] = constants.HIDE
	    treasure.remove(t.xloc,t.zloc)
		os.DIT['treasures'] = prev
	  end
    end
  end
  
  io.writeDebug('arena',"Done.\n",colors.success)
  return res
end
function arena.setup(w,h)
  commands.exec("summon ArmorStand ~ "..constants.SeaLevel.." ~10 {"..constants.MarkerTags.."CustomName:\""..constants.ArenaMarkerName.."\"}")
  arena.resize(w,h,false)
end
function arena.remove()
  io.writeDebug('arena',"Removing Arena... ")
  
  commands.gamerule("doTileDrops",false)
  commands.exec("execute @e[type=ArmorStand,name="..constants.ArenaMarkerName.."] ~ ~ ~ /fill ~ ~ ~ ~"..arena.border.w().." ~ ~ minecraft:water 0 destroy")
  commands.exec("execute @e[type=ArmorStand,name="..constants.ArenaMarkerName.."] ~ ~ ~ /fill ~ ~ ~ ~ ~ ~"..arena.border.h().." minecraft:water 0 destroy")
  commands.exec("execute @e[type=ArmorStand,name="..constants.ArenaMarkerName.."] ~ ~ ~ /fill ~"..arena.border.w().." ~ ~"..arena.border.h().." ~"..arena.border.w().." ~ ~ minecraft:water 0 destroy")
  commands.exec("execute @e[type=ArmorStand,name="..constants.ArenaMarkerName.."] ~ ~ ~ /fill ~"..arena.border.w().." ~ ~"..arena.border.h().." ~ ~ ~"..arena.border.h().." minecraft:water 0 destroy")
  commands.gamerule("doTileDrops",true)

  
  io.writeDebug('arena',"Done.\n",colors.success)
end
function arena.kill()
  arena.remove()
  commands.exec("kill @e[type=ArmorStand,name="..constants.ArenaMarkerName.."]")
end


treasures = {}
treasure = {}
function treasure.create(xloc,zloc,value)
  commands.exec("execute @e[type=ArmorStand,name="..constants.ArenaMarkerName.."] ~1 ~ ~1 summon ArmorStand ~"..xloc.." ~ ~"..zloc.." {"..constants.MarkerTags.."CustomName:\""..constants.TreasureMarkerName.."\",Equipment:"..constants.TreasureEquipment.."}")
end
function treasure.add(par)
  local t = table.copy(constants.Defualts.treasure)
  for i,_ in pairs(par) do
    t[i] = par[i]
  end
  
  io.writeDebug('treasures',"Adding Treasure at [")
  io.writeDebug('treasures',t.xloc,colors.info)
  io.writeDebug('treasures',",")
  io.writeDebug('treasures',t.zloc,colors.info)
  io.writeDebug('treasures',"] with value: ")
  io.writeDebug('treasures',t.value,colors.value)
  io.writeDebug('treasures'," ... ")
  
  if not isStruct(t,"treasure") then
    error("Incorrect Treasure data ["..tostring(par.xloc)..","..tostring(par.xloc)..","..tostring(par.value).."]\n")
  end
  
  t.getLoc = function(self)
    return location.new(self.xloc,self.zloc)
  end
  
  if t.xloc < 0 or arena.w < t.xloc
  or t.zloc < 0 or arena.h < t.zloc then
    error("Cannot create Treasure outside of arena",0)
  end
  
  if os.isVis then
    treasure.create(t.xloc,t.zloc,t.value)
  end
  
  table.insert(treasures,t)
  
  io.writeDebug('treasures',"Done.\n",colors.success)
  return true
end
function treasure.remove(xloc,zloc)
  local hasKilled = false
  for i,t in pairs(treasures) do
    if t.xloc == xloc and t.zloc == zloc then
	  io.writeDebug('treasures',"Removing Treasure in location [")
	  io.writeDebug('treasures',xloc,colors.info)
	  io.writeDebug('treasures',",")
	  io.writeDebug('treasures',zloc,colors.info)
	  io.writeDebug('treasures',"] ... ")
	  table.remove(treasures,i)
	  hasKilled = true
	end
  end
  
  if hasKilled == false then
    error("No treasure at ["..xloc","..zloc.."].")
  else
	io.writeDebug('treasures',"Done.\n",colors.success)
  end
  
  if os.isVis then
    commands.exec("execute @e[type=ArmorStand,name="..constants.ArenaMarkerName.."] ~"..(1+xloc).." ~ ~"..(1+zloc).." kill @e[type=ArmorStand,name="..constants.TreasureMarkerName..",r=1]")
  end
  
  return true
end
function treasure.removeAll()
  io.writeDebug('treasures',"Removing all Treasures ... ")
  treasures = {}
  
  if not (pirates == nil or table.isEmpty(pirates)) then
    local p
    for i,p in ipairs(pirates) do
	  if isStruct(p.treasure,"treasure") then
        p.treasure.value = 0
        p.treasure.xloc = nil
        p.treasure.zloc = nil
	  end
	end
  end
  
  if commands.testfor("@e[type=ArmorStand,name="..constants.TreasureMarkerName.."]") then
    commands.exec("kill @e[type=ArmorStand,name="..constants.TreasureMarkerName.."]")
  end
  
  io.writeDebug('treasures',"Done.\n",colors.success)
  return true
end


pirates = {}
function getPirates()
  return table.copy(pirates)
end
pirate = {}
pirate.lastPirateID = 0
function pirate.find(pirateID)
  if type(pirateID) ~= "number" then
    return nil,"cannot find pirate: expected number, got "..type(pirateID)
  end
  
  for id,p in ipairs(pirates) do
    if id == pirateID then
	  return p
	end
  end
  
  return nil,"cannot find pirate: no pirate with ID "..pirateID
end
function pirate.send(pirateID,msg,prtcl)
  p = pirate.find(pirateID)
  if p == nil then
    print("No such pirate with ID "..pirateID,colors.error)
  end
  
  if msg then msg = pirateID.." "..msg
  else return
  end
  
  rednet.broadcast(msg,prtcl)
end
function pirate.create(p)
  local turtleData = ""
  if p.drunkTime > 0 then
    turtleData = constants.TurtleData.Drunk
  end
  if table.isEmpty(p.treasure) then
    turtleData = constants.TurtleData.Normal
  elseif isStruct(p.treasure,"treasure") then
    turtleData = constants.TurtleData.HasTreasure
  else
    turtleData = constants.TurtleData.Normal
  end
  
  commands.gamerule("doTileDrops",false)
  commands.exec("execute @e[type=ArmorStand,name="..constants.ArenaMarkerName.."] ~1 ~ ~1 setblock ~"..p.xloc.." ~1 ~"..p.zloc.." "..turtleData)
  commands.gamerule("doTileDrops",true)
  
  sleep(.01)
  
  rednet.broadcast(p.id,"setID")
  rednet.broadcast(p.owner,"setOwner")
  rednet.broadcast(p.xloc,"setXLoc")
  rednet.broadcast(p.zloc,"setZLoc")
end
function pirate.add(par)
  local p = table.copy(constants.Defualts.pirate)
  
  for i,_ in pairs(par) do
    p[i] = par[i]
  end
  
  p.getLoc = function(self)
    return location.new(self.xloc,self.zloc)
  end
  p.sxloc = p.xloc
  p.szloc = p.zloc
  
  --io.write("\n")
  --table.print(p)
  
  if p.id == nil then
    p.id = pirate.lastPirateID
	pirate.lastPirateID = pirate.lastPirateID + 1
  elseif p.id > pirate.lastPirateID then
    pirate.lastPirateID = p.id + 1
  end
  
  io.writeDebug('pirates',"Adding Pirate at [")
  io.writeDebug('pirates',p.xloc,colors.info)
  io.writeDebug('pirates',",")
  io.writeDebug('pirates',p.zloc,colors.info)
  io.writeDebug('pirates',"] with owner: ")
  io.writeDebug('pirates',p.owner,colors.name)
  io.writeDebug('pirates'," ... ")
  
  local s,ei,ev = isStruct(p,"pirate")
  if not s then
    error("Incorrect pirate data: ["..ei.."]="..tostring(p[ei])..", expected "..ev)
  end
  
  if p.xloc < 0 or arena.w < p.xloc
  or p.zloc < 0 or arena.h < p.zloc then
    error("Cannot create Pirate outside arena")
  end
  
  local occupied = false
  for i=0,pirate.lastPirateID do
    if pirates[i] then
      if p.xloc == pirates[i].xloc and p.zloc == pirates[i].zloc then
	    occupied = true
		break
	  end
	end
  end
  if occupied then
    error("Space ["..p.xloc..","..p.zloc.."] already occupied!",colors.error)
  end
  
  pirates[p.id] = p
  
  if os.isVis then
    pirate.create(p)
  end
  
  io.writeDebug('pirates',"Done.\n",colors.success)
  
  return pirates[p.id]
end
function pirate.remove(p1,p2)
  local xloc
  local zloc
  local id
  
  local res
  
  if p2 == nil then -- assume p1 is pirate id
    id = p1
	io.writeDebug('pirates',"Removing Pirate with ID #")
	io.writeDebug('pirates',id,colors.info)
	io.writeDebug('pirates'," ... ")
  else -- assume p1,p2 are pirate xloc,zloc
    xloc = p1
	zloc = p2
	io.writeDebug('pirates',"Removing Pirate at location [")
	io.writeDebug('pirates',xloc,colors.info)
	io.writeDebug('pirates',",")
	io.writeDebug('pirates',zloc,colors.info)
	io.writeDebug('pirates',"] ... ")
	
	local p
	for i=0,pirate.lastPirateID do
	  if pirates[i] then
	    if pirates[i].xloc == xloc and pirates[i].zloc == zloc then
		  p = pirates[i]
		  break
		end
	  end
	end
	
	local prev = os.DIT[pirates]
	os.DIT['pirates'] = constants.HIDE
	res = pirate.remove(p.id)
	os.DIT['pirates'] = prev
	
	return res
  end
  
  if pirates[id] == nil then
    error("No pirates with ID #"..id)
  end
  
  if os.isVis then
    --commands.gamerule("doTileDrops",false)
	local s,tRes = commands.exec("execute @e[type=ArmorStand,name="..constants.ArenaMarkerName.."] ~1 ~ ~1 testforblock ~"..pirates[id].xloc.." ~1 ~"..pirates[id].zloc.." air",false)
    
    --[[
	io.write(tostring(s)..": ",colors.brown)
    print(table.unpack(tRes),colors.brown)
	--]]
	
	if not s then
	  sleep(.05)
	  commands.exec("execute @e[type=ArmorStand,name="..constants.ArenaMarkerName.."] ~1 ~ ~1 setblock ~"..pirates[id].xloc.." ~1 ~"..pirates[id].zloc.." air 0 replace ",false)
    end
	--commands.gamerule("doTileDrops",true)
  end
  
  if isStruct(pirates[id].treasure,"treasure") then
  	if pirates[id].treasure.xloc ~= nil and pirates[id].treasure.zloc ~= nil then
	  local prev = DIT['treasures']
	  os.DIT['treasures'] = constants.HIDE
	  treasure.add(pirates[id].treasure.xloc,pirates[id].treasure.zloc,pirates[id].treasure.value)
	  os.DIT['treasures'] = prev
	end
  end
  
  pirates[id] = nil
  
  io.writeDebug('pirates',"Done.\n",colors.success)
  
  return true
end
function pirate.removeAll()
  io.writeDebug('pirates',"Removing all Pirates... ")
  
  local prev = os.DIT['pirates']
  os.DIT['pirates'] = constants.HIDE
  for i=0,pirate.lastPirateID do
    if pirates[i] then
	  pirate.remove(i)
	end
  end
  os.DIT['pirates'] = prev
  
  io.writeDebug('pirates',"Done.\n",colors.success)
  return true
end

function getCollisionPoints()
  return table.copy(moves.sail.moves.sail.collisions)
end

moves = {
  sail = {
    paths = {},
    collisions = {},
    queue = function(pirateID,path)
      io.writeDebug('sail',"queued to pirate #",colors.pink)
      io.writeDebug('sail',pirateID.."\n",colors.info)
      moves.sail.paths[pirateID] = path
	end,
	dequeue = function()
      if table.isEmpty(moves.sail.paths) then
        return true
      end
      
      -- store pirate's future location while/after sailing
      local fpirates = table.copy(pirates)
      -- remove non moving pirates
      for i,fp in ipairs(fpirates) do
        if moves.sail.paths[i] == nil then
	      fpirates[i] = nil
	    end
      end
      -- store path
      local path = {}
      
      if not os.DIT['sail'] and os.isVis then io.write("animating pirates...",colors.lightGray) end
      
      -- simulate movement:
	  -- iterate over each move
      for i=1,constants.MAXMOVES do
	    io.writeDebug('sail',"Turn #"..i.."\n",colors.info)
        -- calculate pirate's next location
        for _,fp in pairs(fpirates) do
	      path = moves.sail.paths[fp.id]
	      if #path < i then -- path ended before current turn
	        break
	      end
	      
	      io.writeDebug('sail',"fpirate #",colors.lightGray)
	      io.writeDebug('sail',fp.id,colors.green)
	      io.writeDebug('sail',": ",colors.lightGray)
	      for a=1,#path do
            io.writeDebug('sail',tostring(path[a]).." ",colors.path)
	      end
	      io.writeDebug('sail',"\n")
	  
	      if path[i] == "up" then
		    fp.zloc = fp.zloc + 1
	      elseif path[i] == "down" then
		    fp.zloc = fp.zloc - 1
	      elseif path[i] == "right" then
	    	fp.xloc = fp.xloc - 1
	      elseif path[i] == "left" then
	    	fp.xloc = fp.xloc + 1
	      else
	    	error("incorrect path data: pirate #"..fp.id.."'s path["..i.."] = "..tostring(path[i]))
	      end
	    end
	    
        io.writeDebug('sail',"looking for collisions\n")
	    -- check for overlapping locations, and add them to collisions
        for _,fp1 in pairs(fpirates) do
          for _,fp2 in pairs(fpirates) do
	    	if fp1.id ~= fp2.id
	    	and fp1.xloc == fp2.xloc
	    	and fp1.zloc == fp2.zloc
	    	then
	    	  -- add collision point
	    	  table.insert(moves.sail.collisions,{fp1.xloc,fp1.zloc})
              io.writeDebug('sail',"collision at ["..fp1.xloc..","..fp1.zloc.."]\n",colors.lightGray)
	    	  -- end path *at* collision point (needed for later)
	    	  moves.sail.paths[fp1.id] = table.cut(moves.sail.paths[fp1.id],i)
	    	  moves.sail.paths[fp2.id] = table.cut(moves.sail.paths[fp2.id],i)
	    	end
	      end
        end
      end
      
      -- remove duplicate collision points
      io.writeDebug('sail',"-removing duplicates-\n",colors.lightGray)
      io.writeDebug('sail',"collisions before: "..#moves.sail.collisions.."\n",colors.info)
      for i=1,#moves.sail.collisions do
        pt1 = moves.sail.collisions[i]
	    for _,pt2 in pairs(moves.sail.collisions) do
	      if (pt1.xloc == pt2.xloc) and (pt1.zloc == pt2.zloc) then -- is dupe
	    	table.remove(moves.sail.collisions,i)
	    	break
	      end
	    end
      end
      io.writeDebug('sail',"collisions after: "..#moves.sail.collisions.."\n",colors.info)
        
      -- iterate over all collision points
      for _,pt in pairs(moves.sail.collisions) do
        pt.pirates = {}
        -- find and store colliding pirates in each collision point
	    -- (at this point, all fpirates are at their end position, and thanks to table.cut() cutting colliding pirates' path end *at the collision*)
        for _,fp in pairs(fpirates) do
	      if pt.xloc == fp.xloc and pt.zloc == fp.zloc then
	        -- store pirate id
	    	pt.pirates[fp.id] = fp.id
	        -- remove collision point from path, as it's impossible to reach
	        table.remove(path[fp.id],#path[fp.id] - 1)
	      end
	    end
      end
      
      --if os.DIT['sail'] then os.p() end
      
      --= SAILING =--
        
      if os.DIT['sail'] then
        io.writeDebug('sail',"start loc:\n",colors.action)
        for pirateID,fp in pairs(fpirates) do
	      io.writeDebug('sail',"#",colors.lightGray)
	      io.writeDebug('sail',pirates[pirateID].id,colors.green)
	      io.writeDebug('sail'," [",colors.lightGray)
	      io.writeDebug('sail',pirates[pirateID].xloc,colors.info)
	      io.writeDebug('sail',",",colors.lightGray)
	      io.writeDebug('sail',pirates[pirateID].zloc,colors.info)
	      io.writeDebug('sail',"]\n",colors.lightGray)
	    end
	    io.writeDebug('sail',"moves.sail.paths count",colors.action)
	    io.writeDebug('sail',": ")
	    io.writeDebug('sail',table.getn(moves.sail.paths),colors.action)
	    io.writeDebug('sail',"\n{")
        for pirateID,path in pairs(moves.sail.paths) do
          io.writeDebug('sail',moves.sail.paths[pirateID],colors.action)
          io.writeDebug('sail',",")
        end
        io.writeDebug('sail',"}\n")
    	
        for pirateID,path in pairs(moves.sail.paths) do
	      io.writeDebug('sail',"pirate #",colors.lightGray)
	      io.writeDebug('sail',pirateID,colors.green)
	      io.writeDebug('sail',": ",colors.lightGray)
	      for a=1,#path do
            io.writeDebug('sail',tostring(path[a]).." ",colors.path)
	      end
	      io.writeDebug('sail',"\n")
	    end
      end
      
      if not os.isVis then
        -- use simple cache update system
	    io.writeDebug('sail',"simple sail\n",colors.lightGray)
	    
        for pirateID,path in pairs(moves.sail.paths) do
	      for i=1,#path do
	        if path[i] == "up" then
		      pirates[pirateID].zloc = pirates[pirateID].zloc + 1
	        elseif path[i] == "down" then
	    	  pirates[pirateID].zloc = pirates[pirateID].zloc - 1
	        elseif path[i] == "right" then
	    	  pirates[pirateID].xloc = pirates[pirateID].xloc - 1
	        elseif path[i] == "left" then
	    	  pirates[pirateID].xloc = pirates[pirateID].xloc + 1
	        end
	      end
	    end
      else
        -- use complex parrallel turtle movement + live cache update
	    io.writeDebug('sail',"complex sail\n",colors.lightGray)  
        
	    local SFL = {}
        local function getPirateInfo()
          local s,m,p
          local t
          local pirateID
          local myPirate
          local xloc,zloc
	      while true do
            s,m,p = rednet.receive()
            t = string.stt(m)
            io.writeDebug({'turtle','sail'},p.." ",colors.action)
            pirateID = tonumber(t[1])
	        io.writeDebug({'turtle','sail'},pirateID,colors.green)
            myPirate = pirate.find(pirateID)
            if p == "reportLoc" then
	          xloc = tonumber(t[2])
	          zloc = tonumber(t[3])
	    	  io.writeDebug({'turtle','sail'}," [")
	    	  io.writeDebug({'turtle','sail'},xloc,colors.info)
	    	  io.writeDebug({'turtle','sail'},",")
	    	  io.writeDebug({'turtle','sail'},zloc,colors.info)
	    	  io.writeDebug({'turtle','sail'},"]\n")
	          -- update the cache
	          myPirate.xloc = xloc
	          myPirate.zloc = zloc
            end
            if p == "reportState" then
	          io.writeDebug({'turtle','sail'}," "..tostring(t[2]).."\n",colors.cyan)
	          os.queueEvent("reportState: "..tostring(pirateID),tostring(t[2]))
            end
	      end
        end
        
        for pirateID,path in pairs(moves.sail.paths) do
	      -- create individual movment functions
	      table.insert(SFL,
	        function()
	          -- encode path
              local msg = ""
              for _,a in pairs(moves.sail.paths[pirateID]) do
                msg = msg..a.." "
              end
	    	  
	    	  -- send turtle path
              pirate.send(pirateID,msg,"setSail")
	    	  io.writeDebug({'turtle','sail'},"pirate #",colors.lightGray)
		      io.writeDebug({'turtle','sail'},pirateID,colors.green)
		      io.writeDebug({'turtle','sail'},": ",colors.lightGray)
              io.writeDebug({'turtle','sail'},msg.."\n",colors.msg)
		      -- track turtle movement, assumes
		      -- getPirateInfo() is running in parallel
		      local e,state = os.pullEvent("reportState: "..pirateID)
		      while state ~= "sailing" do
		        e,state = os.pullEvent("reportState: "..pirateID)
		      end
	    	  local e,state = os.pullEvent("reportState: "..pirateID)
		      while state ~= "stationary" do
		        e,state = os.pullEvent("reportState: "..pirateID)
	    	  end
	        end
	      )
        end
        
	    -- run sails and getPirateInfo
	    parallel.waitForAny(
	      function() -- will end when all pirates are stationary
	        -- run all sails in parallel
	        parallel.waitForAll(table.unpack(SFL))
	      end,
	      getPirateInfo -- will never end
	    )
      end
      
      moves.sail.paths = nil
      moves.sail.paths = {}
      
      if os.DIT['sail'] then
        io.writeDebug('sail',"end loc:\n",colors.action)
        for pirateID,_ in pairs(fpirates) do
	      io.writeDebug('sail',"#",colors.lightGray)
	      io.writeDebug('sail',pirates[pirateID].id,colors.green)
	      io.writeDebug('sail'," [",colors.lightGray)
	      io.writeDebug('sail',pirates[pirateID].xloc,colors.info)
	      io.writeDebug('sail',",",colors.lightGray)
	      io.writeDebug('sail',pirates[pirateID].zloc,colors.info)
	      io.writeDebug('sail',"]\n",colors.lightGray)
	    end
	    os.p()
      end
      
      if not os.DIT['sail'] then term.clearLine() end
      
      return true
	end
  },
  attack = {
    attacks = {},
	queue = function(attackerID,targetID,power)
	  table.insert(moves.attack.attacks,
	    {
	      ['attacker'] = attackerID,
	      ['target'] = trgetID,
	      ['power'] = power,
	    }
	  )
	end,
	dequeue = function()
	  for _,attackData in pairs(moves.attack.attacks) do
	    local atckr,trgt = core.pirates[attackData.attacker],core.pirates[attackData.target]
		local power = attackData.power
	    commands.execAsync("execute @e[type=ArmorStand,name="..constants.ArenaMarkerName.."] ~ ~ ~ summon "..constants.Barrel.." ~ ~ ~ {Motion:["..(.05*(core.pirate[trgtID].xloc-core.pirate[att].xloc))..","..(.37)..","..(.05*(core.pirate[trgtID].zloc - core.pirate[att].zloc)).."]}")
        if trgt.vulnerableTime == 0 then
		  trgt.vulnerableTime = constants.DeffendCooldown
          io.write("Pirate #")
          io.write(trgt.id,colors.info)
          print(" deflected the attack!",colors.success)
        else
          trgt.drunkTime = power
          io.write("Pirate #")
          io.write(trgt.id,colors.info)
          io.write(" is hit, and is disabled for ",colors.error)
          io.write(power,colors.purple)
          print(" turns.",colors.error)
		end
      end
	end
  },
  
  dequeue = function()
    for _,m in pairs(moves) do
	  if type(m) == "table" then
	    if type(m.dequeue) == "function" then
	      m.dequeue()
		end
	  end
	end
  end,
}

if not fs.exists(folder.bot) then
  fs.makeDir(folder.bot)
end
local players = {}
player = {}
function getPlayers()
  return players
end
function getPlayer(name)
  for _,pl in ipairs(players) do
    if pl.name == name then
	  return pl
	end
  end
  return nil,"cannot find player: no player named "..name
end
function player.eliminate(name)
  for i=1,#players do
    --print(players[i].name,colors.pink)
    if players[i].name == name then
      if players[i].isActive == true then
	    io.write("Player ")
		io.write(name,colors.name)
	    io.write(" has been ")
		io.write("eliminated\n",colors.red)
		players[i].isActive = false
		
		for j=1,#pirates do
		  if pirates[j].owner == players[i].name then
		    pirate.remove(j)
		  end
		end
		
		break
	  end
	end
  end
end
function player.add(name)
  local pl = {}
  
  if type(name) == "table" then
    local pl = name
	name = pl.name
  end

  io.writeDebug('players',"Adding player ")
  io.writeDebug('players',name,colors.name)
  io.writeDebug('players'," ... ")

  pl.name = name
  pl.score = 0
  pl.moves = constants.MAXMOVES
  
  pl.isActive = true
  
  local botFile = fs.open(folder.bot..name,"r")
  pl.doTurn,err = loadstring(botFile.readAll(),name)
  err = errMsg(err)
  
  botFile.close()
  
  players[#players+1] = pl
  
  if pl.doTurn == nil then -- bot file compiling error
    io.write("\nPlayer ")
	io.write(name,colors.name)
	print("'s Bot failed to compile.")
	print(err,colors.info)
	player.eliminate(name)
	--os.p()
	return
  end
  
  io.writeDebug('players',"Done.\n",colors.success)
  sleep(.1)
end
function player.remove(name)
  for i=1,#players do
    if players[i].name == name then
	  table.remove(players,i)
	end
  end
  
  for i=0,pirate.lastPirateID do
    if pirates[i] then
      if pirates[i].owner == name then
	    pirate.remove(i)
	  end
	end
  end
end
function player.removeAll()
  for i=1,#players do
    player.remove(players[i].name)
  end
end
activePlayer = getPlayers()[1]

function checkCollisions()
  if table.isEmpty(moves.sail.collisions) then
    return true,"no collision"
  end

  for i=1,#moves.sail.collisions do -- kill (remove) colliding pirates
    for j,pt in ipairs(moves.sail.collisions[i].pirates) do
      pirate.remove(p.id)
	end
  end
  
  for _,pt in pairs(moves.sail.collisions) do
    io.writeDebug('collision',"collision at [",colors.error)
    io.writeDebug('collision',loc.xloc)
	io.writeDebug('collision',",",colors.error)
	io.writeDebug('collision',loc.zloc,colors.info)
	
	if os.isVis then
	  -- DO EXPLOSION
	end
	
    io.writeDebug('collision',"]. pirates ",colors.error)
	for pirateID,p in ipairs(pt) do
	  io.write("#",colors.error)
	  io.write(p,colors.info)
	  io.write(" ",colors.error)
	end
	io.write("drowned",colors.error)
  end
  
  moves.sail.collisions = nil
  moves.sail.collisions = {}
  return true
end
function checkPickup(turnNum)
  --[[
  io.write("checkPickup: ",colors.green)
  io.write(turnNum.." ",colors.red)
  io.write(#treasures,colors.pink)
  io.write("<-")
  ]]--
  
  if table.isEmpty(pirates) or table.isEmpty(treasures) then
    return false,"no pirates/treasures"
  end
  
  for i,p in pairs(pirates) do
    for j,t in ipairs(treasures) do
	  if p then
	    if p.xloc == p.xloc and t.zloc == p.zloc then
		  if not isStruct(p.treasure,"treasure") then
			io.write("Pirate #")
			io.write(i,colors.info)
			io.write(" picked up a Treasure with value: ")
			print(t.value,colors.value)
			
		    pirates[i].treasure = table.copy(t)
			
			local prev = os.DIT['treasures']
			os.DIT['treasures'] = constants.HIDE
			treasure.remove(t.xloc,t.zloc)
			os.DIT['treasures'] = prev
		  end
		end
	  end
	end
  end
  
  --print(#treasures,colors.pink)
  
  return true
end
function checkDropoff()
  if table.isEmpty(pirates) then
    return false,"no pirates"
  end
  
  for ID,p in pairs(pirates) do
	if p then
	  if p.xloc == p.sxloc and p.zloc == p.szloc then
		if isStruct(p.treasure,"treasure") then
		  io.write("Pirate #")
	      io.write(ID,colors.info)
		  io.write(" earned ")
		  io.write(p.treasure.value,colors.value)
		  io.write(" points for Player ")
		  io.write(p.owner,colors.name)
		  print(".")
		  
		  for i=1,#players do
			if players[i].name == p.owner then
			  players[i].score = players[i].score + p.treasure.value
			end
		  end
		  p.treasure.xloc = nil
		  p.treasure.zloc = nil
		  p.treasure.value = nil
		end
	  end
	end
  end
  
  return true
end

function advanceTime(num)
  if num == nil then num = 1 end
  
  for pirateID,p in pairs(pirates) do
    p.drunkTime = p.drunkTime - num
	if p.vulnerableTime > num then
	  p.vulnerableTime = p.vulnerableTime - num
	else
	  p.vulnerableTime = constants.DeffendCooldown
	end
  end
end

function cleanup(force)
  local tmpIsVis = os.isVis
  if force == nil or force == false then
    -- DO NOTHING
  elseif force == true then
    os.isVis = true
  end
  
  io.writeDebug('cleanup',"running cleanup...\n",colors.pink)

  local tprev,pprev,aprev = os.DIT['treasures'],os.DIT['pirates'],os.DIT['arena']
  
  os.DIT['treasures'] = os.DIT[''] and os.DIT['cleanup']
  os.DIT['pirates'] = os.DIT[''] and os.DIT['cleanup']
  --os.DIT['arena'] = os.DIT[''] and os.DIT['cleanup']
  
  treasure.removeAll()
  pirate.removeAll()
  --arena.remove()
  
  os.DIT['treasures'],os.DIT['pirates'],os.DIT['arena'] = tprev,pprev,aprev
  
  io.writeDebug('cleanup',"cleanup successful.\n",colors.pink)
  
  os.isVis = tmpIsVis
end

map = {
  name = "",
  isParsed = false,
  parse = function(mapFile)
    local prev
    local show = os.DIT['map']
    if mapFile == nil then mapFile = map.name end
    
    io.writeDebug('map',"\nParsing Map ",colors.action)
    io.writeDebug('map',mapFile,colors.map)
    io.writeDebug('map'," ...\n",colors.value)
    
    local fullPath = folder.map..mapFile
    
    local function mapError()
      io.write("Map ")
	  io.write(mapFile,colors.map)
	  print(" is not an valid map!\n")
      os.p()
    end
    
    if not fs.exists(fullPath) then
      io.write("Map ")
	  io.write(mapFile,colors.map)
	  io.write(" is not an existing map!\nMake sure your map file is in \"")
	  io.write(folder.map,colors.info)
	  print("\"\n")
      os.p()
	  return false
    end
    local f = fs.open(fullPath,"r")
    local l = f.readLine()
    local tl = {}
	local prev
    
    local w,h
    while not w or not h do
      if not l then
	    mapError()
	    return false
	  end
      tl = string.stt(l)
	  if tl[1] == "width" then
	    w = tonumber(tl[2])
	  elseif tl[1] == "hight" then
	    h = tonumber(tl[2])
	  end
	  l = f.readLine()
    end
	
    prev = os.DIT['arena']
    os.DIT['arena'] = show and constants.SHOW
    arena.setup(w,h)
    os.DIT['arena'] = prev
    
    f.close()
	
    f = fs.open(fullPath,"r")
    l = f.readLine()
    while l do
	  sleep(0)
      tl = string.stt(l)
	  
	  if tl[1] == "treasure" then
	    local t = {}
	    t.xloc = tonumber(tl[2])
	    t.zloc = tonumber(tl[3])
	    t.value = tonumber(tl[4])
	    
	    prev = os.DIT['treasures']
	    os.DIT['treasures'] = show and constants.SHOW
	    treasure.add(t)
	    os.DIT['treasures'] = prev
	  elseif tl[1] == "pirate" then
	    local p = {}
	    p.xloc = tonumber(tl[2])
	    p.zloc = tonumber(tl[3])
		
		for i,pl in pairs(players) do
		  if i == tonumber(tl[4]) then
		    p.owner = pl.name
		  end
		end
        
		if p.owner then
	      prev = os.DIT['pirates']
	      os.DIT['pirates'] = show and constants.SHOW
		  pirate.add(p)
	      os.DIT['pirates'] = prev
		end
	  end
	  
      l = f.readLine()
    end
    
    map.isParsed = true
    
    io.writeDebug('map',"\nMap parsing ",colors.action)
    io.writeDebug('map',"Successful.\n\n",colors.success)
  end
}

turnData = {}
function turnData.save(turnNum)
  if turnNum == nil then
	return
  end
  if not (turnNum > #turnData) then
    return
  end
  if turnNum < 1 or turnNum > constants.MAXTURNS then
	return
  end
  
  io.writeDebug('save',"saving turn data...\n",colors.pink)
  
  --[[
  io.write("save: ",colors.green)
  io.write(turnNum.." ",colors.info)
  io.write(#treasures,colors.value)
  io.write("->",colors.green)
  if turnData[turnNum] ~= nil then
    io.write(#(turnData[turnNum].treasures),colors.cache)
  else
    io.write(nil,colors.cache)
  end
  --]]
  
  
  turnData[turnNum] = {}
  turnData[turnNum].pirates = table.copy(pirates)
  turnData[turnNum].treasures = table.copy(treasures)
  turnData[turnNum].players = table.copy(players)
  turnData[turnNum].arena = table.copy(arena)
  
  --[[
  print(" "..#turnData[turnNum].treasures,colors.cache)
  --]]
  
  io.writeDebug('save',"saving complete.\n",colors.pink)
  --sleep(2)
end
function turnData.load(turnNum)
  if os.isVis and not os.DIT['load'] then
    io.write("loading scene. please wait.",colors.lightGray)
  end
  
  io.writeDebug('load',"loading turn data...\n",colors.pink)
  
  if turnNum == nil then
	return
  end
  if turnData[turnNum] == nil then
	turnData.load(turnNum-1)
	turnData.save(turnNum)
  end
  
  --[[
  io.write("load: ",colors.green)
  io.write(turnNum,colors.info)
  io.write("->",colors.green)
  io.write(game.getTurn().." ",colors.info)
  io.write(#(turnData[turnNum].treasures),colors.cache)
  io.write("->",colors.green)
  io.write(#treasures.." ",colors.value)
  --]]
  
  local ta,tp,tt,tpl = os.DIT['arena'],os.DIT['pirates'],os.DIT['treasures'],os.DIT['players']
  os.DIT['arena'] = ta and os.DIT['load']
  os.DIT['pirates'] = tp and os.DIT['load']
  os.DIT['treasures'] = tt and os.DIT['load']
  os.DIT['players'] = tpl and os.DIT['load']
  
  local tmp = {}
  
  tmp = table.copy(turnData[turnNum].arena)
  arena.resize(tmp.w+1,tmp.h+1)
  
  tmp = table.copy(turnData[turnNum].pirates)
  for i=1,pirate.lastPirateID-1 do
    p = tmp[i]
	if p ~= nil then
      pirate.add(p)
	end
  end
  
  tmp = table.copy(turnData[turnNum].treasures)
  for i,t in ipairs(tmp) do
    treasure.add(t)
  end
  
  players = table.copy(turnData[turnNum].players)
  
  os.DIT['arena'],os.DIT['pirates'],os.DIT['treasures'],os.DIT['players'] = ta,tp,tt,tpl
  
  --[[
  io.write(#treasures.."\n",colors.value)
  --]]
  
  io.writeDebug('load',"loading complete.\n",colors.pink)
  
  if os.isVis and not os.DIT['load'] then
    term.clearLine()
  end
end