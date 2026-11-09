extends "res://scripts/creature/monster.gd"


func _ready() -> void:
	# Statistics
	SPEED = 200.0
	DAMAGE = 50.0
	HEALTH = 70.0

	# Knockback
	KNOCKBACK_FORCE = 600.0
	KNOCKBACK_UP = 200.0

	# Patrol
	PATROL_SPEED = 100.0
	PATROL_DISTANCE = 200.0

	# Detection
	DETECTION_OFFSET = 275.0
	DETECTION_BACK_OFFSET = -100.0

	# Slow
	slow_duration = 5.0
	slow_multiplier = 0.5

	super()


func handle_movement() -> void:
	var movement_multiplier := slow_multiplier if is_slowed else 1.0

	# Patrol
	if player == null or not player_visible:
		is_chasing = false
		player_in_attack_area = false

		super()
		return

	# Attack
	if player_in_attack_area:
		monster.play("attack")
		velocity.x = 0
		return

	# Chase
	is_chasing = true

	monster.play("run")

	var direction: float = sign(
		player.global_position.x - global_position.x
	)

	velocity.x = direction * SPEED * movement_multiplier

	if direction != 0:
		monster.flip_h = direction > 0

	update_detection_area()
	update_attack_area()
