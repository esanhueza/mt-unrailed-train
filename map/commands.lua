minetest.register_chatcommand("generate", {
	params = "<text>",
	description = "Send text to chat",
	privs = {talk = true},
  func = function( _ , text)
    for i,v in ipairs(unrailedtrain.levels) do
      print(v.name .. " = " .. text, v.name == text)
      if v.name == text then
        unrailedtrain:generate_level(v)
        return
      end
    end
	end,
})