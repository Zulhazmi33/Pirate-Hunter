extends Control

@onready var vbox_container: VBoxContainer = $Option
@onready var level_selection: Control = $Choose_level


func _ready() -> void:
	#level_selection.hide()
	get_tree().change_scene_to_file.call_deferred("res://scenes/level/level_1.tscn")


func _on_pressed_start() -> void:
	vbox_container.hide()
	level_selection.show()
	
	#get_tree().change_scene_to_file("res://scenes/level/level_1.tscn")


func _on_pressed_option() -> void:
	print("option")


func _on_pressed_exit() -> void:
	get_tree().quit()
