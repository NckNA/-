extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game_state = root.get_node_or_null("/root/GameState")
	if game_state == null:
		_fail("GameState autoload is missing.")
		return

	game_state.start_new_game()

	if game_state.LOCAL_GRID_WIDTH < 40:
		_fail("LOCAL_GRID_WIDTH should be at least 40.")
		return
	if game_state.LOCAL_GRID_HEIGHT < 24:
		_fail("LOCAL_GRID_HEIGHT should be at least 24.")
		return
	if game_state.LOCAL_CELL_SIZE != 32:
		_fail("LOCAL_CELL_SIZE should be 32.")
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

	var cell: Dictionary = tile.get_local_cell(0, 0, game_state.LOCAL_GRID_WIDTH)
	if cell.is_empty():
		_fail("Cell 0,0 is missing.")
		return

	var required_fields := [
		"x",
		"y",
		"terrain_type",
		"zone_type",
		"building_id",
		"resource_type",
		"resource_amount",
		"blocked",
		"reserved",
		"land_value",
		"land_status"
	]

	for field_name in required_fields:
		if not cell.has(field_name):
			_fail("Cell 0,0 is missing field: %s." % field_name)
			return

	var free_for_building = tile.is_local_cell_free_for_building(0, 0, game_state.LOCAL_GRID_WIDTH)
	if typeof(free_for_building) != TYPE_BOOL:
		_fail("is_local_cell_free_for_building() did not return bool.")
		return

	print("Local grid 0.002 test passed.")
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
