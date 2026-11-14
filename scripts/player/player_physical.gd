extends RefCounted

#region -> Import
# a. import
@export var scene_knife: PackedScene = preload("res://scenes/ability/physical/knife.tscn")
var attack_area: Area2D

# b. node
var throw_spawn: Marker2D
var original_spawn_position: Vector2

# c. knife
const ammo_limit = 3
var AMMO = ammo_limit
var ammo_icon = []

#endregion

func setup(parent: CharacterBody2D) -> void:
	
	# a. get node
	attack_area = parent.get_node("AttackArea")
	throw_spawn = parent.get_node("ThrowSpawn")
	
	# b. throw position
	original_spawn_position = throw_spawn.position
	
	# c. get ammo icon
	ammo_icon = [
		parent.get_node("Camera2D/Knife/Control/ammo_1"),
		parent.get_node("Camera2D/Knife/Control/ammo_2"),
		parent.get_node("Camera2D/Knife/Control/ammo_3"),
		parent.get_node("Camera2D/Knife/Control/ammo_4"),
		parent.get_node("Camera2D/Knife/Control/ammo_5"),
		parent.get_node("Camera2D/Knife/Control/ammo_6"),
		parent.get_node("Camera2D/Knife/Control/ammo_7")
	]

#detect enemy
func detect_enemy() -> void:
	for body in attack_area.get_overlapping_bodies():
		if body.name.begins_with("fierceTooth") or body.name.begins_with("pinkStar"):
			print("KILL")

#ammo
func ammo_initialise() -> void:
	for i in range(ammo_icon.size()):
		ammo_icon[i].visible = i < AMMO

func ammo_reduce() -> void:
	AMMO -= 1
	for i in range(ammo_icon.size()):
		ammo_icon[i].visible = i < AMMO
		
func ammo_increase(knife: CharacterBody2D) -> void:
	AMMO += 1
	for i in range(ammo_icon.size()):
		ammo_icon[i].visible = i < AMMO
	knife.queue_free()
	
#throw knife	
func throw(player: AnimatedSprite2D) -> void:
	var projectile = scene_knife.instantiate()
	
	if AMMO != 0 :
		# a. reduce ammo
		ammo_reduce()
		# b. Get scene	
		player.get_tree().current_scene.add_child(projectile)
		# c. Change marker position based on player direction
		throw_spawn.position.x = abs(original_spawn_position.x) * (-1 if player.flip_h else 1)
		# d. Spawn position
		projectile.global_position = throw_spawn.global_position
		# e. Direction
		projectile.direction = -1.0 if player.flip_h else 1.0
		# f. Collision direction
		projectile.attack_collision.position.x = abs(projectile.attack_collision_x) * projectile.direction
		# g. Sprite direction
		projectile.projectile.flip_h = player.flip_h
