class_name WaveSpawner
extends Node
## Hace aparecer los enemigos de cada oleada sobre `path`, según su WaveData.

signal wave_started(index: int)
## Ya salieron todos los enemigos de la oleada y no queda ninguno en el mapa.
signal wave_cleared(index: int)
## Se emite justo después de agregar el enemigo al camino.
signal enemy_spawned(enemy: Enemy)

@export var waves: Array[WaveData] = []
@export var path: Path2D
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
		_spawn(_schedule.pop_front().enemy)

	if _schedule.is_empty() and _alive == 0:
		_is_running = false
		wave_cleared.emit(current_wave)


## Arma el cronograma de la oleada `index` y empieza a contar el tiempo.
func start_wave(index: int) -> void:
	current_wave = index
	_schedule = waves[index].build_schedule()
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


## Crea un enemigo con `data` sobre el camino y lo cuenta como vivo.
func _spawn(data: EnemyData) -> void:
	var enemy: Enemy = enemy_scene.instantiate()
	enemy.data = data
	enemy.died.connect(_on_enemy_removed)
	enemy.escaped.connect(_on_enemy_removed)
	path.add_child(enemy)
	_alive += 1
	enemy_spawned.emit(enemy)


## Un enemigo murió o escapó: deja de contarlo.
func _on_enemy_removed(_enemy: Enemy) -> void:
	_alive -= 1
