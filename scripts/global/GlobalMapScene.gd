extends Control

const TileButtonScript := preload("res://scripts/global/TileButton.gd")
const MAP_ZOOM_MIN := 0.5
const MAP_ZOOM_DEFAULT := 1.0
const MAP_ZOOM_ABSOLUTE_MAX := 16.0
const MAP_ZOOM_TILE_SCREEN_FRACTION := 0.75
const MAP_ZOOM_STEP := 1.12
const MAP_PAN_SPEED := 420.0
const MAP_FAST_PAN_SPEED := 980.0

var map_view: PanelContainer
var map_clip: Control
var map_root: Control
var map_grid: GridContainer
var selected_tile_label: Label
var climate_label: Label
var relief_label: Label
var vegetation_label: Label
var water_feature_label: Label
var settlement_label: Label
var control_label: Label
var zoning_label: Label
var journal_label: Label
var tutorial_goals_label: Label
var version_label: Label
var zoom_label: Label
var hint_label: Label
var help_overlay: ColorRect
var help_panel: PanelContainer
var enter_button: Button
var camp_action_button: Button
var center_map_button: Button
var tile_buttons: Array = []
var map_zoom: float = MAP_ZOOM_DEFAULT
var camera_offset: Vector2 = Vector2.ZERO
var is_panning_map: bool = false
var last_pan_mouse_position: Vector2 = Vector2.ZERO


func _ready() -> void:
	GameState.initialize_map()
	_build_ui()
	refresh_map()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		call_deferred("_set_camera_offset", camera_offset)


func _build_ui() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	add_child(margin)

	var main_row := HBoxContainer.new()
	main_row.add_theme_constant_override("separation", 20)
	margin.add_child(main_row)

	map_view = PanelContainer.new()
	map_view.custom_minimum_size = Vector2(640, 520)
	map_view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	map_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_row.add_child(map_view)

	map_clip = Control.new()
	map_clip.clip_contents = true
	map_clip.mouse_filter = Control.MOUSE_FILTER_STOP
	map_clip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	map_clip.size_flags_vertical = Control.SIZE_EXPAND_FILL
	map_clip.gui_input.connect(_on_map_view_gui_input)
	map_view.add_child(map_clip)

	map_root = Control.new()
	map_root.mouse_filter = Control.MOUSE_FILTER_PASS
	map_clip.add_child(map_root)

	map_grid = GridContainer.new()
	map_grid.columns = GameState.map_width
	map_grid.add_theme_constant_override("h_separation", 0)
	map_grid.add_theme_constant_override("v_separation", 0)
	map_root.add_child(map_grid)

	var side_panel := PanelContainer.new()
	side_panel.custom_minimum_size = Vector2(280, 0)
	main_row.add_child(side_panel)

	var side_margin := MarginContainer.new()
	side_margin.add_theme_constant_override("margin_left", 14)
	side_margin.add_theme_constant_override("margin_top", 14)
	side_margin.add_theme_constant_override("margin_right", 14)
	side_margin.add_theme_constant_override("margin_bottom", 14)
	side_panel.add_child(side_margin)

	var info_column := VBoxContainer.new()
	info_column.add_theme_constant_override("separation", 12)
	side_margin.add_child(info_column)

	var title_label := Label.new()
	title_label.text = "Глобальная карта"
	info_column.add_child(title_label)

	version_label = Label.new()
	version_label.text = GameState.get_version_text()
	info_column.add_child(version_label)

	zoom_label = Label.new()
	info_column.add_child(zoom_label)

	center_map_button = Button.new()
	center_map_button.text = "К выбранному"
	center_map_button.pressed.connect(center_global_map_on_selected_tile_or_player)
	info_column.add_child(center_map_button)

	var hint_panel := PanelContainer.new()
	info_column.add_child(hint_panel)

	var hint_margin := MarginContainer.new()
	hint_margin.add_theme_constant_override("margin_left", 8)
	hint_margin.add_theme_constant_override("margin_top", 5)
	hint_margin.add_theme_constant_override("margin_right", 8)
	hint_margin.add_theme_constant_override("margin_bottom", 5)
	hint_panel.add_child(hint_margin)

	hint_label = Label.new()
	hint_label.custom_minimum_size = Vector2(190, 0)
	hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint_margin.add_child(hint_label)

	selected_tile_label = Label.new()
	info_column.add_child(selected_tile_label)

	climate_label = Label.new()
	info_column.add_child(climate_label)

	relief_label = Label.new()
	info_column.add_child(relief_label)

	vegetation_label = Label.new()
	info_column.add_child(vegetation_label)

	water_feature_label = Label.new()
	info_column.add_child(water_feature_label)

	settlement_label = Label.new()
	info_column.add_child(settlement_label)

	control_label = Label.new()
	info_column.add_child(control_label)

	zoning_label = Label.new()
	info_column.add_child(zoning_label)

	enter_button = Button.new()
	enter_button.text = "Войти в тайл"
	enter_button.disabled = true
	enter_button.pressed.connect(_on_enter_tile_pressed)
	info_column.add_child(enter_button)

	camp_action_button = Button.new()
	camp_action_button.text = "Построить лагерь"
	camp_action_button.disabled = true
	camp_action_button.tooltip_text = "Нужно: wood 5, stone 2"
	camp_action_button.pressed.connect(_on_camp_action_pressed)
	info_column.add_child(camp_action_button)

	var save_button := Button.new()
	save_button.text = "Сохранить"
	save_button.pressed.connect(_on_save_pressed)
	info_column.add_child(save_button)

	var load_button := Button.new()
	load_button.text = "Загрузить"
	load_button.pressed.connect(_on_load_pressed)
	info_column.add_child(load_button)

	var new_game_button := Button.new()
	new_game_button.text = "Новая игра"
	new_game_button.pressed.connect(_on_new_game_pressed)
	info_column.add_child(new_game_button)

	var help_button := Button.new()
	help_button.text = "Справка"
	help_button.pressed.connect(_toggle_help_panel)
	info_column.add_child(help_button)

	var journal_title := Label.new()
	journal_title.text = "Журнал:"
	info_column.add_child(journal_title)

	journal_label = Label.new()
	journal_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_column.add_child(journal_label)

	tutorial_goals_label = Label.new()
	tutorial_goals_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_column.add_child(tutorial_goals_label)

	_build_help_panel()


