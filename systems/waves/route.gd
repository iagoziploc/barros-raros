class_name Route
extends Path2D
## Un recorrido completo de una entrada al río. La curva se arma en _ready() pegando,
## en orden, las curvas de `segments` (tramos dibujados en el nivel). Así un tramo
## compartido se dibuja una sola vez y lo usan todas las rutas que pasan por él.

## Tramos que forman la ruta, en orden. Cada uno empieza donde termina el anterior.
@export var segments: Array[Path2D] = []
## Variante de esta ruta que pasa por el pozo, para los enemigos que roban tierra.
## Vacía = por esta entrada no se llega al pozo.
@export var dig_route: Route


## Arma la curva con los tramos (si tiene).
func _ready() -> void:
	if not segments.is_empty():
		curve = _join_segments()


## Devuelve una curva con los puntos de todos los tramos, en coordenadas de esta ruta.
## Si un tramo empieza en el mismo punto donde terminó el anterior, ese punto no se repite.
func _join_segments() -> Curve2D:
	var joined := Curve2D.new()
	for segment in segments:
		var part := segment.curve
		for i in part.point_count:
			var point := to_local(segment.to_global(part.get_point_position(i)))
			var last := joined.point_count - 1
			if i == 0 and last >= 0 and joined.get_point_position(last).distance_to(point) < 1.0:
				joined.set_point_out(last, part.get_point_out(i))
				continue
			joined.add_point(point, part.get_point_in(i), part.get_point_out(i))
	return joined
