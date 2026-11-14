extends CharacterBody2D

#region -> import
# Character
@onready var player: AnimatedSprite2D = $Player
@onready var attack_area: Area2D = $AttackArea
@onready var detection_area: Area2D = $DetectionArea
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

# Sound
@onready var sound_jump: AudioStreamPlayer2D = $Jump
@onready var sound_death: AudioStreamPlayer2D = $Death

# Movement
const SPEED = 300.0
const JUMP_VELOCITY = -900.0

# Health
@onready var energy_health: TextureRect = $Camera2D/lifebar_player/Control/energy_health
var HEALTH := 225.0 #based on actual size of x-axis
var isDead := false
var invincible := false
var invincible_timer := 0.0
var invincible_flash_timer := 0.0

# MANA
@onready var energy_mana: TextureRect = $Camera2D/lifebar_player/Control/energy_mana
const MANA_initial := 260.0 
var MANA := MANA_initial #based on actual size of x-axis
var MANA_regen_rate := 5
var mana_timer: float = 0.0

# Knockback
@export var KNOCKBACK_FORCE: float = 600.0
@export var KNOCKBACK_UP: float = 200.0
var knockback_timer := 0.0

# Shield
@onready var shield: CharacterBody2D = $Shield
var shield_tween: Tween
var shield_visible := false

# Projectile
@export_enum("arrow", "slowed", "shield", "teleport") var projectileType: String = "teleport"
var projectile_types = ["arrow", "slowed", "shield", "teleport"]
@onready var ability_icon: TextureRect = $Camera2D/CanvasLayer/Icon
var icon_arrow = preload("res://assets/images/icon/Arrow.png")
var icon_knife = preload("res://assets/images/icon/Knife.png")
var icon_slowed = preload("res://assets/images/icon/Slowed.png")
var icon_shield = preload("res://assets/images/icon/Shield.png")
var icon_teleport = preload("res://assets/images/icon/Teleport.png")
@export var scene_knife: PackedScene = preload("res://scenes/ability/physical/knife.tscn")
@export var scene_arrow: PackedScene = preload("res://scenes/ability/water/arrow.tscn")
@export var scene_slowed: PackedScene = preload("res://scenes/ability/water/slowed.tscn")
@export var scene_shield: PackedScene = preload("res://scenes/ability/water/shield.tscn")
@onready var throw_spawn: Marker2D = $ThrowSpawn

# Enemy detection
var nearby_enemies: Array[CharacterBody2D] = []
var enemy: CharacterBody2D = null

#Teleport
@export var TELEPORT_DISTANCE: float = 100.0

#endregion


#region -> Starter
func _ready() -> void:
	#immune to 'STOP TIME'
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	ability_icon.texture = icon_teleport
	
	shield.hide()
	shield.scale = Vector2(0.1, 0.1)

	for effect in attack_effects:
		effect.hide()
		effect.animation_finished.connect(_on_attack_effect_animation_finished)

	for dust in [dust_jump, dust_run]:
		dust.hide()
		dust.animation_finished.connect(_on_dust_animation_finished)

	player.animation_finished.connect(_on_animation_finished)
	player.frame_changed.connect(_on_player_frame_changed)
	
	#Detection signals
	detection_area.body_entered.connect(_on_detection_area_body_entered)
	detection_area.body_exited.connect(_on_detection_area_body_exited)
	attack_area.body_entered.connect(_on_attack_area_body_entered)
	attack_area.body_exited.connect(_on_attack_area_body_exited)
#endregion


#region -> Physics
func _physics_process(delta: float) -> void:
	
	#if dead, ignore
	if isDead:
		return
	
	#prevent movement during teleport
	if player.animation == "teleport_down" or player.animation == "teleport_up":
		return
		
	update_invincibility(delta)
	knockback_timer = maxf(knockback_timer - delta, 0.0)

	#gravity
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

func update_direction() -> void:
	throw_spawn.position.x = abs(throw_spawn.position.x) * (-1 if player.flip_h else 1)
	attack_collision.position.x = -attack_collision_x if player.flip_h else attack_collision_x

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
		update_direction()
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
#endregion


#region -> Run_Per_Frame
func _process(delta: float) -> void:
	
	#regen mana per second
	mana_timer += delta
	if mana_timer >= 1.0:
		mana_timer = 0.0

		if MANA < MANA_initial:
			MANA += MANA_regen_rate
			energy_mana.size.x += MANA_regen_rate

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


#region -> Detect Player

func _on_detection_area_body_entered(body: Node2D) -> void:
	if body.name.begins_with("fierceTooth") or body.name.begins_with("pinkStar"):
		nearby_enemies.append(body)


