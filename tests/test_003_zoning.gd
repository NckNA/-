extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game_state = root.get_node_or_null("/root/GameState")
	if game_state == null:
		_fail("GameState autoload is missing.")
		return

	game_state.start_new_game()

	var tile = _find_non_water_tile(game_state)
	if tile == null:
		_fail("Could not find a non-water tile.")
		return

	tile.ensure_local_grid_initialized(game_state.LOCAL_GRID_WIDTH, game_state.LOCAL_GRID_HEIGHT)

	var first_cell: Dictionary = tile.get_local_cell(0, 0, game_state.LOCAL_GRID_WIDTH)
	if not first_cell.has("zone_type"):
		_fail("Cell 0,0 is missing zone_type.")
		return

	var residential_result: bool = tile.set_zone_for_cell(
		1,
		1,
		game_state.LOCAL_GRID_WIDTH,
		game_state.ZONE_RESIDENTIAL
	)
	if not residential_result:
		_fail("Could not set residential zone.")
		return

	var residential_cell: Dictionary = tile.get_local_cell(1, 1, game_state.LOCAL_GRID_WIDTH)
	if str(residential_cell.get("zone_type", "")) != game_state.ZONE_RESIDENTIAL:
		_fail("Cell 1,1 zone_type is not residential.")
		return
	if int(residential_cell.get("land_value", 0)) <= 0:
		_fail("Cell 1,1 land_value should be greater than 0.")
		return
	if str(residential_cell.get("land_status", "")) == "":
		_fail("Cell 1,1 land_status is empty.")
		return

	var trade_result: bool = tile.set_zone_for_cell(
		2,
		1,
		game_state.LOCAL_GRID_WIDTH,
		game_state.ZONE_TRADE
	)
	if not trade_result:
		_fail("Could not set trade zone.")
		return

	if tile.get_zoned_cells_count() < 2:
		_fail("Zoned cell count should be at least 2.")
		return

	print("Zoning 0.003 test passed.")
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
