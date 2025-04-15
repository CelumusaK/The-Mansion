extends State
class_name TeleportState

@export var chase_speed: float = 100.0  # High speed movement towards player
@export var update_path_interval: float = 0.2  # How often to update the path

var path_timer: float = 0.0

func Enter():
	print("Enter Chase Mode")
	update_path()  # Set initial path to player

func Exit():
	print("Exit Chase Mode")

func Update(delta: float):
	# Periodically update path to player
	path_timer -= delta
	if path_timer <= 0:
		update_path()
		path_timer = update_path_interval
	
	# Transition logic
	if zombie.is_player_in_range:
		Transitioned.emit(self, "Attack")

func Physics_Update(delta: float):
	var current_location = zombie.global_transform.origin
	var next_location = nav_agent.get_next_path_position()
	var direction = (next_location - current_location).normalized()
	
	# Move towards the player at high speed
	zombie.velocity = direction * chase_speed
	
	# Face movement direction
	FSM.face_movement_direction(zombie, zombie.velocity, delta, 10.0)
	
	# Update navigation agent
	nav_agent.set_velocity(zombie.velocity)

func update_path():
	if player and nav_agent:
		nav_agent.set_target_position(player.global_transform.origin)
