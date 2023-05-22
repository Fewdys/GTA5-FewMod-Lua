--[[A Lot Was Taken From Other Scripts]]--
--[[Most Was Kept Original, Remade or Modified]]--
--[[Script Is Still A WIP So There May Be Minor Issues]]--

util.keep_running()
util.require_natives(1676318796)
util.require_natives(1663599433)

local response = false
local localversion = 1.31
local localKs = false
async_http.init("raw.githubusercontent.com", "/Fewdys/GTA5-FewMod/main/FewModVersion.lua", function(output)
    currentVer = tostring(output)
    response = true
    if localversion ~= currentVer then
        util.toast("There is an update for FewMod available, use the Update Button to update it.")
        menu.action(menu.my_root(), "Update Script", {}, "Grabs The Newest Version Of Script From \nLink: https://github.com/Fewdys/GTA5-FewMod-Lua", function()
            async_http.init('raw.githubusercontent.com','/Fewdys/GTA5-FewMod/main/Few.lua',function(a)
                local err = select(2,load(a))
                if err then
                    util.toast("There was a issue updating FewMod, please update it manually from github.")
                    util.log("There was a issue updating FewMod, please update it manually from github.")
                    util.toast("Link: https://github.com/Fewdys/GTA5-FewMod-Lua")
                    util.log("Link: https://github.com/Fewdys/GTA5-FewMod-Lua")
                return end
                local f = io.open(filesystem.scripts_dir()..SCRIPT_RELPATH, "wb")
                f:write(a)
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
local aim_only, aim_only_fake_lag = false, false;
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
local defaultBookmark = "default_library"

local spawned_objects = {}
local ladder_objects = {}
local remove_projectiles = false
local int_min = -2147483647
local int_max = 2147483647
local spawned_objects = {}
local ladder_objects = {}

local wallbr = util.joaat("bkr_prop_biker_bblock_mdm3")
local floorbr = util.joaat("bkr_prop_biker_landing_zone_01")
local launch_vehicle = {"Throw Up", "Throw Go Ahead", "Throw Back", "Throw Down", "Catapul"}
local invites = {"Yacht", "Office", "Clubhouse", "Office Garage", "Custom Auto Shop", "Apartment"}
local style_names = {"Normal", "Semi-Rushed", "Reverse", "Ignore Lights", "Avoid Traffic", "Avoid Traffic Extremely", "Sometimes Overtake Traffic"}
local drivingStyles = {786603, 1074528293, 8388614, 1076, 2883621, 786468, 262144, 786469, 512, 5, 6}
local interior_stuff = {0, 233985, 169473, 169729, 169985, 170241, 177665, 177409, 185089, 184833, 184577, 163585, 167425, 167169}

util.toast("Welcome " .. SOCIALCLUB.SC_ACCOUNT_INFO_GET_NICKNAME())

util.toast("Loading FewMod...")
util.log("Loading FewMod...")

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

util.yield(2000)
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

util.yield_once()
menu.divider(uwuself, "Lua Shit")
menu.divider(uwuvehicle, "Lua Shit")
menu.divider(uwuonline, "Lua Shit")
--menu.divider(protecc, "Lua Shit")
menu.divider(uwuworld, "Lua Shit")
menu.divider(uwustand, "Lua Shit")
util.yield_once()

-- Few Functions
util.yield_once()
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

    cwash_in_progwess = function()
        kitty_alpha = 0
        kitty_alpha_incr = 0.01
        kitty_alpha_thread = util.create_thread(function (thr)
            while true do
                kitty_alpha = kitty_alpha + kitty_alpha_incr
                if kitty_alpha > 1 then
                    kitty_alpha = 1
                elseif kitty_alpha < 0 then 
                    kitty_alpha = 0
                    util.stop_thread()
                end
                util.yield(5)
            end
        end)

        kitty_thread = util.create_thread(function (thr)
            starttime = os.clock()
            local alpha = 0
            while true do
                timepassed = os.clock() - starttime
                if timepassed > 3 then
                    kitty_alpha_incr = -0.01
                end
                if kitty_alpha == 0 then
                    util.stop_thread()
                end
                util.yield(5)
            end
        end)
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

    disableProjectileLoop = function(projectile) --This Was Taken From Ryze
        util.create_thread(function()
            util.create_tick_handler(function()
                WEAPON.REMOVE_ALL_PROJECTILES_OF_TYPE(projectile, false)
                return remove_projectiles
            end)
        end)
    end,

    yieldModelLoad = function(hash)
        while not STREAMING.HAS_MODEL_LOADED(hash) do util.yield() end
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

    getNightclubDailyEarnings = function()
        local popularity = math.floor(util.STAT_GET_INT("CLUB_POPULARITY") / 10)
        if popularity > 90 then return 10000
        elseif popularity > 85 then return 9000
        elseif popularity > 80 then return 8000
        elseif popularity > 75 then return 7000
        elseif popularity > 70 then return 6000
        elseif popularity > 65 then return 5500
        elseif popularity > 60 then return 5000
        elseif popularity > 55 then return 4500
        elseif popularity > 50 then return 4000
        elseif popularity > 45 then return 3500
        elseif popularity > 40 then return 3000
        elseif popularity > 35 then return 2500
        elseif popularity > 30 then return 2000
        elseif popularity > 25 then return 1500
        elseif popularity > 20 then return 1000
        elseif popularity > 15 then return 750
        elseif popularity > 10 then return 500
        elseif popularity > 5 then return 250
        else return 100
        end
    end,

    playerIsTargetingEntity = function(playerPed)
        local playerList = players.list(true, true, true)
        for k, playerPid in pairs(playerList) do
            if PLAYER.IS_PLAYER_TARGETTING_ENTITY(playerPid, playerPed) or PLAYER.IS_PLAYER_FREE_AIMING_AT_ENTITY  (playerPid, playerPed) then 
                if not isWhitelisted(playerPid) then
                    karma[playerPed] = {
                        player_id = playerPid, 
                        ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(playerPid)
                    }
                    return true 
                end
            end
        end
        karma[playerPed] = nil
        return false 
    end,

    explodePlayer = function(ped, loop)
        local pos = ENTITY.GET_ENTITY_COORDS(ped)
        local blamedPlayer = PLAYER.PLAYER_PED_ID() 
        if blameExpPlayer and blameExp then 
            blamedPlayer = PLAYER.GET_PLAYER_PED(blameExpPlayer)
        elseif blameExp then
            local playerList = players.list(true, true, true)
            blamedPlayer = PLAYER.GET_PLAYER_PED(math.random(0, #playerList))
        end
        if not loop and PED.IS_PED_IN_ANY_VEHICLE(ped, true) then
            for i = 0, 50, 1 do --50 explosions to account for armored vehicles
                if ownExp or blameExp then 
                    owned_explosion(blamedPlayer, pos)
                else
                    explosion(pos)
                end
                util.yield(10)
            end
        elseif ownExp or blameExp then
            owned_explosion(blamedPlayer, pos)
        else
            explosion(pos)
        end
        util.yield(10)
    end,

    get_coords = function(entity)
        entity = entity or PLAYER.PLAYER_PED_ID()
        return ENTITY.GET_ENTITY_COORDS(entity, true)
    end,

    play_all = function(sound, sound_group, wait_for)
        for i=0, 31, 1 do
            AUDIO.PLAY_SOUND_FROM_ENTITY(-1, sound, PLAYER.GET_PLAYER_PED(i), sound_group, true, 20)
        end
        util.yield(wait_for)
    end,

    explode_all = function(earrape_type, wait_for)
        for i=0, 31, 1 do
            coords = util.get_coords(PLAYER.GET_PLAYER_PED(i))
            FIRE.ADD_EXPLOSION(coords.x, coords.y, coords.z, 0, 100, true, false, 150, false)
            if earrape_type == EARRAPE_BED then
                AUDIO.PLAY_SOUND_FROM_COORD(-1, "Bed", coords.x, coords.y, coords.z, "WastedSounds", true, 999999999, true)
            end
            if earrape_type == EARRAPE_FLASH then
                AUDIO.PLAY_SOUND_FROM_COORD(-1, "MP_Flash", coords.x, coords.y, coords.z, "WastedSounds", true, 999999999, true)
                AUDIO.PLAY_SOUND_FROM_COORD(-1, "MP_Flash", coords.x, coords.y, coords.z, "WastedSounds", true, 999999999, true)
                AUDIO.PLAY_SOUND_FROM_COORD(-1, "MP_Flash", coords.x, coords.y, coords.z, "WastedSounds", true, 999999999, true)
            end
        end
        util.yield(wait_for)
    end,

    kicks = {
        1104117595,
        697566862,
        1268038438,
        915462795,
        697566862,
        1268038438,
        915462795
    },

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
util.yield_once()

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
clear_radius = 100000
function clear_area(clear_radius)
    target_pos = ENTITY.GET_ENTITY_COORDS(PLAYER.PLAYER_PED_ID())
    MISC.CLEAR_AREA(target_pos['x'], target_pos['y'], target_pos['z'], clear_radius, true, false, false, false)
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

players.on_join(function(player_id)

    menu.divider(menu.player_root(player_id), "Lua Shit")

    local Few = menu.list(menu.player_root(player_id), "FewMod")
    local malicious = menu.list(Few, "Malicious")
    local trolling = menu.list(Few, "Troll")
    local friendly = menu.list(Few, "Friendly")
    local vehicle = menu.list(Few, "Vehicle")
    local attachc = menu.list(Few, "Misc")

menu.action(Few, "Block Player / Player Join", {"block"}, "Shortcut to Blocking The Player Join Reaction", function()
    if player_id ~= players.user() then
        menu.trigger_commands("historyblock" .. PLAYER.GET_PLAYER_NAME(player_id))
        util.toast("You Will Now Be Blocking "..PLAYER.GET_PLAYER_NAME(player_id).."'s Join \n(Or Have Unblocked There Join)")
        util.log("You Will Now Be Blocking "..PLAYER.GET_PLAYER_NAME(player_id).."'s Join \n(Or Have Unblocked There Join)")
    else
        util.toast("You Cant Block Yourself Silly <3")
    end
end)

    menu.action(menu.player_root(player_id), "Breakup Kick", {}, "Stand's Breakup Kick", function()
        menu.trigger_commands("breakup"..PLAYER.GET_PLAYER_NAME(player_id))
    end)

    menu.action(menu.player_root(player_id), "Ban Kick", {}, "Stand's Ban Kick (Discrete Kick)", function()
        menu.trigger_commands("ban"..PLAYER.GET_PLAYER_NAME(player_id))
    end)

    menu.action(menu.player_root(player_id), "Love Letter Kick", {}, "Stand's Love Letter Kick (Discrete Kick)", function()
        menu.trigger_commands("loveletterkick"..PLAYER.GET_PLAYER_NAME(player_id))
    end)

    menu.action(menu.player_root(player_id), "Steamroll Crash", {}, "Stand's Crash", function()
        menu.trigger_commands("steamroll"..PLAYER.GET_PLAYER_NAME(player_id))
    end)

    function RequestControl(entity)
        local tick = 0
        while not NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(entity) and tick < 100000 do
            util.yield()
            NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(entity)
            tick = tick + 1
        end
    end

    -------------------------------------------------------------------------------------------------------

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

    menu.action(trolling, "Cage Vehicle", {"cage"}, "", function()
        local container_hash = util.joaat("benson")
        local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)
        local pos = ENTITY.GET_ENTITY_COORDS(ped)
        request_model(container_hash)
        local container = entities.create_vehicle(container_hash, ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(ped, 0.0, 2.0, 0.0), ENTITY.GET_ENTITY_HEADING(ped))
        spawned_objects[#spawned_objects + 1] = container
        ENTITY.SET_ENTITY_VISIBLE(container, false)
        ENTITY.FREEZE_ENTITY_POSITION(container, true)
    end)

    local cage = menu.list(trolling, "Cage Player", {}, "")

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
		util.yield(0015)
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
	    util.yield(0015)
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
	    util.yield(0015)
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
	    util.yield(0015)
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
	    util.yield(0015)
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
	    util.yield(0015)
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
		util.yield(0015)
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

    menu.action(trolling, "Spawn Ramp In Front Of them", {}, "", function() 
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
        util.yield(1000)
        entities.delete_by_handle(ramp)
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

    local inf_loading = menu.list(trolling, "Infinite Loading Screen", {}, "")
    menu.action(inf_loading, "Teleport To MC", {}, "", function()
        util.trigger_script_event(1 << player_id, {891653640, player_id, 0, 32, NETWORK.NETWORK_HASH_FROM_PLAYER_HANDLE(player_id), 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0})    
    end)

    menu.action(inf_loading, "Apartament", {}, "", function()
        util.trigger_script_event(1 << player_id , {-1796714618, player_id, 0, 1, player_id})
    end)
        
    menu.action_slider(inf_loading, "Currupt", {}, "Click to select a style", invites, function(index, name)
        switch name do
            case 1:
                util.trigger_script_event(1 << player_id, {36077543, player_id, 1})
            break
            case 2:
                util.trigger_script_event(1 << player_id, {36077543, player_id, 2})
            break
            case 3:
                util.trigger_script_event(1 << player_id, {36077543, player_id, 3})
            break
            case 4:
                util.trigger_script_event(1 << player_id, {36077543, player_id, 4})
            break
            case 5:
                util.trigger_script_event(1 << player_id, {36077543, player_id, 5})
            break
            case 6:
                util.trigger_script_event(1 << player_id, {36077543, player_id, 6})
            break
        end
    end)


    local freeze = menu.list(malicious, "Freeze Methods", {}, "")

    player_toggle_loop(freeze, player_id, "Scene Freeze", {}, "Works Better Than Most Of Them.", function()
        util.trigger_script_event(1 << player_id , {330622597, player_id, 0, 0, 0, 0, 0})
    end)

    player_toggle_loop(freeze, player_id, "Scene Freeze V2", {}, "Works less than upper one.", function()
        util.trigger_script_event(1 << player_id, {-1796714618, player_id, 0, 1, 0, 0})
        util.yield(500)
    end)

    player_toggle_loop(freeze, player_id, "Event Freeze", {}, "Triggers all events.", function()
        local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)
        util.trigger_script_event(1 << player_id, {-93722397, player_id, 0, 0, 0, 0, 0})
        util.trigger_script_event(1 << player_id, {330622597, player_id, 0, 0, 0, 0, 0})
        TASK.CLEAR_PED_TASKS_IMMEDIATELY(player_id)
        util.yield(500)
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

playerposition = function(entity, distance)
	if not ENTITY.DOES_ENTITY_EXIST(entity) then
    end
	local coords = ENTITY.GET_ENTITY_FORWARD_VECTOR(entity)
	coords:mul(distance)
	coords:add(ENTITY.GET_ENTITY_COORDS(entity, true))
	return coords
end

function GetLocalPed()
    return PLAYER.PLAYER_PED_ID()
end

NetworkControl = function(entity, timeOut)
	timeOut = timeOut or 1000
	local start = util.current_time_millis()
	while not NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(entity) and
	util.current_time_millis() - start < timeOut do
		util.yield_once()
	end
	return util.current_time_millis() - start < timeOut
end

local function deletehandlers(list)
    for _, entity in pairs(list) do
        if ENTITY.DOES_ENTITY_EXIST(entity) then
            ENTITY.SET_ENTITY_AS_MISSION_ENTITY(entity, false, false)
            NetworkControl(entity)
            entities.delete_by_handle(entity)
        end
    end
end

function attach_ladder(hash, aY, aZ, a_, b0, b1, b2, b3, player_id)
    while not STREAMING.HAS_MODEL_LOADED(hash) do
        STREAMING.REQUEST_MODEL(hash)
        util.yield()
    end
    playerped3 = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)
    table_ladder[attach] = OBJECT.CREATE_OBJECT(hash, 1.55, 3.35, 0, true, true)
    ENTITY.ATTACH_ENTITY_TO_ENTITY(
        table_ladder[attach],
        playerped3,
        0,
        aY,
        aZ,
        a_,
        b0,
        b2,
        b1,
        false,
        true,
        true,
        false,
        0,
        false
    )
    ENTITY.SET_ENTITY_VISIBLE(table_ladder[attach], b3)
    STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(hash)
    attach = attach + 1
end

function RqModel(hash)
    STREAMING.REQUEST_MODEL(hash)
    local count = 0
    util.toast("Requesting model...")
    while not STREAMING.HAS_MODEL_LOADED(hash) and count < 100 do
        STREAMING.REQUEST_MODEL(hash)
        count = count + 1
        util.yield(10)
    end
    if not STREAMING.HAS_MODEL_LOADED(hash) then
        util.toast("Tried for 1 second, couldn't load this specified model!")
    end
end

    function entity_fuck(player_id)
        while true do
        for _, entity in ipairs(entities.get_all_objects_as_handles(entities.get_all_vehicles_as_handles(entities.get_all_peds_as_handles()))) do
            if ENTITY.DOES_ENTITY_EXIST(entity) and not ENTITY.IS_ENTITY_A_MISSION_ENTITY(entity) and not PED.IS_PED_A_PLAYER(NETWORK.NETWORK_GET_PLAYER_INDEX_FROM_PED(entity)) then
                local entityCoords = ENTITY.GET_ENTITY_COORDS(entity)
                local height = 100.0
                ENTITY.SET_ENTITY_COORDS_NO_OFFSET(entity, entityCoords.x + math.random(-100, 100), entityCoords.y + math.random(-100, 100), height)
                ENTITY.SET_ENTITY_VELOCITY(entity, math.random(-10, 10), math.random(-10, 10), math.random(30, 50))
                ENTITY.SET_ENTITY_MAX_SPEED(entity, 500.0)
                ENTITY.SET_ENTITY_ROTATION(entity, math.random(-180, 180), math.random(-180, 180), math.random(-180, 180), 0, 1)
                end
            end
            util.yield(1)
        end
    end

    function veh_entity_fuck(player_id)
        while true do
        for _, entity in ipairs(entities.get_all_vehicles_as_handles()) do
            if ENTITY.DOES_ENTITY_EXIST(entity) and not ENTITY.IS_ENTITY_A_MISSION_ENTITY(entity) and not PED.IS_PED_A_PLAYER(NETWORK.NETWORK_GET_PLAYER_INDEX_FROM_PED(entity)) then
                local entityCoords = ENTITY.GET_ENTITY_COORDS(entity)
                local height = 100.0
                ENTITY.SET_ENTITY_COORDS_NO_OFFSET(entity, entityCoords.x, entityCoords.y, height)
                ENTITY.SET_ENTITY_VELOCITY(entity, math.random(-10, 10), math.random(-10, 10), math.random(30, 50))
                ENTITY.SET_ENTITY_MAX_SPEED(entity, 500.0)
                ENTITY.SET_ENTITY_ROTATION(entity, math.random(-180, 180), math.random(-180, 180), math.random(-180, 180), 0, 1)
                end
            end
            util.yield(1)
        end
    end

    function veh_entity_fly(player_id)
        while true do
        for _, entity in ipairs(entities.get_all_vehicles_as_handles()) do
            if ENTITY.DOES_ENTITY_EXIST(entity) and not ENTITY.IS_ENTITY_A_MISSION_ENTITY(entity) and not PED.IS_PED_A_PLAYER(NETWORK.NETWORK_GET_PLAYER_INDEX_FROM_PED(entity)) then
                local entityCoords = ENTITY.GET_ENTITY_COORDS(entity)
                local holecoords = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id), true)
                vcoords = ENTITY.GET_ENTITY_COORDS(veh, true)
                speed = 100
                local x_vec = (holecoords['x']-vcoords['x'])*speed
                local y_vec = (holecoords['y']-vcoords['y'])*speed
                local z_vec = ((holecoords['z']+hole_zoff)-vcoords['z'])*speed
                ENTITY.SET_ENTITY_VELOCITY(entity, math.random(-10, 10), math.random(-10, 10), math.random(30, 50))
                ENTITY.SET_ENTITY_MAX_SPEED(entity, 500.0)
                ENTITY.SET_ENTITY_ROTATION(entity, math.random(-180, 180), math.random(-180, 180), math.random(-180, 180), 0, 1)
                end
            end
            util.yield(1)
        end
    end

    function obj_entity_fuck(player_id)
        while true do
        for _, entity in ipairs(entities.get_all_objects_as_handles()) do
            if ENTITY.DOES_ENTITY_EXIST(entity) and not ENTITY.IS_ENTITY_A_MISSION_ENTITY(entity) and not PED.IS_PED_A_PLAYER(NETWORK.NETWORK_GET_PLAYER_INDEX_FROM_PED(entity)) then
                local entityCoords = ENTITY.GET_ENTITY_COORDS(entity)
                local height = 100.0
                ENTITY.SET_ENTITY_COORDS_NO_OFFSET(entity, entityCoords.x, entityCoords.y, height)
                ENTITY.SET_ENTITY_VELOCITY(entity, math.random(-10, 10), math.random(-10, 10), math.random(30, 50))
                ENTITY.SET_ENTITY_MAX_SPEED(entity, 500.0)
                ENTITY.SET_ENTITY_ROTATION(entity, math.random(-180, 180), math.random(-180, 180), math.random(-180, 180), 0, 1)
                end
            end
            util.yield(1)
        end
    end

    function ped_entity_fuck(player_id)
        while true do
        for _, entity in ipairs(entities.get_all_peds_as_handles()) do
            if ENTITY.DOES_ENTITY_EXIST(entity) and not ENTITY.IS_ENTITY_A_MISSION_ENTITY(entity) and not PED.IS_PED_A_PLAYER(NETWORK.NETWORK_GET_PLAYER_INDEX_FROM_PED(entity)) then
                local entityCoords = ENTITY.GET_ENTITY_COORDS(entity)
                local height = 100.0
                ENTITY.SET_ENTITY_COORDS_NO_OFFSET(entity, entityCoords.x + math.random(-100, 100), entityCoords.y + math.random(-100, 100), height)
                ENTITY.SET_ENTITY_VELOCITY(entity, math.random(-10, 10), math.random(-10, 10), math.random(30, 50))
                ENTITY.SET_ENTITY_MAX_SPEED(entity, 500.0)
                ENTITY.SET_ENTITY_ROTATION(entity, math.random(-180, 180), math.random(-180, 180), math.random(-180, 180), 0, 1)
                end
            end
            util.yield(1)
        end
    end

    function pickup_entity_fuck(player_id)
        while true do
        for _, entity in ipairs(entities.get_all_pickups_as_handles()) do
            if ENTITY.DOES_ENTITY_EXIST(entity) and not ENTITY.IS_ENTITY_A_MISSION_ENTITY(entity) and not PED.IS_PED_A_PLAYER(NETWORK.NETWORK_GET_PLAYER_INDEX_FROM_PED(entity)) then
                local entityCoords = ENTITY.GET_ENTITY_COORDS(entity)
                local height = 100.0
                ENTITY.SET_ENTITY_COORDS_NO_OFFSET(entity, entityCoords.x + math.random(-100, 100), entityCoords.y + math.random(-100, 100), height)
                ENTITY.SET_ENTITY_VELOCITY(entity, math.random(-10, 10), math.random(-10, 10), math.random(30, 50))
                ENTITY.SET_ENTITY_MAX_SPEED(entity, 500.0)
                ENTITY.SET_ENTITY_ROTATION(entity, math.random(-180, 180), math.random(-180, 180), math.random(-180, 180), 0, 1)
                end
            end
            util.yield(1)
        end
    end

    function Push_Player_Up(player_id)
        local TargetPlayerPed = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)
        local Target = ENTITY.GET_ENTITY_COORDS(TargetPlayerPed, true)
        local hydra_req = util.joaat("freigh")
        local cargo_req = util.joaat("metrotrain")
        for i = 1, 10 do
        request_model(hydra_req)
        request_model(cargo_req)
        local hydra = entities.create_vehicle(hydra_req, Target, 0.0)
        local cargoplane = entities.create_vehicle(cargo_req, Target, 0.0)
        ENTITY.SET_ENTITY_VISIBLE(hydra, false, 0)
        ENTITY.SET_ENTITY_VISIBLE(cargoplane, false, 0)
        ENTITY.SET_ENTITY_AS_MISSION_ENTITY(hydra, true, true)
        ENTITY.SET_ENTITY_AS_MISSION_ENTITY(cargoplane, true, true)
        ENTITY.SET_ENTITY_COORDS_NO_OFFSET(cargoplane, Target.x + math.random(-3000, 3000), Target.y + math.random(-3000, 3000), Target.z + math.random(-3000, 3000))
        ENTITY.SET_ENTITY_COORDS_NO_OFFSET(hydra, Target.x + math.random(-3000, 3000), Target.y + math.random(-3000, 3000), Target.z + math.random(-3000, 3000))
        ENTITY.ATTACH_ENTITY_TO_ENTITY(cargoplane, hydra, -1, 0.0, 0.0, 20.0, 0.0, 0.0, 0.0, false, false, false, false, 0, true)
        ENTITY.SET_ENTITY_ROTATION(cargoplane, math.random(0, 360), math.random(0, 360), math.random(0, 360), 0, true)
        ENTITY.SET_ENTITY_ROTATION(hydra, math.random(0, 360), math.random(0, 360), math.random(0, 360), 0, true)
        ENTITY.SET_ENTITY_VELOCITY(cargoplane, math.random(-10, 10), math.random(-10, 10), math.random(30, 50))
        ENTITY.SET_ENTITY_VELOCITY(hydra, math.random(-10, 10), math.random(-10, 10), math.random(30, 50))
        end
    end

    local useforce = {
        184361638,
        1890640474,
        868868440,
    }

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

menu.action(crashes, "FewMod All In One", {"FewModLobbyCrash"}, "Uses Multiple Crashes In The Menu", function()
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
    menu.trigger_commands("E1CrashEvent" .. PLAYER.GET_PLAYER_NAME(player_id))
    util.yield(23000)
    util.toast("Done E1 Crash Event")
    util.log("Done E1 Crash Event")
    menu.trigger_commands("BigChunxusCrash" .. PLAYER.GET_PLAYER_NAME(player_id))
    util.yield(20000)
    util.toast("Done Big Chunxus Crash")
    util.log("Done Big Chunxus Crash")
    menu.trigger_commands("clearworld")
    menu.trigger_commands("da2T1Crash" .. PLAYER.GET_PLAYER_NAME(player_id))
    util.toast("Done 2T1 Crash")
    util.log("Done 2T1 Crash")
    menu.trigger_commands("weededcrash" .. PLAYER.GET_PLAYER_NAME(player_id))
    util.toast("Done Weed Crash")
    util.log("Done Weed Crash")
    menu.trigger_commands("Yachtyv4" .. PLAYER.GET_PLAYER_NAME(player_id))
    util.yield(10000)
    util.toast("Done Yacht Crash v4")
    util.log("Done Yacht Crash v4")
    menu.trigger_commands("Yachtyv5" .. PLAYER.GET_PLAYER_NAME(player_id))
    util.yield(10000)
    util.toast("Done Yacht Crash v5")
    util.log("Done Yacht Crash v5")
    menu.trigger_commands("musclecrash" .. PLAYER.GET_PLAYER_NAME(player_id))
    util.yield(10000)
    util.toast("Done Muscle Crash")
    util.log("Done Muscle Crash")
    menu.trigger_commands("daoutfitcrashv1" .. PLAYER.GET_PLAYER_NAME(player_id))
    util.yield(10000)
    util.toast("Done Outfit Crash")
    util.log("Done Outfit Crash")
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
    menu.trigger_commands("crashv78" .. PLAYER.GET_PLAYER_NAME(player_id))
    util.yield(15000)
    util.toast("Done Sync Crash v2")
    util.log("Done Sync Crash v2")
    menu.trigger_commands("crashv79" .. PLAYER.GET_PLAYER_NAME(player_id))
    util.yield(10000)
    util.toast("Done Sync Crash v3")
    util.log("Done Sync Crash v3")
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

menu.divider(crashes, "Fragment Crashes")

menu.toggle_loop(crashes, "Fragment Crash V1", {"FragmentCrashv1"}, "Skidded From 2take1", function(on_toggle)
                if player_id ~= players.user() then
                        local object = entities.create_object(util.joaat("prop_fragtest_cnst_04"), ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)))
                        OBJECT.BREAK_OBJECT_FRAGMENT_CHILD(object, 1, false)
                        entities.delete_by_handle(object)
                        local object = entities.create_object(util.joaat("prop_fragtest_cnst_04"), ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)))
                        OBJECT.BREAK_OBJECT_FRAGMENT_CHILD(object, 1, false)
                        entities.delete_by_handle(object)
                        local object = entities.create_object(util.joaat("prop_fragtest_cnst_04"), ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)))
                        OBJECT.BREAK_OBJECT_FRAGMENT_CHILD(object, 1, false)
                        entities.delete_by_handle(object)
                        local object = entities.create_object(util.joaat("prop_fragtest_cnst_04"), ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)))
                        OBJECT.BREAK_OBJECT_FRAGMENT_CHILD(object, 1, false)
                        entities.delete_by_handle(object)
                        local object = entities.create_object(util.joaat("prop_fragtest_cnst_04"), ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)))
                        OBJECT.BREAK_OBJECT_FRAGMENT_CHILD(object, 1, false)
                        entities.delete_by_handle(object)
                        local object = entities.create_object(util.joaat("prop_fragtest_cnst_04"), ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)))
                        OBJECT.BREAK_OBJECT_FRAGMENT_CHILD(object, 1, false)
                        entities.delete_by_handle(object)
                        local object = entities.create_object(util.joaat("prop_fragtest_cnst_04"), ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)))
                        OBJECT.BREAK_OBJECT_FRAGMENT_CHILD(object, 1, false)
                        entities.delete_by_handle(object)
                        local object = entities.create_object(util.joaat("prop_fragtest_cnst_04"), ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)))
                        OBJECT.BREAK_OBJECT_FRAGMENT_CHILD(object, 1, false)
                        entities.delete_by_handle(object)
                        local object = entities.create_object(util.joaat("prop_fragtest_cnst_04"), ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)))
                        OBJECT.BREAK_OBJECT_FRAGMENT_CHILD(object, 1, false)
                        entities.delete_by_handle(object)
                        local object = entities.create_object(util.joaat("prop_fragtest_cnst_04"), ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)))
                        OBJECT.BREAK_OBJECT_FRAGMENT_CHILD(object, 1, false)
                        util.yield(1000)
                        entities.delete_by_handle(object)
                    end
                end)

                menu.toggle_loop(crashes, "Fragment Crash V2", {"fragmentv2"}, "", function(on_toggle)
                    if player_id ~= players.user() then
                    local TargetPlayerPed = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)
                    local TargetPlayerPos = ENTITY.GET_ENTITY_COORDS(TargetPlayerPed, true)
                    local Object_pizza2 = entities.create_object(util.joaat("prop_fragtest_cnst_04"), ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)))
                        OBJECT.BREAK_OBJECT_FRAGMENT_CHILD(object, 1, false)
                    local Object_pizza2 = entities.create_object(util.joaat("prop_fragtest_cnst_04"), ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)))
                        OBJECT.BREAK_OBJECT_FRAGMENT_CHILD(object, 1, false)
                    local Object_pizza2 = entities.create_object(util.joaat("prop_fragtest_cnst_04"), ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)))
                        OBJECT.BREAK_OBJECT_FRAGMENT_CHILD(object, 1, false)
                    local Object_pizza2 = entities.create_object(util.joaat("prop_fragtest_cnst_04"), ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)))
                        OBJECT.BREAK_OBJECT_FRAGMENT_CHILD(object, 1, false)
                    for i = 0, 100 do 
                        local TargetPlayerPos = ENTITY.GET_ENTITY_COORDS(TargetPlayerPed, true);
                        ENTITY.SET_ENTITY_COORDS_NO_OFFSET(Object_pizza2, TargetPlayerPos.x, TargetPlayerPos.y, TargetPlayerPos.z, false, true, true)
                        ENTITY.SET_ENTITY_COORDS_NO_OFFSET(Object_pizza2, TargetPlayerPos.x, TargetPlayerPos.y, TargetPlayerPos.z, false, true, true)
                        ENTITY.SET_ENTITY_COORDS_NO_OFFSET(Object_pizza2, TargetPlayerPos.x, TargetPlayerPos.y, TargetPlayerPos.z, false, true, true)
                        ENTITY.SET_ENTITY_COORDS_NO_OFFSET(Object_pizza2, TargetPlayerPos.x, TargetPlayerPos.y, TargetPlayerPos.z, false, true, true)
                    util.yield(10)
                    entities.delete_by_handle(Object_pizza2)
                    entities.delete_by_handle(Object_pizza2)
                    entities.delete_by_handle(Object_pizza2)
                    entities.delete_by_handle(Object_pizza2)
                    return
                    end
                end
            end)

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
	
    menu.divider(crashes, "Other Crashes")

    menu.action(crashes, "Script Crash", {}, "", function(on_toggle)
        menu.trigger_commands("scripthost")
        util.yield(25)
        menu.trigger_commands("givesh" .. players.get_name(player_id))
        util.power_crash(player_id)
    end)

    local modelc = menu.list(crashes, "Model Crashes", {}, "")


    menu.action(modelc, "FragText", {"FragTestCrashv2"}, "", function()
        Fewd.BlockSyncs(player_id, function()
            local object = entities.create_object(util.joaat("prop_fragtest_cnst_04"), ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)))
            OBJECT.BREAK_OBJECT_FRAGMENT_CHILD(object, 1, false)
            util.yield(1000)
            entities.delete_by_handle(object)
        end)
    end)

    menu.action(modelc, "FragTest X10", {"FragTestCrashv3"}, "", function()
        Fewd.BlockSyncs(player_id, function()
            local object = entities.create_object(util.joaat("prop_fragtest_cnst_04"), ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)))
            OBJECT.BREAK_OBJECT_FRAGMENT_CHILD(object, 1, false)
            entities.delete_by_handle(object)
            local object = entities.create_object(util.joaat("prop_fragtest_cnst_04"), ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)))
            OBJECT.BREAK_OBJECT_FRAGMENT_CHILD(object, 1, false)
            entities.delete_by_handle(object)
            local object = entities.create_object(util.joaat("prop_fragtest_cnst_04"), ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)))
            OBJECT.BREAK_OBJECT_FRAGMENT_CHILD(object, 1, false)
            entities.delete_by_handle(object)
            local object = entities.create_object(util.joaat("prop_fragtest_cnst_04"), ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)))
            OBJECT.BREAK_OBJECT_FRAGMENT_CHILD(object, 1, false)
            entities.delete_by_handle(object)
            local object = entities.create_object(util.joaat("prop_fragtest_cnst_04"), ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)))
            OBJECT.BREAK_OBJECT_FRAGMENT_CHILD(object, 1, false)
            entities.delete_by_handle(object)
            local object = entities.create_object(util.joaat("prop_fragtest_cnst_04"), ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)))
            OBJECT.BREAK_OBJECT_FRAGMENT_CHILD(object, 1, false)
            entities.delete_by_handle(object)
            local object = entities.create_object(util.joaat("prop_fragtest_cnst_04"), ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)))
            OBJECT.BREAK_OBJECT_FRAGMENT_CHILD(object, 1, false)
            entities.delete_by_handle(object)
            local object = entities.create_object(util.joaat("prop_fragtest_cnst_04"), ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)))
            OBJECT.BREAK_OBJECT_FRAGMENT_CHILD(object, 1, false)
            entities.delete_by_handle(object)
            local object = entities.create_object(util.joaat("prop_fragtest_cnst_04"), ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)))
            OBJECT.BREAK_OBJECT_FRAGMENT_CHILD(object, 1, false)
            entities.delete_by_handle(object)
            local object = entities.create_object(util.joaat("prop_fragtest_cnst_04"), ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)))
            OBJECT.BREAK_OBJECT_FRAGMENT_CHILD(object, 1, false)
            util.yield(1000)
            entities.delete_by_handle(object)
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
                                if not players.exists(player_id) then
                                        return
                                end
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
    menu.action(modelc, "E1CrashEvent", {"E1CrashEvent"}, "Skid from x-force", function()
        local int_min = -2147483647
        local int_max = 2147483647
            for i = 1, 15 do
            util.trigger_script_event(1 << player_id, {-555356783, 3, 85952, 99999, 1142667203, 526822745, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0})
            end
            util.yield()
            for i = 1, 15 do
            util.trigger_script_event(1 << player_id, {-555356783, 3, 85952, 99999, 1142667203, 526822745, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0})
            end
            util.trigger_script_event(1 << player_id, {-555356783, 3, 85952, 99999, 1142667203, 526822745, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0})
    end)
    menu.action(modelc, "Event 2", {"E2Crash"}, "Skid from x-force", function()
        local int_min = -2147483647
        local int_max = 2147483647
            for i = 1, 15 do
            util.trigger_script_event(1 << player_id, {-555356783, 3, 420, 69, 1337, 88, 360, 666, 6969, 696969, math.random(int_min, int_max), math.random(int_min, int_max),
            math.random(int_min, int_max), math.random(int_min, int_max), math.random(int_min, int_max), math.random(int_min, int_max),
            math.random(int_min, int_max), player_id, math.random(int_min, int_max), math.random(int_min, int_max), math.random(int_min, int_max)})
            util.trigger_script_event(1 << player_id, {-555356783, 3, 420, 69, 1337, 88, 360, 666, 6969, 696969})
            end
            util.yield()
            for i = 1, 15 do
            util.trigger_script_event(1 << player_id, {-555356783, 3, 420, 69, 1337, 88, 360, 666, 6969, 696969, player_id, math.random(int_min, int_max)})
            util.trigger_script_event(1 << player_id, {-555356783, 3, 420, 69, 1337, 88, 360, 666, 6969, 696969})
            end
            util.trigger_script_event(1 << player_id, {-555356783, 3, 420, 69, 1337, 88, 360, 666, 6969, 696969})
    end)

    local pclpid = {}

    menu.action(modelc, "XC Crash (Clones Crash)", {"XCCrash"}, "Clones the player causing (XC)", function()
        local p = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)
        local c = ENTITY.GET_ENTITY_COORDS(p)
        for i = 1, 25 do
            local pclone = entities.create_ped(26, ENTITY.GET_ENTITY_MODEL(p), c, 0)
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

    menu.action(modelc, "Big Chunxus Cwash'", {"BigChunxusCrash"}, "Skid from x-force (Big CHUNGUS)", function()
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
	
    -- This is a Prisuhm crash fixed by idk who, edited by me
	
	    local krustykrab = menu.list(crashes, "Crusty Crab Crash", {"CrustyCrabCrash"}, "It's risky to spectate, beware: it works on 2T1 users")

    local peds = 5
    menu.slider(krustykrab, "Number of spatulas", {}, "Send spatulas ah~", 1, 50, 1, 1, function(amount)
        util.toast(players.get_name(player_id).. " Spatulas have been sen")
        peds = amount
    end)

    local crash_ents = {}
    local crash_toggle = false
    menu.toggle(krustykrab, "Number of spatulas", {"SpatalusCrash"}, "It's risky to spectate, beware.", function(val)
        menu.trigger_commands("anticrashcamera on")
        util.toast(players.get_name(player_id).. " Spatulas have been sen")
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
            menu.trigger_commands("anticrashcamera off")
        end)
    end)

    local nmcrashes = menu.list(crashes, "Normal Model Crashes", {}, "")

    menu.action(nmcrashes, "Yatchy V1", {"Yachtyv1"}, "Crash event (A1:EA0FF6AD) sending prop yacht.", function()
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
    
    menu.action(nmcrashes, "Yatchy V2", {"Yachtyv2"}, "Crash event (A1:E8958704) sending prop yacht001.", function()
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
    
    menu.action(nmcrashes, "Yatchy V3", {"YachtCv3"}, "Crash event (A1:1A7AEACE) sending prop yacht002.", function()
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
    
    menu.action(nmcrashes, "Yatchy V4", {"Yachtyv4"}, "Crash event (A1:408D3AA0) sending prop apayacht.", function()
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
    
    menu.action(nmcrashes, "Yatchy V5", {"Yachtyv5"}, "Crash event (A1:B36122B5) sending prop yachtwin.", function()
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

    menu.action(crashes, "2T1Crash", {"da2T1Crash"}, "", function()
        Fewd.BlockSyncs(player_id, function()
            local object = entities.create_object(util.joaat("prop_fragtest_cnst_04"), ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)))
            OBJECT.BREAK_OBJECT_FRAGMENT_CHILD(object, 1, false)
            util.yield(1000)
            entities.delete_by_handle(object)
        end)
    end)

   menu.action(crashes, "Unblockable V4", {"YachtCrash"}, "It should be fixed, for now", function()
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

menu.divider(crashes, "Rope Crashes")

    menu.action(crashes, "Rope Crash Silent", {"silentropecrash"}, "", function(on_loop)
        PHYSICS.ROPE_LOAD_TEXTURES()
        local hashes = {2132890591, 2727244247}
        local pc = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id))
        local veh = VEHICLE.CREATE_VEHICLE(hashes[i], pc.x + 5, pc.y, pc.z, 0, true, true, false)
        Utillitruck3_pos = ENTITY.GET_ENTITY_COORDS(veh)
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
        entities.delete_by_handle(veh); entities.delete_by_handle(ped)
        PHYSICS.DELETE_CHILD_ROPE(rope)
        PHYSICS.ROPE_UNLOAD_TEXTURES()
    end)
	
menu.divider(crashes, "Parachute Crashes")

	menu.toggle(crashes, "Para Crash", {"ParaCrash"}, "Will Automatically Restart Script After", function(on)
        if on then
		for n = 0 , 1 do
			PEDP = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(PLAYER.PLAYER_ID())
				object_hash = 1043035044
					STREAMING.REQUEST_MODEL(object_hash)
				while not STREAMING.HAS_MODEL_LOADED(object_hash) do
					util.yield()
					end
					PLAYER.SET_PLAYER_PARACHUTE_MODEL_OVERRIDE(PLAYER.PLAYER_ID(),object_hash)
                    ENTITY.SET_ENTITY_COORDS_NO_OFFSET(PEDP, 0,0,500, 0, 0, 1) -- Original Code
					WEAPON.GIVE_DELAYED_WEAPON_TO_PED(PEDP, 0xFBAB5776, 1000, false)
					util.yield(1000)
				for i = 0 , 1 do
					PED.FORCE_PED_TO_OPEN_PARACHUTE(PEDP)
					end
					util.yield(1000)
					menu.trigger_commands("tplsia")
				bush_hash = 1585741317
					STREAMING.REQUEST_MODEL(bush_hash)
				while not STREAMING.HAS_MODEL_LOADED(bush_hash) do
					util.yield()
					end
					PLAYER.SET_PLAYER_PARACHUTE_MODEL_OVERRIDE(PLAYER.PLAYER_ID(),bush_hash)
                    ENTITY.SET_ENTITY_COORDS_NO_OFFSET(PEDP, 0,0,500, 0, 0, 1) -- Original Code
					WEAPON.GIVE_DELAYED_WEAPON_TO_PED(PEDP, 0xFBAB5776, 1000, false)
					util.yield(1000)
				for i = 0 , 1 do
					PED.FORCE_PED_TO_OPEN_PARACHUTE(PEDP)
					end
					util.yield(1000)
					menu.trigger_commands("tplsia")
                    end
                else
                    menu.trigger_commands("tpmazehelipad")
                    util.restart_script()
                end
			end)

    -- Parachute Crash 1

	menu.toggle(crashes, "Para Crash V1", {"paracrashv1"}, "Will Automatically Restart Script After", function(on)
        if on then
		for n = 0 , 5 do
			PEDP = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(PLAYER.PLAYER_ID())
            heli_hash = util.joaat("p_crahsed_heli_s")
					STREAMING.REQUEST_MODEL(heli_hash)
				while not STREAMING.HAS_MODEL_LOADED(heli_hash) do
					util.yield()
					end
					PLAYER.SET_PLAYER_PARACHUTE_MODEL_OVERRIDE(PLAYER.PLAYER_ID(),heli_hash)
                    ENTITY.SET_ENTITY_COORDS_NO_OFFSET(PEDP, math.random(0, 2555), math.random(0, 2815), math.random(1, 1232), false, false, false) 
                    --ENTITY.SET_ENTITY_COORDS_NO_OFFSET(PEDP, 0,0,500, 0, 0, 1) -- Original Code
					WEAPON.GIVE_DELAYED_WEAPON_TO_PED(PEDP, 0xFBAB5776, 1000, false)
					util.yield(1000)
				for i = 0 , 20 do
					PED.FORCE_PED_TO_OPEN_PARACHUTE(PEDP)
					end
					util.yield(1000)
					menu.trigger_commands("tplsia")
				post_hash = util.joaat("prop_traffic_01a")
					STREAMING.REQUEST_MODEL(post_hash)
				while not STREAMING.HAS_MODEL_LOADED(post_hash) do
					util.yield()
					end
					PLAYER.SET_PLAYER_PARACHUTE_MODEL_OVERRIDE(PLAYER.PLAYER_ID(),post_hash)
                    ENTITY.SET_ENTITY_COORDS_NO_OFFSET(PEDP, math.random(0, 2555), math.random(0, 2815), math.random(1, 1232), false, false, false) 
                    --ENTITY.SET_ENTITY_COORDS_NO_OFFSET(PEDP, 0,0,500, 0, 0, 1) -- Original Code
					WEAPON.GIVE_DELAYED_WEAPON_TO_PED(PEDP, 0xFBAB5776, 1000, false)
					util.yield(1000)
				for i = 0 , 20 do
					PED.FORCE_PED_TO_OPEN_PARACHUTE(PEDP)
					end
					util.yield(1000)
					menu.trigger_commands("tplsia")

                    flag_hash = util.joaat("prop_beachflag_02")
					STREAMING.REQUEST_MODEL(flag_hash)
				while not STREAMING.HAS_MODEL_LOADED(flag_hash) do
					util.yield()
					end
					PLAYER.SET_PLAYER_PARACHUTE_MODEL_OVERRIDE(PLAYER.PLAYER_ID(),flag_hash)
                    ENTITY.SET_ENTITY_COORDS_NO_OFFSET(PEDP, math.random(0, 3000), math.random(0, 3000), math.random(0, 3000), false, false, false) 
                    --ENTITY.SET_ENTITY_COORDS_NO_OFFSET(PEDP, 0,0,500, 0, 0, 1) -- Original Code
					WEAPON.GIVE_DELAYED_WEAPON_TO_PED(PEDP, 0xFBAB5776, 1000, false)
					util.yield(1000)
				for i = 0 , 20 do
					PED.FORCE_PED_TO_OPEN_PARACHUTE(PEDP)
					end
					util.yield(1000)
					menu.trigger_commands("tplsia")
                    end
                else
                    menu.trigger_commands("tpmazehelipad")
                    util.restart_script()
                end
			end)

        -- Parachute Crash 2
                
menu.toggle_loop(crashes, "Para Crash V2", {"paracrashv2"}, "", function()
    local pos = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id))
    local player = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)
    Fewd.BlockSyncs(player_id, function()
        util.yield(500)

        local crash_parachute = util.joaat("prop_logpile_06b")
        local parachute = util.joaat("p_parachute1_mp_dec")

        STREAMING.REQUEST_MODEL(crash_parachute)
        STREAMING.REQUEST_MODEL(parachute)

        for i = 1, 1 do
            PLAYER.SET_PLAYER_PARACHUTE_MODEL_OVERRIDE(player_id, crash_parachute)
            WEAPON.GIVE_DELAYED_WEAPON_TO_PED(player, 0xFBAB5776, 1000, false)
            ENTITY.SET_ENTITY_COORDS_NO_OFFSET(player, pos.x, pos.y, pos.z + 100, 0, 0, 1)
            util.yield(1000)
            PED.FORCE_PED_TO_OPEN_PARACHUTE(player)
            util.yield(1000)
            TASK.CLEAR_PED_TASKS_IMMEDIATELY(player)
        end

        PLAYER.SET_PLAYER_PARACHUTE_MODEL_OVERRIDE(player_id, parachute)
        util.yield(500)
    end)
