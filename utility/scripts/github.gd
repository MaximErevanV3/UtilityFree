extends Button  # Указываем, что этот скрипт принадлежит кнопке


func _on_github_pressed():
	var url = "https://github.com/MaximErevanV3/UtilityFree"  # Замените на нужный вам URL
	OS.shell_open(url)  # Открывает браузер с указанным URL
