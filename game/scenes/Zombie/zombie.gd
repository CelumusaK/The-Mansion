extends CharacterBody3D

@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var attack_hitbox: Area3D = $RightHand/Attack_Hitbox

@export var map: NavigationRegion3D
@export var player: CharacterBody3D
@export var gravity: float = 9.8
@export var rotation_speed: float = 5.0
@export var teleport_cooldown: float = 15.0

# State tracking
var is_player_in_range: bool = false
var last_direction: Vector3 = Vector3.ZERO
var SPEED: float = 1.0
var is_danger: bool = false
var stun_count: int = 0
var player_has_mirror: bool = false
var is_glass_breaking: bool = false
var is_attacking: bool = false

var teleport_timer: float = 0.0
var can_teleport: bool = true


func _ready():
	# Initialize the navigation agent
	nav_agent.avoidance_enabled = true
	nav_agent.max_neighbors = 8
	nav_agent.neighbor_distance = 50.0
	nav_agent.time_horizon = 0.5
	nav_agent.max_speed = 2.0
	
	nav_agent.velocity_computed.connect(_on_velocity_computed)

func _process(delta: float) -> void:
	# Apply gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	# Move the zombie
	move_and_slide()
	
func _is_glass_breaking(is_breaking: bool):
	is_glass_breaking = is_breaking
	
func _on_velocity_computed(safe_velocity):
	# This is called when the NavigationAgent computes a new velocity
	velocity.x = safe_velocity.x
	velocity.z = safe_velocity.z

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
	
func teleport_to(position: Vector3):
	if !can_teleport:
		return false

	# Actually teleport
	global_transform.origin = position

	# Reset teleport cooldown
	can_teleport = false
	teleport_timer = teleport_cooldown

	# Signal success
	return true

func increment_stun_count():
	stun_count += 1

func reset_stun_count():
	stun_count = 0

func update_mirror_status():
	# This should be connected to some signal from the player or inventory system
	# For now, we'll create a simplified check
	var player_node = get_tree().get_first_node_in_group("Player")
	if player_node.has_method("check_hands"):
		player_has_mirror = player_node.check_hands()
	
func deal_damage(amount: float):
	var player_node = get_tree().get_first_node_in_group("Player")
	if player_node.has_method("take_damage"):
		player_node.take_damage(amount)
