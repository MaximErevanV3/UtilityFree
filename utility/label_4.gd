extends Label

# Таймер для обновления информации о памяти
var memory_timer = 0.0
var update_interval = 1.0  # Интервал обновления в секундах

func _ready():
	# Устанавливаем начальный текст
	text = "Загрузка информации о памяти..."

func _process(delta):
	# Увеличиваем таймер
	memory_timer += delta

	# Проверяем, прошло ли достаточно времени для обновления
	if memory_timer >= update_interval:
		memory_timer = 0.0  # Сбрасываем таймер
		update_memory_info()  # Обновляем информацию о памяти

func update_memory_info():
	# Получаем информацию о памяти
	var memory_info = OS.get_memory_info()

	# Проверяем наличие ключей 'used' и 'total' в словаре
	if "used" in memory_info and "total" in memory_info:
		var used_memory = memory_info["used"] / (1024 * 1024)  # Используемая память в МБ
		var total_memory = memory_info["total"] / (1024 * 1024)  # Общая память в МБ

		# Обновляем текст на экране
		text = "Используемая ОЗУ: %.2f МБ\nОбщая ОЗУ: %.2f МБ" % [used_memory, total_memory]
	else:
		text = "Ошибка: информация о памяти недоступна."
