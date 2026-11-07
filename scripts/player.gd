
extends CharacterBody2D

#region -> import
# Character
@onready var player: AnimatedSprite2D = $Player
@onready var attack_area: Area2D = $AttackArea
@onready var attack_collision: CollisionShape2D = $AttackArea/Collision
@onready var attack_collision_x: float = abs(attack_collision.position.x)

# Dust & attack effects
@onready var dust_jump: AnimatedSprite2D = $Dust_particle/Dust_jump
@onready var dust_run: AnimatedSprite2D = $Dust_particle/Dust_run
@onready var attack_effects: Array[AnimatedSprite2D] = [
	$Attack_effect/attack_1,
	$Attack_effect/attack_2,
	$Attack_effect/attack_3
]

var was_on_floor := false

# Attack
@export var DAMAGE: float = 50.0
var attack_index := 0
var attacking := false
var attack_queued := false
var enemy: CharacterBody2D = null

# Sound
@onready var sound_jump: AudioStreamPlayer2D = $Jump
@onready var sound_death: AudioStreamPlayer2D = $Death

# Movement
const SPEED = 300.0
const JUMP_VELOCITY = -900.0

# Health
@onready var energy: TextureRect = $Camera2D/lifebar_player/energy

var health := 250.0
var isDead := false
var invincible := false
var invincible_timer := 0.0
var invincible_flash_timer := 0.0

# Knockback
@export var KNOCKBACK_FORCE: float = 600.0
@export var KNOCKBACK_UP: float = 200.0
var knockback_timer := 0.0

# Bubble
@onready var bubble: CharacterBody2D = $Bubble
var bubble_tween: Tween
var bubble_visible := false

# Projectile
@export var scene_arrow: PackedScene = preload("res://scenes/ability/arrow.tscn")
@export var scene_knife: PackedScene = preload("res://scenes/ability/knife.tscn")
@export var scene_bind: PackedScene = preload("res://scenes/ability/bind.tscn")
@onready var throw_spawn: Marker2D = $ThrowSpawn
@export_enum("knife", "arrow", "bind", "bubble") var projectileType: String = "knife"

# Icon
@onready var ability_icon: TextureRect = $Camera2D/CanvasLayer/Panel/TextureRect

var icon_arrow = preload("res://assets/images/icon/Arrow.png")
var icon_knife = preload("res://assets/images/icon/Knife.png")
var icon_bind = preload("res://assets/images/icon/Bind.png")
var icon_bubble = preload("res://assets/images/icon/Bubble.png")

#endregion


#region -> Starter
func _ready() -> void:
	ability_icon.texture = icon_knife
	
	bubble.hide()
	bubble.scale = Vector2(0.1, 0.1)

	for effect in attack_effects:
		effect.hide()
		effect.animation_finished.connect(_on_attack_effect_animation_finished)

	for dust in [dust_jump, dust_run]:
		dust.hide()
		dust.animation_finished.connect(_on_dust_animation_finished)

	player.animation_finished.connect(_on_animation_finished)
	player.frame_changed.connect(_on_player_frame_changed)

	attack_area.body_entered.connect(_on_attack_area_body_entered)
	attack_area.body_exited.connect(_on_attack_area_body_exited)
#endregion


#region -> Physics
func _physics_process(delta: float) -> void:
	if isDead:
		return

	update_invincibility(delta)

	knockback_timer = maxf(knockback_timer - delta, 0.0)

	if not is_on_floor():
		velocity += get_gravity() * delta

	handle_movement()
	handle_abilities()

	move_and_slide()

	# Cancel aerial attack on landing
	if attacking and player.animation == "aerial_attack" and is_on_floor():
		reset_attack()

	# Normal animation
	if not attacking and player.animation != "hit":
		play_normal_animation()

	was_on_floor = is_on_floor()

func update_invincibility(delta: float) -> void:
	if not invincible:
		return

	invincible_timer -= delta
	invincible_flash_timer -= delta

	if invincible_flash_timer <= 0:
		invincible_flash_timer = 0.1
		player.modulate.a = 1.0 if player.modulate.a < 1.0 else 0.5

	if invincible_timer <= 0:
		invincible = false
		player.modulate = Color.WHITE

func handle_movement() -> void:
	if knockback_timer > 0:
		return

	# Jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		dust_run.hide()
		dust_run.stop()

		velocity.y = JUMP_VELOCITY
		sound_jump.play()
		play_dust(dust_jump, "jump")

	# Direction
	var direction := Input.get_axis("left", "right")

	if direction:
		velocity.x = direction * SPEED
		player.flip_h = direction < 0

		attack_collision.position.x = -attack_collision_x if player.flip_h else attack_collision_x
		throw_spawn.position.x = -abs(throw_spawn.position.x) if player.flip_h else abs(throw_spawn.position.x)
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
#endregion


#region -> Animation & Particles
func play_normal_animation() -> void:
	if not is_on_floor():
		player.play("jump" if velocity.y < 0 else "fall")
	elif velocity.x != 0:
		player.play("run")
	else:
		player.play("idle")

func play_dust(dust: AnimatedSprite2D, animation: String) -> void:
	dust.show()
	dust.play(animation)

