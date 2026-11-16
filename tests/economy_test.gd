extends Node
## Prueba automática de Economy.
##
## Se corre desde la terminal, sin abrir el editor:
##   godot --headless --path . res://tests/economy_test.tscn
## Imprime cada chequeo y termina con código 0 si todo pasó, o 1 si algo falló.

var _failures := 0
var _depleted_kinds: Array = []


func _ready() -> void:
	# Escuchamos la señal de derrota para comprobar que se emite cuando corresponde.
	Economy.depleted.connect(func(kind): _depleted_kinds.append(kind))

	_test_starts_full()
	_test_spend()
	_test_cannot_spend_last_unit()
	_test_refund()
	_test_steal_and_defeat()

	print("")
	print("Resultado: %d falla(s)" % _failures)
	get_tree().quit(1 if _failures > 0 else 0)


func _test_starts_full() -> void:
	print("Empieza con los valores iniciales")
	Economy.reset()
	_check(Economy.earth == Economy.STARTING_EARTH, "tierra inicial")
	_check(Economy.water == Economy.STARTING_WATER, "agua inicial")


func _test_spend() -> void:
	print("Gastar")
	Economy.reset()
	_check(Economy.spend(30, 10), "puede pagar 30 de tierra y 10 de agua")
	_check(Economy.earth == 70 and Economy.water == 90, "quedan 70 de tierra y 90 de agua")
	_check(not Economy.spend(500, 0), "no puede pagar 500 de tierra")
	_check(Economy.earth == 70 and Economy.water == 90, "si no alcanza, no gasta nada")


func _test_cannot_spend_last_unit() -> void:
	print("No se puede gastar hasta quedar en 0")
	Economy.reset()
	_check(not Economy.spend(Economy.STARTING_EARTH, 0), "no puede gastar toda la tierra")
	_check(Economy.spend(Economy.STARTING_EARTH - 1, 0), "sí puede dejar 1 de tierra")


func _test_refund() -> void:
	print("Devolución de un golem caído")
	Economy.reset()
	Economy.spend(40, 20)
	Economy.refund(40, 20)
	_check(Economy.earth == 80 and Economy.water == 90, "devuelve la mitad del costo")


func _test_steal_and_defeat() -> void:
	print("Robo y derrota")
	Economy.reset()
	_depleted_kinds.clear()
	Economy.steal(Economy.Kind.WATER, 30)
	_check(Economy.water == 70, "robar 30 de agua deja 70")
	_check(_depleted_kinds.is_empty(), "todavía no hay derrota")
	Economy.steal(Economy.Kind.WATER, 999)
	_check(Economy.water == 0, "el agua no baja de 0")
	_check(_depleted_kinds == [Economy.Kind.WATER], "se avisa la derrota por agua")
	Economy.steal(Economy.Kind.EARTH, 999)
	_check(_depleted_kinds.size() == 1, "la derrota se avisa una sola vez")


func _check(condition: bool, description: String) -> void:
	if condition:
		print("  ok     ", description)
	else:
		_failures += 1
		print("  FALLA  ", description)
