-- control.lua

-- Tower Defense Scenario control



-- Modules
-------------------------------------------------------------------------------


local Table = require("Utils.Table")
local Maths = require("Utils.Maths")
local ScenarioUtils = require("Utils.Scenario")

local Event = require("stdlib.event.event")

local WaveCtrl = require("wave_control")
local UpgradeSystem = require("upgrade_system")

local TableGUI = require("Utils.TableViewer")
local mod_gui = require("mod-gui")


-- TODO
-------------------------------------------------------------------------------

-- Cliff in SE
-- License
-- Testing

-- Testing round 2

-- Voting UI
-- Difficulty ui
-- Difficulties

-- Outside game system
-- Reset surface

-- Determine Wave Group movement ticks in advance so they are timed evenly

-- Sort upgrade ui.
-- Table UI is buggy again.

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
-- inventory and equipment data
-- Starting inventory and equipment system
-- Map
-- Loot on map
-- Map script data
-- Forces, players set up
-- Rocket Turret
-- System Sounds



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

-- Game Constants
-------------------------------------------------------------------------------

-- TODO: {x = 217.5, y = 72.5} causes bugs
local buffers = {{x = 180.5, y = 57.5}, {x = 186.5, y = 41.5}, {x = 187.5, y = 51.5}, {x = 187.5, y = 64.5}, {x = 177.5, y = 73.5}, {x = 181.5, y = 90.5}, {x = 187.5, y = 83.5}, {x = 199.5, y = 57.5}, {x = 207.5, y = 52.5}, {x = 214.5, y = 45.5}, {x = 217.5, y = 53.5}, {x = 195.5, y = 95.5}, {x = 197.5, y = 81.5}, {x = 204.5, y = 87.5}, {x = 221.5, y = 84.5}, {x = 225.5, y = 42.5}, {x = 226.5, y = 59.5}, {x = 233.5, y = 52.5}, {x = 240.5, y = 58.5}, {x = 231.5, y = 83.5}, {x = 233.5, y = 65.5}, {x = 237.5, y = 75.5}}
local buffers_1 = {}
local buffers_2 = {}
for _, p in pairs(buffers) do
    if p.x < 220 then
        table.insert(buffers_1, p)
    else
        table.insert(buffers_2, p)
    end
end

