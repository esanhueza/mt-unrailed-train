
local cargo_entity = {
	initial_properties = {
		collisionbox = {-0.5, -0.5, -0.5, 0.5, 0.5, 0.5},
		visual = "mesh",
		mesh = "cargo_cart_1.b3d",
		textures = {"railers.png"},
		static_save = false,
	},
	old_pos = nil,
  old_dir = nil,
	railtype = nil,
  parent = nil,
	owner = nil,
}

function cargo_entity:add_material_1(item)
	local obj = minetest.add_entity(self.object:get_pos(), "unrailedtrain:iron_1")
	obj:set_attach(self.object, "", {
		x= 2 * (self.cargo.material_1 % 2 == 0 and -1 or 1), 
		y= math.floor(self.cargo.material_1 / 2) * 1.5 - 1.5, -- the y offset between the base of the car and the material, 
		z= 2 * (self.cargo.material_1 % 2 == 0 and 1 or -1)
	}, {
		x= 0, 
		y= 90 * self.cargo.material_1, 
		z= 0
	})
	self.cargo.material_1 = self.cargo.material_1 + 1
end


function cargo_entity:add_material_2(item)
	local obj = minetest.add_entity(self.object:get_pos(), "unrailedtrain:wood_1")
	obj:set_attach(self.object, "", {
		x= 2 * (self.cargo.material_2 % 2 == 0 and -1 or 1), 
		y= math.floor(self.cargo.material_2 / 2) * 1.5 - 1.5, -- the y offset between the base of the car and the material, 
		z= 2 * (self.cargo.material_2 % 2 == 0 and -1 or 1)
	}, {
		x= 0, 
		y= 90 * self.cargo.material_2, 
		z= 0
	})
	self.cargo.material_2 = self.cargo.material_2 + 1
end

function cargo_entity:on_step(dtime)
	if self.parent ~= nil and self.parent.running then
		self.object:set_velocity(self.parent.object:get_velocity())
		self.old_dir = vector.normalize(self.object:get_velocity())
	end
end

function cargo_entity:on_activate(staticdata, dtime_s)
	self.object:set_armor_groups({immortal=1})
	self.cargo = {
		material_1 = 0,
		material_2 = 0,
	}
end

function cargo_entity:on_rightclick(clicker)
	if clicker:get_wielded_item() then
		local item = clicker:get_wielded_item()
		if item:get_name() == "default:iron_lump" then
			self.add_material_1(self, item)
			return
		end
		if string.match(item:get_name(), "_wood") or string.match(item:get_name(), "_tree") then
			self.add_material_2(self, item)
			return
		end
	end
	unrailedtrain:on_rightclick_over_cart(self, clicker)
end

function cargo_entity:on_punch(puncher, time_from_last_punch, tool_capabilities, direction)  
	unrailedtrain:on_punch_on_cart(self, puncher, time_from_last_punch, tool_capabilities, direction)
end

minetest.register_entity("unrailedtrain:cargo_cart", cargo_entity)

minetest.register_craftitem("unrailedtrain:cargo_cart", {
	description = "Cargo cart",
	inventory_image = minetest.inventorycube("carts_cart_top.png", "carts_cart_side.png", "carts_cart_side.png"),
	wield_image = "carts_cart_side.png",
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
	end,
})