extends Node
## ProgressionManager - Story Mode Incremental Progression System
## Handles currencies, upgrades, abilities, color mastery, and campaign progress

# Preload the upgrade definitions
const UpgradeDefs = preload("res://resources/upgrade_definitions.gd")

# Signals for UI updates
signal currencies_changed(currencies: Dictionary)
signal currency_changed(currency: String, new_amount: int)
signal upgrade_purchased(category: String, upgrade_id: String, new_level: int)
signal ability_unlocked(ability_id: String)
signal ability_upgraded(ability_id: String, new_level: int)
signal ability_used(ability_id: String, remaining: int)
signal color_mastery_upgraded(color: String, new_level: int)
signal campaign_progress_changed(chapter: int, level: int)

# ============ CURRENCIES ============

var currencies: Dictionary = {
	"slime_essence": 0,
	"star_dust": 0,
	"color_crystals": {
		"red": 0,
		"orange": 0,
		"yellow": 0,
		"green": 0,
		"blue": 0,
		"purple": 0
	}
}

# ============ UPGRADES ============

# Upgrade levels by category (category -> upgrade_id -> level)
var upgrades: Dictionary = {
	"scoring": {
		"point_boost": 0,
		"color_mastery_red": 0,
		"color_mastery_orange": 0,
		"color_mastery_yellow": 0,
		"color_mastery_green": 0,
		"color_mastery_blue": 0,
		"color_mastery_purple": 0,
		"match_4_bonus": 0,
		"match_5_bonus": 0,
		"special_bonus": 0
	},
	"moves": {
		"starting_moves": 0,
		"move_saver": 0,
		"emergency_moves": 0
	},
	"specials": {
		"striped_chance": 0,
		"wrapped_chance": 0,
		"color_bomb_chance": 0,
		"striped_power": 0,
		"wrapped_power": 0
	},
	"combos": {
		"combo_multiplier": 0,
		"cascade_boost": 0,
		"chain_reaction": 0
	}
}

# ============ ABILITIES ============

# Active abilities (ability_id -> {unlocked, level})
var abilities: Dictionary = {
	"slime_swap": {"unlocked": false, "level": 0},
	"color_burst": {"unlocked": false, "level": 0},
	"row_sweep": {"unlocked": false, "level": 0},
	"column_sweep": {"unlocked": false, "level": 0},
	"shuffle_plus": {"unlocked": false, "level": 0},
	"time_freeze": {"unlocked": false, "level": 0},
	"color_transform": {"unlocked": false, "level": 0},
	"special_spawner": {"unlocked": false, "level": 0}
}

# ============ COLOR MASTERY ============

# Color mastery levels (separate from scoring upgrades, uses color crystals)
var color_mastery: Dictionary = {
	"red": 0,
	"orange": 0,
	"yellow": 0,
	"green": 0,
	"blue": 0,
	"purple": 0
}

# ============ SKILL TREE ============

# Skill tree node levels (node_id -> level)
var skill_tree_nodes: Dictionary = {}

# ============ CAMPAIGN ============

var campaign: Dictionary = {
	"current_chapter": 1,
	"current_level": 1,
	"completed_levels": [],  # Array of "chapter-level" strings like "1-1", "1-2"
	"level_stars": {}  # Dictionary of "chapter-level": stars (1-3)
}

# ============ PER-GAME STATE ============

# Reset at the start of each level
var game_state: Dictionary = {
	"ability_uses": {},  # ability_id -> remaining uses this game
	"score_streak": 0,  # Consecutive matches without move waste
	"time_freeze_moves": 0,  # Moves that don't consume (from Time Freeze)
	"cascade_count": 0,  # Current cascade depth
	"emergency_moves_used": false  # Whether emergency moves were triggered
}


func _ready() -> void:
	# Load progression data if in story mode
	if SaveManager.active_mode == SaveManager.MODE_STORY:
		load_progression()


# ============ CURRENCY FUNCTIONS ============

func add_currency(currency_type: String, amount: int) -> void:
	if currency_type == "slime_essence":
		currencies.slime_essence += amount
		currency_changed.emit("slime_essence", currencies.slime_essence)
	elif currency_type == "star_dust":
		currencies.star_dust += amount
		currency_changed.emit("star_dust", currencies.star_dust)
	currencies_changed.emit(currencies)
	save_progression()


func add_color_crystal(color: String, amount: int = 1) -> void:
	if currencies.color_crystals.has(color):
		currencies.color_crystals[color] += amount
		currencies_changed.emit(currencies)
		save_progression()


