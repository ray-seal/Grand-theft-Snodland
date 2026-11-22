extends CharacterBody3D
class_name SnodlandPlayer

@export var move_speed: float = 5.0
@export var acceleration: float = 18.0
@export var gravity_strength: float = 20.0
var controls_enabled := false

func _physics_process(delta: float) -> void:
	var input_vector := Vector2.ZERO
	if controls_enabled:
		if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT): input_vector.x -= 1.0
		if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT): input_vector.x += 1.0
		if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP): input_vector.y -= 1.0
		if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN): input_vector.y += 1.0
	input_vector = input_vector.normalized()
	var target := Vector3(input_vector.x, 0.0, input_vector.y) * move_speed
	velocity.x = move_toward(velocity.x, target.x, acceleration * delta)
	velocity.z = move_toward(velocity.z, target.z, acceleration * delta)
	if not is_on_floor():
		velocity.y -= gravity_strength * delta
	else:
		velocity.y = 0.0
	move_and_slide()
	if input_vector.length() > 0.05:
		rotation.y = lerp_angle(rotation.y, atan2(-input_vector.x, -input_vector.y), 12.0 * delta)
