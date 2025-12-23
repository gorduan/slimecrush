class_name CampaignData
extends RefCounted
## CampaignData - Static data for campaign chapters and levels
## Defines level targets, unlock requirements, and chapter themes

# ============ CHAPTER DEFINITIONS ============

const CHAPTERS: Dictionary = {
	1: {
		"name": "Tutorial Forest",
		"description": "Learn the basics of slime matching",
		"theme": "forest",
		"unlock_requirement": null,  # Always unlocked
		"levels": 10
	},
	2: {
		"name": "Slime Caves",
		"description": "Venture into the mysterious caves",
		"theme": "caves",
		"unlock_requirement": {"type": "chapter_complete", "chapter": 1},
		"levels": 10
	},
	3: {
		"name": "Crystal Mines",
		"description": "Discover the sparkling crystal depths",
		"theme": "crystals",
		"unlock_requirement": {"type": "chapter_complete", "chapter": 2, "essence_spent": 500},
		"levels": 10
	},
	4: {
		"name": "Lava Depths",
		"description": "Brave the scorching underground",
		"theme": "lava",
		"unlock_requirement": {"type": "chapter_complete", "chapter": 3, "essence_spent": 1500},
		"levels": 10
	},
	5: {
		"name": "Frozen Peaks",
		"description": "Climb the icy mountain heights",
		"theme": "ice",
		"unlock_requirement": {"type": "chapter_complete", "chapter": 4, "essence_spent": 3000},
		"levels": 10
	},
	6: {
		"name": "Cloud Kingdom",
		"description": "Ascend to the realm above the clouds",
		"theme": "clouds",
		"unlock_requirement": {"type": "chapter_complete", "chapter": 5, "essence_spent": 5000},
		"levels": 10
	},
	7: {
		"name": "Shadow Realm",
		"description": "Enter the mysterious dark dimension",
		"theme": "shadow",
		"unlock_requirement": {"type": "chapter_complete", "chapter": 6, "essence_spent": 8000},
		"levels": 10
	},
	8: {
		"name": "Rainbow Palace",
		"description": "The ultimate slime challenge awaits",
		"theme": "rainbow",
		"unlock_requirement": {"type": "chapter_complete", "chapter": 7, "essence_spent": 12000},
		"levels": 10
	}
}

# ============ LEVEL DEFINITIONS ============

# Base values for level scaling
const BASE_TARGET_SCORE: int = 500
const TARGET_SCORE_INCREMENT: int = 100
const BASE_MOVES: int = 25
const MOVES_INCREMENT_PER_CHAPTER: int = 2

# Star thresholds (multipliers of target score)
const STAR_1_MULTIPLIER: float = 1.0   # Complete the level
const STAR_2_MULTIPLIER: float = 1.5   # 150% of target
const STAR_3_MULTIPLIER: float = 2.0   # 200% of target

# ============ STATIC HELPER FUNCTIONS ============

static func get_chapter(chapter_id: int) -> Dictionary:
	if CHAPTERS.has(chapter_id):
		return CHAPTERS[chapter_id]
	return {}


static func get_total_chapters() -> int:
	return CHAPTERS.size()


static func get_level_data(chapter: int, level: int) -> Dictionary:
	if chapter < 1 or level < 1 or level > 10:
		return {}

	# Calculate level index (0-indexed across all chapters)
	var global_level = (chapter - 1) * 10 + level

	# Calculate target score
	# Increases by 100 per level, with chapter multiplier
	var chapter_multiplier = 1.0 + (chapter - 1) * 0.2  # +20% per chapter
	var base = BASE_TARGET_SCORE + (global_level - 1) * TARGET_SCORE_INCREMENT
	var target_score = int(base * chapter_multiplier)

	# Calculate moves
	# Base 25, +2 per chapter, slight variation per level
	var base_moves = BASE_MOVES + (chapter - 1) * MOVES_INCREMENT_PER_CHAPTER
	var level_variation = [0, 0, 1, 1, 2, 2, 3, 3, 4, 5]  # Levels 1-10
	var moves = base_moves + level_variation[level - 1]

	return {
		"chapter": chapter,
		"level": level,
		"global_level": global_level,
		"target_score": target_score,
		"moves": moves,
		"star_thresholds": {
			1: target_score,
			2: int(target_score * STAR_2_MULTIPLIER),
			3: int(target_score * STAR_3_MULTIPLIER)
		}
	}


