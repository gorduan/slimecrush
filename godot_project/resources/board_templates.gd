extends RefCounted
class_name BoardTemplates
## BoardTemplates - Vordefinierte Spielfeld-Formen
## 1 = spielbares Feld, 0 = leer/blockiert

# Standard 8x8 Quadrat
const TEMPLATE_SQUARE_8x8: Array = [
	[1, 1, 1, 1, 1, 1, 1, 1],
	[1, 1, 1, 1, 1, 1, 1, 1],
	[1, 1, 1, 1, 1, 1, 1, 1],
	[1, 1, 1, 1, 1, 1, 1, 1],
	[1, 1, 1, 1, 1, 1, 1, 1],
	[1, 1, 1, 1, 1, 1, 1, 1],
	[1, 1, 1, 1, 1, 1, 1, 1],
	[1, 1, 1, 1, 1, 1, 1, 1],
]

# Kleineres 7x7 Quadrat (zentriert)
const TEMPLATE_SQUARE_7x7: Array = [
	[0, 1, 1, 1, 1, 1, 1, 0],
	[1, 1, 1, 1, 1, 1, 1, 1],
	[1, 1, 1, 1, 1, 1, 1, 1],
	[1, 1, 1, 1, 1, 1, 1, 1],
	[1, 1, 1, 1, 1, 1, 1, 1],
	[1, 1, 1, 1, 1, 1, 1, 1],
	[1, 1, 1, 1, 1, 1, 1, 1],
	[0, 1, 1, 1, 1, 1, 1, 0],
]

# Diamant-Form
const TEMPLATE_DIAMOND: Array = [
	[0, 0, 0, 1, 1, 0, 0, 0],
	[0, 0, 1, 1, 1, 1, 0, 0],
	[0, 1, 1, 1, 1, 1, 1, 0],
	[1, 1, 1, 1, 1, 1, 1, 1],
	[1, 1, 1, 1, 1, 1, 1, 1],
	[0, 1, 1, 1, 1, 1, 1, 0],
	[0, 0, 1, 1, 1, 1, 0, 0],
	[0, 0, 0, 1, 1, 0, 0, 0],
]

# Kreuz-Form
const TEMPLATE_CROSS: Array = [
	[0, 0, 1, 1, 1, 1, 0, 0],
	[0, 0, 1, 1, 1, 1, 0, 0],
	[1, 1, 1, 1, 1, 1, 1, 1],
	[1, 1, 1, 1, 1, 1, 1, 1],
	[1, 1, 1, 1, 1, 1, 1, 1],
	[1, 1, 1, 1, 1, 1, 1, 1],
	[0, 0, 1, 1, 1, 1, 0, 0],
	[0, 0, 1, 1, 1, 1, 0, 0],
]

# L-Form
const TEMPLATE_L_SHAPE: Array = [
	[1, 1, 1, 0, 0, 0, 0, 0],
	[1, 1, 1, 0, 0, 0, 0, 0],
	[1, 1, 1, 0, 0, 0, 0, 0],
	[1, 1, 1, 0, 0, 0, 0, 0],
	[1, 1, 1, 1, 1, 1, 1, 1],
	[1, 1, 1, 1, 1, 1, 1, 1],
	[1, 1, 1, 1, 1, 1, 1, 1],
	[1, 1, 1, 1, 1, 1, 1, 1],
]

# Umgekehrte L-Form
const TEMPLATE_L_SHAPE_REVERSED: Array = [
	[0, 0, 0, 0, 0, 1, 1, 1],
	[0, 0, 0, 0, 0, 1, 1, 1],
	[0, 0, 0, 0, 0, 1, 1, 1],
	[0, 0, 0, 0, 0, 1, 1, 1],
	[1, 1, 1, 1, 1, 1, 1, 1],
	[1, 1, 1, 1, 1, 1, 1, 1],
	[1, 1, 1, 1, 1, 1, 1, 1],
	[1, 1, 1, 1, 1, 1, 1, 1],
]

# Donut (Loch in der Mitte)
const TEMPLATE_DONUT: Array = [
	[1, 1, 1, 1, 1, 1, 1, 1],
	[1, 1, 1, 1, 1, 1, 1, 1],
	[1, 1, 0, 0, 0, 0, 1, 1],
	[1, 1, 0, 0, 0, 0, 1, 1],
	[1, 1, 0, 0, 0, 0, 1, 1],
	[1, 1, 0, 0, 0, 0, 1, 1],
	[1, 1, 1, 1, 1, 1, 1, 1],
	[1, 1, 1, 1, 1, 1, 1, 1],
]

# Sanduhr
const TEMPLATE_HOURGLASS: Array = [
	[1, 1, 1, 1, 1, 1, 1, 1],
	[0, 1, 1, 1, 1, 1, 1, 0],
	[0, 0, 1, 1, 1, 1, 0, 0],
	[0, 0, 0, 1, 1, 0, 0, 0],
	[0, 0, 0, 1, 1, 0, 0, 0],
	[0, 0, 1, 1, 1, 1, 0, 0],
	[0, 1, 1, 1, 1, 1, 1, 0],
	[1, 1, 1, 1, 1, 1, 1, 1],
]