end)
                

menu.toggle_loop(crashes, "Para Crash V3", {"paracrashv3"}, "", function()
    local ped = PLAYER.PLAYER_PED_ID()
    local pos = ENTITY.GET_ENTITY_COORDS(ped, true)
    local hashes = {util.joaat("prop_beach_parasol_02"), util.joaat("prop_parasol_04c")}
    for i = 1, #hashes do
        RqModel(hashes[i])
        PLAYER.SET_PLAYER_PARACHUTE_MODEL_OVERRIDE(player_id, hashes[i])
        ENTITY.SET_ENTITY_COORDS_NO_OFFSET(ped, 0, 0, 500, false, true, true)
        WEAPON.GIVE_DELAYED_WEAPON_TO_PED(ped, 0xFBAB5776, 1000, false)
        util.yield(200)
        for i = 0 , 20 do
            PED.FORCE_PED_TO_OPEN_PARACHUTE(ped)
        end
        util.yield(1200)
    end
    ENTITY.SET_ENTITY_COORDS_NO_OFFSET(ped, pos.x, pos.y, pos.z, false, true, true)
end)

menu.divider(crashes, "Item Crashes")

      menu.toggle(crashes, "All Scenario Crashes", {"togglescenariocrashes"}, "It's risky to spectate using this but your call", function(on_toggle)
        if on_toggle then
            util.yield()
            menu.trigger_commands("anticrashcamera")
            util.yield()
            menu.trigger_commands("bongoguitarscrash" .. PLAYER.GET_PLAYER_NAME(player_id))
            util.yield(200)
            menu.trigger_commands("cigarscrash" .. PLAYER.GET_PLAYER_NAME(player_id))
            util.yield(200)
            menu.trigger_commands("spatularcrash" .. PLAYER.GET_PLAYER_NAME(player_id))
            util.yield(200)
            menu.trigger_commands("barbellcrash" .. PLAYER.GET_PLAYER_NAME(player_id))
            util.yield(200)
            menu.trigger_commands("hammercrash" .. PLAYER.GET_PLAYER_NAME(player_id))
            util.yield(200)
            menu.trigger_commands("fishingcrash" .. PLAYER.GET_PLAYER_NAME(player_id))
            util.yield(200)
            menu.trigger_commands("jackhammercrash" .. PLAYER.GET_PLAYER_NAME(player_id))
            util.yield(200)
            menu.trigger_commands("broomcrash" .. PLAYER.GET_PLAYER_NAME(player_id))
            util.yield(200)
            menu.trigger_commands("drunkcrash" .. PLAYER.GET_PLAYER_NAME(player_id))
            util.yield(200)
            menu.trigger_commands("trowelcrash" .. PLAYER.GET_PLAYER_NAME(player_id))
            util.yield(200)
            menu.trigger_commands("wincleancrash" .. PLAYER.GET_PLAYER_NAME(player_id))
            util.yield(200)
            menu.trigger_commands("torchcrash" .. PLAYER.GET_PLAYER_NAME(player_id))
            util.yield(200)
            menu.trigger_commands("coffeecrash" .. PLAYER.GET_PLAYER_NAME(player_id))
            util.yield(200)
        else
            util.yield()
            menu.trigger_commands("bongoguitarscrash" .. PLAYER.GET_PLAYER_NAME(player_id))
            util.yield(200)
            menu.trigger_commands("cigarscrash" .. PLAYER.GET_PLAYER_NAME(player_id))
            util.yield(200)
            menu.trigger_commands("spatularcrash" .. PLAYER.GET_PLAYER_NAME(player_id))
            util.yield(200)
            menu.trigger_commands("barbellcrash" .. PLAYER.GET_PLAYER_NAME(player_id))
            util.yield(200)
            menu.trigger_commands("hammercrash" .. PLAYER.GET_PLAYER_NAME(player_id))
            util.yield(200)
            menu.trigger_commands("fishingcrash" .. PLAYER.GET_PLAYER_NAME(player_id))
            util.yield(200)
            menu.trigger_commands("jackhammercrash" .. PLAYER.GET_PLAYER_NAME(player_id))
            util.yield(200)
            menu.trigger_commands("broomcrash" .. PLAYER.GET_PLAYER_NAME(player_id))
            util.yield(200)
            menu.trigger_commands("drunkcrash" .. PLAYER.GET_PLAYER_NAME(player_id))
            util.yield(200)
            menu.trigger_commands("trowelcrash" .. PLAYER.GET_PLAYER_NAME(player_id))
            util.yield(200)
            menu.trigger_commands("wincleancrash" .. PLAYER.GET_PLAYER_NAME(player_id))
            util.yield(200)
            menu.trigger_commands("torchcrash" .. PLAYER.GET_PLAYER_NAME(player_id))
            util.yield(200)
            menu.trigger_commands("coffeecrash" .. PLAYER.GET_PLAYER_NAME(player_id))
            util.yield(200)
            menu.trigger_commands("noentities")
            util.yield(200)
            menu.trigger_commands("noentities")
            util.yield()
            menu.trigger_commands("anticrashcamera")
            end
        end)

        menu.divider(crashes, "_________________________________________")

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

