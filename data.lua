local S = "__towerdefense__"


require("data/rocket-turret")

local ProtUtils = require("Utils.Prototype")
local Table = require("Utils.Table")



data:extend{
    {
        type = "item",
        name = "alien-artifact",
        icon = S .. "/graphics/icons/alien-artifact.png",
        icon_size = 32,
        flags = {"goes-to-main-inventory"},
        subgroup = "raw-material", 
        order = "g[alien-artifact]",
        stack_size = 1000
    },
}




-- Short range artillery turret
local entity, item, recipe = ProtUtils.new_entity("artillery-turret-medium-range", "artillery-turret", "artillery-turret")
local gun = Table.copy(ProtUtils.gun("artillery-wagon-cannon"))

entity.manual_range_modifier = 1
entity.gun = "artillery-wagon-cannon-medium-range"
gun.name = "artillery-wagon-cannon-medium-range"
gun.attack_parameters.range = 5 * 32

data:extend{entity, item, recipe, gun}


-- Sound
local function add_utility_sound(name, filename)
    data.raw["utility-sounds"]["default"][name] =
    {
        {
            filename = filename
        }
    }
end
add_utility_sound("message", "__core__/sound/message.ogg")