func refresh_map() -> void:
	for tile_button in tile_buttons:
		tile_button.queue_free()

	tile_buttons.clear()
	map_grid.columns = GameState.map_width

	for y in range(GameState.map_height):
		for x in range(GameState.map_width):
			var tile_data = GameState.get_tile(x, y)
			var tile_button = TileButtonScript.new()
			tile_button.setup(tile_data)
			tile_button.set_map_zoom(map_zoom)
			tile_button.tile_selected.connect(_on_tile_selected)
			tile_button.map_zoom_requested.connect(_on_map_zoom_requested)
			tile_button.map_pan_started.connect(_on_map_pan_started)
			tile_button.map_pan_moved.connect(_on_map_pan_moved)
			tile_button.map_pan_finished.connect(_on_map_pan_finished)
			map_grid.add_child(tile_button)
			tile_buttons.append(tile_button)

	_update_map_content_rects()
	_apply_map_zoom()
	call_deferred("_set_camera_offset", camera_offset)
	_refresh_tile_buttons()
	_update_info()
	_update_journal_ui()


func _build_help_panel() -> void:
	var panel_size := Vector2(460, 360)

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
	title_label.text = "Справка: Глобальная карта"
	help_column.add_child(title_label)

	var scroll_container := ScrollContainer.new()
	scroll_container.custom_minimum_size = Vector2(0, 260)
	scroll_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	help_column.add_child(scroll_container)

	var help_label := Label.new()
	help_label.custom_minimum_size = Vector2(400, 0)
	help_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	help_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	help_label.text = _get_help_text()
	scroll_container.add_child(help_label)

	var close_button := Button.new()
	close_button.text = "Закрыть"
	close_button.pressed.connect(_hide_help_panel)
	help_column.add_child(close_button)


