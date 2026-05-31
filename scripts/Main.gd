extends Node2D

@onready var map_manager = $MapManager
@onready var local_map = $LocalMap
@onready var player = $Player
@onready var camera = $MainCamera

func _input(event):
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_G:
			local_map.toggle_grid()
