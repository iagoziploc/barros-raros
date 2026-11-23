class_name FloatingText
extends Label
## Un texto chico que aparece en el mapa (por ejemplo "+3"), sube, se desvanece y se borra solo.
## Se crea con FloatingText.spawn(): no necesita escena.

const RISE := 40.0
const DURATION := 0.9


## Crea el texto `text` de color `color` en `world_position`, como hijo de `parent`.
static func spawn(parent: Node, world_position: Vector2, text: String, color: Color) -> void:
	var label := FloatingText.new()
	label.text = text
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 6)
	label.add_theme_font_size_override("font_size", 22)
	label.z_index = 5
	parent.add_child(label)
	# Centrado en el punto: se corre la mitad de su ancho y su alto.
	label.global_position = world_position - label.get_minimum_size() / 2.0


## Sube y se desvanece a la vez; al terminar, se borra.
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tween := create_tween().set_parallel()
	tween.tween_property(self, "position:y", position.y - RISE, DURATION).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0.0, DURATION).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(queue_free)
