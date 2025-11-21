extends Sprite2D

@export var use_time := 2.8
@export var recharge_time := 7.0

var is_active := false

@onready var anim_player := $"../AnimationPlayer"
@onready var manager := $"../../.."
@onready var audio_start := $"../TimeSlowStart"
@onready var audio_stop := $"../TimeSlowStop"

func _ready():
	await get_tree().process_frame
	visible = true
	anim_player.playback_process_mode = AnimationPlayer.ANIMATION_PROCESS_IDLE
	anim_player.animation_finished.connect(Callable(self, "_on_animation_finished"))

func _input(event):
	if event.is_action_pressed("time_slow") and not is_active:
		await activate_clock()

func activate_clock() -> void:
	is_active = true

	anim_player.speed_scale = 4.0
	anim_player.play("UseSlow")

	if audio_start:
		audio_start.play()

	if manager:
		manager.start_time_slow()

	var real_use_time := use_time
	if manager:
		real_use_time = manager.slow_duration * manager.slow_scale

	await get_tree().create_timer(real_use_time, false).timeout

	if manager and manager.has_method("end_time_slow_now"):
		manager.end_time_slow_now()
	elif manager and manager.has_method("_end_time_slow"):
		manager._end_time_slow()

	anim_player.speed_scale = 1.0
	anim_player.play("RechargeSlow")

	if audio_stop:
		audio_stop.play()

func _on_animation_finished(anim_name: String) -> void:
	if anim_name == "RechargeSlow" and not anim_player.is_playing():
		is_active = false
