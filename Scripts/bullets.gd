extends Area3D

@export var speed: float = 40.0
@export var lifetime: float = 3.0
var velocity: Vector3 = Vector3.ZERO
var life_timer: float = 0.0

func set_velocity(v: Vector3) -> void:
	velocity = v

func _ready() -> void:
	life_timer = lifetime
	connect("body_entered", Callable(self, "_on_body_entered"))

func _physics_process(delta: float) -> void:
	global_position += velocity * delta

	# countdown lifetime
	life_timer -= delta
	if life_timer <= 0.0:
		queue_free()

func _on_body_entered(body: Node) -> void:
	# prevent self-collision if needed
	if body.is_in_group("enemies"):
		return

	print("💥 Bullet hit:", body.name)
	queue_free()
