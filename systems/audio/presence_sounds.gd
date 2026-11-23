class_name PresenceSounds
extends Node
## Hace sonar en loop el `presence_sound` de cada tipo de unidad mientras haya al menos una
## en el mapa (también mientras se construye). Aunque haya varias del mismo tipo, suena uno solo.

## Nodo donde están las unidades.
@export var units: Node

# Sonido -> AudioStreamPlayer que lo está reproduciendo.
var _players := {}


## Compara los sonidos que deberían sonar con los que suenan: prende los que faltan
## y apaga los que sobran.
func _process(_delta: float) -> void:
	var wanted := {}
	for unit: Unit in units.get_children():
		if unit.data.presence_sound and not unit.is_queued_for_deletion():
			wanted[unit.data.presence_sound] = unit.data.presence_volume_db
	for stream in wanted:
		if not _players.has(stream):
			_players[stream] = _start(stream, wanted[stream])
	for stream in _players.keys():
		if not wanted.has(stream):
			_players[stream].queue_free()
			_players.erase(stream)


## Crea un reproductor para `stream` que vuelve a empezar al terminar, y lo arranca.
func _start(stream: AudioStream, volume_db: float) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = volume_db
	player.bus = &"SFX"
	add_child(player)
	player.finished.connect(player.play)
	player.play()
	return player
