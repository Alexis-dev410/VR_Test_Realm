extends State

@onready var anim: AnimationPlayer = $"../../AnimationPlayer"
@onready var gun: Node3D = null
@onready var muzzle_flash: Node3D = null
var enemy: CharacterBody3D

@export var fire_rate: float = 1.0
@export var attack_range: float = 10.0
@export var bullet_scene: PackedScene
var fire_timer: float = 0.0

# Fixed local position for gun in NPC space
var gun_position: Vector3 = Vector3(-0.169, 1.436, 0.544)

func enter(_msg := {}) -> void:
	enemy = $"../.."
	anim.play("Pistol_Shoot")
	fire_timer = 0.0

	# Place gun manually in front of NPC
	if enemy.gun_instance:
		gun = enemy.gun_instance
		gun.global_position = enemy.global_position + gun_position
		gun.visible = true

		# Find muzzle flash under the gun if present
		muzzle_flash = gun.get_node_or_null("MuzzleFlash")
		if muzzle_flash:
			muzzle_flash.visible = false

func physics_update(delta: float) -> void:
	if not enemy.target:
		state_machine.transition_to("Idle")
		return

	# Keep gun following NPC
	if gun:
		gun.global_position = enemy.global_position + gun_position
		gun.look_at(enemy.target.global_position, Vector3.UP)  # optional: orient toward target

	# Keep animation playing
	if anim.current_animation != "Pistol_Shoot":
		anim.play("Pistol_Shoot")

	var dist_to_target = enemy.global_position.distance_to(enemy.target.global_position)

	# Switch to FollowBall if target out of range or not visible
	if dist_to_target > attack_range or not enemy.can_see_target():
		state_machine.transition_to("FollowBall")
		return

	fire_timer -= delta
	if fire_timer <= 0.0:
		fire_bullet()
		fire_timer = fire_rate

	# Face the target
	var to_target = (enemy.target.global_position - enemy.global_position).normalized()
	var target_basis = Basis.looking_at(to_target, Vector3.UP)
	target_basis = target_basis.rotated(Vector3.UP, PI)
	enemy.basis = enemy.basis.slerp(target_basis, enemy.turn_speed * delta)


func fire_bullet() -> void:
	if not bullet_scene or not muzzle_flash:
		return

	# Flash and play animation
	anim.play("Pistol_Shoot")
	muzzle_flash.visible = true
	await get_tree().create_timer(0.05).timeout
	muzzle_flash.visible = false

	# Fire bullet
	var bullet = bullet_scene.instantiate()
	get_tree().current_scene.add_child(bullet)
	bullet.global_transform = muzzle_flash.global_transform

	if bullet.has_method("set_velocity"):
		var dir = -muzzle_flash.global_transform.basis.z.normalized()
		bullet.set_velocity(dir * 40.0)
