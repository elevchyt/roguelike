extends Node2D

onready var Root = get_node("/root/World/")
onready var GameManager = get_node("/root/World/GameManager")
onready var CameraNode = get_node("/root/World/Camera2D")
onready var Player = get_parent()

func consume_item(itemName):
	match itemName:
		"Health Potion":
			var amount = ceil(Player.healthMax * 0.1)
			Player.health = clamp(Player.health + amount, Player.health, Player.healthMax)
			
			# Show health added number text
			GameManager.create_healing_text(Player, str(amount) + " HP")
			