function deletehandlers(list)
    for _, entity in pairs(list) do
        if ENTITY.DOES_ENTITY_EXIST(entity) then
            ENTITY.SET_ENTITY_AS_MISSION_ENTITY(entity, false, false)
            NetworkControl(entity)
            entities.delete_by_handle(entity)
        end
    end
end

function RqModel(hash)
    STREAMING.REQUEST_MODEL(hash)
    local count = 0
    util.toast("Requesting model...")
    while not STREAMING.HAS_MODEL_LOADED(hash) and count < 100 do
        STREAMING.REQUEST_MODEL(hash)
        count = count + 1
        util.yield(10)
    end
    if not STREAMING.HAS_MODEL_LOADED(hash) then
        util.toast("Tried for 1 second, couldn't load this specified model!")
    end
end

function GetLocalPed()
    return PLAYER.PLAYER_PED_ID()
end

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
-----------------------------------------------------------------------------------------------------------
local Cheraxcrash = menu.list(crashes, "Cherax Crashes", {}, "")

menu.action(Cheraxcrash,"Cherax Crash", {"dacheraxcrash"}, "Working.", function()
    menu.trigger_commands("choke" .. PLAYER.GET_PLAYER_NAME(player_id))
    menu.trigger_commands("flashcrash" .. PLAYER.GET_PLAYER_NAME(player_id))
    menu.trigger_commands("choke" .. PLAYER.GET_PLAYER_NAME(player_id))
    menu.trigger_commands("flashcrash" .. PLAYER.GET_PLAYER_NAME(player_id))
    util.yield()
    util.toast("Cherax Crash Sent to " .. PLAYER.GET_PLAYER_NAME(player_id))
    util.log("Cherax Crash Sent to " .. PLAYER.GET_PLAYER_NAME(player_id))
end, nil, nil, COMMANDPERM_AGGRESSIVE)

menu.toggle_loop(Cheraxcrash,"Cherax Crash", {"cheraxcrash"}, "Working.", function()
    if player_id ~= players.user() then
    menu.trigger_commands("choke" .. PLAYER.GET_PLAYER_NAME(player_id))
    menu.trigger_commands("flashcrash" .. PLAYER.GET_PLAYER_NAME(player_id))
    menu.trigger_commands("choke" .. PLAYER.GET_PLAYER_NAME(player_id))
    menu.trigger_commands("flashcrash" .. PLAYER.GET_PLAYER_NAME(player_id))
    util.yield()
    util.toast("Cherax Crash Sent to " .. PLAYER.GET_PLAYER_NAME(player_id))
    util.log("Cherax Crash Sent to " .. PLAYER.GET_PLAYER_NAME(player_id))
    end
end)
-----------------------------------------------------------------------------------------------------------
local Northcrash = menu.list(crashes, "North Crashes", {}, "")

menu.action(Northcrash,"North Crash", {"danorthcrash"}, "Working.", function()
    local pos = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id))
    local michael = util.joaat("player_zero")
    while not STREAMING.HAS_MODEL_LOADED(michael) do
        STREAMING.REQUEST_MODEL(michael)
        util.yield()
    end
    local ped = entities.create_ped(0, michael, pos, 0)
    PED.SET_PED_COMPONENT_VARIATION(ped, 0, 0, 6, 0)
    PED.SET_PED_COMPONENT_VARIATION(ped, 0, 0, 7, 0)
    util.yield()
    util.yield(500)
    entities.delete_by_handle(ped)
    util.toast("North Crash Sent to " .. PLAYER.GET_PLAYER_NAME(player_id))
    util.log("North Crash Sent to " .. PLAYER.GET_PLAYER_NAME(player_id))
end, nil, nil, COMMANDPERM_AGGRESSIVE)

menu.toggle_loop(Northcrash,"North Crash", {"northcrash"}, "Working. Can't crash yourself with toggled.", function()
    if player_id ~= players.user() then
    local pos = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id))
    local michael = util.joaat("player_zero")
    while not STREAMING.HAS_MODEL_LOADED(michael) do
        STREAMING.REQUEST_MODEL(michael)
        util.yield()
    end
    local ped = entities.create_ped(0, michael, pos, 0)
    PED.SET_PED_COMPONENT_VARIATION(ped, 0, 0, 6, 0)
    PED.SET_PED_COMPONENT_VARIATION(ped, 0, 0, 7, 0)
    util.yield()
    util.yield(500)
    entities.delete_by_handle(ped)
    util.toast("North Crash Sent to " .. PLAYER.GET_PLAYER_NAME(player_id))
    util.log("North Crash Sent to " .. PLAYER.GET_PLAYER_NAME(player_id))
    end
end)
-----------------------------------------------------------------------------------------------------------
local KiddionsCrash = menu.list(crashes, "Kiddions Crashes", {}, "")

menu.action(KiddionsCrash,"Kiddions Crash", {"dakiddionscrash"}, "Working. LMFAO", function()
    menu.trigger_commands("flashcrash" .. PLAYER.GET_PLAYER_NAME(player_id))
    util.yield()
    util.toast("Kiddions Crash Sent to " .. PLAYER.GET_PLAYER_NAME(player_id))
    util.log("Kiddions Crash Sent to " .. PLAYER.GET_PLAYER_NAME(player_id))
end, nil, nil, COMMANDPERM_AGGRESSIVE)

menu.toggle_loop(KiddionsCrash,"Kiddions Crash", {"kiddionscrash"}, "Working. LMFAO", function()
    if player_id ~= players.user() then
    menu.trigger_commands("flashcrash" .. PLAYER.GET_PLAYER_NAME(player_id))
    util.yield()
    util.toast("Kiddions Crash Sent to " .. PLAYER.GET_PLAYER_NAME(player_id))
    util.log("Kiddions Crash Sent to " .. PLAYER.GET_PLAYER_NAME(player_id))
    end
end)

--------------------------------------------------------------------------------------------------------------------------------

menu.action(crashes, "Outfit crash v1", {"daoutfitcrashv1"}, "Changes freemode ped outfit variations and gives them homing launchers. Similar to a bro hug. Will have to turn off anticrashcamera yourself.", function(on)
    menu.trigger_commands("anticrashcamera on")
    local player_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)
    local old_coords = ENTITY.GET_ENTITY_COORDS(player_ped)
for i=1,1  do
    ENTITY.SET_ENTITY_COORDS_NO_OFFSET(player_ped, -1329.5868, -3041.565, 65.06483)
    local math_random = math.random
    local joaat = util.joaat
    util.yield(10)
    local pedhash1 = util.joaat("MP_F_Freemode_01")
    local pedhash2 = util.joaat("MP_F_Freemode_01")
    local pedhash3 = util.joaat("MP_F_Freemode_01")
    while not STREAMING.HAS_MODEL_LOADED(pedhash1, pedhash2, pedhash3) do
        STREAMING.REQUEST_MODEL(pedhash1, pedhash2, pedhash3)
        util.yield(10)
    end
    local FinalRenderedCamRot = CAM.GET_FINAL_RENDERED_CAM_ROT(2).z
    SpawnedPeds1 = {}
    local ped_amount = math_random(5, 15) -- Picks number between 5 and 15
    for i = 1, ped_amount do
        local pedtype = 0
        local PlayerPedCoords = ENTITY.GET_ENTITY_COORDS(player_ped, true)
        local coords = PlayerPedCoords
        local loc1, loc2, loc3, pedt = math_random(0, 15), math_random(0, 15), math_random(0, 15), math_random(0, 15)
        coords.x = coords.x
        coords.y = coords.y
        coords.z = coords.z
        if loc1 == 1 then
            coords.x = coords.x - math_random(0, 15)
        else
            coords.x = coords.x + math_random(0, 15)
        end
        if loc2 == 1 then
            coords.y = coords.y - math_random(0, 15)
        else
            coords.y = coords.y + math_random(0, 15)
        end
        if loc3 == 1 then
            coords.z = coords.z - math_random(0, 15)
        else
            coords.z = coords.z + math_random(0, 15)
        end
        if pedt == 1 then
            pedtype = 0
        else
            pedtype = 3
        end
        SpawnedPeds2 = {}
        local ped_amount = math_random(7, 10)
        for i = 1, ped_amount do
            local pedtype = 0
            local coords = PlayerPedCoords
            local loc1, loc2, loc3, pedt = math_random(0, 15), math_random(0, 15), math_random(0, 15), math_random(0, 15)
            coords.x = coords.x
            coords.y = coords.y
            coords.z = coords.z
            if loc1 == 1 then
                coords.x = coords.x - math_random(0, 15)
            else
                coords.x = coords.x + math_random(0, 15)
            end
            if loc2 == 1 then
                coords.y = coords.y - math_random(0, 15)
            else
                coords.y = coords.y + math_random(0, 15)
            end
            if loc3 == 1 then
                coords.z = coords.z - math_random(0, 15)
            else
                coords.z = coords.z + math_random(0, 15)
            end
            if pedt == 1 then
                pedtype = 0
            else
                pedtype = 3
            end
            SpawnedPeds3 = {}
            local ped_amount = math_random(7, 10)
            for i = 1, ped_amount do
                local pedtype = 0
                local coords = PlayerPedCoords
                local loc1, loc2, loc3, pedt = math_random(0, 15), math_random(0, 15), math_random(0, 15), math_random(0, 15)
                coords.x = coords.x
                coords.y = coords.y
                coords.z = coords.z
                if loc1 == 1 then
                    coords.x = coords.x - math_random(0, 15)
                else
                    coords.x = coords.x + math_random(0, 15)
                end
                if loc2 == 1 then
                    coords.y = coords.y - math_random(0, 15)
                else
                    coords.y = coords.y + math_random(0, 15)
                end
                if loc3 == 1 then
                    coords.z = coords.z - math_random(0, 15)
                else
                    coords.z = coords.z + math_random(0, 15)
                end
                if pedt == 1 then
                    pedtype = 0
                else
                    pedtype = 3
                end
        SpawnedPeds1[i] = entities.create_ped(pedtype, pedhash1, coords, FinalRenderedCamRot)
        SpawnedPeds2[i] = entities.create_ped(pedtype, pedhash2, coords, FinalRenderedCamRot)
        SpawnedPeds3[i] = entities.create_ped(pedtype, pedhash3, coords, FinalRenderedCamRot)
        ENTITY.ATTACH_ENTITY_TO_ENTITY(SpawnedPeds1[i], SpawnedPeds2[i], PlayerPedCoords, 0, 0, 0, 0, 0, 0, 0, 0, true, true, false, 0, true)
        ENTITY.ATTACH_ENTITY_TO_ENTITY(SpawnedPeds2[i], SpawnedPeds3[i], PlayerPedCoords, 0, 0, 0, 0, 0, 0, 0, 0, true, true, false, 0, true)
        ENTITY.SET_ENTITY_INVINCIBLE(SpawnedPeds1[i], true)
        ENTITY.SET_ENTITY_AS_MISSION_ENTITY(SpawnedPeds1[i], true, true)
        TASK.TASK_START_SCENARIO_IN_PLACE(SpawnedPeds1[i], "Walk_Facility", 0, false)
        ENTITY.SET_ENTITY_INVINCIBLE(SpawnedPeds2[i], true)
        ENTITY.SET_ENTITY_AS_MISSION_ENTITY(SpawnedPeds2[i], true, true)
        TASK.TASK_START_SCENARIO_IN_PLACE(SpawnedPeds2[i], "Walk_Facility", 0, false)
        ENTITY.SET_ENTITY_INVINCIBLE(SpawnedPeds3[i], true)
        ENTITY.SET_ENTITY_AS_MISSION_ENTITY(SpawnedPeds3[i], true, true)
        TASK.TASK_START_SCENARIO_IN_PLACE(SpawnedPeds3[i], "Walk_Facility", 0, false)
        ENTITY.SET_ENTITY_VISIBLE(SpawnedPeds1[i], true)
        ENTITY.SET_ENTITY_VISIBLE(SpawnedPeds2[i], true)
        ENTITY.SET_ENTITY_VISIBLE(SpawnedPeds3[i], true)
        MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(coords.x, coords.y, coords.z + 1, coords.x, coords.y, coords.z, 0, true, util.joaat("weapon_stungun"), players.user_ped(), false, true, 1.0)
        util.yield(5)
        local coords = ENTITY.GET_ENTITY_COORDS(ped1, true)
        WEAPON.GIVE_WEAPON_TO_PED(SpawnedPeds1[i], util.joaat('WEAPON_HOMINGLAUNCHER'), 9999, true, true)
        local obj
        repeat
            obj = WEAPON.GET_CURRENT_PED_WEAPON_ENTITY_INDEX(SpawnedPeds1[i], 0)
        until obj ~= 0 or util.yield()
        ENTITY.DETACH_ENTITY(obj, true, true) 
        util.yield(1)
        FIRE.ADD_EXPLOSION(coords.x, coords.y, coords.z, 0, 1.0, false, true, 0.0, false)
        WEAPON.GIVE_WEAPON_TO_PED(SpawnedPeds2[i], util.joaat('WEAPON_HOMINGLAUNCHER'), 9999, true, true)
        repeat
            obj = WEAPON.GET_CURRENT_PED_WEAPON_ENTITY_INDEX(SpawnedPeds2[i], 0)
        until obj ~= 0 or util.yield()
        ENTITY.DETACH_ENTITY(obj, true, true) 
        util.yield(1)
        FIRE.ADD_EXPLOSION(coords.x, coords.y, coords.z, 0, 1.0, false, true, 0.0, false)
        WEAPON.GIVE_WEAPON_TO_PED(SpawnedPeds3[i], util.joaat('WEAPON_HOMINGLAUNCHER'), 9999, true, true)
        repeat
            obj = WEAPON.GET_CURRENT_PED_WEAPON_ENTITY_INDEX(SpawnedPeds3[i], 0)
        until obj ~= 0 or util.yield()
        ENTITY.DETACH_ENTITY(obj, true, true) 
        util.yield(1)
        FIRE.ADD_EXPLOSION(coords.x, coords.y, coords.z, 0, 1.0, false, true, 0.0, false)
    end
    for i = 1, ped_amount do
        PED.SET_PED_RANDOM_COMPONENT_VARIATION(player_ped, 0)
        PED.SET_PED_COMPONENT_VARIATION(player_ped, 3, 0, 1, 0)
        PED.SET_PED_RANDOM_COMPONENT_VARIATION(SpawnedPeds1[i], 0)
        PED.SET_PED_COMPONENT_VARIATION(SpawnedPeds1[i], 3, 0, 1, 0)
        PED.SET_PED_RANDOM_COMPONENT_VARIATION(SpawnedPeds2[i], 0)
        PED.SET_PED_COMPONENT_VARIATION(SpawnedPeds2[i], 3, 0, 1, 0)
        PED.SET_PED_RANDOM_COMPONENT_VARIATION(SpawnedPeds3[i], 0)
        PED.SET_PED_COMPONENT_VARIATION(SpawnedPeds3[i], 3, 0, 1, 0)
        util.yield(5000)
        menu.trigger_commands("anticrashcamera off")
        end
        util.yield(10)
        end
        menu.trigger_commands("clearworld")
        end
        ENTITY.SET_ENTITY_COORDS_NO_OFFSET(player_ped, old_coords.x, old_coords.y, old_coords.z)
        util.toast("Outfit Crash In Progress!\n" .. "\n" .. pedtype .. " Ped Types \n" .. "\n" .. ped_amount .. " Random Peds")
        menu.trigger_commands("anticrashcamera off")
    end
