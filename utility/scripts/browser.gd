extends Button  # Указываем, что этот скрипт принадлежит кнопке


func _on_browser_pressed():
	# Эта строчка закроет главное меню и откроет соцсеть
	get_tree().change_scene_to_file("res://Browser.tscn")
