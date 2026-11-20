extends Node
## Pruebas de Unit y UnitPlacer. Se corre con:
##   godot --headless --path . res://tests/unit_test.tscn
## Sale con código 0 si todo pasó y 1 si algo falló.

const LEVEL := preload("res://levels/level_01/level_01.tscn")
const ENEMY := preload("res://entities/enemies/enemy.tscn")
const BALANCED := preload("res://data/units/balanceado.tres")
const PALITA := preload("res://data/enemies/salaryman_palita.tres")

## Tiempo máximo de juego (no real) que se espera a que la unidad mate al enemigo.
const FIGHT_TIMEOUT := 60.0
## Un punto libre, lejos del camino y del río.
const FREE_POINT := Vector2(1100, 120)

var _failures := 0
var _level: Node2D
var _placer: UnitPlacer
var _path: Path2D
# Copia de la unidad balanceada que se construye al instante, para las pruebas que no
# tratan de la construcción.
var _instant: UnitData


func _ready() -> void:
	Engine.time_scale = 8.0
	_instant = BALANCED.duplicate()
	_instant.build_time = 0.0

	_level = LEVEL.instantiate()
	_level.start_on_ready = false
	_level.get_node("BGM").autoplay = false
	add_child(_level)
	_placer = _level.get_node("UnitPlacer")
	_path = _level.get_node("EnemyPath")

	# Esperar un frame de física para que las áreas ya estén registradas.
	await get_tree().physics_frame

	_test_placement()
	await _test_building()
	_test_refunds()
	await _test_fight()
	await _test_hits_and_splash()
	await _test_animated_hits()
	_test_icon()
	_test_defeat_blocks_building()

	print("")
	print("Resultado: %d falla(s)" % _failures)
	get_tree().quit(1 if _failures > 0 else 0)


func _test_placement() -> void:
	print("Colocar unidades")
	Economy.reset()
	_check(not _placer.can_place_at(FREE_POINT), "sin selección no se puede colocar")

	_placer.select(_instant)
	_check(_placer.can_place_at(FREE_POINT), "se puede colocar en un lugar libre")
	_check(not _placer.can_place_at(Vector2(640, 660)), "no se puede colocar en el río")

	var unit := _placer.place_at(FREE_POINT)
	_check(unit != null, "place_at devuelve la unidad")
	_check(Economy.earth == Economy.config.starting_earth - _instant.earth_cost, "cobra la tierra")
	_check(Economy.water == Economy.config.starting_water - _instant.water_cost, "cobra el agua")
	_check(not _placer.is_placing(), "colocar deselecciona")

	_placer.select(_instant)
	var too_close := FREE_POINT + Vector2(_instant.spacing - 1.0, 0)
	var far_enough := FREE_POINT + Vector2(_instant.spacing + 1.0, 0)
	_check(not _placer.can_place_at(too_close), "no se puede colocar más cerca que `spacing`")
	_check(_placer.can_place_at(far_enough), "sí se puede apenas más lejos que `spacing`")
	_placer.cancel()
	_clear_units()


func _test_building() -> void:
	print("Construcción")
	Economy.reset()
	var changes: Array[bool] = []
	_placer.building_changed.connect(func(value): changes.append(value))

	_placer.select(BALANCED)
	var unit := _placer.place_at(FREE_POINT)
	_check(not unit.is_built, "arranca en construcción")
	_check(_placer.is_building(), "el colocador sabe que hay una construcción en curso")
	_check(changes == [true], "avisa que empezó la construcción")

	_placer.select(BALANCED)
	_check(not _placer.is_placing(), "mientras se construye no se puede seleccionar otra")

	var time_left := BALANCED.build_time + 2.0
	while not unit.is_built and time_left > 0.0:
		await get_tree().process_frame
		time_left -= get_process_delta_time()
	_check(unit.is_built, "termina de construirse")
	_check(not _placer.is_building(), "y libera el lugar para construir otra")
	_check(changes == [true, false], "avisa que terminó la construcción")
	_clear_units()

	_placer.select(BALANCED)
	_placer.place_at(FREE_POINT).free()
	_check(not _placer.is_building(), "si la destruyen en construcción, también se libera")


func _test_refunds() -> void:
	print("Devoluciones")
	Economy.reset()
	_placer.select(_instant)
	_placer.place_at(FREE_POINT).remove(false)
	var expected := Economy.config.starting_earth - _instant.earth_cost \
			+ floori(_instant.earth_cost * Economy.config.refund_ratio_destroyed)
	_check(Economy.earth == expected, "destruirla devuelve la parte configurada")

	Economy.reset()
	_placer.select(_instant)
	_placer.place_at(FREE_POINT + Vector2(200, 0)).remove(true)
	_check(Economy.earth == Economy.config.starting_earth, "si sobrevive a la oleada devuelve todo")
	_clear_units()


