extends Node2D
## Conecta las piezas del nivel y guía la partida de principio a fin:
## intro -> (diálogo de la oleada -> oleada) x N -> final.
## La secuencia completa está en _run(), escrita en orden con await.

## Segundos entre una oleada y la siguiente cuando no hay diálogo en el medio.
@export var time_between_waves := 5.0
## Si es false, el nivel no arranca solo (lo usan las pruebas).
@export var start_on_ready := true

@export_group("Narrativa")
## Cinemática del comienzo. Puede quedar vacía.
@export var intro: Dialogue
## Diálogo que se muestra antes de cada oleada, en el mismo orden que las oleadas.
## Un elemento vacío = esa oleada arranca sin diálogo.
@export var wave_dialogues: Array[Dialogue] = []
## Cinemática del final, después de la última oleada. Puede quedar vacía.
@export var ending: Dialogue

# Rutas de los diálogos ya mostrados. `static`: pertenece al script y no a la escena,
# así que sobrevive a reload_current_scene() (no se borra al reiniciar con R).
static var _seen_dialogues: Array[String] = []

@onready var _spawner: WaveSpawner = $WaveSpawner
@onready var _units: Node2D = $Units
@onready var _placer: UnitPlacer = $UnitPlacer
@onready var _hud := $HUD
@onready var _build_bar := $BuildBar
@onready var _dialogue_box: DialogueBox = $DialogueBox


## Reinicia la economía, conecta las piezas y arranca la partida.
func _ready() -> void:
	Economy.reset()
	_spawner.wave_started.connect(_on_wave_started)
	_build_bar.unit_selected.connect(_placer.select)
	if start_on_ready:
		_run()


## La partida completa, en orden. Cada await espera a que termine ese momento.
func _run() -> void:
	await _play_once(intro)

	for index in _spawner.waves.size():
		if index < wave_dialogues.size():
			await _play_once(wave_dialogues[index])
		elif index > 0:
			await get_tree().create_timer(time_between_waves).timeout

		_spawner.start_wave(index)
		await _spawner.wave_cleared
		if Economy.is_defeated():
			return  # El HUD ya muestra la derrota.
		_dissolve_units()

	await _play_once(ending)
	_hud.show_victory()


## Muestra `dialogue` y espera a que termine, salvo que ya se haya visto en esta sesión.
## Los diálogos creados por código (sin archivo) se muestran siempre.
func _play_once(dialogue: Dialogue) -> void:
	if dialogue == null:
		return
	var path := dialogue.resource_path
	if path != "":
		if path in _seen_dialogues:
			return
		_seen_dialogues.append(path)
	await _dialogue_box.play(dialogue)


## Actualiza el número de oleada en el HUD.
func _on_wave_started(index: int) -> void:
	_hud.set_wave(index + 1)


## Disuelve las unidades que llegaron al final de la oleada (devuelven todo su costo).
func _dissolve_units() -> void:
	for unit: Unit in _units.get_children():
		unit.remove(true)


## Tecla R: reinicia el nivel. Los diálogos ya vistos no se repiten.
func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	if key.keycode == KEY_R:
		get_tree().reload_current_scene()
