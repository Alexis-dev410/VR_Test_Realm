extends State

@onready var anim: AnimationPlayer = $"../../AnimationPlayer"
@onready var navigation_agent: NavigationAgent3D = $"../../NavigationAgent3D"
var enemy: CharacterBody3D
var time_manager

@export var follow_speed: float = 10.0
@export var attack_range: float = 20.0
@export var lost_sight_delay: float = 2.0
var lost_sight_timer: float = 0.0

func _ready() -> void:
	enemy = $"../.."
	time_manager = get_tree().get_first_node_in_group("TimeSlowManager")

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
	update_anim_speed()
	if check_dead():
		return
	if not enemy.target:
		state_machine.transition_to("Idle")
		return

	var target = enemy.target
	var dist = enemy.global_position.distance_to(target.global_position)

	# === Slowdown scaling ===
	var slow_scale: float = 1.0
	if time_manager and time_manager.is_active():
		slow_scale = float(time_manager.get_scale())

	var speed = follow_speed * slow_scale
	var rot_speed = enemy.turn_speed * slow_scale
	# ========================

	if enemy.can_see_target():
		lost_sight_timer = 0.0
		navigation_agent.set_target_position(target.global_position)
	else:
		lost_sight_timer += delta
		if lost_sight_timer >= lost_sight_delay:
			state_machine.transition_to("Idle")
			return

	# attack?
	if dist <= attack_range:
		state_machine.transition_to("Shoot")
		return

	# movement
	if not navigation_agent.is_navigation_finished():
		var current_pos = enemy.global_position
		var next_pos = navigation_agent.get_next_path_position()
		var dir = current_pos.direction_to(next_pos)

		enemy.velocity = dir * speed

		if enemy.velocity.length() > 0.1:
			var tb = Basis.looking_at(enemy.velocity.normalized(), Vector3.UP)
			tb = tb.rotated(Vector3.UP, PI)
			enemy.basis = enemy.basis.slerp(tb, rot_speed * delta)

	enemy.move_and_slide()

func update_anim_speed():
	if not anim:
		return
	var slow_scale: float = 1.0
	if time_manager and time_manager.is_active():
		slow_scale = float(time_manager.get_scale())
	anim.speed_scale = slow_scale


func exit() -> void:
	print("Exiting FollowBall")
