extends Button # Скрипт висит прямо на кнопке, поэтому наследуемся от Button

# Узел PasswordLabel лежит на один уровень выше (у родителя Node2D),
# поэтому мы используем путь "../PasswordLabel"
@onready var password_label: Label = $"../PasswordLabel"

const LOWERCASE = "abcdefghijklmnopqrstuvwxyz"
const UPPERCASE = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
const DIGITS = "0123456789"
const SYMBOLS = "!@#$%^&*()-_=+[{]};:,.<>/? "

func _ready() -> void:
	# Так как скрипт на кнопке, связываем встроенный сигнал pressed сам с собой
	self.pressed.connect(_generate_complex_password)

func _generate_complex_password() -> void:
	if password_label == null:
		push_error("Критическая ошибка: Узел с именем PasswordLabel не найден рядом с кнопкой!")
		return
		
	var password_length: int = 16
	var all_characters: String = LOWERCASE + UPPERCASE + DIGITS + SYMBOLS
	var generated_password: String = ""
	
	var crypto = RandomNumberGenerator.new()
	crypto.randomize()
	
	for i in range(password_length):
		var random_index: int = crypto.randi_range(0, all_characters.length() - 1)
		generated_password += all_characters[random_index]
	
	# Выводим результат и копируем в буфер Windows
	password_label.text = generated_password
	DisplayServer.clipboard_set(generated_password)
