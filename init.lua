local mod_start_time = minetest.get_us_time()
local bow_charged_timer = 0

x_bows = {
	pvp = minetest.settings:get_bool('enable_pvp') or false,
	creative = minetest.settings:get_bool('creative_mode') or false,
	mesecons = minetest.get_modpath('mesecons'),
	hbhunger = minetest.get_modpath('hbhunger'),
	registered_arrows = {},
	registered_bows = {},
	player_bow_sneak = {},
	settings = {
		x_bows_attach_arrows_to_entities = minetest.settings:get_bool("x_bows_attach_arrows_to_entities", false)
	}
}

function x_bows.is_creative(name)
	return x_bows.creative or minetest.check_player_privs(name, {creative = true})
end

function x_bows.register_bow(name, def)
	if name == nil or name == '' then
		return false
	end

	def.name = 'x_bows:' .. name
	def.name_charged = 'x_bows:' .. name .. '_charged'
	def.description = def.description or name
	def.uses = def.uses or 150

	x_bows.registered_bows[def.name_charged] = def

	-- not charged bow
	minetest.register_tool(def.name, {
		description = def.description .. '\n' .. minetest.colorize('#00FF00', 'Critical Arrow Chance: ' .. (1 / def.crit_chance) * 100 .. '%'),
		inventory_image = def.inventory_image or 'x_bows_bow_wood.png',
		-- on_use = function(itemstack, user, pointed_thing)
		-- end,
		on_place = x_bows.load,
		on_secondary_use = x_bows.load,
		groups = {bow = 1, flammable = 1},
		-- range = 0
	})

	-- charged bow
	minetest.register_tool(def.name_charged, {
		description = def.description .. '\n' .. minetest.colorize('#00FF00', 'Critical Arrow Chance: ' .. (1 / def.crit_chance) * 100 .. '%'),
		inventory_image = def.inventory_image_charged or 'x_bows_bow_wood_charged.png',
		on_use = x_bows.shoot,
		groups = {bow = 1, flammable = 1, not_in_creative_inventory = 1},
	})

	-- recipes
	if def.recipe then
		minetest.register_craft({
			output = def.name,
			recipe = def.recipe
		})
	end
end

function x_bows.register_arrow(name, def)
	if name == nil or name == '' then
		return false
	end

	def.name = 'x_bows:' .. name
	def.description = def.description or name

	x_bows.registered_arrows[def.name] = def

	minetest.register_craftitem('x_bows:' .. name, {
		description = def.description .. '\n' .. minetest.colorize('#00FF00', 'Damage: ' .. def.tool_capabilities.damage_groups.fleshy) .. '\n' .. minetest.colorize('#00BFFF', 'Charge Time: ' .. def.tool_capabilities.full_punch_interval .. 's'),
		inventory_image = def.inventory_image,
		groups = {arrow = 1, flammable = 1}
	})

	-- recipes
	if def.craft then
		minetest.register_craft({
			output = def.name ..' ' .. (def.craft_count or 4),
			recipe = def.craft
		})
	end
end

