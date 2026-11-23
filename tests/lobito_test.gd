extends Node
## Pruebas del lobito. Se corre con:
##   godot --headless --path . res://tests/lobito_test.tscn
## Sale con código 0 si todo pasó y 1 si algo falló.

const LOBITO := preload("res://entities/lobito/lobito.tscn")

var _failures := 0


func _ready() -> void:
	Engine.time_scale = 8.0
	await _test_fetch()
	print("")
	print("Resultado: %d falla(s)" % _failures)
	get_tree().quit(1 if _failures > 0 else 0)


func _test_fetch() -> void:
	print("Ir a buscar el recurso más bajo")
	Economy.reset()
	Economy.spend(0, 30)  # El agua queda más baja: tiene que traer agua.
	var home := Node2D.new()
	home.position = Vector2(500, 300)
	add_child(home)
	var lobito: Node2D = LOBITO.instantiate()
	lobito.home = home
	lobito.interval = 0.5
	lobito.water_area = Rect2(500, 500, 1, 1)  # El brillo aparece a 200 px de casa.
	add_child(lobito)
	_check(lobito.global_position == home.global_position, "empieza en casa")

	var farthest := 0.0
	var time_left := 10.0
	while Economy.water == 70 and time_left > 0.0:
		await get_tree().process_frame
		time_left -= get_process_delta_time()
		farthest = maxf(farthest, lobito.global_position.distance_to(home.global_position))
	_check(farthest > 190.0, "sale de casa hasta el brillo")
	_check(Economy.water == 70 + lobito.amount, "vuelve y entrega agua (la más baja)")
	_check(lobito.global_position.distance_to(home.global_position) < 1.0, "entrega en casa")
	_check(Economy.earth == 100, "no toca la tierra")
	var elapsed := 10.0 - time_left
	_check(elapsed > lobito.interval + 1.5, "tarda el intervalo más el viaje, no solo el intervalo")
	lobito.queue_free()
	home.queue_free()


func _check(condition: bool, description: String) -> void:
	if condition:
		print("  ok     ", description)
	else:
		_failures += 1
		print("  FALLA  ", description)
