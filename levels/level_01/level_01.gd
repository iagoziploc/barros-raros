extends Node2D
## Conecta las piezas del nivel: oleadas, HUD, barra de construcción y unidades.
## Arranca la primera oleada en _ready(), después de conectar todas las señales.

## Segundos de pausa entre una oleada y la siguiente.
@export var time_between_waves := 5.0
## Si es false, el nivel no arranca solo (lo usan las pruebas).
@export var start_on_ready := true

@onready var _spawner: WaveSpawner = $WaveSpawner
@onready var _units: Node2D = $Units
@onready var _placer: UnitPlacer = $UnitPlacer
@onready var _hud := $HUD
@onready var _build_bar := $BuildBar


## Reinicia la economía, conecta las piezas y arranca la primera oleada.
func _ready() -> void:
	Economy.reset()
	_spawner.wave_started.connect(_on_wave_started)
	_spawner.wave_cleared.connect(_on_wave_cleared)
	_build_bar.unit_selected.connect(_placer.select)
	if start_on_ready:
		_spawner.start_wave(0)


## Actualiza el número de oleada en el HUD.
func _on_wave_started(index: int) -> void:
	_hud.set_wave(index + 1)


## Disuelve las unidades, y arranca la oleada siguiente o muestra la victoria.
func _on_wave_cleared(index: int) -> void:
	if Economy.is_defeated():
		return
	print("oleada %d superada" % (index + 1))
	print("te quedan %d de tierra y %d de agua" % [Economy.earth, Economy.water])

	# Las unidades que llegan al final de la oleada se disuelven y devuelven todo su costo.
	for unit: Unit in _units.get_children():
		unit.remove(true)

	if _spawner.has_more_waves():
		await get_tree().create_timer(time_between_waves).timeout
		_spawner.start_wave(index + 1)
	else:
		_hud.show_victory()
