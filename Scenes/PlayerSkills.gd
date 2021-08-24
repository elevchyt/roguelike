extends Node2D

onready var GameManager = get_node("/root/World/GameManager")
onready var Player = get_parent()
onready var PlayerArea = Player.get_node("Area2D")
onready var PlayerSprite = Player.get_node('Sprite')
onready var PlayerTarget = Player.get_node('Target')
onready var PlayerTargetCollision = Player.get_node('Target/CollisionShape2D')
onready var PlayerTargetSprite = Player.get_node('Target/TargetSprite')
onready var PlayerTween = Player.get_node('Tween')
onready var HUD = get_node("/root/World/HUD")

# Skill Instances Pre-Load
onready var objFlare = preload('res://Scenes/Skills/Flare.tscn')
onready var objThunderclap = preload('res://Scenes/Skills/Thunderclap.tscn')
onready var objHealingPrayer = preload('res://Scenes/Skills/Healing Prayer.tscn')

################################################################################################################
# Skill Use Function
func use_skill(skillName):
	match skillName:
		'Flare':
			Player.targetMode = false
			
			# Damage Calculation
			var damage = ceil(Player.intelligence / 2.0 + Player.strength / 4.0)
			var targetNode = PlayerTarget.get_overlapping_areas()
			if (targetNode.empty() == false):
				var targetCreature = targetNode[0].get_parent()
				# Use skill
				if (targetCreature.isMonster == true):
					if (Player.skillInVision == true && (Player.position != to_global(PlayerTarget.position))):
						# Skill Projectile Animation
						print(Player.name + ' used ' + Player.skills[Player.skillChooseIndex])
						var instance = objFlare.instance()
						var instanceSprite = instance.get_node("AnimatedSprite")
						var instanceTween = instance.get_node("Tween")
						instance.z_index = 10
						instanceSprite.look_at(PlayerTargetSprite.get_parent().position) # set rotation to target
						add_child(instance)
						
						# Shoot projectile (THIS DELAYS TURN END!)
						instanceTween.interpolate_property(instance, "position", instance.position, PlayerTargetSprite.get_parent().position, 0.6, instanceTween.TRANS_QUART , instanceTween.EASE_OUT_IN)
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
						
						# EVASION CHECK
						var hitChance = randi() % 100
						if (hitChance > targetCreature.evasionPerc):
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
						# Show miss text on successful evasion by the target creature
						else:
							var damageText = targetCreature.get_node('TextDamage')

							z_index = 1
							damageText.get_node('TextDamage').bbcode_text = '[center][color=#ffffff]MISS[/color][/center]'
							damageText.get_node('TextDamageShadow').bbcode_text = '[center][color=#ff212123]MISS[/color][/center]'
							PlayerTween.interpolate_property(damageText, "position", Vector2.ZERO, Vector2(0, -128), 0.3, Tween.EASE_IN, Tween.EASE_OUT)
							PlayerTween.start()
							damageText.visible = true
							yield(get_tree().create_timer(1), "timeout") # DELAYS NEXT TURN, TOO
							z_index = 0
							damageText.visible = false
							damageText.position = Vector2.ZERO
							
						# End Turn
						Player.end_turn()
		'Thunderclap':
			# End Turn Variables
			Player.hasPlayed = true
			Player.active = false
			
			# Reduce player mana
			Player.mana -= Player.skillsManaCost[Player.skillChooseIndex]
			
			# Leave skills toolbar
			HUD.get_node('Tween').stop_all()
			HUD.get_node('SkillsConfirmCancelButtons').position = Vector2(0, 0)
			Player.skillSlots[Player.skillChooseIndex].scale = Vector2(1, 1)
			Player.skillSlots[Player.skillChooseIndex].modulate.a = 1
			
			# Player + Skill Animation
			Player.Tween.interpolate_property(PlayerSprite, "scale", PlayerSprite.scale, PlayerSprite.scale * 1.3, 0.6, Tween.TRANS_CIRC, Tween.EASE_IN_OUT)
			Player.Tween.start()
			yield(get_tree().create_timer(0.7), "timeout")
			Player.Tween.interpolate_property(PlayerSprite, "scale", PlayerSprite.scale , PlayerSprite.scale * 0.7, 0.4, Tween.TRANS_ELASTIC, Tween.EASE_OUT)
			Player.Tween.start()
			
			# Play particle animation
			print(Player.name + ' used ' + Player.skills[Player.skillChooseIndex])
			var instance = objThunderclap.instance()
			var instanceSprite = instance.get_node("AnimatedSprite")
			instance.z_index = -2
			add_child(instance)
			
			yield(get_tree().create_timer(0.1), "timeout") # (!) makes sure the collisions register on Area2D (hitbox)
			
			instanceSprite.playing = true
			
			# Damage Calculation (happens mid-animation)
			var damage = ceil(Player.intelligence / 2.0 + Player.strength / 2.0)
			print(damage)
			
			# Find targets around player & deal damage to them
			for enemy in instance.enemiesToHit:
				# Reduce enemy health
				enemy.health -= damage
				
				# Show damage text
				var damageText = enemy.get_node('TextDamage')
				
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
				if (enemy.health <= 0):
					# Check for level-up
					Player.xpCurrent += enemy.level
					Player.level_up_check()
				
					# Destroy target
					enemy.queue_free()
			
			# Reset player scale
			yield(get_tree().create_timer(0.3), "timeout")
			Player.Tween.interpolate_property(PlayerSprite, "scale", PlayerSprite.scale, Vector2(1, 1), 0.2, Tween.TRANS_LINEAR, Tween.EASE_OUT)
			Player.Tween.start()
			
			# End Turn
			yield(get_tree().create_timer(0.5), "timeout") # wait for this amount after all damage is dealt
			Player.end_turn()
			
		'Healing Prayer':
			Player.targetMode = false
			
			# Heal Calculation
			var healing = ceil(Player.intelligence * 0.8)
			var targetNode = PlayerTarget.get_overlapping_areas()
			if (targetNode.empty() == false):
				var targetCreature = targetNode[0].get_parent()
				# Use skill
				if (targetCreature.isMonster == false && targetCreature.isPlayer == true):
					if (Player.skillInVision == true):
						# Skill Particle Animation
						print(Player.name + ' used ' + Player.skills[Player.skillChooseIndex])
						var instance = objHealingPrayer.instance()
						var instanceSprite = instance.get_node("AnimatedSprite")
						instance.position = PlayerTargetSprite.get_parent().position
						instance.z_index = 10
						add_child(instance)
							
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
						
						# Increase target health
						targetCreature.health = clamp(targetCreature.health + healing, 0, targetCreature.healthMax)

						# Show healing text
						var damageText = targetCreature.get_node('TextDamage')
						
						z_index = 1
						damageText.get_node('TextDamage').bbcode_text = '[center][color=#ffffff]' + '+' + str(healing) + '[/color][/center]'
						damageText.get_node('TextDamageShadow').bbcode_text = '[center][color=#ff212123]' + '+' + str(healing) + '[/color][/center]'
						PlayerTween.interpolate_property(damageText, "position", Vector2.ZERO, Vector2(0, -128), 0.3, Tween.EASE_IN, Tween.EASE_OUT)
						PlayerTween.start()
						damageText.visible = true
						yield(get_tree().create_timer(1.4), "timeout") # DELAYS NEXT TURN, TOO
						z_index = 0
						damageText.visible = false
						damageText.position = Vector2.ZERO
						
						# End Turn
						Player.end_turn()
