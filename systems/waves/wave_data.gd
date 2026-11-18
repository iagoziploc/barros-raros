class_name WaveData
extends Resource
## Una oleada: la lista de grupos de enemigos que la forman.

@export var entries: Array[WaveEntry] = []


## Devuelve todas las apariciones de la oleada ordenadas por tiempo:
## [{ "time": float, "enemy": EnemyData }, ...]
func build_schedule() -> Array[Dictionary]:
	var schedule: Array[Dictionary] = []
	for entry in entries:
		for i in entry.count:
			schedule.append({
				"time": entry.start_time + i * entry.interval,
				"enemy": entry.enemy,
			})
	schedule.sort_custom(func(a, b): return a.time < b.time)
	return schedule


func total_enemies() -> int:
	var total := 0
	for entry in entries:
		total += entry.count
	return total
