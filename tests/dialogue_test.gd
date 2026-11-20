extends Node
## Pruebas de DialogueBox y del flujo de partida del nivel. Se corre con:
##   godot --headless --path . res://tests/dialogue_test.tscn
## Sale con código 0 si todo pasó y 1 si algo falló.

const DIALOGUE_BOX := preload("res://ui/dialogue_box/dialogue_box.tscn")
const LEVEL := preload("res://levels/level_01/level_01.tscn")
const PALITA := preload("res://data/enemies/salaryman_palita.tres")

## Tiempo máximo de juego (no real) que se espera a que termine la oleada de prueba.
const WAVE_TIMEOUT := 120.0

var _failures := 0


func _ready() -> void:
	Engine.time_scale = 8.0
	await _test_dialogue_box()
	await _test_level_flow()

	print("")
	print("Resultado: %d falla(s)" % _failures)
	get_tree().quit(1 if _failures > 0 else 0)


func _test_dialogue_box() -> void:
	print("Caja de diálogo")
	var box: DialogueBox = DIALOGUE_BOX.instantiate()
	add_child(box)
	var finished := [false]
	box.finished.connect(func(): finished[0] = true)

	box.play(_make_dialogue(2))  # Sin await: la prueba sigue mientras el diálogo corre.
	var text: RichTextLabel = box.get_node("%BoxText")
	_check(box.is_playing(), "arranca el diálogo")
	_check(get_tree().paused, "pausa el juego")
	_check(text.visible_characters == 0, "el texto arranca oculto")

	await get_tree().process_frame
	await get_tree().process_frame
	_check(text.visible_characters > 0, "el texto aparece letra por letra")

	box.advance()
	_check(text.visible_characters == -1, "el primer avance completa la línea")
	box.advance()
	_check(text.visible_characters == 0, "el segundo pasa a la línea siguiente")

	box.advance()
	box.advance()
	_check(finished[0], "al pasar la última línea emite finished")
	_check(not get_tree().paused, "y despausa el juego")
	box.queue_free()


func _test_level_flow() -> void:
	print("Flujo de partida")
	var level := LEVEL.instantiate()
	TestUtils.silence(level)
	level.intro = _make_dialogue(1)
	# Los arrays tipados se crean con su tipo: un [] común no se convierte solo
	# al asignarlo a través de una variable sin tipo como `level`.
	var wave_dialogues: Array[Dialogue] = [_make_dialogue(1)]
	level.wave_dialogues = wave_dialogues
	level.ending = _make_dialogue(1)
	var spawner: WaveSpawner = level.get_node("WaveSpawner")
	spawner.waves = [_make_wave()]
	add_child(level)

	var box: DialogueBox = level.get_node("DialogueBox")
	await get_tree().process_frame

	_check(box.is_playing() and get_tree().paused, "arranca con la intro y el juego pausado")
	_check(not spawner.is_running(), "la oleada todavía no arrancó")

	await _skip_dialogue(box)  # Intro.
	await _skip_dialogue(box)  # Diálogo de la oleada 1.
	_check(spawner.is_running(), "después de los diálogos arranca la oleada")
	_check(not get_tree().paused, "y el juego ya no está pausado")

	var time_left := WAVE_TIMEOUT
	while spawner.is_running() and time_left > 0.0:
		await get_tree().process_frame
		time_left -= get_process_delta_time()
	await get_tree().process_frame
	_check(box.is_playing(), "al terminar la oleada aparece el final")

	await _skip_dialogue(box)  # Final.
	var message: Label = level.get_node("HUD").get_node("%MessageLabel")
	_check(message.visible and message.text == tr("HUD_VICTORY"), "después del final, la victoria")
	level.queue_free()


# Avanza el diálogo actual hasta que termine.
func _skip_dialogue(box: DialogueBox) -> void:
	while box.is_playing():
		box.advance()
		await get_tree().process_frame
	await get_tree().process_frame


# Diálogo de `count` líneas con textos que existen en el CSV.
func _make_dialogue(count: int) -> Dialogue:
	var dialogue := Dialogue.new()
	for i in count:
		var line := DialogueLine.new()
		line.speaker = Speaker.new()
		line.text_key = "INTRO_01"
		dialogue.lines.append(line)
	return dialogue


# Oleada de un solo enemigo.
func _make_wave() -> WaveData:
	var entry := WaveEntry.new()
	entry.enemy = PALITA
	entry.count = 1
	var wave := WaveData.new()
	wave.entries = [entry]
	return wave


func _check(condition: bool, description: String) -> void:
	if condition:
		print("  ok     ", description)
	else:
		_failures += 1
		print("  FALLA  ", description)
