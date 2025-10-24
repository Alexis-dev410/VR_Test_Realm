extends Node3D

@onready var npc = $NPC
@onready var target = $Target

func _ready():
	await ready
	if npc and target:
		npc.set_target(target)
