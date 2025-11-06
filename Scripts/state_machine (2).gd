extends StateMachine

@export var min_state_duration: float = 0.5  # seconds
var state_timer: float = 0.0

func _physics_process(delta: float) -> void:
	state_timer += delta
	if state:
		state.physics_update(delta)

func transition_to(target_state_name: String, msg: Dictionary = {}) -> void:
	# Prevent rapid transitions
	if state_timer < min_state_duration:
		return
	if not has_node(target_state_name):
		return

	if state:
		state.exit()
	state = get_node(target_state_name)
	if state:
		state.enter(msg)
		state_timer = 0.0
		emit_signal("transitioned", state.name)
