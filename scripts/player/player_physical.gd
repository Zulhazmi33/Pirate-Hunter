extends RefCounted

#region -> Import
# a. import
@export var scene_knife: PackedScene = preload("res://scenes/ability/physical/knife.tscn")
var attack_area: Area2D

# b. node
var throw_spawn: Marker2D
var original_spawn_position: Vector2
var throw_raycast: RayCast2D

# c. knife
const ammo_limit = 5
var AMMO = ammo_limit
var ammo_icon = []

#endregion

func setup(parent: CharacterBody2D) -> void:
	
	# a. get node
	attack_area = parent.get_node("AttackArea")
	throw_spawn = parent.get_node("ThrowSpawn")
	throw_raycast = parent.get_node("RayCast2D")
	
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


#region 1) -> Knife
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
	
func throw(player: AnimatedSprite2D) -> void:
	var projectile = scene_knife.instantiate()
	
	if AMMO != 0 :
		
		# a. reduce ammo
		ammo_reduce()
		# b. Get scene	
		player.get_tree().current_scene.add_child(projectile)
		# c. Change marker position based on player direction
		throw_spawn.position.x = abs(original_spawn_position.x) * (-1 if player.flip_h else 1)
		# d. Direction
		projectile.direction = -1.0 if player.flip_h else 1.0
		# e. Collision direction (normal)
		projectile.attack_collision.position.x = abs(projectile.attack_collision_x) * projectile.direction
		# f. Collision direction (attack area)
		projectile.collision.position.x = abs(projectile.collision_x) * projectile.direction
		# h. Sprite direction
		projectile.projectile.flip_h = player.flip_h
		
		
		# i. a. If collide, spawn at collision point
		if throw_raycast.is_colliding():
			var target = throw_raycast.get_collider()
			var move_back = 40 # elak error
			
			projectile.global_position = throw_raycast.get_collision_point() - Vector2(move_back * projectile.direction, 0)
			
			# Check collision type
			if target.name.begins_with("TileMapLayer"):
				projectile.stuck(target, "wall")
			else:
				projectile.stuck(target, "monster")
			return
		
		# i. b. Spawn position
		projectile.global_position = throw_spawn.global_position

		
		
#endregion	
