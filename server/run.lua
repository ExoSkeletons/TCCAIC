--= Run =--



local tArgs = {...}
if #tArgs < 2 then
  print("Usage: run <map> <bot1> <bot2> ...")
  return
end

if doAuto == true then
  _G['debug'] = debug
  _G['bots'] = bots
  
  local monitors = {peripheral.find("monitor")}
  
  for _,mon in pairs(monitors) do
    mon.setTextScale(1.4)
  end
  
  local multiTerm = {}
  for funcName,_ in pairs(monitors[1]) do
    multiTerm[funcName] = function(...)
      for i=1,#monitors-1 do monitors[i][funcName](unpack(arg)) end
      return monitors[#monitors][funcName](unpack(arg))
    end
  end
  term.redirect(multiTerm)
  
  term.clear()
  term.setCursorPos(1,1)
end

dofile("game/utils")

os.loadAPI(folder.apis.."constants")

local function loadAPIS()
  os.loadAPI(folder.apis.."core")
  os.loadAPI(folder.apis.."game")
end
local function unloadAPIS()
  os.unloadAPI("game")
  os.unloadAPI("core")
  os.unloadAPI("constants")
end

-- backup to-be-modified system functions
local pullEvent = os.pullEvent
local exec = commands.exec
local nprint = print
local clearLine = term.clearLine

os.pullEvent = os.pullEventRaw
print = function(par,fgc,bgc)
  io.write(par,fgc,bgc)
  io.write("\n")
end
term.clearLine = function()
  local x,y = term.getCursorPos()
  if x == 1 and y > 1 then
    y = y - 1
  end
  term.setCursorPos(1,y)
  clearLine()
end
commands.exec = function(cmd,doError)
  if cmd == nil then return end
  if doError == nil then doError = true end
  local s,r = exec(cmd)
  if doError then
    if not s then
      io.write("failed to execute command:\n",colors.error)
	  io.write(tostring(cmd).."\n",colors.info)
	  io.writeDebug('commands',"error message: ",colors.error)
      io.writeDebug('commands',r[1].."\n",colors.info)
	  r = nil
	  error("failed to execute command",0)
	end
  end
  
  return s,r
end

os.DIT = {
  all = nil,
  
  event = constants.HIDE,
  
  ui = constants.HIDE,
  
  save = constants.HIDE,
  load = constants.HIDE,
  
  pickup = constants.SHOW,
  dropoff = constants.SHOW,
  
  cleanup = constants.HIDE,
  
  pirates = constants.SHOW,
  treasures = constants.SHOW,
  arena = constants.SHOW,
  
  sail = constants.SHOW,
  path = constants.SHOW,
  
  turtle = constants.SHOW,
  
  commands = constants.SHOW,
  scoreboard = constants.SHOW,
  
  players = constants.SHOW,
  
  map = constants.SHOW
}
io.writeDebug = function(info,par,fgc)
  if os.DIT == nil then error("cannot find os.DIT") end
  if os.DIT['all'] == constants.HIDE then return end
  
  local show = true
  
  if type(info) == "table" then
    for _,i in ipairs(info) do
	  show = show and os.DIT[i]
	end
  else
    show = os.DIT[info]
  end
  
  if os.DIT['all'] == constants.SHOW
  or show == true then
    io.write(par,fgc)
  end
end
os.randomError = function()
  local errors = {
  
    "Whoops!",
	"Thats odd...",
	"Oh snap!",
	"Ouch!",
	"Well thats unfortunate...",
	"Error 404 - error message not found.",
	"Crash!",
	"This doesn't look good.",
	"This is bad...",
	"Oh no!!!",
	"This is a problem...",
	"Huh.",
	"Heusten, we have a problem...",
	"Well what do you know...",
	"*&^%&%$*%^&",
	"Oh no! an error!",
	"Shiver me Timbers!!!",
	"Abort!!! Abort!!!",
	"1/0 = !?",
	"Bug detected!",
	"Failed to activate NUKE.exe!",
	"A thing happend.",
	"So thats what the red button does...",
	"Boop dee boop!",
	"Bug repelling spray out of order!",
	"Something went wrong there.",
	"An error occurred.",
	"I dont think its was supposed to do that...",
	"Iluminati",
	"This is embarrassing...",
	"R.I.P.",
	"Not again...",
	"Nooo.....",
	"Rage quit engage!",
	"This doesn't happen normaly...",
	"os.queueEvent(\"Error\")",
	"A wild error message appears!",
	"You might want to contact the creator.",
	"I guess I forgot to remove a semicolon...",
	"Definatly not an Error!",
	"I said add Hugs, not Bugs!",
	"Awesomeness overload!!!",
	"Please fix bug #"..math.random(1,100).."!",
	":(",
	"We've been comprimised.",
	"Epic failure!"
  
  }

  local num = math.random(1,#errors)
  
  local errMsg = errors[num]
  if errMsg == "Iluminati" then
	io.write("Ilumin",colors.action)
	io.write("[REDACTED]",colors.red)
	print("!",colors.action)
  else
	print(errMsg,colors.action)
  end
end
os.isVis = false

os.c()

loadAPIS()


local function scanKeywords(file)
  local f = fs.open(file,"r")
  local fullCode = f.readAll() -- get the entire code
  f.close()
  
  local function findAsProtected(code,name)
    code = string.clean(code)
    if not (string.find(code,"[^A-Z,a-z]"..name.."[^A-Z,a-z]") ~= nil) then
	  return false
	end
	
	io.write("Bot ")
	io.write(file,colors.name)
	io.write(" contains Suspicious use of ")
	io.write(name,colors.red)
	print("!")
	print("Check ")
	print(constants.THEWEBSITE.."/protected",colors.info)
	io.write("for a list of protected APIs and functions for a list of protected APIs, or simply click the ")
	io.write("Link in Chat",colors.action)
	print("!\n")
	os.p()
	commands.exec("/w @a[r="..constants.ChatBroadcastRadius.."] Link: "..constants.THEWEBSITE.."/protected")
	
	os.queueEvent("terminate")
	while true do sleep(.1) end
  end
  
  if -- check for keywords
     findAsProtected(fullCode,"commands")
  or findAsProtected(fullCode,"coroutine")
  or findAsProtected(fullCode,"disk")
  or findAsProtected(fullCode,"fs")
  or findAsProtected(fullCode,"gps")
  or findAsProtected(fullCode,"help")
  or findAsProtected(fullCode,"http")
  --or findAsProtected(fullCode,"io")
  or findAsProtected(fullCode,"keys")
  or findAsProtected(fullCode,"multishell")
  or findAsProtected(fullCode,"os")
  or findAsProtected(fullCode,"paintutils")
  or findAsProtected(fullCode,"parrallel")
  or findAsProtected(fullCode,"peripheral")
  or findAsProtected(fullCode,"rednet")
  or findAsProtected(fullCode,"redstone")
  or findAsProtected(fullCode,"rs")
  or findAsProtected(fullCode,"settings")
  or findAsProtected(fullCode,"shell")
  or findAsProtected(fullCode,"term")
  or findAsProtected(fullCode,"textutils")
  or findAsProtected(fullCode,"turtle")
  or findAsProtected(fullCode,"window")
  
  or findAsProtected(fullCode,"_env")
  or findAsProtected(fullCode,"_g")
  or findAsProtected(fullCode,"getfenv")
  or findAsProtected(fullCode,"setfenv")
  or findAsProtected(fullCode,"_echo")
  
  or findAsProtected(fullCode,"load")
  or findAsProtected(fullCode,"loadstring")
  or findAsProtected(fullCode,"loadfile")
  or findAsProtected(fullCode,"dofile")
  
  or findAsProtected(fullCode,"printerror")
  
  or findAsProtected(fullCode,"core")
  
  or findAsProtected(fullCode,"read")
  
  then
  end
end
local function parsePlayers(playerList)
  for i=1,#playerList do
    if not fs.exists(folder.bot..playerList[i]) then
      io.write("Bot ")
	  io.write(playerList[i],colors.name)
	  io.write(" is not an existing bot!\nMake sure your bot is in \"")
	  io.write(folder.bot,colors.info)
	  print("\"\n")
	  os.p()
	  error("",0)
    end
	
	scanKeywords(folder.bot..playerList[i])
  end
  
  for i=1,#playerList do
    core.player.add(playerList[i])
  end
end


local function main()
  core.map.name = tArgs[1]
  
  parsePlayers(table.cut(tArgs,2))
  os.p()
  
  local function createButtons()
    local play = {}
    play.txt = ">>"
    play.fgc = colors.green
    play.len = string.len(play.txt)
    play.org = math.floor(term.w()/2)
	play.key = "space"
	play.show = function()
	  return core.isPaused
	end
    play.action = function()
      core.isPaused = false
    end
    local pause = table.copy(play)
    pause.txt = "||"
	pause.show = function()
	  return not core.isPaused
	end
    pause.action = function()
      core.isPaused = true
    end
	core.addButton(pause)
	core.addButton(play)
    
    local prev = {}
    prev.txt = "< "
    prev.fgc = colors.action
    prev.len = string.len(prev.txt)
    prev.org = play.org - prev.len
	prev.key = "left"
	prev.show = function()
	  return core.isPaused
	end
    prev.action = function()
      if core.turn > 1 then
        core.turn = core.turn - 1
	  end
    end
    core.addButton(prev)

    local future = {}
    future.txt = " >"
    future.fgc = colors.action
    future.len = string.len(future.txt)
    future.org = play.org + play.len
	future.key = "right"
	future.show = function()
	  return core.isPaused
	end
    future.action = function()
      core.turn = core.turn + 1
    end
    core.addButton(future)

    local fast = table.copy(future)
    fast.txt = ">>"
	fast.show = function()
	  return not core.isPaused and not core.isVis
	end
    fast.action = function()
      if core.speedFactor < .5f then
        core.speedFactor = core.speedFactor + .1f
	  end
    end
    core.addButton(fast)

    local slow = table.copy(prev)
    slow.txt = "<<"
	slow.show = function()
	  return not core.isPaused and not core.isVis
	end
    slow.action = function()
      if .19f < core.speedFactor then
        core.speedFactor = core.speedFactor - .10f
	  end
    end
    core.addButton(slow)

    local visON = {}
    visON.txt = "[visualise]"
    visON.len = string.len(visON.txt)
    visON.org = term.w() - visON.len + 1
	visON.fgc = colors.blue
	visON.key = "v"
	visON.show = function()
	  return not os.isVis
	end
    visON.action = function()
	  if core.turn > 1 and not core.isPaused then
	    core.turn = core.turn - 1
	  end
      os.isVis = true
    end
    local visOFF = table.copy(visON)
    visOFF.txt = "[[ stop  ]]"
    visOFF.fgc = colors.orange
	visOFF.show = function()
	  return os.isVis
	end
    visOFF.action = function()
	  os.isVis = false
      core.cleanup(true) -- forced cleanup
	  core.turnData.load(core.turn) -- reload
    end
    core.addButton(visON)
    core.addButton(visOFF)
  end
  createButtons()
  
  if core.map.parse(map) == false then
	return true
  end
  os.p()
  
  core.turn = 1
  core.turnData.save(core.turn)
  core.cleanup()
  
  local function doTurn()
    for i=1,#game.getAllPlayers() do -- run all bots
	  --os.lua()
	  
	  activePlayer = game.getAllPlayers()[i]
	  activePlayer.moves = constants.MAXMOVES
	  core.activePlayer = activePlayer
	  if activePlayer.isActive then
	    io.write("Player ")
	    io.write(activePlayer.name,colors.name)
	    print(" is making his move.")
	    
	    local s,err = pcall(activePlayer.doTurn,activePlayer.name)
		--err = core.errMsg(err)
		if not s then -- eliminate crashed players
		  io.write("Bot ")
		  io.write(activePlayer.name,colors.name)
		  io.write(" has ")
		  print("crashed!!!",colors.error)
		  print(err,colors.green)
		  core.player.eliminate(activePlayer.name)
		end
	  end
	end
	
	if game.activePlayersCount() == 1 then -- only one bot left
	  for i=1,#game.getAllPlayers() do
		if game.getAllPlayers()[i].isActive then
		  activePlayer = game.getAllPlayers()[i].name
		end
	  end
	  io.write("--= Player ",colors.success)
	  io.write(activePlayer,colors.name)
	  print(" Wins by defualt =--\n",colors.success)
	  os.p()
	  return 2
	end
	if game.activePlayersCount() == 0 then -- all bots crashed
	  print("No active bots left.")
	  core.turn = constants.MAXTURNS
	  os.p()
	  return 1
	end
	
	core.checkCollisions()
	core.moves.dequeue()
    core.checkPickup(core.turn)
    core.checkDropoff()
	core.advanceTime()
	
	return 0
  end
  
  local UI = {
    print = function()
	  -- print interface
	  local xc,yc
      xc,yc = term.getCursorPos()
	  term.setCursorPos(1,term.h())
	  term.clearLine()
      for i,button in ipairs(core.buttons) do
	    if button.show() then
		  term.setCursorPos(button.org,term.h())
		  io.write(button.txt,button.fgc,button.bgc)
	    end
	  end
      if not os.isVis then
	    term.setCursorPos((term.w()/2 - 3),term.h()-1)
	    io.write("speed: ",colors.cyan)
	    io.write(math.ceil((core.speedFactor*10)-.9),colors.white)
	  end
	
      term.setCursorPos(xc,yc)
    end,
    handle = function()
      local dat
	  local e,k
	  local xclick,yclick
	  
	  local w,h = term.getSize()
	  if doAuto then
	    local tmon = peripheral.find("monitor")
		w,h = tmon.getSize()
		h = h-1
	  end
	  
	  local refreshTimer = os.startTimer(constants.MAXSLEEP-(4*core.speedFactor))
	  
	  while true do
	    -- wait for clicks & timeout
	    dat = {os.pullEvent()}
		e = dat[1]
	    
	    xc,yc = term.getCursorPos()
	    if yc == h-1 then
	      term.setCursorPos(xc,yc-1)
		  term.clearLine()
	    end
	    io.writeDebug("event",e.."\n",colors.action)
	  
	    if e == "SRefresh" then
	      break
	    elseif (e == "timer" and dat[2] == refreshTimer) and ((not core.isPaused) or os.isVis) then
	      os.queueEvent("SRefresh") -- timeout. refresh.
	    elseif e == "mouse_click" and dat[2] == 1 then -- left click
		  xclick,yclick = dat[3],dat[4]
		  io.writeDebug('ui',"["..xclick..","..yclick.."]\n",colors.purple)
		  if yclick == h then -- the bottom part of the screen
		    for i=1,#core.buttons do
			  button = core.buttons[i]
		      if button.org <= xclick and xclick < button.org + button.len then -- clicked on button
		        if button.show() then
			      button.action()
				  io.writeDebug('ui',"hit\n",colors.action)
				  os.queueEvent("SRefresh") -- refresh
				  break
			    end
			  end
		    end
		    --sleep(constants.clickRespondTime)
		  end
		elseif e == "monitor_touch" then -- monitor hit
		  os.queueEvent("mouse_click",1,dat[3],dat[4])
	    elseif e == "key" then -- check for hotkeys
		  k = dat[2]
		  for i=1,#core.buttons do
		    button = core.buttons[i]
			if button.key == keys.getName(k) then -- found key
			  if button.show() then
			    button.action()
				io.writeDebug('ui',keys.getName(k),colors.orange)
				os.queueEvent("SRefresh")
				break
			  end
			end
		  end
		end
	  end
	  if os.DIT['event'] then sleep(.4) end
    end
  }
  
  local exitCode,res
  
  game = table.protect(game)
  
  while game.getTurn() < constants.MAXTURNS + 1 do -- MAIN TURN LOOP
    os.c()
	
    io.write("Turn #",colors.action)
	io.write(game.getTurn(),colors.info)
	print(".",colors.action)
	
	core.turnData.load(core.turn) -- load current turns' data
	
	exitCode,res = doTurn()
	if exitCode == nil or exitCode == 0 then -- ok
	  -- DO NOTHING
	elseif exitCode == 1 then -- exit loop
	  break
	elseif exitCode == 2 then -- exit main
	  return res
	elseif exitCode == 3 then -- error
	  error(res)
	end
	
	UI.print()
	UI.handle()
	
	core.turnData.save(core.turn+1)
	
	if not core.isPaused then
	  core.turn = core.turn + 1
	end
	
	core.cleanup()
  end

  --os.p()
  
  core.clearButtons()
  
  print("\nNo more turns!\n",colors.error)
  
  local isDraw = true
  local prev
  for i=2,#game.getAllPlayers() do -- Check for Draw
    prev = game.getAllPlayers()[i-1]
    if game.getAllPlayers()[i].score ~= prev.score then
	  isDraw = false
	  break
	end
  end
  
  -- Print battle outcome
  if isDraw then
    -- Print Draw
    io.write("All players have ")
	io.write(core.getPlayers()[1].score,colors.value)
	print(" points.")
    print("--= Draw =--\n",colors.success)
  else -- Print rating
    -- sort players from lowest score to highest
    local done = false
    local tmp = 0
    while not done do
      done = true
      for i=1,#core.getPlayers()-1 do
        if core.getPlayers()[i+1].score < core.getPlayers()[i].score then
	      -- swap players[i],players[i+1]
          tmp = core.getPlayers()[i]
          core.getPlayers()[i] = core.getPlayers()[i+1]
          core.getPlayers()[i+1] = tmp
		
          done = false
        end
      end
    end
  
    local maxcount
    if #core.getPlayers() > constants.MAXCOUNT then
      maxcount = constants.MAXCOUNT
    else
      maxcount = #core.getPlayers()
    end
  
    local doNewCount = true
    local skip = false
    local isFirst = true
    for  i = #core.getPlayers(),#core.getPlayers()-maxcount+1,-1 do
      skip = false
	  
	  if isFirst and doNewCount then
	    io.write("--= ",colors.success)
	  elseif doNewCount then
	    io.write("    ")
	  end
      io.write("Player ")
	  io.write(core.getPlayers()[i].name,colors.name)
	  io.write(" ")
	  if core.getPlayers()[i-1] then
	    if core.getPlayers()[i].score == core.getPlayers()[i-1].score then
	      io.write("and ")
	      doNewCount = false
		  skip = true
	    end
	  end
	  if not skip then
	    io.write("scored ")
	    io.write(core.getPlayers()[i].score,colors.value)
	    io.write(" points")
	    doNewCount = true
	    if isFirst then
	      isFirst = false
	  	  print(" =--",colors.success)
	    else
	      print(".")
	    end
	  end
    end
  end
  
  io.write("\n")
  os.p()
end
local function restore()
  commands.exec = exec

  os.DIT = nil
  os.isVis = nil
  os.randomError = nil
  
  os.pullEvent = pullEvent
  
  term.clearLine = clearLine
  print = nprint
  type = type
end
local function quit(exitCode)
  core.objectives.removeAll()
  core.cleanup(true)
  if core.map.isParsed then core.arena.kill() end
  
  if exitCode == nil or exitCode == 0 then
	term.clear()
	term.setCursorPos(1,1)
	print("Thank you for participating in ",nil,nil,true)
	game.name()
	print("!")
  elseif exitCode == 1 then
	print("-- Exit Faliure --",colors.action,nil,true)
  end
  
  unloadAPIS()
  
  os.queueEvent("quitComplete",exitCode)
end

local function catchTerminate()
  local event
  while true do
    event = os.pullEvent("terminate")
	if 1 < core.turn then
	  os.isPaused = false
	  core.turn = constants.MAXTURNS
	  --os.queueEvent("SRefresh")
	else
	  quit()
	end
	os.pullEventRaw("quitComplete")
	
	os.pullEvent = pullEvent
	os.queueEvent("terminate")
  end
end
local function mainCaller()
  local s,err = pcall(main)
  if not s then
    os.randomError()
	io.write("Error: ",colors.red)
	print(err,colors.white)
	game.name()
   	print(" had to close.")
	quit(1)
  else
    quit()
  end
end

parallel.waitForAny(mainCaller,catchTerminate)

restore()

os.p()

if doAuto then
  commands.exec("scoreboard players set @a[score_InMatch=1] room 2",false) -- 2 -> skip inv clear at 1
  commands.exec("scoreboard players set @a[score_InMatch=1] InMatch 0",false)
end

os.c()
