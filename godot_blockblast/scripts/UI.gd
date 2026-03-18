extends Control

signal restart_pressed

@onready var score_label = $ScorePanel/VBox/ScoreLabel
@onready var high_score_label = $ScorePanel/VBox/HighScoreLabel
@onready var game_over_overlay = $GameOverOverlay
@onready var final_score_label = $GameOverOverlay/Panel/VBox/FinalScoreLabel
@onready var final_high_label = $GameOverOverlay/Panel/VBox/FinalHighLabel
@onready var combo_popup = $ComboPopup
@onready var combo_label = $ComboPopup/ComboLabel

var display_score: int = 0
var target_score: int = 0
var score_tween: Tween = null

@onready var score_panel = $ScorePanel

func _ready():
	game_over_overlay.visible = false
	combo_popup.visible = false
	_style_score_panel()

func _style_score_panel():
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.12, 0.22, 0.95)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.3, 0.35, 0.6, 0.8)
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	style.shadow_color = Color(0, 0, 0, 0.5)
	style.shadow_size = 5
	score_panel.add_theme_stylebox_override("panel", style)

	var go_panel = $GameOverOverlay/Panel
	var go_style = StyleBoxFlat.new()
	go_style.bg_color = Color(0.08, 0.1, 0.2, 0.98)
	go_style.border_width_left = 2
	go_style.border_width_right = 2
	go_style.border_width_top = 2
	go_style.border_width_bottom = 2
	go_style.border_color = Color(0.4, 0.4, 0.8, 0.9)
	go_style.corner_radius_top_left = 16
	go_style.corner_radius_top_right = 16
	go_style.corner_radius_bottom_left = 16
	go_style.corner_radius_bottom_right = 16
	go_style.shadow_color = Color(0, 0, 0, 0.7)
	go_style.shadow_size = 16
	go_panel.add_theme_stylebox_override("panel", go_style)

func update_score(new_score: int):
	target_score = new_score
	if score_tween:
		score_tween.kill()
	score_tween = create_tween()
	score_tween.tween_method(_set_display_score, display_score, target_score, 0.4)

func _set_display_score(value: int):
	display_score = value
	score_label.text = "SCORE\n%d" % value

func update_high_score(hs: int):
	high_score_label.text = "BEST\n%d" % hs

func show_combo(combo: int):
	combo_label.text = "COMBO x%d!" % combo
	combo_popup.visible = true
	combo_popup.modulate.a = 1.0
	combo_popup.scale = Vector2(0.3, 0.3)

	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(combo_popup, "scale", Vector2(1.2, 1.2), 0.2).set_ease(Tween.EASE_OUT)
	tween.tween_property(combo_popup, "modulate:a", 1.0, 0.1)
	await tween.finished

	var tween2 = create_tween()
	tween2.set_parallel(true)
	tween2.tween_property(combo_popup, "scale", Vector2(1.0, 1.0), 0.1)
	await tween2.finished

	await get_tree().create_timer(0.8).timeout

	var tween3 = create_tween()
	tween3.tween_property(combo_popup, "modulate:a", 0.0, 0.3)
	await tween3.finished
	combo_popup.visible = false

func show_game_over(score: int, high_score: int):
	final_score_label.text = "Score: %d" % score
	final_high_label.text = "Best: %d" % high_score
	game_over_overlay.visible = true
	game_over_overlay.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(game_over_overlay, "modulate:a", 1.0, 0.5)

func hide_game_over():
	var tween = create_tween()
	tween.tween_property(game_over_overlay, "modulate:a", 0.0, 0.3)
	await tween.finished
	game_over_overlay.visible = false

func _on_restart_button_pressed():
	restart_pressed.emit()
