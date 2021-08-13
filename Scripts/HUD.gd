extends CanvasLayer

var currentPlayer

func _process(delta):
	
	# Update HUD
	if (currentPlayer != null):
		match (currentPlayer.playerColor):
			"blue":
				$ClassLevel.bbcode_text = '[center]' + '[color=#ff4b80ca]' + str(currentPlayer.playerClass) + '[/color]' + ', Level ' + str(currentPlayer.level) + '[/center]'
			"pink":
				$ClassLevel.bbcode_text = '[center]' + '[color=#ffcf8acb]' + str(currentPlayer.playerClass) + '[/color]' + ', Level ' + str(currentPlayer.level) + '[/center]'
			"orange":
				$ClassLevel.bbcode_text = '[center]' + '[color=#ffd3a068]' + str(currentPlayer.playerClass) + '[/color]' + ', Level ' + str(currentPlayer.level) + '[/center]'
				
		$ClassLevelShadow.bbcode_text = '[center]' + '[color=#ff212123]' + str(currentPlayer.playerClass) + ', Level ' + str(currentPlayer.level) + '[/color][/center]'
		
		
		$Health.bbcode_text = 'HP: ' + str(currentPlayer.health) + '/' + str(currentPlayer.healthMax)
		$HealthShadow.bbcode_text = '[color=#ff212123]HP: ' + str(currentPlayer.health) + '/' + str(currentPlayer.healthMax) + '[/color]'
		$ManaShadow.bbcode_text = '[color=#ff212123]MP: ' + str(currentPlayer.mana) + '/' + str(currentPlayer.manaMax) + '[/color]'
		$Mana.bbcode_text = 'MP: ' + str(currentPlayer.mana) + '/' + str(currentPlayer.manaMax)
		$STR.text = 'STR: ' + str(currentPlayer.strength)
		$DEX.text = 'DEX: ' + str(currentPlayer.dexterity)
		$INT.text = 'STR: ' + str(currentPlayer.intelligence)
		$Evasion.text = 'Ev: ' + str(currentPlayer.evasionPerc) + '%'
