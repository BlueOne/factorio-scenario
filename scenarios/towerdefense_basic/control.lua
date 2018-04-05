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

local cfg = require("cfg")


-- TODO
-------------------------------------------------------------------------------


-- License

-- Map: Work On Paths, map frame SW
-- Sprite for alien artifact
-- Make lobby pos nicer
-- Format Vote GUI title
-- Structure this file
-- Testing round 2

-- Difficulties




-- Determine Wave Group movement ticks in advance so they are timed evenly
-- Multiplayer Debugging
-- Player Name
-- Last Used

-- Low Priority:
-- Sort upgrade ui.
-- Observers
-- Rocket silo death animation heavier?
-- Gfx effects for upgrade purchase at affected entity.
-- (Edit forces of entities and active/inactive)


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
        {17, -55},
        -- {2, 98},
        -- {-134, 22}
    },

    game_destroy_delay = 60*60,

    player_forbidden_actions = {
        defines.input_action.open_blueprint_library_gui
    },
    observer_forbidden_actions = {
        defines.input_action.add_permission_group,
        -- defines.input_action.alt_select_area,
        -- defines.input_action.alt_select_blueprint_entities,
        defines.input_action.begin_mining,
        defines.input_action.begin_mining_terrain,
        defines.input_action.build_item,
        defines.input_action.build_rail,
        defines.input_action.build_terrain,
        defines.input_action.cancel_craft,
        defines.input_action.cancel_deconstruct,
        -- defines.input_action.cancel_new_blueprint,
        -- defines.input_action.cancel_research	
        -- defines.input_action.change_active_item_group_for_crafting,
        -- defines.input_action.change_active_item_group_for_filters,
        -- defines.input_action.change_active_quick_bar,
        defines.input_action.change_arithmetic_combinator_parameters,
        -- defines.input_action.change_blueprint_book_record_label,
        defines.input_action.change_decider_combinator_parameters,
        -- defines.input_action.change_item_label,
        defines.input_action.change_picking_state,
        defines.input_action.change_programmable_speaker_alert_parameters,
        defines.input_action.change_programmable_speaker_circuit_parameters,
        defines.input_action.change_programmable_speaker_parameters,
        defines.input_action.change_riding_state,
        defines.input_action.change_shooting_state,
        -- defines.input_action.change_single_blueprint_record_label,
        defines.input_action.change_train_stop_station,
        defines.input_action.change_train_wait_condition,
        defines.input_action.change_train_wait_condition_data,
        -- defines.input_action.clean_cursor_stack,
        -- defines.input_action.clear_selected_blueprint,
        -- defines.input_action.clear_selected_deconstruction_item,
        defines.input_action.connect_rolling_stock,
        defines.input_action.copy_entity_settings,
        defines.input_action.craft,
        -- defines.input_action.create_blueprint_like,
        defines.input_action.cursor_split,
        defines.input_action.cursor_transfer,
        defines.input_action.custom_input,
        -- defines.input_action.cycle_blueprint_book_backwards,
        -- defines.input_action.cycle_blueprint_book_forwards,
        -- defines.input_action.deconstruct,
        -- defines.input_action.delete_blueprint_record,
        -- defines.input_action.delete_custom_tag,
        defines.input_action.delete_permission_group,
        -- defines.input_action.destroy_opened_item
        defines.input_action.disconnect_rolling_stock,
        defines.input_action.drag_train_schedule,
        defines.input_action.drag_train_wait_condition,
        -- defines.input_action.drop_blueprint_record,
        defines.input_action.drop_item,
        -- defines.input_action.drop_to_blueprint_book,
        -- defines.input_action.edit_custom_tag,
        defines.input_action.edit_permission_group,
        defines.input_action.edit_train_schedule,
        -- defines.input_action.export_blueprint,
        defines.input_action.fast_entity_split,
        defines.input_action.fast_entity_transfer,
        -- defines.input_action.grab_blueprint_record,	
        -- defines.input_action.gui_checked_state_changed,
        -- defines.input_action.gui_click,
        -- defines.input_action.gui_elem_changed,
        -- defines.input_action.gui_selection_state_changed,
        -- defines.input_action.gui_text_changed,
        -- defines.input_action.gui_value_changed,
        -- defines.input_action.import_blueprint,	
        -- defines.input_action.import_blueprint_string,
        defines.input_action.inventory_split, 
        defines.input_action.inventory_transfer,
        defines.input_action.launch_rocket,
        defines.input_action.market_offer,
        -- defines.input_action.mod_settings_changed,
        -- defines.input_action.open_achievements_gui,
        -- defines.input_action.open_blueprint_library_gui,
        -- defines.input_action.open_blueprint_record,
        -- defines.input_action.open_bonus_gui,
        -- defines.input_action.open_character_gui,	
        -- defines.input_action.open_equipment,
        -- defines.input_action.open_gui,
        -- defines.input_action.open_item,
        -- defines.input_action.open_kills_gui,
        -- defines.input_action.open_logistic_gui,
        -- defines.input_action.open_mod_item,
        -- defines.input_action.open_production_gui,
        -- defines.input_action.open_technology_gui,
        -- defines.input_action.open_train_gui,
        -- defines.input_action.open_train_station_gui,
        -- defines.input_action.open_trains_gui,
        defines.input_action.open_tutorials_gui,
        defines.input_action.paste_entity_settings,
        defines.input_action.place_equipment,
        defines.input_action.remove_cables,
        defines.input_action.reset_assembling_machine,
        defines.input_action.rotate_entity,
        defines.input_action.select_area,
        -- defines.input_action.select_blueprint_entities,
        defines.input_action.select_entity_slot,
        defines.input_action.select_gun,
        defines.input_action.select_item,
        defines.input_action.select_tile_slot,
        defines.input_action.set_auto_launch_rocket,
        -- defines.input_action.set_autosort_inventory,
        defines.input_action.set_behavior_mode,
        defines.input_action.set_car_weapons_control,
        defines.input_action.set_circuit_condition,
        defines.input_action.set_circuit_mode_of_operation,
        -- defines.input_action.set_deconstruction_item_tile_selection_mode,
        -- defines.input_action.set_deconstruction_item_trees_and_rocks_only,
        defines.input_action.set_entity_color,
        defines.input_action.set_entity_energy_property,
        defines.input_action.set_filter,
        defines.input_action.set_infinity_container_filter_item,
        defines.input_action.set_infinity_container_remove_unfiltered_items,
        defines.input_action.set_inserter_max_stack_size,
        defines.input_action.set_inventory_bar,
        defines.input_action.set_logistic_filter_item,
        defines.input_action.set_logistic_filter_signal,
        defines.input_action.set_logistic_trash_filter_item,
        defines.input_action.set_request_from_buffers,
        -- defines.input_action.set_research_finished_stops_game,
        defines.input_action.set_signal,
        -- defines.input_action.set_single_blueprint_record_icon,
        defines.input_action.set_splitter_priority,
        defines.input_action.set_train_stopped,
        defines.input_action.setup_assembling_machine,
        -- defines.input_action.setup_blueprint,
        -- defines.input_action.setup_single_blueprint_record,
        defines.input_action.shortcut_quick_bar_transfer,
        defines.input_action.smart_pipette,
        defines.input_action.stack_split,
        defines.input_action.stack_transfer,
        defines.input_action.start_repair,
        defines.input_action.start_research,
        -- defines.input_action.start_walking,
        defines.input_action.switch_connect_to_logistic_network,
        defines.input_action.switch_constant_combinator_state,
        defines.input_action.switch_power_switch_state,
        defines.input_action.switch_to_rename_stop_gui,	
        defines.input_action.take_equipment,
        -- defines.input_action.toggle_deconstruction_item_entity_filter_mode,
        -- defines.input_action.toggle_deconstruction_item_tile_filter_mode,
        defines.input_action.toggle_driving,
        defines.input_action.toggle_enable_vehicle_logistics_while_moving,
        defines.input_action.toggle_show_entity_info,
        defines.input_action.use_ability,
        defines.input_action.use_artillery_remote,
        defines.input_action.use_item,
        defines.input_action.wire_dragging,
        -- defines.input_action.write_to_console,
    }
}


