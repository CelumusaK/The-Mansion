class_name Player extends CharacterBody3D

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

@export_group("Controls map names")
@export var MOVE_FORWARD: String = "forward"
@export var MOVE_BACK: String = "back"
@export var MOVE_LEFT: String = "left"
@export var MOVE_RIGHT: String = "right"
@export var JUMP: String = "jump"
@export var CROUCH: String = "crouch"
@export var SPRINT: String = "sprint"
@export var PAUSE: String = "pause"

@export_group("Customizable player stats")
@export var walk_back_speed: float = 1.5
@export var walk_speed: float = 2.5
@export var sprint_speed: float = 5.0
@export var crouch_speed: float = 1.5
@export var jump_height: float = 1.0
@export var acceleration: float = 10.0
@export var arm_length: float = 0.5
@export var regular_climb_speed: float = 6.0
@export var fast_climb_speed: float = 8.0
@export_range(0.0, 1.0) var view_bobbing_amount: float = 1.0
@export_range(1.0, 10.0) var camera_sensitivity: float = 2.0
@export_range(0.0, 0.5) var camera_start_deadzone: float = .2
@export_range(0.0, 0.5) var camera_end_deadzone: float = .1

@export_group("Feature toggles")
@export var allow_jump: bool = true
@export var allow_crouch: bool = true
@export var allow_sprint: bool = true
@export var allow_climb: bool = true

# Player 'character' components
@onready var camera_pivot: Node3D = %CameraPivot
@onready var state_machine: PlayerStateMachine = %StateMachine
@onready var animation_player: AnimationPlayer = %AnimationPlayer
@onready var view_bobbing_player = %ViewBobbingPlayer

# Raycasts used for detecting if the player is touching a wall
@onready var bottom_raycast: RayCast3D = %BottomRaycast
@onready var middle_raycast: RayCast3D = %MiddleRaycast
@onready var top_raycast: RayCast3D = %TopRaycast

# Raycasts used for getting the ledge position and checking if there's enough space
@onready var surface_raycasts_root: Node3D = %SurfaceRaycasts
@onready var projected_height_raycast: RayCast3D = %ProjectedHeightRaycast
@onready var surface_raycast: RayCast3D = %SurfaceRaycast

# Raycasts used for checking if there's enough horizontal space to climb
@onready var left_climbable_raycast: RayCast3D = %LeftClimbableRaycast
@onready var right_climbable_raycast: RayCast3D = %RightClimbableRaycast

# Raycast for detecting ceiling
@onready var crouch_raycast = %CrouchRaycast
@onready var pick_up: RayCast3D = $CameraPivot/SmoothCamera/PickUp
@onready var right_hand: Node3D = $CameraPivot/SmoothCamera/RightHand
@onready var left_hand: Node3D = $CameraPivot/SmoothCamera/LeftHand

@onready var label: Label = $UserInterface/CrosshairContainer/Label
@onready var victory: CenterContainer = $UserInterface/Victory
@onready var anim_victory: AnimationPlayer = $UserInterface/Victory/AnimVictory
@onready var _damage: AudioStreamPlayer3D = $Damage

var pick_up_item
var fov_angle = 90.0  # Field of view in degrees
var view_distance = 50.0  # How far the player can see

# Dynamic values used for calculation
var input_direction: Vector2
var ledge_position: Vector3 = Vector3.ZERO
var mouse_motion: Vector2
var default_view_bobbing_amount: float
var movement_strength: float

# Player state values that are set by applying state
var climb_speed: float = fast_climb_speed
var is_crouched: bool = false
var can_climb: bool
var can_climb_timer: Timer
var is_affected_by_gravity: bool = true
var is_moving: bool = false

# Values that are set 'false' if corresponding controls aren't mapped
var can_move: bool = true
var can_jump: bool = true
var can_crouch: bool = true
var can_sprint: bool = true
var can_pause: bool = true
var is_sprinting: bool = false

const HAND_MIRROR = preload("res://game/scenes/items/mirror/game_mirror1.tscn")
const TORCH = preload("res://game/scenes/items/torch/torch.tscn")
@onready var health_bar: ProgressBar = $UserInterface/HealthBar
@onready var color_rect: ColorRect = $UserInterface/ColorRect
@onready var stamina: ProgressBar = $UserInterface/Stamina

var player_torch: RayCast3D
var glass_breaking: bool = false
var time: float = 0.0

