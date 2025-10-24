extends State

@onready var anim: AnimationPlayer = $"../../AnimationPlayer"
@onready var navigation_agent: NavigationAgent3D = $"../../NavigationAgent3D"
var enemy: CharacterBody3D
var last_target_position: Vector3
var lost_timer: float = 0.0

func enter(_msg := {}) -> void:
	print("Entering FollowBall")
	enemy = $"../.."
	anim.play("Walk")

	if enemy.target:
		last_target_position = enemy.target.global_position
		navigation_agent.set_target_position(last_target_position)
	else:
		print("⚠️ No target set — staying idle.")
		state_machine.transition_to("Idle")

func physics_update(delta: float) -> void:
	if not enemy.target:
		return

	# --- Update path if target moved ---
	if enemy.target.global_position.distance_to(last_target_position) > 0.5:
		last_target_position = enemy.target.global_position
		navigation_agent.set_target_position(last_target_position)

	# --- Handle navigation ---
	if navigation_agent.is_navigation_finished():
		# Wait a short moment to confirm we’re really done (avoid teleport flicker)
		lost_timer += delta
		if lost_timer > 1.0:
			print("🎯 Ball reached — going idle.")
			state_machine.transition_to("Idle")
			return
	else:
		lost_timer = 0.0

	var next_pos = navigation_agent.get_next_path_position()
	var dir = enemy.global_position.direction_to(next_pos)
	enemy.velocity = dir * enemy.movement_speed
	enemy.move_and_slide()

	if enemy.velocity.length() > 0.1:
		var target_basis = Basis.looking_at(enemy.velocity.normalized(), Vector3.UP)
		target_basis = target_basis.rotated(Vector3.UP, PI)
		enemy.basis = enemy.basis.slerp(target_basis, enemy.turn_speed * delta)

func exit() -> void:
	print("Exiting FollowBall")