-- Move players to lobby
------------------------------------------------------------------------------

Event.register(defines.events.on_player_joined_game, function(event)
    local player = game.players[event.player_index]
    local game_control = global.game_control
    if game_control then
        GameControl.player_enter_game(game_control, player)
    else
        System.move_player_to_lobby(player)
    end
end)


function System.move_player_to_lobby(player)
    if not global.system then System.init() end
    local pos = System.constants.lobby_positions[global.system.lobby_position_index]
    player.teleport(pos, global.system.lobby_surface)
    if player.character and player.character.valid then 
        player.character.destroy()
    end

    global.system.observer_permission_group.add_player(player)

    player.minimap_enabled = false
    player.zoom = 1

    -- Make sure UIs are destroyed
    WaveCtrl.destroy_ui(player)
    UpgradeSystem.destroy_ui(player)
end




-- Lobby and Difficulty Select
-------------------------------------------------------------------------------



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
    for _, ent in pairs(surface.find_entities_filtered{type="gun-turret"}) do
        ent.insert("firearm-magazine")
    end
end


Event.register(VoteUI.on_vote_finished, function(event)
    if event.vote_name == GameControl.game_constants.difficulty_vote_cfg.name then
        game.print("Selected " .. event.option.title)
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



-- System
-------------------------------------------------------------------------------


function System.init()
    local lobby_surface = game.surfaces["lobby"] or game.create_surface("lobby")

    local player_permission_group = game.permissions.get_group("player_group") or game.permissions.create_group("player_group")
    for _, action in pairs(System.constants.player_forbidden_actions) do
        player_permission_group.set_allows_action(action, false)
    end

    local observer_permission_group = game.permissions.get_group("observer_group") or game.permissions.create_group("observer_group")
    for _, action in pairs(System.constants.observer_forbidden_actions) do
        observer_permission_group.set_allows_action(action, false)
    end


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
        observer_permission_group = observer_permission_group,
        -- saved_entities = {force = {}},
        -- lobby_position_index = 1,
    }

    global.system = system

    -- Init Lobby
    System.prepare_lobby_surface(lobby_surface)
    global.system.lobby_position_index = math.random(#System.constants.lobby_positions)

    for _, player in pairs(game.players) do
        System.move_player_to_lobby(player)

        -- More Band-aid for ui
        if player.gui.top.mod_gui_button_flow then
            for _, button in pairs(player.gui.top.mod_gui_button_flow.children) do
                if button and button.valid and button.name == "creative-mode-fix_main-menu-open-button" then button.destroy() end
            end
        end
    end

    System.start_game_vote()
end


Event.register(-10, function() 
    if not global.system then 
        System.init()
    elseif global.system.game_destroy_tick and global.system.game_destroy_tick < game.tick then
        System.end_game()
    end
end)


Event.register(GameControl.on_game_ended, function()
    global.system.game_destroy_tick = game.tick + System.constants.game_destroy_delay
    for _, player in pairs(global.system.player_force.players) do
        global.system.observer_permission_group.add_player(player)        
    end

    game.print("The game will automatically restart in a minute.")
end)


function System.end_game()
    -- Clean up old game
    GameControl.destroy_game(global.game_control)
    
    -- Move players out of the way
    global.system.lobby_position_index = math.random(#System.constants.lobby_positions)        
    global.system.game_destroy_tick = nil
    for _, player in pairs(global.system.player_force.players) do
        System.move_player_to_lobby(player)
    end

    -- Start vote for new game
    System.start_game_vote()
end       

function System.start_game_vote()
    local system = global.system
    
    local admin_present = false
    for _, player in pairs(system.player_force.players) do
        if player.admin and player.connected then
            admin_present = true
            break
        end
    end

    local vote_cfg = Table.copy(GameControl.game_constants.difficulty_vote_cfg)
    local vote = VoteUI.get_vote(vote_cfg.name)
    if vote then
        VoteUI.destroy(vote)
    end

    if game.is_multiplayer() and (not admin_present or cfg.select_difficulty_via_vote) then
        vote_cfg.force = system.player_force
        VoteUI.init_vote(vote_cfg.name, vote_cfg, GameControl.game_constants.difficulty_vote_options)    
    else
        vote_cfg.mode = "single"
        vote_cfg.duration = nil
        vote = VoteUI.init_vote(vote_cfg.name, vote_cfg, GameControl.game_constants.difficulty_vote_options)    
        for _, player in pairs(system.player_force.players) do
            if player.admin then
                VoteUI.add_player(vote, player)
            end
        end
    end
end





-- Commands


commands.add_command("reset", "Reset the game.", function(event)
    local player = game.players[event.player_index]
    if not player.admin then player.print("Only allowed for admins!") return end
    game.print("Reset.")
    System.end_game()
end)

commands.add_command("startvote", "Start a vote for all players to participate in. Separate title and options with |. Example '/startvote Which Technology? |Nuclear|Rocket|Flamethrower|Moar Faster'", function(event)
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

Event.register(VoteUI.on_vote_finished, function(event)
    if event.vote_name == "player-vote" then
        game.print("Vote Ended. Selected " .. event.option_name)
    end
end)



commands.add_command("dbg_wv", "Debug Wave Controller", function(event) 
    local player = game.players[event.player_index]
    if not player.admin then return end
    player.print(serpent.block(global.game_control.wave_control)) 
end)

commands.add_command("dbg_show_const", "Show Scenario Constants", function(event) 
    local player = game.players[event.player_index]
    if not player.admin then return end
    local ui = TableGUI.create("Scenario Constants")
    TableGUI.create_ui(ui, player)
    TableGUI.add_table(ui, "Scenario Constants", GameControl.game_constants)
end)

commands.add_command("dbg_show_game_globals", "Show Game State", function(event) 
    local player = game.players[event.player_index]
    if not player.admin then return end
    local ui = TableGUI.create("Game Globals")
    TableGUI.create_ui(ui, player)
    TableGUI.add_table(ui, "Game Control", global.game_control)
end)

commands.add_command("dbg_testing", "Cheats! Desyncs in multiplayer.", function(event)
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