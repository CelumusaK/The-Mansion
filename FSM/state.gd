extends Node
class_name State

signal Transitioned

var player: CharacterBody3D
var next_state: String
var nav_agent: NavigationAgent3D
var zombie: CharacterBody3D

func Enter():
	pass
	
func Exit():
	pass
	
func Update(delta: float):
	pass
	
func Physics_Update(delta: float):
	pass
