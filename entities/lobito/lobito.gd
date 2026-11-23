extends Node2D
## El lobito de río. Cada `interval` segundos aparece un brillo del recurso más bajo
## (hasta `max_sparkles` a la vez). El lobito los va a buscar de a uno, vuelve a casa
## (el Cara de Barro) y entrega `amount`. Los brillos aparecen más rápido de lo que él
## alcanza a juntarlos: se acumulan hasta el máximo. Hasta que llegue su dibujo, es un punto.

## Segundos entre un brillo y el siguiente.
@export var interval := 2.5
## Cuántos brillos puede haber en el mapa a la vez. Llegado el máximo, no aparecen más.
@export var max_sparkles := 5
## Cuánto devuelve cada brillo.
@export var amount := 2
## Velocidad en píxeles por segundo.
@export var speed := 140.0
## Adónde vuelve a entregar. Vacío = donde empieza.
@export var home: Node2D
## Zona donde pueden aparecer los brillos de tierra.
@export var earth_area := Rect2(100, 220, 1080, 360)
## Zona donde pueden aparecer los brillos de agua (el río).
@export var water_area := Rect2(20, 615, 1240, 40)

const COLOR := Color(0.35, 0.22, 0.12)
const OUTLINE_COLOR := Color(0.95, 0.85, 0.65)

# Brillos que están en el mapa esperando que los busquen.
var _sparkles: Array[Sparkle] = []
# Brillo que el lobito trae en la boca de vuelta a casa, o null.
var _carrying: Sparkle
# true mientras está en un viaje (yendo o volviendo).
var _is_busy := false

@onready var _timer: Timer = $RecoverTimer


## Se ubica en casa, configura el reloj y lo arranca. El reloj se repite solo.
func _ready() -> void:
	if home:
		global_position = home.global_position
	_timer.wait_time = interval
	_timer.timeout.connect(_on_recover_timer_timeout)
	_timer.start()


## Hace aparecer un brillo del recurso más bajo (si no se llegó al máximo)
## y, si el lobito está en casa sin hacer nada, sale a buscar.
func _on_recover_timer_timeout() -> void:
	if _sparkles.size() < max_sparkles:
		if (Economy.earth <= Economy.water):
			_spawn_sparkle(Economy.Kind.EARTH)
		else:
			_spawn_sparkle(Economy.Kind.WATER)
	if not _is_busy:
		_fetch_all()


## Agrega un brillo de `kind` en un punto al azar de su zona.
func _spawn_sparkle(kind: Economy.Kind) -> void:
	var sparkle := Sparkle.new()
	sparkle.kind = kind
	sparkle.position = _random_point(earth_area if kind == Economy.Kind.EARTH else water_area)
	get_parent().add_child(sparkle)
	_sparkles.append(sparkle)


## Busca brillos de a uno hasta que no quede ninguno: va, lo agarra, vuelve y entrega.
## Cada await espera a que termine un tramo del viaje.
func _fetch_all() -> void:
	_is_busy = true
	while not _sparkles.is_empty():
		var sparkle := _pick_next()
		_sparkles.erase(sparkle)
		await _walk_to(sparkle.global_position)
		_carrying = sparkle
		sparkle.hide()
		queue_redraw()

		await _walk_to(home.global_position if home else global_position)
		_carrying = null
		sparkle.queue_free()
		queue_redraw()
		if sparkle.kind == Economy.Kind.EARTH:
			Economy.add(amount, 0)
		else:
			Economy.add(0, amount)
	_is_busy = false


## Elige el próximo brillo: el más cercano del recurso que esté más bajo ahora;
## si no hay de ese recurso, el más cercano de cualquiera.
func _pick_next() -> Sparkle:
	var lowest := Economy.Kind.EARTH if Economy.earth <= Economy.water else Economy.Kind.WATER
	var best: Sparkle = null
	for sparkle in _sparkles:
		if best == null or _is_better(sparkle, best, lowest):
			best = sparkle
	return best


## true si `a` conviene más que `b`: primero el del recurso `lowest`, después el más cercano.
func _is_better(a: Sparkle, b: Sparkle, lowest: Economy.Kind) -> bool:
	if (a.kind == lowest) != (b.kind == lowest):
		return a.kind == lowest
	return global_position.distance_to(a.global_position) < global_position.distance_to(b.global_position)


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