local scenario_constants = {
    spawner_money = 3,
    wave_money = 10,
    initial_money = 15,
    player_spawn_position = {105, -75},
    artillery_initial_ammo = 3,
    initial_wait = 10 * 60 * 60,
    wave_delay = 5 * 60 * 60,
    lane1 = {
        weight = 1,
        path = {{206, 66}, {165, 40}, {121, 0}, {121, -50}, {128, -90}},
        buffers = buffers_1
    },
    lane2 = {
        weight = 0.5, 
        path = {{213, 71}, {208, 29}, {209, -90}, {144, -98}},
        buffers = buffers_2
    },
    blocking_turret_count = 4,
    starting_inventory = {
        ["steel-axe"] = 20,
        --["submachine-gun"] = 1,
        --["firearm-magazine"] = 20,
        ["artillery-targeting-remote"] = 1,
        ["blueprint"] = 2,
        ["deconstruction-planner"] = 1,
        -- ["modular-armor"] = {
        --     type="armor",
        --     equipment = {
        --         "night-vision-equipment",
        --         {name="energy-shield-equipment", count=2},
        --         {name="battery-equipment", count = 2},
        --         {name="solar-panel-equipment", count = "fill"}
        --     }
        -- }
        ["construction-robot"] = 15,
        ["power-armor"] = {
            type = "armor",
            equipment = {
                "fusion-reactor-equipment",
                {name="energy-shield-equipment", count = 2},
                {name="personal-roboport-equipment", count = 2},
                "night-vision-equipment",
            }
        }
    },
    starting_items = {
        ["coal"] = 50,
        ["iron-plate"] = 500,
        ["iron-gear-wheel"] = 200,
        ["electronic-circuit"] = 600,
        ["copper-plate"] = 300,
        ["steel-plate"] = 300,
        ["engine-unit"] = 30,
        ["small-electric-pole"] = 200,
        ["big-electric-pole"] = 50,
        ["small-lamp"] = 200,
        ["pipe"] = 300,
        ["transport-belt"] = 600,
        ["underground-belt"] = 100,
        ["splitter"] = 50,
        ["inserter"] = 200,
        ["electric-mining-drill"] = 200,
        ["steel-furnace"] = 200,
        ["assembling-machine-2"] = 30,
        ["boiler"] = 20,
        ["steam-engine"] = 40,
        ["pumpjack"] = 10,
        ["oil-refinery"] = 4,
        ["chemical-plant"] = 10,
        ["centrifuge"] = 10,
        ["gun-turret"] = 10,
        ["grenade"] = 50,
        ["piercing-rounds-magazine"] = 100,
    },
    unlock_technologies = {
        "automation",
        "automation-2",
        "logistics",
        "turrets",
        "military",
        "steel-processing",
        "electronics",
        "heavy-armor",
        "fluid-handling",
        "circuit-network",
        "optics",
        "military-2",
        -- "railway",
        -- "automated-rail-transportation",
        -- "rail-signals",
        "toolbelt",
        "electric-energy-distribution-1",
        "advanced-material-processing",
        "engine",
        "logistics-2",
        "automobilism",
        "tanks",
        "electric-engine",
        "oil-processing",
        "plastics",
        "sulfur-processing",
        "batteries",
        "laser",
        "battery",
        "stack-inserter",
        "laser-turrets",
        "modules",
        "modular-armor",
        "military-3",
        "concrete",
        "cluster-grenade",
        -- "flammables",
        -- "flamethrower",
        "advanced-electronics",
        "inserter-capacity-bonus-1",
        "inserter-capacity-bonus-2",
        "worker-robots-speed-1",
        "worker-robots-speed-2",
    },

    lock_recipes = {
        "science-pack-1",
        "science-pack-2",
        "science-pack-3",
        "military-science-pack",
        "production-science-pack",
        "hightech-science-pack"
    },

    unlock_recipes = {
        "rocket-launcher"
    },


    upgrades = {
        -- {
        --     name = "Repair",
        --     description = "Instantly repair the silo by 1000 Health.";
        --     cost = 1,
        --     level_max = 50,
        --     icon = "item/repair-pack",
        --     action = function(game_control, upgrade_data)
        --         if not game_control.rocket_silo or not game_control.rocket_silo.valid then
        --             return "The Rocket Silo seems to be unavailable."
        --         end

        --         if game_control.rocket_silo.health > 4000 then 
        --             return "Rocket silo is missing less 1000 health!"
        --         else
        --             game_control.rocket_silo.health = game_control.rocket_silo.health + 1000
        --         end
        --     end
        -- },
        {
            name = "Artillery Shell",
            description = "Add an artillery shell to the artillery turret.",
            cost = 2,
            cost_increase = 0,
            level_max = 50,
            icon = "item/artillery-shell",
            action = function(game_control, upgrade_data)
                if not game_control.artillery_turret or not game_control.artillery_turret.valid then
                    return "The Artillery Turret seems to be unavailable."
                end
                local count = game_control.artillery_turret.insert({name = "artillery-shell", count=1})
                if count == 0 then
                    return "No inventory space for artillery shells!"
                end
            end
        },
        {
            name = "Bullet Upgrade",
            description = "Upgrades bullet damage and shooting speed.",
            cost = 8,
            cost_increase = 2,
            icon = "item/piercing-rounds-magazine",
            unlock = {
                "bullet-damage",
                "bullet-speed"
            },
            level_max = 3,
        },
        {
            name = "Turret Upgrade",
            description = "Upgrades turret damage.",
            cost = 4,
            icon = "item/gun-turret",
            unlock = "gun-turret-damage",
            level_max = 3,
        },
        {
            name = "Laser Turret Upgrade",
            description = "Upgrades laser turret damage and shooting speed.",
            cost = 5,
            icon = "item/laser-turret",
            unlock = {
                "laser-turret-damage",
                "laser-turret-speed",
            },
            level_max = 3,
        },
        -- {
        --     name = "Flamethrower Upgrade",
        --     description = "Upgrades flamethrower damage.",
        --     cost = 6,
        --     icon = "item/flamethrower-turret",
        --     unlock = {
        --         "flamethrower-damage",
        --     },
        --     level_max = 2,
        --     prerequisites = "Flame Technology"
        -- },
        -- {
        --     name = "Rocket Upgrade",
        --     description = "Upgrades rocket damage and shooting speed.",
        --     cost = 10,
        --     cost_increase = 2,
        --     icon = "item/rocket",
        --     unlock = {
        --         "rocket-damage",
        --         "rocket-speed",
        --     },
        --     level_max = 2,
        --     prerequisites = {"Rocket Technology"},
        -- },
        -- {
        --     name = "Rocket Turret Damage",
        --     description = "Upgrades rocket turret damage.",
        --     cost = 8,
        --     icon = "item/rocket-turret",
        --     unlock = {
        --         "rocket-turret-damage",
        --     },
        --     level_max = 2,
        --     prerequisites = {"Rocket Technology"},
        -- },
        -- {
        --     name = "Shotgun Shell Upgrade",
        --     description = "Upgrades shotgun damage and shooting speed.",
        --     cost = 2,
        --     icon = "item/shotgun-shell",
        --     unlock = {
        --         "shotgun-shell-damage",
        --         "shotgun-shell-speed",
        --     },
        --     level_max = 4,
        -- },
        {
            name = "Flame Technology",
            description = "Unlocks Flamethrower Turrets \n\nYou will need engine units and oil.",
            cost = 20,
            icon = "item/flamethrower-turret",
            unlock = {
                "flammables",
                "flamethrower",
            }
        },
        {
            name = "Rocket Technology",
            description = "Unlocks rockets and the rocket turret. \n\nYou will need explosives and advanced circuits. ",
            cost = 20,
            icon = "item/rocket",
            unlock = {
                "explosives",
                "rocketry",
                "explosive-rocketry",
                "rocket-turret",
            }
        },
        {
            name = "Nuclear Technology",
            description = "Unlocks uranium ammo and nuclear bombs (by the way, there is no friendly fire in this mode). \n\nYou will need sulfuric acid and uranium.",
            cost = 20,
            icon = "item/uranium-rounds-magazine",
            unlock = {
                "nuclear-power",
                "uranium-ammo",
                "atomic-bomb",
            }
        },
        {
            name = "Robot Speed",
            description = "Increases worker robot speed by 50%.",
            cost = 12,
            icon = "item/construction-robot",
            unlock = {
                "worker-robots-speed-3",
                "worker-robots-speed-4",
            }
        },
        {
            name = "Faster Hands",
            description = "Increases handcrafting speed and mining speed by 150%",
            cost = 12,
            icon = "item/iron-axe",
            action = function(game_control, upgrade_data)
                game_control.player_force.manual_crafting_speed_modifier = game_control.player_force.manual_crafting_speed_modifier + 1.5
                game_control.player_force.manual_mining_speed_modifier = game_control.player_force.manual_mining_speed_modifier + 1.5
            end
        },
        {
            name = "Faster Movement",
            description = "Increases running speed by 80% of vanilla speed.",
            cost = 12,
            icon = "item/exoskeleton-equipment",
            max_level = 2,
            action = function(game_control, upgrade_data)
                game_control.player_force.character_running_speed_modifier = game_control.player_force.character_running_speed_modifier + 0.8
            end
        },
        -- {
        --     name = "Time",
        --     description = "Delay next wave by 5 minutes.",
        --     cost = 8,
        --     icon = "item/lab",
        --     max_level = 2,
        --     cost_increase = "double",
        --     action = function(game_control, upgrade_data)
        --         WaveCtrl.delay_wave(game_control.wave_control, 5 * 60 * 60)
        --     end
        -- },
    },

    -- Unused currently and up to change
    difficulty_settings = {
        {
            name = "Very Easy",
            group_size = 5, 
            group_time_factor = 120, -- Time in ticks per unit (on average, keep in mind units are clumped into groups)
            unit_factor = 0.4, -- Multiplier for total unit count
            duration_factor = 4, -- Time per wave multiplier
        },
        {
            name = "Normal",
            group_size = 10,
            group_time_factor = 60,
            unit_factor = 0.7,
            duration_factor = 3,
        },
        {
            name = "Hard",
            group_size = 15,
            group_time_factor = 30,
            unit_factor = 1,
            duration_factor = 2,
        }, 
        {
            name = "Very Hard",
            group_size = 20,
            group_time_factor = 30,
            unit_factor = 1.3,
            duration_factor = 1.5,
        },
        {
            name = "Insane",
            group_size = 40,
            group_time_factor = 15,
            unit_factor = 2,
            duration_factor = 1,
        }
    },
    lobby_positions = { -- Available positions on lobby surface
        {17, -50},
        -- {5, 90},
        -- {-134, 22}
    },

    loot = {
        medium = {
            entities = {"medium-ship-wreck"},
            items = {
                ["express-transport-belt"] = 100,
                ["express-underground-belt"] = 50,
                ["uranium-rounds-magazine"] = 200,
            }
        },
        large = {
            entities = {"big-ship-wreck-1", "big-ship-wreck-2", "big-ship-wreck-3"},
            items = {
                ["atomic-bomb"] = 2,
                ["artillery-shell"] = 4,
            }
        }
        -- small = {entities = {"small-ship-wreck"}, items={}},
    }
}

