extends Control

const PlayerScript := preload("res://scripts/local/Player.gd")
const ResourceNodeScript := preload("res://scripts/local/ResourceNode.gd")
const CAMP_STORAGE_ITEMS := ["wood", "stone", "berries", "cooked_berries"]

class LocalGridOverlay:
	extends Control

	var grid_width: int = 0
	var grid_height: int = 0
	var cell_size: int = 32
	var selected_cell: Vector2i = Vector2i(-1, -1)
	var grid_data: Array = []

	func setup(new_width: int, new_height: int, new_cell_size: int) -> void:
		grid_width = new_width
		grid_height = new_height
		cell_size = new_cell_size
		size = Vector2(grid_width * cell_size, grid_height * cell_size)
		custom_minimum_size = size
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		queue_redraw()

	func set_selected_cell(new_selected_cell: Vector2i) -> void:
		selected_cell = new_selected_cell
		queue_redraw()

	func set_grid_data(new_grid_data: Array) -> void:
		grid_data = new_grid_data
		queue_redraw()

	func _draw() -> void:
		var grid_size := Vector2(grid_width * cell_size, grid_height * cell_size)

		for cell in grid_data:
			if not cell is Dictionary:
				continue

			var cell_data: Dictionary = cell
			var zone_type := str(cell_data.get("zone_type", "none"))
			if zone_type == "none":
				continue

			var zone_color := _get_zone_color(zone_type)
			if zone_color.a <= 0.0:
				continue

			var cell_rect := Rect2(
				Vector2(int(cell_data.get("x", 0)) * cell_size, int(cell_data.get("y", 0)) * cell_size),
				Vector2(cell_size, cell_size)
			)
			draw_rect(cell_rect, zone_color, true)

		if selected_cell.x >= 0 and selected_cell.y >= 0:
			var selected_rect := Rect2(
				Vector2(selected_cell.x * cell_size, selected_cell.y * cell_size),
				Vector2(cell_size, cell_size)
			)
			draw_rect(selected_rect, Color(1.0, 0.9, 0.25, 0.18), true)
			draw_rect(selected_rect, Color(1.0, 0.9, 0.25, 0.95), false, 2.0)

		var grid_color := Color(1.0, 1.0, 1.0, 0.18)
		for grid_x in range(grid_width + 1):
			var x_pos := float(grid_x * cell_size)
			draw_line(Vector2(x_pos, 0), Vector2(x_pos, grid_size.y), grid_color, 1.0)

		for grid_y in range(grid_height + 1):
			var y_pos := float(grid_y * cell_size)
			draw_line(Vector2(0, y_pos), Vector2(grid_size.x, y_pos), grid_color, 1.0)

	func _get_zone_color(zone_type: String) -> Color:
		match zone_type:
			"residential":
				return Color(0.95, 0.95, 0.72, 0.22)
			"craft":
				return Color(0.55, 0.42, 0.32, 0.22)
			"trade":
				return Color(1.0, 0.86, 0.25, 0.24)
			"agriculture":
				return Color(0.25, 0.85, 0.25, 0.22)
			"extraction":
				return Color(0.24, 0.24, 0.24, 0.28)
			"forestry":
				return Color(0.05, 0.45, 0.16, 0.26)
			"administration":
				return Color(0.25, 0.48, 0.95, 0.24)
			"military":
				return Color(0.9, 0.22, 0.18, 0.24)
			_:
				return Color(0, 0, 0, 0)

var selected_tile = null
var show_local_grid: bool = true
var selected_local_cell: Vector2i = Vector2i(-1, -1)
var local_map_offset: Vector2 = Vector2.ZERO
var is_panning_map: bool = false
var last_pan_mouse_position: Vector2 = Vector2.ZERO
var zoning_mode_enabled: bool = false
var selected_zone_type: String = GameState.ZONE_RESIDENTIAL
var day_label: Label
var time_label: Label
var health_label: Label
var hunger_label: Label
var energy_label: Label
var global_tile_label: Label
var danger_label: Label
var inventory_label: Label
var skills_label: Label
var action_costs_label: Label
var tutorial_goals_label: Label
var local_tabs: TabContainer
var character_tab: VBoxContainer
var camp_tab: VBoxContainer
var land_tab: VBoxContainer
var journal_tab: VBoxContainer
var camp_status_label: Label
var campfire_status_label: Label
var campfire_requirements_label: Label
var camp_storage_label: Label
var version_label: Label
var hint_label: Label
var hover_cell_label: Label
var local_cell_info_label: Label
var help_overlay: ColorRect
var help_panel: PanelContainer
var eat_berries_button: Button
var eat_cooked_berries_button: Button
var quick_rest_button: Button
var build_camp_button: Button
var prepare_campfire_resources_button: Button
var build_campfire_button: Button
var cooking_status_label: Label
var cook_berries_button: Button
var rest_button: Button
var deposit_buttons: Dictionary = {}
var withdraw_buttons: Dictionary = {}
var journal_label: Label
var local_map_view: PanelContainer
var local_map_clip: Control
var local_map_root: Control
var terrain_background: ColorRect
var objects_layer: Control
var grid_overlay: LocalGridOverlay
var player_node = null
var camp_node: ColorRect
var campfire_node: ColorRect
var grid_button: Button
var zoning_button: Button
var zone_buttons: Dictionary = {}
var selected_zone_label: Label


func _ready() -> void:
	GameState.initialize_player_data()
	GameState.initialize_map()

	if GameState.selected_tile == null:
		GameState.select_tile(GameState.get_tile(0, 0))

	selected_tile = GameState.selected_tile
	selected_tile.visited = true
	GameState.move_player_to_tile(selected_tile)
	selected_tile.ensure_local_grid_initialized(GameState.LOCAL_GRID_WIDTH, GameState.LOCAL_GRID_HEIGHT)

	_build_scene()


func _build_scene() -> void:
	var background := ColorRect.new()
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.color = Color.html("#1b1a17")
	add_child(background)

	_build_ui()
	_spawn_objects(objects_layer, selected_tile.terrain_type)
	_spawn_camp_if_needed()
	_spawn_campfire_if_needed()
	_build_grid_overlay()

	player_node = PlayerScript.new()
	player_node.set_world_bounds(
		GameState.get_local_map_pixel_width(),
		GameState.get_local_map_pixel_height()
	)
	player_node.position = Vector2(
		GameState.get_local_map_pixel_width() / 2.0,
		GameState.get_local_map_pixel_height() / 2.0
	)
	local_map_root.add_child(player_node)
	call_deferred("_center_map_on_player")


