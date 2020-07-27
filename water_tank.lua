

minetest.register_entity("mytrain:water_tank", {
	initial_properties = {
		collisionbox = {-0.5, -0.5, -0.5, 0.5, 0.5, 0.5},
		visual = "mesh",
		mesh = "carts_cart.b3d",
		visual_size = {x=0.9, y=0.5},
		-- textures = {"carts_cart.png"},
		textures = {"tnt_side.png"},
		static_save = false,
	},
	old_pos = nil,
  old_dir = nil,
	railtype = nil,
  parent = nil,
	owner = nil,
	attached_items = {},
  cart_index = nil,
  on_activate = function(self, staticdata, dtime_s)
    self.object:set_armor_groups({immortal=1})
  end,
  on_step = function(self, dtime)
    if self.parent ~= nil and self.parent.running then
      self.object:set_velocity(self.parent.object:get_velocity())
      self.old_dir = vector.normalize(self.object:get_velocity())
    end
  end,
  on_punch = function(self, puncher, time_from_last_punch, tool_capabilities, direction)
    mytrain:on_punch_on_cart(self, puncher, time_from_last_punch, tool_capabilities, direction)
  end,
  on_rightclick = function(self, clicker)
    mytrain:on_rightclick_over_cart(self, clicker)
  end
})


minetest.register_craftitem("mytrain:water_tank", {
	description = "Water tank",
	inventory_image = minetest.inventorycube("tnt_side.png", "tnt_side.png", "tnt_side.png"),
	wield_image = "tnt_side.png",
	on_place = function(itemstack, placer, pointed_thing)
		-- use cart as tool
		local under = pointed_thing.under
		local node = minetest.get_node(under)
		local udef = minetest.registered_nodes[node.name]
		if udef and udef.on_rightclick and
				not (placer and placer:is_player() and
				placer:get_player_control().sneak) then
			return udef.on_rightclick(under, node, placer, itemstack,
				pointed_thing) or itemstack
		end
    -- print(dump(pointed_thing))
		-- if node.name == "carts:rail" then
      --local obj = minetest.add_entity(under, "mytrain:cargo_cart")
      --obj.owner = placer
      
		--end
	end,
})