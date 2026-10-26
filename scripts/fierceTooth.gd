extends CharacterBody2D

@onready var sprite: AnimatedSprite2D = $Monster
@onready var detection_area: Area2D = $DetectionArea
@onready var attack_area: Area2D = $AttackArea

@export var SPEED: float = 200.0
@export var JUMP_VELOCITY: float = -900.0

# For patrolling only
@export var PATROL_SPEED: float = 100.0
@export var PATROL_DISTANCE: float = 200.0
var patrol_wall_cooldown: float = 0.0

# Detection
@export var DETECTION_OFFSET: float = 200.0
@export var DETECTION_BACK_OFFSET: float = -100.0
var is_chasing: bool = false

var patrol_start_x: float
var patrol_direction: float = -1.0

var player: CharacterBody2D = null
var player_in_attack_area: bool = false
var player_visible: bool = false

# Attack
@export var DAMAGE: float = 300.0


# Initial
func _ready():
	# Patrol
	patrol_start_x = global_position.x

	# Detect player
	detection_area.body_entered.connect(_on_detection_area_body_entered)
	detection_area.body_exited.connect(_on_detection_area_body_exited)

	# Detect attack range
	attack_area.body_entered.connect(_on_attack_area_body_entered)
	attack_area.body_exited.connect(_on_attack_area_body_exited)

	# Detect attack animation frame
	sprite.frame_changed.connect(_on_attack_frame_changed)

	# Initial detection position
	update_detection_area()


# Logic for physics
func _physics_process(delta):

	# Animation FPS
	if sprite.animation == "attack":
		sprite.speed_scale = 1.0
	elif is_chasing:
		sprite.speed_scale = 15.0 / 7.0
	else:
		sprite.speed_scale = 1.0

	# Patrol cooldown
	patrol_wall_cooldown -= delta

	# Gravity
	if not is_on_floor():
		velocity += get_gravity() * delta
	else:
		velocity.y = 0

	# Check if Player can be seen
	if player != null:
		if is_chasing:
			player_visible = true
		else:
			player_visible = can_see_player()
	else:
		player_visible = false

	# No Player / Player is hidden
	if player == null or not player_visible:
		sprite.play("run")

		velocity.x = patrol_direction * PATROL_SPEED

		# Change direction at patrol limits
		if global_position.x >= patrol_start_x + PATROL_DISTANCE:
			patrol_direction = -1.0

		elif global_position.x <= patrol_start_x - PATROL_DISTANCE:
			patrol_direction = 1.0

		# Turn around when hitting a vertical wall while patrolling
		if not is_chasing and is_on_wall() and patrol_wall_cooldown <= 0:
			patrol_direction *= -1
			patrol_wall_cooldown = 0.2

		sprite.flip_h = patrol_direction > 0

		player_in_attack_area = false

	# Player is visible and close enough to attack
	elif player_in_attack_area:
		sprite.play("attack")
		velocity.x = 0

	# Chase Player
	else:
		is_chasing = true

		sprite.play("run")

		var direction = sign(player.global_position.x - global_position.x)

		velocity.x = direction * SPEED

		if direction != 0:
			sprite.flip_h = direction > 0

	# Update DetectionArea based on facing direction
	update_detection_area()

	# Jump when hitting an obstacle
	if is_chasing and is_on_wall() and is_on_floor():
		var collision = get_last_slide_collision()

		if collision != null and collision.get_collider() != player:
			var normal = collision.get_normal()

			# Only jump when hitting a wall from the side
			if abs(normal.x) > 0.5:
				velocity.y = JUMP_VELOCITY
				sprite.play("jump")

	# Move
	move_and_slide()


# Detection radius
func update_detection_area():
	if sprite.flip_h:
		detection_area.position.x = DETECTION_OFFSET - DETECTION_BACK_OFFSET
	else:
		detection_area.position.x = -DETECTION_OFFSET + DETECTION_BACK_OFFSET


# Logic when seeing player
func can_see_player() -> bool:
	var space_state = get_world_2d().direct_space_state

	var query = PhysicsRayQueryParameters2D.create(
		global_position,
		player.global_position
	)

	# Don't let the ray hit the monster itself
	query.exclude = [self]

	var result = space_state.intersect_ray(query)

	# Nothing was hit
	if result.is_empty():
		return false

	# The first thing hit is the Player
	if result.collider == player:
		return true

	# Something else was hit first
	return false


#region --> Built-in detection method

func _on_detection_area_body_entered(body):
	if body.name == "Player":
		player = body


func _on_detection_area_body_exited(body):
	if body == player:
		player = null
		player_in_attack_area = false
		is_chasing = false


func _on_attack_area_body_entered(body):
	if body == player:
		player_in_attack_area = true


func _on_attack_area_body_exited(body):
	if body == player:
		player_in_attack_area = false

#endregion


#region --> Attack damage

func _on_attack_frame_changed() -> void:
	# Only deal damage during the attack animation
	if sprite.animation != "attack":
		return

	# Only deal damage on frame 0
	if sprite.frame != 0:
		return

	# Player must still be inside attack range
	if not player_in_attack_area:
		return

	# Make sure we have a Player reference
	if player == null:
		return

	# Deal damage
	#player.take_damage(DAMAGE)
	player.take_damage(DAMAGE, global_position)

#endregion
