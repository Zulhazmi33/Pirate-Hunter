extends RefCounted

var icon: TextureRect

var current_index := 3
var projectile_types = ["arrow", "slowed", "shield", "teleport"]
var icons = {
	"arrow": preload("res://assets/images/icon/Arrow.png"),
	"slowed": preload("res://assets/images/icon/Slowed.png"),
	"shield": preload("res://assets/images/icon/Shield.png"),
	"teleport": preload("res://assets/images/icon/Teleport.png")
}


func setup(player: CharacterBody2D) -> void:
	icon = player.get_node("Camera2D/CanvasLayer/Icon")
	update_icon()


func swap() -> void:
	current_index = (current_index + 1) % projectile_types.size()
	update_icon()


func update_icon() -> void:
	var selected = projectile_types[current_index]
	icon.texture = icons[selected]


func getType() -> String:
	return projectile_types[current_index]
