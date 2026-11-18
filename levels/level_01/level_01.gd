extends Node2D

@onready var _spawner: WaveSpawner = $WaveSpawner


func _ready() -> void:
	_spawner.wave_cleared.connect(_on_wave_cleared)
	pass


func _on_wave_cleared(index: int) -> void:
	print("oleada %d superada" % (index + 1))
	print("te quedan %d de tierra y %d de agua" % [Economy.earth, Economy.water])
	pass
