extends Node2D

onready var GameManager = get_node("/root/World/GameManager")
onready var Player = get_parent()
onready var PlayerTarget = Player.get_node('Target')
onready var PlayerTargetCollision = Player.get_node('Target/CollisionShape2D')
onready var PlayerTargetSprite = Player.get_node('Target/TargetSprite')
onready var PlayerTween = Player.get_node('Tween')
onready var HUD = get_node("/root/World/HUD")

# Skill Instances Pre-Load
onready var objFlare = preload('res://Scenes/Skills/Flare.tscn')

################################################################################################################
# Skill Use Function
func use_skill(skillName):
	print(Player.skillInVision)
	
	# Check for mana before using skill
	match skillName:
		'Flare':
			# Damage Calculation
			var damage = ceil(Player.intelligence / 2.0 + Player.strength / 4.0)
			var targetNode = PlayerTarget.get_overlapping_areas()
			if (targetNode.empty() == false):
				var targetCreature = targetNode[0].get_parent()
				if (targetCreature.isMonster == true):
					# Skill Projectile Animation
					if (Player.skillInVision == true && (Player.position != to_global(PlayerTarget.position))):
						print(Player.name + ' used ' + Player.skills[Player.skillChooseIndex])
						var instance = objFlare.instance()
						var instanceSprite = instance.get_node("AnimatedSprite")
						var instanceTween = instance.get_node("Tween")
						instance.z_index = 10
						instanceSprite.look_at(PlayerTargetSprite.get_parent().position) # set rotation to target
						add_child(instance)
						
						# Shoot projectile
						instanceTween.interpolate_property(instance, "position", instance.position, PlayerTargetSprite.get_parent().position, 0.5, instanceTween.TRANS_CIRC, instanceTween.EASE_OUT_IN)
						instanceTween.start()
							
						# Leave skills toolbar
						HUD.get_node('Tween').stop_all()
						HUD.get_node('SkillsConfirmCancelButtons').position = Vector2(0, 0)
						Player.skillSlots[Player.skillChooseIndex].scale = Vector2(1, 1)
						Player.skillSlots[Player.skillChooseIndex].modulate.a = 1
						
						# Reset Target
						PlayerTargetCollision.disabled = true
						PlayerTarget.position = Vector2.ZERO
						PlayerTarget.visible = false
						
						# Reset RayCast
						Player.RayTarget.set_cast_to(PlayerTarget.position)
						Player.RayTarget.force_raycast_update()
						
						# End Turn Variables
						Player.hasPlayed = true
						Player.active = false
						
						# Reduce player mana
						Player.mana -= Player.skillsManaCost[Player.skillChooseIndex]
						
						# Reduce target health
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
						Player.end_turn()
