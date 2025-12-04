extends State

@onready var anim: AnimationPlayer = $"../../AnimationPlayer"
@onready var navigation_agent: NavigationAgent3D = $"../../NavigationAgent3D"
var enemy: CharacterBody3D
var time_manager

func _ready() -> void:
	enemy = $"../.."
	time_manager = get_tree().get_first_node_in_group("TimeSlowManager")

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
	# -------------------------------------

	if not state_machine:
		print("❌ Patrolling: state_machine is NULL!")
		return

	print("Entering Patrolling")
	anim.play("Walk")

	var patrol_area = 150.0
	var random_target = Vector3(
		randf_range(-patrol_area/2, patrol_area/2),
		enemy.global_position.y,
		randf_range(-patrol_area/2, patrol_area/2)
	)
	navigation_agent.set_target_position(random_target)

func physics_update(delta: float) -> void:
	update_anim_speed()
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

	# --- Movement Slowdown ---
	var slow_scale: float = 1.0
	if time_manager and time_manager.is_active():
		slow_scale = float(time_manager.get_scale())

	# Use enemy's exported speed/turn values if available; otherwise fallback
	var base_speed: float = 5.0
	if Engine.has_singleton("ScriptServer"): # cheap guard; most cases enemy will have the var
		# assume enemy has movement_speed exported (defined in EnemyPathfinding.gd)
		base_speed = float(enemy.movement_speed)

	var base_turn_speed: float = 5.0
	if Engine.has_singleton("ScriptServer"):
		base_turn_speed = float(enemy.turn_speed)

	var speed: float = base_speed * slow_scale
	var rot_speed: float = base_turn_speed * slow_scale

	enemy.velocity = dir * speed
	# -------------------------

	if enemy.velocity.length() > 0.1:
		var target_basis: Basis = Basis.looking_at(enemy.velocity.normalized(), Vector3.UP)
		target_basis = target_basis.rotated(Vector3.UP, PI)
		enemy.basis = enemy.basis.slerp(target_basis, rot_speed * delta)

	enemy.move_and_slide()

func update_anim_speed():
	if not anim:
		return
	var slow_scale: float = 1.0
	if time_manager and time_manager.is_active():
		slow_scale = float(time_manager.get_scale())
	anim.speed_scale = slow_scale


func exit() -> void:
	print("Exiting Patrolling")