func _ready() -> void:
	stamina.value = stamina.max_value
	health_bar.value = health_bar.max_value
	default_view_bobbing_amount = view_bobbing_amount
	victory.visible = false
	if can_pause:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion or event is InputEventScreenDrag:
		mouse_motion = -event.relative * 0.001
	
	if can_pause:
		if event.is_action_pressed(PAUSE):
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _physics_process(delta: float) -> void:
	if can_move:
		if Input.get_vector(MOVE_LEFT, MOVE_RIGHT, MOVE_FORWARD, MOVE_BACK):
			input_direction = Input.get_vector(MOVE_LEFT, MOVE_RIGHT, MOVE_FORWARD, MOVE_BACK)
		else:
			input_direction = Vector2.ZERO
	
	# Add the gravity.
	if not is_on_floor() && is_affected_by_gravity:
		velocity.y -= gravity * delta
	
	# Resetting climb ability when on ground
	if is_on_floor() && !can_climb:
		if can_climb_timer != null:
			can_climb_timer.queue_free()
		can_climb = true
	
	move_and_slide()


func _process(_delta: float):
	if health_bar.value <= 0:
		get_tree().reload_current_scene()
	
	if !is_sprinting:
		stamina.value += 1
		
	if color_rect.visible:
		time += _delta
		if time > 0.5:
			color_rect.visible = false
			time = 0.0
			
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		# Handling camera in '_process' so that camera movement is framerate independent
		_handle_camera_motion()
		
	if right_hand.get_child_count() > 0:
		var item = right_hand.get_child(0)
		if item is Torch:
			glass_breaking = item.is_glass_breaking
				
			if item.is_game_won == true:
				set_physics_process(false)
				if !victory.visible:
					anim_victory.play("won")
				victory.visible = true
				

	if left_hand.get_child_count() > 0:
		var item = left_hand.get_child(0)  # <- FIXED
		if item is Torch:
			glass_breaking = item.is_glass_breaking
				
			if item.is_game_won == true:
				set_physics_process(false)
				if !victory.visible:
					
					anim_victory.play("won")
				victory.visible = true
		
	if pick_up.is_colliding():
		if pick_up.get_collider() is HandMirror:
			pick_up_item = HAND_MIRROR
			label.visible = true
		elif pick_up.get_collider() is Torch:
			pick_up_item = TORCH
			label.visible = true
	else:
		label.visible = false
	
	if Input.is_action_just_pressed("pick_right"):
		if right_hand.get_child_count() > 0:
			for child in right_hand.get_children():
				# Remove from hand but don't destroy
				right_hand.remove_child(child)

				# Add to world
				get_tree().get_root().add_child(child)

				# Set position to hand's global position
				child.global_position = right_hand.global_position

				# Add physics if the item has a physics body
				if child.has_method("apply_impulse"):
					# Apply random force to make it "fly off"
					var random_direction = Vector3(
						randf_range(-1, 1),
						randf_range(0.5, 1.5),  # Mostly upward
						randf_range(-1, 1)
					).normalized()

					var force = random_direction * 5.0  # Adjust force as needed
					child.apply_impulse(Vector3.ZERO, force)
				
		if pick_up_item != null:
			get_parent().remove_child(pick_up.get_collider())
			var item = pick_up_item.instantiate()
			right_hand.add_child(item) 
		
	if Input.is_action_just_pressed("pick_left"):
		if left_hand.get_child_count() > 0:
			for child in left_hand.get_children():
				# Remove from hand but don't destroy
				left_hand.remove_child(child)

				# Add to world
				get_tree().get_root().add_child(child)

				# Set position to hand's global position
				child.global_position = left_hand.global_position

				# Add physics if the item has a physics body
				if child.has_method("apply_impulse"):
					# Apply random force to make it "fly off"
					var random_direction = Vector3(
						randf_range(-1, 1),
						randf_range(0.5, 1.5),  # Mostly upward
						randf_range(-1, 1)
					).normalized()

					var force = random_direction * 5.0  # Adjust force as needed
					child.apply_impulse(Vector3.ZERO, force)
				
		if pick_up_item != null:
			get_parent().remove_child(pick_up.get_collider())
			var item = pick_up_item.instantiate()
			left_hand.add_child(item)
			
func get_enemy_pos(zombie) -> String:
	var direction_to_zombie = (zombie.global_position - global_position).normalized()
	var player_forward = -global_transform.basis.z
	var dot_product = direction_to_zombie.dot(player_forward)
	
	if dot_product > 0.5:
		return "Front"
	elif dot_product < -0.5:
		return "Back"
	else:
		return "Side"

