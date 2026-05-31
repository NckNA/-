extends ColorRect
class_name ResourceNode

signal resource_clicked(resource_node)

const TYPE_TREE := "tree"
const TYPE_BERRY_BUSH := "berry_bush"
const TYPE_STONE := "stone"

var resource_id: String = ""
var resource_type: String = ""
var amount: int = 1


func setup(new_resource_id: String, new_resource_type: String, new_amount: int, new_position: Vector2) -> void:
	resource_id = new_resource_id
	resource_type = new_resource_type
	amount = new_amount
	position = new_position
	mouse_filter = Control.MOUSE_FILTER_STOP

	match resource_type:
		TYPE_TREE:
			size = Vector2(34, 48)
			color = Color.html("#166b2f")
		TYPE_BERRY_BUSH:
			size = Vector2(30, 24)
			color = Color.html("#8bc34a")
		TYPE_STONE:
			size = Vector2(34, 28)
			color = Color.html("#676767")

	tooltip_text = "%s: %d" % [resource_type, amount]

	if amount <= 0:
		hide()
		mouse_filter = Control.MOUSE_FILTER_IGNORE


func collect_one() -> void:
	amount -= 1

	if amount <= 0:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		queue_free()
	else:
		tooltip_text = "%s: %d" % [resource_type, amount]


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			resource_clicked.emit(self)
			accept_event()
