minetest.register_chatcommand("generate", {
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

minetest.register_chatcommand("remove", {
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
        unrailedtrain:remove_level(player, v)
        return
      end
    end
	end,
})