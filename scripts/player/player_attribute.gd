extends RefCounted

#1. Mana
var energy_mana: TextureRect
const mana_initial := 260.0 
var mana_regen_rate := 5.0
var mana_timer: float = 0.0
var MANA := mana_initial #based on actual size of x-axis

func setup(player: CharacterBody2D) -> void:
	energy_mana = player.get_node("Camera2D/lifebar_player/Control/energy_mana")

#region -> Mana
func mana_reduce(mana_cost: float) -> bool:
	var reduce_mana = maxf(MANA - mana_cost, 0.0)
	if reduce_mana >= 32.0:
		MANA = reduce_mana
		energy_mana.size.x = reduce_mana
		return true
	else :
		return false

func mana_regen(delta) -> void :
	mana_timer += delta
	if mana_timer >= 1.0:
		mana_timer = 0.0
		if MANA < mana_initial:
			MANA += mana_regen_rate
			energy_mana.size.x += mana_regen_rate
#endregion