func _build_ui() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(margin)

	var main_ui_column := VBoxContainer.new()
	main_ui_column.add_theme_constant_override("separation", 10)
	main_ui_column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(main_ui_column)

	var top_bar := HBoxContainer.new()
	top_bar.add_theme_constant_override("separation", 12)
	top_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	main_ui_column.add_child(top_bar)

	var back_button := Button.new()
	back_button.text = "Назад на карту"
	back_button.pressed.connect(_on_back_button_pressed)
	top_bar.add_child(back_button)

	var help_button := Button.new()
	help_button.text = "Справка"
	help_button.pressed.connect(_toggle_help_panel)
	top_bar.add_child(help_button)

	grid_button = Button.new()
	grid_button.text = "Сетка: вкл"
	grid_button.pressed.connect(_toggle_local_grid)
	top_bar.add_child(grid_button)

	zoning_button = Button.new()
	zoning_button.text = "Зоны: выкл"
	zoning_button.pressed.connect(_toggle_zoning_mode)
	top_bar.add_child(zoning_button)

	var center_map_button := Button.new()
	center_map_button.text = "К игроку"
	center_map_button.pressed.connect(_center_map_on_player)
	top_bar.add_child(center_map_button)

	version_label = Label.new()
	version_label.text = GameState.get_version_text()
	top_bar.add_child(version_label)

	var tile_label := Label.new()
	tile_label.text = "Тайл: %d, %d | %s" % [
		selected_tile.x,
		selected_tile.y,
		GameState.get_terrain_display_name(selected_tile.terrain_type)
	]
	top_bar.add_child(tile_label)

	hover_cell_label = Label.new()
	hover_cell_label.text = "Клетка: -"
	top_bar.add_child(hover_cell_label)

	var hint_panel := PanelContainer.new()
	hint_panel.custom_minimum_size = Vector2(540, 0)
	main_ui_column.add_child(hint_panel)

	var hint_margin := MarginContainer.new()
	hint_margin.add_theme_constant_override("margin_left", 10)
	hint_margin.add_theme_constant_override("margin_top", 6)
	hint_margin.add_theme_constant_override("margin_right", 10)
	hint_margin.add_theme_constant_override("margin_bottom", 6)
	hint_panel.add_child(hint_margin)

	hint_label = Label.new()
	hint_label.custom_minimum_size = Vector2(520, 0)
	hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint_margin.add_child(hint_label)

	var main_content_row := HBoxContainer.new()
	main_content_row.add_theme_constant_override("separation", 12)
	main_content_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_content_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	main_ui_column.add_child(main_content_row)

	_build_local_map_view(main_content_row)

	var player_panel := PanelContainer.new()
	player_panel.custom_minimum_size = Vector2(330, 0)
	main_content_row.add_child(player_panel)

	var player_margin := MarginContainer.new()
	player_margin.add_theme_constant_override("margin_left", 10)
	player_margin.add_theme_constant_override("margin_top", 8)
	player_margin.add_theme_constant_override("margin_right", 10)
	player_margin.add_theme_constant_override("margin_bottom", 8)
	player_panel.add_child(player_margin)

	var player_column := VBoxContainer.new()
	player_column.add_theme_constant_override("separation", 4)
	player_margin.add_child(player_column)

	local_tabs = TabContainer.new()
	local_tabs.custom_minimum_size = Vector2(300, 0)
	player_column.add_child(local_tabs)

	character_tab = VBoxContainer.new()
	character_tab.name = "Персонаж"
	character_tab.add_theme_constant_override("separation", 4)
	local_tabs.add_child(character_tab)

	camp_tab = VBoxContainer.new()
	camp_tab.name = "Лагерь"
	camp_tab.add_theme_constant_override("separation", 4)
	local_tabs.add_child(camp_tab)

	land_tab = VBoxContainer.new()
	land_tab.name = "Земля"
	land_tab.add_theme_constant_override("separation", 4)
	local_tabs.add_child(land_tab)

	journal_tab = VBoxContainer.new()
	journal_tab.name = "Журнал"
	journal_tab.add_theme_constant_override("separation", 4)
	local_tabs.add_child(journal_tab)

	day_label = Label.new()
	character_tab.add_child(day_label)

	time_label = Label.new()
	character_tab.add_child(time_label)

	health_label = Label.new()
	character_tab.add_child(health_label)

	hunger_label = Label.new()
	character_tab.add_child(hunger_label)

	energy_label = Label.new()
	character_tab.add_child(energy_label)

	global_tile_label = Label.new()
	character_tab.add_child(global_tile_label)

	danger_label = Label.new()
	character_tab.add_child(danger_label)

	inventory_label = Label.new()
	character_tab.add_child(inventory_label)

	skills_label = Label.new()
	skills_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	character_tab.add_child(skills_label)

	action_costs_label = Label.new()
	action_costs_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	character_tab.add_child(action_costs_label)

	var tutorial_goals_scroll := ScrollContainer.new()
	tutorial_goals_scroll.custom_minimum_size = Vector2(0, 120)
	tutorial_goals_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	character_tab.add_child(tutorial_goals_scroll)

	tutorial_goals_label = Label.new()
	tutorial_goals_label.custom_minimum_size = Vector2(250, 0)
	tutorial_goals_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tutorial_goals_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tutorial_goals_scroll.add_child(tutorial_goals_label)

	quick_rest_button = Button.new()
	quick_rest_button.text = "Передохнуть"
	quick_rest_button.pressed.connect(_on_quick_rest_pressed)
	character_tab.add_child(quick_rest_button)

	eat_berries_button = Button.new()
	eat_berries_button.text = "Съесть ягоды"
	eat_berries_button.pressed.connect(_on_eat_berries_pressed)
	character_tab.add_child(eat_berries_button)

	eat_cooked_berries_button = Button.new()
	eat_cooked_berries_button.text = "Съесть приготовленные ягоды"
	eat_cooked_berries_button.pressed.connect(_on_eat_cooked_berries_pressed)
	character_tab.add_child(eat_cooked_berries_button)

	camp_status_label = Label.new()
	camp_tab.add_child(camp_status_label)

	build_camp_button = Button.new()
	build_camp_button.text = "Поставить лагерь"
	build_camp_button.pressed.connect(_on_build_camp_pressed)
	camp_tab.add_child(build_camp_button)

	campfire_status_label = Label.new()
	camp_tab.add_child(campfire_status_label)

	campfire_requirements_label = Label.new()
	campfire_requirements_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	camp_tab.add_child(campfire_requirements_label)

	prepare_campfire_resources_button = Button.new()
	prepare_campfire_resources_button.text = "Подготовить ресурсы для костра"
	prepare_campfire_resources_button.pressed.connect(_on_prepare_campfire_resources_pressed)
	camp_tab.add_child(prepare_campfire_resources_button)

	build_campfire_button = Button.new()
	build_campfire_button.text = "Построить костёр"
	build_campfire_button.pressed.connect(_on_build_campfire_pressed)
	camp_tab.add_child(build_campfire_button)

	cooking_status_label = Label.new()
	camp_tab.add_child(cooking_status_label)

	cook_berries_button = Button.new()
	cook_berries_button.text = "Приготовить ягоды"
	cook_berries_button.pressed.connect(_on_cook_berries_pressed)
	camp_tab.add_child(cook_berries_button)

	rest_button = Button.new()
	rest_button.text = "Нет лагеря для отдыха"
	rest_button.pressed.connect(_on_rest_at_camp_pressed)
	camp_tab.add_child(rest_button)

	camp_storage_label = Label.new()
	camp_tab.add_child(camp_storage_label)

	_build_camp_storage_buttons(camp_tab)
	_build_land_tab()

	var journal_title := Label.new()
	journal_title.text = "Журнал:"
	journal_tab.add_child(journal_title)

	journal_label = Label.new()
	journal_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	journal_tab.add_child(journal_label)

	_update_player_panel()
	_update_local_cell_info_ui()
	_build_help_panel()


