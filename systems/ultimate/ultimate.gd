class_name Ultimate
extends Node
## La ultimate: se carga con el `ultimate_charge` de cada enemigo que muere. Llena, se tira
## (botón del HUD o barra espaciadora) y durante `duration` segundos:
## salen `extra_lobitos` ayudantes, los brillos aparecen `sparkle_rate` veces más rápido
## y los recursos pueden pasar el máximo hasta `resource_bonus` (lo que sobra queda).

## Cambió la carga o el estado. `fraction` va de 0 a 1: la carga, o el tiempo que queda si
## está activa. Pensada para el HUD.
signal changed(fraction: float, is_ready: bool, is_active: bool)

## Carga necesaria para poder tirarla (la suma del `ultimate_charge` de los enemigos muertos).
@export var charge_needed := 15
## Segundos que dura.
@export var duration := 10.0
## Lobitos ayudantes que aparecen.
@export var extra_lobitos := 2
## Cuántas veces más rápido aparecen los brillos (2 = el doble).
@export var sparkle_rate := 2.0
## Cuánto se puede pasar del máximo de tierra y agua mientras dura.
@export var resource_bonus := 50
## El lobito principal: los ayudantes salen de su casa y juntan sus brillos.
@export var lobito: Lobito
## De dónde se entera de cada enemigo nuevo, para sumar carga cuando muere.
@export var spawner: WaveSpawner
@export var lobito_scene: PackedScene = preload("res://entities/lobito/lobito.tscn")

var charge := 0
# Segundos que le quedan; 0 = no está activa.
var _time_left := 0.0
var _helpers: Array[Lobito] = []


## Escucha a cada enemigo que aparece y avisa el estado inicial.
func _ready() -> void:
	if spawner:
		spawner.enemy_spawned.connect(_on_enemy_spawned)
	_emit_changed()


## Mientras está activa, descuenta el tiempo y la termina al llegar a 0.
func _process(delta: float) -> void:
	if not is_active():
		return
	_time_left -= delta
	if _time_left <= 0.0:
		_end()
	else:
		_emit_changed()


## Barra espaciadora: la tira.
func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key and key.pressed and not key.echo and key.keycode == KEY_SPACE:
		activate()
		get_viewport().set_input_as_handled()


## true si la carga está completa y no está activa.
func is_ready() -> bool:
	return charge >= charge_needed and not is_active()


## true mientras dura.
func is_active() -> bool:
	return _time_left > 0.0


## Al terminar una oleada: si está activa la termina, y la carga vuelve a 0.
func reset() -> void:
	if is_active():
		_end()
	charge = 0
	_emit_changed()


## Suma `amount` de carga, sin pasar de `charge_needed`. Mientras está activa no carga.
func add_charge(amount: int) -> void:
	if is_active():
		return
	charge = mini(charge + amount, charge_needed)
	_emit_changed()


## La tira, si está lista: ayudantes, brillos más rápidos y más lugar para recursos.
func activate() -> void:
	if not is_ready() or lobito == null:
		return
	charge = 0
	_time_left = duration
	Economy.set_bonus_max(resource_bonus)
	lobito.set_sparkle_rate(sparkle_rate)
	for i in extra_lobitos:
		var helper: Lobito = lobito_scene.instantiate()
		helper.helper_of = lobito
		helper.home = lobito.home
		# Los mismos números que el principal (los que se ajustaron en el nivel, no los de la escena).
		helper.amount = lobito.amount
		helper.speed = lobito.speed
		helper.pause_at_stops = lobito.pause_at_stops
		helper.modulate = Color(1.0, 0.9, 0.7)
		# Justo después del lobito en el árbol: así también pasa por detrás de los árboles.
		lobito.add_sibling(helper)
		_helpers.append(helper)
	_emit_changed()


## Se terminó: los ayudantes vuelven y se van, los brillos y el máximo vuelven a lo normal.
func _end() -> void:
	_time_left = 0.0
	Economy.set_bonus_max(0)
	lobito.set_sparkle_rate(1.0)
	for helper in _helpers:
		if is_instance_valid(helper):
			helper.retire()
	_helpers.clear()
	_emit_changed()


## Un enemigo nuevo: cuando muera (no cuando escape), suma su carga.
func _on_enemy_spawned(enemy: Enemy) -> void:
	enemy.died.connect(_on_enemy_died)


## Responde a Enemy.died.
func _on_enemy_died(enemy: Enemy) -> void:
	add_charge(enemy.data.ultimate_charge)


## Avisa con `changed`: la carga mientras se junta, o el tiempo que queda si está activa.
func _emit_changed() -> void:
	var fraction := _time_left / duration if is_active() else float(charge) / charge_needed
	changed.emit(fraction, is_ready(), is_active())
