extends Button

# Этот метод будет вызван, когда кнопка будет нажата
func _on_Button_pressed():
	# Открываем командную строку
	OS.shell_open("cmd.exe")
