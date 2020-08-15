
function unrailedtrain:cart_move(cart, dtime)
	local vel = cart.object:get_velocity()
	local pos = cart.object:get_pos()
	local cart_dir = carts:velocity_to_dir(vel)
	local same_dir = vector.equals(cart_dir, cart.old_dir)
	local update = {}

	if cart.old_pos and same_dir then
		local flo_pos = vector.round(pos)
		local flo_old = vector.round(cart.old_pos)
		if vector.equals(flo_pos, flo_old) then
      -- Do not check one node multiple times
			return
		end

		local acc = cart.object:get_acceleration()
		local distance = dtime * (vector.length(vel) + 0.5 * dtime * vector.length(acc))

		local new_pos, new_dir = carts:pathfinder(
			pos, cart.old_pos, cart.old_dir, distance, nil,
			nil, true)
		
		if new_pos and false then
			-- No rail found: set to the expected position
			pos = new_pos
			update.pos = true
			cart_dir = new_dir
		end
	end

	local railparams

	local dir = carts:get_rail_direction(
		pos, cart_dir, nil, nil, cart.railtype
	)
	local dir_changed = not vector.equals(dir, cart.old_dir)

	if dir_changed then
		for _, v in pairs({"x","y","z"}) do
			-- End of the rail
      if dir[v] ~= 0 and math.abs(dir[v]) == math.abs(cart.old_dir[v]) then
				cart:stop()
				cart.dir = cart.old_dir
				return
			end
		end
	end

	local new_acc = {x=0, y=0, z=0}
	if vector.equals(dir, {x=0, y=0, z=0}) then
		vel = {x=0, y=0, z=0}
		local pos_r = vector.round(pos)
		if not carts:is_rail(pos_r, cart.railtype) and cart.old_pos then
			cart:stop()
			pos = cart.old_pos
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
			if dir.y ~= cart.old_dir.y then
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

	cart.object:set_acceleration(new_acc)
	cart.old_pos = vector.round(pos)
	if not vector.equals(dir, {x=0, y=0, z=0}) then
		cart.old_dir = vector.new(dir)
	end

	if cart.old_dir.x ~= 0 then
		cart.object:set_yaw(-carts:get_sign(dir.x) * vector.angle({x=0, y=0, z=1}, dir))
	end
	if cart.old_dir.z ~= 0 then
		cart.object:set_yaw(carts:get_sign(dir.z) * vector.angle({x=0, y=0, z=1}, dir))
	end
	
	if update.vel then
		cart.object:set_velocity(vel)
	end
	if update.pos then
		if dir_changed then
			cart.object:set_pos(pos)
		else
			cart.object:move_to(pos)
		end
	end
end

local function get_railparams(pos)
	local node = minetest.get_node(pos)
	return carts.railparams[node.name] or {}
end

local function set_entity_yaw(self)
	local yaw = 0
	if self.old_dir.x < 0 then
		yaw = 0.5
	elseif self.old_dir.x > 0 then
		yaw = 1.5
	elseif self.old_dir.z < 0 then
		yaw = 1
	end
	self.object:set_yaw(yaw * math.pi)
end

function unrailedtrain:find_next_free_trail(pos, dir)
  local t = {
    vector.add(pos, {x=-1, y=0, z=0}),
    vector.add(pos, {x=0, y=0, z=-1}),
    vector.add(pos, {x=1, y=0, z=0}),
    vector.add(pos, {x=0, y=0, z=1}),
  }

  for _, v in ipairs(t) do
    if dir == nil or (dir ~= nil and not vector.equals(v, vector.add(pos, dir))) then
      local node = minetest.get_node(v)
      if node ~= nil and node.name == "carts:rail"  then
        return v
      end
    end
  end
  return nil
end

function table.find(t, l)
  for _, v in ipairs(t) do
    if l == v then
      return v
    end
  end
  return nil
end

function table.find_index(t, l)
  for i, v in ipairs(t) do
    if l == v then
      return i
    end
  end
  return nil
end

function table.last (self)
  local last = nil
  for _, k in pairs(self) do
      last = k
  end
  return last
end

function table.length (self)
  local i = 0
  for j, _ in pairs(self) do
      i = j
  end
  return i
end

function table.empty (self)
  for _, _ in pairs(self) do
      return false
  end
  return true
end

function unrailedtrain:on_rightclick_over_cart(cart_clicked, clicker)
  local item = clicker:get_wielded_item()
  local motor = (cart_clicked.parent ~= nil) and cart_clicked.parent or cart_clicked 
  
  local is_cart = table.find(unrailedtrain.groups.carts, item:get_name())
  if not is_cart then
    return
  end

  local cart_index = table.find_index(motor.carts, cart_clicked)
  
  local new_cart_obj = minetest.add_entity(cart_clicked.object:get_pos(), item:get_name())

  unrailedtrain:attach_cart(motor, cart_index, new_cart_obj:get_luaentity())
end

