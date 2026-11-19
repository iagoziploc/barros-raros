extends Node
## Pruebas del HUD. Se corre con:
##   godot --headless --path . res://tests/hud_test.tscn
## Sale con código 0 si todo pasó y 1 si algo falló.

const HUD := preload("res://ui/hud/hud.tscn")

var _failures := 0
var _hud: CanvasLayer


func _ready() -> void:
	Economy.reset()
	_hud = HUD.instantiate()
	add_child(_hud)

	_test_translations()
	_test_resources()
	await _test_sudden_death()
	_test_defeat()

	print("")
	print("Resultado: %d falla(s)" % _failures)
	get_tree().quit(1 if _failures > 0 else 0)


func _test_translations() -> void:
	print("Traducciones")
	_check(tr("HUD_EARTH") != "HUD_EARTH", "la clave HUD_EARTH tiene texto")
	_check(tr("HUD_DEFEAT") != "HUD_DEFEAT", "la clave HUD_DEFEAT tiene texto")


func _test_resources() -> void:
	print("Tierra y agua")
	_check(_label("EarthLabel").text.contains("%d" % Economy.earth), "muestra la tierra inicial")
	Economy.steal(Economy.Kind.WATER, 30)
	_check(_label("WaterLabel").text.contains("%d" % Economy.water), "se actualiza al robar agua")


func _test_sudden_death() -> void:
	print("Muerte súbita")
	_check(not _label("WaterAlert").visible, "sin alerta mientras hay agua")
	Economy.steal(Economy.Kind.WATER, 9999)
	await _after_next_process()
	_check(_label("WaterAlert").visible, "aparece la alerta al quedarse sin agua")
	_check(not _label("EarthAlert").visible, "la de tierra sigue oculta")
	Economy.add(0, 10)
	await _after_next_process()
	_check(not _label("WaterAlert").visible, "desaparece al recuperar agua")


func _test_defeat() -> void:
	print("Derrota")
	_check(not _label("MessageLabel").visible, "sin cartel antes de perder")
	Economy.steal(Economy.Kind.EARTH, 9999)
	Economy._process(Economy.config.sudden_death_seconds + 0.1)
	_check(_label("MessageLabel").visible, "aparece el cartel de derrota")
	_check(_label("MessageLabel").text == tr("HUD_DEFEAT"), "con el texto de derrota")


# process_frame se emite antes de los _process() de ese frame:
# esperarlo dos veces garantiza que el _process() del HUD ya corrió.
func _after_next_process() -> void:
	await get_tree().process_frame
	await get_tree().process_frame


func _label(unique_name: String) -> Label:
	return _hud.get_node("%" + unique_name)


func _check(condition: bool, description: String) -> void:
	if condition:
		print("  ok     ", description)
	else:
		_failures += 1
		print("  FALLA  ", description)
