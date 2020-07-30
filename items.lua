minetest.register_entity("unrailedtrain:iron_1", {
	initial_properties = {
		collisionbox = {-0.01, -0.01, -0.01, 0.01, 0.01, 0.01},
		visual = "mesh",
		mesh = "iron_1.b3d",
		textures = {"railers.png"},
		static_save = false,
	},
})

minetest.register_entity("unrailedtrain:wood_1", {
	initial_properties = {
		collisionbox = {-0.01, -0.01, -0.01, 0.01, 0.01, 0.01},
		visual = "mesh",
		mesh = "wood_1.b3d",
		textures = {"railers.png"},
		static_save = false,
	},
})
