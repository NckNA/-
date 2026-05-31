extends CanvasLayer

@export var map_manager_path: NodePath
@onready var map_manager = get_node(map_manager_path)

@onready var coords_label = $Panel/VBoxContainer/CoordsLabel
@onready var terrain_label = $Panel/VBoxContainer/TerrainLabel
@onready var resource_label = $Panel/VBoxContainer/ResourceLabel
@onready var zone_label = $Panel/VBoxContainer/ZoneLabel
@onready var occupied_label = $Panel/VBoxContainer/OccupiedLabel
@onready var building_label = $Panel/VBoxContainer/BuildingLabel
@onready var action_label = $Panel/VBoxContainer/ActionLabel
@onready var resources_label = $ResourcesPanel/ResourcesLabel

func _ready():
	map_manager.tile_selected.connect(_on_tile_selected)
	map_manager.resources_updated.connect(_on_resources_updated)
	update_info(null)

func _on_tile_selected(tile_data):
	update_info(tile_data)

func _on_resources_updated(resources):
	resources_label.text = "Wood: %d\nStone: %d\nIron: %d" % [
		resources["wood"],
		resources["stone"],
		resources["iron"]
	]

func update_info(tile_data):
	if tile_data:
		coords_label.text = "Coords: (%d, %d)" % [tile_data.grid_x, tile_data.grid_y]
		terrain_label.text = "Terrain: " + tile_data.terrain_type
		resource_label.text = "Resource: " + tile_data.resource_type
		zone_label.text = "Zone ID: " + str(tile_data.resource_zone_id)
		occupied_label.text = "Occupied: " + str(tile_data.occupied)
		building_label.text = "Building: %s (Zone: %d)" % [tile_data.building_type, tile_data.building_resource_zone_id]
	else:
		coords_label.text = "Coords: None"
		terrain_label.text = "Terrain: -"
		resource_label.text = "Resource: -"
		zone_label.text = "Zone ID: -"
		occupied_label.text = "Occupied: -"
		building_label.text = "Building: -"

func _on_build_mine_pressed():
	action_label.text = map_manager.build("mine")

func _on_build_lumber_camp_pressed():
	action_label.text = map_manager.build("lumber_camp")

func _on_build_quarry_pressed():
	action_label.text = map_manager.build("quarry")
