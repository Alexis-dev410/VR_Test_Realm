extends Node
class_name TimeSlowManager

@export var slow_scale: float = 0.25
@export var slow_duration: float = 5.0

@onready var audio_start := $"TimeSlowStart"
@onready var audio_stop := $"TimeSlowStop"

var _active: bool = false

func start_time_slow() -> void:
	if _active:
		return

	_active = true
	Engine.time_scale = slow_scale

	if audio_start:
		audio_start.play()

	var timer = Timer.new()
	timer.one_shot = true
	timer.wait_time = slow_duration
	add_child(timer)

	timer.timeout.connect(Callable(self, "_on_timeout").bind(timer))
	timer.start()

func _on_timeout(timer: Timer) -> void:
	end_time_slow_now()
	if timer:
		timer.queue_free()

func end_time_slow_now() -> void:
	if not _active:
		return

	_active = false
	Engine.time_scale = 1.0

	if audio_stop:
		audio_stop.play()
