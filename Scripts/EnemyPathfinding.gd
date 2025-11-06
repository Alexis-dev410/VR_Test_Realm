extends CharacterBody3D

@onready var sm: StateMachine = $StateMachine
@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var nav: NavigationAgent3D = $NavigationAgent3D
@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@export var gun_scene: PackedScene
@onready var skeleton: Skeleton3D = $Skeleton3D

@export var movement_speed: float = 15.0
@export var turn_speed: float = 5.0
@export var vision_angle: float = 360.0  # degrees
@export var vision_distance: float = 30.0  # optional max distance

var target: CharacterBody3D
var gun_instance: Node3D

func set_target(new_target: Node3D) -> void:
	target = new_target
	if target:
		print("✅ NPC target set.")
	else:
		print("❌ Target is null.")

func _ready():
	nav_agent.avoidance_enabled = true
	nav_agent.radius = 0.5
	nav_agent.height = 1.8

	if skeleton and gun_scene:
		var ba = skeleton.find_child("RightHandAttachment", true, false)
		if not ba:
			ba = BoneAttachment3D.new()
			ba.name = "RightHandAttachment"
			ba.bone_name = "DEF-hand.R"
			skeleton.add_child(ba)

		gun_instance = gun_scene.instantiate()
		ba.add_child(gun_instance)
		gun_instance.visible = true
		print("🔫 NPC equipped with gun.")



func _on_target_teleported():
	if sm.state.name != "FollowBall":
		print("🎯 Target teleported — switching to FollowBall")
		sm.transition_to("FollowBall")
	else:
		print("🔁 Target teleported — refreshing path")
		if target:
			$NavigationAgent3D.set_target_position(target.global_position)


func can_see_target() -> bool:
	if not target:
		return false

	var space_state = get_world_3d().direct_space_state

	# --- Direction and distance ---
	var to_target = target.global_position - global_position
	var distance_to_target = to_target.length()
	if distance_to_target > vision_distance:
		return false

	# --- Field of View ---
	to_target = to_target.normalized()
	var forward = -global_transform.basis.z.normalized()  # NPC faces -Z
	var dot = clamp(forward.dot(to_target), -1.0, 1.0)
	var angle_deg = rad_to_deg(acos(dot))
	if angle_deg > vision_angle / 2:
		return false

	# --- Raycast (eye height to target center) ---
	var eye_height = 1.5
	var target_height = 1.0  # adjust based on capsule size
	var start = global_position + Vector3.UP * eye_height
	var end = target.global_position + Vector3.UP * target_height

	var params = PhysicsRayQueryParameters3D.new()
	params.from = start
	params.to = end
	params.exclude = [self]
	params.collide_with_areas = false
	params.collide_with_bodies = true

	var result = space_state.intersect_ray(params)

	# --- Visibility check ---
	if result and result.collider != target:
		return false  # blocked by wall or obstacle

	return true


func check_vision() -> void:
	if not target:
		return

	if can_see_target():
		# Switch to following if not already
		if sm.state.name not in ["FollowBall", "Shoot"]:
			print("👀 NPC sees the player — switching to FollowBall")
			sm.transition_to("FollowBall")
	else:
		# Optional: buffer to prevent flickering when target teleports
		if sm.state.name == "FollowBall":
			await get_tree().create_timer(0.5).timeout
			if not can_see_target() and sm.state.name == "FollowBall":
				print("❌ Lost sight of player — going Idle")
				sm.transition_to("Idle")
