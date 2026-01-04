local modname = minetest.get_current_modname()

local mysponge_table = {
	{"sponge_dry",    "Dry Sponge",    "mysponge_sponge.png",  0.5,  {dig_immediate=2, flammable=1}, 3},
	{"sponge_moist",  "Moist Sponge",  "mysponge_sponge2.png", 0.7,  {dig_immediate=2, not_in_creative_inventory=1}, 2},
	{"sponge_wet",    "Wet Sponge",    "mysponge_sponge3.png", 0.85, {dig_immediate=2, not_in_creative_inventory=1}, 1},
	{"sponge_soaked", "Soaked Sponge", "mysponge_sponge3.png", 1.0,  {dig_immediate=2, not_in_creative_inventory=1}, 0},
}

local function absorb_water(pos, current_item)
	local radius = 0
	for _, data in ipairs(mysponge_table) do
		if data[1] == current_item then
			radius = data[6]
			break
		end
	end

	if radius <= 0 and current_item ~= "sponge_soaked" then radius = 0 end
	if current_item == "sponge_soaked" then return false end

	local adjacent_min = {x = pos.x - 1, y = pos.y - 1, z = pos.z - 1}
	local adjacent_max = {x = pos.x + 1, y = pos.y + 1, z = pos.z + 1}
	local trigger_nodes = minetest.find_nodes_in_area(adjacent_min, adjacent_max, {"group:water"})
	
	if #trigger_nodes > 0 then
		local soak_min = {x = pos.x - radius, y = pos.y - radius, z = pos.z - radius}
		local soak_max = {x = pos.x + radius, y = pos.y + radius, z = pos.z + radius}
		local all_water = minetest.find_nodes_in_area(soak_min, soak_max, {"group:water"})
		
		for _, wpos in ipairs(all_water) do
			minetest.set_node(wpos, {name = "mysponge:air1"})
		end
		
		minetest.set_node(pos, {name = "mysponge:sponge_soaked"})
		minetest.sound_play("default_water_footstep", {pos = pos, gain = 0.5})
		return true
	end
	return false
end

for _, data in ipairs(mysponge_table) do
	local item, desc, image, scale, nodegroup = unpack(data)
	local half_width = scale / 2
	local height_top = -0.5 + scale 

	minetest.register_node(modname .. ":" .. item, {
		description = desc,
		tiles = {image},
		drawtype = "nodebox",
		paramtype = "light",
		groups = nodegroup,
		node_box = {
			type = "fixed",
			fixed = {-half_width, -0.5, -half_width, half_width, height_top, half_width},
		},
		selection_box = {
			type = "fixed",
			fixed = {-half_width, -0.5, -half_width, half_width, height_top, half_width},
		},
		after_place_node = function(pos, placer, itemstack, pointed_thing)
			absorb_water(pos, item)
		end,
		on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
			if itemstack:get_name() == "bucket:bucket_empty" and node.name ~= modname .. ":sponge_dry" then
				local inv = clicker:get_inventory()
				local leftover = inv:add_item("main", "bucket:bucket_water")
				
				if not leftover:is_empty() then
					minetest.add_item(clicker:get_pos(), leftover)
				end
				
				itemstack:take_item()
				
				minetest.add_particlespawner({
					amount = 20,
					time = 0.1,
					minpos = {x=pos.x-0.2, y=pos.y, z=pos.z-0.2}, 
					maxpos = {x=pos.x+0.2, y=pos.y+0.2, z=pos.z+0.2},
					minvel = {x=-3, y=1, z=-3}, maxvel = {x=3, y=4, z=3},
					minacc = {x=0, y=-9.8, z=0}, maxacc = {x=0, y=-9.8, z=0},
					minexptime = 0.4, maxexptime = 0.8,
					minsize = 1, maxsize = 3,
					texture = "mysponge_drop.png",
				})

				minetest.set_node(pos, {name = modname .. ":sponge_dry"})
				minetest.sound_play("default_water_footstep", {pos = pos, gain = 0.8})
				return itemstack
			end
		end,
	})
end

