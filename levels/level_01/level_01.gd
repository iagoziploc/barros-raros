extends Node2D

@onready var _spawner: WaveSpawner = $WaveSpawner


func _ready() -> void:
	_spawner.wave_cleared.connect(_on_wave_cleared)


func _on_wave_cleared(index: int) -> void:
	print("oleada %d superada" % (index + 1))
	print("te quedan %d de tierra y %d de agua" % [Economy.earth, Economy.water])

func _on_wave_started(index: int) -> void:
	$HUD.set_wave(index + 1)
