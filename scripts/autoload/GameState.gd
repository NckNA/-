extends Node

const GameTileDataScript := preload("res://data/GameTileData.gd")
const PlayerDataScript := preload("res://data/PlayerData.gd")

const GAME_VERSION := "0.003-dev"
const GAME_TITLE := "Владение"
const GLOBAL_TEXTURE_CONTINENTAL_PLAINS := "res://assets/textures/global/continental_plains.png"

const TERRAIN_FOREST := "forest"
const TERRAIN_PLAINS := "plains"
const TERRAIN_WASTELAND := "wasteland"
const TERRAIN_WATER := "water"
const CLIMATE_ARID := "arid"
const CLIMATE_CONTINENTAL := "continental"
const CLIMATE_DESERT := "desert"
const CLIMATE_NORDIC := "nordic"
const CLIMATE_MEDITERRANEAN := "mediterranean"
const CLIMATE_OCEANIC := "oceanic"
const CLIMATE_POLAR := "polar"
const CLIMATE_SEA := "sea"
const CLIMATE_TROPICAL := "tropical"
const CLIMATE_STEPPE := "steppe"
const RELIEF_FLAT := "flat"
const RELIEF_PLAINS := "plains"
const RELIEF_ROCKY := "rocky"
const RELIEF_HILLS := "hills"
const RELIEF_MOUNTAINS := "mountains"
const RELIEF_PLATEAU := "plateau"
const RELIEF_LOWLAND := "lowland"
const RELIEF_FOOTHILLS := "foothills"
const RELIEF_CANYON := "canyon"
const FOREST_NO := "no_forest"
const FOREST_SPARSE := "sparse_forest"
const FOREST_MEDIUM := "medium_forest"
const FOREST_MASSIF := "forest_massif"
const VEGETATION_NONE := "none"
const VEGETATION_FOREST := "forest"
const VEGETATION_STEPPE := "steppe"
const VEGETATION_GRASSLAND := "grassland"
const VEGETATION_SHRUBS := "shrubs"
const VEGETATION_SPARSE_FOREST := "sparse_forest"
const VEGETATION_TAIGA := "taiga"
const VEGETATION_TUNDRA := "tundra"
const VEGETATION_JUNGLE := "jungle"
const VEGETATION_SAVANNA := "savanna"
const VEGETATION_WASTELAND := "wasteland"
const WATER_NONE := "none"
const WATER_STREAM := "stream"
const WATER_SMALL_RIVER := "small_river"
const WATER_MEDIUM_RIVER := "medium_river"
const WATER_LARGE_RIVER := "large_river"
const WATER_LAKE := "lake"
const WATER_SWAMP := "swamp"
const WATER_POND := "pond"
const WATER_SPRING := "spring"
const WATER_COAST := "coast"
const WATER_SEA := "sea"
const WATER_OASIS := "oasis"
const SETTLEMENT_NONE := "none"
const SETTLEMENT_CAMP := "camp"
const SETTLEMENT_HAMLET := "hamlet"
const SETTLEMENT_VILLAGE := "village"
const SETTLEMENT_TOWN := "town"
const SETTLEMENT_CITY := "city"
const SETTLEMENT_FORTRESS := "fortress"
const CONTROL_NONE := "none"
const ZONE_NONE := "none"
const ZONE_RESIDENTIAL := "residential"
const ZONE_CRAFT := "craft"
const ZONE_TRADE := "trade"
const ZONE_AGRICULTURE := "agriculture"
const ZONE_EXTRACTION := "extraction"
const ZONE_FORESTRY := "forestry"
const ZONE_ADMINISTRATION := "administration"
const ZONE_MILITARY := "military"
const CAMP_WOOD_COST := 5
const CAMP_STONE_COST := 2
const CAMPFIRE_WOOD_COST := 3
const CAMPFIRE_STONE_COST := 1
const BERRY_HUNGER_RESTORE := 5
const COOK_BERRIES_INPUT := 2
const COOKED_BERRIES_OUTPUT := 1
const COOKED_BERRIES_HUNGER_RESTORE := 15
const COOKED_BERRIES_ENERGY_RESTORE := 5
const GATHER_BASE_ENERGY_COST := 3
const BUILD_CAMP_ENERGY_COST := 10
const BUILD_CAMPFIRE_ENERGY_COST := 5
const COOK_BERRIES_ENERGY_COST := 2
const QUICK_REST_HOURS := 4
const QUICK_REST_ENERGY_RESTORE := 15
const QUICK_REST_HUNGER_GAIN := 2
const LOCAL_GRID_WIDTH := 48
const LOCAL_GRID_HEIGHT := 32
const LOCAL_CELL_SIZE := 32
const CLIMATE_TYPES := [
	CLIMATE_ARID,
	CLIMATE_CONTINENTAL,
	CLIMATE_DESERT,
	CLIMATE_NORDIC,
	CLIMATE_MEDITERRANEAN,
	CLIMATE_OCEANIC,
	CLIMATE_POLAR,
	CLIMATE_SEA,
	CLIMATE_TROPICAL,
	CLIMATE_STEPPE
]
const RELIEF_TYPES := [
	RELIEF_LOWLAND,
	RELIEF_PLAINS,
	RELIEF_HILLS,
	RELIEF_FOOTHILLS,
	RELIEF_MOUNTAINS,
	RELIEF_ROCKY
]
const FOREST_LEVEL_TYPES := [
	FOREST_NO,
	FOREST_SPARSE,
	FOREST_MEDIUM,
	FOREST_MASSIF
]
const VEGETATION_TYPES := [
	VEGETATION_NONE,
	VEGETATION_FOREST,
	VEGETATION_STEPPE,
	VEGETATION_GRASSLAND,
	VEGETATION_SHRUBS,
	VEGETATION_SPARSE_FOREST,
	VEGETATION_TAIGA,
	VEGETATION_TUNDRA,
	VEGETATION_JUNGLE,
	VEGETATION_SAVANNA,
	VEGETATION_WASTELAND
]
const WATER_FEATURE_TYPES := [
	WATER_NONE,
	WATER_SMALL_RIVER,
	WATER_MEDIUM_RIVER,
	WATER_LARGE_RIVER,
	WATER_LAKE,
	WATER_SWAMP,
	WATER_OASIS,
	WATER_COAST,
	WATER_SEA
]
const SETTLEMENT_TYPES := [
	SETTLEMENT_NONE,
	SETTLEMENT_CAMP,
	SETTLEMENT_HAMLET,
	SETTLEMENT_VILLAGE,
	SETTLEMENT_TOWN,
	SETTLEMENT_CITY,
	SETTLEMENT_FORTRESS
]
const ZONE_TYPES := [
	ZONE_NONE,
	ZONE_RESIDENTIAL,
	ZONE_CRAFT,
	ZONE_TRADE,
	ZONE_AGRICULTURE,
	ZONE_EXTRACTION,
	ZONE_FORESTRY,
	ZONE_ADMINISTRATION,
	ZONE_MILITARY
]
const TUTORIAL_GOAL_ORDER := [
	"collect_wood",
	"collect_stone",
	"build_camp",
	"deposit_to_camp",
	"build_campfire",
	"cook_berries",
	"rest_at_camp"
]

var map_width: int = 24
var map_height: int = 16
var day: int = 1
var hour: int = 8
var tiles: Array = []
var selected_tile = null
var player_data = null
var journal_entries: Array = []
var tutorial_goals := {}
var global_tile_texture_cache: Dictionary = {}


func _ready() -> void:
	initialize_player_data()
	initialize_map()
	initialize_tutorial_goals()


func initialize_player_data() -> void:
	if player_data == null:
		player_data = PlayerDataScript.new()

	player_data.ensure_skills_initialized()


func initialize_map() -> void:
	initialize_player_data()

	if not tiles.is_empty():
		return

	tiles.clear()
	var world_layers := _generate_world_layers()
	var terrain_map: Array = world_layers.get("terrain", [])
	var climate_map: Array = world_layers.get("climate", [])
	var relief_map: Array = world_layers.get("relief", [])
	var vegetation_map: Array = world_layers.get("vegetation", [])
	var water_feature_map: Array = world_layers.get("water_feature", [])
	var soil_fertility_map: Array = world_layers.get("soil_fertility", [])

	for y in range(map_height):
		var row: Array = []

		for x in range(map_width):
			var terrain_type: String = str(_get_layer_value(terrain_map, x, y, TERRAIN_PLAINS))
			var tile_data = GameTileDataScript.new(x, y, terrain_type)
			tile_data.danger_level = get_default_danger_for_terrain(terrain_type)
			tile_data.climate_type = str(_get_layer_value(climate_map, x, y, CLIMATE_CONTINENTAL))
			tile_data.relief_type = normalize_relief_type(str(_get_layer_value(relief_map, x, y, RELIEF_PLAINS)))
			tile_data.vegetation_type = str(_get_layer_value(vegetation_map, x, y, VEGETATION_GRASSLAND))
			tile_data.water_feature = normalize_water_feature(str(_get_layer_value(water_feature_map, x, y, WATER_NONE)), tile_data.climate_type)
			tile_data.soil_fertility = int(_get_layer_value(soil_fertility_map, x, y, 1))
			configure_public_natural_features_for_tile(tile_data)
			row.append(tile_data)

		tiles.append(row)


func get_tile(x: int, y: int):
	if y < 0 or y >= tiles.size():
		return null

	var row: Array = tiles[y]
	if x < 0 or x >= row.size():
		return null

	return row[x]


func select_tile(tile_data) -> void:
	if selected_tile != null:
		selected_tile.selected = false

	selected_tile = tile_data

	if selected_tile != null:
		selected_tile.selected = true


func move_player_to_tile(tile_data) -> void:
	if tile_data == null:
		return

	initialize_player_data()
	player_data.global_x = tile_data.x
	player_data.global_y = tile_data.y


func start_new_game() -> void:
	if selected_tile != null:
		selected_tile.selected = false

	tiles.clear()
	selected_tile = null
	map_width = 24
	map_height = 16
	day = 1
	hour = 8
	player_data = PlayerDataScript.new()
	player_data.ensure_skills_initialized()
	journal_entries.clear()
	tutorial_goals.clear()
	initialize_map()
	initialize_tutorial_goals()
	add_journal_entry("system", "Новая игра", "Начата версия %s" % GAME_VERSION)
	add_journal_entry("system", "Цели обновлены", "Первые цели игрока сброшены")


