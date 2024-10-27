extends Area2D


const speed = 300.0


func _physics_process(delta: float) -> void:
	position.x -= delta * speed
	if global_position.x < -150:
		call_deferred("free")
