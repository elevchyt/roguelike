extends Node2D

onready var Root = get_node("/root/World/")
onready var GameManager = get_node("/root/World/GameManager")
onready var CameraNode = get_node("/root/World/Camera2D")
onready var Player = get_parent()
onready var PlayerArea = Player.get_node("Area2D")
onready var PlayerSprite = Player.get_node('Sprite')
onready var PlayerTarget = Player.get_node('Target')
onready var PlayerRay = Player.get_node("RayCastVision")
onready var PlayerTargetCollision = Player.get_node('Target/CollisionShape2D')
onready var PlayerTargetSprite = Player.get_node('Target/TargetSprite')
onready var PlayerTween = Player.get_node('Tween')
onready var HUD = get_node("/root/World/HUD")

# Hit Sucess (is referred in some skill scenes (e.g. Flare) to do specific things like camera shakes only on hit etc.
var hitSuccess = false

# Skill Instances Pre-Load
onready var objCleave = preload('res://Scenes/Skills/Cleave.tscn')
onready var objRetaliation = preload('res://Scenes/Skills/Retaliation.tscn')
onready var objFlare = preload('res://Scenes/Skills/Flare.tscn')
onready var objThunderclap = preload('res://Scenes/Skills/Thunderclap.tscn')
onready var objCurse = preload('res://Scenes/Skills/Curse.tscn')
onready var objPoisonDart = preload('res://Scenes/Skills/Poison Dart.tscn')
onready var objEnsnare = preload('res://Scenes/Skills/Ensnare.tscn')
onready var objHealingPrayer = preload('res://Scenes/Skills/Healing Prayer.tscn')
onready var objPurify = preload('res://Scenes/Skills/Purify.tscn')
onready var objDivineShield = preload('res://Scenes/Skills/Divine Shield.tscn')
onready var objRessurect = preload('res://Scenes/Skills/Ressurect.tscn')


