local v3_len = vector.length

local function rail_on_step(self, dtime)
	if not self.running then
		return
	end

	local vel = self.object:get_velocity()
	local pos = self.object:get_pos()
	local cart_dir = carts:velocity_to_dir(vel)
	local same_dir = vector.equals(cart_dir, self.old_dir)
	local update = {}

	if self.old_pos and same_dir then
		local flo_pos = vector.round(pos)
		local flo_old = vector.round(self.old_pos)
		if vector.equals(flo_pos, flo_old) then
			-- Do not check one node multiple times
			return
		end
	end

	local stop_wiggle = false
	if self.old_pos and same_dir then
		-- Detection for "skipping" nodes (perhaps use average dtime?)
		-- It's sophisticated enough to take the acceleration in account
		local acc = self.object:get_acceleration()
		local distance = dtime * (v3_len(vel) + 0.5 * dtime * v3_len(acc))

		local new_pos, new_dir = carts:pathfinder(
			pos, self.old_pos, self.old_dir, distance, nil,
			nil, self.railtype
		)

		if new_pos then
			-- No rail found: set to the expected position
			pos = new_pos
			update.pos = true
			cart_dir = new_dir
		end
	elseif self.old_pos and self.old_dir.y ~= 1 then
		-- Stop wiggle
		stop_wiggle = true
	end

	local railparams

	local dir = carts:get_rail_direction(
		pos, cart_dir, ctrl, nil, self.railtype
	)
	local dir_changed = not vector.equals(dir, self.old_dir)

	if dir_changed then
		for _, v in pairs({"x","y","z"}) do
			-- End of the rail
			if dir[v] ~= 0 and math.abs(dir[v]) == math.abs(self.old_dir[v]) then
				self.stop(self)
				self.dir = self.old_dir
				return
			end
		end
	end

	local new_acc = {x=0, y=0, z=0}
	if stop_wiggle or vector.equals(dir, {x=0, y=0, z=0}) then
		vel = {x = 0, y = 0, z = 0}
		local pos_r = vector.round(pos)
		if not carts:is_rail(pos_r, self.railtype)
				and self.old_pos then
			pos = self.old_pos
		elseif not stop_wiggle then
			pos = pos_r
		else
			pos.y = math.floor(pos.y + 0.5)
		end
		update.pos = true
		update.vel = true
	else
		-- Direction change detected
		if dir_changed then
			vel = vector.multiply(dir, math.abs(vel.x + vel.z))
			update.vel = true
			if dir.y ~= self.old_dir.y then
				pos = vector.round(pos)
				update.pos = true
			end
		end
		-- Center on the rail
		if dir.z ~= 0 and math.floor(pos.x + 0.5) ~= pos.x then
			pos.x = math.floor(pos.x + 0.5)
			update.pos = true
		end
		if dir.x ~= 0 and math.floor(pos.z + 0.5) ~= pos.z then
			pos.z = math.floor(pos.z + 0.5)
			update.pos = true
		end

		-- Slow down or speed up..
		local acc = dir.y * -4.0


		-- no need to check for railparams == nil since we always make it exist.
		local speed_mod = unrailedtrain.acceleration
		if speed_mod and speed_mod ~= 0 then
			acc = acc + speed_mod
		else
			acc = acc - 0.005
		end
		new_acc = vector.multiply(dir, acc)
	end

	-- Limits
	local max_vel = unrailedtrain.speed_max
	for _, v in pairs({"x","y","z"}) do
		if math.abs(vel[v]) > max_vel then
			vel[v] = carts:get_sign(vel[v]) * max_vel
			new_acc[v] = 0
			update.vel = true
		end
	end

	self.object:set_acceleration(new_acc)
	self.old_pos = vector.round(pos)
	if not vector.equals(dir, {x=0, y=0, z=0}) and not stop_wiggle then
		self.old_dir = vector.new(dir)
	end

	set_yaw(self)

	local anim = {x=0, y=0}
	if dir.y == -1 then
		anim = {x=1, y=1}
	elseif dir.y == 1 then
		anim = {x=2, y=2}
	end
	self.object:set_animation(anim, 1, 0)

	if update.vel then
		self.object:set_velocity(vel)
	end
	if update.pos then
		if dir_changed then
			self.object:set_pos(pos)
		else
			self.object:move_to(pos)
		end
	end

	-- call event handler
	-- rail_on_step_event(railparams.on_step, self, dtime)
end

minetest.register_entity("unrailedtrain:motor", {
	initial_properties = {
		collisionbox = {-0.5, -0.5, -0.5, 0.5, 0.5, 0.5},
		visual = "mesh",
		mesh = "train_1.b3d",
		visual_size = {x=1, y=1},
		textures = {"railers.png"},
		static_save = true
	},
	old_dir = {x=0, y=0, z=0},
	velocity = {x=0, y=0, z=0},
	old_pos = nil,
	railtype = nil,
	running = false,
	owner = nil,
	carts = {},
  on_activate = function(self, staticdata, dtime_s) 
		self.object:set_armor_groups({immortal=1})
		self.carts = {}
		table.insert(self.carts, self)
		self.stop(self)
  end,
  on_step = function(self, dtime)
    rail_on_step(self, dtime)
	end,
	on_punch = function(self, puncher, time_from_last_punch, tool_capabilities, dir)
		unrailedtrain:on_punch_on_motor(self, puncher, time_from_last_punch, tool_capabilities, dir)
	end,
	on_rightclick = function(self, clicker)
		local item = clicker:get_wielded_item()
		
		local is_cart = table.find(unrailedtrain.groups.carts, item:get_name())
		if not is_cart then
			return
		end 
		unrailedtrain:attach_cart(self, 1, item)
	end,
	stop = function(self) 
		self.running = false
		self.object:set_properties({pointable = true})
		self.object:set_acceleration({x=0, y=0, z=0})
		self.object:set_velocity({x=0, y=0, z=0})
	end,
	start = function(self)
		self.running = true
		self.object:set_velocity(vector.add(self.old_dir, 0.1))
		self.object:set_properties({pointable = false})
	end,
})

minetest.register_craftitem("unrailedtrain:motor", {
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
			local obj =	minetest.add_entity(under, "unrailedtrain:motor")
			local entity = obj:get_luaentity()
			entity.owner = placer
			
			local trail_pos = find_next_free_trail(under, nil)
			if trail_pos then
				entity.old_dir = vector.direction(under, trail_pos)
			end
			unrailedtrain:add_train(entity)
		end
	end,
})