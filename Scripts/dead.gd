extends State

var enemy: CharacterBody3D
var anim_player: AnimationPlayer
var time_manager
@onready var anim: AnimationPlayer = $"../../AnimationPlayer"

func _ready() -> void:
	time_manager = get_tree().get_first_node_in_group("TimeSlowManager")

func enter(_msg := {}) -> void:
	# --- Safe state_machine assignment ---
	if not state_machine:
		var p = get_parent()
		if p is StateMachine:
			state_machine = p
		else:
			for i in range(4):
				p = p.get_parent()
				if p is StateMachine:
					state_machine = p
					break

	if not state_machine:
		print("❌ Dead: state_machine is NULL!")
		return
	# -------------------------------------

	enemy = $"../.."
	enemy.velocity = Vector3.ZERO

	anim_player = enemy.anim

	if anim_player and anim_player.has_animation("Death01"):
		anim_player.play("Death01")
		anim_player.animation_finished.connect(_on_anim_finished, CONNECT_ONE_SHOT)
	else:
		enemy.queue_free()

func physics_update(_delta: float) -> void:
	# Update animation speed every frame
	update_anim_speed()

func update_anim_speed():
	if not anim_player:
		return
	var slow_scale: float = 1.0
	if time_manager and time_manager.is_active():
		slow_scale = float(time_manager.get_scale())
	anim_player.speed_scale = slow_scale

func _on_anim_finished(anim_name: String) -> void:
	if anim_name == "Death01":
		enemy.queue_free()
