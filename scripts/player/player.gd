
extends CharacterBody2D

#region 0) -> Variable

# 1. Import
@onready var player: AnimatedSprite2D = $Player
@onready var sound_jump: AudioStreamPlayer2D = $Jump
@onready var attack_area: Area2D = $AttackArea
var nearby_enemies: Array[CharacterBody2D] = []

var physical = preload("res://scripts/player/player_physical.gd").new()
var water_magic = preload("res://scripts/player/player_water.gd").new()
var icon = preload("res://scripts/player/player_icon.gd").new()
var attribute = preload("res://scripts/player/player_attribute.gd").new()

# 2. Attribute
const SPEED = 300.0
const JUMP_VELOCITY = -900.0
const attackArea_position = 50

# 3. Switch/Condition
var is_attacking = false

#endregion



#region 1) -> Starter
func _ready() -> void:
	#initialized classes
	attribute.setup(self)
	icon.setup(self)
	physical.setup(self)
	water_magic.setup(self, attribute)
	
	#immune to 'time stop'
	player.process_mode = Node.PROCESS_MODE_ALWAYS
	
	#initialise collision
	attack_area.position.x = attackArea_position
	
#endregion


#region 2) -> Process
func _process(delta: float) -> void:
	#mana regen
	attribute.mana_regen(delta)
#endregion


#region 3) -> Physics
func _physics_process(delta: float) -> void:
		
	#region a) -> Built-in
		move_and_slide()
	#endregion
	
	#region b) -> Movement
		# Jump
		if Input.is_action_just_pressed("jump"):
			if is_on_floor():
				velocity.y = JUMP_VELOCITY
				sound_jump.play()
				
		# Fall
		if not is_on_floor():
			velocity += get_gravity() * delta
			
		# Left/right
		var direction := Input.get_axis("left", "right")
		if direction:
			velocity.x = direction * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
	#endregion

	#region c) -> Direction
		if direction == 1.0:
			player.flip_h = false
			attack_area.position.x = attackArea_position
		elif direction == -1.0:
			player.flip_h = true
			attack_area.position.x = -attackArea_position
	#endregion

	#region d) -> Attack (physical)
		if Input.is_action_just_pressed("attack"):
			if not is_attacking:
				print('attack')
				is_attacking = true
				player.play("attack_1")
				physical.detect_enemy()
	#endregion
	
	#region e) -> Attack (water magic)
		# 'swap'
		if Input.is_action_just_pressed("swap"):
			icon.swap()
		# 'trigger'
		if Input.is_action_just_pressed("spell"):
			if not is_attacking:
				#a) shoot
				if icon.getType() == 'arrow' or icon.getType() == 'slowed':
					is_attacking = true
					player.play("shoot")
				#b) teleport
				elif icon.getType() == "teleport":
					if is_on_floor():
						is_attacking = true
						await water_magic.teleport_to_random_enemy(player, self, get_tree(), nearby_enemies)
						is_attacking = false
	#endregion
	
	#region LAST) -> Animation
		if is_attacking:        
			pass
			
		#Jump
		elif not is_on_floor():
			if velocity.y < 0:
				player.play("jump")
			else:
				player.play("fall")
		#Move
		elif velocity.x != 0:
			player.play("run")
		else:
			player.play("idle")
	#endregion
	
#endregion


#region 4) -> Signal

func _on_player_animation_finished() -> void:
	if player.animation == "attack_1":
		is_attacking = false
	if player.animation == "shoot":
		is_attacking = false
	
func _on_player_frame_changed() -> void:
	if player.animation == "shoot":
		if player.frame == 1:
			water_magic.shoot(player, icon.getType())

func _on_detection_area_body_entered(body: Node2D) -> void:
	if body.name.begins_with("fierceTooth") or body.name.begins_with("pinkStar"):
		nearby_enemies.append(body)

func _on_detection_area_body_exited(body: Node2D) -> void:
	if body in nearby_enemies:
		nearby_enemies.erase(body)
	
#endregion
