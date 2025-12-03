extends State

@onready var anim: AnimationPlayer = $"../../AnimationPlayer"
@export var bullet_scene: PackedScene
@export var attack_range: float = 10.0

var enemy: CharacterBody3D
var has_fired: bool = false

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

	# ensure state_machine reference
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

	enemy = $"../.."

	if not enemy or not enemy.gun_instance:
		print("❌ NPC gun_instance not found")
		return

	if not enemy.muzzle_point:
		enemy.muzzle_point = enemy.gun_instance.get_node_or_null("MuzzlePoint")
		if not enemy.muzzle_point:
			print("❌ MuzzlePoint missing")
			return

	# 🔥 IMPORTANT: If entering Shoot state with 0 ammo → RELOAD immediately
	if enemy.needs_reload():
		print("⛔ Entered Shoot but ammo = 0 → Reloading")
		state_machine.transition_to("Reload")
		return

	has_fired = false
	anim.play("Pistol_Shoot")


func physics_update(delta: float) -> void:
	if not enemy.target:
		state_machine.transition_to("Idle")
		return

	# Vision / distance check
	var dist = enemy.global_position.distance_to(enemy.target.global_position)
	if dist > attack_range or not enemy.can_see_target():
		state_machine.transition_to("FollowBall")
		return

	# Rotate toward player
	var to_target = (enemy.target.global_position - enemy.global_position).normalized()
	var target_basis = Basis.looking_at(to_target, Vector3.UP).rotated(Vector3.UP, PI)
	enemy.basis = enemy.basis.slerp(target_basis, enemy.turn_speed * delta)

	# 🔥 BEFORE FIRING: Check if reload is needed
	if enemy.needs_reload():
		print("⛔ Out of ammo → Reloading")
		state_machine.transition_to("Reload")
		return

	# Fire bullet at the animation firing frame
	if anim.current_animation == "Pistol_Shoot" and anim.current_animation_position > 0.15 and not has_fired:
		fire_bullet()
		has_fired = true

		# 🔥 AFTER FIRING: if ammo now zero, reload
		if enemy.needs_reload():
			print("💀 Ammo reached 0 → Reloading")
			state_machine.transition_to("Reload")
			return

	# End shoot animation return to following
	if not anim.is_playing():
		state_machine.transition_to("FollowBall")


func fire_bullet() -> void:
	# If somehow ammo is empty prevent firing
	if enemy.needs_reload():
		print("❌ Tried to fire with 0 ammo")
		return

	if not bullet_scene or not enemy.muzzle_point:
		print("❌ Cannot fire: missing data")
		return

	# 🔥 CONSUME AMMO HERE
	enemy.consume_ammo()
	print("🔫 Ammo after shot:", enemy.ammo)

	var bullet = bullet_scene.instantiate()
	get_tree().current_scene.add_child(bullet)

	var start_pos = enemy.muzzle_point.global_position
	var target_pos = enemy.target.global_position + Vector3(0, 1.5, 0)
	var dir = (target_pos - start_pos).normalized()

	bullet.global_transform.origin = start_pos
	bullet.look_at(target_pos, Vector3.UP)

	if bullet.has_method("set_velocity"):
		bullet.set_velocity(dir * 40.0)
