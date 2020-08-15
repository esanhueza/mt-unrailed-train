minetest.register_chatcommand("start_game", {
	params = "<text>",
	description = "Start current level",
	privs = {talk = true},
  func = function( name , text)
    local player = minetest.get_player_by_name(name)
		if not player then
			return false, "Player not found"
    end
    unrailedtrain:start_game(player)
	end,
})

minetest.register_chatcommand("train_info", {
	params = "<text>",
	description = "Start current level",
	privs = {talk = true},
  func = function( name , text)
    local player = minetest.get_player_by_name(name)
		if not player then
			return false, "Player not found"
    end
    print(dump(unrailedtrain.session.train))
	end,
})

minetest.register_chatcommand("generate_game", {
	params = "<text>",
	description = "Start current level",
	privs = {talk = true},
  func = function( name , text)
    local player = minetest.get_player_by_name(name)
		if not player then
			return false, "Player not found"
    end
    unrailedtrain:generate_game(player)
	end,
})

minetest.register_chatcommand("generate_map", {
	params = "<text>",
	description = "Send text to chat",
	privs = {talk = true},
  func = function( name , text)
    local player = minetest.get_player_by_name(name)
		if not player then
			return false, "Player not found"
    end
    
    for i,v in ipairs(unrailedtrain.levels) do
      if v.name == text then
        unrailedtrain:generate_level(player, v)
        return
      end
    end
	end,
})

minetest.register_chatcommand("remove_level", {
	params = "<text>",
	description = "Send text to chat",
	privs = {talk = true},
  func = function( name , text)
    local player = minetest.get_player_by_name(name)
		if not player then
			return false, "Player not found"
    end
    
    for i,v in ipairs(unrailedtrain.levels) do
      if v.name == text then
        unrailedtrain:remove_map_level(v)
        return
      end
    end
	end,
})