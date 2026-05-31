extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game_state = root.get_node_or_null("/root/GameState")
	if game_state == null:
		_fail("GameState autoload is missing.")
		return

	game_state.start_new_game()
	_check_vegetation_resource_ownership(game_state)
	_check_camp_settlement_compatibility(game_state)

	for y in range(game_state.map_height):
		for x in range(game_state.map_width):
			var tile = game_state.get_tile(x, y)
			if tile == null:
				_fail("Missing tile at %d,%d." % [x, y])
				return

			if not game_state.CLIMATE_TYPES.has(tile.climate_type):
				_fail("Invalid climate_type at %d,%d: %s." % [x, y, tile.climate_type])
				return
			if not game_state.RELIEF_TYPES.has(tile.relief_type):
				_fail("Invalid public relief_type at %d,%d: %s." % [x, y, tile.relief_type])
				return
			if not game_state.WATER_FEATURE_TYPES.has(tile.water_feature):
				_fail("Invalid public water_feature at %d,%d: %s." % [x, y, tile.water_feature])
				return
			if not game_state.FOREST_LEVEL_TYPES.has(tile.forest_level):
				_fail("Invalid forest_level at %d,%d: %s." % [x, y, tile.forest_level])
				return
			if not game_state.get_allowed_forest_levels_for_climate(tile.climate_type).has(tile.forest_level):
				_fail("Forest level %s is not allowed for climate %s at %d,%d." % [tile.forest_level, tile.climate_type, x, y])
				return
			if not (tile.vegetation_resources is Array):
				_fail("vegetation_resources is not an Array at %d,%d." % [x, y])
				return
			if not game_state.SETTLEMENT_TYPES.has(tile.settlement_type):
				_fail("Invalid settlement_type at %d,%d: %s." % [x, y, tile.settlement_type])
				return

			var allowed_resources: Array = game_state.get_allowed_vegetation_resources_for_climate(tile.climate_type)
			for resource_id in tile.vegetation_resources:
				if not allowed_resources.has(str(resource_id)):
					_fail("Vegetation resource %s is not allowed for climate %s at %d,%d." % [str(resource_id), tile.climate_type, x, y])
					return

			if tile.climate_type == game_state.CLIMATE_SEA:
				if tile.forest_level != game_state.FOREST_NO:
					_fail("Sea climate has forest at %d,%d." % [x, y])
					return
				if not tile.vegetation_resources.is_empty():
					_fail("Sea climate has vegetation resources at %d,%d." % [x, y])
					return
				if tile.water_feature != game_state.WATER_SEA:
					_fail("Sea climate should use sea water_feature at %d,%d." % [x, y])
					return

			if tile.climate_type == game_state.CLIMATE_POLAR:
				if tile.forest_level != game_state.FOREST_NO:
					_fail("Polar climate has forest at %d,%d." % [x, y])
					return
				if not tile.vegetation_resources.is_empty():
					_fail("Polar climate has vegetation resources at %d,%d." % [x, y])
					return

			if tile.has_camp and tile.settlement_type != game_state.SETTLEMENT_CAMP:
				_fail("Camp tile does not expose settlement_type camp at %d,%d." % [x, y])
				return

	await _check_global_ui_public_fields(game_state)

	print("Global tile public fields 0.003 test passed.")
	quit(0)


func _check_vegetation_resource_ownership(game_state) -> void:
	var resource_owners: Dictionary = {}
	for climate_type in game_state.CLIMATE_TYPES:
		for resource_id in game_state.get_allowed_vegetation_resources_for_climate(climate_type):
			var resource_text := str(resource_id)
			if resource_owners.has(resource_text):
				_fail("Vegetation resource %s is shared by %s and %s." % [resource_text, str(resource_owners[resource_text]), str(climate_type)])
				return

			resource_owners[resource_text] = climate_type


func _check_camp_settlement_compatibility(game_state) -> void:
	var tile = game_state.get_tile(1, 1)
	if tile == null:
		_fail("Cannot check camp settlement compatibility: tile 1,1 is missing.")
		return

	tile.has_camp = true
	tile.settlement_type = game_state.SETTLEMENT_NONE
	game_state.normalize_public_tile_fields(tile)
	if tile.settlement_type != game_state.SETTLEMENT_CAMP:
		_fail("has_camp true should expose settlement_type camp.")
		return


func _check_global_ui_public_fields(game_state) -> void:
	var packed_scene = load("res://scenes/GlobalMapScene.tscn")
	if packed_scene == null:
		_fail("Cannot load GlobalMapScene.")
		return

	var scene = packed_scene.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame

	game_state.select_tile(game_state.get_tile(1, 1))
	scene.call("_update_info")

	var terrain_label = scene.get("terrain_label")
	var visited_label = scene.get("visited_label")
	var camp_label = scene.get("camp_label")
	var local_grid_label = scene.get("local_grid_label")
	var settlement_label = scene.get("settlement_label")

	if terrain_label != null and terrain_label.get_parent() != null:
		_fail("terrain_label should not be public in GlobalMapScene.")
		return
	if visited_label != null and visited_label.get_parent() != null:
		_fail("visited_label should not be public in GlobalMapScene.")
		return
	if camp_label != null and camp_label.get_parent() != null:
		_fail("camp_label should not be public in GlobalMapScene.")
		return
	if local_grid_label != null and local_grid_label.get_parent() != null:
		_fail("local_grid_label should not be public in GlobalMapScene.")
		return
	if settlement_label == null or settlement_label.get_parent() == null:
		_fail("settlement_label should be visible in GlobalMapScene.")
		return

	var tile_buttons: Array = scene.get("tile_buttons")
	if tile_buttons.is_empty():
		_fail("GlobalMapScene has no tile buttons.")
		return

	var tooltip := str(tile_buttons[0].tooltip_text)
	for forbidden_text in ["Тип:", "visited", "Локальная", "Лагерь:", "Плодородие", "Опасность"]:
		if tooltip.contains(forbidden_text):
			_fail("Global tile tooltip still exposes forbidden text: %s." % forbidden_text)
			return

	root.remove_child(scene)
	scene.free()


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
