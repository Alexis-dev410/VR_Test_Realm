class_name EnemyStateMachine
extends StateMachine

@export var min_state_duration: float = 0.5  # seconds
var state_timer: float = 0.0

func _ready() -> void:
	# If the parent/base StateMachine didn't set an initial state, pick the first valid State child.
	# This avoids calling methods on `state` when it's still null.
	if not state:
		for child in get_children():
			# we consider a "State" any node that implements enter() and physics_update()
			if child and child.has_method("enter") and child.has_method("physics_update"):
				state = child
				state.enter()
				print("✅ EnemyStateMachine: auto-initialized state to:", state.name)
				break

func _physics_process(delta: float) -> void:
	state_timer += delta
	if state:
		# guard in case state gets freed or set to null mid-frame
		state.physics_update(delta)

# Safe unhandled input delegation: only call if state exists and implements handle_input
func _unhandled_input(event: InputEvent) -> void:
	if state and state.has_method("handle_input"):
		state.handle_input(event)

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
