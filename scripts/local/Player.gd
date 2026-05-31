extends ColorRect
class_name Player

var speed: float = 220.0
var world_width: float = 0.0
var world_height: float = 0.0


func set_world_bounds(new_world_width: float, new_world_height: float) -> void:
	world_width = new_world_width
	world_height = new_world_height


func _ready() -> void:
	color = Color.html("#1f57ff")
	size = Vector2(32, 32)


func _process(delta: float) -> void:
	var direction := Vector2.ZERO

	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		direction.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		direction.x += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		direction.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		direction.y += 1.0

	if direction != Vector2.ZERO:
		position += direction.normalized() * speed * delta

	var movement_bounds := get_viewport_rect().size
	if world_width > 0.0 and world_height > 0.0:
		movement_bounds = Vector2(world_width, world_height)

	position.x = clamp(position.x, 0.0, movement_bounds.x - size.x)
	position.y = clamp(position.y, 0.0, movement_bounds.y - size.y)
