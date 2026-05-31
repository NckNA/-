extends Node

const GameTileDataScript := preload("res://data/GameTileData.gd")
const PlayerDataScript := preload("res://data/PlayerData.gd")
const SAVE_PATH := "user://save_game.json"


func save_game() -> bool:
	GameState.initialize_tutorial_goals()
	GameState.add_journal_entry("system", "Игра сохранена")

	var save_data := {
		"map_width": GameState.map_width,
		"map_height": GameState.map_height,
		"day": GameState.day,
		"hour": GameState.hour,
		"tiles": _get_tiles_save_data(),
		"selected_tile": _get_selected_tile_save_data(),
		"player_data": _get_player_save_data(),
		"journal_entries": GameState.journal_entries,
		"tutorial_goals": GameState.tutorial_goals
	}

	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		print("Не удалось открыть файл сохранения.")
		return false

	file.store_string(JSON.stringify(save_data, "\t"))
	print("Игра сохранена: %s" % SAVE_PATH)
	return true


func load_game() -> bool:
	if not has_save():
		print("Сохранение не найдено.")
		return false

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		print("Не удалось прочитать файл сохранения.")
		return false

	var json_text := file.get_as_text()
	var json := JSON.new()
	var error := json.parse(json_text)

	if error != OK:
		print("Ошибка чтения JSON сохранения.")
		return false

	var save_data = json.data
	if not save_data is Dictionary:
		print("Файл сохранения имеет неверный формат.")
		return false

	_restore_game_state(save_data)
	GameState.add_journal_entry("system", "Сохранение загружено", "Мир восстановлен")
	print("Игра загружена: %s" % SAVE_PATH)
	return true


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func delete_save() -> bool:
	if not has_save():
		print("Сохранение уже отсутствует.")
		return false

	var dir := DirAccess.open("user://")
	if dir == null:
		print("Не удалось открыть папку сохранений.")
		return false

	var error := dir.remove("save_game.json")
	if error != OK:
		print("Не удалось удалить сохранение.")
		return false

	print("Сохранение удалено.")
	return true


func _get_tiles_save_data() -> Array:
	var saved_rows: Array = []

	for row in GameState.tiles:
		var saved_row: Array = []

		for tile_data in row:
			saved_row.append({
				"x": tile_data.x,
				"y": tile_data.y,
				"terrain_type": tile_data.terrain_type,
				"danger_level": tile_data.danger_level,
				"climate_type": tile_data.climate_type,
				"relief_type": tile_data.relief_type,
				"vegetation_type": tile_data.vegetation_type,
				"water_feature": tile_data.water_feature,
				"soil_fertility": tile_data.soil_fertility,
				"forest_level": tile_data.forest_level,
				"vegetation_resources": tile_data.vegetation_resources,
				"settlement_type": tile_data.settlement_type,
				"control_owner": tile_data.control_owner,
				"has_camp": tile_data.has_camp,
				"visited": tile_data.visited,
				"selected": tile_data.selected,
				"local_resources": tile_data.local_resources,
				"local_grid": tile_data.local_grid,
				"camp_storage": tile_data.camp_storage,
				"camp_upgrades": tile_data.camp_upgrades
			})

		saved_rows.append(saved_row)

	return saved_rows


func _get_selected_tile_save_data():
	if GameState.selected_tile == null:
		return null

	return {
		"x": GameState.selected_tile.x,
		"y": GameState.selected_tile.y
	}


func _get_player_save_data() -> Dictionary:
	GameState.initialize_player_data()

	return {
		"name": GameState.player_data.name,
		"global_x": GameState.player_data.global_x,
		"global_y": GameState.player_data.global_y,
		"health": GameState.player_data.health,
		"hunger": GameState.player_data.hunger,
		"energy": GameState.player_data.energy,
		"inventory": GameState.player_data.inventory,
		"skills": GameState.player_data.skills
	}


