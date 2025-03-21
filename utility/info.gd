extends Label

func _ready():
	# Получаем информацию о компьютере
	var info = ""
	info += "Операционная система: " + OS.get_name() + "\n"
	info += "Версия ОС: " + OS.get_version() + "\n"
	info += "Количество ядер: " + str(OS.get_processor_count()) + "\n"

	# Устанавливаем текст в Label
	self.text = info
