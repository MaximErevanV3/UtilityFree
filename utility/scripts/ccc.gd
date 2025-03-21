extends Control

# Определяем пользовательский сигнал
signal CCC

# Ссылка на LineEdit
onready var path_input = $LineEdit # Убедитесь, что узел называется LineEdit
# Ссылка на кнопку
onready var open_button = $Button # Убедитесь, что узел называется Button

func _ready():
	# Подключаем сигнал нажатия кнопки к пользовательскому сигналу
	open_button.connect("pressed", self, "_on_open_button_pressed")
	# Подключаем пользовательский сигнал к функции
	connect("CCC", self, "_on_CCC_signal")

func _on_open_button_pressed():
	var folder_path = path_input.text
	if folder_path != "":
		# Эмитируем пользовательский сигнал
		emit_signal("CCC", folder_path)
	else:
		print("Пожалуйста, введите путь к папке!")

# Функция, обрабатывающая пользовательский сигнал
func _on_CCC_signal(folder_path):
	# Открываем папку, используя системную команду
	OS.shell_open(folder_path)
