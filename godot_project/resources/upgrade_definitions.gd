extends RefCounted
class_name UpgradeDefinitions
## UpgradeDefinitions - Static data for all upgrades and abilities
## Used by ProgressionManager to calculate costs and effects

# ============ UPGRADE DEFINITIONS ============

const UPGRADES: Dictionary = {
	"scoring": {
		"point_boost": {
			"name": "Point Boost",
			"description": "Increases base points earned from all matches",
			"max_level": 20,
			"cost_base": 50,
			"cost_type": "slime_essence",
			"effect_per_level": 0.05,
			"effect_description": "+5% base points"
		},
		"color_mastery_red": {
			"name": "Red Mastery",
			"description": "Increases points earned from red slime matches",
			"max_level": 10,
			"cost_base": 100,
			"cost_type": "slime_essence",
			"effect_per_level": 0.10,
			"effect_description": "+10% red points"
		},
		"color_mastery_orange": {
			"name": "Orange Mastery",
			"description": "Increases points earned from orange slime matches",
			"max_level": 10,
			"cost_base": 100,
			"cost_type": "slime_essence",
			"effect_per_level": 0.10,
			"effect_description": "+10% orange points"
		},
		"color_mastery_yellow": {
			"name": "Yellow Mastery",
			"description": "Increases points earned from yellow slime matches",
			"max_level": 10,
			"cost_base": 100,
			"cost_type": "slime_essence",
			"effect_per_level": 0.10,
			"effect_description": "+10% yellow points"
		},
		"color_mastery_green": {
			"name": "Green Mastery",
			"description": "Increases points earned from green slime matches",
			"max_level": 10,
			"cost_base": 100,
			"cost_type": "slime_essence",
			"effect_per_level": 0.10,
			"effect_description": "+10% green points"
		},
		"color_mastery_blue": {
			"name": "Blue Mastery",
			"description": "Increases points earned from blue slime matches",
			"max_level": 10,
			"cost_base": 100,
			"cost_type": "slime_essence",
			"effect_per_level": 0.10,
			"effect_description": "+10% blue points"
		},
		"color_mastery_purple": {
			"name": "Purple Mastery",
			"description": "Increases points earned from purple slime matches",
			"max_level": 10,
			"cost_base": 100,
			"cost_type": "slime_essence",
			"effect_per_level": 0.10,
			"effect_description": "+10% purple points"
		},
		"match_4_bonus": {
			"name": "Match-4 Expert",
			"description": "Increases bonus points from 4-match combos",
			"max_level": 10,
			"cost_base": 75,
			"cost_type": "slime_essence",
			"effect_per_level": 0.08,
			"effect_description": "+8% Match-4 points"
		},
		"match_5_bonus": {
			"name": "Match-5 Expert",
			"description": "Increases bonus points from 5+ match combos",
			"max_level": 10,
			"cost_base": 100,
			"cost_type": "slime_essence",
			"effect_per_level": 0.10,
			"effect_description": "+10% Match-5+ points"
		},
		"special_bonus": {
			"name": "Special Activator",
			"description": "Increases points when special slimes activate",
			"max_level": 10,
			"cost_base": 150,
			"cost_type": "slime_essence",
			"effect_per_level": 0.15,
			"effect_description": "+15% special activation points"
		}
	},
	"moves": {
		"starting_moves": {
			"name": "Extra Moves",
			"description": "Start each level with additional moves",
			"max_level": 10,
			"cost_base": 200,
			"cost_type": "slime_essence",
			"effect_per_level": 1,
			"effect_description": "+1 starting move"
		},
		"move_saver": {
			"name": "Move Saver",
			"description": "Chance to not consume a move on successful match",
			"max_level": 5,
			"cost_base": 300,
			"cost_type": "slime_essence",
			"effect_per_level": 0.05,
			"effect_description": "+5% chance to save move"
		},
		"emergency_moves": {
			"name": "Emergency Reserve",
			"description": "Gain emergency moves when reaching 0 moves",
			"max_level": 3,
			"cost_base": 1000,
			"cost_type": "slime_essence",
			"effect_per_level": 1,
			"effect_description": "+1 emergency move"
		}
	},
	"specials": {
		"striped_chance": {
			"name": "Striped Luck",
			"description": "Increases chance for Match-4 to create striped slimes",
			"max_level": 10,
			"cost_base": 80,
			"cost_type": "slime_essence",
			"effect_per_level": 0.03,
			"effect_description": "+3% striped chance"
		},
		"wrapped_chance": {
			"name": "Wrapped Luck",
			"description": "Increases chance for L/T shapes to create wrapped slimes",
			"max_level": 10,
			"cost_base": 100,
			"cost_type": "slime_essence",
			"effect_per_level": 0.03,
			"effect_description": "+3% wrapped chance"
		},
		"color_bomb_chance": {
			"name": "Color Bomb Luck",
			"description": "Increases chance for Match-5 to create color bombs",
			"max_level": 5,
			"cost_base": 200,
			"cost_type": "slime_essence",
			"effect_per_level": 0.02,
			"effect_description": "+2% color bomb chance"
		},
		"striped_power": {
			"name": "Striped Power",
			"description": "Striped slimes clear additional rows/columns",
			"max_level": 5,
			"cost_base": 50,
			"cost_type": "star_dust",
			"effect_per_level": 1,
			"effect_description": "+1 row/column cleared"
		},
		"wrapped_power": {
			"name": "Wrapped Power",
			"description": "Wrapped slimes have larger explosion radius",
			"max_level": 5,
			"cost_base": 60,
			"cost_type": "star_dust",
			"effect_per_level": 1,
			"effect_description": "+1 explosion radius"
		}
	},
	"combos": {
		"combo_multiplier": {
			"name": "Combo Master",
			"description": "Increases the combo multiplier base value",
			"max_level": 10,
			"cost_base": 100,
			"cost_type": "slime_essence",
			"effect_per_level": 0.1,
			"effect_description": "+0.1 combo multiplier"
		},
		"cascade_boost": {
			"name": "Cascade Boost",
			"description": "Increases points earned per cascade step",
			"max_level": 10,
			"cost_base": 150,
			"cost_type": "slime_essence",
			"effect_per_level": 0.05,
			"effect_description": "+5% per cascade"
		},
		"chain_reaction": {
			"name": "Chain Reaction",
			"description": "Chance for cascades to trigger extra matches",
			"max_level": 5,
			"cost_base": 400,
			"cost_type": "slime_essence",
			"effect_per_level": 0.03,
			"effect_description": "+3% extra match chance"
		}
	}
}

