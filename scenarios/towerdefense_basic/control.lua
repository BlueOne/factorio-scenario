-- control.lua

-- Tower Defense Scenario control
-- Contains meta game logic such as lobby and difficulty selection
-- Actual game logic is in game_control.lua


-- Modules
-------------------------------------------------------------------------------


local Table = require("Utils/Table")
local VoteUI = require("Utils/VoteUI")

local Event = require("stdlib/event/event")
local StdString = require("stdlib/utils/string")

local WaveCtrl = require("wave_control")
local UpgradeSystem = require("upgrade_system")

local TableGUI = require("Utils/TableViewer")

local GameControl = require("game_control")


-- TODO
-------------------------------------------------------------------------------

-- License

-- Testing round 2

-- Difficulties



-- Lobby

-- Determine Wave Group movement ticks in advance so they are timed evenly

-- Sort upgrade ui.

-- Multiplayer Debugging
-- Player Name

-- Low Priority:
-- reset surface
-- Rocket silo death animation nuke?
-- Gfx effects for upgrade purchase at affected entity.
-- (Edit forces of entities and active/inactive)
-- Observers


-- Done: 
-- Wave System
-- Upgrade and Money System
-- Upgrade Data
-- Forces, players set up
-- Starting inventory and equipment system
-- inventory and equipment data
-- Cliff Tools
-- Map
-- Loot on map
-- Map script data
-- Rocket Turret
-- System Sounds
-- Upgrade UI
-- Wave UI
-- Hints
-- Voting UI
-- Difficulty ui




-- Command Collection

-- New Decoratives
-- /c game.player.surface.destroy_decoratives({{-1000, -1000}, {1000, 1000}}); game.player.surface.regenerate_decorative()

-- Make cliffs on lane marker surface
-- /c for _,ent in pairs(game.surfaces["lane-markers"].find_entities_filtered{name="cliff"}) do ent.destroy() end for _, ent in pairs(game.surfaces.nauvis.find_entities_filtered{name="cliff"}) do game.surfaces["lane-markers"].create_entity{name=ent.name, force=ent.force, position=ent.position, cliff_orientation = ent.cliff_orientation} end

-- Save Buffers
-- /c 
-- local t = {}
-- for _, ent in pairs(game.player.surface.find_entities_filtered{name="centrifuge"}) do table.insert(t, ent.position) end
-- game.write_file("buffers.txt", serpent.line(t))

-- Remove a few buttons
-- /c game.player.gui.top.mod_gui_button_flow["creative-mode-fix_main-menu-open-button"].destroy(); game.player.gui.top.mod_gui_button_flow.silo_gui_sprite_button.destroy()

-- Cheat Mode and Techs
-- /c game.player.cheat_mode = true; game.player.force.research_all_technologies(); game.player.force.research_all_technologies(); game.player.force.research_all_technologies()



local System = {}
System.constants = {
    lobby_positions = { -- Available positions on lobby surface
        {17, -50},
        {5, 90},
        {-134, 22}
    },
}


Event.register(defines.events.on_player_joined_game, function(event)
    local player = game.players[event.player_index]
    local game_control = global.game_control
    if game_control then
        GameControl.player_enter_game(game_control, player)
    else
        System.move_player_to_lobby(player)
    end
end)



-- TODO
-- local function post_end_game()



Event.register(VoteUI.on_vote_finished, function(event)
    if event.vote_name == GameControl.game_constants.difficulty_vote_cfg.name then
        game.print("Selected " .. event.option_name)
    else 
        return
    end

    local difficulty_settings = event.option

    local system = global.system

    global.game_control = {
        player_force = system.player_force,
        enemy_force = system.enemy_force,
        wave_force = system.wave_force,
        neutral_force = system.neutral_force,
        ally_force = system.ally_force,
        surface = system.surface,
        lane_marker_surface = system.lane_marker_surface,
        player_permission_group = system.player_permission_group,
        -- ended = false,
        -- game_constants = game_constants,
        -- active_players = {},
        -- rocket_silo = nil,
        -- artillery_turret = nil
    }

    GameControl.restart(global.game_control, difficulty_settings)
end)





-- Lobby and Difficulty Select
-------------------------------------------------------------------------------

function System.move_player_to_lobby(player)
    local pos = System.constants[global.system.lobby_position_index]
    player.teleport(pos, global.system.lobby_surface)

    player.minimap_enabled = false

    -- Make sure UIs are destroyed
    WaveCtrl.destroy_ui(player)
    UpgradeSystem.destroy_ui(player)

    -- Set permissions
end


