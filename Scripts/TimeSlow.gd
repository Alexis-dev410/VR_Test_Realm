extends Sprite2D

@export var use_time := 5.0
@export var recharge_time := 7.0

var is_active := false  # Blocks re-pressing
var is_recharging := false

@onready var anim_player := $"../AnimationPlayer"
@onready var audio_start := $"../TimeSlowStart"
@onready var audio_stop := $"../TimeSlowStop"

func _ready():
	visible = true  


func _input(event):
	if event.is_action_pressed("time_slow") and not is_active:
		activate_clock()

func activate_clock() -> void:
	is_active = true

	# Speed up fade-in animation so the clock appears quickly
	anim_player.speed_scale = 4.0
	anim_player.play("UseSlow")

	# Play timeslow start audio
	if audio_start:
		audio_start.play()

	timer_sequence()

func timer_sequence() -> void:
	# Let Time Slow run for X seconds
	await get_tree().create_timer(use_time).timeout

	# FORCE STOP current animation so it doesn't hang transparent
	anim_player.stop()

	# Reset normal speed for recharge
	anim_player.speed_scale = 1.0

	# Play fade-out / recharge animation
	anim_player.play("RechargeSlow")

	# Play stop sound
	if audio_stop:
		audio_stop.play()

	# Wait for recharge period
	await get_tree().create_timer(recharge_time).timeout

	visible = false  # Hide clock again after recharge completes

	is_active = false
