extends Node
## Pruebas de Modifiers, las listas de noticias, NewsChoice y las noticias entre oleadas. Se corre con:
##   godot --headless --path . res://tests/news_test.tscn
## Sale con código 0 si todo pasó y 1 si algo falló.

const LEVEL := preload("res://levels/level_01/level_01.tscn")
const ENEMY := preload("res://entities/enemies/enemy.tscn")
const NEWS_CHOICE := preload("res://ui/news_choice/news_choice.tscn")
const BALANCED := preload("res://data/units/balanceado.tres")
const PALITA := preload("res://data/enemies/salaryman_palita.tres")
const GOOD_NEWS := preload("res://data/news/good_news.tres")
const BAD_NEWS := preload("res://data/news/bad_news.tres")

## Tiempo máximo de juego (no real) que se espera a que pase algo.
const TIMEOUT := 120.0

var _failures := 0


func _ready() -> void:
	Engine.time_scale = 8.0
	_test_modifiers()
	_test_modifiers_in_game_objects()
	_test_pools()
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


func _test_pools() -> void:
	print("Listas de buenas y malas noticias")
	var all_good := true
	var all_bad := true
	for i in 30:
		for option in GOOD_NEWS.draw(2):
			var effect: NewsEffect = option.effects[0]
			all_good = all_good and Modifiers.is_good(effect.stat, effect.amount)
		for option in BAD_NEWS.draw(2):
			var effect: NewsEffect = option.effects[0]
			all_bad = all_bad and not Modifiers.is_good(effect.stat, effect.amount)
	_check(all_good, "las buenas siempre son buenas")
	_check(all_bad, "las malas siempre son malas")

	var options := GOOD_NEWS.draw(2)
	_check(options.size() == 2 and options[0].title_key != options[1].title_key, "saca 2 distintas")

	var effect_range := EffectRange.new()
	effect_range.stat = Modifiers.Stat.UNIT_DAMAGE
	effect_range.min_amount = 0.15
	effect_range.max_amount = 0.25
	var in_range := true
	var values := {}
	for i in 50:
		var amount: float = effect_range.roll().effects[0].amount
		in_range = in_range and amount >= 0.15 and amount <= 0.25
		values[amount] = true
	_check(in_range, "el valor sale entre el mínimo y el máximo")
	_check(values.size() > 1, "y no siempre el mismo")


func _test_news_choice() -> void:
	print("Pantalla de buenas y malas noticias")
	Economy.reset()
	Modifiers.reset()
	var choice: NewsChoice = NEWS_CHOICE.instantiate()
	add_child(choice)
	var done := []
	# Una lambda async: espera toda la elección, mientras la prueba sigue.
	var wait := func():
		await choice.run(GOOD_NEWS, BAD_NEWS)
		done.append(true)
	wait.call()

	var cards := choice.get_node("%Cards")
	_check(choice.visible and get_tree().paused, "se muestra y pausa el juego")
	_check(cards.get_child_count() == 2, "dos tarjetas boca abajo")

	choice.pick_kind(NewsChoice.Kind.BAD)
	await get_tree().process_frame
	_check(choice.shown_options().size() == 2, "al abrir la mala aparecen 2 opciones")
	var first := choice.shown_options()
	choice.reroll()
	_check(Economy.earth == 100, "el primer re-roll es gratis")
	choice.reroll()
	_check(Economy.earth == 100 - choice.reroll_earth_cost and Economy.water == 100 - choice.reroll_water_cost,
			"el segundo cobra tierra y agua")
	_check(choice.shown_options() != first, "y cambia las opciones")

	var bad: NewsOption = choice.shown_options()[0]
	choice.pick(bad)
	await get_tree().process_frame
	_check(cards.get_child_count() == 1 and choice.visible, "queda la otra tarjeta boca abajo")
	_check(not done, "todavía no terminó")

	choice.pick_kind(NewsChoice.Kind.GOOD)
	await get_tree().process_frame
	var good: NewsOption = choice.shown_options()[0]
	choice.pick(good)
	await get_tree().process_frame
	_check(done == [true], "con las dos elegidas, termina")
	_check(not choice.visible and not get_tree().paused, "se oculta y despausa")
	var good_effect: NewsEffect = good.effects[0]
	var bad_effect: NewsEffect = bad.effects[0]
	if good_effect.stat != bad_effect.stat and good_effect.stat in Modifiers.PERCENT_STATS:
		_check(is_equal_approx(Modifiers.get_value(good_effect.stat), good_effect.amount), "se aplicó la buena elegida")
	if good_effect.stat != bad_effect.stat and bad_effect.stat in Modifiers.PERCENT_STATS:
		_check(is_equal_approx(Modifiers.get_value(bad_effect.stat), bad_effect.amount), "se aplicó la mala elegida")
	choice.queue_free()
	Modifiers.reset()
	Economy.reset()


func _test_news_between_waves() -> void:
	print("Noticias entre oleadas")
	var level := LEVEL.instantiate()
	TestUtils.silence(level)
	TestUtils.remove_lobito(level)
	level.intro = null
	var no_dialogues: Array[Dialogue] = []
	level.wave_dialogues = no_dialogues
	level.ending = null
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
	_check(choice.visible, "después de la oleada 1 aparecen las noticias")
	_check(spawner.current_wave == 0, "la oleada 2 todavía no arrancó")

	for kind in [NewsChoice.Kind.GOOD, NewsChoice.Kind.BAD]:
		choice.pick_kind(kind)
		await get_tree().process_frame
		choice.pick(choice.shown_options()[0])
		await get_tree().process_frame
	await _wait_until(func(): return spawner.current_wave == 1)
	_check(spawner.current_wave == 1, "después de elegir las dos arranca la oleada 2")
	level.queue_free()
	Modifiers.reset()


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
