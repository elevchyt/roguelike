extends CanvasLayer

var currentPlayer

func _process(delta):
	# Update HUD
	if (currentPlayer != null):
		$Health.text = 'HP: ' + str(currentPlayer.health) + '/' + str(currentPlayer.healthMax)
		$Mana.text = 'MP: ' + str(currentPlayer.mana) + '/' + str(currentPlayer.manaMax)
		$STR.text = 'STR: ' + str(currentPlayer.strength)
		$DEX.text = 'DEX: ' + str(currentPlayer.dexterity)
		$INT.text = 'STR: ' + str(currentPlayer.intelligence)
