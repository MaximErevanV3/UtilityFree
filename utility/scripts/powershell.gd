extends Button # или другой ваш корневой узел

# Функция, которая будет вызвана при нажатии на кнопку
func _on_power_pressed():
	OS.shell_open("powershell")  # Открывает PowerShell
