extends CanvasLayer
## Muestra tierra, agua, oleada, la cuenta regresiva de muerte súbita, la barra de la ultimate,
## el cartel de unidad nueva y un cartel central (derrota o victoria).
## Solo lee Economy: no modifica nada. El botón de la ultimate avisa con `ultimate_pressed`.

## Se tocó el botón de la ultimate.
signal ultimate_pressed

const ULTIMATE_READY_COLOR := Color(1.0, 0.85, 0.4)

@onready var _earth_label: Label = %EarthLabel
@onready var _water_label: Label = %WaterLabel
@onready var _wave_label: Label = %WaveLabel
@onready var _earth_alert: Label = %EarthAlert
@onready var _water_alert: Label = %WaterAlert
@onready var _message_label: Label = %MessageLabel
@onready var _retry_label: Label = %RetryLabel
@onready var _unlock_label: Label = %UnlockLabel
@onready var _ultimate_bar: ProgressBar = %UltimateBar
@onready var _ultimate_button: Button = %UltimateButton

# Tween que hace latir el botón de la ultimate cuando está lista, o null.
var _ultimate_pulse: Tween


## Escucha a Economy y pinta el estado actual.
func _ready() -> void:
	Economy.changed.connect(_on_economy_changed)
	Economy.defeated.connect(_on_economy_defeated)
	# Economy ya emitió `changed` antes de que existiera el HUD: se pinta el estado actual a mano.
	_on_economy_changed(Economy.earth, Economy.water)
	_message_label.hide()
	_retry_label.hide()
	_unlock_label.hide()
	_wave_label.hide()  # Hasta que arranque la primera oleada.
	_retry_label.text = tr("HUD_RETRY")
	_ultimate_button.text = tr("HUD_ULTIMATE")
	_ultimate_button.pressed.connect(ultimate_pressed.emit)
	set_ultimate(0.0, false, false)


## Actualiza las alertas de muerte súbita. Se hace en cada frame porque
## la cuenta regresiva cambia sin que Economy emita señales.
func _process(_delta: float) -> void:
	_update_alert(_earth_alert, Economy.Kind.EARTH, "HUD_SUDDEN_DEATH_EARTH")
	_update_alert(_water_alert, Economy.Kind.WATER, "HUD_SUDDEN_DEATH_WATER")


## Muestra el número de oleada (empieza en 1).
func set_wave(number: int) -> void:
	_wave_label.text = tr("HUD_WAVE") % number
	_wave_label.show()


## Pinta la ultimate: `fraction` de 0 a 1 (carga, o tiempo que le queda si está activa).
## Lista = el botón se habilita y late; activa = la barra se vacía mientras dura.
func set_ultimate(fraction: float, is_ready: bool, is_active: bool) -> void:
	_ultimate_bar.value = fraction
	_ultimate_button.disabled = not is_ready
	if is_ready and _ultimate_pulse == null:
		_ultimate_pulse = create_tween().set_loops()
		_ultimate_pulse.tween_property(_ultimate_button, "modulate", ULTIMATE_READY_COLOR, 0.4)
		_ultimate_pulse.tween_property(_ultimate_button, "modulate", Color.WHITE, 0.4)
	elif not is_ready and _ultimate_pulse:
		_ultimate_pulse.kill()
		_ultimate_pulse = null
		_ultimate_button.modulate = Color.WHITE
	_ultimate_bar.modulate = ULTIMATE_READY_COLOR if is_active else Color.WHITE


## Muestra el cartel de unidad nueva un segundo y medio y lo desvanece.
func show_unit_unlocked(data: UnitData) -> void:
	_unlock_label.text = tr("UNIT_UNLOCKED") % tr(data.name_key)
	_unlock_label.modulate.a = 1.0
	_unlock_label.show()
	var tween := create_tween()
	tween.tween_interval(1.5)
	tween.tween_property(_unlock_label, "modulate:a", 0.0, 0.8)


## Muestra el cartel de victoria.
func show_victory() -> void:
	_show_message("HUD_VICTORY")


## Actualiza las etiquetas de tierra y agua.
func _on_economy_changed(earth: int, water: int) -> void:
	_earth_label.text = tr("HUD_EARTH") % [earth, Economy.max_earth]
	_water_label.text = tr("HUD_WATER") % [water, Economy.max_water]


## Muestra el cartel de derrota y cómo reintentar.
func _on_economy_defeated(_kind: Economy.Kind) -> void:
	_show_message("HUD_DEFEAT")
	_retry_label.show()


## Muestra el cartel central con el texto de `text_key`.
func _show_message(text_key: String) -> void:
	_message_label.text = tr(text_key)
	_message_label.show()


## Muestra la alerta de `kind` con los segundos restantes, o la oculta.
func _update_alert(label: Label, kind: Economy.Kind, text_key: String) -> void:
	label.visible = Economy.is_in_sudden_death(kind)
	if label.visible:
		label.text = tr(text_key) % Economy.sudden_death_time_left(kind)
