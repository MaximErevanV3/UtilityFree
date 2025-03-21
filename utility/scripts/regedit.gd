extends Button # или другой ваш корневой узел

# Функция, которая будет вызвана при нажатии на кнопку
func _on_regedit_pressed():
	OS.shell_open("regedit")  # Открывает редактор реестра
