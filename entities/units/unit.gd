class_name Unit
extends Node2D
## Se construye durante `data.build_time` segundos (semitransparente, con barra de progreso
## y sin atacar). Al terminar suena y, desde ahí, cada `data.attack_interval` segundos
## ataca al enemigo de su rango que está más avanzado en el camino.
## Un ataque son uno o más golpes (`data.hit_damages`). Con animación "hit", cada golpe
## cae en su cuadro (`data.hit_frames`); sin animación, caen todos al instante.
## Es la unidad de piñas y la base de las demás: MortarUnit y PoolUnit la extienden
## y reemplazan solo lo que hacen distinto (_strike y _act).

## Terminó de construirse.
signal built(unit: Unit)

const BUILDING_COLOR := Color(1.0, 1.0, 1.0, 0.45)
const DEBUG_HIT_COLOR := Color(1.0, 0.9, 0.3)

@export var data: UnitData
## Herramienta de depuración: dibuja el alcance y, en cada golpe, el área (`splash_radius`)
## alrededor del objetivo. Se activa en el inspector de unit.tscn.
@export var show_debug_areas := false

var is_built := false
## Lo que se pagó al colocarla (con modificadores). Se usa para la devolución.
## -1 = no se indicó: se usa el costo base de `data`.
var paid_earth := -1
var paid_water := -1

# Para show_debug_areas: dónde fue el último golpe (en coordenadas de la unidad)
# y qué tan visible queda el círculo (1 = recién, 0 = ya se borró).
var _debug_hit_position := Vector2.ZERO
var _debug_hit_alpha := 0.0

# Duración total de la construcción (con modificadores) y segundos que faltan.
var _build_duration := 0.0
var _build_time_left := 0.0
# Segundos que faltan para poder empezar el próximo ataque.
var _cooldown := 0.0
# Índice del próximo golpe del ataque en curso (posición en data.hit_damages).
var _next_hit := 0

@onready var _sprite: AnimatedSprite2D = $Sprite
@onready var _range: Area2D = $Range
@onready var _range_shape: CollisionShape2D = $Range/Shape
@onready var _spawn_sound: AudioStreamPlayer2D = $SpawnSound
@onready var _hit_sound: AudioStreamPlayer2D = $HitSound
@onready var _build_progress: ProgressBar = $BuildProgress


## Aplica animaciones y rango desde `data` y arranca la construcción.
func _ready() -> void:
	_sprite.sprite_frames = _make_sprite_frames()
	_sprite.scale = Vector2.ONE * data.sprite_scale
	_sprite.animation_finished.connect(_on_sprite_animation_finished)
	_sprite.frame_changed.connect(_on_sprite_frame_changed)
	_sprite.play("idle")

	# Una forma nueva por unidad: si la compartieran, cambiar el radio de una las cambiaría a todas.
	var circle := CircleShape2D.new()
	circle.radius = data.attack_range
	_range_shape.shape = circle

	if paid_earth < 0:
		paid_earth = data.earth_cost
	if paid_water < 0:
		paid_water = data.water_cost

	_build_duration = data.build_time * Modifiers.multiplier(Modifiers.Stat.UNIT_BUILD_TIME)
	_build_time_left = _build_duration
	if _build_time_left <= 0.0:
		_finish_building()
	else:
		_sprite.modulate = BUILDING_COLOR
		_build_progress.show()


## Mientras se construye, avanza la barra. Construida, hace lo suyo en _act().
func _process(delta: float) -> void:
	if not is_built:
		_build_time_left -= delta
		_build_progress.value = 1.0 - _build_time_left / _build_duration
		if _build_time_left <= 0.0:
			_finish_building()
		return
	_act(delta)


## Lo que hace la unidad construida en cada frame: ataca cuando el cooldown llega a 0.
## Las unidades que no atacan así (la pileta) lo reemplazan.
func _act(delta: float) -> void:
	_cooldown = maxf(_cooldown - delta, 0.0)
	if _cooldown > 0.0:
		return

	var target := _find_target()
	if target == null:
		return

	_cooldown = data.attack_interval / _attack_speed()
	_start_attack(target)


## Saca a la unidad del mapa y devuelve recursos.
## survived = true: llegó al final de la oleada (devolución completa).
## survived = false: la destruyó el jugador (devolución parcial).
func remove(survived: bool) -> void:
	if survived:
		Economy.refund_survived(paid_earth, paid_water)
	else:
		Economy.refund_destroyed(paid_earth, paid_water)
	queue_free()


## Las animaciones de `data`, o una animación "idle" de un solo cuadro con `data.texture`.
func _make_sprite_frames() -> SpriteFrames:
	if data.sprite_frames:
		return data.sprite_frames
	var frames := SpriteFrames.new()
	frames.add_animation("idle")
	frames.add_frame("idle", data.texture)
	return frames


## Vuelve sólida, oculta la barra, reproduce el sonido y avisa con `built`.
func _finish_building() -> void:
	is_built = true
	_sprite.modulate = Color.WHITE
	_build_progress.hide()
	_play_sound(_spawn_sound, data.spawn_sound)
	built.emit(self)


