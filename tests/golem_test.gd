extends Node
## Pruebas de Golem y GolemPlacer. Se corre con:
##   godot --headless --path . res://tests/golem_test.tscn
## Sale con código 0 si todo pasó y 1 si algo falló.

const LEVEL := preload("res://levels/level_01/level_01.tscn")
const ENEMY := preload("res://entities/enemies/enemy.tscn")
const BALANCED := preload("res://data/golems/golem_balanceado.tres")
const PALITA := preload("res://data/enemies/salaryman_palita.tres")

## Tiempo máximo de juego (no real) que se espera a que el golem mate al enemigo.
const FIGHT_TIMEOUT := 60.0
## Un punto libre, lejos del camino y del río.
const FREE_POINT := Vector2(1100, 120)

var _failures := 0
var _level: Node2D
var _placer: GolemPlacer
var _path: Path2D


func _ready() -> void:
	Engine.time_scale = 8.0
	_level = LEVEL.instantiate()
	_level.start_on_ready = false
	_level.get_node("BGM").autoplay = false
	add_child(_level)
	_placer = _level.get_node("GolemPlacer")
	_path = _level.get_node("EnemyPath")

	# Esperar un frame de física para que las áreas ya estén registradas.
	await get_tree().physics_frame

	_test_placement()
	_test_refunds()
	await _test_fight()
	_test_defeat_blocks_building()

	print("")
	print("Resultado: %d falla(s)" % _failures)
	get_tree().quit(1 if _failures > 0 else 0)


func _test_placement() -> void:
	print("Colocar golems")
	Economy.reset()
	_check(not _placer.can_place_at(FREE_POINT), "sin selección no se puede colocar")

	_placer.select(BALANCED)
	_check(_placer.can_place_at(FREE_POINT), "se puede colocar en un lugar libre")
	_check(not _placer.can_place_at(Vector2(640, 660)), "no se puede colocar en el río")

	var golem := _placer.place_at(FREE_POINT)
	_check(golem != null, "place_at devuelve el golem")
	_check(Economy.earth == Economy.config.starting_earth - BALANCED.earth_cost, "cobra la tierra")
	_check(Economy.water == Economy.config.starting_water - BALANCED.water_cost, "cobra el agua")
	_check(_placer.place_at(FREE_POINT + Vector2(10, 0)) == null, "no se puede colocar pegado a otro")

	golem.free()
	_placer.cancel()


func _test_refunds() -> void:
	print("Devoluciones")
	Economy.reset()
	_placer.select(BALANCED)
	_placer.place_at(FREE_POINT).remove(false)
	var expected := Economy.config.starting_earth - BALANCED.earth_cost \
			+ floori(BALANCED.earth_cost * Economy.config.refund_ratio_destroyed)
	_check(Economy.earth == expected, "destruirlo devuelve la parte configurada")

	Economy.reset()
	_placer.place_at(FREE_POINT + Vector2(200, 0)).remove(true)
	_check(Economy.earth == Economy.config.starting_earth, "si sobrevive a la oleada devuelve todo")
	_placer.cancel()
	# remove() usa queue_free(): se borran a mano para que no ocupen lugar en la próxima prueba.
	for golem in _level.get_node("Golems").get_children():
		golem.free()


func _test_fight() -> void:
	print("Pelea")
	Economy.reset()
	# El golem va al costado del camino, a 300 px del inicio.
	var side_of_path := _path.curve.sample_baked(300.0) + Vector2(0, 50)
	_placer.select(BALANCED)
	var golem := _placer.place_at(side_of_path)
	_placer.cancel()

	var enemy: Enemy = ENEMY.instantiate()
	enemy.data = PALITA
	_path.add_child(enemy)
	var deaths: Array[Enemy] = []
	enemy.died.connect(func(e): deaths.append(e))

	var time_left := FIGHT_TIMEOUT
	while deaths.is_empty() and time_left > 0.0 and is_instance_valid(enemy):
		await get_tree().process_frame
		time_left -= get_process_delta_time()
	_check(deaths.size() == 1, "el golem mata al enemigo que pasa cerca")
	golem.free()


func _test_defeat_blocks_building() -> void:
	print("Derrota")
	Economy.reset()
	Economy.steal(Economy.Kind.EARTH, 9999)
	Economy._process(Economy.config.sudden_death_seconds + 0.1)
	_placer.select(BALANCED)
	_check(not _placer.can_place_at(FREE_POINT), "después de perder no se puede construir")
	_placer.cancel()


func _check(condition: bool, description: String) -> void:
	if condition:
		print("  ok     ", description)
	else:
		_failures += 1
		print("  FALLA  ", description)
