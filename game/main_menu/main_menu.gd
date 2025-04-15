extends Node3D

const game = preload("res://game/game.tscn")

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var color_rect: ColorRect = $TransitionScreen/ColorRect
@onready var anim_player: AnimationPlayer = $TransitionScreen/AnimationPlayer
@onready var transition_screen: CanvasLayer = $TransitionScreen
@onready var main_music: AudioStreamPlayer3D = $MainMusic
@onready var scroll_container: ScrollContainer = $UI/ScrollContainer
@onready var panel_container: ScrollContainer = $UI/PanelContainer

func _ready() -> void:
	animation_player.play("intro")
	animation_player.play("words")
	color_rect.visible = false
	main_music.play()

func _on_play_pressed() -> void:
	if game != null:
		main_music.volume_db = -10
		transition_screen.transition()
		await transition_screen.animation_finished
		get_tree().change_scene_to_packed(game)
		Dialogic.start("Intro")


func _on_controls_pressed() -> void:
	scroll_container.visible = !scroll_container.visible


func _on_exit_pressed() -> void:
	get_tree().quit()


func _on_control_pressed() -> void:
	panel_container.visible = !panel_container.visible
