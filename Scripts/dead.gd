extends State

var enemy: CharacterBody3D
var anim_player: AnimationPlayer

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

func _on_anim_finished(anim_name: String) -> void:
	if anim_name == "Death01":
		enemy.queue_free()
