extends CharacterBody3D

@onready var sm: StateMachine = $StateMachine
@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var nav: NavigationAgent3D = $NavigationAgent3D

@export var movement_speed: float = 15.0
@export var turn_speed: float = 5.0
@export var vision_angle: float = 60.0  # degrees
@export var vision_distance: float = 30.0  # optional max distance

var target: Node3D

func set_target(new_target: Node3D) -> void:
	target = new_target
	if target:
		print("✅ NPC target set.")
	else:
		print("❌ Target is null.")



func _on_target_teleported():
	if sm.state.name != "FollowBall":
		print("🎯 Target teleported — switching to FollowBall")
		sm.transition_to("FollowBall")
	else:
		print("🔁 Target teleported — refreshing path")
		if target:
			$NavigationAgent3D.set_target_position(target.global_position)


# --- Vision check method ---
func can_see_target() -> bool:
	if not target:
		return false

	var to_target = (target.global_position - global_position).normalized()
	var forward = -global_transform.basis.z.normalized()  # NPC faces -Z
	var angle_deg = rad_to_deg(acos(forward.dot(to_target)))  # Godot 4.4

	if angle_deg > vision_angle / 2:
		return false  # target outside FOV

	# Raycast for obstacles
	var params = PhysicsRayQueryParameters3D.new()
	params.from = global_position
	params.to = target.global_position
	params.exclude = [self]

	var space_state = get_world_3d().direct_space_state
	var result = space_state.intersect_ray(params)
	if result and result.collider != target:
		return false  # something blocking view

	# Optional: distance check
	if global_position.distance_to(target.global_position) > vision_distance:
		return false

	return true


func check_vision():
	if target and can_see_target():
		if sm.state.name != "FollowBall":
			print("👀 NPC sees the target — switching to FollowBall")
			sm.transition_to("FollowBall")
