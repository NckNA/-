extends Resource
class_name GameTileData

var x: int = 0
var y: int = 0
var terrain_type: String = "plains"
var danger_level: int = 0
var climate_type: String = "continental"
var relief_type: String = "plains"
var vegetation_type: String = "grassland"
var water_feature: String = "none"
var soil_fertility: int = 1
var forest_level: String = "no_forest"
var vegetation_resources: Array = []
var settlement_type: String = "none"
var control_owner: String = "none"
var has_camp: bool = false
var visited: bool = false
var selected: bool = false
var local_resources: Array = []
var local_grid: Array = []
var camp_storage: Dictionary = {}
var camp_upgrades: Dictionary = {}


func _init(new_x: int = 0, new_y: int = 0, new_terrain_type: String = "plains") -> void:
	x = new_x
	y = new_y
	terrain_type = new_terrain_type
	danger_level = 0
	climate_type = "continental"
	relief_type = "plains"
	vegetation_type = "grassland"
	water_feature = "none"
	soil_fertility = 1
	forest_level = "no_forest"
	vegetation_resources = []
	settlement_type = "none"
	control_owner = "none"
	local_resources = []
	local_grid = []
	camp_storage = {}
	camp_upgrades = {}


func ensure_local_grid_initialized(width: int, height: int) -> void:
	if local_grid.size() == width * height:
		_ensure_local_grid_cell_defaults()
		return

	local_grid = []

	for cell_y in range(height):
		for cell_x in range(width):
			var cell := {
				"x": cell_x,
				"y": cell_y,
				"terrain_type": terrain_type,
				"zone_type": "none",
				"building_id": "",
				"resource_type": "",
				"resource_amount": 0,
				"blocked": false,
				"reserved": false,
				"land_value": 1,
				"land_status": "poor"
			}

			if terrain_type == "water":
				cell["blocked"] = true
				cell["land_value"] = 0
				cell["land_status"] = "blocked"

			local_grid.append(cell)


func _ensure_local_grid_cell_defaults() -> void:
	for index in range(local_grid.size()):
		var cell = local_grid[index]
		if not cell is Dictionary:
			continue

		var cell_data: Dictionary = cell
		if not cell_data.has("zone_type"):
			cell_data["zone_type"] = "none"
		if not cell_data.has("building_id"):
			cell_data["building_id"] = ""
		if not cell_data.has("resource_type"):
			cell_data["resource_type"] = ""
		if not cell_data.has("resource_amount"):
			cell_data["resource_amount"] = 0
		if not cell_data.has("blocked"):
			cell_data["blocked"] = false
		if not cell_data.has("reserved"):
			cell_data["reserved"] = false
		if not cell_data.has("land_value"):
			cell_data["land_value"] = calculate_base_land_value_for_cell(cell_data)
		if not cell_data.has("land_status"):
			cell_data["land_status"] = calculate_land_status(int(cell_data.get("land_value", 1)))

		local_grid[index] = cell_data


func get_local_cell(cell_x: int, cell_y: int, width: int) -> Dictionary:
	if cell_x < 0 or cell_y < 0:
		return {}
	if cell_x >= width:
		return {}

	var index := cell_y * width + cell_x
	if index < 0 or index >= local_grid.size():
		return {}

	return local_grid[index]


func set_local_cell(cell_x: int, cell_y: int, width: int, cell_data: Dictionary) -> void:
	if cell_x < 0 or cell_y < 0:
		return
	if cell_x >= width:
		return

	var index := cell_y * width + cell_x
	if index < 0 or index >= local_grid.size():
		return

	local_grid[index] = cell_data


func is_local_cell_free_for_building(cell_x: int, cell_y: int, width: int) -> bool:
	var cell := get_local_cell(cell_x, cell_y, width)
	if cell.is_empty():
		return false
	if bool(cell.get("blocked", false)):
		return false
	if bool(cell.get("reserved", false)):
		return false
	if str(cell.get("building_id", "")) != "":
		return false

	return true


func set_zone_for_cell(cell_x: int, cell_y: int, width: int, zone_type: String) -> bool:
	var cell := get_local_cell(cell_x, cell_y, width)
	if cell.is_empty():
		return false
	if bool(cell.get("blocked", false)):
		return false

	cell["zone_type"] = zone_type
	cell["land_value"] = calculate_base_land_value_for_cell(cell)
	cell["land_status"] = calculate_land_status(int(cell["land_value"]))
	set_local_cell(cell_x, cell_y, width, cell)
	return true


func calculate_base_land_value_for_cell(cell: Dictionary) -> int:
	var value := 1
	var cell_zone_type := str(cell.get("zone_type", "none"))

	match cell_zone_type:
		"residential":
			value += 1
		"craft":
			value += 1
		"trade":
			value += 2
		"agriculture":
			value += 1
		"extraction":
			value += 1
		"forestry":
			value += 1
		"administration":
			value += 3
		"military":
			value += 2

	if bool(cell.get("blocked", false)):
		value = 0

	return value


func calculate_land_status(value: int) -> String:
	if value <= 0:
		return "blocked"
	if value <= 2:
		return "poor"
	if value <= 4:
		return "common"
	if value <= 6:
		return "good"

	return "prestige"


func get_zoned_cells_count() -> int:
	var count := 0
	for cell in local_grid:
		if str(cell.get("zone_type", "none")) != "none":
			count += 1

	return count


func ensure_local_resources_generated() -> void:
	if not local_resources.is_empty():
		return

	match terrain_type:
		"forest":
			_generate_forest_resources()
		"plains":
			_generate_plains_resources()
		"wasteland":
			_generate_wasteland_resources()


func _generate_forest_resources() -> void:
	_add_local_resource("tree_1", "tree", Vector2(160, 120), 1)
	_add_local_resource("tree_2", "tree", Vector2(260, 230), 1)
	_add_local_resource("tree_3", "tree", Vector2(640, 160), 1)
	_add_local_resource("tree_4", "tree", Vector2(720, 420), 1)
	_add_local_resource("tree_5", "tree", Vector2(380, 460), 1)
	_add_local_resource("berry_bush_1", "berry_bush", Vector2(260, 390), 1)
	_add_local_resource("berry_bush_2", "berry_bush", Vector2(560, 330), 1)
	_add_local_resource("stone_1", "stone", Vector2(470, 180), 1)
	_add_local_resource("stone_2", "stone", Vector2(690, 300), 1)


func _generate_plains_resources() -> void:
	_add_local_resource("berry_bush_1", "berry_bush", Vector2(180, 180), 1)
	_add_local_resource("berry_bush_2", "berry_bush", Vector2(650, 260), 1)


func _generate_wasteland_resources() -> void:
	_add_local_resource("stone_1", "stone", Vector2(140, 160), 1)
	_add_local_resource("stone_2", "stone", Vector2(320, 360), 1)
	_add_local_resource("stone_3", "stone", Vector2(590, 210), 1)
	_add_local_resource("stone_4", "stone", Vector2(720, 430), 1)


func _add_local_resource(resource_id: String, resource_type: String, resource_position: Vector2, amount: int) -> void:
	local_resources.append({
		"id": resource_id,
		"type": resource_type,
		"x": resource_position.x,
		"y": resource_position.y,
		"amount": amount
	})
