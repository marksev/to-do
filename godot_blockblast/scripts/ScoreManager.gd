extends Node

signal score_changed(new_score: int)
signal high_score_changed(new_high_score: int)

const SAVE_PATH = "user://highscore.save"
const POINTS_PER_CELL = 10
const POINTS_PER_LINE = 100

var score: int = 0
var high_score: int = 0
var combo_count: int = 0

func _ready():
	load_high_score()

func add_placement_score(cell_count: int):
	var points = cell_count * POINTS_PER_CELL
	score += points
	score_changed.emit(score)
	_check_high_score()

func add_clear_score(lines_cleared: int):
	if lines_cleared <= 0:
		combo_count = 0
		return
	combo_count += 1
	var base_points = lines_cleared * POINTS_PER_LINE
	var multiplied = base_points * combo_count
	score += multiplied
	score_changed.emit(score)
	_check_high_score()
	return combo_count

func reset():
	score = 0
	combo_count = 0
	score_changed.emit(score)

func _check_high_score():
	if score > high_score:
		high_score = score
		high_score_changed.emit(high_score)
		save_high_score()

func save_high_score():
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_32(high_score)
		file.close()

func load_high_score():
	if FileAccess.file_exists(SAVE_PATH):
		var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
		if file:
			high_score = file.get_32()
			file.close()
	high_score_changed.emit(high_score)
