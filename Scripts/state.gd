@abstract
class_name State
extends Node

# Abstract class

var state_machine: StateMachine = null

# Virtual methods
func handle_input(_event: InputEvent):
	pass
	
func update(_delta: float) -> void:
	pass
	
func physics_update(_delta: float) -> void:
	pass
	
func enter(_msg := {}) -> void:
	pass
	
func exit() -> void:
	pass
