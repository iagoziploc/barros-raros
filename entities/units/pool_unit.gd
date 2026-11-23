class_name PoolUnit
extends Unit
## Unidad de agua: una pileta de barro sobre el camino. Atrapa a los enemigos que la pisan,
## hasta `data.pool_capacity` a la vez, y tarda `data.pool_consume_time` en hundir a cada uno.
## Llena, deja pasar; cuando se hunde uno, se libera un lugar.
## No usa el cooldown ni los golpes de Unit: reemplaza _act().

const MUD_COLOR := Color(0.36, 0.25, 0.15, 0.85)
const MUD_EDGE_COLOR := Color(0.25, 0.17, 0.1)

# Enemigos que se está hundiendo ahora.
var _trapped: Array[Enemy] = []


## Atrapa a los enemigos que están en el charco mientras haya lugar, primero a los más avanzados.
func _act(_delta: float) -> void:
	var enemies := _enemies_in_range()
	enemies.sort_custom(func(a: Enemy, b: Enemy): return a.progress > b.progress)
	for enemy in enemies:
		if _trapped.size() >= data.pool_capacity:
			return
		if enemy.is_trapped():
			continue
		_trap(enemy)


## Hunde a `enemy` y lo cuenta hasta que muera.
func _trap(enemy: Enemy) -> void:
	_trapped.append(enemy)
	enemy.died.connect(_on_trapped_enemy_died)
	enemy.trap(data.pool_consume_time * enemy.data.sink_time_multiplier)
	_play_sound(_hit_sound, data.hit_sound, data.hit_volume_db)


## Se hundió (o lo mató otra unidad antes): libera su lugar.
func _on_trapped_enemy_died(enemy: Enemy) -> void:
	_trapped.erase(enemy)


## El charco, debajo de todo lo que dibuja Unit.
func _draw() -> void:
	draw_circle(Vector2.ZERO, data.attack_range, MUD_COLOR)
	draw_arc(Vector2.ZERO, data.attack_range, 0.0, TAU, 48, MUD_EDGE_COLOR, 3.0)
	super._draw()
