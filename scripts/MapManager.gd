extends Node

const MAP_WIDTH = 48
const MAP_HEIGHT = 32
const CELL_SIZE = 32

signal tile_selected(tile_data)
signal map_updated

var map_data = {} # Dictionary of Vector2i -> TileData
var selected_tile_coords = Vector2i(-1, -1)

func _ready():
	generate_map()

func generate_map():
	# 1. Fill with plain terrain
	for y in range(MAP_HEIGHT):
		for x in range(MAP_WIDTH):
			map_data[Vector2i(x, y)] = TileData.new(x, y, "plain", "none", -1)

	# 2. Forest area (deterministic)
	# Let's put a forest in the top-left quadrant
	for y in range(2, 12):
		for x in range(2, 12):
			var tile = map_data[Vector2i(x, y)]
			tile.terrain_type = "forest"
			tile.resource_type = "wood"
			tile.resource_zone_id = 100

	# 3. Stone resource zone
	# Let's put stone in the bottom-left
	for y in range(20, 26):
		for x in range(5, 11):
			var tile = map_data[Vector2i(x, y)]
			tile.terrain_type = "hill"
			tile.resource_type = "stone"
			tile.resource_zone_id = 200

	# 4. Two separate iron resource zones
	# Iron zone 1 (top-right)
	for y in range(5, 8):
		for x in range(35, 38):
			var tile = map_data[Vector2i(x, y)]
			tile.terrain_type = "mountain"
			tile.resource_type = "iron"
			tile.resource_zone_id = 301

	# Iron zone 2 (bottom-right)
	for y in range(22, 25):
		for x in range(38, 41):
			var tile = map_data[Vector2i(x, y)]
			tile.terrain_type = "mountain"
			tile.resource_type = "iron"
			tile.resource_zone_id = 302

	# 5. Water (some visual variety)
	for x in range(0, MAP_WIDTH):
		var y = 15 + int(3 * sin(x * 0.2))
		if Vector2i(x, y) in map_data:
			map_data[Vector2i(x, y)].terrain_type = "water"
		if Vector2i(x, y+1) in map_data:
			map_data[Vector2i(x, y+1)].terrain_type = "water"

	# 6. Mountains (more variety)
	for y in range(0, 5):
		for x in range(20, 25):
			var tile = map_data[Vector2i(x, y)]
			if tile.terrain_type == "plain":
				tile.terrain_type = "mountain"

	map_updated.emit()

func get_tile_at_coords(coords: Vector2i) -> TileData:
	if coords in map_data:
		return map_data[coords]
	return null

func select_tile(coords: Vector2i):
	if coords in map_data:
		selected_tile_coords = coords
		tile_selected.emit(map_data[coords])
	else:
		selected_tile_coords = Vector2i(-1, -1)
		tile_selected.emit(null)

func build(building_type: String) -> String:
	if selected_tile_coords == Vector2i(-1, -1):
		return "No tile selected."

	var tile = map_data[selected_tile_coords]

	if tile.occupied:
		return "Tile is already occupied."

	match building_type:
		"mine":
			if tile.resource_type != "iron":
				return "Mines can only be built on iron."
			tile.building_type = "mine"
		"lumber_camp":
			if tile.terrain_type != "forest" and tile.resource_type != "wood":
				return "Lumber camps can only be built on forest/wood."
			tile.building_type = "lumber_camp"
		"quarry":
			if tile.resource_type != "stone":
				return "Quarries can only be built on stone."
			tile.building_type = "quarry"
		_:
			return "Unknown building type."

	tile.occupied = true
	tile.building_resource_zone_id = tile.resource_zone_id
	map_updated.emit()
	tile_selected.emit(tile) # Refresh UI
	return "Built " + building_type + " successfully."
