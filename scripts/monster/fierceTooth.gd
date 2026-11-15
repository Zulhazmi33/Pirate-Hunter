extends CharacterBody2D

#region 0) -> Import
var monster = preload("res://scripts/monster/monster.gd").new()
var player: Node2D = null

#endregion

#region 1) -> Starter
func _ready() -> void:
	# a. initialized classes
	monster.setup(self)

#endregion

#region 2) -> Process
func _physics_process(delta: float) -> void:
	
	# a. instantiate movement
	monster._physics_process(delta)

	# b. detect player
	if is_instance_valid(player):
		if monster.detect_player(player):
			var is_chasing = await monster.alert()
			#if is_chasing:
				#monster.chasing(player)
				
		else:
			pass

#endregion


#region 4) -> Signal
func _on_detection_area_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		player = body

func _on_detection_area_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		player = null
		monster.is_alerted = false
		monster.is_attacking = false
	
#endregion
