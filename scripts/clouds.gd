extends Node2D

#import
@onready var small_cloud_1: Sprite2D = $SmallCloud1
@onready var small_cloud_2: Sprite2D = $SmallCloud2
@onready var small_cloud_3: Sprite2D = $SmallCloud3
@onready var small_cloud_4: Sprite2D = $SmallCloud4
@onready var small_cloud_5: Sprite2D = $SmallCloud5
@onready var small_cloud_6: Sprite2D = $SmallCloud6
@onready var small_cloud_7: Sprite2D = $SmallCloud7
@onready var small_cloud_8: Sprite2D = $SmallCloud8
@onready var small_cloud_9: Sprite2D = $SmallCloud9

#speed
@export var speed_0: float = 30.0
@export var speed_1: float = 15.0
@export var speed_2: float = 30.0
@export var speed_3: float = 25.0
@export var speed_4: float = 30.0
@export var speed_5: float = 30.0
@export var speed_6: float = 20.0
@export var speed_7: float = 35.0
@export var speed_8: float = 25.0
@export var speed_9: float = 15.0

func _process(delta: float) -> void:
	small_cloud_1.position.x -= speed_1 * delta
	small_cloud_2.position.x -= speed_2 * delta
	small_cloud_3.position.x -= speed_3 * delta
	small_cloud_4.position.x -= speed_4 * delta
	small_cloud_5.position.x -= speed_5 * delta
	small_cloud_6.position.x -= speed_6 * delta
	small_cloud_7.position.x -= speed_7 * delta
	small_cloud_8.position.x -= speed_8 * delta
	small_cloud_9.position.x -= speed_9 * delta
