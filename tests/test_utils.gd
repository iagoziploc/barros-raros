class_name TestUtils
## Funciones compartidas por las pruebas.


## Apaga todos los sonidos con autoplay del nodo `Sound` del nivel. Llamar antes de add_child:
## si suenan al cerrar Godot, avisa que la reproducción quedó sin liberar.
static func silence(level: Node) -> void:
	for player in level.get_node("Sound").get_children():
		if player is AudioStreamPlayer:
			player.autoplay = false


## Saca al lobito del nivel: suma recursos solo y desarma las cuentas de las pruebas.
## Llamar antes de add_child.
static func remove_lobito(level: Node) -> void:
	var lobito := level.get_node_or_null("Lobito")
	if lobito:
		level.remove_child(lobito)
		lobito.free()
