class_name NewsChoice
extends CanvasLayer
## Las buenas y malas noticias entre oleadas. Aparecen dos tarjetas boca abajo (la buena y la
## mala); el jugador elige cuál abrir primero. Al abrirla se sortean 2 opciones de su lista
## (EffectPool), elige una y se aplica. Después abre la otra. Se puede pedir otras opciones
## (re-roll): `free_rerolls` gratis cada vez que aparece la pantalla; después cuesta recursos.
## Pausa el juego mientras está abierta (process_mode = Always en la escena).

## El jugador dio vuelta la tarjeta `kind`.
signal kind_picked(kind: Kind)
## El jugador eligió una opción.
signal chosen(option: NewsOption)

## Las dos tarjetas.
enum Kind { GOOD, BAD }

const GOOD_COLOR := "#9be37a"
const BAD_COLOR := "#ff8a6e"
const CARD_BACKGROUND := Color(0.13, 0.09, 0.06)
const GOOD_BORDER := Color(0.45, 0.7, 0.35)
const BAD_BORDER := Color(0.75, 0.35, 0.28)
const NEUTRAL_BORDER := Color(0.55, 0.4, 0.25)

## Cuántas opciones se muestran al abrir cada tarjeta.
@export var options_per_card := 2
## Re-rolls gratis cada vez que aparece la pantalla.
@export var free_rerolls := 1
## Lo que cuesta cada re-roll después de los gratis.
@export var reroll_earth_cost := 5
@export var reroll_water_cost := 5

# Re-rolls usados en esta aparición de la pantalla.
var _rerolls_used := 0
# Lista de la tarjeta abierta (para el re-roll) y opciones que se están mostrando.
var _open_pool: EffectPool
var _shown_options: Array[NewsOption] = []

@onready var _title: Label = %Title
@onready var _cards_box: HBoxContainer = %Cards
@onready var _reroll_button: Button = %RerollButton


## Arranca oculta. El botón de re-roll se conecta una sola vez.
func _ready() -> void:
	_reroll_button.pressed.connect(reroll)
	hide()


## Toda la elección, en orden. Usar con await: `await news_choice.run(buenas, malas)`.
## Pausa el juego, deja abrir las dos tarjetas en el orden que el jugador quiera,
## aplica lo elegido en cada una y al final despausa.
func run(good_pool: EffectPool, bad_pool: EffectPool) -> void:
	var pools := {Kind.GOOD: good_pool, Kind.BAD: bad_pool}
	_rerolls_used = 0
	var was_paused := get_tree().paused
	get_tree().paused = true
	show()
	while not pools.is_empty():
		_show_face_down(pools.keys())
		var kind: Kind = await kind_picked
		_open(kind, pools[kind])
		var option: NewsOption = await chosen
		option.apply()
		pools.erase(kind)
	hide()
	get_tree().paused = was_paused


## Da vuelta la tarjeta `kind` como si el jugador la hubiera tocado (lo usan las pruebas).
func pick_kind(kind: Kind) -> void:
	kind_picked.emit(kind)


## Elige `option` como si el jugador hubiera tocado su tarjeta (lo usan las pruebas).
func pick(option: NewsOption) -> void:
	chosen.emit(option)


## Las opciones que se están mostrando ahora.
func shown_options() -> Array[NewsOption]:
	return _shown_options


## Cambia las opciones de la tarjeta abierta por otras, si alcanza para pagarlo.
func reroll() -> void:
	if _open_pool == null:
		return
	if _rerolls_used >= free_rerolls:
		if not Economy.spend(reroll_earth_cost, reroll_water_cost):
			return
	_rerolls_used += 1
	_show_options(_open_pool.draw(options_per_card))


## El título y las tarjetas que faltan abrir, boca abajo.
func _show_face_down(kinds: Array) -> void:
	_open_pool = null
	_title.text = tr("NEWS_TITLE")
	_reroll_button.hide()
	_clear_cards()
	for kind in kinds:
		var key := "NEWS_GOOD_CARD" if kind == Kind.GOOD else "NEWS_BAD_CARD"
		var card := Button.new()
		card.text = tr(key)
		card.custom_minimum_size = Vector2(360, 220)
		card.focus_mode = Control.FOCUS_NONE
		card.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		card.add_theme_font_size_override("font_size", 28)
		var style := _card_style(GOOD_BORDER if kind == Kind.GOOD else BAD_BORDER)
		card.add_theme_stylebox_override("normal", style)
		card.add_theme_stylebox_override("hover", _card_style(Color.WHITE))
		card.add_theme_stylebox_override("pressed", style)
		# Diferida: la tarjeta se borra al abrirse, y no conviene borrarla mientras avisa su propio clic.
		card.pressed.connect(pick_kind.bind(kind), CONNECT_DEFERRED)
		_cards_box.add_child(card)


## Abre la tarjeta `kind`: el título pasa a ser su texto y se sortean sus opciones.
func _open(kind: Kind, pool: EffectPool) -> void:
	_open_pool = pool
	_title.text = tr("NEWS_GOOD_CARD" if kind == Kind.GOOD else "NEWS_BAD_CARD")
	_show_options(pool.draw(options_per_card))
	_reroll_button.show()


## Muestra `options` como tarjetas y actualiza el botón de re-roll (gratis o con costo).
func _show_options(options: Array[NewsOption]) -> void:
	_shown_options = options
	_clear_cards()
	for option in options:
		_cards_box.add_child(_make_card(option))
	if _rerolls_used < free_rerolls:
		_reroll_button.text = tr("NEWS_REROLL_FREE")
		_reroll_button.disabled = false
	else:
		_reroll_button.text = tr("NEWS_REROLL") % [reroll_earth_cost, reroll_water_cost]
		_reroll_button.disabled = not Economy.can_afford(reroll_earth_cost, reroll_water_cost)


## Saca todas las tarjetas que haya.
func _clear_cards() -> void:
	for child in _cards_box.get_children():
		_cards_box.remove_child(child)
		child.queue_free()


## Arma la tarjeta de una opción: nombre, efectos (verde = bueno, rojo = malo) y botón.
func _make_card(option: NewsOption) -> Control:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(420, 0)
	card.add_theme_stylebox_override("panel", _card_style(NEUTRAL_BORDER))

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
	button.pressed.connect(pick.bind(option), CONNECT_DEFERRED)
	column.add_child(button)
	return card


## Fondo de las tarjetas: el mismo marrón que la caja de diálogo, con borde de `border`.
func _card_style(border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = CARD_BACKGROUND
	style.border_color = border
	style.set_border_width_all(3)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(20)
	return style
