--= Main Server =--



shell.run("update server")

dofile("rom/game/utils")

os.c()
io.write("Main Server "..versions.TCCAIC.."."..versions.Server.."\n",colors.yellow)
--shell.run("run map_1 a b c d")

local net = peripheral.wrap("top")
rednet.open("top")

if not fs.exists(folder.root) then
  fs.makeDir(folder.root)
end

shell.openTab("serverLog")
