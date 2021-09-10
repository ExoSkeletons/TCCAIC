--= Server Log =--



dofile("game/utils")

-- custom tabs setup
local tabs = {}
local tab = {}
tab.focus = 1
tab.new = function(title,setFocus)
  local w,h = term.getSize()
  local tabID
  local windowObj
  
  windowObj = window.create(term.current(),1,2,w,h-1,setFocus)
  windowObj.nwrite = windowObj.write
  windowObj.write = function(txt,fg,bg)
	self = windowObj
	
	local winX,winY = windowObj.getSize()
    local pfg,pbg = windowObj.getTextColor(),windowObj.getBackgroundColor()
    if txt == nil then return end
    if fg == nil then fg = pfg end
    if bg == nil then bg = pbg end
    windowObj.setTextColor(fg)
    windowObj.setBackgroundColor(bg)
	
	txt = tostring(txt)
	local winW,winH = windowObj.getSize()
	local c
	for i=1,string.len(txt) do
	  c = string.sub(txt,i,i)
	  if c == "\n" then
	    winX,winY = windowObj.getCursorPos()
		if winY == winH then
		  windowObj.scroll(1)
		  windowObj.setCursorPos(1,winY)
		else
	      windowObj.setCursorPos(1,winY+1)
		end
	  else
        windowObj.nwrite(c)
	  end
	end
    windowObj.setTextColor(pfg)
    windowObj.setBackgroundColor(pbg)
  end
  windowObj.title = title
  tabs[#tabs+1] = windowObj
  tabID = #tabs
  
  if setFocus then
    tab.focus = tabID
  end
  
  return tabs[tabID]
end
tab.redrawAll = function()
  local w,h = term.getSize()
  local xc,yc = term.getCursorPos()
  local pfg,pbg = term.getTextColor(),term.getBackgroundColor()
  local tabColorPallet = {
    focus = {
	  fg = colors.yellow,
	  bg = colors.black,
	},
    unfocus = {
	  fg = colors.black,
	  bg = colors.gray,
	},
  }
  local colorPallet
  
  paintutils.drawLine(1,1,w,1,tabColorPallet.unfocus.bg) -- draw bar
  term.setCursorPos(1,1)
  for tabID=1,#tabs do -- draw tab titles
	-- select colorPallet
	if tabID == tab.focus then
	  colorPallet = tabColorPallet.focus
	else
	  colorPallet = tabColorPallet.unfocus
	end
	-- write title
	io.write(
	    " "..tabs[tabID].title.." ",
	    colorPallet.fg,
		colorPallet.bg
	)
  end
  if tabs[tab.focus] then -- redraw focusd tab
    tabs[tab.focus].redraw()
  end
  
  term.setTextColor(pfg)
  term.setBackgroundColor(pbg)
  term.setCursorPos(1,1)
end
tab.setFocus = function(tabID)
  if tabs[tabID] then
    for i=1,#tabs do
      tabs[i].setVisible(false)
    end
    tabs[tabID].setVisible(true)
	tab.focus = tabID
	tab.redrawAll()
  end
end
tab.handleMouseInput = function(b,xPos,yPos)
  if yPos == 1 then -- hit tab bar
    local tabXPos = 1
    for tabID=1,#tabs do
	  if tabXPos < xPos+1 and xPos < tabXPos+(1+string.len(tabs[tabID].title)+1) then
	    tab.setFocus(tabID)
		break
	  end
	  tabXPos = tabXPos+(1+string.len(tabs[tabID].title)+1)
	end
  else
    
  end
end
tab.handleKeyInput = function(k)
  
end

local nterm = term
local term = tab.new("general",true)

local PCIDs = {}
local id = {
  last = 0,
}
id.exists = function(par)
  local pc,_id
  if type(par) == "string" then
    _id = PCIDs[par]
  elseif type(par) == "number" then
    _id = par
  else
    return nil
  end
  return _id < id.last + 1
end
id.new = function()
  id.last = id.last + 1
  return id.last
end
id.link = function(name)
  if PCIDs[name] == nil then
    term.write("Linked PCIDs[")
    term.write(name,colors.name)
    term.write("] to ID ")
    PCIDs[name] = id.new()
    term.write(PCIDs[name].."\n",colors.info)
  end
  return PCIDs[name]
end
id.name = function(_id)
  _id = tonumber(_id)
  for name,i in pairs(PCIDs) do
    if i == _id then
	  return name
	end
  end
  return nil
end

local netReceive = rednet.receive
local PCReceive = function(p,timeout)
  local par,msg,prtcl = netReceive(p,timeout)
  local tmsg,tprtcl = string.stt(msg),string.stt(prtcl)
  
  if prtcl ~= "match"
  and prtcl ~= "linkPocketID"
  and tprtcl[1] ~= "file"
  then
    term.write("Rednet get!\n",colors.action)
    term.write(tostring(sender).." ",colors.info)
    term.write(tostring(prtcl).." ",colors.green)
    term.write(tostring(msg).."\n",colors.white)
  end
  
  if par == nil and msg == nil and prtcl == nil then
    return
  end
  
  local name,PCID
  
  if prtcl == "linkPocketID" then
    name = msg
    PCID = id.link(name)
    rednet.broadcast(PCID,"linkPocketID")
	return PCID,msg,prtcl
  end
  
  msg = table.tts(table.cut(tmsg,2))
  sender = tmsg[1]
  
  return sender,msg,prtcl
end
local netSend = rednet.send
local PCSend = function(PCID,msg,prtcl)
  if PCID == nil then
    return
  end
  rednet.broadcast(PCID.." "..tostring(msg),prtcl)
end
local PCBroadcast = function(msg,prtcl,PCList)
  if PCList == nil then
    PCList = PCIDs
  end
  
  --[[ debuging broadcast
  io.write("broadcasting to ",colors.purple)
  table.print(PCList)
  io.write(msg.."\n")
  --]]
  
  for _,PCID in pairs(PCList) do
    PCSend(PCID,msg,prtcl)
  end
end

local file = {
  name,
  path,
  type,
  handle,
}

local function wirelessFiles()
  local tab = tab.new("file transfer")
  
  local s,m,p
  local tm,tp
  local line = ""
  
  while true do
    s,m,p = PCReceive()
    tm,tp = string.stt(m),string.stt(p)
    
    if tp[1] == "file" then
      file.name = string.lower(tp[3])
      tab.write("File name: \"")
      tab.write(file.name,colors.action)
	  tab.write("\" Type: ")
      if tp[4] == "bot" then
	    tab.write("bot",colors.name)
	    file.type = folder.bot
      elseif tp[4] == "map" then
	    tab.write("map",colors.map)
	    file.type = folder.map
      else
	    tab.write("unknown",colors.error)
        file.name = nil
      end
	  
	  if file.name ~= nil then
	    file.path = file.type.."/"..tostring(file.name)
        if tp[2] == "upload" then
	      tab.write("\nUpdating "..tp[4].." \"")
		  if tp[4] == "bot" then
		    tab.write(file.name,colors.name)
		  elseif tp[4] == "map" then
		    tab.write(file.name,colors.map)
		  end
		  tab.write("\" ... ")
		  file.handle = fs.open(file.path,"w") -- open file
	  	  file.handle.write(m) -- write code to file
		  PCSend(s,"success","file upload")
		  file.handle.close()
		  tab.write("Done.\n",colors.success)
        elseif tp[2] == "download" then
          tab.write("Sending file ",colors.action)
		  tab.write("\"")
          tab.write(file.path,colors.name)
          tab.write("\" to ")
          tab.write(s,colors.name)
          file.handle = fs.open(file.path,"r")
          PCSend(s,file.handle.readAll(),"file download")
	      file.handle.close()
		end
	  else
	    PCSend(s,"failed",p)
      end
    end
  end
end
local function doMatching()
  local tab = tab.new("match making",false)
  
  local playerList,playerListPrev = {},{}
  local blackList,blackListPrev = {},{}
  local owner,ownerPrev = -1,nil
  local created = false
  
  local run = false
  local bots = {}
  local map = ""
  
  local function runMatch()
    commands.exec("scoreboard players set @a[score_room_min=110] InMatch 1",false)
	commands.exec("tp @a[score_InMatch=1] 0 25 4")
    
	local runENV = {
	  ['debug'] = function(par,clr)
	    local t = "string"
		local m = "nil"
		if par == nil then
		  m = "nil"
		end
		if clr == nil then
		  clr = colors.white
		end
		if type(par) == "table" then
		  t = "list"
		  m = "%"..clr.." "..table.tts(par)
		elseif type(par) == "string" then
		  t = "string"
		  m = tostring(par).."\n "..clr
		end
		
		PCSend(PCIDs[core.activePlayer.name],"%"..t.." "..m,"match")
	  end,
	  ['bots'] = bots,
	  ['doAuto'] = true, -- signals to "run" to run on auto (no pause)
	}
	multishell.setFocus(multishell.launch(runENV,"run",map,table.unpack(bots)))
  end
  
  local rePingTime = .75
  
  local s,m,p
  local tm
  local function writeLobby(txt,clr,excludeList)
    local writeList = table.copy(playerList)
	if excludeList then
	  local s,index
	  for i=1,#excludeList do
	    s,index = table.search(writeList,excludeList[i])
		if s then
		  table.remove(writeList,index)
		end
	  end
	end
	if txt ~= nil then
	  local msg = "%string "..txt
	  if clr == nil then clr = term.getTextColor() end
	  msg = msg.." "..clr
      --[[ debuging writeList
      io.write("writing to ",colors.purple)
      table.print(writeList)
      io.write(msg.."\n")
	  os.p()
      --]]
	  tab.write(txt,clr)
	  PCBroadcast(msg,"match",writeList)
	end
  end
  local function handleNet()
	-- refresh playerList
	playerList = {}
	-- clear blackList if the match is closed
	if not created then
	  blackList = {}
	  blackListPrev = {}
	end
	-- reping players
	PCBroadcast("ping","match",playerListPrev)
	
	while true do
	  repeat
        s,m,p = PCReceive("match")
	  until m ~= nil
	  
	  tm = string.stt(m)
	  s = tonumber(s)
	  
	  if id.exists(s) then -- s is a linked PC
	    if m == "connect" then
		  if not created then
		    tab.write(id.name(s),colors.name)
		    tab.write(" created a match. waiting for players.\n",colors.lightBlue)
		    created = true
		  end
		  if not table.search(playerList,s) then -- dupe protection
			-- add player s
	        playerList[table.getn(playerList)+1] = s
		  end
		  if owner == -1 then
		    owner = s
			PCSend(s,"owner","match")
		  end
		elseif tm[1] == "chat" then -- chat
		  m = string.gsub(m,"chat","",1)
		  if tm[2] == id.name(s) then
		    writeLobby(m,colors.chat)
		  else
		    writeLobby(id.name(s)..":",colors.chat)
		    writeLobby(m,colors.white)
		  end
		  writeLobby("\n")
		elseif tm[1] == "owner" then
		  PCSend(s,"%string ".."match owner:\n "..colors.lightGray,"match")
		  PCSend(s,"%string "..id.name(owner).."\n "..colors.name,"match")
		elseif tm[1] == "players" then
		  local names = {}
		  for _,v in pairs(playerListPrev) do
		    table.insert(names,id.name(v))
		  end
		  if not table.isEmpty(names) then
		    PCSend(s,"%string ".."connected players:\n "..colors.lightGray,"match")
		    PCSend(s,"%list %"..colors.name.." "..table.tts(names),"match")
		  end
		elseif tm[1] == "map" then
		  if tm[2] == "list" then
		    tab.write(id.name(s),colors.name)
			tab.write(" requested map list:",colors.action)
			local list = fs.list(folder.map)
			if not table.isEmpty(list) then
			  tab.write("\n"..table.tts(list),colors.info)
			  PCSend(s,"%string ".."map list:\n "..colors.lightGray,"match")
			  PCSend(s,"%list %"..colors.map.." "..table.tts(list),"match")
		    else
			  PCSend(s,"%string ".."no maps found\n "..colors.error,"match")
			  tab.write(" no maps found",colors.error)
			end
			tab.write("\n")
		  elseif tm[2] == "select" then
		    if tm[3] ~= nil then
			  -- select map tm[4]
			end
		  end
		end
		
		if tm[1] == "ban"
		or tm[1] == "run"
		or tm[1] == "unban"
		or (tm[1] == "map" and tm[2] == "set")
		then
		  if s == owner then -- check for owner only commands
		    if tm[1] == "ban" then
			  if PCIDs[tm[2]] == s then
		        PCSend(s,"%string ".."you cannot ban yourself\n "..colors.error,"match")
		      elseif PCIDs[tm[2]] == owner then
		        PCSend(s,"%string ".."you cannot ban the owner\n "..colors.error,"match")
		      elseif PCIDs[tm[2]] then
		        table.insert(blackList,PCIDs[tm[2]])
			  end
		    elseif tm[1] == "unban" then
		      local b,i = table.search(blackList,PCIDs[tm[2]])
			  if b then
			    table.remove(blackList,i)
			  end
		    elseif tm[1] == "map" and tm[2] == "set" and tm[3] ~= nil then
			  if fs.isFile(folder.map..tm[3]) then
			    map = tostring(tm[3])
				writeLobby("selected map ",colors.lightGray)
				writeLobby(map.."\n",colors.map)
			  else
			    PCSend(s,"%string "..tm[3].." is not an existing map!\n "..colors.error,"match")
			  end
			elseif (m == "run" or m == "start") and s == owner then
			  run = true
		    else
		      -- DO NOTHING
		    end
		  else
		    PCSend(s,"%string ".."you are not the owner\n "..colors.error,"match")
		  end
		end
	  end
	end
  end
  
  while true do
	parallel.waitForAny(
	  handleNet,
	  function() -- refresh timer
	    sleep(rePingTime)
	  end
	)
	
	--[[ debug playerList
	io.write("prev: ",colors.purple)
	table.print(playerListPrev)
	io.write("curr: ",colors.purple)
	table.print(playerList)
	io.write("-----------\n",colors.pink)
	--]]
	
	-- check for player disconnecting
	for i,PCIDPrev in pairs(playerListPrev) do
	  if not table.search(playerList,PCIDPrev) then -- disconnect
	    writeLobby(id.name(PCIDPrev),colors.name)
	    writeLobby(" disconnected\n",colors.lightGray)
		if PCIDPrev == owner then
		  owner = -1
		end
	  end
	end
	-- check for player joining
	for i,PCID in pairs(playerList) do
	  if not table.search(playerListPrev,PCID) then -- new player
	    writeLobby(id.name(PCID),colors.name,{PCID})
		PCSend(PCID,"%string ".."you".." "..colors.name,"match")
	    writeLobby(" joined\n",colors.lightBlue)
	  end
	end
	
	-- check for player unbanning
	for i,PCIDPrev in pairs(blackListPrev) do
	  if not table.search(blackList,PCIDPrev) then -- player is no longer on blackList
	    writeLobby(id.name(PCIDPrev).." has been unbanned\n",colors.lightGray)
	  end
	end
	-- check for player banning
	for i,PCID in pairs(blackList) do
	  if table.search(blackListPrev,PCID) then -- new banned player
	    local s,j = table.search(playerList,PCID)
		if s then
	      table.remove(playerList,j) -- remove banned players
		  PCSend(PCID,"banned","match")
	      writeLobby(id.name(PCID).." has been banned\n",colors.red)
	    end
	  end
	end
	
	-- check for match "exit"
	if table.isEmpty(playerList) and created then
	  tab.write("match closed.\n",colors.lightGray)
	  created = false
	end
	
	
	-- check for run
	if run then
	  bots = table.copy(playerList)
	  for i,bot in pairs(playerList) do
	    if not fs.isFile(folder.bot..id.name(bot)) then
		  bots[i] = nil
		else
		  bots[i] = id.name(bot)
		end
	  end
	  if table.isEmpty(bots) then
	    writeLobby("cannot run match with 0 bots!\n",colors.error)
	  elseif run then
	    if fs.isFile(folder.map..map) then
		  runMatch()
		else
		  PCSend(owner,"%string ".."please select a map\n".." "..colors.chat,"match")
		end
	  end
	end
	run = false
	
	
	-- update cache
	playerListPrev = table.copy(playerList)
	blackListPrev = table.copy(blackList)
  end
  
  rednet.broadcast("exit","match")
end

local function main()
  parallel.waitForAny(
    function() -- handle tabs
	  local e
	  local b,xPos,yPos
	  local k
	  while true do
		tab.redrawAll()
	    parallel.waitForAny(
		  function() -- mouse_click
	        e,b,xPos,yPos = os.pullEvent("mouse_click")
		  end,
		  function() -- key
	        e,k = os.pullEvent("key")
		  end,
		  function() -- refresh
		    sleep(.05)
		  end
		)
		if e == "mouse_click" then
		  tab.handleMouseInput(b,xPos,yPos)
		elseif e == "key" then
		  tab.handleKeyInput(k)
		end
	  end
	end,
    
	wirelessFiles,
    doMatching
  )
end

local s,res = pcall(main)
if not s then
  io.write(tostring(res),colors.error)
end

os.p()
