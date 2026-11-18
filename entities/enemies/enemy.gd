class_name Enemy
extends PathFollow2D
## Avanza por el Path2D padre a `data.speed`.
## Roba al entrar en áreas de los grupos "wet_zone" y "river".
## Se elimina al morir o al llegar al río.

## Lo mataron. Se emite antes de queue_free().
signal died(enemy: Enemy)
## Llegó al río (o al final del camino). Se emite antes de queue_free().
signal escaped(enemy: Enemy)

@export var data: EnemyData

var health: int

# Evita emitir died/escaped dos veces en el mismo frame antes de que queue_free() lo borre.
var _is_gone := false

@onready var _sprite: Sprite2D = $Sprite
@onready var _placeholder: ColorRect = $Placeholder
@onready var _hitbox: Area2D = $Hitbox


func _ready() -> void:
	health = data.max_health
	_apply_visual()
	_hitbox.area_entered.connect(_on_hitbox_area_entered)


func _process(delta: float) -> void:
	progress += data.speed * delta
	if progress_ratio >= 1.0:
		_escape()


## Resta `amount - data.armor` de vida (mínimo 1). Si llega a 0, muere.
func take_damage(amount: int) -> void:
	if _is_gone:
		return
	health -= maxi(amount - data.armor, 1)
	if health <= 0:
		_is_gone = true
		died.emit(self)
		queue_free()


func _apply_visual() -> void:
	if data.texture:
		_sprite.texture = data.texture
		_sprite.scale = Vector2.ONE * data.sprite_scale
		_placeholder.hide()
	else:
		_sprite.hide()
		_placeholder.color = data.placeholder_color


func _on_hitbox_area_entered(area: Area2D) -> void:
	if area.is_in_group("wet_zone"):
		if data.earth_stolen > 0:
			Economy.steal(Economy.Kind.EARTH, data.earth_stolen)
	elif area.is_in_group("river"):
		if data.water_stolen > 0:
			Economy.steal(Economy.Kind.WATER, data.water_stolen)
		_escape()


func _escape() -> void:
	if _is_gone:
		return
	_is_gone = true
	escaped.emit(self)
	queue_free()
