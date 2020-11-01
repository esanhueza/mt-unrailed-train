function unrailedtrain.create_lobby()
  local last_lobby = table.last(unrailedtrain.lobby.lobbies)
  local t_lobbies = #unrailedtrain.lobby.lobbies
  local l_index = {
    z=t_lobbies % 100,
    y=math.floor(t_lobbies / 10),
    x=math.floor(t_lobbies / 100)
  }

  local pos = unrailedtrain.lobby.position
  pos.x = pos.x + l_index.x * (unrailedtrain.lobby.separation + unrailedtrain.lobby.size.x)
  pos.y = pos.y + l_index.y * (unrailedtrain.lobby.separation + unrailedtrain.lobby.size.y)
  pos.z = pos.z + l_index.z * (unrailedtrain.lobby.separation + unrailedtrain.lobby.size.z)
  
  local l_id = unrailedtrain.lobby.count + 1
  unrailedtrain.lobby.count = l_id
  local lobby = {
    index = l_index,
    id = l_id,
    state = 'free',
    leader = nil,
    players = {},
    position = pos,
    spawn_pos = {x=pos.x + 2, y=pos.y + 1, z=pos.z+5} 
  }
  minetest.place_schematic(pos, unrailedtrain.lobby.mts, 0, nil, true, nil)
  table.insert(unrailedtrain.lobby.lobbies, lobby)
  minetest.log("action", "Lobby created at " .. (pos.x) .. ", " .. (pos.y) .. "," .. (pos.z))
  return lobby
end

function unrailedtrain.find_invitation_by_target(player_name)
  for i,v in ipairs(unrailedtrain.lobby.invitations) do
    if v.target == player_name then
      return v
    end
  end
end

function unrailedtrain.find_lobby_by_leader(player_name)
  for i,v in ipairs(unrailedtrain.lobby.lobbies) do
    if v.leader == player_name then
      return v
    end
  end
end

function unrailedtrain.find_player_lobby(player_name)
  for i,v in ipairs(unrailedtrain.lobby.lobbies) do
    if v.leader == player_name or table.find(v.players, player_name) then
      return v
    end
  end
end

function unrailedtrain.remove_invitation(invitation)
  for i,v in ipairs(unrailedtrain.lobby.invitations) do
    if v == invitation then
      table.remove(unrailedtrain.lobby.invitations, i)
      return
    end
  end
end

function unrailedtrain.invite_player(sender, target_name)
  if not target_name then
    return
  end
  if sender:get_player_name() == target_name then
    minetest.chat_send_player(sender:get_player_name(), "You can't invite yourself")
    return
  end
  if string.len(target_name) > 512 then
    minetest.chat_send_player(sender:get_player_name(), "Player name too long")
    return
  end
  local target_player = minetest.get_player_by_name(target_name)
  if not target_player then
    minetest.chat_send_player(sender:get_player_name(), "Player is not online")
    return
  end
  local has_invitation = unrailedtrain.find_invitation_by_target(target_name)
  if has_invitation then
    minetest.chat_send_player(sender:get_player_name(), ("Player has another invitation pending."))
    return
  end

  local formspec = {
      "formspec_version[3]",
      "size[6,3.476]",
      "label[0.375,0.5;", minetest.formspec_escape(sender:get_player_name()), " has invited you to\nplay together!]",
      "button[3.5,2.3;2,0.8;accept;Accept]",
      "button[0.5,2.3;2,0.8;ignore;Ignore]"
  }

  minetest.show_formspec(target_player:get_player_name(), "unrailedtrain:invitation",  table.concat(formspec, ""))
  table.insert(unrailedtrain.lobby.invitations, {
    target = target_player:get_player_name(),
    sender = sender:get_player_name(),
  })

  minetest.chat_send_player(sender:get_player_name(), "Your invitatión was sent")
end

function unrailedtrain.resolve_invitation(player, fields)
  local invitation = unrailedtrain.find_invitation_by_target(player:get_player_name())
  if not invitation then
    minetest.log("action", "Player " .. player:get_player_name() .. " tried to answer a invitation that does not exist anymore.")
    minetest.chat_send_player(player:get_player_name(), "The invitation expired.")
    return
  end
  if fields.ignore then
    minetest.chat_send_player(invitation.sender, player:get_player_name() .. " did not accept the invitation.")
    minetest.close_formspec(player:get_player_name(), "unrailedtrain:invitation")
    unrailedtrain.remove_invitation(invitation)
    return
  end
  
  if not fields.accept then
    -- something weird happened
    return
  end

  local lobby = unrailedtrain.find_lobby_by_leader(invitation.sender)
  if not lobby then
    minetest.chat_send_player(player:get_player_name(), invitation.sender .. " is not online anymore.")
  end

  table.insert(lobby.players, player:get_player_name())
  player:set_pos(lobby.spawn_pos)
  minetest.log("action", "Player " .. player:get_player_name() .. " was teleported to " .. invitation.sender .. "'s lobby.")
  unrailedtrain.remove_invitation(invitation)
  minetest.close_formspec(player:get_player_name(), "unrailedtrain:invitation")
end

function unrailedtrain.assign_player_lobby(player, last_login)
  local lobby = unrailedtrain.find_player_lobby(player:get_player_name())
  if lobby then
    player:set_pos(lobby.spawn_pos)
    return
  end
  -- find next free lobby
  for i,v in ipairs(unrailedtrain.lobby.lobbies) do
    if v.state == 'free' then
      lobby = v
      break
    end
  end
  if not lobby then
    -- if no free lobby exists
    -- create a new lobby
    lobby = unrailedtrain.create_lobby()
  end
  lobby.leader = player:get_player_name()
  lobby.state = 'in_use'
  table.insert(lobby.players, player:get_player_name())
  player:set_pos(lobby.spawn_pos)
  minetest.log("action", "Player " .. player:get_player_name() .. " was added to lobby [".. lobby.id .."].")
end

function unrailedtrain.remove_player_from_lobby(player, timed_out)
  local lobby = unrailedtrain.find_player_lobby(player:get_player_name())
  if not lobby then
    minetest.log("action", "Player " .. player:get_player_name() .. " leave and didn't have a lobby assigned.")
    return
  end
  if lobby.leader == player:get_player_name() then
    lobby.leader = nil
    minetest.log("action", "Player " .. player:get_player_name() .. " was removed as the leader of the lobby [" .. lobby.id .. "].")
  end
  table.remove(lobby.players, table.find_index(lobby.players, player:get_player_name()))
  minetest.log("action", "Player " .. player:get_player_name() .. " was removed from lobby [" .. lobby.id .. "].")

  if #lobby.players == 0 then
    lobby.state = 'free'
    minetest.log("action", "Lobby [" .. lobby.id .. "] is now free.")
  end
end