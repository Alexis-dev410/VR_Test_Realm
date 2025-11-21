extends Area3D

@export var speed: float = 80.0
@export var lifetime: float = 3.0
@export var damage: int = 1

var velocity: Vector3 = Vector3.ZERO
var life_timer: float = 0.0

func set_velocity(v: Vector3) -> void:
	velocity = v

func _ready():
	life_timer = lifetime
	connect("body_entered", Callable(self, "_on_body_entered"))

func _physics_process(delta):
	global_position += velocity * delta

	life_timer -= delta
	if life_timer <= 0:
		queue_free()

func _on_body_entered(body):
	if body.is_in_group("Enemy"):
		if body.has_method("apply_damage"):
			body.apply_damage(damage)
	print("💥 Bullet hit:", body.name)
	queue_free()  # despawn bullet on any hit
