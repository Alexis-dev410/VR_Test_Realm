extends Node3D

# Connected to Area3D -> body_entered
func _on_area_3d_body_entered(body: Node3D) -> void:
	print("Area entered by:", body.name, " | class:", body.get_class())

	var target = _find_target_with_method(body)
	if target:
		# Prefer the public wrapper if present
		if target.has_method("choose_new_direction"):
			target.call_deferred("choose_new_direction")
			print("Called choose_new_direction on:", target.name)
		else:
			target.call_deferred("_choose_new_direction")
			print("Called _choose_new_direction on:", target.name)
	else:
		print("No ancestor with choose_new_direction/_choose_new_direction found.")

# Walks up the node tree to find a node that exposes the desired method
func _find_target_with_method(node: Node) -> Node:
	var cur := node
	while cur:
		if cur.has_method("choose_new_direction") or cur.has_method("_choose_new_direction"):
			return cur
		cur = cur.get_parent()
	return null
