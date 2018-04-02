-- game_control.lua

-- Actual Game and Tower Defense logic resides here
-- There can only be one game running at any given time.
-- Distinguish from pre game stuff like difficulty selection and lobby.



local Table = require("Utils/Table")
local Maths = require("Utils/Maths")
local ScenarioUtils = require("Utils/Scenario")

local Event = require("stdlib/event/event")

local WaveCtrl = require("wave_control")
local UpgradeSystem = require("upgrade_system")

local mod_gui = require("mod-gui")

local cfg = require("cfg")


local GameControl = {}


-- TODO: {x = 217.5, y = 72.5} causes bugs but it's still on the map.
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

GameControl.game_constants = {
    spawner_money = 3,
    wave_money = 10,
    initial_money = 15,
    player_spawn_position = {105, -75},
    artillery_initial_ammo = 3,
    initial_wait = 10 * 60 * 60,
    wave_duration = 5 * 60 * 60,
    lane1 = {
        weight = 1,
        path = {{206, 66}, {165, 40}, {121, 0}, {120, -37}, {128, -90}},
        buffers = buffers_1
    },
    lane2 = {
        weight = 0.5, 
        path = {{213, 71}, {208, 29}, {209, -90}, {144, -98}},
        buffers = buffers_2
    },
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
        ["construction-robot"] = 25,
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
        "explosives",
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
            name = "artillery-shell",
            title = "Artillery Shell",
            description = "Add an artillery shell to the artillery turret.",
            cost = 2,
            cost_increase = 0,
            level_max = 50,
            icon = "item/artillery-shell",
            action = function(game_control, _)
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
            cost = 6,
            cost_increase = 1,
            icon = "item/piercing-rounds-magazine",
            unlock = {
                "bullet-damage",
                "bullet-speed"
            },
            level_max = 4,
        },
        {
            name = "Gun Turret Upgrade",
            description = "Upgrades gun turret damage.",
            cost = 4,
            icon = "item/gun-turret",
            unlock = "gun-turret-damage",
            level_max = 4,
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
            name = "flame-technology",
            title = "Flame Technology",
            description = "Unlocks Flamethrower Turrets \n\nYou will need engine units and oil.",
            cost = 20,
            icon = "item/flamethrower-turret",
            unlock = {
                "flammables",
                "flamethrower",
            }
        },
        {
            name = "rocket-technology",
            title = "Rocket Technology",
            description = "Unlocks rockets and the rocket turret. \n\nYou will need explosives and advanced circuits. ",
            cost = 20,
            icon = "item/rocket",
            unlock = {
                "rocketry",
                "explosive-rocketry",
                "rocket-turret",
            }
        },
        {
            name = "nuclear-technology",
            title = "Nuclear Technology",
            description = "Unlocks uranium ammo. \n\nYou will need sulfuric acid and uranium.",
            cost = 20,
            icon = "item/uranium-rounds-magazine",
            unlock = {
                "nuclear-power",
                "uranium-ammo",
                "atomic-bomb",
            }
        },
        {
            name = "robot-speed",
            title = "Robot Speed",
            description = "Increases worker robot speed by 50%.",
            cost = 12,
            icon = "item/construction-robot",
            unlock = {
                "worker-robots-speed-3",
                "worker-robots-speed-4",
            }
        },
        {
            name = "faster-hands",
            title = "Faster Hands",
            description = "Increases handcrafting speed and mining speed by 150%",
            cost = 12,
            icon = "item/iron-axe",
            action = function(game_control, _)
                game_control.player_force.manual_crafting_speed_modifier = game_control.player_force.manual_crafting_speed_modifier + 1.5
                game_control.player_force.manual_mining_speed_modifier = game_control.player_force.manual_mining_speed_modifier + 1.5
            end
        },
        {
            name = "faster-movement",
            title = "Faster Movement",
            description = "Increases running speed by 50% of current.",
            cost = 12,
            icon = "item/exoskeleton-equipment",
            max_level = 2,
            action = function(game_control, _)
                game_control.player_force.character_running_speed_modifier = game_control.player_force.character_running_speed_modifier + 1
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

    difficulty_vote_options = {
        normal = {
            title = "Normal",
            tooltip = "Good to get to know the scenario, but dont fool around too much.",

            wave_duration_factor = 2
        },
        hard = {
            title = "Hard",
            tooltip = "Hope you know what you are doing. ",

            wave_duration_factor = 1.5
        },
        ["very-hard"] = {
            title = "Very Hard",
            tooltip = "Veterans beware.",

            wave_duration_factor = 1
        }, 
        ["insane"] = {
            title = "Insane",
            tooltip = "Seriously. It's not meant to be played like this.",

            wave_duration_factor = 0.8
        }
    },
    difficulty_vote_cfg = {
        name = "select-difficulty",
        title = "Select Difficulty",
        -- description = "",
        -- frame_style = nil,
        duration = 2*60,
        mode = "majority",
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

GameControl.game_constants.hints = {
    "Biters will come in waves to attack your rocket silo. You win if you survive all waves. You lose if your silo falls. ",
    "At the end of each wave your team receives " .. GameControl.game_constants.wave_money .. " alien artifacts. These can be used to purchase upgrades.",
    "Use the artillery turret in an emergency. There is no friendly fire: You cannot hurt allied buildings. ", -- gets modified if this is a stand-alone scenario
    "Some purchasable upgrades correspond to technologies, for example Bullet Upgrade 1 unlocks the Bullet Damage 1 and Bullet Shooting Speed 1 technologies.",
    "The aliens in the south west are peaceful. Their spawners drop " .. GameControl.game_constants.spawner_money .. " alien artifacts each.",
    "Behemoth biters will not be damaged by piercing rounds unless you have upgrades researched.",
    "The east lane only gets half the attacks of the west lane. Apparently biters dont like to go near water.",
    [9] = "Final wave. Good luck. "
}




function GameControl.adjust_game_constants(game_control, difficulty_settings)
    local game_constants = game_control.game_constants -- luacheck:ignore
    -- Make vanilla
    if not cfg.is_mod then
        local upgrades = game_constants.upgrades
        for k, upgrade in pairs(upgrades) do
            -- Remove Rocket Turret
            if upgrade.name == "rocket-technology" then
                upgrade.description = "Unlocks rockets. \n\nYou will need explosives. "
                upgrade.cost = 10
                upgrade.unlock = {
                    "rocketry",
                    "explosive-rocketry",
                }
                game_constants.ending_message = "Made by unique_2.\n This scenario uses: \n - factorio stdlib. \n\n Thanks for playing!"

            -- Remove Artillery Turret
            elseif upgrade.name == "artillery-shell" then
                upgrades[k] = nil
                game_constants.hints[3] = "There is no friendly fire: You cannot hurt allied buildings."
                game_constants.starting_inventory["artillery-targeting-remote"] = nil
                game_constants.loot.large.items = {["atomic-bomb"] = 2}
            end
        end
    end

    -- Difficulty
    game_constants.wave_duration = game_constants.wave_duration * difficulty_settings.wave_duration_factor
end



local function make_wave(game_control, unit_str, duration, size)
    if not duration then duration = game_control.game_constants.wave_duration end

    local wave = {
        lanes = {global.game_control.lane1, global.game_control.lane2},
        group_size = size or 15,
        group_time_factor = 15,
        unit = {unit_str, 30},
        duration = duration,
    }

    WaveCtrl.make_wave(game_control.wave_control, wave)
end

local function init_waves(game_control)
    local waves = {
        "b111aa",
        "22bb1",
        {"c22bb", game_control.game_constants.wave_duration * 2},
        "33cc2",
        {"d333c", game_control.game_constants.wave_duration * 2},
        {"4", nil, 4},
        "4dcc22bb",
        "44d3c",
        "444dd",
    }
    for _, wave in pairs(waves) do
        if type(wave) == "string" then
            make_wave(game_control, wave)
        else
            make_wave(game_control, wave[1], wave[2], wave[3])
        end
    end
end



-- Reset Forces
-------------------------------------------------------------------------------

function GameControl.reset_player_force(game_control)
    local force = game_control.player_force

    force.reset()
    force.disable_research()
    force.chart_all()
    force.set_spawn_position(game_control.game_constants.player_spawn_position, game_control.surface)

    force.set_cease_fire(game_control.enemy_force, false)
    force.set_cease_fire(game_control.wave_force, false)
    force.set_friend(game_control.ally_force, true)
    force.set_cease_fire(game_control.ally_force, true)
    force.set_friend(game_control.enemy_force, false)
    force.friendly_fire = false
    

    -- Research Techs
    for _, tech in pairs(game_control.game_constants.unlock_technologies or {}) do
        if force.technologies[tech] then
            force.technologies[tech].researched = true
        end
    end

    -- Lock recipes
    for _, recipe in pairs(game_control.game_constants.lock_recipes or {}) do
        if force.recipes[recipe] then
            force.recipes[recipe].enabled = false
        end
    end

    -- Unlock recipes
    for _, recipe in pairs(game_control.game_constants.unlock_recipes or {}) do
        if force.recipes[recipe] then
            force.recipes[recipe].enabled = true
        end
    end

    
    -- Hide Techs
    for _, tech in pairs(force.technologies) do
        if not tech.researched and not Table.find(tech.name, game_control.game_constants.available_techs or {}) then
            tech.enabled = false
        end
    end

    -- Bonuses
    force.character_running_speed_modifier = force.character_running_speed_modifier + 1
end

function GameControl.reset_wave_force(game_control)
    local force = game_control.wave_force

    force.reset()
    force.set_cease_fire(game_control.player_force, true)   
    force.set_cease_fire(game_control.ally_force, false)
    force.set_cease_fire(game_control.enemy_force, true)
    force.set_friend(game_control.player_force, false)
end

function GameControl.reset_enemy_force(game_control)
    local force = game_control.enemy_force
    force.reset()
    force.evolution_factor = 0.6
    --game_control.surface.peaceful_mode = true
    force.set_cease_fire(game_control.wave_force, true)
    force.set_cease_fire(game_control.ally_force, false)
    force.set_cease_fire(game_control.player_force, false)
end

function GameControl.reset_ally_force(game_control)
    local force = game_control.ally_force
    force.reset()
    force.set_friend(game_control.player_force, true)
    force.set_cease_fire(game_control.enemy_force, true)    
    force.set_cease_fire(game_control.player_force, true)    
    force.set_cease_fire(game_control.wave_force, false)    
end




-- Players
------------------------------------------------------------------------------
function GameControl.player_enter_game(game_control, player)
    if not player.connected or game_control.active_players[player.name] then
        return
    end

    game_control.active_players[player.name] = true

    -- Spawn
    ScenarioUtils.spawn_player(
        player, 
        game_control.surface, 
        player.force.get_spawn_position(game_control.surface), 
        game_control.game_constants.starting_inventory
    )

    -- Set up player
    player.cheat_mode = false
    game_control.player_permission_group.add_player(player)
    player.minimap_enabled = true

    -- UI
    UpgradeSystem.create_ui(player)
    local mod_flow = mod_gui.get_frame_flow(player)        
    local wave_ui_frame = WaveCtrl.create_ui(player, game_control.wave_control, mod_flow)
    local caption = game_control.game_constants.hints[game_control.wave_control.spawning_wave_index] or game_control.game_constants.hints[1]
    local label = wave_ui_frame.add{type="label", name="hint_label", caption=caption}
    label.style.visible = true
    label.style.single_line = false

    -- Bonuses
    player.character_running_speed_modifier = 0
end


-- Surface
------------------------------------------------------------------------------
function GameControl.reset_surface(game_control)
    local forces = {game_control.player_force, game_control.neutral_force, game_control.ally_force, game_control.enemy_force, game_control.wave_force}
    local surface = game_control.surface
    local excluded_types = {["cliff"] = true, }
    local excluded_names = {["fish"] = true, }


    if not global.system.saved_entities then
        -- Remove position markers
        for _, ent in pairs(surface.find_entities_filtered{name="centrifuge"}) do 
            ent.destroy()
        end


        -- Save entities for next game
        global.system.saved_entities = {}
        local attributes = {"position", "orientation", "direction", "health", }
        local entity_attributes = {["resource"] = {"amount"}, ["assembling-machine"] = {"recipe"}, ["underground-belt"] = {"type"}, ["train-stop"] = {"backer_name"}, ["radar"] = {"backer_name"}}

        for _, force in pairs(forces) do
            local force_name = force.name
            global.system.saved_entities[force_name] = {}
            for _, ent in pairs(surface.find_entities_filtered{force=force}) do
                local entity_type = ent.type
                local name = ent.name
                if not excluded_types[entity_type] and not excluded_names[name] then
                    local saved_entity = {name = name, force = force_name}
                    for _, attrib in pairs(attributes) do
                        saved_entity[attrib] = ent[attrib]
                    end
                    for _, attrib in pairs(entity_attributes[entity_type] or {}) do
                        saved_entity[attrib] = ent[attrib]
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
        game_control.artillery_turret.insert({name="artillery-shell", count=game_control.game_constants.artillery_initial_ammo})
    end
    
    -- Set enemy units properly
    for _, ent in pairs(surface.find_entities_filtered{type="unit-spawner", force="wave-enemy"}) do
        ent.destructible = false
        ent.active = false
    end
    for _, ent in pairs(surface.find_entities_filtered{type="turret", force="wave-enemy"}) do
        ent.force = game_control.enemy_force
    end

    -- Add loot
    for _, loot_category in pairs(game_control.game_constants.loot) do
        for _, entity_name in pairs(loot_category.entities) do
            for _, ent in pairs(surface.find_entities_filtered{name=entity_name}) do
                if ent.get_inventory(defines.inventory.chest) then
                    for name, count in pairs(loot_category.items) do
                        ent.insert{name=name, count=count}
                        ent.destructible = false
                    end
                else
                    local chests = ScenarioUtils.create_item_chests(surface, ent.position, game_control.neutral_force, loot_category.items) 
                    for _, chest in pairs(chests or {}) do chest.destructible = false end
                end
            end
        end
    end
end




-- Game Start and End

-- global.game_control = {
--     player_force,
--     enemy_force,
--     wave_force,
--     neutral_force,
--     ally_force,
--     surface,
--     lane_marker_surface,
--     player_permission_group,
--     -- ended,
--     -- game_constants,
--     -- active_players,
--     -- rocket_silo,
--     -- artillery_turret
-- }

function GameControl.restart(game_control, difficulty_settings)
    Table.merge_into_first{game_control, {
        ended = false, 
        game_constants = Table.copy(GameControl.game_constants),
        active_players = {},
    }}

    -- Set Difficulty and configure
    GameControl.adjust_game_constants(game_control, difficulty_settings)

    -- Reset Entities
    GameControl.reset_surface(game_control)


    -- Reset Forces
    GameControl.reset_player_force(game_control)
    GameControl.reset_wave_force(game_control)
    GameControl.reset_enemy_force(game_control)
    GameControl.reset_ally_force(game_control)


    -- Starting items
    ScenarioUtils.create_item_chests(
        game_control.surface, 
        game_control.game_constants.player_spawn_position, 
        game_control.player_force, 
        game_control.game_constants.starting_items
    )

    -- Reset Upgrade System
    UpgradeSystem.init(game_control.game_constants.upgrades, game_control.player_force, game_control.game_constants.initial_money)
    
    -- Reset Wave System
    game_control.wave_control = WaveCtrl.init{
        wave_force = game_control.wave_force,
        surface = game_control.surface,
        initial_wait = game_control.game_constants.wave_duration * 2,
    }
    game_control.lane1 = Table.deepcopy(game_control.game_constants.lane1)
    game_control.lane2 = Table.deepcopy(game_control.game_constants.lane2)
    init_waves(game_control)

    -- Setup Players
    for _, player in pairs(game_control.player_force.players) do
        -- Spawn, Gui Creation.
        GameControl.player_enter_game(game_control, player)
    end
end


function GameControl.end_game(game_control, win)        
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



function GameControl.destroy_game()
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

        GameControl.end_game(game_control, false)

        -- Inform Players
        game_control.player_force.print("Rocket Silo died! Game Over.")
        game_control.player_force.play_sound{path="utility/game_lost", }
        
        -- event.cause entity is available, do something with it?
    elseif entity.type == "unit-spawner" and global.game_control and entity.force.name == global.game_control.enemy_force.name then 
        UpgradeSystem.give_money(global.game_control.player_force, game_control.game_constants.spawner_money, global.game_control.surface, {event.entity.position})
    end
end)


Event.register(defines.events.on_player_joined_game, function(event)
    local player = game.players[event.player_index]
    local game_control = global.game_control
    if game_control then
        GameControl.player_enter_game(game_control, player)
    end
end)


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


-- Game Events and Alerts
------------------------------------------------------------------------------



-- Alert players to Wave Start
Event.register(WaveCtrl.on_wave_starting, function(event)
    local game_control = global.game_control
    if event.wave_index > 0 then
        game_control.player_force.play_sound{path="utility/new_objective", }        
        game_control.player_force.print("Wave " .. event.wave_index .. " has started.")
    else
        game_control.player_force.play_sound{path="utility/new_objective", }                
        game_control.player_force.print("First wave starting soon!")
    end
end)


-- Alert players to attacks on silo.
Event.register(-5*60, function()
    local game_control = global.game_control
    if game_control and not game_control.ended then
        if game_control.rocket_silo_health and game_control.rocket_silo_health > game_control.rocket_silo.health then
            game_control.player_force.play_sound{path="utility/scenario_message"}
        end
        game_control.rocket_silo_health = game_control.rocket_silo.health
    end
end)

-- Wave Ended
Event.register(WaveCtrl.on_wave_destroyed, function(event)
    local game_control = global.game_control
    if event.game_ended then
        -- Win
        GameControl.end_game(game_control, true)

        for _, player in pairs(game_control.player_force.players) do
            local score = UpgradeSystem.get_money(game_control.player_force)
            mod_gui.get_frame_flow(player).wave_frame.hint_label.caption = "Final Score: " .. score .. "\n\n" .. game_control.game_constants.ending_message or ""
        end

        game_control.player_force.play_sound{path="utility/game_won", }
        game_control.player_force.print("You win! Congratulations!")
    else
        UpgradeSystem.give_money(global.game_control.player_force, game_control.game_constants.wave_money)
        
        for _, player in pairs(game_control.player_force.players) do
            mod_gui.get_frame_flow(player).wave_frame.hint_label.caption = game_control.game_constants.hints[game_control.wave_control.spawning_wave_index] or ""
        end
        game_control.player_force.play_sound{path="utility/new_objective", }
        game_control.player_force.print("Wave " .. event.wave_index .. " ended. ")
    end
end)




return GameControl