extends State

@onready var anim: AnimationPlayer = $"../../AnimationPlayer"
@onready var navigation_agent: NavigationAgent3D = $"../../NavigationAgent3D"
var enemy: CharacterBody3D

func _ready() -> void:
	enemy = $"../.."

func check_dead():
	if enemy.hp <= 0:
		state_machine.transition_to("Dead")
		return true
	return false

func enter(_msg := {}) -> void:
	if check_dead():
		return
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
		print("❌ Patrolling: state_machine is NULL!")
		return
	# -------------------------------------

	print("Entering Patrolling")
	enemy = $"../.."
	anim.play("Walk")

	var patrol_area = 40.0
	var random_target = Vector3(
		randf_range(-patrol_area/2, patrol_area/2),
		enemy.global_position.y,
		randf_range(-patrol_area/2, patrol_area/2)
	)
	navigation_agent.set_target_position(random_target)

func physics_update(delta: float) -> void:
	enemy.check_vision()
	if state_machine.state.name != "Patrolling":
		return

	if navigation_agent.is_navigation_finished():
		await get_tree().create_timer(0.5).timeout
		state_machine.transition_to("Idle")
		return

	var current_pos = enemy.global_position
	var next_pos = navigation_agent.get_next_path_position()
	var dir = current_pos.direction_to(next_pos)
	enemy.velocity = dir * 15.0

	if enemy.velocity.length() > 0.1:
		var target_basis = Basis.looking_at(enemy.velocity.normalized(), Vector3.UP)
		target_basis = target_basis.rotated(Vector3.UP, PI)
		enemy.basis = enemy.basis.slerp(target_basis, 5.0 * delta)

	enemy.move_and_slide()

func exit() -> void:
	print("Exiting Patrolling")
