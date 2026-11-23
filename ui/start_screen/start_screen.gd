class_name StartScreen
extends CanvasLayer
## Pantalla negra del comienzo: título, controles y "clic para empezar".
## Pausa el juego hasta el clic (process_mode = Always en la escena).
## Se muestra una sola vez por sesión: al reiniciar con R ya no aparece.

## El jugador hizo clic para empezar.
signal started

# `static`: sobrevive a reload_current_scene(), como los diálogos ya vistos del nivel.
static var _was_shown := false

@onready var _title: Label = %Title
@onready var _controls: Label = %Controls
@onready var _click_label: Label = %ClickLabel


## Arranca oculta, con los textos traducidos.
func _ready() -> void:
	_title.text = tr("START_TITLE")
	_controls.text = tr("START_CONTROLS")
	_click_label.text = tr("START_CLICK")
	hide()


## Muestra la pantalla y espera el clic. Usar con await. Si ya se mostró en esta sesión,
## vuelve enseguida.
func wait_for_start() -> void:
	if _was_shown:
		return
	_was_shown = true
	var was_paused := get_tree().paused
	get_tree().paused = true
	show()
	_blink()
	await started
	hide()
	get_tree().paused = was_paused


## Clic izquierdo (o Enter / espacio) mientras está visible: empieza.
func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	var click := event as InputEventMouseButton
	var is_click := click != null and click.pressed and click.button_index == MOUSE_BUTTON_LEFT
	if is_click or event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		started.emit()


## Hace titilar "clic para empezar" mientras la pantalla esté abierta.
func _blink() -> void:
	var tween := create_tween().set_loops()
	tween.tween_property(_click_label, "modulate:a", 0.25, 0.6)
	tween.tween_property(_click_label, "modulate:a", 1.0, 0.6)
	# El tween se corta solo al ocultarse: así no queda corriendo para siempre.
	started.connect(tween.kill, CONNECT_ONE_SHOT)
