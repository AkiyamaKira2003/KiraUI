-- Lua 5.3+ / Luau compatibility polyfills
if not math.ldexp then math.ldexp = function(x, n) return x * 2 ^ n end end
if not math.frexp then math.frexp = function(x)
    if x == 0 then return 0, 0 end
    local exp = math.floor(math.log(math.abs(x)) / math.log(2)) + 1
    local mantissa = x / 2 ^ exp
    return mantissa, exp
end end
if not loadstring and load then loadstring = load end
if not loadstring then loadstring = function(s) return load(s) end end

local tAkjrIRdq,ltAcELvGzk,ZVOoBlCEzTM,AbFsJOrE,oYANaOHUQcPs,BwoodiEAFu,EaksGWapyD,lvheOxWcCmfk,XplGtTryNLU,FPwbuFJZR,DfrqgXXsrB,bltBKQceuE,SGhakrAqt,bUXCKYzh,VSnWQoaPLJJ,SaBbjFyXo,GzYMiIXWDD,QSuGCcbnDyQ,YycneaNqxz,KcYuaOcsE,SVHPAEOaQ,butLjlkioU,ddVgCvfWHM,ZUTjSALmBd,llUtBaFau
tAkjrIRdq=assert;ltAcELvGzk=error;ZVOoBlCEzTM=ipairs;AbFsJOrE=next;oYANaOHUQcPs=pairs;BwoodiEAFu=pcall;EaksGWapyD=print;lvheOxWcCmfk=rawget;XplGtTryNLU=select;FPwbuFJZR=tonumber;DfrqgXXsrB=tostring;bltBKQceuE=xpcall;SGhakrAqt=math.abs;bUXCKYzh=math.floor;VSnWQoaPLJJ=math.huge;SaBbjFyXo=math.max;GzYMiIXWDD=math.min;QSuGCcbnDyQ=string.find;YycneaNqxz=string.lower;KcYuaOcsE=string.sub;SVHPAEOaQ=string.upper;butLjlkioU=table.concat;ddVgCvfWHM=table.insert;ZUTjSALmBd=table.sort;llUtBaFau=os.clock;
return (function()
--[[
    Kira Hub - Greedy Growers Script
    UI: Kira UI loaded from GitHub

    Ready now:
      - Kira UI loader
      - responsive UI through Kira UI
      - Auto Buy Seed via ProximityPrompt + wallet/cost validation
      - Auto Plant via ToggleEquip(hotbar/storage, index) + SeedType/ItemId verification
      - Weather-aware Auto Plant gate using CurrentWeather / WeatherService
      - Coordinator so planting and equipment-based tasks do not collide
      - PlantRound multiplier/death monitor + auto harvest/dead collection
      - Own-plot detection by OwnerUserId
      - Own-plot fruit name + mutation scanner
      - Auto mutation scan
      - Runtime cleanup when re-executed

    Adapter slots kept for later:
      - Server-side equip protocol (ToolService.ToggleEquip args)
      - Tree mature/dead detection
      - Plant-result verification
      - Harvest action
]]

--============================================================
-- KIRA UI LOADER
--============================================================

local ahrBAuuaAFi = tAkjrIRdq(loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/AkiyamaKira2003/KiraUI/refs/heads/main/KiraUI.lua"
)))()

if type(ahrBAuuaAFi) ~= "table"
    or type(ahrBAuuaAFi.CreateWindow) ~= "function" then

    ltAcELvGzk("[KiraHub] Invalid Kira UI library returned from URL")
end

--============================================================
-- SERVICES
--============================================================

local oLUBZcUVcgEG = game:GetService("Players")
local vwsoFVgmZ = game:GetService("ReplicatedStorage")

local dxLeYzjrD = oLUBZcUVcgEG.LocalPlayer
local vhsjTXIP = dxLeYzjrD:WaitForChild("PlayerGui")

--============================================================
-- OLD RUNTIME CLEANUP
-- Prevent duplicated loops/connections when script is rerun.
--============================================================

local JUUDRJUXiNbh = (getgenv and getgenv()) or _G

if JUUDRJUXiNbh.KiraGreedyGrowers and type(JUUDRJUXiNbh.KiraGreedyGrowers.Destroy) == "function" then
    BwoodiEAFu(function()
        JUUDRJUXiNbh.KiraGreedyGrowers:Destroy()
    end)
end

if JUUDRJUXiNbh.KiraGarden and type(JUUDRJUXiNbh.KiraGarden.Destroy) == "function" then
    BwoodiEAFu(function()
        JUUDRJUXiNbh.KiraGarden:Destroy()
    end)
end

local PKTqUhNlA = {Alive= true,
    Connections = {},
    HolderConnections = {},
    Window = nil,
}

JUUDRJUXiNbh.KiraGreedyGrowers = PKTqUhNlA
JUUDRJUXiNbh.KiraGarden = PKTqUhNlA

function PKTqUhNlA:Track(connection)
    if connection then
        table.insert(self.Connections, connection)
    end
    return connection
end

function PKTqUhNlA:Destroy()
    if not self.Alive then
        return
    end

    self.Alive = false

    if self.State then
        self.State.AutoBuy = false
        self.State.AutoPlant = false
        self.State.AutoHarvest = false
        self.State.AutoCollectDead = false
        self.State.AutoMutationScan = false
        self.State.AutoSellDeadTree = false
        self.State.AutoSellFruit = false
        self.State.AutoCollectFruit = false
        self.State.AutoCompostSeed = false
        self.State.AntiAfk = false
    end

    if self.DisableAntiAfk then
        BwoodiEAFu(self.DisableAntiAfk)
    end

    if self.StopAllFeatures then
        BwoodiEAFu(self.StopAllFeatures)
    end

    for _, connection in ZVOoBlCEzTM(self.Connections) do
        BwoodiEAFu(function()
            connection:Disconnect()
        end)
    end

    for _, RvcbuCAdxLIN in oYANaOHUQcPs(self.HolderConnections) do
        for _, connection in ZVOoBlCEzTM(RvcbuCAdxLIN) do
            BwoodiEAFu(function()
                connection:Disconnect()
            end)
        end
    end

    self.Connections = {}
    self.HolderConnections = {}

    if self.Window and self.Window.Gui and self.Window.Gui.Parent then
        BwoodiEAFu(function()
            self.Window.Gui:Destroy()
        end)
    end

    if JUUDRJUXiNbh.KiraGreedyGrowers == self then
        JUUDRJUXiNbh.KiraGreedyGrowers = nil
    end

    if JUUDRJUXiNbh.KiraGarden == self then
        JUUDRJUXiNbh.KiraGarden = nil
    end
end

--============================================================
-- GAME REFERENCES
--============================================================

local sWnyyWKj = vwsoFVgmZ
    .Packages
    ._Index["sleitnick_knit@1.6.0"]
    .knit

local KplnAOsvyjN = sWnyyWKj
    .Services
    .PlantRoundService
    .RF
    .StartRound

local hxVkjLkuFG = sWnyyWKj
    .Services
    .PlantRoundService
    .RF
    .CollectDeadTree

local HDDdNMSaA = sWnyyWKj
    .Services
    .ToolService
    .RE
    .ToggleEquip

local EbMWmSACcQ = sWnyyWKj
    .Services
    .DataService
    .RE
    .DataUpdate

local egNXrkSOdCn = nil
BwoodiEAFu(function()
    egNXrkSOdCn = sWnyyWKj
        .Services
        .SellStandService
        .RF
        .SellTree
end)

local UJwppRCtz = nil
BwoodiEAFu(function()
    UJwppRCtz = sWnyyWKj
        .Services
        .WeatherService
        .RE
        .WeatherChanged
end)

local LlgPhAFU =
    vwsoFVgmZ:FindFirstChild("CurrentWeather")
    or vwsoFVgmZ:WaitForChild("CurrentWeather", 5)

local UQqophNh = workspace:WaitForChild("BigField")
local xgfYDVTAxpy = UQqophNh:WaitForChild("ConveyorSeeds")
local cTVnIvMQRMZ = UQqophNh:WaitForChild("PlayerPlots")

--============================================================
-- STATE
--============================================================

local ibVEMhwTQRuM = {AutoBuy= false,
    AutoPlant = false,
    AutoHarvest = false,
    AutoCollectDead = true,
    AutoMutationScan = false,
    AutoSellDeadTree = false,
    AutoSellFruit = false,
    AutoCollectFruit = false,
    AutoCompostSeed = false,
    CollectAllFruit = false,
    AntiAfk = false,

    BuyRarity = "ALL",
    BuyRarities = {"ALL"},
    BuySeed = "ALL",
    BuySeeds = {"ALL"},
    BuyDelay = 0.15,

    PlantSeed = "Fig",
    PlantSeeds = {"Fig"},
    CompostSeed = "Oak",
    CompostSeeds = {"Oak"},
    Fertilizer = "Magic",
    UseWorm = false,
    WormTypes = {"Worm"},
    WormSortMode = "Lowest",
    WormMultiplierMin = 5,
    WormMultiplierMax = 10,
    WormSettingsLocked = true,
    WormTypesLocked = true,
    WormPriorityLocked = true,
    WormSettings = {},
    AllowMutatedSeeds = true,
    PlantOnlyDuringWeather = false,

    HarvestMultiplier = 20,
    HarvestMultiplierLocked = true,
    HarvestMultipliers = {},
    PlantRoundScanInterval = 0.08,
    SellDelay = 0.15,
    CompostDelay = 0.25,
    MinFruitMutations = 5,
    FruitCollectInterval = 1,
    FruitCollectDelay = 0.1,

    MutationScanInterval = 2,
    Debug = false,
}

PKTqUhNlA.State = ibVEMhwTQRuM

local euyMjRhaK = {Phase= "IDLE",
    Status = "Starting...",
    MyPlot = nil,
    PurchaseCount = 0,
    PlantCount = 0,
    FruitListedCount = 0,
    LastPlantContext = nil,
    LastPurchase = nil,
    LastInventorySource = "none",

    HarvestCount = 0,
    DeadCollectCount = 0,
    FruitCollectCount = 0,
    LastCollectedFruit = nil,
    LastHarvest = nil,
    SellDeadTreeCount = 0,
    LastSoldDeadTree = nil,
    SellFruitCount = 0,
    LastSoldFruit = nil,
    CompostCount = 0,
    CompostGiveCount = 0,
    CompostCollectCount = 0,
    CompostTeleportCount = 0,
    CompostDistance = 0,
    CompostMode = "UNKNOWN",
    CompostAnchor = nil,
    CompostPrompt = nil,
    CompostAnchorPrompt = nil,
    LastCompostSeed = nil,
    LastCompostAction = nil,
    LastCompostLeashNotice = 0,
    WormCount = 0,
    LastWormSource = "none",
    LastUsedWorm = nil,
    CurrentPlantRound = nil,
    CurrentMultiplier = 0,
    CurrentSeed = nil,
    CurrentHarvestTarget = 20,
    CurrentWeather = "Normal",
    WeatherActive = false,
    AntiAfkMode = "off",
    AntiAfkDisabledCount = 0,
}

PKTqUhNlA.Runtime = euyMjRhaK

local RLYSHrriuiBl = {
    "Basic",
    "Better",
    "Premium",
    "Super",
    "Magic",
}


-- Complete seed catalog + prices supplied from the in-game seed shop.
local qrOkZyKh = {
    {Name= "Apple",        PriceText = "$200"},
    {Name= "Avocado",      PriceText = "$20K"},
    {Name= "Banana",       PriceText = "$3B"},
    {Name= "Blooming",     PriceText = "$750B"},
    {Name= "Cherry",       PriceText = "$2.50M"},
    {Name= "Coconut",      PriceText = "$10M"},
    {Name= "Diamond",      PriceText = "$1Qi"},
    {Name= "Dragon Fruit", PriceText = "$7B"},
    {Name= "Elder",        PriceText = "$5Oc"},
    {Name= "Fig",          PriceText = "$500"},
    {Name= "Glowing",      PriceText = "$500B"},
    {Name= "Glowshroom",   PriceText = "$3.50Oc"},
    {Name= "Lemon",        PriceText = "$15K"},
    {Name= "Magic",        PriceText = "$500T"},
    {Name= "Mango",        PriceText = "$5M"},
    {Name= "Money",        PriceText = "$14Sx"},
    {Name= "Mushroom",     PriceText = "$7Sx"},
    {Name= "Oak",          PriceText = "Free"},
    {Name= "Orange",       PriceText = "$10K"},
    {Name= "Peach",        PriceText = "$350"},
    {Name= "Pine",         PriceText = "$25"},
    {Name= "Pizza",        PriceText = "$850T"},
    {Name= "Starfruit",    PriceText = "$4.50B"},
    {Name= "Void",         PriceText = "$1.75Qi"},
}

local MKjocGYu = {}
local tqxPJvMCxC = {}
local SwXZMPqV = {}
local BMBjiIBTo = {"ALL"}
local ePXrjpkrf = {}
local ESIHFmWdFau = {}
local ITzawOckSLt = {}
local HKJosaZrHScv = {}

local fzMNsCGQ = {
    "COMMON",
    "UNCOMMON",
    "RARE",
    "EPIC",
    "LEGENDARY",
    "MYTHIC",
}

local dmbppbxeQ = {"ALL"}
local PGBvtZsGLC = {}

for LvOjTWuqYW, KJQdzwwjQOsx in ZVOoBlCEzTM(fzMNsCGQ) do
    PGBvtZsGLC[KJQdzwwjQOsx] = LvOjTWuqYW
    dmbppbxeQ[#dmbppbxeQ + 1] = KJQdzwwjQOsx
end

local WMAKOxdVMPqh = {
    [""] = 1,
    k = 1e3,
    m = 1e6,
    b = 1e9,
    t = 1e12,
    q = 1e15,
    qa = 1e15,
    qi = 1e18,
    sx = 1e21,
    sp = 1e24,
    oc = 1e27,
    no = 1e30,
    dc = 1e33,
    de = 1e33,
}

local function VcHKPCEOMcp(QtoBGFWIF)
    QtoBGFWIF = DfrqgXXsrB(QtoBGFWIF or "")
    QtoBGFWIF = QtoBGFWIF:gsub("<.->", "")
    QtoBGFWIF = QtoBGFWIF:gsub(",", "")
    QtoBGFWIF = QtoBGFWIF:gsub("%s+", "")

    if QtoBGFWIF == "" then
        return nil
    end

    local mGrFPvGieJAk = string.lower(QtoBGFWIF)

    if mGrFPvGieJAk == "free"
        or string.find(mGrFPvGieJAk, "free", 1, true) then
        return 0
    end

    QtoBGFWIF = QtoBGFWIF:gsub("[%$€£¥]", "")

    local pQvnqyZnr, jfWmUADzLmk =
        QtoBGFWIF:match("([%+%-]?[%d%.]+)([%a]*)")

    local ERQNGrtnl = FPwbuFJZR(pQvnqyZnr)

    if not ERQNGrtnl then
        return nil
    end

    local MxRPMdGNQWn =
        WMAKOxdVMPqh[string.lower(DfrqgXXsrB(jfWmUADzLmk or ""))]

    if not MxRPMdGNQWn then
        return nil
    end

    return ERQNGrtnl * MxRPMdGNQWn
end

local function djMtGYIoe(DhaBjHwh)
    return HKJosaZrHScv[DfrqgXXsrB(DhaBjHwh or "")]
        or math.huge
end

local function cblgbjKYmINB(a, b)
    local VumrEGrN = DfrqgXXsrB(a or "")
    local TuhrRGzvUd = DfrqgXXsrB(b or "")
    local oYyToIKdKZO = djMtGYIoe(VumrEGrN)
    local kdoGYzSwtx = djMtGYIoe(TuhrRGzvUd)

    if oYyToIKdKZO ~= kdoGYzSwtx then
        return oYyToIKdKZO < kdoGYzSwtx
    end

    return VumrEGrN < TuhrRGzvUd
end

local function lDrsWJKe(a, b)
    return cblgbjKYmINB(
        ePXrjpkrf[DfrqgXXsrB(a or "")] or a,
        ePXrjpkrf[DfrqgXXsrB(b or "")] or b
    )
end

for _, seed in ZVOoBlCEzTM(qrOkZyKh) do
    local ROxVchvm = seed.Name .. " Seed (" .. seed.PriceText .. ")"

    MKjocGYu[#MKjocGYu + 1] = seed.Name
    tqxPJvMCxC[#tqxPJvMCxC + 1] = ROxVchvm
    SwXZMPqV[#SwXZMPqV + 1] = ROxVchvm
    BMBjiIBTo[#BMBjiIBTo + 1] = ROxVchvm
    ePXrjpkrf[ROxVchvm] = seed.Name
    ESIHFmWdFau[seed.Name] = ROxVchvm
    ITzawOckSLt[seed.Name] = seed.PriceText
    HKJosaZrHScv[seed.Name] = VcHKPCEOMcp(seed.PriceText)
end

table.sort(MKjocGYu, cblgbjKYmINB)
table.sort(tqxPJvMCxC, lDrsWJKe)
table.sort(SwXZMPqV, lDrsWJKe)
table.sort(BMBjiIBTo, function(a, b)
    if a == b then
        return false
    elseif a == "ALL" then
        return true
    elseif b == "ALL" then
        return false
    end

    return lDrsWJKe(a, b)
end)

local function nvOpXnTaTpp(BNnGQGeIA)
    local jonwukNNT = {}

    for _, XUWueugAwuSw in ZVOoBlCEzTM(BNnGQGeIA or {}) do
        jonwukNNT[#jonwukNNT + 1] = XUWueugAwuSw
    end

    return jonwukNNT
end

local function XQlTufcFzRad(BNnGQGeIA)
    if type(BNnGQGeIA) ~= "table" then
        BNnGQGeIA = BNnGQGeIA == nil and {} or {BNnGQGeIA}
    end

    local jonwukNNT = {}
    local QZYVNgIzkz = {}
    local TwEMslBkyWZ = false

    for _, XUWueugAwuSw in ZVOoBlCEzTM(BNnGQGeIA) do
        local QtoBGFWIF = DfrqgXXsrB(XUWueugAwuSw or "")

        if QtoBGFWIF == "ALL" then
            TwEMslBkyWZ = true
            break
        end

        local DhaBjHwh = ePXrjpkrf[QtoBGFWIF] or QtoBGFWIF

        if DhaBjHwh ~= ""
            and ESIHFmWdFau[DhaBjHwh]
            and not QZYVNgIzkz[DhaBjHwh] then

            QZYVNgIzkz[DhaBjHwh] = true
            jonwukNNT[#jonwukNNT + 1] = DhaBjHwh
        end
    end

    if TwEMslBkyWZ then
        jonwukNNT = nvOpXnTaTpp(MKjocGYu)
    end

    table.sort(jonwukNNT, cblgbjKYmINB)
    return jonwukNNT
end

local function cMtFJivxtN(BNnGQGeIA)
    ibVEMhwTQRuM.BuySeeds = XQlTufcFzRad(BNnGQGeIA)
    ibVEMhwTQRuM.BuySeed =
        #ibVEMhwTQRuM.BuySeeds == #MKjocGYu
        and "ALL"
        or (ibVEMhwTQRuM.BuySeeds[1] or "NONE")

    return nvOpXnTaTpp(ibVEMhwTQRuM.BuySeeds)
end

local function BKheSqKQSiI()
    if type(ibVEMhwTQRuM.BuySeeds) ~= "table" then
        return cMtFJivxtN(ibVEMhwTQRuM.BuySeed or "ALL")
    end

    return XQlTufcFzRad(ibVEMhwTQRuM.BuySeeds)
end

local function yhyrfMddESAN(BNnGQGeIA)
    local vPMLceeu = {}

    for _, DhaBjHwh in ZVOoBlCEzTM(XQlTufcFzRad(BNnGQGeIA)) do
        vPMLceeu[#vPMLceeu + 1] = ESIHFmWdFau[DhaBjHwh] or DhaBjHwh
    end

    return vPMLceeu
end

local function AyxJZxZvpa()
    local otMRsdmAPve = BKheSqKQSiI()

    if #otMRsdmAPve == #MKjocGYu then
        return "all seeds"
    elseif #otMRsdmAPve == 0 then
        return "no seeds selected"
    end

    return table.concat(otMRsdmAPve, ", ")
end

local function WMJXgCkxL(BNnGQGeIA)
    if type(BNnGQGeIA) ~= "table" then
        BNnGQGeIA = BNnGQGeIA == nil and {} or {BNnGQGeIA}
    end

    local jonwukNNT = {}
    local QZYVNgIzkz = {}
    local TwEMslBkyWZ = false

    for _, XUWueugAwuSw in ZVOoBlCEzTM(BNnGQGeIA) do
        local KJQdzwwjQOsx = string.upper(DfrqgXXsrB(XUWueugAwuSw or ""))

        if KJQdzwwjQOsx == "ALL" then
            TwEMslBkyWZ = true
            break
        end

        if PGBvtZsGLC[KJQdzwwjQOsx] and not QZYVNgIzkz[KJQdzwwjQOsx] then
            QZYVNgIzkz[KJQdzwwjQOsx] = true
            jonwukNNT[#jonwukNNT + 1] = KJQdzwwjQOsx
        end
    end

    if TwEMslBkyWZ then
        jonwukNNT = nvOpXnTaTpp(fzMNsCGQ)
    end

    table.sort(jonwukNNT, function(a, b)
        return (PGBvtZsGLC[a] or math.huge)
            < (PGBvtZsGLC[b] or math.huge)
    end)

    return jonwukNNT
end

local function QOGIdmUgLGgH(BNnGQGeIA)
    ibVEMhwTQRuM.BuyRarities = WMJXgCkxL(BNnGQGeIA)
    ibVEMhwTQRuM.BuyRarity =
        #ibVEMhwTQRuM.BuyRarities == #fzMNsCGQ
        and "ALL"
        or (ibVEMhwTQRuM.BuyRarities[1] or "NONE")

    return nvOpXnTaTpp(ibVEMhwTQRuM.BuyRarities)
end

local function caURwNsUKyWo()
    if type(ibVEMhwTQRuM.BuyRarities) ~= "table" then
        return QOGIdmUgLGgH(ibVEMhwTQRuM.BuyRarity or "ALL")
    end

    return WMJXgCkxL(ibVEMhwTQRuM.BuyRarities)
end

local function OObSspcJge()
    local otMRsdmAPve = caURwNsUKyWo()

    if #otMRsdmAPve == #fzMNsCGQ then
        return "all rarities"
    elseif #otMRsdmAPve == 0 then
        return "no rarities selected"
    end

    return table.concat(otMRsdmAPve, ", ")
end

local function sctjttTck(BNnGQGeIA, fallbackSeed)
    if type(BNnGQGeIA) ~= "table" then
        BNnGQGeIA = BNnGQGeIA == nil and {} or {BNnGQGeIA}
    end

    local jonwukNNT = {}
    local QZYVNgIzkz = {}

    for _, XUWueugAwuSw in ZVOoBlCEzTM(BNnGQGeIA) do
        local QtoBGFWIF = DfrqgXXsrB(XUWueugAwuSw or "")
        local DhaBjHwh = ePXrjpkrf[QtoBGFWIF] or QtoBGFWIF

        if DhaBjHwh ~= ""
            and ESIHFmWdFau[DhaBjHwh]
            and not QZYVNgIzkz[DhaBjHwh] then

            QZYVNgIzkz[DhaBjHwh] = true
            jonwukNNT[#jonwukNNT + 1] = DhaBjHwh
        end
    end

    if #jonwukNNT == 0 and fallbackSeed then
        jonwukNNT[1] = fallbackSeed == true and (ibVEMhwTQRuM.PlantSeed or "Fig") or fallbackSeed
    end

    table.sort(jonwukNNT, cblgbjKYmINB)

    return jonwukNNT
end

local function xvfaxgVJgb(BNnGQGeIA)
    ibVEMhwTQRuM.PlantSeeds = sctjttTck(BNnGQGeIA)
    ibVEMhwTQRuM.PlantSeed = ibVEMhwTQRuM.PlantSeeds[1] or ibVEMhwTQRuM.PlantSeed
    return nvOpXnTaTpp(ibVEMhwTQRuM.PlantSeeds)
end

local function RyYbdTkwDtE()
    if type(ibVEMhwTQRuM.PlantSeeds) ~= "table" then
        return xvfaxgVJgb({ibVEMhwTQRuM.PlantSeed or "Fig"})
    end

    return nvOpXnTaTpp(ibVEMhwTQRuM.PlantSeeds)
end

local function KMlaDNlrszI(BNnGQGeIA)
    local vPMLceeu = {}

    for _, DhaBjHwh in ZVOoBlCEzTM(sctjttTck(BNnGQGeIA)) do
        vPMLceeu[#vPMLceeu + 1] = ESIHFmWdFau[DhaBjHwh] or DhaBjHwh
    end

    return vPMLceeu
end

local function XkuqAzFB(BNnGQGeIA)
    return sctjttTck(BNnGQGeIA)
end

local function ivsIiUzIw(BNnGQGeIA)
    ibVEMhwTQRuM.CompostSeeds =
        sctjttTck(
            BNnGQGeIA,
            ibVEMhwTQRuM.CompostSeed or "Oak"
        )
    ibVEMhwTQRuM.CompostSeed =
        ibVEMhwTQRuM.CompostSeeds[1]
        or ibVEMhwTQRuM.CompostSeed
        or "Oak"
    return nvOpXnTaTpp(ibVEMhwTQRuM.CompostSeeds)
end

local function XuodfQsedbd()
    if type(ibVEMhwTQRuM.CompostSeeds) ~= "table" then
        return ivsIiUzIw({ibVEMhwTQRuM.CompostSeed or "Oak"})
    end

    return nvOpXnTaTpp(ibVEMhwTQRuM.CompostSeeds)
end

local function vAvhLYicjXw(BNnGQGeIA)
    local vPMLceeu = {}

    for _, DhaBjHwh in ZVOoBlCEzTM(sctjttTck(BNnGQGeIA)) do
        vPMLceeu[#vPMLceeu + 1] = ESIHFmWdFau[DhaBjHwh] or DhaBjHwh
    end

    return vPMLceeu
end

local function vfTaHKJkC(BNnGQGeIA)
    return sctjttTck(BNnGQGeIA)
end

local function cXqsYNhLLg()
    local otMRsdmAPve = XuodfQsedbd()

    if #otMRsdmAPve == 0 then
        return "no seeds selected"
    end

    return table.concat(otMRsdmAPve, ", ")
end

cMtFJivxtN(ibVEMhwTQRuM.BuySeeds or ibVEMhwTQRuM.BuySeed or "ALL")
QOGIdmUgLGgH(ibVEMhwTQRuM.BuyRarities or ibVEMhwTQRuM.BuyRarity or "ALL")
xvfaxgVJgb(ibVEMhwTQRuM.PlantSeeds or {ibVEMhwTQRuM.PlantSeed or "Fig"})
ivsIiUzIw(ibVEMhwTQRuM.CompostSeeds or {ibVEMhwTQRuM.CompostSeed or "Oak"})

local function oyZlEENU(XUWueugAwuSw, hVKRNUmvaW)
    local QtoBGFWIF = DfrqgXXsrB(XUWueugAwuSw or "")
    local pQvnqyZnr =
        QtoBGFWIF:match("%-?%d+%.?%d*")
        or QtoBGFWIF:match("%-?%.%d+")

    local ERQNGrtnl =
        FPwbuFJZR(pQvnqyZnr)
        or FPwbuFJZR(hVKRNUmvaW)
        or FPwbuFJZR(ibVEMhwTQRuM.HarvestMultiplier)
        or 20

    ERQNGrtnl = math.max(0.01, ERQNGrtnl)
    return math.floor(ERQNGrtnl * 100 + 0.5) / 100
end

local function BmAHDGzgYbNu(XUWueugAwuSw)
    ibVEMhwTQRuM.HarvestMultiplier =
        oyZlEENU(XUWueugAwuSw, ibVEMhwTQRuM.HarvestMultiplier)

    euyMjRhaK.CurrentHarvestTarget = ibVEMhwTQRuM.HarvestMultiplier
    return ibVEMhwTQRuM.HarvestMultiplier
end

local function PyoJDKby(BNnGQGeIA)
    local jonwukNNT = {}

    for eRdipkcQbcnW, XUWueugAwuSw in oYANaOHUQcPs(BNnGQGeIA or {}) do
        local DhaBjHwh = DfrqgXXsrB(eRdipkcQbcnW or "")

        if ESIHFmWdFau[DhaBjHwh] then
            jonwukNNT[DhaBjHwh] =
                oyZlEENU(
                    XUWueugAwuSw,
                    ibVEMhwTQRuM.HarvestMultiplier
                )
        end
    end

    return jonwukNNT
end

local function XLZYOtQEIi(XUWueugAwuSw)
    if type(XUWueugAwuSw) == "table" then
        if XUWueugAwuSw.Locked ~= nil then
            ibVEMhwTQRuM.HarvestMultiplierLocked = XUWueugAwuSw.Locked == true
        end

        BmAHDGzgYbNu(XUWueugAwuSw.Shared or XUWueugAwuSw.Default)

        if type(XUWueugAwuSw.Values) == "table" then
            ibVEMhwTQRuM.HarvestMultipliers =
                PyoJDKby(XUWueugAwuSw.Values)
        end
    else
        BmAHDGzgYbNu(XUWueugAwuSw)
    end

    return {Locked= ibVEMhwTQRuM.HarvestMultiplierLocked,
        Shared = ibVEMhwTQRuM.HarvestMultiplier,
        Values = PyoJDKby(ibVEMhwTQRuM.HarvestMultipliers),
    }
end

local function DGUSmiSQl(DhaBjHwh)
    local tpSFmqQNLSF =
        oyZlEENU(
            ibVEMhwTQRuM.HarvestMultiplier,
            20
        )

    if ibVEMhwTQRuM.HarvestMultiplierLocked then
        return tpSFmqQNLSF
    end

    DhaBjHwh = DfrqgXXsrB(DhaBjHwh or "")
    return oyZlEENU(
        ibVEMhwTQRuM.HarvestMultipliers[DhaBjHwh],
        tpSFmqQNLSF
    )
end

local function wTksbWBOfVL()
    local aXYrwpDekZCq = {}
    local otMRsdmAPve = RyYbdTkwDtE()

    table.sort(otMRsdmAPve, cblgbjKYmINB)

    for _, DhaBjHwh in ZVOoBlCEzTM(otMRsdmAPve) do
        aXYrwpDekZCq[#aXYrwpDekZCq + 1] = {Key= DhaBjHwh,
            Text = ESIHFmWdFau[DhaBjHwh] or DhaBjHwh,
        }
    end

    return aXYrwpDekZCq
end

local function rdYzIypaIF()
    if ibVEMhwTQRuM.HarvestMultiplierLocked then
        return "locked at " .. DfrqgXXsrB(ibVEMhwTQRuM.HarvestMultiplier) .. "x"
    end

    return "custom per seed"
end

XLZYOtQEIi({Locked= ibVEMhwTQRuM.HarvestMultiplierLocked,
    Shared = ibVEMhwTQRuM.HarvestMultiplier,
    Values = ibVEMhwTQRuM.HarvestMultipliers,
})

--============================================================
-- ADAPTERS FOR DATA YOU WILL PROVIDE LATER
--============================================================

local LLTinptsjcFz = {
    -- Optional extra verification after the built-in PlantRound detector
    -- confirms that StartRound created a new round.
    -- function(context) -> true / false / nil
    VerifyPlant = nil,
}

PKTqUhNlA.Adapters = LLTinptsjcFz

--============================================================
-- UI SAFE HELPERS
--============================================================

local function wJyAtKFRpbz(...)
    if ibVEMhwTQRuM.Debug then
        EaksGWapyD("[KiraHub]", ...)
    end
end

local function foUSPDNDz(QtoBGFWIF, tone)
    euyMjRhaK.Status = DfrqgXXsrB(QtoBGFWIF or "")
    if PKTqUhNlA.Window then
        PKTqUhNlA.Window:SetStatus(euyMjRhaK.Status, tone)
    end
    wJyAtKFRpbz(euyMjRhaK.Status)
end

local function HXuhwCIQZAB(QtoBGFWIF, tone)
    euyMjRhaK.Phase = DfrqgXXsrB(QtoBGFWIF or "IDLE")
    if PKTqUhNlA.Window then
        PKTqUhNlA.Window:SetPhase(euyMjRhaK.Phase, tone)
    end
end

local function AoDYQAJZTEZM(title, QtoBGFWIF, tone, duration)
    if PKTqUhNlA.Window
        and type(PKTqUhNlA.Window.Notify) == "function" then

        PKTqUhNlA.Window:Notify({Title= title or "Kira Hub",
            Text = DfrqgXXsrB(QtoBGFWIF or ""),
            Tone = tone,
            Duration = duration,
        })
    end
end

--============================================================
-- ANTI-AFK
--============================================================

local dLeIFYjISzv = {Connection= nil,
    DisabledConnections = {},
}

local function wvQAurwsLo(connection, methodName)
    local uPirkaZfGG, PcjiroTtNDGI = BwoodiEAFu(function()
        return connection[methodName]
    end)

    if uPirkaZfGG and type(PcjiroTtNDGI) == "function" then
        return PcjiroTtNDGI
    end

    return nil
end

local function oCrdbSreuG()
    if dLeIFYjISzv.Connection then
        BwoodiEAFu(function()
            dLeIFYjISzv.Connection:Disconnect()
        end)
    end

    dLeIFYjISzv.Connection = nil
end

local function SpIcSRilxYM()
    for _, connection in ZVOoBlCEzTM(dLeIFYjISzv.DisabledConnections) do
        local qEYPbXRDcc = wvQAurwsLo(connection, "Enable")

        if qEYPbXRDcc then
            BwoodiEAFu(function()
                qEYPbXRDcc(connection)
            end)
        end
    end

    dLeIFYjISzv.DisabledConnections = {}
end

local function QMnDLYrVkq()
    local uPirkaZfGG, oawJCBFNb = BwoodiEAFu(function()
        return game:GetService("VirtualUser")
    end)

    if not uPirkaZfGG or not oawJCBFNb then
        return
    end

    BwoodiEAFu(function()
        oawJCBFNb:CaptureController()
        oawJCBFNb:ClickButton2(Vector2.new())
    end)
end

local function kjpOqSXBa()
    oCrdbSreuG()
    SpIcSRilxYM()

    local WSWLxRnrR = 0
    local ldBeAOtoW = getconnections or get_signal_cons

    if type(ldBeAOtoW) == "function" then
        local uPirkaZfGG, RvcbuCAdxLIN =
            BwoodiEAFu(function()
                return ldBeAOtoW(dxLeYzjrD.Idled)
            end)

        if uPirkaZfGG and type(RvcbuCAdxLIN) == "table" then
            for _, connection in oYANaOHUQcPs(RvcbuCAdxLIN) do
                local gGegChxnwnu =
                    wvQAurwsLo(connection, "Disable")
                local qEYPbXRDcc =
                    wvQAurwsLo(connection, "Enable")

                if connection
                    and gGegChxnwnu
                    and qEYPbXRDcc then

                    local EatGthUsLRZQ = BwoodiEAFu(function()
                        gGegChxnwnu(connection)
                    end)

                    if EatGthUsLRZQ then
                        WSWLxRnrR += 1
                        table.insert(
                            dLeIFYjISzv.DisabledConnections,
                            connection
                        )
                    end
                end
            end
        end
    end

    dLeIFYjISzv.Connection =
        dxLeYzjrD.Idled:Connect(function()
            QMnDLYrVkq()
        end)

    euyMjRhaK.AntiAfkDisabledCount = WSWLxRnrR
    euyMjRhaK.AntiAfkMode =
        WSWLxRnrR > 0
        and "idle guard + click"
        or "idle click"
end

local function WFtZRMBScv()
    oCrdbSreuG()
    SpIcSRilxYM()

    euyMjRhaK.AntiAfkDisabledCount = 0
    euyMjRhaK.AntiAfkMode = "off"

    if ibVEMhwTQRuM then
        ibVEMhwTQRuM.AntiAfk = false
    end
end

PKTqUhNlA.DisableAntiAfk = WFtZRMBScv

local function vHRPUjRYZUZk(mnlJbSzzP, silent)
    ibVEMhwTQRuM.AntiAfk = mnlJbSzzP == true

    if ibVEMhwTQRuM.AntiAfk then
        kjpOqSXBa()

        if not silent then
            foUSPDNDz("Anti-AFK enabled")
        end
    else
        WFtZRMBScv()

        if not silent then
            foUSPDNDz("Anti-AFK disabled")
        end
    end
end

--============================================================
-- FEATURE GENERATIONS
--============================================================

local tFzXKhTXs = {}

local function PxzWtllXIL(CRwBIXohMQ)
    tFzXKhTXs[CRwBIXohMQ] = (tFzXKhTXs[CRwBIXohMQ] or 0) + 1
end

local function nFPpZjLd(CRwBIXohMQ, runner)
    tFzXKhTXs[CRwBIXohMQ] = (tFzXKhTXs[CRwBIXohMQ] or 0) + 1
    local OUYXhMYnTP = tFzXKhTXs[CRwBIXohMQ]

    task.spawn(function()
        local function lSSAtRsxOpy()
            return (not PKTqUhNlA.Alive) or tFzXKhTXs[CRwBIXohMQ] ~= OUYXhMYnTP
        end

        local uPirkaZfGG, ujxUlzok = bltBKQceuE(function()
            runner(lSSAtRsxOpy)
        end, debug.traceback)

        if not uPirkaZfGG and PKTqUhNlA.Alive then
            warn("[KiraHub:" .. DfrqgXXsrB(CRwBIXohMQ) .. "]", ujxUlzok)
        end
    end)
end

local function pQFNwZAvvQA(seconds, lSSAtRsxOpy)
    local QHmwcvVZcPU = os.clock() + math.max(0, FPwbuFJZR(seconds) or 0)

    while os.clock() < QHmwcvVZcPU do
        if lSSAtRsxOpy and lSSAtRsxOpy() then
            return false
        end
        task.wait(math.min(0.05, math.max(0.01, QHmwcvVZcPU - os.clock())))
    end

    return true
end

--============================================================
-- WEATHER STATE
--============================================================

local function LXQesoUbwMC(XUWueugAwuSw)
    local QtoBGFWIF = DfrqgXXsrB(XUWueugAwuSw or "")
    QtoBGFWIF = QtoBGFWIF:match("^%s*(.-)%s*$") or ""

    if QtoBGFWIF == "" then
        return "Normal"
    end

    return QtoBGFWIF
end

local function oKEHLRBQYmx(XUWueugAwuSw)
    return string.lower(LXQesoUbwMC(XUWueugAwuSw)) ~= "normal"
end

local function DEGvWhkAYo(XUWueugAwuSw)
    local CSJzVWFOz = LXQesoUbwMC(XUWueugAwuSw)

    euyMjRhaK.CurrentWeather = CSJzVWFOz
    euyMjRhaK.WeatherActive = oKEHLRBQYmx(CSJzVWFOz)

    return euyMjRhaK.CurrentWeather, euyMjRhaK.WeatherActive
end

local function dHqyhbRECjo()
    local XUWueugAwuSw = nil

    if LlgPhAFU then
        BwoodiEAFu(function()
            XUWueugAwuSw = LlgPhAFU.Value
        end)
    end

    return DEGvWhkAYo(XUWueugAwuSw)
end

local function ZtkuZoIr()
    local CSJzVWFOz, UnCMwRYd = dHqyhbRECjo()

    if not ibVEMhwTQRuM.PlantOnlyDuringWeather then
        return true, CSJzVWFOz
    end

    return UnCMwRYd, CSJzVWFOz
end

local function tZYyGNtS(lSSAtRsxOpy)
    if not ibVEMhwTQRuM.PlantOnlyDuringWeather then
        return true
    end

    local IHaByJlryk = nil

    while PKTqUhNlA.Alive
        and ibVEMhwTQRuM.AutoPlant
        and not lSSAtRsxOpy() do

        if not ibVEMhwTQRuM.PlantOnlyDuringWeather then
            return true
        end

        local UnCMwRYd, CSJzVWFOz = ZtkuZoIr()

        if UnCMwRYd then
            foUSPDNDz(
                "Weather active: "
                    .. CSJzVWFOz
                    .. "; planting allowed"
            )
            return true
        end

        if CSJzVWFOz ~= IHaByJlryk then
            HXuhwCIQZAB("WAIT WEATHER", "warning")
            foUSPDNDz(
                "Waiting for weather before planting (current: "
                    .. CSJzVWFOz
                    .. ")",
                "warning"
            )
            IHaByJlryk = CSJzVWFOz
        end

        if not pQFNwZAvvQA(0.25, lSSAtRsxOpy) then
            return false
        end
    end

    return false
end

dHqyhbRECjo()

if UJwppRCtz and UJwppRCtz.OnClientEvent then
    PKTqUhNlA:Track(UJwppRCtz.OnClientEvent:Connect(function(CSJzVWFOz)
        local nwooXzdW = euyMjRhaK.CurrentWeather
        local jIsUVHAQEx, UnCMwRYd = DEGvWhkAYo(CSJzVWFOz)

        if jIsUVHAQEx ~= nwooXzdW
            and ibVEMhwTQRuM.AutoPlant
            and ibVEMhwTQRuM.PlantOnlyDuringWeather then

            if UnCMwRYd then
                foUSPDNDz("Weather active: " .. jIsUVHAQEx)
            else
                foUSPDNDz(
                    "Weather ended; next plant waits for weather",
                    "warning"
                )
            end
        end
    end))
end

if LlgPhAFU then
    PKTqUhNlA:Track(LlgPhAFU:GetPropertyChangedSignal("Value"):Connect(function()
        local nwooXzdW = euyMjRhaK.CurrentWeather
        local jIsUVHAQEx, UnCMwRYd = dHqyhbRECjo()

        if jIsUVHAQEx ~= nwooXzdW
            and ibVEMhwTQRuM.AutoPlant
            and ibVEMhwTQRuM.PlantOnlyDuringWeather then

            if UnCMwRYd then
                foUSPDNDz("Weather active: " .. jIsUVHAQEx)
            else
                foUSPDNDz(
                    "Weather ended; next plant waits for weather",
                    "warning"
                )
            end
        end
    end))
end

local function bQLHthvj()
    PxzWtllXIL("AutoBuy")
    PxzWtllXIL("AutoPlant")
    PxzWtllXIL("AutoSellDeadTree")
    PxzWtllXIL("AutoSellFruit")
    PxzWtllXIL("AutoCollectFruit")
    PxzWtllXIL("AutoCompostSeed")
    PxzWtllXIL("CompostMovementGuard")
    PxzWtllXIL("AutoMutationScan")
    PxzWtllXIL("RoundMonitor")
    PxzWtllXIL("ManualPlant")
end

PKTqUhNlA.StopAllFeatures = bQLHthvj

--============================================================
-- MUTEX
--============================================================

local GouULHoGsWxF = {}
GouULHoGsWxF.__index = GouULHoGsWxF

function GouULHoGsWxF.new(CRwBIXohMQ)
    return setmetatable({Name= CRwBIXohMQ,
        Owner = nil,
    }, GouULHoGsWxF)
end

function GouULHoGsWxF:Acquire(owner, lSSAtRsxOpy, timeout)
    local lqYddjmpEbqG = os.clock()

    while PKTqUhNlA.Alive and self.Owner ~= nil and self.Owner ~= owner do
        if lSSAtRsxOpy and lSSAtRsxOpy() then
            return false
        end

        if timeout and (os.clock() - lqYddjmpEbqG) >= timeout then
            return false
        end

        task.wait(0.02)
    end

    if not PKTqUhNlA.Alive or (lSSAtRsxOpy and lSSAtRsxOpy()) then
        return false
    end

    self.Owner = owner
    return true
end

function GouULHoGsWxF:Release(owner)
    if self.Owner == owner then
        self.Owner = nil
    end
end

local Guqfamwp = GouULHoGsWxF.new("Equipment")
local MogsXTREOt = GouULHoGsWxF.new("Action")
local CskrVDMQyUS = GouULHoGsWxF.new("Plant")
local XbOuitZgCfm = GouULHoGsWxF.new("PlantRound")

--============================================================
-- COORDINATOR
-- Plant gets priority before equipment-dependent background work.
--============================================================

local wpFutleQBCyz = {PlantIntent= false,
    CriticalAction = nil,
    CriticalOwner = nil,
}

PKTqUhNlA.Coordinator = wpFutleQBCyz

function wpFutleQBCyz:IsPlantBusy()
    return self.PlantIntent or self.CriticalAction == "PLANTING"
end

function wpFutleQBCyz:WaitPlantClear(lSSAtRsxOpy)
    while PKTqUhNlA.Alive and self:IsPlantBusy() do
        if lSSAtRsxOpy and lSSAtRsxOpy() then
            return false
        end
        task.wait(0.025)
    end

    return PKTqUhNlA.Alive and not (lSSAtRsxOpy and lSSAtRsxOpy())
end

function wpFutleQBCyz:AcquireBackgroundEquipment(owner, lSSAtRsxOpy)
    -- First wait for any queued/current plant.
    if not self:WaitPlantClear(lSSAtRsxOpy) then
        return false
    end

    while PKTqUhNlA.Alive do
        if not MogsXTREOt:Acquire(owner, lSSAtRsxOpy) then
            return false
        end

        if not Guqfamwp:Acquire(owner, lSSAtRsxOpy) then
            MogsXTREOt:Release(owner)
            return false
        end

        -- A plant may have announced intent while this task waited for equipment.
        -- If so, yield priority immediately.
        if not self:IsPlantBusy() then
            return true
        end

        Guqfamwp:Release(owner)
        MogsXTREOt:Release(owner)

        if not self:WaitPlantClear(lSSAtRsxOpy) then
            return false
        end
    end

    return false
end

function wpFutleQBCyz:ReleaseBackgroundEquipment(owner)
    Guqfamwp:Release(owner)
    MogsXTREOt:Release(owner)
end

function wpFutleQBCyz:AcquireAction(owner, lSSAtRsxOpy, timeout)
    if not self:WaitPlantClear(lSSAtRsxOpy) then
        return false
    end

    if not MogsXTREOt:Acquire(owner, lSSAtRsxOpy, timeout) then
        return false
    end

    if self:IsPlantBusy() and self.CriticalOwner ~= owner then
        MogsXTREOt:Release(owner)
        return false
    end

    return true
end

function wpFutleQBCyz:ReleaseAction(owner)
    MogsXTREOt:Release(owner)
end

function wpFutleQBCyz:BeginPlant(owner, lSSAtRsxOpy)
    if not CskrVDMQyUS:Acquire(owner, lSSAtRsxOpy) then
        return false
    end

    -- Announce intent BEFORE waiting for locks.
    -- This blocks new background actions from touching remotes/tools first.
    self.PlantIntent = true
    self.CriticalOwner = owner
    HXuhwCIQZAB("PLANT QUEUED", "warning")

    if not MogsXTREOt:Acquire(owner, lSSAtRsxOpy) then
        self.PlantIntent = false
        self.CriticalOwner = nil
        CskrVDMQyUS:Release(owner)
        HXuhwCIQZAB("IDLE")
        return false
    end

    if not Guqfamwp:Acquire(owner, lSSAtRsxOpy) then
        MogsXTREOt:Release(owner)
        self.PlantIntent = false
        self.CriticalOwner = nil
        CskrVDMQyUS:Release(owner)
        HXuhwCIQZAB("IDLE")
        return false
    end

    self.CriticalAction = "PLANTING"
    HXuhwCIQZAB("PLANTING", "warning")
    return true
end

function wpFutleQBCyz:EndPlant(owner)
    if self.CriticalOwner ~= owner then
        return
    end

    self.CriticalAction = nil
    self.CriticalOwner = nil
    Guqfamwp:Release(owner)
    MogsXTREOt:Release(owner)
    self.PlantIntent = false
    CskrVDMQyUS:Release(owner)
    HXuhwCIQZAB("IDLE")
end

--============================================================
-- CHARACTER / TOOL HELPERS
--============================================================

local function yfAvfulpTS()
    return dxLeYzjrD.Character
end

local function QRxoupMChfPU()
    local wERpewMzabU = yfAvfulpTS()
    if not wERpewMzabU then
        return nil
    end
    return wERpewMzabU:FindFirstChildOfClass("Humanoid")
end

local function jdMXqPJlODtA()
    local wERpewMzabU = yfAvfulpTS()
    if not wERpewMzabU then
        return nil
    end
    return wERpewMzabU:FindFirstChildOfClass("Tool")
end

local function OyZLrMivikrp()
    local dQSktSlt = {}
    local wERpewMzabU = yfAvfulpTS()

    if not wERpewMzabU then
        return dQSktSlt
    end

    for _, child in ZVOoBlCEzTM(wERpewMzabU:GetChildren()) do
        if child:IsA("Tool") then
            dQSktSlt[#dQSktSlt + 1] = child
        end
    end

    return dQSktSlt
end

local function jvVkYVzFo(XUWueugAwuSw)
    return string.lower(DfrqgXXsrB(XUWueugAwuSw or ""))
end

local function cIjnZGwi(CRwBIXohMQ)
    CRwBIXohMQ = DfrqgXXsrB(CRwBIXohMQ or "")
    CRwBIXohMQ = CRwBIXohMQ:gsub("%b()", "")
    CRwBIXohMQ = CRwBIXohMQ:gsub("[_%s%-]*[Ss][Ee][Ee][Dd].*$", "")
    CRwBIXohMQ = CRwBIXohMQ:gsub("^%s+", ""):gsub("%s+$", "")
    return CRwBIXohMQ
end

--============================================================
-- INVENTORY BRIDGE
--
-- Uses the real DataService inventory (Hotbar + Storage).
-- It can:
--   1) reuse getgenv().KiraInventory when that API is already loaded,
--   2) bootstrap an internal cache from existing DataUpdate callbacks,
--   3) live-sync from DataUpdate afterwards.
--============================================================

local ZMZXtZNTlb = {Inventory= nil,
    Source = "none",
    LastUpdate = 0,
    Version = 0,
}

PKTqUhNlA.Inventory = ZMZXtZNTlb

local function LiOmaZCFo(tbl, eRdipkcQbcnW)
    if type(tbl) ~= "table" then
        return nil
    end

    local uPirkaZfGG, XUWueugAwuSw = BwoodiEAFu(lvheOxWcCmfk, tbl, eRdipkcQbcnW)

    if uPirkaZfGG then
        return XUWueugAwuSw
    end

    return nil
end

local function OFjzDxmLK(tbl)
    if type(tbl) ~= "table" then
        return function()
            return nil
        end
    end

    local eRdipkcQbcnW = nil

    return function()
        local uPirkaZfGG, BiHHHidSmm, wpfMogOT = BwoodiEAFu(AbFsJOrE, tbl, eRdipkcQbcnW)

        if not uPirkaZfGG or BiHHHidSmm == nil then
            return nil
        end

        eRdipkcQbcnW = BiHHHidSmm
        return BiHHHidSmm, wpfMogOT
    end
end

local function JsWrmjlSRyvZ(XUWueugAwuSw, FtEBEyLZpOZP)
    if type(XUWueugAwuSw) ~= "table" then
        return XUWueugAwuSw
    end

    FtEBEyLZpOZP = FtEBEyLZpOZP or {}

    if FtEBEyLZpOZP[XUWueugAwuSw] then
        return FtEBEyLZpOZP[XUWueugAwuSw]
    end

    local eMUGVdRYqdCC = {}
    FtEBEyLZpOZP[XUWueugAwuSw] = eMUGVdRYqdCC

    for eRdipkcQbcnW, child in OFjzDxmLK(XUWueugAwuSw) do
        eMUGVdRYqdCC[JsWrmjlSRyvZ(eRdipkcQbcnW, FtEBEyLZpOZP)] =
            JsWrmjlSRyvZ(child, FtEBEyLZpOZP)
    end

    return eMUGVdRYqdCC
end

--============================================================
-- WORM BRIDGE
--============================================================

do

local nYXywNLTy = {RawWorms= nil,
    Worms = {},
    Source = "none",
    Authoritative = false,
    LastUpdate = 0,
    Reservations = {},
}

local LeMlSaHuCDZK = {
    "Worm",
    "DewyWorm",
    "ShockedWorm",
    "DustyWorm",
    "FrostedWorm",
    "InfestedWorm",
    "RadioactiveWorm",
    "ChargedWorm",
    "SlimyWorm",
    "GoldenWorm",
    "ScaledWorm",
    "CosmicWorm",
}

local EPFtgAjFueFR = {Worm= {Display= "Worm",
        Mutation = "None",
        IsMutated = false,
    },
    DewyWorm = {Display= "Dewy Worm",
        Mutation = "Dewy",
        IsMutated = true,
    },
    ShockedWorm = {Display= "Shocked Worm",
        Mutation = "Shocked",
        IsMutated = true,
    },
    DustyWorm = {Display= "Dusty Worm",
        Mutation = "Dusty",
        IsMutated = true,
    },
    FrostedWorm = {Display= "Frosted Worm",
        Mutation = "Frosted",
        IsMutated = true,
    },
    InfestedWorm = {Display= "Infested Worm",
        Mutation = "Infested",
        IsMutated = true,
    },
    RadioactiveWorm = {Display= "Radioactive Worm",
        Mutation = "Radioactive",
        IsMutated = true,
    },
    ChargedWorm = {Display= "Charged Worm",
        Mutation = "Charged",
        IsMutated = true,
    },
    SlimyWorm = {Display= "Slimy Worm",
        Mutation = "Slimy",
        IsMutated = true,
    },
    GoldenWorm = {Display= "Golden Worm",
        Mutation = "Golden",
        IsMutated = true,
    },
    ScaledWorm = {Display= "Scaled Worm",
        Mutation = "Scaled",
        IsMutated = true,
    },
    CosmicWorm = {Display= "Cosmic Worm",
        Mutation = "Cosmic",
        IsMutated = true,
    },
}

local nCrwenUaxB = {}
local qtAQhGEJwk = {}

for _, TnTMwMYuEI in ZVOoBlCEzTM(LeMlSaHuCDZK) do
    local orUiSoOu = EPFtgAjFueFR[TnTMwMYuEI]
    local ROxVchvm = orUiSoOu and orUiSoOu.Display or TnTMwMYuEI

    nCrwenUaxB[#nCrwenUaxB + 1] = ROxVchvm
    qtAQhGEJwk[ROxVchvm] = TnTMwMYuEI
end

PKTqUhNlA.WormBridge = nYXywNLTy
PKTqUhNlA.Worms = nYXywNLTy
PKTqUhNlA.WormTypes = LeMlSaHuCDZK
PKTqUhNlA.WormLabels = nCrwenUaxB

local function YHVWDRUqDHUT(TnTMwMYuEI)
    TnTMwMYuEI = DfrqgXXsrB(TnTMwMYuEI or "")

    local orUiSoOu = EPFtgAjFueFR[TnTMwMYuEI]

    if orUiSoOu then
        return orUiSoOu
    end

    local FgynLSfATX = TnTMwMYuEI:match("^(.-)Worm$")

    if TnTMwMYuEI == "Worm" then
        FgynLSfATX = "None"
    elseif not FgynLSfATX or FgynLSfATX == "" then
        FgynLSfATX = TnTMwMYuEI
    end

    return {Display=
            TnTMwMYuEI == "Worm"
            and "Worm"
            or (FgynLSfATX .. " Worm"),
        Mutation = FgynLSfATX,
        IsMutated = TnTMwMYuEI ~= "Worm",
    }
end

local function zXGqXbrDSpXG(CvVgzwvx)
    return type(CvVgzwvx) == "table"
        and type(LiOmaZCFo(CvVgzwvx, "id")) == "string"
        and type(LiOmaZCFo(CvVgzwvx, "wormType")) == "string"
        and FPwbuFJZR(LiOmaZCFo(CvVgzwvx, "mult")) ~= nil
end

local function VjVqtNmxmc(CvVgzwvx)
    if not zXGqXbrDSpXG(CvVgzwvx) then
        return nil
    end

    local TnTMwMYuEI = DfrqgXXsrB(LiOmaZCFo(CvVgzwvx, "wormType"))
    local orUiSoOu = YHVWDRUqDHUT(TnTMwMYuEI)

    return {Id= DfrqgXXsrB(LiOmaZCFo(CvVgzwvx, "id")),
        RawType = TnTMwMYuEI,
        DisplayType = orUiSoOu.Display,
        Mutation = orUiSoOu.Mutation,
        IsMutated = orUiSoOu.IsMutated == true,
        Mult = FPwbuFJZR(LiOmaZCFo(CvVgzwvx, "mult")),
        Raw = CvVgzwvx,
    }
end

local function UvIiCzxQURN(tbl)
    local dQSktSlt = {}
    local QZYVNgIzkz = {}

    if type(tbl) ~= "table" then
        return dQSktSlt
    end

    for _, CvVgzwvx in OFjzDxmLK(tbl) do
        local TqnUoHdHB = VjVqtNmxmc(CvVgzwvx)

        if TqnUoHdHB and not QZYVNgIzkz[TqnUoHdHB.Id] then
            QZYVNgIzkz[TqnUoHdHB.Id] = true
            dQSktSlt[#dQSktSlt + 1] = TqnUoHdHB
        end
    end

    table.sort(dQSktSlt, function(a, b)
        if a.RawType ~= b.RawType then
            return a.RawType < b.RawType
        end

        if a.Mult ~= b.Mult then
            return a.Mult < b.Mult
        end

        return a.Id < b.Id
    end)

    return dQSktSlt
end

local function HuYjKPxfZn(BNnGQGeIA, allowEmpty)
    if type(BNnGQGeIA) ~= "table" then
        BNnGQGeIA = BNnGQGeIA == nil and {} or {BNnGQGeIA}
    end

    local otMRsdmAPve = {}
    local QZYVNgIzkz = {}

    for _, XUWueugAwuSw in ZVOoBlCEzTM(BNnGQGeIA) do
        local QtoBGFWIF = DfrqgXXsrB(XUWueugAwuSw or "")
        local TnTMwMYuEI = qtAQhGEJwk[QtoBGFWIF] or QtoBGFWIF

        if not EPFtgAjFueFR[TnTMwMYuEI] then
            local LoiwERgeqm = QtoBGFWIF:gsub("%s+", "")
            TnTMwMYuEI =
                EPFtgAjFueFR[LoiwERgeqm]
                and LoiwERgeqm
                or (
                    EPFtgAjFueFR[LoiwERgeqm .. "Worm"]
                    and (LoiwERgeqm .. "Worm")
                    or TnTMwMYuEI
                )
        end

        if TnTMwMYuEI ~= "" and not QZYVNgIzkz[TnTMwMYuEI] then
            QZYVNgIzkz[TnTMwMYuEI] = true
            otMRsdmAPve[#otMRsdmAPve + 1] = TnTMwMYuEI
        end
    end

    if #otMRsdmAPve == 0 and not allowEmpty then
        otMRsdmAPve[1] = "Worm"
    end

    table.sort(otMRsdmAPve, function(a, b)
        local pCkQHITYu = table.find(LeMlSaHuCDZK, a) or math.huge
        local ZsKONTNDr = table.find(LeMlSaHuCDZK, b) or math.huge

        if pCkQHITYu == ZsKONTNDr then
            return a < b
        end

        return pCkQHITYu < ZsKONTNDr
    end)

    return otMRsdmAPve
end

local function sYDqgQLHozVo(BNnGQGeIA)
    ibVEMhwTQRuM.WormTypes = HuYjKPxfZn(BNnGQGeIA)
    return ibVEMhwTQRuM.WormTypes
end

local function MZBgYtJSAUqN()
    ibVEMhwTQRuM.WormTypes = HuYjKPxfZn(ibVEMhwTQRuM.WormTypes)
    return ibVEMhwTQRuM.WormTypes
end

local function KastlRMLXa(BNnGQGeIA, allowEmpty)
    local vPMLceeu = {}

    for _, TnTMwMYuEI in ZVOoBlCEzTM(HuYjKPxfZn(BNnGQGeIA, allowEmpty)) do
        vPMLceeu[#vPMLceeu + 1] = YHVWDRUqDHUT(TnTMwMYuEI).Display
    end

    return vPMLceeu
end

local function rzIuRxBYRfq(XUWueugAwuSw)
    local ERQNGrtnl = FPwbuFJZR(XUWueugAwuSw)

    if not ERQNGrtnl then
        return "?"
    end

    return DfrqgXXsrB(math.floor(ERQNGrtnl * 100 + 0.5) / 100)
end

local function wLoicBaczG(TqnUoHdHB)
    if not TqnUoHdHB then
        return "none"
    end

    return DfrqgXXsrB(TqnUoHdHB.DisplayType)
        .. " "
        .. rzIuRxBYRfq(TqnUoHdHB.Mult)
        .. "x"
end

function nYXywNLTy:SetRaw(rawWorms, wizwGhwnAuC, authoritative)
    if type(rawWorms) ~= "table" then
        return false
    end

    local AMjunKtKpHo = UvIiCzxQURN(rawWorms)

    if #AMjunKtKpHo == 0 and authoritative ~= true then
        return false
    end

    self.RawWorms = rawWorms
    self.Worms = AMjunKtKpHo
    self.Source = wizwGhwnAuC or "unknown"
    self.Authoritative = authoritative == true
    self.LastUpdate = os.clock()

    euyMjRhaK.WormCount = #AMjunKtKpHo
    euyMjRhaK.LastWormSource = self.Source

    if self.Authoritative then
        local LPawgQwRR = {}

        for _, TqnUoHdHB in ZVOoBlCEzTM(AMjunKtKpHo) do
            LPawgQwRR[TqnUoHdHB.Id] = true
        end

        for id, UshhKFSN in oYANaOHUQcPs(self.Reservations) do
            if UshhKFSN.State ~= "CONSUMED"
                and LPawgQwRR[id] then
                self.Reservations[id] = nil
            end
        end
    end

    return true
end

function nYXywNLTy:GetAll()
    return self.Worms
end

function nYXywNLTy:GetCount()
    return #self.Worms
end

function nYXywNLTy:GetById(id)
    id = DfrqgXXsrB(id or "")

    for _, TqnUoHdHB in ZVOoBlCEzTM(self.Worms) do
        if TqnUoHdHB.Id == id then
            return TqnUoHdHB
        end
    end

    return nil
end

function nYXywNLTy:GetByType(TnTMwMYuEI)
    local dQSktSlt = {}

    for _, TqnUoHdHB in ZVOoBlCEzTM(self.Worms) do
        if TqnUoHdHB.RawType == TnTMwMYuEI then
            dQSktSlt[#dQSktSlt + 1] = TqnUoHdHB
        end
    end

    return dQSktSlt
end

function nYXywNLTy:IsOwned(id)
    return self:GetById(id) ~= nil
end

function nYXywNLTy:Resolve(CQQfyKmnCw)
    CQQfyKmnCw = type(CQQfyKmnCw) == "table" and CQQfyKmnCw or nil

    local esMDLymRGTsN = {}

    local kBKtjiGs =
        CQQfyKmnCw
        and HuYjKPxfZn(CQQfyKmnCw.Types, true)
        or MZBgYtJSAUqN()

    if #kBKtjiGs == 0 then
        return nil
    end

    for _, TnTMwMYuEI in ZVOoBlCEzTM(kBKtjiGs) do
        esMDLymRGTsN[TnTMwMYuEI] = true
    end

    local QYpNjJtTM = {}
    local TlrdxZZY =
        CQQfyKmnCw
        and FPwbuFJZR(CQQfyKmnCw.MinMult)
        or FPwbuFJZR(ibVEMhwTQRuM.WormMultiplierMin)
        or 0
    local mthmOnXWtwP =
        CQQfyKmnCw
        and FPwbuFJZR(CQQfyKmnCw.MaxMult)
        or FPwbuFJZR(ibVEMhwTQRuM.WormMultiplierMax)
        or math.huge

    if TlrdxZZY > mthmOnXWtwP then
        TlrdxZZY, mthmOnXWtwP = mthmOnXWtwP, TlrdxZZY
    end

    for _, TqnUoHdHB in ZVOoBlCEzTM(self.Worms) do
        if esMDLymRGTsN[TqnUoHdHB.RawType]
            and TqnUoHdHB.Mult >= TlrdxZZY
            and TqnUoHdHB.Mult <= mthmOnXWtwP
            and not self.Reservations[TqnUoHdHB.Id] then
            QYpNjJtTM[#QYpNjJtTM + 1] = TqnUoHdHB
        end
    end

    table.sort(QYpNjJtTM, function(a, b)
        if a.Mult == b.Mult then
            return a.Id < b.Id
        end

        local qjYfLHIxKQAM =
            CQQfyKmnCw
            and CQQfyKmnCw.SortMode
            or ibVEMhwTQRuM.WormSortMode

        if qjYfLHIxKQAM == "Highest" then
            return a.Mult > b.Mult
        end

        return a.Mult < b.Mult
    end)

    return QYpNjJtTM[1]
end

function nYXywNLTy:Reserve(TqnUoHdHB, owner)
    if not TqnUoHdHB or not TqnUoHdHB.Id then
        return false
    end

    if self.Reservations[TqnUoHdHB.Id] then
        return false
    end

    self.Reservations[TqnUoHdHB.Id] = {State= "PENDING",
        Owner = owner or "AutoPlant",
        At = os.clock(),
    }

    return true
end

function nYXywNLTy:Mark(id, state)
    id = DfrqgXXsrB(id or "")

    if id == "" then
        return
    end

    self.Reservations[id] = {State= DfrqgXXsrB(state or "UNCERTAIN"),
        Owner = "AutoPlant",
        At = os.clock(),
    }
end

function nYXywNLTy:Release(id)
    id = DfrqgXXsrB(id or "")

    local UshhKFSN = self.Reservations[id]

    if UshhKFSN and UshhKFSN.State == "PENDING" then
        self.Reservations[id] = nil
    end
end

function nYXywNLTy:GetSummary()
    local BJcVpFOFxzMV = {}

    for _, TqnUoHdHB in ZVOoBlCEzTM(self.Worms) do
        local KOnCliJlsM = BJcVpFOFxzMV[TqnUoHdHB.RawType]

        if not KOnCliJlsM then
            KOnCliJlsM = {RawType= TqnUoHdHB.RawType,
                Display = TqnUoHdHB.DisplayType,
                Mutation = TqnUoHdHB.Mutation,
                Count = 0,
                Lowest = nil,
                Highest = nil,
            }

            BJcVpFOFxzMV[TqnUoHdHB.RawType] = KOnCliJlsM
        end

        KOnCliJlsM.Count += 1
        KOnCliJlsM.Lowest =
            KOnCliJlsM.Lowest
            and math.min(KOnCliJlsM.Lowest, TqnUoHdHB.Mult)
            or TqnUoHdHB.Mult
        KOnCliJlsM.Highest =
            KOnCliJlsM.Highest
            and math.max(KOnCliJlsM.Highest, TqnUoHdHB.Mult)
            or TqnUoHdHB.Mult
    end

    return BJcVpFOFxzMV
end

function nYXywNLTy:GetSummaryText()
    local ceWxoeag = {
        "Worms: "
            .. DfrqgXXsrB(self:GetCount())
            .. " | Source: "
            .. DfrqgXXsrB(self.Source),
    }

    local BJcVpFOFxzMV = self:GetSummary()

    for _, TnTMwMYuEI in ZVOoBlCEzTM(LeMlSaHuCDZK) do
        local KOnCliJlsM = BJcVpFOFxzMV[TnTMwMYuEI]

        if KOnCliJlsM then
            ceWxoeag[#ceWxoeag + 1] =
                KOnCliJlsM.Display
                .. ": "
                .. DfrqgXXsrB(KOnCliJlsM.Count)
                .. " ("
                .. rzIuRxBYRfq(KOnCliJlsM.Lowest)
                .. "x-"
                .. rzIuRxBYRfq(KOnCliJlsM.Highest)
                .. "x)"
        end
    end

    if #ceWxoeag == 1 then
        ceWxoeag[#ceWxoeag + 1] = "No Worm detected yet."
    end

    return table.concat(ceWxoeag, "\n")
end

function nYXywNLTy:Bootstrap()
    if type(getgc) ~= "function" then
        return false
    end

    local uPirkaZfGG, szXLysgZpDej = BwoodiEAFu(getgc, true)

    if not uPirkaZfGG then
        uPirkaZfGG, szXLysgZpDej = BwoodiEAFu(getgc)
    end

    if not uPirkaZfGG or type(szXLysgZpDej) ~= "table" then
        return false
    end

    local lGcrYDHyzQ = nil
    local zyeAonWS = {}

    for _, jMfmkYAPhthA in OFjzDxmLK(szXLysgZpDej) do
        if type(jMfmkYAPhthA) == "table" then
            local AMjunKtKpHo = UvIiCzxQURN(jMfmkYAPhthA)

            if #AMjunKtKpHo > #zyeAonWS then
                lGcrYDHyzQ = jMfmkYAPhthA
                zyeAonWS = AMjunKtKpHo
            end
        end
    end

    if lGcrYDHyzQ and #zyeAonWS > 0 then
        return self:SetRaw(lGcrYDHyzQ, "getgc", false)
    end

    return false
end

local function pysijFczGgU(tBOlbjGIlYW, path)
    local WhuildgWaxd = false
    local AMjunKtKpHo = LiOmaZCFo(tBOlbjGIlYW, "Worms")

    if type(AMjunKtKpHo) == "table" then
        WhuildgWaxd =
            nYXywNLTy:SetRaw(
                AMjunKtKpHo,
                "DataUpdate.Worms",
                true
            )
            or WhuildgWaxd
    end

    if type(path) == "table"
        and LiOmaZCFo(path, 1) == "Worms" then
        WhuildgWaxd =
            nYXywNLTy:SetRaw(
                tBOlbjGIlYW,
                "DataUpdate path Worms",
                true
            )
            or WhuildgWaxd
    end

    return WhuildgWaxd
end

PKTqUhNlA.SyncWormDataUpdate = pysijFczGgU
PKTqUhNlA.NormalizeWormTypeSelection = HuYjKPxfZn
PKTqUhNlA.SetWormTypeSelection = sYDqgQLHozVo
PKTqUhNlA.GetWormTypeSelection = MZBgYtJSAUqN
PKTqUhNlA.WormTypesToLabels = KastlRMLXa
PKTqUhNlA.FormatWorm = wLoicBaczG
PKTqUhNlA.FormatMultiplier = rzIuRxBYRfq

end

local function xARxrIrhjKTJ()
    local QYpNjJtTM = {
        JUUDRJUXiNbh.KiraFullInventory,
        JUUDRJUXiNbh.KiraInventory,
    }

    for _, api in ZVOoBlCEzTM(QYpNjJtTM) do
        if type(api) == "table"
            and api ~= ZMZXtZNTlb then

            if type(api.IsReady) == "function" then
                local uPirkaZfGG, BYTJMcoqR = BwoodiEAFu(function()
                    return api:IsReady()
                end)

                if uPirkaZfGG and BYTJMcoqR then
                    return api
                end
            end

            local wrFTmooW =
                type(api.GetInventory) == "function"
                and api.GetInventory
                or type(api.Get) == "function"
                and api.Get
                or nil

            if wrFTmooW then
                local uPirkaZfGG, CnnSbMNHy = BwoodiEAFu(function()
                    return wrFTmooW(api)
                end)

                if uPirkaZfGG
                    and type(CnnSbMNHy) == "table"
                    and (
                        type(LiOmaZCFo(CnnSbMNHy, "Hotbar")) == "table"
                        or type(LiOmaZCFo(CnnSbMNHy, "Storage")) == "table"
                    ) then

                    return api
                end
            end
        end
    end

    return nil
end

local function UKIlsCatl(CnnSbMNHy)
    if type(CnnSbMNHy) ~= "table" then
        return false
    end

    return type(LiOmaZCFo(CnnSbMNHy, "Hotbar")) == "table"
        or type(LiOmaZCFo(CnnSbMNHy, "Storage")) == "table"
end

local function fZNTKPAFBSy(CnnSbMNHy, wizwGhwnAuC)
    if not UKIlsCatl(CnnSbMNHy) then
        return false
    end

    ZMZXtZNTlb.Inventory = JsWrmjlSRyvZ(CnnSbMNHy)
    ZMZXtZNTlb.Source = wizwGhwnAuC or "unknown"
    ZMZXtZNTlb.LastUpdate = os.clock()
    ZMZXtZNTlb.Version =
        (ZMZXtZNTlb.Version or 0) + 1
    euyMjRhaK.LastInventorySource = ZMZXtZNTlb.Source

    return true
end

local function WdCdqAajy(update)
    if type(update) ~= "table" then
        return
    end

    if type(ZMZXtZNTlb.Inventory) ~= "table" then
        ZMZXtZNTlb.Inventory = {}
    end

    local ybcXirpUG = false

    for branch, branchData in OFjzDxmLK(update) do
        ZMZXtZNTlb.Inventory[branch] =
            JsWrmjlSRyvZ(branchData)

        ybcXirpUG = true
    end

    if ybcXirpUG then
        ZMZXtZNTlb.Source = "DataUpdate"
        ZMZXtZNTlb.LastUpdate = os.clock()
        ZMZXtZNTlb.Version =
            (ZMZXtZNTlb.Version or 0) + 1
        euyMjRhaK.LastInventorySource = "DataUpdate"
    end
end

function PKTqUhNlA.InventoryPathParts(path)
    local NQYAzsomZ = {}

    if type(path) ~= "table" then
        return NQYAzsomZ
    end

    for LvOjTWuqYW = 1, 12 do
        local XUWueugAwuSw = LiOmaZCFo(path, LvOjTWuqYW)

        if XUWueugAwuSw == nil then
            break
        end

        NQYAzsomZ[#NQYAzsomZ + 1] = XUWueugAwuSw
    end

    return NQYAzsomZ
end

function PKTqUhNlA.InventoryPathText(NQYAzsomZ)
    local QtoBGFWIF = {}

    for _, muPHtvEg in ZVOoBlCEzTM(NQYAzsomZ or {}) do
        QtoBGFWIF[#QtoBGFWIF + 1] = DfrqgXXsrB(muPHtvEg)
    end

    return table.concat(QtoBGFWIF, ".")
end

function PKTqUhNlA.ApplyInventoryPathUpdate(tBOlbjGIlYW, path)
    local NQYAzsomZ = PKTqUhNlA.InventoryPathParts(path)

    if NQYAzsomZ[1] ~= "Inventory"
        or NQYAzsomZ[2] == nil then

        return false
    end

    if type(ZMZXtZNTlb.Inventory) ~= "table" then
        ZMZXtZNTlb.Inventory = {}
    end

    if #NQYAzsomZ == 2 then
        ZMZXtZNTlb.Inventory[NQYAzsomZ[2]] =
            JsWrmjlSRyvZ(tBOlbjGIlYW)
    else
        local jVhdYEIPZTmD = ZMZXtZNTlb.Inventory

        for LvOjTWuqYW = 2, #NQYAzsomZ - 1 do
            local eRdipkcQbcnW = NQYAzsomZ[LvOjTWuqYW]
            local IfRutpBlMj = LiOmaZCFo(jVhdYEIPZTmD, eRdipkcQbcnW)

            if type(IfRutpBlMj) ~= "table" then
                IfRutpBlMj = {}
                jVhdYEIPZTmD[eRdipkcQbcnW] = IfRutpBlMj
            end

            jVhdYEIPZTmD = IfRutpBlMj
        end

        jVhdYEIPZTmD[NQYAzsomZ[#NQYAzsomZ]] =
            JsWrmjlSRyvZ(tBOlbjGIlYW)
    end

    ZMZXtZNTlb.Source =
        "DataUpdate-direct:"
        .. PKTqUhNlA.InventoryPathText(NQYAzsomZ)
    ZMZXtZNTlb.LastUpdate = os.clock()
    ZMZXtZNTlb.Version =
        (ZMZXtZNTlb.Version or 0) + 1
    euyMjRhaK.LastInventorySource = ZMZXtZNTlb.Source

    return true
end

PKTqUhNlA:Track(EbMWmSACcQ.OnClientEvent:Connect(function(tBOlbjGIlYW, path)
    if type(tBOlbjGIlYW) == "table"
        and type(PKTqUhNlA.SyncWormDataUpdate) == "function" then
        PKTqUhNlA.SyncWormDataUpdate(tBOlbjGIlYW, path)
    end

    if type(tBOlbjGIlYW) == "table" then
        local CnnSbMNHy = LiOmaZCFo(tBOlbjGIlYW, "Inventory")

        if type(CnnSbMNHy) == "table" then
            WdCdqAajy(CnnSbMNHy)
        end
    end

    -- Defensive direct-delta format:
    -- {"Inventory", "Hotbar"} replaces a branch.
    -- {"Inventory", "Hotbar", 6} updates a single slot.
    PKTqUhNlA.ApplyInventoryPathUpdate(tBOlbjGIlYW, path)
end))

local function gCyrbzFf(cNriAbRfCZO)
    if type(cNriAbRfCZO) ~= "function" then
        return nil
    end

    if type(getupvalues) == "function" then
        local uPirkaZfGG, BNnGQGeIA = BwoodiEAFu(getupvalues, cNriAbRfCZO)

        if uPirkaZfGG and type(BNnGQGeIA) == "table" then
            return BNnGQGeIA
        end
    end

    if debug and type(debug.getupvalues) == "function" then
        local uPirkaZfGG, BNnGQGeIA = BwoodiEAFu(debug.getupvalues, cNriAbRfCZO)

        if uPirkaZfGG and type(BNnGQGeIA) == "table" then
            return BNnGQGeIA
        end
    end

    return nil
end

local function RigOBXyzF(eNOyItOd)
    local FtEBEyLZpOZP = {}
    local DbqzrmQqgbjo = 0

    local function viGkUeznUDor(XUWueugAwuSw, depth)
        if type(XUWueugAwuSw) ~= "table" or FtEBEyLZpOZP[XUWueugAwuSw] then
            return nil
        end

        FtEBEyLZpOZP[XUWueugAwuSw] = true
        DbqzrmQqgbjo += 1

        if DbqzrmQqgbjo > 2500 then
            return nil
        end

        local CnnSbMNHy = LiOmaZCFo(XUWueugAwuSw, "Inventory")

        if UKIlsCatl(CnnSbMNHy) then
            return CnnSbMNHy
        end

        if UKIlsCatl(XUWueugAwuSw) then
            return XUWueugAwuSw
        end

        if depth >= 5 then
            return nil
        end

        for _, child in OFjzDxmLK(XUWueugAwuSw) do
            if type(child) == "table" then
                local EJWoSYJFtW = viGkUeznUDor(child, depth + 1)

                if EJWoSYJFtW then
                    return EJWoSYJFtW
                end
            end
        end

        return nil
    end

    return viGkUeznUDor(eNOyItOd, 0)
end

local function hfBLUgtjD()
    local baWDTpCF = xARxrIrhjKTJ()

    if baWDTpCF and type(baWDTpCF.GetInventory) == "function" then
        local uPirkaZfGG, CnnSbMNHy = BwoodiEAFu(function()
            return baWDTpCF:GetInventory()
        end)

        if uPirkaZfGG and fZNTKPAFBSy(CnnSbMNHy, "KiraInventory") then
            return true
        end
    end

    if type(getconnections) ~= "function" then
        return false
    end

    local uPirkaZfGG, RvcbuCAdxLIN =
        BwoodiEAFu(getconnections, EbMWmSACcQ.OnClientEvent)

    if not uPirkaZfGG or type(RvcbuCAdxLIN) ~= "table" then
        return false
    end

    for connectionIndex, connection in ZVOoBlCEzTM(RvcbuCAdxLIN) do
        local cNriAbRfCZO = nil

        BwoodiEAFu(function()
            cNriAbRfCZO = connection.Function
        end)

        if type(cNriAbRfCZO) ~= "function" then
            BwoodiEAFu(function()
                cNriAbRfCZO = connection.Callback
            end)
        end

        if type(cNriAbRfCZO) == "function" then
            local xBVXKjndcj = gCyrbzFf(cNriAbRfCZO)

            if type(xBVXKjndcj) == "table" then
                for upvalueName, XUWueugAwuSw in OFjzDxmLK(xBVXKjndcj) do
                    if type(XUWueugAwuSw) == "table" then
                        local CnnSbMNHy =
                            RigOBXyzF(XUWueugAwuSw)

                        if CnnSbMNHy then
                            return fZNTKPAFBSy(
                                CnnSbMNHy,
                                "existing-cache:"
                                    .. DfrqgXXsrB(connectionIndex)
                                    .. ":"
                                    .. DfrqgXXsrB(upvalueName)
                            )
                        end
                    end
                end
            end
        end
    end

    return false
end

hfBLUgtjD()
if PKTqUhNlA.WormBridge then
    PKTqUhNlA.WormBridge:Bootstrap()
end

local function TjIHhQMpnV(eNOyItOd, path, callback, FtEBEyLZpOZP)
    if type(eNOyItOd) ~= "table" then
        return
    end

    FtEBEyLZpOZP = FtEBEyLZpOZP or {}

    if FtEBEyLZpOZP[eNOyItOd] then
        return
    end

    FtEBEyLZpOZP[eNOyItOd] = true

    local pZWezDiISM =
        LiOmaZCFo(eNOyItOd, "itemType")
        or LiOmaZCFo(eNOyItOd, "ItemType")

    local sKvykwKmzSJv =
        LiOmaZCFo(eNOyItOd, "id")
        or LiOmaZCFo(eNOyItOd, "itemId")
        or LiOmaZCFo(eNOyItOd, "ItemId")

    if pZWezDiISM ~= nil or sKvykwKmzSJv ~= nil then
        callback(eNOyItOd, path)
    end

    for eRdipkcQbcnW, child in OFjzDxmLK(eNOyItOd) do
        if type(child) == "table" then
            TjIHhQMpnV(
                child,
                path .. "." .. DfrqgXXsrB(eRdipkcQbcnW),
                callback,
                FtEBEyLZpOZP
            )
        end
    end
end

function ZMZXtZNTlb:IsReady()
    local baWDTpCF = xARxrIrhjKTJ()

    if baWDTpCF then
        return true
    end

    return type(self.Inventory) == "table"
end

function ZMZXtZNTlb:GetInventory()
    local baWDTpCF = xARxrIrhjKTJ()

    if baWDTpCF and type(baWDTpCF.GetInventory) == "function" then
        local uPirkaZfGG, CnnSbMNHy = BwoodiEAFu(function()
            return baWDTpCF:GetInventory()
        end)

        if uPirkaZfGG and type(CnnSbMNHy) == "table" then
            self.Source = "KiraInventory"
            local sUkAECEIL = FPwbuFJZR(baWDTpCF.LastUpdate)

            if sUkAECEIL
                and sUkAECEIL ~= self.ExternalLastUpdate then

                self.ExternalLastUpdate = sUkAECEIL
                self.LastUpdate = sUkAECEIL
                self.Version = (self.Version or 0) + 1
            end

            euyMjRhaK.LastInventorySource = self.Source
            return CnnSbMNHy
        end
    end

    if baWDTpCF and type(baWDTpCF.Get) == "function" then
        local uPirkaZfGG, CnnSbMNHy = BwoodiEAFu(function()
            return baWDTpCF:Get()
        end)

        if uPirkaZfGG and type(CnnSbMNHy) == "table" then
            self.Source = "KiraFullInventory"
            local sUkAECEIL = FPwbuFJZR(baWDTpCF.LastUpdate)

            if sUkAECEIL
                and sUkAECEIL ~= self.ExternalLastUpdate then

                self.ExternalLastUpdate = sUkAECEIL
                self.LastUpdate = sUkAECEIL
                self.Version = (self.Version or 0) + 1
            end

            euyMjRhaK.LastInventorySource = self.Source
            return CnnSbMNHy
        end
    end

    return self.Inventory and JsWrmjlSRyvZ(self.Inventory) or nil
end

function PKTqUhNlA.GetInventoryVersion()
    ZMZXtZNTlb:GetInventory()
    return FPwbuFJZR(ZMZXtZNTlb.Version) or 0
end

function PKTqUhNlA.WaitForInventoryRefresh(previousVersion, lSSAtRsxOpy, timeout)
    local QHmwcvVZcPU =
        os.clock() + (FPwbuFJZR(timeout) or 2)

    while PKTqUhNlA.Alive
        and not (
            type(lSSAtRsxOpy) == "function"
            and lSSAtRsxOpy()
        )
        and os.clock() < QHmwcvVZcPU do

        if PKTqUhNlA.GetInventoryVersion() ~= previousVersion then
            return true
        end

        task.wait(0.08)
    end

    return false
end

function PKTqUhNlA.ClearInventoryLocation(VthIAVxSEI, expectedItemId)
    if not VthIAVxSEI
        or type(ZMZXtZNTlb.Inventory) ~= "table" then

        return false
    end

    local PDnviBYoORx =
        LiOmaZCFo(
            ZMZXtZNTlb.Inventory,
            VthIAVxSEI.Container
        )

    if type(PDnviBYoORx) ~= "table" then
        return false
    end

    local CvVgzwvx =
        LiOmaZCFo(PDnviBYoORx, VthIAVxSEI.Index)

    if CvVgzwvx == nil then
        return false
    end

    local ftkFgiCevokN =
        LiOmaZCFo(CvVgzwvx, "id")
        or LiOmaZCFo(CvVgzwvx, "itemId")
        or LiOmaZCFo(CvVgzwvx, "ItemId")
        or LiOmaZCFo(CvVgzwvx, "Id")
        or LiOmaZCFo(CvVgzwvx, "uuid")
        or LiOmaZCFo(CvVgzwvx, "UUID")

    if expectedItemId ~= nil
        and ftkFgiCevokN ~= nil
        and DfrqgXXsrB(ftkFgiCevokN) ~= DfrqgXXsrB(expectedItemId) then

        return false
    end

    PDnviBYoORx[VthIAVxSEI.Index] = nil

    return true
end

local function xfbGWaEamWXE(XUWueugAwuSw, depth, FtEBEyLZpOZP)
    depth = depth or 0
    FtEBEyLZpOZP = FtEBEyLZpOZP or {}

    if depth > 4 then
        return "..."
    end

    if type(XUWueugAwuSw) ~= "table" then
        return DfrqgXXsrB(XUWueugAwuSw)
    end

    if FtEBEyLZpOZP[XUWueugAwuSw] then
        return "<cycle>"
    end

    FtEBEyLZpOZP[XUWueugAwuSw] = true
    local NQYAzsomZ = {}

    for eRdipkcQbcnW, child in OFjzDxmLK(XUWueugAwuSw) do
        NQYAzsomZ[#NQYAzsomZ + 1] =
            DfrqgXXsrB(eRdipkcQbcnW)
            .. "="
            .. xfbGWaEamWXE(child, depth + 1, FtEBEyLZpOZP)
    end

    table.sort(NQYAzsomZ)
    FtEBEyLZpOZP[XUWueugAwuSw] = nil
    return "{" .. table.concat(NQYAzsomZ, ",") .. "}"
end

local function rFeoDPhd(CvVgzwvx)
    if type(CvVgzwvx) ~= "table" then
        return ""
    end

    local NQYAzsomZ = {}
    local FtEBEyLZpOZP = {}

    local function eydOEnaha(XUWueugAwuSw, path, depth)
        if type(XUWueugAwuSw) ~= "table"
            or FtEBEyLZpOZP[XUWueugAwuSw]
            or depth > 5 then
            return
        end

        FtEBEyLZpOZP[XUWueugAwuSw] = true

        for eRdipkcQbcnW, child in OFjzDxmLK(XUWueugAwuSw) do
            local mDHEjrNgJ = jvVkYVzFo(eRdipkcQbcnW)
            local FVgBLHUvKdf =
                path == ""
                and DfrqgXXsrB(eRdipkcQbcnW)
                or (path .. "." .. DfrqgXXsrB(eRdipkcQbcnW))

            if string.find(mDHEjrNgJ, "mutation", 1, true) then
                local AFMgnure =
                    child ~= nil
                    and child ~= false
                    and child ~= ""
                    and child ~= 0
                    and jvVkYVzFo(child) ~= "none"
                    and jvVkYVzFo(child) ~= "false"
                    and not (
                        type(child) == "table"
                        and AbFsJOrE(child) == nil
                    )

                if AFMgnure then
                    NQYAzsomZ[#NQYAzsomZ + 1] =
                        FVgBLHUvKdf
                        .. "="
                        .. xfbGWaEamWXE(child)
                end
            elseif type(child) == "table" then
                eydOEnaha(child, FVgBLHUvKdf, depth + 1)
            end
        end

        FtEBEyLZpOZP[XUWueugAwuSw] = nil
    end

    eydOEnaha(CvVgzwvx, "", 0)
    table.sort(NQYAzsomZ)

    return table.concat(NQYAzsomZ, " | ")
end

local function oCsyfpJnzjH(path)
    path = DfrqgXXsrB(path or "")

    local PDnviBYoORx, WVELRoxY =
        path:match("^Inventory%.([^%.]+)%.(%d+)$")

    local LvOjTWuqYW = FPwbuFJZR(WVELRoxY)

    if not PDnviBYoORx or not LvOjTWuqYW then
        return nil
    end

    if PDnviBYoORx == "Hotbar" then
        return {Container= "Hotbar",
            IsHotbar = true,
            Index = LvOjTWuqYW,
        }
    elseif PDnviBYoORx == "Storage" then
        return {Container= "Storage",
            IsHotbar = false,
            Index = LvOjTWuqYW,
        }
    end

    return nil
end

function ZMZXtZNTlb:GetSeeds()
    local CnnSbMNHy = self:GetInventory()
    local WUcKIyzSAqgs = {}

    if type(CnnSbMNHy) ~= "table" then
        return WUcKIyzSAqgs
    end

    local function XghEKcywnp(CvVgzwvx)
        local brFeJHrLrSF =
            LiOmaZCFo(CvVgzwvx, "seedType")
            or LiOmaZCFo(CvVgzwvx, "SeedType")

        local XUWueugAwuSw =
            brFeJHrLrSF
            or LiOmaZCFo(CvVgzwvx, "seed")
            or LiOmaZCFo(CvVgzwvx, "Seed")
            or LiOmaZCFo(CvVgzwvx, "name")
            or LiOmaZCFo(CvVgzwvx, "Name")
            or LiOmaZCFo(CvVgzwvx, "itemName")
            or LiOmaZCFo(CvVgzwvx, "ItemName")
            or LiOmaZCFo(CvVgzwvx, "displayName")
            or LiOmaZCFo(CvVgzwvx, "DisplayName")

        if type(XUWueugAwuSw) ~= "string" then
            return nil
        end

        local EQkOFXGQS = cIjnZGwi(XUWueugAwuSw)

        if EQkOFXGQS == ""
            or jvVkYVzFo(EQkOFXGQS) == "seed" then
            return nil
        end

        return EQkOFXGQS
    end

    TjIHhQMpnV(
        CnnSbMNHy,
        "Inventory",
        function(CvVgzwvx, path)
            local pZWezDiISM =
                jvVkYVzFo(
                    LiOmaZCFo(CvVgzwvx, "itemType")
                    or LiOmaZCFo(CvVgzwvx, "ItemType")
                )

            local EQkOFXGQS = XghEKcywnp(CvVgzwvx)
            local YfioPeYVE =
                pZWezDiISM ~= ""

            local bAQQATjKccA =
                pZWezDiISM == "seed"
                or (
                    not YfioPeYVE
                    and (
                        LiOmaZCFo(CvVgzwvx, "seedType") ~= nil
                        or LiOmaZCFo(CvVgzwvx, "SeedType") ~= nil
                    )
                )

            if bAQQATjKccA and EQkOFXGQS then
                local FgynLSfATX = rFeoDPhd(CvVgzwvx)
                local VthIAVxSEI = oCsyfpJnzjH(path)

                WUcKIyzSAqgs[#WUcKIyzSAqgs + 1] = {SeedType= EQkOFXGQS,

                    Count =
                        FPwbuFJZR(
                            LiOmaZCFo(CvVgzwvx, "count")
                            or LiOmaZCFo(CvVgzwvx, "Count")
                            or 1
                        ) or 1,

                    Id =
                        LiOmaZCFo(CvVgzwvx, "id")
                        or LiOmaZCFo(CvVgzwvx, "itemId")
                        or LiOmaZCFo(CvVgzwvx, "ItemId"),

                    ItemType = pZWezDiISM ~= "" and pZWezDiISM or "seed",
                    Mutation = FgynLSfATX,
                    IsMutated = FgynLSfATX ~= "",
                    Path = path,
                    Location = VthIAVxSEI,
                    Data = JsWrmjlSRyvZ(CvVgzwvx),
                }
            end
        end
    )

    table.sort(WUcKIyzSAqgs, function(a, b)
        if jvVkYVzFo(a.SeedType) ~= jvVkYVzFo(b.SeedType) then
            return jvVkYVzFo(a.SeedType) < jvVkYVzFo(b.SeedType)
        end

        if a.IsMutated ~= b.IsMutated then
            return not a.IsMutated
        end

        return DfrqgXXsrB(a.Path) < DfrqgXXsrB(b.Path)
    end)

    return WUcKIyzSAqgs
end

function ZMZXtZNTlb:GetSeedCount(DhaBjHwh)
    local VuDvjaRnSLZL = jvVkYVzFo(DhaBjHwh)
    local nPPqaVMjIHf = 0

    for _, seed in ZVOoBlCEzTM(self:GetSeeds()) do
        if jvVkYVzFo(seed.SeedType) == VuDvjaRnSLZL then
            nPPqaVMjIHf += FPwbuFJZR(seed.Count) or 0
        end
    end

    return nPPqaVMjIHf
end

function ZMZXtZNTlb:ResolveSeed(DhaBjHwh, DcAmitWhFX)
    local VuDvjaRnSLZL = jvVkYVzFo(DhaBjHwh)
    local ftkFgiCevokN = nil

    if DcAmitWhFX then
        ftkFgiCevokN =
            DcAmitWhFX:GetAttribute("ItemId")
            or DcAmitWhFX:GetAttribute("itemId")
            or DcAmitWhFX:GetAttribute("id")
    end

    local qLfdgteI = {}

    for _, seed in ZVOoBlCEzTM(self:GetSeeds()) do
        if jvVkYVzFo(seed.SeedType) == VuDvjaRnSLZL
            and (FPwbuFJZR(seed.Count) or 0) > 0
            and seed.Location ~= nil
            and (
                ibVEMhwTQRuM.AllowMutatedSeeds
                or not seed.IsMutated
            ) then

            local ihZCPKaH = FPwbuFJZR(seed.Count) or 0

            -- Duplicate stacks can represent mutations. Prefer plain stacks.
            if not seed.IsMutated then
                ihZCPKaH += 1000000000000000
            end

            if ftkFgiCevokN ~= nil
                and DfrqgXXsrB(seed.Id) == DfrqgXXsrB(ftkFgiCevokN) then
                ihZCPKaH += 1000000000000
            end

            if seed.Location.IsHotbar then
                ihZCPKaH += 1000000000
            end

            qLfdgteI[#qLfdgteI + 1] = {SeedType= seed.SeedType,
                Count = seed.Count,
                Id = seed.Id,
                Mutation = seed.Mutation,
                IsMutated = seed.IsMutated,
                Path = seed.Path,
                Location = seed.Location,
                Data = seed.Data,
                Score = ihZCPKaH,
            }
        end
    end

    table.sort(qLfdgteI, function(a, b)
        if a.Score == b.Score then
            return DfrqgXXsrB(a.Path) < DfrqgXXsrB(b.Path)
        end
        return a.Score > b.Score
    end)

    return qLfdgteI[1]
end

PKTqUhNlA.GetItemMutationSignature = rFeoDPhd
PKTqUhNlA.ParseInventoryLocation = oCsyfpJnzjH

do
    local function hweIUOEL(XUWueugAwuSw, hVKRNUmvaW)
        local ERQNGrtnl =
            FPwbuFJZR(
                DfrqgXXsrB(XUWueugAwuSw or ""):match("%-?%d+%.?%d*")
                or DfrqgXXsrB(XUWueugAwuSw or ""):match("%-?%.%d+")
                or XUWueugAwuSw
            )
            or FPwbuFJZR(hVKRNUmvaW)
            or 5

        ERQNGrtnl = math.max(0, ERQNGrtnl)
        return math.floor(ERQNGrtnl * 100 + 0.5) / 100
    end

    local function OIcdvOgJoDZ(XUWueugAwuSw, hVKRNUmvaW)
        XUWueugAwuSw = DfrqgXXsrB(XUWueugAwuSw or hVKRNUmvaW or "Lowest")

        if XUWueugAwuSw == "Highest" then
            return "Highest"
        end

        return "Lowest"
    end

    local function fGLXcjkPyLVN(XUWueugAwuSw, hVKRNUmvaW)
        XUWueugAwuSw = type(XUWueugAwuSw) == "table" and XUWueugAwuSw or {}
        hVKRNUmvaW = type(hVKRNUmvaW) == "table" and hVKRNUmvaW or {}

        local TlrdxZZY =
            hweIUOEL(
                XUWueugAwuSw.MinMult or XUWueugAwuSw.Min or XUWueugAwuSw.Minimum,
                hVKRNUmvaW.MinMult or ibVEMhwTQRuM.WormMultiplierMin or 5
            )

        local mthmOnXWtwP =
            hweIUOEL(
                XUWueugAwuSw.MaxMult or XUWueugAwuSw.Max or XUWueugAwuSw.Maximum,
                hVKRNUmvaW.MaxMult or ibVEMhwTQRuM.WormMultiplierMax or 10
            )

        if TlrdxZZY > mthmOnXWtwP then
            TlrdxZZY, mthmOnXWtwP = mthmOnXWtwP, TlrdxZZY
        end

        local eKAmKQGHBuwj =
            XUWueugAwuSw.Use ~= nil
            and XUWueugAwuSw.Use == true
            or (
                XUWueugAwuSw.Use == nil
                and hVKRNUmvaW.Use == true
            )

        local WGOtDLHU =
            PKTqUhNlA.NormalizeWormTypeSelection
            or function(ephNnOXqNlUd, allowEmpty)
                if type(ephNnOXqNlUd) ~= "table" then
                    ephNnOXqNlUd = ephNnOXqNlUd == nil and {} or {ephNnOXqNlUd}
                end

                if #ephNnOXqNlUd == 0 and not allowEmpty then
                    return {"Worm"}
                end

                return ephNnOXqNlUd
            end

        local cMZkIdNmqen =
            XUWueugAwuSw.Types
            or XUWueugAwuSw.WormTypes
            or hVKRNUmvaW.Types
            or (eKAmKQGHBuwj and ibVEMhwTQRuM.WormTypes or {})

        local ephNnOXqNlUd =
            WGOtDLHU(cMZkIdNmqen, true)

        if eKAmKQGHBuwj and #ephNnOXqNlUd == 0 then
            ephNnOXqNlUd = WGOtDLHU(ibVEMhwTQRuM.WormTypes or {"Worm"})
        elseif not eKAmKQGHBuwj then
            ephNnOXqNlUd = WGOtDLHU(ephNnOXqNlUd, true)
        end

        return {Use= eKAmKQGHBuwj and #ephNnOXqNlUd > 0,
            Types = ephNnOXqNlUd,
            SortMode =
                OIcdvOgJoDZ(
                    XUWueugAwuSw.SortMode or XUWueugAwuSw.Priority,
                    hVKRNUmvaW.SortMode or ibVEMhwTQRuM.WormSortMode
                ),
            MinMult = TlrdxZZY,
            MaxMult = mthmOnXWtwP,
        }
    end

    local function UPbpCazewef()
        return fGLXcjkPyLVN({Use= ibVEMhwTQRuM.UseWorm,
            Types = ibVEMhwTQRuM.WormTypes,
            SortMode = ibVEMhwTQRuM.WormSortMode,
            MinMult = ibVEMhwTQRuM.WormMultiplierMin,
            MaxMult = ibVEMhwTQRuM.WormMultiplierMax,
        })
    end

    local function QndbGYZN(XUWueugAwuSw)
        local CQQfyKmnCw =
            fGLXcjkPyLVN(XUWueugAwuSw, UPbpCazewef())

        ibVEMhwTQRuM.UseWorm = CQQfyKmnCw.Use
        ibVEMhwTQRuM.WormTypes = CQQfyKmnCw.Types
        ibVEMhwTQRuM.WormSortMode = CQQfyKmnCw.SortMode
        ibVEMhwTQRuM.WormMultiplierMin = CQQfyKmnCw.MinMult
        ibVEMhwTQRuM.WormMultiplierMax = CQQfyKmnCw.MaxMult

        return CQQfyKmnCw
    end

    function PKTqUhNlA.GetWormSettingsForSeed(DhaBjHwh)
        local tpSFmqQNLSF = UPbpCazewef()

        ibVEMhwTQRuM.WormTypesLocked =
            ibVEMhwTQRuM.WormTypesLocked ~= false

        ibVEMhwTQRuM.WormPriorityLocked =
            ibVEMhwTQRuM.WormPriorityLocked ~= false

        ibVEMhwTQRuM.WormSettingsLocked =
            ibVEMhwTQRuM.WormTypesLocked
            and ibVEMhwTQRuM.WormPriorityLocked

        if ibVEMhwTQRuM.WormTypesLocked
            and ibVEMhwTQRuM.WormPriorityLocked then
            return tpSFmqQNLSF
        end

        if type(ibVEMhwTQRuM.WormSettings) ~= "table" then
            ibVEMhwTQRuM.WormSettings = {}
        end

        local CQQfyKmnCw =
            fGLXcjkPyLVN(
                ibVEMhwTQRuM.WormSettings[DfrqgXXsrB(DhaBjHwh or "")],
                tpSFmqQNLSF
            )

        if ibVEMhwTQRuM.WormTypesLocked then
            CQQfyKmnCw.Use = tpSFmqQNLSF.Use
            CQQfyKmnCw.Types = JsWrmjlSRyvZ(tpSFmqQNLSF.Types)
        end

        if ibVEMhwTQRuM.WormPriorityLocked then
            CQQfyKmnCw.SortMode = tpSFmqQNLSF.SortMode
        end

        CQQfyKmnCw.MinMult = tpSFmqQNLSF.MinMult
        CQQfyKmnCw.MaxMult = tpSFmqQNLSF.MaxMult

        return fGLXcjkPyLVN(CQQfyKmnCw, tpSFmqQNLSF)
    end

    function PKTqUhNlA.SetWormSettingsForSeed(DhaBjHwh, XUWueugAwuSw)
        local bnqNhGgNjiU = DfrqgXXsrB(DhaBjHwh or "")
        local tpSFmqQNLSF = UPbpCazewef()
        local jIsUVHAQEx =
            fGLXcjkPyLVN(
                type(ibVEMhwTQRuM.WormSettings) == "table"
                and ibVEMhwTQRuM.WormSettings[bnqNhGgNjiU]
                or nil,
                tpSFmqQNLSF
            )

        local CQQfyKmnCw =
            fGLXcjkPyLVN(
                XUWueugAwuSw,
                jIsUVHAQEx
            )

        ibVEMhwTQRuM.WormTypesLocked =
            ibVEMhwTQRuM.WormTypesLocked ~= false

        ibVEMhwTQRuM.WormPriorityLocked =
            ibVEMhwTQRuM.WormPriorityLocked ~= false

        ibVEMhwTQRuM.WormSettingsLocked =
            ibVEMhwTQRuM.WormTypesLocked
            and ibVEMhwTQRuM.WormPriorityLocked

        if ibVEMhwTQRuM.WormTypesLocked
            and ibVEMhwTQRuM.WormPriorityLocked then
            return QndbGYZN(CQQfyKmnCw)
        end

        if type(ibVEMhwTQRuM.WormSettings) ~= "table" then
            ibVEMhwTQRuM.WormSettings = {}
        end

        if ibVEMhwTQRuM.WormTypesLocked then
            CQQfyKmnCw.Use = jIsUVHAQEx.Use
            CQQfyKmnCw.Types = jIsUVHAQEx.Types
        end

        if ibVEMhwTQRuM.WormPriorityLocked then
            CQQfyKmnCw.SortMode = jIsUVHAQEx.SortMode
        end

        CQQfyKmnCw.MinMult = tpSFmqQNLSF.MinMult
        CQQfyKmnCw.MaxMult = tpSFmqQNLSF.MaxMult

        ibVEMhwTQRuM.WormSettings[bnqNhGgNjiU] = CQQfyKmnCw
        return PKTqUhNlA.GetWormSettingsForSeed(bnqNhGgNjiU)
    end

    function PKTqUhNlA.GetSharedWormSettings()
        return UPbpCazewef()
    end

    function PKTqUhNlA.SetSharedWormSettings(XUWueugAwuSw)
        return QndbGYZN(XUWueugAwuSw)
    end

    function PKTqUhNlA.ExportWormSettingsState()
        ibVEMhwTQRuM.WormTypesLocked =
            ibVEMhwTQRuM.WormTypesLocked ~= false

        ibVEMhwTQRuM.WormPriorityLocked =
            ibVEMhwTQRuM.WormPriorityLocked ~= false

        ibVEMhwTQRuM.WormSettingsLocked =
            ibVEMhwTQRuM.WormTypesLocked
            and ibVEMhwTQRuM.WormPriorityLocked

        return {Locked= ibVEMhwTQRuM.WormSettingsLocked == true,
            TypesLocked = ibVEMhwTQRuM.WormTypesLocked == true,
            PriorityLocked = ibVEMhwTQRuM.WormPriorityLocked == true,
            Shared = UPbpCazewef(),
            Values = JsWrmjlSRyvZ(ibVEMhwTQRuM.WormSettings or {}),
        }
    end

    function PKTqUhNlA.ApplyWormSettingsState(XUWueugAwuSw)
        if type(XUWueugAwuSw) == "table" then
            local bTOFCmgU =
                XUWueugAwuSw.Locked ~= false

            local MqDzDOsZNNB =
                XUWueugAwuSw.TypesLocked

            if MqDzDOsZNNB == nil then
                MqDzDOsZNNB = XUWueugAwuSw.WormTypesLocked
            end

            local mdLohPoc =
                XUWueugAwuSw.PriorityLocked

            if mdLohPoc == nil then
                mdLohPoc = XUWueugAwuSw.WormPriorityLocked
            end

            ibVEMhwTQRuM.WormTypesLocked =
                MqDzDOsZNNB == nil
                and bTOFCmgU
                or MqDzDOsZNNB == true

            ibVEMhwTQRuM.WormPriorityLocked =
                mdLohPoc == nil
                and bTOFCmgU
                or mdLohPoc == true

            ibVEMhwTQRuM.WormSettingsLocked =
                ibVEMhwTQRuM.WormTypesLocked
                and ibVEMhwTQRuM.WormPriorityLocked

            QndbGYZN(
                XUWueugAwuSw.Shared
                or XUWueugAwuSw.Default
                or XUWueugAwuSw
            )

            ibVEMhwTQRuM.WormSettings = {}

            if type(XUWueugAwuSw.Values) == "table" then
                local tpSFmqQNLSF = UPbpCazewef()

                for DhaBjHwh, CQQfyKmnCw in oYANaOHUQcPs(XUWueugAwuSw.Values) do
                    ibVEMhwTQRuM.WormSettings[DfrqgXXsrB(DhaBjHwh)] =
                        fGLXcjkPyLVN(CQQfyKmnCw, tpSFmqQNLSF)
                end
            end
        end

        return PKTqUhNlA.ExportWormSettingsState()
    end
end

--============================================================
-- TOOL / SEED VERIFICATION
--============================================================

local function UhasFEscpy(iZoQeOxOdO)
    if not iZoQeOxOdO then
        return nil
    end

    return iZoQeOxOdO:GetAttribute("ItemId")
        or iZoQeOxOdO:GetAttribute("itemId")
        or iZoQeOxOdO:GetAttribute("Id")
        or iZoQeOxOdO:GetAttribute("id")
end

local function MLuVxMKxGY(
    iZoQeOxOdO,
    DhaBjHwh,
    expectedItemId,
    allowLooseItemId
)
    if not iZoQeOxOdO or not iZoQeOxOdO:IsA("Tool") then
        return false
    end

    if iZoQeOxOdO:GetAttribute("IsSeed") == false then
        return false
    end

    local VuDvjaRnSLZL = jvVkYVzFo(DhaBjHwh)

    local OZrjIWrMvRTs =
        iZoQeOxOdO:GetAttribute("SeedType")
        or iZoQeOxOdO:GetAttribute("Seed")
        or iZoQeOxOdO:GetAttribute("SeedName")
        or iZoQeOxOdO:GetAttribute("Item")

    local zrbJyNgEPHaR = false

    if OZrjIWrMvRTs ~= nil then
        zrbJyNgEPHaR = jvVkYVzFo(OZrjIWrMvRTs) == VuDvjaRnSLZL
    else
        local rsBADmaybXb = jvVkYVzFo(iZoQeOxOdO.Name)

        zrbJyNgEPHaR =
            rsBADmaybXb == VuDvjaRnSLZL
            or rsBADmaybXb == VuDvjaRnSLZL .. " seed"
            or (
                string.sub(rsBADmaybXb, 1, #VuDvjaRnSLZL) == VuDvjaRnSLZL
                and string.find(
                    string.sub(rsBADmaybXb, #VuDvjaRnSLZL + 1),
                    "seed",
                    1,
                    true
                ) ~= nil
            )
    end

    if not zrbJyNgEPHaR then
        return false
    end

    if expectedItemId ~= nil
        and not allowLooseItemId then

        local iwPALJXk = UhasFEscpy(iZoQeOxOdO)

        -- Safe mode: if we know the exact inventory item ID,
        -- the equipped Tool must expose and match it.
        if iwPALJXk == nil
            or DfrqgXXsrB(iwPALJXk) ~= DfrqgXXsrB(expectedItemId) then
            return false
        end
    end

    return true
end

local function QrsDjipIhch(
    DhaBjHwh,
    expectedItemId,
    timeout,
    allowLooseItemId
)
    local QHmwcvVZcPU = os.clock() + (FPwbuFJZR(timeout) or 1.5)

    while PKTqUhNlA.Alive and os.clock() < QHmwcvVZcPU do
        local gfGCiliPwd = OyZLrMivikrp()

        if #gfGCiliPwd == 1 then
            local wBmRAlRrmt = gfGCiliPwd[1]

            if MLuVxMKxGY(
                wBmRAlRrmt,
                DhaBjHwh,
                expectedItemId,
                allowLooseItemId
            ) then
                return wBmRAlRrmt
            end
        end

        task.wait(0.025)
    end

    return nil
end

local function KxmYSguYv(
    DhaBjHwh,
    loPlXfSGwyxw,
    allowLooseItemId
)
    local wERpewMzabU = yfAvfulpTS()

    if not wERpewMzabU then
        return false, "character missing"
    end

    if not loPlXfSGwyxw or not loPlXfSGwyxw.Location then
        return false, "inventory location missing"
    end

    local gvsPDuYXO = loPlXfSGwyxw.Id
    local jIsUVHAQEx = jdMXqPJlODtA()

    if jIsUVHAQEx
        and MLuVxMKxGY(
            jIsUVHAQEx,
            DhaBjHwh,
            gvsPDuYXO,
            allowLooseItemId
        ) then

        return true
    end

    local VthIAVxSEI = loPlXfSGwyxw.Location

    -- ToggleEquip protocol:
    -- true = Hotbar, false = Storage/inventory, number = branch index.
    local uPirkaZfGG, ujxUlzok = BwoodiEAFu(function()
        HDDdNMSaA:FireServer(
            VthIAVxSEI.IsHotbar,
            VthIAVxSEI.Index
        )
    end)

    if not uPirkaZfGG then
        return false, "ToggleEquip failed: " .. DfrqgXXsrB(ujxUlzok)
    end

    local wBmRAlRrmt =
        QrsDjipIhch(
            DhaBjHwh,
            gvsPDuYXO,
            1.75,
            allowLooseItemId
        )

    if not wBmRAlRrmt then
        return false, "ToggleEquip did not produce exact SeedType + ItemId"
    end

    return true
end

local function RKToqRBd(DhaBjHwh)
    local jIsUVHAQEx = jdMXqPJlODtA()

    local loPlXfSGwyxw =
        ZMZXtZNTlb:ResolveSeed(
            DhaBjHwh,
            jIsUVHAQEx
        )

    if not loPlXfSGwyxw then
        local KPqHgqZokm =
            ZMZXtZNTlb:GetSeedCount(
                DhaBjHwh
            )

        if KPqHgqZokm > 0
            and not ibVEMhwTQRuM.AllowMutatedSeeds then

            return nil,
                nil,
                "Only mutated "
                    .. DfrqgXXsrB(DhaBjHwh)
                    .. " seeds are available"
        end

        return nil,
            nil,
            "Seed not found in your bag: "
                .. DfrqgXXsrB(DhaBjHwh)
    end

    if jIsUVHAQEx
        and MLuVxMKxGY(
            jIsUVHAQEx,
            DhaBjHwh,
            loPlXfSGwyxw.Id
        ) then
        return jIsUVHAQEx, loPlXfSGwyxw
    end

    if not KxmYSguYv(
        DhaBjHwh,
        loPlXfSGwyxw
    ) then
        return nil,
            loPlXfSGwyxw,
            "Could not equip exact inventory seed "
                .. DfrqgXXsrB(DhaBjHwh)
                .. " ("
                .. DfrqgXXsrB(loPlXfSGwyxw.Path)
                .. ", id="
                .. DfrqgXXsrB(loPlXfSGwyxw.Id)
                .. ")"
    end

    local wBmRAlRrmt =
        QrsDjipIhch(
            DhaBjHwh,
            loPlXfSGwyxw.Id,
            1.5
        )

    if not wBmRAlRrmt then
        return nil,
            loPlXfSGwyxw,
            "Equipped Tool did not match SeedType + ItemId"
    end

    return wBmRAlRrmt, loPlXfSGwyxw
end

local function rRUUBuGfgaxk(DhaBjHwh, expectedItemId)
    local ycMNfkdWITzR = {0, 0.05, 0.05}

    for LvOjTWuqYW, LWALSqdy in ZVOoBlCEzTM(ycMNfkdWITzR) do
        if LWALSqdy > 0 then
            task.wait(LWALSqdy)
        end

        local gfGCiliPwd = OyZLrMivikrp()
        local iZoQeOxOdO = gfGCiliPwd[1]

        if #gfGCiliPwd ~= 1
            or not iZoQeOxOdO
            or not MLuVxMKxGY(
                iZoQeOxOdO,
                DhaBjHwh,
                expectedItemId
            ) then

            return false,
                "seed verify #"
                    .. DfrqgXXsrB(LvOjTWuqYW)
                    .. " failed (equipped tools="
                    .. DfrqgXXsrB(#gfGCiliPwd)
                    .. ")"
        end
    end

    return true
end

--============================================================
-- AUTO SELL DEAD TREES
--============================================================

local function UrKxbeTklwO(XUWueugAwuSw, umiaOedd)
    if type(XUWueugAwuSw) ~= "string" then
        return false
    end

    return string.find(
        string.lower(XUWueugAwuSw),
        string.lower(umiaOedd),
        1,
        true
    ) ~= nil
end

local function frrntFCxtLm(CvVgzwvx)
    return LiOmaZCFo(CvVgzwvx, "id")
        or LiOmaZCFo(CvVgzwvx, "itemId")
        or LiOmaZCFo(CvVgzwvx, "ItemId")
        or LiOmaZCFo(CvVgzwvx, "Id")
        or LiOmaZCFo(CvVgzwvx, "uuid")
        or LiOmaZCFo(CvVgzwvx, "UUID")
end

local function rdJrWNGbGThM(CvVgzwvx)
    if type(CvVgzwvx) ~= "table" then
        return nil
    end

    local pZWezDiISM =
        jvVkYVzFo(
            LiOmaZCFo(CvVgzwvx, "itemType")
            or LiOmaZCFo(CvVgzwvx, "ItemType")
        )
    local WDWDzrmni =
        LiOmaZCFo(CvVgzwvx, "isDead")
        or LiOmaZCFo(CvVgzwvx, "IsDead")
        or LiOmaZCFo(CvVgzwvx, "Dead")

    if pZWezDiISM == "tree"
        and WDWDzrmni ~= nil then

        if WDWDzrmni ~= true then
            return nil
        end

        local pURLJBVyP =
            LiOmaZCFo(CvVgzwvx, "seedType")
            or LiOmaZCFo(CvVgzwvx, "SeedType")
            or LiOmaZCFo(CvVgzwvx, "treeType")
            or LiOmaZCFo(CvVgzwvx, "TreeType")
            or "Tree"

        return {TreeType= pURLJBVyP,
            DisplayName =
                "Dead "
                .. DfrqgXXsrB(pURLJBVyP)
                .. " Tree",
            Multiplier =
                FPwbuFJZR(
                    LiOmaZCFo(CvVgzwvx, "multiplier")
                    or LiOmaZCFo(CvVgzwvx, "Multiplier")
                    or LiOmaZCFo(CvVgzwvx, "mult")
                    or LiOmaZCFo(CvVgzwvx, "Mult")
                ),
            WoodValue =
                FPwbuFJZR(
                    LiOmaZCFo(CvVgzwvx, "woodValue")
                    or LiOmaZCFo(CvVgzwvx, "WoodValue")
                ),
            ItemId = frrntFCxtLm(CvVgzwvx),
            Raw = CvVgzwvx,
        }
    end

    local zyAFfxdNGIgV = false
    local ddResYTHxsY = false
    local pURLJBVyP = nil
    local MxRPMdGNQWn = nil
    local dqXNyVJbsaq = nil
    local sKvykwKmzSJv = frrntFCxtLm(CvVgzwvx)

    local function erNeVySH(XUWueugAwuSw)
        XUWueugAwuSw = DfrqgXXsrB(XUWueugAwuSw or "")

        if XUWueugAwuSw == "" or #XUWueugAwuSw > 80 then
            return false
        end

        return UrKxbeTklwO(XUWueugAwuSw, "dead")
            or UrKxbeTklwO(XUWueugAwuSw, "tree")
            or XUWueugAwuSw:match("%([%d%.]+%s*[xX]%)") ~= nil
    end

    local function fZjlHaquT(XUWueugAwuSw)
        XUWueugAwuSw = DfrqgXXsrB(XUWueugAwuSw or "")

        if erNeVySH(XUWueugAwuSw) and not dqXNyVJbsaq then
            dqXNyVJbsaq = XUWueugAwuSw
        end

        if UrKxbeTklwO(XUWueugAwuSw, "tree") then
            zyAFfxdNGIgV = true
        end

        if UrKxbeTklwO(XUWueugAwuSw, "dead") then
            ddResYTHxsY = true
        end

        local RMXMCvdU =
            XUWueugAwuSw:match("[Dd]ead%s+(.+)%s+[Tt]ree")
            or XUWueugAwuSw:match("(.+)%s+[Tt]ree")

        if RMXMCvdU and RMXMCvdU ~= "" and not pURLJBVyP then
            pURLJBVyP = RMXMCvdU
        end

        local eedfEsvlA =
            XUWueugAwuSw:match("%(([%d%.]+)%s*[xX]%)")

        if eedfEsvlA and not MxRPMdGNQWn then
            MxRPMdGNQWn = FPwbuFJZR(eedfEsvlA)
        end
    end

    local function eydOEnaha(XUWueugAwuSw, eRdipkcQbcnW, depth, FtEBEyLZpOZP)
        if depth > 5 then
            return
        end

        local mDHEjrNgJ = string.lower(DfrqgXXsrB(eRdipkcQbcnW or ""))

        if type(XUWueugAwuSw) == "string" then
            local QtoBGFWIF = string.lower(XUWueugAwuSw)

            if string.find(QtoBGFWIF, "tree", 1, true) then
                zyAFfxdNGIgV = true
            end

            if string.find(QtoBGFWIF, "dead", 1, true) then
                ddResYTHxsY = true
            end

            if mDHEjrNgJ == "treetype"
                or mDHEjrNgJ == "tree"
                or mDHEjrNgJ == "seedtype"
                or mDHEjrNgJ == "name"
                or mDHEjrNgJ == "displayname" then

                fZjlHaquT(XUWueugAwuSw)
                if not pURLJBVyP
                    and mDHEjrNgJ ~= "name"
                    and mDHEjrNgJ ~= "displayname" then
                    pURLJBVyP = XUWueugAwuSw
                end
            else
                fZjlHaquT(XUWueugAwuSw)
            end

            if (
                mDHEjrNgJ == "id"
                or mDHEjrNgJ == "itemid"
                or mDHEjrNgJ == "uuid"
            ) and not sKvykwKmzSJv then
                sKvykwKmzSJv = XUWueugAwuSw
            end
        elseif type(XUWueugAwuSw) == "boolean" then
            if XUWueugAwuSw == true
                and (
                    mDHEjrNgJ == "dead"
                    or mDHEjrNgJ == "isdead"
                    or string.find(mDHEjrNgJ, "dead", 1, true)
                ) then

                ddResYTHxsY = true
            end

            if XUWueugAwuSw == true
                and string.find(mDHEjrNgJ, "tree", 1, true) then

                zyAFfxdNGIgV = true
            end
        elseif type(XUWueugAwuSw) == "number" then
            if string.find(mDHEjrNgJ, "mult", 1, true)
                or mDHEjrNgJ == "multiplier" then

                MxRPMdGNQWn = MxRPMdGNQWn or XUWueugAwuSw
            end
        elseif type(XUWueugAwuSw) == "table" then
            FtEBEyLZpOZP = FtEBEyLZpOZP or {}

            if FtEBEyLZpOZP[XUWueugAwuSw] then
                return
            end

            FtEBEyLZpOZP[XUWueugAwuSw] = true

            local uyNUuLrLQw = 0

            for childKey, childValue in OFjzDxmLK(XUWueugAwuSw) do
                uyNUuLrLQw += 1

                if uyNUuLrLQw > 120 then
                    break
                end

                eydOEnaha(childValue, childKey, depth + 1, FtEBEyLZpOZP)
            end

            FtEBEyLZpOZP[XUWueugAwuSw] = nil
        end
    end

    fZjlHaquT(
        LiOmaZCFo(CvVgzwvx, "name")
        or LiOmaZCFo(CvVgzwvx, "Name")
        or LiOmaZCFo(CvVgzwvx, "displayName")
        or LiOmaZCFo(CvVgzwvx, "DisplayName")
        or LiOmaZCFo(CvVgzwvx, "treeType")
        or LiOmaZCFo(CvVgzwvx, "TreeType")
        or LiOmaZCFo(CvVgzwvx, "seedType")
        or LiOmaZCFo(CvVgzwvx, "SeedType")
    )

    eydOEnaha(CvVgzwvx, "", 0, {})

    if LiOmaZCFo(CvVgzwvx, "isDead") == true
        or LiOmaZCFo(CvVgzwvx, "IsDead") == true
        or LiOmaZCFo(CvVgzwvx, "Dead") == true then

        ddResYTHxsY = true
    end

    if UrKxbeTklwO(LiOmaZCFo(CvVgzwvx, "itemType"), "tree")
        or UrKxbeTklwO(LiOmaZCFo(CvVgzwvx, "ItemType"), "tree")
        or LiOmaZCFo(CvVgzwvx, "TreeType") ~= nil
        or LiOmaZCFo(CvVgzwvx, "treeType") ~= nil then

        zyAFfxdNGIgV = true
    end

    if not zyAFfxdNGIgV or not ddResYTHxsY then
        return nil
    end

    return {TreeType= pURLJBVyP or "Unknown",
        DisplayName = dqXNyVJbsaq,
        Multiplier = MxRPMdGNQWn,
        ItemId = sKvykwKmzSJv,
        Raw = CvVgzwvx,
    }
end

local function VUTOgsqLEhB(ksXdsOKIx)
    if not ksXdsOKIx then
        return "Dead Tree"
    end

    local CRwBIXohMQ = DfrqgXXsrB(ksXdsOKIx.DisplayName or "")

    if CRwBIXohMQ == "" then
        CRwBIXohMQ = DfrqgXXsrB(ksXdsOKIx.TreeType or "Tree")
    end

    if not UrKxbeTklwO(CRwBIXohMQ, "dead") then
        CRwBIXohMQ = "Dead " .. CRwBIXohMQ
    end

    if not UrKxbeTklwO(CRwBIXohMQ, "tree") then
        CRwBIXohMQ = CRwBIXohMQ .. " Tree"
    end

    if ksXdsOKIx.Multiplier and not CRwBIXohMQ:match("%([%d%.]+%s*[xX]%)") then
        CRwBIXohMQ = CRwBIXohMQ
            .. " ("
            .. DfrqgXXsrB(ksXdsOKIx.Multiplier)
            .. "x)"
    end

    return CRwBIXohMQ
end

local function yHrNQLoKBR()
    if not ZMZXtZNTlb:IsReady() then
        hfBLUgtjD()
    end

    local CnnSbMNHy = ZMZXtZNTlb:GetInventory()
    local XYuqTCClIeZ = {}

    if type(CnnSbMNHy) ~= "table" then
        return XYuqTCClIeZ
    end

    TjIHhQMpnV(
        CnnSbMNHy,
        "Inventory",
        function(CvVgzwvx, path)
            local VthIAVxSEI =
                oCsyfpJnzjH(path)

            if not VthIAVxSEI then
                return
            end

            local ksXdsOKIx = rdJrWNGbGThM(CvVgzwvx)

            if ksXdsOKIx then
                ksXdsOKIx.Index = VthIAVxSEI.Index
                ksXdsOKIx.IsHotbar = VthIAVxSEI.IsHotbar
                ksXdsOKIx.Container = VthIAVxSEI.Container
                ksXdsOKIx.Path = path
                ksXdsOKIx.Location = VthIAVxSEI

                XYuqTCClIeZ[#XYuqTCClIeZ + 1] = ksXdsOKIx
            end
        end
    )

    table.sort(XYuqTCClIeZ, function(a, b)
        return DfrqgXXsrB(a.Path) < DfrqgXXsrB(b.Path)
    end)

    return XYuqTCClIeZ
end

PKTqUhNlA.GetDeadTrees = yHrNQLoKBR

PKTqUhNlA.PrintDeadTrees = function()
    local yPVGQBaFWuT = yHrNQLoKBR()

    EaksGWapyD("")
    EaksGWapyD("===== KIRA DEAD TREES =====")

    for LvOjTWuqYW, ksXdsOKIx in ZVOoBlCEzTM(yPVGQBaFWuT) do
        EaksGWapyD(
            LvOjTWuqYW,
            ksXdsOKIx.Path,
            "|",
            VUTOgsqLEhB(ksXdsOKIx),
            "| ID:",
            DfrqgXXsrB(ksXdsOKIx.ItemId)
        )
    end

    EaksGWapyD("Total:", #yPVGQBaFWuT)
    EaksGWapyD("===========================")
end

local function omtzFoCmg(iZoQeOxOdO, ksXdsOKIx, allowLoose)
    if not iZoQeOxOdO or not iZoQeOxOdO:IsA("Tool") or not ksXdsOKIx then
        return false
    end

    local gvsPDuYXO = ksXdsOKIx.ItemId
    local iwPALJXk = UhasFEscpy(iZoQeOxOdO)

    if gvsPDuYXO ~= nil then
        if iwPALJXk ~= nil then
            return DfrqgXXsrB(iwPALJXk) == DfrqgXXsrB(gvsPDuYXO)
        end

        if allowLoose ~= true then
            return false
        end
    end

    local rsBADmaybXb = DfrqgXXsrB(iZoQeOxOdO.Name or "")

    if UrKxbeTklwO(rsBADmaybXb, "dead")
        and UrKxbeTklwO(rsBADmaybXb, "tree") then
        return true
    end

    if iZoQeOxOdO:GetAttribute("IsDead") == true
        or iZoQeOxOdO:GetAttribute("Dead") == true then

        if iZoQeOxOdO:GetAttribute("TreeType") ~= nil
            or iZoQeOxOdO:GetAttribute("treeType") ~= nil
            or UrKxbeTklwO(rsBADmaybXb, "tree") then

            return true
        end
    end

    return false
end

local function efcxmLlzZd(ksXdsOKIx, timeout)
    local QHmwcvVZcPU = os.clock() + (FPwbuFJZR(timeout) or 2)

    while PKTqUhNlA.Alive and os.clock() < QHmwcvVZcPU do
        local gfGCiliPwd = OyZLrMivikrp()

        if #gfGCiliPwd == 1
            and omtzFoCmg(gfGCiliPwd[1], ksXdsOKIx, true) then
            return gfGCiliPwd[1]
        end

        task.wait(0.03)
    end

    return nil
end

local function nyVtovxYkT()
    local iaojDScxh = QRxoupMChfPU()

    if iaojDScxh then
        BwoodiEAFu(function()
            iaojDScxh:UnequipTools()
        end)
    end

    task.wait(0.05)
end

local function nrsqFEykCc(ksXdsOKIx)
    if not ksXdsOKIx or not ksXdsOKIx.Location then
        return nil, "inventory location missing"
    end

    local jIsUVHAQEx = jdMXqPJlODtA()

    if omtzFoCmg(jIsUVHAQEx, ksXdsOKIx, false) then
        return jIsUVHAQEx
    end

    nyVtovxYkT()

    local uPirkaZfGG, ujxUlzok = BwoodiEAFu(function()
        HDDdNMSaA:FireServer(
            ksXdsOKIx.Location.IsHotbar,
            ksXdsOKIx.Location.Index
        )
    end)

    if not uPirkaZfGG then
        return nil, "Equip failed: " .. DfrqgXXsrB(ujxUlzok)
    end

    local wBmRAlRrmt = efcxmLlzZd(ksXdsOKIx, 2)

    if not wBmRAlRrmt then
        return nil, "Could not equip " .. VUTOgsqLEhB(ksXdsOKIx)
    end

    return wBmRAlRrmt
end

local function BnBfySFT(ksXdsOKIx, lSSAtRsxOpy)
    if not egNXrkSOdCn then
        return false, "Sell service was not found"
    end

    if not wpFutleQBCyz:AcquireBackgroundEquipment(
        "AutoSellDeadTree",
        lSSAtRsxOpy
    ) then
        return false, "cancelled"
    end

    local uPirkaZfGG, WfmhLERIYGg = bltBKQceuE(function()
        local iZoQeOxOdO, OJzlPmkLd = nrsqFEykCc(ksXdsOKIx)

        if not iZoQeOxOdO then
            ltAcELvGzk(OJzlPmkLd or "Could not equip dead tree")
        end

        if ksXdsOKIx.ItemId ~= nil then
            local iwPALJXk = UhasFEscpy(iZoQeOxOdO)

            if iwPALJXk ~= nil
                and DfrqgXXsrB(iwPALJXk) ~= DfrqgXXsrB(ksXdsOKIx.ItemId) then
                ltAcELvGzk("Equipped item changed before selling")
            end
        end

        HXuhwCIQZAB("SELLING", "warning")
        foUSPDNDz(
            "Selling " .. VUTOgsqLEhB(ksXdsOKIx) .. "...",
            "warning"
        )

        local dQSktSlt = egNXrkSOdCn:InvokeServer()

        euyMjRhaK.SellDeadTreeCount += 1
        euyMjRhaK.LastSoldDeadTree = {Name= VUTOgsqLEhB(ksXdsOKIx),
            Path = ksXdsOKIx.Path,
            Result = dQSktSlt,
        }

        PKTqUhNlA.ClearInventoryLocation(
            ksXdsOKIx.Location,
            ksXdsOKIx.ItemId
        )

        return dQSktSlt
    end, debug.traceback)

    wpFutleQBCyz:ReleaseBackgroundEquipment("AutoSellDeadTree")

    if not wpFutleQBCyz:IsPlantBusy() then
        HXuhwCIQZAB("IDLE")
    end

    if not uPirkaZfGG then
        local uRQanNSTiFqN =
            DfrqgXXsrB(WfmhLERIYGg):match("^[^\n]+")
            or DfrqgXXsrB(WfmhLERIYGg)

        foUSPDNDz("Sell dead tree failed: " .. uRQanNSTiFqN, "danger")
        return false, uRQanNSTiFqN
    end

    return true, WfmhLERIYGg
end

local function FbIMnaYWL(lSSAtRsxOpy)
    local yLbjhpVKOB = {}

    while PKTqUhNlA.Alive
        and ibVEMhwTQRuM.AutoSellDeadTree
        and not lSSAtRsxOpy() do

        if not ZMZXtZNTlb:IsReady() then
            hfBLUgtjD()
            foUSPDNDz("Waiting for bag data before selling...", "warning")

            if not pQFNwZAvvQA(0.5, lSSAtRsxOpy) then
                break
            end
        else
            local SOmfoAbH = os.clock()
            local yPVGQBaFWuT = yHrNQLoKBR()
            local otMRsdmAPve = nil

            for _, tree in ZVOoBlCEzTM(yPVGQBaFWuT) do
                local OVYmLrNOMZpK = yLbjhpVKOB[tree.Path]

                if not OVYmLrNOMZpK or OVYmLrNOMZpK <= SOmfoAbH then
                    otMRsdmAPve = tree
                    break
                end
            end

            if otMRsdmAPve then
                local XgKJlGmpyrd =
                    PKTqUhNlA.GetInventoryVersion()
                local yFYedyPjpUi = BnBfySFT(otMRsdmAPve, lSSAtRsxOpy)

                if yFYedyPjpUi then
                    foUSPDNDz(
                        "Sold "
                            .. VUTOgsqLEhB(otMRsdmAPve)
                            .. " | total "
                            .. DfrqgXXsrB(euyMjRhaK.SellDeadTreeCount),
                        "success"
                    )

                    PKTqUhNlA.WaitForInventoryRefresh(
                        XgKJlGmpyrd,
                        lSSAtRsxOpy,
                        2
                    )

                    if not pQFNwZAvvQA(ibVEMhwTQRuM.SellDelay, lSSAtRsxOpy) then
                        break
                    end
                else
                    yLbjhpVKOB[otMRsdmAPve.Path] = os.clock() + 5

                    if not pQFNwZAvvQA(0.35, lSSAtRsxOpy) then
                        break
                    end
                end
            else
                if #yPVGQBaFWuT == 0 then
                    foUSPDNDz("No dead trees in your bag")
                else
                    foUSPDNDz("Waiting before retrying dead tree sales", "warning")
                end

                if not pQFNwZAvvQA(1, lSSAtRsxOpy) then
                    break
                end
            end
        end
    end

    wpFutleQBCyz:ReleaseBackgroundEquipment("AutoSellDeadTree")

    if not wpFutleQBCyz:IsPlantBusy() then
        HXuhwCIQZAB("IDLE")
    end
end

--============================================================
-- AUTO PLANT CATALOG
--============================================================

local function xZgKeaJVSR()
    local BNnGQGeIA = {}

    for _, ROxVchvm in ZVOoBlCEzTM(tqxPJvMCxC) do
        BNnGQGeIA[#BNnGQGeIA + 1] = ROxVchvm
    end

    return BNnGQGeIA
end

PKTqUhNlA.GetAvailableSeeds = xZgKeaJVSR

local VtLHIlnk = 0

local function XiRANzkuIiam()
    local otMRsdmAPve = RyYbdTkwDtE()

    if #otMRsdmAPve == 0 then
        return nil, "No plant seed selected"
    end

    for offset = 1, #otMRsdmAPve do
        local LvOjTWuqYW = ((VtLHIlnk + offset - 1) % #otMRsdmAPve) + 1
        local DhaBjHwh = otMRsdmAPve[LvOjTWuqYW]

        if ZMZXtZNTlb:GetSeedCount(DhaBjHwh) > 0 then
            local QFnSxcLhb =
                ZMZXtZNTlb:ResolveSeed(
                    DhaBjHwh,
                    jdMXqPJlODtA()
                )

            if QFnSxcLhb then
                VtLHIlnk = LvOjTWuqYW
                ibVEMhwTQRuM.PlantSeed = DhaBjHwh
                return DhaBjHwh
            end
        end
    end

    return nil, "None of the selected seeds are available in your bag"
end

--============================================================
-- OWN PLOT
--============================================================

local function kUPNnQqxT()
    for _, EojeQsclmwhy in ZVOoBlCEzTM(cTVnIvMQRMZ:GetChildren()) do
        local IePDiBFSOqPi = FPwbuFJZR(EojeQsclmwhy:GetAttribute("OwnerUserId"))

        if IePDiBFSOqPi == dxLeYzjrD.UserId then
            euyMjRhaK.MyPlot = EojeQsclmwhy
            return EojeQsclmwhy
        end
    end

    euyMjRhaK.MyPlot = nil
    return nil
end

PKTqUhNlA.FindMyPlot = kUPNnQqxT

--============================================================
-- AUTO COMPOST SEEDS
--============================================================

local TQQVQyTiPrA = nil

local function zlLzuiziNH()
local lavgSrlnDTi = 0
local eCHBbBixk = 10
local YMsqNBUOM = 11
local IJeZfaVtoyc = 6
local jGNYWGwIvOYe = 3

local function hpuUymguVr(DhaBjHwh, DcAmitWhFX)
    local VuDvjaRnSLZL = jvVkYVzFo(DhaBjHwh)
    local ftkFgiCevokN = DcAmitWhFX and UhasFEscpy(DcAmitWhFX)
    local qLfdgteI = {}

    for _, seed in ZVOoBlCEzTM(ZMZXtZNTlb:GetSeeds()) do
        if jvVkYVzFo(seed.SeedType) == VuDvjaRnSLZL
            and (FPwbuFJZR(seed.Count) or 0) > 0
            and seed.Location ~= nil then

            local ihZCPKaH = FPwbuFJZR(seed.Count) or 0

            if ftkFgiCevokN ~= nil
                and DfrqgXXsrB(seed.Id) == DfrqgXXsrB(ftkFgiCevokN) then
                ihZCPKaH += 1000000000000
            end

            if seed.Location.IsHotbar then
                ihZCPKaH += 1000000000
            end

            qLfdgteI[#qLfdgteI + 1] = {SeedType= seed.SeedType,
                Count = seed.Count,
                Id = seed.Id,
                Mutation = seed.Mutation,
                IsMutated = seed.IsMutated,
                Path = seed.Path,
                Location = seed.Location,
                Data = seed.Data,
                Score = ihZCPKaH,
            }
        end
    end

    table.sort(qLfdgteI, function(a, b)
        if a.Score == b.Score then
            return DfrqgXXsrB(a.Path) < DfrqgXXsrB(b.Path)
        end
        return a.Score > b.Score
    end)

    return qLfdgteI[1]
end

local function mDYXXKdvx()
    local otMRsdmAPve = XuodfQsedbd()

    if #otMRsdmAPve == 0 then
        return nil, "No compost seed selected"
    end

    local jIsUVHAQEx = jdMXqPJlODtA()

    if jIsUVHAQEx then
        for _, DhaBjHwh in ZVOoBlCEzTM(otMRsdmAPve) do
            if MLuVxMKxGY(jIsUVHAQEx, DhaBjHwh, nil) then
                ibVEMhwTQRuM.CompostSeed = DhaBjHwh
                return DhaBjHwh
            end
        end
    end

    for offset = 1, #otMRsdmAPve do
        local LvOjTWuqYW = ((lavgSrlnDTi + offset - 1) % #otMRsdmAPve) + 1
        local DhaBjHwh = otMRsdmAPve[LvOjTWuqYW]
        local QFnSxcLhb =
            hpuUymguVr(
                DhaBjHwh,
                jdMXqPJlODtA()
            )

        if QFnSxcLhb then
            lavgSrlnDTi = LvOjTWuqYW
            ibVEMhwTQRuM.CompostSeed = DhaBjHwh
            return DhaBjHwh
        end
    end

    return nil, "None of the selected compost seeds are in your bag"
end

local function FsHJEOcKA()
    local wERpewMzabU = yfAvfulpTS()

    if not wERpewMzabU then
        return nil
    end

    return wERpewMzabU:FindFirstChild("HumanoidRootPart")
        or wERpewMzabU.PrimaryPart
end

local function auCVpQdmzsmA(yQJrjaPZKi)
    if not yQJrjaPZKi then
        return nil, nil
    end

    local ODlrNcZGPi = yQJrjaPZKi.Parent

    if ODlrNcZGPi and ODlrNcZGPi:IsA("BasePart") then
        return ODlrNcZGPi.Position, ODlrNcZGPi
    end

    if ODlrNcZGPi and ODlrNcZGPi:IsA("Attachment") then
        local HuXrGncZny = ODlrNcZGPi:FindFirstAncestorWhichIsA("BasePart")
        return ODlrNcZGPi.WorldPosition, HuXrGncZny
    end

    local muPHtvEg = yQJrjaPZKi:FindFirstAncestorWhichIsA("BasePart")

    if muPHtvEg then
        return muPHtvEg.Position, muPHtvEg
    end

    return nil, nil
end

local function VrrQDjyqq()
    local EojeQsclmwhy = kUPNnQqxT()

    if not EojeQsclmwhy then
        return nil, "My plot was not found"
    end

    local HNsjNhyaQ =
        EojeQsclmwhy:FindFirstChild("CompostBin")
        or EojeQsclmwhy:FindFirstChild("CompostBin", true)

    local yQJrjaPZKi = nil

    if HNsjNhyaQ then
        local sfFJiJxwdL =
            HNsjNhyaQ:FindFirstChild("PromptPart")
        if sfFJiJxwdL then
            yQJrjaPZKi =
                sfFJiJxwdL:FindFirstChild("CompostPrompt")
                or sfFJiJxwdL:FindFirstChildWhichIsA(
                    "ProximityPrompt",
                    true
                )
        end

        yQJrjaPZKi =
            yQJrjaPZKi
            or HNsjNhyaQ:FindFirstChild("CompostPrompt", true)
            or HNsjNhyaQ:FindFirstChildWhichIsA(
                "ProximityPrompt",
                true
            )
    end

    yQJrjaPZKi =
        yQJrjaPZKi
        or EojeQsclmwhy:FindFirstChild("CompostPrompt", true)

    if yQJrjaPZKi and yQJrjaPZKi:IsA("ProximityPrompt") then
        return yQJrjaPZKi
    end

    return nil, "Compost prompt was not found"
end

local function cdlpyubBHoDe(yQJrjaPZKi)
    local QtoBGFWIF =
        DfrqgXXsrB(
            yQJrjaPZKi
            and yQJrjaPZKi.ActionText
            or ""
        )

    local mGrFPvGieJAk = string.lower(QtoBGFWIF)

    if string.find(mGrFPvGieJAk, "collect", 1, true) then
        return "collect", QtoBGFWIF
    end

    if string.find(mGrFPvGieJAk, "give", 1, true) then
        return "give", QtoBGFWIF
    end

    return "unknown", QtoBGFWIF
end

local function ityBmxmMVGe(yQJrjaPZKi)
    local ggLmjaobdy, QtoBGFWIF = cdlpyubBHoDe(yQJrjaPZKi)

    euyMjRhaK.CompostMode = string.upper(ggLmjaobdy)
    euyMjRhaK.LastCompostAction = QtoBGFWIF ~= "" and QtoBGFWIF or euyMjRhaK.LastCompostAction

    return ggLmjaobdy, QtoBGFWIF
end

local function qfEGKElS(yQJrjaPZKi)
    local eNOyItOd = FsHJEOcKA()

    if not eNOyItOd then
        return nil, "character root missing"
    end

    local yQScPDyubd, muPHtvEg = auCVpQdmzsmA(yQJrjaPZKi)

    if not yQScPDyubd then
        return nil, "compost prompt position missing"
    end

    local zMSDroBKL =
        FPwbuFJZR(yQJrjaPZKi.MaxActivationDistance)
        or 12
    local axXemhEjusJI = (eNOyItOd.Position - yQScPDyubd).Magnitude

    euyMjRhaK.CompostPrompt = yQJrjaPZKi
    euyMjRhaK.CompostDistance =
        math.floor(axXemhEjusJI * 10 + 0.5) / 10

    return {Root= eNOyItOd,
        Position = yQScPDyubd,
        Part = muPHtvEg,
        MaxDistance = zMSDroBKL,
        Distance = axXemhEjusJI,
    }
end

local function xkctDfJwcp(ksXdsOKIx)
    local eNOyItOd = ksXdsOKIx.Root
    local yQScPDyubd = ksXdsOKIx.Position
    local muPHtvEg = ksXdsOKIx.Part
    local BsNmWocxkqu = eNOyItOd.Position - yQScPDyubd
    local SUjMxDPnxm = Vector3.new(BsNmWocxkqu.X, 0, BsNmWocxkqu.Z)

    if SUjMxDPnxm.Magnitude < 1 and muPHtvEg then
        local BlDTzHnuVEv = muPHtvEg.CFrame.LookVector
        SUjMxDPnxm = Vector3.new(-BlDTzHnuVEv.X, 0, -BlDTzHnuVEv.Z)
    end

    if SUjMxDPnxm.Magnitude < 0.1 then
        SUjMxDPnxm = Vector3.new(0, 0, -1)
    end

    local EBqZuFAZS =
        math.min(
            IJeZfaVtoyc,
            math.max(4, (ksXdsOKIx.MaxDistance or 12) * 0.5)
        )
    local UwGsJUXRQAa = SUjMxDPnxm.Unit
    local umiaOedd =
        yQScPDyubd
        + (UwGsJUXRQAa * EBqZuFAZS)
    local MoLMGZsP = eNOyItOd.Position.Y
    local aVfVROmVuWCP =
        Vector3.new(umiaOedd.X, MoLMGZsP, umiaOedd.Z)
    local VeuhEylPBmsJ =
        Vector3.new(yQScPDyubd.X, MoLMGZsP, yQScPDyubd.Z)

    return CFrame.new(aVfVROmVuWCP, VeuhEylPBmsJ)
end

local function aVhDMLoLZ(yQJrjaPZKi, ksXdsOKIx)
    if euyMjRhaK.CompostAnchorPrompt ~= yQJrjaPZKi
        or typeof(euyMjRhaK.CompostAnchor) ~= "CFrame" then

        euyMjRhaK.CompostAnchorPrompt = yQJrjaPZKi
        euyMjRhaK.CompostAnchor =
            xkctDfJwcp(ksXdsOKIx)
    end

    return euyMjRhaK.CompostAnchor
end

local function EaqphqpMLI(yQJrjaPZKi, ksXdsOKIx)
    local eNOyItOd = ksXdsOKIx.Root
    local iaojDScxh = QRxoupMChfPU()

    if iaojDScxh then
        BwoodiEAFu(function()
            iaojDScxh.Sit = false
        end)
    end

    BwoodiEAFu(function()
        eNOyItOd.AssemblyLinearVelocity = Vector3.zero
        eNOyItOd.AssemblyAngularVelocity = Vector3.zero
    end)

    eNOyItOd.CFrame = aVhDMLoLZ(yQJrjaPZKi, ksXdsOKIx)
    euyMjRhaK.CompostTeleportCount += 1

    local SOmfoAbH = os.clock()
    if SOmfoAbH - (euyMjRhaK.LastCompostLeashNotice or 0)
        > jGNYWGwIvOYe then

        euyMjRhaK.LastCompostLeashNotice = SOmfoAbH
        AoDYQAJZTEZM(
            "Auto Compost Seed",
            "Auto Compost đang chạy. Hãy ở gần Compost Bin cho đến khi tắt.",
            "warning",
            3.5
        )
    end
end

local function FYNvIHAMyJIJ(yQJrjaPZKi, limit, lSSAtRsxOpy)
    local ksXdsOKIx, DCuONQIRL = qfEGKElS(yQJrjaPZKi)

    if not ksXdsOKIx then
        return false, DCuONQIRL
    end

    local zMSDroBKL =
        FPwbuFJZR(ksXdsOKIx.MaxDistance)
        or 12
    local mJMZOryZWawI =
        math.min(
            FPwbuFJZR(limit) or eCHBbBixk,
            math.max(3, zMSDroBKL - 1)
        )

    if ksXdsOKIx.Distance <= mJMZOryZWawI then
        return true, false
    end

    if not wpFutleQBCyz:WaitPlantClear(lSSAtRsxOpy) then
        return false, "waiting for planting to finish"
    end

    ksXdsOKIx, DCuONQIRL = qfEGKElS(yQJrjaPZKi)

    if not ksXdsOKIx then
        return false, DCuONQIRL
    end

    EaqphqpMLI(yQJrjaPZKi, ksXdsOKIx)
    foUSPDNDz(
        "Returned to compost area",
        "warning"
    )

    return true, true
end

local function ElSRDydYCrj(lSSAtRsxOpy)
    while PKTqUhNlA.Alive
        and ibVEMhwTQRuM.AutoCompostSeed
        and not lSSAtRsxOpy() do

        local yQJrjaPZKi = VrrQDjyqq()

        if yQJrjaPZKi then
            ityBmxmMVGe(yQJrjaPZKi)
            FYNvIHAMyJIJ(
                yQJrjaPZKi,
                YMsqNBUOM,
                lSSAtRsxOpy
            )
        else
            euyMjRhaK.CompostMode = "MISSING"
            euyMjRhaK.CompostDistance = 0
            euyMjRhaK.CompostAnchor = nil
            euyMjRhaK.CompostPrompt = nil
            euyMjRhaK.CompostAnchorPrompt = nil
        end

        task.wait(0.15)
    end
end

local function FjHSTilJhA(yQJrjaPZKi)
    if not yQJrjaPZKi then
        return false, "CompostPrompt missing"
    end

    if type(fireproximityprompt) ~= "function" then
        return false, "fireproximityprompt unavailable"
    end

    local uPirkaZfGG, ujxUlzok = BwoodiEAFu(function()
        fireproximityprompt(yQJrjaPZKi)
    end)

    if not uPirkaZfGG then
        return false, DfrqgXXsrB(ujxUlzok)
    end

    return true
end

local function ZUOjVjPEKjr(yQJrjaPZKi)
    HXuhwCIQZAB("COMPOST", "warning")
    foUSPDNDz("Collecting compost...", "warning")

    local XbUDFIepRJM, aAIBWyUMkPz = FjHSTilJhA(yQJrjaPZKi)
    if not XbUDFIepRJM then
        ltAcELvGzk(aAIBWyUMkPz)
    end

    euyMjRhaK.CompostCollectCount += 1
    euyMjRhaK.CompostCount += 1
    euyMjRhaK.LastCompostAction = "Collect"
    euyMjRhaK.LastCompostSeed = nil

    return "collect"
end

local function LqpmdhxAjM(DhaBjHwh)
    local jIsUVHAQEx = jdMXqPJlODtA()

    if jIsUVHAQEx
        and MLuVxMKxGY(jIsUVHAQEx, DhaBjHwh, nil) then

        return jIsUVHAQEx, nil, nil
    end

    local loPlXfSGwyxw =
        hpuUymguVr(
            DhaBjHwh,
            jIsUVHAQEx
        )

    if not loPlXfSGwyxw then
        return nil,
            nil,
            "Seed not found in your bag: "
                .. DfrqgXXsrB(DhaBjHwh)
    end

    local ABGeANcWlwK, OJzlPmkLd =
        KxmYSguYv(
            DhaBjHwh,
            loPlXfSGwyxw,
            true
        )

    if not ABGeANcWlwK then
        return nil,
            loPlXfSGwyxw,
            OJzlPmkLd
                or (
                    "Could not equip compost seed "
                    .. DfrqgXXsrB(DhaBjHwh)
                )
    end

    local wBmRAlRrmt =
        QrsDjipIhch(
            DhaBjHwh,
            loPlXfSGwyxw.Id,
            1.5,
            true
        )

    if not wBmRAlRrmt then
        return nil,
            loPlXfSGwyxw,
            "Compost seed was not equipped"
    end

    return wBmRAlRrmt, loPlXfSGwyxw
end

local function ReJoilryb(DhaBjHwh)
    local jIsUVHAQEx = jdMXqPJlODtA()

    if not jIsUVHAQEx then
        return false, "You are not holding a seed"
    end

    if not MLuVxMKxGY(jIsUVHAQEx, DhaBjHwh, nil) then
        return false,
            "You are not holding "
                .. DfrqgXXsrB(DhaBjHwh)
                .. " seed"
    end

    return true
end

local function zHlhhpSq(lSSAtRsxOpy)
    local yQJrjaPZKi, aIHGDUstExJb = VrrQDjyqq()

    if not yQJrjaPZKi then
        return false, aIHGDUstExJb
    end

    local ggLmjaobdy = ityBmxmMVGe(yQJrjaPZKi)
    local DhaBjHwh = nil
    local MHYAAEXgCdz = nil

    if ggLmjaobdy == "unknown" then
        foUSPDNDz(
            "Waiting for Compost Bin prompt...",
            "warning"
        )
        return false, "Compost prompt is not ready"
    end

    if ggLmjaobdy ~= "collect" then
        DhaBjHwh, MHYAAEXgCdz = mDYXXKdvx()

        if not DhaBjHwh then
            return false, MHYAAEXgCdz
        end
    end

    if not wpFutleQBCyz:AcquireBackgroundEquipment(
        "AutoCompostSeed",
        lSSAtRsxOpy
    ) then
        return false, "cancelled"
    end

    local RnCJjUHos = nil

    local uPirkaZfGG, lyIbGZBLJjNW = bltBKQceuE(function()
        yQJrjaPZKi, aIHGDUstExJb = VrrQDjyqq()
        if not yQJrjaPZKi then
            ltAcELvGzk(aIHGDUstExJb)
        end

        ggLmjaobdy = ityBmxmMVGe(yQJrjaPZKi)

        local hFIoNJWzPg, GRaogDOUFhnW =
            FYNvIHAMyJIJ(
                yQJrjaPZKi,
                eCHBbBixk,
                lSSAtRsxOpy
            )

        if not hFIoNJWzPg then
            ltAcELvGzk(GRaogDOUFhnW or "Could not move into compost range")
        end

        if GRaogDOUFhnW == true then
            task.wait(0.08)
        end

        if ggLmjaobdy == "unknown" then
            foUSPDNDz(
                "Waiting for Compost Bin prompt...",
                "warning"
            )
            return "wait"
        end

        if ggLmjaobdy == "collect" then
            RnCJjUHos =
                PKTqUhNlA.GetInventoryVersion()
            return ZUOjVjPEKjr(yQJrjaPZKi)
        end

        DhaBjHwh, MHYAAEXgCdz = mDYXXKdvx()
        if not DhaBjHwh then
            ltAcELvGzk(MHYAAEXgCdz)
        end

        HXuhwCIQZAB("COMPOST", "warning")
        foUSPDNDz(
            "Composting "
                .. DfrqgXXsrB(DhaBjHwh)
                .. " seed...",
            "warning"
        )

        local wBmRAlRrmt,
            loPlXfSGwyxw,
            OJzlPmkLd =
                LqpmdhxAjM(DhaBjHwh)

        if not wBmRAlRrmt then
            ltAcELvGzk(OJzlPmkLd or "Could not equip compost seed")
        end

        task.wait(0.08)

        yQJrjaPZKi, aIHGDUstExJb = VrrQDjyqq()
        if not yQJrjaPZKi then
            ltAcELvGzk(aIHGDUstExJb)
        end

        ggLmjaobdy = ityBmxmMVGe(yQJrjaPZKi)

        hFIoNJWzPg, GRaogDOUFhnW =
            FYNvIHAMyJIJ(
                yQJrjaPZKi,
                eCHBbBixk,
                lSSAtRsxOpy
            )

        if not hFIoNJWzPg then
            ltAcELvGzk(GRaogDOUFhnW or "Could not move into compost range")
        end

        if GRaogDOUFhnW == true then
            task.wait(0.08)
        end

        ggLmjaobdy = ityBmxmMVGe(yQJrjaPZKi)

        if ggLmjaobdy == "collect" then
            RnCJjUHos =
                PKTqUhNlA.GetInventoryVersion()
            return ZUOjVjPEKjr(yQJrjaPZKi)
        elseif ggLmjaobdy ~= "give" then
            foUSPDNDz(
                "Waiting for Compost Bin prompt...",
                "warning"
            )
            return "wait"
        end

        local RPUuMSzuaPOX, sTbPRrpHKm =
            ReJoilryb(DhaBjHwh)

        if not RPUuMSzuaPOX then
            foUSPDNDz(
                "Compost waiting: "
                    .. DfrqgXXsrB(sTbPRrpHKm),
                "warning"
            )
            return "wait"
        end

        RnCJjUHos =
            PKTqUhNlA.GetInventoryVersion()

        local XbUDFIepRJM, aAIBWyUMkPz = FjHSTilJhA(yQJrjaPZKi)
        if not XbUDFIepRJM then
            ltAcELvGzk(aAIBWyUMkPz)
        end

        euyMjRhaK.LastCompostAction = "Give Seed"
        euyMjRhaK.LastCompostSeed = DhaBjHwh
        euyMjRhaK.CompostGiveCount += 1
        euyMjRhaK.CompostCount += 1

        foUSPDNDz(
            "Give Seed fired: "
                .. DfrqgXXsrB(DhaBjHwh)
        )

        return DhaBjHwh
    end, debug.traceback)

    wpFutleQBCyz:ReleaseBackgroundEquipment("AutoCompostSeed")

    if not wpFutleQBCyz:IsPlantBusy() then
        HXuhwCIQZAB("IDLE")
    end

    if not uPirkaZfGG then
        local uRQanNSTiFqN =
            DfrqgXXsrB(lyIbGZBLJjNW):match("^[^\n]+")
            or DfrqgXXsrB(lyIbGZBLJjNW)

        foUSPDNDz("Auto Compost failed: " .. uRQanNSTiFqN, "danger")
        return false, uRQanNSTiFqN
    end

    if lyIbGZBLJjNW == "wait" then
        return true, lyIbGZBLJjNW
    elseif lyIbGZBLJjNW == "collect" then
        if RnCJjUHos ~= nil then
            PKTqUhNlA.WaitForInventoryRefresh(
                RnCJjUHos,
                lSSAtRsxOpy,
                2
            )
        end

        foUSPDNDz("Compost collected")
    else
        if RnCJjUHos ~= nil then
            PKTqUhNlA.WaitForInventoryRefresh(
                RnCJjUHos,
                lSSAtRsxOpy,
                2
            )
        end

        foUSPDNDz("Composted " .. DfrqgXXsrB(lyIbGZBLJjNW) .. " seed")
    end

    return true, lyIbGZBLJjNW
end

TQQVQyTiPrA = function(lSSAtRsxOpy)
    nFPpZjLd(
        "CompostMovementGuard",
        ElSRDydYCrj
    )

    AoDYQAJZTEZM(
        "Auto Compost Seed",
        "Đã bật Auto Compost Seed. Script sẽ giữ bạn trong vùng compost khi cần.",
        "warning",
        4
    )

    while PKTqUhNlA.Alive
        and ibVEMhwTQRuM.AutoCompostSeed
        and not lSSAtRsxOpy() do

        local uPirkaZfGG = zHlhhpSq(lSSAtRsxOpy)

        if lSSAtRsxOpy()
            or not ibVEMhwTQRuM.AutoCompostSeed then
            break
        end

        local LWALSqdy =
            uPirkaZfGG and ibVEMhwTQRuM.CompostDelay or 0.75

        if not pQFNwZAvvQA(LWALSqdy, lSSAtRsxOpy) then
            break
        end
    end

    PxzWtllXIL("CompostMovementGuard")
    wpFutleQBCyz:ReleaseBackgroundEquipment("AutoCompostSeed")
    euyMjRhaK.CompostAnchor = nil
    euyMjRhaK.CompostPrompt = nil
    euyMjRhaK.CompostAnchorPrompt = nil

    if not wpFutleQBCyz:IsPlantBusy() then
        HXuhwCIQZAB("IDLE")
    end
end

PKTqUhNlA.GetCompostSeeds = function()
    return XuodfQsedbd()
end

PKTqUhNlA.CompostOnce = function()
    return zHlhhpSq(function()
        return not PKTqUhNlA.Alive
    end)
end

end

zlLzuiziNH()

--============================================================
-- PLANT ROUND LIFECYCLE
--============================================================

local function RfAxgCjnjg(kHtWakxlAm)
    if not kHtWakxlAm then
        return nil
    end

    return FPwbuFJZR(
        DfrqgXXsrB(kHtWakxlAm.Name):match("_(%d+)$")
    )
end

local function xgaAZuLdymsR(kHtWakxlAm)
    if not kHtWakxlAm then
        return nil
    end

    local cZYiEHIJWAEh = kHtWakxlAm:FindFirstChild("MultDisplay")

    if not cZYiEHIJWAEh then
        return nil
    end

    return cZYiEHIJWAEh:FindFirstChild("ProximityPrompt")
        or cZYiEHIJWAEh:FindFirstChildWhichIsA("ProximityPrompt", true)
end

local function VXbzSdNydTv(kHtWakxlAm)
    if not kHtWakxlAm or not kHtWakxlAm.Parent then
        return false
    end

    if string.sub(
        DfrqgXXsrB(kHtWakxlAm.Name),
        1,
        #"PlantRound_"
    ) ~= "PlantRound_" then
        return false
    end

    local iCVWKWYZwjHS =
        "PlantRound_"
        .. DfrqgXXsrB(dxLeYzjrD.UserId)
        .. "_"

    if string.sub(kHtWakxlAm.Name, 1, #iCVWKWYZwjHS) == iCVWKWYZwjHS then
        return true
    end

    local yQJrjaPZKi = xgaAZuLdymsR(kHtWakxlAm)

    if yQJrjaPZKi then
        local TchWhIGbaLz =
            yQJrjaPZKi:GetAttribute("PlantOwnerID")
            or yQJrjaPZKi:GetAttribute("PlantOwnerId")

        if FPwbuFJZR(TchWhIGbaLz) == dxLeYzjrD.UserId then
            return true
        end
    end

    local TchWhIGbaLz =
        kHtWakxlAm:GetAttribute("PlantOwnerID")
        or kHtWakxlAm:GetAttribute("PlantOwnerId")

    return FPwbuFJZR(TchWhIGbaLz) == dxLeYzjrD.UserId
end

local function lciEiyCr()
    local meYmQTnufS = {}

    for _, child in ZVOoBlCEzTM(UQqophNh:GetChildren()) do
        if VXbzSdNydTv(child) then
            meYmQTnufS[#meYmQTnufS + 1] = child
        end
    end

    table.sort(meYmQTnufS, function(a, b)
        return (RfAxgCjnjg(a) or 0)
            < (RfAxgCjnjg(b) or 0)
    end)

    return meYmQTnufS
end

local function eymQWPKD()
    local QZYVNgIzkz = {}
    local qkySwoMOnU = 0

    for _, kHtWakxlAm in ZVOoBlCEzTM(lciEiyCr()) do
        QZYVNgIzkz[kHtWakxlAm] = true
        qkySwoMOnU = math.max(
            qkySwoMOnU,
            RfAxgCjnjg(kHtWakxlAm) or 0
        )
    end

    return QZYVNgIzkz, qkySwoMOnU
end

local function HYpjMmzn(QtoBGFWIF)
    QtoBGFWIF = DfrqgXXsrB(QtoBGFWIF or "")

    local pQvnqyZnr =
        QtoBGFWIF:match("([%d]+%.?[%d]*)%s*[xX]")
        or QtoBGFWIF:match("([%d]+%.?[%d]*)")

    return FPwbuFJZR(pQvnqyZnr)
end

local buxBHzlExq = Color3.fromRGB(255, 50, 50)

local function JFQRzFlAXQJ(a, b, tolerance)
    tolerance = FPwbuFJZR(tolerance) or (1 / 255)

    return math.abs(a.R - b.R) <= tolerance
        and math.abs(a.G - b.G) <= tolerance
        and math.abs(a.B - b.B) <= tolerance
end

local function ciyEOPymQW(kHtWakxlAm)
    if not VXbzSdNydTv(kHtWakxlAm) then
        return nil
    end

    local cZYiEHIJWAEh = kHtWakxlAm:FindFirstChild("MultDisplay")
    local dzGwxesc =
        cZYiEHIJWAEh
        and cZYiEHIJWAEh:FindFirstChild("BillboardGui")

    local JIxfYesp =
        dzGwxesc
        and dzGwxesc:FindFirstChild("MainFrame")

    local wfvYmaqRGdp =
        JIxfYesp
        and JIxfYesp:FindFirstChild("Mult")

    local zgNYkbRit =
        JIxfYesp
        and JIxfYesp:FindFirstChild("Value")

    local MxRPMdGNQWn = nil

    if wfvYmaqRGdp
        and (
            wfvYmaqRGdp:IsA("TextLabel")
            or wfvYmaqRGdp:IsA("TextButton")
            or wfvYmaqRGdp:IsA("TextBox")
        ) then
        MxRPMdGNQWn = HYpjMmzn(wfvYmaqRGdp.Text)
    end

    local fRSOIIhPQ = false

    if zgNYkbRit
        and (
            zgNYkbRit:IsA("TextLabel")
            or zgNYkbRit:IsA("TextButton")
            or zgNYkbRit:IsA("TextBox")
        ) then
        local uaUfBgyz =
            DfrqgXXsrB(zgNYkbRit.Text or "")

        local DUKhdbKIb =
            uaUfBgyz:gsub("%s+", "")

        fRSOIIhPQ =
            JFQRzFlAXQJ(
                zgNYkbRit.TextColor3,
                buxBHzlExq,
                2 / 255
            )
            or string.find(
                DUKhdbKIb,
                "255,50,50",
                1,
                true
            ) ~= nil
    end

    local yQJrjaPZKi = xgaAZuLdymsR(kHtWakxlAm)
    local TchWhIGbaLz = nil

    if yQJrjaPZKi then
        TchWhIGbaLz =
            yQJrjaPZKi:GetAttribute("PlantOwnerID")
            or yQJrjaPZKi:GetAttribute("PlantOwnerId")
    end

    return {Round= kHtWakxlAm,
        Serial = RfAxgCjnjg(kHtWakxlAm),
        MultDisplay = cZYiEHIJWAEh,
        Billboard = dzGwxesc,
        MainFrame = JIxfYesp,
        MultLabel = wfvYmaqRGdp,
        ValueLabel = zgNYkbRit,
        Multiplier = MxRPMdGNQWn,
        Dead = fRSOIIhPQ,
        Prompt = yQJrjaPZKi,
        OwnerId = FPwbuFJZR(TchWhIGbaLz),
    }
end

local function UFtCUOsISQtE(beforeSet, beforeMaxSerial, timeout)
    local QHmwcvVZcPU =
        os.clock() + (FPwbuFJZR(timeout) or 3)

    while PKTqUhNlA.Alive and os.clock() < QHmwcvVZcPU do
        local lGcrYDHyzQ = nil

        for _, kHtWakxlAm in ZVOoBlCEzTM(lciEiyCr()) do
            local mtjjZPXM = RfAxgCjnjg(kHtWakxlAm) or 0

            if not beforeSet[kHtWakxlAm]
                or mtjjZPXM > beforeMaxSerial then

                if not lGcrYDHyzQ
                    or mtjjZPXM > (RfAxgCjnjg(lGcrYDHyzQ) or 0) then
                    lGcrYDHyzQ = kHtWakxlAm
                end
            end
        end

        if lGcrYDHyzQ then
            return lGcrYDHyzQ
        end

        task.wait(0.04)
    end

    return nil
end

local function SQlPAyWBEQ(LNufBNUJAR)
    if LNufBNUJAR
        and LNufBNUJAR.PlantRound
        and LNufBNUJAR.PlantRound.Parent
        and VXbzSdNydTv(LNufBNUJAR.PlantRound) then
        return LNufBNUJAR.PlantRound
    end

    local MzrzoZEjZohK =
        LNufBNUJAR
        and LNufBNUJAR.BeforeRoundSerial
        or 0

    local jMfmkYAPhthA = nil

    for _, kHtWakxlAm in ZVOoBlCEzTM(lciEiyCr()) do
        local mtjjZPXM = RfAxgCjnjg(kHtWakxlAm) or 0

        if mtjjZPXM > MzrzoZEjZohK
            and (
                not jMfmkYAPhthA
                or mtjjZPXM > (RfAxgCjnjg(jMfmkYAPhthA) or 0)
            ) then
            jMfmkYAPhthA = kHtWakxlAm
        end
    end

    if LNufBNUJAR and jMfmkYAPhthA then
        LNufBNUJAR.PlantRound = jMfmkYAPhthA
    end

    return jMfmkYAPhthA
end

PKTqUhNlA.GetOwnPlantRounds = lciEiyCr
PKTqUhNlA.GetPlantRoundInfo = ciyEOPymQW

local HpqCsUNehWs = setmetatable({}, {__mode= "k",
})

local function vrGYPXgh(kHtWakxlAm, DhaBjHwh)
    if kHtWakxlAm and DhaBjHwh then
        HpqCsUNehWs[kHtWakxlAm] = DfrqgXXsrB(DhaBjHwh)
    end
end

local function EgiwikUN(kHtWakxlAm)
    if not kHtWakxlAm then
        return nil
    end

    local DhaBjHwh = HpqCsUNehWs[kHtWakxlAm]

    if DhaBjHwh then
        return DhaBjHwh
    end

    local LNufBNUJAR = euyMjRhaK.LastPlantContext

    if LNufBNUJAR
        and LNufBNUJAR.PlantRound == kHtWakxlAm
        and LNufBNUJAR.Seed then

        DhaBjHwh = DfrqgXXsrB(LNufBNUJAR.Seed)
        vrGYPXgh(kHtWakxlAm, DhaBjHwh)
        return DhaBjHwh
    end

    return nil
end

local function PwPdrJwbG(kHtWakxlAm)
    return DGUSmiSQl(EgiwikUN(kHtWakxlAm))
end

PKTqUhNlA.GetHarvestTargetForSeed = DGUSmiSQl
PKTqUhNlA.GetHarvestTargetForRound = PwPdrJwbG

--============================================================
-- MUTATION SCANNER
--============================================================

local function xiZaGgEVoUD(QtoBGFWIF)
    QtoBGFWIF = DfrqgXXsrB(QtoBGFWIF or "")
    QtoBGFWIF = QtoBGFWIF:gsub("<.->", "")
    QtoBGFWIF = QtoBGFWIF:gsub("&amp;", "&")
    QtoBGFWIF = QtoBGFWIF:gsub("&lt;", "<")
    QtoBGFWIF = QtoBGFWIF:gsub("&gt;", ">")
    QtoBGFWIF = QtoBGFWIF:gsub("^%s+", ""):gsub("%s+$", "")
    return QtoBGFWIF
end

local function zIwNzVxielXw(QtoBGFWIF)
    QtoBGFWIF = DfrqgXXsrB(QtoBGFWIF or "")
    QtoBGFWIF = QtoBGFWIF:gsub("&", "&amp;")
    QtoBGFWIF = QtoBGFWIF:gsub("<", "&lt;")
    QtoBGFWIF = QtoBGFWIF:gsub(">", "&gt;")
    return QtoBGFWIF
end

local function cagbPKyCDdA(QtoBGFWIF)
    return (DfrqgXXsrB(QtoBGFWIF or ""):match("^%s*(.-)%s*$")) or ""
end

local function eulgADICZF(QtoBGFWIF)
    QtoBGFWIF = cagbPKyCDdA(QtoBGFWIF)

    if QtoBGFWIF == "" then
        return ""
    end

    if QtoBGFWIF:find("<font", 1, true)
        or QtoBGFWIF:find("<b>", 1, true)
        or QtoBGFWIF:find("<i>", 1, true)
        or QtoBGFWIF:find("<u>", 1, true)
        or QtoBGFWIF:find("<s>", 1, true) then

        return QtoBGFWIF
    end

    return zIwNzVxielXw(QtoBGFWIF)
end

local function JHeHuWKa(QtoBGFWIF)
    QtoBGFWIF = xiZaGgEVoUD(QtoBGFWIF)
    QtoBGFWIF = QtoBGFWIF:gsub("[\r\n]+", ",")
    QtoBGFWIF = QtoBGFWIF:gsub("%s*[%+,%|]%s*", ",")
    QtoBGFWIF = QtoBGFWIF:gsub("%s*,%s*", ",")

    local BNnGQGeIA = {}
    local QZYVNgIzkz = {}

    for muPHtvEg in QtoBGFWIF:gmatch("[^,]+") do
        local XUWueugAwuSw = cagbPKyCDdA(muPHtvEg)
        XUWueugAwuSw =
            cagbPKyCDdA(
                XUWueugAwuSw:gsub("^[Mm]utations?:%s*", "")
            )

        local eRdipkcQbcnW = jvVkYVzFo(XUWueugAwuSw)

        if XUWueugAwuSw ~= ""
            and eRdipkcQbcnW ~= "none"
            and eRdipkcQbcnW ~= "normal"
            and eRdipkcQbcnW ~= "no mutation"
            and eRdipkcQbcnW ~= "no mutations"
            and eRdipkcQbcnW ~= "mutation"
            and eRdipkcQbcnW ~= "mutations"
            and not QZYVNgIzkz[eRdipkcQbcnW] then

            QZYVNgIzkz[eRdipkcQbcnW] = true
            BNnGQGeIA[#BNnGQGeIA + 1] = XUWueugAwuSw
        end
    end

    return BNnGQGeIA
end

local EqJoEozgzfg = {
    "Dewy",
    "Dusty",
    "Frosted",
    "Shocked",
    "Radioactive",
    "Golden",
    "Cosmic",
}

local function TRBZSzHi(QtoBGFWIF)
    local NQYAzsomZ = JHeHuWKa(QtoBGFWIF)

    if #NQYAzsomZ > 1 then
        return #NQYAzsomZ, NQYAzsomZ
    end

    local SgxiIThqSlXm = xiZaGgEVoUD(QtoBGFWIF)
    local cTAyyytM = string.lower(SgxiIThqSlXm)
    local EJWoSYJFtW = {}
    local QZYVNgIzkz = {}

    for _, mutationName in ZVOoBlCEzTM(EqJoEozgzfg) do
        local eRdipkcQbcnW = jvVkYVzFo(mutationName)

        if string.find(
            cTAyyytM,
            eRdipkcQbcnW,
            1,
            true
        ) and not QZYVNgIzkz[eRdipkcQbcnW] then

            EJWoSYJFtW[#EJWoSYJFtW + 1] = mutationName
            QZYVNgIzkz[eRdipkcQbcnW] = true
        end
    end

    if #EJWoSYJFtW > 0 then
        return #EJWoSYJFtW, EJWoSYJFtW
    end

    return #NQYAzsomZ, NQYAzsomZ
end

local function FGApyjULGyb(XUWueugAwuSw)
    if XUWueugAwuSw == nil then
        return nil
    end

    if typeof(XUWueugAwuSw) == "number" then
        local QtoBGFWIF = DfrqgXXsrB(math.floor(XUWueugAwuSw * 100 + 0.5) / 100)
        return QtoBGFWIF
    end

    local QtoBGFWIF = cagbPKyCDdA(XUWueugAwuSw)

    if QtoBGFWIF == "" then
        return nil
    end

    return QtoBGFWIF
end

local function NQgnmBye(instance, names)
    if not instance then
        return nil
    end

    for _, CRwBIXohMQ in ZVOoBlCEzTM(names) do
        local XUWueugAwuSw = instance:GetAttribute(CRwBIXohMQ)
        local rebdYfoIFFw = FGApyjULGyb(XUWueugAwuSw)

        if rebdYfoIFFw then
            return rebdYfoIFFw
        end
    end

    return nil
end

local function BdMdWktPyu(eNOyItOd, names, patterns)
    if not eNOyItOd then
        return nil
    end

    local VuDvjaRnSLZL = {}

    for _, CRwBIXohMQ in ZVOoBlCEzTM(names or {}) do
        VuDvjaRnSLZL[string.lower(CRwBIXohMQ)] = true
    end

    for _, obj in ZVOoBlCEzTM(eNOyItOd:GetDescendants()) do
        if obj:IsA("TextLabel")
            or obj:IsA("TextButton")
            or obj:IsA("TextBox") then

            local QtoBGFWIF = xiZaGgEVoUD(obj.Text)

            if QtoBGFWIF ~= "" then
                local QUlyWSImzyd = string.lower(obj.Name)

                if VuDvjaRnSLZL[QUlyWSImzyd] then
                    return QtoBGFWIF
                end

                for _, pattern in ZVOoBlCEzTM(patterns or {}) do
                    if string.find(string.lower(QtoBGFWIF), pattern, 1, true) then
                        return QtoBGFWIF
                    end
                end
            end
        end
    end

    return nil
end

local function HWmcIHkgz(JIxfYesp, bTjKsleJ)
    local QtoBGFWIF =
        BdMdWktPyu(
            JIxfYesp,
            {
                "Fruit Money",
                "FruitMoney",
                "Value",
                "FruitValue",
                "Money",
            },
            {
                "$/min",
                "fruit $",
                "value",
            }
        )

    if QtoBGFWIF then
        return QtoBGFWIF
    end

    return NQgnmBye(
        bTjKsleJ,
        {
            "FruitValue",
            "Value",
            "FruitMoney",
            "Money",
            "CoinsPerMinute",
        }
    )
end

local function QrbIxVJEqHGh(bTjKsleJ, fallbackText)
    local hVKRNUmvaW = cagbPKyCDdA(xiZaGgEVoUD(fallbackText))

    if hVKRNUmvaW ~= ""
        and jvVkYVzFo(hVKRNUmvaW) ~= "none" then

        return hVKRNUmvaW
    end

    local wizwGhwnAuC =
        NQgnmBye(
            bTjKsleJ,
            {
                "FruitMutation",
                "Mutations",
                "Mutation",
            }
        )

    if wizwGhwnAuC then
        return wizwGhwnAuC
    end

    local ODlrNcZGPi = bTjKsleJ and bTjKsleJ.Parent

    for _ = 1, 4 do
        if not ODlrNcZGPi then
            break
        end

        wizwGhwnAuC =
            NQgnmBye(
                ODlrNcZGPi,
                {
                    "FruitMutation",
                    "Mutations",
                    "Mutation",
                }
            )

        if wizwGhwnAuC then
            return wizwGhwnAuC
        end

        ODlrNcZGPi = ODlrNcZGPi.Parent
    end

    return fallbackText
end

local function psKuspqQP()
    local EojeQsclmwhy = kUPNnQqxT()
    if not EojeQsclmwhy then
        return {}, "My plot was not found"
    end

    local YUytgcWIyg = vhsjTXIP:FindFirstChild("PlotBillboards")
    if not YUytgcWIyg then
        return {}, "PlotBillboards was not found"
    end

    local XYuqTCClIeZ = {}

    for _, dzGwxesc in ZVOoBlCEzTM(YUytgcWIyg:GetDescendants()) do
        if dzGwxesc:IsA("BillboardGui")
            and dzGwxesc.Name == "FruitBillboard_WithPrompt"
            and dzGwxesc.Adornee
            and dzGwxesc.Adornee.Name == "FruitSpawn"
            and dzGwxesc.Adornee:IsDescendantOf(EojeQsclmwhy) then

            local JIxfYesp = dzGwxesc:FindFirstChild("MainFrame")

            if JIxfYesp then
                local ZyfAwIMnhA = JIxfYesp:FindFirstChild("Name")
                local cVJIkOMOr = JIxfYesp:FindFirstChild("Mutations")

                local GMhMNUmf = "Unknown"
                local FgynLSfATX = "None"
                local MYfIeqgbb = "None"

                if ZyfAwIMnhA and (ZyfAwIMnhA:IsA("TextLabel") or ZyfAwIMnhA:IsA("TextButton") or ZyfAwIMnhA:IsA("TextBox")) then
                    GMhMNUmf = xiZaGgEVoUD(ZyfAwIMnhA.Text)
                end

                if cVJIkOMOr
                    and (cVJIkOMOr:IsA("TextLabel") or cVJIkOMOr:IsA("TextButton") or cVJIkOMOr:IsA("TextBox"))
                    and cVJIkOMOr.Text ~= "" then
                    local EWcINeRRS =
                        xiZaGgEVoUD(cVJIkOMOr.Text)

                    if EWcINeRRS ~= "" then
                        FgynLSfATX = EWcINeRRS
                        MYfIeqgbb =
                            eulgADICZF(cVJIkOMOr.Text)
                    end
                end

                local bTjKsleJ = dzGwxesc.Adornee
                local BCOlhEka =
                    QrbIxVJEqHGh(bTjKsleJ, FgynLSfATX)
                local wnnztFOY, QnFyVawVul =
                    TRBZSzHi(BCOlhEka)

                if #QnFyVawVul > 0 then
                    FgynLSfATX =
                        table.concat(QnFyVawVul, " + ")
                else
                    local pUgvDQrSXl =
                        cagbPKyCDdA(xiZaGgEVoUD(BCOlhEka))

                    if pUgvDQrSXl ~= ""
                        and jvVkYVzFo(pUgvDQrSXl) ~= "none" then

                        FgynLSfATX = pUgvDQrSXl
                    else
                        FgynLSfATX = "None"
                    end
                end

                if MYfIeqgbb == "None"
                    and FgynLSfATX ~= "None" then

                    MYfIeqgbb =
                        zIwNzVxielXw(FgynLSfATX)
                end

                local uaUfBgyz = HWmcIHkgz(JIxfYesp, bTjKsleJ)
                local MSZbokKn =
                    NQgnmBye(
                        bTjKsleJ,
                        {
                            "FruitSizeMult",
                            "SizeMultiplier",
                            "SizeMult",
                        }
                    )

                table.insert(XYuqTCClIeZ, {Name= GMhMNUmf,
                    Mutation = FgynLSfATX,
                    MutationRichText = MYfIeqgbb,
                    MutationSource = BCOlhEka,
                    MutationParts = QnFyVawVul,
                    MutationCount = wnnztFOY,
                    FruitValue = uaUfBgyz,
                    SizeMultiplier = MSZbokKn,
                    FruitSpawn = bTjKsleJ,
                    Billboard = dzGwxesc,
                    Plot = EojeQsclmwhy,
                })
            end
        end
    end

    table.sort(XYuqTCClIeZ, function(a, b)
        if a.Name == b.Name then
            return a.Mutation < b.Mutation
        end
        return a.Name < b.Name
    end)

    euyMjRhaK.FruitListedCount = #XYuqTCClIeZ
    return XYuqTCClIeZ
end

PKTqUhNlA.ScanMyMutations = psKuspqQP

local function ErFGTEfyIlQM()
    local OVYmLrNOMZpK =
        setmetatable({}, {__mode= "k",
        })

    local function nHmHODxTv(ksXdsOKIx)
        local bTjKsleJ =
            ksXdsOKIx and ksXdsOKIx.FruitSpawn

        if not bTjKsleJ or not bTjKsleJ.Parent then
            return nil
        end

        return bTjKsleJ:FindFirstChild("ProximityPrompt")
            or bTjKsleJ:FindFirstChildWhichIsA(
                "ProximityPrompt",
                true
            )
    end

    local function EjXJqYlPo(ksXdsOKIx, yQJrjaPZKi)
        local bTjKsleJ =
            ksXdsOKIx and ksXdsOKIx.FruitSpawn

        if not bTjKsleJ or not bTjKsleJ.Parent then
            return true
        end

        if ksXdsOKIx.Billboard and not ksXdsOKIx.Billboard.Parent then
            return true
        end

        if yQJrjaPZKi and not yQJrjaPZKi.Parent then
            return true
        end

        local uPirkaZfGG, mnlJbSzzP =
            BwoodiEAFu(function()
                return yQJrjaPZKi and yQJrjaPZKi.Enabled
            end)

        if uPirkaZfGG and mnlJbSzzP == false then
            return true
        end

        return false
    end

    local function wJiqCFIY(ksXdsOKIx, yQJrjaPZKi, timeout)
        local QHmwcvVZcPU =
            os.clock() + (FPwbuFJZR(timeout) or 0.75)

        while PKTqUhNlA.Alive and os.clock() < QHmwcvVZcPU do
            if EjXJqYlPo(ksXdsOKIx, yQJrjaPZKi) then
                return true
            end

            task.wait(0.04)
        end

        return EjXJqYlPo(ksXdsOKIx, yQJrjaPZKi)
    end

    local function vKnUaAxk(ksXdsOKIx)
        if ibVEMhwTQRuM.CollectAllFruit then
            return true
        end

        local YLgISKeuTi =
            math.max(
                0,
                math.floor(
                    (FPwbuFJZR(ibVEMhwTQRuM.MinFruitMutations) or 0)
                    + 0.5
                )
            )

        return (FPwbuFJZR(ksXdsOKIx.MutationCount) or 0) >= YLgISKeuTi
    end

    local function jVDkEsMUsjr(ksXdsOKIx, lSSAtRsxOpy)
        if not ksXdsOKIx
            or not ksXdsOKIx.FruitSpawn
            or not ksXdsOKIx.FruitSpawn.Parent then

            return false, "fruit-missing"
        end

        if not vKnUaAxk(ksXdsOKIx) then
            return false, "filtered"
        end

        local zSrEarOfx =
            OVYmLrNOMZpK[ksXdsOKIx.FruitSpawn] or 0

        if zSrEarOfx > os.clock() then
            return false, "cooldown"
        end

        local yQJrjaPZKi =
            nHmHODxTv(ksXdsOKIx)

        if not yQJrjaPZKi then
            OVYmLrNOMZpK[ksXdsOKIx.FruitSpawn] = os.clock() + 1
            return false, "prompt-missing"
        end

        if type(fireproximityprompt) ~= "function" then
            foUSPDNDz(
                "Fruit collect needs fireproximityprompt",
                "danger"
            )
            return false, "fireproximityprompt-unavailable"
        end

        if not wpFutleQBCyz:AcquireAction(
            "AutoCollectFruit",
            lSSAtRsxOpy,
            1
        ) then
            return false, "busy"
        end

        if lSSAtRsxOpy()
            or not ibVEMhwTQRuM.AutoCollectFruit
            or not ksXdsOKIx.FruitSpawn.Parent
            or not vKnUaAxk(ksXdsOKIx) then

            wpFutleQBCyz:ReleaseAction("AutoCollectFruit")
            return false, "cancelled"
        end

        yQJrjaPZKi = nHmHODxTv(ksXdsOKIx)

        if not yQJrjaPZKi then
            wpFutleQBCyz:ReleaseAction("AutoCollectFruit")
            OVYmLrNOMZpK[ksXdsOKIx.FruitSpawn] = os.clock() + 1
            return false, "prompt-missing"
        end

        HXuhwCIQZAB("COLLECT FRUIT", "warning")
        foUSPDNDz(
            "Collecting "
                .. DfrqgXXsrB(ksXdsOKIx.Name or "fruit")
                .. " ("
                .. DfrqgXXsrB(ksXdsOKIx.MutationCount or 0)
                .. " mutation(s))",
            "warning"
        )

        local XbUDFIepRJM, aAIBWyUMkPz =
            BwoodiEAFu(function()
                fireproximityprompt(yQJrjaPZKi)
            end)

        local RcEgnLXWKPPQ = false

        if XbUDFIepRJM then
            RcEgnLXWKPPQ = wJiqCFIY(ksXdsOKIx, yQJrjaPZKi, 0.75)
        end

        wpFutleQBCyz:ReleaseAction("AutoCollectFruit")

        if not wpFutleQBCyz:IsPlantBusy() then
            HXuhwCIQZAB("IDLE")
        end

        if not XbUDFIepRJM then
            OVYmLrNOMZpK[ksXdsOKIx.FruitSpawn] = os.clock() + 1.5
            foUSPDNDz(
                "Collect fruit failed: "
                    .. DfrqgXXsrB(aAIBWyUMkPz),
                "danger"
            )
            return false, DfrqgXXsrB(aAIBWyUMkPz)
        end

        if not RcEgnLXWKPPQ then
            OVYmLrNOMZpK[ksXdsOKIx.FruitSpawn] = os.clock() + 1.25
            foUSPDNDz(
                "Collect fruit was not confirmed yet",
                "warning"
            )
            return false, "unverified"
        end

        OVYmLrNOMZpK[ksXdsOKIx.FruitSpawn] = nil
        euyMjRhaK.FruitCollectCount += 1
        euyMjRhaK.LastCollectedFruit = {Name= ksXdsOKIx.Name,
            MutationCount = ksXdsOKIx.MutationCount,
            Mutation = ksXdsOKIx.Mutation,
            At = os.clock(),
        }

        return true, "collected"
    end

    local function EDGuBRaC(lSSAtRsxOpy)
        local tBOlbjGIlYW, ujxUlzok =
            psKuspqQP()

        if ujxUlzok then
            return 0, ujxUlzok, 0
        end

        table.sort(tBOlbjGIlYW, function(a, b)
            local BXVtJveZsHQ = FPwbuFJZR(a.MutationCount) or 0
            local AiSghBSLYKJ = FPwbuFJZR(b.MutationCount) or 0

            if BXVtJveZsHQ == AiSghBSLYKJ then
                return DfrqgXXsrB(a.Name) < DfrqgXXsrB(b.Name)
            end

            return BXVtJveZsHQ > AiSghBSLYKJ
        end)

        local mwLRTkUYiu = 0
        local GpCYQIsOilaM = 0

        for _, bTjKsleJ in ZVOoBlCEzTM(tBOlbjGIlYW) do
            if lSSAtRsxOpy()
                or not ibVEMhwTQRuM.AutoCollectFruit then
                break
            end

            if vKnUaAxk(bTjKsleJ) then
                mwLRTkUYiu += 1

                local uPirkaZfGG =
                    jVDkEsMUsjr(bTjKsleJ, lSSAtRsxOpy)

                if uPirkaZfGG then
                    GpCYQIsOilaM += 1

                    if not pQFNwZAvvQA(
                        ibVEMhwTQRuM.FruitCollectDelay,
                        lSSAtRsxOpy
                    ) then
                        break
                    end
                else
                    task.wait(0.02)
                end
            end
        end

        return GpCYQIsOilaM, nil, mwLRTkUYiu
    end

    local function xIPKitYl(lSSAtRsxOpy)
        local fCZgzZoj = 0

        while PKTqUhNlA.Alive
            and ibVEMhwTQRuM.AutoCollectFruit
            and not lSSAtRsxOpy() do

            local GpCYQIsOilaM, ujxUlzok, mwLRTkUYiu =
                EDGuBRaC(lSSAtRsxOpy)

            if ujxUlzok then
                foUSPDNDz(
                    "Fruit collect waiting: "
                        .. DfrqgXXsrB(ujxUlzok),
                    "warning"
                )
            elseif GpCYQIsOilaM > 0 then
                foUSPDNDz(
                    "Collected "
                        .. DfrqgXXsrB(GpCYQIsOilaM)
                        .. " fruit(s) | total "
                        .. DfrqgXXsrB(euyMjRhaK.FruitCollectCount),
                    "success"
                )
                fCZgzZoj = os.clock()
            elseif os.clock() - fCZgzZoj >= 3 then
                if mwLRTkUYiu > 0 then
                    foUSPDNDz(
                        "Fruit matched; waiting before retrying collection",
                        "warning"
                    )
                elseif ibVEMhwTQRuM.CollectAllFruit then
                    foUSPDNDz("No fruit ready to collect")
                else
                    foUSPDNDz(
                        "No fruit has "
                            .. DfrqgXXsrB(ibVEMhwTQRuM.MinFruitMutations)
                            .. "+ mutation(s) yet"
                    )
                end

                fCZgzZoj = os.clock()
            end

            if not pQFNwZAvvQA(
                ibVEMhwTQRuM.FruitCollectInterval,
                lSSAtRsxOpy
            ) then
                break
            end
        end

        wpFutleQBCyz:ReleaseAction("AutoCollectFruit")

        if not wpFutleQBCyz:IsPlantBusy() then
            HXuhwCIQZAB("IDLE")
        end
    end

    return xIPKitYl
end

local kMZYSSjK =
    ErFGTEfyIlQM()

local function UuxadzuPhcII()
    local function LLzZMVPHPnSt(CRwBIXohMQ)
        CRwBIXohMQ = DfrqgXXsrB(CRwBIXohMQ or "")

        for group in CRwBIXohMQ:gmatch("%(([^%)]*)%)") do
            local tShfQYgpdzVr =
                cagbPKyCDdA(xiZaGgEVoUD(group))

            if tShfQYgpdzVr ~= ""
                and not tShfQYgpdzVr:match("^[%d%.]+%s*[xX]$") then

                return tShfQYgpdzVr
            end
        end

        return ""
    end

    local function jwQjUPUNPfoz(XUWueugAwuSw)
        XUWueugAwuSw = DfrqgXXsrB(XUWueugAwuSw or "")

        local MxRPMdGNQWn =
            XUWueugAwuSw:match("%(([%d%.]+)%s*[xX]%)")
            or XUWueugAwuSw:match("([%d%.]+)%s*[xX]")

        return FPwbuFJZR(MxRPMdGNQWn)
    end

    local function wQCkYsiuAmfU(XUWueugAwuSw)
        XUWueugAwuSw = xiZaGgEVoUD(XUWueugAwuSw)
        XUWueugAwuSw = XUWueugAwuSw:gsub("[\r\n]+", " ")
        XUWueugAwuSw = XUWueugAwuSw:gsub("%s+", " ")
        return cagbPKyCDdA(XUWueugAwuSw)
    end

    local function kjoiCYVHEhgt(XUWueugAwuSw)
        XUWueugAwuSw = wQCkYsiuAmfU(XUWueugAwuSw)

        if XUWueugAwuSw == "" then
            return false
        end

        if not UrKxbeTklwO(XUWueugAwuSw, "fruit") then
            return false
        end

        return UrKxbeTklwO(XUWueugAwuSw, "basket")
            or UrKxbeTklwO(XUWueugAwuSw, "crate")
            or UrKxbeTklwO(XUWueugAwuSw, "box")
            or UrKxbeTklwO(XUWueugAwuSw, "pack")
            or UrKxbeTklwO(XUWueugAwuSw, "bundle")
            or UrKxbeTklwO(XUWueugAwuSw, "container")
    end

    local function nbaNjbSc(XUWueugAwuSw)
        XUWueugAwuSw = wQCkYsiuAmfU(XUWueugAwuSw)

        if XUWueugAwuSw == ""
            or #XUWueugAwuSw > 180
            or jvVkYVzFo(XUWueugAwuSw) == "fruit"
            or jvVkYVzFo(XUWueugAwuSw) == "fruits"
            or kjoiCYVHEhgt(XUWueugAwuSw)
            or UrKxbeTklwO(XUWueugAwuSw, "seed")
            or (
                UrKxbeTklwO(XUWueugAwuSw, "dead")
                and UrKxbeTklwO(XUWueugAwuSw, "tree")
            ) then

            return false
        end

        return UrKxbeTklwO(XUWueugAwuSw, "fruit")
    end

    local function qjXQywHRDBbP(CvVgzwvx)
        local BSPGrulBdTMz =
            LiOmaZCFo(CvVgzwvx, "mutations")
            or LiOmaZCFo(CvVgzwvx, "Mutations")
            or LiOmaZCFo(CvVgzwvx, "mutation")
            or LiOmaZCFo(CvVgzwvx, "Mutation")

        if type(BSPGrulBdTMz) == "table" then
            local NQYAzsomZ = {}
            local QZYVNgIzkz = {}

            for LvOjTWuqYW = 1, #BSPGrulBdTMz do
                local XUWueugAwuSw =
                    cagbPKyCDdA(xiZaGgEVoUD(BSPGrulBdTMz[LvOjTWuqYW]))
                local eRdipkcQbcnW =
                    jvVkYVzFo(XUWueugAwuSw)

                if XUWueugAwuSw ~= ""
                    and eRdipkcQbcnW ~= "none"
                    and not QZYVNgIzkz[eRdipkcQbcnW] then

                    QZYVNgIzkz[eRdipkcQbcnW] = true
                    NQYAzsomZ[#NQYAzsomZ + 1] = XUWueugAwuSw
                end
            end

            for _, XUWueugAwuSw in OFjzDxmLK(BSPGrulBdTMz) do
                if type(XUWueugAwuSw) ~= "table" then
                    local QtoBGFWIF =
                        cagbPKyCDdA(xiZaGgEVoUD(XUWueugAwuSw))
                    local eRdipkcQbcnW =
                        jvVkYVzFo(QtoBGFWIF)

                    if QtoBGFWIF ~= ""
                        and eRdipkcQbcnW ~= "none"
                        and not QZYVNgIzkz[eRdipkcQbcnW] then

                        QZYVNgIzkz[eRdipkcQbcnW] = true
                        NQYAzsomZ[#NQYAzsomZ + 1] = QtoBGFWIF
                    end
                end
            end

            return table.concat(NQYAzsomZ, " + ")
        end

        if BSPGrulBdTMz ~= nil then
            return cagbPKyCDdA(xiZaGgEVoUD(BSPGrulBdTMz))
        end

        return ""
    end

    local function nTRqdnwSZ(CvVgzwvx)
        if type(CvVgzwvx) ~= "table" then
            return nil
        end

        local pZWezDiISM =
            jvVkYVzFo(
                LiOmaZCFo(CvVgzwvx, "itemType")
                or LiOmaZCFo(CvVgzwvx, "ItemType")
            )

        if pZWezDiISM == "seed"
            or UrKxbeTklwO(pZWezDiISM, "seed")
            or rdJrWNGbGThM(CvVgzwvx) ~= nil then

            return nil
        end

        local wjRCgzROOWzU =
            LiOmaZCFo(CvVgzwvx, "fruitName")
            or LiOmaZCFo(CvVgzwvx, "FruitName")
        local brFeJHrLrSF =
            LiOmaZCFo(CvVgzwvx, "seedType")
            or LiOmaZCFo(CvVgzwvx, "SeedType")
        local nPBKoHmyT =
            LiOmaZCFo(CvVgzwvx, "fruitType")
            or LiOmaZCFo(CvVgzwvx, "FruitType")

        if pZWezDiISM == "fruit"
            or wjRCgzROOWzU ~= nil
            or nPBKoHmyT ~= nil then

            local QpGRyxcf =
                qjXQywHRDBbP(CvVgzwvx)
            local wnnztFOY = 0
            local QnFyVawVul = {}

            if QpGRyxcf ~= "" then
                wnnztFOY, QnFyVawVul =
                    TRBZSzHi(QpGRyxcf)
            end

            local dqXNyVJbsaq =
                wjRCgzROOWzU
                or LiOmaZCFo(CvVgzwvx, "name")
                or LiOmaZCFo(CvVgzwvx, "Name")
                or LiOmaZCFo(CvVgzwvx, "displayName")
                or LiOmaZCFo(CvVgzwvx, "DisplayName")
                or nPBKoHmyT
                or "Fruit"

            return {FruitType=
                    brFeJHrLrSF
                    or nPBKoHmyT
                    or dqXNyVJbsaq
                    or "Fruit",
                DisplayName = dqXNyVJbsaq,
                Multiplier =
                    FPwbuFJZR(
                        LiOmaZCFo(CvVgzwvx, "multiplier")
                        or LiOmaZCFo(CvVgzwvx, "Multiplier")
                        or LiOmaZCFo(CvVgzwvx, "mult")
                        or LiOmaZCFo(CvVgzwvx, "Mult")
                    ),
                SellValue =
                    FPwbuFJZR(
                        LiOmaZCFo(CvVgzwvx, "sellValue")
                        or LiOmaZCFo(CvVgzwvx, "SellValue")
                    ),
                MutationText = QpGRyxcf,
                MutationCount = wnnztFOY,
                MutationParts = QnFyVawVul,
                ItemId = frrntFCxtLm(CvVgzwvx),
                Raw = CvVgzwvx,
            }
        end

        local TbsynaNqjIVh = false
        local WdfNOCpFotZw = nil
        local dqXNyVJbsaq = nil
        local MxRPMdGNQWn = nil
        local QpGRyxcf = nil
        local sKvykwKmzSJv = frrntFCxtLm(CvVgzwvx)
        local QZcesAMXLRbt = false

        local function crxMacQFGB(XUWueugAwuSw)
            return kjoiCYVHEhgt(XUWueugAwuSw)
        end

        local function DrExoqpZBW(XUWueugAwuSw)
            return nbaNjbSc(XUWueugAwuSw)
        end

        local function YufPwtBAKRQM(XUWueugAwuSw, mDHEjrNgJ)
            XUWueugAwuSw = DfrqgXXsrB(XUWueugAwuSw or "")

            if XUWueugAwuSw == "" then
                return
            end

            if crxMacQFGB(XUWueugAwuSw) then
                QZcesAMXLRbt = true
                return
            end

            if DrExoqpZBW(XUWueugAwuSw) then
                TbsynaNqjIVh = true

                if not dqXNyVJbsaq then
                    dqXNyVJbsaq = XUWueugAwuSw
                end
            end

            if UrKxbeTklwO(XUWueugAwuSw, "fruit") then
                TbsynaNqjIVh = true
            end

            if not WdfNOCpFotZw
                and (
                    mDHEjrNgJ == "fruittype"
                    or mDHEjrNgJ == "fruit"
                    or mDHEjrNgJ == "seedtype"
                ) then

                WdfNOCpFotZw = XUWueugAwuSw
            end

            MxRPMdGNQWn =
                MxRPMdGNQWn
                or jwQjUPUNPfoz(XUWueugAwuSw)

            local OhjWNJad =
                LLzZMVPHPnSt(XUWueugAwuSw)

            if OhjWNJad ~= ""
                and not QpGRyxcf then

                QpGRyxcf = OhjWNJad
            end
        end

        local function eydOEnaha(XUWueugAwuSw, eRdipkcQbcnW, depth, FtEBEyLZpOZP)
            if depth > 5 then
                return
            end

            local mDHEjrNgJ =
                jvVkYVzFo(eRdipkcQbcnW)

            if type(XUWueugAwuSw) == "string" then
                if mDHEjrNgJ == "id"
                    or mDHEjrNgJ == "itemid"
                    or mDHEjrNgJ == "uuid" then

                    sKvykwKmzSJv = sKvykwKmzSJv or XUWueugAwuSw
                end

                if string.find(mDHEjrNgJ, "fruit", 1, true) then
                    TbsynaNqjIVh = true
                end

                if string.find(mDHEjrNgJ, "mutation", 1, true)
                    and not QpGRyxcf then

                    QpGRyxcf = XUWueugAwuSw
                end

                YufPwtBAKRQM(XUWueugAwuSw, mDHEjrNgJ)
            elseif type(XUWueugAwuSw) == "number" then
                if string.find(mDHEjrNgJ, "mult", 1, true)
                    or mDHEjrNgJ == "multiplier" then

                    MxRPMdGNQWn = MxRPMdGNQWn or XUWueugAwuSw
                end
            elseif type(XUWueugAwuSw) == "table" then
                FtEBEyLZpOZP = FtEBEyLZpOZP or {}

                if FtEBEyLZpOZP[XUWueugAwuSw] then
                    return
                end

                FtEBEyLZpOZP[XUWueugAwuSw] = true

                local uyNUuLrLQw = 0

                for childKey, childValue in OFjzDxmLK(XUWueugAwuSw) do
                    uyNUuLrLQw += 1

                    if uyNUuLrLQw > 140 then
                        break
                    end

                    eydOEnaha(childValue, childKey, depth + 1, FtEBEyLZpOZP)
                end

                FtEBEyLZpOZP[XUWueugAwuSw] = nil
            end
        end

        YufPwtBAKRQM(
            LiOmaZCFo(CvVgzwvx, "name")
            or LiOmaZCFo(CvVgzwvx, "Name")
            or LiOmaZCFo(CvVgzwvx, "displayName")
            or LiOmaZCFo(CvVgzwvx, "DisplayName")
            or LiOmaZCFo(CvVgzwvx, "fruitType")
            or LiOmaZCFo(CvVgzwvx, "FruitType")
            or LiOmaZCFo(CvVgzwvx, "seedType")
            or LiOmaZCFo(CvVgzwvx, "SeedType"),
            "name"
        )

        eydOEnaha(CvVgzwvx, "", 0, {})

        local hDAdlIkB =
            dqXNyVJbsaq
            or LiOmaZCFo(CvVgzwvx, "name")
            or LiOmaZCFo(CvVgzwvx, "Name")
            or LiOmaZCFo(CvVgzwvx, "displayName")
            or LiOmaZCFo(CvVgzwvx, "DisplayName")
            or pZWezDiISM

        if crxMacQFGB(hDAdlIkB)
            and not WdfNOCpFotZw
            and not MxRPMdGNQWn
            and not QpGRyxcf then

            return nil
        end

        if UrKxbeTklwO(pZWezDiISM, "fruit")
            or LiOmaZCFo(CvVgzwvx, "fruitType") ~= nil
            or LiOmaZCFo(CvVgzwvx, "FruitType") ~= nil then

            TbsynaNqjIVh = true
        end

        if not TbsynaNqjIVh then
            return nil
        end

        local wnnztFOY = 0
        local QnFyVawVul = {}

        if QpGRyxcf then
            wnnztFOY, QnFyVawVul =
                TRBZSzHi(QpGRyxcf)
        end

        return {FruitType= WdfNOCpFotZw or "Fruit",
            DisplayName = dqXNyVJbsaq,
            Multiplier = MxRPMdGNQWn,
            MutationText = QpGRyxcf,
            MutationCount = wnnztFOY,
            MutationParts = QnFyVawVul,
            ItemId = sKvykwKmzSJv,
            Raw = CvVgzwvx,
        }
    end

    local function UlWCzTFgJsk(ksXdsOKIx)
        if not ksXdsOKIx then
            return "Fruit"
        end

        local CRwBIXohMQ =
            cagbPKyCDdA(ksXdsOKIx.DisplayName or "")

        if CRwBIXohMQ == "" then
            CRwBIXohMQ = DfrqgXXsrB(ksXdsOKIx.FruitType or "Fruit")
        end

        if not UrKxbeTklwO(CRwBIXohMQ, "fruit") then
            CRwBIXohMQ = CRwBIXohMQ .. " Fruit"
        end

        if ksXdsOKIx.Multiplier
            and not CRwBIXohMQ:match("%([%d%.]+%s*[xX]%)") then

            CRwBIXohMQ = CRwBIXohMQ
                .. " ("
                .. DfrqgXXsrB(ksXdsOKIx.Multiplier)
                .. "x)"
        end

        return CRwBIXohMQ
    end

    local function IePsMfSJ()
        if not ZMZXtZNTlb:IsReady() then
            hfBLUgtjD()
        end

        local CnnSbMNHy =
            ZMZXtZNTlb:GetInventory()

        local XYuqTCClIeZ = {}

        if type(CnnSbMNHy) == "table" then
            TjIHhQMpnV(
                CnnSbMNHy,
                "Inventory",
                function(CvVgzwvx, path)
                    local VthIAVxSEI =
                        oCsyfpJnzjH(path)

                    if not VthIAVxSEI then
                        return
                    end

                    local ksXdsOKIx =
                        nTRqdnwSZ(CvVgzwvx)

                    if ksXdsOKIx then
                        ksXdsOKIx.Index = VthIAVxSEI.Index
                        ksXdsOKIx.IsHotbar = VthIAVxSEI.IsHotbar
                        ksXdsOKIx.Container = VthIAVxSEI.Container
                        ksXdsOKIx.Path = path
                        ksXdsOKIx.Location = VthIAVxSEI

                        XYuqTCClIeZ[#XYuqTCClIeZ + 1] = ksXdsOKIx
                    end
                end
            )
        end

        local ECBzCRvri = {}

        for _, ksXdsOKIx in ZVOoBlCEzTM(XYuqTCClIeZ) do
            if ksXdsOKIx.ItemId ~= nil then
                ECBzCRvri[DfrqgXXsrB(ksXdsOKIx.ItemId)] = true
            end
        end

        local function SFoJKgcRI(iZoQeOxOdO)
            if not iZoQeOxOdO or not iZoQeOxOdO:IsA("Tool") then
                return false
            end

            local CRwBIXohMQ =
                DfrqgXXsrB(iZoQeOxOdO.Name or "")

            if CRwBIXohMQ == ""
                or UrKxbeTklwO(CRwBIXohMQ, "seed")
                or UrKxbeTklwO(CRwBIXohMQ, "basket")
                or UrKxbeTklwO(CRwBIXohMQ, "crate")
                or UrKxbeTklwO(CRwBIXohMQ, "box")
                or UrKxbeTklwO(CRwBIXohMQ, "pack")
                or UrKxbeTklwO(CRwBIXohMQ, "bundle")
                or UrKxbeTklwO(CRwBIXohMQ, "container")
                or (
                    UrKxbeTklwO(CRwBIXohMQ, "dead")
                    and UrKxbeTklwO(CRwBIXohMQ, "tree")
                ) then

                return false
            end

            local pZWezDiISM =
                jvVkYVzFo(
                    iZoQeOxOdO:GetAttribute("ItemType")
                    or iZoQeOxOdO:GetAttribute("itemType")
                )

            return UrKxbeTklwO(CRwBIXohMQ, "fruit")
                or pZWezDiISM == "fruit"
                or UrKxbeTklwO(pZWezDiISM, "fruit")
                or iZoQeOxOdO:GetAttribute("FruitType") ~= nil
                or iZoQeOxOdO:GetAttribute("fruitType") ~= nil
        end

        local function PXwEpaVjQupp(iZoQeOxOdO, containerName)
            if not SFoJKgcRI(iZoQeOxOdO) then
                return
            end

            local sKvykwKmzSJv = UhasFEscpy(iZoQeOxOdO)

            if sKvykwKmzSJv ~= nil
                and ECBzCRvri[DfrqgXXsrB(sKvykwKmzSJv)] then
                return
            end

            local TqnClSCVSK =
                "Tool."
                .. DfrqgXXsrB(containerName or "Bag")
                .. "."
                .. DfrqgXXsrB(iZoQeOxOdO.Name)

            if sKvykwKmzSJv == nil
                and ECBzCRvri[TqnClSCVSK] then
                return
            end

            ECBzCRvri[sKvykwKmzSJv ~= nil and DfrqgXXsrB(sKvykwKmzSJv) or TqnClSCVSK] = true

            local CRwBIXohMQ =
                DfrqgXXsrB(iZoQeOxOdO.Name or "Fruit")
            local WdfNOCpFotZw =
                iZoQeOxOdO:GetAttribute("FruitType")
                or iZoQeOxOdO:GetAttribute("fruitType")
                or CRwBIXohMQ:match("^%s*(.-)%s+[Ff]ruit")
                or "Fruit"
            local QpGRyxcf =
                iZoQeOxOdO:GetAttribute("Mutations")
                or iZoQeOxOdO:GetAttribute("Mutation")
                or LLzZMVPHPnSt(CRwBIXohMQ)
            local wnnztFOY = 0
            local QnFyVawVul = {}

            if QpGRyxcf then
                wnnztFOY, QnFyVawVul =
                    TRBZSzHi(QpGRyxcf)
            end

            XYuqTCClIeZ[#XYuqTCClIeZ + 1] = {FruitType= WdfNOCpFotZw,
                DisplayName = CRwBIXohMQ,
                Multiplier =
                    FPwbuFJZR(iZoQeOxOdO:GetAttribute("Multiplier"))
                    or FPwbuFJZR(iZoQeOxOdO:GetAttribute("multiplier"))
                    or jwQjUPUNPfoz(CRwBIXohMQ),
                MutationText = QpGRyxcf,
                MutationCount = wnnztFOY,
                MutationParts = QnFyVawVul,
                ItemId = sKvykwKmzSJv,
                Tool = iZoQeOxOdO,
                Path = TqnClSCVSK,
                Raw = iZoQeOxOdO,
            }
        end

        local wERpewMzabU =
            yfAvfulpTS()

        if wERpewMzabU then
            for _, child in ZVOoBlCEzTM(wERpewMzabU:GetChildren()) do
                PXwEpaVjQupp(child, "Character")
            end
        end

        local EpqpXlAKwSFT =
            dxLeYzjrD:FindFirstChild("Backpack")

        if EpqpXlAKwSFT then
            for _, child in ZVOoBlCEzTM(EpqpXlAKwSFT:GetChildren()) do
                PXwEpaVjQupp(child, "Backpack")
            end
        end

        table.sort(XYuqTCClIeZ, function(a, b)
            local hTrUggddvX = FPwbuFJZR(a.Multiplier) or 0
            local HDnHfXdy = FPwbuFJZR(b.Multiplier) or 0

            if hTrUggddvX == HDnHfXdy then
                return DfrqgXXsrB(a.Path) < DfrqgXXsrB(b.Path)
            end

            return hTrUggddvX < HDnHfXdy
        end)

        return XYuqTCClIeZ
    end

    local function OEuDdXtu(iZoQeOxOdO, ksXdsOKIx, allowLoose)
        if not iZoQeOxOdO or not iZoQeOxOdO:IsA("Tool") or not ksXdsOKIx then
            return false
        end

        local rsBADmaybXb =
            DfrqgXXsrB(iZoQeOxOdO.Name or "")

        if UrKxbeTklwO(rsBADmaybXb, "seed")
            or (
                UrKxbeTklwO(rsBADmaybXb, "fruit")
                and (
                    UrKxbeTklwO(rsBADmaybXb, "basket")
                    or UrKxbeTklwO(rsBADmaybXb, "crate")
                    or UrKxbeTklwO(rsBADmaybXb, "box")
                    or UrKxbeTklwO(rsBADmaybXb, "pack")
                    or UrKxbeTklwO(rsBADmaybXb, "bundle")
                    or UrKxbeTklwO(rsBADmaybXb, "container")
                )
            )
            or (
                UrKxbeTklwO(rsBADmaybXb, "dead")
                and UrKxbeTklwO(rsBADmaybXb, "tree")
            ) then

            return false
        end

        if ksXdsOKIx.Tool ~= nil
            and iZoQeOxOdO == ksXdsOKIx.Tool then
            return true
        end

        local gvsPDuYXO =
            ksXdsOKIx.ItemId

        local iwPALJXk =
            UhasFEscpy(iZoQeOxOdO)

        if gvsPDuYXO ~= nil then
            if iwPALJXk ~= nil then
                return DfrqgXXsrB(iwPALJXk) == DfrqgXXsrB(gvsPDuYXO)
            end

            if allowLoose ~= true then
                return false
            end
        end

        if UrKxbeTklwO(rsBADmaybXb, "fruit") then
            return true
        end

        local qUGiGWtRUR =
            jvVkYVzFo(
                iZoQeOxOdO:GetAttribute("ItemType")
                or iZoQeOxOdO:GetAttribute("itemType")
            )

        if qUGiGWtRUR == "fruit"
            or UrKxbeTklwO(qUGiGWtRUR, "fruit")
            or iZoQeOxOdO:GetAttribute("FruitType") ~= nil
            or iZoQeOxOdO:GetAttribute("fruitType") ~= nil then

            return true
        end

        return false
    end

    local function ndpVdJKNFYAj(ksXdsOKIx, timeout)
        local QHmwcvVZcPU =
            os.clock() + (FPwbuFJZR(timeout) or 2)

        while PKTqUhNlA.Alive and os.clock() < QHmwcvVZcPU do
            local gfGCiliPwd =
                OyZLrMivikrp()

            if #gfGCiliPwd == 1
                and OEuDdXtu(gfGCiliPwd[1], ksXdsOKIx, true) then

                return gfGCiliPwd[1]
            end

            task.wait(0.03)
        end

        return nil
    end

    local function uafXIOxOu(ksXdsOKIx)
        if not ksXdsOKIx then
            return nil, "fruit info missing"
        end

        local jIsUVHAQEx =
            jdMXqPJlODtA()

        if OEuDdXtu(jIsUVHAQEx, ksXdsOKIx, false) then
            return jIsUVHAQEx
        end

        nyVtovxYkT()

        if ksXdsOKIx.Tool and ksXdsOKIx.Tool.Parent then
            local iaojDScxh = QRxoupMChfPU()

            if iaojDScxh then
                BwoodiEAFu(function()
                    iaojDScxh:EquipTool(ksXdsOKIx.Tool)
                end)

                local wBmRAlRrmt =
                    ndpVdJKNFYAj(ksXdsOKIx, 1)

                if wBmRAlRrmt then
                    return wBmRAlRrmt
                end
            end
        end

        if not ksXdsOKIx.Location then
            return nil, "inventory location missing"
        end

        local uPirkaZfGG, ujxUlzok =
            BwoodiEAFu(function()
                HDDdNMSaA:FireServer(
                    ksXdsOKIx.Location.IsHotbar,
                    ksXdsOKIx.Location.Index
                )
            end)

        if not uPirkaZfGG then
            return nil, "Equip failed: " .. DfrqgXXsrB(ujxUlzok)
        end

        local wBmRAlRrmt =
            ndpVdJKNFYAj(ksXdsOKIx, 2)

        if not wBmRAlRrmt then
            return nil,
                "Could not equip " .. UlWCzTFgJsk(ksXdsOKIx)
        end

        return wBmRAlRrmt
    end

    local function ZaLSvEGNgb(ksXdsOKIx)
        if ksXdsOKIx and ksXdsOKIx.ItemId ~= nil then
            return "id:" .. DfrqgXXsrB(ksXdsOKIx.ItemId)
        end

        return "path:" .. DfrqgXXsrB(ksXdsOKIx and ksXdsOKIx.Path or "")
    end

    local function yPIunlDL(ksXdsOKIx)
        PKTqUhNlA.ClearInventoryLocation(
            ksXdsOKIx and ksXdsOKIx.Location,
            ksXdsOKIx and ksXdsOKIx.ItemId
        )
    end

    local function KfPvKIFJOy(ksXdsOKIx, lSSAtRsxOpy)
        if not egNXrkSOdCn then
            return false, "Sell service was not found"
        end

        if not wpFutleQBCyz:AcquireBackgroundEquipment(
            "AutoSellFruit",
            lSSAtRsxOpy
        ) then
            return false, "cancelled"
        end

        local uPirkaZfGG, WfmhLERIYGg =
            bltBKQceuE(function()
                local iZoQeOxOdO, OJzlPmkLd =
                    uafXIOxOu(ksXdsOKIx)

                if not iZoQeOxOdO then
                    ltAcELvGzk(OJzlPmkLd or "Could not equip fruit")
                end

                if ksXdsOKIx.ItemId ~= nil then
                    local iwPALJXk =
                        UhasFEscpy(iZoQeOxOdO)

                    if iwPALJXk ~= nil
                        and DfrqgXXsrB(iwPALJXk) ~= DfrqgXXsrB(ksXdsOKIx.ItemId) then

                        ltAcELvGzk("Equipped item changed before selling")
                    end
                end

                HXuhwCIQZAB("SELLING", "warning")
                foUSPDNDz(
                    "Selling "
                        .. UlWCzTFgJsk(ksXdsOKIx)
                        .. "...",
                    "warning"
                )

                local dQSktSlt =
                    egNXrkSOdCn:InvokeServer()

                euyMjRhaK.SellFruitCount += 1
                euyMjRhaK.LastSoldFruit = {Name= UlWCzTFgJsk(ksXdsOKIx),
                    Path = ksXdsOKIx.Path,
                    Result = dQSktSlt,
                }

                yPIunlDL(ksXdsOKIx)

                return dQSktSlt
            end, debug.traceback)

        wpFutleQBCyz:ReleaseBackgroundEquipment("AutoSellFruit")

        if not wpFutleQBCyz:IsPlantBusy() then
            HXuhwCIQZAB("IDLE")
        end

        if not uPirkaZfGG then
            local uRQanNSTiFqN =
                DfrqgXXsrB(WfmhLERIYGg):match("^[^\n]+")
                or DfrqgXXsrB(WfmhLERIYGg)

            foUSPDNDz(
                "Sell fruit failed: " .. uRQanNSTiFqN,
                "danger"
            )

            return false, uRQanNSTiFqN
        end

        return true, WfmhLERIYGg
    end

    local function xIPKitYl(lSSAtRsxOpy)
        local yLbjhpVKOB = {}

        while PKTqUhNlA.Alive
            and ibVEMhwTQRuM.AutoSellFruit
            and not lSSAtRsxOpy() do

            if not ZMZXtZNTlb:IsReady() then
                hfBLUgtjD()
                foUSPDNDz(
                    "Waiting for bag data before selling fruit...",
                    "warning"
                )

                if not pQFNwZAvvQA(0.5, lSSAtRsxOpy) then
                    break
                end
            else
                local SOmfoAbH = os.clock()
                local YbeigJdp = IePsMfSJ()
                local otMRsdmAPve = nil

                for _, bTjKsleJ in ZVOoBlCEzTM(YbeigJdp) do
                    local OVYmLrNOMZpK =
                        yLbjhpVKOB[ZaLSvEGNgb(bTjKsleJ)]

                    if not OVYmLrNOMZpK
                        or OVYmLrNOMZpK <= SOmfoAbH then
                        otMRsdmAPve = bTjKsleJ
                        break
                    end
                end

                if otMRsdmAPve then
                    local XgKJlGmpyrd =
                        PKTqUhNlA.GetInventoryVersion()
                    local yFYedyPjpUi =
                        KfPvKIFJOy(otMRsdmAPve, lSSAtRsxOpy)

                    if yFYedyPjpUi then
                        foUSPDNDz(
                            "Sold "
                                .. UlWCzTFgJsk(otMRsdmAPve)
                                .. " | total "
                                .. DfrqgXXsrB(euyMjRhaK.SellFruitCount),
                            "success"
                        )

                        if not PKTqUhNlA.WaitForInventoryRefresh(
                            XgKJlGmpyrd,
                            lSSAtRsxOpy,
                            2
                        ) then
                            yLbjhpVKOB[ZaLSvEGNgb(otMRsdmAPve)] =
                                os.clock() + 1.5
                        end

                        if not pQFNwZAvvQA(
                            ibVEMhwTQRuM.SellDelay,
                            lSSAtRsxOpy
                        ) then
                            break
                        end
                    else
                        yLbjhpVKOB[ZaLSvEGNgb(otMRsdmAPve)] =
                            os.clock() + 5

                        if not pQFNwZAvvQA(0.35, lSSAtRsxOpy) then
                            break
                        end
                    end
                else
                    if #YbeigJdp == 0 then
                        foUSPDNDz("No fruit in your bag")
                    else
                        foUSPDNDz(
                            "Waiting before retrying fruit sales",
                            "warning"
                        )
                    end

                    if not pQFNwZAvvQA(1, lSSAtRsxOpy) then
                        break
                    end
                end
            end
        end

        wpFutleQBCyz:ReleaseBackgroundEquipment("AutoSellFruit")

        if not wpFutleQBCyz:IsPlantBusy() then
            HXuhwCIQZAB("IDLE")
        end
    end

    PKTqUhNlA.GetFruits = IePsMfSJ

    PKTqUhNlA.PrintFruits = function()
        local YbeigJdp =
            IePsMfSJ()

        EaksGWapyD("")
        EaksGWapyD("===== KIRA FRUITS =====")

        for LvOjTWuqYW, ksXdsOKIx in ZVOoBlCEzTM(YbeigJdp) do
            EaksGWapyD(
                LvOjTWuqYW,
                ksXdsOKIx.Path,
                "|",
                UlWCzTFgJsk(ksXdsOKIx),
                "| ID:",
                DfrqgXXsrB(ksXdsOKIx.ItemId)
            )
        end

        EaksGWapyD("Total:", #YbeigJdp)
        EaksGWapyD("=======================")
    end

    return xIPKitYl
end

local yNkNYPlA =
    UuxadzuPhcII()

--============================================================
-- AUTO BUY QUEUE
--============================================================

--============================================================
-- AUTO BUY - PROXIMITY PROMPT + MONEY SAFETY
--============================================================

local rkvmSXwQtNqI =
    setmetatable({}, {__mode= "k",
    })

local PBVhQLUjGPc = {}
local XgoxmCVrJL = {}

local YCXNjPztYiv = {
    [""] = 1,

    k = 1e3,
    m = 1e6,
    b = 1e9,
    t = 1e12,

    q = 1e15,
    qa = 1e15,
    qi = 1e18,
    sx = 1e21,
    sp = 1e24,
    oc = 1e27,
    no = 1e30,
    dc = 1e33,
    de = 1e33,

    ud = 1e36,
    dd = 1e39,
    td = 1e42,
    qad = 1e45,
    qid = 1e48,
    sxd = 1e51,
    spd = 1e54,
    ocd = 1e57,
    nod = 1e60,
    vg = 1e63,
}

local function LUSjWilitB(QtoBGFWIF)
    QtoBGFWIF = DfrqgXXsrB(QtoBGFWIF or "")
    QtoBGFWIF = QtoBGFWIF:gsub("<.->", "")
    QtoBGFWIF = QtoBGFWIF:gsub(",", "")
    QtoBGFWIF = QtoBGFWIF:gsub("%s+", "")

    if QtoBGFWIF == "" then
        return nil
    end

    if jvVkYVzFo(QtoBGFWIF) == "free"
        or string.find(jvVkYVzFo(QtoBGFWIF), "free", 1, true) then
        return 0
    end

    -- Keep digits, decimal point, minus sign and alphabetic suffix.
    QtoBGFWIF = QtoBGFWIF:gsub("[%$€£¥]", "")

    local mJpacLslinIi =
        FPwbuFJZR(QtoBGFWIF)

    if mJpacLslinIi ~= nil then
        return mJpacLslinIi
    end

    local pQvnqyZnr, jfWmUADzLmk =
        QtoBGFWIF:match("([%+%-]?[%d%.]+)([%a]*)")

    local ERQNGrtnl = FPwbuFJZR(pQvnqyZnr)

    if not ERQNGrtnl then
        return nil
    end

    jfWmUADzLmk = jvVkYVzFo(jfWmUADzLmk)

    local MxRPMdGNQWn =
        YCXNjPztYiv[jfWmUADzLmk]

    if MxRPMdGNQWn == nil then
        return nil
    end

    return ERQNGrtnl * MxRPMdGNQWn
end

local function xuILeEJFvfld()
    local HpFVOrUUhoMi =
        dxLeYzjrD:FindFirstChild("leaderstats")

    if not HpFVOrUUhoMi then
        return nil, "leaderstats not found"
    end

    local function XNMWfkUDyi(stat)
        if not stat then
            return nil
        end

        local uPirkaZfGG, rKvIshOMn =
            BwoodiEAFu(function()
                return stat.Value
            end)

        if not uPirkaZfGG or rKvIshOMn == nil then
            return nil
        end

        if typeof(rKvIshOMn) == "number" then
            return rKvIshOMn,
                DfrqgXXsrB(stat.Name) .. ": " .. DfrqgXXsrB(rKvIshOMn)
        end

        local rxyOhZAzx =
            LUSjWilitB(rKvIshOMn)

        if rxyOhZAzx ~= nil then
            return rxyOhZAzx,
                DfrqgXXsrB(stat.Name) .. ": " .. DfrqgXXsrB(rKvIshOMn)
        end

        return nil
    end

    local gxgxwYsxMTli = {
        "Cash",
        "Money",
        "Coins",
        "Coin",
        "Wallet",
        "Gold",
        "$",
    }

    for _, NrtELUjWkSE in ZVOoBlCEzTM(gxgxwYsxMTli) do
        local rFCibROv, GLUFZLLAdGTy =
            XNMWfkUDyi(
                HpFVOrUUhoMi:FindFirstChild(NrtELUjWkSE)
            )

        if rFCibROv ~= nil then
            return rFCibROv, GLUFZLLAdGTy
        end
    end

    for _, stat in ZVOoBlCEzTM(HpFVOrUUhoMi:GetChildren()) do
        local NrtELUjWkSE =
            jvVkYVzFo(stat.Name)

        if string.find(NrtELUjWkSE, "cash", 1, true)
            or string.find(NrtELUjWkSE, "money", 1, true)
            or string.find(NrtELUjWkSE, "coin", 1, true)
            or string.find(NrtELUjWkSE, "wallet", 1, true)
            or string.find(NrtELUjWkSE, "gold", 1, true)
            or string.find(NrtELUjWkSE, "$", 1, true) then

            local rFCibROv, GLUFZLLAdGTy =
                XNMWfkUDyi(stat)

            if rFCibROv ~= nil then
                return rFCibROv, GLUFZLLAdGTy
            end
        end
    end

    return nil, "money leaderstat not found"
end

local function TsFvnjHxAxe()
    local NPUdyLjr =
        vhsjTXIP:FindFirstChild("HUD")

    local ylMHxxRSQ =
        NPUdyLjr and NPUdyLjr:FindFirstChild("BottomLeft")

    local TpFFslNP =
        ylMHxxRSQ and ylMHxxRSQ:FindFirstChild("CoinsWallet")

    local ROxVchvm =
        TpFFslNP and TpFFslNP:FindFirstChild("TextLabel")

    if ROxVchvm and (
        ROxVchvm:IsA("TextLabel")
        or ROxVchvm:IsA("TextButton")
        or ROxVchvm:IsA("TextBox")
    ) then
        return ROxVchvm
    end

    return nil
end

local function AcshXZuiGq()
    local QNzDYCbfs, glWSLyQzCjhv =
        xuILeEJFvfld()

    if QNzDYCbfs ~= nil then
        return QNzDYCbfs, glWSLyQzCjhv
    end

    local ROxVchvm = TsFvnjHxAxe()

    if not ROxVchvm then
        return nil,
            DfrqgXXsrB(glWSLyQzCjhv or "wallet label not found")
    end

    local XUWueugAwuSw =
        LUSjWilitB(ROxVchvm.Text)

    if XUWueugAwuSw == nil then
        return nil,
            "could not parse wallet: "
                .. DfrqgXXsrB(ROxVchvm.Text)
    end

    return XUWueugAwuSw, ROxVchvm.Text
end

local function tWMOxzAahiG(holder)
    if not holder then
        return nil
    end

    local EQkOFXGQS =
        holder:GetAttribute("SeedType")
        or holder:GetAttribute("Seed")
        or holder:GetAttribute("SeedName")

    local KJQdzwwjQOsx =
        holder:GetAttribute("Rarity")
        or "UNKNOWN"

    local QNrflgyBEk =
        holder:GetAttribute("SpawnId")

    local dzGwxesc =
        holder:FindFirstChild("BillboardGui")

    local urBeLPAnpTv =
        dzGwxesc and dzGwxesc:FindFirstChild("Frame")

    local qvXpGfeYxWHS =
        urBeLPAnpTv and urBeLPAnpTv:FindFirstChild("Cost")

    if not qvXpGfeYxWHS then
        qvXpGfeYxWHS =
            holder:FindFirstChild("Cost", true)
    end

    local uBCyouiP = nil

    if qvXpGfeYxWHS and (
        qvXpGfeYxWHS:IsA("TextLabel")
        or qvXpGfeYxWHS:IsA("TextButton")
        or qvXpGfeYxWHS:IsA("TextBox")
    ) then
        uBCyouiP = qvXpGfeYxWHS.Text
    end

    -- Billboard cost is the source of truth; catalog price is only a
    -- fallback if the UI object has not replicated yet.
    if not uBCyouiP or uBCyouiP == "" then
        uBCyouiP =
            ITzawOckSLt[
                DfrqgXXsrB(EQkOFXGQS or "")
            ]
    end

    local yQJrjaPZKi =
        holder:FindFirstChild("ProximityPrompt")
        or holder:FindFirstChildWhichIsA(
            "ProximityPrompt",
            true
        )

    return {Holder= holder,
        SeedType = DfrqgXXsrB(EQkOFXGQS or "Unknown Seed"),
        Rarity = DfrqgXXsrB(KJQdzwwjQOsx),
        SpawnId = QNrflgyBEk,
        CostObject = qvXpGfeYxWHS,
        CostText = uBCyouiP,
        Cost = LUSjWilitB(uBCyouiP),
        Prompt = yQJrjaPZKi,
    }
end

PKTqUhNlA.GetSeedHolderInfo = tWMOxzAahiG
PKTqUhNlA.ParseGameNumber = LUSjWilitB
PKTqUhNlA.GetCoins = AcshXZuiGq

local function lyfSfMMiH(holderInfo)
    local otMRsdmAPve = caURwNsUKyWo()

    if #otMRsdmAPve == #fzMNsCGQ then
        return true
    end

    local VuDvjaRnSLZL = jvVkYVzFo(holderInfo.Rarity)

    for _, KJQdzwwjQOsx in ZVOoBlCEzTM(otMRsdmAPve) do
        if jvVkYVzFo(KJQdzwwjQOsx) == VuDvjaRnSLZL then
            return true
        end
    end

    return false
end

local function JYfSlbWdE(holderInfo)
    local otMRsdmAPve = BKheSqKQSiI()

    if #otMRsdmAPve == #MKjocGYu then
        return true
    end

    local VuDvjaRnSLZL = jvVkYVzFo(holderInfo.SeedType)

    for _, DhaBjHwh in ZVOoBlCEzTM(otMRsdmAPve) do
        if jvVkYVzFo(DhaBjHwh) == VuDvjaRnSLZL then
            return true
        end
    end

    return false
end

local function ZOErpbzRT(holderInfo)
    if holderInfo.SpawnId ~= nil then
        return DfrqgXXsrB(holderInfo.SpawnId)
            .. ":"
            .. jvVkYVzFo(holderInfo.SeedType)
    end

    return DfrqgXXsrB(holderInfo.Holder)
        .. ":"
        .. jvVkYVzFo(holderInfo.SeedType)
end

local function WYIEBUUAT()
    -- Kept as a compatibility API for the existing System button.
    PBVhQLUjGPc = {}
end

local function XarpitBPFIg()
    -- AutoBuy is intentionally polling GetChildren now; no queue/event needed.
    local uyNUuLrLQw = 0

    for _, holder in ZVOoBlCEzTM(xgfYDVTAxpy:GetChildren()) do
        if holder.Name == "SeedHolder" then
            uyNUuLrLQw += 1
        end
    end

    return uyNUuLrLQw
end

local function yLKgAPTB(holder, lSSAtRsxOpy)
    if not holder
        or not holder.Parent
        or holder.Name ~= "SeedHolder" then
        return false, "invalid-holder"
    end

    local ksXdsOKIx =
        tWMOxzAahiG(holder)

    if not ksXdsOKIx then
        return false, "no-info"
    end

    if not lyfSfMMiH(ksXdsOKIx)
        or not JYfSlbWdE(ksXdsOKIx) then
        return false, "filtered"
    end

    if not ksXdsOKIx.Prompt then
        return false, "prompt-missing"
    end

    if ksXdsOKIx.Cost == nil then
        foUSPDNDz(
            "Skipped "
                .. ksXdsOKIx.SeedType
                .. ": unknown cost "
                .. DfrqgXXsrB(ksXdsOKIx.CostText),
            "warning"
        )

        return false, "cost-unreadable"
    end

    local rFCibROv, WVWFXsiIeOm =
        AcshXZuiGq()

    if rFCibROv == nil then
        foUSPDNDz(
            "AutoBuy paused: "
                .. DfrqgXXsrB(WVWFXsiIeOm),
            "danger"
        )

        return false, "wallet-unreadable"
    end

    if rFCibROv < ksXdsOKIx.Cost then
        local eRdipkcQbcnW =
            ZOErpbzRT(ksXdsOKIx)

        local SOmfoAbH = os.clock()

        if SOmfoAbH
            - (XgoxmCVrJL[eRdipkcQbcnW] or 0)
            >= 3 then

            XgoxmCVrJL[eRdipkcQbcnW] = SOmfoAbH

            foUSPDNDz(
                "Not enough money for "
                    .. ksXdsOKIx.SeedType
                    .. " ("
                    .. DfrqgXXsrB(ksXdsOKIx.CostText)
                    .. ")",
                "warning"
            )
        end

        return false, "insufficient"
    end

    local eRdipkcQbcnW =
        ZOErpbzRT(ksXdsOKIx)

    if rkvmSXwQtNqI[holder] == eRdipkcQbcnW then
        return true, "already-purchased"
    end

    if (PBVhQLUjGPc[eRdipkcQbcnW] or 0)
        > os.clock() then
        return false, "cooldown"
    end

    -- Plant intent blocks new purchases from touching equipment.
    if not wpFutleQBCyz:AcquireBackgroundEquipment(
        "AutoBuy",
        lSSAtRsxOpy
    ) then
        return false, "cancelled"
    end

    -- Re-read immediately after waiting for the lock.
    if not holder.Parent or not ibVEMhwTQRuM.AutoBuy then
        wpFutleQBCyz:ReleaseBackgroundEquipment("AutoBuy")
        return false, "cancelled"
    end

    ksXdsOKIx = tWMOxzAahiG(holder)

    if not ksXdsOKIx
        or not lyfSfMMiH(ksXdsOKIx)
        or not JYfSlbWdE(ksXdsOKIx) then

        wpFutleQBCyz:ReleaseBackgroundEquipment("AutoBuy")
        return false, "changed"
    end

    local rMjOglHbK = AcshXZuiGq()

    if rMjOglHbK == nil
        or ksXdsOKIx.Cost == nil
        or rMjOglHbK < ksXdsOKIx.Cost then

        wpFutleQBCyz:ReleaseBackgroundEquipment("AutoBuy")
        return false, "insufficient"
    end

    local LtolXkUgwI =
        ZMZXtZNTlb:GetSeedCount(
            ksXdsOKIx.SeedType
        )
    local RnCJjUHos =
        PKTqUhNlA.GetInventoryVersion()

    HXuhwCIQZAB("BUYING")

    foUSPDNDz(
        "Buying "
            .. ksXdsOKIx.SeedType
            .. " ["
            .. ksXdsOKIx.Rarity
            .. "] "
            .. DfrqgXXsrB(ksXdsOKIx.CostText)
    )

    if type(fireproximityprompt) ~= "function" then
        wpFutleQBCyz:ReleaseBackgroundEquipment("AutoBuy")

        foUSPDNDz(
            "fireproximityprompt is unavailable",
            "danger"
        )

        return false, "fireproximityprompt-unavailable"
    end

    PBVhQLUjGPc[eRdipkcQbcnW] =
        os.clock() + 1.25

    local XbUDFIepRJM, aAIBWyUMkPz =
        BwoodiEAFu(function()
            fireproximityprompt(
                ksXdsOKIx.Prompt
            )
        end)

    if not XbUDFIepRJM then
        wpFutleQBCyz:ReleaseBackgroundEquipment("AutoBuy")

        foUSPDNDz(
            "Prompt failed: "
                .. DfrqgXXsrB(aAIBWyUMkPz),
            "danger"
        )

        return false, "prompt-error"
    end

    -- Wait for one of three purchase proofs:
    -- inventory increased, wallet decreased, or this holder disappeared.
    local RcEgnLXWKPPQ = false
    local QHmwcvVZcPU =
        os.clock()
        + math.max(
            1.25,
            ibVEMhwTQRuM.BuyDelay + 1.0
        )

    while PKTqUhNlA.Alive
        and os.clock() < QHmwcvVZcPU do

        if not holder.Parent then
            RcEgnLXWKPPQ = true
            break
        end

        local pFVaxqaMiOae =
            ZMZXtZNTlb:GetSeedCount(
                ksXdsOKIx.SeedType
            )

        if pFVaxqaMiOae > LtolXkUgwI then
            RcEgnLXWKPPQ = true
            break
        end

        local ZifQgOjeaRO =
            AcshXZuiGq()

        if ksXdsOKIx.Cost > 0
            and ZifQgOjeaRO ~= nil
            and ZifQgOjeaRO < rMjOglHbK then

            RcEgnLXWKPPQ = true
            break
        end

        task.wait(0.04)
    end

    -- Buying may auto-equip the purchased seed. That is fine.
    -- AutoPlant only equips its selected seed inside plantTransaction.

    wpFutleQBCyz:ReleaseBackgroundEquipment("AutoBuy")

    if not wpFutleQBCyz:IsPlantBusy() then
        HXuhwCIQZAB("IDLE")
    end

    if not RcEgnLXWKPPQ then
        foUSPDNDz(
            "Purchase unverified: "
                .. ksXdsOKIx.SeedType,
            "warning"
        )

        return false, "unverified"
    end

    PKTqUhNlA.WaitForInventoryRefresh(
        RnCJjUHos,
        lSSAtRsxOpy,
        1.5
    )

    rkvmSXwQtNqI[holder] = eRdipkcQbcnW
    euyMjRhaK.PurchaseCount += 1

    euyMjRhaK.LastPurchase = {SeedType= ksXdsOKIx.SeedType,
        Rarity = ksXdsOKIx.Rarity,
        SpawnId = ksXdsOKIx.SpawnId,
        Cost = ksXdsOKIx.Cost,
        CostText = ksXdsOKIx.CostText,
        PurchasedAt = os.clock(),
    }

    foUSPDNDz(
        "Bought "
            .. ksXdsOKIx.SeedType
            .. " for "
            .. DfrqgXXsrB(ksXdsOKIx.CostText)
    )

    return true, "purchased"
end

local function tgBBKFdcBcp(lSSAtRsxOpy)
    while PKTqUhNlA.Alive
        and ibVEMhwTQRuM.AutoBuy
        and not lSSAtRsxOpy() do

        local RnhjkjusFM =
            xgfYDVTAxpy:GetChildren()

        for _, holder in ZVOoBlCEzTM(RnhjkjusFM) do
            if lSSAtRsxOpy()
                or not ibVEMhwTQRuM.AutoBuy then
                break
            end

            if holder.Name == "SeedHolder" then
                yLKgAPTB(
                    holder,
                    lSSAtRsxOpy
                )

                -- Tiny yield keeps UI/game responsive while many seeds are present.
                task.wait(0.025)
            end
        end

        -- The conveyor is small; polling avoids stale DescendantAdded/attribute races.
        task.wait(0.12)
    end

    wpFutleQBCyz:ReleaseBackgroundEquipment("AutoBuy")
end

--============================================================
-- PLANT TRANSACTION
--============================================================

local function HUjHZUVvW(XUWueugAwuSw)
    for _, mmeTHSsPZRY in ZVOoBlCEzTM(RLYSHrriuiBl) do
        if mmeTHSsPZRY == XUWueugAwuSw then
            return true
        end
    end
    return false
end

local function nYFNFuIM()
    local mbPXivzXVClC, CSJzVWFOz = ZtkuZoIr()

    if not mbPXivzXVClC then
        return nil,
            "Waiting for weather before planting (current: "
                .. DfrqgXXsrB(CSJzVWFOz)
                .. ")"
    end

    local DhaBjHwh, MHYAAEXgCdz = XiRANzkuIiam()

    if not DhaBjHwh then
        return nil, MHYAAEXgCdz or "No plant seed selected"
    end

    local mmeTHSsPZRY = ibVEMhwTQRuM.Fertilizer

    if not HUjHZUVvW(mmeTHSsPZRY) then
        return nil, "Invalid fertilizer: " .. DfrqgXXsrB(mmeTHSsPZRY)
    end

    local ZZEpQIODx =
        ZMZXtZNTlb:GetSeedCount(
            DhaBjHwh
        )

    if ZZEpQIODx <= 0 then
        return nil,
            "No "
                .. DfrqgXXsrB(DhaBjHwh)
                .. " seed in Inventory"
    end

    return {SeedName= DhaBjHwh,
        Fertilizer = mmeTHSsPZRY,
        OwnedCount = ZZEpQIODx,
        Weather = CSJzVWFOz,
    }
end

local function gSrVNXcYPyKa(owner, lSSAtRsxOpy)
    owner = owner or "AutoPlant"

    local zcivxxfdJ, NqFalTNWDKg = nYFNFuIM()

    if not zcivxxfdJ then
        foUSPDNDz(
            "Auto Plant waiting: " .. DfrqgXXsrB(NqFalTNWDKg),
            "warning"
        )
        return false, NqFalTNWDKg
    end

    if not wpFutleQBCyz:BeginPlant(owner, lSSAtRsxOpy) then
        return false, "cancelled"
    end

    local DhaBjHwh = zcivxxfdJ.SeedName
    local mmeTHSsPZRY = zcivxxfdJ.Fertilizer
    local uZCJXEOYcHhL = nil
    local WwZAUNwWsX = false
    local RnCJjUHos = nil

    local uPirkaZfGG, HqvmSTue = bltBKQceuE(function()
        local vCwajuOLYX,
            freshError =
                nYFNFuIM()

        if not vCwajuOLYX then
            ltAcELvGzk(freshError)
        end

        DhaBjHwh = vCwajuOLYX.SeedName
        mmeTHSsPZRY = vCwajuOLYX.Fertilizer

        local XDnMSwceHFM =
            type(PKTqUhNlA.GetWormSettingsForSeed) == "function"
            and PKTqUhNlA.GetWormSettingsForSeed(DhaBjHwh)
            or nil

        local ZZEpQIODx =
            vCwajuOLYX.OwnedCount

        foUSPDNDz(
            "Equipping "
                .. DfrqgXXsrB(DhaBjHwh)
                .. " (owned x"
                .. DfrqgXXsrB(ZZEpQIODx)
                .. ")..."
        )

        local wBmRAlRrmt,
            loPlXfSGwyxw,
            OJzlPmkLd =
                RKToqRBd(DhaBjHwh)

        if not wBmRAlRrmt or not loPlXfSGwyxw then
            ltAcELvGzk(
                OJzlPmkLd
                or (
                    "Seed tool not found/equipped: "
                    .. DfrqgXXsrB(DhaBjHwh)
                )
            )
        end

        -- Triple stability verification checks SeedType AND exact ItemId.
        local RcEgnLXWKPPQ, fZOfTTWSLl =
            rRUUBuGfgaxk(
                DhaBjHwh,
                loPlXfSGwyxw.Id
            )

        if not RcEgnLXWKPPQ then
            ltAcELvGzk(fZOfTTWSLl)
        end

        -- Final immediate exact check before the remote call.
        local UQMPeCrGpeMo =
            OyZLrMivikrp()

        local wyWAjqLPEb =
            UQMPeCrGpeMo[1]

        if #UQMPeCrGpeMo ~= 1
            or not wyWAjqLPEb
            or not MLuVxMKxGY(
                wyWAjqLPEb,
                DhaBjHwh,
                loPlXfSGwyxw.Id
            ) then

            ltAcELvGzk(
                "Equipped seed changed/ambiguous immediately before StartRound"
            )
        end

        local qWfYuUYtlujd,
            beforeMaxSerial =
                eymQWPKD()

        local TqnUoHdHB = nil
        local KOAQgbtKrF = mmeTHSsPZRY

        if XDnMSwceHFM
            and XDnMSwceHFM.Use
            and PKTqUhNlA.WormBridge then

            TqnUoHdHB =
                PKTqUhNlA.WormBridge:Resolve(
                    XDnMSwceHFM
                )

            if TqnUoHdHB
                and PKTqUhNlA.WormBridge:Reserve(
                    TqnUoHdHB,
                    owner
                ) then

                uZCJXEOYcHhL = TqnUoHdHB.Id
                KOAQgbtKrF = "None"
            else
                TqnUoHdHB = nil
            end
        end

        foUSPDNDz(
            "Planting "
                .. DhaBjHwh
                .. " + "
                .. (
                    TqnUoHdHB
                    and (PKTqUhNlA.FormatWorm and PKTqUhNlA.FormatWorm(TqnUoHdHB) or "Worm")
                    or mmeTHSsPZRY
                )
                .. (
                    XDnMSwceHFM
                    and XDnMSwceHFM.Use
                    and not TqnUoHdHB
                    and " (no matching Worm)"
                    or ""
                )
                .. "..."
        )

        local xOZqsPjGFS = os.clock()
        local zxiTFWnr
        RnCJjUHos =
            PKTqUhNlA.GetInventoryVersion()

        if TqnUoHdHB then
            WwZAUNwWsX = true
            zxiTFWnr =
                KplnAOsvyjN:InvokeServer(
                    DhaBjHwh,
                    "None",
                    TqnUoHdHB.Id
                )
        else
            zxiTFWnr =
                KplnAOsvyjN:InvokeServer(
                    DhaBjHwh,
                    mmeTHSsPZRY
                )
        end


        if zxiTFWnr == false then
            ltAcELvGzk("StartRound returned false")
        end

        local WbivZzCrXard =
            UFtCUOsISQtE(
                qWfYuUYtlujd,
                beforeMaxSerial,
                3
            )

        if not WbivZzCrXard then
            ltAcELvGzk(
                "StartRound returned but no new owned PlantRound appeared"
            )
        end

        if TqnUoHdHB and uZCJXEOYcHhL then
            PKTqUhNlA.WormBridge:Mark(
                uZCJXEOYcHhL,
                "CONSUMED"
            )
        end

        local LNufBNUJAR = {Seed= DhaBjHwh,
            SeedItemId = loPlXfSGwyxw.Id,
            SeedInventoryPath = loPlXfSGwyxw.Path,
            SeedMutation = loPlXfSGwyxw.Mutation,
            SeedCountBeforePlant = ZZEpQIODx,
            Fertilizer = KOAQgbtKrF,
            RequestedFertilizer = mmeTHSsPZRY,
            UsedWorm = TqnUoHdHB ~= nil,
            WormId = TqnUoHdHB and TqnUoHdHB.Id or nil,
            WormType = TqnUoHdHB and TqnUoHdHB.RawType or nil,
            WormDisplayType = TqnUoHdHB and TqnUoHdHB.DisplayType or nil,
            WormMutation = TqnUoHdHB and TqnUoHdHB.Mutation or nil,
            WormMult = TqnUoHdHB and TqnUoHdHB.Mult or nil,
            WormSettings = XDnMSwceHFM and JsWrmjlSRyvZ(XDnMSwceHFM) or nil,
            HarvestTarget = DGUSmiSQl(DhaBjHwh),
            StartResponse = zxiTFWnr,
            StartedAt = xOZqsPjGFS,
            InventoryVersionBefore = RnCJjUHos,
            Plot = kUPNnQqxT(),

            BeforeRoundSerial = beforeMaxSerial,
            PlantRound = WbivZzCrXard,
            PlantRoundSerial = RfAxgCjnjg(WbivZzCrXard),
        }

        if type(LLTinptsjcFz.VerifyPlant) == "function" then
            local LaJJbgnJbW, HUIbpYBpNWYP = BwoodiEAFu(LLTinptsjcFz.VerifyPlant, LNufBNUJAR)
            if not LaJJbgnJbW then
                ltAcELvGzk("VerifyPlant adapter error: " .. DfrqgXXsrB(HUIbpYBpNWYP))
            end
            if HUIbpYBpNWYP == false then
                ltAcELvGzk("VerifyPlant adapter rejected the plant")
            end
        end

        vrGYPXgh(WbivZzCrXard, DhaBjHwh)

        euyMjRhaK.LastPlantContext = LNufBNUJAR
        euyMjRhaK.CurrentPlantRound = WbivZzCrXard
        euyMjRhaK.CurrentMultiplier = 0
        euyMjRhaK.CurrentSeed = DhaBjHwh
        euyMjRhaK.CurrentHarvestTarget = LNufBNUJAR.HarvestTarget
        euyMjRhaK.LastUsedWorm = TqnUoHdHB and {Id= TqnUoHdHB.Id,
            Type = TqnUoHdHB.RawType,
            DisplayType = TqnUoHdHB.DisplayType,
            Mutation = TqnUoHdHB.Mutation,
            Mult = TqnUoHdHB.Mult,
        } or nil
        euyMjRhaK.PlantCount = euyMjRhaK.PlantCount + 1
        return LNufBNUJAR
    end, debug.traceback)

    wpFutleQBCyz:EndPlant(owner)

    if not uPirkaZfGG then
        if uZCJXEOYcHhL and PKTqUhNlA.WormBridge then
            if WwZAUNwWsX then
                PKTqUhNlA.WormBridge:Mark(
                    uZCJXEOYcHhL,
                    "UNCERTAIN"
                )
            else
                PKTqUhNlA.WormBridge:Release(
                    uZCJXEOYcHhL
                )
            end
        end

        local uRQanNSTiFqN = DfrqgXXsrB(HqvmSTue):match("^[^\n]+") or DfrqgXXsrB(HqvmSTue)
        foUSPDNDz("Plant failed: " .. uRQanNSTiFqN, "danger")
        return false, uRQanNSTiFqN
    end

    if RnCJjUHos ~= nil then
        PKTqUhNlA.WaitForInventoryRefresh(
            RnCJjUHos,
            lSSAtRsxOpy,
            2
        )
    end

    foUSPDNDz("Plant verified: " .. DfrqgXXsrB(DhaBjHwh))
    return true, HqvmSTue
end

PKTqUhNlA.PlantOnce = function()
    return gSrVNXcYPyKa("ExternalPlant", function()
        return not PKTqUhNlA.Alive
    end)
end

--============================================================
-- LIVE PLANT ROUND MONITOR / HARVEST
--============================================================

local wCAQCoWrgLd = {}

local function cqPcOyLkvPtH(kHtWakxlAm, timeout)
    local QHmwcvVZcPU =
        os.clock() + (FPwbuFJZR(timeout) or 1.5)

    while os.clock() < QHmwcvVZcPU do
        if not kHtWakxlAm or not kHtWakxlAm.Parent then
            return true
        end

        task.wait(0.04)
    end

    return not kHtWakxlAm or not kHtWakxlAm.Parent
end

local function TtzKyEKPf(yQJrjaPZKi)
    if not yQJrjaPZKi then
        return false, "ProximityPrompt missing"
    end

    if type(fireproximityprompt) ~= "function" then
        return false, "fireproximityprompt unavailable"
    end

    local uPirkaZfGG, ujxUlzok = BwoodiEAFu(function()
        fireproximityprompt(yQJrjaPZKi)
    end)

    if not uPirkaZfGG then
        return false, DfrqgXXsrB(ujxUlzok)
    end

    return true
end

local function txPqbIUDrkAR(kHtWakxlAm, ggLmjaobdy, lSSAtRsxOpy)
    if not kHtWakxlAm
        or not kHtWakxlAm.Parent
        or not VXbzSdNydTv(kHtWakxlAm) then
        return false, "round-missing"
    end

    local OVYmLrNOMZpK = wCAQCoWrgLd[kHtWakxlAm] or 0

    if OVYmLrNOMZpK > os.clock() then
        return false, "cooldown"
    end

    -- Planting has priority over every collect/harvest interaction.
    if wpFutleQBCyz:IsPlantBusy() then
        return false, "plant-busy"
    end

    if not wpFutleQBCyz:AcquireAction(
        "RoundMonitor",
        lSSAtRsxOpy,
        1
    ) then
        return false, "busy"
    end

    if not XbOuitZgCfm:Acquire(
        "RoundMonitor",
        lSSAtRsxOpy,
        1
    ) then
        wpFutleQBCyz:ReleaseAction("RoundMonitor")
        return false, "busy"
    end

    local ksXdsOKIx = ciyEOPymQW(kHtWakxlAm)

    if not ksXdsOKIx then
        XbOuitZgCfm:Release("RoundMonitor")
        wpFutleQBCyz:ReleaseAction("RoundMonitor")
        return false, "round-invalid"
    end

    if ksXdsOKIx.OwnerId ~= nil
        and ksXdsOKIx.OwnerId ~= dxLeYzjrD.UserId then
        XbOuitZgCfm:Release("RoundMonitor")
        wpFutleQBCyz:ReleaseAction("RoundMonitor")
        return false, "wrong-owner"
    end

    local YpOnPFFzN =
        ggLmjaobdy == "dead"
        and "COLLECT DEAD"
        or "HARVESTING"

    local DhaBjHwh = EgiwikUN(kHtWakxlAm)
    local mheQJrvIu = PwPdrJwbG(kHtWakxlAm)

    HXuhwCIQZAB(
        YpOnPFFzN,
        ggLmjaobdy == "dead" and "danger" or "warning"
    )

    local yzFftzeHecos = false
    local RyfILevMgb = nil
    local RnCJjUHos =
        PKTqUhNlA.GetInventoryVersion()

    if ggLmjaobdy == "dead" then
        foUSPDNDz(
            "Collecting dead tree "
                .. kHtWakxlAm.Name
                .. "...",
            "warning"
        )

        -- Exact-round prompt first.
        if ksXdsOKIx.Prompt then
            yzFftzeHecos,
                RyfILevMgb =
                    TtzKyEKPf(ksXdsOKIx.Prompt)
        end

        -- If the prompt did not remove it, use the no-arg dead-tree RF fallback.
        if not yzFftzeHecos
            or not cqPcOyLkvPtH(kHtWakxlAm, 0.45) then

            local uPirkaZfGG, dQSktSlt = BwoodiEAFu(function()
                return hxVkjLkuFG:InvokeServer()
            end)

            if uPirkaZfGG and dQSktSlt ~= false then
                yzFftzeHecos = true
            elseif not yzFftzeHecos then
                RyfILevMgb = DfrqgXXsrB(dQSktSlt)
            end
        end
    else
        foUSPDNDz(
            "Harvesting "
                .. kHtWakxlAm.Name
                .. " at "
                .. DfrqgXXsrB(ksXdsOKIx.Multiplier or "?")
                .. "x / target "
                .. DfrqgXXsrB(mheQJrvIu)
                .. "x..."
        )

        yzFftzeHecos,
            RyfILevMgb =
                TtzKyEKPf(ksXdsOKIx.Prompt)
    end

    local aDOqObTqCh = false

    if yzFftzeHecos then
        aDOqObTqCh = cqPcOyLkvPtH(kHtWakxlAm, 1.5)
    end

    XbOuitZgCfm:Release("RoundMonitor")
    wpFutleQBCyz:ReleaseAction("RoundMonitor")

    if not wpFutleQBCyz:IsPlantBusy() then
        HXuhwCIQZAB("IDLE")
    end

    if not yzFftzeHecos then
        wCAQCoWrgLd[kHtWakxlAm] = os.clock() + 0.75

        foUSPDNDz(
            YpOnPFFzN
                .. " failed: "
                .. DfrqgXXsrB(RyfILevMgb),
            "danger"
        )

        return false, RyfILevMgb
    end

    if not aDOqObTqCh then
        wCAQCoWrgLd[kHtWakxlAm] = os.clock() + 0.75

        foUSPDNDz(
            YpOnPFFzN
                .. " unverified: round still exists",
            "warning"
        )

        return false, "round-still-exists"
    end

    wCAQCoWrgLd[kHtWakxlAm] = nil

    PKTqUhNlA.WaitForInventoryRefresh(
        RnCJjUHos,
        lSSAtRsxOpy,
        1.75
    )

    euyMjRhaK.LastHarvest = {Mode= ggLmjaobdy,
        RoundName = kHtWakxlAm.Name,
        Seed = DhaBjHwh,
        Multiplier = ksXdsOKIx.Multiplier,
        Target = mheQJrvIu,
        At = os.clock(),
    }

    if ggLmjaobdy == "dead" then
        euyMjRhaK.DeadCollectCount += 1
        foUSPDNDz("Dead tree collected")
    else
        euyMjRhaK.HarvestCount += 1
        foUSPDNDz(
            "Harvested at "
                .. DfrqgXXsrB(ksXdsOKIx.Multiplier or "?")
                .. "x"
        )
    end

    if euyMjRhaK.CurrentPlantRound == kHtWakxlAm then
        euyMjRhaK.CurrentPlantRound = nil
        euyMjRhaK.CurrentMultiplier = 0
        euyMjRhaK.CurrentSeed = nil
        euyMjRhaK.CurrentHarvestTarget = ibVEMhwTQRuM.HarvestMultiplier
    end

    return true
end

local function FSpVeFeSC()
    return ibVEMhwTQRuM.AutoHarvest or ibVEMhwTQRuM.AutoCollectDead
end

local function MYPWVjAymKiW(lSSAtRsxOpy)
    while PKTqUhNlA.Alive
        and FSpVeFeSC()
        and not lSSAtRsxOpy() do

        local meYmQTnufS = lciEiyCr()

        for _, kHtWakxlAm in ZVOoBlCEzTM(meYmQTnufS) do
            if lSSAtRsxOpy()
                or not FSpVeFeSC() then
                break
            end

            local ksXdsOKIx = ciyEOPymQW(kHtWakxlAm)

            if ksXdsOKIx then
                local mheQJrvIu =
                    PwPdrJwbG(kHtWakxlAm)

                if euyMjRhaK.CurrentPlantRound == kHtWakxlAm then
                    euyMjRhaK.CurrentMultiplier =
                        FPwbuFJZR(ksXdsOKIx.Multiplier) or 0
                    euyMjRhaK.CurrentSeed =
                        EgiwikUN(kHtWakxlAm)
                    euyMjRhaK.CurrentHarvestTarget =
                        mheQJrvIu
                end

                if ksXdsOKIx.Dead then
                    if ibVEMhwTQRuM.AutoCollectDead then
                        txPqbIUDrkAR(
                            kHtWakxlAm,
                            "dead",
                            lSSAtRsxOpy
                        )
                    end
                elseif ibVEMhwTQRuM.AutoHarvest
                    and ksXdsOKIx.Multiplier ~= nil
                    and ksXdsOKIx.Multiplier >= mheQJrvIu then

                    txPqbIUDrkAR(
                        kHtWakxlAm,
                        "live",
                        lSSAtRsxOpy
                    )
                end
            end
        end

        task.wait(ibVEMhwTQRuM.PlantRoundScanInterval)
    end

    XbOuitZgCfm:Release("RoundMonitor")
    wpFutleQBCyz:ReleaseAction("RoundMonitor")
end

local function ETfcENxgk()
    PxzWtllXIL("RoundMonitor")

    if FSpVeFeSC() then
        nFPpZjLd(
            "RoundMonitor",
            MYPWVjAymKiW
        )
    end
end

local function nFqnaXQCZe(LNufBNUJAR, lSSAtRsxOpy)
    local kHtWakxlAm = SQlPAyWBEQ(LNufBNUJAR)

    if not kHtWakxlAm then
        foUSPDNDz(
            "The growing plant could not be found after planting",
            "danger"
        )
        return false
    end

    euyMjRhaK.CurrentPlantRound = kHtWakxlAm

    while PKTqUhNlA.Alive
        and ibVEMhwTQRuM.AutoPlant
        and not lSSAtRsxOpy() do

        if not kHtWakxlAm.Parent then
            euyMjRhaK.CurrentPlantRound = nil
            euyMjRhaK.CurrentMultiplier = 0
            euyMjRhaK.CurrentSeed = nil
            euyMjRhaK.CurrentHarvestTarget = ibVEMhwTQRuM.HarvestMultiplier
            HXuhwCIQZAB("IDLE")
            return true
        end

        local ksXdsOKIx = ciyEOPymQW(kHtWakxlAm)

        if ksXdsOKIx then
            local mheQJrvIu =
                PwPdrJwbG(kHtWakxlAm)

            euyMjRhaK.CurrentMultiplier =
                FPwbuFJZR(ksXdsOKIx.Multiplier) or 0
            euyMjRhaK.CurrentSeed =
                LNufBNUJAR.Seed or EgiwikUN(kHtWakxlAm)
            euyMjRhaK.CurrentHarvestTarget =
                mheQJrvIu

            if ksXdsOKIx.Dead then
                HXuhwCIQZAB("DEAD", "danger")

                if ibVEMhwTQRuM.AutoCollectDead then
                    foUSPDNDz(
                        "Tree died; waiting for dead-tree collection",
                        "warning"
                    )
                else
                    foUSPDNDz(
                        "Tree is dead. Enable Auto Collect Dead to continue.",
                        "danger"
                    )
                end
            elseif ibVEMhwTQRuM.AutoHarvest
                and ksXdsOKIx.Multiplier ~= nil
                and ksXdsOKIx.Multiplier >= mheQJrvIu then

                HXuhwCIQZAB("READY", "warning")
            else
                HXuhwCIQZAB("GROWING")
            end
        end

        -- Equipment lock is intentionally free while the tree grows.
        task.wait(0.08)
    end

    return false
end

local function gDWpmugEBns(lSSAtRsxOpy)
    while PKTqUhNlA.Alive
        and ibVEMhwTQRuM.AutoPlant
        and not lSSAtRsxOpy() do

        if not tZYyGNtS(lSSAtRsxOpy) then
            break
        end

        if lSSAtRsxOpy() or not ibVEMhwTQRuM.AutoPlant then
            break
        end

        local IYaMnUzVcMk, LNufBNUJAR =
            gSrVNXcYPyKa(
                "AutoPlant",
                lSSAtRsxOpy
            )

        if lSSAtRsxOpy() or not ibVEMhwTQRuM.AutoPlant then
            break
        end

        if IYaMnUzVcMk then
            if not nFqnaXQCZe(LNufBNUJAR, lSSAtRsxOpy) then
                break
            end
        else
            if not pQFNwZAvvQA(0.5, lSSAtRsxOpy) then
                break
            end
        end
    end

    wpFutleQBCyz:EndPlant("AutoPlant")
    Guqfamwp:Release("AutoPlant")
    MogsXTREOt:Release("AutoPlant")
    CskrVDMQyUS:Release("AutoPlant")

    if not wpFutleQBCyz:IsPlantBusy() then
        HXuhwCIQZAB("IDLE")
    end
end

PKTqUhNlA.CollectPlantRound = txPqbIUDrkAR

--============================================================
-- KIRA UI
--============================================================

local function GDUgNLxkAhS()
local ZVSHaxVHqSBo = ahrBAuuaAFi:CreateWindow({SingletonName= "KiraGreedyGrowersScript",
    Title = "Kira Hub",
    Subtitle = "Greedy Growers Script",
    Size = Vector2.new(1000, 600),
    MinSize = Vector2.new(600, 400),
    MaxSize = Vector2.new(1400, 900),
    ToggleKey = Enum.KeyCode.RightShift,
    ShowCloseButton = false,
    ShadowEnabled = false,
    LauncherShadowEnabled = false,
    BackdropEnabled = false,
    ConfigFolder = "KiraUI/Configs/KiraGreedyGrowers",
    DefaultConfigName = "Config 1",
    Status = "Initializing Greedy Growers controller...",
    Phase = "IDLE",
})

PKTqUhNlA.Window = ZVSHaxVHqSBo

local vdYASBydim = ZVSHaxVHqSBo:AddTab("Automation", "A")
local KsIgBRYnWLp = ZVSHaxVHqSBo:AddTab("Garden", "G")
local qHYNwkwkLcVy = ZVSHaxVHqSBo:AddTab("System", "S")

--============================================================
-- AUTOMATION TAB
--============================================================

local NfdrVYlg = vdYASBydim:AddSection("Buying")

local BnraZFVTJ = NfdrVYlg:AddToggle({Text= "Auto Buy Seeds",
    Default = ibVEMhwTQRuM.AutoBuy,
    Flag = "auto_buy",
})

local uOKRbmFS
local ZsjhWQpGBDRm = false

if type(NfdrVYlg.AddMultiSelect) == "function" then
    ZsjhWQpGBDRm = true
    uOKRbmFS = NfdrVYlg:AddMultiSelect({Text= "Buy Seeds",
        Values = SwXZMPqV,
        Default = yhyrfMddESAN(BKheSqKQSiI()),
        Placeholder = "Select seeds...",
        MaxVisibleItems = 8,
        Flag = "buy_seed",
    })
else
    uOKRbmFS = NfdrVYlg:AddDropdown({Text= "Buy Seed",
        Values = BMBjiIBTo,
        Default = ibVEMhwTQRuM.BuySeed == "ALL"
            and "ALL"
            or (ESIHFmWdFau[ibVEMhwTQRuM.BuySeed] or "ALL"),
        Flag = "buy_seed",
    })
end

local MEQYmxrci
local jhfnmoBic = false

if type(NfdrVYlg.AddMultiSelect) == "function" then
    jhfnmoBic = true
    MEQYmxrci = NfdrVYlg:AddMultiSelect({Text= "Buy Rarities",
        Values = fzMNsCGQ,
        Default = caURwNsUKyWo(),
        Placeholder = "Select rarities...",
        MaxVisibleItems = 6,
        Flag = "buy_rarity",
    })
else
    MEQYmxrci = NfdrVYlg:AddDropdown({Text= "Buy Rarity",
        Values = dmbppbxeQ,
        Default = ibVEMhwTQRuM.BuyRarity == "NONE"
            and "ALL"
            or ibVEMhwTQRuM.BuyRarity,
        Flag = "buy_rarity",
    })
end

local UekcHSdHOg = NfdrVYlg:AddSlider({Text= "Buy Check Delay",
    Min = 0.05,
    Max = 1.00,
    Default = ibVEMhwTQRuM.BuyDelay,
    Step = 0.05,
    Suffix = "s",
    Flag = "buy_delay",
})

NfdrVYlg:AddLabel({Text= "Auto Buy only buys seeds that match your filters and skips anything you cannot afford.",
    Wrap = true,
    Muted = true,
    Height = 44,
})

local BeaqiqCFv = vdYASBydim:AddSection("Planting")

local WSHzliWt = BeaqiqCFv:AddToggle({Text= "Auto Plant",
    Default = ibVEMhwTQRuM.AutoPlant,
    Flag = "auto_plant",
})

local OeQwwvFUSS = BeaqiqCFv:AddToggle({Text= "Only Plant During Weather",
    Default = ibVEMhwTQRuM.PlantOnlyDuringWeather,
    Flag = "plant_weather_only",
})

local vsTbpMygwUx

if type(BeaqiqCFv.AddMultiSelect) == "function" then
    vsTbpMygwUx = BeaqiqCFv:AddMultiSelect({Text= "Seeds",
        Values = tqxPJvMCxC,
        Default = KMlaDNlrszI(RyYbdTkwDtE()),
        Placeholder = "Select seeds...",
        MaxVisibleItems = 8,
        Flag = "plant_seeds",
    })
else
    vsTbpMygwUx = BeaqiqCFv:AddDropdown({Text= "Seed",
        Values = tqxPJvMCxC,
        Default = ESIHFmWdFau[ibVEMhwTQRuM.PlantSeed],
        Flag = "plant_seed",
    })
end

local txexGZwAUQ = BeaqiqCFv:AddDropdown({Text= "Fertilizer",
    Values = RLYSHrriuiBl,
    Default = ibVEMhwTQRuM.Fertilizer,
    Flag = "fertilizer",
})

do
    local BhPAHmHGP = false
    local ZWwEhaoIJ
    local xkmiuosYFq
    local kVkwDEtd
    local bNdFHBYlOkP = {
        "Lowest",
        "Highest",
    }

    local function RPRukCuTHV(XUWueugAwuSw)
        return DfrqgXXsrB(XUWueugAwuSw) == "Highest"
            and "Highest"
            or "Lowest"
    end

    local function hdeSYWqGAnr(vPMLceeu)
        if type(PKTqUhNlA.NormalizeWormTypeSelection) == "function" then
            return PKTqUhNlA.NormalizeWormTypeSelection(vPMLceeu, true)
        end

        return {}
    end

    local function KastlRMLXa(ephNnOXqNlUd)
        if type(PKTqUhNlA.WormTypesToLabels) == "function" then
            return PKTqUhNlA.WormTypesToLabels(ephNnOXqNlUd, true)
        end

        return {}
    end

    local function RFNbBEMMJ()
        if type(PKTqUhNlA.ExportWormSettingsState) == "function" then
            return PKTqUhNlA.ExportWormSettingsState()
        end

        return {Locked= true,
            TypesLocked = true,
            PriorityLocked = true,
            Shared = {Use= false,
                Types = {},
                SortMode = "Lowest",
                MinMult = 5,
                MaxMult = 10,
            },
            Values = {},
        }
    end

    local function WfzvYZcR(CQQfyKmnCw, hVKRNUmvaW)
        CQQfyKmnCw = type(CQQfyKmnCw) == "table" and CQQfyKmnCw or {}
        hVKRNUmvaW = type(hVKRNUmvaW) == "table" and hVKRNUmvaW or {}

        local ephNnOXqNlUd =
            hdeSYWqGAnr(
                CQQfyKmnCw.Types
                or CQQfyKmnCw.WormTypes
                or hVKRNUmvaW.Types
                or {}
            )

        local eKAmKQGHBuwj =
            CQQfyKmnCw.Use ~= nil
            and CQQfyKmnCw.Use == true
            or (
                CQQfyKmnCw.Use == nil
                and hVKRNUmvaW.Use == true
            )

        if not eKAmKQGHBuwj then
            ephNnOXqNlUd = {}
        end

        return {Use= eKAmKQGHBuwj and #ephNnOXqNlUd > 0,
            Types = ephNnOXqNlUd,
            SortMode =
                RPRukCuTHV(
                    CQQfyKmnCw.SortMode
                    or CQQfyKmnCw.Priority
                    or hVKRNUmvaW.SortMode
                ),
            MinMult = 5,
            MaxMult = 10,
        }
    end

    local function ZeGSRENWDqTA()
        local tBOlbjGIlYW = RFNbBEMMJ()
        local tpSFmqQNLSF = WfzvYZcR(tBOlbjGIlYW.Shared)
        local BNnGQGeIA = {}

        for DhaBjHwh, CQQfyKmnCw in oYANaOHUQcPs(tBOlbjGIlYW.Values or {}) do
            local KOnCliJlsM =
                WfzvYZcR(CQQfyKmnCw, tpSFmqQNLSF)

            BNnGQGeIA[DfrqgXXsrB(DhaBjHwh)] =
                KOnCliJlsM.Use
                and KastlRMLXa(KOnCliJlsM.Types)
                or {}
        end

        return {Locked= tBOlbjGIlYW.TypesLocked ~= false,
            Shared =
                tpSFmqQNLSF.Use
                and KastlRMLXa(tpSFmqQNLSF.Types)
                or {},
            Values = BNnGQGeIA,
            Items = wTksbWBOfVL(),
        }
    end

    local function sJODHOrMToH()
        local tBOlbjGIlYW = RFNbBEMMJ()
        local tpSFmqQNLSF = WfzvYZcR(tBOlbjGIlYW.Shared)
        local BNnGQGeIA = {}

        for DhaBjHwh, CQQfyKmnCw in oYANaOHUQcPs(tBOlbjGIlYW.Values or {}) do
            BNnGQGeIA[DfrqgXXsrB(DhaBjHwh)] =
                RPRukCuTHV(
                    type(CQQfyKmnCw) == "table"
                    and CQQfyKmnCw.SortMode
                    or tpSFmqQNLSF.SortMode
                )
        end

        return {Locked= tBOlbjGIlYW.PriorityLocked ~= false,
            Shared = tpSFmqQNLSF.SortMode,
            Values = BNnGQGeIA,
            Items = wTksbWBOfVL(),
        }
    end

    local function kAXktpLdMRZU()
        if not kVkwDEtd then
            return
        end

        local tBOlbjGIlYW = RFNbBEMMJ()
        local tpSFmqQNLSF = WfzvYZcR(tBOlbjGIlYW.Shared)
        local pHerSwhB =
            tpSFmqQNLSF.Use
            and (
                table.concat(
                    KastlRMLXa(tpSFmqQNLSF.Types),
                    ", "
                )
                .. " | "
                .. tpSFmqQNLSF.SortMode
            )
            or "use fertilizer"

        local ceWxoeag = {
            "Types: "
                .. (
                    tBOlbjGIlYW.TypesLocked ~= false
                    and "same for all seeds"
                    or "custom per seed"
                ),
            "Priority: "
                .. (
                    tBOlbjGIlYW.PriorityLocked ~= false
                    and "same for all seeds"
                    or "custom per seed"
                ),
            "Shared: " .. pHerSwhB,
            "No Worm selected means that seed uses fertilizer.",
        }

        if PKTqUhNlA.WormBridge then
            ceWxoeag[#ceWxoeag + 1] =
                PKTqUhNlA.WormBridge:GetSummaryText()
        end

        kVkwDEtd:SetText(
            table.concat(ceWxoeag, "\n")
        )
    end

    function PKTqUhNlA.RefreshWormControls()
        if not ZWwEhaoIJ
            or not xkmiuosYFq then
            return
        end

        BhPAHmHGP = true
        ZWwEhaoIJ:SetValue(ZeGSRENWDqTA(), true)
        xkmiuosYFq:SetValue(sJODHOrMToH(), true)
        BhPAHmHGP = false

        kAXktpLdMRZU()
    end

    local function DtTNYXEYgNaI()
        if BhPAHmHGP then
            return
        end

        BhPAHmHGP = true

        local ZlcOnaLiC =
            ZWwEhaoIJ
            and ZWwEhaoIJ.Value
            or ZeGSRENWDqTA()

        local ljxPHfbqsln =
            xkmiuosYFq
            and xkmiuosYFq.Value
            or sJODHOrMToH()

        local vQEhivhgdBO =
            ibVEMhwTQRuM.WormTypesLocked ~= false

        local FcKkRKYEIUlz =
            ibVEMhwTQRuM.WormPriorityLocked ~= false

        ibVEMhwTQRuM.WormTypesLocked =
            ZlcOnaLiC.Locked ~= false

        ibVEMhwTQRuM.WormPriorityLocked =
            ljxPHfbqsln.Locked ~= false

        ibVEMhwTQRuM.WormSettingsLocked =
            ibVEMhwTQRuM.WormTypesLocked
            and ibVEMhwTQRuM.WormPriorityLocked

        local zvdwcpRxNqwo =
            hdeSYWqGAnr(ZlcOnaLiC.Shared)

        if type(PKTqUhNlA.SetSharedWormSettings) == "function" then
            PKTqUhNlA.SetSharedWormSettings({Use= #zvdwcpRxNqwo > 0,
                Types = zvdwcpRxNqwo,
                SortMode = RPRukCuTHV(ljxPHfbqsln.Shared),
                MinMult = 5,
                MaxMult = 10,
            })
        end

        local TgnMQPnw =
            ibVEMhwTQRuM.WormSettings or {}

        local WqCuKzClFUmx = {}

        for DhaBjHwh in oYANaOHUQcPs(TgnMQPnw) do
            WqCuKzClFUmx[DfrqgXXsrB(DhaBjHwh)] = true
        end

        for DhaBjHwh in oYANaOHUQcPs(ZlcOnaLiC.Values or {}) do
            WqCuKzClFUmx[DfrqgXXsrB(DhaBjHwh)] = true
        end

        for DhaBjHwh in oYANaOHUQcPs(ljxPHfbqsln.Values or {}) do
            WqCuKzClFUmx[DfrqgXXsrB(DhaBjHwh)] = true
        end

        ibVEMhwTQRuM.WormSettings = {}

        for DhaBjHwh in oYANaOHUQcPs(WqCuKzClFUmx) do
            if ESIHFmWdFau[DhaBjHwh] then
                local ePsFdTwtV =
                    WfzvYZcR(
                        TgnMQPnw[DhaBjHwh],
                        {Use= #zvdwcpRxNqwo > 0,
                            Types = zvdwcpRxNqwo,
                            SortMode =
                                RPRukCuTHV(
                                    ljxPHfbqsln.Shared
                                ),
                        }
                    )

                local BCckXWVK =
                    ZlcOnaLiC.Values
                    and ZlcOnaLiC.Values[DhaBjHwh]

                local LfoaIEwDuiep =
                    BCckXWVK

                if LfoaIEwDuiep == nil then
                    LfoaIEwDuiep =
                        KastlRMLXa(ePsFdTwtV.Types)
                end

                local ephNnOXqNlUd =
                    hdeSYWqGAnr(
                        LfoaIEwDuiep ~= nil
                        and LfoaIEwDuiep
                        or ZlcOnaLiC.Shared
                    )

                local XYYfagCRE =
                    ljxPHfbqsln.Values
                    and ljxPHfbqsln.Values[DhaBjHwh]

                ibVEMhwTQRuM.WormSettings[DhaBjHwh] = {Use= #ephNnOXqNlUd > 0,
                    Types = ephNnOXqNlUd,
                    SortMode =
                        RPRukCuTHV(
                            XYYfagCRE
                            or ePsFdTwtV.SortMode
                            or ljxPHfbqsln.Shared
                        ),
                    MinMult = 5,
                    MaxMult = 10,
                }
            end
        end

        BhPAHmHGP = false

        if vQEhivhgdBO ~= ibVEMhwTQRuM.WormTypesLocked
            or FcKkRKYEIUlz ~= ibVEMhwTQRuM.WormPriorityLocked then
            foUSPDNDz(
                "Worm: types "
                    .. (
                        ibVEMhwTQRuM.WormTypesLocked
                        and "locked"
                        or "custom"
                    )
                    .. ", priority "
                    .. (
                        ibVEMhwTQRuM.WormPriorityLocked
                        and "locked"
                        or "custom"
                    )
            )
        end

        kAXktpLdMRZU()
    end

    ZWwEhaoIJ = BeaqiqCFv:AddMultiSelectMap({Text= "Worm Types",
        Values = PKTqUhNlA.WormLabels or {"Worm"},
        Items = wTksbWBOfVL,
        Locked = ibVEMhwTQRuM.WormTypesLocked ~= false,
        Shared = ZeGSRENWDqTA().Shared,
        ItemValues = ZeGSRENWDqTA().Values,
        EmptyText = "Use fertilizer",
        MaxVisibleItems = 6,
        MaxVisibleChoices = 8,
        MaxLabels = 1,
        ItemControlWidth = 166,
    })

    xkmiuosYFq = BeaqiqCFv:AddSelectMap({Text= "Worm Priority",
        Values = bNdFHBYlOkP,
        Items = wTksbWBOfVL,
        Locked = ibVEMhwTQRuM.WormPriorityLocked ~= false,
        Shared = sJODHOrMToH().Shared,
        ItemValues = sJODHOrMToH().Values,
        MaxVisibleItems = 6,
        ItemControlWidth = 112,
    })

    kVkwDEtd = BeaqiqCFv:AddLabel({Text= "Worm inventory is loading...",
        Wrap = true,
        Muted = true,
        Height = 118,
    })

    ZWwEhaoIJ:OnChanged(function()
        DtTNYXEYgNaI("types")
    end)

    xkmiuosYFq:OnChanged(function()
        DtTNYXEYgNaI("priority")
    end)

    if type(ZVSHaxVHqSBo.RegisterConfigItem) == "function" then
        ZVSHaxVHqSBo:RegisterConfigItem("worm_settings", {}, {Getter= function()
                return PKTqUhNlA.ExportWormSettingsState()
            end,
            Setter = function(XUWueugAwuSw)
                PKTqUhNlA.ApplyWormSettingsState(XUWueugAwuSw)
                PKTqUhNlA.RefreshWormControls()
            end,
        })
    end

    task.spawn(function()
        while PKTqUhNlA.Alive
            and ZVSHaxVHqSBo.Gui
            and ZVSHaxVHqSBo.Gui.Parent do

            kAXktpLdMRZU()
            task.wait(1)
        end
    end)

    PKTqUhNlA.RefreshWormControls()
end

local BnNzdXHmmx =
    vdYASBydim:AddSection(
        "Harvest"
    )

local kMAWeIWI =
    BnNzdXHmmx:AddToggle({Text= "Auto Harvest",
        Default = ibVEMhwTQRuM.AutoHarvest,
        Flag = "auto_harvest",
    })

local VzhdfHEI =
    BnNzdXHmmx:AddToggle({Text= "Clear Dead Trees",
        Default = ibVEMhwTQRuM.AutoCollectDead,
        Flag = "clear_dead_trees",
    })

local fSONraohYAAG =
    BnNzdXHmmx:AddToggle({Text= "Auto Collect Fruit",
        Default = ibVEMhwTQRuM.AutoCollectFruit,
        Flag = "auto_collect_fruit",
    })

local BxZCavsNlG =
    BnNzdXHmmx:AddToggle({Text= "Collect All Fruit",
        Default = ibVEMhwTQRuM.CollectAllFruit,
        Flag = "collect_all_fruit",
    })

local mQWmyXAPG =
    BnNzdXHmmx:AddInput({Text= "Minimum Fruit Mutations",
        Numeric = true,
        Min = 0,
        Default = ibVEMhwTQRuM.MinFruitMutations,
        Step = 1,
        Placeholder = "5",
        Flag = "min_fruit_mutations",
    })

local nLHwcAJvJ =
    BnNzdXHmmx:AddSlider({Text= "Fruit Check Delay",
        Min = 0.25,
        Max = 5.00,
        Default = ibVEMhwTQRuM.FruitCollectInterval,
        Step = 0.25,
        Suffix = "s",
        Flag = "fruit_collect_interval",
    })

local RxASKBGxtwI

if type(BnNzdXHmmx.AddNumberMap) == "function" then
    RxASKBGxtwI =
        BnNzdXHmmx:AddNumberMap({Text= "Harvest Targets",
            Items = wTksbWBOfVL,
            Locked = ibVEMhwTQRuM.HarvestMultiplierLocked,
            Shared = ibVEMhwTQRuM.HarvestMultiplier,
            Values = ibVEMhwTQRuM.HarvestMultipliers,
            Min = 0.01,
            Step = 0.01,
            Suffix = "x",
            Placeholder = "Shared multiplier",
            MaxVisibleItems = 6,
            Flag = "harvest_targets",
        })
else
    RxASKBGxtwI =
        BnNzdXHmmx:AddInput({Text= "Harvest At Multiplier",
            Numeric = true,
            Min = 0.01,
            Default = ibVEMhwTQRuM.HarvestMultiplier,
            Step = 0.01,
            Placeholder = "100 or 94.57",
            Flag = "harvest_multiplier",
        })
end

local NEAVSpcFZG =
    BnNzdXHmmx:AddLabel({Text= "Waiting for a plant to grow...",
        Wrap = true,
        Muted = true,
        Height = 78,
    })

BnNzdXHmmx:AddLabel({Text= "Auto Harvest watches your growing plant and collects it when it reaches your target. Auto Collect Fruit picks fruit from your plot; Collect All Fruit ignores the mutation minimum.",
    Wrap = true,
    Muted = true,
    Height = 74,
})

local HNjWdzMJTsV = vdYASBydim:AddSection("Selling")

local wPDpgXsd = HNjWdzMJTsV:AddToggle({Text= "Auto Sell Dead Trees",
    Default = ibVEMhwTQRuM.AutoSellDeadTree,
    Flag = "auto_sell_dead_trees",
})

local RdrxvLvuX = HNjWdzMJTsV:AddToggle({Text= "Auto Sell Fruit",
    Default = ibVEMhwTQRuM.AutoSellFruit,
    Flag = "auto_sell_fruit",
})

local ohSqYrSVs = HNjWdzMJTsV:AddSlider({Text= "Sell Delay",
    Min = 0.05,
    Max = 1.00,
    Default = ibVEMhwTQRuM.SellDelay,
    Step = 0.05,
    Suffix = "s",
    Flag = "sell_delay",
})

HNjWdzMJTsV:AddLabel({Text= "Auto Sell sells dead trees and collected fruit from your bag. It waits if another action is using your held item.",
    Wrap = true,
    Muted = true,
    Height = 54,
})

local yOgaIYwGhsb = vdYASBydim:AddSection("Composting")

local tXdecIiUV =
    yOgaIYwGhsb:AddToggle({Text= "Auto Compost Seed",
        Default = ibVEMhwTQRuM.AutoCompostSeed,
        Flag = "auto_compost_seed",
    })

local OwKkmqTff
local gdxDTXid = false

if type(yOgaIYwGhsb.AddMultiSelect) == "function" then
    gdxDTXid = true
    OwKkmqTff =
        yOgaIYwGhsb:AddMultiSelect({Text= "Compost Seeds",
            Values = tqxPJvMCxC,
            Default = vAvhLYicjXw(XuodfQsedbd()),
            Placeholder = "Select seeds...",
            MaxVisibleItems = 8,
            Flag = "compost_seeds",
        })
else
    OwKkmqTff =
        yOgaIYwGhsb:AddDropdown({Text= "Compost Seed",
            Values = tqxPJvMCxC,
            Default = ESIHFmWdFau[ibVEMhwTQRuM.CompostSeed],
            Flag = "compost_seed",
        })
end

local YvipksYoZh =
    yOgaIYwGhsb:AddSlider({Text= "Compost Delay",
        Min = 0.10,
        Max = 2.00,
        Default = ibVEMhwTQRuM.CompostDelay,
        Step = 0.05,
        Suffix = "s",
        Flag = "compost_delay",
    })

yOgaIYwGhsb:AddLabel({Text= "Auto Compost uses the selected seeds from Hotbar and Storage, including seeds with weather or special names, then collects the reward when it is ready.",
    Wrap = true,
    Muted = true,
    Height = 58,
})

local xTNVQxhAY = vdYASBydim:AddSection("Live Status", {Span= "full",
})

local zvVSqHrMlO = xTNVQxhAY:AddLabel({Text= "Getting Kira Hub ready...",
    Wrap = true,
    Height = 232,
})

--============================================================
-- GARDEN TAB
--============================================================

local BDxpiojPQKbS = KsIgBRYnWLp:AddSection("My Plot")

local yUSlqYqU = BDxpiojPQKbS:AddLabel({Text= "Finding your plot...",
    Wrap = true,
    Height = 64,
})

BDxpiojPQKbS:AddButton({Text= "Refresh My Plot",
    Callback = function()
        local EojeQsclmwhy = kUPNnQqxT()
        if EojeQsclmwhy then
            yUSlqYqU:SetText(
                "Your plot: " .. EojeQsclmwhy.Name
            )
            foUSPDNDz("My plot: " .. EojeQsclmwhy.Name)
        else
            yUSlqYqU:SetText("My plot was not found")
            foUSPDNDz("My plot was not found", "danger")
        end
    end,
})

local OMllaFECG = KsIgBRYnWLp:AddSection("My Fruit Mutations", {Span= "full",
})

local UGIVRgvBE = OMllaFECG:AddToggle({Text= "Auto Refresh Fruit List",
    Default = ibVEMhwTQRuM.AutoMutationScan,
    Flag = "auto_refresh_fruits",
})

local uvOCyyAiZ = OMllaFECG:AddSlider({Text= "Fruit Refresh Interval",
    Min = 0.5,
    Max = 10,
    Default = ibVEMhwTQRuM.MutationScanInterval,
    Step = 0.5,
    Suffix = "s",
    Flag = "fruit_refresh_interval",
})

local HmwGeiVS = OMllaFECG:AddLabel({Text= "Press Refresh Fruit List to show every fruit on your plot and its mutation.",
    Wrap = true,
    RichText = true,
    Height = 190,
})

if HmwGeiVS and type(HmwGeiVS.SetRichText) == "function" then
    HmwGeiVS:SetRichText(true)
elseif HmwGeiVS and HmwGeiVS.Label then
    HmwGeiVS.Label.RichText = true
end

local function WZvhEZmy(ksXdsOKIx, height)
    height = math.max(64, FPwbuFJZR(height) or 190)

    if ksXdsOKIx and type(ksXdsOKIx.SetHeight) == "function" then
        ksXdsOKIx:SetHeight(height)
        return
    end

    if ksXdsOKIx and ksXdsOKIx.Instance then
        ksXdsOKIx.Instance.Size = UDim2.new(ksXdsOKIx.Instance.Size.X.Scale, ksXdsOKIx.Instance.Size.X.Offset, 0, height)
    end
end

local function iPexFYUa(silent)
    local tBOlbjGIlYW, ujxUlzok = psKuspqQP()

    if ujxUlzok then
        WZvhEZmy(HmwGeiVS, 190)
        HmwGeiVS:SetText(ujxUlzok)
        if not silent then
            foUSPDNDz(ujxUlzok, "danger")
        end
        return
    end

    if #tBOlbjGIlYW == 0 then
        WZvhEZmy(HmwGeiVS, 190)
        HmwGeiVS:SetText("No fruit mutation data found on my plot.")
        if not silent then
            foUSPDNDz("Fruit list: 0 fruit")
        end
        return
    end

    local ceWxoeag = {}
    ceWxoeag[#ceWxoeag + 1] = "Total: " .. DfrqgXXsrB(#tBOlbjGIlYW) .. " fruit(s)"
    ceWxoeag[#ceWxoeag + 1] = ""

    for LvOjTWuqYW = 1, #tBOlbjGIlYW do
        local bTjKsleJ = tBOlbjGIlYW[LvOjTWuqYW]
        local sMYoMwHBBUgT = {
            "Value: " .. zIwNzVxielXw(bTjKsleJ.FruitValue or "?"),
            "Mutations: " .. DfrqgXXsrB(bTjKsleJ.MutationCount or 0),
        }

        ceWxoeag[#ceWxoeag + 1] =
            DfrqgXXsrB(LvOjTWuqYW)
            .. ". "
            .. zIwNzVxielXw(bTjKsleJ.Name)

        ceWxoeag[#ceWxoeag + 1] =
            "   " .. table.concat(sMYoMwHBBUgT, " | ")

        ceWxoeag[#ceWxoeag + 1] =
            "   Mutation: " .. (bTjKsleJ.MutationRichText or "None")
    end

    WZvhEZmy(HmwGeiVS, (#ceWxoeag * 16) + 18)
    HmwGeiVS:SetText(table.concat(ceWxoeag, "\n"))

    if not silent then
        foUSPDNDz("Fruit list: " .. DfrqgXXsrB(#tBOlbjGIlYW) .. " fruit(s)")
    end
end

OMllaFECG:AddButton({Text= "Refresh Fruit List",
    Callback = function()
        iPexFYUa(false)
    end,
})

--============================================================
-- SYSTEM TAB
--============================================================

local KqlWmKAYClRC = qHYNwkwkLcVy:AddSection("Controls")

local RLjbrIMQz = KqlWmKAYClRC:AddToggle({Text= "Show Extra Logs",
    Default = ibVEMhwTQRuM.Debug,
    Flag = "show_extra_logs",
})

if type(KqlWmKAYClRC.AddKeybind) == "function" then
    KqlWmKAYClRC:AddKeybind({Text= "Show / Hide Key",
        WindowToggle = true,
        Flag = "show_hide_key",
    })
else
    KqlWmKAYClRC:AddLabel({Text= "Show / Hide: RightShift",
        Muted = true,
        Height = 28,
    })
end

local asRVVntKCLIk = KqlWmKAYClRC:AddToggle({Text= "Anti-AFK",
    Default = ibVEMhwTQRuM.AntiAfk,
    Flag = "anti_afk",
})

KqlWmKAYClRC:AddButton({Text= "Refresh Shop List",
    Callback = function()
        WYIEBUUAT()

        foUSPDNDz(
            "Shop list refreshed: "
                .. DfrqgXXsrB(
                    XarpitBPFIg()
                )
                .. " item(s)"
        )
    end,
})

KqlWmKAYClRC:AddButton({Text= "Hide UI",
    Callback = function()
        if type(ZVSHaxVHqSBo.SetVisible) == "function" then
            ZVSHaxVHqSBo:SetVisible(false)
            foUSPDNDz("UI hidden. Press the show/hide key or the K launcher.")
        end
    end,
})

KqlWmKAYClRC:AddButton({Text= "STOP ALL",
    Danger = true,
    Callback = function()
        ibVEMhwTQRuM.AutoBuy = false
        ibVEMhwTQRuM.AutoPlant = false
        ibVEMhwTQRuM.AutoHarvest = false
        ibVEMhwTQRuM.AutoCollectDead = false
        ibVEMhwTQRuM.AutoMutationScan = false
        ibVEMhwTQRuM.AutoSellDeadTree = false
        ibVEMhwTQRuM.AutoSellFruit = false
        ibVEMhwTQRuM.AutoCollectFruit = false
        ibVEMhwTQRuM.AutoCompostSeed = false
        ibVEMhwTQRuM.AntiAfk = false

        bQLHthvj()
        WFtZRMBScv()
        WYIEBUUAT()

        BnraZFVTJ:SetValue(false, true)
        WSHzliWt:SetValue(false, true)
        kMAWeIWI:SetValue(false, true)
        VzhdfHEI:SetValue(false, true)
        UGIVRgvBE:SetValue(false, true)
        wPDpgXsd:SetValue(false, true)
        RdrxvLvuX:SetValue(false, true)
        fSONraohYAAG:SetValue(false, true)
        tXdecIiUV:SetValue(false, true)
        asRVVntKCLIk:SetValue(false, true)

        if not wpFutleQBCyz:IsPlantBusy()
            and MogsXTREOt.Owner == nil
            and Guqfamwp.Owner == nil
            and CskrVDMQyUS.Owner == nil
            and XbOuitZgCfm.Owner == nil then
            HXuhwCIQZAB("IDLE")
        else
            HXuhwCIQZAB("STOPPING", "warning")
        end

        foUSPDNDz("Stopping automation safely...", "warning")
    end,
})

KqlWmKAYClRC:AddButton({Text= "Destroy Script",
    Danger = true,
    Callback = function()
        PKTqUhNlA:Destroy()
    end,
})

if type(ZVSHaxVHqSBo.AddConfigSection) == "function" then
    ZVSHaxVHqSBo:AddConfigSection(qHYNwkwkLcVy, {Title= "Saved Settings",
        Span = 1,
        DefaultName = "Config 1",
    })
end

--============================================================
-- ATTACH UI BEHAVIOR AFTER UI EXISTS
--============================================================

BnraZFVTJ:OnChanged(function(XUWueugAwuSw)
    ibVEMhwTQRuM.AutoBuy = XUWueugAwuSw == true

    if ibVEMhwTQRuM.AutoBuy then
        foUSPDNDz("Auto Buy enabled")
        nFPpZjLd("AutoBuy", tgBBKFdcBcp)
    else
        PxzWtllXIL("AutoBuy")
        WYIEBUUAT()
        foUSPDNDz("Auto Buy disabled")
    end
end)

uOKRbmFS:OnChanged(function(XUWueugAwuSw)
    local otMRsdmAPve = cMtFJivxtN(XUWueugAwuSw)

    if ZsjhWQpGBDRm
        and type(uOKRbmFS.SetValue) == "function" then
        uOKRbmFS:SetValue(yhyrfMddESAN(otMRsdmAPve), true)
    end

    WYIEBUUAT()
    foUSPDNDz("Buy seeds: " .. AyxJZxZvpa())
end)

MEQYmxrci:OnChanged(function(XUWueugAwuSw)
    local otMRsdmAPve = QOGIdmUgLGgH(XUWueugAwuSw)

    if jhfnmoBic
        and type(MEQYmxrci.SetValue) == "function" then
        MEQYmxrci:SetValue(otMRsdmAPve, true)
    end

    WYIEBUUAT()
    foUSPDNDz("Buy rarities: " .. OObSspcJge())
end)

UekcHSdHOg:OnChanged(function(XUWueugAwuSw)
    ibVEMhwTQRuM.BuyDelay = FPwbuFJZR(XUWueugAwuSw) or 0.15
end)

WSHzliWt:OnChanged(function(XUWueugAwuSw)
    ibVEMhwTQRuM.AutoPlant = XUWueugAwuSw == true

    if ibVEMhwTQRuM.AutoPlant then
        local CSJzVWFOz, UnCMwRYd = dHqyhbRECjo()

        if ibVEMhwTQRuM.PlantOnlyDuringWeather and not UnCMwRYd then
            foUSPDNDz(
                "Auto Plant enabled; waiting for weather (current: "
                    .. CSJzVWFOz
                    .. ")",
                "warning"
            )
        else
            foUSPDNDz("Auto Plant enabled")
        end

        nFPpZjLd("AutoPlant", gDWpmugEBns)
    else
        PxzWtllXIL("AutoPlant")

        if not wpFutleQBCyz:IsPlantBusy() then
            HXuhwCIQZAB("IDLE")
        else
            HXuhwCIQZAB("STOPPING", "warning")
        end

        foUSPDNDz("Auto Plant disabled")
    end
end)

OeQwwvFUSS:OnChanged(function(XUWueugAwuSw)
    ibVEMhwTQRuM.PlantOnlyDuringWeather = XUWueugAwuSw == true

    local CSJzVWFOz, UnCMwRYd = dHqyhbRECjo()

    if ibVEMhwTQRuM.PlantOnlyDuringWeather then
        if UnCMwRYd then
            foUSPDNDz(
                "Weather-only planting ON: "
                    .. CSJzVWFOz
            )
        else
            foUSPDNDz(
                "Weather-only planting ON; waiting for weather (current: "
                    .. CSJzVWFOz
                    .. ")",
                "warning"
            )
        end
    else
        foUSPDNDz("Weather-only planting OFF")

        if ibVEMhwTQRuM.AutoPlant and not wpFutleQBCyz:IsPlantBusy() then
            HXuhwCIQZAB("IDLE")
        end
    end
end)

vsTbpMygwUx:OnChanged(function(XUWueugAwuSw)
    local otMRsdmAPve =
        type(XUWueugAwuSw) == "table"
        and XkuqAzFB(XUWueugAwuSw)
        or XkuqAzFB({XUWueugAwuSw})

    otMRsdmAPve = xvfaxgVJgb(otMRsdmAPve)

    if #otMRsdmAPve == 0 then
        foUSPDNDz("No plant seed selected", "warning")
        if RxASKBGxtwI
            and type(RxASKBGxtwI.SetItems) == "function" then
            RxASKBGxtwI:SetItems({}, true)
        end
        return
    end

    if RxASKBGxtwI
        and type(RxASKBGxtwI.SetItems) == "function" then
        RxASKBGxtwI:SetItems(wTksbWBOfVL(), true)
    end

    if type(PKTqUhNlA.RefreshWormControls) == "function" then
        PKTqUhNlA.RefreshWormControls()
    end

    local LPawgQwRR = {}

    for _, DhaBjHwh in ZVOoBlCEzTM(otMRsdmAPve) do
        if ZMZXtZNTlb:GetSeedCount(DhaBjHwh) > 0 then
            LPawgQwRR[#LPawgQwRR + 1] = DhaBjHwh
        end
    end

    if #LPawgQwRR > 0 then
        foUSPDNDz(
            "Plant seeds: "
                .. table.concat(otMRsdmAPve, ", ")
                .. " | owned: "
                .. table.concat(LPawgQwRR, ", ")
        )
    else
        foUSPDNDz(
            "Plant seeds: "
                .. table.concat(otMRsdmAPve, ", ")
                .. " (not currently owned)",
            "warning"
        )
    end
end)

txexGZwAUQ:OnChanged(function(XUWueugAwuSw)
    ibVEMhwTQRuM.Fertilizer = DfrqgXXsrB(XUWueugAwuSw)
    foUSPDNDz("Fertilizer: " .. ibVEMhwTQRuM.Fertilizer)
end)

kMAWeIWI:OnChanged(function(XUWueugAwuSw)
    ibVEMhwTQRuM.AutoHarvest = XUWueugAwuSw == true
    ETfcENxgk()

    foUSPDNDz(
        "Auto Harvest: "
            .. (ibVEMhwTQRuM.AutoHarvest and "ON" or "OFF")
    )
end)

VzhdfHEI:OnChanged(function(XUWueugAwuSw)
    ibVEMhwTQRuM.AutoCollectDead = XUWueugAwuSw == true
    ETfcENxgk()

    foUSPDNDz(
        "Auto Collect Dead: "
            .. (ibVEMhwTQRuM.AutoCollectDead and "ON" or "OFF")
    )
end)

fSONraohYAAG:OnChanged(function(XUWueugAwuSw)
    ibVEMhwTQRuM.AutoCollectFruit = XUWueugAwuSw == true

    if ibVEMhwTQRuM.AutoCollectFruit then
        foUSPDNDz("Auto Collect Fruit enabled")
        nFPpZjLd("AutoCollectFruit", kMZYSSjK)
    else
        PxzWtllXIL("AutoCollectFruit")
        wpFutleQBCyz:ReleaseAction("AutoCollectFruit")
        foUSPDNDz("Auto Collect Fruit disabled")

        if not wpFutleQBCyz:IsPlantBusy() then
            HXuhwCIQZAB("IDLE")
        end
    end
end)

BxZCavsNlG:OnChanged(function(XUWueugAwuSw)
    ibVEMhwTQRuM.CollectAllFruit = XUWueugAwuSw == true

    if ibVEMhwTQRuM.CollectAllFruit then
        foUSPDNDz("Collect All Fruit enabled")
    else
        foUSPDNDz(
            "Collecting fruit with "
                .. DfrqgXXsrB(ibVEMhwTQRuM.MinFruitMutations)
                .. "+ mutation(s)"
        )
    end
end)

mQWmyXAPG:OnChanged(function(XUWueugAwuSw)
    ibVEMhwTQRuM.MinFruitMutations =
        math.max(
            0,
            math.floor(
                (FPwbuFJZR(XUWueugAwuSw) or ibVEMhwTQRuM.MinFruitMutations or 0)
                + 0.5
            )
        )

    foUSPDNDz(
        "Minimum fruit mutations: "
            .. DfrqgXXsrB(ibVEMhwTQRuM.MinFruitMutations)
    )
end)

nLHwcAJvJ:OnChanged(function(XUWueugAwuSw)
    ibVEMhwTQRuM.FruitCollectInterval =
        math.max(0.25, FPwbuFJZR(XUWueugAwuSw) or 1)
end)

RxASKBGxtwI:OnChanged(function(XUWueugAwuSw)
    XLZYOtQEIi(XUWueugAwuSw)

    foUSPDNDz(
        "Harvest targets: "
            .. rdYzIypaIF()
    )
end)

wPDpgXsd:OnChanged(function(XUWueugAwuSw)
    ibVEMhwTQRuM.AutoSellDeadTree = XUWueugAwuSw == true

    if ibVEMhwTQRuM.AutoSellDeadTree then
        foUSPDNDz("Auto Sell Dead Trees enabled")
        nFPpZjLd("AutoSellDeadTree", FbIMnaYWL)
    else
        PxzWtllXIL("AutoSellDeadTree")
        wpFutleQBCyz:ReleaseBackgroundEquipment("AutoSellDeadTree")
        foUSPDNDz("Auto Sell Dead Trees disabled")

        if not wpFutleQBCyz:IsPlantBusy() then
            HXuhwCIQZAB("IDLE")
        end
    end
end)

RdrxvLvuX:OnChanged(function(XUWueugAwuSw)
    ibVEMhwTQRuM.AutoSellFruit = XUWueugAwuSw == true

    if ibVEMhwTQRuM.AutoSellFruit then
        foUSPDNDz("Auto Sell Fruit enabled")
        nFPpZjLd("AutoSellFruit", yNkNYPlA)
    else
        PxzWtllXIL("AutoSellFruit")
        wpFutleQBCyz:ReleaseBackgroundEquipment("AutoSellFruit")
        foUSPDNDz("Auto Sell Fruit disabled")

        if not wpFutleQBCyz:IsPlantBusy() then
            HXuhwCIQZAB("IDLE")
        end
    end
end)

ohSqYrSVs:OnChanged(function(XUWueugAwuSw)
    ibVEMhwTQRuM.SellDelay = FPwbuFJZR(XUWueugAwuSw) or 0.15
end)

tXdecIiUV:OnChanged(function(XUWueugAwuSw)
    ibVEMhwTQRuM.AutoCompostSeed = XUWueugAwuSw == true

    if ibVEMhwTQRuM.AutoCompostSeed then
        if ibVEMhwTQRuM.AutoPlant then
            ibVEMhwTQRuM.AutoPlant = false
            PxzWtllXIL("AutoPlant")

            if WSHzliWt
                and type(WSHzliWt.SetValue) == "function" then
                WSHzliWt:SetValue(false, true)
            end

            AoDYQAJZTEZM(
                "Auto Compost Seed",
                "Auto Plant đã tạm dừng để giữ bạn ở khu vực Compost Bin.",
                "warning",
                4
            )
        end

        foUSPDNDz("Auto Compost Seed enabled")
        nFPpZjLd("AutoCompostSeed", TQQVQyTiPrA)
    else
        PxzWtllXIL("AutoCompostSeed")
        PxzWtllXIL("CompostMovementGuard")
        wpFutleQBCyz:ReleaseBackgroundEquipment("AutoCompostSeed")
        euyMjRhaK.CompostAnchor = nil
        euyMjRhaK.CompostPrompt = nil
        euyMjRhaK.CompostAnchorPrompt = nil
        foUSPDNDz("Auto Compost Seed disabled")

        if not wpFutleQBCyz:IsPlantBusy() then
            HXuhwCIQZAB("IDLE")
        end
    end
end)

OwKkmqTff:OnChanged(function(XUWueugAwuSw)
    local otMRsdmAPve =
        type(XUWueugAwuSw) == "table"
        and vfTaHKJkC(XUWueugAwuSw)
        or vfTaHKJkC({XUWueugAwuSw})

    otMRsdmAPve = ivsIiUzIw(otMRsdmAPve)

    if type(OwKkmqTff.SetValue) == "function" then
        if gdxDTXid then
            OwKkmqTff:SetValue(
                vAvhLYicjXw(otMRsdmAPve),
                true
            )
        else
            OwKkmqTff:SetValue(
                ESIHFmWdFau[otMRsdmAPve[1] or ibVEMhwTQRuM.CompostSeed],
                true
            )
        end
    end

    foUSPDNDz("Compost seeds: " .. cXqsYNhLLg())
end)

YvipksYoZh:OnChanged(function(XUWueugAwuSw)
    ibVEMhwTQRuM.CompostDelay =
        math.max(0.1, FPwbuFJZR(XUWueugAwuSw) or 0.25)
end)

uvOCyyAiZ:OnChanged(function(XUWueugAwuSw)
    ibVEMhwTQRuM.MutationScanInterval = FPwbuFJZR(XUWueugAwuSw) or 2
end)

UGIVRgvBE:OnChanged(function(XUWueugAwuSw)
    ibVEMhwTQRuM.AutoMutationScan = XUWueugAwuSw == true

    if ibVEMhwTQRuM.AutoMutationScan then
        nFPpZjLd("AutoMutationScan", function(lSSAtRsxOpy)
            while PKTqUhNlA.Alive and ibVEMhwTQRuM.AutoMutationScan and not lSSAtRsxOpy() do
                iPexFYUa(true)
                if not pQFNwZAvvQA(ibVEMhwTQRuM.MutationScanInterval, lSSAtRsxOpy) then
                    break
                end
            end
        end)
        foUSPDNDz("Auto Refresh Fruit List enabled")
    else
        PxzWtllXIL("AutoMutationScan")
        foUSPDNDz("Auto Refresh Fruit List disabled")
    end
end)

RLjbrIMQz:OnChanged(function(XUWueugAwuSw)
    ibVEMhwTQRuM.Debug = XUWueugAwuSw == true
    foUSPDNDz("Extra logs: " .. (ibVEMhwTQRuM.Debug and "ON" or "OFF"))
end)

asRVVntKCLIk:OnChanged(function(XUWueugAwuSw)
    vHRPUjRYZUZk(XUWueugAwuSw == true)
end)

--============================================================
-- INITIAL PLOT + LIVE COORDINATOR INFO
--============================================================

task.defer(function()
    if not PKTqUhNlA.Alive then
        return
    end

    local EojeQsclmwhy = kUPNnQqxT()

    if EojeQsclmwhy then
        yUSlqYqU:SetText(
            "Your plot: " .. EojeQsclmwhy.Name
        )
    else
        yUSlqYqU:SetText("My plot was not detected yet")
    end
end)

task.spawn(function()
    while PKTqUhNlA.Alive and ZVSHaxVHqSBo.Gui and ZVSHaxVHqSBo.Gui.Parent do
        local DcAmitWhFX = jdMXqPJlODtA()

        local rFCibROv, WVWFXsiIeOm =
            AcshXZuiGq()

        local SazuaLvhPq = "none"

        if euyMjRhaK.LastPurchase then
            SazuaLvhPq =
                DfrqgXXsrB(euyMjRhaK.LastPurchase.SeedType)
                .. " "
                .. DfrqgXXsrB(euyMjRhaK.LastPurchase.CostText)
        end

        zvVSqHrMlO:SetText(table.concat({
            "Status: " .. DfrqgXXsrB(euyMjRhaK.Phase),
            "Key: No Key",
            "Coins: " .. DfrqgXXsrB(WVWFXsiIeOm or rFCibROv or "?"),
            "Worms: "
                .. DfrqgXXsrB(euyMjRhaK.WormCount or 0)
                .. " | "
                .. DfrqgXXsrB(euyMjRhaK.LastWormSource or "none"),
            "Inventory: "
                .. DfrqgXXsrB(euyMjRhaK.LastInventorySource or "none")
                .. " | v"
                .. DfrqgXXsrB(ZMZXtZNTlb.Version or 0),
            "Weather: " .. DfrqgXXsrB(euyMjRhaK.CurrentWeather)
                .. (
                    euyMjRhaK.WeatherActive
                    and " (active)"
                    or " (normal)"
                ),
            "Anti-AFK: "
                .. (
                    ibVEMhwTQRuM.AntiAfk
                    and "ON"
                    or "OFF"
                ),
            "Held item: " .. DfrqgXXsrB(DcAmitWhFX and DcAmitWhFX.Name or "none"),
            "Action lock: " .. DfrqgXXsrB(MogsXTREOt.Owner or "none"),
            "Tool lock: " .. DfrqgXXsrB(Guqfamwp.Owner or "none"),
            "Last buy: " .. SazuaLvhPq,
            "Last worm: "
                .. DfrqgXXsrB(
                    euyMjRhaK.LastUsedWorm
                    and (
                        DfrqgXXsrB(euyMjRhaK.LastUsedWorm.DisplayType)
                        .. " "
                        .. DfrqgXXsrB(euyMjRhaK.LastUsedWorm.Mult)
                        .. "x"
                    )
                    or "none"
                ),
            "Bought: " .. DfrqgXXsrB(euyMjRhaK.PurchaseCount)
                .. "   |   Planted: " .. DfrqgXXsrB(euyMjRhaK.PlantCount)
                .. "   |   Harvested: " .. DfrqgXXsrB(euyMjRhaK.HarvestCount)
                .. "   |   Cleared: " .. DfrqgXXsrB(euyMjRhaK.DeadCollectCount)
                .. "   |   Fruit: " .. DfrqgXXsrB(euyMjRhaK.FruitCollectCount),
            "Dead trees sold: " .. DfrqgXXsrB(euyMjRhaK.SellDeadTreeCount),
            "Fruit sold: " .. DfrqgXXsrB(euyMjRhaK.SellFruitCount),
            "Compost: "
                .. DfrqgXXsrB(euyMjRhaK.CompostMode or "UNKNOWN")
                .. " | distance "
                .. DfrqgXXsrB(euyMjRhaK.CompostDistance or 0)
                .. " | given "
                .. DfrqgXXsrB(euyMjRhaK.CompostGiveCount or 0)
                .. " | collected "
                .. DfrqgXXsrB(euyMjRhaK.CompostCollectCount or 0),
            "Fruit listed: " .. DfrqgXXsrB(euyMjRhaK.FruitListedCount),
        }, "\n"))

        local WbXuprlRWe = euyMjRhaK.CurrentPlantRound

        if not WbXuprlRWe or not WbXuprlRWe.Parent then
            local meYmQTnufS = lciEiyCr()
            WbXuprlRWe = meYmQTnufS[#meYmQTnufS]
        end

        if WbXuprlRWe then
            local AmHzJvpYeo = ciyEOPymQW(WbXuprlRWe)

            if AmHzJvpYeo then
                local DhaBjHwh =
                    EgiwikUN(WbXuprlRWe)
                    or "unknown"
                local mheQJrvIu =
                    PwPdrJwbG(WbXuprlRWe)

                NEAVSpcFZG:SetText(
                    table.concat({
                        "Current plant: " .. DfrqgXXsrB(DhaBjHwh),
                        "Growth: "
                            .. DfrqgXXsrB(AmHzJvpYeo.Multiplier or "?")
                            .. "x / "
                            .. DfrqgXXsrB(mheQJrvIu)
                            .. "x",
                        "Target: "
                            .. rdYzIypaIF(),
                        "Worm: "
                            .. (
                                euyMjRhaK.LastPlantContext
                                and euyMjRhaK.LastPlantContext.PlantRound == WbXuprlRWe
                                and euyMjRhaK.LastPlantContext.UsedWorm
                                and (
                                    DfrqgXXsrB(euyMjRhaK.LastPlantContext.WormDisplayType)
                                    .. " "
                                    .. DfrqgXXsrB(euyMjRhaK.LastPlantContext.WormMult)
                                    .. "x"
                                )
                                or "none"
                            ),
                        "Health: "
                            .. (
                                AmHzJvpYeo.Dead
                                and "needs clearing"
                                or "growing"
                            ),
                    }, "\n")
                )
            end
        else
            NEAVSpcFZG:SetText(
                "No plant is growing right now."
            )
        end

        task.wait(0.35)
    end
end)

-- Character respawn: no feature restart is needed; helpers always resolve Character fresh.
PKTqUhNlA:Track(dxLeYzjrD.CharacterAdded:Connect(function()
    task.wait(0.75)
    if PKTqUhNlA.Alive then
        foUSPDNDz("Character reloaded; automation retained")
    end
end))

-- If Kira UI is closed/destroyed, stop runtime too.
PKTqUhNlA:Track(ZVSHaxVHqSBo.Gui.AncestryChanged:Connect(function(_, ODlrNcZGPi)
    if ODlrNcZGPi == nil and PKTqUhNlA.Alive then
        PKTqUhNlA:Destroy()
    end
end))

if FSpVeFeSC() then
    ETfcENxgk()
end

HXuhwCIQZAB("IDLE")
foUSPDNDz("Kira Hub ready")

if type(ZVSHaxVHqSBo.LoadAutoConfig) == "function" then
    task.defer(function()
        if not PKTqUhNlA.Alive then
            return
        end

        local uPirkaZfGG, dQSktSlt, CRwBIXohMQ = ZVSHaxVHqSBo:LoadAutoConfig()

        if uPirkaZfGG and CRwBIXohMQ then
            foUSPDNDz(
                "Autoload config loaded: "
                    .. DfrqgXXsrB(CRwBIXohMQ)
                    .. " ("
                    .. DfrqgXXsrB(dQSktSlt)
                    .. " setting(s))",
                "success"
            )
        elseif not uPirkaZfGG then
            foUSPDNDz(
                "Autoload failed: " .. DfrqgXXsrB(dQSktSlt),
                "danger"
            )
        end
    end)
end

-- Expose useful functions for later patching/debugging.
PKTqUhNlA.RefreshMutations = iPexFYUa
PKTqUhNlA.ClearBuyQueue = WYIEBUUAT
PKTqUhNlA.ScanConveyor = XarpitBPFIg
PKTqUhNlA.GetInventory = function()
    return ZMZXtZNTlb:GetInventory()
end
PKTqUhNlA.GetSeeds = function()
    return ZMZXtZNTlb:GetSeeds()
end
PKTqUhNlA.GetSeedCount = function(DhaBjHwh)
    return ZMZXtZNTlb:GetSeedCount(DhaBjHwh)
end
PKTqUhNlA.GetPlantSeeds = function()
    return RyYbdTkwDtE()
end
PKTqUhNlA.GetHarvestTargets = function()
    return {Locked= ibVEMhwTQRuM.HarvestMultiplierLocked,
        Shared = ibVEMhwTQRuM.HarvestMultiplier,
        Values = PyoJDKby(ibVEMhwTQRuM.HarvestMultipliers),
    }
end
PKTqUhNlA.GetWeather = function()
    local CSJzVWFOz, UnCMwRYd = dHqyhbRECjo()

    return {Current= CSJzVWFOz,
        Active = UnCMwRYd,
        PlantOnlyDuringWeather = ibVEMhwTQRuM.PlantOnlyDuringWeather,
    }
end
PKTqUhNlA.ResolveSeed = function(DhaBjHwh)
    return ZMZXtZNTlb:ResolveSeed(
        DhaBjHwh,
        jdMXqPJlODtA()
    )
end
PKTqUhNlA.AllSeeds = MKjocGYu
PKTqUhNlA.SeedCatalog = qrOkZyKh
PKTqUhNlA.SeedPriceText = ITzawOckSLt
PKTqUhNlA.RefreshRoundMonitor = ETfcENxgk
PKTqUhNlA.KiraUI = ahrBAuuaAFi

end

GDUgNLxkAhS()

return PKTqUhNlA

end)()