func _on_detection_area_body_exited(body: Node2D) -> void:
	if body in nearby_enemies:
		nearby_enemies.erase(body)
	
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
		"throw", "shoot", "aerial_attack":
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
	if player.frame == 2 and (player.animation == "throw" or player.animation == "shoot"):
		var projectile
		
		if player.animation == "throw":
			projectile = scene_knife.instantiate()
			get_tree().current_scene.add_child(projectile)
			projectile.global_position = throw_spawn.global_position
			projectile.direction = -1.0 if player.flip_h else 1.0
			projectile.attack_collision.position.x = abs(projectile.attack_collision_x) * projectile.direction
			projectile.knife.flip_h = player.flip_h
			
		elif player.animation == "shoot":

			match projectileType:
				"arrow":
					projectile = scene_arrow.instantiate()
				"slowed":
					projectile = scene_slowed.instantiate()
					
			get_tree().current_scene.add_child(projectile)

			#reduce mana
			var reduce_mana = maxf(MANA - projectile.mana_cost, 0.0)
			if reduce_mana >= 32.0:
				MANA = reduce_mana
				energy_mana.size.x = reduce_mana
			
			#shoot
			projectile.global_position = throw_spawn.global_position
			projectile.direction = -1.0 if player.flip_h else 1.0
			projectile.attack_collision.position.x = abs(projectile.attack_collision_x) * projectile.direction
			
			projectile.projectile.flip_h = !player.flip_h
			
#endregion


#region -> Reduce Health
func take_damage(damage: float, attacker_position: Vector2) -> void:
	if invincible or isDead:
		return
	HEALTH = maxf(HEALTH - damage, 0.0)
	energy_health.size.x = HEALTH

	invincible = true
	invincible_timer = 1.0
	invincible_flash_timer = 0.0

	reset_attack()

	var direction = sign(global_position.x - attacker_position.x)
	velocity = Vector2(direction * KNOCKBACK_FORCE, -KNOCKBACK_UP)
	knockback_timer = 0.2

	if HEALTH <= 0:
		isDead = true
		energy_health.hide()
		player.play("dead")
		sound_death.play()
	else:
		player.play("hit")
#endregion


#region -> Detect Enemy
func _on_attack_area_body_entered(body: Node2D) -> void:
	if body.name.begins_with("fierceTooth") or body.name.begins_with("pinkStar"):
		enemy = body

func _on_attack_area_body_exited(body: Node2D) -> void:
	if body == enemy:
		enemy = null
#endregion


#region -> Ability
func handle_abilities() -> void:
	if Input.is_action_just_pressed("attack") and knockback_timer <= 0:

		# Check whether LEFT or RIGHT is pressed
		if Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_RIGHT):
			throw_projectile()
		else:
			handle_attack()

	if Input.is_action_just_pressed("swap"):
		var current_index = projectile_types.find(projectileType)
		current_index = (current_index + 1) % projectile_types.size()

		projectileType = projectile_types[current_index]
		ability_icon.texture = get_projectile_icon(projectileType)

	if Input.is_action_just_pressed("spell"):
		if projectileType == "arrow" or projectileType == "slowed":
			shoot_projectile()
		elif projectileType == "shield":
			toggle_shield()
		elif projectileType == "teleport" and is_on_floor():
			teleport_to_random_enemy()

func toggle_shield() -> void:
	if shield_tween:
		shield_tween.kill()

	shield_visible = !shield_visible

	#show
	if shield_visible: 
		
		#reduce mana
		var mana_cost = scene_shield.instantiate().mana_cost
		var reduce_mana = maxf(MANA - mana_cost, 0.0)
		if reduce_mana >= 32.0:
			MANA = reduce_mana
			energy_mana.size.x = reduce_mana
		else:
			return
		
		shield.show()
		shield.set_physics_process(true)
		shield.set_collision_layer_value(3, true)
		shield.set_collision_mask_value(2, true)

		shield_tween = create_tween()
		shield_tween.tween_property(shield, "scale", Vector2.ONE, 0.5)
		shield_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	#hide
	else:
		
		shield_tween = create_tween()
		shield_tween.tween_property(shield, "scale", Vector2(0.1, 0.1), 0.3)
		shield_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		shield_tween.tween_callback(func():
			shield.hide()
			shield.set_physics_process(false)
			shield.set_collision_layer_value(3, false)
			shield.set_collision_mask_value(2, false)
		)

func shoot_projectile() -> void:
	attacking = true
	player.play("shoot")
func throw_projectile() -> void:
	attacking = true
	player.play("throw")
	
func get_projectile_icon(type: String) -> Texture2D:
	match type:
		"arrow":
			return icon_arrow
		"slowed":
			return icon_slowed
		"shield":
			return icon_shield
		"teleport":
			return icon_teleport

	return null

func teleport_to_random_enemy() -> void:
	
	#reduce mana
	var mana_cost = 20.0
	var reduce_mana = maxf(MANA - mana_cost, 0.0)
	if reduce_mana >= 32.0:
		MANA = reduce_mana
		energy_mana.size.x = reduce_mana
	else:
		return
	
	nearby_enemies = nearby_enemies.filter(func(target): return is_instance_valid(target))

	if nearby_enemies.is_empty():
		return

	enemy = nearby_enemies.pick_random()

	var enemy_sprite = enemy.get_node("Monster") as AnimatedSprite2D
	var direction = 1.0 if enemy_sprite.flip_h else -1.0

	attacking = true
	get_tree().paused = true

	# Disappear
	player.play("teleport_down")
	await player.animation_finished

	if not is_instance_valid(enemy):
		attacking = false
		get_tree().paused = false
		return

	# Teleport behind enemy
	global_position = enemy.global_position + Vector2(-direction * TELEPORT_DISTANCE, 0)

	# Face enemy
	player.flip_h = enemy_sprite.flip_h

	# Update positions
	update_direction()

	# Appear
	player.play("teleport_up")
	await player.animation_finished

	attacking = false
	get_tree().paused = false

	play_normal_animation()

#endregion
