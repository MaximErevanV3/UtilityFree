extends Button

var password_label: Label

const LOWERCASE = "abcdefghijklmnopqrstuvwxyz"
const UPPERCASE = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
const DIGITS = "0123456789"
const SYMBOLS = "!@#$%^&*()-_=+[{]};:,.<>/"

func _ready() -> void:
	self.pressed.connect(_generate_complex_password)
	_find_password_label(get_tree().current_scene)

func _find_password_label(node: Node) -> void:
	if node is Label and (node.name == "PasswordLabel" or "password" in node.name.to_lower()):
		password_label = node
		return
	for child in node.get_children():
		_find_password_label(child)
		if password_label:
			return

func _generate_complex_password() -> void:
	if not is_instance_valid(password_label):
		if has_node("../PasswordLabel"):
			password_label = get_node("../PasswordLabel") as Label
			
	if not is_instance_valid(password_label):
		push_error("PasswordLabel is not assigned or invalid!")
		return
		
	var crypto = Crypto.new()
	var password_length: int = 16
	var password_bytes: PackedByteArray = crypto.generate_random_bytes(password_length)
	
	var pool_required: Array[String] = [LOWERCASE, UPPERCASE, DIGITS, SYMBOLS]
	var all_characters: String = LOWERCASE + UPPERCASE + DIGITS + SYMBOLS
	var password_chars: Array[String] = []
	
	for i in range(pool_required.size()):
		var byte_val: int = password_bytes[i]
		var pool: String = pool_required[i]
		password_chars.append(pool[byte_val % pool.length()])
		
	for i in range(pool_required.size(), password_length):
		var byte_val: int = password_bytes[i]
		password_chars.append(all_characters[byte_val % all_characters.length()])
		
	var shuffle_bytes: PackedByteArray = crypto.generate_random_bytes(password_length)
	for i in range(password_length - 1, 0, -1):
		var j: int = shuffle_bytes[i] % (i + 1)
		var temp: String = password_chars[i]
		password_chars[i] = password_chars[j]
		password_chars[j] = temp
		
	var generated_password: String = "".join(password_chars)
	
	password_label.text = generated_password
	DisplayServer.clipboard_set(generated_password)
