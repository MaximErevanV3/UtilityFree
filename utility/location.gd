extends Label
# Ссылка на Label
onready var location_label = $LocationLabel

func _ready():
	var url = "http://ip-api.com/json/"
	var http_request = HTTPRequest.new()
	add_child(http_request)

	var error = http_request.request(url)
	if error != OK:
		print("Ошибка запроса: ", error)

	# Обработчик ответа
	http_request.connect("request_completed", self, "_on_request_completed")

func _on_request_completed(result, response_code, headers, body):
	if response_code == 200:
		var json_data = JSON.parse(body)
		if json_data.error == OK:
			var location_info = json_data.result
			var display_text = "Город: %s\nРегион: %s\nСтрана: %s\nШирота: %s\nДолгота: %s" % [
				location_info.city,
				location_info.region,
				location_info.country,
				location_info.lat,
				location_info.lon
			]
			location_label.text = display_text  # Обновляем текст в Label
	else:
		location_label.text = "Ошибка ответа: %d" % response_code  # Обновляем текст в случае ошибки
