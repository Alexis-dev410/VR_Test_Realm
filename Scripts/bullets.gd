extends Node3D

@export var speed: float = 40.0
var velocity: Vector3 = Vector3.ZERO

func set_velocity(v: Vector3) -> void:
	velocity = v

func _physics_process(delta: float) -> void:
	global_position += velocity * delta
