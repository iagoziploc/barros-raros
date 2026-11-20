extends Node2D
## Conecta las piezas del nivel y guía la partida de principio a fin:
## intro -> (diálogo de la oleada -> oleada -> noticia) x N -> final.
## La secuencia completa está en _run(), escrita en orden con await.

## Segundos entre una oleada y la siguiente cuando no hay ni noticia ni diálogo en el medio.
@export var time_between_waves := 5.0
## Si es false, el nivel no arranca solo (lo usan las pruebas).
@export var start_on_ready := true

@export_group("Narrativa")
## Cinemática del comienzo. Puede quedar vacía.
@export var intro: Dialogue
## Diálogo que se muestra antes de cada oleada, en el mismo orden que las oleadas.
## Un elemento vacío = esa oleada arranca sin diálogo.
@export var wave_dialogues: Array[Dialogue] = []
## Noticia que llega después de cada oleada (la 0 después de la oleada 1, y así).
## Después de la última oleada no hay noticia. Un elemento vacío = sin noticia.
@export var wave_news: Array[NewsEvent] = []
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
@onready var _news_choice: NewsChoice = $NewsChoice


## Reinicia la economía y los modificadores, conecta las piezas y arranca la partida.
func _ready() -> void:
	Economy.reset()
	Modifiers.reset()
	_spawner.wave_started.connect(_on_wave_started)
	_build_bar.unit_selected.connect(_placer.select)
	_placer.building_changed.connect(_build_bar.set_building)
	if start_on_ready:
		_run()


## La partida completa, en orden. Cada await espera a que termine ese momento.
func _run() -> void:
	await _play_once(intro)

	var last_wave := _spawner.waves.size() - 1
	for index in _spawner.waves.size():
		var dialogue: Dialogue = wave_dialogues[index] if index < wave_dialogues.size() else null
		await _play_once(dialogue)

		_spawner.start_wave(index)
		await _spawner.wave_cleared
		if Economy.is_defeated():
			return  # El HUD ya muestra la derrota.
		_dissolve_units()

		if index == last_wave:
			break
		# Entre oleadas: la noticia, o si no hay ni noticia ni diálogo siguiente, una pausa.
		var news: NewsEvent = wave_news[index] if index < wave_news.size() else null
		var has_next_dialogue := index + 1 < wave_dialogues.size() and wave_dialogues[index + 1] != null
		if news:
			await _run_news(news)
		elif not has_next_dialogue:
			await get_tree().create_timer(time_between_waves).timeout

	await _play_once(ending)
	_hud.show_victory()


## Muestra la noticia (si no se vio antes), espera la elección del jugador y la aplica.
func _run_news(news: NewsEvent) -> void:
	await _play_once(news.dialogue)
	if news.options.is_empty():
		return
	var option: NewsOption = await _news_choice.choose(news)
	option.apply()


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