func advance_time(hours_to_add: int = 1) -> void:
	initialize_player_data()

	for i in range(hours_to_add):
		hour += 1

		if hour >= 24:
			hour = 0
			day += 1

		if hour % 6 == 0:
			_apply_six_hour_effects()


func get_time_text() -> String:
	return "%02d:00" % hour


func get_version_text() -> String:
	return GAME_TITLE + " " + GAME_VERSION


func get_local_map_pixel_width() -> int:
	return LOCAL_GRID_WIDTH * LOCAL_CELL_SIZE


func get_local_map_pixel_height() -> int:
	return LOCAL_GRID_HEIGHT * LOCAL_CELL_SIZE


func get_zone_title(zone_type: String) -> String:
	match zone_type:
		ZONE_NONE:
			return "Нет зоны"
		ZONE_RESIDENTIAL:
			return "Жилая зона"
		ZONE_CRAFT:
			return "Ремесленная зона"
		ZONE_TRADE:
			return "Торговая зона"
		ZONE_AGRICULTURE:
			return "Сельхоз-зона"
		ZONE_EXTRACTION:
			return "Добыча"
		ZONE_FORESTRY:
			return "Лесозаготовка"
		ZONE_ADMINISTRATION:
			return "Административная зона"
		ZONE_MILITARY:
			return "Военная зона"
		_:
			return zone_type


func get_climate_title(climate_type: String) -> String:
	match climate_type:
		CLIMATE_ARID:
			return "Засушливый"
		CLIMATE_CONTINENTAL:
			return "Континентальный"
		CLIMATE_DESERT:
			return "Пустыня"
		CLIMATE_NORDIC:
			return "Нордический"
		CLIMATE_MEDITERRANEAN:
			return "Средиземноморье"
		CLIMATE_OCEANIC:
			return "Океанический"
		CLIMATE_POLAR:
			return "Полярный"
		CLIMATE_SEA:
			return "Море"
		CLIMATE_TROPICAL:
			return "Тропический"
		CLIMATE_STEPPE:
			return "Степной"
		_:
			return climate_type


func normalize_climate_type(climate_type: String, tile_y: int = -1, terrain_type: String = "", water_feature: String = "") -> String:
	if water_feature == WATER_SEA:
		return CLIMATE_SEA
	if CLIMATE_TYPES.has(climate_type):
		return climate_type
	if climate_type == "alpine" or climate_type == "highland":
		if tile_y >= 0:
			var pole_distance: int = min(tile_y, map_height - 1 - tile_y)
			if pole_distance <= 3:
				return CLIMATE_NORDIC

		return CLIMATE_CONTINENTAL

	return CLIMATE_CONTINENTAL


func normalize_relief_type(relief_type: String) -> String:
	match relief_type:
		RELIEF_LOWLAND, RELIEF_PLAINS, RELIEF_HILLS, RELIEF_FOOTHILLS, RELIEF_MOUNTAINS, RELIEF_ROCKY:
			return relief_type
		RELIEF_FLAT:
			return RELIEF_PLAINS
		RELIEF_PLATEAU:
			return RELIEF_HILLS
		RELIEF_CANYON:
			return RELIEF_ROCKY
		_:
			return RELIEF_PLAINS


func get_relief_title(relief_type: String) -> String:
	match relief_type:
		RELIEF_FLAT:
			return "Плоский"
		RELIEF_PLAINS:
			return "Равнины"
		RELIEF_ROCKY:
			return "Скалы"
		RELIEF_HILLS:
			return "Холмы"
		RELIEF_MOUNTAINS:
			return "Горы"
		RELIEF_PLATEAU:
			return "Плато"
		RELIEF_LOWLAND:
			return "Низина"
		RELIEF_FOOTHILLS:
			return "Предгорья"
		RELIEF_CANYON:
			return "Ущелье"
		_:
			return relief_type


func get_forest_level_title(forest_level: String) -> String:
	match forest_level:
		FOREST_NO:
			return "Нет леса"
		FOREST_SPARSE:
			return "Редколесье"
		FOREST_MEDIUM:
			return "Среднелесье"
		FOREST_MASSIF:
			return "Лесной массив"
		_:
			return forest_level


func get_vegetation_resource_title(resource_id: String) -> String:
	match resource_id:
		"turnip":
			return "Репа"
		"rye":
			return "Рожь"
		"cloudberry":
			return "Морошка"
		"cranberry":
			return "Клюква"
		"northern_mushrooms":
			return "Северные грибы"
		"wheat":
			return "Пшеница"
		"apples":
			return "Яблоки"
		"hops":
			return "Хмель"
		"carrot":
			return "Морковь"
		"flax":
			return "Лён"
		"barley":
			return "Ячмень"
		"cabbage":
			return "Капуста"
		"beet":
			return "Свёкла"
		"hemp":
			return "Конопля"
		"cherry":
			return "Вишня"
		"millet":
			return "Просо"
		"wormwood":
			return "Полынь"
		"wild_onion":
			return "Дикий лук"
		"licorice":
			return "Солодка"
		"safflower":
			return "Сафлор"
		"sorghum":
			return "Сорго"
		"sesame":
			return "Кунжут"
		"aloe":
			return "Алоэ"
		"cumin":
			return "Зира"
		"capers":
			return "Каперсы"
		"date_palm":
			return "Финиковая пальма"
		"saxaul":
			return "Саксаул"
		"frankincense_tree":
			return "Ладанное дерево"
		"myrrh":
			return "Мирра"
		"henna":
			return "Хна"
		"grapes":
			return "Виноград"
		"olives":
			return "Оливки"
		"figs":
			return "Инжир"
		"lavender":
			return "Лаванда"
		"saffron":
			return "Шафран"
		"rice":
			return "Рис"
		"sugarcane":
			return "Сахарный тростник"
		"cocoa":
			return "Какао"
		"cotton":
			return "Хлопок"
		"spices":
			return "Пряности"
		_:
			return resource_id


func get_allowed_forest_levels_for_climate(climate_type: String) -> Array:
	match climate_type:
		CLIMATE_POLAR, CLIMATE_SEA, CLIMATE_DESERT:
			return [FOREST_NO]
		CLIMATE_NORDIC, CLIMATE_OCEANIC, CLIMATE_CONTINENTAL:
			return [FOREST_SPARSE, FOREST_MEDIUM, FOREST_MASSIF]
		CLIMATE_STEPPE, CLIMATE_ARID:
			return [FOREST_NO, FOREST_SPARSE]
		CLIMATE_MEDITERRANEAN:
			return [FOREST_NO, FOREST_SPARSE, FOREST_MEDIUM]
		CLIMATE_TROPICAL:
			return [FOREST_MEDIUM, FOREST_MASSIF]
		_:
			return [FOREST_NO]


func get_allowed_vegetation_resources_for_climate(climate_type: String) -> Array:
	match climate_type:
		CLIMATE_NORDIC:
			return ["turnip", "rye", "cloudberry", "cranberry", "northern_mushrooms"]
		CLIMATE_OCEANIC:
			return ["wheat", "apples", "hops", "carrot", "flax"]
		CLIMATE_CONTINENTAL:
			return ["barley", "cabbage", "beet", "hemp", "cherry"]
		CLIMATE_STEPPE:
			return ["millet", "wormwood", "wild_onion", "licorice", "safflower"]
		CLIMATE_ARID:
			return ["sorghum", "sesame", "aloe", "cumin", "capers"]
		CLIMATE_DESERT:
			return ["date_palm", "saxaul", "frankincense_tree", "myrrh", "henna"]
		CLIMATE_MEDITERRANEAN:
			return ["grapes", "olives", "figs", "lavender", "saffron"]
		CLIMATE_TROPICAL:
			return ["rice", "sugarcane", "cocoa", "cotton", "spices"]
		_:
			return []


func get_vegetation_resource_climate_map() -> Dictionary:
	var result: Dictionary = {}
	for climate_type in CLIMATE_TYPES:
		for resource_id in get_allowed_vegetation_resources_for_climate(climate_type):
			result[str(resource_id)] = climate_type

	return result


func get_vegetation_display_text(tile_data) -> String:
	if tile_data == null:
		return "Нет"

	var parts: Array = []
	if str(tile_data.forest_level) != FOREST_NO:
		parts.append(get_forest_level_title(str(tile_data.forest_level)))

	for resource_id in tile_data.vegetation_resources:
		if parts.size() >= 3:
			break

		var resource_text := get_vegetation_resource_title(str(resource_id))
		if resource_text != "none" and resource_text != "Нет":
			parts.append(resource_text)

	if parts.is_empty():
		return "Нет"

	return ", ".join(parts)


func get_vegetation_title(vegetation_type: String) -> String:
	match vegetation_type:
		VEGETATION_NONE:
			return "Нет растительности"
		VEGETATION_FOREST:
			return "Лес"
		VEGETATION_STEPPE:
			return "Степь"
		VEGETATION_GRASSLAND:
			return "Луг"
		VEGETATION_SHRUBS:
			return "Кустарник"
		VEGETATION_SPARSE_FOREST:
			return "Редколесье"
		VEGETATION_TAIGA:
			return "Тайга"
		VEGETATION_TUNDRA:
			return "Тундра"
		VEGETATION_JUNGLE:
			return "Джунгли"
		VEGETATION_SAVANNA:
			return "Саванна"
		VEGETATION_WASTELAND:
			return "Пустошь"
		_:
			return vegetation_type


func normalize_water_feature(water_feature: String, climate_type: String = "") -> String:
	match water_feature:
		WATER_NONE, WATER_COAST, WATER_SMALL_RIVER, WATER_MEDIUM_RIVER, WATER_LARGE_RIVER, WATER_LAKE, WATER_SWAMP, WATER_OASIS, WATER_SEA:
			if water_feature == WATER_OASIS and climate_type != CLIMATE_DESERT and climate_type != CLIMATE_ARID:
				return WATER_NONE
			return water_feature
		WATER_STREAM:
			return WATER_SMALL_RIVER
		WATER_POND, WATER_SPRING:
			return WATER_LAKE
		_:
			return WATER_NONE


func get_water_feature_title(water_feature: String) -> String:
	match water_feature:
		WATER_OASIS:
			return "Оазис"
		WATER_NONE:
			return "Нет"
		WATER_STREAM:
			return "Ручей"
		WATER_SMALL_RIVER:
			return "Маленькая речка"
		WATER_MEDIUM_RIVER:
			return "Средняя река"
		WATER_LARGE_RIVER:
			return "Большая река"
		WATER_LAKE:
			return "Озеро"
		WATER_SWAMP:
			return "Болото"
		WATER_POND:
			return "Пруд"
		WATER_SPRING:
			return "Родник"
		WATER_COAST:
			return "Побережье"
		WATER_SEA:
			return "Море"
		_:
			return water_feature