scenario_constants.hints = {
    "Biters will come in waves to attack your rocket silo. You win if you survive all waves. You lose if you silo falls. ",
    "At the end of each wave your team receives " .. scenario_constants.wave_money .. " alien artifacts. These can be used to purchase upgrades.",
    "Use the artillery turret in an emergency. There is no friendly fire: You cannot hurt allied buildings. ",
    "Some purchasable upgrades correspond to technologies, for example Bullet Upgrade 1 unlocks the Bullet Damage 1 and Bullet Shooting Speed 1 technologies.",
    "The aliens in the south west are peaceful. Their spawners drop " .. scenario_constants.spawner_money .. " alien artifacts each.",
    "Behemoth biters will not be damaged by piercing rounds unless you have upgrades researched.",
    "The east lane only gets half the attacks of the west lane. Apparently biters dont like to go near water.",
    [9] = "Final wave. Good luck. "
}

scenario_constants.ending_message = "Credits: This scenario uses \n - factorio stdlib. \n - predictabowl's rocket turret. \n\n Made by unique_2."






-- Init Wave System
-------------------------------------------------------------------------------


-- TODO: Finish this
local function make_wave(unit_str, duration, size)
    if not duration then duration = scenario_constants.wave_delay end

    local wave = {
        lanes = {global.game_control.lane1, global.game_control.lane2},
        group_size = size or 15,
        group_time_factor = 15,
        unit = {unit_str, 30},
        duration = duration,
    }

    WaveCtrl.make_wave(global.game_control.wave_control, wave)
