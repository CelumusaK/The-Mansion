extends CharacterBody3D

@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var scream: AudioStreamPlayer3D = $Scream
@onready var groul: AudioStreamPlayer3D = $Groul

@export var map: NavigationRegion3D
@export var player: CharacterBody3D

var SPEED: float = 1.0

var is_player_in_range: bool = false
var is_danger: bool = false

func update_target_location(target_location):
	nav_agent.set_target_position(target_location)


func _on_navigation_agent_3d_velocity_computed(safe_velocity: Vector3) -> void:
	velocity = velocity.move_toward(safe_velocity, .25)
	move_and_slide()


func _on_detection_area_body_entered(body: Node3D) -> void:
	is_player_in_range = true
	if body.check_hands():
		is_danger = true
	else:
		is_danger = false


func _on_detection_area_body_exited(body: Node3D) -> void:
	is_player_in_range = false
