
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

function unrailedtrain.map_generator.decorate(x,y,z, biome, parms)
	local dec=biome.dec
	if dec==nil then return end --no decorations!
	local area=parms.area
	local data=parms.data
	local vmparam2=parms.vmparam2
	local d=1
	local r=math.random()*100
	--minetest.log("    r="..r)
	--we will loop until we hit the end of the list, or an entry whose chancebot is <= r
	--so when we exit we will be in one of these conditions
	--dec[d]==nil (this biome had no decorations)
	--r>=dec[d].chancetop (chance was too high, no decoration selected)
	--r<dec[d].chancetop (d is the decoration that was selected)
	while (dec[d]~=nil) and (r<dec[d].chancebot) do
		--minetest.log("      d="..d.." chancetop="..luautils.var_or_nil(dec[d].chancetop).." chancebot="..luautils.var_or_nil(dec[d].chancebot))
		d=d+1
		end
	--minetest.log("      d="..d.." chancetop="..luautils.var_or_nil(dec[d].chancetop).." chancebot="..luautils.var_or_nil(dec[d].chancebot))
	if (dec[d]~=nil) and (r<dec[d].chancetop) then
		--decorate
		--minetest.log("      hit d="..d.." chancetop="..luautils.var_or_nil(dec[d].chancetop).." chancebot="..luautils.var_or_nil(dec[d].chancebot))

		--deal with offest here, because we use it for all three decoration types
		local px=x
		local py=y
		local pz=z
		if dec[d].offset_x ~= nil then px=px+dec[d].offset_x end
		if dec[d].offset_y ~= nil then py=py+dec[d].offset_y end
		if dec[d].offset_z ~= nil then pz=pz+dec[d].offset_z end
		--this is only used in type=node for right now
		local rotate=nil
		if dec[d].rotate~=nil then
			if type(dec[d].rotate)=="table" then rotate=dec[d].rotate[math.random(1,#dec[d].rotate)]
			elseif dec[d].rotate=="random" then rotate=math.random(0,3)
			elseif dec[d].rotate=="random3d" then rotate=math.random(0,11)
			else rotate=dec[d].rotate
			end --if dec[d].rotate==random
		end --if dec[d].rotate~=nil
		if dec[d].node~=nil then
			--minetest.log("decorate:placing node="..dec[d].node.." biomename="..biome.name.." d="..d)
			--note that rotate will be nil unless they sent a rotate value, and if it is nil, it will be ignored
			placenode(px,py,pz,area,data,dec[d].node, vmparam2,rotate)
			if dec[d].height~=nil then
				local height_max=dec[d].height_max
				if height_max==nil then height_max=dec[d].height end
				local r=math.random(dec[d].height,height_max)
				--minetest.log("heighttest-> height="..dec[d].height.." height_max="..height_max.." r="..r)
				for i=2,r do --start at 2 because we already placed 1
					--minetest.log(" i="..i.." y-i+1="..(y-i)+1)
					placenode(px,py+i-1,pz,area,data,dec[d].node, vmparam2,rotate)
				end --for
			end --if dec[d].node.height
		elseif dec[d].func~=nil then
			dec[d].func(px, py, pz, area, data)
		elseif dec[d].schematic~=nil then
			--minetest.log("  unrailedtrain.decorate-> schematic "..luautils.pos_to_str_xyz(x,y,z).." biome="..biome.name)
			--placenode(x,y+1,z,area,data,c_mese)
			--minetest.place_schematic({x=x,y=y,z=z}, dec[d].schema, "random", nil, true)
			--minetest.place_schematic_on_vmanip(parms.vm,{x=x,y=y,z=z}, dec[d].schema, "random", nil, true)
			--can't add schematics to the area properly, so they get added to the parms.mts table, then placed at the end just before the vm is saved
			--I'm using offset instead of center so I dont have to worry about whether the schematic is a table or mts file
			--I dont know how to send flags for mts file schematics, flags dont seem to be working well for me anyway
			table.insert(parms.mts,{{x=px,y=py,z=pz},dec[d].schematic})
		elseif dec[d].lsystem~=nil then
			--minetest.spawn_tree({x=px,y=py,z=pz},dec[d].lsystem)
			--cant add it here, so treating the same as schematic
			table.insert(parms.lsys,{{x=px,y=py,z=pz},dec[d].lsys})
		end --if dec[d].node~=nil
	end --if (dec[d]~=nil)

	--minetest.log("  unrailedtrain.decorate-> "..luautils.pos_to_str_xyz(x,y,z).." biome="..biome.name.." r="..r.." d="..d)
end


function unrailedtrain.map_generator.get_content_id(nodename)
	if nodename==nil or nodename=="" then return nil
	--if you sent a number, assume that is the correct content id
	elseif type(nodename)=="number" then return nodename
	else return minetest.get_content_id(nodename)
	end --if
end


function unrailedtrain.map_generator.calc_biome_dec(biome)
	--minetest.log("realms calc_biome_dec-> biome="..von(biome.name))
	local d=1
	if biome.dec~=nil then --there are decorations!
		--# gets the length of an array
		--putting it in biome.dec.max is probably not really needed, but I find it easy to use and understand
		biome.dec.max=#biome.dec
		local chancetop=0
		local chancebot=0
		--loop BACKWARDS from last decoration to first setting our chances.
		--the point here is that we dont want to roll each chance individually.  We want to roll ONE chance,
		--and then determine which decoration, if any, was selected.  So this process sets up the chancetop and chancebot
		--for each dec element so that we can easily (and quickly) go through them when decorating.
		--example:  dec[1].chance=3 gdec[2].chance=5 dec 3.chance=2
		--after this runs
		--dec[1].chancebot=7  dec[1].chancetop=9
		--dec[2].chancebot=2  dec[2].chancetop=7
		--dec[3].chancebot=0  dec[3].chancetop=2
		for d=biome.dec.max, 1, -1 do
			--minetest.log("realms calc_biome_dec->   decoration["..d.."] =")
			luautils.log_table(biome.dec[d])
			if biome.dec[d].chance~=nil then  --check this because intend to incorporate noise option in future.
				chancebot=chancetop
				chancetop=chancetop+biome.dec[d].chance
				biome.dec[d].chancetop=chancetop
				biome.dec[d].chancebot=chancebot
				--turn node entries from strings into numbers
				biome.dec[d].node=unrailedtrain.map_generator.get_content_id(biome.dec[d].node) --will return nil if passed nil
				--minetest.log("realms calc_biome_dec->  content_id="..von(biome.dec[d].node))
			end --if dec.chance~=nil
		end --for d
		--this is the default function for realms defined biomes, no need to have to specify it every time
		if biome.decorate==nil then biome.decorate=unrailedtrain.decorate end
	end --if biome.dec~=nil
end --calc_biome_dec



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
	unrailedtrain.map_generator.calc_biome_dec(biome)
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
	unrailedtrain.map_generator.calc_biome_dec(biome)
	minetest.log("realms-> biome registered for: "..biome.name)
end



dofile(unrailedtrain.modpath.."/map/levels.lua")
dofile(unrailedtrain.modpath.."/map/biomes/grassland.lua")
dofile(unrailedtrain.modpath.."/map/layer_barrier_generator.lua")
dofile(unrailedtrain.modpath.."/map/map_generator.lua")
dofile(unrailedtrain.modpath.."/map/commands.lua")

