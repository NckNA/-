extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var global_scene = _instantiate_scene("res://scenes/GlobalMapScene.tscn")
	if global_scene == null:
		return

	root.add_child(global_scene)
	_check_help_controls(global_scene, "GlobalMapScene")
	_check_global_tile_ui_cleanup(global_scene)
	_free_scene(global_scene)

	var game_state = root.get_node_or_null("/root/GameState")
	if game_state != null:
		game_state.start_new_game()
		game_state.select_tile(game_state.get_tile(0, 0))

	var local_scene = _instantiate_scene("res://scenes/LocalTileScene.tscn")
	if local_scene == null:
		return

	root.add_child(local_scene)
	if local_scene.get("hint_label") == null:
		_fail("LocalTileScene: hint_label is missing.")
		return

	_check_help_controls(local_scene, "LocalTileScene")
	_free_scene(local_scene)

	print("UI 0.002 smoke test passed.")
	quit(0)


func _instantiate_scene(scene_path: String):
	var packed_scene = load(scene_path)
	if packed_scene == null:
		_fail("Cannot load scene: %s" % scene_path)
		return null

	var scene = packed_scene.instantiate()
	if scene == null:
		_fail("Cannot instantiate scene: %s" % scene_path)
		return null

	return scene


func _check_help_controls(scene, scene_name: String) -> void:
	var help_panel = scene.get("help_panel")
	var help_overlay = scene.get("help_overlay")

	if help_panel == null:
		_fail("%s: help_panel is missing." % scene_name)
		return
	if help_overlay == null:
		_fail("%s: help_overlay is missing." % scene_name)
		return

	scene.call("_toggle_help_panel")
	if not help_panel.visible:
		_fail("%s: help_panel did not open." % scene_name)
		return
	if not help_overlay.visible:
		_fail("%s: help_overlay did not open." % scene_name)
		return

	scene.call("_hide_help_panel")
	if help_panel.visible:
		_fail("%s: help_panel did not close." % scene_name)
		return
	if help_overlay.visible:
		_fail("%s: help_overlay did not close." % scene_name)
		return


func _check_global_tile_ui_cleanup(scene) -> void:
	var game_state = root.get_node_or_null("/root/GameState")
	if game_state == null:
		_fail("GlobalMapScene: GameState autoload is missing.")
		return

	game_state.select_tile(game_state.get_tile(1, 1))
	scene.call("_update_info")

	if _node_tree_text_contains(scene, "Плодородие"):
		_fail("GlobalMapScene: fertility should not be shown in the global tile UI.")
		return
	if _node_tree_text_contains(scene, "Опасность"):
		_fail("GlobalMapScene: danger should not be shown in the global tile UI.")
		return

	var tile_buttons: Array = scene.get("tile_buttons")
	if not tile_buttons.is_empty():
		var tooltip := str(tile_buttons[0].tooltip_text)
		if tooltip.contains("Плодородие") or tooltip.contains("Опасность"):
			_fail("GlobalMapScene: tile tooltip should not show fertility or danger.")
			return


func _node_tree_text_contains(node: Node, needle: String) -> bool:
	if node is Label:
		if node.text.contains(needle):
			return true
	if node is Button:
		if node.text.contains(needle):
			return true

	for child in node.get_children():
		if _node_tree_text_contains(child, needle):
			return true

	return false


func _free_scene(scene: Node) -> void:
	if scene.get_parent() != null:
		scene.get_parent().remove_child(scene)
	scene.free()


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
