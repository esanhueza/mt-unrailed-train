
mytrain = {}
mytrain.modpath = minetest.get_modpath("mytrain")

-- Maximal speed of the cart in m/s (min = -1)
mytrain.speed_max = 0.15
mytrain.acceleration = 0.01
mytrain.trains = {}


mytrain.groups = {
	carts = { 
		"mytrain:cargo_cart",
		"mytrain:water_tank"
	 }
}

dofile(mytrain.modpath.."/functions.lua")
dofile(mytrain.modpath.."/motor.lua")
dofile(mytrain.modpath.."/cargo_cart.lua")
dofile(mytrain.modpath.."/water_tank.lua")

