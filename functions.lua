local function get_railparams(pos)
	local node = minetest.get_node(pos)
	return carts.railparams[node.name] or {}
end

function find_next_free_trail(pos, dir)
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
  return false
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

function mytrain:on_rightclick_over_cart(self, clicker)
  local item = clicker:get_wielded_item()
  local motor = self
  
  if self.parent ~= nil then
    motor = self.parent
  end
  
  local is_cart = table.find(mytrain.groups.carts, item:get_name())
  if not is_cart then
    return
  end

  local cart_index = table.find_index(motor.carts, self)
  mytrain:attach_cart(motor, cart_index, item)
end

function mytrain:attach_cart(motor, cart_pos, cart)
  local dir = motor.carts[cart_pos].old_dir
  local new_pos = find_next_free_trail(
    vector.round(motor.carts[cart_pos].object:get_pos()), 
    dir
  )
  local last_available_pos = find_next_free_trail(
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
    local obj = minetest.add_entity(new_pos, cart:get_name())
    local entity = obj:get_luaentity()
    entity.parent = motor
    entity.cart_index = cart_pos + 1
    entity.old_dir = vector.direction(
      new_pos,
      motor.carts[cart_pos].object:get_pos()
    )
    table.insert(motor.carts, cart_pos + 1, entity)
  else
    print("no more trails availables.")
  end
end

function mytrain:detach_cart(motor, cart)
  local cart_index = table.find_index(motor.carts, cart)
  table.remove(motor.carts, cart_index)
end

function mytrain:on_punch_on_cart(cart_entity, puncher, time_from_last_punch, tool_capabilities, direction)
	local pos = cart_entity.object:get_pos()
  local vel = cart_entity.object:get_velocity()
  
	-- Player digs cart by sneak-punch
	if puncher:get_player_control().sneak then
		if cart_entity.sound_handle then
			minetest.sound_stop(cart_entity.sound_handle)
		end
		-- Detach driver and items
		for _, obj_ in ipairs(cart_entity.attached_items) do
			if obj_ then
				obj_:set_detach()
			end
		end
		-- Pick up cart
		local inv = puncher:get_inventory()

    -- Add a replacement cart to the world
    minetest.add_item(cart_entity.object:get_pos(), leftover)
    mytrain:detach_cart(cart_entity.parent, cart_entity)
    cart_entity.object:remove()
		return
	end
end