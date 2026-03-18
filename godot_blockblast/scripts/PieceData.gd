extends Node

# All piece shape definitions as 2D arrays (1 = filled, 0 = empty)
# Each piece also has a color

const PIECES = [
	# 0: I-horizontal (4x1)
	{
		"shape": [[1, 1, 1, 1]],
		"color": Color(0.2, 0.8, 1.0),
		"name": "I_H"
	},
	# 1: I-vertical (1x4)
	{
		"shape": [[1], [1], [1], [1]],
		"color": Color(0.2, 0.8, 1.0),
		"name": "I_V"
	},
	# 2: Square (2x2)
	{
		"shape": [[1, 1], [1, 1]],
		"color": Color(1.0, 0.85, 0.1),
		"name": "SQUARE"
	},
	# 3: L-shape
	{
		"shape": [[1, 0], [1, 0], [1, 1]],
		"color": Color(1.0, 0.5, 0.1),
		"name": "L"
	},
	# 4: J-shape (mirrored L)
	{
		"shape": [[0, 1], [0, 1], [1, 1]],
		"color": Color(0.3, 0.3, 1.0),
		"name": "J"
	},
	# 5: T-shape
	{
		"shape": [[1, 1, 1], [0, 1, 0]],
		"color": Color(0.7, 0.1, 0.9),
		"name": "T"
	},
	# 6: S-shape
	{
		"shape": [[0, 1, 1], [1, 1, 0]],
		"color": Color(0.1, 0.9, 0.4),
		"name": "S"
	},
	# 7: Z-shape
	{
		"shape": [[1, 1, 0], [0, 1, 1]],
		"color": Color(0.9, 0.2, 0.2),
		"name": "Z"
	},
	# 8: Single cell
	{
		"shape": [[1]],
		"color": Color(0.9, 0.9, 0.9),
		"name": "DOT"
	},
	# 9: Small L (3 cells)
	{
		"shape": [[1, 0], [1, 1]],
		"color": Color(1.0, 0.6, 0.8),
		"name": "SMALL_L"
	},
	# 10: Small J (mirrored small L)
	{
		"shape": [[0, 1], [1, 1]],
		"color": Color(0.4, 1.0, 0.9),
		"name": "SMALL_J"
	},
	# 11: 3x1 horizontal
	{
		"shape": [[1, 1, 1]],
		"color": Color(0.8, 0.4, 1.0),
		"name": "LINE_3H"
	},
	# 12: 3x1 vertical
	{
		"shape": [[1], [1], [1]],
		"color": Color(0.8, 0.4, 1.0),
		"name": "LINE_3V"
	},
	# 13: 2x1 horizontal
	{
		"shape": [[1, 1]],
		"color": Color(1.0, 0.75, 0.3),
		"name": "LINE_2H"
	},
	# 14: 2x1 vertical
	{
		"shape": [[1], [1]],
		"color": Color(1.0, 0.75, 0.3),
		"name": "LINE_2V"
	},
	# 15: Big L rotated
	{
		"shape": [[1, 1, 1], [1, 0, 0]],
		"color": Color(1.0, 0.4, 0.4),
		"name": "L_ROT"
	},
	# 16: Big J rotated
	{
		"shape": [[1, 1, 1], [0, 0, 1]],
		"color": Color(0.4, 0.8, 0.4),
		"name": "J_ROT"
	},
	# 17: 3x3 full square
	{
		"shape": [[1, 1, 1], [1, 1, 1], [1, 1, 1]],
		"color": Color(0.9, 0.6, 0.1),
		"name": "BIG_SQUARE"
	},
	# 18: Plus/cross shape
	{
		"shape": [[0, 1, 0], [1, 1, 1], [0, 1, 0]],
		"color": Color(0.6, 0.2, 0.8),
		"name": "PLUS"
	},
	# 19: Corner shape
	{
		"shape": [[1, 1], [1, 0]],
		"color": Color(0.2, 0.7, 0.9),
		"name": "CORNER"
	},
]

static func get_random_piece() -> Dictionary:
	return PIECES[randi() % PIECES.size()]

static func get_piece_count() -> int:
	return PIECES.size()
