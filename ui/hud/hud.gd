extends CanvasLayer
## Muestra tierra, agua, oleada, la cuenta regresiva de muerte súbita
## y un cartel central (derrota o victoria).
## Solo lee Economy: no modifica nada.

@onready var _earth_label: Label = %EarthLabel
@onready var _water_label: Label = %WaterLabel
@onready var _wave_label: Label = %WaveLabel
@onready var _earth_alert: Label = %EarthAlert
@onready var _water_alert: Label = %WaterAlert
@onready var _message_label: Label = %MessageLabel


## Escucha a Economy y pinta el estado actual.
func _ready() -> void:
	Economy.changed.connect(_on_economy_changed)
	Economy.defeated.connect(_on_economy_defeated)
	# Economy ya emitió `changed` antes de que existiera el HUD: se pinta el estado actual a mano.
	_on_economy_changed(Economy.earth, Economy.water)
	_message_label.hide()
	_wave_label.hide()  # Hasta que arranque la primera oleada.


## Actualiza las alertas de muerte súbita. Se hace en cada frame porque
## la cuenta regresiva cambia sin que Economy emita señales.
func _process(_delta: float) -> void:
	_update_alert(_earth_alert, Economy.Kind.EARTH, "HUD_SUDDEN_DEATH_EARTH")
	_update_alert(_water_alert, Economy.Kind.WATER, "HUD_SUDDEN_DEATH_WATER")


## Muestra el número de oleada (empieza en 1).
func set_wave(number: int) -> void:
	_wave_label.text = tr("HUD_WAVE") % number
	_wave_label.show()


## Muestra el cartel de victoria.
func show_victory() -> void:
	_show_message("HUD_VICTORY")


## Actualiza las etiquetas de tierra y agua.
func _on_economy_changed(earth: int, water: int) -> void:
	_earth_label.text = tr("HUD_EARTH") % [earth, Economy.max_earth]
	_water_label.text = tr("HUD_WATER") % [water, Economy.max_water]


## Muestra el cartel de derrota.
func _on_economy_defeated(_kind: Economy.Kind) -> void:
	_show_message("HUD_DEFEAT")


## Muestra el cartel central con el texto de `text_key`.
func _show_message(text_key: String) -> void:
	_message_label.text = tr(text_key)
	_message_label.show()


## Muestra la alerta de `kind` con los segundos restantes, o la oculta.
func _update_alert(label: Label, kind: Economy.Kind, text_key: String) -> void:
	label.visible = Economy.is_in_sudden_death(kind)
	if label.visible:
		label.text = tr(text_key) % Economy.sudden_death_time_left(kind)
