extends Control

func _on_startup_pressed() -> void:
	# Путь в реестре, который мы хотим показать пользователю
	var target_path: String = "HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Run"
	
	# Внутренний путь настроек regedit, чтобы задать последнее открытое окно
	var reg_path: String = "HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Applets\\Regedit"
	
	# Исправленный вызов: передаем пустой массив [] для сбора вывода, 
	# а затем true, чтобы дождаться записи в реестр перед открытием окна
	var output = []
	OS.execute("cmd.exe", ["/c", "reg add \"" + reg_path + "\" /v LastKey /t REG_SZ /d \"" + target_path + "\" /f"], output, true)
	
	# Запускаем сам Редактор реестра
	OS.execute("cmd.exe", ["/c", "start regedit.exe"])
