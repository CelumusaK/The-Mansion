extends State
class_name StalkState

var SPEED: float = 1.0

func Enter():
	print("Enter Stalk")
	nav_agent.set_target_position( player.global_transform.origin)
	
func Exit():
	print("Exit Stalk")
	
func Update(delta: float):
	var enemy_pos = player.get_enemy_pos(zombie)
	if enemy_pos == "Front":
		Transitioned.emit(self, "Stunned")
		
	if !zombie.is_player_in_range:
		Transitioned.emit(self, "Wander")
		
	var distance_to_target = zombie.global_transform.origin.distance_to( player.global_transform.origin)
	if distance_to_target < 10 or zombie.velocity == Vector3.ZERO:
		pass
	
func Physics_Update(delta: float):
	var current_location = zombie.global_transform.origin
	var next_location = nav_agent.get_next_path_position()
	var new_velocity = (next_location - current_location) * SPEED
	
	nav_agent.set_velocity(new_velocity)
