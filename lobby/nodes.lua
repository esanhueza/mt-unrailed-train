local invitation_node_def = {
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

  on_construct = function(pos)
    local meta = minetest.get_meta(pos)
    meta:set_string("formspec", "field[text;;${text}]")
  end,
  on_receive_fields = function(pos, formname, fields, sender)
    unrailedtrain.invite_player(sender, fields.text)
  end,
	on_blast = function() end,
	on_destruct = function () end,
}

minetest.register_node("unrailedtrain:invitation_sign", invitation_node_def)