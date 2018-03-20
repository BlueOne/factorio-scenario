
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

    local label = top_flow.add{type="label", caption="Upgrades", tooltip = "Alien Artifacts can be used to buy goods and services."}
    label.style.font = "default-large-bold"
    
    label.style.right_padding = 100
    local value_label = top_flow.add{name="money_label", type="label", caption="0"}
    value_label.style.font_color = UpgradeSystem.artifact_color
    value_label.style.font = "default-large-bold"
    top_flow.add{type="sprite", sprite=UpgradeSystem.artifact_sprite, name="money_sprite", caption=upgrade_system.money, tooltip = "Alien Artifacts"}

    local scroll = frame.add{type = "scroll-pane", name = "upgrade_scroll"}
    scroll.style.maximal_height = 450
    local upgrade_table = scroll.add{type = "table", name = "upgrade_table", column_count = 3}
    --upgrade_table.draw_horizontal_lines = true
    -- upgrade_table.style.horizontal_spacing = 0
    -- upgrade_table.style.vertical_spacing = 0
    

    for _, upgrade in pairs(upgrade_system.available_upgrades) do
        local name = upgrade.name
        local cost_label = upgrade_table.add{type="button", style="icon_button", caption=upgrade.cost, name="upgrade_cost_" .. name, tooltip="Purchase"}
        cost_label.style.height = 30
        cost_label.style.width = 30
        cost_label.style.top_padding = 0
        --local cost_label = upgrade_table.add{type="button", style="recipe_slot_button", caption=upgrade.cost, name="upgrade_cost_" .. name}
        cost_label.style.font_color = UpgradeSystem.artifact_color
        cost_label.style.font = "default-bold"
        upgrade_table.add{type="sprite", name="upgrade_sprite_" .. name, sprite=upgrade.icon}
        upgrade_table.add{type="label", name="upgrade_name_" .. name, caption=formatted_upgrade_name(upgrade) .. "  [?]", tooltip=upgrade.description}
    end

        
    GuiUtils.make_hide_button(player, frame, true, UpgradeSystem.artifact_sprite)
end

function UpgradeSystem.get_ui(player)
    return mod_gui.get_frame_flow(player).upgradeframe
end
    

-- Award money
-------------------------------------------------------------------------------

function UpgradeSystem.give_money(force, amount, surface, position)
    local upgrade_system = UpgradeSystem.get_force_upgrade_system(force)
    upgrade_system.money = upgrade_system.money + amount
    if surface and position then
        local text
        if amount > 0 then
            text = "+" .. amount
        else
            text = "-" .. amount
        end
        surface.create_entity{name = "flying-text", position = position, text = text, color = UpgradeSystem.artifact_color}    
    end

    for _, player in  pairs(upgrade_system.force.players) do
        local upgradeframe = UpgradeSystem.get_ui(player)
        if upgradeframe then
            upgradeframe.top_flow.money_label.caption = upgrade_system.money
        end
    end
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
    else
        local error
        if upgrade.action then 
            error = upgrade.action(global.game_control, upgrade) 
        elseif upgrade.unlock then
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
                    game.print("Error: Technology Unlock not found: " .. tech .. ". This may constitute a bug.")
                end
            end
        end
        
        if not error then
            upgrade_system.force.print("Purchased Upgrade: " .. formatted_upgrade_name(upgrade))
            UpgradeSystem.give_money(upgrade_system.force, -upgrade.cost)
            if level >= level_max then
                upgrade_system.available_upgrades[upgrade_key] = nil
                for _, player in pairs(upgrade_system.force.players) do
                    local frame = UpgradeSystem.get_ui(player)
                    local table = frame.upgrade_scroll.upgrade_table
                    table["upgrade_sprite_" .. upgrade.name].destroy()
                    table["upgrade_cost_" .. upgrade.name].destroy()
                    table["upgrade_name_" .. upgrade.name].destroy()
                end
            else
                -- Update cost
                if upgrade.cost_increase == "linear" or not upgrade.cost_increase then
                    upgrade.cost = upgrade.cost + 1
                elseif upgrade.cost_increase == "double" then
                    upgrade.cost = upgrade.cost * 2
                end
                upgrade.level = level + 1
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
        else
            buying_player.print("Purchase failed: Unrecognized error." .. serpent.block(error))
        end
    end
end


--  System
-------------------------------------------------------------------------------

function UpgradeSystem.init(upgrades, force, money)
    local upgrade_system = {
        force = force or game.forces.player, 
        available_upgrades = Table.deepcopy(upgrades), 
        money = money or 0
    }

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