end

local function init_waves()
    local waves = {
        "b111aa",
        "22bb1",
        {"c22bb", scenario_constants.wave_delay * 2},
        "33cc2",
        {"d333c", scenario_constants.wave_delay * 2},
        {"4", nil, 4},
        "4dcc22bb",
        "44d3c",
        "444dd",
    }
    for _, wave in pairs(waves) do
        if type(wave) == "string" then
            make_wave(wave)
        else
            make_wave(wave[1], wave[2], wave[3])
        end
    end
end


-- Reset Forces
-------------------------------------------------------------------------------

local function reset_player_force(game_control)
    local force = game_control.player_force

    force.reset()
    force.disable_research()
    force.chart_all()
    force.set_spawn_position(scenario_constants.player_spawn_position, game_control.surface)

    force.set_cease_fire(game_control.enemy_force, false)
    force.set_cease_fire(game_control.wave_force, false)
    force.set_friend(game_control.ally_force, true)
    force.set_cease_fire(game_control.ally_force, true)
    force.set_friend(game_control.enemy_force, false)
    force.friendly_fire = false
    

    -- Research Techs
    for _, tech in pairs(scenario_constants.unlock_technologies or {}) do
        if force.technologies[tech] then
            force.technologies[tech].researched = true
        end
    end

    -- Lock recipes
    for _, recipe in pairs(scenario_constants.lock_recipes or {}) do
        if force.recipes[recipe] then
            force.recipes[recipe].enabled = false
        end
    end

    -- Unlock recipes
    for _, recipe in pairs(scenario_constants.unlock_recipes or {}) do
        if force.recipes[recipe] then
            force.recipes[recipe].enabled = true
        end
    end

    
    -- Hide Techs
    for _, tech in pairs(force.technologies) do
        if not tech.researched and not Table.find(tech.name, scenario_constants.available_techs or {}) then
            tech.enabled = false
        end
    end

    -- Bonuses
    force.character_running_speed_modifier = force.character_running_speed_modifier + 1
    for _, player in pairs(force.players) do 
        player.character_running_speed_modifier = 0
    end
