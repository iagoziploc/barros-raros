extends Node
## Autoload `Mute`: la tecla M prende y apaga todo el sonido del juego.
## Es un autoload para que funcione siempre: en pausa, en los diálogos y después de reiniciar.

## Cambió el estado: true = sin sonido.
signal changed(is_muted: bool)

const MASTER_BUS := 0


## Sigue recibiendo teclas aunque el juego esté en pausa.
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


## Tecla M: alterna el sonido.
func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key and key.pressed and not key.echo and key.keycode == KEY_M:
		toggle()


## Apaga el sonido si estaba prendido, y al revés.
func toggle() -> void:
	set_muted(not is_muted())


## true si el sonido está apagado.
func is_muted() -> bool:
	return AudioServer.is_bus_mute(MASTER_BUS)


## Apaga (true) o prende (false) el bus Master, por donde pasa todo el sonido.
func set_muted(muted: bool) -> void:
	AudioServer.set_bus_mute(MASTER_BUS, muted)
	changed.emit(muted)