function x_bows.load(itemstack, user, pointed_thing)
	local time_load = minetest.get_us_time()
	local inv = user:get_inventory()
	local inv_list = inv:get_list('main')
	local bow_name = itemstack:get_name()
	local bow_def = x_bows.registered_bows[bow_name .. '_charged']
	local itemstack_arrows = {}

	if pointed_thing.under then
		local node = minetest.get_node(pointed_thing.under)
		local node_def = minetest.registered_nodes[node.name]

		if node_def and node_def.on_rightclick then
			return node_def.on_rightclick(pointed_thing.under, node, user, itemstack, pointed_thing)
		end
	end

	for k, st in ipairs(inv_list) do
		if not st:is_empty() and x_bows.registered_arrows[st:get_name()] then
			table.insert(itemstack_arrows, st)
		end
	end

	-- take 1st found arrow in the list
	local itemstack_arrow = itemstack_arrows[1]

	if itemstack_arrow and bow_def then
		local _tool_capabilities = x_bows.registered_arrows[itemstack_arrow:get_name()].tool_capabilities

		minetest.after(0, function(v_user, v_bow_name, v_time_load)
			local wielded_item = v_user:get_wielded_item()
			local wielded_item_name = wielded_item:get_name()

			if wielded_item_name == v_bow_name then
				local meta = wielded_item:get_meta()

				meta:set_string('arrow', itemstack_arrow:get_name())
				meta:set_string('time_load', tostring(v_time_load))
				wielded_item:set_name(v_bow_name .. '_charged')
				v_user:set_wielded_item(wielded_item)

				if not x_bows.is_creative(user:get_player_name()) then
					inv:remove_item('main', itemstack_arrow:get_name())
				end
			end
		end, user, bow_name, time_load)

		-- sound plays when charge time reaches full punch interval time
		-- @TODO: find a way to prevent this from playing when not fully charged
		minetest.after(_tool_capabilities.full_punch_interval, function(v_user, v_bow_name)
			local wielded_item = v_user:get_wielded_item()
			local wielded_item_name = wielded_item:get_name()

			if wielded_item_name == v_bow_name .. '_charged' then
				minetest.sound_play('x_bows_bow_loaded', {
					to_player = user:get_player_name(),
					gain = 0.6
				})
			end
		end, user, bow_name)

		minetest.sound_play('x_bows_bow_load', {
			to_player = user:get_player_name(),
			gain = 0.6
		})

		return itemstack
	end
end

function x_bows.shoot(itemstack, user, pointed_thing)
	local time_shoot = minetest.get_us_time();
	local meta = itemstack:get_meta()
	local meta_arrow = meta:get_string('arrow')
	local time_load = tonumber(meta:get_string('time_load'))
	local tflp = (time_shoot - time_load) / 1000000

	if not x_bows.registered_arrows[meta_arrow] then
		return itemstack
	end

	local bow_name_charged = itemstack:get_name()
	local bow_name = x_bows.registered_bows[bow_name_charged].name
	local uses = x_bows.registered_bows[bow_name_charged].uses
	local crit_chance = x_bows.registered_bows[bow_name_charged].crit_chance
	local _tool_capabilities = x_bows.registered_arrows[meta_arrow].tool_capabilities

	local staticdata = {
		arrow = meta_arrow,
		user_name = user:get_player_name(),
		is_critical_hit = false,
		_tool_capabilities = _tool_capabilities,
		_tflp = tflp,
	}

	-- crits, only on full punch interval
	if crit_chance and crit_chance > 1 and tflp >= _tool_capabilities.full_punch_interval then
		if math.random(1, crit_chance) == 1 then
			staticdata.is_critical_hit = true
		end
	end

	local sound_name = 'x_bows_bow_shoot'
	if staticdata.is_critical_hit then
		sound_name = 'x_bows_bow_shoot_crit'
	end

	meta:set_string('arrow', '')
	itemstack:set_name(bow_name)

	local pos = user:get_pos()
	local dir = user:get_look_dir()
	local obj = minetest.add_entity({x = pos.x, y = pos.y + 1.5, z = pos.z}, 'x_bows:arrow_entity', minetest.serialize(staticdata))

	if not obj then
		return itemstack
	end

	local lua_ent = obj:get_luaentity()
	local strength_multiplier = tflp

	if strength_multiplier > _tool_capabilities.full_punch_interval then
		strength_multiplier = 1
	end

	local strength = 30 * strength_multiplier

	obj:set_velocity(vector.multiply(dir, strength))
	obj:set_acceleration({x = dir.x * -3, y = -10, z = dir.z * -3})
	obj:set_yaw(minetest.dir_to_yaw(dir))

	if not x_bows.is_creative(user:get_player_name()) then
		itemstack:add_wear(65535 / uses)
	end

	minetest.sound_play(sound_name, {
		gain = 0.3,
		pos = user:get_pos(),
		max_hear_distance = 10
	})

	return itemstack
end

