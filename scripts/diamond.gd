extends Area2D

@export var collectible_type: String;
@onready var sprite: AnimatedSprite2D = $object

func _ready():
	sprite.play(collectible_type)
