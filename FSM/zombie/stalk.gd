extends State
class_name StalkState

@onready var animation_player: AnimationPlayer = $"../../AnimationPlayer"
@onready var scream: AudioStreamPlayer3D = $"../../Scream"

@export var speed: float = 2.0  # Slightly faster than wander
@export var attack_distance: float = 2.0
@export var update_path_interval: float = 0.5

var path_timer: float = 0.0
var has_screamed: bool = false

func Enter():
	# Check if player has a mirror first
	if zombie.player_has_mirror:
		Transitioned.emit(self, "Teleport")
		return
		
	# Play appropriate animation
	if animation_player.has_animation("run/run"):
		animation_player.play("run/run")  # Use run animation if available
	elif animation_player.has_animation("walk/walk"):
		animation_player.play("walk/walk", 1.2)  # Speed up walk animation slightly
	else:
		push_error("No appropriate stalking animation found")
	
	# Set initial path to player
	update_path()
	
	# Play scream when starting to stalk
	if scream and !has_screamed:
		scream.play()
		has_screamed = true
	
func Exit():
	zombie.last_direction = zombie.velocity.normalized()
	
func Update(delta: float):
	# Check if player has a mirror first
	if zombie.player_has_mirror:
		Transitioned.emit(self, "Teleport")
		return
			
	var enemy_pos = player.get_enemy_pos(zombie)
	
	# Update path to player periodically
	path_timer -= delta
	if path_timer <= 0:
		update_path()
		path_timer = update_path_interval
	
	# State transition logic
	if zombie.is_player_in_range:
		if enemy_pos == "Front" and !player.glass_breaking:
			Transitioned.emit(self, "Stunned")
	else:
		Transitioned.emit(self, "Wander")
	
	# Check if close enough to attack (if you have an attack state)
	var distance_to_player = zombie.global_transform.origin.distance_to(player.global_transform.origin)
	if distance_to_player < attack_distance:
		Transitioned.emit(self, "Attack")
	
func Physics_Update(delta: float):
	var current_location = zombie.global_transform.origin
	var next_location = nav_agent.get_next_path_position()
	var direction = (next_location - current_location).normalized()
	
	# Set the velocity based on the direction and speed
	zombie.velocity = direction * speed
	
	# Make zombie face the direction it's moving
	FSM.face_movement_direction(zombie, zombie.velocity, delta, 7.0)  # Faster turning when stalking
	
	# Update navigation agent
	nav_agent.set_velocity(zombie.velocity)

func update_path():
	if player and nav_agent:
		nav_agent.set_target_position(player.global_transform.origin)
