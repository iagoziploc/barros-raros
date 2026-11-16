extends Node
## Economía del Cara de Barro: la tierra y el agua.
##
## Son la vida y la moneda al mismo tiempo ("defendés lo mismo que gastás"):
## - Los golems cuestan tierra y agua.
## - Los enemigos roban tierra o agua.
## - Si cualquiera de los dos llega a 0, perdés.
##
## Es un autoload: Godot crea una sola instancia al arrancar el juego,
## y cualquier script la puede usar escribiendo `Economy`.

enum Kind { EARTH, WATER }

## Se emite cada vez que cambia la tierra o el agua. La interfaz la escucha para actualizarse.
signal changed(earth: int, water: int)
## Se emite una sola vez, cuando un recurso llega a 0. Es la derrota del MVP.
signal depleted(kind: Kind)

# Valores de balance. Son provisorios: se ajustan jugando.
const STARTING_EARTH := 100
const STARTING_WATER := 100
## Parte del costo que devuelve un golem al caer (0.5 = la mitad).
const REFUND_RATIO := 0.5

var earth: int
var water: int

var _is_depleted := false


func _ready() -> void:
	reset()


## Vuelve a los valores iniciales. Se llama al empezar cada partida.
func reset() -> void:
	earth = STARTING_EARTH
	water = STARTING_WATER
	_is_depleted = false
	changed.emit(earth, water)


## ¿Alcanza para pagar este costo?
## No se puede gastar el último puñado: pagar nunca puede dejarte en 0,
## porque eso sería perder por tu propia mano.
func can_afford(earth_cost: int, water_cost: int) -> bool:
	return earth - earth_cost > 0 and water - water_cost > 0


## Intenta pagar un costo. Si no alcanza, no gasta nada y devuelve false.
func spend(earth_cost: int, water_cost: int) -> bool:
	if not can_afford(earth_cost, water_cost):
		return false
	_set_amounts(earth - earth_cost, water - water_cost)
	return true


## Suma recursos: devoluciones, ofrendas, regeneración.
func add(earth_amount: int, water_amount: int) -> void:
	_set_amounts(earth + earth_amount, water + water_amount)


## Un golem cayó: su barro vuelve a ser tierra y agua, y recuperás una parte.
func refund(earth_cost: int, water_cost: int) -> void:
	add(floori(earth_cost * REFUND_RATIO), floori(water_cost * REFUND_RATIO))


## Un enemigo roba un recurso. Nunca baja de 0.
func steal(kind: Kind, amount: int) -> void:
	match kind:
		Kind.EARTH:
			_set_amounts(earth - amount, water)
		Kind.WATER:
			_set_amounts(earth, water - amount)


# Único lugar donde cambian los valores. Así el aviso (changed)
# y el chequeo de derrota no se pueden olvidar en ninguna función.
func _set_amounts(new_earth: int, new_water: int) -> void:
	if _is_depleted:
		return  # La partida ya terminó: no cambia nada más.

	earth = maxi(new_earth, 0)
	water = maxi(new_water, 0)
	changed.emit(earth, water)

	if earth == 0:
		_is_depleted = true
		depleted.emit(Kind.EARTH)
	elif water == 0:
		_is_depleted = true
		depleted.emit(Kind.WATER)
