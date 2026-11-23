class_name WaveData
extends Resource
## Una oleada: la lista de grupos de enemigos que la forman.

@export var entries: Array[WaveEntry] = []
## Segundos de respiro desde que arranca la oleada hasta que empiezan a contar los grupos
## (un grupo con Start Time 0 sale recién después de esta demora).
@export var start_delay := 1.0
## Unidades que se estrenan al empezar esta oleada: se suman a la barra de construcción.
@export var new_units: Array[UnitData] = []


## Devuelve todas las apariciones de la oleada ordenadas por tiempo:
## [{ "time": float, "enemy": EnemyData, "entrances": int }, ...]
## `count_multiplier` agranda o achica cada grupo (1.2 = 20% más enemigos, mismo intervalo).
func build_schedule(count_multiplier := 1.0) -> Array[Dictionary]:
	var schedule: Array[Dictionary] = []
	for entry in entries:
		for i in roundi(entry.count * count_multiplier):
			schedule.append({
				"time": entry.start_time + i * entry.interval,
				"enemy": entry.enemy,
				"entrances": entry.entrances,
			})
	schedule.sort_custom(func(a, b): return a.time < b.time)
	return schedule


## Suma la cantidad de enemigos de todos los grupos.
func total_enemies() -> int:
	var total := 0
	for entry in entries:
		total += entry.count
	return total
