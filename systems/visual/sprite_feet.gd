class_name SpriteFeet
## Calcula cuánto correr un dibujo para que su punto quede en los pies (el borde de abajo de lo
## que está dibujado), y no en el centro de la imagen ni en su borde, que puede tener
## espacio transparente.


## El `offset` para un sprite centrado: sube el dibujo hasta que su píxel visible más bajo
## quede en el punto del nodo. Mide el primer cuadro (si la imagen es una tira de `frames`
## cuadros a lo ancho). `extra` corre el resultado a mano: positivo = el dibujo baja.
static func offset_for(texture: Texture2D, frames := 1, extra := 0.0) -> Vector2:
	if texture == null:
		return Vector2.ZERO
	var image := texture.get_image()
	var frame_size := Vector2i(image.get_width() / frames, image.get_height())
	# get_used_rect(): el rectángulo donde hay píxeles que no son transparentes.
	var used := image.get_region(Rect2i(Vector2i.ZERO, frame_size)).get_used_rect()
	return Vector2(0, frame_size.y / 2.0 - used.end.y + extra)
