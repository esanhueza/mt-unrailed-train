unrailedtrain.game = {
  number_of_players = 1,
  map_start_position = {
    x = 0,
    y = 0,
    z = 0
  },
  map_length = 100,
  map_width = 50,
  map_height = 50,
}

function unrailedtrain:start_game(player)
  if unrailedtrain.session.train ~= nil then
    unrailedtrain.session.train:start()
  end
end

function unrailedtrain:generate_game(player)
  if unrailedtrain.session == nil then
    self:register_player(player:get_player_name())
    local level = self:find_level("level_1")
    if level == nil then
      minetest.log("'Level 1 not found'")
      return
    end
    unrailedtrain.session.current_level = level
    self:generate_level(player, level, true)

    -- spawn train
    local entity = unrailedtrain:place_train(player, {
      x=level.last_rail_pos.x,
      y=level.last_rail_pos.y,
      z=level.last_rail_pos.z + 6
    }, {
      x=0,
      y=0,
      z=1
    })
    
    for i,v in ipairs(unrailedtrain.basic_carts) do
      local cart_obj = minetest.add_entity(level.last_rail_pos, v)
      unrailedtrain:attach_cart(entity, 1, cart_obj:get_luaentity())
    end
    -- teleport player to level
    player:set_pos(level.last_rail_pos)
	end
end

function unrailedtrain:find_level(name)
  for i,v in ipairs(unrailedtrain.levels) do
    if string.match(v.name, name) then
      return v
    end
  end
  return nil
end

function unrailedtrain:find_next_level(player_name)
  local session = unrailedtrain:find_player_session(player_name)
  if session then
    for i,v in ipairs(unrailedtrain.game.levels) do
      if v.index == session.level + 1 then
        return v
      end
    end
  end
  return nil
end

function unrailedtrain:register_player(player_name)
  unrailedtrain.session = {
    player_name = player_name,
    current_level = nil,
    carts = {},
    train = nil,
    position = {x=0, y=0, z=0}
  }
end