extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game_state = root.get_node_or_null("/root/GameState")
	if game_state == null:
		_fail("GameState autoload is missing.")
		return

	game_state.start_new_game()

	if game_state.map_width != 24:
		_fail("map_width should be 24.")
		return
	if game_state.map_height != 16:
		_fail("map_height should be 16.")
		return

	var has_steppe := false
	var has_water_feature := false
	var has_rough_relief := false
	var has_connected_river := false
	var has_polar_cap := false
	var has_warm_center := false
	var has_continental_plain_texture := false
	var river_features := [
		game_state.WATER_STREAM,
		game_state.WATER_SMALL_RIVER,
		game_state.WATER_MEDIUM_RIVER,
		game_state.WATER_LARGE_RIVER
	]
	var river_terminal_features := [
		game_state.WATER_SEA,
		game_state.WATER_LAKE,
		game_state.WATER_SWAMP
	]

	for y in range(game_state.map_height):
		for x in range(game_state.map_width):
			var tile = game_state.get_tile(x, y)
			if tile == null:
				_fail("Tile is null at %d,%d." % [x, y])
				return

			if not game_state.CLIMATE_TYPES.has(tile.climate_type):
				_fail("Invalid climate_type at %d,%d: %s." % [x, y, tile.climate_type])
				return
			if not game_state.RELIEF_TYPES.has(tile.relief_type):
				_fail("Invalid relief_type at %d,%d: %s." % [x, y, tile.relief_type])
				return
			if not game_state.VEGETATION_TYPES.has(tile.vegetation_type):
				_fail("Invalid vegetation_type at %d,%d: %s." % [x, y, tile.vegetation_type])
				return
			if not game_state.WATER_FEATURE_TYPES.has(tile.water_feature):
				_fail("Invalid water_feature at %d,%d: %s." % [x, y, tile.water_feature])
				return

			var pole_distance: int = min(y, game_state.map_height - 1 - y)
			var distance_to_sea := _get_distance_to_sea(game_state, x, y)

			if tile.water_feature == game_state.WATER_SEA and tile.climate_type != game_state.CLIMATE_SEA:
				_fail("Sea tile must have sea climate at %d,%d." % [x, y])
				return
			if tile.water_feature != game_state.WATER_SEA and tile.climate_type == game_state.CLIMATE_SEA:
				_fail("Land tile cannot have sea climate at %d,%d." % [x, y])
				return
			if tile.climate_type == "alpine" or tile.climate_type == "highland":
				_fail("Highland/alpine is not an allowed climate at %d,%d." % [x, y])
				return
			if pole_distance <= 1 and (tile.climate_type == game_state.CLIMATE_TROPICAL or tile.climate_type == game_state.CLIMATE_DESERT or tile.climate_type == game_state.CLIMATE_MEDITERRANEAN):
				_fail("Polar cap has an invalid warm climate at %d,%d: %s." % [x, y, tile.climate_type])
				return
			if pole_distance >= 6 and tile.climate_type == game_state.CLIMATE_POLAR:
				_fail("Warm center has polar climate without a polar cap at %d,%d." % [x, y])
				return
			if tile.climate_type == game_state.CLIMATE_DESERT and pole_distance < 6:
				_fail("Desert should only appear in warm dry bands at %d,%d." % [x, y])
				return
			if tile.climate_type == game_state.CLIMATE_MEDITERRANEAN and (pole_distance < 5 or distance_to_sea > 3):
				_fail("Mediterranean climate should be warm and near the sea at %d,%d." % [x, y])
				return
			if tile.climate_type == game_state.CLIMATE_OCEANIC and distance_to_sea > 4 and not _has_near_major_water(game_state, x, y):
				_fail("Oceanic climate is too far from major water at %d,%d." % [x, y])
				return

			if tile.climate_type == game_state.CLIMATE_STEPPE or tile.vegetation_type == game_state.VEGETATION_STEPPE:
				has_steppe = true
			if pole_distance <= 1 and (tile.climate_type == game_state.CLIMATE_POLAR or tile.climate_type == game_state.CLIMATE_NORDIC):
				has_polar_cap = true
			if pole_distance >= 6 and (tile.climate_type == game_state.CLIMATE_TROPICAL or tile.climate_type == game_state.CLIMATE_MEDITERRANEAN or tile.climate_type == game_state.CLIMATE_ARID or tile.climate_type == game_state.CLIMATE_DESERT):
				has_warm_center = true
			if tile.water_feature != game_state.WATER_NONE:
				has_water_feature = true
			var texture_path: String = game_state.get_global_tile_texture_path(tile)
			if texture_path != "":
				if tile.climate_type != game_state.CLIMATE_CONTINENTAL:
					_fail("Global texture assigned to wrong climate at %d,%d." % [x, y])
					return
				if tile.relief_type != game_state.RELIEF_PLAINS and tile.relief_type != game_state.RELIEF_LOWLAND:
					_fail("Global texture assigned to wrong relief at %d,%d." % [x, y])
					return
				if tile.water_feature != game_state.WATER_NONE:
					_fail("Global texture assigned to water tile at %d,%d." % [x, y])
					return
				has_continental_plain_texture = true
			if tile.relief_type == game_state.RELIEF_HILLS or tile.relief_type == game_state.RELIEF_MOUNTAINS or tile.relief_type == game_state.RELIEF_ROCKY:
				has_rough_relief = true
			if river_features.has(tile.water_feature):
				if not _has_adjacent_water_continuation(game_state, x, y, river_features, river_terminal_features):
					_fail("River tile is isolated at %d,%d." % [x, y])
					return
				has_connected_river = true
			if _has_forbidden_climate_neighbor(game_state, x, y):
				_fail("Forbidden climate adjacency near %d,%d: %s." % [x, y, tile.climate_type])
				return

	if not has_steppe:
		_fail("World should contain at least one steppe climate or vegetation tile.")
		return
	if not has_polar_cap:
		_fail("World should contain a cold polar/nordic cap.")
		return
	if not has_warm_center:
		_fail("World should contain a warm center climate.")
		return
	if not has_water_feature:
		_fail("World should contain at least one tile with water_feature.")
		return
	if not has_rough_relief:
		_fail("World should contain at least one hills, mountains, or rocky tile.")
		return
	if not has_connected_river:
		_fail("World should contain at least one connected river tile.")
		return
	if not has_continental_plain_texture:
		_fail("World should contain at least one continental plains tile with a global texture.")
		return

	print("World metadata 0.003 test passed.")
	quit(0)


