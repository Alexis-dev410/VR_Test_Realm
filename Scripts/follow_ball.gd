extends State

@onready var anim: AnimationPlayer = $"../../AnimationPlayer"
@onready var navigation_agent: NavigationAgent3D = $"../../NavigationAgent3D"
var enemy: CharacterBody3D

@export var follow_speed: float = 15.0
@export var attack_range: float = 10.0
@export var lost_sight_delay: float = 2.0
var lost_sight_timer: float = 0.0

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
		print("❌ FollowBall: state_machine is NULL!")
		return
	# -------------------------------------

	print("Entering FollowBall")
	enemy = $"../.."
	anim.play("Walk")
	lost_sight_timer = 0.0

func physics_update(delta: float) -> void:
	if check_dead():
		return
	if not enemy.target:
		state_machine.transition_to("Idle")
		return

	var target = enemy.target
	var dist = enemy.global_position.distance_to(target.global_position)

	if enemy.can_see_target():
		lost_sight_timer = 0.0
		navigation_agent.set_target_position(target.global_position)
	else:
		lost_sight_timer += delta
		if lost_sight_timer >= lost_sight_delay:
			print("Lost sight → Idle")
			state_machine.transition_to("Idle")
			return

	if dist <= attack_range:
		state_machine.transition_to("Shoot")
		return

	if not navigation_agent.is_navigation_finished():
		var current_pos = enemy.global_position
		var next_pos = navigation_agent.get_next_path_position()
		var dir = current_pos.direction_to(next_pos)
		enemy.velocity = dir * follow_speed

		if enemy.velocity.length() > 0.1:
			var target_basis = Basis.looking_at(enemy.velocity.normalized(), Vector3.UP)
			target_basis = target_basis.rotated(Vector3.UP, PI)
			enemy.basis = enemy.basis.slerp(target_basis, 5.0 * delta)

	enemy.move_and_slide()

func exit() -> void:
	print("Exiting FollowBall")
