extends Node
## Pruebas de WaveData y WaveSpawner. Se corre con:
##   godot --headless --path . res://tests/wave_test.tscn
## Sale con código 0 si todo pasó y 1 si algo falló.

const LEVEL := preload("res://levels/level_01/level_01.tscn")
const PALITA := preload("res://data/enemies/salaryman_palita.tres")
const BOTELLITA := preload("res://data/enemies/salaryman_botellita.tres")
const WAVE_01 := preload("res://data/waves/wave_01.tres")

## Tiempo máximo de juego (no real) que se espera a que termine la oleada.
const WAVE_TIMEOUT := 300.0

var _failures := 0


func _ready() -> void:
	Engine.time_scale = 8.0

	_test_schedule()
	_test_wave_01_data()
	await _test_spawner()

	print("")
	print("Resultado: %d falla(s)" % _failures)
	get_tree().quit(1 if _failures > 0 else 0)


func _test_schedule() -> void:
	print("Orden de aparición")
	var wave := _make_wave()
	var schedule := wave.build_schedule()
	var times: Array = schedule.map(func(item): return item.time)
	_check(times == [0.0, 0.5, 1.0, 1.5], "los grupos se intercalan por tiempo")
	_check(schedule[1].enemy == BOTELLITA, "el segundo en salir es el de la botellita")
	_check(wave.total_enemies() == 4, "total_enemies suma todos los grupos")


func _test_wave_01_data() -> void:
	print("Datos de la oleada 1")
	_check(WAVE_01.total_enemies() == 20, "la oleada 1 tiene 20 enemigos")


func _test_spawner() -> void:
	print("WaveSpawner")
	Economy.reset()
	var level := LEVEL.instantiate()
	var spawner: WaveSpawner = level.get_node("WaveSpawner")
	spawner.autostart = false
	spawner.waves = [_make_wave()]
	# Sin música: si suena al cerrar, Godot avisa que la reproducción quedó sin liberar.
	level.get_node("BGM").autoplay = false
	add_child(level)

	var spawned: Array[Enemy] = []
	var cleared: Array[int] = []
	spawner.enemy_spawned.connect(func(e): spawned.append(e))
	spawner.wave_cleared.connect(func(i): cleared.append(i))

	spawner.start_wave(0)
	_check(spawner.is_running(), "la oleada arranca")

	var time_left := WAVE_TIMEOUT
	while cleared.is_empty() and time_left > 0.0:
		await get_tree().process_frame
		time_left -= get_process_delta_time()

	_check(spawned.size() == 4, "aparecen los 4 enemigos")
	_check(cleared == [0], "avisa que la oleada 0 terminó")
	_check(not spawner.is_running(), "deja de correr")
	_check(not spawner.has_more_waves(), "no hay más oleadas")
	level.queue_free()


# Oleada chica: 2 de la palita y 2 de la botellita, intercalados cada 0,5 s.
func _make_wave() -> WaveData:
	var palitas := WaveEntry.new()
	palitas.enemy = PALITA
	palitas.count = 2
	palitas.interval = 1.0
	palitas.start_time = 0.0

	var botellitas := WaveEntry.new()
	botellitas.enemy = BOTELLITA
	botellitas.count = 2
	botellitas.interval = 1.0
	botellitas.start_time = 0.5

	var wave := WaveData.new()
	wave.entries = [palitas, botellitas]
	return wave


func _check(condition: bool, description: String) -> void:
	if condition:
		print("  ok     ", description)
	else:
		_failures += 1
		print("  FALLA  ", description)
