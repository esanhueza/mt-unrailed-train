unrailedtrain.map_generator.register_noise("filler_map", {
	offset = 0,
	scale = 1,
	spread = {x=100, y=100, z=100},
	octaves = 1,
	seed = 3112332142,
	persist = 0.3,
	flags = "defaults, absvalue"
})	

unrailedtrain.map_generator.register_noise("stone_map", {
	offset = 0,
	scale = 1.4,
	spread = {x=7, y=7, z=20},
	octaves = 1,
	seed = 3112332142,
	persist = 0.6,
	flags = "defaults"
})


function unrailedtrain:remove_map_level(conf)
	local vm = minetest.get_voxel_manip()
	local e1, e2 = vm:read_from_map(conf.minp, conf.maxp)
  local area = VoxelArea:new{MinEdge=e1, MaxEdge=e2}
  local data = {}
	vm:get_data(data)
	vm:get_param2_data(vmparam2)

	for z=conf.minp.z - 10, conf.maxp.z + 20 do
		for y=conf.minp.y - 10, conf.maxp.y + 10 do
      for x=conf.minp.x - 10, conf.maxp.x + 10 do
				luautils.place_node(x,y,z, area, data, minetest.get_content_id("air"))
      end
    end
	end

  vm:set_data(data)
	vm:set_lighting({day=0, night=0})
	vm:calc_lighting()
	vm:write_to_map()
	minetest.log("unrailedtrain generate_level 'level removed'")
end

function unrailedtrain:generate_map_level(conf)
	local size2d = luautils.box_sizexz(conf.minp, conf.maxp)
  local minposxz = {x=conf.minp.x, y=conf.minp.z}
  local surface = {}
  local vmparam2 = {}
	local nixz=1
	local filler_noise = unrailedtrain.map_generator.get_noise2d("filler_map", conf.seed, size2d, minposxz)
	local stone_noise = unrailedtrain.map_generator.get_noise2d("stone_map", conf.seed, size2d, minposxz)
	local station_pos = {
		x = math.floor(conf.minp.x + 8 + math.random() * (conf.maxp.x - conf.minp.x - 8)),
		z = conf.maxp.z - 6
	}

  for z=conf.minp.z, conf.maxp.z do
		surface[z]={}
		for x=conf.minp.x, conf.maxp.x do
			surface[z][x]={}
			surface[z][x].top = conf.sealevel + math.floor(filler_noise[nixz] * 5)
			surface[z][x].bot = conf.sealevel + math.floor(stone_noise[nixz] * 5)
			if luautils.distance2d(x, z, station_pos.x, station_pos.z, 1) < 10 or luautils.distance2d(x, z, conf.last_rail_pos.x, conf.last_rail_pos.z, 1) < 10 then
				surface[z][x].bot = conf.sealevel
			end
			nixz=nixz+1
		end
	end
  
	local vm = minetest.get_voxel_manip()
	local e1, e2 = vm:read_from_map(conf.minp, conf.maxp)
  local area = VoxelArea:new{MinEdge=e1, MaxEdge=e2}
  local data = {}
	vm:get_data(data)
	vm:get_param2_data(vmparam2)

	local biome = unrailedtrain.map_generator.biome[conf.biome]
	for z=conf.minp.z, conf.maxp.z do
		for y=conf.minp.y, conf.maxp.y do
      for x=conf.minp.x, conf.maxp.x do
        local sfc=surface[z][x]
        if y<sfc.bot then
          luautils.place_node(x,y,z, area, data, biome.node_stone)
        elseif y<sfc.top and sfc.top >= sfc.bot then 
          luautils.place_node(x,y,z, area, data, biome.node_filler)
        elseif y==sfc.top and sfc.top >= sfc.bot then
          luautils.place_node(x,y,z, area, data, biome.node_top)
					--if biome_def.decorate~=nil then biome_def.decorate(x,y+1,z, biome_def, conf) end
        end
      end
    end
	end
	
	local mts = {}
	local lsys = {}
	biome:add_resources({
		conf = conf,
		vm   = vm,
		area = area,
		data = data,
		surface = surface,
		filler_noise = filler_noise,
		stone_noise = stone_noise,
		mts = mts,
		lsys = lsys
	})

  vm:set_data(data)

	for i = 1, #mts do
		if luautils.distance2d(mts[i][1].x, mts[i][1].z, station_pos.x, station_pos.z, 1) >= 10 and luautils.distance2d(mts[i][1].x, mts[i][1].z, conf.last_rail_pos.x, conf.last_rail_pos.z, 1) >= 10 then
			minetest.place_schematic_on_vmanip(vm, mts[i][1], mts[i][2], "random", nil, true)  --true means force replace other nodes
		end
	end

	station_pos.y = math.max(surface[station_pos.z][station_pos.x].top, surface[station_pos.z][station_pos.x].bot)
	minetest.place_schematic_on_vmanip(
		vm,
		station_pos,
		unrailedtrain.modpath.."/schematics/"..conf.station..".mts",
		nil,
		nil,
		true
	)
	
	vm:set_lighting({day=0, night=0})
	vm:calc_lighting()
	vm:write_to_map()

	minetest.log("lsys size: " .. #lsys)
	for i = 1, #lsys do
		minetest.spawn_tree(lsys[i][1],lsys[i][2])
	end
	minetest.log("unrailedtrain generate_level 'level generated'")

	return {
		station_position = station_pos,
		surface = surface
	}
end