extends RefCounted

var attack_area: Area2D

func setup(parent: CharacterBody2D) -> void:
	attack_area = parent.get_node("AttackArea")

func detect_enemy() -> void:
	for body in attack_area.get_overlapping_bodies():
		if body.name.begins_with("fierceTooth") or body.name.begins_with("pinkStar"):
			print("KILL")
