extends Node2D
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.is_echo():
		if event.keycode == KEY_F1:
			var error = get_tree().change_scene_to_file("res://Game.tscn")
			if error != OK:
				print("Ошибка открытия пасхалки: ", error)
