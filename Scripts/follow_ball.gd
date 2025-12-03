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
	if not state_machine:
		var p = get_parent()
		for i in range(4):
			if p is StateMachine:
				state_machine = p
				break
			p = p.get_parent()

	print("Entering FollowBall")
	anim.play("Walk")
	lost_sight_timer = 0.0

func physics_update(delta: float) -> void:
	if check_dead():
		return

	if not enemy.target:
		state_machine.transition_to("Idle")
		return

	var tgt = enemy.target
	var dist = enemy.global_position.distance_to(tgt.global_position)

	if enemy.can_see_target():
		lost_sight_timer = 0.0
		navigation_agent.set_target_position(tgt.global_position)
	else:
		lost_sight_timer += delta
		if lost_sight_timer >= lost_sight_delay:
			state_machine.transition_to("Idle")
			return

	if dist <= attack_range:
		state_machine.transition_to("Shoot")
		return

	if not navigation_agent.is_navigation_finished():
		var current_pos = enemy.global_position
		var next_pos = navigation_agent.get_next_path_position()
		var dir = current_pos.direction_to(next_pos)

		# Set movement direction only
		enemy.move_dir = dir

		# Rotation
		if dir.length() > 0.1:
			var tb = Basis.looking_at(dir, Vector3.UP).rotated(Vector3.UP, PI)
			enemy.basis = enemy.basis.slerp(tb, 5.0 * delta)

func exit() -> void:
	print("Exiting FollowBall")
