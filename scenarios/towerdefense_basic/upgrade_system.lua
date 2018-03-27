
-- Upgrade System
-------------------------------------------------------------------------------
-- Shared per force, each force can have at most one.


-- Modules
-------------------------------------------------------------------------------

local UpgradeSystem = {}

local mod_gui = require("mod-gui")
local GuiUtils = require("Utils.Gui")
local Table = require("Utils.Table")
local Event = require("stdlib.event.event")
local GuiEvent = require("stdlib.event.gui")




-- Constants
-------------------------------------------------------------------------------

UpgradeSystem.artifact_color = {r = 1, g = 0.5, b = 0.7, a = 1}
--local red_color = {r=1, g=0.1, b=0.1, a=0.2}
UpgradeSystem.artifact_sprite = "item/alien-artifact"
UpgradeSystem.artifact_tooltip = "Obtain Alien Artifacts by killing waves or spawners."




-- Globals
-------------------------------------------------------------------------------

global.UpgradeSystem = global.UpgradeSystem or {
    upgrade_systems_by_force = {}
}

function UpgradeSystem.get_force_upgrade_system(force)
    return global.UpgradeSystem.upgrade_systems_by_force[force.name]
end

function UpgradeSystem.get_player_upgrade_system(player)
    return global.UpgradeSystem.upgrade_systems_by_force[player.force.name]
end




-- Utils
-------------------------------------------------------------------------------

local function formatted_upgrade_name(upgrade)
    local text = upgrade.name
    if upgrade.level or upgrade.level_max then
        text = text .. " " .. (upgrade.level or 1)
    end
    return text
end




-- UI
-------------------------------------------------------------------------------

function UpgradeSystem.destroy_ui(player)
    local gui = mod_gui.get_frame_flow(player)
    if gui.upgradeframe then
        GuiUtils.remove_hide_button(player, gui.upgradeframe)
        gui.upgradeframe.destroy()
    end
end

function UpgradeSystem.create_ui(player)
    local upgrade_system = UpgradeSystem.get_player_upgrade_system(player)
    local gui = mod_gui.get_frame_flow(player)
    if gui.upgradeframe and gui.upgradeframe.valid then
        UpgradeSystem.destroy_ui(player)
    end
    local frame = gui.add{type="frame", name = "upgradeframe", direction = "vertical"}
    frame.style.visible = false
    local top_flow = frame.add{name="top_flow", type="flow", direction = "horizontal"}

    local label = top_flow.add{type="label", caption="Upgrades", tooltip = UpgradeSystem.artifact_tooltip}
    label.style.font = "default-large-bold"
    
    label.style.right_padding = 100
    local value_label = top_flow.add{name="money_label", type="label", caption=upgrade_system.money or 0, tooltip = UpgradeSystem.artifact_tooltip}
    value_label.style.font_color = UpgradeSystem.artifact_color
    value_label.style.font = "default-large-bold"
    top_flow.add{type="sprite", sprite=UpgradeSystem.artifact_sprite, name="money_sprite", caption=upgrade_system.money, tooltip = UpgradeSystem.artifact_tooltip}

    local scroll = frame.add{type = "scroll-pane", name = "upgrade_scroll"}
    scroll.style.maximal_height = 440
    scroll.add{type = "table", name = "upgrade_table", column_count = 3}
    --upgrade_table.draw_horizontal_lines = true
    -- upgrade_table.style.horizontal_spacing = 0
    -- upgrade_table.style.vertical_spacing = 0
    

    for _, upgrade in pairs(upgrade_system.available_upgrades) do
        if not upgrade.disabled then
            UpgradeSystem.add_upgrade_to_ui(upgrade, player)
        end
    end

        
    GuiUtils.make_hide_button(player, frame, true, UpgradeSystem.artifact_sprite)
end

