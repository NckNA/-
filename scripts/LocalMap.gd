extends Node2D

@export var map_manager_path: NodePath
@onready var map_manager = get_node(map_manager_path)

var show_grid: bool = true

func _ready():
	map_manager.map_updated.connect(queue_redraw)

func _draw():
	if not map_manager:
		return

	var cell_size = map_manager.CELL_SIZE

	# Draw tiles
	for coords in map_manager.map_data:
		var tile = map_manager.map_data[coords]
		var rect = Rect2(coords.x * cell_size, coords.y * cell_size, cell_size, cell_size)
		var color = get_terrain_color(tile.terrain_type)
		draw_rect(rect, color)

		# Draw resource indicator
		if tile.resource_type != "none":
			var res_rect = Rect2(coords.x * cell_size + 8, coords.y * cell_size + 8, 16, 16)
			var res_color = get_resource_color(tile.resource_type)
			draw_rect(res_rect, res_color)

		# Draw building
		if tile.occupied:
			var b_rect = Rect2(coords.x * cell_size + 4, coords.y * cell_size + 4, 24, 24)
			draw_rect(b_rect, Color.BLACK, false, 2.0)
			# Mini indicator for building type
			var type_rect = Rect2(coords.x * cell_size + 10, coords.y * cell_size + 10, 12, 12)
			draw_rect(type_rect, Color.WHITE)

	# Draw grid
	if show_grid:
		for x in range(map_manager.MAP_WIDTH + 1):
			draw_line(Vector2(x * cell_size, 0), Vector2(x * cell_size, map_manager.MAP_HEIGHT * cell_size), Color(0.5, 0.5, 0.5, 0.5))
		for y in range(map_manager.MAP_HEIGHT + 1):
			draw_line(Vector2(0, y * cell_size), Vector2(map_manager.MAP_WIDTH * cell_size, y * cell_size), Color(0.5, 0.5, 0.5, 0.5))

	# Draw selection highlight
	if map_manager.selected_tile_coords != Vector2i(-1, -1):
		var s_coords = map_manager.selected_tile_coords
		var s_rect = Rect2(s_coords.x * cell_size, s_coords.y * cell_size, cell_size, cell_size)
		draw_rect(s_rect, Color.YELLOW, false, 3.0)

func get_terrain_color(terrain_type: String) -> Color:
	match terrain_type:
		"plain": return Color.DARK_GREEN
		"forest": return Color.FOREST_GREEN
		"hill": return Color.SADDLE_BROWN
		"water": return Color.DEEP_SKY_BLUE
		"mountain": return Color.DIM_GRAY
		_: return Color.MAGENTA

func get_resource_color(resource_type: String) -> Color:
	match resource_type:
		"wood": return Color.BURLYWOOD
		"stone": return Color.LIGHT_GRAY
		"iron": return Color.SILVER
		_: return Color.TRANSPARENT

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			var local_pos = get_local_mouse_position()
			var cell_size = map_manager.CELL_SIZE
			var grid_x = int(local_pos.x / cell_size)
			var grid_y = int(local_pos.y / cell_size)

			if grid_x >= 0 and grid_x < map_manager.MAP_WIDTH and grid_y >= 0 and grid_y < map_manager.MAP_HEIGHT:
				map_manager.select_tile(Vector2i(grid_x, grid_y))
				queue_redraw()

func toggle_grid():
	show_grid = !show_grid
	queue_redraw()
