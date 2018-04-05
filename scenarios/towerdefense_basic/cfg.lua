-- cfg.lua
-- Important Configuration Options

local cfg = {
    -- The scenario can be played as a soft-mod or normal mod. In soft-mod 
    -- mode, the scenario can be played in multiplayer without having the 
    -- mod installed. However the artillery turret and rocket turret are not 
    -- available. To start the game in softmod-mode, copy the directory of this 
    -- scenario to the scenario directory of your factorio installation 
    -- (google it if you need) and set the following to false.
    is_mod = true ,

    -- Difficulty can be selected by all players via vote or by admin.
    -- If this is not multiplayer then this choice is ignored.
    -- If no admin is present then the difficulty will be decided via vote 
    -- regardless of the choice given here.
    select_difficulty_via_vote = true,
}

return cfg