## Mira hacia `target` y arranca el ataque: con la animación "hit" si se puede usar,
## o con todos los golpes de una vez si no.
func _start_attack(target: Enemy) -> void:
	# El dibujo pega hacia la izquierda: si el objetivo está a la derecha, se espeja.
	_sprite.flip_h = target.global_position.x > global_position.x
	_next_hit = 0
	if _can_animate_hits():
		# Si ataca más rápido, la animación también: así los golpes siguen cayendo en sus cuadros.
		_sprite.speed_scale = _attack_speed()
		_sprite.play("hit")
	else:
		for index in data.hit_damages.size():
			_strike(index)


## true si hay animación "hit" y un cuadro indicado para cada golpe.
func _can_animate_hits() -> bool:
	return _sprite.sprite_frames.has_animation("hit") \
			and data.hit_frames.size() == data.hit_damages.size()


## Golpe número `index` del ataque: daña al mejor objetivo del rango y a los enemigos
## que estén a `data.splash_radius` de él. Si ya no hay objetivo, el golpe va al aire.
func _strike(index: int) -> void:
	var target := _find_target()
	if target == null:
		return
	var damage := _hit_damage(index)
	var piercing := _armor_piercing()
	for enemy in _enemies_in_range():
		var distance := enemy.global_position.distance_to(target.global_position)
		if enemy == target or distance <= data.splash_radius:
			enemy.take_damage(damage, piercing)
	_play_sound(_hit_sound, data.hit_sound)
	if show_debug_areas:
		_show_debug_hit(target.global_position)


## Daño del golpe número `index`, con los modificadores. Siempre al menos 1.
func _hit_damage(index: int) -> int:
	var base_damage: int = data.hit_damages[index]
	return maxi(roundi(base_damage * Modifiers.multiplier(Modifiers.Stat.UNIT_DAMAGE)), 1)


## Puntos de armadura que ignoran los golpes, según los modificadores.
func _armor_piercing() -> int:
	return roundi(Modifiers.get_value(Modifiers.Stat.UNIT_ARMOR_PIERCING))


## Devuelve el enemigo dentro del rango con mayor `progress`, o null si no hay ninguno.
## Ignora a los que se está hundiendo una pileta: ya están perdidos.
func _find_target() -> Enemy:
	var best: Enemy = null
	for enemy in _enemies_in_range():
		if enemy.is_trapped():
			continue
		if best == null or enemy.progress > best.progress:
			best = enemy
	return best


## Multiplicador de velocidad de ataque de los modificadores (1 = normal).
func _attack_speed() -> float:
	return Modifiers.multiplier(Modifiers.Stat.UNIT_ATTACK_SPEED)


## Todos los enemigos que están dentro del rango.
func _enemies_in_range() -> Array[Enemy]:
	var enemies: Array[Enemy] = []
	for area in _range.get_overlapping_areas():
		var enemy := area.get_parent() as Enemy
		if enemy:
			enemies.append(enemy)
	return enemies


## Reproduce `stream` en `player` con un tono al azar según `data.pitch_variation`.
func _play_sound(player: AudioStreamPlayer2D, stream: AudioStream) -> void:
	if stream == null:
		return
	player.stream = stream
	player.pitch_scale = randf_range(1.0 - data.pitch_variation, 1.0 + data.pitch_variation)
	player.play()


## Durante "hit", cuando la animación llega al cuadro del próximo golpe, lo aplica.
## Usa >= y while por si en un frame lento la animación salteó algún cuadro.
func _on_sprite_frame_changed() -> void:
	if _sprite.animation != &"hit":
		return
	while _next_hit < data.hit_frames.size() and _sprite.frame >= data.hit_frames[_next_hit]:
		_strike(_next_hit)
		_next_hit += 1


## Con show_debug_areas: el círculo de alcance y, si hubo un golpe reciente, su área.
func _draw() -> void:
	if not show_debug_areas:
		return
	draw_arc(Vector2.ZERO, data.attack_range, 0.0, TAU, 64, Color(1, 1, 1, 0.3), 1.0)
	if _debug_hit_alpha > 0.0:
		var color := Color(DEBUG_HIT_COLOR, _debug_hit_alpha)
		draw_circle(_debug_hit_position, maxf(data.splash_radius, 3.0), Color(color, 0.25 * _debug_hit_alpha))
		draw_arc(_debug_hit_position, maxf(data.splash_radius, 3.0), 0.0, TAU, 48, color, 2.0)


## Marca el área del golpe en `global_point` y la desvanece en medio segundo.
func _show_debug_hit(global_point: Vector2) -> void:
	_debug_hit_position = to_local(global_point)
	_debug_hit_alpha = 1.0
	# tween_method llama a la función con valores que van de 1 a 0 durante 0,5 s.
	create_tween().tween_method(_set_debug_hit_alpha, 1.0, 0.0, 0.5)


## Usada por el tween de _show_debug_hit: actualiza la transparencia y redibuja.
func _set_debug_hit_alpha(alpha: float) -> void:
	_debug_hit_alpha = alpha
	queue_redraw()


## Al terminar cualquier animación sin loop (como "hit"), vuelve a "idle".
func _on_sprite_animation_finished() -> void:
	_sprite.speed_scale = 1.0
	_sprite.play("idle")
