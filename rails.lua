local rail_stack_item_def = {
	description = "Stack of rails",
	stack_max = 6,
	inventory_image = "carts_rail_straight.png",
	wield_image = "carts_rail_straight.png",
}

local rail_stack_entity_def = {
	initial_properties = {
		inventory_image = "carts_rail_straight.png",
		visual = "mesh",
		mesh = "rail.b3d",
		textures = {"railers.png"},
		physical = true,
		pointable = true,
		collisionbox = {-0.5, -0.5, -0.5, 0.5, -0.4, 0.5},
		static_save = false,
	},
	count = 1,
	stack = nil,
	parent = nil,
}

function rail_stack_entity_def:add(n)
	local added = ((self.count + n) > rail_stack_item_def.stack_max) and (rail_stack_item_def.stack_max - self.count) or n
	for i=self.count,self.count + added - 1 do
		local item = minetest.add_entity(self.object:get_pos(), "unrailedtrain:rail_1")
		item:set_attach(self.object, "",
			{ x = 0, y = 0.1 + i, z = 0 },
			{ x = 0, y = 90 * i, z =0 }
		)
		local entity = item:get_luaentity()
		table.insert(self.stack, entity)
		entity.parent = self
	end
	self.count = self.count + added
	return added
end

function rail_stack_entity_def:take(n)
	local taken = (self.count - n) < 0 and self.count or n
	for i = self.count, 1, -1 do
		if i > self.count - taken then
			self.stack[i].object:set_detach()
			self.stack[i].object:remove()
			table.remove(self.stack, i)
		end
	end
	self.count = self.count - taken
	return taken
end

function rail_stack_entity_def:on_rightclick(clicker)
	if clicker:get_player_control().sneak and clicker:get_wielded_item():get_name() == "unrailedtrain:rail_stack" and self.count < rail_stack_item_def.stack_max then
		local base = self.parent ~= nil and self.parent or self
		local free_space = rail_stack_item_def.stack_max - base.count
		local item = clicker:get_wielded_item()
		local taken = base:add(item:get_count())
		item:take_item(taken)
		clicker:set_wielded_item(item)
	end
end

function rail_stack_entity_def:on_activate(staticdata, dtime_s)
	self.stack = {self}
	self.count = 1
end

function rail_stack_entity_def:on_punch(puncher, time_from_last_punch, tool_capabilities, direction, damage)
	if puncher:get_wielded_item():get_name() ~= "" and puncher:get_wielded_item():get_name() ~= "unrailedtrain:rail_stack" then
		return
	end

	local stack = ItemStack("unrailedtrain:rail_stack")
	local max_taken = rail_stack_item_def.stack_max
	local qty_wielded = 0
	if puncher:get_wielded_item():get_name() == "unrailedtrain:rail_stack" then
		max_taken = puncher:get_wielded_item():get_free_space()
	end
	local base = self.parent ~= nil and self.parent or self
	local taken = base:take(max_taken)
	stack:set_count(puncher:get_wielded_item():get_count() + taken)
	puncher:set_wielded_item(stack)
end


function rail_stack_item_def.on_place(itemstack, placer, pointed_thing)
	local control = placer:get_player_control()
	if pointed_thing.type == 'node' and minetest.get_node_or_nil(pointed_thing.above) then
		if control.sneak then
			local count = itemstack:get_count()
			local base_object = minetest.add_entity(pointed_thing.above, "unrailedtrain:rail_1")
			if base_object ~= nil then
				local base_entity = base_object:get_luaentity()
				local added = base_entity:add(count - 1)
				itemstack:set_count(count - added - 1)
			end
			return itemstack
		else
			minetest.set_node(pointed_thing.above, {name="carts:rail"})
			itemstack:take_item()
		end
	end
	return itemstack
end

minetest.register_entity("unrailedtrain:rail_1", rail_stack_entity_def)
minetest.register_craftitem("unrailedtrain:rail_stack", rail_stack_item_def)


minetest.override_item("carts:rail", {
	groups = { dig_immediate = 2, rail = 1 },
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