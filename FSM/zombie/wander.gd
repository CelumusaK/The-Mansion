extends State
class_name WanderState

@onready var scream: AudioStreamPlayer3D = $"../../Scream"
@onready var growl: AudioStreamPlayer3D = $"../../Groul"
@onready var animation_player: AnimationPlayer = $"../../AnimationPlayer"


@export var min_distance: float = 5.0
@export var max_distance: float = 20.0
@export var play_chance: float = 0.5
@export var speed: float = 1.0

func Enter():
	animation_player.play("walk/walk")
	set_random_pos()
	
	# Play growl with chance
	var random_value = randf()
	if random_value < play_chance and growl and !growl.playing:
		growl.play()
	
func Exit():
	print("Exit Wander")
	
func Update(delta: float):
	if player.glass_breaking and !zombie.is_player_in_range:
		Transitioned.emit(self, "Teleport")
		
	var enemy_pos = player.get_enemy_pos(zombie)
	
	# State transition logic
	if zombie.is_player_in_range:
		if enemy_pos == "Front" and !player.glass_breaking:
			Transitioned.emit(self, "Stunned")
		else:
			Transitioned.emit(self, "Stalk")
	
	if nav_agent.is_navigation_finished():
		Transitioned.emit(self, "Idle") 
	
func Physics_Update(delta: float):
	var current_location = zombie.global_transform.origin
	var next_location = nav_agent.get_next_path_position()
	var direction = (next_location - current_location).normalized()
	
	# Set the velocity based on the direction and speed
	zombie.velocity = direction * speed
	
	# Make zombie face the direction it's moving
	FSM.face_movement_direction(zombie, zombie.velocity, delta)
	
	# Update navigation agent
	nav_agent.set_velocity(zombie.velocity)
	
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
	
	if zombie != null and nav_agent != null:
		var map = get_tree().get_first_node_in_group("NavigationMap")
		if map:
			var closest_point = NavigationServer3D.map_get_closest_point(map.get_navigation_map(), target_position)
			nav_agent.set_target_position(closest_point)
