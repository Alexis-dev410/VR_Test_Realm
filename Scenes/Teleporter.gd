extends Node3D

@export var teleport_interval: float = 5.0
@onready var timer: Timer = Timer.new()

signal teleported

func _ready():
	timer.wait_time = teleport_interval
	timer.autostart = true
	timer.one_shot = false
	add_child(timer)
	timer.timeout.connect(_on_timer_timeout)

func _on_timer_timeout():
	var new_x = randf_range(-20.0, 20.0)
	var new_z = randf_range(-20.0, 20.0)
	global_position = Vector3(new_x, global_position.y, new_z)
	print("Ball teleported to:", global_position)
	emit_signal("teleported")
