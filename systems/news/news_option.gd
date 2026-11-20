class_name NewsOption
extends Resource
## Una de las opciones que se eligen después de una noticia.

## Clave de localization/strings.csv con el título de la opción.
@export var title_key := ""
## Efectos que se aplican al elegirla. Lo normal es uno bueno y uno malo.
@export var effects: Array[NewsEffect] = []


## Aplica todos los efectos de la opción.
func apply() -> void:
	for effect in effects:
		Modifiers.apply(effect.stat, effect.amount)
