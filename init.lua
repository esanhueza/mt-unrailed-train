
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
	 }
}

dofile(unrailedtrain.modpath.."/functions.lua")
dofile(unrailedtrain.modpath.."/motor.lua")
dofile(unrailedtrain.modpath.."/cargo_cart.lua")
dofile(unrailedtrain.modpath.."/water_tank.lua")