function x_bows.particle_effect(pos, type)
	if type == 'arrow' then
		return minetest.add_particlespawner({
			amount = 1,
			time = 0.1,
			minpos = pos,
			maxpos = pos,
			minexptime = 1,
			maxexptime = 1,
			minsize = 2,
			maxsize = 2,
			texture = 'x_bows_arrow_particle.png',
			animation = {
				type = 'vertical_frames',
				aspect_w = 8,
				aspect_h = 8,
				length = 1,
			},
			glow = 1
		})
	elseif type == 'arrow_crit' then
		return minetest.add_particlespawner({
			amount = 3,
			time = 0.1,
			minpos = pos,
			maxpos = pos,
			minexptime = 0.5,
			maxexptime = 0.5,
			minsize = 2,
			maxsize = 2,
			texture = 'x_bows_arrow_particle.png^[colorize:#B22222:127',
			animation = {
				type = 'vertical_frames',
				aspect_w = 8,
				aspect_h = 8,
				length = 1,
			},
			glow = 1
		})
	elseif type == 'bubble' then
		return minetest.add_particlespawner({
			amount = 1,
			time = 1,
			minpos = pos,
			maxpos = pos,
			minvel = {x=1, y=1, z=0},
			maxvel = {x=1, y=1, z=0},
			minacc = {x=1, y=1, z=1},
			maxacc = {x=1, y=1, z=1},
			minexptime = 0.2,
			maxexptime = 0.5,
			minsize = 0.5,
			maxsize = 1,
			texture = 'x_bows_bubble.png'
		})
	elseif type == 'arrow_tipped' then
		return minetest.add_particlespawner({
			amount = 5,
			time = 1,
			minpos = vector.subtract(pos, 0.5),
			maxpos = vector.add(pos, 0.5),
			minexptime = 0.4,
			maxexptime = 0.8,
			minvel = {x=-0.4, y=0.4, z=-0.4},
			maxvel = {x=0.4, y=0.6, z=0.4},
			minacc = {x=0.2, y=0.4, z=0.2},
			maxacc = {x=0.4, y=0.6, z=0.4},
			minsize = 4,
			maxsize = 6,
			texture = 'x_bows_arrow_tipped_particle.png^[colorize:#008000:127',
			animation = {
				type = 'vertical_frames',
				aspect_w = 8,
				aspect_h = 8,
				length = 1,
			},
			glow = 1
		})
	end
end

-- sneak, fov adjustments when bow is charged
minetest.register_globalstep(function(dtime)
	bow_charged_timer = bow_charged_timer + dtime

	if bow_charged_timer > 0.5 then
		for _, player in ipairs(minetest.get_connected_players()) do
			local name = player:get_player_name()
			local stack = player:get_wielded_item()
			local item = stack:get_name()

			if not item then
				return
			end

			if not x_bows.player_bow_sneak[name] then
				x_bows.player_bow_sneak[name] = {}
			end

			if item == 'x_bows:bow_wood_charged' and not x_bows.player_bow_sneak[name].sneak then
				if minetest.get_modpath('playerphysics') then
					playerphysics.add_physics_factor(player, 'speed', 'x_bows:bow_wood_charged', 0.25)
				end

				x_bows.player_bow_sneak[name].sneak = true
				player:set_fov(0.9, true, 0.4)
			elseif item ~= 'x_bows:bow_wood_charged' and x_bows.player_bow_sneak[name].sneak then
				if minetest.get_modpath('playerphysics') then
					playerphysics.remove_physics_factor(player, 'speed', 'x_bows:bow_wood_charged')
				end

				x_bows.player_bow_sneak[name].sneak = false
				player:set_fov(1, true, 0.4)
			end
		end

		bow_charged_timer = 0
	end
end)

local path = minetest.get_modpath('x_bows')

dofile(path .. '/nodes.lua')
dofile(path .. '/arrow.lua')
dofile(path .. '/items.lua')

local mod_end_time = (minetest.get_us_time() - mod_start_time) / 1000000

print('[Mod] x_bows loaded.. ['.. mod_end_time ..'s]')
