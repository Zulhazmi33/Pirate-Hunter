extends CharacterBody2D

# character
@onready var player: AnimatedSprite2D = $Player_attack

# dust particle
@onready var dust_jump: AnimatedSprite2D = $Dust_particle/Dust_jump
@onready var dust_run: AnimatedSprite2D = $Dust_particle/Dust_run

# sword effects
@onready var dust_attack_1: AnimatedSprite2D = $Attack_effect/attack_1
@onready var dust_attack_2: AnimatedSprite2D = $Attack_effect/attack_2
@onready var dust_attack_3: AnimatedSprite2D = $Attack_effect/attack_3

# sound
@onready var sound_jump: AudioStreamPlayer2D = $Jump
@onready var sound_death: AudioStreamPlayer2D = $Death

# physics
const SPEED = 300.0
const JUMP_VELOCITY = -900.0

# attack combo
var attack_index := 0
var attacking := false
var attack_queued := false

# dust
var was_on_floor := false

# attack effects
var attack_effects: Array[AnimatedSprite2D]

# =========================
# START
# =========================
func _ready() -> void:
	attack_effects = [
		dust_attack_1,
		dust_attack_2,
		dust_attack_3
	]

	# Hide particles/effects
	dust_jump.visible = false
	dust_run.visible = false

	for effect in attack_effects:
		effect.visible = false
		effect.animation_finished.connect(_on_attack_effect_animation_finished)

	# Animation signals
	player.animation_finished.connect(_on_animation_finished)
	dust_jump.animation_finished.connect(_on_dust_animation_finished)
	dust_run.animation_finished.connect(_on_dust_animation_finished)
func _physics_process(delta: float) -> void:

	# 1) Gravity
	if not is_on_floor():
		velocity += get_gravity() * delta

	# 2) Jump
	if Input.is_action_just_pressed("jump") and is_on_floor():

		# Stop running dust
		dust_run.stop()
		dust_run.visible = false
		#Jump
		velocity.y = JUMP_VELOCITY
		sound_jump.play()

		# Play jump dust
		play_dust(dust_jump, "jump")
		
	# 3) Direction
	var direction := Input.get_axis("left", "right")

	if direction:
		#Direction
		velocity.x = direction * SPEED
		player.flip_h = direction < 0

		# Run dust (KIV)
		#if is_on_floor() and not attacking and not Input.is_action_just_pressed("jump"):
			#dust_run.flip_h = player.flip_h
			#play_dust(dust_run, "run")
		#else:
			#dust_run.stop()
			#dust_run.visible = false

	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		
	# 4) Attack
	if Input.is_action_just_pressed("attack"):
		handle_attack()

	# 5) Move player
	move_and_slide()

	# 6) Cancel aerial attack when landing
	if attacking and player.animation == "aerial_attack" and is_on_floor():
		attacking = false
		attack_index = 0
		attack_queued = false

	# 7) Normal animation
	if not attacking:
		play_normal_animation()

	was_on_floor = is_on_floor()


# =========================
# ATTACK
# =========================
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
	player.play("attack_" + str(index))
	play_attack_effect(index)
func play_attack_effect(index: int) -> void:
	var effect = attack_effects[index - 1]

	effect.flip_h = player.flip_h
	effect.position.x = abs(effect.position.x) * (-1 if player.flip_h else 1)
	effect.visible = true
	effect.play("attack")


# =========================
# NORMAL ANIMATION
# =========================
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


# =========================
# ANIMATION FINISHED
# =========================
func _on_animation_finished() -> void:

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


# =========================
# DUST
# =========================
func play_dust(dust: AnimatedSprite2D, animation: String) -> void:
	dust.visible = true
	dust.play(animation)
func _on_dust_animation_finished() -> void:
	dust_jump.visible = false
	dust_run.visible = false


# =========================
# ATTACK EFFECT
# =========================
func _on_attack_effect_animation_finished() -> void:
	for effect in attack_effects:
		effect.visible = false
