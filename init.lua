
unrailedtrain = {}
unrailedtrain.modpath = minetest.get_modpath("unrailedtrain")

-- Maximal speed of the cart in m/s (min = -1)
unrailedtrain.speed_max = 0.15
unrailedtrain.acceleration = 0.01
unrailedtrain.trains = {}

unrailedtrain.groups = {
	carts = { 
		"unrailedtrain:cargo_cart",
		"unrailedtrain:water_tank"
	 },
}

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
dofile(unrailedtrain.modpath.."/motor.lua")
dofile(unrailedtrain.modpath.."/cargo_cart.lua")
dofile(unrailedtrain.modpath.."/water_tank.lua")

