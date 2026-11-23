class_name MortarUnit
extends Unit
## Unidad de tierra: en vez de pegar, cada golpe tira un terrón (MudShot) que vuela en arco
## hasta donde VA a estar el objetivo y, al caer, daña a todos a `data.splash_radius`.
## Todo lo demás (construcción, cooldown, animación, devolución) lo hereda de Unit.


## Lanza un terrón al lugar donde va a estar el objetivo cuando caiga.
## Reemplaza al _strike de Unit, que pegaba en el momento.
func _strike(index: int) -> void:
	var target := _find_target()
	if target == null:
		return
	var landing := target.predict_position(data.projectile_flight_time)
	var shot := MudShot.new()
	add_child(shot)
	shot.landed.connect(_on_shot_landed.bind(_hit_damage(index)))
	shot.launch(body_position(), landing, data.projectile_flight_time,
			data.projectile_arc_height, data.projectile_texture)


## Un terrón cayó en `point`: daña a todos los enemigos a `data.splash_radius`.
## Busca en el grupo "enemies" porque pueden estar fuera del rango de la unidad.
func _on_shot_landed(point: Vector2, damage: int) -> void:
	var piercing := _armor_piercing()
	for enemy: Enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy.global_position.distance_to(point) <= data.splash_radius:
			enemy.take_damage(damage, piercing)
	_play_sound(_hit_sound, data.hit_sound)
	if show_debug_areas:
		_show_debug_hit(point)
