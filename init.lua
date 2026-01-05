local modname = core.get_current_modname()

local states = {
    {
        id = "dry", desc = "Dry Sponge", tex = "mysponge_sponge.png", size = 0.5, 
        inv = true, next_state = nil, dry_time = 0, drip_count = 0, steam_count = 0, water_yield = 0
    },
    {
        id = "moist", desc = "Moist Sponge", tex = "mysponge_sponge2.png", size = 0.7, 
        inv = false, next_state = "dry", dry_time = 45, drip_count = 2, steam_count = 1, water_yield = 1
    },
    {
        id = "wet", desc = "Wet Sponge", tex = "mysponge_sponge3.png", size = 0.85, 
        inv = false, next_state = "moist", dry_time = 60, drip_count = 8, steam_count = 3, water_yield = 2
    },
    {
        id = "soaked", desc = "Soaked Sponge", tex = "mysponge_sponge3.png", size = 1.0, 
        inv = false, next_state = "wet", dry_time = 90, drip_count = 25, steam_count = 10, water_yield = 3
    },
}

local function is_touching_water(pos)
    local sides = {
        {x = pos.x + 1, y = pos.y,     z = pos.z},
        {x = pos.x - 1, y = pos.y,     z = pos.z},
        {x = pos.x,     y = pos.y + 1, z = pos.z},
        {x = pos.x,     y = pos.y - 1, z = pos.z},
        {x = pos.x,     y = pos.y,     z = pos.z + 1},
        {x = pos.x,     y = pos.y,     z = pos.z - 1},
    }
    for _, s_pos in ipairs(sides) do
        local node = core.get_node(s_pos)
        if core.get_item_group(node.name, "water") ~= 0 then
            return true
        end
    end
    return false
end

local function absorb_water(pos)
    if not is_touching_water(pos) then
        return false
    end

    local radius = 3
    local nodes = core.find_nodes_in_area(
        {x = pos.x - radius, y = pos.y - radius, z = pos.z - radius},
        {x = pos.x + radius, y = pos.y + radius, z = pos.z + radius},
        {"group:water"}
    )
    
    if #nodes > 0 then
        for _, p in ipairs(nodes) do
            core.remove_node(p)
        end
        core.set_node(pos, {name = modname .. ":sponge_soaked"})
        return true
    end
    return false
end

local state_data = {}
for _, s in ipairs(states) do state_data[modname .. ":sponge_" .. s.id] = s end

for _, state in ipairs(states) do
    local box_size = state.size / 2
    local groups = {dig_immediate = 3, sponge = 1}
    if state.id == "dry" then groups.sponge_dry = 1 end
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
        
        on_construct = function(pos)
            if state.id == "dry" then
                absorb_water(pos)
            elseif state.next_state then
                core.get_node_timer(pos):start(2)
            end
        end,

        on_neighbor_update = function(pos, node, neighbor_pos)
            if state.id == "dry" then
                absorb_water(pos)
            end
        end,

        on_punch = function(pos, node, puncher, pointed_thing)
            if not puncher or not state.next_state then return end
            
            local held_item = puncher:get_wielded_item()
            if held_item:get_name() == "bucket:bucket_empty" then
                core.set_node(pos, {name = modname .. ":sponge_" .. state.next_state})
                
                held_item:take_item()
                puncher:set_wielded_item(held_item)
                
                local inv = puncher:get_inventory()
                local water_bucket = ItemStack("bucket:bucket_water")
                if inv:room_for_item("main", water_bucket) then
                    inv:add_item("main", water_bucket)
                else
                    core.add_item(puncher:get_pos(), water_bucket)
                end
                
                core.sound_play("default_water_footstep", {pos = pos, gain = 0.5})
            end
        end,

        on_timer = function(pos, elapsed)
            local surrounding = core.find_nodes_in_area(vector.subtract(pos, 1), vector.add(pos, 1), {"group:lava"})
            if #surrounding > 0 then
                core.set_node(pos, {name = modname .. ":dried_leaves"})
                return false
            end

            if not state.next_state then return false end

            local meta = core.get_meta(pos)
            local neighbors = core.find_nodes_in_area(vector.subtract(pos, 1), vector.add(pos, 1), {"air"})
            
            if #neighbors > 0 then
                meta:set_int("is_drying", 1)
                local current_dry = (meta:get_float("dry_progress") or 0) + elapsed
                if current_dry >= state.dry_time then
                    core.set_node(pos, {name = modname .. ":sponge_" .. state.next_state})
                    return false
                end
                meta:set_float("dry_progress", current_dry)
            else
                meta:set_int("is_drying", 0)
            end
            return true
        end,

        on_blast = function(pos, intensity)
            core.remove_node(pos)
            return {modname .. ":sponge_" .. state.id}
        end,
    })

    if state.water_yield > 0 then
        core.register_craft({
            type = "cooking",
            output = modname .. ":sponge_dry",
            recipe = modname .. ":sponge_" .. state.id,
            cooktime = 3,
            replacements = {
                {modname .. ":sponge_" .. state.id, "default:water_source " .. state.water_yield}
            }
        })
    end
