extends Node2D

@onready var water_reflect_1: Sprite2D = $WaterReflect1
@onready var water_reflect_2: Sprite2D = $WaterReflect2
@onready var water_reflect_3: Sprite2D = $WaterReflect3

var start_x_1: float
var start_x_2: float
var start_x_3: float

@export var speed: float = 2.0
@export var distance: float = 3.0

func _ready() -> void:
	start_x_1 = water_reflect_1.position.x
	start_x_2 = water_reflect_2.position.x
	start_x_3 = water_reflect_3.position.x

func _process(delta: float) -> void:
	water_reflect_1.position.x = start_x_1 + sin(Time.get_ticks_msec() / 1000.0 * speed) * distance
	water_reflect_2.position.x = start_x_2 + sin(Time.get_ticks_msec() / 1000.0 * speed) * distance
	water_reflect_3.position.x = start_x_3 + sin(Time.get_ticks_msec() / 1000.0 * speed) * distance
