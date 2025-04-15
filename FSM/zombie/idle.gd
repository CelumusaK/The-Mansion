extends State
class_name IdleState

@onready var scream: AudioStreamPlayer3D = $"../../Scream"
@onready var growl: AudioStreamPlayer3D = $"../../Groul"
@onready var animation_player: AnimationPlayer = $"../../AnimationPlayer"

@export var play_chance: float = 0.5
@export var idle_time_min: float = 2.0
@export var idle_time_max: float = 5.0

var time: float = 0.0

func Enter():
	animation_player.play("idle/idle")
	
	# Set random idle time
	time = randf_range(idle_time_min, idle_time_max)
	
	# Play growl with chance
	var random_value = randf()
	if random_value < play_chance and growl and !growl.playing:
		growl.play()
	
func Exit():
	print("E Idle")
	
func Update(delta: float):
	if player.glass_breaking and !zombie.is_player_in_range:
		Transitioned.emit(self, "Teleport")
	# Check for player position relative to zombie
	var enemy_pos = player.get_enemy_pos(zombie)
	
	# State transition logic
	if zombie.is_player_in_range:
		if enemy_pos == "Front" and !player.glass_breaking:
			Transitioned.emit(self, "Stunned")
		else:
			Transitioned.emit(self, "Stalk")
			
	# Time-based transition
	time -= delta
	if time <= 0:
		Transitioned.emit(self, "Wander")
	
func Physics_Update(delta: float):
	zombie.velocity = Vector3.ZERO
