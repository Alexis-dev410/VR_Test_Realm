extends State

@onready var anim: AnimationPlayer = $"../../AnimationPlayer"
@export var bullet_scene: PackedScene
@export var attack_range: float = 10.0

var enemy: CharacterBody3D
var has_fired: bool = false

func enter(_msg := {}) -> void:
	enemy = $"../.."

	if not enemy or not enemy.gun_instance:
		print("❌ NPC gun_instance not found, cannot shoot")
		return

	if not enemy.muzzle_point:
		enemy.muzzle_point = enemy.gun_instance.get_node_or_null("MuzzlePoint")
		if not enemy.muzzle_point:
			print("❌ MuzzlePoint missing on gun")
			return

	has_fired = false
	anim.play("Pistol_Shoot")
	print("🎬 Playing shoot animation")

func physics_update(delta: float) -> void:
	if not enemy.target:
		state_machine.transition_to("Idle")
		return

	var dist_to_target = enemy.global_position.distance_to(enemy.target.global_position)
	if dist_to_target > attack_range or not enemy.can_see_target():
		state_machine.transition_to("FollowBall")
		return

	# Face target
	var to_target = (enemy.target.global_position - enemy.global_position).normalized()
	var target_basis = Basis.looking_at(to_target, Vector3.UP).rotated(Vector3.UP, PI)
	enemy.basis = enemy.basis.slerp(target_basis, enemy.turn_speed * delta)

	# Wait until a specific animation frame or time to fire once
	if anim.current_animation == "Pistol_Shoot" and anim.current_animation_position > 0.15 and not has_fired:
		fire_bullet()
		has_fired = true

	# When the animation finishes, return to follow or idle
	if not anim.is_playing():
		state_machine.transition_to("FollowBall")

func fire_bullet() -> void:
	if not bullet_scene or not enemy.gun_instance or not enemy.muzzle_point:
		print("❌ Cannot fire: missing bullet_scene or muzzle_point")
		return

	print("🔫 fire_bullet called")

	var bullet = bullet_scene.instantiate()
	get_tree().current_scene.add_child(bullet)

	# Get start position from muzzle
	var start_pos = enemy.muzzle_point.global_position

	# Aim directly at the target (ignoring any animation tilt)
	var target_pos = enemy.target.global_position + Vector3(0, 1.5, 0) # aim roughly at chest/head height
	var dir = (target_pos - start_pos).normalized()

	# Place bullet and orient it along direction
	bullet.global_transform.origin = start_pos
	bullet.look_at(target_pos, Vector3.UP)

	print("🔥 Bullet fired from:", start_pos, "toward:", target_pos, "dir:", dir)

	# Apply velocity
	if bullet.has_method("set_velocity"):
		bullet.set_velocity(dir * 40.0)
