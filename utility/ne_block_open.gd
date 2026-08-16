extends Control
func _on_social_button_pressed() -> void:
	# Эта строчка закроет главное меню и откроет соцсеть
	get_tree().change_scene_to_file("res://SocialScene.tscn")
