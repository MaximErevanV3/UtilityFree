extends Control

# ============================================
# HTML ТЕСТИРОВЩИК — полный экран, крупные кнопки
# WebView уже должен быть на сцене
# ============================================

@export var start_url: String = "about:blank"

var webview: Node = null
var address_line: LineEdit
var status_label: Label
var file_dialog: FileDialog
var paste_dialog: Window
var paste_text_edit: TextEdit


func _ready():
	anchors_preset = PRESET_FULL_RECT
	
	# === Фон ===
	var bg := ColorRect.new()
	bg.name = "Background"
	bg.color = Color("0d1117")
	bg.anchors_preset = PRESET_FULL_RECT
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	
	# === Ищем WebView ===
	webview = _find_webview()
	if webview == null:
		push_error("❌ Добавьте ноду WebView в сцену")
		return
	
	if "full_window_size" in webview:
		webview.full_window_size = false
	
	# === СТРОИМ UI ===
	_build_ui()
	_build_paste_dialog()
	_build_file_dialog()
	_connect_signals()
	
	_safe_call("load_url", start_url)
	_update_status("Готов. Нажмите «Открыть» для выбора .html файла.")


# ============================================
# ГЛАВНЫЙ UI — ПРАВИЛЬНАЯ ИЕРАРХИЯ НА ВЕСЬ ЭКРАН
# ============================================
func _build_ui():
	# Корневой MarginContainer — отступы от краёв окна
	var root_margin := MarginContainer.new()
	root_margin.name = "RootMargin"
	root_margin.anchors_preset = PRESET_FULL_RECT
	root_margin.add_theme_constant_override("margin_left", 24)
	root_margin.add_theme_constant_override("margin_top", 24)
	root_margin.add_theme_constant_override("margin_right", 24)
	root_margin.add_theme_constant_override("margin_bottom", 24)
	add_child(root_margin)
	
	# VBox растягивается на всё пространство внутри margin
	var vbox := VBoxContainer.new()
	vbox.name = "MainVBox"
	vbox.add_theme_constant_override("separation", 16)
	root_margin.add_child(vbox)
	
	# --- TOOLBAR ---
	var toolbar_panel := PanelContainer.new()
	toolbar_panel.name = "Toolbar"
	toolbar_panel.custom_minimum_size = Vector2(0, 72)
	vbox.add_child(toolbar_panel)
	
	var toolbar_style := StyleBoxFlat.new()
	toolbar_style.bg_color = Color("161b22")
	toolbar_style.border_color = Color("30363d")
	toolbar_style.border_width_bottom = 1
	toolbar_style.corner_radius_top_left = 16
	toolbar_style.corner_radius_top_right = 16
	toolbar_style.corner_radius_bottom_left = 16
	toolbar_style.corner_radius_bottom_right = 16
	toolbar_style.shadow_color = Color("000000")
	toolbar_style.shadow_size = 12
	toolbar_style.shadow_offset = Vector2(0, 6)
	toolbar_panel.add_theme_stylebox_override("panel", toolbar_style)
	
	var toolbar_margin := MarginContainer.new()
	toolbar_margin.add_theme_constant_override("margin_left", 20)
	toolbar_margin.add_theme_constant_override("margin_right", 20)
	toolbar_margin.add_theme_constant_override("margin_top", 14)
	toolbar_margin.add_theme_constant_override("margin_bottom", 14)
	toolbar_panel.add_child(toolbar_margin)
	
	var toolbar := HBoxContainer.new()
	toolbar.alignment = BoxContainer.ALIGNMENT_CENTER
	toolbar.add_theme_constant_override("separation", 12)
	toolbar_margin.add_child(toolbar)
	
	# Кнопки
	_add_toolbar_btn(toolbar, "📂  Открыть файл", _on_open_file, "Выбрать .html через проводник", Color("238636"))
	_add_toolbar_btn(toolbar, "📋  Вставить код", _on_paste_html, "Вставить HTML-код вручную", Color("1f6feb"))
	_add_toolbar_btn(toolbar, "↻  Обновить", _on_reload, "Перезагрузить", Color("6e7681"))
	
	toolbar.add_child(_create_vsep())
	
	# Адресная строка
	address_line = LineEdit.new()
	address_line.placeholder_text = "Введите URL или перетащите .html файл..."
	address_line.size_flags_horizontal = SIZE_EXPAND_FILL
	address_line.text_submitted.connect(_on_go)
	address_line.add_theme_color_override("font_color", Color("e6edf3"))
	address_line.add_theme_color_override("font_placeholder_color", Color("6e7681"))
	address_line.add_theme_font_size_override("font_size", 15)
	
	var addr_style := StyleBoxFlat.new()
	addr_style.bg_color = Color("0d1117")
	addr_style.border_color = Color("30363d")
	addr_style.border_width_left = 1
	addr_style.border_width_top = 1
	addr_style.border_width_right = 1
	addr_style.border_width_bottom = 1
	addr_style.corner_radius_top_left = 12
	addr_style.corner_radius_top_right = 12
	addr_style.corner_radius_bottom_left = 12
	addr_style.corner_radius_bottom_right = 12
	addr_style.content_margin_left = 18
	addr_style.content_margin_right = 18
	addr_style.content_margin_top = 10
	addr_style.content_margin_bottom = 10
	
	var addr_focus := addr_style.duplicate()
	addr_focus.border_color = Color("58a6ff")
	addr_focus.border_width_bottom = 2
	
	address_line.add_theme_stylebox_override("normal", addr_style)
	address_line.add_theme_stylebox_override("focus", addr_focus)
	toolbar.add_child(address_line)
	
	_add_toolbar_btn(toolbar, "▶", _on_go, "Перейти", Color("1f6feb"))
	
	toolbar.add_child(_create_vsep())
	
	_add_toolbar_btn(toolbar, "✕  Выход", _on_exit, "В главное меню", Color("da3633"))
	
	# --- WEBVIEW (растягивается на всё оставшееся) ---
	var web_panel := PanelContainer.new()
	web_panel.name = "WebPanel"
	web_panel.size_flags_vertical = SIZE_EXPAND_FILL
	vbox.add_child(web_panel)
	
	var web_style := StyleBoxFlat.new()
	web_style.bg_color = Color("0d1117")
	web_style.border_color = Color("30363d")
	web_style.border_width_left = 1
	web_style.border_width_top = 1
	web_style.border_width_right = 1
	web_style.border_width_bottom = 1
	web_style.corner_radius_top_left = 16
	web_style.corner_radius_top_right = 16
	web_style.corner_radius_bottom_left = 16
	web_style.corner_radius_bottom_right = 16
	web_style.shadow_color = Color("000000")
	web_style.shadow_size = 14
	web_style.shadow_offset = Vector2(0, 7)
	web_panel.add_theme_stylebox_override("panel", web_style)
	
	var web_margin := MarginContainer.new()
	web_margin.add_theme_constant_override("margin_left", 4)
	web_margin.add_theme_constant_override("margin_top", 4)
	web_margin.add_theme_constant_override("margin_right", 4)
	web_margin.add_theme_constant_override("margin_bottom", 4)
	web_panel.add_child(web_margin)
	
	# Переносим WebView
	var old_parent := webview.get_parent()
	if old_parent != null and old_parent != web_margin:
		old_parent.remove_child(webview)
	elif webview.get_parent() == null:
		pass
	
	webview.anchors_preset = PRESET_FULL_RECT
	webview.offset_left = 0
	webview.offset_top = 0
	webview.offset_right = 0
	webview.offset_bottom = 0
	web_margin.add_child(webview)
	
	# --- СТАТУС-БАР ---
	var status_panel := PanelContainer.new()
	status_panel.name = "StatusBar"
	status_panel.custom_minimum_size = Vector2(0, 44)
	vbox.add_child(status_panel)
	
	var status_style := StyleBoxFlat.new()
	status_style.bg_color = Color("161b22")
	status_style.border_color = Color("30363d")
	status_style.border_width_top = 1
	status_style.corner_radius_top_left = 14
	status_style.corner_radius_top_right = 14
	status_style.corner_radius_bottom_left = 14
	status_style.corner_radius_bottom_right = 14
	status_panel.add_theme_stylebox_override("panel", status_style)
	
	var status_margin := MarginContainer.new()
	status_margin.add_theme_constant_override("margin_left", 20)
	status_margin.add_theme_constant_override("margin_right", 20)
	status_margin.add_theme_constant_override("margin_top", 11)
	status_margin.add_theme_constant_override("margin_bottom", 11)
	status_panel.add_child(status_margin)
	
	status_label = Label.new()
	status_label.text = "Загрузка..."
	status_label.add_theme_color_override("font_color", Color("8b949e"))
	status_label.add_theme_font_size_override("font_size", 14)
	status_margin.add_child(status_label)