func _update_player_panel() -> void:
	var player_data = GameState.player_data

	day_label.text = "День: %d" % GameState.day
	time_label.text = "Время: %s" % GameState.get_time_text()
	health_label.text = "Здоровье: %d" % player_data.health
	hunger_label.text = "Голод: %d" % player_data.hunger
	energy_label.text = "Энергия: %d" % player_data.energy
	global_tile_label.text = "Глобальный тайл: %d, %d" % [player_data.global_x, player_data.global_y]
	danger_label.text = "Опасность тайла: %d, риск при сборе: %d%%" % [
		GameState.get_selected_tile_danger_level(),
		GameState.get_gather_risk_chance()
	]
	hint_label.text = _get_hint_text()
	inventory_label.text = "Инвентарь: %s" % _get_inventory_text(player_data.inventory)
	skills_label.text = _get_skills_text()
	action_costs_label.text = _get_action_costs_text()
	if tutorial_goals_label != null:
		tutorial_goals_label.text = GameState.get_tutorial_goals_text()
	quick_rest_button.disabled = player_data.energy >= 100
	eat_berries_button.disabled = not GameState.can_eat_berries()
	eat_cooked_berries_button.disabled = not GameState.can_eat_cooked_berries()
	_update_camp_status_label()
	_update_camp_button()
	_update_campfire_ui()
	_update_campfire_requirements_ui()
	_update_prepare_campfire_button()
	_update_cooking_ui()
	_update_rest_button()
	_update_camp_storage_ui()
	_update_camp_storage_buttons()
	_update_journal_ui()
	_update_local_cell_info_ui()
	_update_zoning_ui()


func _build_land_tab() -> void:
	var title_label := Label.new()
	title_label.text = "Разметка земли"
	land_tab.add_child(title_label)

	var description_label := Label.new()
	description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description_label.text = "Выберите тип зоны и кликните по клеткам локальной карты. Это основа будущего градостроительного режима."
	land_tab.add_child(description_label)

	var zone_buttons_grid := GridContainer.new()
	zone_buttons_grid.columns = 2
	land_tab.add_child(zone_buttons_grid)

	var zone_button_data := [
		[GameState.ZONE_NONE, "Нет зоны"],
		[GameState.ZONE_RESIDENTIAL, "Жилая"],
		[GameState.ZONE_CRAFT, "Ремесленная"],
		[GameState.ZONE_TRADE, "Торговая"],
		[GameState.ZONE_AGRICULTURE, "Сельхоз"],
		[GameState.ZONE_EXTRACTION, "Добыча"],
		[GameState.ZONE_FORESTRY, "Лес"],
		[GameState.ZONE_ADMINISTRATION, "Админ"],
		[GameState.ZONE_MILITARY, "Военная"]
	]

	for zone_data in zone_button_data:
		var zone_type := str(zone_data[0])
		var zone_title := str(zone_data[1])
		var zone_button := Button.new()
		zone_button.text = zone_title
		zone_button.pressed.connect(_select_zone_type.bind(zone_type))
		zone_buttons_grid.add_child(zone_button)
		zone_buttons[zone_type] = zone_button

	selected_zone_label = Label.new()
	selected_zone_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	land_tab.add_child(selected_zone_label)

	local_cell_info_label = Label.new()
	local_cell_info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	land_tab.add_child(local_cell_info_label)


func _build_local_map_view(parent: Control) -> void:
	local_map_view = PanelContainer.new()
	local_map_view.custom_minimum_size = Vector2(640, 480)
	local_map_view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	local_map_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	local_map_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(local_map_view)

	local_map_clip = Control.new()
	local_map_clip.clip_contents = true
	local_map_clip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	local_map_clip.size_flags_vertical = Control.SIZE_EXPAND_FILL
	local_map_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	local_map_view.add_child(local_map_clip)

	local_map_root = Control.new()
	local_map_root.size = Vector2(
		GameState.get_local_map_pixel_width(),
		GameState.get_local_map_pixel_height()
	)
	local_map_root.custom_minimum_size = local_map_root.size
	local_map_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	local_map_clip.add_child(local_map_root)

	terrain_background = ColorRect.new()
	terrain_background.position = Vector2.ZERO
	terrain_background.size = local_map_root.size
	terrain_background.color = GameState.get_local_background_color(selected_tile.terrain_type)
	terrain_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	local_map_root.add_child(terrain_background)

	objects_layer = Control.new()
	objects_layer.position = Vector2.ZERO
	objects_layer.size = local_map_root.size
	objects_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	local_map_root.add_child(objects_layer)


