local entity_def = {
	initial_properties = {
		collisionbox = {-0.5, -0.5, -0.5, 0.5, 0.5, 0.5},
		visual = "mesh",
		mesh = "train_1.b3d",
		visual_size = {x=1, y=1},
		textures = {"railers.png"},
		static_save = false
	},
	old_dir = {x=0, y=0, z=0},
	old_pos = nil,
	railtype = nil,
	running = false,
	owner = nil,
	carts = {}	
}

function entity_def:on_step(dtime)
	if self.running then
		unrailedtrain:cart_move(self, dtime)
		local node_under = minetest.get_node(self.old_pos)
		if node_under.name == "carts:rail" then
			minetest.set_node(self.old_pos, {name="unrailedtrain:indestructible_rail"})
		end
	end
end

function entity_def:on_punch(puncher, time_from_last_punch, tool_capabilities, dir)
	unrailedtrain:on_punch_on_motor(self, puncher, time_from_last_punch, tool_capabilities, dir)
end

function entity_def:on_rightclick(clicker)
	local item = clicker:get_wielded_item()
	
	local is_cart = table.find(unrailedtrain.groups.carts, item:get_name())
	if not is_cart then
		return
	end
	local cart_obj = minetest.add_entity(self.object:get_pos(), item:get_name())
	unrailedtrain:attach_cart(self, 1, cart_obj:get_luaentity())
end
	
function entity_def:on_activate (staticdata, dtime_s) 
	self.object:set_armor_groups({immortal=1})
	self.carts = {}
	self.old_pos = self.object:get_pos()
	table.insert(self.carts, self)
	self.stop(self)
end

function entity_def:start()
	self.running = true
	self.object:set_velocity(vector.multiply(self.old_dir, 0.4))
	for i,v in ipairs(self.carts) do
		v.object:set_velocity(vector.multiply(v.old_dir, 0.4))
	end
	self.object:set_properties({pointable = false})
end

function entity_def:stop() 
	self.running = false
	self.object:set_properties({pointable = true})
	self.object:set_acceleration({x=0, y=0, z=0})
	self.object:set_velocity({x=0, y=0, z=0})
	for i,v in ipairs(self.carts) do
		if v ~= self then
			v:stop()
		end
	end
end

minetest.register_entity("unrailedtrain:motor_1", entity_def)

minetest.register_craftitem("unrailedtrain:motor_1", {
	description = "Train motor",
	wield_image = "dirt.png",
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

		if node.name == "carts:rail" then
			unrailedtrain:place_train(placer, under)
		end
	end,
})