extends Node2D

@export var speed: float = 200.0

func _process(delta):
	var direction = Vector2.ZERO
	if Input.is_key_pressed(KEY_W):
		direction.y -= 1
	if Input.is_key_pressed(KEY_S):
		direction.y += 1
	if Input.is_key_pressed(KEY_A):
		direction.x -= 1
	if Input.is_key_pressed(KEY_D):
		direction.x += 1

	if direction != Vector2.ZERO:
		position += direction.normalized() * speed * delta

func _draw():
	# Draw a simple shape for the player
	draw_circle(Vector2.ZERO, 12, Color.RED)
	draw_circle(Vector2.ZERO, 10, Color.WHITE)
	draw_circle(Vector2.ZERO, 5, Color.RED)
