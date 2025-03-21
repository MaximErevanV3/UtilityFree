extends Node

# Переменные для хранения IP-адреса и пинга
var ip_address: String = ""
var ping: int = 0

# Ссылки на Label для отображения информации
onready var ip_label = $IP
onready var ping_label = $PingLabel

func _ready():
	# Получаем и отображаем IP-адрес
	ip_address = OS.get_local_host().get_ip()
	ip_label.text = "Ваш IP-адрес: " + ip_address
	# Пинг до удаленного сервера
	ping_to_server("8.8.8.8")

func ping_to_server(server: String):
	var dns = DNS.new()
	dns.connect("resolved", self, "_on_dns_resolved")
	dns.query(server)

func _on_dns_resolved(result):
	if result.is_ok():
		ping = result.get_time()
		ping_label.text = "Пинг до сервера: " + str(ping) + " мс"
	else:
		ping_label.text = "Не удалось получить пинг."
