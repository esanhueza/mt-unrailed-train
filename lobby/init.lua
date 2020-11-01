
unrailedtrain.lobby = {
  position = {x=29000, y=29000, z=29000},
  size = {x=100, y=100, z=100},
  separation = 50,
  mts = unrailedtrain.modpath.."/schematics/lobby_1.mts",
  lobbies = {},
  count = 0,
  invitations = {}
}

dofile(unrailedtrain.modpath.."/lobby/functions.lua")
dofile(unrailedtrain.modpath.."/lobby/nodes.lua")




minetest.register_on_player_receive_fields(function(player, formname, fields)
  if formname == "unrailedtrain:invitation" then
    unrailedtrain.resolve_invitation(player, fields)  
    return
  end
end)

minetest.register_on_joinplayer(unrailedtrain.assign_player_lobby)
minetest.register_on_leaveplayer(unrailedtrain.remove_player_from_lobby)