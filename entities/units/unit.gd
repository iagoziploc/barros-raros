class_name Unit
extends Node2D
## Golpea cada `data.attack_interval` segundos al enemigo de su rango
## que está más avanzado en el camino.

@export var data: UnitData

# Segundos que faltan para poder volver a golpear.
var _cooldown := 0.0

@onready var _sprite: Sprite2D = $Sprite
@onready var _range: Area2D = $Range
@onready var _range_shape: CollisionShape2D = $Range/Shape
@onready var _spawn_sound: AudioStreamPlayer2D = $SpawnSound


## Aplica imagen y rango desde `data` y reproduce el sonido de nacimiento.
func _ready() -> void:
	_sprite.texture = data.texture
	_sprite.scale = Vector2.ONE * data.sprite_scale

	# Una forma nueva por unidad: si la compartieran, cambiar el radio de una las cambiaría a todas.
	var circle := CircleShape2D.new()
	circle.radius = data.attack_range
	_range_shape.shape = circle

	if data.spawn_sound:
		_spawn_sound.stream = data.spawn_sound
		_spawn_sound.pitch_scale = randf_range(1.0 - data.pitch_variation, 1.0 + data.pitch_variation)
		_spawn_sound.play()


## Descuenta el cooldown y, cuando llega a 0, golpea al mejor objetivo si hay alguno.
func _process(delta: float) -> void:
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
