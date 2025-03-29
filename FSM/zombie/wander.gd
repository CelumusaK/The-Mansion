extends State
class_name WanderState

@onready var scream: AudioStreamPlayer3D = $"../../Scream"
@onready var groul: AudioStreamPlayer3D = $"../../Groul"


@export var min_distance: float = 5.0
@export var max_distance: float = 20.0
@export var play_chance: float = 0.5

var SPEED: float = 1.0

func Enter():
	print("Enter Wanter")
	set_random_pos()
	var random_value = randf_range(0.0, 1.0 )
	if random_value < play_chance:
		if !groul.playing:
			groul.playing = true
	
func Exit():
	print("Exit Wander")
	
func Update(delta: float):
	var enemy_pos = player.get_enemy_pos(zombie)
	if enemy_pos == "Front":
		Transitioned.emit(self, "Stunned")
		
	if nav_agent.target_reached:
		Transitioned.emit(self, "Idle") 
	
func Physics_Update(delta: float):
	var current_location = zombie.global_transform.origin
	var next_location = nav_agent.get_next_path_position()
	var new_velocity = (next_location - current_location) * SPEED
	
	nav_agent.set_velocity(new_velocity)
	
func set_random_pos():
	var current_position = zombie.global_transform.origin
	
	# Generate random direction
	var random_direction = Vector3(
		randf_range(-1.0, 1.0),
		0.0, # Keep it on the same Y level
		randf_range(-1.0, 1.0)
	).normalized()
	
	var random_distance = randf_range(min_distance, max_distance)
	var target_position = current_position + (random_direction * random_distance)
	
	if zombie != null  and nav_agent != null:
		var map = get_tree().get_first_node_in_group("NavigationMap")
		var closest_point = NavigationServer3D.map_get_closest_point(map.get_navigation_map(), target_position)
		nav_agent.set_target_position( closest_point)
	
