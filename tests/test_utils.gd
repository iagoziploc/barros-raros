class_name TestUtils
## Funciones compartidas por las pruebas.


## Apaga todos los sonidos con autoplay del nodo `Sound` del nivel. Llamar antes de add_child:
## si suenan al cerrar Godot, avisa que la reproducción quedó sin liberar.
static func silence(level: Node) -> void:
	for player in level.get_node("Sound").get_children():
		if player is AudioStreamPlayer:
			player.autoplay = false