func _build_grid_overlay() -> void:
	grid_overlay = LocalGridOverlay.new()
	grid_overlay.name = "LocalGridOverlay"
	grid_overlay.setup(GameState.LOCAL_GRID_WIDTH, GameState.LOCAL_GRID_HEIGHT, GameState.LOCAL_CELL_SIZE)
	grid_overlay.set_grid_data(selected_tile.local_grid)
	grid_overlay.visible = show_local_grid
	local_map_root.add_child(grid_overlay)
	_update_grid_button()


func _toggle_local_grid() -> void:
	show_local_grid = not show_local_grid

	if grid_overlay != null:
		grid_overlay.visible = show_local_grid

	_update_grid_button()


func _update_grid_button() -> void:
	if grid_button == null:
		return

	if show_local_grid:
		grid_button.text = "Сетка: вкл"
	else:
		grid_button.text = "Сетка: выкл"


func _toggle_zoning_mode() -> void:
	zoning_mode_enabled = not zoning_mode_enabled
	_update_zoning_ui()


func _select_zone_type(zone_type: String) -> void:
	selected_zone_type = zone_type
	_update_zoning_ui()


func _update_zoning_ui() -> void:
	if zoning_button != null:
		if zoning_mode_enabled:
			zoning_button.text = "Зоны: вкл"
		else:
			zoning_button.text = "Зоны: выкл"

	if selected_zone_label != null:
		selected_zone_label.text = "Выбрана зона: %s" % GameState.get_zone_title(selected_zone_type)

	for zone_type in zone_buttons.keys():
		var zone_button: Button = zone_buttons[zone_type]
		zone_button.disabled = str(zone_type) == selected_zone_type


func _set_local_map_offset(new_offset: Vector2) -> void:
	local_map_offset = new_offset
	_clamp_local_map_offset()

	if local_map_root != null:
		local_map_root.position = local_map_offset


func _clamp_local_map_offset() -> void:
	if local_map_clip == null:
		return

	var view_size := local_map_clip.size
	var map_size := Vector2(
		GameState.get_local_map_pixel_width(),
		GameState.get_local_map_pixel_height()
	)

	if map_size.x <= view_size.x:
		local_map_offset.x = 0.0
	else:
		local_map_offset.x = clamp(local_map_offset.x, view_size.x - map_size.x, 0.0)

	if map_size.y <= view_size.y:
		local_map_offset.y = 0.0
	else:
		local_map_offset.y = clamp(local_map_offset.y, view_size.y - map_size.y, 0.0)


func _center_map_on_player() -> void:
	if player_node == null or local_map_clip == null:
		return

	var player_center: Vector2 = player_node.position + player_node.size * 0.5
	var wanted_offset: Vector2 = local_map_clip.size * 0.5 - player_center
	_set_local_map_offset(wanted_offset)


func _is_screen_position_inside_map(screen_position: Vector2) -> bool:
	if local_map_clip == null:
		return false

	return local_map_clip.get_global_rect().has_point(screen_position)


func _screen_position_to_local_map_position(screen_position: Vector2) -> Vector2:
	if local_map_clip == null:
		return Vector2(-1, -1)

	return screen_position - local_map_clip.global_position - local_map_offset


func _get_local_cell_coords_at_position(screen_position: Vector2) -> Vector2i:
	if not _is_screen_position_inside_map(screen_position):
		return Vector2i(-1, -1)

	var local_map_position := _screen_position_to_local_map_position(screen_position)
	var cell_x := int(floor(local_map_position.x / GameState.LOCAL_CELL_SIZE))
	var cell_y := int(floor(local_map_position.y / GameState.LOCAL_CELL_SIZE))

	if cell_x < 0 or cell_y < 0:
		return Vector2i(-1, -1)
	if cell_x >= GameState.LOCAL_GRID_WIDTH or cell_y >= GameState.LOCAL_GRID_HEIGHT:
		return Vector2i(-1, -1)

	return Vector2i(cell_x, cell_y)


func _update_hovered_local_cell(screen_position: Vector2) -> void:
	if hover_cell_label == null:
		return

	var cell_coords := _get_local_cell_coords_at_position(screen_position)
	if cell_coords.x < 0:
		hover_cell_label.text = "Клетка: -"
	else:
		hover_cell_label.text = "Клетка: %d,%d" % [cell_coords.x, cell_coords.y]


func _select_local_cell_at_position(screen_position: Vector2) -> bool:
	var cell_coords := _get_local_cell_coords_at_position(screen_position)
	if cell_coords.x < 0:
		return false

	selected_local_cell = cell_coords

	if zoning_mode_enabled:
		_apply_zone_to_selected_cell()

	if grid_overlay != null:
		grid_overlay.set_selected_cell(selected_local_cell)

	_update_local_cell_info_ui()
	return true


func _apply_zone_to_selected_cell() -> void:
	if selected_tile == null or selected_local_cell.x < 0:
		return

	var changed: bool = selected_tile.set_zone_for_cell(
		selected_local_cell.x,
		selected_local_cell.y,
		GameState.LOCAL_GRID_WIDTH,
		selected_zone_type
	)

	if not changed:
		return

	GameState.add_journal_entry(
		"zoning",
		"Зона изменена",
		"Клетка %d,%d: %s" % [
			selected_local_cell.x,
			selected_local_cell.y,
			GameState.get_zone_title(selected_zone_type)
		]
	)
	_update_grid_overlay_data()


func _update_grid_overlay_data() -> void:
	if grid_overlay == null or selected_tile == null:
		return

	grid_overlay.set_grid_data(selected_tile.local_grid)


