class_name EffectPool
extends Resource
## Lista de posibilidades (las buenas noticias o las malas). Cada vez se sortean algunas.

@export var entries: Array[EffectRange] = []


## Sortea `count` posibilidades distintas, cada una con su valor al azar.
func draw(count: int) -> Array[NewsOption]:
	var shuffled := entries.duplicate()
	shuffled.shuffle()
	var options: Array[NewsOption] = []
	for entry: EffectRange in shuffled.slice(0, count):
		options.append(entry.roll())
	return options