static func calculate_stars(score: int, target_score: int) -> int:
	if score >= target_score * STAR_3_MULTIPLIER:
		return 3
	elif score >= target_score * STAR_2_MULTIPLIER:
		return 2
	elif score >= target_score:
		return 1
	return 0


static func is_chapter_unlocked(chapter_id: int, completed_levels: Array, total_essence_spent: int) -> bool:
	var chapter = get_chapter(chapter_id)
	if chapter.is_empty():
		return false

	var requirement = chapter.unlock_requirement
	if requirement == null:
		return true  # No requirement

	# Check chapter completion
	if requirement.type == "chapter_complete":
		var required_chapter = requirement.chapter
		# Check if all 10 levels of required chapter are complete
		for level in range(1, 11):
			var key = "%d-%d" % [required_chapter, level]
			if key not in completed_levels:
				return false

		# Check essence spent requirement if present
		if requirement.has("essence_spent"):
			if total_essence_spent < requirement.essence_spent:
				return false

		return true

	return false


static func get_chapter_progress(chapter_id: int, completed_levels: Array) -> Dictionary:
	var completed = 0
	var total_stars = 0

	for level in range(1, 11):
		var key = "%d-%d" % [chapter_id, level]
		if key in completed_levels:
			completed += 1

	return {
		"completed": completed,
		"total": 10,
		"percentage": completed / 10.0
	}


static func get_next_level(chapter: int, level: int) -> Dictionary:
	if level < 10:
		return {"chapter": chapter, "level": level + 1}
	elif chapter < get_total_chapters():
		return {"chapter": chapter + 1, "level": 1}
	return {}  # No more levels


static func get_chapter_theme(chapter_id: int) -> String:
	var chapter = get_chapter(chapter_id)
	return chapter.get("theme", "forest")


static func get_unlock_description(chapter_id: int) -> String:
	var chapter = get_chapter(chapter_id)
	if chapter.is_empty():
		return ""

	var requirement = chapter.unlock_requirement
	if requirement == null:
		return "Available from start"

	var text = "Complete Chapter %d" % requirement.chapter
	if requirement.has("essence_spent"):
		text += " and spend %d Slime Essence" % requirement.essence_spent

	return text


# ============ REWARD CALCULATION ============

static func calculate_completion_rewards(chapter: int, level: int, stars: int, is_first_time: bool) -> Dictionary:
	var rewards = {
		"star_dust": 0,
		"first_time_bonus": 0,
		"essence_multiplier": 1.0
	}

	# Star dust based on stars earned
	match stars:
		1: rewards.star_dust = 1
		2: rewards.star_dust = 3
		3: rewards.star_dust = 5

	# First time completion bonus
	if is_first_time:
		rewards.first_time_bonus = 3
		rewards.star_dust += rewards.first_time_bonus

	# Essence multiplier (reduced for replays)
	if not is_first_time:
		rewards.essence_multiplier = 0.5  # 50% essence on replay

	return rewards


# ============ SPECIAL LEVEL TYPES (for future expansion) ============

const SPECIAL_LEVELS: Dictionary = {
	# Chapter 1, Level 5: Tutorial for specials
	"1-5": {
		"type": "tutorial",
		"tutorial_topic": "specials",
		"guaranteed_special": true
	},
	# Chapter 1, Level 10: First boss-like level
	"1-10": {
		"type": "boss",
		"time_limit": 120,  # 2 minutes
		"bonus_reward": 5  # Extra star dust
	}
}


static func get_special_level_data(chapter: int, level: int) -> Dictionary:
	var key = "%d-%d" % [chapter, level]
	if SPECIAL_LEVELS.has(key):
		return SPECIAL_LEVELS[key]
	return {}


static func is_special_level(chapter: int, level: int) -> bool:
	var key = "%d-%d" % [chapter, level]
	return SPECIAL_LEVELS.has(key)
