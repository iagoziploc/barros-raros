class_name Enemy
extends PathFollow2D
## Avanza por el Path2D padre a `data.speed`.
## En el área del grupo "wet_zone" se detiene `data.earth_steal_duration` segundos
## y después roba tierra. En el área del grupo "river" roba agua y se va.
## Se elimina al morir o al llegar al río.

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

@onready var _sprite: Sprite2D = $Sprite
@onready var _placeholder: ColorRect = $Placeholder
@onready var _hitbox: Area2D = $Hitbox


## Inicializa la vida y el aspecto desde `data` y empieza a escuchar su hitbox.
func _ready() -> void:
	health = data.max_health
	_apply_visual()
	_hitbox.area_entered.connect(_on_hitbox_area_entered)


## Si está robando, descuenta la pausa y roba al terminarla. Si no, avanza por el camino.
func _process(delta: float) -> void:
	if is_stealing():
		_steal_time_left -= delta
		if _steal_time_left <= 0.0:
			_steal_time_left = 0.0
			Economy.steal(Economy.Kind.EARTH, data.earth_stolen)
		return

	progress += data.speed * delta
	if progress_ratio >= 1.0:
		_escape()


## true mientras está detenido en la zona húmeda.
func is_stealing() -> bool:
	return _steal_time_left > 0.0


## Resta `amount - data.armor` de vida (mínimo 1). Si llega a 0, muere.
func take_damage(amount: int) -> void:
	if _is_gone:
		return
	health -= maxi(amount - data.armor, 1)
	if health <= 0:
		_is_gone = true
		died.emit(self)
		queue_free()
	else:
		_flash()


## Se tiñe de rojo y vuelve al color normal.
func _flash() -> void:
	modulate = Color(1.0, 0.4, 0.4)
	create_tween().tween_property(self, "modulate", Color.WHITE, 0.15)


## Usa la textura de `data` o, si no hay, el cuadrado de color.
func _apply_visual() -> void:
	if data.texture:
		_sprite.texture = data.texture
		_sprite.scale = Vector2.ONE * data.sprite_scale
		_placeholder.hide()
	else:
		_sprite.hide()
		_placeholder.color = data.placeholder_color


## Reacciona a las zonas del nivel según su grupo: zona húmeda o río.
func _on_hitbox_area_entered(area: Area2D) -> void:
	if area.is_in_group("wet_zone"):
		if data.earth_stolen > 0:
			_start_stealing_earth()
	elif area.is_in_group("river"):
		if data.water_stolen > 0:
			Economy.steal(Economy.Kind.WATER, data.water_stolen)
		_escape()


## Arranca la pausa de robo de tierra. Si muere antes de terminarla, no roba.
func _start_stealing_earth() -> void:
	steal_started.emit(Economy.Kind.EARTH)
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
