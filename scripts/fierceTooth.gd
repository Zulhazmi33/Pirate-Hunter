
extends CharacterBody2D

#region -> import
# Character
@onready var fierceTooth: AnimatedSprite2D = $Monster
@onready var detection_area: Area2D = $DetectionArea
@onready var attack_area: Area2D = $AttackArea
@onready var attack_collision: CollisionShape2D = $AttackArea/Collision
@onready var attack_collision_x: float = abs(attack_collision.position.x)

# Lifebar
@onready var lifebar_enemy: Node2D = $lifebar_enemy
@onready var energy: TextureRect = $lifebar_enemy/energy

# Movement
@export var SPEED: float = 200.0
@export var JUMP_VELOCITY: float = -900.0
@export var PATROL_SPEED: float = 100.0
@export var PATROL_DISTANCE: float = 200.0
@export var DETECTION_OFFSET: float = 200.0
@export var DETECTION_BACK_OFFSET: float = -100.0

var patrol_start_x: float
var patrol_direction := -1.0
var patrol_wall_cooldown := 0.0
var is_chasing := false

# Player detection
var player: CharacterBody2D = null
var player_in_attack_area := false
var player_visible := false

# Attack
@export var DAMAGE: float = 50.0
@onready var sound_bite: AudioStreamPlayer2D = $Bite

# Health
var health := 70.0
var isDead := false
var invincible := false
var invincible_timer := 0.0
var invincible_flash_timer := 0.0

# Knockback
@export var KNOCKBACK_FORCE: float = 600.0
@export var KNOCKBACK_UP: float = 200.0
var knockback_timer := 0.0

# Slow effect
var is_slowed := false
var slow_timer := 0.0
var slow_duration := 5.0
var slow_multiplier := 0.5
#endregion


#region -> Starter

func _ready() -> void:
	lifebar_enemy.hide()
	patrol_start_x = global_position.x

	# Detection signals
	detection_area.body_entered.connect(_on_detection_area_body_entered)
	detection_area.body_exited.connect(_on_detection_area_body_exited)
	attack_area.body_entered.connect(_on_attack_area_body_entered)
	attack_area.body_exited.connect(_on_attack_area_body_exited)

	# Animation signal
	fierceTooth.frame_changed.connect(_on_attack_frame_changed)

	update_detection_area()
	update_attack_area()

#endregion


#region -> Physics

func _physics_process(delta: float) -> void:
	update_invincibility(delta)

	knockback_timer = maxf(knockback_timer - delta, 0.0)

	if knockback_timer == 0 and velocity.x != 0 and fierceTooth.animation == "hit":
		velocity.x = 0

	# Animation speed
	if is_slowed:
		fierceTooth.speed_scale = 0.5
	elif is_chasing and fierceTooth.animation != "attack":
		fierceTooth.speed_scale = 15.0/7.0
	elif fierceTooth.animation == "attack":
		fierceTooth.speed_scale = 1.0
	else:
		fierceTooth.speed_scale = 1.0
		
		
		
	# Gravity
	patrol_wall_cooldown -= delta

	if is_on_floor():
		velocity.y = 0
	else:
		velocity += get_gravity() * delta

	# Player visibility
	player_visible = player != null and (is_chasing or can_see_player())

	if fierceTooth.animation != "hit" and fierceTooth.animation != "dead":
		handle_movement()

	move_and_slide()


func update_invincibility(delta: float) -> void:
	# Slow effect
	if is_slowed:
		slow_timer -= delta
		if slow_timer <= 0:
			is_slowed = false
			fierceTooth.modulate = Color.WHITE
		
	if not invincible:
		return

	invincible_timer -= delta
	invincible_flash_timer -= delta

	if invincible_flash_timer <= 0:
		invincible_flash_timer = 0.1
		fierceTooth.modulate = Color.WHITE if fierceTooth.modulate != Color.WHITE else Color(1, 1, 1, 0.5)

	if invincible_timer <= 0:
		invincible = false
		fierceTooth.modulate = Color.WHITE