func _on_tile_selected(tile_data) -> void:
	GameState.select_tile(tile_data)
	_refresh_tile_buttons()
	_update_info()


func _refresh_tile_buttons() -> void:
	for tile_button in tile_buttons:
		tile_button.set_selected(tile_button.tile_data.selected)


func zoom_global_map_in() -> void:
	_zoom_map_to_keyboard_target(map_zoom * MAP_ZOOM_STEP)


func zoom_global_map_out() -> void:
	_zoom_map_to_keyboard_target(map_zoom / MAP_ZOOM_STEP)


func reset_global_map_zoom() -> void:
	_zoom_map_to_keyboard_target(MAP_ZOOM_DEFAULT)


func zoom_global_map_in_at_position(view_position: Vector2) -> void:
	_zoom_map_to_view_position(map_zoom * MAP_ZOOM_STEP, view_position)


func zoom_global_map_out_at_position(view_position: Vector2) -> void:
	_zoom_map_to_view_position(map_zoom / MAP_ZOOM_STEP, view_position)


func center_global_map_on_selected_tile_or_player() -> void:
	var world_position := _get_focus_world_position()
	if world_position.x < 0.0 or world_position.y < 0.0:
		world_position = _get_map_base_content_size() * 0.5

	_center_map_on_world_position(world_position)


func _on_map_zoom_requested(direction: int) -> void:
	var view_position := _get_mouse_position_in_map_view()
	if direction > 0:
		zoom_global_map_in_at_position(view_position)
	elif direction < 0:
		zoom_global_map_out_at_position(view_position)


func _set_map_zoom(new_zoom: float) -> void:
	map_zoom = clamp(new_zoom, MAP_ZOOM_MIN, _get_map_zoom_max())
	_apply_map_zoom()


func _apply_map_zoom() -> void:
	if map_root != null:
		map_root.scale = Vector2(map_zoom, map_zoom)

	for tile_button in tile_buttons:
		tile_button.set_map_zoom(map_zoom)

	if zoom_label != null:
		zoom_label.text = "Зум карты: %d%%" % int(round(map_zoom * 100.0))

	if map_grid != null:
		map_grid.queue_sort()

	_set_camera_offset(camera_offset)


func _zoom_map_to_keyboard_target(new_zoom: float) -> void:
	if GameState.selected_tile != null:
		var selected_world_position := _get_tile_world_position(GameState.selected_tile.x, GameState.selected_tile.y)
		_zoom_map_to_world_position(new_zoom, selected_world_position, _get_map_view_size() * 0.5)
	else:
		_zoom_map_to_view_position(new_zoom, _get_map_view_size() * 0.5)


func _zoom_map_to_view_position(new_zoom: float, view_position: Vector2) -> void:
	var world_position := _view_position_to_world(view_position)
	var old_zoom := map_zoom
	_set_map_zoom(new_zoom)
	if is_equal_approx(old_zoom, map_zoom):
		return

	_set_camera_offset(view_position - world_position * map_zoom)


func _zoom_map_to_world_position(new_zoom: float, world_position: Vector2, view_position: Vector2) -> void:
	_set_map_zoom(new_zoom)
	_set_camera_offset(view_position - world_position * map_zoom)


func get_camera_offset() -> Vector2:
	return camera_offset


func _set_camera_offset(new_offset: Vector2) -> void:
	camera_offset = _clamp_camera_offset(new_offset)
	if map_root != null:
		map_root.position = camera_offset


func _clamp_camera_offset(offset: Vector2) -> Vector2:
	var content_size := _get_map_content_size()
	var view_size := _get_map_view_size()
	if view_size == Vector2.ZERO:
		return offset

	var camera_padding := _get_camera_padding()
	var min_offset := view_size - content_size - camera_padding
	var max_offset := camera_padding

	var result := Vector2(
		clamp(offset.x, min_offset.x, max_offset.x),
		clamp(offset.y, min_offset.y, max_offset.y)
	)

	return result