func _update_local_cell_info_ui() -> void:
	if local_cell_info_label == null:
		return

	if selected_tile == null or selected_local_cell.x < 0:
		local_cell_info_label.text = "Клетка: не выбрана"
		return

	var cell: Dictionary = selected_tile.get_local_cell(
		selected_local_cell.x,
		selected_local_cell.y,
		GameState.LOCAL_GRID_WIDTH
	)

	if cell.is_empty():
		local_cell_info_label.text = "Клетка: не выбрана"
		return

	var building_text := str(cell.get("building_id", ""))
	if building_text == "":
		building_text = "нет"

	var resource_text := str(cell.get("resource_type", ""))
	if resource_text == "":
		resource_text = "нет"
	else:
		resource_text = "%s %d" % [resource_text, int(cell.get("resource_amount", 0))]

	var zone_type := str(cell.get("zone_type", GameState.ZONE_NONE))
	var land_value := int(cell.get("land_value", 1))
	var land_status := str(cell.get("land_status", "poor"))
	var free_text := "нет"
	if selected_tile.is_local_cell_free_for_building(
		selected_local_cell.x,
		selected_local_cell.y,
		GameState.LOCAL_GRID_WIDTH
	):
		free_text = "да"

	local_cell_info_label.text = "\n".join([
		"Клетка: %d,%d" % [selected_local_cell.x, selected_local_cell.y],
		"Тип: %s" % str(cell.get("terrain_type", "")),
		"Зона: %s" % GameState.get_zone_title(zone_type),
		"Статус земли: %s" % land_status,
		"Ценность земли: %d" % land_value,
		"Здание: %s" % building_text,
		"Ресурс: %s" % resource_text,
		"Свободна для здания: %s" % free_text
	])


func _build_camp_storage_buttons(parent: Control) -> void:
	for item_name in CAMP_STORAGE_ITEMS:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		parent.add_child(row)

		var deposit_button := Button.new()
		deposit_button.text = "Сложить %s" % item_name
		deposit_button.pressed.connect(_on_deposit_item_pressed.bind(item_name))
		row.add_child(deposit_button)
		deposit_buttons[item_name] = deposit_button

		var withdraw_button := Button.new()
		withdraw_button.text = "Забрать %s" % item_name
		withdraw_button.pressed.connect(_on_withdraw_item_pressed.bind(item_name))
		row.add_child(withdraw_button)
		withdraw_buttons[item_name] = withdraw_button


func _update_camp_button() -> void:
	build_camp_button.tooltip_text = ""

	if selected_tile == null:
		build_camp_button.text = "Поставить лагерь"
		build_camp_button.disabled = true
		return

	if selected_tile.has_camp:
		build_camp_button.text = "Лагерь уже стоит"
		build_camp_button.disabled = true
		return

	build_camp_button.text = "Поставить лагерь"
	var can_build: bool = GameState.can_build_camp_on_selected_tile()
	var has_energy: bool = GameState.has_enough_energy(GameState.BUILD_CAMP_ENERGY_COST)
	build_camp_button.disabled = not can_build or not has_energy

	if not has_energy:
		build_camp_button.tooltip_text = "Недостаточно энергии"


func _update_camp_status_label() -> void:
	if selected_tile == null:
		camp_status_label.text = "Лагерь: -"
	elif selected_tile.has_camp:
		camp_status_label.text = "Лагерь: есть"
	else:
		camp_status_label.text = "Лагерь: нет"


func _update_rest_button() -> void:
	if selected_tile == null or not selected_tile.has_camp:
		rest_button.text = "Нет лагеря для отдыха"
		rest_button.disabled = true
		return

	rest_button.text = "Отдохнуть в лагере"
	rest_button.disabled = GameState.player_data.energy >= 100 and GameState.player_data.health >= 100


func _update_campfire_ui() -> void:
	build_campfire_button.tooltip_text = ""

	if selected_tile == null or not selected_tile.has_camp:
		campfire_status_label.text = "Костёр: нет лагеря"
		build_campfire_button.text = "Построить костёр"
		build_campfire_button.disabled = true
		return

	if GameState.has_campfire_on_selected_tile():
		campfire_status_label.text = "Костёр: есть"
		build_campfire_button.text = "Костёр уже есть"
		build_campfire_button.disabled = true
		return

	campfire_status_label.text = "Костёр: нет"
	build_campfire_button.text = "Построить костёр"
	var can_build: bool = GameState.can_build_campfire_on_selected_tile()
	var has_energy: bool = GameState.has_enough_energy(GameState.BUILD_CAMPFIRE_ENERGY_COST)
	build_campfire_button.disabled = not can_build or not has_energy

	if not has_energy:
		build_campfire_button.tooltip_text = "Недостаточно энергии"
	elif build_campfire_button.disabled:
		build_campfire_button.tooltip_text = "Нужно в складе лагеря: wood 3, stone 1"


func _update_campfire_requirements_ui() -> void:
	var status: Dictionary = GameState.get_campfire_requirements_status()

	if not bool(status["has_camp"]):
		campfire_requirements_label.text = "Костёр: сначала нужен лагерь"
		return

	if bool(status["has_campfire"]):
		campfire_requirements_label.text = "Костёр построен."
		return

	campfire_requirements_label.text = "Для костра нужно в складе: wood %d, stone %d. В складе: wood %d/%d, stone %d/%d. В инвентаре: wood %d, stone %d." % [
		int(status["required_wood"]),
		int(status["required_stone"]),
		int(status["storage_wood"]),
		int(status["required_wood"]),
		int(status["storage_stone"]),
		int(status["required_stone"]),
		int(status["inventory_wood"]),
		int(status["inventory_stone"])
	]