func get_currency(currency_type: String) -> int:
	if currency_type == "slime_essence":
		return currencies.slime_essence
	elif currency_type == "star_dust":
		return currencies.star_dust
	return 0


func get_color_crystal(color: String) -> int:
	return currencies.color_crystals.get(color, 0)


func spend_currency(currency_type: String, amount: int) -> bool:
	var current = get_currency(currency_type)
	if current >= amount:
		if currency_type == "slime_essence":
			currencies.slime_essence -= amount
		elif currency_type == "star_dust":
			currencies.star_dust -= amount
		currencies_changed.emit(currencies)
		save_progression()
		return true
	return false


func spend_color_crystal(color: String, amount: int) -> bool:
	if currencies.color_crystals.get(color, 0) >= amount:
		currencies.color_crystals[color] -= amount
		currencies_changed.emit(currencies)
		save_progression()
		return true
	return false


# ============ UPGRADE FUNCTIONS ============

func get_upgrade_level(category: String, upgrade_id: String) -> int:
	if upgrades.has(category) and upgrades[category].has(upgrade_id):
		return upgrades[category][upgrade_id]
	return 0


func purchase_upgrade(category: String, upgrade_id: String) -> bool:
	var current_level = get_upgrade_level(category, upgrade_id)
	var definition = UpgradeDefs.get_upgrade(category, upgrade_id)

	if definition.is_empty():
		return false

	if current_level >= definition.max_level:
		return false  # Already maxed

	var cost = definition.cost_base * (current_level + 1)
	var cost_type = definition.cost_type

	if cost_type == "slime_essence" or cost_type == "star_dust":
		if spend_currency(cost_type, cost):
			upgrades[category][upgrade_id] = current_level + 1
			upgrade_purchased.emit(category, upgrade_id, current_level + 1)
			save_progression()
			return true

	return false


func get_upgrade_cost(category: String, upgrade_id: String) -> int:
	var current_level = get_upgrade_level(category, upgrade_id)
	var definition = UpgradeDefs.get_upgrade(category, upgrade_id)
	if definition.is_empty():
		return 0
	return definition.cost_base * (current_level + 1)


func can_afford_upgrade(category: String, upgrade_id: String) -> bool:
	var definition = UpgradeDefs.get_upgrade(category, upgrade_id)
	if definition.is_empty():
		return false

	var current_level = get_upgrade_level(category, upgrade_id)
	if current_level >= definition.max_level:
		return false

	var cost = definition.cost_base * (current_level + 1)
	var cost_type = definition.cost_type

	if cost_type == "slime_essence":
		return currencies.slime_essence >= cost
	elif cost_type == "star_dust":
		return currencies.star_dust >= cost

	return false


# ============ SKILL TREE HELPERS ============

func get_skill_node_level(node_id: String) -> int:
	return skill_tree_nodes.get(node_id, 0)


func _sum_skill_effect(node_ids: Array, effect_per_level: float) -> float:
	var total: float = 0.0
	for node_id in node_ids:
		total += get_skill_node_level(node_id) * effect_per_level
	return total


# ============ UPGRADE EFFECT GETTERS (from Skill Tree) ============

func get_score_multiplier() -> float:
	# Sum all point boost nodes
	var bonus: float = 0.0
	bonus += get_skill_node_level("point_boost_1") * 0.05
	bonus += get_skill_node_level("point_boost_2") * 0.08
	bonus += get_skill_node_level("point_boost_3") * 0.12
	return 1.0 + bonus


func get_match_4_bonus() -> float:
	var level = get_skill_node_level("match4_bonus")
	return 1.0 + (level * 0.10)  # +10% per level


func get_match_5_bonus() -> float:
	var level = get_skill_node_level("match5_bonus")
	return 1.0 + (level * 0.15)  # +15% per level


func get_special_activation_bonus() -> float:
	var level = get_skill_node_level("special_score_bonus")
	return 1.0 + (level * 0.20)  # +20% per level


func get_color_score_bonus(color: String) -> float:
	var node_id = color + "_mastery"
	var level = get_skill_node_level(node_id)
	var bonus = level * 0.15  # +15% per level

	# Add all_color_multiplier bonus
	bonus += get_skill_node_level("color_master") * 0.05

	return 1.0 + bonus


func get_bonus_starting_moves() -> int:
	var total: int = 0
	total += get_skill_node_level("starting_moves_1") * 1
	total += get_skill_node_level("starting_moves_2") * 2
	total += get_skill_node_level("starting_moves_3") * 3
	return total