func normalize_settlement_type(settlement_type: String, has_camp: bool = false) -> String:
	if has_camp and (settlement_type == "" or settlement_type == SETTLEMENT_NONE):
		return SETTLEMENT_CAMP
	if SETTLEMENT_TYPES.has(settlement_type):
		return settlement_type

	return SETTLEMENT_NONE


func get_settlement_title(settlement_type: String) -> String:
	match settlement_type:
		SETTLEMENT_NONE:
			return "Нет"
		SETTLEMENT_CAMP:
			return "Лагерь"
		SETTLEMENT_HAMLET:
			return "Деревушка"
		SETTLEMENT_VILLAGE:
			return "Деревня"
		SETTLEMENT_TOWN:
			return "Городок"
		SETTLEMENT_CITY:
			return "Город"
		SETTLEMENT_FORTRESS:
			return "Крепость"
		_:
			return settlement_type


func get_control_owner_title(control_owner: String) -> String:
	if control_owner == "" or control_owner == CONTROL_NONE:
		return "Нет"

	return control_owner


func initialize_tutorial_goals() -> void:
	for goal_id in TUTORIAL_GOAL_ORDER:
		if not tutorial_goals.has(goal_id):
			tutorial_goals[goal_id] = false


func complete_tutorial_goal(goal_id: String) -> void:
	if not TUTORIAL_GOAL_ORDER.has(goal_id):
		return

	initialize_tutorial_goals()

	if bool(tutorial_goals[goal_id]):
		return

	tutorial_goals[goal_id] = true
	add_journal_entry("goal", "Цель выполнена", get_tutorial_goal_title(goal_id))


func get_tutorial_goal_title(goal_id: String) -> String:
	match goal_id:
		"collect_wood":
			return "Собрать дерево"
		"collect_stone":
			return "Собрать камень"
		"build_camp":
			return "Построить лагерь"
		"deposit_to_camp":
			return "Сложить ресурс в склад лагеря"
		"build_campfire":
			return "Построить костёр"
		"cook_berries":
			return "Приготовить ягоды"
		"rest_at_camp":
			return "Отдохнуть в лагере"
		_:
			return goal_id


func get_tutorial_goals_text() -> String:
	initialize_tutorial_goals()

	var lines: Array = ["Первые цели:"]
	for goal_id in TUTORIAL_GOAL_ORDER:
		var mark := "[ ]"
		if bool(tutorial_goals.get(goal_id, false)):
			mark = "[x]"

		lines.append("%s %s" % [mark, get_tutorial_goal_title(goal_id)])

	return "\n".join(lines)


func get_tutorial_goals_compact_text(max_lines: int = 4) -> String:
	initialize_tutorial_goals()

	var lines: Array = ["Первые цели:"]
	if max_lines <= 0:
		return "\n".join(lines)

	var first_incomplete_index := -1
	var last_completed_index := -1
	for index in range(TUTORIAL_GOAL_ORDER.size()):
		var goal_id: String = TUTORIAL_GOAL_ORDER[index]
		if bool(tutorial_goals.get(goal_id, false)):
			last_completed_index = index
		elif first_incomplete_index == -1:
			first_incomplete_index = index

	if first_incomplete_index == -1:
		lines.append("[x] Базовый цикл завершён")
		return "\n".join(lines)

	var compact_goal_ids: Array = []
	if last_completed_index >= 0:
		compact_goal_ids.append(TUTORIAL_GOAL_ORDER[last_completed_index])

	for index in range(first_incomplete_index, TUTORIAL_GOAL_ORDER.size()):
		if compact_goal_ids.size() >= max_lines:
			break

		var goal_id: String = TUTORIAL_GOAL_ORDER[index]
		if not compact_goal_ids.has(goal_id):
			compact_goal_ids.append(goal_id)

	for compact_goal_id in compact_goal_ids:
		var goal_id := str(compact_goal_id)
		var mark := "[ ]"
		if bool(tutorial_goals.get(goal_id, false)):
			mark = "[x]"

		lines.append("%s %s" % [mark, get_tutorial_goal_title(goal_id)])

	return "\n".join(lines)


func add_journal_entry(category: String, title: String, description: String = "", priority: String = "normal") -> void:
	var entry := {
		"day": day,
		"hour": hour,
		"category": category,
		"priority": priority,
		"title": title,
		"description": description
	}

	journal_entries.append(entry)

	while journal_entries.size() > 100:
		journal_entries.pop_front()

	print(title)


func get_recent_journal_entries(limit: int = 6) -> Array:
	var recent_entries: Array = []
	var index := journal_entries.size() - 1

	while index >= 0 and recent_entries.size() < limit:
		recent_entries.append(journal_entries[index])
		index -= 1

	return recent_entries


func add_skill_xp(skill_name: String, amount: int) -> void:
	initialize_player_data()

	var result: Dictionary = player_data.add_skill_xp(skill_name, amount)
	if bool(result.get("leveled_up", false)):
		add_journal_entry(
			"skill",
			"Навык повышен",
			"%s уровень %d" % [
				str(result.get("skill_name", skill_name)),
				int(result.get("new_level", 1))
			]
		)


func get_gather_energy_cost() -> int:
	initialize_player_data()

	var survival_level: int = player_data.get_skill_level("survival")
	if survival_level >= 4:
		return 1
	if survival_level >= 2:
		return 2

	return GATHER_BASE_ENERGY_COST


func has_enough_energy(amount: int) -> bool:
	initialize_player_data()

	return player_data.energy >= amount


func spend_energy(amount: int) -> bool:
	initialize_player_data()

	if amount <= 0:
		return true
	if player_data.energy < amount:
		return false

	player_data.energy = max(0, player_data.energy - amount)
	return true


func get_default_danger_for_terrain(terrain_type: String) -> int:
	match terrain_type:
		TERRAIN_WATER:
			return 0
		TERRAIN_PLAINS:
			return 1
		TERRAIN_FOREST:
			return 2
		TERRAIN_WASTELAND:
			return 3
		_:
			return 0


func configure_natural_features_for_tile(tile_data) -> void:
	if tile_data == null:
		return

	var layers := _generate_world_layers()
	var climate_map: Array = layers.get("climate", [])
	var relief_map: Array = layers.get("relief", [])
	var vegetation_map: Array = layers.get("vegetation", [])
	var water_feature_map: Array = layers.get("water_feature", [])
	var soil_fertility_map: Array = layers.get("soil_fertility", [])

	if tile_data.terrain_type == TERRAIN_WATER:
		var generated_water_feature := str(_get_layer_value(water_feature_map, tile_data.x, tile_data.y, WATER_SEA))
		tile_data.water_feature = normalize_water_feature(generated_water_feature if generated_water_feature != WATER_NONE else WATER_SEA)
		if tile_data.water_feature == WATER_SEA:
			tile_data.climate_type = CLIMATE_SEA
			tile_data.relief_type = RELIEF_LOWLAND
			tile_data.vegetation_type = VEGETATION_NONE
			tile_data.soil_fertility = 0
			configure_public_natural_features_for_tile(tile_data)
			return

	tile_data.climate_type = str(_get_layer_value(climate_map, tile_data.x, tile_data.y, CLIMATE_CONTINENTAL))
	tile_data.relief_type = str(_get_layer_value(relief_map, tile_data.x, tile_data.y, RELIEF_PLAINS))
	tile_data.vegetation_type = str(_get_layer_value(vegetation_map, tile_data.x, tile_data.y, VEGETATION_GRASSLAND))
	tile_data.water_feature = normalize_water_feature(str(_get_layer_value(water_feature_map, tile_data.x, tile_data.y, WATER_NONE)), tile_data.climate_type)
	tile_data.soil_fertility = int(_get_layer_value(soil_fertility_map, tile_data.x, tile_data.y, 1))
	configure_public_natural_features_for_tile(tile_data)


func configure_public_natural_features_for_tile(tile_data) -> void:
	if tile_data == null:
		return

	tile_data.climate_type = normalize_climate_type(tile_data.climate_type, tile_data.y, tile_data.terrain_type, tile_data.water_feature)
	tile_data.relief_type = normalize_relief_type(tile_data.relief_type)
	tile_data.water_feature = normalize_water_feature(tile_data.water_feature, tile_data.climate_type)
	tile_data.settlement_type = normalize_settlement_type(tile_data.settlement_type, tile_data.has_camp)
	if str(tile_data.control_owner) == "":
		tile_data.control_owner = CONTROL_NONE

	tile_data.forest_level = _choose_forest_level_for_tile(tile_data)
	tile_data.vegetation_resources = _choose_vegetation_resources_for_tile(tile_data)


func normalize_public_tile_fields(tile_data) -> void:
	if tile_data == null:
		return

	tile_data.climate_type = normalize_climate_type(tile_data.climate_type, tile_data.y, tile_data.terrain_type, tile_data.water_feature)
	tile_data.relief_type = normalize_relief_type(tile_data.relief_type)
	tile_data.water_feature = normalize_water_feature(tile_data.water_feature, tile_data.climate_type)
	tile_data.settlement_type = normalize_settlement_type(tile_data.settlement_type, tile_data.has_camp)
	if str(tile_data.control_owner) == "":
		tile_data.control_owner = CONTROL_NONE
	if not FOREST_LEVEL_TYPES.has(tile_data.forest_level):
		tile_data.forest_level = FOREST_NO

	var allowed_resources := get_allowed_vegetation_resources_for_climate(tile_data.climate_type)
	var filtered_resources: Array = []
	if tile_data.vegetation_resources is Array:
		for resource_id in tile_data.vegetation_resources:
			var resource_text := str(resource_id)
			if allowed_resources.has(resource_text) and not filtered_resources.has(resource_text):
				filtered_resources.append(resource_text)
			if filtered_resources.size() >= 2:
				break

	if tile_data.climate_type == CLIMATE_SEA or tile_data.climate_type == CLIMATE_POLAR:
		filtered_resources.clear()
		tile_data.forest_level = FOREST_NO

	tile_data.vegetation_resources = filtered_resources


