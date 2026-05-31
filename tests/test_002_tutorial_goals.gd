extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game_state = root.get_node_or_null("/root/GameState")
	if game_state == null:
		_fail("GameState autoload is missing.")
		return

	game_state.start_new_game()

	if game_state.tutorial_goals.is_empty():
		_fail("tutorial_goals is empty after start_new_game().")
		return

	if bool(game_state.tutorial_goals.get("collect_wood", true)):
		_fail("collect_wood should be false at the start.")
		return

	var compact_text: String = game_state.get_tutorial_goals_compact_text(4)
	if compact_text.is_empty():
		_fail("Compact tutorial goals text is empty.")
		return
	if not compact_text.contains("Первые цели"):
		_fail("Compact tutorial goals text does not contain the title.")
		return

	game_state.complete_tutorial_goal("collect_wood")
	if not bool(game_state.tutorial_goals.get("collect_wood", false)):
		_fail("collect_wood was not completed.")
		return

	var compact_after_complete: String = game_state.get_tutorial_goals_compact_text(4)
	if compact_after_complete.is_empty():
		_fail("Compact tutorial goals text is empty after completing collect_wood.")
		return

	var journal_count_after_first_complete: int = game_state.journal_entries.size()
	game_state.complete_tutorial_goal("collect_wood")
	if game_state.journal_entries.size() != journal_count_after_first_complete:
		_fail("Completing collect_wood twice added a duplicate journal entry.")
		return

	if not game_state.get_tutorial_goals_text().contains("Собрать дерево"):
		_fail("Tutorial goals text does not contain the wood goal title.")
		return

	print("Tutorial goals 0.002 test passed.")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