func get_move_saver_chance() -> float:
	var level = get_skill_node_level("move_saver")
	return level * 0.05  # +5% chance per level


func get_emergency_moves() -> int:
	return get_skill_node_level("emergency_reserve")  # +1 per level


func get_striped_chance_bonus() -> float:
	var bonus: float = 0.0
	bonus += get_skill_node_level("striped_chance_1") * 0.04
	bonus += get_skill_node_level("striped_chance_2") * 0.06
	return bonus


func get_wrapped_chance_bonus() -> float:
	var bonus: float = 0.0
	bonus += get_skill_node_level("wrapped_chance_1") * 0.04
	bonus += get_skill_node_level("wrapped_chance_2") * 0.06
	return bonus


func get_color_bomb_chance_bonus() -> float:
	var level = get_skill_node_level("colorbomb_chance")
	return level * 0.03  # +3% per level


func get_striped_power_bonus() -> int:
	return get_skill_node_level("striped_power")  # +1 row/col per level


func get_wrapped_power_bonus() -> int:
	return get_skill_node_level("wrapped_power")  # +1 radius per level


func get_combo_multiplier_bonus() -> float:
	var bonus: float = 0.0
	bonus += get_skill_node_level("combo_base") * 0.1
	bonus += get_skill_node_level("combo_master") * 0.15
	bonus += get_skill_node_level("combo_legend") * 0.2
	return bonus


func get_cascade_boost() -> float:
	var level = get_skill_node_level("cascade_boost")
	return 1.0 + (level * 0.08)  # +8% per cascade per level


func get_chain_reaction_chance() -> float:
	var level = get_skill_node_level("chain_reaction")
	return level * 0.03  # +3% per level


func has_colorbomb_creates_striped() -> bool:
	return get_skill_node_level("colorbomb_power") > 0


# ============ ABILITY FUNCTIONS ============

func is_ability_unlocked(ability_id: String) -> bool:
	return abilities.get(ability_id, {}).get("unlocked", false)


func get_ability_level(ability_id: String) -> int:
	return abilities.get(ability_id, {}).get("level", 0)


func unlock_ability(ability_id: String) -> bool:
	var definition = UpgradeDefs.get_ability(ability_id)
	if definition.is_empty():
		return false

	if is_ability_unlocked(ability_id):
		return false  # Already unlocked

	var cost = definition.unlock_cost
	if spend_currency("star_dust", cost):
		abilities[ability_id].unlocked = true
		ability_unlocked.emit(ability_id)
		save_progression()
		return true

	return false


func upgrade_ability(ability_id: String) -> bool:
	if not is_ability_unlocked(ability_id):
		return false

	var definition = UpgradeDefs.get_ability(ability_id)
	if definition.is_empty():
		return false

	var current_level = get_ability_level(ability_id)
	if current_level >= definition.max_level:
		return false  # Already maxed

	# Ability upgrades cost star dust (increasing per level)
	var cost = definition.upgrade_cost * (current_level + 1)
	if spend_currency("star_dust", cost):
		abilities[ability_id].level = current_level + 1
		save_progression()
		return true

	return false


func get_ability_uses_per_game(ability_id: String) -> int:
	var definition = UpgradeDefs.get_ability(ability_id)
	if definition.is_empty():
		return 0

	var base_uses = definition.base_uses
	var upgrade_uses = definition.upgrade_uses * get_ability_level(ability_id)
	return base_uses + upgrade_uses


func init_game_abilities() -> void:
	# Initialize ability uses for a new game
	game_state.ability_uses.clear()
	for ability_id in abilities.keys():
		if is_ability_unlocked(ability_id):
			game_state.ability_uses[ability_id] = get_ability_uses_per_game(ability_id)


func use_ability(ability_id: String) -> bool:
	var remaining = game_state.ability_uses.get(ability_id, 0)
	if remaining > 0:
		game_state.ability_uses[ability_id] = remaining - 1
		ability_used.emit(ability_id, remaining - 1)
		return true
	return false


func get_ability_remaining_uses(ability_id: String) -> int:
	return game_state.ability_uses.get(ability_id, 0)


# ============ COLOR MASTERY FUNCTIONS ============

func get_color_mastery_level(color: String) -> int:
	return color_mastery.get(color, 0)


func upgrade_color_mastery(color: String) -> bool:
	var current_level = get_color_mastery_level(color)
	var cost = UpgradeDefs.get_color_mastery_cost(current_level + 1)

	if current_level >= 5:
		return false  # Max level is 5

	if spend_color_crystal(color, cost):
		color_mastery[color] = current_level + 1
		color_mastery_upgraded.emit(color, current_level + 1)
		save_progression()
		return true

	return false


