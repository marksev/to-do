extends Panel

var cell_color: Color = Color.TRANSPARENT
var is_filled: bool = false

func set_color(color: Color):
	cell_color = color
	is_filled = true
	queue_redraw()

func clear():
	cell_color = Color.TRANSPARENT
	is_filled = false
	queue_redraw()
