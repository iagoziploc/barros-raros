class_name GolemPlacer
extends Node2D
## Coloca golems con el mouse.
## Con un golem seleccionado: clic izquierdo coloca, clic derecho o Esc cancela.
## Sin selección: clic derecho sobre un golem lo destruye.
## Debe estar en la posición (0, 0) del nivel: dibuja en coordenadas globales.

signal golem_placed(golem: Golem)

@export var golem_scene: PackedScene = preload("res://entities/golems/golem.tscn")
## Nodo donde se agregan los golems.
@export var container: Node2D
## Distancia mínima entre dos golems.
@export var min_spacing := 56.0
## Distancia máxima al golem para destruirlo con clic derecho.
@export var destroy_radius := 36.0

const VALID_COLOR := Color(1.0, 1.0, 1.0, 0.6)
const INVALID_COLOR := Color(1.0, 0.3, 0.3, 0.6)

var _selected: GolemData

@onready var _ghost: Sprite2D = $Ghost


## Arranca sin nada seleccionado.
func _ready() -> void:
	_ghost.hide()


## Mueve el fantasma al mouse y lo tiñe según si se puede colocar ahí.
func _process(_delta: float) -> void:
	if _selected == null:
		return
	_ghost.position = get_global_mouse_position()
	_ghost.modulate = VALID_COLOR if can_place_at(_ghost.position) else INVALID_COLOR
	queue_redraw()


## Dibuja el círculo de alcance alrededor del fantasma.
func _draw() -> void:
	if _selected:
		draw_arc(_ghost.position, _selected.attack_range, 0.0, TAU, 64, _ghost.modulate, 2.0)


## Maneja los clics que la interfaz no usó y la tecla Esc.
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		cancel()
		return

	var click := event as InputEventMouseButton
	if click == null or not click.pressed:
		return

	var mouse := get_global_mouse_position()
	if click.button_index == MOUSE_BUTTON_LEFT and _selected:
		place_at(mouse)
		get_viewport().set_input_as_handled()
	elif click.button_index == MOUSE_BUTTON_RIGHT:
		if _selected:
			cancel()
		else:
			_destroy_at(mouse)
		get_viewport().set_input_as_handled()


## Activa la colocación del golem `data` y muestra su fantasma.
func select(data: GolemData) -> void:
	_selected = data
	_ghost.texture = data.texture
	_ghost.scale = Vector2.ONE * data.sprite_scale
	_ghost.show()


## Sale del modo colocación.
func cancel() -> void:
	_selected = null
	_ghost.hide()
	queue_redraw()


## true si hay un golem seleccionado.
func is_placing() -> bool:
	return _selected != null


## Si se puede, cobra y coloca el golem seleccionado en `point`. Devuelve el golem o null.
func place_at(point: Vector2) -> Golem:
	if not can_place_at(point):
		return null
	Economy.spend(_selected.earth_cost, _selected.water_cost)
	var golem: Golem = golem_scene.instantiate()
	golem.data = _selected
	golem.position = point
	container.add_child(golem)
	golem_placed.emit(golem)
	return golem


## true si hay golem seleccionado, alcanzan los recursos, no hay otro golem
## a menos de `min_spacing` y el punto no está en un área `no_build`.
func can_place_at(point: Vector2) -> bool:
	if _selected == null:
		return false
	if not Economy.can_afford(_selected.earth_cost, _selected.water_cost):
		return false
	for golem in container.get_children():
		if golem.position.distance_to(point) < min_spacing:
			return false
	return not _is_in_no_build_area(point)


## Pregunta al motor de física si en `point` hay un área del grupo "no_build".
func _is_in_no_build_area(point: Vector2) -> bool:
	var query := PhysicsPointQueryParameters2D.new()
	query.position = point
	query.collide_with_areas = true
	query.collide_with_bodies = false
	for hit in get_world_2d().direct_space_state.intersect_point(query):
		if hit.collider.is_in_group("no_build"):
			return true
	return false


## Destruye el primer golem a menos de `destroy_radius` de `point`.
func _destroy_at(point: Vector2) -> void:
	for golem: Golem in container.get_children():
		if golem.position.distance_to(point) <= destroy_radius:
			golem.remove(false)
			return
