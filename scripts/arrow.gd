extends CharacterBody2D

@onready var arrow: AnimatedSprite2D = $AnimatedSprite2D

#detection
#@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var attack_area: Area2D = $AttackArea
var enemy: CharacterBody2D = null

const SPEED = 700.0
var direction: float = 1.0

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
	print(body)
	if body.name.begins_with("fierceTooth"):
		enemy = body

func _on_attack_area_body_exited(body):
	enemy = null