# ============================================
# ДИАЛОГ: ВСТАВИТЬ HTML-КОД
# ============================================
func _build_paste_dialog():
	paste_dialog = Window.new()
	paste_dialog.name = "PasteDialog"
	paste_dialog.title = "Вставить HTML-код"
	paste_dialog.size = Vector2i(1000, 700)
	paste_dialog.min_size = Vector2i(700, 500)
	paste_dialog.close_requested.connect(func(): paste_dialog.hide())
	add_child(paste_dialog)
	
	# Фон
	var bg := ColorRect.new()
	bg.color = Color("0d1117")
	bg.anchors_preset = PRESET_FULL_RECT
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	paste_dialog.add_child(bg)
	
	# Margin
	var margin := MarginContainer.new()
	margin.anchors_preset = PRESET_FULL_RECT
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_top", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_bottom", 28)
	paste_dialog.add_child(margin)
	
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	margin.add_child(vbox)
	
	# Заголовок
	var title := Label.new()
	title.text = "📝  Редактор HTML"
	title.add_theme_color_override("font_color", Color("e6edf3"))
	title.add_theme_font_size_override("font_size", 22)
	vbox.add_child(title)
	
	var hint := Label.new()
	hint.text = "Вставьте HTML-код и нажмите «Запустить»"
	hint.add_theme_color_override("font_color", Color("8b949e"))
	hint.add_theme_font_size_override("font_size", 14)
	vbox.add_child(hint)
	
	# TextEdit
	paste_text_edit = TextEdit.new()
	paste_text_edit.size_flags_vertical = SIZE_EXPAND_FILL
	paste_text_edit.placeholder_text = "<!DOCTYPE html>\n<html>\n<head>\n  <style>body { font-family: sans-serif; }</style>\n</head>\n<body>\n  <h1>Hello World</h1>\n</body>\n</html>"
	paste_text_edit.add_theme_color_override("font_color", Color("e6edf3"))
	paste_text_edit.add_theme_color_override("font_placeholder_color", Color("484f58"))
	paste_text_edit.add_theme_color_override("background_color", Color("0d1117"))
	paste_text_edit.add_theme_color_override("caret_color", Color("58a6ff"))
	paste_text_edit.add_theme_font_size_override("font_size", 14)
	paste_text_edit.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	paste_text_edit.highlight_current_line = true
	paste_text_edit.minimap_draw = true
	paste_text_edit.minimap_width = 100
	
	var te_style := StyleBoxFlat.new()
	te_style.bg_color = Color("161b22")
	te_style.border_color = Color("30363d")
	te_style.border_width_left = 1
	te_style.border_width_top = 1
	te_style.border_width_right = 1
	te_style.border_width_bottom = 1
	te_style.corner_radius_top_left = 14
	te_style.corner_radius_top_right = 14
	te_style.corner_radius_bottom_left = 14
	te_style.corner_radius_bottom_right = 14
	te_style.content_margin_left = 16
	te_style.content_margin_right = 16
	te_style.content_margin_top = 16
	te_style.content_margin_bottom = 16
	paste_text_edit.add_theme_stylebox_override("normal", te_style)
	paste_text_edit.add_theme_stylebox_override("focus", te_style)
	vbox.add_child(paste_text_edit)
	
	# Кнопки
	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_END
	btn_row.add_theme_constant_override("separation", 14)
	vbox.add_child(btn_row)
	
	var btn_run := Button.new()
	btn_run.text = "▶  Запустить"
	btn_run.pressed.connect(_on_run_pasted_html)
	_style_big_btn(btn_run, Color("238636"))
	btn_row.add_child(btn_run)
	
	var btn_close := Button.new()
	btn_close.text = "✕  Отмена"
	btn_close.pressed.connect(func(): paste_dialog.hide())
	_style_big_btn(btn_close, Color("30363d"))
	btn_row.add_child(btn_close)


