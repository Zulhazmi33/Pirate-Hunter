extends CharacterBody2D

const mana_cost: float = 50.0

func _ready():
	collision_layer = 4
	collision_mask = 2