func purchase_color_mastery(color: String) -> bool:
	# Alias for upgrade_color_mastery for consistent naming
	return upgrade_color_mastery(color)


func get_color_mastery_point_bonus(color: String) -> float:
	var level = get_color_mastery_level(color)
	if level >= 1:
		return 0.10  # +10% points at level 1+
	return 0.0


func get_color_mastery_essence_bonus(color: String) -> float:
	var level = get_color_mastery_level(color)
	if level >= 2:
		return 0.05  # +5% essence at level 2+
	return 0.0


func get_color_mastery_match_upgrade_chance(color: String) -> float:
	var level = get_color_mastery_level(color)
	if level >= 3:
		return 0.05  # 5% Match-3 -> Match-4 at level 3+
	return 0.0


func get_color_mastery_special_bonus(color: String) -> float:
	var level = get_color_mastery_level(color)
	if level >= 4:
		return 0.25  # +25% special damage at level 4+
	return 0.0


func get_color_mastery_spawn_bonus(color: String) -> float:
	var level = get_color_mastery_level(color)
	if level >= 5:
		return 0.05  # +5% spawn chance at level 5
	return 0.0


# ============ CAMPAIGN FUNCTIONS ============

func get_current_chapter() -> int:
	return campaign.current_chapter


func get_current_level() -> int:
	return campaign.current_level


func set_current_level(chapter: int, level: int) -> void:
	campaign.current_chapter = chapter
	campaign.current_level = level
	campaign_progress_changed.emit(chapter, level)
	save_progression()


func is_level_completed(chapter: int, level: int) -> bool:
	var key = "%d-%d" % [chapter, level]
	return key in campaign.completed_levels


func get_level_stars(chapter: int, level: int) -> int:
	var key = "%d-%d" % [chapter, level]
	return campaign.level_stars.get(key, 0)


func complete_level(chapter: int, level: int, stars: int, is_first_time: bool) -> Dictionary:
	var key = "%d-%d" % [chapter, level]
	var previous_stars = get_level_stars(chapter, level)

	# Update stars if better
	if stars > previous_stars:
		campaign.level_stars[key] = stars

	# Mark as completed
	if key not in campaign.completed_levels:
		campaign.completed_levels.append(key)

	# Calculate rewards
	var rewards = {
		"star_dust": 0,
		"first_time_bonus": 0
	}

	# Star dust based on stars
	match stars:
		1: rewards.star_dust = 1
		2: rewards.star_dust = 3
		3: rewards.star_dust = 5

	# First time bonus
	if is_first_time:
		rewards.first_time_bonus = 3
		rewards.star_dust += rewards.first_time_bonus

	# Award star dust
	add_currency("star_dust", rewards.star_dust)

	save_progression()
	return rewards


func is_chapter_unlocked(chapter: int) -> bool:
	if chapter == 1:
		return true

	# Check if previous chapter is complete
	var prev_chapter = chapter - 1
	for level in range(1, 11):  # 10 levels per chapter
		if not is_level_completed(prev_chapter, level):
			return false

	# Check essence spent requirement (500 per chapter after 2)
	if chapter >= 3:
		var required_spent = (chapter - 2) * 500
		# TODO: Track total essence spent
		pass

	return true


func get_chapter_completion(chapter: int) -> float:
	var completed = 0
	for level in range(1, 11):
		if is_level_completed(chapter, level):
			completed += 1
	return completed / 10.0


# ============ GAME STATE FUNCTIONS ============

func reset_game_state() -> void:
	game_state = {
		"ability_uses": {},
		"score_streak": 0,
		"time_freeze_moves": 0,
		"cascade_count": 0,
		"emergency_moves_used": false
	}
	init_game_abilities()


func increment_cascade() -> void:
	game_state.cascade_count += 1


func reset_cascade() -> void:
	game_state.cascade_count = 0


func get_current_cascade() -> int:
	return game_state.cascade_count


func check_move_saver() -> bool:
	# Returns true if move should be saved (not consumed)
	var chance = get_move_saver_chance()
	return randf() < chance


func use_time_freeze() -> void:
	game_state.time_freeze_moves = 3


func has_time_freeze_active() -> bool:
	return game_state.time_freeze_moves > 0


func consume_time_freeze_move() -> bool:
	if game_state.time_freeze_moves > 0:
		game_state.time_freeze_moves -= 1
		return true  # Move was covered by time freeze
	return false


