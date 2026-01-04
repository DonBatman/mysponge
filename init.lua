local modname = core.get_current_modname()

local states = {
    {id = "dry",    desc = "Dry Sponge",    tex = "mysponge_sponge.png",  size = 0.5,  inv = true},
    {id = "moist",  desc = "Moist Sponge",  tex = "mysponge_sponge2.png", size = 0.7,  inv = false},
    {id = "wet",    desc = "Wet Sponge",    tex = "mysponge_sponge3.png", size = 0.85, inv = false},
    {id = "soaked", desc = "Soaked Sponge", tex = "mysponge_sponge3.png", size = 1.0,  inv = false},
}

local function dry_nearby_leaves(pos)
    local radius = 1
    local found = false
    for x = -radius, radius do
        for y = -radius, radius do
            for z = -radius, radius do
                local p = {x=pos.x+x, y=pos.y+y, z=pos.z+z}
                local node = core.get_node(p).name
                if core.get_item_group(node, "leaves") > 0 then
                    core.set_node(p, {name = modname .. ":dry_leaves"})
                    found = true
                end
            end
        end
    end
    return found
end

local function absorb_water(pos)
    local radius = 5
    local minp = vector.subtract(pos, radius)
    local maxp = vector.add(pos, radius)
    local nodes = core.find_nodes_in_area(minp, maxp, {"group:water"})
    
    if #nodes > 0 then
        for _, p in ipairs(nodes) do
            core.set_node(p, {name = modname .. ":air_temp"})
        end
        core.sound_play("default_water_footstep", {pos = pos, gain = 0.5})
        return true
    end
    return false
end

for _, state in ipairs(states) do
    local box_size = state.size / 2
    local groups = {dig_immediate = 2}
    if not state.inv then groups.not_in_creative_inventory = 1 end

    core.register_node(modname .. ":sponge_" .. state.id, {
        description = state.desc,
        tiles = {state.tex},
        drawtype = "nodebox",
        paramtype = "light",
        groups = groups,
        node_box = {
            type = "fixed",
            fixed = {-box_size, -0.5, -box_size, box_size, -0.5 + state.size, box_size},
        },
        after_place_node = function(pos, placer, itemstack)
            local leaves_dried = dry_nearby_leaves(pos)
            local water_absorbed = absorb_water(pos)

            if water_absorbed then
                core.set_node(pos, {name = modname .. ":sponge_soaked"})
            elseif leaves_dried and state.id == "dry" then
                core.set_node(pos, {name = modname .. ":sponge_moist"})
            end
        end,
        on_rightclick = function(pos, node, clicker, itemstack)
            if itemstack:get_name() == "bucket:bucket_empty" and state.id ~= "dry" then
                local inv = clicker:get_inventory()
                if inv:room_for_item("main", "bucket:bucket_water") then
                    itemstack:take_item()
                    inv:add_item("main", "bucket:bucket_water")
                    core.set_node(pos, {name = modname .. ":sponge_dry"})
                    core.sound_play("default_water_footstep", {pos = pos, gain = 0.7})
                end
            end
        end,
    })
end

core.register_node(modname .. ":dry_leaves", {
    description = "Dry Leaves",
    tiles = {"mysponge_dry_leaves.png"},
    drawtype = "allfaces_optional",
    paramtype = "light",
    groups = {snappy = 3, leafdecay = 3, leaves = 1, flammable = 2},
})

core.register_node(modname .. ":air_temp", {
    drawtype = "airlike",
    walkable = false,
    pointable = false,
    buildable_to = true,
    sunlight_propagates = true,
    paramtype = "light",
    groups = {not_in_creative_inventory = 1},
    on_construct = function(pos)
        core.get_node_timer(pos):start(1.0)
    end,
    on_timer = function(pos)
        core.set_node(pos, {name = "air"})
    end,
})

core.register_abm({
    label = "Sponge Effects",
    nodenames = {modname .. ":sponge_moist", modname .. ":sponge_wet", modname .. ":sponge_soaked"},
    interval = 1,
    chance = 2,
    action = function(pos, node)
        if node.name == modname .. ":sponge_moist" then
            core.add_particle({
                pos = {x=pos.x + math.random(-2,2)/10, y=pos.y+0.2, z=pos.z + math.random(-2,2)/10},
                velocity = {x=0, y=0.5, z=0},
                expirationtime = 2,
                size = 3,
                texture = "mysponge_drop.png^[opacity:40",
            })
        else
            core.add_particle({
                pos = {x=pos.x + math.random(-3,3)/10, y=pos.y-0.4, z=pos.z + math.random(-3,3)/10},
                velocity = {x=0, y=-2, z=0},
                acceleration = {x=0, y=-9, z=0},
                expirationtime = 0.8,
                size = 1.5,
                collisiondetection = true,
                texture = "mysponge_drop.png",
            })
        end
    end,
})

core.register_craft({
    output = modname .. ":sponge_dry",
    recipe = {
        {"farming:string", "wool:yellow", "farming:string"},
        {"wool:yellow", "default:mese_crystal_fragment", "wool:yellow"},
        {"farming:string", "wool:yellow", "farming:string"},
    }
})

local wet_types = {"moist", "wet", "soaked"}
for _, t in ipairs(wet_types) do
    core.register_craft({
        type = "cooking",
        recipe = modname .. ":sponge_" .. t,
        output = modname .. ":sponge_dry",
        cooktime = 3,
    })
end
