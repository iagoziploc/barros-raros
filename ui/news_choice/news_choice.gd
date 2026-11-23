class_name NewsChoice
extends CanvasLayer
## Muestra las opciones de un NewsEvent como tarjetas y espera a que el jugador elija una.
## Pausa el juego mientras está abierta (process_mode = Always en la escena).

## El jugador eligió una opción.
signal chosen(option: NewsOption)

const GOOD_COLOR := "#9be37a"
const BAD_COLOR := "#ff8a6e"

@onready var _title: Label = %Title
@onready var _cards_box: HBoxContainer = %Cards


## Arranca oculta, con el título traducido.
func _ready() -> void:
	_title.text = tr("NEWS_TITLE")
	hide()


## Muestra las opciones de `event` y espera la elección. Usar con await:
## `var option: NewsOption = await news_choice.choose(event)`.
func choose(event: NewsEvent) -> NewsOption:
	for child in _cards_box.get_children():
		child.queue_free()
	for option in event.options:
		_cards_box.add_child(_make_card(option))

	var was_paused := get_tree().paused
	get_tree().paused = true
	show()
	var option: NewsOption = await chosen
	hide()
	get_tree().paused = was_paused
	return option


## Elige `option` como si el jugador hubiera tocado su tarjeta (lo usan las pruebas).
func pick(option: NewsOption) -> void:
	chosen.emit(option)


## Arma la tarjeta de una opción: título, efectos (verde = bueno, rojo = malo) y botón.
func _make_card(option: NewsOption) -> Control:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(420, 0)
	card.add_theme_stylebox_override("panel", _card_style())

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	card.add_child(column)

	var title := Label.new()
	title.text = tr(option.title_key)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.add_theme_font_size_override("font_size", 26)
	column.add_child(title)

	var effects := RichTextLabel.new()
	effects.bbcode_enabled = true
	effects.fit_content = true
	effects.scroll_active = false
	effects.add_theme_font_size_override("normal_font_size", 22)
	for effect in option.effects:
		var color := GOOD_COLOR if Modifiers.is_good(effect.stat, effect.amount) else BAD_COLOR
		effects.append_text("[color=%s]%s[/color]\n" % [color, Modifiers.describe(effect.stat, effect.amount)])
	column.add_child(effects)

	var button := Button.new()
	button.text = tr("NEWS_CHOOSE")
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(pick.bind(option))
	column.add_child(button)
	return card


## Fondo de las tarjetas: el mismo marrón con borde que la caja de diálogo.
func _card_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.13, 0.09, 0.06)
	style.border_color = Color(0.55, 0.4, 0.25)
	style.set_border_width_all(3)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(20)
	return style
