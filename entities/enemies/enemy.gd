class_name Enemy
extends PathFollow2D
## Avanza por el Path2D padre a `data.speed`.
## En el área del grupo "wet_zone" se detiene `data.earth_steal_duration` segundos
## y después roba tierra. En el área del grupo "river" roba agua y se va.
## Se elimina al morir o al llegar al río. Una pileta lo puede atrapar: se queda quieto,
## se hunde y muere (trap).

## Lo mataron. Se emite antes de queue_free().
signal died(enemy: Enemy)
## Llegó al río (o al final del camino). Se emite antes de queue_free().
signal escaped(enemy: Enemy)
## Se detuvo a robar. Pensada para disparar la animación de robo.
signal steal_started(kind: Economy.Kind)

@export var data: EnemyData

var health: int

# Evita emitir died/escaped dos veces en el mismo frame antes de que queue_free() lo borre.
var _is_gone := false
# Segundos que le quedan detenido robando tierra. 0 = está caminando.
var _steal_time_left := 0.0
# Velocidad de este enemigo en particular: data.speed con una variación al azar.
var _speed := 0.0
# true desde que lo atrapa una pileta.
var _is_trapped := false

@onready var _sprite: Sprite2D = $Sprite
@onready var _placeholder: ColorRect = $Placeholder
@onready var _hitbox: Area2D = $Hitbox
@onready var _dig_sound: AudioStreamPlayer2D = $DigSound


## Inicializa vida, velocidad y aspecto desde `data` y empieza a escuchar su hitbox.
func _ready() -> void:
	add_to_group("enemies")
	health = data.max_health
	_speed = data.speed * randf_range(1.0 - data.speed_variation, 1.0 + data.speed_variation) \
			* Modifiers.multiplier(Modifiers.Stat.ENEMY_SPEED)
	_apply_visual()
	_hitbox.area_entered.connect(_on_hitbox_area_entered)


## Si está robando, descuenta la pausa y roba al terminarla. Si no, avanza por el camino.
## Atrapado no hace nada: el hundimiento lo maneja el tween de trap().
func _process(delta: float) -> void:
	if _is_trapped:
		return
	if is_stealing():
		_steal_time_left -= delta
		if _steal_time_left <= 0.0:
			_steal_time_left = 0.0
			Economy.steal(Economy.Kind.EARTH, data.earth_stolen)
		return

	progress += _speed * delta
	if progress_ratio >= 1.0:
		_escape()


## true mientras está detenido en la zona húmeda.
func is_stealing() -> bool:
	return _steal_time_left > 0.0


## Resta `amount` menos la armadura de vida (mínimo 1). Si llega a 0, muere.
## `armor_piercing` son puntos de armadura que el golpe ignora.
func take_damage(amount: int, armor_piercing := 0) -> void:
	if _is_gone:
		return
	var armor := maxi(data.armor - armor_piercing, 0)
	health -= maxi(amount - armor, 1)
	if health <= 0:
		_die()
	else:
		_flash()


## true desde que lo atrapa una pileta.
func is_trapped() -> bool:
	return _is_trapped


## Lo atrapa una pileta: deja de caminar y de robar, se hunde durante `duration` segundos
## y muere, sin importar su vida ni su armadura.
func trap(duration: float) -> void:
	if _is_gone or _is_trapped:
		return
	_is_trapped = true
	_steal_time_left = 0.0
	var tween := create_tween().set_parallel()
	tween.tween_property(self, "scale", Vector2.ONE * 0.4, duration)
	tween.tween_property(self, "modulate", Color(0.45, 0.32, 0.2, 0.6), duration)
	tween.chain().tween_callback(_die)


## Dónde va a estar dentro de `seconds` segundos si sigue caminando (para apuntarle de lejos).
## Si está quieto (robando o atrapado), donde está ahora.
func predict_position(seconds: float) -> Vector2:
	if _is_trapped or is_stealing():
		return global_position
	var path := get_parent() as Path2D
	var future := path.curve.sample_baked(progress + _speed * seconds)
	return path.to_global(future)


## Muere: grita (con un reproductor aparte, que no se borra con él), avisa con `died` y se borra.
func _die() -> void:
	if _is_gone:
		return
	_is_gone = true
	Sfx.play_detached(data.death_sound, self)
	died.emit(self)
	queue_free()


## Se tiñe de rojo y vuelve al color normal. Atrapado no: taparía el color del hundimiento.
func _flash() -> void:
	if _is_trapped:
		return
	modulate = Color(1.0, 0.4, 0.4)
	create_tween().tween_property(self, "modulate", Color.WHITE, 0.15)


## Usa la textura de `data` o, si no hay, el cuadrado de color.
func _apply_visual() -> void:
	if data.texture:
		_sprite.texture = data.texture
		_sprite.scale = Vector2.ONE * data.sprite_scale
		# Igual que las unidades: la posición sobre el camino son sus pies.
		_sprite.offset = Vector2(0, -data.texture.get_height() / 2.0)
		_placeholder.hide()
	else:
		_sprite.hide()
		_placeholder.color = data.placeholder_color


## Reacciona a las zonas del nivel según su grupo: zona húmeda o río.
func _on_hitbox_area_entered(area: Area2D) -> void:
	if area.is_in_group("wet_zone"):
		if data.steals_earth():
			_start_stealing_earth()
	elif area.is_in_group("river"):
		if data.water_stolen > 0:
			Economy.steal(Economy.Kind.WATER, data.water_stolen)
		_escape()


## Arranca la pausa de robo de tierra (con el sonido de la pala). Si muere antes de terminarla, no roba.
func _start_stealing_earth() -> void:
	steal_started.emit(Economy.Kind.EARTH)
	if data.dig_sound:
		_dig_sound.stream = data.dig_sound
		_dig_sound.play()
	if data.earth_steal_duration <= 0.0:
		Economy.steal(Economy.Kind.EARTH, data.earth_stolen)
	else:
		_steal_time_left = data.earth_steal_duration


## Sale del mapa: avisa con `escaped` y se borra.
func _escape() -> void:
	if _is_gone:
		return
	_is_gone = true
	escaped.emit(self)
	queue_free()
