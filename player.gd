extends CharacterBody2D

signal flap

const JUMP_VELOCITY = -500.0


func _physics_process(delta: float) -> void:
	velocity += get_gravity() * delta

	if Input.is_action_just_pressed("Flap"):
		velocity.y = JUMP_VELOCITY
		flap.emit()

	move_and_slide()