################################################################################################################
# Skill Use Function
func use_skill(skillName):
	hitSuccess = false
	
	match skillName:
		'Retaliation':
			Player.skillInVision = true # make sure non-targeted skills can be cast
			
			# End Turn Variables
			Player.hasPlayed = true
			Player.active = false
			
			# Reduce player mana & set cooldown
			Player.mana -= Player.skillsManaCost[Player.skillChooseIndex]
			Player.skillsCooldownCurrent[Player.skillChooseIndex] = Player.skillsCooldown[Player.skillChooseIndex]
			
			# Leave skills toolbar
			HUD.get_node('Tween').stop_all()
			HUD.get_node('SkillsConfirmCancelButtons').position = Vector2(0, 0)
			HUD.get_node('SkillDetails').visible = false
			Player.skillSlots[Player.skillChooseIndex].scale = Vector2(1, 1)
			Player.skillSlots[Player.skillChooseIndex].modulate.a = 1
			
			# Play particle animation
			print(Player.name + ' used ' + Player.skills[Player.skillChooseIndex])
			var instance = objRetaliation.instance()
			var instanceSprite = instance.get_node("AnimatedSprite")
			instance.z_index = -2
			add_child(instance)
			instanceSprite.playing = true
			
			yield(get_tree().create_timer(0.1), "timeout") # (!) makes sure the collisions register on Area2D (hitbox)
			
			# Camera Shake
			CameraNode.shake(9, 0.01, 0.2)
			
			# Apply retaliation effect
			Player.retaliation = true
			Player.retaliationCounter = 2
			instanceSprite.playing = true
			Player.retaliationNode = instance
			
			# End Turn
			yield(get_tree().create_timer(0.6), "timeout")
			Player.end_turn()
		'Flare':
			# Find eligible target
			var targetNode = PlayerTarget.get_overlapping_areas()
			if (targetNode.empty() == false):
				# Use skill
				var targetCreature = targetNode[0].get_parent()
				if (targetCreature.isMonster == true):
					if (Player.skillInVision == true && (Player.position != to_global(PlayerTarget.position))):
						Player.targetMode = false # leave target mode
						
						# Skill Projectile Animation
						print(Player.name + ' used ' + Player.skills[Player.skillChooseIndex])
						var instance = objFlare.instance()
						var instanceSprite = instance.get_node("AnimatedSprite")
						var instanceTween = instance.get_node("Tween")
						instanceSprite.look_at(PlayerTargetSprite.get_parent().position + Vector2(48, 48)) # set rotation to target
						add_child(instance)
						
						# Shoot projectile
						instanceTween.interpolate_property(instance, "position", instance.position, PlayerTargetSprite.get_parent().position, 0.6, instanceTween.TRANS_QUART , instanceTween.EASE_OUT_IN)
						instanceTween.start()
						
						# Leave skills toolbar
						HUD.get_node('Tween').stop_all()
						HUD.get_node('SkillsConfirmCancelButtons').position = Vector2(0, 0)
						HUD.get_node('SkillDetails').visible = false
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
						
						# Reduce player mana & set cooldown
						Player.mana -= Player.skillsManaCost[Player.skillChooseIndex]
						Player.skillsCooldownCurrent[Player.skillChooseIndex] = Player.skillsCooldown[Player.skillChooseIndex]
						
						# EVASION CHECK
						randomize()
						var hitChance = randi() % 100
						if (hitChance > targetCreature.evasionPerc):
							hitSuccess = true
							
							# Damage Calculation (happens mid-animation)
							var damage
							if (targetCreature.cursed == true):
								damage = ceil((ceil(Player.intelligence / 2.0 + Player.strength / 4.0) - targetCreature.damageResistance) * 1.2)
							else:
								damage = ceil((ceil(Player.intelligence / 2.0 + Player.strength / 4.0) - targetCreature.damageResistance))
							
							# Reduce target health
							targetCreature.health -= damage

							# Show damage text
							GameManager.create_damage_text(targetCreature, damage, '#ffffff')
							
							# Check if killed & gain xp (check for level-up)
							if (targetCreature.health <= 0):
								targetCreature.health = 0
								
								# Check if ensnared == true to remove ensnareNode on death
								if (targetCreature.ensnared == true):
									targetCreature.ensnareNode.queue_free()
								
								# Check for level-up
								for player in GameManager.players:
									player.xpCurrent += targetCreature.level
									player.level_up_check()
								
								# Destroy target
								targetCreature.queue_free()
						# Show miss text on successful evasion by the target creature
						else:
							GameManager.create_status_text(targetCreature, 'MISS', '#ffffff')
							
						# End Turn
						yield(get_tree().create_timer(1.5), "timeout") # wait for this amount after all damage is dealt
						Player.end_turn()
				# Else show invalid target feedback text
				else:
					HUD.get_node('FeedbackTextTarget').visible = true
					yield(get_tree().create_timer(1), "timeout")
					HUD.get_node('FeedbackTextTarget').visible = false
		'Thunderclap':
			Player.skillInVision = true # make sure non-targeted skills can be cast
			
			# End Turn Variables
			Player.hasPlayed = true
			Player.active = false
			
			# Reduce player mana & set cooldown
			Player.mana -= Player.skillsManaCost[Player.skillChooseIndex]
			Player.skillsCooldownCurrent[Player.skillChooseIndex] = Player.skillsCooldown[Player.skillChooseIndex]
			
			# Leave skills toolbar
			HUD.get_node('Tween').stop_all()
			HUD.get_node('SkillsConfirmCancelButtons').position = Vector2(0, 0)
			HUD.get_node('SkillDetails').visible = false
			Player.skillSlots[Player.skillChooseIndex].scale = Vector2(1, 1)
			Player.skillSlots[Player.skillChooseIndex].modulate.a = 1
			
			# Player + Skill Animation
			Player.Tween.interpolate_property(PlayerSprite, "scale", PlayerSprite.scale, PlayerSprite.scale * 1.3, 0.8, Tween.TRANS_ELASTIC, Tween.EASE_IN_OUT)
			Player.Tween.start()
			yield(get_tree().create_timer(1), "timeout")
			Player.Tween.interpolate_property(PlayerSprite, "scale", PlayerSprite.scale, PlayerSprite.scale * 0.7, 0.5, Tween.TRANS_ELASTIC, Tween.EASE_IN_OUT)
			Player.Tween.start()
			yield(get_tree().create_timer(0.2), "timeout")
			
			# Play particle animation
			print(Player.name + ' used ' + Player.skills[Player.skillChooseIndex])
			var instance = objThunderclap.instance()
			var instanceSprite = instance.get_node("AnimatedSprite")
			instance.z_index = -2
			add_child(instance)
			instanceSprite.playing = true
			
			yield(get_tree().create_timer(0.1), "timeout") # (!) makes sure the collisions register on Area2D (hitbox)
			
			# Camera Shake
			CameraNode.shake(16, 0.04, 0.5)
			
			# Find targets around player & deal damage to them
			for enemy in instance.enemiesToHit:
				# Damage Calculation (happens mid-animation)
				var damage
				if (enemy.cursed == true):
					damage = ceil((ceil(Player.intelligence / 2.0 + Player.strength / 2.0) - enemy.damageResistance) * 1.2)
				else:
					damage = ceil((ceil(Player.intelligence / 2.0 + Player.strength / 2.0) - enemy.damageResistance))
				
				# Reduce enemy health
				enemy.health -= damage
				
				# Show damage text
				GameManager.create_damage_text(enemy, damage, '#ffffff')
				
				# Check if killed & gain xp (check for level-up)
				if (enemy.health <= 0):
					enemy.health = 0
					
					# Check if ensnared == true to remove ensnareNode on death
					if (enemy.ensnared == true):
						enemy.ensnareNode.queue_free()
					
					# Check for level-up
					for player in GameManager.players:
						player.xpCurrent += enemy.level
						player.level_up_check()
				
					# Destroy target
					enemy.queue_free()
			
			# Reset player scale
			yield(get_tree().create_timer(0.3), "timeout")
			Player.Tween.interpolate_property(PlayerSprite, "scale", PlayerSprite.scale, Vector2(1, 1), 0.3, Tween.TRANS_ELASTIC, Tween.EASE_IN_OUT)
			Player.Tween.start()
			
			# End Turn
			yield(get_tree().create_timer(0.6), "timeout") # wait for this amount after all damage is dealt
			Player.end_turn()
			
		'Curse':
			# Curse Target
			var targetNode = PlayerTarget.get_overlapping_areas()
			if (targetNode.empty() == false):
				# Use skill
				var targetCreature = targetNode[0].get_parent()
				if (targetCreature.isMonster == true && targetCreature.isPlayer == false):
					if (Player.skillInVision == true):
						Player.targetMode = false # leave target mode
						
						# Camera Shake
						CameraNode.shake(8, 0.2, 1)
						
						# Skill Particle Animation
						print(Player.name + ' used ' + Player.skills[Player.skillChooseIndex])
						var instance = objCurse.instance()
						var instanceSprite = instance.get_node("AnimatedSprite")
						instanceSprite.playing = true
						instance.position = PlayerTargetSprite.get_parent().position
						add_child(instance)
						
						PlayerTween.interpolate_property(instanceSprite, "scale", Vector2(2, 2), Vector2(1, 1), 0.8, Tween.EASE_IN, Tween.EASE_OUT)
						PlayerTween.start()
						
						# Apply skill effect
						targetCreature.cursed = true
						targetCreature.cursedCounter = 3
						targetCreature.evasionPerc = 0
						
						# Leave skills toolbar
						HUD.get_node('Tween').stop_all()
						HUD.get_node('SkillsConfirmCancelButtons').position = Vector2(0, 0)
						HUD.get_node('SkillDetails').visible = false
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
						
						# Reduce player mana & set cooldown
						Player.mana -= Player.skillsManaCost[Player.skillChooseIndex]
						Player.skillsCooldownCurrent[Player.skillChooseIndex] = Player.skillsCooldown[Player.skillChooseIndex]
						
						# Show cursed text
						GameManager.create_status_text(targetCreature, 'cursed', '#ffffff')
						
						# End Turn
						Player.end_turn()
				# Else show invalid target feedback text
				else:
					HUD.get_node('FeedbackTextTarget').visible = true
					yield(get_tree().create_timer(1), "timeout")
					HUD.get_node('FeedbackTextTarget').visible = false
		'Poison Dart':
			# Find eligible target
			var targetNode = PlayerTarget.get_overlapping_areas()
			if (targetNode.empty() == false):
				# Use skill
				var targetCreature = targetNode[0].get_parent()
				if (targetCreature.isMonster == true):
					if (Player.skillInVision == true && (Player.position != to_global(PlayerTarget.position))):
						Player.targetMode = false # leave target mode
						
						# (Rogue) Remove invisibility
						if (Player.invisible == true):
							Player.invisible = false
							Player.invisibleCounter = 0
							PlayerSprite.modulate = Color(1, 1, 1, 1)
						
						# Skill Projectile Animation
						print(Player.name + ' used ' + Player.skills[Player.skillChooseIndex])
						var instance = objPoisonDart.instance()
						var instanceSprite = instance.get_node("AnimatedSprite")
						var instanceTween = instance.get_node("Tween")
						instanceSprite.look_at(PlayerTargetSprite.get_parent().position + Vector2(48, 48)) # set rotation to target
						add_child(instance)
						
						# Shoot projectile
						instanceTween.interpolate_property(instance, "position", instance.position, PlayerTargetSprite.get_parent().position, 0.6, instanceTween.TRANS_QUART , instanceTween.EASE_OUT_IN)
						instanceTween.start()
						
						# Leave skills toolbar
						HUD.get_node('Tween').stop_all()
						HUD.get_node('SkillsConfirmCancelButtons').position = Vector2(0, 0)
						HUD.get_node('SkillDetails').visible = false
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
						
						# Reduce player mana & set cooldown
						Player.mana -= Player.skillsManaCost[Player.skillChooseIndex]
						Player.skillsCooldownCurrent[Player.skillChooseIndex] = Player.skillsCooldown[Player.skillChooseIndex]
						
						# EVASION CHECK
						randomize()
						var hitChance = randi() % 100
						if (hitChance > targetCreature.evasionPerc):
							hitSuccess = true
							
							# Damage Calculation (happens mid-animation)
							var damage
							if (targetCreature.cursed == true):
								damage = ceil(Player.strength - targetCreature.damageResistance * 1.2)
							else:
								damage = ceil(Player.intelligence - targetCreature.damageResistance)
							
							# Reduce target health
							targetCreature.health -= damage

							# Show damage text
							GameManager.create_damage_text(targetCreature, damage, '#ffffff')
							
							# Check for poison effect application
							randomize()
							var poisonChance = randi() % 100
							if (poisonChance > 50):
								
								targetCreature.poisoned = true
								targetCreature.poisonedCounter = 3
								targetCreature.playerWhoPoisonedMe = Player
								
								# Show poisoned status text 
								GameManager.create_status_text(targetCreature, 'poisoned', '#c2d368')
								
						# Show miss text on successful evasion by the target creature
						else:
							GameManager.create_status_text(targetCreature, 'MISS', '#ffffff')
						
						# Check if killed & gain xp (check for level-up)
						if (targetCreature.health <= 0):
							targetCreature.health = 0
							
							# Check if ensnared == true to remove ensnareNode on death
							if (targetCreature.ensnared == true):
								targetCreature.ensnareNode.queue_free()
							
							# Check for level-up
							for player in GameManager.players:
								player.xpCurrent += targetCreature.level
								player.level_up_check()
							
							# Destroy target
							targetCreature.queue_free()
							
						# End Turn
						yield(get_tree().create_timer(1.5), "timeout") # wait for this amount after all damage is dealt
						Player.end_turn()
					# Else show invalid target feedback text
				else:
					HUD.get_node('FeedbackTextTarget').visible = true
					yield(get_tree().create_timer(1), "timeout")
					HUD.get_node('FeedbackTextTarget').visible = false
		'Ensnare':
			# Find eligible target
			var targetNode = PlayerTarget.get_overlapping_areas()
			if (targetNode.empty() == false):
				# Use skill
				var targetCreature = targetNode[0].get_parent()
				if (targetCreature.isMonster == true):
					if (Player.skillInVision == true && (Player.position != to_global(PlayerTarget.position))):
						Player.targetMode = false # leave target mode
						
						# (Rogue) Remove invisibility
						if (Player.invisible == true):
							Player.invisible = false
							Player.invisibleCounter = 0
							PlayerSprite.modulate = Color(1, 1, 1, 1)
						
						# Skill Projectile Animation
						print(Player.name + ' used ' + Player.skills[Player.skillChooseIndex])
						var instance = objEnsnare.instance()
						var instanceSprite = instance.get_node("AnimatedSprite")
						var instanceTween = instance.get_node("Tween")
						instanceSprite.look_at(PlayerTargetSprite.get_parent().position + Vector2(48, 48)) # set rotation to target
						Root.add_child(instance)
						targetCreature.ensnareNode = instance
						
						# Shoot projectile
						instanceTween.interpolate_property(instance, "position", Player.position, to_global(PlayerTarget.position), 0.6, instanceTween.TRANS_QUART , instanceTween.EASE_OUT_IN)
						instanceTween.start()
						
						# Leave skills toolbar
						HUD.get_node('Tween').stop_all()
						HUD.get_node('SkillsConfirmCancelButtons').position = Vector2(0, 0)
						HUD.get_node('SkillDetails').visible = false
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
						
						# Reduce player mana & set cooldown
						Player.mana -= Player.skillsManaCost[Player.skillChooseIndex]
						Player.skillsCooldownCurrent[Player.skillChooseIndex] = Player.skillsCooldown[Player.skillChooseIndex]
							
						# Set ensnared effect
						targetCreature.ensnared = true
						targetCreature.ensnaredCounter = 3
						targetCreature.evasionPerc = 0
						
						# Show ensnared status text
						GameManager.create_status_text(targetCreature, 'ensnared', '#ffffff')
					
						# End Turn
						Player.end_turn()
				# Else show invalid target feedback text
				else:
					HUD.get_node('FeedbackTextTarget').visible = true
					yield(get_tree().create_timer(1), "timeout")
					HUD.get_node('FeedbackTextTarget').visible = false
		'Leap':
			# Check target area
			var targetNode = PlayerTarget.get_overlapping_areas()
			if (targetNode.empty() == false):
				var targetCreature = targetNode[0].get_parent()
				if (targetCreature.isMonster == false && targetCreature.isPlayer == false):
					# Use skill
					useLeap()
				# Else show invalid target feedback text
				else:
					HUD.get_node('FeedbackTextTarget').visible = true
					yield(get_tree().create_timer(1), "timeout")
					HUD.get_node('FeedbackTextTarget').visible = false
			# If the tile is empty use skill
			else:
				# Use skill
				useLeap()
		'Shadow Walk':
			# Use skill
			Player.targetMode = false
			Player.invisible = true
			var index = Player.skills.find('Shadow Walk')
			Player.invisibleCounter = Player.skillsRange[index]
			
			# Leave skills toolbar
			HUD.get_node('Tween').stop_all()
			HUD.get_node('SkillsConfirmCancelButtons').position = Vector2(0, 0)
			HUD.get_node('SkillDetails').visible = false
			Player.skillSlots[Player.skillChooseIndex].scale = Vector2(1, 1)
			Player.skillSlots[Player.skillChooseIndex].modulate.a = 1
			
			# Set transparency
			Player.Tween.interpolate_property(PlayerSprite, "modulate", Color(1, 1, 1, 1), Color(1, 1, 1, 0.2), 0.5, Tween.TRANS_SINE, Tween.EASE_OUT)
			Player.Tween.start()
			
			# End Turn Variables
			Player.hasPlayed = true
			Player.active = false
			
			# Reduce player mana & set cooldown
			Player.mana -= Player.skillsManaCost[Player.skillChooseIndex]
			Player.skillsCooldownCurrent[Player.skillChooseIndex] = Player.skillsCooldown[Player.skillChooseIndex]
			
			# Show invisible text
			GameManager.create_status_text(Player, 'invisible', '#ffffff')
			
			# End Turn
			yield(get_tree().create_timer(1.5), "timeout")
			Player.end_turn()
		'Healing Prayer':
			# Heal Calculation
			var healing = ceil(Player.intelligence * 0.8)
			var targetNode = PlayerTarget.get_overlapping_areas()
			if (targetNode.empty() == false):
				var targetCreature = targetNode[0].get_parent()
				# Use skill
				if (targetCreature.isMonster == false && targetCreature.isPlayer == true && targetCreature.state != 'dying' && targetCreature.state != 'dead'):
					if (Player.skillInVision == true):
						Player.targetMode = false # leave target mode
						# Camera Shake
						CameraNode.shake(16, 0.4, 1)
						
						# Skill Particle Animation
						print(Player.name + ' used ' + Player.skills[Player.skillChooseIndex])
						var instance = objHealingPrayer.instance()
						var instanceSprite = instance.get_node("AnimatedSprite")
						instanceSprite.playing = true
						instance.position = PlayerTargetSprite.get_parent().position
						add_child(instance)
							
						# Leave skills toolbar
						HUD.get_node('Tween').stop_all()
						HUD.get_node('SkillsConfirmCancelButtons').position = Vector2(0, 0)
						HUD.get_node('SkillDetails').visible = false
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
						
						# Reduce player mana & set cooldown
						Player.mana -= Player.skillsManaCost[Player.skillChooseIndex]
						Player.skillsCooldownCurrent[Player.skillChooseIndex] = Player.skillsCooldown[Player.skillChooseIndex]
						
						# Increase target health
						targetCreature.health = clamp(targetCreature.health + healing, 0, targetCreature.healthMax)

						# Show healing text
						GameManager.create_healing_text(targetCreature, healing)
						
						# End Turn
						yield(get_tree().create_timer(1.5), "timeout")
						Player.end_turn()
				# Else show invalid target feedback text
				else:
					HUD.get_node('FeedbackTextTarget').visible = true
					yield(get_tree().create_timer(1), "timeout")
					HUD.get_node('FeedbackTextTarget').visible = false
		'Purify':
			var targetNode = PlayerTarget.get_overlapping_areas()
			if (targetNode.empty() == false):
				var targetCreature = targetNode[0].get_parent()
				# Use skill
				if (targetCreature.isMonster == false && targetCreature.isPlayer == true && targetCreature.state != 'dying' && targetCreature.state != 'dead'):
					if (Player.skillInVision == true):
						Player.targetMode = false # leave target mode
						# Camera Shake
						CameraNode.shake(12, 0.2, 1)
						
						# Skill Particle Animation
						print(Player.name + ' used ' + Player.skills[Player.skillChooseIndex])
						var instance = objPurify.instance()
						var instanceSprite = instance.get_node("AnimatedSprite")
						instanceSprite.playing = true
						instance.position = PlayerTargetSprite.get_parent().position
						add_child(instance)
							
						# Leave skills toolbar
						HUD.get_node('Tween').stop_all()
						HUD.get_node('SkillsConfirmCancelButtons').position = Vector2(0, 0)
						HUD.get_node('SkillDetails').visible = false
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
						
						# Reduce player mana & set cooldown
						Player.mana -= Player.skillsManaCost[Player.skillChooseIndex]
						Player.skillsCooldownCurrent[Player.skillChooseIndex] = Player.skillsCooldown[Player.skillChooseIndex]
						
						# Remove debuffs from friendly target
						targetCreature.poisoned = false
						targetCreature.ensnared = false
						targetCreature.cursed = false
						
						# Show purify text
						GameManager.create_status_text(targetCreature, 'purified', '#ffa2dcc7')
						
						# End Turn
						yield(get_tree().create_timer(1.5), "timeout")
						Player.end_turn()
				# Else show invalid target feedback text
				else:
					HUD.get_node('FeedbackTextTarget').visible = true
					yield(get_tree().create_timer(1), "timeout")
					HUD.get_node('FeedbackTextTarget').visible = false
		'Divine Shield':
			var targetNode = PlayerTarget.get_overlapping_areas()
			if (targetNode.empty() == false):
				var targetCreature = targetNode[0].get_parent()
				# Use skill
				if (targetCreature.isMonster == false && targetCreature.isPlayer == true && targetCreature.state != 'dying' && targetCreature.state != 'dead'):
					if (Player.skillInVision == true):
						Player.targetMode = false # leave target mode
						# Camera Shake
						CameraNode.shake(10, 0.2, 0.8)
						
						# Skill Particle Animation
						print(Player.name + ' used ' + Player.skills[Player.skillChooseIndex])
						var instance = objDivineShield.instance()
						var instanceSprite = instance.get_node("AnimatedSprite")
						instanceSprite.playing = true
						targetCreature.add_child(instance)
							
						# Leave skills toolbar
						HUD.get_node('Tween').stop_all()
						HUD.get_node('SkillsConfirmCancelButtons').position = Vector2(0, 0)
						HUD.get_node('SkillDetails').visible = false
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
						
						# Reduce player mana & set cooldown
						Player.mana -= Player.skillsManaCost[Player.skillChooseIndex]
						Player.skillsCooldownCurrent[Player.skillChooseIndex] = Player.skillsCooldown[Player.skillChooseIndex]
						
						# Set target's invulnerable state to true
						targetCreature.invulnerable = true
						targetCreature.invulnerableCounter = 2
						
						# Show invulnerable text
						GameManager.create_status_text(targetCreature, 'invulnerable', '#ffa2dcc7')
						
						# End Turn
						yield(get_tree().create_timer(1.5), "timeout")
						Player.end_turn()
				# Else show invalid target feedback text
				else:
					HUD.get_node('FeedbackTextTarget').visible = true
					yield(get_tree().create_timer(1), "timeout")
					HUD.get_node('FeedbackTextTarget').visible = false
		'Ressurect':
			var targetNode = PlayerTarget.get_overlapping_areas()
			if (targetNode.empty() == false):
				var targetCreature = targetNode[0].get_parent()
				# Use skill
				if (targetCreature.isMonster == false && targetCreature.isPlayer == true && targetCreature.state == 'dying'):
					if (Player.skillInVision == true):
						Player.targetMode = false # leave target mode
						# Camera Shake
						CameraNode.shake(10, 0.05, 0.65)
						
						# Skill Particle Animation
						print(Player.name + ' used ' + Player.skills[Player.skillChooseIndex])
						var instance = objRessurect.instance()
						var instanceSprite = instance.get_node("AnimatedSprite")
						instanceSprite.playing = true
						targetCreature.add_child(instance)
							
						# Leave skills toolbar
						HUD.get_node('Tween').stop_all()
						HUD.get_node('SkillsConfirmCancelButtons').position = Vector2(0, 0)
						HUD.get_node('SkillDetails').visible = false
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
						
						# Reduce player mana & set cooldown
						Player.mana -= Player.skillsManaCost[Player.skillChooseIndex]
						Player.skillsCooldownCurrent[Player.skillChooseIndex] = Player.skillsCooldown[Player.skillChooseIndex]
						
						# Set health & mana of ressurected target (20%) & set state to 'alive' (+ reset alpha)
						yield(get_tree().create_timer(1.3), "timeout")
						targetCreature.health = ceil(targetCreature.healthMax * 0.2)
						targetCreature.mana = ceil(targetCreature.manaMax * 0.2)
						targetCreature.state = 'alive'
						targetCreature.get_node('Sprite').modulate.a = 1
						
						# Show ressurected text
						GameManager.create_status_text(targetCreature, 'ressurected', '#ffa2dcc7')
						
						# End Turn
						Player.end_turn()
				# Else show invalid target feedback text
				else:
					HUD.get_node('FeedbackTextTarget').visible = true
					yield(get_tree().create_timer(1), "timeout")
					HUD.get_node('FeedbackTextTarget').visible = false
