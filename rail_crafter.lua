local entity_def = {
	initial_properties = {
		collisionbox = {-0.5, -0.5, -0.5, 0.5, 0.5, 0.5},
		visual = "mesh",
		mesh = "cargo_cart_1.b3d",
		textures = {"railers.png"},
		static_save = false,
	},
	old_pos = nil,
  old_dir = nil,
	railtype = nil,
  parent = nil,
	owner = nil,
  capacity = 6,
  cooldown = 0
}

function entity_def:add_rails(amount)
  if (self.capacity <= self.cargo.rails) then return 0 end
  local added = self.cargo.rails + amount <= self.capacity and amount or self.capacity - self.cargo.rails
  for i=1,added do
    local obj = minetest.add_entity(self.object:get_pos(), "unrailedtrain:rail_1")
    obj:set_attach(self.object, "", {
      x = 0, 
      y = (self.cargo.rails) - 1,
      z = 0
    }, {
      x = 0, 
      y = 0, 
      z = 0
    })
    table.insert( self.cargo.entities, obj:get_luaentity() )
    self.cargo.rails = self.cargo.rails + 1
  end	
  return added
end

function entity_def:take_rails(amount)
  if amount <= 0 or self.cargo.rails == 0 then return 0 end
  local removed = self.cargo.rails >= amount and amount or self.cargo.rails
  for i=1,removed do
    local rail = table.remove( self.cargo.entities )
    rail.object:set_detach()
    rail.object:remove()
  end
  self.cargo.rails = self.cargo.rails - removed
  return removed
end

function entity_def:craft_rail(dtime)
  if self.cooldown <= 0 and self.cargo.rails < self.capacity then
    if self.cargo.mat1_count < 1 or self.cargo.mat2_count < 1 then
      local mats = unrailedtrain.take_materials(
        self.parent,
        1 - self.cargo.mat1_count,
        1 - self.cargo.mat2_count
      )
      if mats ~= nil then
        self.cargo.mat1_count = self.cargo.mat1_count + mats.mat1
        self.cargo.mat2_count = self.cargo.mat2_count + mats.mat2
      end
    end
    if self.cargo.mat1_count >= 1 and self.cargo.mat2_count >= 1 then
      self.add_rails(self, 1)
      self.cargo.mat1_count = self.cargo.mat1_count - 1
      self.cargo.mat2_count = self.cargo.mat2_count - 1
      self.cooldown = unrailedtrain.crafting_cooldown
    end
  end
  self.cooldown = self.cooldown - dtime
end
function entity_def:on_step(dtime)
  if self.parent then
    if self.parent.running then
      unrailedtrain:cart_move(self, dtime)
    end
    self:craft_rail(dtime)
  end
end

function entity_def:stop()
	self.object:set_acceleration({x=0, y=0, z=0})
	self.object:set_velocity({x=0, y=0, z=0})
end

function entity_def:on_activate(staticdata, dtime_s)
  self.object:set_armor_groups({immortal=1, punch_operable=1})
  self.cooldown = 0
	self.old_pos = self.object:get_pos()
	self.cargo = {
    rails = 0,
    entities = {},
    mat1_count = 0,
    mat2_count = 0
	}
end

function entity_def:on_rightclick(clicker)
  local wielded_item = clicker:get_wielded_item()
  if wielded_item ~= nil and self.cargo.rails > 0 then
    if wielded_item:get_name() == "" or wielded_item:get_name() == "unrailedtrain:rail_stack" then
      local taken = self.take_rails(self, wielded_item:get_free_space())
      local stack = ItemStack("unrailedtrain:rail_stack")
      stack:set_count(wielded_item:get_count() + taken)
      clicker:set_wielded_item(stack)
    end
  end
end

function entity_def:on_punch(puncher, time_from_last_punch, tool_capabilities, direction)
  unrailedtrain:on_punch_on_cart(self, puncher, time_from_last_punch, tool_capabilities, direction)
end

minetest.register_entity("unrailedtrain:rail_crafter_1", entity_def)

minetest.register_craftitem("unrailedtrain:rail_crafter_1", {
	description = "Rails crafter",
	inventory_image = minetest.inventorycube("carts_cart_top.png", "carts_cart_side.png", "carts_cart_side.png"),
	wield_image = "carts_cart_side.png",
	on_place = function(itemstack, placer, pointed_thing)
		-- use cart as tool
		local under = pointed_thing.under
		local node = minetest.get_node(under)
		local udef = minetest.registered_nodes[node.name]
		if udef and udef.on_rightclick and
				not (placer and placer:is_player() and
				placer:get_player_control().sneak) then
			return udef.on_rightclick(under, node, placer, itemstack,
				pointed_thing) or itemstack
		end
	end,
})