func _choose_forest_level_for_tile(tile_data) -> String:
	var climate := str(tile_data.climate_type)
	var allowed := get_allowed_forest_levels_for_climate(climate)
	if allowed.is_empty():
		return FOREST_NO
	if climate == CLIMATE_SEA or climate == CLIMATE_POLAR or climate == CLIMATE_DESERT:
		return FOREST_NO

	var water_feature := str(tile_data.water_feature)
	var relief := str(tile_data.relief_type)
	var has_water := water_feature != WATER_NONE and water_feature != WATER_SEA
	var roll: int = abs(tile_data.x * 37 + tile_data.y * 53 + map_width * 11) % 100
	var forest_level := FOREST_NO

	match climate:
		CLIMATE_NORDIC, CLIMATE_OCEANIC, CLIMATE_CONTINENTAL:
			if relief == RELIEF_MOUNTAINS or relief == RELIEF_ROCKY:
				forest_level = FOREST_SPARSE if roll < 70 else FOREST_MEDIUM
			elif roll < 25:
				forest_level = FOREST_SPARSE
			elif roll < 68:
				forest_level = FOREST_MEDIUM
			else:
				forest_level = FOREST_MASSIF
		CLIMATE_STEPPE:
			forest_level = FOREST_SPARSE if has_water and roll < 28 else FOREST_NO
		CLIMATE_ARID:
			forest_level = FOREST_SPARSE if _water_supports_sparse_forest(water_feature) and roll < 25 else FOREST_NO
		CLIMATE_MEDITERRANEAN:
			if roll < 42:
				forest_level = FOREST_NO
			elif roll < 82:
				forest_level = FOREST_SPARSE
			else:
				forest_level = FOREST_MEDIUM
		CLIMATE_TROPICAL:
			forest_level = FOREST_MASSIF if roll < 62 else FOREST_MEDIUM

	if not allowed.has(forest_level):
		return str(allowed[0])

	return forest_level


func _choose_vegetation_resources_for_tile(tile_data) -> Array:
	var climate := str(tile_data.climate_type)
	var allowed := get_allowed_vegetation_resources_for_climate(climate)
	var result: Array = []
	if allowed.is_empty() or climate == CLIMATE_SEA or climate == CLIMATE_POLAR:
		return result

	var water_feature := str(tile_data.water_feature)
	var resource_count := 2
	if climate == CLIMATE_DESERT:
		resource_count = 1 if _water_supports_desert_plants(water_feature) else 0
	elif climate == CLIMATE_ARID:
		resource_count = 2 if _water_supports_desert_plants(water_feature) else 1
	elif climate == CLIMATE_STEPPE:
		resource_count = 2 if water_feature != WATER_NONE else 1

	var start_index: int = abs(tile_data.x * 13 + tile_data.y * 29 + map_height * 7) % allowed.size()
	for offset in range(resource_count):
		var resource_id := str(allowed[(start_index + offset * 2) % allowed.size()])
		if not result.has(resource_id):
			result.append(resource_id)

	return result


func _water_supports_sparse_forest(water_feature: String) -> bool:
	return water_feature == WATER_COAST or water_feature == WATER_LAKE or water_feature == WATER_SWAMP or water_feature == WATER_OASIS or water_feature == WATER_SMALL_RIVER or water_feature == WATER_MEDIUM_RIVER or water_feature == WATER_LARGE_RIVER


func _water_supports_desert_plants(water_feature: String) -> bool:
	return water_feature == WATER_OASIS or water_feature == WATER_COAST or water_feature == WATER_LAKE or water_feature == WATER_SMALL_RIVER or water_feature == WATER_MEDIUM_RIVER or water_feature == WATER_LARGE_RIVER


func get_selected_tile_danger_level() -> int:
	if selected_tile == null:
		return 0

	return int(selected_tile.danger_level)


func get_gather_risk(tile_data) -> int:
	initialize_player_data()

	if tile_data == null:
		return 0

	var danger_level: int = int(tile_data.danger_level)
	var base_chance: int = danger_level * 5
	var survival_level: int = player_data.get_skill_level("survival")
	var risk_reduction: int = 0

	if survival_level >= 4:
		risk_reduction = 6
	elif survival_level >= 2:
		risk_reduction = 3

	return max(0, base_chance - risk_reduction)


func get_gather_risk_chance() -> int:
	return get_gather_risk(selected_tile)


func roll_gather_danger_event() -> Dictionary:
	initialize_player_data()

	var chance: int = get_gather_risk_chance()
	if chance <= 0:
		return {"happened": false}

	if randi_range(1, 100) > chance:
		return {"happened": false}

	var event_type := ""
	var description := ""

	match randi_range(1, 3):
		1:
			event_type = "scratch"
			description = "Игрок поцарапался"
			player_data.change_health(-3)
		2:
			event_type = "fatigue"
			description = "Игрок сильно устал"
			player_data.change_energy(-5)
		3:
			event_type = "bad_step"
			description = "Игрок оступился"
			player_data.change_health(-2)
			player_data.change_energy(-3)

	add_journal_entry("danger", description)

	return {
		"happened": true,
		"event_type": event_type,
		"description": description
	}


func _apply_six_hour_effects() -> void:
	player_data.hunger += 1

	if player_data.hunger >= 10:
		player_data.energy = max(0, player_data.energy - 2)

	if player_data.hunger >= 20:
		player_data.health = max(0, player_data.health - 1)

	if player_data.hunger > 50:
		player_data.energy = max(0, player_data.energy - 1)


func can_eat_berries() -> bool:
	initialize_player_data()

	var inventory: Dictionary = player_data.inventory
	return int(inventory.get("berries", 0)) > 0


func eat_berries() -> bool:
	if not can_eat_berries():
		return false

	var inventory: Dictionary = player_data.inventory
	var berries_count := int(inventory.get("berries", 0)) - 1

	if berries_count <= 0:
		inventory.erase("berries")
	else:
		inventory["berries"] = berries_count

	player_data.hunger = max(0, player_data.hunger - BERRY_HUNGER_RESTORE)
	advance_time()
	add_journal_entry("personal", "Игрок съел ягоды")
	return true


func can_eat_cooked_berries() -> bool:
	initialize_player_data()

	var inventory: Dictionary = player_data.inventory
	return int(inventory.get("cooked_berries", 0)) > 0


func eat_cooked_berries() -> bool:
	if not can_eat_cooked_berries():
		return false

	var inventory: Dictionary = player_data.inventory
	var cooked_berries_count: int = int(inventory.get("cooked_berries", 0)) - 1

	if cooked_berries_count <= 0:
		inventory.erase("cooked_berries")
	else:
		inventory["cooked_berries"] = cooked_berries_count

	player_data.hunger = max(0, player_data.hunger - COOKED_BERRIES_HUNGER_RESTORE)
	player_data.energy = min(100, player_data.energy + COOKED_BERRIES_ENERGY_RESTORE)
	advance_time()
	add_journal_entry("personal", "Игрок съел приготовленные ягоды")
	return true


func can_build_camp_on_selected_tile() -> bool:
	if selected_tile == null:
		return false
	if selected_tile.has_camp:
		return false
	if selected_tile.terrain_type == TERRAIN_WATER:
		return false

	initialize_player_data()

	var inventory: Dictionary = player_data.inventory
	return int(inventory.get("wood", 0)) >= CAMP_WOOD_COST and int(inventory.get("stone", 0)) >= CAMP_STONE_COST


func build_camp_on_selected_tile() -> bool:
	if not can_build_camp_on_selected_tile():
		return false

	if not spend_energy(BUILD_CAMP_ENERGY_COST):
		return false

	var inventory: Dictionary = player_data.inventory
	inventory["wood"] = int(inventory.get("wood", 0)) - CAMP_WOOD_COST
	inventory["stone"] = int(inventory.get("stone", 0)) - CAMP_STONE_COST
	selected_tile.has_camp = true
	selected_tile.settlement_type = SETTLEMENT_CAMP
	add_journal_entry("camp", "Лагерь построен", "Потрачено wood 5, stone 2")
	complete_tutorial_goal("build_camp")
	add_skill_xp("construction", 10)
	return true


func has_campfire_on_selected_tile() -> bool:
	if selected_tile == null:
		return false

	return bool(selected_tile.camp_upgrades.get("campfire", false))


func can_build_campfire_on_selected_tile() -> bool:
	if selected_tile == null:
		return false
	if not selected_tile.has_camp:
		return false
	if has_campfire_on_selected_tile():
		return false

	return int(selected_tile.camp_storage.get("wood", 0)) >= CAMPFIRE_WOOD_COST and int(selected_tile.camp_storage.get("stone", 0)) >= CAMPFIRE_STONE_COST


func get_campfire_requirements_status() -> Dictionary:
	initialize_player_data()

	var has_camp: bool = selected_tile != null and selected_tile.has_camp
	var has_campfire: bool = false
	var storage_wood: int = 0
	var storage_stone: int = 0

	if selected_tile != null:
		has_campfire = bool(selected_tile.camp_upgrades.get("campfire", false))
		storage_wood = int(selected_tile.camp_storage.get("wood", 0))
		storage_stone = int(selected_tile.camp_storage.get("stone", 0))

	var inventory: Dictionary = player_data.inventory
	var inventory_wood: int = int(inventory.get("wood", 0))
	var inventory_stone: int = int(inventory.get("stone", 0))

	return {
		"has_camp": has_camp,
		"has_campfire": has_campfire,
		"required_wood": CAMPFIRE_WOOD_COST,
		"required_stone": CAMPFIRE_STONE_COST,
		"storage_wood": storage_wood,
		"storage_stone": storage_stone,
		"inventory_wood": inventory_wood,
		"inventory_stone": inventory_stone,
		"missing_storage_wood": max(0, CAMPFIRE_WOOD_COST - storage_wood),
		"missing_storage_stone": max(0, CAMPFIRE_STONE_COST - storage_stone)
	}


func prepare_campfire_resources_on_selected_tile() -> bool:
	if selected_tile == null:
		return false
	if not selected_tile.has_camp:
		return false
	if has_campfire_on_selected_tile():
		return false

	initialize_player_data()

	var moved_parts: Array = []
	var moved_wood: int = _move_inventory_item_to_camp_storage_for_requirement("wood", CAMPFIRE_WOOD_COST)
	var moved_stone: int = _move_inventory_item_to_camp_storage_for_requirement("stone", CAMPFIRE_STONE_COST)

	if moved_wood > 0:
		moved_parts.append("wood x%d" % moved_wood)
	if moved_stone > 0:
		moved_parts.append("stone x%d" % moved_stone)

	if moved_parts.is_empty():
		return false

	add_journal_entry("camp", "Ресурсы подготовлены для костра", ", ".join(moved_parts))
	return true


