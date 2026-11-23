class_name DialogueBox
extends CanvasLayer
## Muestra un Dialogue línea por línea, con el texto apareciendo letra por letra.
## Clic, Espacio o Enter: completa la línea que se está escribiendo o pasa a la siguiente.
## Corre aunque el juego esté pausado (process_mode = Always en la escena).

## Se emite al cerrar la última línea.
signal finished

## Velocidad del efecto de máquina de escribir.
@export var characters_per_second := 40.0

var _dialogue: Dialogue
var _index := -1
# Caracteres visibles acumulados como float, para avanzar de a fracciones por frame.
var _visible_chars := 0.0
# Estado de pausa anterior al diálogo, para restaurarlo al terminar.
var _was_paused := false

@onready var _box: Control = %Box
@onready var _box_portrait: TextureRect = %BoxPortrait
@onready var _box_name: Label = %BoxName
@onready var _box_text: RichTextLabel = %BoxText
@onready var _cinematic: Control = %Cinematic
@onready var _cinematic_portrait: TextureRect = %CinematicPortrait
@onready var _cinematic_name: Label = %CinematicName
@onready var _cinematic_text: RichTextLabel = %CinematicText
@onready var _advance_sound: AudioStreamPlayer = $AdvanceSound


## Arranca oculto.
func _ready() -> void:
	_box.hide()
	_cinematic.hide()


## Hace avanzar el efecto de máquina de escribir.
func _process(delta: float) -> void:
	if _dialogue == null:
		return
	var text := _text_label()
	var total := text.get_total_character_count()
	if text.visible_characters < 0 or text.visible_characters >= total:
		return
	_visible_chars += characters_per_second * delta
	text.visible_characters = mini(int(_visible_chars), total)


## Mientras hay un diálogo, se queda con los clics y con Espacio/Enter antes que nadie.
func _input(event: InputEvent) -> void:
	if _dialogue == null:
		return
	var click := event as InputEventMouseButton
	var clicked := click != null and click.pressed and click.button_index == MOUSE_BUTTON_LEFT
	if clicked or event.is_action_pressed("ui_accept"):
		advance()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel"):
		_finish()
		get_viewport().set_input_as_handled()

## Muestra `dialogue` y espera a que termine. Usar con await: `await dialogue_box.play(d)`.
func play(dialogue: Dialogue) -> void:
	if dialogue == null or dialogue.lines.is_empty():
		return
	_dialogue = dialogue
	_index = -1
	_was_paused = get_tree().paused
	if dialogue.pauses_game:
		get_tree().paused = true
	_layout().show()
	advance()
	await finished


## true mientras hay un diálogo en pantalla.
func is_playing() -> bool:
	return _dialogue != null


## Si la línea actual todavía se está escribiendo, la completa. Si no, pasa a la siguiente.
func advance() -> void:
	if _dialogue == null:
		return
	var text := _text_label()
	if _index >= 0 and text.visible_characters >= 0 \
			and text.visible_characters < text.get_total_character_count():
		text.visible_characters = -1  # -1 = mostrar todo.
		return

	_advance_sound.play()
	_index += 1
	if _index >= _dialogue.lines.size():
		_finish()
	else:
		_show_line(_dialogue.lines[_index])


## Carga nombre, retrato y texto de `line` en el estilo actual, con el texto oculto.
func _show_line(line: DialogueLine) -> void:
	var speaker := line.speaker
	var name_label := _cinematic_name if _is_cinematic() else _box_name
	var portrait := _cinematic_portrait if _is_cinematic() else _box_portrait

	name_label.text = tr(speaker.name_key) if speaker and speaker.name_key != "" else ""
	name_label.visible = name_label.text != ""
	if speaker:
		name_label.add_theme_color_override("font_color", speaker.name_color)
	portrait.texture = speaker.portrait if speaker else null
	portrait.visible = portrait.texture != null

	var text := _text_label()
	var content := tr(line.text_key)
	text.text = "[center]%s[/center]" % content if _is_cinematic() else content
	text.visible_characters = 0
	_visible_chars = 0.0


## Oculta todo, restaura la pausa y avisa que terminó.
func _finish() -> void:
	_layout().hide()
	_dialogue = null
	get_tree().paused = _was_paused
	finished.emit()


## true si el diálogo actual usa el estilo cinemático.
func _is_cinematic() -> bool:
	return _dialogue.style == Dialogue.Style.CINEMATIC


## Contenedor del estilo actual (caja o cinemática).
func _layout() -> Control:
	return _cinematic if _is_cinematic() else _box


## Etiqueta de texto del estilo actual.
func _text_label() -> RichTextLabel:
	return _cinematic_text if _is_cinematic() else _box_text