func _update_prepare_campfire_button() -> void:
	prepare_campfire_resources_button.text = "Подготовить ресурсы для костра"
	prepare_campfire_resources_button.tooltip_text = ""

	var status: Dictionary = GameState.get_campfire_requirements_status()
	if not bool(status["has_camp"]):
		prepare_campfire_resources_button.disabled = true
		prepare_campfire_resources_button.tooltip_text = "Сначала нужен лагерь."
		return

	if bool(status["has_campfire"]):
		prepare_campfire_resources_button.disabled = true
		prepare_campfire_resources_button.tooltip_text = "Костёр уже построен."
		return

	var missing_wood: int = int(status["missing_storage_wood"])
	var missing_stone: int = int(status["missing_storage_stone"])
	var inventory_wood: int = int(status["inventory_wood"])
	var inventory_stone: int = int(status["inventory_stone"])
	var storage_needs_resources: bool = missing_wood > 0 or missing_stone > 0
	var can_move_resources: bool = (missing_wood > 0 and inventory_wood > 0) or (missing_stone > 0 and inventory_stone > 0)

	prepare_campfire_resources_button.disabled = not (storage_needs_resources and can_move_resources)

	if prepare_campfire_resources_button.disabled:
		if not storage_needs_resources:
			prepare_campfire_resources_button.tooltip_text = "Все ресурсы для костра уже в складе."
		else:
			prepare_campfire_resources_button.tooltip_text = "В инвентаре нет недостающих ресурсов."


func _update_camp_storage_ui() -> void:
	camp_storage_label.text = "Склад лагеря: %s" % _get_camp_storage_text()


func _update_cooking_ui() -> void:
	cook_berries_button.text = "Приготовить ягоды"
	cook_berries_button.tooltip_text = ""

	if selected_tile == null or not selected_tile.has_camp:
		cooking_status_label.text = "Готовка: нужен лагерь"
		cook_berries_button.disabled = true
		return

	if not GameState.has_campfire_on_selected_tile():
		cooking_status_label.text = "Готовка: нужен костёр"
		cook_berries_button.disabled = true
		return

	var berries_in_storage: int = int(selected_tile.camp_storage.get("berries", 0))
	var can_cook: bool = GameState.can_cook_berries_at_campfire()
	var has_energy: bool = GameState.has_enough_energy(GameState.COOK_BERRIES_ENERGY_COST)

	if can_cook and has_energy:
		cooking_status_label.text = "Готовка: можно приготовить ягоды"
		cook_berries_button.disabled = false
	elif can_cook and not has_energy:
		cooking_status_label.text = "Готовка: не хватает энергии"
		cook_berries_button.disabled = true
		cook_berries_button.tooltip_text = "Недостаточно энергии"
	else:
		cooking_status_label.text = "Готовка: нужно berries 2 в складе. В складе berries: %d" % berries_in_storage
		cook_berries_button.disabled = true
		cook_berries_button.tooltip_text = "Нужно berries 2 в складе лагеря."


func _update_camp_storage_buttons() -> void:
	for item_name in CAMP_STORAGE_ITEMS:
		var deposit_button: Button = deposit_buttons[item_name]
		var withdraw_button: Button = withdraw_buttons[item_name]

		deposit_button.disabled = not _can_deposit_item(item_name)
		withdraw_button.disabled = not _can_withdraw_item(item_name)


func _can_deposit_item(item_name: String) -> bool:
	if selected_tile == null or not selected_tile.has_camp:
		return false

	return int(GameState.player_data.inventory.get(item_name, 0)) >= 1


func _can_withdraw_item(item_name: String) -> bool:
	if selected_tile == null or not selected_tile.has_camp:
		return false

	return int(selected_tile.camp_storage.get(item_name, 0)) >= 1


func _get_camp_storage_text() -> String:
	if selected_tile == null or not selected_tile.has_camp:
		return "нет лагеря"
	if selected_tile.camp_storage.is_empty():
		return "пусто"

	return _get_inventory_text(selected_tile.camp_storage)


func _update_journal_ui() -> void:
	journal_label.text = _get_journal_text()


func _get_journal_text() -> String:
	var recent_entries := GameState.get_recent_journal_entries(6)
	if recent_entries.is_empty():
		return "Журнал пуст"

	var lines: Array = []

	for entry in recent_entries:
		var line := "[День %d %02d:00] %s" % [
			int(entry.get("day", 1)),
			int(entry.get("hour", 0)),
			str(entry.get("title", ""))
		]
		var description := str(entry.get("description", ""))
		if description != "":
			line += ": %s" % description

		lines.append(line)

	return "\n".join(lines)


func _build_help_panel() -> void:
	var panel_size := Vector2(500, 420)

	help_overlay = ColorRect.new()
	help_overlay.visible = false
	help_overlay.z_index = 99
	help_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	help_overlay.color = Color(0, 0, 0, 0.35)
	help_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(help_overlay)

	help_panel = PanelContainer.new()
	help_panel.visible = false
	help_panel.z_index = 100
	help_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	help_panel.custom_minimum_size = panel_size
	help_panel.size = panel_size
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.07, 0.07, 0.06, 0.96)
	panel_style.border_color = Color(0.55, 0.48, 0.34)
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(6)
	help_panel.add_theme_stylebox_override("panel", panel_style)
	add_child(help_panel)
	_center_help_panel()

	var help_margin := MarginContainer.new()
	help_margin.add_theme_constant_override("margin_left", 16)
	help_margin.add_theme_constant_override("margin_top", 14)
	help_margin.add_theme_constant_override("margin_right", 16)
	help_margin.add_theme_constant_override("margin_bottom", 14)
	help_panel.add_child(help_margin)

	var help_column := VBoxContainer.new()
	help_column.add_theme_constant_override("separation", 8)
	help_margin.add_child(help_column)

	var title_label := Label.new()
	title_label.text = "Справка: Локальный тайл"
	help_column.add_child(title_label)

	var scroll_container := ScrollContainer.new()
	scroll_container.custom_minimum_size = Vector2(0, 320)
	scroll_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	help_column.add_child(scroll_container)

	var help_label := Label.new()
	help_label.custom_minimum_size = Vector2(440, 0)
	help_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	help_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	help_label.text = _get_help_text()
	scroll_container.add_child(help_label)

	var close_button := Button.new()
	close_button.text = "Закрыть"
	close_button.pressed.connect(_hide_help_panel)
	help_column.add_child(close_button)


func _toggle_help_panel() -> void:
	if help_panel == null or help_overlay == null:
		return

	var new_visible := not help_panel.visible
	help_panel.visible = new_visible
	help_overlay.visible = new_visible

	if new_visible:
		_center_help_panel()


func _hide_help_panel() -> void:
	if help_panel != null:
		help_panel.visible = false
	if help_overlay != null:
		help_overlay.visible = false


