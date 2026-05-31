extends SceneTree

const GLOBAL_TILE_SIZE := 36.0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game_state = root.get_node_or_null("/root/GameState")
	if game_state == null:
		_fail("GameState autoload is missing.")
		return

	game_state.start_new_game()

	var packed_scene = load("res://scenes/GlobalMapScene.tscn")
	if packed_scene == null:
		_fail("Cannot load GlobalMapScene.")
		return

	var scene = packed_scene.instantiate()
	if scene == null:
		_fail("Cannot instantiate GlobalMapScene.")
		return

	root.add_child(scene)
	await process_frame
	await process_frame

	var map_view = scene.get("map_view")
	var map_clip = scene.get("map_clip")
	var map_root = scene.get("map_root")
	var tile_buttons: Array = scene.get("tile_buttons")
	var version_label = scene.get("version_label")

	if map_view == null or map_clip == null or map_root == null:
		_fail("Global map view nodes are missing.")
		return
	if map_view is ScrollContainer or map_clip is ScrollContainer:
		_fail("Global map still uses ScrollContainer for camera control.")
		return
	if tile_buttons.is_empty():
		_fail("GlobalMapScene has no tile buttons.")
		return
	if version_label == null:
		_fail("GlobalMapScene has no version_label.")
		return

	var original_zoom: float = float(scene.get("map_zoom"))
	if abs(original_zoom - 1.0) > 0.001:
		_fail("Default map zoom is not 100%.")
		return

	var original_tile_size: float = float(tile_buttons[0].custom_minimum_size.x)
	if abs(original_tile_size - GLOBAL_TILE_SIZE) > 0.001:
		_fail("Global tile base size is invalid.")
		return

	var view_position: Vector2 = map_clip.size * 0.5
	scene.call("_set_camera_offset", scene.call("get_camera_offset"))
	await process_frame
	var world_before_zoom: Vector2 = scene.call("_view_position_to_world", view_position)
	scene.call("zoom_global_map_in_at_position", view_position)
	await process_frame
	var world_after_zoom: Vector2 = scene.call("_view_position_to_world", view_position)

	if float(scene.get("map_zoom")) <= original_zoom:
		_fail("Zoom to cursor did not increase global map zoom.")
		return
	if world_before_zoom.distance_to(world_after_zoom) > 0.1:
		_fail("Zoom to cursor did not keep the same world position under the cursor.")
		return
	if abs(float(tile_buttons[0].custom_minimum_size.x) - original_tile_size) > 0.001:
		_fail("Tile minimum size changed instead of scaling only map_root.")
		return
	if map_root.scale.x <= 1.0 or map_root.scale.y <= 1.0:
		_fail("map_root scale did not change after zoom.")
		return
	if version_label.scale != Vector2.ONE:
		_fail("Global UI was scaled by map zoom.")
		return

	var offset_before_drag: Vector2 = scene.call("get_camera_offset")
	var middle_press := InputEventMouseButton.new()
	middle_press.button_index = MOUSE_BUTTON_MIDDLE
	middle_press.pressed = true
	middle_press.global_position = Vector2(300.0, 300.0)
	scene.call("_on_map_view_gui_input", middle_press)

	var drag_motion := InputEventMouseMotion.new()
	drag_motion.global_position = Vector2(340.0, 330.0)
	scene.call("_on_map_view_gui_input", drag_motion)
	await process_frame

	if scene.call("get_camera_offset") == offset_before_drag:
		_fail("Middle mouse drag did not pan the map.")
		return

	var middle_release := InputEventMouseButton.new()
	middle_release.button_index = MOUSE_BUTTON_MIDDLE
	middle_release.pressed = false
	middle_release.global_position = Vector2(340.0, 330.0)
	scene.call("_on_map_view_gui_input", middle_release)

	for i in range(80):
		scene.call("zoom_global_map_out")
	await process_frame
	if float(scene.get("map_zoom")) < 0.5:
		_fail("Map zoom went below minimum.")
		return

	for i in range(80):
		scene.call("zoom_global_map_in")
	await process_frame
	var max_zoom: float = float(scene.call("_get_map_zoom_max"))
	if float(scene.get("map_zoom")) > max_zoom + 0.01:
		_fail("Map zoom went above calculated maximum.")
		return
	if max_zoom <= 3.0:
		_fail("Calculated max zoom is too weak for inspecting one tile.")
		return

	scene.call("reset_global_map_zoom")
	await process_frame
	if abs(float(scene.get("map_zoom")) - 1.0) > 0.001:
		_fail("Map zoom reset did not restore default zoom.")
		return

	scene.call("_set_camera_offset", Vector2(-100000.0, -100000.0))
	await process_frame
	var clamped_negative_offset: Vector2 = scene.call("get_camera_offset")
	if clamped_negative_offset.x <= -100000.0 or clamped_negative_offset.y <= -100000.0:
		_fail("Map camera went beyond negative bounds.")
		return

	scene.call("_set_camera_offset", Vector2(100000.0, 100000.0))
	await process_frame
	var clamped_positive_offset: Vector2 = scene.call("get_camera_offset")
	if clamped_positive_offset.x >= 100000.0 or clamped_positive_offset.y >= 100000.0:
		_fail("Map camera went beyond positive bounds.")
		return

	var target_x := 12
	var target_y := 8
	var target_index: int = target_y * game_state.map_width + target_x
	var target_button = tile_buttons[target_index]
	var click_event := InputEventMouseButton.new()
	click_event.button_index = MOUSE_BUTTON_LEFT
	click_event.pressed = true
	target_button.call("_gui_input", click_event)

	if game_state.selected_tile == null:
		_fail("Click after zoom did not select a tile.")
		return
	if game_state.selected_tile.x != target_x or game_state.selected_tile.y != target_y:
		_fail("Click after zoom selected the wrong tile.")
		return

	scene.call("reset_global_map_zoom")
	await process_frame
	_select_tile(game_state, 0, 0)
	scene.call("center_global_map_on_selected_tile_or_player")
	await process_frame
	if not _is_tile_centered(scene, 0, 0, 2.0):
		_fail("Top-left global tile cannot be centered.")
		return

	_select_tile(game_state, game_state.map_width - 1, game_state.map_height - 1)
	scene.call("center_global_map_on_selected_tile_or_player")
	await process_frame
	if not _is_tile_centered(scene, game_state.map_width - 1, game_state.map_height - 1, 2.0):
		_fail("Bottom-right global tile cannot be centered.")
		return

	_select_tile(game_state, 0, game_state.map_height - 1)
	scene.call("center_global_map_on_selected_tile_or_player")
	await process_frame
	if not _is_tile_centered(scene, 0, game_state.map_height - 1, 2.0):
		_fail("Bottom-left global tile cannot be centered.")
		return

	var bottom_center_x: int = int(game_state.map_width / 2)
	var bottom_center_y: int = game_state.map_height - 1
	_select_tile(game_state, bottom_center_x, bottom_center_y)
	scene.call("center_global_map_on_selected_tile_or_player")
	await process_frame
	for i in range(18):
		scene.call("zoom_global_map_in")
	await process_frame
	if not _is_tile_centered(scene, bottom_center_x, bottom_center_y, 2.0):
		_fail("Bottom-center global tile moved away from center during keyboard zoom.")
		return

	scene.call("_set_camera_offset", Vector2(-100000.0, -100000.0))
	await process_frame
	var negative_offset_after_padding: Vector2 = scene.call("get_camera_offset")
	var view_size: Vector2 = scene.call("_get_map_view_size")
	var content_size: Vector2 = scene.call("_get_map_content_size")
	var padding := view_size * 0.5
	var min_offset := view_size - content_size - padding
	if negative_offset_after_padding.x < min_offset.x - 0.01 or negative_offset_after_padding.y < min_offset.y - 0.01:
		_fail("Camera padding clamp allowed offset beyond negative virtual field.")
		return

	scene.call("_set_camera_offset", Vector2(100000.0, 100000.0))
	await process_frame
	var positive_offset_after_padding: Vector2 = scene.call("get_camera_offset")
	if positive_offset_after_padding.x > padding.x + 0.01 or positive_offset_after_padding.y > padding.y + 0.01:
		_fail("Camera padding clamp allowed offset beyond positive virtual field.")
		return

	root.remove_child(scene)
	scene.free()

	print("Global map strategic camera 0.003 test passed.")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _select_tile(game_state, x: int, y: int) -> void:
	var tile_data = game_state.get_tile(x, y)
	game_state.select_tile(tile_data)


func _is_tile_centered(scene, tile_x: int, tile_y: int, tolerance: float) -> bool:
	var map_clip = scene.get("map_clip")
	var selected_world_position := Vector2(
		(float(tile_x) + 0.5) * GLOBAL_TILE_SIZE,
		(float(tile_y) + 0.5) * GLOBAL_TILE_SIZE
	)
	var selected_view_position: Vector2 = scene.call("_world_position_to_view", selected_world_position)
	var view_center: Vector2 = map_clip.size * 0.5
	return selected_view_position.distance_to(view_center) <= tolerance
