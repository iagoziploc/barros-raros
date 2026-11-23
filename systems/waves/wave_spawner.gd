class_name WaveSpawner
extends Node
## Hace aparecer los enemigos de cada oleada según su WaveData. Cada enemigo sale por una
## de las entradas que permite su grupo, sorteada; si roba tierra, va por la ruta con pozo.

signal wave_started(index: int)
## Ya salieron todos los enemigos de la oleada y no queda ninguno en el mapa.
signal wave_cleared(index: int)
## Se emite justo después de agregar el enemigo al camino.
signal enemy_spawned(enemy: Enemy)

@export var waves: Array[WaveData] = []
## Ruta de cada entrada, en el orden de las casillas de WaveEntry.entrances:
## arriba izquierda, arriba derecha, izquierda.
@export var entrances: Array[Route] = []
@export var enemy_scene: PackedScene = preload("res://entities/enemies/enemy.tscn")
## Arranca la primera oleada al cargar. Pensado para probar mientras no hay flujo de partida.
@export var autostart := false

var current_wave := -1

var _schedule: Array[Dictionary] = []
var _elapsed := 0.0
var _alive := 0
var _is_running := false


## Arranca la primera oleada si `autostart` está activo.
func _ready() -> void:
	if autostart and not waves.is_empty():
		start_wave(0)


## Saca los enemigos cuyo tiempo ya llegó y avisa `wave_cleared` cuando no queda nadie.
func _process(delta: float) -> void:
	if not _is_running:
		return

	_elapsed += delta
	# while y no if: si en un frame se cumplieron varios tiempos, salen todos.
	while not _schedule.is_empty() and _schedule[0].time <= _elapsed:
		var spawn: Dictionary = _schedule.pop_front()
		_spawn(spawn.enemy, spawn.entrances)

	if _schedule.is_empty() and _alive == 0:
		_is_running = false
		wave_cleared.emit(current_wave)


## Arma el cronograma de la oleada `index` y empieza a contar el tiempo.
func start_wave(index: int) -> void:
	current_wave = index
	_schedule = waves[index].build_schedule(Modifiers.multiplier(Modifiers.Stat.ENEMY_COUNT))
	_elapsed = 0.0
	_alive = 0
	_is_running = true
	wave_started.emit(index)


## true desde start_wave() hasta que se emite wave_cleared.
func is_running() -> bool:
	return _is_running


## true si después de la oleada actual queda otra en `waves`.
func has_more_waves() -> bool:
	return current_wave + 1 < waves.size()


## Crea un enemigo con `data` en una de las entradas de `allowed_entrances` y lo cuenta como vivo.
func _spawn(data: EnemyData, allowed_entrances: int) -> void:
	var enemy: Enemy = enemy_scene.instantiate()
	enemy.data = data
	enemy.died.connect(_on_enemy_removed)
	enemy.escaped.connect(_on_enemy_removed)
	_pick_route(data, allowed_entrances).add_child(enemy)
	_alive += 1
	enemy_spawned.emit(enemy)


## Sortea la ruta de un enemigo entre las entradas tildadas en `allowed_entrances`
## (un número donde cada bit es una casilla). Los que roban tierra usan la variante con pozo
## y descartan las entradas que no tienen. Si no queda ninguna, sortea entre todas.
func _pick_route(data: EnemyData, allowed_entrances: int) -> Route:
	var options: Array[Route] = []
	var fallback: Array[Route] = []
	for index in entrances.size():
		var route := entrances[index]
		if data.earth_stolen > 0:
			route = route.dig_route
		if route == null:
			continue
		fallback.append(route)
		# 1 << index es el bit de la casilla número index: 1, 2, 4...
		if allowed_entrances & (1 << index):
			options.append(route)
	if options.is_empty():
		options = fallback
	return options.pick_random()


## Un enemigo murió o escapó: deja de contarlo.
func _on_enemy_removed(_enemy: Enemy) -> void:
	_alive -= 1
