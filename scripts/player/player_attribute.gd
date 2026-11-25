extends RefCounted

#region 0) -> variable

#1. PLayer
var player_body: CharacterBody2D
var player_sprite: AnimatedSprite2D
var sound_death: AudioStreamPlayer2D

#2. Health
var HEALTH := 350 # FIX for now
var energy_health: TextureRect

#3. Mana
var energy_mana: TextureRect
const mana_limit := 350.0 
var mana_regen_rate := 5.0
var mana_timer: float = 0.0
var MANA := mana_limit #based on actual size of x-axis

#4. Switch
var is_dead = false
var is_knockback = false
var is_attacked = false

#endregion

#region 1) -> Setup
func setup(player: CharacterBody2D) -> void:
	player_body = player
	player_sprite = player.get_node("Player")
	
	sound_death = player.get_node("Death")
	
	energy_health = player.get_node("Camera2D/Lifebar_player/Control/energy_health")
	energy_mana = player.get_node("Camera2D/Lifebar_player/Control/energy_mana")

#endregion


#region 2) -> Health
func health_reduce(DAMAGE: float, FORCE: float, player_position: Vector2) -> void:
	if is_dead:
		return

	# a. Knockback/push enemy away from player
	var direction = sign(player_body.global_position.x - player_position.x)
	is_knockback = true
	player_body.velocity.x = direction * FORCE
	
	# b. Die
	if (HEALTH - DAMAGE) < 32:
		player_body.set_collision_layer_value(1, false)
		
		is_dead = true
		energy_health.hide()
		sound_death.play()
		player_sprite.play("dead")

	# c. Take damage
	else:
		HEALTH -= DAMAGE
		energy_health.size.x = HEALTH
		
		is_attacked = true
		player_body.set_collision_layer_value(1, false)
		
		player_sprite.play("hit")
		await player_sprite.animation_finished
		
		is_attacked = false
		player_body.set_collision_layer_value(1, true)

#endregion


#region 3) -> Mana
func mana_reduce(mana_cost: float) -> bool:
	var reduce_mana = maxf(MANA - mana_cost, 0.0)
	if reduce_mana >= 32.0:
		MANA = reduce_mana
		energy_mana.size.x = reduce_mana
		return true
	else :
		return false

func mana_regen(delta) -> void :
	mana_timer += delta
	if mana_timer >= 1.0:
		mana_timer = 0.0
		if MANA < mana_limit:
			MANA += mana_regen_rate
			energy_mana.size.x += mana_regen_rate
#endregion
