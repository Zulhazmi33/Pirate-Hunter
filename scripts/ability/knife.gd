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
var embedded := false

#attack_collision
@onready var attack_collision: CollisionShape2D = $AttackArea/Collision
@onready var attack_collision_x: float = abs(attack_collision.position.x)

func _process(_delta: float) -> void:
	if not embedded:
		return

	if is_instance_valid(enemy) and enemy.isDead:
		queue_free()
			
func _ready() -> void:
	attack_area.body_entered.connect(_on_attack_area_body_entered)
	attack_area.body_exited.connect(_on_attack_area_body_exited)

func _physics_process(delta: float) -> void:
	if is_stopped:
		return

	velocity.x = direction * SPEED
	move_and_slide()

	if is_on_wall():
		#velocity = Vector2.ZERO
		#is_stopped = true
		#knife.pause()
		embed_knife(get_last_slide_collision().get_collider())

func _on_attack_area_body_entered(body):
	if body.name.begins_with("TileMapLayer"):
		embed_knife(body)

	elif body.name.begins_with("fierceTooth") or body.name.begins_with("pinkStar"):
		enemy = body
		enemy.take_damage(DAMAGE, global_position)
		embed_knife(body)


func embed_knife(target: Node2D) -> void:
	if embedded:
		return

	embedded = true
	velocity = Vector2.ZERO
	is_stopped = true

	# Disable collision detection
	attack_area.set_deferred("monitoring", false)
	attack_collision.set_deferred("disabled", true)

	# Stop physics movement
	set_physics_process(false)

	# Play embedded animation
	knife.play("embedded")

	# Remember current position
	var current_position = global_position

	# Attach to monster/wall
	call_deferred("attach_knife", target, current_position)

func attach_knife(target: Node2D, current_position: Vector2) -> void:
	if not is_instance_valid(target):
		return

	reparent(target)
	global_position = current_position

	# Position embedded knife
	knife.position.x = 20 * direction

func _on_attack_area_body_exited(body):
	if body == enemy and not embedded:
		enemy = null
