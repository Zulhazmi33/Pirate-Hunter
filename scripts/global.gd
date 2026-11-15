extends Node

# a. list all monster
var monster_names = [
	"fierceTooth",
	"pinkStar",
    "crabby"
]
func monster_list(body: Node) -> bool:
	for name in monster_names:
		if body.name.begins_with(name):
			return true
	return false
