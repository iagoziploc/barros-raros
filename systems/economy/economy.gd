extends Node
## Autoload. Guarda la tierra y el agua del jugador y maneja la muerte súbita.
## Los valores de balance se leen de `config` (res://data/economy.tres).

enum Kind { EARTH, WATER }

## Cambió la tierra o el agua.
signal changed(earth: int, water: int)
## Un recurso llegó a 0 y empezó su cuenta regresiva.
signal sudden_death_started(kind: Kind)
## El recurso volvió a ser mayor que 0 antes de que terminara la cuenta regresiva.
signal sudden_death_ended(kind: Kind)
## Terminó la cuenta regresiva de algún recurso. Se emite una sola vez por partida.
signal defeated(kind: Kind)

var config: EconomyConfig = preload("res://data/economy.tres")

var earth: int
var water: int
## Son variables, no constantes, para poder subirlas temporalmente.
var max_earth: int
var max_water: int
## Cuánto se puede pasar del máximo ahora mismo (lo usa la ultimate). 0 = nada.
## Lo que quede por encima del máximo cuando vuelve a 0 se conserva hasta que se gaste.
var bonus_max := 0

# Recursos en muerte súbita -> segundos que les quedan. Ej.: { Kind.WATER: 3.2 }
var _sudden_death := {}
var _is_defeated := false


## Carga los valores iniciales.
func _ready() -> void:
	reset()


## Descuenta el tiempo de cada muerte súbita activa y emite `defeated` si alguna llega a 0.
func _process(delta: float) -> void:
	if _is_defeated or _sudden_death.is_empty():
		return

	# keys() devuelve una copia, así que se puede modificar el diccionario dentro del for.
	for kind in _sudden_death.keys():
		_sudden_death[kind] -= delta
		if _sudden_death[kind] <= 0.0:
			_is_defeated = true
			_sudden_death.clear()
			defeated.emit(kind)
			return


## Cambia cuánto se puede pasar del máximo y avisa con `changed` (el HUD muestra el máximo nuevo).
func set_bonus_max(amount: int) -> void:
	bonus_max = amount
	changed.emit(earth, water)


## Vuelve a los valores iniciales de `config`.
func reset() -> void:
	earth = config.starting_earth
	water = config.starting_water
	max_earth = config.max_earth
	max_water = config.max_water
	bonus_max = 0
	_sudden_death.clear()
	_is_defeated = false
	changed.emit(earth, water)


## Devuelve true si hay tierra y agua suficientes. Se permite quedar en 0.
## Después de la derrota siempre devuelve false.
func can_afford(earth_cost: int, water_cost: int) -> bool:
	return not _is_defeated and earth >= earth_cost and water >= water_cost


## true después de que terminó la cuenta regresiva de algún recurso.
func is_defeated() -> bool:
	return _is_defeated


## Descuenta el costo y devuelve true. Si no alcanza, no descuenta nada y devuelve false.
func spend(earth_cost: int, water_cost: int) -> bool:
	if not can_afford(earth_cost, water_cost):
		return false
	_set_amounts(earth - earth_cost, water - water_cost)
	return true


## Suma recursos sin pasar de max_earth / max_water (más `bonus_max`).
func add(earth_amount: int, water_amount: int) -> void:
	_set_amounts(earth + earth_amount, water + water_amount)


## Devuelve el costo multiplicado por config.refund_ratio_destroyed.
func refund_destroyed(earth_cost: int, water_cost: int) -> void:
	_refund(earth_cost, water_cost, config.refund_ratio_destroyed)


## Devuelve el costo multiplicado por config.refund_ratio_survived.
func refund_survived(earth_cost: int, water_cost: int) -> void:
	_refund(earth_cost, water_cost, config.refund_ratio_survived)


## Resta `amount` del recurso indicado, sin bajar de 0.
func steal(kind: Kind, amount: int) -> void:
	match kind:
		Kind.EARTH:
			_set_amounts(earth - amount, water)
		Kind.WATER:
			_set_amounts(earth, water - amount)


## true si `kind` está en 0 con la cuenta regresiva corriendo.
func is_in_sudden_death(kind: Kind) -> bool:
	return _sudden_death.has(kind)


## Segundos que le quedan a la cuenta regresiva de `kind`, o 0 si no está activa.
func sudden_death_time_left(kind: Kind) -> float:
	return _sudden_death.get(kind, 0.0)


## Suma el costo multiplicado por `ratio`, redondeando hacia abajo.
func _refund(earth_cost: int, water_cost: int, ratio: float) -> void:
	add(floori(earth_cost * ratio), floori(water_cost * ratio))


## Único lugar donde cambian tierra y agua: limita entre 0 y el máximo,
## emite `changed` y actualiza la muerte súbita.
func _set_amounts(new_earth: int, new_water: int) -> void:
	if _is_defeated:
		return

	earth = _limit(new_earth, earth, max_earth + bonus_max)
	water = _limit(new_water, water, max_water + bonus_max)
	changed.emit(earth, water)

	_update_sudden_death(Kind.EARTH, earth)
	_update_sudden_death(Kind.WATER, water)


## El valor nuevo de un recurso, entre 0 y `cap`. Si ya estaba por encima de `cap`
## (sobró de una ultimate), puede bajar pero no subir: lo que sobró se conserva.
func _limit(new_amount: int, old_amount: int, cap: int) -> int:
	if new_amount <= cap:
		return maxi(new_amount, 0)
	return maxi(cap, mini(new_amount, old_amount))


## Arranca la cuenta regresiva al llegar a 0 y la cancela al salir de 0.
func _update_sudden_death(kind: Kind, amount: int) -> void:
	var is_active := _sudden_death.has(kind)
	if amount == 0 and not is_active:
		_sudden_death[kind] = config.sudden_death_seconds
		sudden_death_started.emit(kind)
	elif amount > 0 and is_active:
		_sudden_death.erase(kind)
		sudden_death_ended.emit(kind)
