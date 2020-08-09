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
  sessions = {
    {
      player = "player1", -- player name
      game_time = 300, -- seconds
      carts = {
        "train_1", -- entity's name
        "cargo_cart_1"
      },
      level = 1, -- level_index
      position = {x=0, y=0, z=0} -- position of the last station reached
    }
  }
}

function unrailedtrain:find_player_session(player_name)
  for i,v in ipairs(unrailedtrain.game.sessions) do
    if v.player == player_name then
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
  table.insert( unrailedtrain.sessions, {
    player = player_name,
    game_time = 0,
    carts = {
      "train_1",
      "cargo_cart_1",
      "rail_crafter_1"
    },
    level = 1,
    position = {x=0, y=0, z=0}
  })
end