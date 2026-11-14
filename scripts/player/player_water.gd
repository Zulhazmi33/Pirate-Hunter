extends RefCounted

#region -> Import
@export var scene_arrow: PackedScene = preload("res://scenes/ability/water/arrow.tscn")
@export var scene_knife: PackedScene = preload("res://scenes/ability/physical/knife.tscn")
@export var scene_slowed: PackedScene = preload("res://scenes/ability/water/slowed.tscn")
@export var scene_shield: PackedScene = preload("res://scenes/ability/water/shield.tscn")

# b. node
var throw_spawn: Marker2D
var original_spawn_position: Vector2

# c. variable
var attribute
var enemy
var TELEPORT_DISTANCE: float = 100.0

#endregion

func setup(player: CharacterBody2D, shared_attribute) -> void:
	attribute = shared_attribute

	throw_spawn = player.get_node("ThrowSpawn")
	original_spawn_position = throw_spawn.position


func shoot(player: AnimatedSprite2D, type: String) -> void:
	var projectile;
	
	#a. Choose arrow
	if type == 'arrow':
		projectile = scene_arrow.instantiate()
	elif type == 'slowed':
		projectile = scene_slowed.instantiate()
		
	# b. Use mana	
	var has_mana = attribute.mana_reduce(projectile.mana_cost);
	
	if has_mana:
		# a. Get scene	
		player.get_tree().current_scene.add_child(projectile)
		# b. Change marker position based on player direction
		throw_spawn.position.x = abs(original_spawn_position.x) * (-1 if player.flip_h else 1)
		# c. Spawn position
		projectile.global_position = throw_spawn.global_position
		# d. Direction
		projectile.direction = -1.0 if player.flip_h else 1.0
		# e. Collision direction
		projectile.attack_collision.position.x = abs(projectile.attack_collision_x) * projectile.direction
		# f. Sprite direction
		projectile.projectile.flip_h = !player.flip_h

func teleport_to_random_enemy(player: AnimatedSprite2D, player_body: CharacterBody2D, game_tree: SceneTree,  nearby_enemies: Array) -> void:
	
	# 1. remove if enemy already die
	nearby_enemies = nearby_enemies.filter(func(target): return is_instance_valid(target))
	
	# 2. if no enemy, ignore
	if nearby_enemies.is_empty():
		return
		
	# 3a. Pick random enemy
	#enemy = nearby_enemies.pick_random()
	# 3a. Pick farthest enemy
	enemy = nearby_enemies[0]

	for target in nearby_enemies:
		if player_body.global_position.distance_to(target.global_position) > player_body.global_position.distance_to(enemy.global_position):
			enemy = target

	# 4. Get enemy's position
	var enemy_sprite = enemy.get_node("Monster") as AnimatedSprite2D
	var direction = 1.0 if enemy_sprite.flip_h else -1.0

	# 5. reduce mana
	var mana_cost = 20.0
	var has_mana = attribute.mana_reduce(mana_cost)
	if has_mana:
		# 1. Stop time
		game_tree.paused = true

		# 2a. Disappear
		player.play("teleport_down")
		await player.animation_finished

		# 2. Teleport behind enemy
		player_body.global_position = enemy.global_position + Vector2(-direction * TELEPORT_DISTANCE, 0)
		# 2c. Face enemy
		player.flip_h = !enemy_sprite.flip_h
		# 2d Update throw positions
		throw_spawn.position.x = abs(throw_spawn.position.x) * (-1 if player.flip_h else 1)

		# 3a. Appear
		player.play("teleport_up")
		await player.animation_finished
		# 3b. Start time
		game_tree.paused = false
	
