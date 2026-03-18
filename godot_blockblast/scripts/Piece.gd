extends Control

signal drag_started(piece)
signal drag_ended(piece, drop_position: Vector2)

const CELL_SIZE = 52
const CELL_PADDING = 2
const BOARD_CELL_SIZE = 64
const BOARD_CELL_PADDING = 3

var shape: Array = []
var piece_color: Color = Color.WHITE
var piece_name: String = ""
var is_dragging: bool = false
var drag_offset: Vector2 = Vector2.ZERO
var original_position: Vector2 = Vector2.ZERO  # global position at drag start
var original_local_pos: Vector2 = Vector2.ZERO  # local position in tray
var tray_index: int = 0
var used: bool = false

var _scale_factor: float = 1.0

func _ready():
	mouse_filter = Control.MOUSE_FILTER_STOP

func setup(piece_data: Dictionary, index: int):
	tray_index = index
	shape = piece_data["shape"]
	piece_color = piece_data["color"]
	piece_name = piece_data["name"]
	_build_visual()

func _build_visual():
	for child in get_children():
		child.queue_free()

	var rows = shape.size()
	var cols = 0
	for row in shape:
		cols = max(cols, row.size())

	size = Vector2(
		cols * (CELL_SIZE + CELL_PADDING) - CELL_PADDING,
		rows * (CELL_SIZE + CELL_PADDING) - CELL_PADDING
	)

	for r in range(rows):
		for c in range(shape[r].size()):
			if shape[r][c] == 1:
				var cell = _create_cell(r, c)
				add_child(cell)

func _create_cell(row: int, col: int) -> Panel:
	var cell = Panel.new()
	cell.position = Vector2(col * (CELL_SIZE + CELL_PADDING), row * (CELL_SIZE + CELL_PADDING))
	cell.size = Vector2(CELL_SIZE, CELL_SIZE)
	cell.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var style = StyleBoxFlat.new()
	style.bg_color = piece_color
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 3
	style.border_width_bottom = 1
	style.border_color = piece_color.lightened(0.45)
	style.shadow_color = Color(0, 0, 0, 0.5)
	style.shadow_size = 4
	style.shadow_offset = Vector2(2, 3)
	style.corner_radius_top_left = 9
	style.corner_radius_top_right = 9
	style.corner_radius_bottom_left = 9
	style.corner_radius_bottom_right = 9
	cell.add_theme_stylebox_override("panel", style)

	# Inner highlight for 3D bevel
	var highlight = Panel.new()
	highlight.position = Vector2(3, 2)
	highlight.size = Vector2(CELL_SIZE - 6, CELL_SIZE * 0.35)
	highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var hl_style = StyleBoxFlat.new()
	hl_style.bg_color = Color(1, 1, 1, 0.22)
	hl_style.corner_radius_top_left = 6
	hl_style.corner_radius_top_right = 6
	hl_style.corner_radius_bottom_left = 3
	hl_style.corner_radius_bottom_right = 3
	highlight.add_theme_stylebox_override("panel", hl_style)
	cell.add_child(highlight)

	return cell

func _gui_input(event: InputEvent):
	if used:
		return
	# Support both mouse press and touch tap
	var pressed_pos = Vector2.ZERO
	var got_press = false
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		pressed_pos = event.global_position
		got_press = true
	elif event is InputEventScreenTouch and event.pressed:
		pressed_pos = event.position
		got_press = true
	if got_press:
		_start_drag(pressed_pos)
		get_viewport().set_input_as_handled()

func _start_drag(global_pos: Vector2):
	is_dragging = true
	original_position = global_position
	original_local_pos = position
	drag_offset = global_pos - global_position

	_scale_factor = float(BOARD_CELL_SIZE) / float(CELL_SIZE)
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(_scale_factor, _scale_factor), 0.1).set_ease(Tween.EASE_OUT)

	z_index = 100
	drag_started.emit(self)

func update_drag_position(global_pos: Vector2):
	if not is_dragging:
		return
	global_position = global_pos - drag_offset * _scale_factor

func end_drag(global_pos: Vector2):
	if not is_dragging:
		return
	is_dragging = false
	z_index = 0
	drag_ended.emit(self, global_pos)

func return_to_tray():
	is_dragging = false
	z_index = 0
	# Reparent back to tray and restore local position
	var tray = get_parent()
	var tween = create_tween()
	tween.set_parallel(true)
	if original_local_pos != Vector2.ZERO:
		# Convert current global pos to local for smooth tween
		var target_local = original_local_pos
		tween.tween_property(self, "position", target_local, 0.2).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2.ONE, 0.2).set_ease(Tween.EASE_OUT)

func mark_used():
	used = true
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	await tween.finished
	queue_free()
