class_name EnemyData
extends Resource
## Datos de un tipo de enemigo. Cada tipo es un .tres en data/enemies/.

@export_group("Movimiento y vida")
## Píxeles por segundo a lo largo del camino.
@export var speed := 60.0
## Cuánto puede variar la velocidad de cada enemigo, al azar. 0.15 = entre 85% y 115% de `speed`.
@export_range(0.0, 0.5, 0.01) var speed_variation := 0.15
@export var max_health := 10
## Se resta al daño de cada golpe. Cada golpe hace al menos 1 de daño.
@export var armor := 0
## Multiplica el tiempo que tarda una pileta en hundirlo. 2 = tarda el doble.
@export var sink_time_multiplier := 1.0

@export_group("Robo")
## Tierra que roba en la zona húmeda. 0 = no roba tierra ni se detiene.
@export var earth_stolen := 0
## Segundos que se queda quieto en la zona húmeda antes de robar la tierra.
@export var earth_steal_duration := 1.5
## Agua que roba al llegar al río. 0 = no roba agua.
@export var water_stolen := 0

@export_group("Recompensa")
## Cuánto carga la barra de la ultimate al morir.
@export var ultimate_charge := 1

@export_group("Sonido")
## Suena al morir. Puede ser un AudioStreamRandomizer (uno al azar de varios).
@export var death_sound: AudioStream
## Suena al empezar a robar tierra (la pala).
@export var dig_sound: AudioStream

@export_group("Visual")
## Si es null se dibuja un cuadrado de `placeholder_color`. Puede ser una tira de cuadros
## iguales, uno al lado del otro (un spritesheet de una fila): ver `frames`.
@export var texture: Texture2D
## Cuántos cuadros tiene `texture` a lo ancho. 1 = imagen fija.
@export var frames := 1
## Cuadros por segundo de la caminata.
@export var walk_fps := 6.0
@export var sprite_scale := 1.0
## Ajuste fino de dónde quedan los pies, en píxeles de la imagen original (positivo = el dibujo
## baja). Lo normal es 0: los pies se calculan solos con lo que está dibujado.
@export var foot_offset := 0.0

# Resultado de feet_offset() la primera vez que se calcula (null = todavía no).
var _feet_offset_cache = null
@export var placeholder_color := Color.WHITE


## Corrimiento del dibujo para que la posición sobre el camino sean sus pies (ver SpriteFeet).
## Se calcula una vez y se guarda, porque aparecen muchos enemigos iguales.
func feet_offset() -> Vector2:
	if _feet_offset_cache == null:
		_feet_offset_cache = SpriteFeet.offset_for(texture, frames, foot_offset)
	return _feet_offset_cache


## true si roba tierra: cava en el pozo y por eso solo usa entradas que pasan por él.
func steals_earth() -> bool:
	return earth_stolen > 0
