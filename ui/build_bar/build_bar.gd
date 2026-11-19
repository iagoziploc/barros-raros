extends CanvasLayer
## Un botón por cada golem de `golems`. Los botones se desactivan si no alcanzan los recursos.
## Las teclas 1, 2, 3… seleccionan el primer, segundo, tercer golem.

signal golem_selected(data: GolemData)

@export var golems: Array[GolemData] = []

# Botón -> GolemData que representa.
var _buttons := {}

@onready var _buttons_box: HBoxContainer = %Buttons


## Crea los botones y los mantiene actualizados con los recursos.
func _ready() -> void:
	for data in golems:
		_add_button(data)
	Economy.changed.connect(_on_economy_changed)
	_refresh_buttons()


## Tecla N: selecciona el golem N de la lista.
func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	var index := key.keycode - KEY_1
	if index >= 0 and index < golems.size():
		golem_selected.emit(golems[index])


## Crea un botón con nombre, costo e imagen del golem, y lo agrega a la barra.
func _add_button(data: GolemData) -> void:
	var button := Button.new()
	button.text = "%s\n%s" % [tr(data.name_key), tr("BUILD_COST") % [data.earth_cost, data.water_cost]]
	button.icon = data.texture
	button.expand_icon = true
	button.custom_minimum_size = Vector2(220, 72)
	# Sin foco: así la barra espaciadora y las flechas no "aprietan" el botón.
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(func(): golem_selected.emit(data))
	_buttons_box.add_child(button)
	_buttons[button] = data


## Responde a Economy.changed.
func _on_economy_changed(_earth: int, _water: int) -> void:
	_refresh_buttons()


## Desactiva los botones de los golems que no se pueden pagar.
func _refresh_buttons() -> void:
	for button: Button in _buttons:
		var data: GolemData = _buttons[button]
		button.disabled = not Economy.can_afford(data.earth_cost, data.water_cost)
