extends CanvasLayer

onready var GameManager = get_node("/root/World/GameManager")
var currentPlayer

func _process(delta):
	# Update HUD
	if (currentPlayer != null):
		# Toggle hud visibility (H)
		if (Input.is_action_just_pressed("key_h")):
			hide()
		elif (Input.is_action_just_released("key_h")):
			show()
		
		# SET HUD VALUES
		match (currentPlayer.playerColor):
			"blue":
				$ClassLevel.bbcode_text = '[center]' + '[color=#ff4b80ca]' + str(currentPlayer.playerClass) + '[/color]' + ', Level ' + str(currentPlayer.level) + '[/center]'
			"pink":
				$ClassLevel.bbcode_text = '[center]' + '[color=#ffcf8acb]' + str(currentPlayer.playerClass) + '[/color]' + ', Level ' + str(currentPlayer.level) + '[/center]'
			"orange":
				$ClassLevel.bbcode_text = '[center]' + '[color=#ffd3a068]' + str(currentPlayer.playerClass) + '[/color]' + ', Level ' + str(currentPlayer.level) + '[/center]'
				
		$ClassLevelShadow.bbcode_text = '[center]' + '[color=#ff212123]' + str(currentPlayer.playerClass) + ', Level ' + str(currentPlayer.level) + '[/color][/center]'
		
		$XP.bbcode_text = '[color=#ffffff]XP: ' + str(currentPlayer.xpCurrent) + '/' + str(currentPlayer.xpToLevel) + '[/color]'
		$XPShadow.bbcode_text = '[color=#ff212123]XP: ' + str(currentPlayer.xpCurrent) + '/' + str(currentPlayer.xpToLevel) + '[/color]'
		$Health.bbcode_text = '[center]HP: ' + str(currentPlayer.health) + '/' + str(currentPlayer.healthMax) + '[/center]'
		$HealthShadow.bbcode_text = '[center][color=#ff212123]HP: ' + str(currentPlayer.health) + '/' + str(currentPlayer.healthMax) + '[/color][/center]'
		$ManaShadow.bbcode_text = '[center][color=#ff212123]MP: ' + str(currentPlayer.mana) + '/' + str(currentPlayer.manaMax) + '[/color][/center]'
		$Mana.bbcode_text = '[center]MP: ' + str(currentPlayer.mana) + '/' + str(currentPlayer.manaMax) + '[/center]'
		$STR.bbcode_text = 'STR: ' + str(currentPlayer.strength)
		$STRShadow.bbcode_text = '[color=#ff212123]STR: ' + str(currentPlayer.strength) + '[/color]'
		$DEX.bbcode_text = 'DEX: ' + str(currentPlayer.dexterity)
		$DEXShadow.bbcode_text = '[color=#ff212123]DEX: ' + str(currentPlayer.dexterity) + '[/color]'
		$INT.bbcode_text = 'INT: ' + str(currentPlayer.intelligence)
		$INTShadow.bbcode_text = '[color=#ff212123]INT: ' + str(currentPlayer.intelligence) + '[/color]'
		$Evasion.bbcode_text = 'Ev: ' + str(currentPlayer.evasionPerc) + '%'
		$EvasionShadow.bbcode_text = '[color=#ff212123]Ev: ' + str(currentPlayer.evasionPerc) + '%' + '[/color]'
		
		# Cooldowns Text
		if (currentPlayer.skillsCooldownCurrent[0] > 0):
			$Skill1/Cooldown/Cooldown.bbcode_text = '[center]' + str(currentPlayer.skillsCooldownCurrent[0]) + '[/center]'
			$Skill1/Cooldown/CooldownShadow.bbcode_text = '[center][color=#ff212123]' + str(currentPlayer.skillsCooldownCurrent[0]) + '[/color][/center]'
			$Skill1.modulate.a = 0.8
			$Skill1/Cooldown.visible = true
		else:
			$Skill1.modulate.a = 1
			$Skill1/Cooldown.visible = false
		if (currentPlayer.skillsCooldownCurrent[1] > 0):
			$Skill2/Cooldown/Cooldown.bbcode_text = '[center]' + str(currentPlayer.skillsCooldownCurrent[1]) + '[/center]'
			$Skill2/Cooldown/CooldownShadow.bbcode_text = '[center][color=#ff212123]' + str(currentPlayer.skillsCooldownCurrent[1]) + '[/color][/center]'
			$Skill2.modulate.a = 0.8
			$Skill2/Cooldown.visible = true
		else:
			$Skill2.modulate.a = 1
			$Skill2/Cooldown.visible = false
		if (currentPlayer.skillsCooldownCurrent[2] > 0):
			$Skill3/Cooldown/Cooldown.bbcode_text = '[center]' + str(currentPlayer.skillsCooldownCurrent[2]) + '[/center]'
			$Skill3/Cooldown/CooldownShadow.bbcode_text = '[center][color=#ff212123]' + str(currentPlayer.skillsCooldownCurrent[2]) + '[/color][/center]'
			$Skill3.modulate.a = 0.8
			$Skill3/Cooldown.visible = true
		else:
			$Skill3.modulate.a = 1
			$Skill3/Cooldown.visible = false
		if (currentPlayer.skillsCooldownCurrent[3] > 0):
			$Skill4/Cooldown/Cooldown.bbcode_text = '[center]' + str(currentPlayer.skillsCooldownCurrent[3]) + '[/center]'
			$Skill4/Cooldown/CooldownShadow.bbcode_text = '[center][color=#ff212123]' + str(currentPlayer.skillsCooldownCurrent[3]) + '[/color][/center]'
			$Skill4.modulate.a = 0.8
			$Skill4/Cooldown.visible = true
		else:
			$Skill4.modulate.a = 1
			$Skill4/Cooldown.visible = false

func hide():
	scale = Vector2(0, 0)

func show():
	scale = Vector2(1, 1)
