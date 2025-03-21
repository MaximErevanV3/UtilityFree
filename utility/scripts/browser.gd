extends Button  # Указываем, что этот скрипт принадлежит кнопке


func _on_browser_pressed():
	var url = "https://google.com"  # Замените на нужный вам URL
	OS.shell_open(url)  # Открывает браузер с указанным URL
