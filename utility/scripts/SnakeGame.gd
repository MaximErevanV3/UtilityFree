extends Node2D

# ========== НАСТРОЙКИ СЕТКИ ==========
@export var grid_size: int = 32
@export var grid_width: int = 24
@export var grid_height: int = 18
@export var move_delay: float = 0.12

# ========== СОСТОЯНИЕ ИГРЫ ==========
var curr_snake: Array[Vector2] = []
var prev_snake: Array[Vector2] = []
var direction: Vector2 = Vector2.RIGHT
var next_direction: Vector2 = Vector2.RIGHT
var apple: Vector2 = Vector2.ZERO

var score: int = 0
var high_score: int = 0
var game_over: bool = false

var move_timer: float = 0.0
var pulse_time: float = 0.0
var score_bounce: float = 1.0

# ========== UI ==========
var score_label: Label
var high_label: Label
var back_button: Button
var game_over_panel: Panel
var result_label: Label  # ← ССЫЛКА НА ResultLabel

# ========== ЛЕЙАУТ ==========
var field_offset: Vector2 = Vector2.ZERO
var current_cell_size: float = 32.0


func _ready() -> void:
	_load_high_score()
	_setup_ui()
	_start_game()
	get_tree().root.size_changed.connect(_on_window_resized)
	_on_window_resized()


func _process(delta: float) -> void:
	pulse_time += delta
	score_bounce = lerp(score_bounce, 1.0, delta * 8.0)
	if score_label:
		score_label.scale = Vector2.ONE * score_bounce

	if game_over:
		queue_redraw()
		return

	move_timer += delta
	if move_timer >= move_delay:
		move_timer -= move_delay
		_move_snake()

	queue_redraw()


func _input(event: InputEvent) -> void:
	if game_over:
		if event.is_action_pressed("ui_accept") or (event is InputEventMouseButton and event.pressed):
			_hide_game_over()
			_start_game()
		return

	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_RIGHT, KEY_D:
				if direction != Vector2.LEFT: next_direction = Vector2.RIGHT
			KEY_LEFT, KEY_A:
				if direction != Vector2.RIGHT: next_direction = Vector2.LEFT
			KEY_UP, KEY_W:
				if direction != Vector2.DOWN: next_direction = Vector2.UP
			KEY_DOWN, KEY_S:
				if direction != Vector2.UP: next_direction = Vector2.DOWN


func _move_snake() -> void:
	direction = next_direction
	prev_snake = curr_snake.duplicate()

	var head: Vector2 = curr_snake[0] + direction

	if head.x < 0 or head.x >= grid_width or head.y < 0 or head.y >= grid_height:
		_trigger_game_over()
		return

	if head in curr_snake:
		_trigger_game_over()
		return

	curr_snake.insert(0, head)

	if head == apple:
		score += 1
		score_label.text = "Счёт: %d" % score
		score_bounce = 1.35
		_spawn_eat_particles(_grid_to_pixel(apple) + Vector2.ONE * current_cell_size * 0.5)
		_spawn_apple()
		prev_snake.append(prev_snake[-1])
	else:
		curr_snake.pop_back()


func _spawn_apple() -> void:
	randomize()
	while true:
		var pos = Vector2(randi() % grid_width, randi() % grid_height)
		if not pos in curr_snake:
			apple = pos
			break


func _trigger_game_over() -> void:
	game_over = true
	if score > high_score:
		high_score = score
		_save_high_score()
	_show_game_over()


