class_name Unit
extends Node2D
## Se construye durante `data.build_time` segundos (semitransparente, con barra de progreso
## y sin atacar). Al terminar suena y, desde ahí, golpea cada `data.attack_interval`
## segundos al enemigo de su rango que está más avanzado en el camino.

## Terminó de construirse.
signal built(unit: Unit)

const BUILDING_COLOR := Color(1.0, 1.0, 1.0, 0.45)

@export var data: UnitData

var is_built := false

# Segundos que faltan para terminar de construirse.
var _build_time_left := 0.0
# Segundos que faltan para poder volver a golpear.
var _cooldown := 0.0

@onready var _sprite: Sprite2D = $Sprite
@onready var _range: Area2D = $Range
@onready var _range_shape: CollisionShape2D = $Range/Shape
@onready var _spawn_sound: AudioStreamPlayer2D = $SpawnSound
@onready var _build_progress: ProgressBar = $BuildProgress


## Aplica imagen y rango desde `data` y arranca la construcción.
func _ready() -> void:
	_sprite.texture = data.texture
	_sprite.scale = Vector2.ONE * data.sprite_scale

	# Una forma nueva por unidad: si la compartieran, cambiar el radio de una las cambiaría a todas.
	var circle := CircleShape2D.new()
	circle.radius = data.attack_range
	_range_shape.shape = circle

	_build_time_left = data.build_time
	if _build_time_left <= 0.0:
		_finish_building()
	else:
		_sprite.modulate = BUILDING_COLOR
		_build_progress.show()


## Mientras se construye, avanza la barra. Construida, golpea cuando el cooldown llega a 0.
func _process(delta: float) -> void:
	if not is_built:
		_build_time_left -= delta
		_build_progress.value = 1.0 - _build_time_left / data.build_time
		if _build_time_left <= 0.0:
			_finish_building()
		return

	_cooldown = maxf(_cooldown - delta, 0.0)
	if _cooldown > 0.0:
		return

	var target := _find_target()
	if target == null:
		return

	target.take_damage(data.damage)
	_cooldown = data.attack_interval
	_play_punch(target.global_position)


## Saca a la unidad del mapa y devuelve recursos.
## survived = true: llegó al final de la oleada (devolución completa).
## survived = false: la destruyó el jugador (devolución parcial).
func remove(survived: bool) -> void:
	if survived:
		Economy.refund_survived(data.earth_cost, data.water_cost)
	else:
		Economy.refund_destroyed(data.earth_cost, data.water_cost)
	queue_free()


## Vuelve sólida, oculta la barra, reproduce el sonido y avisa con `built`.
func _finish_building() -> void:
	is_built = true
	_sprite.modulate = Color.WHITE
	_build_progress.hide()
	if data.spawn_sound:
		_spawn_sound.stream = data.spawn_sound
		_spawn_sound.pitch_scale = randf_range(1.0 - data.pitch_variation, 1.0 + data.pitch_variation)
		_spawn_sound.play()
	built.emit(self)


## Devuelve el enemigo dentro del rango con mayor `progress`, o null si no hay ninguno.
func _find_target() -> Enemy:
	var best: Enemy = null
	for area in _range.get_overlapping_areas():
		var enemy := area.get_parent() as Enemy
		if enemy and (best == null or enemy.progress > best.progress):
			best = enemy
	return best


## Adelanta el sprite 10 px hacia el objetivo y lo devuelve a su lugar.
func _play_punch(target_position: Vector2) -> void:
	var direction := (target_position - global_position).normalized()
	var tween := create_tween()
	tween.tween_property(_sprite, "position", direction * 10.0, 0.06)
	tween.tween_property(_sprite, "position", Vector2.ZERO, 0.12)