func _test_fight() -> void:
	print("Pelea")
	Economy.reset()
	# La unidad va al costado del camino, a 300 px del inicio.
	var side_of_path := _path.curve.sample_baked(300.0) + Vector2(0, 50)
	_placer.select(_instant)
	var unit := _placer.place_at(side_of_path)

	var enemy: Enemy = ENEMY.instantiate()
	enemy.data = PALITA
	_path.add_child(enemy)
	var deaths: Array[Enemy] = []
	enemy.died.connect(func(e): deaths.append(e))

	var time_left := FIGHT_TIMEOUT
	while deaths.is_empty() and time_left > 0.0 and is_instance_valid(enemy):
		await get_tree().process_frame
		time_left -= get_process_delta_time()
	_check(deaths.size() == 1, "la unidad mata al enemigo que pasa cerca")
	unit.free()


func _test_hits_and_splash() -> void:
	print("Golpes y área")
	Economy.reset()
	var data: UnitData = _instant.duplicate()
	data.hit_frames = []  # Sin animación: todos los golpes al instante.
	data.hit_damages = [1, 3]
	data.splash_radius = 24.0
	var unit := _place_near_path(data, 300.0)

	var close_pair := [_spawn_still_enemy(300.0), _spawn_still_enemy(310.0)]
	var far_enemy := _spawn_still_enemy(300.0 + data.attack_range * 3)
	await _wait_until(func(): return close_pair[0].health < 100)

	_check(close_pair[0].health == 96, "el objetivo recibe los dos golpes (1 + 3)")
	_check(close_pair[1].health == 96, "el enemigo pegado también los recibe (área)")
	_check(far_enemy.health == 100, "el enemigo lejano no recibe nada")
	for node in close_pair + [far_enemy, unit]:
		node.free()


func _test_animated_hits() -> void:
	print("Golpes sincronizados con la animación")
	# Tiempo real: acelerado, los dos cuadros de golpe caerían en el mismo frame
	# y no se vería la vida intermedia entre el jab y el golpe fuerte.
	Engine.time_scale = 1.0
	Economy.reset()
	var unit := _place_near_path(_instant, 300.0)
	var enemy := _spawn_still_enemy(300.0)
	var healths: Array[int] = []
	var total: int = 0
	for damage in _instant.hit_damages:
		total += damage

	var time_left := 5.0
	while enemy.health > 100 - total and time_left > 0.0:
		await get_tree().process_frame
		time_left -= get_process_delta_time()
		if healths.is_empty() or healths.back() != enemy.health:
			healths.append(enemy.health)

	_check(enemy.health == 100 - total, "un ataque completo hace la suma de sus golpes")
	_check(healths.has(100 - _instant.hit_damages[0]), "el primer golpe llega antes que el segundo")
	enemy.free()
	unit.free()
	Engine.time_scale = 8.0


func _test_icon() -> void:
	print("Ícono")
	var first_frame := BALANCED.sprite_frames.get_frame_texture("idle", 0)
	_check(BALANCED.get_icon() == first_frame, "el ícono es el primer cuadro de idle")
	var no_frames := UnitData.new()
	no_frames.texture = BALANCED.texture
	_check(no_frames.get_icon() == BALANCED.texture, "sin animaciones, el ícono es la textura")


# Coloca una unidad de tipo `data` al costado del camino, a `distance` px del inicio.
func _place_near_path(data: UnitData, distance: float) -> Unit:
	_placer.select(data)
	return _placer.place_at(_path.curve.sample_baked(distance) + Vector2(0, 50))


# Un enemigo quieto con 100 de vida, a `distance` px del inicio del camino.
func _spawn_still_enemy(distance: float) -> Enemy:
	var data := EnemyData.new()
	data.speed = 0.0
	data.max_health = 100
	var enemy: Enemy = ENEMY.instantiate()
	enemy.data = data
	enemy.progress = distance
	_path.add_child(enemy)
	return enemy


# Espera frames hasta que `condition` dé true, o hasta 5 segundos de juego.
func _wait_until(condition: Callable) -> void:
	var time_left := 5.0
	while not condition.call() and time_left > 0.0:
		await get_tree().process_frame
		time_left -= get_process_delta_time()


func _test_defeat_blocks_building() -> void:
	print("Derrota")
	Economy.reset()
	Economy.steal(Economy.Kind.EARTH, 9999)
	Economy._process(Economy.config.sudden_death_seconds + 0.1)
	_placer.select(_instant)
	_check(not _placer.can_place_at(FREE_POINT), "después de perder no se puede construir")
	_placer.cancel()


# remove() usa queue_free(): acá se borran en el momento para no ocupar lugar en la prueba siguiente.
func _clear_units() -> void:
	for unit in _level.get_node("Units").get_children():
		unit.free()


func _check(condition: bool, description: String) -> void:
	if condition:
		print("  ok     ", description)
	else:
		_failures += 1
		print("  FALLA  ", description)
