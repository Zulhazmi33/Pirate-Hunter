extends CharacterBody2D

# character
@onready var player: AnimatedSprite2D = $Player
@onready var attack_area: Area2D = $AttackArea
@onready var attack_collision: CollisionShape2D = $AttackArea/Collision
@onready var attack_collision_x: float = abs($AttackArea/Collision.position.x)

# dust particle
@onready var dust_jump: AnimatedSprite2D = $Dust_particle/Dust_jump
@onready var dust_run: AnimatedSprite2D = $Dust_particle/Dust_run
var was_on_floor := false

# sword effects
@onready var dust_attack_1: AnimatedSprite2D = $Attack_effect/attack_1
@onready var dust_attack_2: AnimatedSprite2D = $Attack_effect/attack_2
@onready var dust_attack_3: AnimatedSprite2D = $Attack_effect/attack_3
var attack_effects: Array[AnimatedSprite2D]

# attack combo
var attack_index := 0
var attacking := false
var attack_queued := false
@export var DAMAGE: float = 50.0

# sound
@onready var sound_jump: AudioStreamPlayer2D = $Jump
@onready var sound_death: AudioStreamPlayer2D = $Death

# physics
const SPEED = 300.0
const JUMP_VELOCITY = -900.0

# health
@onready var energy: TextureRect = $Camera2D/lifebar_player/energy
var health: float = 250.0
var isDead: bool = false
var invincible: bool = false
var invincible_timer: float = 0.0
var invincible_flash_timer: float = 0.0

# knockback
@export var KNOCKBACK_FORCE: float = 600.0
@export var KNOCKBACK_UP: float = 200.0
var knockback_timer: float = 0.0

#detection
@onready var collision: CollisionShape2D = $Collision
var enemy: CharacterBody2D = null

#ability
#bubble
@onready var bubble: CharacterBody2D = $Bubble
var bubble_tween: Tween
var bubble_visible := false
#arrow
@export var water_arrow_scene: PackedScene = preload("uid://jovkp5fv52ba")
@onready var arrow_spawn: Marker2D = $ArrowSpawn


#region -> starter
func _ready() -> void:
	#hide bubble
	bubble.hide()
	bubble.scale = Vector2(0.1, 0.1)
	#looping atack's  combo
	attack_effects = [
		dust_attack_1,
		dust_attack_2,
		dust_attack_3
	]
	for effect in attack_effects:
		effect.visible = false
		effect.animation_finished.connect(_on_attack_effect_animation_finished)

	# Hide particles/effects
	dust_jump.visible = false
	dust_run.visible = false

	# Animation signals
	player.animation_finished.connect(_on_animation_finished)
	dust_jump.animation_finished.connect(_on_dust_animation_finished)
	dust_run.animation_finished.connect(_on_dust_animation_finished)
	
	#attack range
	attack_area.body_entered.connect(_on_attack_area_body_entered)
	attack_area.body_exited.connect(_on_attack_area_body_exited)
	
#endregion


#region -> physic_process()
func _physics_process(delta: float) -> void:

	# Prevent movement if dead
	if isDead:
		return
		
	# Invincibility timer
	if invincible:
		invincible_timer -= delta
		invincible_flash_timer -= delta

		# Flash white
		if invincible_flash_timer <= 0:
			invincible_flash_timer = 0.1
			player.modulate = Color.WHITE if player.modulate != Color.WHITE else Color(1, 1, 1, 0.5)

		if invincible_timer <= 0:
			invincible = false
			player.modulate = Color.WHITE
		
	# Knockback timer
	if knockback_timer > 0:
		knockback_timer -= delta

	# 1) Gravity
	if not is_on_floor():
		velocity += get_gravity() * delta

	# 2) Jump
	if Input.is_action_just_pressed("jump") and is_on_floor() and knockback_timer <= 0:

		dust_run.stop()
		dust_run.visible = false

		velocity.y = JUMP_VELOCITY
		sound_jump.play()

		play_dust(dust_jump, "jump")

	# 3) Direction
	if knockback_timer <= 0:

		var direction := Input.get_axis("left", "right")

		if direction:
			velocity.x = direction * SPEED
			player.flip_h = direction < 0

			# Move attack collision based on direction
			attack_collision.position.x = -attack_collision_x if player.flip_h else attack_collision_x

			# Move arrow spawn based on direction
			arrow_spawn.position.x = -abs(arrow_spawn.position.x) if player.flip_h else abs(arrow_spawn.position.x)
			
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)

	# 4) Attack
	if Input.is_action_just_pressed("attack") and knockback_timer <= 0:
		handle_attack()
		
	# 4.1) Bubble ability
	if Input.is_action_just_pressed("shield"):
		toggle_bubble()
	# 4.2 Water Arrow
	if Input.is_action_just_pressed("shoot"):
		shoot_arrow()

	# 5) Move player
	move_and_slide()

	# 6) Cancel aerial attack when landing
	if attacking and player.animation == "aerial_attack" and is_on_floor():
		attacking = false
		attack_index = 0
		attack_queued = false

	# 7) Normal animation
	if not attacking and player.animation != "hit" and not isDead:
		play_normal_animation()

	was_on_floor = is_on_floor()