func _move_inventory_item_to_camp_storage_for_requirement(item_name: String, required_amount: int) -> int:
	var storage_amount: int = int(selected_tile.camp_storage.get(item_name, 0))
	var missing_amount: int = max(0, required_amount - storage_amount)
	var inventory: Dictionary = player_data.inventory
	var inventory_amount: int = int(inventory.get(item_name, 0))
	var moved_amount: int = min(missing_amount, inventory_amount)

	if moved_amount <= 0:
		return 0

	inventory[item_name] = inventory_amount - moved_amount
	if int(inventory[item_name]) <= 0:
		inventory.erase(item_name)

	selected_tile.camp_storage[item_name] = storage_amount + moved_amount
	return moved_amount


func build_campfire_on_selected_tile() -> bool:
	if not can_build_campfire_on_selected_tile():
		return false

	if not spend_energy(BUILD_CAMPFIRE_ENERGY_COST):
		return false

	selected_tile.camp_storage["wood"] = int(selected_tile.camp_storage.get("wood", 0)) - CAMPFIRE_WOOD_COST
	selected_tile.camp_storage["stone"] = int(selected_tile.camp_storage.get("stone", 0)) - CAMPFIRE_STONE_COST

	if int(selected_tile.camp_storage["wood"]) <= 0:
		selected_tile.camp_storage.erase("wood")
	if int(selected_tile.camp_storage["stone"]) <= 0:
		selected_tile.camp_storage.erase("stone")

	selected_tile.camp_upgrades["campfire"] = true
	add_journal_entry("camp", "Костёр построен", "Потрачено wood 3, stone 1")
	complete_tutorial_goal("build_campfire")
	add_skill_xp("construction", 5)
	return true


func can_cook_berries_at_campfire() -> bool:
	if selected_tile == null:
		return false
	if not selected_tile.has_camp:
		return false
	if not has_campfire_on_selected_tile():
		return false

	return int(selected_tile.camp_storage.get("berries", 0)) >= COOK_BERRIES_INPUT


func cook_berries_at_campfire() -> bool:
	if not can_cook_berries_at_campfire():
		return false

	if not spend_energy(COOK_BERRIES_ENERGY_COST):
		return false

	var storage: Dictionary = selected_tile.camp_storage
	var berries_count: int = int(storage.get("berries", 0)) - COOK_BERRIES_INPUT

	if berries_count <= 0:
		storage.erase("berries")
	else:
		storage["berries"] = berries_count

	storage["cooked_berries"] = int(storage.get("cooked_berries", 0)) + COOKED_BERRIES_OUTPUT
	advance_time()
	add_journal_entry("camp", "Ягоды приготовлены", "berries x2 -> cooked_berries x1")
	complete_tutorial_goal("cook_berries")
	add_skill_xp("cooking", 5)
	return true


func quick_rest() -> bool:
	initialize_player_data()

	if player_data.energy >= 100:
		return false

	player_data.energy = min(100, player_data.energy + QUICK_REST_ENERGY_RESTORE)
	player_data.hunger += QUICK_REST_HUNGER_GAIN
	advance_time(QUICK_REST_HOURS)
	add_journal_entry("personal", "Игрок передохнул", "Короткий отдых занял 4 часа")
	return true


func rest_at_camp() -> bool:
	if selected_tile == null:
		return false
	if not selected_tile.has_camp:
		return false

	initialize_player_data()

	var energy_restore := 40
	var health_restore := 5

	if has_campfire_on_selected_tile():
		energy_restore = 60
		health_restore = 10

	player_data.energy = min(100, player_data.energy + energy_restore)

	if player_data.hunger < 20:
		player_data.health = min(100, player_data.health + health_restore)

	advance_time(8)
	add_journal_entry("camp", "Игрок отдохнул в лагере", "Отдых занял 8 часов")
	complete_tutorial_goal("rest_at_camp")
	return true


func deposit_to_camp(item_name: String, amount: int) -> bool:
	if selected_tile == null:
		return false
	if not selected_tile.has_camp:
		return false
	if amount <= 0:
		return false

	initialize_player_data()

	var inventory: Dictionary = player_data.inventory
	if int(inventory.get(item_name, 0)) < amount:
		return false

	inventory[item_name] = int(inventory.get(item_name, 0)) - amount
	if int(inventory[item_name]) <= 0:
		inventory.erase(item_name)

	selected_tile.camp_storage[item_name] = int(selected_tile.camp_storage.get(item_name, 0)) + amount
	add_journal_entry("camp", "Ресурс сложен в лагерь", "%s x%d" % [item_name, amount])
	complete_tutorial_goal("deposit_to_camp")
	return true


func withdraw_from_camp(item_name: String, amount: int) -> bool:
	if selected_tile == null:
		return false
	if not selected_tile.has_camp:
		return false
	if amount <= 0:
		return false

	if int(selected_tile.camp_storage.get(item_name, 0)) < amount:
		return false

	selected_tile.camp_storage[item_name] = int(selected_tile.camp_storage.get(item_name, 0)) - amount
	if int(selected_tile.camp_storage[item_name]) <= 0:
		selected_tile.camp_storage.erase(item_name)

	initialize_player_data()
	player_data.inventory[item_name] = int(player_data.inventory.get(item_name, 0)) + amount
	add_journal_entry("camp", "Ресурс взят из лагеря", "%s x%d" % [item_name, amount])
	return true


func get_terrain_display_name(terrain_type: String) -> String:
	match terrain_type:
		TERRAIN_FOREST:
			return "лес"
		TERRAIN_PLAINS:
			return "равнина"
		TERRAIN_WASTELAND:
			return "пустошь"
		TERRAIN_WATER:
			return "вода"
		_:
			return "неизвестно"


func get_terrain_color(terrain_type: String) -> Color:
	match terrain_type:
		TERRAIN_FOREST:
			return Color.html("#2f8f3a")
		TERRAIN_PLAINS:
			return Color.html("#d6c84f")
		TERRAIN_WASTELAND:
			return Color.html("#777777")
		TERRAIN_WATER:
			return Color.html("#2f73d6")
		_:
			return Color.html("#ffffff")


func get_global_tile_texture_path(tile_data) -> String:
	if tile_data == null:
		return ""
	if tile_data.climate_type != CLIMATE_CONTINENTAL:
		return ""
	if tile_data.relief_type != RELIEF_PLAINS and tile_data.relief_type != RELIEF_LOWLAND:
		return ""
	if tile_data.water_feature != WATER_NONE:
		return ""

	return GLOBAL_TEXTURE_CONTINENTAL_PLAINS


func get_global_tile_texture(tile_data):
	var texture_path := get_global_tile_texture_path(tile_data)
	if texture_path == "":
		return null
	if global_tile_texture_cache.has(texture_path):
		return global_tile_texture_cache[texture_path]

	var image := Image.new()
	var error := image.load(texture_path)
	if error != OK:
		print("Не удалось загрузить текстуру глобальной карты: %s" % texture_path)
		return null

	var texture := ImageTexture.create_from_image(image)
	global_tile_texture_cache[texture_path] = texture
	return texture


func get_local_background_color(terrain_type: String) -> Color:
	match terrain_type:
		TERRAIN_FOREST:
			return Color.html("#3f7f39")
		TERRAIN_PLAINS:
			return Color.html("#d7cd78")
		TERRAIN_WASTELAND:
			return Color.html("#8b8880")
		TERRAIN_WATER:
			return Color.html("#2f73d6")
		_:
			return Color.html("#000000")


func _generate_terrain_map() -> Array:
	var layers := _generate_world_layers()
	return layers.get("terrain", [])


func _generate_world_layers() -> Dictionary:
	var elevation_map: Array = _create_layer(2)
	var water_feature_map: Array = _create_layer(WATER_NONE)

	_generate_base_land_and_sea(elevation_map, water_feature_map)
	_generate_mountain_regions(elevation_map)
	_mark_coastal_tiles(elevation_map, water_feature_map)
	_generate_rivers(water_feature_map, elevation_map)
	_generate_lakes_and_swamps(water_feature_map, elevation_map)
	_apply_water_lowlands(elevation_map, water_feature_map)

	var relief_map: Array = _generate_relief_layer(elevation_map, water_feature_map)
	var sea_distance_map: Array = _generate_distance_to_water_layer(water_feature_map, [WATER_SEA, WATER_COAST])
	var moisture_map: Array = _generate_moisture_layer(water_feature_map, elevation_map, relief_map, sea_distance_map)
	var climate_map: Array = _generate_climate_layer(elevation_map, relief_map, water_feature_map, sea_distance_map, moisture_map)
	_smooth_climate_layer(climate_map, water_feature_map, sea_distance_map, moisture_map, elevation_map, relief_map, 4)

	var humidity_map: Array = _generate_humidity_layer(water_feature_map, climate_map, moisture_map)
	var vegetation_map: Array = _generate_vegetation_layer(climate_map, relief_map, water_feature_map, humidity_map)
	var terrain_map: Array = _generate_terrain_from_natural_layers(relief_map, climate_map, vegetation_map, water_feature_map, humidity_map)
	var soil_fertility_map: Array = _generate_soil_fertility_layer(terrain_map, climate_map, vegetation_map, water_feature_map)

	return {
		"terrain": terrain_map,
		"climate": climate_map,
		"relief": relief_map,
		"vegetation": vegetation_map,
		"water_feature": water_feature_map,
		"soil_fertility": soil_fertility_map
	}


func _create_layer(default_value) -> Array:
	var layer: Array = []

	for y in range(map_height):
		var row: Array = []

		for x in range(map_width):
			row.append(default_value)

		layer.append(row)

	return layer


func _get_layer_value(layer: Array, x: int, y: int, default_value):
	if y < 0 or y >= layer.size():
		return default_value

	var row = layer[y]
	if not row is Array:
		return default_value
	if x < 0 or x >= row.size():
		return default_value

	return row[x]


func _set_layer_value(layer: Array, x: int, y: int, value) -> void:
	if y < 0 or y >= layer.size():
		return

	var row = layer[y]
	if not row is Array:
		return
	if x < 0 or x >= row.size():
		return

	row[x] = value
	layer[y] = row


