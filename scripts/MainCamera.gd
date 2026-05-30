extends Camera2D

@export var player_path: NodePath
@onready var player = get_node(player_path)

var is_panning: bool = false

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_MIDDLE:
			is_panning = event.pressed

	if event is InputEventMouseMotion and is_panning:
		position -= event.relative / zoom

	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_C:
			center_on_player()

func center_on_player():
	if player:
		position = player.position
