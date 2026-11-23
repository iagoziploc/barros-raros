extends Node
## Pruebas de la ultimate y del máximo extra de Economy. Se corre con:
##   godot --headless --path . res://tests/ultimate_test.tscn
## Sale con código 0 si todo pasó y 1 si algo falló.

const LEVEL := preload("res://levels/level_01/level_01.tscn")
const PALITA := preload("res://data/enemies/salaryman_palita.tres")

var _failures := 0


func _ready() -> void:
	Engine.time_scale = 8.0
	_test_bonus_max()
	await _test_ultimate()
	print("")
	print("Resultado: %d falla(s)" % _failures)
	get_tree().quit(1 if _failures > 0 else 0)


func _test_bonus_max() -> void:
	print("Pasar el máximo")
	Economy.reset()
	Economy.add(30, 0)
	_check(Economy.earth == 100, "sin ultimate no pasa del máximo")
	Economy.bonus_max = 50
	Economy.add(30, 0)
	_check(Economy.earth == 130, "con ultimate pasa del máximo")
	Economy.add(100, 0)
	_check(Economy.earth == 150, "pero no del máximo más el extra")
	Economy.bonus_max = 0
	Economy.add(10, 0)
	_check(Economy.earth == 150, "al terminar, lo que sobró queda pero no sube más")
	Economy.spend(30, 0)
	_check(Economy.earth == 120, "y se puede gastar")
	Economy.spend(30, 0)
	Economy.add(30, 0)
	_check(Economy.earth == 100, "una vez abajo del máximo, vuelve a tener tope")


func _test_ultimate() -> void:
	print("Ultimate")
	Economy.reset()
	var level := LEVEL.instantiate()
	level.start_on_ready = false
	TestUtils.silence(level)
	add_child(level)
	var ultimate: Ultimate = level.get_node("Ultimate")
	var lobito: Lobito = level.get_node("Lobito")

	ultimate.activate()
	_check(not ultimate.is_active(), "sin carga no se puede tirar")

	var enemy: Enemy = load("res://entities/enemies/enemy.tscn").instantiate()
	enemy.data = PALITA
	var spawner: WaveSpawner = level.get_node("WaveSpawner")
	spawner.entrances[0].add_child(enemy)
	spawner.enemy_spawned.emit(enemy)
	enemy.take_damage(1000)
	_check(ultimate.charge == PALITA.ultimate_charge, "cada enemigo muerto suma su carga")

	ultimate.add_charge(1000)
	_check(ultimate.charge == ultimate.charge_needed and ultimate.is_ready(), "la carga tiene tope y queda lista")
	var lobitos_before := _count_lobitos(level)
	ultimate.activate()
	_check(ultimate.is_active() and ultimate.charge == 0, "se tira y se vacía la carga")
	_check(_count_lobitos(level) == lobitos_before + ultimate.extra_lobitos, "aparecen los lobitos ayudantes")
	_check(Economy.bonus_max == ultimate.resource_bonus, "se puede pasar el máximo")
	_check(is_equal_approx(lobito._timer.wait_time, lobito.interval / ultimate.sparkle_rate),
			"los brillos aparecen más rápido")
	ultimate.activate()
	_check(_count_lobitos(level) == lobitos_before + ultimate.extra_lobitos, "no se puede tirar dos veces a la vez")

	var time_left := ultimate.duration + 30.0
	while ultimate.is_active() and time_left > 0.0:
		await get_tree().process_frame
		time_left -= get_process_delta_time()
	_check(not ultimate.is_active(), "termina después de su duración")
	_check(Economy.bonus_max == 0, "y el máximo vuelve a la normalidad")
	_check(is_equal_approx(lobito._timer.wait_time, lobito.interval), "y los brillos también")
	time_left = 30.0
	while _count_lobitos(level) > lobitos_before and time_left > 0.0:
		await get_tree().process_frame
		time_left -= get_process_delta_time()
	_check(_count_lobitos(level) == lobitos_before, "los ayudantes terminan su viaje y se van")

	ultimate.add_charge(1000)
	ultimate.activate()
	ultimate.reset()
	_check(not ultimate.is_active() and ultimate.charge == 0, "al terminar la oleada se corta y la carga vuelve a 0")
	_check(Economy.bonus_max == 0, "y el máximo vuelve a la normalidad")
	level.queue_free()


func _count_lobitos(level: Node) -> int:
	var count := 0
	for child in level.get_children():
		if child is Lobito and not child.is_queued_for_deletion():
			count += 1
	return count


func _check(condition: bool, description: String) -> void:
	if condition:
		print("  ok     ", description)
	else:
		_failures += 1
		print("  FALLA  ", description)