func _generate_base_land_and_sea(elevation_map: Array, water_feature_map: Array) -> void:
	_paint_water_rectangle(elevation_map, water_feature_map, 0, 0, map_width, 1, WATER_SEA, 0)
	_paint_water_rectangle(elevation_map, water_feature_map, 0, 0, 1, map_height, WATER_SEA, 0)
	_paint_water_rectangle(elevation_map, water_feature_map, map_width - 3, 0, 3, 5, WATER_SEA, 0)
	_paint_water_rectangle(elevation_map, water_feature_map, map_width - 1, 8, 1, 3, WATER_SEA, 0)
	_paint_water_rectangle(elevation_map, water_feature_map, map_width - 2, map_height - 6, 2, 6, WATER_SEA, 0)
	_paint_water_rectangle(elevation_map, water_feature_map, 0, map_height - 3, 6, 3, WATER_SEA, 0)
	_paint_water_rectangle(elevation_map, water_feature_map, 9, map_height - 2, 7, 2, WATER_SEA, 0)


func _paint_water_rectangle(elevation_map: Array, water_feature_map: Array, start_x: int, start_y: int, width: int, height: int, water_feature: String, elevation: int) -> void:
	for y in range(start_y, start_y + height):
		for x in range(start_x, start_x + width):
			_set_layer_value(water_feature_map, x, y, water_feature)
			_set_layer_value(elevation_map, x, y, elevation)


func _generate_mountain_regions(elevation_map: Array) -> void:
	_apply_mountain_chain(elevation_map, [
		Vector2i(5, 2),
		Vector2i(6, 3),
		Vector2i(7, 4),
		Vector2i(8, 5),
		Vector2i(9, 6)
	])
	_apply_mountain_chain(elevation_map, [
		Vector2i(16, 3),
		Vector2i(17, 4),
		Vector2i(18, 5),
		Vector2i(19, 6),
		Vector2i(20, 7)
	])
	_apply_mountain_chain(elevation_map, [
		Vector2i(13, 10),
		Vector2i(14, 11),
		Vector2i(15, 12),
		Vector2i(16, 13)
	])


func _apply_mountain_chain(elevation_map: Array, points: Array) -> void:
	for point in points:
		if not point is Vector2i:
			continue

		_set_layer_value(elevation_map, point.x, point.y, 4)

		for offset_y in range(-1, 2):
			for offset_x in range(-1, 2):
				if offset_x == 0 and offset_y == 0:
					continue

				var near_x: int = point.x + offset_x
				var near_y: int = point.y + offset_y
				var current_elevation: int = int(_get_layer_value(elevation_map, near_x, near_y, 2))

				if current_elevation > 0 and current_elevation < 3:
					_set_layer_value(elevation_map, near_x, near_y, 3)


func _mark_coastal_tiles(elevation_map: Array, water_feature_map: Array) -> void:
	for y in range(map_height):
		for x in range(map_width):
			if str(_get_layer_value(water_feature_map, x, y, WATER_NONE)) != WATER_NONE:
				continue
			if not _has_neighbor_with_water_feature(water_feature_map, x, y, [WATER_SEA]):
				continue

			_set_layer_value(water_feature_map, x, y, WATER_COAST)
			var elevation: int = int(_get_layer_value(elevation_map, x, y, 2))
			if elevation > 1 and elevation < 4:
				_set_layer_value(elevation_map, x, y, 1)


func _generate_distance_to_water_layer(water_feature_map: Array, target_features: Array) -> Array:
	var distance_map: Array = _create_layer(99)

	for y in range(map_height):
		for x in range(map_width):
			var current_feature := str(_get_layer_value(water_feature_map, x, y, WATER_NONE))
			if target_features.has(current_feature):
				_set_layer_value(distance_map, x, y, 0)
				continue

			var nearest_distance := 99

			for check_y in range(map_height):
				for check_x in range(map_width):
					var checked_feature := str(_get_layer_value(water_feature_map, check_x, check_y, WATER_NONE))
					if not target_features.has(checked_feature):
						continue

					var distance: int = abs(x - check_x) + abs(y - check_y)
					if distance < nearest_distance:
						nearest_distance = distance

			_set_layer_value(distance_map, x, y, nearest_distance)

	return distance_map


func _generate_moisture_layer(water_feature_map: Array, elevation_map: Array, relief_map: Array, sea_distance_map: Array) -> Array:
	var moisture_map: Array = _create_layer(2)

	for y in range(map_height):
		for x in range(map_width):
			var water_feature := str(_get_layer_value(water_feature_map, x, y, WATER_NONE))
			var elevation: int = int(_get_layer_value(elevation_map, x, y, 2))
			var relief := str(_get_layer_value(relief_map, x, y, RELIEF_PLAINS))
			var distance_to_sea: int = int(_get_layer_value(sea_distance_map, x, y, 99))
			var moisture := 2

			if water_feature == WATER_SEA:
				moisture = 5
			elif distance_to_sea <= 1:
				moisture += 2
			elif distance_to_sea <= 3:
				moisture += 1
			elif distance_to_sea >= 7:
				moisture -= 1

			if _is_near_water_feature(water_feature_map, x, y, [WATER_LAKE, WATER_SWAMP, WATER_MEDIUM_RIVER, WATER_LARGE_RIVER, WATER_SMALL_RIVER, WATER_STREAM], 2):
				moisture += 1
			if water_feature == WATER_SWAMP or water_feature == WATER_LAKE:
				moisture += 1
			if relief == RELIEF_MOUNTAINS or elevation >= 4:
				moisture -= 1
			if x >= int(map_width * 0.58) and y >= int(map_height * 0.36) and y <= int(map_height * 0.70):
				moisture -= 2
			if x >= int(map_width * 0.70) and y >= int(map_height * 0.42) and y <= int(map_height * 0.76):
				moisture -= 1

			_set_layer_value(moisture_map, x, y, int(clamp(moisture, 0, 5)))

	return moisture_map


func _generate_climate_layer(elevation_map: Array, relief_map: Array, water_feature_map: Array, sea_distance_map: Array, moisture_map: Array) -> Array:
	var climate_map: Array = _create_layer(CLIMATE_CONTINENTAL)

	for y in range(map_height):
		for x in range(map_width):
			var water_feature := str(_get_layer_value(water_feature_map, x, y, WATER_NONE))
			var elevation: int = int(_get_layer_value(elevation_map, x, y, 2))
			var relief := str(_get_layer_value(relief_map, x, y, RELIEF_PLAINS))
			var distance_to_sea: int = int(_get_layer_value(sea_distance_map, x, y, 99))
			var moisture: int = int(_get_layer_value(moisture_map, x, y, 2))
			var pole_distance: int = min(y, map_height - 1 - y)
			var temperature_band: int = pole_distance

			if water_feature == WATER_SEA:
				_set_layer_value(climate_map, x, y, CLIMATE_SEA)
				continue

			if elevation >= 4:
				temperature_band -= 2
			elif elevation == 3 or relief == RELIEF_HILLS:
				temperature_band -= 1

			temperature_band = max(0, temperature_band)

			var climate := _choose_climate_for_tile(
				x,
				y,
				temperature_band,
				distance_to_sea,
				moisture,
				elevation,
				relief
			)

			_set_layer_value(climate_map, x, y, climate)

	return climate_map


func _choose_climate_for_tile(x: int, y: int, temperature_band: int, distance_to_sea: int, moisture: int, elevation: int, relief: String) -> String:
	var near_sea := distance_to_sea <= 2
	var far_from_sea := distance_to_sea >= 5
	var dry_interior := _is_dry_interior_cell(x, y, distance_to_sea, moisture)

	if temperature_band <= 0:
		return CLIMATE_POLAR if elevation >= 4 or moisture <= 2 else CLIMATE_NORDIC
	if temperature_band == 1:
		if near_sea and moisture >= 4:
			return CLIMATE_OCEANIC
		return CLIMATE_NORDIC
	if temperature_band <= 3:
		if near_sea and moisture >= 3:
			return CLIMATE_OCEANIC
		return CLIMATE_NORDIC if temperature_band <= 2 else CLIMATE_CONTINENTAL
	if temperature_band <= 5:
		if near_sea and moisture >= 3:
			return CLIMATE_OCEANIC
		if far_from_sea and moisture <= 1:
			return CLIMATE_STEPPE
		if dry_interior and moisture <= 2:
			return CLIMATE_STEPPE
		return CLIMATE_CONTINENTAL

	if moisture >= 4:
		if near_sea or relief == RELIEF_LOWLAND:
			return CLIMATE_TROPICAL
		return CLIMATE_OCEANIC
	if near_sea and moisture == 3:
		return CLIMATE_MEDITERRANEAN
	if moisture <= 0 and far_from_sea:
		return CLIMATE_DESERT
	if moisture <= 1:
		return CLIMATE_ARID
	if moisture == 2 or dry_interior:
		return CLIMATE_STEPPE

	return CLIMATE_CONTINENTAL


func _is_dry_interior_cell(x: int, y: int, distance_to_sea: int, moisture: int) -> bool:
	if distance_to_sea < 4:
		return false

	var center_band_start := int(map_height * 0.36)
	var center_band_end := int(map_height * 0.70)
	var dry_east_start := int(map_width * 0.58)

	return x >= dry_east_start and y >= center_band_start and y <= center_band_end and moisture <= 2


func _smooth_climate_layer(climate_map: Array, water_feature_map: Array, sea_distance_map: Array, moisture_map: Array, elevation_map: Array, relief_map: Array, passes: int) -> void:
	for _pass_index in range(passes):
		var next_map := _duplicate_layer(climate_map)

		for y in range(map_height):
			for x in range(map_width):
				var water_feature := str(_get_layer_value(water_feature_map, x, y, WATER_NONE))
				var current_climate := str(_get_layer_value(climate_map, x, y, CLIMATE_CONTINENTAL))

				if water_feature == WATER_SEA:
					_set_layer_value(next_map, x, y, CLIMATE_SEA)
					continue
				if current_climate == CLIMATE_SEA:
					current_climate = _get_transition_climate_for_position(x, y, sea_distance_map, moisture_map, elevation_map, relief_map)

				var fixed_climate := _fix_climate_for_position(
					current_climate,
					x,
					y,
					sea_distance_map,
					moisture_map,
					elevation_map,
					relief_map
				)
				fixed_climate = _fix_climate_for_neighbors(
					fixed_climate,
					x,
					y,
					climate_map,
					water_feature_map,
					sea_distance_map,
					moisture_map,
					elevation_map,
					relief_map
				)
				fixed_climate = _fix_isolated_climate(
					fixed_climate,
					x,
					y,
					climate_map,
					water_feature_map,
					sea_distance_map,
					moisture_map,
					elevation_map,
					relief_map
				)

				_set_layer_value(next_map, x, y, fixed_climate)

		for y in range(map_height):
			for x in range(map_width):
				_set_layer_value(climate_map, x, y, _get_layer_value(next_map, x, y, CLIMATE_CONTINENTAL))


