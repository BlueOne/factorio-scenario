-- control.lua

-- Tower Defense Scenario control



-- Modules
-------------------------------------------------------------------------------


local Table = require("Utils.Table")
local ScenarioUtils = require("Utils.Scenario")

local Event = require("stdlib.event.event")

local WaveCtrl = require("wave_control")
local UpgradeSystem = require("upgrade_system")


local TableGUI = require("Utils.TableViewer")


-- TODO
-------------------------------------------------------------------------------

-- Biters attack things.
-- Voting UI
-- difficulty ui
-- outside game system
-- Debug current code
-- Reset surface

-- Map
--  => Edit forces of entities and active/inactive
--  => More Resources?
--  => Place parts of base?

-- Actual Waves
-- Balance Difficulty levels

-- Multiplayer Debugging
-- Stability Testing


-- Later:
-- Determine Wave Group movement ticks in advance so they are not as staggered
-- Reset Entities could be distributed over multiple ticks. Also can we make it more performant?
-- UIs needs more touches
-- Handle Blueprints in player inventory when restarting
-- decoratives and remnants on map
-- Gfx effects for upgrade purchase - at player and affected entity.


-- Done: 
-- Map script data
-- Upgrade and Money System
-- Upgrade Data
-- Wave System
-- Loot (basic)
-- Starting inventory and equipment data
-- Starting inventory and equipment system
-- Forces, players set up





-- Game Constants
-------------------------------------------------------------------------------


local buffers = {{x = 180.5, y = 57.5}, {x = 186.5, y = 41.5}, {x = 187.5, y = 51.5}, {x = 187.5, y = 64.5}, {x = 177.5, y = 73.5}, {x = 181.5, y = 90.5}, {x = 187.5, y = 83.5}, {x = 199.5, y = 59.5}, {x = 207.5, y = 52.5}, {x = 214.5, y = 45.5}, {x = 217.5, y = 53.5}, {x = 197.5, y = 81.5}, {x = 204.5, y = 87.5}, {x = 217.5, y = 72.5}, {x = 221.5, y = 84.5}, {x = 226.5, y = 59.5}, {x = 233.5, y = 52.5}, {x = 231.5, y = 83.5}, {x = 233.5, y = 65.5}, {x = 237.5, y = 75.5}}
local buffers_1 = {}
local buffers_2 = {}
for _, p in pairs(buffers) do
    if p.x < 210 then
        table.insert(buffers_1, p)
    else
        table.insert(buffers_2, p)
    end
end