func _center_help_panel() -> void:
	if help_panel == null:
		return

	help_panel.position = (get_viewport_rect().size - help_panel.size) * 0.5


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F1:
			_toggle_help_panel()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_ESCAPE and help_panel != null and help_panel.visible:
			_hide_help_panel()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_G:
			_toggle_local_grid()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_C:
			_center_map_on_player()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_Z:
			_toggle_zoning_mode()
			get_viewport().set_input_as_handled()

	if event is InputEventMouseMotion:
		if is_panning_map:
			var pan_delta: Vector2 = event.position - last_pan_mouse_position
			last_pan_mouse_position = event.position
			_set_local_map_offset(local_map_offset + pan_delta)
			get_viewport().set_input_as_handled()
		else:
			_update_hovered_local_cell(event.position)
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_MIDDLE:
			if event.pressed and _is_screen_position_inside_map(event.position):
				is_panning_map = true
				last_pan_mouse_position = event.position
				get_viewport().set_input_as_handled()
			elif not event.pressed:
				is_panning_map = false
				get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_LEFT and event.pressed and not is_panning_map:
			if _select_local_cell_at_position(event.position):
				get_viewport().set_input_as_handled()


func _get_hint_text() -> String:
	if selected_tile == null or not selected_tile.has_camp:
		return "Цель: соберите ресурсы и постройте лагерь."
	if not GameState.has_campfire_on_selected_tile():
		return "Цель: перенесите ресурсы в склад лагеря и постройте костёр."

	return "Цель: готовьте еду, отдыхайте и продолжайте исследование."


func _get_help_text() -> String:
	return "\n".join([
		"Локальный тайл",
		"",
		"WASD — движение персонажа.",
		"Клик по ресурсу — собрать ресурс.",
		"Сбор тратит энергию.",
		"Ягоды можно есть сырыми.",
		"Чтобы развиваться дальше: соберите дерево и камень, поставьте лагерь, сложите ресурсы в склад, постройте костёр.",
		"Костёр позволяет готовить ягоды.",
		"Приготовленные ягоды полезнее обычных.",
		"Опасность тайла создаёт риск при сборе ресурсов.",
		"Навыки растут от действий.",
		"Первые цели помогают пройти базовый цикл выживания.",
		"Полный список первых целей находится во вкладке Персонаж.",
		"Локальная карта стала большой клеточной территорией.",
		"Сетка показывает землю внутри выбранного глобального тайла.",
		"В будущем игрок сможет размечать зоны, а NPC будут строить внутри разрешённых зон.",
		"Важные здания лорда будут размещаться игроком вручную.",
		"Средняя кнопка мыши + движение — двигать карту.",
		"C — центрировать карту на игроке.",
		"G — показать или скрыть сетку.",
		"Z — включить или выключить режим разметки зон.",
		"Во вкладке 'Земля' можно выбрать тип зоны.",
		"В режиме зон клик по клетке меняет её назначение.",
		"Зоны пока не строят здания автоматически. Это подготовка к будущим NPC и экономике поселения.",
		"Лорд размечает землю, а в будущих версиях NPC смогут строить внутри разрешённых зон.",
		"Клик по клетке выбирает её и показывает данные справа.",
		"F1 — открыть или закрыть справку.",
		"Esc — закрыть справку."
	])


func _spawn_camp_if_needed() -> void:
	if selected_tile == null:
		return
	if not selected_tile.has_camp:
		return
	if camp_node != null and is_instance_valid(camp_node):
		return

	camp_node = ColorRect.new()
	camp_node.name = "CampCenter"
	camp_node.position = Vector2(540, 280)
	camp_node.size = Vector2(70, 50)
	camp_node.color = Color.html("#8a5a24")
	camp_node.tooltip_text = "Лагерь"
	camp_node.mouse_filter = Control.MOUSE_FILTER_STOP
	objects_layer.add_child(camp_node)


func _spawn_campfire_if_needed() -> void:
	if selected_tile == null:
		return
	if not selected_tile.has_camp:
		return
	if not GameState.has_campfire_on_selected_tile():
		return
	if campfire_node != null and is_instance_valid(campfire_node):
		return

	campfire_node = ColorRect.new()
	campfire_node.name = "Campfire"
	campfire_node.position = Vector2(620, 300)
	campfire_node.size = Vector2(28, 28)
	campfire_node.color = Color.html("#ff7a1a")
	campfire_node.tooltip_text = "Костёр"
	campfire_node.mouse_filter = Control.MOUSE_FILTER_STOP
	objects_layer.add_child(campfire_node)


func _get_inventory_text(inventory: Dictionary) -> String:
	if inventory.is_empty():
		return "пусто"

	var parts: Array = []
	for item_name in inventory.keys():
		parts.append("%s: %s" % [str(item_name), str(inventory[item_name])])

	return ", ".join(parts)


func _get_skills_text() -> String:
	var player_data = GameState.player_data
	player_data.ensure_skills_initialized()

	var lines: Array = ["Навыки:"]
	for skill_name in ["survival", "construction", "cooking"]:
		var level: int = player_data.get_skill_level(skill_name)
		var xp: int = player_data.get_skill_xp(skill_name)
		var required_xp: int = player_data.get_xp_required_for_next_level(level)
		lines.append("%s: ур. %d, xp %d/%d" % [skill_name, level, xp, required_xp])

	return "\n".join(lines)


func _get_action_costs_text() -> String:
	return "Расход энергии: сбор %d, лагерь %d, костёр %d, готовка %d" % [
		GameState.get_gather_energy_cost(),
		GameState.BUILD_CAMP_ENERGY_COST,
		GameState.BUILD_CAMPFIRE_ENERGY_COST,
		GameState.COOK_BERRIES_ENERGY_COST
	]


func _spawn_objects(objects_layer: Control, terrain_type: String) -> void:
	selected_tile.ensure_local_resources_generated()
	_spawn_saved_resources(objects_layer)

	match terrain_type:
		GameState.TERRAIN_PLAINS:
			_spawn_decorative_objects(objects_layer, [
				[Vector2(350, 390), Vector2(42, 24), Color.html("#eee4a0")],
				[Vector2(760, 470), Vector2(44, 24), Color.html("#eee4a0")]
			])
		GameState.TERRAIN_WATER:
			_spawn_decorative_objects(objects_layer, [
				[Vector2(0, 0), Vector2(110, 640), Color.html("#d6c579")],
				[Vector2(110, 0), Vector2(20, 640), Color.html("#c9b86e")]
			])


