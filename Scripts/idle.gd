extends State

@onready var anim: AnimationPlayer = $"../../AnimationPlayer"
var enemy: CharacterBody3D

func enter(_msg := {}) -> void:
	print("Entering Idle")
	enemy = $"../.."
	anim.play("Idle")

	# Random idle duration before patrolling
	var wait_time = randf_range(1.0, 2.5)
	await get_tree().create_timer(wait_time).timeout
	if state_machine.state.name == "Idle":
		state_machine.transition_to("Patrolling")

func physics_update(_delta: float) -> void:
	enemy.check_vision()
	enemy.velocity = Vector3.ZERO

func exit() -> void:
	print("Exiting Idle")