function System.prepare_lobby_surface(surface)
    for _, ent in pairs(surface.find_entities_filtered{name="nuclear-reactor"}) do
        ent.temperature = 450
    end

    for _, ent in pairs(surface.find_entities_filtered{type="unit-spawner"}) do
        ent.active = false
    end

    for _, ent in pairs(surface.find_entities_filtered{type="ammo-turret"}) do
        ent.insert("firearm-magazine")
    end
    for _, ent in pairs(surface.find_entities_filtered{car="gun-turret"}) do
        ent.insert("firearm-magazine")
    end
end


-- System
-------------------------------------------------------------------------------


function System.init()
    local lobby_surface = game.surfaces["lobby"] or game.create_surface("lobby")
    local player_permission_group = game.permissions.get_group("player_group") or game.permissions.create_group("player_group")
    player_permission_group.set_allows_action(defines.input_action.open_blueprint_library_gui, false)

    local system = {
        player_force = game.forces.player,
        enemy_force = game.forces.enemy,
        neutral_force = game.forces.neutral,
        wave_force = game.forces["wave-enemy"] or game.create_force("wave-enemy"),
        ally_force = game.forces.ally or game.create_force("ally"),
        surface = game.surfaces.nauvis,
        lobby_surface = lobby_surface,
        lane_marker_surface = game.surfaces["lane-markers"],
        player_permission_group = player_permission_group,
        -- saved_entities = {force = {}},
        -- lobby_position_index = 1,
    }

    global.system = system

    System.prepare_lobby_surface(lobby_surface)

    for _, player in pairs(game.players) do
        -- More Band-aid for ui
        if player.gui.top.mod_gui_button_flow then
            for _, button in pairs(player.gui.top.mod_gui_button_flow.children) do
                if button and button.valid and button.name == "creative-mode-fix_main-menu-open-button" then button.destroy() end
            end
        end
    end

    local cfg = Table.copy(GameControl.game_constants.difficulty_vote_cfg)
    cfg.force = system.player_force
    VoteUI.init_vote(cfg.name, cfg, GameControl.game_constants.difficulty_vote_options)
end


Event.register(-10, function() 
    if not global.system then 
        System.init()
    end
end)



commands.add_command("dbg_wv", "Debug Wave Controller", function(event) 
    local player = game.players[event.player_index]
    if not player.admin then return end
    player.print(serpent.block(global.game_control.wave_control)) 
end)

commands.add_command("show_const", "Show Scenario Constants", function(event) 
    local player = game.players[event.player_index]
    if not player.admin then return end
    local ui = TableGUI.create("Scenario Constants")
    TableGUI.create_ui(ui, player)
    TableGUI.add_table(ui, "Scenario Constants", GameControl.game_constants)
end)

commands.add_command("show_game_globals", "Show Game State", function(event) 
    local player = game.players[event.player_index]
    if not player.admin then return end
    local ui = TableGUI.create("Game Globals")
    TableGUI.create_ui(ui, player)
    TableGUI.add_table(ui, "Game Control", global.game_control)
end)

commands.add_command("testing", "Cheats! Desyncs on player join.", function(event)
    local player = game.players[event.player_index]
    if not player.admin then return end
    local game_control = global.game_control
    if game_control then
        UpgradeSystem.give_money(game_control.player_force, 1000)
    end
    game_control.wave_control.next_wave_tick = game.tick + 3 * 60 * 60
    game_control.game_constants.wave_duration = 3 * 60 * 60
    for _, pl in pairs(game_control.player_force.players) do 
        pl.cheat_mode = true
    end
end)

commands.add_command("startvote", "Start a vote for all players to participate in. Example '/startvote Which Technology? |Nuclear|Rocket|Flamethrower'", function(event)
    local player = game.players[event.player_index]
    if not event.parameter then 
        player.print("Invalid Input!")
        return
    end
    local options_list = StdString.split(event.parameter, "|")
    if #options_list < 1 then
        player.print("Invalid Input!")
        return
    end

    if Table.count_keys(global.VoteUI.votes) >= 1 then 
        player.print("There is already an active vote!")
        return 
    end

    local vote_name = options_list[1]
    if #StdString.trim(vote_name) < 10 then
        player.print("Invalid title.")
        return
    end
    local options = {}
    for i, n in pairs(options_list) do 
        if i > 1 then
            options[n] = {name = n, title = n, }
        end
    end

    local cfg = {
        title = vote_name,
        description = "Vote started by " .. player.name,
        force="player",
        duration = 60,
        sprite = "item/power-armor",
        mode = "timeout"
    }

    VoteUI.init_vote("player-vote", cfg, options)
end)