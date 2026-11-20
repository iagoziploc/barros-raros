class_name UnitData
extends Resource
## Datos de un tipo de unidad. Cada tipo es un .tres en data/units/.

## Clave de localization/strings.csv con el nombre.
@export var name_key := ""

@export_group("Costo")
@export var earth_cost := 20
@export var water_cost := 10

@export_group("Construcción")
## Segundos que tarda en construirse. Mientras tanto no ataca y no se puede construir otra.
@export var build_time := 3.0
## Distancia mínima en píxeles entre esta unidad y cualquier otra.
@export var spacing := 72.0

@export_group("Ataque")
## Daño de cada golpe de un ataque, en orden. [1, 3] = un jab de 1 y un golpe de 3.
## Se resta la armadura del enemigo a cada golpe por separado.
@export var hit_damages: Array[int] = [4]
## Cuadro de la animación "hit" en que conecta cada golpe (uno por cada elemento de
## `hit_damages`). Vacío = todos los golpes caen al instante.
@export var hit_frames: Array[int] = []
## Los enemigos a esta distancia del objetivo también reciben cada golpe. 0 = solo el objetivo.
@export var splash_radius := 0.0
## Segundos entre el comienzo de un ataque y el siguiente.
@export var attack_interval := 0.8
## Radio en píxeles dentro del cual detecta enemigos.
@export var attack_range := 90.0

@export_group("Visual y sonido")
## Animaciones "idle" (quieta) y "hit" (ataque). Si está vacío se usa `texture` sin animar.
@export var sprite_frames: SpriteFrames
## Imagen fija, para unidades sin animaciones.
@export var texture: Texture2D
@export var sprite_scale := 0.12
## Se reproduce al terminar de construirse. Puede quedar vacío.
@export var spawn_sound: AudioStream
## Se reproduce en cada golpe que conecta. Puede quedar vacío.
@export var hit_sound: AudioStream
## Cuánto puede subir o bajar el tono de los sonidos. 0.2 = entre 80% y 120% del tono original.
@export_range(0.0, 0.5, 0.01) var pitch_variation := 0.2


## Imagen que representa a la unidad en el fantasma y en la barra:
## el primer cuadro de "idle" si hay animaciones, o `texture` si no.
func get_icon() -> Texture2D:
	if sprite_frames and sprite_frames.has_animation("idle") \
			and sprite_frames.get_frame_count("idle") > 0:
		return sprite_frames.get_frame_texture("idle", 0)
	return texture