func _restore_game_state(save_data: Dictionary) -> void:
	GameState.map_width = int(save_data.get("map_width", 24))
	GameState.map_height = int(save_data.get("map_height", 16))
	GameState.day = int(save_data.get("day", 1))
	GameState.hour = int(save_data.get("hour", 8))
	GameState.tiles.clear()
	GameState.selected_tile = null
	GameState.player_data = _restore_player_data(save_data.get("player_data", {}))
	GameState.journal_entries = _restore_journal_entries(save_data.get("journal_entries", []))
	GameState.tutorial_goals = _restore_tutorial_goals(save_data.get("tutorial_goals", {}))
	GameState.initialize_tutorial_goals()

	var saved_tiles: Array = save_data.get("tiles", [])

	for saved_row in saved_tiles:
		var row: Array = []

		for saved_tile in saved_row:
			var tile_data = GameTileDataScript.new(
				int(saved_tile.get("x", 0)),
				int(saved_tile.get("y", 0)),
				str(saved_tile.get("terrain_type", GameState.TERRAIN_PLAINS))
			)
			tile_data.danger_level = int(saved_tile.get(
				"danger_level",
				GameState.get_default_danger_for_terrain(tile_data.terrain_type)
			))
			if not saved_tile.has("climate_type") or not saved_tile.has("relief_type") or not saved_tile.has("vegetation_type") or not saved_tile.has("water_feature"):
				GameState.configure_natural_features_for_tile(tile_data)

			tile_data.climate_type = GameState.normalize_climate_type(
				str(saved_tile.get("climate_type", tile_data.climate_type)),
				tile_data.y,
				tile_data.terrain_type,
				str(saved_tile.get("water_feature", tile_data.water_feature))
			)
			tile_data.relief_type = GameState.normalize_relief_type(str(saved_tile.get("relief_type", tile_data.relief_type)))
			tile_data.vegetation_type = str(saved_tile.get("vegetation_type", tile_data.vegetation_type))
			tile_data.water_feature = GameState.normalize_water_feature(str(saved_tile.get("water_feature", tile_data.water_feature)), tile_data.climate_type)
			tile_data.soil_fertility = int(clamp(int(saved_tile.get("soil_fertility", tile_data.soil_fertility)), 0, 5))
			tile_data.has_camp = bool(saved_tile.get("has_camp", false))
			tile_data.settlement_type = str(saved_tile.get("settlement_type", GameState.SETTLEMENT_CAMP if tile_data.has_camp else GameState.SETTLEMENT_NONE))
			tile_data.control_owner = str(saved_tile.get("control_owner", GameState.CONTROL_NONE))
			tile_data.forest_level = str(saved_tile.get("forest_level", GameState.FOREST_NO))
			var saved_vegetation_resources = saved_tile.get("vegetation_resources", [])
			if saved_vegetation_resources is Array:
				tile_data.vegetation_resources = saved_vegetation_resources
			else:
				tile_data.vegetation_resources = []
			GameState.normalize_public_tile_fields(tile_data)
			tile_data.visited = bool(saved_tile.get("visited", false))
			tile_data.selected = false
			tile_data.local_resources = _restore_local_resources(saved_tile.get("local_resources", []))
			tile_data.local_grid = _restore_local_grid(saved_tile.get("local_grid", []))
			tile_data.camp_storage = _restore_item_dictionary(saved_tile.get("camp_storage", {}))
			tile_data.camp_upgrades = _restore_camp_upgrades(saved_tile.get("camp_upgrades", {}))
			row.append(tile_data)

		GameState.tiles.append(row)

	var selected_save_data = save_data.get("selected_tile", null)
	if selected_save_data is Dictionary:
		var selected_x := int(selected_save_data.get("x", -1))
		var selected_y := int(selected_save_data.get("y", -1))
		GameState.select_tile(GameState.get_tile(selected_x, selected_y))


