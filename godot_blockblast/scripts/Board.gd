extends Control

signal lines_cleared(count: int, positions: Array)
signal piece_placed(cell_count: int)

const GRID_SIZE = 8
const CELL_SIZE = 64
const CELL_PADDING = 3
const GRID_OFFSET = Vector2(16, 16)

var grid: Array = []  # 2D array [row][col] = Color or null
var ghost_cells: Array = []  # cells to highlight for placement preview
var ghost_valid: bool = false

@onready var cells_container = $CellsContainer
@onready var highlight_container = $HighlightContainer

var cell_nodes: Array = []  # 2D array of cell node references

func _ready():
	custom_minimum_size = get_total_size()
	size = get_total_size()
	_init_grid()
	_create_visual_grid()
	_style_background()

func _style_background():
	var bg = $BoardBG
	if bg:
		bg.size = get_total_size()
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.08, 0.1, 0.18, 1.0)
		style.border_width_left = 2
		style.border_width_right = 2
		style.border_width_top = 2
		style.border_width_bottom = 2
		style.border_color = Color(0.2, 0.25, 0.5, 0.7)
		style.corner_radius_top_left = 12
		style.corner_radius_top_right = 12
		style.corner_radius_bottom_left = 12
		style.corner_radius_bottom_right = 12
		style.shadow_color = Color(0, 0, 0, 0.6)
		style.shadow_size = 8
		style.shadow_offset = Vector2(0, 4)
		bg.add_theme_stylebox_override("panel", style)

func _init_grid():
	grid = []
	for r in range(GRID_SIZE):
		var row = []
		for c in range(GRID_SIZE):
			row.append(null)
		grid.append(row)

func _create_visual_grid():
	cell_nodes = []
	for r in range(GRID_SIZE):
		var row_nodes = []
		for c in range(GRID_SIZE):
			var cell = _create_cell(r, c)
			cells_container.add_child(cell)
			row_nodes.append(cell)
		cell_nodes.append(row_nodes)

func _create_cell(row: int, col: int) -> Control:
	var cell = Panel.new()
	cell.position = GRID_OFFSET + Vector2(col * (CELL_SIZE + CELL_PADDING), row * (CELL_SIZE + CELL_PADDING))
	cell.size = Vector2(CELL_SIZE, CELL_SIZE)
	cell.name = "Cell_%d_%d" % [row, col]

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.14, 0.22, 0.85)
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.25, 0.28, 0.45, 0.5)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	cell.add_theme_stylebox_override("panel", style)

	return cell

func get_total_size() -> Vector2:
	var total = GRID_SIZE * CELL_SIZE + (GRID_SIZE - 1) * CELL_PADDING + GRID_OFFSET.x * 2
	return Vector2(total, total)

# Convert world position to grid coordinates
func world_to_grid(world_pos: Vector2) -> Vector2i:
	var local = world_pos - global_position - GRID_OFFSET
	var col = int(local.x / (CELL_SIZE + CELL_PADDING))
	var row = int(local.y / (CELL_SIZE + CELL_PADDING))
	return Vector2i(col, row)

# Get world position of a grid cell
func grid_to_world(row: int, col: int) -> Vector2:
	return global_position + GRID_OFFSET + Vector2(col * (CELL_SIZE + CELL_PADDING), row * (CELL_SIZE + CELL_PADDING))

# Check if a piece shape can be placed at given grid position
func can_place(shape: Array, grid_row: int, grid_col: int) -> bool:
	for r in range(shape.size()):
		for c in range(shape[r].size()):
			if shape[r][c] == 1:
				var gr = grid_row + r
				var gc = grid_col + c
				if gr < 0 or gr >= GRID_SIZE or gc < 0 or gc >= GRID_SIZE:
					return false
				if grid[gr][gc] != null:
					return false
	return true

# Place a piece on the grid
func place_piece(shape: Array, color: Color, grid_row: int, grid_col: int):
	var cell_count = 0
	for r in range(shape.size()):
		for c in range(shape[r].size()):
			if shape[r][c] == 1:
				grid[grid_row + r][grid_col + c] = color
				cell_count += 1
				_update_cell_visual(grid_row + r, grid_col + c, color)
	piece_placed.emit(cell_count)
	clear_ghost()
	await get_tree().process_frame
	await _check_and_clear_lines()

func _check_and_clear_lines():
	var full_rows = []
	var full_cols = []

	for r in range(GRID_SIZE):
		var full = true
		for c in range(GRID_SIZE):
			if grid[r][c] == null:
				full = false
				break
		if full:
			full_rows.append(r)

	for c in range(GRID_SIZE):
		var full = true
		for r in range(GRID_SIZE):
			if grid[r][c] == null:
				full = false
				break
		if full:
			full_cols.append(c)

	if full_rows.is_empty() and full_cols.is_empty():
		lines_cleared.emit(0, [])
		return

	# Collect all cells to clear
	var cells_to_clear = []
	for r in full_rows:
		for c in range(GRID_SIZE):
			if not cells_to_clear.has(Vector2i(r, c)):
				cells_to_clear.append(Vector2i(r, c))
	for c in full_cols:
		for r in range(GRID_SIZE):
			if not cells_to_clear.has(Vector2i(r, c)):
				cells_to_clear.append(Vector2i(r, c))

	var total_lines = full_rows.size() + full_cols.size()

	# Animate and clear
	await _animate_clear(cells_to_clear)

	for cell_pos in cells_to_clear:
		grid[cell_pos.x][cell_pos.y] = null
		_update_cell_visual(cell_pos.x, cell_pos.y, null)

	lines_cleared.emit(total_lines, cells_to_clear)

