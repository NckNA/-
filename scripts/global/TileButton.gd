extends ColorRect
class_name TileButton

signal tile_selected(tile_data)
signal map_zoom_requested(direction)
signal map_pan_started(global_position)
signal map_pan_moved(global_position)
signal map_pan_finished()

const BASE_TILE_SIZE := 36.0

var tile_data = null
var base_color: Color = Color.WHITE
var is_selected: bool = false
var background_texture: Texture2D = null
var map_zoom: float = 1.0


func setup(new_tile_data) -> void:
	tile_data = new_tile_data
	base_color = GameState.get_terrain_color(tile_data.terrain_type)
	is_selected = tile_data.selected
	_load_background_texture()
	_update_tile_size()
	mouse_filter = Control.MOUSE_FILTER_STOP
	_update_tooltip()
	_refresh_visual()


func _update_tooltip() -> void:
	if tile_data == null:
		tooltip_text = ""
		return

	_apply_public_tooltip()


func _apply_public_tooltip() -> void:
	GameState.normalize_public_tile_fields(tile_data)
	tooltip_text = "\n".join([
		"x: %d, y: %d" % [tile_data.x, tile_data.y],
		"Климат: %s" % GameState.get_climate_title(tile_data.climate_type),
		"Рельеф: %s" % GameState.get_relief_title(tile_data.relief_type),
		"Вода: %s" % GameState.get_water_feature_title(tile_data.water_feature),
		"Растительность: %s" % GameState.get_vegetation_display_text(tile_data),
		"Населённый пункт: %s" % GameState.get_settlement_title(tile_data.settlement_type),
		"Контроль: %s" % GameState.get_control_owner_title(tile_data.control_owner),
		"Зоны: %d" % tile_data.get_zoned_cells_count()
	])


func set_selected(value: bool) -> void:
	is_selected = value
	if tile_data != null:
		tile_data.selected = value

	_update_tooltip()
	_refresh_visual()


func _load_background_texture() -> void:
	background_texture = null
	var loaded_texture = GameState.get_global_tile_texture(tile_data)
	if loaded_texture is Texture2D:
		background_texture = loaded_texture


func set_map_zoom(new_zoom: float) -> void:
	map_zoom = new_zoom
	queue_redraw()


func _update_tile_size() -> void:
	custom_minimum_size = Vector2(BASE_TILE_SIZE, BASE_TILE_SIZE)


func _refresh_visual() -> void:
	var new_color := base_color

	if tile_data != null and tile_data.visited:
		new_color = new_color.lightened(0.12)
	if tile_data != null and tile_data.has_camp:
		new_color = new_color.lerp(Color.html("#b9802c"), 0.45)
	if is_selected:
		new_color = new_color.lightened(0.35)

	color = new_color
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			map_zoom_requested.emit(1)
			accept_event()
			return
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			map_zoom_requested.emit(-1)
			accept_event()
			return
		if (event.button_index == MOUSE_BUTTON_MIDDLE or event.button_index == MOUSE_BUTTON_RIGHT) and event.pressed:
			map_pan_started.emit(event.global_position)
			accept_event()
			return
		if (event.button_index == MOUSE_BUTTON_MIDDLE or event.button_index == MOUSE_BUTTON_RIGHT) and not event.pressed:
			map_pan_finished.emit()
			accept_event()
			return
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			tile_selected.emit(tile_data)
	elif event is InputEventMouseMotion:
		if (event.button_mask & MOUSE_BUTTON_MASK_MIDDLE) != 0 or (event.button_mask & MOUSE_BUTTON_MASK_RIGHT) != 0:
			map_pan_moved.emit(event.global_position)
			accept_event()


func _draw() -> void:
	if background_texture != null:
		draw_texture_rect_region(
			background_texture,
			Rect2(Vector2.ZERO, size),
			_get_background_texture_region(),
			color
		)

	var border_color := Color(0.0, 0.0, 0.0, 0.35)
	var border_width := 1.0

	if is_selected:
		border_color = Color.WHITE
		border_width = 3.0

	draw_rect(Rect2(Vector2.ZERO, size), border_color, false, border_width)

	if tile_data != null and tile_data.visited:
		draw_circle(Vector2(size.x - 8.0, 8.0), 4.0, Color(1.0, 1.0, 1.0, 0.9))

	if tile_data != null and tile_data.has_camp:
		draw_rect(Rect2(Vector2(6.0, size.y - 12.0), Vector2(10.0, 8.0)), Color.html("#5a3415"), true)


func _get_background_texture_region() -> Rect2:
	if background_texture == null or tile_data == null:
		return Rect2(Vector2.ZERO, size)

	var texture_size := background_texture.get_size()
	var source_size := size * map_zoom
	var region_size := Vector2(min(source_size.x, texture_size.x), min(source_size.y, texture_size.y))
	var max_offset := texture_size - region_size
	var offset := Vector2.ZERO

	if max_offset.x > 0.0:
		offset.x = fposmod(float(tile_data.x * 37), max_offset.x)
	if max_offset.y > 0.0:
		offset.y = fposmod(float(tile_data.y * 53), max_offset.y)

	return Rect2(offset, region_size)
