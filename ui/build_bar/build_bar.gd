extends CanvasLayer
## Un botón por cada unidad de `units`, con su costo actual (con modificadores).
## Los botones se desactivan si no alcanzan los recursos o si hay una construcción en curso.
## Las teclas 1, 2, 3… seleccionan la primera, segunda, tercera unidad.

signal unit_selected(data: UnitData)

@export var units: Array[UnitData] = []

# Botón -> UnitData que representa.
var _buttons := {}
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


## Recibe UnitPlacer.building_changed: desactiva todo mientras se construye.
func set_building(is_building: bool) -> void:
	_is_building = is_building
	_refresh_buttons()


## Crea un botón con la imagen de la unidad y lo agrega a la barra.
## El texto (nombre y costo) lo escribe _refresh_buttons().
func _add_button(data: UnitData) -> void:
	var button := Button.new()
	button.icon = data.get_icon()
	button.expand_icon = true
	button.custom_minimum_size = Vector2(220, 72)
	# Sin foco: así la barra espaciadora y las flechas no "aprietan" el botón.
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(func(): unit_selected.emit(data))
	_buttons_box.add_child(button)
	_buttons[button] = data


## Responde a Economy.changed.
func _on_economy_changed(_earth: int, _water: int) -> void:
	_refresh_buttons()


## Actualiza el costo de cada botón y desactiva los que no se pueden usar ahora.
func _refresh_buttons() -> void:
	for button: Button in _buttons:
		var data: UnitData = _buttons[button]
		var earth_cost := Modifiers.earth_cost(data)
		var water_cost := Modifiers.water_cost(data)
		button.text = "%s\n%s" % [tr(data.name_key), tr("BUILD_COST") % [earth_cost, water_cost]]
		button.disabled = _is_building or not Economy.can_afford(earth_cost, water_cost)
