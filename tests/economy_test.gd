extends Node
## Pruebas de Economy. Se corre con:
##   godot --headless --path . res://tests/economy_test.tscn
## Sale con código 0 si todo pasó y 1 si algo falló.
## Los valores esperados se calculan desde Economy.config, no están escritos a mano.

var _failures := 0
# Señales recibidas, en orden.
var _events: Array[String] = []


func _ready() -> void:
	Economy.sudden_death_started.connect(func(kind): _events.append("start %s" % kind))
	Economy.sudden_death_ended.connect(func(kind): _events.append("end %s" % kind))
	Economy.defeated.connect(func(kind): _events.append("defeated %s" % kind))

	_test_starts_full()
	_test_spend()
	_test_can_spend_to_zero()
	_test_max_is_a_cap()
	_test_refunds()
	_test_sudden_death_recovered()
	_test_sudden_death_timeout()

	print("")
	print("Resultado: %d falla(s)" % _failures)
	get_tree().quit(1 if _failures > 0 else 0)


func _test_starts_full() -> void:
	print("Empieza con los valores iniciales")
	_reset()
	_check(Economy.earth == Economy.config.starting_earth, "tierra inicial")
	_check(Economy.water == Economy.config.starting_water, "agua inicial")


func _test_spend() -> void:
	print("Gastar")
	_reset()
	var earth := Economy.earth
	var water := Economy.water
	_check(Economy.spend(30, 10), "puede pagar 30 de tierra y 10 de agua")
	_check(Economy.earth == earth - 30 and Economy.water == water - 10, "se descuenta el costo")
	_check(not Economy.spend(9999, 0), "no puede pagar más de lo que tiene")
	_check(Economy.earth == earth - 30, "si no alcanza, no gasta nada")


func _test_can_spend_to_zero() -> void:
	print("Se puede gastar hasta quedar en 0")
	_reset()
	_check(Economy.spend(Economy.earth, 0), "puede gastar toda la tierra")
	_check(Economy.earth == 0, "queda en 0")
	_check(Economy.is_in_sudden_death(Economy.Kind.EARTH), "y empieza la muerte súbita")


func _test_max_is_a_cap() -> void:
	print("El máximo es un tope")
	_reset()
	Economy.add(500, 500)
	_check(Economy.earth == Economy.max_earth, "la tierra no pasa del máximo")
	_check(Economy.water == Economy.max_water, "el agua no pasa del máximo")


func _test_refunds() -> void:
	print("Devolución de unidades")
	_reset()
	Economy.spend(40, 20)
	var earth := Economy.earth
	var water := Economy.water
	Economy.refund_destroyed(40, 20)
	var ratio := Economy.config.refund_ratio_destroyed
	_check(Economy.earth == earth + floori(40 * ratio), "destruirlo devuelve su parte de tierra")
	_check(Economy.water == water + floori(20 * ratio), "destruirlo devuelve su parte de agua")

	_reset()
	Economy.spend(40, 20)
	Economy.refund_survived(40, 20)
	_check(Economy.earth == Economy.config.starting_earth, "si sobrevive a la oleada, vuelve todo")


func _test_sudden_death_recovered() -> void:
	print("Muerte súbita: recuperarse a tiempo")
	_reset()
	Economy.steal(Economy.Kind.WATER, 9999)
	_check(Economy.water == 0, "el agua no baja de 0")
	_check(_events == ["start %s" % Economy.Kind.WATER], "empieza la muerte súbita del agua")

	# Llamar a _process a mano simula el paso del tiempo sin esperar.
	Economy._process(Economy.config.sudden_death_seconds - 0.5)
	_check(Economy.sudden_death_time_left(Economy.Kind.WATER) > 0.0, "todavía queda tiempo")

	Economy.add(0, 10)
	_check(not Economy.is_in_sudden_death(Economy.Kind.WATER), "al recuperar agua se cancela")
	_check(_events.has("end %s" % Economy.Kind.WATER), "se avisa que terminó")
	_check(not _events.has("defeated %s" % Economy.Kind.WATER), "no hay derrota")


func _test_sudden_death_timeout() -> void:
	print("Muerte súbita: se termina el tiempo")
	_reset()
	Economy.steal(Economy.Kind.EARTH, 9999)
	Economy._process(Economy.config.sudden_death_seconds + 0.1)
	_check(_events.has("defeated %s" % Economy.Kind.EARTH), "se avisa la derrota por tierra")

	Economy.add(50, 0)
	_check(Economy.earth == 0, "después de perder, ya nada cambia")
	_check(Economy.is_defeated(), "is_defeated() devuelve true")
	_check(not Economy.can_afford(0, 0), "después de perder no se puede gastar")
	Economy._process(10.0)
	_check(_events.count("defeated %s" % Economy.Kind.EARTH) == 1, "la derrota se avisa una sola vez")


func _reset() -> void:
	Economy.reset()
	_events.clear()


func _check(condition: bool, description: String) -> void:
	if condition:
		print("  ok     ", description)
	else:
		_failures += 1
		print("  FALLA  ", description)
