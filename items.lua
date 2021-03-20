x_bows.register_bow('bow_wood', {
	description = 'Wooden Bow',
	uses = 385,
	-- `crit_chance` 10% chance, 5 is 20% chance
	-- (1 / crit_chance) * 100 = % chance
	crit_chance = 10,
	recipe = {
		{'', 'default:stick', 'farming:string'},
		{'default:stick', '', 'farming:string'},
		{'', 'default:stick', 'farming:string'},
	}
})

x_bows.register_arrow('arrow_wood', {
	description = 'Arrow Wood',
	inventory_image = 'x_bows_arrow_wood.png',
	craft = {
		{'default:flint'},
		{'group:stick'},
		{'group:wool'}
	},
	tool_capabilities = {
		full_punch_interval = 1,
		max_drop_level = 0,
		damage_groups = {fleshy=2}
	}
})

x_bows.register_arrow('arrow_stone', {
	description = 'Arrow Stone',
	inventory_image = 'x_bows_arrow_stone.png',
	craft = {
		{'default:flint'},
		{'group:stone'},
		{'group:wool'}
	},
	tool_capabilities = {
		full_punch_interval = 1.2,
		max_drop_level = 0,
		damage_groups = {fleshy=4}
	}
})

x_bows.register_arrow('arrow_bronze', {
	description = 'Arrow Bronze',
	inventory_image = 'x_bows_arrow_bronze.png',
	craft = {
		{'default:flint'},
		{'default:bronze_ingot'},
		{'group:wool'}
	},
	tool_capabilities = {
		full_punch_interval = 0.8,
		max_drop_level = 1,
		damage_groups = {fleshy=6}
	}
})

x_bows.register_arrow('arrow_steel', {
	description = 'Arrow Steel',
	inventory_image = 'x_bows_arrow_steel.png',
	craft = {
		{'default:flint'},
		{'default:steel_ingot'},
		{'group:wool'}
	},
	tool_capabilities = {
		full_punch_interval = 0.7,
		max_drop_level = 1,
		damage_groups = {fleshy=6}
	}
})

x_bows.register_arrow('arrow_mese', {
	description = 'Arrow Mese',
	inventory_image = 'x_bows_arrow_mese.png',
	craft = {
		{'default:flint'},
		{'default:mese_crystal'},
		{'group:wool'}
	},
	tool_capabilities = {
		full_punch_interval = 0.7,
		max_drop_level = 1,
		damage_groups = {fleshy=7}
	}
})

x_bows.register_arrow('arrow_diamond', {
	description = 'Arrow Diamond',
	inventory_image = 'x_bows_arrow_diamond.png',
	craft = {
		{'default:flint'},
		{'default:diamond'},
		{'group:wool'}
	},
	tool_capabilities = {
		full_punch_interval = 0.7,
		max_drop_level = 1,
		damage_groups = {fleshy=8}
	}
})

x_bows.register_arrow('arrow_diamond_tipped_poison', {
	description = 'Arrow Diamond Tipped Poison (0:05)',
	inventory_image = 'x_bows_arrow_diamond_poison.png',
	craft = {
		{'', '', ''},
		{'', 'default:marram_grass_1', ''},
		{'', 'x_bows:arrow_diamond', ''}
	},
	tool_capabilities = {
		full_punch_interval = 0.7,
		max_drop_level = 1,
		damage_groups = {fleshy=8}
	},
	craft_count = 1
})

minetest.register_craft({
	type = 'fuel',
	recipe = 'x_bows:bow_wood',
	burntime = 3,
})

minetest.register_craft({
	type = 'fuel',
	recipe = 'x_bows:arrow_wood',
	burntime = 1,
})
