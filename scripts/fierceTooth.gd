extends "res://scripts/monster.gd"

#initialize
func _ready() -> void:
	SPEED = 200.0
	DAMAGE = 50.0
	HEALTH = 70.0
	JUMP_VELOCITY = -900.0
	
	KNOCKBACK_FORCE = 600.0
	KNOCKBACK_UP = 200.0
	
	PATROL_SPEED = 100.0
	PATROL_DISTANCE = 200.0
	
	DETECTION_OFFSET = 275.0
	DETECTION_BACK_OFFSET = -100.0
	
	slow_duration = 5.0
	slow_multiplier = 0.5

	super()
