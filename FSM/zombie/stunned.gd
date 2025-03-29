extends State
class_name StunnedState

var SPEED: float = 1.0

func Enter():
	print("Enter Stunned")
	nav_agent.set_target_position(zombie.global_transform.origin)  # Stop movement
	zombie.velocity = Vector3.ZERO  # Explicitly set velocity to zero
	
func Exit():
	print("Exit Stunned")
	
func Update(delta: float):
	var enemy_pos = player.get_enemy_pos(zombie)
	if enemy_pos == "Side" or enemy_pos == "Back" and zombie.is_player_in_range:
		Transitioned.emit(self, "Stalk")
		
	if enemy_pos == "Side" or enemy_pos == "Back":
		Transitioned.emit(self, "wander")
	
func Physics_Update(delta: float):
	zombie.velocity = Vector3.ZERO
	nav_agent.set_velocity(Vector3.ZERO)
