extends CharacterBody3D

@export var move_speed: float = 2.0
@export var gravity: float = 9.8
@export var turn_speed: float = 5.0   # Larger = faster interpolation

@onready var anim: AnimationPlayer = $AnimationPlayer

var move_direction: Vector3 = Vector3.ZERO
var change_timer: float = 0.0
var interval: float = 7.0

func _ready() -> void:
	_choose_new_direction()

func _physics_process(delta: float) -> void:
	change_timer -= delta
	if change_timer <= 0.0:
		_choose_new_direction()

	# Gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0

	# Horizontal movement
	var horiz = move_direction * move_speed
	velocity.x = horiz.x
	velocity.z = horiz.z

	move_and_slide()

	# Smoothly rotate toward movement direction (with 180° correction)
	if move_direction.length() > 0.1:
		var target_basis = Basis.looking_at(move_direction, Vector3.UP)
		target_basis = target_basis.rotated(Vector3.UP, PI) # Flip 180° around Y
		basis = basis.slerp(target_basis, turn_speed * delta)

func _choose_new_direction() -> void:
	var angle = randf_range(0.0, TAU)
	move_direction = Vector3(cos(angle), 0.0, sin(angle)).normalized()
	change_timer = interval
	if not anim.is_playing():
		anim.play("Walk")
