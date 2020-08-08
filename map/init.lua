
--Realms is Minetest mod that allows you to use multiple diferent lua landscape generators
--and control exactly where each one runs on the map through the unrailedtrain.conf file

unrailedtrain.map_generator = {}

local c_air = minetest.get_content_id("air")
local c_stone = minetest.get_content_id("default:stone")
local c_dirt = minetest.get_content_id("default:dirt")
local c_dirt_grass = minetest.get_content_id("default:dirt_with_grass")
local c_sand = minetest.get_content_id("default:sand")

unrailedtrain.map_generator.undefined_biome={
	name="undefined_biome",
	node_top=c_dirt_grass,
	depth_top = 1,
	node_filler=c_dirt,
	depth_filler = 5,
	dec=nil
	}

unrailedtrain.map_generator.undefined_underwater_biome={
	name="undefined_underwater_biome",
	node_top=c_sand,
	depth_top = 1,
	node_filler=c_sand,
	depth_filler = 1,
	dec=nil
	}

local vmparam2 = {}

local pts=luautils.pos_to_str
local von=luautils.var_or_nil
local placenode=luautils.place_node

--note that these are global
unrailedtrain.map_generator.rmg={}  --realms map gen
unrailedtrain.map_generator.rmf={}  --realms map function
unrailedtrain.map_generator.noise={} --noise (so you can reuse the same noise or change it easily)
unrailedtrain.map_generator.biome={} --where registered biomes are stored.  Remember, registered biomes do nothing unless included in a biome map
unrailedtrain.map_generator.biomemap={}

function unrailedtrain.map_generator.register_noise(name, noise)
	local nameseed=0
	for i=1,string.len(name) do
		nameseed=nameseed+i*string.byte(name,i)
	end --for
	noise.nameseed=nameseed
	unrailedtrain.map_generator.noise[name]=noise
	minetest.log("realms-> noise registered for: "..name)
end


function unrailedtrain.map_generator.get_noise(noisename, seed)
	local noise = unrailedtrain.map_generator.noise[noisename]
	noise.seed = noise.nameseed + tonumber(seed)
	return noise
end

function unrailedtrain.map_generator.get_noise2d(noisename, seed, size2d, minposxz)
	local noise = unrailedtrain.map_generator.get_noise(noisename, seed)
	local noisemap = minetest.get_perlin_map(noise, size2d):get_2d_map_flat(minposxz)
	return noisemap
end