func _animate_clear(cells: Array):
	# Flash cells white
	for cell_pos in cells:
		var node = cell_nodes[cell_pos.x][cell_pos.y]
		var style = StyleBoxFlat.new()
		style.bg_color = Color.WHITE
		style.corner_radius_top_left = 8
		style.corner_radius_top_right = 8
		style.corner_radius_bottom_left = 8
		style.corner_radius_bottom_right = 8
		node.add_theme_stylebox_override("panel", style)

	await get_tree().create_timer(0.12).timeout

	# Scale out animation using tween
	var tween = create_tween()
	tween.set_parallel(true)
	for cell_pos in cells:
		var node = cell_nodes[cell_pos.x][cell_pos.y]
		tween.tween_property(node, "scale", Vector2(1.3, 1.3), 0.1)
		tween.tween_property(node, "modulate:a", 0.0, 0.15)

	await tween.finished

	# Reset scale/alpha
	for cell_pos in cells:
		var node = cell_nodes[cell_pos.x][cell_pos.y]
		node.scale = Vector2.ONE
		node.modulate.a = 1.0

func _update_cell_visual(row: int, col: int, color):
	var node = cell_nodes[row][col]
	var style = StyleBoxFlat.new()

	if color == null:
		style.bg_color = Color(0.12, 0.14, 0.22, 0.85)
		style.border_width_left = 1
		style.border_width_right = 1
		style.border_width_top = 1
		style.border_width_bottom = 1
		style.border_color = Color(0.25, 0.28, 0.45, 0.5)
	else:
		style.bg_color = color
		# Bevel effect using border
		style.border_width_left = 2
		style.border_width_right = 2
		style.border_width_top = 3
		style.border_width_bottom = 1
		style.border_color = color.lightened(0.4)
		# Shadow via expand margin
		style.shadow_color = Color(0, 0, 0, 0.4)
		style.shadow_size = 3
		style.shadow_offset = Vector2(2, 2)

	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	node.add_theme_stylebox_override("panel", style)

# Show ghost preview
func show_ghost(shape: Array, color: Color, grid_row: int, grid_col: int):
	clear_ghost()
	ghost_valid = can_place(shape, grid_row, grid_col)
	var ghost_color = Color(color.r, color.g, color.b, 0.45) if ghost_valid else Color(1.0, 0.2, 0.2, 0.35)

	for r in range(shape.size()):
		for c in range(shape[r].size()):
			if shape[r][c] == 1:
				var gr = grid_row + r
				var gc = grid_col + c
				if gr >= 0 and gr < GRID_SIZE and gc >= 0 and gc < GRID_SIZE:
					ghost_cells.append(Vector2i(gr, gc))
					_set_ghost_visual(gr, gc, ghost_color, ghost_valid)

func clear_ghost():
	for cell_pos in ghost_cells:
		# Restore original color
		_update_cell_visual(cell_pos.x, cell_pos.y, grid[cell_pos.x][cell_pos.y])
	ghost_cells.clear()

func _set_ghost_visual(row: int, col: int, color: Color, valid: bool):
	var node = cell_nodes[row][col]
	var style = StyleBoxFlat.new()
	style.bg_color = color

	if valid:
		style.border_width_left = 2
		style.border_width_right = 2
		style.border_width_top = 2
		style.border_width_bottom = 2
		style.border_color = Color(0.5, 1.0, 0.5, 0.8)
	else:
		style.border_width_left = 2
		style.border_width_right = 2
		style.border_width_top = 2
		style.border_width_bottom = 2
		style.border_color = Color(1.0, 0.2, 0.2, 0.8)

	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	node.add_theme_stylebox_override("panel", style)

# Check if any of the given pieces can fit on the board
func check_game_over(pieces: Array) -> bool:
	for piece_data in pieces:
		if piece_data == null:
			continue
		var shape = piece_data["shape"]
		for r in range(GRID_SIZE):
			for c in range(GRID_SIZE):
				if can_place(shape, r, c):
					return false
	return true

func get_snap_position(shape: Array, world_pos: Vector2) -> Vector2i:
	# Find best grid snap position centered on the piece
	var shape_rows = shape.size()
	var shape_cols = shape[0].size() if shape.size() > 0 else 0
	var local = world_pos - global_position - GRID_OFFSET
	var col = int(round(local.x / (CELL_SIZE + CELL_PADDING)))
	var row = int(round(local.y / (CELL_SIZE + CELL_PADDING)))
	return Vector2i(row, col)
