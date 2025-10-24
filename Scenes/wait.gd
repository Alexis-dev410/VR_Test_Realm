extends State

@export var wait_time := 2.0
@onready var timer := Timer.new()

func enter(_msg := {}) -> void:
	print("Entering Wait")
	if not timer.is_connected("timeout", Callable(self, "_on_timeout")):
		timer.timeout.connect(_on_timeout)
	add_child(timer)
	timer.start(wait_time)

func _on_timeout():
	timer.stop()
	state_machine.transition_to("Patrolling")

func exit() -> void:
	print("Exiting Wait")
	if timer.is_stopped() == false:
		timer.stop()