#endregion


#region -> Attack damage
func handle_attack() -> void:
	# Air attack
	if not is_on_floor():
		attacking = true
		player.play("aerial_attack")
		return

	# Start ground combo
	if not attacking:
		attacking = true
		attack_index = 1
		play_ground_attack(1)
		return

	# Queue next attack
	if attack_index < 3:
		attack_queued = true
		
func play_ground_attack(index: int) -> void:
	if enemy != null:
		enemy.take_damage(DAMAGE, global_position)
		
	player.play("attack_" + str(index))
	play_attack_effect(index)
	
func play_attack_effect(index: int) -> void:
	var effect = attack_effects[index - 1]

	effect.flip_h = player.flip_h
	effect.position.x = abs(effect.position.x) * (-1 if player.flip_h else 1)
	effect.visible = true
	effect.play("attack")
#endregion


#region -> Animation 
func play_normal_animation() -> void:
	if not is_on_floor():
		if velocity.y < 0:
			player.play("jump")
		else:
			player.play("fall")

	elif velocity.x != 0:
		player.play("run")

	else:
		player.play("idle")

func _on_animation_finished() -> void:

	# Prevent movement if dead
	if isDead:
		return
		
	# Hit
	if player.animation == "hit":
		play_normal_animation()
		return

	# Aerial attack
	if player.animation == "aerial_attack":
		attacking = false
		play_normal_animation()
		return

	# Ground attacks
	if player.animation.begins_with("attack_"):
		if attack_queued and attack_index < 3:
			attack_queued = false
			attack_index += 1
			play_ground_attack(attack_index)
		else:
			attacking = false
			attack_index = 0
#endregion


#region -> Dust particle
#1) move
func play_dust(dust: AnimatedSprite2D, animation: String) -> void:
	dust.visible = true
	dust.play(animation)
func _on_dust_animation_finished() -> void:
	dust_jump.visible = false
	dust_run.visible = false
#2) attack
func _on_attack_effect_animation_finished() -> void:
	for effect in attack_effects:
		effect.visible = false
#endregion


#region -> Reduce health
func take_damage(damage: float, attacker_position: Vector2) -> void:
	if invincible || isDead:
		return

	health -= damage
	energy.size.x = health

	invincible = true
	invincible_timer = 1.0

	# Cancel current attack
	attacking = false
	attack_queued = false
	attack_index = 0

	var knockback_direction = sign(global_position.x - attacker_position.x)
	velocity.x = knockback_direction * KNOCKBACK_FORCE
	velocity.y = -KNOCKBACK_UP
	knockback_timer = 0.2

	player.play("hit")

	if health <= 0:
		health = 0
		energy.visible = false
		isDead = true
		player.play("dead")
		sound_death.play()
#endregion


#region -> Detect enemy
func _on_attack_area_body_entered(body):
	print("Player detected: ", body.name)
	if body.name.begins_with("fierceTooth"):
		enemy = body

func _on_attack_area_body_exited(body):
	enemy = null
#endregion


#region -> Ability
func toggle_bubble() -> void:

	# Prevent previous animation from interfering
	if bubble_tween:
		bubble_tween.kill()

	bubble_visible = !bubble_visible

	if bubble_visible:
		bubble.show()
		bubble.set_physics_process(true)
		bubble.set_collision_layer_value(3, true)
		bubble.set_collision_mask_value(2, true)

		bubble_tween = create_tween()
		bubble_tween.tween_property(
			bubble,
			"scale",
			Vector2(1.0, 1.0),
			1
		).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	else:
		bubble_tween = create_tween()
		bubble_tween.tween_property(
			bubble,
			"scale",
			Vector2(0.1, 0.1),
			0.3
		).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)

		bubble_tween.tween_callback(func():
			bubble.hide()
			bubble.set_physics_process(false)
			bubble.set_collision_layer_value(3, false)
			bubble.set_collision_mask_value(2, false)
		)

func shoot_arrow() -> void:

	var arrow = water_arrow_scene.instantiate()

	get_tree().current_scene.add_child(arrow)

	# Set spawn position based on player direction
	arrow.global_position = arrow_spawn.global_position

	# Set arrow direction
	arrow.direction = -1.0 if player.flip_h else 1.0

	# Flip arrow sprite
	arrow.arrow.flip_h = !player.flip_h

#endregion