function unrailedtrain.map_generator.add_resource(x,y,z, parms, resources)
	local area=parms.area
	local data=parms.data
	local vmparam2=parms.vmparam2
	local d=1
	local r=math.random()*100
	print(dump(resources[d].chancebot))
	while (resources[d]~=nil) and (r<resources[d].chancebot) do
		d=d+1
		end
	if (resources[d]~=nil) and (r<resources[d].chancetop) then
		local px=x
		local py=y
		local pz=z
		if resources[d].offset_x ~= nil then px=px+resources[d].offset_x end
		if resources[d].offset_y ~= nil then py=py+resources[d].offset_y end
		if resources[d].offset_z ~= nil then pz=pz+resources[d].offset_z end
		local rotate=nil
		if resources[d].rotate~=nil then
			if type(resources[d].rotate)=="table" then rotate=resources[d].rotate[math.random(1,#resources[d].rotate)]
			elseif resources[d].rotate=="random" then rotate=math.random(0,3)
			elseif resources[d].rotate=="random3d" then rotate=math.random(0,11)
			else rotate=resources[d].rotate
			end
		end
		if resources[d].node~=nil then
			--note that rotate will be nil unless they sent a rotate value, and if it is nil, it will be ignored
			placenode(px,py,pz,area,data,resources[d].node, vmparam2,rotate)
			if resources[d].height~=nil then
				local height_max=resources[d].height_max
				if height_max==nil then height_max=resources[d].height end
				local r=math.random(resources[d].height,height_max)
				for i=2,r do --start at 2 because we already placed 1
					placenode(px,py+i-1,pz,area,data,resources[d].node, vmparam2,rotate)
				end
			end
		elseif resources[d].func~=nil then
			resources[d].func(px, py, pz, area, data)
		elseif resources[d].schematic~=nil then
			table.insert(parms.mts,{{x=px,y=py,z=pz},resources[d].schematic})
		elseif resources[d].lsystem~=nil then
			table.insert(parms.lsys,{{x=px,y=py,z=pz},resources[d].lsys})
		end
	end
end

function unrailedtrain.map_generator.get_content_id(nodename)
	if nodename==nil or nodename=="" then return nil
	--if you sent a number, assume that is the correct content id
	elseif type(nodename)=="number" then return nodename
	else return minetest.get_content_id(nodename)
	end --if
end

function unrailedtrain.map_generator.calc_biome_elements(biome, property)
	local d=1
	if biome[property]~=nil then --there are[property]orations!
		--# gets the length of an array
		--putting it in biome[property].max is probably not really needed, but I find it easy to use and understand
		biome[property].max=#biome[property]
		local chancetop=0
		local chancebot=0
		--loop BACKWARDS from last[property]oration to first setting our chances.
		--the point here is that we dont want to roll each chance individually.  We want to roll ONE chance,
		--and then determine which[property]oration, if any, was selected.  So this process sets up the chancetop and chancebot
		--for each[property] element so that we can easily (and quickly) go through them when[property]orating.
		--example: [property][1].chance=3 [property][2].chance=5[property] 3.chance=2
		--after this runs
		--[property][1].chancebot=7 [property][1].chancetop=9
		--[property][2].chancebot=2 [property][2].chancetop=7
		--[property][3].chancebot=0 [property][3].chancetop=2
		for d=biome[property].max, 1, -1 do
			--minetest.log("realms calc_biome[property]->  [property]oration["..d.."] =")
			luautils.log_table(biome[property][d])
			if biome[property][d].chance~=nil then  --check this because intend to incorporate noise option in future.
				chancebot=chancetop
				chancetop=chancetop+biome[property][d].chance
				biome[property][d].chancetop=chancetop
				biome[property][d].chancebot=chancebot
				--turn node entries from strings into numbers
				biome[property][d].node=unrailedtrain.map_generator.get_content_id(biome[property][d].node) --will return nil if passed nil
				--minetest.log("realms calc_biome->  content_id="..von(biome.dec[d].node))
			end --if dec.chance~=nil
		end --for d
	end --if biome.dec~=nil
end

function unrailedtrain.map_generator.calc_biome(biome)
	unrailedtrain.map_generator.calc_biome_elements(biome, "metals")
	unrailedtrain.map_generator.calc_biome_elements(biome, "wood")
	unrailedtrain.map_generator.calc_biome_elements(biome, "decorations")
end



--********************************
--untested, probably needs to be modified so you could add multiple decorations
function unrailedtrain.map_generator.add_decoration(biome,newdec)
	--minetest.log("add_decoration-> #newdec="..#newdec)
	if biome.dec==nil then biome.dec=newdec
	else 
		for _,v in pairs(newdec) do
			table.insert(biome.dec, v)
		end--for
	--biome.dec[#biome.dec+1]=newdec
	end --if
	unrailedtrain.map_generator.calc_biome(biome)
	--minetest.log("  add_decoration -> #biome.dec="..#biome.dec)
end --add_decoration




function unrailedtrain.map_generator.add_dec_flowers(biomein,modifier,cat)
	local biome
	if type(biomein)=="string" then biome=unrailedtrain.map_generator.biome[biomein]
	else biome=biomein
	end --if type(biomein)
	if modifer==nil or modifier==0 then modifier=1 end 
	if flowers then --if the flowers mod is available
		--the category parm may not be needed, since I'm just adding all flowers the same right now
		if cat==nil or cat=="all" then  
			unrailedtrain.map_generator.add_decoration(biome,
				{
					{chance=0.30*modifier, node="flowers:dandelion_yellow"},
					{chance=0.30*modifier, node="flowers:dandelion_white"},
					{chance=0.25*modifier, node="flowers:rose"},
					{chance=0.25*modifier, node="flowers:tulip"},
					{chance=0.20*modifier, node="flowers:chrysanthemum_green"},
					{chance=0.20*modifier, node="flowers:geranium"},
					{chance=0.20*modifier, node="flowers:viola"},
					{chance=0.05*modifier, node="flowers:tulip_black"},
				})
		end --if cat==all
	end --if flowers
end --add_dec_flowers


function unrailedtrain.map_generator.add_dec_mushrooms(biomein,modifier) --can add a cat to this later if needed
	if type(biomein)=="string" then biome=unrailedtrain.biome[biomein]
	else biome=biomein
	end --if type(biomein)
	if modifer==nil or modifier==0 then modifier=1 end 
	unrailedtrain.map_generator.add_decoration(biome,
		{
			{chance=0.05*modifier,node="realms:mushroom_white"},
			{chance=0.01*modifier,node="realms:mushroom_milkcap"},
			{chance=0.01*modifier,node="realms:mushroom_shaggy_mane"},
			{chance=0.01*modifier,node="realms:mushroom_parasol"},
			{chance=0.005*modifier,node="realms:mushroom_sulfer_tuft"},
		})
	if flowers then --if the flowers mod is available
		unrailedtrain.map_generator.add_decoration(biome,
			{
				{chance=0.05*modifier, node="flowers:mushroom_brown"},
				{chance=0.05*modifier, node="flowers:mushroom_red"},
			})
	end --if flowers
end --add_dec_flowers


--********************************
function unrailedtrain.map_generator.register_biome(biome)
	if unrailedtrain.map_generator.biome[biome.name]~=nil then
		minetest.log("unrailedtrain.register_biome-> ***WARNING!!!*** duplicate biome being registered!  biome.name="..biome.name)
	end
	unrailedtrain.map_generator.biome[biome.name]=biome

	--set defaults
	if biome.depth_top==nil then biome.depth_top=1 end
	if biome.node_filler==nil then biome.node_filler="default:dirt" end
	if biome.depth_filler==nil then biome.depth_filler=3 end
	if biome.node_stone==nil then biome.node_stone="default:stone" end


	--turn the node names into node numbers
	--minetest.log("*** biome.name="..biome.name)
	biome.node_dust = unrailedtrain.map_generator.get_content_id(biome.node_dust)
	biome.node_top = unrailedtrain.map_generator.get_content_id(biome.node_top)
	biome.node_filler = unrailedtrain.map_generator.get_content_id(biome.node_filler)
	biome.node_stone = unrailedtrain.map_generator.get_content_id(biome.node_stone)
	biome.node_water_top = unrailedtrain.map_generator.get_content_id(biome.node_water_top)
	biome.node_riverbed = unrailedtrain.map_generator.get_content_id(biome.node_riverbed)
	--will have to do the same thing for the dec.node entries, but we do that below

	--now deal with the decorations (this is different from the way minetest does its biomes)
	unrailedtrain.map_generator.calc_biome(biome)
	minetest.log("realms-> biome registered for: "..biome.name)
end



dofile(unrailedtrain.modpath.."/map/levels.lua")
dofile(unrailedtrain.modpath.."/map/biomes/grassland.lua")
dofile(unrailedtrain.modpath.."/map/layer_barrier_generator.lua")
dofile(unrailedtrain.modpath.."/map/map_generator.lua")
dofile(unrailedtrain.modpath.."/map/commands.lua")

