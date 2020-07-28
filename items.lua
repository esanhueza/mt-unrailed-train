
local entity_definition = {
	initial_properties = {
		collisionbox = {-0.5, -0.5, -0.5, 0.5, 0.5, 0.5},
		visual = "mesh",
		mesh = "iron_1.b3d",
		textures = {"railers.png"},
		static_save = false,
	},
}

minetest.register_entity("unrailedtrain:iron_1", entity_definition)