################################################################################################################
# Cleave (Passive Skill)
func cleave_check(target):
	if (Player.cleave == true):
		var instance = objCleave.instance()
		var instanceTween = instance.get_node("Tween")
		instance.position = to_local(target.position)
		add_child(instance)
		
		yield(get_tree().create_timer(0.1), "timeout") # makes sure all enemies are stored
		var enemiesToHit = instance.enemiesToHit
		instance.queue_free()
		
		# Check for a hit on every adjacent enemy
		if (enemiesToHit.empty() == false):
			for adjEnemy in enemiesToHit:
				randomize()
				var hitChance = randi() % 100
				if (hitChance <= Player.cleaveChancePerc):
					# Reduce health
					var damageTotal = ceil(Player.strength / 3.0)
					adjEnemy.health -= damageTotal
					
					# Show damage text
					GameManager.create_damage_text(adjEnemy, damageTotal, '#ffffff')
					
					# Check if killed & gain xp (check for level-up)
					if (adjEnemy.health <= 0):
						adjEnemy.health
						
						# Check if ensnared == true to remove ensnareNode on death
						if (adjEnemy.ensnared == true):
							adjEnemy.ensnareNode.queue_free()
						
						# Check for level-up (every player)
						for player in GameManager.players:
							player.xpCurrent += adjEnemy.level
							player.level_up_check()
						
						# Destroy target
						adjEnemy.queue_free()

