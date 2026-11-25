extends CharacterBody2D

#region -> Import
@onready var projectile: AnimatedSprite2D = $AnimatedSprite2D
var player: AnimatedSprite2D

# direction
var direction: float = 1.0
const SPEED = 700
const DAMAGE = 30
const FORCE = 0.0

#normal collision
@onready var collision: CollisionShape2D = $Collision
@onready var collision_x: float = abs(collision.position.x)

#attack_collision
@onready var attack_collision: CollisionShape2D = $AttackArea/Collision
@onready var attack_collision_x: float = abs(attack_collision.position.x)

#switch/condition
var is_embedded = false

#endregion

#region 1) -> Physic
func _physics_process(delta: float) -> void:
	velocity.x = direction * SPEED
	move_and_slide()

#endregion

#region 2) -> Signal
func _on_attack_area_body_entered(body: Node2D) -> void:	
	# a. wall
	if body.name.begins_with("TileMapLayer"):
		stuck(body, "wall")
	# b. enemy
	elif Global.monster_list(body):
		#body.take_damage(DAMAGE, global_position)
		if !body.monster.is_dead:
			body.monster.health_reduce(DAMAGE, FORCE, global_position)
			stuck(body, "monster")

#endregion


#region 3) -> method
func stuck(target: Node2D, type: String) -> void:

	if type == 'wall':
		# stop movement
		velocity = Vector2.ZERO
		set_physics_process(false)
		projectile.play("stuck")

		# disable attack collision
		attack_collision.set_deferred("disabled", true)
		
	elif type == 'monster':
		 #prevent multiple embedding
		if is_embedded:
			return
		is_embedded = true

		# stop movement
		velocity = Vector2.ZERO
		set_physics_process(false)

		# disable attack collision
		attack_collision.set_deferred("disabled", true)

		# play animation
		projectile.play("stuck")

		# remember current position
		var current_position = global_position

		# attach to enemy/wall
		call_deferred("attach_knife", target, current_position)

func attach_knife(target: Node2D, current_position: Vector2) -> void:
	
	# remove from current parent
	get_parent().remove_child(self)

	# attach knife to enemy
	target.add_child(self)
	
	# maintain original world position
	global_position = current_position

func store_player(Player: AnimatedSprite2D) -> void:
	player = Player
		#if throw_raycast.is_colliding():
			#print("Clashed with wall / TileMapLayer")
		#else:
			#print("No collision")
	
#endregion
