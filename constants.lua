--= Constants =--



THEWEBSITE = "TheSiteIsNotUpYet.lolz"

ChatBroadcastRadius = 10

MAXTURNS = 30
MAXMOVES = 6
MAXCOUNT = 5

MAXSLEEP = 2

SUCCESS = true
FAILURE = false

ON = true
OFF = false
SHOW = true
HIDE = false

MarkerTags = "Marker:1b,NoGravity:1b,CustomNameVisible:0b,Invisible:1b,"
TreasureMarkerName = "TreasureMarker"
ArenaMarkerName = "ArenaCorner"
TreasureEquipment = "[{},{},{},{},{id:gold_block,Count:1}]"
TurtleRaw = {
  Normal = "computercraft:CC-TurtleExpanded",
  Advanced = "computercraft:CC-TurtleAdvanced",
  Equipment = "leftUpgrade:\"computercraft:wireless_modem\",rightUpgrade:\"minecraft:diamond_sword\",label:\"Pirate Client\",dir:3,computerID:1,on:1b,leftUpgradeNBT:{active:1b}",
}
TurtleData = {
  Normal = TurtleRaw.Normal.." 0 replace {"..TurtleRaw.Equipment.."}",
  HasTreasure = TurtleRaw.Advanced.." 0 replace {"..TurtleRaw.Equipment.."}",
  Drunk = TurtleRaw.Advanced.." 0 replace {"..TurtleRaw.Equipment..",colorIndex:5}",
  Prot = TurtleRaw.Advanced.." 0 replace {"..TurtleRaw.Equipment..",colorIndex:0}",
}
Barrel = "SnowBall"

Defualts = {}
Defualts.treasure = {
  value = 0,
}
Defualts.pirate = {
  drunkTime = 0,
  attackCooldown = 0,
  vulnerableTime = 1,
  treasure = Defualts.treasure,
}

FirePower = 5
AttackCooldown = 4
DeffendCooldown = 4

TValueObjective = "TreasureValue"
ScoreObjective = "Score"

SeaLevel = 2

clickRespondTime = .01