# T-Form
const TEMPLATE_T_SHAPE: Array = [
	[1, 1, 1, 1, 1, 1, 1, 1],
	[1, 1, 1, 1, 1, 1, 1, 1],
	[1, 1, 1, 1, 1, 1, 1, 1],
	[0, 0, 1, 1, 1, 1, 0, 0],
	[0, 0, 1, 1, 1, 1, 0, 0],
	[0, 0, 1, 1, 1, 1, 0, 0],
	[0, 0, 1, 1, 1, 1, 0, 0],
	[0, 0, 1, 1, 1, 1, 0, 0],
]

# Herz-Form
const TEMPLATE_HEART: Array = [
	[0, 1, 1, 0, 0, 1, 1, 0],
	[1, 1, 1, 1, 1, 1, 1, 1],
	[1, 1, 1, 1, 1, 1, 1, 1],
	[1, 1, 1, 1, 1, 1, 1, 1],
	[0, 1, 1, 1, 1, 1, 1, 0],
	[0, 0, 1, 1, 1, 1, 0, 0],
	[0, 0, 0, 1, 1, 0, 0, 0],
	[0, 0, 0, 0, 0, 0, 0, 0],
]

# Pfeil nach oben
const TEMPLATE_ARROW_UP: Array = [
	[0, 0, 0, 1, 1, 0, 0, 0],
	[0, 0, 1, 1, 1, 1, 0, 0],
	[0, 1, 1, 1, 1, 1, 1, 0],
	[1, 1, 1, 1, 1, 1, 1, 1],
	[0, 0, 1, 1, 1, 1, 0, 0],
	[0, 0, 1, 1, 1, 1, 0, 0],
	[0, 0, 1, 1, 1, 1, 0, 0],
	[0, 0, 1, 1, 1, 1, 0, 0],
]

# Plus-Form (dick)
const TEMPLATE_PLUS: Array = [
	[0, 0, 1, 1, 1, 1, 0, 0],
	[0, 0, 1, 1, 1, 1, 0, 0],
	[1, 1, 1, 1, 1, 1, 1, 1],
	[1, 1, 1, 1, 1, 1, 1, 1],
	[1, 1, 1, 1, 1, 1, 1, 1],
	[1, 1, 1, 1, 1, 1, 1, 1],
	[0, 0, 1, 1, 1, 1, 0, 0],
	[0, 0, 1, 1, 1, 1, 0, 0],
]

# U-Form
const TEMPLATE_U_SHAPE: Array = [
	[1, 1, 0, 0, 0, 0, 1, 1],
	[1, 1, 0, 0, 0, 0, 1, 1],
	[1, 1, 0, 0, 0, 0, 1, 1],
	[1, 1, 0, 0, 0, 0, 1, 1],
	[1, 1, 1, 1, 1, 1, 1, 1],
	[1, 1, 1, 1, 1, 1, 1, 1],
	[1, 1, 1, 1, 1, 1, 1, 1],
	[1, 1, 1, 1, 1, 1, 1, 1],
]

# Ecken (nur die Ecken)
const TEMPLATE_CORNERS: Array = [
	[1, 1, 1, 0, 0, 1, 1, 1],
	[1, 1, 1, 0, 0, 1, 1, 1],
	[1, 1, 1, 0, 0, 1, 1, 1],
	[0, 0, 0, 0, 0, 0, 0, 0],
	[0, 0, 0, 0, 0, 0, 0, 0],
	[1, 1, 1, 0, 0, 1, 1, 1],
	[1, 1, 1, 0, 0, 1, 1, 1],
	[1, 1, 1, 0, 0, 1, 1, 1],
]

# Schachbrett-Muster (große Felder)
const TEMPLATE_CHECKERBOARD: Array = [
	[1, 1, 0, 0, 1, 1, 0, 0],
	[1, 1, 0, 0, 1, 1, 0, 0],
	[0, 0, 1, 1, 0, 0, 1, 1],
	[0, 0, 1, 1, 0, 0, 1, 1],
	[1, 1, 0, 0, 1, 1, 0, 0],
	[1, 1, 0, 0, 1, 1, 0, 0],
	[0, 0, 1, 1, 0, 0, 1, 1],
	[0, 0, 1, 1, 0, 0, 1, 1],
]

# Treppe
const TEMPLATE_STAIRS: Array = [
	[1, 0, 0, 0, 0, 0, 0, 0],
	[1, 1, 0, 0, 0, 0, 0, 0],
	[1, 1, 1, 0, 0, 0, 0, 0],
	[1, 1, 1, 1, 0, 0, 0, 0],
	[1, 1, 1, 1, 1, 0, 0, 0],
	[1, 1, 1, 1, 1, 1, 0, 0],
	[1, 1, 1, 1, 1, 1, 1, 0],
	[1, 1, 1, 1, 1, 1, 1, 1],
]

