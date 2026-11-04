extends Area2D

@export var collectible_type: String;
@onready var coin: AnimatedSprite2D = $object
@onready var sound_collected: AudioStreamPlayer2D = $Collected

signal collected

func _on_body_entered(_body: Node2D) -> void:
	sound_collected.play()	
	coin.animation = "collected"
	collected.emit()
	call_deferred("_disable_collision")
	
func _disable_collision() -> void:
	coin.disabled = true

func _on_animated_sprite_2d_animation_looped() -> void:
	if coin.animation == "collected":
		queue_free()
