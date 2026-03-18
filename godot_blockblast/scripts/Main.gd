extends Control

const PieceData = preload("res://scripts/PieceData.gd")

@onready var board = $Board
@onready var score_manager = $ScoreManager
@onready var ui = $UI
@onready var tray = $Tray
@onready var sound_manager = $SoundManager

var tray_pieces: Array = [null, null, null]
var piece_nodes: Array = [null, null, null]
var active_drag_piece = null
var game_active: bool = true
var is_placing: bool = false  # prevent double-placement during async

func _ready():
	randomize()
	_style_tray()
	_connect_signals()
	_fill_tray()
	ui.update_score(0)
	ui.update_high_score(score_manager.high_score)

func _style_tray():
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.12, 0.22, 0.92)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.25, 0.3, 0.55, 0.8)
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	style.shadow_color = Color(0, 0, 0, 0.5)
	style.shadow_size = 6
	style.shadow_offset = Vector2(0, 3)
	tray.add_theme_stylebox_override("panel", style)

func _connect_signals():
	board.lines_cleared.connect(_on_lines_cleared)
	board.piece_placed.connect(_on_piece_placed)
	score_manager.score_changed.connect(ui.update_score)
	score_manager.high_score_changed.connect(ui.update_high_score)
	ui.restart_pressed.connect(_restart_game)

func _fill_tray():
	for i in range(3):
		tray_pieces[i] = PieceData.get_random_piece()
	_spawn_tray_pieces()

func _spawn_tray_pieces():
	for node in piece_nodes:
		if is_instance_valid(node):
			node.queue_free()
	piece_nodes = [null, null, null]

	for i in range(3):
		if tray_pieces[i] != null:
			_spawn_piece_at_slot(i, tray_pieces[i])

func _spawn_piece_at_slot(index: int, piece_data: Dictionary):
	var piece_scene = load("res://scenes/Piece.tscn")
	var piece = piece_scene.instantiate()
	tray.add_child(piece)
	piece.setup(piece_data, index)

	var slot_width = tray.size.x / 3.0
	var slot_center_x = slot_width * index + slot_width / 2.0
	var piece_center_x = slot_center_x - piece.size.x / 2.0
	var piece_center_y = tray.size.y / 2.0 - piece.size.y / 2.0
	piece.position = Vector2(piece_center_x, piece_center_y)
	piece.original_local_pos = piece.position
	piece.original_position = piece.global_position

	piece.drag_started.connect(_on_piece_drag_started)
	piece.drag_ended.connect(_on_piece_drag_ended)
	piece_nodes[index] = piece

func _on_piece_drag_started(piece):
	if not game_active or is_placing:
		piece.return_to_tray()
		return
	active_drag_piece = piece

func _on_piece_drag_ended(piece, drop_position: Vector2):
	if not game_active or is_placing:
		piece.return_to_tray()
		return
	active_drag_piece = null
	_try_place_piece(piece, drop_position)

func _try_place_piece(piece, drop_position: Vector2):
	var shape = piece.shape
	var grid_pos = board.get_snap_position(shape, drop_position)
	var gr = grid_pos.x
	var gc = grid_pos.y

	board.clear_ghost()

	if board.can_place(shape, gr, gc):
		is_placing = true
		var color = piece.piece_color
		var idx = piece.tray_index
		tray_pieces[idx] = null
		piece_nodes[idx] = null
		sound_manager.play_place()
		piece.mark_used()
		await board.place_piece(shape, color, gr, gc)
		is_placing = false
		_check_tray_refill()
	else:
		piece.return_to_tray()
		sound_manager.play_invalid()

func _input(event: InputEvent):
	if active_drag_piece == null:
		return

	if event is InputEventMouseMotion:
		active_drag_piece.update_drag_position(event.global_position)
		var shape = active_drag_piece.shape
		var grid_pos = board.get_snap_position(shape, event.global_position)
		board.show_ghost(shape, active_drag_piece.piece_color, grid_pos.x, grid_pos.y)

	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		var piece = active_drag_piece
		active_drag_piece = null
		piece.end_drag(event.global_position)

func _check_tray_refill():
	var all_used = true
	for p in tray_pieces:
		if p != null:
			all_used = false
			break

	if all_used:
		_fill_tray()
		# After refill, check if new pieces can fit
		await get_tree().process_frame
		if board.check_game_over(tray_pieces):
			_on_game_over()
	else:
		var remaining = []
		for p in tray_pieces:
			if p != null:
				remaining.append(p)
		if board.check_game_over(remaining):
			_on_game_over()

func _on_piece_placed(cell_count: int):
	score_manager.add_placement_score(cell_count)

func _on_lines_cleared(count: int, positions: Array):
	if count > 0:
		var combo = score_manager.add_clear_score(count)
		sound_manager.play_clear(combo)
		if combo > 1:
			ui.show_combo(combo)
		# Spawn a particle burst per cleared row/col center (not per cell)
		var spawned_positions = {}
		for pos in positions:
			# Spawn at row-center and col-center positions (avoid duplicates by using sparse sampling)
			if pos.y == 0 and not spawned_positions.has("r%d" % pos.x):
				spawned_positions["r%d" % pos.x] = true
				_spawn_particle_at(board.grid_to_world(pos.x, 4))
			if pos.x == 0 and not spawned_positions.has("c%d" % pos.y):
				spawned_positions["c%d" % pos.y] = true
				_spawn_particle_at(board.grid_to_world(4, pos.y))
	else:
		score_manager.combo_count = 0

func _spawn_particle_at(world_pos: Vector2):
	var particle_scene = load("res://scenes/ParticleExplosion.tscn")
	var particle = particle_scene.instantiate()
	add_child(particle)
	particle.global_position = world_pos + Vector2(32, 32)
	particle.emitting = true
	get_tree().create_timer(2.0).timeout.connect(func():
		if is_instance_valid(particle):
			particle.queue_free()
	)

func _on_game_over():
	game_active = false
	sound_manager.play_game_over()
	await get_tree().create_timer(0.6).timeout
	if is_instance_valid(ui):
		ui.show_game_over(score_manager.score, score_manager.high_score)

func _restart_game():
	game_active = true
	is_placing = false
	active_drag_piece = null
	score_manager.reset()

	# Reset board
	board._init_grid()
	for r in range(board.GRID_SIZE):
		for c in range(board.GRID_SIZE):
			board._update_cell_visual(r, c, null)
	board.clear_ghost()

	# Clear tray
	for node in piece_nodes:
		if is_instance_valid(node):
			node.queue_free()
	piece_nodes = [null, null, null]
	tray_pieces = [null, null, null]

	_fill_tray()
	ui.hide_game_over()
