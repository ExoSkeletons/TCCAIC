-- Update --



if http == nil then
  printError("HTTP is disabled.")
  return
end

local tArgs = {...}
if #tArgs < 1 then
  print("Usage: update server/pc")
  return
end
tArgs[1] = string.lower(tArgs[1])

local tfg = term.getTextColor()

local URL = "http://pastebin.com/raw/"

local req = {
  filename = "req",
  url = URL.."4sFhyLC9",
  handle = {},
  dat = {},
}

req.handle.new = http.get(req.url)
req.handle.old = fs.open(req.filename,"r")
req.dat.new = {}
req.dat.old = {}

if req.handle.new then -- load new req
  local l
  repeat
    l = req.handle.new.readLine()
	if l and l ~= "" and l:sub(1,1) ~= "#" then
	  if l:sub(1,1) == "%" then
	    p = l:gsub("%%","",1)
	  elseif p == tArgs[1] or p == "all" then
        table.insert(
	      req.dat.new,
	      { -- info table
	        path = l,                                  -- download path
            ver = tonumber(req.handle.new.readLine()), -- version
            code = req.handle.new.readLine(),          -- pastebin code
	      }
	    )
	  end
	end
  until l == nil
else
  printError("cannot connect to \""..URL.."\".")
  return
end
if req.handle.old then -- load old req
  local l
  repeat
    l = req.handle.old.readLine()
	if l and l ~= "" and l:sub(1,1) ~= "#" then
	  if l:sub(1,1) == "%" then
	    p = l:gsub("%%","",1)
	  elseif p == tArgs[1] or p == "all" then
        table.insert(
	      req.dat.old,
	      { -- info table
	        path = l,                                  -- download path
            ver = tonumber(req.handle.old.readLine()), -- version
            code = req.handle.old.readLine(),          -- pastebin code
	      }
	    )
	  end
	end
  until l == nil
end

-- remove old unused files
for _,old in pairs(req.dat.old) do
  local isReq = false
  for _,new in pairs(req.dat.new) do
    if new.path == old.path then
	  isReq = true
	  break
	end
  end
  if not isReq then
	fs.delete(old.path) -- delete old file
	term.setTextColor(colors.red)
	term.write("-Removed file ")
	term.setTextColor(colors.lightBlue)
	term.write(old.path)
	term.setTextColor(colors.red)
	print("")
  end
end
-- update old required files
for _,new in pairs(req.dat.new) do
  for _,old in pairs(req.dat.old) do
    if old.path == new.path and old.ver < new.ver then -- filepaths match and newer version detected
	  local h,err = http.get(URL..new.code) -- get new code
	  if h then
		if fs.exists(old.path) then     -- delete old file
	      fs.delete(old.path)
		end
	    local f = fs.open(new.path,"w") -- create new file
	    f.write(h.readAll())            -- write to file
	    f.close()
	    term.setTextColor(colors.orange)
	    term.write("*Updated file ")
	    term.setTextColor(colors.lightBlue)
	    term.write(old.path)
	    term.setTextColor(colors.orange)
	    print("")
	  else
	    printError("failed to update "..old.path..": "..err)
      end
	end
  end
end
-- add new required files
for _,new in pairs(req.dat.new) do
  local isNew = true
  for _,old in pairs(req.dat.old) do
    if new.path == old.path then
	  isNew = false
	  break
	end
  end
  if isNew then
    local h,err = http.get(URL..new.code) -- get new code
	if h then
	  local f = fs.open(new.path,"w") -- create new file
	  f.write(h.readAll())            -- write new code
	  f.close()
	  term.setTextColor(colors.green)
	  term.write("+Added file ")
	  term.setTextColor(colors.lightBlue)
	  term.write(new.path)
	  term.setTextColor(colors.green)
	  print("")
	else
	  printError("failed to download "..new.path..": "..err)
	end
  end
end

-- update old req file
if req.handle.new then
  req.handle.new.close()
end
if req.handle.old then
  req.handle.old.close()
end
req.handle.new = http.get(req.url)
req.handle.old = fs.open(req.filename,"w")     -- flush old req
req.handle.old.write(req.handle.new.readAll()) -- write new req

term.setTextColor(tfg)

-- close handles
req.handle.old.close()
req.handle.new.close()