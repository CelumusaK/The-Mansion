extends RigidBody3D
class_name Torch

@onready var glass_breaking: AudioStreamPlayer3D = $GlassBreaking
@onready var light_ray: AudioStreamPlayer3D = $LightRay
@onready var time: Label = %time
@export var light: RayCast3D
@export var light_node: Light3D  # Reference to the actual light node

var elapsed_time: float = 0.0
var time_to_win: float = 10.0
var is_game_won: bool = false
var is_glass_breaking: bool = false

# Flickering light variables
var light_on_time: float = 0.0
var time_before_flicker: float = 15.0  # Light stays on for 15 seconds before flickering
var is_flickering: bool = false
var flicker_duration: float = 2.0  # How long the flickering lasts
var flicker_timer: float = 0.0
var off_duration: float = 0.5  # How long the light stays off
var off_timer: float = 0.0
var is_off: bool = false

func _process(delta: float) -> void:
	# Game win condition
	if elapsed_time >= time_to_win:
		is_game_won = true
		time.visible = false
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		return
	
	# Handle light ray collision and game timer
	if light.is_colliding():
		time.visible = true
		elapsed_time += delta
		time.text = str(int(elapsed_time))
		is_glass_breaking = true
		
		if !glass_breaking.playing and !light_ray.playing:
			glass_breaking.playing = true
			light_ray.playing = true
		
		# Handle light flickering effect
		handle_light_effect(delta)
	else:
		if elapsed_time > 0:
			time.visible = true
			elapsed_time -= delta
			time.text = str(int(elapsed_time))
		else:
			time.visible = false
			is_game_won = false
		
		glass_breaking.playing = false
		light_ray.playing = false
		is_glass_breaking = false
		
		# Reset light effect timers when not colliding
		reset_light_effect()

func handle_light_effect(delta: float) -> void:
	if !is_flickering and !is_off:
		# Count time with light on
		light_on_time += delta
		
		# Start flickering after the specified time
		if light_on_time >= time_before_flicker:
			is_flickering = true
			flicker_timer = 0.0
			light_on_time = 0.0
	
	if is_flickering:
		flicker_timer += delta
		
		# Rapid flickering effect (toggle every 0.1 seconds)
		if int(flicker_timer * 10) % 2 == 0:
			light_node.visible = true
		else:
			light_node.visible = false
		
		# End flickering and turn off after flicker duration
		if flicker_timer >= flicker_duration:
			is_flickering = false
			is_off = true
			off_timer = 0.0
			light_node.visible = false
	
	if is_off:
		off_timer += delta
		
		# Turn light back on after off duration
		if off_timer >= off_duration:
			is_off = false
			light_node.visible = true

func reset_light_effect() -> void:
	light_on_time = 0.0
	is_flickering = false
	is_off = false
	light_node.visible = true
