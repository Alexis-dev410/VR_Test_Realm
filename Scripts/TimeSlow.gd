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

	anim_player.play("UseSlow")

	if audio_start:
		audio_start.play()

	if manager:
		manager.start_time_slow()

	var real_use_time: float = use_time
	if manager:
		real_use_time = float(manager.slow_duration)
		await get_tree().create_timer(real_use_time, false).timeout

	if manager:
		manager.end_time_slow_now()

	anim_player.play("RechargeSlow")

	if audio_stop:
		audio_stop.play()

func _on_animation_finished(anim_name: String):
	if anim_name == "RechargeSlow" and not anim_player.is_playing():
		is_active = false
