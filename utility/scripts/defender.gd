extends Button  # или другой ваш корневой узел

# Функция, которая будет вызвана при нажатии на кнопку
func _on_defender_pressed():
	OS.shell_open("ms-settings:windowsdefender")  # Открывает Microsoft Defender
