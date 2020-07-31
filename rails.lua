minetest.register_entity("unrailedtrain:rail_1", {
	initial_properties = {
		inventory_image = "carts_rail_straight.png",
		visual = "cube",
		physical = false,
		visual_size = {x=1, y=1/10, z=1},
		collisionbox = {-0.01, -0.01, -0.01, 0.01, 0.01, 0.01},
		textures = {
				"carts_rail_straight.png", "carts_rail_straight.png", 
				"carts_rail_straight.png", "carts_rail_straight.png",
				"carts_rail_straight.png", "carts_rail_straight.png"
			},
		static_save = false,
	},
})

minetest.register_craftitem("unrailedtrain:rail_stack", {
	description = "Stack of rails",
	stack_max = 6,
	inventory_image = "carts_rail_straight.png",
	wield_image = "carts_rail_straight.png",
	on_place = function(itemstack, placer, pointed_thing)
		if pointed_thing.type == 'node' and minetest.get_node_or_nil(pointed_thing.above) then
			minetest.set_node(pointed_thing.above, {name="carts:rail"})
			itemstack:take_item()
		end
		return itemstack
	end,
})


minetest.override_item("carts:rail", {
	groups = { dig_immediate = 2 },
	drop = {
		max_items = 1,
		items = {
			{
				items = { "unrailedtrain:rail_stack" },
				rarity = 1
			}
		}
	},
})