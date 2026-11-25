
extends CharacterBody2D

#region 0) -> Import
var monster = preload("res://scripts/monster/monster.gd").new()
var player: Node2D = null

const DAMAGE = 100
const FORCE = 300.0

#endregion

#region 1) -> Starter
func _ready() -> void:
	# a. initialized classes
	monster.setup(self)
	monster.attackArea_position = 0.0

#endregion

#region 2) -> Process
func _physics_process(delta: float) -> void:

	# a. instantiate movement
	if not monster.is_attacking:
		monster._physics_process(delta)

	# b. detect player
	if is_instance_valid(player) and not monster.is_attacking:
		if monster.detect_player(player):
			var can_attack = await monster.alert_animation()

			if can_attack:
				monster.spinning()

#endregion

#region 4) -> Signal
func _on_detection_area_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		player = body

func _on_detection_area_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		player = null
		monster.is_alerted = false

func _on_attack_area_body_entered(body: Node2D) -> void:
	if body.name == "Player" and monster.is_attacking:
		body.attribute.health_reduce(DAMAGE, FORCE, global_position)

	
#endregion
