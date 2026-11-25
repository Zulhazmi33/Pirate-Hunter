
extends RefCounted

#region 0) -> Variable
#import
var monster_body: CharacterBody2D
var monster_sprite: AnimatedSprite2D
var attack_area: CollisionShape2D
var detection_area: CollisionShape2D
var start_position: Vector2
var lifebar: Node2D
var lifebar_energy: TextureRect

var SPEED: float = 100.0

#collision
var attackArea_position = 25
const detectionArea_position = 350

#distance
const move_distance: float = 400.0
var DIRECTION: int = -1

#switch
var is_alerted: bool = false
var is_attacking: bool = false
var is_attacked: bool = false
var is_dead: bool = false
var is_knockback: bool = false

#health
var HEALTH := 70 # FIX for now

#endregion

#region 1) -> Setup
func setup(body: CharacterBody2D) -> void:
	monster_body = body
	start_position = body.global_position

	monster_sprite = body.get_node("Monster")
	lifebar = body.get_node("lifebar_enemy")
	lifebar_energy = body.get_node("lifebar_enemy/energy")
	attack_area = body.get_node("AttackArea/Collision")
	detection_area = body.get_node("DetectionArea/Collision")

	#hide lifebar by default
	lifebar.hide()

#endregion


#region 2) -> Process
func _physics_process(delta: float) -> void:

	#region a) -> Prevent code
	if is_alerted or is_attacking or is_attacked or is_dead or is_knockback:

		# Still apply gravity while alerted
		if not monster_body.is_on_floor():
			monster_body.velocity += monster_body.get_gravity() * delta

		if not is_dead:
			monster_body.move_and_slide()

		return

	#endregion

	#region b) -> Gravity
	if not monster_body.is_on_floor():
		monster_body.velocity += monster_body.get_gravity() * delta
	#endregion

	#region c) -> Movement
	# a. Move monster
	monster_body.velocity.x = SPEED * DIRECTION
	monster_body.move_and_slide()

	# b. Run animation
	monster_sprite.play("run")

	# c. Flip sprite
	monster_sprite.flip_h = DIRECTION > 0

	# d. Detect wall collision
	for i in range(monster_body.get_slide_collision_count()):
		var collision = monster_body.get_slide_collision(i)
		var collider = collision.get_collider()
		var normal = collision.get_normal()

		if collider is TileMapLayer and abs(normal.x) > 0.8:
			DIRECTION *= -1
			start_position = monster_body.global_position
			return

	# e. Check movement distance
	var distance = abs(monster_body.global_position.x - start_position.x)

	if distance >= move_distance:
		DIRECTION *= -1
		start_position = monster_body.global_position

	#endregion

	#region d) -> Direction
	if DIRECTION > 0:
		attack_area.position.x = attackArea_position
		detection_area.position.x = detectionArea_position
	else:
		detection_area.position.x = -detectionArea_position
		attack_area.position.x = -attackArea_position

	#endregion

#endregion


#region 3) -> Attack
func detect_player(player: Node2D) -> bool:

	var space_state = monster_body.get_world_2d().direct_space_state

	var query = PhysicsRayQueryParameters2D.create(
		monster_body.global_position,
		player.global_position
	)

	# Ignore the monster itself
	query.exclude = [monster_body.get_rid()]

	var result = space_state.intersect_ray(query)

	# Check whether the first object hit is the player
	return not result.is_empty() and result.collider == player

func alert_animation() -> bool:

	# Prevent repeated alert
	if is_alerted or is_attacking or is_attacked or is_dead:
		return false

	is_alerted = true

	# 1. Stop movement
	monster_body.velocity.x = 0
	monster_body.velocity.y = 0

	# 2. Play 'alert' animation
	monster_sprite.play("alert")

	# 3. Wait 1 second
	await monster_body.get_tree().create_timer(1.0).timeout

	monster_sprite.play("run")

	# 4. Resume movement state
	is_alerted = false

	# 5. Attack
	is_attacking = true

	return true

func spinning() -> void:

	# 1. Play attack animation
	monster_sprite.play("attack")

	var timer = 0.0
	var duration = 2.0
	var spin_speed = 500.0
	var delta = 1.0 / 60.0

	while timer < duration:

		# 2. Move forward unless wall is encountered
		if monster_body.is_on_wall():
			monster_body.velocity.x = 0
		else:
			monster_body.velocity.x = spin_speed * DIRECTION

		# 3. Apply gravity
		if not monster_body.is_on_floor():
			monster_body.velocity += monster_body.get_gravity() * delta

		# 4. Collision-aware movement
		monster_body.move_and_slide()

		# 5. Wait for next physics frame
		timer += delta
		await monster_body.get_tree().physics_frame

	# 6. Stop movement
	monster_body.velocity.x = 0

	# 7. Finish attacking
	is_attacking = false

	# 8. Return to run animation
	monster_sprite.play("run")
	
#endregion


#region 4) -> Attribute
func health_reduce(DAMAGE: float, FORCE: float, player_position: Vector2) -> void:

	if is_dead:
		return

	# a. Knockback/push enemy away from player
	var direction = sign(monster_body.global_position.x - player_position.x)
	is_knockback = true
	monster_body.velocity.x = direction * FORCE

	# b. Die
	if (HEALTH - DAMAGE) < 32:
		is_dead = true
		lifebar_energy.hide()
		monster_sprite.play("dead")
		await monster_sprite.animation_finished
		lifebar.hide()
		monster_body.set_collision_mask_value(1, false)

	# c. Take damage
	else:
		HEALTH -= DAMAGE
		lifebar_energy.size.x = HEALTH
		is_attacked = true
		lifebar.show()
		monster_sprite.play("hit")
		await monster_sprite.animation_finished
		is_attacked = false

#endregion
