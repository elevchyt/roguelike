extends Node2D

onready var GameManager = get_node("/root/World/GameManager")
onready var Player = get_parent()
onready var PlayerTarget = Player.get_node('Target')
onready var PlayerTargetSprite = Player.get_node('Target/TargetSprite')

# Skill Instances Pre-Load
onready var objFlare = preload('res://Scenes/Skills/Flare.tscn')

################################################################################################################
# Skill Use Function
func use_skill(skillName):
	print(Player.skillInVision)
	match skillName:
		'Flare':
			if (Player.skillInVision == true && (Player.position != to_global(PlayerTarget.position))):
				print(Player.name + ' used ' + Player.skills[Player.skillChooseIndex])
				
				var instance = objFlare.instance()
				var instanceSprite = instance.get_node("AnimatedSprite")
				var instanceTween = instance.get_node("Tween")
				
				instance.z_index = 10
				instanceSprite.look_at(PlayerTargetSprite.get_parent().position) # set rotation to target
				
				add_child(instance)
				
				# Shoot skill
				instanceTween.interpolate_property(instance, "position", instance.position, PlayerTargetSprite.get_parent().position, 0.5, instanceTween.TRANS_CIRC, instanceTween.EASE_IN_OUT)
				instanceTween.start()
