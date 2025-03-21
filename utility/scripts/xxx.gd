extends Button

func _on_XXX_pressed():
	var folder_path = "C:\\"  # Замените на нужный путь
	OS.shell_open(folder_path)
