
minetest.register_node("mysponge:sponge_dry",{
	description = "Dry Sponge",
	tiles = {"mysponge_sponge.png"},
	drawtype = "nodebox",
	visual_scale = 0.5,
	paramtype = "light",
	groups = {dig_immediate=1, oddly_breakable_by_hand=1},
	node_box = {
		type = "fixed",
		fixed = {
			{-0.5, -0.5, -0.5, 0.5, 0.5, 0.5}, 
			}
		},
	selection_box = {
		type = "fixed",
		fixed = {
			{-0.25, -0.25, -0.25, 0.25, 0.25, 0.25}, 
		}
	}
})



minetest.register_node("mysponge:sponge_moist",{
--	description = "Moist Sponge",
	tiles = {"mysponge_sponge2.png"},
	drawtype = "nodebox",
	visual_scale = 0.7,
	paramtype = "light",
	groups = {dig_immediate=1, oddly_breakable_by_hand=1, not_in_creative_inventory=1},
	node_box = {
		type = "fixed",
		fixed = {
			{-0.5, -0.5, -0.5, 0.5, 0.5, 0.5}, 
		}
	},
	selection_box = {
		type = "fixed",
		fixed = {
			{-0.25, -0.5, -0.25, 0.25, 0, 0.25}, 
		}
	}
})
minetest.register_node("mysponge:sponge_wet",{
--	description = "Wet Sponge",
	tiles = {"mysponge_sponge3.png"},
	drawtype = "nodebox",
	visual_scale = 1,
	paramtype = "light",
	groups = {dig_immediate=1, oddly_breakable_by_hand=1, not_in_creative_inventory=1},
	node_box = {
		type = "fixed",
		fixed = {
			{-0.5, -0.5, -0.5, 0.5, 0.5, 0.5}, 
		}
	},
	selection_box = {
		type = "fixed",
		fixed = {
			{-0.25, -0.5, -0.25, 0.25, 0, 0.25}, 
		}
	}
})
minetest.register_node("mysponge:sponge_soaked",{
--	description = "Soaked Sponge",
	tiles = {"mysponge_sponge4.png"},
	drawtype = "nodebox",
	visual_scale = 1.5,
	paramtype = "light",
	groups = {dig_immediate=1, oddly_breakable_by_hand=1, not_in_creative_inventory=1},
	node_box = {
		type = "fixed",
		fixed = {
			{-0.5, -0.5, -0.5, 0.5, 0.5, 0.5}, 
		}
	},
	selection_box = {
		type = "fixed",
		fixed = {
			{-0.5, -0.5, -0.5, 0.5, 0.5, 0.5}, 
		}
	},

})
minetest.register_node("mysponge:air1",{
--	description = "Air 1",
	tiles = {"mysponge_air.png"},
	drawtype = "allfaces",
	walkable = false,
	paramtype = "light",
	groups = {dig_immediate=1, oddly_breakable_by_hand=1, not_in_creative_inventory=1}
})
minetest.register_node("mysponge:air2",{
--	description = "Air 2",
	tiles = {"mysponge_air.png"},
	drawtype = "allfaces",
	walkable = false,
	paramtype = "light",
	groups = {dig_immediate=1, oddly_breakable_by_hand=1, not_in_creative_inventory=1}
})
minetest.register_node("mysponge:air3",{
--	description = "Air 3",
	tiles = {"mysponge_air.png"},
	drawtype = "allfaces",
	walkable = false,
	paramtype = "light",
	groups = {dig_immediate=1, oddly_breakable_by_hand=1, not_in_creative_inventory=1}
})


minetest.register_node("mysponge:dry_leaves",{
	description = "Dry Leaves",
	tiles = {"mysponge_dry_leaves.png"},
	drawtype = "allfaces_optional",
	paramtype = "light",
	groups = {dig_immediate=1, oddly_breakable_by_hand=1}
})


-------------------------------------------------------------------------
--ABMs
-------------------------------------------------------------------------
--Set Air