# Rahmen (außen voll, innen leer)
const TEMPLATE_FRAME: Array = [
	[1, 1, 1, 1, 1, 1, 1, 1],
	[1, 0, 0, 0, 0, 0, 0, 1],
	[1, 0, 0, 0, 0, 0, 0, 1],
	[1, 0, 0, 0, 0, 0, 0, 1],
	[1, 0, 0, 0, 0, 0, 0, 1],
	[1, 0, 0, 0, 0, 0, 0, 1],
	[1, 0, 0, 0, 0, 0, 0, 1],
	[1, 1, 1, 1, 1, 1, 1, 1],
]

# H-Form
const TEMPLATE_H_SHAPE: Array = [
	[1, 1, 0, 0, 0, 0, 1, 1],
	[1, 1, 0, 0, 0, 0, 1, 1],
	[1, 1, 0, 0, 0, 0, 1, 1],
	[1, 1, 1, 1, 1, 1, 1, 1],
	[1, 1, 1, 1, 1, 1, 1, 1],
	[1, 1, 0, 0, 0, 0, 1, 1],
	[1, 1, 0, 0, 0, 0, 1, 1],
	[1, 1, 0, 0, 0, 0, 1, 1],
]

# Kleines Loch in der Mitte
const TEMPLATE_SMALL_HOLE: Array = [
	[1, 1, 1, 1, 1, 1, 1, 1],
	[1, 1, 1, 1, 1, 1, 1, 1],
	[1, 1, 1, 1, 1, 1, 1, 1],
	[1, 1, 1, 0, 0, 1, 1, 1],
	[1, 1, 1, 0, 0, 1, 1, 1],
	[1, 1, 1, 1, 1, 1, 1, 1],
	[1, 1, 1, 1, 1, 1, 1, 1],
	[1, 1, 1, 1, 1, 1, 1, 1],
]

# Alle Templates als Array für einfachen Zugriff
const ALL_TEMPLATES: Array = [
	TEMPLATE_SQUARE_8x8,
	TEMPLATE_SQUARE_7x7,
	TEMPLATE_DIAMOND,
	TEMPLATE_CROSS,
	TEMPLATE_L_SHAPE,
	TEMPLATE_L_SHAPE_REVERSED,
	TEMPLATE_DONUT,
	TEMPLATE_HOURGLASS,
	TEMPLATE_T_SHAPE,
	TEMPLATE_HEART,
	TEMPLATE_ARROW_UP,
	TEMPLATE_PLUS,
	TEMPLATE_U_SHAPE,
	TEMPLATE_CORNERS,
	TEMPLATE_CHECKERBOARD,
	TEMPLATE_STAIRS,
	TEMPLATE_FRAME,
	TEMPLATE_H_SHAPE,
	TEMPLATE_SMALL_HOLE,
]

# Template-Namen für Debug/UI
const TEMPLATE_NAMES: Array = [
	"Quadrat 8x8",
	"Quadrat 7x7",
	"Diamant",
	"Kreuz",
	"L-Form",
	"L-Form (umgekehrt)",
	"Donut",
	"Sanduhr",
	"T-Form",
	"Herz",
	"Pfeil",
	"Plus",
	"U-Form",
	"Ecken",
	"Schachbrett",
	"Treppe",
	"Rahmen",
	"H-Form",
	"Kleines Loch",
]


# Gibt ein Template basierend auf Level zurück
static func get_template_for_level(level: int) -> Array:
	# Level 1-3: Einfache Formen
	# Level 4-6: Mittelschwere Formen
	# Level 7-10: Schwierige Formen
	var level_in_stage = ((level - 1) % 10) + 1

	match level_in_stage:
		1:
			return TEMPLATE_SQUARE_8x8
		2:
			return TEMPLATE_SQUARE_7x7
		3:
			return TEMPLATE_SMALL_HOLE
		4:
			return TEMPLATE_DIAMOND
		5:
			return TEMPLATE_CROSS
		6:
			return TEMPLATE_PLUS
		7:
			return TEMPLATE_DONUT
		8:
			return TEMPLATE_L_SHAPE if level % 2 == 0 else TEMPLATE_L_SHAPE_REVERSED
		9:
			return TEMPLATE_HOURGLASS
		10:
			return TEMPLATE_HEART
		_:
			return TEMPLATE_SQUARE_8x8


# Gibt ein zufälliges Template zurück
static func get_random_template() -> Array:
	return ALL_TEMPLATES[randi() % ALL_TEMPLATES.size()]


# Zählt die spielbaren Felder in einem Template
static func count_playable_cells(template: Array) -> int:
	var count = 0
	for row in template:
		for cell in row:
			if cell == 1:
				count += 1
	return count


# Prüft ob eine Position im Template spielbar ist
static func is_playable(template: Array, x: int, y: int) -> bool:
	if y < 0 or y >= template.size():
		return false
	if x < 0 or x >= template[y].size():
		return false
	return template[y][x] == 1
