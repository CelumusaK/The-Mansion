extends State
class_name AttackState

@onready var animation_player: AnimationPlayer = $"../../AnimationPlayer"
@onready var hit: AudioStreamPlayer3D = $"../../Hit"

@export var attack_damage: float = 15.0
@export var attack_duration: float = 2.6
@export var cooldown: float = 0.5

var attack_timer: float = 0.0
var has_damaged: bool = false
var attack_complete: bool = false

func Enter():
	hit.play()
	# Check if player has a mirror
	if zombie.player_has_mirror:
		Transitioned.emit(self, "Teleport")
		return
	
	# Play attack animation
	if animation_player.has_animation("attack/attack"):
		animation_player.play("attack/attack")
	else:
		push_error("No attack animation found")

	# Reset timers and flags
	attack_timer = 0.0
	has_damaged = false
	attack_complete = false
	
	
func Exit():
	print("Exit Attack")
	
func Update(delta: float):
	# Check if player has a mirror (in case they just got one)
	if zombie.player_has_mirror:
		Transitioned.emit(self, "Teleport")
		return

	var enemy_pos = player.get_enemy_pos(zombie)

	# Update attack timer
	attack_timer += delta
	
	# Check if we should apply damage at the right animation frame
	if !has_damaged && attack_timer >= attack_duration * 0.4:  # Apply damage 40% into animation
		apply_damage()
		has_damaged = true

	# Check if attack is finished
	if !attack_complete && attack_timer >= attack_duration:
		attack_complete = true
		attack_timer = 0.0  # Reset for cooldown
	
	# After cooldown, transition
	if attack_complete && attack_timer >= cooldown:
		if enemy_pos == "Front" && zombie.is_player_in_range:
			Transitioned.emit(self, "Stunned")
		else:
			Transitioned.emit(self, "Stalk")
	
func Physics_Update(delta: float):
	zombie.velocity = Vector3.ZERO

	# Make zombie face the player during attack
	if player:
		FSM.face_target(zombie, player.global_transform.origin, delta, 10.0)  # Fast turning when attacking

func apply_damage():
	# Find if player is in attack hitbox
	var player_in_range = false

	if zombie.attack_hitbox:
		var bodies = zombie.attack_hitbox.get_overlapping_bodies()
		for body in bodies:
			if body.is_in_group("Player"):
				zombie.deal_damage(attack_damage)