end, nil, nil, COMMANDPERM_AGGRESSIVE)

menu.action(crashes, "Outfit crash v2", {"daoutfitcrashv2"}, "Changes their outfit variations. Lasts around 30 seconds.", function(on)
    local math_random = math.random
    menu.trigger_commands("anticrashcamera on")
    menu.trigger_commands("mpfemale")
    util.yield(10)
    local player_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)
    local FinalRenderedCamRot = CAM.GET_FINAL_RENDERED_CAM_ROT(2).z
    SpawnedPeds1 = {}
    local ped_amount = math_random(7, 10) -- Picks number between 7 and 10
    for i = 1, ped_amount do
        local pedtype = 0
        local PlayerPedCoords = ENTITY.GET_ENTITY_COORDS(player_ped, true)
        local coords = PlayerPedCoords
        local loc1, loc2, loc3, pedt = math_random(0, 15), math_random(0, 15), math_random(0, 15), math_random(0, 15)
        coords.x = coords.x
        coords.y = coords.y
        coords.z = coords.z
        if loc1 == 1 then
            coords.x = coords.x - math_random(0, 15)
        else
            coords.x = coords.x + math_random(0, 15)
        end
        if loc2 == 1 then
            coords.y = coords.y - math_random(0, 15)
        else
            coords.y = coords.y + math_random(0, 15)
        end
        if loc3 == 1 then
            coords.z = coords.z - math_random(0, 15)
        else
            coords.z = coords.z + math_random(0, 15)
        end
        if pedt == 1 then
            pedtype = 0
        else
            pedtype = 3
        end
        SpawnedPeds2 = {}
        local ped_amount = math_random(7, 10)
        for i = 1, ped_amount do
            local pedtype = 0
            local coords = PlayerPedCoords
            local loc1, loc2, loc3, pedt = math_random(0, 15), math_random(0, 15), math_random(0, 15), math_random(0, 15)
            coords.x = coords.x
            coords.y = coords.y
            coords.z = coords.z
            if loc1 == 1 then
                coords.x = coords.x - math_random(0, 15)
            else
                coords.x = coords.x + math_random(0, 15)
            end
            if loc2 == 1 then
                coords.y = coords.y - math_random(0, 15)
            else
                coords.y = coords.y + math_random(0, 15)
            end
            if loc3 == 1 then
                coords.z = coords.z - math_random(0, 15)
            else
                coords.z = coords.z + math_random(0, 15)
            end
            if pedt == 1 then
                pedtype = 0
            else
                pedtype = 3
            end
            SpawnedPeds3 = {}
            local ped_amount = math_random(7, 10)
            for i = 1, ped_amount do
                local pedtype = 0
                local coords = PlayerPedCoords
                local loc1, loc2, loc3, pedt = math_random(0, 15), math_random(0, 15), math_random(0, 15), math_random(0, 15)
                coords.x = coords.x
                coords.y = coords.y
                coords.z = coords.z
                if loc1 == 1 then
                    coords.x = coords.x - math_random(0, 15)
                else
                    coords.x = coords.x + math_random(0, 15)
                end
                if loc2 == 1 then
                    coords.y = coords.y - math_random(0, 15)
                else
                    coords.y = coords.y + math_random(0, 15)
                end
                if loc3 == 1 then
                    coords.z = coords.z - math_random(0, 15)
                else
                    coords.z = coords.z + math_random(0, 15)
                end
                if pedt == 1 then
                    pedtype = 0
                else
                    pedtype = 3
                end
        ENTITY.SET_ENTITY_INVINCIBLE(player_ped, true)
        ENTITY.SET_ENTITY_AS_MISSION_ENTITY(player_ped, true, true)
        TASK.TASK_START_SCENARIO_IN_PLACE(player_ped, "Walk_Facility", 0, false)
        ENTITY.SET_ENTITY_VISIBLE(player_ped, true)
        MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(coords.x, coords.y, coords.z + 1, coords.x, coords.y, coords.z, 0, true, util.joaat("weapon_stungun"), players.user_ped(), false, true, 1.0)
        util.yield(5)
    end
    for i = 1, ped_amount do
        PED.SET_PED_RANDOM_COMPONENT_VARIATION(player_ped, 0)
        PED.SET_PED_COMPONENT_VARIATION(player_ped, 3, 0, 1, 0)
        util.yield(20000)
        menu.trigger_commands("anticrashcamera off")
        end
        util.yield(10)
        end
        util.toast("Outfit Crash In Progress!\n" .. "\n" .. pedtype .. " Ped Types \n" .. "\n" .. ped_amount .. " Random Peds")
        menu.trigger_commands("anticrashcamera off")
    end
end, nil, nil, COMMANDPERM_AGGRESSIVE)


menu.action(crashes, "Outfit crash v3", {"daoutfitcrashv3"}, "Changes your outfit variations. Lasts around 30 seconds.", function(on)
    local math_random = math.random
    menu.trigger_commands("anticrashcamera on")
    menu.trigger_commands("mpfemale")
    util.yield(10)
    local player_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user())
    local FinalRenderedCamRot = CAM.GET_FINAL_RENDERED_CAM_ROT(2).z
    SpawnedPeds1 = {}
    local ped_amount = math_random(7, 10) -- Picks number between 7 and 10
    for i = 1, ped_amount do
        local pedtype = 0
        local PlayerPedCoords = ENTITY.GET_ENTITY_COORDS(player_ped, true)
        local coords = PlayerPedCoords
        local loc1, loc2, loc3, pedt = math_random(0, 15), math_random(0, 15), math_random(0, 15), math_random(0, 15)
        coords.x = coords.x
        coords.y = coords.y
        coords.z = coords.z
        if loc1 == 1 then
            coords.x = coords.x - math_random(0, 15)
        else
            coords.x = coords.x + math_random(0, 15)
        end
        if loc2 == 1 then
            coords.y = coords.y - math_random(0, 15)
        else
            coords.y = coords.y + math_random(0, 15)
        end
        if loc3 == 1 then
            coords.z = coords.z - math_random(0, 15)
        else
            coords.z = coords.z + math_random(0, 15)
        end
        if pedt == 1 then
            pedtype = 0
        else
            pedtype = 3
        end
        SpawnedPeds2 = {}
        local ped_amount = math_random(7, 10)
        for i = 1, ped_amount do
            local pedtype = 0
            local coords = PlayerPedCoords
            local loc1, loc2, loc3, pedt = math_random(0, 15), math_random(0, 15), math_random(0, 15), math_random(0, 15)
            coords.x = coords.x
            coords.y = coords.y
            coords.z = coords.z
            if loc1 == 1 then
                coords.x = coords.x - math_random(0, 15)
            else
                coords.x = coords.x + math_random(0, 15)
            end
            if loc2 == 1 then
                coords.y = coords.y - math_random(0, 15)
            else
                coords.y = coords.y + math_random(0, 15)
            end
            if loc3 == 1 then
                coords.z = coords.z - math_random(0, 15)
            else
                coords.z = coords.z + math_random(0, 15)
            end
            if pedt == 1 then
                pedtype = 0
            else
                pedtype = 3
            end
            SpawnedPeds3 = {}
            local ped_amount = math_random(7, 10)
            for i = 1, ped_amount do
                local pedtype = 0
                local coords = PlayerPedCoords
                local loc1, loc2, loc3, pedt = math_random(0, 15), math_random(0, 15), math_random(0, 15), math_random(0, 15)
                coords.x = coords.x
                coords.y = coords.y
                coords.z = coords.z
                if loc1 == 1 then
                    coords.x = coords.x - math_random(0, 15)
                else
                    coords.x = coords.x + math_random(0, 15)
                end
                if loc2 == 1 then
                    coords.y = coords.y - math_random(0, 15)
                else
                    coords.y = coords.y + math_random(0, 15)
                end
                if loc3 == 1 then
                    coords.z = coords.z - math_random(0, 15)
                else
                    coords.z = coords.z + math_random(0, 15)
                end
                if pedt == 1 then
                    pedtype = 0
                else
                    pedtype = 3
                end
        ENTITY.SET_ENTITY_INVINCIBLE(player_ped, true)
        ENTITY.SET_ENTITY_AS_MISSION_ENTITY(player_ped, true, true)
        TASK.TASK_START_SCENARIO_IN_PLACE(player_ped, "Walk_Facility", 0, false)
        ENTITY.SET_ENTITY_VISIBLE(player_ped, true)
        MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(coords.x, coords.y, coords.z + 1, coords.x, coords.y, coords.z, 0, true, util.joaat("weapon_stungun"), players.user_ped(), false, true, 1.0)
        util.yield(5)
        --menu.trigger_commands("anticrashcamera off")
    end
    for i = 1, ped_amount do
        PED.SET_PED_RANDOM_COMPONENT_VARIATION(player_ped, 0)
        PED.SET_PED_COMPONENT_VARIATION(player_ped, 3, 0, 1, 0)
        util.yield(20000)
        menu.trigger_commands("anticrashcamera off")
        end
        util.yield(10)
        end
        util.toast("Outfit Crash In Progress!\n" .. "\n" .. pedtype .. " Ped Types \n" .. "\n" .. ped_amount .. " Random Peds")
        menu.trigger_commands("anticrashcamera off")
    end
end, nil, nil, COMMANDPERM_AGGRESSIVE)


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

    menu.divider(crashes, "_________________________________________")

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
    menu.trigger_commands("superc 3")
    menu.trigger_commands("superc 4")
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
    menu.trigger_commands("superc 3")
    menu.trigger_commands("superc 4")
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
    menu.trigger_commands("superc 3")
    menu.trigger_commands("superc 4")
end)

-------------------------------------------------------------------------------------------------------------------------------------------------------

local kicks = menu.list(malicious, "Kicks", {}, "")
	
menu.divider(kicks, "Base Kicks")

    menu.action(kicks, "Adaptive Kick", {}, "", function()
        menu.trigger_commands("scripthos")
        util.trigger_script_event(1 << player_id, {1104117595, player_id, 1, 0, 2, 14, 3, 1})
        util.trigger_script_event(1 << player_id, {1104117595, player_id, 1, 0, 2, 167, 3, 1})
        util.trigger_script_event(1 << player_id, {1104117595, player_id, 1, 0, 2, 257, 3, 1})
        menu.trigger_commands("breakup" .. players.get_name(player_id))
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

    menu.action(kicks, "Power Kick", {}, "", function()
        Fewd.power_kick(player_id)
    end)

    menu.action(trolling, "Send To Jail", {}, "", function()
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

    local function GiveWeapon(attacker)
        if (weapon0 == true) then
            WEAPON.REQUEST_WEAPON_ASSET(unarmed, 31, 0)
            WEAPON.GIVE_WEAPON_TO_PED(attacker, unarmed, 1, false, true)
        elseif (weapon1 == true) then
            WEAPON.REQUEST_WEAPON_ASSET(machete, 31, 0)
            WEAPON.GIVE_WEAPON_TO_PED(attacker, machete, 1, false, true)
        elseif (weapon2 == true) then
            WEAPON.REQUEST_WEAPON_ASSET(pistol, 31, 0)
            WEAPON.GIVE_WEAPON_TO_PED(attacker, pistol, 1, false, true)
        elseif (weapon3 == true) then
            WEAPON.REQUEST_WEAPON_ASSET(stungun, 31, 0)
            WEAPON.GIVE_WEAPON_TO_PED(attacker, stungun, 1, false, true)
        elseif (weapon4 == true) then
            WEAPON.REQUEST_WEAPON_ASSET(atomizer, 31, 0)
            WEAPON.GIVE_WEAPON_TO_PED(attacker, atomizer, 1, false, true)
        elseif (weapon5 == true) then
            WEAPON.REQUEST_WEAPON_ASSET(shotgun, 31, 0)
            WEAPON.GIVE_WEAPON_TO_PED(attacker, shotgun, 1, false, true)
        elseif (weapon6 == true) then
            WEAPON.REQUEST_WEAPON_ASSET(sniper, 31, 0)
            WEAPON.GIVE_WEAPON_TO_PED(attacker, sniper, 1, false, true)
        elseif (weapon7 == true) then
            WEAPON.REQUEST_WEAPON_ASSET(microsmg, 31, 0)
            WEAPON.GIVE_WEAPON_TO_PED(attacker, microsmg, 1, false, true)
        elseif (weapon8 == true) then
            WEAPON.REQUEST_WEAPON_ASSET(minigun, 31, 0)
            WEAPON.GIVE_WEAPON_TO_PED(attacker, minigun, 1, false, true)
        elseif (weapon9 == true) then
            WEAPON.REQUEST_WEAPON_ASSET(RPG, 31, 0)
            WEAPON.GIVE_WEAPON_TO_PED(attacker, RPG, 1, false, true)
        elseif (weapon10 == true) then
            WEAPON.REQUEST_WEAPON_ASSET(hellbringer, 31, 0)
            WEAPON.GIVE_WEAPON_TO_PED(attacker, hellbringer, 1, false, true)
        elseif (weapon11 == true) then
            WEAPON.REQUEST_WEAPON_ASSET(railgun, 31, 0)
            WEAPON.GIVE_WEAPON_TO_PED(attacker, railgun, 1, false, true)
        end
    end

    local function setAttribute(attacker)
        PED.SET_PED_COMBAT_ATTRIBUTES(attacker, 38, true)
        PED.SET_PED_COMBAT_ATTRIBUTES(attacker, 5, true)
        PED.SET_PED_COMBAT_ATTRIBUTES(attacker, 0, true)
        PED.SET_PED_COMBAT_ATTRIBUTES(attacker, 12, true)
        PED.SET_PED_COMBAT_ATTRIBUTES(attacker, 22, true)
        PED.SET_PED_COMBAT_ATTRIBUTES(attacker, 54, true)
        PED.SET_PED_COMBAT_RANGE(attacker, 4)
        PED.SET_PED_COMBAT_ABILITY(attacker, 3)
    end

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

    menu.action(trolling, "Teleport To The Backrooms", {}, "", function()
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
        menu.trigger_commands("givecollectibles" .. players.get_name(player_id))
	end, nil, nil, COMMANDPERM_FRIENDLY)

    menu.toggle_loop(friendly, "Drop Cash Loop", {"cashloop"}, "", function()
        local coords = players.get_position(player_id)
        coords.z = coords.z + 1.5
        local cash = MISC.GET_HASH_KEY("PICKUP_VEHICLE_MONEY_VARIABLE")
        STREAMING.REQUEST_MODEL(cash)
        if STREAMING.HAS_MODEL_LOADED(cash) == false then  
            STREAMING.REQUEST_MODEL(cash)
        end
        OBJECT.CREATE_AMBIENT_PICKUP(1704231442, coords.x, coords.y, coords.z, 0, 2000, cash, false, true)
        util.toast("Cash Dropping To " .. players.get_name(player_id))
        util.yield(3400)
    end)

    menu.toggle_loop(friendly, "Drop RP (Attach)", {"dropfigures"}, "", function()
        local coords = players.get_position(player_id)
        coords.z = coords.z + 1.5
        local random_hash = 0x4D6514A3
        local random_int = math.random(1, 8)
        if random_int == 1 then
            random_hash = 0x4D6514A3
        elseif random_int == 2 then
            random_hash = 0x748F3A2A
        elseif random_int == 3 then
            random_hash = 0x1A9736DA
        elseif random_int == 4 then
            random_hash = 0x3D1B7A2F
        elseif random_int == 5 then
            random_hash = 0x1A126315
        elseif random_int == 6 then
            random_hash = 0xD937A5E9
        elseif random_int == 7 then
            random_hash = 0x23DDE6DB
        elseif random_int == 8 then
            random_hash = 0x991F8C36
        end
        STREAMING.REQUEST_MODEL(random_hash)
        if STREAMING.HAS_MODEL_LOADED(random_hash) == false then  
            STREAMING.REQUEST_MODEL(random_hash)
        end
        OBJECT.CREATE_AMBIENT_PICKUP(-1009939663, coords.x, coords.y, coords.z, 0, 1, random_hash, false, true)
        menu.trigger_commands("attachto" .. players.get_name(player_id))
        menu.trigger_commands("tppickups" .. players.get_name(player_id))
        util.yield(3000)
    end)

    menu.toggle_loop(friendly, "Give Casino Chips", {"dropchips"}, "Idk if its safe for the new DLC", function(toggle)
        local coords = players.get_position(player_id)
        coords.z = coords.z + 1.5
        local card = MISC.GET_HASH_KEY("vw_prop_vw_lux_card_01a")
        STREAMING.REQUEST_MODEL(card)
        if STREAMING.HAS_MODEL_LOADED(card) == false then  
            STREAMING.REQUEST_MODEL(card)
        end
        OBJECT.CREATE_AMBIENT_PICKUP(-1009939663, coords.x, coords.y, coords.z, 0, 1, card, false, true)
    end)

    menu.action(friendly, "Give Life and Armor", {}, "", function()
        menu.trigger_commands("autoheal"..players.get_name(player_id))
    end)

    menu.toggle_loop(friendly, "Drop Guns & Armor", {"dropguns"}, "", function()
        local coords = players.get_position(player_id)
        coords.z = coords.z + 1.5
        local random_hash = 0x6E4E65C2
        local random_int = math.random(1, 75)
        if random_int == 1 then
            random_hash = 0x741C684A
        elseif random_int == 2 then
            random_hash = 0x68605A36
        elseif random_int == 3 then
            random_hash = 0x6C5B941A
        elseif random_int == 4 then
            random_hash = 0xD3A39366
        elseif random_int == 5 then
            random_hash = 0x550447A9
        elseif random_int == 6 then
            random_hash = 0xF99E15D0
        elseif random_int == 7 then
            random_hash = 0xA421A532
        elseif random_int == 8 then
            random_hash = 0xF33C83B0
        elseif random_int == 10 then
            random_hash = 0xDF711959
        elseif random_int == 11 then
            random_hash = 0xB2B5325E
        elseif random_int == 12 then
            random_hash = 0x85CAA9B1
        elseif random_int == 13 then
            random_hash = 0xB2930A14
        elseif random_int == 14 then
            random_hash = 0xFE2A352C
        elseif random_int == 15 then
            random_hash = 0x693583AD
        elseif random_int == 16 then
            random_hash = 0x1D9588D3
        elseif random_int == 17 then
            random_hash = 0x3A4C2AD2
        elseif random_int == 18 then
            random_hash = 0x4BFB42D1
        elseif random_int == 19 then
            random_hash = 0x4D36C349
        elseif random_int == 20 then
            random_hash = 0x2F36B434
        elseif random_int == 21 then
            random_hash = 0x8F707C18
        elseif random_int == 22 then
            random_hash = 0xA9355DCD
        elseif random_int == 23 then
            random_hash = 0x96B412A3
        elseif random_int == 24 then
            random_hash = 0x9299C95B
        elseif random_int == 25 then
            random_hash = 0x5E0683A1
        elseif random_int == 26 then
            random_hash = 0x2DD30479
        elseif random_int == 27 then
            random_hash = 0x1CD604C7
        elseif random_int == 28 then
            random_hash = 0x7C119D58
        elseif random_int == 29 then
            random_hash = 0xF9AFB48F
        elseif random_int == 30 then
            random_hash = 0x8967B4F3
        elseif random_int == 31 then
            random_hash = 0x3B662889
        elseif random_int == 32 then
            random_hash = 0x2E764125
        elseif random_int == 33 then
            random_hash = 0xFD16169E
        elseif random_int == 34 then
            random_hash = 0xCB13D282
        elseif random_int == 35 then
            random_hash = 0xC69DE3FF
        elseif random_int == 36 then
            random_hash = 0x278D8734
        elseif random_int == 37 then
            random_hash = 0x295691A9
        elseif random_int == 38 then
            random_hash = 0x81EE601E
        elseif random_int == 39 then
            random_hash = 0x88EAACA7
        elseif random_int == 40 then
            random_hash = 0x872DC888
        elseif random_int == 41 then
            random_hash = 0x094AA1CF
        elseif random_int == 42 then
            random_hash = 0xE33D8630
        elseif random_int == 43 then
            random_hash = 0x80AB931C
        elseif random_int == 44 then
            random_hash = 0x6E717A95
        elseif random_int == 45 then
            random_hash = 0x1CD2CF66
        elseif random_int == 46 then
            random_hash = 0x6773257D
        elseif random_int == 47 then
            random_hash = 0x20796A82
        elseif random_int == 48 then
            random_hash = 0x116FC4E6
        elseif random_int == 49 then
            random_hash = 0xE4BD2FC6
        elseif random_int == 50 then
            random_hash = 0xDE58E0B3
        elseif random_int == 51 then
            random_hash = 0x77F3F2DD
        elseif random_int == 52 then
            random_hash = 0xC02CF125
        elseif random_int == 53 then
            random_hash = 0x881AB0A8
        elseif random_int == 54 then
            random_hash = 0x84837FD7
        elseif random_int == 55 then
            random_hash = 0xF25A01B9
        elseif random_int == 56 then
            random_hash = 0x815D66E8
        elseif random_int == 57 then
            random_hash = 0xFA51ABF5
        elseif random_int == 58 then
            random_hash = 0xC5B72713
        elseif random_int == 59 then
            random_hash = 0x5307A4EC
        elseif random_int == 60 then
            random_hash = 0x9CF13918
        elseif random_int == 61 then
            random_hash = 0x0968339D
        elseif random_int == 62 then
            random_hash = 0xBFEE6C3B
        elseif random_int == 63 then
            random_hash = 0xEBF89D5F
        elseif random_int == 64 then
            random_hash = 0x22B15640
        elseif random_int == 65 then
            random_hash = 0x763F7121
        elseif random_int == 66 then
            random_hash = 0xF92F486C
        elseif random_int == 67 then
            random_hash = 0x602941D0
        elseif random_int == 68 then
            random_hash = 0x31EA45C9
        elseif random_int == 69 then
            random_hash = 0xBED46EC5
        elseif random_int == 70 then
            random_hash = 0x079284A9
        elseif random_int == 71 then
            random_hash = 0x624F7213
        elseif random_int == 72 then
            random_hash = 0xC01EB678
        elseif random_int == 73 then
            random_hash = 0x5C517D97
        elseif random_int == 74 then
            random_hash = 0xBD4DE242
        elseif random_int == 75 then
            random_hash = 0xE013E01C
        end
        STREAMING.REQUEST_MODEL(random_hash)
        if STREAMING.HAS_MODEL_LOADED(random_hash) == true then  
            STREAMING.REQUEST_MODEL(random_hash)
        end
        OBJECT.CREATE_AMBIENT_PICKUP(random_hash, coords.x, coords.y, coords.z, 0, 1, random_hash, false, true)
    end)

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


------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Vehicle

    menu.action(vehicle, "Detach", {"detach"}, "unstuck yourself", function()
        local car = PED.GET_VEHICLE_PED_IS_IN(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id), true)
        ENTITY.DETACH_ENTITY(car, false, false)
        if player_cur_car ~= 0 then
            ENTITY.DETACH_ENTITY(player_cur_car, false, false)
        end
        ENTITY.DETACH_ENTITY(players.user_ped(), false, false)
    end)

menu.action(vehicle, "Attach to BMX", {""}, "Use Ledge Sit animation to properly sit on the player's bars", function()
    local car = PED.GET_VEHICLE_PED_IS_IN(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id), true)
    if car ~= 0 then
        NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(car)
        ENTITY.ATTACH_ENTITY_TO_ENTITY(players.user_ped(), car, 0, 0.0--[[x]], 0.5--[[z]], 0.4--[[y]], 0.0--[[verticle (flip)]], 0.0--[[horizontal (go sideways)]], 0.0--[[w (turn)]], 1.0, 1, true, true, true, true, 0, true)
        end
end)

