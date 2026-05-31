extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game_state = root.get_node_or_null("/root/GameState")
	if game_state == null:
		_fail("GameState autoload is missing.")
		return

	game_state.start_new_game()

	if game_state.LOCAL_GRID_WIDTH != 48:
		_fail("LOCAL_GRID_WIDTH should be 48.")
		return
	if game_state.LOCAL_GRID_HEIGHT != 32:
		_fail("LOCAL_GRID_HEIGHT should be 32.")
		return
	if game_state.LOCAL_CELL_SIZE != 32:
		_fail("LOCAL_CELL_SIZE should be 32.")
		return
	if game_state.get_local_map_pixel_width() != 1536:
		_fail("Local map pixel width should be 1536.")
		return
	if game_state.get_local_map_pixel_height() != 1024:
		_fail("Local map pixel height should be 1024.")
		return

	var tile = _find_non_water_tile(game_state)
	if tile == null:
		_fail("Could not find a non-water tile.")
		return

	tile.ensure_local_grid_initialized(game_state.LOCAL_GRID_WIDTH, game_state.LOCAL_GRID_HEIGHT)
	var expected_size: int = game_state.LOCAL_GRID_WIDTH * game_state.LOCAL_GRID_HEIGHT
	if tile.local_grid.size() != expected_size:
		_fail("local_grid has wrong size: %d, expected %d." % [tile.local_grid.size(), expected_size])
		return

	print("Local map size 0.002 test passed.")
	quit(0)


func _find_non_water_tile(game_state):
	for y in range(game_state.map_height):
		for x in range(game_state.map_width):
			var tile = game_state.get_tile(x, y)
			if tile != null and tile.terrain_type != game_state.TERRAIN_WATER:
				return tile

	return null


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
