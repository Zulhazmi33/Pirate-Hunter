extends HBoxContainer

signal item_selected(id: int)

@onready var button1 = $Button_1
@onready var button2 = $Button_2
@onready var button3 = $Button_3

func _ready():
	button1.pressed.connect(func(): select_item(1))
	button2.pressed.connect(func(): select_item(2))
	button3.pressed.connect(func(): select_item(3))


func select_item(id: int):
	print('id = ',id)
	print('item_selected = ',item_selected)
	item_selected.emit(id)
