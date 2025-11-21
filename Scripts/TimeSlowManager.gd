extends Node
class_name TimeSlowManager

signal time_slow_started(target_scale: float, duration: float)
signal time_slow_ended()

@export var slow_scale: float = 0.25         # engine time_scale when slowed
@export var slow_duration: float = 5.0       # default automatic duration (seconds)
@export var transition_time: float = 0.25    # ramp in/out time (seconds)
@export var audio_bus_name: String = "Master" # bus to apply pitch shift (optional)
@export var use_audio_pitch: bool = true     # toggle pitch effect usage
@export var pitch_factor_multiplier: float = 1.0 # multiply target_scale to compute pitch

var _active: bool = false
var _tween: Tween = null
var _auto_timer: Timer = null
var _bus_index: int = -1
var _pitch_effect_idx: int = -1
var _original_pitch_scale: float = 1.0

func _ready() -> void:
	# Prepare timer
	_auto_timer = Timer.new()
	_auto_timer.one_shot = true
	add_child(_auto_timer)
	_auto_timer.timeout.connect(Callable(self, "_on_auto_timeout"))

	# Resolve audio bus + pitch effect if requested
	_bus_index = AudioServer.get_bus_index(audio_bus_name)
	if _bus_index != -1 and use_audio_pitch:
		# find first AudioEffectPitchShift on that bus
		var count := AudioServer.get_bus_effect_count(_bus_index)
		_pitch_effect_idx = -1
		for i in range(count):
			var eff = AudioServer.get_bus_effect(_bus_index, i)
			if eff is AudioEffectPitchShift:
				_pitch_effect_idx = i
				_original_pitch_scale = eff.pitch_scale
				break
		if _pitch_effect_idx == -1:
			# no pitch shift effect found; warn in console
			push_warning("TimeSlowManager: no AudioEffectPitchShift found on bus '%s' (bus_index=%d). Add one if you want audio pitch scaling." % [audio_bus_name, _bus_index])
	else:
		_pitch_effect_idx = -1

	# Ensure engine timescale starts at 1.0 (do not clobber project defaults)
	Engine.time_scale = Engine.time_scale if Engine.time_scale > 0 else 1.0

	# Optionally listen for a global input action (toggle)
	# If you plan to put TimeSlowManager as Autoload, it will still receive _input calls.
	set_process_input(true)


func _input(event: InputEvent) -> void:
	# toggle on action press
	if event.is_action_pressed("time_slow"):
		if _active:
			end_time_slow()
		else:
			start_time_slow(slow_duration, slow_scale)


func is_active() -> bool:
	return _active


func start_time_slow(duration: float = -1.0, scale: float = -1.0, pitch_scale: float = -1.0) -> void:
	# duration: seconds to auto-end (use slow_duration if <=0)
	# scale: engine time_scale target (use slow_scale if <=0)
	# pitch_scale: audio pitch target (if <=0, computed from scale * multiplier)
	var target_scale := scale if scale > 0.0 else slow_scale
	var dur := duration if duration > 0.0 else slow_duration
	var target_pitch := pitch_scale if pitch_scale > 0.0 else (target_scale * pitch_factor_multiplier)

	# if already active, refresh timer and re-tween to new values
	if _active:
		if _auto_timer.is_stopped() == false:
			_auto_timer.stop()
		_auto_timer.wait_time = dur
		_auto_timer.start()
		# re-tween to the new target quickly
		_start_tween(target_scale, target_pitch)
		emit_signal("time_slow_started", target_scale, dur)
		return

	_active = true
	emit_signal("time_slow_started", target_scale, dur)

	# auto-end timer
	_auto_timer.wait_time = dur
	_auto_timer.start()

	# start tweening
	_start_tween(target_scale, target_pitch)


func end_time_slow() -> void:
	if not _active:
		return

	_active = false
	if _auto_timer and _auto_timer.is_stopped() == false:
		_auto_timer.stop()

	# tween back to 1.0 and reset audio pitch
	_start_tween(1.0, 1.0)
	emit_signal("time_slow_ended")


func _start_tween(target_scale: float, target_pitch: float) -> void:
	# kill existing tween
	if _tween:
		_tween.kill()
		_tween = null

	# create tween for Engine.time_scale
	_tween = get_tree().create_tween()
	_tween.tween_property(Engine, "time_scale", target_scale, transition_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	# audio pitch: use callable bind to pass argument
	if _pitch_effect_idx != -1 and use_audio_pitch:
		var cb := Callable(self, "_apply_pitch").bind(target_pitch)
		_tween.tween_callback(cb)

	# ensure final cleanup when tween finishes (only needed when returning to 1)
	_tween.connect("finished", Callable(self, "_on_tween_finished"))


func _apply_pitch(value: float) -> void:
	if _bus_index == -1 or _pitch_effect_idx == -1:
		return
	var eff = AudioServer.get_bus_effect(_bus_index, _pitch_effect_idx)
	if eff is AudioEffectPitchShift:
		eff.pitch_scale = value


func _on_tween_finished() -> void:
	# If we ended back at 1.0, ensure audio pitch reset
	if Engine.time_scale >= 0.999:
		# restore original pitch if we stored it earlier
		if _pitch_effect_idx != -1:
			var eff = AudioServer.get_bus_effect(_bus_index, _pitch_effect_idx)
			if eff is AudioEffectPitchShift:
				eff.pitch_scale = _original_pitch_scale


func _on_auto_timeout() -> void:
	end_time_slow()
