extends Node
## El lobito de río: cada `interval` segundos devuelve `amount` del recurso más bajo.

## Segundos entre una ayuda y la siguiente.
@export var interval := 4.0
## Cuánto devuelve cada vez.
@export var amount := 2
@onready var _timer: Timer = $RecoverTimer


## Configura el reloj y lo arranca.
func _ready() -> void:
	_timer.wait_time = interval
	_timer.timeout.connect(_on_recover_timer_timeout)
	_timer.start()


## Devuelve `amount` del recurso que esté más bajo.
func _on_recover_timer_timeout() -> void:
	if (Economy.earth <= Economy.water):
		Economy.add(amount, 0)
	else:
		Economy.add(0, amount)
