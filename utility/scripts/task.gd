extends Button # или другой ваш корневой узел

# Функция, которая будет вызвана при нажатии на кнопку
func _on_task_pressed():
	OS.shell_open("taskmgr")  # Открывает диспетчер задач в Windows
