class_name UnitPlacer
extends Node2D
## Coloca unidades con el mouse, de a una por vez.
## Con una unidad seleccionada: clic izquierdo coloca (y deselecciona), clic derecho o Esc cancela.
## Sin selección: clic derecho sobre una unidad la destruye.
## Mientras una unidad se construye no se puede seleccionar ni colocar otra.
## Debe estar en la posición (0, 0) del nivel: dibuja en coordenadas globales.

signal unit_placed(unit: Unit)
## Empezó (true) o terminó (false) la construcción en curso.
signal building_changed(is_building: bool)

@export var unit_scene: PackedScene = preload("res://entities/units/unit.tscn")
## Nodo donde se agregan las unidades.
@export var container: Node2D
## Rutas de los enemigos, para saber qué es "sobre el camino" (`UnitData.placement`).
@export var routes: Array[Path2D] = []
## Hasta cuántos píxeles del centro del camino cuenta como "sobre el camino" (la mitad del ancho).
@export var path_half_width := 34.0
## Herramienta de diseño: con una unidad seleccionada, pinta de rojo dónde NO se puede
## construir esa unidad (zonas prohibidas, camino, distancia a otras unidades).
## Se activa en el inspector del nodo UnitPlacer del nivel.
@export var show_build_map := false
## Tamaño en píxeles de cada cuadradito del mapa de construcción.
const BUILD_MAP_CELL := 16
const BUILD_MAP_COLOR := Color(1.0, 0.2, 0.2, 0.35)

## Distancia máxima a la unidad para destruirla con clic derecho.
@export var destroy_radius := 36.0

const VALID_COLOR := Color(1.0, 1.0, 1.0, 0.6)
const INVALID_COLOR := Color(1.0, 0.3, 0.3, 0.6)

var _selected: UnitData
# Para show_build_map: esquinas de los cuadraditos donde no se puede construir.
var _blocked_cells: Array[Vector2] = []
# Unidad que se está construyendo, o null.
var _building: Unit

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
	if _selected and show_build_map:
		for cell in _blocked_cells:
			draw_rect(Rect2(cell, Vector2.ONE * BUILD_MAP_CELL), BUILD_MAP_COLOR)
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


## Activa la colocación de la unidad `data` y muestra su fantasma.
## No hace nada si hay una unidad en construcción.
func select(data: UnitData) -> void:
	if is_building():
		return
	_selected = data
	_ghost.texture = data.get_icon()
	_ghost.scale = Vector2.ONE * data.sprite_scale
	_ghost.show()
	if show_build_map:
		_update_build_map()


## Sale del modo colocación.
func cancel() -> void:
	_selected = null
	_ghost.hide()
	queue_redraw()


## true si hay una unidad seleccionada.
func is_placing() -> bool:
	return _selected != null


## true si hay una unidad en construcción.
func is_building() -> bool:
	return _building != null


## Si se puede, cobra, coloca la unidad seleccionada en `point` y deselecciona.
## Devuelve la unidad o null.
func place_at(point: Vector2) -> Unit:
	if not can_place_at(point):
		return null
	var earth_cost := Modifiers.earth_cost(_selected)
	var water_cost := Modifiers.water_cost(_selected)
	Economy.spend(earth_cost, water_cost)
	var scene := _selected.scene if _selected.scene else unit_scene
	var unit: Unit = scene.instantiate()
	unit.data = _selected
	unit.paid_earth = earth_cost
	unit.paid_water = water_cost
	unit.position = point
	container.add_child(unit)
	cancel()
	if not unit.is_built:
		_start_tracking(unit)
	unit_placed.emit(unit)
	return unit


## true si hay unidad seleccionada, no hay otra en construcción, alcanzan los recursos,
## se respeta la distancia mínima (`spacing`), el punto no está en un área `no_build`
## y se respeta `placement`: sobre el camino, fuera de él o en cualquier lado.
func can_place_at(point: Vector2) -> bool:
	if _selected == null or is_building():
		return false
	if not Economy.can_afford(Modifiers.earth_cost(_selected), Modifiers.water_cost(_selected)):
		return false
	return is_buildable_spot(point)


## true si el lugar sirve para la unidad seleccionada, sin mirar recursos ni construcciones:
## distancia a otras unidades (`spacing`), `placement` (sobre o fuera del camino) y zonas `no_build`.
func is_buildable_spot(point: Vector2) -> bool:
	for unit: Unit in container.get_children():
		# Vale la distancia más grande de las dos unidades.
		var spacing := maxf(unit.data.spacing, _selected.spacing)
		if unit.position.distance_to(point) < spacing:
			return false
	if _selected.placement == UnitData.Placement.ON_PATH and not _is_on_path(point):
		return false
	if _selected.placement == UnitData.Placement.OFF_PATH and _is_on_path(point):
		return false
	return not _is_in_no_build_area(point)


## Para show_build_map: recorre la pantalla en cuadraditos y guarda los que no sirven.
func _update_build_map() -> void:
	_blocked_cells.clear()
	var screen := get_viewport_rect().size
	for y in range(0, int(screen.y), BUILD_MAP_CELL):
		for x in range(0, int(screen.x), BUILD_MAP_CELL):
			var corner := Vector2(x, y)
			if not is_buildable_spot(corner + Vector2.ONE * BUILD_MAP_CELL / 2.0):
				_blocked_cells.append(corner)


## true si `point` está a menos de `path_half_width` de la curva de alguna ruta.
func _is_on_path(point: Vector2) -> bool:
	for path in routes:
		# La curva está en coordenadas del Path2D: se pasa el punto a esas coordenadas y se vuelve.
		var closest := path.to_global(path.curve.get_closest_point(path.to_local(point)))
		if closest.distance_to(point) <= path_half_width:
			return true
	return false


## Registra `unit` como la construcción en curso hasta que termine o desaparezca.
func _start_tracking(unit: Unit) -> void:
	_building = unit
	unit.built.connect(_on_building_done)
	# Si la destruyen o se disuelve antes de terminar, también se libera el lugar.
	unit.tree_exiting.connect(_on_building_done.bind(unit))
	building_changed.emit(true)


## La construcción en curso terminó o su unidad salió del mapa.
func _on_building_done(unit: Unit) -> void:
	if unit != _building:
		return
	_building = null
	building_changed.emit(false)


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


## Destruye la primera unidad a menos de `destroy_radius` de `point`.
func _destroy_at(point: Vector2) -> void:
	for unit: Unit in container.get_children():
		if unit.position.distance_to(point) <= destroy_radius:
			unit.remove(false)
			return
