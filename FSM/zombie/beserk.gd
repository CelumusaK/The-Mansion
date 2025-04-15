extends State
class_name BerserkState

@export var berserk_duration: float = 20.0
@export var speed: float = 2.5  # Very fast
@export var teleport_interval: float = 5.0
@export var attack_distance: float = 3.0  # Increased attack range

var berserk_timer: float = 0.0
var teleport_timer: float = 0.0

func Enter():
	# Check if player has a mirror
	if zombie.player_has_mirror:
		Transitioned.emit(self, "Teleport")
		return
	
	# Set timers
	berserk_timer = berserk_duration
	teleport_timer = teleport_interval

	# Update path to player
	update_path()
	
func Exit():
	print("Exit Berserk")
	# Reset stun count after berserk period
	zombie.reset_stun_count()
	
func Update(delta: float):
	# Check if player has a mirror
	if zombie.player_has_mirror:
		Transitioned.emit(self, "Teleport")
		return
	
	# Update timers
	berserk_timer -= delta
	teleport_timer -= delta

	# Teleport periodically
	if teleport_timer <= 0 && zombie.can_teleport:
		Transitioned.emit(self, "Teleport")
		teleport_timer = teleport_interval
		return
	
	# Update path to player periodically
	if fmod(berserk_timer, 0.5) < delta:
		update_path()
	
	# Check if berserk time is over
	if berserk_timer <= 0:
		Transitioned.emit(self, "Wander")
		return

	# Check if close enough to attack
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
	FSM.face_movement_direction(zombie, zombie.velocity, delta, 10.0)  # Very fast turning in berserk

	# Update navigation agent
	nav_agent.set_velocity(zombie.velocity)

func update_path():
	if player and nav_agent:
		nav_agent.set_target_position(player.global_transform.origin)
