extends Line2D
## Dibuja en el juego la curva del Path2D padre (el Path2D solo se ve en el editor).


func _ready() -> void:
	var path := get_parent() as Path2D
	# get_baked_points() aproxima la curva con muchos segmentos rectos.
	points = path.curve.get_baked_points()
