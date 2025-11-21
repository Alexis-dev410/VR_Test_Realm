extends Sprite2D

@export var use_time := 2.8
@export var recharge_time := 7.0

var is_active := false

@onready var anim_player := $"../AnimationPlayer"
@onready var audio_start := $"../TimeSlowStart"
@onready var audio_stop := $"../TimeSlowStop"

func _ready():
	await get_tree().process_frame
	visible = true
	anim_player.playback_process_mode = AnimationPlayer.ANIMATION_PROCESS_IDLE  # ignore time scale

func _input(event):
	if event.is_action_pressed("time_slow") and not is_active:
		await activate_clock()

func activate_clock() -> void:
	is_active = true

	# Speed up fade-in animation
	anim_player.speed_scale = 4.0
	anim_player.play("UseSlow")

	if audio_start:
		audio_start.play()

	await timer_sequence()

func timer_sequence() -> void:
	# Wait for Time Slow duration (real seconds)
	await get_tree().create_timer(use_time, false).timeout

	# FORCE STOP current animation so the clock doesn't hang transparent
	anim_player.stop()

	# Reset normal speed for recharge
	anim_player.speed_scale = 1.0
	anim_player.play("RechargeSlow")

	# Play stop audio
	if audio_stop:
		audio_stop.play()

	# Wait for recharge period (real seconds)
	await get_tree().create_timer(recharge_time, false).timeout

	is_active = false
 
