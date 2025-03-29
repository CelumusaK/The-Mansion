extends Node
class_name FSM

@export var initial_state : State

@export var nav_agent: NavigationAgent3D
@export var zombie: CharacterBody3D

var current_state : State
var states : Dictionary = {}
var state_to_follow: String

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