# ============================================
# ДИАЛОГ: СИСТЕМНЫЙ ПРОВОДНИК (строго .html)
# ============================================
func _build_file_dialog():
	file_dialog = FileDialog.new()
	file_dialog.name = "FileDialog"
	file_dialog.title = "Выберите HTML-файл"
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	file_dialog.access = FileDialog.ACCESS_FILESYSTEM  # ← системный проводник Windows/Linux/macOS
	file_dialog.filters = PackedStringArray(["*.html ; HTML файлы"])
	file_dialog.file_selected.connect(_on_file_selected)
	file_dialog.canceled.connect(func(): _update_status("Отменено"))
	add_child(file_dialog)


# ============================================
# СТИЛИ — УВЕЛИЧЕННЫЕ КНОПКИ
# ============================================
func _add_toolbar_btn(parent: Node, text: String, cb: Callable, tip: String, accent: Color):
	var btn := Button.new()
	btn.text = text
	btn.tooltip_text = tip
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.add_theme_font_size_override("font_size", 15)
	
	var normal := StyleBoxFlat.new()
	normal.bg_color = accent.darkened(0.1)
	normal.corner_radius_top_left = 12
	normal.corner_radius_top_right = 12
	normal.corner_radius_bottom_left = 12
	normal.corner_radius_bottom_right = 12
	normal.content_margin_left = 18
	normal.content_margin_right = 18
	normal.content_margin_top = 10
	normal.content_margin_bottom = 10
	
	var hover := normal.duplicate()
	hover.bg_color = accent
	
	var pressed := normal.duplicate()
	pressed.bg_color = accent.darkened(0.3)
	
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_color_override("font_color", Color("ffffff"))
	btn.pressed.connect(cb)
	parent.add_child(btn)
	return btn

