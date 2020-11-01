local startgame_node_def = {
	groups = {attached_node = 1},  
  description = desc,
  drawtype = "nodebox",
  tiles = {"default_sign_wall_steel.png"},
  inventory_image = "default_sign_steel.png",
  wield_image = "default_sign_steel.png",
  paramtype = "light",
  paramtype2 = "wallmounted",
  sunlight_propagates = true,
  is_ground_content = false,
  walkable = false,
  node_box = {
    type = "wallmounted",
    wall_top    = {-0.4375, 0.4375, -0.3125, 0.4375, 0.5, 0.3125},
    wall_bottom = {-0.4375, -0.5, -0.3125, 0.4375, -0.4375, 0.3125},
    wall_side   = {-0.5, -0.3125, -0.4375, -0.4375, 0.3125, 0.4375},
  },
  legacy_wallmounted = true,
  on_punch = function(pos, node, player)
    print(dump(pos))
    print(dump(node))
    print(dump(player))
    unrailedtrain:start_game(player)
  end,
	on_blast = function() end,
	on_destruct = function () end,
}

minetest.register_node("unrailedtrain:startgame_sign", startgame_node_def)