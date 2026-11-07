extends CharacterBody2D

@onready var slowed: AnimatedSprite2D = $AnimatedSprite2D

#detection
@onready var attack_area: Area2D = $AttackArea
var enemy: CharacterBody2D = null

const SPEED = 300.0
@export var DAMAGE: float = 0.0
var direction: float = 1.0

#attack_collision
@onready var attack_collision: CollisionShape2D = $AttackArea/Collision
@onready var attack_collision_x: float = abs(attack_collision.position.x)

func _ready() -> void:
	# Detect attack range
	attack_area.body_entered.connect(_on_attack_area_body_entered)
	attack_area.body_exited.connect(_on_attack_area_body_exited)

func _physics_process(delta: float) -> void:
	velocity.x = direction * SPEED
	move_and_slide()

	if is_on_wall():
		queue_free()
		
func _on_attack_area_body_entered(body):
	if body.name.begins_with("TileMapLayer"):
		queue_free()
		
	elif body.name.begins_with("fierceTooth"):
		enemy = body
		
		#enemy.take_damage(DAMAGE, global_position)
		enemy.slow_movement()
		queue_free()
		
func _on_attack_area_body_exited(body):
	enemy = null
