extends Node
## Pruebas del enemigo sobre level_01. Se corre con:
##   godot --headless --path . res://tests/enemy_test.tscn
## Sale con código 0 si todo pasó y 1 si algo falló.

const LEVEL := preload("res://levels/level_01/level_01.tscn")
const ENEMY := preload("res://entities/enemies/enemy.tscn")
const PALITA := preload("res://data/enemies/salaryman_palita.tres")
const BOTELLITA := preload("res://data/enemies/salaryman_botellita.tres")

## Tiempo máximo de juego (no real) que se espera a que los enemigos lleguen al río.
const ROUTE_TIMEOUT := 120.0

var _failures := 0
var _path: Path2D


func _ready() -> void:
	# Acelera el juego para no esperar el recorrido en tiempo real.
	Engine.time_scale = 8.0

	var level := LEVEL.instantiate()
	# Sin oleadas: la prueba decide qué enemigos aparecen.
	level.start_on_ready = false
	TestUtils.silence(level)
	TestUtils.remove_lobito(level)
	add_child(level)
	_path = level.get_node("Routes/TopLeftDig")

	await _test_route_and_steal()
	await _test_stops_to_steal_earth()
	_test_damage_and_armor()
	_test_speed_variation()
	_test_death_sound()

	print("")
	print("Resultado: %d falla(s)" % _failures)
	get_tree().quit(1 if _failures > 0 else 0)


func _test_route_and_steal() -> void:
	print("Recorrer el camino y robar")
	Economy.reset()
	var escaped: Array[Enemy] = []
	for data in [PALITA, BOTELLITA]:
		var enemy := _spawn(data)
		enemy.escaped.connect(func(e): escaped.append(e))

	var time_left := ROUTE_TIMEOUT
	while escaped.size() < 2 and time_left > 0.0:
		await get_tree().process_frame
		time_left -= get_process_delta_time()

	_check(escaped.size() == 2, "los dos llegan al río")
	_check(Economy.earth == Economy.config.starting_earth - PALITA.earth_stolen,
			"el de la palita roba tierra en la zona húmeda")
	_check(Economy.water == Economy.config.starting_water - BOTELLITA.water_stolen,
			"el de la botellita roba agua en el río")


func _test_stops_to_steal_earth() -> void:
	print("Pausa para robar tierra")
	Economy.reset()
	var enemy := _spawn(PALITA)

	var time_left := ROUTE_TIMEOUT
	while not enemy.is_stealing() and time_left > 0.0:
		await get_tree().process_frame
		time_left -= get_process_delta_time()
	_check(enemy.is_stealing(), "se detiene en la zona húmeda")

	var progress_before := enemy.progress
	await get_tree().process_frame
	_check(enemy.progress == progress_before, "mientras roba no avanza")
	_check(Economy.earth == Economy.config.starting_earth, "todavía no robó")

	enemy.take_damage(1000)
	await get_tree().create_timer(PALITA.earth_steal_duration + 0.5).timeout
	_check(Economy.earth == Economy.config.starting_earth, "si muere robando, no se lleva nada")


func _test_speed_variation() -> void:
	print("Variación de velocidad")
	var data := EnemyData.new()
	data.speed = 100.0
	data.speed_variation = 0.2
	var speeds := []
	for i in 20:
		var enemy := _spawn(data)
		speeds.append(enemy._speed)
		enemy.free()
	_check(speeds.all(func(s): return s >= 80.0 and s <= 120.0), "todas quedan entre 80% y 120%")
	_check(speeds.min() != speeds.max(), "no son todas iguales")

	data.speed_variation = 0.0
	var steady := _spawn(data)
	_check(steady._speed == 100.0, "con variación 0, la velocidad es exacta")
	steady.free()


func _test_death_sound() -> void:
	print("Sonido al morir")
	var enemy := _spawn(PALITA)
	var scene := get_tree().current_scene
	var before := scene.get_child_count()
	enemy.take_damage(1000)
	var player := scene.get_child(scene.get_child_count() - 1) as AudioStreamPlayer2D
	_check(scene.get_child_count() == before + 1 and player != null, "al morir deja un reproductor aparte")
	_check(player != null and player.stream == PALITA.death_sound, "con el grito del enemigo")
	_check(PALITA.death_sound is AudioStreamRandomizer, "que elige uno al azar entre varios")


func _test_damage_and_armor() -> void:
	print("Daño y armadura")
	var armored := EnemyData.new()
	armored.max_health = 10
	armored.armor = 3
	var enemy := _spawn(armored)

	enemy.take_damage(5)
	_check(enemy.health == 8, "la armadura resta daño (5 - 3 = 2)")
	enemy.take_damage(1)
	_check(enemy.health == 7, "cada golpe hace al menos 1")

	var deaths: Array[Enemy] = []
	enemy.died.connect(func(e): deaths.append(e))
	enemy.take_damage(100)
	_check(deaths == [enemy], "al quedarse sin vida emite died")
	enemy.take_damage(100)
	_check(deaths.size() == 1, "died se emite una sola vez")


func _spawn(data: EnemyData) -> Enemy:
	var enemy: Enemy = ENEMY.instantiate()
	enemy.data = data  # Antes de add_child, porque _ready() lo usa.
	_path.add_child(enemy)
	return enemy


func _check(condition: bool, description: String) -> void:
	if condition:
		print("  ok     ", description)
	else:
		_failures += 1
		print("  FALLA  ", description)
