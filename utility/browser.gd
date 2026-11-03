extends Control

## Если true — WebView ужимается и показывается панель с кнопкой выхода.
## Если false — WebView на весь экран, выход только по ESC.
@export var use_toolbar: bool = false
@export var start_url: String = "https://google.com"

var webview: Node = null
var address_line: LineEdit


func _ready():
	anchors_preset = PRESET_FULL_RECT
	
	# 1. Ищем WebView на сцене (вы добавили его вручную)
	webview = _find_webview()
	if webview == null:
		push_error("❌ Добавьте ноду WebView в сцену Browser.tscn")
		return
	
	# 2. Строим UI в зависимости от режима
	if use_toolbar:
		_build_with_toolbar()
	else:
		_build_fullscreen()
	
	# 3. Стартовая страница
	_safe_call("load_url", start_url)


# ============================================
# РЕЖИМ 1: Полный экран (WebView перекрывает всё)
# ============================================
func _build_fullscreen():
	# full_window_size по умолчанию true — WebView на весь экран.
	# Godot-UI не виден поверх нативного окна, поэтому кнопки бесполезны.
	print("=== БРАУЗЕР (полный экран) ===")
	print("Нажмите ESC для выхода на главную сцену")
	print("===============================")


# ============================================
# РЕЖИМ 2: С панелью инструментов (кнопка видна)
# ============================================
func _build_with_toolbar():
	# Отключаем полноэкранный режим, чтобы WebView вписался в контейнер
	if "full_window_size" in webview:
		webview.full_window_size = false
	
	# Убираем WebView из текущего родителя (чтобы перенести в контейнер)
	var old_parent := webview.get_parent()
	if old_parent != null:
		old_parent.remove_child(webview)
	
	# --- Основной layout ---
	var vbox := VBoxContainer.new()
	vbox.anchors_preset = PRESET_FULL_RECT
	vbox.offset_left = 8
	vbox.offset_top = 8
	vbox.offset_right = -8
	vbox.offset_bottom = -8
	add_child(vbox)
	
	# --- Панель инструментов ---
	var toolbar := HBoxContainer.new()
	toolbar.custom_minimum_size = Vector2(0, 48)
	vbox.add_child(toolbar)
	
	_add_btn(toolbar, "←", _on_back, "Назад")
	_add_btn(toolbar, "→", _on_forward, "Вперёд")
	_add_btn(toolbar, "↻", _on_reload, "Обновить")
	
	address_line = LineEdit.new()
	address_line.placeholder_text = "Введите адрес..."
	address_line.size_flags_horizontal = SIZE_EXPAND_FILL
	address_line.text_submitted.connect(_on_go)
	toolbar.add_child(address_line)
	
	_add_btn(toolbar, "Перейти", _on_go)
	
	# ⬇⬇⬇ КНОПКА ВЫХОДА ⬇⬇⬇
	var btn_exit := Button.new()
	btn_exit.text = "❌ Выход"
	btn_exit.tooltip_text = "Вернуться на главную сцену (node_2d.tscn)"
	# Красный фон, чтобы было видно
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.75, 0.12, 0.12)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	btn_exit.add_theme_stylebox_override("normal", style)
	btn_exit.pressed.connect(_on_exit)
	toolbar.add_child(btn_exit)
	# ⬆⬆⬆ КНОПКА ВЫХОДА ⬆⬆⬆
	
	# --- Контейнер под WebView ---
	var web_container := Control.new()
	web_container.size_flags_vertical = SIZE_EXPAND_FILL
	vbox.add_child(web_container)
	
	# Помещаем WebView внутрь контейнера — он растянется на его размер
	web_container.add_child(webview)
	
	# Подписываемся на загрузку страницы
	if webview.has_signal("page_load_finished"):
		webview.page_load_finished.connect(_on_page_finished)


# ============================================
# Навигация
# ============================================
func _on_back():
	_safe_call("eval", "history.back();")

func _on_forward():
	_safe_call("eval", "history.forward();")

func _on_reload():
	_safe_call("reload")

func _on_go(_txt := ""):
	var url := address_line.text.strip_edges()
	if url.is_empty():
		return
	if not url.begins_with("http://") and not url.begins_with("https://"):
		url = "https://" + url
		address_line.text = url
	_safe_call("load_url", url)

func _on_exit():
	get_tree().change_scene_to_file("res://node_2d.tscn")

func _on_page_finished(url: String):
	if address_line != null:
		address_line.text = url


# ============================================
# Вспомогательные методы
# ============================================
func _find_webview() -> Node:
	for node in _get_all_children(self):
		if node.get_class() == "WebView":
			return node
	return null

func _get_all_children(node: Node) -> Array[Node]:
	var out: Array[Node] = []
	for c in node.get_children():
		out.append(c)
		out.append_array(_get_all_children(c))
	return out

func _add_btn(parent: Node, text: String, cb: Callable, tip := ""):
	var b := Button.new()
	b.text = text
	b.tooltip_text = tip
	b.pressed.connect(cb)
	parent.add_child(b)

func _safe_call(method: String, arg: Variant = null) -> bool:
	if webview == null or not webview.has_method(method):
		return false
	if arg == null:
		webview.call(method)
	else:
		webview.call(method, arg)
	return true


# ============================================
# Выход по ESC (работает ВСЕГДА, в обоих режимах)
# ============================================
func _process(_delta):
	# Опрос глобального состояния клавиш обходит перехват событий нативным WebView
	if Input.is_action_just_pressed("ui_cancel"):
		_on_exit()


func _unhandled_key_input(event):
	# Резервный вариант, если _process тоже заблокирован
	if event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		_on_exit()
