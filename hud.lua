function unrailedtrain.edit_inventory(player)
  player:get_inventory():set_size("main", 1)
  player:hud_set_hotbar_itemcount(1)
  player:hud_set_hotbar_image("")
  player:hud_set_flags({
    healthbar = false,
    breathbar = false,
    minimap = false,
    minimap_radar = false,
    hotbar = false,
    crosshair = false
  })
end

minetest.register_on_joinplayer(unrailedtrain.edit_inventory)