func _spawn_saved_resources(objects_layer: Control) -> void:
	for resource_data in selected_tile.local_resources:
		if int(resource_data.get("amount", 0)) <= 0:
			continue

		var resource_id := str(resource_data.get("id", ""))
		var resource_type := str(resource_data.get("type", ""))
		var resource_position := Vector2(
			float(resource_data.get("x", 0.0)),
			float(resource_data.get("y", 0.0))
		)
		var amount := int(resource_data.get("amount", 1))
		_spawn_resource_object(objects_layer, resource_id, resource_type, resource_position, amount)


func _spawn_resource_object(objects_layer: Control, resource_id: String, resource_type: String, resource_position: Vector2, amount: int) -> void:
	var resource_node = ResourceNodeScript.new()
	resource_node.setup(resource_id, resource_type, amount, resource_position)
	resource_node.resource_clicked.connect(_on_resource_clicked)
	objects_layer.add_child(resource_node)


func _spawn_decorative_objects(objects_layer: Control, objects_data: Array) -> void:
	for object_data in objects_data:
		_add_object(objects_layer, object_data[0], object_data[1], object_data[2])


func _add_object(objects_layer: Control, object_position: Vector2, object_size: Vector2, object_color: Color) -> void:
	var object := ColorRect.new()
	object.position = object_position
	object.size = object_size
	object.color = object_color
	object.mouse_filter = Control.MOUSE_FILTER_IGNORE
	objects_layer.add_child(object)


func _on_resource_clicked(resource_node) -> void:
	if zoning_mode_enabled:
		return

	var item_name := _get_inventory_item_for_resource(resource_node.resource_type)

	if item_name == "":
		return

	var energy_cost: int = GameState.get_gather_energy_cost()
	if not GameState.spend_energy(energy_cost):
		print("Недостаточно энергии для сбора ресурса.")
		GameState.add_journal_entry("personal", "Недостаточно энергии", "Нужно энергии: %d" % energy_cost)
		_update_player_panel()
		return

	var inventory: Dictionary = GameState.player_data.inventory
	inventory[item_name] = int(inventory.get(item_name, 0)) + 1
	_reduce_tile_resource_amount(resource_node.resource_id)
	resource_node.collect_one()
	GameState.advance_time()
	GameState.add_journal_entry("resource", "Ресурс собран", item_name)
	GameState.add_skill_xp("survival", 1)
	if item_name == "wood":
		GameState.complete_tutorial_goal("collect_wood")
	elif item_name == "stone":
		GameState.complete_tutorial_goal("collect_stone")

	var danger_result: Dictionary = GameState.roll_gather_danger_event()
	if bool(danger_result.get("happened", false)):
		print(str(danger_result.get("description", "")))
	_update_player_panel()


func _on_build_camp_pressed() -> void:
	if GameState.build_camp_on_selected_tile():
		_spawn_camp_if_needed()
		_update_player_panel()
		print("Лагерь построен.")
	else:
		print("Не хватает ресурсов или лагерь уже есть.")
		_update_player_panel()


func _on_build_campfire_pressed() -> void:
	if GameState.build_campfire_on_selected_tile():
		_spawn_campfire_if_needed()
		_update_player_panel()
		print("Костёр построен.")
	else:
		print("Не хватает ресурсов для костра или костёр уже есть.")
		_update_player_panel()


func _on_prepare_campfire_resources_pressed() -> void:
	if GameState.prepare_campfire_resources_on_selected_tile():
		print("Ресурсы подготовлены для костра.")
	else:
		print("Нет ресурсов для подготовки костра.")

	_update_player_panel()


func _on_rest_at_camp_pressed() -> void:
	if GameState.rest_at_camp():
		_update_player_panel()
		print("Вы отдохнули в лагере.")
	else:
		print("Отдых невозможен: лагеря нет.")
		_update_player_panel()


func _on_quick_rest_pressed() -> void:
	if GameState.quick_rest():
		print("Игрок передохнул.")
	else:
		print("Отдых не нужен.")

	_update_player_panel()


func _on_deposit_item_pressed(item_name: String) -> void:
	if GameState.deposit_to_camp(item_name, 1):
		print("Сложено в лагерь: %s" % item_name)
	else:
		print("Не удалось сложить в лагерь: %s" % item_name)

	_update_player_panel()


func _on_withdraw_item_pressed(item_name: String) -> void:
	if GameState.withdraw_from_camp(item_name, 1):
		print("Взято из лагеря: %s" % item_name)
	else:
		print("Не удалось взять из лагеря: %s" % item_name)

	_update_player_panel()


func _on_cook_berries_pressed() -> void:
	if GameState.cook_berries_at_campfire():
		print("Ягоды приготовлены.")
	else:
		print("Нельзя приготовить ягоды.")

	_update_player_panel()


func _reduce_tile_resource_amount(resource_id: String) -> void:
	for resource_data in selected_tile.local_resources:
		if str(resource_data.get("id", "")) == resource_id:
			resource_data["amount"] = max(0, int(resource_data.get("amount", 0)) - 1)
			return


func _on_eat_berries_pressed() -> void:
	if GameState.eat_berries():
		_update_player_panel()
	else:
		print("Нет ягод в инвентаре.")
		_update_player_panel()


func _on_eat_cooked_berries_pressed() -> void:
	if GameState.eat_cooked_berries():
		print("Игрок съел приготовленные ягоды.")
	else:
		print("Нет приготовленных ягод.")

	_update_player_panel()


func _get_inventory_item_for_resource(resource_type: String) -> String:
	match resource_type:
		ResourceNodeScript.TYPE_TREE:
			return "wood"
		ResourceNodeScript.TYPE_BERRY_BUSH:
			return "berries"
		ResourceNodeScript.TYPE_STONE:
			return "stone"
		_:
			return ""


func _on_back_button_pressed() -> void:
	GameState.advance_time()
	GameState.add_journal_entry("travel", "Игрок вернулся на глобальную карту")
	get_tree().change_scene_to_file("res://scenes/GlobalMapScene.tscn")
