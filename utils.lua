--= Utils =--



versions = {
  TCCAIC = "4",
  Server = "4",
  Client = {
    Pirate = "3",
	Pocket = "4",
  },
}

table.isEmpty = function(t)
  if t == nil then return false end
  for i,v in pairs(t) do
    if type(v) == "table" then
	  if table.isEmpty(v) == false then
	    return false
	  end
    elseif v then  
	  return false
	end
  end
  for i=0,#t do
    if type(t[i]) == "table" then
	  if table.isEmpty(t[i]) == false then
	    return false
	  end
    elseif t[i] then
	  return false
	end
  end
  return true
end
table.protect = function(t)
  if not type(t) == "table" then
    return
  end
  
  return setmetatable({}, {
    __index = t,
    __newindex = function(tbl, key, value)
	  error("cannot modify: table is protected")
    end
  })
end
table.copy = function(t)
  if type(t) ~= "table" then return t end
  --local meta = getmetatable(t)
  local target = {}
  for k, v in pairs(t) do
    if type(v) == "table" then
      target[k] = table.copy(v)
    else
      target[k] = v
    end
  end
  --setmetatable(target, meta)
  return target
end
table.isEqual = function(t1,t2,ignore_mt)
  local ty1 = type(t1)
  local ty2 = type(t2)
  if ty1 ~= ty2 then return false end
  -- non-table types can be directly compared
  if ty1 ~= 'table' and ty2 ~= 'table' then return t1 == t2 end
  -- as well as tables which have the metamethod __eq
  local mt = getmetatable(t1)
  
  if not ignore_mt and mt and mt.__eq then return t1 == t2 end
  
  for k1,v1 in pairs(t1) do
    local v2 = t2[k1]
    if v2 == nil or not table.isEqual(v1,v2) then return false end
  end
  
  for k2,v2 in pairs(t2) do
    local v1 = t1[k2]
    if v1 == nil or not table.isEqual(v1,v2) then return false end
  end
  
  return true
end
table.tts = function(t,splitChar)
  if type(t) ~= "table" then
    return
  end
  
  local str = "nil"
  local f = true
  if splitChar == nil then
    splitChar = " "
  end
  for i,v in pairs(t) do
    if type(v) ~= "string" then
	  v = tostring(v):gsub(" ","") -- function: xxxx -> function:xxxx
	end
    if not f then
      str = str..splitChar..v
	else
	  str = v
	  f = false
	end
  end
  
  return str
end
table.cut = function(t,startPos,endPos)
  local res = {}
  
  if endPos == nil then
    endPos = table.getn(t)
  end
  if startPos == nil then
    if endPos == table.getn(t) then
	  return t
	else
	  startPos = 1
	end
  end
  
  for k=startPos,endPos do
    table.insert(res,t[k])
  end
  table.tts(res)
  return res
end
table.getn = function(t)
  if t == nil then return 0 end
  
  local n = 0
  for _,v in pairs(t) do
    n = n + 1
  end
  return n
end
table.print = function(t,indent)
  if indent == nil then indent = 0 end
  
  if indent > 0 then io.write(string.rep("  ",indent)) end
  io.write("{\n")
  for i,k in pairs(t) do
    io.write(string.rep("  ",indent+1))
    io.write("["..i.."]=")
	if type(k) == "table" then
	  table.print(k,indent+1)
	else
	  io.write(tostring(k))
	end
	io.write(",\n")
  end
  if indent > 0 then io.write(string.rep("  ",indent)) end
  io.write("}")
  if indent == 0 then io.write("\n") end
end
table.search = function(t,e)
  for i,v in pairs(t) do
    if v == e then
      return true,i
    end
  end
  for i=1,#t do
    if t[i] == e then
	  return true,i
	end
  end
  return false
end

string.stt = function(str,sep)
  if sep == nil then
    sep = " "
  end
  
  local res = {}
  local reg = string.format("([^%s]+)",sep)
  for i in string.gmatch(tostring(str),reg) do
    table.insert(res,i)
  end
  
  return res
end
string.clean = function(str)
  return string.gsub(str,"%s+","")