end
core.register_abm({
    label = "Sponge Leaf Drying",
    nodenames = {"group:sponge"},
    interval = 2.0,
    chance = 5,
    action = function(pos, node)
        local radius = 1
        local leaf_nodes = core.find_nodes_in_area(
            {x = pos.x - radius, y = pos.y - radius, z = pos.z - radius},
            {x = pos.x + radius, y = pos.y + radius, z = pos.z + radius},
            {"group:leaves"}
        )
        
        for _, leaf_pos in ipairs(leaf_nodes) do
            core.set_node(leaf_pos, {name = modname .. ":dried_leaves"})
        end
    end,
})

core.register_abm({
    label = "Sponge Absorption Check",
    nodenames = {"group:sponge_dry"},
    neighbors = {"group:water"},
    interval = 1.0,
    chance = 1,
    action = function(pos, node)
        absorb_water(pos)
    end,
})

core.register_abm({
    label = "Sponge Effects",
    nodenames = {"group:sponge"},
    interval = 1.0,
    chance = 1,
    action = function(pos, node)
        local data = state_data[node.name]
        if not data then return end
        if data.drip_count > 0 then
            core.add_particlespawner({
                amount = data.drip_count,
                time = 1,
                minpos = {x=pos.x-0.2, y=pos.y-0.4, z=pos.z-0.2},
                maxpos = {x=pos.x+0.2, y=pos.y-0.1, z=pos.z+0.2},
                minvel = {x=0, y=-1, z=0},
                maxvel = {x=0, y=-2, z=0},
                minacc = {x=0, y=-9.8, z=0},
                maxacc = {x=0, y=-9.8, z=0},
                minexptime = 0.5,
                maxexptime = 1.0,
                minsize = 1,
                maxsize = 2,
                texture = "mysponge_drip.png",
            })
        end
        local meta = core.get_meta(pos)
        if meta:get_int("is_drying") == 1 and data.steam_count > 0 then
            core.add_particlespawner({
                amount = data.steam_count,
                time = 1,
                minpos = {x=pos.x-0.3, y=pos.y, z=pos.z-0.3},
                maxpos = {x=pos.x+0.3, y=pos.y+0.3, z=pos.z+0.3},
                minvel = {x=-0.1, y=0.2, z=-0.1},
                maxvel = {x=0.1, y=2.5, z=0.1},
                minexptime = 1,
                maxexptime = 2,
                minsize = 0.5,
                maxsize = 2,
                texture = "mysponge_evap.png",
            })
        end
    end,
})

core.register_node(modname .. ":dried_leaves", {
    description = "Dried Leaves",
    drawtype = "allfaces_optional",
    tiles = {"default_leaves.png^[colorize:#5C4033:120"},
    paramtype = "light",
    groups = {snappy = 3, flammable = 2, leaves = 1},
})
