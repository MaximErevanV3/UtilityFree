extends Button  # Указываем, что этот скрипт принадлежит кнопке


func _on_vk_pressed():
	var url = "https://vk.com/loxcheviti"  # Замените на нужный вам URL
	OS.shell_open(url)  # Открывает браузер с указанным URL