func _get_camera_padding() -> Vector2:
	return _get_map_view_size() * 0.5


func _get_map_view_size() -> Vector2:
	if map_clip == null:
		return Vector2.ZERO

	return map_clip.size


func _get_map_content_size() -> Vector2:
	return _get_map_base_content_size() * map_zoom


func _get_map_base_content_size() -> Vector2:
	if GameState.map_width <= 0 or GameState.map_height <= 0:
		return Vector2.ZERO

	return Vector2(
		float(GameState.map_width) * TileButtonScript.BASE_TILE_SIZE,
		float(GameState.map_height) * TileButtonScript.BASE_TILE_SIZE
	)


func _get_map_zoom_max() -> float:
	var view_size := _get_map_view_size()
	if view_size.x <= 0.0 or view_size.y <= 0.0:
		return 3.0

	var calculated_zoom: float = min(view_size.x, view_size.y) / TileButtonScript.BASE_TILE_SIZE * MAP_ZOOM_TILE_SCREEN_FRACTION
	return max(MAP_ZOOM_DEFAULT, min(MAP_ZOOM_ABSOLUTE_MAX, calculated_zoom))


func _update_map_content_rects() -> void:
	var base_size := _get_map_base_content_size()
	if map_root != null:
		map_root.custom_minimum_size = base_size
		map_root.size = base_size
	if map_grid != null:
		map_grid.custom_minimum_size = base_size
		map_grid.size = base_size


func _get_mouse_position_in_map_view() -> Vector2:
	if map_clip == null:
		return _get_map_view_size() * 0.5

	var mouse_position := map_clip.get_local_mouse_position()
	var view_size := _get_map_view_size()
	return Vector2(
		clamp(mouse_position.x, 0.0, view_size.x),
		clamp(mouse_position.y, 0.0, view_size.y)
	)


func _view_position_to_world(view_position: Vector2) -> Vector2:
	if map_zoom <= 0.0:
		return Vector2.ZERO

	return (view_position - camera_offset) / map_zoom


func _world_position_to_view(world_position: Vector2) -> Vector2:
	return world_position * map_zoom + camera_offset


func _get_focus_world_position() -> Vector2:
	var focus_tile = GameState.selected_tile
	if focus_tile == null:
		GameState.initialize_player_data()
		focus_tile = GameState.get_tile(GameState.player_data.global_x, GameState.player_data.global_y)

	if focus_tile == null:
		return Vector2(-1.0, -1.0)

	return _get_tile_world_position(focus_tile.x, focus_tile.y)


func _get_tile_world_position(tile_x: int, tile_y: int) -> Vector2:
	return Vector2(
		(float(tile_x) + 0.5) * TileButtonScript.BASE_TILE_SIZE,
		(float(tile_y) + 0.5) * TileButtonScript.BASE_TILE_SIZE
	)


func _center_map_on_world_position(world_position: Vector2) -> void:
	_set_camera_offset(_get_map_view_size() * 0.5 - world_position * map_zoom)


func _pan_map_by(delta: Vector2) -> void:
	_set_camera_offset(camera_offset + delta)


func _on_map_pan_started(global_position: Vector2) -> void:
	is_panning_map = true
	last_pan_mouse_position = global_position


func _on_map_pan_moved(global_position: Vector2) -> void:
	if not is_panning_map:
		return

	_pan_map_by(global_position - last_pan_mouse_position)
	last_pan_mouse_position = global_position


func _on_map_pan_finished() -> void:
	is_panning_map = false


