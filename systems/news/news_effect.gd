class_name NewsEffect
extends Resource
## Un efecto de una opción de noticia: qué estadística cambia y cuánto.

@export var stat: Modifiers.Stat = Modifiers.Stat.UNIT_DAMAGE
## Para las estadísticas en porcentaje: 0.2 = +20%, -0.1 = -10%.
## Para penetración de armadura y recursos al instante: la cantidad (3 = +3).
@export var amount := 0.2