menu.action(vehicle, "Attach to Addon Car Hood", {""}, "Use Ledge Sit animation to properly sit on the player's car", function()
    local car = PED.GET_VEHICLE_PED_IS_IN(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id), true)
    if car ~= 0 then
        NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(car)
            ENTITY.ATTACH_ENTITY_TO_ENTITY(players.user_ped(), car, 0, 0.5--[[x]], 1.9--[[z]], 0--[[y]], 0.0--[[verticle (flip)]], 0.0--[[horizontal (go sideways)]], 0.0--[[w (turn)]], 1.0, 1, true, true, true, true, 0, true)
        end
end)

menu.action(vehicle, "Attach Floating", {""}, "Attach to player's car (syncs for everyone)", function()
    local car = PED.GET_VEHICLE_PED_IS_IN(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id), true)
    if car ~= 0 then
        NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(car)
            ENTITY.ATTACH_ENTITY_TO_ENTITY(players.user_ped(), car, 0, 0.0--[[x]], -1.60--[[z]], 3.3--[[y]], 0.0--[[verticle (flip)]], 0.0--[[horizontal (go sideways)]], 0.0--[[w (turn)]], 1.0, 1, true, true, true, true, 0, true)
        end
end)

menu.action(vehicle, "Attach to Car Roof", {""}, "Attach to player's car (syncs for everyone)", function()
    local car = PED.GET_VEHICLE_PED_IS_IN(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id), true)
    if car ~= 0 then
        NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(car)
            ENTITY.ATTACH_ENTITY_TO_ENTITY(players.user_ped(), car, 0, 0.0, -0.20, 2.00, 0.0--[[verticle (flip)]], 0.0--[[horizontal (go sideways)]], 0.0--[[w (turn)]], 1.0, 1, true, true, true, true, 0, true)
        end
end)

menu.action(vehicle, "Attach to Car Trunk", {""}, "Attach to player's car (syncs for everyone)", function()
    local car = PED.GET_VEHICLE_PED_IS_IN(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id), true)
    if car ~= 0 then
        NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(car)
            ENTITY.ATTACH_ENTITY_TO_ENTITY(players.user_ped(), car, 0, 0.0--[[x]], -1.60--[[z]], 1.60--[[y]], 0.0--[[verticle (flip)]], 0.0--[[horizontal (go sideways)]], 0.0--[[w (turn)]], 1.0, 1, true, true, true, true, 0, true)
        end
end)

--[[menu.action(attachc, "Clear World", {"clearworldv2"}, "Clean Up The Mess It Might Have Made", function()
    util.yield(0500)
    menu.trigger_commands("clearworld")
end)]]


menu.action(attachc, "Detach", {"detach"}, "unstuck yourself", function()
    local car = PED.GET_VEHICLE_PED_IS_IN(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id), true)
    ENTITY.DETACH_ENTITY(car, false, false)
    if player_cur_car ~= 0 then
        ENTITY.DETACH_ENTITY(player_cur_car, false, false)
    end
    ENTITY.DETACH_ENTITY(players.user_ped(), false, false)
end)

--menu.toggle_loop(attachc, "Attach To Player 'Test' (Super Scuffed)", {""}, "Attach to player (scuffed sync for everyone)", function()
        --local p = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)
        --local c = ENTITY.GET_ENTITY_COORDS(p)
        --local boneId = ENTITY.GET_ENTITY_BONE_INDEX_BY_NAME(p, "head")
        --local item = 322248450 --[[util.joaat("prop_elecbox_12")]]
        --util.yield_once()
        --request_model(item)
        --local object = entities.create_object(item, c)
        --ENTITY.FREEZE_ENTITY_POSITION(object)
        --ENTITY.SET_ENTITY_VISIBLE(object, false)
        --ENTITY.ATTACH_ENTITY_TO_ENTITY(item, p, 0, 0.0--[[x]], -5.0--[[z]], -25--[[y]], 0.0--[[verticle (flip)]], 0.0--[[horizontal (go sideways)]], 0.0--[[w (turn)]], 1.0, 1, true, true, true, true, 0, true)
        --ENTITY.ATTACH_ENTITY_TO_ENTITY(p, object, 0, 0.0--[[x]], -5.0--[[z]], -25--[[y]], 0.0--[[verticle (flip)]], 0.0--[[horizontal (go sideways)]], 0.0--[[w (turn)]], 1.0, 1, true, true, true, true, 0, true)
        --ENTITY.ATTACH_ENTITY_TO_ENTITY(players.user_ped(), p, 0, 0.0--[[x]], 0.0--[[z]], 1.65--[[y]], 0.0--[[verticle (flip)]], 0.0--[[horizontal (go sideways)]], 0.0--[[w (turn)]], 1.0, 1, true, true, true, true, 0, true)
        --util.yield_once()
        --ENTITY.ATTACH_ENTITY_TO_ENTITY(players.user_ped(), object, 0, 0.0--[[x]], 0.0--[[z]], 1.65--[[y]], 0.0--[[verticle (flip)]], 0.0--[[horizontal (go sideways)]], 0.0--[[w (turn)]], 1.0, 1, true, true, true, true, 0, true)
        --util.yield(0300)
        --menu.trigger_commands("cleararea")
--end)

menu.action(attachc, "Attach To Player", {""}, "Partial Synced (Person You Attach To Cannot See You Are Attached To Them)", function()
    ENTITY.ATTACH_ENTITY_TO_ENTITY(players.user_ped(), PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id), 0, 0.0, 1.0, 1.0, 2.0, 1.0,1, true, true, true, false, 0, true)
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
    menu.trigger_commands("tp " .. PLAYER.GET_PLAYER_NAME(player_id))
end)

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
            util.toast(players.get_name(player_id) .. " Repaired vehicle")
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

   	menu.action(vehicle, "Disable Vehicle", {}, "It's better than stand", function(toggle)
        --local p = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)
        local veh = PED.GET_VEHICLE_PED_IS_IN(p, false)
        if (PED.IS_PED_IN_ANY_VEHICLE(p)) then
            TASK.CLEAR_PED_TASKS_IMMEDIATELY(p)
        else
            local veh2 = PED.GET_VEHICLE_PED_IS_TRYING_TO_ENTER(p)
            entities.delete_by_handle(veh2)
        end
    end)

    menu.action(vehicle, "Disable Vehicle v2", {}, "Unblockable by stand '10/02'", function(toggle)
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
util.yield_once()

-------------------------------------------------------------------------------------------------------------------------------------------------

--==Menu's==--
util.yield(5000)
local selfc = menu.list(uwuself, "Main", {}, "Main Options.")
local weapons = menu.list(uwuself, "Weapons", {}, "")
local online = menu.list(uwuonline, "FewMod", {}, "Online mode options")
local world = menu.list(uwuworld, "FewMod", {}, "Options around you")
local detections = menu.list(uwuonline, "FewMod Detection", {}, "Lua Detections")
local protects = menu.list(uwuonline, "FewMod Protections", {}, "Lua Protections")
local vehicles = menu.list(uwuvehicle, "FewMod", {}, "Vehicle Options")
local fun = menu.list(uwuself, "Fun", {}, "Fun Stuff To Mess With")
local misc = menu.list(uwustand, "Misc", {}, "Useful and fast shortcuts")
--local update = menu.action(menu.my_root(), "Github Link", {}, "Link To Github For Manual Updates")
local running = menu.divider(menu.my_root(), "Script Running")
local versionnumber = menu.divider(menu.my_root(), "Version: "..localversion)

util.toast("FewMod Loaded")
util.log("FewMod Loaded")

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
        util.yield()
    end
    return NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(entity)
end

YOINK_PEDS = false
YOINK_VEHICLES = false
YOINK_OBJECTS = false
YOINK_PICKUPS = false

YOINK_RANGE = 500

Yoinkshit = false

local getEntityCoords = ENTITY.GET_ENTITY_COORDS
local getPlayerPed = PLAYER.GET_PLAYER_PED

local yoinkSettings = menu.list(uwuworld, "Force Request Control Settings", {}, "")


menu.toggle(yoinkSettings, "Force Request Control", {"controlall"}, "", function (yoink)
    if yoink then
        Yoinkshit = true
        util.create_thread(function()
            while Yoinkshit do
                local yoinksq = YOINK_RANGE^2
                local localCoord = getEntityCoords(getPlayerPed(players.user()))
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

menu.action(uwuworld, "Clean World/Super Cleanse", {"clearworld"}, "Literally cleans everything in the area including peds, cars, objects, bools etc.", function(on_click)
    clear_area(2000000)
    local vehicles = delete_entities_by_range(entities.get_all_vehicles_as_handles(), 1000000, "VEHICLE")
    local objects = delete_entities_by_range(entities.get_all_objects_as_handles(), 1000000, "OBJECT")
    local peds = delete_entities_by_range(entities.get_all_peds_as_handles(), 1000000, "PED")
    local player_pos = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user()), 1)
    GRAPHICS.REMOVE_PARTICLE_FX_IN_RANGE(player_pos.x, player_pos.y, player_pos.z, 1000000)
        local ct = 0
        for k,ent in pairs(entities.get_all_vehicles_as_handles()) do
            local driver = VEHICLE.GET_PED_IN_VEHICLE_SEAT(ent, -1)
            if not PED.IS_PED_A_PLAYER(driver) then
                entities.delete_by_handle(ent)
                ct += 1
            end
        end
        for k,ent in pairs(entities.get_all_peds_as_handles()) do
            if not PED.IS_PED_A_PLAYER(ent) then
                entities.delete_by_handle(ent)
            end
            ct += 1
        end
        for k,ent in pairs(entities.get_all_objects_as_handles()) do
            entities.delete_by_handle(ent)
            ct += 1
        end
        for i, entity in pairs(entities.get_all_objects_as_handles()) do
            request_control2(entity)
            entities.delete_by_handle(entity) 
        end
        local rope_alloc = memory.alloc(4)
        for i=0, 100 do 
            memory.write_int(rope_alloc, i)
            if PHYSICS.DOES_ROPE_EXIST(rope_alloc) then   
                PHYSICS.DELETE_ROPE(rope_alloc)
                ct += 1
            end
        end
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
                    util.toast(players.get_name(player_id) .. " Is Using a Modded Weapon ".. "(" .. util.reverse_joaat(WEAPON.GET_SELECTED_PED_WEAPON(ped, weapon_hash, false)) .. ")")
                    util.yield_once()
                    break
                    menu.trigger_commands("clearnotifications")
                end
            end
        end
    end
end)

menu.toggle_loop(detections, "Thunder Join", {}, "Detects if a player is using Thunder Join.", function()
    for _, player_id in ipairs(players.list(false, true, true)) do
        if not util.is_session_transition_active() and Fewd.get_spawn_state(player_id) == 0 and players.get_script_host() == player_id  then
            util.toast(players.get_name(player_id) .. " Is Using (Thunder Join) and Now Classified as a Modder.")
        end
    end
end)

--------------------------------------------------------------------------------------------------------------------------------
--Self
local bounty_local = nil
local bounty_timer = nil
local BOUNTY_LOCAL <constexpr> = 2793046 + 1886 + 17
local BOUNTY_TIMER <constexpr> = 2359296 + 1 + (0 * 5568) + 5150 + 13

inc_vehs = true
local rbp = menu.ref_by_path

menu.action(selfc, "Plutia", {"plutia"}, "Plutia From Neptunia \n(Ingnore If You Dont Have Neptunia DLC)", function()
        menu.trigger_commands("outfitplutia")
        menu.trigger_commands("allguns")
end)

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
        end
    end
end

local interiors = {
    {"Safe Space [AFK Room]", {x=-158.71494, y=-982.75885, z=149.13135}},
    {"Torture Room", {x=147.170, y=-2201.804, z=4.688}},
    {"Mining Tunnels", {x=-595.48505, y=2086.4502, z=131.38136}},
    {"Omegas Garage", {x=2330.2573, y=2572.3005, z=46.679367}},
    {"50 Car Garage", {x=520.0, y=-2625.0, z=-50.0}},
    {"Server Farm", {x=2474.0847, y=-332.58887, z=92.9927}},
    {"Character Creation", {x=402.91586, y=-998.5701, z=-99.004074}},
    {"Life Invader Building", {x=-1082.8595, y=-254.774, z=37.763317}},
    {"Mission End Garage", {x=405.9228, y=-954.1149, z=-99.6627}},
    {"Destroyed Hospital", {x=304.03894, y=-590.3037, z=43.291893}},
    {"Stadium", {x=-256.92334, y=-2024.9717, z=30.145584}},
    {"Comedy Club", {x=-430.00974, y=261.3437, z=83.00648}},
    {"Record A Studios", {x=-1010.6883, y=-49.127754, z=-99.40313}},
    {"Bahama Mamas Nightclub", {x=-1394.8816, y=-599.7526, z=30.319544}},
    {"Janitors House", {x=-110.20285, y=-8.6156025, z=70.51957}},
    {"Therapists House", {x=-1913.8342, y=-574.5799, z=11.435149}},
    {"Martin Madrazos House", {x=1395.2512, y=1141.6833, z=114.63437}},
    {"Floyds Apartment", {x=-1156.5099, y=-1519.0894, z=10.632717}},
    {"Michaels House", {x=-813.8814, y=179.07889, z=72.15914}},
    {"Franklins House (Strawberry)", {x=-14.239959, y=-1439.6913, z=31.101551}},
    {"Franklins House (Vinewood Hills)", {x=7.3125067, y=537.3615, z=176.02803}},
    {"Trevors House", {x=1974.1617, y=3819.032, z=33.436287}},
    {"Lesters House", {x=1273.898, y=-1719.304, z=54.771}},
    {"Lesters Warehouse", {x=713.5684, y=-963.64795, z=30.39534}},
    {"Lesters Office", {x=707.2138, y=-965.5549, z=30.412853}},
    {"Meth Lab", {x=1391.773, y=3608.716, z=38.942}},
    {"Acid Lab", {x=484.69, y=-2625.36, z=-49.0}},
    {"Morgue Lab", {x=495.0, y=-2560.0, z=-50.0}},
    {"Humane Labs", {x=3625.743, y=3743.653, z=28.69009}},
    {"Motel Room", {x=152.2605, y=-1004.471, z=-99.024}},
    {"Police Station", {x=443.4068, y=-983.256, z=30.689589}},
    {"Bank Vault", {x=263.39627, y=214.39891, z=101.68336}},
    {"Blaine County Bank", {x=-109.77874, y=6464.8945, z=31.626724}}, -- credit to fluidware for telling me about this one
    {"Tequi-La-La Bar", {x=-564.4645, y=275.5777, z=83.074585}},
    {"Scrapyard Body Shop", {x=485.46396, y=-1315.0614, z=29.2141}},
    {"The Lost MC Clubhouse", {x=980.8098, y=-101.96038, z=74.84504}},
    {"Vangelico Jewlery Store", {x=-629.9367, y=-236.41296, z=38.057056}},
    {"Airport Lounge", {x=-913.8656, y=-2527.106, z=36.331566}},
    {"Morgue", {x=240.94368, y=-1379.0645, z=33.74177}},
    {"Union Depository", {x=1.298771, y=-700.96967, z=16.131021}},
    {"Fort Zancudo Tower", {x=-2357.9187, y=3249.689, z=101.45073}},
    {"Agency Interior", {x=-1118.0181, y=-77.93254, z=-98.99977}},
    {"Agency Garage", {x=-1071.0494, y=-71.898506, z=-94.59982}},
    {"Terrobyte Interior", {x=-1421.015, y=-3012.587, z=-80.000}},
    {"Bunker Interior", {x=899.5518,y=-3246.038, z=-98.04907}},
    {"IAA Office", {x=128.20, y=-617.39, z=206.04}},
    {"FIB Top Floor", {x=135.94359, y=-749.4102, z=258.152}},
    {"FIB Floor 47", {x=134.5835, y=-766.486, z=234.152}},
    {"FIB Floor 49", {x=134.635, y=-765.831, z=242.152}},
    {"Big Fat White Cock", {x=-31.007448, y=6317.047, z=40.04039}},
    {"Strip Club DJ Booth", {x=121.398254, y=-1281.0024, z=29.480522}},
}

    menu.divider(online, "Normal Stuff")

    menu.action(online, "Check Lobby for GodMode", {}, "Checks the entire lobby for godmode, and notifies you of their names.", function()
        CheckLobbyForGodmode()
    end)

    menu.toggle_loop(online, "Toast Players When Joining", {}, "Toasts number of players when you join a new session.", function ()
        CheckLobbyForPlayers()
    end)

    block_blaming = menu.ref_by_path("Online>Protections>Block Blaming")
    menu.toggle_loop(online, "Disable Block Blaming While Shooting", {}, "Still keep the benefits of block blaming but also be able to deal damage to other players.", function()
        if PLAYER.IS_PLAYER_FREE_AIMING(players.user()) then
            block_blaming.value = false
        else
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
        util.yield(0500)
        if players.get_script_host() ~= players.user() and Fewd.get_spawn_state(players.user()) ~= 0 then
            menu.trigger_command(menu.ref_by_path("Players>"..players.get_name_with_tags(players.user())..">Friendly>Give Script Host"))
        else
            util.yield(0275)
            menu.trigger_commands("scripthost")
        end
    end)

    menu.toggle_loop(online, "Never Script Host", {}, "You never become the Script Host (Could Sometimes Help Prevent Kicks Related To Having Script Host) \nNote: Don't Use With Script Host Addiction, It Will Break The Session and Also Become Pointless", function()
        util.yield(0500)
        if players.get_script_host() == players.user() then
            menu.trigger_command(menu.ref_by_path("Players>"..players.get_name_with_tags(players.get_host())..">Friendly>Give Script Host"))
        end
    end)

    local moneywoo = menu.list(online, "Money & RP Options", {}, "Need I Say More?")

    function SET_INT_GLOBAL(global, value)
        memory.write_int(memory.script_global(global), value)
    end

    menu.toggle_loop(moneywoo, "Start $500k + $750k Loop", {""}, "500k + 750k Loop Every 10 Seconds. Warning! Dont spend over 50 million a day. If cash stops it will start again in 60 seconds. \nCould Be Risky Idk", function()
        SET_INT_GLOBAL(1968313, 1)
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
        SET_INT_GLOBAL(1968313, 2)
        util.log("$750K Added")
        util.yield(250)
        menu.trigger_commands("accepterrors")
        util.yield(250)
        menu.trigger_commands("accepterrors")
        util.yield(300)
        menu.trigger_commands("accepterrors")
        util.yield(150)
        menu.trigger_commands("accepterrors")
        util.yield(27500)
        SET_INT_GLOBAL(1968313, 2)
        util.log("$750K Added")
        util.yield(250)
        menu.trigger_commands("accepterrors")
        util.yield(250)
        menu.trigger_commands("accepterrors")
        util.yield(300)
        menu.trigger_commands("accepterrors")
        util.yield(150)
        menu.trigger_commands("accepterrors")
        util.yield(26500)
    end)

    menu.toggle(moneywoo, "Money Drop All", {"cashloopall"}, "Money drops all players", function()
        for _, pid in players.list(false, true, true) do
            local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)
            local pos = players.get_position(ped)
            if ENTITY.DOES_ENTITY_EXIST(ped) then
            menu.trigger_commands("cashloop " .. PLAYER.GET_PLAYER_NAME(player_id))
            end
        end
    end)

    local tps = menu.list(online, "Teleports", {}, "Places To TP To")

    for index, data in interiors do
        local location_name = data[1]
        local location_coords = data[2]
        menu.action(tps, location_name, {}, "", function()
            menu.trigger_commands("doors on")
            menu.trigger_commands("nodeathbarriers on")
            ENTITY.SET_ENTITY_COORDS_NO_OFFSET(players.user_ped(), location_coords.x, location_coords.y, location_coords.z, false, false, false)
        end)
    end

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
local sfchat = require("lib.ScaleformLib")("multiplayer_chat")
sfchat:draw_fullscreen()

