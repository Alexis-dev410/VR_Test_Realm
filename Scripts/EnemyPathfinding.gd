extends CharacterBody3D

@export var movement_speed: float = 15.0
@export var turn_speed: float = 5.0
@export var movement_target: Node3D

@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D

var reached_target: bool = false

func _ready():
	navigation_agent.path_desired_distance = 0.5
	navigation_agent.target_desired_distance = 0.5

	if not anim.is_playing():
		anim.play("Walk")

	# Connect to ball's teleport signal if it exists
	if movement_target.has_signal("teleported"):
		movement_target.teleported.connect(_on_ball_teleported)

	actor_setup.call_deferred()

func actor_setup():
	await get_tree().physics_frame
	set_movement_target(movement_target.global_position)

func set_movement_target(pos: Vector3):
	navigation_agent.set_target_position(pos)
	reached_target = false
	if anim.current_animation != "Walk":
		anim.play("Walk")

func _physics_process(delta):
	if reached_target:
		return

	if navigation_agent.is_navigation_finished():
		return

	var current_pos: Vector3 = global_position
	var next_pos: Vector3 = navigation_agent.get_next_path_position()

	# Only move in XZ plane
	var direction = next_pos - current_pos
	direction.y = 0
	if direction.length() > 0.01:
		direction = direction.normalized()

	velocity = direction * movement_speed

	# Rotate smoothly toward path direction (flip 180° so he faces forward)
	if direction.length() > 0.1:
		var target_basis = Basis.looking_at(direction, Vector3.UP)
		target_basis = target_basis.rotated(Vector3.UP, PI)
		basis = basis.slerp(target_basis, turn_speed * delta)

	move_and_slide()

# Called when NPC enters the ball’s Area3D
func _on_area_3d_body_entered(body: Node3D) -> void:
	if body == self:
		reached_target = true
		if anim.current_animation != "Idle":
			anim.play("Idle")

# Called when the ball teleports
func _on_ball_teleported():
	set_movement_target(movement_target.global_position)
