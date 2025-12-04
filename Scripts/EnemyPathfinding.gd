extends CharacterBody3D

@onready var sm: EnemyStateMachine = $StateMachine
@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var skeleton: Skeleton3D = $Rig/Skeleton3D
@export var gun_scene: PackedScene
@export var reload_time: float = 1.5

@export var movement_speed: float = 15.0
@export var turn_speed: float = 5.0
@export var vision_angle: float = 360.0
@export var vision_distance: float = 40.0
@export var max_hp: int = 1
@export var max_ammo: int = 7

var hp: int = 5
var target: CharacterBody3D
var gun_instance: Node3D
var muzzle_point: Node3D
var ammo: int = max_ammo
var is_reloading: bool = false


func ts_delta(delta: float) -> float:
	var tsm := get_tree().get_first_node_in_group("TimeSlowManager")
	if tsm and tsm.is_active():
		if is_in_group("Enemy"):
			return delta * tsm.get_scale()
	return delta


func set_target(new_target: Node3D) -> void:
	target = new_target
	if target:
		print("✔ NPC target set.")
	else:
		print("❌ Target is null.")

func _ready():
	nav_agent.avoidance_enabled = true
	nav_agent.radius = 0.5
	nav_agent.height = 1.8

	if gun_scene and skeleton:
		var ba = skeleton.find_child("RightHandAttachment", true, false)
		if not ba:
			ba = BoneAttachment3D.new()
			ba.name = "RightHandAttachment"
			ba.bone_name = "DEF-hand.R"
			skeleton.add_child(ba)

		gun_instance = gun_scene.instantiate()
		ba.add_child(gun_instance)
		gun_instance.visible = true

		gun_instance.position = Vector3(-0.044, 0.183, 0.019)
		gun_instance.rotation_degrees = Vector3(76.9, -17.4, -15.5)
		gun_instance.scale = Vector3(0.7, 0.7, 0.7)

		muzzle_point = gun_instance.get_node_or_null("MuzzlePoint")
		if not muzzle_point:
			muzzle_point = Node3D.new()
			muzzle_point.name = "MuzzlePoint"
			muzzle_point.transform.origin = Vector3(0, 0, -0.5)
			gun_instance.add_child(muzzle_point)

	hp = max_hp

func _on_target_teleported():
	if sm.state.name != "FollowBall":
		sm.transition_to("FollowBall")
	else:
		if target:
			nav_agent.set_target_position(target.global_position)

func can_see_target() -> bool:
	if not target:
		return false

	var space_state = get_world_3d().direct_space_state
	var to_target = target.global_position - global_position

	if to_target.length() > vision_distance:
		return false

	var forward = -global_transform.basis.z.normalized()
	var ang = rad_to_deg(acos(clamp(forward.dot(to_target.normalized()), -1, 1)))
	if ang > vision_angle / 2:
		return false

	var start = global_position + Vector3.UP * 1.5
	var end = target.global_position + Vector3.UP

	var params = PhysicsRayQueryParameters3D.new()
	params.from = start
	params.to = end
	params.exclude = [self]
	params.collide_with_areas = false
	params.collide_with_bodies = true

	var result = space_state.intersect_ray(params)
	if result and result.collider != target:
		return false

	return true

func check_vision():
	if not target:
		return

	if can_see_target():
		if sm.state.name not in ["FollowBall", "Shoot"]:
			sm.transition_to("FollowBall")
	else:
		if sm.state.name == "FollowBall":
			await get_tree().create_timer(0.5).timeout
			if not can_see_target() and sm.state.name == "FollowBall":
				sm.transition_to("Idle")

func apply_damage(amount: int):
	hp -= amount
	if hp <= 0:
		sm.transition_to("Dead")

func consume_ammo():
	ammo -= 1
	if ammo < 0:
		ammo = 0

func needs_reload() -> bool:
	return ammo <= 0

func start_reload():
	if is_reloading:
		return
	if ammo >= max_ammo:
		return

	is_reloading = true
	sm.transition_to("Reload")