func _draw() -> void:
	var total_w: float = grid_width * current_cell_size
	var total_h: float = grid_height * current_cell_size
	var field_rect := Rect2(field_offset, Vector2(total_w, total_h))

	# Фон поля
	draw_rect(field_rect, Color("0b0f19"), true)

	# Сетка
	var grid_color := Color("1e293b")
	for x in range(grid_width + 1):
		var fx: float = field_offset.x + x * current_cell_size
		draw_line(Vector2(fx, field_offset.y), Vector2(fx, field_offset.y + total_h), grid_color, 1.0)
	for y in range(grid_height + 1):
		var fy: float = field_offset.y + y * current_cell_size
		draw_line(Vector2(field_offset.x, fy), Vector2(field_offset.x + total_w, fy), grid_color, 1.0)

	var t: float = clamp(move_timer / move_delay, 0.0, 1.0)

	# Яблоко
	var apple_pulse: float = 1.0 + 0.08 * sin(pulse_time * 5.0)
	var apple_vis: Vector2 = _grid_to_pixel(apple) + Vector2.ONE * current_cell_size * 0.5
	var apple_r: float = current_cell_size * 0.32 * apple_pulse

	draw_circle(apple_vis + Vector2(3, 3), apple_r, Color(0, 0, 0, 0.3))
	draw_circle(apple_vis, apple_r, Color("ef4444"))

	var glint_r: float = apple_r * 0.35
	var glint_pos: Vector2 = apple_vis + Vector2(-apple_r * 0.3, -apple_r * 0.35)
	draw_circle(glint_pos, glint_r, Color("fca5a5"))

	# Змейка
	var seg_count: int = curr_snake.size()
	for i in range(seg_count):
		var vis_grid: Vector2
		if i < prev_snake.size():
			vis_grid = prev_snake[i].lerp(curr_snake[i], t)
		else:
			vis_grid = curr_snake[i]

		var pixel_pos: Vector2 = _grid_to_pixel(vis_grid)
		var center: Vector2 = pixel_pos + Vector2.ONE * current_cell_size * 0.5

		if i == 0:
			var head_r: float = current_cell_size * 0.42
			draw_circle(center + Vector2(3, 3), head_r, Color(0, 0, 0, 0.35))
			draw_circle(center, head_r, Color("4ade80"))
			_draw_eyes(center, head_r)
		else:
			var body_size: float = current_cell_size - 4
			var body_rect := Rect2(pixel_pos + Vector2.ONE * 2, Vector2.ONE * body_size)
			var ratio: float = float(i) / float(max(seg_count - 1, 1))
			var body_color: Color = Color("22c55e").lerp(Color("14532d"), ratio)

			# Тень сегмента
			var shadow_rect := body_rect.grow_individual(0, 0, -2, -2)
			shadow_rect.position += Vector2(3, 3)
			draw_rect(shadow_rect, Color(0, 0, 0, 0.25), true)

			draw_rect(body_rect, body_color, true)


func _draw_eyes(head_center: Vector2, head_r: float) -> void:
	var eye_offset: float = head_r * 0.35
	var eye_r: float = head_r * 0.22
	var pupil_r: float = head_r * 0.10

	var look_dir: Vector2 = direction.normalized()
	if look_dir == Vector2.ZERO:
		look_dir = Vector2.RIGHT

	var perp := Vector2(-look_dir.y, look_dir.x)

	var left_eye: Vector2 = head_center + look_dir * eye_offset * 0.6 + perp * eye_offset * 0.7
	var right_eye: Vector2 = head_center + look_dir * eye_offset * 0.6 - perp * eye_offset * 0.7

	draw_circle(left_eye, eye_r, Color.WHITE)
	draw_circle(right_eye, eye_r, Color.WHITE)

	var pupil_shift: Vector2 = look_dir * eye_r * 0.4
	draw_circle(left_eye + pupil_shift, pupil_r, Color("0f172a"))
	draw_circle(right_eye + pupil_shift, pupil_r, Color("0f172a"))


func _spawn_eat_particles(world_pos: Vector2) -> void:
	var p := CPUParticles2D.new()
	p.position = world_pos
	p.amount = 16
	p.lifetime = 0.5
	p.one_shot = true
	p.explosiveness = 0.9
	p.direction = Vector2(0, -1)
	p.spread = 100.0
	p.gravity = Vector2(0, 300)
	p.initial_velocity_min = 80
	p.initial_velocity_max = 180
	p.scale_amount_min = 2.0
	p.scale_amount_max = 5.0
	p.color = Color("fbbf24")
	add_child(p)
	p.emitting = true

	await get_tree().create_timer(0.7).timeout
	p.queue_free()