# Execute (Passive Skill)
func execute_target(target):
	# Camera Shake
	CameraNode.shake(15, 0.04, 0.5)
	
	# Reduce health to 0
	target.health = 0
	
	# Show executed text
	GameManager.create_status_text(target, "*executed*", '#ffffff')
	
	# Check if killed & gain xp (check for level-up)
	if (target.health <= 0):
		target.health = 0
		
		for player in GameManager.players:
			player.xpCurrent += target.level
			player.level_up_check()
		
		# Destroy target
		target.queue_free()
################################################################################################################
# Use leap (function to avoid code duplication)
func useLeap():
	if (Player.skillInVision == true && Player.position != to_global(PlayerTarget.position)):
		Player.targetMode = false # leave target mode
		
		# Leave skills toolbar
		HUD.get_node('Tween').stop_all()
		HUD.get_node('SkillsConfirmCancelButtons').position = Vector2(0, 0)
		HUD.get_node('SkillDetails').visible = false
		Player.skillSlots[Player.skillChooseIndex].scale = Vector2(1, 1)
		Player.skillSlots[Player.skillChooseIndex].modulate.a = 1
		
		# Reset Target (only visibility & collisions)
		PlayerTarget.visible = false
		PlayerTargetCollision.disabled = true
		
		# Reset RayCast
		Player.RayTarget.set_cast_to(PlayerTarget.position)
		Player.RayTarget.force_raycast_update()
		
		# Move player to target location
		Player.Tween.interpolate_property(Player, "position", Player.position, to_global(PlayerTargetSprite.get_parent().position), 0.8, Tween.TRANS_BACK, Tween.EASE_IN_OUT)
		Player.Tween.interpolate_property(PlayerSprite, "scale", Player.scale, Player.scale * 1.25, 0.4, Tween.TRANS_BACK, Tween.EASE_IN_OUT)
		Player.Tween.start()
		yield(get_tree().create_timer(0.4), "timeout")
		Player.Tween.interpolate_property(PlayerSprite, "scale", Player.scale, Player.scale, 0.4, Tween.TRANS_BACK, Tween.EASE_IN_OUT)
		Player.Tween.start()
		
		# Reset target (position)
		PlayerTarget.position = Vector2.ZERO
		
		# End Turn Variables
		Player.hasPlayed = true
		Player.active = false
		
		# Reduce player mana & set cooldown
		Player.mana -= Player.skillsManaCost[Player.skillChooseIndex]
		Player.skillsCooldownCurrent[Player.skillChooseIndex] = Player.skillsCooldown[Player.skillChooseIndex]
		
		# End Turn
		Player.z_index = 3
		yield(get_tree().create_timer(1.2), "timeout")
		Player.z_index = 2
		Player.end_turn()
