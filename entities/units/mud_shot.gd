class_name MudShot
extends Node2D
## Proyectil del mortero: vuela en arco de un punto a otro y avisa con `landed` al caer.
## No hace daño: eso lo decide quien lo tiró.
## Es `top_level`: se mueve en coordenadas globales aunque sea hijo de la unidad.

## Llegó al suelo en `point` (coordenadas globales). Se emite antes de borrarse.
signal landed(point: Vector2)

const COLOR := Color(0.42, 0.28, 0.16)
const RADIUS := 8.0

var _from := Vector2.ZERO
var _to := Vector2.ZERO
var _arc_height := 0.0
var _texture: Texture2D


## Arranca el vuelo de `from` a `to` en `flight_time` segundos, con una parábola de
## `arc_height` píxeles. Sin `texture` se dibuja un círculo.
func launch(from: Vector2, to: Vector2, flight_time: float, arc_height: float,
		texture: Texture2D = null) -> void:
	top_level = true
	_from = from
	_to = to
	_arc_height = arc_height
	_texture = texture
	_fly(0.0)
	var tween := create_tween()
	tween.tween_method(_fly, 0.0, 1.0, flight_time)
	tween.tween_callback(_land)


## Ubica el proyectil en el punto `t` del vuelo (0 = salida, 1 = llegada).
## La recta de `_from` a `_to`, levantada por una parábola que es 0 en las puntas
## y `_arc_height` en el medio: 4 * t * (1 - t) vale 1 cuando t = 0.5.
func _fly(t: float) -> void:
	global_position = _from.lerp(_to, t) + Vector2.UP * _arc_height * 4.0 * t * (1.0 - t)
	queue_redraw()


## Avisa dónde cayó y se borra.
func _land() -> void:
	landed.emit(_to)
	queue_free()


## La imagen del proyectil, o un círculo marrón si no hay.
func _draw() -> void:
	if _texture:
		draw_texture(_texture, -_texture.get_size() / 2.0)
	else:
		draw_circle(Vector2.ZERO, RADIUS, COLOR)