func _setup_ui() -> void:
	back_button = Button.new()
	back_button.text = "❌ Выход в меню"
	back_button.position = Vector2(20, 20)
	back_button.custom_minimum_size = Vector2(160, 45)
	var btn_style := StyleBoxFlat.new()
	btn_style.bg_color = Color("1e1e24")
	btn_style.border_color = Color("334155")
	btn_style.border_width_bottom = 3
	btn_style.corner_radius_top_left = 8
	btn_style.corner_radius_top_right = 8
	btn_style.corner_radius_bottom_left = 8
	btn_style.corner_radius_bottom_right = 8
	back_button.add_theme_stylebox_override("normal", btn_style)

	var btn_hover: StyleBoxFlat = btn_style.duplicate()
	btn_hover.bg_color = Color("27272e")
	back_button.add_theme_stylebox_override("hover", btn_hover)

	add_child(back_button)
	back_button.pressed.connect(_on_back_pressed)

	score_label = Label.new()
	score_label.text = "Счёт: 0"
	score_label.position = Vector2(200, 24)
	score_label.add_theme_font_size_override("font_size", 28)
	score_label.add_theme_color_override("font_color", Color("e2e8f0"))
	score_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
	score_label.add_theme_constant_override("shadow_offset_x", 2)
	score_label.add_theme_constant_override("shadow_offset_y", 2)
	add_child(score_label)

	high_label = Label.new()
	high_label.text = "Рекорд: 0"
	high_label.position = Vector2(200, 58)
	high_label.add_theme_font_size_override("font_size", 16)
	high_label.add_theme_color_override("font_color", Color("94a3b8"))
	add_child(high_label)

	game_over_panel = Panel.new()
	game_over_panel.anchors_preset = Control.PRESET_CENTER
	game_over_panel.custom_minimum_size = Vector2(360, 220)
	game_over_panel.visible = false
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color("0f172a")
	panel_style.border_color = Color("334155")
	panel_style.border_width_left = 2
	panel_style.border_width_top = 2
	panel_style.border_width_right = 2
	panel_style.border_width_bottom = 2
	panel_style.corner_radius_top_left = 12
	panel_style.corner_radius_top_right = 12
	panel_style.corner_radius_bottom_left = 12
	panel_style.corner_radius_bottom_right = 12
	panel_style.shadow_color = Color(0, 0, 0, 0.5)
	panel_style.shadow_size = 12
	game_over_panel.add_theme_stylebox_override("panel", panel_style)
	add_child(game_over_panel)

	var vbox := VBoxContainer.new()
	vbox.anchors_preset = Control.PRESET_FULL_RECT
	vbox.offset_left = 20
	vbox.offset_top = 20
	vbox.offset_right = -20
	vbox.offset_bottom = -20
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	game_over_panel.add_child(vbox)

	var title := Label.new()
	title.text = "💀 ИГРА ОКОНЧЕНА"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color("ef4444"))
	vbox.add_child(title)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 12)
	vbox.add_child(spacer)

	# ← СОХРАНЯЕМ ССЫЛКУ В ПЕРЕМЕННУЮ КЛАССА
	result_label = Label.new()
	result_label.name = "ResultLabel"
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_label.add_theme_font_size_override("font_size", 20)
	result_label.add_theme_color_override("font_color", Color("e2e8f0"))
	vbox.add_child(result_label)

	var hint := Label.new()
	hint.text = "Нажмите ЛКМ или Enter для рестарта"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 14)
	hint.add_theme_color_override("font_color", Color("64748b"))
	vbox.add_child(hint)


func _show_game_over() -> void:
	# ← ИСПОЛЬЗУЕМ СОХРАНЁННУЮ ССЫЛКУ, А НЕ get_node
	result_label.text = "Счёт: %d   |   Рекорд: %d" % [score, high_score]
	game_over_panel.visible = true
	high_label.text = "Рекорд: %d" % high_score


func _hide_game_over() -> void:
	game_over_panel.visible = false


func _start_game() -> void:
	curr_snake.clear()
	var center := Vector2(grid_width / 2, grid_height / 2)
	curr_snake.append(center)
	curr_snake.append(center + Vector2.LEFT)
	curr_snake.append(center + Vector2.LEFT * 2)

	prev_snake = curr_snake.duplicate()
	direction = Vector2.RIGHT
	next_direction = Vector2.RIGHT
	score = 0
	score_label.text = "Счёт: 0"
	score_label.scale = Vector2.ONE
	high_label.text = "Рекорд: %d" % high_score
	game_over = false
	move_timer = 0.0
	_spawn_apple()


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://node_2d.tscn")


func _on_window_resized() -> void:
	_recalculate_layout()
	_center_game_over_panel()


func _recalculate_layout() -> void:
	var win_size := get_viewport().get_visible_rect().size
	var top_panel: float = 90.0
	var margin: float = 32.0

	var avail_w: float = win_size.x - margin * 2
	var avail_h: float = win_size.y - top_panel - margin

	var scale_w: float = avail_w / (grid_width * grid_size)
	var scale_h: float = avail_h / (grid_height * grid_size)
	var final_scale: float = min(scale_w, scale_h)

	if final_scale <= 0:
		final_scale = 1.0

	current_cell_size = grid_size * final_scale

	var field_w: float = grid_width * current_cell_size
	var field_h: float = grid_height * current_cell_size

	field_offset.x = (win_size.x - field_w) / 2
	field_offset.y = top_panel + (avail_h - field_h) / 2


func _center_game_over_panel() -> void:
	var win := get_viewport().get_visible_rect().size
	game_over_panel.position = (win - game_over_panel.custom_minimum_size) / 2


func _grid_to_pixel(grid_pos: Vector2) -> Vector2:
	return field_offset + grid_pos * current_cell_size


func _load_high_score() -> void:
	var file: FileAccess = FileAccess.open("user://snake_high.save", FileAccess.READ)
	if file:
		high_score = file.get_32()
		file.close()


func _save_high_score() -> void:
	var file: FileAccess = FileAccess.open("user://snake_high.save", FileAccess.WRITE)
	if file:
		file.store_32(high_score)
		file.close()
