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
	add_child(level)
	_path = level.get_node("EnemyPath")
	# Saca los enemigos de prueba que trae el nivel, para controlar cuáles hay.
	for child in _path.get_children():
		if child is Enemy:
			child.free()

	await _test_route_and_steal()
	_test_damage_and_armor()

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