func _duplicate_layer(layer: Array) -> Array:
	var duplicated: Array = []

	for row in layer:
		if row is Array:
			duplicated.append(row.duplicate())
		else:
			duplicated.append(row)

	return duplicated


func _fix_climate_for_position(climate: String, x: int, y: int, sea_distance_map: Array, moisture_map: Array, elevation_map: Array, relief_map: Array) -> String:
	var pole_distance: int = min(y, map_height - 1 - y)
	var distance_to_sea: int = int(_get_layer_value(sea_distance_map, x, y, 99))
	var moisture: int = int(_get_layer_value(moisture_map, x, y, 2))
	var elevation: int = int(_get_layer_value(elevation_map, x, y, 2))

	if climate == CLIMATE_OCEANIC and distance_to_sea > 3 and moisture < 4:
		return CLIMATE_CONTINENTAL if moisture >= 2 else CLIMATE_STEPPE
	if climate == CLIMATE_MEDITERRANEAN and (pole_distance < 5 or distance_to_sea > 3):
		return CLIMATE_OCEANIC if distance_to_sea <= 2 and moisture >= 3 else CLIMATE_CONTINENTAL
	if climate == CLIMATE_DESERT and (pole_distance < 6 or moisture >= 2):
		return CLIMATE_ARID if pole_distance >= 5 and moisture <= 2 else CLIMATE_STEPPE
	if climate == CLIMATE_ARID and pole_distance <= 3:
		return CLIMATE_CONTINENTAL if pole_distance >= 3 else CLIMATE_NORDIC
	if climate == CLIMATE_STEPPE and pole_distance <= 2:
		return CLIMATE_NORDIC
	if climate == CLIMATE_TROPICAL and (pole_distance < 6 or moisture < 4):
		if pole_distance <= 3:
			return CLIMATE_CONTINENTAL
		return CLIMATE_OCEANIC if distance_to_sea <= 2 and moisture >= 3 else CLIMATE_MEDITERRANEAN
	if climate == CLIMATE_POLAR and pole_distance > 1 and elevation < 4:
		return CLIMATE_NORDIC

	return climate


func _fix_climate_for_neighbors(climate: String, x: int, y: int, climate_map: Array, water_feature_map: Array, sea_distance_map: Array, moisture_map: Array, elevation_map: Array, relief_map: Array) -> String:
	for offset in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		var neighbor_water := str(_get_layer_value(water_feature_map, x + offset.x, y + offset.y, WATER_NONE))
		if neighbor_water == WATER_SEA:
			continue

		var neighbor_climate := str(_get_layer_value(climate_map, x + offset.x, y + offset.y, ""))
		if neighbor_climate == "":
			continue
		if not _is_forbidden_climate_pair(climate, neighbor_climate):
			continue

		return _get_transition_climate_for_position(x, y, sea_distance_map, moisture_map, elevation_map, relief_map)

	return climate


func _fix_isolated_climate(climate: String, x: int, y: int, climate_map: Array, water_feature_map: Array, sea_distance_map: Array, moisture_map: Array, elevation_map: Array, relief_map: Array) -> String:
	var counts := {}

	for offset_y in range(-1, 2):
		for offset_x in range(-1, 2):
			if offset_x == 0 and offset_y == 0:
				continue

			var neighbor_water := str(_get_layer_value(water_feature_map, x + offset_x, y + offset_y, WATER_NONE))
			if neighbor_water == WATER_SEA:
				continue

			var neighbor_climate := str(_get_layer_value(climate_map, x + offset_x, y + offset_y, ""))
			if neighbor_climate == "" or neighbor_climate == CLIMATE_SEA:
				continue

			counts[neighbor_climate] = int(counts.get(neighbor_climate, 0)) + 1

	var dominant_climate := ""
	var dominant_count := 0
	for key in counts.keys():
		var count := int(counts[key])
		if count > dominant_count:
			dominant_climate = str(key)
			dominant_count = count

	if dominant_count >= 5 and dominant_climate != "" and climate != dominant_climate:
		if not _is_forbidden_climate_pair(dominant_climate, _get_transition_climate_for_position(x, y, sea_distance_map, moisture_map, elevation_map, relief_map)):
			return dominant_climate

	return climate


func _is_forbidden_climate_pair(first_climate: String, second_climate: String) -> bool:
	if first_climate == CLIMATE_SEA or second_climate == CLIMATE_SEA:
		return false

	if first_climate == CLIMATE_POLAR:
		return second_climate == CLIMATE_DESERT or second_climate == CLIMATE_TROPICAL or second_climate == CLIMATE_MEDITERRANEAN
	if second_climate == CLIMATE_POLAR:
		return first_climate == CLIMATE_DESERT or first_climate == CLIMATE_TROPICAL or first_climate == CLIMATE_MEDITERRANEAN
	if first_climate == CLIMATE_NORDIC:
		return second_climate == CLIMATE_DESERT or second_climate == CLIMATE_TROPICAL
	if second_climate == CLIMATE_NORDIC:
		return first_climate == CLIMATE_DESERT or first_climate == CLIMATE_TROPICAL
	if first_climate == CLIMATE_DESERT and (second_climate == CLIMATE_OCEANIC or second_climate == CLIMATE_TROPICAL):
		return true
	if second_climate == CLIMATE_DESERT and (first_climate == CLIMATE_OCEANIC or first_climate == CLIMATE_TROPICAL):
		return true

	return false


func _get_transition_climate_for_position(x: int, y: int, sea_distance_map: Array, moisture_map: Array, elevation_map: Array, relief_map: Array) -> String:
	var pole_distance: int = min(y, map_height - 1 - y)
	var distance_to_sea: int = int(_get_layer_value(sea_distance_map, x, y, 99))
	var moisture: int = int(_get_layer_value(moisture_map, x, y, 2))
	var elevation: int = int(_get_layer_value(elevation_map, x, y, 2))
	var relief: String = str(_get_layer_value(relief_map, x, y, RELIEF_PLAINS))
	var temperature_band: int = pole_distance

	if elevation >= 4:
		temperature_band -= 2
	elif elevation == 3 or relief == RELIEF_HILLS:
		temperature_band -= 1

	temperature_band = max(0, temperature_band)

	if temperature_band <= 1:
		return CLIMATE_NORDIC
	if temperature_band <= 3:
		return CLIMATE_OCEANIC if distance_to_sea <= 2 and moisture >= 3 else CLIMATE_CONTINENTAL
	if temperature_band <= 5:
		return CLIMATE_STEPPE if moisture <= 1 and distance_to_sea >= 4 else CLIMATE_CONTINENTAL
	if moisture >= 4 and distance_to_sea <= 3:
		return CLIMATE_MEDITERRANEAN
	if moisture <= 1 and distance_to_sea >= 4:
		return CLIMATE_ARID
	if moisture == 2:
		return CLIMATE_STEPPE

	return CLIMATE_CONTINENTAL


func _generate_rivers(water_feature_map: Array, elevation_map: Array) -> void:
	_apply_river_path(water_feature_map, elevation_map, [
		Vector2i(6, 3),
		Vector2i(7, 3),
		Vector2i(7, 4),
		Vector2i(8, 4),
		Vector2i(9, 4),
		Vector2i(9, 5),
		Vector2i(9, 6),
		Vector2i(10, 6),
		Vector2i(11, 6),
		Vector2i(11, 7),
		Vector2i(12, 7),
		Vector2i(12, 8),
		Vector2i(13, 8),
		Vector2i(14, 8)
	])
	_apply_river_path(water_feature_map, elevation_map, [
		Vector2i(18, 5),
		Vector2i(19, 5),
		Vector2i(19, 6),
		Vector2i(20, 6),
		Vector2i(20, 7),
		Vector2i(21, 7),
		Vector2i(21, 8),
		Vector2i(22, 8),
		Vector2i(22, 9),
		Vector2i(23, 9)
	])
	_apply_river_path(water_feature_map, elevation_map, [
		Vector2i(15, 11),
		Vector2i(15, 12),
		Vector2i(15, 13),
		Vector2i(14, 13),
		Vector2i(14, 14),
		Vector2i(15, 14)
	])
	_apply_river_path(water_feature_map, elevation_map, [
		Vector2i(5, 5),
		Vector2i(5, 6),
		Vector2i(4, 6),
		Vector2i(4, 7),
		Vector2i(3, 7),
		Vector2i(3, 8),
		Vector2i(2, 8),
		Vector2i(1, 8),
		Vector2i(1, 9),
		Vector2i(0, 9)
	])


func _apply_river_path(water_feature_map: Array, elevation_map: Array, path: Array) -> void:
	if path.size() < 2:
		return

	for index in range(path.size()):
		var point = path[index]
		if not point is Vector2i:
			continue

		var existing_feature := str(_get_layer_value(water_feature_map, point.x, point.y, WATER_NONE))
		if existing_feature == WATER_SEA or existing_feature == WATER_LAKE:
			continue

		var river_feature := WATER_SMALL_RIVER
		if path.size() >= 7 and index > int(path.size() * 0.6):
			river_feature = WATER_MEDIUM_RIVER

		_set_layer_value(water_feature_map, point.x, point.y, river_feature)

		var elevation: int = int(_get_layer_value(elevation_map, point.x, point.y, 2))
		if elevation > 1 and elevation < 4:
			_set_layer_value(elevation_map, point.x, point.y, 1)

	var end_point = path[path.size() - 1]
	if end_point is Vector2i:
		var end_feature := str(_get_layer_value(water_feature_map, end_point.x, end_point.y, WATER_NONE))
		if end_feature != WATER_SEA and end_feature != WATER_LAKE:
			_set_layer_value(water_feature_map, end_point.x, end_point.y, WATER_SWAMP)


func _generate_lakes_and_swamps(water_feature_map: Array, elevation_map: Array) -> void:
	_set_lake_cell(water_feature_map, elevation_map, 13, 8)
	_set_lake_cell(water_feature_map, elevation_map, 14, 8)
	_set_lake_cell(water_feature_map, elevation_map, 14, 9)
	_set_lake_cell(water_feature_map, elevation_map, 3, 10)

	_set_swamp_cell(water_feature_map, elevation_map, 12, 9)
	_set_swamp_cell(water_feature_map, elevation_map, 13, 9)
	_set_swamp_cell(water_feature_map, elevation_map, 15, 9)
	_set_swamp_cell(water_feature_map, elevation_map, 2, 9)


