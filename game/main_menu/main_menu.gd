extends Node3D

const game = preload("res://game/game.tscn")

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var color_rect: ColorRect = $TransitionScreen/ColorRect
@onready var anim_player: AnimationPlayer = $TransitionScreen/AnimationPlayer
@onready var transition_screen: CanvasLayer = $TransitionScreen

func _ready() -> void:
	animation_player.play("intro")
	color_rect.visible = false

func _on_play_pressed() -> void:
	if game != null:
		transition_screen.transition()
		await transition_screen.animation_finished
		get_tree().change_scene_to_packed(game)


func _on_controls_pressed() -> void:
	pass # Replace with function body.


func _on_exit_pressed() -> void:
	get_tree().quit()
