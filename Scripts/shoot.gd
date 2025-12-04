extends State

@onready var anim: AnimationPlayer = $"../../AnimationPlayer"
@export var bullet_scene: PackedScene
@export var attack_range: float = 20.0

var enemy: CharacterBody3D
var has_fired: bool = false
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

	# safe state_machine assignment
	if not state_machine:
		var p = get_parent()
		for i in range(4):
			if p is StateMachine:
				state_machine = p
				break
			p = p.get_parent()

	enemy = $"../.."

	if not enemy or not enemy.gun_instance:
		print("❌ NPC gun_instance not found")
		return

	# fetch muzzle if missing
	if not enemy.muzzle_point:
		enemy.muzzle_point = enemy.gun_instance.get_node_or_null("MuzzlePoint")
		if not enemy.muzzle_point:
			print("❌ MuzzlePoint missing")
			return

	# reload if needed
	if enemy.needs_reload():
		state_machine.transition_to("Reload")
		return

	has_fired = false
	anim.play("Pistol_Shoot")

func physics_update(delta: float) -> void:
	update_anim_speed()
	if not enemy.target:
		state_machine.transition_to("Idle")
		return

	var target = enemy.target

	# === Slowdown scaling ===
	var slow_scale: float = 1.0
	if time_manager and time_manager.is_active():
		slow_scale = float(time_manager.get_scale())

	var rot_speed = enemy.turn_speed * slow_scale
	# ========================

	# distance/vision check
	var dist = enemy.global_position.distance_to(target.global_position)
	if dist > attack_range or not enemy.can_see_target():
		state_machine.transition_to("FollowBall")
		return

	# rotate toward target (scaled)
	var to_target = (target.global_position - enemy.global_position).normalized()
	var target_basis = Basis.looking_at(to_target, Vector3.UP).rotated(Vector3.UP, PI)
	enemy.basis = enemy.basis.slerp(target_basis, rot_speed * delta)

	# ammo check
	if enemy.needs_reload():
		state_machine.transition_to("Reload")
		return

	# fire moment
	if anim.current_animation == "Pistol_Shoot" \
	and anim.current_animation_position > 0.15 \
	and not has_fired:

		fire_bullet()
		has_fired = true

		if enemy.needs_reload():
			state_machine.transition_to("Reload")
			return

	# animation ended → chase
	if not anim.is_playing():
		state_machine.transition_to("FollowBall")

func fire_bullet() -> void:
	if enemy.needs_reload():
		return

	if not bullet_scene or not enemy.muzzle_point:
		return

	enemy.consume_ammo()

	var bullet = bullet_scene.instantiate()
	get_tree().current_scene.add_child(bullet)

	var start_pos = enemy.muzzle_point.global_position
	var target_pos = enemy.target.global_position + Vector3(0, 1.5, 0)
	var dir = (target_pos - start_pos).normalized()

	bullet.global_transform.origin = start_pos
	bullet.look_at(target_pos, Vector3.UP)

	if bullet.has_method("set_velocity"):
		bullet.set_velocity(dir * 40.0)

func update_anim_speed():
	if not anim:
		return
	var slow_scale: float = 1.0
	if time_manager and time_manager.is_active():
		slow_scale = float(time_manager.get_scale())
	anim.speed_scale = slow_scale
