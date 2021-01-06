extends Node2D

var motion : Vector2 = Vector2.ZERO
export(float, 0.0, 1.0, 0.001) var damping = 1.0


func _physics_process(delta):
	#Apply Motion
	position += motion * delta
	
	#Apply Damping
	motion *= damping


func calculate_motion(target_point: Vector2, stiffness: float = 1.0) -> Vector2:
	return (target_point - global_position) * stiffness