minetest.register_abm({
	label = "Sponge Particles",
	nodenames = {modname .. ":sponge_soaked", modname .. ":sponge_wet", modname .. ":sponge_moist"},
	interval = 1.0,
	chance = 1,
	action = function(pos, node)
		if node.name == modname .. ":sponge_soaked" or node.name == modname .. ":sponge_wet" then
			local below = {x=pos.x, y=pos.y-1, z=pos.z}
			local b_node = minetest.get_node(below)
			local def = minetest.registered_nodes[b_node.name]
			
			if def and (not def.walkable or b_node.name == "air") then
				minetest.add_particlespawner({
					amount = 3,
					time = 1,
					minpos = {x = pos.x - 0.3, y = pos.y - 0.45, z = pos.z - 0.3},
					maxpos = {x = pos.x + 0.3, y = pos.y - 0.5, z = pos.z + 0.3},
					minvel = {x = 0, y = -1, z = 0},
					maxvel = {x = 0, y = -2, z = 0},
					minacc = {x = 0, y = -9.8, z = 0},
					maxacc = {x = 0, y = -9.8, z = 0},
					minexptime = 1, maxexptime = 2,
					minsize = 1.5, maxsize = 2.5,
					texture = "mysponge_drop.png",
					vertical = true,
				})
			end
		elseif node.name == modname .. ":sponge_moist" then
			minetest.add_particlespawner({
				amount = 2,
				time = 1,
				minpos = {x = pos.x - 0.2, y = pos.y + 0.1, z = pos.z - 0.2},
				maxpos = {x = pos.x + 0.2, y = pos.y + 0.4, z = pos.z + 0.2},
				minvel = {x = -0.1, y = 0.1, z = -0.1},
				maxvel = {x = 0.1, y = 0.3, z = 0.1},
				minexptime = 1.5, maxexptime = 2.5,
				minsize = 1, maxsize = 2,
				texture = "mysponge_drop.png^[opacity:80",
			})
		end
	end,
})

local air_nodes = {"air1", "air2", "air3"}
for i, airnode in ipairs(air_nodes) do
	local next_node = air_nodes[i+1] and (modname .. ":" .. air_nodes[i+1]) or "air"
	minetest.register_node(modname .. ":" .. airnode, {
		description = "Air",
		drawtype = "airlike",
		walkable = false,
		pointable = false,
		buildable_to = true,
		paramtype = "light",
		sunlight_propagates = true,
		groups = {not_in_creative_inventory = 1},
		on_construct = function(pos)
			minetest.get_node_timer(pos):start(0.5)
		end,
		on_timer = function(pos)
			minetest.set_node(pos, {name = next_node})
		end,
	})
end

minetest.register_node(modname .. ":dry_leaves", {
	description = "Dry Leaves",
	tiles = {"mysponge_dry_leaves.png"},
	drawtype = "allfaces_optional",
	paramtype = "light",
	groups = {dig_immediate = 2, oddly_breakable_by_hand = 1, leaves = 1},
})

minetest.register_abm({
	label = "Sponge Leaf Drying",
	nodenames = {"group:leaves"},
	neighbors = {modname .. ":sponge_dry"},
	interval = 5.0,
	chance = 2,
	action = function(pos, node)
		local below = {x=pos.x, y=pos.y-1, z=pos.z}
		local b_node = minetest.get_node(below)
		
		if b_node.name == modname .. ":sponge_dry" and node.name ~= modname .. ":dry_leaves" then
			minetest.set_node(pos, {name = modname .. ":dry_leaves"})
			minetest.set_node(below, {name = modname .. ":sponge_moist"})
			minetest.sound_play("default_dry_grass_footstep", {pos = pos, gain = 0.5})
		end
	end,
})

minetest.register_abm({
	label = "Sponge Water Absorption",
	nodenames = {modname .. ":sponge_dry", modname .. ":sponge_moist", modname .. ":sponge_wet"},
	neighbors = {"group:water"},
	interval = 1.0,
	chance = 1,
	action = function(pos, node)
		local item_name = node.name:split(":")[2]
		absorb_water(pos, item_name)
	end,
})

local drying_chain = {
	[modname .. ":sponge_soaked"] = modname .. ":sponge_wet",
	[modname .. ":sponge_wet"]    = modname .. ":sponge_moist",
	[modname .. ":sponge_moist"]  = modname .. ":sponge_dry",
}

minetest.register_abm({
	label = "Sponge Drying",
	nodenames = {modname .. ":sponge_soaked", modname .. ":sponge_wet", modname .. ":sponge_moist"},
	neighbors = {"air"},
	interval = 45,
	chance = 1,
	action = function(pos, node)
		local next_stage = drying_chain[node.name]
		if next_stage then
			minetest.set_node(pos, {name = next_stage})
		end
	end,
})

local function register_sponge_drying(input_item, water_yield)
	minetest.register_craft({
		type = "cooking",
		output = "default:water_source " .. tostring(water_yield),
		recipe = input_item,
		cooktime = 5,
		replacements = {{input_item, modname .. ":sponge_dry"}},
	})
end

register_sponge_drying(modname .. ":sponge_soaked", 3)
register_sponge_drying(modname .. ":sponge_wet", 2)
register_sponge_drying(modname .. ":sponge_moist", 1)

minetest.register_craft({
	output = modname .. ":sponge_dry 1",
	recipe = {
		{"farming:string", "wool:yellow", "farming:string"},
		{"wool:yellow", "default:mese_crystal_fragment", "wool:yellow"},
		{"farming:string", "wool:yellow", "farming:string"},
	},
})
