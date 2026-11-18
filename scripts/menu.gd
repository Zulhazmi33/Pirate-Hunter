extends Control

func _ready() -> void:
	get_tree().change_scene_to_file("res://scenes/level/level_1.tscn")
	pass
	
func _on_pressed_start() -> void:
	get_tree().change_scene_to_file("res://scenes/level/level_1.tscn")

func _on_pressed_option() -> void:
	print('option')

func _on_pressed_exit() -> void:
	get_tree().quit()
