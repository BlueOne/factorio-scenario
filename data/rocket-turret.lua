
local ProtUtils = require("Utils.Prototype")
local Table = require("Utils.Table")
local S = "__towerdefense__"


-- Rocket Turret related prototypes

-- Copy from gun turret
local entity, item, recipe = ProtUtils.new_entity("rocket-turret", "gun-turret", "ammo-turret")


-- Prepare Entity
local function rocket_turret_extension(inputs)
  return
  {
    filename = S .. "/graphics/entity/missile-turret-place.png",
    priority = "medium",
    line_length = 1;
    width = 90,
    height = 90,
    direction_count = 8,
    frame_count = inputs.frame_count and inputs.frame_count or 1,
    run_mode = inputs.run_mode and inputs.run_mode or "forward",
    shift = {0, -0.7},
    axially_symmetrical = false
  }
end

-- Set up entity
Table.merge_into_first{entity, {
  icon = S .. "/graphics/icons/rocket-turret.png",
  max_health = 600,
  collision_box = {{-0.7, -0.7 }, {0.7, 0.7}},
  selection_box = {{-1, -1 }, {1, 1}},
  rotation_speed = 0.015,
  preparing_speed = 0.08,
  folding_speed = 0.08,
  dying_explosion = "medium-explosion",
  attacking_speed = 0.5,  
  folded_animation = 
  {
    layers =
    {
      rocket_turret_extension{frame_count=1, line_length = 1}
    }
  },
  preparing_animation = 
 {
    layers =
    {
      rocket_turret_extension{}
    }
  },
  prepared_animation = 
  {
    layers =
    {
      {
         filename = S .. "/graphics/entity/missile-turret-sheet.png",
         line_length = 4,
         width = 90,
         height = 90,
         frame_count = 1,
         axially_symmetrical = false,
         direction_count = 32,
         shift = {0,-0.7},
      }
    }
  },
  folding_animation = 
  { 
    layers = 
    { 
      rocket_turret_extension{run_mode = "backward"}
    }
  },

  vehicle_impact_sound =  { filename = "__base__/sound/car-metal-impact.ogg", volume = 0.65 },
  turret_base_has_direction = true,
  
  attack_parameters =
  {
    type = "projectile",
    ammo_category = "rocket",
    cooldown = 75,
    projectile_creation_distance = 1.39375,
    projectile_center = {0.0625, -0.0875}, -- same as rocket_turret_attack shift
    damage_modifier = 1, --1.2  
    shell_particle =
    {
      name = "shell-particle",
      direction_deviation = 0.1,
      speed = 0.1,
      speed_deviation = 0.03,
      center = {0, 0},
      creation_distance = -1.925,
      starting_frame_speed = 0.2,
      starting_frame_speed_deviation = 0.1
    },
    turn_range = 0.28,
    range = 30,
    min_range = 10,
    sound =
    {
      {
        filename = "__base__/sound/fight/rocket-launcher.ogg",
        volume = 0.85
      }
    }

  },
  call_for_help_radius = 40
}}

entity.base_picture = nil



-- Set up Item
Table.merge_into_first{item, 
  {
    icon = S .. "/graphics/icons/rocket-turret.png",
    order = "b[turret]-b-b",
    stack_size = 20,
  }
}

-- Set up Recipe
Table.merge_into_first{recipe,
  {
    enabled = false,
    energy_required = 15,
    ingredients =
    {
      {"iron-gear-wheel", 10},
      {"copper-plate", 20},
      {"steel-plate", 15},
      {"advanced-circuit", 10},
    },
  },
}

local tech = Table.deepcopy(ProtUtils.technology("rocket-damage-2"))
Table.merge_into_first{tech, {
  name = "rocket-turret",
  icon_size=128,
  icon = S .. "/graphics/icons/rocket-turret-l.png",
  effects =
  {
    {
      type = "unlock-recipe",
      recipe = "rocket-turret"
    }
  },
  prerequisites = {"turrets", "rocketry"},
}, 
}


data:extend{entity, item, recipe, tech}


local techs = {}
for i = 1, 7 do 
  tech = Table.deepcopy(ProtUtils.technology("flamethrower-damage-" .. i))
  Table.merge_into_first{tech, 
  {
    name = "rocket-turret-damage-" .. i,
    icon = S .. "/graphics/icons/rocket-turret-l.png",
    effects = {
      {
        type = "turret-attack",
        turret_id = "rocket-turret",
        modifier = tech.effects[2].modifier,
      }
    },
  }}
  if i > 1 then 
    tech.prerequisites = {"rocket-turret-damage-" .. i-1}
  else
    tech.prerequisites = {"rocket-turret"}
  end
  table.insert(techs, tech)
end

data:extend(techs)