function UpgradeSystem.add_upgrade_to_ui(upgrade, player)
    local parent = mod_gui.get_frame_flow(player).upgradeframe.upgrade_scroll.upgrade_table
    local name = upgrade.name
    local cost_label = parent.add{type="button", style="icon_button", caption=upgrade.cost, name="upgrade_cost_" .. name, tooltip="Purchase"}
    upgrade.cost_label = cost_label
    cost_label.style.height = 30
    cost_label.style.width = 30
    cost_label.style.top_padding = 0
    --local cost_label = upgrade_table.add{type="button", style="recipe_slot_button", caption=upgrade.cost, name="upgrade_cost_" .. name}
    cost_label.style.font_color = UpgradeSystem.artifact_color
    cost_label.style.font = "default-bold"
    parent.add{type="sprite", name="upgrade_sprite_" .. name, sprite=upgrade.icon}
    parent.add{type="label", name="upgrade_name_" .. name, caption=formatted_upgrade_name(upgrade) .. "  [?]", tooltip=upgrade.description}
end

function UpgradeSystem.get_ui(player)
    return mod_gui.get_frame_flow(player).upgradeframe
end
    

-- Money
-------------------------------------------------------------------------------

function UpgradeSystem.give_money(force, amount, surface, positions)
    local upgrade_system = UpgradeSystem.get_force_upgrade_system(force)
    upgrade_system.money = upgrade_system.money + amount
    if surface then
        for _, position in pairs(positions or {}) do
            local text
            if amount > 0 then
                text = "+" .. amount
            else
                text = "-" .. amount
            end
            surface.create_entity{name = "flying-text", position = position, text = text, color = UpgradeSystem.artifact_color}    
        end
    end

    for _, player in  pairs(upgrade_system.force.players) do
        local upgradeframe = UpgradeSystem.get_ui(player)
        if upgradeframe then
            upgradeframe.top_flow.money_label.caption = upgrade_system.money
        end
    end
end

function UpgradeSystem.get_money(force) 
    local upgrade_system = UpgradeSystem.get_force_upgrade_system(force)
    return upgrade_system.money
end


-- Buy upgrade
-------------------------------------------------------------------------------

function UpgradeSystem.purchase_upgrade(upgrade_key, buying_player)
    local upgrade_system = UpgradeSystem.get_player_upgrade_system(buying_player)
    local upgrade = upgrade_system.available_upgrades[upgrade_key]
    local level = upgrade.level or 1
    local level_max = upgrade.level_max or 0

    if upgrade_system.money < upgrade.cost then
        buying_player.print("Purchase failed: Not enough money!")
        buying_player.play_sound{path="utility/cannot_build"}
    else
        local error
        if upgrade.action then 
            error = upgrade.action(global.game_control, upgrade) 
        end
        if not error and upgrade.unlock then
            local unlock = upgrade.unlock
            if type(unlock) == "string" then unlock = {unlock} end
            for _, tech in pairs(unlock) do
                local found = false
                for _, suffix in pairs({"", "-" .. level}) do
                    local technology = upgrade_system.force.technologies[tech .. suffix]
                    if technology then 
                        technology.researched = true
                        found = true
                    end
                end
                if not found then
                    buying_player.print("Purchase failed: Not enough money!")
                    game.print("Error: Technology Unlock not found: " .. tech .. ". This may constitute a bug.")
                end
            end
        end
        
        if not error then

            -- Inform player
            upgrade_system.force.play_sound{path="utility/research_completed", }        
            upgrade_system.force.print("Purchased: " .. formatted_upgrade_name(upgrade))

            for _, player in pairs(upgrade_system.force.players) do
                if player.character then
                    player.surface.create_entity{name = "flying-text", position = player.position, text = "Purchased: " .. formatted_upgrade_name(upgrade), color={r=0.2, g=1, b=0.3}}
                end
            end
            
            -- Prerequisites
            for _, upgr in pairs(upgrade_system.available_upgrades) do
                if upgr.disabled and upgr.prerequisites then
                    for i, prereq in pairs(upgr.prerequisites) do
                        if prereq == upgrade.name then
                            upgr.prerequisites[i] = nil
                            if not next(upgr.prerequisites) then
                                upgr.disabled = false
                                for _, player in pairs(upgrade_system.force.players) do
                                    UpgradeSystem.add_upgrade_to_ui(upgr, player)
                                end
                            end
                        end
                    end
                end
            end

            -- Take money
            UpgradeSystem.give_money(upgrade_system.force, -upgrade.cost)

            if level >= level_max then
                -- Remove upgrade
                upgrade_system.available_upgrades[upgrade_key] = nil
                for _, player in pairs(upgrade_system.force.players) do
                    local frame = UpgradeSystem.get_ui(player)
                    local table = frame.upgrade_scroll.upgrade_table
                    table["upgrade_sprite_" .. upgrade.name].destroy()
                    table["upgrade_cost_" .. upgrade.name].destroy()
                    table["upgrade_name_" .. upgrade.name].destroy()
                end
            else
                -- Set level
                upgrade.level = level + 1

                -- Update cost
                if type(upgrade.cost_increase) == "number" then
                    upgrade.cost = upgrade.cost + upgrade.cost_increase
                elseif upgrade.cost_increase == "linear" or not upgrade.cost_increase then
                    upgrade.cost = upgrade.cost + 1
                elseif upgrade.cost_increase == "double" or upgrade.cost_increase == "exponential" then
                    upgrade.cost = upgrade.cost * 2
                elseif upgrade.cost_increase == "constant" then --luacheck: ignore
                    -- Pass
                else
                    game.print("Unrecognized cost increase value. This may constitute a bug.")
                end

                -- Update UI
                for _, player in pairs(upgrade_system.force.players) do
                    local frame = UpgradeSystem.get_ui(player)
                    local table = frame.upgrade_scroll.upgrade_table
                    table["upgrade_cost_" .. upgrade.name].caption = upgrade.cost
                    table["upgrade_name_" .. upgrade.name].caption = formatted_upgrade_name(upgrade) .. "  [?]"
                end
            end

            return true


        elseif type(error) == "string" then 
            buying_player.print("Purchase failed: " .. error)
            buying_player.play_sound{path="utility/cannot_build", }            
        else
            buying_player.print("Purchase failed: Unrecognized error." .. serpent.block(error))
            buying_player.play_sound{path="utility/cannot_build", }            
        end
    end
