
minetest.register_chatcommand("generate_lobby", {
	params = "<text>",
	description = "Generate a new lobby",
	privs = {talk = true},
  func = function(player_name, text)
    local player = minetest.get_player_by_name(player_name)
		if not player then
			return false, "Player not found"
    end
    unrailedtrain.create_lobby(player_name, {x=30000, y=30000, z=30000})
    player:set_pos({x=30002, y=30001, z=30005})
	end,
})



minetest.register_chatcommand("dump_lobbies", {
	params = "<text>",
	description = "Show lobbies info",
	privs = {talk = true},
  func = function(player_name, text)
    print(dump(unrailedtrain.lobby.lobbies))
	end,
})

