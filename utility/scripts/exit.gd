extends Button
# Функция, которая будет вызвана при нажатии на кнопку
func _on_exit_pressed():
	get_tree().quit()  # Закрывает приложение