end

local function reset_wave_force(game_control)
    local force = game_control.wave_force

    force.reset()
    force.set_cease_fire(game_control.player_force, true)   
    force.set_cease_fire(game_control.ally_force, false)
    force.set_cease_fire(game_control.enemy_force, true)
    force.set_friend(game_control.player_force, false)
end

local function reset_enemy_force(game_control)
    local force = game_control.enemy_force
    force.reset()
    force.evolution_factor = 0.6
    --game_control.surface.peaceful_mode = true
    force.set_cease_fire(game_control.wave_force, true)
    force.set_cease_fire(game_control.ally_force, false)
    force.set_cease_fire(game_control.player_force, false)
end

local function reset_ally_force(game_control)
    local force = game_control.ally_force
    force.reset()
    force.set_friend(game_control.player_force, true)
    force.set_cease_fire(game_control.enemy_force, true)    
    force.set_cease_fire(game_control.player_force, true)    
    force.set_cease_fire(game_control.wave_force, false)    
end

local function player_enter_game(game_control, player)
    if player.connected then
        ScenarioUtils.spawn_player(
            player, 
            game_control.surface, 
            player.force.get_spawn_position(game_control.surface), 
            scenario_constants.starting_inventory
        )

        player.cheat_mode = false
        game_control.player_permission_group.add_player(player)
        player.minimap_enabled = true

        UpgradeSystem.create_ui(player)
        local mod_flow = mod_gui.get_frame_flow(player)        
        local wave_ui_frame = WaveCtrl.create_ui(player, game_control.wave_control, mod_flow)
        local caption = scenario_constants.hints[game_control.wave_control.spawning_wave_index] or scenario_constants.hints[1]
        local label = wave_ui_frame.add{type="label", name="hint_label", caption=caption}
        label.style.visible = true
        label.style.single_line = false
    end
end


local function reset_surface(game_control)
    local forces = {game_control.player_force, game_control.neutral_force, game_control.ally_force, game_control.enemy_force, game_control.wave_force}
    local surface = game_control.surface
    local excluded_types = {["cliff"]=true}
    local excluded_names = {}


    if not global.system.saved_entities then
        -- Remove position markers
        for _, ent in pairs(surface.find_entities_filtered{name="centrifuge"}) do 
            ent.destroy()
        end


        -- Save entities for next game
        global.system.saved_entities = {}
        local attributes = {"position", "amount", "orientation", "direction", "health", }
        local entity_attributes = {["assembling-machine"] = {"recipe"}, ["inserter"] = {"filter"}, ["underground-belt"] = {"type"}, ["container"] = {"bar"}, ["train-stop"] = {"backer-name"}}

        for _, force in pairs(forces) do
            local force_name = force.name
            global.system.saved_entities[force_name] = {}
            for _, ent in pairs(surface.find_entities_filtered{force=force}) do
                local entity_type = ent.type
                local name = ent.name
                if not excluded_types[entity_type] and not excluded_names[name] then
                    local saved_entity = {name = name, force_name}
                    local function cp(attr)
                        saved_entity[attr] = ent.attr
                    end                        
                    for _, attrib in pairs(attributes) do
                        pcall(cp, attrib)
                    end
                    for _, attrib in pairs(entity_attributes[entity_type] or {}) do
                        pcall(cp, attrib)
                    end
                    table.insert(global.system.saved_entities[force_name], saved_entity)
                    -- Activate entities that were set inactive for editing
                    if not ent.active then
                        ent.active = true
                    end
                end
            end
        end
    else
        -- Remove old entities and recreate from data
        for _, force in pairs(forces) do
            for _, ent in pairs(surface.find_entities{force=force}) do
                if not excluded_types[ent.type] then
                    ent.destroy()
                end
            end
        end
        local create = surface.create_entity
        for _, ent in pairs(global.system.saved_entities) do
            create(ent)
        end

        -- Decoratives
        -- TODO: This is shitty, but anything else would require effort and performance...
        surface.destroy_decoratives({{-1000, -1000}, {1000, 1000}})
        game_control.surface.generate_decorative()
    end

    -- Surface properties
    surface.always_day = false

    -- Set special entities
    game_control.rocket_silo = game_control.surface.find_entities_filtered{type="rocket-silo", limit=1}[1]
    game_control.rocket_silo.minable = false

    -- Until we find a better solution.
    game_control.rocket_silo.force = game_control.player_force


    game_control.artillery_turret = game_control.surface.find_entities_filtered{type="artillery-turret", limit=1}[1]
    if game_control.artillery_turret then 
        game_control.artillery_turret.minable = false
        game_control.artillery_turret.insert({name="artillery-shell", count=scenario_constants.artillery_initial_ammo})
    else
        game.print("Artillery Turret not found!")
    end
    -- if scenario_constants.blocking_turrets then
    --     game_control.lane_blocking_turrets = {}
    --     for i, pos in pairs(scenario_constants.blocking_turrets) do
    --         local ent = surface.find_entity("gun-turret", pos)
    --         if ent then 
    --             game_control.lane_blocking_turrets[i] = ent
    --         end
    --     end
    -- end
    
    -- Set enemy units properly
    for _, ent in pairs(surface.find_entities_filtered{type="unit-spawner", force="wave-enemy"}) do
        ent.destructible = false
        ent.active = false
    end
    for _, ent in pairs(surface.find_entities_filtered{type="turret", force="wave-enemy"}) do
        ent.force = game_control.enemy_force
    end

    -- Add loot
    for _, loot_category in pairs(scenario_constants.loot) do
        for _, entity_name in pairs(loot_category.entities) do
            for _, ent in pairs(surface.find_entities_filtered{name=entity_name}) do
                if ent.get_inventory(defines.inventory.chest) then
                    for name, count in pairs(loot_category.items) do
                        ent.insert{name=name, count=count}
                    end
                else
                    ScenarioUtils.create_item_chests(surface, ent.position, game_control.neutral_force, loot_category.items) 
                end
            end
        end
    end
