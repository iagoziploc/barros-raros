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
	_test_csv_rows()
	_test_resources()
	await _test_sudden_death()
	_test_defeat()
	_test_mute_button()
	_test_unit_unlocked()

	print("")
	print("Resultado: %d falla(s)" % _failures)
	get_tree().quit(1 if _failures > 0 else 0)


func _test_translations() -> void:
	print("Traducciones")
	_check(tr("HUD_EARTH") != "HUD_EARTH", "la clave HUD_EARTH tiene texto")
	_check(tr("HUD_DEFEAT") != "HUD_DEFEAT", "la clave HUD_DEFEAT tiene texto")


func _test_csv_rows() -> void:
	print("strings.csv bien formado")
	var file := FileAccess.open("res://localization/strings.csv", FileAccess.READ)
	var broken: Array[String] = []
	while not file.eof_reached():
		# get_csv_line() lee una fila entera, respetando comillas y saltos de línea adentro.
		var row := file.get_csv_line()
		if row.size() == 1 and row[0] == "":
			continue  # Línea vacía (por ejemplo, la última).
		if row.size() != 2:
			broken.append("%s (%d columnas)" % [row[0], row.size()])
	_check(broken.is_empty(), "cada fila tiene clave y texto (2 columnas). Rotas: %s" % [broken])


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
	_check(_label("RetryLabel").visible, "y cómo reintentar")
	_hud.show_victory()
	_check(_label("RetryLabel").text == tr("HUD_PLAY_AGAIN"), "al ganar, cómo volver a jugar")


func _test_unit_unlocked() -> void:
	print("Cartel de unidad nueva")
	var data: UnitData = load("res://data/units/tierra.tres")
	_hud.show_unit_unlocked(data)
	_check(_label("UnlockLabel").visible, "aparece")
	_check(_label("UnlockLabel").text == tr("UNIT_UNLOCKED") % tr(data.name_key), "con el nombre de la unidad")


func _test_mute_button() -> void:
	print("Parlantito")
	var button: MuteButton = _hud.get_node("MuteButton")
	Mute.set_muted(false)
	button.pressed.emit()
	_check(Mute.is_muted(), "tocarlo apaga el sonido")
	button.pressed.emit()
	_check(not Mute.is_muted(), "tocarlo de nuevo lo prende")


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
