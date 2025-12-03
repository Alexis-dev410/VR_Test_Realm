extends State

@onready var anim: AnimationPlayer = $"../../AnimationPlayer"

var enemy

func enter(_msg := {}) -> void:
	# ensure state_machine is valid
	if not state_machine:
		var p = get_parent()
		# walk up parents until we find the state machine
		for i in range(4):
			if p is StateMachine:
				state_machine = p
				break
			p = p.get_parent()

	# NOW we can safely assign enemy
	enemy = $"../.."

	if not enemy:
		print("❌ Reload: enemy is NULL!")
		return

	anim.play("Pistol_Reload")

	# --- SAFE RELOAD SFX ---
	var gun = enemy.gun_instance
	if gun:
		var reload_player = gun.get_node_or_null("Reload")
		if reload_player:
			reload_player.play()
		else:
			print("⚠️ Reload SFX missing on gun")
	else:
		print("⚠️ enemy.gun_instance is NULL")


func physics_update(delta: float) -> void:
	# Transition back ONLY after animation finishes
	if not anim.is_playing():
		print("🔋 Reload complete — ammo reset")
		enemy.ammo = enemy.max_ammo  # refill ammo

		state_machine.transition_to("Idle")
