local biome_def = {
  name = "grassland",
  node_top = "default:dirt_with_grass",
  node_stone = "default:stone",
  depth_top = 1,
  node_filler =  "default:dirt",
  depth_filler = 1,
  node_riverbed = "default:sand",
  depth_riverbed = 2,
  y_max = upper_limit,
  y_min = 6,
  metals={
    {chance=15, node="default:stone_with_iron"},
  },
  wood={
    {chance=3,schematic=minetest.get_modpath("default").."/schematics/apple_tree.mts", offset_x=-3,offset_z=-3,offset_y=-1},
    {chance=0.05,schematic=minetest.get_modpath("default").."/schematics/bush.mts", offset_x=-1,offset_z=-1},
  },
  decorations={
    {chance=5, node="default:grass_1"},
    {chance=5, node="default:grass_2"},
    {chance=5, node="default:grass_3"},
    {chance=5, node="default:grass_4"},
    {chance=5, node="default:grass_5"},
    {chance=0.25, node="flowers:rose"},
    {chance=0.25, node="flowers:tulip"},
    {chance=0.25, node="flowers:dandelion_yellow"},
    {chance=0.25, node="flowers:chrysanthemum_green"},
    {chance=0.25, node="flowers:geranium"},
    {chance=0.25, node="flowers:viola"},
    {chance=0.25, node="flowers:dandelion_white"},
    {chance=0.25, node="flowers:tulip_black"},
    {chance=0.05, node="flowers:mushroom_brown"},
    {chance=0.05, node="flowers:mushroom_red"},
  }
}

-- params: 
-- conf: level configuration
-- surface: map surface
-- vm:
-- area:
-- data:
-- filler_noise
-- stone_noise
function biome_def:add_resources(parms)
  self:add_wood(parms)
  self:add_metals(parms)
end

function biome_def:add_wood(parms)
  local nixz = 1
  for z=parms.conf.minp.z, parms.conf.maxp.z do
    for x=parms.conf.minp.x, parms.conf.maxp.x do
      if parms.surface[z][x].top > parms.surface[z][x].bot then
        if parms.stone_noise[nixz] * 5 < 2 then
          unrailedtrain.map_generator.add_resource(x,parms.surface[z][x].top+1,z, parms, self.wood)
        else
          unrailedtrain.map_generator.add_resource(x,parms.surface[z][x].top+1,z, parms, self.decorations)
        end
      end
			nixz=nixz+1
		end
  end
end

function biome_def:add_metals(parms)
  local nixz = 1
  for z=parms.conf.minp.z, parms.conf.maxp.z do
    for x=parms.conf.minp.x, parms.conf.maxp.x do
      if parms.surface[z][x].bot > parms.surface[z][x].top then
        unrailedtrain.map_generator.add_resource(x,parms.surface[z][x].bot,z, parms, self.metals)
      end
			nixz=nixz+1
		end
	end
end

unrailedtrain.map_generator.register_biome(biome_def)