local scenario_constants = {
    spawner_money = 2,
    wave_money = 4,
    player_spawn_position = {105, -75},
    artillery_initial_ammo = 3,
    lane1 = {
        weight = 1,
        path = {{201, 66}, {168, 44}, {121, 0}, {121, -50}, {162.5, -72}},
        disabled = false,
        buffers = buffers_1
    },
    lane2 = {
        weight = 0.5, 
        path = {{213, 71}, {208, 29}, {209, -63}, {197, -75}, {147, -75}, {162.5, -72}},
        disabled = false,
        buffers = buffers_2
    },
    blocking_turrets = {
        {209, -32},
        {212, -32}
    },
    starting_inventory = {
        ["steel-axe"] = 20,
        --["submachine-gun"] = 1,
        --["firearm-magazine"] = 20,
        ["artillery-targeting-remote"] = 1,
        ["modular-armor"] = {
            type="armor",
            equipment = {
                "night-vision-equipment",
                {name="energy-shield-equipment", count=2},
                {name="battery-equipment", count = 2},
                {name="solar-panel-equipment", count = "fill"}
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
        ["small-electric-pole"] = 400,
        ["big-electric-pole"] = 50,
        ["small-lamp"] = 200,
        ["pipe"] = 300,
        ["transport-belt"] = 500,
        ["underground-belt"] = 100,
        ["splitter"] = 50,
        ["inserter"] = 200,
        ["electric-mining-drill"] = 200,
        ["steel-furnace"] = 200,
        ["assembling-machine-2"] = 30,
        ["boiler"] = 30,
        ["steam-engine"] = 60,
        ["pumpjack"] = 10,
        ["oil-refinery"] = 4,
        ["chemical-plant"] = 10,
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
        "railway",
        "automated-rail-transportation",
        "rail-signals",
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
        "flammables",
        "flamethrower",
        "advanced-electronics",
        "inserter-capacity-bonus-1",
        "inserter-capacity-bonus-2",
    },

    lock_recipes = {
        "science-pack-1",
        "science-pack-2",
        "science-pack-3",
        "military-science-pack",
        "production-science-pack",
        "hightech-science-pack"
    },


    upgrades = {
        {
            name = "Repair",
            description = "Repair the silo by 500 Health.";
            cost = 1,
            level_max = 50,
            icon = "item/repair-pack",
            action = function(game_control, upgrade_data)
                if not game_control.rocket_silo or not game_control.rocket_silo.valid then
                    return "The Rocket Silo seems to be unavailable."
                end

                if game_control.rocket_silo.health > 3000 then 
                    return "Rocket silo is missing less 500 health!"
                else
                    game_control.rocket_silo.health = game_control.rocket_silo.health + 2000
                end
            end
        },
        {
            name = "Artillery Shell",
            description = "Add an artillery shell to the artillery turret.",
            cost = 1,
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
            cost = 4,
            icon = "item/piercing-rounds-magazine",
            unlock = {
                "bullet-damage",
                "bullet-speed"
            },
            level_max = 5,
        },
        {
            name = "Turret Upgrade",
            description = "Upgrades turret damage.",
            cost = 3,
            icon = "item/gun-turret",
            unlock = "gun-turret-damage",
            level_max = 5,
        },
        {
            name = "Laser Turret Upgrade",
            description = "Upgrades laser turret damage and shooting speed.",
            cost = 3,
            icon = "item/laser-turret",
            unlock = {
                "laser-turret-damage",
                "laser-turret-speed",
            },
            level_max = 5,
        },
        {
            name = "Flame Thrower Upgrade",
            description = "Upgrades laser turret damage and shooting speed.",
            cost = 4,
            icon = "item/flamethrower-turret",
            unlock = {
                "flamethrower-damage",
            },
            level_max = 5,
        },
        {
            name = "Shotgun Shell Upgrade",
            description = "Upgrades shotgun damage and shooting speed.",
            cost = 2,
            icon = "item/shotgun-shell",
            unlock = {
                "shotgun-shell-damage",
                "shotgun-shell-speed",
            },
            level_max = 4,
        },
        {
            name = "Nuclear Technology",
            description = "Unlocks uranium ammo and nuclear bombs (by the way, there is no friendly fire in this mode).",
            cost = 10,
            icon = "item/uranium-rounds-magazine",
            unlock = {
                "nuclear-power",
                "uranium-ammo",
                "atomic-bomb",
            }
        },
        {
            name = "Faster Hands",
            description = "Increases handcrafting speed and mining speed by 300%",
            cost = 5,
            icon = "item/iron-axe",
            action = function(game_control, upgrade_data)
                game_control.player_force.manual_crafting_speed_modifier = game_control.player_force.manual_crafting_speed_modifier + 3
                game_control.player_force.manual_mining_speed_modifier = game_control.player_force.manual_mining_speed_modifier + 3
            end
        },
        {
            name = "Faster Movement",
            description = "Increases running speed by 200%",
            cost = 5,
            icon = "item/exoskeleton-equipment",
            action = function(game_control, upgrade_data)
                game_control.player_force.character_running_speed_modifier = game_control.player_force.character_running_speed_modifier + 2
            end
        },
            -- TODO: this
            -- explosive = {
            --     name = "Explosion Technology",
            --     description = "Unlocks rockets and rocket turrets."
            --     cost = 20,
            --     unlock = {
            --         "rocketry",
            --         "explosives",
            --     }
            -- }
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
            entities = {"large-ship-wreck-1", "large-ship-wreck-2", "large-ship-wreck-3"},
            items = {
                ["nuclear-bomb"] = 2,
                ["artillery-shell"] = 2,
            }
        }
        -- small = {entities = {"small-ship-wreck"}, items={}},
    }
}

scenario_constants.hints = {
    "Biter waves will come to attack your rocket silo. You win if you survive all waves. You lose if you silo falls. The silo starts at 500 health out of 5000 but you can repair it if you need to.",
    "At the start of each wave your team will receive " .. scenario_constants.wave_money .. " alien artifacts. These can be used to purchase upgrades.",
    "The aliens on the left half of the map are peaceful, but their buildings drop " .. scenario_constants.spawner_money .. " alien artifacts each.",
    "Your team has an artillery turret which you can use to kill biters in an emergency.",
    "The purchasable upgrades often correspond to technologies, for example Bullet Upgrade 1 unlocks the Bullet Damage 1 and Bullet Shooting Speed 1 technologies.",
    "You cannot hurt your team mates, buildings or the rocket silo. This makes artillery and nukes a bit easier to use. Try it!",
    "You will not be able to beat big biters using basic firearm magazines only.",
    "You can shoot at a lane manually in an emergency but it will cost you precious time. Remember you also have the artillery turret.",
}
-- spoilers = {
--     "The second lane has about half as many biters as the first one.",
-- },




-- Init Wave System
-------------------------------------------------------------------------------


-- TODO: Finish this
local function make_wave(unit_str, factor, duration, size)
    if duration == true then 
        duration = 60*60*7 
    elseif duration == nil then 
        duration = 60*60*2
    end

    local wave = {
        lanes = {global.game_control.lane1, global.game_control.lane2},
        group_size = size or 15,
        group_time_factor = 15,
        unit = {unit_str, (factor or 10)},
        duration = duration
    }

    WaveCtrl.make_wave(global.game_control.wave_control, wave)
end

local function init_waves()
    -- 1
    make_wave("aaaa", 1, 60*60*4)
    make_wave("1aaaa")
    make_wave("111aa")
    make_wave("1111b")
    make_wave("11bbb")
    -- 6
    make_wave("11bbb")
    make_wave("2bbb1")
    make_wave("22bb1")
    make_wave("2222b")
    make_wave("2222222bb11")
    -- 11
    make_wave("22cbb")
    make_wave("22ccc")
    make_wave("3222b")
    make_wave("33222")
    make_wave("333cc")
    -- 16
    make_wave("33333cc11")
    make_wave("3333333")
    make_wave("4")
    make_wave("4d3c")
    make_wave("44d33")
    -- 21
    make_wave("444dd")
    make_wave("444444")
    make_wave("4444dd333ccc")
    make_wave("444444444444")
    -- make_wave("11111")
    -- make_wave("22222")
    -- make_wave("33333")
end




-- Init Upgrade System
-------------------------------------------------------------------------------

Event.register(defines.events.on_entity_died, function(event)
    if event.entity.type == "unit-spawner" and global.game_control and event.entity.force.name == global.game_control.enemy_force.name then 
        UpgradeSystem.give_money(global.game_control.player_force, scenario_constants.spawner_money, global.game_control.surface, event.entity.position)
    end
end)

Event.register(WaveCtrl.on_wave_starting, function(event)
    UpgradeSystem.give_money(global.game_control.player_force, scenario_constants.wave_money)
end)




-- Reset Forces
-------------------------------------------------------------------------------

local function reset_player_force(game_control)
    local force = game_control.player_force

    force.reset()
    force.disable_research()
    force.chart_all()
    force.set_spawn_position(scenario_constants.player_spawn_position, game_control.surface)

    force.friendly_fire = false
    force.set_cease_fire(game_control.player_force, false)
    force.set_cease_fire(game_control.enemy_force, false)
    force.set_cease_fire(game_control.wave_force, false)
    force.set_friend(game_control.ally_force, true)
    force.set_friend(game_control.enemy_force, false)
    
        

    -- Research Techs
    for _, tech in pairs(scenario_constants.unlock_technologies) do
        if force.technologies[tech] then
            force.technologies[tech].researched = true
        end
    end

    -- Lock recipes
    for _, recipe in pairs(scenario_constants.lock_recipes) do
        if force.recipes[recipe] then
            force.recipes[recipe].enabled = false
        end
    end

    
    -- Hide Techs
    for _, tech in pairs(force.technologies) do
        if not tech.researched then --and not Table.find(tech.name, scenario_constants.available_techs) then
            tech.enabled = false
        end
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
        player.minimap_enabled = true

        UpgradeSystem.create_ui(player)
        WaveCtrl.create_ui(player)
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

    -- Set special entities
    game_control.rocket_silo = game_control.surface.find_entities_filtered{type="rocket-silo", limit=1}[1]
    game_control.rocket_silo.minable = false
    game_control.artillery_turret = game_control.surface.find_entities_filtered{type="artillery-turret", limit=1}[1]
    game_control.artillery_turret.minable = false
    game_control.artillery_turret.insert({name="artillery-shell", count=scenario_constants.artillery_initial_ammo})
    if scenario_constants.blocking_turrets then
        game_control.lane_blocking_turrets = {}
        for i, pos in pairs(scenario_constants.blocking_turrets) do
            local ent = surface.find_entity("gun-turret", pos)
            if ent then 
                game_control.lane_blocking_turrets[i] = ent
            end
        end
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
        initial_wait = 8 * 60 * 60,
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
        -- TODO: Save blueprints?
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
    if not game_control then return end

    -- Game End
    if entity.name == "rocket-silo" then 
        end_game(game_control, false)

        -- Inform Players
        game_control.player_force.print("Rocket Silo died! Game Over.")
        -- event.cause entity is available, do something with them?
    -- Unlock Lane 2
    -- elseif entity.name == "ammo-turret" and game_control.lane_blocking_turrets then
    --     for k, turret in pairs(game_control.lane_blocking_turrets) do
    --         if Table.compare(entity.position, turret.position) then
    --             game_control.lane_blocking_turrets[k] = nil
    --             if not next(game_control.lane_blocking_turrets[k]) then
    --                 local p = entity.position
    --                 local area = {{p.x - 10, p.y - 10}, {p.x + 10, p.y + 10}}
    --                 for _, ent in pairs(game_control.surface.find_entities_filtered{force=game_control.wave_force, area=area}) do
    --                     ent.die()
    --                 end
    --                 game.print("They've broken through the eastern bridge defenses!")
    --             end
    --             break
    --         end
    --     end
    end
end)


-- Win
Event.register(WaveCtrl.on_wave_destroyed, function(event)
    if event.game_ended then
        local game_control = global.game_control
        end_game(game_control, true)
        game_control.player_force.print("You win! Congratulations!")
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
        lobby_surface = lobby_surface
        -- saved_entities = {force = {}},
        -- lobby_position_index = 1,
    }
    global.system = system
    global.game_control = {
        player_force = system.player_force,
        enemy_force = system.enemy_force,
        wave_force = system.wave_force,
        neutral_force = system.neutral_force,
        ally_force = system.ally_force,
        surface = system.surface,
        ended = false,
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
    TableGUI.add_table(ui, global.game_control)
end)