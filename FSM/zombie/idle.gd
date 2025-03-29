extends State
class_name IdleState

@onready var scream: AudioStreamPlayer3D = $"../../Scream"
@onready var groul: AudioStreamPlayer3D = $"../../Groul"

@export var play_chance: float = 0.5

var time: float = 0.0

func Enter():
	print("Enter Idle")
	time = randi_range(2, 5)
	var random_value = randf_range(0.0, 1.0 )
	if random_value < play_chance:
		if !groul.playing:
			groul.playing = true
	
func Exit():
	print("E Idle")
	
func Update(delta: float):
	var enemy_pos = player.get_enemy_pos(zombie)
	if enemy_pos == "Front":
		Transitioned.emit(self, "Stunned")
		
	time -= delta
	if time <= 0:
		Transitioned.emit(self, "Wander")
		
	if zombie.is_player_in_range:
		Transitioned.emit(self, "Stalk")
	
func Physics_Update(delta: float):
	zombie.velocity = Vector3.ZERO