func _on_map_view_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			zoom_global_map_in_at_position(event.position)
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			zoom_global_map_out_at_position(event.position)
			get_viewport().set_input_as_handled()
		elif (event.button_index == MOUSE_BUTTON_MIDDLE or event.button_index == MOUSE_BUTTON_RIGHT) and event.pressed:
			_on_map_pan_started(event.global_position)
			get_viewport().set_input_as_handled()
		elif (event.button_index == MOUSE_BUTTON_MIDDLE or event.button_index == MOUSE_BUTTON_RIGHT) and not event.pressed:
			_on_map_pan_finished()
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and is_panning_map:
		_on_map_pan_moved(event.global_position)
		get_viewport().set_input_as_handled()


func _update_info() -> void:
	_update_tutorial_goals_ui()

	if GameState.selected_tile == null:
		hint_label.text = "Выберите тайл на карте."
		selected_tile_label.text = "Тайл не выбран"
		climate_label.text = "Климат: -"
		relief_label.text = "Рельеф: -"
		vegetation_label.text = "Растительность: -"
		water_feature_label.text = "Вода: -"
		zoning_label.text = "Зоны: 0"
		settlement_label.text = "Населённый пункт: -"
		control_label.text = "Контроль: -"
		enter_button.disabled = true
		camp_action_button.text = "Построить лагерь"
		camp_action_button.disabled = true
		return

	var tile_data = GameState.selected_tile
	GameState.normalize_public_tile_fields(tile_data)
	hint_label.text = "Выбран тайл. Можно войти в локальную сцену."
	selected_tile_label.text = "Координаты: %d, %d" % [tile_data.x, tile_data.y]
	climate_label.text = "Климат: %s" % GameState.get_climate_title(tile_data.climate_type)
	relief_label.text = "Рельеф: %s" % GameState.get_relief_title(tile_data.relief_type)
	water_feature_label.text = "Вода: %s" % GameState.get_water_feature_title(tile_data.water_feature)
	zoning_label.text = "Зоны: %d" % tile_data.get_zoned_cells_count()
	vegetation_label.text = "Растительность: %s" % GameState.get_vegetation_display_text(tile_data)
	settlement_label.text = "Населённый пункт: %s" % GameState.get_settlement_title(tile_data.settlement_type)
	control_label.text = "Контроль: %s" % GameState.get_control_owner_title(tile_data.control_owner)
	enter_button.disabled = false

	if tile_data.has_camp:
		camp_action_button.text = "Войти в тайл с поселением"
		camp_action_button.disabled = false
	else:
		camp_action_button.text = "Построить лагерь"
		camp_action_button.disabled = not GameState.can_build_camp_on_selected_tile()


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
	if event is InputEventMouseButton:
		if (event.button_index == MOUSE_BUTTON_MIDDLE or event.button_index == MOUSE_BUTTON_RIGHT) and not event.pressed and is_panning_map:
			_on_map_pan_finished()
			get_viewport().set_input_as_handled()
			return
	if event is InputEventMouseMotion and is_panning_map:
		_on_map_pan_moved(event.global_position)
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F1:
			_toggle_help_panel()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_ESCAPE and help_panel != null and help_panel.visible:
			_hide_help_panel()
			get_viewport().set_input_as_handled()
		elif help_panel != null and help_panel.visible:
			return
		elif _is_zoom_in_key(event):
			zoom_global_map_in()
			get_viewport().set_input_as_handled()
		elif _is_zoom_out_key(event):
			zoom_global_map_out()
			get_viewport().set_input_as_handled()
		elif _is_zoom_reset_key(event):
			reset_global_map_zoom()
			get_viewport().set_input_as_handled()
		elif _is_center_map_key(event):
			center_global_map_on_selected_tile_or_player()
			get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if help_panel != null and help_panel.visible:
		return

	var direction := Vector2.ZERO

	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		direction.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		direction.x += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		direction.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		direction.y += 1.0

	if direction == Vector2.ZERO:
		return

	var pan_speed := MAP_PAN_SPEED
	if Input.is_key_pressed(KEY_SHIFT):
		pan_speed = MAP_FAST_PAN_SPEED

	_pan_map_by(-direction.normalized() * pan_speed / max(map_zoom, 0.1) * delta)


