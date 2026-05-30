extends Resource
class_name TileData

@export var grid_x: int = 0
@export var grid_y: int = 0
@export var terrain_type: String = "plain" # plain, forest, hill, water, mountain
@export var resource_type: String = "none" # none, wood, stone, iron
@export var resource_zone_id: int = -1
@export var occupied: bool = false
@export var building_type: String = "none" # none, mine, lumber_camp, quarry
@export var building_resource_zone_id: int = -1
