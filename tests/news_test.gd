extends Node
## Pruebas de Modifiers, NewsChoice y la noticia entre oleadas. Se corre con:
##   godot --headless --path . res://tests/news_test.tscn
## Sale con código 0 si todo pasó y 1 si algo falló.

const LEVEL := preload("res://levels/level_01/level_01.tscn")
const ENEMY := preload("res://entities/enemies/enemy.tscn")
const NEWS_CHOICE := preload("res://ui/news_choice/news_choice.tscn")
const BALANCED := preload("res://data/units/balanceado.tres")
const PALITA := preload("res://data/enemies/salaryman_palita.tres")

## Tiempo máximo de juego (no real) que se espera a que pase algo.
const TIMEOUT := 120.0

var _failures := 0


func _ready() -> void:
	Engine.time_scale = 8.0
	_test_modifiers()
	_test_modifiers_in_game_objects()
	await _test_news_choice()
	await _test_news_between_waves()

	print("")
	print("Resultado: %d falla(s)" % _failures)
	get_tree().quit(1 if _failures > 0 else 0)


func _test_modifiers() -> void:
	print("Modifiers")
	Economy.reset()
	Modifiers.reset()
	var stat := Modifiers.Stat
	_check(Modifiers.multiplier(stat.UNIT_DAMAGE) == 1.0, "sin efectos, el multiplicador es 1")

	Modifiers.apply(stat.UNIT_WATER_COST, 0.2)
	Modifiers.apply(stat.UNIT_WATER_COST, -0.1)
	_check(is_equal_approx(Modifiers.multiplier(stat.UNIT_WATER_COST), 1.1), "los porcentajes se suman")
	_check(Modifiers.water_cost(BALANCED) == roundi(BALANCED.water_cost * 1.1), "el costo de agua usa el multiplicador")

	Modifiers.apply(stat.ENEMY_SPEED, -5.0)
	_check(Modifiers.multiplier(stat.ENEMY_SPEED) == 0.1, "el multiplicador nunca baja de 0.1")

	var water := Economy.water
	Modifiers.apply(stat.WATER_NOW, -15.0)
	_check(Economy.water == water - 15, "los instantáneos cambian la economía en el momento")

	_check(Modifiers.describe(stat.UNIT_DAMAGE, 0.25).contains("+25%"), "describe muestra el porcentaje")
	_check(Modifiers.describe(stat.UNIT_ARMOR_PIERCING, 2.0).contains("+2"), "describe muestra las cantidades fijas")
	_check(Modifiers.is_good(stat.UNIT_DAMAGE, 0.25), "más daño es bueno")
	_check(not Modifiers.is_good(stat.UNIT_EARTH_COST, 0.2), "más costo es malo")
	_check(Modifiers.is_good(stat.ENEMY_COUNT, -0.2), "menos enemigos es bueno")

	Modifiers.reset()
	_check(Modifiers.get_value(stat.UNIT_WATER_COST) == 0.0, "reset borra todo")


func _test_modifiers_in_game_objects() -> void:
	print("Modificadores aplicados")
	Modifiers.reset()
	var data := EnemyData.new()
	data.speed = 100.0
	data.speed_variation = 0.0
	data.max_health = 100
	data.armor = 3

	Modifiers.apply(Modifiers.Stat.ENEMY_SPEED, 0.5)
	var enemy: Enemy = ENEMY.instantiate()
	enemy.data = data
	add_child(enemy)
	_check(enemy._speed == 150.0, "la velocidad de los enemigos usa el multiplicador")

	enemy.take_damage(5, 2)
	_check(enemy.health == 96, "la penetración ignora armadura (5 - (3 - 2) = 4)")
	enemy.free()

	var wave := WaveData.new()
	var entry := WaveEntry.new()
	entry.enemy = PALITA
	entry.count = 10
	wave.entries = [entry]
	_check(wave.build_schedule(1.2).size() == 12, "la cantidad de enemigos usa el multiplicador")
	Modifiers.reset()


func _test_news_choice() -> void:
	print("Pantalla de noticias")
	var choice: NewsChoice = NEWS_CHOICE.instantiate()
	add_child(choice)
	var event := _make_event()
	var result := []
	# Una lambda async: espera la elección y la guarda, mientras la prueba sigue.
	var wait := func(): result.append(await choice.choose(event))
	wait.call()

	_check(choice.visible and get_tree().paused, "se muestra y pausa el juego")
	_check(choice.get_node("%Cards").get_child_count() == 2, "una tarjeta por opción")
	choice.pick(event.options[1])
	await get_tree().process_frame
	_check(result == [event.options[1]], "devuelve la opción elegida")
	_check(not choice.visible and not get_tree().paused, "se oculta y despausa")
	choice.queue_free()


func _test_news_between_waves() -> void:
	print("Noticia entre oleadas")
	var level := LEVEL.instantiate()
	TestUtils.silence(level)
	level.intro = null
	var no_dialogues: Array[Dialogue] = []
	level.wave_dialogues = no_dialogues
	level.ending = null
	var event := _make_event()
	var news: Array[NewsEvent] = [event]
	level.wave_news = news
	var spawner: WaveSpawner = level.get_node("WaveSpawner")
	spawner.waves = [_make_wave(), _make_wave()]
	add_child(level)
	var box: DialogueBox = level.get_node("DialogueBox")
	var choice: NewsChoice = level.get_node("NewsChoice")

	await _wait_until(func(): return box.is_playing() or choice.visible)
	while box.is_playing():
		box.advance()
		await get_tree().process_frame
	await _wait_until(func(): return choice.visible)
	_check(choice.visible, "después de la oleada 1 aparece la elección")
	_check(spawner.current_wave == 0, "la oleada 2 todavía no arrancó")

	choice.pick(event.options[0])
	await _wait_until(func(): return spawner.current_wave == 1)
	_check(Modifiers.get_value(Modifiers.Stat.UNIT_DAMAGE) == 0.25, "se aplicó el efecto elegido")
	_check(spawner.current_wave == 1, "después de elegir arranca la oleada 2")
	level.queue_free()
	Modifiers.reset()


# Noticia con un diálogo de una línea y dos opciones.
func _make_event() -> NewsEvent:
	var line := DialogueLine.new()
	line.speaker = Speaker.new()
	line.text_key = "NEWS_01_01"
	var dialogue := Dialogue.new()
	dialogue.lines.append(line)

	var event := NewsEvent.new()
	event.dialogue = dialogue
	for amount in [0.25, -0.25]:
		var effect := NewsEffect.new()
		effect.stat = Modifiers.Stat.UNIT_DAMAGE
		effect.amount = amount
		var option := NewsOption.new()
		option.title_key = "NEWS_01_A"
		option.effects.append(effect)
		event.options.append(option)
	return event


# Oleada de un solo enemigo.
func _make_wave() -> WaveData:
	var entry := WaveEntry.new()
	entry.enemy = PALITA
	entry.count = 1
	var wave := WaveData.new()
	wave.entries = [entry]
	return wave


# Espera frames hasta que `condition` dé true, o hasta TIMEOUT segundos de juego.
func _wait_until(condition: Callable) -> void:
	var time_left := TIMEOUT
	while not condition.call() and time_left > 0.0:
		await get_tree().process_frame
		time_left -= get_process_delta_time()


func _check(condition: bool, description: String) -> void:
	if condition:
		print("  ok     ", description)
	else:
		_failures += 1
		print("  FALLA  ", description)