--Air 1
minetest.register_abm({
	nodenames = {"group:water"},
	neighbors = {"mysponge:sponge_dry"},
	interval = 0.5,
	chance = 1,
	action = function(pos)
		minetest.set_node(pos, {name="mysponge:air1"})	
	end
})
--Air 1
minetest.register_abm({
	nodenames = {"group:water"},
	neighbors = {"mysponge:sponge_moist"},
	interval = 0.5,
	chance = 1,
	action = function(pos)
		minetest.set_node(pos, {name="mysponge:air1"})	
	end
})
--Air 1
minetest.register_abm({
	nodenames = {"group:water"},
	neighbors = {"mysponge:sponge_wet"},
	interval = 0.5,
	chance = 1,
	action = function(pos)
		minetest.set_node(pos, {name="mysponge:air1"})	
	end
})

--Air 2
minetest.register_abm({
	nodenames = {"group:water"},
	neighbors = {"mysponge:air1"},
	interval = 0.5,
	chance = 1,
	action = function(pos)
		minetest.set_node(pos, {name="mysponge:air2"})	
	end
})

--Air 3
minetest.register_abm({
	nodenames = {"group:water"},
	neighbors = {"mysponge:air2"},
	interval = 0.5,
	chance = 1,
	action = function(pos)
		minetest.set_node(pos, {name="mysponge:air3"})	
	end
})

-------------------------------------------------------------------------
--Set default Air
-------------------------------------------------------------------------

minetest.register_abm({
	nodenames = {"mysponge:air1","mysponge:air2","mysponge:air3"},
	interval = 5,
	chance = 1,
	action = function(pos)
		minetest.set_node(pos, {name="air"})	
	end
})

-------------------------------------------------------------------------
--Set Sponge
-------------------------------------------------------------------------

minetest.register_abm({
	nodenames = {"mysponge:sponge_dry"},
	neighbors = {"group:water"},
	interval = 0.5,
	chance = 1,
	action = function(pos)
		minetest.set_node(pos, {name="mysponge:sponge_moist"})	
	end

})
minetest.register_abm({
	nodenames = {"mysponge:sponge_moist"},
	neighbors = {"mysponge:air1"},
	interval = 0.5,
	chance = 1,
	action = function(pos)
		minetest.set_node(pos, {name="mysponge:sponge_wet"})
	end,
})
minetest.register_abm({
	nodenames = {"mysponge:sponge_wet"},
	neighbors = {"mysponge:air1"},
	interval = 0.5,
	chance = 1,
	action = function(pos)
		minetest.set_node(pos, {name="mysponge:sponge_soaked"})
	end,
})

------------------------------------------------------------------------------------------------
--Shrink Sponge in Air
------------------------------------------------------------------------------------------------
minetest.register_abm({
	nodenames = {"mysponge:sponge_soaked"},
	neighbors = {"air"},
	interval = 120,
	chance = 1,
	action = function(pos)
		minetest.set_node(pos, {name="mysponge:sponge_wet"})
	end,
})
minetest.register_abm({
	nodenames = {"mysponge:sponge_wet"},
	neighbors = {"air"},
	interval = 120,
	chance = 1,
	action = function(pos)
		minetest.set_node(pos, {name="mysponge:sponge_moist"})
	end,
})
minetest.register_abm({
	nodenames = {"mysponge:sponge_moist"},
	neighbors = {"air"},
	interval = 120,
	chance = 1,
	action = function(pos)
		minetest.set_node(pos, {name="mysponge:sponge_dry"})
	end,
})


-------------------------------------------------------------------------------------------------
--Craft

minetest.register_craft({
		type = "cooking",
		output = "default:water_source 3",
		recipe = "mysponge:sponge_soaked",
		cooktime = 5,
		replacements = {{"mysponge:sponge_soaked", "mysponge:sponge_dry"}},
	})
minetest.register_craft({
		type = "cooking",
		output = "mysponge:dry_leaves",
		recipe = "group:leaves",
		cooktime = 3,
	})
minetest.register_craft({
		output = "mysponge:sponge_dry 1",
		recipe = {
			{"default:mese_crystal_fragment","mysponge:dry_leaves","default:mese_crystal_fragment"},
			{"mysponge:dry_leaves","default:mese_crystal_fragment","mysponge:dry_leaves"},
			{"default:mese_crystal_fragment","mysponge:dry_leaves","default:mese_crystal_fragment"},
			},
		cooktime = 3,
	})





