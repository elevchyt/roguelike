extends Node2D

onready var GameManager = get_node("/root/World/GameManager")
onready var Player = get_parent()
onready var PlayerTarget = Player.get_node('Target')
onready var PlayerTargetSprite = Player.get_node('Target/TargetSprite')
onready var PlayerTween = Player.get_node('Tween')

# Skill Instances Pre-Load
onready var objFlare = preload('res://Scenes/Skills/Flare.tscn')

################################################################################################################
# Skill Use Function
func use_skill(skillName):
	print(Player.skillInVision)
	match skillName:
		'Flare':
			# Damage Calculation
			var damage = ceil(Player.intelligence / 2.0 + Player.strength / 4.0)
			var targetNode = PlayerTarget.get_overlapping_areas()
			if (targetNode.empty() == false):
				var targetCreature = targetNode[0].get_parent()
				if (targetCreature.isMonster == true):
					# End Turn Variables
					Player.hasPlayed = true
					Player.active = false

					# Skill Animation
					if (Player.skillInVision == true && (Player.position != to_global(PlayerTarget.position))):
						print(Player.name + ' used ' + Player.skills[Player.skillChooseIndex])

						var instance = objFlare.instance()
						var instanceSprite = instance.get_node("AnimatedSprite")
						var instanceTween = instance.get_node("Tween")

						instance.z_index = 10
						instanceSprite.look_at(PlayerTargetSprite.get_parent().position) # set rotation to target

						add_child(instance)

						# Shoot projectile
						instanceTween.interpolate_property(instance, "position", instance.position, PlayerTargetSprite.get_parent().position, 0.5, instanceTween.TRANS_CIRC, instanceTween.EASE_IN_OUT)
						instanceTween.start()

					# Reduce health
					targetCreature.health -= damage

					# Show damage text
					var damageText = targetCreature.get_node('TextDamage')

					z_index = 1
					damageText.get_node('TextDamage').bbcode_text = '[center][color=#ffffff]' + '-' + str(damage) + '[/color][/center]'
					damageText.get_node('TextDamageShadow').bbcode_text = '[center][color=#ff212123]' + '-' + str(damage) + '[/color][/center]'
					PlayerTween.interpolate_property(damageText, "position", Vector2.ZERO, Vector2(0, -128), 0.3, Tween.EASE_IN, Tween.EASE_OUT)
					PlayerTween.start()
					damageText.visible = true
					yield(get_tree().create_timer(1), "timeout") # DELAYS NEXT TURN, TOO
					z_index = 0
					damageText.visible = false
					damageText.position = Vector2.ZERO

					# Check if killed & gain xp (check for level-up)
					if (targetCreature.health <= 0):
						# Check for level-up
						Player.xpCurrent += targetCreature.level
						Player.level_up_check()
						
						# Destroy target
						targetCreature.queue_free()
						
				# End Turn
				#Player.end_turn()
