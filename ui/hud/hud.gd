extends CanvasLayer
## Muestra tierra, agua, la cuenta regresiva de muerte súbita y el cartel de derrota.
## Solo lee Economy: no modifica nada.

@onready var _earth_label: Label = %EarthLabel
@onready var _water_label: Label = %WaterLabel
@onready var _wave_label: Label = %WaveLabel
@onready var _earth_alert: Label = %EarthAlert
@onready var _water_alert: Label = %WaterAlert
@onready var _defeat_label: Label = %DefeatLabel


func _ready() -> void:
	Economy.changed.connect(_on_economy_changed)
	Economy.defeated.connect(_on_economy_defeated)
	# Economy ya emitió `changed` antes de que existiera el HUD: se pinta el estado actual a mano.
	_on_economy_changed(Economy.earth, Economy.water)
	_defeat_label.text = tr("HUD_DEFEAT")
	_defeat_label.hide()


# La cuenta regresiva cambia en cada frame sin que Economy emita señales,
# por eso las alertas se actualizan acá y no en _on_economy_changed.
func _process(_delta: float) -> void:
	_update_alert(_earth_alert, Economy.Kind.EARTH, "HUD_SUDDEN_DEATH_EARTH")
	_update_alert(_water_alert, Economy.Kind.WATER, "HUD_SUDDEN_DEATH_WATER")


func _on_economy_changed(earth: int, water: int) -> void:
	_earth_label.text = tr("HUD_EARTH") % [earth, Economy.max_earth]
	_water_label.text = tr("HUD_WATER") % [water, Economy.max_water]


func _on_economy_defeated(_kind: Economy.Kind) -> void:
	_defeat_label.show()


func _update_alert(label: Label, kind: Economy.Kind, text_key: String) -> void:
	label.visible = Economy.is_in_sudden_death(kind)
	if label.visible:
		label.text = tr(text_key) % Economy.sudden_death_time_left(kind)

func set_wave(number: int) -> void:
	_wave_label.text = tr("HUD_WAVE") % number
