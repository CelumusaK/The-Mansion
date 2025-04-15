extends State
class_name StunnedState

@onready var animation_player: AnimationPlayer = $"../../AnimationPlayer"

@export var stunned_duration: float = 3.0
@export var min_stuns_before_berserk: int = 5
@export var max_stuns_before_berserk: int = 9

var stun_timer: float = 0.0

var SPEED: float = 1.0

func Enter():
	animation_player.stop()
	# Stop movement
	nav_agent.set_target_position(zombie.global_transform.origin)
	zombie.velocity = Vector3.ZERO
	
	# Reset stun timer
	stun_timer = stunned_duration
	
	# Increment stun counter
	zombie.increment_stun_count()
	
func Exit():
	print("Exit Stunned")
	
func Update(delta: float):
	var enemy_pos = player.get_enemy_pos(zombie)
	
	# Decrement stun timer
	stun_timer -= delta
	
	# Check if we should go berserk
	if zombie.stun_count >= min_stuns_before_berserk && zombie.stun_count <= max_stuns_before_berserk:
		if stun_timer <= 0:
			# Time to go berserk!
			Transitioned.emit(self, "Beserk")
			return

	 # Regular state transition logic based on player position or timer
	if stun_timer <= 0:
		# Check if player has a mirror
		if zombie.player_has_mirror:
			Transitioned.emit(self, "Teleport")
		elif zombie.is_player_in_range and (enemy_pos == "Side" or enemy_pos == "Back"):
			Transitioned.emit(self, "Stalk")
		else:
			Transitioned.emit(self, "Wander")
	
func Physics_Update(delta: float):
	zombie.velocity = Vector3.ZERO
	nav_agent.set_velocity(Vector3.ZERO)
	
	# Even when stunned, the zombie should face the player
	if player:
		var direction_to_player = (player.global_transform.origin - zombie.global_transform.origin).normalized()
		direction_to_player.y = 0  # Keep on same vertical plane
		FSM.face_movement_direction(zombie, direction_to_player, delta, 1.0) 
