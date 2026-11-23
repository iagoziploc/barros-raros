class_name Lobito
extends Node2D
## El lobito de río. Cada `interval` segundos aparece un brillo del recurso más bajo
## (hasta `max_sparkles` a la vez). El lobito los va a buscar de a uno, vuelve a casa
## (el Cara de Barro) y entrega `amount`. Los brillos aparecen más rápido de lo que él
## alcanza a juntarlos: se acumulan hasta el máximo. Hasta que llegue su dibujo, es un punto.
## Con la ultimate aparecen lobitos ayudantes (`helper_of`), que juntan de los mismos brillos.

## Apareció un brillo nuevo. Los ayudantes lo escuchan para salir a buscar.
signal sparkle_spawned

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

## Lobito principal del que este es ayudante, o null si es el principal. Un ayudante no
## hace aparecer brillos: junta los del principal. Se asigna antes de agregarlo al árbol.
var helper_of: Lobito

# Brillos que están en el mapa esperando que los busquen (solo los usa el principal).
var _sparkles: Array[Sparkle] = []
# Brillo que el lobito trae en la boca de vuelta a casa, o null.
var _carrying: Sparkle
# true mientras está en un viaje (yendo o volviendo).
var _is_busy := false
# true si es un ayudante al que se le terminó el tiempo: termina el viaje y se va.
var _is_retiring := false

@onready var _timer: Timer = $RecoverTimer


## Se ubica en casa. El principal arranca el reloj de los brillos (se repite solo);
## el ayudante sale a buscar cada vez que el principal avisa que hay un brillo nuevo.
func _ready() -> void:
	if home:
		global_position = home.global_position
	if helper_of:
		helper_of.sparkle_spawned.connect(_on_sparkle_spawned)
		_fetch_all.call_deferred()
		return
	_timer.wait_time = interval
	_timer.timeout.connect(_on_recover_timer_timeout)
	_timer.start()


## Hace que los brillos aparezcan `multiplier` veces más rápido (1 = normal).
func set_sparkle_rate(multiplier: float) -> void:
	_timer.wait_time = interval / multiplier


## Para un ayudante: termina el viaje que esté haciendo, entrega y desaparece.
func retire() -> void:
	_is_retiring = true
	if not _is_busy:
		queue_free()


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


## Para un ayudante: el principal avisó que hay un brillo nuevo.
func _on_sparkle_spawned() -> void:
	if not _is_busy:
		_fetch_all()


## Agrega un brillo de `kind` en un punto al azar de su zona y avisa con `sparkle_spawned`.
func _spawn_sparkle(kind: Economy.Kind) -> void:
	var sparkle := Sparkle.new()
	sparkle.kind = kind
	sparkle.position = _random_point(earth_area if kind == Economy.Kind.EARTH else water_area)
	get_parent().add_child(sparkle)
	_sparkles.append(sparkle)
	sparkle_spawned.emit()


## La lista de brillos de la que junta: la propia, o la del principal si es ayudante.
func _pending() -> Array[Sparkle]:
	return helper_of._sparkles if helper_of else _sparkles


## Busca brillos de a uno hasta que no quede ninguno: va, lo agarra, vuelve y entrega.
## Cada await espera a que termine un tramo del viaje. Un ayudante retirado se va al terminar.
func _fetch_all() -> void:
	_is_busy = true
	while not _pending().is_empty() and not _is_retiring:
		var sparkle := _pick_next()
		# Se saca de la lista antes de salir: así otro lobito no va a buscar el mismo.
		_pending().erase(sparkle)
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
	if _is_retiring:
		queue_free()


## Elige el próximo brillo: el más cercano del recurso que esté más bajo ahora;
## si no hay de ese recurso, el más cercano de cualquiera.
func _pick_next() -> Sparkle:
	var lowest := Economy.Kind.EARTH if Economy.earth <= Economy.water else Economy.Kind.WATER
	var best: Sparkle = null
	for sparkle in _pending():
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
