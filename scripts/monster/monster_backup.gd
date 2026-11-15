extends CharacterBody2D

#region -> Import

@onready var monster: AnimatedSprite2D = $Monster
@onready var detection_area: Area2D = $DetectionArea
@onready var attack_area: Area2D = $AttackArea
@onready var attack_collision: CollisionShape2D = $AttackArea/Collision
@onready var attack_collision_x: float = abs(attack_collision.position.x)

@onready var lifebar_enemy: Node2D = $lifebar_enemy
@onready var energy: TextureRect = $lifebar_enemy/energy
@onready var sound_bite: AudioStreamPlayer2D = $Bite

# Movement
@export var SPEED := 0.0
var PATROL_SPEED := 0.0
var PATROL_DISTANCE := 0.0
var DETECTION_OFFSET := 0.0
var DETECTION_BACK_OFFSET := 0.0

@export var PATROL_DIRECTION := -1.0
var patrol_start_x: float
var patrol_wall_cooldown := 0.0
var is_chasing := false

# Detection
var player: CharacterBody2D = null
var player_in_attack_area := false
var player_visible := false
var is_anticipating := false
var anticipation_duration := 1.0

# Attack
@export var DAMAGE := 0.0

# Health
@export var HEALTH := 0.0
var isDead := false
var invincible := false
var invincible_timer := 0.0
var invincible_flash_timer := 0.0

# Knockback
var KNOCKBACK_FORCE := 0.0
var KNOCKBACK_UP := 0.0
var knockback_timer := 0.0

# Slow
var is_slowed := false
var slow_timer := 0.0
var slow_duration := 0.0
var slow_multiplier := 0.0

#endregion


#region -> Starter
func _ready() -> void:
	lifebar_enemy.hide()
	patrol_start_x = global_position.x

	detection_area.body_entered.connect(_on_detection_area_body_entered)
	detection_area.body_exited.connect(_on_detection_area_body_exited)

	attack_area.body_entered.connect(_on_attack_area_body_entered)
	attack_area.body_exited.connect(_on_attack_area_body_exited)

	monster.frame_changed.connect(_on_attack_frame_changed)

	update_detection_area()
	update_attack_area()

#endregion


#region -> Physics
func _physics_process(delta: float) -> void:
	update_invincibility(delta)

	knockback_timer = maxf(knockback_timer - delta, 0.0)

	if knockback_timer == 0.0 and monster.animation == "hit":
		velocity.x = 0

	# Animation speed
	monster.speed_scale = (
		0.5 if is_slowed
		else 15.0 / 7.0 if is_chasing and monster.animation != "attack"
		else 1.0
	)

	# Gravity
	patrol_wall_cooldown -= delta
	velocity.y = 0 if is_on_floor() else velocity.y + get_gravity().y * delta

	# Player visibility
	player_visible = (
		is_instance_valid(player)
		and can_see_player()
	)

	if monster.animation not in ["hit", "dead"] and not is_anticipating:
		handle_movement()

	move_and_slide()

func handle_movement() -> void:
	var movement_multiplier := slow_multiplier if is_slowed else 1.0

	# Patrol
	if player == null or not player_visible:
		monster.play("run")

		velocity.x = PATROL_DIRECTION * PATROL_SPEED * movement_multiplier

		if global_position.x >= patrol_start_x + PATROL_DISTANCE:
			PATROL_DIRECTION = -1.0

		elif global_position.x <= patrol_start_x - PATROL_DISTANCE:
			PATROL_DIRECTION = 1.0

		if not is_chasing and is_on_wall() and patrol_wall_cooldown <= 0:
			PATROL_DIRECTION *= -1
			patrol_wall_cooldown = 0.2

		monster.flip_h = PATROL_DIRECTION > 0

	update_detection_area()
	update_attack_area()

func update_invincibility(delta: float) -> void:

	# Slow effect
	if is_slowed:
		slow_timer -= delta

		if slow_timer <= 0:
			is_slowed = false
			monster.modulate = Color.WHITE

	if not invincible:
		return

	invincible_timer -= delta
	invincible_flash_timer -= delta

	if invincible_flash_timer <= 0:
		invincible_flash_timer = 0.1

		monster.modulate = (
			Color(1, 1, 1, 0.5) if monster.modulate == Color.WHITE
			else Color.WHITE
		)

	if invincible_timer <= 0:
		invincible = false
		monster.modulate = Color.WHITE

#endregion


#region -> Detection Radius
func update_detection_area() -> void:
	detection_area.position.x = (
		DETECTION_OFFSET - DETECTION_BACK_OFFSET
	) * (1 if monster.flip_h else -1)

func update_attack_area() -> void:
	attack_collision.position.x = (
		attack_collision_x * (1 if monster.flip_h else -1)
	)

#endregion


#region -> Seeing Player
func can_see_player() -> bool:
	if not is_instance_valid(player):
		return false

	var query := PhysicsRayQueryParameters2D.create(
		global_position,
		player.global_position
	)

	query.exclude = [self]

	var result := get_world_2d().direct_space_state.intersect_ray(query)

	return (
		not result.is_empty()
		and (result.collider == player or result.collider.name == "Shield")
	)

#endregion


#region -> Detect Player
func _on_detection_area_body_entered(body: Node2D) -> void:
	if body.name not in ["Player", "Shield"]:
		return

	player = body

	if (
		not is_chasing
		and not is_anticipating
		and not isDead
		and can_see_player()
	):
		start_anticipation()

func _on_detection_area_body_exited(body: Node2D) -> void:
	if body != player:
		return

	player = null
	player_in_attack_area = false
	is_chasing = false
	is_anticipating = false

func _on_attack_area_body_entered(body: Node2D) -> void:
	if body == player:
		player_in_attack_area = true

func _on_attack_area_body_exited(body: Node2D) -> void:
	if body == player:
		player_in_attack_area = false

func start_anticipation() -> void:
	is_anticipating = true
	velocity.x = 0

	monster.play("anticipation")

	await get_tree().create_timer(anticipation_duration).timeout

	if isDead or not is_instance_valid(player):
		is_anticipating = false
		return

	if can_see_player():
		is_chasing = true

	is_anticipating = false

#endregion


#region -> Attack Damage
func _on_attack_frame_changed() -> void:
	if monster.animation != "attack" or monster.frame != 3:
		return

	if not player_in_attack_area or not is_instance_valid(player):
		return

	if player.isDead or player.invincible:
		return

	sound_bite.play(0.20)
	player.take_damage(DAMAGE, global_position)

#endregion


#region -> Reduce Health
func take_damage(damage: float, attacker_position: Vector2) -> void:
	HEALTH = maxf(HEALTH - damage, 0)
	energy.size.x = HEALTH

	monster.play("hit")
	lifebar_enemy.show()

	# Invincibility
	invincible = true
	invincible_timer = 1.0
	invincible_flash_timer = 0.0

	# Knockback
	var direction: float = sign(global_position.x - attacker_position.x)

	velocity = Vector2(
		direction * KNOCKBACK_FORCE,
		-KNOCKBACK_UP
	)

	knockback_timer = 0.2

	# Death
	if HEALTH <= 0:
		isDead = true
		energy.hide()

		monster.play("dead")

		collision_layer = 0
		collision_mask = 1 << 3

		velocity = Vector2.ZERO

	await get_tree().create_timer(0.7).timeout

	lifebar_enemy.hide()

	if not isDead:
		monster.play("idle")

func slow_movement() -> void:
	if isDead:
		return

	is_slowed = true
	slow_timer = slow_duration

	monster.modulate = Color(0.5, 0.75, 1.0, 1.0)

#endregion