end
string.starts = function(str,substr)
   return string.sub(str,1,string.len(substr)) == substr
end
string.ends = function(str,substr)
   return string.sub(str,string.len(str)-string.len(substr)+1) == substr
end

fs.isFile = function(path)
  return (fs.exists(path) and not fs.isDir(path))
end

colors.success = colors.green
colors.error = colors.red
colors.info = colors.blue
colors.action = colors.yellow
colors.value = colors.yellow
colors.name = colors.cyan
colors.map = colors.orange
colors.cache = colors.orange
colors.path = colors.purple
colors.msg = colors.lightBlue
colors.chat = colors.gray

local colorNumberMap = table.protect({
	['0'] = colors.white,
	['1'] = colors.orange,
	['2'] = colors.magenta,
	['3'] = colors.lightBlue,
	['4'] = colors.yellow,
	['5'] = colors.lime,
	['6'] = colors.pink,
	['7'] = colors.gray,
	['8'] = colors.lightGray,
	['9'] = colors.cyan,
	['a'] = colors.purple,
	['b'] = colors.blue,
	['c'] = colors.brown,
	['d'] = colors.green,
	['e'] = colors.red,
	['f'] = colors.black
})
function colors.asColor(str)
  return colorNumberMap[string.lower(str)]
end

paintutils.loadAnim = function(path)
  local frames = {}
  local frame = {}
  
  if not fs.exists(path) then
    error("file path invalid")
  end
  
  local f = fs.open(path,"r")
  
  local l
  local tl = {}
  
  while true do
    l = f.readLine()
    if l == "~" or l == nil then
	  -- add frame to frames
	  table.insert(frames,frame)
	  frame = {}
	  
	  if l == nil then -- eof
	    break
	  end
	else
	  local pixelColor
	  for j=1,string.len(l) do
	    -- add char to line
		pixelColor = colors.asColor(string.sub(l,j,j))
		if pixelColor == nil then
		  pixelColor = term.getBackgroundColor()
		end
	    table.insert(tl,pixelColor)
	  end
	  
	  -- add line to frame
	  table.insert(frame,tl)
	  tl = {}
	end
  end
  
  f.close()
  
  return frames
end
paintutils.drawAnim = function(frames,x,y,delay,loop,terminal)
  if x == nil then
    x = 1
  end
  if y == nil then
    y = 1
  end
  if delay == nil then
    delay = .25
  end
  if loop == nil then
    loop = false
  end
  if terminal == nil then
    terminal = term.current()
  end
  
  while true do
    for i,frame in pairs(frames) do -- iterate through frames
	  paintutils.drawImage(frame,x,y,terminal) -- draw frame
	  sleep(delay)
	end
	if not loop then
	  break
	end
  end
end

folder = {}
folder.game = "game/"
folder.apis = folder.game.."apis/"
folder.root = "AppData/"
folder.map = folder.root.."maps/"
folder.bot = folder.root.."bots/"
folder = table.protect(folder)

term.w = function()
  local w,_ = term.getSize()
  return w
end
term.h = function()
  local _,h = term.getSize()
  return h
end

local nwrite = io.write
io.write = function(par,fgc,bgc,slow)  
  local tfgc = term.getTextColor()
  local tbgc = term.getBackgroundColor()
  
  if fgc ~= nil then term.setTextColor(fgc) end
  if bgc ~= nil then term.setBackgroundColor(bgc) end
  if par == nil then
    par = ""
  else
    par = tostring(par)
  end
  
  if not slow then nwrite(tostring(par))
  else textutils.slowWrite(tostring(par))
  end
  
  if fgc ~= nil then term.setTextColor(tfgc) end
  if bgc ~= nil then term.setBackgroundColor(tbgc) end
end


os.p = function()
  io.write("Press SPACE to continue.",colors.action)
  
  local e,c
  
  repeat
    e,c = os.pullEventRaw()
  until (e == "char" and c == " ") or e == "monitor_touch"
  
  local x,y = term.getCursorPos()
  term.clearLine()
  term.setCursorPos(1,y)
end
os.c = function()
  term.current().clear()
  term.current().setCursorPos(1,1)
end
os.lua = function()
  shell.run("lua")
end