func _on_dust_animation_finished() -> void:
	dust_jump.hide()
	dust_run.hide()

func _on_attack_effect_animation_finished() -> void:
	for effect in attack_effects:
		effect.hide()
#endregion


#region -> Attack
func handle_attack() -> void:
	if not is_on_floor():
		attacking = true
		player.play("aerial_attack")
	elif not attacking:
		attacking = true
		attack_index = 1
		play_ground_attack(1)
	elif attack_index < 3:
		attack_queued = true

func play_ground_attack(index: int) -> void:
	player.play("attack_" + str(index))

	var effect = attack_effects[index - 1]
	effect.flip_h = player.flip_h
	effect.position.x = abs(effect.position.x) * (-1 if player.flip_h else 1)
	effect.show()
	effect.play("attack")

func reset_attack() -> void:
	attacking = false
	attack_queued = false
	attack_index = 0

func _on_animation_finished() -> void:
	if isDead:
		return

	match player.animation:
		"throw", "aerial_attack":
			attacking = false
			play_normal_animation()

		"hit":
			play_normal_animation()

		_:
			if player.animation.begins_with("attack_"):
				if attack_queued and attack_index < 3:
					attack_queued = false
					attack_index += 1
					play_ground_attack(attack_index)
				else:
					reset_attack()

func _on_player_frame_changed() -> void:
	# Ground attack damage
	if player.animation.begins_with("attack_") and player.frame == 1:
		if is_instance_valid(enemy):
			enemy.take_damage(DAMAGE, global_position)

	# Projectile throwing
	if player.animation == "throw" and player.frame == 1:
		var projectile

		match projectileType:
			"knife":
				projectile = scene_knife.instantiate()
			"arrow":
				projectile = scene_arrow.instantiate()
			"bind":
				projectile = scene_bind.instantiate()
				
		get_tree().current_scene.add_child(projectile)

		projectile.global_position = throw_spawn.global_position
		projectile.direction = -1.0 if player.flip_h else 1.0
		projectile.attack_collision.position.x = projectile.attack_collision_x * projectile.direction

		if projectileType == "knife":
			projectile.knife.flip_h = player.flip_h
		elif projectileType == "arrow":
			projectile.arrow.flip_h = !player.flip_h
		elif projectileType == "bind":
			projectile.bind.flip_h = !player.flip_h
#endregion


#region -> Reduce Health
func take_damage(damage: float, attacker_position: Vector2) -> void:
	if invincible or isDead:
		return
	health = maxf(health - damage, 0.0)
	energy.size.x = health

	invincible = true
	invincible_timer = 1.0
	invincible_flash_timer = 0.0

	reset_attack()

	var direction = sign(global_position.x - attacker_position.x)
	velocity = Vector2(direction * KNOCKBACK_FORCE, -KNOCKBACK_UP)
	knockback_timer = 0.2

	if health <= 0:
		isDead = true
		energy.hide()
		player.play("dead")
		sound_death.play()
	else:
		player.play("hit")
#endregion


#region -> Detect Enemy
func _on_attack_area_body_entered(body: Node2D) -> void:
	if body.name.begins_with("fierceTooth"):
		enemy = body

func _on_attack_area_body_exited(body: Node2D) -> void:
	if body == enemy:
		enemy = null
#endregion


#region -> Ability
func handle_abilities() -> void:
	if Input.is_action_just_pressed("attack") and knockback_timer <= 0:
		handle_attack()

	if Input.is_action_just_pressed("swap"):
		#toggle_bubble()
		if projectileType == 'knife':
			projectileType = 'arrow'
			ability_icon.texture = icon_arrow
		elif projectileType == 'arrow':
			projectileType = 'bind'
			ability_icon.texture = icon_bind
		elif projectileType == 'bind':
			projectileType = 'bubble'
			ability_icon.texture = icon_bubble
		elif projectileType == 'bubble':
			projectileType = 'knife'
			ability_icon.texture = icon_knife

	if Input.is_action_just_pressed("shoot"):
		if projectileType == 'knife' or projectileType == 'arrow' or projectileType == 'bind':
			shoot_arrow()
		elif projectileType == 'bubble':
			toggle_bubble()


func toggle_bubble() -> void:
	if bubble_tween:
		bubble_tween.kill()

	bubble_visible = !bubble_visible

	#show
	if bubble_visible: 
		bubble.show()
		bubble.set_physics_process(true)
		bubble.set_collision_layer_value(3, true)
		bubble.set_collision_mask_value(2, true)

		bubble_tween = create_tween()
		bubble_tween.tween_property(bubble, "scale", Vector2.ONE, 0.5)
		bubble_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	#hide
	else:
		bubble_tween = create_tween()
		bubble_tween.tween_property(bubble, "scale", Vector2(0.1, 0.1), 0.3)
		bubble_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		bubble_tween.tween_callback(func():
			bubble.hide()
			bubble.set_physics_process(false)
			bubble.set_collision_layer_value(3, false)
			bubble.set_collision_mask_value(2, false)
		)

func shoot_arrow() -> void:
	attacking = true
	player.play("throw")

func shoot_knife() -> void:
	attacking = true
	player.play("throw")
#endregion
