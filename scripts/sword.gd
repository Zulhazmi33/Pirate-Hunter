extends CharacterBody2D

@onready var knife: AnimatedSprite2D = $AnimatedSprite2D

# detection
@onready var attack_area: Area2D = $AttackArea
@onready var original_position: Vector2 = knife.position
var enemy: CharacterBody2D = null

const SPEED = 700.0
@export var DAMAGE: float = 50.0
var direction: float = 1.0


var is_stopped: bool = false

#attack_collision
@onready var attack_collision: CollisionShape2D = $AttackArea/Collision
@onready var attack_collision_x: float = abs(attack_collision.position.x)

func _ready() -> void:
	attack_area.body_entered.connect(_on_attack_area_body_entered)
	attack_area.body_exited.connect(_on_attack_area_body_exited)

func _physics_process(delta: float) -> void:
	if is_stopped:
		return

	velocity.x = direction * SPEED
	move_and_slide()

	if is_on_wall():
		velocity = Vector2.ZERO
		is_stopped = true
		knife.pause()

func _on_attack_area_body_entered(body):
	if body.name.begins_with("TileMapLayer"):
		velocity = Vector2.ZERO
		is_stopped = true
		knife.play("embedded")
		
		# Change embedded animation position depending on 'direction'
		knife.position.x = 20 * direction

	elif body.name.begins_with("fierceTooth"):
		enemy = body
		enemy.take_damage(DAMAGE, global_position)
		queue_free()

func _on_attack_area_body_exited(body):
	enemy = null
