unrailedtrain.map_generator.register_noise("terrain_map", {
	offset = 0,
	scale = 1,
	spread = {x=100, y=100, z=100},
	octaves = 1,
	seed = 3112332122,
	persist = 0.3,
	flags = "defaults, absvalue"
})	

unrailedtrain.map_generator.register_noise("stone_map", {
	offset = 0,
	scale = 1.4,
	spread = {x=7, y=7, z=20},
	octaves = 1,
	seed = 3112332122,
	persist = 0.6,
	flags = "defaults"
})


function unrailedtrain:generate_level(conf)
	minetest.log("unrailedtrain generate_level-> =" .. conf.name)
  local size2d = luautils.box_sizexz(conf.minp,conf.maxp)
  local minposxz = {x=conf.minp.x, y=conf.minp.z}
  local surface = {}
  local vmparam2 = {}
	local nixz=1
	local terrain_noise = unrailedtrain.map_generator.get_noise2d("terrain_map", conf.seed, size2d, minposxz)
	local stone_noise = unrailedtrain.map_generator.get_noise2d("stone_map", conf.seed, size2d, minposxz)
	
  for z=conf.minp.z, conf.maxp.z do
		surface[z]={}
		for x=conf.minp.x, conf.maxp.x do
			surface[z][x]={}
			print(x, z)
			if terrain_noise[nixz] then
				surface[z][x].top = conf.sealevel + math.floor(terrain_noise[nixz] * 5)
				surface[z][x].bot = conf.sealevel + math.floor(stone_noise[nixz] * 5)
			end
			nixz=nixz+1
		end
	end
  
  local vm = minetest.get_voxel_manip(conf.minp, conf.maxp)
  local area = VoxelArea:new{MinEdge=conf.minp, MaxEdge=conf.maxp}
  local data = {}
	vm:get_data(data)
	vm:get_param2_data(vmparam2)
	
	for z=conf.minp.z, conf.maxp.z do
		for y=conf.minp.y, conf.maxp.y do
      for x=conf.minp.x, conf.maxp.x do
        local sfc=surface[z][x]
        local biome_def = unrailedtrain.map_generator.biome[conf.biome]
        if y<sfc.bot then
          luautils.place_node(x,y,z, area, data, biome_def.node_stone)
        elseif y<sfc.top and sfc.top >= sfc.bot then 
          luautils.place_node(x,y,z, area, data, biome_def.node_filler)
        elseif y==sfc.top and sfc.top >= sfc.bot then
          luautils.place_node(x,y,z, area, data, biome_def.node_top)
          --if biome_def.decorate~=nil then biome_def.decorate(x,y+1,z, biome_def, conf) end
        end
      end
    end
  end
  
  vm:set_data(data)
	vm:set_lighting({day=0, night=0})
	vm:calc_lighting()
	vm:write_to_map()
	minetest.log("unrailedtrain generate_level 'level generated'")
end