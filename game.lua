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
  local lobby = private_lobby.find_player_lobby(player:get_player_name())
  if not lobby then
    return
  end

  local session = unrailedtrain:register_session(lobby)
  local level = unrailedtrain:generate_map(lobby)

  for i,player_name in ipairs(session.lobby.players) do
    local p = minetest.get_player_by_name(player_name)
    p:set_pos(level.last_rail_pos)
  end
end

function unrailedtrain:generate_map(session)
  local level_conf = unrailedtrain:find_level("level_1")
  if level_conf == nil then
    minetest.log("'Level 1 not found'")
    return
  end

  local level = unrailedtrain:generate_level(level_conf, true)

  -- spawn train
  local entity = unrailedtrain:place_train({
    x=level_conf.last_rail_pos.x,
    y=level_conf.last_rail_pos.y,
    z=level_conf.last_rail_pos.z + 6
  }, {
    x=0,
    y=0,
    z=1
  })

  if not entity then
    minetest.log("Error when trying to place train.")
    return
  end
  entity.owner = player
  
  for i,v in ipairs(unrailedtrain.basic_carts) do
    local cart_obj = minetest.add_entity(level_conf.last_rail_pos, v)
    unrailedtrain:attach_cart(entity, 1, cart_obj:get_luaentity())
  end

  return level_conf
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

function unrailedtrain:register_session(lobby)
  local session = {
    lobby = lobby,
    current_level = nil,
    carts = {},
    train = nil,
    position = {x=0, y=0, z=0}
  }
  table.insert(unrailedtrain.sessions, session)
  return session
end

minetest.register_on_joinplayer(private_lobby.handle_joinplayer)
minetest.register_on_leaveplayer(private_lobby.remove_player_from_lobby)