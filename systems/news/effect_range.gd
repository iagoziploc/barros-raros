class_name EffectRange
extends Resource
## Una posibilidad de buena o mala noticia: qué estadística cambia y entre qué valores.
## Al sortearla (roll) sale un valor al azar entre `min_amount` y `max_amount`.

## Clave de localization/strings.csv con su nombre de fantasía.
@export var name_key := ""
@export var stat: Modifiers.Stat = Modifiers.Stat.UNIT_DAMAGE
## Valores posibles. Para porcentajes, 0.15 = +15%; para el resto, la cantidad (2, 20, -10).
@export var min_amount := 0.15
@export var max_amount := 0.25


## Sortea el valor y arma la opción para mostrar en una tarjeta. Los porcentajes se redondean
## a 1% y las cantidades a enteros, así el número de la tarjeta es exactamente el que se aplica.
func roll() -> NewsOption:
	var amount := randf_range(min_amount, max_amount)
	if stat in Modifiers.PERCENT_STATS:
		amount = snappedf(amount, 0.01)
	else:
		amount = roundf(amount)
	var effect := NewsEffect.new()
	effect.stat = stat
	effect.amount = amount
	var option := NewsOption.new()
	option.title_key = name_key
	option.effects.append(effect)
	return option