func _restore_player_data(saved_player_data) -> Resource:
	var player_data = PlayerDataScript.new()

	if not saved_player_data is Dictionary:
		player_data.ensure_skills_initialized()
		return player_data

	player_data.name = str(saved_player_data.get("name", "Игрок"))
	player_data.global_x = int(saved_player_data.get("global_x", 0))
	player_data.global_y = int(saved_player_data.get("global_y", 0))
	player_data.health = int(saved_player_data.get("health", 100))
	player_data.hunger = int(saved_player_data.get("hunger", 0))
	player_data.energy = int(saved_player_data.get("energy", 100))

	var saved_inventory = saved_player_data.get("inventory", {})
	if saved_inventory is Dictionary:
		player_data.inventory = saved_inventory

	var saved_skills = saved_player_data.get("skills", {})
	if saved_skills is Dictionary:
		player_data.skills = saved_skills

	player_data.ensure_skills_initialized()

	return player_data


func _restore_local_resources(saved_resources) -> Array:
	var restored_resources: Array = []

	if not saved_resources is Array:
		return restored_resources

	for saved_resource in saved_resources:
		if not saved_resource is Dictionary:
			continue

		restored_resources.append({
			"id": str(saved_resource.get("id", "")),
			"type": str(saved_resource.get("type", "")),
			"x": float(saved_resource.get("x", 0.0)),
			"y": float(saved_resource.get("y", 0.0)),
			"amount": int(saved_resource.get("amount", 0))
		})

	return restored_resources


func _restore_local_grid(saved_grid) -> Array:
	var restored_grid: Array = []

	if not saved_grid is Array:
		return restored_grid

	for saved_cell in saved_grid:
		if not saved_cell is Dictionary:
			continue

		restored_grid.append({
			"x": int(saved_cell.get("x", 0)),
			"y": int(saved_cell.get("y", 0)),
			"terrain_type": str(saved_cell.get("terrain_type", GameState.TERRAIN_PLAINS)),
			"zone_type": str(saved_cell.get("zone_type", "none")),
			"building_id": str(saved_cell.get("building_id", "")),
			"resource_type": str(saved_cell.get("resource_type", "")),
			"resource_amount": int(saved_cell.get("resource_amount", 0)),
			"blocked": bool(saved_cell.get("blocked", false)),
			"reserved": bool(saved_cell.get("reserved", false)),
			"land_value": int(saved_cell.get("land_value", 1)),
			"land_status": str(saved_cell.get("land_status", "poor"))
		})

	return restored_grid


func _restore_item_dictionary(saved_items) -> Dictionary:
	var restored_items: Dictionary = {}

	if not saved_items is Dictionary:
		return restored_items

	for item_name in saved_items.keys():
		var amount := int(saved_items[item_name])
		if amount > 0:
			restored_items[str(item_name)] = amount

	return restored_items


func _restore_camp_upgrades(saved_upgrades) -> Dictionary:
	var restored_upgrades: Dictionary = {}

	if not saved_upgrades is Dictionary:
		return restored_upgrades

	for upgrade_name in saved_upgrades.keys():
		restored_upgrades[str(upgrade_name)] = bool(saved_upgrades[upgrade_name])

	return restored_upgrades


func _restore_journal_entries(saved_entries) -> Array:
	var restored_entries: Array = []

	if not saved_entries is Array:
		return restored_entries

	for saved_entry in saved_entries:
		if not saved_entry is Dictionary:
			continue

		restored_entries.append({
			"day": int(saved_entry.get("day", 1)),
			"hour": int(saved_entry.get("hour", 8)),
			"category": str(saved_entry.get("category", "system")),
			"priority": str(saved_entry.get("priority", "normal")),
			"title": str(saved_entry.get("title", "")),
			"description": str(saved_entry.get("description", ""))
		})

	while restored_entries.size() > 100:
		restored_entries.pop_front()

	return restored_entries


func _restore_tutorial_goals(saved_goals) -> Dictionary:
	var restored_goals: Dictionary = {}

	for goal_id in GameState.TUTORIAL_GOAL_ORDER:
		restored_goals[goal_id] = false

	if not saved_goals is Dictionary:
		return restored_goals

	for goal_id in GameState.TUTORIAL_GOAL_ORDER:
		restored_goals[goal_id] = bool(saved_goals.get(goal_id, false))

	return restored_goals