end


-- Game
-------------------------------------------------------------------------------


local function restart_game(game_control)
    -- Reset Entities
    reset_surface(game_control)


    -- Reset Forces
    reset_player_force(game_control)
    reset_wave_force(game_control)
    reset_enemy_force(game_control)
    reset_ally_force(game_control)


    -- Starting items
    ScenarioUtils.create_item_chests(
        game_control.surface, 
        scenario_constants.player_spawn_position, 
        game_control.player_force, 
        scenario_constants.starting_items
    )

    -- Reset Upgrade System
    UpgradeSystem.init(scenario_constants.upgrades, game_control.player_force, 0)
    
    -- Reset Wave System
    game_control.wave_control = WaveCtrl.init{
        wave_force = game_control.wave_force,
        surface = game_control.surface,
        initial_wait = scenario_constants.initial_wait,
    }
    game_control.lane1 = Table.deepcopy(scenario_constants.lane1)
    game_control.lane2 = Table.deepcopy(scenario_constants.lane2)
    init_waves()

    -- Setup Players
    for _, player in pairs(game_control.player_force.players) do
        -- Spawn, Gui Creation.
        player_enter_game(game_control, player)
    end

end


Event.register(defines.events.on_player_joined_game, function(event)
    local player = game.players[event.player_index]
    if global.game_control then
        player_enter_game(global.game_control, player)
    else
        move_to_lobby(player)
    end
end)



-- Lose / Win

local function end_game(game_control, win)        
    -- Set players invincible
    for _, player in pairs(game_control.player_force.players) do
        if player.character then 
            player.character.destructible = false 
        end
        player.character = nil
    end
        
    game_control.ended = true
    -- Stop Spawning Units and commence biter celebration
    WaveCtrl.stop(game_control.wave_control, win)
end