func _has_adjacent_water_continuation(game_state, x: int, y: int, river_features: Array, river_terminal_features: Array) -> bool:
	for offset in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		var neighbor = game_state.get_tile(x + offset.x, y + offset.y)
		if neighbor == null:
			continue
		if river_features.has(neighbor.water_feature) or river_terminal_features.has(neighbor.water_feature):
			return true

	return false


func _has_forbidden_climate_neighbor(game_state, x: int, y: int) -> bool:
	var tile = game_state.get_tile(x, y)
	if tile == null or tile.climate_type == game_state.CLIMATE_SEA:
		return false

	for offset in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		var neighbor = game_state.get_tile(x + offset.x, y + offset.y)
		if neighbor == null or neighbor.climate_type == game_state.CLIMATE_SEA:
			continue
		if _is_forbidden_pair(game_state, tile.climate_type, neighbor.climate_type):
			return true

	return false


func _is_forbidden_pair(game_state, first_climate: String, second_climate: String) -> bool:
	if first_climate == game_state.CLIMATE_POLAR:
		return second_climate == game_state.CLIMATE_DESERT or second_climate == game_state.CLIMATE_TROPICAL or second_climate == game_state.CLIMATE_MEDITERRANEAN
	if second_climate == game_state.CLIMATE_POLAR:
		return first_climate == game_state.CLIMATE_DESERT or first_climate == game_state.CLIMATE_TROPICAL or first_climate == game_state.CLIMATE_MEDITERRANEAN
	if first_climate == game_state.CLIMATE_NORDIC:
		return second_climate == game_state.CLIMATE_DESERT or second_climate == game_state.CLIMATE_TROPICAL
	if second_climate == game_state.CLIMATE_NORDIC:
		return first_climate == game_state.CLIMATE_DESERT or first_climate == game_state.CLIMATE_TROPICAL
	if first_climate == game_state.CLIMATE_DESERT:
		return second_climate == game_state.CLIMATE_OCEANIC or second_climate == game_state.CLIMATE_TROPICAL
	if second_climate == game_state.CLIMATE_DESERT:
		return first_climate == game_state.CLIMATE_OCEANIC or first_climate == game_state.CLIMATE_TROPICAL

	return false


func _get_distance_to_sea(game_state, x: int, y: int) -> int:
	var nearest_distance := 99

	for check_y in range(game_state.map_height):
		for check_x in range(game_state.map_width):
			var tile = game_state.get_tile(check_x, check_y)
			if tile == null or tile.water_feature != game_state.WATER_SEA:
				continue

			var distance: int = abs(x - check_x) + abs(y - check_y)
			if distance < nearest_distance:
				nearest_distance = distance

	return nearest_distance


func _has_near_major_water(game_state, x: int, y: int) -> bool:
	for check_y in range(y - 2, y + 3):
		for check_x in range(x - 2, x + 3):
			var tile = game_state.get_tile(check_x, check_y)
			if tile == null:
				continue
			if tile.water_feature == game_state.WATER_LAKE or tile.water_feature == game_state.WATER_SWAMP or tile.water_feature == game_state.WATER_MEDIUM_RIVER or tile.water_feature == game_state.WATER_LARGE_RIVER:
				return true

	return false


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