func handle_movement() -> void:
	# Patrol
	if player == null or not player_visible:
		fierceTooth.play("run")
		#velocity.x = patrol_direction * PATROL_SPEED
		velocity.x = patrol_direction * PATROL_SPEED * (slow_multiplier if is_slowed else 1.0)
		player_in_attack_area = false

		# Patrol limits
		if global_position.x >= patrol_start_x + PATROL_DISTANCE:
			patrol_direction = -1.0
		elif global_position.x <= patrol_start_x - PATROL_DISTANCE:
			patrol_direction = 1.0

		# Wall detection
		if not is_chasing and is_on_wall() and patrol_wall_cooldown <= 0:
			patrol_direction *= -1
			patrol_wall_cooldown = 0.2

		fierceTooth.flip_h = patrol_direction > 0

	# Attack
	elif player_in_attack_area:
		fierceTooth.play("attack")
		velocity.x = 0

	# Chase
	else:
		is_chasing = true
		fierceTooth.play("run")

		var direction: float = sign(player.global_position.x - global_position.x)
		#velocity.x = direction * SPEED
		velocity.x = direction * SPEED * (slow_multiplier if is_slowed else 1.0)

		if direction != 0:
			fierceTooth.flip_h = direction > 0

	# Update detection areas
	update_detection_area()
	update_attack_area()

	# Jump over obstacles
	if is_chasing and is_on_wall() and is_on_floor():
		var collision = get_last_slide_collision()

		if collision:
			var collider = collision.get_collider()
			if collider != null and collider != player and collider.name != "Bubble":

				if abs(collision.get_normal().x) > 0.5:
					#velocity.y = JUMP_VELOCITY
					velocity.y = JUMP_VELOCITY * (slow_multiplier if is_slowed else 1.0)
					fierceTooth.play("jump")

#endregion


#region -> Detection Radius

func update_detection_area() -> void:
	detection_area.position.x = (DETECTION_OFFSET - DETECTION_BACK_OFFSET) * (1 if fierceTooth.flip_h else -1)


func update_attack_area() -> void:
	attack_collision.position.x = attack_collision_x * (1 if fierceTooth.flip_h else -1)

#endregion


#region -> Seeing Player

func can_see_player() -> bool:
	var query = PhysicsRayQueryParameters2D.create(
		global_position,
		player.global_position
	)

	query.exclude = [self]

	var result = get_world_2d().direct_space_state.intersect_ray(query)

	return not result.is_empty() and (
		result.collider == player or result.collider.name == "Bubble"
	)

#endregion


#region -> Detect Player

func _on_detection_area_body_entered(body: Node2D) -> void:
	if body.name == "Player" or body.name == "Bubble":
		player = body


func _on_detection_area_body_exited(body: Node2D) -> void:
	if body == player:
		player = null
		player_in_attack_area = false
		is_chasing = false


func _on_attack_area_body_entered(body: Node2D) -> void:
	if body == player:
		player_in_attack_area = true


func _on_attack_area_body_exited(body: Node2D) -> void:
	if body == player:
		player_in_attack_area = false

#endregion


#region -> Attack Damage
func _on_attack_frame_changed() -> void:
	if fierceTooth.animation != "attack" or fierceTooth.frame != 3:
		return

	if not player_in_attack_area or not is_instance_valid(player):
		return

	if player.isDead or player.invincible:
		return

	sound_bite.play(0.20)
	player.take_damage(DAMAGE, global_position)

func slow_movement() -> void:
	if isDead:
		return
		
	is_slowed = true
	slow_timer = slow_duration
	
	
	# Blue / wet appearance
	fierceTooth.modulate = Color(0.5, 0.75, 1.0, 1.0)
#endregion


#region -> Reduce Health

func take_damage(damage: float, attacker_position: Vector2) -> void:
	health -= damage
	energy.size.x = health

	fierceTooth.play("hit")
	lifebar_enemy.show()

	# Invincibility
	invincible = true
	invincible_timer = 1.0
	invincible_flash_timer = 0.0

	# Knockback
	var direction: float = sign(global_position.x - attacker_position.x)
	velocity = Vector2(direction * KNOCKBACK_FORCE, -KNOCKBACK_UP)
	knockback_timer = 0.2

	# Death
	if health <= 0:
		health = 0
		energy.hide()
		isDead = true

		fierceTooth.play("dead")

		# Keep collision with TileMapLayer only
		collision_layer = 0
		collision_mask = 1 << 3

		velocity = Vector2.ZERO

	# Hide lifebar after 0.7 seconds
	await get_tree().create_timer(0.7).timeout

	lifebar_enemy.hide()

	if not isDead:
		fierceTooth.play("idle")

#endregion