-- TODO
local function post_end_game()
    local game_control = global.game_control
    -- local lobby_pos_index = math.random(#scenario_constants.lobby_positions)
    -- global.system.lobby_position_index = math.random(#scenario_constants.lobby_positions)
    -- for _, player in pairs(game_control.player_force.players) do
    --     move_to_lobby(player, lobby_pos_index)
    -- end

    UpgradeSystem.destroy(game_control.player_force)
    WaveCtrl.destroy(game_control.wave_control)
    global.game_control = nil
end


Event.register(defines.events.on_entity_died, function(event)
    local entity = event.entity
    local game_control = global.game_control
    if not game_control or game_control.ended then return end

    -- Game End
    if entity.name == "rocket-silo" then 
        -- Create Rocket Silo Death animation
        local pos = entity.position
        local surface = game_control.surface
        for i=1, 5 do 
            surface.create_entity{name="small-scorchmark", position=Maths.random_position(pos, 6, false)}
        end
        for i=1, 10 do 
            surface.create_entity{name="big-remnants", position=Maths.random_position(pos, 6, false)}
        end
        for i=1, 5 do 
            surface.create_entity{name="medium-explosion", position=Maths.random_position(pos, 10, false)}
        end

        end_game(game_control, false)

        -- Inform Players
        game_control.player_force.print("Rocket Silo died! Game Over.")
        game_control.player_force.play_sound{path="utility/game_lost", }
        
        -- event.cause entity is available, do something with it?
    elseif entity.type == "unit-spawner" and global.game_control and entity.force.name == global.game_control.enemy_force.name then 
        UpgradeSystem.give_money(global.game_control.player_force, scenario_constants.spawner_money, global.game_control.surface, {event.entity.position})
    elseif entity.type == "gun-turret" and entity.force.name == "ally" then
        game_control.blocking_turret_count = game_control.blocking_turret_count - 1
        if game_control.blocking_turret_count <= 0 then 
            game_control.player_force.print("They broke through the defenses on the eastern bridge!")
        --     for t in pairs({"stone-wall", "gate"}) do 
        --         for _, ent in pairs(game_control.surface.find_entities_filtered{force="ally", type=t}) do
        --             ent.die()
        --         end
        --     end
        end 
    end
end)

-- Event.register({defines.events.on_robot_built_entity, defines.events.on_robot_built_tile, defines.events.on_built_entity, defines.events.on_player_built_tile})

-- Forbid player to build on lanes
Event.register(defines.events.on_put_item, function(event)
    local player = game.players[event.player_index]
    local game_control = global.game_control
    if not game_control or game_control.ended then return end
    if not game_control.lane_marker_surface then return end
    if game_control.lane_marker_surface.get_tile(event.position.x, event.position.y).name == "out-of-map" then
        local success = player.clean_cursor()
        if success then 
            player.print("Cannot build here.")
            player.play_sound{path="utility/cannot_build"}
        else
            -- More drastic measures
            local inventory = player.get_main_inventory() 
            local stack = inventory[1]
            inventory.remove(stack)
            player.print("Cannot build here. As a penalty for trying we have removed " .. stack.count .. " " .. stack.name .. " from your inventory.")
            player.play_sound{path="utility/cannot_build"}            
            player.clean_cursor()
        end
    end
end)

Event.register(defines.events.on_built_entity, function(event)
    local entity = event.created_entity
    local player = game.players[event.player_index]    
    local position = entity.position
    local game_control = global.game_control
    if not game_control or game_control.ended then return end
    if not game_control.lane_marker_surface then return end
    if game_control.lane_marker_surface.get_tile(position.x, position.y).name == "out-of-map" then
        if game.item_prototypes[entity.name] then
            player.insert{name=entity.name, count=1}
        end
        entity.destroy()
        player.print("Cannot build here. ")
        player.play_sound{path="utility/cannot_build"}        
    end
end)


Event.register(WaveCtrl.on_wave_starting, function(event)
    local game_control = global.game_control
    if event.wave_index > 0 then
        game_control.player_force.play_sound{path="utility/new_objective", }        
        game.print("Wave " .. event.wave_index .. " has started.")
    else
        game_control.player_force.play_sound{path="utility/new_objective", }                
        game.print("First wave starting soon!")
        UpgradeSystem.give_money(global.game_control.player_force, scenario_constants.initial_money, game_control.surface, {game_control.rocket_silo.position})
    end

end)


-- Alert players to attacks on silo.
script.on_nth_tick(5*60, function()
    local game_control = global.game_control
    if game_control and not game_control.ended then
        if game_control.rocket_silo_health and game_control.rocket_silo_health > game_control.rocket_silo.health then
            game_control.player_force.play_sound{path="utility/scenario_message"}
        end
        game_control.rocket_silo_health = game_control.rocket_silo.health
    end
end)


Event.register(WaveCtrl.on_wave_destroyed, function(event)
    local game_control = global.game_control
    if event.game_ended then
        -- Win
        end_game(game_control, true)

        for _, player in pairs(game_control.player_force.players) do
            local score = UpgradeSystem.get_
            mod_gui.get_frame_flow(player).wave_frame.hint_label.caption = "Final Score: " .. game_control.upgrade_system.money .. "\n\n" .. scenario_constants.ending_message or ""
        end

        game_control.player_force.play_sound{path="utility/game_won", }
        game_control.player_force.print("You win! Congratulations!")
    else
        UpgradeSystem.give_money(global.game_control.player_force, scenario_constants.wave_money)
        
        for _, player in pairs(game_control.player_force.players) do
            mod_gui.get_frame_flow(player).wave_frame.hint_label.caption = scenario_constants.hints[game_control.wave_control.spawning_wave_index] or ""
        end
        game_control.player_force.play_sound{path="utility/new_objective", }
        game_control.player_force.print("Wave " .. event.wave_index .. " ended. ")
    end
end)





-- Lobby and Difficulty Select
-------------------------------------------------------------------------------

local function move_to_lobby(player)
    local pos = scenario_constants[global.system.lobby_position_index]
    player.teleport(pos, global.system.lobby_surface)

    player.minimap_enabled = false

    -- Make sure UIs are destroyed
    WaveCtrl.destroy_ui(player)
    UpgradeSystem.destroy_ui(player)

    -- Set permissions
end

local function create_difficulty_ui(player)
end
local function destroy_difficulty_ui(player)
end

local function prepare_lobby_surface(surface)
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


local function init()
    local lobby_surface = game.surfaces["lobby"] or game.create_surface("lobby")
    local system = {
        player_force = game.forces.player,
        enemy_force = game.forces.enemy,
        neutral_force = game.forces.neutral,
        wave_force = game.forces["wave-enemy"] or game.create_force("wave-enemy"),
        ally_force = game.forces.ally or game.create_force("ally"),
        surface = game.surfaces.nauvis,
        lobby_surface = lobby_surface,
        lane_marker_surface = game.surfaces["lane-markers"]
        -- player_permission_group
        -- saved_entities = {force = {}},
        -- lobby_position_index = 1,
    }

    -- Permissions
    local player_permission_group = game.permissions.get_group("player_group") or game.permissions.create_group("player_group")
    player_permission_group.set_allows_action(defines.input_action.open_blueprint_library_gui, false)
    system.player_permission_group = player_permission_group

    global.system = system
    global.game_control = {
        player_force = system.player_force,
        enemy_force = system.enemy_force,
        wave_force = system.wave_force,
        neutral_force = system.neutral_force,
        ally_force = system.ally_force,
        surface = system.surface,
        lane_marker_surface = system.lane_marker_surface,
        player_permission_group = player_permission_group,
        ended = false,
        blocking_turret_count = scenario_constants.blocking_turret_count
        -- rocket_silo = nil,
        -- artillery_turret = nil
    }

    prepare_lobby_surface(lobby_surface)
    restart_game(global.game_control)
end


script.on_nth_tick(10, function() 
    if not global.game_control then 
        init()
    else
        WaveCtrl.main(global.game_control.wave_control)
    end    
end)


script.on_nth_tick(60, function()
    if global.game_control and global.game_control.wave_control then
        for _, player in pairs(global.game_control.player_force.players) do
            WaveCtrl.update_ui(player, global.game_control.wave_control)
        end
    end
end)




commands.add_command("dbg_wv", "Debug Wave Controller", function(event) game.players[event.player_index].print(serpent.block(global.game_control.wave_control)) end)
commands.add_command("show_const", "Show Scenario Constants", function(event) 
    local player = game.players[event.player_index]
    local ui = TableGUI.create("Scenario Constants")
    TableGUI.create_ui(ui, player)
    TableGUI.add_table(ui, "Scenario Constants", scenario_constants)
end)

commands.add_command("show_game_globals", "Show Game State", function(event) 
    local player = game.players[event.player_index]
    local ui = TableGUI.create("Game Globals")
    TableGUI.create_ui(ui, player)
    TableGUI.add_table(ui, "Game Control", global.game_control)
end)

commands.add_command("testing", "Cheats! Desyncs on player join.", function(event)
    local game_control = global.game_control
    if game_control then
        UpgradeSystem.give_money(game_control.player_force, 1000)
    end
    game_control.wave_control.next_wave_tick = game.tick + 3 * 60 * 60
    scenario_constants.wave_delay = 3 * 60 * 60
    for _, player in pairs(game_control.player_force.players) do 
        player.cheat_mode = true
    end
end)