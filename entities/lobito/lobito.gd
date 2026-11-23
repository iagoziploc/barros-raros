extends Node2D
## El lobito de río. Cada `interval` segundos aparece un brillo del recurso más bajo:
## el lobito va a buscarlo, vuelve a casa (el Cara de Barro) y lo entrega (`amount`).
## Mientras va y vuelve el reloj está parado, así que cuanto más lejos el brillo,
## más tarda la siguiente ayuda. Hasta que llegue su dibujo, es un punto.

## Segundos entre una entrega y el próximo brillo.
@export var interval := 4.0
## Cuánto devuelve cada vez.
@export var amount := 2
## Velocidad en píxeles por segundo.
@export var speed := 140.0
## Adónde vuelve a entregar. Vacío = donde empieza.
@export var home: Node2D
## Zona donde pueden aparecer los brillos de tierra.
@export var earth_area := Rect2(600, 260, 600, 300)
## Zona donde pueden aparecer los brillos de agua (el río).
@export var water_area := Rect2(450, 615, 800, 40)

const COLOR := Color(0.35, 0.22, 0.12)
const OUTLINE_COLOR := Color(0.95, 0.85, 0.65)

# Brillo que el lobito trae en la boca de vuelta a casa, o null.
var _carrying: Sparkle

@onready var _timer: Timer = $RecoverTimer


## Se ubica en casa, configura el reloj y lo arranca.
func _ready() -> void:
	if home:
		global_position = home.global_position
	_timer.wait_time = interval
	_timer.one_shot = true
	_timer.timeout.connect(_on_recover_timer_timeout)
	_timer.start()


## Hace aparecer un brillo del recurso más bajo y sale a buscarlo.
func _on_recover_timer_timeout() -> void:
	if (Economy.earth <= Economy.water):
		_fetch(Economy.Kind.EARTH)
	else:
		_fetch(Economy.Kind.WATER)


## El viaje completo: aparece el brillo, el lobito va, lo agarra, vuelve, entrega
## y recién ahí vuelve a arrancar el reloj. Cada await espera a que termine un tramo.
func _fetch(kind: Economy.Kind) -> void:
	var sparkle := Sparkle.new()
	sparkle.kind = kind
	sparkle.position = _random_point(earth_area if kind == Economy.Kind.EARTH else water_area)
	get_parent().add_child(sparkle)

	await _walk_to(sparkle.global_position)
	_carrying = sparkle
	sparkle.hide()
	queue_redraw()

	await _walk_to(home.global_position if home else global_position)
	_carrying = null
	sparkle.queue_free()
	queue_redraw()
	if kind == Economy.Kind.EARTH:
		Economy.add(amount, 0)
	else:
		Economy.add(0, amount)
	_timer.start()


## Camina en línea recta hasta `target` a `speed`. Usar con await.
## El tween se pausa con el juego, así que en los diálogos el lobito se queda quieto.
func _walk_to(target: Vector2) -> void:
	var duration := global_position.distance_to(target) / speed
	var tween := create_tween()
	tween.tween_property(self, "global_position", target, duration)
	await tween.finished


## Un punto al azar dentro de `area`.
func _random_point(area: Rect2) -> Vector2:
	return area.position + Vector2(randf() * area.size.x, randf() * area.size.y)


## El punto del lobito y, si trae algo, el brillo en la boca.
func _draw() -> void:
	draw_circle(Vector2.ZERO, 9.0, OUTLINE_COLOR)
	draw_circle(Vector2.ZERO, 7.0, COLOR)
	if _carrying:
		var color := Sparkle.EARTH_COLOR if _carrying.kind == Economy.Kind.EARTH else Sparkle.WATER_COLOR
		draw_circle(Vector2(0, -11), 4.0, color)