end


--  System
-------------------------------------------------------------------------------

-- upgrades is a list of upgrades, each upgrade has the form 
-- {
--     name = "name",
--     description = "Long Description",
--     cost = 5,
--     icon = "item/lab", -- spritepath
--     max_level = 2, -- optional, if given this upgrade will get multiple levels
--     cost_increase = "double", -- if this upgrade has multiple levels, this determines the way the costs are determined. Can be a number or "double"/"exponential". If given a number, the cost will increase by that count each time. 1 is default.
--     unlocks = {
--         tech1, 
--         tech2, 
--     }
--     action = function(game_control, upgrade_data)
--         WaveCtrl.delay_wave(game_control.wave_control, 3 * 60 * 60)
--     end
-- }


function UpgradeSystem.init(upgrades, force, money)
    local upgrade_system = {
        force = force or game.forces.player, 
        available_upgrades = Table.deepcopy(upgrades), 
        money = money or 0
    }

    for _, upgrade in pairs(upgrade_system.available_upgrades) do
        if next(upgrade.prerequisites or {}) then
            upgrade.disabled = true
        end
    end
    global.UpgradeSystem.upgrade_systems_by_force[force.name] = upgrade_system
    return upgrade_system
end

function UpgradeSystem.destroy(force)
    global.UpgradeSystem.upgrade_systems_by_force[force.name] = nil
    for _, player in pairs(force.players) do
        UpgradeSystem.destroy_ui(player)
    end
end

-- Register to button clicks
GuiEvent.on_click("upgrade_cost_(.*)", function(event)
    local player = game.players[event.player_index]
    local upgrade_system = UpgradeSystem.get_player_upgrade_system(player)
    for k, upgrade in pairs(upgrade_system.available_upgrades) do
        if upgrade.name == event.match then
            UpgradeSystem.purchase_upgrade(k, player)
        end
    end
end)

-- GuiUtils.register_element_group("upgrade_cost", function(event, player, button_name)
--     local upgrade_system = UpgradeSystem.get_player_upgrade_system(player)
--     for k, upgrade in pairs(upgrade_system.available_upgrades) do
--         if upgrade.name == button_name then
--             UpgradeSystem.purchase_upgrade(k, player)
--         end
--     end
-- end)


return UpgradeSystem