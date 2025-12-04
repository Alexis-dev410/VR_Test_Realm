extends Area3D

@export var speed: float = 80.0
@export var lifetime: float = 3.0
@export var damage: int = 1

var velocity: Vector3 = Vector3.ZERO
var life_timer: float = 0.0

@onready var shoot_sfx: AudioStreamPlayer3D = $Shoot

func ts_delta(delta: float) -> float:
	var tsm := get_tree().get_first_node_in_group("TimeSlowManager")
	if tsm and tsm.is_active():
		if is_in_group("Player"):
			return delta
		return delta * tsm.get_scale()
	return delta

func set_velocity(v: Vector3) -> void:
	velocity = v

func _ready():
	life_timer = lifetime
	connect("body_entered", Callable(self, "_on_body_entered"))

	if shoot_sfx:
		shoot_sfx.play()

func _physics_process(delta):
	var d := ts_delta(delta)
	global_position += velocity * d

	life_timer -= d
	if life_timer <= 0:
		queue_free()

func _on_body_entered(body):
	if body.is_in_group("Enemy"):
		if body.has_method("apply_damage"):
			body.apply_damage(damage)
	queue_free()
