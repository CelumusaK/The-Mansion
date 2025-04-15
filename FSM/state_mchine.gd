extends Node
class_name FSM

@export var initial_state : State

@export var nav_agent: NavigationAgent3D
@export var zombie: CharacterBody3D

var current_state : State
var states : Dictionary = {}
var state_to_follow: String

# Make the zombie face its movement direction
static func face_movement_direction(zombie, velocity: Vector3, delta: float, rotation_speed: float = 5.0):
	if velocity.length() > 0.1:
		var look_direction = velocity.normalized()
		# Only rotate on the horizontal plane (y-axis)
		look_direction.y = 0
		if look_direction != Vector3.ZERO:
			# Create a rotation that points in the direction of movement
			var target_rotation = Basis.looking_at(look_direction, Vector3.UP).get_euler()
			# Smoothly rotate towards the target direction
			zombie.rotation.y = lerp_angle(zombie.rotation.y, target_rotation.y, rotation_speed * delta)

# Make the zombie face toward a specific target position
static func face_target(zombie, target_position: Vector3, delta: float, rotation_speed: float = 5.0):
	var direction = (target_position - zombie.global_transform.origin).normalized()
	direction.y = 0  # Keep on the horizontal plane

	if direction != Vector3.ZERO:
		var target_rotation = Basis.looking_at(direction, Vector3.UP).get_euler()
		zombie.rotation.y = lerp_angle(zombie.rotation.y, target_rotation.y, rotation_speed * delta)

# Find a position behind the target
static func get_position_behind_target(target, distance: float = 2.0):
	var target_transform = target.global_transform
	# Get the backward direction of the target
	var behind_dir = -target_transform.basis.z.normalized()
	# Calculate position behind the target
	return target_transform.origin + (behind_dir * distance)

# Get a random position on the navigation mesh
static func get_random_nav_position(map, current_position: Vector3, min_distance: float = 10.0, max_distance: float = 30.0):
	# Generate random direction on horizontal plane
	var random_direction = Vector3(
		randf_range(-1.0, 1.0),
		0.0,
		randf_range(-1.0, 1.0)
	).normalized()
	
	var random_distance = randf_range(min_distance, max_distance)
	var target_position = current_position + (random_direction * random_distance)

	# Get closest point on navigation mesh
	return NavigationServer3D.map_get_closest_point(map.get_navigation_map(), target_position)
	
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var player = get_tree().get_first_node_in_group("Player")
	for child in get_children():
		if child is State:
			register_state(child, "")
			child.player = player
			child.nav_agent = nav_agent
			child.zombie = zombie
			
	if initial_state:
		initial_state.Enter()
		current_state = initial_state
		
func register_state(state: Node, parent_path: String) -> void:
	var state_path = parent_path + "/" + state.name if parent_path else state.name
	states[state_path.to_lower()] = state
	state.Transitioned.connect(on_child_transition)
	
	for child in state.get_children():
		if child is State:
			register_state(child, state_path)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	
	for child in get_children():
		if child is State:
			if state_to_follow:
				child.next_state = state_to_follow
	
	if current_state:
		current_state.Update(delta)

func _physics_process(delta: float) -> void:
	if current_state:
		current_state.Physics_Update(delta)

func on_child_transition(state, new_state_name):
	if state != current_state:
		return
		
	if current_state:
		current_state.Exit()
		
	var _new_state = states.get(new_state_name.to_lower())
	if !_new_state:
		return
		
	current_state = _new_state
	if _new_state:
		current_state.Enter()