-- motor: lua entity ref to the motor entity
-- cart_pos: cart position in the train
-- cart: lua entity ref to the cart entity
function unrailedtrain:attach_cart(motor, cart_pos, cart)
  local dir = motor.carts[cart_pos].old_dir
  local new_pos = unrailedtrain:find_next_free_trail(
    vector.round(motor.carts[cart_pos].object:get_pos()), 
    dir
  )
  local last_available_pos = unrailedtrain:find_next_free_trail(
    vector.round(table.last(motor.carts).object:get_pos()), 
    dir
  )
  
  if new_pos and last_available_pos then
    for i, c in ipairs(motor.carts) do
      if i > cart_pos then
        if motor.carts[i + 1] ~= nil then
          c.old_dir = vector.direction(motor.carts[i+1].object:get_pos(), c.object:get_pos())
          c.object:set_pos(motor.carts[i+1].object:get_pos())
        else
          c.old_dir = vector.direction(last_available_pos, c.object:get_pos())
          c.object:set_pos(last_available_pos)
        end
      end
    end
    cart.object:set_pos(new_pos)
    cart.parent = motor
    cart.old_dir = vector.direction(
      new_pos,
      motor.carts[cart_pos].object:get_pos()
    )
    table.insert(motor.carts, cart_pos + 1, cart)
  else
    print("no more trails availables.")
  end
end

function unrailedtrain:place_train(player, position, direction)
  -- use cart as tool
  local node = minetest.get_node(position)
  if node.name == "carts:rail" then
    local obj =	minetest.add_entity(position, "unrailedtrain:motor_1")
    local entity = obj:get_luaentity()
    entity.owner = player
    
    local trail_pos = unrailedtrain:find_next_free_trail(position, vector.multiply(direction, -1))
    local trail_dir = vector.direction(position, trail_pos)
    entity.old_dir = direction
    local yaw = vector.angle({x=0, y=0, z=1}, trail_dir)
    entity.object:set_yaw(yaw)
    -- unrailedtrain:add_train(entity)
    unrailedtrain.session.train = entity
    return entity
  end
  return nil
end

function unrailedtrain:detach_cart(motor, cart)
  if not motor then
    return
  end
  -- Remove cart and rearrange the rest of the carts
  local cart_index = table.find_index(motor.carts, cart)
  local changes = {}
  for i,v in pairs(motor.carts) do
    if i > cart_index then
      changes[i] = {
        pos = motor.carts[i-1].object:get_pos(),
        dir = motor.carts[i-1].dir
      }
    end
  end
  for i,v in pairs(changes) do
    motor.carts[i].object:set_pos(v.pos)
    motor.carts[i].dir = v.dir
  end
  table.remove(motor.carts, cart_index)
end

function unrailedtrain:on_punch_on_cart(cart_entity, puncher, time_from_last_punch, tool_capabilities, direction)
  print(dump(cart_entity))
  -- Player digs cart by sneak-punch
	if puncher:get_player_control().sneak then
		if cart_entity.sound_handle then
			minetest.sound_stop(cart_entity.sound_handle)
    end
    
		-- Detach items
    if cart_entity.cargo then
      for _, obj_ in ipairs(cart_entity.cargo) do
        if obj_ then
          obj_:set_detach()
        end
      end
    end

    -- Add a replacement cart to the world
    -- minetest.add_item(cart_entity.object:get_pos())
    unrailedtrain:detach_cart(cart_entity.parent, cart_entity)
    cart_entity.object:remove()
		return
	end
end

function unrailedtrain:on_punch_on_motor(entity, puncher, time_from_last_punch, tool_capabilities, direction)
  if table.length(entity.carts) > 1 then
    return
  end

  
	-- Player digs cart by sneak-punch
	if puncher:get_player_control().sneak then
		if entity.sound_handle then
			minetest.sound_stop(entity.sound_handle)
		end

    -- Add a replacement cart to the world
    -- minetest.add_item(entity.object:get_pos(), leftover)
    unrailedtrain:remove_train(entity)
    entity.object:remove()
		return
  end
  
  -- change train direction
  if not vector.equals(entity.old_dir, {x=0, y=0, z=0}) then
    entity.old_dir = vector.multiply(entity.old_dir, -1)
  else
    local d = find_previous_trail_pos(entity.object:get_pos(), nil)
    if d then
      entity.old_dir = vector.add(d, vector.multiply(entity.object:get_pos(), -1))
    end
  end
  set_entity_yaw(entity)
end

function unrailedtrain:take_materials(amount1, amount2)
	local cargo_cart = nil
  for i,v in ipairs(self.carts) do
		if v.object:get_entity_name() == "unrailedtrain:cargo_cart" then
			cargo_cart = v
		end
	end
	if cargo_cart ~= nil then
		local mat1_amount = unrailedtrain.take_material1_from_cart(cargo_cart, amount1)
		local mat2_amount = unrailedtrain.take_material2_from_cart(cargo_cart, amount2)
		return { 
			mat1 = mat1_amount,
			mat2 = mat2_amount
		}
	end
	return nil
end


function unrailedtrain:take_material1_from_cart(amount)
  if amount <= 0 or self.cargo.mat1_count == 0 then return 0 end
  local removed = self.cargo.mat1_count >= amount and amount or self.cargo.mat1_count
  for i=1,removed do
    local mat = table.remove( self.cargo.mat1_entities )
    mat.object:set_detach()
    mat.object:remove()
  end
  self.cargo.mat1_count = self.cargo.mat1_count - removed
  return removed
end

function unrailedtrain:take_material2_from_cart(amount)
  if amount <= 0 or self.cargo.mat2_count == 0 then return 0 end
  local removed = self.cargo.mat2_count >= amount and amount or self.cargo.mat2_count
  for i=1,removed do
    local mat = table.remove( self.cargo.mat2_entities )
    mat.object:set_detach()
    mat.object:remove()
  end
  self.cargo.mat2_count = self.cargo.mat2_count - removed
  return removed
end
