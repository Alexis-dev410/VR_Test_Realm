extends State

@onready var anim: AnimationPlayer = $"../../AnimationPlayer"
var enemy: CharacterBody3D

func _ready() -> void:
	enemy = $"../.."

func check_dead():
	if enemy.hp <= 0:
		state_machine.transition_to("Dead")
		return true
	return false

func enter(_msg := {}) -> void:
	# --- Safe state_machine assignment ---
	if not state_machine:
		var p = get_parent()
		if p is StateMachine:
			state_machine = p
		else:
			for i in range(4):
				p = p.get_parent()
				if p is StateMachine:
					state_machine = p
					break

	if not state_machine:
		print("❌ Idle: state_machine is NULL!")
		return
	# -------------------------------------

	print("Entering Idle")
	enemy = $"../.."
	anim.play("Idle")

	var wait_time = randf_range(1.0, 2.5)
	await get_tree().create_timer(wait_time).timeout

	if state_machine.state and state_machine.state.name == "Idle":
		state_machine.transition_to("Patrolling")

func physics_update(_delta: float) -> void:
	if check_dead():
		return
	enemy.check_vision()
	enemy.velocity = Vector3.ZERO

func exit() -> void:
	print("Exiting Idle")
