extends Node
## Autoload. Acumula los cambios de balance que eligen las noticias durante la partida
## y los aplica sobre los valores base de los .tres (que nunca se modifican).
## Las estadísticas de porcentaje se suman: +0.2 y luego -0.1 dan un multiplicador de 1.1.

enum Stat {
	UNIT_EARTH_COST,      ## Porcentaje: costo de tierra de las unidades.
	UNIT_WATER_COST,      ## Porcentaje: costo de agua de las unidades.
	UNIT_DAMAGE,          ## Porcentaje: daño de cada golpe.
	UNIT_ATTACK_SPEED,    ## Porcentaje: más = ataca más seguido.
	UNIT_BUILD_TIME,      ## Porcentaje: tiempo de construcción.
	UNIT_ARMOR_PIERCING,  ## Fijo: puntos de armadura enemiga que ignora cada golpe.
	ENEMY_COUNT,          ## Porcentaje: cantidad de enemigos de cada oleada.
	ENEMY_SPEED,          ## Porcentaje: velocidad de los enemigos.
	EARTH_NOW,            ## Instantáneo: suma o resta tierra en el momento.
	WATER_NOW,            ## Instantáneo: suma o resta agua en el momento.
}

## Estadísticas que se expresan en porcentaje (el resto son cantidades fijas).
const PERCENT_STATS := [
	Stat.UNIT_EARTH_COST, Stat.UNIT_WATER_COST, Stat.UNIT_DAMAGE, Stat.UNIT_ATTACK_SPEED,
	Stat.UNIT_BUILD_TIME, Stat.ENEMY_COUNT, Stat.ENEMY_SPEED,
]
## Estadísticas donde subir es bueno para el jugador (para pintar los efectos de verde o rojo).
const GOOD_WHEN_HIGHER := [
	Stat.UNIT_DAMAGE, Stat.UNIT_ATTACK_SPEED, Stat.UNIT_ARMOR_PIERCING,
	Stat.EARTH_NOW, Stat.WATER_NOW,
]
## Clave de localization/strings.csv con la descripción de cada estadística.
const TEXT_KEYS := {
	Stat.UNIT_EARTH_COST: "EFFECT_UNIT_EARTH_COST",
	Stat.UNIT_WATER_COST: "EFFECT_UNIT_WATER_COST",
	Stat.UNIT_DAMAGE: "EFFECT_UNIT_DAMAGE",
	Stat.UNIT_ATTACK_SPEED: "EFFECT_UNIT_ATTACK_SPEED",
	Stat.UNIT_BUILD_TIME: "EFFECT_UNIT_BUILD_TIME",
	Stat.UNIT_ARMOR_PIERCING: "EFFECT_UNIT_ARMOR_PIERCING",
	Stat.ENEMY_COUNT: "EFFECT_ENEMY_COUNT",
	Stat.ENEMY_SPEED: "EFFECT_ENEMY_SPEED",
	Stat.EARTH_NOW: "EFFECT_EARTH_NOW",
	Stat.WATER_NOW: "EFFECT_WATER_NOW",
}

## Cambió algún modificador. La barra de construcción la escucha para actualizar los costos.
signal changed

# Estadística -> valor acumulado. Ej.: { Stat.UNIT_DAMAGE: 0.25 }
var _values := {}


## Borra todos los modificadores. Se llama al empezar cada partida.
func reset() -> void:
	_values.clear()
	changed.emit()


## Aplica un efecto. Los instantáneos cambian la economía en el momento;
## el resto se acumula y vale desde ahora hasta que termine la partida.
func apply(stat: Stat, amount: float) -> void:
	match stat:
		Stat.EARTH_NOW:
			Economy.add(roundi(amount), 0)
		Stat.WATER_NOW:
			Economy.add(0, roundi(amount))
		_:
			_values[stat] = get_value(stat) + amount
			changed.emit()


## Valor acumulado de `stat` (0 si nunca se modificó).
func get_value(stat: Stat) -> float:
	return _values.get(stat, 0.0)


## 1 + el porcentaje acumulado, con un piso de 0.1 para que nada llegue a 0 o a negativo.
func multiplier(stat: Stat) -> float:
	return maxf(1.0 + get_value(stat), 0.1)


## Costo de tierra de `data` con los modificadores aplicados.
func earth_cost(data: UnitData) -> int:
	return roundi(data.earth_cost * multiplier(Stat.UNIT_EARTH_COST))


## Costo de agua de `data` con los modificadores aplicados.
func water_cost(data: UnitData) -> int:
	return roundi(data.water_cost * multiplier(Stat.UNIT_WATER_COST))


## Texto de un efecto para mostrarle al jugador, por ejemplo "Costo de agua: +20%".
func describe(stat: Stat, amount: float) -> String:
	var value := "%+d%%" % roundi(amount * 100) if stat in PERCENT_STATS else "%+d" % roundi(amount)
	return tr(TEXT_KEYS[stat]) % value


## true si este efecto beneficia al jugador.
func is_good(stat: Stat, amount: float) -> bool:
	return (amount > 0) == (stat in GOOD_WHEN_HIGHER)