local Languages = {
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
	{ Name = "English", Key = "en" },
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

function encode(text)
	return string.gsub(text, "%s", "+")
end
function decode(text)
	return string.gsub(text, "%+", " ")
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

targetlangaddict = menu.slider_text(chat_trans, "Target Language", {}, "You need to click to aply change", LangName, function(s)
	targetlang = LangLookupByName[LangKeys[s]]
end)

tradlocaaddict = menu.slider_text(settingtrad, "Location of Translated Message", {}, "You need to click to apply change", {"Global Chat networked", "Global Chat not networked", "Team Chat not networked", "Team Chat networked", "notification"}, function(s)
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
finallangaddict = menu.slider_text(traductmymessage, "Final Language", {"finallang"}, "Final Languge of your message.																	  You need to click to aply change", LangName, function(s)
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
								translationtext = players.get_name(packet_sender).." : "..decode(translation)
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
								chat.send_message(players.get_name(packet_sender).." : "..decode(translation), true, false, true)
								sfchat.ADD_MESSAGE(sender, translationtext, teamchatlabel, false, colorfinal)
							end if (Tradloca == 3) then
								sfchat.ADD_MESSAGE(sender, translationtext, allchatlabel, false, colorfinal)
							end if (Tradloca == 4) then
								botsend = true
								chat.send_message(players.get_name(packet_sender).." : "..decode(translation), false, false, true)
								sfchat.ADD_MESSAGE(sender, translationtext, allchatlabel, false, colorfinal)
							end if (Tradloca == 5) then
								util.toast(players.get_name(packet_sender).." : "..decode(translation), TOAST_ALL)
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

    ------------------------------------------------------------------------------------------------------------------------------------------------------
    
    menu.divider(online, "Lobby Crashes")
    
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
    end)
    
    menu.action(online, "Crash Sesion V1", {}, "", function(on_loop)
        PHYSICS.ROPE_LOAD_TEXTURES()
        local hashes = {2132890591, 2727244247}
        local pc = players.get_position(player_id)
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
        entities.delete_by_handle(veh); entities.delete_by_handle(ped)
        PHYSICS.DELETE_CHILD_ROPE(rope)
        PHYSICS.ROPE_UNLOAD_TEXTURES()
    end)
    
    menu.action(online, "Crash Sesion V2", {}, "", function(on_loop)
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
            util.yield_once()
        end
    end)

--------------------------------------------------------------------------------------------------------------------------------
--Weapons
handle_ptr = memory.alloc(13*8)

local function pid_to_handle(player_id)
    NETWORK.NETWORK_HANDLE_FROM_PLAYER(player_id, handle_ptr, 13)
    return handle_ptr
end

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
menu.slider_text(weapons, "Set Shooting Effect", {}, "", options, function (index)
	selectedOpt = index
end)

menu.divider(weapons, "Other")

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
            obj.prev = OBJECT.CREATE_OBJECT(obj_hash, camcoords.x, camcoords.y, camcoords.z, true, true, true)
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
        util.yield(20)
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

--------------------------------------------------------------------------------------------------------------------------------
--Protections

menu.action(uwuself, "Stop all sounds", {"stopsounds"}, "", function()
    for i=-1,100 do
        AUDIO.STOP_SOUND(i)
        AUDIO.RELEASE_SOUND_ID(i)
    end
end)

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
        util.toast("Detected clone. Cleaning up")
        entities.delete_by_handle(ped)
        util.yield(150)
        end
    end
end)

menu.action(uwuonline, "Anticrashcamera", {}, "Put this here for redundancy", function()
        menu.trigger_commands("anticrashcam")
end)

menu.toggle(uwuonline, "Toggle Anticrashcam", {"acc"}, "Put this here for redundancy", function(on_toggle)
    if on_toggle then
        menu.trigger_commands("anticrashcam on")
        menu.trigger_commands("potatomode on")
    else
        menu.trigger_commands("anticrashcam off")
        menu.trigger_commands("potatomode off")
    end
end)

menu.toggle(uwuonline, "Hide From Crashes", {}, "Tries to block crashes by Using some game natives and menu functions.", function(on_toggle)
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

menu.action(uwuonline, "Restart Natives", {}, "Tries restarting some natives.", function()
    --local playerpos = ENTITY.GET_ENTITY_COORDS(ped, false)
    local player = PLAYER.PLAYER_PED_ID()
    ENTITY.FREEZE_ENTITY_POSITION(player, false)
    MISC.OVERRIDE_FREEZE_FLAGS()
    menu.trigger_commands("rcleararea")
end)

menu.toggle(uwuonline, "Panic Mode", {"panic"}, "This renders an anti-crash mode removing all kinds of events from the game at all costs.", function(on_toggle)
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

menu.toggle_loop(protects, "Block PTFX/Particle Lag", {}, "Note: This Will Remove Any Particles In A Range", function()
    local coords = ENTITY.GET_ENTITY_COORDS(players.user_ped() , false);
    GRAPHICS.REMOVE_PARTICLE_FX_IN_RANGE(coords.x, coords.y, coords.z, 500)
    GRAPHICS.REMOVE_PARTICLE_FX_FROM_ENTITY(players.user_ped())
end)

menu.toggle_loop(protects, "Disable Projectiles", {}, "", function()
    --WEAPON.REMOVE_ALL_PROJECTILES_OF_TYPE(, true)
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
    end
end)

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

local anti_mugger = menu.list(protects, "Anti-Mugger")

menu.toggle_loop(anti_mugger, "To Me", {}, "Block Muggers targeting you.", function() -- thx nowiry for improving my method :D
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
                util.toast("Blocked mugger from " .. players.get_name(memory.read_int(sender)))
            end
        end)
    end
end)

menu.toggle_loop(anti_mugger, "Someone Else", {}, "Block Muggers targeted to someone else.", function()
    if NETWORK.NETWORK_IS_SCRIPT_ACTIVE("am_gang_call", 0, true, 0) then
        local ped_netId = memory.script_local("am_gang_call", 63 + 10 + (0 * 7 + 1))
        local sender = memory.script_local("am_gang_call", 287)
        local target = memory.script_local("am_gang_call", 288)
        local player = players.user()

        util.spoof_script("am_gang_call", function()
            if memory.read_int(target) ~= player and memory.read_int(sender) ~= player
            and NETWORK.NETWORK_DOES_NETWORK_ID_EXIST(memory.read_int(ped_netId)) 
            and NETWORK.NETWORK_REQUEST_CONTROL_OF_NETWORK_ID(memory.read_int(ped_netId)) then
                local mugger = NETWORK.NET_TO_PED(memory.read_int(ped_netId))
                entities.delete_by_handle(mugger)
                util.toast("Block mugger sent by " .. players.get_name(memory.read_int(sender)) .. " to " .. players.get_name(memory.read_int(target)))
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

local obj_limit = 635
menu.slider(pool_limiter, "Object Limit", {"objlimi"}, "", 0, 2500, 600, 1, function(amount)
    obj_limit = amount
end)

local projectile_limit = 15
menu.slider(pool_limiter, "Projectile Limit", {"projlimi"}, "", 0, 125, 40, 1, function(amount)
    projectile_limit = amount
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
menu.toggle_loop(uwuvehicle, "Object Collision", {"ghostobjects"}, "Disables collisions with objects", function()
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
		vehicle = entities.get_user_vehicle_as_handle(true)
		util.yield(2000)
	end
end)

menu.toggle_loop(uwuvehicle, "Loud radio", {"loudradio"}, "Enables loud radio (like lowriders have) on your current vehicle.", function()
	AUDIO.SET_VEHICLE_RADIO_LOUD(vehicle, true)
end, function()
	AUDIO.SET_VEHICLE_RADIO_LOUD(vehicle, false)
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
	VEHICLE.SET_VEHICLE_DIRT_LEVEL(vehicle, dirtAmount)
end)

local windows_root = menu.list(uwuvehicle, "Windows", {vcwindows}, "Roll down/disable windows.")

menu.toggle(windows_root, "All Windows", {"rollwinall"}, "", function(wa)
	if wa then
		VEHICLE.ROLL_DOWN_WINDOWS(vehicle)
	else
		for i=0,7 do
            VEHICLE.ROLL_UP_WINDOW(vehicle, i)
        end
	end
end)
menu.toggle(windows_root, "Front Left", {"rollwinfl"}, "", function(wfl)
	if wfl then
		VEHICLE.ROLL_DOWN_WINDOW(vehicle, 0)
	else
		VEHICLE.ROLL_UP_WINDOW(vehicle, 0)
	end
end)
menu.toggle(windows_root, "Front Right", {"rollwinfr"}, "", function(wfr)
	if wfr then
		VEHICLE.ROLL_DOWN_WINDOW(vehicle, 1)
	else
		VEHICLE.ROLL_UP_WINDOW(vehicle, 1)
	end
end)
menu.toggle(windows_root, "Rear Left", {"rollwinrl"}, "", function(wrl)
	if wrl then
		VEHICLE.ROLL_DOWN_WINDOW(vehicle, 2)
	else
		VEHICLE.ROLL_UP_WINDOW(vehicle, 2)
	end
end)
menu.toggle(windows_root, "Rear Right", {"rollwinrr"}, "", function(wrr)
	if wrr then
		VEHICLE.ROLL_DOWN_WINDOW(vehicle, 3)
	else
		VEHICLE.ROLL_UP_WINDOW(vehicle, 3)
	end
end)
menu.toggle(windows_root, "Mid Left", {"rollwinml"}, "", function(wml)
	if wml then
		VEHICLE.ROLL_DOWN_WINDOW(vehicle, 6)
	else
		VEHICLE.ROLL_UP_WINDOW(vehicle, 6)
	end
end)
menu.toggle(windows_root, "Mid Right", {"rollwinmr"}, "", function(wmr)
	if wmr then
		VEHICLE.ROLL_DOWN_WINDOW(vehicle, 7)
	else
		VEHICLE.ROLL_UP_WINDOW(vehicle, 7)
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

menu.toggle_loop(vehicles, "Silent GodMode", {}, "It will not be detected by most menus", function()
    ENTITY.SET_ENTITY_PROOFS(entities.get_user_vehicle_as_handle(), true, true, true, true, true, 0, 0, true)
    end, function() ENTITY.SET_ENTITY_PROOFS(PED.GET_VEHICLE_PED_IS_IN(players.user(), false), false, false, false, false, false, 0, 0, false)
end)

menu.toggle_loop(vehicles, "Remove Stickys From Car", {"removestickys"}, "", function(toggle)
    local car = PED.GET_VEHICLE_PED_IS_IN(players.user_ped(PLAYER.PLAYER_PED_ID(player_id), true))
    NETWORK.REMOVE_ALL_STICKY_BOMBS_FROM_ENTITY(car)
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

infcms = false
menu.toggle(vehicles, "Infinite Countermeasures", {"infinitecms"}, "It will give infinite countermeasures.", function(on)
    infcms = on
end)

if player_cur_car ~= 0 then
    if everythingproof then
        ENTITY.SET_ENTITY_PROOFS(player_cur_car, true, true, true, true, true, true, true, true)
    end
    --if racemode then
    --    VEHICLE.SET_VEHICLE_IS_RACING(player_cur_car, true)
    --end

    if infcms then
        if VEHICLE.GET_VEHICLE_COUNTERMEASURE_AMMO(player_cur_car) < 100 then
            VEHICLE.SET_VEHICLE_COUNTERMEASURE_AMMO(player_cur_car, 100)
        end
    end

    --if shift_drift then
    --    if PAD.IS_CONTROL_PRESSED(21, 21) then
    --        VEHICLE.SET_VEHICLE_REDUCE_GRIP(player_cur_car, true)
    --        VEHICLE._SET_VEHICLE_REDUCE_TRACTION(player_cur_car, 0.0)
    --    else
    --        VEHICLE.SET_VEHICLE_REDUCE_GRIP(player_cur_car, false)
    --    end
    --end
end

--force_cm = false
--menu.toggle(vehicles, "Force countermeasures", {"forcecms"}, "Force countermeasures on any vehicle to the horn key.", function(on)
--    force_cm = on
--    menu.trigger_commands("getgunsflaregun")
--end)

--if player_cur_car ~= 0 and force_cm then
--    if PAD.IS_CONTROL_PRESSED(46, 46) then
--        local target = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(PLAYER.PLAYER_PED_ID(player_id), math.random(-5, 5), -30.0, math.random(-5, 5))
--        --MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(target.x, target.y, target.z, target.x, target.y, target.z, 300.0, true, -1355376991, PLAYER.PLAYER_PED_ID(player_id), true, false, 100.0)
--        MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(target.x, target.y, target.z, target.x, target.y, target.z, 100.0, true, 1198879012, PLAYER.PLAYER_PED_ID(player_id), true, false, 100.0)
--    end
--end

--------------------------------------------------------------------------------------------------------------------------------------------------------
-- Real Helicopter Mode Start

get_vtable_entry_pointer = function(address, index)
    return memory.read_long(memory.read_long(address) + (8 * index))
end
get_sub_handling_types = function(vehicle, type)
    local veh_handling_address = memory.read_long(entities.handle_to_pointer(vehicle) + 0x938)
    local sub_handling_array = memory.read_long(veh_handling_address + 0x0158)
    local sub_handling_count = memory.read_ushort(veh_handling_address + 0x0160)
    local types = {registerd = sub_handling_count, found = 0}
    for i = 0, sub_handling_count - 1, 1 do
        local sub_handling_data = memory.read_long(sub_handling_array + 8 * i)
        if sub_handling_data ~= 0 then
            local GetSubHandlingType_address = get_vtable_entry_pointer(sub_handling_data, 2)
            local result = util.call_foreign_function(GetSubHandlingType_address, sub_handling_data)
            if type and type == result then return sub_handling_data end
            types[#types+1] = {type = result, address = sub_handling_data}
            types.found = types.found + 1
        end
    end
    if type then return nil else return types end
end
local thrust_offset = 0x8
local better_heli_handling_offsets = {
    ["fYawMul"] = 0x18, -- dont remember
    ["fYawStabilise"] = 0x20, --minor stabalization
    ["fSideSlipMul"] = 0x24, --minor stabalizaztion
    ["fRollStabilise"] = 0x30, --minor stabalization
    ["fAttackLiftMul"] = 0x48, --disables most of it
    ["fAttackDiveMul"] = 0x4C, --disables most of the other axis
    ["fWindMul"] = 0x58, --helps with removing some jitter
    ["fPitchStabilise"] = 0x3C --idk what it does but it seems to help
}
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
util.on_stop(function() 
    VEHICLEE.SET_VEHICLE_GRAVITY(veh, true)
    ENTITYY.SET_ENTITY_COLLISION(veh, true, true);
end)

--------------------------------------------------------------------------------------------------------------------------------
-- Drift Mode Start

local function getCurrentVehicle() 
	local player_id = PLAYER.PLAYER_ID()
	local player_ped = PLAYER.GET_PLAYER_PED(player_id)
    local player_vehicle = 0
    if (PED.IS_PED_IN_ANY_VEHICLE(player_ped)) then
        veh = PED.GET_VEHICLE_PED_IS_USING(player_ped)
        if (NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(veh)) then
            player_vehicle = veh
        end 
    end
    return player_vehicle
end

local function getHeadingOfTravel(veh) 
    local velocity = ENTITY.GET_ENTITY_VELOCITY(veh)
    local x = velocity.x
    local y = velocity.y
    local at2 = math.atan(y, x)
    return math.fmod(270.0 + math.deg(at2), 360.0)
end

local function slamDatBitch(veh, height) 
    if (VEHICLE.IS_VEHICLE_ON_ALL_WHEELS(veh) and not ENTITY.IS_ENTITY_IN_AIR(veh)) then
     
        ENTITY.APPLY_FORCE_TO_ENTITY(veh, 1,    0, 0, height,    0, 0, 0,   true, true)
    end
end

local function getCurGear()
    return memory.read_byte(entities.get_user_vehicle_as_pointer() +memory.read_int(CurrentGearOffset))
end

local function getNextGear()
    return memory.read_byte(entities.get_user_vehicle_as_pointer() +memory.read_int(NextGearOffset))
end

local function setCurGear(gear)
    memory.write_byte(entities.get_user_vehicle_as_pointer() +memory.read_int(CurrentGearOffset), gear)
end

local function setNextGear(gear)
    memory.write_byte(entities.get_user_vehicle_as_pointer() +memory.read_int(NextGearOffset), gear)
end

local function asDegrees(angle)
    return angle * (180.0 / 3.14159265357); 
end

local function wrap360(val) 
    --    this may be the same as:
    --      return math.fmod(val + 360, 360)
    --    but wierd things happen
    while (val < 0.0) do
        val = val + 360.0
    end
    while (val > 360.0) do
        val = val - 360.0
    end
    return val
end

--------------------------------------------------------------------------------------------------------------------------------
-- Fun Stuff

menu.action(fun, "Broomstick Mk2", {""}, "Note: You will be invisible for other players.", function()
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

local fpets = menu.list(fun, "Pets", {}, "Use 1 of them")

menu.toggle_loop(fpets, "Pet Husky (Dog)", {}, "", function()
    if not custom_pet or not ENTITY.DOES_ENTITY_EXIST(custom_pet) then
        local pet = util.joaat("a_c_Husky")
        request_model(pet)
        local pos = players.get_position(players.user())
        custom_pet = entities.create_ped(28, pet, pos, 0)
        PED.SET_PED_COMPONENT_VARIATION(custom_pet, 0, 0, 1, 0)
        ENTITY.SET_ENTITY_INVINCIBLE(custom_pet, true)
    end
    NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(custom_pet)
    TASK.TASK_FOLLOW_TO_OFFSET_OF_ENTITY(custom_pet, players.user_ped(), 0, -0.3, 0, 7.0, -1, 1.5, true)
    util.yield(2500)
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
        PED.SET_PED_COMPONENT_VARIATION(custom_pet, 0, 0, 1, 0)
        ENTITY.SET_ENTITY_INVINCIBLE(custom_pet, true)
    end
    NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(custom_pet)
    TASK.TASK_FOLLOW_TO_OFFSET_OF_ENTITY(custom_pet, players.user_ped(), 0, -0.3, 0, 7.0, -1, 1.5, true)
    util.yield(2500)
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
        PED.SET_PED_COMPONENT_VARIATION(custom_pet, 0, 0, 1, 0)
        ENTITY.SET_ENTITY_INVINCIBLE(custom_pet, true)
    end
    NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(custom_pet)
    TASK.TASK_FOLLOW_TO_OFFSET_OF_ENTITY(custom_pet, players.user_ped(), 0, -0.3, 0, 7.0, -1, 1.5, true)
    util.yield(2500)
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
        --PED.SET_PED_COMPONENT_VARIATION(custom_pet, 0, 0, 1, 0)
        ENTITY.SET_ENTITY_INVINCIBLE(custom_pet, true)
    end
    NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(custom_pet)
    TASK.TASK_FOLLOW_TO_OFFSET_OF_ENTITY(custom_pet, players.user_ped(), 0, -0.3, 0, 7.5, -1, 1.5, true)
    util.yield(2500)
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
        PED.SET_PED_COMPONENT_VARIATION(custom_pet, 0, 0, 1, 0)
        ENTITY.SET_ENTITY_INVINCIBLE(custom_pet, true)
    end
    NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(custom_pet)
    TASK.TASK_FOLLOW_TO_OFFSET_OF_ENTITY(custom_pet, players.user_ped(), 0, -0.3, 0, 6.5, -1, 1.5, true)
    util.yield(2500)
end, function()
    entities.delete_by_handle(custom_pet)
    custom_pet = nil
end)

menu.toggle_loop(fpets, "Pet Rabbit", {}, "", function()
    if not custom_pet or not ENTITY.DOES_ENTITY_EXIST(custom_pet) then
        local pet = util.joaat("A_C_Rabbit_02")
        request_model(pet)
        local pos = players.get_position(players.user())
        custom_pet = entities.create_ped(28, pet, pos, 0)
        PED.SET_PED_COMPONENT_VARIATION(custom_pet, 0, 0, 1, 0)
        ENTITY.SET_ENTITY_INVINCIBLE(custom_pet, true)
    end
    NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(custom_pet)
    TASK.TASK_FOLLOW_TO_OFFSET_OF_ENTITY(custom_pet, players.user_ped(), 0, -0.3, 0, 10.5, -1, 1.5, true)
    util.yield(2500)
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
        PED.SET_PED_COMPONENT_VARIATION(custom_pet, 0, 0, 1, 0)
        ENTITY.SET_ENTITY_INVINCIBLE(custom_pet, true)
    end
    NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(custom_pet)
    TASK.TASK_FOLLOW_TO_OFFSET_OF_ENTITY(custom_pet, players.user_ped(), 0, -0.3, 0, 7.0, -1, 1.5, true)
    util.yield(2500)
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
        PED.SET_PED_COMPONENT_VARIATION(custom_pet, 0, 0, 1, 0)
        ENTITY.SET_ENTITY_INVINCIBLE(custom_pet, true)
    end
    NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(custom_pet)
    TASK.TASK_FOLLOW_TO_OFFSET_OF_ENTITY(custom_pet, players.user_ped(), 0, -0.3, 0, 7.0, -1, 1.5, true)
    util.yield(2500)
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
        PED.SET_PED_COMPONENT_VARIATION(custom_pet, 0, 0, 1, 0)
        ENTITY.SET_ENTITY_INVINCIBLE(custom_pet, true)
    end
    NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(custom_pet)
    TASK.TASK_FOLLOW_TO_OFFSET_OF_ENTITY(custom_pet, players.user_ped(), 0, -0.3, 0, 7.0, -1, 1.5, true)
    util.yield(2500)
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
        --PED.SET_PED_COMPONENT_VARIATION(custom_pet, 0, 0, 1, 0)
        ENTITY.SET_ENTITY_INVINCIBLE(custom_pet, true)
    end
    NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(custom_pet)
    TASK.TASK_FOLLOW_TO_OFFSET_OF_ENTITY(custom_pet, players.user_ped(), 0, -0.3, 0, 6.5, -1, 1.5, true)
    util.yield(2500)
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
        PED.SET_PED_COMPONENT_VARIATION(custom_pet, 0, 0, 1, 0)
        ENTITY.SET_ENTITY_INVINCIBLE(custom_pet, true)
    end
    NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(custom_pet)
    TASK.TASK_FOLLOW_TO_OFFSET_OF_ENTITY(custom_pet, players.user_ped(), 0, -0.3, 0, 7.0, -1, 1.5, true)
    util.yield(2500)
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
        PED.SET_PED_COMPONENT_VARIATION(custom_pet, 0, 0, 1, 0)
        ENTITY.SET_ENTITY_INVINCIBLE(custom_pet, true)
    end
    NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(custom_pet)
    TASK.TASK_FOLLOW_TO_OFFSET_OF_ENTITY(custom_pet, players.user_ped(), 0, -0.3, 0, 7.0, -1, 1.5, true)
    util.yield(2500)
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
        PED.SET_PED_COMPONENT_VARIATION(custom_pet, 0, 0, 1, 0)
        ENTITY.SET_ENTITY_INVINCIBLE(custom_pet, true)
    end
    NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(custom_pet)
    TASK.TASK_FOLLOW_TO_OFFSET_OF_ENTITY(custom_pet, players.user_ped(), 0, -0.3, 0, 7.0, -1, 0, true)
    util.yield(2500)
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
        PED.SET_PED_COMPONENT_VARIATION(custom_pet, 0, 0, 1, 0)
        ENTITY.SET_ENTITY_INVINCIBLE(custom_pet, true)
    end
    NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(custom_pet)
    TASK.TASK_FOLLOW_TO_OFFSET_OF_ENTITY(custom_pet, players.user_ped(), 0, -0.3, 0, 7.0, -1, 1.5, true)
    util.yield(2500)
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
        PED.SET_PED_COMPONENT_VARIATION(custom_pet, 0, 0, 1, 0)
        ENTITY.SET_ENTITY_INVINCIBLE(custom_pet, true)
    end
    NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(custom_pet)
    TASK.TASK_FOLLOW_TO_OFFSET_OF_ENTITY(custom_pet, players.user_ped(), 0, -0.3, 0, 7.0, -1, 1.5, true)
    util.yield(2500)
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
        PED.SET_PED_COMPONENT_VARIATION(custom_pet, 0, 0, 1, 0)
        ENTITY.SET_ENTITY_INVINCIBLE(custom_pet, true)
    end
    NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(custom_pet)
    TASK.TASK_FOLLOW_TO_OFFSET_OF_ENTITY(custom_pet, players.user_ped(), 0, -0.3, 0, 7.0, -1, 1.5, true)
    util.yield(2500)
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
        PED.SET_PED_COMPONENT_VARIATION(custom_pet, 0, 0, 1, 0)
        ENTITY.SET_ENTITY_INVINCIBLE(custom_pet, true)
    end
    NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(custom_pet)
    TASK.TASK_FOLLOW_TO_OFFSET_OF_ENTITY(custom_pet, players.user_ped(), 0, -0.3, 0, 7.0, -1, 1.5, true)
    util.yield(2500)
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
        PED.SET_PED_COMPONENT_VARIATION(custom_pet, 0, 0, 1, 0)
        ENTITY.SET_ENTITY_INVINCIBLE(custom_pet, true)
    end
    NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(custom_pet)
    TASK.TASK_FOLLOW_TO_OFFSET_OF_ENTITY(custom_pet, players.user_ped(), 0, -0.3, 0, 7.0, -1, 1.5, true)
    util.yield(2500)
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
        PED.SET_PED_COMPONENT_VARIATION(custom_pet, 0, 0, 1, 0)
        ENTITY.SET_ENTITY_INVINCIBLE(custom_pet, true)
    end
    NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(custom_pet)
    TASK.TASK_FOLLOW_TO_OFFSET_OF_ENTITY(custom_pet, players.user_ped(), 0, -0.3, 0, 7.0, -1, 1.5, true)
    util.yield(2500)
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
        --PED.SET_PED_COMPONENT_VARIATION(custom_pet, 0, 0, 1, 0)
        ENTITY.SET_ENTITY_INVINCIBLE(custom_pet, true)
    end
    NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(custom_pet)
    TASK.TASK_FOLLOW_TO_OFFSET_OF_ENTITY(custom_pet, players.user_ped(), 0, -0.3, 0, 7.0, -1, 1.5, true)
    util.yield(2500)
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
        --PED.SET_PED_COMPONENT_VARIATION(custom_pet, 0, 0, 1, 0)
        ENTITY.SET_ENTITY_INVINCIBLE(custom_pet, true)
    end
    NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(custom_pet)
    TASK.TASK_FOLLOW_TO_OFFSET_OF_ENTITY(custom_pet, players.user_ped(), 0, -0.3, 0, 7.0, -1, 0, true)
    util.yield(2500)
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
        --PED.SET_PED_COMPONENT_VARIATION(custom_pet, 0, 0, 1, 0)
        ENTITY.SET_ENTITY_INVINCIBLE(custom_pet, true)
    end
    NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(custom_pet)
    TASK.TASK_FOLLOW_TO_OFFSET_OF_ENTITY(custom_pet, players.user_ped(), 0, -0.3, 0, 7.0, -1, 0, true)
    util.yield(2500)
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
        --PED.SET_PED_COMPONENT_VARIATION(custom_pet, 0, 0, 1, 0)
        ENTITY.SET_ENTITY_INVINCIBLE(custom_pet, true)
    end
    NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(custom_pet)
    TASK.TASK_FOLLOW_TO_OFFSET_OF_ENTITY(custom_pet, players.user_ped(), 0, -0.3, 0, 7.0, -1, 0, true)
    util.yield(2500)
end, function()
    entities.delete_by_handle(custom_pet)
    custom_pet = nil
end)

local pmenu = menu.list(fun, "Player Stuff", {}, "Change Into Some Fun Stuff \n(Only Use One At A Time)")

menu.toggle(pmenu, "Become A Monekey", {}, "Change Into A Money", function(on)
    if on then
        menu.trigger_commands("acchimp02")
    else
        menu.trigger_commands("outfit1candydinka")
        util.yield(0500)
        menu.trigger_commands("randomoutfit")
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
        menu.trigger_commands("outfit1candydinka")
        util.yield(0500)
        menu.trigger_commands("randomoutfit")
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
        menu.trigger_commands("outfit1candydinka")
        menu.trigger_commands("allguns")
        util.yield(0500)
        menu.trigger_commands("randomoutfit")
    end
end)

menu.toggle(pmenu, "Become A Mountain Lion", {}, "Change Into A Mountain Lion", function(on)
    if on then
        menu.trigger_commands("noguns")
        menu.trigger_commands("ACmtlion")
        menu.trigger_commands("walkstyle mop")
    else
        menu.trigger_commands("walkstyle poshfemale")
        menu.trigger_commands("outfit1candydinka")
        menu.trigger_commands("allguns")
        util.yield(0500)
        menu.trigger_commands("randomoutfit")
    end
end)

menu.toggle(pmenu, "Become A Panther", {}, "Change Into A Panther", function(on)
    if on then
        menu.trigger_commands("noguns")
        menu.trigger_commands("ACpanther")
        menu.trigger_commands("walkstyle mop")
    else
        menu.trigger_commands("walkstyle poshfemale")
        menu.trigger_commands("outfit1candydinka")
        menu.trigger_commands("allguns")
        util.yield(0500)
        menu.trigger_commands("randomoutfit")
    end
end)

menu.toggle(pmenu, "Become Westy (Dog)", {}, "Change Into Westy (Dog)", function(on)
    if on then
        menu.trigger_commands("noguns")
        menu.trigger_commands("ACWesty")
        menu.trigger_commands("walkstyle mop")
    else
        menu.trigger_commands("walkstyle poshfemale")
        menu.trigger_commands("outfit1candydinka")
        menu.trigger_commands("allguns")
        util.yield(0500)
        menu.trigger_commands("randomoutfit")
    end
end)

menu.toggle(pmenu, "Become A GermanShepherd (Dog)", {}, "Change Into A GermanShepherd (Dog)", function(on)
    if on then
        menu.trigger_commands("noguns")
        menu.trigger_commands("ACShepherd")
        menu.trigger_commands("walkstyle mop")
    else
        menu.trigger_commands("walkstyle poshfemale")
        menu.trigger_commands("outfit1candydinka")
        menu.trigger_commands("allguns")
        util.yield(0500)
        menu.trigger_commands("randomoutfit")
    end
end)

menu.toggle(pmenu, "Become A Rottweiler (Dog)", {}, "Change Into A Rottweiler (Dog)", function(on)
    if on then
        menu.trigger_commands("noguns")
        menu.trigger_commands("ACRottweiler")
        menu.trigger_commands("walkstyle mop")
    else
        menu.trigger_commands("walkstyle poshfemale")
        menu.trigger_commands("outfit1candydinka")
        menu.trigger_commands("allguns")
        util.yield(0500)
        menu.trigger_commands("randomoutfit")
    end
end)

menu.toggle(pmenu, "Become A Poodle (Dog)", {}, "Change Into A Poodle (Dog)", function(on)
    if on then
        menu.trigger_commands("noguns")
        menu.trigger_commands("ACPoodle")
        menu.trigger_commands("walkstyle mop")
    else
        menu.trigger_commands("walkstyle poshfemale")
        menu.trigger_commands("outfit1candydinka")
        menu.trigger_commands("allguns")
        util.yield(0500)
        menu.trigger_commands("randomoutfit")
    end
end)

menu.toggle(pmenu, "Become A Boar", {}, "Change Into A Boar", function(on)
    if on then
        menu.trigger_commands("noguns")
        menu.trigger_commands("ACBoar")
        menu.trigger_commands("walkstyle mop")
    else
        menu.trigger_commands("walkstyle poshfemale")
        menu.trigger_commands("outfit1candydinka")
        menu.trigger_commands("allguns")
        util.yield(0500)
        menu.trigger_commands("randomoutfit")
    end
end)

menu.toggle(pmenu, "Become Pug (Dog)", {}, "Change Into Pug (Dog)", function(on)
    if on then
        menu.trigger_commands("noguns")
        menu.trigger_commands("ACPug")
        menu.trigger_commands("walkstyle mop")
    else
        menu.trigger_commands("walkstyle poshfemale")
        menu.trigger_commands("outfit1candydinka")
        menu.trigger_commands("allguns")
        util.yield(0500)
        menu.trigger_commands("randomoutfit")
    end
end)

menu.toggle(pmenu, "Become Chop (Dog)", {}, "Change Into Chop (Dog)", function(on)
    if on then
        menu.trigger_commands("noguns")
        menu.trigger_commands("ACChop")
        menu.trigger_commands("walkstyle mop")
    else
        menu.trigger_commands("walkstyle poshfemale")
        menu.trigger_commands("outfit1candydinka")
        menu.trigger_commands("allguns")
        util.yield(0500)
        menu.trigger_commands("randomoutfit")
    end
end)

menu.toggle(pmenu, "Become A Coyote", {}, "Change Into A Coyote", function(on)
    if on then
        menu.trigger_commands("noguns")
        menu.trigger_commands("ACCoyote")
        menu.trigger_commands("walkstyle mop")
    else
        menu.trigger_commands("walkstyle poshfemale")
        menu.trigger_commands("outfit1candydinka")
        menu.trigger_commands("allguns")
        util.yield(0500)
        menu.trigger_commands("randomoutfit")
    end
end)

menu.toggle(pmenu, "Become A Deer", {}, "Change Into A Deer", function(on)
    if on then
        menu.trigger_commands("noguns")
        menu.trigger_commands("ACDeer")
        menu.trigger_commands("walkstyle mop")
    else
        menu.trigger_commands("walkstyle poshfemale")
        menu.trigger_commands("outfit1candydinka")
        menu.trigger_commands("allguns")
        util.yield(0500)
        menu.trigger_commands("randomoutfit")
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
        menu.trigger_commands("outfit1candydinka")
        util.yield(0500)
        menu.trigger_commands("randomoutfit")
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
        menu.trigger_commands("outfit1candydinka")
        util.yield(0500)
        menu.trigger_commands("randomoutfit")
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
        menu.trigger_commands("outfit1candydinka")
        util.yield(0500)
        menu.trigger_commands("randomoutfit")
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
        menu.trigger_commands("outfit1candydinka")
        util.yield(0500)
        menu.trigger_commands("randomoutfit")
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
        menu.trigger_commands("outfit1candydinka")
        menu.trigger_commands("allguns")
        util.yield(0500)
        menu.trigger_commands("randomoutfit")
    end
end)

menu.toggle(pmenu, "Become A Rabbit", {}, "Change Into A Rabbit", function(on)
    if on then
        menu.trigger_commands("noguns")
        menu.trigger_commands("ACRabbit")
        menu.trigger_commands("walkstyle mop")
    else
        menu.trigger_commands("walkstyle poshfemale")
        menu.trigger_commands("outfit1candydinka")
        menu.trigger_commands("allguns")
        util.yield(0500)
        menu.trigger_commands("randomoutfit")
    end
end)

menu.toggle(pmenu, "Become A Big Rabbit", {}, "Change Into A Big Rabbit", function(on)
    if on then
        menu.trigger_commands("noguns")
        menu.trigger_commands("ACRabbit02")
        menu.trigger_commands("walkstyle mop")
    else
        menu.trigger_commands("walkstyle poshfemale")
        menu.trigger_commands("outfit1candydinka")
        menu.trigger_commands("allguns")
        util.yield(0500)
        menu.trigger_commands("randomoutfit")
    end
end)

menu.toggle(pmenu, "Become A Furry", {}, "Change Into A Furry lol", function(on)
    if on then
        menu.trigger_commands("IGFurry")
        menu.trigger_commands("walkstyle mop")
    else
        menu.trigger_commands("walkstyle poshfemale")
        menu.trigger_commands("outfit1candydinka")
        util.yield(0500)
        menu.trigger_commands("randomoutfit")
    end
end)

menu.toggle(pmenu, "Become Yule Monster", {}, "Change Into Yule Monster", function(on)
    if on then
        menu.trigger_commands("UMMYuleMonster")
        menu.trigger_commands("walkstyle mop")
    else
        menu.trigger_commands("walkstyle poshfemale")
        menu.trigger_commands("outfit1candydinka")
        util.yield(0500)
        menu.trigger_commands("randomoutfit")
    end
end)

menu.toggle(pmenu, "Become Bigfoot", {}, "Change Into Bigfoot", function(on)
    if on then
        menu.trigger_commands("otr")
        menu.trigger_commands("igorleans")
    else
        menu.trigger_commands("otr")
        menu.trigger_commands("outfit1candydinka")
        util.yield(0500)
        menu.trigger_commands("randomoutfit")
    end
end)

menu.toggle(pmenu, "Become Trevor", {}, "Change Into Trevor", function(on)
    if on then
        menu.trigger_commands("trevor")
        menu.trigger_commands("walkstyle verydrunk")
    else
        menu.trigger_commands("walkstyle poshfemale")
        util.yield(0500)
        menu.trigger_commands("randomoutfit")
    end
end)

menu.toggle(pmenu, "Become Micheal", {}, "Change Into Micheal", function(on)
    if on then
        menu.trigger_commands("michael")
        menu.trigger_commands("walkstyle Micheal")
    else
        menu.trigger_commands("walkstyle poshfemale")
        util.yield(0500)
        menu.trigger_commands("randomoutfit")
    end
end)

menu.toggle(pmenu, "Become Franklin", {}, "Change Into Franklin", function(on)
    if on then
        menu.trigger_commands("franklin")
        menu.trigger_commands("walkstyle Franklin")
    else
        menu.trigger_commands("walkstyle poshfemale")
        util.yield(0500)
        menu.trigger_commands("randomoutfit")
    end
end)

menu.action(fun, "Random Outfit", {}, "Gives You A Random Outfit \n(Can Be Used To Leave Pigeon Mode)", function()
    menu.trigger_commands("outfit1candydinka")
    util.yield(0800)
    menu.trigger_commands("randomoutfit")
end)
--------------------------------------------------------------------------------------------------------------------------------
-- Misc

menu.action(misc, "Alternative Manual Update FewMod", {}, "Grabs The Newest Version Of Script From \nLink: https://github.com/Fewdys/GTA5-FewMod-Lua", function()
    async_http.init('raw.githubusercontent.com','/Fewdys/GTA5-FewMod/main/Few.lua',function(a)
        local err = select(2,load(a))
        if err then
            util.toast("There was a issue updating FewMod, please update it manually from github.")
            util.log("There was a issue updating FewMod, please update it manually from github.")
            util.toast("Link: https://github.com/Fewdys/GTA5-FewMod-Lua")
            util.log("Link: https://github.com/Fewdys/GTA5-FewMod-Lua")
        return end
        local f = io.open(filesystem.scripts_dir()..SCRIPT_RELPATH, "wb")
        f:write(a)
        f:close()
        util.toast("FewMod Updated Successfully. Restarting Script")
        util.log("FewMod Updated Successfully. Restarting Script")
        util.restart_script()
    end)
    async_http.dispatch()
end)

menu.toggle_loop(misc, "Clear All Notifications", {"clearnotifs"}, "I recommend you use Console so you can see the log on screen when people try to crash you with this enabled.", function()
    Clear_Stand_Notifs = menu.ref_by_path("Stand>Clear Notifications")
    Clear_Minimap_Notifs = menu.ref_by_path("Game>Remove Notifications Above Minimap")
        menu.trigger_command(Clear_Stand_Notifs)
        menu.trigger_command(Clear_Minimap_Notifs)
        util.yield(6500)
    end)

menu.toggle(misc, "Screenshot Mode", {}, "So you can take pictures <3", function(on)
	if on then
		menu.trigger_commands("screenshot on")
	else
		menu.trigger_commands("screenshot off")
	end
end)

menu.toggle(misc, "Stand ID", {}, "It makes you invisible to other stand users, but you won't detect them either.", function(on_toggle)
    local standid = menu.ref_by_path("Online>Protections>Detections>Stand User Identification")
    if on_toggle then
        menu.trigger_command(standid, "on")
    else
        menu.trigger_command(standid, "off")
    end
end)

util.on_stop(function ()
    VEHICLE.SET_VEHICLE_GRAVITY(veh, true)
    ENTITY.SET_ENTITY_COLLISION(veh, true, true);
    util.toast("Cleaning...")
end)

-------------------------------------------------------------------------------------------------------------------------------------------------------

-- Blip System

local colors = {
    value = {
        4, 55, 40, 41, 1, 76, 11, 2, 52, 18, 3, 78, 36, 5, 28, 7, 83, 58, 41, 8, 19, 9, 47, 64, 18, 38
    },
    name = {
        "White", "Grey", "Black", 
        "Light red", "Red", "Dark red", 
        "Light green", "Green", "Dark green",
        "Light blue", "Blue", "Dark blue",
        "Light yellow", "Yellow", "Dark yellow",
        "Light purple", "Purple", "Dark purple",
        "Light pink", "Pink", "Dark pink",
        "Light orange", "Orange", "Dark orange",
        "Cyan", "Navy blue"
    }   
}

local sprites = {
    value = {
        1, 270, 744, 133, 439, 304, 354, 489, 484, 570, 682, 781, 788, 652, 161
    },
    name = {
        "Circle", "Hollow Circle", "Camera", "Speech Bubble", "Crown", "Star", "Bolt", "Heart", "Ghost",
        "Badge", "Info", "Present", "Securoserv", "Arrow Sign", "Soundwave"
    }            
}

function table.find(t,v)
    for i, value in ipairs(t) do
        if value == v then
            return i
        end
    end
    return nil
end

-- Blip functions
local function nameExists(name)
    for _, data in ipairs(positionsData) do
        if data.name == name then
            return true
        end
    end

    for _, data in ipairs(bookmarksData) do
        if data.name == name then
            return true
        end
    end 

    return false
end

-- if name already exists, append a number to the end to make it unique
local function GetUniqueName(name)
    local newName = name
    local count = 1
    while nameExists(newName) do
        count = count + 1
        newName = name .. " " .. count
    end
    return newName
end

function TeleportToBlip(x, y, z)
    local playerPed = PLAYER.PLAYER_PED_ID()
    local playerPos = ENTITY.GET_ENTITY_COORDS(playerPed, true)
    local vehicle = PED.GET_VEHICLE_PED_IS_USING(playerPed)
    local coords = {x = x, y = y, z = z}

    if vehicle ~= 0 then
        ENTITY.SET_ENTITY_COORDS(vehicle, coords.x, coords.y, coords.z, false, false, false, true)
    else
        ENTITY.SET_ENTITY_COORDS(playerPed, coords.x, coords.y, coords.z, false, false, false, true)
    end
end

function RenameBlip(oldName, newName)
    if newName ~= nil and newName ~= "" then
        for i, data in ipairs(positionsData) do
            if data.name == oldName then
                data.name = newName
                WriteToFile()
                break
            end
        end
    end
end

function ShowExistingBookmarks(blipdataInfo, blipInstance, bookmarkMenu)
    for i, data in ipairs(createdBookmarks) do
        if blipdataInfo.bookmark ~= menu.get_menu_name(data) then
            local newBookmark = menu.action(bookmarkMenu, menu.get_menu_name(data), {}, "", function()
                local detachedMenu = menu.detach(blipInstance)
                detachedMenu = menu.attach(data, detachedMenu)
                blipdataInfo.bookmark = menu.get_menu_name(data)
                WriteToFile()

                util.toast("Successfully moved " ..blipdataInfo.name .. " to a new blip group")
            end)
            table.insert(bookmarksForBlips, newBookmark)
        end
    end
end

function RefreshExistingBookmarks()
    if #bookmarksForBlips > 0 then
        for i, data in ipairs(bookmarksForBlips) do
            menu.delete(data)
            bookmarksForBlips[i] = nil
        end
    end
end

function SetSpriteValues(blip, blipColor, blipSprite, blipScale)
    HUD.SET_BLIP_SPRITE(blip, blipSprite) -- Set the blip sprite to a standard waypoint
    HUD.SET_BLIP_COLOUR(blip, blipColor) -- Set the blip color to blue
    HUD.SET_BLIP_SCALE(blip, blipScale/10) -- Set the blip scale to normal size
    HUD.SET_BLIP_AS_SHORT_RANGE(blip, true) -- Set the blip as a long-range blip
    HUD.SET_BLIP_DISPLAY(blip, 2) -- Set the blip to show on both the map and minimap
end

function RemoveBlipSprite(blip)
    util.remove_blip(blip)
end

function MoveBlipToCurrentPos(storeBlipData, blipSprite)        
    local playerPed = PLAYER.PLAYER_PED_ID()
    local playerPos = ENTITY.GET_ENTITY_COORDS(playerPed, true)

    storeBlipData.x = playerPos.x
    storeBlipData.y = playerPos.y
    storeBlipData.z = playerPos.z

    HUD.SET_BLIP_COORDS(blipSprite, storeBlipData.x, storeBlipData.y, storeBlipData.z)
end

-- Menu components
menu.divider(world, "Blips")
local settingsWindow = menu.list(world, "Settings", {}, "General settings")
menu.divider(settingsWindow, "General Settings")

local removeWindow = menu.list(settingsWindow, "Remove blip data", {}, "WARNING - Removes all data of your saved positions")
menu.action(removeWindow, "Are you sure? This will remove ALL blips", {}, "", function()
    RemoveSavedBlipsList()
    RefreshFile()
end)

menu.on_blur(removeWindow, function()
    WriteToFile()
end)

local blipSettingsWindow
blipSettingsWindow = menu.list(world, "Blip defaults", {}, "Set up a default settings for your blip")
function CreateBlipSettingsMenu()
    -- Get the current config data

    if #configData == 0 then
        configData = {
            {color = defaultColor, sprite = defaultSprite, scale = defaulScale}
        }
    end

    local configInfo = {
        color = configData[1].color,
        sprite = configData[1].sprite,
        scale = configData[1].scale
    }

    local isChanged = false

    local colorSlider
    local spriteSlider
    local scaleSlider

    local currentColorIndex
    local currentSpriteIndex
    local currentSpriteScale

    currentColorIndex = table.find(colors.value, configInfo.color)
    currentSpriteIndex = table.find(sprites.value, configInfo.sprite)
    currentSpriteScale = configInfo.scale

    menu.divider(blipSettingsWindow, "Default appearance")

    colorSlider = menu.list_select(blipSettingsWindow, "Color", {}, "Set color for your blip", colors.name, currentColorIndex or defaultColor, function(selectedIndex)  
        configInfo.color = colors.value[selectedIndex]
        isChanged = true
    end)

    spriteSlider = menu.list_select(blipSettingsWindow, "Sprite", {}, "Set sprite for your blip", sprites.name, currentSpriteIndex or defaultSprite, function(selectedIndex)
        configInfo.sprite = sprites.value[selectedIndex]
        isChanged = true
    end)

    scaleSlider = menu.slider(blipSettingsWindow, "Scale ", {}, "Set scale of your blip", 6, 14, currentSpriteScale or defaulScale, 1, function(value)  
        configInfo.scale = value
        isChanged = true
    end)

    menu.divider(blipSettingsWindow, "Settings")

    menu.action(blipSettingsWindow, "Reset to default ", {}, "", function()  
        configInfo.color = defaultColor
        configInfo.sprite = defaultSprite
        configInfo.scale = 7.000000 -- can't use defaultScale for some reason?

        currentColorIndex = table.find(colors.value, defaultColor)
        currentSpriteIndex = table.find(sprites.value, defaultSprite)
        currentSpriteScale = 7.000000
    
        local refreshedColorSlider = menu.list_select(blipSettingsWindow, "Color", {}, "Set color for your blip", colors.name, currentColorIndex or defaultColor, function(selectedIndex)  
            configInfo.color = colors.value[selectedIndex]
            isChanged = true
        end)

        local detachedColorSlider = menu.detach(refreshedColorSlider)
        menu.replace(colorSlider, detachedColorSlider)
        colorSlider = refreshedColorSlider

        local refreshedSpriteSlider = menu.list_select(blipSettingsWindow, "Sprite", {}, "Set sprite for your blip", sprites.name, currentSpriteIndex or defaultSprite, function(selectedIndex)
            configInfo.sprite = sprites.value[selectedIndex]
            isChanged = true
        end)

        local detachedSpriteSlider = menu.detach(refreshedSpriteSlider)
        menu.replace(spriteSlider, detachedSpriteSlider)
        spriteSlider = refreshedSpriteSlider

        local refreshedScaleSlider = menu.slider(blipSettingsWindow, "Scale ", {}, "Set scale of your blip", 6, 14, currentSpriteScale or defaulScale, 1, function(value)  
            configInfo.scale = value
            isChanged = true
        end)

        local detachedScaleSlider = menu.detach(refreshedScaleSlider)
        menu.replace(scaleSlider, detachedScaleSlider)
        scaleSlider = refreshedScaleSlider
    
        isChanged = true
    end)    
    

    menu.on_focus(blipSettingsWindow, function()
        if isChanged then
            configData[1] = configInfo
            WriteToFile()
            isChanged = false
        end
    end)
    WriteToFile()
end

local allBlips = {}
local teleportToAllMenu
teleportToAllMenu = menu.list(world, "Quick teleport", {}, "Teleport to blip from any group", function()

    if #allBlips > 0 then
        for i, data in ipairs(allBlips) do
            menu.delete(data)
            allBlips[i] = nil
        end
    end

    for i, v in ipairs(positionsData) do
        local newblip = menu.action(teleportToAllMenu, v.bookmark .. " - " .. v.name, {}, "", function()
            TeleportToBlip(v.x,v.y,v.z)
        end)

        table.insert(allBlips, newblip)
    end
end)

menu.text_input(world, "Create blip group", {"create_blip_group"}, "", function(bookmarkName)
    if bookmarkName ~= nil and bookmarkName ~= "" then   
        
        for i, data in ipairs(bookmarksData) do
            if data.name == bookmarkName then
                bookmarkName = GetUniqueName(bookmarkName)
                break
            end
        end

        local bookmarkInfo = {
            name = bookmarkName
        }

        LoadBookmark(bookmarkInfo)
        table.insert(bookmarksData, bookmarkInfo)
        WriteToFile()
    end
end, "")

local blipGroups = menu.divider(world, "Blip groups")

function LoadBookmark(bookmarkInfo)
    local newBookmark = menu.list(world, bookmarkInfo.name)
    local currentBlipGroup = menu.divider(newBookmark, "Blip group - " ..bookmarkInfo.name)
    local quickTeleportList = {}

    menu.text_input(newBookmark, "Create new blip ", {"create_new_blip" ..bookmarkInfo.name}, "", function(blipName)   
        if blipName ~= nil and blipName ~= "" then
            local playerPed = PLAYER.PLAYER_PED_ID()
            local playerPos = ENTITY.GET_ENTITY_COORDS(playerPed, true)
            local x, y, z = playerPos.x, playerPos.y, playerPos.z
    
            for i, data in ipairs(positionsData) do
                if data.name == blipName then
                    blipName = GetUniqueName(blipName)
                    break
                end
            end
    
            local blipdataInfo = {
                name = blipName, 
                x = x, 
                y = y, 
                z = z,
                blip = blip,
                blipColor = configData[1].color,
                blipSprite = configData[1].sprite,
                blipScale = configData[1].scale,
                bookmark = bookmarkInfo.name
            }

            table.insert(positionsData, blipdataInfo)
            LoadBlip(blipdataInfo)     

            WriteToFile()
            util.toast("Current position saved")
        end
    end, "")

    local teleportList
    teleportList = menu.list(newBookmark, "Quick teleport", {}, "", function()
        local children = menu.get_children(newBookmark)

        if #children > 0 then
            for i, v in ipairs(children) do 
                for j,k in ipairs(positionsData) do
                    if k.name == menu.get_menu_name(v) then           
                        local tpEntry = menu.action(teleportList, menu.get_menu_name(v), {}, "", function()
                            TeleportToBlip(k.x, k.y, k.z)
                        end)
                        table.insert(quickTeleportList, tpEntry)
                    end
                end   
            end 
        end
    end)

    menu.on_focus(teleportList, function()
        for i,v in ipairs(quickTeleportList) do
            menu.delete(v)
            quickTeleportList[i] = nil
        end
    end)


    local settingsList = menu.list(newBookmark, "Group settings")
    menu.text_input(settingsList, "Rename blip group", {"rename_blip_group" ..bookmarkInfo.name}, "", function(newName)
        if newName ~= nil and newName ~= "" then

            for i, data in ipairs(bookmarkInfo) do
                if data.name == newName then
                    newName = GetUniqueName(newName)
                    break
                end
            end

            bookmarkInfo.name = newName
            menu.set_menu_name(newBookmark, newName)
            menu.set_menu_name(currentBlipGroup, "Blip group - " ..newName)

            local children = menu.get_children(newBookmark)

            for i, v in ipairs(children) do     
                for j,k in ipairs(positionsData) do
                    if k.name == menu.get_menu_name(v) then                    
                        k.bookmark = bookmarkInfo.name
                    end
                end   
            end  
            WriteToFile()
        end
    end)

    menu.divider(settingsList, "Blip group settings")
    local blipSettingsInBookmark = menu.list(settingsList, "Blip group appearance")

    menu.divider(blipSettingsInBookmark, "Blip group appearance")
    local currentColorIndex = table.find(colors.value, configData[1].color)

    local currentColor
    menu.list_select(blipSettingsInBookmark, "Color", {}, "Set color for your blip", colors.name, currentColorIndex or defaultColor, function(selectedIndex)  
        local blipGroup = menu.get_children(newBookmark)
        local selectedValue = colors.value[selectedIndex]
        for i, data in ipairs(blipGroup) do
            for j,k in ipairs(positionsData) do
                if k.bookmark == menu.get_menu_name(newBookmark) then
                    k.blipColor = selectedValue
                    currentColor = selectedValue
                    HUD.SET_BLIP_COLOUR(k.blip, selectedValue)
                end
            end
        end
    end)

    local currentSpriteIndex = table.find(sprites.value, configData[1].sprite)
    menu.list_select(blipSettingsInBookmark, "Sprite", {}, "Set sprite for your blip", sprites.name, currentSpriteIndex or defaultSprite, function(selectedIndex)
        local selectedValue = sprites.value[selectedIndex]
        for i, data in ipairs(positionsData) do
            if data.bookmark == menu.get_menu_name(newBookmark) then
                data.blipSprite = selectedValue
                HUD.SET_BLIP_SPRITE(data.blip, selectedValue)
                HUD.SET_BLIP_COLOUR(data.blip, currentColor)
            end
        end
    end)


    local currentSpriteScale = configData[1].scale
    menu.slider(blipSettingsInBookmark, "Scale ", {}, "Set scale of your blip", 6, 14, currentSpriteScale or defaulScale, 1, function(value)  
        local blipGroup = menu.get_children(newBookmark)
        for i, data in ipairs(blipGroup) do
            for j,k in ipairs(positionsData) do
                if k.bookmark == menu.get_menu_name(newBookmark) then
                    k.blipScale = value
                    HUD.SET_BLIP_SCALE(k.blip, value/10)
                end
            end
        end
    end)

    local currentBookmarksList
    currentBookmarksList = menu.list(settingsList, "Move blips to a different blip group", {}, "", function()
        local children = menu.get_children(newBookmark)
        RefreshExistingBookmarks()
        for i, data in ipairs(createdBookmarks) do
            if data ~= newBookmark then
                local listBookmark = menu.action(currentBookmarksList, menu.get_menu_name(data), {}, "", function()
                    for i, v in ipairs(children) do     
                        for j,k in ipairs(positionsData) do
                            if k.name == menu.get_menu_name(v) then                    
                                local detachedChild = menu.detach(v)
                                detachedChild = menu.attach(data, detachedChild)
                                k.bookmark = menu.get_menu_name(data)
                            end
                        end
                    end    
                    util.toast("Successfully moved blips to a new blip group : " ..menu.get_menu_name(data))
                end)
                table.insert(bookmarksForBlips, listBookmark)
            end
        end
    end)

    menu.divider(currentBookmarksList, "Current group - " ..bookmarkInfo.name)


    menu.divider(settingsList, "Removal")
    menu.action(settingsList, "Remove this blip group", {}, "WARNING : This also removes blips. Use 'Move blips to a different blip group' to preserve removing them", function() 
        local children = menu.get_children(newBookmark)
        for i, v in ipairs(children) do     
            for j,k in ipairs(positionsData) do
                if k.name == menu.get_menu_name(v) then
                    table.remove(positionsData, j)
                    util.remove_blip(k.blip)
                end
            end   
        end
        
        menu.delete(newBookmark)
        for i, data in ipairs(bookmarksData) do
            if data.name == bookmarkInfo.name then
                table.remove(bookmarksData, i)
                table.remove(createdBookmarks, i)
                WriteToFile()
                break
            end
        end    
    end)

    table.insert(createdBookmarks, newBookmark)
    menu.divider(newBookmark, "Saved Blips")  
    menu.on_blur(newBookmark, function()
        WriteToFile()
    end)
end

function LoadBlip(blipdataInfo)
    local blipSprite = HUD.ADD_BLIP_FOR_COORD(blipdataInfo.x, blipdataInfo.y, blipdataInfo.z)
    blipdataInfo.blip = blipSprite

    local blipInstance
    for i, data in ipairs(createdBookmarks) do
        if blipdataInfo.bookmark == menu.get_menu_name(data) then
            blipInstance = menu.list(data, blipdataInfo.name)
        end
    end

    local teleportAction = menu.action(blipInstance, "Teleport to " ..blipdataInfo.name, {}, "Teleports you to selected blip", function()
        TeleportToBlip(blipdataInfo.x,blipdataInfo.y,blipdataInfo.z)
    end)

    menu.divider(blipInstance, "Blip Appearance")
    local textAction = menu.text_input(blipInstance, "Rename blip ", {"rename_current_blip"..blipdataInfo.name}, "Name your blip", function(newName) 
        blipdataInfo.name = newName
        menu.set_menu_name(blipInstance, newName)
        menu.set_menu_name(teleportAction, "Teleport to " ..newName)
    end, blipdataInfo.name)

    local currentColorIndex = table.find(colors.value, blipdataInfo.blipColor)
    local chosenColor = blipdataInfo.blipColor or defaultColor
    
    menu.list_select(blipInstance, "Blip color ", {}, "Set color for your blip", colors.name, currentColorIndex or defaultColor, function(selectedIndex)  
        local selectedValue = colors.value[selectedIndex]
        HUD.SET_BLIP_COLOUR(blipSprite, selectedValue)
        blipdataInfo.blipColor = selectedValue
        chosenColor = selectedValue
    end)
    
    local currentSpriteIndex = table.find(sprites.value, blipdataInfo.blipSprite)
    menu.list_select(blipInstance, "Blip sprite ", {}, "Set sprite for your blip", sprites.name, currentSpriteIndex or defaultSprite, function(selectedIndex)  
        local selectedValue = sprites.value[selectedIndex]
        HUD.SET_BLIP_SPRITE(blipSprite, selectedValue)
        HUD.SET_BLIP_COLOUR(blipSprite, chosenColor)
        blipdataInfo.blipSprite = selectedValue
    end)

    local currentSpriteScale = blipdataInfo.blipScale
    menu.slider(blipInstance, "Blip scale ", {}, "Set scale of your blip", 6, 14, currentSpriteScale or defaulScale, 1, function(value)  
        HUD.SET_BLIP_SCALE(blipSprite, value/10)
        blipdataInfo.blipScale = value
    end)   

    menu.toggle(blipInstance, "Is visible ", {}, "Will you see the blip?", function(isChecked)
        if isChecked then
            HUD.SET_BLIP_ALPHA(blipSprite, 255)
        else
            HUD.SET_BLIP_ALPHA(blipSprite, 0)
        end
    end, true)

    menu.divider(blipInstance, "Settings")
    menu.action(blipInstance, "Move blip to current location", {}, "", function()
        MoveBlipToCurrentPos(blipdataInfo, blipSprite)
    end)

    local bookmarkMenu
    bookmarkMenu = menu.list(blipInstance, "Move to a different blip group", {}, "", function()
        ShowExistingBookmarks(blipdataInfo, blipInstance, bookmarkMenu)
    end)
    menu.divider(bookmarkMenu, "Current group - " ..blipdataInfo.bookmark)

    menu.on_focus(bookmarkMenu, function()
        RefreshExistingBookmarks()
    end)

    menu.action(blipInstance, "Remove ", {}, "Removes current blip", function()
        RemoveBlipSprite(blipSprite)
        RemoveFromList(blipInstance, blipdataInfo.name)
        menu.delete(blipInstance)
    end)

    SetSpriteValues(blipSprite, blipdataInfo.blipColor, blipdataInfo.blipSprite, blipdataInfo.blipScale)
    table.insert(spriteTable, blipSprite)
    table.insert(listData, blipInstance)
    menu.on_blur(blipInstance, function()
        WriteToFile()
    end)
end

-- Removal Functions
function RemoveSavedBlipsList()
    if #listData > 0 then
        for i, data in ipairs(listData) do
            menu.delete(data)
        end
    end

    for i, blip in ipairs(spriteTable) do
        util.remove_blip(blip)
    end

    for i, data in ipairs(createdBookmarks) do
        menu.delete(data)
    end

    spriteTable = {}
    listData = {}
    positionsData = {}
    bookmarksData = {}
    configData = {}
    createdBookmarks = {}

    if #configData == 0 then
        configData = {
            {color = defaultColor, sprite = defaultSprite, scale = defaulScale}
        }
    end
end

function RemoveFromList(blipInstance, name)
    for i, data in ipairs(positionsData) do
        if data.name == name then
            table.remove(positionsData, i)
            break
        end
    end

    for i, instance in ipairs(listData) do
        if instance == blipInstance then
            table.remove(listData, i)
            break
        end
    end
    WriteToFile()
end

-- Data handling functions
-- Write the positions data to a file

util.on_pre_stop(function()
    WriteToFile()

    for i, blip in ipairs(spriteTable) do
        util.remove_blip(blip)
    end

    spriteTable = {}
end)

function WriteToFile()
    file = io.open(path6, "w")
    file:write("configTable = {\n")
    for k, v in ipairs(configData) do
        file:write(string.format("{color = %d, sprite = %d, scale = %f},\n",
            v.color, v.sprite, v.scale))
    end
    file:write("}\n")
    file:write("dataTable = {\n")
    for k, v in ipairs(positionsData) do
        file:write(string.format("{name = \"%s\", x = %f, y = %f, z = %f, blip = %s, blipColor = %d, blipSprite = %d, blipScale = %f, bookmark = \"%s\"},\n",
            v.name, v.x, v.y, v.z, v.blip, v.blipColor, v.blipSprite, v.blipScale, v.bookmark))
    end
    file:write("}\n")
    file:write("bookmarkTable = {\n")
    for k, v in ipairs(bookmarksData) do
        file:write(string.format("{name = \"%s\"},\n",
            v.name))
    end
    file:write("}\n")
    file:close()
end

-- Clear the file back to default
function RefreshFile()
    file = io.open(path6, "w")
    file:write("dataTable = {}\n")
    file:write("bookmarkTable = {}\n")
    file:write("configTable = {}")
    file:close()
end

-- Read the positions data from the file
function ReadPositionsData()
    if file then
        io.close(file)
        dofile(path6)

        configData = configTable
        if #configData == 0 then
            configData = {
                {color = defaultColor, sprite = defaultSprite, scale = defaulScale}
            }
        end

        bookmarksData = bookmarkTable

        for i, bookmark in ipairs(bookmarksData) do
            LoadBookmark(bookmark)
        end

        positionsData = dataTable
        for i, data in ipairs(positionsData) do
            LoadBlip(data)
        end

        util.toast("Saved positions have been loaded")
    else
        RefreshFile()
        util.toast("No position_data found, creating new file")
    end
end

ReadPositionsData()
CreateBlipSettingsMenu()


--------------------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------------------

menu.divider(path, "Random Warping")

menu.slider_float(path, "Random Radius", {"radius"}, "sets the radius the random position can be in", 0, 10000, 1000, 100, function (value)
    radius = value / 100;
end)

menu.slider(path, "Randomm Interval (ms)", {"interval (ms)"}, "sets interval between warps", 0, 15000, 2000, 50, function (value)
    interval = value
end)

-- stolen from wiri scirpt sorry your code is in this mess
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
        random_pos();
        menu.trigger_commands("spoofedposition " .. tostring(changed_pos.x) .. ", " .. tostring(changed_pos.y) .. ", " .. tostring(changed_pos.z))
        util.yield(interval)
    else
        util.toast("Failed Lmao")
    end
end)

--------------------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------------------

menu.divider(path, "Slight Offse")

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
--------------------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------------------
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

while true do
    pos = players.get_position(players.user())

    if beacon then
        util.draw_ar_beacon(changed_pos) 
    end

    util.yield()
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------