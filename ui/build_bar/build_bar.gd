extends CanvasLayer
## Un botón por cada unidad de `units`, con su costo actual (con modificadores).
## Las unidades que se estrenan más tarde se suman con unlock().
## Los botones se desactivan si no alcanzan los recursos o si hay una construcción en curso.
## El recurso que falta se pinta de rojo en el costo.
## Las teclas 1, 2, 3… seleccionan la primera, segunda, tercera unidad.

signal unit_selected(data: UnitData)
## Se sumó una unidad nueva a la barra.
signal unit_unlocked(data: UnitData)

## Unidades disponibles desde el comienzo.
@export var units: Array[UnitData] = []

const MISSING_COLOR := "#ff6b5b"

# Botón -> UnitData que representa.
var _buttons := {}
# Botón -> RichTextLabel con su nombre y costo.
var _labels := {}
var _is_building := false

@onready var _buttons_box: HBoxContainer = %Buttons


## Crea los botones y los mantiene actualizados con los recursos y los modificadores.
func _ready() -> void:
	for data in units:
		_add_button(data)
	Economy.changed.connect(_on_economy_changed)
	Modifiers.changed.connect(_refresh_buttons)
	_refresh_buttons()


## Tecla N: selecciona la unidad N de la lista.
func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	var index := key.keycode - KEY_1
	if index >= 0 and index < units.size():
		unit_selected.emit(units[index])


## Suma `data` a la barra (si no estaba) con su botón y su tecla.
func unlock(data: UnitData) -> void:
	if data in units:
		return
	units.append(data)
	_add_button(data)
	_refresh_buttons()
	unit_unlocked.emit(data)


## Recibe UnitPlacer.building_changed: desactiva todo mientras se construye.
func set_building(is_building: bool) -> void:
	_is_building = is_building
	_refresh_buttons()


## Crea un botón con la imagen de la unidad y lo agrega a la barra.
## El texto (nombre y costo) va en un RichTextLabel adentro del botón, porque un Button
## no puede pintar una parte de su texto de otro color. Lo escribe _refresh_buttons().
func _add_button(data: UnitData) -> void:
	var button := Button.new()
	button.icon = data.get_icon()
	button.expand_icon = true
	button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.custom_minimum_size = Vector2(240, 72)
	# Sin foco: así la barra espaciadora y las flechas no "aprietan" el botón.
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(func(): unit_selected.emit(data))

	var label := RichTextLabel.new()
	label.bbcode_enabled = true
	label.scroll_active = false
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Que el clic llegue al botón.
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.offset_left = 64  # A la derecha del ícono.
	label.offset_top = 10
	button.add_child(label)

	_buttons_box.add_child(button)
	_buttons[button] = data
	_labels[button] = label


## Responde a Economy.changed.
func _on_economy_changed(_earth: int, _water: int) -> void:
	_refresh_buttons()


## Actualiza el costo de cada botón y desactiva los que no se pueden usar ahora.
func _refresh_buttons() -> void:
	for button: Button in _buttons:
		var data: UnitData = _buttons[button]
		var earth_cost := Modifiers.earth_cost(data)
		var water_cost := Modifiers.water_cost(data)
		var earth_text := tr("BUILD_COST_EARTH") % earth_cost
		var water_text := tr("BUILD_COST_WATER") % water_cost
		if Economy.earth < earth_cost:
			earth_text = "[color=%s]%s[/color]" % [MISSING_COLOR, earth_text]
		if Economy.water < water_cost:
			water_text = "[color=%s]%s[/color]" % [MISSING_COLOR, water_text]
		_labels[button].text = "%s\n%s · %s" % [tr(data.name_key), earth_text, water_text]
		button.disabled = _is_building or not Economy.can_afford(earth_cost, water_cost)
