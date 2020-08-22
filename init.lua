
unrailedtrain = {}
unrailedtrain.modpath = minetest.get_modpath("unrailedtrain")

-- Maximal speed of the cart in m/s (min = -1)
unrailedtrain.speed_max = 0.4 -- 0.15
unrailedtrain.acceleration = 0.01
unrailedtrain.crafting_cooldown = 5
unrailedtrain.levels = {}
unrailedtrain.session = {}
unrailedtrain.groups = {
	carts = { 
		"unrailedtrain:cargo_cart_1",
		"unrailedtrain:rail_crafter_1",
		"unrailedtrain:water_tank_1"
	 },
	 rails = {
		 "unrailedtrain:indestructible_rail",
		 "crats:rail"
	 }
}
unrailedtrain.basic_train = "unrailedtrain:motor_1"
unrailedtrain.basic_carts = {
	"unrailedtrain:cargo_cart_1",
	"unrailedtrain:rail_crafter_1"
}

function unrailedtrain:generate_level(player, level, add_rails)
	if add_rails then
		level.last_rail_pos = {
			x = math.floor(level.minp.x + 12 + math.random() * (level.maxp.x - level.minp.x - 12)),
			z = level.minp.z
		}
	end
	-- generate map
	local data = unrailedtrain:generate_map_level(level)
	if add_rails then
		level.last_rail_pos.y = math.max(data.surface[level.last_rail_pos.z + 1][level.last_rail_pos.x].top, data.surface[level.last_rail_pos.z + 1][level.last_rail_pos.x].bot) + 1
		for i=0,12 do
			local ry = data.surface[level.last_rail_pos.z + i][level.last_rail_pos.x].top + 1
			minetest.set_node({x=level.last_rail_pos.x, y=ry, z=level.last_rail_pos.z + i}, {name="unrailedtrain:indestructible_rail"})
		end
	end 
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
	unrailedtrain.session.train = train
	--[[
  local index = table.find_index(self.trains, train)
  if index == nil then
		table.insert(self.trains, train)
	end
	]]--
end

function unrailedtrain:remove_train(train)
	unrailedtrain.session.train = nil
	--[[
  local index = table.find_index(self.trains, train)
  if index ~= nil then
		table.remove(self.trains, index)
	end
	]] --
end

dofile(unrailedtrain.modpath.."/utils.lua")
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
dofile(unrailedtrain.modpath.."/hud.lua")