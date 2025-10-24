extends State

@onready var anim: AnimationPlayer = $"../../AnimationPlayer"

func enter(_msg := {}) -> void:
	print("Entering Idle")
	anim.play("Idle")

	# Random idle duration before patrolling again
	var wait_time = randf_range(1.0, 2.5)
	await get_tree().create_timer(wait_time).timeout
	state_machine.transition_to("Patrolling")

func physics_update(_delta: float) -> void:
	# Standing still — no movement logic here
	var enemy = $"../.."
	enemy.velocity = Vector3.ZERO

func exit() -> void:
	print("Exiting Idle")
