extends Control

@onready var web_view: WebView = $WebView
var is_exiting: bool = false
var back_button: Button

func _ready() -> void:
	back_button = Button.new()
	back_button.text = "⬅ НАЗАД В УТИЛИТУ (ВЕРСИЯ 1.5)"
	back_button.custom_minimum_size = Vector2(0, 40)
	
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color("1e1e24")
	style_box.corner_radius_top_left = 6
	style_box.corner_radius_top_right = 6
	style_box.corner_radius_bottom_left = 6
	style_box.corner_radius_bottom_right = 6
	back_button.add_theme_stylebox_override("normal", style_box)
	
	add_child(back_button)
	back_button.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	back_button.offset_bottom = 40
	
	back_button.pressed.connect(_on_auto_back_pressed)
	
	if web_view:
		if web_view.has_method("initialize_with_window"):
			web_view.initialize_with_window(get_window())
		elif web_view.has_method("initialize"):
			web_view.call("initialize", get_window())
			
		web_view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		web_view.offset_top = 40
		
		web_view.load_url("https://neblock.vercel.app/")
	else:
		print("Критическая ошибка: Нода WebView не найдена в корне сцены!")

func _process(delta: float) -> void:
	if web_view and is_instance_valid(back_button):
		web_view.offset_top = 40

func _on_auto_back_pressed() -> void:
	if is_exiting:
		return
	is_exiting = true
	
	back_button.disabled = true
	back_button.text = "Очистка оперативной памяти Windows..."
	
	if web_view and web_view.has_method("terminate"):
		web_view.terminate()
		
	var error = get_tree().change_scene_to_file("res://node_2d.tscn")
	if error != OK:
		print("Не удалось вернуться на главную сцену: ", error)