func can_use_emergency_moves() -> bool:
	return not game_state.emergency_moves_used and get_emergency_moves() > 0


func use_emergency_moves() -> int:
	if can_use_emergency_moves():
		game_state.emergency_moves_used = true
		return get_emergency_moves()
	return 0


# ============ ESSENCE CALCULATION ============

func calculate_essence_earned(color: GameManager.SlimeColor, match_size: int, cascade_level: int) -> int:
	var color_name = GameManager.SLIME_COLOR_NAMES.get(color, "green")
	var base_value = GameManager.SLIME_POINT_VALUES.get(color, 1)

	# Match size multiplier
	var size_mult = 1
	if match_size == 4:
		size_mult = 2
	elif match_size >= 5:
		size_mult = 3

	var essence = base_value * size_mult

	# Cascade bonus (+50% per cascade level)
	if cascade_level > 0:
		essence = int(essence * (1.0 + cascade_level * 0.5))

	# Color mastery essence bonus
	var mastery_bonus = get_color_mastery_essence_bonus(color_name)
	if mastery_bonus > 0:
		essence = int(essence * (1.0 + mastery_bonus))

	return essence


# ============ SAVE/LOAD ============

func save_progression() -> void:
	if SaveManager.active_mode != SaveManager.MODE_STORY:
		return

	var data = {
		"currencies": currencies,
		"upgrades": upgrades,
		"abilities": abilities,
		"color_mastery": color_mastery,
		"campaign": campaign,
		"skill_tree_nodes": skill_tree_nodes
	}
	SaveManager.save_story_progression(data)


func load_progression() -> void:
	var data = SaveManager.load_story_progression()

	# Always reset to defaults first, then load saved data
	# This ensures empty/new slots start fresh
	currencies = {
		"slime_essence": 0,
		"star_dust": 0,
		"color_crystals": {
			"red": 0, "orange": 0, "yellow": 0,
			"green": 0, "blue": 0, "purple": 0
		}
	}
	skill_tree_nodes = {}
	color_mastery = {
		"red": 0, "orange": 0, "yellow": 0,
		"green": 0, "blue": 0, "purple": 0
	}

	if data.is_empty():
		return

	if data.has("currencies"):
		currencies = data.currencies
	if data.has("upgrades"):
		upgrades = data.upgrades
	if data.has("abilities"):
		abilities = data.abilities
	if data.has("color_mastery"):
		color_mastery = data.color_mastery
	if data.has("campaign"):
		campaign = data.campaign
	if data.has("skill_tree_nodes"):
		skill_tree_nodes = data.skill_tree_nodes


func reset_progression() -> void:
	# Reset all progression to defaults
	currencies = {
		"slime_essence": 0,
		"star_dust": 0,
		"color_crystals": {
			"red": 0, "orange": 0, "yellow": 0,
			"green": 0, "blue": 0, "purple": 0
		}
	}

	upgrades = {
		"scoring": {
			"point_boost": 0,
			"color_mastery_red": 0, "color_mastery_orange": 0,
			"color_mastery_yellow": 0, "color_mastery_green": 0,
			"color_mastery_blue": 0, "color_mastery_purple": 0,
			"match_4_bonus": 0, "match_5_bonus": 0, "special_bonus": 0
		},
		"moves": {
			"starting_moves": 0, "move_saver": 0, "emergency_moves": 0
		},
		"specials": {
			"striped_chance": 0, "wrapped_chance": 0, "color_bomb_chance": 0,
			"striped_power": 0, "wrapped_power": 0
		},
		"combos": {
			"combo_multiplier": 0, "cascade_boost": 0, "chain_reaction": 0
		}
	}

	abilities = {
		"slime_swap": {"unlocked": false, "level": 0},
		"color_burst": {"unlocked": false, "level": 0},
		"row_sweep": {"unlocked": false, "level": 0},
		"column_sweep": {"unlocked": false, "level": 0},
		"shuffle_plus": {"unlocked": false, "level": 0},
		"time_freeze": {"unlocked": false, "level": 0},
		"color_transform": {"unlocked": false, "level": 0},
		"special_spawner": {"unlocked": false, "level": 0}
	}

	color_mastery = {
		"red": 0, "orange": 0, "yellow": 0,
		"green": 0, "blue": 0, "purple": 0
	}

	campaign = {
		"current_chapter": 1,
		"current_level": 1,
		"completed_levels": [],
		"level_stars": {}
	}

	# Reset skill tree nodes
	skill_tree_nodes = {}

	save_progression()
