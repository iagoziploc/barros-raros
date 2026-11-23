class_name MuteButton
extends Button
## Parlantito del HUD: muestra si hay sonido y, al tocarlo, lo apaga o prende (como la tecla M).
## Se dibuja con _draw(), sin imagen. Funciona aunque el juego esté en pausa.

const COLOR := Color(1, 1, 1, 0.9)
const OFF_COLOR := Color(1, 0.4, 0.3)
const BACKGROUND_COLOR := Color(0, 0, 0, 0.45)


## Se conecta al autoload Mute para redibujarse cuando cambia.
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	focus_mode = Control.FOCUS_NONE
	flat = true
	pressed.connect(Mute.toggle)
	Mute.changed.connect(_on_mute_changed)


## Responde a Mute.changed.
func _on_mute_changed(_is_muted: bool) -> void:
	queue_redraw()


## Un círculo oscuro (para que se vea sobre el mapa), el parlante y, con sonido, dos ondas;
## sin sonido, una cruz roja.
func _draw() -> void:
	var s := size.y / 32.0  # El dibujo está pensado en 32 px y se escala al tamaño del botón.
	draw_circle(Vector2(16, 16) * s, 16.0 * s, BACKGROUND_COLOR)
	var speaker := PackedVector2Array([
		Vector2(5, 12), Vector2(11, 12), Vector2(18, 5), Vector2(18, 27),
		Vector2(11, 20), Vector2(5, 20),
	])
	for i in speaker.size():
		speaker[i] *= s
	draw_colored_polygon(speaker, COLOR)
	if Mute.is_muted():
		draw_line(Vector2(21, 11) * s, Vector2(29, 21) * s, OFF_COLOR, 3.0 * s)
		draw_line(Vector2(29, 11) * s, Vector2(21, 21) * s, OFF_COLOR, 3.0 * s)
	else:
		draw_arc(Vector2(18, 16) * s, 5.0 * s, -PI / 3, PI / 3, 12, COLOR, 2.0 * s)
		draw_arc(Vector2(18, 16) * s, 10.0 * s, -PI / 3, PI / 3, 16, COLOR, 2.0 * s)
