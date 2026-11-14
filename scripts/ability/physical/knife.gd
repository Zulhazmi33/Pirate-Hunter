extends CharacterBody2D

#region -> Import
@onready var projectile: AnimatedSprite2D = $AnimatedSprite2D

# direction
var direction: float = 1.0
const SPEED = 700

#attack_collision
@onready var attack_collision: CollisionShape2D = $AttackArea/Collision
@onready var attack_collision_x: float = abs(attack_collision.position.x)

#switch/condition
var is_embedded = false

#endregion

func _physics_process(delta: float) -> void:
	velocity.x = direction * SPEED
	move_and_slide()

func _on_attack_area_body_entered(body: Node2D) -> void:
	if body.name.begins_with("TileMapLayer"):
		stuck(body)

	elif body.name.begins_with("fierceTooth") or body.name.begins_with("pinkStar"):
		#enemy.take_damage(DAMAGE, global_position)
		stuck(body)

func stuck(target: Node2D) -> void:
	
	#stop movement
	velocity = Vector2.ZERO
	set_physics_process(false)
	projectile.play("stuck")
	
	#disable attack collision
	attack_collision.set_deferred("disabled", true)