func _is_zoom_in_key(event: InputEventKey) -> bool:
	return event.keycode == KEY_EQUAL or event.unicode == 43


func _is_zoom_out_key(event: InputEventKey) -> bool:
	return event.keycode == KEY_MINUS or event.unicode == 45


func _is_zoom_reset_key(event: InputEventKey) -> bool:
	return event.keycode == KEY_0 or event.unicode == 48


func _is_center_map_key(event: InputEventKey) -> bool:
	return event.keycode == KEY_C


func _get_help_text() -> String:
	return "\n".join([
		"Глобальная карта",
		"",
		"Выберите тайл на карте, чтобы увидеть его данные.",
		"Кнопка 'Войти в тайл' переносит игрока в локальную сцену выбранной территории.",
		"Цвета тайлов сейчас технические и используются для раннего прототипа.",
		"На тайле отображаются тип местности, климат, рельеф, растительность, вода, посещение и лагерь.",
		"Сохранить — записывает состояние мира.",
		"Загрузить — восстанавливает сохранённый мир.",
		"Новая игра — создаёт новый мир и сбрасывает прогресс.",
		"Первые цели показывают базовый порядок действий для новой игры.",
		"На глобальной карте показаны ближайшие первые цели.",
		"Каждый глобальный тайл может иметь свою локальную клеточную карту.",
		"На глобальной карте выбранный тайл показывает количество размеченных клеток.",
		"Каждый глобальный тайл теперь имеет климат, рельеф, растительность и водные особенности.",
		"Эти параметры пока не влияют на экономику, но будут использоваться для ресурсов, поселений, дорог и развития земли.",
		"Локальная карта по-прежнему создаётся при входе в тайл.",
		"Колесо мыши — приблизить или отдалить карту к курсору.",
		"+ / - — изменить зум карты к выбранному тайлу.",
		"0 — сбросить зум карты.",
		"Средняя кнопка мыши + движение — двигать карту.",
		"Правая кнопка мыши + движение — тоже двигать карту.",
		"WASD / стрелки — двигать камеру.",
		"Shift + движение — быстрое движение камеры.",
		"C — камера к игроку или выбранному тайлу.",
		"F1 — открыть или закрыть справку."
		, "ЛКМ по тайлу - выбрать тайл."
	])


func _on_enter_tile_pressed() -> void:
	if GameState.selected_tile == null:
		return

	GameState.selected_tile.visited = true
	GameState.move_player_to_tile(GameState.selected_tile)
	GameState.advance_time()
	GameState.add_journal_entry(
		"travel",
		"Игрок вошёл в тайл",
		"%d, %d" % [GameState.selected_tile.x, GameState.selected_tile.y]
	)
	_update_journal_ui()
	get_tree().change_scene_to_file("res://scenes/LocalTileScene.tscn")


func _on_camp_action_pressed() -> void:
	if GameState.selected_tile == null:
		return

	if GameState.selected_tile.has_camp:
		_on_enter_tile_pressed()
		return

	if GameState.build_camp_on_selected_tile():
		print("Лагерь построен.")
	else:
		print("Недостаточно ресурсов для лагеря. Нужно: wood 5, stone 2.")

	_refresh_tile_buttons()
	_update_info()
	_update_journal_ui()


func _on_save_pressed() -> void:
	SaveSystem.save_game()
	_update_journal_ui()


func _on_load_pressed() -> void:
	if not SaveSystem.has_save():
		print("Сохранение не найдено.")
		return

	if SaveSystem.load_game():
		refresh_map()
		_update_journal_ui()


func _on_new_game_pressed() -> void:
	GameState.start_new_game()
	refresh_map()
	_update_journal_ui()
	print("Новая игра создана.")


func _update_journal_ui() -> void:
	journal_label.text = _get_journal_text()


func _update_tutorial_goals_ui() -> void:
	if tutorial_goals_label != null:
		tutorial_goals_label.text = GameState.get_tutorial_goals_compact_text(4)


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