func check_right_hand() -> bool:
	if right_hand.get_child_count() > 0:
		var item = right_hand.get_child(0)
		if item is HandMirror or item is Torch:
			return true
	return false
	
func check_left_hand() -> bool:
	if left_hand.get_child_count() > 0:
		var item = left_hand.get_child(0)
		if item is HandMirror or item is Torch:
			return true
	return false
	
	
func check_hands() -> bool:
	if check_left_hand() and check_right_hand():
		return true
	return false

func take_damage(damage):
	_damage.play()
	animation_player.play("damage")
	color_rect.visible = true
	health_bar.value -= damage
	health_bar.value = health_bar.value
	shake_camera()

func shake_camera():
	var camera = get_tree().get_first_node_in_group("PlayerCamera")  # Ensure camera is in "PlayerCamera" group
	if not camera:
		return

	var tween = get_tree().create_tween()
	var original_position = camera.transform.origin

	# Increase intensity and randomness
	for _i in range(8):  # More shakes
		var random_offset = Vector3(randf_range(-0.3, 0.3), randf_range(-0.3, 0.3), randf_range(-0.2, 0.2))
		tween.tween_property(camera, "transform:origin", original_position + random_offset, 0.03)  # Faster shakes

	# Smoothly reset position
	tween.tween_property(camera, "transform:origin", original_position, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _handle_camera_motion() -> void:
	rotate_y(mouse_motion.x * camera_sensitivity)
	camera_pivot.rotate_x(mouse_motion.y  * camera_sensitivity)
	
	camera_pivot.rotation_degrees.x = clampf(
		camera_pivot.rotation_degrees.x , -89.0, 89.0
	)
	
	mouse_motion = Vector2.ZERO


func check_climbable() -> bool:
	if crouch_raycast.is_colliding():
		return false
	
	if not bottom_raycast.is_colliding() && not middle_raycast.is_colliding() && not top_raycast.is_colliding():
		return false
	
	var climb_point = surface_raycast.get_collision_point()
	var climb_height = climb_point.y - global_position.y
	
	left_climbable_raycast.global_position.y = climb_point.y + 0.1
	right_climbable_raycast.global_position.y = climb_point.y + 0.1
	
	if left_climbable_raycast.is_colliding() || right_climbable_raycast.is_colliding():
		return false
	
	projected_height_raycast.target_position = Vector3(0, climb_height - 0.1, 0)
	
	if projected_height_raycast.is_colliding():
		return false
	
	ledge_position = climb_point
	return true


func check_small_ledge() -> bool:
	return bottom_raycast.is_colliding() && not middle_raycast.is_colliding() && not top_raycast.is_colliding()


func set_climb_speed(is_small_ledge) -> void:
	if is_small_ledge:
		climb_speed = fast_climb_speed
	else:
		climb_speed = regular_climb_speed


func toggle_crouch() -> void:
	is_crouched = !is_crouched
	
	if is_crouched:
		animation_player.play("crouch")
	else:
		animation_player.play_backwards("crouch")


func setup_can_climb_timer(callback: Callable = _on_grab_available_timeout) -> void:
	if can_climb_timer != null:
		return
	
	can_climb = false
	
	can_climb_timer = Timer.new()
	add_child(can_climb_timer)
	can_climb_timer.wait_time = 1.0
	can_climb_timer.one_shot = true
	can_climb_timer.connect("timeout", callback)
	can_climb_timer.start()


func _on_grab_available_timeout() -> void:
	can_climb = true
	
	if can_climb_timer != null:
		can_climb_timer.queue_free()


## Triggers on every state transition. Could be useful for side effects and debugging
## Note that it's triggered after the 'state' "enter" method
func _on_state_machine_transitioned(state: PlayerState) -> void:
	is_moving = state is Walk || state is Sprint
	
	if is_moving:
		view_bobbing_player.play("view_bobbing", .5, view_bobbing_amount, false)
	else:
		view_bobbing_player.play("RESET", .5)


func _add_input_map_event(action_name: String, keycode: int) -> void:
	var event = InputEventKey.new()
	event.keycode = keycode
	InputMap.add_action(action_name)
	InputMap.action_add_event(action_name, event)


func _on_restart_pressed() -> void:
	get_tree().reload_current_scene()

func _on_quit_pressed() -> void:
	get_tree().quit()


func _on_retry_pressed() -> void:
	get_tree().reload_current_scene()