func _set_lake_cell(water_feature_map: Array, elevation_map: Array, x: int, y: int) -> void:
	var existing_feature := str(_get_layer_value(water_feature_map, x, y, WATER_NONE))
	if existing_feature == WATER_SEA:
		return

	_set_layer_value(water_feature_map, x, y, WATER_LAKE)
	_set_layer_value(elevation_map, x, y, 0)


func _set_swamp_cell(water_feature_map: Array, elevation_map: Array, x: int, y: int) -> void:
	var existing_feature := str(_get_layer_value(water_feature_map, x, y, WATER_NONE))

	if existing_feature == WATER_SEA or existing_feature == WATER_LAKE:
		return

	_set_layer_value(water_feature_map, x, y, WATER_SWAMP)
	_set_layer_value(elevation_map, x, y, 1)


func _apply_water_lowlands(elevation_map: Array, water_feature_map: Array) -> void:
	for y in range(map_height):
		for x in range(map_width):
			if not _has_neighbor_with_any_water(water_feature_map, x, y):
				continue

			var current_feature := str(_get_layer_value(water_feature_map, x, y, WATER_NONE))
			if current_feature == WATER_SEA or current_feature == WATER_LAKE:
				continue

			var elevation: int = int(_get_layer_value(elevation_map, x, y, 2))
			if elevation > 1 and elevation < 4:
				_set_layer_value(elevation_map, x, y, 1)


func _generate_relief_layer(elevation_map: Array, water_feature_map: Array) -> Array:
	var relief_map: Array = _create_layer(RELIEF_PLAINS)

	for y in range(map_height):
		for x in range(map_width):
			var elevation: int = int(_get_layer_value(elevation_map, x, y, 2))
			var water_feature := str(_get_layer_value(water_feature_map, x, y, WATER_NONE))
			var relief := RELIEF_PLAINS

			if water_feature == WATER_SEA or water_feature == WATER_LAKE:
				relief = RELIEF_LOWLAND
			elif elevation >= 4:
				relief = RELIEF_MOUNTAINS
			elif elevation == 3:
				relief = RELIEF_ROCKY if x >= int(map_width * 0.62) else RELIEF_HILLS
			elif elevation == 1:
				relief = RELIEF_LOWLAND
			elif x > int(map_width * 0.70) and y >= int(map_height * 0.35) and y <= int(map_height * 0.70):
				relief = RELIEF_PLAINS
			else:
				relief = RELIEF_PLAINS

			_set_layer_value(relief_map, x, y, relief)

	return relief_map


func _generate_humidity_layer(water_feature_map: Array, climate_map: Array, moisture_map: Array) -> Array:
	var humidity_map: Array = _create_layer(2)

	for y in range(map_height):
		for x in range(map_width):
			var climate := str(_get_layer_value(climate_map, x, y, CLIMATE_CONTINENTAL))
			var humidity: int = int(_get_layer_value(moisture_map, x, y, 2))

			match climate:
				CLIMATE_POLAR, CLIMATE_DESERT:
					humidity = min(humidity, 1)
				CLIMATE_ARID, CLIMATE_STEPPE:
					humidity = min(humidity, 2)
				CLIMATE_OCEANIC, CLIMATE_TROPICAL:
					humidity = max(humidity, 4)
				CLIMATE_SEA:
					humidity = 5
				CLIMATE_NORDIC, CLIMATE_CONTINENTAL, CLIMATE_MEDITERRANEAN:
					humidity = max(humidity, 3)

			if _is_near_water_feature(water_feature_map, x, y, [WATER_SEA, WATER_LAKE, WATER_SWAMP, WATER_MEDIUM_RIVER, WATER_LARGE_RIVER, WATER_SMALL_RIVER, WATER_STREAM], 2):
				humidity += 1
			if x > int(map_width * 0.65) and y > int(map_height * 0.55):
				humidity -= 1

			_set_layer_value(humidity_map, x, y, int(clamp(humidity, 0, 5)))

	return humidity_map


func _generate_vegetation_layer(climate_map: Array, relief_map: Array, water_feature_map: Array, humidity_map: Array) -> Array:
	var vegetation_map: Array = _create_layer(VEGETATION_GRASSLAND)

	for y in range(map_height):
		for x in range(map_width):
			var climate := str(_get_layer_value(climate_map, x, y, CLIMATE_CONTINENTAL))
			var relief := str(_get_layer_value(relief_map, x, y, RELIEF_PLAINS))
			var water_feature := str(_get_layer_value(water_feature_map, x, y, WATER_NONE))
			var humidity: int = int(_get_layer_value(humidity_map, x, y, 2))
			var vegetation := VEGETATION_GRASSLAND

			if water_feature == WATER_SEA or water_feature == WATER_LAKE:
				vegetation = VEGETATION_NONE
			elif relief == RELIEF_MOUNTAINS:
				vegetation = VEGETATION_TUNDRA if climate == CLIMATE_POLAR or climate == CLIMATE_NORDIC else VEGETATION_SPARSE_FOREST
			elif water_feature == WATER_SWAMP:
				vegetation = VEGETATION_SHRUBS
			elif climate == CLIMATE_POLAR:
				vegetation = VEGETATION_TUNDRA
			elif climate == CLIMATE_NORDIC:
				vegetation = VEGETATION_TAIGA if humidity >= 3 else VEGETATION_TUNDRA
			elif climate == CLIMATE_DESERT:
				vegetation = VEGETATION_WASTELAND
			elif climate == CLIMATE_ARID:
				vegetation = VEGETATION_SHRUBS if humidity >= 2 else VEGETATION_WASTELAND
			elif climate == CLIMATE_STEPPE:
				vegetation = VEGETATION_STEPPE
			elif climate == CLIMATE_TROPICAL:
				vegetation = VEGETATION_JUNGLE if humidity >= 4 else VEGETATION_SAVANNA
			elif climate == CLIMATE_OCEANIC:
				vegetation = VEGETATION_FOREST if humidity >= 4 else VEGETATION_GRASSLAND
			elif climate == CLIMATE_MEDITERRANEAN:
				vegetation = VEGETATION_SPARSE_FOREST if humidity >= 4 else VEGETATION_SHRUBS
			elif humidity >= 4:
				vegetation = VEGETATION_FOREST
			elif humidity <= 1:
				vegetation = VEGETATION_STEPPE

			_set_layer_value(vegetation_map, x, y, vegetation)

	return vegetation_map


func _generate_terrain_from_natural_layers(relief_map: Array, climate_map: Array, vegetation_map: Array, water_feature_map: Array, humidity_map: Array) -> Array:
	var terrain_map: Array = _create_layer(TERRAIN_PLAINS)

	for y in range(map_height):
		for x in range(map_width):
			var relief := str(_get_layer_value(relief_map, x, y, RELIEF_PLAINS))
			var climate := str(_get_layer_value(climate_map, x, y, CLIMATE_CONTINENTAL))
			var vegetation := str(_get_layer_value(vegetation_map, x, y, VEGETATION_GRASSLAND))
			var water_feature := str(_get_layer_value(water_feature_map, x, y, WATER_NONE))
			var humidity: int = int(_get_layer_value(humidity_map, x, y, 2))
			var terrain := TERRAIN_PLAINS

			if water_feature == WATER_SEA or water_feature == WATER_LAKE or water_feature == WATER_POND:
				terrain = TERRAIN_WATER
			elif relief == RELIEF_MOUNTAINS or relief == RELIEF_ROCKY or relief == RELIEF_PLATEAU:
				terrain = TERRAIN_WASTELAND
			elif climate == CLIMATE_DESERT or (climate == CLIMATE_ARID and humidity <= 1):
				terrain = TERRAIN_WASTELAND
			elif vegetation == VEGETATION_FOREST or vegetation == VEGETATION_TAIGA or vegetation == VEGETATION_JUNGLE or vegetation == VEGETATION_SPARSE_FOREST:
				terrain = TERRAIN_FOREST

			_set_layer_value(terrain_map, x, y, terrain)

	return terrain_map


func _generate_soil_fertility_layer(terrain_map: Array, climate_map: Array, vegetation_map: Array, water_feature_map: Array) -> Array:
	var soil_map: Array = _create_layer(1)

	for y in range(map_height):
		for x in range(map_width):
			var terrain := str(_get_layer_value(terrain_map, x, y, TERRAIN_PLAINS))
			var climate := str(_get_layer_value(climate_map, x, y, CLIMATE_CONTINENTAL))
			var vegetation := str(_get_layer_value(vegetation_map, x, y, VEGETATION_GRASSLAND))
			var water_feature := str(_get_layer_value(water_feature_map, x, y, WATER_NONE))
			var fertility := 1

			if terrain == TERRAIN_WATER:
				fertility = 0
			elif terrain == TERRAIN_WASTELAND:
				fertility = 1
			elif terrain == TERRAIN_FOREST:
				fertility = 3
			else:
				fertility = 2

			if climate == CLIMATE_POLAR or climate == CLIMATE_DESERT:
				fertility -= 1
			if climate == CLIMATE_TROPICAL or climate == CLIMATE_CONTINENTAL or climate == CLIMATE_STEPPE:
				fertility += 1
			if vegetation == VEGETATION_FOREST or vegetation == VEGETATION_JUNGLE or vegetation == VEGETATION_GRASSLAND:
				fertility += 1
			if water_feature != WATER_NONE and water_feature != WATER_SEA and water_feature != WATER_COAST:
				fertility += 1

			_set_layer_value(soil_map, x, y, int(clamp(fertility, 0, 5)))

	return soil_map


func _has_neighbor_with_any_water(water_feature_map: Array, x: int, y: int) -> bool:
	for offset in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		var feature := str(_get_layer_value(water_feature_map, x + offset.x, y + offset.y, WATER_NONE))
		if feature != WATER_NONE:
			return true

	return false


func _has_neighbor_with_water_feature(water_feature_map: Array, x: int, y: int, features: Array) -> bool:
	for offset in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		var feature := str(_get_layer_value(water_feature_map, x + offset.x, y + offset.y, WATER_NONE))
		if features.has(feature):
			return true

	return false


func _is_near_water_feature(water_feature_map: Array, x: int, y: int, features: Array, distance: int) -> bool:
	for check_y in range(y - distance, y + distance + 1):
		for check_x in range(x - distance, x + distance + 1):
			var feature := str(_get_layer_value(water_feature_map, check_x, check_y, WATER_NONE))
			if features.has(feature):
				return true

	return false
