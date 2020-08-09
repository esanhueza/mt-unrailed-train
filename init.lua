
unrailedtrain = {}
unrailedtrain.modpath = minetest.get_modpath("unrailedtrain")

-- Maximal speed of the cart in m/s (min = -1)
unrailedtrain.speed_max = 0.15
unrailedtrain.acceleration = 0.01
unrailedtrain.crafting_cooldown = 5
unrailedtrain.trains = {}
unrailedtrain.levels = {}
unrailedtrain.groups = {
	carts = { 
		"unrailedtrain:cargo_cart_1",
		"unrailedtrain:rail_crafter_1",
		"unrailedtrain:water_tank_1"
	 },
}

function unrailedtrain:generate_level(player, level)
	-- generate map
	unrailedtrain:generate_map_level(level)
	-- spawn initial station
	-- spawn train
	-- teleport player to level
end

function unrailedtrain:register_level(level_def)
	local start_position = self.game.map_start_position
	local level_length = self.game.map_length
	local level_width = self.game.map_width
	local level_height = self.game.map_width

	level_def.minp = {
		x      = start_position.x,
		y      = start_position.y,
		z      = start_position.z
	}
	level_def.maxp = {
		x      = start_position.x + level_width,
		y      = start_position.y + level_height,
		z      = start_position.x + level_length
	}
	level_def.sealevel = start_position.y + 2
	
	table.insert(self.levels, level_def)
end

function unrailedtrain:add_train(train)
  local index = table.find_index(self.trains, train)
  if index == nil then
		table.insert(self.trains, train)
	end
end

function unrailedtrain:remove_train(train)
  local index = table.find_index(self.trains, train)
  if index ~= nil then
		table.remove(self.trains, index)
	end
end

dofile(unrailedtrain.modpath.."/functions.lua")
dofile(unrailedtrain.modpath.."/items.lua")
dofile(unrailedtrain.modpath.."/rails.lua")
dofile(unrailedtrain.modpath.."/motor.lua")
dofile(unrailedtrain.modpath.."/rail_crafter.lua")
dofile(unrailedtrain.modpath.."/cargo_cart.lua")
dofile(unrailedtrain.modpath.."/water_tank.lua")
dofile(unrailedtrain.modpath.."/game.lua")
dofile(unrailedtrain.modpath.."/map/init.lua")
dofile(unrailedtrain.modpath.."/map/levels.lua")