# ============ ABILITY DEFINITIONS ============

const ABILITIES: Dictionary = {
	"slime_swap": {
		"name": "Slime Swap",
		"description": "Swap any two slimes on the board, regardless of position",
		"unlock_cost": 20,
		"upgrade_cost": 15,
		"base_uses": 1,
		"upgrade_uses": 1,
		"max_level": 2
	},
	"color_burst": {
		"name": "Color Burst",
		"description": "Destroy all slimes of a chosen color",
		"unlock_cost": 35,
		"upgrade_cost": 25,
		"base_uses": 1,
		"upgrade_uses": 1,
		"max_level": 1
	},
	"row_sweep": {
		"name": "Row Sweep",
		"description": "Clear an entire row of your choice",
		"unlock_cost": 25,
		"upgrade_cost": 20,
		"base_uses": 1,
		"upgrade_uses": 1,
		"max_level": 2
	},
	"column_sweep": {
		"name": "Column Sweep",
		"description": "Clear an entire column of your choice",
		"unlock_cost": 25,
		"upgrade_cost": 20,
		"base_uses": 1,
		"upgrade_uses": 1,
		"max_level": 2
	},
	"shuffle_plus": {
		"name": "Shuffle Plus",
		"description": "Shuffle the board without using a limited shuffle",
		"unlock_cost": 15,
		"upgrade_cost": 10,
		"base_uses": 2,
		"upgrade_uses": 1,
		"max_level": 3
	},
	"time_freeze": {
		"name": "Time Freeze",
		"description": "Your next 3 matches don't consume moves",
		"unlock_cost": 50,
		"upgrade_cost": 0,
		"base_uses": 1,
		"upgrade_uses": 0,
		"max_level": 0
	},
	"color_transform": {
		"name": "Color Transform",
		"description": "Change all slimes of one color to another color",
		"unlock_cost": 40,
		"upgrade_cost": 30,
		"base_uses": 1,
		"upgrade_uses": 1,
		"max_level": 1
	},
	"special_spawner": {
		"name": "Special Spawner",
		"description": "Spawn a random special slime on a random position",
		"unlock_cost": 60,
		"upgrade_cost": 0,
		"base_uses": 1,
		"upgrade_uses": 0,
		"max_level": 0
	}
}

# ============ COLOR MASTERY COSTS ============

# Cost in color crystals per level
const COLOR_MASTERY_COSTS: Array[int] = [10, 25, 50, 100, 200]

# ============ STATIC HELPER FUNCTIONS ============

static func get_upgrade(category: String, upgrade_id: String) -> Dictionary:
	if UPGRADES.has(category) and UPGRADES[category].has(upgrade_id):
		return UPGRADES[category][upgrade_id]
	return {}


static func get_ability(ability_id: String) -> Dictionary:
	if ABILITIES.has(ability_id):
		return ABILITIES[ability_id]
	return {}


static func get_color_mastery_cost(level: int) -> int:
	if level >= 1 and level <= 5:
		return COLOR_MASTERY_COSTS[level - 1]
	return 0


static func get_all_upgrades_in_category(category: String) -> Array:
	if UPGRADES.has(category):
		return UPGRADES[category].keys()
	return []


static func get_all_categories() -> Array:
	return UPGRADES.keys()


static func get_all_abilities() -> Array:
	return ABILITIES.keys()


static func calculate_upgrade_cost(category: String, upgrade_id: String, current_level: int) -> int:
	var definition = get_upgrade(category, upgrade_id)
	if definition.is_empty():
		return 0
	return definition.cost_base * (current_level + 1)


static func calculate_ability_upgrade_cost(ability_id: String, current_level: int) -> int:
	var definition = get_ability(ability_id)
	if definition.is_empty():
		return 0
	return definition.upgrade_cost * (current_level + 1)


static func is_upgrade_maxed(category: String, upgrade_id: String, current_level: int) -> bool:
	var definition = get_upgrade(category, upgrade_id)
	if definition.is_empty():
		return true
	return current_level >= definition.max_level


static func is_ability_maxed(ability_id: String, current_level: int) -> bool:
	var definition = get_ability(ability_id)
	if definition.is_empty():
		return true
	return current_level >= definition.max_level


static func get_upgrade_effect_text(category: String, upgrade_id: String, level: int) -> String:
	var definition = get_upgrade(category, upgrade_id)
	if definition.is_empty():
		return ""

	var effect = definition.effect_per_level * level
	if effect < 1.0:
		return "%+d%%" % int(effect * 100)
	else:
		return "%+d" % int(effect)


static func get_ability_uses_text(ability_id: String, level: int) -> String:
	var definition = get_ability(ability_id)
	if definition.is_empty():
		return ""

	var uses = definition.base_uses + (definition.upgrade_uses * level)
	return "%d use(s) per game" % uses
