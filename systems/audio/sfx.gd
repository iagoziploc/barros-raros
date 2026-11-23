class_name Sfx
## Funciones para sonidos que tienen que seguir sonando aunque el nodo que los provoca
## desaparezca (un enemigo que muere, una unidad que se destruye).


## Reproduce `stream` en la posición de `source`, con un reproductor propio que se borra
## solo al terminar. Lo cuelga de la escena actual, así no se corta con queue_free().
static func play_detached(stream: AudioStream, source: Node2D, volume_db := 0.0) -> void:
	if stream == null or not source.is_inside_tree():
		return
	var player := AudioStreamPlayer2D.new()
	player.stream = stream
	player.bus = &"SFX"
	player.volume_db = volume_db
	var tree := source.get_tree()
	var parent: Node = tree.current_scene if tree.current_scene else tree.root
	parent.add_child(player)
	player.global_position = source.global_position
	player.finished.connect(player.queue_free)
	player.play()