func _style_big_btn(btn: Button, color: Color):
	var normal := StyleBoxFlat.new()
	normal.bg_color = color
	normal.corner_radius_top_left = 12
	normal.corner_radius_top_right = 12
	normal.corner_radius_bottom_left = 12
	normal.corner_radius_bottom_right = 12
	normal.content_margin_left = 24
	normal.content_margin_right = 24
	normal.content_margin_top = 12
	normal.content_margin_bottom = 12
	
	var hover := normal.duplicate()
	hover.bg_color = color.lightened(0.12)
	
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_color_override("font_color", Color("ffffff"))
	btn.add_theme_font_size_override("font_size", 15)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

func _create_vsep() -> VSeparator:
	var sep := VSeparator.new()
	sep.add_theme_constant_override("separation", 18)
	sep.modulate = Color("30363d")
	return sep


# ============================================
# СИГНАЛЫ
# ============================================
func _connect_signals():
	if webview == null:
		return
	if webview.has_signal("page_load_finished"):
		if not webview.is_connected("page_load_finished", _on_page_finished):
			webview.page_load_finished.connect(_on_page_finished)
	if not get_viewport().files_dropped.is_connected(_on_files_dropped):
		get_viewport().files_dropped.connect(_on_files_dropped)


# ============================================
# ОБРАБОТЧИКИ
# ============================================
func _on_open_file():
	# ← Открывает СИСТЕМНЫЙ проводник (Windows Explorer / macOS Finder / Linux GTK)
	file_dialog.popup_centered(Vector2i(1100, 750))
	_update_status("Ожидание выбора файла...")

func _on_paste_html():
	# ← Открывает окно для ВВОДА КОДА
	paste_dialog.popup_centered(Vector2i(1000, 700))
	_update_status("Режим вставки HTML-кода")

func _on_reload():
	_safe_call("reload")
	_update_status("Перезагрузка...")

func _on_go(_txt := ""):
	var url := address_line.text.strip_edges()
	if url.is_empty():
		return
	_safe_call("load_url", url)
	_update_status("Загрузка...")

func _on_exit():
	get_tree().change_scene_to_file("res://node_2d.tscn")

func _on_page_finished(url: String):
	if address_line != null and not url.is_empty() and url != "about:blank":
		address_line.text = url
	_update_status("✓ Готово")

func _on_file_selected(path: String):
	# Строго только .html
	if not path.ends_with(".html"):
		_update_status("❌ Можно открывать только .html файлы")
		return
	
	if path.begins_with("res://"):
		_safe_call("load_url", path)
		address_line.text = path
		_update_status("✓ Загружено: " + path.get_file())
		return
	
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		_update_status("❌ Не удалось открыть файл")
		return
	
	var html := file.get_as_text()
	file.close()
	
	_load_html_string(html)
	address_line.text = path
	_update_status("✓ Файл: " + path.get_file())

func _on_run_pasted_html():
	if paste_text_edit == null:
		return
	var html := paste_text_edit.text
	if html.strip_edges().is_empty():
		_update_status("❌ HTML-код пуст")
		return
	
	_load_html_string(html)
	paste_dialog.hide()
	address_line.text = "data:text/html (вставленный код)"
	_update_status("✓ Вставленный HTML запущен")

func _on_files_dropped(files: PackedStringArray):
	for f in files:
		if f.ends_with(".html"):
			_on_file_selected(f)
			return
	_update_status("❌ Перетащите только .html файл")

func _load_html_string(html: String):
	var bytes := html.to_utf8_buffer()
	var base64 := Marshalls.raw_to_base64(bytes)
	var data_uri := "data:text/html;base64," + base64
	_safe_call("load_url", data_uri)


# ============================================
# ВСПОМОГАТЕЛЬНЫЕ
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

func _safe_call(method: String, arg: Variant = null) -> bool:
	if webview == null or not webview.has_method(method):
		_update_status("❌ WebView недоступен")
		return false
	if arg == null:
		webview.call(method)
	else:
		webview.call(method, arg)
	return true

func _update_status(msg: String):
	if status_label != null:
		status_label.text = msg
	print("HTML Tester: ", msg)


# ============================================
# ВЫХОД ПО ESC
# ============================================
func _process(_delta):
	if Input.is_action_just_pressed("ui_cancel"):
		_on_exit()

func _unhandled_key_input(event):
	if event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		_on_exit()
