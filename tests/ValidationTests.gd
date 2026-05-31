extends SceneTree

const PrototypeTileData = preload("res://scripts/PrototypeTileData.gd")

func _init():
	print("Starting Validation Tests...")

	var map_manager = load("res://scripts/MapManager.gd").new()
	map_manager._ready() # Initialize map

	var success = true

	# 1. Map width is 48
	if map_manager.MAP_WIDTH == 48:
		print("[PASS] Map width is 48")
	else:
		print("[FAIL] Map width is ", map_manager.MAP_WIDTH)
		success = false

	# 2. Map height is 32
	if map_manager.MAP_HEIGHT == 32:
		print("[PASS] Map height is 32")
	else:
		print("[FAIL] Map height is ", map_manager.MAP_HEIGHT)
		success = false

	# 3. Cell size is 32
	if map_manager.CELL_SIZE == 32:
		print("[PASS] Cell size is 32")
	else:
		print("[FAIL] Cell size is ", map_manager.CELL_SIZE)
		success = false

	# 4. There are at least two iron resource zones
	var iron_zones = {}
	for coords in map_manager.map_data:
		var tile = map_manager.map_data[coords]
		if tile.resource_type == "iron":
			iron_zones[tile.resource_zone_id] = true

	if iron_zones.size() >= 2:
		print("[PASS] Found %d iron zones" % iron_zones.size())
	else:
		print("[FAIL] Found only %d iron zones" % iron_zones.size())
		success = false

	# 5. Mine can be built on iron
	var iron_tile_coords = Vector2i(-1, -1)
	for coords in map_manager.map_data:
		var tile = map_manager.map_data[coords]
		if tile.resource_type == "iron":
			iron_tile_coords = coords
			break

	map_manager.select_tile(iron_tile_coords)
	var res = map_manager.build("mine")
	if "successfully" in res and map_manager.map_data[iron_tile_coords].building_type == "mine":
		print("[PASS] Mine built on iron")
	else:
		print("[FAIL] Could not build mine on iron: ", res)
		success = false

	# 6. Mine cannot be built on plain/forest/stone without iron
	var plain_tile_coords = Vector2i(-1, -1)
	for coords in map_manager.map_data:
		if map_manager.map_data[coords].terrain_type == "plain" and map_manager.map_data[coords].resource_type == "none":
			plain_tile_coords = coords
			break

	map_manager.select_tile(plain_tile_coords)
	res = map_manager.build("mine")
	if "only" in res:
		print("[PASS] Mine cannot be built on plain")
	else:
		print("[FAIL] Mine was built on plain or wrong error: ", res)
		success = false

	# 7. Lumber camp can be built on forest
	var forest_tile_coords = Vector2i(-1, -1)
	for coords in map_manager.map_data:
		if map_manager.map_data[coords].terrain_type == "forest":
			forest_tile_coords = coords
			break

	map_manager.select_tile(forest_tile_coords)
	res = map_manager.build("lumber_camp")
	if "successfully" in res:
		print("[PASS] Lumber camp built on forest")
	else:
		print("[FAIL] Could not build lumber camp on forest: ", res)
		success = false

	# 8. Quarry can be built on stone
	var stone_tile_coords = Vector2i(-1, -1)
	for coords in map_manager.map_data:
		if map_manager.map_data[coords].resource_type == "stone":
			stone_tile_coords = coords
			break

	map_manager.select_tile(stone_tile_coords)
	res = map_manager.build("quarry")
	if "successfully" in res:
		print("[PASS] Quarry built on stone")
	else:
		print("[FAIL] Could not build quarry on stone: ", res)
		success = false

	# 9. Cannot build twice on same tile
	res = map_manager.build("quarry")
	if "already occupied" in res:
		print("[PASS] Cannot build twice on same tile")
	else:
		print("[FAIL] Allowed building twice or wrong error: ", res)
		success = false

	# 10. Building keeps resource_zone_id of its tile
	var tile = map_manager.map_data[stone_tile_coords]
	if tile.building_type == "quarry" and tile.resource_zone_id == 200:
		print("[PASS] Building keeps resource_zone_id")
	else:
		print("[FAIL] Building lost resource_zone_id or wrong building")
		success = false

	# 11. Resource accumulation works
	# We already built a mine, a lumber camp, and a quarry in previous tests.
	# Let's call _process manually to simulate 1 second pass.
	map_manager._process(1.1)
	if map_manager.global_resources["iron"] == 1 and map_manager.global_resources["stone"] == 1 and map_manager.global_resources["wood"] == 1:
		print("[PASS] Resource accumulation works")
	else:
		print("[FAIL] Resource accumulation failed. Wood: %d, Stone: %d, Iron: %d" % [map_manager.global_resources["wood"], map_manager.global_resources["stone"], map_manager.global_resources["iron"]])
		success = false

	if success:
		print("ALL TESTS PASSED!")
	else:
		print("SOME TESTS FAILED!")

	quit()
