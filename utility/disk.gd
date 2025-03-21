extends Label

var update_interval: float = 1.0  # Интервал обновления в секундах
var timer: float = 0.0

func _ready() -> void:
	text = "Загрузка информации о GPU..."

func _process(delta: float) -> void:
	timer += delta

	if timer >= update_interval:
		timer = 0.0
		update_gpu_info()

func update_gpu_info() -> void:
	var renderer_name = RenderingServer.get_render_info("renderer_name")
	var gpu_info: String = "GPU: %s\n" % renderer_name
	
	# Обновляем текст на Label
	text = gpu_info
