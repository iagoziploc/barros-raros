class_name Sparkle
extends Node2D
## Brillo de un recurso que aparece en el mapa para que el lobito lo vaya a buscar.
## Es solo visual: un círculo que late, del color del recurso.

const EARTH_COLOR := Color(0.95, 0.75, 0.3)
const WATER_COLOR := Color(0.55, 0.9, 1.0)
const RADIUS := 7.0

## Qué recurso es. Define el color.
var kind := Economy.Kind.EARTH


## El color de un recurso: dorado la tierra, celeste el agua. Lo usa también el lobito.
static func color_for(resource: Economy.Kind) -> Color:
	return EARTH_COLOR if resource == Economy.Kind.EARTH else WATER_COLOR


## Arranca a latir (se agranda y se achica sin parar).
func _ready() -> void:
	var tween := create_tween().set_loops()
	tween.tween_property(self, "scale", Vector2.ONE * 1.5, 0.4)
	tween.tween_property(self, "scale", Vector2.ONE, 0.4)


## Un círculo con un halo, del color del recurso.
func _draw() -> void:
	var color := color_for(kind)
	draw_circle(Vector2.ZERO, RADIUS * 1.8, Color(color, 0.3))
	draw_circle(Vector2.ZERO, RADIUS, color)
